/*
    Description:
    Removes items from a container and from the containers inside it (backpacks, vests, uniforms),
    the same places OT_fnc_unitStock counts. Removing only from the top level let items kept
    inside a backpack pass a stock check without being taken.

    Parameters:
        _this # 0: OBJECT - Container (vehicle, box)
        _this # 1: STRING - Classname
        _this # 2: NUMBER - How many to remove

    Usage: private _removed = [_box, "OT_Wood", 5] call OT_fnc_removeFromCargo;

    Returns: NUMBER - How many were removed
*/

params ["_container", "_cls", ["_count", 1]];

private _cfgWeapons = configFile >> "CfgWeapons";
private _fnc = call {
    if (_cls isKindOf "Bag_Base") exitWith { CBA_fnc_removeBackpackCargo };
    if (isClass (configFile >> "CfgMagazines" >> _cls)) exitWith { CBA_fnc_removeMagazineCargo };
    if (_cls isKindOf ["Rifle", _cfgWeapons] || { _cls isKindOf ["Launcher", _cfgWeapons] } || { _cls isKindOf ["Pistol", _cfgWeapons] }) exitWith { CBA_fnc_removeWeaponCargo };
    CBA_fnc_removeItemCargo
};

private _removed = 0;
{
    while { _removed < _count && { [_x, _cls, 1] call _fnc } } do {
        _removed = _removed + 1;
    };
    if (_removed >= _count) exitWith {};
} forEach ([_container] + ((everyContainer _container) apply { _x select 1 }));

_removed;
