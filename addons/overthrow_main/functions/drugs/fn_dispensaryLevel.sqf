/*
    Description:
    A dispensary's level ("drugOps", OT_fnc_dispensaryRegister): 1 a ganja shop, 2 with the back room
    selling blow, 0 if not running (not bought yet).

    Parameters:
        _this: STRING - Dispensary (business name)

    Usage: private _level = _name call OT_fnc_dispensaryLevel;

    Returns: NUMBER
*/

private _ops = server getVariable ["drugOps", []];
private _index = _ops findIf { (_x select 0) isEqualTo _this && { (_x select 1) isEqualTo "dispensary" } };
if (_index < 0) exitWith { 0 };
(_ops select _index) select 4
