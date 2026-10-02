/*
    Description:
    Logistics, gang hijacks and losing the load (OT_fnc_logisticsHijack / OT_fnc_logisticsDeath /
    OT_fnc_logisticsTrack): a forced hijack spawns a few gang members by the cargo vehicle, the gang
    employing the player never hijacks, how a death is judged, the player killed while wanted (cargo
    seized, crates gone) or by a gang (hijacked), any other death leaving a legal job running, a
    destroyed cargo vehicle losing its load, and the settle hook (OT_fnc_logisticsSettle) getting the
    result. Deaths go through the same path the tracker uses for a real one (OT_haulDeath_<id>), no
    one is killed. Run it as the host; a gang is formed in the nearest town if there's none. Part of
    the current QA tests. The test's crates, vehicles and units are deleted afterwards.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Hijacks: in play, drive a loaded haul through a gang's turf (near its camp): now and then a warning, then a roadblock ahead or a pickup chasing you; within 150 m they open fire" call OTQA_fnc_manual;
"Hijacks: in play, kill the hijackers: 'The hijackers are dead: the haul goes on', the job keeps running" call OTQA_fnc_manual;
"Hijacks: in play, die to them: 'Freight to ... failed: <gang> killed you and hijacked the cargo'; die while wanted to anyone else: '... seized the cargo'; die otherwise on a legal job: after the respawn the job and its 'Unload delivery cargo' action are still there" call OTQA_fnc_manual;

// A contract near the host, 15 elements: [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit, danger, brokerId, kind, contraband, addon, gangId]
OTQA_hijack_contract = {
    params ["_id", "_crates", ["_gangId", -1]];
    private _from = ((getPosATL player) getPos [25, getDir player]) findEmptyPosition [0, 60, "C_Truck_02_box_F"];
    if (_from isEqualTo []) then { _from = getPosATL player };
    private _to = ((getPosATL player) getPos [120, (getDir player) + 180]) findEmptyPosition [0, 80, "C_Truck_02_box_F"];
    if (_to isEqualTo []) then { _to = (getPosATL player) getPos [60, (getDir player) + 180] };
    [_id, _from, "QA yard", _to, "QA drop-off", _crates, ["van", "truck"] select (_crates > 2), 1000, 600, 0, "qa", "", "", [], _gangId]
};

// A gang to work with: the one with the camp nearest the player, else a new one in the nearest town
OTQA_hijack_gang = {
    private _best = -1;
    private _dist = 1e9;
    {
        {
            private _g = OT_civilians getVariable [format ["gang%1", _x], []];
            if ((count _g) isEqualTo 9 && { ((_g select 4) distance2D player) < _dist }) then {
                _best = _x;
                _dist = (_g select 4) distance2D player;
            };
        } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
    } forEach OT_allTowns;
    if (_best < 0) then { _best = [(getPosATL player) call OT_fnc_nearestTown, false] call OT_fnc_formGang };
    _best
};

// A gang member to be killed by (not spawned at a camp)
OTQA_hijack_gangUnit = {
    params ["_gangId"];
    private _group = createGroup [opfor, true];
    private _unit = _group createUnit [OT_CRIM_Unit, (getPosATL player) getPos [40, random 360], [], 0, "NONE"];
    _unit setVariable ["OT_gangid", _gangId, true];
    _unit disableAI "ALL";
    _unit
};

// The settle hook: a stand-in recording its calls when there's no real one
OTQA_hijack_stubSettle = {
    OTQA_settled = [];
    if (isNil "OT_fnc_logisticsSettle") exitWith {
        OT_fnc_logisticsSettle = { OTQA_settled pushBack [_this select 0 select 0, _this select 1, _this select 2] };
        true
    };
    false
};
OTQA_hijack_checkSettle = {
    params ["_name", "_id", "_result", "_stubbed"];
    [format ["%1: the job ended '%2'", _name, _result], (missionNamespace getVariable ["OT_haulLastResult", []]) isEqualTo [_id, _result], str (missionNamespace getVariable ["OT_haulLastResult", []])] call OTQA_fnc_check;
    if (_stubbed) then {
        [format ["%1: the settle hook got [contract, uid, '%2']", _name, _result], (OTQA_settled findIf { _x isEqualTo [_id, getPlayerUID player, _result] }) > -1, str OTQA_settled] call OTQA_fnc_check;
        OT_fnc_logisticsSettle = nil;
    } else {
        format ["%1: OT_fnc_logisticsSettle exists, its call isn't recorded here (the tracker's result above is what it gets)", _name] call OTQA_fnc_manual;
    };
};

OTQA_hijack_cleanup = {
    params ["_objects"];
    {
        if (_x isEqualType grpNull) then {
            { deleteVehicle _x } forEach (units _x);
        } else {
            if (!isNull _x) then { detach _x; deleteVehicle _x };
        };
    } forEach _objects;
    player setVariable ["OT_logisticsActive", "", true];
    player setCaptive true;
};

// A job judged by a death: [killer, wanted] passed to its tracker the way it passes a real one
OTQA_hijack_deathJob = {
    params ["_name", "_killer", "_wanted", "_result"];
    private _id = format ["qa%1", round (random 100000)];
    private _contract = [_id, 2] call OTQA_hijack_contract;
    private _stubbed = call OTQA_hijack_stubSettle;
    private _money = player getVariable ["money", 0];
    ([_contract, player, true] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
    sleep 4;
    missionNamespace setVariable [format ["OT_haulDeath_%1", _id], [_killer, _wanted]];
    private _timeout = time + 12;
    waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" || { time > _timeout } };
    sleep 1.5;
    [format ["%1: task failed, no pay, job cleared", _name], ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" && { (player getVariable ["money", 0]) isEqualTo _money } && { (player getVariable ["OT_logisticsActive", ""]) isEqualTo "" },
        format ["%1, money %2 -> %3, job '%4'", [_taskId] call BIS_fnc_taskState, _money, player getVariable ["money", 0], player getVariable ["OT_logisticsActive", ""]]] call OTQA_fnc_check;
    [format ["%1: every crate is gone, out of the rental's cargo", _name], (_crates findIf { !isNull _x }) isEqualTo -1 && { ((_veh getVariable ["ace_cargo_loaded", []]) findIf { _x isEqualType objNull && { isNull _x || { _x in _crates } } }) isEqualTo -1 },
        format ["%1 of %2 crates left, rental cargo %3", { !isNull _x } count _crates, count _crates, _veh getVariable ["ace_cargo_loaded", []]]] call OTQA_fnc_check;
    [_name, _id, _result, _stubbed] call OTQA_hijack_checkSettle;
    [_crates + [_veh]] call OTQA_hijack_cleanup;
};

[
    ["Hijacks: a forced hijack spawns gang members by the cargo vehicle", {
        if (isNil "OT_fnc_logisticsHijack") exitWith { ["Hijacks: OT_fnc_logisticsHijack exists", false, "missing"] call OTQA_fnc_check };
        private _gangId = call OTQA_hijack_gang;
        if (_gangId < 0) exitWith { ["Hijacks: a gang to test with", false, "no gang and none could be formed"] call OTQA_fnc_check };
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 2] call OTQA_hijack_contract;
        ([_contract, player, true] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
        private _res = [_contract, player, _veh, true] call OT_fnc_logisticsHijack;
        _res params [["_group", grpNull], ["_car", objNull], ["_gang", -1]];
        private _units = units _group;
        ["Hijacks: 3-5 armed gang members spawned", (count _units) >= 3 && { (count _units) <= 5 } && { (_units findIf { !alive _x }) isEqualTo -1 },
            format ["%1 units: %2", count _units, _units apply { [typeOf _x, primaryWeapon _x] }]] call OTQA_fnc_check;
        ["Hijacks: within 600 m of the cargo vehicle", _units isNotEqualTo [] && { (_units findIf { (_x distance2D _veh) > 600 }) isEqualTo -1 },
            str (_units apply { round (_x distance2D _veh) })] call OTQA_fnc_check;
        ["Hijacks: they're the gang's members, tagged with the job", _gang > -1 && { (_units findIf { (_x getVariable ["OT_gangid", -2]) isNotEqualTo _gang || { (_x getVariable ["OT_hijack", ""]) isNotEqualTo _id } }) isEqualTo -1 } && { side _group isEqualTo opfor },
            format ["gang %1: %2", _gang, _units apply { [_x getVariable ["OT_gangid", -2], _x getVariable ["OT_hijack", ""]] }]] call OTQA_fnc_check;
        ["Hijacks: their pickup is there (a roadblock or a chase)", !isNull _car && { (_car distance2D _veh) < 600 }, format ["%1, %2 m", typeOf _car, if (isNull _car) then { -1 } else { round (_car distance2D _veh) }]] call OTQA_fnc_check;

        // Killed by one of them is a hijack; once the job ends they go home
        if (_units isNotEqualTo []) then {
            ["Hijacks: killed by one of them is a hijack", ([_units select 0, false] call OT_fnc_logisticsDeath) isEqualTo "hijacked", ""] call OTQA_fnc_check;
        };
        { deleteVehicle _x } forEach _crates;
        private _timeout = time + 12;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" || { time > _timeout } };
        ["Hijacks: the job's over for them once it ends", !(missionNamespace getVariable [format ["OT_haulRunning_%1", _id], false]), ""] call OTQA_fnc_check;
        [_crates + [_veh, _car, _group]] call OTQA_hijack_cleanup;
    }, 60],

    ["Hijacks: the gang employing the player never hijacks", {
        if (isNil "OT_fnc_logisticsHijack") exitWith {};
        private _gangId = call OTQA_hijack_gang;
        if (_gangId < 0) exitWith { ["Hijacks: a gang to test with", false, "no gang"] call OTQA_fnc_check };
        private _veh = createVehicle ["C_Van_01_box_F", (getPosATL player) findEmptyPosition [5, 60, "C_Van_01_box_F"], [], 0, "NONE"];
        private _id = format ["qa%1", round (random 100000)];
        private _spawned = [];

        // Employer on the contract (# 14)
        private _contract = [_id, 1, _gangId] call OTQA_hijack_contract;
        private _res = [_contract, player, _veh, true, _gangId] call OT_fnc_logisticsHijack;
        ["Hijacks: the employer named, forced: no hijack", _res isEqualTo [], str _res] call OTQA_fnc_check;
        _res = [_contract, player, _veh, true] call OT_fnc_logisticsHijack;
        if (_res isNotEqualTo []) then { _spawned append [_res select 0, _res select 1] };
        ["Hijacks: the nearest gang otherwise, never the employer", (_res param [2, -1]) isNotEqualTo _gangId, str _res] call OTQA_fnc_check;

        // Employer in the illegal job's state on the server (OT_logisticsJobs)
        private _hadJobs = !isNil "OT_logisticsJobs";
        if (!_hadJobs) then { OT_logisticsJobs = createHashMap };
        private _id2 = format ["qa%1", round (random 100000)];
        OT_logisticsJobs set [_id2, createHashMapFromArray [["gangId", _gangId]]];
        _res = [[_id2, 1] call OTQA_hijack_contract, player, _veh, true, _gangId] call OT_fnc_logisticsHijack;
        ["Hijacks: the employer from OT_logisticsJobs: no hijack", _res isEqualTo [], str _res] call OTQA_fnc_check;
        OT_logisticsJobs deleteAt _id2;
        if (!_hadJobs) then { OT_logisticsJobs = nil };

        [_spawned + [_veh]] call OTQA_hijack_cleanup;
    }, 30],

    ["Hijacks: how a death is judged", {
        if (isNil "OT_fnc_logisticsDeath") exitWith { ["Hijacks: OT_fnc_logisticsDeath exists", false, "missing"] call OTQA_fnc_check };
        private _gangId = call OTQA_hijack_gang;
        private _gangUnit = [_gangId max 0] call OTQA_hijack_gangUnit;
        private _civ = (createGroup [civilian, true]) createUnit ["C_man_1", (getPosATL player) getPos [40, random 360], [], 0, "NONE"];
        {
            _x params ["_killer", "_wanted", "_expected", "_what"];
            private _got = [_killer, _wanted] call OT_fnc_logisticsDeath;
            [format ["Hijacks: %1 -> '%2'", _what, _expected], _got isEqualTo _expected, format ["got '%1'", _got]] call OTQA_fnc_check;
        } forEach [
            [_gangUnit, false, "hijacked", "killed by a gang member"],
            [_gangUnit, true, "hijacked", "killed by a gang member while wanted"],
            [_civ, true, "seized", "killed by someone else while wanted"],
            [objNull, true, "seized", "died while wanted, no killer"],
            [_civ, false, "", "killed by someone else, not wanted"],
            [objNull, false, "", "died, no killer, not wanted"],
            [player, false, "", "killed themselves"]
        ];
        deleteVehicle _gangUnit;
        deleteVehicle _civ;
    }, 20],

    ["Hijacks: killed while wanted, the cargo is seized", {
        if (isNil "OT_fnc_logisticsDeath") exitWith {};
        ["Hijacks (seized)", objNull, true, "seized"] call OTQA_hijack_deathJob;
    }, 40],

    ["Hijacks: killed by a gang, the cargo is hijacked", {
        if (isNil "OT_fnc_logisticsDeath") exitWith {};
        private _gangId = call OTQA_hijack_gang;
        private _gangUnit = [_gangId max 0] call OTQA_hijack_gangUnit;
        ["Hijacks (hijacked)", _gangUnit, false, "hijacked"] call OTQA_hijack_deathJob;
        deleteVehicle _gangUnit;
    }, 40],

    ["Hijacks: any other death leaves a legal job running", {
        if (isNil "OT_fnc_logisticsDeath") exitWith {};
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 1] call OTQA_hijack_contract;
        private _stubbed = call OTQA_hijack_stubSettle;
        ([_contract, player, false] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
        sleep 4;
        missionNamespace setVariable [format ["OT_haulDeath_%1", _id], [objNull, false]];
        sleep 8;
        ["Hijacks: not wanted, not a gang: the job goes on", ([_taskId] call BIS_fnc_taskState) isNotEqualTo "FAILED" && { (player getVariable ["OT_logisticsActive", ""]) isEqualTo _id } && { (_crates findIf { isNull _x }) isEqualTo -1 },
            format ["%1, job '%2', crates %3", [_taskId] call BIS_fnc_taskState, player getVariable ["OT_logisticsActive", ""], _crates]] call OTQA_fnc_check;
        // Then every crate lost: "lost" to the settle hook
        { deleteVehicle _x } forEach _crates;
        private _timeout = time + 12;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" || { time > _timeout } };
        ["Hijacks (lost)", _id, "lost", _stubbed] call OTQA_hijack_checkSettle;
        [_crates] call OTQA_hijack_cleanup;
    }, 40],

    ["Hijacks: a destroyed cargo vehicle loses its load", {
        if (isNil "OT_fnc_logisticsStart") exitWith {};
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 2] call OTQA_hijack_contract;
        private _stubbed = call OTQA_hijack_stubSettle;
        ([_contract, player, true] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
        sleep 2;
        _veh setDamage 1;
        private _timeout = time + 15;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" || { time > _timeout } };
        ["Hijacks: the job failed with the vehicle", ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED", [_taskId] call BIS_fnc_taskState] call OTQA_fnc_check;
        ["Hijacks (vehicle destroyed)", _id, "lost", _stubbed] call OTQA_hijack_checkSettle;
        [_crates + [_veh]] call OTQA_hijack_cleanup;
    }, 40],

    ["Hijacks: a delivery still pays, 'delivered' to the settle hook", {
        if (isNil "OT_fnc_logisticsStart") exitWith {};
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 1] call OTQA_hijack_contract;
        private _stubbed = call OTQA_hijack_stubSettle;
        private _money = player getVariable ["money", 0];
        ([_contract, player, false] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
        { _x setPosATL ((_contract select 3) getPos [4 + _forEachIndex * 2, 90]) } forEach _crates;
        private _timeout = time + 15;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "SUCCEEDED" || { time > _timeout } };
        sleep 2;
        ["Hijacks: delivered and paid", ([_taskId] call BIS_fnc_taskState) isEqualTo "SUCCEEDED" && { ((player getVariable ["money", 0]) - _money) >= 1000 },
            format ["%1, +%2", [_taskId] call BIS_fnc_taskState, (player getVariable ["money", 0]) - _money]] call OTQA_fnc_check;
        ["Hijacks (delivered)", _id, "delivered", _stubbed] call OTQA_hijack_checkSettle;
        [_crates] call OTQA_hijack_cleanup;
    }, 40]
]
