/*
    Description:
    Picks the map's drug lab sites (server, before the economy loads: labs are businesses) and makes
    them businesses (OT_fnc_drugLabsAdd). 2 + 1 per 15 km of map size (Altis 4, Tanoa 3, Malden and
    Livonia 2), spread as far apart as they can be.
    Each one is a run-down industrial shed (OT_fnc_drugLabSite) by a road, 1.3 to 1.9 km out of a town:
    at least 900 m from every town, 500 m from businesses and the Factory, 400 m from freight brokers,
    300 m from radio towers, out of the occupier's restricted areas round its bases (100 m to spare)
    and 500 m clear of every airfield; on flat, dry, empty ground. Named after the nearest town.
    Picked once per save and kept (server variable "drugLabSites"), like the freight brokers.

    Usage: [] call OT_fnc_drugLabSites; (server, scheduled)

    Returns: ARRAY - Sites [id, name, position (the shed's middle), shed position, shed direction,
        road position]
*/

if (!isServer) exitWith { [] };
call OT_fnc_drugLabsVars;

private _version = 1;
private _sites = server getVariable ["drugLabSites", []];
if (_sites isEqualTo [] || { (server getVariable ["drugLabSitesVersion", 0]) isNotEqualTo _version }) then {
    // Ground the labs keep out of, as circles [position, radius]
    private _keepOut = [];
    { _keepOut pushBack [_x select 0, 900] } forEach OT_townData;
    { _keepOut pushBack [_x select 0, 500] } forEach OT_economicData;
    if (!isNil "OT_factoryPos") then { _keepOut pushBack [OT_factoryPos, 500] };
    {
        _x params ["_pos", "_name"];
        _keepOut pushBack [_pos, ([200, 500] select (_name in (missionNamespace getVariable ["OT_NATO_priority", []]))) + 100];
    } forEach OT_objectiveData;
    { _keepOut pushBack [_x select 0, (_x param [2, 1500]) + 500] } forEach OT_airportData;
    { _keepOut pushBack [_x select 0, 300] } forEach OT_commsData;
    { _keepOut pushBack [_x select 4, 400] } forEach (server getVariable ["logisticsBrokers", []]);
    private _isOut = {
        params ["_p"];
        (_keepOut findIf { ((_x select 0) distance2D _p) < (_x select 1) }) isEqualTo -1
    };

    // The shed's footprint in its own coordinates (as the freight brokers' shed, OT_fnc_logisticsSite):
    // x -9 to 16.5 along, y -2.3 to 9 across; its south wall (y -2.3) faces the road
    private _toWorld = {
        params ["_origin", "_dir", "_mx", "_my"];
        [
            (_origin select 0) + (_mx * cos _dir) + (_my * sin _dir),
            (_origin select 1) - (_mx * sin _dir) + (_my * cos _dir),
            0
        ]
    };
    private _edge = 300;
    private _onMap = { params ["_p"]; (_p select 0) > _edge && { (_p select 1) > _edge } && { (_p select 0) < (worldSize - _edge) } && { (_p select 1) < (worldSize - _edge) } };

    // One candidate per town at most: round the town, 1.3 and 1.9 km out, by the nearest road
    private _candidates = [];
    {
        _x params ["_townPos"];
        private _found = [];
        {
            private _dist = _x;
            {
                private _p = _townPos getPos [_dist, _x];
                if (!([_p] call _onMap) || { surfaceIsWater _p } || { !([_p] call _isOut) }) then { continue };
                private _roads = [_p nearRoads 250, [_p], { _x distance2D _input0 }, "ASCEND"] call BIS_fnc_sortBy;
                {
                    private _road = _x;
                    private _next = (roadsConnectedTo _road) param [0, objNull];
                    if (isNull _next) then { continue };
                    private _roadPos = getPosATL _road;
                    private _roadDir = _roadPos getDir (getPosATL _next);
                    {
                        private _dir = _roadDir + _x;
                        private _origin = [_roadPos, _dir, -3.75, 8.3] call _toWorld;
                        private _corners = [[-9, -2.3], [16.5, -2.3], [-9, 9], [16.5, 9], [3.75, 3.35], [-2.6, 3.35], [10.1, 3.35], [21, 3.35]] apply { [_origin, _dir, _x select 0, _x select 1] call _toWorld };
                        private _middle = _corners select 4;
                        if ((_corners findIf { surfaceIsWater _x || { isOnRoad _x } }) > -1) then { continue };
                        private _heights = _corners apply { getTerrainHeightASL _x };
                        if (((selectMax _heights) - (selectMin _heights)) > 1.2) then { continue };
                        if !([_middle] call _isOut) then { continue };
                        if !([_middle] call _onMap) then { continue };
                        if ((nearestObjects [_middle, ["House", "Building"], 22]) isNotEqualTo []) then { continue };
                        if ((_candidates findIf { ((_x select 2) distance2D _middle) < 1500 }) > -1) then { continue };
                        _found = [_middle, _origin, _dir, [_roadPos select 0, _roadPos select 1, 0]];
                        break;
                    } forEach [90, -90];
                    if (_found isNotEqualTo []) then { break };
                } forEach (_roads select [0, 6]);
                if (_found isNotEqualTo []) then { break };
            } forEach [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330];
            if (_found isNotEqualTo []) then { break };
        } forEach [1300, 1900];
        if (_found isNotEqualTo []) then {
            _found params ["_middle", "_origin", "_dir", "_roadPos"];
            _candidates pushBack ["", "", _middle, _origin, _dir, _roadPos];
        };
        sleep 0.01;
    } forEach OT_townData;

    // The first one, then each time the one farthest from those picked
    private _count = 2 + floor (worldSize / 15000);
    private _picked = [];
    if (_candidates isNotEqualTo []) then { _picked pushBack (_candidates deleteAt 0) };
    while { count _picked < _count && { _candidates isNotEqualTo [] } } do {
        private _best = -1;
        private _bestDist = -1;
        {
            private _p = _x select 2;
            private _nearest = selectMin (_picked apply { (_x select 2) distance2D _p });
            if (_nearest > _bestDist) then { _bestDist = _nearest; _best = _forEachIndex };
        } forEach _candidates;
        _picked pushBack (_candidates deleteAt _best);
    };

    // Ids and names (after the nearest town, unique)
    _sites = [];
    private _names = OT_economicData apply { _x select 1 };
    {
        _x params ["", "", "_middle", "_origin", "_dir", "_roadPos"];
        private _town = _middle call OT_fnc_nearestTown;
        private _name = format ["%1 Lab", _town];
        private _n = 2;
        while { _name in _names } do { _name = format ["%1 Lab %2", _town, _n]; _n = _n + 1 };
        _names pushBack _name;
        _sites pushBack [format ["lab%1", _forEachIndex], _name, _middle, _origin, _dir, _roadPos];
    } forEach _picked;

    server setVariable ["drugLabSites", _sites, true];
    server setVariable ["drugLabSitesVersion", _version, true];
    diag_log format ["Overthrow: %1 drug lab sites picked on %2: %3", count _sites, worldName, _sites apply { [_x select 1, (_x select 2) apply { round _x }] }];
};

[_sites] call OT_fnc_drugLabsAdd;
_sites;
