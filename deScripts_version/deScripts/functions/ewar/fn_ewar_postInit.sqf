#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Post-initialization for EWAR drone jamming module.
 * Starts the recovery monitor (all machines), client-side operator loop,
 * and registers ACE self-interaction actions for the EWAR Jammer Backpack.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call deScripts_fnc_ewar_postInit
 *
 * Public: No
 */

if (is3DEN) exitWith {};

// Start recovery & autonomous UAV crit-zone monitor on all machines (server & clients)
[{
    call FUNC(ewar_recoveryLoop);
}, 1.0, []] call CBA_fnc_addPerFrameHandler;

// Start client-side operator loop and ACE self-interactions only if local player interface exists
if (hasInterface) then {
    [{
        call FUNC(ewar_clientLoop);
    }, 0.5, []] call CBA_fnc_addPerFrameHandler;

    // Smooth real-time refresh for the physical Spectrum Device (hgun_esd_01_F) LCD screen when held
    [{
        if (alive player && {((toLower (currentWeapon player)) find "hgun_esd_01" != -1)}) then {
            [0] call FUNC(ewar_updateBackpackHUD);
        };
    }, 0.08, []] call CBA_fnc_addPerFrameHandler;

    if (EGVAR(patches,usesACE)) then {
        private _ewarCategory = [
            QGVAR(ewar_backpackCategory),
            "EWAR Jammer",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\radio_ca.paa",
            {},
            {
                params ["_target", "_player"];
                EGVAR(Settings,ewar_enable) && {alive _player} && {(toLower (backpack _player)) find "b_radiobag_01" != -1}
            }
        ] call ace_interact_menu_fnc_createAction;

        ["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _ewarCategory, true] call ace_interact_menu_fnc_addActionToClass;

        private _parentPath = ["ACE_SelfActions", "ACE_Equipment", QGVAR(ewar_backpackCategory)];

        private _turnOnAction = [
            QGVAR(ewar_turnOnAction),
            "Activate Jammer",
            "",
            {
                params ["_target", "_player"];
                [_player, true] call FUNC(ewar_toggleBackpackJammer);
            },
            {
                params ["_target", "_player"];
                !(_player getVariable [QGVAR(ewar_isJammerActive), false])
            }
        ] call ace_interact_menu_fnc_createAction;

        private _turnOffAction = [
            QGVAR(ewar_turnOffAction),
            "Deactivate Jammer",
            "",
            {
                params ["_target", "_player"];
                [_player, false] call FUNC(ewar_toggleBackpackJammer);
            },
            {
                params ["_target", "_player"];
                _player getVariable [QGVAR(ewar_isJammerActive), false]
            }
        ] call ace_interact_menu_fnc_createAction;

        private _replaceBatteryAction = [
            QGVAR(ewar_replaceBatteryAction),
            "Replace Battery",
            "",
            {
                params ["_target", "_player"];
                [_player] call FUNC(ewar_reloadBackpackBattery);
            },
            {
                params ["_target", "_player"];
                private _unitItems = items _player;
                EGVAR(Settings,ewar_backpackRequiresBattery) && {("GX_UAVBattery" in _unitItems) || {"ACE_UAVBattery" in _unitItems}}
            }
        ] call ace_interact_menu_fnc_createAction;

        private _showHudAction = [
            QGVAR(ewar_showHudAction),
            "Show EWAR HUD",
            "",
            {
                profileNamespace setVariable [QGVAR(ewar_showHUD), true];
                saveProfileNamespace;
                [0] call FUNC(ewar_updateBackpackHUD);
            },
            {
                !(profileNamespace getVariable [QGVAR(ewar_showHUD), true])
            }
        ] call ace_interact_menu_fnc_createAction;

        private _hideHudAction = [
            QGVAR(ewar_hideHudAction),
            "Hide EWAR HUD",
            "",
            {
                profileNamespace setVariable [QGVAR(ewar_showHUD), false];
                saveProfileNamespace;
                GVAR(ewar_hudPopupUntil) = 0;
                [0] call FUNC(ewar_updateBackpackHUD);
            },
            {
                profileNamespace getVariable [QGVAR(ewar_showHUD), true]
            }
        ] call ace_interact_menu_fnc_createAction;

        ["CAManBase", 1, _parentPath, _turnOnAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _turnOffAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _replaceBatteryAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _showHudAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _parentPath, _hideHudAction, true] call ace_interact_menu_fnc_addActionToClass;

        // Beam Focus sub-menu for Directional Spectrum Device (hgun_esd_01_F)
        private _beamFocusMenu = [
            QGVAR(ewar_beamFocusCategory),
            "Beam Focus (Cycle)",
            "",
            {
                params ["_target", "_player"];
                [_player, 1, false] call FUNC(ewar_cycleBeamFocus);
            },
            {
                params ["_target", "_player"];
                ((toLower (currentWeapon _player)) find "hgun_esd_01" != -1) || {((toLower (handgunWeapon _player)) find "hgun_esd_01" != -1)}
            }
        ] call ace_interact_menu_fnc_createAction;

        ["CAManBase", 1, _parentPath, _beamFocusMenu, true] call ace_interact_menu_fnc_addActionToClass;

        private _beamParentPath = ["ACE_SelfActions", "ACE_Equipment", QGVAR(ewar_backpackCategory), QGVAR(ewar_beamFocusCategory)];

        private _beamWideAction = [
            QGVAR(ewar_beamWide),
            "Military Horn (45° | 600m | 3x)",
            "",
            {
                params ["_target", "_player"];
                [_player, 0, true] call FUNC(ewar_cycleBeamFocus);
            },
            {
                params ["_target", "_player"];
                (_player getVariable [QGVAR(ewar_beamMode), 0]) != 0
            }
        ] call ace_interact_menu_fnc_createAction;

        private _beamFocusedAction = [
            QGVAR(ewar_beamFocused),
            "Cross-Dipole Array (20° | 1000m | 4x)",
            "",
            {
                params ["_target", "_player"];
                [_player, 1, true] call FUNC(ewar_cycleBeamFocus);
            },
            {
                params ["_target", "_player"];
                (_player getVariable [QGVAR(ewar_beamMode), 0]) != 1
            }
        ] call ace_interact_menu_fnc_createAction;

        private _beamSpotAction = [
            QGVAR(ewar_beamSpot),
            "Jammer Radome Tube (10° | 1500m | 5x)",
            "",
            {
                params ["_target", "_player"];
                [_player, 2, true] call FUNC(ewar_cycleBeamFocus);
            },
            {
                params ["_target", "_player"];
                (_player getVariable [QGVAR(ewar_beamMode), 0]) != 2
            }
        ] call ace_interact_menu_fnc_createAction;

        ["CAManBase", 1, _beamParentPath, _beamWideAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _beamParentPath, _beamFocusedAction, true] call ace_interact_menu_fnc_addActionToClass;
        ["CAManBase", 1, _beamParentPath, _beamSpotAction, true] call ace_interact_menu_fnc_addActionToClass;
    };

    // Register CBA Keybinds for PageUp (0xC9) and PageDown (0xD1) when holding Spectrum Device
    [
        "deScripts EWAR",
        QGVAR(ewar_keyFocusNarrow),
        ["Focus Beam (Narrow)", "Narrows the directional EWAR beam (45° -> 20° -> 10°) to increase range and kill distance."],
        {
            if (!alive player) exitWith { false };
            if ((toLower (backpack player)) find "b_radiobag_01" == -1) exitWith { false };
            if ((toLower (currentWeapon player)) find "hgun_esd_01" == -1) exitWith { false };
            private _cur = player getVariable [QGVAR(ewar_beamMode), 0];
            if (_cur < 2) then {
                [player, _cur + 1, true] call FUNC(ewar_cycleBeamFocus);
            } else {
                playSoundUI ["cba_ui_empty", 0.35, 1.9];
                [5] call FUNC(ewar_updateBackpackHUD);
            };
            true
        },
        {},
        [0xC9, [false, false, false]]
    ] call CBA_fnc_addKeybind;

    [
        "deScripts EWAR",
        QGVAR(ewar_keyFocusWiden),
        ["Widen Beam", "Widens the directional EWAR beam (10° -> 20° -> 45°) to widen coverage and reduce battery drain."],
        {
            if (!alive player) exitWith { false };
            if ((toLower (backpack player)) find "b_radiobag_01" == -1) exitWith { false };
            if ((toLower (currentWeapon player)) find "hgun_esd_01" == -1) exitWith { false };
            private _cur = player getVariable [QGVAR(ewar_beamMode), 0];
            if (_cur > 0) then {
                [player, _cur - 1, true] call FUNC(ewar_cycleBeamFocus);
            } else {
                playSoundUI ["cba_ui_empty", 0.35, 1.1];
                [5] call FUNC(ewar_updateBackpackHUD);
            };
            true
        },
        {},
        [0xD1, [false, false, false]]
    ] call CBA_fnc_addKeybind;

    // Register Briefing Diary Records for EWAR C-UAS System
    // Note: Arma 3 createDiaryRecord prepends records (LIFO), so we create 3 -> 2 -> 1
    // to have them displayed chronologically (1. Operator, 2. Pilot, 3. Zeus) in the UI.
    if (missionNamespace getVariable [QEGVAR(Settings,showDiaryRecords), true]) then {
        if !(player diarySubjectExists "deScripts_ewar") then {
            player createDiarySubject ["deScripts_ewar", "EWAR C-UAS Guide"];
        };

        player createDiaryRecord ["deScripts_ewar", [
            "3. Zeus & Mission Maker Reference",
            "<font size='16' color='#68d4f8'>ZEUS &amp; MISSION MAKER REFERENCE</font><br/>" +
            "<font color='#98a6b4'>Custom curator modules and mission scripting entry points.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. ZEN Curator Modules</font><br/>" +
            "Located under category <font color='#68d4f8'>TFG EWAR</font>:<br/>" +
            "* <font color='#e0f4e0'>Create Jammer Area:</font> Places a static jammer bubble at the cursor with configurable radius (50m-1500m), core cut ratio, and side exemption.<br/>" +
            "* <font color='#e0f4e0'>Attach Jammer to Object:</font> Attaches a mobile/destructible jammer bubble to any vehicle or radar structure.<br/>" +
            "* <font color='#e0f4e0'>Equip Jammer Backpack (AI):</font> Equips an AI soldier with a faction Radio Pack that jams until death (no batteries required).<br/>" +
            "* <font color='#e0f4e0'>Remove Nearby Jammers:</font> Removes jammers from clicked objects or clears jammers within 100m.<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Mission Init Scripting API</font><br/>" +
            "* <font color='#e0f4e0'>Add Jammer:</font> <font face='EtelkaMonospacePro'>[this, 300] call deScripts_fnc_ewar_addJammer;</font><br/>" +
            "* <font color='#e0f4e0'>Remove Jammer:</font> <font face='EtelkaMonospacePro'>[this] call deScripts_fnc_ewar_removeJammer;</font><br/><br/>" +

            "<font size='14' color='#ffe044'>C. CBA Addon Options</font><br/>" +
            "All parameters can be tuned in real-time under <font color='#68d4f8'>Options &gt; Addon Options &gt; deScripts Mission Settings &gt; 9; Electronic Warfare</font>."
        ]];

        player createDiaryRecord ["deScripts_ewar", [
            "2. UAV Pilot Survival Guide",
            "<font size='16' color='#68d4f8'>UAV PILOT SURVIVAL &amp; COUNTER-MEASURES</font><br/>" +
            "<font color='#98a6b4'>What to do when flying into active electronic warfare environments.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. Recognizing Jamming</font><br/>" +
            "* <font color='#e0f4e0'>Visual Indicators:</font> Analog static snow and chromatic color fringing will appear across your camera feed.<br/>" +
            "* <font color='#e0f4e0'>HUD Signal Meter:</font> A 5-bar signal strength meter will appear on your optics, climbing from White &gt; Yellow &gt; Orange &gt; Red &gt; Flashing Red.<br/>" +
            "* <font color='#e0f4e0'>Dwell Warning:</font> If an EW specialist is tracking you with a directional beam, static and signal loss will aggressively escalate over several seconds.<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Defensive Reactions</font><br/>" +
            "* <font color='#e0f4e0'>Break Line of Sight:</font> Directional jamming requires line-of-sight bore-sight aim. Dive behind mountain ridges, tree lines, or buildings to break the lock and drain the operator's burn progress.<br/>" +
            "* <font color='#e0f4e0'>Turn Away &amp; Extend:</font> Maximize distance to increase the operator's required dwell time up to 30 seconds, giving you time to escape the bubble.<br/><br/>" +

            "<font size='14' color='#ffe044'>C. Fail-Safe Behaviors (Connection Severed)</font><br/>" +
            "* <font color='#e0f4e0'>Rotary / Micro-UAVs (Darter, Black Hornet, Hunter, Pelican):</font> Autopilot initiates vertical controlled auto-land descent.<br/>" +
            "* <font color='#e0f4e0'>Fixed-Wing Recon (Raven, Greyhawk, Sentinel):</font> Enters autonomous 250m circular holding orbit.<br/>" +
            "* <font color='#e0f4e0'>Loitering Munitions / FPVs:</font> Engine immediately cuts; falls ballistically.<br/>" +
            "* <font color='#e0f4e0'>Recovery:</font> Once the drone drifts clear of the jammer or the jammer is destroyed, friendly terminal links restore automatically.<br/>"
        ]];

        player createDiaryRecord ["deScripts_ewar", [
            "1. Operator Field Manual",
            "<font size='16' color='#68d4f8'>EWAR C-UAS OPERATOR FIELD MANUAL</font><br/>" +
            "<font color='#98a6b4'>Guidelines for deploying man-portable counter-UAS electronic warfare systems.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. Backpack Jammer (Omni-Directional Base)</font><br/>" +
            "* <font color='#e0f4e0'>Equipment:</font> Any Radio Pack backpack (<font face='EtelkaMonospacePro'>B_RadioBag_01_*</font>).<br/>" +
            "* <font color='#e0f4e0'>Controls:</font> ACE Self-Interaction &gt; <font color='#68d4f8'>Equipment &gt; EWAR Jammer</font>.<br/>" +
            "* <font color='#e0f4e0'>Omni Radius:</font> 200m progressive static bubble with a 75m emergency hard-kill core.<br/>" +
            "* <font color='#e0f4e0'>Battery Power:</font> Powered by UAV batteries (<font face='EtelkaMonospacePro'>GX_UAVBattery</font> or <font face='EtelkaMonospacePro'>ACE_UAVBattery</font>). Provides <font color='#e0f4e0'>45 minutes</font> continuous transmission in Omni mode. Swap via ACE menu (4-second progress bar).<br/>" +
            "* <font color='#e0f4e0'>RCU Mini-HUD:</font> Compact widget in the lower-right displaying power status LED (<font color='#48f060'>TX ON</font> / <font color='#f05050'>STBY</font>), 4-segment battery bar, and RF coverage.<br/>" +
            "* <font color='#e0f4e0'>Battery Stages:</font> 4 Bars Green (&gt;75%), 3 Bars Yellow (&gt;50%), 2 Bars Orange (&gt;25%), 1 Bar Red (&gt;10%), Flashing Red (&lt;=10% critical auto-shutdown alert).<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Directional Hunter Combo (Spectrum Device)</font><br/>" +
            "* <font color='#e0f4e0'>Equipment:</font> Draw the Contact DLC Spectrum Device (<font face='EtelkaMonospacePro'>hgun_esd_01_F</font>) while wearing a Radio Pack.<br/>" +
            "* <font color='#e0f4e0'>Beam Modes &amp; 3D Antennas:</font> Press <font color='#68d4f8'>PageUp / PageDown</font> (or ACE menu) to swap the physical 3D muzzle antenna (2-second progress bar):<br/>" +
            "  - <font color='#68d4f8'>Military Horn Paddle (45°):</font> 600m max range / 3x power drain (15 min runtime).<br/>" +
            "  - <font color='#68d4f8'>Cross-Dipole Array (20°):</font> 1000m max range / 4x power drain (11.2 min runtime).<br/>" +
            "  - <font color='#68d4f8'>Jammer Radome Tube (10°):</font> 1500m max range / 5x power drain (9 min runtime).<br/>" +
            "* <font color='#e0f4e0'>Passive Scanner &amp; Trigger Pulse (STBY Mode):</font><br/>" +
            "  - Even when the backpack is OFF (<font color='#f05050'>STBY</font>, 0% battery drain), the Spectrum Device passively scans up to the attached antenna's range (<font color='#68d4f8'>600m / 1000m / 1500m</font> with <font color='#68d4f8'>SCAN</font> indicator).<br/>" +
            "  - <font color='#68d4f8'>Hold Left-Click (Trigger):</font> Fires a momentary directional RF burst (<font color='#68d4f8'>PULSE</font>), engaging burn-through lock and draining battery only while the trigger is held.<br/>" +
            "* <font color='#e0f4e0'>RF Waveform Threat Identification (KAISERKOM LCD):</font><br/>" +
            "  - <font color='#ffe044'>Quadcopters / FPVs:</font> Jittering 2-peak twin spike (Control + Analog Video carrier).<br/>" +
            "  - <font color='#ffe044'>Fixed-Wing Recon Planes:</font> Steady 3-peak flat-top plateau (Encrypted SatCom datalink).<br/>" +
            "  - <font color='#ffe044'>Ground UGVs (Stomper / ED-1D):</font> Jagged 4-peak sawtooth steps (Digital FHSS ground link).<br/>" +
            "  - <font color='#ffe044'>Hostile Ground Jammers:</font> Wide 5-peak turbulent noise wall across the band (use compass tape to triangulate enemy EW stations).<br/>" +
            "* <font color='#e0f4e0'>Burn-Through Lock:</font> Keep the enemy drone's yellow wave centered inside your vertical selection gate:<br/>" +
            "  - The top-right progress bar charges up (<font color='#ffe044'>0% to 100%</font>).<br/>" +
            "  - Time-to-kill scales with distance: 5s close-up, 15-20s at mid-range, up to 30s at 1500m.<br/>" +
            "  - Audio lock-on tone climbs in pitch as progress builds.<br/>" +
            "  - Actively burning through surges battery drain by an extra 2x.<br/>" +
            "  - At 100% progress, connection severs and the drone drops into fail-safe!<br/>" +
            "  - If your aim slips, progress decays gradually over 6-8 seconds rather than resetting instantly.<br/>"
        ]];
    };
};
