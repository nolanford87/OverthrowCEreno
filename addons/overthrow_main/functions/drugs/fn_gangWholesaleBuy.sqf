/*
    Description:
    Buys a lot of a drug wholesale from a gang (OT_drugWholesaleLots: 10 ganja or 5 blow) at its
    wholesale price (OT_fnc_gangDrugPrice), with the player's money. Only with OT_drugGangRep or more
    rep with the gang, and room for the whole lot.

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: STRING - Drug class

    Usage: [_gangid, "OT_Ganja"] call OT_fnc_gangWholesaleBuy;

    Returns: BOOL - Bought
*/

params ["_gangid", "_cls"];

if ((player getVariable [format ["gangrep%1", _gangid], 0]) < OT_drugGangRep) exitWith {
    format ["They don't deal in bulk with you (+%1 rep with the gang needed)", OT_drugGangRep] call OT_fnc_notifyMinor;
    false
};
private _lot = OT_drugWholesaleLots getOrDefault [_cls, 0];
private _each = [_gangid, _cls, "buy"] call OT_fnc_gangDrugPrice;
if (_lot < 1 || { _each < 1 }) exitWith { false };
private _total = _lot * _each;
if ((player getVariable ["money", 0]) < _total) exitWith { "You cannot afford that" call OT_fnc_notifyMinor; false };
if !(player canAdd [_cls, _lot]) exitWith { "You don't have room for the whole lot" call OT_fnc_notifyMinor; false };

[-_total] call OT_fnc_money;
for "_i" from 1 to _lot do { player addItem _cls };
format ["Bought %1 %2 wholesale for $%3", _lot, _cls call OT_fnc_weaponGetName, [_total, 1, 0, true] call CBA_fnc_formatNumber] call OT_fnc_notifyMinor;
true
