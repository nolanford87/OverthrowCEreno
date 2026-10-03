/*
    Description:
    A dispensary's stock container, within 50 m on land: the one there, or a new one owned by the
    first general. What's put in it (and in other containers within 50 m) is sold
    (OT_fnc_dispensaryCycle).

    Parameters:
        _this # 0: ARRAY - Dispensary position

    Usage: private _box = [_pos] call OT_fnc_dispensaryContainer;

    Returns: OBJECT - The container
*/

params ["_pos"];

private _container = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) param [0, objNull];
if (!isNull _container) exitWith { _container };

private _p = _pos findEmptyPosition [6, 40, OT_item_CargoContainer];
if (_p isEqualTo [] || { surfaceIsWater _p }) then { _p = _pos getPos [8, 0] };
_container = OT_item_CargoContainer createVehicle _p;
[_container, (server getVariable ["generals", []]) param [0, ""]] call OT_fnc_setOwner;
clearWeaponCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearBackpackCargoGlobal _container;
clearItemCargoGlobal _container;
_container
