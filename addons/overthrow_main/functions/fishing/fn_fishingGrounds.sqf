/*
    Description:
    Picks the map's fishing grounds: 400 m across, offshore in water at least 25 m deep, at least 400 m
    from any coast but within 2.5 km of one, about one per 4 km of coast (at least 4 km apart).
    Unmarked. Picked once per save and kept (server variable "fishingGrounds").

    Usage: [] call OT_fnc_fishingGrounds; (server, scheduled)

    Returns: ARRAY - Ground positions
*/

private _saved = server getVariable ["fishingGrounds", []];
if (_saved isNotEqualTo []) exitWith { _saved };

private _grounds = [];
private _step = 1000;
for "_x" from (_step / 2) to worldSize step _step do {
    for "_y" from (_step / 2) to worldSize step _step do {
        private _p = [_x, _y, 0];
        if !(surfaceIsWater _p) then { continue };
        if ((getTerrainHeightASL _p) > -25) then { continue }; // At least 25 m deep
        // At least 400 m from any coast: open water all around
        private _coastNear = false;
        for "_dir" from 0 to 315 step 45 do {
            if !(surfaceIsWater (_p getPos [400, _dir])) exitWith { _coastNear = true };
        };
        if (_coastNear) then { continue };
        // ...but not out at sea: land within 2.5 km
        private _landNear = false;
        {
            private _dist = _x;
            for "_dir" from 0 to 337.5 step 22.5 do {
                if !(surfaceIsWater (_p getPos [_dist, _dir])) exitWith { _landNear = true };
            };
            if (_landNear) exitWith {};
        } forEach [1000, 1750, 2500];
        if !(_landNear) then { continue };
        if ((_grounds findIf { (_x distance2D _p) < 4000 }) > -1) then { continue };
        _grounds pushBack _p;
    };
    sleep 0.01;
};

server setVariable ["fishingGrounds", _grounds, true];
diag_log format ["Overthrow: %1 fishing grounds picked on %2", count _grounds, worldName];
_grounds;
