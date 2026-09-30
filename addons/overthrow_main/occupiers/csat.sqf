/*
    Occupier template: CSAT (base game, Apex for Pacific).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The police stay the map's own (Gendarmerie).

    Parameters:
        _this # 0: STRING - Camo: "arid" or "pacific"
*/

params [["_camo", "arid"]];

OT_NATO_name = "CSAT";
OT_NATO_markerFlag = "flag_CSAT";
OT_flag_NATO = "Flag_CSAT_F";

OT_faction_NATO = "OPF_F";
OT_fallback_faction_NATO = "OPF_T_F"; // If there were no vehicles in the first faction, take them from this faction

// Aircraft and statics are the same for both camos (Pacific CSAT has none of its own)
OT_NATO_HMG = "O_HMG_01_high_F";
OT_NATO_Vehicles_AirGarrison = [
    ["O_Heli_Light_02_dynamicLoadout_F", 1],
    ["O_Heli_Transport_04_covered_F", 2],
    ["O_Heli_Light_02_unarmed_F", 3],
    ["O_Heli_Attack_02_dynamicLoadout_F", 1],
    ["O_Heli_Transport_04_bench_F", 2]
];
OT_NATO_Vehicles_JetGarrison = [
    ["O_Plane_CAS_02_dynamicLoadout_F", 1],
    ["O_Plane_Fighter_02_F", 1],
    ["O_Plane_Fighter_02_Stealth_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["O_static_AA_F", "O_static_AA_F", "O_Radar_System_02_F", "O_SAM_System_04_F"]; //Added to every airfield
OT_NATO_StaticGarrison_LevelOne = ["O_HMG_01_high_F"];

OT_NATO_Unit_HVT = "O_officer_F";
OT_NATO_Vehicles_ReconDrone = "O_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "O_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["O_Heli_Attack_02_dynamicLoadout_F"];
OT_NATO_Vehicles_AirSupport_Small = ["O_Heli_Light_02_dynamicLoadout_F"];
OT_NATO_Vehicles_AirWingedSupport = ["O_Plane_Fighter_02_F"];
OT_NATO_Vehicle_AirTransport_Small = "O_Heli_Light_02_unarmed_F";
OT_NATO_Vehicle_AirTransport = ["O_Heli_Transport_04_bench_F", "O_Heli_Transport_04_covered_F", "O_Heli_Light_02_unarmed_F"];
OT_NATO_Vehicle_AirTransport_Large = "O_Heli_Transport_04_covered_F";
OT_NATO_Vehicle_CTRGTransport = "O_Heli_Light_02_unarmed_F";

if (_camo isEqualTo "pacific") then {
    OT_faction_NATO = "OPF_T_F";
    OT_fallback_faction_NATO = "OPF_F";

    OT_NATO_StaticGarrison_LevelTwo = ["O_HMG_01_high_F", "O_HMG_01_high_F", "O_GMG_01_high_F", "O_T_MRAP_02_hmg_ghex_F"];
    OT_NATO_StaticGarrison_LevelThree = ["O_static_AT_F", "O_static_AA_F", "O_HMG_01_high_F", "O_HMG_01_high_F", "O_GMG_01_high_F", "O_T_MRAP_02_hmg_ghex_F", "O_T_MRAP_02_gmg_ghex_F"];

    OT_NATO_Unit_Sniper = "O_T_Sniper_F";
    OT_NATO_Unit_Spotter = "O_T_Spotter_F";
    OT_NATO_Unit_AA_spec = "O_T_Soldier_AA_F";
    OT_NATO_Unit_AA_ass = "O_T_Soldier_AAA_F";
    OT_NATO_Unit_HVT = "O_T_Officer_F";
    OT_NATO_Unit_TeamLeader = "O_T_Soldier_TL_F";
    OT_NATO_Unit_SquadLeader = "O_T_Soldier_SL_F";

    OT_NATO_Vehicle_Quad = "O_T_Quadbike_01_ghex_F";
    OT_NATO_Vehicle_Transport = ["O_T_Truck_03_transport_ghex_F", "O_T_Truck_03_covered_ghex_F"];
    OT_NATO_Vehicle_Transport_Light = "O_T_LSV_02_unarmed_F";
    OT_NATO_Vehicles_PoliceSupport = ["O_T_MRAP_02_hmg_ghex_F", "O_T_MRAP_02_gmg_ghex_F", "O_T_LSV_02_armed_F", "O_Heli_Light_02_dynamicLoadout_F"];
    OT_NATO_Vehicles_CASDrone = "O_T_UAV_04_CAS_F";
    OT_NATO_Vehicles_GroundSupport = ["O_T_MRAP_02_gmg_ghex_F", "O_T_MRAP_02_hmg_ghex_F", "O_T_LSV_02_armed_F"];
    OT_NATO_Vehicles_TankSupport = ["O_T_MBT_02_cannon_ghex_F", "O_T_MBT_04_cannon_F"];
    OT_NATO_Vehicles_Convoy = ["O_T_UGV_01_rcws_ghex_F", "O_T_MRAP_02_hmg_ghex_F", "O_T_LSV_02_armed_F", "O_T_LSV_02_armed_F", "O_T_LSV_02_armed_F"];
    OT_NATO_Vehicle_Boat_Small = "O_T_Boat_Armed_01_hmg_F";
    OT_NATO_Vehicles_APC = ["O_T_APC_Wheeled_02_rcws_v2_ghex_F", "O_T_APC_Tracked_02_cannon_ghex_F"];
    OT_NATO_Mortar = "O_Mortar_01_F";
    OT_NATO_Vehicle_HVT = "O_T_MRAP_02_ghex_F";
    OT_NATO_Vehicles_HQGarrison = ["O_T_APC_Tracked_02_AA_ghex_F", "O_T_APC_Tracked_02_AA_ghex_F", "O_GMG_01_high_F", "O_GMG_01_high_F", "O_GMG_01_high_F", "O_HMG_01_high_F", "O_HMG_01_high_F", "O_HMG_01_high_F"];
} else {
    OT_NATO_StaticGarrison_LevelTwo = ["O_HMG_01_high_F", "O_HMG_01_high_F", "O_GMG_01_high_F", "O_MRAP_02_hmg_F"];
    OT_NATO_StaticGarrison_LevelThree = ["O_static_AT_F", "O_static_AA_F", "O_HMG_01_high_F", "O_HMG_01_high_F", "O_GMG_01_high_F", "O_MRAP_02_hmg_F", "O_MRAP_02_gmg_F"];

    OT_NATO_Unit_Sniper = "O_sniper_F";
    OT_NATO_Unit_Spotter = "O_spotter_F";
    OT_NATO_Unit_AA_spec = "O_Soldier_AA_F";
    OT_NATO_Unit_AA_ass = "O_Soldier_AAA_F";
    OT_NATO_Unit_TeamLeader = "O_Soldier_TL_F";
    OT_NATO_Unit_SquadLeader = "O_Soldier_SL_F";

    OT_NATO_Vehicle_Quad = "O_Quadbike_01_F";
    OT_NATO_Vehicle_Transport = ["O_Truck_03_transport_F", "O_Truck_03_covered_F"];
    OT_NATO_Vehicle_Transport_Light = "O_LSV_02_unarmed_F";
    OT_NATO_Vehicles_PoliceSupport = ["O_MRAP_02_hmg_F", "O_MRAP_02_gmg_F", "O_LSV_02_armed_F", "O_Heli_Light_02_dynamicLoadout_F"];
    OT_NATO_Vehicles_GroundSupport = ["O_MRAP_02_gmg_F", "O_MRAP_02_hmg_F", "O_LSV_02_armed_F"];
    OT_NATO_Vehicles_TankSupport = ["O_MBT_02_cannon_F", "O_MBT_04_cannon_F"];
    OT_NATO_Vehicles_Convoy = ["O_UGV_01_rcws_F", "O_MRAP_02_hmg_F", "O_LSV_02_armed_F", "O_LSV_02_armed_F", "O_LSV_02_armed_F"];
    OT_NATO_Vehicle_Boat_Small = "O_Boat_Armed_01_hmg_F";
    OT_NATO_Vehicles_APC = ["O_APC_Wheeled_02_rcws_v2_F", "O_APC_Tracked_02_cannon_F"];
    OT_NATO_Mortar = "O_Mortar_01_F";
    OT_NATO_Vehicle_HVT = "O_MRAP_02_F";
    OT_NATO_Vehicles_HQGarrison = ["O_APC_Tracked_02_AA_F", "O_APC_Tracked_02_AA_F", "O_GMG_01_high_F", "O_GMG_01_high_F", "O_GMG_01_high_F", "O_HMG_01_high_F", "O_HMG_01_high_F", "O_HMG_01_high_F"];
};
