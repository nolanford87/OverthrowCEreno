/*
    Occupier template: RHS US Marine Corps (RHS: USAF).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The police stay the map's own.
    RHS has no Marine jets, trucks, APCs or AA vehicles: those come from the US Air Force and US Army,
    drones and boats are vanilla NATO.

    Parameters:
        _this # 0: STRING - Camo: "wd" (woodland) or "d" (desert)
*/

params [["_camo", "wd"]];

OT_NATO_name = "USMC";
OT_NATO_markerFlag = "flag_USA";
OT_flag_NATO = "Flag_US_F";

OT_NATO_Vehicles_JetGarrison = [
    ["rhs_a10", 1],
    ["rhsusf_f22", 1]
];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirWingedSupport = ["rhs_a10"];

if (_camo isEqualTo "d") then {
    OT_faction_NATO = "rhs_faction_usmc_d";
    OT_fallback_faction_NATO = "rhs_faction_usarmy_d"; // If there were no vehicles in the first faction, take them from this faction

    OT_NATO_HMG = "rhs_m2staticmg_usmc_d";
    OT_NATO_Vehicles_AirGarrison = [
        ["rhs_uh1y_d", 1],
        ["rhs_uh1y_unarmed_d", 3],
        ["rhsusf_ch53e_usmc_d", 2],
        ["rhs_ah1z", 1],
        ["rhs_uh1y_ffar_d", 1]
    ];
    OT_NATO_Vehicles_StaticAAGarrison = ["rhs_stinger_aa_pod_usmc_d", "rhs_stinger_aa_pod_usmc_d"]; //Added to every airfield
    OT_NATO_StaticGarrison_LevelOne = ["rhs_m2staticmg_usmc_d"];
    OT_NATO_StaticGarrison_LevelTwo = ["rhs_m2staticmg_usmc_d", "rhs_m2staticmg_usmc_d", "rhs_mk19_tripod_usmc_d", "rhsusf_m1151_m2_v3_usmc_d"];
    OT_NATO_StaticGarrison_LevelThree = ["rhs_tow_tripod_usmc_d", "rhs_stinger_aa_pod_usmc_d", "rhs_m2staticmg_usmc_d", "rhs_m2staticmg_usmc_d", "rhs_mk19_tripod_usmc_d", "rhsusf_m1151_m2_v3_usmc_d", "rhsusf_m1151_mk19_v3_usmc_d"];

    OT_NATO_Unit_Sniper = "rhsusf_usmc_marpat_d_sniper";
    OT_NATO_Unit_Spotter = "rhsusf_usmc_marpat_d_spotter";
    OT_NATO_Unit_AA_spec = "rhsusf_usmc_marpat_d_stinger";
    OT_NATO_Unit_AA_ass = "rhsusf_usmc_marpat_d_rifleman";
    OT_NATO_Unit_HVT = "rhsusf_usmc_marpat_d_officer";
    OT_NATO_Unit_TeamLeader = "rhsusf_usmc_marpat_d_teamleader";
    OT_NATO_Unit_SquadLeader = "rhsusf_usmc_marpat_d_squadleader";

    OT_NATO_Vehicle_Quad = "rhsusf_m998_d_s_2dr";
    OT_NATO_Vehicle_Transport = ["rhsusf_m1078a1p2_b_d_fmtv_usarmy", "rhsusf_m1083a1p2_b_d_fmtv_usarmy"];
    OT_NATO_Vehicle_Transport_Light = "rhsusf_m1151_usmc_d";
    OT_NATO_Vehicles_PoliceSupport = ["rhsusf_m1151_m2_v3_usmc_d", "rhsusf_m1151_mk19_v3_usmc_d", "rhsusf_m1043_d_s_m2", "rhs_uh1y_d"];
    OT_NATO_Vehicles_AirSupport = ["rhs_ah1z"];
    OT_NATO_Vehicles_AirSupport_Small = ["rhs_uh1y_d"];
    OT_NATO_Vehicles_GroundSupport = ["rhsusf_m1240a1_m2_usmc_d", "rhsusf_m1240a1_mk19_usmc_d", "rhsusf_cgrcat1a2_m2_usmc_d"];
    OT_NATO_Vehicles_TankSupport = ["rhsusf_m1a1fep_d"];
    OT_NATO_Vehicles_Convoy = ["rhsusf_m1240a1_m2crows_usmc_d", "rhsusf_m1151_m2_v3_usmc_d", "rhsusf_m1151_mk19_v3_usmc_d", "rhsusf_m1043_d_s_m2", "rhsusf_m1043_d_s_m2"];
    OT_NATO_Vehicle_AirTransport_Small = "rhs_uh1y_unarmed_d";
    OT_NATO_Vehicle_AirTransport = ["rhsusf_ch53e_usmc_d", "rhs_uh1y_unarmed_d", "rhs_uh1y_d"];
    OT_NATO_Vehicle_AirTransport_Large = "rhsusf_ch53e_usmc_d";
    OT_NATO_Vehicle_Boat_Small = "B_Boat_Armed_01_minigun_F";
    OT_NATO_Vehicles_APC = ["rhsusf_stryker_m1126_m2_d", "rhs_m2a3"];
    OT_NATO_Mortar = "rhs_m252_usmc_d";
    OT_NATO_Vehicle_HVT = "rhsusf_m1240a1_usmc_d";
    OT_NATO_Vehicle_CTRGTransport = "rhs_uh1y_unarmed_d";
    OT_NATO_Vehicles_HQGarrison = ["rhs_m6", "rhs_m6", "rhs_mk19_tripod_usmc_d", "rhs_mk19_tripod_usmc_d", "rhs_mk19_tripod_usmc_d", "rhs_m2staticmg_usmc_d", "rhs_m2staticmg_usmc_d", "rhs_m2staticmg_usmc_d"];
} else {
    OT_faction_NATO = "rhs_faction_usmc_wd";
    OT_fallback_faction_NATO = "rhs_faction_usarmy_wd";

    OT_NATO_HMG = "rhs_m2staticmg_usmc_wd";
    OT_NATO_Vehicles_AirGarrison = [
        ["rhs_uh1y", 1],
        ["rhs_uh1y_unarmed", 3],
        ["rhsusf_ch53e_usmc", 2],
        ["rhs_ah1z_wd", 1],
        ["rhs_uh1y_ffar", 1]
    ];
    OT_NATO_Vehicles_StaticAAGarrison = ["rhs_stinger_aa_pod_usmc_wd", "rhs_stinger_aa_pod_usmc_wd"]; //Added to every airfield
    OT_NATO_StaticGarrison_LevelOne = ["rhs_m2staticmg_usmc_wd"];
    OT_NATO_StaticGarrison_LevelTwo = ["rhs_m2staticmg_usmc_wd", "rhs_m2staticmg_usmc_wd", "rhs_mk19_tripod_usmc_wd", "rhsusf_m1151_m2_v3_usmc_wd"];
    OT_NATO_StaticGarrison_LevelThree = ["rhs_tow_tripod_usmc_wd", "rhs_stinger_aa_pod_usmc_wd", "rhs_m2staticmg_usmc_wd", "rhs_m2staticmg_usmc_wd", "rhs_mk19_tripod_usmc_wd", "rhsusf_m1151_m2_v3_usmc_wd", "rhsusf_m1151_mk19_v3_usmc_wd"];

    OT_NATO_Unit_Sniper = "rhsusf_usmc_marpat_wd_sniper";
    OT_NATO_Unit_Spotter = "rhsusf_usmc_marpat_wd_spotter";
    OT_NATO_Unit_AA_spec = "rhsusf_usmc_marpat_wd_stinger";
    OT_NATO_Unit_AA_ass = "rhsusf_usmc_marpat_wd_rifleman";
    OT_NATO_Unit_HVT = "rhsusf_usmc_marpat_wd_officer";
    OT_NATO_Unit_TeamLeader = "rhsusf_usmc_marpat_wd_teamleader";
    OT_NATO_Unit_SquadLeader = "rhsusf_usmc_marpat_wd_squadleader";

    OT_NATO_Vehicle_Quad = "rhsusf_m998_w_s_2dr";
    OT_NATO_Vehicle_Transport = ["rhsusf_m1078a1p2_b_wd_fmtv_usarmy", "rhsusf_m1083a1p2_b_wd_fmtv_usarmy"];
    OT_NATO_Vehicle_Transport_Light = "rhsusf_m1151_usmc_wd";
    OT_NATO_Vehicles_PoliceSupport = ["rhsusf_m1151_m2_v3_usmc_wd", "rhsusf_m1151_mk19_v3_usmc_wd", "rhsusf_m1043_w_s_m2", "rhs_uh1y"];
    OT_NATO_Vehicles_AirSupport = ["rhs_ah1z_wd"];
    OT_NATO_Vehicles_AirSupport_Small = ["rhs_uh1y"];
    OT_NATO_Vehicles_GroundSupport = ["rhsusf_m1240a1_m2_usmc_wd", "rhsusf_m1240a1_mk19_usmc_wd", "rhsusf_cgrcat1a2_m2_usmc_wd"];
    OT_NATO_Vehicles_TankSupport = ["rhsusf_m1a1fep_wd", "rhsusf_m1a1hc_wd"];
    OT_NATO_Vehicles_Convoy = ["rhsusf_m1240a1_m2crows_usmc_wd", "rhsusf_m1151_m2_v3_usmc_wd", "rhsusf_m1151_mk19_v3_usmc_wd", "rhsusf_m1043_w_s_m2", "rhsusf_m1043_w_s_m2"];
    OT_NATO_Vehicle_AirTransport_Small = "rhs_uh1y_unarmed";
    OT_NATO_Vehicle_AirTransport = ["rhsusf_ch53e_usmc", "rhs_uh1y_unarmed", "rhs_uh1y"];
    OT_NATO_Vehicle_AirTransport_Large = "rhsusf_ch53e_usmc";
    OT_NATO_Vehicle_Boat_Small = "B_T_Boat_Armed_01_minigun_F";
    OT_NATO_Vehicles_APC = ["rhsusf_stryker_m1126_m2_wd", "rhs_m2a3_wd"];
    OT_NATO_Mortar = "rhs_m252_usmc_wd";
    OT_NATO_Vehicle_HVT = "rhsusf_m1240a1_usmc_wd";
    OT_NATO_Vehicle_CTRGTransport = "rhs_uh1y_unarmed";
    OT_NATO_Vehicles_HQGarrison = ["rhs_m6_wd", "rhs_m6_wd", "rhs_mk19_tripod_usmc_wd", "rhs_mk19_tripod_usmc_wd", "rhs_mk19_tripod_usmc_wd", "rhs_m2staticmg_usmc_wd", "rhs_m2staticmg_usmc_wd", "rhs_m2staticmg_usmc_wd"];
};
