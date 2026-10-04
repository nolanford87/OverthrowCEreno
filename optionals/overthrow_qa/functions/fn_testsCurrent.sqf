/*
    Description:
    The current QA suite: tests for the changes since the last archive. Once they pass, they move
    to the archived suite (OTQA_fnc_testsArchive).

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

private _tests = [];
{
    _tests append (call _x);
} forEach [
    OTQA_fnc_testsOfficeTemplates
];

if (_tests isEqualTo []) then {
    "No current tests yet, everything is in the archived QA tests" call OTQA_fnc_manual;
};
_tests;
