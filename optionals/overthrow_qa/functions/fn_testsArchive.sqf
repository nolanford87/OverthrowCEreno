/*
    Description:
    The archived QA suite: every test that passed when it was archived (2026-09-29), to re-run after
    big changes. The bug fix tests (nine batches), the review / DLC / garage tests and the occupier
    tests. The bug fix tests run last, their final test blows the player's cover.
    New tests go in the current suite (OTQA_fnc_testsCurrent).

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

private _tests = [];
{
    _tests append (call _x);
} forEach [
    OTQA_fnc_testsFollowups,
    OTQA_fnc_testsOccupiers,
    OTQA_fnc_testsBugFixes
];
_tests;
