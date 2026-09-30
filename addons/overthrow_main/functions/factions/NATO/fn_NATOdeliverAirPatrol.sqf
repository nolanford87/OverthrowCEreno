/*
    Description:
    A patrol helicopter / VTOL a base just traded for (OT_fnc_NATOupgradeHeavyGarrisons) flies in:
    it appears high above the occupier's nearest airfield (OT_fnc_NATOnearestAirfield), descends and
    flies to the base. It's already on the base's
    air patrol list, shot down on the way it comes off it (tagged "airpatrol"). At the base it lands
    and becomes the base's patrol aircraft when the base is spawned (a player near), otherwise it's
    removed and the base spawns it parked next time.
    It sets off 8 real minutes after it's ordered (OT_fnc_NATOdeliveryWait), resistance intelligence may
    report it as soon as it's ordered (OT_fnc_NATOdeliveryIntel). The base lost meanwhile, it's called off.

    Parameters:
        _this # 0: STRING - Aircraft class
        _this # 1: STRING - Base name
        _this # 2: ARRAY - Base position
        _this # 3: ARRAY - Airfield position it comes from

    Usage: [_type, _name, _pos, _airfieldPos] spawn OT_fnc_NATOdeliverAirPatrol;
*/

params ["_type", "_name", "_basePos", "_airfieldPos"];

// Announced to the resistance if intelligence reports it, then it sets off after the wait
private _delay = missionNamespace getVariable ["OT_deliveryDelay", 480]; // Changed only by the QA tests
private _intel = [_basePos, _name, 2000, ["route", _airfieldPos], _type, _delay] call OT_fnc_NATOdeliveryIntel;
[_name, _type, "airpatrol", _delay] call OT_fnc_NATOdeliveryWait;
if (_name in (server getVariable ["NATOabandoned", []])) exitWith {
    // The base was lost meanwhile: called off, it comes off the list
    private _list = server getVariable [format ["airpatrol%1", _name], []];
    private _index = _list find _type;
    if (_index > -1) then { _list deleteAt _index };
    server setVariable [format ["airpatrol%1", _name], _list, true];
    _intel set ["cancel", true];
};

private _from = +_airfieldPos;
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
_intel set ["veh", _veh]; // An intelligence report on it follows it

private _wp = _group addWaypoint [_basePos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "NORMAL";

private _timeout = time + 600;
waitUntil { sleep 3; !alive _veh || { ((units _group) findIf { alive _x }) isEqualTo -1 } || { (_veh distance2D _basePos) < 400 } || { time > _timeout } };
if (!alive _veh) exitWith {};
_veh setVariable ["OT_delivered", true]; // An intelligence report on it has failed

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
