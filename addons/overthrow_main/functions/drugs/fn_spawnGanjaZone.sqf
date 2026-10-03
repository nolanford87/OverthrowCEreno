/*
    Description:
    Spawner for a wild ganja zone (OT_fnc_registerSpawner): its plants, as many as are left, within
    30 m of the middle. Simple objects of a vanilla shrub (OT_ganjaPlantModels), sat on the ground.
    Kept per zone (OT_ganjaZonePlants) and sent to every machine for the harvest action.

    Parameters:
        _this # 0: NUMBER - Zone id
        _this # 1: STRING - Spawn id

    Usage: (spawner)
*/

params ["_id", "_spawnid"];

private _zone = (server getVariable ["ganjaZones", []]) param [(server getVariable ["ganjaZones", []]) findIf { (_x select 0) isEqualTo _id }, []];
if (_zone isEqualTo []) exitWith {};
_zone params ["", "_pos", "_left"];

private _plants = [];
for "_i" from 1 to _left do {
    private _p = _pos getPos [3 + random 27, random 360];
    if (surfaceIsWater _p) then { _p = _pos getPos [random 5, random 360] };
    _p = [_p select 0, _p select 1, 0];
    private _plant = objNull;
    if (OT_ganjaPlantModels isNotEqualTo []) then {
        private _ground = AGLToASL _p;
        _plant = createSimpleObject [selectRandom OT_ganjaPlantModels, _ground];
        _plant setDir (random 360);
        // Its lowest point on the ground, a little sunk in
        private _bottom = ((boundingBoxReal _plant) select 0) select 2;
        _plant setPosWorld [_ground select 0, _ground select 1, (_ground select 2) - _bottom - 0.1];
    } else {
        _plant = createVehicle [OT_ganjaPlantFallback, _p, [], 0, "CAN_COLLIDE"];
        _plant setDir (random 360);
        _plant enableSimulationGlobal false;
    };
    _plants pushBack _plant;
};

OT_ganjaZonePlants set [_id, (OT_ganjaZonePlants getOrDefault [_id, []]) + _plants];
call OT_fnc_ganjaPublishPlants;
spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + _plants, false];
