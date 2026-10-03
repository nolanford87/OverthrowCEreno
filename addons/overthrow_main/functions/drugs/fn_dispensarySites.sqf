/*
    Description:
    The map's dispensaries: 2 per map, in big or tourist towns (chosen per map, the first two
    capitals on other maps). Each is a business (OT_economicData, OT_dispensaries) at a roadside spot
    80-300 m from the town centre, beside the road and clear of buildings and other businesses.
    Worked out from terrain objects only, so it's the same on every machine and in every save.

    Usage: call OT_fnc_dispensarySites; (every machine, OT_fnc_drugsVars)
*/

OT_dispensaries = [];

private _preferred = createHashMapFromArray [
    ["Altis", ["Kavala", "Pyrgos"]],
    ["Tanoa", ["Georgetown", "Lijnhaven"]],
    ["Malden", ["La Trinite", "Le Port"]],
    ["Enoch", ["Nadbór", "Topolin"]]
];
private _allTowns = OT_townData apply { _x select 1 }; // OT_allTowns isn't set up yet
private _towns = (_preferred getOrDefault [worldName, []]) select { _x in _allTowns };
if (_towns isEqualTo []) then { _towns = OT_capitals select { _x in _allTowns } };
if (_towns isEqualTo []) then { _towns = _allTowns };
_towns = _towns select [0, 2];

{
    private _town = _x;
    private _townPos = (OT_townData select (OT_townData findIf { (_x select 1) isEqualTo _town })) select 0;
    private _site = [];
    {
        private _road = _x;
        private _rp = getPosATL _road;
        private _dist = _rp distance2D _townPos;
        if (_dist < 80) then { continue };
        if (_dist > 300) exitWith {};
        // Beside the road, either side: on land, not on a road, no building within 8 m
        private _dir = getDir _road;
        {
            private _p = _rp getPos [12, _dir + _x];
            _p = [round (_p select 0), round (_p select 1), 0];
            if (surfaceIsWater _p || { isOnRoad _p }) then { continue };
            if ((nearestTerrainObjects [_p, ["HOUSE", "BUILDING"], 8, false]) isNotEqualTo []) then { continue };
            if ((OT_economicData findIf { ((_x select 0) distance2D _p) < 150 }) > -1) then { continue };
            _site = _p;
            break;
        } forEach [90, -90];
        if (_site isNotEqualTo []) exitWith {};
    } forEach (nearestTerrainObjects [_townPos, ["ROAD", "MAIN ROAD", "TRACK"], 300, true]);
    if (_site isEqualTo []) then { continue };
    private _name = format ["%1 Dispensary", _town];
    OT_economicData pushBack [_site, _name, "OT_Ganja"];
    OT_dispensaries pushBack _name;
} forEach _towns;
