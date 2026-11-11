#include "..\script_component.hpp";
/*
 * Author: BaerMitUmlaut, CPL.Brostrom.A
 * This function runs on postInit unsceduled via made sure by postInitProxy
 *
 * Arguments:
 * none
 *
 * Return Value:
 * nothing
 *
 * Example:
 * call deScripts_fnc_gear_postInit
 *
 */

if (isServer) then {
    if (!isMultiplayer) then {
        SHOW_CHAT_WARNING("Gear_PostInit", "Mission in singelplayer environment");
    };
};

if (hasInterface) then {
    ["ace_arsenal_displayClosed", {
        player call EFUNC(gear,saveLoadout);
    }] call CBA_fnc_addEventHandler;
    
    [QEGVAR(gear,applyLoadout), {
        _this params [
            ["_unit", objNull, [objNull]],
            ["_loadout", "", [""]]
        ];
        _loadout = if (_loadout == "") then {[_unit] call EFUNC(gear,selectLoadout)} else {_loadout};
        [_unit, _loadout] call EFUNC(gear,applyLoadout);
    }] call CBA_fnc_addEventHandler;

    ["CAManBase", "Respawn", {
        params ["_newUnit"];
        if (_newUnit == player) then {
            // Restore saved loadout
            private _saved = missionNamespace getVariable [QEGVAR(Gear,SavedPlayerLoadout), []];
            if !(_saved isEqualTo []) then {
                [_newUnit, _saved] call CBA_fnc_setLoadout;
                _newUnit setVariable [QEGVAR(Gear,Loadout), _saved];
                _newUnit setVariable [QEGVAR(Gear,SavedLoadout), true];
            } else {
                if (isClass (missionConfigFile >> "CfgLoadouts")) then {
                    private _loadout = [_newUnit] call EFUNC(gear,selectLoadout);
                    if (_loadout != "") then {
                        [_newUnit, _loadout] call EFUNC(gear,applyLoadout);
                    };
                };
            };

            // Restore saved traits (Doctor, Medic, Engineer, EOD)
            private _traits = missionNamespace getVariable [QEGVAR(Gear,SavedPlayerTraits), []];
            if !(_traits isEqualTo []) then {
                _traits params [["_medic", 0], ["_engineer", 0], ["_eod", false]];
                _newUnit setVariable ["ace_medical_medicClass", _medic, true];
                _newUnit setUnitTrait ["medic", (_medic > 0)];
                _newUnit setVariable ["ace_isEngineer", _engineer, true];
                _newUnit setUnitTrait ["engineer", (_engineer > 0)];
                _newUnit setVariable ["ACE_isEOD", _eod, true];
                _newUnit setUnitTrait ["explosiveSpecialist", _eod];
            };
        };
    }] call CBA_fnc_addClassEventHandler;
};