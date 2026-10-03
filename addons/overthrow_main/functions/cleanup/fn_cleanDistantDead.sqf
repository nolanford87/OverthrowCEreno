/*
    Description:
    Removes bodies nobody is near (server): every dead unit farther than _range from all players
    that has been dead at least _minAge real seconds (counted from when this first saw it dead).
    Run every 5 minutes by OT_fnc_GUERLoop (800 m, 10 minutes), whoever is online, and before a save
    when there are too many bodies (OT_fnc_saveGame). Bodies near players stay, to be looted.

    Parameters:
        _this # 0: NUMBER - (Optional) Distance from every player, metres (default: 800)
        _this # 1: NUMBER - (Optional) How long dead, real seconds (default: 600)

    Usage: [800, 600] call OT_fnc_cleanDistantDead;

    Returns: NUMBER - Bodies removed
*/

params [["_range", 800], ["_minAge", 600]];

if (!isServer) exitWith { 0 };
private _players = (allPlayers - (entities "HeadlessClient_F")) apply { getPosATL _x };
private _removed = 0;
{
    private _body = _x;
    private _seen = _body getVariable "OT_deadSince";
    if (isNil "_seen") then { _seen = time; _body setVariable ["OT_deadSince", _seen] };
    if ((time - _seen) < _minAge) then { continue };
    if ((_players findIf { (_x distance2D _body) < _range }) > -1) then { continue };
    if (([_body] call OT_fnc_cleanupUnit) isEqualTo true) then { _removed = _removed + 1 };
} forEach allDeadMen;
if (_removed > 0) then {
    diag_log format ["Overthrow: removed %1 bodies over %2 m from every player", _removed, _range];
};
_removed
