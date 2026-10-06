/*
    Description:
    Where a building's door is (its "Door_<n>_trigger" memory point), for locking, picking and breaching
    (OT_fnc_officeDoors, OT_fnc_officeLockNear, OT_fnc_officeBreach). Any machine.

    Parameters:
        _this # 0: OBJECT - Building
        _this # 1: NUMBER - Door, from 1

    Usage: private _at = [_building, 1] call OT_fnc_officeDoorPos;

    Returns: ARRAY - Position AGL, [] where the building doesn't say
*/

params ["_building", "_door"];

private _rel = _building selectionPosition [format ["Door_%1_trigger", _door], "Memory"];
if (_rel isEqualTo [0, 0, 0]) exitWith { [] };
_building modelToWorld _rel
