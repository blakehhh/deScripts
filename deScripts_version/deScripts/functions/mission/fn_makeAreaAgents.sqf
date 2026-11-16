#include "..\script_component.hpp";
/*
 * Author: Antigravity
 * Converts eligible non-player civilian AI units within a trigger or radius into lightweight agents.
 *
 * Arguments:
 * 0: Center <ARRAY, OBJECT, or TRIGGER>
 * 1: Radius <NUMBER> (Optional, Default: 150, ignored if Center is a Trigger)
 *
 * Return Value:
 * Number of converted units <NUMBER>
 *
 * Example:
 * [getPos player, 150] call deScripts_fnc_makeAreaAgents;
 * [thisTrigger] call deScripts_fnc_makeAreaAgents;
 *
 * Public: Yes
 */

if (!isServer) exitWith {0};

params [
    ["_center", [0, 0, 0], [[], objNull]],
    ["_radius", 150, [0]]
];

private _isTrigger = (_center isEqualType objNull) && {!isNull _center} && {triggerArea _center isNotEqualTo [0, 0, 0, false, -1]};
private _centerPos = if (_center isEqualType objNull) then {
    if (isNull _center) then { [0, 0, 0] } else { getPosASL _center }
} else {
    _center
};

if (!_isTrigger && {_centerPos isEqualTo [0, 0, 0]}) exitWith {0};

private _targets = allUnits select {
    (side _x == civilian) &&
    {!isPlayer _x} &&
    {!(_x in playableUnits)} &&
    {isNull objectParent _x} &&
    {!(_x getVariable [QEGVAR(Agent,ignore), false])} &&
    {if (_isTrigger) then {_x inArea _center} else {(_x distance2D _centerPos) <= _radius}}
};

{
    [_x] call FUNC(makeAgent);
} forEach _targets;

count _targets
