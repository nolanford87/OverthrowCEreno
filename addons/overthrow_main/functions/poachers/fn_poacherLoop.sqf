/*
    Description:
    Poachers, every 2 seconds on the server (OT_fnc_initPoachers):
    - a hunting spot whose heat is full (OT_fnc_poacherHeat, within half a shot of OT_poacherFull)
      with a player in it gets a patrol, day or night (OT_fnc_poacherPatrol)
    - a patrol that knows about a player in its spot (or within 50 m of it) calls for backup
      (OT_fnc_poacherCall); the radio chatter goes on until the call goes through, 5-10 s later, and
      the backup comes (OT_fnc_poacherBackup), the spot's heat topped up to full so they stay a while
    - once the poachers know about a player (after the call), that player loses their cover within 300
      m of them, so they shoot
    - every poacher in a spot dead: the call (if any) is cut off, the spot's heat goes back to nothing
      and they're done (OT_fnc_poacherEnd); no new patrol comes there for OT_poacherQuietTime (15 real
      minutes), however hot it gets
    - a spot that has cooled to nothing: the poachers leave (OT_fnc_poacherEnd), unless they're
      still on the radio
    - what's left of finished poachers (OT_poacherCleanup) is deleted once no player is within 500 m
      of it, except a vehicle a player is in or has claimed

    Usage: [OT_fnc_poacherLoop, 2] call CBA_fnc_addPerFrameHandler; (server)
*/

if (isNil "OT_poacherEvents") exitWith {};
private _players = (allPlayers - entities "HeadlessClient_F") select { alive _x };
private _spots = server getVariable ["huntingSpots", []];

// Full spots with a player hunting in them get a patrol
{
    private _index = _x;
    private _pos = _spots param [_index, []];
    if (_pos isEqualTo [] || { _index in OT_poacherEvents }) then { continue };
    if (time < (OT_poacherQuiet getOrDefault [_index, 0])) then { continue }; // Wiped out lately: quiet for a while
    if (([_index] call OT_fnc_poacherHeat) < (OT_poacherFull - 0.5)) then { continue };
    if ((_players findIf { (_x distance2D _pos) < 200 }) isEqualTo -1) then { continue };
    [_index] call OT_fnc_poacherPatrol;
} forEach (keys OT_poacherHeat);

// The poachers out there
{
    private _index = _x;
    private _ev = OT_poacherEvents get _index;
    private _pos = _spots param [_index, _ev get "from"];
    private _patrol = (_ev get "patrol") select { alive _x };
    private _backup = (_ev get "backup") select { alive _x };
    private _alive = _patrol + _backup;
    private _state = _ev get "state";
    private _near = _players select { (_x distance2D _pos) < 1000 };

    // All dead: the spot is quiet again
    if (_alive isEqualTo []) then {
        if (_near isNotEqualTo []) then {
            ([
                "The poachers are dead: the hunting ground will be quiet for a while",
                "The poachers are dead before their call went through: no backup is coming, and the hunting ground will be quiet for a while"
            ] select (_state isEqualTo "calling")) remoteExec ["OT_fnc_notifyGood", _near, false];
        };
        [_index, 0, true] call OT_fnc_poacherHeat;
        OT_poacherQuiet set [_index, time + OT_poacherQuietTime];
        [_index] call OT_fnc_poacherEnd;
        continue;
    };

    // The patrol sees a player in the spot: a call for backup
    if (_state isEqualTo "patrol") then {
        private _seen = _players select {
            private _p = _x;
            (_p distance2D _pos) < 250
                && { (_patrol findIf { (_x distance _p) < 500 && { (_x knowsAbout (vehicle _p)) >= 1.5 } }) > -1 }
        };
        if (_seen isNotEqualTo []) then {
            [_index, _seen select 0] call OT_fnc_poacherCall;
            _state = _ev get "state";
        };
    };

    // On the radio: chatter until the call goes through, then the backup
    if (_state isEqualTo "calling") then {
        if (time >= (_ev get "callEnd")) then {
            ([_index, _ev get "target"] call OT_fnc_poacherBackup) params ["_groups", "_vehicles", "_units"];
            _ev set ["backup", (_ev get "backup") + _units];
            _ev set ["groups", (_ev get "groups") + _groups];
            _ev set ["vehicles", (_ev get "vehicles") + _vehicles];
            _ev set ["state", "backup"];
            [_index, OT_poacherFull] call OT_fnc_poacherHeat;
            if (_near isNotEqualTo []) then {
                "The poachers' backup is on its way: an armed pickup and a car full of them" remoteExec ["OT_fnc_notifyBad", _near, false];
            };
        } else {
            if (time >= (_ev get "nextSound")) then {
                private _speaker = _patrol select 0;
                playSound3D [selectRandom OT_poacherCallSounds, _speaker, false, getPosASL _speaker, 3, 1, 400];
                _ev set ["nextSound", time + 2.5];
            };
        };
    };

    // After the call: anyone they know about nearby is fair game
    if (_state isNotEqualTo "patrol") then {
        {
            private _p = _x;
            private _veh = vehicle _p;
            if (captive _p && { (_alive findIf { (_x distance _p) < 300 && { (_x knowsAbout _veh) >= 1.5 } }) > -1 }) then {
                { if (captive _x) then { [_x, false] remoteExec ["setCaptive", _x] } } forEach ([_p] + ((crew _veh) - [_p]));
            };
        } forEach _near;
    };

    // Cooled: they leave
    if ((_ev get "state") isNotEqualTo "calling" && { ([_index] call OT_fnc_poacherHeat) <= 0 }) then {
        [_index] call OT_fnc_poacherEnd;
    };
} forEach (keys OT_poacherEvents);

// What's left of them, once nobody is near
private _keep = [];
{
    _x params ["_objects", "_groups"];
    private _left = [];
    {
        private _o = _x;
        if (isNull _o) then { continue };
        if ((_players findIf { (_x distance2D _o) < 500 }) > -1) then { _left pushBack _o; continue };
        if (_o isKindOf "CAManBase") then {
            if (isNull objectParent _o) then { deleteVehicle _o } else { (objectParent _o) deleteVehicleCrew _o };
        } else {
            // Not a vehicle a player is in or has claimed (that one is theirs now)
            if (((crew _o) findIf { isPlayer _x }) isEqualTo -1 && { !(_o call OT_fnc_hasOwner) }) then {
                { _o deleteVehicleCrew _x } forEach ((crew _o) select { !isPlayer _x });
                deleteVehicle _o;
            };
        };
    } forEach _objects;
    if (_left isEqualTo []) then {
        { if (!isNull _x && { (units _x) isEqualTo [] }) then { deleteGroup _x } } forEach _groups;
    } else {
        _keep pushBack [_left, _groups];
    };
} forEach OT_poacherCleanup;
OT_poacherCleanup = _keep;
