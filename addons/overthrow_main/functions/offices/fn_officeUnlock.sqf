/*
    Description:
    A locked door of a compound's building (OT_fnc_officeDoors), or a compound's locked gate (all its doors,
    OT_fnc_officeSpawnItems), unlocked: by the lockpick (OT_fnc_officeLockNear), or blown open by a charge
    (OT_fnc_officeBreach). Server.

    Parameters:
        _this # 0: OBJECT - Building or gate
        _this # 1: NUMBER - (Optional) Door, from 1; -1 for all of them, default
        _this # 2: BOOL - (Optional) Swung open as well, default false

    Usage: [_building, 2] remoteExec ["OT_fnc_officeUnlock", 2];

    Returns: Nothing
*/

params [["_building", objNull, [objNull]], ["_door", -1, [0]], ["_open", false, [false]]];

if (isNull _building) exitWith {};
private _doors = [];
if (_door < 0) then {
    for "_d" from 1 to getNumber (configOf _building >> "numberOfDoors") do { _doors pushBack _d };
} else {
    _doors = [_door];
};
if (_open && { !isNil { _building getVariable "OT_officeItem" } }) then { _building enableSimulationGlobal true };
private _sources = ("true" configClasses (configOf _building >> "AnimationSources")) apply { toLower configName _x };
{
    _building setVariable [format ["bis_disabled_Door_%1", _x], 0, true];
    if (_open) then {
        private _prefix = format ["door_%1_", _x];
        { if ((_x find _prefix) isEqualTo 0) then { _building animateSource [_x, 1] } } forEach _sources;
    };
} forEach _doors;
_building setVariable ["OT_lockedDoors", (_building getVariable ["OT_lockedDoors", []]) - _doors, true];
if (_door < 0) then { _building setVariable ["OT_officeGate", nil, true] };
