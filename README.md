# deScripts Architectural Reference Guide

> **Quick Reference Document** for understanding, maintaining, and assessing the **deScripts** Arma 3 mission framework.

---

## Table of Contents
1. [Architectural Overview & Lifecycle](#1-architectural-overview--lifecycle)
   - [Boot & Execution Timeline](#boot--execution-timeline)
   - [Subsystem Relationships](#subsystem-relationships)
2. [Quick Start: Mission Maker Functions (3DEN Init)](#2-quick-start-mission-maker-functions-3den-init)
   - [Airborne & Parachute Operations](#1-airborne--parachute-operations)
   - [Staging Logistics, Crates & Lockers](#2-staging-logistics-crates--lockers)
   - [Aviation & Vehicle Helpers](#3-aviation--vehicle-helpers)
   - [Base Optimization & Training Ranges](#4-base-optimization--training-ranges)
   - [Electronic Warfare & Drone Jamming (C-UAS)](#5-electronic-warfare--drone-jamming-c-uas)
3. [Root Files & Engine Entry Points](#3-root-files--engine-entry-points)
4. [deScripts Core Headers & Life-Cycle Scripts](#4-cscripts-core-headers--life-cycle-scripts)
5. [Initialization Subsystem (`deScripts/functions/init/`)](#5-initialization-subsystem-cscriptsfunctionsinit)
6. [Gear & Loadout Subsystem](#6-gear--loadout-subsystem)
   - [Loadout Resolution Cascade](#loadout-resolution-cascade)
   - [Configuration Files (`deScripts/Loadouts/`)](#configuration-files-cscriptsloadouts)
   - [Gear Functions (`deScripts/functions/gear/`)](#gear-functions-cscriptsfunctionsgear)
7. [Logistics & Cargo Subsystem (`deScripts/functions/logistics/`)](#7-logistics--cargo-subsystem-cscriptsfunctionslogistics)
8. [Mission Helpers (`deScripts/functions/mission/`)](#8-mission-helpers-cscriptsfunctionsmission)
9. [Systems Engine (`deScripts/functions/systems/`)](#9-systems-engine-cscriptsfunctionssystems)
10. [ZEN Zeus Modules (`deScripts/functions/modules/`)](#10-zen-zeus-modules-cscriptsfunctionsmodules)
11. [Electronic Warfare Subsystem (`deScripts/functions/ewar/`)](#11-electronic-warfare-subsystem-descriptsfunctionsewar)
12. [Documents & Briefing Checklists (`deScripts/functions/documents/`)](#12-documents--briefing-checklists-cscriptsfunctionsdocuments)
13. [Diagnostics & Automated Testing (`diag/` & `testing/`)](#13-diagnostics--automated-testing-diag--testing)
14. [Data Assets Summary (`Data/` & `deScripts/Data/`)](#14-data-assets-summary-data--cscriptsdata)
15. [Common Maintenance Tasks ("Where do I change X?")](#15-common-maintenance-tasks-where-do-i-change-x)

---

## 1. Architectural Overview & Lifecycle

deScripts is structured around **CBA Extended Event Handlers (XEH)**, **ACE3 interaction systems**, and engine config hooks. Instead of running monolithic loops, it is event-driven: systems register callbacks, hooks, and ACE actions that execute only when needed (unit spawn, entering staging, opening crates, jumping from aircraft, or Zeus interaction).

### Boot & Execution Timeline

```
[Engine Mission Load]
  │
  ├──> description.ext
  │       ├── Includes deScripts/CfgFunctions.hpp  (Compiles deScripts_fnc_*)
  │       ├── Includes deScripts/CfgLoadouts.hpp   (Mounts loadout definitions)
  │       └── Declares CBA XEH hooks (Extended_PreInit / Extended_PostInit)
  │
  ├──> CBA parses cba_settings.sqf (forces baseline ACE/deScripts mission settings)
  │
[Phase 1: Engine Function PreInit (preInit = 1)]
  │
  ├──> deScripts_fnc_gear_preInit
  │       └── Registers CBA class event handlers on "CAManBase" (InitPost, Respawn, Local)
  │
  └──> deScripts_fnc_ewar_preInit
          └── Initializes GVAR(ewar_jammers) and binds synchronized CBA network event handlers
  │
[Phase 2: CBA Extended PreInit]
  │
  └──> deScripts/deScripts_preInit.sqf
          ├── Detects active mods (ACE, ACEX, Kat, ACRE2, TFAR, ZEN, etc.)
          ├── Registers CBA Addon Settings (deScripts/initSettings.inc.sqf)
          ├── Sets up staging arsenal defaults (deScripts_fnc_init_aceArsenal)
          ├── Compiles logistics database into memory (deScripts_fnc_init_logistics -> deScripts_DATABASE)
          ├── Loads equipment blacklist (deScripts/deScripts_blacklist.sqf -> deScripts_BLACKLIST)
          ├── Registers player chat commands (deScripts_fnc_init_chatCommands)
          ├── Registers ZEN / Zeus curator modules (deScripts_fnc_init_zenModuels)
          └── Binds server logger and player tracking (deScripts_fnc_init_eventHandlers)
  │
[Phase 3: Unit Creation & Engine InitPost]
  │
  └──> "CAManBase" InitPost executes per unit:
          └── Resolves role gear and applies loadout (deScripts_fnc_gear_selectLoadout & applyLoadout)
  │
[Phase 4: Engine Function PostInit (postInit = 1)]
  │
  ├──> deScripts_fnc_gear_postInitProxy -> deScripts_fnc_gear_postInit
  │       └── Hooks "ace_arsenal_displayClosed" to auto-cache custom loadouts
  │
  └──> deScripts_fnc_ewar_postInit
          └── Starts 0.5s client-side UAV jamming evaluation loop (CBA PFH) on player machines
  │
[Phase 5: CBA Extended PostInit]
  │
  └──> deScripts/deScripts_postInit.sqf
          ├── Replaces vanilla FAKs/Medikits with ACE medical (deScripts_fnc_init_aceItemReplace)
          ├── Displays player welcome & difficulty checks (deScripts_fnc_init_message)
          └── Generates briefing diary topics & checklists (deScripts_fnc_init_diary)
  │
[Phase 6: Engine Mission Init]
  │
  └──> init.sqf
          ├── Verifies MP environment
          ├── Sets ACE carry/drag constraints
          └── Hands off execution to custom mission-maker code
```

### Subsystem Relationships

```
                     ┌──────────────────────────────────────────┐
                     │          deScripts_preInit.sqf            │
                     └────┬─────────────────────────────────┬───┘
                          │                                 │
                          v                                 v
        ┌───────────────────────────────────┐     ┌───────────────────────────────────┐
        │       Logistics & Supply DB       │     │     Loadouts & Gear Management    │
        │      (deScripts_logistics.sqf)     │     │    (CfgLoadouts.hpp / gear_*)     │
        └─────────────────┬─────────────────┘     └─────────────────┬─────────────────┘
                          │                                         │
                          ├────────────────────┬────────────────────┤
                          │                    │                    │
                          v                    v                    v
                 ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
                 │ Staging Crates  │  │ Personal Locker │  │ Filtered Staging│
                 │ & Resupply Carts│  │  (addLoadout-   │  │   ACE Arsenal   │
                 │ (fn_doStarter-  │  │    Locker.sqf)  │  │  (fn_addArsenal │
                 │    Crate.sqf)   │  │                 │  │     .sqf)       │
                 └────────┬────────┘  └────────┬────────┘  └────────┬────────┘
                          │                    │                    │
                          └────────────────────┼────────────────────┘
                                               │
                                               v
                          ┌─────────────────────────────────────────┐
                          │         Mission & Live Operations       │
                          │ - ZEN Zeus Modules (modules/zenModule_*)│
                          │ - Airborne Systems (systems/fn_para_*)  │
                          │ - In-Flight Dismounts (fn_addGetOutHelo)│
                          │ - Training Targets (systems/training_*) │
                          │ - Vehicle Decals (fn_setVehicleLable)   │
                          └─────────────────────────────────────────┘
```

---

## 2. Quick Start: Mission Maker Functions (3DEN Init)

These functions are designed for mission makers to paste directly into an object or vehicle's **Init** field in the 3DEN Editor.

> **Namespace Note:** Both legacy `cScripts_fnc_*` and modern `deScripts_fnc_*` prefixes are fully supported. Core compositions and staging crates remain 100% backwards compatible.

---

### 1. Airborne & Parachute Operations

#### **HALO Jump** (`deScripts_fnc_addHaloJump`)
Attaches a high-altitude HALO freefall jump hold action to transport aircraft (C-130J, V-44X Blackfish, CH-47 Chinook, etc.). Checks altitude and validates open ramp/doors before displaying the jump action. Automatically front-mounts the player's backpack and restores it upon landing.

```sqf
// Default: Requires >= 5000m altitude, ramp/doors open, equips steerable "B_Parachute"
[this] call deScripts_fnc_addHaloJump;

// Custom altitude (e.g. 4000m):
[this, 4000] call deScripts_fnc_addHaloJump;

// Full syntax: [_vehicle, _minAltitude (default 5000), _chuteBackpackClass (default "B_Parachute"), _allowStaggered (default false)]
[this, 4500, "B_Parachute", true] call deScripts_fnc_addHaloJump;
```

#### **Static Line Jump** (`deScripts_fnc_addLineJump`)
Attaches a static line mass-drop hold action to transport aircraft. Validates drop altitude window, safe airspeed, and ramp/door status before ejecting paratroopers directly into canopy.

```sqf
// Default: Alt 180m–350m, Speed <= 310 km/h, equips "NonSteerable_Parachute_F"
[this] call deScripts_fnc_addLineJump;

// Custom drop corridor (e.g. 150m min altitude):
[this, 150] call deScripts_fnc_addLineJump;

// Full syntax: [_vehicle, _minAlt (default 180), _maxAlt (default 350), _maxSpeed (default 310), _chuteVehicleClass, _allowStaggered]
[this, 150, 400, 280, "NonSteerable_Parachute_F", true] call deScripts_fnc_addLineJump;
```

---

### 2. Staging Logistics, Crates & Lockers

#### **Starter Crate** (`cScripts_fnc_doStarterCrate` / `deScripts_fnc_doStarterCrate`)
Transforms any crate or container into a Task Force Grey staging supply point. Configures ACE loadout selection, Re-Gear, Heal, Insignia selection, field meals, role qualifications, and automatic ground debris cleanup.

```sqf
// Standard Starter Crate (Empty inventory, ReGear, Heal, Insignia, Role-filtered loadouts)
[this] call cScripts_fnc_doStarterCrate;

// Pre-fill with default Task Force Grey logistics supplies:
[this, "tfg default"] call cScripts_fnc_doStarterCrate;

// Show ALL company loadouts (unrestricted role selection):
[this, "none", true, true, true, true] call cScripts_fnc_doStarterCrate;

// Enable direct sanitized ACE Arsenal on the crate:
[this, "none", true, true, true, false, true] call cScripts_fnc_doStarterCrate;

// Minimal crate (Re-Gear and Heal only, no loadout switching):
[this, "manual", true, true, false] call cScripts_fnc_doStarterCrate;
```

**Parameters Reference:**
```sqf
/*
 * Arguments:
 * 0: Object              <OBJECT>
 * 1: Supplies Type       <STRING>  "none", "tfg default", "full", "all", "manual" (Default: "none")
 * 2: ReGear Action       <BOOL>    (Default: true)
 * 3: Heal Action         <BOOL>    (Default: true)
 * 4: Insignia Selection  <BOOL>    (Default: true)
 * 5: Show All Loadouts   <BOOL>    (Default: false - respects player permissions)
 * 6: Direct ACE Arsenal  <BOOL>    (Default: false - adds sanitized arsenal)
 * 7: Staging Area        <BOOL>    (Default: true)
 */
```

#### **Personal Loadout Locker** (`cScripts_fnc_addLoadoutLocker` / `deScripts_fnc_addLoadoutLocker`)
Turns a locker prop, footlocker, or crate into a claimed personal storage station. Allows individual players to claim the locker, lock out other players, save custom ACE kits, and re-equip their saved gear across sessions.

```sqf
// Standard Personal Locker:
[this] call cScripts_fnc_addLoadoutLocker;

// Locker with custom height offset (useful for stacked lockers or lockers placed on furniture):
[this, 0.5] call cScripts_fnc_addLoadoutLocker;

// Full syntax: [_object, _heightOffset (number or [x,y,z]), _markerHeight (default 0.75)]
[this, [0, 0, 0.2], 0.85] call cScripts_fnc_addLoadoutLocker;
```

#### **Filtered Staging Arsenal** (`cScripts_fnc_addArsenal` / `deScripts_fnc_addArsenal`)
Adds an on-demand, role-filtered ACE Staging Arsenal interaction to an object:
```sqf
[this] call cScripts_fnc_addArsenal;
```

#### **Medical Field Hospital** (`deScripts_fnc_doFieldHospital`)
Designates an object or medical tent as an official ACE Medical Facility (`ace_medical_isMedicalFacility = true`) and stocks it with comprehensive Atlas medical supplies:
```sqf
[this] call deScripts_fnc_doFieldHospital;
```

#### **Standalone Re-Gear & Heal** (`cScripts_fnc_addReGear` & `cScripts_fnc_addHeal`)
Adds dedicated single-purpose ACE interactions to objects:
```sqf
[this] call cScripts_fnc_addReGear; // Resets unit ammo, explosives, and role gear
[this] call cScripts_fnc_addHeal;   // Full ACE medical heal
```

#### **Direct Loadout Action** (`deScripts_fnc_addLoadoutAction`)
Adds a simple scroll-wheel action to equip a specific loadout directly from `CfgLoadouts`:
```sqf
[this, "Equip Heavy Weapons Gunner", "Cav_B_B_Weapons_Gunner_F"] call deScripts_fnc_addLoadoutAction;
```

---

### 3. Aviation & Vehicle Helpers

#### **Helicopter Quick Dismount** (`deScripts_fnc_addGetOutHelo`)
Adds quick-dismount actions ("Get out Left Side" / "Get out Right Side") to transport helicopters for rapid cargo egress:
```sqf
[this] call deScripts_fnc_addGetOutHelo;
```

#### **Escape Wreck** (`deScripts_fnc_addEscapeWreck`)
Attaches a hold action to aircraft allowing pilots, crew, and passengers to safely egress destroyed or burning wrecks:
```sqf
[this] call deScripts_fnc_addEscapeWreck;
```

#### **Tactical Vehicle Decals & Callouts** (`deScripts_fnc_setVehicleLable`)
Attaches tactical unit markings, platoon letters, and numbers to vehicles using 3D textures:
```sqf
// UH-60 Black Hawk Tail Markings (Letter, Number):
[this, "B", "1"] call deScripts_fnc_setVehicleLable;

// C-130 Hercules Markings:
[this, "A", "2"] call deScripts_fnc_setVehicleLable;

// Red Cross / Medical Decal:
[this, "RedCross"] call deScripts_fnc_setVehicleLable;
```

---

### 4. Base Optimization & Training Ranges

#### **Ambient Base AI Optimizer** (`deScripts_fnc_makeAgent`)
Converts an editor-placed AI soldier into an ambient Arma agent (`createAgent`). Strips combat FSM overhead, weapon processing, and pathfinding compute, drastically boosting server FPS at main operating bases:
```sqf
[this] call deScripts_fnc_makeAgent;
```

#### **Range Target Hit Indicator** (`deScripts_fnc_training_addHitIndicator`)
Spawns 3D impact marker spheres on target silhouettes where bullets strike:
```sqf
// Mark hits directly on target:
[this] call deScripts_fnc_training_addHitIndicator;

// Mirror hits onto a separate shooter feedback board:
[this, feedbackBoardObject] call deScripts_fnc_training_addHitIndicator;
```

#### **Range Target Control Console** (`deScripts_fnc_training_addTargetComputer`)
Disables automatic target popup and links targets to a control object/laptop with a "Reset Range Targets" interaction:
```sqf
[this, [target1, target2, target3, target4]] call deScripts_fnc_training_addTargetComputer;
```

---

### 5. Electronic Warfare & Drone Jamming (C-UAS)

#### **Add EWAR Jammer** (`deScripts_fnc_ewar_addJammer` / `cScripts_fnc_ewar_addJammer`)
Attaches an omnidirectional counter-UAS electronic jamming bubble to any vehicle, radar dish, structure, marker, or position. When an enemy or player drone enters the bubble, the operator experiences progressive RF video snow, audio clicks, and a dynamic 5-bar HUD signal degradation meter.

```sqf
// Standard 300m Jammer Bubble (Interference-only, defaults to 0 critical cut):
[this] call deScripts_fnc_ewar_addJammer;

// 500m Bubble attached to an enemy radar truck:
[this, 500] call deScripts_fnc_ewar_addJammer;

// 400m Bubble with inner 30% hard cutoff (drones within 120m are forced into fail-safe):
[this, 400, 0.3] call deScripts_fnc_ewar_addJammer;

// 600m Jammer attached to a map marker, exempting BLUFOR (west) drones:
["marker_jammer_obj", 600, 0, west] call deScripts_fnc_ewar_addJammer;
```

**Parameters Reference:**
```sqf
/*
 * Arguments:
 * 0: Source Object, Position, or Marker <OBJECT|ARRAY|STRING>
 * 1: Max Jamming Radius in meters       <NUMBER>  (Default: 300)
 * 2: Core Cut Ratio (0 = soft only)     <NUMBER>  (Default: 0 - 0.3 = inner 30% severs link)
 * 3: Exempt Side(s)                     <SIDE|ARRAY> (Default: sideUnknown)
 *
 * Return: Jammer ID <STRING>
 */
```

#### **Remove EWAR Jammer** (`deScripts_fnc_ewar_removeJammer` / `cScripts_fnc_ewar_removeJammer`)
Dynamically disables and cleans up an active jammer by its returned ID or attached source object:
```sqf
// Remove by object reference:
[this] call deScripts_fnc_ewar_removeJammer;

// Remove by ID string:
["ewar_jammer_12345_67"] call deScripts_fnc_ewar_removeJammer;
```

---

## 3. Root Files & Engine Entry Points

| File | Purpose & Architectural Role | When / How It Runs | Key Parameters / Variables |
|---|---|---|---|
| `description.ext` | Mission configuration header. Declares engine metadata, MP rules, respawn templates, remote execution policies, garbage collection, ACEX Fortify presets, and includes `CfgFunctions.hpp` and `CfgLoadouts.hpp`. | Evaluated by Arma engine on mission load. | `cba_settings_hasSettingsFile = 1`, `cba_settings_whitelist[]`, `respawn = BASE`, `ACEX_Fortify_Presets`. |
| `init.sqf` | Standard mission startup script. Runs on all clients, server, and headless clients. Partition between core deScripts framework and mission-maker scripts. | Executes after preInit and concurrent with postInit. | Sets `ACE_maxWeightCarry = 8000`, `ACE_maxWeightDrag = 12000`. User scripts go below line 27. |
| `cba_settings.sqf` | Master CBA settings configuration containing forced mission settings (`force force <setting> = <value>;`). Standardizes ACE medical, fatigue, ballistics, radios, and deScripts behavior across all clients. | Parsed and locked by CBA on mission startup. | Forces `deScripts_Settings_*` flags (mission type, diary records, jump simulation, filtered arsenal). |
| `version.txt` | Single-line release tag file. | Read by automated build and packaging scripts (`tools/build.py`). | Current version tag (e.g., `V1.1.3`). |

---

## 4. deScripts Core Headers & Life-Cycle Scripts

| File | Purpose & Architectural Role | When / How It Runs | Key Contents / Details |
|---|---|---|---|
| `deScripts/script_component.hpp` | Component configuration header. Defines root project constants and global toggles. | Included at the top of every SQF and HPP file. | Defines `PREFIX deScripts`, `VERSION "4.5.21"`, and the commented-out `DEBUG_MODE` toggle. |
| `deScripts/script_macros.hpp` | Master preprocessor macro definitions library. Provides namespacing, formatting, safe variable setters, and multi-tier logging macros. | Preprocessed across the framework. | `FUNC()`, `GVAR()`, `SETVAR()`, `GETVAR()`, `SHOW_LOG()`, `SHOW_CHAT_WARNING()`, `SHOW_SERVER_INFO()`. |
| `deScripts/CfgFunctions.hpp` | Registers all framework functions into Arma's `CfgFunctions` under tag `deScripts` (`deScripts_fnc_*`). | Included in `description.ext`. | Organizes functions into categories: `init`, `gear`, `logistics`, `mission`, `systems`, `modules`, `documents`, `diag`, `testing`. |
| `deScripts/deScripts_preInit.sqf` | Master pre-initialization orchestrator. Runs mod detection, sets global state flags, compiles databases, registers chat commands, curator modules, and core event handlers. | Executed via CBA `Extended_PreInit_EventHandlers`. | Initializes `deScripts_Staging_ZoneStatus`, `deScripts_DATABASE`, `deScripts_BLACKLIST`, mod detection flags (`deScripts_patches_uses*`). |
| `deScripts/deScripts_postInit.sqf` | Master post-initialization orchestrator. Runs item replacement, player welcome messages, and briefing generation once entities exist in 3D world. | Executed via CBA `Extended_PostInit_EventHandlers`. | Triggers `fn_init_aceItemReplace`, `fn_init_message`, and `fn_init_diary`. |
| `deScripts/initSettings.inc.sqf` | CBA Addon Settings registration file. Injects deScripts configuration options into the CBA UI and pause menu. | Included inline by `deScripts_preInit.sqf`. | Defines `deScripts_Settings_setMissionType`, `showDiaryRecords`, `useFilteredArsenal`, `replaceMedical`, `jumpSimulation`, etc. |

---

## 5. Initialization Subsystem (`deScripts/functions/init/`)

| File | Function | Purpose & How It Works |
|---|---|---|
| `fn_init_aceArsenal.sqf` | `deScripts_fnc_init_aceArsenal` | Manages staging arsenal lifecycle events and default loadout injection. Sets up `"ace_arsenal_displayClosed"` to cleanup temporary arsenal containers and save the player's selected insignia to `profileNamespace`. |
| `fn_init_aceItemReplace.sqf` | `deScripts_fnc_init_aceItemReplace` | Uses `ace_common_fnc_registerItemReplacement` to automatically convert vanilla `FirstAidKit` and `Medikit` items into standardized ACE Medical supplies (QuickClot, splints, tourniquets, morphine, saline). |
| `fn_init_chatCommands.sqf` | `deScripts_fnc_init_chatCommands` | Registers user chat commands via CBA: `#attendance` (triggers attendance report event), `#deScripts` (displays framework version), and `#loadout` (displays player's current loadout class). |
| `fn_init_diary.sqf` | `deScripts_fnc_init_diary` | Generates briefing records on the map screen. Creates subjects `"TFG"`, `"Chklists"` (Checklists), and `"radioReports"`, calling individual document generator functions. |
| `fn_init_eventHandlers.sqf` | `deScripts_fnc_init_eventHandlers` | Registers framework event handlers: CBA `deScripts_getAttendance`, server log routing (`deScripts_log_text`), and connection tracking (`PlayerConnected` -> `deScripts_log_players` HashMap). |
| `fn_init_logistics.sqf` | `deScripts_fnc_init_logistics` | Parses and compiles `deScripts_logistics.sqf` into an in-memory HashMap stored in the global variable `deScripts_DATABASE`. |
| `fn_init_message.sqf` | `deScripts_fnc_init_message` | Runs on client postInit. Validates server difficulty (warns in chat if not Veteran/Custom) and handles player welcome messages. |
| `fn_init_zenModuels.sqf` | `deScripts_fnc_init_zenModuels` | Registers custom Task Force Grey curator modules into ZEN under categories `"TFG AI"`, `"TFG Logistics"`, `"TFG Utilities"`, `"TFG Mission"`, and `"TFG EWAR"`. |

---

## 6. Gear & Loadout Subsystem

The Gear subsystem automates loadout assignment, saves customized kits, resolves role inheritance, and enforces equipment standards.

### Loadout Resolution Cascade

When a unit spawns, respawns, or changes locality, `deScripts_fnc_gear_selectLoadout` evaluates the unit using a strict 5-tier fallback cascade:

```
1. Saved / Cached Loadout?  ──[Yes]──> Return cached array (deScripts_gear_loadout)
            │ [No]
2. Unit Variable Set?       ──[Yes]──> Return class (deScripts_Gear_LoadoutClass)
            │ [No]
3. 3DEN vehicleVarName?     ──[Yes]──> Return class matching editor name
            │ [No]
4. Unit typeOf (Classname)? ──[Yes]──> Return class matching CfgVehicles class
            │ [No]
5. Side Default Fallback?   ──[Yes]──> Return CommonBlufor / CommonOpfor / etc.
            │ [No]
   Fallback to "" (with chat warning)
```

### Configuration Files (`deScripts/Loadouts/`)

| File | Purpose & Role | Key Classes / Config Entries |
|---|---|---|
| `deScripts/CfgLoadouts.hpp` | Master loadout config root included in `description.ext`. Serves as the mounting point for mission loadout classes. | Defines empty `class CfgLoadouts {};` which is populated and extended by loadout headers. |
| `deScripts/deScripts_blacklist.sqf` | Returns an array of forbidden weapon, launcher, optic, and item classnames stored in `deScripts_BLACKLIST`. | Queried by starter crates and lockers to sanitize arsenals and prevent unapproved equipment from being taken. |
| `deScripts/Loadouts/CfgLoadouts_Bravo_Viking_Weapons.hpp` | Defines platoon-level heavy weapons squad loadouts for Bravo Company (Viking). | Roles: M240B Fireteam Leader, M240B Machinegunner, Ammo Bearer, MAAWS Gunner, MAAWS Assistant, 60mm Mortar Gunner/Assistant. |
| `deScripts/Loadouts/CfgLoadouts_Special.hpp` | Defines specialized headquarters and controller loadouts. | S3 Operations / Mission Controllers (`S3_Base`, `S3`, `S3_1` to `S3_6`). Injects `deScripts_Player_Unit = 'S3'` via `preLoadout`. |
| `deScripts/Loadouts/CfgLoadouts_Training.hpp` | Defines training cadres and recruit gear for qualification ranges. | `Cav_B_Training_Cadre_F` (Instructor), `Cav_B_Training_Cadet_F` (Recruit/Student). |

### Gear Functions (`deScripts/functions/gear/`)

| File | Function | Purpose & How It Works |
|---|---|---|
| `fn_gear_preInit.sqf` | `deScripts_fnc_gear_preInit` | Runs during engine preInit (`preInit = 1`). Hooks CBA event handlers on `CAManBase` (`InitPost`, `Respawn`, `Local`) to automatically assign gear. |
| `fn_gear_postInitProxy.sqf` | `deScripts_fnc_gear_postInitProxy` | Engine postInit bridge (`postInit = 1`). Uses `CBA_fnc_directCall` to execute `fn_gear_postInit.sqf` in an unscheduled environment. |
| `fn_gear_postInit.sqf` | `deScripts_fnc_gear_postInit` | Binds `"ace_arsenal_displayClosed"` event to auto-save custom loadouts and registers the `deScripts_gear_applyLoadout` CBA event. |
| `fn_gear_selectLoadout.sqf` | `deScripts_fnc_gear_selectLoadout` | Core decision engine. Evaluates the unit against the 5-tier resolution cascade and returns the target config class or loadout array. |
| `fn_gear_applyLoadout.sqf` | `deScripts_fnc_gear_applyLoadout` | Applies resolved gear via `CBA_fnc_setLoadout`. Executes `preLoadout` code, filters radio IDs via ACRE2, applies abilities and cosmetics, lowers weapon, and executes `postLoadout` code. |
| `fn_gear_applyAbilities.sqf` | `deScripts_fnc_gear_applyAbilities` | Configures ACE skills on the unit based on config tags: `abilityMedic` (sets `ace_medical_medicClass`), `abilityEngineer` (`ace_isEngineer`), `abilityEOD` (`ACE_isEOD`). |
| `fn_gear_applyCosmetics.sqf` | `deScripts_fnc_gear_applyCosmetics` | Sets player name without rank prefix, assigns in-game rank, applies team color, and applies uniform squad insignia with a 2-second CBA delay. |
| `fn_gear_applyFunctions.sqf` | `deScripts_fnc_gear_applyFunctions` | Automatically inserts ACE earplugs on spawn and grants the "Server Metrics" diagnostic action to logged-in server admins. |
| `fn_gear_getLoadoutDisplayName.sqf` | `deScripts_fnc_gear_getLoadoutDisplayName` | Returns the human-readable `displayName` of a unit's current loadout class for UI menus and attendance logs. |
| `fn_gear_getLoadoutName.sqf` | `deScripts_fnc_gear_getLoadoutName` | Returns the raw internal config classname currently assigned to a unit. |
| `fn_gear_getLoadoutRole.sqf` | `deScripts_fnc_gear_getLoadoutRole` | Returns the role category string (`"officer"`, `"medic"`, `"weapons"`, `"trooper"`) defined in the loadout config. |
| `fn_gear_getSideConfig.sqf` | `deScripts_fnc_gear_getSideConfig` | Maps a side (`west`, `east`, `independent`, `civilian`) to its default fallback base config class (`CommonBlufor`, `CommonOpfor`, etc.). |
| `fn_gear_hasSavedLoadout.sqf` | `deScripts_fnc_gear_hasSavedLoadout` | Returns `true` if the unit has a cached loadout saved from ACE Arsenal (`deScripts_Gear_SavedLoadout`). |
| `fn_gear_loadLoadout.sqf` | `deScripts_fnc_gear_loadLoadout` | Retrieves the saved loadout array from `_unit getVariable "deScripts_gear_loadout"`. |
| `fn_gear_removeLoadout.sqf` | `deScripts_fnc_gear_removeLoadout` | Clears saved loadout cache variables from a unit to reset them to standard default config gear. |
| `fn_gear_saveLoadout.sqf` | `deScripts_fnc_gear_saveLoadout` | Reads unit inventory with `CBA_fnc_getLoadout`, cleans radio IDs, saves the array to `deScripts_Gear_Loadout`, sets saved flag, and persists insignia to `profileNamespace`. |

---

## 7. Logistics & Cargo Subsystem (`deScripts/functions/logistics/`)

| File | Function | Purpose & How It Works |
|---|---|---|
| `deScripts/deScripts_logistics.sqf` | *Data Script* | Master dictionary of crate and vehicle inventories (`GVAR(DATABASE)`). Defines starter crates, resupply crates, infantry medical, Atlas medical, vehicle ammo, and arsenal whitelists. |
| `fn_addCargo.sqf` | `deScripts_fnc_addCargo` | Validates item classnames and counts, then adds them globally to an object using `addItemCargoGlobal`. |
| `fn_checkItemValidity.sqf` | `deScripts_fnc_checkItemValidity` | Verifies an item exists in `CfgMagazines`, `CfgWeapons`, or `CfgVehicles` and respects active ACE/ACEX modules (earplugs, rations, ropes) to prevent missing-mod crashes. |
| `fn_createCargoCrate.sqf` | `deScripts_fnc_createCargoCrate` | Spawns a crate, populates cargo, configures ACE cargo sizes, and can load the crate directly into a vehicle's ACE cargo hold. |
| `fn_doEmptyCrate.sqf` | `deScripts_fnc_doEmptyCrate` | Clears all weapons, ammo, and items from a crate; sets ACE cargo size to 1; makes it draggable/carryable; applies 7th Cavalry custom textures. |
| `fn_doFieldHospital.sqf` | `deScripts_fnc_doFieldHospital` | Designates an object as a Field Hospital facility (`ace_medical_isMedicalFacility = true`) and stocks it with Atlas medical supplies. |
| `fn_doStarterCrateSupplies.sqf` | `deScripts_fnc_doStarterCrateSupplies` | Server-side function that fills a starter crate based on company selection (`"NONE"`, `"FULL"`, `"ALL"`, `"MANUAL"`, `"TFG DEFAULT"`). |
| `fn_doSupplyCrate.sqf` | `deScripts_fnc_doSupplyCrate` | Spawns a resupply crate at a position based on crate type (Infantry Resupply, Atlas Medical, Infantry Medical, Stinger) and registers it with Zeus. |
| `fn_logistics_getAllContainerItems.sqf` | `deScripts_fnc_logistics_getAllContainerItems` | Returns an array of all item classnames registered across all containers in the logistics database (used for whitelisting and testing). |
| `fn_logistics_getContainer.sqf` | `deScripts_fnc_logistics_getContainer` | Retrieves the item array for a specific crate key from `deScripts_DATABASE`. |
| `fn_setCargo.sqf` | `deScripts_fnc_setCargo` | Completely wipes an object's current inventory and populates it with a specified items array via `fn_addCargo`. |
| `fn_setCargoAttributes.sqf` | `deScripts_fnc_setCargoAttributes` | Sets ACE cargo storage space (`ace_cargo_fnc_setSpace`), cargo size (`setSize`), and dragging/carrying properties on an object. |

---

## 8. Mission Helpers (`deScripts/functions/mission/`)

| File | Function | Purpose & How It Works |
|---|---|---|
| `fn_addEscapeWreck.sqf` | `deScripts_fnc_addEscapeWreck` | Adds a hold action ("Escape Wreck") to airframes allowing crew and passengers to safely egress destroyed or burning wrecks via `fn_doGetOutHeloSide`. |
| `fn_addGetOutHelo.sqf` | `deScripts_fnc_addGetOutHelo` | Adds quick dismount scroll-wheel actions to helicopters allowing cargo passengers to rapidly egress on the left or right door. |
| `fn_addHaloJump.sqf` | `deScripts_fnc_addHaloJump` | Attaches a high-altitude HALO jump hold action to transport aircraft. Validates altitude (e.g. >= 5000m) and open ramp before triggering `fn_para_haloJump`. |
| `fn_addLineJump.sqf` | `deScripts_fnc_addLineJump` | Attaches a static line jump hold action to transport aircraft. Checks altitude (180–350m) and airspeed (<= 310 km/h) before triggering `fn_para_lineJump`. |
| `fn_addLoadoutAction.sqf` | `deScripts_fnc_addLoadoutAction` | Adds an addAction on an object to equip a specific loadout: `[this, "Rifleman", "Cav_B_B_Weapons_Rifleman_F"] call deScripts_fnc_addLoadoutAction`. |
| `fn_doStarterCrate.sqf` | `deScripts_fnc_doStarterCrate` | Master staging crate initializer. Attaches Re-Gear, Heal, Insignia selection, ACE Loadout selection, Meal consumption, and debris cleanup. |
| `fn_makeAgent.sqf` | `deScripts_fnc_makeAgent` | Replaces an editor AI unit with a lightweight Arma agent (`createAgent`) to reduce AI processing overhead for base ambient guards/civilians. |
| `fn_setVehicleLable.sqf` | `deScripts_fnc_setVehicleLable` | Attaches tactical callsigns, numerals, and troop decals to air and ground vehicles (UH-60, C-130J, Stryker, Bradley, Abrams) using `UserTexture1m_F`. |

---

## 9. Systems Engine (`deScripts/functions/systems/`)

The Systems engine powers interactive menus, staging mechanics, airborne physics, training range automation, and server diagnostics.

| File | Function | Purpose & How It Works |
|---|---|---|
| `fn_addArsenal.sqf` | `deScripts_fnc_addArsenal` | Spawns an on-demand, filtered ACE Staging Arsenal tailored to the player's assigned role and company. |
| `fn_addDefaultArsenalLoadout.sqf` | `deScripts_fnc_addDefaultArsenalLoadout` | Injects the player's active role loadout into the ACE Arsenal default loadout templates. |
| `fn_addDefaultArsenalLoadouts.sqf` | `deScripts_fnc_addDefaultArsenalLoadouts` | Scans `CfgLoadouts` and loads every valid loadout class into ACE Arsenal's default loadout list. |
| `fn_addEatMeal.sqf` | `deScripts_fnc_addEatMeal` | Adds an ACE interaction to consume a full field meal, resetting ACEX hunger and thirst to zero after a 10-second progress bar. |
| `fn_addHeal.sqf` | `deScripts_fnc_addHeal` | Adds an action to fully heal the player via ACE medical. Automatically disabled if `OneLife` mode is active. |
| `fn_addInsigniaSelection.sqf` | `deScripts_fnc_addInsigniaSelection` | Helper function that creates individual insignia selection actions on an object. |
| `fn_addInsigniaSelectionList.sqf` | `deScripts_fnc_addInsigniaSelectionList` | Builds the hierarchical ACE interaction tree for 7th Cavalry uniform patches (Regimental, Alpha, Bravo, Charlie, Specialized). |
| `fn_addLoadoutLocker.sqf` | `deScripts_fnc_addLoadoutLocker` | Manages Personal Loadout Lockers. Supports claiming/abandoning lockers, owner-only gear management, saving/loading custom kits, and admin overrides. |
| `fn_addLoadoutSelection.sqf` | `deScripts_fnc_addLoadoutSelection` | Adds an individual ACE interaction action for a specific loadout class to a crate or locker. |
| `fn_addObjectToCurator.sqf` | `deScripts_fnc_addObjectToCurator` | Adds a dynamically spawned object or crate to all active Zeus curator interfaces on the next frame. |
| `fn_addReGear.sqf` | `deScripts_fnc_addReGear` | Adds an action to reset the player's ammo, explosives, and role gear back to their starting loadout. |
| `fn_addRolePermissions.sqf` | `deScripts_fnc_addRolePermissions` | ACE interaction menu allowing players to toggle specialist qualifications: Combat Lifesaver, Doctor/Medic, EOD Specialist, or Advanced Engineer. |
| `fn_allowLoadout.sqf` | `deScripts_fnc_allowLoadout` | Permission gatekeeper. Checks whether a player's assigned company permits them to equip a specific loadout (bypassed by Zeus and Admins). |
| `fn_clearDefaultArsenalLoadouts.sqf` | `deScripts_fnc_clearDefaultArsenalLoadouts` | Empties the `ace_arsenal_defaultLoadoutsList` array before building custom whitelists. |
| `fn_createActionCategory.sqf` | `deScripts_fnc_createActionCategory` | Helper function to build nested ACE interaction categories on objects. |
| `fn_createVehicleLable.sqf` | `deScripts_fnc_createVehicleLable` | Creates a `UserTexture1m_F` decal object and attaches it to a vehicle at a specified offset and vector rotation. |
| `fn_deleteDroppedObjects.sqf` | `deScripts_fnc_deleteDroppedObjects` | Garbage collection monitor that deletes weapon and backpack ground holders dropped around staging crates once players move away. |
| `fn_doGetOutHeloSide.sqf` | `deScripts_fnc_doGetOutHeloSide` | Safely ejects a passenger 2.5m out the left or right door of a helicopter while triggering door animations. |
| `fn_filterUnitLoadout.sqf` | `deScripts_fnc_filterUnitLoadout` | Strips runtime instance radio IDs (ACRE2/TFAR) from a loadout array, replacing them with base classnames to prevent radio duplication bugs. |
| `fn_getArsenalWhitelist.sqf` | `deScripts_fnc_getArsenalWhitelist` | Compiles an item whitelist for ACE Arsenal based on player role: includes base loadout items, common equipment, company kit, and matching weapon family accessories. |
| `fn_getAttendance.sqf` | `deScripts_fnc_getAttendance` | Compiles connected player attendance logs (name, role loadout, UTC join time, reconnection counts) and outputs formatted summaries to RPT and chat. |
| `fn_getIcon.sqf` | `deScripts_fnc_getIcon` | Resolves icon strings into absolute texture paths across Arma configs and local mission directories. |
| `fn_getServerMetrics.sqf` | `deScripts_fnc_getServerMetrics` | Diagnostic tool that displays current server FPS, minimum FPS, entity counts, tick uptime, and running SQF script counts to admins. |
| `fn_getVehicleLable.sqf` | `deScripts_fnc_getVehicleLable` | Translates shorthand callsigns and numbers (`"A"`, `"B"`, `"1"`-`"0"`, `"LINE"`, `"STRYKER"`) into texture PAA paths. |
| `fn_para_backpack.sqf` | `deScripts_fnc_para_backpack` | Front-mounts a player's backpack during airborne operations: saves backpack and contents, equips parachute, and adds a ground-only action to restore gear. |
| `fn_para_equipment.sqf` | `deScripts_fnc_para_equipment` | Simulates aerodynamic equipment loss during parachute jumps (drops unstrapped soft caps, NVGs, or sport glasses based on jump simulation difficulty). |
| `fn_para_haloJump.sqf` | `deScripts_fnc_para_haloJump` | Executes high-altitude freefall jump sequence: safely ejects player from aircraft ramp, runs equipment check, and front-mounts backpack. |
| `fn_para_lineJump.sqf` | `deScripts_fnc_para_lineJump` | Executes static line jump sequence: ejects player into airflow, spawns parachute vehicle, moves player directly into canopy, and runs equipment check. |
| `fn_renameObject.sqf` | `deScripts_fnc_renameObject` | Sets `ace_cargo_customName` globally on an object for clear display inside ACE Cargo menus. |
| `fn_setupLoadoutCategories.sqf` | `deScripts_fnc_setupLoadoutCategories` | Builds the hierarchical ACE interaction menu structure for organization loadouts (Alpha Co., Bravo Co., Charlie Co., Training, OPFOR). |
| `fn_setupLoadoutSelection.sqf` | `deScripts_fnc_setupLoadoutSelection` | Scans `CfgLoadouts` and dynamically generates selectable ACE loadout actions on a crate or locker. |
| `fn_training_addHitIndicator.sqf` | `deScripts_fnc_training_addHitIndicator` | Adds a `HitPart` event handler to target silhouettes, spawning small 3D spheres at bullet impact points or mirroring them onto a shooter feedback board. |
| `fn_training_addTargetComputer.sqf` | `deScripts_fnc_training_addTargetComputer` | Disables Arma target auto-reset and links targets to a range control console that can raise and reset all targets on command. |
| `fn_training_clearhitIndicator.sqf` | `deScripts_fnc_training_clearhitIndicator` | Deletes all 3D bullet impact marker spheres from target silhouettes and feedback boards. |

---

## 10. ZEN Zeus Modules (`deScripts/functions/modules/` & `fn_init_zenModuels.sqf`)

Modules registered into the ZEN (Zeus Enhanced) interface for Game Masters during operations.

| Category | Module Display Name | Purpose & How It Works |
|---|---|---|
| `TFG AI` | Enable Unit Simulation | Wakes up frozen or cached AI groups by enabling simulation and un-hiding objects globally. |
| `TFG Logistics` | Spawn Starter Crate | Spawns a full 7th Cavalry staging crate in the field with configurable company filters, heal actions, and arsenal toggles. |
| `TFG Logistics` | Spawn Re-supply Crate | Spawns resupply crates (Infantry Resupply, Atlas Medical, Infantry Medical, Stinger MANPAD). |
| `TFG Utilities` | Apply Loadout | ZEN dialog allowing Zeus to select any loadout from `CfgLoadouts` and force-apply it to a clicked player or AI unit. |
| `TFG Utilities` | Regear Trooper | Re-applies the assigned starting loadout to a clicked unit to quickly re-arm them in the field. |
| `TFG Mission` | Call Endex | Declares ENDEX (End of Exercise). Locks player weapon safeties, pacifies AI groups (Careless/Blue), heals all players, and triggers attendance logging. |
| `TFG Mission` | Take Attendance | Dumps attendance logs of all connected players to the Zeus operator's RPT log. |
| `TFG EWAR` | Create Jammer Area | Prompts Zeus for outer radius (50m–1500m), inner hard-cut core ratio (0–0.9), and faction exemptions; places a static jamming bubble at the clicked position. |
| `TFG EWAR` | Attach Jammer to Object | Attaches a mobile or destructible jammer bubble to a clicked vehicle or object (automatically ceases jamming if the object is destroyed). |
| `TFG EWAR` | Remove Nearby Jammers | Removes a jammer directly from a clicked object or clears all active jammers within 100m of the cursor. |

---

## 11. Electronic Warfare Subsystem (`deScripts/functions/ewar/`)

The EWAR subsystem models omnidirectional counter-UAS (C-UAS) electronic jamming fields. The monitoring routine runs strictly **client-side** on players currently controlling an unmanned asset (`getConnectedUAV player != objNull`), ensuring near-zero server and non-operator overhead.

### Functions Reference

| File | Function | Purpose & How It Works |
|---|---|---|
| `fn_ewar_preInit.sqf` | `deScripts_fnc_ewar_preInit` | Runs during engine preInit (`preInit = 1`). Initializes `GVAR(ewar_jammers)` with JIP synchronization and binds synchronized CBA event handlers for adding/removing jammers. |
| `fn_ewar_postInit.sqf` | `deScripts_fnc_ewar_postInit` | Runs during engine postInit (`postInit = 1`). Starts the 0.5-second client-side `CBA_fnc_addPerFrameHandler` loop on player machines (`hasInterface`). |
| `fn_ewar_addJammer.sqf` | `deScripts_fnc_ewar_addJammer` | Public API (`[source, radius, coreRatio, sideExempt]`) to register a new jammer on an object, marker, or coordinate. Broadcasts globally via CBA events. |
| `fn_ewar_removeJammer.sqf` | `deScripts_fnc_ewar_removeJammer` | Public API to unregister an active jammer by its ID string or attached object reference. |
| `fn_ewar_clientLoop.sqf` | `deScripts_fnc_ewar_clientLoop` | Periodic client evaluation routine. Calculates normalized distance intensity (`0.0` to `1.0`) against all active jammers for the player's connected UAV. |
| `fn_ewar_applyInterference.sqf` | `deScripts_fnc_ewar_applyInterference` | Applies progressive `FilmGrain` static and subtle `ChromAberration` with `ppEffectForceInNVG true`, renders a dynamic 5-bar ascending signal strength HUD meter, and plays audible static clicks. |
| `fn_ewar_clearFX.sqf` | `deScripts_fnc_ewar_clearFX` | Destroys post-processing effect handles, deletes HUD signal bar controls, and resets internal state flags when exiting camera or leaving jamming bubbles. |
| `fn_ewar_handleFailsafe.sqf` | `deScripts_fnc_ewar_handleFailsafe` | Severs player terminal connection (`player connectTerminalToUav objNull`), resets camera, and triggers `deScripts_ewar_executeDroneFailsafe` target event where the drone is local. |
| `fn_ewar_executeFailsafe.sqf` | `deScripts_fnc_ewar_executeFailsafe` | Executes physical fail-safe behavior where the vehicle is local, based on CBA setting `deScripts_Settings_ewar_failsafeBehavior`. |

### Platform Fail-Safe Behaviors (Realistic Mode)

| Unmanned Vehicle Class | Examples (Vanilla / `@GX - Drones` / `@Arma 3 Aegis`) | Physical Fail-Safe Behavior |
|---|---|---|
| **Rotary & Micro-UAVs** | AR-2 Darter, FLIR Black Hornet, Hunter, MQ-8B Fire Scout, AL-6 Pelican | Terminal disconnects; waypoints cleared; initiates controlled vertical auto-land descent (`_uav land "LAND"`). |
| **Fixed-Wing Recon UAVs** | RQ-11B Raven, MQ-4A Greyhawk, UCAV Sentinel, K40 Ababil, Shikra | Terminal disconnects; attack waypoints cleared; enters autonomous 250m circular holding orbit (`LOITER`). |
| **Loitering Munitions / FPVs** | Drone 40, explosive-rigged FPV quadcopters, `isKamikaze` tagged drones | Terminal disconnects; engine instantly killed (`HitEngine = 1`); falls ballistically. |
| **Ground UGVs** | THeMIS, Honeybadger, UGV Stomper, ED-1D/E Demining UGVs | Terminal disconnects; waypoints cleared; brakes engaged (`setVelocity [0,0,0]`); engine stopped. |
| **Naval USVs** | Magura V5 USV | Terminal disconnects; waypoints cleared; propulsion stopped; drifts on water current. |

---

## 12. Documents & Briefing Checklists (`deScripts/functions/documents/`)

Post-initialization functions that build tactical references in the player's in-game briefing screen under `"Chklists"` and `"radioReports"`.

| File | Function | Topic / Title | Content Summary |
|---|---|---|---|
| `fn_DocChklist_CFF.sqf` | `deScripts_fnc_DocChklist_CFF` | `Chklists` > CALL FOR FIRE | Displays Call-For-Fire transmission card graphic (`CFF.jpg`). |
| `fn_DocChklist_JMTASKS.sqf` | `deScripts_fnc_DocChklist_JMTASKS` | `Chklists` > JUMPMASTER CHECKLISTS | Airborne jumpmaster procedures, stick briefing guide, and drop checklists (`AB_Admin_Checklist.paa`, `AB_Drop_Checklist.paa`). |
| `fn_DocChklist_LZEXTRACT.sqf` | `deScripts_fnc_DocChklist_LZEXTRACT` | `Chklists` > HELO EXTRACTION | Helicopter extraction SOPs and checklists (`extract-admin-checklist.paa`, `extract-extract-checklist.paa`). |
| `fn_DocChklist_LZINSERT.sqf` | `deScripts_fnc_DocChklist_LZINSERT` | `Chklists` > HELO INSERTION | Helicopter insertion SOPs and checklists (`insertion-admin-checklist.paa`, `insertion-insert-checklist.paa`). |
| `fn_DocChklist_LZSPECS.sqf` | `deScripts_fnc_DocChklist_LZSPECS` | `Chklists` > LZ/PZ SPECIFICATIONS | Landing point diameter sizes by airframe (`LPSIZES.paa`), terrain types (`LZTYPES.paa`), and map markings (`LZ-MAP-MARKINGS.paa`). |
| `fn_DocRadio_LACEACE.sqf` | `deScripts_fnc_DocRadio_LACEACE` | `radioReports` > LACE/ACE REPORT | Scripted format for reporting Liquids, Ammunition, Casualties, and Equipment. |
| `fn_DocRadio_MEDEVAC.sqf` | `deScripts_fnc_DocRadio_MEDEVAC` | `radioReports` > MEDEVAC REQUEST | Standard 6-line aeromedical evacuation request script with line-by-line guidelines. |
| `fn_DocRadio_ROTARYPICKUP.sqf` | `deScripts_fnc_DocRadio_ROTARYPICKUP` | `radioReports` > ROTARY PICKUP | Tactical extraction request script for helicopter passenger transport. |
| `fn_DocRadio_SPOTREP.sqf` | `deScripts_fnc_DocRadio_SPOTREP` | `radioReports` > SPOTREP | SALUTE-derived Spot Report format (Size, Activity, Location, Uniform, Time, Equipment, Actions). |

---

## 13. Diagnostics & Automated Testing (`diag/` & `testing/`)

| File | Function | Purpose & How It Works |
|---|---|---|
| `deScripts/functions/diag/fn_log.sqf` | `deScripts_fnc_log` | Core logging engine. Formats log lines (`[deScripts] (component) TYPE: message`), writes to local RPT, can forward logs to dedicated server RPT via CBA event `deScripts_log_text`, and optionally echoes to chat. |
| `deScripts/functions/diag/fn_error.sqf` | `deScripts_fnc_error` | Diagnostic wrapper for errors. Defaults: shows in chat, type `"ERROR"`. |
| `deScripts/functions/diag/fn_info.sqf` | `deScripts_fnc_info` | Diagnostic wrapper for info logs. Defaults: RPT only, type `"INFO"`. |
| `deScripts/functions/diag/fn_warning.sqf` | `deScripts_fnc_warning` | Diagnostic wrapper for warnings. Defaults: RPT only, type `"WARNING"`. |
| `deScripts/functions/testing/fn_testing_equipmentUsed.sqf` | `deScripts_fnc_testing_equipmentUsed` | Automated QA test. Iterates over all item classnames in `deScripts_DATABASE` and asserts that every item exists in `CfgMagazines`, `CfgWeapons`, or `CfgVehicles`. |
| `deScripts/functions/testing/fn_testing_loadoutArrays.sqf` | `deScripts_fnc_testing_loadoutArrays` | Automated QA test. Parses all `CfgLoadouts` classes and validates that their `loadout` strings conform to standard Arma 3 10-element `getUnitLoadout` array syntax. |

---

## 14. Data Assets Summary (`Data/` & `deScripts/Data/`)

- `Data/MissionLogo.paa` & `Data/MissionLogo.psd`: Loading screen and overview graphic displayed during mission load.
- `deScripts/Data/Icon/`: Custom UI icons for ACE interactions and loadout locker menus (`icon_arsenal_ca.paa`, `icon_00.paa`, `icon_x.paa`, etc.).
- `deScripts/Data/Images/`: Graphical checklists and references embedded into player map diaries (CFF card, airborne drop checklists, rotary LZ/PZ specification charts).

---

## 15. Common Maintenance Tasks ("Where do I change X?")

| Desired Change | Primary Files to Modify | Notes |
|---|---|---|
| **Add or edit crate supplies / vehicle cargo** | `deScripts/deScripts_logistics.sqf` | Add or update container arrays in `GVAR(DATABASE)`. Run `call deScripts_fnc_testing_equipmentUsed` to verify classnames. |
| **Add or edit player role loadouts** | `deScripts/Loadouts/` (e.g., `CfgLoadouts_Bravo_Viking_Weapons.hpp`) | Inherit from company base class, set `scope = 2`, `displayName`, `role`, and `loadout` array. Run `call deScripts_fnc_testing_loadoutArrays`. |
| **Change forced ACE / mission settings** | `cba_settings.sqf` | Look for `force force <settingName> = <value>;`. |
| **Add or adjust framework CBA settings** | `deScripts/initSettings.inc.sqf` | Uses `CBA_fnc_addSetting`. |
| **Add a new Zeus curator module** | `deScripts/functions/init/fn_init_zenModuels.sqf` & `deScripts/functions/modules/` | Register the module with `zen_custom_modules_fnc_register` and create the module handler. |
| **Adjust EWAR drone jamming, static, or fail-safes** | `deScripts/functions/ewar/` & `deScripts/initSettings.inc.sqf` | Edit `fn_ewar_applyInterference.sqf` for visuals/HUD and `fn_ewar_executeFailsafe.sqf` for platform reactions. |
| **Add a briefing checklist or SOP card** | `deScripts/functions/documents/` & `fn_init_diary.sqf` | Create a new `fn_DocChklist_*.sqf` and call it inside `fn_init_diary.sqf`. |
| **Ban or permit an equipment classname** | `deScripts/deScripts_blacklist.sqf` | Add or remove classnames from the returned blacklist array. |
| **Add a tactical vehicle decal / number** | `deScripts/functions/systems/fn_getVehicleLable.sqf` & `fn_setVehicleLable.sqf` | Add decal mapping in `fn_getVehicleLable.sqf` and model offset coordinates in `fn_setVehicleLable.sqf`. |
