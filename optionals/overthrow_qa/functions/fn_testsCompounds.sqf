/*
    Description:
    The occupier compounds' work in progress (tools/officegen/COMPOUND_PLAN.md, the Rodopoli pilot's step 4 on).
    Part of the current QA tests; the finished steps are in OTQA_fnc_testsOfficeGameplay (archived).
    1. Gates worked by the occupier: a closed gate opens for an occupier soldier, not for one of ours, shuts
       10 s after; the town taken opens and unlocks it
    2. An occupier soldier walks out of Rodopoli's T3 compound and back in through its gate shut (the path
       finding plans no way through a shut gate: it opens for one going somewhere within 40 m)
    3. Static weapons by role: the hmg role a machine gun, the vanilla AT static read as at
    4. The garrison (OT_fnc_officeGarrison through OT_fnc_spawnOffice) of every generated compound (OTQA_cp_cases:
       Rodopoli, Paros, Chalkeia at T3 and T4), one spawn each, the expectations read from the layout: the men made
       (one per 150 m2), the reserve in the layout's groups at ease, the patrol (T4) its own group walking a loop
       inside the walls, the posts holding, aware, flashlights, no NVGs, the area published; then the patrol and
       the reserve hunting a threat outside but staying inside the walls, the town's gendarmerie sent over, the
       parked armed car crewed (where the layout has one), the siren sounding. Losses kept off and paid back on
       Rodopoli T4
    5. An undercover player (unarmed) seen inside the compound's walls loses his cover; outside it he keeps it
    (A truck can't drive in, even through the gate open: the vehicle path finding gives up, so occupier
    vehicles park and unload outside the gate, the user's choice.)

    Returns: ARRAY - [[name, code, seconds], ...]
*/

call OTQA_fnc_testsOfficeHelpers;

private _tests = [];

_tests pushBack ["Office: gates worked by the occupier, open once taken", {
    private _town = "Rodopoli";
    private _o = _town call OTQA_og_officePos;
    private _at = AGLToASL [(_o select 0) + 400, (_o select 1) - 400, 0];
    (([[["object", "Land_NetFence_01_m_gate_F", _at, [[0, 1, 0], [0, 0, 1]], ["ground"]]], west, false, [_town, 3]] call OT_fnc_officeSpawnItems) select 0) params ["_gate"];
    private _phase = { _gate animationSourcePhase "Door_1_sound_source" };
    sleep 2;
    private _shut0 = (call _phase) < 0.1;
    private _ours = ([ASLToAGL _at vectorAdd [0, -4, 0]] call OTQA_og_ours);
    sleep 4;
    private _notOurs = (call _phase) < 0.1;
    deleteVehicle _ours;
    private _grp = createGroup [blufor, true];
    private _them = _grp createUnit ["B_Soldier_F", ASLToAGL _at vectorAdd [0, -4, 0], [], 0, "CAN_COLLIDE"];
    _them disableAI "MOVE";
    _them allowDamage false;
    sleep 4;
    private _opened = (call _phase) > 0.9;
    deleteVehicle _them;
    sleep 6;
    private _stillOpen = (call _phase) > 0.9;
    sleep 8;
    private _shutAgain = (call _phase) < 0.1 && { (_gate getVariable [format ["bis_disabled_Door_%1", 1], 0]) isEqualTo 1 };
    ["Gates: shut and locked, not opened for ours, opened for theirs, shut 10 s after", _shut0 && _notOurs && _opened && _stillOpen && _shutAgain, format ["shut %1, ours left it %2, opened %3, open 6 s after %4, shut and locked 14 s after %5", _shut0, _notOurs, _opened, _stillOpen, _shutAgain]] call OTQA_fnc_check;
    // The town taken: the gate unlocked and swung open
    server setVariable [format ["officeheld%1", _town], true, true];
    [_town, 0] call OT_fnc_officeDoors;
    sleep 2;
    private _taken = (call _phase) > 0.9 && { (_gate getVariable [format ["bis_disabled_Door_%1", 1], 0]) isEqualTo 0 };
    server setVariable [format ["officeheld%1", _town], nil, true];
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
    deleteVehicle _gate;
    ["Gates: the town taken, its gate unlocked and open", _taken, str _taken] call OTQA_fnc_check;
}, 60];

// Each compound gate shut blocks its way: rays across its line every 0.5 m at knee and chest height (OTGATERAY
// lines: the open offsets along the gate, and its animation sources' phases)
_tests pushBack ["Office: a gate shut blocks its way", {
    private _o = "Rodopoli" call OTQA_og_officePos;
    {
        private _cls = _x;
        private _at = AGLToASL [(_o select 0) + 400 + 30 * _forEachIndex, (_o select 1) - 430, 0];
        (([[["object", _cls, _at, [[0, 1, 0], [0, 0, 1]], ["ground"]]], west, false, ["Rodopoli", 3]] call OT_fnc_officeSpawnItems) select 0) params ["_gate"];
        sleep 2;
        (boundingBoxReal _gate) params ["_lo", "_hi"];
        private _open = [];
        for "_off" from ((_lo select 0) + 0.25) to ((_hi select 0) - 0.25) step 0.5 do {
            private _blocked = [0.5, 1.4] findIf {
                private _a = _gate modelToWorldWorld [_off, (_lo select 1) - 1, (_lo select 2) + _x];
                private _b = _gate modelToWorldWorld [_off, (_hi select 1) + 1, (_lo select 2) + _x];
                (lineIntersectsSurfaces [_a, _b, objNull, objNull, true, 1, "GEOM", "NONE"]) isNotEqualTo []
            };
            if (_blocked < 0) then { _open pushBack (round (_off * 10) / 10) };
        };
        private _sources = ("true" configClasses (configOf _gate >> "AnimationSources")) apply { [configName _x, _gate animationSourcePhase (configName _x)] };
        diag_log format ["OTGATERAY|%1|width %2|open at %3|sources %4", _cls, round (((_hi select 0) - (_lo select 0)) * 10) / 10, _open, _sources];
        [format ["Gates: %1 shut blocks its way", _cls], _open isEqualTo [], format ["open at %1 (of %2 m), sources %3", _open, round (((_hi select 0) - (_lo select 0)) * 10) / 10, _sources]] call OTQA_fnc_check;
        deleteVehicle _gate;
    } forEach ["Land_NetFence_01_m_gate_F", "Land_ConcreteWall_01_l_gate_F"];
}, 20];

// An occupier soldier walks out of a compound's tier through its main gate shut and back in (the gate operator
// working it, as in play)
OTQA_cp_walkTest = {
    params ["_town", "_tier"];
    ([_town, _tier, west, true] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];
    private _hq = _town call OTQA_og_officePos;
    // The main gate: the tier's gate marker nearest the HQ, and the gate standing on it
    private _marker = ((([_town] call OT_fnc_officeLayout) select 1) select (_tier - 1)) select { (_x select 0) isEqualTo "gate" };
    _marker = [_marker, [], { (ASLToAGL (_x select 2)) distance2D _hq }, "ASCEND"] call BIS_fnc_sortBy;
    private _gp0 = if (_marker isEqualTo []) then { [0, 0, 0] } else { ASLToAGL ((_marker select 0) select 2) };
    private _gate = (([_objects select { "gate" in toLower typeOf _x }, [], { _x distance2D _gp0 }, "ASCEND"] call BIS_fnc_sortBy) param [0, objNull]);
    if (isNull _gate || { _marker isEqualTo [] }) exitWith {
        { deleteVehicle _x } forEach (_objects + _guards);
        [format ["Walk: %1's T%2 gate found", _town, _tier], false, format ["gate %1, markers %2", _gate, count _marker]] call OTQA_fnc_check;
    };
    // The gate shut, locked and worked by the occupier, as a closed gate is in play
    for "_d" from 1 to (getNumber (configOf _gate >> "numberOfDoors")) max 1 do { _gate setVariable [format ["bis_disabled_Door_%1", _d], 1, true] };
    _gate setVariable ["OT_officeGate", true, true];
    _gate enableSimulationGlobal true;
    [_gate] call OT_fnc_officeGates;
    private _gp = ASLToAGL ((_marker select 0) select 2);
    // Straight out through the gate: across the wall line (the marker's direction runs along it), away from the HQ
    // (along the HQ-to-gate line the point 6 m in fell in a pocket by the HQ's wall at Chalkeia T3: no route to it)
    private _along = ((_marker select 0) select 3) select 0;
    private _out = vectorNormalized [-(_along select 1), _along select 0, 0];
    if (((_gp vectorAdd _out) distance2D _hq) < (_gp distance2D _hq)) then { _out = _out vectorMultiply -1 };
    // Places a man can stand on: 6 m in (not in the HQ, which can stand close to the gate), on the road 25 m out
    private _in = (_gp vectorAdd (_out vectorMultiply -6)) findEmptyPosition [0, 6, "B_Soldier_F"];
    if (_in isEqualTo []) then { _in = _gp vectorAdd (_out vectorMultiply -6) };
    private _road = ((_gp vectorAdd (_out vectorMultiply 25)) nearRoads 15) param [0, objNull];
    private _far = if (isNull _road) then { (_gp vectorAdd (_out vectorMultiply 25)) findEmptyPosition [0, 10, "B_Soldier_F"] } else { getPosATL _road };
    if (_far isEqualTo []) then { _far = _gp vectorAdd (_out vectorMultiply 25) };
    _in set [2, 0];
    _far set [2, 0];
    private _walk = {
        params ["_from", "_to"];
        sleep 16; // The gate shut again behind the last (10 s after him, then its swing)
        private _shut = (_gate animationSourcePhase "Door_1_sound_source") < 0.1;
        private _grp = createGroup [blufor, true];
        private _man = _grp createUnit ["B_Soldier_F", _from, [], 0, "CAN_COLLIDE"];
        _man allowDamage false;
        _grp setBehaviour "AWARE";
        [_man, ([-(_out select 1), _out select 0, 0] vectorMultiply 14) vectorAdd [0, 0, 12]] call OTQA_og_camera;
        _man doMove _to;
        private _t = time + 90;
        private _next = 0;
        waitUntil {
            sleep 1;
            if (time > _next) then {
                _next = time + 5;
                diag_log format ["OTGATEWALKSTEP|%1 m to go|speed %2|expected %3|command %4|gate %5", round (_man distance2D _to), round speed _man, expectedDestination _man, currentCommand _man, _gate animationSourcePhase "Door_1_sound_source"];
            };
            (_man distance2D _to) < 4 || { time > _t }
        };
        private _took = round (90 - (_t - time));
        private _there = (_man distance2D _to) < 4;
        call OTQA_og_cameraOff;
        deleteVehicle _man;
        [_shut, _there, _took]
    };
    private _outward = [_in, _far] call _walk;
    private _inward = [_far, _in] call _walk;
    diag_log format ["OTGATEWALK|%1|T%2|out %3|in %4", _town, _tier, _outward, _inward];
    { deleteVehicle _x } forEach (_objects + _guards);
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
    [format ["Walk (%1 T%2): an occupier soldier gets out through the shut gate", _town, _tier], (_outward select 0) && { _outward select 1 }, format ["gate shut first %1, out %2 in %3 s", _outward select 0, _outward select 1, _outward select 2]] call OTQA_fnc_check;
    [format ["Walk (%1 T%2): an occupier soldier gets in through the shut gate", _town, _tier], (_inward select 0) && { _inward select 1 }, format ["gate shut first %1, in %2 in %3 s", _inward select 0, _inward select 1, _inward select 2]] call OTQA_fnc_check;
};
_tests pushBack ["Compounds: men walk out and in through a shut gate (Rodopoli T3)", { ["Rodopoli", 3] call OTQA_cp_walkTest }, 240];
_tests pushBack ["Compounds: men walk out and in through a shut gate (Chalkeia T3)", { ["Chalkeia", 3] call OTQA_cp_walkTest }, 240];
_tests pushBack ["Compounds: men walk out and in through a shut gate (Paros T3)", { ["Paros", 3] call OTQA_cp_walkTest }, 240];
_tests pushBack ["Compounds: men walk out and in through a shut gate (Paros T4)", { ["Paros", 4] call OTQA_cp_walkTest }, 240];

_tests pushBack ["Office: static weapons by role", {
    private _hmg = ["hmg"] call OT_fnc_officeStatic;
    private _weapon = (getArray (configFile >> "CfgVehicles" >> _hmg >> "Turrets" >> "MainTurret" >> "weapons")) param [0, ""];
    private _mag = (getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines")) param [0, ""];
    private _sim = getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _mag >> "ammo") >> "simulation");
    ["Statics: the hmg role is a machine gun (fires bullets)", _sim isEqualTo "shotBullet", format ["%1 fires %2", _hmg, _sim]] call OTQA_fnc_check;
    ["Statics: the vanilla AT static reads as at, the HMG as hmg", (["B_static_AT_F"] call OT_fnc_officeStatic) isEqualTo "at" && { (["B_HMG_01_high_F"] call OT_fnc_officeStatic) isEqualTo "hmg" }, format ["AT %1, HMG %2", ["B_static_AT_F"] call OT_fnc_officeStatic, ["B_HMG_01_high_F"] call OT_fnc_officeStatic]] call OTQA_fnc_check;
}, 10];

// The compounds tested: every town with a generated compound, at T3 and T4
OTQA_cp_cases = [["Rodopoli", 3], ["Rodopoli", 4], ["Paros", 3], ["Paros", 4], ["Chalkeia", 3], ["Chalkeia", 4]];

// A town's compound spawned by the game's own spawner at a tier, [guards, things, spawner id, town]
OTQA_cp_spawn = {
    params ["_town", "_tier"];
    server setVariable [format ["officetier%1", _town], _tier];
    private _id = format ["OTQA_compound%1", round (time * 100)];
    [_town, _id] call OT_fnc_spawnOffice;
    private _things = spawner getVariable [_id, []];
    private _guards = allUnits select { (_x getVariable ["OT_compoundGuard", ""]) isEqualTo _town };
    [_guards, _things, _id, _town]
};
OTQA_cp_clear = {
    params ["_spawned"];
    _spawned params ["_guards", "_things", "_id", "_town"];
    call OTQA_og_cameraOff;
    { deleteVehicle _x } forEach (allUnits select { (_x getVariable ["OT_compoundGuard", ""]) isEqualTo _town });
    { if (_x isEqualType grpNull) then { { deleteVehicle _x } forEach units _x; deleteGroup _x } else { deleteVehicle _x } } forEach _things;
    spawner setVariable [_id, nil];
    server setVariable [format ["officetier%1", _town], nil];
    server setVariable [format ["compoundlost%1", _town], nil];
    server setVariable [format ["compoundarea%1", _town], nil, true];
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
};
OTQA_cp_patrol = {
    params ["_guards"];
    _guards select { "patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]) }
};
OTQA_cp_reserve = {
    params ["_guards"];
    _guards select { "reserve" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]) }
};
// The garrison's size by the user's rule: one man per 150 m2 of the tier's area (static crews among them)
OTQA_cp_size = {
    params ["_town", "_tier"];
    private _p = [_town, _tier] call OT_fnc_officeCompound;
    private _n = count _p;
    private _a = 0;
    for "_i" from 0 to _n - 1 do {
        private _u = _p select _i; private _v = _p select ((_i + 1) mod _n);
        _a = _a + (_u select 0) * (_v select 1) - (_v select 0) * (_u select 1);
    };
    round ((abs _a) / 2 / 150)
};
// What the tier's layout holds: [patrol men, reserve group sizes (sorted, from the reserve:<n> flags), an armed car]
OTQA_cp_expect = {
    params ["_town", "_tier"];
    private _items = (([_town] call OT_fnc_officeLayout) param [1, []]) param [_tier - 1, []];
    private _guards = _items select { (_x select 0) isEqualTo "guard" };
    private _patrol = { "patrol" in (_x param [4, []]) } count _guards;
    private _keys = createHashMap;
    {
        private _k = (_x param [4, []]) select { (_x select [0, 8]) isEqualTo "reserve:" };
        if (_k isNotEqualTo []) then { _keys set [_k select 0, (_keys getOrDefault [_k select 0, 0]) + 1] };
    } forEach _guards;
    private _sizes = values _keys;
    _sizes sort true;
    [_patrol, _sizes, (_items findIf { (_x select 0) isEqualTo "vehicle" }) > -1]
};

// The garrison at work and its hunt, one spawn per [town, tier]: the men made, the reserve's groups at ease, the
// patrol (T4) its own group walking a loop, the posts holding, the area published; then a threat outside the
// wall: the patrol and the reserve go to combat inside the walls, the gendarmerie to the gate, the armed car (where
// the layout has one) crewed, the siren
OTQA_cp_garrisonTest = {
    params ["_town", "_tier"];
    private _tag = format ["(%1 T%2)", _town, _tier];
    ([_town, _tier] call OTQA_cp_expect) params ["_xPatrol", "_xSizes", "_xCar"];
    private _spawned = [_town, _tier] call OTQA_cp_spawn;
    _spawned params ["_guards"];
    private _patrol = [_guards] call OTQA_cp_patrol;
    private _reserve = [_guards] call OTQA_cp_reserve;
    private _posts = _guards - _patrol - _reserve;
    private _rgroups = (_reserve apply { group _x }) arrayIntersect (_reserve apply { group _x });
    private _pg = group (_patrol param [0, objNull]);
    private _area = server getVariable [format ["compoundarea%1", _town], []];
    private _cycle = ((waypoints _pg) findIf { (waypointType _x) isEqualTo "CYCLE" }) > -1;
    private _free = { _x checkAIFeature "PATH" } count _posts;
    private _unaware = { (behaviour _x) isNotEqualTo "AWARE" } count (_guards - _reserve);
    private _uneasy = { (behaviour _x) isNotEqualTo "SAFE" } count _reserve;
    private _nvg = { hmd _x isNotEqualTo "" } count _guards;
    private _dark = { primaryWeapon _x isNotEqualTo "" && { ((primaryWeaponItems _x) select 1) isEqualTo "" } } count _guards;
    private _size = [_town, _tier] call OTQA_cp_size;
    [format ["Garrison %1: one man per 150 m2 (static crews among them)", _tag], (count _guards) isEqualTo _size, format ["%1 of %2", count _guards, _size]] call OTQA_fnc_check;
    private _sizes = _rgroups apply { count units _x };
    _sizes sort true;
    private _apart = ((_reserve apply { group _x }) findIf { _x isEqualTo (group (_posts param [0, objNull])) || { _x isEqualTo _pg } }) < 0;
    [format ["Garrison %1: the reserve in the layout's groups (2-4 each), its own, at ease", _tag], _sizes isEqualTo _xSizes && { (_sizes findIf { _x < 2 || _x > 4 }) < 0 } && _apart && { _uneasy isEqualTo 0 }, format ["groups %1 (layout %2), apart %3, not relaxed %4", _sizes, _xSizes, _apart, _uneasy]] call OTQA_fnc_check;
    if (_tier >= 4) then {
        [format ["Garrison %1: the patrol of four its own group, walking a loop", _tag], _xPatrol isEqualTo 4 && { (count _patrol) isEqualTo 4 } && { (count units _pg) isEqualTo 4 } && _cycle, format ["%1 in the patrol (layout %2), %3 in its group, %4 waypoints", count _patrol, _xPatrol, count units _pg, count waypoints _pg]] call OTQA_fnc_check;
    } else {
        [format ["Garrison %1: no patrol below T4", _tag], _xPatrol isEqualTo 0 && { _patrol isEqualTo [] }, format ["%1 in the patrol (layout %2)", count _patrol, _xPatrol]] call OTQA_fnc_check;
    };
    [format ["Garrison %1: the posts hold, everyone but the reserve aware, flashlights, no NVGs", _tag], _free isEqualTo 0 && _unaware isEqualTo 0 && _nvg isEqualTo 0 && _dark isEqualTo 0, format ["posts free to walk %1, not aware %2, NVGs %3, no light %4", _free, _unaware, _nvg, _dark]] call OTQA_fnc_check;
    [format ["Garrison %1: the compound's area published for the undercover check", _tag], (count _area) > 2, str count _area] call OTQA_fnc_check;
    // Every quarter second: a patrol or reserve man's crossing out of the walls logged with what stands where he
    // crossed (OTCPCROSS lines)
    private _tracker = [_town, _tier, _patrol + _reserve, _area] spawn {
        params ["_town", "_tier", "_men", "_area"];
        while { true } do {
            {
                private _p = getPosATL _x;
                private _last = _x getVariable ["OTQA_track", _p];
                if (!(_x getVariable ["OTQA_crossed", false]) && { !(_p inPolygon _area) } && { _last inPolygon _area }) then {
                    _x setVariable ["OTQA_crossed", true];
                    private _at = (_p vectorAdd _last) vectorMultiply 0.5;
                    diag_log format ["OTCPCROSS|%1|%2|%3 -> %4|%5|%6|roads %7|near %8", _town, _tier, _last, _p, behaviour _x, isOnRoad _x, (_at nearRoads 6) apply { (getRoadInfo _x) select [0, 2] }, (nearestObjects [ASLToAGL (AGLToASL _at), [], 3]) apply { [typeOf _x, (getModelInfo _x) select 0, getPosATL _x, round ((boundingBoxReal _x) select 2)] }];
                };
                _x setVariable ["OTQA_track", _p];
            } forEach (_men select { alive _x });
            sleep 0.25;
        };
    };
    if (_tier >= 4) then {
        private _from = getPosATL leader _pg;
        [leader _pg, [0, -14, 16]] call OTQA_og_camera;
        for "_i" from 1 to 20 do {
            sleep 1;
            {
                if (!(_x getVariable ["OTQA_out", false]) && { [getPosATL _x, _area] call OT_fnc_officeOutside }) then {
                    _x setVariable ["OTQA_out", true];
                    diag_log format ["OTCPOUT|%1|%2|loop|patrol|%3|a second before %4|wp %5 at %6", _town, _tier, getPosATL _x, _x getVariable ["OTQA_last", []], currentWaypoint _pg, waypointPosition [_pg, currentWaypoint _pg]];
                };
                _x setVariable ["OTQA_last", getPosATL _x];
            } forEach units _pg;
        };
        private _moved = (leader _pg) distance2D _from;
        private _inside = ((units _pg) findIf { [getPosATL _x, _area] call OT_fnc_officeOutside }) < 0;
        [format ["Garrison %1: the patrol walks its loop, inside the walls", _tag], _moved > 4 && _inside, format ["leader %1 m on, all inside %2", round _moved, _inside]] call OTQA_fnc_check;
    };
    // The hunt
    { _x allowDamage false } forEach _guards;
    private _hq = _town call OTQA_og_officePos;
    // One of the town's gendarmes 150 m off
    private _gg = createGroup [blufor, true];
    private _gendarme = _gg createUnit ["B_GEN_Soldier_F", _hq vectorAdd [150, 0, 0], [], 0, "NONE"];
    _gendarme setVariable ["garrison", _town];
    _gendarme allowDamage false;
    // A threat 25 m outside the wall, shown to the garrison
    private _corner = _area select 0;
    private _out = _corner vectorAdd ((vectorNormalized (_corner vectorDiff _hq)) vectorMultiply 25);
    _out set [2, 0];
    private _eg = createGroup [independent, true];
    private _enemy = _eg createUnit ["I_soldier_F", _out, [], 0, "CAN_COLLIDE"];
    _enemy allowDamage false;
    _enemy disableAI "MOVE";
    { _x reveal [_enemy, 4] } forEach _guards;
    [leader ([_rgroups param [0, grpNull], _pg] select (_tier >= 4)), [0, -16, 18]] call OTQA_og_camera;
    private _t = time + 40;
    private _outside = 0;
    private _resOut = 0;
    private _resMoved = 0;
    waitUntil {
        sleep 1;
        _outside = _outside max ({ alive _x && { [getPosATL _x, _area] call OT_fnc_officeOutside } } count _patrol);
        _resOut = _resOut max ({ alive _x && { [getPosATL _x, _area] call OT_fnc_officeOutside } } count _reserve);
        _resMoved = _resMoved max ({ alive _x && { (_x distance2D (_x getVariable ["OT_reserveHome", getPosATL _x])) > 2 } } count _reserve);
        // Where a man got out (OTCPOUT lines in the RPT, the first time each)
        {
            if (alive _x && { !(_x getVariable ["OTQA_out", false]) } && { [getPosATL _x, _area] call OT_fnc_officeOutside }) then {
                _x setVariable ["OTQA_out", true];
                diag_log format ["OTCPOUT|%1|%2|hunt|%3|%4|a second before %5|from %6|%7|%8", _town, _tier, ["reserve", "patrol"] select (_x in _patrol), getPosATL _x, _x getVariable ["OTQA_last", []], _x getVariable ["OT_reserveHome", []], behaviour _x, currentCommand _x];
            };
            _x setVariable ["OTQA_last", getPosATL _x];
        } forEach (_patrol + _reserve);
        time > _t
    };
    private _sent = ((waypoints _gg) findIf { (waypointType _x) isEqualTo "SAD" && { ((waypointPosition _x) distance2D _hq) < 80 } && { !((waypointPosition _x) inPolygon _area) } }) > -1; // To the gate, outside
    private _hunted = (_patrol findIf { (behaviour _x) isEqualTo "COMBAT" }) > -1;
    private _roused = (_reserve findIf { (behaviour _x) in ["AWARE", "COMBAT"] }) > -1;
    private _car = (vehicles select { ((((_x getVariable ["OT_officeItem", []]) param [3, []]) param [0, ""]) isEqualTo "vehicle") && { ((_x getVariable ["OT_officeItem", []]) param [0, ""]) isEqualTo _town } }) param [0, objNull];
    private _siren = missionNamespace getVariable [format ["OT_compoundSiren%1", _town], objNull];
    private _sounding = !isNull _siren && { (_siren distance2D _hq) < 20 };
    private _crew = count crew _car;
    private _crewed = !isNull _car && { _crew > 0 } && { alive gunner _car };
    terminate _tracker;
    { deleteVehicle _x } forEach (crew _car);
    deleteVehicle _enemy;
    deleteVehicle _gendarme;
    [_spawned] call OTQA_cp_clear;
    if (_tier >= 4) then {
        [format ["Hunt %1: the patrol went to combat and never left the walls", _tag], _hunted && { _outside isEqualTo 0 }, format ["in combat %1, most outside at once %2", _hunted, _outside]] call OTQA_fnc_check;
    };
    [format ["Hunt %1: the reserve roused and on the move, never out of the walls", _tag], _roused && { _resMoved > 0 } && { _resOut isEqualTo 0 }, format ["roused %1, most off home at once %2, most outside at once %3", _roused, _resMoved, _resOut]] call OTQA_fnc_check;
    [format ["Hunt %1: the town's gendarmerie sent to the compound's gate, outside", _tag], _sent, str _sent] call OTQA_fnc_check;
    if (_xCar) then {
        [format ["Hunt %1: the parked armed car crewed at the alarm", _tag], _crewed, format ["%1, crew %2", typeOf _car, _crew]] call OTQA_fnc_check;
    } else {
        [format ["Hunt %1: no armed car in the layout, none made", _tag], isNull _car, typeOf _car] call OTQA_fnc_check;
    };
    [format ["Hunt %1: the siren sounds from the HQ", _tag], _sounding, format ["%1 (Sound_Alarm %2)", _siren, isClass (configFile >> "CfgVehicles" >> "Sound_Alarm")]] call OTQA_fnc_check;
    if (!isNull _siren) then { deleteVehicle _siren };
};
{
    _x params ["_town", "_tier"];
    _tests pushBack [format ["Compounds: the garrison at work and its hunt (%1 T%2)", _town, _tier], compile format ["[%1, %2] call OTQA_cp_garrisonTest", str _town, _tier], 120];
} forEach OTQA_cp_cases;

// Losses on one compound (the same code for every town and tier: what's lost comes off the reserve first and is
// paid back over time; the per-town data it reads, size and reserve, the garrison test covers)
_tests pushBack ["Compounds: the garrison's losses, paid back (Rodopoli T4)", {
    private _town = "Rodopoli";
    private _var = format ["compoundlost%1", _town];
    private _size = [_town, 4] call OTQA_cp_size;
    private _fullReserve = 0;
    { _fullReserve = _fullReserve + _x } forEach (([_town, 4] call OTQA_cp_expect) select 1);
    server setVariable [_var, [3, time]];
    private _spawned = [_town, 4] call OTQA_cp_spawn;
    private _first = count (_spawned select 0);
    private _reserveLeft = count ([_spawned select 0] call OTQA_cp_reserve);
    [_spawned] call OTQA_cp_clear;
    private _resources = server getVariable ["NATOresources", 2000];
    server setVariable ["NATOresources", 2000];
    server setVariable [_var, [3, time - 1250]];
    _spawned = [_town, 4] call OTQA_cp_spawn;
    private _second = count (_spawned select 0);
    private _paid = 2000 - (server getVariable ["NATOresources", 2000]);
    private _left = (server getVariable [_var, [0, 0]]) select 0;
    [_spawned] call OTQA_cp_clear;
    server setVariable ["NATOresources", _resources];
    ["Losses: three lost, three fewer made, the reserve's first", _first isEqualTo (_size - 3) && { _reserveLeft isEqualTo ((_fullReserve - 3) max 0) }, format ["%1 made of %2, %3 of the reserve's %4 left", _first, _size, _reserveLeft, _fullReserve]] call OTQA_fnc_check;
    ["Losses: 20 minutes on, two paid back (10 each), one still lost", _second isEqualTo (_size - 1) && { _paid isEqualTo 20 } && { _left isEqualTo 1 }, format ["%1 made of %2, %3 paid, %4 lost", _second, _size, _paid, _left]] call OTQA_fnc_check;
}, 60];

_tests pushBack ["Compounds: undercover inside the walls is spotted", {
    private _spawned = ["Rodopoli", 4] call OTQA_cp_spawn;
    _spawned params ["_guards"];
    private _area = server getVariable ["compoundareaRodopoli", []];
    private _post = (_guards select { !("patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []])) && { isNull objectParent _x } && { ((getPosATL _x) select 2) < 0.5 } && { (getPosATL _x) inPolygon _area } }) param [0, objNull];
    if (isNull _post) exitWith {
        [_spawned] call OTQA_cp_clear;
        ["Undercover: a guard on the ground inside", false, ""] call OTQA_fnc_check;
    };
    { _x allowDamage false; _x setCombatMode "BLUE" } forEach _guards;
    private _loadout = getUnitLoadout player;
    private _was = getPosATL player;
    removeAllWeapons player;
    player allowDamage false;
    // Outside first, 30 m off the wall: undercover kept
    private _hq = "Rodopoli" call OTQA_og_officePos;
    private _outside = (_area select 0) vectorAdd ((vectorNormalized ((_area select 0) vectorDiff _hq)) vectorMultiply 30);
    player setPosATL _outside;
    player setCaptive true;
    player setVariable ["SeenCacheNATO", nil];
    sleep 12;
    private _keptOutside = captive player;
    // Inside, 4 m from a guard
    private _in = (getPosATL _post) vectorAdd ((vectorNormalized (_hq vectorDiff (getPosATL _post))) vectorMultiply 4);
    _in set [2, 0];
    player setPosATL _in;
    player setCaptive true;
    player setVariable ["SeenCacheNATO", nil];
    private _t = time + 20;
    waitUntil { sleep 1; !(captive player) || { time > _t } };
    private _spotted = !(captive player);
    private _wasInside = _in inPolygon _area;
    player setPosATL _was;
    player setUnitLoadout _loadout;
    player setCaptive true;
    player allowDamage true;
    [_spawned] call OTQA_cp_clear;
    ["Undercover: kept outside the walls", _keptOutside, str _keptOutside] call OTQA_fnc_check;
    ["Undercover: seen inside the walls, cover lost", _wasInside && _spotted, format ["inside %1, spotted %2", _wasInside, _spotted]] call OTQA_fnc_check;
}, 60];

_tests
