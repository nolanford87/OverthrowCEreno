/*
    Description:
    What it costs to have a vehicle recovered into the garage, and which garage it goes to (the
    owned warehouse or resistance base nearest the vehicle).
    $100 + $1 per 10 m to that garage + 2% of the vehicle's price, 25% cheaper when the town nearest
    the vehicle is held by the resistance, 25% more when the occupier holds it.

    Parameters:
        _this: OBJECT - Vehicle

    Usage: (_veh call OT_fnc_garageRecoverPrice) params ["_price", "_garage", "_town", "_modifier"];

    Returns: ARRAY - [price (-1 if there is no garage), garage object, nearest town, price change in %]
*/

private _veh = _this;
private _garages = ((warehouse getVariable ["owned", []]) select { !isNull _x }) + (allMissionObjects OT_flag_IND);
if (_garages isEqualTo []) exitWith { [-1, objNull, "", 0] };

private _garage = ([_garages, [], { _x distance2D _veh }, "ASCEND"] call BIS_fnc_sortBy) select 0;
private _distance = _veh distance2D _garage;
private _value = ((cost getVariable [typeOf _veh, [0]]) select 0) max 0;

private _town = _veh call OT_fnc_nearestTown;
private _modifier = [25, -25] select (_town in (server getVariable ["NATOabandoned", []]));

private _price = 100 + (_distance / 10) + (_value * 0.02);
_price = round (_price * (1 + (_modifier / 100)));

[_price, _garage, _town, _modifier];
