#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Replaces the UAV battery in the player's EWAR Radio Pack backpack using an ACE progress bar.
 * Supports both GX_UAVBattery (@GX - Drones) and ACE_UAVBattery (ACE3).
 *
 * Arguments:
 * 0: Player unit <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [player] call deScripts_fnc_ewar_reloadBackpackBattery
 *
 * Public: No
 */

params [["_player", objNull, [objNull]]];

if (isNull _player || {_player != player}) exitWith {};

private _unitItems = items _player;
private _hasGX = "GX_UAVBattery" in _unitItems;
private _hasACE = "ACE_UAVBattery" in _unitItems;

if (!_hasGX && {!_hasACE}) exitWith {
    playSoundUI ["ACE_Sound_Click", 0.6, 0.6];
    [5] call FUNC(ewar_updateBackpackHUD);
};

[
    4,
    [_player],
    {
        params ["_args"];
        _args params ["_unit"];

        private _currentItems = items _unit;
        if ("GX_UAVBattery" in _currentItems) then {
            _unit removeItem "GX_UAVBattery";
            _unit setVariable [QGVAR(ewar_backpackBattery), 100, false];
        } else {
            if ("ACE_UAVBattery" in _currentItems) then {
                _unit removeItem "ACE_UAVBattery";
                _unit setVariable [QGVAR(ewar_backpackBattery), 100, false];
            };
        };

        playSoundUI ["ACE_Sound_Click", 0.6, 1.0];
        [5] call FUNC(ewar_updateBackpackHUD);
    },
    {},
    "Replacing EWAR Jammer Battery...",
    {
        params ["_args"];
        _args params ["_unit"];
        private _curItems = items _unit;
        ([_unit] call GVAR(ewar_fnc_hasJammerPack)) && {("GX_UAVBattery" in _curItems) || {"ACE_UAVBattery" in _curItems}}
    }
] call ace_common_fnc_progressBar;
