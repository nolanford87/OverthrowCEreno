/*
    Description:
    The occupier's unit class for a mayor's office guard role: the police for the gendarmes, the
    occupier's infantry (OT_NATO_Units_LevelTwo, by their config role) for the military ones, with
    the sniper and the police to fall back on. Server (after the occupier is set up).

    Parameters:
        _this # 0: STRING - Role: "gendarme", "rifleman", "autorifleman", "mg_gunner", "marksman", "at" or "officer"

    Usage: private _class = ["marksman"] call OT_fnc_officeGuardClass;

    Returns: STRING - Unit class
*/

params [["_role", "rifleman", [""]]];

// The first of the occupier's infantry with one of these config roles, "" when it has none
private _byRole = {
    params ["_wanted"];
    private _units = missionNamespace getVariable ["OT_NATO_Units_LevelTwo", []];
    private _found = _units select { (toLower getText (configFile >> "CfgVehicles" >> _x >> "role")) in _wanted };
    _found param [0, ""]
};

private _class = switch (_role) do {
    case "gendarme": { OT_NATO_Unit_Police };
    case "officer": { OT_NATO_Unit_HVT };
    case "marksman": {
        private _c = [["marksman"]] call _byRole;
        [_c, OT_NATO_Unit_Sniper] select (_c isEqualTo "")
    };
    case "at": { [["missilespecialist"]] call _byRole };
    case "autorifleman";
    case "mg_gunner": { [["machinegunner"]] call _byRole };
    default { [["rifleman"]] call _byRole };
};
if (_class isEqualTo "") then { _class = [["rifleman", "machinegunner", "grenadier", "combatlifesaver"]] call _byRole };
if (_class isEqualTo "") then { _class = OT_NATO_Unit_Police };
_class
