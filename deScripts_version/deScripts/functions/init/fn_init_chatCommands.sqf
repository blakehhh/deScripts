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
