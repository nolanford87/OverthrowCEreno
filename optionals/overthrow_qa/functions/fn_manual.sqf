/*
    Description:
    Adds a check that has to be done by hand in game (or a test that had to be skipped).

    Parameters:
        _this: STRING - What to check

    Usage: "Get knocked out with no medic around, the respawn hint should show" call OTQA_fnc_manual;
*/

OTQA_manual pushBack _this;
diag_log format ["OT_QA MANUAL [%1] %2", OTQA_currentGroup, _this];
