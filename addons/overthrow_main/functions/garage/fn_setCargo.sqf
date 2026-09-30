/*
    Description:
    Replaces a container's cargo with what OT_fnc_getCargo recorded (empties it first, so any
    default cargo the vehicle spawned with is gone).

    Parameters:
        _this # 0: OBJECT - Vehicle or container
        _this # 1: ARRAY - Cargo from OT_fnc_getCargo

    Usage: [_veh, _cargo] call OT_fnc_setCargo;
*/

params ["_container", ["_cargo", []]];
_cargo params [["_items", [[], []]], ["_weapons", []], ["_magazines", []], ["_backpacks", [[], []]], ["_containers", []]];

clearItemCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearBackpackCargoGlobal _container;

{
    _container addItemCargoGlobal [_x, (_items select 1) select _forEachIndex];
} forEach (_items select 0);
{
    _container addWeaponWithAttachmentsCargoGlobal [_x, 1];
} forEach _weapons;
{
    _x params ["_mag", "_ammo"];
    _container addMagazineAmmoCargo [_mag, 1, _ammo];
} forEach _magazines;
{
    _container addBackpackCargoGlobal [_x, (_backpacks select 1) select _forEachIndex];
} forEach (_backpacks select 0);

// What was inside the uniforms, vests and backpacks, matched to the new ones by class
private _new = everyContainer _container;
private _used = [];
{
    _x params ["_class", "_contents"];
    private _index = _new findIf { (_x select 0) isEqualTo _class && { !((_x select 1) in _used) } };
    if (_index > -1) then {
        private _object = (_new select _index) select 1;
        _used pushBack _object;
        [_object, _contents] call OT_fnc_setCargo;
    };
} forEach _containers;
