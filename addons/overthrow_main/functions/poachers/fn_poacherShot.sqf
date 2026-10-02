/*
    Description:
    A shot fired in a hunting spot: 1 heat to that spot and a quarter of it (OT_poacherSpill) to
    every other spot within 1.5 km (OT_poacherSpillRange). Sent to the server by the "FiredMan"
    handler OT_fnc_wantedSystem adds to players and their recruits. A full spot with a player in it
    gets a patrol (OT_fnc_poacherLoop).

    Parameters:
        _this # 0: NUMBER - Spot index (OT_fnc_inHuntingSpot)

    Usage: [_index] remoteExec ["OT_fnc_poacherShot", 2];

    Returns: NUMBER - The spot's heat now
*/

params [["_index", -1]];

if (!isServer || { _index < 0 }) exitWith { 0 };
private _spots = server getVariable ["huntingSpots", []];
private _pos = _spots param [_index, []];
if (_pos isEqualTo []) exitWith { 0 };

{
    if (_forEachIndex isNotEqualTo _index && { (_x distance2D _pos) < OT_poacherSpillRange }) then {
        [_forEachIndex, OT_poacherSpill] call OT_fnc_poacherHeat;
    };
} forEach _spots;
[_index, 1] call OT_fnc_poacherHeat
