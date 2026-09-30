/*
    Description:
    A tank a base just traded for (OT_fnc_NATOupgradeHeavyGarrisons) is delivered, one of two ways:
    - convoyed from the occupier's nearest HQ or factory (while it holds them) reachable by land,
      with 2 escort vehicles that protect it until it's delivered or destroyed, then leave
    - airdropped in an open field about 2 km from the base, then drives in (always possible)
    It's already on the base's vehicle list, destroyed on the way it comes off it (tagged "vehgarrison").
    At the base it stays and patrols when the base is spawned (a player near), otherwise it's removed
    and the base spawns it next time.

    Parameters:
        _this # 0: STRING - Tank class
        _this # 1: STRING - Base name
        _this # 2: ARRAY - Base position

    Usage: [_type, _name, _pos] spawn OT_fnc_NATOdeliverHeavy;
*/

params ["_type", "_name", "_basePos"];

private _tag = {
    params ["_v"];
    { _x addCuratorEditableObjects [[_v], true] } forEach (allCurators);
    private _g = [_v] call OT_fnc_createNATOCrew;
    { _x setVariable ["garrison", "HQ", false] } forEach (crew _v);
    _g setVariable ["Vcm_Disable", true, false];
    _g;
};

// Where a convoy can come from: the HQ and the factory while the occupier holds them, by land
private _abandoned = server getVariable ["NATOabandoned", []];
private _sources = [];
if !(OT_NATO_HQ in _abandoned) then { _sources pushBack OT_NATO_HQPos };
if !("Factory" in (server getVariable ["GEURowned", []])) then { _sources pushBack OT_factoryPos };
_sources = _sources select { (_x distance2D _basePos) > 500 && { [_x, _basePos] call OT_fnc_regionIsConnected } };
private _convoy = _sources isNotEqualTo [] && { random 100 < 50 };

private _tank = objNull;
private _group = grpNull;
private _escorts = [];
private _from = [];

if (_convoy) then {
    _from = ([_sources, [], { _x distance2D _basePos }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    private _road = [_from, 300] call BIS_fnc_nearestRoad;
    private _start = [getPosATL _road, _from] select (isNull _road);
    private _dir = _start getDir _basePos;
    private _escortTypes = OT_NATO_Vehicles_Convoy select { !(_x isKindOf "Tank") };
    if (_escortTypes isEqualTo []) then { _escortTypes = OT_NATO_Vehicles_GroundSupport };

    // Escort in front, the tank, escort behind
    {
        private _p = (_start getPos [_forEachIndex * 25, _dir + 180]) findEmptyPosition [0, 60, _x];
        if (_p isEqualTo []) then { _p = _start getPos [_forEachIndex * 25, _dir + 180] };
        private _v = createVehicle [_x, _p, [], 0, "NONE"];
        _v setDir _dir;
        private _g = [_v] call _tag;
        if (_forEachIndex isEqualTo 1) then { _tank = _v; _group = _g } else { _escorts pushBack _v; _v setVariable ["OT_escort", _name] };
        _g setBehaviour "SAFE";
        _g setSpeedMode "LIMITED";
        private _wp = _g addWaypoint [_basePos, 50];
        _wp setWaypointType "MOVE";
        sleep 0.5;
    } forEach [selectRandom _escortTypes, _type, selectRandom _escortTypes];
    _tank setVariable ["vehgarrison", _name, true]; // Destroyed on the way, it comes off the base's list
    diag_log format ["Overthrow: %1 convoys a %2 to %3", OT_NATO_name, _type call OT_fnc_vehicleGetName, _name];
} else {
    // Airdrop in an open field about 2 km away
    private _field = [_basePos, 1700, 2300, 12, 0, 0.15, 0, [], [_basePos getPos [2000, random 360], []]] call BIS_fnc_findSafePos;
    private _drop = [_field select 0, _field select 1, 300];
    private _chute = createVehicle ["B_Parachute_02_F", _drop, [], 0, "FLY"];
    _chute setPosATL _drop;
    _tank = createVehicle [_type, _drop, [], 0, "CAN_COLLIDE"];
    _tank allowDamage false;
    _tank attachTo [_chute, [0, 0, -1.3]];
    _tank setVariable ["vehgarrison", _name, true]; // Destroyed on the way, it comes off the base's list
    waitUntil { sleep 0.5; isNull _chute || { ((getPosATL _tank) select 2) < 3 } };
    detach _tank;
    if (!isNull _chute) then { deleteVehicle _chute };
    sleep 2;
    _tank allowDamage true;
    _group = [_tank] call _tag;
    private _wp = _group addWaypoint [_basePos, 50];
    _wp setWaypointType "MOVE";
    diag_log format ["Overthrow: %1 airdrops a %2 near %3", OT_NATO_name, _type call OT_fnc_vehicleGetName, _name];
};

// On its way until it arrives or is destroyed
private _timeout = time + 1800;
waitUntil { sleep 5; !alive _tank || { (_tank distance2D _basePos) < 150 } || { time > _timeout } };

// The escorts' job is done, they head back and go once nobody is near
if (_escorts isNotEqualTo []) then {
    [_escorts, _from] spawn {
        params ["_escorts", "_from"];
        {
            private _g = group driver _x;
            if (!isNull _g) then {
                for "_i" from (count waypoints _g) - 1 to 0 step -1 do { deleteWaypoint [_g, _i] };
                _g move _from;
            };
        } forEach _escorts;
        waitUntil {
            sleep 10;
            _escorts = _escorts select { !isNull _x };
            {
                private _veh = _x;
                if ((allPlayers - entities "HeadlessClient_F") findIf { alive _x && { (_x distance2D _veh) < 1500 } } isEqualTo -1) then {
                    { deleteVehicle _x } forEach (crew _veh);
                    deleteVehicle _veh;
                };
            } forEach _escorts;
            (_escorts select { !isNull _x }) isEqualTo []
        };
    };
};

if (!alive _tank) exitWith {};
for "_i" from (count waypoints _group) - 1 to 0 step -1 do { deleteWaypoint [_group, _i] };

// Nobody near the base: it's there when the base spawns
if !([_basePos] call OT_fnc_inSpawnDistance) exitWith {
    { deleteVehicle _x } forEach (crew _tank);
    deleteVehicle _tank;
    deleteGroup _group;
};
[_group, _tank, _basePos] spawn OT_fnc_NATOvehiclePatrol;
