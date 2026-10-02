/*
    Description:
    Is a position in a town: within its spread (350 m from the centre, 1000 m for capitals and
    sprawling towns) plus an extra distance.

    Parameters:
        _this # 0: ARRAY / OBJECT - Position
        _this # 1: NUMBER - (Optional) Extra metres around the town

    Usage: [getPos player] call OT_fnc_isInTown;

    Returns: BOOL
*/

params ["_pos", ["_extra", 0]];

private _town = _pos call OT_fnc_nearestTown;
private _townPos = server getVariable [_town, []];
if (_townPos isEqualTo []) exitWith { false };
(_townPos distance2D _pos) < (([350, 1000] select (_town in (OT_capitals + OT_sprawling))) + _extra)
