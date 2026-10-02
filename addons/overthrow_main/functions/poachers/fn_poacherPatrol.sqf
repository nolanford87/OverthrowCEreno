/*
    Description:
    Sends a poacher patrol into a hunting spot: 1-3 poachers dressed as hunters (OT_fnc_poacherUnit),
    OPFOR like the gangs (hostile to the resistance and the occupier) but no gang's members. They
    start just outside the spot (250 m from its middle), on the far side from the nearest player, and
    walk around inside it. Nobody is told. They stay OT_poacherStayTime (10 real minutes), longer once
    their backup comes. OT_fnc_poacherLoop runs them:
    spotting a player in the spot starts a call for backup (OT_fnc_poacherCall).

    The spot's entry in OT_poacherEvents (HASHMAP):
        "patrol" - ARRAY of the patrol's units
        "backup" - ARRAY of the backup's units (OT_fnc_poacherBackup)
        "groups" - ARRAY of their groups
        "vehicles" - ARRAY of the backup's vehicles
        "state" - STRING "patrol", "calling" (for backup) or "backup" (it's coming)
        "callEnd" - NUMBER time the call for backup goes through
        "nextSound" - NUMBER time of the next bit of radio chatter
        "target" - ARRAY where the backup heads (the player they saw)
        "from" - ARRAY where the patrol came from (and goes back to)
        "started" - NUMBER time they were sent
        "until" - NUMBER time they leave (unless still on the radio)

    Parameters:
        _this # 0: NUMBER - Hunting spot index
        _this # 1: NUMBER - (Optional) How many, 1-3 (default: 0, a random 1-3)

    Usage: [_index] call OT_fnc_poacherPatrol; (server)

    Returns: GROUP - The patrol, grpNull if none was sent (no such spot, or poachers already there)
*/

params ["_index", ["_count", 0]];

if (!isServer) exitWith { grpNull };
if (isNil "OT_poacherEvents") then { OT_poacherEvents = createHashMap };
private _pos = (server getVariable ["huntingSpots", []]) param [_index, []];
if (_pos isEqualTo [] || { _index in OT_poacherEvents }) exitWith { grpNull };
_pos = [_pos select 0, _pos select 1, 0];
if (_count < 1) then { _count = 1 + floor random 3 };
_count = _count min 3;

// Where from: the far side of the spot from the nearest player, on land
private _players = (allPlayers - entities "HeadlessClient_F") select { alive _x };
private _nearest = objNull;
private _dist = 1e9;
{
    if ((_x distance2D _pos) < _dist) then { _nearest = _x; _dist = _x distance2D _pos };
} forEach _players;
private _away = random 360;
if (!isNull _nearest && { _dist > 5 }) then { _away = _nearest getDir _pos };
private _from = [];
{
    private _p = _pos getPos [250, _away + _x];
    if (!surfaceIsWater _p) exitWith { _from = _p };
} forEach [0, 45, -45, 90, -90, 135, -135, 180];
if (_from isEqualTo []) then { _from = +_pos };
_from set [2, 0];

private _group = createGroup [opfor, true];
_group setVariable ["VCM_NORESCUE", true, true];
private _units = [];
for "_i" from 1 to _count do {
    _units pushBack ([_group, _from, _index, "hunter"] call OT_fnc_poacherUnit);
};
_group setBehaviour "AWARE";
_group setCombatMode "YELLOW";
_group setSpeedMode "LIMITED";
_group setFormation "STAG COLUMN";

// Into the spot and around it
private _wp = _group addWaypoint [_pos, 40];
_wp setWaypointType "MOVE";
for "_i" from 1 to 3 do {
    _wp = _group addWaypoint [_pos getPos [60 + random 90, random 360], 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointTimeout [10, 30, 60];
};
_wp = _group addWaypoint [_pos, 40];
_wp setWaypointType "CYCLE";

OT_poacherEvents set [_index, createHashMapFromArray [
    ["patrol", _units],
    ["backup", []],
    ["groups", [_group]],
    ["vehicles", []],
    ["state", "patrol"],
    ["callEnd", 0],
    ["nextSound", 0],
    ["target", +_pos],
    ["from", _from],
    ["started", time],
    ["until", time + OT_poacherStayTime]
]];
diag_log format ["Overthrow: %1 poachers sent into hunting spot %2", _count, _index];
_group
