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

["TFG Mission", "Add HALO Jump",
    {
        params ["_modulePos", "_objectPos"];
        if (isNull _objectPos || {!(_objectPos isKindOf "Air")}) exitWith {
            ["Place on an aircraft or helicopter"] call zen_common_fnc_showMessage;
        };
        if (!isNil {_objectPos getVariable QEGVAR(VehicleFunc,HaloAction)}) exitWith {
            ["HALO Jump action is already applied to this aircraft"] call zen_common_fnc_showMessage;
        };

        [
            "Configure HALO Jump",
            [
                ["SLIDER", ["Minimum Altitude (m)", "Minimum aircraft altitude (AGL) required to use the HALO Jump action"], [0, 10000, 5000, 0], false],
                ["COMBO", ["Parachute Backpack", "Parachute backpack equipped on jump (current backpack is stowed to chest)"], [["B_Parachute"], ["Steerable Parachute (B_Parachute)"], 0], false],
                ["CHECKBOX", ["Staggered Jump Exit", "Alternates jumpers between left (+12m) and right (-12m) rear exit offsets"], false, false]
            ],
            {
                params ["_dialogValues", "_args"];
                _dialogValues params ["_minAltitude", "_chuteBackpackClass", "_allowStaggered"];
                _args params ["_vehicle"];
                if (isNull _vehicle || {!alive _vehicle}) exitWith {};
                if (!isNil {_vehicle getVariable QEGVAR(VehicleFunc,HaloAction)}) exitWith {
                    ["HALO Jump action is already applied to this aircraft"] call zen_common_fnc_showMessage;
                };

                [_vehicle, round _minAltitude, _chuteBackpackClass, _allowStaggered] remoteExec [QFUNC(addHaloJump), 0, _vehicle];
                [format ["Added HALO Jump (Min Alt: %1m) to %2", round _minAltitude, getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName")]] call zen_common_fnc_showMessage;
            },
            {},
            [_objectPos]
        ] call zen_dialog_fnc_create;
    },
    "\A3\ui_f\data\map\vehicleicons\iconParachute_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG Mission", "Add Static Line Jump",
    {
        params ["_modulePos", "_objectPos"];
        if (isNull _objectPos || {!(_objectPos isKindOf "Air")}) exitWith {
            ["Place on an aircraft or helicopter"] call zen_common_fnc_showMessage;
        };
        if (!isNil {_objectPos getVariable QEGVAR(VehicleFunc,JumpAction)}) exitWith {
            ["Static Line Jump action is already applied to this aircraft"] call zen_common_fnc_showMessage;
        };

        [
            "Configure Static Line Jump",
            [
                ["SLIDER", ["Minimum Altitude (m)", "Lowest altitude (AGL) where the Static Line Jump action is available"], [50, 2000, 180, 0], false],
                ["SLIDER", ["Maximum Altitude (m)", "Highest altitude (AGL) where the Static Line Jump action is available"], [100, 5000, 350, 0], false],
                ["SLIDER", ["Maximum Speed (km/h)", "Maximum aircraft speed (km/h) allowed for static-line exit"], [100, 800, 310, 0], false],
                ["COMBO", ["Parachute Type", "Deployed parachute vehicle class attached automatically after exit"], [["NonSteerable_Parachute_F", "Steerable_Parachute_F"], ["Non-Steerable T-10 (Default)", "Steerable Canopy"], 0], false],
                ["CHECKBOX", ["Staggered Jump Exit", "Alternates jumpers between left (+12m) and right (-12m) rear exit offsets"], false, false]
            ],
            {
                params ["_dialogValues", "_args"];
                _dialogValues params ["_minAltitude", "_maxAltitude", "_maxSpeed", "_chuteVehicleClass", "_allowStaggered"];
                _args params ["_vehicle"];
                if (isNull _vehicle || {!alive _vehicle}) exitWith {};
                if (!isNil {_vehicle getVariable QEGVAR(VehicleFunc,JumpAction)}) exitWith {
                    ["Static Line Jump action is already applied to this aircraft"] call zen_common_fnc_showMessage;
                };

                private _minAlt = round _minAltitude;
                private _maxAlt = (round _maxAltitude) max _minAlt;
                private _spd = round _maxSpeed;

                [_vehicle, _minAlt, _maxAlt, _spd, _chuteVehicleClass, _allowStaggered] remoteExec [QFUNC(addLineJump), 0, _vehicle];
                [format ["Added Static Line Jump (%1m-%2m, <=%3 km/h) to %4", _minAlt, _maxAlt, _spd, getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName")]] call zen_common_fnc_showMessage;
            },
            {},
            [_objectPos]
        ] call zen_dialog_fnc_create;
    },
    "\A3\ui_f\data\map\vehicleicons\iconParachute_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG Mission", "Add Helicopter Get Out Side",
    {
        params ["_modulePos", "_objectPos"];
        if (isNull _objectPos || {!(_objectPos isKindOf "Air")}) exitWith {
            ["Place on an aircraft or helicopter"] call zen_common_fnc_showMessage;
        };
        if (!isNil {_objectPos getVariable QEGVAR(VehicleFunc,GetOutAction)}) exitWith {
            ["Get Out Side actions are already applied to this aircraft"] call zen_common_fnc_showMessage;
        };

        [
            "Configure Helicopter Get Out Side",
            [
                ["CHECKBOX", ["Color-Coded Actions", "Highlights 'Get out Left Side' in Red and 'Get out Right Side' in Blue on the scroll menu"], true, false]
            ],
            {
                params ["_dialogValues", "_args"];
                _dialogValues params ["_useColor"];
                _args params ["_vehicle"];
                if (isNull _vehicle || {!alive _vehicle}) exitWith {};
                if (!isNil {_vehicle getVariable QEGVAR(VehicleFunc,GetOutAction)}) exitWith {
                    ["Get Out Side actions are already applied to this aircraft"] call zen_common_fnc_showMessage;
                };

                [_vehicle, _useColor] remoteExec [QFUNC(addGetOutHelo), 0, _vehicle];
                [format ["Added Get Out Left/Right Side actions to %1", getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName")]] call zen_common_fnc_showMessage;
            },
            {},
            [_objectPos]
        ] call zen_dialog_fnc_create;
    },
    "\A3\ui_f\data\map\vehicleicons\iconHelicopter_ca.paa"
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
    "\a3\ui_f\data\igui\cfg\simpletasks\types\radio_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG EWAR", "Attach Jammer to Object",
    {
        params ["_modulePos", "_objectPos"];
        if (isNull _objectPos) exitWith {
            ["Select a vehicle or object to attach the jammer to"] call zen_common_fnc_showMessage;
        };

        private _objSide = if (count (crew _objectPos) > 0) then {
            side (group ((crew _objectPos) select 0))
        } else {
            if (_objectPos isKindOf "CAManBase") then { side (group _objectPos) } else { sideUnknown }
        };
        private _defaultSideIdx = switch (_objSide) do {
            case west: { 1 };
            case east: { 2 };
            case independent: { 3 };
            case civilian: { 4 };
            default { 0 };
        };

        [
            "Attach EWAR Jammer to Object",
            [
                ["SLIDER", ["Jamming Radius (m)", "Outer radius of the jamming bubble in meters"], [50, 1500, 300, 0], false],
                ["SLIDER", ["Core Cut Ratio", "Inner fraction of radius where link is completely severed (0 = interference only)"], [0, 0.9, 0, 2], false],
                ["COMBO", ["Exempt Side", "Faction unaffected by this jammer"], [[sideUnknown, west, east, independent, civilian], ["None (Affect All)", "BLUFOR", "OPFOR", "Independent", "Civilian"], _defaultSideIdx], false]
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
    "\a3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa"
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
                    ["Jammer Pack Camo", "Select EWAR Jammer Pack variant to equip on the unit"],
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
                            "EWAR Jammer Pack (MTP)",
                            "EWAR Jammer Pack (Woodland)",
                            "EWAR Jammer Pack (Tropic)",
                            "EWAR Jammer Pack (Black)",
                            "EWAR Jammer Pack (Hex)",
                            "EWAR Jammer Pack (Green Hex)",
                            "EWAR Jammer Pack (AAF Digital)",
                            "EWAR Jammer Pack (LDF Geometric)",
                            "EWAR Jammer Pack (Urban)"
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
                    private _oldBag = unitBackpack _unit;
                    private _savedItems = if (!isNull _oldBag) then { getItemCargo _oldBag } else { [[], []] };
                    private _savedMags = if (!isNull _oldBag) then { magazinesAmmoCargo _oldBag } else { [] };
                    private _savedWpns = if (!isNull _oldBag) then { weaponsItemsCargo _oldBag } else { [] };
                    private _savedBags = if (!isNull _oldBag) then { getBackpackCargo _oldBag } else { [[], []] };

                    removeBackpackGlobal _unit;
                    _unit addBackpackGlobal _bagClass;

                    private _newBag = unitBackpack _unit;
                    if (!isNull _newBag) then {
                        clearItemCargoGlobal _newBag;
                        clearMagazineCargoGlobal _newBag;
                        clearWeaponCargoGlobal _newBag;
                        clearBackpackCargoGlobal _newBag;
                        {
                            _newBag addItemCargoGlobal [_x, (_savedItems select 1) select _forEachIndex];
                        } forEach (_savedItems select 0);
                        {
                            _newBag addMagazineAmmoCargo [_x select 0, 1, _x select 1];
                        } forEach _savedMags;
                        {
                            _newBag addWeaponWithAttachmentsCargoGlobal [_x, 1];
                        } forEach _savedWpns;
                        {
                            _newBag addBackpackCargoGlobal [_x, (_savedBags select 1) select _forEachIndex];
                        } forEach (_savedBags select 0);
                    };
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
    "\a3\ui_f\data\igui\cfg\simpletasks\types\backpack_ca.paa"
] call zen_custom_modules_fnc_register;

["TFG EWAR", "Remove Nearby Jammers",
    {
        params ["_modulePos", "_objectPos"];
        if (!isNull _objectPos && {isPlayer _objectPos}) exitWith {
            ["Cannot remove player-equipped EWAR jammer"] call zen_common_fnc_showMessage;
        };

        private _removedAttached = false;
        if (!isNull _objectPos) then {
            private _attachedID = _objectPos getVariable [QGVAR(ewar_jammerID), ""];
            if (_attachedID != "") then {
                [_objectPos] call FUNC(ewar_removeJammer);
                _objectPos setVariable [QGVAR(ewar_isJammerActive), false, true];
                _objectPos setVariable [QGVAR(ewar_jammerID), nil, true];
                ["Removed EWAR jammer from object"] call zen_common_fnc_showMessage;
                _removedAttached = true;
            };
        };
        if (_removedAttached) exitWith {};

        private _posATL = ASLToATL _modulePos;
        private _removedCount = 0;
        if (!isNil QGVAR(ewar_jammers)) then {
            private _toRemove = [];
            {
                _x params ["_id", "_source"];
                private _isPlayerJammer = ((_source isEqualType objNull) && {isPlayer _source}) ||
                    {(_id find "EWAR_BP_") == 0} ||
                    {(_id find "EWAR_PULSE_") == 0};
                if (!_isPlayerJammer) then {
                    private _jPos = if (_source isEqualType objNull) then {
                        if (isNull _source) then { [0, 0, 0] } else { getPosATL _source }
                    } else {
                        _source
                    };
                    if (_jPos isNotEqualTo [0, 0, 0] && {(_posATL distance _jPos) <= 100}) then {
                        _toRemove pushBack [_id, _source];
                    };
                };
            } forEach GVAR(ewar_jammers);

            {
                _x params ["_remId", "_remSrc"];
                [_remId] call FUNC(ewar_removeJammer);
                if ((_remSrc isEqualType objNull) && {!isNull _remSrc}) then {
                    _remSrc setVariable [QGVAR(ewar_isJammerActive), false, true];
                    _remSrc setVariable [QGVAR(ewar_jammerID), nil, true];
                };
                _removedCount = _removedCount + 1;
            } forEach _toRemove;
        };
        [format ["Removed %1 EWAR jammer(s) within 100m", _removedCount]] call zen_common_fnc_showMessage;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\destroy_ca.paa"
] call zen_custom_modules_fnc_register;



INFO("init", "Custom Zen Modules initialization complete");
