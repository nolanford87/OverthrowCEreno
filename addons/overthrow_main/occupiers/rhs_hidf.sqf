/*
    Occupier template: RHS Horizon Islands Defence Force (RHS: GREF).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The police stay the map's own.
    The HIDF has no officer, AA soldier, trucks, tanks, attack helicopters, heavy helicopters, AA vehicles,
    AT/AA statics or mortar: those come from the RHS US Army and USMC, drones and boats are vanilla NATO.
*/

OT_NATO_name = "HIDF";
OT_NATO_markerFlag = "flag_Tanoa";
OT_flag_NATO = "Flag_HorizonIslands_F";

OT_faction_NATO = "rhsgref_faction_hidf";
OT_fallback_faction_NATO = "rhs_faction_usarmy_wd"; // If there were no vehicles in the first faction, take them from this faction

OT_NATO_HMG = "rhsgref_hidf_m2_static";
OT_NATO_Vehicles_AirGarrison = [
    ["rhs_uh1h_hidf", 2],
    ["rhs_uh1h_hidf_unarmed", 3],
    ["rhs_uh1h_hidf_gunship", 1],
    ["rhs_ah1z_wd", 1],
    ["rhs_ch_47f", 1]
];
OT_NATO_Vehicles_JetGarrison = [
    ["rhsgref_a29b_hidf", 2],
    ["rhs_a10", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["rhs_stinger_aa_pod_wd", "rhs_stinger_aa_pod_wd"]; //Added to every airfield
OT_NATO_StaticGarrison_LevelOne = ["rhsgref_hidf_m2_static"];
OT_NATO_StaticGarrison_LevelTwo = ["rhsgref_hidf_m2_static", "rhsgref_hidf_m2_static", "rhsgref_hidf_mk19_static", "rhsgref_hidf_m1025_m2"];
OT_NATO_StaticGarrison_LevelThree = ["rhs_tow_tripod_wd", "rhs_stinger_aa_pod_wd", "rhsgref_hidf_m2_static", "rhsgref_hidf_m2_static", "rhsgref_hidf_mk19_static", "rhsgref_hidf_m1025_m2", "rhsgref_hidf_m1025_mk19"];

OT_NATO_Unit_Sniper = "rhsgref_hidf_sniper";
OT_NATO_Unit_Spotter = "rhsgref_hidf_marksman";
OT_NATO_Unit_AA_spec = "rhsusf_army_ucp_aa";
OT_NATO_Unit_AA_ass = "rhsgref_hidf_rifleman";
OT_NATO_Unit_HVT = "rhsgref_hidf_squadleader";
OT_NATO_Unit_TeamLeader = "rhsgref_hidf_teamleader";
OT_NATO_Unit_SquadLeader = "rhsgref_hidf_squadleader";

OT_NATO_Vehicle_Quad = "rhsgref_hidf_m998_2dr";
OT_NATO_Vehicle_Transport = ["rhsusf_m1078a1p2_wd_fmtv_usarmy", "rhsusf_m1083a1p2_wd_fmtv_usarmy"];
OT_NATO_Vehicle_Transport_Light = "rhsgref_hidf_m998_4dr_fulltop";
OT_NATO_Vehicles_PoliceSupport = ["rhsgref_hidf_m1025_m2", "rhsgref_hidf_m1025_mk19", "rhs_uh1h_hidf_gunship"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["rhs_ah1z_wd"];
OT_NATO_Vehicles_AirSupport_Small = ["rhs_uh1h_hidf_gunship"];
OT_NATO_Vehicles_GroundSupport = ["rhsgref_hidf_m1025_m2", "rhsgref_hidf_m1025_mk19", "rhsgref_hidf_m113a3_m2"];
OT_NATO_Vehicles_TankSupport = ["rhsusf_m1a1aimwd_usarmy"];
OT_NATO_Vehicles_Convoy = ["rhsgref_hidf_m113a3_m2", "rhsgref_hidf_m1025_m2", "rhsgref_hidf_m1025_mk19", "rhsgref_hidf_m1025_m2", "rhsgref_hidf_m1025_m2"];
OT_NATO_Vehicles_AirWingedSupport = ["rhsgref_a29b_hidf"];
OT_NATO_Vehicle_AirTransport_Small = "rhs_uh1h_hidf_unarmed";
OT_NATO_Vehicle_AirTransport = ["rhs_uh1h_hidf_unarmed", "rhs_uh1h_hidf", "rhs_ch_47f"];
OT_NATO_Vehicle_AirTransport_Large = "rhs_ch_47f";
OT_NATO_Vehicle_Boat_Small = "B_T_Boat_Armed_01_minigun_F";
OT_NATO_Vehicles_APC = ["rhsgref_hidf_m113a3_m2", "rhsgref_hidf_m113a3_mk19", "rhs_m2a2_wd"];
OT_NATO_Mortar = "rhs_m252_wd";
OT_NATO_Vehicle_HVT = "rhsgref_hidf_m1025";
OT_NATO_Vehicle_CTRGTransport = "rhs_uh1h_hidf_unarmed";
OT_NATO_Vehicles_HQGarrison = ["rhs_m6_wd", "rhs_m6_wd", "rhsgref_hidf_mk19_static", "rhsgref_hidf_mk19_static", "rhsgref_hidf_mk19_static", "rhsgref_hidf_m2_static", "rhsgref_hidf_m2_static", "rhsgref_hidf_m2_static"];
