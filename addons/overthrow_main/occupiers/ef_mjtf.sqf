/*
    Occupier template: MJTF (Marine Joint Task Force, Expeditionary Forces creator DLC).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The MJTF has no fixed-wing aircraft (other than drones) or light helicopters of its own: the
    vanilla NATO Black Wasp, Wipeout and Pawnee stand in.
    The police stay the map's own (Gendarmerie).

    Parameters:
        _this # 0: STRING - Camo: "Des" (desert) or "Wdl" (woodland)
*/

params [["_camo", "Des"]];
private _c = { format [_this, _camo] }; // "EF_B_X_MJTF_%1" -> the camo's class

OT_NATO_name = "MJTF";
OT_NATO_markerFlag = "EF_flag_29thMEU";
OT_flag_NATO = "EF_Flag_29thMEU";

OT_faction_NATO = "EF_B_MJTF_" + _camo;
OT_fallback_faction_NATO = "BLU_F";

OT_NATO_HMG = "EF_B_HMG_01_high_MJTF_%1" call _c;
OT_NATO_Vehicles_AirGarrison = [
    ["EF_B_Heli_Transport_01_MJTF_%1" call _c, 2],
    ["EF_B_Heli_Transport_01_pylons_MJTF_%1" call _c, 1],
    ["EF_B_Heli_Attack_01_dynamicLoadout_MJTF_%1" call _c, 1],
    ["EF_B_AH99J_MJTF_%1" call _c, 1],
    ["B_Heli_Light_01_F", 2]
];
OT_NATO_Vehicles_JetGarrison = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 1],
    ["B_Plane_Fighter_01_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["EF_B_Static_AA_MJTF_%1" call _c, "EF_B_Static_AA_MJTF_%1" call _c, "B_Radar_System_01_F", "B_SAM_System_03_F"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["EF_B_HMG_01_high_MJTF_%1" call _c];
OT_NATO_StaticGarrison_LevelTwo = ["EF_B_HMG_01_high_MJTF_%1" call _c, "EF_B_HMG_01_high_MJTF_%1" call _c, "EF_B_GMG_01_high_MJTF_%1" call _c, "EF_B_MRAP_01_hmg_MJTF_%1" call _c];
OT_NATO_StaticGarrison_LevelThree = ["EF_B_Static_AT_MJTF_%1" call _c, "EF_B_Static_AA_MJTF_%1" call _c, "EF_B_HMG_01_high_MJTF_%1" call _c, "EF_B_HMG_01_high_MJTF_%1" call _c, "EF_B_GMG_01_high_MJTF_%1" call _c, "EF_B_MRAP_01_hmg_MJTF_%1" call _c, "EF_B_MRAP_01_gmg_MJTF_%1" call _c];

OT_NATO_Unit_Sniper = "EF_B_Marine_Recon_M_%1" call _c;
OT_NATO_Unit_Spotter = "EF_B_Marine_Recon_%1" call _c;
OT_NATO_Unit_AA_spec = "EF_B_Marine_AA_%1" call _c;
OT_NATO_Unit_AA_ass = "EF_B_Marine_AAA_%1" call _c;
OT_NATO_Unit_HVT = "EF_B_Marine_Officer_%1" call _c;
OT_NATO_Unit_TeamLeader = "EF_B_Marine_TL_%1" call _c;
OT_NATO_Unit_SquadLeader = "EF_B_Marine_SL_%1" call _c;

OT_NATO_Vehicle_Quad = "EF_B_Quadbike_01_MJTF_%1" call _c;
OT_NATO_Vehicle_Transport = ["EF_B_Truck_01_transport_MJTF_%1" call _c, "EF_B_Truck_01_covered_MJTF_%1" call _c];
OT_NATO_Vehicle_Transport_Light = "EF_B_MRAP_01_MJTF_%1" call _c;
OT_NATO_Vehicles_PoliceSupport = ["EF_B_MRAP_01_hmg_MJTF_%1" call _c, "EF_B_MRAP_01_gmg_MJTF_%1" call _c, "EF_B_Pickup_mmg_MJTF_%1" call _c, "B_Heli_Light_01_dynamicLoadout_F"];
OT_NATO_Vehicles_ReconDrone = "EF_B_UAV_01_MJTF_%1" call _c;
OT_NATO_Vehicles_CASDrone = "EF_B_UAV_02_dynamicLoadout_MJTF_%1" call _c;
OT_NATO_Vehicles_AirSupport = ["EF_B_Heli_Attack_01_dynamicLoadout_MJTF_%1" call _c, "EF_B_AH99J_MJTF_%1" call _c];
OT_NATO_Vehicles_AirSupport_Small = ["B_Heli_Light_01_dynamicLoadout_F", "EF_B_Heli_Transport_01_pylons_MJTF_%1" call _c];
OT_NATO_Vehicles_GroundSupport = ["EF_B_MRAP_01_gmg_MJTF_%1" call _c, "EF_B_MRAP_01_hmg_MJTF_%1" call _c, "EF_B_MRAP_01_FSV_MJTF_%1" call _c, "EF_B_MRAP_01_AT_MJTF_%1" call _c, "EF_B_Pickup_mmg_MJTF_%1" call _c];
OT_NATO_Vehicles_TankSupport = ["EF_B_MBT_01_cannon_MJTF_%1" call _c, "EF_B_MBT_01_TUSK_MJTF_%1" call _c];
OT_NATO_Vehicles_Convoy = ["EF_B_UGV_01_rcws_MJTF_%1" call _c, "EF_B_MRAP_01_hmg_MJTF_%1" call _c, "EF_B_MRAP_01_FSV_MJTF_%1" call _c, "EF_B_Pickup_mmg_MJTF_%1" call _c];
OT_NATO_Vehicles_AirWingedSupport = ["B_Plane_Fighter_01_F", "B_Plane_CAS_01_dynamicLoadout_F"];
OT_NATO_Vehicle_AirTransport_Small = "B_Heli_Light_01_F";
OT_NATO_Vehicle_AirTransport = ["EF_B_Heli_Transport_01_MJTF_%1" call _c, "EF_B_Heli_Transport_01_MJTF_%1" call _c, "B_Heli_Light_01_F"];
OT_NATO_Vehicle_AirTransport_Large = "EF_B_Heli_Transport_01_MJTF_%1" call _c;
OT_NATO_Vehicle_Boat_Small = "EF_B_CombatBoat_HMG_MJTF_%1" call _c;
OT_NATO_Vehicles_APC = ["EF_B_AAV9_MJTF_%1" call _c, "EF_B_AAV9_50mm_MJTF_%1" call _c];
OT_NATO_Mortar = "EF_B_Mortar_01_MJTF_%1" call _c;
OT_NATO_Vehicle_HVT = "EF_B_MRAP_01_MJTF_%1" call _c;
OT_NATO_Vehicle_CTRGTransport = "EF_B_Heli_Transport_01_MJTF_%1" call _c;
OT_NATO_Vehicles_HQGarrison = ["EF_B_MRAP_01_LAAD_MJTF_%1" call _c, "EF_B_MRAP_01_LAAD_MJTF_%1" call _c, "EF_B_GMG_01_high_MJTF_%1" call _c, "EF_B_GMG_01_high_MJTF_%1" call _c, "EF_B_GMG_01_high_MJTF_%1" call _c, "EF_B_HMG_01_high_MJTF_%1" call _c, "EF_B_HMG_01_high_MJTF_%1" call _c, "EF_B_HMG_01_high_MJTF_%1" call _c];
