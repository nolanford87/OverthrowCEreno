/*
    Occupier template: UNA (Western Sahara creator DLC).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    The UNA has no attack helicopters, jets or AA soldiers of its own: Pawnee / Blackfoot, Buzzard
    and the Western Sahara desert NATO AA team stand in. Reaction Forces / Expeditionary Forces
    vehicles of the UNA are used when those are loaded too.
    The police stay the map's own (Gendarmerie).
*/

private _have = { _this select { isClass (configFile >> "CfgVehicles" >> _x) } };

OT_NATO_name = "UNA";
OT_NATO_markerFlag = "flag_UN";
OT_flag_NATO = "Flag_UNO_F";

OT_faction_NATO = "BLU_UN_lxWS";
OT_fallback_faction_NATO = "BLU_NATO_lxWS";

OT_NATO_HMG = "B_HMG_01_high_F";
OT_NATO_Vehicles_AirGarrison = [
    ["B_UN_Heli_EC_01A_military_RF", 2],
    ["B_Heli_Light_01_F", 2],
    ["B_Heli_Light_01_dynamicLoadout_F", 1]
] select { isClass (configFile >> "CfgVehicles" >> (_x select 0)) };
OT_NATO_Vehicles_JetGarrison = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["B_D_static_AA_lxWS", "B_D_static_AA_lxWS"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["B_HMG_01_high_F"];
OT_NATO_StaticGarrison_LevelTwo = ["B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_UNA_APC_Wheeled_02_hmg_lxWS"];
OT_NATO_StaticGarrison_LevelThree = ["B_D_static_AT_lxWS", "B_D_static_AA_lxWS", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_UNA_APC_Wheeled_02_hmg_lxWS"];

OT_NATO_Unit_Sniper = "B_UN_Soldier_TL_lxWS";
OT_NATO_Unit_Spotter = "B_UN_Soldier_lxWS";
OT_NATO_Unit_AA_spec = "B_D_soldier_AA_lxWS";
OT_NATO_Unit_AA_ass = "B_D_soldier_AAA_lxWS";
OT_NATO_Unit_HVT = "B_UN_officer_lxWS";
OT_NATO_Unit_TeamLeader = "B_UN_Soldier_TL_lxWS";
OT_NATO_Unit_SquadLeader = "B_UN_Soldier_TL_lxWS";

OT_NATO_Vehicle_Quad = "B_D_Quadbike_01_lxWS";
OT_NATO_Vehicle_Transport = ["B_UN_Truck_01_transport_lxWS", "B_UN_Truck_01_covered_lxWS"];
OT_NATO_Vehicle_Transport_Light = "B_UN_MRAP_01_lxWS";
OT_NATO_Vehicles_PoliceSupport = ["B_UNA_APC_Wheeled_02_hmg_lxWS", "B_UN_Offroad_Armor_lxWS", "B_Heli_Light_01_dynamicLoadout_F"];
OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["B_Heli_Attack_01_dynamicLoadout_F"];
OT_NATO_Vehicles_AirSupport_Small = ["B_Heli_Light_01_dynamicLoadout_F"];
OT_NATO_Vehicles_GroundSupport = ["B_UNA_APC_Wheeled_02_hmg_lxWS", "B_UN_Pickup_mmg_rf", "EF_B_Gyra_HMG_UNA", "EF_B_Gyra_Armed_UNA"] call _have;
OT_NATO_Vehicles_TankSupport = ["B_MBT_03_cannon_lxWS"];
OT_NATO_Vehicles_Convoy = ["B_UNA_APC_Wheeled_02_hmg_lxWS", "B_UN_MRAP_01_lxWS", "B_UN_Pickup_mmg_rf", "EF_B_Gyra_HMG_UNA"] call _have;
OT_NATO_Vehicles_AirWingedSupport = ["I_Plane_Fighter_03_dynamicLoadout_F"];
OT_NATO_Vehicle_AirTransport_Small = "B_Heli_Light_01_F";
OT_NATO_Vehicle_AirTransport = (["B_UN_Heli_EC_01A_military_RF", "B_Heli_Light_01_F"] call _have);
OT_NATO_Vehicle_AirTransport_Large = (["B_UN_Heli_EC_01A_military_RF", "B_Heli_Transport_01_F"] call _have) select 0;
OT_NATO_Vehicle_Boat_Small = "B_Boat_Armed_01_minigun_F";
OT_NATO_Vehicles_APC = ["B_UNA_APC_Wheeled_02_hmg_lxWS", "B_UNA_APC_Wheeled_02_unarmed_lxWS", "B_UN_APC_Wheeled_01_command_lxWS"];
OT_NATO_Mortar = "B_D_Mortar_01_lxWS";
OT_NATO_Vehicle_HVT = "B_UN_MRAP_01_lxWS";
OT_NATO_Vehicle_CTRGTransport = "B_Heli_Light_01_F";
OT_NATO_Vehicles_HQGarrison = (["EF_B_Gyra_Antiair_UNA", "EF_B_Gyra_Antiair_UNA"] call _have) + ["B_D_static_AA_lxWS", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F"];
