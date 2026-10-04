/*
    Description:
    Taking a town by its mayor's office (OT_fnc_officeTier, OT_fnc_spawnOffice, OT_fnc_officeCapture, the
    office mode of OT_fnc_NATOQRFfight). Part of the current QA tests.
    1. Tier: a town starts by its population bracket, never above bracket + 1 or its layout's top tier
    2. Spawner: the layout with crewed guards while the office is the occupier's, without guards once
       the resistance holds it
    3. Capture: the task, cleared and held (2 minutes, shortened), the office held, the QRF for it; the
       resistance wins it (forced) and has the town
    4. Lost again: the occupier wins the QRF (forced), stability 50, the office theirs again
    5. Called off: the town's stability rises before the office is taken, the task is cancelled
    6. The fight for the office: the occupier holding it with nobody of ours inside wins
    Uses towns far from the host, so their spawners stay out of it. The hold, the QRF's set-up and the
    results are shortened or forced (OT_officeHoldTime, OT_QRFsetupTime, OT_QRFforceResult).

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Office: in play, bring a town to stability 0: the task 'Take the mayor's office' appears; clear the office, hold it 2 minutes, then hold off the QRF that comes 10 minutes later" call OTQA_fnc_manual;
"Office: the black office markers on the map sit on each town's mayor's office" call OTQA_fnc_manual;
"Office: save while the office is held (before the QRF) and load: the guards don't come back and the QRF still comes" call OTQA_fnc_manual;
"Office: a QRF for the office that runs out (13 minutes with none of theirs left near, or 30) is a resistance win" call OTQA_fnc_manual;

// Towns with an office layout, farthest from the host first
OTQA_og_towns = {
    private _towns = OT_allTowns select { ([_x] call OT_fnc_officeLayout) isNotEqualTo [] };
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
    private _town = "Kavala";
    private _keepPop = server getVariable [format ["population%1", _town], 0];
    private _keepTier = server getVariable [format ["officetier%1", _town], 0];
    private _got = [];
    server setVariable [format ["officetier%1", _town], nil];
    {
        server setVariable [format ["population%1", _town], _x];
        _got pushBack ([_town] call OT_fnc_officeTier);
    } forEach [30, 70, 150, 300, 500];
    // Raised above its bracket + 1
    server setVariable [format ["population%1", _town], 30];
    server setVariable [format ["officetier%1", _town], 5];
    private _capped = [_town] call OT_fnc_officeTier;
    server setVariable [format ["population%1", _town], _keepPop];
    server setVariable [format ["officetier%1", _town], [_keepTier, nil] select (_keepTier isEqualTo 0)];
    ["Tier: starts by bracket (1, 1, 2, 3, 4)", _got isEqualTo [1, 1, 2, 3, 4], str _got] call OTQA_fnc_check;
    ["Tier: never above bracket + 1", _capped isEqualTo 2, str _capped] call OTQA_fnc_check;
    // A layout's top tier caps it too
    private _small = (call OTQA_og_towns) select { count ((([_x] call OT_fnc_officeLayout) select 1) select { _x isNotEqualTo [] }) isEqualTo 2 };
    if (_small isEqualTo []) exitWith { ["Tier: a two-tier layout to cap", false, "none"] call OTQA_fnc_check };
    private _t = _small select 0;
    private _pop = server getVariable [format ["population%1", _t], 0];
    server setVariable [format ["population%1", _t], 500];
    private _top = [_t] call OT_fnc_officeTier;
    server setVariable [format ["population%1", _t], _pop];
    ["Tier: never above the layout's top tier", _top isEqualTo 2, format ["%1 at 500 people: %2", _t, _top]] call OTQA_fnc_check;
}, 10];

_tests pushBack ["Office: the spawner, guards only while it's the occupier's", {
    private _town = (call OTQA_og_towns) select 0;
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

_tests
