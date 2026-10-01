/*
    Description:
    Writes the creator DLC factions (S.O.G. Prairie Fire, Western Sahara, Expeditionary Forces,
    Global Mobilization, CSLA Iron Curtain, Spearhead 1944, Reaction Forces) to the RPT, to build
    occupier templates from: their factions, units, vehicles, flags and flag markers. Creator DLC
    files are encrypted, the game is the only place to read their config. Lines start "OTDUMP|".
    Load the creator DLCs to dump. Archived: no longer in the Zeus menu, run it from the debug console.

    Usage: [] spawn OTQA_fnc_dumpFactions;
*/

private _mods = ["vn", "ws", "ef", "gm", "csla", "spe", "rf"];
private _modOf = { toLowerANSI (configSourceMod _this) };
hint "Overthrow QA: dumping creator DLC factions to the RPT...";
diag_log format ["OTDUMP|START|%1", (getLoadedModsInfo select { (toLowerANSI (_x select 1)) in _mods }) apply { _x select 1 }];

// Factions
{
    private _mod = _x call _modOf;
    if (_mod in _mods) then {
        diag_log format ["OTDUMP|F|%1|%2|%3|%4", configName _x, getText (_x >> "displayName"), getNumber (_x >> "side"), _mod];
    };
} forEach ("true" configClasses (configFile >> "CfgFactionClasses"));

// Flag markers
{
    private _mod = _x call _modOf;
    if (_mod in _mods && { getText (_x >> "markerClass") isEqualTo "Flags" }) then {
        diag_log format ["OTDUMP|M|%1|%2|%3", configName _x, getText (_x >> "name"), _mod];
    };
} forEach ("true" configClasses (configFile >> "CfgMarkers"));

// Units and vehicles: kind, whether it's armed, troop seats
private _kinds = ["CAManBase", "Car", "Wheeled_APC_F", "Tank", "Helicopter", "VTOL_Base_F", "Plane", "Ship", "StaticWeapon", "FlagCarrier", "Motorcycle"];
private _n = 0;
{
    private _cfg = _x;
    private _mod = _cfg call _modOf;
    if (_mod in _mods && { getNumber (_cfg >> "scope") isEqualTo 2 }) then {
        private _cls = configName _cfg;
        private _kind = (_kinds select { _cls isKindOf _x }) joinString "/";
        if (_kind isEqualTo "") then { continue };
        private _weapons = getArray (_cfg >> "weapons") select { !(_x in ["Throw", "Put"]) };
        private _armed = false;
        if !(_cls isKindOf "CAManBase") then {
            {
                private _tc = [_cfg, _x] call BIS_fnc_turretConfig;
                if ((getArray (_tc >> "weapons")) findIf { !(["horn", toLowerANSI _x] call BIS_fnc_inString) && { !(["smoke", toLowerANSI _x] call BIS_fnc_inString) } && { !(["flare", toLowerANSI _x] call BIS_fnc_inString) } && { !(["laserdesignator", toLowerANSI _x] call BIS_fnc_inString) } } > -1) exitWith { _armed = true };
            } forEach ([_cls, true] call BIS_fnc_allTurrets);
            if (_weapons findIf { !(["horn", toLowerANSI _x] call BIS_fnc_inString) && { !(["flare", toLowerANSI _x] call BIS_fnc_inString) } && { !(["smoke", toLowerANSI _x] call BIS_fnc_inString) } } > -1) then { _armed = true };
            if (isClass (_cfg >> "Components" >> "TransportPylonsComponent")) then { _armed = true };
        };
        diag_log format ["OTDUMP|V|%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11",
            _cls, getText (_cfg >> "faction"), getNumber (_cfg >> "side"), _mod, _kind,
            getText (_cfg >> "displayName"), getText (_cfg >> "editorSubcategory"),
            getNumber (_cfg >> "transportSoldier"), _armed, _weapons joinString ",", getText (_cfg >> "vehicleClass")];
        _n = _n + 1;
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

diag_log format ["OTDUMP|DONE|%1", _n];
hint format ["Overthrow QA: %1 creator DLC units and vehicles written to the RPT", _n];
