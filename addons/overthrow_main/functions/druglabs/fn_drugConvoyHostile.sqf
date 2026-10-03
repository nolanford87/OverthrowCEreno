/*
    Description:
    A gang chemical convoy turns on its attackers (OT_fnc_drugConvoyMonitor): no longer captive, in
    combat and firing at will, and they know about players within 300 m.

    Parameters:
        _this # 0: HASHMAP - The convoy

    Usage: [_convoy] call OT_fnc_drugConvoyHostile; (server)
*/

params ["_convoy"];

if (_convoy get "hostile") exitWith {};
_convoy set ["hostile", true];
private _group = _convoy get "group";
{ if (alive _x) then { _x setCaptive false } } forEach (_convoy get "units");
_group setBehaviour "COMBAT";
_group setCombatMode "RED";
_group setSpeedMode "FULL";
private _truck = _convoy get "truck";
if (!isNull _truck) then {
    { _group reveal [_x, 2.5] } forEach (allPlayers select { (_x distance2D _truck) < 300 });
};
