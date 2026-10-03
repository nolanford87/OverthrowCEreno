/*
    Description:
    A gang's turf anger record (server; the saved server variable "drugTurfAnger", one record per gang
    that has had something to be angry about): [gang id, anger, last tick, last attack, warned, rep
    bucket]. The anger is brought up to date (OT_drugTurfDecay forgotten per real minute since the last
    tick) and stored again; a gang without a record gets a fresh one. Times are serverTime (the same
    on every machine): a record from an earlier session, with times ahead of now, starts its clocks
    again. Given a record, that is stored instead (the way to change one: take it, change it, give it
    back).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: ARRAY - (Optional) A record to store

    Usage: private _state = [_gangId] call OT_fnc_drugTurfState; (server)
           [_gangId, _state] call OT_fnc_drugTurfState;

    Returns: ARRAY - The record (a copy)
*/

params ["_gangId", ["_store", []]];

private _all = server getVariable ["drugTurfAnger", []];
private _i = _all findIf { (_x select 0) isEqualTo _gangId };

if (_store isNotEqualTo []) exitWith {
    if (_i > -1) then { _all set [_i, +_store] } else { _all pushBack (+_store) };
    server setVariable ["drugTurfAnger", _all, true];
    +_store
};

private _state = if (_i > -1) then { +(_all select _i) } else { [_gangId, 0, serverTime, -1e6, false, 0] };
_state params ["", "_anger", "_tick", "_attack"];
if (_tick > serverTime || { _attack > serverTime }) then {
    // An earlier session's clocks
    _tick = serverTime;
    _attack = -1e6;
};
_anger = (_anger - (((serverTime - _tick) / 60) * OT_drugTurfDecay)) max 0;
_state set [1, _anger];
_state set [2, serverTime];
_state set [3, _attack];
if (_anger < (OT_drugTurfWarnAt / 2)) then { _state set [4, false] }; // Cooled down: they'd warn again

if (_i > -1) then { _all set [_i, _state] } else { _all pushBack _state };
server setVariable ["drugTurfAnger", _all, true];
+_state
