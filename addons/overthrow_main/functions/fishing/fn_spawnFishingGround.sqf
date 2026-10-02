/*
    Description:
    Spawner for a fishing ground (OT_fnc_registerSpawner): its fish, as many as it has right now
    (6-10, OT_fnc_huntingAvailable; a caught one comes back over about 30 real minutes), swimming 2-6 m
    under the surface inside it. Mostly small fish, fewer mackerel, rare catsharks, tuna and turtles.

    Parameters:
        _this # 0: NUMBER - Ground index
        _this # 1: STRING - Spawn id

    Usage: (spawner)
*/

params ["_index", "_spawnid"];

private _pos = (server getVariable ["fishingGrounds", []]) param [_index, []];
if (_pos isEqualTo []) exitWith {};
private _key = format ["fish%1", _index];
private _count = [_key, 0, [6, 10]] call OT_fnc_huntingAvailable;

private _fish = [];
for "_i" from 1 to _count do {
    private _cls = selectRandomWeighted [
        "Salema_F", 0.25, "Ornate_random_F", 0.2, "Mullet_F", 0.2, "Mackerel_F", 0.15,
        "CatShark_F", 0.08, "Tuna_F", 0.07, "Turtle_F", 0.05
    ];
    private _p = _pos getPos [random 180, random 360];
    private _agent = createAgent [_cls, _p, [], 0, "CAN_COLLIDE"];
    _agent setPosASL [_p select 0, _p select 1, -2 - random 4];
    _agent setVariable ["OT_huntKey", _key];
    _fish pushBack _agent;
};

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _fish, false];
