#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A, SPC.Turn.J
 * This function load all Cav modules. Requires Zen Mod to run propperly. The function will terminate if not.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_init_zenModuels
 *
 * Public: No
 */

if !(EGVAR(patches,usesZen)) exitWith {};
if !(EGVAR(Settings,enable7cavZeusModules)) exitWith {};

INFO("init", "Initializing custom Zen Modules.");

["TFG AI", "Enable Unit Simulation",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenModule,EnableUnitSimulation);    
    },
    "\A3\ui_f\data\map\vehicleicons\iconManVirtual_ca.paa"
] call zen_custom_modules_fnc_register;


["TFG Logistics", "Spawn Starter Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenModule,CreateStarterCrate);    
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

// ["TFG Logistics", "Rekit Vehicle",
//     {
//         params ["_modulePos", "_objectPos"];
//         [_modulePos, _objectPos] call EFUNC(zenModule,RekitVehicle);    
//     },
//     "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
// ] call zen_custom_modules_fnc_register;

// Check if increase training on location is true then add option.
// if (ace_medical_treatment_locationsBoostTraining) then {
//     ["TFG Logistics", "Field Hospital",
//         {
//             params ["_modulePos", "_objectPos"];
//             [_modulePos, _objectPos] call EFUNC(zenModule,CreateFieldHospital);
//         },
//         "\z\ACE\addons\medical_gui\ui\cross.paa"
//     ] call zen_custom_modules_fnc_register;
// };

["TFG Logistics", "Spawn Re-supply Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenModule,CreateSupplyCrate);
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;


["TFG Mission", "Call Endex",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenModule,CallEndex);
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;


["TFG EWAR", "Create Jammer Area",
    {
        params ["_modulePos", "_objectPos"];
        [
            "Create EWAR Jammer Area",
            [
                ["SLIDER", ["Jamming Radius (m)", "Outer radius of the jamming bubble in meters"], [50, 1500, 300, 0], false],
                ["SLIDER", ["Core Cut Ratio", "Inner fraction of radius where link is completely severed (0 = interference only)"], [0, 0.9, 0, 2], false],
                ["COMBO", ["Exempt Side", "Faction unaffected by this jammer"], [[sideUnknown, west, east, independent, civilian], ["None (Affect All)", "BLUFOR", "OPFOR", "Independent", "Civilian"], 0], false]
            ],
            {
                params ["_dialogValues", "_args"];
                _dialogValues params ["_radius", "_coreRatio", "_sideExempt"];
                _args params ["_posATL"];
                [_posATL, round _radius, _coreRatio, _sideExempt] call FUNC(ewar_addJammer);
                [format ["Created EWAR jammer bubble (%1m radius)", round _radius]] call zen_common_fnc_showMessage;
            },
            {},
            [ASLToATL _modulePos]
        ] call zen_dialog_fnc_create;
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG EWAR", "Attach Jammer to Object",
    {
        params ["_modulePos", "_objectPos"];
        if (isNull _objectPos) exitWith {
            ["Select a vehicle or object to attach the jammer to"] call zen_common_fnc_showMessage;
        };
        [
            "Attach EWAR Jammer to Object",
            [
                ["SLIDER", ["Jamming Radius (m)", "Outer radius of the jamming bubble in meters"], [50, 1500, 300, 0], false],
                ["SLIDER", ["Core Cut Ratio", "Inner fraction of radius where link is completely severed (0 = interference only)"], [0, 0.9, 0, 2], false],
                ["COMBO", ["Exempt Side", "Faction unaffected by this jammer"], [[sideUnknown, west, east, independent, civilian], ["None (Affect All)", "BLUFOR", "OPFOR", "Independent", "Civilian"], 0], false]
            ],
            {
                params ["_dialogValues", "_args"];
                _dialogValues params ["_radius", "_coreRatio", "_sideExempt"];
                _args params ["_targetObj"];
                if (isNull _targetObj) exitWith {};
                [_targetObj, round _radius, _coreRatio, _sideExempt] call FUNC(ewar_addJammer);
                [format ["Attached EWAR jammer (%1m radius) to %2", round _radius, getText (configOf _targetObj >> "displayName")]] call zen_common_fnc_showMessage;
            },
            {},
            [_objectPos]
        ] call zen_dialog_fnc_create;
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG EWAR", "Equip Jammer Backpack (AI)",
    {
        params ["_modulePos", "_objectPos"];
        if (isNull _objectPos || {!(_objectPos isKindOf "CAManBase")} || {!alive _objectPos}) exitWith {
            ["Select a living soldier to equip the EWAR Jammer Backpack"] call zen_common_fnc_showMessage;
        };

        private _unitSide = side (group _objectPos);
        private _defaultSideIdx = switch (_unitSide) do {
            case west: { 1 };
            case east: { 2 };
            case independent: { 3 };
            case civilian: { 4 };
            default { 0 };
        };

        private _defaultBagIdx = switch (_unitSide) do {
            case west: { 0 };
            case east: { 4 };
            case independent: { 6 };
            default { 3 };
        };

        [
            "Equip EWAR Jammer Backpack (AI)",
            [
                [
                    "COMBO",
                    ["Radio Pack Camo", "Select Radio Pack variant to equip on the unit"],
                    [
                        [
                            "B_RadioBag_01_mtp_F",
                            "B_RadioBag_01_wdl_F",
                            "B_RadioBag_01_tropic_F",
                            "B_RadioBag_01_black_F",
                            "B_RadioBag_01_hex_F",
                            "B_RadioBag_01_ghex_F",
                            "B_RadioBag_01_digi_F",
                            "B_RadioBag_01_eaf_F",
                            "B_RadioBag_01_oucamo_F"
                        ],
                        [
                            "Radio Pack (MTP)",
                            "Radio Pack (Woodland)",
                            "Radio Pack (Tropic)",
                            "Radio Pack (Black)",
                            "Radio Pack (Hex)",
                            "Radio Pack (Green Hex)",
                            "Radio Pack (AAF Digital)",
                            "Radio Pack (LDF Geometric)",
                            "Radio Pack (Urban)"
                        ],
                        _defaultBagIdx
                    ],
                    false
                ],
                ["SLIDER", ["Jamming Radius (m)", "Outer radius of the jamming bubble in meters"], [50, 1500, 200, 0], false],
                ["SLIDER", ["Core Cut Ratio", "Inner fraction of radius where link is completely severed (0.375 = 75m at 200m)"], [0, 0.9, 0.375, 3], false],
                ["COMBO", ["Exempt Side", "Faction unaffected by this jammer"], [[sideUnknown, west, east, independent, civilian], ["None (Affect All)", "BLUFOR", "OPFOR", "Independent", "Civilian"], _defaultSideIdx], false]
            ],
            {
                params ["_dialogValues", "_args"];
                _dialogValues params ["_bagClass", "_radius", "_coreRatio", "_sideExempt"];
                _args params ["_unit"];
                if (isNull _unit || {!alive _unit}) exitWith {};

                if ((toLower (backpack _unit)) find "b_radiobag_01" == -1) then {
                    removeBackpackGlobal _unit;
                    _unit addBackpackGlobal _bagClass;
                };

                [_unit] call FUNC(ewar_removeJammer);
                private _jammerID = [_unit, round _radius, _coreRatio, _sideExempt] call FUNC(ewar_addJammer);
                _unit setVariable [QGVAR(ewar_isJammerActive), true, true];
                _unit setVariable [QGVAR(ewar_jammerID), _jammerID, true];

                [format ["Equipped EWAR Jammer Backpack (%1m radius) on %2", round _radius, name _unit]] call zen_common_fnc_showMessage;
            },
            {},
            [_objectPos]
        ] call zen_dialog_fnc_create;
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG EWAR", "Remove Nearby Jammers",
    {
        params ["_modulePos", "_objectPos"];
        if (!isNull _objectPos) then {
            private _attachedID = _objectPos getVariable [QGVAR(ewar_jammerID), ""];
            if (_attachedID != "") exitWith {
                [_objectPos] call FUNC(ewar_removeJammer);
                ["Removed EWAR jammer from object"] call zen_common_fnc_showMessage;
            };
        };

        private _posATL = ASLToATL _modulePos;
        private _removedCount = 0;
        if (!isNil QGVAR(ewar_jammers)) then {
            private _toRemove = [];
            {
                _x params ["_id", "_source"];
                private _jPos = if (_source isEqualType objNull) then {
                    if (isNull _source) then { [0, 0, 0] } else { getPosATL _source }
                } else {
                    _source
                };
                if (_jPos isNotEqualTo [0, 0, 0] && {(_posATL distance _jPos) <= 100}) then {
                    _toRemove pushBack _id;
                };
            } forEach GVAR(ewar_jammers);

            {
                [_x] call FUNC(ewar_removeJammer);
                _removedCount = _removedCount + 1;
            } forEach _toRemove;
        };
        [format ["Removed %1 EWAR jammer(s) within 100m", _removedCount]] call zen_common_fnc_showMessage;
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;



INFO("init", "Custom Zen Modules initialization complete");
