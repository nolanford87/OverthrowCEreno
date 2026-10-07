/*
    Description:
    An occupier compound's garrison at work (tools/officegen/garrison_gen.py placed it; the user's spec):
    - its losses first: a guard killed stays lost (server variable "compoundlost<town>": [lost, since]) until the
      occupier pays to replace him, one every 10 minutes for 10 resources each; the guards still lost aren't made;
    - always aware (never safe: relaxed men walk through pieces on roads), weapons free when they see a threat;
      the posts hold where they stand, the patrol ("patrol" guards, a group of their own) walks a loop just
      inside the compound's walls;
    - flashlights rather than night vision, on after dark;
    - in a fight the posts hold and the patrol goes after the nearest threat it knows of, but never out of the
      walls (to the nearest point of its loop instead); a minute after the last contact it walks its loop again;
      at the first contact the town's gendarmerie comes to the compound's main gate from the street (15 m out:
      the gate doesn't open for it, a man can't plan a way to a place behind a shut gate); a patrol man found
      outside the walls is sent straight back to his loop. The first contact also sounds the alarm: a siren from
      the HQ for 90 s (missionNamespace "OT_compoundSiren<town>" while it sounds).
    Runs while any guard lives. Server, from OT_fnc_spawnOffice.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: ARRAY - The guards made (OT_fnc_officeApplyLayout)

    Usage: _guards = [_town, _guards] call OT_fnc_officeGarrison;

    Returns: ARRAY - The guards kept (the ones still lost taken off)
*/

params [["_town", "", [""]], ["_guards", [], [[]]]];

private _lostVar = format ["compoundlost%1", _town];
(server getVariable [_lostVar, [0, 0]]) params ["_lost", "_since"];
if (_since > time) then { _since = time }; // A game loaded again starts its clock anew
// The occupier pays for the replacements due since
if (_lost > 0) then {
    private _resources = server getVariable ["NATOresources", 2000];
    private _due = (floor ((time - _since) / 600)) min _lost min (floor (_resources / 10));
    if (_due > 0) then {
        server setVariable ["NATOresources", _resources - 10 * _due];
        _lost = _lost - _due;
        _since = _since + 600 * _due;
    };
    server setVariable [_lostVar, [_lost, _since]];
};
// The ones still lost: patrol men first, then posts at random (not a static's gunner)
if (_lost > 0) then {
    private _order = (_guards select { "patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]) })
        + ((_guards select { !("patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []])) && { isNull objectParent _x } }) call BIS_fnc_arrayShuffle);
    private _gone = _order select [0, _lost min (count _order)];
    { deleteVehicle _x } forEach _gone;
    _guards = _guards - _gone;
};
if (_guards isEqualTo []) exitWith { [] };

private _patrol = _guards select { "patrol" in (((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]) };
private _posts = _guards - _patrol;
{
    private _unit = _x;
    _unit setVariable ["OT_compoundGuard", _town];
    // Flashlights, not night vision
    private _nvg = hmd _unit;
    if (_nvg isNotEqualTo "") then { _unit unlinkItem _nvg };
    if (primaryWeapon _unit isNotEqualTo "" && { ((primaryWeaponItems _unit) select 1) isEqualTo "" }) then { _unit addPrimaryWeaponItem "acc_flashlight" };
    _unit addEventHandler ["Killed", {
        params ["_unit"];
        private _town = _unit getVariable ["OT_compoundGuard", ""];
        private _var = format ["compoundlost%1", _town];
        (server getVariable [_var, [0, 0]]) params ["_lost", "_since"];
        server setVariable [_var, [_lost + 1, [_since, time] select (_lost isEqualTo 0)]];
    }];
} forEach _guards;
{
    _x setBehaviour "AWARE";
    _x setCombatMode "YELLOW";
} forEach ((_guards apply { group _x }) arrayIntersect (_guards apply { group _x }));
{ _x disableAI "PATH" } forEach _posts; // Posts hold where they stand (they still turn, crouch and fire)

// The patrol's loop: every 8 m along the walls, 3.5 m in, where nothing stands (a line down meets the ground
// first: the compounds' corners are towers and houses, which the path finding can't reach)
private _area = ([_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeCompound) apply { [_x select 0, _x select 1, 0] };
private _loop = [];
private _n = count _area;
for "_i" from 0 to _n - 1 do {
    private _a = _area select _i;
    private _edge = (_area select ((_i + 1) mod _n)) vectorDiff _a;
    private _len = vectorMagnitude _edge;
    if (_len < 2) then { continue };
    private _u = vectorNormalized _edge;
    private _in = [-(_u select 1), _u select 0, 0];
    if !((_a vectorAdd (_u vectorMultiply (_len / 2)) vectorAdd _in) inPolygon _area) then { _in = _in vectorMultiply -1 };
    for "_t" from 2 to _len - 2 step 8 do {
        private _p = _a vectorAdd (_u vectorMultiply _t) vectorAdd (_in vectorMultiply 3.5);
        private _top = (AGLToASL _p) vectorAdd [0, 0, 8];
        private _hit = lineIntersectsSurfaces [_top, _top vectorAdd [0, 0, -10], objNull, objNull, true, 1, "GEOM", "NONE"];
        if ((_hit isEqualTo [] || { isNull ((_hit select 0) select 2) }) && { _p inPolygon _area }) then { _loop pushBack _p };
    };
};
private _walk = {
    params ["_group", "_loop"];
    { deleteWaypoint _x } forEach ((waypoints _group) select { (_x select 1) > 0 });
    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "AWARE";
    } forEach _loop;
    if (_loop isNotEqualTo []) then { (_group addWaypoint [_loop select 0, 0]) setWaypointType "CYCLE" };
};
private _patrolGroup = group (_patrol param [0, objNull]);
// The patrol's moves are this function's (inside the walls only), not an AI mod's flanking (LAMBS)
// and no attack orders of its own (the engine's "ATTACK" takes a man out over a wall the path finding keeps to:
// it still fires at what it sees)
if (!isNull _patrolGroup) then {
    _patrolGroup setVariable ["lambs_danger_disableGroupAI", true, true];
    { _x disableAI "TARGET" } forEach _patrol;
};
if (!isNull _patrolGroup && { count _loop > 1 }) then {
    { _x enableAI "PATH"; _x doFollow (leader _patrolGroup) } forEach _patrol; // Off the post OT_fnc_officeGuard holds them at
    [_patrolGroup, _loop] call _walk;
};

[_town, _guards, _patrolGroup, _loop, _walk] spawn {
    params ["_town", "_guards", "_patrolGroup", "_loop", "_walk"];
    private _alerted = false;
    private _lastContact = -1e9;
    private _hunting = false;
    while { sleep 5; ({ alive _x } count _guards) > 0 } do {
        private _alive = _guards select { alive _x };
        private _groups = (_alive apply { group _x }) arrayIntersect (_alive apply { group _x });
        // Lights after dark
        { _x enableGunLights (["Auto", "ForceOn"] select (sunOrMoon < 0.5)) } forEach _groups;
        private _contact = (_alive findIf { (behaviour _x) isEqualTo "COMBAT" }) > -1;
        if (_contact) then { _lastContact = time };
        // The first contact brings the town's gendarmerie over and crews the compound's parked armed car (it stays
        // where it's parked, a gun on the approach)
        if (_contact && { !_alerted }) then {
            _alerted = true;
            // The siren from the HQ, 90 s
            private _siren = ["Sound_Alarm", "Sound_Alarm2"] select { isClass (configFile >> "CfgVehicles" >> _x) };
            if (_siren isNotEqualTo []) then {
                private _source = createSoundSource [_siren select 0, ASLToAGL ((([_town] call OT_fnc_officeLayout) select 0) select 1), [], 0];
                missionNamespace setVariable [format ["OT_compoundSiren%1", _town], _source];
                [{ deleteVehicle _this }, _source, 90] call CBA_fnc_waitAndExecute;
            };
            {
                private _veh = _x;
                createVehicleCrew _veh;
                { _x setVariable ["OT_compoundGuard", _town]; _x disableAI "PATH" } forEach crew _veh;
                (group effectiveCommander _veh) setBehaviour "COMBAT";
            } forEach (vehicles select {
                alive _x && { (crew _x) isEqualTo [] }
                    && { (((_x getVariable ["OT_officeItem", []]) param [0, ""]) isEqualTo _town) }
                    && { ((((_x getVariable ["OT_officeItem", []]) param [3, []]) param [0, ""]) isEqualTo "vehicle") }
            });
            // Outside the main gate (the town's gate nearest the HQ), 15 m out from the compound's middle
            private _hq = ASLToAGL ((([_town] call OT_fnc_officeLayout) select 0) select 1);
            private _gates = ((missionNamespace getVariable ["OT_officeGates", []]) select { !isNull _x && { (((_x getVariable ["OT_officeItem", []]) param [0, ""]) isEqualTo _town) } });
            private _at = getPosATL (_alive select 0);
            if (_gates isNotEqualTo []) then {
                private _gate = ([_gates, [], { _x distance2D _hq }, "ASCEND"] call BIS_fnc_sortBy) select 0;
                _at = (getPosATL _gate) vectorAdd ((vectorNormalized ((getPosATL _gate) vectorDiff _hq)) vectorMultiply 15);
            };
            private _gendarmes = allUnits select { alive _x && { (_x getVariable ["garrison", ""]) isEqualTo _town } };
            {
                private _g = _x;
                { deleteWaypoint _x } forEach ((waypoints _g) select { (_x select 1) > 0 });
                private _wp = _g addWaypoint [_at, 5];
                _wp setWaypointType "SAD";
                _wp setWaypointBehaviour "AWARE";
                _wp setWaypointSpeed "FULL";
            } forEach ((_gendarmes apply { group _x }) arrayIntersect (_gendarmes apply { group _x }));
        };
        // The patrol hunts the nearest threat it knows of, inside the walls only; one outside straight back in
        private _leader = leader _patrolGroup;
        private _area = ([_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeCompound) apply { [_x select 0, _x select 1, 0] };
        if (_area isNotEqualTo [] && { count _loop > 1 }) then {
            { if (alive _x && { [getPosATL _x, _area] call OT_fnc_officeOutside }) then { private _m = _x; _m doMove (([_loop, [], { _x distance2D _m }, "ASCEND"] call BIS_fnc_sortBy) select 0) } } forEach (units _patrolGroup);
        };
        if (!isNull _patrolGroup && { alive _leader } && { count _loop > 1 }) then {
            private _threats = (_leader targets [true, 300]) select { alive _x };
            if (_threats isNotEqualTo []) then {
                private _t = [_threats, [], { _leader distance _x }, "ASCEND"] call BIS_fnc_sortBy;
                private _seen = _leader getHideFrom (_t select 0);
                private _go = if (_seen inPolygon _area) then { _seen } else { ([_loop, [], { _x distance2D _seen }, "ASCEND"] call BIS_fnc_sortBy) select 0 };
                { deleteWaypoint _x } forEach ((waypoints _patrolGroup) select { (_x select 1) > 0 });
                { _x doMove _go } forEach (units _patrolGroup);
                _hunting = true;
            } else {
                if (_hunting && { time > _lastContact + 60 }) then {
                    _hunting = false;
                    { _x doFollow _leader } forEach (units _patrolGroup);
                    [_patrolGroup, _loop] call _walk;
                };
            };
        };
    };
};
_guards
