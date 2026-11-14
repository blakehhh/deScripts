#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Periodic monitor (runs exclusively on the server) that:
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

if (!isServer) exitWith {};
if !(EGVAR(Settings,ewar_enable)) exitWith {};

// Prune stale jammers whose source object/player disconnected or was deleted
if (!isNil QGVAR(ewar_jammers) && {GVAR(ewar_jammers) isNotEqualTo []}) then {
    private _beforeCount = count GVAR(ewar_jammers);
    GVAR(ewar_jammers) = GVAR(ewar_jammers) select {
        private _src = _x select 1;
        !((_src isEqualType objNull) && {isNull _src})
    };
    if ((count GVAR(ewar_jammers)) != _beforeCount) then {
        publicVariable QGVAR(ewar_jammers);
    };
};

// Sanitize orphaned directional burn state if locking operator died, holstered, or disconnected
{
    if (!isNull _x && {(_x getVariable [QGVAR(ewar_burnIntensity), 0]) > 0}) then {
        private _op = _x getVariable [QGVAR(ewar_burnOperator), objNull];
        if (isNull _op || {!alive _op} || {((toLower (currentWeapon _op)) find "hgun_esd_01") == -1}) then {
            _x setVariable [QGVAR(ewar_burnIntensity), nil, true];
            _x setVariable [QGVAR(ewar_burnOperator), nil, true];
        };
    };
} forEach allUnitsUAV;

// Helper to check if a UAV is currently inside any active jammer's hard kill zone
private _fnc_isUavInCritZone = {
    params ["_uav", "_uavSide"];

    if (isNil QGVAR(ewar_jammers) || {GVAR(ewar_jammers) isEqualTo []}) exitWith { false };

    private _uavPos = getPosATL _uav;
    private _uavPosASL = aimPos _uav;
    if (_uavPosASL isEqualTo [0, 0, 0]) then {
        _uavPosASL = (getPosASL _uav) vectorAdd [0, 0, 1.0];
    };
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
                // Directional Spectrum Device: Verify matching locking operator, dynamic max range, and full burn-through lock
                private _maxDirRange = _radius * ((missionNamespace getVariable [QEGVAR(Settings,ewar_directionalMultiplier), 3.0]) * 2.5);
                if (
                    ((_uav getVariable [QGVAR(ewar_burnIntensity), 0]) >= 1.0) &&
                    {(_uav getVariable [QGVAR(ewar_burnOperator), objNull]) isEqualTo _source} &&
                    {(_uavPos distance (getPosATL _source)) <= _maxDirRange}
                ) then {
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
                        private _sourcePosASL = if (_source isEqualType objNull) then {
                            if (_isMan) then {
                                eyePos _source
                            } else {
                                private _ap = aimPos _source;
                                if (_ap isEqualTo [0, 0, 0]) then { (getPosASL _source) vectorAdd [0, 0, 1.5] } else { _ap }
                            };
                        } else {
                            (ATLToASL _source) vectorAdd [0, 0, 1.5]
                        };
                        if !(terrainIntersectASL [_sourcePosASL, _uavPosASL]) then {
                            _inCrit = true;
                        };
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
        if (!isNull _uav && {alive _uav} && {!(_uav getVariable [QGVAR(ewar_isFailsafeActive), false])} && {!(_uav getVariable [QGVAR(ewar_permanentlyDisabled), false])}) then {
            private _uavSide = if (count (crew _uav) > 0) then { side (group ((crew _uav) select 0)) } else { side _uav };
            if (_uavSide != civilian && {_uavSide != sideUnknown}) then {
                if ([_uav, _uavSide] call _fnc_isUavInCritZone) then {
                    if (local _uav) then {
                        [_uav] call FUNC(ewar_executeFailsafe);
                    } else {
                        [QGVAR(ewar_executeDroneFailsafe), [_uav], _uav] call CBA_fnc_targetEvent;
                    };
                };
            };
        };
    } forEach allUnitsUAV;
};

// 2. Check existing jammed drones for recovery once clear of all active crit zones
if (isNil QGVAR(ewar_jammedDrones) || {GVAR(ewar_jammedDrones) isEqualTo []}) exitWith {};

GVAR(ewar_jammedDrones) = GVAR(ewar_jammedDrones) select {
    !isNull _x && {alive _x} && {!(_x getVariable [QGVAR(ewar_permanentlyDisabled), false])}
};

{
    private _uav = _x;
    private _origSide = _uav getVariable [QGVAR(ewar_originalSide), sideUnknown];
    if !([_uav, _origSide] call _fnc_isUavInCritZone) then {
        if (local _uav) then {
            [_uav] call FUNC(ewar_restoreDroneSide);
        } else {
            [QGVAR(ewar_restoreDroneSide), [_uav], _uav] call CBA_fnc_targetEvent;
        };
    };
} forEach (+GVAR(ewar_jammedDrones));
