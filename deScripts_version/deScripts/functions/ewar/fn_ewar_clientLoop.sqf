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
private _isPackActive = player getVariable [QGVAR(ewar_isJammerActive), false];
private _isPulsing = player getVariable [QGVAR(ewar_isPulsing), false];
if (_isPackActive || {_isPulsing}) then {
    if (!alive player || {(toLower (backpack player)) find "b_radiobag_01" == -1}) then {
        player setVariable [QGVAR(ewar_isPulsing), false, true];
        [player, false] call FUNC(ewar_toggleBackpackJammer);
    } else {
        if (EGVAR(Settings,ewar_backpackRequiresBattery)) then {
            private _isDirectional = ((toLower (currentWeapon player)) find "hgun_esd_01" != -1) || {_isPulsing};
            private _beamMode = player getVariable [QGVAR(ewar_beamMode), 0];
            private _powerDrainMult = if (_isDirectional) then {
                private _baseDrain = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalPowerDrain), 3.0];
                private _drainMult = _baseDrain + (_beamMode * 1.0); // 3x (Wide), 4x (Focused), 5x (Spot)
                private _burnProgress = missionNamespace getVariable [QGVAR(ewar_burnProgress), 0];
                if (!isNil "_burnProgress" && {finite _burnProgress} && {_burnProgress > 0}) then {
                    _drainMult = _drainMult * 2.0; // Burn-through actively surges power draw by an extra 2x
                };
                _drainMult
            } else {
                1.0
            };

            private _battery = player getVariable [QGVAR(ewar_backpackBattery), 100];
            private _batteryLifeSec = (EGVAR(Settings,ewar_backpackBatteryLife) max 1) * 60;
            private _drain = (0.5 / _batteryLifeSec) * 100 * _powerDrainMult;
            _battery = (_battery - _drain) max 0;
            player setVariable [QGVAR(ewar_backpackBattery), _battery, true];

            if (_battery <= 0) then {
                player setVariable [QGVAR(ewar_isPulsing), false, true];
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
    private _uavPosASL = aimPos _uav;
    if (_uavPosASL isEqualTo [0, 0, 0]) then {
        _uavPosASL = (getPosASL _uav) vectorAdd [0, 0, 1.0];
    };
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
                // Directional 3D cone mode (Option A: Pure Directional with variable beam focus)
                private _beamMode = _source getVariable [QGVAR(ewar_beamMode), 0];
                private _baseMult = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalMultiplier), 3.0];
                private _baseCone = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalConeAngle), 45];

                private _dirMult = switch (_beamMode) do {
                    case 1: { _baseMult * (5.0 / 3.0) };
                    case 2: { _baseMult * (7.5 / 3.0) };
                    default { _baseMult };
                };
                private _coneAngle = switch (_beamMode) do {
                    case 1: { _baseCone * (20 / 45) };
                    case 2: { _baseCone * (10 / 45) };
                    default { _baseCone };
                };
                private _halfAngle = _coneAngle * 0.5;
                private _effRadius = _radius * _dirMult;

                private _sourceEyePos = eyePos _source;
                private _vecToUav = _uavPosASL vectorDiff _sourceEyePos;
                private _dist = vectorMagnitude _vecToUav;

                if (_dist <= _effRadius && {_dist > 0.1}) then {
                    private _rawDir = _source weaponDirection (currentWeapon _source);
                    if (_rawDir isEqualTo [] || {_rawDir isEqualTo [0, 0, 0]}) then {
                        _rawDir = eyeDirection _source;
                    };
                    if (_rawDir isEqualTo [] || {_rawDir isEqualTo [0, 0, 0]}) then {
                        _rawDir = [0, 1, 0];
                    };
                    private _aimDir = vectorNormalized _rawDir;

                    private _uavDir = vectorNormalized _vecToUav;
                    private _dot = ((_aimDir vectorDotProduct _uavDir) max -1) min 1;
                    if (!finite _dot) then { _dot = 0; };
                    private _angleDeg = acos _dot;

                    if (_angleDeg <= _halfAngle) then {
                        private _terrainBlocked = terrainIntersectASL [_sourceEyePos, _uavPosASL];
                        if (!_terrainBlocked) then {
                            private _objBlocked = lineIntersects [_sourceEyePos, _uavPosASL, _source, _uav];
                            private _burnLevel = (_uav getVariable [QGVAR(ewar_burnIntensity), 0]) max 0 min 1;
                            if (!finite _burnLevel) then { _burnLevel = 0; };
                            private _baseIntensity = 0.25 + (0.55 * (1 - (_dist / (_effRadius max 1))));
                            private _intensity = if (_objBlocked) then {
                                // Penetrating interference when obstructed by objects/foliage (scaled by burn level)
                                ((_baseIntensity * 0.50) + ((0.85 - (_baseIntensity * 0.50)) * (_burnLevel ^ 1.2))) min 0.85
                            } else {
                                (_baseIntensity + ((1.0 - _baseIntensity) * (_burnLevel ^ 1.2))) min 1.0
                            };
                            if (!finite _intensity) then { _intensity = 0; };
                            if (_intensity > _maxIntensity) then {
                                _maxIntensity = _intensity;
                            };
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
                            private _rawInt = 0.84 * (1 - ((_dist - _coreDist) / ((_radius - _coreDist) max 1)));
                            private _srcASL = if (_source isEqualType objNull) then {
                                private _ap = aimPos _source;
                                if (_ap isEqualTo [0, 0, 0]) then { (getPosASL _source) vectorAdd [0, 0, 1.5] } else { _ap }
                            } else {
                                (ATLToASL _source) vectorAdd [0, 0, 1.5]
                            };
                            if (terrainIntersectASL [_srcASL, _uavPosASL]) then {
                                _rawInt * 0.25
                            } else {
                                _rawInt
                            }
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
