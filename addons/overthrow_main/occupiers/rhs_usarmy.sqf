/*
    Occupier template: RHS US Army (RHS: USAF).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The police stay the map's own.
    Aircraft come from the US Air Force and SOCOM (Little Birds), drones and boats are vanilla NATO.

    Parameters:
        _this # 0: STRING - Camo: "wd" (woodland, UCP) or "d" (desert, OCP)
*/

params [["_camo", "wd"]];

OT_NATO_name = "US Army";
OT_NATO_markerFlag = "flag_USA";
OT_flag_NATO = "Flag_US_F";

OT_NATO_Vehicles_JetGarrison = [
    ["rhs_a10", 1],
    ["rhsusf_f22", 1]
];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport_Small = ["rhs_melb_ah6m"];
OT_NATO_Vehicles_AirWingedSupport = ["rhs_a10"];

if (_camo isEqualTo "d") then {
    OT_faction_NATO = "rhs_faction_usarmy_d";
    OT_fallback_faction_NATO = "rhs_faction_usarmy_wd"; // If there were no vehicles in the first faction, take them from this faction

    OT_NATO_HMG = "rhs_m2staticmg_d";
    OT_NATO_Vehicles_AirGarrison = [
        ["rhs_uh60m_d", 2],
        ["rhs_uh60m2_d", 2],
        ["rhs_ch_47f_10", 1],
        ["rhs_ah64d", 1],
        ["rhs_melb_ah6m", 1],
        ["rhs_melb_mh6m", 2]
    ];
    OT_NATO_Vehicles_StaticAAGarrison = ["rhs_stinger_aa_pod_d", "rhs_stinger_aa_pod_d"]; //Added to every airfield
    OT_NATO_StaticGarrison_LevelOne = ["rhs_m2staticmg_d"];
    OT_NATO_StaticGarrison_LevelTwo = ["rhs_m2staticmg_d", "rhs_m2staticmg_d", "rhs_mk19_tripod_d", "rhsusf_m1151_m2_v1_usarmy_d"];
    OT_NATO_StaticGarrison_LevelThree = ["rhs_tow_tripod_d", "rhs_stinger_aa_pod_d", "rhs_m2staticmg_d", "rhs_m2staticmg_d", "rhs_mk19_tripod_d", "rhsusf_m1151_m2_v1_usarmy_d", "rhsusf_m1151_mk19_v1_usarmy_d"];

    OT_NATO_Unit_Sniper = "rhsusf_army_ocp_sniper";
    OT_NATO_Unit_Spotter = "rhsusf_army_ocp_marksman";
    OT_NATO_Unit_AA_spec = "rhsusf_army_ocp_aa";
    OT_NATO_Unit_AA_ass = "rhsusf_army_ocp_rifleman";
    OT_NATO_Unit_HVT = "rhsusf_army_ocp_officer";
    OT_NATO_Unit_TeamLeader = "rhsusf_army_ocp_teamleader";
    OT_NATO_Unit_SquadLeader = "rhsusf_army_ocp_squadleader";

    OT_NATO_Vehicle_Quad = "rhsusf_m998_d_2dr";
    OT_NATO_Vehicle_Transport = ["rhsusf_m1078a1p2_b_d_fmtv_usarmy", "rhsusf_m1083a1p2_b_d_fmtv_usarmy"];
    OT_NATO_Vehicle_Transport_Light = "rhsusf_m1151_usarmy_d";
    OT_NATO_Vehicles_PoliceSupport = ["rhsusf_m1151_m2_v1_usarmy_d", "rhsusf_m1151_mk19_v1_usarmy_d", "rhsusf_m1025_d_m2", "rhs_melb_ah6m"];
    OT_NATO_Vehicles_AirSupport = ["rhs_ah64d"];
    OT_NATO_Vehicles_GroundSupport = ["rhsusf_m1240a1_m2_usarmy_d", "rhsusf_m1240a1_mk19_usarmy_d", "rhsusf_m1151_m2_v1_usarmy_d"];
    OT_NATO_Vehicles_TankSupport = ["rhsusf_m1a2sep1d_usarmy", "rhsusf_m1a1aimd_usarmy"];
    OT_NATO_Vehicles_Convoy = ["rhsusf_m1240a1_m2crows_usarmy_d", "rhsusf_m1151_m2_v1_usarmy_d", "rhsusf_m1151_mk19_v1_usarmy_d", "rhsusf_m1025_d_m2", "rhsusf_m1025_d_m2"];
    OT_NATO_Vehicle_AirTransport_Small = "rhs_uh60m2_d";
    OT_NATO_Vehicle_AirTransport = ["rhs_ch_47f_10", "rhs_uh60m_d", "rhs_uh60m2_d"];
    OT_NATO_Vehicle_AirTransport_Large = "rhs_ch_47f_10";
    OT_NATO_Vehicle_Boat_Small = "B_Boat_Armed_01_minigun_F";
    OT_NATO_Vehicles_APC = ["rhsusf_stryker_m1126_m2_d", "rhs_m2a3", "rhsusf_m113d_usarmy"];
    OT_NATO_Mortar = "rhs_m252_d";
    OT_NATO_Vehicle_HVT = "rhsusf_m1240a1_usarmy_d";
    OT_NATO_Vehicle_CTRGTransport = "rhs_uh60m_d";
    OT_NATO_Vehicles_HQGarrison = ["rhs_m6", "rhs_m6", "rhs_mk19_tripod_d", "rhs_mk19_tripod_d", "rhs_mk19_tripod_d", "rhs_m2staticmg_d", "rhs_m2staticmg_d", "rhs_m2staticmg_d"];
} else {
    OT_faction_NATO = "rhs_faction_usarmy_wd";
    OT_fallback_faction_NATO = "rhs_faction_usarmy_d";

    OT_NATO_HMG = "rhs_m2staticmg_wd";
    OT_NATO_Vehicles_AirGarrison = [
        ["rhs_uh60m", 2],
        ["rhs_uh60m2", 2],
        ["rhs_ch_47f", 1],
        ["rhs_ah64d_wd", 1],
        ["rhs_melb_ah6m", 1],
        ["rhs_melb_mh6m", 2]
    ];
    OT_NATO_Vehicles_StaticAAGarrison = ["rhs_stinger_aa_pod_wd", "rhs_stinger_aa_pod_wd"]; //Added to every airfield
    OT_NATO_StaticGarrison_LevelOne = ["rhs_m2staticmg_wd"];
    OT_NATO_StaticGarrison_LevelTwo = ["rhs_m2staticmg_wd", "rhs_m2staticmg_wd", "rhs_mk19_tripod_wd", "rhsusf_m1151_m2_v1_usarmy_wd"];
    OT_NATO_StaticGarrison_LevelThree = ["rhs_tow_tripod_wd", "rhs_stinger_aa_pod_wd", "rhs_m2staticmg_wd", "rhs_m2staticmg_wd", "rhs_mk19_tripod_wd", "rhsusf_m1151_m2_v1_usarmy_wd", "rhsusf_m1151_mk19_v1_usarmy_wd"];

    OT_NATO_Unit_Sniper = "rhsusf_army_ucp_sniper";
    OT_NATO_Unit_Spotter = "rhsusf_army_ucp_marksman";
    OT_NATO_Unit_AA_spec = "rhsusf_army_ucp_aa";
    OT_NATO_Unit_AA_ass = "rhsusf_army_ucp_rifleman";
    OT_NATO_Unit_HVT = "rhsusf_army_ucp_officer";
    OT_NATO_Unit_TeamLeader = "rhsusf_army_ucp_teamleader";
    OT_NATO_Unit_SquadLeader = "rhsusf_army_ucp_squadleader";

    OT_NATO_Vehicle_Quad = "rhsusf_m998_w_2dr";
    OT_NATO_Vehicle_Transport = ["rhsusf_m1078a1p2_b_wd_fmtv_usarmy", "rhsusf_m1083a1p2_b_wd_fmtv_usarmy"];
    OT_NATO_Vehicle_Transport_Light = "rhsusf_m1151_usarmy_wd";
    OT_NATO_Vehicles_PoliceSupport = ["rhsusf_m1151_m2_v1_usarmy_wd", "rhsusf_m1151_mk19_v1_usarmy_wd", "rhsusf_m1025_w_m2", "rhs_melb_ah6m"];
    OT_NATO_Vehicles_AirSupport = ["rhs_ah64d_wd"];
    OT_NATO_Vehicles_GroundSupport = ["rhsusf_m1240a1_m2_usarmy_wd", "rhsusf_m1240a1_mk19_usarmy_wd", "rhsusf_m1151_m2_v1_usarmy_wd"];
    OT_NATO_Vehicles_TankSupport = ["rhsusf_m1a2sep1wd_usarmy", "rhsusf_m1a1aimwd_usarmy"];
    OT_NATO_Vehicles_Convoy = ["rhsusf_m1240a1_m2crows_usarmy_wd", "rhsusf_m1151_m2_v1_usarmy_wd", "rhsusf_m1151_mk19_v1_usarmy_wd", "rhsusf_m1025_w_m2", "rhsusf_m1025_w_m2"];
    OT_NATO_Vehicle_AirTransport_Small = "rhs_uh60m2";
    OT_NATO_Vehicle_AirTransport = ["rhs_ch_47f", "rhs_uh60m", "rhs_uh60m2"];
    OT_NATO_Vehicle_AirTransport_Large = "rhs_ch_47f";
    OT_NATO_Vehicle_Boat_Small = "B_T_Boat_Armed_01_minigun_F";
    OT_NATO_Vehicles_APC = ["rhsusf_stryker_m1126_m2_wd", "rhs_m2a3_wd", "rhsusf_m113_usarmy"];
    OT_NATO_Mortar = "rhs_m252_wd";
    OT_NATO_Vehicle_HVT = "rhsusf_m1240a1_usarmy_wd";
    OT_NATO_Vehicle_CTRGTransport = "rhs_uh60m";
    OT_NATO_Vehicles_HQGarrison = ["rhs_m6_wd", "rhs_m6_wd", "rhs_mk19_tripod_wd", "rhs_mk19_tripod_wd", "rhs_mk19_tripod_wd", "rhs_m2staticmg_wd", "rhs_m2staticmg_wd", "rhs_m2staticmg_wd"];
};
