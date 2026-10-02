/*
    Description:
    Illegal freight on a broker's board (server, from OT_fnc_logisticsOffers). Illegal work is always for
    the gang whose camp is nearest the broker; with no gang on the map there is none.
    - Half the time (each 15 minute board) a smuggling contract: 1-4 crates of contraband to a town
      1.5 km or more away by road, paying the legal rate (OT_fnc_logisticsPay) times 2.5 for drugs,
      3 for weapons and ammo, 2 for turtles and other poached goods.
    - Each legal contract has a 35% chance of a contraband add-on, taken or not when accepting it:
      1-2 more crates hidden in the load for the same drop-off, paying their legal rate times the same
      multiplier on top.
    Contracts are 15 elements: [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit,
    danger, brokerId, kind ("" legal, "smuggle"), contraband ("", "drugs", "weapons", "turtles"),
    add-on ([] or [contraband, crates, extra pay $]), gang id ("" or NUMBER)].

    Parameters:
        _this # 0: ARRAY - Broker [id, name, stand position, loading spot, ...] (or [broker], as filtered)
        _this # 1: ARRAY - The broker's legal contracts; changed in place: padded to 15 elements, some get an add-on

    Usage: _offers append ([_broker, _offers] call OT_fnc_logisticsIllegalOffers); (server)

    Returns: ARRAY - Smuggling contracts to add to the board
*/

params ["_broker", "_offers"];

if (!isServer || { _broker isEqualTo [] }) exitWith { [] };
if ((_broker select 0) isEqualType []) then { _broker = _broker select 0 };
_broker params ["_brokerId", "_fromName", "", "_fromPos"];

// Legal contracts get the illegal fields, empty
{
    private _contract = _x;
    {
        if ((count _contract) <= _x) then { _contract set [_x, ["", "", [], ""] select (_x - 11)] };
    } forEach [11, 12, 13, 14];
} forEach _offers;

// The gang behind it: the one with its camp nearest the broker
private _gangId = -1;
private _best = 1e10;
{
    {
        private _gang = OT_civilians getVariable [format ["gang%1", _x], []];
        if (_gang isNotEqualTo []) then {
            private _dist = (_gang select 4) distance2D _fromPos;
            if (_dist < _best) then {
                _best = _dist;
                _gangId = _x;
            };
        };
    } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
} forEach OT_allTowns;
if (_gangId < 0) exitWith { [] };

private _multiplier = createHashMapFromArray [["drugs", 2.5], ["weapons", 3], ["turtles", 2]];
private _kinds = keys _multiplier;

// Add-ons on some legal contracts
{
    if ((_x select 11) isEqualTo "" && { (_x select 13) isEqualTo [] } && { (random 1) < 0.35 }) then {
        private _contraband = selectRandom _kinds;
        private _crates = 1 + floor random 2;
        private _extra = round ((([_x select 1, _x select 3, _crates] call OT_fnc_logisticsPay) select 0) * (_multiplier get _contraband));
        _x set [13, [_contraband, _crates, _extra]];
        _x set [14, _gangId];
    };
} forEach _offers;

// A smuggling contract, half the time: to a town by road, dropped by its nearest road
private _smuggling = [];
if ((random 1) < 0.5) then {
    private _towns = OT_townData select {
        (_x select 1) isNotEqualTo _fromName
        && { ((_x select 0) distance2D _fromPos) > 1500 }
        && { [_fromPos, _x select 0] call OT_fnc_regionIsConnected }
    };
    for "_try" from 1 to 5 do {
        if (_towns isEqualTo []) then { break };
        private _town = _towns deleteAt (floor random (count _towns));
        _town params ["_townPos", "_toName"];
        private _road = [_townPos, 300] call BIS_fnc_nearestRoad;
        if (isNull _road) then { continue };
        private _drop = (getPos _road) findEmptyPosition [5, 60, "C_Truck_02_transport_F"];
        if (_drop isEqualTo [] || { surfaceIsWater _drop }) then { _drop = getPos _road };
        if (surfaceIsWater _drop) then { continue };
        _drop = [_drop select 0, _drop select 1, 0];

        private _contraband = selectRandom _kinds;
        private _crates = 1 + floor random 4;
        ([_fromPos, _drop, _crates] call OT_fnc_logisticsPay) params ["_pay", "_time", "_danger"];
        _smuggling pushBack [
            format ["smug%1_%2", _brokerId, floor random 1000000],
            _fromPos, _fromName, _drop, _toName, _crates, ["truck", "van"] select (_crates <= 2),
            round (_pay * (_multiplier get _contraband)), _time, _danger, _brokerId,
            "smuggle", _contraband, [], _gangId
        ];
        break;
    };
};

_smuggling;
