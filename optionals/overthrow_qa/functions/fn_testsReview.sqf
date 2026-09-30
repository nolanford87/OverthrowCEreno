/*
    Description:
    Second review follow-ups (fix/review-followups): employee deaths, garrison lists, stats loop, job rewards.

    Returns: ARRAY - [[name, code], ...], part of the review and DLC QA tests (OTQA_fnc_testsFollowups)
*/

"Respawn, then use Reset UI a few times: the stats HUD keeps updating and doesn't flicker" call OTQA_fnc_manual;
"Multiplayer (as a non-host player): finish a 'Kill NATO' and an 'Operative transport' job, you get the money and the kill count hints, the host doesn't" call OTQA_fnc_manual;
"Save at night (after 19:00), restart and load: time runs at the night speed straight away" call OTQA_fnc_manual;
"New game screen: pick Occupier Loadouts (Standard, Faction Random, Fully Random), start, save and reload: the choice stays" call OTQA_fnc_manual;
"As a general, open the player list and select an offline player who never saved money: shows $0, no script error" call OTQA_fnc_manual;

// Far corner of the map, away from towns and players
OTQA_rv_spawnKill = {
    params ["_side", "_var", "_value"];
    private _pos = [worldSize - 100, worldSize - 100, 0];
    private _killerGrp = createGroup civilian;
    private _killer = _killerGrp createUnit ["C_man_1", _pos, [], 0, "CAN_COLLIDE"];
    private _victimGrp = createGroup _side;
    private _victim = _victimGrp createUnit [["C_man_1", "B_Soldier_F"] select (_side isEqualTo blufor), _pos getPos [30, 0], [], 0, "CAN_COLLIDE"];
    _victim setVariable [_var, _value];
    [_victim, _killer, _killer] call OT_fnc_deathHandler;
    { deleteVehicle _x } forEach [_victim, _killer];
    deleteGroup _killerGrp;
    deleteGroup _victimGrp;
};

[
    ["Employee death lowers the employee count", {
        server setVariable ["OTQA_TESTemploy", 3, true];
        [civilian, "employee", "OTQA_TEST"] call OTQA_rv_spawnKill;
        private _count = server getVariable ["OTQA_TESTemploy", -1];
        ["Business loses one employee", _count isEqualTo 2, format ["employees: %1 (was 3)", _count]] call OTQA_fnc_check;
        server setVariable ["OTQA_TESTemploy", nil, true];
    }],

    ["Vehicle garrison list update", {
        server setVariable ["vehgarrisonOTQA_TEST", ["B_Soldier_F", "OTQA_other"], true];
        [blufor, "vehgarrison", "OTQA_TEST"] call OTQA_rv_spawnKill;
        private _list = server getVariable ["vehgarrisonOTQA_TEST", []];
        ["Dead unit's class is removed from the list", _list isEqualTo ["OTQA_other"], format ["list: %1", _list]] call OTQA_fnc_check;

        // Not in the list: nothing else may be removed
        [blufor, "vehgarrison", "OTQA_TEST"] call OTQA_rv_spawnKill;
        _list = server getVariable ["vehgarrisonOTQA_TEST", []];
        ["Unlisted class leaves the list alone", _list isEqualTo ["OTQA_other"], format ["list: %1", _list]] call OTQA_fnc_check;
        server setVariable ["vehgarrisonOTQA_TEST", nil, true];
    }],

    ["Stats loop restart", {
        private _before = missionNamespace getVariable ["OT_statsLoopId", 0];
        player call OT_fnc_statsSystem;
        private _after = missionNamespace getVariable ["OT_statsLoopId", 0];
        ["Restarting the stats HUD replaces the old loop", _after isEqualTo (_before + 1), format ["loop id %1 -> %2", _before, _after]] call OTQA_fnc_check;
    }],

    ["Occupier buys base vehicles", {
        // Real purchase with a zero chance roll, then the bases' vehicle lists are put back
        private _bases = OT_objectiveData + OT_airportData;
        private _saved = _bases apply { +(server getVariable [format ["vehgarrison%1", _x select 1], []]) };
        private _countVehicles = { { !(_x isKindOf "StaticWeapon") && { _x isKindOf "LandVehicle" } } count _this };
        private _before = 0;
        { _before = _before + (_x call _countVehicles) } forEach _saved;
        private _resources = server getVariable ["NATOresources", 2000];
        server setVariable ["NATOresources", 3000];

        private _left = [1500, 0] call OT_fnc_NATOupgradeVehicleGarrisons;
        private _after = 0;
        { _after = _after + ((server getVariable [format ["vehgarrison%1", _x select 1], []]) call _countVehicles) } forEach _bases;
        private _paid = 3000 - (server getVariable ["NATOresources", 3000]);
        ["A base gets one new vehicle", _after isEqualTo (_before + 1), format ["vehicles %1 -> %2 (all bases full or near a player if unchanged)", _before, _after]] call OTQA_fnc_check;
        ["It is paid from the occupier's resources", _paid in [250, 400] && { (1500 - _left) isEqualTo _paid }, format ["paid %1", _paid]] call OTQA_fnc_check;

        { server setVariable [format ["vehgarrison%1", (_bases select _forEachIndex) select 1], _x, true] } forEach _saved;
        server setVariable ["NATOresources", _resources];
    }],

    ["Base vehicle patrols near players", {
        // A crewed vehicle "parked" at a base right next to the player starts patrolling
        private _cls = selectRandom OT_NATO_Vehicles_GroundSupport;
        private _pos = player getPos [150, getDir player];
        _pos = _pos findEmptyPosition [0, 100, _cls];
        if (_pos isEqualTo []) exitWith { "Base vehicle patrol test skipped: no room for a vehicle near you" call OTQA_fnc_manual };
        private _veh = createVehicle [_cls, _pos, [], 0, "NONE"];
        private _group = [_veh] call OT_fnc_createNATOCrew;
        { _x disableAI "TARGET"; _x disableAI "AUTOTARGET" } forEach (crew _veh); // Don't shoot at the player
        _veh setCaptive true;
        { _x setCaptive true } forEach (crew _veh);
        private _script = [_group, _veh, getPos _veh] spawn OT_fnc_NATOvehiclePatrol;

        private _timeout = time + 45;
        waitUntil { sleep 1; (count (waypoints _group) > 1) || { time > _timeout } };
        ["Vehicle patrols while a player is within 2 km", count (waypoints _group) > 1, format ["%1, %2 waypoints", _cls, count waypoints _group]] call OTQA_fnc_check;

        terminate _script;
        { deleteVehicle _x } forEach (crew _veh);
        deleteVehicle _veh;
        deleteGroup _group;
    }],

    ["Occupier trades base vehicles for heavy ones", {
        // Real trade at the HQ with a zero chance roll, then the lists are put back
        private _hq = (OT_objectiveData + OT_airportData) select { (_x select 1) isEqualTo OT_NATO_HQ } param [0, []];
        if (_hq isEqualTo [] || { [_hq select 0] call OT_fnc_inSpawnDistance }) exitWith {
            "Heavy vehicle trade test skipped: the HQ is loaded (you're near it)" call OTQA_fnc_manual;
        };
        private _bases = OT_objectiveData + OT_airportData;
        private _savedVeh = _bases apply { +(server getVariable [format ["vehgarrison%1", _x select 1], []]) };
        private _savedAir = _bases apply { +(server getVariable [format ["airpatrol%1", _x select 1], []]) };
        private _resources = server getVariable ["NATOresources", 2000];

        // Only the HQ can trade: every other base gets nothing to trade in for this test
        { server setVariable [format ["vehgarrison%1", _x select 1], [], true] } forEach _bases;
        server setVariable [format ["vehgarrison%1", OT_NATO_HQ], [selectRandom OT_NATO_Vehicles_GroundSupport], true];
        server setVariable [format ["airpatrol%1", OT_NATO_HQ], [], true];
        server setVariable ["NATOresources", 3000];

        private _left = [1500, 0] call OT_fnc_NATOupgradeHeavyGarrisons;
        private _veh = server getVariable [format ["vehgarrison%1", OT_NATO_HQ], []];
        private _air = server getVariable [format ["airpatrol%1", OT_NATO_HQ], []];
        private _paid = 3000 - (server getVariable ["NATOresources", 3000]);
        private _gotTank = (_veh findIf { _x in OT_NATO_Vehicles_TankSupport }) > -1;
        ["HQ traded its light vehicle for a tank or patrol aircraft", (_gotTank && { count _veh isEqualTo 1 }) || { _veh isEqualTo [] && { count _air isEqualTo 1 } }, format ["vehicles %1, air patrol %2", _veh, _air]] call OTQA_fnc_check;
        ["The trade is paid from the occupier's resources", _paid > 0 && { (1500 - _left) isEqualTo _paid }, format ["paid %1", _paid]] call OTQA_fnc_check;

        { server setVariable [format ["vehgarrison%1", (_bases select _forEachIndex) select 1], _x, true] } forEach _savedVeh;
        { server setVariable [format ["airpatrol%1", (_bases select _forEachIndex) select 1], _x, true] } forEach _savedAir;
        server setVariable ["NATOresources", _resources];
    }],

    ["Base patrol aircraft circles near players", {
        private _cls = selectRandom (OT_NATO_Vehicles_AirSupport + OT_NATO_Vehicles_AirSupport_Small);
        private _pos = (player getPos [200, getDir player]) findEmptyPosition [0, 150, _cls];
        if (_pos isEqualTo []) exitWith { "Base air patrol test skipped: no room for a helicopter near you" call OTQA_fnc_manual };
        private _veh = createVehicle [_cls, _pos, [], 0, "NONE"];
        private _group = [_veh] call OT_fnc_createNATOCrew;
        { _x disableAI "TARGET"; _x disableAI "AUTOTARGET"; _x setCaptive true } forEach (crew _veh); // Don't shoot at the player
        _veh setCaptive true;
        private _script = [_group, _veh, getPos _veh] spawn OT_fnc_NATOairPatrolBase;

        private _timeout = time + 35;
        waitUntil { sleep 1; ((waypoints _group) findIf { waypointType _x isEqualTo "LOITER" } > -1) || { time > _timeout } };
        ["Patrol aircraft circles the base while a player is within 2 km", (waypoints _group) findIf { waypointType _x isEqualTo "LOITER" } > -1, _cls] call OTQA_fnc_check;

        terminate _script;
        { deleteVehicle _x } forEach (crew _veh);
        deleteVehicle _veh;
        deleteGroup _group;
    }],

    ["FOB buys a vehicle", {
        // A FOB 200 m from the player gets its vehicle upgrade, like OT_fnc_NATOupgradeFOBs buys it
        private _pos = player getPos [200, getDir player];
        private _fobs = server getVariable ["NATOfobs", []];
        private _fob = [_pos, 4, ["Vehicle"]];
        _fobs pushBack _fob;
        server setVariable ["NATOfobs", _fobs, true];
        [_pos, ["Vehicle"]] spawn OT_fnc_NATOupgradeFOB;

        private _timeout = time + 10;
        private _veh = objNull;
        waitUntil {
            sleep 0.5;
            _veh = (_pos nearEntities [["Car"], 80]) select { (_x getVariable ["OT_fobVehicle", []]) isEqualTo _pos } param [0, objNull];
            !isNull _veh || { time > _timeout }
        };
        private _crewOK = !isNull _veh && { (crew _veh) isNotEqualTo [] } && { side group driver _veh isEqualTo blufor };
        ["FOB vehicle spawns crewed (BLUFOR)", _crewOK, format ["%1", typeOf _veh]] call OTQA_fnc_check;

        if (!isNull _veh) then {
            { _x disableAI "TARGET"; _x disableAI "AUTOTARGET" } forEach (crew _veh);
            _veh setDamage 1;
            sleep 1;
        };
        ["A destroyed FOB vehicle frees the upgrade", !("Vehicle" in (_fob select 2)), format ["upgrades %1", _fob select 2]] call OTQA_fnc_check;

        if (!isNull _veh) then { { deleteVehicle _x } forEach (crew _veh); deleteVehicle _veh };
        _fobs = server getVariable ["NATOfobs", []];
        _fobs deleteAt (_fobs find _fob);
        server setVariable ["NATOfobs", _fobs, true];
    }]
]
