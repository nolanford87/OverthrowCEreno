/*
    Occupier template: NATO (Desert) (Western Sahara creator DLC).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    Its fighter jets are the vanilla NATO ones. Expeditionary Forces vehicles of desert NATO
    (M-ATV FSV / AT, RAH-66J) are used when that's loaded too.
    The police stay the map's own (Gendarmerie).
*/

private _have = { _this select { isClass (configFile >> "CfgVehicles" >> _x) } };

OT_NATO_name = "NATO";
OT_NATO_markerFlag = "flag_NATO";
OT_flag_NATO = "Flag_NATO_F";

OT_faction_NATO = "BLU_NATO_lxWS";
OT_fallback_faction_NATO = "BLU_F";

OT_NATO_HMG = "B_HMG_01_high_F";
OT_NATO_Vehicles_AirGarrison = [
    ["B_D_Heli_Light_01_dynamicLoadout_lxWS", 1],
    ["B_D_Heli_Light_01_lxWS", 3],
    ["B_D_Heli_Attack_01_dynamicLoadout_lxWS", 1],
    ["B_D_Heli_Transport_01_lxWS", 2],
    ["B_Heli_Transport_03_unarmed_F", 2]
];
OT_NATO_Vehicles_JetGarrison = [
    ["B_D_Plane_CAS_01_dynamicLoadout_lxWS", 1],
    ["B_Plane_Fighter_01_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["B_D_static_AA_lxWS", "B_D_static_AA_lxWS", "B_Radar_System_01_F", "B_SAM_System_03_F"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["B_HMG_01_high_F"];
OT_NATO_StaticGarrison_LevelTwo = ["B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_D_MRAP_01_hmg_lxWS"];
OT_NATO_StaticGarrison_LevelThree = ["B_D_static_AT_lxWS", "B_D_static_AA_lxWS", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_D_MRAP_01_hmg_lxWS", "B_D_MRAP_01_gmg_lxWS"];

OT_NATO_Unit_Sniper = "B_D_recon_M_lxWS";
OT_NATO_Unit_Spotter = "B_D_recon_lxWS";
OT_NATO_Unit_AA_spec = "B_D_soldier_AA_lxWS";
OT_NATO_Unit_AA_ass = "B_D_soldier_AAA_lxWS";
OT_NATO_Unit_HVT = "B_D_officer_lxWS";
OT_NATO_Unit_TeamLeader = "B_D_Soldier_TL_lxWS";
OT_NATO_Unit_SquadLeader = "B_D_Soldier_SL_lxWS";

OT_NATO_Vehicle_Quad = "B_D_Quadbike_01_lxWS";
OT_NATO_Vehicle_Transport = ["B_D_Truck_01_transport_lxWS", "B_D_Truck_01_covered_lxWS"];
OT_NATO_Vehicle_Transport_Light = "B_D_MRAP_01_lxWS";
OT_NATO_Vehicles_PoliceSupport = ["B_D_MRAP_01_hmg_lxWS", "B_D_MRAP_01_gmg_lxWS", "B_D_Heli_Light_01_dynamicLoadout_lxWS"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["B_D_Heli_Attack_01_dynamicLoadout_lxWS", "B_D_Heli_Attack_01_pylons_dynamicLoadout_lxWS", "EF_B_AH99J_NATO_Des"] call _have;
OT_NATO_Vehicles_AirSupport_Small = ["B_D_Heli_Light_01_dynamicLoadout_lxWS"];
OT_NATO_Vehicles_GroundSupport = ["B_D_MRAP_01_gmg_lxWS", "B_D_MRAP_01_hmg_lxWS", "EF_B_MRAP_01_FSV_NATO_Des", "EF_B_MRAP_01_AT_NATO_Des"] call _have;
OT_NATO_Vehicles_TankSupport = ["B_D_MBT_01_cannon_lxWS", "B_D_MBT_01_TUSK_lxWS"];
OT_NATO_Vehicles_Convoy = ["B_D_UGV_01_rcws_lxWS", "B_D_MRAP_01_hmg_lxWS", "B_D_MRAP_01_gmg_lxWS", "EF_B_MRAP_01_FSV_NATO_Des"] call _have;
OT_NATO_Vehicles_AirWingedSupport = ["B_D_Plane_CAS_01_dynamicLoadout_lxWS", "B_Plane_Fighter_01_F"];
OT_NATO_Vehicle_AirTransport_Small = "B_D_Heli_Light_01_lxWS";
OT_NATO_Vehicle_AirTransport = ["B_D_Heli_Transport_01_lxWS", "B_D_Heli_Transport_01_lxWS", "B_Heli_Transport_03_F"];
OT_NATO_Vehicle_AirTransport_Large = "B_Heli_Transport_03_F";
OT_NATO_Vehicle_Boat_Small = (["EF_B_CombatBoat_HMG_NATO_Des", "B_Boat_Armed_01_minigun_F"] call _have) select 0;
OT_NATO_Vehicles_APC = ["B_D_APC_Wheeled_01_cannon_lxWS", "B_D_APC_Tracked_01_rcws_lxWS"];
OT_NATO_Mortar = "B_D_Mortar_01_lxWS";
OT_NATO_Vehicle_HVT = "B_D_MRAP_01_lxWS";
OT_NATO_Vehicle_CTRGTransport = "B_D_Heli_Transport_01_lxWS";
OT_NATO_Vehicles_HQGarrison = ["B_D_APC_Tracked_01_aa_lxWS", "B_D_APC_Tracked_01_aa_lxWS", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F"];
