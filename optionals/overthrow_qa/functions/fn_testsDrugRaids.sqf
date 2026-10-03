/*
    Description:
    Occupier heat and raids on drug operations (drugs slice 3a: OT_fnc_drugHeat, OT_fnc_drugHeatTick,
    OT_fnc_drugRaidChance, OT_fnc_drugRaidCheck, OT_fnc_drugRaid), with real raids on the drug lab
    farthest from the host (a dispensary if the map has no lab), owned for the tests. Part of the
    current QA tests.
    1. Heat: blow adds 3 a unit, ganja 1, only on owned operations, saved in "drugHeat"; the cycles
       report it; the gang turf hook hears every call
    2. Decay: 1 a real minute (30 s a tick at most), the shut and cooldown timers count down, an
       operation reopens, one with nothing left is dropped
    3. Chance: none under 40 heat, grows with heat to 30% at 400 and no more, falls with stability
       (a quarter at 100), none shut, in cooldown or unowned
    4. The roll: the likeliest operation, held back by the roll, a QRF, a counter-attack and the
       occupier's resources; the military from 200 heat (300 paid), the gendarmerie under it (100);
       one at a time; none in the cooldown; none on an unowned operation even forced
    5. Warning: 2 minutes without intelligence, 10 with resistance support of 50 or a radio tower
       within 4 km of its town; task and marker on the operation; called off, the resources come back
    6. Gendarmerie raid: 4 in a police car from the nearest base, heading for the operation; the
       resistance holds it (forced): heat 0, cooldown, task succeeded
    7. Military raid the occupier wins (forced): ganja, blow and precursors seized, shut for an hour
       (its cycle does nothing, the business info says so), a quarter of the heat left; open again
       once the shut time is cleared
    8. A shut dispensary sells nothing until it reopens
    The fights' results are forced (OT_QRFforceResult) and their 10 minute set-up skipped
    (OT_QRFsetupTime); NATO turns and raid rolls are held off while the tests run.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Drug raids: in play, run a hot lab (cooking its full 18 blow a cycle): the business info's heat line climbs, the raid chance shows from 40 heat, and a raid comes with its task, the red marker on the lab and the warning (10 minutes with a radio tower near its town or support of 50, 2 without)" call OTQA_fnc_manual;
"Drug raids: watch a raid arrive: under 200 heat a police car with 4 gendarmes from the nearest base, from 200 the military's truck; the QRF progress bar shows; losing lists what was seized and the business info reads RAIDED for an hour, 'open again' shows when it ends" call OTQA_fnc_manual;
"Drug raids: save during a raid's warning and reload: the raid is gone, the heat, shut time and cooldown are kept" call OTQA_fnc_manual;

// Everything the tests change, to put back afterwards
OTQA_raid_save = {
    OT_nextNATOTurn = time + 3600; // No NATO turn while a test runs
    OT_drugRaidNextRoll = time + 3600; // And no raid roll of its own
    createHashMapFromArray [
        ["heat", +(server getVariable ["drugHeat", []])],
        ["ops", +(server getVariable ["drugOps", []])],
        ["owned", +(server getVariable ["GEURowned", []])],
        ["abandoned", +(server getVariable ["NATOabandoned", []])],
        ["resources", server getVariable ["NATOresources", 2000]],
        ["lastAttack", server getVariable ["NATOlastattack", 0]]
    ];
};
OTQA_raid_restore = {
    params ["_saved"];
    OT_drugRaidRoll = nil;
    OT_QRFsetupTime = nil;
    OT_QRFforceResult = nil;
    server setVariable ["drugHeat", _saved get "heat", true];
    server setVariable ["drugOps", _saved get "ops", true];
    server setVariable ["GEURowned", _saved get "owned", true];
    server setVariable ["NATOabandoned", _saved get "abandoned", true];
    server setVariable ["NATOresources", _saved get "resources", true];
    server setVariable ["NATOlastattack", _saved get "lastAttack", true];
    server setVariable ["drugRaidTarget", "", true];
    OT_drugRaidNextRoll = time + 120;
    OT_nextNATOTurn = time + 120;
};

// No QRF, counter-attack or raid running (waits up to 60 s for a QRF to end)
OTQA_raid_idle = {
    private _timeout = time + 60;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    (server getVariable ["NATOattacking", ""]) isEqualTo "" && { (server getVariable ["NATOcounterTarget", ""]) isEqualTo "" } && { (server getVariable ["drugRaidTarget", ""]) isEqualTo "" };
};

// The operation the tests use: the lab farthest from the host, a dispensary if the map has no lab
OTQA_raid_op = {
    private _sites = missionNamespace getVariable ["OT_drugLabSites", []];
    if (_sites isNotEqualTo []) exitWith {
        private _site = ([_sites, [], { (_x select 2) distance2D player }, "DESCEND"] call BIS_fnc_sortBy) select 0;
        [_site select 0, _site select 1, "lab", _site select 2]
    };
    private _shops = OT_dispensaries select { (_x call OT_fnc_getBusinessData) isNotEqualTo [] };
    private _name = ([_shops, [], { ((_x call OT_fnc_getBusinessData) select 0) distance2D player }, "DESCEND"] call BIS_fnc_sortBy) param [0, ""];
    if (_name isEqualTo "") exitWith { [] };
    [_name, _name, "dispensary", (_name call OT_fnc_getBusinessData) select 0]
};
// The resistance owns (or doesn't own) an operation for a test; owned, it's registered on drugOps
OTQA_raid_own = {
    params ["_op", ["_own", true]];
    _op params ["", "_name", "_type"];
    private _owned = (server getVariable ["GEURowned", []]) - [_name];
    if (_own) then {
        _owned pushBack _name;
        server setVariable ["GEURowned", _owned, true];
        if (_type isEqualTo "lab") then { _name call OT_fnc_drugLabRegister } else { [_name] call OT_fnc_dispensaryRegister };
    } else {
        server setVariable ["GEURowned", _owned, true];
    };
};
OTQA_raid_town = {
    params ["_op"];
    private _ops = server getVariable ["drugOps", []];
    (_ops param [_ops findIf { (_x select 0) isEqualTo (_op select 0) }, ["", "", [], ""]]) select 3
};
OTQA_raid_box = {
    params ["_op"];
    if ((_op select 2) isEqualTo "lab") then { (_op select 1) call OT_fnc_drugLabContainer } else { [_op select 3] call OT_fnc_dispensaryContainer }
};
// Its cycle, called directly: a lab's returns the blow made, a dispensary's its income
OTQA_raid_cycle = {
    params ["_op", "_num"];
    _op params ["", "_name", "_type", "_pos"];
    if (_type isEqualTo "lab") then { [_name, _pos, _num] call OT_fnc_drugLabCycle } else { [_name, _pos, _num] call OT_fnc_dispensaryCycle }
};
// How many of a class are in a container
OTQA_raid_count = {
    params ["_box", "_cls"];
    if (isNull _box) exitWith { 0 };
    private _n = 0;
    { if ((_x select 0) isEqualTo _cls) then { _n = _n + (_x select 1) } } forEach (_box call OT_fnc_unitStock);
    _n
};
// Empties the drugs and precursors out of the containers round a place, returns the containers there before
OTQA_raid_clearAround = {
    params ["_pos"];
    private _boxes = nearestObjects [_pos, [OT_item_CargoContainer], 50];
    {
        private _b = _x;
        { [_b, _x, 1000] call OT_fnc_removeFromCargo } forEach ["OT_Ganja", "OT_Blow", "OT_Precursors"];
    } forEach _boxes;
    _boxes
};
// The town's support and stability, to put back
OTQA_raid_townVars = {
    params ["_town"];
    [_town, server getVariable [format ["rep%1", _town], 0], server getVariable [format ["stability%1", _town], 50]];
};
OTQA_raid_townRestore = {
    params ["_town", "_rep", "_stability"];
    server setVariable [format ["rep%1", _town], _rep, true];
    server setVariable [format ["stability%1", _town], _stability, true];
};
// Calls off a raid in its warning
OTQA_raid_cancel = {
    private _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    _state set ["cancel", true];
    private _timeout = time + 10;
    waitUntil { sleep 0.5; (_state getOrDefault ["phase", ""]) isEqualTo "cancelled" || { time > _timeout } };
    (_state getOrDefault ["phase", ""]) isEqualTo "cancelled";
};
// Deletes the raiders and their vehicles
OTQA_raid_cleanForces = {
    {
        { if (!isNull objectParent _x) then { deleteVehicle objectParent _x }; deleteVehicle _x } forEach (units _x);
    } forEach (spawner getVariable ["NATOattackforce", []]);
    spawner setVariable ["NATOattackforce", [], false];
};

private _tests = [];

_tests pushBack ["Drug raids: heat per unit (blow 3, ganja 1), only on owned operations, the turf hook", {
    ["Heat: drug raids started (OT_fnc_initDrugRaids), drugHeat saved", !isNil "OT_drugRaidsInitDone" && { !isNil { server getVariable "drugHeat" } }, ""] call OTQA_fnc_check;
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Heat: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id", "_name", "_type", "_pos"];
    [_op] call OTQA_raid_own;
    [_id, 0, 0, 0] call OT_fnc_drugHeatSet;

    // The gang turf hook (slice 3b), stubbed while there's none
    private _stubbed = isNil "OT_fnc_drugTurf";
    OTQA_turfCalls = [];
    if (_stubbed) then { OT_fnc_drugTurf = { OTQA_turfCalls pushBack _this } };

    private _h1 = [_id, "ganja", 10] call OT_fnc_drugHeat;
    private _h2 = [_id, "blow", 10] call OT_fnc_drugHeat;
    ["Heat: 10 ganja add 10, 10 blow add 30", _h1 isEqualTo 10 && { _h2 isEqualTo 40 } && { (([_id] call OT_fnc_drugHeatGet) select 0) isEqualTo 40 }, format ["%1 then %2 on %3", _h1, _h2, _name]] call OTQA_fnc_check;
    ["Heat: saved in the server variable drugHeat as [id, heat, seconds shut, seconds of cooldown]", ((server getVariable ["drugHeat", []]) findIf { _x isEqualTo [_id, 40, 0, 0] }) > -1, str (server getVariable ["drugHeat", []])] call OTQA_fnc_check;

    // Not owned: nothing
    [_op, false] call OTQA_raid_own;
    private _h3 = [_id, "blow", 10] call OT_fnc_drugHeat;
    ["Heat: none on an operation the resistance doesn't own", _h3 isEqualTo 40 && { !([_id] call OT_fnc_drugOpOwned) }, format ["heat %1", _h3]] call OTQA_fnc_check;
    [_op] call OTQA_raid_own;
    ["Heat: none for something that's no drug operation", (["QA Not An Op", "blow", 5] call OT_fnc_drugHeat) isEqualTo 0, ""] call OTQA_fnc_check;
    if (_stubbed) then {
        ["Heat: the gang turf hook (OT_fnc_drugTurf) hears every call, owned or not", OTQA_turfCalls isEqualTo [[_id, "ganja", 10], [_id, "blow", 10], [_id, "blow", 10], ["QA Not An Op", "blow", 5]], str OTQA_turfCalls] call OTQA_fnc_check;
        OT_fnc_drugTurf = nil;
    } else {
        "Drug raids: OT_fnc_drugTurf exists (slice 3b), its calls weren't recorded: check it hears a dispensary's sales and a lab's batches" call OTQA_fnc_manual;
    };

    // The cycles report what they make and sell
    private _boxesBefore = [_pos] call OTQA_raid_clearAround;
    private _box = [_op] call OTQA_raid_box;
    [_id, 0] call OT_fnc_drugHeatSet;
    if (_type isEqualTo "lab") then {
        _box addItemCargoGlobal ["OT_Precursors", 2];
        private _made = [_op, 2] call OTQA_raid_cycle;
        ["Heat: a lab's batch heats it (2 precursors: 6 blow, 18 heat)", _made isEqualTo 6 && { (([_id] call OT_fnc_drugHeatGet) select 0) isEqualTo 18 }, format ["made %1, heat %2", _made, ([_id] call OT_fnc_drugHeatGet) select 0]] call OTQA_fnc_check;
    } else {
        _box addItemCargoGlobal ["OT_Ganja", 6];
        private _funds = [] call OT_fnc_resistanceFunds;
        [_op, 2] call OTQA_raid_cycle;
        server setVariable ["money", _funds, true];
        ["Heat: a dispensary's sales heat it (6 ganja: 6 heat)", (([_id] call OT_fnc_drugHeatGet) select 0) isEqualTo 6, format ["heat %1", ([_id] call OT_fnc_drugHeatGet) select 0]] call OTQA_fnc_check;
    };
    [_pos] call OTQA_raid_clearAround;
    if !(_box in _boxesBefore) then { deleteVehicle _box };
    [_saved] call OTQA_raid_restore;
}, 30];

_tests pushBack ["Drug raids: heat decays in real time, shut and cooldown count down, reopening", {
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Decay: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id"];
    [_op] call OTQA_raid_own;
    private _half = OT_drugHeatDecay * 0.5; // 30 s of decay
    [_id, 100, 50, 20] call OT_fnc_drugHeatSet;
    private _r = [];
    isNil {
        OT_drugHeatLast = time - 30;
        [] call OT_fnc_drugHeatTick;
        _r pushBack ([_id] call OT_fnc_drugHeatGet);
        OT_drugHeatLast = time - 30;
        [] call OT_fnc_drugHeatTick;
        _r pushBack ([_id] call OT_fnc_drugHeatGet);
    };
    (_r select 0) params ["_h1", "_s1", "_c1"];
    ["Decay: 30 s take half a heat (1 a minute) and 30 s off the timers", (abs (_h1 - (100 - _half))) < 0.01 && { _s1 isEqualTo 20 } && { _c1 isEqualTo 0 }, format ["heat %1, shut %2, cooldown %3 (100, 50, 20 before)", _h1, _s1, _c1]] call OTQA_fnc_check;
    (_r select 1) params ["_h2", "_s2"];
    ["Decay: the shut time runs out, the operation is open again", (abs (_h2 - (100 - (2 * _half)))) < 0.01 && { _s2 isEqualTo 0 } && { ([_id] call OT_fnc_drugOpShut) isEqualTo 0 }, format ["heat %1, shut %2", _h2, _s2]] call OTQA_fnc_check;

    // At most 30 s a tick, a long pause doesn't burn it all
    private _h3 = 0;
    isNil {
        [_id, 100] call OT_fnc_drugHeatSet;
        OT_drugHeatLast = time - 600;
        [] call OT_fnc_drugHeatTick;
        _h3 = ([_id] call OT_fnc_drugHeatGet) select 0;
    };
    ["Decay: at most 30 s a tick", (abs (_h3 - (100 - _half))) < 0.01, format ["heat %1", _h3]] call OTQA_fnc_check;

    // Nothing left: off the list
    isNil {
        [_id, _half * 0.5, 0, 0] call OT_fnc_drugHeatSet;
        OT_drugHeatLast = time - 30;
        [] call OT_fnc_drugHeatTick;
    };
    ["Decay: an operation with no heat and no timers left is dropped from drugHeat", ((server getVariable ["drugHeat", []]) findIf { (_x select 0) isEqualTo _id }) isEqualTo -1 && { ([_id] call OT_fnc_drugHeatGet) isEqualTo [0, 0, 0] }, str (server getVariable ["drugHeat", []])] call OTQA_fnc_check;
    [_saved] call OTQA_raid_restore;
}, 30];

_tests pushBack ["Drug raids: the chance grows with heat and falls with stability", {
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Chance: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id"];
    [_op] call OTQA_raid_own;
    private _town = [_op] call OTQA_raid_town;
    private _vars = [_town] call OTQA_raid_townVars;
    private _full = OT_drugRaidHeatFull;
    private _max = OT_drugRaidChanceMax;
    private _at = {
        params ["_heat", "_stability", ["_shut", 0], ["_cooldown", 0]];
        [_id, _heat, _shut, _cooldown] call OT_fnc_drugHeatSet;
        server setVariable [format ["stability%1", _town], _stability, true];
        [_id] call OT_fnc_drugRaidChance
    };
    private _c = [[0, 0], [OT_drugRaidHeatMin - 1, 0], [OT_drugRaidHeatMin, 0], [_full / 2, 0], [_full / 2, 50], [_full, 0], [_full * 2, 0], [_full, 100], [_full, 0, 100, 0], [_full, 0, 0, 100]] apply { _x call _at };
    ["Chance: none under 40 heat, some from it", (_c select 0) isEqualTo 0 && { (_c select 1) isEqualTo 0 } && { (_c select 2) > 0 }, format ["0: %1, 39: %2, 40: %3", _c select 0, _c select 1, _c select 2]] call OTQA_fnc_check;
    ["Chance: grows with heat (stability 0): 200 heat 15%, 400 30%, no more past that", (abs ((_c select 3) - (_max / 2))) < 0.01 && { (abs ((_c select 5) - _max)) < 0.01 } && { (abs ((_c select 6) - _max)) < 0.01 },
        format ["200: %1, 400: %2, 800: %3", _c select 3, _c select 5, _c select 6]] call OTQA_fnc_check;
    ["Chance: falls with stability: 200 heat at 50 is 7.5%, 400 at 100 is 7.5% (a quarter, the floor)", (abs ((_c select 4) - (_max / 4))) < 0.01 && { (abs ((_c select 7) - (_max * OT_drugRaidStabilityFloor))) < 0.01 },
        format ["200 at 50: %1, 400 at 100: %2", _c select 4, _c select 7]] call OTQA_fnc_check;
    ["Chance: none while shut or in its cooldown", (_c select 8) isEqualTo 0 && { (_c select 9) isEqualTo 0 }, format ["shut: %1, cooldown: %2", _c select 8, _c select 9]] call OTQA_fnc_check;
    [_id, _full, 0, 0] call OT_fnc_drugHeatSet;
    [_op, false] call OTQA_raid_own;
    ["Chance: none on an operation the resistance doesn't own", ([_id] call OT_fnc_drugRaidChance) isEqualTo 0, ""] call OTQA_fnc_check;
    _vars call OTQA_raid_townRestore;
    [_saved] call OTQA_raid_restore;
}, 30];

_tests pushBack ["Drug raids: the roll, who comes, one at a time, cooldown, the strength paid", {
    if !(call OTQA_raid_idle) exitWith { ["Roll: no QRF, counter-attack or raid running first", false, format ["attacking '%1', counter-attack '%2', raid '%3'", server getVariable ["NATOattacking", ""], server getVariable ["NATOcounterTarget", ""], server getVariable ["drugRaidTarget", ""]]] call OTQA_fnc_check };
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Roll: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id", "_name"];
    [_op] call OTQA_raid_own;
    private _town = [_op] call OTQA_raid_town;
    private _vars = [_town] call OTQA_raid_townVars;
    server setVariable [format ["stability%1", _town], 0, true];
    // The test's operation is the only hot one
    server setVariable ["drugHeat", [[_id, OT_drugRaidHeatFull, 0, 0]], true];
    server setVariable ["NATOresources", 2000, true];
    private _r = [];
    isNil {
        OT_drugRaidRoll = 100; // The roll never passes
        _r pushBack [[] call OT_fnc_drugRaidCheck, OT_drugRaidChance];
        OT_drugRaidRoll = 0; // Always passes
        server setVariable ["NATOattacking", "QA", true];
        _r pushBack ([] call OT_fnc_drugRaidCheck);
        server setVariable ["NATOattacking", "", true];
        server setVariable ["NATOcounterTarget", "QA", true];
        _r pushBack ([] call OT_fnc_drugRaidCheck);
        server setVariable ["NATOcounterTarget", "", true];
        server setVariable ["NATOresources", 299, true];
        _r pushBack ([] call OT_fnc_drugRaidCheck);
        server setVariable ["NATOresources", 2000, true];
    };
    (_r select 0) params ["_s0", "_chance"];
    ["Roll: the likeliest operation is rolled against (30% at 400 heat, stability 0), the roll can fail", !_s0 && { (abs (_chance - OT_drugRaidChanceMax)) < 0.01 } && { (server getVariable ["drugRaidTarget", ""]) isEqualTo "" }, format ["started %1, chance %2", _s0, _chance]] call OTQA_fnc_check;
    ["Roll: none while a QRF is being fought", !(_r select 1), ""] call OTQA_fnc_check;
    ["Roll: none while a counter-attack is on the way", !(_r select 2), ""] call OTQA_fnc_check;
    ["Roll: none the occupier can't pay for (a military raid costs 300)", !(_r select 3), ""] call OTQA_fnc_check;

    // It starts: the military from 200 heat, 300 paid, one at a time
    private _started = [false, "", 100000] call OT_fnc_drugRaidCheck;
    sleep 1;
    private _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    ["Roll: it starts on the hot operation, the military (heat 200+), 300 resources paid", _started && { (server getVariable ["drugRaidTarget", ""]) isEqualTo _id } && { (_state getOrDefault ["op", ""]) isEqualTo _id } && { (_state getOrDefault ["forces", ""]) isEqualTo "military" } && { (server getVariable ["NATOresources", 0]) isEqualTo 1700 },
        format ["started %1, target '%2', forces %3, resources %4", _started, server getVariable ["drugRaidTarget", ""], _state getOrDefault ["forces", ""], server getVariable ["NATOresources", 0]]] call OTQA_fnc_check;
    ["Roll: one raid at a time, even forced", !([true, _id, 0] call OT_fnc_drugRaidCheck), ""] call OTQA_fnc_check;
    private _cancelled = call OTQA_raid_cancel;
    sleep 1;
    ["Roll: called off, the resources come back", _cancelled && { (server getVariable ["NATOresources", 0]) isEqualTo 2000 } && { (server getVariable ["drugRaidTarget", ""]) isEqualTo "" }, format ["cancelled %1, resources %2", _cancelled, server getVariable ["NATOresources", 0]]] call OTQA_fnc_check;

    // The gendarmerie under 200 heat, 100 paid
    [_id, OT_drugRaidMilitaryHeat - 1] call OT_fnc_drugHeatSet;
    _started = [false, "", 100000] call OT_fnc_drugRaidCheck;
    sleep 1;
    _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    ["Roll: under 200 heat the gendarmerie comes, 100 paid", _started && { (_state getOrDefault ["forces", ""]) isEqualTo "police" } && { (server getVariable ["NATOresources", 0]) isEqualTo 1900 },
        format ["started %1, forces %2, resources %3", _started, _state getOrDefault ["forces", ""], server getVariable ["NATOresources", 0]]] call OTQA_fnc_check;
    call OTQA_raid_cancel;
    sleep 1;

    // Held back by the operation's cooldown
    [_id, OT_drugRaidHeatFull, 0, 600] call OT_fnc_drugHeatSet;
    ["Roll: none in the operation's cooldown", !([] call OT_fnc_drugRaidCheck) && { OT_drugRaidChance isEqualTo 0 }, format ["chance %1", OT_drugRaidChance]] call OTQA_fnc_check;

    // Not owned: nothing, even forced
    [_id, OT_drugRaidHeatFull, 0, 0] call OT_fnc_drugHeatSet;
    [_op, false] call OTQA_raid_own;
    ["Roll: no raid on an operation the resistance doesn't own, even forced", !([true, _id, 0] call OT_fnc_drugRaidCheck) && { (server getVariable ["drugRaidTarget", ""]) isEqualTo "" }, ""] call OTQA_fnc_check;

    _vars call OTQA_raid_townRestore;
    [_saved] call OTQA_raid_restore;
}, 60];

_tests pushBack ["Drug raids: 2 minutes' warning without intelligence, 10 with, task and marker on the operation", {
    if !(call OTQA_raid_idle) exitWith { ["Warning: no QRF, counter-attack or raid running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Warning: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id", "_name", "_type", "_pos"];
    [_op] call OTQA_raid_own;
    private _town = [_op] call OTQA_raid_town;
    private _vars = [_town] call OTQA_raid_townVars;
    private _bases = (OT_objectiveData + OT_airportData) apply { _x select 1 };
    [_id, 100, 0, 0] call OT_fnc_drugHeatSet;
    server setVariable ["NATOresources", 2000, true];

    // No intelligence: no tower held, support 0
    server setVariable ["NATOabandoned", (_saved get "abandoned") select { _x in _bases }, true];
    server setVariable [format ["rep%1", _town], 0, true];
    private _intel = [_town] call OT_fnc_NATOcounterIntel;
    private _started = [true, _id] call OT_fnc_drugRaidCheck;
    sleep 1;
    private _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    private _warning = _state getOrDefault ["warning", -1];
    private _left = (_state getOrDefault ["attackAt", 0]) - time;
    ["Warning: 2 minutes without intelligence", !_intel && { _started } && { _warning isEqualTo 120 } && { _left > 110 && _left <= 120 }, format ["intel %1, started %2, warning %3 s, %4 s left", _intel, _started, _warning, round _left]] call OTQA_fnc_check;
    private _task = _state getOrDefault ["task", ""];
    private _markers = _state getOrDefault ["markers", []];
    ["Warning: a task and a marker on the operation", [_task] call BIS_fnc_taskExists && { _markers isNotEqualTo [] } && { (_markers findIf { !(_x in allMapMarkers) }) isEqualTo -1 } && { (_markers findIf { ((getMarkerPos _x) distance2D _pos) > 10 }) isEqualTo -1 },
        format ["task %1, markers %2 at %3", _task, _markers, _markers apply { round ((getMarkerPos _x) distance2D _pos) }]] call OTQA_fnc_check;
    private _cancelled = call OTQA_raid_cancel;
    sleep 1;
    ["Warning: called off, task cancelled, markers gone, resources back", _cancelled && { ([_task] call BIS_fnc_taskState) isEqualTo "CANCELED" } && { (_markers findIf { _x in allMapMarkers }) isEqualTo -1 }
        && { (server getVariable ["NATOresources", 0]) isEqualTo 2000 } && { (server getVariable ["drugRaidTarget", ""]) isEqualTo "" },
        format ["phase %1, task %2, resources %3", _state getOrDefault ["phase", ""], [_task] call BIS_fnc_taskState, server getVariable ["NATOresources", 0]]] call OTQA_fnc_check;

    // Support of 50 in its town
    server setVariable [format ["rep%1", _town], 50, true];
    _intel = [_town] call OT_fnc_NATOcounterIntel;
    _started = [true, _id] call OT_fnc_drugRaidCheck;
    sleep 1;
    _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    ["Warning: 10 minutes with support of 50 in its town", _intel && { _started } && { (_state getOrDefault ["warning", -1]) isEqualTo 600 }, format ["%1: intel %2, warning %3 s", _town, _intel, _state getOrDefault ["warning", -1]]] call OTQA_fnc_check;
    call OTQA_raid_cancel;
    sleep 1;
    server setVariable [format ["rep%1", _town], 0, true];

    // A radio tower held within 4 km of its town
    private _townPos = server getVariable [_town, [0, 0, 0]];
    private _i = OT_NATOComms findIf { ((_x select 0) distance2D _townPos) < 3500 };
    if (_i < 0) then {
        format ["Drug raids: no radio tower within 3.5 km of %1, check the tower intelligence on a raid by hand", _town] call OTQA_fnc_manual;
    } else {
        private _tower = (OT_NATOComms select _i) select 1;
        server setVariable ["NATOabandoned", (server getVariable ["NATOabandoned", []]) + [_tower], true];
        _intel = [_town] call OT_fnc_NATOcounterIntel;
        _started = [true, _id] call OT_fnc_drugRaidCheck;
        sleep 1;
        _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
        ["Warning: 10 minutes with a radio tower near its town", _intel && { _started } && { (_state getOrDefault ["warning", -1]) isEqualTo 600 }, format ["%1, intel %2, warning %3 s", _tower, _intel, _state getOrDefault ["warning", -1]]] call OTQA_fnc_check;
        call OTQA_raid_cancel;
        sleep 1;
    };

    // No longer owned in the warning: called off by itself
    _started = [true, _id, 100000] call OT_fnc_drugRaidCheck;
    sleep 1;
    _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    [_op, false] call OTQA_raid_own;
    private _timeout = time + 10;
    waitUntil { sleep 0.5; (_state getOrDefault ["phase", ""]) isEqualTo "cancelled" || { time > _timeout } };
    ["Warning: called off by itself once the resistance no longer owns the operation", _started && { (_state getOrDefault ["phase", ""]) isEqualTo "cancelled" } && { (server getVariable ["drugRaidTarget", ""]) isEqualTo "" }, format ["phase %1", _state getOrDefault ["phase", ""]]] call OTQA_fnc_check;

    _vars call OTQA_raid_townRestore;
    [_saved] call OTQA_raid_restore;
}, 90];

_tests pushBack ["Drug raids: the gendarmerie from the nearest base heads for the operation, the resistance holds it", {
    if !(call OTQA_raid_idle) exitWith { ["Gendarmerie: no QRF, counter-attack or raid running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Gendarmerie: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id", "_name", "_type", "_pos"];
    [_op] call OTQA_raid_own;
    [_id, 100, 0, 0] call OT_fnc_drugHeatSet; // Under 200: the gendarmerie
    server setVariable ["NATOresources", 2000, true];
    ([_pos] call OT_fnc_NATOGetAttackVectors) params ["_ground", "_air"];
    private _expected = (_ground + _air) param [0, []];
    if (_expected isEqualTo []) exitWith { ["Gendarmerie: an occupier base to come from", false, _name] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };

    OT_QRFsetupTime = 100000; // Held until the raiders have been checked
    spawner setVariable ["NATOattackforce", [], false];
    private _started = [true, _id, 0] call OT_fnc_drugRaidCheck;
    private _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    private _timeout = time + 20;
    waitUntil { sleep 0.5; (count (spawner getVariable ["NATOattackforce", []])) > 0 || { time > _timeout } };
    private _from = _state getOrDefault ["from", []];
    ["Gendarmerie: from the nearest base", _started && { (_from param [1, ""]) isEqualTo (_expected select 1) },
        format ["from %1, expected %2 (by road: %3), %4 m from %5", _from param [1, ""], _expected select 1, _ground isNotEqualTo [], round ((_expected select 0) distance2D _pos), _name]] call OTQA_fnc_check;
    private _groups = spawner getVariable ["NATOattackforce", []];
    private _units = [];
    { _units append (units _x) } forEach _groups;
    if (_state getOrDefault ["byAir", false]) then {
        ["Gendarmerie: no base by road, so the raid is flown in by the military instead", (_state getOrDefault ["forces", ""]) isEqualTo "military" && { _groups isNotEqualTo [] }, format ["forces %1, %2 groups", _state getOrDefault ["forces", ""], count _groups]] call OTQA_fnc_check;
    } else {
        private _types = [OT_NATO_Unit_PoliceCommander_Heavy, OT_NATO_Unit_Police_Heavy] apply { toLowerANSI _x };
        private _gendarmes = _units select { (toLowerANSI typeOf _x) in _types };
        private _inCar = _units select { (typeOf objectParent _x) isEqualTo OT_NATO_Vehicle_Police };
        ["Gendarmerie: 4 gendarmes in a police car, set off from the base", (count _groups) isEqualTo 1 && { (count _units) isEqualTo 4 } && { (count _gendarmes) isEqualTo 4 } && { (count _inCar) isEqualTo 4 } && { ((leader (_groups select 0)) distance2D (_expected select 0)) < 500 },
            format ["%1 groups, %2 units (%3 gendarmes, %4 in a %5), %6 m from %7", count _groups, count _units, count _gendarmes, count _inCar, OT_NATO_Vehicle_Police, if (_groups isEqualTo []) then { -1 } else { round ((leader (_groups select 0)) distance2D (_expected select 0)) }, _expected select 1]] call OTQA_fnc_check;
    };
    _timeout = time + 30;
    private _heading = {
        _groups select { ((waypoints _x) findIf { ((waypointPosition _x) distance2D _pos) < 250 }) > -1 }
    };
    waitUntil { sleep 1; (count (call _heading)) isEqualTo (count _groups) || { time > _timeout } };
    ["Gendarmerie: heading for the operation", _groups isNotEqualTo [] && { (count (call _heading)) isEqualTo (count _groups) },
        format ["%1 of %2 groups with a waypoint at %3", count (call _heading), count _groups, _name]] call OTQA_fnc_check;
    ["Gendarmerie: the operation is under attack (one QRF at a time)", (server getVariable ["NATOattacking", ""]) isEqualTo _name && { (_state getOrDefault ["phase", ""]) isEqualTo "attack" }, format ["attacking '%1', phase %2", server getVariable ["NATOattacking", ""], _state getOrDefault ["phase", ""]]] call OTQA_fnc_check;

    // The resistance holds it
    OT_QRFforceResult = -1;
    OT_QRFsetupTime = 0;
    _timeout = time + 30;
    waitUntil { sleep 1; (_state getOrDefault ["phase", ""]) isEqualTo "done" || { time > _timeout } };
    sleep 1;
    private _task = _state getOrDefault ["task", ""];
    ([_id] call OT_fnc_drugHeatGet) params ["_heat", "_shut", "_cooldown"];
    ["Resistance holds: the heat is gone, nothing shut, the cooldown set, task succeeded", !(_state getOrDefault ["won", true]) && { _heat isEqualTo 0 } && { _shut isEqualTo 0 } && { _cooldown > (OT_drugRaidCooldown - 60) && _cooldown <= OT_drugRaidCooldown }
        && { ([_task] call BIS_fnc_taskState) isEqualTo "SUCCEEDED" } && { (server getVariable ["drugRaidTarget", "?"]) isEqualTo "" } && { (server getVariable ["NATOattacking", "?"]) isEqualTo "" },
        format ["phase %1, won %2, heat %3, shut %4, cooldown %5, task %6", _state getOrDefault ["phase", ""], _state getOrDefault ["won", "?"], _heat, _shut, _cooldown, [_task] call BIS_fnc_taskState]] call OTQA_fnc_check;

    call OTQA_raid_cleanForces;
    [_saved] call OTQA_raid_restore;
}, 120];

_tests pushBack ["Drug raids: the military raid the occupier wins seizes the stock and shuts the operation", {
    if !(call OTQA_raid_idle) exitWith { ["Occupier wins: no QRF, counter-attack or raid running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_raid_save;
    private _op = call OTQA_raid_op;
    if (_op isEqualTo []) exitWith { ["Occupier wins: a drug operation to test with", false, "no lab or dispensary on this map"] call OTQA_fnc_check; [_saved] call OTQA_raid_restore };
    _op params ["_id", "_name", "_type", "_pos"];
    [_op] call OTQA_raid_own;
    private _boxesBefore = [_pos] call OTQA_raid_clearAround;
    private _box = [_op] call OTQA_raid_box;
    _box addItemCargoGlobal ["OT_Ganja", 5];
    _box addItemCargoGlobal ["OT_Blow", 4];
    _box addItemCargoGlobal ["OT_Precursors", 3];
    [_id, 300, 0, 0] call OT_fnc_drugHeatSet; // 200 and over: the military
    server setVariable ["NATOresources", 2000, true];

    OT_QRFsetupTime = 0;
    OT_QRFforceResult = 1;
    spawner setVariable ["NATOattackforce", [], false];
    private _started = [true, _id, 0] call OT_fnc_drugRaidCheck;
    private _state = missionNamespace getVariable ["OT_drugRaidState", createHashMap];
    private _timeout = time + 60;
    waitUntil { sleep 1; (_state getOrDefault ["phase", ""]) isEqualTo "done" || { time > _timeout } };
    sleep 1;

    private _task = _state getOrDefault ["task", ""];
    ["Occupier wins: the military came (heat 200+), the raid is won", _started && { (_state getOrDefault ["forces", ""]) isEqualTo "military" } && { _state getOrDefault ["won", false] },
        format ["started %1, forces %2, phase %3, won %4", _started, _state getOrDefault ["forces", ""], _state getOrDefault ["phase", ""], _state getOrDefault ["won", "?"]]] call OTQA_fnc_check;
    private _counts = ["OT_Ganja", "OT_Blow", "OT_Precursors"] apply { [_box, _x] call OTQA_raid_count };
    ["Occupier wins: 5 ganja, 4 blow and 3 precursors seized, the container empty", (_state getOrDefault ["seized", []]) isEqualTo [5, 4, 3] && { _counts isEqualTo [0, 0, 0] }, format ["seized %1, left %2", _state getOrDefault ["seized", []], _counts]] call OTQA_fnc_check;
    ([_id] call OT_fnc_drugHeatGet) params ["_heat", "_shut", "_cooldown"];
    ["Occupier wins: shut for an hour, a quarter of the heat left, the cooldown set", _shut > (OT_drugRaidShutTime - 60) && { _shut <= OT_drugRaidShutTime } && { (abs (_heat - (300 * OT_drugRaidHeatAfterWin))) < 0.01 } && { _cooldown > (OT_drugRaidCooldown - 60) && _cooldown <= OT_drugRaidCooldown },
        format ["shut %1 s, heat %2, cooldown %3 s", _shut, _heat, _cooldown]] call OTQA_fnc_check;
    ["Occupier wins: task failed, markers gone, nothing under attack", ([_task] call BIS_fnc_taskState) isEqualTo "FAILED" && { ((_state getOrDefault ["markers", []]) findIf { _x in allMapMarkers }) isEqualTo -1 } && { (server getVariable ["drugRaidTarget", "?"]) isEqualTo "" } && { (server getVariable ["NATOattacking", "?"]) isEqualTo "" },
        format ["task %1", [_task] call BIS_fnc_taskState]] call OTQA_fnc_check;

    // Shut: its cycle does nothing, the business info says so; cleared, it works again
    ["Occupier wins: the business info reads RAIDED", "RAIDED" in ([_name] call OT_fnc_drugOpInfo), [_name] call OT_fnc_drugOpInfo] call OTQA_fnc_check;
    private _funds = [] call OT_fnc_resistanceFunds;
    if (_type isEqualTo "lab") then {
        _box addItemCargoGlobal ["OT_Precursors", 2];
        private _made = [_op, 2] call OTQA_raid_cycle;
        ["Occupier wins: the shut lab cooks nothing", _made isEqualTo 0 && { ([_box, "OT_Precursors"] call OTQA_raid_count) isEqualTo 2 } && { ([_box, "OT_Blow"] call OTQA_raid_count) isEqualTo 0 }, format ["made %1", _made]] call OTQA_fnc_check;
        [_id, -1, 0] call OT_fnc_drugHeatSet;
        _made = [_op, 2] call OTQA_raid_cycle;
        ["Occupier wins: open again, it cooks (2 precursors into 6 blow)", _made isEqualTo 6 && { ([_box, "OT_Blow"] call OTQA_raid_count) isEqualTo 6 }, format ["made %1", _made]] call OTQA_fnc_check;
    } else {
        _box addItemCargoGlobal ["OT_Ganja", 6];
        private _income = [_op, 2] call OTQA_raid_cycle;
        ["Occupier wins: the shut dispensary sells nothing", _income isEqualTo 0 && { ([_box, "OT_Ganja"] call OTQA_raid_count) isEqualTo 6 }, format ["income %1", _income]] call OTQA_fnc_check;
        [_id, -1, 0] call OT_fnc_drugHeatSet;
        _income = [_op, 2] call OTQA_raid_cycle;
        ["Occupier wins: open again, it sells (6 ganja)", _income > 0 && { ([_box, "OT_Ganja"] call OTQA_raid_count) isEqualTo 0 }, format ["income %1", _income]] call OTQA_fnc_check;
    };
    server setVariable ["money", _funds, true];

    [_pos] call OTQA_raid_clearAround;
    if !(_box in _boxesBefore) then { deleteVehicle _box };
    call OTQA_raid_cleanForces;
    [_saved] call OTQA_raid_restore;
}, 120];

_tests pushBack ["Drug raids: a shut dispensary sells nothing until it reopens", {
    private _name = OT_dispensaries param [0, ""];
    if (_name isEqualTo "" || { (_name call OT_fnc_getBusinessData) isEqualTo [] }) exitWith { "Drug raids: no dispensary on this map to check a shut one sells nothing" call OTQA_fnc_manual };
    private _saved = call OTQA_raid_save;
    private _pos = (_name call OT_fnc_getBusinessData) select 0;
    private _op = [_name, _name, "dispensary", _pos];
    [_op] call OTQA_raid_own;
    private _boxesBefore = [_pos] call OTQA_raid_clearAround;
    private _box = [_op] call OTQA_raid_box;
    _box addItemCargoGlobal ["OT_Ganja", 6];
    private _funds = [] call OT_fnc_resistanceFunds;

    [_name, -1, 600] call OT_fnc_drugHeatSet;
    private _income = [_op, 2] call OTQA_raid_cycle;
    ["Shut dispensary: sells nothing, the stock stays, the info reads RAIDED", _income isEqualTo 0 && { ([_box, "OT_Ganja"] call OTQA_raid_count) isEqualTo 6 } && { "RAIDED" in ([_name] call OT_fnc_drugOpInfo) }, format ["income %1, ganja %2", _income, [_box, "OT_Ganja"] call OTQA_raid_count]] call OTQA_fnc_check;
    [_name, -1, 0] call OT_fnc_drugHeatSet;
    _income = [_op, 2] call OTQA_raid_cycle;
    ["Shut dispensary: open again, 2 employees sell the 6 ganja", _income > 0 && { ([_box, "OT_Ganja"] call OTQA_raid_count) isEqualTo 0 } && { !("RAIDED" in ([_name] call OT_fnc_drugOpInfo)) }, format ["income %1", _income]] call OTQA_fnc_check;

    server setVariable ["money", _funds, true];
    [_pos] call OTQA_raid_clearAround;
    if !(_box in _boxesBefore) then { deleteVehicle _box };
    [_saved] call OTQA_raid_restore;
}, 30];

_tests;
