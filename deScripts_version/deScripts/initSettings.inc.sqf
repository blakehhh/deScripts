private _deScriptSettings = "deScripts Mission Settings";

// 1; Mission
[ // Mission Type
    QEGVAR(Settings,setMissionType),
    "LIST",
    ["Mission Type", "This will deside on what kind of startup hint you get on mission start."],
    [_deScriptSettings, "1; Mission"],
    [[0,1,2,3], ["Custom", "Operation", "Training", "Public"], 1],
    true,
    {},
    true
] call CBA_fnc_addSetting;


// 3; Player
[ // Documents
    QEGVAR(Settings,showDiaryRecords),
    "CHECKBOX",
    ["Documents","Allow the mission to write diary help documents."],
    [_deScriptSettings, "3; Player"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

// 4; Staging

[ // Show all loadouts
    QEGVAR(Settings,showAllLoadouts),
    "CHECKBOX",
    ["Show all loadouts","Allow the selection of any loadouts from the personal selection menu."],
    [_deScriptSettings, "4; Staging"],
    false,
    true,
    {
        params ["_value"];
        EGVAR(Staging,showAllLoadouts) = _value;
    },
    false
] call CBA_fnc_addSetting;
[ // Use Filtered Arsenal
    QEGVAR(Settings,useFilteredArsenal),
    "CHECKBOX",
    ["Use Filtered Arsenal","Use a filtered or show all items in the staging arsenal."],
    [_deScriptSettings, "4; Staging"],
    true,
    true,
    {},
    false
] call CBA_fnc_addSetting;



// 6; Item Replacement system
[ // Enable
    QEGVAR(Settings,allowReplaceItem),
    "CHECKBOX",
    ["Enable","Allow objects to be replaced with streamlined gear for consistency."],
    [_deScriptSettings, "6; Item Replacement"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Medical Items
    QEGVAR(Settings,replaceMedical),
    "LIST",
    ["Medical Items","Allow medical items to be replaced with our custom ones.\nNote: this system will not be disabled if the ace medical convert items is enabled."],
    [_deScriptSettings, "6; Item Replacement"],
    [[0,1], ["Disabled", "Convert medical equipment"], 1],
    true,
    {},
    true
] call CBA_fnc_addSetting;

// 7; Combat Jump Simulation
[ // Simulation Type
    QEGVAR(Settings,jumpSimulation),
    "LIST",
    ["Simulation Type","Combat jump simulation is a system that checks for lose equiped gear in the form of;\nnight vision googles, hats or glasses and make you lose the on a combat jump.\n    None: No simulation is done.\n    Basic: Lose gear unassigned.\n    Advanced: Lose gear is removed."],
    [_deScriptSettings, "7; Combat Jump Simulation"],
    [[0,1,2], ["None", "Basic", "Advanced"], 2],
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Include Night Vision Googles
    QEGVAR(Settings,jumpSimulationNVG),
    "CHECKBOX",
    ["Include Night Vision Googles","Include equiped Night Vison Googles in the simulation."],
    [_deScriptSettings, "7; Combat Jump Simulation"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Include Non-combat Googles
    QEGVAR(Settings,jumpSimulationGlasses),
    "CHECKBOX",
    ["Include Non-combat Googles","Include Non-combat Googles in the simulation. This refere to sunshades and simular non-safety googles."],
    [_deScriptSettings, "7; Combat Jump Simulation"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Include Non-combat Headgear
    QEGVAR(Settings,jumpSimulationHat),
    "CHECKBOX",
    ["Include Non-combat Headgear","Include Non-combat Headgear in the simulation. This refere to hats bandanas and baretes."],
    [_deScriptSettings, "7; Combat Jump Simulation"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;


// 8; Zeus
[ // Enable Custom Zeus Moduels
    QEGVAR(Settings,enable7cavZeusModules),
    "CHECKBOX",
    ["Enable Custom Zeus Moduels","Allow mission to add 7Cav moduels using the Achilles or ZEN framework."],
    [_deScriptSettings, "8; Zeus"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

// 9; Electronic Warfare
[
    QEGVAR(Settings,ewar_enable),
    "CHECKBOX",
    ["Enable EWAR Drone Jamming", "Enables counter-UAS jamming fields and interference."],
    [_deScriptSettings, "9; Electronic Warfare"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_failsafeBehavior),
    "LIST",
    ["Drone Fail-safe Behavior", "What happens to drones when link is completely cut."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [[0, 1, 2], ["Realistic (Quads Auto-Land, Planes Orbit)", "Engine Cut (All Crash)", "Disconnect Terminal Only"], 0],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_backpackRadius),
    "SLIDER",
    ["Backpack Jammer Radius (m)", "Jamming radius of player-operated Radio Pack backpacks."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [50, 600, 200, 0],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_backpackCoreRatio),
    "SLIDER",
    ["Backpack Core Cut Ratio", "Inner fraction of radius where link is completely severed (0.375 = 75m kill at 200m radius)."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [0, 0.9, 0.375, 3],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_backpackRequiresBattery),
    "CHECKBOX",
    ["Backpack Requires Batteries", "Requires UAV batteries (GX or ACE) to power player backpack jammers."],
    [_deScriptSettings, "9; Electronic Warfare"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_backpackBatteryLife),
    "SLIDER",
    ["Battery Runtime (Minutes)", "Duration a single UAV battery will power the backpack jammer."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [1, 60, 30, 0],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_directionalMultiplier),
    "SLIDER",
    ["Directional Range Multiplier", "Range amplification factor when wielding the Spectrum Device (hgun_esd_01_F)."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [1.5, 5.0, 3.0, 1],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_directionalConeAngle),
    "SLIDER",
    ["Directional 3D Cone Angle (Degrees)", "Total 3D beam width angle when aiming the Spectrum Device."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [15, 90, 45, 0],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,ewar_directionalPowerDrain),
    "SLIDER",
    ["Directional Battery Drain Multiplier", "Battery drain rate multiplier when operating in directional mode."],
    [_deScriptSettings, "9; Electronic Warfare"],
    [1.0, 3.0, 1.5, 1],
    true,
    {},
    true
] call CBA_fnc_addSetting;



