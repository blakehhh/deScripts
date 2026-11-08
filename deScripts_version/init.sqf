#include "deScripts\script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This is the mission init.sqf this is run witout exceptions on mission start.
 * Some sections in this script only run when your on a multiplayer enviroment to avoid errors and issues.
 * Read more about Initzialisation order here: https://community.bistudio.com/wiki/Initialization_Order
 */

if (!isMultiplayer) then {SHOW_CHAT_WARNING("", "Mission is running on singelplayer enviroment!");};
#ifdef DEBUG_MODE
    SHOW_INFO("init", "Initializing...");
    SHOW_CHAT_INFO_1("init", "deScripts Version %1 is running.", VERSION);
    SHOW_CHAT_WARNING("init", "Debug mode is currently active.");
    logEntities;
#endif

//enableSaving [false, false];

// To Turns off or on ambient Wildelife, Ambient Sounds and wind sound strenght.
//enableEnvironment [false, true, 1];

ACE_maxWeightCarry = 8000;
ACE_maxWeightDrag = 12000;

INFO("init", "Initialization completed.");

/* APPLY STUFF ONLY BELOW THIS LINE */

GEKI_acreBoostRange = 100;     // metres from a booster object
GEKI_acreBoostPower = 50000;  // transmit power in milliwatts (50 W, same as the radio racks)

[{
    params ["_frequency", "_power", "_rxRadio", "_txRadio"];

    private _txObject = [_txRadio] call acre_sys_radio_fnc_getRadioObject;
    private _boosters = missionNamespace getVariable ["GEKI_acreBoosters", []];
    private _boosted = !isNull _txObject && {
        (_boosters findIf { !isNull _x && { _x distance _txObject < GEKI_acreBoostRange } }) > -1
    };

    if (_boosted) then {
        [_frequency, _power max GEKI_acreBoostPower, _rxRadio, _txRadio] call acre_sys_signal_fnc_getSignalCore
    } else {
        _this call acre_sys_signal_fnc_getSignalCore
    };
}] call acre_api_fnc_setCustomSignalFunc;