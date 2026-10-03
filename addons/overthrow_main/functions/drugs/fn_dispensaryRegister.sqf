/*
    Description:
    Registers a dispensary as a drug operation (server): the saved server variable "drugOps" holds
    [id, type, position, town, level] for each (labs are added the same way), for the systems that
    look for them. A dispensary's id is its business name, its type "dispensary". Registering one
    already there keeps its level unless a level is given.

    Parameters:
        _this # 0: STRING - Dispensary (business name)
        _this # 1: NUMBER - (Optional) Level: 1 a ganja shop, 2 with the back room selling blow

    Usage: [_name] call OT_fnc_dispensaryRegister; (server)

    Returns: NUMBER - Its level, 0 if it isn't a dispensary
*/

params ["_name", ["_level", -1]];

if !(_name in OT_dispensaries) exitWith { 0 };
private _data = _name call OT_fnc_getBusinessData;
if (_data isEqualTo []) exitWith { 0 };
private _pos = _data select 0;

private _ops = server getVariable ["drugOps", []];
private _index = _ops findIf { (_x select 0) isEqualTo _name };
if (_index > -1) then {
    if (_level > 0) then { (_ops select _index) set [4, _level] };
    _level = (_ops select _index) select 4;
} else {
    _level = _level max 1;
    _ops pushBack [_name, "dispensary", _pos, _pos call OT_fnc_nearestTown, _level];
};
server setVariable ["drugOps", _ops, true];
_level
