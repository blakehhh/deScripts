#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Applies progressive visual/audio interference and 5-bar HUD signal indicator to a UAV operator,
 * and triggers the hard cutoff fail-safe at critical jamming intensity.
 *
 * Arguments:
 * 0: Connected UAV <OBJECT>
 * 1: Jamming Intensity (0.0 to 1.0) <NUMBER>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_uav, 0.65] call deScripts_fnc_ewar_applyInterference
 *
 * Public: No
 */

params ["_uav", "_intensity"];

// Hard cutoff and Fail-Safe execution (Tier 3)
if (_intensity >= 0.85) exitWith {
    [_uav] call FUNC(ewar_handleFailsafe);
};

GVAR(ewar_activeFX) = true;

// 1. Post-processing video interference & 5-bar signal HUD when looking through UAV camera optics
if (cameraOn isEqualTo _uav) then {
    if (_intensity > 0) then {
        // RF Static / Snow (FilmGrain) — fixed grainSize (2.0) so it never zooms in
        if (isNil QGVAR(ewar_grainHandle)) then {
            GVAR(ewar_grainHandle) = ppEffectCreate ["FilmGrain", 2005];
            GVAR(ewar_grainHandle) ppEffectEnable true;
            GVAR(ewar_grainHandle) ppEffectForceInNVG true;
        };
        private _normIntensity = (_intensity / 0.84) min 1.0;
        GVAR(ewar_grainHandle) ppEffectAdjust [
            _normIntensity * 0.85,
            0.15,
            2.0,
            1.0,
            1.0,
            false
        ];
        GVAR(ewar_grainHandle) ppEffectCommit 0.15;

        // Subtle Video Signal Splitting (ChromAberration)
        if (isNil QGVAR(ewar_chromHandle)) then {
            GVAR(ewar_chromHandle) = ppEffectCreate ["ChromAberration", 2006];
            GVAR(ewar_chromHandle) ppEffectEnable true;
            GVAR(ewar_chromHandle) ppEffectForceInNVG true;
        };
        private _aberration = (_normIntensity ^ 2) * 0.025;
        GVAR(ewar_chromHandle) ppEffectAdjust [_aberration, _aberration * 0.5, true];
        GVAR(ewar_chromHandle) ppEffectCommit 0.15;
    } else {
        if (!isNil QGVAR(ewar_grainHandle)) then {
            GVAR(ewar_grainHandle) ppEffectEnable false;
            ppEffectDestroy GVAR(ewar_grainHandle);
            GVAR(ewar_grainHandle) = nil;
        };
        if (!isNil QGVAR(ewar_chromHandle)) then {
            GVAR(ewar_chromHandle) ppEffectEnable false;
            ppEffectDestroy GVAR(ewar_chromHandle);
            GVAR(ewar_chromHandle) = nil;
        };
    };

    // 2. 5-Bar Signal Strength Indicator on HUD
    private _display = findDisplay 46;
    if (!isNull _display) then {
        if (isNil QGVAR(ewar_signalBars) || {GVAR(ewar_signalBars) isEqualTo []} || {isNull (GVAR(ewar_signalBars) select 0)}) then {
            GVAR(ewar_signalBars) = [];
            private _baseX = safeZoneX + safeZoneW * 0.4825;
            private _baseY = safeZoneY + safeZoneH * 0.81;
            private _barW = safeZoneW * 0.005;
            private _gap = safeZoneW * 0.0025;
            private _maxH = safeZoneH * 0.028;

            for "_i" from 0 to 4 do {
                private _ctrl = _display ctrlCreate ["RscText", -1];
                private _barH = _maxH * ((_i + 1) / 5);
                private _posX = _baseX + _i * (_barW + _gap);
                private _posY = _baseY + (_maxH - _barH);
                _ctrl ctrlSetPosition [_posX, _posY, _barW, _barH];
                _ctrl ctrlCommit 0;
                GVAR(ewar_signalBars) pushBack _ctrl;
            };
        };

        private _signalRatio = (1 - (_intensity / 0.84)) max 0 min 1;
        private _activeBars = round (_signalRatio * 5);

        {
            if (_forEachIndex < _activeBars) then {
                _x ctrlSetBackgroundColor [1, 1, 1, 0.9];
            } else {
                _x ctrlSetBackgroundColor [0.45, 0.45, 0.45, 0.35];
            };
        } forEach GVAR(ewar_signalBars);
    };
} else {
    call FUNC(ewar_clearFX);
    GVAR(ewar_activeFX) = true;
};

// 3. Audio static clicks/pops when viewing UAV feed
if (cameraOn isEqualTo _uav && {_intensity > 0.25} && {diag_tickTime > (GVAR(ewar_nextStaticSound) select 0)}) then {
    playSoundUI ["cba_ui_empty", 0.35 * _intensity, 1];
    GVAR(ewar_nextStaticSound) = [diag_tickTime + random [0.5, 1.5, 3]];
};
