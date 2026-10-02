/*
    Description:
    Picks the map's freight brokers: one for each big town (capitals, sprawling towns and towns of 400
    people or more) and each industrial business (mines, lumberyards, power plants, factories, quarries,
    or a business that makes steel, wood, lumber or plastic) and the Factory. Fisheries have their own
    trade. Places within 400 m of each other share one.
    Each airfield (OT_airportData) also gets its own: "<Airfield> Freight Office", a civilian office
    outside the airfield's fence, 500 m to 1.4 km from its centre, that works whoever holds the airfield.
    The airfield's grounds are worked out from the map's ILS data (CfgWorlds: its runway and taxiways)
    and its hangars, terminals and towers.
    Each broker works from a white industrial shed (Land_i_Shed_Ind_F, OT_fnc_logisticsSite) put up by
    a road within 1.5 km of the place: its long side 6 m from the road, at least 200 m from any business
    and 300 m from another broker, on flat, dry, empty ground, out of every airfield's grounds and the
    occupier's restricted areas round its bases (OT_fnc_wantedLoop). The broker stands in its office;
    crates and rented vehicles appear on the road in front (the loading spot).
    Picked once per save and kept (server variable "logisticsBrokers"), like the hunting spots; picked
    again when the way they're picked changes ("logisticsBrokersVersion").

    Usage: [] call OT_fnc_logisticsBrokers; (server, scheduled)

    Returns: ARRAY - Brokers [id, name, stand position, loading spot (on the road), shed position,
        shed direction, road direction, airfield ("" for a town's or a business's broker)]
*/

private _version = 4; // 4: airfield freight offices, sheds kept off airfields and out of restricted areas
private _saved = server getVariable ["logisticsBrokers", []];
if (_saved isNotEqualTo [] && { (server getVariable ["logisticsBrokersVersion", 1]) isEqualTo _version }) exitWith { _saved };

// [position, name, airfield] of every place that gets a broker, in a fixed order so ids are stable
private _places = [];
{
    _x params ["_pos", "_town"];
    if (_town in (OT_capitals + OT_sprawling) || { (server getVariable [format ["population%1", _town], 0]) >= 400 }) then {
        _places pushBack [_pos, _town, ""];
    };
} forEach OT_townData;

private _industrial = ["Mine", "Lumber", "Power Plant", "Factory", "Quarry"]; // Not "Plant": plantations aren't industrial
private _goods = ["OT_Steel", "OT_Wood", "OT_Lumber", "OT_Plastic"];
{
    _x params ["_pos", "_name", ["_input", ""], ["_output", ""]];
    if (_name in OT_fisheries) then { continue };
    if ((_industrial findIf { _x in _name }) > -1 || { _output in _goods }) then {
        _places pushBack [_pos, _name, ""];
    };
} forEach OT_economicData;
if (!isNil "OT_factoryPos") then { _places pushBack [OT_factoryPos, "Factory", ""] };
// The airfields' freight offices last, so the towns' and businesses' brokers stay where they were
{
    _x params ["_pos", "_name"];
    _places pushBack [_pos, format ["%1 Freight Office", _name], _name];
} forEach OT_airportData;

// Businesses the sheds keep 200 m from
private _businesses = OT_economicData apply { _x select 0 };
if (!isNil "OT_factoryPos") then { _businesses pushBack OT_factoryPos };

// Ground the sheds keep out of, as circles [position, radius]
private _keepOut = [];
// The occupier's restricted areas (OT_fnc_wantedLoop): 500 m round its priority bases, 200 m round the
// others, 40 m round radio towers; 100 m to spare
{
    _x params ["_pos", "_name"];
    _keepOut pushBack [_pos, ([200, 500] select (_name in OT_NATO_priority)) + 100];
} forEach (OT_objectiveData + OT_airportData);
{ _keepOut pushBack [_x select 0, 140] } forEach OT_commsData;

// The map's runways (CfgWorlds ILS data, the main airport's and each of "SecondaryAirports"):
// [ILS position, runway axis [x, y], taxi points]
private _runways = [];
private _readIls = {
    params ["_cfg"];
    private _ils = getArray (_cfg >> "ilsPosition");
    if ((count _ils) < 2) exitWith {};
    private _dir = getArray (_cfg >> "ilsDirection"); // [x, slope, z]
    private _ax = _dir param [0, 0];
    private _ay = _dir param [2, 1];
    private _len = sqrt ((_ax ^ 2) + (_ay ^ 2));
    if (_len isEqualTo 0) then { _ax = 0; _ay = 1; _len = 1 };
    private _taxi = [];
    {
        private _xz = getArray (_cfg >> _x); // x, z pairs
        for "_i" from 0 to (count _xz) - 2 step 2 do { _taxi pushBack [_xz select _i, _xz select (_i + 1), 0] };
    } forEach ["ilsTaxiIn", "ilsTaxiOff"];
    _runways pushBack [[_ils select 0, _ils select 1, 0], [_ax / _len, _ay / _len], _taxi];
};
private _world = configFile >> "CfgWorlds" >> worldName;
[_world] call _readIls;
private _secondary = _world >> "SecondaryAirports";
for "_i" from 0 to (count _secondary) - 1 do {
    if (isClass (_secondary select _i)) then { [_secondary select _i] call _readIls };
};

// Each airfield's grounds (inside its fence): 180 m either side of its runway, 120 m round its taxiways,
// 100 m round its hangars, terminals and towers. With no runway found, 600 m round its centre
private _airfieldBuildings = (missionNamespace getVariable ["OT_airportTerminals", []]) + [
    "Land_Airport_Tower_F", "Land_Airport_01_controlTower_F", "Land_Airport_02_controlTower_F",
    "Land_Hangar_F", "Land_TentHangar_V1_F", "Land_Airport_01_hangar_F",
    "Land_Airport_02_hangar_left_F", "Land_Airport_02_hangar_right_F"
];
{
    _x params ["_center", "_name", ["_radius", 1500]];
    private _search = (_radius max 1000) min 2000;
    private _found = false;
    {
        _x params ["_ils", "_axis", "_taxi"];
        if ((_ils distance2D _center) > _search) then { continue };
        _found = true;
        // The runway runs along its ILS axis, as far as its taxi points reach (both ways)
        _axis params ["_ux", "_uy"];
        private _along = (_taxi apply { (((_x select 0) - (_ils select 0)) * _ux) + (((_x select 1) - (_ils select 1)) * _uy) }) + [0];
        private _from = selectMin _along;
        private _to = selectMax _along;
        if (_taxi isEqualTo []) then { _from = -1000; _to = 1000 };
        for "_t" from _from to _to step 50 do {
            _keepOut pushBack [[(_ils select 0) + (_t * _ux), (_ils select 1) + (_t * _uy), 0], 180];
        };
        { _keepOut pushBack [_x, 120] } forEach _taxi;
    } forEach _runways;
    {
        _keepOut pushBack [getPosATL _x, 100];
    } forEach (nearestObjects [_center, _airfieldBuildings, _search, true]);
    _keepOut pushBack [_center, [500, 600] select !_found];
} forEach OT_airportData;

// The shed's footprint in its own coordinates (from an in-game probe of Land_i_Shed_Ind_F): x -9 to
// 16.5 along, y -2.3 to 9 across; its south wall (y -2.3) faces the road
private _toWorld = {
    params ["_origin", "_dir", "_mx", "_my"];
    [
        (_origin select 0) + (_mx * cos _dir) + (_my * sin _dir),
        (_origin select 1) - (_mx * sin _dir) + (_my * cos _dir),
        0
    ]
};
private _brokers = [];
private _findSite = {
    params ["_center", ["_minDist", 0], ["_maxDist", 1500]];
    // Only the keep-out circles that reach this far
    private _avoid = _keepOut select { ((_x select 0) distance2D _center) < (_maxDist + (_x select 1) + 50) };
    private _isOut = {
        params ["_p"];
        (_avoid findIf { ((_x select 0) distance2D _p) < (_x select 1) }) isEqualTo -1
    };
    private _roads = (_center nearRoads _maxDist) select {
        private _d = _x distance2D _center;
        _d >= _minDist && { [getPosATL _x] call _isOut }
    };
    private _site = [];
    {
        private _road = _x;
        private _next = (roadsConnectedTo _road) param [0, objNull];
        if (isNull _next) then { continue };
        private _roadPos = getPosATL _road;
        private _roadDir = _roadPos getDir (getPosATL _next);
        {
            // The shed faces the road from this side: its +y away from the road
            private _dir = _roadDir + _x;
            // South wall 6 m from the road's centre, the footprint's middle (x 3.75) level with the road piece
            private _origin = [_roadPos, _dir, -3.75, 8.3] call _toWorld;
            private _corners = [[-9, -2.3], [16.5, -2.3], [-9, 9], [16.5, 9], [3.75, 3.35], [-2.6, 3.35], [10.1, 3.35]] apply { [_origin, _dir, _x select 0, _x select 1] call _toWorld };
            private _middle = _corners select 4;
            if ((_corners findIf { surfaceIsWater _x || { isOnRoad _x } }) > -1) then { continue };
            private _heights = _corners apply { getTerrainHeightASL _x };
            if (((selectMax _heights) - (selectMin _heights)) > 1.2) then { continue };
            if ((_middle distance2D _center) < _minDist || { (_middle distance2D _center) > (_maxDist - 100) }) then { continue };
            if !([_middle] call _isOut) then { continue };
            if ((_businesses findIf { (_x distance2D _middle) < 200 }) > -1) then { continue };
            if ((_brokers findIf { ((_x select 4) distance2D _middle) < 300 }) > -1) then { continue };
            if ((nearestObjects [_middle, ["House", "Building"], 18]) isNotEqualTo []) then { continue };
            _site = [_origin, _dir, _roadPos, _roadDir];
            break;
        } forEach [90, -90];
        if (_site isNotEqualTo []) then { break };
    } forEach (([_roads, [], { _x distance2D _center }, "ASCEND"] call BIS_fnc_sortBy) select [0, 400]); // The nearest 400 road pieces
    _site;
};

{
    _x params ["_pos", "_name", "_airfield"];
    // Two places this close (a business in a big town) share one broker; an airfield has its own office
    if (_airfield isEqualTo "" && { (_brokers findIf { ((_x select 4) distance2D _pos) < 400 }) > -1 }) then { continue };
    // An airfield's office: outside it, up to 1.4 km from its centre (500 m+: its keep-out circle)
    private _site = if (_airfield isEqualTo "") then { [_pos] call _findSite } else { [_pos, 300, 1500] call _findSite };
    if (_site isEqualTo []) then {
        diag_log format ["Overthrow: no site for a freight broker's shed near %1", _name];
        continue;
    };
    _site params ["_origin", "_dir", "_roadPos", "_roadDir"];
    // He stands in the office (the shed's south-west corner)
    private _stand = [_origin, _dir, -7.4, 0.3] call _toWorld;
    _brokers pushBack [format ["broker%1", count _brokers], _name, _stand, [_roadPos select 0, _roadPos select 1, 0], _origin, _dir, _roadDir, _airfield];
    sleep 0.01;
} forEach _places;

server setVariable ["logisticsBrokers", _brokers, true];
server setVariable ["logisticsBrokersVersion", _version, true];
diag_log format ["Overthrow: %1 freight brokers picked on %2 (%3 airfield freight offices)", count _brokers, worldName, { (_x select 7) isNotEqualTo "" } count _brokers];
_brokers;
