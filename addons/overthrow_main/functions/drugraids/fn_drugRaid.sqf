/*
    Description:
    The occupier raids a drug operation (chosen by OT_fnc_drugRaidCheck), the same way it
    counter-attacks a town (OT_fnc_NATOCounterTown).
    1. Warning: the players get a task and a map marker on the operation. With intelligence on its
       town (OT_fnc_NATOcounterIntel: a resistance radio tower within 4 km or support of 50) that's 10
       real minutes before the raiders move out, without it 2. It's called off (resources given back)
       if the resistance no longer owns the operation by then.
    2. Raid: once no other QRF is being fought, the raiders leave the occupier base nearest the
       operation (OT_fnc_NATOGetAttackVectors: by road within 5 km, otherwise flown in from the
       nearest airfield or helipad, otherwise from the HQ). The gendarmerie: 4 in a police car
       (OT_fnc_drugRaidPolice). The military: two squads in a truck or one by air
       (OT_fnc_NATOGroundForces), one dispatch more with over 2 players. The gendarmerie can't fly, a
       raid by air is the military's.
    3. The fight is a QRF fight at the operation (OT_fnc_NATOQRFfight). The occupier winning seizes
       every ganja, blow and precursor in its containers (OT_fnc_drugRaidSeize), shuts it for
       OT_drugRaidShutTime (its cycle does nothing meanwhile, OT_fnc_drugOpShut) and leaves it
       OT_drugRaidHeatAfterWin of its heat; the resistance holding it takes its heat to 0. Either way
       it's not raided again for OT_drugRaidCooldown.
    While it runs, OT_drugRaidState (a hashmap, not saved) says where it's at, for the QA tests.

    Parameters:
        _this # 0: STRING - Operation id
        _this # 1: STRING - "police" or "military"
        _this # 2: NUMBER - Strength (already paid for by the caller)
        _this # 3: NUMBER - Warning time in seconds, -1 (default) for the intelligence-based one
        _this # 4: HASHMAP - (Optional) Its state, made by the caller (OT_fnc_drugRaidCheck) so it's
            there straight away; a new one if not given

    Usage: [_opId, "police", 100] spawn OT_fnc_drugRaid;

    Returns: Nothing
*/

params ["_opId", "_forces", "_strength", ["_warning", -1], ["_state", createHashMap]];

private _ops = server getVariable ["drugOps", []];
private _op = _ops param [_ops findIf { (_x select 0) isEqualTo _opId }, []];
_op params ["", ["_type", ""], ["_pos", [0, 0, 0]], ["_town", ""]];
private _name = [_opId] call OT_fnc_drugOpBusiness;
private _intel = _town isNotEqualTo "" && { [_town] call OT_fnc_NATOcounterIntel };
if (_warning < 0) then { _warning = OT_drugRaidWarning select _intel };

_state merge [createHashMapFromArray [
    ["op", _opId], ["name", _name], ["type", _type], ["town", _town], ["forces", _forces], ["strength", _strength],
    ["intel", _intel], ["warning", _warning], ["attackAt", time + _warning], ["phase", "warning"],
    ["from", []], ["byAir", false], ["seized", [0, 0, 0]]
], true];
if !("cancel" in _state) then { _state set ["cancel", false] };
OT_drugRaidState = _state;
server setVariable ["drugRaidTarget", _opId, true];

// The warning: task and map marker
private _tskid = format ["drugraid%1%2", _opId, round (diag_tickTime * 1000)];
private _minutes = round (_warning / 60);
private _who = ["the gendarmerie", format ["%1 forces", OT_NATO_name]] select (_forces isEqualTo "military");
private _desc = if (_intel) then {
    format ["Resistance intelligence reports that %1 are about to raid %2. They move out in about %3 minutes.", _who, _name, _minutes]
} else {
    format ["%1 are about to raid %2. We only found out now, they move out in about %3 minutes.", _who, _name, _minutes]
};
_desc = _desc + format [" Defend it: if they win they seize everything in its containers and it's shut for %1 minutes. Hold them off and the heat on it is gone.", round (OT_drugRaidShutTime / 60)];
[independent, [_tskid], [_desc, format ["Defend %1", _name], _tskid], _pos, "CREATED", 1, true, "defend", true] call BIS_fnc_taskCreate;

private _area = createMarker [_tskid + "_area", _pos];
_area setMarkerShapeLocal "ELLIPSE";
_area setMarkerSizeLocal [150, 150];
_area setMarkerBrushLocal "FDiagonal";
_area setMarkerColor "ColorOPFOR";
private _label = createMarker [_tskid + "_label", _pos];
_label setMarkerTypeLocal "mil_warning";
_label setMarkerColorLocal "ColorOPFOR";
_label setMarkerText format ["Raid: %1", _name];
private _markers = [_area, _label];
_state set ["task", _tskid];
_state set ["markers", _markers];

if (_intel) then {
    format ["Resistance intelligence: %1 are about to raid %2, moving out in about %3 minutes", _who, _name, _minutes] remoteExec ["OT_fnc_notifyBad", 0, false];
} else {
    format ["%1 are about to raid %2, in about %3 minutes", _who, _name, _minutes] remoteExec ["OT_fnc_notifyBad", 0, false];
};
diag_log format ["Overthrow: %1 raid on %2 in %3 s (intel %4, %5, strength %6)", OT_NATO_name, _name, _warning, _intel, _forces, _strength];

// Called off: the resources come back
private _cancel = {
    params ["_reason"];
    { deleteMarker _x } forEach _markers;
    [_tskid, "CANCELED", true] call BIS_fnc_taskSetState;
    server setVariable ["NATOresources", (server getVariable ["NATOresources", 0]) + _strength];
    server setVariable ["drugRaidTarget", "", true];
    _state set ["phase", "cancelled"];
    diag_log format ["Overthrow: %1 raid on %2 called off (%3)", OT_NATO_name, _name, _reason];
};
private _isOn = { [_opId] call OT_fnc_drugOpOwned };

waitUntil { sleep 1; time >= (_state get "attackAt") || { _state get "cancel" } || { !(call _isOn) } };
if ((_state get "cancel") || { !(call _isOn) }) exitWith { ["no longer needed"] call _cancel };

// One QRF fight at a time
waitUntil { sleep 2; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { _state get "cancel" } };
if ((_state get "cancel") || { !(call _isOn) }) exitWith { ["no longer needed"] call _cancel };

// Where from: the nearest base by road, else flown in from the nearest airfield / helipad, else the HQ
([_pos] call OT_fnc_NATOGetAttackVectors) params ["_ground", "_air"];
private _from = [];
private _byAir = false;
call {
    if (_ground isNotEqualTo []) exitWith { _from = _ground select 0 };
    _byAir = true;
    if (_air isNotEqualTo []) exitWith { _from = _air select 0 };
    if !(OT_NATO_HQ in (server getVariable ["NATOabandoned", []])) then { _from = [OT_NATO_HQPos, OT_NATO_HQ] };
};
if (_from isEqualTo []) exitWith {
    format ["%1 has no base left to raid %2 from", OT_NATO_name, _name] remoteExec ["OT_fnc_notifyGood", 0, false];
    ["no base"] call _cancel;
};
_from params ["_obpos", "_obname"];
if (_byAir && { _forces isEqualTo "police" }) then { _forces = "military" }; // The gendarmerie doesn't fly
_who = ["The gendarmerie", format ["%1 forces", OT_NATO_name]] select (_forces isEqualTo "military");

server setVariable ["NATOattacking", _name, true];
server setVariable ["NATOattackstart", time, true];
_state set ["phase", "attack"];
_state set ["from", [_obpos, _obname]];
_state set ["byAir", _byAir];
_state set ["forces", _forces];
format ["%1 are moving on %2 from %3", _who, _name, _obname] remoteExec ["OT_fnc_notifyBad", 0, false];

// The raiders
spawner setVariable ["NATOattackforce", [], false];
private _left = _strength;
if (_forces isEqualTo "police") then {
    [_obpos, _pos, _town] spawn OT_fnc_drugRaidPolice;
    _left = _left - (OT_drugRaidStrength get "police");
} else {
    private _dispatches = 1;
    if (count (allPlayers - (entities "HeadlessClient_F")) > 2) then { _dispatches = 2 };
    for "_i" from 0 to (_dispatches - 1) do {
        private _ao = [_pos, _pos getDir _obpos] call OT_fnc_getAO;
        [_obpos, _ao, _pos, _byAir, _i * 60] spawn OT_fnc_NATOGroundForces;
        _left = _left - 200;
    };
};
diag_log format ["Overthrow: %1 raid on %2: %3 from %4 (by air %5)", OT_NATO_name, _name, _forces, _obname, _byAir];

private _success = {
    params ["_tskid", "_opId", "_name", "_markers", "_state"];
    // The occupier has raided it: stock seized, shut for a while, most of the heat off
    { deleteMarker _x } forEach _markers;
    [_tskid, "FAILED", true] spawn BIS_fnc_taskSetState;
    private _seized = [_opId] call OT_fnc_drugRaidSeize;
    private _heat = ([_opId] call OT_fnc_drugHeatGet) select 0;
    [_opId, _heat * OT_drugRaidHeatAfterWin, OT_drugRaidShutTime, OT_drugRaidCooldown] call OT_fnc_drugHeatSet;
    _state set ["seized", _seized];
    _seized params ["_ganja", "_blow", "_precursors"];
    format ["%1 has raided %2: %3 ganja, %4 blow and %5 precursors seized, it's shut for %6 minutes", OT_NATO_name, _name, _ganja, _blow, _precursors, round (OT_drugRaidShutTime / 60)] remoteExec ["OT_fnc_notifyBad", 0, false];
    diag_log format ["Overthrow: %1 raided %2, seized %3", OT_NATO_name, _name, _seized];
};

private _fail = {
    params ["_tskid", "_opId", "_name", "_markers"];
    // The resistance has held it: the heat is gone
    { deleteMarker _x } forEach _markers;
    [_tskid, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
    [_opId, 0, -1, OT_drugRaidCooldown] call OT_fnc_drugHeatSet;
    format ["The resistance has held %1 against the raid, the heat on it is gone", _name] remoteExec ["OT_fnc_notifyGood", 0, false];
};

private _won = [_pos, _left max 0, _success, _fail, [_tskid, _opId, _name, _markers, _state], _town] call OT_fnc_NATOQRFfight;

server setVariable ["drugRaidTarget", "", true];
_state set ["won", _won];
_state set ["phase", "done"];
