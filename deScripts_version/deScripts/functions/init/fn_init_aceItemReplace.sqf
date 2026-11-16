#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A
 * This function enables standardization of item use by swaping items to desired item.
 *
 * Example:
 * call deScripts_fnc_init_aceItemReplace
 *
 * Public: No
 */

if (!EGVAR(patches,usesACE)) exitWith {};

INFO("init", "Initializing Item replacement system.");

if (missionNamespace getVariable ["ace_medical_treatment_convertItems", 2] == 2) then {
    switch (EGVAR(Settings,replaceMedical)) do {
        case (1): {
            private _fakReplacement = if (EGVAR(patches,usesKat)) then {
                ["kat_IFAK"]
            } else {
                [
                    "ACE_quikclot",
                    "ACE_splint",
                    "ACE_quikclot", "ACE_quikclot", "ACE_quikclot",
                    "ACE_tourniquet"
                ]
            };
            ["FirstAidKit", _fakReplacement] call ace_common_fnc_registerItemReplacement;
            private _medikitReplacement = if (EGVAR(patches,usesKat)) then {
                ["kat_MFAK"]
            } else {
                [
                    "ACE_splint",
                    "ACE_quikclot", "ACE_quikclot", "ACE_quikclot", "ACE_quikclot", "ACE_quikclot", "ACE_quikclot",
                    "ACE_morphine", "ACE_morphine",
                    "ACE_salineIV_500", "ACE_salineIV_500",
                    "ACE_tourniquet","ACE_tourniquet",
                    "ACE_adenosine",
                    "ACE_epinephrine", "ACE_epinephrine",
                    "ACE_surgicalKit",
                    "ACE_personalAidKit"
                ]
            };
            ["Medikit", _medikitReplacement] call ace_common_fnc_registerItemReplacement;
        };
    };
};


INFO("init", "Item replacement initialization completed.");
