/*
    Description:
    Hunting, every 5 seconds on the server (livestock every 20):
    - a player who walks into a hunting spot reveals it to everyone, for good (saved, "huntingRevealed")
    - livestock at farms near players: goats, sheep and hens around farm buildings (barns, cowsheds,
      chicken coops, stone sheds) outside towns within 700 m of a player, 2-4 per farm, the 3 nearest farms per
      player. They go once no player is within 1 km. Killing one outside a hunting spot costs the
      nearest town 1 resistance support (OT_fnc_farmAnimalKilled).

    Usage: [OT_fnc_huntingLoop, 5] call CBA_fnc_addPerFrameHandler; (server)
*/

private _players = (allPlayers - entities "HeadlessClient_F") select { alive _x };

// Revealing spots
private _revealed = server getVariable ["huntingRevealed", []];
{
    private _player = _x;
    if (!isNull objectParent _player && { (objectParent _player) isKindOf "Air" }) then { continue };
    private _index = _player call OT_fnc_inHuntingSpot;
    if (_index > -1 && { !(_index in _revealed) }) then {
        _revealed pushBack _index;
        server setVariable ["huntingRevealed", _revealed, true];
        [_index] call OT_fnc_huntingRevealMarker;
        "You found a hunting ground, it's on the map" remoteExec ["OT_fnc_notifyMinor", _player, false];
    };
} forEach _players;

// Livestock at farms, every 20 seconds (looking for farm buildings is the slow part)
OT_huntLoopTick = (missionNamespace getVariable ["OT_huntLoopTick", 0]) + 1;
if ((OT_huntLoopTick % 4) isNotEqualTo 0) exitWith {};
if (isNil "OT_farms") then { OT_farms = createHashMap };
private _farmWords = ["barn", "cowshed", "chickencoop", "stone_shed", "farm", "pigsty", "haystack"];
{
    private _player = _x;
    if (!isNull objectParent _player) then { continue };
    private _farms = (nearestObjects [_player, ["House"], 700]) select {
        private _type = toLowerANSI (typeOf _x);
        (_farmWords findIf { _x in _type }) > -1 && { !([getPosATL _x] call OT_fnc_isInTown) }
    };
    // The 3 nearest, at least 60 m apart (a farm has several buildings)
    private _picked = [];
    {
        private _b = _x;
        if (count _picked >= 3) exitWith {};
        if ((_picked findIf { (_x distance2D _b) < 60 }) isEqualTo -1) then { _picked pushBack _b };
    } forEach _farms;
    {
        private _key = format ["farm%1", (getPosATL _x) apply { round _x }];
        private _farm = OT_farms getOrDefault [_key, []];
        if (_farm isNotEqualTo []) then { continue };
        private _count = [_key, 0, [2, 4]] call OT_fnc_huntingAvailable;
        private _animals = [];
        for "_i" from 1 to _count do {
            private _cls = selectRandomWeighted ["Goat_random_F", 0.35, "Sheep_random_F", 0.35, "Hen_random_F", 0.2, "Cock_random_F", 0.1];
            private _p = (_x getPos [10 + random 25, random 360]) findEmptyPosition [0, 20, _cls];
            if (_p isEqualTo [] || { surfaceIsWater _p }) then { continue };
            private _animal = createAgent [_cls, _p, [], 0, "NONE"];
            _animal setDir (random 360);
            _animal setVariable ["OT_huntKey", _key];
            _animal setVariable ["OT_livestock", true, true];
            _animal addEventHandler ["Killed", { _this call OT_fnc_farmAnimalKilled }];
            _animals pushBack _animal;
        };
        OT_farms set [_key, [getPosATL _x, _animals]];
    } forEach _picked;
} forEach _players;

// Farms nobody is near any more: their animals (and carcasses) go
{
    _y params ["_pos", "_animals"];
    if ((_players findIf { (_x distance2D _pos) < 1000 }) isEqualTo -1) then {
        { if (!isNull _x) then { deleteVehicle _x } } forEach _animals;
        OT_farms deleteAt _x;
    };
} forEach (+OT_farms);
