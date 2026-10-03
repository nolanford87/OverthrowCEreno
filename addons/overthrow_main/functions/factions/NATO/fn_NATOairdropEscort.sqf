/*
    Description:
    The attack helicopter escorting a tank airdrop (OT_fnc_NATOdeliverHeavy) while the occupier holds an
    airfield. It sets off from the airfield nearest the drop ahead of the Blackfish: holding only that one
    airfield it takes off from the ground there, holding more it appears flying over the nearest. It
    scouts the landing zone and attacks the resistance it finds there (the drop goes ahead regardless),
    then follows the tank on its drive to the base, attacking threats near it. Once the tank has arrived,
    is destroyed or taken, it leaves (back to an airfield, off the map when the occupier holds none) and
    is removed once no player is within 2 km. Shot down, the delivery carries on alone.
    An undercover player counts as a civilian (captive): it doesn't attack them.
    The delivery talks to it through a hashmap: it sets "tank" (the dropped tank, objNull when the
    Blackfish was shot down) and "done" (the delivery is over or called off); this sets "heli".
    On the helicopter, for the QA tests: "OT_escortFor" (base name), "OT_escortStart" ("ground" / "air"),
    "OT_escortStartPos" (where it was created), "OT_escortPhase" ("scout", "escort", "leave") and
    "OT_escortAtLZ" (time it reached the landing zone).

    Parameters:
        _this # 0: STRING - Helicopter class (OT_fnc_NATOattackHelicopter)
        _this # 1: ARRAY - Drop point (the landing zone)
        _this # 2: STRING - Base name
        _this # 3: HASHMAP - The delivery's handle
        _this # 4: NUMBER - (Optional) Seconds before it sets off

    Usage: [_class, _drop, _name, _escort, _sleep] spawn OT_fnc_NATOairdropEscort;
*/

params ["_class", "_lz", "_name", "_handle", ["_sleep", 0]];

if (_sleep > 0) then { sleep _sleep };
if (_handle getOrDefault ["done", false] || { _name in (server getVariable ["NATOabandoned", []]) }) exitWith {};
private _airfields = call OT_fnc_NATOheldAirfields;
if (_airfields isEqualTo []) exitWith {}; // It lost its last airfield meanwhile: no escort
private _airfieldPos = ([_lz] call OT_fnc_NATOnearestAirfield) select 0;
private _ground = (count _airfields) isEqualTo 1;

private _heli = objNull;
if (_ground) then {
    // On the ground at its only airfield: a free helipad, otherwise a clear spot near it
    private _spot = [];
    private _dir = _airfieldPos getDir _lz;
    {
        if ((_x nearEntities [["Air", "LandVehicle"], 12]) isEqualTo [] && { !surfaceIsWater (getPosATL _x) }) exitWith {
            _spot = getPosATL _x;
            _dir = getDir _x;
        };
    } forEach (nearestObjects [_airfieldPos, ["Land_HelipadCircle_F", "Land_HelipadSquare_F", "Land_HelipadCivil_F", "Land_HelipadRescue_F"], 600]);
    if (_spot isEqualTo []) then {
        _spot = _airfieldPos findEmptyPosition [20, 300, _class];
        if (_spot isEqualTo [] || { surfaceIsWater _spot }) then { _spot = _airfieldPos };
    };
    _heli = createVehicle [_class, [_spot select 0, _spot select 1, 0], [], 0, "NONE"];
    _heli setDir _dir;
} else {
    // Already flying over the nearest one
    private _from = [_airfieldPos select 0, _airfieldPos select 1, 150];
    _heli = createVehicle [_class, _from, [], 0, "FLY"];
    _heli setPosATL _from;
    _heli setDir (_from getDir _lz);
    _heli setVelocityModelSpace [0, 50, 0];
};
_heli setVariable ["OT_escortFor", _name, true];
_heli setVariable ["OT_escortStart", ["air", "ground"] select _ground, true];
_heli setVariable ["OT_escortStartPos", getPosATL _heli, true];
_heli setVariable ["OT_escortPhase", "scout", true];
private _group = [_heli] call OT_fnc_createNATOCrew;
{ _x setVariable ["garrison", "HQ", false] } forEach (crew _heli);
{ _x addCuratorEditableObjects [[_heli], true] } forEach (allCurators);
_group setVariable ["Vcm_Disable", true, false];
_group setBehaviour "AWARE";
_group setCombatMode "RED"; // Engages whoever it finds
_heli engineOn true; // On the ground: running, it takes off with its first waypoint
_heli flyInHeight 100;
_handle set ["heli", _heli];
diag_log format ["Overthrow: a %1 escorts the airdrop to %2 (%3 start)", _class call OT_fnc_vehicleGetName, _name, ["flying", "ground"] select _ground];

// Crewed and flying (shot down or its pilot dead, it's done)
private _crewed = { alive _heli && { alive driver _heli } };
// The resistance near a place, shown to the crew to attack. An undercover player is a civilian (captive)
private _reveal = {
    params ["_centre", "_radius"];
    {
        if (alive _x && { (side _x) isEqualTo resistance }) then { _group reveal [_x, 2] };
    } forEach (_centre nearEntities [["CAManBase", "LandVehicle", "StaticWeapon"], _radius]);
};
private _clearWaypoints = {
    for "_i" from (count waypoints _group) - 1 to 0 step -1 do { deleteWaypoint [_group, _i] };
};

// Ahead of the Blackfish to the landing zone at full speed, then circles it until the tank is down
private _wp = _group addWaypoint [_lz, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "FULL";
private _circle = _group addWaypoint [_lz, 0];
_circle setWaypointType "LOITER";
_circle setWaypointLoiterRadius 300;
_circle setWaypointLoiterType "CIRCLE_L";
_circle setWaypointSpeed "NORMAL";

private _timeout = time + 1200;
waitUntil {
    sleep 3;
    if ((call _crewed) && { (_heli distance2D _lz) < 400 }) then {
        if ((_heli getVariable ["OT_escortAtLZ", -1]) < 0) then { _heli setVariable ["OT_escortAtLZ", time, true] };
        [_lz, 400] call _reveal;
    };
    !(call _crewed) || { "tank" in _handle } || { _handle getOrDefault ["done", false] } || { time > _timeout }
};
if !(call _crewed) exitWith {}; // Shot down: the delivery carries on alone

// Over the tank on its drive to the base, attacking threats near it
private _tank = _handle getOrDefault ["tank", objNull];
if (alive _tank && { !(_handle getOrDefault ["done", false]) }) then {
    _heli setVariable ["OT_escortPhase", "escort", true];
    call _clearWaypoints;
    private _centre = getPosATL _tank;
    private _over = _group addWaypoint [_centre, 0];
    _over setWaypointType "LOITER";
    _over setWaypointLoiterRadius 250;
    _over setWaypointLoiterType "CIRCLE_L";
    _over setWaypointSpeed "NORMAL";
    _group setCurrentWaypoint _over;
    _heli flyInHeight 80;
    private _escortTimeout = time + 2400;
    waitUntil {
        sleep 5;
        if (alive _tank && { call _crewed }) then {
            // Keeps up with it
            if ((_tank distance2D _centre) > 100) then {
                _centre = getPosATL _tank;
                _over setWaypointPosition [_centre, 0];
            };
            [getPosATL _tank, 500] call _reveal;
        };
        !(call _crewed) || { !alive _tank } || { _handle getOrDefault ["done", false] } || { _tank call OT_fnc_hasOwner } || { time > _escortTimeout }
    };
};
if !(call _crewed) exitWith {};

// Its job is done: back to the occupier's nearest airfield, or off the map when it holds none, and it
// goes once nobody is near
_heli setVariable ["OT_escortPhase", "leave", true];
call _clearWaypoints;
private _dest = [];
if ((call OT_fnc_NATOheldAirfields) isEqualTo []) then {
    _dest = [getPosATL _heli, true] call OT_fnc_NATOoffMapPoint;
} else {
    _dest = ([getPosATL _heli] call OT_fnc_NATOnearestAirfield) select 0;
};
_group move _dest;
_heli flyInHeight 150;
private _size = worldSize;
private _leaveTimeout = time + 600;
waitUntil {
    sleep 10;
    !alive _heli
    || { time > _leaveTimeout }
    || { ((getPosATL _heli) select 0) < 0 || { ((getPosATL _heli) select 0) > _size } || { ((getPosATL _heli) select 1) < 0 } || { ((getPosATL _heli) select 1) > _size } }
    || { (allPlayers - entities "HeadlessClient_F") findIf { alive _x && { (_x distance2D _heli) < 2000 } } isEqualTo -1 }
};
if (alive _heli) then {
    { deleteVehicle _x } forEach (crew _heli);
    deleteVehicle _heli;
    deleteGroup _group;
};
