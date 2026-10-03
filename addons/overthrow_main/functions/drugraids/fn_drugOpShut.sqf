/*
    Description:
    Is a drug operation shut after a raid (OT_fnc_drugRaid)? While it is, its business cycle makes and
    sells nothing (OT_fnc_dispensaryCycle, OT_fnc_drugLabCycle); the time is counted down in real
    time while players are online (OT_fnc_drugHeatTick).

    Parameters:
        _this # 0: STRING - Operation id

    Usage: if (([_opId] call OT_fnc_drugOpShut) > 0) exitWith { 0 };

    Returns: NUMBER - Real seconds it's shut for, 0 when open
*/

params ["_opId"];

([_opId] call OT_fnc_drugHeatGet) select 1
