#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Client-side evaluation loop for EWAR drone jamming and manpack RCU HUD.
 * Runs periodically to update backpack battery/HUD and check if the player's
 * connected UAV is inside any jamming bubble.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_ewar_clientLoop
 *
 * Public: No
 */

if !(EGVAR(Settings,ewar_enable)) exitWith {
    if (GVAR(ewar_activeFX)) then {
        call FUNC(ewar_clearFX);
    };
    [0] call FUNC(ewar_updateBackpackHUD);
};

// 1. Handle local player's EWAR Backpack Jammer (battery drain, unequip safeguard, and RCU HUD)
if (player getVariable [QGVAR(ewar_isJammerActive), false]) then {
    if (!alive player || {(toLower (backpack player)) find "b_radiobag_01" == -1}) then {
        [player, false] call FUNC(ewar_toggleBackpackJammer);
    } else {
        if (EGVAR(Settings,ewar_backpackRequiresBattery)) then {
            private _isDirectional = ((toLower (currentWeapon player)) find "hgun_esd_01" != -1);
            private _powerDrainMult = if (_isDirectional) then {
                missionNamespace getVariable [QEGVAR(Settings,ewar_directionalPowerDrain), 1.5]
            } else {
                1.0
            };

            private _battery = player getVariable [QGVAR(ewar_backpackBattery), 100];
            private _batteryLifeSec = (EGVAR(Settings,ewar_backpackBatteryLife) max 1) * 60;
            private _drain = (0.5 / _batteryLifeSec) * 100 * _powerDrainMult;
            _battery = (_battery - _drain) max 0;
            player setVariable [QGVAR(ewar_backpackBattery), _battery, true];

            if (_battery <= 0) then {
                [player, false] call FUNC(ewar_toggleBackpackJammer);
            };
        };
    };
};

[0] call FUNC(ewar_updateBackpackHUD);

// 2. Evaluate UAV jamming if local player is connected to a drone
private _uav = getConnectedUAV player;
if (isNull _uav) exitWith {
    if (GVAR(ewar_activeFX)) then {
        call FUNC(ewar_clearFX);
    };
};

private _maxIntensity = 0;

if (!isNil QGVAR(ewar_jammers) && {GVAR(ewar_jammers) isNotEqualTo []}) then {
    private _uavPos = getPosATL _uav;
    private _uavPosASL = getPosASL _uav;
    private _uavSide = if (!isNull (driver _uav)) then { side (group (driver _uav)) } else { side (group player) };

    {
        _x params ["_id", "_source", "_radius", "_coreRatio", "_sideExempt"];

        private _isExempt = if (_sideExempt isEqualType []) then {
            _uavSide in _sideExempt
        } else {
            _uavSide isEqualTo _sideExempt
        };

        if (!_isExempt && {_radius > 0}) then {
            private _isMan = (_source isEqualType objNull) && {_source isKindOf "CAManBase"};
            private _isDirMan = _isMan && {alive _source} && {((toLower (currentWeapon _source)) find "hgun_esd_01" != -1)};

            if (_isDirMan) then {
                // Directional 3D 45-degree cone mode (Option A: Pure Directional)
                private _dirMult = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalMultiplier), 3.0];
                private _coneAngle = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalConeAngle), 45];
                private _halfAngle = _coneAngle * 0.5;

                private _effRadius = _radius * _dirMult;
                private _effCoreRatio = _coreRatio max 0 min 0.95;
                private _coreDist = _effRadius * _effCoreRatio;

                private _sourceEyePos = eyePos _source;
                private _vecToUav = _uavPosASL vectorDiff _sourceEyePos;
                private _dist = vectorMagnitude _vecToUav;

                if (_dist <= _effRadius) then {
                    private _aimDir = vectorNormalized (_source weaponDirection (currentWeapon _source));
                    if (_aimDir isEqualTo [0, 0, 0]) then {
                        _aimDir = vectorNormalized (eyeDirection _source);
                    };

                    private _uavDir = vectorNormalized _vecToUav;
                    private _dot = (_aimDir vectorDotProduct _uavDir) max -1 min 1;
                    private _angleDeg = acos _dot;

                    if (_angleDeg <= _halfAngle) then {
                        private _intensity = if (_effCoreRatio > 0 && {_dist <= _coreDist}) then {
                            1.0
                        } else {
                            0.84 * (1 - ((_dist - _coreDist) / ((_effRadius - _coreDist) max 1)))
                        };
                        if (_intensity > _maxIntensity) then {
                            _maxIntensity = _intensity;
                        };
                    };
                };
            } else {
                // Standard omnidirectional bubble mode
                private _pos = if (_source isEqualType objNull) then {
                    if (isNull _source || {!alive _source}) then {
                        [0, 0, 0]
                    } else {
                        getPosATL _source
                    };
                } else {
                    _source
                };

                if (_pos isNotEqualTo [0, 0, 0]) then {
                    private _dist = _uavPos distance _pos;
                    if (_dist <= _radius) then {
                        private _coreDist = _radius * (_coreRatio max 0 min 0.95);
                        private _intensity = if (_coreRatio > 0 && {_dist <= _coreDist}) then {
                            1.0
                        } else {
                            0.84 * (1 - ((_dist - _coreDist) / ((_radius - _coreDist) max 1)))
                        };
                        if (_intensity > _maxIntensity) then {
                            _maxIntensity = _intensity;
                        };
                    };
                };
            };
        };
    } forEach GVAR(ewar_jammers);
};

if (_maxIntensity <= 0 && {!(cameraOn isEqualTo _uav)}) exitWith {
    if (GVAR(ewar_activeFX)) then {
        call FUNC(ewar_clearFX);
    };
};

[_uav, _maxIntensity] call FUNC(ewar_applyInterference);
