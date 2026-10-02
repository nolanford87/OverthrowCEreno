/*
    Description:
    A player accepts a freight contract (OT_fnc_logisticsMenu): if it's still on offer, it's taken out
    of the broker's offers so no one else can take it and the haul starts (OT_fnc_logisticsStart).
    Otherwise (someone was faster, or the offers changed) the rental fee is paid back. Only the
    contract id comes from the client, the contract itself is the server's.

    Parameters:
        _this # 0: STRING - Broker id
        _this # 1: STRING - Contract id
        _this # 2: OBJECT - Player
        _this # 3: BOOL - Rented the broker's vehicle
        _this # 4: NUMBER - Rental fee already taken ($)

    Usage: [_brokerId, _contractId, player, _rental, _fee] remoteExec ["OT_fnc_logisticsClaim", 2];
*/

params ["_brokerId", "_contractId", "_player", "_rental", ["_fee", 0]];

if (!isServer || { isNull _player }) exitWith {};

private _key = format ["logisticsOffers%1", _brokerId];
private _contract = [];
// Found and removed without a break, two claims at once can't both get it
isNil {
    private _cached = server getVariable [_key, []];
    private _offers = _cached param [1, []];
    private _idx = _offers findIf { (_x select 0) isEqualTo _contractId };
    if (_idx > -1) then {
        _contract = _offers deleteAt _idx;
        server setVariable [_key, [_cached select 0, _offers], true];
    };
};

if (_contract isEqualTo []) exitWith {
    "That contract is no longer available" remoteExec ["OT_fnc_notifyMinor", _player];
    if (_fee > 0) then { [_fee, "Rental refunded"] remoteExec ["OT_fnc_money", _player] };
};

[_contract, _player, _rental] remoteExec ["OT_fnc_logisticsStart", 2];
