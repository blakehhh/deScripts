#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Removes an active EWAR drone jammer by its ID or attached source object.
 *
 * Arguments:
 * 0: Jammer ID or Source Object <STRING|OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["ewar_jammer_12345_10"] call deScripts_fnc_ewar_removeJammer
 * [this] call deScripts_fnc_ewar_removeJammer
 *
 * Public: Yes
 */

params [
    ["_target", "", ["", objNull]]
];

private _jammerID = "";
if (_target isEqualType objNull) then {
    if (!isNull _target) then {
        _jammerID = _target getVariable [QGVAR(ewar_jammerID), ""];
        _target setVariable [QGVAR(ewar_jammerID), nil, true];
    };
} else {
    _jammerID = _target;
};

if (_jammerID == "") exitWith {};

[QGVAR(ewar_removeJammer), [_jammerID]] call CBA_fnc_globalEvent;
