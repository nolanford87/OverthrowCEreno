/*
    Description:
    Checks that apply to every build: loops compiled, functions defined, settings applied.

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

[
    ["Action loops compiled", {
        // Loop bodies are strings compiled at runtime. A syntax error (e.g. a // comment) compiles to empty code
        if (isNil "action_loop") exitWith {
            ["Action loops compiled", false, "action_loop is not initialised"] call OTQA_fnc_check;
        };
        private _bad = [];
        {
            _x params ["_id", "_condition", "_code"];
            // The autosave loop is registered without code on purpose, the loop runner handles it itself
            if (_id isEqualTo "OT_autosave_loop") then { continue };
            if ((str _condition) isEqualTo "{}" || { (str _code) isEqualTo "{}" }) then { _bad pushBack _id };
        } forEach action_loop;
        ["Action loops compiled", _bad isEqualTo [], format ["%1 loops, empty after compiling: %2", count action_loop, _bad]] call OTQA_fnc_check;
    }],

    ["All OT functions defined", {
        private _missing = [];
        private _count = 0;
        {
            {
                _count = _count + 1;
                if (isNil { missionNamespace getVariable format ["OT_fnc_%1", configName _x] }) then {
                    _missing pushBack configName _x;
                };
            } forEach ("true" configClasses _x);
        } forEach ("true" configClasses (configFile >> "CfgFunctions" >> "OT"));
        ["All OT functions defined", _missing isEqualTo [], format ["%1 functions, missing: %2", _count, _missing]] call OTQA_fnc_check;
    }],

    ["Time speed applied", {
        private _day = ["ot_timemultiplierday", OT_timeMultiplierDay] call BIS_fnc_getParamValue;
        private _night = ["ot_timemultipliernight", OT_timeMultiplierNight] call BIS_fnc_getParamValue;
        ["Time speed matches lobby parameters", (OT_timeMultiplierDay isEqualTo _day) && { OT_timeMultiplierNight isEqualTo _night },
            format ["params day %1 / night %2, in use day %3 / night %4", _day, _night, OT_timeMultiplierDay, OT_timeMultiplierNight]] call OTQA_fnc_check;
        if (OT_fastTime) then {
            ["Time multiplier active", timeMultiplier in [OT_timeMultiplierDay, OT_timeMultiplierNight],
                format ["timeMultiplier is %1", timeMultiplier]] call OTQA_fnc_check;
        };
    }],

    ["Lobby parameters read", {
        private _townParam = (["ot_showtownchange", 1] call BIS_fnc_getParamValue) isEqualTo 1;
        private _enemyParam = (["ot_showenemygroup", 1] call BIS_fnc_getParamValue) isEqualTo 1;
        ["Town popup parameter applied", OT_showTownChange isEqualTo _townParam,
            format ["param %1, in use %2", _townParam, OT_showTownChange]] call OTQA_fnc_check;
        ["Enemy groups parameter applied", OT_showEnemyGroups isEqualTo _enemyParam,
            format ["param %1, in use %2", _enemyParam, OT_showEnemyGroups]] call OTQA_fnc_check;
    }],

    ["Town popup loop running", {
        ["Town popup loop running", (missionNamespace getVariable ["OT_setupPlayerUnit", objNull]) isEqualTo player,
            "started once for the current body"] call OTQA_fnc_check;
    }]
]
