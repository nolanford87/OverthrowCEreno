/*
    Description:
    A player accepts a freight contract (OT_fnc_logisticsAccept): if it's still on offer, it's taken out
    of the broker's offers so no one else can take it and the haul starts (OT_fnc_logisticsStart).
    Otherwise (someone was faster, or the offers changed) the rental fee and any cash deposit are paid
    back. Only the contract id comes from the client, the contract itself is the server's.
    Illegal work (a smuggling contract or a taken add-on) is refused, everything paid back, when the
    gang hates the player (reputation below -9) or a vehicle put up as collateral isn't theirs or is
    more than 100 m away.

    Parameters:
        _this # 0: STRING - Broker id
        _this # 1: STRING - Contract id
        _this # 2: OBJECT - Player
        _this # 3: BOOL - Rented the broker's vehicle
        _this # 4: NUMBER - Rental fee already taken ($)
        _this # 5: BOOL - Took the contract's contraband add-on (default: false)
        _this # 6: STRING - Collateral for illegal work: "cash", "vehicle", "rep" (default: "")
        _this # 7: OBJECT - Vehicle put up as collateral (default: objNull)
        _this # 8: NUMBER - Cash deposit already taken ($) (default: 0)

    Usage: [_brokerId, _contractId, player, _rental, _fee, _addon, _collateral, _collVeh, _deposit] remoteExec ["OT_fnc_logisticsClaim", 2];
*/

params ["_brokerId", "_contractId", "_player", "_rental", ["_fee", 0], ["_addon", false], ["_collateral", ""], ["_collVeh", objNull], ["_deposit", 0]];

if (!isServer || { isNull _player }) exitWith {};

private _refund = {
    params ["_text"];
    _text remoteExec ["OT_fnc_notifyMinor", _player];
    if (_fee > 0) then { [_fee, "Rental refunded"] remoteExec ["OT_fnc_money", _player] };
    if (_deposit > 0) then { [_deposit, "Deposit refunded"] remoteExec ["OT_fnc_money", _player] };
};

private _key = format ["logisticsOffers%1", _brokerId];
private _onOffer = (server getVariable [_key, []]) param [1, []];
private _contract = [];
private _found = _onOffer findIf { (_x select 0) isEqualTo _contractId };
if (_found > -1) then { _contract = _onOffer select _found };
if (_contract isEqualTo []) exitWith { ["That contract is no longer available"] call _refund };

// Illegal work: the gang has to want it, and the collateral has to be there
private _illegal = (_contract param [11, ""]) isEqualTo "smuggle" || { _addon && { (_contract param [13, []]) isNotEqualTo [] } };
if (_illegal) then {
    private _gangId = _contract param [14, ""];
    if ((_player getVariable [format ["gangrep%1", _gangId], 0]) < -9) exitWith { _illegal = "The gang won't work with you" };
    if (_collateral isEqualTo "vehicle" && {
        isNull _collVeh || { !alive _collVeh } || { (_collVeh getVariable ["owner", ""]) isNotEqualTo (getPlayerUID _player) } || { (_collVeh distance2D _player) > 100 } || { (_collVeh getVariable ["OT_collateral", ""]) isNotEqualTo "" }
    }) exitWith { _illegal = "That vehicle can't be put up as collateral" };
    if !(_collateral in ["cash", "vehicle", "rep"]) exitWith { _illegal = "No collateral was put up" };
};
if (_illegal isEqualType "") exitWith { [_illegal] call _refund };

_contract = [];
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

if (_contract isEqualTo []) exitWith { ["That contract is no longer available"] call _refund };

[_contract, _player, _rental, _addon, _collateral, _collVeh, _deposit] remoteExec ["OT_fnc_logisticsStart", 2];
