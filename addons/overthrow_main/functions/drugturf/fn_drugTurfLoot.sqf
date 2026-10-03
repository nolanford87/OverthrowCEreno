/*
    Description:
    A gang takes its cut of a drug operation by force (server; OT_fnc_drugTurfSquad at the operation,
    OT_fnc_drugTurfAttack for a simulated raid): up to OT_drugTurfLoot (10 ganja, 5 blow) out of the
    containers within 50 m of it. Everyone is told what they took.

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: ARRAY - The operation's drugOps entry

    Usage: [_gangId, _op] call OT_fnc_drugTurfLoot; (server)

    Returns: ARRAY - [ganja taken, blow taken]
*/

params ["_gangId", "_op"];

if (!isServer) exitWith { [] };
_op params ["", "", "_pos"];
private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
private _name = if ((count _gang) isEqualTo 9) then { _gang select 8 } else { "The gang" };

private _taken = [];
private _counts = [];
{
    private _cls = _x;
    private _max = OT_drugTurfLoot getOrDefault [_cls, 0];
    private _n = 0;
    {
        if (_n >= _max) then { break };
        _n = _n + ([_x, _cls, _max - _n] call OT_fnc_removeFromCargo);
    } forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);
    _counts pushBack _n;
    if (_n > 0) then { _taken pushBack format ["%1 %2", _n, _cls call OT_fnc_weaponGetName] };
} forEach ["OT_Ganja", "OT_Blow"];

private _label = [_op] call OT_fnc_drugTurfOpLabel;
(if (_taken isEqualTo []) then {
    format ["%1 raided %2 and found nothing worth taking", _name, _label]
} else {
    format ["%1 raided %2 and took %3: their cut, they say", _name, _label, _taken joinString " and "]
}) remoteExec ["OT_fnc_notifyBad", 0, false];
_counts
