/*
    Description:
    Blow (drugs slice 2): the blow precursor item (illegal, confiscated in a search), the drug lab
    sites (OT_fnc_drugLabSites: sheds, businesses, hidden markers, price), buying a lab (on drugOps),
    a lab cooking precursors into blow each cycle with its cap and calling the heat hook
    (OT_fnc_drugLabCycle; OT_fnc_drugHeat stubbed while there's none), an industrial business switched
    to make precursors (OT_fnc_drugPrecursorToggle / OT_fnc_drugPrecursorCycle), and the gangs'
    chemical convoys (OT_fnc_drugConvoyStart / OT_fnc_drugConvoyTick / OT_fnc_drugConvoyCleanup) forced
    near the host. Cycles are called directly, nothing waits for the business timer. Run it as the host
    (a general); a gang is formed in the nearest town if there's none. Part of the current QA tests.
    Labs and businesses bought or switched here are put back as they were, funds too; the convoys are
    deleted. The buy test moves the player to a lab and back.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Blow: in play, drive near a gang's camp (within 2 km) and wait for a chemical convoy (30-60 real min after the last, 15-30 after start): 'Word is <gang> are moving a chemical shipment...', a rough 'Chemical shipment' marker moving with the truck and one where it's going" call OTQA_fnc_manual;
"Blow: ambush a chemical convoy: they drive peacefully until shot at, then fight back (the police escort with them); loot the precursors from the truck; the convoy is gone once you're 500 m away" call OTQA_fnc_manual;
"Blow: look at a lab (its run-down shed by a road, a cook's benches inside, a container off its east end): the main menu offers it for sale; once bought its flask icon shows on the map like the shops'" call OTQA_fnc_manual;
"Blow: at an owned industrial business, the main menu button reads 'Make precursors' / 'Stop precursors'; the resistance screen's business info says how many it makes" call OTQA_fnc_manual;

// A gang to work with: the one with the camp nearest the player, else a new one in the nearest town
OTQA_blow_gang = {
    private _best = -1;
    private _dist = 1e9;
    {
        {
            private _g = OT_civilians getVariable [format ["gang%1", _x], []];
            if ((count _g) isEqualTo 9 && { ((_g select 4) distance2D player) < _dist }) then {
                _best = _x;
                _dist = (_g select 4) distance2D player;
            };
        } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
    } forEach OT_allTowns;
    if (_best < 0) then { _best = [(getPosATL player) call OT_fnc_nearestTown, false] call OT_fnc_formGang };
    _best
};

// How many of a class are in a container (and the containers in it)
OTQA_blow_count = {
    params ["_box", "_cls"];
    if (isNull _box) exitWith { 0 };
    private _n = 0;
    { if ((_x select 0) isEqualTo _cls) then { _n = _n + (_x select 1) } } forEach (_box call OT_fnc_unitStock);
    _n
};

// Empties the precursors and blow out of the containers round a place, returns the containers there before
OTQA_blow_clearAround = {
    params ["_pos"];
    private _boxes = nearestObjects [_pos, [OT_item_CargoContainer], 50];
    {
        private _b = _x;
        { [_b, _x, 1000] call OT_fnc_removeFromCargo } forEach ["OT_Precursors", "OT_Blow"];
    } forEach _boxes;
    _boxes
};

// The heat hook: a stand-in recording its calls when there's no real one
OTQA_blow_stubHeat = {
    OTQA_heat = [];
    if (isNil "OT_fnc_drugHeat") exitWith {
        OT_fnc_drugHeat = { OTQA_heat pushBack _this };
        true
    };
    false
};

[
    ["Blow: the precursor item exists, is illegal and priced", {
        ["Blow: OT_Precursors is an item (CfgWeapons), with a ground item (CfgVehicles OT_PrecursorsItem)", isClass (configFile >> "CfgWeapons" >> "OT_Precursors") && { isClass (configFile >> "CfgVehicles" >> "OT_PrecursorsItem") },
            format ["%1 / %2", isClass (configFile >> "CfgWeapons" >> "OT_Precursors"), isClass (configFile >> "CfgVehicles" >> "OT_PrecursorsItem")]] call OTQA_fnc_check;
        ["Blow: OT_Precursors is in OT_illegalItems (searches confiscate it), not a drug sold by dealers", ("OT_Precursors" in OT_illegalItems) && { !("OT_Precursors" in OT_allDrugs) }, str OT_illegalItems] call OTQA_fnc_check;
        ["Blow: OT_Precursors costs $150", ((cost getVariable ["OT_Precursors", []]) param [0, -1]) isEqualTo 150, str (cost getVariable ["OT_Precursors", []])] call OTQA_fnc_check;
        private _had = [player, "OT_Precursors"] call OTQA_blow_count;
        player addItemToUniform "OT_Precursors";
        private _seen = ((player call OT_fnc_getSearchStock) findIf { (_x select 0) isEqualTo "OT_Precursors" }) > -1;
        player removeItem "OT_Precursors";
        ["Blow: one carried shows in what a search looks at (OT_fnc_getSearchStock)", _seen, format ["had %1", _had]] call OTQA_fnc_check;
    }, 20],

    ["Blow: a NATO search confiscates precursors (stand still, on foot, undercover)", {
        if !(alive player && { captive player } && { isNull objectParent player }) exitWith {
            "Blow search test skipped: be undercover (not wanted) and on foot, then run again" call OTQA_fnc_manual;
        };
        // Searched with just the uniform and two precursors on: weapons would blow the cover, so they're put back after
        private _loadout = getUnitLoadout player;
        private _uniform = uniform player;
        player setUnitLoadout [[], [], [], [_uniform, []], [], [], "", "", [], ["ItemMap", "", "", "", "", ""]];
        player addItemToUniform "OT_Precursors";
        player addItemToUniform "OT_Precursors";
        private _carried = [player, "OT_Precursors"] call OTQA_blow_count;
        if (_carried isEqualTo 0) exitWith {
            player setUnitLoadout _loadout;
            ["Blow: precursors fit in the uniform for the search", false, uniform player] call OTQA_fnc_check;
        };
        private _grp = createGroup blufor;
        private _cop = _grp createUnit [OT_NATO_Unit_Police, player getPos [3, getDir player], [], 0, "CAN_COLLIDE"];
        { _cop disableAI _x } forEach ["TARGET", "AUTOTARGET", "AUTOCOMBAT", "FSM"];
        [player, _cop] call OT_fnc_NATOsearch;
        sleep 2;
        private _left = [player, "OT_Precursors"] call OTQA_blow_count;
        ["Blow: the search took the precursors", _left isEqualTo 0, format ["%1 of %2 left", _left, _carried]] call OTQA_fnc_check;
        ["Blow: the cover held (captive), precursors alone don't make you wanted", captive player, ""] call OTQA_fnc_check;
        player setUnitLoadout _loadout;
        deleteVehicle _cop;
        deleteGroup _grp;
    }, 60],

    ["Blow: lab sites, sheds, businesses and hidden markers", {
        private _sites = missionNamespace getVariable ["OT_drugLabSites", []];
        private _want = 2 + floor (worldSize / 15000);
        ["Blow: lab sites picked (2 + 1 per 15 km of map)", (count _sites) > 0 && { (count _sites) <= _want }, format ["%1 of %2: %3", count _sites, _want, _sites apply { _x select 1 }]] call OTQA_fnc_check;
        ["Blow: kept in the save (server variable drugLabSites)", (server getVariable ["drugLabSites", []]) isEqualTo _sites, ""] call OTQA_fnc_check;
        private _names = _sites apply { _x select 1 };
        ["Blow: lab names are unique", (count (_names arrayIntersect _names)) isEqualTo (count _names), str _names] call OTQA_fnc_check;
        private _owned = server getVariable ["GEURowned", []];
        {
            _x params ["_id", "_name", "_pos", "_origin", "_dir", "_roadPos"];
            private _i = OT_economicData findIf { (_x select 1) isEqualTo _name };
            private _entry = if (_i > -1) then { OT_economicData select _i } else { [] };
            [format ["Blow: %1 is a business (precursors in, blow out)", _name], _entry isEqualTo [_pos, _name, "OT_Precursors", "OT_Blow"] && { _name in OT_drugLabs }, str _entry] call OTQA_fnc_check;
            private _shed = (nearestObjects [_origin, [OT_drugLabShed], 15]) param [0, objNull];
            [format ["Blow: %1's shed stands there (%2)", _name, OT_drugLabShed], !isNull _shed && { (_shed getVariable ["OT_drugLab", ""]) isEqualTo _id }, if (isNull _shed) then { "none" } else { _shed getVariable ["OT_drugLab", ""] }] call OTQA_fnc_check;
            private _town = selectMin (OT_townData apply { round ((_x select 0) distance2D _pos) });
            private _business = selectMin ((OT_economicData select { (_x select 1) isNotEqualTo _name }) apply { round ((_x select 0) distance2D _pos) });
            [format ["Blow: %1 is out of town (900 m+) and away from businesses (500 m+), on dry land, by a road", _name], _town >= 900 && { _business >= 500 } && { !surfaceIsWater _pos } && { (_roadPos distance2D _pos) < 20 } && { (_roadPos nearRoads 15) isNotEqualTo [] },
                format ["town %1 m, business %2 m, road %3 m", _town, _business, round (_roadPos distance2D _pos)]] call OTQA_fnc_check;
            [format ["Blow: %1's map marker is a lab icon, hidden unless owned", _name], (markerType _name) isEqualTo "ot_Lab" && { (_name in _owned) || { (markerAlpha _name) isEqualTo 0 } },
                format ["%1, alpha %2, owned %3", markerType _name, markerAlpha _name, _name in _owned]] call OTQA_fnc_check;
            private _stability = 1.0 - ((server getVariable [format ["stability%1", OT_nation], 100]) / 100);
            private _price = _name call OT_fnc_getBusinessPrice;
            [format ["Blow: %1 costs $60,000 plus the instability markup", _name], (abs (_price - (60000 + (60000 * _stability)))) < 1, str _price] call OTQA_fnc_check;
            [format ["Blow: %1 is the nearest location there (Business, so the main menu sells it)", _name], ((_roadPos call OT_fnc_nearestLocation) select [0, 2]) isEqualTo [_name, "Business"], str ((_roadPos call OT_fnc_nearestLocation) select [0, 2])] call OTQA_fnc_check;
        } forEach _sites;
    }, 30],

    ["Blow: buy a lab, it goes on drugOps", {
        private _site = (missionNamespace getVariable ["OT_drugLabSites", []]) param [0, []];
        if (_site isEqualTo []) exitWith { ["Blow: a lab to buy", false, "no lab sites"] call OTQA_fnc_check };
        if !(call OT_fnc_playerIsGeneral) exitWith { "Blow buy test skipped: run it as a general" call OTQA_fnc_manual };
        _site params ["_id", "_name", "_pos", "", "", "_roadPos"];
        private _owned = server getVariable ["GEURowned", []];
        private _wasOwned = _name in _owned;
        private _ops = +(server getVariable ["drugOps", []]);
        private _funds = [] call OT_fnc_resistanceFunds;
        private _employ = server getVariable [format ["%1employ", _name], 0];
        if (_wasOwned) then { server setVariable ["GEURowned", _owned - [_name], true] };
        server setVariable ["drugOps", _ops select { (_x select 0) isNotEqualTo _id }, true];
        private _price = _name call OT_fnc_getBusinessPrice;
        server setVariable ["money", _price + 1000, true];

        // There and back
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        private _back = getPosASL player;
        private _spot = _roadPos findEmptyPosition [0, 20, "C_man_1"];
        if (_spot isEqualTo []) then { _spot = _roadPos };
        player setPosATL _spot;
        sleep 1;
        [] call OT_fnc_buyBusiness;
        sleep 2;
        player setPosASL _back;

        ["Blow: bought, the resistance owns it", _name in (server getVariable ["GEURowned", []]), str (server getVariable ["GEURowned", []])] call OTQA_fnc_check;
        ["Blow: paid the price, 2 employees", ((abs (([] call OT_fnc_resistanceFunds) - 1000)) < 1) && { (server getVariable [format ["%1employ", _name], 0]) isEqualTo 2 },
            format ["funds %1 (price %2), employees %3", [] call OT_fnc_resistanceFunds, _price, server getVariable [format ["%1employ", _name], 0]]] call OTQA_fnc_check;
        private _entry = (server getVariable ["drugOps", []]) select { (_x select 0) isEqualTo _id };
        ["Blow: on drugOps as [id, 'lab', position, nearest town, level 1]", _entry isEqualTo [[_id, "lab", _pos, _pos call OT_fnc_nearestTown, 1]], str _entry] call OTQA_fnc_check;
        _name call OT_fnc_drugLabRegister;
        ["Blow: registering again doesn't add it twice", (count ((server getVariable ["drugOps", []]) select { (_x select 0) isEqualTo _id })) isEqualTo 1, ""] call OTQA_fnc_check;
        private _otherOps = +(server getVariable ["drugOps", []]);
        ["Blow: drugOps keeps other operations (slice 1's dispensaries)", (count (_otherOps select { (_x select 0) isNotEqualTo _id })) isEqualTo (count (_ops select { (_x select 0) isNotEqualTo _id })), str _otherOps] call OTQA_fnc_check;

        // Put back
        server setVariable ["money", _funds, true];
        server setVariable [format ["%1employ", _name], _employ, true];
        private _nowOwned = (server getVariable ["GEURowned", []]) - [_name];
        if (_wasOwned) then { _nowOwned pushBack _name } else { _name setMarkerColor "ColorWhite" };
        server setVariable ["GEURowned", _nowOwned, true];
        server setVariable ["drugOps", _ops, true];
    }, 40],

    ["Blow: a lab cooks precursors into blow each cycle, capped, and reports heat", {
        private _site = (missionNamespace getVariable ["OT_drugLabSites", []]) param [0, []];
        if (_site isEqualTo []) exitWith { ["Blow: a lab to cook in", false, "no lab sites"] call OTQA_fnc_check };
        _site params ["_id", "_name", "_pos"];
        private _owned = server getVariable ["GEURowned", []];
        private _wasOwned = _name in _owned;
        if (!_wasOwned) then { server setVariable ["GEURowned", _owned + [_name], true] };
        private _ops = +(server getVariable ["drugOps", []]);
        private _boxesBefore = [_pos] call OTQA_blow_clearAround;
        private _box = _name call OT_fnc_drugLabContainer;
        ["Blow: the lab has a container within 50 m", !isNull _box && { (_box distance2D _pos) < 50 }, if (isNull _box) then { "none" } else { str round (_box distance2D _pos) }] call OTQA_fnc_check;
        _box addItemCargoGlobal ["OT_Precursors", 10];
        private _stubbed = call OTQA_blow_stubHeat;

        private _made = [_name, _pos, 3] call OT_fnc_drugLabCycle;
        ["Blow: 3 employees cook 3 precursors into 9 blow", _made isEqualTo 9 && { ([_box, "OT_Precursors"] call OTQA_blow_count) isEqualTo 7 } && { ([_box, "OT_Blow"] call OTQA_blow_count) isEqualTo 9 },
            format ["made %1, precursors %2, blow %3", _made, [_box, "OT_Precursors"] call OTQA_blow_count, [_box, "OT_Blow"] call OTQA_blow_count]] call OTQA_fnc_check;
        _made = [_name, _pos, 20] call OT_fnc_drugLabCycle;
        ["Blow: 20 employees still cook only 6 (the cap) into 18 blow", _made isEqualTo 18 && { ([_box, "OT_Precursors"] call OTQA_blow_count) isEqualTo 1 } && { ([_box, "OT_Blow"] call OTQA_blow_count) isEqualTo 27 },
            format ["made %1, precursors %2, blow %3", _made, [_box, "OT_Precursors"] call OTQA_blow_count, [_box, "OT_Blow"] call OTQA_blow_count]] call OTQA_fnc_check;
        _made = [_name, _pos, 20] call OT_fnc_drugLabCycle;
        ["Blow: the last precursor makes 3", _made isEqualTo 3 && { ([_box, "OT_Precursors"] call OTQA_blow_count) isEqualTo 0 }, format ["made %1", _made]] call OTQA_fnc_check;
        _made = [_name, _pos, 20] call OT_fnc_drugLabCycle;
        ["Blow: no precursors, no blow", _made isEqualTo 0, format ["made %1", _made]] call OTQA_fnc_check;
        if (_stubbed) then {
            ["Blow: the heat hook got [lab id, 'blow', amount] for each cycle that made some", OTQA_heat isEqualTo [[_id, "blow", 9], [_id, "blow", 18], [_id, "blow", 3]], str OTQA_heat] call OTQA_fnc_check;
            OT_fnc_drugHeat = nil;
        } else {
            "Blow: OT_fnc_drugHeat exists (slice 3), its calls aren't recorded here" call OTQA_fnc_manual;
        };
        ["Blow: the cycle put the lab on drugOps", ((server getVariable ["drugOps", []]) findIf { (_x select 0) isEqualTo _id && { (_x select 1) isEqualTo "lab" } }) > -1, str (server getVariable ["drugOps", []])] call OTQA_fnc_check;

        // Precursors in another container within 50 m are cooked too
        private _otherPos = _pos findEmptyPosition [10, 40, OT_item_CargoContainer];
        if (_otherPos isEqualTo []) then { _otherPos = _pos getPos [30, 0] };
        private _other = createVehicle [OT_item_CargoContainer, _otherPos, [], 0, "NONE"];
        clearItemCargoGlobal _other;
        _other addItemCargoGlobal ["OT_Precursors", 2];
        _made = [_name, _pos, 5] call OT_fnc_drugLabCycle;
        ["Blow: precursors in another container within 50 m are cooked, blow goes in the lab's", _made isEqualTo 6 && { ([_other, "OT_Precursors"] call OTQA_blow_count) isEqualTo 0 }, format ["made %1", _made]] call OTQA_fnc_check;
        deleteVehicle _other;

        // Put back
        if (!_wasOwned) then { server setVariable ["GEURowned", (server getVariable ["GEURowned", []]) - [_name], true] };
        server setVariable ["drugOps", _ops, true];
        [_pos] call OTQA_blow_clearAround;
        if !(_box in _boxesBefore) then { deleteVehicle _box };
    }, 30],

    ["Blow: an industrial business switched to precursors makes them each cycle", {
        private _name = (missionNamespace getVariable ["OT_precursorBusinesses", []]) param [0, ""];
        if (_name isEqualTo "") exitWith { "Blow: no industrial business on this map to make precursors" call OTQA_fnc_manual };
        private _pos = (_name call OT_fnc_getBusinessData) select 0;
        private _owned = server getVariable ["GEURowned", []];
        private _wasOwned = _name in _owned;
        private _at = +(server getVariable ["precursorsAt", []]);
        private _funds = [] call OT_fnc_resistanceFunds;
        if (_wasOwned) then { server setVariable ["GEURowned", _owned - [_name], true] };
        server setVariable ["precursorsAt", _at - [_name], true];
        ["Blow: one the resistance doesn't own can't be switched on", !([_name, true] call OT_fnc_drugPrecursorToggle) && { !(_name in (server getVariable ["precursorsAt", []])) }, ""] call OTQA_fnc_check;
        server setVariable ["GEURowned", (server getVariable ["GEURowned", []]) + [_name], true];
        ["Blow: switched on once owned", ([_name] call OT_fnc_drugPrecursorToggle) && { _name in (server getVariable ["precursorsAt", []]) }, str (server getVariable ["precursorsAt", []])] call OTQA_fnc_check;
        ["Blow: a non-industrial business can't be", !(["QA Not A Business", true] call OT_fnc_drugPrecursorToggle), ""] call OTQA_fnc_check;

        private _boxesBefore = [_pos] call OTQA_blow_clearAround;
        server setVariable ["money", 10000, true];
        private _made = [_name, _pos, 4] call OT_fnc_drugPrecursorCycle;
        private _box = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) param [0, objNull];
        ["Blow: 4 employees make 2 precursors into its container for $120", _made isEqualTo 2 && { ([_box, "OT_Precursors"] call OTQA_blow_count) isEqualTo 2 } && { ([] call OT_fnc_resistanceFunds) isEqualTo 9880 },
            format ["made %1, in the container %2, funds %3", _made, [_box, "OT_Precursors"] call OTQA_blow_count, [] call OT_fnc_resistanceFunds]] call OTQA_fnc_check;
        _made = [_name, _pos, 20] call OT_fnc_drugPrecursorCycle;
        ["Blow: 20 employees make 4 (the most)", _made isEqualTo 4 && { ([_box, "OT_Precursors"] call OTQA_blow_count) isEqualTo 6 }, format ["made %1", _made]] call OTQA_fnc_check;
        server setVariable ["money", 50, true];
        _made = [_name, _pos, 4] call OT_fnc_drugPrecursorCycle;
        ["Blow: none when the resistance can't pay for the chemicals", _made isEqualTo 0 && { ([] call OT_fnc_resistanceFunds) isEqualTo 50 }, format ["made %1, funds %2", _made, [] call OT_fnc_resistanceFunds]] call OTQA_fnc_check;
        server setVariable ["money", 10000, true];
        ["Blow: switched off", !([_name] call OT_fnc_drugPrecursorToggle) && { !(_name in (server getVariable ["precursorsAt", []])) }, ""] call OTQA_fnc_check;
        _made = [_name, _pos, 4] call OT_fnc_drugPrecursorCycle;
        ["Blow: switched off, it makes none", _made isEqualTo 0 && { ([] call OT_fnc_resistanceFunds) isEqualTo 10000 }, format ["made %1", _made]] call OTQA_fnc_check;

        // Put back
        server setVariable ["money", _funds, true];
        server setVariable ["precursorsAt", _at, true];
        private _nowOwned = (server getVariable ["GEURowned", []]) - [_name];
        if (_wasOwned) then { _nowOwned pushBack _name };
        server setVariable ["GEURowned", _nowOwned, true];
        [_pos] call OTQA_blow_clearAround;
        if (!isNull _box && { !(_box in _boxesBefore) }) then { deleteVehicle _box };
    }, 30],

    ["Blow: a forced gang chemical convoy near the host, with an escort", {
        private _gangId = call OTQA_blow_gang;
        if (_gangId < 0) exitWith { ["Blow: a gang to test with", false, "no gang and none could be formed"] call OTQA_fnc_check };
        private _start = (getPosATL player) getPos [200, getDir player];
        private _to = (getPosATL player) getPos [1500, getDir player];
        private _res = [_gangId, 1, _start, _to] call OT_fnc_drugConvoyStart;
        ["Blow: the convoy set off", _res isNotEqualTo [], str _res] call OTQA_fnc_check;
        if (_res isEqualTo []) exitWith {};
        _res params ["_id", "_truck", "_escort", "_group"];
        private _convoy = missionNamespace getVariable ["OT_drugConvoy", []];
        ["Blow: it's the one running (OT_drugConvoy)", _convoy isNotEqualTo [] && { (_convoy get "id") isEqualTo _id }, ""] call OTQA_fnc_check;
        private _load = [_truck, "OT_Precursors"] call OTQA_blow_count;
        ["Blow: a truck on the road near the start with 6-10 precursors in its cargo", !isNull _truck && { alive _truck } && { (_truck distance2D _start) < 700 } && { _load >= 6 } && { _load <= 10 } && { (_truck getVariable ["OT_drugConvoy", ""]) isEqualTo _id },
            format ["%1, %2 m from the start, %3 precursors", typeOf _truck, round (_truck distance2D _start), _load]] call OTQA_fnc_check;
        private _gangCrew = (crew _truck) select { (_x getVariable ["OT_gangid", -2]) isEqualTo _gangId };
        ["Blow: 2-3 of the gang's members in the truck, a driver among them", (count _gangCrew) >= 2 && { (count _gangCrew) <= 3 } && { (driver _truck) in _gangCrew } && { side _group isEqualTo opfor },
            format ["%1 of %2 crew, driver %3", count _gangCrew, count (crew _truck), driver _truck]] call OTQA_fnc_check;
        ["Blow: an occupier police car escorts it, its crew in the gang's group", !isNull _escort && { (typeOf _escort) isEqualTo OT_NATO_Vehicle_Police } && { (crew _escort) isNotEqualTo [] } && { ((crew _escort) findIf { (group _x) isNotEqualTo _group }) isEqualTo -1 },
            if (isNull _escort) then { "no escort" } else { format ["%1, crew %2; escort men [alive, in, captive, lifeState, m away]: %3", typeOf _escort, (crew _escort) apply { [typeOf _x, side group _x] },
                ((units _group) select { _x getVariable ["OT_drugConvoyEscort", false] }) apply { [alive _x, typeOf objectParent _x, captive _x, lifeState _x, round (_x distance _escort)] }] }] call OTQA_fnc_check;
        ["Blow: they drive along peacefully (captive, holding fire) towards where they're going", ((units _group) findIf { !captive _x }) isEqualTo -1 && { (combatMode _group) isEqualTo "BLUE" } && { ((waypoints _group) findIf { ((waypointPosition _x) distance2D _to) < 50 }) > -1 },
            format ["%1 captive of %2, %3", { captive _x } count (units _group), count (units _group), combatMode _group]] call OTQA_fnc_check;
        sleep 1.5;
        ["Blow: word reached the host: a 'Chemical shipment' marker and its destination", (markerShape format ["drugconvoy_%1", _id]) isNotEqualTo "" && { (markerShape format ["drugconvoy_%1_to", _id]) isNotEqualTo "" }, ""] call OTQA_fnc_check;

        // Lootable: the cargo isn't locked, precursors come out
        private _taken = [_truck, "OT_Precursors", 2] call OT_fnc_removeFromCargo;
        ["Blow: its cargo is lootable (not locked, precursors come out)", (locked _truck) < 2 && { _taken isEqualTo 2 } && { ([_truck, "OT_Precursors"] call OTQA_blow_count) isEqualTo (_load - 2) }, format ["locked %1, took %2", locked _truck, _taken]] call OTQA_fnc_check;

        // Cleanup: not while a player is near, at once with a distance of 0
        ["Blow: not cleared away while a player is near", !([_convoy, 100000] call OT_fnc_drugConvoyCleanup) && { !isNull _truck }, ""] call OTQA_fnc_check;
        private _people = units _group;
        ["Blow: cleared away", [_convoy, 0] call OT_fnc_drugConvoyCleanup, ""] call OTQA_fnc_check;
        sleep 3;
        ["Blow: truck, escort and people gone, nothing running, markers gone", isNull _truck && { isNull _escort } && { (_people findIf { !isNull _x }) isEqualTo -1 } && { (missionNamespace getVariable ["OT_drugConvoy", []]) isEqualTo [] } && { (markerShape format ["drugconvoy_%1", _id]) isEqualTo "" },
            format ["truck %1, escort %2, %3 people left, marker '%4'", isNull _truck, isNull _escort, { !isNull _x } count _people, markerShape format ["drugconvoy_%1", _id]]] call OTQA_fnc_check;
    }, 45],

    ["Blow: a chemical convoy without an escort, and its timing", {
        private _gangId = call OTQA_blow_gang;
        if (_gangId < 0) exitWith { ["Blow: a gang to test with", false, "no gang"] call OTQA_fnc_check };
        private _next = missionNamespace getVariable ["OT_drugConvoyNext", 0];
        private _res = [_gangId, 0, (getPosATL player) getPos [200, (getDir player) + 90], (getPosATL player) getPos [1500, (getDir player) + 90]] call OT_fnc_drugConvoyStart;
        _res params [["_id", ""], ["_truck", objNull], ["_escort", objNull], ["_group", grpNull]];
        ["Blow: without an escort, just the truck", !isNull _truck && { isNull _escort } && { ((units _group) findIf { _x getVariable ["OT_drugConvoyEscort", false] }) isEqualTo -1 }, str _res] call OTQA_fnc_check;
        OT_drugConvoyNext = 0;
        private _running = missionNamespace getVariable ["OT_drugConvoy", []];
        ["Blow: no new convoy while one is running", !([] call OT_fnc_drugConvoyTick) && { _running isNotEqualTo [] } && { (_running get "id") isEqualTo _id } && { (missionNamespace getVariable ["OT_drugConvoy", []]) isEqualTo _running }, ""] call OTQA_fnc_check;
        if (_running isNotEqualTo []) then { [_running, 0] call OT_fnc_drugConvoyCleanup };
        OT_drugConvoyNext = time + 600;
        ["Blow: none before its time", !([] call OT_fnc_drugConvoyTick) && { (missionNamespace getVariable ["OT_drugConvoy", []]) isEqualTo [] }, ""] call OTQA_fnc_check;

        // Its time come, a gang camp within 2 km of a player: one sets off from there, the next 30-60 min on
        private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
        if (((_gang select 4) distance2D player) < OT_drugConvoyRange) then {
            OT_drugConvoyNext = 0;
            private _started = [] call OT_fnc_drugConvoyTick;
            private _convoy = missionNamespace getVariable ["OT_drugConvoy", []];
            private _wait = OT_drugConvoyNext - time;
            ["Blow: its time come, one sets off from a gang camp near a player; the next in 30-60 min", _started && { _convoy isNotEqualTo [] } && { _wait >= 1795 } && { _wait <= 3605 },
                format ["started %1, next in %2 s", _started, round _wait]] call OTQA_fnc_check;
            if (_convoy isNotEqualTo []) then {
                private _gangs = [];
                { _gangs append (OT_civilians getVariable [format ["gangs%1", _x], []]) } forEach OT_allTowns;
                ["Blow: it's a gang with its camp within 2 km of a player", (_convoy get "gang") in _gangs && { (((OT_civilians getVariable [format ["gang%1", _convoy get "gang"], []]) param [4, [0, 0, 0]]) distance2D player) < OT_drugConvoyRange }, str (_convoy get "gang")] call OTQA_fnc_check;
                [_convoy, 0] call OT_fnc_drugConvoyCleanup;
            };
        } else {
            format ["Blow: the scheduled convoy wasn't tested: the nearest gang camp is %1 m away (needs < 2 km)", round ((_gang select 4) distance2D player)] call OTQA_fnc_manual;
        };
        OT_drugConvoyNext = _next;
    }, 45]
];
