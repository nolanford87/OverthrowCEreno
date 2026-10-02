/*
    Description:
    Picks the map's hunting spots: about 400 m across, in forest and open countryside away from towns,
    bases, radio towers and the occupier HQ. One candidate per 1.5 km square of the map, the best spot
    in it by terrain (selectBestPlaces). Picked once per save and kept (server variable "huntingSpots"),
    so revealed spots stay where they are.

    Usage: [] call OT_fnc_huntingSpots; (server, scheduled)

    Returns: ARRAY - Spot positions
*/

private _saved = server getVariable ["huntingSpots", []];
if (_saved isNotEqualTo []) exitWith { _saved };

private _cell = 1500;
private _avoid = (OT_objectiveData + OT_airportData + OT_commsData) apply { _x select 0 };
_avoid pushBack OT_NATO_HQPos;
private _spots = [];
for "_x" from (_cell / 2) to worldSize step _cell do {
    for "_y" from (_cell / 2) to worldSize step _cell do {
        private _best = (selectBestPlaces [[_x, _y], 700, "(1 + forest + trees + meadow) * (1 - houses) * (1 - sea)", 50, 1]) param [0, []];
        if (_best isEqualTo []) then { continue };
        _best params ["_p", "_value"];
        _p = [_p select 0, _p select 1, 0];
        if (_value < 0.5 || { surfaceIsWater _p }) then { continue };
        // Away from towns (their spread plus 600 m), bases, towers and the HQ, and from each other
        if ([_p, 600] call OT_fnc_isInTown) then { continue };
        if ((_avoid findIf { (_x distance2D _p) < 800 }) > -1) then { continue };
        if ((_spots findIf { (_x distance2D _p) < 900 }) > -1) then { continue };
        _spots pushBack _p;
    };
    sleep 0.01;
};

server setVariable ["huntingSpots", _spots, true];
diag_log format ["Overthrow: %1 hunting spots picked on %2", count _spots, worldName];
_spots;
