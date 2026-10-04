/*
    Description:
    Mayor's office defence template review (the "officereview" QA suite, by hand): moves the host to
    flat ground on the north-east side of Altis's main airfield and shows the current building five
    times in a row, one copy per defence tier (1 to 5) with its template applied
    (OT_fnc_officeApplyTemplate), the guards standing still as unarmed placeholders, a label floating
    over each copy. Looking at anything placed from within 6 m gives "Good: <class> (Tier N, #i)",
    "Bad: ..." and "Issue: ..." (a text box, ZEN's dialog when ZEN is loaded) which log, for the
    generator's author:
        OTFEEDBACK|template key|tier|item index in its tier|class or role|[x, y, z] model pos|good or bad or issue|note
    Standing at a copy gives "Review: mark Tier N reviewed" (OTFEEDBACK|TIERDONE|key|tier; its label
    turns green). The host's own actions move through the buildings ("Review: next building",
    "Review: previous building", logged as OTFEEDBACK|BUILDING|key when shown, with a reminder of
    the tiers not yet marked), list the votes and the tiers reviewed so far, and end the review
    ("Review: finished"): only then does the suite finish and the QA runner's "OT_QA ===== DONE" get
    logged. Buildings without a template yet are left out. run-qa.ps1 -Only limits it to the classes
    named. The vote, issue, tier and site code paths are checked by OTQA_fnc_testsOfficeTemplates.

    The real town step ("Review: see it in a real town"): the current building's real instance on the
    map, inside a town (OTQA_officeReview_realFind: the towns whose population bracket the building is
    meant for first, then any town; the instance nearest its town's centre), the host put down outside
    it and the template applied to the REAL building at tier 1 with placeholders, logged as
        OTFEEDBACK|REALTOWN|key|town|building class|pos
    The real building and, for the hospital, its real wings are never deleted or hidden: only the
    template's own things are taken off it again (OT_fnc_officeClearTemplate deletes what it put there
    and nothing else; a pass over the review's own lists catches anything it left). There, "Real town:
    next tier" / "previous tier" cycle the tiers (the tier in a hint and in the label over the building),
    "Real town: mark Tier N reviewed" logs OTFEEDBACK|REALTIERDONE|key|town|tier, "Real town: back to the
    airport" clears and returns to the row (same building) and "Real town: next building" clears, returns
    and moves on. The issue actions work the same there and log, with the town:
        OTFEEDBACK|REAL|town|key|tier|index|class or role|[x, y, z] model pos|issue|note
    "Review: finished" clears the real town too. Checked by OTQA_fnc_testsOfficeReviewTown.

    Returns: ARRAY - [[name, code, seconds]] (one test, so the QA runner can run it as a suite)
*/

OTQA_officeReview = createHashMap; // The review's state: keys, the building shown, its copies, the votes, the tiers done, the site, the real town

// The office classes with a template, as keys (the ones asked for, else all of them)
OTQA_officeReview_keys = {
    private _classes = missionNamespace getVariable ["OTQA_only", []];
    if (_classes isEqualTo []) then {
        _classes = [
            "Land_i_Stone_HouseBig_V1_F", "Land_i_House_Big_02_V1_F", "Land_i_House_Big_01_V1_F", "Land_i_Shop_01_V1_F",
            "Land_i_Shop_02_V1_F", "Land_Research_HQ_F", "Land_Offices_01_V1_F", "Land_Hospital_main_F"
        ];
    };
    private _keys = (_classes apply { [_x] call OT_fnc_officeTemplateKey }) select { _x isNotEqualTo "" };
    _keys = _keys arrayIntersect _keys;
    _keys select { ([_x] call OT_fnc_officeTemplate) isNotEqualTo [] }
};

// The template item a thing placed by the review stands for: [key, tier, index in its tier, class or role, model pos], [] for anything else
OTQA_officeReview_itemOf = {
    params [["_obj", objNull, [objNull]]];
    if (isNull _obj) exitWith { [] };
    private _item = _obj getVariable ["OT_officeItem", []];
    if ((count _item) isNotEqualTo 4) exitWith { [] };
    _item params ["_key", "_tier", "_index", "_it"];
    [_key, _tier, _index, _it select 1, _it select 2]
};

// A template item's id (key|tier|index): the same in every copy that has it (tiers add up, so an item
// of tier 2 is in the tier 2-5 copies), so an issue flagged on one copy covers them all
OTQA_officeReview_itemId = {
    params [["_obj", objNull, [objNull]]];
    private _item = [_obj] call OTQA_officeReview_itemOf;
    if (_item isEqualTo []) exitWith { "" };
    format ["%1|%2|%3", _item select 0, _item select 1, _item select 2]
};
OTQA_officeReview_isReported = {
    params [["_obj", objNull, [objNull]]];
    private _id = [_obj] call OTQA_officeReview_itemId;
    _id isNotEqualTo "" && { _id in (OTQA_officeReview getOrDefault ["reported", createHashMap]) }
};

// The town a thing placed by the review stands in: the real town's, when it's one of the things on the
// real building, "" for the airport row
OTQA_officeReview_townOf = {
    params [["_obj", objNull, [objNull]]];
    private _real = OTQA_officeReview get "real";
    if (isNil "_real" || { isNull _obj }) exitWith { "" };
    if (_obj in ((_real get "objects") + (_real get "guards"))) then { _real get "town" } else { "" }
};

// A vote on a thing: logged for the author (the line logged is returned), counted, confirmed. A thing on the
// real building logs the town with it (OTFEEDBACK|REAL|town|...), the airport row's line is unchanged
OTQA_officeReview_vote = {
    params ["_obj", "_vote", ["_note", ""]];
    private _item = [_obj] call OTQA_officeReview_itemOf;
    if (_item isEqualTo []) exitWith { hint "Office review: that isn't one of the template's things"; "" };
    _item params ["_key", "_tier", "_index", "_what", "_pos"];
    private _town = [_obj] call OTQA_officeReview_townOf;
    private _line = if (_town isEqualTo "") then {
        format ["OTFEEDBACK|%1|%2|%3|%4|%5|%6|%7", _key, _tier, _index, _what, _pos, _vote, _note]
    } else {
        format ["OTFEEDBACK|REAL|%1|%2|%3|%4|%5|%6|%7|%8", _town, _key, _tier, _index, _what, _pos, _vote, _note]
    };
    diag_log _line;
    private _votes = OTQA_officeReview getOrDefault ["votes", []];
    _votes pushBack ([_key, _tier, _index, _what, _vote, _note] + ([[], [_town]] select (_town isNotEqualTo "")));
    OTQA_officeReview set ["votes", _votes];
    if (_vote isEqualTo "issue") then {
        private _reported = OTQA_officeReview getOrDefault ["reported", createHashMap];
        _reported set [format ["%1|%2|%3", _key, _tier, _index], _note];
        OTQA_officeReview set ["reported", _reported];
    };
    hint format ["ISSUE%8: %1\ntier %2, item %3 at %4%5\n\nCounts for tiers %2-5 (every copy that has it).\n%6 issues so far on %7", _what, _tier, _index, _pos, ["", format ["\n%1", _note]] select (_note isNotEqualTo ""), { (_x select 0) isEqualTo _key } count _votes, _key, ["", format [" in %1", _town]] select (_town isNotEqualTo "")];
    _line
};

// The issue text box's confirmation (ZEN's dialog calls it with [values, arguments]), the vote with the note
OTQA_officeReview_issueConfirm = {
    params [["_results", [], [[]]], ["_args", [], [[]]]];
    _args params [["_obj", objNull, [objNull]]];
    [_obj, "issue", _results param [0, ""]] call OTQA_officeReview_vote
};

// The issue text box (ZEN's dialog), a plain "issue" vote without ZEN
OTQA_officeReview_issue = {
    params ["_obj"];
    if (isClass (configFile >> "CfgPatches" >> "zen_dialog")) then {
        [
            "Office review: what's wrong with it?",
            [["EDIT", "Issue", ""]],
            OTQA_officeReview_issueConfirm,
            {},
            [_obj]
        ] call zen_dialog_fnc_create;
        ""
    } else {
        [["issue"], [_obj]] call OTQA_officeReview_issueConfirm
    };
};

// The feedback actions' script: addAction calls it with [the thing, the player, action id, [vote]]
OTQA_officeReview_voteAction = {
    params [["_target", objNull, [objNull]], "_caller", "_actionId", ["_arguments", [], [[]]]];
    private _vote = _arguments param [0, "good"];
    if (_vote isEqualTo "issue") exitWith { [_target] call OTQA_officeReview_issue };
    [_target, _vote] call OTQA_officeReview_vote
};

// The issue action on a thing, offered only while the player looks at it (cursorObject) from within 6 m,
// the item in its name; anything not flagged counts as fine. Once an item has an issue (on any copy)
// the action says so, and another note can still be added
OTQA_officeReview_actions = {
    params ["_obj"];
    private _item = [_obj] call OTQA_officeReview_itemOf;
    if (_item isEqualTo []) exitWith {};
    _item params ["", "_tier", "_index", "_what"];
    private _label = format ["%1 (Tier %2, #%3)", _what, _tier, _index];
    private _condition = "cursorObject isEqualTo _target";
    _obj addAction [format ["<t color='#ff8080'>Issue: %1...</t>", _label], { _this call OTQA_officeReview_voteAction }, ["issue"], 1.5, true, true, "", _condition + " && { !([_target] call OTQA_officeReview_isReported) }", 6];
    _obj addAction [format ["<t color='#ffc080'>Issue reported, add a note: %1...</t>", _label], { _this call OTQA_officeReview_voteAction }, ["issue"], 1.5, true, true, "", _condition + " && { [_target] call OTQA_officeReview_isReported }", 6];
};

// Tiers marked reviewed: whether one is, marking one (logged, the line returned), the player's actions' condition
OTQA_officeReview_tierIsDone = {
    params ["_tier"];
    [OTQA_officeReview getOrDefault ["key", ""], _tier] in (OTQA_officeReview getOrDefault ["done", []])
};
OTQA_officeReview_tierDone = {
    params ["_tier"];
    private _key = OTQA_officeReview getOrDefault ["key", ""];
    if (_key isEqualTo "" || { [_tier] call OTQA_officeReview_tierIsDone }) exitWith { "" };
    private _done = OTQA_officeReview getOrDefault ["done", []];
    _done pushBack [_key, _tier];
    OTQA_officeReview set ["done", _done];
    private _line = format ["OTFEEDBACK|TIERDONE|%1|%2", _key, _tier];
    diag_log _line;
    hint format ["Tier %1 of %2 marked reviewed\n%3 of 5 tiers done on it", _tier, _key, { (_x select 0) isEqualTo _key } count _done];
    _line
};
// Whether the player stands at a tier's copy (within its half of the row's spacing) that isn't marked yet
OTQA_officeReview_atTier = {
    params ["_tier"];
    private _copies = OTQA_officeReview getOrDefault ["copies", []];
    private _i = _copies findIf { (_x select 4) isEqualTo _tier };
    if (_i < 0 || { [_tier] call OTQA_officeReview_tierIsDone }) exitWith { false };
    (player distance2D ((_copies select _i) select 5)) < ((OTQA_officeReview getOrDefault ["width", 40]) / 2)
};
OTQA_officeReview_tierAction = {
    params ["_target", "_caller", "_actionId", ["_arguments", [], [[]]]];
    [_arguments param [0, 1]] call OTQA_officeReview_tierDone
};

// Flat ground on the main airfield's north-east side for a row of five copies this wide: bearings 0 to 90
// from the airport's centre, 300 to 1500 m out, the row along the compass or a diagonal, flatness only
// (airfields are full of small objects); first with no occupier men within 300 m, then anywhere flat.
// [first copy's position, the row's direction], [] when there is none; the site is logged
OTQA_officeReview_site = {
    params ["_width"];
    private _airport = OT_airportData apply { [(_x select 0) distance2D [14600, 16700, 0], _x select 0] };
    _airport sort true;
    private _centre = (_airport param [0, [0, [14600, 16700, 0]]]) select 1;
    private _found = [];
    {
        private _strict = _x;
        for "_r" from 300 to 1500 step 100 do {
            { private _d = _x;
                private _p = _centre getPos [_r, _d];
                {
                    private _rowDir = _x;
                    private _ok = true;
                    for "_i" from 0 to 4 do {
                        private _c = _p getPos [_i * _width, _rowDir];
                        if (surfaceIsWater _c || { (_c isFlatEmpty [-1, -1, 0.2, (_width / 2) min 30, 0, false, objNull]) isEqualTo [] }) exitWith { _ok = false };
                        if (_strict && { ((_c nearEntities ["CAManBase", 300]) findIf { (side group _x) isEqualTo blufor && { !(_x getVariable ["OT_placeholder", false]) } }) > -1 }) exitWith { _ok = false };
                    };
                    if (_ok) exitWith { _found = [_p, _rowDir] };
                } forEach [45, 0, 90, 135, 30, 60];
                if (_found isNotEqualTo []) exitWith {};
            } forEach [45, 35, 55, 25, 65, 15, 75, 5, 85, 0, 90]; // North-east first, then either side of it
            if (_found isNotEqualTo []) exitWith {};
        };
        if (_found isNotEqualTo []) exitWith {};
    } forEach [true, false];
    if (_found isNotEqualTo []) then {
        diag_log format ["OT_QA office review: site %1, row towards %2, %3 m apart: %4 m at %5 degrees from the airport's centre %6", (_found select 0) apply { round _x }, _found select 1, round _width, round (_centre distance2D (_found select 0)), round (_centre getDir (_found select 0)), _centre apply { round _x }];
    };
    _found
};

// The copies shown taken away (and the terrain objects hidden for them shown again): the guards first and,
// when it can wait, the buildings a frame later (a building with men still in it may not go)
OTQA_officeReview_clear = {
    private _copies = OTQA_officeReview getOrDefault ["copies", []];
    OTQA_officeReview set ["copies", []];
    { [_x select 0] call OT_fnc_officeClearTemplate } forEach _copies;
    if (canSuspend) then { sleep 1 };
    private _buildings = [];
    {
        _x params ["_b", "_parts"];
        { deleteVehicle _x } forEach _parts;
        deleteVehicle _b;
        _buildings append (_parts + [_b]);
    } forEach _copies;
    // A building that ignores deleteVehicle (the Offices_01 block does) goes once hidden
    [_buildings] spawn {
        params ["_buildings"];
        sleep 1;
        { if (!isNull _x) then { _x hideObjectGlobal true; deleteVehicle _x } } forEach _buildings;
    };
    { _x hideObjectGlobal false } forEach (OTQA_officeReview getOrDefault ["hidden", []]);
    OTQA_officeReview set ["hidden", []];
};

// A building's five copies, tier 1 to 5 along the row, the host at the first (scheduled: it waits for
// the last copies to go)
OTQA_officeReview_show = {
    params ["_key"];
    call OTQA_officeReview_clear;
    sleep 1;
    private _tiers = [_key] call OT_fnc_officeTemplate;
    // How wide the copies stand: the template's extent (the tier 5 perimeter) plus a gap
    private _xs = [];
    private _ys = [];
    { { _xs pushBack ((_x select 2) select 0); _ys pushBack ((_x select 2) select 1) } forEach _x } forEach _tiers;
    private _width = (((selectMax _xs) - (selectMin _xs)) max ((selectMax _ys) - (selectMin _ys))) + 14;
    private _site = [_width] call OTQA_officeReview_site;
    if (_site isEqualTo []) then {
        _site = OTQA_officeReview getOrDefault ["lastSite", []];
        if (_site isEqualTo []) exitWith {};
        diag_log format ["OT_QA office review: no flat row for %1 (%2 m), using the last site", _key, _width];
    };
    if (_site isEqualTo []) exitWith { hint format ["Office review: no open flat ground on the airfield for %1", _key] };
    OTQA_officeReview set ["lastSite", _site];
    OTQA_officeReview set ["width", _width];
    _site params ["_base", "_rowDir"];
    private _hidden = OTQA_officeReview getOrDefault ["hidden", []];
    private _copies = [];
    for "_tier" from 1 to 5 do {
        private _pos = _base getPos [(_tier - 1) * _width, _rowDir];
        {
            if !(_x in _hidden) then { _x hideObjectGlobal true; _hidden pushBack _x };
        } forEach (nearestTerrainObjects [_pos, [], _width / 2 + 5, false]);
        ([_key, _pos, 0] call OTQA_fnc_officeSpawn) params ["_b", "_parts"];
        if (isNull _b) exitWith {};
        ([_b, _tier, west, _parts, true] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
        { _x enableSimulationGlobal true; [_x] call OTQA_officeReview_actions } forEach _objects; // No actions on a thing without simulation
        { [_x] call OTQA_officeReview_actions } forEach _guards;
        (boundingBoxReal _b) params ["", "_max"];
        _copies pushBack [_b, _parts, _objects, _guards, _tier, _pos, (_max select 2) + 4];
    };
    OTQA_officeReview set ["hidden", _hidden];
    OTQA_officeReview set ["copies", _copies];
    OTQA_officeReview set ["key", _key];
    diag_log format ["OTFEEDBACK|BUILDING|%1", _key];
    private _stand = (_base getPos [_width / 2 + 6, _rowDir + 180]) findEmptyPosition [0, 20, "CAManBase"];
    if (_stand isEqualTo []) then { _stand = _base getPos [_width / 2 + 6, _rowDir + 180] };
    player setPosATL [_stand select 0, _stand select 1, 0];
    private _keys = OTQA_officeReview get "keys";
    hint format ["Office review: %1 (%2 of %3)\nTier 1 to 5 along the row, %4 m apart.\nLook at anything placed for its Good / Bad / Issue actions; at each copy, mark its tier reviewed. Your own actions move to the next or previous building, see it in a real town, list the votes and finish the review.", _key, (_keys find _key) + 1, count _keys, round _width];
};

OTQA_officeReview_step = {
    params ["_by"];
    private _keys = OTQA_officeReview get "keys";
    private _key = OTQA_officeReview getOrDefault ["key", ""];
    private _i = ((_keys find _key) + _by + (count _keys)) mod (count _keys);
    if (!isNil { OTQA_officeReview get "showing" } && { !scriptDone (OTQA_officeReview get "showing") }) exitWith { hint "Office review: the next building is still being set up" };
    private _missing = [1, 2, 3, 4, 5] select { !([_x] call OTQA_officeReview_tierIsDone) };
    if (_key isNotEqualTo "" && { _missing isNotEqualTo [] }) then {
        systemChat format ["Office review: tiers not marked reviewed on %1: %2 (previous building brings it back)", _key, _missing joinString ", "];
    };
    OTQA_officeReview set ["showing", [_keys select _i] spawn OTQA_officeReview_show];
};

OTQA_officeReview_list = {
    private _votes = OTQA_officeReview getOrDefault ["votes", []];
    private _done = OTQA_officeReview getOrDefault ["done", []];
    private _realDone = OTQA_officeReview getOrDefault ["realDone", []];
    private _text = format ["<t size='1.2'>Office review: %1 issues, %2 tiers reviewed, %3 in real towns</t>", count _votes, count _done, count _realDone];
    {
        private _key = _x;
        private _mine = _votes select { (_x select 0) isEqualTo _key };
        private _tiers = (_done select { (_x select 0) isEqualTo _key }) apply { _x select 1 };
        _tiers sort true;
        private _real = (_realDone select { (_x select 0) isEqualTo _key }) apply { format ["%1 in %2", _x select 2, _x select 1] };
        if (_mine isNotEqualTo [] || { _tiers isNotEqualTo [] } || { _real isNotEqualTo [] }) then {
            _text = _text + format ["<br/>%1: %2 issues; tiers reviewed: %3%4", _key, count _mine, ["none", _tiers joinString " "] select (_tiers isNotEqualTo []), ["", format ["; real town: %1", _real joinString ", "]] select (_real isNotEqualTo [])];
        };
    } forEach (OTQA_officeReview getOrDefault ["keys", []]);
    hint parseText _text;
    {
        systemChat format ["%1 T%2 #%3 %4: %5%6", _x select 0, _x select 1, _x select 2, _x select 3, _x select 5, ["", format [" (in %1)", _x param [6, ""]]] select ((count _x) > 6)];
    } forEach _votes;
};

// ----- The real town step -----

// The population brackets each building is meant for (the mayor's office design: B1 under 50, B2 50-99,
// B3 100-199, B4 200-399, B5 400 and more; a key not listed takes any town), a population's bracket, and
// a town's spread (OT_fnc_isInTown's: 350 m from the centre, 1000 m for capitals and sprawling towns)
OTQA_officeReview_brackets = createHashMapFromArray [
    ["i_Stone_HouseBig_V1_F", [1]], ["i_House_Big_02_V1_F", [1, 2]], ["i_Shop_01_V1_F", [1, 2, 3]],
    ["i_House_Big_01_V1_F", [2, 3, 4]], ["i_Shop_02_V1_F", [3, 4]], ["Research_HQ_F", [4, 5]],
    ["Offices_01_V1_F", [5]], ["Hospital_main_F", [5]]
];
OTQA_officeReview_bracket = {
    params ["_population"];
    if (_population < 50) exitWith { 1 };
    if (_population < 100) exitWith { 2 };
    if (_population < 200) exitWith { 3 };
    if (_population < 400) exitWith { 4 };
    5
};
OTQA_officeReview_townRadius = {
    params ["_town"];
    [350, 1000] select (_town in (OT_capitals + OT_sprawling))
};

// The real instance of a building nearest its town's centre among these towns: any class the key covers (the
// variants too, OT_fnc_officeTemplateKey), inside the town's spread with this town the nearest, standing (no
// ruin) and not hidden. [distance from the centre, building, town], [] with none
OTQA_officeReview_realNearest = {
    params ["_key", "_towns"];
    private _best = [];
    {
        private _town = _x;
        private _centre = server getVariable [_town, []];
        if (_centre isNotEqualTo []) then {
            {
                if (([_x] call OT_fnc_officeTemplateKey) isEqualTo _key && { alive _x } && { !isObjectHidden _x } && { ((getPos _x) call OT_fnc_nearestTown) isEqualTo _town }) then {
                    private _d = _x distance2D _centre;
                    if (_best isEqualTo [] || { _d < (_best select 0) }) then { _best = [_d, _x, _town] };
                };
            } forEach (nearestObjects [_centre, ["House", "Building"], [_town] call OTQA_officeReview_townRadius]);
        };
    } forEach _towns;
    _best
};

// A multi-piece building's real other pieces (the hospital's wings), found by it on the map as the office probe does
OTQA_officeReview_realParts = {
    params ["_key", "_b"];
    private _classes = ([_key] call OT_fnc_officeParts) apply { _x select 0 };
    if (_classes isEqualTo []) exitWith { [] };
    private _near = nearestObjects [_b, [], 80];
    private _parts = [];
    {
        private _class = _x;
        private _part = (_near select { (typeOf _x) isEqualTo _class }) param [0, objNull];
        if (!isNull _part) then { _parts pushBack _part };
    } forEach _classes;
    _parts
};

// A real instance of a building on the map, inside a town: first in the towns whose population bracket the
// building is meant for, then in any, the instance nearest its town's centre. [building, town, its real other
// pieces], [] when none stands in a town; remembered per key (the search reads every town's buildings)
OTQA_officeReview_realFind = {
    params ["_key"];
    private _found = OTQA_officeReview getOrDefault ["realFound", createHashMap];
    if (_key in _found && { !isNull ((_found get _key) select 0) }) exitWith { _found get _key };
    private _wanted = OTQA_officeReview_brackets getOrDefault [_key, [1, 2, 3, 4, 5]];
    private _fits = OT_allTowns select { ([server getVariable [format ["population%1", _x], 0]] call OTQA_officeReview_bracket) in _wanted };
    private _best = [_key, _fits] call OTQA_officeReview_realNearest;
    if (_best isEqualTo []) then { _best = [_key, OT_allTowns - _fits] call OTQA_officeReview_realNearest };
    if (_best isEqualTo []) exitWith { [] };
    _best params ["_d", "_b", "_town"];
    private _result = [_b, _town, [_key, _b] call OTQA_officeReview_realParts];
    _found set [_key, _result];
    OTQA_officeReview set ["realFound", _found];
    diag_log format ["OT_QA office review: real %1 in %2 (population %3, bracket %4, meant for %5): %6 at %7, %8 m from the centre, %9 other pieces", _key, _town, server getVariable [format ["population%1", _town], 0], [server getVariable [format ["population%1", _town], 0]] call OTQA_officeReview_bracket, _wanted, typeOf _b, (getPosATL _b) apply { round _x }, round _d, count (_result select 2)];
    _result
};

// Somewhere for the host to stand outside a real building: beyond its pieces' corners plus 8 m, towards the
// town's centre first then round the compass, on land where a man fits
OTQA_officeReview_realStand = {
    params ["_b", "_parts", "_centre"];
    private _r = 0;
    {
        private _o = _x;
        (boundingBoxReal _o) params ["_min", "_max"];
        {
            _r = _r max (_b distance2D (_o modelToWorld _x));
        } forEach [_min, _max, [_min select 0, _max select 1, 0], [_max select 0, _min select 1, 0]];
    } forEach ([_b] + _parts);
    _r = _r + 8;
    private _dir = _b getDir _centre;
    private _stand = [];
    {
        if (_stand isEqualTo []) then {
            private _p = _b getPos [_r, _dir + _x];
            if (!surfaceIsWater _p) then {
                private _empty = _p findEmptyPosition [0, 8, "CAManBase"];
                if (_empty isNotEqualTo []) then { _stand = _empty };
            };
        };
    } forEach [0, 45, -45, 90, -90, 135, -135, 180];
    if (_stand isEqualTo []) then { _stand = _b getPos [_r, _dir] };
    [_stand select 0, _stand select 1, 0]
};

// Real-town mode: whether it's on, and whether one of its scheduled steps is still running
OTQA_officeReview_realActive = { !isNil { OTQA_officeReview get "real" } };
OTQA_officeReview_realBusy = { !isNil { OTQA_officeReview get "realBusy" } && { !scriptDone (OTQA_officeReview get "realBusy") } };

// The template's things off the real building: OT_fnc_officeClearTemplate deletes only the guards and objects it
// put there (the building's OT_officeGuards and OT_officeObjects), then a pass over the review's own lists for
// anything it left; the real building and its pieces are never touched. Scheduled
OTQA_officeReview_realStrip = {
    private _real = OTQA_officeReview get "real";
    if (isNil "_real") exitWith {};
    private _things = (_real get "objects") + (_real get "guards");
    _real set ["objects", []];
    _real set ["guards", []];
    [_real get "building"] call OT_fnc_officeClearTemplate;
    if (_things isNotEqualTo []) then {
        sleep 1;
        { if (!isNull _x) then { _x hideObjectGlobal true; deleteVehicle _x } } forEach _things;
    };
};

// The template on the real building at a tier (whatever was on it taken off first), the placeholders and props
// with the issue actions, the tier in a hint and the label over the building. Scheduled
OTQA_officeReview_realApply = {
    params ["_tier"];
    private _real = OTQA_officeReview get "real";
    if (isNil "_real") exitWith {};
    call OTQA_officeReview_realStrip;
    sleep 1;
    private _b = _real get "building";
    ([_b, _tier, west, _real get "parts", true] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
    { _x enableSimulationGlobal true; [_x] call OTQA_officeReview_actions } forEach _objects; // No actions on a thing without simulation
    { [_x] call OTQA_officeReview_actions } forEach _guards;
    _real set ["objects", _objects];
    _real set ["guards", _guards];
    _real set ["tier", _tier];
    hint format ["Real town: %1 in %2\nTier %3 on the real building (%4 things, %5 guards).\nLook at anything placed for its Issue action; your own actions change the tier, mark it reviewed, go back to the airport or on to the next building.", _real get "key", _real get "town", _tier, count _objects, count _guards];
};

// Off to a real town with the current building: its real instance found, the host outside it, tier 1 on it;
// logged as OTFEEDBACK|REALTOWN|key|town|class|pos. False when none stands in a town. Scheduled
OTQA_officeReview_realStart = {
    params ["_key"];
    if (call OTQA_officeReview_realActive || { _key isEqualTo "" }) exitWith { false };
    private _found = [_key] call OTQA_officeReview_realFind;
    if (_found isEqualTo []) exitWith {
        diag_log format ["OT_QA office review: no real %1 stands in a town on %2", _key, worldName];
        hint format ["Office review: no real Land_%1 stands in a town on %2", _key, worldName];
        false
    };
    _found params ["_b", "_town", "_parts"];
    private _centre = server getVariable [_town, getPosATL _b];
    (boundingBoxReal _b) params ["", "_max"];
    private _real = createHashMap;
    _real set ["key", _key];
    _real set ["town", _town];
    _real set ["building", _b];
    _real set ["parts", _parts];
    _real set ["tier", 0];
    _real set ["objects", []];
    _real set ["guards", []];
    _real set ["airport", getPosASL player];
    _real set ["label", [(getPosATL _b) select 0, (getPosATL _b) select 1, ((getPosATL _b) select 2) + (_max select 2) + 4]];
    private _line = format ["OTFEEDBACK|REALTOWN|%1|%2|%3|%4", _key, _town, typeOf _b, (getPosATL _b) apply { round (_x * 10) / 10 }];
    _real set ["logged", _line];
    OTQA_officeReview set ["real", _real];
    diag_log _line;
    player setPosATL ([_b, _parts, _centre] call OTQA_officeReview_realStand);
    [1] call OTQA_officeReview_realApply;
    true
};

// The next or previous tier on the real building (round from 5 to 1). Scheduled
OTQA_officeReview_realStep = {
    params ["_by"];
    private _real = OTQA_officeReview get "real";
    if (isNil "_real") exitWith {};
    [(((_real get "tier") - 1 + _by + 5) mod 5) + 1] call OTQA_officeReview_realApply;
};

// Back from the real town: the template off the real building (it stays as it was), the host where they stood
// at the airport. Scheduled
OTQA_officeReview_realEnd = {
    private _real = OTQA_officeReview get "real";
    if (isNil "_real") exitWith {};
    call OTQA_officeReview_realStrip;
    (_real get "building") setVariable ["OT_officeParts", nil];
    OTQA_officeReview deleteAt "real";
    player setPosASL (_real get "airport");
};

// Tiers marked reviewed in a real town: whether the current one is, marking it (logged, the line returned),
// the player's actions' condition (the tier shown, not yet marked)
OTQA_officeReview_realTierIsDone = {
    params ["_tier"];
    private _real = OTQA_officeReview get "real";
    if (isNil "_real") exitWith { false };
    [_real get "key", _real get "town", _tier] in (OTQA_officeReview getOrDefault ["realDone", []])
};
OTQA_officeReview_realTierDone = {
    params ["_tier"];
    private _real = OTQA_officeReview get "real";
    if (isNil "_real" || { [_tier] call OTQA_officeReview_realTierIsDone }) exitWith { "" };
    private _done = OTQA_officeReview getOrDefault ["realDone", []];
    _done pushBack [_real get "key", _real get "town", _tier];
    OTQA_officeReview set ["realDone", _done];
    private _line = format ["OTFEEDBACK|REALTIERDONE|%1|%2|%3", _real get "key", _real get "town", _tier];
    diag_log _line;
    hint format ["Tier %1 of %2 in %3 marked reviewed", _tier, _real get "key", _real get "town"];
    _line
};
OTQA_officeReview_realAtTier = {
    params ["_tier"];
    private _real = OTQA_officeReview get "real";
    !isNil "_real" && { (_real get "tier") isEqualTo _tier } && { !(call OTQA_officeReview_realBusy) } && { !([_tier] call OTQA_officeReview_realTierIsDone) }
};
OTQA_officeReview_realTierAction = {
    params ["_target", "_caller", "_actionId", ["_arguments", [], [[]]]];
    [_arguments param [0, 1]] call OTQA_officeReview_realTierDone
};

// The player's actions' conditions: at the airport row with a building shown and nothing being set up, and in a
// real town with no step running
OTQA_officeReview_atAirport = {
    !(call OTQA_officeReview_realActive) && { !(call OTQA_officeReview_realBusy) } && { (OTQA_officeReview getOrDefault ["key", ""]) isNotEqualTo "" } && { isNil { OTQA_officeReview get "showing" } || { scriptDone (OTQA_officeReview get "showing") } }
};
OTQA_officeReview_inTown = {
    (call OTQA_officeReview_realActive) && { !(call OTQA_officeReview_realBusy) }
};

[
    ["Mayor's office template review", {
        private _keys = call OTQA_officeReview_keys;
        if (_keys isEqualTo []) exitWith { ["Office review: buildings with a template to review", false, "none"] call OTQA_fnc_check };
        OTQA_officeReview set ["keys", _keys];
        OTQA_officeReview set ["votes", []];
        OTQA_officeReview set ["done", []];
        OTQA_officeReview set ["realDone", []];
        OTQA_officeReview set ["finished", false];
        OTQA_officeReview set ["home", getPosASL player];
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        player allowDamage false;
        player setCaptive true;
        private _actions = [
            player addAction ["<t color='#80c0ff'>Review: next building</t>", { [1] call OTQA_officeReview_step }, nil, 2, false, true, "", "!(call OTQA_officeReview_realActive) && { !(call OTQA_officeReview_realBusy) }"],
            player addAction ["<t color='#80c0ff'>Review: previous building</t>", { [-1] call OTQA_officeReview_step }, nil, 1.9, false, true, "", "!(call OTQA_officeReview_realActive) && { !(call OTQA_officeReview_realBusy) }"],
            player addAction ["<t color='#c0c0ff'>Review: see it in a real town</t>", { OTQA_officeReview set ["realBusy", [OTQA_officeReview getOrDefault ["key", ""]] spawn OTQA_officeReview_realStart] }, nil, 1.85, false, true, "", "call OTQA_officeReview_atAirport"],
            player addAction ["Review: list votes so far", { call OTQA_officeReview_list }, nil, 1.8, false, true, "", "true"],
            player addAction ["<t color='#ffc080'>Review: finished</t>", { OTQA_officeReview set ["finished", true] }, nil, 1.7, false, true, "", "true"],
            player addAction ["<t color='#c0c0ff'>Real town: next tier</t>", { OTQA_officeReview set ["realBusy", [1] spawn OTQA_officeReview_realStep] }, nil, 2, false, true, "", "call OTQA_officeReview_inTown"],
            player addAction ["<t color='#c0c0ff'>Real town: previous tier</t>", { OTQA_officeReview set ["realBusy", [-1] spawn OTQA_officeReview_realStep] }, nil, 1.9, false, true, "", "call OTQA_officeReview_inTown"],
            player addAction ["<t color='#80c0ff'>Real town: back to the airport</t>", { OTQA_officeReview set ["realBusy", [] spawn OTQA_officeReview_realEnd] }, nil, 1.75, false, true, "", "call OTQA_officeReview_inTown"],
            player addAction ["<t color='#80c0ff'>Real town: next building</t>", { OTQA_officeReview set ["realBusy", [] spawn { call OTQA_officeReview_realEnd; [1] call OTQA_officeReview_step }] }, nil, 1.74, false, true, "", "call OTQA_officeReview_inTown"]
        ];
        for "_t" from 1 to 5 do {
            _actions pushBack (player addAction [format ["<t color='#c0ffc0'>Review: mark Tier %1 reviewed</t>", _t], { _this call OTQA_officeReview_tierAction }, [_t], 1.65, false, true, "", format ["!(call OTQA_officeReview_realActive) && { [%1] call OTQA_officeReview_atTier }", _t]]);
            _actions pushBack (player addAction [format ["<t color='#c0ffc0'>Real town: mark Tier %1 reviewed</t>", _t], { _this call OTQA_officeReview_realTierAction }, [_t], 1.65, false, true, "", format ["[%1] call OTQA_officeReview_realAtTier", _t]]);
        };
        private _draw = addMissionEventHandler ["Draw3D", {
            {
                _x params ["", "", "", "", "_tier", "_pos", "_height"];
                private _done = [_tier] call OTQA_officeReview_tierIsDone;
                drawIcon3D ["", [[1, 1, 1, 1], [0.5, 1, 0.5, 1]] select _done, [_pos select 0, _pos select 1, _height], 0, 0, 0, format ["Land_%1 - Tier %2%3", OTQA_officeReview get "key", _tier, ["", " - reviewed"] select _done], 2, 0.04, "PuristaMedium", "center"];
            } forEach (OTQA_officeReview getOrDefault ["copies", []]);
            private _real = OTQA_officeReview get "real";
            if (!isNil "_real") then {
                private _tier = _real get "tier";
                private _done = [_tier] call OTQA_officeReview_realTierIsDone;
                drawIcon3D ["", [[1, 1, 1, 1], [0.5, 1, 0.5, 1]] select _done, _real get "label", 0, 0, 0, format ["Land_%1 - Tier %2 - %3%4", _real get "key", _tier, _real get "town", ["", " - reviewed"] select _done], 2, 0.04, "PuristaMedium", "center"];
            };
        }];
        diag_log format ["OT_QA office review: %1 buildings: %2", count _keys, _keys];
        [_keys select 0] call OTQA_officeReview_show;

        waitUntil { sleep 1; OTQA_officeReview get "finished" };

        private _showing = OTQA_officeReview getOrDefault ["showing", scriptNull];
        if (!isNull _showing) then { waitUntil { sleep 0.5; scriptDone _showing } };
        private _busy = OTQA_officeReview getOrDefault ["realBusy", scriptNull];
        if (!isNull _busy) then { waitUntil { sleep 0.5; scriptDone _busy } };
        if (call OTQA_officeReview_realActive) then { call OTQA_officeReview_realEnd };
        call OTQA_officeReview_clear;
        { player removeAction _x } forEach _actions;
        removeMissionEventHandler ["Draw3D", _draw];
        player setPosASL (OTQA_officeReview get "home");
        player allowDamage true;
        private _votes = OTQA_officeReview get "votes";
        private _done = OTQA_officeReview get "done";
        private _realDone = OTQA_officeReview get "realDone";
        diag_log format ["OTFEEDBACK|END|%1 votes, %2 tiers reviewed, %3 in real towns", count _votes, count _done, count _realDone];
        ["Office review: finished by the reviewer", true, format ["%1 buildings, %2 votes, %3 tiers reviewed, %4 in real towns (OTFEEDBACK lines in the RPT)", count _keys, count _votes, count _done, count _realDone]] call OTQA_fnc_check;
    }, 86400]
]
