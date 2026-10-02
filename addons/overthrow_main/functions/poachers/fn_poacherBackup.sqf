/*
    Description:
    The poachers' backup: an offroad with a mounted machine gun and a civilian car, every seat of both
    filled with poachers dressed as armed bandits (OT_fnc_poacherUnit), driving in from 600-900 m away
    (on a road if there is one) to where the patrol saw the player. The car's lot get out near there
    and search the area; the gun truck hunts around it. Base game vehicles only, whatever this install
    has. Their vehicles are free to take once they're dead.

    Parameters:
        _this # 0: NUMBER - Hunting spot index
        _this # 1: ARRAY - (Optional) Where they head (default: the middle of the spot)

    Usage: [_index, getPosATL _player] call OT_fnc_poacherBackup; (server)

    Returns: ARRAY - [groups, vehicles, units], [[], [], []] if there's no such spot
*/

params ["_index", ["_target", []]];

private _pos = (server getVariable ["huntingSpots", []]) param [_index, []];
if (!isServer || { _pos isEqualTo [] }) exitWith { [[], [], []] };
_pos = [_pos select 0, _pos select 1, 0];
if (_target isEqualTo []) then { _target = +_pos };

// Where from: 600-900 m from the spot, a road if one turns up, else open land
private _spot = [];
private _land = [];
for "_i" from 1 to 20 do {
    private _p = _pos getPos [600 + random 300, random 360];
    private _roads = (_p nearRoads 100) select { private _d = _x distance2D _pos; _d >= 620 && { _d <= 880 } };
    if (_roads isNotEqualTo []) exitWith { _spot = getPosATL (selectRandom _roads) };
    if (_land isEqualTo [] && { !surfaceIsWater _p }) then { _land = _p };
};
if (_spot isEqualTo []) then { _spot = _land };
if (_spot isEqualTo []) then { _spot = _pos getPos [750, random 360] };
_spot set [2, 0];
private _dir = _spot getDir _pos;

private _hmgs = ["O_G_Offroad_01_armed_F", "I_G_Offroad_01_armed_F", "B_G_Offroad_01_armed_F"] select { isClass (configFile >> "CfgVehicles" >> _x) };
private _cars = ["C_Offroad_01_F", "C_SUV_01_F", "C_Hatchback_01_F", "C_Hatchback_01_sport_F"] select { isClass (configFile >> "CfgVehicles" >> _x) };
private _types = [];
if (_hmgs isNotEqualTo []) then { _types pushBack (_hmgs select 0) };
if (_cars isNotEqualTo []) then { _types pushBack (selectRandom _cars) };

private _groups = [];
private _vehicles = [];
private _units = [];
{
    // The gun truck in front, the car 15 m behind it
    private _p = +_spot;
    if (_forEachIndex > 0) then {
        _p = (_spot getPos [15, _dir + 180]) findEmptyPosition [0, 40, _x];
        if (_p isEqualTo []) then { _p = _spot getPos [15, _dir + 180] };
    };
    private _veh = createVehicle [_x, _p, [], 0, "NONE"];
    _veh setDir _dir;
    _veh setVariable ["OT_poacherVeh", _index, true];
    _vehicles pushBack _veh;

    // Every seat taken
    private _group = createGroup [opfor, true];
    _group setVariable ["VCM_NORESCUE", true, true];
    _groups pushBack _group;
    for "_i" from 1 to (count (fullCrew [_veh, "", true])) do {
        private _unit = [_group, _p getPos [8, _dir + 90], _index, "bandit"] call OT_fnc_poacherUnit;
        if !(_unit moveInAny _veh) exitWith { deleteVehicle _unit };
        _units pushBack _unit;
    };
    _group addVehicle _veh;
    _group setBehaviour "AWARE";
    _group setCombatMode "RED";
    _group setSpeedMode "FULL";

    // In to where the player was: the car's lot get out short of it, the gun truck drives up
    private _short = _target getPos [[150, 100] select (_forEachIndex isEqualTo 0), _target getDir _spot];
    private _wp = _group addWaypoint [_short, 20];
    _wp setWaypointType (["GETOUT", "MOVE"] select (_forEachIndex isEqualTo 0));
    _wp = _group addWaypoint [_target, 50];
    _wp setWaypointType "SAD";
} forEach _types;

diag_log format ["Overthrow: poacher backup (%1, %2 men) sent to hunting spot %3 from %4 m", _vehicles apply { typeOf _x }, count _units, _index, round (_spot distance2D _pos)];
[_groups, _vehicles, _units]
