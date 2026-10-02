/*
    Description:
    Picks the map's freight brokers: one for each big town (capitals, sprawling towns and towns of 400
    people or more) and each industrial business (mines, lumberyards, power plants, factories, quarries,
    or a business that makes steel, wood, lumber or plastic) and the Factory. Fisheries have their own
    trade. Places within 400 m of each other share one.
    Each broker works from a white industrial shed (Land_i_Shed_Ind_F, OT_fnc_logisticsSite) put up by
    a road within 1.5 km of the place: its long side 6 m from the road, at least 200 m from any business
    and 300 m from another broker, on flat, dry, empty ground. The broker stands in its office; crates
    and rented vehicles appear on the road in front (the loading spot).
    Picked once per save and kept (server variable "logisticsBrokers"), like the hunting spots; picked
    again when the way they're picked changes ("logisticsBrokersVersion").

    Usage: [] call OT_fnc_logisticsBrokers; (server, scheduled)

    Returns: ARRAY - Brokers [id, name, stand position, loading spot (on the road), shed position,
        shed direction, road direction]
*/

private _version = 3; // 3: brokers in sheds by a road, away from businesses
private _saved = server getVariable ["logisticsBrokers", []];
if (_saved isNotEqualTo [] && { (server getVariable ["logisticsBrokersVersion", 1]) isEqualTo _version }) exitWith { _saved };

// [position, name] of every place that gets a broker, in a fixed order so ids are stable
private _places = [];
{
    _x params ["_pos", "_town"];
    if (_town in (OT_capitals + OT_sprawling) || { (server getVariable [format ["population%1", _town], 0]) >= 400 }) then {
        _places pushBack [_pos, _town];
    };
} forEach OT_townData;

private _industrial = ["Mine", "Lumber", "Power Plant", "Factory", "Quarry"]; // Not "Plant": plantations aren't industrial
private _goods = ["OT_Steel", "OT_Wood", "OT_Lumber", "OT_Plastic"];
{
    _x params ["_pos", "_name", ["_input", ""], ["_output", ""]];
    if (_name in OT_fisheries) then { continue };
    if ((_industrial findIf { _x in _name }) > -1 || { _output in _goods }) then {
        _places pushBack [_pos, _name];
    };
} forEach OT_economicData;
if (!isNil "OT_factoryPos") then { _places pushBack [OT_factoryPos, "Factory"] };

// Businesses the sheds keep 200 m from
private _businesses = OT_economicData apply { _x select 0 };
if (!isNil "OT_factoryPos") then { _businesses pushBack OT_factoryPos };

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
    params ["_center"];
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
            if ((_businesses findIf { (_x distance2D _middle) < 200 }) > -1) then { continue };
            if ((_brokers findIf { ((_x select 4) distance2D _middle) < 300 }) > -1) then { continue };
            if ((nearestObjects [_middle, ["House", "Building"], 18]) isNotEqualTo []) then { continue };
            _site = [_origin, _dir, _roadPos, _roadDir];
            break;
        } forEach [90, -90];
        if (_site isNotEqualTo []) then { break };
    } forEach (([_center nearRoads 1500, [], { _x distance2D _center }, "ASCEND"] call BIS_fnc_sortBy) select [0, 400]); // The nearest 400 road pieces
    _site;
};

{
    _x params ["_pos", "_name"];
    // Two places this close (a business in a big town) share one broker
    if ((_brokers findIf { ((_x select 4) distance2D _pos) < 400 }) > -1) then { continue };
    private _site = [_pos] call _findSite;
    if (_site isEqualTo []) then {
        diag_log format ["Overthrow: no site for a freight broker's shed near %1", _name];
        continue;
    };
    _site params ["_origin", "_dir", "_roadPos", "_roadDir"];
    // He stands in the office (the shed's south-west corner)
    private _stand = [_origin, _dir, -7.4, 0.3] call _toWorld;
    _brokers pushBack [format ["broker%1", count _brokers], _name, _stand, [_roadPos select 0, _roadPos select 1, 0], _origin, _dir, _roadDir];
    sleep 0.01;
} forEach _places;

server setVariable ["logisticsBrokers", _brokers, true];
server setVariable ["logisticsBrokersVersion", _version, true];
diag_log format ["Overthrow: %1 freight brokers picked on %2", count _brokers, worldName];
_brokers;
