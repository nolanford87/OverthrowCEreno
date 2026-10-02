/*
    Description:
    The poacher patrol in a hunting spot has seen a player: one of them calls for backup on the radio,
    for 5-10 seconds (radio chatter anyone nearby hears, OT_fnc_poacherLoop keeps it going, and a
    warning for players within 600 m). Killing the whole patrol before it's done cancels the backup;
    otherwise it comes (OT_fnc_poacherBackup). The player is fair game to them from now on: their
    cover is gone (as when a gang recognizes them) and the patrol opens fire. A hunting licence makes
    no difference to poachers.

    Parameters:
        _this # 0: NUMBER - Hunting spot index
        _this # 1: OBJECT - (Optional) The player they saw (default: objNull)

    Usage: [_index, _player] call OT_fnc_poacherCall; (server)

    Returns: BOOL - Was a call started (false: no patrol there, it's dead, or it already called)
*/

params ["_index", ["_player", objNull]];

if (!isServer || { isNil "OT_poacherEvents" }) exitWith { false };
private _ev = OT_poacherEvents getOrDefault [_index, createHashMap];
if ((count _ev) isEqualTo 0 || { (_ev get "state") isNotEqualTo "patrol" }) exitWith { false };
private _patrol = (_ev get "patrol") select { alive _x };
if (_patrol isEqualTo []) exitWith { false };

private _pos = (server getVariable ["huntingSpots", []]) param [_index, getPosATL (_patrol select 0)];
_ev set ["state", "calling"];
_ev set ["callEnd", time + 5 + random 5];
_ev set ["nextSound", 0];
if (!isNull _player) then {
    _ev set ["target", getPosATL _player];
    // Wanted to them (and to anyone else who sees it), with everyone in their vehicle
    private _veh = vehicle _player;
    { if (captive _x) then { [_x, false] remoteExec ["setCaptive", _x] } } forEach ([_player] + ((crew _veh) - [_player]));
    { (group _x) reveal [_veh, 4] } forEach _patrol;
};
{
    _x setBehaviour "COMBAT";
    _x setCombatMode "RED";
} forEach (_ev get "groups");

// The first of the chatter now, the rest from the loop
private _speaker = _patrol select 0;
playSound3D [selectRandom OT_poacherCallSounds, _speaker, false, getPosASL _speaker, 3, 1, 400];
_ev set ["nextSound", time + 2.5];
private _near = (allPlayers - entities "HeadlessClient_F") select { (_x distance2D _pos) < 600 };
if (_near isNotEqualTo []) then {
    "You hear a poacher shouting into a radio for backup: kill the patrol before the call goes through" remoteExec ["OT_fnc_notifyBad", _near, false];
};
true
