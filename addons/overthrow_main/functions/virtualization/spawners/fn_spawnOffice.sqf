/*
    Description:
    A town's mayor's office while a player is near (a town spawner, OT_townSpawners): its authored layout
    (OT_fnc_officeLayout) at the town's defence tier (OT_fnc_officeTier). The fortifications always stand;
    the occupier's guards only while the office is theirs (the resistance hasn't taken it, server variable
    "officeheld<town>", nor the town), at work as the compound's garrison (OT_fnc_officeGarrison), its area
    then published for the undercover check ("compoundarea<town>"). Towns without a layout have no office.
    Server.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: STRING - Spawner id

    Usage: [_town, _spawnid] spawn OT_fnc_spawnOffice;

    Returns: Nothing
*/

if (!isServer) exitWith {};

params ["_town", "_spawnid"];

if (([_town] call OT_fnc_officeLayout) isEqualTo []) exitWith {};
// The QA layout editor showing this town puts its own tiers up (OT_officeEditing): the game's office stays out
if ((missionNamespace getVariable ["OT_officeEditing", ""]) isEqualTo _town) exitWith {};

([_town, [_town] call OT_fnc_officeTier, blufor] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];

private _groups = [];
private _areaVar = format ["compoundarea%1", _town];
if ((_town in (server getVariable ["NATOabandoned", []])) || { server getVariable [format ["officeheld%1", _town], false] }) then {
    { deleteVehicle _x } forEach _guards;
    server setVariable [_areaVar, nil, true];
} else {
    // The compound's garrison at work (OT_fnc_officeGarrison), its area a restricted one for the undercover
    // (OT_fnc_wantedLoop)
    _guards = [_town, _guards] call OT_fnc_officeGarrison;
    _groups = ((_guards apply { group _x }) arrayIntersect (_guards apply { group _x })) select { !isNull _x };
    { _x addCuratorEditableObjects [_guards, false] } forEach allCurators;
    server setVariable [_areaVar, ([_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeCompound) apply { [_x select 0, _x select 1, 0] }, true];
};

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _objects + _groups, false];
