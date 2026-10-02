/*
    Description:
    Buys a hunting licence at a general store: $300, 2.5 real hours whatever the time speed (buying
    again starts a fresh 2.5 hours). The time left is a player variable ("OT_huntLicence", seconds),
    saved with the player and counted down by OT_fnc_huntingLicenceLoop.
    With it, a hunting rifle (OT_huntingWeapons) can be carried and fired outside towns without
    losing your cover (OT_fnc_isLegalHunter).

    Usage: call OT_fnc_buyHuntingLicence;
*/

private _price = 300;
if ((player getVariable ["money", 0]) < _price) exitWith {
    format ["A hunting licence costs $%1", _price] call OT_fnc_notifyMinor;
};
[-_price] call OT_fnc_money;
player setVariable ["OT_huntLicence", 9000, true];
playSound "3DEN_notificationDefault";
"Hunting licence bought: for 2.5 hours you can carry and fire a hunting rifle outside towns without blowing your cover" call OT_fnc_notifyMinor;
