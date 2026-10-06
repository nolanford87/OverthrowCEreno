/*
    Description:
    Taking a town by its mayor's office (OT_fnc_officeTier, OT_fnc_spawnOffice, OT_fnc_officeCapture, the
    office mode of OT_fnc_NATOQRFfight). Part of the current QA tests.
    1. Tier: a town starts by its population bracket, never above bracket + 1 or its layout's top tier
    2. Spawner: the layout with crewed guards while the office is the occupier's, without guards once
       the resistance holds it
    3. Capture: the task, cleared and held (2 minutes, shortened), the office held, the QRF for it; the
       resistance wins it (forced) and has the town
    3b. A town under 100 people is the resistance's with its office, no QRF
    4. Lost again: the occupier wins the QRF (forced), stability 50, the office theirs again
    5. Called off: the town's stability rises before the office is taken, the task is cancelled
    6. The fight for the office: the occupier holding it with nobody of ours inside wins
    7. The office's radius: 30 m for a house, out to the wings for Kavala's hospital
    8. The office's area: the compound at the town's tier (Rodopoli: T3 then T4), the radius at tiers 1-2
    9. Locked doors: Rodopoli's doors out of its compound locked at T3, all unlocked for none; the lockpick
       unlocks one; a charge breaches the doors near it and a closed gate, not those farther off
    10. Lookout towers: the trees and bushes within 10 m of Rodopoli's T3 tower cleared at T3 (not saved as the
       layout's hides), back at tier 1
    Uses towns far from the host, so their spawners stay out of it. The hold, the QRF's set-up and the
    results are shortened or forced (OT_officeHoldTime, OT_QRFsetupTime, OT_QRFforceResult).

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Office: in play, bring a town to stability 0: the task 'Take the mayor's office' appears; clear the office, hold it 2 minutes, then hold off the QRF that comes 10 minutes later" call OTQA_fnc_manual;
"Office: the black office markers on the map sit on each town's mayor's office" call OTQA_fnc_manual;
"Office: save while the office is held (before the QRF) and load: the guards don't come back and the QRF still comes" call OTQA_fnc_manual;
"Office: a QRF for the office that runs out (13 minutes with none of theirs left near, or 30) is a resistance win" call OTQA_fnc_manual;

// Towns with an office layout, farthest from the host first (locked at 100 people or more, or under 100 with _small)
OTQA_og_towns = {
    params [["_small", false]];
    private _towns = OT_allTowns select { ([_x] call OT_fnc_officeLayout) isNotEqualTo [] && { (([_x] call OT_fnc_officeBracket) <= 2) isEqualTo _small } };
    [_towns, [], { (server getVariable [_x, [0, 0, 0]]) distance2D player }, "DESCEND"] call BIS_fnc_sortBy;
};
OTQA_og_officePos = { ASLToAGL ((([_this] call OT_fnc_officeLayout) select 0) select 1) };

// Everything the capture tests change
OTQA_og_save = {
    params ["_town"];
    OT_nextNATOTurn = time + 3600;
    createHashMapFromArray [
        ["abandoned", +(server getVariable ["NATOabandoned", []])],
        ["resources", server getVariable ["NATOresources", 2000]],
        ["grace", +(server getVariable ["NATOtownGrace", []])],
        ["lastAttack", server getVariable ["NATOlastattack", 0]],
        ["stability", server getVariable [format ["stability%1", _town], 50]],
        ["garrison", server getVariable [format ["garrison%1", _town], 0]]
    ];
};
OTQA_og_restore = {
    params ["_town", "_saved"];
    OT_officeHoldTime = nil;
    OT_QRFsetupTime = nil;
    OT_QRFforceResult = nil;
    server setVariable ["NATOabandoned", _saved get "abandoned", true];
    server setVariable ["NATOresources", _saved get "resources", true];
    server setVariable ["NATOtownGrace", _saved get "grace", true];
    server setVariable ["NATOlastattack", _saved get "lastAttack", true];
    server setVariable [format ["stability%1", _town], _saved get "stability", true];
    server setVariable [format ["garrison%1", _town], _saved get "garrison", true];
    server setVariable [format ["officeheld%1", _town], nil, true];
    OT_nextNATOTurn = time + 120;
};
OTQA_og_idle = {
    private _timeout = time + 60;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    (server getVariable ["NATOattacking", ""]) isEqualTo ""
};
// One of ours standing in the office
OTQA_og_ours = {
    params ["_pos"];
    private _group = createGroup [independent, true];
    private _unit = _group createUnit ["I_soldier_F", _pos, [], 0, "CAN_COLLIDE"];
    _unit allowDamage false;
    _unit disableAI "MOVE";
    _unit
};

private _tests = [];

_tests pushBack ["Office: the tier by population bracket, capped", {
    // A town whose layout goes to tier 5
    private _town = (OT_allTowns select { count ((([_x] call OT_fnc_officeLayout) param [1, []]) select { _x isNotEqualTo [] }) isEqualTo 5 }) param [0, "Pyrgos"];
    private _layout = OT_officeLayouts get _town;
    private _keepBracket = _layout param [3, 0];
    private _keepPop = server getVariable [format ["population%1", _town], 0];
    private _keepTier = server getVariable [format ["officetier%1", _town], 0];
    private _got = [];
    server setVariable [format ["officetier%1", _town], nil];
    {
        _layout set [3, _x];
        _got pushBack ([_town] call OT_fnc_officeTier);
    } forEach [1, 2, 3, 4, 5];
    // Locked: this game's population doesn't move it
    _layout set [3, 2];
    server setVariable [format ["population%1", _town], 500];
    private _lockedTier = [_town] call OT_fnc_officeTier;
    // Raised above its bracket + 1
    server setVariable [format ["officetier%1", _town], 5];
    private _capped = [_town] call OT_fnc_officeTier;
    // A layout without a locked bracket goes by the population
    _layout set [3, 0];
    server setVariable [format ["officetier%1", _town], nil];
    private _byPop = [_town] call OT_fnc_officeTier;
    _layout set [3, _keepBracket];
    server setVariable [format ["population%1", _town], _keepPop];
    server setVariable [format ["officetier%1", _town], [_keepTier, nil] select (_keepTier isEqualTo 0)];
    ["Tier: starts by bracket (1, 1, 2, 3, 4)", _got isEqualTo [1, 1, 2, 3, 4], str _got] call OTQA_fnc_check;
    ["Tier: the locked bracket, not this game's population", _lockedTier isEqualTo 1, format ["%1, bracket 2 at 500 people: %2", _town, _lockedTier]] call OTQA_fnc_check;
    ["Tier: never above bracket + 1", _capped isEqualTo 3, str _capped] call OTQA_fnc_check;
    ["Tier: by the population without a locked bracket", _byPop isEqualTo 4, format ["500 people: %1", _byPop]] call OTQA_fnc_check;
    ["Tier: every layout has its bracket locked", (values OT_officeLayouts) findIf { (_x param [3, 0]) isEqualTo 0 } isEqualTo -1, str ((keys OT_officeLayouts) select { ((OT_officeLayouts get _x) param [3, 0]) isEqualTo 0 })] call OTQA_fnc_check;
    // A layout's top tier caps it too
    // (its highest tier with anything in it: tier 1 may be empty)
    private _authored = { private _n = 0; { if (_x isNotEqualTo []) then { _n = _forEachIndex + 1 } } forEach ((OT_officeLayouts get _this) select 1); _n };
    private _small = ([true] call OTQA_og_towns) select { (_x call _authored) < 5 };
    if (_small isEqualTo []) exitWith { ["Tier: a layout under 5 tiers to cap", false, "none"] call OTQA_fnc_check };
    private _t = _small select 0;
    private _l = OT_officeLayouts get _t;
    private _b = _l param [3, 0];
    private _keepT = server getVariable [format ["officetier%1", _t], 0];
    _l set [3, 5];
    server setVariable [format ["officetier%1", _t], 5];
    private _top = [_t] call OT_fnc_officeTier;
    _l set [3, _b];
    server setVariable [format ["officetier%1", _t], [_keepT, nil] select (_keepT isEqualTo 0)];
    ["Tier: never above the layout's top tier", _top isEqualTo (_t call _authored), format ["%1 at bracket 5, tier 5: %2 (layout to %3)", _t, _top, _t call _authored]] call OTQA_fnc_check;
}, 10];

_tests pushBack ["Office: the spawner, guards only while it's the occupier's", {
    // A town whose layout has guards at its tier (the walls-only drafts have none)
    private _town = ((([true] call OTQA_og_towns) + (call OTQA_og_towns)) select {
        private _t = _x;
        (((([_t] call OT_fnc_officeLayout) select 1) param [([_t] call OT_fnc_officeTier) - 1, []]) findIf { (_x select 0) isEqualTo "guard" }) > -1
    }) param [0, ""];
    if (_town isEqualTo "") exitWith { ["Spawner: a town whose layout has guards", false, "none"] call OTQA_fnc_check };
    private _held = format ["officeheld%1", _town];
    private _runs = [];
    {
        server setVariable [_held, _x, true];
        spawner setVariable ["OTQA_office", [], false];
        private _h = [_town, "OTQA_office"] spawn OT_fnc_spawnOffice;
        waitUntil { sleep 0.5; scriptDone _h };
        private _things = spawner getVariable ["OTQA_office", []];
        private _groups = _things select { _x isEqualType grpNull };
        private _men = flatten (_groups apply { units _x });
        _runs pushBack [{ _x isEqualType objNull } count _things, count _men, blufor countSide _men];
        ["OTQA_office", [], [], {}, []] call OT_fnc_despawn;
        sleep 2;
    } forEach [false, true];
    server setVariable [_held, nil, true];
    (_runs select 0) params ["_objects", "_men", "_blufor"];
    ["Spawner: the layout's things and its guards", _objects > 0 && { _men > 0 } && { _men isEqualTo _blufor }, format ["%1 at tier %2: %3 things, %4 men (%5 occupier)", _town, [_town] call OT_fnc_officeTier, _objects, _men, _blufor]] call OTQA_fnc_check;
    (_runs select 1) params ["_objects2", "_men2"];
    ["Spawner: held by the resistance, the things without guards", _objects2 isEqualTo _objects && { _men2 isEqualTo 0 }, format ["%1 things, %2 men", _objects2, _men2]] call OTQA_fnc_check;
}, 60];

_tests pushBack ["Office: taken, held, the QRF for it won", {
    if !(call OTQA_og_idle) exitWith { ["Capture: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _town = (call OTQA_og_towns) select 0;
    private _saved = [_town] call OTQA_og_save;
    private _pos = _town call OTQA_og_officePos;
    OT_officeHoldTime = 10;
    OT_QRFsetupTime = 0;
    server setVariable [format ["stability%1", _town], 0, true];
    [_town] spawn OT_fnc_officeCapture;
    sleep 2;
    private _task = format ["office%1", _town];
    ["Capture: the task to take the office", ([_task] call BIS_fnc_taskState) isEqualTo "CREATED", [_task] call BIS_fnc_taskState] call OTQA_fnc_check;
    // Nobody of ours there: not taken
    sleep 15;
    private _early = server getVariable [format ["officeheld%1", _town], false];
    private _unit = [_pos] call OTQA_og_ours;
    private _timeout = time + 40;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo _town || { time > _timeout } };
    // The fight starts once the QRF's forces are sent
    _timeout = time + 30;
    waitUntil { sleep 1; ((server getVariable ["QRFpos", [0, 0, 0]]) distance2D _pos) < 1 || { time > _timeout } };
    private _state = [_task] call BIS_fnc_taskState;
    private _held = server getVariable [format ["officeheld%1", _town], false];
    ["Capture: not taken with nobody of ours inside", !_early, ""] call OTQA_fnc_check;
    ["Capture: cleared and held, the task done and the QRF for the office on", _state isEqualTo "SUCCEEDED" && { _held } && { (server getVariable ["NATOattacking", ""]) isEqualTo _town } && { ((server getVariable ["QRFpos", [0, 0, 0]]) distance2D _pos) < 1 }, format ["task %1, held %2, attacking '%3', QRF at %4 m from the office", _state, _held, server getVariable ["NATOattacking", ""], round ((server getVariable ["QRFpos", [0, 0, 0]]) distance2D _pos)]] call OTQA_fnc_check;
    OT_QRFforceResult = -1;
    _timeout = time + 30;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    ["Capture: the resistance wins the QRF and has the town", _town in (server getVariable ["NATOabandoned", []]), ""] call OTQA_fnc_check;
    deleteVehicle _unit;
    [_town, _saved] call OTQA_og_restore;
}, 120];

_tests pushBack ["Office: a small town is taken with its office", {
    if !(call OTQA_og_idle) exitWith { ["Small town: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _town = ([true] call OTQA_og_towns) select 0;
    private _saved = [_town] call OTQA_og_save;
    OT_officeHoldTime = 10;
    server setVariable [format ["stability%1", _town], 0, true];
    [_town] spawn OT_fnc_officeCapture;
    sleep 2;
    private _unit = [_town call OTQA_og_officePos] call OTQA_og_ours;
    private _timeout = time + 40;
    waitUntil { sleep 1; _town in (server getVariable ["NATOabandoned", []]) || { time > _timeout } };
    sleep 6;
    private _taken = _town in (server getVariable ["NATOabandoned", []]);
    ["Small town: the resistance's with its office, no QRF", _taken && { (server getVariable ["NATOattacking", ""]) isEqualTo "" } && { !(missionNamespace getVariable [format ["OT_officeCapture%1", _town], false]) }, format ["%1 (%2 people): taken %3, attacking '%4'", _town, server getVariable [format ["population%1", _town], 0], _taken, server getVariable ["NATOattacking", ""]]] call OTQA_fnc_check;
    deleteVehicle _unit;
    [_town, _saved] call OTQA_og_restore;
}, 60];

_tests pushBack ["Office: lost again when the occupier wins its QRF", {
    if !(call OTQA_og_idle) exitWith { ["Lost: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _town = (call OTQA_og_towns) select 1;
    private _saved = [_town] call OTQA_og_save;
    OT_QRFsetupTime = 0;
    server setVariable [format ["stability%1", _town], 0, true];
    // Held already (as after a load): straight to the QRF
    server setVariable [format ["officeheld%1", _town], true, true];
    [_town] spawn OT_fnc_officeCapture;
    private _timeout = time + 30;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo _town || { time > _timeout } };
    private _started = (server getVariable ["NATOattacking", ""]) isEqualTo _town;
    OT_QRFforceResult = 1;
    _timeout = time + 30;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    private _stability = server getVariable [format ["stability%1", _town], 0];
    private _held = server getVariable [format ["officeheld%1", _town], false];
    ["Lost: held at load, straight to the QRF", _started, ""] call OTQA_fnc_check;
    ["Lost: the occupier wins, stability 50, the office theirs again", _stability isEqualTo 50 && { !_held } && { !(_town in (server getVariable ["NATOabandoned", []])) }, format ["stability %1, held %2", _stability, _held]] call OTQA_fnc_check;
    [_town, _saved] call OTQA_og_restore;
}, 90];

_tests pushBack ["Office: called off when stability rises", {
    private _town = (call OTQA_og_towns) select 2;
    private _saved = [_town] call OTQA_og_save;
    server setVariable [format ["stability%1", _town], 0, true];
    [_town] spawn OT_fnc_officeCapture;
    sleep 2;
    server setVariable [format ["stability%1", _town], 10, true];
    private _task = format ["office%1", _town];
    private _timeout = time + 15;
    waitUntil { sleep 1; ([_task] call BIS_fnc_taskState) isEqualTo "CANCELED" || { time > _timeout } };
    sleep 1;
    ["Called off: the task cancelled, the capture over", ([_task] call BIS_fnc_taskState) isEqualTo "CANCELED" && { !(missionNamespace getVariable [format ["OT_officeCapture%1", _town], false]) }, [_task] call BIS_fnc_taskState] call OTQA_fnc_check;
    [_town, _saved] call OTQA_og_restore;
}, 30];

_tests pushBack ["Office: the radius covers a big building", {
    private _house = (call OTQA_og_towns) select 0;
    private _small = [_house] call OT_fnc_officeRadius;
    // Kavala's hospital as its office for the check (its layout comes from the designers)
    private _keep = OT_officeLayouts getOrDefault ["Kavala", nil];
    private _hospital = (nearestObjects [[3760.45, 12990.06, 0], ["Land_Hospital_main_F"], 10, true]) param [0, objNull];
    OT_officeLayouts set ["Kavala", [["Land_Hospital_main_F", getPosASL _hospital, getDir _hospital, false], [[], [], [], [], []]]];
    private _big = ["Kavala"] call OT_fnc_officeRadius;
    if (isNil "_keep") then { OT_officeLayouts deleteAt "Kavala" } else { OT_officeLayouts set ["Kavala", _keep] };
    ["Radius: 30 m round a house", _small isEqualTo 30, format ["%1: %2 m", _house, _small]] call OTQA_fnc_check;
    ["Radius: out to the wings round Kavala's hospital", !isNull _hospital && { _big > 45 }, format ["%1 m (hospital found %2)", round _big, !isNull _hospital]] call OTQA_fnc_check;
}, 10];

_tests pushBack ["Office: the area is the compound at the town's tier", {
    private _town = "Rodopoli";
    private _var = format ["officetier%1", _town];
    private _keep = server getVariable [_var, -1];
    private _pos = _town call OTQA_og_officePos;
    // A spot in the T3 and T4 areas (the HQ), one in T4 only, one outside both
    private _spots = [[18720, 16597, 0], [18750, 16575, 0], [18680, 16620, 0]] apply { createVehicleLocal ["Land_HelipadEmpty_F", _x, [], 0, "CAN_COLLIDE"] };
    private _ins = {
        params ["_tier"];
        server setVariable [_var, _tier];
        private _area = [_town] call OT_fnc_officeArea;
        [_area isEqualType [], _spots apply { [_x, _area, _pos] call OT_fnc_officeInArea }]
    };
    private _t3 = [3] call _ins;
    private _t4 = [4] call _ins;
    private _t1 = [1] call _ins;
    server setVariable [_var, [_keep, nil] select (_keep isEqualTo -1)];
    { deleteVehicle _x } forEach _spots;
    ["Area: tier 3 is the T3 compound (HQ in, T4-only spot out, outside out)", _t3 isEqualTo [true, [true, false, false]], str _t3] call OTQA_fnc_check;
    ["Area: tier 4 is the T4 compound (the T4-only spot in)", _t4 isEqualTo [true, [true, true, false]], str _t4] call OTQA_fnc_check;
    ["Area: tier 1 is the radius round the office", (_t1 select 0) isEqualTo false && { ((_t1 select 1) select 0) }, str _t1] call OTQA_fnc_check;
}, 10];

_tests pushBack ["Office: the compound's doors locked, picked and breached", {
    private _town = "Rodopoli";
    private _locked = { (_this select 0) getVariable [format ["bis_disabled_Door_%1", _this select 1], 0] };
    private _t3 = [_town, 3] call OT_fnc_officeDoors;
    diag_log format ["OT_QA locked doors %1 T3: %2", _town, _t3 apply { [typeOf (_x select 0), _x select 1, getPosATL (_x select 0)] }];
    private _t4 = [_town, 4] call OT_fnc_officeDoors;
    diag_log format ["OT_QA locked doors %1 T4: %2", _town, _t4 apply { [typeOf (_x select 0), _x select 1, getPosATL (_x select 0)] }];
    private _none = [_town, 0] call OT_fnc_officeDoors;
    private _allOpen = ((_t3 + _t4) findIf { (_x call _locked) isNotEqualTo 0 }) < 0;
    _t3 = [_town, 3] call OT_fnc_officeDoors;
    private _allLocked = (_t3 findIf { (_x call _locked) isNotEqualTo 1 }) < 0;
    // The block probe's buildings by the same rule: T3 the house across its line (6 doors), T4 the two houses
    // across its line and the garage (13)
    ["Doors: T3 locks the doors out of the compound, the building knows them", (count _t3) isEqualTo 6 && { (count _t4) isEqualTo 13 } && _allLocked && { (_t3 findIf { !((_x select 1) in ((_x select 0) getVariable ["OT_lockedDoors", []])) }) < 0 }, format ["%1 locked at T3, %2 at T4", count _t3, count _t4]] call OTQA_fnc_check;
    ["Doors: none locked for no tier, all unlocked again", _none isEqualTo [] && _allOpen, str count _none] call OTQA_fnc_check;

    // The lockpick: one door unlocked, the rest kept
    (_t3 select 0) params ["_pb", "_pd"];
    [_pb, _pd] call OT_fnc_officeUnlock;
    private _picked = ([_pb, _pd] call _locked) isEqualTo 0 && { !(_pd in (_pb getVariable ["OT_lockedDoors", []])) };
    private _others = ((_t3 - [[_pb, _pd]]) findIf { (_x call _locked) isNotEqualTo 1 }) < 0;
    ["Lockpick: the door unlocked, the others still locked", _picked && _others, format ["%1 door %2", typeOf _pb, _pd]] call OTQA_fnc_check;

    // A charge at a locked door: it's breached, a locked door more than 3 m off isn't
    _t3 = [_town, 3] call OT_fnc_officeDoors;
    (_t3 select 0) params ["_bb", "_bd"];
    private _at = AGLToASL ([_bb, _bd] call OT_fnc_officeDoorPos);
    private _far = _t3 select { (AGLToASL ([_x select 0, _x select 1] call OT_fnc_officeDoorPos) distance _at) > 6 };
    [_at] call OT_fnc_officeBreach;
    private _breached = ([_bb, _bd] call _locked) isEqualTo 0;
    private _kept = (_far findIf { (_x call _locked) isNotEqualTo 1 }) < 0;
    ["Charge: the door by it breached, those farther off still locked", _breached && _kept && { _far isNotEqualTo [] }, format ["%1 door %2, %3 farther off", typeOf _bb, _bd, count _far]] call OTQA_fnc_check;

    // A closed gate: locked, never picked, breached by a charge
    private _o = _town call OTQA_og_officePos;
    private _gatePos = AGLToASL [(_o select 0) + 400, (_o select 1) + 400, 0];
    (([[["object", "Land_NetFence_01_m_gate_F", _gatePos, [[0, 1, 0], [0, 0, 1]], ["ground"]]], west, true, [_town, 3]] call OT_fnc_officeSpawnItems) select 0) params ["_gate"];
    private _gateLocked = (_gate getVariable ["OT_officeGate", false]) && { ([_gate, 1] call _locked) isEqualTo 1 };
    [AGLToASL ((getPosATL _gate) vectorAdd [6, 0, 0])] call OT_fnc_officeBreach;
    private _stillLocked = ([_gate, 1] call _locked) isEqualTo 1;
    [getPosASL _gate] call OT_fnc_officeBreach;
    private _gateOpen = ([_gate, 1] call _locked) isEqualTo 0 && { !(_gate getVariable ["OT_officeGate", false]) };
    deleteVehicle _gate;
    ["Gate: a closed gate locked, a charge 6 m off leaves it, one at it breaches it", _gateLocked && _stillLocked && _gateOpen, format ["locked %1, after a far charge %2, breached %3", _gateLocked, _stillLocked, _gateOpen]] call OTQA_fnc_check;

    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
}, 20];

_tests pushBack ["Office: trees cleared round the lookout towers", {
    private _town = "Rodopoli";
    private _tower = (((([_town] call OT_fnc_officeLayout) select 1) select 2) select { "lookout" in (_x param [4, []]) }) param [0, []];
    if (_tower isEqualTo []) exitWith { ["Towers: Rodopoli's T3 has a lookout tower", false, ""] call OTQA_fnc_check };
    private _trees = nearestTerrainObjects [ASLToAGL (_tower select 2), ["TREE", "SMALL TREE", "BUSH"], 10, false, true];
    private _far = (nearestTerrainObjects [ASLToAGL (_tower select 2), ["TREE", "SMALL TREE", "BUSH"], 30, false, true]) select { ((_x distance2D ASLToAGL (_tower select 2)) > 14) && { !isObjectHidden _x } };
    [_town, 3] call OT_fnc_officeHide;
    private _hidden = (_trees findIf { !isObjectHidden _x }) < 0;
    private _farKept = (_far findIf { isObjectHidden _x }) < 0;
    private _apart = ((OT_officeHidden getOrDefault [_town, []]) arrayIntersect _trees) isEqualTo [];
    [_town, 1] call OT_fnc_officeHide;
    private _back = (_trees findIf { isObjectHidden _x }) < 0;
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    ["Towers: the trees within 10 m cleared at T3, those farther off kept, apart from the layout's hides", _trees isNotEqualTo [] && _hidden && _farKept && _apart, format ["%1 trees and bushes cleared, %2 farther off kept %3, apart %4", count _trees, count _far, _farKept, _apart]] call OTQA_fnc_check;
    ["Towers: the trees back at tier 1", _back, str _back] call OTQA_fnc_check;
}, 10];

_tests pushBack ["Office: the occupier holding it wins the fight", {
    if !(call OTQA_og_idle) exitWith { ["Fight: no QRF running first", false, server getVariable ["NATOattacking", ""]] call OTQA_fnc_check };
    private _town = (call OTQA_og_towns) select 3;
    private _saved = [_town] call OTQA_og_save;
    private _pos = _town call OTQA_og_officePos;
    OT_officeHoldTime = 10;
    OT_QRFsetupTime = 0;
    private _group = createGroup [blufor, true];
    private _them = _group createUnit [OT_NATO_Unit_Police, _pos, [], 0, "CAN_COLLIDE"];
    _them allowDamage false;
    _them disableAI "MOVE";
    OTQA_og_won = "";
    server setVariable ["NATOattacking", _town, true];
    private _h = [_pos, 0, { OTQA_og_won = "occupier" }, { OTQA_og_won = "resistance" }, [], _town, 30] spawn OT_fnc_NATOQRFfight;
    private _timeout = time + 40;
    waitUntil { sleep 1; scriptDone _h || { time > _timeout } };
    ["Fight: holding the office with nobody of ours inside wins it for the occupier", OTQA_og_won isEqualTo "occupier", format ["'%1' after %2 s", OTQA_og_won, round (40 - (_timeout - time))]] call OTQA_fnc_check;
    deleteVehicle _them;
    [_town, _saved] call OTQA_og_restore;
}, 60];

_tests pushBack ["Office: a tier removes map objects, others bring them back", {
    private _town = (call OTQA_og_towns) select 0;
    private _pos = _town call OTQA_og_officePos;
    // Two map walls or fences near the office, one removed from tier 2 on, the other at tier 3 only
    private _walls = (nearestTerrainObjects [_pos, ["WALL", "FENCE"], 60, true, true]) select { !isObjectHidden _x };
    if ((count _walls) < 2) exitWith { ["Hide: two map walls near the office", false, format ["%1: %2", _town, count _walls]] call OTQA_fnc_check };
    _walls params ["_a", "_b"];
    private _item = { ["hide", (getModelInfo _this) select 0, getPosASL _this, [vectorDir _this, vectorUp _this], []] };
    private _layout = OT_officeLayouts get _town;
    private _keep = +(_layout select 1);
    private _tiers = +_keep;
    _tiers set [1, (_tiers select 1) + [_a call _item]];
    _tiers set [2, (_tiers select 2) + [_a call _item, _b call _item]];
    _layout set [1, _tiers];
    private _seen = [1, 2, 3, 2, 0] apply { [_town, _x] call OT_fnc_officeHide; [isObjectHidden _a, isObjectHidden _b] };
    _layout set [1, _keep];
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    ["Hide: tier 1 none, 2 one, 3 both, back to 2 one, none with no tier", _seen isEqualTo [[false, false], [true, false], [true, true], [true, false], [false, false]], format ["%1: %2", _town, _seen]] call OTQA_fnc_check;
    // A tier put up hides its own (OT_fnc_officeApplyLayout), and spawns nothing for them
    _tiers = +_keep;
    _tiers set [0, (_tiers select 0) + [_a call _item]];
    _layout set [1, _tiers];
    ([_town, 1, west, true] call OT_fnc_officeApplyLayout) params ["_office", "_objects", "_guards"];
    private _hidden = isObjectHidden _a;
    private _made = count (_objects + _guards);
    [_office] call OT_fnc_officeClearTemplate;
    _layout set [1, _keep];
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    // A removal holds at the tiers above it: _a removed at tier 1 only stays hidden at tier 3
    _tiers = +_keep;
    _tiers set [0, (_tiers select 0) + [_a call _item]];
    _layout set [1, _tiers];
    [_town, 3] call OT_fnc_officeHide;
    private _up = isObjectHidden _a;
    _layout set [1, _keep];
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    ["Hide: a map object removed at a tier stays removed above it", _up && { !isObjectHidden _a }, format ["hidden at tier 3 %1, back after %2", _up, !isObjectHidden _a]] call OTQA_fnc_check;
    ["Hide: a tier put up hides its map objects, nothing made for them", _hidden && { _made isEqualTo count ((_keep select 0) select { !((_x select 0) in ["hide", "gate"]) }) } && { !isObjectHidden _a }, format ["hidden %1, %2 things made, back after %3", _hidden, _made, !isObjectHidden _a]] call OTQA_fnc_check;
}, 20];

_tests pushBack ["Office: a gate stands open", {
    private _pos = (((call OTQA_og_towns) select 0) call OTQA_og_officePos) vectorAdd [0, 60, 0];
    private _made = [[
        ["object", "Land_NetFence_01_m_gate_F", AGLToASL _pos, [[0, 1, 0], [0, 0, 1]], ["ground", "open"]],
        ["object", "Land_Net_Fence_Gate_F", AGLToASL (_pos vectorAdd [10, 0, 0]), [[0, 1, 0], [0, 0, 1]], ["ground", "open"]],
        ["gate", "4.0", AGLToASL (_pos vectorAdd [20, 0, 0]), [[0, 1, 0], [0, 0, 1]], []]
    ], west, true] call OT_fnc_officeSpawnItems;
    sleep 1;
    private _objects = _made select 0;
    private _phases = _objects apply { [_x animationSourcePhase "Door_1_sound_source", _x animationSourcePhase "Door_2_sound_source"] };
    { deleteVehicle _x } forEach _objects;
    ["Gate: both gates made open, nothing made for a gate marker", (count _objects) isEqualTo 2 && { (_phases findIf { (_x select 0) < 0.9 || { (_x select 1) < 0.9 } }) isEqualTo -1 }, format ["%1 made, door phases %2", count _objects, _phases]] call OTQA_fnc_check;
}, 20];

_tests
