/*
    Description:
    Picks the map's freight brokers: one in each big town (capitals, sprawling towns and towns of 400
    people or more) and one at each industrial business (mines, lumberyards, plants, factories,
    quarries, or a business that makes steel, wood, lumber or plastic) and the Factory. Fisheries
    have their own trade. Each broker gets a loading spot: flat, empty land for a truck near the
    location, off the road if possible (roadside in a built-up town), where the crates and rented
    vehicles appear; the broker stands by it.
    Picked once per save and kept (server variable "logisticsBrokers"), like the hunting spots; picked
    again when the way they're picked changes ("logisticsBrokersVersion").

    Usage: [] call OT_fnc_logisticsBrokers; (server, scheduled)

    Returns: ARRAY - Brokers [id, name, pos, loadingPos]
*/

private _version = 2; // 2: loading spots searched ring by ring, roadside as a fallback
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

// Flat, empty, dry land for a truck: points in rings 15 m apart out to 400 m, each checked for room
// for a truck. Off the road first; in a built-up town with no such spot, by the roadside
private _findSpot = {
    params ["_center"];
    private _spot = [];
    {
        private _offRoad = _x;
        for "_r" from 15 to 400 step 15 do {
            for "_dir" from 0 to 330 step 30 do {
                private _p = (_center getPos [_r, _dir]) findEmptyPosition [0, 10, "C_Truck_02_transport_F"];
                if (_p isNotEqualTo []
                    && { !(surfaceIsWater _p) }
                    && { !_offRoad || { !(isOnRoad _p) } }
                    && { (_p isFlatEmpty [-1, -1, [0.3, 0.5] select !_offRoad, 6, 0, false, objNull]) isNotEqualTo [] }
                ) exitWith { _spot = [_p select 0, _p select 1, 0] };
            };
            if (_spot isNotEqualTo []) exitWith {};
        };
        if (_spot isNotEqualTo []) exitWith {};
    } forEach [true, false];
    _spot;
};

private _brokers = [];
{
    _x params ["_pos", "_name"];
    // Two places this close (a business in a big town) share one broker
    if ((_brokers findIf { ((_x select 2) distance2D _pos) < 400 }) > -1) then { continue };
    private _loading = [_pos] call _findSpot;
    if (_loading isEqualTo []) then {
        diag_log format ["Overthrow: no loading spot for a freight broker at %1", _name];
        continue;
    };
    // The broker stands a few metres from the loading spot, so the player finds both together
    private _stand = _loading findEmptyPosition [6, 20, "C_man_1"];
    if (_stand isEqualTo [] || { surfaceIsWater _stand }) then { _stand = _loading getPos [6, 0] };
    _brokers pushBack [format ["broker%1", count _brokers], _name, [_stand select 0, _stand select 1, 0], _loading];
    sleep 0.01;
} forEach _places;

server setVariable ["logisticsBrokers", _brokers, true];
server setVariable ["logisticsBrokersVersion", _version, true];
diag_log format ["Overthrow: %1 freight brokers picked on %2", count _brokers, worldName];
_brokers;
