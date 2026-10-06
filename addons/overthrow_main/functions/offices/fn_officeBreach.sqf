/*
    Description:
    A charge gone off (ACE explosives' detonation, fn_initVar): a compound's locked door within 3 m of it
    (OT_fnc_officeDoors), or a compound's locked gate within 5 m (OT_fnc_officeSpawnItems), unlocked and
    blown open (OT_fnc_officeUnlock). A gate only opens this way, a door also to the lockpick. Server.

    Parameters:
        _this # 0: ARRAY - Where the charge went off, ASL

    Usage: [getPosASL _explosive] remoteExec ["OT_fnc_officeBreach", 2];

    Returns: Nothing
*/

params [["_pos", [], [[]]]];

if (_pos isEqualTo []) exitWith {};
{
    private _b = _x;
    if (_b getVariable ["OT_officeGate", false]) then {
        if (((getPosASL _b) distance2D _pos) <= 5) then { [_b, -1, true] call OT_fnc_officeUnlock };
        continue;
    };
    {
        private _at = [_b, _x] call OT_fnc_officeDoorPos;
        if (_at isNotEqualTo [] && { ((AGLToASL _at) distance _pos) <= 3 }) then { [_b, _x, true] call OT_fnc_officeUnlock };
    } forEach +(_b getVariable ["OT_lockedDoors", []]);
} forEach (nearestObjects [ASLToAGL _pos, [], 40, true]);
