#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This function save players loadout
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * true or false <BOOL>
 *
 * Example:
 * [player] call deScripts_fnc_gear_saveLoadout
 *
 */

params [["_unit", objNull, [objNull]]];

private _loadout = [_unit] call CBA_fnc_getLoadout;
_loadout = [_loadout] call FUNC(filterUnitLoadout);

_unit setVariable [QEGVAR(Gear,Loadout), _loadout];
_unit setVariable [QEGVAR(Gear,SavedLoadout), true];
if (_unit == player) then {
    missionNamespace setVariable [QEGVAR(Gear,SavedPlayerLoadout), _loadout];
    private _medicClass = _unit getVariable ["ace_medical_medicClass", if (_unit getUnitTrait "medic") then {1} else {0}];
    private _engClass = _unit getVariable ["ace_isEngineer", if (_unit getUnitTrait "engineer") then {1} else {0}];
    private _isEOD = _unit getVariable ["ACE_isEOD", _unit getUnitTrait "explosiveSpecialist"];
    missionNamespace setVariable [QEGVAR(Gear,SavedPlayerTraits), [_medicClass, _engClass, _isEOD]];
};

private _insignia = _unit call BIS_fnc_getUnitInsignia;
if (_insignia != "") then {
    profileNamespace setVariable [QEGVAR(Profile,Insignia), _insignia];
};

[
    [],
    ["Loadout has been saved"],
    [""],
    [""]
] call CBA_fnc_notify;

_unit getVariable [QEGVAR(Gear,SavedLoadout), false];
