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

// Map-wide civilian AI to agent conversion
if (isServer && {missionNamespace getVariable [QEGVAR(Settings,autoConvertCivAgents), false]}) then {
    [{
        {
            if (
                (side _x == civilian) &&
                {!isPlayer _x} &&
                {!(_x in playableUnits)} &&
                {isNull objectParent _x} &&
                {!(_x getVariable [QEGVAR(Agent,ignore), false])}
            ) then {
                [_x] call FUNC(makeAgent);
            };
        } forEach +allUnits;
    }] call CBA_fnc_execNextFrame;

    if !(missionNamespace getVariable [QEGVAR(Settings,autoConvertCivAgentsOnce), false]) then {
        ["CAManBase", "InitPost", {
            params ["_unit"];
            [{
                params ["_unit"];
                if (
                    !isNull _unit &&
                    {alive _unit} &&
                    {side _unit == civilian} &&
                    {!isPlayer _unit} &&
                    {!(_unit in playableUnits)} &&
                    {isNull objectParent _unit} &&
                    {!(_unit getVariable [QEGVAR(Agent,ignore), false])}
                ) then {
                    [_unit] call FUNC(makeAgent);
                };
            }, [_unit]] call CBA_fnc_execNextFrame;
        }, true, [], true] call CBA_fnc_addClassEventHandler;
    };
};

// Backwards compatibility aliases for older compositions / missions
if (isNil "cScripts_fnc_doStarterCrate") then { cScripts_fnc_doStarterCrate = FUNC(doStarterCrate); };
if (isNil "cScripts_fnc_addLoadoutLocker") then { cScripts_fnc_addLoadoutLocker = FUNC(addLoadoutLocker); };
if (isNil "cScripts_fnc_addArsenal") then { cScripts_fnc_addArsenal = FUNC(addArsenal); };
if (isNil "cScripts_fnc_addHeal") then { cScripts_fnc_addHeal = FUNC(addHeal); };
if (isNil "cScripts_fnc_setupLoadoutCategories") then { cScripts_fnc_setupLoadoutCategories = FUNC(setupLoadoutCategories); };
if (isNil "cScripts_fnc_setupLoadoutSelection") then { cScripts_fnc_setupLoadoutSelection = FUNC(setupLoadoutSelection); };



INFO("postInit", "Initialization completed.");
