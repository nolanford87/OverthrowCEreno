/*
    Occupier template: 3CB AAF (Altis Armed Forces, 3CB Factions, BLUFOR variant).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    Recon and CAS drones are vanilla (3CB AAF has none).
    The police stay the map's own (Gendarmerie).
*/

OT_NATO_name = "AAF";
OT_NATO_markerFlag = "UK3CB_Marker_AAF_Army";
OT_flag_NATO = "Flag_AAF_Army";

OT_faction_NATO = "UK3CB_AAF_B";
OT_fallback_faction_NATO = "UK3CB_AAF_B";

OT_NATO_HMG = "UK3CB_AAF_B_M2_TriPod";
OT_NATO_Vehicles_AirGarrison = [
    ["UK3CB_AAF_B_AH9", 1],
    ["UK3CB_AAF_B_UH60M2", 2],
    ["UK3CB_AAF_B_Bell412_Utility", 2],
    ["UK3CB_AAF_B_Unarmed_MH9", 2],
    ["UK3CB_AAF_B_AH1Z", 1],
    ["UK3CB_AAF_B_UH1H_M240", 1]
];
OT_NATO_Vehicles_JetGarrison = [
    ["UK3CB_AAF_B_Gripen", 1],
    ["UK3CB_AAF_B_L39_CAS", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["UK3CB_AAF_B_RBS70", "UK3CB_AAF_B_RBS70", "UK3CB_AAF_B_Stinger_AA_pod", "UK3CB_AAF_B_Stinger_AA_pod"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["UK3CB_AAF_B_M2_TriPod"];
OT_NATO_StaticGarrison_LevelTwo = ["UK3CB_AAF_B_M2_TriPod", "UK3CB_AAF_B_M2_TriPod", "UK3CB_AAF_B_MK19_TriPod", "UK3CB_AAF_B_M1151_OGPK_M2"];
OT_NATO_StaticGarrison_LevelThree = ["UK3CB_AAF_B_TOW_TriPod", "UK3CB_AAF_B_RBS70", "UK3CB_AAF_B_M2_TriPod", "UK3CB_AAF_B_M2_TriPod", "UK3CB_AAF_B_MK19_TriPod", "UK3CB_AAF_B_M1151_OGPK_M2", "UK3CB_AAF_B_M1151_OGPK_MK19"];

OT_NATO_Unit_Sniper = "UK3CB_AAF_B_SNI";
OT_NATO_Unit_Spotter = "UK3CB_AAF_B_SPOT";
OT_NATO_Unit_AA_spec = "UK3CB_AAF_B_AA";
OT_NATO_Unit_AA_ass = "UK3CB_AAF_B_AA_ASST";
OT_NATO_Unit_HVT = "UK3CB_AAF_B_OFF";
OT_NATO_Unit_TeamLeader = "UK3CB_AAF_B_TL";
OT_NATO_Unit_SquadLeader = "UK3CB_AAF_B_SL";

OT_NATO_Vehicle_Quad = "UK3CB_AAF_B_Quadbike";
OT_NATO_Vehicle_Transport = ["UK3CB_AAF_B_MTVR_Closed", "UK3CB_AAF_B_MTVR_Open", "UK3CB_AAF_B_M939"];
OT_NATO_Vehicle_Transport_Light = "UK3CB_AAF_B_M1151";
OT_NATO_Vehicles_PoliceSupport = ["UK3CB_AAF_B_M1151_OGPK_M2", "UK3CB_AAF_B_LR_WMIK_M2", "UK3CB_AAF_B_Offroad_M2", "UK3CB_AAF_B_AH9"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["UK3CB_AAF_B_AH1Z", "UK3CB_AAF_B_AH1Z_CS"];
OT_NATO_Vehicles_AirSupport_Small = ["UK3CB_AAF_B_AH9", "UK3CB_AAF_B_Bell412_Armed"];
OT_NATO_Vehicles_GroundSupport = ["UK3CB_AAF_B_M1151_OGPK_M2", "UK3CB_AAF_B_M1151_OGPK_MK19", "UK3CB_AAF_B_Dingo_HMG", "UK3CB_AAF_B_M1117"];
OT_NATO_Vehicles_TankSupport = ["UK3CB_AAF_B_M1A1", "UK3CB_AAF_B_M60A3"];
OT_NATO_Vehicles_Convoy = ["UK3CB_AAF_B_M1151_OGPK_M2", "UK3CB_AAF_B_Dingo_HMG", "UK3CB_AAF_B_LR_WMIK_M2", "UK3CB_AAF_B_M1151_OGPK_MK19", "UK3CB_AAF_B_M1117"];
OT_NATO_Vehicles_AirWingedSupport = ["UK3CB_AAF_B_Gripen", "UK3CB_AAF_B_L39_CAS"];
OT_NATO_Vehicle_AirTransport_Small = "UK3CB_AAF_B_Unarmed_MH9";
OT_NATO_Vehicle_AirTransport = ["UK3CB_AAF_B_UH60M2", "UK3CB_AAF_B_Bell412_Utility", "UK3CB_AAF_B_Unarmed_MH9"];
OT_NATO_Vehicle_AirTransport_Large = "UK3CB_AAF_B_UH60M2";
OT_NATO_Vehicle_Boat_Small = "UK3CB_AAF_B_RHIB_Gunboat";
OT_NATO_Vehicles_APC = ["UK3CB_AAF_B_LAV25", "UK3CB_AAF_B_M113_M2", "UK3CB_AAF_B_AAV"];
OT_NATO_Mortar = "UK3CB_AAF_B_M252";
OT_NATO_Vehicle_HVT = "UK3CB_AAF_B_SUV_Armoured";
OT_NATO_Vehicle_CTRGTransport = "UK3CB_AAF_B_Unarmed_MH9";
OT_NATO_Vehicles_HQGarrison = ["UK3CB_AAF_B_MTVR_ZU23", "UK3CB_AAF_B_MTVR_ZU23", "UK3CB_AAF_B_MK19_TriPod", "UK3CB_AAF_B_MK19_TriPod", "UK3CB_AAF_B_MK19_TriPod", "UK3CB_AAF_B_M2_TriPod", "UK3CB_AAF_B_M2_TriPod", "UK3CB_AAF_B_M2_TriPod"];
