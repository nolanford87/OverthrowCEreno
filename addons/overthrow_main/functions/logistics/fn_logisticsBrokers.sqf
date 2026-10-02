/*
    Description:
    Picks the map's freight brokers: one in each big town (capitals, sprawling towns and towns of 400
    people or more) and one at each industrial business (mines, lumberyards, plants, factories,
    quarries, or a business that makes steel, wood, lumber or plastic) and the Factory. Fisheries
    have their own trade. Each broker gets a loading spot: flat, empty land for a truck near the
    location, off the road, where the crates and rented vehicles appear; the broker stands by it.
    Picked once per save and kept (server variable "logisticsBrokers"), like the hunting spots.

    Usage: [] call OT_fnc_logisticsBrokers; (server, scheduled)

    Returns: ARRAY - Brokers [id, name, pos, loadingPos]
*/

private _saved = server getVariable ["logisticsBrokers", []];
if (_saved isNotEqualTo []) exitWith { _saved };

// [position, name] of every place that gets a broker, in a fixed order so ids are stable
private _places = [];
{
    _x params ["_pos", "_town"];
    if (_town in (OT_capitals + OT_sprawling) || { (server getVariable [format ["population%1", _town], 0]) >= 400 }) then {
        _places pushBack [_pos, _town];
    };
} forEach OT_townData;

private _industrial = ["Mine", "Lumber", "Power Plant", "Factory", "Plant", "Quarry"];
private _goods = ["OT_Steel", "OT_Wood", "OT_Lumber", "OT_Plastic"];
{
    _x params ["_pos", "_name", ["_input", ""], ["_output", ""]];
    if (_name in OT_fisheries) then { continue };
    if ((_industrial findIf { _x in _name }) > -1 || { _output in _goods }) then {
        _places pushBack [_pos, _name];
    };
} forEach OT_economicData;
if (!isNil "OT_factoryPos") then { _places pushBack [OT_factoryPos, "Factory"] };

// Flat, empty, dry and off the road, for a truck; tried farther out until one is found
private _findSpot = {
    params ["_center"];
    private _spot = [];
    {
        private _p = _center findEmptyPosition [_x select 0, _x select 1, "C_Truck_02_transport_F"];
        if (_p isNotEqualTo []
            && { !(surfaceIsWater _p) }
            && { !(isOnRoad _p) }
            && { (_p isFlatEmpty [-1, -1, 0.3, 6, 0, false, objNull]) isNotEqualTo [] }
        ) exitWith { _spot = [_p select 0, _p select 1, 0] };
    } forEach [[10, 80], [40, 150], [80, 250], [150, 400]];
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
diag_log format ["Overthrow: %1 freight brokers picked on %2", count _brokers, worldName];
_brokers;
