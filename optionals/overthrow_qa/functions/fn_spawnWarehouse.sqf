/*
    Description:
    Zeus QA helper: creates a warehouse owned by the player at a position, set up like one the
    player built (owner, owned warehouses list), so warehouse and garage features can be tested
    anywhere. It is saved with the game like any built warehouse.

    Parameters:
        _this # 0: ARRAY - Position (ASL, as the Zeus context menu gives it)
        _this # 1: OBJECT - Owner

    Usage: [_position, player] remoteExecCall ["OTQA_fnc_spawnWarehouse", 2];
*/

if (!isServer) exitWith {};
params ["_posASL", "_player"];

private _pos = ASLToATL _posASL;
_pos set [2, 0];
private _warehouse = createVehicle [OT_warehouse, _pos, [], 0, "NONE"];
_warehouse setDir (getDir _player);
[_warehouse, getPlayerUID _player] call OT_fnc_setOwner;

private _owned = warehouse getVariable ["owned", []];
_owned pushBack _warehouse;
warehouse setVariable ["owned", _owned, true];

private _clutter = createVehicle ["Land_ClutterCutter_large_F", getPos _warehouse, [], 0, "CAN_COLLIDE"];
_clutter enableDynamicSimulation true;

// Every machine caches which warehouse is nearest
{ OT_warehouseLocationCache = createHashMap } remoteExecCall ["call", 0];

"Warehouse spawned, it's yours" remoteExecCall ["hint", _player];
diag_log format ["OT_QA spawned a warehouse for %1 at %2", name _player, _pos];
