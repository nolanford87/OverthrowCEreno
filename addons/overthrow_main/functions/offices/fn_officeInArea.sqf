/*
    Description:
    Is a unit in a mayor's office's area (OT_fnc_officeArea): inside the compound's polygon, or within the
    radius of the office's position. Any machine.

    Parameters:
        _this # 0: OBJECT - Unit
        _this # 1: ARRAY or NUMBER - The area (OT_fnc_officeArea)
        _this # 2: ARRAY - The office's position (for a radius)

    Usage: private _in = [_unit, _area, _pos] call OT_fnc_officeInArea;

    Returns: BOOL
*/

params ["_unit", "_area", "_pos"];

if (_area isEqualType 0) exitWith { (_unit distance2D _pos) <= _area };
(getPosWorld _unit) inPolygon _area
