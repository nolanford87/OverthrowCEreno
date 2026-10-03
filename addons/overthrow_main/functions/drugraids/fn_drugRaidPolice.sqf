/*
    Description:
    The gendarmerie's raiding party (OT_fnc_drugRaid, under OT_drugRaidMilitaryHeat): a commander and
    3 heavy gendarmes in a police car, spawned at the occupier base they come from. They drive to the
    road nearest the operation, get out and search and destroy there. Like the counter-attack forces
    (OT_fnc_NATOGroundForces) the group goes on the spawner's "NATOattackforce" list, and the
    survivors are cleared away once the fight is over and no player is near.

    Parameters:
        _this # 0: ARRAY - Base position they set off from
        _this # 1: ARRAY - The operation's position
        _this # 2: STRING - Its town

    Usage: [_obpos, _pos, _town] spawn OT_fnc_drugRaidPolice;

    Returns: Nothing
*/

params ["_frompos", "_attackpos", "_town"];

private _spawnpos = _frompos findEmptyPosition [10, 100, OT_NATO_Vehicle_Police];
if (_spawnpos isEqualTo []) then { _spawnpos = _frompos findEmptyPosition [0, 100, OT_NATO_Vehicle_Police] };
if (_spawnpos isEqualTo []) then { _spawnpos = +_frompos };
_spawnpos set [2, 1]; // Just off the ground, so it doesn't blow up on something

private _veh = createVehicle [OT_NATO_Vehicle_Police, [0, 0, 1000 + random 1000], [], 0, "CAN_COLLIDE"];
_veh setDir (_frompos getDir _attackpos);
_veh setPosATL _spawnpos;
_veh setVariable ["garrison", "HQ", false];
clearWeaponCargoGlobal _veh;
clearMagazineCargoGlobal _veh;
clearItemCargoGlobal _veh;
clearBackpackCargoGlobal _veh;

private _group = createGroup blufor;
_group deleteGroupWhenEmpty true;
_group addVehicle _veh;
{
    private _unit = _group createUnit [_x, _spawnpos, [], 5, "NONE"];
    [_unit, _town] call OT_fnc_initGendarm;
    _unit setVariable ["garrison", "HQ", false]; // Cleared away after the fight like the other QRF forces, not a town's garrison
    _unit setVariable ["VCOM_NOPATHING_Unit", true, false];
    _unit moveInAny _veh;
} forEach [OT_NATO_Unit_PoliceCommander_Heavy, OT_NATO_Unit_Police_Heavy, OT_NATO_Unit_Police_Heavy, OT_NATO_Unit_Police_Heavy];
{
    _x addCuratorEditableObjects [(units _group) + [_veh], true];
} forEach allCurators;
spawner setVariable ["NATOattackforce", (spawner getVariable ["NATOattackforce", []]) + [_group], false];

sleep 1;

// To the road nearest the operation, out, and through the place
private _drop = _attackpos;
private _roads = [_attackpos nearRoads 150, [_attackpos], { _x distance2D _input0 }, "ASCEND"] call BIS_fnc_sortBy;
if (_roads isNotEqualTo []) then { _drop = getPosATL (_roads select 0) };

private _wp = _group addWaypoint [_drop, 0];
_wp setWaypointType "MOVE";
_wp setWaypointBehaviour "CARELESS";
_wp setWaypointSpeed "FULL";
_wp setWaypointCompletionRadius 30;

_wp = _group addWaypoint [_drop, 0];
_wp setWaypointType "GETOUT";
_wp setWaypointBehaviour "AWARE";

_wp = _group addWaypoint [_attackpos, 0];
_wp setWaypointType "SAD";
_wp setWaypointBehaviour "COMBAT";
_wp setWaypointSpeed "FULL";

// Once the fight is over and nobody is near, the survivors and the car go
[
    { (server getVariable ["NATOattacking", ""]) isEqualTo "" && { !([_this # 1] call OT_fnc_inSpawnDistance) } },
    {
        params ["_group", "", "_veh"];
        { if (alive _x) then { [_x] call OT_fnc_cleanup } } forEach (units _group);
        if (!isNull _veh) then { [_veh] call OT_fnc_cleanup };
    },
    [_group, _attackpos, _veh],
    (120 * 60) // Timeout 2 hours
] call CBA_fnc_waitUntilAndExecute;
