#include "script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This is the rules set for the mission using the cba XEH. Each setting here is alterd via cbaSettings
 */
if (is3DEN) exitWith {};

INFO("postInit", "Initializing...");


// item replacement
if (EGVAR(Settings,allowReplaceItem)) then {
    call EFUNC(init,aceItemReplace);
};


// messages 
call EFUNC(init,message);

// diary records
if (EGVAR(Settings,showDiaryRecords)) then {
    call EFUNC(init,diary);
};

// Backwards compatibility aliases for older compositions / missions
if (isNil "cScripts_fnc_doStarterCrate") then { cScripts_fnc_doStarterCrate = FUNC(doStarterCrate); };
if (isNil "cScripts_fnc_addLoadoutLocker") then { cScripts_fnc_addLoadoutLocker = FUNC(addLoadoutLocker); };
if (isNil "cScripts_fnc_addArsenal") then { cScripts_fnc_addArsenal = FUNC(addArsenal); };
if (isNil "cScripts_fnc_addHeal") then { cScripts_fnc_addHeal = FUNC(addHeal); };
if (isNil "cScripts_fnc_setupLoadoutCategories") then { cScripts_fnc_setupLoadoutCategories = FUNC(setupLoadoutCategories); };
if (isNil "cScripts_fnc_setupLoadoutSelection") then { cScripts_fnc_setupLoadoutSelection = FUNC(setupLoadoutSelection); };



INFO("postInit", "Initialization completed.");
