/*
    Description:
    The headquarters and bases worth over 1000 trade in one of their light vehicles (armed cars,
    MRAPs, APCs) for heavy armour (a tank) or an armed helicopter / VTOL that patrols the base.
    The traded vehicle refunds part of its price. Only for bases no player is near, at most one
    trade a turn. Tanks go in the base's vehicle garrison (same count, so the vehicle caps hold),
    aircraft in its air patrol (server variable "airpatrol<base>").

    Parameters:
        _spend - The current spending limit
        _chance - Higher is less likely to trade

    Usage: _spend = [_spend, _chance] call OT_fnc_NATOupgradeHeavyGarrisons;

    Returns: Scalar - How much is left to spend
*/

params ["_spend", "_chance"];

private _costTank = 800;
private _costAir = 900;
private _refundLight = 125;
private _refundAPC = 200;
if (_spend < (_costTank - _refundAPC) || { random 100 < _chance }) exitWith { _spend };

// Tanks, and armed helicopters and VTOLs of the occupier
private _tanks = +OT_NATO_Vehicles_TankSupport;
private _aircraft = OT_NATO_Vehicles_AirSupport + OT_NATO_Vehicles_AirSupport_Small;
{
    {
        if (_x isKindOf "VTOL_Base_F" && { (configFile >> "CfgVehicles" >> _x) call OT_fnc_isArmedPlane }) then { _aircraft pushBackUnique _x };
    } forEach ((OT_factionVehicles getOrDefault [_x, [[], []]]) select 0);
} forEach OT_occupierFactions;
_aircraft = _aircraft arrayIntersect _aircraft;

private _resources = server getVariable ["NATOresources", 2000];
private _abandoned = server getVariable ["NATOabandoned", []];

{
    _x params ["_pos", "_name", "_worth"];
    private _isHQ = _name isEqualTo OT_NATO_HQ;
    if (_name in _abandoned || { !_isHQ && { _worth <= 1000 } } || { [_pos] call OT_fnc_inSpawnDistance }) then { continue };

    // A light vehicle to trade in: not a static gun, a tank or one of the HQ's own defences
    private _garrison = server getVariable [format ["vehgarrison%1", _name], []];
    private _light = _garrison select {
        !(_x isKindOf "StaticWeapon") && { _x isKindOf "LandVehicle" } && { !(_x in _tanks) } && { !(_x in OT_NATO_Vehicles_HQGarrison) }
    };
    if (_light isEqualTo []) then { continue };
    // Cheapest first, keep the APCs
    private _sell = (_light select { !(_x in OT_NATO_Vehicles_APC) }) param [0, _light select 0];
    private _refund = [_refundLight, _refundAPC] select (_sell in OT_NATO_Vehicles_APC);

    private _numTanks = { _x in _tanks } count _garrison;
    private _airpatrol = server getVariable [format ["airpatrol%1", _name], []];
    private _canTank = _tanks isNotEqualTo [] && { _numTanks < ([2, 3] select _isHQ) } && { _spend >= (_costTank - _refund) };
    private _canAir = _aircraft isNotEqualTo [] && { count _airpatrol < ([1, 2] select _isHQ) } && { _spend >= (_costAir - _refund) };
    if (!_canTank && !_canAir) then { continue };

    private _toAir = _canAir && { !_canTank || { random 100 < 40 } };
    private _cost = ([_costTank, _costAir] select _toAir) - _refund;
    private _type = selectRandom ([_tanks, _aircraft] select _toAir);

    _garrison deleteAt (_garrison find _sell);
    if (_toAir) then {
        _airpatrol pushBack _type;
        server setVariable [format ["airpatrol%1", _name], _airpatrol, true];
    } else {
        _garrison pushBack _type;
    };
    server setVariable [format ["vehgarrison%1", _name], _garrison, true];
    _spend = _spend - _cost;
    _resources = _resources - _cost;
    diag_log format ["Overthrow: %1 traded a %2 at %3 for a %4", OT_NATO_name, _sell call OT_fnc_vehicleGetName, _name, _type call OT_fnc_vehicleGetName];
    break;
} forEach ((OT_objectiveData + OT_airportData) call BIS_fnc_arrayShuffle);

server setVariable ["NATOresources", _resources];

_spend;
