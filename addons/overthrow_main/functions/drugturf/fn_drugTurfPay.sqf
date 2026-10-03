/*
    Description:
    Books a cut paid to a gang under its turf deal (server; "drugTurfDeals", OT_fnc_drugTurfDeal): the
    cash or blow goes on the deal's totals, and the dealmaker earns 1 rep with the gang for every
    OT_drugTurfRepPerPaid of worth (OT_fnc_gangRep, when they're on; the rest carried over).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: STRING - "cash" or "blow"
        _this # 2: NUMBER - How much
        _this # 3: NUMBER - Its worth ($; blow at the town's drug price)

    Usage: [_gangId, "cash", 120, 120] call OT_fnc_drugTurfPay; (server)

    Returns: ARRAY - The deal now, [] for no deal
*/

params ["_gangId", "_what", "_amount", "_worth"];

private _deals = server getVariable ["drugTurfDeals", []];
private _i = _deals findIf { (_x select 0) isEqualTo _gangId };
if (_i < 0) exitWith { [] };
private _deal = +(_deals select _i);
_deal params ["", "_uid", "_cash", "_blow", "_bucket"];

if (_what isEqualTo "blow") then { _deal set [3, _blow + _amount] } else { _deal set [2, _cash + _amount] };
_bucket = _bucket + (_worth / OT_drugTurfRepPerPaid);
if (_bucket >= 0.9999) then {
    private _rep = floor (_bucket + 0.0001);
    _bucket = _bucket - _rep;
    private _maker = (allPlayers select { (getPlayerUID _x) isEqualTo _uid }) param [0, objNull];
    if (!isNull _maker) then { [_maker, _gangId, _rep, "their cut"] call OT_fnc_gangRep };
};
_deal set [4, _bucket];

_deals set [_i, _deal];
server setVariable ["drugTurfDeals", _deals, true];
+_deal
