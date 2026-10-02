/*
    Description:
    An animal of a hunting spot was killed by a player or one of the resistance's men (its "Killed"
    event, OT_fnc_spawnHuntingSpot; server): hunting pressure on that spot by the animal's size (half
    the meat it gives, OT_huntMeat: a rabbit 0.5, a goat 1.5), and a quarter of it (OT_poacherSpill)
    on every other spot within 1.5 km (OT_poacherSpillRange). The poachers may come when the meat is
    picked up (OT_fnc_poacherRoll).

    Parameters:
        _this # 0: NUMBER - Spot index
        _this # 1: STRING - The animal's class

    Usage: [_index, typeOf _animal] call OT_fnc_poacherKill; (server)

    Returns: NUMBER - The spot's pressure now
*/

params [["_index", -1], ["_cls", ""]];

if (!isServer || { _index < 0 }) exitWith { 0 };
private _spots = server getVariable ["huntingSpots", []];
private _pos = _spots param [_index, []];
if (_pos isEqualTo []) exitWith { 0 };
private _weight = ((OT_huntMeat getOrDefault [_cls, 1]) / 2) max 0.5;
{
    if (_forEachIndex isNotEqualTo _index && { (_x distance2D _pos) < OT_poacherSpillRange }) then {
        [_forEachIndex, _weight * OT_poacherSpill] call OT_fnc_poacherPressure;
    };
} forEach _spots;
[_index, _weight] call OT_fnc_poacherPressure
