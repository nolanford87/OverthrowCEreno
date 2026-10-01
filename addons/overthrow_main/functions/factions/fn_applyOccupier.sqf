/*
    Description:
    Sets up the occupying faction chosen in the lobby ("Occupying faction", ot_enemy_faction).
    Puts the map's own setup back (from mission initVar), runs the chosen template from
    \overthrow_main\occupiers over it, then rebuilds the lists that depend on the occupier.
    A template whose faction isn't loaded (e.g. RHS without the mod) falls back to the map's setup.

    The server applies the lobby choice before initVar, then the one stored in the save
    (server variable "OT_occupier") once a game is started or loaded. Clients do the same.

    Parameters:
        _this # 0: NUMBER - Lobby value of "Occupying faction" (0 is the map's own setup)

    Usage: [2] call OT_fnc_applyOccupier;

    Returns: NUMBER - The value applied (0 when the chosen faction isn't loaded)
*/

params [["_choice", 0, [0]]];

// Lobby value: [template file, faction it needs, template parameters]
// Keep the values, saves and server configs store them
private _templates = [
    ["", ""],                                                   // 0 Map default
    ["nato.sqf", "BLU_F", ["arid"]],                            // 1 NATO
    ["nato.sqf", "BLU_T_F", ["pacific"]],                       // 2 NATO Pacific
    ["nato.sqf", "BLU_W_F", ["woodland"]],                      // 3 NATO Woodland
    ["rhs_usarmy.sqf", "rhs_faction_usarmy_wd", ["wd"]],       // 4 RHS US Army Woodland
    ["rhs_usarmy.sqf", "rhs_faction_usarmy_d", ["d"]],         // 5 RHS US Army Desert
    ["rhs_usmc.sqf", "rhs_faction_usmc_wd", ["wd"]],           // 6 RHS USMC Woodland
    ["rhs_usmc.sqf", "rhs_faction_usmc_d", ["d"]],             // 7 RHS USMC Desert
    ["rhs_hidf.sqf", "rhsgref_faction_hidf", []],              // 8 RHS Horizon Islands Defence Force
    ["uk3cb_aaf.sqf", "UK3CB_AAF_B", []],                       // 9 3CB AAF
    ["uk3cb_ldf.sqf", "UK3CB_LDF_B", []],                       // 10 3CB LDF
    ["uk3cb_lsm.sqf", "UK3CB_LSM_B", []],                       // 11 3CB LSM
    ["uk3cb_mdf.sqf", "UK3CB_MDF_B", []],                       // 12 3CB MDF
    ["uk3cb_mei.sqf", "UK3CB_MEI_B", []],                       // 13 3CB MEI
    ["csat.sqf", "OPF_F", ["arid"]],                            // 14 CSAT
    ["csat.sqf", "OPF_T_F", ["pacific"]],                       // 15 CSAT Pacific
    ["aaf.sqf", "IND_F", []],                                   // 16 AAF
    ["ldf.sqf", "IND_E_F", []],                                 // 17 LDF
    ["rhs_msv.sqf", "rhs_faction_msv", []],                   // 18 RHS Russia (MSV)
    // Creator DLCs
    ["ws_una.sqf", "BLU_UN_lxWS", []],                          // 19 Western Sahara UNA
    ["ws_ion.sqf", "BLU_ION_lxWS", []],                         // 20 Western Sahara ION Services
    ["ws_nato.sqf", "BLU_NATO_lxWS", []],                       // 21 Western Sahara NATO (Desert)
    ["ws_sfia.sqf", "OPF_SFIA_lxWS", []],                       // 22 Western Sahara SFIA
    ["ws_tura.sqf", "BLU_TURA_lxWS", []],                       // 23 Western Sahara Tura
    ["ef_mjtf.sqf", "EF_B_MJTF_Des", ["Des"]],                  // 24 Expeditionary Forces MJTF (Desert)
    ["ef_mjtf.sqf", "EF_B_MJTF_Wdl", ["Wdl"]]                   // 25 Expeditionary Forces MJTF (Woodland)
];

// The map's own setup, saved the first time so a template can be swapped for another
private _isOccupierVar = { ((_this select [0, 8]) isEqualTo "ot_nato_") || { _this in ["ot_faction_nato", "ot_fallback_faction_nato", "ot_flag_nato"] } };
if (isNil "OT_occupierMapDefault") then {
    OT_occupierMapDefault = [];
    {
        private _value = missionNamespace getVariable _x;
        if (!isNil "_value" && { _x call _isOccupierVar }) then {
            if (_value isEqualType []) then { _value = +_value };
            OT_occupierMapDefault pushBack [_x, _value];
        };
    } forEach (allVariables missionNamespace);
};
{
    _x params ["_var", "_value"];
    if (_value isEqualType []) then { _value = +_value };
    missionNamespace setVariable [_var, _value];
} forEach OT_occupierMapDefault;

OT_occupierChoice = _choice; // What was asked for, _choice becomes what could be applied
(_templates param [_choice, _templates # 0]) params ["_file", "_faction", ["_args", []]];
if (_faction isNotEqualTo "" && { !isClass (configFile >> "CfgFactionClasses" >> _faction) }) then {
    diag_log format ["Overthrow: Occupying faction %1 (%2) isn't loaded, using the map's own", _choice, _faction];
    _file = "";
    _choice = 0;
};
if (_file isNotEqualTo "") then {
    _args call compileScript ["\overthrow_main\occupiers\" + _file];
};
diag_log format ["Overthrow: Occupying faction %1: %2 (%3)", _choice, OT_NATO_name, OT_faction_NATO];

// A vanilla occupier gets its side's official DLC vehicles too, owned or not
if (_choice in [0, 1, 2, 3, 14, 15, 16, 17]) then { call OT_fnc_occupierDLCVehicles };

OT_occupierApplied = _choice;
call OT_fnc_applyOccupierPools;
_choice;
