/*
    Description:
    Fishing (OT_fnc_initFishing): fishing grounds offshore, their fish, casting a boat's net, general
    stores buying fish, turtles (contraband, sold to faction reps), fisheries at coastal towns' piers and
    their cycle. Part of the current QA tests. Run it as the host (it reads the server's fishing state);
    moves the host around and puts them back.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Fishing: in play, the boat dealer sells the motorboat (and the Tanoa fishing boat); its driver gets 'Cast the net' (every 15 s, going slowly), the catch goes in the boat's cargo" call OTQA_fnc_manual;
"Fishing: a faction rep offers to buy sea turtles; a gendarme / checkpoint search confiscates them" call OTQA_fnc_manual;

// The fishing ground nearest the host: [index, position]
OTQA_fish_ground = {
    private _grounds = server getVariable ["fishingGrounds", []];
    if (_grounds isEqualTo []) exitWith { [] };
    private _sorted = [_grounds apply { [_x distance2D player, _x] }, [], { _x select 0 }, "ASCEND"] call BIS_fnc_sortBy;
    private _pos = (_sorted select 0) select 1;
    [_grounds find _pos, _pos]
};

[
    ["Fishing: grounds picked offshore", {
        if (OT_piers isEqualTo []) exitWith { format ["Fishing: %1 has no sea, no fishing grounds or fisheries to test", worldName] call OTQA_fnc_manual };
        private _grounds = server getVariable ["fishingGrounds", []];
        ["Fishing: grounds were picked", (count _grounds) > 3, format ["%1 grounds on %2", count _grounds, worldName]] call OTQA_fnc_check;
        private _bad = [];
        {
            private _p = _x;
            private _open = true;
            for "_dir" from 0 to 315 step 45 do { if !(surfaceIsWater (_p getPos [400, _dir])) exitWith { _open = false } };
            if (!surfaceIsWater _p || { (getTerrainHeightASL _p) > -25 } || { !_open }) then { _bad pushBack _forEachIndex };
        } forEach _grounds;
        ["Fishing: in water 25 m deep or more, 400 m or more from any coast", _bad isEqualTo [], format ["bad: %1", _bad]] call OTQA_fnc_check;
        private _close = [];
        { private _p = _x; private _i = _forEachIndex; if ((_grounds findIf { _x isNotEqualTo _p && { (_x distance2D _p) < 3990 } }) > -1) then { _close pushBack _i } } forEach _grounds;
        ["Fishing: about one per 4 km of coast (4 km apart)", _close isEqualTo [], format ["too close: %1", _close]] call OTQA_fnc_check;
        ["Fishing: the boat dealer sells the fishing boats", (OT_boats findIf { (_x select 0) isEqualTo "C_Boat_Civil_01_F" }) > -1 && { (!isClass (configFile >> "CfgVehicles" >> "C_Boat_Civil_04_F")) || { (OT_boats findIf { (_x select 0) isEqualTo "C_Boat_Civil_04_F" }) > -1 } },
            str ((OT_boats select { (_x select 0) in OT_fishingBoats }) apply { _x select [0, 2] })] call OTQA_fnc_check;
    }],

    ["Fishing: fish at a ground, casting the net", {
        if (OT_piers isEqualTo []) exitWith {};
        (call OTQA_fish_ground) params [["_index", -1], ["_pos", []]];
        if (_index < 0) exitWith { ["Fishing: a ground to fish", false, "no grounds"] call OTQA_fnc_check };
        private _home = getPosATL player;
        private _key = format ["fish%1", _index];
        private _boat = createVehicle ["C_Boat_Civil_01_F", _pos, [], 0, "NONE"];
        player moveInDriver _boat;
        private _isFish = { (OT_fishItems getOrDefault [typeOf _x, ""]) isNotEqualTo "" && { (_x getVariable ["OT_huntKey", ""]) isEqualTo _key } };
        private _fish = [];
        private _timeout = time + 40;
        waitUntil { sleep 2; _fish = (agents apply { agent _x }) select { alive _x && _isFish }; _fish isNotEqualTo [] || { time > _timeout } };
        ["Fishing: the ground's fish spawn (6-10)", (count _fish) > 0 && { (count _fish) <= 10 } && { (_fish findIf { (_x distance2D _pos) > 220 }) isEqualTo -1 },
            format ["%1: %2", count _fish, _fish apply { typeOf _x }]] call OTQA_fnc_check;
        if (_fish isEqualTo []) exitWith { moveOut player; deleteVehicle _boat; player setPosATL _home };

        // Right over a fish: the net catches it into the boat's cargo, it counts against the ground
        private _target = _fish select 0;
        private _item = OT_fishItems get (typeOf _target);
        private _before = [_key] call OT_fnc_huntingAvailable;
        private _tp = getPosASL _target;
        _boat setPosASL [_tp select 0, _tp select 1, 0.5];
        private _caught = [_boat, player] call OT_fnc_castNet;
        sleep 0.2; // Deleted at the end of the frame
        private _after = [_key] call OT_fnc_huntingAvailable;
        private _cargo = itemCargo _boat;
        ["Fishing: the net catches the fish into the boat's cargo", _item in _caught && { _item in _cargo } && { isNull _target }, format ["caught %1, cargo %2", _caught, _cargo]] call OTQA_fnc_check;
        ["Fishing: a catch counts against the ground", _after < _before, format ["%1 -> %2", _before, _after]] call OTQA_fnc_check;
        ["Fishing: only boats that fish can cast", ([player, objNull] call OT_fnc_castNet) isEqualTo [] && { (OT_fishingBoats getOrDefault ["C_Boat_Transport_02_F", 0]) isEqualTo 0 }, ""] call OTQA_fnc_check;

        moveOut player;
        deleteVehicle _boat;
        player setPosATL _home;
    }, 90],

    ["Fishing: selling fish and turtles", {
        private _town = player call OT_fnc_nearestTown;
        private _prices = OT_fishSellItems apply { [_x, [_town, _x, 0] call OT_fnc_getSellPrice] };
        private _p = createHashMapFromArray _prices;
        ["Fishing: general stores buy fish, rarer ones for more", ((_prices findIf { (_x select 1) < 15 }) isEqualTo -1) && { (_p get "OT_Fish_Tuna") > (_p get "OT_Fish_Mackerel") } && { (_p get "OT_Fish_Mackerel") > (_p get "OT_Fish_Salema") },
            str (_prices apply { [(_x select 0) select [8], _x select 1] })] call OTQA_fnc_check;
        private _added = player canAdd "OT_Fish_Salema";
        if (_added) then { player addItem "OT_Fish_Salema" };
        private _stock = ([player, "General"] call OT_fnc_unitStock) apply { _x select 0 };
        ["Fishing: a general store takes fish (not turtles)", (!_added || { "OT_Fish_Salema" in _stock }) && { !("OT_Turtle" in (["OT_Meat"] + OT_fishSellItems)) }, str (_stock select { _x in OT_fishSellItems })] call OTQA_fnc_check;
        if (_added) then { player removeItem "OT_Fish_Salema" };
        ["Fishing: turtles are contraband, not for general stores", "OT_Turtle" in OT_illegalItems && { !("OT_Turtle" in OT_fishSellItems) } && { !("OT_Turtle" in OT_allDrugs) }, ""] call OTQA_fnc_check;

        // Sold to a faction rep: $400 and +1 influence each
        // Room for the turtles: an empty carryall for the test (the host's gear is put back after)
        private _loadout = getUnitLoadout player;
        removeBackpack player;
        player addBackpack "B_Carryall_khk";
        clearAllItemsFromBackpack player;
        private _money = player getVariable ["money", 0];
        private _influence = player getVariable ["influence", 0];
        for "_i" from 1 to 2 do { player addItemToBackpack "OT_Turtle" };
        private _had = { _x isEqualTo "OT_Turtle" } count (items player);
        call OT_fnc_sellTurtles;
        sleep 1;
        private _left = { _x isEqualTo "OT_Turtle" } count (items player);
        ["Fishing: a faction rep pays $400 and +1 influence per turtle", _had isEqualTo 2 && { _left isEqualTo 0 } && { ((player getVariable ["money", 0]) - _money) isEqualTo 800 } && { ((player getVariable ["influence", 0]) - _influence) isEqualTo 2 },
            format ["%1 turtles, %2 left, money +%3, influence +%4", _had, _left, (player getVariable ["money", 0]) - _money, (player getVariable ["influence", 0]) - _influence]] call OTQA_fnc_check;
        player setUnitLoadout _loadout;
    }],

    ["Fishing: fisheries at coastal towns", {
        if (OT_piers isEqualTo []) exitWith {};
        private _missing = OT_fisheries select { (_x call OT_fnc_getBusinessData) isEqualTo [] || { (server getVariable [_x, []]) isEqualTo [] } || { (markerType _x) isEqualTo "" } };
        ["Fishing: 3 fisheries on the map, at coastal towns' piers, spread out", (count OT_fisheries) > 0 && { (count OT_fisheries) <= 3 } && { _missing isEqualTo [] },
            format ["%1 fisheries: %2; missing: %3", count OT_fisheries, OT_fisheries, _missing]] call OTQA_fnc_check;
        if (OT_fisheries isEqualTo []) exitWith {};

        // Its cycle: catches 2 per employee into its container, sells what's delivered
        private _name = OT_fisheries select 0;
        private _pos = (_name call OT_fnc_getBusinessData) select 0;
        private _hadContainer = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) isNotEqualTo [];
        [_name, _pos, 2] call OT_fnc_fisheryCycle; // Makes sure it has its container, catches 4
        private _container = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) param [0, objNull];
        private _fishIn = { _x in OT_fishSellItems } count (itemCargo _container);
        ["Fishing: a fishery catches 2 fish per employee into its container, on land", !isNull _container && { _fishIn >= 4 } && { !surfaceIsWater (getPosATL _container) },
            format ["%1 fish in its container, %2 m from the pier", _fishIn, round (_container distance2D _pos)]] call OTQA_fnc_check;
        _container addItemCargoGlobal ["OT_Fish_Tuna", 3];
        private _funds = [] call OT_fnc_resistanceFunds;
        private _income = [_name, _pos, 2] call OT_fnc_fisheryCycle;
        private _fundsAfter = [] call OT_fnc_resistanceFunds;
        ["Fishing: it sells delivered fish for resistance funds (up to 5 per employee)", _income > 0 && { (_fundsAfter - _funds) isEqualTo _income },
            format ["income $%1, funds %2 -> %3", _income, _funds, _fundsAfter]] call OTQA_fnc_check;
        if (!_hadContainer) then { deleteVehicle _container }; // One it already had keeps what's in it
    }]
]
