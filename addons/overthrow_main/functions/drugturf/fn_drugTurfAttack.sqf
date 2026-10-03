/*
    Description:
    A gang attacks over drugs on its turf (server; OT_fnc_drugTurfAdd when its anger is up). Everyone
    is warned of a raid on an operation, the seller of an ambush; then the squad sets off
    (OT_fnc_drugTurfSquad). A raid on an operation out of spawn distance of every player spawns
    nobody: after OT_drugTurfAttackDelay (3 min) it's simulated, the loot taken all the same
    (OT_fnc_drugTurfLoot), unless a player has come within spawn distance by then, when the squad
    sets off as usual. One squad per gang at a time (OT_drugTurfSquads).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: STRING - "op" (a raid) or "street" (an ambush)
        _this # 2: ARRAY or OBJECT - The drugOps entry raided, or the seller ambushed

    Usage: [_gangId, "op", _op] call OT_fnc_drugTurfAttack; (server)

    Returns: GROUP - The squad; grpNull when none sets off now (a raid out of spawn distance, a squad
        of theirs already out, no such gang)
*/

params ["_gangId", "_mode", "_what"];

if (!isServer) exitWith { grpNull };
private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
if ((count _gang) isNotEqualTo 9) exitWith { grpNull };
private _name = _gang select 8;
if (isNil "OT_drugTurfSquads") then { OT_drugTurfSquads = createHashMap };
if (!isNull (OT_drugTurfSquads getOrDefault [_gangId, grpNull])) exitWith { grpNull };

private _raid = _mode isEqualTo "op";
if (!_raid && { isNull _what || { !alive _what } }) exitWith { grpNull };
private _pos = if (_raid) then { _what select 2 } else { getPosATL _what };
_pos = [_pos select 0, _pos select 1, 0];

if (_raid) then {
    format ["%1 are sending men to %2: pay their cut (talk to them) or defend it", _name, [_what] call OT_fnc_drugTurfOpLabel] remoteExec ["OT_fnc_notifyBad", 0, false];
} else {
    format ["%1 are coming for you: you've been dealing on their turf", _name] remoteExec ["OT_fnc_notifyBad", _what, false];
};

if (!_raid || { [_pos] call OT_fnc_inSpawnDistance }) exitWith { [_gangId, _mode, _what, _pos] call OT_fnc_drugTurfSquad };

// Nobody near the operation: simulated after a while, unless someone comes near meanwhile
[_gangId, _what, _pos] spawn {
    params ["_gangId", "_op", "_pos"];
    private _until = time + OT_drugTurfAttackDelay;
    waitUntil { sleep 5; time > _until || { [_pos] call OT_fnc_inSpawnDistance } };
    if ([_pos] call OT_fnc_inSpawnDistance) exitWith { [_gangId, "op", _op, _pos] call OT_fnc_drugTurfSquad };
    [_gangId, _op] call OT_fnc_drugTurfLoot;
};
grpNull
