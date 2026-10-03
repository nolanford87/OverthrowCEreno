/*
    Description:
    Drugs, slice 1 (OT_fnc_initDrugs, OT_fnc_drugsVars): wild ganja zones (placement, hidden until near,
    reveal and marker, plants spawning and despawning, harvesting, a harvested-out zone replaced
    elsewhere), dispensaries (towns, buying, level 1 selling ganja, level 2 blow, drug operations, the
    heat hook, no cover lost) and gang bulk deals (wholesale and bulk prices, rep needed). Part of the
    current QA tests. Run it as the host. Moves the host around and puts them back; zones it grows
    are removed again, a dispensary it buys stays bought.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Drugs: in play, walking up to a wild ganja patch says so and puts a green area on the map; the plants look like shrubs on the ground (not floating or buried); 'Harvest the ganja plant' shows within 3 m of one" call OTQA_fnc_manual;
"Drugs: a dispensary shows on the map with a leaf icon and its name when zoomed in (like the shops); its budtender stands at a roadside stall; talking to him offers to stock the shelves (and to a general, the back room)" call OTQA_fnc_manual;
"Drugs: talking to a gang member or leader offers 'Can we do business in bulk?'; under +20 rep they turn you down, with it the bulk deals menu shows prices" call OTQA_fnc_manual;

// An empty carryall on the host for the test (their gear is put back after)
OTQA_ganja_room = {
    private _loadout = getUnitLoadout player;
    removeBackpack player;
    player addBackpack "B_Carryall_khk";
    clearAllItemsFromBackpack player;
    _loadout
};
OTQA_ganja_count = {
    params ["_cls"];
    { _x isEqualTo _cls } count (items player)
};
OTQA_ganja_zone = {
    params ["_id"];
    private _zones = server getVariable ["ganjaZones", []];
    _zones param [_zones findIf { (_x select 0) isEqualTo _id }, []]
};
// The host stands at a position (somewhere free near it)
OTQA_ganja_standAt = {
    params ["_p"];
    private _e = _p findEmptyPosition [0, 30, "CAManBase"];
    if (_e isEqualTo []) then { _e = _p };
    player setPosATL [_e select 0, _e select 1, 0];
};
// A dry spot on land at least _dist from _pos (for the host to stand)
OTQA_ganja_landAway = {
    params ["_pos", "_dist"];
    private _found = [];
    for "_dir" from 0 to 330 step 30 do {
        private _p = _pos getPos [_dist, _dir];
        if ((_p select 0) < 50 || { (_p select 1) < 50 } || { (_p select 0) > worldSize - 50 } || { (_p select 1) > worldSize - 50 }) then { continue };
        if (surfaceIsWater _p) then { continue };
        _p = _p findEmptyPosition [0, 60, "CAManBase"];
        if (_p isNotEqualTo [] && { !surfaceIsWater _p }) exitWith { _found = _p };
    };
    _found
};

OTQA_ganja_firstId = server getVariable ["ganjaNextId", 0]; // Zones from here on were grown by the tests
OTQA_ganja_testZone = -1;

[
    ["Drugs: setup, zones placed and hidden", {
        ["Drugs: drugs started", !isNil "OT_drugsInitDone" && { !isNil "OT_ganjaZonePlants" }, ""] call OTQA_fnc_check;
        private _zones = server getVariable ["ganjaZones", []];
        ["Drugs: 4 wild ganja zones (or replacements growing)", ((count _zones) + (count OT_ganjaRegrow)) >= OT_ganjaZoneCount && { (count _zones) <= OT_ganjaZoneCount + 1 },
            format ["%1 zones, %2 growing back", count _zones, count OT_ganjaRegrow]] call OTQA_fnc_check;
        private _bases = ((OT_objectiveData + OT_airportData + OT_commsData) apply { _x select 0 }) + [OT_NATO_HQPos];
        private _bad = _zones select {
            private _p = _x select 1;
            surfaceIsWater _p || { [_p, 500] call OT_fnc_isInTown } || { (_bases findIf { (_x distance2D _p) < 800 }) > -1 }
            || { (_p nearRoads 40) isNotEqualTo [] }
        };
        ["Drugs: zones on land in the countryside, away from towns, bases and roads", _bad isEqualTo [], format ["bad: %1", _bad apply { _x select 0 }]] call OTQA_fnc_check;
        private _close = _zones select { private _z = _x; (_zones findIf { _x isNotEqualTo _z && { ((_x select 1) distance2D (_z select 1)) < OT_ganjaZoneSpacing } }) > -1 };
        ["Drugs: zones 1.5 km or more apart", _close isEqualTo [], format ["too close: %1", _close apply { _x select 0 }]] call OTQA_fnc_check;
        private _wrong = _zones select { ((markerShape format ["ganjazone%1", _x select 0]) isNotEqualTo "") isNotEqualTo (_x select 3) };
        ["Drugs: only revealed zones are on the map", _wrong isEqualTo [], format ["wrong: %1", _wrong apply { _x select 0 }]] call OTQA_fnc_check;
        ["Drugs: plant models found", OT_ganjaPlantModels isNotEqualTo [] || { isClass (configFile >> "CfgVehicles" >> OT_ganjaPlantFallback) }, str OT_ganjaPlantModels] call OTQA_fnc_check;
        ["Drugs: ganja is illegal", "OT_Ganja" in OT_illegalItems, ""] call OTQA_fnc_check;

        // Spots the zone finder picks are valid
        private _spot = [] call OT_fnc_ganjaFindSpot;
        ["Drugs: the zone finder finds valid countryside spots", _spot isNotEqualTo [] && { [_spot] call OT_fnc_ganjaValidSpot }, str _spot] call OTQA_fnc_check;
        ["Drugs: a town centre is not a valid spot", !([OT_allTownPositions select 0] call OT_fnc_ganjaValidSpot), ""] call OTQA_fnc_check;
    }, 60],

    ["Drugs: a zone near the host, revealed when near, plants spawn and despawn", {
        private _home = getPosATL player;
        private _pos = [getPosATL player, 3000] call OT_fnc_ganjaFindSpot;
        if (_pos isEqualTo []) then { _pos = [getPosATL player, 6000, [], 800] call OT_fnc_ganjaFindSpot };
        if (_pos isEqualTo []) exitWith { ["Drugs: a spot for a test zone near the host", false, "none found within 6 km"] call OTQA_fnc_check };
        private _id = [_pos] call OT_fnc_ganjaNewZone;
        OTQA_ganja_testZone = _id;
        private _zone = [_id] call OTQA_ganja_zone;
        private _mrk = format ["ganjazone%1", _id];
        ["Drugs: a new zone is hidden, with 6-8 plants", _zone isNotEqualTo [] && { !(_zone select 3) } && { (markerShape _mrk) isEqualTo "" } && { (_zone select 2) >= 6 } && { (_zone select 2) <= 8 },
            str _zone] call OTQA_fnc_check;

        // 150 m away: still hidden; plants spawn (in spawn distance)
        private _off = [_pos, 150] call OTQA_ganja_landAway;
        if (_off isEqualTo []) then { _off = _pos getPos [150, 0] };
        player setPosATL _off;
        sleep 0.5;
        call OT_fnc_ganjaLoop;
        ["Drugs: 150 m away it stays hidden", !(([_id] call OTQA_ganja_zone) select 3) && { (markerShape _mrk) isEqualTo "" }, ""] call OTQA_fnc_check;
        private _timeout = time + 40;
        waitUntil { sleep 1; ((OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x }) isNotEqualTo [] || { time > _timeout } };
        private _plants = (OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x };
        ["Drugs: its plants spawn when a player is in spawn distance, within 30 m", (count _plants) isEqualTo (_zone select 2) && { (_plants findIf { (_x distance2D _pos) > 31 }) isEqualTo -1 },
            format ["%1 plants of %2", count _plants, _zone select 2]] call OTQA_fnc_check;
        ["Drugs: every machine knows the plants (harvest action)", (_plants findIf { !(_x in OT_ganjaPlants) }) isEqualTo -1, format ["%1 in OT_ganjaPlants", count OT_ganjaPlants]] call OTQA_fnc_check;
        private _low = _plants select { ((getPosATL _x) select 2) > 3 || { ((getPosATL _x) select 2) < -3 } };
        ["Drugs: plants sit on the ground", _low isEqualTo [], str (_plants apply { round (((getPosATL _x) select 2) * 10) / 10 })] call OTQA_fnc_check;

        // Walking in reveals it, for everyone, saved
        [_pos] call OTQA_ganja_standAt;
        sleep 0.5;
        call OT_fnc_ganjaLoop;
        ["Drugs: walking in reveals it, a green area on the map", (([_id] call OTQA_ganja_zone) select 3) && { (markerShape _mrk) isEqualTo "ELLIPSE" } && { (markerColor _mrk) isEqualTo "ColorGreen" },
            format ["%1, %2, %3", markerShape _mrk, markerColor _mrk, markerSize _mrk]] call OTQA_fnc_check;

        // Far away: the plants despawn (30 s after spawning at the soonest), back again they respawn
        private _far = [_pos, OT_spawnDistance + 900] call OTQA_ganja_landAway;
        if (_far isEqualTo []) exitWith {
            "Drugs: no dry land far enough from the test zone to check its plants despawn" call OTQA_fnc_manual;
            player setPosATL _home;
        };
        player setPosATL _far;
        _timeout = time + 75;
        waitUntil { sleep 2; (_plants findIf { !isNull _x }) isEqualTo -1 || { time > _timeout } };
        ["Drugs: with nobody near, the plants despawn", (_plants findIf { !isNull _x }) isEqualTo -1, format ["%1 left", { !isNull _x } count _plants]] call OTQA_fnc_check;
        player setPosATL _off;
        _timeout = time + 40;
        waitUntil { sleep 1; ((OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x }) isNotEqualTo [] || { time > _timeout } };
        ["Drugs: back near, they spawn again", count ((OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x }) isEqualTo (_zone select 2), ""] call OTQA_fnc_check;
        player setPosATL _home;
    }, 240],

    ["Drugs: harvesting, a harvested-out zone is replaced elsewhere", {
        private _id = OTQA_ganja_testZone;
        private _zone = [_id] call OTQA_ganja_zone;
        if (_zone isEqualTo []) exitWith { ["Drugs: the test zone to harvest", false, "no test zone"] call OTQA_fnc_check };
        private _home = getPosATL player;
        private _pos = _zone select 1;
        private _loadout = call OTQA_ganja_room;
        [_pos] call OTQA_ganja_standAt;
        private _timeout = time + 40;
        waitUntil { sleep 1; ((OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x }) isNotEqualTo [] || { time > _timeout } };
        private _plants = (OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x };
        if (_plants isEqualTo []) exitWith { ["Drugs: plants to harvest", false, "none spawned"] call OTQA_fnc_check; player setUnitLoadout _loadout; player setPosATL _home };

        // The action: kneel 2.5 s, the plant goes, 2-4 ganja
        private _plant = _plants select 0;
        private _pp = getPosWorld _plant;
        player setPosATL [(_pp select 0) + 1, _pp select 1, 0];
        private _left = _zone select 2;
        private _had = ["OT_Ganja"] call OTQA_ganja_count;
        [] spawn OT_fnc_ganjaHarvest;
        sleep 4.5;
        private _got = (["OT_Ganja"] call OTQA_ganja_count) - _had;
        private _leftNow = ([_id] call OTQA_ganja_zone) select 2;
        private _gone = _plants select { isNull _x };
        ["Drugs: harvesting a plant gives 2-4 ganja, the plant goes", (count _gone) isEqualTo 1 && { _got >= 2 } && { _got <= 4 } && { _leftNow isEqualTo (_left - 1) },
            format ["+%1 ganja, plants %2 -> %3, %4 deleted", _got, _left, _leftNow, count _gone]] call OTQA_fnc_check;
        // One still there but no longer in the zone (deleted this frame) isn't harvested again either
        private _again = (_plants select { !isNull _x }) select 0;
        OT_ganjaZonePlants set [_id, (OT_ganjaZonePlants get _id) - [_again]];
        ["Drugs: a plant can't be harvested twice", ([_again, player] call OT_fnc_ganjaPick) isEqualTo 0 && { ([objNull, player] call OT_fnc_ganjaPick) isEqualTo 0 }, ""] call OTQA_fnc_check;
        OT_ganjaZonePlants set [_id, (OT_ganjaZonePlants get _id) + [_again]];

        // The rest: the last one harvests the zone out
        _had = ["OT_Ganja"] call OTQA_ganja_count;
        private _total = 0;
        { _total = _total + ([_x, player] call OT_fnc_ganjaPick) } forEach ((OT_ganjaZonePlants getOrDefault [_id, []]) select { !isNull _x });
        sleep 1;
        _got = (["OT_Ganja"] call OTQA_ganja_count) - _had;
        private _regrow = OT_ganjaRegrow select { (_x select 1) isNotEqualTo [] && { ((_x select 1) distance2D _pos) < 1 } };
        ["Drugs: harvested out, the zone and its marker vanish", ([_id] call OTQA_ganja_zone) isEqualTo [] && { (markerShape format ["ganjazone%1", _id]) isEqualTo "" } && { _got isEqualTo _total } && { _total >= 2 * (_left - 1) },
            format ["+%1 ganja (%2 given)", _got, _total]] call OTQA_fnc_check;
        ["Drugs: a replacement grows in 30-60 real minutes", (count _regrow) isEqualTo 1 && { ((_regrow select 0 select 0) - time) >= 1790 } && { ((_regrow select 0 select 0) - time) <= 3600 },
            format ["%1", _regrow apply { round ((_x select 0) - time) }]] call OTQA_fnc_check;

        // Its timer up: a new zone elsewhere
        private _before = server getVariable ["ganjaNextId", 0];
        (_regrow select 0) set [0, time - 1];
        call OT_fnc_ganjaLoop;
        _timeout = time + 60;
        waitUntil { sleep 1; (server getVariable ["ganjaNextId", 0]) > _before || { time > _timeout } };
        sleep 0.5;
        private _new = ([_before] call OTQA_ganja_zone);
        ["Drugs: when its timer is up, a new hidden zone grows elsewhere", _new isNotEqualTo [] && { ((_new select 1) distance2D _pos) >= OT_ganjaZoneSpacing } && { !(_new select 3) },
            format ["new zone %1, %2 m from the old one", _new param [0, -1], round ((_new param [1, _pos]) distance2D _pos)]] call OTQA_fnc_check;

        player setUnitLoadout _loadout;
        player setPosATL _home;
    }, 180],

    ["Drugs: dispensary towns, buying one, drug operations", {
        ["Drugs: 1-2 dispensaries, each a business with its own map icon", (count OT_dispensaries) in [1, 2] && { (OT_dispensaries findIf { (_x call OT_fnc_getBusinessData) isEqualTo [] || { (markerType _x) isNotEqualTo "ot_Dispensary" } }) isEqualTo -1 },
            format ["%1, markers %2", OT_dispensaries, OT_dispensaries apply { markerType _x }]] call OTQA_fnc_check;
        if (OT_dispensaries isEqualTo []) exitWith {};
        private _towns = OT_dispensaries apply { ((_x call OT_fnc_getBusinessData) select 0) call OT_fnc_nearestTown };
        ["Drugs: dispensaries in big or tourist towns", (_towns findIf { !(_x in OT_allTowns) }) isEqualTo -1, str _towns] call OTQA_fnc_check;
        private _crowded = OT_dispensaries select {
            private _n = _x;
            private _p = (_x call OT_fnc_getBusinessData) select 0;
            (OT_economicData findIf { (_x select 1) isNotEqualTo _n && { ((_x select 0) distance2D _p) < 150 } }) > -1
        };
        ["Drugs: dispensaries keep away from other businesses, on land", _crowded isEqualTo [] && { (OT_dispensaries findIf { surfaceIsWater ((_x call OT_fnc_getBusinessData) select 0) }) isEqualTo -1 }, str _crowded] call OTQA_fnc_check;
        ["Drugs: drugOps is a saved list", (server getVariable ["drugOps", 0]) isEqualType [], ""] call OTQA_fnc_check;

        // Buying one, as a general, from the main menu's Buy (OT_fnc_buyBusiness)
        private _name = OT_dispensaries select 0;
        private _pos = (_name call OT_fnc_getBusinessData) select 0;
        if !(call OT_fnc_playerIsGeneral) exitWith { "Drugs: the host isn't a general, buy a dispensary by hand and check it shows in the resistance screen" call OTQA_fnc_manual };
        private _home = getPosATL player;
        [_pos] call OTQA_ganja_standAt;
        sleep 0.5;
        private _price = _name call OT_fnc_getBusinessPrice;
        ["Drugs: a dispensary has a price", _price > 0, format ["$%1", _price]] call OTQA_fnc_check;
        if !(_name in (server getVariable ["GEURowned", []])) then {
            [_price + 1000] call OT_fnc_resistanceFunds;
            private _funds = [] call OT_fnc_resistanceFunds;
            call OT_fnc_buyBusiness;
            sleep 1.5;
            ["Drugs: the resistance buys it", _name in (server getVariable ["GEURowned", []]) && { (_funds - ([] call OT_fnc_resistanceFunds)) isEqualTo _price },
                format ["owned %1, paid $%2 of $%3", _name in (server getVariable ["GEURowned", []]), _funds - ([] call OT_fnc_resistanceFunds), _price]] call OTQA_fnc_check;
        } else {
            [_name] call OT_fnc_dispensaryRegister;
        };
        private _op = (server getVariable ["drugOps", []]) select { (_x select 0) isEqualTo _name };
        ["Drugs: it's registered as a drug operation [id, type, position, town, level]", (count _op) isEqualTo 1 && { ((_op select 0) select 1) isEqualTo "dispensary" } && { ((_op select 0) select 2) isEqualTo _pos } && { ((_op select 0) select 3) in OT_allTowns } && { ((_op select 0) select 4) in [1, 2] },
            str _op] call OTQA_fnc_check;
        player setPosATL _home;
    }, 60],

    ["Drugs: dispensary level 1 sells ganja, level 2 blow, the heat hook, no cover lost", {
        private _name = OT_dispensaries param [0, ""];
        if (_name isEqualTo "" || { !(_name in (server getVariable ["GEURowned", []])) }) exitWith { "Drugs: no bought dispensary to test its cycle" call OTQA_fnc_manual };
        private _pos = (_name call OT_fnc_getBusinessData) select 0;
        private _town = _pos call OT_fnc_nearestTown;
        // Level 1 for the test
        [_name, 1] call OT_fnc_dispensaryRegister;
        private _container = [_pos] call OT_fnc_dispensaryContainer;
        // Only what the test puts in: drugs already in containers there are taken out
        { private _c = _x; { [_c, _x, 9999] call OT_fnc_removeFromCargo } forEach ["OT_Ganja", "OT_Blow"] } forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);

        // The heat hook, stubbed when nothing provides it yet
        private _stubbed = isNil "OT_fnc_drugHeat";
        OTQA_heatCalls = [];
        if (_stubbed) then { OT_fnc_drugHeat = { OTQA_heatCalls pushBack _this } };

        // Stocking the shelves: the player's ganja goes in its container, cover kept
        private _home = getPosATL player;
        private _loadout = call OTQA_ganja_room;
        [_pos] call OTQA_ganja_standAt;
        player setCaptive true;
        for "_i" from 1 to 8 do { player addItem "OT_Ganja" };
        for "_i" from 1 to 4 do { player addItem "OT_Blow" };
        private _given = [_name] call OT_fnc_dispensaryStock;
        private _inBox = { _x isEqualTo "OT_Ganja" } count (itemCargo _container);
        ["Drugs: stocking the shelves moves the player's ganja (not blow at level 1) to its container, no cover lost", _given isEqualTo 8 && { _inBox isEqualTo 8 } && { (["OT_Ganja"] call OTQA_ganja_count) isEqualTo 0 } && { (["OT_Blow"] call OTQA_ganja_count) isEqualTo 4 } && { captive player },
            format ["handed %1, %2 in the box, captive %3", _given, _inBox, captive player]] call OTQA_fnc_check;
        _container addItemCargoGlobal ["OT_Blow", 4];
        for "_i" from 1 to 4 do { player removeItem "OT_Blow" };

        // Level 1: 3 ganja per employee, no blow
        private _ganjaPrice = [_town, "OT_Ganja"] call OT_fnc_getDrugPrice;
        private _blowPrice = [_town, "OT_Blow"] call OT_fnc_getDrugPrice;
        private _funds = [] call OT_fnc_resistanceFunds;
        private _income = [_name, _pos, 2] call OT_fnc_dispensaryCycle;
        private _gain = ([] call OT_fnc_resistanceFunds) - _funds;
        private _ganjaLeft = { _x isEqualTo "OT_Ganja" } count (itemCargo _container);
        private _blowLeft = { _x isEqualTo "OT_Blow" } count (itemCargo _container);
        ["Drugs: level 1 sells 3 ganja per employee at the town's drug price for resistance funds", _income isEqualTo (6 * _ganjaPrice) && { _gain isEqualTo _income } && { _ganjaLeft isEqualTo 2 } && { _blowLeft isEqualTo 4 },
            format ["income $%1 (6 x $%2 expected), funds +%3, %4 ganja and %5 blow left", _income, _ganjaPrice, _gain, _ganjaLeft, _blowLeft]] call OTQA_fnc_check;
        ["Drugs: selling at the dispensary costs no cover", captive player, ""] call OTQA_fnc_check;
        if (_stubbed) then {
            ["Drugs: each sale calls the heat hook [id, type, quantity]", OTQA_heatCalls isEqualTo [[_name, "ganja", 6]], str OTQA_heatCalls] call OTQA_fnc_check;
        } else {
            "Drugs: OT_fnc_drugHeat already exists, the hook calls weren't recorded: check its heat goes up when the dispensary sells" call OTQA_fnc_manual;
        };

        // Level 2: the back room, paid from resistance funds
        if (call OT_fnc_playerIsGeneral) then {
            [OT_dispensaryUpgradeCost + 1000] call OT_fnc_resistanceFunds;
            _funds = [] call OT_fnc_resistanceFunds;
            private _done = [_name] call OT_fnc_dispensaryUpgrade;
            sleep 0.5;
            ["Drugs: a general opens the back room for $25,000 resistance funds", _done && { (_name call OT_fnc_dispensaryLevel) isEqualTo 2 } && { (_funds - ([] call OT_fnc_resistanceFunds)) isEqualTo OT_dispensaryUpgradeCost },
                format ["level %1, paid $%2", _name call OT_fnc_dispensaryLevel, _funds - ([] call OT_fnc_resistanceFunds)]] call OTQA_fnc_check;
        } else {
            [_name, 2] call OT_fnc_dispensaryRegister;
        };
        OTQA_heatCalls = [];
        _funds = [] call OT_fnc_resistanceFunds;
        _income = [_name, _pos, 2] call OT_fnc_dispensaryCycle;
        _ganjaLeft = { _x isEqualTo "OT_Ganja" } count (itemCargo _container);
        _blowLeft = { _x isEqualTo "OT_Blow" } count (itemCargo _container);
        ["Drugs: level 2 also sells 1 blow per employee", _income isEqualTo ((2 * _ganjaPrice) + (2 * _blowPrice)) && { (([] call OT_fnc_resistanceFunds) - _funds) isEqualTo _income } && { _ganjaLeft isEqualTo 0 } && { _blowLeft isEqualTo 2 },
            format ["income $%1 (2 ganja $%2, 2 blow $%3 expected), %4 ganja and %5 blow left", _income, _ganjaPrice, _blowPrice, _ganjaLeft, _blowLeft]] call OTQA_fnc_check;
        if (_stubbed) then {
            ["Drugs: blow sales call the heat hook too", OTQA_heatCalls isEqualTo [[_name, "ganja", 2], [_name, "blow", 2]], str OTQA_heatCalls] call OTQA_fnc_check;
        };
        private _op = (server getVariable ["drugOps", []]) select { (_x select 0) isEqualTo _name };
        ["Drugs: its drug operation shows level 2", (count _op) isEqualTo 1 && { ((_op select 0) select 4) isEqualTo 2 }, str _op] call OTQA_fnc_check;
        ["Drugs: nothing in stock, nothing sold", ([_name, _pos, 2] call OT_fnc_dispensaryCycle) isEqualTo (2 * _blowPrice) && { ([_name, _pos, 2] call OT_fnc_dispensaryCycle) isEqualTo 0 }, ""] call OTQA_fnc_check;

        if (_stubbed) then { OT_fnc_drugHeat = nil };
        player setCaptive false;
        player setUnitLoadout _loadout;
        player setPosATL _home;
    }, 60],

    ["Drugs: gang wholesale and bulk deals", {
        private _gangid = -1;
        for "_i" from 0 to (OT_civilians getVariable ["autogangid", -1]) do {
            if ((OT_civilians getVariable [format ["gang%1", _i], []]) isNotEqualTo []) exitWith { _gangid = _i };
        };
        if (_gangid < 0) exitWith { "Drugs: no gang on the map yet to test bulk deals with" call OTQA_fnc_manual };
        private _gang = OT_civilians getVariable [format ["gang%1", _gangid], []];
        private _town = _gang select 2;
        private _repKey = format ["gangrep%1", _gangid];
        private _rep = player getVariable [_repKey, 0];
        private _money = player getVariable ["money", 0];
        private _loadout = call OTQA_ganja_room;

        private _dealerG = [_town, "OT_Ganja"] call OT_fnc_getDrugPrice;
        private _dealerB = [_town, "OT_Blow"] call OT_fnc_getDrugPrice;
        private _buyG = [_gangid, "OT_Ganja", "buy"] call OT_fnc_gangDrugPrice;
        private _buyB = [_gangid, "OT_Blow", "buy"] call OT_fnc_gangDrugPrice;
        private _sellG = [_gangid, "OT_Ganja", "sell"] call OT_fnc_gangDrugPrice;
        private _sellB = [_gangid, "OT_Blow", "sell"] call OT_fnc_gangDrugPrice;
        ["Drugs: wholesale is 0.7x the dealer's price, bulk 0.6x (under the street's 1.2x), never bought back for more", _buyG isEqualTo (round (_dealerG * 0.7)) && { _buyB isEqualTo (round (_dealerB * 0.7)) } && { _sellG isEqualTo (round (_dealerG * 0.6)) } && { _sellB isEqualTo (round (_dealerB * 0.6)) } && { _sellG < _buyG } && { _buyG < _dealerG },
            format ["%1: dealer $%2/$%3, wholesale $%4/$%5, bulk $%6/$%7", _town, _dealerG, _dealerB, _buyG, _buyB, _sellG, _sellB]] call OTQA_fnc_check;

        // Not enough rep: no deals
        player setVariable [_repKey, OT_drugGangRep - 1, true];
        player setVariable ["money", 100000, true];
        for "_i" from 1 to 3 do { player addItem "OT_Ganja" };
        private _bought = [_gangid, "OT_Ganja"] call OT_fnc_gangWholesaleBuy;
        private _paid = [_gangid] call OT_fnc_gangBulkSell;
        ["Drugs: under +20 rep the gang won't deal in bulk", !_bought && { _paid isEqualTo 0 } && { (player getVariable ["money", 0]) isEqualTo 100000 } && { (["OT_Ganja"] call OTQA_ganja_count) isEqualTo 3 },
            format ["bought %1, paid %2, money %3", _bought, _paid, player getVariable ["money", 0]]] call OTQA_fnc_check;

        // Enough rep: a lot of 10 ganja and 5 blow wholesale
        player setVariable [_repKey, OT_drugGangRep, true];
        private _okG = [_gangid, "OT_Ganja"] call OT_fnc_gangWholesaleBuy;
        private _okB = [_gangid, "OT_Blow"] call OT_fnc_gangWholesaleBuy;
        private _spent = 100000 - (player getVariable ["money", 0]);
        ["Drugs: with +20 rep, buys 10 ganja and 5 blow wholesale", _okG && { _okB } && { _spent isEqualTo ((10 * _buyG) + (5 * _buyB)) } && { (["OT_Ganja"] call OTQA_ganja_count) isEqualTo 13 } && { (["OT_Blow"] call OTQA_ganja_count) isEqualTo 5 },
            format ["spent $%1, %2 ganja, %3 blow", _spent, ["OT_Ganja"] call OTQA_ganja_count, ["OT_Blow"] call OTQA_ganja_count]] call OTQA_fnc_check;
        player setVariable ["money", 10, true];
        ["Drugs: wholesale needs the money", !([_gangid, "OT_Ganja"] call OT_fnc_gangWholesaleBuy) && { (player getVariable ["money", 0]) isEqualTo 10 }, ""] call OTQA_fnc_check;

        // Bulk: everything, at the bulk price
        player setVariable ["money", 0, true];
        _paid = [_gangid] call OT_fnc_gangBulkSell;
        ["Drugs: sells all of it to the gang at the bulk price (more if the host's vehicles nearby carry drugs)", _paid >= ((13 * _sellG) + (5 * _sellB)) && { (player getVariable ["money", 0]) isEqualTo _paid } && { (["OT_Ganja"] call OTQA_ganja_count) isEqualTo 0 } && { (["OT_Blow"] call OTQA_ganja_count) isEqualTo 0 },
            format ["paid $%1", _paid]] call OTQA_fnc_check;

        player setVariable [_repKey, _rep, true];
        player setVariable ["money", _money, true];
        player setUnitLoadout _loadout;
    }, 60],

    ["Drugs: clean up the test zones", {
        private _mine = (server getVariable ["ganjaZones", []]) select { (_x select 0) >= OTQA_ganja_firstId };
        { [_x select 0] call OT_fnc_ganjaRemoveZone } forEach _mine;
        ["Drugs: zones grown by the tests removed", ((server getVariable ["ganjaZones", []]) findIf { (_x select 0) >= OTQA_ganja_firstId }) isEqualTo -1, format ["%1 removed", count _mine]] call OTQA_fnc_check;
    }]
]
