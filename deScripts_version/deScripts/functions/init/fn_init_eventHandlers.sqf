#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This function add eventhandlers.
 *
 * Example:
 * call deScripts_fnc_init_eventHandlers
 *
 * Public: No
 */

INFO("InitEventHandlers","Creating Global EventHandlers");


// Player Events
if (GVAR(isPlayer)) then {
    INFO("InitEventHandlers","Creating Client EventHandlers");

    ["unit", {
        ["update"] call FUNC(loadoutLocker_marker);
    }] call CBA_fnc_addPlayerEventHandler;

    [QEGVAR(player,setRolePermissions), {
        params [
            ["_unit", objNull, [objNull]],
            ["_medic", 0, [0]],
            ["_engineer", 0, [0]],
            ["_eod", false, [false]]
        ];
        if (isNull _unit || {!local _unit}) exitWith {};

        _unit setVariable ["ace_medical_medicClass", _medic, true];
        _unit setUnitTrait ["medic", (_medic > 0)];
        _unit setVariable ["ace_isEngineer", _engineer, true];
        _unit setUnitTrait ["engineer", (_engineer > 0)];
        _unit setVariable ["ACE_isEOD", _eod, true];
        _unit setUnitTrait ["explosiveSpecialist", _eod];

        if (_unit == player) then {
            missionNamespace setVariable [QEGVAR(Gear,SavedPlayerTraits), [_medic, _engineer, _eod]];
        };
    }] call CBA_fnc_addEventHandler;

    // TODO: Possibly use in the future 
    //["ace_zeusCreated", {
    //    _this params ["_zeus"];
    //}] call CBA_fnc_addEventHandler;
    //
    //["zen_common_createZeus", {
    //    _this params ["_zeus"];
    //}] call CBA_fnc_addEventHandler;
};


// Server Events
if (!isServer) exitWith {};
INFO("InitEventHandlers","Creating Server EventHandlers");

[QEGVAR(log,text), {
    diag_log text _this;
}] call CBA_fnc_addEventHandler;