/*
    Description:
    The occupier counter-attacks a town the resistance holds (chosen by OT_fnc_NATOcounterTowns).
    1. Warning: the players get a task and a map marker naming the town. With intelligence
       (OT_fnc_NATOcounterIntel) that's 10 real minutes before the occupier moves out, without it 2.
       It's called off (resources given back) if the town is no longer the resistance's by then.
    2. Attack: once no other QRF is being fought, ground forces leave the occupier base nearest the
       town (OT_fnc_NATOGetAttackVectors: by road within 5 km, otherwise flown in from the nearest
       airfield or helipad, otherwise from the HQ). Each squad dispatch (OT_fnc_NATOGroundForces: two
       squads in a truck, one by air) costs 200 of the strength: 1 dispatch, 2 from 600 strength, 3
       from 1000, one more with over 2 players; a support vehicle (100) by road from 800.
    3. The fight is a QRF fight for the town (OT_fnc_NATOQRFfight). The occupier winning takes the
       town back (OT_fnc_NATOretakeTown): its resistance police are removed, its stability goes back
       to 100 (fully the occupier's, as after a FOB takeover) and resistance support there drops by half (25 at least). The resistance winning
       keeps it, with an hour's grace from counter-attacks (OT_fnc_NATOtownGrace).
    While it runs, OT_counterTownState (a hashmap, not saved) says where it's at, for the QA tests.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Strength (already paid for by the caller)
        _this # 2: NUMBER - Warning time in seconds, -1 (default) for the intelligence-based one
        _this # 3: HASHMAP - (Optional) Its state, made by the caller (OT_fnc_NATOcounterTowns) so it's
            there straight away; a new one if not given

    Usage: [_town, _strength] spawn OT_fnc_NATOCounterTown;

    Returns: Nothing
*/

params ["_town", "_strength", ["_warning", -1], ["_state", createHashMap]];

private _posTown = server getVariable [_town, [0, 0, 0]];
private _intel = [_town] call OT_fnc_NATOcounterIntel;
if (_warning < 0) then { _warning = [120, 600] select _intel };

_state merge [createHashMapFromArray [
    ["town", _town], ["strength", _strength], ["intel", _intel], ["warning", _warning],
    ["attackAt", time + _warning], ["phase", "warning"], ["from", []], ["byAir", false]
], true];
if !("cancel" in _state) then { _state set ["cancel", false] };
OT_counterTownState = _state;
server setVariable ["NATOcounterTarget", _town, true];

// The warning: task and map marker
private _tskid = format ["retake%1%2", _town, round (diag_tickTime * 1000)];
private _minutes = round (_warning / 60);
private _desc = if (_intel) then {
    format ["Resistance intelligence reports that %1 is preparing to take %2 back. Its forces move out in about %3 minutes.", OT_NATO_name, _town, _minutes]
} else {
    format ["%1 forces are about to move on %2. We only found out now, they move out in about %3 minutes.", OT_NATO_name, _town, _minutes]
};
_desc = _desc + " Hold the town: if they win it, its police are lost and it goes back to them.";
[independent, [_tskid], [_desc, format ["Hold %1", _town], _tskid], _posTown, "CREATED", 1, true, "defend", true] call BIS_fnc_taskCreate;

private _area = createMarker [_tskid + "_area", _posTown];
_area setMarkerShapeLocal "ELLIPSE";
_area setMarkerSizeLocal [300, 300];
_area setMarkerBrushLocal "FDiagonal";
_area setMarkerColor "ColorOPFOR";
private _label = createMarker [_tskid + "_label", _posTown];
_label setMarkerTypeLocal "mil_warning";
_label setMarkerColorLocal "ColorOPFOR";
_label setMarkerText format ["Counter-attack: %1", _town];
private _markers = [_area, _label];
_state set ["task", _tskid];
_state set ["markers", _markers];

if (_intel) then {
    format ["Resistance intelligence: %1 is preparing to take %2 back, moving out in about %3 minutes", OT_NATO_name, _town, _minutes] remoteExec ["OT_fnc_notifyBad", 0, false];
} else {
    format ["%1 forces are about to move on %2, in about %3 minutes", OT_NATO_name, _town, _minutes] remoteExec ["OT_fnc_notifyBad", 0, false];
};
diag_log format ["Overthrow: %1 counter-attack on %2 in %3 s (intel %4, strength %5)", OT_NATO_name, _town, _warning, _intel, _strength];

// Called off: the resources come back
private _cancel = {
    params ["_reason"];
    { deleteMarker _x } forEach _markers;
    [_tskid, "CANCELED", true] call BIS_fnc_taskSetState;
    server setVariable ["NATOresources", (server getVariable ["NATOresources", 0]) + _strength];
    server setVariable ["NATOcounterTarget", "", true];
    _state set ["phase", "cancelled"];
    diag_log format ["Overthrow: %1 counter-attack on %2 called off (%3)", OT_NATO_name, _town, _reason];
};
private _isHeld = { _town in (server getVariable ["NATOabandoned", []]) };

waitUntil { sleep 1; time >= (_state get "attackAt") || { _state get "cancel" } || { !(call _isHeld) } };
if ((_state get "cancel") || { !(call _isHeld) }) exitWith { ["no longer needed"] call _cancel };

// One QRF fight at a time
waitUntil { sleep 2; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { _state get "cancel" } };
if ((_state get "cancel") || { !(call _isHeld) }) exitWith { ["no longer needed"] call _cancel };

// Where from: the nearest base by road, else flown in from the nearest airfield / helipad, else the HQ
([_posTown] call OT_fnc_NATOGetAttackVectors) params ["_ground", "_air"];
private _from = [];
private _byAir = false;
call {
    if (_ground isNotEqualTo []) exitWith { _from = _ground select 0 };
    _byAir = true;
    if (_air isNotEqualTo []) exitWith { _from = _air select 0 };
    if !(OT_NATO_HQ in (server getVariable ["NATOabandoned", []])) then { _from = [OT_NATO_HQPos, OT_NATO_HQ] };
};
if (_from isEqualTo []) exitWith {
    format ["%1 has no base left to counter-attack %2 from", OT_NATO_name, _town] remoteExec ["OT_fnc_notifyGood", 0, false];
    ["no base"] call _cancel;
};
_from params ["_obpos", "_obname"];

server setVariable ["NATOattacking", _town, true];
server setVariable ["NATOattackstart", time, true];
_state set ["phase", "attack"];
_state set ["from", [_obpos, _obname]];
_state set ["byAir", _byAir];
format ["%1 forces are moving on %2 from %3", OT_NATO_name, _town, _obname] remoteExec ["OT_fnc_notifyBad", 0, false];

// The forces
spawner setVariable ["NATOattackforce", [], false];
private _dispatches = 1;
if (_strength >= 600) then { _dispatches = 2 };
if (_strength >= 1000) then { _dispatches = 3 };
if (count (allPlayers - (entities "HeadlessClient_F")) > 2) then { _dispatches = _dispatches + 1 };
private _left = _strength;
for "_i" from 0 to (_dispatches - 1) do {
    private _ao = [_posTown, _posTown getDir _obpos] call OT_fnc_getAO;
    [_obpos, _ao, _posTown, _byAir, _i * 60] spawn OT_fnc_NATOGroundForces;
    _left = _left - 200;
};
if (!_byAir && { _strength >= 800 }) then {
    [_obpos, _posTown, 100, 30] spawn OT_fnc_NATOGroundSupport;
    _left = _left - 100;
};
diag_log format ["Overthrow: %1 counter-attack on %2: %3 dispatches from %4 (by air %5)", OT_NATO_name, _town, _dispatches, _obname, _byAir];

private _success = {
    params ["_tskid", "_town", "_markers"];
    // The occupier has won the town back
    { deleteMarker _x } forEach _markers;
    [_tskid, "FAILED", true] spawn BIS_fnc_taskSetState;
    private _support = server getVariable [format ["rep%1", _town], 0];
    [_town, 100, 25 max (round (_support * 0.5))] call OT_fnc_NATOretakeTown;
    format ["%1 has taken %2 back, its police are gone", OT_NATO_name, _town] remoteExec ["OT_fnc_notifyBad", 0, false];
};

private _fail = {
    params ["_tskid", "_town", "_markers"];
    // The resistance has held the town
    { deleteMarker _x } forEach _markers;
    [_tskid, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
    ["set", _town, 3600] call OT_fnc_NATOtownGrace;
    format ["The resistance has held %1 against %2", _town, OT_NATO_name] remoteExec ["OT_fnc_notifyGood", 0, false];
};

private _won = [_posTown, _left max 0, _success, _fail, [_tskid, _town, _markers], _town] call OT_fnc_NATOQRFfight;

server setVariable ["NATOcounterTarget", "", true];
_state set ["won", _won];
_state set ["phase", "done"];
