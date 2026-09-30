/*
    Description:
    A base's garrison vehicle patrols around the base while a player is within 2 km of it, and
    drives back to where it was parked when no player is. Ends when the vehicle, its crew or the
    base (despawned) is gone. Spawned by OT_fnc_spawnNATOObjective.

    Parameters:
        _this # 0: GROUP - The vehicle's crew
        _this # 1: OBJECT - The vehicle
        _this # 2: ARRAY - Position of the base

    Usage: [_group, _veh, _basePos] spawn OT_fnc_NATOvehiclePatrol;
*/

params ["_group", "_veh", "_basePos"];

private _home = getPosATL _veh;
private _patrolling = false;

while { sleep 30; alive _veh && { !isNull _group } && { (units _group) findIf { alive _x } > -1 } } do {
    private _playerNear = (allPlayers - entities "HeadlessClient_F") findIf { alive _x && { (_x distance2D _basePos) < 2000 } } > -1;
    if (_playerNear && !_patrolling) then {
        _patrolling = true;
        [_group, _basePos, 300] call BIS_fnc_taskPatrol;
    };
    if (!_playerNear && _patrolling) then {
        _patrolling = false;
        for "_i" from (count waypoints _group) - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };
        _group move _home;
    };
};
