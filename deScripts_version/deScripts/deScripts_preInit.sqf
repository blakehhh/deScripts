#include "script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This is the rules set for the mission using the cba XEH. Each setting here is alterd via cbaSettings
 */

INFO(if (is3DEN) then {"EDEN"} else {"preInit"}, "Initializing CBA Settings...");

// Check installed moduels
EGVAR(patches,usesACE)          = isClass (configFile >> "CfgPatches" >> "ace_main");
EGVAR(patches,usesACEArsenal)   = isClass (configFile >> "CfgPatches" >> "ace_arsenal");
EGVAR(patches,usesACEX)         = isClass (configFile >> "CfgPatches" >> "acex_main");
EGVAR(patches,usesKat)          = isClass (configFile >> "CfgPatches" >> "kat_main");
EGVAR(patches,usesACRE)         = isClass (configFile >> "CfgPatches" >> "acre_sys_core");
EGVAR(patches,usesTFAR)         = isClass (configFile >> "CfgPatches" >> "task_force_radio");
EGVAR(patches,usesAlive)        = isClass (configFile >> "CfgPatches" >> "ALiVE_main");
EGVAR(patches,usesZen)          = isClass (configFile >> "CfgPatches" >> "zen_main");
EGVAR(patches,usesACEAX)        = isCLass (configFile >> "CfgPatches" >> "aceax_main");

// Global Variables
EGVAR(Staging,ZoneStatus) = false;
EGVAR(Staging,showAllLoadouts) = false;
GVAR(isPlayer) = hasInterface || {isPlayer player};
GVAR(OneLife) = !isNil{(getArray (missionconfigfile >> "respawnTemplates") select 0) == "ace_spectator"};

// Backwards compatibility aliases for older compositions & missions (cScripts -> deScripts)
if (isClass (missionConfigFile >> "CfgFunctions" >> "deScripts")) then {
    {
        private _category = _x;
        if (isClass _category) then {
            {
                private _funcName = configName _x;
                private _deFunc = missionNamespace getVariable ["deScripts_fnc_" + _funcName, nil];
                if (!isNil "_deFunc") then {
                    missionNamespace setVariable ["cScripts_fnc_" + _funcName, _deFunc];
                };
            } forEach ("true" configClasses _category);
        };
    } forEach ("true" configClasses (missionConfigFile >> "CfgFunctions" >> "deScripts"));
};

cScripts_fnc_doStarterCrate = FUNC(doStarterCrate);
cScripts_fnc_addLoadoutLocker = FUNC(addLoadoutLocker);
cScripts_fnc_addArsenal = FUNC(addArsenal);
cScripts_fnc_addReGear = FUNC(addReGear);
cScripts_fnc_addHeal = FUNC(addHeal);
cScripts_fnc_setupLoadoutCategories = FUNC(setupLoadoutCategories);
cScripts_fnc_setupLoadoutSelection = FUNC(setupLoadoutSelection);
cScripts_fnc_createCargoCrate = FUNC(createCargoCrate);
cScripts_fnc_setCargoAttributes = FUNC(setCargoAttributes);

#include "initSettings.inc.sqf"

INFO(if (is3DEN) then {"EDEN"} else {"preInit"}, "Initialization of CBA Settings completed...");

// Ace Arsenal
call EFUNC(init,aceArsenal);


// Load preInit mission settings
if (is3DEN) exitWith {};
INFO("preInit", "Initializing...");


// Logistical Database
EGVAR(DATABASE,DONE) = false;
GVAR(DATABASE) = call EFUNC(init,logistics);
EGVAR(DATABASE,DONE) = true;

// Blacklist Database
GVAR(BLACKLIST) = call compileFinal preprocessFileLineNumbers "deScripts\deScripts_blacklist.sqf";
if (isNil {GVAR(BLACKLIST)}) then { GVAR(BLACKLIST) = []; };


call EFUNC(init,chatCommands);

call EFUNC(init,zenModuels);


call EFUNC(init,eventHandlers);

INFO("preInit", "Initialization completed.");
