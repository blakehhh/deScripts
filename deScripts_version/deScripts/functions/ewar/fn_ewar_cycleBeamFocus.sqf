#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Cycles or sets the directional beam focus mode on the player's EWAR system,
 * playing an ACE weapon attachment animation and swapping the 3D muzzle antenna
 * on the Spectrum Device (hgun_esd_01_F).
 *
 * Mode 0: Wide (45 deg, 3.0x range = 600m, 3x drain) -> muzzle_antenna_01_f
 * Mode 1: Focused (20 deg, 5.0x range = 1000m, 4x drain) -> muzzle_antenna_02_f
 * Mode 2: Spot (10 deg, 7.5x range = 1500m, 5x drain) -> muzzle_antenna_03_f
 *
 * Arguments:
 * 0: Target unit (player) <OBJECT>
 * 1: Step offset (+1 / -1) or exact mode index (0..2) <NUMBER>
 * 2: Set exact mode index instead of stepping (optional, default false) <BOOL>
 *
 * Return Value:
 * Target beam mode index <NUMBER>
 *
 * Example:
 * [player, 1, false] call deScripts_fnc_ewar_cycleBeamFocus
 * [player, 2, true] call deScripts_fnc_ewar_cycleBeamFocus
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_val", 1, [0]],
    ["_isExact", false, [false]]
];

if (isNull _unit || {_unit != player}) exitWith { 0 };

private _curMode = _unit getVariable [QGVAR(ewar_beamMode), 0];
private _newMode = if (_isExact) then {
    (_val max 0) min 2
} else {
    (_curMode + _val + 3) mod 3
};

if (_newMode == _curMode) exitWith {
    playSoundUI ["cba_ui_empty", 0.35, 1.0];
    [5] call FUNC(ewar_updateBackpackHUD);
    _curMode
};

if (_unit getVariable [QGVAR(ewar_isSwappingAntenna), false]) exitWith {
    _curMode
};

private _antennaClass = switch (_newMode) do {
    case 1: { "muzzle_antenna_02_f" };
    case 2: { "muzzle_antenna_03_f" };
    default { "muzzle_antenna_01_f" };
};

private _barTitle = switch (_newMode) do {
    case 1: { "Mounting Cross-Dipole Array (20° / 1000m)..." };
    case 2: { "Installing Jammer Radome Tube (10° / 1500m)..." };
    default { "Attaching Military Horn Paddle (45° / 600m)..." };
};

private _fnc_applySwap = {
    params ["_targetUnit", "_modeIndex", "_muzzleClass"];

    _targetUnit setVariable [QGVAR(ewar_isSwappingAntenna), false];
    _targetUnit setVariable [QGVAR(ewar_beamMode), _modeIndex, true];

    if (((toLower (handgunWeapon _targetUnit)) find "hgun_esd_01") != -1) then {
        {
            if (((toLower _x) find "muzzle_antenna_") != -1) then {
                _targetUnit removeHandgunItem _x;
            };
        } forEach (handgunItems _targetUnit);

        _targetUnit addHandgunItem _muzzleClass;
    };

    private _pitch = 1.35 + (_modeIndex * 0.25);
    playSoundUI ["cba_ui_empty", 0.5, _pitch];
    [5] call FUNC(ewar_updateBackpackHUD);
};

if (EGVAR(patches,usesACE)) then {
    _unit setVariable [QGVAR(ewar_isSwappingAntenna), true];
    _unit playAction "GestureReloadPistol";
    playSoundUI ["cba_ui_empty", 0.4, 0.85];

    [
        2.0,
        [_unit, _newMode, _antennaClass, _fnc_applySwap],
        {
            params ["_args"];
            _args params ["_u", "_m", "_ant", "_fn"];
            [_u, _m, _ant] call _fn;
        },
        {
            params ["_args"];
            _args params ["_u"];
            _u setVariable [QGVAR(ewar_isSwappingAntenna), false];
            playSoundUI ["cba_ui_empty", 0.4, 0.6];
        },
        _barTitle,
        {
            params ["_args"];
            _args params ["_u"];
            alive _u && {((toLower (currentWeapon _u)) find "hgun_esd_01" != -1) || {((toLower (handgunWeapon _u)) find "hgun_esd_01" != -1)}}
        },
        ["isNotInside", "isNotSitting"]
    ] call ace_common_fnc_progressBar;
} else {
    [_unit, _newMode, _antennaClass] call _fnc_applySwap;
};

_newMode
