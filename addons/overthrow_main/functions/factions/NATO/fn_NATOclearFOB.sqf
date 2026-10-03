/*
    Description:
    Clears what a FOB built: its flag, barriers, sandbags and static weapons (not ones a player has
    taken), its marker and its living soldiers on foot (tagged "OT_fob"). Dead bodies stay, pulled out
    of the statics, until the wrecks and bodies are cleaned up. Its vehicle is left alone.
    Its garrison's spawner (OT_fnc_NATOregisterFOB) goes too, it isn't spawned again.
    Used when a FOB is cleared by the resistance and when it disbands after taking its town back.

    Parameters:
        _this # 0: ARRAY - FOB position

    Usage: [_fobPos] call OT_fnc_NATOclearFOB;
*/

params ["_fobPos"];

// Its virtualized garrison: no longer spawned, the living ones spawned now are deleted below
private _spawnid = OT_fobSpawners getOrDefault [_fobPos, ""];
if (_spawnid isNotEqualTo "") then {
    OT_fobSpawners deleteAt _fobPos;
    _spawnid call OT_fnc_deregisterSpawner;
    private _index = OT_allSpawned find _spawnid;
    if (_index > -1) then { OT_allSpawned deleteAt _index };
    spawner setVariable [_spawnid, nil, false];
};

private _types = [OT_flag_NATO, OT_NATO_Barrier_Small, OT_NATO_Barrier_Large, OT_NATO_Sandbag_Curved, OT_NATO_HMG, OT_NATO_Mortar] + OT_NATO_StaticGarrison_LevelOne;
{
    private _obj = _x;
    if ((crew _obj) findIf { isPlayer _x } isEqualTo -1) then {
        {
            if (alive _x) then { deleteVehicle _x } else { moveOut _x };
        } forEach (crew _obj);
        deleteVehicle _obj;
    };
} forEach ((nearestObjects [_fobPos, _types, 60]) select { !(_x call OT_fnc_hasOwner) });

{ deleteVehicle _x } forEach (allUnits select {
    alive _x && { isNull objectParent _x } && { (_x getVariable ["OT_fob", []]) isEqualTo _fobPos }
});

deleteMarker format ["natofob%1", str _fobPos];
