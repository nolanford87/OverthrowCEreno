/*
    Description:
    Finds a spot for a wild ganja zone (OT_fnc_ganjaValidSpot): random tries anywhere on the map, or
    around a position (the QA tests use that to put one near the host).

    Parameters:
        _this # 0: ARRAY - (Optional) Search around here, [] for anywhere on the map
        _this # 1: NUMBER - (Optional) Search radius around it, default 3000 m
        _this # 2: ARRAY - (Optional) More positions to keep OT_ganjaZoneSpacing from
        _this # 3: NUMBER - (Optional) Tries, default 400

    Usage: private _pos = [] call OT_fnc_ganjaFindSpot;

    Returns: ARRAY - Position, [] if none was found
*/

params [["_center", []], ["_radius", 3000], ["_avoid", []], ["_tries", 400]];

private _found = [];
for "_i" from 1 to _tries do {
    private _p = if (_center isEqualTo []) then {
        [random worldSize, random worldSize, 0]
    } else {
        _center getPos [100 + random (_radius - 100), random 360]
    };
    if ((_p select 0) < 100 || { (_p select 1) < 100 } || { (_p select 0) > (worldSize - 100) } || { (_p select 1) > (worldSize - 100) }) then { continue };
    if ([_p, _avoid] call OT_fnc_ganjaValidSpot) exitWith { _found = [round (_p select 0), round (_p select 1), 0] };
};
_found
