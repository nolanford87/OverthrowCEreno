/*
    Description:
    An airdrop by an armed Blackfish (whatever the occupier): it flies in at 250-325 m from the
    occupier's nearest airfield (when it holds none, from a random map edge, starting a little outside
    the map: OT_fnc_NATOoffMapPoint), releases the vehicle on a parachute 75 m below it over the drop
    point, flies on (off the map again when it came from there) and is removed once no player is within
    2 km or it's off the map.
    Shot down before the drop, nothing is dropped. Waits until the vehicle has landed.
    The Blackfish carries "OT_airdropCargo" (class) and, once dropped, "OT_deliveryCargo" (the vehicle),
    so an intelligence report on it can follow the delivery (OT_fnc_NATOdeliveryIntel). For the QA tests
    it also carries "OT_airdropOrigin" (where it started) and "OT_dropTime" (when it dropped).

    Parameters:
        _this # 0: STRING - Vehicle class to drop
        _this # 1: ARRAY - Drop point
        _this # 2: ARRAY - (Optional) [code, arguments] run with [Blackfish, arguments] when it takes off

    Usage: ([_class, _dropPos] call OT_fnc_NATOairdropVehicle) params ["_vehicle", "_blackfish"];

    Returns: ARRAY - [dropped vehicle (objNull if it was shot down), Blackfish]
*/

params ["_cargoClass", "_dropPoint", ["_onLaunch", []]];

private _planeClass = "B_T_VTOL_01_armed_F";
private _altitude = 250 + random 75;
private _airfield = [_dropPoint] call OT_fnc_NATOnearestAirfield;
private _offMap = _airfield isEqualTo [];
// From the nearest airfield, or a little outside the map on a random edge when the occupier holds none
private _origin = [];
if (_offMap) then { _origin = [_dropPoint] call OT_fnc_NATOoffMapPoint } else { _origin = _airfield select 0 };
_origin = [_origin select 0, _origin select 1, _altitude];

private _plane = createVehicle [_planeClass, _origin, [], 0, "FLY"];
// Above the sea level off the map (over the sea, above the water, not the sea bed)
_plane setPosASL [_origin select 0, _origin select 1, ((getTerrainHeightASL _origin) max 0) + _altitude];
_plane setDir (_origin getDir _dropPoint);
_plane setVelocityModelSpace [0, 80, 0];
_plane setVariable ["OT_airdropCargo", _cargoClass, true];
_plane setVariable ["OT_airdropOrigin", _origin, true];
private _planeGroup = [_plane] call OT_fnc_createNATOCrew;
{ _x setVariable ["garrison", "HQ", false] } forEach (crew _plane);
{ _x addCuratorEditableObjects [[_plane], true] } forEach (allCurators);
_planeGroup setVariable ["Vcm_Disable", true, false];
_planeGroup setBehaviour "CARELESS"; // Straight to the drop
_plane flyInHeight _altitude;
private _wp = _planeGroup addWaypoint [_dropPoint, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "NORMAL";
if (_onLaunch isNotEqualTo []) then {
    _onLaunch params ["_code", ["_arguments", []]];
    [_plane, _arguments] call _code;
};

// It flies on (out over the nearest map edge when it came from off the map) and goes once nobody is near
// or it's off the map (after the drop, or with nothing to drop)
private _leave = {
    params ["_plane", "_group", "_offMap"];
    for "_i" from (count waypoints _group) - 1 to 0 step -1 do { deleteWaypoint [_group, _i] };
    if (_offMap) then {
        _group move ([getPosATL _plane, true] call OT_fnc_NATOoffMapPoint);
    } else {
        _group move (_plane getPos [6000, getDir _plane]);
    };
    [_plane, _group] spawn {
        params ["_plane", "_group"];
        private _timeout = time + 600;
        private _size = worldSize;
        waitUntil {
            sleep 10;
            !alive _plane
            || { time > _timeout }
            || { ((getPosATL _plane) select 0) < 0 || { ((getPosATL _plane) select 0) > _size } || { ((getPosATL _plane) select 1) < 0 } || { ((getPosATL _plane) select 1) > _size } }
            || { (allPlayers - entities "HeadlessClient_F") findIf { alive _x && { (_x distance2D _plane) < 2000 } } isEqualTo -1 }
        };
        if (alive _plane) then {
            { deleteVehicle _x } forEach (crew _plane);
            deleteVehicle _plane;
            deleteGroup _group;
        };
    };
};

private _timeout = time + 900;
waitUntil { sleep 1; !alive _plane || { (_plane distance2D _dropPoint) < 120 } || { time > _timeout } };
if (!alive _plane) exitWith { [objNull, _plane] };
if (time > _timeout) exitWith { [_plane, _planeGroup, _offMap] call _leave; [objNull, _plane] };

// Release it right over the drop point (an open field), 75 m below the Blackfish
private _release = [_dropPoint select 0, _dropPoint select 1, ((getPosATL _plane) select 2) - 75];
private _chute = createVehicle ["B_Parachute_02_F", _release, [], 0, "FLY"];
_chute setPosATL _release;
private _vehicle = createVehicle [_cargoClass, _release, [], 0, "CAN_COLLIDE"];
_vehicle allowDamage false;
_vehicle attachTo [_chute, [0, 0, -1.3]];
_plane setVariable ["OT_deliveryCargo", _vehicle, true];
_plane setVariable ["OT_dropTime", time, true];
[_plane, _planeGroup, _offMap] call _leave;

// It falls under the parachute as it would (the wind may carry it). Down, or stopped coming down
// (caught on trees / a roof: the parachute, which carries it, stops falling; not checked in the
// first seconds while it opens), or taking too long. Wherever it ends up wrong (the water, sunk
// into the ground, caught above it) it's put back on the ground
private _released = time;
private _landTimeout = time + 180;
private _still = 0;
waitUntil {
    sleep 0.5;
    if (!isNull _chute && { time > _released + 10 } && { ((velocity _chute) select 2) > -0.3 }) then { _still = _still + 1 } else { _still = 0 };
    isNull _chute || { ((getPosATL _vehicle) select 2) < 3 } || { _still >= 6 } || { time > _landTimeout }
};
detach _vehicle;
_vehicle setVelocity [0, 0, 0];
if (!isNull _chute) then { deleteVehicle _chute };
sleep 3; // Settles

// Put back on the ground (the engine finds a clear spot on the surface)
private _place = {
    params ["_vehicle", "_pos", "_why"];
    _vehicle setVelocity [0, 0, 0];
    _vehicle setVehiclePosition [[_pos select 0, _pos select 1, 0], [], 10, "NONE"];
    _vehicle setVectorUp (surfaceNormal (getPosATL _vehicle));
    diag_log format ["Overthrow: airdropped %1 %2, put on the ground at %3", typeOf _vehicle, _why, getPosATL _vehicle];
};
private _at = getPosATL _vehicle;
call {
    // Came down in the water: on the drop point's field
    if (surfaceIsWater _at && { !surfaceIsWater _dropPoint }) exitWith { [_vehicle, _dropPoint, "came down in the water"] call _place };
    // Sunk into the ground
    if ((_at select 2) < -0.5 || { ((getPosASL _vehicle) select 2) < ((getTerrainHeightASL _at) - 0.5) }) exitWith { [_vehicle, _at, "sank into the ground"] call _place };
    // Resting above the ground (a roof, trees)
    if ((_at select 2) > 2) exitWith { [_vehicle, _at, "was caught above the ground"] call _place };
};
_vehicle allowDamage true;
[_vehicle, _plane];
