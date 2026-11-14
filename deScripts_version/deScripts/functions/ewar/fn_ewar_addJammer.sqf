#include "..\script_component.hpp";
/*
 * Author: deScripts Team
 * Registers a new omnidirectional EWAR drone jammer bubble in the mission.
 *
 * Arguments:
 * 0: Source Object, Position Array, or Marker Name <OBJECT|ARRAY|STRING>
 * 1: Max Jamming Radius in meters <NUMBER> (Default: 300)
 * 2: Core Jamming Radius Ratio <NUMBER> (Default: 0)
 * 3: Exempt Side(s) <SIDE|ARRAY> (Default: sideUnknown)
 *
 * Return Value:
 * Jammer ID <STRING>
 *
 * Example:
 * [this, 300] call deScripts_fnc_ewar_addJammer
 * ["marker_jammer_1", 500, 0.25, west] call deScripts_fnc_ewar_addJammer
 *
 * Public: Yes
 */

params [
    ["_source", objNull, [objNull, [], ""]],
    ["_radius", 300, [0]],
    ["_coreRatio", 0, [0]],
    ["_sideExempt", sideUnknown, [sideUnknown, []]]
];

if (_source isEqualType "") then {
    _source = getMarkerPos _source;
};

if (_source isEqualType objNull && {isNull _source}) exitWith { "" };
if (_source isEqualType [] && {_source isEqualTo [0, 0, 0]}) exitWith { "" };

private _jammerID = format ["ewar_jammer_%1_%2", round (random 100000), round diag_tickTime];
private _jammerData = [_jammerID, _source, _radius, _coreRatio, _sideExempt];

if (_source isEqualType objNull) then {
    _source setVariable [QGVAR(ewar_jammerID), _jammerID, true];
};

if (!isServer) then {
    if (isNil QGVAR(ewar_jammers)) then {
        GVAR(ewar_jammers) = [];
    };
    GVAR(ewar_jammers) pushBackUnique _jammerData;
};
[QGVAR(ewar_addJammer), [_jammerData]] call CBA_fnc_serverEvent;

_jammerID
