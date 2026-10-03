/*
    Description:
    The business a drug operation is ("drugOps", OT_fnc_dispensaryRegister / OT_fnc_drugLabRegister):
    a dispensary's id is its business name already, a lab's ("lab0") maps to its name ("Kavala Lab").

    Parameters:
        _this # 0: STRING - Operation id

    Usage: private _name = [_opId] call OT_fnc_drugOpBusiness;

    Returns: STRING - Business name, "" if it's no drug operation
*/

params ["_opId"];

private _ops = server getVariable ["drugOps", []];
private _i = _ops findIf { (_x select 0) isEqualTo _opId };
if (_i < 0) exitWith { "" };
if (((_ops select _i) select 1) isEqualTo "lab") exitWith { (_opId call OT_fnc_drugLabData) param [1, ""] };
_opId
