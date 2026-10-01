/*
    Description:
    How fast game-clock systems should go compared with the game clock, to keep Overthrow's original
    real-time pace (time at 4x): 4 / the current time speed. At 24x it's 1/6 (game hours go 6 times
    faster than the original, so what happens per game hour should happen a sixth as much), at 4x 1,
    at 1x 4. Used by income, business wages, factory production, propaganda and stability drift.

    Usage: private _pace = call OT_fnc_timePace;

    Returns: NUMBER
*/

4 / (timeMultiplier max 1)
