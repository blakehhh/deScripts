#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Executes physical fail-safe behavior on a jammed unmanned vehicle where it is local.
 * Switches invisible crew to civilian so cTAB, ATAK, and UAV terminals drop connection.
 * Supports Vanilla, @GX - Drones, and @Arma 3 Aegis assets.
 *
 * Arguments:
 * 0: Unmanned Vehicle <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_uav] call deScripts_fnc_ewar_executeFailsafe
 *
 * Public: No
 */

params ["_uav"];

if (isNull _uav || {!local _uav}) exitWith {};

// Switch invisible AI crew to civilian so cTAB, ATAK, and UAV terminals immediately drop connection
private _crew = crew _uav;
if (_crew isNotEqualTo []) then {
    if (isNil {_uav getVariable QGVAR(ewar_originalSide)}) then {
        private _origGrp = group (_crew select 0);
        _uav setVariable [QGVAR(ewar_originalGroup), _origGrp, true];
        _uav setVariable [QGVAR(ewar_originalSide), side _origGrp, true];
    };
    private _civGroup = createGroup [civilian, true];
    _crew joinSilent _civGroup;
};

// Register in active jammed drones list for server recovery monitoring
[QGVAR(ewar_registerJammedDrone), [_uav]] call CBA_fnc_serverEvent;

// Check CBA setting mode (0: Realistic, 1: Engine Cut, 2: Terminal Disconnect Only)
private _behavior = EGVAR(Settings,ewar_failsafeBehavior);
if (_behavior == 2) exitWith {};

if (_behavior == 1) exitWith {
    _uav setHitPointDamage ["HitEngine", 1];
    _uav engineOn false;
};

// Realistic Mode (0):

// 1. Loitering munitions / FPV / Drone 40 (@GX - Drones & custom FPVs)
if (
    _uav isKindOf "gx_drones_drone40_base" ||
    {toLower (typeOf _uav) find "drone40" != -1} ||
    {_uav getVariable ["isKamikaze", false]} ||
    {_uav isKindOf "ModuleExplosive_F"}
) exitWith {
    _uav setHitPointDamage ["HitEngine", 1];
    _uav engineOn false;
};

// 2. Rotary & Micro-UAVs (AR-2 Darter, FLIR Black Hornet, Hunter, MQ-8B Fire Scout, AL-6 Pelican)
if (_uav isKindOf "Helicopter") exitWith {
    private _grp = group _uav;
    while {(count (waypoints _grp)) > 0} do {
        deleteWaypoint [_grp, 0];
    };
    _uav land "LAND";
};

// 3. Fixed-Wing UAVs (RQ-11B Raven, MQ-4A Greyhawk, UCAV Sentinel, K40 Ababil, Shikra)
if (_uav isKindOf "Plane") exitWith {
    private _grp = group _uav;
    while {(count (waypoints _grp)) > 0} do {
        deleteWaypoint [_grp, 0];
    };
    private _wp = _grp addWaypoint [getPosASL _uav, 0];
    _wp setWaypointType "LOITER";
    _wp setWaypointLoiterRadius 250;
    _wp setWaypointLoiterType "CIRCLE";
    _uav setAutonomous true;
};

// 4. Ground UGVs (THeMIS, Honeybadger, UGV Stomper, ED-1D/E Demining UGVs)
if (_uav isKindOf "LandVehicle") exitWith {
    private _grp = group _uav;
    while {(count (waypoints _grp)) > 0} do {
        deleteWaypoint [_grp, 0];
    };
    _uav setVelocity [0, 0, 0];
    _uav engineOn false;
    _uav setAutonomous false;
};

// 5. Naval USVs (Magura V5 USV)
if (_uav isKindOf "Ship") exitWith {
    private _grp = group _uav;
    while {(count (waypoints _grp)) > 0} do {
        deleteWaypoint [_grp, 0];
    };
    _uav setVelocity [0, 0, 0];
    _uav engineOn false;
    _uav setAutonomous false;
};
