// This function should only be called on the server

params ["_town", "_soldier", "_amount"];

// Only spawn them now if the town is spawned, so they are despawned with it. Otherwise
// spawnPolice spawns them from the police count when the town spawns
private _spawnid = spawner getVariable [format ["townspawnid%1", _town], ""];
if !(_spawnid in OT_allSpawned) exitWith {};

private _posTown = server getVariable [format ["policepos%1", _town], server getVariable _town];

private _group = createGroup independent;
_group setVariable ["VCM_TOUGHSQUAD", true, true];
_group setVariable ["VCM_NORESCUE", true, true];

for "_i" from 1 to _amount do {
    private _pos = [[[_posTown, 35]]] call BIS_fnc_randomPos;

    private _unit = [_soldier, _pos, _group, false] call OT_fnc_createSoldier; // Gear was taken from the warehouse by addPolice
    [_unit] joinSilent _group;
    _unit setRank "SERGEANT";
    [_unit, _town] call OT_fnc_initPolice;
    _unit setBehaviour "SAFE";
};

_group call OT_fnc_initPolicePatrol;

private _groups = spawner getVariable [_spawnid, []];
_groups pushBack _group;
spawner setVariable [_spawnid, _groups, false];
