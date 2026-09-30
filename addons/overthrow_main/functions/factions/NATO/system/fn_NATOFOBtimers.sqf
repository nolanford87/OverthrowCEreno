/*
    Description:
    Counts down the FOB takeover timers (OT_fnc_NATOstartFOBTimer). A timer whose FOB was cleared is
    dropped. When one runs out, the town falls back under the occupier's control: 100% stability,
    no resistance support, a small occupier garrison. Run by the NATO loop every few seconds, the
    time left is saved with the game.

    Usage: call OT_fnc_NATOFOBtimers;
*/

private _now = time;
// The loop only runs with players online, time without any doesn't count
private _elapsed = ((_now - (missionNamespace getVariable ["OT_fobTimerLast", _now])) max 0) min 30;
OT_fobTimerLast = _now;

private _timers = server getVariable ["NATOfobTimers", []];
if (_timers isEqualTo []) exitWith {};
private _fobs = (server getVariable ["NATOfobs", []]) apply { _x select 0 };
private _keep = [];

{
    _x params ["_fobPos", "_left", "_town"];
    if !(_fobPos in _fobs) then {
        format ["The %1 FOB near %2 was cleared, %2 stays as it is", OT_NATO_name, _town] remoteExec ["OT_fnc_notifyGood", 0, false];
        continue;
    };
    _left = _left - _elapsed;
    if (_left > 0) then {
        _keep pushBack [_fobPos, _left, _town];
        continue;
    };

    // Time's up: the town is the occupier's again
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _index = _abandoned find _town;
    if (_index > -1) then { _abandoned deleteAt _index };
    server setVariable ["NATOabandoned", _abandoned, true];
    server setVariable [format ["NATOpatrolsent%1", _town], false];

    [_town, -(server getVariable [format ["rep%1", _town], 0])] call OT_fnc_support;
    [_town, 100 - (server getVariable [format ["stability%1", _town], 0])] call OT_fnc_stability;

    // The garrison a town at 100% stability starts with (initNATO)
    private _garrison = [2, 4] select (_town in OT_NATO_priority);
    server setVariable [format ["garrison%1", _town], (server getVariable [format ["garrison%1", _town], 0]) max _garrison, true];

    format ["%1 is back under %2 control", _town, OT_NATO_name] remoteExec ["OT_fnc_notifyBad", 0, false];
    diag_log format ["Overthrow: %1 FOB took %2 back", OT_NATO_name, _town];
} forEach _timers;

server setVariable ["NATOfobTimers", _keep];
