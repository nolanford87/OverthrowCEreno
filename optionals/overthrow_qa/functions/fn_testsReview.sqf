/*
    Description:
    Second review follow-ups (fix/review-followups): employee deaths, garrison lists, stats loop, job rewards.

    Returns: ARRAY - [[name, code], ...], part of the review and DLC QA tests (OTQA_fnc_testsFollowups)
*/

"Respawn, then use Reset UI a few times: the stats HUD keeps updating and doesn't flicker" call OTQA_fnc_manual;
"Multiplayer (as a non-host player): finish a 'Kill NATO' and an 'Operative transport' job, you get the money and the kill count hints, the host doesn't" call OTQA_fnc_manual;
"Save at night (after 19:00), restart and load: time runs at the night speed straight away" call OTQA_fnc_manual;
"New game screen: pick Occupier Loadouts (Standard, Faction Random, Fully Random), start, save and reload: the choice stays" call OTQA_fnc_manual;
"A FOB whose bought vehicle arrives (drives in or parachuted) warns that the nearest town falls back in 15 minutes; clear the FOB in time and it doesn't. If it takes the town, its vehicle patrols the town afterwards and the FOB is gone once you are dead or over 1 km away" call OTQA_fnc_manual;
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
        // An open spot (not in trees, which destroy a spawning helicopter)
        private _pos = [player getPos [200, getDir player], 0, 200, 15, 0, 0.2, 0, [], [[], []]] call BIS_fnc_findSafePos;
        if (_pos isEqualTo []) exitWith { "Base air patrol test skipped: no room for a helicopter near you" call OTQA_fnc_manual };
        private _veh = createVehicle [_cls, _pos, [], 0, "NONE"];
        private _group = [_veh] call OT_fnc_createNATOCrew;
        { _x disableAI "TARGET"; _x disableAI "AUTOTARGET"; _x setCaptive true } forEach (crew _veh); // Don't shoot at the player
        _veh setCaptive true;
        private _script = [_group, _veh, getPos _veh] spawn OT_fnc_NATOairPatrolBase;

        private _timeout = time + 35;
        waitUntil { sleep 1; ((waypoints _group) findIf { waypointType _x isEqualTo "LOITER" } > -1) || { time > _timeout } };
        ["Patrol aircraft circles the base while a player is within 2 km", (waypoints _group) findIf { waypointType _x isEqualTo "LOITER" } > -1,
            format ["%1, alive %2, crew %3, %4 waypoints", _cls, alive _veh, count crew _veh, count waypoints _group]] call OTQA_fnc_check;

        terminate _script;
        { deleteVehicle _x } forEach (crew _veh);
        deleteVehicle _veh;
        deleteGroup _group;
    }],

    ["FOB buys a vehicle", {
        // A FOB 200 m from the player gets its vehicle upgrade, like OT_fnc_NATOupgradeFOBs buys it
        private _pos = player getPos [200, getDir player];
        private _fobs = server getVariable ["NATOfobs", []];
        // Full garrison and every other upgrade, so a vehicle is the only thing it could still buy
        private _fob = [_pos, 16, ["Mortar", "Barriers", "HMG", "Vehicle"]];
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
        ["A destroyed FOB vehicle isn't replaced", !("Vehicle" in (_fob select 2)) && { "VehicleLost" in (_fob select 2) }, format ["upgrades %1", _fob select 2]] call OTQA_fnc_check;
        // The FOB doesn't buy another one (the only FOB, zero chance roll, plenty to spend)
        private _resources = server getVariable ["NATOresources", 2000];
        private _allFobs = server getVariable ["NATOfobs", []];
        server setVariable ["NATOfobs", [_fob], true];
        [2000, 0] call OT_fnc_NATOupgradeFOBs;
        server setVariable ["NATOfobs", _allFobs, true];
        server setVariable ["NATOresources", _resources];
        ["The FOB can't buy another vehicle", !("Vehicle" in (_fob select 2)), format ["upgrades %1", _fob select 2]] call OTQA_fnc_check;

        if (!isNull _veh) then { { deleteVehicle _x } forEach (crew _veh); deleteVehicle _veh };
        _fobs = server getVariable ["NATOfobs", []];
        _fobs deleteAt (_fobs find _fob);
        server setVariable ["NATOfobs", _fobs, true];
        // Losing the vehicle started this test FOB's takeover timer, drop it
        server setVariable ["NATOfobTimers", (server getVariable ["NATOfobTimers", []]) select { (_x select 0) isNotEqualTo _pos }];
    }],

    ["Bought FOB vehicle is delivered", {
        // Bought for a FOB 200 m from the player: it drives in from a base, or is parachuted in
        private _pos = player getPos [200, getDir player];
        private _fobs = server getVariable ["NATOfobs", []];
        private _fob = [_pos, 16, ["Mortar", "Barriers", "HMG", "Vehicle"]];
        _fobs pushBack _fob;
        server setVariable ["NATOfobs", _fobs, true];
        OT_deliveryIntelChance = 0; // No intelligence report task from this test
        [_pos, true] spawn OT_fnc_NATOdeliverFOBVehicle;

        private _timeout = time + 10;
        private _veh = objNull;
        waitUntil {
            sleep 0.5;
            _veh = vehicles select { (_x getVariable ["OT_fobVehicle", []]) isEqualTo _pos } param [0, objNull];
            !isNull _veh || { time > _timeout }
        };
        sleep 2;
        private _way = ["not found", "parachuted in", "driving in"] select ([0, [1, 2] select (((getPosATL _veh) select 2) < 5)] select !isNull _veh);
        ["FOB vehicle is on its way (not placed at the FOB)", !isNull _veh && { ((_veh distance2D _pos) > 60) || { ((getPosATL _veh) select 2) > 5 } },
            format ["%1, %2 m from the FOB, %3 m up (%4)", typeOf _veh, round (_veh distance2D _pos), round ((getPosATL _veh) select 2), _way]] call OTQA_fnc_check;

        if (!isNull _veh) then {
            { deleteVehicle _x } forEach (crew _veh);
            { detach _x; deleteVehicle _x } forEach (attachedObjects _veh);
            if (!isNull attachedTo _veh) then { deleteVehicle (attachedTo _veh) };
            deleteVehicle _veh;
        };
        _fobs = server getVariable ["NATOfobs", []];
        _fobs deleteAt (_fobs find _fob);
        server setVariable ["NATOfobs", _fobs, true];
        OT_deliveryIntelChance = nil;
    }],

    ["FOB takeover timer", {
        // A FOB near a town (one the resistance holds if there is one), its timer started as when its vehicle arrives
        private _abandoned = server getVariable ["NATOabandoned", []];
        private _town = (_abandoned select { _x in OT_allTowns }) param [0, (getPos player) call OT_fnc_nearestTown];
        private _townPos = server getVariable [_town, getPos player];
        private _allFobs = server getVariable ["NATOfobs", []];
        private _fobPos = _townPos getPos [150, 0];
        private _fob = [_fobPos, 16, ["Mortar", "Barriers", "HMG", "Vehicle"]];
        server setVariable ["NATOfobs", _allFobs + [_fob], true];

        [_fobPos] call OT_fnc_NATOstartFOBTimer;
        private _timer = (server getVariable ["NATOfobTimers", []]) select { (_x select 0) isEqualTo _fobPos } param [0, []];
        ["Timer starts at 15 minutes for the nearest town", (_timer param [1, 0]) isEqualTo 900 && { (_timer param [2, ""]) isEqualTo _town } && { "TownTimer" in (_fob select 2) }, format ["%1", _timer]] call OTQA_fnc_check;
        [_fobPos] call OT_fnc_NATOstartFOBTimer;
        ["Only one timer per FOB", ({ (_x select 0) isEqualTo _fobPos } count (server getVariable ["NATOfobTimers", []])) isEqualTo 1, ""] call OTQA_fnc_check;

        // Its vehicle, still alive, should join the town's garrison
        private _vehCls = selectRandom OT_NATO_Vehicles_GroundSupport;
        private _vehPos = _fobPos findEmptyPosition [10, 80, _vehCls];
        if (_vehPos isEqualTo []) then { _vehPos = _fobPos };
        private _fobVeh = createVehicle [_vehCls, _vehPos, [], 0, "NONE"];
        _fobVeh setVariable ["OT_fobVehicle", _fobPos];
        [_fobVeh] call OT_fnc_createNATOCrew;
        private _townVehicles = +(server getVariable [format ["vehgarrison%1", _town], []]);

        // A resistance police station with police in the town
        private _stationPos = (_townPos getPos [60, 90]) findEmptyPosition [0, 100, OT_policeStation];
        if (_stationPos isEqualTo []) then { _stationPos = _townPos getPos [60, 90] };
        private _station = createVehicle [OT_policeStation, _stationPos, [], 0, "NONE"];
        [_station, getPlayerUID player] call OT_fnc_setOwner;
        server setVariable [format ["policepos%1", _town], getPos _station, true];
        server setVariable [format ["police%1", _town], 2, true];
        private _policeGroup = createGroup independent;
        private _officer = _policeGroup createUnit ["I_G_Soldier_F", _stationPos getPos [8, 0], [], 0, "NONE"];
        _officer setVariable ["polgarrison", _town, true];

        // Time's up (the save is disposable, the town really flips)
        _timer set [1, 0];
        call OT_fnc_NATOFOBtimers;
        private _newList = server getVariable [format ["vehgarrison%1", _town], []];
        ["The FOB's vehicle joins the town's garrison", (count _newList) isEqualTo ((count _townVehicles) + 1) && { _vehCls in _newList } && { (_fobVeh getVariable ["vehgarrison", ""]) isEqualTo _town },
            format ["%1: %2", _town, _newList]] call OTQA_fnc_check;
        ["The FOB is set to disband", "Disband" in (_fob select 2), ""] call OTQA_fnc_check;
        sleep 0.5; // Deleting takes a frame
        ["The resistance police station and its police are removed", isNull _station && { isNull _officer } && { (server getVariable [format ["police%1", _town], -1]) isEqualTo -1 },
            format ["station %1, officer %2, police %3", !isNull _station, !isNull _officer, server getVariable [format ["police%1", _town], -1]]] call OTQA_fnc_check;
        deleteGroup _policeGroup;

        // It disbands once no player is within 1 km
        call OT_fnc_NATOFOBtimers;
        private _stillThere = ((server getVariable ["NATOfobs", []]) findIf { (_x select 0) isEqualTo _fobPos }) > -1;
        if ((player distance2D _fobPos) > 1000) then {
            ["FOB disbands when no player is within 1 km", !_stillThere, ""] call OTQA_fnc_check;
        } else {
            ["FOB stays while a player is within 1 km", _stillThere, format ["%1 m away", round (player distance2D _fobPos)]] call OTQA_fnc_check;
        };

        { deleteVehicle _x } forEach (crew _fobVeh);
        deleteVehicle _fobVeh;
        server setVariable [format ["vehgarrison%1", _town], _townVehicles, true];
        private _stability = server getVariable [format ["stability%1", _town], 0];
        private _support = server getVariable [format ["rep%1", _town], 0];
        ["Town is back under occupier control, 100% stability, no resistance support",
            !(_town in (server getVariable ["NATOabandoned", []])) && { _stability isEqualTo 100 } && { _support isEqualTo 0 },
            format ["%1: stability %2, support %3", _town, _stability, _support]] call OTQA_fnc_check;
        ["Timer is done", ((server getVariable ["NATOfobTimers", []]) findIf { (_x select 0) isEqualTo _fobPos }) isEqualTo -1, ""] call OTQA_fnc_check;

        // A cleared FOB's timer is dropped
        private _fob2Pos = _townPos getPos [150, 180];
        server setVariable ["NATOfobs", _allFobs + [[_fob2Pos, 16, ["Mortar", "Barriers", "HMG", "VehicleLost"]]], true];
        [_fob2Pos] call OT_fnc_NATOstartFOBTimer;
        server setVariable ["NATOfobs", _allFobs, true]; // Cleared
        call OT_fnc_NATOFOBtimers;
        ["Clearing the FOB cancels its timer", ((server getVariable ["NATOfobTimers", []]) findIf { (_x select 0) isEqualTo _fob2Pos }) isEqualTo -1, ""] call OTQA_fnc_check;
    }],

    ["Bought patrol aircraft flies in", {
        // Ordered for a (test) base at the player: it appears high above the occupier's nearest airfield
        private _cls = selectRandom (OT_NATO_Vehicles_AirSupport + OT_NATO_Vehicles_AirSupport_Small);
        private _basePos = getPos player;
        private _airfield = [_basePos, "OTQA_TEST"] call OT_fnc_NATOnearestAirfield;
        if (_airfield isEqualTo []) exitWith {
            ["The occupier holds no airfield, so it can't buy aircraft", true, ""] call OTQA_fnc_check;
        };
        OT_deliveryIntelChance = 0; // No intelligence report task from this test
        private _script = [_cls, "OTQA_TEST", _basePos, _airfield select 0] spawn OT_fnc_NATOdeliverAirPatrol;
        private _timeout = time + 10;
        private _veh = objNull;
        waitUntil {
            sleep 0.5;
            _veh = vehicles select { (_x getVariable ["airpatrol", ""]) isEqualTo "OTQA_TEST" } param [0, objNull];
            !isNull _veh || { time > _timeout }
        };
        sleep 1;
        private _dist = round (_veh distance2D (_airfield select 0));
        private _alt = round ((getPosATL _veh) select 2);
        ["Patrol aircraft appears high above the nearest held airfield", !isNull _veh && { _dist < 400 } && { _alt > 150 } && { alive _veh },
            format ["%1 over %2: %3 m from it, %4 m up", _cls, _airfield select 1, _dist, _alt]] call OTQA_fnc_check;

        // With no airfield held, no aircraft can be bought
        private _abandoned = server getVariable ["NATOabandoned", []];
        server setVariable ["NATOabandoned", _abandoned + (OT_airportData apply { _x select 1 }), true];
        ["Without a held airfield there's nowhere to buy aircraft from", ([_basePos, "OTQA_TEST"] call OT_fnc_NATOnearestAirfield) isEqualTo [], ""] call OTQA_fnc_check;
        server setVariable ["NATOabandoned", _abandoned, true];

        terminate _script;
        if (!isNull _veh) then {
            private _group = group driver _veh;
            { deleteVehicle _x } forEach (crew _veh);
            deleteVehicle _veh;
            deleteGroup _group;
        };
        OT_deliveryIntelChance = nil;
    }],

    ["Bought tank is delivered", {
        // Ordered for a (test) base at the player: convoyed with 2 escorts, or airdropped about 2 km away
        if (OT_NATO_Vehicles_TankSupport isEqualTo []) exitWith { "Tank delivery test skipped: the occupier has no tanks" call OTQA_fnc_manual };
        private _cls = selectRandom OT_NATO_Vehicles_TankSupport;
        private _basePos = getPos player;
        OT_deliveryIntelChance = 0; // No intelligence report task from this test
        private _script = [_cls, "OTQA_TEST", _basePos] spawn OT_fnc_NATOdeliverHeavy;
        private _timeout = time + 15;
        private _tank = objNull;
        waitUntil {
            sleep 0.5;
            _tank = vehicles select { (_x getVariable ["vehgarrison", ""]) isEqualTo "OTQA_TEST" } param [0, objNull];
            !isNull _tank || { time > _timeout }
        };
        sleep 2;
        private _escorts = vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo "OTQA_TEST" };
        private _alt = (getPosATL _tank) select 2;
        private _dist = _tank distance2D _basePos;
        private _airdrop = _alt > 20 || { (_dist > 1500) && { (_dist < 2500) } && { _escorts isEqualTo [] } };
        private _convoy = (count _escorts) isEqualTo 2 && { (_escorts findIf { !alive _x || { isNull driver _x } }) isEqualTo -1 };
        ["Tank is convoyed (2 escorts) or airdropped about 2 km away", !isNull _tank && { _airdrop || _convoy },
            format ["%1: %2, %3 m from the base, %4 m up, %5 escorts", _cls, ["airdrop", "convoy"] select _convoy, round _dist, round _alt, count _escorts]] call OTQA_fnc_check;

        terminate _script;
        {
            private _v = _x;
            private _g = group driver _v;
            { deleteVehicle _x } forEach (crew _v);
            { detach _x; deleteVehicle _x } forEach (attachedObjects _v);
            if (!isNull attachedTo _v) then { deleteVehicle (attachedTo _v) };
            deleteVehicle _v;
            if (!isNull _g) then { deleteGroup _g };
        } forEach (_escorts + ([_tank] select { !isNull _x }));
        OT_deliveryIntelChance = nil;
    }]
]
