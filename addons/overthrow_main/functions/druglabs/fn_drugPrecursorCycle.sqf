/*
    Description:
    An industrial business switched to make blow precursors (server variable "precursorsAt",
    OT_fnc_drugPrecursorToggle) makes them as well as its usual output each 15-minute business cycle
    (OT_fnc_GUERLoop, after wages): 1 per OT_precursorPerEmployees (2) employees, rounded up, at most
    OT_precursorMax (4), into its container (within 50 m, a new one if there's none). The chemicals
    cost OT_precursorCost ($60) each from resistance funds; none are made if the resistance can't pay.

    Parameters:
        _this # 0: STRING - Business name
        _this # 1: ARRAY - Its position
        _this # 2: NUMBER - Employees

    Usage: [_name, _pos, _num] call OT_fnc_drugPrecursorCycle; (server)

    Returns: NUMBER - Precursors made
*/

params ["_name", "_pos", "_num"];

if !(_name in (server getVariable ["precursorsAt", []])) exitWith { 0 };
if (_num <= 0) exitWith { 0 };
private _qty = (ceil (_num / OT_precursorPerEmployees)) min OT_precursorMax;
private _cost = _qty * OT_precursorCost;
if (([] call OT_fnc_resistanceFunds) < _cost) exitWith {
    format ["The resistance can't pay for the chemicals at %1: no precursors this time", _name] remoteExec ["OT_fnc_notifyMinor", 0, false];
    0
};
[-_cost] call OT_fnc_resistanceFunds;

private _container = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) param [0, objNull];
if (isNull _container) then {
    private _p = _pos findEmptyPosition [5, 50, OT_item_CargoContainer];
    if (_p isEqualTo []) then { _p = _pos };
    _container = OT_item_CargoContainer createVehicle _p;
    [_container, (server getVariable ["generals", []]) param [0, ""]] call OT_fnc_setOwner;
    clearWeaponCargoGlobal _container;
    clearMagazineCargoGlobal _container;
    clearBackpackCargoGlobal _container;
    clearItemCargoGlobal _container;
};
_container addItemCargoGlobal ["OT_Precursors", _qty];
_qty;
