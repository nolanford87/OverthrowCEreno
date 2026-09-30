/*
    Description:
    A delivery to the occupier (a tank, a patrol aircraft or a FOB's vehicle) waits 8 real minutes
    before it sets off (OT_fnc_NATOdeliveryWait) and may be reported by resistance intelligence as
    soon as it's ordered: 20% + the destination town's resistance support / 20, at most 80%.
    Reported, the players get a task to destroy or steal it before it arrives: $3500 for a tank, $2000
    for an aircraft, $1000 for a FOB vehicle (the callers pass it) and +20 influence to whoever does it.
    It fails when it's delivered (the delivery sets "OT_delivered" on it, or removes it on arrival) or
    40 minutes after it set off, and is cancelled when the delivery is called off.
    The task doesn't track the vehicle: for a route (convoy, fly-in) it shows where it comes from and
    where it goes, for an airdrop an area (off-centre) it may land in.

    Returns a handle the delivery hands the vehicle to once it has set off (["veh", vehicle]; for an
    airdrop the Blackfish, the report then follows what it drops) or calls it off (["cancel", true]).

    Parameters:
        _this # 0: ARRAY - Where it's going
        _this # 1: STRING - What it's for, e.g. "Zaros Base" or "the FOB near Georgetown"
        _this # 2: NUMBER - Money reward (tank 3500, aircraft 2000, FOB vehicle 1000)
        _this # 3: ARRAY - What intelligence knows: ["route", from position] or ["drop", drop position]
        _this # 4: STRING - Class of the vehicle delivered
        _this # 5: NUMBER - Seconds until it sets off

    Usage: private _intel = [_basePos, _name, 3500, ["route", _start], _type, _delay] call OT_fnc_NATOdeliveryIntel;
        ... _intel set ["veh", _tank];

    Returns: HASHMAP - The handle ("reported": BOOL, "task": STRING)
*/

params ["_destination", "_for", ["_reward", 1000], ["_info", []], ["_vehClass", ""], ["_delay", 0]];
_info params [["_kind", "route"], ["_where", _destination]];

private _intel = createHashMapFromArray [["reported", false], ["task", ""]];
private _town = _destination call OT_fnc_nearestTown;
private _support = server getVariable [format ["rep%1", _town], 0];
private _chance = ((20 + (_support / 20)) max 0) min 80;
_chance = missionNamespace getVariable ["OT_deliveryIntelChance", _chance]; // Set only by the QA tests
if (random 100 >= _chance) exitWith { _intel };

private _vehName = _vehClass call OT_fnc_vehicleGetName;
private _taskId = format ["intercept%1", round (diag_tickTime * 1000) + round random 1000];
_intel set ["reported", true];
_intel set ["task", _taskId];

// What intelligence knows, on the map
private _markers = [];
private _taskPos = [];
private _how = "";
private _when = ["It is setting out now", format ["It sets out in about %1 minutes", round (_delay / 60)]] select (_delay >= 60);
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
    _how = format ["%1: it will be airdropped somewhere in the marked area near %2, then head for %3.", _when, _taskPos call OT_fnc_nearestTown, _for];
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
    _how = format ["%1 from near %2, heading for %3.", _when, _where call OT_fnc_nearestTown, _for];
};

[
    independent, [_taskId],
    [
        format ["Resistance intelligence reports that a %1 is being delivered to %2. %4 Destroy it or steal it before it gets there.<br/><br/>Reward: $%3, +20 influence", _vehName, _for, _reward, _how],
        format ["Intercept the %1", _vehName],
        _taskId
    ],
    _taskPos, "CREATED", 1, true, "destroy", true
] call BIS_fnc_taskCreate;
private _soon = ["now", format ["in about %1 minutes", round (_delay / 60)]] select (_delay >= 60);
format ["Resistance intelligence: a %1 is being delivered to %2, setting out %3", _vehName, _for, _soon] remoteExec ["OT_fnc_notifyMinor", 0, false];

[_intel, _markers, _taskId, _vehName, _for, _reward] spawn {
    params ["_intel", "_markers", "_taskId", "_vehName", "_for", "_reward"];

    // Until it sets off (or is called off)
    waitUntil { sleep 1; ("veh" in _intel) || { _intel getOrDefault ["cancel", false] } };
    private _veh = _intel getOrDefault ["veh", objNull];
    if (_intel getOrDefault ["cancel", false] || { isNull _veh }) exitWith {
        { deleteMarker _x } forEach _markers;
        [_taskId, "CANCELED", true] call BIS_fnc_taskSetState;
        format ["The %1 for %2 was called off", _vehName, _for] remoteExec ["OT_fnc_notifyMinor", 0, false];
    };
    _veh setVariable ["OT_interceptTask", _taskId];

    // Who destroyed it
    private _watch = {
        params ["_veh"];
        _veh setVariable ["OT_interceptKiller", objNull];
        _veh addEventHandler ["Killed", {
            params ["_veh", "_killer", "_instigator"];
            _veh setVariable ["OT_interceptKiller", [_killer, _instigator] select (!isNull _instigator)];
            _veh setVariable ["OT_interceptDestroyed", true];
        }];
    };
    [_veh] call _watch;

    private _timeout = time + 2400;
    private _result = "";
    private _winner = objNull;
    waitUntil {
        sleep 3;
        // An airdrop's Blackfish has dropped it: from now on it's about the dropped vehicle
        if (!isNull _veh && { !isNull (_veh getVariable ["OT_deliveryCargo", objNull]) }) then {
            _veh = _veh getVariable ["OT_deliveryCargo", objNull];
            _veh setVariable ["OT_interceptTask", _taskId];
            [_veh] call _watch;
        };
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
        20 remoteExec ["OT_fnc_influence", _winner, false];
    } else {
        20 remoteExec ["OT_fnc_influence", 0, false];
    };
};

_intel;
