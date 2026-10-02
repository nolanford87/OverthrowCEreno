/*
    Description:
    A hunting spot's hunting pressure: how much game has been taken there in the last
    OT_poacherWindow real seconds (30 minutes, the time a spot takes to refill). Each animal killed
    counts by its size (OT_fnc_poacherKill); older kills drop out of it.

    Parameters:
        _this # 0: NUMBER - Spot index
        _this # 1: NUMBER - (Optional) Pressure to add now (default: 0)
        _this # 2: BOOL - (Optional) Clear it first (default: false)

    Usage: [_index] call OT_fnc_poacherPressure; (server)

    Returns: NUMBER - The pressure now
*/

params ["_index", ["_add", 0], ["_reset", false]];

if (isNil "OT_poacherPressure") then { OT_poacherPressure = createHashMap };
private _kills = if (_reset) then { [] } else {
    (OT_poacherPressure getOrDefault [_index, []]) select { (time - (_x select 0)) < OT_poacherWindow }
};
if (_add > 0) then { _kills pushBack [time, _add] };
if (_kills isEqualTo []) then { OT_poacherPressure deleteAt _index } else { OT_poacherPressure set [_index, _kills] };

private _total = 0;
{ _total = _total + (_x select 1) } forEach _kills;
_total
