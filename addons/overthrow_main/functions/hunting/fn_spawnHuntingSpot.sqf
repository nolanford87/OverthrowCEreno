/*
    Description:
    Spawner for a hunting spot (OT_fnc_registerSpawner): its animals, as many as it has right now
    (OT_fnc_huntingAvailable), wandering inside it. Mostly rabbits, some goats and sheep (wild
    herds, no support cost here), the odd snake. One killed counts against the spot until it comes back.

    Parameters:
        _this # 0: NUMBER - Spot index
        _this # 1: STRING - Spawn id

    Usage: (spawner)
*/

params ["_index", "_spawnid"];

private _pos = (server getVariable ["huntingSpots", []]) param [_index, []];
if (_pos isEqualTo []) exitWith {};
private _count = [format ["spot%1", _index]] call OT_fnc_huntingAvailable;

private _animals = [];
for "_i" from 1 to _count do {
    private _cls = selectRandomWeighted ["Rabbit_F", 0.5, "Goat_random_F", 0.2, "Sheep_random_F", 0.2, "Snake_random_F", 0.1];
    private _p = _pos getPos [random 170, random 360];
    if (surfaceIsWater _p) then { _p = _pos };
    private _animal = createAgent [_cls, _p, [], 0, "NONE"];
    _animal setDir (random 360);
    _animal setVariable ["OT_huntKey", format ["spot%1", _index]];
    _animal addEventHandler ["Killed", {
        params ["_animal"];
        [_animal getVariable ["OT_huntKey", ""], -1] call OT_fnc_huntingAvailable;
    }];
    _animals pushBack _animal;
};

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _animals, false];
