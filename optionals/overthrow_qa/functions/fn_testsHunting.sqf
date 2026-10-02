/*
    Description:
    Hunting (OT_fnc_initHunting): spots picked from terrain, revealed by walking in, animals that
    spawn, count against the spot and come back, carcasses picked up as raw meat, the general store
    buying it, livestock costing support outside spots, the hunting licence and the cover it gives.
    Part of the current QA tests. Moves the host around and puts them back. Run it as the host (it
    reads the server's hunting state).

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Hunting: in play, a revealed spot is a yellow-green area on the map; shooting an animal and using 'Pick up the carcass' gives raw meat; a general store buys it and offers the hunting licence and gear" call OTQA_fnc_manual;
"Hunting: goats, sheep and hens wander around farm buildings outside towns" call OTQA_fnc_manual;

// The spot nearest the host: [index, position]
OTQA_hunt_spot = {
    private _spots = server getVariable ["huntingSpots", []];
    if (_spots isEqualTo []) exitWith { [] };
    private _sorted = [_spots apply { [_x distance2D player, _x] }, [], { _x select 0 }, "ASCEND"] call BIS_fnc_sortBy;
    private _pos = (_sorted select 0) select 1;
    [_spots find _pos, _pos]
};

// Agents of a spot
OTQA_hunt_animals = {
    params ["_index"];
    (agents apply { agent _x }) select { alive _x && { (_x getVariable ["OT_huntKey", ""]) isEqualTo format ["spot%1", _index] } }
};

[
    ["Hunting: spots picked from terrain", {
        private _spots = server getVariable ["huntingSpots", []];
        ["Hunting: spots were picked", (count _spots) > 5, format ["%1 spots on %2", count _spots, worldName]] call OTQA_fnc_check;
        private _bad = _spots select { surfaceIsWater _x || { [_x, 0] call OT_fnc_isInTown } };
        ["Hunting: on land, not in towns", _bad isEqualTo [], format ["%1 bad", count _bad]] call OTQA_fnc_check;
        private _bases = (OT_objectiveData + OT_airportData + OT_commsData) apply { _x select 0 };
        private _nearBase = _spots select { private _p = _x; (_bases findIf { (_x distance2D _p) < 800 }) > -1 };
        ["Hunting: away from bases and towers", _nearBase isEqualTo [], format ["%1 too close", count _nearBase]] call OTQA_fnc_check;
        ["Hunting: hunting rifles found, no automatic ones", (count OT_huntingWeapons) > 0 && { !("arifle_MX_F" in OT_huntingWeapons) } && { (!isClass (configFile >> "CfgWeapons" >> "sgun_HunterShotgun_01_F")) || { "sgun_HunterShotgun_01_F" in OT_huntingWeapons } },
            format ["%1 hunting rifles: %2", count OT_huntingWeapons, OT_huntingWeapons select [0, 6]]] call OTQA_fnc_check;
    }],

    ["Hunting: every spot is hidden until walked into", {
        private _spots = server getVariable ["huntingSpots", []];
        if (_spots isEqualTo []) exitWith { ["Hunting: spots to reveal", false, "no spots"] call OTQA_fnc_check };
        private _home = getPosATL player;
        private _wasRevealed = +(server getVariable ["huntingRevealed", []]);

        // All hidden
        server setVariable ["huntingRevealed", [], true];
        { deleteMarker format ["huntspot%1", _forEachIndex] } forEach _spots;
        private _shown = _spots select { (markerShape format ["huntspot%1", _forEachIndex]) isNotEqualTo "" };
        ["Hunting: all spots hidden", _shown isEqualTo [], format ["%1 still on the map", count _shown]] call OTQA_fnc_check;

        // Into each one: the hunting loop reveals it (run straight away, it also runs every 5 s)
        private _missed = [];
        {
            private _p = [_x select 0, _x select 1, 0] findEmptyPosition [0, 40, "CAManBase"];
            if (_p isEqualTo []) then { _p = [_x select 0, _x select 1, 0] };
            player setPosATL _p;
            sleep 0.3;
            call OT_fnc_huntingLoop;
            private _mrk = format ["huntspot%1", _forEachIndex];
            if !(_forEachIndex in (server getVariable ["huntingRevealed", []]) && { (markerColor _mrk) isEqualTo "OT_ColorHunting" }) then { _missed pushBack _forEachIndex };
        } forEach _spots;
        ["Hunting: walking into each spot reveals it", _missed isEqualTo [], format ["%1 of %2 revealed, missed: %3", (count _spots) - (count _missed), count _spots, _missed]] call OTQA_fnc_check;

        // Back as it was
        {
            if !(_forEachIndex in _wasRevealed) then { deleteMarker format ["huntspot%1", _forEachIndex] };
        } forEach _spots;
        server setVariable ["huntingRevealed", _wasRevealed, true];
        player setPosATL _home;
    }, 600],

    ["Hunting: walking in reveals a spot, its animals spawn", {
        (call OTQA_hunt_spot) params [["_index", -1], ["_pos", []]];
        if (_index < 0) exitWith { ["Hunting: a spot to test", false, "no spots"] call OTQA_fnc_check };
        private _home = getPosATL player;
        // Hidden again for the test
        private _revealed = server getVariable ["huntingRevealed", []];
        _revealed = _revealed - [_index];
        server setVariable ["huntingRevealed", _revealed, true];
        deleteMarker format ["huntspot%1", _index];

        player setPosATL (_pos findEmptyPosition [0, 50, "CAManBase"]);
        private _timeout = time + 15;
        waitUntil { sleep 1; _index in (server getVariable ["huntingRevealed", []]) || { time > _timeout } };
        private _mrk = format ["huntspot%1", _index];
        ["Hunting: walking in reveals it", _index in (server getVariable ["huntingRevealed", []]), format ["spot %1", _index]] call OTQA_fnc_check;
        ["Hunting: a yellow-green area 400 m across on the map", (markerShape _mrk) isEqualTo "ELLIPSE" && { (markerColor _mrk) isEqualTo "OT_ColorHunting" } && { ((markerSize _mrk) select 0) isEqualTo 200 },
            format ["%1, %2, %3", markerShape _mrk, markerColor _mrk, markerSize _mrk]] call OTQA_fnc_check;

        _timeout = time + 40;
        waitUntil { sleep 2; ([_index] call OTQA_hunt_animals) isNotEqualTo [] || { time > _timeout } };
        private _animals = [_index] call OTQA_hunt_animals;
        ["Hunting: its animals spawn (up to 5)", (count _animals) > 0 && { (count _animals) <= 5 } && { (_animals findIf { (_x distance2D _pos) > 260 }) isEqualTo -1 },
            format ["%1: %2", count _animals, _animals apply { typeOf _x }]] call OTQA_fnc_check;
        player setPosATL _home;
    }, 90],

    ["Hunting: kills count, come back, and carcasses give meat", {
        (call OTQA_hunt_spot) params [["_index", -1], ["_pos", []]];
        if (_index < 0) exitWith {};
        private _home = getPosATL player;
        player setPosATL (_pos findEmptyPosition [0, 50, "CAManBase"]);
        private _timeout = time + 40;
        waitUntil { sleep 2; ([_index] call OTQA_hunt_animals) isNotEqualTo [] || { time > _timeout } };
        private _animal = ([_index] call OTQA_hunt_animals) param [0, objNull];
        if (isNull _animal) exitWith { ["Hunting: an animal to hunt", false, "none spawned"] call OTQA_fnc_check; player setPosATL _home };

        private _key = format ["spot%1", _index];
        private _before = [_key] call OT_fnc_huntingAvailable;
        _animal setPosATL ((getPosATL player) getPos [2, getDir player]);
        _animal setDamage 1;
        sleep 1;
        private _after = [_key] call OT_fnc_huntingAvailable;
        ["Hunting: a kill counts against the spot", _after isEqualTo (_before - 1), format ["%1 -> %2", _before, _after]] call OTQA_fnc_check;

        // Picked up
        private _meat = OT_huntMeat getOrDefault [typeOf _animal, 0];
        private _had = { _x isEqualTo "OT_Meat" } count (items player);
        [_animal] spawn OT_fnc_huntPickup;
        sleep 4.5;
        private _has = { _x isEqualTo "OT_Meat" } count (items player);
        ["Hunting: the carcass becomes raw meat", isNull _animal && { _has >= _had } && { (_has - _had) <= _meat } && { _meat > 0 },
            format ["%1: +%2 meat in inventory (gives %3)", typeOf _animal, _has - _had, _meat]] call OTQA_fnc_check;

        // Comes back over 30 minutes
        private _state = OT_huntState get _key;
        OT_huntState set [_key, [_state select 0, _state select 1, (_state select 2) - 1800]];
        private _back = [_key] call OT_fnc_huntingAvailable;
        ["Hunting: 30 minutes later the spot is full again", _back isEqualTo (_state select 0), format ["%1 of %2", _back, _state select 0]] call OTQA_fnc_check;

        // The general store buys it
        private _town = player call OT_fnc_nearestTown;
        private _price = [_town, "OT_Meat", 0] call OT_fnc_getSellPrice;
        private _added = false;
        if (!("OT_Meat" in items player) && { player canAdd "OT_Meat" }) then { player addItem "OT_Meat"; _added = true };
        private _stock = ([player, "General"] call OT_fnc_unitStock) apply { _x select 0 };
        ["Hunting: a general store buys raw meat", _price >= 30 && { "OT_Meat" in _stock || { !("OT_Meat" in items player) } }, format ["$%1 each in %2", _price, _town]] call OTQA_fnc_check;
        if (_added) then { player removeItem "OT_Meat" };
        for "_i" from 1 to (_has - _had) do { player removeItem "OT_Meat" };
        player setPosATL _home;
    }, 90],

    ["Hunting: livestock costs support outside a spot", {
        private _spawnGoat = {
            params ["_p"];
            private _g = createAgent ["Goat_random_F", _p, [], 0, "CAN_COLLIDE"];
            _g setVariable ["OT_huntKey", "farmQA"];
            _g addEventHandler ["Killed", { _this call OT_fnc_farmAnimalKilled }];
            _g
        };
        // Outside any spot: the host's position, or a step away from the nearest spot's edge
        private _p = getPosATL player;
        if ((_p call OT_fnc_inHuntingSpot) > -1) then { _p = _p getPos [400, 0] };
        private _town = _p call OT_fnc_nearestTown;
        private _rep = [_town] call OT_fnc_support;
        private _goat = [_p getPos [3, 0]] call _spawnGoat;
        _goat setDamage [1, true, player, player];
        sleep 1;
        private _after = [_town] call OT_fnc_support;
        ["Hunting: a farm animal killed outside a spot costs 1 support", _after isEqualTo (_rep - 1), format ["%1: %2 -> %3", _town, _rep, _after]] call OTQA_fnc_check;
        deleteVehicle _goat;

        (call OTQA_hunt_spot) params [["_index", -1], ["_pos", []]];
        if (_index < 0) exitWith {};
        _town = _pos call OT_fnc_nearestTown;
        _rep = [_town] call OT_fnc_support;
        _goat = [_pos] call _spawnGoat;
        _goat setDamage [1, true, player, player];
        sleep 1;
        _after = [_town] call OT_fnc_support;
        ["Hunting: in a hunting spot it costs nothing", _after isEqualTo _rep, format ["%1: %2 -> %3", _town, _rep, _after]] call OTQA_fnc_check;
        deleteVehicle _goat;
    }],

    ["Hunting: the licence and the cover it gives", {
        (call OTQA_hunt_spot) params [["_index", -1], ["_pos", []]];
        if (_index < 0 || { OT_huntingWeapons isEqualTo [] }) exitWith {};
        private _home = getPosATL player;
        private _loadout = getUnitLoadout player;
        private _licence = player getVariable ["OT_huntLicence", 0];
        private _money = player getVariable ["money", 0];

        // Bought
        player setVariable ["money", _money + 300, true];
        call OT_fnc_buyHuntingLicence;
        ["Hunting: a licence costs $300 and lasts 2.5 hours", (player getVariable ["OT_huntLicence", 0]) isEqualTo 9000 && { (player getVariable ["money", 0]) isEqualTo _money }, format ["%1 s, $%2", player getVariable ["OT_huntLicence", 0], player getVariable ["money", 0]]] call OTQA_fnc_check;

        // Counts down in real time
        isNil {
            player setVariable ["OT_huntLicence", 100, true];
            OT_huntLicenceLast = time - 20;
            call OT_fnc_huntingLicenceLoop;
        };
        private _left = player getVariable ["OT_huntLicence", 0];
        ["Hunting: the licence counts down in real time", _left > 75 && { _left < 85 }, format ["100 s -> %1 s after 20 s", round _left]] call OTQA_fnc_check;

        // A hunting rifle in a spot (outside towns), with and without the licence, and in a town
        private _rifle = ["sgun_HunterShotgun_01_F", OT_huntingWeapons select 0] select !("sgun_HunterShotgun_01_F" in OT_huntingWeapons);
        removeAllWeapons player;
        player addWeapon _rifle;
        player setPosATL (_pos findEmptyPosition [0, 50, "CAManBase"]);
        player setVariable ["OT_huntLicence", 9000, true];
        private _legal = [player] call OT_fnc_isLegalHunter;
        private _armed = player call OT_fnc_hasWeaponEquipped;
        ["Hunting: licensed, outside towns: the hunting rifle keeps your cover", _legal && { !_armed } && { (player call OT_fnc_huntingLegalItems) isNotEqualTo [] }, format ["%1, armed %2", _rifle, _armed]] call OTQA_fnc_check;
        player setVariable ["OT_huntLicence", 0, true];
        ["Hunting: without a licence it doesn't", player call OT_fnc_hasWeaponEquipped, ""] call OTQA_fnc_check;
        player setVariable ["OT_huntLicence", 9000, true];
        private _town = player call OT_fnc_nearestTown;
        player setPosATL ((server getVariable _town) findEmptyPosition [0, 60, "CAManBase"]);
        ["Hunting: in a town it doesn't", player call OT_fnc_hasWeaponEquipped, _town] call OTQA_fnc_check;

        player setUnitLoadout _loadout;
        player setVariable ["OT_huntLicence", _licence, true];
        player setPosATL _home;
    }, 60]
]
