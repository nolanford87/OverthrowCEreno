/*
    Description:
    The heat hook the drug operations call for everything they sell or make (OT_fnc_dispensaryCycle,
    OT_fnc_drugLabCycle): adds the occupier's heat on the operation, OT_drugHeatPerUnit per unit
    (blow 3, ganja 1), if the resistance owns it (OT_fnc_drugOpOwned). Heat decays over real time
    (OT_fnc_drugHeatTick) and, with low stability in the operation's town, brings raids
    (OT_fnc_drugRaidCheck). The gang turf hook (OT_fnc_drugTurf, drugs slice 3b) hears every call too.

    Parameters:
        _this # 0: STRING - Operation id ("Kavala Dispensary", "lab0")
        _this # 1: STRING - "ganja" or "blow"
        _this # 2: NUMBER - Units sold or made

    Usage: [_opId, "blow", _qty] call OT_fnc_drugHeat; (server)

    Returns: NUMBER - The operation's heat now
*/

params ["_opId", "_kind", ["_qty", 0]];

if (isServer && { _qty > 0 } && { [_opId] call OT_fnc_drugOpOwned }) then {
    private _heat = ([_opId] call OT_fnc_drugHeatGet) select 0;
    [_opId, _heat + (_qty * (OT_drugHeatPerUnit getOrDefault [_kind, 1]))] call OT_fnc_drugHeatSet;
};

// Gang turf (slice 3b) hears every sale and batch as well, when it's there
private _turf = missionNamespace getVariable "OT_fnc_drugTurf";
if (!isNil "_turf") then { [_opId, _kind, _qty] call _turf };

([_opId] call OT_fnc_drugHeatGet) select 0
