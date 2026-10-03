/*
    Description:
    Counts the drug operations' heat and raid timers down in real time (server, every 30 seconds from
    OT_fnc_initDrugRaids, only while players are online, like the town grace periods): heat loses
    OT_drugHeatDecay a minute, the time shut after a raid and the cooldown before the next one run
    down, and an operation whose shut time runs out is reported open again. Entries with nothing
    left are dropped from "drugHeat".

    Usage: [] call OT_fnc_drugHeatTick; (server)

    Returns: NUMBER - Real seconds counted down (at most 30)
*/

private _now = time;
private _elapsed = ((_now - (missionNamespace getVariable ["OT_drugHeatLast", _now])) max 0) min 30;
OT_drugHeatLast = _now;

private _list = server getVariable ["drugHeat", []];
if (_list isEqualTo [] || { _elapsed isEqualTo 0 }) exitWith { _elapsed };

private _reopened = [];
{
    _x params ["_opId", "_heat", "_shut", "_cooldown"];
    _x set [1, (_heat - (OT_drugHeatDecay * _elapsed / 60)) max 0];
    if (_shut > 0) then {
        _shut = (_shut - _elapsed) max 0;
        _x set [2, _shut];
        if (_shut isEqualTo 0) then { _reopened pushBack _opId };
    };
    if (_cooldown > 0) then { _x set [3, (_cooldown - _elapsed) max 0] };
} forEach _list;
server setVariable ["drugHeat", _list select { (_x select 1) > 0 || { (_x select 2) > 0 } || { (_x select 3) > 0 } }, true];

{
    private _name = [_x] call OT_fnc_drugOpBusiness;
    if (_name isEqualTo "") then { _name = _x };
    format ["%1 is open again after the raid", _name] remoteExec ["OT_fnc_notifyMinor", 0, false];
} forEach _reopened;
_elapsed
