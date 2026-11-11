#include "..\script_component.hpp";
/*
 * Author: SGT.Brostrom.A
 * This function apply functions to a player.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_gear_applyFunctions
 *
 */




//Server metrics
if ((call BIS_fnc_admin) >= 2) then {
    player addAction ["Server Metrics", {
        [owner player] call FUNC(getServerMetrics);
    }, [], 0, false, true];
};