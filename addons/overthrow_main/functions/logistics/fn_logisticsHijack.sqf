/*
    Description:
    A gang tries to hijack a freight haul (server, OT_fnc_logisticsTrack every 30 seconds while the
    player drives the loaded cargo vehicle). The gang is the one whose camp is nearest the vehicle -
    never the gang employing the player on an illegal job (contract # 14 or its OT_logisticsJobs
    entry). Chance per try: on its turf (camp within 800 m) 20%, 35% for illegal cargo, +1% per
    $1000 of pay (up to +10%); anywhere else 0.5%, 1% for illegal cargo.

    The gang: 3-4 members (one more for illegal cargo) with the gang's own gear, at a roadblock (their
    pickup across the road) about 300 m ahead along the road the player is on or heading to, or, with
    no road ahead, in a pickup chasing them from 350 m behind. The player is warned as they show up.
    Within 150 m they open fire (the player and their crew wanted, as when a gang recognizes them).
    Killing them all keeps the job going; the player dying to them hijacks the cargo
    (OT_fnc_logisticsDeath). They go home once the job is over, all of them are dead, or after 10
    minutes, and are deleted once no player is within 400 m.

    Parameters:
        _this # 0: ARRAY - Contract (see OT_fnc_logisticsStart; # 11 kind, # 12 contraband, # 14 gang id)
        _this # 1: OBJECT - The player hauling it
        _this # 2: OBJECT - Cargo vehicle
        _this # 3: BOOL - Force it: no chance roll, the nearest gang wherever it is (default: false)
        _this # 4: NUMBER - This gang (default: -1, the nearest one)

    Usage: [_contract, _player, _veh] call OT_fnc_logisticsHijack;

    Returns: ARRAY - [group, gang vehicle, gang id], [] if no hijack
*/

params ["_contract", "_player", "_veh", ["_force", false], ["_gangId", -1]];

if (!isServer || { isNull _veh } || { isNull _player }) exitWith { [] };
_contract params ["_id", "", "", "_toPos", "", "", "", "_pay"];

// A gang id as a number (-1 for none), whatever form it was stored in
private _toGangId = {
    if (_this isEqualType 0) exitWith { _this };
    if (_this isEqualType "" && { _this isNotEqualTo "" }) exitWith { parseNumber _this };
    -1
};

// Illegal cargo: an illegal kind or contraband on the contract, or an illegal job's state on the server
private _job = (missionNamespace getVariable ["OT_logisticsJobs", createHashMap]) getOrDefault [_id, []];
private _contraband = _contract param [12, false];
private _illegal = ((_contract param [11, ""]) in ["illegal", "contraband", "smuggling", "smuggle"])
    || { _contraband isEqualType true && { _contraband } }
    || { _contraband isEqualType "" && { _contraband isNotEqualTo "" } }
    || { _contraband isEqualType [] && { _contraband isNotEqualTo [] } }
    || { _job isNotEqualTo [] };

// The gang employing the player never hijacks them
private _employer = (_contract param [14, -1]) call _toGangId;
// OT_fnc_logisticsStart's entry: [kind, contraband, collateral, gangId, ...]
if (_employer < 0 && { _job isEqualType [] } && { (count _job) > 3 }) then { _employer = (_job select 3) call _toGangId };
if (_employer < 0 && { _job isEqualType createHashMap }) then {
    {
        private _g = (_job getOrDefault [_x, -1]) call _toGangId;
        if (_g > -1) exitWith { _employer = _g };
    } forEach ["gangId", "gangid", "gang"];
};
if (_gangId > -1 && { _gangId isEqualTo _employer }) exitWith { [] };

// The gang: the given one, else the one with the nearest camp
private _pos = getPosATL _veh;
private _gang = [];
private _dist = 1e9;
if (_gangId > -1) then {
    _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
    if ((count _gang) isEqualTo 9) then { _dist = (_gang select 4) distance2D _pos };
} else {
    {
        {
            private _g = OT_civilians getVariable [format ["gang%1", _x], []];
            if ((count _g) isEqualTo 9 && { _x isNotEqualTo _employer } && { ((_g select 4) distance2D _pos) < _dist }) then {
                _gang = _g;
                _gangId = _x;
                _dist = (_g select 4) distance2D _pos;
            };
        } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
    } forEach OT_allTowns;
};
if ((count _gang) isNotEqualTo 9) exitWith { [] };

if (!_force) then {
    private _chance = if (_dist < 800) then {
        ([20, 35] select _illegal) + ((_pay / 1000) min 10)
    } else {
        [0.5, 1] select _illegal
    };
    if ((random 100) >= _chance) then { _gang = [] };
};
if (_gang isEqualTo []) exitWith { [] };
_gang params ["", "", "_town", "", "_camp", "", "", "", "_name"];

// Where: a roadblock ahead on the road, or a car chasing from behind
private _heading = if ((speed _veh) > 5) then { getDir _veh } else { _veh getDir _toPos };
private _ahead = _veh getPos [300, _heading];
private _roads = [(_ahead nearRoads 150) select { (_x distance2D _veh) > 200 }, [_ahead], { _x distance2D _input0 }, "ASCEND"] call BIS_fnc_sortBy;
private _chase = _roads isEqualTo [];
private _spot = [];
if (_chase) then {
    _spot = _veh getPos [350, _heading + 180];
    private _road = [_spot nearRoads 200, [_spot], { _x distance2D _input0 }, "ASCEND"] call BIS_fnc_sortBy;
    if (_road isNotEqualTo []) then {
        _spot = getPosATL (_road select 0);
    } else {
        private _free = _spot findEmptyPosition [0, 100, "C_Offroad_01_F"];
        if (_free isNotEqualTo []) then { _spot = _free };
    };
} else {
    _spot = getPosATL (_roads select 0);
};
_spot set [2, 0];

private _car = createVehicle ["C_Offroad_01_F", _spot, [], 0, "NONE"];
_car setDir ([_heading, _heading + 90] select !_chase);
_car setVariable ["OT_hijack", _id, true];

private _group = createGroup [opfor, true];
_group setVariable ["VCM_TOUGHSQUAD", true, true];
_group setVariable ["VCM_NORESCUE", true, true];
private _size = 3 + (floor (random 2)) + ([0, 1] select _illegal);
for "_i" from 1 to _size do {
    private _unit = _group createUnit [OT_CRIM_Unit, _spot getPos [4 + random 4, random 360], [], 0, "NONE"];
    [_unit] joinSilent _group;
    [_unit, _town, [], _gangId] call OT_fnc_initCriminal;
    _unit setVariable ["OT_gangid", _gangId, true];
    _unit setVariable ["hometown", _town, true];
    _unit setVariable ["OT_hijack", _id, true];
    if (_chase) then { _unit moveInAny _car };
    { _x addCuratorEditableObjects [[_unit], false] } forEach allCurators;
};
_group setBehaviour "AWARE";
_group setCombatMode "YELLOW";
if (_chase) then {
    _group setSpeedMode "FULL";
    _group move (getPosATL _veh);
} else {
    // Behind their pickup across the road
    private _wp = _group addWaypoint [_spot, 0];
    _wp setWaypointType "HOLD";
};

([
    format ["%1 are after your cargo: a roadblock on the road ahead", _name],
    format ["%1 are after your cargo: a pickup is coming up behind you", _name]
] select _chase) remoteExec ["OT_fnc_notifyBad", _player, false];

// They open fire within 150 m, chase the player, go home when it's over; gone once nobody is near
[_id, getPlayerUID _player, _group, units _group, _car, _camp, _chase] spawn {
    params ["_id", "_uid", "_group", "_members", "_car", "_camp", "_chase"];
    private _started = time;
    private _hostile = false;
    while { true } do {
        sleep 2;
        private _alive = _members select { alive _x };
        private _target = (allPlayers select { (getPlayerUID _x) isEqualTo _uid && { alive _x } }) param [0, objNull];
        if (_alive isEqualTo []) exitWith {
            if (_hostile && { !isNull _target } && { missionNamespace getVariable [format ["OT_haulRunning_%1", _id], false] }) then {
                "The hijackers are dead: the haul goes on" remoteExec ["OT_fnc_notifyGood", _target, false];
            };
        };
        if (!(missionNamespace getVariable [format ["OT_haulRunning_%1", _id], false]) || { (time - _started) > 600 }) exitWith {};
        if (!isNull _target) then {
            private _veh = vehicle _target;
            if ((_alive findIf { (_x distance _target) < 150 }) > -1) then {
                // Wanted to them (and to anyone else who sees it), as when a gang recognizes you
                if (captive _target) then {
                    { [_x, false] remoteExec ["setCaptive", _x] } forEach ([_target] + ((crew _veh) - [_target]));
                };
                _group reveal [_veh, 4];
                if (!_hostile) then {
                    _hostile = true;
                    _group setBehaviour "COMBAT";
                    _group setCombatMode "RED";
                    "The gang opens fire: they want your cargo" remoteExec ["OT_fnc_notifyBad", _target, false];
                };
            };
            if (_chase || _hostile) then { _group move (getPosATL _veh) };
        };
    };

    // Home: back to their camp, deleted once no player is within 400 m
    _group setBehaviour "SAFE";
    _group move _camp;
    waitUntil {
        sleep 10;
        private _objects = _members + [_car];
        (_objects findIf { private _o = _x; !isNull _o && { (allPlayers findIf { (_x distance2D _o) < 400 }) > -1 } }) isEqualTo -1
    };
    // The dead too (they leave the group)
    { if (!isNull _x) then { deleteVehicle _x } } forEach _members;
    // Their pickup too, unless a player took it
    if (!isNull _car && { ((crew _car) findIf { isPlayer _x }) isEqualTo -1 } && { !(_car call OT_fnc_hasOwner) }) then { deleteVehicle _car };
    sleep 1;
    deleteGroup _group;
};

[_group, _car, _gangId]
