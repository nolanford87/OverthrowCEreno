/*
    Occupier template: 3CB LSM (Livonia Separatist Militia, 3CB Factions, BLUFOR variant).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The LSM has no aircraft or boats: helicopters, jets and boats come from 3CB ChDSZ
    (UK3CB_CHD_B, also the fallback faction), the attack helicopter from RHS (VVS Mi-24V).
    Drones are vanilla. The police stay the map's own (Gendarmerie).
*/

OT_NATO_name = "Separatists";
OT_NATO_markerFlag = "UK3CB_Marker_LSM";
OT_flag_NATO = "Flag_LSM";

OT_faction_NATO = "UK3CB_LSM_B";
OT_fallback_faction_NATO = "UK3CB_CHD_B"; // If there were no vehicles in the first faction, take them from this faction

OT_NATO_HMG = "UK3CB_LSM_B_DSHKM";
OT_NATO_Vehicles_AirGarrison = [
    ["UK3CB_CHD_B_Mi8AMTSh", 1],
    ["UK3CB_CHD_B_Mi8", 2],
    ["UK3CB_CHD_B_Mi8AMT", 2]
];
OT_NATO_Vehicles_JetGarrison = [];
OT_NATO_Vehicles_StaticAAGarrison = ["UK3CB_LSM_B_ZU23", "UK3CB_LSM_B_ZU23", "UK3CB_CHD_B_Igla_AA_pod", "UK3CB_CHD_B_Igla_AA_pod"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["UK3CB_LSM_B_DSHKM"];
OT_NATO_StaticGarrison_LevelTwo = ["UK3CB_LSM_B_DSHKM", "UK3CB_LSM_B_DSHKM", "UK3CB_LSM_B_AGS", "UK3CB_LSM_B_Hilux_Dshkm"];
OT_NATO_StaticGarrison_LevelThree = ["UK3CB_LSM_B_Metis", "UK3CB_LSM_B_ZU23", "UK3CB_LSM_B_DSHKM", "UK3CB_LSM_B_DSHKM", "UK3CB_LSM_B_AGS", "UK3CB_LSM_B_Hilux_Dshkm", "UK3CB_LSM_B_UAZ_AGS30"];

OT_NATO_Unit_Sniper = "UK3CB_LSM_B_SNI";
OT_NATO_Unit_Spotter = "UK3CB_LSM_B_SPOT";
OT_NATO_Unit_AA_spec = "UK3CB_LSM_B_AA";
OT_NATO_Unit_AA_ass = "UK3CB_LSM_B_AA_ASST";
OT_NATO_Unit_HVT = "UK3CB_LSM_B_OFF";
OT_NATO_Unit_TeamLeader = "UK3CB_LSM_B_TL";
OT_NATO_Unit_SquadLeader = "UK3CB_LSM_B_SL";

OT_NATO_Vehicle_Quad = "UK3CB_LSM_B_TT650";
OT_NATO_Vehicle_Transport = ["UK3CB_LSM_B_Ural", "UK3CB_LSM_B_Ural_Open", "UK3CB_LSM_B_Gaz66_Covered"];
OT_NATO_Vehicle_Transport_Light = "UK3CB_LSM_B_UAZ_Closed";
OT_NATO_Vehicles_PoliceSupport = ["UK3CB_LSM_B_Hilux_Dshkm", "UK3CB_LSM_B_Pickup_Dshkm", "UK3CB_LSM_B_LR_WMIK_DSHKM", "UK3CB_LSM_B_UAZ_AGS30"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["RHS_Mi24V_vvs"];
OT_NATO_Vehicles_AirSupport_Small = ["UK3CB_CHD_B_Mi8AMTSh"];
OT_NATO_Vehicles_GroundSupport = ["UK3CB_LSM_B_Hilux_Dshkm", "UK3CB_LSM_B_LR_WMIK_DSHKM", "UK3CB_LSM_B_BTR40_DSHKMS", "UK3CB_LSM_B_BRDM2"];
OT_NATO_Vehicles_TankSupport = ["UK3CB_LSM_B_T72B", "UK3CB_LSM_B_T72BM", "UK3CB_LSM_B_T55"];
OT_NATO_Vehicles_Convoy = ["UK3CB_LSM_B_Hilux_Dshkm", "UK3CB_LSM_B_UAZ_AGS30", "UK3CB_LSM_B_BTR40_PKM", "UK3CB_LSM_B_LR_WMIK_DSHKM", "UK3CB_LSM_B_BRDM2"];
OT_NATO_Vehicles_AirWingedSupport = ["UK3CB_CHD_B_Su25SM_CAS"];
OT_NATO_Vehicle_AirTransport_Small = "UK3CB_CHD_B_Mi8AMT";
OT_NATO_Vehicle_AirTransport = ["UK3CB_CHD_B_Mi8", "UK3CB_CHD_B_Mi8AMT"];
OT_NATO_Vehicle_AirTransport_Large = "UK3CB_CHD_B_Mi8";
OT_NATO_Vehicle_Boat_Small = "UK3CB_CHD_B_Fishing_Boat_DSHKM";
OT_NATO_Vehicles_APC = ["UK3CB_LSM_B_BMP2", "UK3CB_LSM_B_BTR60", "UK3CB_LSM_B_MTLB_PKT"];
OT_NATO_Mortar = "UK3CB_LSM_B_2b14_82mm";
OT_NATO_Vehicle_HVT = "UK3CB_LSM_B_UAZ_Closed";
OT_NATO_Vehicle_CTRGTransport = "UK3CB_CHD_B_Mi8AMT";
OT_NATO_Vehicles_HQGarrison = ["UK3CB_LSM_B_ZsuTank", "UK3CB_LSM_B_ZsuTank", "UK3CB_LSM_B_AGS", "UK3CB_LSM_B_AGS", "UK3CB_LSM_B_AGS", "UK3CB_LSM_B_DSHKM", "UK3CB_LSM_B_DSHKM", "UK3CB_LSM_B_DSHKM"];
