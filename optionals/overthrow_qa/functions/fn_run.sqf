/*
    Description:
    Runs QA tests and reports the results on screen and in the RPT (lines starting with "OT_QA").
    Each test runs in its own script, so one failing with a script error doesn't stop the others.

    Parameters:
        _this # 0: STRING - "all", "common" or a batch number such as "7"

    Usage: ["all"] spawn OTQA_fnc_run;
*/

params [["_which", "all", [""]]];

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
OTQA_results = [];
OTQA_manual = [];

private _build = getText (configFile >> "CfgPatches" >> "OT_Overthrow_Main" >> "versionStr");
diag_log format ["OT_QA ===== START %1 (build %2, %3) =====", _which, _build, worldName];
hint format ["Overthrow QA: running %1...", _which];

private _groups = [];
if (_which in ["all", "common"]) then { _groups pushBack ["common", OTQA_fnc_testsCommon] };
if (_which in ["all", "5"]) then { _groups pushBack ["batch 5", OTQA_fnc_testsBatch5] };
if (_which in ["all", "6"]) then { _groups pushBack ["batch 6", OTQA_fnc_testsBatch6] };
if (_which in ["all", "7"]) then { _groups pushBack ["batch 7", OTQA_fnc_testsBatch7] };

{
    _x params ["_group", "_testList"];
    OTQA_currentGroup = _group;
    private _tests = call _testList;
    {
        _x params ["_name", "_code"];
        OTQA_currentTest = _name;
        private _before = count OTQA_results + count OTQA_manual;
        private _handle = [] spawn _code;
        private _timeout = time + 60;
        waitUntil { sleep 0.2; scriptDone _handle || { time > _timeout } };
        if !(scriptDone _handle) then {
            terminate _handle;
            [_name, false, "timed out after 60 s"] call OTQA_fnc_check;
        } else {
            if ((count OTQA_results + count OTQA_manual) isEqualTo _before) then {
                [_name, false, "no result, the test probably hit a script error (see RPT)"] call OTQA_fnc_check;
            };
        };
    } forEach _tests;
} forEach _groups;

private _pass = { _x select 1 } count OTQA_results;
private _fail = (count OTQA_results) - _pass;
diag_log format ["OT_QA ===== DONE %1: %2 passed, %3 failed, %4 manual =====", _which, _pass, _fail, count OTQA_manual];

private _text = format ["<t size='1.2'>Overthrow QA: %1</t><br/>%2 passed, %3 failed", _which, _pass, _fail];
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
