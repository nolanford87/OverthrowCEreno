/*
    Description:
    The bug fix QA suite: every bug fix test in one list. The tests for each fix batch live in
    their own file (fn_testsCommon, fn_testsBatch1 ...), this puts them together in run order.
    Batch 7 runs last, its unconscious test blows the player's cover.

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

private _tests = [];
{
    _tests append (call _x);
} forEach [
    OTQA_fnc_testsCommon,
    OTQA_fnc_testsBatch1,
    OTQA_fnc_testsBatch2,
    OTQA_fnc_testsBatch3,
    OTQA_fnc_testsBatch4,
    OTQA_fnc_testsBatch5,
    OTQA_fnc_testsBatch6,
    OTQA_fnc_testsBatch8,
    OTQA_fnc_testsBatch9,
    OTQA_fnc_testsReview,
    OTQA_fnc_testsDLC,
    OTQA_fnc_testsBatch7
];
_tests;
