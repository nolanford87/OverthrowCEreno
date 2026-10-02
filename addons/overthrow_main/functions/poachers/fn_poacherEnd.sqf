/*
    Description:
    The poachers in a hunting spot are done: wiped out, or the spot has cooled and they leave. Those
    still alive head back the way they came, a kilometre out. Everything (them, the dead, the backup's
    vehicles) goes on OT_poacherCleanup, deleted by OT_fnc_poacherLoop once no player is within 500 m
    of it - never a vehicle a player is in or has claimed. The spot is free for a new patrol.

    Parameters:
        _this # 0: NUMBER - Hunting spot index

    Usage: [_index] call OT_fnc_poacherEnd; (server)
*/

params ["_index"];

if (!isServer || { isNil "OT_poacherEvents" }) exitWith {};
private _ev = OT_poacherEvents getOrDefault [_index, createHashMap];
OT_poacherEvents deleteAt _index;
if ((count _ev) isEqualTo 0) exitWith {};

private _pos = (server getVariable ["huntingSpots", []]) param [_index, _ev get "from"];
private _away = _pos getPos [1000, _pos getDir (_ev get "from")];
private _groups = (_ev get "groups") select { !isNull _x };
{
    private _group = _x;
    for "_i" from (count (waypoints _group)) - 1 to 0 step -1 do { deleteWaypoint [_group, _i] };
    _group setBehaviour "SAFE";
    _group setCombatMode "GREEN";
    _group setSpeedMode "NORMAL";
    _group move _away;
} forEach _groups;

if (isNil "OT_poacherCleanup") then { OT_poacherCleanup = [] };
OT_poacherCleanup pushBack [(_ev get "patrol") + (_ev get "backup") + (_ev get "vehicles"), _groups];
