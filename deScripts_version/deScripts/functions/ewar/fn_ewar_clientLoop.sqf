#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Client-side evaluation loop for EWAR drone jamming.
 * Runs periodically to check if the player's connected UAV is inside any jamming bubble.
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
};

private _uav = getConnectedUAV player;
if (isNull _uav) exitWith {
    if (GVAR(ewar_activeFX)) then {
        call FUNC(ewar_clearFX);
    };
};

private _maxIntensity = 0;

if (!isNil QGVAR(ewar_jammers) && {GVAR(ewar_jammers) isNotEqualTo []}) then {
    private _uavPos = getPosATL _uav;
    private _uavSide = if (!isNull (driver _uav)) then { side (group (driver _uav)) } else { side (group player) };

    {
        _x params ["_id", "_source", "_radius", "_coreRatio", "_sideExempt"];

        private _isExempt = if (_sideExempt isEqualType []) then {
            _uavSide in _sideExempt
        } else {
            _uavSide isEqualTo _sideExempt
        };

        if (!_isExempt && {_radius > 0}) then {
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
    } forEach GVAR(ewar_jammers);
};

if (_maxIntensity <= 0 && {!(cameraOn isEqualTo _uav)}) exitWith {
    if (GVAR(ewar_activeFX)) then {
        call FUNC(ewar_clearFX);
    };
};

[_uav, _maxIntensity] call FUNC(ewar_applyInterference);
