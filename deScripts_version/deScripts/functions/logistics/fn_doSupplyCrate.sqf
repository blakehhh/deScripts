#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A, J.Turn
 * This populats a given object with items.
 * Use for mission resupplies.
 *
 * Arguments:
 * 0: Module Position <ARRAY> (Default: [0.0,0.0,0.0])
 * 1: Crate Type <STRING> (Default: "crate_resupply_general")
 *
 * Example:
 * [[0.0,0.0,0.0],"crate_resupply_general"] call deScripts_fnc_doSupplyCrate;
 * [[0.0,0.0,0.0],"crate_medicalAtlas"] call deScripts_fnc_doSupplyCrate;
 */

if (!isServer) exitWith {};

params [
    ["_modulePos", [0.0,0.0,0.0], [[0.0,0.0,0.0]]], 
    ["_crateType","crate_resupply_general",[""]]
];

// Crate model changes based on container of the crate
private _crateModel = "";

switch (_crateType) do {
    case "crate_medicalAtlas";
    case "crate_medicalInfantry": {
        _crateModel = "ace_medicalSupplyCrate";
    };
    case "crate_stinger": {
        _crateModel = "Box_NATO_WpsLaunch_F";
    };
    default {
        _crateModel = "Box_NATO_Equip_F";
    };
};

// Create crate at module position
INFO_2("Logistics", "Spawning %1 on %2", _crateType, _modulePos);
private _crate = _crateModel createVehicle _modulePos;

// Add items from logistics database entry
if (isServer) then {
    [{!isNil{EGVAR(DATABASE,DONE)} && EGVAR(DATABASE,DONE);}, {
        _this params ["_crate","_crateType"];
        private _container = GET_CONTAINER(_crateType);
        [_crate, _container] call FUNC(setCargo);
}, [_crate, _crateType]] call CBA_fnc_waitUntilAndExecute;
};

// Change ace characteristics of crate
[_crate, 1] call ace_cargo_fnc_setSize;
[_crate, true] call ace_dragging_fnc_setDraggable;
[_crate, true] call ace_dragging_fnc_setCarryable;

// Add object to the curator for all Zeuses
_crate call ace_zeus_fnc_addObjectToCurator;
