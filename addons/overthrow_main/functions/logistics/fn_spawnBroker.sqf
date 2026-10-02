/*
    Description:
    Spawns a freight broker (spawner, OT_fnc_initLogistics): a worker standing by his loading spot.
    Talking to him (OT_fnc_talkToCiv) offers freight contracts (OT_fnc_logisticsMenu).

    Parameters:
        _this # 0: STRING - Broker id
        _this # 1: STRING - Spawner id

    Usage: [_id, _spawnid] call OT_fnc_spawnBroker; (server, from the virtualization)
*/

params ["_id", "_spawnid"];

private _broker = (server getVariable ["logisticsBrokers", []]) select { (_x select 0) isEqualTo _id };
if (_broker isEqualTo []) exitWith {};
(_broker select 0) params ["", "", "_pos", "_loading"];

private _group = createGroup civilian;
_group setBehaviour "CARELESS";
_group setVariable ["Vcm_Disable", true, true];
private _cls = ["C_man_1", OT_civType_worker] select (isClass (configFile >> "CfgVehicles" >> OT_civType_worker));
private _civ = _group createUnit [_cls, _pos, [], 0, "CAN_COLLIDE"];
_civ setPosATL [_pos select 0, _pos select 1, 0];
_civ setDir (_civ getDir _loading); // Facing his loading spot
_civ disableAI "MOVE";
_civ setVariable ["NOAI", true, false];
_civ setVariable ["OT_broker", _id, true];

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + [_group], false];
