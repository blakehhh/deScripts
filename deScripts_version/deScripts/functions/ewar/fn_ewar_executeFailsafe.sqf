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
if (_uav getVariable [QGVAR(ewar_isFailsafeActive), false]) exitWith {};
_uav setVariable [QGVAR(ewar_isFailsafeActive), true, true];

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
    _uav setVariable [QGVAR(ewar_permanentlyDisabled), true, true];
    private _grp = group _uav;
    while {(count (waypoints _grp)) > 0} do {
        deleteWaypoint [_grp, 0];
    };
    {
        _x disableAI "MOVE";
        _x disableAI "FSM";
        _x disableAI "TARGET";
        _x disableAI "AUTOTARGET";
    } forEach (crew _uav);
    _uav setAutonomous false;
    _uav setFuel 0;
    _uav engineOn false;
};

// Realistic Mode (0):

// 1. Loitering munitions / FPV / Drone 40 (@GX - Drones & custom FPVs)
private _typeLower = toLower (typeOf _uav);
private _isDrone40 = (_uav isKindOf "gx_drones_drone40_base") || {(_typeLower find "drone40") != -1};
if (
    _isDrone40 ||
    {(_typeLower find "fpv") != -1} ||
    {_uav getVariable ["isKamikaze", false]} ||
    {_uav isKindOf "ModuleExplosive_F"}
) exitWith {
    private _wasAirborne = (!isTouchingGround _uav) && {((getPosATL _uav) select 2) > 1.5};
    _uav setVariable [QGVAR(ewar_permanentlyDisabled), true, true];
    private _grp = group _uav;
    while {(count (waypoints _grp)) > 0} do {
        deleteWaypoint [_grp, 0];
    };
    {
        _x disableAI "MOVE";
        _x disableAI "FSM";
        _x disableAI "TARGET";
        _x disableAI "AUTOTARGET";
    } forEach (crew _uav);
    _uav setAutonomous false;
    _uav setFuel 0;
    _uav engineOn false;

    if (_wasAirborne) then {
        private _fnc_detonateImpact = {
            params ["_drone", "_use40mm"];
            if (isNull _drone || {_drone getVariable [QGVAR(ewar_impactDetonated), false]}) exitWith {};
            _drone setVariable [QGVAR(ewar_impactDetonated), true];

            private _ehId = _drone getVariable [QGVAR(ewar_epeContactEH), -1];
            if (_ehId >= 0) then {
                _drone removeEventHandler ["EpeContactStart", _ehId];
                _drone setVariable [QGVAR(ewar_epeContactEH), -1];
            };

            // Only spawn impact warhead if the drone hasn't already detonated on its own
            if (alive _drone) then {
                private _ammoClass = if (_use40mm) then { "G_40mm_HE" } else { "R_PG32V_F" };
                private _ordnance = createVehicle [_ammoClass, getPosATL _drone, [], 0, "CAN_COLLIDE"];
                triggerAmmo _ordnance;
                _drone setDamage 1;
            };
        };

        _uav setVariable [QGVAR(ewar_fnc_detonateImpact), _fnc_detonateImpact];
        _uav setVariable [QGVAR(ewar_isDrone40), _isDrone40];

        private _ehId = _uav addEventHandler ["EpeContactStart", {
            params ["_object1"];
            private _fn = _object1 getVariable [QGVAR(ewar_fnc_detonateImpact), {}];
            private _use40mm = _object1 getVariable [QGVAR(ewar_isDrone40), true];
            [_object1, _use40mm] call _fn;
        }];
        _uav setVariable [QGVAR(ewar_epeContactEH), _ehId];

        [
            {
                params ["_drone"];
                isNull _drone ||
                {!alive _drone} ||
                {_drone getVariable [QGVAR(ewar_impactDetonated), false]} ||
                {isTouchingGround _drone} ||
                {((getPosATL _drone) select 2) <= 0.35} ||
                {((getPosASL _drone) select 2) <= 0.35} ||
                {
                    private _posASL = getPosASL _drone;
                    private _vel = velocity _drone;
                    private _velDir = if ((vectorMagnitude _vel) > 0.05) then { vectorNormalized _vel } else { [0, 0, -1] };
                    private _step = (_vel vectorMultiply (diag_deltaTime * 1.5)) vectorAdd (_velDir vectorMultiply 0.35);
                    private _hits = lineIntersectsSurfaces [_posASL, _posASL vectorAdd _step, _drone, driver _drone, true, 2, "FIRE", "GEOM"];
                    (_hits findIf {
                        private _hitObj = _x select 2;
                        isNull _hitObj || {!(_hitObj isEqualTo _drone) && {!(_hitObj in (crew _drone))}}
                    }) != -1
                }
            },
            {
                params ["_drone", "_use40mm", "_fn"];
                [_drone, _use40mm] call _fn;
            },
            [_uav, _isDrone40, _fnc_detonateImpact],
            30,
            {
                params ["_drone", "_use40mm", "_fn"];
                [_drone, _use40mm] call _fn;
            }
        ] call CBA_fnc_waitUntilAndExecute;
    };
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
