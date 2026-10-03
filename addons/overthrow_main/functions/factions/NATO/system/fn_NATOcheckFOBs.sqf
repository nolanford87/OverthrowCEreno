/*
    Author: ThomasAngel, ARMAZac

    Description:
    Loops through all FOBs

    Parameters:
        -

    Usage: [] call OT_fnc_NATOabandonTowers;

    Returns: Boolean - was a FOB cleared
*/

private _countered = false;
private _clearedFOBs = [];
private _fobs = server getVariable ["NATOfobs", []];

{
    _x params ["_pos", "_garrison"];
    // Its garrison is virtualized (OT_fnc_spawnNATOFOB): not spawned (or still spawning), its stored
    // soldiers hold it, spawned the living occupier soldiers near it do (its dead don't hold it)
    private _spawnid = OT_fobSpawners getOrDefault [_pos, ""];
    private _spawned = _spawnid in OT_allSpawned && { (spawner getVariable [format ["spawning%1", _spawnid], -1]) isEqualTo -1 };
    private _numMil = _garrison;
    if (_spawned || { _spawnid isEqualTo "" }) then {
        _numMil = { alive _x && { side group _x isEqualTo blufor } } count (_pos nearEntities ["CAManBase", 300]);
    };
    private _numRes = { alive _x && { side _x isEqualTo independent || captive _x } } count (_pos nearEntities ["CAManBase", 50]);
    if (_numMil isEqualTo 0 && { _numRes > 0 }) then {
        _countered = true;
        _clearedFOBs pushBack _x;
        format ["Cleared %1 FOB", OT_NATO_name] remoteExec ["OT_fnc_notifyMinor", 0, false];
        [_pos] call OT_fnc_NATOclearFOB; // Its construction goes, the bodies stay
    };
} forEach _fobs;

{
    _fobs deleteAt (_fobs find _x);
} forEach _clearedFOBs;

_countered;
