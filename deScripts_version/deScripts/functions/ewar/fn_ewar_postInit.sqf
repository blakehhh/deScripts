#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Post-initialization for EWAR drone jamming module.
 * Starts the recovery monitor (all machines), client-side operator loop,
 * and registers ACE self-interaction actions for the EWAR Jammer Backpack.
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

// Start recovery monitor on all machines (server & clients)
[{
    call FUNC(ewar_recoveryLoop);
}, 2.0, []] call CBA_fnc_addPerFrameHandler;

// Start client-side operator loop and ACE self-interactions only if local player interface exists
if (hasInterface) then {
    [{
        call FUNC(ewar_clientLoop);
    }, 0.5, []] call CBA_fnc_addPerFrameHandler;

    if (EGVAR(patches,usesACE)) then {
        private _ewarCategory = [
            QGVAR(ewar_backpackCategory),
            "EWAR Jammer",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\radio_ca.paa",
            {},
            {
                params ["_target", "_player"];
                EGVAR(Settings,ewar_enable) && {alive _player} && {(toLower (backpack _player)) find "b_radiobag_01" != -1}
            }
        ] call ace_interact_menu_fnc_createAction;

        ["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _ewarCategory, true] call ace_interact_menu_fnc_addActionToClass;

        private _parentPath = ["ACE_SelfActions", "ACE_Equipment", QGVAR(ewar_backpackCategory)];

        private _turnOnAction = [
            QGVAR(ewar_turnOnAction),
            "Activate Jammer",
            "",
            {
                params ["_target", "_player"];
                [_player, true] call FUNC(ewar_toggleBackpackJammer);
            },
            {
                params ["_target", "_player"];
                !(_player getVariable [QGVAR(ewar_isJammerActive), false])
            }
        ] call ace_interact_menu_fnc_createAction;

        private _turnOffAction = [
            QGVAR(ewar_turnOffAction),
            "Deactivate Jammer",
            "",
            {
                params ["_target", "_player"];
                [_player, false] call FUNC(ewar_toggleBackpackJammer);
            },
            {
                params ["_target", "_player"];
                _player getVariable [QGVAR(ewar_isJammerActive), false]
            }
        ] call ace_interact_menu_fnc_createAction;

        private _replaceBatteryAction = [
            QGVAR(ewar_replaceBatteryAction),
            "Replace Battery",
            "",
            {
                params ["_target", "_player"];
                [_player] call FUNC(ewar_reloadBackpackBattery);
            },
            {
                params ["_target", "_player"];
                private _unitItems = items _player;
                EGVAR(Settings,ewar_backpackRequiresBattery) && {("GX_UAVBattery" in _unitItems) || {"ACE_UAVBattery" in _unitItems}}
            }
        ] call ace_interact_menu_fnc_createAction;

        private _showHudAction = [
            QGVAR(ewar_showHudAction),
            "Show EWAR HUD",
            "",
            {
                profileNamespace setVariable [QGVAR(ewar_showHUD), true];
                saveProfileNamespace;
                [0] call FUNC(ewar_updateBackpackHUD);
            },
            {
                !(profileNamespace getVariable [QGVAR(ewar_showHUD), true])
            }
        ] call ace_interact_menu_fnc_createAction;

        private _hideHudAction = [
            QGVAR(ewar_hideHudAction),
            "Hide EWAR HUD",
            "",
            {
                profileNamespace setVariable [QGVAR(ewar_showHUD), false];
                saveProfileNamespace;
                GVAR(ewar_hudPopupUntil) = 0;
                [0] call FUNC(ewar_updateBackpackHUD);
            },
            {
                profileNamespace getVariable [QGVAR(ewar_showHUD), true]
            }
        ] call ace_interact_menu_fnc_createAction;

        ["CAManBase", 1, _parentPath, _turnOnAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _turnOffAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _replaceBatteryAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _showHudAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _hideHudAction, true] call ace_interact_menu_fnc_addActionToClass;
    };
};
