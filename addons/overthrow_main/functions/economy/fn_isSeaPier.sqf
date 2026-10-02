/*
    Description:
    Is a pier on the sea: water below sea level (at least 2 m deep) within 150 m of it. A pier on a
    lake or pond inland doesn't count (its water lies above sea level). Used for boat dealers
    (OT_fnc_findTownPiers) and fisheries (fn_initVar).

    Parameters:
        _this: ARRAY - Pier position

    Usage: _pos call OT_fnc_isSeaPier;

    Returns: BOOL
*/

private _pos = _this;
private _sea = false;
{
    private _dist = _x;
    for "_dir" from 0 to 315 step 45 do {
        private _p = _pos getPos [_dist, _dir];
        if (surfaceIsWater _p && { (getTerrainHeightASL _p) < -2 }) exitWith { _sea = true };
    };
    if (_sea) exitWith {};
} forEach [30, 75, 150];
_sea
