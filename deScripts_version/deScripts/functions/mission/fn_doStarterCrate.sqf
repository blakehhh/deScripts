#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A (Modified by Antigravity)
 * Initializes a master starter/equipment crate.
 * Attaches physical logistics, functional actions (Heal, Eat Meal, Role Permissions),
 * anti-transport protection, area debris cleanup, and optional ACE Arsenal / Loadouts.
 *
 * Arguments:
 * 0: Object              <OBJECT>  Target crate or object.
 * 1: Selection Scale     <STRING>  (Optional, default: "none")
 *                                  - "none" / "manual" : Generic title ("Equipment Crate"), preserves 3DEN editor cargo, skips server logistics.
 *                                  - "tfg"  / "tfg default" : Title "TFG Equipment Crate", loads tfg_default logistics template.
 *                                  - "all" / "full"    : Generic title ("Equipment Crate"), loads all default logistics.
 * 2: ReGear Action       <BOOL>    (Deprecated/Unused) Kept for positional parameter compatibility.
 * 3: Heal Action         <BOOL>    (Optional, default: true)  Adds ACE full-heal action.
 * 4: Insignia Selection  <BOOL>    (Deprecated/Unused) Kept for positional parameter compatibility.
 * 5: Allow All Loadouts  <BOOL>    (Optional, default: false) Show all loadout categories when CfgLoadouts is active.
 * 6: Arsenal             <BOOL>    (Optional, default: false) Enable ACE Arsenal on the crate with mission blacklist.
 *
 * Return Value:
 * None
 *
 * Example:
 * [this] call deScripts_fnc_doStarterCrate;
 * [this, "tfg"] call deScripts_fnc_doStarterCrate;
 * [this, "none"] call deScripts_fnc_doStarterCrate;
 */

params [
    ["_object", objNull, [objNull]],
    ["_quickSelectScale", "none", [""]],
    ["_reGearOption", false, [true]],
    ["_reHealOption", true, [true]],
    ["_InsigniaSelectOption", false, [true]],
    ["_allowAllLoadouts", false, [false]],
    ["_arsenal", false, [false]]
];

INFO_2("StarterCrate", "Starting to apply functions to %1 (%2)", _object, typeOf _object);

// Lowercase
_quickSelectScale = toLower(_quickSelectScale);

// If isServer call equipBase (skip if manual/none to preserve 3DEN cargo and avoid empty server logistics thread)
if (isServer && {!(_quickSelectScale in ["none", "manual", ""])}) then {
    [{!isNil{EGVAR(DATABASE,DONE)} && EGVAR(DATABASE,DONE);}, {
        _this params ["_object", "_quickSelectScale"];
        [_object, _quickSelectScale] call FUNC(doStarterCrateSupplies);
    }, [_object, _quickSelectScale]] call CBA_fnc_waitUntilAndExecute;
};

// Format the crate's display title for the top action menu header
private _crateName = switch (true) do {
    case (_quickSelectScale in ['none', 'all', 'full', 'manual']): { " " };
    case (_quickSelectScale in ['tfg default', 'tfg']): { " TFG " };
    default { format [" %1 ", [_quickSelectScale] call CBA_fnc_capitalize] };
};
_object addAction [format ["<img image='deScripts\Data\Icon\icon_00.paa' /> %1Equipment Crate", _crateName], {}, [], 1.5, true, true, "", "true", 5];

// Call addHeal option
if (_reHealOption) then {
    [_object] call FUNC(addHeal);
};

// Call Quick Selection only when CfgLoadouts has active loadout definitions
if (isClass (missionConfigFile >> "CfgLoadouts") && {count ("true" configClasses (missionConfigFile >> "CfgLoadouts")) > 0}) then {
    if (!(_quickSelectScale in ["manual", "none"])) then {
        [_object, "ACE_MainActions", _allowAllLoadouts] call FUNC(setupLoadoutSelection);
    };
};


// Add Eat Meal and Role Permissions interactions
[_object] call FUNC(addEatMeal);
[_object] call FUNC(addRolePermissions);

// Make end of options line.
_object addAction ["---", {}, [], 1.5, true, true, "", "true", 5];

// Disable slingload
_object enableRopeAttach false;

// Make object not loadable in ACE
[_object, -1] call ace_cargo_fnc_setSize;

// Make Starter crate clean junk around it
[_object, 15] call FUNC(deleteDroppedObjects);



// Add save gear eventHandler
[_object, "ContainerClosed", {
    player call EFUNC(gear,saveLoadout);
}] call CBA_fnc_addBISEventHandler;

// Handle Arsenal
if (_arsenal) then {
    // Add all virtual items to the box locally on each client
    [_object, true, false] call ace_arsenal_fnc_initBox;
    
    // Define the blacklist
    private _blacklist = GVAR(BLACKLIST);
    [_object, _blacklist, false] call ace_arsenal_fnc_removeVirtualItems;
};

