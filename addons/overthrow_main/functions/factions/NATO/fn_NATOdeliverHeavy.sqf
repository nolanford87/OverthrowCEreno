/*
    Description:
    A tank a base just traded for (OT_fnc_NATOupgradeHeavyGarrisons) is delivered, one of two ways:
    - convoyed from the nearest place the occupier holds (HQ, factory, a base or radio tower) at least
      4 km away and reachable by land, starting on a road within 50 m of it, with 2 escort vehicles
      that protect it until it's delivered or destroyed, then leave
    - airdropped by an armed Blackfish (OT_fnc_NATOairdropVehicle) in an open field about 2 km from the
      base on its island, then drives in (always possible; shot down before the drop, it's lost)
    It's already on the base's vehicle list, destroyed on the way it comes off it (tagged "vehgarrison").
    At the base it stays and patrols when the base is spawned (a player near), otherwise it's removed
    and the base spawns it next time.

    Parameters:
        _this # 0: STRING - Tank class
        _this # 1: STRING - Base name
        _this # 2: ARRAY - Base position
        _this # 3: STRING - (Optional) "airdrop" / "convoy" to deliver it that way (the QA tests; a convoy
            only when one can reach the base)

    Usage: [_type, _name, _pos] spawn OT_fnc_NATOdeliverHeavy;
*/

params ["_type", "_name", "_basePos", ["_method", ""]];

private _tag = {
    params ["_v"];
    { _x addCuratorEditableObjects [[_v], true] } forEach (allCurators);
    private _g = [_v] call OT_fnc_createNATOCrew;
    { _x setVariable ["garrison", "HQ", false] } forEach (crew _v);
    _g setVariable ["Vcm_Disable", true, false];
    _g;
};

// Where a convoy can come from: the HQ, the factory and any base or radio tower the occupier holds, at
// least 4 km away, reachable by land and with a road within 50 m to start on
private _abandoned = server getVariable ["NATOabandoned", []];
private _sources = [];
if !(OT_NATO_HQ in _abandoned) then { _sources pushBack OT_NATO_HQPos };
if !("Factory" in (server getVariable ["GEURowned", []])) then { _sources pushBack OT_factoryPos };
{
    _x params ["_sourcePos", "_sourceName"];
    if (!(_sourceName in _abandoned) && { _sourceName isNotEqualTo _name }) then { _sources pushBack _sourcePos };
} forEach (OT_objectiveData + OT_airportData + OT_commsData);
_sources = _sources select {
    (_x distance2D _basePos) >= 4000 && { [_x, _basePos] call OT_fnc_regionIsConnected } && { (_x nearRoads 50) isNotEqualTo [] }
};
// An open field on land to airdrop it in, on the base's island (it has to drive there): about 2 km
// away, further or nearer if there's none. A few tries per distance, one can land on another island
private _field = [];
{
    _x params ["_min", "_max"];
    for "_i" from 1 to 6 do {
        private _try = [_basePos, _min, _max, 12, 0, 0.15, 0, [], [[], []]] call BIS_fnc_findSafePos;
        // Found nothing, findSafePos returns the map centre: only take a spot that is where we looked
        if (_try isNotEqualTo []
            && { !surfaceIsWater _try }
            && { (_try distance2D _basePos) >= (_min - 50) }
            && { (_try distance2D _basePos) <= (_max + 50) }
            && { [_try, _basePos] call OT_fnc_regionIsConnected }
        ) exitWith { _field = _try };
    };
    if (_field isNotEqualTo []) exitWith {};
} forEach [[1700, 2300], [1000, 3500], [500, 4000]];

private _convoy = _method isNotEqualTo "airdrop" && { _sources isNotEqualTo [] } && { _method isEqualTo "convoy" || { random 100 < 50 } };
// No field on land (small islands): convoy it if it can come by road, otherwise drop it by the base
if (_field isEqualTo [] && { _sources isNotEqualTo [] } && { _method isNotEqualTo "airdrop" }) then { _convoy = true };
if (_field isEqualTo []) then {
    _field = _basePos findEmptyPosition [30, 300, _type];
    if (_field isEqualTo [] || { surfaceIsWater _field }) then { _field = _basePos };
};

private _tank = objNull;
private _group = grpNull;
private _escorts = [];
private _from = [];

if (_convoy) then {
    _from = ([_sources, [], { _x distance2D _basePos }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    // On a road within 50 m of it
    private _road = ([_from nearRoads 50, [], { _x distance2D _from }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    private _start = getPosATL _road;
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
    [_tank, _basePos, _name, 3500, ["route", _start]] spawn OT_fnc_NATOdeliveryIntel; // Resistance intelligence may report it

    // A convoy vehicle that hasn't moved after a minute is sent on again
    [[_tank] + _escorts, _basePos] spawn {
        params ["_vehicles", "_basePos"];
        private _positions = _vehicles apply { getPosATL _x };
        sleep 60;
        {
            if (alive _x && { ((getPosATL _x) distance2D (_positions select _forEachIndex)) < 20 } && { !isNull driver _x }) then {
                (group driver _x) move _basePos;
                (driver _x) doMove _basePos;
            };
        } forEach _vehicles;
    };
    diag_log format ["Overthrow: %1 convoys a %2 to %3", OT_NATO_name, _type call OT_fnc_vehicleGetName, _name];
} else {
    // Airdropped by an armed Blackfish over the open field found above (never in the water)
    private _drop = [_field select 0, _field select 1, 0];
    diag_log format ["Overthrow: %1 airdrops a %2 near %3", OT_NATO_name, _type call OT_fnc_vehicleGetName, _name];
    private _onLaunch = {
        params ["_plane", "_args"];
        _args params ["_basePos", "_name", "_drop", "_type"];
        _plane setVariable ["OT_airdropFor", _name, true]; // The base doesn't spawn it while it's on its way
        [_plane, _basePos, _name, 3500, ["drop", _drop], _type] spawn OT_fnc_NATOdeliveryIntel; // Resistance intelligence may report it
    };
    _tank = ([_type, _drop, [_onLaunch, [_basePos, _name, _drop, _type]]] call OT_fnc_NATOairdropVehicle) select 0;
    if (isNull _tank) then {
        // Shot down with the Blackfish: it comes off the base's list
        private _list = server getVariable [format ["vehgarrison%1", _name], []];
        private _index = _list find _type;
        if (_index > -1) then { _list deleteAt _index };
        server setVariable [format ["vehgarrison%1", _name], _list, true];
    } else {
        _tank setVariable ["vehgarrison", _name, true]; // Destroyed on the way, it comes off the base's list
        _group = [_tank] call _tag;
        private _wp = _group addWaypoint [_basePos, 50];
        _wp setWaypointType "MOVE";
    };
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
_tank setVariable ["OT_delivered", true]; // An intelligence report on it has failed
for "_i" from (count waypoints _group) - 1 to 0 step -1 do { deleteWaypoint [_group, _i] };

// Nobody near the base: it's there when the base spawns
if !([_basePos] call OT_fnc_inSpawnDistance) exitWith {
    { deleteVehicle _x } forEach (crew _tank);
    deleteVehicle _tank;
    deleteGroup _group;
};
[_group, _tank, _basePos] spawn OT_fnc_NATOvehiclePatrol;
