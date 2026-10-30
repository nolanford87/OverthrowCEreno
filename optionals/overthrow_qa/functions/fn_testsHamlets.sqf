/*
    Description:
    The hamlets' mayor's offices (a town that can never reach tier 3: tools/officegen/hamlet_gen.py, the user's
    design): police only; tier 1 four gendarmes in the building, tier 2 those four and two patrols of three
    ("patrol:1", "patrol:2") walking a ring round the office (OT_fnc_officeGarrison), from opposite sides and
    opposite ways round, within 40 m of it; every bigger town's tiers 1-2 the same (hamlet_gen.py --bigger), its
    compound tiers on top. Part of the archived QA tests. Uses the hamlet and the bigger town farthest from the
    host, each's tier set to 2 for the test and put back.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Hamlets: in play, a hamlet's tier 2 patrols go after you when you shoot near the office, but not more than about 40 m from it, and walk their ring again a minute after" call OTQA_fnc_manual;

call OTQA_fnc_testsOfficeHelpers;
private _tests = [];

// [small (the hamlets) or not, label] for the checks
OTQA_hm_layouts = {
    params ["_small", "_label"];
    private _hamlets = [_small] call OTQA_og_towns;
    private _flags = { _this param [4, []] };
    private _bad = [];
    {
        private _town = _x;
        private _tiers = (([_town] call OT_fnc_officeLayout) select 1) select { _x isNotEqualTo [] }; // Its 5 slots, the authored ones
        private _guards = _tiers apply { _x select { (_x select 0) isEqualTo "guard" } };
        private _t1 = _guards param [0, []];
        private _t2 = _guards param [1, []];
        private _p1 = { "patrol:1" in (_x call _flags) } count _t2;
        private _p2 = { "patrol:2" in (_x call _flags) } count _t2;
        private _military = { (_x select 1) isNotEqualTo "gendarme" } count (_t1 + _t2);
        if !(((count _tiers) isEqualTo 2 || { !_small }) && { (count _t1) isEqualTo 4 } && { ({ "patrol" in (_x call _flags) } count _t1) isEqualTo 0 }
            && { (count _t2) isEqualTo 10 } && { _p1 isEqualTo 3 } && { _p2 isEqualTo 3 } && { _military isEqualTo 0 }) then {
            _bad pushBack [_town, count _tiers, count _t1, count _t2, _p1, _p2, _military];
        };
    } forEach _hamlets;
    [format ["%1: every one's T1 4 gendarmes inside, T2 10 with 2 patrols of 3, no military%2", _label, ["", " (and only 2 tiers)"] select _small],
        _hamlets isNotEqualTo [] && { _bad isEqualTo [] },
        format ["%1 towns; off ([town, tiers, T1 men, T2 men, patrol 1, patrol 2, military]): %2", count _hamlets, _bad]] call OTQA_fnc_check;
};
_tests pushBack ["Hamlets: the layouts, police only", { [true, "Hamlets"] call OTQA_hm_layouts }, 10];
_tests pushBack ["Bigger towns: tiers 1-2 police only", { [false, "Bigger towns"] call OTQA_hm_layouts }, 10];

OTQA_hm_live = {
    params ["_small", "_label"];
    private _town = ([_small] call OTQA_og_towns) param [0, ""];
    if (_town isEqualTo "") exitWith { [format ["%1: a town to spawn", _label], false, "none"] call OTQA_fnc_check };
    private _tierVar = format ["officetier%1", _town];
    private _keep = server getVariable [_tierVar, -1];
    server setVariable [_tierVar, 2];
    private _office = _town call OTQA_og_officePos;
    spawner setVariable ["OTQA_hamlet", [], false];
    private _h = [_town, "OTQA_hamlet"] spawn OT_fnc_spawnOffice;
    waitUntil { sleep 0.5; scriptDone _h };
    private _groups = (spawner getVariable ["OTQA_hamlet", []]) select { _x isEqualType grpNull };
    private _patrols = _groups select { (units _x) findIf { "patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]) } > -1 };
    private _wps = _patrols apply { ((waypoints _x) select { (_x select 1) > 0 }) apply { waypointPosition _x } };
    private _cycles = { ((waypoints _x) findIf { (waypointType _x) isEqualTo "CYCLE" }) > -1 } count _patrols;
    private _far = flatten (_wps apply { _x apply { _x distance2D _office } });
    private _starts = _wps apply { _x param [0, [0, 0, 0]] };
    private _apart = if ((count _starts) isEqualTo 2) then { (_starts select 0) distance2D (_starts select 1) } else { 0 };
    [format ["%1: two patrols of 3, each on a ring of waypoints round the office, from opposite sides", _label],
        (count _patrols) isEqualTo 2 && { (_patrols findIf { (count units _x) isNotEqualTo 3 }) < 0 } && { _cycles isEqualTo 2 }
            && { (_wps findIf { (count _x) < 4 }) < 0 } && { (_far findIf { _x < 6 }) < 0 } && { _apart > 10 },
        format ["%1: %2 patrols (men %3), waypoints %4, cycles %5, %6-%7 m from the office, starts %8 m apart", _town, count _patrols, _patrols apply { count units _x }, _wps apply { count _x }, _cycles, round (selectMin (_far + [0])), round (selectMax (_far + [0])), round _apart]] call OTQA_fnc_check;

    private _men = flatten (_patrols apply { units _x });
    private _from = _men apply { getPosATL _x };
    sleep 40;
    private _moved = 0;
    { if ((_x distance2D (_from select _forEachIndex)) > 3) then { _moved = _moved + 1 } } forEach _men;
    // Within 40 m of the office, or 10 m past the ring round a big one (OT_fnc_officeGarrison)
    private _bound = 40 max ((selectMax (_far + [0])) + 10);
    private _out = { (_x distance2D _office) > _bound } count _men;
    [format ["%1: the patrols walk, within %2 m of the office", _label, round _bound],
        _men isNotEqualTo [] && { _moved isEqualTo (count _men) } && { _out isEqualTo 0 },
        format ["%1 of %2 moved, %3 more than 40 m out", _moved, count _men, _out]] call OTQA_fnc_check;

    ["OTQA_hamlet", [], [], {}, []] call OT_fnc_despawn;
    server setVariable [_tierVar, [_keep, nil] select (_keep isEqualTo -1)];
};
_tests pushBack ["Hamlets: tier 2's patrols walk the ring round the office", { [true, "Hamlets"] call OTQA_hm_live }, 90];
_tests pushBack ["Bigger towns: tier 2's patrols walk the ring round the office", { [false, "Bigger towns"] call OTQA_hm_live }, 90];

_tests
