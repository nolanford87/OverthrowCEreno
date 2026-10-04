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

    Returns: ARRAY - [[name, code, seconds]] (one test, so the QA runner can run it as a suite)
*/

OTQA_officeReview = createHashMap; // The review's state: keys, the building shown, its copies, the votes, the tiers done, the site

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

// A vote on a thing: logged for the author (the line logged is returned), counted, confirmed
OTQA_officeReview_vote = {
    params ["_obj", "_vote", ["_note", ""]];
    private _item = [_obj] call OTQA_officeReview_itemOf;
    if (_item isEqualTo []) exitWith { hint "Office review: that isn't one of the template's things"; "" };
    _item params ["_key", "_tier", "_index", "_what", "_pos"];
    private _line = format ["OTFEEDBACK|%1|%2|%3|%4|%5|%6|%7", _key, _tier, _index, _what, _pos, _vote, _note];
    diag_log _line;
    private _votes = OTQA_officeReview getOrDefault ["votes", []];
    _votes pushBack [_key, _tier, _index, _what, _vote, _note];
    OTQA_officeReview set ["votes", _votes];
    if (_vote isEqualTo "issue") then {
        private _reported = OTQA_officeReview getOrDefault ["reported", createHashMap];
        _reported set [format ["%1|%2|%3", _key, _tier, _index], _note];
        OTQA_officeReview set ["reported", _reported];
    };
    hint format ["ISSUE: %1\ntier %2, item %3 at %4%5\n\nCounts for tiers %2-5 (every copy that has it).\n%6 issues so far on %7", _what, _tier, _index, _pos, ["", format ["\n%1", _note]] select (_note isNotEqualTo ""), { (_x select 0) isEqualTo _key } count _votes, _key];
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
    hint format ["Office review: %1 (%2 of %3)\nTier 1 to 5 along the row, %4 m apart.\nLook at anything placed for its Good / Bad / Issue actions; at each copy, mark its tier reviewed. Your own actions move to the next or previous building, list the votes and finish the review.", _key, (_keys find _key) + 1, count _keys, round _width];
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
    private _text = format ["<t size='1.2'>Office review: %1 issues, %2 tiers reviewed</t>", count _votes, count _done];
    {
        private _key = _x;
        private _mine = _votes select { (_x select 0) isEqualTo _key };
        private _tiers = (_done select { (_x select 0) isEqualTo _key }) apply { _x select 1 };
        _tiers sort true;
        if (_mine isNotEqualTo [] || { _tiers isNotEqualTo [] }) then {
            _text = _text + format ["<br/>%1: %2 issues; tiers reviewed: %3", _key, count _mine, ["none", _tiers joinString " "] select (_tiers isNotEqualTo [])];
        };
    } forEach (OTQA_officeReview getOrDefault ["keys", []]);
    hint parseText _text;
    {
        systemChat format ["%1 T%2 #%3 %4: %5", _x select 0, _x select 1, _x select 2, _x select 3, _x select 5];
    } forEach _votes;
};

[
    ["Mayor's office template review", {
        private _keys = call OTQA_officeReview_keys;
        if (_keys isEqualTo []) exitWith { ["Office review: buildings with a template to review", false, "none"] call OTQA_fnc_check };
        OTQA_officeReview set ["keys", _keys];
        OTQA_officeReview set ["votes", []];
        OTQA_officeReview set ["done", []];
        OTQA_officeReview set ["finished", false];
        OTQA_officeReview set ["home", getPosASL player];
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        player allowDamage false;
        player setCaptive true;
        private _actions = [
            player addAction ["<t color='#80c0ff'>Review: next building</t>", { [1] call OTQA_officeReview_step }, nil, 2, false, true, "", "true"],
            player addAction ["<t color='#80c0ff'>Review: previous building</t>", { [-1] call OTQA_officeReview_step }, nil, 1.9, false, true, "", "true"],
            player addAction ["Review: list votes so far", { call OTQA_officeReview_list }, nil, 1.8, false, true, "", "true"],
            player addAction ["<t color='#ffc080'>Review: finished</t>", { OTQA_officeReview set ["finished", true] }, nil, 1.7, false, true, "", "true"]
        ];
        for "_t" from 1 to 5 do {
            _actions pushBack (player addAction [format ["<t color='#c0ffc0'>Review: mark Tier %1 reviewed</t>", _t], { _this call OTQA_officeReview_tierAction }, [_t], 1.65, false, true, "", format ["[%1] call OTQA_officeReview_atTier", _t]]);
        };
        private _draw = addMissionEventHandler ["Draw3D", {
            {
                _x params ["", "", "", "", "_tier", "_pos", "_height"];
                private _done = [_tier] call OTQA_officeReview_tierIsDone;
                drawIcon3D ["", [[1, 1, 1, 1], [0.5, 1, 0.5, 1]] select _done, [_pos select 0, _pos select 1, _height], 0, 0, 0, format ["Land_%1 - Tier %2%3", OTQA_officeReview get "key", _tier, ["", " - reviewed"] select _done], 2, 0.04, "PuristaMedium", "center"];
            } forEach (OTQA_officeReview getOrDefault ["copies", []]);
        }];
        diag_log format ["OT_QA office review: %1 buildings: %2", count _keys, _keys];
        [_keys select 0] call OTQA_officeReview_show;

        waitUntil { sleep 1; OTQA_officeReview get "finished" };

        private _showing = OTQA_officeReview getOrDefault ["showing", scriptNull];
        if (!isNull _showing) then { waitUntil { sleep 0.5; scriptDone _showing } };
        call OTQA_officeReview_clear;
        { player removeAction _x } forEach _actions;
        removeMissionEventHandler ["Draw3D", _draw];
        player setPosASL (OTQA_officeReview get "home");
        player allowDamage true;
        private _votes = OTQA_officeReview get "votes";
        private _done = OTQA_officeReview get "done";
        diag_log format ["OTFEEDBACK|END|%1 votes, %2 tiers reviewed", count _votes, count _done];
        ["Office review: finished by the reviewer", true, format ["%1 buildings, %2 votes, %3 tiers reviewed (OTFEEDBACK lines in the RPT)", count _keys, count _votes, count _done]] call OTQA_fnc_check;
    }, 86400]
]
