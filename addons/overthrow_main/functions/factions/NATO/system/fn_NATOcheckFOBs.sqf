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
    private _numMil = { alive _x && { side group _x isEqualTo blufor } } count (_pos nearEntities ["CAManBase", 300]); // Its dead don't hold it
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
