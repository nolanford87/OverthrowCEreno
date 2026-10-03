/*
    Description:
    The resistance's turf deal with a gang, if there is one (any machine; the saved server variable
    "drugTurfDeals", OT_fnc_drugTurfDeal): [gang id, dealmaker's uid, cash paid, blow paid, rep
    bucket]. On the server, a deal with a gang that's gone is dropped here.

    Parameters:
        _this # 0: NUMBER - Gang id

    Usage: private _deal = [_gangId] call OT_fnc_drugTurfDealOf;

    Returns: ARRAY - The deal, [] for none
*/

params ["_gangId"];

private _deals = server getVariable ["drugTurfDeals", []];
private _i = _deals findIf { (_x select 0) isEqualTo _gangId };
if (_i < 0) exitWith { [] };
if (isServer && { (count (OT_civilians getVariable [format ["gang%1", _gangId], []])) isNotEqualTo 9 }) exitWith {
    // The gang's gone, so is the deal
    _deals deleteAt _i;
    server setVariable ["drugTurfDeals", _deals, true];
    []
};
+(_deals select _i)
