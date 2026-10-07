/*
    Description:
    The occupier compounds' work in progress (tools/officegen/COMPOUND_PLAN.md, the Rodopoli pilot's step 4 on).
    Part of the current QA tests; the finished steps are in OTQA_fnc_testsOfficeGameplay (archived).
    1. Gates worked by the occupier: a closed gate opens for an occupier soldier, not for one of ours, shuts
       10 s after; the town taken opens and unlocks it
    2. An occupier soldier walks out of Rodopoli's T3 compound and back in through its gate shut (the path
       finding plans no way through a shut gate: it opens for one going somewhere within 40 m)
    3. Static weapons by role: the hmg role a machine gun, the vanilla AT static read as at
    4. The garrison (OT_fnc_officeGarrison through OT_fnc_spawnOffice, Rodopoli at T4): the guards made, the
       patrol its own group walking a loop inside the walls, the posts holding, aware, flashlights, no NVGs, the
       area published; losses kept off and paid back; the patrol hunting a threat outside but staying inside the
       walls, the town's gendarmerie sent over, the parked armed car crewed
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

_tests pushBack ["Office: the occupier's men walk out and in through a shut gate", {
    private _town = "Rodopoli";
    ([_town, 3, west, true] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];
    private _gate = (_objects select { "gate" in toLower typeOf _x }) param [0, objNull];
    private _marker = ((([_town] call OT_fnc_officeLayout) select 1) select 2) select { (_x select 0) isEqualTo "gate" };
    if (isNull _gate || { _marker isEqualTo [] }) exitWith {
        { deleteVehicle _x } forEach (_objects + _guards);
        ["Walk: Rodopoli's T3 gate found", false, format ["gate %1, markers %2", _gate, count _marker]] call OTQA_fnc_check;
    };
    // The gate shut, locked and worked by the occupier, as a closed gate is in play
    _gate setVariable ["bis_disabled_Door_1", 1, true];
    _gate setVariable ["bis_disabled_Door_2", 1, true];
    _gate setVariable ["OT_officeGate", true, true];
    _gate enableSimulationGlobal true;
    [_gate] call OT_fnc_officeGates;
    private _gp = ASLToAGL ((_marker select 0) select 2);
    private _hq = _town call OTQA_og_officePos;
    private _out = (_gp vectorDiff _hq) vectorMultiply (1 / ((_gp distance2D _hq) max 1));
    private _in = _gp vectorAdd (_out vectorMultiply -10);
    private _far = _gp vectorAdd (_out vectorMultiply 30);
    _in set [2, 0];
    _far set [2, 0];
    private _walk = {
        params ["_from", "_to"];
        sleep 12; // The gate shut again behind the last
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
    diag_log format ["OTGATEWALK|%1|out %2|in %3", _town, _outward, _inward];
    { deleteVehicle _x } forEach (_objects + _guards);
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
    ["Walk: an occupier soldier gets out through the shut gate", (_outward select 0) && { _outward select 1 }, format ["gate shut first %1, out %2 in %3 s", _outward select 0, _outward select 1, _outward select 2]] call OTQA_fnc_check;
    ["Walk: an occupier soldier gets in through the shut gate", (_inward select 0) && { _inward select 1 }, format ["gate shut first %1, in %2 in %3 s", _inward select 0, _inward select 1, _inward select 2]] call OTQA_fnc_check;
}, 240];

_tests pushBack ["Office: static weapons by role", {
    private _hmg = ["hmg"] call OT_fnc_officeStatic;
    private _weapon = (getArray (configFile >> "CfgVehicles" >> _hmg >> "Turrets" >> "MainTurret" >> "weapons")) param [0, ""];
    private _mag = (getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines")) param [0, ""];
    private _sim = getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _mag >> "ammo") >> "simulation");
    ["Statics: the hmg role is a machine gun (fires bullets)", _sim isEqualTo "shotBullet", format ["%1 fires %2", _hmg, _sim]] call OTQA_fnc_check;
    ["Statics: the vanilla AT static reads as at, the HMG as hmg", (["B_static_AT_F"] call OT_fnc_officeStatic) isEqualTo "at" && { (["B_HMG_01_high_F"] call OT_fnc_officeStatic) isEqualTo "hmg" }, format ["AT %1, HMG %2", ["B_static_AT_F"] call OT_fnc_officeStatic, ["B_HMG_01_high_F"] call OT_fnc_officeStatic]] call OTQA_fnc_check;
}, 10];

// Rodopoli's compound spawned by the game's own spawner at a tier, [guards, things, spawner id]
OTQA_cp_spawn = {
    params ["_tier"];
    private _town = "Rodopoli";
    server setVariable [format ["officetier%1", _town], _tier];
    private _id = format ["OTQA_compound%1", round (time * 100)];
    [_town, _id] call OT_fnc_spawnOffice;
    private _things = spawner getVariable [_id, []];
    private _guards = allUnits select { (_x getVariable ["OT_compoundGuard", ""]) isEqualTo _town };
    [_guards, _things, _id]
};
OTQA_cp_clear = {
    params ["_spawned"];
    _spawned params ["_guards", "_things", "_id"];
    call OTQA_og_cameraOff;
    { deleteVehicle _x } forEach (allUnits select { (_x getVariable ["OT_compoundGuard", ""]) isEqualTo "Rodopoli" });
    { if (_x isEqualType grpNull) then { { deleteVehicle _x } forEach units _x; deleteGroup _x } else { deleteVehicle _x } } forEach _things;
    spawner setVariable [_id, nil];
    server setVariable ["officetierRodopoli", nil];
    server setVariable ["compoundlostRodopoli", nil];
    server setVariable ["compoundareaRodopoli", nil, true];
    ["Rodopoli", ["Rodopoli"] call OT_fnc_officeTier] call OT_fnc_officeHide;
    ["Rodopoli", ["Rodopoli"] call OT_fnc_officeTier] call OT_fnc_officeDoors;
};
OTQA_cp_patrol = {
    params ["_guards"];
    _guards select { "patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]) }
};

_tests pushBack ["Compounds: the garrison at work", {
    private _spawned = [4] call OTQA_cp_spawn;
    _spawned params ["_guards"];
    private _patrol = [_guards] call OTQA_cp_patrol;
    private _posts = _guards - _patrol;
    private _pg = group (_patrol param [0, objNull]);
    private _area = server getVariable ["compoundareaRodopoli", []];
    private _cycle = ((waypoints _pg) findIf { (waypointType _x) isEqualTo "CYCLE" }) > -1;
    private _free = { _x checkAIFeature "PATH" } count _posts;
    private _unaware = { (behaviour _x) isNotEqualTo "AWARE" } count _guards;
    private _nvg = { hmd _x isNotEqualTo "" } count _guards;
    private _dark = { primaryWeapon _x isNotEqualTo "" && { ((primaryWeaponItems _x) select 1) isEqualTo "" } } count _guards;
    ["Garrison: T4's 15 men (14 guards, the HMG's gunner)", (count _guards) isEqualTo 15, str count _guards] call OTQA_fnc_check;
    ["Garrison: the patrol of four its own group, walking a loop", (count _patrol) isEqualTo 4 && { (count units _pg) isEqualTo 4 } && _cycle, format ["%1 in the patrol, %2 in its group, %3 waypoints", count _patrol, count units _pg, count waypoints _pg]] call OTQA_fnc_check;
    ["Garrison: the posts hold, everyone aware, flashlights, no NVGs", _free isEqualTo 0 && _unaware isEqualTo 0 && _nvg isEqualTo 0 && _dark isEqualTo 0, format ["posts free to walk %1, not aware %2, NVGs %3, no light %4", _free, _unaware, _nvg, _dark]] call OTQA_fnc_check;
    ["Garrison: the compound's area published for the undercover check", (count _area) > 2, str count _area] call OTQA_fnc_check;
    private _from = getPosATL leader _pg;
    [leader _pg, [0, -14, 16]] call OTQA_og_camera;
    sleep 30;
    private _moved = (leader _pg) distance2D _from;
    private _inside = ((units _pg) findIf { [getPosATL _x, _area] call OT_fnc_officeOutside }) < 0;
    ["Garrison: the patrol walks its loop, inside the walls", _moved > 5 && _inside, format ["leader %1 m on, all inside %2", round _moved, _inside]] call OTQA_fnc_check;
    [_spawned] call OTQA_cp_clear;
}, 90];

_tests pushBack ["Compounds: the garrison's losses, paid back", {
    server setVariable ["compoundlostRodopoli", [3, time]];
    private _spawned = [4] call OTQA_cp_spawn;
    private _first = count (_spawned select 0);
    private _patrolLeft = count ([_spawned select 0] call OTQA_cp_patrol);
    [_spawned] call OTQA_cp_clear;
    private _resources = server getVariable ["NATOresources", 2000];
    server setVariable ["NATOresources", 2000];
    server setVariable ["compoundlostRodopoli", [3, time - 1250]];
    _spawned = [4] call OTQA_cp_spawn;
    private _second = count (_spawned select 0);
    private _paid = 2000 - (server getVariable ["NATOresources", 2000]);
    private _left = (server getVariable ["compoundlostRodopoli", [0, 0]]) select 0;
    [_spawned] call OTQA_cp_clear;
    server setVariable ["NATOresources", _resources];
    ["Losses: three lost, three fewer made, the patrol's first", _first isEqualTo 12 && { _patrolLeft isEqualTo 1 }, format ["%1 made, %2 of the patrol", _first, _patrolLeft]] call OTQA_fnc_check;
    ["Losses: 20 minutes on, two paid back (10 each), one still lost", _second isEqualTo 14 && { _paid isEqualTo 20 } && { _left isEqualTo 1 }, format ["%1 made, %2 paid, %3 lost", _second, _paid, _left]] call OTQA_fnc_check;
}, 60];

_tests pushBack ["Compounds: the patrol hunts inside the walls, the gendarmerie comes", {
    private _spawned = [4] call OTQA_cp_spawn;
    _spawned params ["_guards"];
    private _pg = group (([_guards] call OTQA_cp_patrol) param [0, objNull]);
    private _area = server getVariable ["compoundareaRodopoli", []];
    { _x allowDamage false } forEach _guards;
    // One of the town's gendarmes 150 m off
    private _hq = "Rodopoli" call OTQA_og_officePos;
    private _gg = createGroup [blufor, true];
    private _gendarme = _gg createUnit ["B_GEN_Soldier_F", _hq vectorAdd [150, 0, 0], [], 0, "NONE"];
    _gendarme setVariable ["garrison", "Rodopoli"];
    _gendarme allowDamage false;
    // A threat 25 m outside the wall, shown to the patrol
    private _corner = _area select 0;
    private _out = _corner vectorAdd ((vectorNormalized (_corner vectorDiff _hq)) vectorMultiply 25);
    private _eg = createGroup [independent, true];
    private _enemy = _eg createUnit ["I_soldier_F", _out, [], 0, "CAN_COLLIDE"];
    _enemy allowDamage false;
    _enemy disableAI "MOVE";
    { _x reveal [_enemy, 4] } forEach (units _pg);
    [leader _pg, [0, -16, 18]] call OTQA_og_camera;
    private _t = time + 40;
    private _outside = 0;
    waitUntil {
        sleep 1;
        _outside = _outside max ({ alive _x && { [getPosATL _x, _area] call OT_fnc_officeOutside } } count units _pg);
        {
            if (alive _x && { [getPosATL _x, _area] call OT_fnc_officeOutside }) then {
                private _g = (OT_officeGates select { alive _x }) apply { [_x distance2D (getPosATL _x), _x] };
                diag_log format ["OTHUNTOUT|%1 at %2|nearest gate %3 m, open %4|behaviour %5|command %6", typeOf _x, getPosATL _x, round (((nearestObjects [_x, ["Land_ConcreteWall_01_l_gate_F", "Land_NetFence_01_m_gate_F"], 60]) apply { _x distance2D (getPosATL _x) }) param [0, -1]), ((nearestObjects [_x, ["Land_ConcreteWall_01_l_gate_F", "Land_NetFence_01_m_gate_F"], 60]) apply { _x animationSourcePhase "Door_1_sound_source" }) param [0, -1], behaviour _x, currentCommand _x];
            };
        } forEach units _pg;
        time > _t
    };
    private _sent = ((waypoints _gg) findIf { (waypointType _x) isEqualTo "SAD" && { ((waypointPosition _x) distance2D _hq) < 60 } && { !((waypointPosition _x) inPolygon _area) } }) > -1; // To the gate, outside
    private _hunted = ((units _pg) findIf { (behaviour _x) isEqualTo "COMBAT" }) > -1;
    private _car = (vehicles select { ((((_x getVariable ["OT_officeItem", []]) param [3, []]) param [0, ""]) isEqualTo "vehicle") && { ((_x getVariable ["OT_officeItem", []]) param [0, ""]) isEqualTo "Rodopoli" } }) param [0, objNull];
    private _crew = count crew _car;
    private _crewed = !isNull _car && { _crew > 0 } && { alive gunner _car };
    { deleteVehicle _x } forEach (crew _car);
    deleteVehicle _enemy;
    deleteVehicle _gendarme;
    [_spawned] call OTQA_cp_clear;
    ["Hunt: the patrol went to combat and never left the walls", _hunted && { _outside isEqualTo 0 }, format ["in combat %1, most outside at once %2", _hunted, _outside]] call OTQA_fnc_check;
    ["Hunt: the town's gendarmerie sent to the compound's gate, outside", _sent, str _sent] call OTQA_fnc_check;
    ["Hunt: the parked armed car crewed at the alarm", _crewed, format ["%1, crew %2", typeOf _car, _crew]] call OTQA_fnc_check;
}, 90];

_tests pushBack ["Compounds: undercover inside the walls is spotted", {
    private _spawned = [4] call OTQA_cp_spawn;
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
