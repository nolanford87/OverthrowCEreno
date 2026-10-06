/*
    Description:
    Is a position out of a compound's area by more than a margin (the area's line runs through the gates and along
    the walls: a man in a gateway or against a wall is still in). Any machine.

    Parameters:
        _this # 0: ARRAY - Position (AGL or ATL)
        _this # 1: ARRAY - The area's polygon ([[x, y, 0], ...], OT_fnc_officeCompound)
        _this # 2: NUMBER - (Optional) Margin in metres, default 2.5

    Usage: if ([getPosATL _unit, _area] call OT_fnc_officeOutside) then { ... };

    Returns: BOOL
*/

params ["_pos", "_area", ["_margin", 2.5]];

if (count _area < 3) exitWith { false };
private _p = [_pos select 0, _pos select 1, 0];
if (_p inPolygon _area) exitWith { false };
private _n = count _area;
private _near = 1e9;
for "_i" from 0 to _n - 1 do {
    private _a = _area select _i;
    private _ab = (_area select ((_i + 1) mod _n)) vectorDiff _a;
    private _l = (vectorMagnitude _ab) max 0.01;
    private _t = 0 max (_l min (((_p vectorDiff _a) vectorDotProduct _ab) / _l));
    _near = _near min ((_a vectorAdd (_ab vectorMultiply (_t / _l))) distance2D _p);
};
_near > _margin
