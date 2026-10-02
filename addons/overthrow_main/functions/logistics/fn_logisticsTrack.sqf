/*
    Description:
    Tracks a freight haul until it ends (server, spawned by OT_fnc_logisticsStart), every 3 seconds.

    Delivered: every crate of the job that still exists is within 30 m (2D) of the drop-off and on
    the ground - not attached to anything (ACE attaches a loaded crate to its vehicle, hidden, and
    carrying/dragging attaches it to the player) and not listed in a nearby vehicle's ACE cargo
    (ace_cargo_loaded). Pay: the contract's pay for the share of crates that made it, -10% per full
    5 minutes over the time limit; +1 support in the town it went to.
    Failed: every crate is lost (destroyed, or deleted with the vehicle carrying it), or twice the
    time limit has gone by. The player dying doesn't end a legal haul.
    Afterwards the rental goes back to the broker straight away (not the player's any more, locked,
    gone 20 seconds later) and leftover crates are deleted once no player is within 300 m.

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

private _result = "";
private _delivered = 0;
private _elapsed = 0;
waitUntil {
    sleep 3;
    _elapsed = time - _started;
    private _left = _crates select { !isNull _x && { alive _x } };

    // Pickup marker: gone once nothing is left waiting at the loading spot
    if ((markerShape _marker) isNotEqualTo "" && {
        (_left findIf { (_x distance2D _fromPos) < 50 && { !([_x] call _isLoaded) } }) isEqualTo -1
    }) then {
        deleteMarker _marker;
    };

    call {
        if (_left isEqualTo []) exitWith { _result = "lost" };
        if (_elapsed >= (_timeLimit * 2)) exitWith { _result = "late" };
        if ((_left findIf { (_x distance2D _toPos) > 30 || { [_x] call _isLoaded } }) isEqualTo -1) exitWith {
            _result = "delivered";
            _delivered = count _left;
        };
    };
    _result isNotEqualTo ""
};

deleteMarker _marker;
private _player = (allPlayers select { (getPlayerUID _x) isEqualTo _uid }) param [0, objNull];
if (!isNull _player && { (_player getVariable ["OT_logisticsActive", ""]) isEqualTo _id }) then {
    _player setVariable ["OT_logisticsActive", "", true];
};

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
        ([
            format ["Freight to %1 failed: far too late, the client found another hauler", _toName],
            format ["Freight to %1 failed: every crate was lost", _toName]
        ] select (_result isEqualTo "lost")) remoteExec ["OT_fnc_notifyBad", _player, false];
    };
};

// Crates still loaded go now (they're hidden): out of the vehicle's ACE cargo too, so the space
// comes back and ACE doesn't keep a deleted object listed
{
    private _crate = _x;
    private _holder = attachedTo _crate;
    if (!isNull _holder && { _crate in (_holder getVariable ["ace_cargo_loaded", []]) }) then {
        private _loaded = _holder getVariable ["ace_cargo_loaded", []];
        _loaded deleteAt (_loaded find _crate);
        _holder setVariable ["ace_cargo_loaded", _loaded, true];
        _holder setVariable ["ace_cargo_space", (_holder getVariable ["ace_cargo_space", 0]) + 1, true];
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
