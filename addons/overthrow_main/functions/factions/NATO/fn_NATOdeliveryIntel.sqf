/*
    Description:
    A delivery to the occupier (a tank, a patrol aircraft or a FOB's vehicle) may be reported by
    resistance intelligence: 20% + the destination town's resistance support / 20, at most 80%.
    Reported, the players get a task to destroy or steal it before it arrives: $3500 for a tank, $2000
    for an aircraft, $1000 for a FOB vehicle (the callers pass it) and +10 influence to whoever does it. It fails when it's delivered (the delivery sets
    "OT_delivered" on it, or removes it on arrival) or after 40 minutes.
    The task doesn't track the vehicle: for a route (convoy, fly-in) it shows where it comes from and
    where it goes, for an airdrop an area (off-centre) it may land in.

    Parameters:
        _this # 0: OBJECT - The vehicle being delivered
        _this # 1: ARRAY - Where it's going
        _this # 2: STRING - What it's for, e.g. "Zaros Base" or "the FOB near Georgetown"
        _this # 3: NUMBER - Money reward (tank 3500, aircraft 2000, FOB vehicle 1000)
        _this # 4: ARRAY - What intelligence knows: ["route", from position] or ["drop", drop position]

    Usage: [_veh, _destination, _name, 3500, ["route", _start]] spawn OT_fnc_NATOdeliveryIntel;
*/

params ["_veh", "_destination", "_for", ["_reward", 1000], ["_info", []]];
_info params [["_kind", "route"], ["_where", getPos _veh]];

private _town = _destination call OT_fnc_nearestTown;
private _support = server getVariable [format ["rep%1", _town], 0];
private _chance = ((20 + (_support / 20)) max 0) min 80;
_chance = missionNamespace getVariable ["OT_deliveryIntelChance", _chance]; // Set only by the QA tests
if (random 100 >= _chance) exitWith {};

private _vehName = (typeOf _veh) call OT_fnc_vehicleGetName;
private _taskId = format ["intercept%1", round (diag_tickTime * 1000) + round random 1000];

// What intelligence knows, on the map
private _markers = [];
private _taskPos = [];
private _how = "";
if (_kind isEqualTo "drop") then {
    // An area it may land in, not centred on the drop point
    private _radius = 350;
    _taskPos = _where getPos [random (_radius * 0.6), random 360];
    private _area = createMarker [_taskId + "_area", _taskPos];
    _area setMarkerShape "ELLIPSE";
    _area setMarkerSize [_radius, _radius];
    _area setMarkerBrush "FDiagonal";
    _area setMarkerColor "ColorOPFOR";
    private _label = createMarker [_taskId + "_label", _taskPos];
    _label setMarkerType "mil_warning";
    _label setMarkerColor "ColorOPFOR";
    _label setMarkerText format ["Possible drop zone: %1", _vehName];
    _markers = [_area, _label];
    _how = format ["It will be airdropped somewhere in the marked area near %1, then head for %2.", _taskPos call OT_fnc_nearestTown, _for];
} else {
    // Where it comes from and where it goes
    _taskPos = _where;
    private _start = createMarker [_taskId + "_from", _where];
    _start setMarkerType "mil_start";
    _start setMarkerColor "ColorOPFOR";
    _start setMarkerText format ["Delivery from: %1", _vehName];
    private _end = createMarker [_taskId + "_to", _destination];
    _end setMarkerType "mil_end";
    _end setMarkerColor "ColorOPFOR";
    _end setMarkerText format ["Delivery to: %1", _for];
    _markers = [_start, _end];
    _how = format ["It is setting out from near %1, heading for %2.", _where call OT_fnc_nearestTown, _for];
};

[
    independent, [_taskId],
    [
        format ["Resistance intelligence reports that a %1 is being delivered to %2. %4 Destroy it or steal it before it gets there.<br/><br/>Reward: $%3, +10 influence", _vehName, _for, _reward, _how],
        format ["Intercept the %1", _vehName],
        _taskId
    ],
    _taskPos, "CREATED", 1, true, "destroy", true
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

{ deleteMarker _x } forEach _markers;

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
