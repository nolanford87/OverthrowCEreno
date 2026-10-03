/*
    Description:
    A drug operation's heat and raid timers, from the saved server variable "drugHeat":
    [[id, heat, seconds shut, seconds of cooldown], ...] (OT_fnc_drugHeatSet, OT_fnc_drugHeatTick).
    An operation not on it has 0 of each.

    Parameters:
        _this # 0: STRING - Operation id

    Usage: ([_opId] call OT_fnc_drugHeatGet) params ["_heat", "_shut", "_cooldown"];

    Returns: ARRAY - [heat, seconds shut after a raid, seconds before it can be raided again]
*/

params ["_opId"];

private _list = server getVariable ["drugHeat", []];
private _i = _list findIf { (_x select 0) isEqualTo _opId };
if (_i < 0) exitWith { [0, 0, 0] };
(_list select _i) select [1, 3]
