/*
    Description:
    The mayor's office layout editor (the "townlayout" QA suite, by hand): goes through the towns one by
    one, puts the host by the town's office with a first guess at its tier 1 defences, and lets them
    rearrange and add to it with Zeus, then save it tier by tier. Each town's office:
        - the one its saved layout names (OT_fnc_officeLayout), with that layout's tier 1;
        - else a guess (OTQA_townLayout_guess): the first of its population bracket's candidate buildings
          standing in the town, nearest the centre, then a lower bracket's; failing all, the bracket's first
          candidate spawned near the centre; with the generator's tier 1 (OT_fnc_officeApplyTemplate).
    Guards are placeholders (they stand still and don't fight); men placed with Zeus are made to stand still
    too, and everything placed with Zeus counts as the layout's. The host's actions:
        "Layout: save <town> tier N" logs the office and every thing there now (a full snapshot):
            OTLAYOUT|world|town|OFFICE|class|[x,y,z] ASL|direction|spawned
            OTLAYOUT|world|town|TIER|n|item count
            OTLAYOUT|world|town|ITEM|n|guard|role|[x,y,z] ASL|direction|
            OTLAYOUT|world|town|ITEM|n|object|class|[x,y,z] ASL|[vectorDir,vectorUp]|flag (a flag pole) or nothing
        "Layout: load tier N+1" (once tier N is saved, up to the town's cap: its bracket + 1, at most 5): that
            tier's saved layout when there is one, else what stands now plus the generator's additions for it;
        "Layout: make the building you look at the office";
        "Layout: next town" / "previous town" (the town's things taken off, the map's buildings untouched);
        "Layout: finished".
    tools/officegen/merge_layouts.py merges the saves from the RPT into the mod's layouts (a rebuild later,
    a town's saved tiers come back here). run-qa.ps1 -Only "town,..." limits it to those towns; it starts at
    the first town with tiers left to save. The save, load and editing paths are checked by
    OTQA_fnc_testsTownLayout.

    Returns: ARRAY - [[name, code, seconds]] (one test, so the QA runner can run it as a suite)
*/

OTQA_townLayout = createHashMap; // The editor's state: towns, the town shown, its office, tier, things, saves

// The office candidates on Altis by population bracket, best first (the mayor's office design), as template keys
OTQA_townLayout_candidates = createHashMapFromArray [
    [1, ["i_Stone_HouseBig_V1_F", "i_House_Big_02_V1_F", "i_Shop_01_V1_F"]],
    [2, ["i_House_Big_02_V1_F", "i_Shop_01_V1_F", "i_House_Big_01_V1_F"]],
    [3, ["i_House_Big_01_V1_F", "i_Shop_02_V1_F", "i_Shop_01_V1_F"]],
    [4, ["Research_HQ_F", "i_House_Big_01_V1_F", "i_Shop_02_V1_F"]],
    [5, ["Offices_01_V1_F", "Hospital_main_F", "Research_HQ_F"]]
];

// A town's population bracket (the review's), and the highest tier its office reaches: the bracket + 1, at most 5
OTQA_townLayout_bracket = {
    params ["_town"];
    [server getVariable [format ["population%1", _town], 0]] call OTQA_officeReview_bracket
};
OTQA_townLayout_cap = {
    params ["_town"];
    (([_town] call OTQA_townLayout_bracket) + 1) min 5
};

// Whether a town has tiers up to its cap left to save
OTQA_townLayout_unfinished = {
    params ["_town"];
    private _layout = [_town] call OT_fnc_officeLayout;
    _layout isEqualTo [] || { (((_layout select 1) select [0, [_town] call OTQA_townLayout_cap]) findIf { _x isEqualTo [] }) > -1 }
};

// A guess at a town's office: [building, its real other pieces, spawned]
OTQA_townLayout_guess = {
    params ["_town"];
    private _centre = server getVariable [_town, [0, 0, 0]];
    private _near = (nearestObjects [_centre, ["House", "Building"], [_town] call OTQA_officeReview_townRadius]) select {
        alive _x && { !isObjectHidden _x } && { ((getPos _x) call OT_fnc_nearestTown) isEqualTo _town }
    };
    private _bracket = [_town] call OTQA_townLayout_bracket;
    private _b = objNull;
    for "_br" from _bracket to 1 step -1 do {
        {
            private _key = _x;
            private _i = _near findIf { ([_x] call OT_fnc_officeTemplateKey) isEqualTo _key };
            if (_i > -1) exitWith { _b = _near select _i };
        } forEach (OTQA_townLayout_candidates get _br);
        if (!isNull _b) exitWith {};
    };
    if (!isNull _b) exitWith { [_b, [[_b] call OT_fnc_officeTemplateKey, _b] call OTQA_officeReview_realParts, false] };
    private _key = (OTQA_townLayout_candidates get _bracket) select 0;
    private _pos = _centre findEmptyPosition [5, 150, "Land_" + _key];
    if (_pos isEqualTo []) then { _pos = _centre };
    ([_key, _pos, round random 360] call OTQA_fnc_officeSpawn) params ["_spawned", "_parts"];
    [_spawned, _parts, true]
};

// The town's things standing now: what the editor put there and what was placed with Zeus (a placed man's whole
// group), never the office or the host
OTQA_townLayout_live = {
    private _all = [];
    {
        if (!isNull _x) then {
            if (_x isKindOf "CAManBase") then { { _all pushBackUnique _x } forEach (units group _x) } else { _all pushBackUnique _x };
        };
    } forEach (OTQA_townLayout getOrDefault ["things", []]);
    _all - ([OTQA_townLayout getOrDefault ["building", objNull], player] + (OTQA_townLayout getOrDefault ["parts", []]))
};

// The town's things taken off (the men first, the rest a moment later; a House object that ignores deleteVehicle
// goes once hidden). Scheduled
OTQA_townLayout_clearThings = {
    private _things = call OTQA_townLayout_live;
    OTQA_townLayout set ["things", []];
    private _men = _things select { _x isKindOf "CAManBase" };
    private _groups = [];
    { _groups pushBackUnique (group _x); deleteVehicle _x } forEach _men;
    sleep 0.5;
    { deleteVehicle _x } forEach (_things - _men);
    { if (!isNull _x && { (units _x) isEqualTo [] }) then { deleteGroup _x } } forEach _groups;
    [_things] spawn {
        params ["_things"];
        sleep 1;
        { if (!isNull _x) then { _x hideObjectGlobal true; deleteVehicle _x } } forEach _things;
    };
};

// The town left as it was: its things off, a spawned office gone, the map's buildings untouched. Scheduled
OTQA_townLayout_clear = {
    call OTQA_townLayout_clearThings;
    private _b = OTQA_townLayout getOrDefault ["building", objNull];
    if (OTQA_townLayout getOrDefault ["spawned", false]) then {
        { deleteVehicle _x } forEach ([_b] + (OTQA_townLayout getOrDefault ["parts", []]));
    } else {
        if (!isNull _b) then { { _b setVariable [_x, nil] } forEach ["OT_officeObjects", "OT_officeGuards", "OT_officeTier", "OT_officeParts"] };
    };
    OTQA_townLayout set ["building", objNull];
    OTQA_townLayout set ["parts", []];
    OTQA_townLayout set ["spawned", false];
};

// Things made editable with the host's Zeus and given simulation, so Zeus moves them
OTQA_townLayout_editable = {
    params ["_things"];
    { if !(_x isKindOf "CAManBase") then { _x enableSimulationGlobal true } } forEach _things;
    private _curator = getAssignedCuratorLogic player;
    if (!isNull _curator) then { _curator addCuratorEditableObjects [_things, true] };
};

// The save action's text: the town and the tier shown
OTQA_townLayout_actionText = {
    private _id = OTQA_townLayout getOrDefault ["saveAction", -1];
    if (_id < 0) exitWith {};
    player setUserActionText [_id, format ["<t color='#c0ffc0'>Layout: save %1 tier %2</t>", OTQA_townLayout getOrDefault ["town", ""], OTQA_townLayout getOrDefault ["tier", 1]]];
};

// A town shown: its office (the saved one or a guess) with its saved tier 1 or the generator's, the host outside.
// Scheduled
OTQA_townLayout_show = {
    params ["_town"];
    call OTQA_townLayout_clear;
    sleep 1;
    private _layout = [_town] call OT_fnc_officeLayout;
    private _b = objNull;
    private _parts = [];
    private _spawned = false;
    private _things = [];
    if (_layout isNotEqualTo []) then {
        ([_town, 1, west, true] call OT_fnc_officeApplyLayout) params ["_office", "_objects", "_guards"];
        _b = _office;
        _things = _objects + _guards;
        _spawned = (_layout select 0) param [3, false];
        _parts = [[_b] call OT_fnc_officeTemplateKey, _b] call OTQA_officeReview_realParts;
    } else {
        ([_town] call OTQA_townLayout_guess) params ["_guessed", "_guessedParts", "_guessedSpawned"];
        _b = _guessed;
        _parts = _guessedParts;
        _spawned = _guessedSpawned;
    };
    if (isNull _b) exitWith { hint format ["Layout: no office for %1", _town] };
    if (_things isEqualTo []) then {
        ([_b, 1, west, _parts, true] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
        _things = _objects + _guards;
    };
    OTQA_townLayout set ["town", _town];
    OTQA_townLayout set ["building", _b];
    OTQA_townLayout set ["parts", _parts];
    OTQA_townLayout set ["spawned", _spawned];
    OTQA_townLayout set ["tier", 1];
    OTQA_townLayout set ["cap", [_town] call OTQA_townLayout_cap];
    OTQA_townLayout set ["things", _things];
    OTQA_townLayout set ["saved", []];
    [_things] call OTQA_townLayout_editable;
    (boundingBoxReal _b) params ["", "_max"];
    OTQA_townLayout set ["label", (getPosATL _b) vectorAdd [0, 0, (_max select 2) + 4]];
    player setPosATL ([_b, _parts, server getVariable [_town, getPosATL _b]] call OTQA_officeReview_realStand);
    call OTQA_townLayout_actionText;
    private _towns = OTQA_townLayout getOrDefault ["towns", [_town]];
    hint format ["Layout: %1 (%2 of %3), population %4, tier 1 of %5\nOffice: %6%7, %8.\nMove things and place more with Zeus, then save the tier.", _town, (_towns find _town) + 1, count _towns, server getVariable [format ["population%1", _town], 0], OTQA_townLayout get "cap", typeOf _b, ["", " (spawned, no fitting building here)"] select _spawned, ["the generator's guess", "your saved tier 1"] select (_layout isNotEqualTo [] && { ((_layout select 1) select 0) isNotEqualTo [] })];
};

// A number array as text with this many decimals (format would round positions to 0.1 m)
OTQA_townLayout_vec = {
    params ["_v", ["_decimals", 3]];
    format ["[%1]", (_v apply { _x toFixed _decimals }) joinString ","]
};

// A guard's role: the template's or the layout's when it was put there by them, else from the unit's class
OTQA_townLayout_role = {
    params ["_unit"];
    private _item = _unit getVariable ["OT_officeItem", []];
    if ((count _item) isEqualTo 4 && { ((_item select 3) select 0) isEqualTo "guard" }) exitWith { (_item select 3) select 1 };
    private _class = typeOf _unit;
    if (_class isEqualTo (missionNamespace getVariable ["OT_NATO_Unit_Police", ""])) exitWith { "gendarme" };
    if (_class isEqualTo (missionNamespace getVariable ["OT_NATO_Unit_HVT", ""])) exitWith { "officer" };
    switch (toLower getText ((configOf _unit) >> "role")) do {
        case "machinegunner": { "autorifleman" };
        case "marksman";
        case "sniper": { "marksman" };
        case "missilespecialist": { "at" };
        default { "rifleman" };
    }
};

// The tier shown saved: the office and a snapshot of every thing there, logged (the lines returned)
OTQA_townLayout_save = {
    private _town = OTQA_townLayout get "town";
    private _tier = OTQA_townLayout get "tier";
    private _b = OTQA_townLayout get "building";
    private _things = (call OTQA_townLayout_live) select { !(_x isKindOf "CAManBase") || { alive _x } };
    private _lines = [
        format ["OTLAYOUT|%1|%2|OFFICE|%3|%4|%5|%6", worldName, _town, typeOf _b, [getPosASL _b] call OTQA_townLayout_vec, (getDir _b) toFixed 2, OTQA_townLayout get "spawned"],
        format ["OTLAYOUT|%1|%2|TIER|%3|%4", worldName, _town, _tier, count _things]
    ];
    {
        private _o = _x;
        _lines pushBack (if (_o isKindOf "CAManBase") then {
            format ["OTLAYOUT|%1|%2|ITEM|%3|guard|%4|%5|%6|", worldName, _town, _tier, [_o] call OTQA_townLayout_role, [getPosASL _o] call OTQA_townLayout_vec, (getDir _o) toFixed 1]
        } else {
            format ["OTLAYOUT|%1|%2|ITEM|%3|object|%4|%5|[%6,%7]|%8", worldName, _town, _tier, typeOf _o, [getPosASL _o] call OTQA_townLayout_vec, [vectorDir _o, 4] call OTQA_townLayout_vec, [vectorUp _o, 4] call OTQA_townLayout_vec, ["", "flag"] select (_o isKindOf "FlagCarrier")]
        });
    } forEach _things;
    { diag_log _x } forEach _lines;
    (OTQA_townLayout get "saved") pushBackUnique _tier;
    OTQA_townLayout set ["saves", (OTQA_townLayout getOrDefault ["saves", 0]) + 1];
    private _men = { _x isKindOf "CAManBase" } count _things;
    hint format ["Layout: %1 tier %2 saved\n%3 things, %4 guards.%5", _town, _tier, (count _things) - _men, _men, ["\nLoad the next tier when you're ready.", "\nThat's this town's last tier: next town when you're ready."] select (_tier >= (OTQA_townLayout get "cap"))];
    _lines
};

// The next tier: its saved layout when there is one, else what stands plus the generator's additions for it. Scheduled
OTQA_townLayout_next = {
    private _town = OTQA_townLayout get "town";
    private _tier = (OTQA_townLayout get "tier") + 1;
    if (_tier > (OTQA_townLayout get "cap")) exitWith { hint format ["Layout: %1's office goes up to tier %2", _town, OTQA_townLayout get "cap"] };
    private _layout = [_town] call OT_fnc_officeLayout;
    private _new = [];
    private _saved = _layout isNotEqualTo [] && { ((_layout select 1) param [_tier - 1, []]) isNotEqualTo [] };
    if (_saved) then {
        call OTQA_townLayout_clearThings;
        sleep 1;
        ([_town, _tier, west, true] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];
        _new = _objects + _guards;
        OTQA_townLayout set ["things", _new];
    } else {
        ([OTQA_townLayout get "building", _tier, west, OTQA_townLayout get "parts", true, _tier] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
        _new = _objects + _guards;
        (OTQA_townLayout get "things") append _new;
    };
    [_new] call OTQA_townLayout_editable;
    OTQA_townLayout set ["tier", _tier];
    call OTQA_townLayout_actionText;
    hint format ["Layout: %1 tier %2 of %3\n%4", _town, _tier, OTQA_townLayout get "cap", ["What stood at tier " + str (_tier - 1) + " plus the generator's " + str (count _new) + " additions for this tier.", "Your saved tier " + str _tier + "."] select _saved];
};

// The building looked at made the office (a spawned one taken away); the things stay
OTQA_townLayout_setOffice = {
    private _o = cursorObject;
    if (isNull _o || { !(_o isKindOf "House") } || { _o in (call OTQA_townLayout_live) }) exitWith { hint "Layout: look at a building to make it the office" };
    private _old = OTQA_townLayout get "building";
    if (OTQA_townLayout get "spawned") then { { deleteVehicle _x } forEach ([_old] + (OTQA_townLayout get "parts")) };
    OTQA_townLayout set ["building", _o];
    OTQA_townLayout set ["parts", [[_o] call OT_fnc_officeTemplateKey, _o] call OTQA_officeReview_realParts];
    OTQA_townLayout set ["spawned", false];
    (boundingBoxReal _o) params ["", "_max"];
    OTQA_townLayout set ["label", (getPosATL _o) vectorAdd [0, 0, (_max select 2) + 4]];
    hint format ["Layout: %1's office is now %2\nSave the tier to keep it.", OTQA_townLayout get "town", typeOf _o];
};

// The next or previous town. Scheduled
OTQA_townLayout_step = {
    params ["_by"];
    private _towns = OTQA_townLayout get "towns";
    private _i = ((OTQA_townLayout getOrDefault ["index", 0]) + _by + (count _towns)) mod (count _towns);
    OTQA_townLayout set ["index", _i];
    [_towns select _i] call OTQA_townLayout_show;
};

OTQA_townLayout_busy = { !isNil { OTQA_townLayout get "busy" } && { !scriptDone (OTQA_townLayout get "busy") } };
OTQA_townLayout_run = {
    params ["_code", ["_args", []]];
    if (call OTQA_townLayout_busy) exitWith { hint "Layout: wait, still setting up" };
    OTQA_townLayout set ["busy", _args spawn _code];
};

[
    ["Mayor's office town layouts", {
        call OTQA_fnc_officeReview; // Its helpers: the brackets, a town's spread, a building's real pieces, where to stand
        private _towns = missionNamespace getVariable ["OTQA_only", []];
        if (_towns isEqualTo []) then { _towns = +OT_allTowns };
        _towns = _towns select { _x in OT_allTowns };
        if (_towns isEqualTo []) exitWith { ["Layout: towns to lay out", false, "none"] call OTQA_fnc_check };
        OTQA_townLayout set ["towns", _towns];
        OTQA_townLayout set ["index", 0 max (_towns findIf { [_x] call OTQA_townLayout_unfinished })];
        OTQA_townLayout set ["saves", 0];
        OTQA_townLayout set ["finished", false];
        OTQA_townLayout set ["home", getPosASL player];
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        player allowDamage false;
        player setCaptive true;

        // Zeus (OTQA_fnc_autoZeus) and what's placed with it counted as the town's, placed men standing still
        private _until = time + 60;
        waitUntil { sleep 1; !isNull (getAssignedCuratorLogic player) || { time > _until } };
        private _curator = getAssignedCuratorLogic player;
        private _placed = -1;
        if (!isNull _curator) then {
            _placed = _curator addEventHandler ["CuratorObjectPlaced", {
                params ["", "_entity"];
                if (isNil { OTQA_townLayout get "town" }) exitWith {};
                (OTQA_townLayout get "things") pushBack _entity;
                if (_entity isKindOf "CAManBase") then {
                    { _x disableAI "PATH"; _x setUnitPos "UP"; doStop _x } forEach (units group _entity);
                };
            }];
        };

        private _inTown = "!(call OTQA_townLayout_busy) && { !isNil { OTQA_townLayout get 'town' } }";
        private _actions = [
            player addAction ["<t color='#c0ffc0'>Layout: save tier</t>", { call OTQA_townLayout_save }, nil, 2, false, true, "", _inTown],
            player addAction ["<t color='#c0c0ff'>Layout: load next tier</t>", { [OTQA_townLayout_next] call OTQA_townLayout_run }, nil, 1.95, false, true, "", _inTown + " && { (OTQA_townLayout get 'tier') in (OTQA_townLayout get 'saved') } && { (OTQA_townLayout get 'tier') < (OTQA_townLayout get 'cap') }"],
            player addAction ["<t color='#ffc080'>Layout: make the building you look at the office</t>", { call OTQA_townLayout_setOffice }, nil, 1.9, false, true, "", _inTown + " && { cursorObject isKindOf 'House' } && { cursorObject isNotEqualTo (OTQA_townLayout get 'building') } && { (player distance cursorObject) < 80 }"],
            player addAction ["<t color='#80c0ff'>Layout: next town</t>", { [OTQA_townLayout_step, [1]] call OTQA_townLayout_run }, nil, 1.8, false, true, "", "!(call OTQA_townLayout_busy)"],
            player addAction ["<t color='#80c0ff'>Layout: previous town</t>", { [OTQA_townLayout_step, [-1]] call OTQA_townLayout_run }, nil, 1.79, false, true, "", "!(call OTQA_townLayout_busy)"],
            player addAction ["<t color='#ffc080'>Layout: finished</t>", { OTQA_townLayout set ["finished", true] }, nil, 1.7, false, true, "", "true"]
        ];
        OTQA_townLayout set ["saveAction", _actions select 0];
        private _draw = addMissionEventHandler ["Draw3D", {
            private _town = OTQA_townLayout get "town";
            if (isNil "_town") exitWith {};
            private _tier = OTQA_townLayout get "tier";
            private _saved = _tier in (OTQA_townLayout get "saved");
            drawIcon3D ["", [[1, 1, 1, 1], [0.5, 1, 0.5, 1]] select _saved, OTQA_townLayout get "label", 0, 0, 0, format ["%1 office - tier %2 of %3%4", _town, _tier, OTQA_townLayout get "cap", ["", " - saved"] select _saved], 2, 0.04, "PuristaMedium", "center"];
        }];
        diag_log format ["OT_QA town layouts: %1 towns, starting at %2", count _towns, _towns select (OTQA_townLayout get "index")];
        [_towns select (OTQA_townLayout get "index")] call OTQA_townLayout_show;

        waitUntil { sleep 1; OTQA_townLayout get "finished" };

        private _busy = OTQA_townLayout getOrDefault ["busy", scriptNull];
        if (!isNull _busy) then { waitUntil { sleep 0.5; scriptDone _busy } };
        call OTQA_townLayout_clear;
        OTQA_townLayout deleteAt "town";
        { player removeAction _x } forEach _actions;
        removeMissionEventHandler ["Draw3D", _draw];
        if (_placed > -1) then { _curator removeEventHandler ["CuratorObjectPlaced", _placed] };
        player setPosASL (OTQA_townLayout get "home");
        player allowDamage true;
        diag_log format ["OTLAYOUT|END|%1 saves", OTQA_townLayout get "saves"];
        ["Layout: finished by the author", true, format ["%1 tiers saved (OTLAYOUT lines in the RPT, merge with tools/officegen/merge_layouts.py)", OTQA_townLayout get "saves"]] call OTQA_fnc_check;
    }, 86400]
]
