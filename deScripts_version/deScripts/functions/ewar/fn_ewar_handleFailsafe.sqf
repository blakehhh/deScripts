#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Severs the local player's UAV terminal connection and triggers the physical
 * fail-safe behavior on the machine where the UAV is local.
 *
 * Arguments:
 * 0: Connected UAV <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_uav] call deScripts_fnc_ewar_handleFailsafe
 *
 * Public: No
 */

params ["_uav"];

// Release remote control and exit UAV camera if actively viewing through it
if (cameraOn isEqualTo _uav) then {
    objNull remoteControl (driver _uav);
    objNull remoteControl (gunner _uav);
    player switchCamera cameraView;
};

// Sever player terminal connection
player connectTerminalToUav objNull;
call FUNC(ewar_clearFX);

titleText ["<t color='#ff0000' size='1.5'>UAV LINK SEVERED — CRITICAL ELECTRONIC JAMMING</t>", "PLAIN DOWN", 0.8, true, true];

// Trigger fail-safe logic where the UAV is local
[QGVAR(ewar_executeDroneFailsafe), [_uav], _uav] call CBA_fnc_targetEvent;
