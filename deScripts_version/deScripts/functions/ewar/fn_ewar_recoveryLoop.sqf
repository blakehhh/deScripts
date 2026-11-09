#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Periodic monitor that checks whether jammed drones have exited all active jammer
 * crit zones or if jammers have been destroyed, restoring their crew back to original faction.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_ewar_recoveryLoop
 *
 * Public: No
 */

if (isNil QGVAR(ewar_jammedDrones) || {GVAR(ewar_jammedDrones) isEqualTo []}) exitWith {};

{
    private _uav = _x;
    if (isNull _uav || {!alive _uav}) then {
        [QGVAR(ewar_unregisterJammedDrone), [_uav]] call CBA_fnc_globalEvent;
    } else {
        if (local _uav) then {
            private _uavPos = getPosATL _uav;
            private _origSide = _uav getVariable [QGVAR(ewar_originalSide), sideUnknown];
            private _inCritZone = false;

            if (!isNil QGVAR(ewar_jammers)) then {
                {
                    _x params ["_id", "_source", "_radius", "_coreRatio", "_sideExempt"];

                    private _isExempt = if (_sideExempt isEqualType []) then {
                        _origSide in _sideExempt
                    } else {
                        _origSide isEqualTo _sideExempt
                    };

                    if (!_isExempt && {_radius > 0} && {_coreRatio > 0}) then {
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
                            private _coreDist = _radius * (_coreRatio max 0 min 0.95);
                            if ((_uavPos distance _pos) <= _coreDist) then {
                                _inCritZone = true;
                            };
                        };
                    };

                    if (_inCritZone) exitWith {};
                } forEach GVAR(ewar_jammers);
            };

            if (!_inCritZone) then {
                [_uav] call FUNC(ewar_restoreDroneSide);
            };
        };
    };
} forEach GVAR(ewar_jammedDrones);
