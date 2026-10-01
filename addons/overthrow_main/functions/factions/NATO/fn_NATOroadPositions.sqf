/*
    Description:
    Spots on a road to spawn a column of vehicles in, one behind the other: the first on the given
    road piece, the others following the road back, away from where the column is heading, about
    _spacing apart. A dead end runs out of road: other road pieces nearby make up the rest. Every
    spot is the centre of a road piece, so the vehicles spawn on the road, clear of buildings.

    Parameters:
        _this # 0: OBJECT - Road piece the first vehicle starts on
        _this # 1: NUMBER - How many spots
        _this # 2: ARRAY - Where the column is heading
        _this # 3: NUMBER - (Optional) Metres between vehicles, default 25

    Usage: ([_road, 3, _basePos] call OT_fnc_NATOroadPositions) params ["_lead", ...];

    Returns: ARRAY - [[position ATL, direction], ...], the first one in front
*/

params ["_road", "_count", "_towards", ["_spacing", 25]];

private _spots = [getPosATL _road];
private _visited = [_road];
private _current = _road;
private _last = getPosATL _road;
private _steps = 0;
while { count _spots < _count && { _steps < 200 } } do {
    _steps = _steps + 1;
    private _next = (roadsConnectedTo _current) - _visited;
    if (_next isEqualTo []) exitWith {};
    // Back along the road: the piece furthest from where it's heading
    _current = ([_next, [], { _x distance2D _towards }, "DESCEND"] call BIS_fnc_sortBy) select 0;
    _visited pushBack _current;
    if (((getPosATL _current) distance2D _last) >= _spacing) then {
        _last = getPosATL _current;
        _spots pushBack _last;
    };
};
// A dead end: other road pieces nearby
if (count _spots < _count) then {
    {
        if (count _spots >= _count) exitWith {};
        private _p = getPosATL _x;
        if ((_spots findIf { (_x distance2D _p) < _spacing }) isEqualTo -1) then { _spots pushBack _p };
    } forEach ([_road nearRoads 200, [], { _x distance2D _road }, "ASCEND"] call BIS_fnc_sortBy);
};

// Each faces the one in front of it, the first one where it's heading
_spots apply {
    private _i = _spots find _x;
    private _dir = [(_x getDir (_spots select (_i - 1))), (_x getDir _towards)] select (_i isEqualTo 0);
    [[_x select 0, _x select 1, 0], _dir]
};
