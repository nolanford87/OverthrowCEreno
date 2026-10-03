/*
    Description:
    Does the resistance own a drug operation (its business is on "GEURowned")? Only owned operations
    build heat and get raided (OT_fnc_drugHeat, OT_fnc_drugRaidChance).

    Parameters:
        _this # 0: STRING - Operation id

    Usage: if ([_opId] call OT_fnc_drugOpOwned) then { ... };

    Returns: BOOL
*/

params ["_opId"];

private _name = [_opId] call OT_fnc_drugOpBusiness;
_name isNotEqualTo "" && { _name in (server getVariable ["GEURowned", []]) }
