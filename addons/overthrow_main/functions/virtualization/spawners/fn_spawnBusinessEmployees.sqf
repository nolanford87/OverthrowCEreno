params ["_pos", "_name", "_spawnid"];

private _count = 0;
private _groups = [];

// A fishery is marked by a fisherman standing among his gear by the pier, owned or not
if (_name in OT_fisheries) then {
    private _spot = _pos findEmptyPosition [0, 25, "C_man_1"];
    if (_spot isEqualTo []) then { _spot = _pos };
    private _props = [];
    {
        _x params ["_cls", "_dist", "_dir", "_turn"];
        if !(isClass (configFile >> "CfgVehicles" >> _cls)) then { continue };
        private _p = _spot getPos [_dist, _dir];
        if (surfaceIsWater _p) then { continue };
        private _o = createVehicle [_cls, _p, [], 0, "CAN_COLLIDE"];
        _o setDir _turn;
        _o setVectorUp (surfaceNormal _p);
        _o enableSimulationGlobal false;
        _props pushBack _o;
    } forEach [
        ["Land_FishingGear_01_F", 3, 40, 120],
        ["Land_FishingGear_02_F", 3.5, 320, 200],
        ["Land_CrabCages_F", 4, 180, 30],
        ["Land_WoodenCrate_01_F", 2.5, 100, 15],
        ["Land_Basket_F", 2, 250, 0],
        ["Land_Bucket_painted_F", 1.5, 140, 0]
    ];
    private _fisherGroup = createGroup civilian;
    _fisherGroup setBehaviour "CARELESS";
    private _cls = ["C_man_1", "C_man_fisherman_01_F"] select (isClass (configFile >> "CfgVehicles" >> "C_man_fisherman_01_F"));
    private _fisherman = _fisherGroup createUnit [_cls, _spot, [], 0, "CAN_COLLIDE"];
    _fisherman setPosATL [_spot select 0, _spot select 1, 0];
    _fisherman setDir (random 360);
    _fisherman setVariable ["NOAI", true, false];
    _fisherman setVariable ["OT_fishery", _name, true];
    [_fisherman] call OT_fnc_idleAnim; // Stays put, idling
    _fisherGroup setVariable ["Vcm_Disable", true, true];
    spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _props + [_fisherGroup], false];
};

private _numCiv = server getVariable [format ["%1employ", _name], 0];
if (_numCiv isEqualTo 0) exitWith { [] };

private _group = createGroup independent;
_group setBehaviour "SAFE";
_groups pushBack _group;

while { _count < _numCiv } do {
    _pos = [[[_pos, 50]]] call BIS_fnc_randomPos;
    private _civ = _group createUnit [OT_civType_worker, _pos, [], 0, "NONE"];
    _civ setBehaviour "SAFE";
    private _identity = call OT_fnc_randomLocalIdentity;
    _identity set [1, ""]; // Retain original worker clothes
    [_civ, _identity] call OT_fnc_applyIdentity;
    _civ setVariable ["employee", _name, true];
    _count = _count + 1;
    sleep 0.3;
};
spawner setVariable [format ["employees%1", _name], _group, false];

private _dest = _pos getPos [random 100, random 360];
private _bdg = [_pos, ["Building"]] call OT_fnc_getRandomBuilding;
if !(_bdg isEqualType true) then { _dest = getPos (_bdg) };

private _wp = _group addWaypoint [_dest, 0];
private _start = _dest;
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "LIMITED";
_wp setWaypointCompletionRadius 40;
_wp setWaypointTimeout [0, 4, 8];

_dest = _pos getPos [random 100, random 360];
_bdg = [_start, ["Building"]] call OT_fnc_getRandomBuilding;
if !(_bdg isEqualType true) then { _dest = getPos (_bdg) };

_wp = _group addWaypoint [_dest, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "LIMITED";
_wp setWaypointCompletionRadius 10;
_wp setWaypointTimeout [20, 40, 80];

_wp = _group addWaypoint [_start, 0];
_wp setWaypointType "CYCLE";

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _groups, false];
