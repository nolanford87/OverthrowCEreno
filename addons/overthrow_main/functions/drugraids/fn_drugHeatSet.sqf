/*
    Description:
    Sets a drug operation's heat and raid timers in the saved server variable "drugHeat" (server):
    [[id, heat, seconds shut, seconds of cooldown], ...]. Values left out (or negative) stay as they
    are; an operation not on the list is added.

    Parameters:
        _this # 0: STRING - Operation id
        _this # 1: NUMBER - (Optional) Heat
        _this # 2: NUMBER - (Optional) Seconds it's shut for after a raid
        _this # 3: NUMBER - (Optional) Seconds before it can be raided again

    Usage: [_opId, 0] call OT_fnc_drugHeatSet; (server)
        [_opId, -1, OT_drugRaidShutTime, OT_drugRaidCooldown] call OT_fnc_drugHeatSet;

    Returns: ARRAY - [heat, seconds shut, seconds of cooldown] now
*/

params ["_opId", ["_heat", -1], ["_shut", -1], ["_cooldown", -1]];

private _list = server getVariable ["drugHeat", []];
private _i = _list findIf { (_x select 0) isEqualTo _opId };
private _entry = if (_i < 0) then { [_opId, 0, 0, 0] } else { _list select _i };
if (_heat >= 0) then { _entry set [1, _heat] };
if (_shut >= 0) then { _entry set [2, _shut] };
if (_cooldown >= 0) then { _entry set [3, _cooldown] };
if (_i < 0) then { _list pushBack _entry };
server setVariable ["drugHeat", _list, true];
_entry select [1, 3]
