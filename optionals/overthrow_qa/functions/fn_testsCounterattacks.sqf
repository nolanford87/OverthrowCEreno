/*
    Description:
    Occupier counter-attacks on resistance towns (OT_fnc_NATOcounterTowns, OT_fnc_NATOCounterTown),
    with real attacks on towns over 1.5 km from the host. Part of the current QA tests.
    1. Locked: no counter-attack, even forced, while the resistance holds no base
    2. Unlock: one base held unlocks them, and they stay unlocked once it's lost again
    3. Unlock for real: the resistance wins a QRF for a base (forced result) and they're unlocked
    4. Target: the least defended resistance town (police, then support), skipping grace periods
    5. Grace: winning the first QRF for a town (forced result) gives it an hour, counted down in real
       time and gone once it runs out
    6. Warning: 2 minutes without intelligence, 10 with resistance support of 50 or a radio tower
       within 4 km; called off, the resources come back
    7. Spending and frequency: the chance grows with resources and towns held, the cooldowns and the
       300 minimum hold it back, the strength is paid when it starts, one at a time
    8. Forces: from the nearest base, heading for the town; the resistance wins (forced) and keeps it
    9. Occupier wins (forced): the town is the occupier's again, its police gone, stability -30,
       support halved (25 at least)
    The fights' results are forced (OT_QRFforceResult) and their 10 minute set-up skipped
    (OT_QRFsetupTime); NATO turns are held off while the tests run.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Counter-attacks: in play, after the first base is taken, a counter-attack comes about every 30-60 real minutes mid-game; check the task, the red marker on the town and the warning (10 minutes with a radio tower near or support of 50, 2 without)" call OTQA_fnc_manual;
"Counter-attacks: defend a town in play, the occupier's trucks come from the nearest base and the QRF progress bar shows; losing it removes the police station and its marker" call OTQA_fnc_manual;
"Counter-attacks: save during a counter-attack's warning and reload, the town is still the resistance's and the counter-attack is gone" call OTQA_fnc_manual;

// Everything the tests change, to put back afterwards
OTQA_ca_save = {
    OT_nextNATOTurn = time + 3600; // No NATO turn while a test runs
    createHashMapFromArray [
        ["abandoned", +(server getVariable ["NATOabandoned", []])],
        ["unlocked", server getVariable ["NATOcounterUnlocked", false]],
        ["resources", server getVariable ["NATOresources", 2000]],
        ["grace", +(server getVariable ["NATOtownGrace", []])],
        ["lastCounter", server getVariable ["NATOlastTownCounter", 0]],
        ["lastAttack", server getVariable ["NATOlastattack", 0]]
    ];
};
OTQA_ca_restore = {
    params ["_saved"];
    OT_counterTownRoll = nil;
    OT_QRFsetupTime = nil;
    OT_QRFforceResult = nil;
    server setVariable ["NATOabandoned", _saved get "abandoned", true];
    server setVariable ["NATOcounterUnlocked", _saved get "unlocked", true];
    server setVariable ["NATOresources", _saved get "resources", true];
    server setVariable ["NATOtownGrace", _saved get "grace", true];
    server setVariable ["NATOlastTownCounter", _saved get "lastCounter", true];
    server setVariable ["NATOlastattack", _saved get "lastAttack", true];
    server setVariable ["NATOcounterTarget", "", true];
    OT_nextNATOTurn = time + 120;
};

// No QRF being fought (waits up to 60 s)
OTQA_ca_idle = {
    private _timeout = time + 60;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    (server getVariable ["NATOattacking", ""]) isEqualTo "" && { (server getVariable ["NATOcounterTarget", ""]) isEqualTo "" };
};

OTQA_ca_bases = { (OT_objectiveData + OT_airportData) apply { _x select 1 } };

// Towns over _minDist from the host, nearest first, not an FOB's target
OTQA_ca_towns = {
    params [["_minDist", 1500]];
    private _fobTowns = (server getVariable ["NATOfobTimers", []]) apply { _x select 2 };
    private _towns = OT_allTowns select { !(_x in _fobTowns) && { ((server getVariable [_x, [0, 0, 0]]) distance2D player) > _minDist } };
    [_towns, [], { (server getVariable [_x, [0, 0, 0]]) distance2D player }, "ASCEND"] call BIS_fnc_sortBy;
};

// The resistance holds just these towns (and the bases it had)
OTQA_ca_hold = {
    params ["_towns", "_saved"];
    private _keep = (call OTQA_ca_bases) + (OT_NATOComms apply { _x select 1 });
    private _list = ((_saved get "abandoned") select { _x in _keep }) + _towns;
    server setVariable ["NATOabandoned", _list, true];
    { ["clear", _x] call OT_fnc_NATOtownGrace } forEach _towns;
};

// The town's police, support and stability, to put back
OTQA_ca_townVars = {
    params ["_town"];
    [_town, server getVariable [format ["police%1", _town], 0], server getVariable [format ["rep%1", _town], 0], server getVariable [format ["stability%1", _town], 50]];
};
OTQA_ca_townRestore = {
    params ["_town", "_police", "_rep", "_stability"];
    server setVariable [format ["police%1", _town], _police, true];
    server setVariable [format ["rep%1", _town], _rep, true];
    server setVariable [format ["stability%1", _town], _stability, true];
};

// Calls off a counter-attack in its warning
OTQA_ca_cancel = {
    private _state = missionNamespace getVariable ["OT_counterTownState", createHashMap];
    _state set ["cancel", true];
    private _timeout = time + 10;
    waitUntil { sleep 0.5; (_state getOrDefault ["phase", ""]) isEqualTo "cancelled" || { time > _timeout } };
    (_state getOrDefault ["phase", ""]) isEqualTo "cancelled";
};

private _tests = [];

_tests pushBack ["Counter-attacks: locked until a base is taken, then for good", {
    private _saved = call OTQA_ca_save;
    private _town = (call OTQA_ca_towns) param [0, ""];
    private _bases = call OTQA_ca_bases;
    private _base = _bases select 0;
    private _r = [];
    isNil {
        // No base held: nothing, even forced
        server setVariable ["NATOabandoned", [_town], true];
        server setVariable ["NATOcounterUnlocked", false, true];
        private _started = [true, _town, 0] call OT_fnc_NATOcounterTowns;
        _r pushBack [_started, server getVariable ["NATOcounterUnlocked", false], server getVariable ["NATOcounterTarget", ""]];

        // One base held: unlocked (no attack, the roll never passes)
        OT_counterTownRoll = 100;
        server setVariable ["NATOabandoned", [_town, _base], true];
        _started = [] call OT_fnc_NATOcounterTowns;
        _r pushBack [_started, server getVariable ["NATOcounterUnlocked", false]];

        // The base lost again: still unlocked
        server setVariable ["NATOabandoned", [_town], true];
        _started = [] call OT_fnc_NATOcounterTowns;
        _r pushBack [_started, server getVariable ["NATOcounterUnlocked", false]];
    };
    (_r select 0) params ["_s1", "_u1", "_t1"];
    ["Locked: no counter-attack while no base is held, even forced", !_s1 && { !_u1 } && { _t1 isEqualTo "" }, format ["started %1, unlocked %2, target '%3'", _s1, _u1, _t1]] call OTQA_fnc_check;
    (_r select 1) params ["_s2", "_u2"];
    ["Unlocked once a base is held", _u2 && { !_s2 }, format ["unlocked %1 (with %2), started %3", _u2, _base, _s2]] call OTQA_fnc_check;
    (_r select 2) params ["_s3", "_u3"];
    ["Stays unlocked once the base is lost", _u3, format ["unlocked %1", _u3]] call OTQA_fnc_check;
    [_saved] call OTQA_ca_restore;
}, 30];

_tests pushBack ["Counter-attacks: winning a base's QRF unlocks them", {
    if !(call OTQA_ca_idle) exitWith { ["Unlock by a base: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_ca_save;
    // The occupier base farthest from the host, so its fight stays out of the way
    private _held = (OT_objectiveData + OT_airportData) select { !((_x select 1) in (_saved get "abandoned")) && { (_x select 1) isNotEqualTo OT_NATO_HQ } };
    if (_held isEqualTo []) exitWith { ["Unlock by a base: an occupier base to fight for", false, "none left"] call OTQA_fnc_check; [_saved] call OTQA_ca_restore };
    private _base = ([_held, [], { (_x select 0) distance2D player }, "DESCEND"] call BIS_fnc_sortBy) select 0;
    _base params ["_basePos", "_baseName"];
    server setVariable ["NATOcounterUnlocked", false, true];

    OT_QRFsetupTime = 0;
    OT_QRFforceResult = -1;
    server setVariable ["NATOattacking", _baseName, true];
    server setVariable ["NATOattackstart", time, true];
    [_baseName, 150] spawn OT_fnc_NATOResponseObjective;
    private _timeout = time + 60;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    private _captured = _baseName in (server getVariable ["NATOabandoned", []]);
    ["Unlock by a base: the resistance wins its QRF", _captured, format ["%1 captured %2", _baseName, _captured]] call OTQA_fnc_check;
    ["Unlock by a base: counter-attacks unlocked", server getVariable ["NATOcounterUnlocked", false], ""] call OTQA_fnc_check;

    // The base goes back to the occupier
    [_saved] call OTQA_ca_restore;
    _baseName setMarkerType OT_NATO_markerFlag;
    format ["%1_restrict", _baseName] setMarkerAlpha 0.4;
}, 90];

_tests pushBack ["Counter-attacks: the least defended town, not one in grace", {
    private _saved = call OTQA_ca_save;
    private _towns = call OTQA_ca_towns;
    if (count _towns < 3) exitWith { ["Target: three towns away from the host", false, str count _towns] call OTQA_fnc_check; [_saved] call OTQA_ca_restore };
    _towns = _towns select [0, 3];
    _towns params ["_a", "_b", "_c"];
    private _vars = _towns apply { [_x] call OTQA_ca_townVars };
    [_towns, _saved] call OTQA_ca_hold;
    // A: 3 police. B and C: none, B with more support
    server setVariable [format ["police%1", _a], 3, true];
    server setVariable [format ["rep%1", _a], 0, true];
    server setVariable [format ["police%1", _b], 0, true];
    server setVariable [format ["rep%1", _b], 40, true];
    server setVariable [format ["police%1", _c], 0, true];
    server setVariable [format ["rep%1", _c], 10, true];

    private _t1 = [] call OT_fnc_NATOcounterTarget;
    ["Target: no police and the least support", _t1 isEqualTo _c, format ["picked %1, expected %2 (A %3: 3 police, B %4: 40 support, C %5: 10 support)", _t1, _c, _a, _b, _c]] call OTQA_fnc_check;
    ["set", _c, 3600] call OT_fnc_NATOtownGrace;
    private _t2 = [] call OT_fnc_NATOcounterTarget;
    ["Target: skips a town in grace", _t2 isEqualTo _b, format ["picked %1, expected %2", _t2, _b]] call OTQA_fnc_check;
    ["set", _b, 3600] call OT_fnc_NATOtownGrace;
    private _t3 = [] call OT_fnc_NATOcounterTarget;
    ["Target: the police count", _t3 isEqualTo _a, format ["picked %1, expected %2", _t3, _a]] call OTQA_fnc_check;
    ["set", _a, 3600] call OT_fnc_NATOtownGrace;
    private _t4 = [] call OT_fnc_NATOcounterTarget;
    ["Target: none when every town is in grace", _t4 isEqualTo "", format ["picked '%1'", _t4]] call OTQA_fnc_check;

    { _x call OTQA_ca_townRestore } forEach _vars;
    [_saved] call OTQA_ca_restore;
}, 30];

_tests pushBack ["Counter-attacks: an hour's grace after winning the first QRF", {
    if !(call OTQA_ca_idle) exitWith { ["Grace: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_ca_save;
    // An occupier town far from the host
    private _town = (call OTQA_ca_towns) select { !(_x in (_saved get "abandoned")) } param [0, ""];
    if (_town isEqualTo "") exitWith { ["Grace: an occupier town", false, "none"] call OTQA_fnc_check; [_saved] call OTQA_ca_restore };
    private _vars = [_town] call OTQA_ca_townVars;
    ["clear", _town] call OT_fnc_NATOtownGrace;

    OT_QRFsetupTime = 0;
    OT_QRFforceResult = -1;
    server setVariable ["NATOattacking", _town, true];
    server setVariable ["NATOattackstart", time, true];
    [_town, 150] spawn OT_fnc_NATOResponseTown;
    private _timeout = time + 60;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    private _taken = _town in (server getVariable ["NATOabandoned", []]);
    private _grace = ["get", _town] call OT_fnc_NATOtownGrace;
    ["Grace: the resistance wins the town's first QRF", _taken, format ["%1 resistance's: %2", _town, _taken]] call OTQA_fnc_check;
    ["Grace: an hour from then", _grace > 3540 && { _grace <= 3600 }, format ["%1 s", _grace]] call OTQA_fnc_check;
    private _target = [] call OT_fnc_NATOcounterTarget;
    ["Grace: not a target meanwhile", _target isNotEqualTo _town, format ["target '%1'", _target]] call OTQA_fnc_check;

    // Counted down in real time (in one go, the NATO loop counts it down too)
    private _after = 0;
    isNil {
        _grace = ["get", _town] call OT_fnc_NATOtownGrace;
        OT_townGraceLast = time - 20;
        ["tick"] call OT_fnc_NATOtownGrace;
        _after = ["get", _town] call OT_fnc_NATOtownGrace;
    };
    ["Grace: counts down in real time", (_grace - _after) >= 19 && { (_grace - _after) <= 22 }, format ["%1 -> %2 s", _grace, _after]] call OTQA_fnc_check;

    // Runs out
    private _left = -1;
    isNil {
        server setVariable ["NATOtownGrace", [[_town, 10]], true];
        OT_townGraceLast = time - 30;
        ["tick"] call OT_fnc_NATOtownGrace;
        _left = ["get", _town] call OT_fnc_NATOtownGrace;
    };
    ["Grace: gone once it runs out", _left isEqualTo 0 && { ((server getVariable ["NATOtownGrace", []]) findIf { (_x select 0) isEqualTo _town }) isEqualTo -1 }, format ["%1 s left", _left]] call OTQA_fnc_check;
    [[_town], _saved] call OTQA_ca_hold;
    _target = [] call OT_fnc_NATOcounterTarget;
    ["Grace: a target again afterwards", _target isEqualTo _town, format ["target '%1' (the only town held)", _target]] call OTQA_fnc_check;

    _vars call OTQA_ca_townRestore;
    [_saved] call OTQA_ca_restore;
}, 90];

_tests pushBack ["Counter-attacks: 10 minutes' warning with intelligence, 2 without", {
    if !(call OTQA_ca_idle) exitWith { ["Warning: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_ca_save;
    // A town with a radio tower within 3.5 km
    private _towns = call OTQA_ca_towns;
    private _town = "";
    private _tower = "";
    {
        private _tpos = server getVariable [_x, [0, 0, 0]];
        private _i = OT_NATOComms findIf { ((_x select 0) distance2D _tpos) < 3500 };
        if (_i > -1) exitWith { _town = _x; _tower = (OT_NATOComms select _i) select 1 };
    } forEach _towns;
    if (_town isEqualTo "") then { _town = _towns param [0, ""] };
    if (_town isEqualTo "") exitWith { ["Warning: a town away from the host", false, "none"] call OTQA_fnc_check; [_saved] call OTQA_ca_restore };
    private _vars = [_town] call OTQA_ca_townVars;
    private _towers = OT_NATOComms apply { _x select 1 };
    private _bases = call OTQA_ca_bases;
    server setVariable ["NATOcounterUnlocked", true, true];

    // No intelligence: no tower held, support 0
    server setVariable ["NATOabandoned", ((_saved get "abandoned") select { _x in _bases }) + [_town], true];
    server setVariable [format ["rep%1", _town], 0, true];
    private _intel = [_town] call OT_fnc_NATOcounterIntel;
    ["Warning: no intelligence without a tower or support", !_intel, ""] call OTQA_fnc_check;
    private _started = [true, _town] call OT_fnc_NATOcounterTowns;
    sleep 1;
    private _state = missionNamespace getVariable ["OT_counterTownState", createHashMap];
    private _warning = _state getOrDefault ["warning", -1];
    private _left = (_state getOrDefault ["attackAt", 0]) - time;
    ["Warning: 2 minutes without intelligence", _started && { _warning isEqualTo 120 } && { _left > 110 && _left <= 120 }, format ["started %1, warning %2 s, %3 s left", _started, _warning, round _left]] call OTQA_fnc_check;
    private _task = _state getOrDefault ["task", ""];
    private _markers = _state getOrDefault ["markers", []];
    ["Warning: a task and a marker on the town", [_task] call BIS_fnc_taskExists && { _markers isNotEqualTo [] } && { (_markers findIf { !(_x in allMapMarkers) }) isEqualTo -1 },
        format ["task %1, markers %2", _task, _markers]] call OTQA_fnc_check;
    private _resBefore = server getVariable ["NATOresources", 0];
    private _strength = _state getOrDefault ["strength", 0];
    private _cancelled = call OTQA_ca_cancel;
    sleep 1;
    ["Warning: called off, task cancelled, markers gone, resources back", _cancelled && { ([_task] call BIS_fnc_taskState) isEqualTo "CANCELED" } && { (_markers findIf { _x in allMapMarkers }) isEqualTo -1 }
        && { (server getVariable ["NATOresources", 0]) isEqualTo (_resBefore + _strength) } && { (server getVariable ["NATOcounterTarget", ""]) isEqualTo "" },
        format ["phase %1, task %2, resources %3 -> %4 (strength %5)", _state getOrDefault ["phase", ""], [_task] call BIS_fnc_taskState, _resBefore, server getVariable ["NATOresources", 0], _strength]] call OTQA_fnc_check;

    // Support of 50
    server setVariable [format ["rep%1", _town], 50, true];
    _intel = [_town] call OT_fnc_NATOcounterIntel;
    _started = [true, _town] call OT_fnc_NATOcounterTowns;
    sleep 1;
    _state = missionNamespace getVariable ["OT_counterTownState", createHashMap];
    ["Warning: 10 minutes with support of 50", _intel && { _started } && { (_state getOrDefault ["warning", -1]) isEqualTo 600 }, format ["intel %1, warning %2 s", _intel, _state getOrDefault ["warning", -1]]] call OTQA_fnc_check;
    call OTQA_ca_cancel;
    server setVariable [format ["rep%1", _town], 0, true];

    // A radio tower held within 4 km
    if (_tower isEqualTo "") then {
        "Counter-attacks: no radio tower within 3.5 km of a town away from the host, check the tower intelligence by hand" call OTQA_fnc_manual;
    } else {
        private _list = server getVariable ["NATOabandoned", []];
        _list pushBack _tower;
        server setVariable ["NATOabandoned", _list, true];
        _intel = [_town] call OT_fnc_NATOcounterIntel;
        _started = [true, _town] call OT_fnc_NATOcounterTowns;
        sleep 1;
        _state = missionNamespace getVariable ["OT_counterTownState", createHashMap];
        ["Warning: 10 minutes with a radio tower near", _intel && { _started } && { (_state getOrDefault ["warning", -1]) isEqualTo 600 }, format ["%1, intel %2, warning %3 s", _tower, _intel, _state getOrDefault ["warning", -1]]] call OTQA_fnc_check;
        call OTQA_ca_cancel;
    };

    _vars call OTQA_ca_townRestore;
    [_saved] call OTQA_ca_restore;
}, 90];

_tests pushBack ["Counter-attacks: resources and frequency", {
    if !(call OTQA_ca_idle) exitWith { ["Frequency: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_ca_save;
    private _towns = (call OTQA_ca_towns) select [0, 6];
    if (count _towns < 6) exitWith { ["Frequency: six towns away from the host", false, str count _towns] call OTQA_fnc_check; [_saved] call OTQA_ca_restore };
    server setVariable ["NATOcounterUnlocked", true, true];
    server setVariable ["NATOlastTownCounter", -100000, true];
    server setVariable ["NATOlastattack", -100000, true];

    // The chance (the roll never passes)
    OT_counterTownRoll = 100;
    private _chanceFor = {
        params ["_n", "_res"];
        [_towns select [0, _n], _saved] call OTQA_ca_hold;
        server setVariable ["NATOresources", _res, true];
        [] call OT_fnc_NATOcounterTowns;
        OT_counterTownChance;
    };
    private _c1 = [1, 500] call _chanceFor;
    private _c2 = [1, 2500] call _chanceFor;
    private _c3 = [5, 1500] call _chanceFor;
    private _c4 = [6, 3500] call _chanceFor;
    ["Frequency: 15% + 5% per town + 1% per 100 resources, at most 80%", _c1 isEqualTo 25 && { _c2 isEqualTo 45 } && { _c3 isEqualTo 55 } && { _c4 isEqualTo 80 },
        format ["1 town 500: %1%%, 1 town 2500: %2%%, 5 towns 1500: %3%%, 6 towns 3500: %4%% (expected 25, 45, 55, 80)", _c1, _c2, _c3, _c4]] call OTQA_fnc_check;

    // Held back: cooldowns, resources (the roll always passes)
    OT_counterTownRoll = 0;
    [[_towns select 0], _saved] call OTQA_ca_hold;
    private _r = [];
    isNil {
        server setVariable ["NATOresources", 2000, true];
        server setVariable ["NATOlastTownCounter", time - 1000, true];
        _r pushBack ([] call OT_fnc_NATOcounterTowns);
        server setVariable ["NATOlastTownCounter", -100000, true];
        server setVariable ["NATOlastattack", time - 300, true];
        _r pushBack ([] call OT_fnc_NATOcounterTowns);
        server setVariable ["NATOlastattack", -100000, true];
        server setVariable ["NATOresources", 299, true];
        _r pushBack ([] call OT_fnc_NATOcounterTowns);
    };
    ["Frequency: none within 25 minutes of the last", !(_r select 0), ""] call OTQA_fnc_check;
    ["Frequency: none within 10 minutes of a QRF", !(_r select 1), ""] call OTQA_fnc_check;
    ["Frequency: none under 300 resources", !(_r select 2), ""] call OTQA_fnc_check;

    // Paid when it starts, one at a time
    private _town = _towns select 0;
    server setVariable ["NATOresources", 2000, true];
    private _popControl = call OT_fnc_getControlledPopulation;
    private _mul = 3;
    if (_popControl > 1000) then { _mul = 4 };
    if (_popControl > 2000) then { _mul = 5 };
    private _expected = (((server getVariable [format ["population%1", _town], 100]) * _mul) max 300) min 1200;
    private _started = [false, _town, 300] call OT_fnc_NATOcounterTowns;
    private _paid = 2000 - (server getVariable ["NATOresources", 0]);
    ["Frequency: it starts and pays its strength", _started && { _paid isEqualTo _expected } && { (time - (server getVariable ["NATOlastTownCounter", 0])) < 5 },
        format ["started %1, paid %2, expected %3 (population %4 x %5)", _started, _paid, _expected, server getVariable [format ["population%1", _town], 100], _mul]] call OTQA_fnc_check;
    server setVariable ["NATOlastTownCounter", -100000, true];
    private _second = [false, _towns select 1, 300] call OT_fnc_NATOcounterTowns;
    ["Frequency: one at a time", !_second, ""] call OTQA_fnc_check;
    sleep 1;
    call OTQA_ca_cancel;

    [_saved] call OTQA_ca_restore;
}, 60];

_tests pushBack ["Counter-attacks: forces from the nearest base, the resistance holds", {
    if !(call OTQA_ca_idle) exitWith { ["Forces: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_ca_save;
    private _town = (call OTQA_ca_towns) param [0, ""];
    private _pos = server getVariable [_town, [0, 0, 0]];
    [[_town], _saved] call OTQA_ca_hold;
    server setVariable ["NATOcounterUnlocked", true, true];
    ([_pos] call OT_fnc_NATOGetAttackVectors) params ["_ground", "_air"];
    private _expected = (_ground + _air) param [0, []];
    if (_expected isEqualTo []) exitWith { ["Forces: an occupier base to come from", false, _town] call OTQA_fnc_check; [_saved] call OTQA_ca_restore };

    OT_QRFsetupTime = 100000; // Held until the forces have been checked
    spawner setVariable ["NATOattackforce", [], false];
    [true, _town, 0] call OT_fnc_NATOcounterTowns;
    private _state = missionNamespace getVariable ["OT_counterTownState", createHashMap];
    private _timeout = time + 15;
    waitUntil { sleep 0.5; (count (spawner getVariable ["NATOattackforce", []])) > 0 || { time > _timeout } };
    private _from = _state getOrDefault ["from", []];
    ["Forces: from the nearest base", (_from param [1, ""]) isEqualTo (_expected select 1),
        format ["from %1, expected %2 (by road: %3), %4 m from %5", _from param [1, ""], _expected select 1, _ground isNotEqualTo [], round ((_expected select 0) distance2D _pos), _town]] call OTQA_fnc_check;
    private _groups = spawner getVariable ["NATOattackforce", []];
    private _near = _groups select { ((leader _x) distance2D (_expected select 0)) < 500 };
    ["Forces: they set off from the base", _groups isNotEqualTo [] && { (count _near) isEqualTo (count _groups) },
        format ["%1 of %2 groups within 500 m of %3", count _near, count _groups, _expected select 1]] call OTQA_fnc_check;

    _timeout = time + 30;
    private _heading = {
        _groups select { ((waypoints _x) findIf { ((waypointPosition _x) distance2D _pos) < 250 }) > -1 }
    };
    waitUntil { sleep 1; (count (call _heading)) isEqualTo (count _groups) || { time > _timeout } };
    ["Forces: heading for the town", _groups isNotEqualTo [] && { (count (call _heading)) isEqualTo (count _groups) },
        format ["%1 of %2 groups with a waypoint at %3", count (call _heading), count _groups, _town]] call OTQA_fnc_check;
    ["Forces: the town is under attack", (server getVariable ["NATOattacking", ""]) isEqualTo _town, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check;

    // The resistance wins
    OT_QRFforceResult = -1;
    OT_QRFsetupTime = 0;
    _timeout = time + 30;
    waitUntil { sleep 1; (_state getOrDefault ["phase", ""]) isEqualTo "done" || { time > _timeout } };
    sleep 1;
    private _task = _state getOrDefault ["task", ""];
    private _grace = ["get", _town] call OT_fnc_NATOtownGrace;
    ["Resistance wins: the town stays theirs, an hour's grace, task succeeded", !(_state getOrDefault ["won", true]) && { _town in (server getVariable ["NATOabandoned", []]) } && { _grace > 3500 }
        && { ([_task] call BIS_fnc_taskState) isEqualTo "SUCCEEDED" } && { (server getVariable ["NATOcounterTarget", "?"]) isEqualTo "" },
        format ["phase %1, won %2, grace %3 s, task %4", _state getOrDefault ["phase", ""], _state getOrDefault ["won", "?"], _grace, [_task] call BIS_fnc_taskState]] call OTQA_fnc_check;

    {
        { if (!isNull objectParent _x) then { deleteVehicle objectParent _x }; deleteVehicle _x } forEach (units _x);
    } forEach _groups;
    [_saved] call OTQA_ca_restore;
}, 120];

_tests pushBack ["Counter-attacks: the occupier wins the town back", {
    if !(call OTQA_ca_idle) exitWith { ["Occupier wins: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _saved = call OTQA_ca_save;
    private _town = (call OTQA_ca_towns) param [0, ""];
    private _pos = server getVariable [_town, [0, 0, 0]];
    [[_town], _saved] call OTQA_ca_hold;
    server setVariable ["NATOcounterUnlocked", true, true];
    server setVariable [format ["police%1", _town], 4, true];
    server setVariable [format ["rep%1", _town], 40, true];
    server setVariable [format ["stability%1", _town], 70, true];
    // One of its police officers, spawned
    private _group = createGroup independent;
    private _cop = _group createUnit [typeOf player, _pos, [], 20, "NONE"];
    _cop setVariable ["polgarrison", _town, true];

    OT_QRFsetupTime = 0;
    OT_QRFforceResult = 1;
    [true, _town, 0] call OT_fnc_NATOcounterTowns;
    private _state = missionNamespace getVariable ["OT_counterTownState", createHashMap];
    private _timeout = time + 60;
    waitUntil { sleep 1; (_state getOrDefault ["phase", ""]) isEqualTo "done" || { time > _timeout } };
    sleep 1;

    private _task = _state getOrDefault ["task", ""];
    ["Occupier wins: the town is the occupier's again", (_state getOrDefault ["won", false]) && { !(_town in (server getVariable ["NATOabandoned", []])) },
        format ["phase %1, won %2", _state getOrDefault ["phase", ""], _state getOrDefault ["won", "?"]]] call OTQA_fnc_check;
    private _police = server getVariable [format ["police%1", _town], 0];
    ["Occupier wins: its police are gone", _police isEqualTo 0 && { isNull _cop }, format ["police %1, officer %2", _police, ["still there", "gone"] select (isNull _cop)]] call OTQA_fnc_check;
    private _stability = server getVariable [format ["stability%1", _town], 0];
    ["Occupier wins: stability -30", _stability isEqualTo 40, format ["70 -> %1", _stability]] call OTQA_fnc_check;
    private _rep = server getVariable [format ["rep%1", _town], 0];
    ["Occupier wins: support halved, at least 25 off", _rep isEqualTo 15, format ["40 -> %1", _rep]] call OTQA_fnc_check;
    ["Occupier wins: task failed, markers gone, no grace", ([_task] call BIS_fnc_taskState) isEqualTo "FAILED" && { ((_state getOrDefault ["markers", []]) findIf { _x in allMapMarkers }) isEqualTo -1 }
        && { (["get", _town] call OT_fnc_NATOtownGrace) isEqualTo 0 },
        format ["task %1", [_task] call BIS_fnc_taskState]] call OTQA_fnc_check;

    if (!isNull _cop) then { deleteVehicle _cop };
    [_saved] call OTQA_ca_restore;
    [_town, 0] call OT_fnc_stability; // Its markers, for the restored list
}, 90];

_tests;
