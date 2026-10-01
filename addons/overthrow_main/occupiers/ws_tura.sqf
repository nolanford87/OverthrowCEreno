/*
    Occupier template: Tura (warlord militia, Western Sahara creator DLC, BLUFOR variant).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    Tura has armed offroads and pickups only: for trucks, APCs, tanks, aircraft and AA it takes
    SFIA's (also Western Sahara), with CSAT's helicopters and the Buzzard. Reaction Forces pickups of
    Tura are used when that's loaded too.
    The police stay the map's own (Gendarmerie).
*/

private _have = { _this select { isClass (configFile >> "CfgVehicles" >> _x) } };

OT_NATO_name = "Tura";
OT_NATO_markerFlag = "lxWS_flag_Tura";
OT_flag_NATO = "Flag_Syndikat_F";

OT_faction_NATO = "BLU_TURA_lxWS";
OT_fallback_faction_NATO = "OPF_SFIA_lxWS";

OT_NATO_HMG = "B_Tura_HMG_02_high_lxWS";
OT_NATO_Vehicles_AirGarrison = [
    ["O_Heli_Light_02_unarmed_F", 2],
    ["O_Heli_Light_02_dynamicLoadout_F", 1]
];
OT_NATO_Vehicles_JetGarrison = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["B_Tura_ZU23_lxWS", "B_Tura_ZU23_lxWS"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["B_Tura_HMG_02_high_lxWS"];
OT_NATO_StaticGarrison_LevelTwo = ["B_Tura_HMG_02_high_lxWS", "B_Tura_HMG_02_high_lxWS", "B_Tura_ZU23_lxWS", "B_Tura_Offroad_armor_armed_lxWS"];
OT_NATO_StaticGarrison_LevelThree = ["B_Tura_ZU23_lxWS", "B_Tura_HMG_02_high_lxWS", "B_Tura_HMG_02_high_lxWS", "B_Tura_Offroad_armor_armed_lxWS", "B_Tura_Offroad_armor_AT_lxWS", "B_Tura_Offroad_armor_AA_lxWS"];

OT_NATO_Unit_Sniper = "B_Tura_scout_lxWS";
OT_NATO_Unit_Spotter = "B_Tura_watcher_lxWS";
OT_NATO_Unit_AA_spec = "O_SFIA_soldier_aa_lxWS";
OT_NATO_Unit_AA_ass = "O_SFIA_Soldier_AAA_lxWS";
OT_NATO_Unit_HVT = "B_Tura_enforcer_lxWS";
OT_NATO_Unit_TeamLeader = "B_Tura_enforcer_lxWS";
OT_NATO_Unit_SquadLeader = "B_Tura_enforcer_lxWS";

OT_NATO_Vehicle_Quad = "O_Quadbike_01_F";
OT_NATO_Vehicle_Transport = ["O_SFIA_Truck_02_transport_lxWS", "O_SFIA_Truck_02_covered_lxWS"];
OT_NATO_Vehicle_Transport_Light = "B_Tura_Offroad_armor_lxWS";
OT_NATO_Vehicles_PoliceSupport = ["B_Tura_Offroad_armor_armed_lxWS", "B_Tura_Offroad_armor_AT_lxWS"];
OT_NATO_Vehicles_ReconDrone = "O_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "O_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["O_Heli_Light_02_dynamicLoadout_F"];
OT_NATO_Vehicles_AirSupport_Small = ["O_Heli_Light_02_dynamicLoadout_F"];
OT_NATO_Vehicles_GroundSupport = ["B_Tura_Offroad_armor_armed_lxWS", "B_Tura_Offroad_armor_AT_lxWS", "B_Tura_Pickup_01_hmg_RF", "B_Tura_Pickup_01_Rocket_rf"] call _have;
OT_NATO_Vehicles_TankSupport = ["O_SFIA_MBT_02_cannon_lxWS", "O_SFIA_APC_Tracked_02_cannon_lxWS"];
OT_NATO_Vehicles_Convoy = ["B_Tura_Offroad_armor_armed_lxWS", "B_Tura_Offroad_armor_AT_lxWS", "B_Tura_Pickup_01_hmg_RF"] call _have;
OT_NATO_Vehicles_AirWingedSupport = ["I_Plane_Fighter_03_dynamicLoadout_F"];
OT_NATO_Vehicle_AirTransport_Small = "O_Heli_Light_02_unarmed_F";
OT_NATO_Vehicle_AirTransport = ["O_Heli_Light_02_unarmed_F"];
OT_NATO_Vehicle_AirTransport_Large = "O_Heli_Light_02_unarmed_F";
OT_NATO_Vehicle_Boat_Small = "O_Boat_Armed_01_hmg_F";
OT_NATO_Vehicles_APC = ["O_SFIA_APC_Wheeled_02_hmg_lxWS", "O_SFIA_APC_Wheeled_02_unarmed_lxWS"];
OT_NATO_Mortar = "B_Tura_Mortar_lxWS";
OT_NATO_Vehicle_HVT = "B_Tura_Offroad_armor_lxWS";
OT_NATO_Vehicle_CTRGTransport = "O_Heli_Light_02_unarmed_F";
OT_NATO_Vehicles_HQGarrison = ["B_Tura_Offroad_armor_AA_lxWS", "B_Tura_Offroad_armor_AA_lxWS", "B_Tura_ZU23_lxWS", "B_Tura_ZU23_lxWS", "B_Tura_HMG_02_high_lxWS", "B_Tura_HMG_02_high_lxWS", "B_Tura_HMG_02_high_lxWS"];
