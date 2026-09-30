/*
    Occupier template: 3CB MEI (Middle East Insurgents, 3CB Factions, BLUFOR variant).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The MEI has no aircraft, boats or APCs: helicopters, the CAS jet and the boat come from
    3CB Takistan National Army (UK3CB_TKA_B, also the fallback faction), APCs from 3CB Takistan
    Pro-Government Militia (UK3CB_TKM_B). Drones are vanilla. No jets are parked at airfields.
    The police stay the map's own (Gendarmerie).
*/

OT_NATO_name = "Insurgents";
OT_NATO_markerFlag = "UK3CB_Marker_MEI";
OT_flag_NATO = "Flag_MEI";

OT_faction_NATO = "UK3CB_MEI_B";
OT_fallback_faction_NATO = "UK3CB_TKA_B"; // If there were no vehicles in the first faction, take them from this faction

OT_NATO_HMG = "UK3CB_MEI_B_DSHKM";
OT_NATO_Vehicles_AirGarrison = [
    ["UK3CB_TKA_B_Mi8AMTSh", 1],
    ["UK3CB_TKA_B_Mi8", 2],
    ["UK3CB_TKA_B_UH1H", 2],
    ["UK3CB_TKA_B_UH1H_GUNSHIP", 1]
];
OT_NATO_Vehicles_JetGarrison = [];
OT_NATO_Vehicles_StaticAAGarrison = ["UK3CB_MEI_B_ZU23", "UK3CB_MEI_B_ZU23", "UK3CB_MEI_B_Igla_AA_pod", "UK3CB_MEI_B_Igla_AA_pod"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["UK3CB_MEI_B_DSHKM"];
OT_NATO_StaticGarrison_LevelTwo = ["UK3CB_MEI_B_DSHKM", "UK3CB_MEI_B_DSHKM", "UK3CB_MEI_B_AGS", "UK3CB_MEI_B_Hilux_Dshkm"];
OT_NATO_StaticGarrison_LevelThree = ["UK3CB_MEI_B_SPG9", "UK3CB_MEI_B_ZU23", "UK3CB_MEI_B_DSHKM", "UK3CB_MEI_B_DSHKM", "UK3CB_MEI_B_AGS", "UK3CB_MEI_B_Hilux_Dshkm", "UK3CB_MEI_B_Hilux_GMG"];

OT_NATO_Unit_Sniper = "UK3CB_MEI_B_SNI";
OT_NATO_Unit_Spotter = "UK3CB_MEI_B_SPOT";
OT_NATO_Unit_AA_spec = "UK3CB_MEI_B_AA";
OT_NATO_Unit_AA_ass = "UK3CB_MEI_B_AA_ASST";
OT_NATO_Unit_HVT = "UK3CB_MEI_B_WAR";
OT_NATO_Unit_TeamLeader = "UK3CB_MEI_B_TL";
OT_NATO_Unit_SquadLeader = "UK3CB_MEI_B_SL";

OT_NATO_Vehicle_Quad = "UK3CB_MEI_B_TT650";
OT_NATO_Vehicle_Transport = ["UK3CB_MEI_B_V3S_Closed", "UK3CB_MEI_B_V3S_Open"];
OT_NATO_Vehicle_Transport_Light = "UK3CB_MEI_B_Offroad";
OT_NATO_Vehicles_PoliceSupport = ["UK3CB_MEI_B_Hilux_Dshkm", "UK3CB_MEI_B_Pickup_DSHKM", "UK3CB_MEI_B_LandRover_Opentop_DSHKM", "UK3CB_MEI_B_Offroad_M2"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["UK3CB_TKA_B_Mi_24V"];
OT_NATO_Vehicles_AirSupport_Small = ["UK3CB_TKA_B_UH1H_GUNSHIP"];
OT_NATO_Vehicles_GroundSupport = ["UK3CB_MEI_B_Hilux_Dshkm", "UK3CB_MEI_B_Hilux_GMG", "UK3CB_MEI_B_Hilux_Spg9", "UK3CB_MEI_B_LandRover_Opentop_DSHKM"];
OT_NATO_Vehicles_TankSupport = ["UK3CB_MEI_B_T55"];
OT_NATO_Vehicles_Convoy = ["UK3CB_MEI_B_Hilux_Dshkm", "UK3CB_MEI_B_Pickup_DSHKM", "UK3CB_MEI_B_LandRover_Opentop_PKM", "UK3CB_MEI_B_Hilux_Zu23", "UK3CB_MEI_B_Hilux_GMG"];
OT_NATO_Vehicles_AirWingedSupport = ["UK3CB_TKA_B_Su25SM_CAS"];
OT_NATO_Vehicle_AirTransport_Small = "UK3CB_TKA_B_UH1H";
OT_NATO_Vehicle_AirTransport = ["UK3CB_TKA_B_Mi8", "UK3CB_TKA_B_UH1H"];
OT_NATO_Vehicle_AirTransport_Large = "UK3CB_TKA_B_Mi8";
OT_NATO_Vehicle_Boat_Small = "UK3CB_TKA_B_RHIB_Gunboat";
OT_NATO_Vehicles_APC = ["UK3CB_TKM_B_BTR60", "UK3CB_TKM_B_BMP1", "UK3CB_TKM_B_MTLB_PKT"];
OT_NATO_Mortar = "UK3CB_MEI_B_2b14_82mm";
OT_NATO_Vehicle_HVT = "UK3CB_MEI_B_Offroad";
OT_NATO_Vehicle_CTRGTransport = "UK3CB_TKA_B_UH1H";
OT_NATO_Vehicles_HQGarrison = ["UK3CB_MEI_B_V3S_Zu23", "UK3CB_MEI_B_V3S_Zu23", "UK3CB_MEI_B_AGS", "UK3CB_MEI_B_AGS", "UK3CB_MEI_B_AGS", "UK3CB_MEI_B_DSHKM", "UK3CB_MEI_B_DSHKM", "UK3CB_MEI_B_DSHKM"];
