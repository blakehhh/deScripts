#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Restores a jammed UAV's invisible crew back to its original faction/side.
 *
 * Arguments:
 * 0: UAV <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_uav] call deScripts_fnc_ewar_restoreDroneSide
 *
 * Public: No
 */

params ["_uav"];

if (isNull _uav || {!local _uav}) exitWith {};

private _origSide = _uav getVariable [QGVAR(ewar_originalSide), sideUnknown];
if (_origSide == sideUnknown) exitWith {
    _uav setVariable [QGVAR(ewar_isFailsafeActive), nil, true];
    _uav setVariable [QGVAR(ewar_burnIntensity), nil, true];
    _uav setVariable [QGVAR(ewar_burnOperator), nil, true];
    [QGVAR(ewar_unregisterJammedDrone), [_uav]] call CBA_fnc_serverEvent;
};

private _crew = crew _uav;
if (_crew isNotEqualTo []) then {
    private _origGrp = _uav getVariable [QGVAR(ewar_originalGroup), grpNull];
    if (!isNull _origGrp && {side _origGrp == _origSide}) then {
        _crew joinSilent _origGrp;
    } else {
        private _newGrp = createGroup [_origSide, true];
        _crew joinSilent _newGrp;
        _uav setVariable [QGVAR(ewar_originalGroup), _newGrp, true];
    };

    // Restore flight state & autonomy if modified during failsafe
    if (_uav isKindOf "Helicopter") then {
        _uav land "NONE";
    };
    if ((_uav isKindOf "Plane") || {_uav isKindOf "LandVehicle"} || {_uav isKindOf "Ship"}) then {
        _uav setAutonomous true;
    };
};

_uav setVariable [QGVAR(ewar_isFailsafeActive), nil, true];
_uav setVariable [QGVAR(ewar_burnIntensity), nil, true];
_uav setVariable [QGVAR(ewar_burnOperator), nil, true];
_uav setVariable [QGVAR(ewar_originalSide), nil, true];
_uav setVariable [QGVAR(ewar_originalGroup), nil, true];

[QGVAR(ewar_unregisterJammedDrone), [_uav]] call CBA_fnc_serverEvent;
