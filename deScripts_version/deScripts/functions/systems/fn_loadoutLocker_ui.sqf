#include "..\script_component.hpp"
/*
 * Author: Antigravity
 * Handles UI interactions and state updates for the Personal Loadout Locker dialog.
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Parameters <ARRAY> (Optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["onLoad", [_display]] call deScripts_fnc_loadoutLocker_ui;
 */

params [
    ["_mode", "", [""]],
    ["_params", [], [[]]]
];

switch (_mode) do {
    case "onLoad": {
        _params params [["_display", displayNull, [displayNull]]];
        if (isNull _display) exitWith {};

        // Retrieve claimed locker or fall back to current interaction target
        private _locker = player getVariable [QEGVAR(systems,claimed_locker), objNull];
        if (isNull _locker) then {
            _locker = missionNamespace getVariable ["deScripts_ui_currentLocker", objNull];
            if (!isNull _locker && {(_locker getVariable [QEGVAR(systems,locker_ownerUID), ""]) == getPlayerUID player}) then {
                player setVariable [QEGVAR(systems,claimed_locker), _locker, true];
            };
        };

        // Set Title with Locker Owner's Name
        private _ctrlTitle = _display displayCtrl 19101;
        private _ownerName = if (!isNull _locker) then {
            _locker getVariable [QEGVAR(systems,locker_owner), name player]
        } else {
            name player
        };
        _ctrlTitle ctrlSetText format [" PERSONAL LOCKER - %1", toUpper _ownerName];

        // Hide preset picker overlay by default
        {
            (_display displayCtrl _x) ctrlShow false;
        } forEach [19180, 19181, 19182, 19183, 19184];

        // Update all status panels
        ["updateStatus", [_display]] call FUNC(loadoutLocker_ui);
    };

    case "updateStatus": {
        private _display = if (count _params > 0) then {_params select 0} else {findDisplay 19100};
        if (isNull _display) exitWith {};

        // 1. Role Buttons Dynamic State (Green when active, Slate when inactive)
        private _medicClass = player getVariable ["ace_medical_medicClass", 0];
        private _engineerClass = player getVariable ["ace_isEngineer", 0];
        private _isEOD = player getVariable ["ACE_isEOD", false];

        private _colorActive = [0.15, 0.50, 0.20, 1.0];
        private _colorInactive = [0.18, 0.22, 0.28, 1.0];
        private _bgCLS = _display displayCtrl 19125;
        private _bgMedic = _display displayCtrl 19126;
        private _bgEng = _display displayCtrl 19127;
        private _bgEOD = _display displayCtrl 19128;

        _bgCLS ctrlSetBackgroundColor (if (_medicClass == 1) then {_colorActive} else {_colorInactive});
        _bgCLS ctrlCommit 0;

        _bgMedic ctrlSetBackgroundColor (if (_medicClass == 2) then {_colorActive} else {_colorInactive});
        _bgMedic ctrlCommit 0;

        _bgEng ctrlSetBackgroundColor (if (_engineerClass > 0) then {_colorActive} else {_colorInactive});
        _bgEng ctrlCommit 0;

        _bgEOD ctrlSetBackgroundColor (if (_isEOD) then {_colorActive} else {_colorInactive});
        _bgEOD ctrlCommit 0;

        // 2. Preset Buttons Availability Check (Persistent 4-slot mapping)
        private _savedLoadouts = profileNamespace getVariable ["ace_arsenal_saved_loadouts", []];
        private _slots = profileNamespace getVariable [QEGVAR(Profile,LockerSlots), ["Preset 1", "Preset 2", "Preset 3", "Preset 4"]];
        if (!(_slots isEqualType []) || {count _slots < 4}) then {
            private _fixed = +_slots;
            if (!(_fixed isEqualType [])) then { _fixed = []; };
            while {count _fixed < 4} do {
                _fixed pushBack format ["Preset %1", (count _fixed) + 1];
            };
            _slots = _fixed;
        };

        {
            _x params ["_idc", "_slotIdx"];
            private _presetName = _slots param [_slotIdx, format ["Preset %1", _slotIdx + 1], [""]];
            private _hasPreset = (_savedLoadouts findIf {_x isEqualType [] && {count _x > 0} && {(_x select 0) == _presetName}}) != -1;
            private _btn = _display displayCtrl _idc;
            _btn ctrlSetText _presetName;
            _btn ctrlEnable _hasPreset;
            _btn ctrlSetTooltip (if (_hasPreset) then {
                format ["Equip '%1'", _presetName]
            } else {
                format ["'%1' not found in ACE Arsenal (click icon to assign)", _presetName]
            });
        } forEach [
            [19110, 0],
            [19111, 1],
            [19112, 2],
            [19117, 3]
        ];

        // 3. Medical Triage Silhouette & Status Summary
        private _bodyPartDamage = player getVariable ["ace_medical_bodyPartDamage", [0, 0, 0, 0, 0, 0]];
        private _baseThreshold = player getVariable ["ace_medical_damageThreshold", missionNamespace getVariable ["ace_medical_playerDamageThreshold", 1]];
        private _partIDCs = [19201, 19202, 19203, 19204, 19205, 19206];
        private _limbThresholdCfg = missionNamespace getVariable ["ace_medical_limbDamageThreshold", 0];
        private _useLimbDamage = [false, !isPlayer player, true] select (missionNamespace getVariable ["ace_medical_useLimbDamage", 0]);

        private _totalDamage = 0;

        {
            private _partIndex = _forEachIndex;
            private _ctrlPart = _display displayCtrl _x;
            private _damage = _bodyPartDamage param [_partIndex, 0];
            _totalDamage = _totalDamage + _damage;

            private _threshold = switch (_partIndex) do {
                case 0: {_baseThreshold * 1.25};
                case 1: {_baseThreshold * 1.5};
                default {
                    if (_limbThresholdCfg != 0 && {_useLimbDamage}) then {
                        _baseThreshold * _limbThresholdCfg
                    } else {
                        1.2
                    };
                };
            };
            private _normDamage = (_damage / (0.01 max _threshold)) min 1;
            private _color = if (!isNil "ace_medical_gui_fnc_damageToRGBA") then {
                [_normDamage] call ace_medical_gui_fnc_damageToRGBA
            } else {
                [1, 1 - _normDamage, 1 - _normDamage, 1]
            };

            _ctrlPart ctrlSetTextColor _color;
        } forEach _partIDCs;

        private _ctrlMedText = _display displayCtrl 19210;
        private _bloodVolume = player getVariable ["ace_medical_bloodVolume", 6.0];
        private _statusStr = if (_totalDamage > 0.05 || {_bloodVolume < 5.9}) then {
            "<t color='#f0c040'>Injured</t>"
        } else {
            "<t color='#88ff88'>Healthy</t>"
        };
        _ctrlMedText ctrlSetStructuredText parseText format ["<t align='center'>%1</t>", _statusStr];

        // 4. Field Rations Status Icons (Thirst & Hunger)
        private _ctrlThirst = _display displayCtrl 19220;
        private _ctrlHunger = _display displayCtrl 19221;
        if (missionNamespace getVariable ["acex_field_rations_enabled", false]) then {
            private _thirst = player getVariable ["acex_field_rations_thirst", 0];
            private _hunger = player getVariable ["acex_field_rations_hunger", 0];

            {
                _x params ["_ctrl", "_val", "_label"];
                private _color = if (_val <= 3) then {
                    [0.5, 0.5, 0.5, 0.4]
                } else {
                    [
                        1,
                        linearConversion [35, 90, _val, 1, 0, true],
                        linearConversion [0, 40, _val, 1, 0, true],
                        1
                    ]
                };
                _ctrl ctrlSetTextColor _color;
                _ctrl ctrlSetTooltip format ["%1: %2%3", _label, round _val, "%"];
                _ctrl ctrlShow true;
            } forEach [
                [_ctrlThirst, _thirst, "Thirst"],
                [_ctrlHunger, _hunger, "Hunger"]
            ];
        } else {
            _ctrlThirst ctrlShow false;
            _ctrlHunger ctrlShow false;
        };
    };

    case "equipSlot": {
        _params params [["_slotIndex", 0, [0]]];
        private _slots = profileNamespace getVariable [QEGVAR(Profile,LockerSlots), ["Preset 1", "Preset 2", "Preset 3", "Preset 4"]];
        private _targetPreset = _slots param [_slotIndex, "", [""]];
        if (_targetPreset != "") then {
            ["equipKit", [_targetPreset]] call FUNC(loadoutLocker_ui);
        };
    };

    case "openPicker": {
        _params params [["_slotIndex", 0, [0]]];
        private _display = findDisplay 19100;
        if (isNull _display) exitWith {};

        private _savedLoadouts = profileNamespace getVariable ["ace_arsenal_saved_loadouts", []];
        private _names = [];
        {
            if (_x isEqualType [] && {count _x > 0} && {(_x select 0) isEqualType ""}) then {
                _names pushBack (_x select 0);
            };
        } forEach _savedLoadouts;

        if (_names isEqualTo []) exitWith {
            ["No saved ACE Arsenal presets found!"] call ace_common_fnc_displayTextPicture;
        };

        _names sort true;
        missionNamespace setVariable ["deScripts_ui_pickerSlot", _slotIndex];
        missionNamespace setVariable ["deScripts_ui_pickerNames", _names];

        private _ctrlSearch = _display displayCtrl 19184;
        _ctrlSearch ctrlSetText "";

        (_display displayCtrl 19181) ctrlSetText format [" SELECT PRESET FOR SLOT %1", _slotIndex + 1];
        {
            (_display displayCtrl _x) ctrlShow true;
        } forEach [19180, 19181, 19182, 19183, 19184];

        ["filterPicker"] call FUNC(loadoutLocker_ui);
        ctrlSetFocus _ctrlSearch;
    };

    case "filterPicker": {
        private _display = findDisplay 19100;
        if (isNull _display) exitWith {};

        private _query = toLower (ctrlText (_display displayCtrl 19184));
        private _names = missionNamespace getVariable ["deScripts_ui_pickerNames", []];
        private _ctrlList = _display displayCtrl 19182;
        lbClear _ctrlList;
        {
            if (_query == "" || {(toLower _x) find _query != -1}) then {
                _ctrlList lbAdd _x;
            };
        } forEach _names;
    };

    case "selectPreset": {
        _params params [["_ctrl", controlNull, [controlNull]], ["_lbIdx", -1, [0]]];
        if (isNull _ctrl || {_lbIdx < 0}) exitWith {};

        private _presetName = _ctrl lbText _lbIdx;
        private _slotIndex = missionNamespace getVariable ["deScripts_ui_pickerSlot", 0];
        private _slots = +(profileNamespace getVariable [QEGVAR(Profile,LockerSlots), ["Preset 1", "Preset 2", "Preset 3", "Preset 4"]]);
        while {count _slots < 4} do {
            _slots pushBack format ["Preset %1", (count _slots) + 1];
        };
        _slots set [_slotIndex, _presetName];
        profileNamespace setVariable [QEGVAR(Profile,LockerSlots), _slots];
        saveProfileNamespace;

        ["closePicker"] call FUNC(loadoutLocker_ui);
        ["updateStatus"] call FUNC(loadoutLocker_ui);
    };

    case "closePicker": {
        private _display = findDisplay 19100;
        if (isNull _display) exitWith {};
        {
            (_display displayCtrl _x) ctrlShow false;
        } forEach [19180, 19181, 19182, 19183, 19184];
    };

    case "equipKit": {
        _params params [["_targetPreset", "", [""]]];
        private _savedLoadouts = profileNamespace getVariable ["ace_arsenal_saved_loadouts", []];
        private _loadoutIndex = _savedLoadouts findIf {(_x select 0) == _targetPreset};

        if (_loadoutIndex != -1) then {
            private _loadoutData = +((_savedLoadouts select _loadoutIndex) select 1);
            private _vanillaLoadout = _loadoutData;
            if (_loadoutData isEqualType [] && {count _loadoutData > 0} && {(_loadoutData select 0) isEqualType []} && {count (_loadoutData select 0) == 10}) then {
                _vanillaLoadout = +(_loadoutData select 0);
            };
            _vanillaLoadout = [_vanillaLoadout] call FUNC(filterUnitLoadout);

            // Enforce mission blacklist (GVAR(BLACKLIST)) on loaded preset
            private _blacklist = missionNamespace getVariable [QGVAR(BLACKLIST), []];
            private _strippedCount = 0;
            if (_blacklist isNotEqualTo [] && {_vanillaLoadout isEqualType []}) then {
                private _blMap = createHashMap;
                { _blMap set [_x, true]; } forEach _blacklist;

                // Weapon slots: 0 (primary), 1 (launcher), 2 (handgun), 8 (binoculars)
                {
                    private _wepArr = _vanillaLoadout param [_x, [], [[]]];
                    if (_wepArr isNotEqualTo []) then {
                        private _wepClass = _wepArr param [0, "", [""]];
                        if (_wepClass != "" && {_wepClass in _blMap}) then {
                            _vanillaLoadout set [_x, []];
                            _strippedCount = _strippedCount + 1;
                        } else {
                            {
                                private _att = _wepArr param [_x, "", [""]];
                                if (_att != "" && {_att in _blMap}) then {
                                    _wepArr set [_x, ""];
                                    _strippedCount = _strippedCount + 1;
                                };
                            } forEach [1, 2, 3, 6];
                            {
                                private _magArr = _wepArr param [_x, [], [[]]];
                                if (_magArr isNotEqualTo [] && {(_magArr param [0, "", [""]]) in _blMap}) then {
                                    _wepArr set [_x, []];
                                    _strippedCount = _strippedCount + 1;
                                };
                            } forEach [4, 5];
                        };
                    };
                } forEach [0, 1, 2, 8];

                // Container slots: 3 (uniform), 4 (vest), 5 (backpack)
                {
                    private _contArr = _vanillaLoadout param [_x, [], [[]]];
                    if (_contArr isNotEqualTo []) then {
                        private _contClass = _contArr param [0, "", [""]];
                        if (_contClass != "" && {_contClass in _blMap}) then {
                            _vanillaLoadout set [_x, []];
                            _strippedCount = _strippedCount + 1;
                        } else {
                            private _items = _contArr param [1, [], [[]]];
                            private _kept = [];
                            {
                                private _itemClass = _x param [0, "", [""]];
                                if (_itemClass != "" && {_itemClass in _blMap}) then {
                                    _strippedCount = _strippedCount + 1;
                                } else {
                                    _kept pushBack _x;
                                };
                            } forEach _items;
                            _contArr set [1, _kept];
                        };
                    };
                } forEach [3, 4, 5];

                // Headgear (6) and Facewear (7)
                {
                    private _gearClass = _vanillaLoadout param [_x, "", [""]];
                    if (_gearClass != "" && {_gearClass in _blMap}) then {
                        _vanillaLoadout set [_x, ""];
                        _strippedCount = _strippedCount + 1;
                    };
                } forEach [6, 7];

                // Assigned items (9): map, gps, radio, compass, watch, nvg
                private _assigned = _vanillaLoadout param [9, [], [[]]];
                {
                    if (_x != "" && {_x in _blMap}) then {
                        _assigned set [_forEachIndex, ""];
                        _strippedCount = _strippedCount + 1;
                    };
                } forEach _assigned;
            };

            [player, _vanillaLoadout] call CBA_fnc_setLoadout;
            [player] call EFUNC(gear,saveLoadout);
            private _msg = if (_strippedCount > 0) then {
                format ["Equipped %1 (%2 blacklisted item(s) removed).", _targetPreset, _strippedCount]
            } else {
                format ["Equipped %1.", _targetPreset]
            };
            [_msg] call ace_common_fnc_displayTextPicture;
            ["updateStatus"] call FUNC(loadoutLocker_ui);
        } else {
            [format ["Missing '%1' preset in your ACE Arsenal!", _targetPreset]] call ace_common_fnc_displayTextPicture;
        };
    };

    case "openArsenal": {
        closeDialog 0;
        call FUNC(clearDefaultArsenalLoadouts);
        call FUNC(addDefaultArsenalLoadout);

        [player, true] call ace_arsenal_fnc_addVirtualItems;

        private _blacklist = GVAR(BLACKLIST);
        [player, _blacklist, false] call ace_arsenal_fnc_removeVirtualItems;

        [{
            [player, player, false] call ace_arsenal_fnc_openBox;
            [QEGVAR(StagingArsenal,displayOpen)] call CBA_fnc_localEvent;
            [{
                private _loadout = [player] call EFUNC(gear,getLoadoutName);
                private _loadoutCfg = missionConfigFile >> "CfgLoadouts" >> _loadout;
                private _titleMsg = if (isClass _loadoutCfg) then {
                    private _name = getText (_loadoutCfg >> "displayName");
                    private _company = getText (_loadoutCfg >> "company");
                    format ["Arsenal for %1 Co. %2 loaded", [_company] call CBA_fnc_capitalize, _name]
                } else {
                    format ["Arsenal loaded for %1", _loadout]
                };
                [(findDisplay 1127001), _titleMsg] call ace_arsenal_fnc_message;
            }, [], 0.35] call CBA_fnc_waitAndExecute;
        }] call CBA_fnc_execNextFrame;
    };

    case "setRole": {
        _params params [["_role", "", [""]]];
        switch (_role) do {
            case "CLS": {
                private _current = player getVariable ["ace_medical_medicClass", 0];
                if (_current == 1) then {
                    player setVariable ["ace_medical_medicClass", 0, true];
                    player setUnitTrait ["medic", false];
                    systemChat "Role removed: Combat Lifesaver.";
                } else {
                    player setVariable ["ace_medical_medicClass", 1, true];
                    player setUnitTrait ["medic", true];
                    systemChat "Role updated: Combat Lifesaver (CLS).";
                };
            };
            case "Medic": {
                private _current = player getVariable ["ace_medical_medicClass", 0];
                if (_current == 2) then {
                    player setVariable ["ace_medical_medicClass", 0, true];
                    player setUnitTrait ["medic", false];
                    systemChat "Role removed: Medic.";
                } else {
                    player setVariable ["ace_medical_medicClass", 2, true];
                    player setUnitTrait ["medic", true];
                    systemChat "Role updated: Medic (Doctor).";
                };
            };
            case "Engineer": {
                private _current = player getVariable ["ace_isEngineer", 0];
                if (_current > 0) then {
                    player setVariable ["ace_isEngineer", 0, true];
                    player setUnitTrait ["engineer", false];
                    systemChat "Role removed: Advanced Engineer.";
                } else {
                    player setVariable ["ace_isEngineer", 2, true];
                    player setUnitTrait ["engineer", true];
                    systemChat "Role updated: Advanced Engineer.";
                };
            };
            case "EOD": {
                private _current = player getVariable ["ACE_isEOD", false];
                player setVariable ["ACE_isEOD", !_current, true];
                player setUnitTrait ["explosiveSpecialist", !_current];
                if (!_current) then {
                    systemChat "Role updated: Explosive/Demo Specialist (EOD) added.";
                } else {
                    systemChat "Role updated: Explosive/Demo Specialist (EOD) removed.";
                };
            };
            case "clearAll": {
                player setVariable ["ace_medical_medicClass", 0, true];
                player setUnitTrait ["medic", false];
                player setVariable ["ace_isEngineer", 0, true];
                player setUnitTrait ["engineer", false];
                player setVariable ["ACE_isEOD", false, true];
                player setUnitTrait ["explosiveSpecialist", false];
                systemChat "All role permissions have been removed.";
            };
        };

        // Persist traits to missionNamespace for respawn retention
        private _savedMedic = player getVariable ["ace_medical_medicClass", 0];
        private _savedEng = player getVariable ["ace_isEngineer", 0];
        private _savedEOD = player getVariable ["ACE_isEOD", false];
        missionNamespace setVariable [QEGVAR(Gear,SavedPlayerTraits), [_savedMedic, _savedEng, _savedEOD]];

        ["updateStatus"] call FUNC(loadoutLocker_ui);
    };

    case "heal": {
        if (GVAR(OneLife)) exitWith {
            [[], ["Full heal is disabled during One-Life operations."], [""], [""]] call CBA_fnc_notify;
        };
        [player, player] call ace_medical_treatment_fnc_fullHeal;
        [[], ["You have been fully healed."], [""], [""]] call CBA_fnc_notify;
        ["updateStatus"] call FUNC(loadoutLocker_ui);
    };

    case "eatAndDrink": {
        closeDialog 0;
        private _target = player getVariable [QEGVAR(systems,claimed_locker), objNull];
        if (isNull _target) then {
            _target = missionNamespace getVariable ["deScripts_ui_currentLocker", objNull];
        };

        private _anim = [player, _target] call ace_field_rations_fnc_getDrinkAnimation;
        player setVariable ["ace_field_rations_previousAnim", animationState player];
        [player, _anim, 1] call ace_common_fnc_doAnimation;

        [10, [player, _target], {
            params ["_args"];
            _args params ["_player", "_target"];
            _player setVariable ["acex_field_rations_hunger", 0, true];
            _player setVariable ["acex_field_rations_thirst", 0, true];
            systemChat "You have eaten a meal and drank water.";
            _player setVariable ["ace_field_rations_previousAnim", nil];
            if (alive _player && {!isNull _target && {_player distance _target <= 5}}) then {
                createDialog "deScripts_RscLoadoutLocker";
            };
        }, {
            params ["_args"];
            _args params ["_player", "_target"];
            systemChat "You stopped eating and drinking.";
            
            if (isNull objectParent _player && {!(_player call ace_common_fnc_isSwimming)}) then {
                private _prevAnim = _player getVariable ["ace_field_rations_previousAnim", ""];
                if (_prevAnim != "") then {
                    [_player, _prevAnim, 2] call ace_common_fnc_doAnimation;
                };
            };
            _player setVariable ["ace_field_rations_previousAnim", nil];
            if (alive _player && {!isNull _target && {_player distance _target <= 5}}) then {
                createDialog "deScripts_RscLoadoutLocker";
            };
        }, "Eating and Drinking...", {true}, ["isNotInside"]] call ace_common_fnc_progressBar;
    };

    case "closeDisplay": {
        if (!isNull (findDisplay 19100)) then {
            (findDisplay 19100) closeDisplay 1;
            closeDialog 0;
        };
        ["delete"] call FUNC(loadoutLocker_marker);
    };

    case "abandonLocker": {
        (findDisplay 19100) closeDisplay 1;
        closeDialog 0;
        private _target = player getVariable [QEGVAR(systems,claimed_locker), objNull];
        if (isNull _target) then {
            _target = missionNamespace getVariable ["deScripts_ui_currentLocker", objNull];
        };
        if (!isNull _target) then {
            _target setVariable [QEGVAR(systems,locker_owner), "", true];
            _target setVariable [QEGVAR(systems,locker_ownerUID), "", true];
            player setVariable [QEGVAR(systems,claimed_locker), objNull, true];
            missionNamespace setVariable ["deScripts_ui_currentLocker", objNull];
            ["delete"] call FUNC(loadoutLocker_marker);
            ["Locker Abandoned."] call ace_common_fnc_displayTextPicture;
        };
    };
};
