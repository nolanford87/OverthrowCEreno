/*
    Description:
    A patrol helicopter / VTOL a base just traded for (OT_fnc_NATOupgradeHeavyGarrisons) flies in:
    it appears 3-4 km from the base high up, descends and flies to the base. It's already on the base's
    air patrol list, shot down on the way it comes off it (tagged "airpatrol"). At the base it lands
    and becomes the base's patrol aircraft when the base is spawned (a player near), otherwise it's
    removed and the base spawns it parked next time.

    Parameters:
        _this # 0: STRING - Aircraft class
        _this # 1: STRING - Base name
        _this # 2: ARRAY - Base position

    Usage: [_type, _name, _pos] spawn OT_fnc_NATOdeliverAirPatrol;
*/

params ["_type", "_name", "_basePos"];

private _from = _basePos getPos [3000 + random 1000, random 360];
_from set [2, 500];
private _veh = createVehicle [_type, _from, [], 0, "FLY"];
_veh setPosATL _from;
_veh setDir (_from getDir _basePos);
_veh setVelocityModelSpace [0, 60, 0];
_veh setVariable ["airpatrol", _name, true]; // Shot down on the way, it comes off the base's list
private _group = [_veh] call OT_fnc_createNATOCrew;
{ _x setVariable ["garrison", "HQ", false] } forEach (crew _veh);
{ _x addCuratorEditableObjects [[_veh], true] } forEach (allCurators);
_group setVariable ["Vcm_Disable", true, false];
_group setBehaviour "AWARE";
_veh flyInHeight 150;

private _wp = _group addWaypoint [_basePos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "NORMAL";

private _timeout = time + 600;
waitUntil { sleep 3; !alive _veh || { ((units _group) findIf { alive _x }) isEqualTo -1 } || { (_veh distance2D _basePos) < 400 } || { time > _timeout } };
if (!alive _veh) exitWith {};

// Nobody near the base: it's parked there when the base spawns
if !([_basePos] call OT_fnc_inSpawnDistance) exitWith {
    { deleteVehicle _x } forEach (crew _veh);
    deleteVehicle _veh;
    deleteGroup _group;
};

// Land at the base and become its patrol aircraft
private _landing = _basePos findEmptyPosition [25, 300, _type];
if (_landing isEqualTo []) then { _landing = _basePos };
private _pad = createVehicle ["Land_HelipadEmpty_F", _landing, [], 0, "CAN_COLLIDE"];
for "_i" from (count waypoints _group) - 1 to 0 step -1 do { deleteWaypoint [_group, _i] };
_veh move _landing;
waitUntil { sleep 2; !alive _veh || { (_veh distance2D _landing) < 150 } || { time > _timeout } };
if (alive _veh) then {
    _veh land "LAND";
    waitUntil { sleep 2; !alive _veh || { isTouchingGround _veh } || { time > _timeout } };
};
if (alive _veh && { !isNull _group }) then {
    [_group, _veh, _basePos] spawn OT_fnc_NATOairPatrolBase;
};
[_pad] spawn { sleep 60; deleteVehicle (_this select 0) };
