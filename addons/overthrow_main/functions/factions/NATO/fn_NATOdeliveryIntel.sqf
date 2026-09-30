/*
    Description:
    A delivery to the occupier (a tank, a patrol aircraft or a FOB's vehicle) may be reported by
    resistance intelligence: 20% + the destination town's resistance support / 20, at most 80%.
    Reported, the players get a task to destroy or steal it before it arrives: $500 ($250 for a FOB
    vehicle) and +10 influence to whoever does it. It fails when it's delivered (the delivery sets
    "OT_delivered" on it, or removes it on arrival) or after 40 minutes.

    Parameters:
        _this # 0: OBJECT - The vehicle being delivered
        _this # 1: ARRAY - Where it's going
        _this # 2: STRING - What it's for, e.g. "Zaros Base" or "the FOB near Georgetown"
        _this # 3: NUMBER - Money reward

    Usage: [_veh, _destination, _name, 500] spawn OT_fnc_NATOdeliveryIntel;
*/

params ["_veh", "_destination", "_for", ["_reward", 500]];

private _town = _destination call OT_fnc_nearestTown;
private _support = server getVariable [format ["rep%1", _town], 0];
private _chance = ((20 + (_support / 20)) max 0) min 80;
_chance = missionNamespace getVariable ["OT_deliveryIntelChance", _chance]; // Set only by the QA tests
if (random 100 >= _chance) exitWith {};

private _vehName = (typeOf _veh) call OT_fnc_vehicleGetName;
private _taskId = format ["intercept%1", round (diag_tickTime * 1000) + round random 1000];
[
    independent, [_taskId],
    [
        format ["Resistance intelligence reports that a %1 is being delivered to %2. Destroy it or steal it before it gets there.<br/><br/>Reward: $%3, +10 influence", _vehName, _for, _reward],
        format ["Intercept the %1", _vehName],
        _taskId
    ],
    _veh, "CREATED", 1, true, "destroy", true
] call BIS_fnc_taskCreate;
_veh setVariable ["OT_interceptTask", _taskId];
format ["Resistance intelligence: a %1 is being delivered to %2", _vehName, _for] remoteExec ["OT_fnc_notifyMinor", 0, false];

// Who destroyed it
_veh setVariable ["OT_interceptKiller", objNull];
_veh addEventHandler ["Killed", {
    params ["_veh", "_killer", "_instigator"];
    _veh setVariable ["OT_interceptKiller", [_killer, _instigator] select (!isNull _instigator)];
    _veh setVariable ["OT_interceptDestroyed", true];
}];

private _timeout = time + 2400;
private _result = "";
private _winner = objNull;
waitUntil {
    sleep 3;
    call {
        if (isNull _veh) exitWith { _result = "delivered" }; // Removed on arrival
        if (_veh getVariable ["OT_interceptDestroyed", false]) exitWith {
            _result = "destroyed";
            _winner = _veh getVariable ["OT_interceptKiller", objNull];
        };
        if (_veh call OT_fnc_hasOwner) exitWith {
            _result = "stolen";
            private _uid = _veh call OT_fnc_getOwner;
            _winner = (allPlayers select { getPlayerUID _x isEqualTo _uid }) param [0, objNull];
        };
        if (_veh getVariable ["OT_delivered", false]) exitWith { _result = "delivered" };
        if (time > _timeout) exitWith { _result = "delivered" };
    };
    _result isNotEqualTo ""
};

if (_result isEqualTo "delivered") exitWith {
    [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
    format ["The %1 reached %2", _vehName, _for] remoteExec ["OT_fnc_notifyBad", 0, false];
};

[_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
format ["The %1 for %2 was %3", _vehName, _for, _result] remoteExec ["OT_fnc_notifyGood", 0, false];

// The reward goes to whoever did it (a resistance AI: the money is shared by everyone), with
// influence. Nobody to credit (it crashed, the thief is offline): everyone gets the influence
if (!isNull _winner) then { [_winner, _reward] call OT_fnc_rewardMoney };
if (!isNull _winner && { isPlayer _winner }) then {
    10 remoteExec ["OT_fnc_influence", _winner, false];
} else {
    10 remoteExec ["OT_fnc_influence", 0, false];
};
