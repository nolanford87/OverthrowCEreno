/*
    Occupier template: 3CB LDF (Livonian Defence Force, 3CB Factions, BLUFOR variant).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The map marker (3CB has no LDF marker), armed boat and drones are vanilla.
    The police stay the map's own (Gendarmerie).
*/

OT_NATO_name = "LDF";
OT_NATO_markerFlag = "flag_EAF";
OT_flag_NATO = "Flag_LDF";

OT_faction_NATO = "UK3CB_LDF_B";
OT_fallback_faction_NATO = "UK3CB_LDF_B";

OT_NATO_HMG = "UK3CB_LDF_B_M2_TriPod";
OT_NATO_Vehicles_AirGarrison = [
    ["UK3CB_LDF_B_Mi_24V", 1],
    ["UK3CB_LDF_B_Mi8AMT", 3],
    ["UK3CB_LDF_B_Mi8", 2],
    ["UK3CB_LDF_B_Mi8AMTSh", 1]
];
OT_NATO_Vehicles_JetGarrison = [
    ["UK3CB_LDF_B_Su25SM_CAS", 1],
    ["UK3CB_LDF_B_Mig29S", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["UK3CB_LDF_B_RBS70", "UK3CB_LDF_B_RBS70", "UK3CB_LDF_B_Igla_AA_pod", "UK3CB_LDF_B_ZU23"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["UK3CB_LDF_B_M2_TriPod"];
OT_NATO_StaticGarrison_LevelTwo = ["UK3CB_LDF_B_M2_TriPod", "UK3CB_LDF_B_M2_TriPod", "UK3CB_LDF_B_AGS", "UK3CB_LDF_B_M1151_OGPK_M2"];
OT_NATO_StaticGarrison_LevelThree = ["UK3CB_LDF_B_Kornet", "UK3CB_LDF_B_RBS70", "UK3CB_LDF_B_M2_TriPod", "UK3CB_LDF_B_M2_TriPod", "UK3CB_LDF_B_AGS", "UK3CB_LDF_B_M1151_OGPK_M2", "UK3CB_LDF_B_Tigr_STS"];

OT_NATO_Unit_Sniper = "UK3CB_LDF_B_SNI";
OT_NATO_Unit_Spotter = "UK3CB_LDF_B_SPOT";
OT_NATO_Unit_AA_spec = "UK3CB_LDF_B_AA";
OT_NATO_Unit_AA_ass = "UK3CB_LDF_B_AA_ASST";
OT_NATO_Unit_HVT = "UK3CB_LDF_B_OFF";
OT_NATO_Unit_TeamLeader = "UK3CB_LDF_B_TL";
OT_NATO_Unit_SquadLeader = "UK3CB_LDF_B_SL";

OT_NATO_Vehicle_Quad = "UK3CB_LDF_B_Quadbike";
OT_NATO_Vehicle_Transport = ["UK3CB_LDF_B_T810_Closed", "UK3CB_LDF_B_T810_Open"];
OT_NATO_Vehicle_Transport_Light = "UK3CB_LDF_B_M1151";
OT_NATO_Vehicles_PoliceSupport = ["UK3CB_LDF_B_M1151_OGPK_M2", "UK3CB_LDF_B_Pickup_M2", "UK3CB_LDF_B_Tigr_STS"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["UK3CB_LDF_B_Mi_24V", "UK3CB_LDF_B_Mi_24P"];
OT_NATO_Vehicles_AirSupport_Small = ["UK3CB_LDF_B_Mi8AMTSh"];
OT_NATO_Vehicles_GroundSupport = ["UK3CB_LDF_B_M1151_OGPK_M2", "UK3CB_LDF_B_Dingo_HMG", "UK3CB_LDF_B_Tigr_STS", "UK3CB_LDF_B_BRDM2"];
OT_NATO_Vehicles_TankSupport = ["UK3CB_LDF_B_Leopard", "UK3CB_LDF_B_T72BB"];
OT_NATO_Vehicles_Convoy = ["UK3CB_LDF_B_M1151_OGPK_M2", "UK3CB_LDF_B_Dingo_HMG", "UK3CB_LDF_B_Tigr_STS", "UK3CB_LDF_B_M1151_OGPK_MK19", "UK3CB_LDF_B_BRDM2"];
OT_NATO_Vehicles_AirWingedSupport = ["UK3CB_LDF_B_Su25SM_CAS", "UK3CB_LDF_B_Mig29S"];
OT_NATO_Vehicle_AirTransport_Small = "UK3CB_LDF_B_Mi8AMT";
OT_NATO_Vehicle_AirTransport = ["UK3CB_LDF_B_Mi8", "UK3CB_LDF_B_Mi8AMT"];
OT_NATO_Vehicle_AirTransport_Large = "UK3CB_LDF_B_Mi8";
OT_NATO_Vehicle_Boat_Small = "B_Boat_Armed_01_minigun_F";
OT_NATO_Vehicles_APC = ["UK3CB_LDF_B_Marshall", "UK3CB_LDF_B_BMP2", "UK3CB_LDF_B_MTLB_Cannon"];
OT_NATO_Mortar = "UK3CB_LDF_B_M252";
OT_NATO_Vehicle_HVT = "UK3CB_LDF_B_Tigr";
OT_NATO_Vehicle_CTRGTransport = "UK3CB_LDF_B_Mi8AMT";
OT_NATO_Vehicles_HQGarrison = ["UK3CB_LDF_B_ZsuTank", "UK3CB_LDF_B_ZsuTank", "UK3CB_LDF_B_AGS", "UK3CB_LDF_B_AGS", "UK3CB_LDF_B_AGS", "UK3CB_LDF_B_M2_TriPod", "UK3CB_LDF_B_M2_TriPod", "UK3CB_LDF_B_M2_TriPod"];
