/*
    Description:
    A drug lab's cargo container (server): the one within 50 m of the lab, else a new one off the
    shed's east end, owned by the first general. Precursors put in it (or any container within 50 m)
    are cooked into blow there each business cycle (OT_fnc_drugLabCycle).

    Parameters:
        _this: STRING - Lab name or id

    Usage: private _box = "Kavala Lab" call OT_fnc_drugLabContainer;

    Returns: OBJECT - The container (objNull for no such lab)
*/

private _site = _this call OT_fnc_drugLabData;
if (_site isEqualTo []) exitWith { objNull };
_site params ["", "", "_pos", "_origin", "_dir"];

private _container = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) param [0, objNull];
if (isNull _container) then {
    // Off the east end (x 21 in the shed's own coordinates, OT_fnc_drugLabSites checked the ground there)
    private _spot = [(_origin select 0) + (21 * cos _dir) + (3.35 * sin _dir), (_origin select 1) - (21 * sin _dir) + (3.35 * cos _dir), 0];
    private _p = _spot findEmptyPosition [0, 25, OT_item_CargoContainer];
    if (_p isEqualTo []) then { _p = _spot };
    _container = createVehicle [OT_item_CargoContainer, _p, [], 0, "NONE"];
    _container setDir (_dir + 90);
    [_container, (server getVariable ["generals", []]) param [0, ""]] call OT_fnc_setOwner;
    clearWeaponCargoGlobal _container;
    clearMagazineCargoGlobal _container;
    clearBackpackCargoGlobal _container;
    clearItemCargoGlobal _container;
};
_container;
