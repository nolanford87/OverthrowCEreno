/*
    Occupier template: SFIA (Sefrawi Freedom and Independence Army, Western Sahara creator DLC).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    SFIA has no jets, light attack helicopters or drones of its own: CSAT's stand in. Reaction
    Forces / Expeditionary Forces vehicles of SFIA are used when those are loaded too.
    The police stay the map's own (Gendarmerie).
*/

private _have = { _this select { isClass (configFile >> "CfgVehicles" >> _x) } };

OT_NATO_name = "SFIA";
OT_NATO_markerFlag = "lxWS_flag_SFIA";
OT_flag_NATO = "Flag_SFIA_lxWS";

OT_faction_NATO = "OPF_SFIA_lxWS";
OT_fallback_faction_NATO = "OPF_F";

OT_NATO_HMG = "O_SFIA_HMG_02_high_lxWS";
OT_NATO_Vehicles_AirGarrison = [
    ["O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS", 1],
    ["O_SFIA_Heli_EC_02_RF", 1],
    ["O_Heli_Light_02_unarmed_F", 3],
    ["O_Heli_Light_02_dynamicLoadout_F", 1]
] select { isClass (configFile >> "CfgVehicles" >> (_x select 0)) };
OT_NATO_Vehicles_JetGarrison = [
    ["O_Plane_CAS_02_dynamicLoadout_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["O_SFIA_ZU23_lxWS", "O_SFIA_ZU23_lxWS", "O_static_AA_F"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["O_SFIA_HMG_02_high_lxWS"];
OT_NATO_StaticGarrison_LevelTwo = ["O_SFIA_HMG_02_high_lxWS", "O_SFIA_HMG_02_high_lxWS", "O_SFIA_ZU23_lxWS", "O_SFIA_Offroad_armed_lxWS"];
OT_NATO_StaticGarrison_LevelThree = ["O_static_AT_F", "O_SFIA_ZU23_lxWS", "O_SFIA_HMG_02_high_lxWS", "O_SFIA_HMG_02_high_lxWS", "O_SFIA_Offroad_armed_lxWS", "O_SFIA_Offroad_AT_lxWS", "O_SFIA_APC_Wheeled_02_hmg_lxWS"];

OT_NATO_Unit_Sniper = "O_SFIA_sharpshooter_lxWS";
OT_NATO_Unit_Spotter = "O_SFIA_Soldier_TL_lxWS";
OT_NATO_Unit_AA_spec = "O_SFIA_soldier_aa_lxWS";
OT_NATO_Unit_AA_ass = "O_SFIA_Soldier_AAA_lxWS";
OT_NATO_Unit_HVT = "O_SFIA_officer_lxWS";
OT_NATO_Unit_TeamLeader = "O_SFIA_Soldier_TL_lxWS";
OT_NATO_Unit_SquadLeader = "O_SFIA_Soldier_TL_lxWS";

OT_NATO_Vehicle_Quad = "O_Quadbike_01_F";
OT_NATO_Vehicle_Transport = ["O_SFIA_Truck_02_transport_lxWS", "O_SFIA_Truck_02_covered_lxWS"];
OT_NATO_Vehicle_Transport_Light = "O_SFIA_Offroad_lxWS";
OT_NATO_Vehicles_PoliceSupport = ["O_SFIA_Offroad_armed_lxWS", "O_SFIA_Offroad_AT_lxWS", "O_SFIA_APC_Wheeled_02_hmg_lxWS"];
OT_NATO_Vehicles_ReconDrone = "O_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "O_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS"];
OT_NATO_Vehicles_AirSupport_Small = ["O_SFIA_Heli_EC_02_RF", "O_Heli_Light_02_dynamicLoadout_F"] call _have;
OT_NATO_Vehicles_GroundSupport = ["O_SFIA_Offroad_armed_lxWS", "O_SFIA_Offroad_AT_lxWS", "O_SFIA_APC_Wheeled_02_hmg_lxWS", "EF_O_Gyra_HMG_SFIA", "EF_O_Gyra_Armed_SFIA"] call _have;
OT_NATO_Vehicles_TankSupport = ["O_SFIA_MBT_02_cannon_lxWS", "O_SFIA_APC_Tracked_02_cannon_lxWS"];
OT_NATO_Vehicles_Convoy = ["O_SFIA_Offroad_armed_lxWS", "O_SFIA_Offroad_AT_lxWS", "O_SFIA_APC_Wheeled_02_hmg_lxWS", "EF_O_Gyra_HMG_SFIA"] call _have;
OT_NATO_Vehicles_AirWingedSupport = ["O_Plane_CAS_02_dynamicLoadout_F"];
OT_NATO_Vehicle_AirTransport_Small = "O_Heli_Light_02_unarmed_F";
OT_NATO_Vehicle_AirTransport = ["O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS", "O_Heli_Light_02_unarmed_F"];
OT_NATO_Vehicle_AirTransport_Large = "O_Heli_Transport_04_bench_F";
OT_NATO_Vehicle_Boat_Small = "O_Boat_Armed_01_hmg_F";
OT_NATO_Vehicles_APC = ["O_SFIA_APC_Tracked_02_cannon_lxWS", "O_SFIA_APC_Tracked_02_30mm_lxWS", "O_SFIA_APC_Wheeled_02_hmg_lxWS", "O_SFIA_APC_Wheeled_02_unarmed_lxWS"];
OT_NATO_Mortar = "O_SFIA_Mortar_lxWS";
OT_NATO_Vehicle_HVT = "O_SFIA_Offroad_lxWS";
OT_NATO_Vehicle_CTRGTransport = "O_Heli_Light_02_unarmed_F";
OT_NATO_Vehicles_HQGarrison = ["O_SFIA_APC_Tracked_02_AA_lxWS", "O_SFIA_Truck_02_aa_lxWS", "O_SFIA_ZU23_lxWS", "O_SFIA_ZU23_lxWS", "O_SFIA_HMG_02_high_lxWS", "O_SFIA_HMG_02_high_lxWS", "O_SFIA_HMG_02_high_lxWS"];
