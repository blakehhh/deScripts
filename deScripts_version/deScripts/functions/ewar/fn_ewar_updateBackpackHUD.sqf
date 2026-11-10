#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Renders and updates:
 * 1. The Slim Vertical EWAR C-UAS Manpack RCU Mini-HUD widget in the lower-right corner.
 * 2. The native physical LCD screen on the Spectrum Device (hgun_esd_01_F) via #EM_* missionNamespace variables.
 *
 * Arguments:
 * 0: Force transient popup duration in seconds (optional, default 0) <NUMBER>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [5] call deScripts_fnc_ewar_updateBackpackHUD
 *
 * Public: No
 */

params [["_popupSeconds", 0, [0]]];

if !(hasInterface) exitWith {};

if (_popupSeconds > 0) then {
    GVAR(ewar_hudPopupUntil) = diag_tickTime + _popupSeconds;
};

private _hasBackpack = alive player && {(toLower (backpack player)) find "b_radiobag_01" != -1};
private _isActive = player getVariable [QGVAR(ewar_isJammerActive), false];
private _battery = player getVariable [QGVAR(ewar_backpackBattery), 100];
private _showPersistent = profileNamespace getVariable [QGVAR(ewar_showHUD), true];
private _inPopupWindow = diag_tickTime < (missionNamespace getVariable [QGVAR(ewar_hudPopupUntil), 0]);
private _isLowBatteryAlert = _isActive && {EGVAR(Settings,ewar_backpackRequiresBattery)} && {_battery <= 10};

private _holdingESD = alive player && {((toLower (currentWeapon player)) find "hgun_esd_01" != -1)};
private _isDirectional = _hasBackpack && {_holdingESD};

private _radius = round (EGVAR(Settings,ewar_backpackRadius));
private _coreRatio = missionNamespace getVariable [QEGVAR(Settings,ewar_backpackCoreRatio), 0.375];
private _beamMode = player getVariable [QGVAR(ewar_beamMode), 0];
private _baseMult = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalMultiplier), 3.0];
private _baseCone = missionNamespace getVariable [QEGVAR(Settings,ewar_directionalConeAngle), 45];

private _dirMult = switch (_beamMode) do {
    case 1: { _baseMult * (5.0 / 3.0) };
    case 2: { _baseMult * (7.5 / 3.0) };
    default { _baseMult };
};
private _coneAngle = switch (_beamMode) do {
    case 1: { _baseCone * (20 / 45) };
    case 2: { _baseCone * (10 / 45) };
    default { _baseCone };
};
private _effRadius = round (_radius * _dirMult);
private _effCoreDist = round (_effRadius * (_coreRatio max 0 min 0.95));

// Momentary Left-Click Trigger Pulse when Backpack is in STBY
private _triggerHeld = _isDirectional && {isNull (findDisplay 49)} && {!visibleMap} && {isNull (findDisplay 312)} && {((inputAction "DefaultAction") > 0) || {((inputAction "Fire") > 0)}};
private _canPulse = (!_isActive) && {_triggerHeld} && {!(EGVAR(Settings,ewar_backpackRequiresBattery)) || {_battery > 0}};
private _wasPulsing = player getVariable [QGVAR(ewar_isPulsing), false];
if (_canPulse isNotEqualTo _wasPulsing) then {
    player setVariable [QGVAR(ewar_isPulsing), _canPulse, true];
    if (_canPulse) then {
        [player] call FUNC(ewar_removeJammer);
        private _exemptFriendly = missionNamespace getVariable [QEGVAR(Settings,ewar_backpackExemptFriendly), true];
        private _sideExempt = if (_exemptFriendly) then { side (group player) } else { sideUnknown };
        private _jammerID = [player, _radius, _coreRatio, _sideExempt] call FUNC(ewar_addJammer);
        player setVariable [QGVAR(ewar_jammerID), _jammerID, true];
        playSoundUI ["ACE_Sound_Click", 0.6, 1.4];
    } else {
        if (!_isActive) then {
            [player] call FUNC(ewar_removeJammer);
        };
    };
};
private _isTransmitting = _isActive || {_canPulse};

private _targetInCone = false;
private _targetInKill = false;
private _lockedIsObstructed = false;
private _passiveSignalDetected = false;
private _lockedDist = 99999;
private _scanRadius = _effRadius;
private _burnProgress = missionNamespace getVariable [QGVAR(ewar_burnProgress), 0];
if (isNil "_burnProgress" || {!(finite _burnProgress)} || {_burnProgress < 0}) then {
    _burnProgress = 0;
    GVAR(ewar_burnProgress) = 0;
};

// ============================================================================
// 1. DRIVE PHYSICAL SPECTRUM DEVICE LCD SCREEN (#EM_* Engine Variables)
// ============================================================================
if (_holdingESD) then {
    // Ensure 3D muzzle antenna matches current beam focus mode on initial draw
    if !(player getVariable [QGVAR(ewar_isSwappingAntenna), false]) then {
        private _expectedAntenna = switch (_beamMode) do {
            case 1: { "muzzle_antenna_02_f" };
            case 2: { "muzzle_antenna_03_f" };
            default { "muzzle_antenna_01_f" };
        };
        private _curHandgunItems = (handgunItems player) apply { toLower _x };
        if !(_expectedAntenna in _curHandgunItems) then {
            {
                if (((toLower _x) find "muzzle_antenna_") != -1) then {
                    player removeHandgunItem _x;
                };
            } forEach (handgunItems player);
            player addHandgunItem _expectedAntenna;
        };
    };

    // Configure X-axis (2400 - 2500 MHz UAV Band, 2450 = Center Boresight) and Y-axis (0 - 100 dB)
    missionNamespace setVariable ["#EM_FMin", 2400];
    missionNamespace setVariable ["#EM_FMax", 2500];
    missionNamespace setVariable ["#EM_SMin", 0];
    missionNamespace setVariable ["#EM_SMax", 100];

    // Map active beam focus angle (45 deg / 20 deg / 10 deg) to the center selection gate on the LCD screen
    private _halfGateSpan = (_coneAngle / 90) * 50;
    missionNamespace setVariable ["#EM_SelMin", 2450 - _halfGateSpan];
    missionNamespace setVariable ["#EM_SelMax", 2450 + _halfGateSpan];

    private _emPairs = [];
    private _rawDir = player weaponDirection (currentWeapon player);
    if (_rawDir isEqualTo [] || {_rawDir isEqualTo [0, 0, 0]}) then {
        _rawDir = eyeDirection player;
    };
    if (_rawDir isEqualTo [] || {_rawDir isEqualTo [0, 0, 0]}) then {
        _rawDir = [0, 1, 0];
    };
    private _aimDir = vectorNormalized _rawDir;
    private _aimHeading = if ((_aimDir select 0) == 0 && {(_aimDir select 1) == 0}) then {
        0
    } else {
        (_aimDir select 0) atan2 (_aimDir select 1)
    };
    private _playerEye = eyePos player;
    private _halfAngle = _coneAngle * 0.5;
    private _playerSide = side (group player);

    private _dt = (diag_tickTime - (missionNamespace getVariable [QGVAR(ewar_lastBurnTick), diag_tickTime])) max 0.01 min 0.5;
    GVAR(ewar_lastBurnTick) = diag_tickTime;

    private _exemptFriendly = missionNamespace getVariable [QEGVAR(Settings,ewar_backpackExemptFriendly), true];
    // Antenna scan aperture and detection range scale with physical antenna attachment
    _scanRadius = _effRadius;
    private _scanAperture = switch (_beamMode) do {
        case 1: { 30 };
        case 2: { 15 };
        default { 45 };
    };
    private _nearbyUavs = _playerEye nearEntities [["Air", "Car", "Tank"], _scanRadius];
    private _lockedUav = objNull;

    // A. Scan Aerial & Ground Drones (Distinct RF Waveforms)
    {
        if (unitIsUAV _x && {alive _x}) then {
            private _uavSide = if (count (crew _x) > 0) then { side (group ((crew _x) select 0)) } else { side _x };
            private _origSide = _x getVariable [QGVAR(ewar_originalSide), _uavSide];
            private _isValidTarget = (!_exemptFriendly || {_origSide != _playerSide}) && {_origSide != sideUnknown};
            if (_isValidTarget) then {
                private _uavAimPos = aimPos _x;
                if (_uavAimPos isEqualTo [0, 0, 0]) then {
                    _uavAimPos = (getPosASL _x) vectorAdd [0, 0, 1.0];
                };
                private _vec = _uavAimPos vectorDiff _playerEye;
                private _dist = vectorMagnitude _vec;
                if (_dist <= _scanRadius && {_dist > 0.1}) then {
                    private _uavDir = vectorNormalized _vec;
                    private _dot = ((_aimDir vectorDotProduct _uavDir) max -1) min 1;
                    if (!finite _dot) then { _dot = 0; };
                    private _angle3D = acos _dot;

                    private _uavHeading = if ((_vec select 0) == 0 && {(_vec select 1) == 0}) then {
                        0
                    } else {
                        (_vec select 0) atan2 (_vec select 1)
                    };
                    private _relAz = _uavHeading - _aimHeading;
                    if (_relAz > 180) then { _relAz = _relAz - 360; };
                    if (_relAz < -180) then { _relAz = _relAz + 360; };

                    // Plot any UAV within antenna aperture horizontal bearing onto the LCD graph
                    if (abs _relAz <= _scanAperture) then {
                        private _terrainBlocked = terrainIntersectASL [_playerEye, _uavAimPos];
                        private _objBlocked = if (_terrainBlocked) then {
                            true
                        } else {
                            lineIntersects [_playerEye, _uavAimPos, player, _x]
                        };
                        private _losFactor = if (_terrainBlocked) then {
                            0.25
                        } else {
                            if (_objBlocked) then { 0.60 } else { 1.0 }
                        };

                        _passiveSignalDetected = true;
                        private _freq = (2450 + ((_relAz / _scanAperture) * 50)) max 2405 min 2495;
                        private _distFactor = 1 - ((_dist / (_scanRadius max 1)) min 0.92);
                        private _elevDiff = abs (_angle3D - (abs _relAz));
                        private _pitchFactor = 1 - ((_elevDiff / _scanAperture) min 0.80);
                        private _strength = (12 + (_distFactor * 82)) * _pitchFactor * _losFactor;

                        // Active directional burn-through requires that terrain (hills/bedrock) does not block the path
                        // Objects (trees, foliage, walls) allow burn-through at an increased dwell time
                        if (!_terrainBlocked && {_isDirectional} && {_isTransmitting} && {_dist <= _effRadius} && {_angle3D <= _halfAngle}) then {
                            _targetInCone = true;
                            if (_dist < _lockedDist) then {
                                _lockedDist = _dist;
                                _lockedUav = _x;
                                _lockedIsObstructed = _objBlocked;
                            };
                        };

                        if ((_x isKindOf "Car") || {_x isKindOf "Tank"}) then {
                            // 1. Ground UGV: Connected 3-Step Ascending Staircase / Sawtooth (0.5 MHz contiguous bins)
                            private _hop = (sin (diag_tickTime * 18)) * 4;
                            private _ugvProfile = [
                                [-3.5, 0.38], [-3.0, 0.42], [-2.5, 0.44],
                                [-2.0, 0.66], [-1.5, 0.70], [-1.0, 0.72], [-0.5, 0.74],
                                [0.0, 0.92],  [0.5, 0.96],  [1.0, 0.98],  [1.5, 1.00],
                                [2.0, 0.65],  [2.5, 0.40]
                            ];
                            {
                                _x params ["_off", "_mult"];
                                private _ptAmp = (_strength * _mult) + (if (_off >= 0 && {_off <= 1.5}) then { _hop } else { 0 });
                                _emPairs pushBack [(_freq + _off) max 2401 min 2499, _ptAmp max 6 min 99];
                            } forEach _ugvProfile;
                        } else {
                            if (_x isKindOf "Plane") then {
                                // 2. Fixed-Wing Recon UAV: Solid Flat-Top Mesa / Plateau (0.5 MHz contiguous bins)
                                private _planeProfile = [
                                    [-3.0, 0.55], [-2.5, 0.88],
                                    [-2.0, 0.94], [-1.5, 0.95], [-1.0, 0.96], [-0.5, 0.96],
                                    [0.0, 0.96],  [0.5, 0.96],  [1.0, 0.96],  [1.5, 0.95], [2.0, 0.94],
                                    [2.5, 0.88],  [3.0, 0.55]
                                ];
                                {
                                    _x params ["_off", "_mult"];
                                    _emPairs pushBack [(_freq + _off) max 2401 min 2499, (_strength * _mult) max 6 min 99];
                                } forEach _planeProfile;
                            } else {
                                // 3. Rotary Quadcopter / FPV: Connected Twin-Peak 'M' Wave (Control + Analog Video Carrier)
                                private _jitter = (random 8) - 4;
                                private _quadProfile = [
                                    [-2.0, 0.55, 0], [-1.5, 0.92, 0], [-1.0, 0.78, 0],
                                    [-0.5, 0.48, 0], [0.0, 0.38, 0],  [0.5, 0.48, 0],
                                    [1.0, 0.80, 1],  [1.5, 0.98, 1],  [2.0, 0.55, 1]
                                ];
                                {
                                    _x params ["_off", "_mult", "_useJitter"];
                                    private _ptAmp = (_strength * _mult) + (if (_useJitter == 1) then { _jitter } else { 0 });
                                    _emPairs pushBack [(_freq + _off) max 2401 min 2499, _ptAmp max 6 min 99];
                                } forEach _quadProfile;
                            };
                        };
                    };
                };
            };
        };
    } forEach _nearbyUavs;

    // B. Scan & Triangulate Hostile Ground Jammers (Solid 14 MHz Wide Boiling Noise Wall)
    if (!isNil QGVAR(ewar_jammers) && {GVAR(ewar_jammers) isNotEqualTo []}) then {
        {
            _x params ["_jId", "_jSource", "_jRadius", "_jCore", "_jExempt"];
            private _isSelf = (_jSource isEqualType objNull) && {_jSource isEqualTo player};
            if (!_isSelf) then {
                private _isFriendlyJammer = if (_jExempt isEqualType []) then {
                    _playerSide in _jExempt
                } else {
                    (_jExempt isEqualTo _playerSide) || {(_jSource isEqualType objNull) && {(side (group _jSource)) isEqualTo _playerSide} && {_exemptFriendly}}
                };

                if (!_isFriendlyJammer) then {
                    private _jPosASL = if (_jSource isEqualType objNull) then {
                        if (isNull _jSource || {!alive _jSource}) then {
                            [0, 0, 0]
                        } else {
                            private _ap = aimPos _jSource;
                            if (_ap isEqualTo [0, 0, 0]) then { (getPosASL _jSource) vectorAdd [0, 0, 1.5] } else { _ap }
                        }
                    } else {
                        (ATLToASL _jSource) vectorAdd [0, 0, 1.5]
                    };

                    if (_jPosASL isNotEqualTo [0, 0, 0]) then {
                        private _jVec = _jPosASL vectorDiff _playerEye;
                        private _jDist = vectorMagnitude _jVec;
                        if (_jDist <= _scanRadius && {_jDist > 0.1}) then {
                            private _jDir = vectorNormalized _jVec;
                            private _jDot = ((_aimDir vectorDotProduct _jDir) max -1) min 1;
                            if (!finite _jDot) then { _jDot = 0; };
                            private _jAngle3D = acos _jDot;

                            private _jHeading = if ((_jVec select 0) == 0 && {(_jVec select 1) == 0}) then {
                                0
                            } else {
                                (_jVec select 0) atan2 (_jVec select 1)
                            };
                            private _jRelAz = _jHeading - _aimHeading;
                            if (_jRelAz > 180) then { _jRelAz = _jRelAz - 360; };
                            if (_jRelAz < -180) then { _jRelAz = _jRelAz + 360; };

                            if (abs _jRelAz <= _scanAperture) then {
                                private _jTerrainBlocked = terrainIntersectASL [_playerEye, _jPosASL];
                                private _jIgnoreObj = if (_jSource isEqualType objNull) then { _jSource } else { objNull };
                                private _jObjBlocked = if (_jTerrainBlocked) then {
                                    true
                                } else {
                                    lineIntersects [_playerEye, _jPosASL, player, _jIgnoreObj]
                                };
                                private _jLosFactor = if (_jTerrainBlocked) then {
                                    0.25
                                } else {
                                    if (_jObjBlocked) then { 0.60 } else { 1.0 }
                                };

                                _passiveSignalDetected = true;
                                private _jFreq = (2450 + ((_jRelAz / _scanAperture) * 50)) max 2408 min 2492;
                                private _jDistFactor = 1 - ((_jDist / (_scanRadius max 1)) min 0.90);
                                private _jElevDiff = abs (_jAngle3D - (abs _jRelAz));
                                private _jPitchFactor = 1 - ((_jElevDiff / _scanAperture) min 0.75);
                                private _jStrength = (20 + (_jDistFactor * 78)) * _jPitchFactor * _jLosFactor;

                                // Populate every 0.5 MHz bin from -7.0 to +7.0 (29 contiguous bins) for a solid noise barrage
                                for "_step" from -14 to 14 do {
                                    private _off = _step * 0.5;
                                    private _edgeTaper = if (abs _step >= 12) then { 0.72 } else { 1.0 };
                                    private _noiseAmp = _jStrength * _edgeTaper * (0.62 + (random 0.38));
                                    _emPairs pushBack [(_jFreq + _off) max 2401 min 2499, _noiseAmp max 10 min 99];
                                };
                            };
                        };
                    };
                };
            };
        } forEach GVAR(ewar_jammers);
    };

    // Sort [freq, amp] pairs left-to-right across the 2.40 - 2.50 GHz spectrum
    _emPairs sort true;
    private _emValues = [];
    {
        _emValues pushBack (_x select 0);
        _emValues pushBack (_x select 1);
    } forEach _emPairs;

    // Active Electronic Warfare Burn-Through Dwell-Time Processing
    if (_targetInCone && {_isDirectional} && {_isTransmitting} && {!isNull _lockedUav}) then {
        private _prevTarget = missionNamespace getVariable [QGVAR(ewar_burnTarget), objNull];
        if (!isNull _prevTarget && {_prevTarget != _lockedUav}) then {
            _prevTarget setVariable [QGVAR(ewar_burnIntensity), 0, true];
            _burnProgress = _burnProgress * 0.5;
        };
        GVAR(ewar_burnTarget) = _lockedUav;

        // Scale lock dwell time: 5s close range up to 30s at max beam range
        private _distRatio = ((_lockedDist / (_effRadius max 1)) max 0) min 1;
        if (!finite _distRatio) then { _distRatio = 0; };
        private _timeToKill = (5.0 + (25.0 * _distRatio)) max 1;
        // Obstructed sightlines (trees, foliage, walls) increase dwell time by 2.2x (~11s close, ~66s max range)
        if (_lockedIsObstructed) then {
            _timeToKill = _timeToKill * 2.2;
        };
        private _chargeRate = 1.0 / _timeToKill;
        if (!finite _chargeRate) then { _chargeRate = 0.2; };

        _burnProgress = ((_burnProgress + (_chargeRate * _dt)) max 0) min 1.0;
        if (!finite _burnProgress) then { _burnProgress = 0; };
        GVAR(ewar_burnProgress) = _burnProgress;
        _lockedUav setVariable [QGVAR(ewar_burnIntensity), _burnProgress, true];

        if (_burnProgress >= 1.0) then {
            _targetInKill = true;
            if !(_lockedUav getVariable [QGVAR(ewar_isFailsafeActive), false]) then {
                [QGVAR(ewar_executeDroneFailsafe), [_lockedUav], _lockedUav] call CBA_fnc_targetEvent;
            };
        };
    } else {
        // Graceful lock decay when aim slips off target
        if (_burnProgress > 0) then {
            _burnProgress = ((_burnProgress - (0.15 * _dt)) max 0) min 1.0;
            if (!finite _burnProgress) then { _burnProgress = 0; };
            GVAR(ewar_burnProgress) = _burnProgress;
            private _prevTarget = missionNamespace getVariable [QGVAR(ewar_burnTarget), objNull];
            if (!isNull _prevTarget) then {
                _prevTarget setVariable [QGVAR(ewar_burnIntensity), _burnProgress, true];
                if (_burnProgress <= 0) then {
                    GVAR(ewar_burnTarget) = objNull;
                };
            };
        };
    };

    missionNamespace setVariable ["#EM_Values", _emValues];
    missionNamespace setVariable ["#EM_Transmit", _isDirectional && {_isTransmitting}];
    missionNamespace setVariable ["#EM_Progress", _burnProgress];

    // Clear Muzzle_1 ammo so the hip-fire 3D model screen clears "999.9 MHz"
    player setAmmo ["Muzzle_1", 0];

    // Hide the native "2.40 GHz", "2.4 GHz", and "2.50 GHz" labels at the bottom of the KAISERKOM LCD screen
    // Contact DLC stores the Spectrum Device weaponInfoType display via uiNamespace "bin_object"
    private _esdDisp = ctrlParent (uiNamespace getVariable ["bin_object", controlNull]);
    if (!isNull _esdDisp) then {
        private _ctrlSpec = _esdDisp displayCtrl 1999;
        if (!isNull _ctrlSpec) then {
            private _freqCtrls = +(_ctrlSpec getVariable ["bin_graphLegendH", []]);
            _freqCtrls pushBackUnique (_ctrlSpec getVariable ["bin_selectedText", controlNull]);
            {
                _freqCtrls pushBackUnique (_esdDisp displayCtrl _x);
            } forEach [4001, 5600, 5601, 5650];

            {
                if (!isNull _x) then {
                    _x ctrlSetText "";
                    _x ctrlSetTextColor [0, 0, 0, 0];
                    _x ctrlSetFade 1;
                    _x ctrlShow false;
                    _x ctrlCommit 0;
                };
            } forEach _freqCtrls;

            // Unbind references on _ctrlSpec so BIN_fnc_showPlayerSpectrumAnalyzer cannot re-populate them
            _ctrlSpec setVariable ["bin_graphLegendH", []];
            _ctrlSpec setVariable ["bin_selectedText", controlNull];
        };
    };

    if (_targetInCone && {diag_tickTime > (missionNamespace getVariable [QGVAR(ewar_lastLockSound), 0]) + (0.85 - (_burnProgress * 0.45))}) then {
        private _tonePitch = if (_targetInKill) then { 2.2 } else { 1.2 + (_burnProgress * 0.8) };
        playSoundUI ["\A3\Sounds_F\sfx\hint-2.wss", 0.5, _tonePitch];
        GVAR(ewar_lastLockSound) = diag_tickTime;
    };
};

// ============================================================================
// 2. SLIM SINGLE-COLUMN RCU MINI-HUD (Lower-Right Corner)
// ============================================================================
private _shouldShowRCU = EGVAR(Settings,ewar_enable) && {_hasBackpack} && {_showPersistent || {_inPopupWindow} || {_isLowBatteryAlert}};

if (!_shouldShowRCU) exitWith {
    if (!isNil QGVAR(ewar_backpackHUDCtrls)) then {
        {
            if (!isNull _x) then {
                ctrlDelete _x;
            };
        } forEach GVAR(ewar_backpackHUDCtrls);
        GVAR(ewar_backpackHUDCtrls) = nil;
    };
};

private _display = findDisplay 46;
if (isNull _display) exitWith {};

// 15 controls total (0..14)
if (isNil QGVAR(ewar_backpackHUDCtrls) || {count GVAR(ewar_backpackHUDCtrls) != 15} || {isNull (GVAR(ewar_backpackHUDCtrls) select 0)}) then {
    if (!isNil QGVAR(ewar_backpackHUDCtrls)) then {
        {
            if (!isNull _x) then {
                ctrlDelete _x;
            };
        } forEach GVAR(ewar_backpackHUDCtrls);
    };
    GVAR(ewar_backpackHUDCtrls) = [];

    private _panelW = safeZoneW * 0.062;
    private _panelH = safeZoneH * 0.136;
    private _panelX = safeZoneX + safeZoneW - _panelW - (safeZoneW * 0.012);
    private _panelY = safeZoneY + safeZoneH - _panelH - (safeZoneH * 0.085);

    private _hdrH = _panelH * 0.19;
    private _ftrH = _panelH * 0.18;
    private _bodyY = _panelY + _hdrH;
    private _bodyH = _panelH - _hdrH - _ftrH;

    // 0: Main panel background
    private _bg = _display ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
    _bg ctrlSetBackgroundColor [0.07, 0.08, 0.09, 0.85];
    _bg ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _bg;

    // 1: Header background bar
    private _hdrBg = _display ctrlCreate ["RscText", -1];
    _hdrBg ctrlSetPosition [_panelX, _panelY, _panelW, _hdrH];
    _hdrBg ctrlSetBackgroundColor [0.14, 0.16, 0.18, 0.95];
    _hdrBg ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _hdrBg;

    // 2: Header text
    private _hdrTxt = _display ctrlCreate ["RscStructuredText", -1];
    _hdrTxt ctrlSetPosition [_panelX, _panelY + (_hdrH * 0.08), _panelW, _hdrH * 0.92];
    _hdrTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _hdrTxt ctrlSetStructuredText parseText "<t align='center' size='0.68' font='PuristaSemibold' color='#d8e0e8'>EWAR C-UAS</t>";
    _hdrTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _hdrTxt;

    // 3: Footer background bar
    private _ftrBg = _display ctrlCreate ["RscText", -1];
    _ftrBg ctrlSetPosition [_panelX, _panelY + _panelH - _ftrH, _panelW, _ftrH];
    _ftrBg ctrlSetBackgroundColor [0.14, 0.16, 0.18, 0.95];
    _ftrBg ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ftrBg;

    // 4: Footer text
    private _ftrTxt = _display ctrlCreate ["RscStructuredText", -1];
    _ftrTxt ctrlSetPosition [_panelX, _panelY + _panelH - _ftrH + (_ftrH * 0.08), _panelW, _ftrH * 0.92];
    _ftrTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _ftrTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ftrTxt;

    // 5 & 6: Top Status Row (LED + Mode Label centered above Battery)
    private _ledW = safeZoneW * 0.0055;
    private _ledH = safeZoneH * 0.0098;
    private _ledX = _panelX + (_panelW * 0.18);
    private _ledY = _bodyY + (_bodyH * 0.08);

    private _ledBezel = _display ctrlCreate ["RscText", -1];
    _ledBezel ctrlSetPosition [_ledX, _ledY, _ledW, _ledH];
    _ledBezel ctrlSetBackgroundColor [0.02, 0.02, 0.02, 0.95];
    _ledBezel ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ledBezel;

    private _ledPadW = safeZoneW * 0.0006;
    private _ledPadH = safeZoneH * 0.0011;
    private _ledCore = _display ctrlCreate ["RscText", -1];
    _ledCore ctrlSetPosition [_ledX + _ledPadW, _ledY + _ledPadH, _ledW - (_ledPadW * 2), _ledH - (_ledPadH * 2)];
    _ledCore ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _ledCore;

    // 7: Mode Text (Beside LED)
    private _modeTxt = _display ctrlCreate ["RscStructuredText", -1];
    _modeTxt ctrlSetPosition [
        _ledX + _ledW + (_panelW * 0.035),
        _ledY - (_bodyH * 0.04),
        _panelW * 0.70,
        _bodyH * 0.22
    ];
    _modeTxt ctrlSetBackgroundColor [0, 0, 0, 0];
    _modeTxt ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _modeTxt;

    // 8..10: Vertical Battery Icon (Slim, balanced aspect ratio centered horizontally)
    private _battW = _panelW * 0.32;
    private _battH = _bodyH * 0.54;
    private _capW = _battW * 0.45;
    private _capH = _bodyH * 0.05;

    private _battX = _panelX + ((_panelW - _battW) / 2);
    private _capTopY = _bodyY + (_bodyH * 0.35);
    private _battY = _capTopY + _capH;

    // 8: Top terminal cap
    private _battCap = _display ctrlCreate ["RscText", -1];
    _battCap ctrlSetPosition [_battX + ((_battW - _capW) / 2), _capTopY, _capW, _capH];
    _battCap ctrlSetBackgroundColor [0.85, 0.88, 0.90, 0.9];
    _battCap ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battCap;

    // 9: Outer battery casing
    private _battOuter = _display ctrlCreate ["RscText", -1];
    _battOuter ctrlSetPosition [_battX, _battY, _battW, _battH];
    _battOuter ctrlSetBackgroundColor [0.85, 0.88, 0.90, 0.9];
    _battOuter ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battOuter;

    // 10: Inner hollow cavity
    private _borderW = safeZoneW * 0.0012;
    private _borderH = safeZoneH * 0.002;
    private _innerX = _battX + _borderW;
    private _innerY = _battY + _borderH;
    private _innerW = _battW - (_borderW * 2);
    private _innerH = _battH - (_borderH * 2);

    private _battInner = _display ctrlCreate ["RscText", -1];
    _battInner ctrlSetPosition [_innerX, _innerY, _innerW, _innerH];
    _battInner ctrlSetBackgroundColor [0.09, 0.10, 0.12, 0.95];
    _battInner ctrlCommit 0;
    GVAR(ewar_backpackHUDCtrls) pushBack _battInner;

    // 11..14: 4 Stacked Horizontal Battery Bars
    private _padX = _innerW * 0.13;
    private _padY = _innerH * 0.09;
    private _gapY = _innerH * 0.06;
    private _segW = _innerW - (_padX * 2);
    private _segH = (_innerH - (_padY * 2) - (_gapY * 3)) / 4;

    for "_i" from 0 to 3 do {
        private _seg = _display ctrlCreate ["RscText", -1];
        private _segY = (_innerY + _innerH - _padY - _segH) - (_i * (_segH + _gapY));
        _seg ctrlSetPosition [_innerX + _padX, _segY, _segW, _segH];
        _seg ctrlCommit 0;
        GVAR(ewar_backpackHUDCtrls) pushBack _seg;
    };
};

private _ftrTxt = GVAR(ewar_backpackHUDCtrls) select 4;
private _ledCore = GVAR(ewar_backpackHUDCtrls) select 6;
private _modeTxt = GVAR(ewar_backpackHUDCtrls) select 7;

if (_isDirectional) then {
    if (_isTransmitting) then {
        if (_targetInCone) then {
            if (_targetInKill) then {
                _ledCore ctrlSetBackgroundColor [1.0, 0.20, 0.20, 1.0];
                _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#ff4444'>KILL</t>";
                _ftrTxt ctrlSetStructuredText parseText "<t align='center' size='0.60' font='PuristaMedium' color='#ff4444'>LINK SEVERED</t>";
            } else {
                if (_lockedIsObstructed) then {
                    _ledCore ctrlSetBackgroundColor [0.95, 0.60, 0.10, 1.0];
                    _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.70' font='PuristaBold' color='#ffaa33'>LOCK [OBS]</t>";
                    private _lockPct = if (finite _burnProgress) then { round (_burnProgress * 100) } else { 0 };
                    _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.54' font='PuristaMedium' color='#ffaa33'>OBS: %1%% [%2m]</t>", _lockPct, _effRadius];
                } else {
                    _ledCore ctrlSetBackgroundColor [0.95, 0.85, 0.15, 1.0];
                    _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#ffe044'>LOCK</t>";
                    private _lockPct = if (finite _burnProgress) then { round (_burnProgress * 100) } else { 0 };
                    _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.54' font='PuristaMedium' color='#ffe044'>LOCK: %1%% [%2m]</t>", _lockPct, _effRadius];
                };
            };
        } else {
            if (_canPulse) then {
                _ledCore ctrlSetBackgroundColor [0.20, 0.85, 1.0, 1.0];
                _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#68d4f8'>PULSE</t>";
                _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.56' font='PuristaMedium' color='#68d4f8'>PULSE: %1m DIR %2°</t>", _effRadius, round _coneAngle];
            } else {
                _ledCore ctrlSetBackgroundColor [0.15, 0.95, 0.25, 1.0];
                _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#88e0ff'>TX DIR</t>";
                _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.60' font='PuristaMedium' color='#68d4f8'>RF: %1m DIR %2°</t>", _effRadius, round _coneAngle];
            };
        };
    } else {
        if (_passiveSignalDetected) then {
            _ledCore ctrlSetBackgroundColor [0.25, 0.70, 0.95, 1.0];
            _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#68d4f8'>SCAN</t>";
            _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.56' font='PuristaMedium' color='#68d4f8'>SCAN: %1m [%2°]</t>", _scanRadius, round _coneAngle];
        } else {
            _ledCore ctrlSetBackgroundColor [0.95, 0.15, 0.15, 1.0];
            _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#d8b8b8'>STBY</t>";
            _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.60' font='PuristaMedium' color='#98a6b4'>RF: %1m DIR %2°</t>", _effRadius, round _coneAngle];
        };
    };
} else {
    _ftrTxt ctrlSetStructuredText parseText format ["<t align='center' size='0.62' font='PuristaMedium' color='#98a6b4'>RF: %1m OMNI</t>", _radius];

    if (_isActive) then {
        _ledCore ctrlSetBackgroundColor [0.15, 0.95, 0.25, 1.0];
        _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#e0f4e0'>TX ON</t>";
    } else {
        _ledCore ctrlSetBackgroundColor [0.95, 0.15, 0.15, 1.0];
        _modeTxt ctrlSetStructuredText parseText "<t align='left' size='0.74' font='PuristaBold' color='#d8b8b8'>STBY</t>";
    };
};

// Semiotic 4-Stage Battery Bar Colors
private _effBattery = if (EGVAR(Settings,ewar_backpackRequiresBattery)) then { _battery } else { 100 };
private _activeSegs = switch (true) do {
    case (_effBattery > 75): { 4 };
    case (_effBattery > 50): { 3 };
    case (_effBattery > 25): { 2 };
    case (_effBattery > 0):  { 1 };
    default                  { 0 };
};

private _segColor = switch (_activeSegs) do {
    case 4: { [0.48, 0.80, 0.38, 0.95] }; // 76-100%: Solid Green
    case 3: { [0.98, 0.90, 0.22, 0.95] }; // 51-75%: Solid Yellow
    case 2: { [0.98, 0.64, 0.20, 0.95] }; // 26-50%: Solid Orange
    case 1: { [0.94, 0.36, 0.36, 0.95] }; // 1-25%: Solid Red
    default { [0.94, 0.36, 0.36, 0.95] };
};

private _emptySegColor = [0.20, 0.22, 0.25, 0.45];

private _flashBottom = _effBattery <= 10 && {_effBattery > 0};
private _flashOn = if (_flashBottom) then {
    ((floor (diag_tickTime * 2)) mod 2) == 0
} else {
    true
};

for "_i" from 0 to 3 do {
    private _segCtrl = GVAR(ewar_backpackHUDCtrls) select (11 + _i);
    if (_i < _activeSegs) then {
        if (_i == 0 && {_flashBottom} && {!_flashOn}) then {
            _segCtrl ctrlSetBackgroundColor [0.45, 0.15, 0.15, 0.25];
        } else {
            _segCtrl ctrlSetBackgroundColor _segColor;
        };
    } else {
        _segCtrl ctrlSetBackgroundColor _emptySegColor;
    };
};
