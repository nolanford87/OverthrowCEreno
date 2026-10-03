/*
    Description:
    Puts up a drug lab (server, every session, OT_fnc_initDrugLabs): a run-down industrial shed
    (OT_drugLabShed, the freight brokers' shed's grimy twin, OT_fnc_logisticsSite) at the lab's site
    (OT_fnc_drugLabSites), trees and bushes on its footprint hidden, its hall fitted out as a cook's
    lab (camping tables with gas bottles, buckets and bottles, drums and canisters, a generator) and a
    mattress in its office. Nothing goes within 2 m of a door. The lab's container
    (OT_fnc_drugLabContainer) stands off the shed's east end.

    Parameters:
        _this: ARRAY - Lab site [id, name, position, shed position, shed direction, road position]

    Usage: _site call OT_fnc_drugLabSite;

    Returns: OBJECT - The shed
*/

params ["_id", "_name", "_middle", "_origin", "_dir"];

{ _x hideObjectGlobal true } forEach (nearestTerrainObjects [_middle, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "FENCE", "WALL", "HIDE"], 18, false]);

private _shed = createVehicle [OT_drugLabShed, _origin, [], 0, "CAN_COLLIDE"];
_shed setDir _dir;
// Raised 0.5 m to 1 m so the floor never sits below the ground (as OT_fnc_logisticsSite)
private _ground = [[-9, -2.3], [16.5, -2.3], [-9, 9], [16.5, 9], [3.75, 3.35]] apply {
    getTerrainHeightASL [(_origin select 0) + ((_x select 0) * cos _dir) + ((_x select 1) * sin _dir), (_origin select 1) - ((_x select 0) * sin _dir) + ((_x select 1) * cos _dir)]
};
private _lift = (((selectMax _ground) - (getTerrainHeightASL _origin)) + 0.5) max 0.5 min 1;
_shed setPosATL [_origin select 0, _origin select 1, _lift];
_shed allowDamage false;
_shed setVariable ["OT_drugLab", _id, true];

private _floor = -1.36;
private _doors = [];
for "_i" from 1 to (getNumber ((configOf _shed) >> "numberOfDoors")) do {
    private _p = _shed selectionPosition [format ["Door_%1_trigger", _i], "Memory"];
    if (_p isNotEqualTo [0, 0, 0]) then { _doors pushBack [_p select 0, _p select 1] };
};

private _place = {
    params ["_cls", "_mx", "_my", "_turn", ["_onTop", 0]];
    if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith { objNull };
    if ((_doors findIf { (_x distance2D [_mx, _my]) < 2 }) > -1) exitWith { objNull };
    private _o = createVehicle [_cls, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _o allowDamage false;
    _o setDir (_dir + _turn);
    private _bottom = ((boundingBoxReal _o) select 0) select 2;
    private _p = _shed modelToWorldWorld [_mx, _my, _floor + _onTop];
    _o setPosWorld [_p select 0, _p select 1, (_p select 2) - _bottom];
    _o enableSimulationGlobal false;
    _o
};
// A table with things on it
private _table = {
    params ["_mx", "_my", "_turn", "_onIt"];
    private _t = ["Land_CampingTable_F", _mx, _my, _turn] call _place;
    if (isNull _t) exitWith {};
    (boundingBoxReal _t) params ["_min", "_max"];
    private _h = (_max select 2) - (_min select 2);
    { [_x select 0, _mx + (_x select 1), _my + (_x select 2), _x select 3, _h] call _place } forEach _onIt;
};

// The cook's benches along the north wall
[1.5, 7.9, 0, [["Land_GasTank_01_blue_F", -0.5, 0, 0], ["Land_Bucket_clean_F", 0.4, 0.1, 0]]] call _table;
[4.5, 7.9, 0, [["Land_BottlePlastic_V1_F", -0.6, 0, 0], ["Land_BottlePlastic_V1_F", -0.4, 0.1, 0], ["Land_Camping_Light_F", 0.3, 0, 0]]] call _table;
[7.5, 7.9, 0, [["Land_PlasticCase_01_small_F", -0.3, 0, 0], ["Land_GasTank_01_yellow_F", 0.5, 0, 0]]] call _table;
[
    ["Land_Portable_generator_F", -2.6, 8.2, 0],
    ["Land_FireExtinguisher_F", -3.5, 8.5, 0],
    ["Land_GasTank_01_blue_F", 10.0, 8.4, 0],
    ["Land_CanisterPlastic_F", 11.0, 8.2, 30],
    ["Land_CanisterFuel_F", 11.6, 8.4, 0],
    ["Land_BarrelEmpty_grey_F", 13.0, 8.2, 0],
    ["Land_MetalBarrel_F", 14.2, 8.1, 0],
    ["Land_MetalBarrel_F", 15.3, 7.4, 0],
    ["Land_BarrelTrash_grey_F", 15.4, 6.2, 0],
    ["Land_Workbench_01_F", 15.6, 3.0, 270],
    ["Land_Sacks_heap_F", 14.8, 0.2, 0],
    ["Land_PaperBox_closed_F", 12.5, -1.3, 0],
    ["Land_Pallet_F", 9.8, -1.4, 0],
    ["Land_PlasticBucket_01_closed_F", 6.0, 6.5, 0],
    ["Land_PlasticBucket_01_open_F", 6.6, 6.7, 0],
    ["Land_GarbageBags_F", 3.0, -1.2, 0],
    // The office: where the cook sleeps
    ["Land_Sleeping_bag_F", -6.5, 1.5, 90],
    ["Land_CampingChair_V2_F", -5.4, -1.4, 200]
] apply { _x call _place };

_shed;
