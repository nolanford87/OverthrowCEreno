/*
    Occupier template: AAF (Altis Armed Forces, base game).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The police stay the map's own (Gendarmerie).
*/

OT_NATO_name = "AAF";
OT_NATO_markerFlag = "flag_AAF";
OT_flag_NATO = "Flag_AAF_F";

OT_faction_NATO = "IND_F";
OT_fallback_faction_NATO = "IND_F";

OT_NATO_HMG = "I_HMG_01_high_F";
OT_NATO_Vehicles_AirGarrison = [
    ["I_Heli_light_03_dynamicLoadout_F", 2],
    ["I_Heli_Transport_02_F", 2],
    ["I_Heli_light_03_unarmed_F", 3]
];
OT_NATO_Vehicles_JetGarrison = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 2],
    ["I_Plane_Fighter_04_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["I_static_AA_F", "I_static_AA_F", "I_LT_01_AA_F"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["I_HMG_01_high_F"];
OT_NATO_StaticGarrison_LevelTwo = ["I_HMG_01_high_F", "I_HMG_01_high_F", "I_GMG_01_high_F", "I_MRAP_03_hmg_F"];
OT_NATO_StaticGarrison_LevelThree = ["I_static_AT_F", "I_static_AA_F", "I_HMG_01_high_F", "I_HMG_01_high_F", "I_GMG_01_high_F", "I_MRAP_03_hmg_F", "I_MRAP_03_gmg_F"];

OT_NATO_Unit_Sniper = "I_Sniper_F";
OT_NATO_Unit_Spotter = "I_Spotter_F";
OT_NATO_Unit_AA_spec = "I_Soldier_AA_F";
OT_NATO_Unit_AA_ass = "I_Soldier_AAA_F";
OT_NATO_Unit_HVT = "I_officer_F";
OT_NATO_Unit_TeamLeader = "I_Soldier_TL_F";
OT_NATO_Unit_SquadLeader = "I_Soldier_SL_F";

OT_NATO_Vehicle_Quad = "I_Quadbike_01_F";
OT_NATO_Vehicle_Transport = ["I_Truck_02_transport_F", "I_Truck_02_covered_F"];
OT_NATO_Vehicle_Transport_Light = "I_MRAP_03_F";
OT_NATO_Vehicles_PoliceSupport = ["I_MRAP_03_hmg_F", "I_MRAP_03_gmg_F", "I_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_ReconDrone = "I_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "I_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["I_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_AirSupport_Small = ["I_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_GroundSupport = ["I_MRAP_03_gmg_F", "I_MRAP_03_hmg_F", "I_LT_01_cannon_F"];
OT_NATO_Vehicles_TankSupport = ["I_MBT_03_cannon_F"];
OT_NATO_Vehicles_Convoy = ["I_UGV_01_rcws_F", "I_MRAP_03_hmg_F", "I_MRAP_03_gmg_F", "I_LT_01_cannon_F"];
OT_NATO_Vehicles_AirWingedSupport = ["I_Plane_Fighter_04_F"];
OT_NATO_Vehicle_AirTransport_Small = "I_Heli_light_03_unarmed_F";
OT_NATO_Vehicle_AirTransport = ["I_Heli_Transport_02_F", "I_Heli_light_03_unarmed_F"];
OT_NATO_Vehicle_AirTransport_Large = "I_Heli_Transport_02_F";
OT_NATO_Vehicle_Boat_Small = "I_Boat_Armed_01_minigun_F";
OT_NATO_Vehicles_APC = ["I_APC_Wheeled_03_cannon_F", "I_APC_tracked_03_cannon_F"];
OT_NATO_Mortar = "I_Mortar_01_F";
OT_NATO_Vehicle_HVT = "I_MRAP_03_F";
OT_NATO_Vehicle_CTRGTransport = "I_Heli_light_03_unarmed_F";
OT_NATO_Vehicles_HQGarrison = ["I_LT_01_AA_F", "I_LT_01_AA_F", "I_GMG_01_high_F", "I_GMG_01_high_F", "I_GMG_01_high_F", "I_HMG_01_high_F", "I_HMG_01_high_F", "I_HMG_01_high_F"];
