/*
    Description:
    The occupier's attack helicopter for an airdrop escort (OT_fnc_NATOairdropEscort): one from its
    template's air support (OT_NATO_Vehicles_AirSupport). When its template has none, there's no escort.
    When none of its template's are in the game (a mod missing), a vanilla one for its side.

    Usage: private _class = call OT_fnc_NATOattackHelicopter;

    Returns: STRING - Helicopter class, "" when it has none
*/

private _list = missionNamespace getVariable ["OT_NATO_Vehicles_AirSupport", []];
if (_list isEqualTo []) exitWith { "" };

private _cfg = configFile >> "CfgVehicles";
private _helis = _list select { isClass (_cfg >> _x) && { _x isKindOf "Helicopter" } };
if (_helis isNotEqualTo []) exitWith { selectRandom _helis };

// CfgFactionClasses side: 0 OPFOR, 1 BLUFOR, 2 independent
private _fallback = ["O_Heli_Attack_02_dynamicLoadout_F", "B_Heli_Attack_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F"] param [missionNamespace getVariable ["OT_NATO_factionSide", 1], "B_Heli_Attack_01_dynamicLoadout_F"];
if (isClass (_cfg >> _fallback)) exitWith { _fallback };
"";
