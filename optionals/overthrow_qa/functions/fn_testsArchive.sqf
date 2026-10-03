/*
    Description:
    The archived QA suite: every test that passed when it was archived (2026-09-29, delivery
    intelligence 2026-09-30, deliveries / FOB clear-up / vanilla DLC vehicles / convoys on the road /
    creator DLC occupiers 2026-10-01, hunting / real-time pace / fishing / freight logistics 2026-10-02, freight slice 2 / poachers / fisherman / airdrop escort / town counter-attacks / virtual FOB garrisons 2026-10-03), to re-run
    after big changes. The virtual FOB garrison tests, the town counter-attack tests, the airdrop escort tests, the poacher and fisherman tests, the freight logistics (airfield offices, smuggling, hijacks), real-time pace and fishing tests, the delivery intelligence tests (airdrops, convoys, the 8 minute wait), the FOB
    clear-up tests, the vanilla DLC vehicle test, the bug fix tests (nine batches), the review / DLC /
    garage tests and the occupier tests. The bug fix tests run last, their final test blows the
    player's cover.
    New tests go in the current suite (OTQA_fnc_testsCurrent).

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

private _tests = [];
{
    _tests append (call _x);
} forEach [
    OTQA_fnc_testsFOBVirtual,
    OTQA_fnc_testsCounterattacks,
    OTQA_fnc_testsAirdropEscort,
    OTQA_fnc_testsPoachers,
    OTQA_fnc_testsFisherman,
    OTQA_fnc_testsLogistics,
    OTQA_fnc_testsLogisticsAirfields,
    OTQA_fnc_testsSmuggling,
    OTQA_fnc_testsHijacks,
    OTQA_fnc_testsPace,
    OTQA_fnc_testsFishing,
    OTQA_fnc_testsHunting,
    OTQA_fnc_testsIntel,
    OTQA_fnc_testsFOB,
    OTQA_fnc_testsDLCVehicles,
    OTQA_fnc_testsFollowups,
    OTQA_fnc_testsOccupiers,
    OTQA_fnc_testsBugFixes
];
_tests;
