#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Toggles the EWAR jammer on the player's equipped Radio Pack backpack.
 * Updates the RCU Mini-HUD widget (and triggers a 5-second transient popup if hidden).
 *
 * Arguments:
 * 0: Target unit (player) <OBJECT>
 * 1: Desired state (optional bool, or toggle if nil) <BOOL>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [player, true] call deScripts_fnc_ewar_toggleBackpackJammer
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_state", nil]
];

if (isNull _unit || {_unit != player}) exitWith {};

private _isActive = _unit getVariable [QGVAR(ewar_isJammerActive), false];
private _newState = if (isNil "_state") then { !_isActive } else { _state };

if (_newState) then {
    private _currentBackpack = toLower (backpack _unit);
    if (_currentBackpack find "b_radiobag_01" == -1) exitWith {};

    private _battery = _unit getVariable [QGVAR(ewar_backpackBattery), 100];
    if (EGVAR(Settings,ewar_backpackRequiresBattery) && {_battery <= 0}) exitWith {
        playSoundUI ["cba_ui_empty", 0.5, 0.6];
        [5] call FUNC(ewar_updateBackpackHUD);
    };

    // Remove any existing jammer entry on the unit before registering a fresh one
    [_unit] call FUNC(ewar_removeJammer);

    private _radius = round (EGVAR(Settings,ewar_backpackRadius));
    private _coreRatio = missionNamespace getVariable [QEGVAR(Settings,ewar_backpackCoreRatio), 0.375];
    private _exemptFriendly = missionNamespace getVariable [QEGVAR(Settings,ewar_backpackExemptFriendly), true];
    private _sideExempt = if (_exemptFriendly) then { side (group _unit) } else { sideUnknown };
    private _jammerID = [_unit, _radius, _coreRatio, _sideExempt] call FUNC(ewar_addJammer);

    _unit setVariable [QGVAR(ewar_isJammerActive), true, true];
    _unit setVariable [QGVAR(ewar_jammerID), _jammerID, true];

    playSoundUI ["cba_ui_empty", 0.5, 1.2];
    [5] call FUNC(ewar_updateBackpackHUD);
} else {
    [_unit] call FUNC(ewar_removeJammer);
    _unit setVariable [QGVAR(ewar_isJammerActive), false, true];

    GVAR(ewar_burnProgress) = 0;
    private _prevTarget = missionNamespace getVariable [QGVAR(ewar_burnTarget), objNull];
    if (!isNull _prevTarget) then {
        _prevTarget setVariable [QGVAR(ewar_burnIntensity), 0, true];
    };
    GVAR(ewar_burnTarget) = objNull;

    playSoundUI ["cba_ui_empty", 0.5, 0.8];
    [5] call FUNC(ewar_updateBackpackHUD);
};
