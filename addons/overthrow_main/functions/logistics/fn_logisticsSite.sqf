/*
    Description:
    Puts up a freight broker's shed (server, every session, OT_fnc_initLogistics): a white industrial
    shed (Land_i_Shed_Ind_F) at the broker's site (OT_fnc_logisticsBrokers), trees and bushes on its
    footprint hidden, its small office furnished (desk with a laptop, chair, cabinets, water cooler)
    and its hall stocked (shelves, pallets, crates, a workbench, barrels), keeping the door at its west
    end and the middle of the hall clear. Positions are in the shed's own coordinates, from an in-game
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
_shed setPosATL [_origin select 0, _origin select 1, 0];
_shed allowDamage false;
_shed setVariable ["OT_brokerShed", _id, true];

private _floor = -1.36;
private _place = {
    params ["_cls", "_mx", "_my", "_turn", ["_onTop", 0]];
    if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith { objNull };
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

// The office: desk facing the door, the broker behind it (OT_fnc_spawnBroker)
[
    ["Land_TableDesk_F", -6.3, 0.3, 90],
    ["Land_OfficeChair_01_F", -8.2, -1.4, 200],
    ["Land_OfficeCabinet_01_F", -8.6, 2.0, 90],
    ["Land_OfficeCabinet_02_F", -5.0, -1.8, 180],
    ["Land_WaterCooler_01_new_F", -5.0, 2.2, 270],
    ["Land_FireExtinguisher_F", -4.8, -0.9, 270]
] apply { _x call _place };
// On the desk
["Land_Laptop_unfolded_F", -6.3, 0.0, 270, 0.79] call _place;
["Land_Printer_01_F", -6.3, 0.9, 270, 0.79] call _place;

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
