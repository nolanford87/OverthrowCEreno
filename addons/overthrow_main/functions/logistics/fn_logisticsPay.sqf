/*
    Description:
    What a haul pays, how long it may take and how dangerous the route is. Danger (0 to 0.5) is the
    share of towns within 1.5 km of the straight route that the occupier still holds or that are
    unstable (below 50), scaled to 0.5; it raises the pay by as much. The time limit is about 1.5 times
    the driving time at 40 km/h (90 s per km), plus a minute to load.

    Parameters:
        _this # 0: ARRAY - From (loading spot)
        _this # 1: ARRAY - To (drop-off)
        _this # 2: NUMBER - Crates

    Usage: [_fromPos, _toPos, _crates] call OT_fnc_logisticsPay;

    Returns: ARRAY - [pay $, time limit in seconds (real time), danger 0-0.5]
*/

params ["_fromPos", "_toPos", "_crates"];

private _distKm = (_fromPos distance2D _toPos) / 1000;
private _abandoned = server getVariable ["NATOabandoned", []];

// Distance from a town to the route segment (2D), the town counts if it's within 1.5 km
private _ax = _fromPos select 0;
private _ay = _fromPos select 1;
private _dx = (_toPos select 0) - _ax;
private _dy = (_toPos select 1) - _ay;
private _len2 = (_dx * _dx) + (_dy * _dy);
private _near = 0;
private _bad = 0;
{
    _x params ["_pos", "_town"];
    private _t = 0;
    if (_len2 > 0) then {
        _t = ((((_pos select 0) - _ax) * _dx) + (((_pos select 1) - _ay) * _dy)) / _len2;
        _t = (_t max 0) min 1;
    };
    private _closest = [_ax + (_t * _dx), _ay + (_t * _dy), 0];
    if ((_closest distance2D _pos) <= 1500) then {
        _near = _near + 1;
        if (!(_town in _abandoned) || { (server getVariable [format ["stability%1", _town], 100]) < 50 }) then {
            _bad = _bad + 1;
        };
    };
} forEach OT_townData;

private _danger = 0;
if (_near > 0) then { _danger = 0.5 * _bad / _near };
private _pay = round ((40 + (_distKm * 12 * _crates)) * (1 + _danger));
private _time = round (60 + (_distKm * 90 * 1.5));

[_pay, _time, _danger];
