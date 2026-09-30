/*
    Description:
    What it costs to have a vehicle recovered into the garage, and which garage it goes to (the
    owned warehouse or resistance base nearest the vehicle).
    $100 + $1 per 10 m to that garage + 2% of the vehicle's price, 25% cheaper when the town nearest
    the vehicle is held by the resistance, 25% more when the occupier holds it, and 50% more when it
    carries contraband (what checkpoints look for: drugs, weapons, ammo, military gear, an attached
    weapon; also inside backpacks etc. and ACE cargo crates).

    Parameters:
        _this: OBJECT - Vehicle

    Usage: (_veh call OT_fnc_garageRecoverPrice) params ["_price", "_garage", "_town", "_modifier"];

    Returns: ARRAY - [price (-1 if there is no garage), garage object, nearest town, town price change in %, has contraband]
*/

private _veh = _this;
private _garages = ((warehouse getVariable ["owned", []]) select { !isNull _x }) + (allMissionObjects OT_flag_IND);
if (_garages isEqualTo []) exitWith { [-1, objNull, "", 0, false] };

private _garage = ([_garages, [], { _x distance2D _veh }, "ASCEND"] call BIS_fnc_sortBy) select 0;
private _distance = _veh distance2D _garage;
private _value = ((cost getVariable [typeOf _veh, [0]]) select 0) max 0;

private _town = _veh call OT_fnc_nearestTown;
private _modifier = [25, -25] select (_town in (server getVariable ["NATOabandoned", []]));

// Contraband: every class in its cargo (nested containers too) and in its ACE cargo
private _classes = [];
private _collect = {
    _this params ["_items", "_weapons", "_magazines", "_backpacks", "_containers"];
    _classes append (_items select 0);
    _classes append (_weapons apply { _x select 0 });
    _classes append (_magazines apply { _x select 0 });
    _classes append (_backpacks select 0);
    { (_x select 1) call _collect } forEach _containers;
};
(_veh call OT_fnc_getCargo) call _collect;
{
    if (_x isEqualType objNull) then {
        _classes pushBack (typeOf _x);
        (_x call OT_fnc_getCargo) call _collect;
    } else {
        _classes pushBack _x;
    };
} forEach (_veh getVariable ["ace_cargo_loaded", []]);
private _illegal = OT_illegalItems + OT_allWeapons + OT_allMagazines + OT_illegalHeadgear + OT_illegalVests + OT_allStaticBackpacks + OT_allOptics;
private _contraband = ((_veh getVariable ["OT_attachedClass", ""]) isNotEqualTo "")
    || { _classes findIf { (([_x] call BIS_fnc_baseWeapon) in _illegal) || { _x in _illegal } } > -1 };

private _price = 100 + (_distance / 10) + (_value * 0.02);
_price = _price * (1 + (_modifier / 100));
if (_contraband) then { _price = _price * 1.5 };
_price = round _price;

[_price, _garage, _town, _modifier, _contraband];
