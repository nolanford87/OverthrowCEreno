/*
    Description:
    Mayor's office defence template review (the "officereview" QA suite, by hand): moves the host to
    open, flat ground on Altis's main airfield and shows the current building five times in a row,
    one copy per defence tier (1 to 5) with its template applied (OT_fnc_officeApplyTemplate), the
    guards standing still as unarmed placeholders, a label floating over each copy. Walking up to
    anything placed (within 3.5 m) gives "Feedback: Good", "Feedback: Bad" and "Feedback: Issue..."
    (a text box, ZEN's dialog when ZEN is loaded) which log, for the generator's author:
        OTFEEDBACK|template key|tier|item index in its tier|class or role|[x, y, z] model pos|good or bad or issue|note
    The host's own actions move through the buildings ("Review: next building", "Review: previous
    building", logged as OTFEEDBACK|BUILDING|key when shown), list the votes so far, and end the
    review ("Review: finished"): only then does the suite finish and the QA runner's "OT_QA ===== DONE"
    get logged. Buildings without a template yet are left out. run-qa.ps1 -Only limits it to the
    classes named.

    Returns: ARRAY - [[name, code, seconds]] (one test, so the QA runner can run it as a suite)
*/

OTQA_officeReview = createHashMap; // The review's state: keys, the building shown, its copies, the votes, the site

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

// A vote on an item: logged for the author, counted, confirmed
OTQA_officeReview_vote = {
    params ["_obj", "_vote", ["_note", ""]];
    (_obj getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0]]]]) params ["_key", "_tier", "_index", "_item"];
    _item params ["_kind", "_what", "_pos"];
    diag_log format ["OTFEEDBACK|%1|%2|%3|%4|%5|%6|%7", _key, _tier, _index, _what, _pos, _vote, _note];
    (OTQA_officeReview get "votes") pushBack [_key, _tier, _index, _what, _vote, _note];
    private _votes = OTQA_officeReview get "votes";
    hint format ["%1: %2\ntier %3, item %4 at %5\n\n%6 votes so far on %7", toUpper _vote, _what, _tier, _index, _pos, count _votes, _key];
};

// The issue text box (ZEN's dialog), a plain "issue" vote without ZEN
OTQA_officeReview_issue = {
    params ["_obj"];
    if (isClass (configFile >> "CfgPatches" >> "zen_dialog")) then {
        [
            "Office review: what's wrong with it?",
            [["EDIT", "Issue", ""]],
            { params ["_results", "_obj"]; [_obj, "issue", _results select 0] call OTQA_officeReview_vote },
            {},
            _obj
        ] call zen_dialog_fnc_create;
    } else {
        [_obj, "issue", "issue"] call OTQA_officeReview_vote;
    };
};

// The three feedback actions on something placed
OTQA_officeReview_actions = {
    params ["_obj"];
    _obj addAction ["<t color='#80ff80'>Feedback: Good</t>", { [_target, "good"] call OTQA_officeReview_vote }, nil, 1.6, true, true, "", "true", 3.5];
    _obj addAction ["<t color='#ff8080'>Feedback: Bad</t>", { [_target, "bad"] call OTQA_officeReview_vote }, nil, 1.5, true, true, "", "true", 3.5];
    _obj addAction ["Feedback: Issue...", { [_target] call OTQA_officeReview_issue }, nil, 1.4, true, true, "", "true", 3.5];
};

// Open, flat ground on the main airfield for a row of five copies this wide, no occupier men near:
// [first copy's position, the row's direction], [] when there is none
OTQA_officeReview_site = {
    params ["_width"];
    private _airport = OT_airportData apply { [(_x select 0) distance2D [14600, 16700, 0], _x select 0] };
    _airport sort true;
    private _centre = (_airport param [0, [0, [14600, 16700, 0]]]) select 1;
    private _found = [];
    for "_r" from 400 to 1500 step 100 do {
        for "_d" from 0 to 345 step 15 do {
            private _p = _centre getPos [_r, _d];
            {
                private _rowDir = _x;
                private _ok = true;
                for "_i" from 0 to 4 do {
                    private _c = _p getPos [_i * _width, _rowDir];
                    if (surfaceIsWater _c || { (_c isFlatEmpty [-1, -1, 0.2, (_width / 2) min 30, 0, false, objNull]) isEqualTo [] }) exitWith { _ok = false };
                    if (((_c nearEntities ["CAManBase", 300]) findIf { (side group _x) isEqualTo blufor && { !(_x getVariable ["OT_placeholder", false]) } }) > -1) exitWith { _ok = false };
                };
                if (_ok) exitWith { _found = [_p, _rowDir] };
            } forEach [90, 0, 45, 135];
            if (_found isNotEqualTo []) exitWith {};
        };
        if (_found isNotEqualTo []) exitWith {};
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
    hint format ["Office review: %1 (%2 of %3)\nTier 1 to 5 along the row, %4 m apart.\nWalk up to anything placed for the Feedback actions; your own actions move to the next or previous building, list the votes and finish the review.", _key, (_keys find _key) + 1, count _keys, round _width];
};

OTQA_officeReview_step = {
    params ["_by"];
    private _keys = OTQA_officeReview get "keys";
    private _i = ((_keys find (OTQA_officeReview get "key")) + _by + (count _keys)) mod (count _keys);
    if (!isNil { OTQA_officeReview get "showing" } && { !scriptDone (OTQA_officeReview get "showing") }) exitWith { hint "Office review: the next building is still being set up" };
    OTQA_officeReview set ["showing", [_keys select _i] spawn OTQA_officeReview_show];
};

OTQA_officeReview_list = {
    private _votes = OTQA_officeReview get "votes";
    private _text = format ["<t size='1.2'>Office review: %1 votes</t>", count _votes];
    {
        private _key = _x;
        private _mine = _votes select { (_x select 0) isEqualTo _key };
        if (_mine isNotEqualTo []) then {
            _text = _text + format ["<br/>%1: %2 good, %3 bad, %4 issues", _key, { (_x select 4) isEqualTo "good" } count _mine, { (_x select 4) isEqualTo "bad" } count _mine, { (_x select 4) isEqualTo "issue" } count _mine];
        };
    } forEach (OTQA_officeReview get "keys");
    hint parseText _text;
    {
        if ((_x select 4) isNotEqualTo "good") then {
            systemChat format ["%1 T%2 #%3 %4: %5 %6", _x select 0, _x select 1, _x select 2, _x select 3, _x select 4, _x select 5];
        };
    } forEach _votes;
};

[
    ["Mayor's office template review", {
        private _keys = call OTQA_officeReview_keys;
        if (_keys isEqualTo []) exitWith { ["Office review: buildings with a template to review", false, "none"] call OTQA_fnc_check };
        OTQA_officeReview set ["keys", _keys];
        OTQA_officeReview set ["votes", []];
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
        private _draw = addMissionEventHandler ["Draw3D", {
            {
                _x params ["", "", "", "", "_tier", "_pos", "_height"];
                drawIcon3D ["", [1, 1, 1, 1], [_pos select 0, _pos select 1, _height], 0, 0, 0, format ["Land_%1 - Tier %2", OTQA_officeReview get "key", _tier], 2, 0.04, "PuristaMedium", "center"];
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
        diag_log format ["OTFEEDBACK|END|%1 votes", count _votes];
        ["Office review: finished by the reviewer", true, format ["%1 buildings, %2 votes (OTFEEDBACK lines in the RPT)", count _keys, count _votes]] call OTQA_fnc_check;
    }, 86400]
]
