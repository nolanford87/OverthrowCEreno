/*
    Description:
    Recovery service: a player pays to have one of their vehicles taken into the garage from wherever
    it is (the owned warehouse or resistance base nearest the vehicle), in its current condition.
    Price from OT_fnc_garageRecoverPrice. Only for the player's own vehicles.

    Parameters:
        _this # 0: OBJECT - Vehicle
        _this # 1: OBJECT - Player

    Usage: [_veh, player] remoteExecCall ["OT_fnc_garageRecover", 2];
*/

if (!isServer) exitWith {};
params ["_veh", "_player"];

private _hint = { _this remoteExecCall ["hint", _player] };
if (isNull _veh || { !alive _veh }) exitWith { "That vehicle is gone" call _hint };
private _owner = _veh call OT_fnc_getOwner;
if (isNil "_owner" || { _owner isNotEqualTo getPlayerUID _player }) exitWith { "You can only recover your own vehicles" call _hint };

(_veh call OT_fnc_garageRecoverPrice) params ["_price", "_garage", "_town"];
if (_price < 0) exitWith { "You need an owned warehouse or a resistance base to recover vehicles to" call _hint };
if ((_player getVariable ["money", 0]) < _price) exitWith { format ["Recovering it costs $%1, you don't have enough", [_price, 1, 0, true] call CBA_fnc_formatNumber] call _hint };

private _name = (typeOf _veh) call OT_fnc_vehicleGetName;
if !([_veh, _player, _garage] call OT_fnc_garageStore) exitWith {};

[-_price] remoteExec ["OT_fnc_money", _player];
format ["Your %1 was recovered to the garage (%2) for $%3", _name, _garage call OT_fnc_nearestTown, [_price, 1, 0, true] call CBA_fnc_formatNumber] remoteExecCall ["OT_fnc_notifyMinor", _player];
