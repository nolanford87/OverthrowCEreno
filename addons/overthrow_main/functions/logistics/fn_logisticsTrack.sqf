/*
    Description:
    Tracks a freight haul until it ends (server, spawned by OT_fnc_logisticsStart), every 3 seconds.

    Delivered: every crate of the job that still exists is within 30 m (2D) of the drop-off and on
    the ground - not attached to anything (ACE attaches a loaded crate to its vehicle, hidden, and
    carrying/dragging attaches it to the player) and not listed in a nearby vehicle's ACE cargo
    (ace_cargo_loaded). Pay: the contract's pay for the share of crates that made it, -10% per full
    5 minutes over the time limit; +1 support in the town it went to.

    There's no cargo damage (the crates can't be damaged). The load is only lost when:
    - "lost": every crate is gone - deleted, or loaded in a vehicle that was destroyed,
    - "seized": the player is killed while wanted - the occupier takes the cargo,
    - "hijacked": the player is killed by a gang - the gang takes the cargo.
    Seized and hijacked crates are deleted straight away. Dying any other way doesn't end the job:
    the player's new body (after a respawn or reconnect) gets the job and its unload action back.
    "late": twice the time limit has gone by.

    The player's death: their body is watched; whether they were wanted is how they last were while
    alive and conscious (ACE sets a player wanted as they fall unconscious), the killer comes from
    OT_fnc_deathHandler on their machine (OT_killedBy on the body). The death is passed on in
    OT_haulDeath_<id> = [killer, wanted] (the QA tests set it too) and judged by OT_fnc_logisticsDeath.

    Gangs: every 30 seconds while the player drives the loaded cargo vehicle, a gang may try to
    hijack it (OT_fnc_logisticsHijack: often on gang turf, rarely elsewhere), at most twice per job and
    5 minutes apart.

    Afterwards the rental goes back to the broker straight away (not the player's any more, locked,
    gone 20 seconds later) and leftover crates are deleted once no player is within 300 m. Then
    OT_fnc_logisticsSettle (if there is one) gets [contract, uid, result]; the result is also kept in
    OT_haulLastResult = [job id, result].

    Parameters:
        _this # 0: ARRAY - Contract (see OT_fnc_logisticsStart)
        _this # 1: STRING - UID of the player who accepted it (found again if they reconnect)
        _this # 2: ARRAY - The job's crates
        _this # 3: OBJECT - Rental vehicle, objNull if none
        _this # 4: STRING - Task id
        _this # 5: STRING - Pickup marker
        _this # 6: NUMBER - Time the job started (server time)

    Usage: [_contract, _uid, _crates, _veh, _taskId, _marker, time] spawn OT_fnc_logisticsTrack;
*/

params ["_contract", "_uid", "_crates", "_veh", "_taskId", "_marker", "_started"];
_contract params ["_id", "_fromPos", "_fromName", "_toPos", "_toName", "_count", "_size", "_pay", "_timeLimit"];

if (!isServer) exitWith {};

// A crate is in a vehicle while ACE has it in its cargo (loaded crates are attached and hidden)
private _isLoaded = {
    params ["_crate"];
    if (!isNull (attachedTo _crate)) exitWith { true };
    (((getPosATL _crate) nearEntities [["LandVehicle", "Air", "Ship"], 50]) findIf {
        _crate in (_x getVariable ["ace_cargo_loaded", []])
    }) > -1
};

// The job is running (OT_fnc_logisticsHijack's gangs go home once it isn't); no death waiting yet
private _runningVar = format ["OT_haulRunning_%1", _id];
private _deathVar = format ["OT_haulDeath_%1", _id];
missionNamespace setVariable [_runningVar, true];
missionNamespace setVariable [_deathVar, nil];

private _result = "";
private _delivered = 0;
private _elapsed = 0;
private _killerGang = -1;
private _unit = objNull; // The player's body being watched
private _seen = false; // A body has been watched before (a new one means a respawn or reconnect)
private _wanted = false; // Wanted the last time they were alive and conscious
private _deadSince = -1;
private _tick = 0;
private _hijacks = 0;
private _lastHijack = -1e9;
waitUntil {
    sleep 3;
    _tick = _tick + 1;
    _elapsed = time - _started;
    // Crates in a destroyed vehicle are lost with it (ACE may leave them attached to the wreck)
    private _left = _crates select {
        !isNull _x && { alive _x } && {
            private _holder = attachedTo _x;
            isNull _holder || { alive _holder } || { _holder isKindOf "CAManBase" }
        }
    };

    // Pickup marker: gone once nothing is left waiting at the loading spot
    if ((markerShape _marker) isNotEqualTo "" && {
        (_left findIf { (_x distance2D _fromPos) < 50 && { !([_x] call _isLoaded) } }) isEqualTo -1
    }) then {
        deleteMarker _marker;
    };

    // The player's body: did it die? The killer arrives from their machine, a few seconds at most
    if (!isNull _unit && { !alive _unit }) then {
        if (_deadSince < 0) then { _deadSince = time };
        private _killer = _unit getVariable "OT_killedBy";
        if (!isNil "_killer" || { (time - _deadSince) > 6 }) then {
            if (isNil "_killer") then { _killer = objNull };
            missionNamespace setVariable [_deathVar, [_killer, _wanted]];
            _unit = objNull;
            _deadSince = -1;
        };
    };
    if (isNull _unit) then {
        private _new = (allPlayers select { (getPlayerUID _x) isEqualTo _uid && { alive _x } }) param [0, objNull];
        if (!isNull _new) then {
            // A new body: the job and the unload action come back to it
            if (_seen && { (_new getVariable ["OT_logisticsActive", ""]) isNotEqualTo _id }) then {
                _new setVariable ["OT_logisticsActive", _id, true];
                [_id, _toPos] remoteExec ["OT_fnc_logisticsUnloadAction", _new];
            };
            _unit = _new;
            _seen = true;
        };
    };
    if (!isNull _unit && { alive _unit } && { !(_unit getVariable ["ACE_isUnconscious", false]) }) then {
        _wanted = !(captive _unit);
    };

    // A death to judge (from the watch above, or the QA tests)
    private _deathResult = "";
    private _death = missionNamespace getVariable [_deathVar, []];
    if (_death isNotEqualTo []) then {
        missionNamespace setVariable [_deathVar, nil];
        _death params [["_killer", objNull], ["_wasWanted", false]];
        _deathResult = [_killer, _wasWanted] call OT_fnc_logisticsDeath;
        if (_deathResult isEqualTo "hijacked") then { _killerGang = _killer getVariable ["OT_gangid", -1] };
    };

    // Gangs: a try every 30 s while the player drives the loaded vehicle, away from both ends
    if ((_tick mod 10) isEqualTo 0 && { _hijacks < 2 } && { (time - _lastHijack) > 300 } && { !isNull _unit } && { alive _unit }) then {
        private _cargoVeh = vehicle _unit;
        if (_cargoVeh isNotEqualTo _unit
            && { (_left findIf { (attachedTo _x) isEqualTo _cargoVeh }) > -1 }
            && { (speed _cargoVeh) > 15 }
            && { (_cargoVeh distance2D _toPos) > 400 }
            && { (_cargoVeh distance2D _fromPos) > 400 }
        ) then {
            if (([_contract, _unit, _cargoVeh] call OT_fnc_logisticsHijack) isNotEqualTo []) then {
                _hijacks = _hijacks + 1;
                _lastHijack = time;
            };
        };
    };

    call {
        if (_left isEqualTo []) exitWith { _result = "lost" };
        if (_deathResult isNotEqualTo "") exitWith { _result = _deathResult };
        if (_elapsed >= (_timeLimit * 2)) exitWith { _result = "late" };
        if ((_left findIf { (_x distance2D _toPos) > 30 || { [_x] call _isLoaded } }) isEqualTo -1) exitWith {
            _result = "delivered";
            _delivered = count _left;
        };
    };
    _result isNotEqualTo ""
};

missionNamespace setVariable [_runningVar, nil];
missionNamespace setVariable [_deathVar, nil];
deleteMarker _marker;
// The player: their live body if there is one, else the body they had
private _players = allPlayers select { (getPlayerUID _x) isEqualTo _uid };
private _player = (_players select { alive _x }) param [0, _players param [0, objNull]];
{
    if ((_x getVariable ["OT_logisticsActive", ""]) isEqualTo _id) then {
        _x setVariable ["OT_logisticsActive", "", true];
    };
} forEach _players;

if (_result isEqualTo "delivered") then {
    // -10% per full 5 minutes late, for the crates that arrived
    private _late = floor (((_elapsed - _timeLimit) max 0) / 300);
    private _earned = round (_pay * (_delivered / _count) * ((1 - (_late * 0.1)) max 0));
    [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
    if (!isNull _player && { _earned > 0 }) then {
        [_earned, "Freight delivered"] remoteExec ["OT_fnc_money", _player, false];
    };
    if (_toName in OT_allTowns) then { [_toName, 1] call OT_fnc_support };
    if (!isNull _player) then {
        private _text = format ["Freight delivered to %1", _toName];
        if (_delivered < _count) then { _text = _text + format [" (%1 of %2 crates)", _delivered, _count] };
        if (_late > 0) then { _text = _text + format [", %1 minutes late", round ((_elapsed - _timeLimit) / 60)] };
        _text remoteExec ["OT_fnc_notifyGood", _player, false];
    };
} else {
    [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
    if (!isNull _player) then {
        private _gangName = "A gang";
        private _gang = OT_civilians getVariable [format ["gang%1", _killerGang], []];
        if ((count _gang) isEqualTo 9) then { _gangName = _gang select 8 };
        ((createHashMapFromArray [
            ["late", format ["Freight to %1 failed: far too late, the client found another hauler", _toName]],
            ["lost", format ["Freight to %1 failed: every crate was lost", _toName]],
            ["seized", format ["Freight to %1 failed: you were killed while wanted, %2 seized the cargo", _toName, OT_NATO_name]],
            ["hijacked", format ["Freight to %1 failed: %2 killed you and hijacked the cargo", _toName, _gangName]]
        ]) getOrDefault [_result, format ["Freight to %1 failed", _toName]]) remoteExec ["OT_fnc_notifyBad", _player, false];
    };
};

OT_haulLastResult = [_id, _result];
if (!isNil "OT_fnc_logisticsSettle") then { [_contract, _uid, _result] call OT_fnc_logisticsSettle };

// Crates still loaded go now (they're hidden): out of the vehicle's ACE cargo too, so the space
// comes back and ACE doesn't keep a deleted object listed. Seized or hijacked: every crate goes.
private _taken = _result in ["seized", "hijacked"];
{
    private _crate = _x;
    private _holder = attachedTo _crate;
    private _inCargo = !isNull _holder && { _crate in (_holder getVariable ["ace_cargo_loaded", []]) };
    if (_inCargo) then {
        private _loaded = _holder getVariable ["ace_cargo_loaded", []];
        _loaded deleteAt (_loaded find _crate);
        _holder setVariable ["ace_cargo_loaded", _loaded, true];
        _holder setVariable ["ace_cargo_space", (_holder getVariable ["ace_cargo_space", 0]) + 1, true];
    };
    if (_inCargo || _taken) then {
        detach _crate;
        deleteVehicle _crate;
    };
} forEach (_crates select { !isNull _x });

// The rental goes back to the broker as the job ends: no longer the player's, locked, anyone in it
// out, gone 20 seconds later (it isn't kept once the load is dropped off)
if (!isNull _veh && { alive _veh }) then {
    _veh setVariable ["owner", nil, true];
    [_veh, 2] remoteExec ["lock", _veh];
    { [_x] remoteExec ["moveOut", _x] } forEach (crew _veh);
    if (!isNull _player) then { "The broker takes the rental back" remoteExec ["OT_fnc_notifyMinor", _player, false] };
    [_veh] spawn {
        params ["_veh"];
        sleep 20;
        if (!isNull _veh) then {
            { [_x] remoteExec ["moveOut", _x] } forEach (crew _veh);
            sleep 1;
            deleteVehicle _veh;
        };
    };
};

// Leftover crates go once nobody is around to see it
[_crates] spawn {
    params ["_crates"];
    sleep 1; // Crates deleted above are only null from the next frame
    private _objects = _crates select { !isNull _x };
    while { _objects isNotEqualTo [] } do {
        {
            private _obj = _x;
            if ((allPlayers findIf { (_x distance2D _obj) < 300 }) isEqualTo -1) then {
                detach _obj;
                deleteVehicle _obj;
            };
        } forEach _objects;
        sleep 10;
        _objects = _objects select { !isNull _x };
    };
};
