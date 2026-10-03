/*
    Description:
    A point a little outside the map (1.5 km beyond its edge), where an occupier aircraft comes from or
    leaves to when the occupier holds no airfield. On a random edge, level with the position give or
    take a quarter of the map, or straight out over the edge nearest the position.

    Parameters:
        _this # 0: ARRAY - Position
        _this # 1: BOOL - (Optional) The edge nearest the position instead of a random one

    Usage: private _origin = [_dropPoint] call OT_fnc_NATOoffMapPoint;

    Returns: ARRAY - [x, y, 0]
*/

params ["_pos", ["_nearest", false]];

private _size = worldSize;
private _margin = 1500;
_pos params ["_px", "_py"];

// West, east, south, north
private _edge = floor random 4;
if (_nearest) then {
    private _gaps = [_px, _size - _px, _py, _size - _py];
    _edge = _gaps find (selectMin _gaps);
};

// Along the edge: level with the position (a random edge: give or take a quarter of the map), on the map
private _shift = 0;
if (!_nearest) then { _shift = (_size / 4) - random (_size / 2) };
private _ax = ((_px + _shift) max 0) min _size;
private _ay = ((_py + _shift) max 0) min _size;

[
    [-_margin, _ay, 0],
    [_size + _margin, _ay, 0],
    [_ax, -_margin, 0],
    [_ax, _size + _margin, 0]
] select _edge;
