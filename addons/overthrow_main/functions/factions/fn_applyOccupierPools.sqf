/*
    Description:
    Builds the lists that depend on which faction occupies the island, from the weapons, gear and
    vehicles initVar collected for every faction (OT_factionPools, OT_factionVehicles):
    - OT_allBLU* weapons (supply crates, faction weapon jobs) from the occupier's factions
    - OT_allBLUOffensiveVehicles / OT_allBLUVehicles from every faction on the occupier's side
    - the pools for "Randomize NATO loadouts": the occupier's own factions ("faction random")
      or everything in the game ("fully random", lobby setting "ot_randomloadoutpool")
    Run by initVar, and again by OT_fnc_applyOccupier when the occupier changes.

    Usage: call OT_fnc_applyOccupierPools;
*/

if (isNil "OT_factionPools") exitWith {}; // initVar hasn't run yet, it calls this at its end

private _cfgFactions = configFile >> "CfgFactionClasses";
private _cfgWeapons = configFile >> "CfgWeapons";

// The occupier's side (the units still fight on the BLUFOR side), and its CfgGroups folder
OT_NATO_factionSide = getNumber (_cfgFactions >> OT_faction_NATO >> "side");
OT_NATO_groupSide = ["East", "West", "Indep"] param [OT_NATO_factionSide, "West"];

// Its own factions: the main one, the one vehicles fall back to, and the police
OT_occupierFactions = [OT_faction_NATO, OT_fallback_faction_NATO, getText (configFile >> "CfgVehicles" >> OT_NATO_Unit_Police >> "faction")];
private _sideFactions = (keys OT_factionPools) select { getNumber (_cfgFactions >> _x >> "side") isEqualTo OT_NATO_factionSide };

private _merge = {
    private _merged = call OT_newLoadoutPool;
    {
        private _factionPool = OT_factionPools getOrDefault [_x, createHashMap];
        {
            (_merged get _x) append (_factionPool getOrDefault [_x, []]);
        } forEach (keys _merged);
    } forEach _this;
    {
        _merged set [_x, (_merged get _x) arrayIntersect (_merged get _x)];
    } forEach (keys _merged);
    _merged;
};
private _poolOccupier = OT_occupierFactions call _merge;

// The occupier's own weapons, also used for supply crates and faction weapon jobs
OT_allBLURifles = _poolOccupier get "rifles";
OT_allBLUGLRifles = _poolOccupier get "glRifles";
OT_allBLUMachineGuns = _poolOccupier get "machineGuns";
OT_allBLUSniperRifles = _poolOccupier get "sniperRifles";
OT_allBLULaunchers = _poolOccupier get "launchers";
OT_allBLUPistols = _poolOccupier get "handguns";
OT_allBLUSMG = _poolOccupier get "smgs";
OT_allBLURifleMagazines = [];
{
    OT_allBLURifleMagazines append getArray (_cfgWeapons >> _x >> "magazines");
} forEach OT_allBLURifles;
OT_allBLURifleMagazines = OT_allBLURifleMagazines arrayIntersect OT_allBLURifleMagazines;

// Vehicles of the occupier's side (initNATO picks the occupier's own from these)
OT_allBLUOffensiveVehicles = [];
OT_allBLUVehicles = [];
{
    (OT_factionVehicles getOrDefault [_x, [[], []]]) params ["_offensive", "_other"];
    OT_allBLUOffensiveVehicles append _offensive;
    OT_allBLUVehicles append _other;
} forEach _sideFactions;

// Both are kept (the QA tests go through them), OT_randomLoadoutPool is the one in use
private _poolSetting = ["ot_randomloadoutpool", 0] call BIS_fnc_getParamValue;
OT_randomLoadoutPools = [_poolOccupier, OT_loadoutPoolAll];
OT_randomLoadoutPool = OT_randomLoadoutPools select (_poolSetting > 0);
