/*
    Description:
    The gang whose turf a place is on: the one with the nearest camp within OT_drugTurfRadius
    (1.5 km). Any machine (the gangs are public).

    Parameters:
        _this # 0: ARRAY - Position
        _this # 1: NUMBER - (Optional) A gang id to leave out (default: none)

    Usage: ([_pos] call OT_fnc_drugTurfGang) params [["_gangId", -1], ["_gang", []]];

    Returns: ARRAY - [gang id, gang data (the 9 elements)], [] when it's on no gang's turf
*/

params ["_pos", ["_skip", -1]];

private _best = -1;
private _bestGang = [];
private _dist = OT_drugTurfRadius;
{
    {
        private _g = OT_civilians getVariable [format ["gang%1", _x], []];
        if (_x isNotEqualTo _skip && { (count _g) isEqualTo 9 } && { ((_g select 4) distance2D _pos) <= _dist }) then {
            _best = _x;
            _bestGang = _g;
            _dist = (_g select 4) distance2D _pos;
        };
    } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
} forEach OT_allTowns;

if (_best < 0) exitWith { [] };
[_best, _bestGang]
