/*
    Description:
    A gang's squad sets off over drugs on its turf (server, OT_fnc_drugTurfAttack): OT_drugTurfSquad
    (3) of its members with its gear (OT_fnc_initCriminal), on foot, from 250-350 m away (200-300 for
    an ambush), on land and away from players.
    A raid: they walk to the operation; a player within 150 m of them is fair game (they open fire,
    and the player loses their cover, as when a gang recognizes them); within 30 m of the operation
    they take their cut by force (OT_fnc_drugTurfLoot) and go home.
    An ambush: they come for the seller, opening fire within 100 m, until they're dead, out of reach
    (1 km from where they dealt) or the squad gives up.
    The squad goes home (to the camp) once it's done, all dead, after OT_drugTurfSquadTimeout
    (10 min), or when the gang's deal is made meanwhile (its group variable OT_drugTurfEnd), and is
    deleted once no player is within 400 m of any of them. One per gang at a time
    (OT_drugTurfSquads: gang id to group).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: STRING - "op" (a raid) or "street" (an ambush)
        _this # 2: ARRAY or OBJECT - The drugOps entry raided, or the seller ambushed
        _this # 3: ARRAY - Where to: the operation, or where the seller is

    Usage: [_gangId, "op", _op, _pos] call OT_fnc_drugTurfSquad; (server)

    Returns: GROUP - The squad, grpNull when one of theirs is out already (or no such gang)
*/

params ["_gangId", "_mode", "_what", "_pos"];

if (!isServer) exitWith { grpNull };
private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
if ((count _gang) isNotEqualTo 9) exitWith { grpNull };
_gang params ["", "", "_town", "", "_camp", "", "", "", "_name"];
if (isNil "OT_drugTurfSquads") then { OT_drugTurfSquads = createHashMap };
if (!isNull (OT_drugTurfSquads getOrDefault [_gangId, grpNull])) exitWith { grpNull };
private _raid = _mode isEqualTo "op";
_pos = [_pos select 0, _pos select 1, 0];

// Where they set off
private _from = [250, 200] select !_raid;
private _spot = [];
for "_i" from 1 to 12 do {
    private _p = _pos getPos [_from + random 100, random 360];
    if (surfaceIsWater _p) then { continue };
    _p = _p findEmptyPosition [0, 50, "CAManBase"];
    if (_p isEqualTo [] || { surfaceIsWater _p }) then { continue };
    if ((allPlayers findIf { (_x distance2D _p) < 150 }) > -1) then { continue };
    _spot = _p;
    break;
};
if (_spot isEqualTo []) then { _spot = _pos getPos [_from + 50, random 360] };
_spot = [_spot select 0, _spot select 1, 0];

private _group = createGroup [opfor, true];
_group setVariable ["VCM_TOUGHSQUAD", true, true];
_group setVariable ["VCM_NORESCUE", true, true];
_group setVariable ["OT_drugTurf", _gangId, true];
for "_i" from 1 to OT_drugTurfSquad do {
    private _unit = _group createUnit [OT_CRIM_Unit, _spot getPos [2 + random 4, random 360], [], 0, "NONE"];
    [_unit] joinSilent _group;
    [_unit, _town, [], _gangId] call OT_fnc_initCriminal;
    _unit setVariable ["OT_gangid", _gangId, true];
    _unit setVariable ["hometown", _town, true];
    _unit setVariable ["OT_drugTurf", _gangId, true];
    { _x addCuratorEditableObjects [[_unit], false] } forEach allCurators;
};
_group setBehaviour "AWARE";
_group setCombatMode "YELLOW";
_group setSpeedMode "FULL";
_group move _pos;
OT_drugTurfSquads set [_gangId, _group];

[_gangId, _group, units _group, _raid, _what, _pos, _camp, _name] spawn {
    params ["_gangId", "_group", "_members", "_raid", "_what", "_pos", "_camp", "_name"];
    private _started = time;
    private _hostile = false;
    private _nextMove = 0;
    private _reach = [150, 100] select !_raid;
    private _label = "";
    if (_raid) then { _label = [_what] call OT_fnc_drugTurfOpLabel };

    while { true } do {
        sleep 2;
        private _alive = _members select { alive _x };
        if (_alive isEqualTo []) exitWith {
            if (_raid) then {
                format ["%1's men are dead: %2 is safe for now", _name, _label] remoteExec ["OT_fnc_notifyGood", 0, false];
            } else {
                if (!isNull _what) then { format ["%1's men are dead", _name] remoteExec ["OT_fnc_notifyGood", _what, false] };
            };
        };
        if ((time - _started) > OT_drugTurfSquadTimeout || { _group getVariable ["OT_drugTurfEnd", false] }) exitWith {};
        if (!_raid && { isNull _what || { !alive _what } || { (_what distance2D _pos) > 1000 } }) exitWith {};

        // A player near them is fair game
        private _near = objNull;
        {
            private _p = _x;
            if ((_alive findIf { (_x distance _p) < _reach }) > -1) exitWith { _near = _p };
        } forEach (allPlayers select { alive _x });
        if (!isNull _near) then {
            private _veh = vehicle _near;
            if (captive _near) then {
                { [_x, false] remoteExec ["setCaptive", _x] } forEach ([_near] + ((crew _veh) - [_near]));
            };
            _group reveal [_veh, 4];
            if (!_hostile) then {
                _hostile = true;
                _group setBehaviour "COMBAT";
                _group setCombatMode "RED";
                format ["%1's men open fire", _name] remoteExec ["OT_fnc_notifyBad", _near, false];
            };
            _group move (getPosATL _veh);
            _nextMove = time + 10;
        } else {
            if (time > _nextMove) then {
                _nextMove = time + 20;
                if (_raid) then { _group move _pos } else { _group move (getPosATL _what) };
            };
        };

        // At the operation: their cut, by force
        if (_raid && { (_alive findIf { (_x distance2D _pos) < 30 }) > -1 }) exitWith {
            [_gangId, _what] call OT_fnc_drugTurfLoot;
            sleep 5;
        };
    };

    // Home: back to their camp, deleted once no player is within 400 m
    _group setBehaviour "SAFE";
    _group setCombatMode "YELLOW";
    _group move _camp;
    waitUntil {
        sleep 10;
        (_members findIf { private _o = _x; !isNull _o && { (allPlayers findIf { (_x distance2D _o) < 400 }) > -1 } }) isEqualTo -1
    };
    if ((OT_drugTurfSquads getOrDefault [_gangId, grpNull]) isEqualTo _group) then { OT_drugTurfSquads deleteAt _gangId };
    { if (!isNull _x) then { deleteVehicle _x } } forEach _members;
    sleep 1;
    deleteGroup _group;
};
_group
