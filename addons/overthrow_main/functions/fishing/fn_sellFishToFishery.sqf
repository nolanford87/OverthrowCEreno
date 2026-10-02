/*
    Description:
    Sells the player's catch to a fishery's fisherman (talking to him, OT_fnc_talkToCiv): every fish
    on the player and in the cargo of the vehicle they're in or their own vehicles within 50 m (the
    boat tied up at the pier). He pays 10% over a general store in his town (OT_fnc_getSellPrice).
    Sea turtles aren't his trade: they stay (a faction representative buys those).

    Parameters:
        _this # 0: OBJECT - The fisherman

    Usage: [_civ] call OT_fnc_sellFishToFishery; (client)
*/

params ["_civ"];

private _town = (getPosATL _civ) call OT_fnc_nearestTown;
private _uid = getPlayerUID player;
private _vehicles = (player nearEntities [["Ship", "LandVehicle"], 50]) select { (_x call OT_fnc_getOwner) isEqualTo _uid };
if ((vehicle player) isNotEqualTo player) then { _vehicles pushBackUnique (vehicle player) };

private _total = 0;
private _sold = 0;
{
    private _cls = _x;
    private _price = round (([_town, _cls, 0] call OT_fnc_getSellPrice) * 1.1);
    private _n = { _x isEqualTo _cls } count (items player);
    for "_i" from 1 to _n do { player removeItem _cls };
    { _n = _n + ([_x, _cls, 9999] call OT_fnc_removeFromCargo) } forEach _vehicles;
    _sold = _sold + _n;
    _total = _total + (_n * _price);
} forEach OT_fishSellItems;

if (_sold isEqualTo 0) exitWith { "You have no fish to sell (on you or in your boat nearby)" call OT_fnc_notifyMinor };
[_total] call OT_fnc_money;
format ["Sold %1 fish to the fishery for $%2", _sold, [_total, 1, 0, true] call CBA_fnc_formatNumber] call OT_fnc_notifyMinor;
playSound "3DEN_notificationDefault";
