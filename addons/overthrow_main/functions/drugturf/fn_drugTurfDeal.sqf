/*
    Description:
    Starts or ends the resistance's deal with a gang over its turf (server; the saved server variable
    "drugTurfDeals": [gang id, dealmaker's uid, cash paid, blow paid, rep bucket] per deal). Starting:
    the dealmaker (a player on) pays OT_drugTurfDealFee out of their money (OT_fnc_money on their
    machine) and gets OT_drugTurfDealRep rep with the gang; from then on the gang takes OT_drugTurfCut
    of what's made on its turf instead of getting angry (OT_fnc_drugTurf, OT_fnc_drugTurfStreet), its
    anger is forgotten and a squad it has out goes home (OT_fnc_drugTurfSquad). Ending: nothing more
    is owed, the gang wants its turf respected again. Everyone is told either way. A deal with a gang
    that's gone ends by itself (OT_fnc_drugTurfDealOf).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: STRING - The dealmaker's uid
        _this # 2: BOOL - true to start (default), false to end

    Usage: [_gangId, getPlayerUID player, true] remoteExec ["OT_fnc_drugTurfDeal", 2, false];

    Returns: BOOL - Done (false: no such gang, a deal already / none, the dealmaker off or short of
        the fee)
*/

params ["_gangId", "_uid", ["_start", true]];

if (!isServer) exitWith { false };
private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
if ((count _gang) isNotEqualTo 9) exitWith { false };
private _name = _gang select 8;
private _deals = server getVariable ["drugTurfDeals", []];
private _i = _deals findIf { (_x select 0) isEqualTo _gangId };

if (_start) exitWith {
    if (_i > -1) exitWith { false };
    private _maker = (allPlayers select { (getPlayerUID _x) isEqualTo _uid }) param [0, objNull];
    if (isNull _maker || { (_maker getVariable ["money", 0]) < OT_drugTurfDealFee }) exitWith { false };
    [-OT_drugTurfDealFee, format ["%1's fee", _name]] remoteExec ["OT_fnc_money", _maker, false];

    _deals pushBack [_gangId, _uid, 0, 0, 0];
    server setVariable ["drugTurfDeals", _deals, true];

    // Forgiven and forgotten
    private _state = [_gangId] call OT_fnc_drugTurfState;
    _state set [1, 0];
    _state set [4, false];
    _state set [5, 0];
    [_gangId, _state] call OT_fnc_drugTurfState;
    private _squad = (missionNamespace getVariable ["OT_drugTurfSquads", createHashMap]) getOrDefault [_gangId, grpNull];
    if (!isNull _squad) then { _squad setVariable ["OT_drugTurfEnd", true] };

    [_maker, _gangId, OT_drugTurfDealRep, "the deal"] call OT_fnc_gangRep;
    format ["Deal with %1: they take %2 of what we make on their turf (%3 km round their camp); our operations and dealing there are safe from them", _name, (str (round (OT_drugTurfCut * 100))) + "%", OT_drugTurfRadius / 1000] remoteExec ["OT_fnc_notifyGood", 0, false];
    true
};

if (_i < 0) exitWith { false };
_deals deleteAt _i;
server setVariable ["drugTurfDeals", _deals, true];
format ["The deal with %1 is off: they'll want their turf respected again", _name] remoteExec ["OT_fnc_notifyMinor", 0, false];
true
