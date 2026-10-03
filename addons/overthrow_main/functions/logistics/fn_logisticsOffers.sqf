/*
    Description:
    A freight broker's contracts: the same for everyone for 15 minutes (real time), then new ones.
    Made on the server and cached as "logisticsOffers<id>" = [window, offers] (window = serverTime
    / 900), so a client reads the cache, or asks the server and waits for it when it's out of date.
    Destinations are on land the same island can reach by road (OT_fnc_regionIsConnected): towns,
    businesses, the Factory, ports (town docks and fisheries) and the airfields' freight offices, at
    least 1.5 km away. One small job for a van (1-2 crates) somewhere near, a medium one and a big one
    farther out for a truck, and a long haul (3-6 crates) to a port or an airfield when there's one:
    one of the farther ones, 3 km or more away when it can be. Pay and time come from
    OT_fnc_logisticsPay (distance x crates x danger); a long haul pays a quarter more (handling at
    the port or airfield) and gets a quarter more time plus 2 minutes (the roads wind more over a
    long way). Then the illegal offers, when they're loaded (OT_fnc_logisticsIllegalOffers: it may
    add smuggling contracts and set add-on offers on the legal ones). An accepted contract is taken
    out of the cache (OT_fnc_logisticsClaim).

    Parameters:
        _this # 0: STRING - Broker id

    Usage: [_brokerId] call OT_fnc_logisticsOffers; (scheduled)

    Returns: ARRAY - Contracts [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit,
        danger, brokerId, kind, contraband, addon, gangId]: kind "" (legal) or "smuggle"; contraband
        "", "drugs", "weapons" or "turtles"; addon [] or a contraband add-on offer; gangId "" or the
        gang behind it. A legal contract's are "", "", [], ""
*/

params ["_brokerId"];

private _key = format ["logisticsOffers%1", _brokerId];
private _window = floor (([time, serverTime] select isMultiplayer) / 900);

if (!isServer) exitWith {
    private _cached = server getVariable [_key, []];
    if ((_cached param [0, -1]) isNotEqualTo _window) then {
        [_brokerId] remoteExec ["OT_fnc_logisticsOffers", 2];
        private _timeout = time + 10;
        waitUntil { sleep 0.2; ((server getVariable [_key, []]) param [0, -1]) isEqualTo _window || { time > _timeout } };
        _cached = server getVariable [_key, []];
    };
    _cached param [1, []];
};

// Two players asking at once: the second waits for the first's offers
private _lock = format ["OT_logisticsMaking%1", _brokerId];
waitUntil { (time - (missionNamespace getVariable [_lock, -100])) > 10 };
private _cached = server getVariable [_key, []];
if ((_cached param [0, -1]) isEqualTo _window) exitWith { _cached select 1 };

private _brokers = server getVariable ["logisticsBrokers", []];
private _index = _brokers findIf { (_x select 0) isEqualTo _brokerId };
if (_index < 0) exitWith { [] };
private _broker = _brokers select _index;
_broker params ["", "_fromName", "", "_fromPos"];
missionNamespace setVariable [_lock, time];

// Every destination: [position, name, kind]: "" a town, a business or the Factory; "docks" a town's
// pier (the land by it is found below); "port" a fishery; "airfield" an airfield's freight office
private _places = OT_townData apply { [_x select 0, _x select 1, ""] };
{
    if ((_x select 1) in (missionNamespace getVariable ["OT_drugLabs", []])) then { continue }; // Nobody ships freight to a drug lab
    _places pushBack [_x select 0, _x select 1, ["", "port"] select ((_x select 1) in OT_fisheries)];
} forEach OT_economicData;
if (!isNil "OT_factoryPos") then { _places pushBack [OT_factoryPos, "Factory", ""] };
{
    _x params ["_pos", "_town"];
    private _piers = server getVariable [format ["activepiersin%1", _town], []];
    if (_piers isNotEqualTo []) then { _places pushBack [_piers select 0, format ["%1 docks", _town], "docks"] };
} forEach OT_townData;
{
    _x params ["", "_name", "", "_loading", "", "", "", ["_airfield", ""]];
    if (_airfield isNotEqualTo "") then { _places pushBack [_loading, _name, "airfield"] };
} forEach _brokers;
_places = _places select {
    (_x select 1) isNotEqualTo _fromName
    && { ((_x select 0) distance2D _fromPos) > 1500 }
    && { [_fromPos, _x select 0] call OT_fnc_regionIsConnected }
};
_places = [_places, [], { (_x select 0) distance2D _fromPos }, "ASCEND"] call BIS_fnc_sortBy;

// Long hauls: to a port or an airfield, 3 km or more away when there are any; the farther half of them
private _long = _places select { (_x select 2) in ["docks", "port", "airfield"] };
private _longFar = _long select { ((_x select 0) distance2D _fromPos) >= 3000 };
if (_longFar isNotEqualTo []) then { _long = _longFar };
_long = _long select [floor ((count _long) / 2), count _long];

// Where the crates go: dry land by the nearest road, room for a truck. Docks: the land by the pier
private _dropAt = {
    params ["_pos", "_isDocks"];
    if (_isDocks) then {
        private _land = [];
        for "_r" from 0 to 120 step 10 do {
            for "_dir" from 0 to 330 step 30 do {
                private _p = _pos getPos [_r, _dir];
                if !(surfaceIsWater _p) exitWith { _land = _p };
            };
            if (_land isNotEqualTo []) exitWith {};
        };
        _pos = _land;
    };
    if (_pos isEqualTo []) exitWith { [] };
    private _road = [_pos, 200] call BIS_fnc_nearestRoad;
    private _base = [getPos _road, _pos] select (isNull _road);
    private _drop = _base findEmptyPosition [5, 60, "C_Truck_02_transport_F"];
    if (_drop isEqualTo [] || { surfaceIsWater _drop }) then { _drop = _base };
    if (surfaceIsWater _drop) exitWith { [] };
    [_drop select 0, _drop select 1, 0];
};

private _offers = [];
if (_places isNotEqualTo []) then {
    private _half = ceil ((count _places) / 2);
    private _near = _places select [0, _half];
    private _far = _places select [(count _places) - _half, _half];
    private _used = [];
    {
        _x params ["_pool", "_min", "_max", "_isLong"];
        if (_pool isEqualTo []) then { continue };
        // A few tries for a destination not offered yet with a drop-off on land
        for "_try" from 1 to 5 do {
            private _dest = selectRandom _pool;
            _dest params ["_destPos", "_toName", "_kind"];
            if (_toName in _used) then { continue };
            private _toPos = [_destPos, _kind isEqualTo "docks"] call _dropAt;
            if (_toPos isEqualTo []) then { continue };
            _used pushBack _toName;
            private _crates = _min + floor random (_max - _min + 1);
            private _size = ["truck", "van"] select (_crates <= 2);
            ([_fromPos, _toPos, _crates] call OT_fnc_logisticsPay) params ["_pay", "_time", "_danger"];
            if (_isLong) then {
                _pay = round (_pay * 1.25);
                _time = round ((_time * 1.25) + 120);
            };
            _offers pushBack [
                format ["haul%1_%2", _brokerId, floor random 1000000],
                _fromPos, _fromName, _toPos, _toName, _crates, _size, _pay, _time, _danger, _brokerId,
                "", "", [], "" // Legal: kind, contraband, add-on offer, gang
            ];
            break;
        };
    } forEach [[_near, 1, 2, false], [_places, 3, 5, false], [_far, 4, 8, false], [_long, 3, 6, true]];
};

// Smuggling contracts and contraband add-ons on the legal ones (gangs), when that's loaded
if (!isNil "OT_fnc_logisticsIllegalOffers") then { _offers append ([_broker, _offers] call OT_fnc_logisticsIllegalOffers) };

server setVariable [_key, [_window, _offers], true];
missionNamespace setVariable [_lock, -100];
_offers;
