/*
    Description:
    Gives a vanilla occupier (the map's own NATO, NATO, CSAT, AAF or LDF) the vehicles of its side from
    the official DLCs, whether or not the players own them (AI crews them either way):
    - NATO: Prowler AT (Apex), Rhino MGS and Rhino MGS UP (Tanks), Blackfish gunship and transports
      (Apex), Black Wasp II Stealth and Sentinel UCAV (Jets)
    - CSAT: Qilin AT and Xi'an transports (Apex), T-100X Futura (Apex), T-140K Angara (Tanks),
      Shikra Stealth (Jets)
    - AAF and LDF: AWC Nyx autocannon and AT (Tanks)
    Added to the pools by role: armed cars to ground support and convoys, tanks and the Rhino to the
    tanks, VTOLs to the parked aircraft at airfields, jets to the jets. The Rhino has no seats for
    troops, so it isn't an APC here.
    Run by OT_fnc_applyOccupier after the template, it picks the side and camo from OT_faction_NATO.

    Usage: call OT_fnc_occupierDLCVehicles;
*/

private _add = {
    params ["_var", "_classes"];
    private _list = missionNamespace getVariable [_var, []];
    { _list pushBackUnique _x } forEach _classes;
    missionNamespace setVariable [_var, _list];
};
// Aircraft parked at airfields are [class, how many]
private _addParked = {
    params ["_var", "_pairs"];
    private _list = missionNamespace getVariable [_var, []];
    {
        private _class = _x select 0;
        if ((_list findIf { (_x select 0) isEqualTo _class }) isEqualTo -1) then { _list pushBack _x };
    } forEach _pairs;
    missionNamespace setVariable [_var, _list];
};

switch (OT_faction_NATO) do {
    case "BLU_F";
    case "BLU_T_F";
    case "BLU_W_F": {
        private _arid = OT_faction_NATO isEqualTo "BLU_F";
        private _p = ["B_T_", "B_"] select _arid;
        private _vtol = ["_F", "_blue_F"] select _arid;
        if (OT_faction_NATO isEqualTo "BLU_W_F") then { _vtol = "_olive_F" };
        ["OT_NATO_Vehicles_GroundSupport", [_p + "LSV_01_AT_F"]] call _add;
        ["OT_NATO_Vehicles_Convoy", [_p + "LSV_01_AT_F"]] call _add;
        ["OT_NATO_Vehicles_TankSupport", [_p + "AFV_Wheeled_01_cannon_F", _p + "AFV_Wheeled_01_up_cannon_F"]] call _add;
        ["OT_NATO_Vehicles_AirGarrison", [
            ["B_T_VTOL_01_armed" + _vtol, 1],
            ["B_T_VTOL_01_infantry" + _vtol, 1],
            ["B_T_VTOL_01_vehicle" + _vtol, 1]
        ]] call _addParked;
        ["OT_NATO_Vehicles_JetGarrison", [["B_Plane_Fighter_01_Stealth_F", 1], ["B_UAV_05_F", 1]]] call _addParked;
        ["OT_NATO_Vehicles_AirWingedSupport", ["B_Plane_Fighter_01_Stealth_F"]] call _add;
    };
    case "OPF_F";
    case "OPF_T_F": {
        private _hex = OT_faction_NATO isEqualTo "OPF_T_F";
        ["OT_NATO_Vehicles_GroundSupport", [["O_LSV_02_AT_F", "O_T_LSV_02_AT_F"] select _hex]] call _add;
        ["OT_NATO_Vehicles_Convoy", [["O_LSV_02_AT_F", "O_T_LSV_02_AT_F"] select _hex]] call _add;
        ["OT_NATO_Vehicles_TankSupport", [
            ["O_MBT_02_railgun_F", "O_T_MBT_02_railgun_ghex_F"] select _hex,
            ["O_MBT_04_command_F", "O_T_MBT_04_command_F"] select _hex
        ]] call _add;
        ["OT_NATO_Vehicles_AirGarrison", [
            [["O_T_VTOL_02_infantry_grey_F", "O_T_VTOL_02_infantry_dynamicLoadout_F"] select _hex, 1],
            [["O_T_VTOL_02_vehicle_grey_F", "O_T_VTOL_02_vehicle_dynamicLoadout_F"] select _hex, 1]
        ]] call _addParked;
        ["OT_NATO_Vehicles_JetGarrison", [["O_Plane_Fighter_02_Stealth_F", 1]]] call _addParked;
        ["OT_NATO_Vehicles_AirWingedSupport", ["O_Plane_Fighter_02_Stealth_F"]] call _add;
    };
    case "IND_F";
    case "IND_E_F": {
        ["OT_NATO_Vehicles_GroundSupport", ["I_LT_01_cannon_F", "I_LT_01_AT_F"]] call _add;
        ["OT_NATO_Vehicles_Convoy", ["I_LT_01_cannon_F", "I_LT_01_AT_F"]] call _add;
    };
};
