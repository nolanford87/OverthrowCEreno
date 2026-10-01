/*
    Description:
    Spots on a road to spawn a column of vehicles in, one behind the other, from the given road
    piece forward along the road towards where the column is heading (out of the base it starts
    at, not deeper into it), about _spacing apart. A spot with a building or vehicle within 7 m is
    skipped (a big vehicle would clip it and be wrecked). A dead end runs out of road: other clear
    road pieces nearby make up the rest. Every spot is the centre of a road piece.

    Parameters:
        _this # 0: OBJECT - Road piece the last vehicle starts on
        _this # 1: NUMBER - How many spots
        _this # 2: ARRAY - Where the column is heading
        _this # 3: NUMBER - (Optional) Metres between vehicles, default 25

    Usage: ([_road, 3, _basePos] call OT_fnc_NATOroadPositions) params ["_lead", ...];

    Returns: ARRAY - [[position ATL, direction], ...], the first one in front
*/

params ["_road", "_count", "_towards", ["_spacing", 25]];

private _clear = { (nearestObjects [_this, ["Building", "LandVehicle"], 7]) isEqualTo [] };

private _spots = [];
private _visited = [_road];
private _current = _road;
private _last = [];
if ((getPosATL _road) call _clear) then { _last = getPosATL _road; _spots pushBack _last };
private _steps = 0;
while { count _spots < _count && { _steps < 300 } } do {
    _steps = _steps + 1;
    private _next = (roadsConnectedTo _current) - _visited;
    if (_next isEqualTo []) exitWith {};
    // On along the road: the piece nearest to where it's heading
    _current = ([_next, [], { _x distance2D _towards }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    _visited pushBack _current;
    private _p = getPosATL _current;
    if ((_last isEqualTo [] || { (_p distance2D _last) >= _spacing }) && { _p call _clear }) then {
        _last = _p;
        _spots pushBack _p;
    };
};
// A dead end: other clear road pieces nearby
if (count _spots < _count) then {
    {
        if (count _spots >= _count) exitWith {};
        private _p = getPosATL _x;
        if ((_spots findIf { (_x distance2D _p) < _spacing }) isEqualTo -1 && { _p call _clear }) then { _spots pushBack _p };
    } forEach ([_road nearRoads 250, [], { _x distance2D _road }, "ASCEND"] call BIS_fnc_sortBy);
};
// Nothing clear at all: the road pieces as they are
if (_spots isEqualTo []) then { _spots pushBack (getPosATL _road) };

// Front first: the spot furthest along. Each faces the one in front of it, the first one where it's heading
reverse _spots;
_spots apply {
    private _i = _spots find _x;
    private _dir = [(_x getDir (_spots select (_i - 1))), (_x getDir _towards)] select (_i isEqualTo 0);
    [[_x select 0, _x select 1, 0], _dir]
};
