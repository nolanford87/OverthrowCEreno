/*
    Description:
    A gang's bulk price for a drug, each, from the dealer's price in the gang's town
    (OT_fnc_getDrugPrice): wholesale, buying from them, at OT_drugWholesale (cheaper than a dealer);
    bulk, selling to them, at OT_drugBulkSell (less than the street pays, but always taken).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: STRING - Drug class
        _this # 2: STRING - "buy" (wholesale) or "sell" (bulk)

    Usage: private _each = [_gangid, "OT_Ganja", "buy"] call OT_fnc_gangDrugPrice;

    Returns: NUMBER - Price each, 0 if the gang is gone
*/

params ["_gangid", "_cls", ["_mode", "buy"]];

private _gang = OT_civilians getVariable [format ["gang%1", _gangid], []];
if (_gang isEqualTo []) exitWith { 0 };
private _town = _gang select 2;
if !(_town in OT_allTowns) then { _town = OT_nation };
private _dealer = [_town, _cls] call OT_fnc_getDrugPrice;
(round (_dealer * ([OT_drugBulkSell, OT_drugWholesale] select (_mode isEqualTo "buy")))) max 1
