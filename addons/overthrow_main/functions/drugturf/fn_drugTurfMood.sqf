/*
    Description:
    A word for how a gang feels about drugs on its turf, from its anger (OT_fnc_drugTurfAngerOf):
    "not bothered" under half of OT_drugTurfWarnAt, "annoyed" up to it, "angry" from there, "furious"
    from three quarters of OT_drugTurfAttackAt.

    Parameters:
        _this # 0: NUMBER - Anger

    Usage: private _mood = [[_gangId] call OT_fnc_drugTurfAngerOf] call OT_fnc_drugTurfMood;

    Returns: STRING
*/

params ["_anger"];

call {
    if (_anger >= (OT_drugTurfAttackAt * 0.75)) exitWith { "furious" };
    if (_anger >= OT_drugTurfWarnAt) exitWith { "angry" };
    if (_anger >= (OT_drugTurfWarnAt / 2)) exitWith { "annoyed" };
    "not bothered"
}
