/*
    Occupier template: NATO (Overthrow's own setup, the maps use one of these by default).
    Run by OT_fnc_applyOccupier over the map's own setup, it only needs to set what differs.

    Parameters:
        _this # 0: STRING - Camo: "arid" (Altis, Malden), "pacific" (Tanoa) or "woodland" (Livonia)
*/

params [["_camo", "arid"]];

OT_NATO_name = "NATO";
OT_NATO_markerFlag = "flag_NATO";
OT_flag_NATO = "Flag_NATO_F";

switch (_camo) do {
    case "pacific": {
        OT_faction_NATO = "BLU_T_F";
        OT_fallback_faction_NATO = "BLU_F"; // If there were no vehicles in the first faction, take them from this faction
        OT_NATO_HMG = "B_HMG_01_high_F";
        OT_NATO_Vehicles_AirGarrison = [
            ["B_T_VTOL_01_vehicle_F", 1],
            ["B_T_VTOL_01_infantry_F", 1],
            ["B_Heli_Light_01_armed_F", 1],
            ["B_Heli_Transport_03_unarmed_F", 2],
            ["B_Heli_Light_01_F", 3],
            ["B_Heli_Attack_01_F", 1],
            ["B_Heli_Transport_01_F", 2]
        ];

        OT_NATO_Vehicles_StaticAAGarrison = [
            "B_T_Static_AA_F",
            "B_T_Static_AA_F"
        ]; //Added to every airfield

        OT_NATO_Vehicles_JetGarrison = [
            ["B_Plane_CAS_01_F", 1]
        ];

        if (OT_hasJetsDLC) then {
            OT_NATO_Vehicles_JetGarrison pushBack ["B_Plane_Fighter_01_F", 1];
            OT_NATO_Vehicles_JetGarrison pushBack ["B_Plane_Fighter_01_Stealth_F", 1];
            OT_NATO_Vehicles_StaticAAGarrison pushBack "B_Radar_System_01_F";
            OT_NATO_Vehicles_StaticAAGarrison pushBack "B_SAM_System_03_F";
        };

        OT_NATO_StaticGarrison_LevelOne = ["B_HMG_01_high_F"];
        OT_NATO_StaticGarrison_LevelTwo = ["B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_T_MRAP_01_hmg_F"];
        OT_NATO_StaticGarrison_LevelThree = ["B_T_Static_AT_F", "B_T_Static_AA_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_T_MRAP_01_hmg_F", "B_T_MRAP_01_gmg_F"];

        OT_NATO_CommTowers = ["Land_TTowerBig_1_F", "Land_TTowerBig_2_F"];

        OT_NATO_Unit_Sniper = "B_T_Sniper_F";
        OT_NATO_Unit_Spotter = "B_T_Spotter_F";
        OT_NATO_Unit_AA_spec = "B_T_Soldier_AA_F";
        OT_NATO_Unit_AA_ass = "B_T_Soldier_AAA_F";
        OT_NATO_Unit_HVT = "B_T_Officer_F";
        OT_NATO_Unit_TeamLeader = "B_T_Soldier_TL_F";
        OT_NATO_Unit_SquadLeader = "B_T_Soldier_SL_F";

        OT_NATO_Unit_PoliceCommander = "B_Gen_Commander_F";
        OT_NATO_Unit_PoliceCommander_Heavy = "B_Gen_Commander_Heavy_F";
        OT_NATO_Unit_Police = "B_Gen_Soldier_F";
        OT_NATO_Unit_Police_Heavy = "B_Gen_Soldier_Heavy_F";
        OT_NATO_Unit_PoliceMedic_Heavy = "B_Gen_Medic_Heavy_F";
        OT_NATO_Vehicle_PoliceHeli = "B_Heli_Light_01_F";
        OT_NATO_Vehicle_Quad = "B_Quadbike_01_F";
        OT_NATO_Vehicle_Police = "B_GEN_Offroad_01_gen_F";
        OT_NATO_Vehicle_Transport = ["B_T_Truck_01_transport_F", "B_T_Truck_01_covered_F"];
        OT_NATO_Vehicle_Transport_Light = "B_T_LSV_01_unarmed_F";
        OT_NATO_Vehicles_PoliceSupport = ["B_T_MRAP_01_hmg_F", "B_T_MRAP_01_gmg_F", "B_T_LSV_01_armed_F", "B_Heli_Light_01_armed_F"];
        OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
        OT_NATO_Vehicles_CASDrone = "B_UAV_02_CAS_F";
        OT_NATO_Vehicles_AirSupport = ["B_Heli_Attack_01_F"];
        OT_NATO_Vehicles_AirSupport_Small = ["B_Heli_Light_01_armed_F"];
        OT_NATO_Vehicles_GroundSupport = ["B_T_MRAP_01_gmg_F", "B_T_MRAP_01_hmg_F", "B_T_LSV_01_armed_F"];
        OT_NATO_Vehicles_TankSupport = ["B_T_MBT_01_TUSK_F", "B_T_MBT_01_cannon_F"];
        OT_NATO_Vehicles_Convoy = ["B_T_UGV_01_rcws_olive_F", "B_T_MRAP_01_hmg_F", "B_T_LSV_01_armed_F", "B_T_LSV_01_armed_F", "B_T_LSV_01_armed_F"];
        OT_NATO_Vehicles_AirWingedSupport = ["B_Plane_Fighter_01_F"];
        OT_NATO_Vehicle_AirTransport_Small = "B_Heli_Transport_01_camo_F";
        OT_NATO_Vehicle_AirTransport = ["B_Heli_Transport_03_F", "B_Heli_Transport_01_F", "B_Heli_Transport_01_F"];
        OT_NATO_Vehicle_AirTransport_Large = "B_Heli_Transport_03_F";
        OT_NATO_Vehicle_Boat_Small = "B_T_Boat_Armed_01_minigun_F";
        OT_NATO_Vehicles_APC = ["B_T_APC_Wheeled_01_cannon_F"];

        OT_NATO_Sandbag_Curved = "Land_BagFence_01_round_green_F";
        OT_NATO_Barrier_Small = "Land_HBarrier_01_line_5_green_F";
        OT_NATO_Barrier_Large = "Land_HBarrier_01_wall_6_green_F";

        OT_NATO_Mortar = "B_T_Mortar_01_F";

        OT_NATO_Vehicle_HVT = "B_T_MRAP_01_F";

        OT_NATO_Vehicle_CTRGTransport = "B_CTRG_Heli_Transport_01_tropic_F";

        OT_NATO_weapons_Police = [];
        OT_NATO_weapons_Pistols = ["hgun_Pistol_heavy_01_F", "hgun_ACPC2_F", "hgun_P07_F", "hgun_Rook40_F"];
        OT_NATO_Vehicles_HQGarrison = ["B_T_APC_Tracked_01_AA_F", "B_T_APC_Tracked_01_AA_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F"];
    };
    case "woodland": {
        OT_faction_NATO = "BLU_W_F";
        OT_fallback_faction_NATO = "BLU_T_F"; // If there were no vehicles in the first faction, take them from this faction
        OT_NATO_HMG = "B_HMG_01_high_F";
        OT_NATO_Vehicles_AirGarrison = [
            ["B_Heli_Light_01_armed_F", 1],
            ["B_Heli_Transport_03_unarmed_F", 2],
            ["B_Heli_Light_01_F", 3],
            ["B_Heli_Attack_01_F", 1],
            ["B_Heli_Transport_01_F", 2]
        ];

        OT_NATO_Vehicles_StaticAAGarrison = [
            "B_T_Static_AA_F",
            "B_T_Static_AA_F"
        ]; //Added to every airfield

        OT_NATO_Vehicles_JetGarrison = [
            ["B_Plane_CAS_01_F", 1]
        ];

        if (OT_hasJetsDLC) then {
            OT_NATO_Vehicles_JetGarrison pushBack ["B_Plane_Fighter_01_F", 1];
            OT_NATO_Vehicles_JetGarrison pushBack ["B_Plane_Fighter_01_Stealth_F", 1];
            OT_NATO_Vehicles_StaticAAGarrison pushBack "B_Radar_System_01_F";
            OT_NATO_Vehicles_StaticAAGarrison pushBack "B_SAM_System_03_F";
        };

        OT_NATO_StaticGarrison_LevelOne = ["B_HMG_01_high_F"];
        OT_NATO_StaticGarrison_LevelTwo = ["B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_T_MRAP_01_hmg_F"];
        OT_NATO_StaticGarrison_LevelThree = ["B_T_Static_AT_F", "B_T_Static_AA_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_T_MRAP_01_hmg_F", "B_T_MRAP_01_gmg_F"];

        OT_NATO_CommTowers = ["Land_TTowerBig_1_F", "Land_TTowerBig_2_F"];

        OT_NATO_Unit_Sniper = "B_T_Sniper_F";
        OT_NATO_Unit_Spotter = "B_T_Spotter_F";
        OT_NATO_Unit_AA_spec = "B_W_Soldier_AA_F";
        OT_NATO_Unit_AA_ass = "B_W_Soldier_AAA_F";
        OT_NATO_Unit_HVT = "B_W_Officer_F";
        OT_NATO_Unit_TeamLeader = "B_W_Soldier_TL_F";
        OT_NATO_Unit_SquadLeader = "B_W_Soldier_SL_F";

        OT_NATO_Unit_PoliceCommander = "B_Gen_Commander_F";
        OT_NATO_Unit_PoliceCommander_Heavy = "B_Gen_Commander_Heavy_F";
        OT_NATO_Unit_Police = "B_Gen_Soldier_F";
        OT_NATO_Unit_Police_Heavy = "B_Gen_Soldier_Heavy_F";
        OT_NATO_Unit_PoliceMedic_Heavy = "B_Gen_Medic_Heavy_F";
        OT_NATO_Vehicle_PoliceHeli = "B_Heli_Light_01_F";
        OT_NATO_Vehicle_Quad = "B_Quadbike_01_F";
        OT_NATO_Vehicle_Police = "B_GEN_Offroad_01_gen_F";
        OT_NATO_Vehicle_Transport = ["B_T_Truck_01_transport_F", "B_T_Truck_01_covered_F"];
        OT_NATO_Vehicle_Transport_Light = "B_T_LSV_01_unarmed_F";
        OT_NATO_Vehicles_PoliceSupport = ["B_T_MRAP_01_hmg_F", "B_T_MRAP_01_gmg_F", "B_T_LSV_01_armed_F", "B_Heli_Light_01_armed_F"];
        OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
        OT_NATO_Vehicles_CASDrone = "B_UAV_02_CAS_F";
        OT_NATO_Vehicles_AirSupport = ["B_Heli_Attack_01_F"];
        OT_NATO_Vehicles_AirSupport_Small = ["B_Heli_Light_01_armed_F"];
        OT_NATO_Vehicles_GroundSupport = ["B_T_MRAP_01_gmg_F", "B_T_MRAP_01_hmg_F", "B_T_LSV_01_armed_F"];
        OT_NATO_Vehicles_TankSupport = ["B_T_MBT_01_TUSK_F", "B_T_MBT_01_cannon_F"];
        OT_NATO_Vehicles_Convoy = ["B_T_UGV_01_rcws_olive_F", "B_T_MRAP_01_hmg_F", "B_T_LSV_01_armed_F", "B_T_LSV_01_armed_F", "B_T_LSV_01_armed_F"];
        OT_NATO_Vehicles_AirWingedSupport = ["B_Plane_Fighter_01_F"];
        OT_NATO_Vehicle_AirTransport_Small = "B_Heli_Transport_01_camo_F";
        OT_NATO_Vehicle_AirTransport = ["B_Heli_Transport_03_F", "B_Heli_Transport_01_F", "B_Heli_Transport_01_F"];
        OT_NATO_Vehicle_AirTransport_Large = "B_Heli_Transport_03_F";
        OT_NATO_Vehicle_Boat_Small = "B_T_Boat_Armed_01_minigun_F";
        OT_NATO_Vehicles_APC = ["B_T_APC_Wheeled_01_cannon_F"];

        OT_NATO_Sandbag_Curved = "Land_BagFence_01_round_green_F";
        OT_NATO_Barrier_Small = "Land_HBarrier_01_line_5_green_F";
        OT_NATO_Barrier_Large = "Land_HBarrier_01_wall_6_green_F";

        OT_NATO_Mortar = "B_T_Mortar_01_F";

        OT_NATO_Vehicle_HVT = "B_T_MRAP_01_F";

        OT_NATO_Vehicle_CTRGTransport = "B_CTRG_Heli_Transport_01_tropic_F";

        OT_NATO_weapons_Police = [];
        OT_NATO_weapons_Pistols = ["hgun_Pistol_heavy_01_F", "hgun_ACPC2_F", "hgun_P07_F", "hgun_Rook40_F"];
        OT_NATO_Vehicles_HQGarrison = ["B_T_APC_Tracked_01_AA_F", "B_T_APC_Tracked_01_AA_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F"];
    };
    default {
        OT_faction_NATO = "BLU_F";
        OT_fallback_faction_NATO = "BLU_T_F"; // If there were no vehicles in the first faction, take them from this faction
        OT_NATO_HMG = "B_HMG_01_high_F";
        OT_NATO_Vehicles_AirGarrison = [
            ["B_T_VTOL_01_vehicle_blue_F", 1],
            ["B_T_VTOL_01_infantry_blue_F", 1],
            ["B_Heli_Light_01_armed_F", 1],
            ["B_Heli_Transport_03_unarmed_F", 2],
            ["B_Heli_Light_01_F", 3],
            ["B_Heli_Attack_01_F", 1],
            ["B_Heli_Transport_01_F", 2]
        ];

        OT_NATO_Vehicles_JetGarrison = [
            ["B_Plane_CAS_01_F", 1]
        ];

        OT_NATO_Vehicles_StaticAAGarrison = [
            "B_Static_AA_F",
            "B_Static_AA_F"
        ]; //Added to every airfield

        if (OT_hasJetsDLC) then {
            OT_NATO_Vehicles_JetGarrison pushBack ["B_Plane_Fighter_01_F", 1];
            OT_NATO_Vehicles_JetGarrison pushBack ["B_Plane_Fighter_01_Stealth_F", 1];
            OT_NATO_Vehicles_StaticAAGarrison pushBack "B_Radar_System_01_F";
            OT_NATO_Vehicles_StaticAAGarrison pushBack "B_SAM_System_03_F";
        };

        OT_NATO_StaticGarrison_LevelOne = ["B_HMG_01_high_F"];
        OT_NATO_StaticGarrison_LevelTwo = ["B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_MRAP_01_hmg_F"];
        OT_NATO_StaticGarrison_LevelThree = ["B_Static_AT_F", "B_Static_AA_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_GMG_01_high_F", "B_MRAP_01_hmg_F", "B_MRAP_01_gmg_F"];

        OT_NATO_CommTowers = ["Land_TTowerBig_1_F", "Land_TTowerBig_2_F"];

        OT_NATO_Unit_Sniper = "B_Sniper_F";
        OT_NATO_Unit_Spotter = "B_Spotter_F";
        OT_NATO_Unit_AA_spec = "B_Soldier_AA_F";
        OT_NATO_Unit_AA_ass = "B_Soldier_AAA_F";
        OT_NATO_Unit_HVT = "B_Officer_F";
        OT_NATO_Unit_TeamLeader = "B_Soldier_TL_F";
        OT_NATO_Unit_SquadLeader = "B_Soldier_SL_F";

        OT_NATO_Unit_PoliceCommander = "B_Gen_Commander_F";
        OT_NATO_Unit_PoliceCommander_Heavy = "B_Gen_Commander_Heavy_F";
        OT_NATO_Unit_Police = "B_Gen_Soldier_F";
        OT_NATO_Unit_Police_Heavy = "B_Gen_Soldier_Heavy_F";
        OT_NATO_Unit_PoliceMedic_Heavy = "B_Gen_Medic_Heavy_F";
        OT_NATO_Vehicle_PoliceHeli = "B_Heli_Light_01_F";
        OT_NATO_Vehicle_Quad = "B_Quadbike_01_F";
        OT_NATO_Vehicle_Police = "B_GEN_Offroad_01_gen_F";
        OT_NATO_Vehicle_Transport = ["B_Truck_01_transport_F", "B_Truck_01_covered_F"];
        OT_NATO_Vehicle_Transport_Light = "B_LSV_01_unarmed_F";
        OT_NATO_Vehicles_PoliceSupport = ["B_MRAP_01_hmg_F", "B_MRAP_01_gmg_F", "B_LSV_01_armed_F", "B_Heli_Light_01_armed_F"];
        OT_NATO_Vehicles_ReconDrone = "B_UAV_01_F";
        OT_NATO_Vehicles_CASDrone = "B_UAV_02_CAS_F";
        OT_NATO_Vehicles_AirSupport = ["B_Heli_Attack_01_F"];
        OT_NATO_Vehicles_AirSupport_Small = ["B_Heli_Light_01_armed_F"];
        OT_NATO_Vehicles_GroundSupport = ["B_MRAP_01_gmg_F", "B_MRAP_01_hmg_F", "B_LSV_01_armed_F"];
        OT_NATO_Vehicles_TankSupport = ["B_MBT_01_TUSK_F", "B_MBT_01_cannon_F"];
        OT_NATO_Vehicles_Convoy = ["B_UGV_01_rcws_F", "B_MRAP_01_hmg_F", "B_LSV_01_armed_F", "B_LSV_01_armed_F", "B_LSV_01_armed_F"];
        OT_NATO_Vehicles_AirWingedSupport = ["B_Plane_Fighter_01_F"];
        OT_NATO_Vehicle_AirTransport_Small = "B_Heli_Transport_01_camo_F";
        OT_NATO_Vehicle_AirTransport = ["B_Heli_Transport_03_F", "B_Heli_Transport_01_F", "B_Heli_Transport_01_F"];
        OT_NATO_Vehicle_AirTransport_Large = "B_Heli_Transport_03_F";
        OT_NATO_Vehicle_Boat_Small = "B_Boat_Armed_01_minigun_F";
        OT_NATO_Vehicles_APC = ["B_APC_Wheeled_01_cannon_F"];

        OT_NATO_Sandbag_Curved = "Land_BagFence_01_round_green_F";
        OT_NATO_Barrier_Small = "Land_HBarrier_01_line_5_green_F";
        OT_NATO_Barrier_Large = "Land_HBarrier_01_wall_6_green_F";

        OT_NATO_Mortar = "B_Mortar_01_F";

        OT_NATO_Vehicle_HVT = "B_MRAP_01_F";

        OT_NATO_Vehicle_CTRGTransport = "B_CTRG_Heli_Transport_01_sand_F";

        OT_NATO_weapons_Police = [];
        OT_NATO_weapons_Pistols = ["hgun_Pistol_heavy_01_F", "hgun_ACPC2_F", "hgun_P07_F", "hgun_Rook40_F"];
        OT_NATO_Vehicles_HQGarrison = ["B_APC_Tracked_01_AA_F", "B_APC_Tracked_01_AA_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_GMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F", "B_HMG_01_high_F"];
    };
};
