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

// Start recovery & autonomous UAV crit-zone monitor strictly on the Server
if (isServer) then {
    [{
        call FUNC(ewar_recoveryLoop);
    }, 1.0, []] call CBA_fnc_addPerFrameHandler;
};

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
                playSoundUI ["ACE_Sound_Click", 0.5, 1.8];
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
                playSoundUI ["ACE_Sound_Click", 0.5, 0.9];
                [5] call FUNC(ewar_updateBackpackHUD);
            };
            true
        },
        {},
        [0xD1, [false, false, false]]
    ] call CBA_fnc_addKeybind;

    // Register Briefing Diary Records for EWAR C-UAS System
    // Note: Arma 3 createDiaryRecord prepends records (LIFO), so we create 5 -> 4 -> 3 -> 2 -> 1
    // to have them displayed chronologically (1. Quick Start, 2. Directional Hunter, 3. Threat Signatures, 4. Pilot, 5. Zeus) in the UI.
    if (missionNamespace getVariable [QEGVAR(Settings,showDiaryRecords), true]) then {
        if !(player diarySubjectExists "deScripts_ewar") then {
            player createDiarySubject ["deScripts_ewar", "EWAR C-UAS Guide"];
        };

        // 5. Zeus & Mission Maker Reference
        player createDiaryRecord ["deScripts_ewar", [
            "5. Zeus & Mission Maker Reference",
            "<font size='16' color='#68d4f8'>ZEUS &amp; MISSION MAKER REFERENCE</font><br/>" +
            "<font color='#98a6b4'>Curator modules and mission scripting entry points for mission creators.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. ZEN Curator Modules</font><br/>" +
            "Located under category <font color='#68d4f8'>TFG EWAR</font> in the Zeus context menu:<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Create Jammer Area:</font> Places a static jammer bubble at the cursor with configurable radius (50m-1500m), core cut ratio, and side exemption.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Attach Jammer to Object:</font> Attaches a mobile/destructible jammer bubble to any vehicle, antenna mast, or radar structure.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Equip Jammer Backpack (AI):</font> Equips an AI soldier with a faction Radio Pack that jams until death (no batteries required).<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Remove Nearby Jammers:</font> Removes jammers from clicked objects or clears static jammer bubbles within 100m.<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Mission Init Scripting API</font><br/>" +
            "Execute from an object's init box in the Eden Editor or via server script:<br/>" +
            "<font color='#98a6b4'>// Add a 300m jammer bubble to this object/vehicle:</font><br/>" +
            "<font face='EtelkaMonospacePro' color='#e0ffe0'>&nbsp;&nbsp;[this, 300] call deScripts_fnc_ewar_addJammer;</font><br/><br/>" +
            "<font color='#98a6b4'>// Remove active jammer bubble from this object:</font><br/>" +
            "<font face='EtelkaMonospacePro' color='#e0ffe0'>&nbsp;&nbsp;[this] call deScripts_fnc_ewar_removeJammer;</font><br/><br/>" +

            "<font size='14' color='#ffe044'>C. CBA Addon Options</font><br/>" +
            "All parameters can be tuned in real-time under:<br/>" +
            "<font color='#e0f4e0'>Options &gt; Addon Options &gt; deScripts Mission Settings &gt; 9; Electronic Warfare</font>."
        ]];

        // 4. UAV Pilot Survival Guide
        player createDiaryRecord ["deScripts_ewar", [
            "4. UAV Pilot Survival Guide",
            "<font size='16' color='#68d4f8'>UAV PILOT SURVIVAL &amp; COUNTER-MEASURES</font><br/>" +
            "<font color='#98a6b4'>What to do when flying into active electronic warfare environments.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. Recognizing Jamming Symptoms</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Visual Static &amp; Color Fringing:</font> Analog static snow and chromatic aberrations appear on your optical camera feed.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>HUD Signal Meter:</font> A 5-bar meter appears on your optics HUD, escalating from <font color='#ffffff'>White</font> &gt; <font color='#ffe044'>Yellow</font> &gt; <font color='#ff9922'>Orange</font> &gt; <font color='#ff4444'>Red</font> &gt; <font color='#ff2222'>Flashing Red</font>.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Directional Dwell Warning:</font> If an EW specialist is tracking you with a directional beam, signal degradation escalates rapidly over several seconds.<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Defensive Evasive Reactions</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Break Line of Sight:</font> Directional jamming requires direct boresight aim. Dive behind ridges, treelines, or buildings to break lock and bleed the operator's burn progress.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Turn Away &amp; Extend:</font> Increase standoff distance immediately. Max distance extends the operator's required dwell time up to 30 seconds, giving you ample time to escape.<br/><br/>" +

            "<font size='14' color='#ffe044'>C. Fail-Safe Behaviors (Connection Severed)</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Rotary / Micro-UAVs (Darter, Black Hornet, Hunter, Pelican):</font> Autopilot initiates a vertical controlled auto-landing descent.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Fixed-Wing Recon (Raven, Greyhawk, Sentinel):</font> Enters an autonomous 250m circular holding orbit at current altitude.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Loitering Munitions / FPVs:</font> Engine cuts immediately; falls ballistically.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Link Recovery:</font> Once the drone drifts clear of the jammer or the jammer is destroyed, friendly terminal control restores automatically."
        ]];

        // 3. Threat RF Signatures
        player createDiaryRecord ["deScripts_ewar", [
            "3. Threat RF Signatures",
            "<font size='16' color='#68d4f8'>RF WAVEFORM THREAT IDENTIFICATION</font><br/>" +
            "<font color='#98a6b4'>Recognizing and classifying enemy transmitters on the KAISERKOM LCD screen.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. Rotary Quadcopters &amp; FPV Attack Drones</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Waveform:</font> Connected twin-peak <font color='#ffe044'>'M' Wave</font> (dual carriers: C2 control link + analog video feed).<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Behavior:</font> High-frequency vertical jitter; fast azimuth shifts as the drone maneuvers.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Threat Level:</font> Extreme. High probability of loitering munition or explosive payload.<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Fixed-Wing Reconnaissance UAVs</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Waveform:</font> Wide, solid <font color='#ffe044'>Flat-Top Mesa / Plateau</font> across contiguous frequency bins.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Behavior:</font> Stable amplitude; slow, steady bearing drift consistent with high-altitude orbital patterns.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Threat Level:</font> Medium / Strategic. Indicates enemy artillery spotting or strike coordination.<br/><br/>" +

            "<font size='14' color='#ffe044'>C. Unmanned Ground Vehicles (UGVs)</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Waveform:</font> Connected 3-step <font color='#ffe044'>Ascending Staircase / Sawtooth</font> wave.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Behavior:</font> Rhythmic amplitude pulsing from FHSS (Frequency-Hopping Spread Spectrum) ground datalink.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Threat Level:</font> Ground scout / armed combat vehicle.<br/><br/>" +

            "<font size='14' color='#ffe044'>D. Hostile Electronic Warfare Jammers</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Waveform:</font> Wide 14 MHz <font color='#ff4444'>Boiling Noise Wall</font> spanning across the analyzer display.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Behavior:</font> High continuous amplitude; turbulent boiling noise floor.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Tactical Action:</font> Use the Spectrum Device's compass tape and azimuth readout to take multi-point triangulation bearings on the hostile EW site."
        ]];

        // 2. Directional Hunter & Antennas Guide
        player createDiaryRecord ["deScripts_ewar", [
            "2. Directional Hunter & Antennas Guide",
            "<font size='16' color='#68d4f8'>DIRECTIONAL HUNTER &amp; ANTENNAS</font><br/>" +
            "<font color='#98a6b4'>Operating the Spectrum Device in combination with the Radio Pack.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. The Hunter-Killer Concept</font><br/>" +
            "Drawing the Contact DLC <font color='#e0f4e0'>Spectrum Device</font> (<font face='EtelkaMonospacePro'>hgun_esd_01_F</font>) while wearing any Radio Pack backpack connects the transmitter into a high-powered, focused directional jammer.<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Physical Antennas &amp; Beam Modes</font><br/>" +
            "Cycle antenna modes with <font face='EtelkaMonospacePro' color='#ffffff'>[ PAGE UP ]</font> / <font face='EtelkaMonospacePro' color='#ffffff'>[ PAGE DOWN ]</font> or via ACE Self-Interaction (plays a 2-second reload animation to swap the 3D muzzle antenna):<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#68d4f8'>Military Horn Paddle (45° | 600m):</font> Wide horizontal scan (±45°), 600m max range, 3x battery drain (15 min continuous runtime). Ideal for CQB, urban areas, and fast FPV drone defense.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#68d4f8'>Cross-Dipole Array (20° | 1000m):</font> Balanced scan aperture (±30°), 1000m max range, 4x battery drain (11.2 min runtime). Optimal for general squad security and patrol coverage.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#68d4f8'>Jammer Radome Tube (10° | 1500m):</font> Narrow surgical aperture (±15°), 1500m max range, 5x battery drain (9 min runtime). Designed for neutralizing high-altitude recon UAVs and distant enemy EW emitters.<br/><br/>" +

            "<font size='14' color='#ffe044'>C. Passive Direction-Finding &amp; Trigger Pulse</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Passive SCAN (0% Battery):</font> In <font color='#f05050'>STBY</font>, the device passively receives signals up to the attached antenna's range. Drones appear on the graph as you sweep your crosshair across their bearing.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Momentary Trigger Pulse:</font> Holding <font face='EtelkaMonospacePro' color='#ffffff'>[ LEFT CLICK ]</font> fires an immediate directional RF burst (<font color='#68d4f8'>PULSE</font>), initiating burn-through lock without having to manually switch on the backpack jammer.<br/><br/>" +

            "<font size='14' color='#ffe044'>D. Burn-Through Lock &amp; Line of Sight</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Line-of-Sight Required:</font> Buildings/walls dampen passive signals (60%) and hills heavily attenuate them (25%). Active directional burn-through requires a clear sightline; obstacles block lock charging.<br/>" +
            "<font color='#68d4f8'>▪</font> Keep the target's yellow signal centered inside the vertical cyan selection gate on the LCD screen.<br/>" +
            "<font color='#68d4f8'>▪</font> The lock progress bar charges from <font color='#ffe044'>0% to 100%</font> as the audio tone climbs in pitch.<br/>" +
            "<font color='#68d4f8'>▪</font> Dwell time scales with distance: 5s at close range, 15-20s at mid-range, up to 30s at 1500m.<br/>" +
            "<font color='#68d4f8'>▪</font> If your aim slips or the drone ducks behind cover, progress decays gradually over 6-8 seconds instead of wiping instantly.<br/>" +
            "<font color='#68d4f8'>▪</font> At 100% lock, link is severed (<font color='#ff4444'>KILL</font>) and the drone drops into fail-safe!"
        ]];

        // 1. C-UAS Quick Start & Equipment
        player createDiaryRecord ["deScripts_ewar", [
            "1. C-UAS Quick Start & Equipment",
            "<font size='16' color='#68d4f8'>EWAR C-UAS QUICK START GUIDE</font><br/>" +
            "<font color='#98a6b4'>Basic setup, controls, battery power, and RCU Mini-HUD reference.</font><br/><br/>" +

            "<font size='14' color='#ffe044'>A. Required Equipment</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Backpack Jammer:</font> Any Radio Pack backpack (<font face='EtelkaMonospacePro'>B_RadioBag_01_*</font>).<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Directional Scanner:</font> Contact DLC Spectrum Device (<font face='EtelkaMonospacePro'>hgun_esd_01_F</font>).<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Power Supply:</font> Standard UAV Batteries (<font face='EtelkaMonospacePro'>GX_UAVBattery</font> or <font face='EtelkaMonospacePro'>ACE_UAVBattery</font>).<br/><br/>" +

            "<font size='14' color='#ffe044'>B. Quick Controls</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Toggle Jammer:</font> <font color='#68d4f8'>ACE Self-Interaction</font> ➔ <font color='#ffe044'>Equipment</font> ➔ <font color='#48f060'>EWAR Jammer</font>.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Change Antenna / Beam Focus:</font> Press <font face='EtelkaMonospacePro' color='#ffffff'>[ PAGE UP ]</font> to narrow focus (longer range) or <font face='EtelkaMonospacePro' color='#ffffff'>[ PAGE DOWN ]</font> to widen.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Momentary Burst:</font> With Spectrum Device drawn, hold <font face='EtelkaMonospacePro' color='#ffffff'>[ LEFT CLICK ]</font>.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Replace Battery:</font> ACE Self-Interaction &gt; Equipment &gt; EWAR Jammer &gt; Replace Battery (4s progress bar).<br/><br/>" +

            "<font size='14' color='#ffe044'>C. Backpack Jammer Coverage &amp; Battery Life</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Omni Bubble:</font> 200m progressive static zone with a 75m emergency hard-kill core.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Battery Runtime:</font> 45 minutes continuous transmission in Omni mode on a single UAV battery.<br/><br/>" +

            "<font size='14' color='#ffe044'>D. RCU Mini-HUD Guide (Lower-Right)</font><br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#48f060'>TX ON / TX DIR:</font> Active continuous RF transmission.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#68d4f8'>SCAN / PULSE:</font> Passive signal detection or momentary trigger transmission.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#ffe044'>LOCK [xx%]:</font> Active burn-through dwell time charging on a tracked drone.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#ff4444'>KILL:</font> Link severed; drone forced into fail-safe mode.<br/>" +
            "<font color='#68d4f8'>▪</font> <font color='#e0f4e0'>Battery Indicator:</font> 4 Bars Green (&gt;75%), 3 Bars Yellow (&gt;50%), 2 Bars Orange (&gt;25%), 1 Bar Red (&gt;10%), Flashing Red (&le;10% critical auto-shutdown alert)."
        ]];
    };
};
