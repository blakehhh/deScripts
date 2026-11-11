#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This function adds equipment to a given item baserd on company type.
 *
 * Arguments:
 * 0: Crate <OBJECT>
 * 1: Set company type. <STRING> ["none","alpha","bravo","charlie","medical","full"]
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this] call deScripts_fnc_doStarterCrateSupplies;
 * [this,"none"] call deScripts_fnc_doStarterCrateSupplies;
 *
 */

params [
    ["_crate", objNull, [objNull]],
    ["_companySelector", "NONE"]
];

if (!isServer) exitWith {};

// Set upper case
_companySelector = toUpper(_companySelector);

// Create categories
private _officer = ["OFFICER"];
private _tfg = ["TFG DEFAULT", "TFG"];

if !(_companySelector in (["NONE", "FULL", "ALL", "MANUAL"] + _officer + _tfg)) exitWith {
    ERROR_2("StarterCrate", "%1 (Starter Crate Supplies) is using a unsupported cartegory '%2'.", _crate, _companySelector);
};

INFO_3("StarterCrate", "Applying %1 items to %2 (%3)", _companySelector, _crate, typeOf _crate);

private _container = switch (_companySelector) do {
    case "TFG";
    case "TFG DEFAULT": {GET_CONTAINER("tfg_default");};

    case "FULL";
    case "ALL": {
        private _fullContainer = [];
        {
            private _items = GET_CONTAINER(_x);
            _fullContainer append _items;
        } forEach ["tfg_default"];
    };

    case "";
    case "MANUAL";
    case "NONE": {[]};
    default {[]};
};

// If manual, none, or if no supplies are defined, do not wipe existing editor inventory
if (_companySelector in ["MANUAL", "NONE", ""] || {_container isEqualTo []}) exitWith {
    INFO_2("StarterCrate", "Preserving editor cargo for %1 (selector: %2)", _crate, _companySelector);
    true
};

[_crate, _container] call FUNC(setCargo);

true
