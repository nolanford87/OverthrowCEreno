/*
    Occupier template: Livonian Defense Force (Contact DLC).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The LDF has no tanks, jets or transport helicopters of its own, it borrows the AAF's.
    The police stay the map's own (Gendarmerie).
*/

OT_NATO_name = "LDF";
OT_NATO_markerFlag = "flag_EAF";
OT_flag_NATO = "Flag_EAF_F";

OT_faction_NATO = "IND_E_F";
OT_fallback_faction_NATO = "IND_F"; // If there were no vehicles in the first faction, take them from this faction

OT_NATO_HMG = "I_E_HMG_01_high_F";
OT_NATO_Vehicles_AirGarrison = [
    ["I_E_Heli_light_03_dynamicLoadout_F", 2],
    ["I_E_Heli_light_03_unarmed_F", 3],
    ["I_Heli_Transport_02_F", 2]
];
OT_NATO_Vehicles_JetGarrison = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 1],
    ["I_Plane_Fighter_04_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["I_E_Static_AA_F", "I_E_Static_AA_F", "I_E_Radar_System_01_F", "I_E_SAM_System_03_F"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["I_E_HMG_01_high_F"];
OT_NATO_StaticGarrison_LevelTwo = ["I_E_HMG_01_high_F", "I_E_HMG_01_high_F", "I_E_GMG_01_high_F", "I_E_Offroad_01_covered_F"];
OT_NATO_StaticGarrison_LevelThree = ["I_E_Static_AT_F", "I_E_Static_AA_F", "I_E_HMG_01_high_F", "I_E_HMG_01_high_F", "I_E_GMG_01_high_F", "I_E_HMG_02_high_F", "I_E_UGV_01_rcws_F"];

OT_NATO_Unit_Sniper = "I_E_soldier_M_F";
OT_NATO_Unit_Spotter = "I_E_RadioOperator_F";
OT_NATO_Unit_AA_spec = "I_E_Soldier_AA_F";
OT_NATO_Unit_AA_ass = "I_E_Soldier_AAA_F";
OT_NATO_Unit_HVT = "I_E_Officer_F";
OT_NATO_Unit_TeamLeader = "I_E_Soldier_TL_F";
OT_NATO_Unit_SquadLeader = "I_E_Soldier_SL_F";

OT_NATO_Vehicle_Quad = "I_E_Quadbike_01_F";
OT_NATO_Vehicle_Transport = ["I_E_Truck_02_transport_F", "I_E_Truck_02_F"];
OT_NATO_Vehicle_Transport_Light = "I_E_Offroad_01_covered_F";
OT_NATO_Vehicles_PoliceSupport = ["I_E_Offroad_01_covered_F", "I_E_UGV_01_rcws_F", "I_E_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_ReconDrone = "I_E_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "I_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["I_E_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_AirSupport_Small = ["I_E_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_GroundSupport = ["I_E_UGV_01_rcws_F", "I_E_APC_tracked_03_cannon_F"];
OT_NATO_Vehicles_TankSupport = ["I_E_APC_tracked_03_cannon_F", "I_MBT_03_cannon_F"];
OT_NATO_Vehicles_Convoy = ["I_E_UGV_01_rcws_F", "I_E_Offroad_01_covered_F", "I_E_APC_tracked_03_cannon_F"];
OT_NATO_Vehicles_AirWingedSupport = ["I_Plane_Fighter_04_F"];
OT_NATO_Vehicle_AirTransport_Small = "I_E_Heli_light_03_unarmed_F";
OT_NATO_Vehicle_AirTransport = ["I_Heli_Transport_02_F", "I_E_Heli_light_03_unarmed_F"];
OT_NATO_Vehicle_AirTransport_Large = "I_Heli_Transport_02_F";
OT_NATO_Vehicle_Boat_Small = "I_Boat_Armed_01_minigun_F";
OT_NATO_Vehicles_APC = ["I_E_APC_tracked_03_cannon_F"];
OT_NATO_Mortar = "I_E_Mortar_01_F";
OT_NATO_Vehicle_HVT = "I_E_Offroad_01_covered_F";
OT_NATO_Vehicle_CTRGTransport = "I_E_Heli_light_03_unarmed_F";
OT_NATO_Vehicles_HQGarrison = ["I_LT_01_AA_F", "I_LT_01_AA_F", "I_E_GMG_01_high_F", "I_E_GMG_01_high_F", "I_E_GMG_01_high_F", "I_E_HMG_01_high_F", "I_E_HMG_01_high_F", "I_E_HMG_01_high_F"];
