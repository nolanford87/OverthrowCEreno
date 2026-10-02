/*
    Description:
    A player picked up a carcass in a hunting spot (OT_fnc_huntPickup): the poachers may have noticed.
    The chance rises with the spot's hunting pressure (OT_fnc_poacherPressure): nothing up to 1, then
    15% per point over it, at most 60% (a goat 1.5 -> 7.5%, two goats 3 -> 30%, four goats -> 60%).
    No roll while poachers are already there or the spot is quiet after they were wiped out
    (OT_poacherQuiet). On a hit a patrol comes (OT_fnc_poacherPatrol).

    Parameters:
        _this # 0: NUMBER - Spot index
        _this # 1: NUMBER - (Optional, tests) Roll to use, 0 to 1 (default: random)

    Usage: [_index] remoteExec ["OT_fnc_poacherRoll", 2];

    Returns: BOOL - Poachers are coming
*/

params [["_index", -1], ["_roll", -1]];

if (!isServer || { _index < 0 } || { isNil "OT_poacherEvents" }) exitWith { false };
if (_index in OT_poacherEvents) exitWith { false };
if (time < (OT_poacherQuiet getOrDefault [_index, 0])) exitWith { false };
private _chance = ((([_index] call OT_fnc_poacherPressure) - 1) * OT_poacherChanceStep) max 0 min OT_poacherChanceMax;
if (_roll < 0) then { _roll = random 1 };
if (_roll >= _chance) exitWith { false };
!isNull ([_index] call OT_fnc_poacherPatrol)
