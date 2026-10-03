/*
    Description:
    Removes a wild ganja zone (server): harvested out, or cleaned up by the QA tests. Its spawner
    goes (OT_fnc_NATOclearFOB does the same), its plants are deleted, its marker comes off the map.

    Parameters:
        _this # 0: NUMBER - Zone id

    Usage: [_id] call OT_fnc_ganjaRemoveZone; (server)
*/

params ["_id"];

private _spawnid = OT_ganjaSpawners getOrDefault [_id, ""];
if (_spawnid isNotEqualTo "") then {
    OT_ganjaSpawners deleteAt _id;
    _spawnid call OT_fnc_deregisterSpawner;
    private _index = OT_allSpawned find _spawnid;
    if (_index > -1) then { OT_allSpawned deleteAt _index };
    spawner setVariable [_spawnid, nil, false];
};
{ if (!isNull _x) then { deleteVehicle _x } } forEach (OT_ganjaZonePlants getOrDefault [_id, []]);
OT_ganjaZonePlants deleteAt _id;
call OT_fnc_ganjaPublishPlants;

deleteMarker format ["ganjazone%1", _id];
private _zones = (server getVariable ["ganjaZones", []]) select { (_x select 0) isNotEqualTo _id };
server setVariable ["ganjaZones", _zones, true];
