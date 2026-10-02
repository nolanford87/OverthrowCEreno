/*
    Description:
    Puts up a freight broker's shed (server, every session, OT_fnc_initLogistics): a white industrial
    shed (Land_i_Shed_Ind_F) at the broker's site (OT_fnc_logisticsBrokers), trees and bushes on its
    footprint hidden, its small office furnished (desk with a laptop, cabinets, water cooler, printer)
    and its hall stocked (shelves, pallets, crates, a workbench, barrels). Nothing goes within 2 m of a
    door (its "Door_N_trigger" points), and the way from the office door to the broker stays clear. Positions are in the shed's own coordinates, from an in-game
    probe of its floor plan (OTQA_fnc_probeBuilding): office x -9 to -4.5, y -2.3 to 2.6; hall the
    rest, x -9 to 16.5, y -2.3 to 9; floor 1.36 m below its centre.

    Parameters:
        _this: ARRAY - Broker [id, name, stand, loading spot, shed position, shed direction, road direction]

    Usage: _broker call OT_fnc_logisticsSite;

    Returns: OBJECT - The shed
*/

params ["_id", "", "", "", "_origin", "_dir"];

// Trees, bushes and rocks on its footprint
private _middle = [(_origin select 0) + (3.75 * cos _dir) + (3.35 * sin _dir), (_origin select 1) - (3.75 * sin _dir) + (3.35 * cos _dir), 0];
{ _x hideObjectGlobal true } forEach (nearestTerrainObjects [_middle, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "FENCE", "WALL", "HIDE"], 18, false]);

private _shed = createVehicle ["Land_i_Shed_Ind_F", _origin, [], 0, "CAN_COLLIDE"];
_shed setDir _dir;
// Raised 0.5 m to 1 m so the floor never sits below the ground: 0.5 m over the highest point under it
private _ground = [[-9, -2.3], [16.5, -2.3], [-9, 9], [16.5, 9], [3.75, 3.35]] apply {
    getTerrainHeightASL [(_origin select 0) + ((_x select 0) * cos _dir) + ((_x select 1) * sin _dir), (_origin select 1) - ((_x select 0) * sin _dir) + ((_x select 1) * cos _dir)]
};
private _lift = (((selectMax _ground) - (getTerrainHeightASL _origin)) + 0.5) max 0.5 min 1;
_shed setPosATL [_origin select 0, _origin select 1, _lift];
_shed allowDamage false;
_shed setVariable ["OT_brokerShed", _id, true];

private _floor = -1.36;
private _stand = [-7.4, 0.3]; // Where the broker stands (OT_fnc_spawnBroker)

// Its doors (memory points "Door_N_trigger"), in its own coordinates: nothing goes within 2 m of one
private _doors = [];
for "_i" from 1 to (getNumber ((configOf _shed) >> "numberOfDoors")) do {
    private _p = _shed selectionPosition [format ["Door_%1_trigger", _i], "Memory"];
    if (_p isNotEqualTo [0, 0, 0]) then { _doors pushBack [_p select 0, _p select 1] };
};
diag_log format ["Overthrow: freight broker shed %1 doors (own coordinates): %2", _id, _doors apply { _x apply { (round (_x * 10)) / 10 } }];
// The office's doors (within 4 m of the broker: the outside one in the south wall, the one to the
// hall in the north): a clear lane from each to him (the hall door if none found)
private _officeDoors = _doors select { (_x distance2D _stand) < 4 };
if (_officeDoors isEqualTo []) then { _officeDoors = [[-8.3, 2.5]] };
private _laneDist = {
    params ["_p"];
    // Distance from _p to the nearest segment broker -> office door
    selectMin (_officeDoors apply {
        private _a = _stand; private _b = _x;
        private _ab = [(_b select 0) - (_a select 0), (_b select 1) - (_a select 1)];
        private _len2 = ((_ab select 0) ^ 2) + ((_ab select 1) ^ 2);
        private _t = if (_len2 > 0) then { (((((_p select 0) - (_a select 0)) * (_ab select 0)) + (((_p select 1) - (_a select 1)) * (_ab select 1))) / _len2) max 0 min 1 } else { 0 };
        [_p select 0, _p select 1] distance2D [(_a select 0) + (_t * (_ab select 0)), (_a select 1) + (_t * (_ab select 1))]
    })
};
private _inTheWay = {
    params ["_mx", "_my", ["_lane", 0]];
    ((_doors findIf { (_x distance2D [_mx, _my]) < 2 }) > -1) || { _lane > 0 && { ([[_mx, _my]] call _laneDist) < _lane } }
};

private _place = {
    params ["_cls", "_mx", "_my", "_turn", ["_onTop", 0], ["_lane", 0]];
    if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith { objNull };
    if ([_mx, _my, _lane] call _inTheWay) exitWith { objNull }; // Keeps doors and the way to the broker clear
    private _o = createVehicle [_cls, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _o allowDamage false;
    _o setDir (_dir + _turn);
    // Standing on the floor (or on a table): its own bottom at that height
    private _bottom = ((boundingBoxReal _o) select 0) select 2;
    private _p = _shed modelToWorldWorld [_mx, _my, _floor + _onTop];
    _o setPosWorld [_p select 0, _p select 1, (_p select 2) - _bottom];
    _o enableSimulationGlobal false;
    _o
};

// The office: the desk in front of the broker (he faces east, both doors are behind him to the west),
// cabinets, a water cooler and a printer along the east side, away from the doors and the ways in
["Land_TableDesk_F", -6.2, 0.3, 90, 0, 1] call _place;
["Land_Laptop_unfolded_F", -6.2, 0.0, 270, 0.79, 1] call _place;
private _lowCabinet = ["Land_OfficeCabinet_02_F", -5.0, -1.8, 180, 0, 1.2] call _place;
if (!isNull _lowCabinet) then {
    // The printer on top of it
    (boundingBoxReal _lowCabinet) params ["_min", "_max"];
    ["Land_Printer_01_F", -5.0, -1.8, 180, (_max select 2) - (_min select 2), 1.2] call _place;
};
[
    ["Land_OfficeCabinet_01_F", -4.9, 1.2, 270, 0, 1.2],
    ["Land_WaterCooler_01_new_F", -5.6, 2.2, 180, 0, 1.2],
    ["Land_FireExtinguisher_F", -4.9, -0.6, 270, 0, 1.2]
] apply { _x call _place };

// The hall: along the north wall and the east end, the middle and the west door clear
[
    ["Land_ShelvesMetal_F", -1.5, 8.2, 0],
    ["Land_ShelvesMetal_F", 1.5, 8.2, 0],
    ["Land_ShelvesMetal_F", 9.5, 8.2, 0],
    ["Land_ShelvesMetal_F", 12.5, 8.2, 0],
    ["Land_Pallets_stack_F", 15.2, 7.6, 0],
    ["Land_Pallets_stack_F", 15.2, 5.6, 90],
    ["Land_Workbench_01_F", 15.6, 2.4, 270],
    ["Land_ToolTrolley_02_F", 14.6, 0.6, 30],
    ["Land_CratesWooden_F", 13.0, -1.2, 0],
    ["Land_WoodenCrate_01_stack_x3_F", 10.5, -1.3, 90],
    ["Land_PaperBox_closed_F", 8.0, -1.3, 0],
    ["Land_PaperBox_open_full_F", 6.8, 7.8, 20],
    ["Land_PalletTrolley_01_yellow_F", 4.5, 0.0, 60],
    ["Land_Pallet_F", 2.5, -1.4, 0],
    ["Land_BarrelEmpty_F", -3.6, 8.2, 0],
    ["Land_BarrelWater_F", -2.8, 8.3, 0],
    ["Land_Tyres_F", 15.4, -0.8, 0]
] apply { _x call _place };

_shed;
