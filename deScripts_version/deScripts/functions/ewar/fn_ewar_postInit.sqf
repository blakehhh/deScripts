#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Post-initialization for EWAR drone jamming module.
 * Starts the client-side UAV jamming evaluation loop.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_ewar_postInit
 *
 * Public: No
 */

if (is3DEN) exitWith {};
if !(hasInterface) exitWith {};

[{
    call FUNC(ewar_clientLoop);
}, 0.5, []] call CBA_fnc_addPerFrameHandler;
