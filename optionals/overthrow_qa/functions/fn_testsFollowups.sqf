/*
    Description:
    The review and DLC QA suite: tests for the fixes made after the nine bug fix batches
    (second review follow-ups, DLC compatibility, randomized loadout pools).
    Run it on each map, the DLC tests check that map's own class lists.

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

private _tests = [];
{
    _tests append (call _x);
} forEach [
    OTQA_fnc_testsReview,
    OTQA_fnc_testsDLC,
    OTQA_fnc_testsGarage
];
_tests;
