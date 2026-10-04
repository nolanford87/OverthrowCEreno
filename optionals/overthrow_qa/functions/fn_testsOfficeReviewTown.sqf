/*
    Description:
    The office template review's real town step (OTQA_fnc_officeReview): for every key with a template,
    a real instance found on the map inside a town (logged with the town), in a town of a population
    bracket the building is meant for where the map has one, the hospital the real Kavala one with
    its two real wings found by it; then, through the review's own code path (realStart, realStep,
    realEnd), tier 1 and then tier 3 put on the real building: every item of those tiers made as
    placeholders carrying the issue actions, the REALTOWN line, an issue logged with the town
    (OTFEEDBACK|REAL|town|key|tier|index|class|pos|issue|note) and counted with it, the tier marked
    (OTFEEDBACK|REALTIERDONE|key|town|tier), and once back at the airport the template's things gone
    while the real building and its wings still stand, unhidden and unhurt, the host back where they
    stood. Part of the current QA tests. Moves the host to the towns and back; the host can't be hurt
    while it runs.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

OTQA_officeTown = createHashMap; // The keys checked and the host's place

// Is a building inside a town as the review means it: within the town's spread, this town the nearest
OTQA_officeTown_inTown = {
    params ["_b", "_town"];
    private _centre = server getVariable [_town, [0, 0, 0]];
    (_b distance2D _centre) < ([_town] call OTQA_officeReview_townRadius) && { ((getPos _b) call OT_fnc_nearestTown) isEqualTo _town }
};

// The template's items of tiers 1 to N that OT_fnc_officeApplyTemplate makes: [objects, guards] counts
OTQA_officeTown_wanted = {
    params ["_key", "_tier"];
    private _tiers = [_key] call OT_fnc_officeTemplate;
    private _objects = 0;
    private _guards = 0;
    for "_t" from 1 to _tier do {
        {
            if ((_x select 0) isEqualTo "guard") then { _guards = _guards + 1 } else {
                if (isClass (configFile >> "CfgVehicles" >> (_x select 1))) then { _objects = _objects + 1 };
            };
        } forEach (_tiers select (_t - 1));
    };
    [_objects, _guards]
};

// One key: the real instance visited through the review's code path, tier 1 then tier 3 on it, an issue and the
// tier logged with the town, then back with the real building untouched
OTQA_officeTown_one = {
    params ["_key"];
    private _found = [_key] call OTQA_officeReview_realFind;
    if (_found isEqualTo []) exitWith {
        format ["Office review town: %1 not visited, no real instance in a town on %2", _key, worldName] call OTQA_fnc_manual;
    };
    _found params ["_b", "_town", "_parts"];
    private _pieces = [_b] + _parts;
    private _before = _pieces apply { [typeOf _x, getPosATL _x, getDir _x, damage _x] };
    private _from = getPosASL player;

    // There: tier 1 on the real building, the host outside it
    private _started = [_key] call OTQA_officeReview_realStart;
    sleep 1;
    private _real = OTQA_officeReview getOrDefault ["real", createHashMap];
    private _objects = _real getOrDefault ["objects", []];
    private _guards = _real getOrDefault ["guards", []];
    ([_key, 1] call OTQA_officeTown_wanted) params ["_wantObjects", "_wantGuards"];
    [format ["Office review town: %1 in %2: the review goes there and puts tier 1 on the real building", _key, _town], _started && { call OTQA_officeReview_realActive } && { (_real getOrDefault ["tier", 0]) isEqualTo 1 } && { (_real getOrDefault ["building", objNull]) isEqualTo _b } && { (_real getOrDefault ["town", ""]) isEqualTo _town } && { (count _objects) isEqualTo _wantObjects } && { (count _guards) isEqualTo _wantGuards } && { (_objects findIf { isNull _x }) isEqualTo -1 } && { (_guards findIf { isNull _x || { !alive _x } }) isEqualTo -1 },
        format ["started %1, tier %2, %3 of %4 objects, %5 of %6 guards", _started, _real getOrDefault ["tier", 0], count _objects, _wantObjects, count _guards, _wantGuards]] call OTQA_fnc_check;
    if (!_started) exitWith {};
    ["Office review town: the REALTOWN line names the key, town, class and position", (_real getOrDefault ["logged", ""]) isEqualTo format ["OTFEEDBACK|REALTOWN|%1|%2|%3|%4", _key, _town, typeOf _b, (getPosATL _b) apply { round (_x * 10) / 10 }], _real getOrDefault ["logged", ""]] call OTQA_fnc_check;
    private _stand = getPosATL player;
    private _r = 0;
    { private _o = _x; (boundingBoxReal _o) params ["_min", "_max"]; { _r = _r max (_b distance2D (_o modelToWorld _x)) } forEach [_min, _max, [_min select 0, _max select 1, 0], [_max select 0, _min select 1, 0]] } forEach _pieces;
    [format ["Office review town: %1 the host stands outside the real building, on land, within 60 m of it", _key], (_stand distance2D _b) >= (_r - 1) && { (_stand distance2D _b) < (_r + 60) } && { !surfaceIsWater _stand } && { isNull objectParent player },
        format ["%1 m from the building (its corners reach %2 m)", round (_stand distance2D _b), round _r]] call OTQA_fnc_check;
    [format ["Office review town: %1 the guards there are placeholders with the issue actions, the props simulated", _key], (_guards findIf { !(_x getVariable ["OT_placeholder", false]) || { (weapons _x) isNotEqualTo [] } || { !captive _x } }) isEqualTo -1 && { ((_objects + _guards) findIf { private _o = _x; ((actionIDs _o) findIf { "Issue" in ((_o actionParams _x) select 0) }) isEqualTo -1 }) isEqualTo -1 } && { (_objects findIf { !simulationEnabled _x }) isEqualTo -1 },
        format ["%1 guards, %2 objects", count _guards, count _objects]] call OTQA_fnc_check;

    // Tier 3: tier 1's things gone, tiers 1 to 3 made
    [2] call OTQA_officeReview_realStep;
    sleep 2;
    private _old = _objects + _guards;
    _objects = _real getOrDefault ["objects", []];
    _guards = _real getOrDefault ["guards", []];
    ([_key, 3] call OTQA_officeTown_wanted) params ["_want3Objects", "_want3Guards"];
    [format ["Office review town: %1 next tier twice puts tier 3 on it, tier 1's things gone", _key], (_real getOrDefault ["tier", 0]) isEqualTo 3 && { (count _objects) isEqualTo _want3Objects } && { (count _guards) isEqualTo _want3Guards } && { ((_objects + _guards) findIf { isNull _x }) isEqualTo -1 } && { (_old findIf { !isNull _x }) isEqualTo -1 },
        format ["tier %1, %2 of %3 objects, %4 of %5 guards, %6 of tier 1's things left", _real getOrDefault ["tier", 0], count _objects, _want3Objects, count _guards, _want3Guards, { !isNull _x } count _old]] call OTQA_fnc_check;

    // An issue on a thing there carries the town, and so does its vote; the tier marked reviewed there
    private _obj = _objects param [0, objNull];
    if (!isNull _obj) then {
        (_obj getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0]]]]) params ["", "_tier", "_index", "_item"];
        private _votesBefore = count (OTQA_officeReview getOrDefault ["votes", []]);
        private _line = [["the desk floats"], [_obj]] call OTQA_officeReview_issueConfirm;
        private _want = format ["OTFEEDBACK|REAL|%1|%2|%3|%4|%5|%6|issue|the desk floats", _town, _key, _tier, _index, _item select 1, _item select 2];
        private _vote = (OTQA_officeReview getOrDefault ["votes", []]) param [_votesBefore, []];
        [format ["Office review town: %1 an issue there logs the town with the thing's key, tier, index, class, position and note", _key], _line isEqualTo _want && { _vote isEqualTo [_key, _tier, _index, _item select 1, "issue", "the desk floats", _town] } && { [_obj] call OTQA_officeReview_isReported },
            format ["%1 / wanted %2; vote %3", _line, _want, _vote]] call OTQA_fnc_check;
    };
    private _offeredBefore = [3] call OTQA_officeReview_realAtTier;
    private _line = [player, player, -1, [3]] call OTQA_officeReview_realTierAction;
    private _offeredAfter = [3] call OTQA_officeReview_realAtTier;
    [format ["Office review town: %1 marking the tier there logs it with the town and takes the action away", _key], _offeredBefore && { !_offeredAfter } && { _line isEqualTo format ["OTFEEDBACK|REALTIERDONE|%1|%2|3", _key, _town] } && { [3] call OTQA_officeReview_realTierIsDone } && { !([1] call OTQA_officeReview_realTierIsDone) } && { ([3] call OTQA_officeReview_realTierDone) isEqualTo "" } && { [_key, _town, 3] in (OTQA_officeReview getOrDefault ["realDone", []]) },
        format ["offered %1 then %2, %3", _offeredBefore, _offeredAfter, _line]] call OTQA_fnc_check;

    // Back to the airport: the template's things gone, the real building and its wings as they were, the host back
    call OTQA_officeReview_realEnd;
    sleep 3;
    private _left = (_objects + _guards) select { !isNull _x };
    private _after = _pieces apply { [typeOf _x, getPosATL _x, getDir _x, damage _x] };
    [format ["Office review town: %1 back from the town, the template's things are gone", _key], !(call OTQA_officeReview_realActive) && { _left isEqualTo [] } && { isNil { _b getVariable "OT_officeObjects" } } && { isNil { _b getVariable "OT_officeGuards" } },
        format ["active %1, left: %2", call OTQA_officeReview_realActive, _left apply { typeOf _x }]] call OTQA_fnc_check;
    [format ["Office review town: %1 the real building and its %2 pieces still stand, unhidden, unhurt and unmoved", _key, count _parts], (_pieces findIf { isNull _x || { !alive _x } || { isObjectHidden _x } }) isEqualTo -1 && { _after isEqualTo _before } && { (count _pieces) isEqualTo (1 + count ([_key] call OT_fnc_officeParts)) },
        format ["before %1, after %2", _before, _after]] call OTQA_fnc_check;
    [format ["Office review town: %1 the host is back where they stood", _key], ((getPosASL player) distance _from) < 5, format ["%1 m off", round ((getPosASL player) distance _from)]] call OTQA_fnc_check;
};

private _tests = [
    ["Office review town: a real instance of every building inside a town of its bracket", {
        call OTQA_fnc_officeReview; // Defines the review's functions (and resets its state)
        private _keys = call OTQA_officeReview_keys;
        OTQA_officeReview set ["keys", _keys];
        OTQA_officeReview set ["votes", []];
        OTQA_officeReview set ["done", []];
        OTQA_officeReview set ["realDone", []];
        OTQA_officeTown set ["keys", _keys];
        OTQA_officeTown set ["home", getPosASL player];
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        player allowDamage false;
        player setCaptive true;
        private _bracket = { [server getVariable [format ["population%1", _this], 0]] call OTQA_officeReview_bracket };
        ["Office review town: the population brackets are B1 under 50, B2 50-99, B3 100-199, B4 200-399, B5 400 and more", ([0, 49, 50, 99, 100, 199, 200, 399, 400, 1200] apply { [_x] call OTQA_officeReview_bracket }) isEqualTo [1, 1, 2, 2, 3, 3, 4, 4, 5, 5], ""] call OTQA_fnc_check;
        {
            private _key = _x;
            private _found = [_key] call OTQA_officeReview_realFind;
            if (_found isEqualTo []) then {
                diag_log format ["OT_QA office review town: %1 -> none in a town on %2", _key, worldName];
                [format ["Office review town: %1 has a real instance inside a town", _key], worldName isNotEqualTo "Altis", "none found"] call OTQA_fnc_check;
                continue;
            };
            _found params ["_b", "_town", "_parts"];
            private _wanted = OTQA_officeReview_brackets getOrDefault [_key, [1, 2, 3, 4, 5]];
            private _fitting = OT_allTowns select { (_x call _bracket) in _wanted };
            // Whether any instance stands in a fitting town (the review must then have picked one of them)
            private _nearestFitting = [_key, _fitting] call OTQA_officeReview_realNearest;
            private _anyFitting = _nearestFitting isNotEqualTo [];
            diag_log format ["OT_QA office review town: %1 -> %2 (population %3, bracket %4 of %5): %6 at %7, %8 m from the centre", _key, _town, server getVariable [format ["population%1", _town], 0], _town call _bracket, _wanted, typeOf _b, (getPosATL _b) apply { round _x }, round (_b distance2D (server getVariable [_town, [0, 0, 0]]))];
            [format ["Office review town: %1 has a real instance inside a town, a standing map building of a class the key covers", _key], !isNull _b && { alive _b } && { !isObjectHidden _b } && { ([_b] call OT_fnc_officeTemplateKey) isEqualTo _key } && { [_b, _town] call OTQA_officeTown_inTown } && { _town in OT_allTowns },
                format ["%1 in %2 at %3", typeOf _b, _town, getPosATL _b]] call OTQA_fnc_check;
            [format ["Office review town: %1 stands in a town of a bracket it's meant for (%2) when the map has one", _key, _wanted], !_anyFitting || { (_town call _bracket) in _wanted }, format ["%1, population %2, bracket %3", _town, server getVariable [format ["population%1", _town], 0], _town call _bracket]] call OTQA_fnc_check;
            [format ["Office review town: %1 the real instance picked is the one nearest its town's centre among the fitting towns", _key], !_anyFitting || { (_nearestFitting select 1) isEqualTo _b }, format ["%1 m from %2's centre", round (_b distance2D (server getVariable [_town, [0, 0, 0]])), _town]] call OTQA_fnc_check;
            if (_key isEqualTo "Hospital_main_F") then {
                ["Office review town: the hospital is the real Kavala one with its two real wings found by it", _town isEqualTo "Kavala" && { (_parts apply { typeOf _x }) isEqualTo ["Land_Hospital_side1_F", "Land_Hospital_side2_F"] } && { (_parts findIf { (_x distance _b) > 80 }) isEqualTo -1 },
                    format ["%1, parts %2", _town, _parts apply { [typeOf _x, round (_x distance _b)] }]] call OTQA_fnc_check;
            } else {
                [format ["Office review town: %1 is a single-piece building with no other pieces", _key], _parts isEqualTo [], str (_parts apply { typeOf _x })] call OTQA_fnc_check;
            };
        } forEach _keys;
    }, 240]
];
{
    _tests pushBack [format ["Office review town: %1 visited, tier 1 then 3 on the real building", _x], compile format ["['%1'] call OTQA_officeTown_one", _x], 120];
} forEach ([
    "i_Stone_HouseBig_V1_F", "i_House_Big_02_V1_F", "i_House_Big_01_V1_F", "i_Shop_01_V1_F",
    "i_Shop_02_V1_F", "Research_HQ_F", "Offices_01_V1_F", "Hospital_main_F"
] select { ([_x] call OT_fnc_officeTemplate) isNotEqualTo [] });
_tests pushBack ["Office review town: the host back from the towns", {
    private _home = OTQA_officeTown getOrDefault ["home", []];
    if (call OTQA_officeReview_realActive) then { call OTQA_officeReview_realEnd };
    if (_home isNotEqualTo []) then { player setPosASL _home };
    player allowDamage true;
    player setCaptive true;
    ["Office review town: the host is back where they were", _home isEqualTo [] || { (getPosASL player) distance _home < 5 }, str _home] call OTQA_fnc_check;
    OTQA_officeReview = createHashMap;
}];
_tests
