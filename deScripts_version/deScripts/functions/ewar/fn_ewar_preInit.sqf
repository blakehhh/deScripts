#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Pre-initialization for EWAR drone jamming module.
 * Sets up global jammer array and synchronized CBA event handlers.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_ewar_preInit
 *
 * Public: No
 */

if (isNil QGVAR(ewar_jammers)) then {
    GVAR(ewar_jammers) = [];
};

if (isNil QGVAR(ewar_jammedDrones)) then {
    GVAR(ewar_jammedDrones) = [];
};

GVAR(ewar_activeFX) = false;
GVAR(ewar_nextStaticSound) = [0];

// Event handler for synchronized jammer addition
[QGVAR(ewar_addJammer), {
    params ["_jammerData"];
    if (isNil QGVAR(ewar_jammers)) then {
        GVAR(ewar_jammers) = [];
    };
    GVAR(ewar_jammers) pushBackUnique _jammerData;
    if (isServer) then {
        publicVariable QGVAR(ewar_jammers);
    };
}] call CBA_fnc_addEventHandler;

// Event handler for synchronized jammer removal
[QGVAR(ewar_removeJammer), {
    params ["_jammerID"];
    if (isNil QGVAR(ewar_jammers)) exitWith {};
    GVAR(ewar_jammers) = GVAR(ewar_jammers) select { (_x select 0) != _jammerID };
    if (isServer) then {
        publicVariable QGVAR(ewar_jammers);
    };
}] call CBA_fnc_addEventHandler;

// Target event handler to execute physical fail-safe where the drone is local
[QGVAR(ewar_executeDroneFailsafe), {
    params ["_uav"];
    if (isNull _uav) exitWith {};
    if (!local _uav) exitWith {};
    [_uav] call FUNC(ewar_executeFailsafe);
}] call CBA_fnc_addEventHandler;

// Target event handler to restore drone side where the drone is local
[QGVAR(ewar_restoreDroneSide), {
    params ["_uav"];
    if (isNull _uav) exitWith {};
    if (!local _uav) exitWith {};
    [_uav] call FUNC(ewar_restoreDroneSide);
}] call CBA_fnc_addEventHandler;

// Event handler for registering jammed drone (Server authoritative)
[QGVAR(ewar_registerJammedDrone), {
    params ["_uav"];
    if (!isServer) exitWith {};
    if (isNull _uav) exitWith {};
    if (isNil QGVAR(ewar_jammedDrones)) then {
        GVAR(ewar_jammedDrones) = [];
    };
    GVAR(ewar_jammedDrones) pushBackUnique _uav;
}] call CBA_fnc_addEventHandler;

// Event handler for unregistering jammed drone (Server authoritative)
[QGVAR(ewar_unregisterJammedDrone), {
    params ["_uav"];
    if (!isServer) exitWith {};
    if (isNil QGVAR(ewar_jammedDrones)) exitWith {};
    GVAR(ewar_jammedDrones) = GVAR(ewar_jammedDrones) select { !isNull _x && {_x isNotEqualTo _uav} };
}] call CBA_fnc_addEventHandler;
