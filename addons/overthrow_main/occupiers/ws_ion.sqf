/*
    Occupier template: ION Services (private military company, Western Sahara creator DLC).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.
    ION has no armour heavier than its APCs, no attack aircraft and no AA soldiers of its own:
    Badger IFVs and the Rhino MGS stand in as its heavy armour, Hellcats / Pawnees and the Buzzard
    as its aircraft, the Western Sahara desert NATO AA team as its AA. Reaction Forces vehicles of
    ION are used when that's loaded too.
    The police stay the map's own (Gendarmerie).
*/

private _have = { _this select { isClass (configFile >> "CfgVehicles" >> _x) } };

OT_NATO_name = "ION";
OT_NATO_markerFlag = "flag_usa"; // ION has no flag marker (its flag is Flag_ION_F), it's an American company
OT_flag_NATO = "Flag_ION_F";

OT_faction_NATO = "BLU_ION_lxWS";
OT_fallback_faction_NATO = "BLU_NATO_lxWS";

OT_NATO_HMG = "B_HMG_01_high_F";
OT_NATO_Vehicles_AirGarrison = [
    ["B_ION_Heli_EC_01_RF", 2],
    ["I_Heli_light_03_unarmed_F", 2],
    ["I_Heli_light_03_dynamicLoadout_F", 1],
    ["B_Heli_Light_01_dynamicLoadout_F", 1]
] select { isClass (configFile >> "CfgVehicles" >> (_x select 0)) };
OT_NATO_Vehicles_JetGarrison = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 1]
];
OT_NATO_Vehicles_StaticAAGarrison = ["B_D_static_AA_lxWS", "B_D_static_AA_lxWS"]; //Added to every airfield

OT_NATO_StaticGarrison_LevelOne = ["B_HMG_01_high_F"];
OT_NATO_StaticGarrison_LevelTwo = ["B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_ION_Offroad_armed_lxWS"];
OT_NATO_StaticGarrison_LevelThree = ["B_D_static_AT_lxWS", "B_D_static_AA_lxWS", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_ION_Offroad_armed_lxWS", "B_ION_APC_Wheeled_02_hmg_lxWS"];

OT_NATO_Unit_Sniper = "B_ION_marksman_lxWS";
OT_NATO_Unit_Spotter = "B_ION_TL_lxWS";
OT_NATO_Unit_AA_spec = "B_D_soldier_AA_lxWS";
OT_NATO_Unit_AA_ass = "B_D_soldier_AAA_lxWS";
OT_NATO_Unit_HVT = "B_ION_TL_lxWS";
OT_NATO_Unit_TeamLeader = "B_ION_TL_lxWS";
OT_NATO_Unit_SquadLeader = "B_ION_TL_lxWS";

OT_NATO_Vehicle_Quad = "B_ION_Quadbike_01_lxWS";
OT_NATO_Vehicle_Transport = ["B_ION_Truck_02_covered_lxWS"];
OT_NATO_Vehicle_Transport_Light = "B_ION_Offroad_lxWS";
OT_NATO_Vehicles_PoliceSupport = ["B_ION_Offroad_armed_lxWS", "B_ION_APC_Wheeled_02_hmg_lxWS", "I_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_ReconDrone = "ION_UAV_01_lxWS";
OT_NATO_Vehicles_CASDrone = "B_UAV_02_dynamicLoadout_F";
OT_NATO_Vehicles_AirSupport = ["I_Heli_light_03_dynamicLoadout_F"];
OT_NATO_Vehicles_AirSupport_Small = ["B_Heli_Light_01_dynamicLoadout_F"];
OT_NATO_Vehicles_GroundSupport = ["B_ION_Offroad_armed_lxWS", "B_ION_APC_Wheeled_02_hmg_lxWS", "B_ION_Pickup_mmg_rf", "B_ION_Pickup_rcws_rf"] call _have;
OT_NATO_Vehicles_TankSupport = ["B_D_APC_Wheeled_01_cannon_lxWS", "B_AFV_Wheeled_01_up_cannon_F"];
OT_NATO_Vehicles_Convoy = ["B_ION_Offroad_armed_lxWS", "B_ION_APC_Wheeled_02_hmg_lxWS", "B_ION_Pickup_mmg_rf"] call _have;
OT_NATO_Vehicles_AirWingedSupport = ["I_Plane_Fighter_03_dynamicLoadout_F"];
OT_NATO_Vehicle_AirTransport_Small = "I_Heli_light_03_unarmed_F";
OT_NATO_Vehicle_AirTransport = ["B_ION_Heli_EC_01_RF", "I_Heli_light_03_unarmed_F"] call _have;
OT_NATO_Vehicle_AirTransport_Large = (["B_ION_Heli_EC_01_RF", "I_Heli_Transport_02_F"] call _have) select 0;
OT_NATO_Vehicle_Boat_Small = "B_Boat_Armed_01_minigun_F";
OT_NATO_Vehicles_APC = ["B_ION_APC_Wheeled_02_hmg_lxWS", "B_ION_APC_Wheeled_01_command_lxWS"];
OT_NATO_Mortar = "B_D_Mortar_01_lxWS";
OT_NATO_Vehicle_HVT = "B_ION_Offroad_lxWS";
OT_NATO_Vehicle_CTRGTransport = "I_Heli_light_03_unarmed_F";
OT_NATO_Vehicles_HQGarrison = (["B_ION_Pickup_aat_rf", "B_ION_Pickup_aat_rf"] call _have) + ["B_D_static_AA_lxWS", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F"];
