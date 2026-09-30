if (!isServer) exitWith {};

params ["_town", "_spawnid"];

private _abandoned = server getVariable ["NATOabandoned", []];
private _stability = server getVariable format ["stability%1", _town];
if (_town in _abandoned) exitWith {};

private _groups = [];
private _numNATO = server getVariable format ["garrison%1", _town];
private _count = 0;
private _range = 350;

if (_town in OT_capitals) then {
    _range = 900;
};

//record the spawn ID for job tasks
spawner setVariable [format ["spawnid%1", _town], _spawnid];

while { _count < _numNATO } do {

    private _home = _town call OT_fnc_getRandomRoadPosition;
    private _pos = _home findEmptyPosition [2, 50];

    if (_pos isNotEqualTo []) then {

        private _group = createGroup blufor;
        _group setVariable ["VCM_TOUGHSQUAD", true, true];
        _group setVariable ["VCM_NORESCUE", true, true];
        _group deleteGroupWhenEmpty true;
        _groups pushBack _group;

        private _toSpawn = OT_NATO_Unit_PoliceCommander;
        if (_stability < 25) then { _toSpawn = OT_NATO_Unit_PoliceCommander_Heavy };
        private _civ = _group createUnit [_toSpawn, _home, [], 0, "NONE"];

        _civ setVariable ["garrison", _town, false];
        [_civ] joinSilent _group;
        _civ setRank "CORPORAL";
        _civ setBehaviour "SAFE";

        [_civ, _town] call OT_fnc_initGendarm;

        _toSpawn = OT_NATO_Unit_Police;
        if (_stability < 25) then { _toSpawn = OT_NATO_Unit_Police_Heavy };
        _civ = _group createUnit [_toSpawn, _pos, [], 0, "NONE"];
        _civ setVariable ["garrison", _town, false];
        [_civ] joinSilent _group;
        _civ setRank "PRIVATE";
        [_civ, _town] call OT_fnc_initGendarm;
        _civ setBehaviour "SAFE";
        if (_stability < 25) then {
            _toSpawn = OT_NATO_Unit_PoliceMedic_Heavy;
            _civ = _group createUnit [_toSpawn, _pos, [], 0, "NONE"];
            _civ setVariable ["garrison", _town, false];
            [_civ] joinSilent _group;
            _civ setRank "PRIVATE";
            [_civ, _town] call OT_fnc_initGendarm;
            _civ setBehaviour "SAFE";
        };

        sleep 0.5;
        _group call OT_fnc_initGendarmPatrol;
        _range = _range + 50;
        _count = _count + 2;

        {
            _x addCuratorEditableObjects [units _group, false];
        } forEach (allCurators);
    };
};

// Vehicles in the town's garrison (a FOB that took the town back left its vehicle), crewed, patrolling
// the town while a player is near. One still out there (driving over from the FOB) isn't spawned again
private _present = (vehicles select { alive _x && { (_x getVariable ["vehgarrison", ""]) isEqualTo _town } }) apply { typeOf _x };
private _townPos = server getVariable _town;
{
    private _index = _present find _x;
    if (_index > -1) then { _present deleteAt _index; continue };
    private _pos = (_town call OT_fnc_getRandomRoadPosition) findEmptyPosition [5, 80, _x];
    if (_pos isEqualTo []) then { continue };
    private _veh = createVehicle [_x, _pos, [], 0, "NONE"];
    _veh setDir (random 360);
    _veh setVariable ["vehgarrison", _town, true]; // Destroyed or stolen, it comes off the town's list
    private _vgroup = [_veh] call OT_fnc_createNATOCrew;
    { _x setVariable ["garrison", _town, false] } forEach (crew _veh);
    { _x addCuratorEditableObjects [[_veh], true] } forEach (allCurators);
    [_vgroup, _veh, _townPos] spawn OT_fnc_NATOvehiclePatrol;
    _groups pushBack _veh;
    _groups pushBack _vgroup;
    sleep 0.5;
} forEach (server getVariable [format ["vehgarrison%1", _town], []]);

spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _groups, false];
