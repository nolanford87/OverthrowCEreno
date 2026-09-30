/*
    Occupier template: RHS Russian Motor Rifle Troops (RHS: AFRF).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The police stay the map's own.
    Tanks come from the Tank Troops, aircraft from the Air Force (VVS), AA from the Air Defence Troops (VPVO),
    drones and boats are vanilla CSAT.
*/

OT_NATO_name = "Russian Army";
OT_NATO_markerFlag = "rhs_flag_russia";
OT_flag_NATO = "rhs_Flag_Russia_F";

OT_faction_NATO = "rhs_faction_msv";
OT_fallback_faction_NATO = "rhs_faction_tv"; // If there were no vehicles in the first faction, take them from this faction

OT_NATO_HMG = "rhs_kord_high_msv";
OT_NATO_Vehicles_AirGarrison = [
    ["rhs_ka60_c", 2],
    ["rhs_mi8mt_vvsc", 2],
    ["rhs_mi8amtsh_vvsc", 1],
    ["rhs_mi24p_vvsc", 1],
    ["rhs_ka52_vvsc", 1]
];
OT_NATO_Vehicles_JetGarrison = [
    ["rhs_su25sm_vvsc", 1],
    ["rhs_mig29sm_vvsc", 1],
    ["rhs_t50_vvs_generic_ext", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["rhs_igla_aa_pod_msv", "rhs_igla_aa_pod_msv", "rhs_zu23_msv", "rhs_p37_turret_vpvo"]; //Added to every airfield
OT_NATO_StaticGarrison_LevelOne = ["rhs_kord_high_msv"];
OT_NATO_StaticGarrison_LevelTwo = ["rhs_kord_high_msv", "rhs_kord_high_msv", "rhs_ags30_tripod_msv", "rhs_tigr_sts_msv"];
OT_NATO_StaticGarrison_LevelThree = ["rhs_kornet_9m133_2_msv", "rhs_igla_aa_pod_msv", "rhs_kord_high_msv", "rhs_kord_high_msv", "rhs_ags30_tripod_msv", "rhs_tigr_sts_msv", "rhsgref_brdm2_msv"];

OT_NATO_Unit_Sniper = "rhs_msv_emr_marksman";
OT_NATO_Unit_Spotter = "rhs_msv_emr_efreitor";
OT_NATO_Unit_AA_spec = "rhs_msv_emr_aa";
OT_NATO_Unit_AA_ass = "rhs_msv_emr_rifleman";
OT_NATO_Unit_HVT = "rhs_msv_emr_officer";
OT_NATO_Unit_TeamLeader = "rhs_msv_emr_junior_sergeant";
OT_NATO_Unit_SquadLeader = "rhs_msv_emr_sergeant";

OT_NATO_Vehicle_Quad = "rhs_uaz_open_msv_01";
OT_NATO_Vehicle_Transport = ["rhs_kamaz5350_msv", "rhs_ural_msv_01"];
OT_NATO_Vehicle_Transport_Light = "rhs_uaz_msv_01";
OT_NATO_Vehicles_PoliceSupport = ["rhs_tigr_sts_msv", "rhsgref_brdm2_msv", "rhs_mi8mtv3_vvsc"];
OT_NATO_Vehicles_ReconDrone = "O_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "O_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["rhs_mi28n_vvsc", "rhs_ka52_vvsc"];
OT_NATO_Vehicles_AirSupport_Small = ["rhs_mi8amtsh_vvsc"];
OT_NATO_Vehicles_GroundSupport = ["rhs_tigr_sts_msv", "rhsgref_brdm2_msv", "rhs_btr80_msv"];
OT_NATO_Vehicles_TankSupport = ["rhs_t72bd_tv", "rhs_t80u", "rhs_t90a_tv"];
OT_NATO_Vehicles_Convoy = ["rhs_btr80_msv", "rhsgref_brdm2_msv", "rhs_tigr_sts_msv", "rhs_tigr_sts_msv", "rhs_tigr_sts_msv"];
OT_NATO_Vehicles_AirWingedSupport = ["rhs_su25sm_vvsc", "rhs_mig29sm_vvsc"];
OT_NATO_Vehicle_AirTransport_Small = "rhs_ka60_c";
OT_NATO_Vehicle_AirTransport = ["rhs_mi8mt_vvsc", "rhs_mi8amt_vvsc", "rhs_ka60_c"];
OT_NATO_Vehicle_AirTransport_Large = "rhs_mi8amt_vvsc";
OT_NATO_Vehicle_Boat_Small = "O_Boat_Armed_01_hmg_F";
OT_NATO_Vehicles_APC = ["rhs_btr80a_msv", "rhs_bmp2_msv", "rhs_bmp3m_msv"];
OT_NATO_Mortar = "rhs_2b14_82mm_msv";
OT_NATO_Vehicle_HVT = "rhs_tigr_m_msv";
OT_NATO_Vehicle_CTRGTransport = "rhs_ka60_c";
OT_NATO_Vehicles_HQGarrison = ["rhs_zsu234_aa", "rhs_zsu234_aa", "rhs_ags30_tripod_msv", "rhs_ags30_tripod_msv", "rhs_ags30_tripod_msv", "rhs_kord_high_msv", "rhs_kord_high_msv", "rhs_kord_high_msv"];
