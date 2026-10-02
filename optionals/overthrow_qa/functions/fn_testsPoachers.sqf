/*
    Description:
    Poachers (OT_fnc_initPoachers): animals killed in a hunting spot putting hunting pressure on it
    by their size (and a little on the spots near it) for 30 minutes, picking up meat rolling for a
    patrol (more likely the more pressure), the 1-3 patrol dressed as hunters, hostile to the player
    and the occupier, a patrol that sees the player calling for backup, killing it in time cancelling
    the call, the backup (a gun truck and a car, every seat filled, 600-900 m out), $25 a poacher,
    wiping them out clearing the pressure and keeping the spot quiet for 15 minutes, the hunting
    licence making no difference, leaving when their time is up and the cleanup. Part of the current
    QA tests. Moves the host around, gives them a shotgun, and puts them back; the host can't be hurt while it runs. Run it as the host (it reads and drives
    the server's poacher state).

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Poachers: in play, a patrol that sees you plays radio chatter (audible from about 400 m) for 5-10 seconds while one of them calls for backup; the message says so" call OTQA_fnc_manual;
"Poachers: the patrol looks like civilian hunters (hunting clothes, boonie hats or caps, a bandolier, hunting shotguns/rifles); the backup looks like armed bandits (guerrilla clothes, balaclavas or bandannas, vests, carbines) in an armed offroad and a civilian car" call OTQA_fnc_manual;
"Poachers: the backup drives in on the roads and the car's lot get out and search; their bodies, guns and vehicles can be looted" call OTQA_fnc_manual;

// The spot nearest the host: [index, position]
OTQA_poach_spot = {
    private _spots = server getVariable ["huntingSpots", []];
    if (_spots isEqualTo []) exitWith { [-1, []] };
    private _sorted = [_spots apply { [_x distance2D player, _x] }, [], { _x select 0 }, "ASCEND"] call BIS_fnc_sortBy;
    private _pos = (_sorted select 0) select 1;
    [_spots find _pos, _pos]
};

// A spot's poachers gone at once (deleted, not cleaned up later), its pressure and quiet cleared
OTQA_poach_clear = {
    params ["_index"];
    private _ev = OT_poacherEvents getOrDefault [_index, createHashMap];
    if ((count _ev) > 0) then {
        OT_poacherEvents deleteAt _index;
        {
            if (!isNull _x) then {
                if (isNull objectParent _x) then { deleteVehicle _x } else { (objectParent _x) deleteVehicleCrew _x };
            };
        } forEach ((_ev get "patrol") + (_ev get "backup"));
        { if (!isNull _x) then { deleteVehicle _x } } forEach (_ev get "vehicles");
    };
    [_index, 0, true] call OT_fnc_poacherPressure;
    if (!isNil "OT_poacherQuiet") then { OT_poacherQuiet deleteAt _index };
};

// Waits (up to _limit seconds) for a condition, the poacher loop runs every 2 s
OTQA_poach_wait = {
    params ["_cond", ["_limit", 6]];
    private _timeout = time + _limit;
    waitUntil { sleep 0.5; (call _cond) || { time > _timeout } };
    call _cond
};

// Somewhere at least 1.5 km from a position, on land (a town, or the host's start)
OTQA_poach_away = {
    params ["_pos"];
    private _p = OTQA_poach_home;
    if ((_p distance2D _pos) < 1500) then {
        private _towns = OT_allTowns select { ((server getVariable _x) distance2D _pos) > 1500 };
        if (_towns isNotEqualTo []) then { _p = server getVariable (selectRandom _towns) };
    };
    private _free = _p findEmptyPosition [0, 60, "CAManBase"];
    [_free, _p] select (_free isEqualTo [])
};

// Where the host started, their gear, licence and money: put back by the last test
OTQA_poach_home = getPosATL player;
OTQA_poach_loadout = getUnitLoadout player;
OTQA_poach_licence = player getVariable ["OT_huntLicence", 0];
OTQA_poach_damage = isDamageAllowed player;

[
    ["Poachers: a kill puts pressure on its spot by size, and a little on the spots near it", {
        private _spots = server getVariable ["huntingSpots", []];
        // A spot with another within 1.4 km, and one over 1.6 km away
        private _a = -1;
        private _b = -1;
        {
            private _p = _x;
            private _n = _spots findIf { _x isNotEqualTo _p && { (_x distance2D _p) < 1400 } };
            if (_n > -1) exitWith { _a = _forEachIndex; _b = _n };
        } forEach _spots;
        if (_a < 0) exitWith { ["Poachers: two spots near each other to test", false, format ["%1 spots", count _spots]] call OTQA_fnc_check };
        private _far = _spots findIf { (_x distance2D (_spots select _a)) > 1600 };
        { [_x] call OTQA_poach_clear } forEach ([_a, _b, _far] select { _x > -1 });

        [_a, "Rabbit_F"] call OT_fnc_poacherKill;
        private _pa = [_a] call OT_fnc_poacherPressure;
        ["Poachers: a rabbit puts 0.5 on its spot", _pa isEqualTo 0.5, format ["spot %1: %2", _a, _pa]] call OTQA_fnc_check;
        [_a, "Goat_random_F"] call OT_fnc_poacherKill;
        _pa = [_a] call OT_fnc_poacherPressure;
        private _pb = [_b] call OT_fnc_poacherPressure;
        private _pf = [[_far] call OT_fnc_poacherPressure, 0] select (_far < 0);
        ["Poachers: a goat puts 1.5 more", _pa isEqualTo 2, format ["%1", _pa]] call OTQA_fnc_check;
        ["Poachers: and a quarter of each on a spot within 1.5 km", _pb isEqualTo 0.5, format ["spot %1, %2 m away: %3", _b, round ((_spots select _a) distance2D (_spots select _b)), _pb]] call OTQA_fnc_check;
        ["Poachers: nothing on a spot further away", _pf isEqualTo 0, format ["spot %1: %2", _far, _pf]] call OTQA_fnc_check;
        ["Poachers: no patrol from kills alone (they come at the pickup)", !(_a in OT_poacherEvents), ""] call OTQA_fnc_check;

        // Kills count for 30 minutes
        OT_poacherPressure set [_a, [[time - 1801, 1.5], [time - 1000, 0.5]]];
        _pa = [_a] call OT_fnc_poacherPressure;
        ["Poachers: kills over 30 minutes old drop out", _pa isEqualTo 0.5, format ["%1", _pa]] call OTQA_fnc_check;
        OT_poacherPressure set [_a, [[time - 1801, 1.5]]];
        _pa = [_a] call OT_fnc_poacherPressure;
        ["Poachers: nothing left, the spot is forgotten", _pa isEqualTo 0 && { !(_a in OT_poacherPressure) }, format ["%1", _pa]] call OTQA_fnc_check;
        { [_x] call OTQA_poach_clear } forEach ([_a, _b, _far] select { _x > -1 });
    }],

    ["Poachers: a hunting spot's animal killed by the player puts pressure on it", {
        (call OTQA_poach_spot) params ["_index", "_pos"];
        if (_index < 0) exitWith { ["Poachers: a spot to test", false, "no spots"] call OTQA_fnc_check };
        [_index] call OTQA_poach_clear;
        player allowDamage false;
        private _free = _pos findEmptyPosition [0, 50, "CAManBase"];
        player setPosATL ([_free, _pos] select (_free isEqualTo []));
        OTQA_poach_index = _index;
        private _live = { (agents apply { agent _x }) select { alive _x && { (_x getVariable ["OT_huntIndex", -1]) isEqualTo OTQA_poach_index } } };
        private _found = [{ (call _live) isNotEqualTo [] }, 15] call OTQA_poach_wait;
        if (!_found) exitWith { "Poachers: no live animal in the nearest spot (hunted out?); kill one by hand there, its spot gets hunting pressure" call OTQA_fnc_manual };
        private _animal = (call _live) select 0;
        _animal setDamage [1, true, player, player];
        sleep 1;
        private _p = [_index] call OT_fnc_poacherPressure;
        ["Poachers: the kill counts by its size", _p > 0, format ["%1 (%2)", _p, typeOf _animal]] call OTQA_fnc_check;
        [_index] call OTQA_poach_clear;
    }, 30],

    ["Poachers: picking up meat rolls for a patrol, more likely the more is taken", {
        (call OTQA_poach_spot) params ["_index", "_pos"];
        if (_index < 0) exitWith {};
        [_index] call OTQA_poach_clear;
        player allowDamage false;
        private _free = _pos findEmptyPosition [0, 50, "CAManBase"];
        player setPosATL ([_free, _pos] select (_free isEqualTo []));

        // Pressure 1 or under: never
        [_index, 1] call OT_fnc_poacherPressure;
        ["Poachers: no chance at 1 or under", !([_index, 0] call OT_fnc_poacherRoll), ""] call OTQA_fnc_check;
        // 3 (two goats): 30%
        [_index, 3, true] call OT_fnc_poacherPressure;
        ["Poachers: at 3, a roll over 30% misses", !([_index, 0.31] call OT_fnc_poacherRoll) && { !(_index in OT_poacherEvents) }, ""] call OTQA_fnc_check;
        ["Poachers: at 3, a roll under 30% sends them", [_index, 0.29] call OT_fnc_poacherRoll, ""] call OTQA_fnc_check;
        ["Poachers: no second patrol while they're there", !([_index, 0] call OT_fnc_poacherRoll), ""] call OTQA_fnc_check;
        [_index] call OTQA_poach_clear;
        // A lot: at most 60%
        [_index, 20] call OT_fnc_poacherPressure;
        ["Poachers: at most 60%", !([_index, 0.61] call OT_fnc_poacherRoll) && { [_index, 0.59] call OT_fnc_poacherRoll }, ""] call OTQA_fnc_check;

        if !(_index in OT_poacherEvents) exitWith {};
        private _patrol = (OT_poacherEvents get _index) get "patrol";
        private _u = _patrol select 0;
        ["Poachers: 1-3 of them, at the spot", (count _patrol) in [1, 2, 3] && { (_patrol findIf { !alive _x || { (_x distance2D _pos) > 450 } }) isEqualTo -1 },
            format ["%1 at %2 m", count _patrol, _patrol apply { round (_x distance2D _pos) }]] call OTQA_fnc_check;
        ["Poachers: OPFOR, hostile to the resistance and the occupier", (side group _u) isEqualTo opfor
            && { [opfor, side group player] call BIS_fnc_sideIsEnemy } && { [side group player, opfor] call BIS_fnc_sideIsEnemy }
            && { [opfor, blufor] call BIS_fnc_sideIsEnemy } && { [blufor, opfor] call BIS_fnc_sideIsEnemy },
            format ["%1 vs player %2 and %3", side group _u, side group player, blufor]] call OTQA_fnc_check;
        ["Poachers: not gang members", (_patrol findIf { (_x getVariable ["OT_gangid", -1]) > -1 || { !isNil { _x getVariable "criminal" } } }) isEqualTo -1, ""] call OTQA_fnc_check;
        ["Poachers: the patrol are hunters with hunting guns", (_patrol findIf { (_x getVariable ["OT_poacherLook", ""]) isNotEqualTo "hunter" || { primaryWeapon _x isEqualTo "" } || { uniform _x isEqualTo "" } }) isEqualTo -1,
            format ["%1", _patrol apply { [uniform _x, headgear _x, primaryWeapon _x, primaryWeaponMagazine _x] }]] call OTQA_fnc_check;
        private _stay = ((OT_poacherEvents get _index) get "until") - time;
        ["Poachers: they stay 10 minutes", _stay > (OT_poacherStayTime - 30) && { _stay <= OT_poacherStayTime }, format ["%1 s", round _stay]] call OTQA_fnc_check;

        // A chosen size: always 1-3
        private _counts = [];
        {
            [_index] call OTQA_poach_clear;
            private _g = [_index, _x] call OT_fnc_poacherPatrol;
            _counts pushBack (count units _g);
        } forEach [0, 0, 0, 5];
        ["Poachers: a patrol is never more than 3", (_counts findIf { _x < 1 || { _x > 3 } }) isEqualTo -1, format ["%1 (the last asked for 5)", _counts]] call OTQA_fnc_check;
        [_index] call OTQA_poach_clear;
        OTQA_poach_test = _index;
    }, 60],

    ["Poachers: seeing a player starts the call for backup, licence or not", {
        (call OTQA_poach_spot) params ["_index", "_pos"];
        if (_index < 0) exitWith {};
        // A fresh patrol (the last test's may have seen the host already)
        [_index] call OTQA_poach_clear;
        [_index, 2] call OT_fnc_poacherPatrol;
        player allowDamage false;

        // A legal hunter: licence, a hunting rifle only, outside towns, in cover
        private _rifle = ["sgun_HunterShotgun_01_F", OT_huntingWeapons param [0, ""]] select !("sgun_HunterShotgun_01_F" in OT_huntingWeapons);
        if (_rifle isNotEqualTo "") then {
            removeAllWeapons player;
            player addWeapon _rifle;
        };
        player setVariable ["OT_huntLicence", 9000, true];
        player setCaptive true;
        ["Poachers: the host is a legal hunter for this", [player] call OT_fnc_isLegalHunter, _rifle] call OTQA_fnc_check;

        private _ev = OT_poacherEvents get _index;
        private _patrol = (_ev get "patrol") select { alive _x };
        { _x setPosATL ((getPosATL player) getPos [40, random 360]) } forEach _patrol;
        { (group _x) reveal [player, 4] } forEach _patrol;
        private _calling = [{ (_ev get "state") isEqualTo "calling" }, 6] call OTQA_poach_wait;
        private _len = (_ev get "callEnd") - time;
        ["Poachers: a patrol that sees a player calls for backup", _calling, format ["state %1", _ev get "state"]] call OTQA_fnc_check;
        ["Poachers: the call takes 5-10 seconds", _calling && { _len >= 4 } && { _len <= 10 }, format ["ends in %1 s", _len]] call OTQA_fnc_check;
        sleep 1;
        ["Poachers: the licence doesn't help: the host lost their cover", !captive player, format ["legal hunter %1", [player] call OT_fnc_isLegalHunter]] call OTQA_fnc_check;
        OTQA_poach_test = _index;
    }, 30],

    ["Poachers: killing the patrol before the call goes through cancels the backup", {
        private _index = missionNamespace getVariable ["OTQA_poach_test", -1];
        private _ev = OT_poacherEvents getOrDefault [_index, createHashMap];
        if ((count _ev) isEqualTo 0 || { (_ev get "state") isNotEqualTo "calling" }) exitWith {
            ["Poachers: a patrol on the radio to kill", false, "the last test didn't leave one"] call OTQA_fnc_check;
        };
        // Time to do it (the call could be nearly through by now)
        _ev set ["callEnd", time + 10];
        private _patrol = (_ev get "patrol") select { alive _x };
        private _money = player getVariable ["money", 0];
        { _x setDamage [1, true, player, player] } forEach _patrol;
        sleep 1.5;
        private _paid = (player getVariable ["money", 0]) - _money;
        ["Poachers: $25 for each one killed", _paid isEqualTo (OT_poacherBounty * (count _patrol)), format ["+$%1 for %2", _paid, count _patrol]] call OTQA_fnc_check;
        private _over = [{ !(_index in OT_poacherEvents) }, 6] call OTQA_poach_wait;
        ["Poachers: all dead, they're done", _over, ""] call OTQA_fnc_check;
        ["Poachers: wiping them out clears the spot's pressure", ([_index] call OT_fnc_poacherPressure) isEqualTo 0, format ["%1", [_index] call OT_fnc_poacherPressure]] call OTQA_fnc_check;

        // Long past when the call would have gone through: no backup
        sleep ((((_ev get "callEnd") - time) max 0) + 4);
        private _backup = vehicles select { (_x getVariable ["OT_poacherVeh", -1]) isEqualTo _index && { alive _x } };
        ["Poachers: no backup comes", _backup isEqualTo [] && { (_ev get "backup") isEqualTo [] }, format ["%1", _backup apply { typeOf _x }]] call OTQA_fnc_check;
    }, 40],

    ["Poachers: the backup is a gun truck and a car, every seat filled, from 600-900 m", {
        (call OTQA_poach_spot) params ["_index", "_pos"];
        if (_index < 0) exitWith {};
        [_index] call OTQA_poach_clear;
        player allowDamage false;
        [_index, 1] call OT_fnc_poacherPatrol;
        [_index, 3] call OT_fnc_poacherPressure;
        ["Poachers: the call starts", [_index, player] call OT_fnc_poacherCall, ""] call OTQA_fnc_check;
        private _ev = OT_poacherEvents get _index;
        _ev set ["callEnd", time];
        private _came = [{ (_ev get "state") isEqualTo "backup" }, 6] call OTQA_poach_wait;
        ["Poachers: once the call goes through the backup comes", _came, format ["state %1", _ev get "state"]] call OTQA_fnc_check;
        if (!_came) exitWith {};

        private _vehicles = _ev get "vehicles";
        private _hmg = _vehicles select { (typeOf _x) in ["O_G_Offroad_01_armed_F", "I_G_Offroad_01_armed_F", "B_G_Offroad_01_armed_F"] };
        private _car = _vehicles select { (typeOf _x) in ["C_Offroad_01_F", "C_SUV_01_F", "C_Hatchback_01_F", "C_Hatchback_01_sport_F"] };
        // The car is claimed by the host (as if they took it): the cleanup has to leave it
        if (_car isNotEqualTo []) then { [_car select 0, getPlayerUID player] call OT_fnc_setOwner };
        ["Poachers: an offroad HMG and a civilian car", (count _vehicles) isEqualTo 2 && { (count _hmg) isEqualTo 1 } && { (count _car) isEqualTo 1 }, format ["%1", _vehicles apply { typeOf _x }]] call OTQA_fnc_check;
        private _empty = _vehicles select { ((fullCrew [_x, "", true]) findIf { isNull (_x select 0) }) > -1 };
        private _crew = [];
        { _crew append (crew _x) } forEach _vehicles;
        ["Poachers: every seat filled with poachers", _empty isEqualTo [] && { (_crew findIf { (_x getVariable ["OT_poacher", -1]) isNotEqualTo _index }) isEqualTo -1 } && { !isNull gunner (_hmg param [0, objNull]) },
            format ["%1 men: %2", count _crew, _vehicles apply { [typeOf _x, count crew _x, count (fullCrew [_x, "", true])] }]] call OTQA_fnc_check;
        ["Poachers: the backup are bandits with balaclavas or bandannas", (_crew findIf { (_x getVariable ["OT_poacherLook", ""]) isNotEqualTo "bandit" || { goggles _x isEqualTo "" } || { primaryWeapon _x isEqualTo "" } }) isEqualTo -1,
            format ["%1", (_crew select [0, 3]) apply { [uniform _x, goggles _x, primaryWeapon _x] }]] call OTQA_fnc_check;
        private _dists = _vehicles apply { round (_x distance2D _pos) };
        ["Poachers: they start 600-900 m out", (_dists findIf { _x < 570 || { _x > 930 } }) isEqualTo -1, format ["%1 m", _dists]] call OTQA_fnc_check;
        private _heading = _vehicles select { private _g = group (driver _x); !isNull _g && { ((waypoints _g) findIf { ((waypointPosition _x) distance2D player) < 200 }) > -1 } };
        ["Poachers: they head for the player", (count _heading) isEqualTo 2, format ["%1 of 2", count _heading]] call OTQA_fnc_check;
        private _stay = (_ev get "until") - time;
        ["Poachers: with the backup they stay 10 minutes from then", _stay > (OT_poacherStayTime - 30) && { _stay <= OT_poacherStayTime }, format ["%1 s", round _stay]] call OTQA_fnc_check;

        // All of them dead: paid for, pressure cleared
        private _all = ((_ev get "patrol") + (_ev get "backup")) select { alive _x };
        private _money = player getVariable ["money", 0];
        { _x setDamage [1, true, player, player] } forEach _all;
        sleep 2;
        private _paid = (player getVariable ["money", 0]) - _money;
        ["Poachers: $25 for each of them", _paid isEqualTo (OT_poacherBounty * (count _all)), format ["+$%1 for %2", _paid, count _all]] call OTQA_fnc_check;
        private _over = [{ !(_index in OT_poacherEvents) }, 6] call OTQA_poach_wait;
        ["Poachers: wiping out the spot clears its pressure", _over && { ([_index] call OT_fnc_poacherPressure) isEqualTo 0 }, format ["%1", [_index] call OT_fnc_poacherPressure]] call OTQA_fnc_check;
        // Quiet for 15 minutes after: however much is taken, no patrol until it's over
        private _quiet = (OT_poacherQuiet getOrDefault [_index, 0]) - time;
        ["Poachers: wiped out, the spot is quiet for 15 minutes", _quiet > (OT_poacherQuietTime - 60) && { _quiet <= OT_poacherQuietTime }, format ["%1 s left", round _quiet]] call OTQA_fnc_check;
        [_index, 20] call OT_fnc_poacherPressure;
        ["Poachers: no patrol while it's quiet, however much is taken", !([_index, 0] call OT_fnc_poacherRoll) && { !(_index in OT_poacherEvents) }, ""] call OTQA_fnc_check;
        OT_poacherQuiet set [_index, time - 1];
        ["Poachers: once the quiet is over, they can come again", [_index, 0] call OT_fnc_poacherRoll, ""] call OTQA_fnc_check;
        [_index] call OTQA_poach_clear;
        OTQA_poach_left = [(_ev get "patrol") + (_ev get "backup"), _hmg param [0, objNull], _car param [0, objNull], _pos];
    }, 60],

    ["Poachers: they leave when their time is up, everything is cleaned up once nobody is near", {
        (call OTQA_poach_spot) params ["_index", "_pos"];
        if (_index < 0) exitWith {};
        player allowDamage false;
        (missionNamespace getVariable ["OTQA_poach_left", []]) params [["_dead", []], ["_hmg", objNull], ["_car", objNull]];

        // A patrol whose time is up: they go, but stay until nobody is near. The host just outside
        // the spot with the patrol close by (so they don't call for backup)
        [_index] call OTQA_poach_clear;
        private _g = [_index, 2] call OT_fnc_poacherPatrol;
        private _patrol = units _g;
        private _edge = _pos getPos [320, random 360];
        player setPosATL ([_edge findEmptyPosition [0, 50, "CAManBase"], _edge] select ((_edge findEmptyPosition [0, 50, "CAManBase"]) isEqualTo []));
        { _x setPosATL ((getPosATL player) getPos [30, random 360]) } forEach _patrol;
        sleep 2.5;
        ["Poachers: they stay while their time runs", _index in OT_poacherEvents, ""] call OTQA_fnc_check;
        (OT_poacherEvents get _index) set ["until", time - 1];
        private _gone = [{ !(_index in OT_poacherEvents) }, 6] call OTQA_poach_wait;
        ["Poachers: once it's up they leave", _gone && { (_patrol findIf { !alive _x }) isEqualTo -1 }, ""] call OTQA_fnc_check;
        ["Poachers: still around while the player is near", (_patrol findIf { isNull _x }) isEqualTo -1, format ["%1 m away", _patrol apply { round (_x distance2D player) }]] call OTQA_fnc_check;

        // The host 1.5 km away: all gone, but the claimed car
        player setPosATL ([_pos] call OTQA_poach_away);
        sleep 1;
        call OT_fnc_poacherLoop;
        sleep 1;
        ["Poachers: the patrol that left is deleted", (_patrol findIf { !isNull _x }) isEqualTo -1, format ["%1 left", { !isNull _x } count _patrol]] call OTQA_fnc_check;
        ["Poachers: the dead and the gun truck are deleted", (_dead findIf { !isNull _x }) isEqualTo -1 && { isNull _hmg }, format ["%1 bodies left, gun truck %2", { !isNull _x } count _dead, _hmg]] call OTQA_fnc_check;
        ["Poachers: a vehicle the player claimed stays", !isNull _car, ""] call OTQA_fnc_check;
        if (!isNull _car) then { deleteVehicle _car };

        // Back as it was
        [_index] call OTQA_poach_clear;
        player setUnitLoadout OTQA_poach_loadout;
        player setVariable ["OT_huntLicence", OTQA_poach_licence, true];
        player setPosATL OTQA_poach_home;
        player allowDamage OTQA_poach_damage;
    }, 40]
]
