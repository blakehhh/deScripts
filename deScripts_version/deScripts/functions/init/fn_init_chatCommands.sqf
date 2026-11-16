#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This function handle all our custom chat commands
 *
 * Example:
 * call deScripts_fnc_init_ChatCommands
 *
 * Public: No
 */

// Help and diagnostic commands
["deScripts", {
    systemChat format["deScripts version: %1", VERSION];
}, "all"] call CBA_fnc_registerChatCommand;

["debug", {
    if (!isServer && {!(serverCommandAvailable "#kick")} && {isNull (getAssignedCuratorLogic player)}) exitWith {
        systemChat "[deScripts] Admin or Zeus privileges required for #debug.";
    };
    private _newState = !(missionNamespace getVariable [QGVAR(debugMode), false]);
    missionNamespace setVariable [QGVAR(debugMode), _newState];
    systemChat format ["[deScripts] Debug logging %1.", if (_newState) then {"ENABLED"} else {"DISABLED"}];
}, "all"] call CBA_fnc_registerChatCommand;

["metrics", {
    if (!isServer && {!(serverCommandAvailable "#kick")} && {isNull (getAssignedCuratorLogic player)}) exitWith {
        systemChat "[deScripts] Admin or Zeus privileges required for #metrics.";
    };
    [clientOwner] remoteExec [QFUNC(getServerMetrics), 2, false];
}, "all"] call CBA_fnc_registerChatCommand;
