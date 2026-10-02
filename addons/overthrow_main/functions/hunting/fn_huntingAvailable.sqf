/*
    Description:
    How many animals a hunting spot or farm has right now, and records a change. Each has 3-5 (farms
    2-4) animals for the session; one killed comes back over real time, the whole lot in about 30
    minutes. Kept for the session only (OT_huntState, server).

    Parameters:
        _this # 0: STRING - Key ("spot<i>" or "farm<pos>")
        _this # 1: NUMBER - (Optional) Change to the count (-1: one was killed)
        _this # 2: ARRAY - (Optional) [min, max] animals, default [3, 5]

    Usage: ["spot4"] call OT_fnc_huntingAvailable;

    Returns: NUMBER - Animals available
*/

params ["_key", ["_change", 0], ["_range", [3, 5]]];

if (isNil "OT_huntState") then { OT_huntState = createHashMap };
private _state = OT_huntState getOrDefault [_key, []];
if (_state isEqualTo []) then {
    private _max = (_range select 0) + floor random (((_range select 1) - (_range select 0)) + 1);
    _state = [_max, _max, time];
};
_state params ["_max", "_count", "_last"];

// Refill: all of them back in 30 minutes
private _per = 1800 / _max;
private _back = floor ((time - _last) / _per);
if (_back > 0) then {
    _count = (_count + _back) min _max;
    _last = [_last + (_back * _per), time] select (_count >= _max);
};
if (_change isNotEqualTo 0) then {
    if (_count >= _max) then { _last = time };
    _count = ((_count + _change) max 0) min _max;
};
OT_huntState set [_key, [_max, _count, _last]];
_count
