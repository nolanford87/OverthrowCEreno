/*
    Description:
    Angers a gang about drugs on its turf (server; OT_fnc_drugTurf for an operation,
    OT_fnc_drugTurfStreet for a street sale). The points go on its record (OT_fnc_drugTurfState),
    halved (OT_drugTurfLenient) when one of the players blamed has OT_drugGangRep or more rep with the
    gang; every OT_drugTurfRepPer points cost those players 1 rep with it (OT_fnc_gangRep, the odd
    points carried over). At OT_drugTurfWarnAt the gang warns once (everyone, about an operation; the
    seller, about their dealing); at OT_drugTurfAttackAt, OT_drugTurfAttackWait or more after its last
    attack, it attacks (OT_fnc_drugTurfAttack: a raid on the operation, an ambush on the seller) and the
    anger is spent.

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: NUMBER - Anger points
        _this # 2: ARRAY - The players blamed (rep loss)
        _this # 3: ARRAY - What it's about: ["op", drugOps entry] or ["street", the seller]

    Usage: [_gangId, 6, allPlayers, ["op", _op]] call OT_fnc_drugTurfAdd; (server)

    Returns: NUMBER - Anger now (0 right after an attack)
*/

params ["_gangId", "_points", "_players", "_source"];

private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
if ((count _gang) isNotEqualTo 9 || { _points <= 0 }) exitWith { 0 };
private _name = _gang select 8;
_players = _players select { !isNull _x && { isPlayer _x } };
_source params ["_kind", "_what"];

// A friend of the gang vouches for it: half the offence
private _bestRep = -1e9;
{ _bestRep = _bestRep max (_x getVariable [format ["gangrep%1", _gangId], 0]) } forEach _players;
if (_bestRep >= OT_drugGangRep) then { _points = _points * OT_drugTurfLenient };

private _state = [_gangId] call OT_fnc_drugTurfState;
_state params ["", "_anger", "", "_lastAttack", "_warned", "_bucket"];
_anger = (_anger + _points) min (OT_drugTurfAttackAt * 2);

// Rep: whole points, the rest carried over
_bucket = _bucket + (_points / OT_drugTurfRepPer);
if (_bucket >= 0.9999) then {
    private _lost = floor (_bucket + 0.0001);
    _bucket = _bucket - _lost;
    { [_x, _gangId, -_lost, "dealing on their turf"] call OT_fnc_gangRep } forEach _players;
};

if (!_warned && { _anger >= OT_drugTurfWarnAt }) then {
    _warned = true;
    if (_kind isEqualTo "op") then {
        format ["%1 are angry about %2 on their turf: pay their cut (talk to them) or expect trouble", _name, [_what] call OT_fnc_drugTurfOpLabel] remoteExec ["OT_fnc_notifyBad", 0, false];
    } else {
        if (!isNull _what) then {
            format ["%1 don't like you dealing on their turf: pay their cut (talk to them) or expect trouble", _name] remoteExec ["OT_fnc_notifyBad", _what, false];
        };
    };
};

if (_anger >= OT_drugTurfAttackAt && { (serverTime - _lastAttack) >= OT_drugTurfAttackWait }) then {
    _anger = 0;
    _warned = false;
    _lastAttack = serverTime;
    [_gangId, _kind, _what] call OT_fnc_drugTurfAttack;
};

[_gangId, [_gangId, _anger, serverTime, _lastAttack, _warned, _bucket]] call OT_fnc_drugTurfState;
_anger
