/*
    Description:
    Sells the player's sea turtles to a faction representative: $400 and +1 influence each.

    Usage: call OT_fnc_sellTurtles;
*/

private _count = { _x isEqualTo "OT_Turtle" } count (items player);
if (_count isEqualTo 0) exitWith { "You have no sea turtles" call OT_fnc_notifyMinor };
for "_i" from 1 to _count do { player removeItem "OT_Turtle" };
private _price = (cost getVariable ["OT_Turtle", [400]]) select 0;
[_price * _count] call OT_fnc_money;
_count call OT_fnc_influence;
playSound "3DEN_notificationDefault";
