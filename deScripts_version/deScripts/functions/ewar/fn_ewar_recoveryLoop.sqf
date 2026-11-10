#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Periodic monitor (runs on server and clients) that:
 * 1. Evaluates all active UAVs (including autonomous AI / Zeus drones) against active jammer
 *    crit zones (both Omni and Directional cones) and triggers fail-safe when inside.
 * 2. Checks whether previously jammed drones have exited all active jammer crit zones,
 *    restoring their crew back to original faction.
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

if !(EGVAR(Settings,ewar_enable)) exitWith {};

// Helper to check if a UAV is currently inside any active jammer's hard kill zone
private _fnc_isUavInCritZone = {
    params ["_uav", "_uavSide"];

    if (isNil QGVAR(ewar_jammers) || {GVAR(ewar_jammers) isEqualTo []}) exitWith { false };

    private _uavPos = getPosATL _uav;
    private _uavPosASL = getPosASL _uav;
    private _inCrit = false;

    {
        _x params ["_id", "_source", "_radius", "_coreRatio", "_sideExempt"];

        private _isExempt = if (_sideExempt isEqualType []) then {
            _uavSide in _sideExempt
        } else {
            _uavSide isEqualTo _sideExempt
        };

        if (!_isExempt && {_radius > 0} && {_coreRatio > 0}) then {
            private _isMan = (_source isEqualType objNull) && {_source isKindOf "CAManBase"};
            private _isDirMan = _isMan && {alive _source} && {((toLower (currentWeapon _source)) find "hgun_esd_01" != -1)};

            if (_isDirMan) then {
                // Directional Spectrum Device: Burn-through dwell-time lock (progress >= 1.0)
                if ((_uav getVariable [QGVAR(ewar_burnIntensity), 0]) >= 1.0) then {
                    _inCrit = true;
                };
            } else {
                // Standard omnidirectional bubble mode (point-blank emergency kill core)
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
                        _inCrit = true;
                    };
                };
            };
        };

        if (_inCrit) exitWith {};
    } forEach GVAR(ewar_jammers);

    _inCrit
};

// 1. Evaluate all active UAVs (including autonomous AI / Zeus drones) for new crit-zone entry
if (!isNil QGVAR(ewar_jammers) && {GVAR(ewar_jammers) isNotEqualTo []}) then {
    {
        private _uav = _x;
        if (!isNull _uav && {alive _uav} && {local _uav} && {!(_uav getVariable [QGVAR(ewar_isFailsafeActive), false])}) then {
            private _uavSide = if (count (crew _uav) > 0) then { side (group ((crew _uav) select 0)) } else { side _uav };
            if (_uavSide != civilian && {_uavSide != sideUnknown}) then {
                if ([_uav, _uavSide] call _fnc_isUavInCritZone) then {
                    [_uav] call FUNC(ewar_executeFailsafe);
                };
            };
        };
    } forEach allUnitsUAV;
};

// 2. Check existing jammed drones for recovery once clear of all active crit zones
if (isNil QGVAR(ewar_jammedDrones) || {GVAR(ewar_jammedDrones) isEqualTo []}) exitWith {};

{
    private _uav = _x;
    if (isNull _uav || {!alive _uav}) then {
        [QGVAR(ewar_unregisterJammedDrone), [_uav]] call CBA_fnc_globalEvent;
    } else {
        if (local _uav) then {
            private _origSide = _uav getVariable [QGVAR(ewar_originalSide), sideUnknown];
            if !([_uav, _origSide] call _fnc_isUavInCritZone) then {
                [_uav] call FUNC(ewar_restoreDroneSide);
            };
        };
    };
} forEach GVAR(ewar_jammedDrones);
