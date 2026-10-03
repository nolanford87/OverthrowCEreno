/*
    Description:
    The occupier's nearest airfield (one it still holds) to a position, where bought aircraft come from.
    A base that is an airfield itself gets its aircraft from another one, unless it's the only one left.

    Parameters:
        _this # 0: ARRAY - Position
        _this # 1: STRING - (Optional) Base asking, not used unless it's the only airfield

    Usage: private _airfield = [_pos, _name] call OT_fnc_NATOnearestAirfield;

    Returns: ARRAY - [position, name], [] when the occupier holds no airfield
*/

params ["_pos", ["_exclude", ""]];

private _held = call OT_fnc_NATOheldAirfields;
if (_held isEqualTo []) exitWith { [] };

private _others = _held select { (_x select 1) isNotEqualTo _exclude };
if (_others isEqualTo []) then { _others = _held };

private _nearest = ([_others, [], { (_x select 0) distance2D _pos }, "ASCEND"] call BIS_fnc_sortBy) select 0;
[_nearest select 0, _nearest select 1];
