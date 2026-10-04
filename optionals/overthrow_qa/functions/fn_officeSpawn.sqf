/*
    Description:
    Spawns a mayor's office building for the template review and tests: the main building and, for
    a multi-piece one (OT_fnc_officeParts), its other pieces where they stand on the map, facing a
    direction, with the ground floor (the lowest building position: the model's origin sits above
    it) on the ground. Server.

    Parameters:
        _this # 0: STRING - Template key (OT_fnc_officeTemplateKey), the class is "Land_" + key
        _this # 1: ARRAY - Position
        _this # 2: NUMBER - (Optional) Direction, default 0

    Usage: (["i_House_Big_01_V1_F", _pos, 137] call OTQA_fnc_officeSpawn) params ["_building", "_parts"];

    Returns: ARRAY - [building, [other pieces]], [objNull, []] when the class doesn't exist
*/

params ["_key", "_pos", ["_dir", 0]];

private _class = "Land_" + _key;
if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith { [objNull, []] };

private _b = createVehicle [_class, _pos, [], 0, "CAN_COLLIDE"];
_b setDir _dir;
_b setPosATL [_pos select 0, _pos select 1, 0];

// The ground floor on the ground
private _floors = (_b buildingPos -1) apply { (_b worldToModel _x) select 2 };
if (_floors isNotEqualTo []) then {
    private _floorATL = (_b modelToWorld [0, 0, selectMin _floors]) select 2;
    _b setPosATL [_pos select 0, _pos select 1, ((getPosATL _b) select 2) - _floorATL];
};

private _parts = [];
{
    _x params ["_partClass", "_offset", "_partDir"];
    if !(isClass (configFile >> "CfgVehicles" >> _partClass)) then { continue };
    private _o = createVehicle [_partClass, _pos, [], 0, "CAN_COLLIDE"];
    _o setDir (_dir + _partDir);
    _o setPosATL (_b modelToWorld _offset);
    _parts pushBack _o;
} forEach ([_key] call OT_fnc_officeParts);

[_b, _parts]
