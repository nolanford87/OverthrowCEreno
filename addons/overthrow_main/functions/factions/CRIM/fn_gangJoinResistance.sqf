params ["_leader", "_gangid", "_player"];

private _gang = OT_civilians getVariable [format ["gang%1", _gangid], []];
if (_gang isEqualTo []) exitWith { diag_log "Overthrow Error: gang not found (OT_fnc_gangJoinResistance)" };

private _group = createGroup independent;
private _name = _gang select 8;
private _town = _gang select 2;

[_leader] joinSilent grpNull;
[_leader] joinSilent _group;
_group selectLeader _leader;
_leader enableAI "PATH";

private _cc = _player getVariable ["OT_squadcount", 0];
_group setGroupIdGlobal [_name];
_cc = _cc + 1;
_player hcSetGroup [_group, groupId _group, "teamgreen"];

private _gangGroup = spawner getVariable [format ["gangspawn%1", _gangid], grpNull];

{
    [_x] joinSilent grpNull;
    [_x] joinSilent _group;
    [_x, getPlayerUID player] call OT_fnc_setOwner;
    _x setVariable ["OT_spawntrack", true, true];
    player reveal [_x, 4];
} forEach (units _gangGroup);

_player setVariable ["OT_squadcount", _cc, true];

private _recruits = server getVariable ["squads", []];
_recruits pushBack [getPlayerUID _player, _gangid, _group, []];
server setVariable ["squads", _recruits, true];

// Remove the gang like the other places a gang ends, so the town can get a new gang later
OT_civilians setVariable [format ["gang%1", _gangid], nil, true];
private _gangs = OT_civilians getVariable [format ["gangs%1", _town], []];
private _idx = _gangs find _gangid;
if (_idx > -1) then { _gangs deleteAt _idx };
OT_civilians setVariable [format ["gangs%1", _town], _gangs, true];
deleteMarker format ["gang%1", _town];
spawner setVariable [format ["gangspawn%1", _gangid], grpNull, true];

format ["%1 has joined the resistance as your squad, use ctrl + space to command", _name] call OT_fnc_notifyMinor;
