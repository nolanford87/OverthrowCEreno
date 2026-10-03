/*
    Description:
    Virtualized occupier FOB garrisons (OT_fnc_NATOregisterFOB, OT_fnc_spawnNATOFOB): a FOB's
    soldiers and gun crews are stored in its "NATOfobs" entry [position, soldiers on foot, upgrades,
    crewed HMGs, crewed mortars] and only spawned while a player is within spawn distance. Real FOBs
    are built 2-3 km from the host (out of spawn distance) or 250-400 m from it. The host can't be
    hurt and is captive while the tests run. Part of the current QA tests.
    1. Spawn: not spawned with no player near, spawned to its stored garrison once the host is near;
       soldiers killed come off the stored garrison and stay off after a despawn and respawn
    2. Upgrades: they add to the stored garrison, spawned at once if the FOB is spawned, not if not
    3. Loss: a despawned FOB with soldiers holds against a resistance soldier; a wiped out despawned
       one and a wiped out spawned one are cleared (construction, spawner) when the host walks in
    4. Takeover timer: the FOB disbands once the host is over 1 km away, despawned or spawned
    5. Soldiers that set a FOB up are handed to its spawner, despawned with no player near
    6. No live FOB garrison unit with no player near its FOB

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Virtual FOBs: save near a FOB after killing some of its soldiers and a HMG gunner, reload, walk up to it: it has the same soldiers and crewed guns left (none of the dead come back)" call OTQA_fnc_manual;
"Virtual FOBs: walk up to a FOB with a mortar: its soldiers patrol, its HMGs and mortar are crewed, the mortar still fires on known targets / during an occupier attack" call OTQA_fnc_manual;

// Everything the tests change on the host, to put back afterwards
OTQA_fobv_save = {
    OT_nextNATOTurn = time + 3600; // No NATO turn (upgrades) while a test runs
    private _saved = [getPosATL player, captive player, server getVariable ["NATOresources", 2000]];
    player allowDamage false;
    player setCaptive true;
    _saved;
};
OTQA_fobv_restore = {
    params ["_saved"];
    _saved params ["_home", "_captive", "_resources"];
    player setPosATL _home;
    player setCaptive _captive;
    player allowDamage true;
    server setVariable ["NATOresources", _resources, true];
    OT_nextNATOTurn = time + 120;
};

// A spot for a FOB _min to _max m from the host, [] if none was found
OTQA_fobv_spot = {
    params ["_min", "_max"];
    private _p = [getPos player, _min, _max, 15, 0, 0.3, 0] call BIS_fnc_findSafePos;
    private _dist = _p distance2D player;
    if (_dist < _min || { _dist > (_max + 200) }) exitWith { [] };
    [_p select 0, _p select 1, 0];
};

// A FOB as a loaded game has one: flag, upgrades built, garrison virtualized. Returns its entry
OTQA_fobv_make = {
    params ["_pos", "_foot", "_upgrades"];
    OT_flag_NATO createVehicle _pos;
    private _fob = [_pos, _foot, +_upgrades];
    private _fobs = server getVariable ["NATOfobs", []];
    _fobs pushBack _fob;
    [_fob] call OT_fnc_NATOregisterFOB;
    server setVariable ["NATOfobs", _fobs, true];
    [_pos, _upgrades] spawn OT_fnc_NATOupgradeFOB;
    _fob;
};

OTQA_fobv_entry = {
    params ["_pos"];
    (server getVariable ["NATOfobs", []]) select { (_x select 0) isEqualTo _pos } param [0, []];
};
OTQA_fobv_listed = {
    params ["_pos"];
    ((server getVariable ["NATOfobs", []]) findIf { (_x select 0) isEqualTo _pos }) > -1;
};

// Its stored garrison: [soldiers on foot, crewed HMGs, crewed mortars]
OTQA_fobv_stored = {
    params ["_pos"];
    private _fob = [_pos] call OTQA_fobv_entry;
    [_fob param [1, -1], _fob param [3, -1], _fob param [4, -1]];
};

// Its living garrison units ("" all of them, or a role: "foot", "HMG", "Mortar")
OTQA_fobv_live = {
    params ["_pos", ["_role", ""]];
    allUnits select {
        private _r = _x getVariable ["OT_fobRole", ""];
        (_x getVariable ["OT_fob", []]) isEqualTo _pos && { _r isNotEqualTo "" } && { _role isEqualTo "" || { _r isEqualTo _role } }
    };
};

// What is spawned: [soldiers on foot, crewed HMGs, crewed mortars]
OTQA_fobv_counts = {
    params ["_pos"];
    private _guns = {
        params ["_role"];
        private _list = [];
        { _list pushBackUnique (_x getVariable ["OT_fobGun", objNull]) } forEach ([_pos, _role] call OTQA_fobv_live);
        count _list;
    };
    [count ([_pos, "foot"] call OTQA_fobv_live), ["HMG"] call _guns, ["Mortar"] call _guns];
};

OTQA_fobv_spawnid = {
    params ["_pos"];
    OT_fobSpawners getOrDefault [_pos, ""];
};
OTQA_fobv_spawned = {
    params ["_pos"];
    private _id = [_pos] call OTQA_fobv_spawnid;
    _id isNotEqualTo "" && { _id in OT_allSpawned };
};

// Its guns (built empty by OT_fnc_NATOupgradeFOB)
OTQA_fobv_guns = {
    params ["_pos"];
    (nearestObjects [_pos, ["StaticWeapon"], 60]) select { (_x getVariable ["OT_fobStatic", []]) isEqualTo _pos };
};

// What it built still standing (flag, barriers, sandbags, statics)
OTQA_fobv_built = {
    params ["_pos"];
    count (nearestObjects [_pos, [OT_flag_NATO, OT_NATO_Barrier_Small, OT_NATO_Barrier_Large, OT_NATO_Sandbag_Curved, OT_NATO_HMG, OT_NATO_Mortar] + OT_NATO_StaticGarrison_LevelOne, 60]);
};

// Waits until it's spawned to its stored garrison (up to _timeout s)
OTQA_fobv_waitSpawned = {
    params ["_pos", ["_timeout", 45]];
    private _end = time + _timeout;
    waitUntil {
        sleep 1;
        ([_pos] call OTQA_fobv_spawned && { ([_pos] call OTQA_fobv_counts) isEqualTo ([_pos] call OTQA_fobv_stored) }) || { time > _end }
    };
};

// Waits until it's despawned (up to _timeout s, it stays at least 30 s after spawning)
OTQA_fobv_waitDespawned = {
    params ["_pos", ["_timeout", 120]];
    private _end = time + _timeout;
    waitUntil {
        sleep 2;
        (!([_pos] call OTQA_fobv_spawned) && { ([_pos] call OTQA_fobv_live) isEqualTo [] }) || { time > _end }
    };
};

// The host goes _dist m from it
OTQA_fobv_goNear = {
    params ["_pos", "_dist"];
    private _p = _pos getPos [_dist, random 360];
    private _empty = _p findEmptyPosition [0, 40, "C_man_1"];
    if (_empty isNotEqualTo []) then { _p = _empty };
    player setPosATL [_p select 0, _p select 1, 0];
};

// Clears a test FOB that is still there and the bodies of its garrison
OTQA_fobv_remove = {
    params ["_pos"];
    if ([_pos] call OTQA_fobv_listed) then {
        [_pos] call OT_fnc_NATOclearFOB;
        private _fobs = server getVariable ["NATOfobs", []];
        private _index = _fobs findIf { (_x select 0) isEqualTo _pos };
        if (_index > -1) then { _fobs deleteAt _index };
        server setVariable ["NATOfobs", _fobs, true];
    };
    { deleteVehicle _x } forEach (allDeadMen select { (_x getVariable ["OT_fob", []]) isEqualTo _pos });
    { deleteVehicle _x } forEach (nearestObjects [_pos, [OT_flag_NATO], 20]);
};

private _tests = [];

_tests pushBack ["Virtual FOB: spawned only near, deaths stay after a respawn", {
    private _saved = call OTQA_fobv_save;
    private _pos = [2000, 3000] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Spawn: a spot for the FOB 2-3 km away", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    [_pos, 6, ["Barriers", "HMG", "Mortar"]] call OTQA_fobv_make;
    sleep 15;

    private _guns = [_pos] call OTQA_fobv_guns;
    ["Spawn: not spawned with no player near", !([_pos] call OTQA_fobv_spawned) && { ([_pos] call OTQA_fobv_live) isEqualTo [] },
        format ["host %1 m away, %2 live", round (player distance2D _pos), count ([_pos] call OTQA_fobv_live)]] call OTQA_fnc_check;
    ["Spawn: its garrison is stored", ([_pos] call OTQA_fobv_stored) isEqualTo [6, 4, 1], str ([_pos] call OTQA_fobv_entry)] call OTQA_fnc_check;
    ["Spawn: its guns are built, empty", (count _guns) isEqualTo 5 && { (_guns findIf { (crew _x) isNotEqualTo [] }) isEqualTo -1 },
        format ["%1 guns, %2 crewed", count _guns, { (crew _x) isNotEqualTo [] } count _guns]] call OTQA_fnc_check;

    [_pos, 250] call OTQA_fobv_goNear;
    [_pos] call OTQA_fobv_waitSpawned;
    ["Spawn: spawned to its stored garrison once the host is near", [_pos] call OTQA_fobv_spawned && { ([_pos] call OTQA_fobv_counts) isEqualTo [6, 4, 1] },
        format ["spawned %1, stored %2", [_pos] call OTQA_fobv_counts, [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;

    // 2 soldiers and a HMG gunner killed
    private _foot = [_pos, "foot"] call OTQA_fobv_live;
    private _gunner = ([_pos, "HMG"] call OTQA_fobv_live) param [0, objNull];
    { _x setDamage 1 } forEach ((_foot select [0, 2]) + [_gunner]);
    sleep 2;
    ["Spawn: the dead come off the stored garrison", ([_pos] call OTQA_fobv_stored) isEqualTo [4, 3, 1], format ["stored %1", [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;

    player setPosATL (_saved select 0);
    [_pos] call OTQA_fobv_waitDespawned;
    ["Spawn: despawned once the host is away", !([_pos] call OTQA_fobv_spawned) && { ([_pos] call OTQA_fobv_live) isEqualTo [] } && { ([_pos] call OTQA_fobv_stored) isEqualTo [4, 3, 1] },
        format ["%1 live, stored %2", count ([_pos] call OTQA_fobv_live), [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;

    [_pos, 250] call OTQA_fobv_goNear;
    [_pos] call OTQA_fobv_waitSpawned;
    ["Spawn: respawned worn down, the dead don't come back", ([_pos] call OTQA_fobv_counts) isEqualTo [4, 3, 1] && { ([_pos] call OTQA_fobv_stored) isEqualTo [4, 3, 1] },
        format ["spawned %1, stored %2", [_pos] call OTQA_fobv_counts, [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;

    [_pos] call OTQA_fobv_remove;
    [_saved] call OTQA_fobv_restore;
}, 360];

_tests pushBack ["Virtual FOB: upgrades add to the stored garrison", {
    private _saved = call OTQA_fobv_save;
    private _pos = [2000, 3000] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Upgrades: a spot for the FOB 2-3 km away", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    private _fob = [_pos, 12, ["Barriers"]] call OTQA_fobv_make;
    // Only this FOB can be upgraded (OT_fnc_NATOupgradeFOBs upgrades the first one it can)
    private _upgrade = {
        params ["_spend"];
        private _all = server getVariable ["NATOfobs", []];
        server setVariable ["NATOfobs", [_fob], true];
        [_spend, -1] call OT_fnc_NATOupgradeFOBs;
        server setVariable ["NATOfobs", _all, true];
    };

    [_pos, 250] call OTQA_fobv_goNear;
    [_pos] call OTQA_fobv_waitSpawned;
    ["Upgrades: spawned", ([_pos] call OTQA_fobv_counts) isEqualTo [12, 0, 0], format ["spawned %1", [_pos] call OTQA_fobv_counts]] call OTQA_fnc_check;

    // 4 soldiers while spawned
    [160] call _upgrade;
    private _end = time + 20;
    waitUntil { sleep 1; (count ([_pos, "foot"] call OTQA_fobv_live)) >= 16 || { time > _end } };
    sleep 2;
    ["Upgrades: 4 soldiers stored and spawned at once while spawned", (([_pos] call OTQA_fobv_stored) select 0) isEqualTo 16 && { (count ([_pos, "foot"] call OTQA_fobv_live)) isEqualTo 16 },
        format ["stored %1, %2 live", [_pos] call OTQA_fobv_stored, count ([_pos, "foot"] call OTQA_fobv_live)]] call OTQA_fnc_check;

    // HMGs while spawned (16 soldiers: no more of them, barriers already up)
    [160] call _upgrade;
    _end = time + 30;
    waitUntil { sleep 1; (([_pos] call OTQA_fobv_counts) select 1) >= 4 || { time > _end } };
    ["Upgrades: HMGs stored and crewed at once while spawned", "HMG" in (_fob select 2) && { (([_pos] call OTQA_fobv_stored) select 1) isEqualTo 4 } && { (([_pos] call OTQA_fobv_counts) select 1) isEqualTo 4 },
        format ["upgrades %1, stored %2, spawned %3", _fob select 2, [_pos] call OTQA_fobv_stored, [_pos] call OTQA_fobv_counts]] call OTQA_fnc_check;

    // A mortar while despawned
    player setPosATL (_saved select 0);
    [_pos] call OTQA_fobv_waitDespawned;
    [310] call _upgrade;
    sleep 8;
    private _mortar = ([_pos] call OTQA_fobv_guns) select { typeOf _x isEqualTo OT_NATO_Mortar };
    ["Upgrades: a mortar stored, built and not crewed while despawned", (([_pos] call OTQA_fobv_stored) select 2) isEqualTo 1 && { (count _mortar) isEqualTo 1 } && { ([_pos] call OTQA_fobv_live) isEqualTo [] },
        format ["stored %1, %2 mortars, %3 live", [_pos] call OTQA_fobv_stored, count _mortar, count ([_pos] call OTQA_fobv_live)]] call OTQA_fnc_check;

    [_pos, 250] call OTQA_fobv_goNear;
    [_pos] call OTQA_fobv_waitSpawned;
    ["Upgrades: all of it spawned once the host is near", ([_pos] call OTQA_fobv_counts) isEqualTo [16, 4, 1],
        format ["spawned %1, stored %2", [_pos] call OTQA_fobv_counts, [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;

    [_pos] call OTQA_fobv_remove;
    [_saved] call OTQA_fobv_restore;
}, 300];

_tests pushBack ["Virtual FOB: loss and clear-up, despawned and spawned", {
    private _saved = call OTQA_fobv_save;
    private _pos = [2000, 3000] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Loss: a spot for the FOB 2-3 km away", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    private _fob = [_pos, 4, ["Barriers"]] call OTQA_fobv_make;
    sleep 8;

    // A resistance soldier at the despawned FOB: its stored soldiers hold it
    private _group = createGroup [independent, true];
    private _rebel = _group createUnit [OT_NATO_Unit_TeamLeader, _pos getPos [10, random 360], [], 0, "NONE"];
    [_rebel] joinSilent _group;
    _rebel allowDamage false;
    call OT_fnc_NATOcheckFOBs;
    ["Loss: a despawned FOB with soldiers holds against a resistance soldier", [_pos] call OTQA_fobv_listed && { !([_pos] call OTQA_fobv_spawned) },
        format ["side %1, %2 m away, stored %3", side group _rebel, round (_rebel distance2D _pos), [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;
    deleteVehicle _rebel;

    // Wiped out (stored garrison 0), the host walks in
    _fob set [1, 0];
    private _spawnid = [_pos] call OTQA_fobv_spawnid;
    [_pos, 8] call OTQA_fobv_goNear;
    sleep 3;
    call OT_fnc_NATOcheckFOBs;
    sleep 1;
    ["Loss: a wiped out despawned FOB is cleared when the host walks in", !([_pos] call OTQA_fobv_listed) && { ([_pos] call OTQA_fobv_built) isEqualTo 0 }
        && { (OT_allSpawners findIf { (_x select 0) isEqualTo _spawnid }) isEqualTo -1 } && { !(_pos in OT_fobSpawners) },
        format ["listed %1, %2 objects left", [_pos] call OTQA_fobv_listed, [_pos] call OTQA_fobv_built]] call OTQA_fnc_check;
    [_pos] call OTQA_fobv_remove;

    // Spawned near the host, all of it killed, the host walks in
    player setPosATL (_saved select 0);
    _pos = [250, 400] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Loss: a spot for the FOB near the host", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    [_pos, 4, ["Barriers", "HMG"]] call OTQA_fobv_make;
    [_pos] call OTQA_fobv_waitSpawned;
    ["Loss: spawned near the host", ([_pos] call OTQA_fobv_counts) isEqualTo [4, 4, 0], format ["spawned %1", [_pos] call OTQA_fobv_counts]] call OTQA_fnc_check;
    private _dead = [_pos] call OTQA_fobv_live;
    { _x setDamage 1 } forEach _dead;
    sleep 2;
    ["Loss: wiped out, its stored garrison is 0", ([_pos] call OTQA_fobv_stored) isEqualTo [0, 0, 0], format ["stored %1", [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;
    // Any other occupier soldier within 300 m still holds it: killed too
    { _x setDamage 1 } forEach ((_pos nearEntities ["CAManBase", 300]) select { alive _x && { side group _x isEqualTo blufor } });
    _spawnid = [_pos] call OTQA_fobv_spawnid;
    [_pos, 8] call OTQA_fobv_goNear;
    sleep 3;
    call OT_fnc_NATOcheckFOBs;
    sleep 1;
    ["Loss: a wiped out spawned FOB is cleared, the bodies stay", !([_pos] call OTQA_fobv_listed) && { ([_pos] call OTQA_fobv_built) isEqualTo 0 }
        && { !(_spawnid in OT_allSpawned) } && { !(_pos in OT_fobSpawners) } && { (_dead findIf { isNull _x }) isEqualTo -1 },
        format ["listed %1, %2 objects left, %3 of %4 bodies", [_pos] call OTQA_fobv_listed, [_pos] call OTQA_fobv_built, { !isNull _x } count _dead, count _dead]] call OTQA_fnc_check;

    [_pos] call OTQA_fobv_remove;
    [_saved] call OTQA_fobv_restore;
}, 240];

_tests pushBack ["Virtual FOB: takeover timer, despawned and spawned", {
    private _saved = call OTQA_fobv_save;
    private _runTimer = {
        params ["_pos"];
        private _timers = server getVariable ["NATOfobTimers", []];
        _timers pushBack [_pos, 1, _pos call OT_fnc_nearestTown];
        server setVariable ["NATOfobTimers", _timers];
        OT_fobTimerLast = time - 5;
        call OT_fnc_NATOFOBtimers;
    };

    // Despawned: the timer runs out with the host 2-3 km away, it disbands
    private _pos = [2000, 3000] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Timer: a spot for the FOB 2-3 km away", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    [_pos, 4, ["Barriers"]] call OTQA_fobv_make;
    sleep 8;
    private _spawnid = [_pos] call OTQA_fobv_spawnid;
    [_pos] call _runTimer;
    sleep 1;
    call OT_fnc_NATOFOBtimers;
    sleep 1;
    ["Timer: a despawned FOB disbands", !([_pos] call OTQA_fobv_listed) && { ([_pos] call OTQA_fobv_built) isEqualTo 0 } && { !(_pos in OT_fobSpawners) }
        && { (OT_allSpawners findIf { (_x select 0) isEqualTo _spawnid }) isEqualTo -1 } && { ([_pos] call OTQA_fobv_live) isEqualTo [] },
        format ["listed %1, %2 objects left", [_pos] call OTQA_fobv_listed, [_pos] call OTQA_fobv_built]] call OTQA_fnc_check;
    [_pos] call OTQA_fobv_remove;

    // Spawned: the timer runs out with the host near, it disbands once the host is over 1 km away
    _pos = [250, 400] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Timer: a spot for the FOB near the host", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    private _fob = [_pos, 4, ["Barriers", "HMG"]] call OTQA_fobv_make;
    [_pos] call OTQA_fobv_waitSpawned;
    _spawnid = [_pos] call OTQA_fobv_spawnid;
    [_pos] call _runTimer;
    ["Timer: a spawned FOB stays while the host is near", [_pos] call OTQA_fobv_listed && { "Disband" in (_fob select 2) } && { ([_pos] call OTQA_fobv_counts) isEqualTo [4, 4, 0] },
        format ["upgrades %1, spawned %2", _fob select 2, [_pos] call OTQA_fobv_counts]] call OTQA_fnc_check;
    private _away = [getPos player, 1500, 2200, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
    player setPosATL [_away select 0, _away select 1, 0];
    sleep 2;
    call OT_fnc_NATOFOBtimers;
    sleep 1;
    ["Timer: a spawned FOB disbands once the host is away, its garrison gone", !([_pos] call OTQA_fobv_listed) && { ([_pos] call OTQA_fobv_built) isEqualTo 0 }
        && { ([_pos] call OTQA_fobv_live) isEqualTo [] } && { !(_spawnid in OT_allSpawned) } && { !(_pos in OT_fobSpawners) },
        format ["host %1 m away, listed %2, %3 objects, %4 live", round (player distance2D _pos), [_pos] call OTQA_fobv_listed, [_pos] call OTQA_fobv_built, count ([_pos] call OTQA_fobv_live)]] call OTQA_fnc_check;

    [_pos] call OTQA_fobv_remove;
    [_saved] call OTQA_fobv_restore;
}, 150];

_tests pushBack ["Virtual FOB: soldiers setting a FOB up are handed to its spawner", {
    private _saved = call OTQA_fobv_save;
    private _pos = [2000, 3000] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Set up: a spot for the FOB 2-3 km away", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    // As OT_fnc_NATOGroupDeployFOB does
    private _group = createGroup [blufor, true];
    for "_i" from 1 to 3 do {
        _group createUnit [selectRandom OT_NATO_Units_LevelOne, _pos getPos [10, random 360], [], 0, "NONE"];
    };
    OT_flag_NATO createVehicle _pos;
    private _fob = [_pos, { alive _x } count (units _group), [], 0, 0];
    private _fobs = server getVariable ["NATOfobs", []];
    _fobs pushBack _fob;
    [_fob, _group] call OT_fnc_NATOregisterFOB;
    server setVariable ["NATOfobs", _fobs, true];
    ["Set up: its soldiers are its spawned garrison", [_pos] call OTQA_fobv_spawned && { (count ([_pos, "foot"] call OTQA_fobv_live)) isEqualTo 3 },
        format ["%1 live", count ([_pos, "foot"] call OTQA_fobv_live)]] call OTQA_fnc_check;
    [_pos] call OTQA_fobv_waitDespawned;
    ["Set up: despawned with no player near, still stored", !([_pos] call OTQA_fobv_spawned) && { ([_pos] call OTQA_fobv_live) isEqualTo [] } && { (([_pos] call OTQA_fobv_stored) select 0) isEqualTo 3 },
        format ["%1 live, stored %2", count ([_pos] call OTQA_fobv_live), [_pos] call OTQA_fobv_stored]] call OTQA_fnc_check;

    [_pos] call OTQA_fobv_remove;
    [_saved] call OTQA_fobv_restore;
}, 180];

_tests pushBack ["Virtual FOB: no live garrison with no player near", {
    private _saved = call OTQA_fobv_save;
    private _pos = [2000, 3000] call OTQA_fobv_spot;
    if (_pos isEqualTo []) exitWith {
        ["Live units: a spot for the FOB 2-3 km away", false, "none found"] call OTQA_fnc_check;
        [_saved] call OTQA_fobv_restore;
    };
    [_pos, 16, ["Barriers", "HMG", "Mortar"]] call OTQA_fobv_make;
    sleep 15;
    // Every FOB out of every player's spawn distance: what it stores (all of it live before) and what is live
    private _players = allPlayers - entities "HeadlessClient_F";
    private _far = (server getVariable ["NATOfobs", []]) select {
        private _fobPos = _x select 0;
        (_players findIf { (_x distance2D _fobPos) < OT_spawnDistance }) isEqualTo -1
    };
    private _stored = 0;
    private _live = 0;
    {
        _stored = _stored + (_x param [1, 0]) + (_x param [3, 0]) + (_x param [4, 0]);
        _live = _live + count ([_x select 0] call OTQA_fobv_live);
    } forEach _far;
    ["Live units: no FOB soldier is live with no player near", _live isEqualTo 0 && { _stored >= 21 },
        format ["%1 FOBs out of spawn distance: %2 soldiers and gunners stored (live before), %3 live now", count _far, _stored, _live]] call OTQA_fnc_check;

    [_pos] call OTQA_fobv_remove;
    [_saved] call OTQA_fobv_restore;
}, 60];

_tests;
