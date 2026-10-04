/*
    Description:
    The mayor's office layout editor (the "townlayout" QA suite, by hand). For each town in turn:
        1. Its office: the one its saved layout names (OT_fnc_officeLayout), else the first of its population
           bracket's three candidate buildings standing in the town (nearest the centre), then a lower
           bracket's; failing all, the bracket's first candidate spawned near the centre.
        2. The host is put on the street in front of the office's main door, a red 30 m circle round the office
           on the map, tier 1 on it: the saved tier 1; else, when another town's office is the same building and
           laid out already, that layout's tier 1 moved onto this office (OTQA_townLayout_baseline, the same
           place and turn relative to the building), and its later tiers add what that town's tiers added;
           else the building's generator template for tier 1 (OT_fnc_officeApplyTemplate).
        3. The host moves things and places more with Zeus (everything placed counts as the town's; guards are
           placeholders that stand still, men placed with Zeus are made to stand still too).
        4. "Layout: save <town> tier N" saves everything there as tier N (a full snapshot) and goes on to tier
           N+1: the saved tier N+1 when there is one, else what stands plus the generator's additions for N+1.
           Up to the town's highest tier: its bracket + 1, at most 5.
        5. Once the highest tier is saved: the review. "Review: show tier N" puts any saved tier up again (it can
           be changed and saved again), "Review: confirm <town>, next town" goes on to the next town and back to 1.
    Each save is logged:
        OTLAYOUT|world|town|OFFICE|class|[x,y,z] ASL|direction|spawned
        OTLAYOUT|world|town|TIER|n|item count
        OTLAYOUT|world|town|ITEM|n|guard|role|[x,y,z] ASL|direction|
        OTLAYOUT|world|town|ITEM|n|object|class|[x,y,z] ASL|[vectorDir,vectorUp]|flag (a flag pole) or nothing
    and kept for the rest of the run (OT_officeLayouts) for the review and the next tiers.
    tools/officegen/merge_layouts.py merges the saves from the RPT into the mod's layouts (after a rebuild, a
    town's saved tiers come back here). Also "Layout: make the building you look at the office", "Layout: skip to
    the next town" / "previous town" and "Layout: finished". run-qa.ps1 -Only "town,..." limits it to those
    towns; it starts at the first town with tiers left to save. Checked by OTQA_fnc_testsTownLayout.

    Returns: ARRAY - [[name, code, seconds]] (one test, so the QA runner can run it as a suite)
*/

OTQA_townLayout = createHashMap; // The editor's state: towns, the town shown, its office, tier, things, review

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

// Whether a town has tiers up to its highest left to save
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

// Where the host stands: on the street in front of the office's main door (its template's "main" doorway marker),
// the first road straight out from the door, else the road nearest the door; with no road within 40 m, outside
// the building towards the town's centre. [position ATL, the point looked at]
OTQA_townLayout_front = {
    params ["_b", "_parts", "_town"];
    private _centre = server getVariable [_town, getPosATL _b];
    private _door = [];
    {
        private _items = _x;
        private _i = _items findIf { (_x select 0) isEqualTo "doorway" && { (_x select 1) isEqualTo "main" } };
        if (_i > -1) exitWith { _door = _items select _i };
    } forEach ([[_b] call OT_fnc_officeTemplateKey] call OT_fnc_officeTemplate);
    private _from = getPosATL _b;
    private _out = _b getDir _centre;
    if (_door isNotEqualTo []) then {
        _from = _b modelToWorld (_door select 2);
        _out = (getDir _b) + (_door select 3);
    };
    private _stand = [];
    for "_d" from 2 to 40 do {
        private _p = _from getPos [_d, _out];
        if (isOnRoad _p) exitWith { _stand = _p };
    };
    if (_stand isEqualTo []) then {
        private _roads = (_from nearRoads 40) apply { [_x distance2D _from, _x] };
        _roads sort true;
        if (_roads isNotEqualTo []) then { _stand = getPosATL ((_roads select 0) select 1) };
    };
    if (_stand isEqualTo []) exitWith { [[_b, _parts, _centre] call OTQA_officeReview_realStand, _from] };
    private _empty = _stand findEmptyPosition [0, 6, "CAManBase"];
    if (_empty isNotEqualTo []) then { _stand = _empty };
    [[_stand select 0, _stand select 1, 0], _from]
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
    { { _groups pushBackUnique (group _x); deleteVehicle _x } forEach (crew _x) } forEach (_things - _men); // A static's gunner
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
    deleteMarkerLocal "OTQA_townLayout_office";
};

// The map's red 30 m circle round the office being laid out (none once the editor leaves the town)
OTQA_townLayout_marker = {
    deleteMarkerLocal "OTQA_townLayout_office";
    private _b = OTQA_townLayout getOrDefault ["building", objNull];
    if (isNull _b || { isNil { OTQA_townLayout get "town" } }) exitWith {};
    private _m = createMarkerLocal ["OTQA_townLayout_office", getPosATL _b];
    _m setMarkerShapeLocal "ELLIPSE";
    _m setMarkerSizeLocal [30, 30];
    _m setMarkerBrushLocal "Border";
    _m setMarkerColorLocal "ColorRed";
};

// Another town's layout for the same building (template key) as this office, to start from instead of the
// template: the town saved most recently in this run, else the one with the most tiers saved. [town, office, tiers], [] with none
OTQA_townLayout_baseline = {
    params ["_b", "_town"];
    private _key = [_b] call OT_fnc_officeTemplateKey;
    if (_key isEqualTo "") exitWith { [] };
    [""] call OT_fnc_officeLayout; // The saved layouts read (OT_officeLayouts)
    private _fits = {
        params ["_t"];
        private _l = OT_officeLayouts getOrDefault [_t, []];
        _t isNotEqualTo _town && { _l isNotEqualTo [] } && { ([(_l select 0) select 0] call OT_fnc_officeTemplateKey) isEqualTo _key } && { ((_l select 1) select 0) isNotEqualTo [] }
    };
    private _recent = +(OTQA_townLayout getOrDefault ["recent", []]);
    reverse _recent;
    private _i = _recent findIf { [_x] call _fits };
    private _from = if (_i > -1) then { _recent select _i } else { "" };
    if (_from isEqualTo "") then {
        private _all = ((keys OT_officeLayouts) select { [_x] call _fits }) apply { [{ _x isNotEqualTo [] } count ((OT_officeLayouts get _x) select 1), _x] };
        _all sort false;
        _from = (_all param [0, [0, ""]]) select 1;
    };
    if (_from isEqualTo "") exitWith { [] };
    private _l = OT_officeLayouts get _from;
    [_from, _l select 0, +(_l select 1)]
};

// A vector turned clockwise (as Arma's directions go) about the vertical
OTQA_townLayout_turn = {
    params ["_v", "_t"];
    [((_v select 0) * cos _t) + ((_v select 1) * sin _t), ((_v select 1) * cos _t) - ((_v select 0) * sin _t), _v select 2]
};

// Another town's layout items moved onto this office: the same place and turn relative to the building; what
// stood outside the building's footprint stands as high above this town's ground as it stood above that one's
OTQA_townLayout_moveItems = {
    params ["_items", "_fromOffice", "_b"];
    _fromOffice params ["", "_fromPos", "_fromDir"];
    private _toPos = getPosASL _b;
    private _toDir = getDir _b;
    (boundingBoxReal _b) params ["_min", "_max"];
    _items apply {
        _x params ["_kind", "_what", "_at", "_orient", ["_extra", []]];
        private _local = [_at vectorDiff _fromPos, -_fromDir] call OTQA_townLayout_turn;
        private _p = _toPos vectorAdd ([_local, _toDir] call OTQA_townLayout_turn);
        private _inside = (_local select 0) >= (_min select 0) && { (_local select 0) <= (_max select 0) } && { (_local select 1) >= (_min select 1) } && { (_local select 1) <= (_max select 1) };
        if (!_inside) then { _p set [2, (getTerrainHeightASL _p) + ((_at select 2) - (getTerrainHeightASL _at))] };
        private _turn = _toDir - _fromDir;
        [_kind, _what, _p, if (_kind isEqualTo "guard") then { _orient + _turn } else { _orient apply { [_x, _turn] call OTQA_townLayout_turn } }, _extra]
    }
};

// What a tier added to the one before it: its items not standing in the earlier tier (same kind and class or role,
// within 10 cm)
OTQA_townLayout_added = {
    params ["_now", "_before"];
    _now select {
        private _a = _x;
        (_before findIf { (_x select 0) isEqualTo (_a select 0) && { (_x select 1) isEqualTo (_a select 1) } && { ((_x select 2) distance (_a select 2)) < 0.1 } }) isEqualTo -1
    }
};

// Things made editable with the host's Zeus and given simulation, so Zeus moves them
OTQA_townLayout_editable = {
    params ["_things"];
    { if !(_x isKindOf "CAManBase") then { _x enableSimulationGlobal true } } forEach _things;
    private _curator = getAssignedCuratorLogic player;
    if (!isNull _curator) then { _curator addCuratorEditableObjects [_things, true] };
};

// The save action's text: the town and the tier shown, "again" in the review
OTQA_townLayout_actionText = {
    private _id = OTQA_townLayout getOrDefault ["saveAction", -1];
    if (_id < 0) exitWith {};
    private _review = OTQA_townLayout getOrDefault ["review", false];
    player setUserActionText [_id, format ["<t color='#c0ffc0'>Layout: save %1 tier %2%3</t>", OTQA_townLayout getOrDefault ["town", ""], OTQA_townLayout getOrDefault ["tier", 1], ["", " again"] select _review]];
};

// A saved tier put up again (the things there taken off first). Scheduled
OTQA_townLayout_putSaved = {
    params ["_tier"];
    call OTQA_townLayout_clearThings;
    sleep 1;
    ([OTQA_townLayout get "town", _tier, west, true] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];
    OTQA_townLayout set ["things", _objects + _guards];
    OTQA_townLayout set ["tier", _tier];
    [_objects + _guards] call OTQA_townLayout_editable;
    call OTQA_townLayout_actionText;
};

// The review: a saved tier shown again. Scheduled
OTQA_townLayout_reviewShow = {
    params ["_tier"];
    [_tier] call OTQA_townLayout_putSaved;
    hint format ["Review: %1 tier %2 of %3 (as saved)\nShow another tier, change this one and save it again, or confirm the town to go on.", OTQA_townLayout get "town", _tier, OTQA_townLayout get "cap"];
};
OTQA_townLayout_startReview = {
    OTQA_townLayout set ["review", true];
    call OTQA_townLayout_actionText;
    hint format ["Review: %1, all %2 tiers saved\nShow each tier to check it (your actions), change one and save it again if needed, then confirm the town to go on to the next.", OTQA_townLayout get "town", OTQA_townLayout get "cap"];
};

// A town shown: its office, the host on the street in front, tier 1 (saved or the generator's); a town with every
// tier saved goes straight to the review. Scheduled
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
    private _savedFirst = _things isNotEqualTo [];
    // Not laid out yet: another town's layout for the same building to start from, else the template
    private _baseline = [[], [_b, _town] call OTQA_townLayout_baseline] select (_layout isEqualTo []);
    if (!_savedFirst) then {
        if (_baseline isNotEqualTo []) then {
            ([[(_baseline select 2) select 0, _baseline select 1, _b] call OTQA_townLayout_moveItems, west, true, [_town, 1]] call OT_fnc_officeSpawnItems) params ["_objects", "_guards"];
            _things = _objects + _guards;
        } else {
            ([_b, 1, west, _parts, true] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
            _things = _objects + _guards;
        };
    };
    OTQA_townLayout set ["baseline", _baseline];
    OTQA_townLayout set ["town", _town];
    OTQA_townLayout set ["building", _b];
    OTQA_townLayout set ["parts", _parts];
    OTQA_townLayout set ["spawned", _spawned];
    OTQA_townLayout set ["tier", 1];
    OTQA_townLayout set ["cap", [_town] call OTQA_townLayout_cap];
    OTQA_townLayout set ["things", _things];
    OTQA_townLayout set ["review", false];
    [_things] call OTQA_townLayout_editable;
    (boundingBoxReal _b) params ["", "_max"];
    OTQA_townLayout set ["label", (getPosATL _b) vectorAdd [0, 0, (_max select 2) + 4]];
    ([_b, _parts, _town] call OTQA_townLayout_front) params ["_stand", "_look"];
    player setPosATL _stand;
    player setDir (_stand getDir _look);
    call OTQA_townLayout_actionText;
    call OTQA_townLayout_marker;
    if !([_town] call OTQA_townLayout_unfinished) exitWith { call OTQA_townLayout_startReview };
    private _towns = OTQA_townLayout getOrDefault ["towns", [_town]];
    private _start = if (_savedFirst) then { "your saved tier 1" } else {
        if (_baseline isNotEqualTo []) then { format ["%1's tier 1 (the same building)", _baseline select 0] } else { "the template's tier 1" }
    };
    hint format ["Layout: %1 (%2 of %3), population %4: tier 1 of %5\nOffice: %6%7, with %8.\nMove things and place more with Zeus, then save the tier.", _town, (_towns find _town) + 1, count _towns, server getVariable [format ["population%1", _town], 0], OTQA_townLayout get "cap", typeOf _b, ["", " (spawned, no fitting building here)"] select _spawned, _start];
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

// The tier shown saved: a snapshot of every thing there, logged (the lines returned) and kept as the town's layout
// for the rest of the run (OT_officeLayouts)
OTQA_townLayout_save = {
    private _town = OTQA_townLayout get "town";
    private _tier = OTQA_townLayout get "tier";
    private _b = OTQA_townLayout get "building";
    private _spawned = OTQA_townLayout get "spawned";
    private _items = ((call OTQA_townLayout_live) select { !(_x isKindOf "CAManBase") || { alive _x } }) apply {
        if (_x isKindOf "CAManBase") then {
            ["guard", [_x] call OTQA_townLayout_role, getPosASL _x, getDir _x, []]
        } else {
            private _static = [_x] call OT_fnc_officeStatic;
            if (_static isNotEqualTo "") exitWith { ["static", _static, getPosASL _x, [vectorDir _x, vectorUp _x], []] };
            ["object", typeOf _x, getPosASL _x, [vectorDir _x, vectorUp _x], [[], ["flag"]] select (_x isKindOf "FlagCarrier")]
        }
    };
    private _lines = [
        format ["OTLAYOUT|%1|%2|OFFICE|%3|%4|%5|%6", worldName, _town, typeOf _b, [getPosASL _b] call OTQA_townLayout_vec, (getDir _b) toFixed 2, _spawned],
        format ["OTLAYOUT|%1|%2|TIER|%3|%4", worldName, _town, _tier, count _items]
    ];
    {
        _x params ["_kind", "_what", "_at", "_orient", "_extra"];
        _lines pushBack (if (_kind isEqualTo "guard") then {
            format ["OTLAYOUT|%1|%2|ITEM|%3|guard|%4|%5|%6|", worldName, _town, _tier, _what, [_at] call OTQA_townLayout_vec, _orient toFixed 1]
        } else {
            format ["OTLAYOUT|%1|%2|ITEM|%3|%9|%4|%5|[%6,%7]|%8", worldName, _town, _tier, _what, [_at] call OTQA_townLayout_vec, [_orient select 0, 4] call OTQA_townLayout_vec, [_orient select 1, 4] call OTQA_townLayout_vec, _extra joinString ",", _kind]
        });
    } forEach _items;
    { diag_log _x } forEach _lines;
    private _layout = [_town] call OT_fnc_officeLayout;
    private _tiers = if (_layout isEqualTo []) then { [[], [], [], [], []] } else { +(_layout select 1) };
    _tiers set [_tier - 1, _items];
    OT_officeLayouts set [_town, [[typeOf _b, getPosASL _b, getDir _b, _spawned], _tiers]];
    private _recent = (OTQA_townLayout getOrDefault ["recent", []]) - [_town];
    _recent pushBack _town;
    OTQA_townLayout set ["recent", _recent];
    OTQA_townLayout set ["saves", (OTQA_townLayout getOrDefault ["saves", 0]) + 1];
    _lines
};

// After a save: on to the next tier (saved, else what stands plus the generator's additions for it), or the review
// once the highest is saved; in the review, it stays on the tier saved again. Scheduled
OTQA_townLayout_advance = {
    private _town = OTQA_townLayout get "town";
    private _tier = OTQA_townLayout get "tier";
    if (OTQA_townLayout get "review") exitWith { hint format ["Review: %1 tier %2 saved again", _town, _tier] };
    if (_tier >= (OTQA_townLayout get "cap")) exitWith { call OTQA_townLayout_startReview };
    _tier = _tier + 1;
    private _layout = [_town] call OT_fnc_officeLayout;
    if (((_layout select 1) param [_tier - 1, []]) isNotEqualTo []) exitWith {
        [_tier] call OTQA_townLayout_putSaved;
        hint format ["Layout: %1 tier %2 of %3: your saved tier %2\nChange it with Zeus, then save the tier.", _town, _tier, OTQA_townLayout get "cap"];
    };
    // The additions for the tier: what the baseline town's tier added there, moved here, else the template's
    private _baseline = OTQA_townLayout getOrDefault ["baseline", []];
    private _fromTown = "";
    private _made = [];
    if (_baseline isNotEqualTo [] && { ((_baseline select 2) select (_tier - 1)) isNotEqualTo [] }) then {
        private _added = [(_baseline select 2) select (_tier - 1), (_baseline select 2) select (_tier - 2)] call OTQA_townLayout_added;
        _made = [[_added, _baseline select 1, OTQA_townLayout get "building"] call OTQA_townLayout_moveItems, west, true, [_town, _tier]] call OT_fnc_officeSpawnItems;
        _fromTown = _baseline select 0;
    } else {
        _made = [OTQA_townLayout get "building", _tier, west, OTQA_townLayout get "parts", true, _tier] call OT_fnc_officeApplyTemplate;
    };
    _made params ["_objects", "_guards"];
    (OTQA_townLayout get "things") append (_objects + _guards);
    [_objects + _guards] call OTQA_townLayout_editable;
    OTQA_townLayout set ["tier", _tier];
    call OTQA_townLayout_actionText;
    hint format ["Layout: %1 tier %2 of %3\nYour tier %4 plus %5's %6 additions for tier %2.\nChange it with Zeus, then save the tier.", _town, _tier, OTQA_townLayout get "cap", _tier - 1, ["the template", _fromTown] select (_fromTown isNotEqualTo ""), count (_objects + _guards)];
};
OTQA_townLayout_saveAndGo = {
    private _lines = call OTQA_townLayout_save;
    call OTQA_townLayout_advance;
    _lines
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
    call OTQA_townLayout_marker;
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
            player addAction ["<t color='#c0ffc0'>Layout: save tier</t>", { [OTQA_townLayout_saveAndGo] call OTQA_townLayout_run }, nil, 2, false, true, "", _inTown],
            player addAction ["<t color='#80ff80'>Review: confirm this town, next town</t>", { [OTQA_townLayout_step, [1]] call OTQA_townLayout_run }, nil, 1.97, false, true, "", _inTown + " && { OTQA_townLayout get 'review' }"],
            player addAction ["<t color='#ffc080'>Layout: make the building you look at the office</t>", { call OTQA_townLayout_setOffice }, nil, 1.9, false, true, "", _inTown + " && { cursorObject isKindOf 'House' } && { cursorObject isNotEqualTo (OTQA_townLayout get 'building') } && { (player distance cursorObject) < 80 }"],
            player addAction ["<t color='#80c0ff'>Layout: skip to the next town</t>", { [OTQA_townLayout_step, [1]] call OTQA_townLayout_run }, nil, 1.8, false, true, "", "!(call OTQA_townLayout_busy)"],
            player addAction ["<t color='#80c0ff'>Layout: back to the previous town</t>", { [OTQA_townLayout_step, [-1]] call OTQA_townLayout_run }, nil, 1.79, false, true, "", "!(call OTQA_townLayout_busy)"],
            player addAction ["<t color='#ffc080'>Layout: finished</t>", { OTQA_townLayout set ["finished", true] }, nil, 1.7, false, true, "", "true"]
        ];
        for "_t" from 1 to 5 do {
            _actions pushBack (player addAction [format ["<t color='#c0c0ff'>Review: show tier %1</t>", _t], { [OTQA_townLayout_reviewShow, [(_this select 3) select 0]] call OTQA_townLayout_run }, [_t], 1.95 - _t / 100, false, true, "", _inTown + format [" && { OTQA_townLayout get 'review' } && { %1 <= (OTQA_townLayout get 'cap') } && { (OTQA_townLayout get 'tier') isNotEqualTo %1 }", _t]]);
        };
        OTQA_townLayout set ["saveAction", _actions select 0];
        private _draw = addMissionEventHandler ["Draw3D", {
            private _town = OTQA_townLayout get "town";
            if (isNil "_town") exitWith {};
            private _review = OTQA_townLayout get "review";
            drawIcon3D ["", [[1, 1, 1, 1], [0.5, 1, 0.5, 1]] select _review, OTQA_townLayout get "label", 0, 0, 0, format ["%1 office - tier %2 of %3%4", _town, OTQA_townLayout get "tier", OTQA_townLayout get "cap", ["", " - review"] select _review], 2, 0.04, "PuristaMedium", "center"];
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
