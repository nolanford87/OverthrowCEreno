/*
    Description:
    A base's patrol helicopter / VTOL takes off and circles the base while a player is within 2 km
    of it, and flies back and lands where it was parked when no player is. Ends when the aircraft,
    its crew or the base (despawned) is gone. Spawned by OT_fnc_spawnNATOObjective.

    Parameters:
        _this # 0: GROUP - The aircraft's crew
        _this # 1: OBJECT - The aircraft
        _this # 2: ARRAY - Position of the base

    Usage: [_group, _veh, _basePos] spawn OT_fnc_NATOairPatrolBase;
*/

params ["_group", "_veh", "_basePos"];

private _home = getPosATL _veh;
private _flying = false;

while { sleep 20; alive _veh && { !isNull _group } && { (units _group) findIf { alive _x } > -1 } } do {
    private _playerNear = (allPlayers - entities "HeadlessClient_F") findIf { alive _x && { (_x distance2D _basePos) < 2000 } } > -1;
    if (_playerNear isEqualTo _flying) then { continue };
    _flying = _playerNear;

    for "_i" from (count waypoints _group) - 1 to 0 step -1 do {
        deleteWaypoint [_group, _i];
    };
    if (_flying) then {
        _veh flyInHeight 150;
        private _wp = _group addWaypoint [_basePos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterType "CIRCLE_L";
        _wp setWaypointLoiterRadius 500;
        _wp setWaypointBehaviour "AWARE";
    } else {
        private _wp = _group addWaypoint [_home, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointStatements ["true", "(vehicle this) land 'LAND'"];
    };
};
