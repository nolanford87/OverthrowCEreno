/*
    Description:
    A town's mayor's office while a player is near (a town spawner, OT_townSpawners): its authored layout
    (OT_fnc_officeLayout) at the town's defence tier (OT_fnc_officeTier). The fortifications always stand;
    the occupier's guards only while the office is theirs (the resistance hasn't taken it, server variable
    "officeheld<town>", nor the town). Towns without a layout have no office. Server.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: STRING - Spawner id

    Usage: [_town, _spawnid] spawn OT_fnc_spawnOffice;

    Returns: Nothing
*/

if (!isServer) exitWith {};

params ["_town", "_spawnid"];

if (([_town] call OT_fnc_officeLayout) isEqualTo []) exitWith {};

([_town, [_town] call OT_fnc_officeTier, blufor] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];

private _groups = [];
if ((_town in (server getVariable ["NATOabandoned", []])) || { server getVariable [format ["officeheld%1", _town], false] }) then {
    { deleteVehicle _x } forEach _guards;
} else {
    _groups = [group (_guards param [0, objNull])] select { !isNull _x };
    { _x addCuratorEditableObjects [_guards, false] } forEach allCurators;
};

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _objects + _groups, false];
