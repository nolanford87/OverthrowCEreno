/*
    Description:
    The occupier spends resources on new vehicles for its bases (vehicle garrisons), like
    OT_fnc_NATOupgradeGarrisons does for soldiers. Only for bases no player is near, the vehicle
    appears the next time the base spawns. Armed cars and MRAPs for any base, APCs for the
    bigger ones. At most one vehicle a turn, and 2 more than a base of its value starts with.

    Parameters:
        _spend - The current spending limit
        _chance - Higher is less likely to buy

    Usage: _spend = [_spend, _chance] call OT_fnc_NATOupgradeVehicleGarrisons;

    Returns: Scalar - How much is left to spend
*/

params ["_spend", "_chance"];

private _costLight = 250;
private _costAPC = 400;
if (_spend < _costLight) exitWith { _spend };

// The occupier's own armed ground vehicles, like initNATO picks for new games
private _cfgVehicles = configFile >> "CfgVehicles";
private _isGround = { !((_x isKindOf "Air") || { _x isKindOf "Tank" } || { _x isKindOf "Ship" }) };
private _light = OT_allBLUOffensiveVehicles select { getText (_cfgVehicles >> _x >> "faction") == OT_faction_NATO && _isGround };
if (_light isEqualTo []) then {
    _light = OT_allBLUOffensiveVehicles select { getText (_cfgVehicles >> _x >> "faction") == OT_fallback_faction_NATO && _isGround };
};
_light = (_light + OT_NATO_Vehicles_GroundSupport) select { !(_x in OT_NATO_Vehicles_APC) };
private _apcs = +OT_NATO_Vehicles_APC;

private _resources = server getVariable ["NATOresources", 2000];
private _abandoned = server getVariable ["NATOabandoned", []];

{
    _x params ["_pos", "_name", "_worth"];
    if (_name in _abandoned) then { continue };

    // Vehicles it has now (not counting static guns). Room for the most a base of its value starts
    // with (initNATO: 1, 2 or 3 by value, 2 at the HQ) plus 2 bought ones
    private _garrison = server getVariable [format ["vehgarrison%1", _name], []];
    private _vehicles = { !(_x isKindOf "StaticWeapon") && { _x isKindOf "LandVehicle" } } count _garrison;
    private _max = 1;
    if (_worth > 500) then { _max = 2 };
    if (_worth > 1000) then { _max = 3 };
    if (_name isEqualTo OT_NATO_HQ) then { _max = 2 };
    _max = _max + 2;
    if (_vehicles >= _max || { random 100 < _chance } || { [_pos] call OT_fnc_inSpawnDistance }) then { continue };

    private _useAPC = _worth > 1000 && { _apcs isNotEqualTo [] } && { _spend >= _costAPC } && { random 100 < 40 };
    if (!_useAPC && { _light isEqualTo [] }) then { continue };
    private _type = selectRandom ([_light, _apcs] select _useAPC);
    private _cost = [_costLight, _costAPC] select _useAPC;

    _garrison pushBack _type;
    server setVariable [format ["vehgarrison%1", _name], _garrison, true];
    _spend = _spend - _cost;
    _resources = _resources - _cost;
    diag_log format ["Overthrow: %1 bought a %2 for %3", OT_NATO_name, _type call OT_fnc_vehicleGetName, _name];
    break;
} forEach ((OT_objectiveData + OT_airportData) call BIS_fnc_arrayShuffle); // No base goes first every time

server setVariable ["NATOresources", _resources];

_spend;
