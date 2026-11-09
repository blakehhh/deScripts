#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Renders and updates the EWAR C-UAS Manpack RCU Mini-HUD widget on the local client.
 * Displays power status LED (Green/Red), vertical 4-segment battery icon, and header/footer.
 *
 * Arguments:
 * 0: Force transient popup duration in seconds (optional, default 0) <NUMBER>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [5] call deScripts_fnc_ewar_updateBackpackHUD
 *
 * Public: No
 */

params [["_popupSeconds", 0, [0]]];

if !(hasInterface) exitWith {};

if (_popupSeconds > 0) then {
    GVAR(ewar_hudPopupUntil) = diag_tickTime + _popupSeconds;
};

private _hasBackpack = alive player && {(toLower (backpack player)) find "b_radiobag_01" != -1};
private _isActive = player getVariable [QGVAR(ewar_isJammerActive), false];
private _battery = player getVariable [QGVAR(ewar_backpackBattery), 100];
private _showPersistent = profileNamespace getVariable [QGVAR(ewar_showHUD), true];
private _inPopupWindow = diag_tickTime < (missionNamespace getVariable [QGVAR(ewar_hudPopupUntil), 0]);
private _isLowBatteryAlert = _isActive && {EGVAR(Settings,ewar_backpackRequiresBattery)} && {_battery <= 10};

private _shouldShow = EGVAR(Settings,ewar_enable) && {_hasBackpack} && {_showPersistent || {_inPopupWindow} || {_isLowBatteryAlert}};

if (!_shouldShow) exitWith {
    if (!isNil QGVAR(ewar_backpackHUDCtrls)) then {
        {
            if (!isNull _x) then {
                ctrlDelete _x;
            };
        } forEach GVAR(ewar_backpackHUDCtrls);
        GVAR(ewar_backpackHUDCtrls) = nil;
    };
};

private _display = findDisplay 46;
if (isNull _display) exitWith {};

// Create HUD controls if not yet initialized (14 controls total)
if (isNil QGVAR(ewar_backpackHUDCtrls) || {count GVAR(ewar_backpackHUDCtrls) < 14} || {isNull (GVAR(ewar_backpackHUDCtrls) select 0)}) then {
    if (!isNil QGVAR(ewar_backpackHUDCtrls)) then {
        {
            if (!isNull _x) then {
                ctrlDelete _x;
            };
        } forEach GVAR(ewar_backpackHUDCtrls);
    };
    GVAR(ewar_backpackHUDCtrls) = [];

    private _panelW = safeZoneW * 0.092;
    private _panelH = safeZoneH * 0.120;
    private _panelX = safeZoneX + safeZoneW - _panelW - (safeZoneW * 0.012);
    private _panelY = safeZoneY + safeZoneH - _panelH - (safeZoneH * 0.085);

    private _hdrH = _panelH * 0.21;
    private _ftrH = _panelH * 0.20;
    private _bodyY = _panelY + _hdrH;
    private _bodyH = _panelH - _hdrH - _ftrH;

    // 0: Main panel background
    private _bg = _display ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
    _bg ctrlSetBackgroundColor [0.07, 0.08, 0.09, 0.85];
    _bg ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _bg;

    // 1: Header background bar
    private _hdrBg = _display ctrlCreate ["RscText", -1];
    _hdrBg ctrlSetPosition [_panelX, _panelY, _panelW, _hdrH];
    _hdrBg ctrlSetBackgroundColor [0.14, 0.16, 0.18, 0.95];
    _hdrBg ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _hdrBg;

    // 2: Header text (vertically centered)
    private _hdrTxt = _display ctrlCreate ["RscStructuredText", -1];
    _hdrTxt ctrlSetPosition [_panelX, _panelY + (_hdrH * 0.08), _panelW, _hdrH * 0.92];
    _hdrTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _hdrTxt ctrlSetStructuredText parseText "<t align='center' size='0.72' font='PuristaSemibold' color='#d8e0e8'>EWAR C-UAS</t>";
    _hdrTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _hdrTxt;

    // 3: Footer background bar
    private _ftrBg = _display ctrlCreate ["RscText", -1];
    _ftrBg ctrlSetPosition [_panelX, _panelY + _panelH - _ftrH, _panelW, _ftrH];
    _ftrBg ctrlSetBackgroundColor [0.14, 0.16, 0.18, 0.95];
    _ftrBg ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ftrBg;

    // 4: Footer text (vertically centered)
    private _ftrTxt = _display ctrlCreate ["RscStructuredText", -1];
    _ftrTxt ctrlSetPosition [_panelX, _panelY + _panelH - _ftrH + (_ftrH * 0.08), _panelW, _ftrH * 0.92];
    _ftrTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _ftrTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ftrTxt;

    // 5 & 6: Power Status LED Indicator (Bezel + Glowing Core)
    private _leftX = _panelX + (_panelW * 0.09);
    private _ledW = safeZoneW * 0.0065;
    private _ledH = safeZoneH * 0.0115;
    private _ledY = _bodyY + (_bodyH * 0.24);

    private _ledBezel = _display ctrlCreate ["RscText", -1];
    _ledBezel ctrlSetPosition [_leftX, _ledY, _ledW, _ledH];
    _ledBezel ctrlSetBackgroundColor [0.02, 0.02, 0.02, 0.95];
    _ledBezel ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ledBezel;

    private _ledPadW = safeZoneW * 0.0008;
    private _ledPadH = safeZoneH * 0.0014;
    private _ledCore = _display ctrlCreate ["RscText", -1];
    _ledCore ctrlSetPosition [_leftX + _ledPadW, _ledY + _ledPadH, _ledW - (_ledPadW * 2), _ledH - (_ledPadH * 2)];
    _ledCore ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ledCore;

    // 7: Mode & Battery Text Column (Left side)
    private _modeTxt = _display ctrlCreate ["RscStructuredText", -1];
    _modeTxt ctrlSetPosition [
        _leftX + _ledW + (_panelW * 0.02),
        _ledY - (_bodyH * 0.06),
        _panelW * 0.45,
        _bodyH * 0.36
    ];
    _modeTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _modeTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _modeTxt;

    // 8: Battery % Readout (Aligned cleanly under LED & Mode label)
    private _battTxt = _display ctrlCreate ["RscStructuredText", -1];
    _battTxt ctrlSetPosition [
        _leftX - (_panelW * 0.03),
        _bodyY + (_bodyH * 0.54),
        _panelW * 0.54,
        _bodyH * 0.36
    ];
    _battTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _battTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battTxt;

    // 9..11: Vertical Battery Icon (Centered vertically inside body cavity)
    private _battW = _panelW * 0.22;
    private _battH = _bodyH * 0.68;
    private _capW = _battW * 0.44;
    private _capH = _bodyH * 0.065;
    private _totalBattH = _battH + _capH;

    private _battX = _panelX + (_panelW * 0.67);
    private _capTopY = _bodyY + ((_bodyH - _totalBattH) / 2);
    private _battY = _capTopY + _capH;

    // 9: Top terminal cap
    private _battCap = _display ctrlCreate ["RscText", -1];
    _battCap ctrlSetPosition [_battX + ((_battW - _capW) / 2), _capTopY, _capW, _capH];
    _battCap ctrlSetBackgroundColor [0.85, 0.88, 0.90, 0.9];
    _battCap ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battCap;

    // 10: Outer battery casing
    private _battOuter = _display ctrlCreate ["RscText", -1];
    _battOuter ctrlSetPosition [_battX, _battY, _battW, _battH];
    _battOuter ctrlSetBackgroundColor [0.85, 0.88, 0.90, 0.9];
    _battOuter ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battOuter;

    // 11: Inner hollow cavity
    private _borderW = safeZoneW * 0.0012;
    private _borderH = safeZoneH * 0.002;
    private _innerX = _battX + _borderW;
    private _innerY = _battY + _borderH;
    private _innerW = _battW - (_borderW * 2);
    private _innerH = _battH - (_borderH * 2);

    private _battInner = _display ctrlCreate ["RscText", -1];
    _battInner ctrlSetPosition [_innerX, _innerY, _innerW, _innerH];
    _battInner ctrlSetBackgroundColor [0.09, 0.10, 0.12, 0.95];
    _battInner ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battInner;

    // 12..15: 4 Stacked Horizontal Battery Bars (Index 12 = bottom 25%, Index 15 = top 100%)
    private _padX = _innerW * 0.13;
    private _padY = _innerH * 0.09;
    private _gapY = _innerH * 0.06;
    private _segW = _innerW - (_padX * 2);
    private _segH = (_innerH - (_padY * 2) - (_gapY * 3)) / 4;

    for "_i" from 0 to 3 do {
        private _seg = _display ctrlCreate ["RscText", -1];
        private _segY = (_innerY + _innerH - _padY - _segH) - (_i * (_segH + _gapY));
        _seg ctrlSetPosition [_innerX + _padX, _segY, _segW, _segH];
        _seg ctrlCommit 0;
        GVAR(ewar_backpackHUDCtrls) pushBack _seg;
    };
};

// Update dynamic values on the controls
private _ftrTxt = GVAR(ewar_backpackHUDCtrls) select 4;
private _ledCore = GVAR(ewar_backpackHUDCtrls) select 6;
private _modeTxt = GVAR(ewar_backpackHUDCtrls) select 7;
private _battTxt = GVAR(ewar_backpackHUDCtrls) select 8;

private _radius = round (EGVAR(Settings,ewar_backpackRadius));
private _isDirectional = ((toLower (currentWeapon player)) find "hgun_esd_01" != -1);
private _dirMult = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalMultiplier), 3.0];
private _coneAngle = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalConeAngle), 45];
private _targetInCone = false;

if (_isDirectional) then {
    private _effRadius = round (_radius * _dirMult);
    _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.66' font='PuristaMedium' color='#68d4f8'>RF: %1m DIR %2°</t>", _effRadius, round _coneAngle];

    if (_isActive) then {
        // Check if an enemy/unexempt drone is within the 3D cone
        private _aimDir = vectorNormalized (player weaponDirection (currentWeapon player));
        if (_aimDir isEqualTo [0, 0, 0]) then {
            _aimDir = vectorNormalized (eyeDirection player);
        };
        private _playerEye = eyePos player;
        private _halfAngle = _coneAngle * 0.5;
        private _playerSide = side (group player);

        private _nearbyUavs = _playerEye nearEntities [["Air", "Car"], _effRadius];
        {
            if (unitIsUAV _x && {alive _x}) then {
                private _uavSide = if (!isNull (driver _x)) then { side (group (driver _x)) } else { sideUnknown };
                if (_uavSide != _playerSide && {_uavSide != civilian}) then {
                    private _vec = (getPosASL _x) vectorDiff _playerEye;
                    private _dist = vectorMagnitude _vec;
                    if (_dist <= _effRadius) then {
                        private _dot = (_aimDir vectorDotProduct (vectorNormalized _vec)) max -1 min 1;
                        if ((acos _dot) <= _halfAngle) exitWith {
                            _targetInCone = true;
                        };
                    };
                };
            };
        } forEach _nearbyUavs;

        if (_targetInCone) then {
            _ledCore ctrlSetBackgroundColor [0.95, 0.85, 0.15, 1.0];
            _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.72' font='PuristaBold' color='#ffe044'>TX LOCK</t>";

            if (cameraView == "GUNNER" && {diag_tickTime > (missionNamespace getVariable [QGVAR(ewar_lastLockSound), 0]) + 0.9}) then {
                playSoundUI ["cba_ui_empty", 0.45, 1.7];
                GVAR(ewar_lastLockSound) = diag_tickTime;
            };
        } else {
            _ledCore ctrlSetBackgroundColor [0.15, 0.95, 0.25, 1.0];
            _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#88e0ff'>TX DIR</t>";
        };
    } else {
        _ledCore ctrlSetBackgroundColor [0.95, 0.15, 0.15, 1.0];
        _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#d8b8b8'>STBY DIR</t>";
    };
} else {
    _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.66' font='PuristaMedium' color='#98a6b4'>RF: %1m OMNI</t>", _radius];

    if (_isActive) then {
        _ledCore ctrlSetBackgroundColor [0.15, 0.95, 0.25, 1.0];
        _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.76' font='PuristaBold' color='#e0f4e0'>TX ON</t>";
    } else {
        _ledCore ctrlSetBackgroundColor [0.95, 0.15, 0.15, 1.0];
        _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.76' font='PuristaBold' color='#d8b8b8'>STBY</t>";
    };
};

private _pctText = if (EGVAR(Settings,ewar_backpackRequiresBattery)) then {
    format ["%1%%", round _battery]
} else {
    "INF"
};

private _drainTag = if (_isDirectional && {_isActive} && {EGVAR(Settings,ewar_backpackRequiresBattery)}) then {
    " <t size='0.62' font='PuristaMedium' color='#68d4f8'>1.5X</t>"
} else {
    ""
};

_battTxt ctrlSetStructuredText parseText format ["<t align='left' size='0.68' font='PuristaSemibold' color='#b8c4d0'>BAT: %1%2</t>", _pctText, _drainTag];

// Calculate active battery segments (0 to 4) and color matching reference image
private _effBattery = if (EGVAR(Settings,ewar_backpackRequiresBattery)) then { _battery } else { 100 };
private _activeSegs = switch (true) do {
    case (_effBattery > 75): { 4 };
    case (_effBattery > 50): { 3 };
    case (_effBattery > 25): { 2 };
    case (_effBattery > 0):  { 1 };
    default                  { 0 };
};

private _segColor = switch (_activeSegs) do {
    case 4: { [0.48, 0.80, 0.38, 0.95] }; // 100%: Green
    case 3: { [0.98, 0.90, 0.22, 0.95] }; // 75%: Yellow
    case 2: { [0.98, 0.64, 0.20, 0.95] }; // 50%: Orange
    case 1: { [0.94, 0.36, 0.36, 0.95] }; // 25%: Red
    default { [0.94, 0.36, 0.36, 0.95] };
};

private _emptySegColor = [0.20, 0.22, 0.25, 0.45];

// Flash bottom segment if battery <= 10%
private _flashBottom = _effBattery <= 10 && {_effBattery > 0};
private _flashOn = true;
if (_flashBottom) then {
    GVAR(ewar_battFlashState) = !(missionNamespace getVariable [QGVAR(ewar_battFlashState), false]);
    _flashOn = GVAR(ewar_battFlashState);
};

for "_i" from 0 to 3 do {
    private _segCtrl = GVAR(ewar_backpackHUDCtrls) select (12 + _i);
    if (_i < _activeSegs) then {
        if (_i == 0 && {_flashBottom} && {!_flashOn}) then {
            _segCtrl ctrlSetBackgroundColor [0.45, 0.15, 0.15, 0.25];
        } else {
            _segCtrl ctrlSetBackgroundColor _segColor;
        };
    } else {
        _segCtrl ctrlSetBackgroundColor _emptySegColor;
    };
};
