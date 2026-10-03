/*
    Description:
    Sells all the player's ganja and blow to a gang in bulk: on them, and in the cargo of the vehicle
    they're in or their own vehicles within 50 m. The gang always takes it, at its bulk price
    (OT_fnc_gangDrugPrice, less than the street pays) and without the town noticing. Only with
    OT_drugGangRep or more rep with the gang.

    Parameters:
        _this # 0: NUMBER - Gang id

    Usage: [_gangid] call OT_fnc_gangBulkSell;

    Returns: NUMBER - Money paid
*/

params ["_gangid"];

if ((player getVariable [format ["gangrep%1", _gangid], 0]) < OT_drugGangRep) exitWith {
    format ["They don't deal in bulk with you (+%1 rep with the gang needed)", OT_drugGangRep] call OT_fnc_notifyMinor;
    0
};

private _uid = getPlayerUID player;
private _vehicles = (player nearEntities [["Car", "Tank", "Ship", "Air"], 50]) select { (_x call OT_fnc_getOwner) isEqualTo _uid };
if (!isNull objectParent player) then { _vehicles pushBackUnique (objectParent player) };

private _total = 0;
private _sold = [];
{
    private _cls = _x;
    private _price = [_gangid, _cls, "sell"] call OT_fnc_gangDrugPrice;
    if (_price < 1) then { continue };
    private _n = { _x isEqualTo _cls } count (items player);
    for "_i" from 1 to _n do { player removeItem _cls };
    { _n = _n + ([_x, _cls, 9999] call OT_fnc_removeFromCargo) } forEach _vehicles;
    if (_n > 0) then {
        _total = _total + (_n * _price);
        _sold pushBack format ["%1 %2", _n, _cls call OT_fnc_weaponGetName];
    };
} forEach ["OT_Ganja", "OT_Blow"];

if (_sold isEqualTo []) exitWith { "You have no drugs to sell them (on you or in your vehicles nearby)" call OT_fnc_notifyMinor; 0 };
[_total] call OT_fnc_money;
format ["Sold %1 to the gang for $%2", _sold joinString " and ", [_total, 1, 0, true] call CBA_fnc_formatNumber] call OT_fnc_notifyMinor;
playSound "3DEN_notificationDefault";
_total
