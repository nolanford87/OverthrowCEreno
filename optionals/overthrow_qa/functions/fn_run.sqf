/*
    Description:
    Runs a QA test suite and reports the results on screen and in the RPT (lines starting with "OT_QA").
    Each test runs in its own script, so one failing with a script error doesn't stop the others.
    A test is [name, code] or [name, code, seconds it may take] (120 by default).

    Parameters:
        _this # 0: STRING - Suite to run: "current" (tests for the changes since the last archive) or
            "archive" (every test that passed before); its parts "bugfixes", "followups" and "occupiers"
            also run on their own; the surveys "towns" and "offices"; "officereview" (by hand)

    Usage: ["current"] spawn OTQA_fnc_run;
*/

params [["_suite", "current", [""]]];

private _suites = createHashMapFromArray [
    ["current", ["Current QA tests", OTQA_fnc_testsCurrent]],
    ["archive", ["Archived QA tests", OTQA_fnc_testsArchive]],
    // The parts of the archive, still runnable on their own
    ["bugfixes", ["Bug fix QA tests", OTQA_fnc_testsBugFixes]],
    ["followups", ["Review and DLC QA tests", OTQA_fnc_testsFollowups]],
    ["occupiers", ["Occupier QA tests", OTQA_fnc_testsOccupiers]],
    // Surveys (not tests): data for designing features, lines in the RPT
    ["towns", ["Town survey", OTQA_fnc_dumpTowns]],
    ["offices", ["Mayor's office building probe", OTQA_fnc_probeOffices]],
    // The review by hand of the mayor's office defence templates (ends when the reviewer picks "Review: finished")
    ["officereview", ["Mayor's office template review", OTQA_fnc_officeReview]]
];
if !(_suite in _suites) exitWith {
    hint format ["Overthrow QA: unknown test suite %1", _suite];
};
(_suites get _suite) params ["_title", "_testList"];

if (!isServer || !hasInterface) exitWith {
    hint "Overthrow QA: run the tests as the host (or in singleplayer)";
};
if (!isNil "OTQA_running") exitWith {
    hint "Overthrow QA: tests are already running";
};
if (isNil "OT_NATOInitDone") exitWith {
    hint "Overthrow QA: wait until the mission has finished loading";
};
OTQA_running = true;
OT_deliveryDelay = 0; // Deliveries set off at once in the tests (8 minutes in play), a test may change it
OTQA_results = [];
OTQA_manual = [];
OTQA_currentGroup = _title;

private _build = getText (configFile >> "CfgPatches" >> "OT_Overthrow_Main" >> "versionStr");
diag_log format ["OT_QA ===== START %1 (build %2, %3) =====", _title, _build, worldName];
hint format ["Overthrow QA: running %1...", _title];

{
    _x params ["_name", "_code", ["_limit", 120]];
    OTQA_currentTest = _name;
    private _before = count OTQA_results + count OTQA_manual;
    private _handle = [] spawn _code;
    private _timeout = time + _limit;
    waitUntil { sleep 0.2; scriptDone _handle || { time > _timeout } };
    if !(scriptDone _handle) then {
        terminate _handle;
        [_name, false, format ["timed out after %1 s", _limit]] call OTQA_fnc_check;
    } else {
        if ((count OTQA_results + count OTQA_manual) isEqualTo _before) then {
            [_name, false, "no result, the test probably hit a script error (see RPT)"] call OTQA_fnc_check;
        };
    };
} forEach (call _testList);

private _pass = { _x select 1 } count OTQA_results;
private _fail = (count OTQA_results) - _pass;
diag_log format ["OT_QA ===== DONE %1: %2 passed, %3 failed, %4 manual =====", _title, _pass, _fail, count OTQA_manual];

private _text = format ["<t size='1.2'>%1</t><br/>%2 passed, %3 failed", _title, _pass, _fail];
{
    _x params ["_name", "_ok", "_detail"];
    if (!_ok) then {
        _text = _text + format ["<br/><t color='#ff6060'>FAIL: %1</t><br/><t size='0.8'>%2</t>", _name, _detail];
    };
} forEach OTQA_results;
if (OTQA_manual isNotEqualTo []) then {
    _text = _text + format ["<br/><br/>%1 manual checks listed in chat", count OTQA_manual];
};
hint parseText _text;
{
    systemChat format ["QA manual: %1", _x];
} forEach OTQA_manual;

OTQA_running = nil;
OT_deliveryDelay = nil;
