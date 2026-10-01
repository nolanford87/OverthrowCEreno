/*
    Description:
    The current QA suite: tests for the changes since the last archive. Once they pass, they move
    to the archived suite (OTQA_fnc_testsArchive).

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

private _tests = [];
// Intel 1 only: its first delivery was wrecked spawning against a building (spawn protection added since);
// the other delivery intelligence tests are archived
_tests append ((call OTQA_fnc_testsIntel) select { ((_x select 0) find "Intel 1:") isEqualTo 0 });
{
    _tests append (call _x);
} forEach [
    OTQA_fnc_testsOccupiers // Every lobby option, with the creator DLC ones (19-25)
];

if (_tests isEqualTo []) then {
    "No current tests yet, everything is in the archived QA tests" call OTQA_fnc_manual;
};
_tests;
