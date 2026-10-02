/*
    Description:
    A freight broker's 3 contracts: the same for everyone for 15 minutes (real time), then new ones.
    Made on the server and cached as "logisticsOffers<id>" = [window, offers] (window = serverTime
    / 900), so a client reads the cache, or asks the server and waits for it when it's out of date.
    Destinations are on land the same island can reach by road (OT_fnc_regionIsConnected): towns,
    businesses, the Factory and town docks, at least 1.5 km away. One small job for a van (1-2
    crates) somewhere near, a medium one and a big one farther out for a truck. An accepted contract
    is taken out of the cache (OT_fnc_logisticsClaim).

    Parameters:
        _this # 0: STRING - Broker id

    Usage: [_brokerId] call OT_fnc_logisticsOffers; (scheduled)

    Returns: ARRAY - Contracts [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit, danger, brokerId]
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

private _broker = (server getVariable ["logisticsBrokers", []]) select { (_x select 0) isEqualTo _brokerId };
if (_broker isEqualTo []) exitWith { [] };
(_broker select 0) params ["", "_fromName", "", "_fromPos"];
missionNamespace setVariable [_lock, time];

// Every destination: [position, name, is docks]
private _places = OT_townData apply { [_x select 0, _x select 1, false] };
{
    _places pushBack [_x select 0, _x select 1, false];
} forEach OT_economicData;
if (!isNil "OT_factoryPos") then { _places pushBack [OT_factoryPos, "Factory", false] };
{
    _x params ["_pos", "_town"];
    private _piers = server getVariable [format ["activepiersin%1", _town], []];
    if (_piers isNotEqualTo []) then { _places pushBack [_piers select 0, format ["%1 docks", _town], true] };
} forEach OT_townData;
_places = _places select {
    (_x select 1) isNotEqualTo _fromName
    && { ((_x select 0) distance2D _fromPos) > 1500 }
    && { [_fromPos, _x select 0] call OT_fnc_regionIsConnected }
};
_places = [_places, [], { (_x select 0) distance2D _fromPos }, "ASCEND"] call BIS_fnc_sortBy;

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
        _x params ["_pool", "_min", "_max"];
        // A few tries for a destination not offered yet with a drop-off on land
        for "_try" from 1 to 5 do {
            private _dest = selectRandom _pool;
            _dest params ["_destPos", "_toName", "_isDocks"];
            if (_toName in _used) then { continue };
            private _toPos = [_destPos, _isDocks] call _dropAt;
            if (_toPos isEqualTo []) then { continue };
            _used pushBack _toName;
            private _crates = _min + floor random (_max - _min + 1);
            private _size = ["truck", "van"] select (_crates <= 2);
            ([_fromPos, _toPos, _crates] call OT_fnc_logisticsPay) params ["_pay", "_time", "_danger"];
            _offers pushBack [
                format ["haul%1_%2", _brokerId, floor random 1000000],
                _fromPos, _fromName, _toPos, _toName, _crates, _size, _pay, _time, _danger, _brokerId
            ];
            break;
        };
    } forEach [[_near, 1, 2], [_places, 3, 5], [_far, 4, 8]];
};

server setVariable [_key, [_window, _offers], true];
missionNamespace setVariable [_lock, -100];
_offers;
