/*
    Description:
    The chance (% per roll, OT_fnc_drugRaidCheck) that the occupier raids a drug operation now: none
    unless the resistance owns it, its heat is OT_drugRaidHeatMin or more and it's neither shut nor in
    its cooldown. From there it grows with heat, OT_drugRaidChanceMax at OT_drugRaidHeatFull, times
    how unstable its town is: the full chance at stability 0, OT_drugRaidStabilityFloor x it at 100.

    Parameters:
        _this # 0: STRING - Operation id

    Usage: private _chance = [_opId] call OT_fnc_drugRaidChance;

    Returns: NUMBER - 0 to OT_drugRaidChanceMax
*/

params ["_opId"];

private _ops = server getVariable ["drugOps", []];
private _i = _ops findIf { (_x select 0) isEqualTo _opId };
if (_i < 0 || { !([_opId] call OT_fnc_drugOpOwned) }) exitWith { 0 };
([_opId] call OT_fnc_drugHeatGet) params ["_heat", "_shut", "_cooldown"];
if (_heat < OT_drugRaidHeatMin || { _shut > 0 } || { _cooldown > 0 }) exitWith { 0 };

private _town = (_ops select _i) select 3;
private _stability = server getVariable [format ["stability%1", _town], 100];
private _byHeat = ((_heat / OT_drugRaidHeatFull) min 1) * OT_drugRaidChanceMax;
private _byStability = (((100 - _stability) / 100) max OT_drugRaidStabilityFloor) min 1;
_byHeat * _byStability
