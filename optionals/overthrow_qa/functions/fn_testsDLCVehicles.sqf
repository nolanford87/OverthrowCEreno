/*
    Description:
    Vanilla occupiers get their side's official DLC vehicles (OT_fnc_occupierDLCVehicles), owned or
    not: applies each vanilla "Occupying faction" option and checks the DLC vehicles are in its
    pools and exist. Puts the save's own occupier back at the end. Part of the current QA tests.

    Returns: ARRAY - [[name, code], ...]
*/

[
    ["Vanilla occupiers have their side's DLC vehicles", {
        private _saveChoice = server getVariable ["OT_occupier", 0];
        {
            _x params ["_value", "_label", "_expect"];
            private _applied = [_value] call OT_fnc_applyOccupier;
            if (_applied isNotEqualTo _value) then {
                [format ["%1: DLC vehicles", _label], false, format ["option %1 applied as %2", _value, _applied]] call OTQA_fnc_check;
                continue;
            };
            private _missing = [];
            private _absent = [];
            {
                _x params ["_var", "_class"];
                private _list = missionNamespace getVariable [_var, []];
                if !(isClass (configFile >> "CfgVehicles" >> _class)) then { _missing pushBack _class };
                if ((_list findIf { _x isEqualTo _class || { _x isEqualType [] && { (_x select 0) isEqualTo _class } } }) isEqualTo -1) then { _absent pushBack format ["%1 in %2", _class, _var] };
            } forEach _expect;
            [format ["%1: DLC vehicles in its pools", _label], _absent isEqualTo [] && { _missing isEqualTo [] },
                format ["not in the pools: %1; no such class: %2", _absent, _missing]] call OTQA_fnc_check;
        } forEach [
            [1, "NATO", [
                ["OT_NATO_Vehicles_GroundSupport", "B_LSV_01_AT_F"],
                ["OT_NATO_Vehicles_TankSupport", "B_AFV_Wheeled_01_up_cannon_F"],
                ["OT_NATO_Vehicles_AirGarrison", "B_T_VTOL_01_armed_blue_F"],
                ["OT_NATO_Vehicles_JetGarrison", "B_UAV_05_F"],
                ["OT_NATO_Vehicles_AirWingedSupport", "B_Plane_Fighter_01_Stealth_F"]
            ]],
            [2, "NATO Pacific", [
                ["OT_NATO_Vehicles_Convoy", "B_T_LSV_01_AT_F"],
                ["OT_NATO_Vehicles_TankSupport", "B_T_AFV_Wheeled_01_cannon_F"],
                ["OT_NATO_Vehicles_AirGarrison", "B_T_VTOL_01_armed_F"]
            ]],
            [3, "NATO Woodland", [
                ["OT_NATO_Vehicles_TankSupport", "B_T_AFV_Wheeled_01_up_cannon_F"],
                ["OT_NATO_Vehicles_AirGarrison", "B_T_VTOL_01_infantry_olive_F"]
            ]],
            [14, "CSAT", [
                ["OT_NATO_Vehicles_GroundSupport", "O_LSV_02_AT_F"],
                ["OT_NATO_Vehicles_TankSupport", "O_MBT_02_railgun_F"],
                ["OT_NATO_Vehicles_TankSupport", "O_MBT_04_command_F"],
                ["OT_NATO_Vehicles_AirGarrison", "O_T_VTOL_02_infantry_grey_F"],
                ["OT_NATO_Vehicles_AirWingedSupport", "O_Plane_Fighter_02_Stealth_F"]
            ]],
            [15, "CSAT Pacific", [
                ["OT_NATO_Vehicles_TankSupport", "O_T_MBT_02_railgun_ghex_F"],
                ["OT_NATO_Vehicles_AirGarrison", "O_T_VTOL_02_vehicle_dynamicLoadout_F"]
            ]],
            [16, "AAF", [
                ["OT_NATO_Vehicles_GroundSupport", "I_LT_01_AT_F"]
            ]],
            [17, "LDF", [
                ["OT_NATO_Vehicles_GroundSupport", "I_LT_01_cannon_F"],
                ["OT_NATO_Vehicles_Convoy", "I_LT_01_AT_F"]
            ]]
        ];
        [_saveChoice] call OT_fnc_applyOccupier;
        ["Vanilla DLC vehicles: the save's own occupier is back", OT_occupierApplied isEqualTo _saveChoice || { OT_occupierChoice isEqualTo _saveChoice }, OT_NATO_name] call OTQA_fnc_check;
    }]
]
