/*
    Description:
    Brings a FOB its vehicle (the "Vehicle" upgrade). A bought one is delivered: it drives in from the
    nearest occupier base on the same landmass, or is parachuted in over the FOB when no base is
    reachable by land. It starts patrolling the FOB once there, and the FOB's takeover timer starts
    (OT_fnc_NATOstartFOBTimer). When a game is loaded it's already at
    the FOB. Destroyed or taken by a player on the way, the FOB loses it (OT_fnc_NATOreleaseFOBVehicle).

    Parameters:
        _this # 0: ARRAY - FOB position
        _this # 1: BOOL - Deliver it (bought now), false puts it at the FOB (game loaded)

    Usage: [_pos, true] spawn OT_fnc_NATOdeliverFOBVehicle;
*/

params ["_pos", ["_deliver", false]];

// A light armed car from the occupier's ground support (no tanks)
private _cars = OT_NATO_Vehicles_GroundSupport select { (_x isKindOf "Car") && { !(_x isKindOf "Tank") } };
private _cls = selectRandom ([_cars, OT_NATO_Vehicles_GroundSupport] select (_cars isEqualTo []));

private _setup = {
    params ["_v"];
    _v setVariable ["OT_fobVehicle", _pos];
    _v addEventHandler ["Killed", { [_this select 0] call OT_fnc_NATOreleaseFOBVehicle }];
    _v addEventHandler ["GetIn", {
        params ["_veh", "", "_unit"];
        if (isPlayer _unit) then { [_veh] call OT_fnc_NATOreleaseFOBVehicle };
    }];
    { _x addCuratorEditableObjects [[_v], true] } forEach allCurators;
};
private _crew = {
    params ["_v"];
    private _g = [_v] call OT_fnc_createNATOCrew;
    { _x setVariable ["garrison", "HQ", false] } forEach (crew _v);
    _g;
};

// Nearest occupier base it can drive from
private _from = [];
if (_deliver) then {
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _bases = (OT_objectiveData + OT_airportData) select {
        !((_x select 1) in _abandoned) && { [_x select 0, _pos] call OT_fnc_regionIsConnected }
    };
    if (_bases isNotEqualTo []) then {
        _from = (([_bases, [], { (_x select 0) distance2D _pos }, "ASCEND"] call BIS_fnc_sortBy) select 0) select 0;
    };
};

private _v = objNull;
private _g = grpNull;

call {
    // Game loaded: it's already at the FOB
    if (!_deliver) exitWith {
        private _p = _pos findEmptyPosition [12, 60, _cls];
        if (_p isEqualTo []) then { _p = _pos getPos [20, random 360] };
        _v = createVehicle [_cls, _p, [], 0, "NONE"];
        _v setDir (random 360);
        [_v] call _setup;
        _g = [_v] call _crew;
    };

    // Drives in
    if (_from isNotEqualTo []) exitWith {
        private _road = [_from, 300] call BIS_fnc_nearestRoad;
        private _start = [getPosATL _road, _from] select (isNull _road);
        _start = _start findEmptyPosition [0, 100, _cls];
        if (_start isEqualTo []) then { _start = _from };
        _v = createVehicle [_cls, _start, [], 0, "NONE"];
        _v setDir (_start getDir _pos);
        [_v] call _setup;
        [_v, _pos, format ["the FOB near %1", _pos call OT_fnc_nearestTown], 1000, ["route", _start]] spawn OT_fnc_NATOdeliveryIntel; // May be reported
        _g = [_v] call _crew;
        _g setBehaviour "SAFE";
        private _wp = _g addWaypoint [_pos, 30];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "NORMAL";
        private _timeout = time + 1200;
        waitUntil { sleep 5; !alive _v || { (_v distance2D _pos) < 60 } || { time > _timeout } };
        if (alive _v) then {
            for "_i" from (count waypoints _g) - 1 to 0 step -1 do { deleteWaypoint [_g, _i] };
        };
    };

    // Airdropped over the FOB by an armed Blackfish
    private _drop = _pos getPos [random 40, random 360];
    private _onLaunch = {
        params ["_plane", "_args"];
        _args params ["_pos", "_drop", "_cls"];
        _plane setVariable ["OT_airdropFOB", _pos, true];
        [_plane, _pos, format ["the FOB near %1", _pos call OT_fnc_nearestTown], 1000, ["drop", _drop], _cls] spawn OT_fnc_NATOdeliveryIntel; // May be reported
    };
    _v = ([_cls, _drop, [_onLaunch, [_pos, _drop, _cls]]] call OT_fnc_NATOairdropVehicle) select 0;
    if (isNull _v) exitWith {
        // Shot down with the Blackfish: the FOB has lost its vehicle (no other one), its takeover timer starts
        private _fobs = server getVariable ["NATOfobs", []];
        {
            if ((_x select 0) isEqualTo _pos) exitWith {
                private _index = (_x select 2) find "Vehicle";
                if (_index > -1) then { (_x select 2) set [_index, "VehicleLost"] };
            };
        } forEach _fobs;
        server setVariable ["NATOfobs", _fobs, true];
        [_pos] call OT_fnc_NATOstartFOBTimer;
    };
    [_v] call _setup;
    _g = [_v] call _crew;
};

if (alive _v && { !isNull _g }) then {
    [_g, _v, _pos] spawn OT_fnc_NATOvehiclePatrol;
    // Its last upgrade has arrived: the FOB's takeover timer starts, an intelligence report on it has failed
    if (_deliver) then {
        _v setVariable ["OT_delivered", true];
        [_pos] call OT_fnc_NATOstartFOBTimer;
    };
};
