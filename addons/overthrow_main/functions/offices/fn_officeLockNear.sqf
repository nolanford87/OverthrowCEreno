/*
    Description:
    The locked compound door (OT_fnc_officeDoors) a unit is at, for the lockpick: one of the building it's
    looking at, within 3 m. Gates are never picked (only a charge opens them, OT_fnc_officeBreach). Any machine.

    Parameters:
        _this # 0: OBJECT - Unit

    Usage: ([player] call OT_fnc_officeLockNear) params ["_building", "_door"];

    Returns: ARRAY - [building, door], [] for none
*/

params ["_unit"];

private _b = cursorObject;
private _found = [];
{
    private _at = [_b, _x] call OT_fnc_officeDoorPos;
    if (_at isNotEqualTo [] && { ((AGLToASL _at) distance (getPosASL _unit)) < 3 }) exitWith { _found = [_b, _x] };
} forEach (_b getVariable ["OT_lockedDoors", []]);
_found
