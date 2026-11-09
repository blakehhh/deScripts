#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Clears any active EWAR post-processing effects and HUD signal bars on the local client.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_ewar_clearFX
 *
 * Public: No
 */

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

if (!isNil QGVAR(ewar_distortHandle)) then {
    GVAR(ewar_distortHandle) ppEffectEnable false;
    ppEffectDestroy GVAR(ewar_distortHandle);
    GVAR(ewar_distortHandle) = nil;
};

if (!isNil QGVAR(ewar_signalBars)) then {
    {
        if (!isNull _x) then {
            ctrlDelete _x;
        };
    } forEach GVAR(ewar_signalBars);
    GVAR(ewar_signalBars) = nil;
};

GVAR(ewar_activeFX) = false;
