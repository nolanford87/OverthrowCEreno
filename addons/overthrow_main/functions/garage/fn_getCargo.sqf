/*
    Description:
    Records everything in a container's cargo, so OT_fnc_setCargo can put it back exactly:
    items, weapons with their attachments and loaded magazines, magazines with their ammo count,
    backpacks, and what is inside uniforms, vests and backpacks in the cargo.

    Parameters:
        _this: OBJECT - Vehicle or container

    Usage: private _cargo = _veh call OT_fnc_getCargo;

    Returns: ARRAY - [items, weapons, magazines, backpacks, containers]
*/

private _container = _this;
[
    getItemCargo _container, // [[classes], [counts]], includes uniforms and vests
    weaponsItemsCargo _container,
    magazinesAmmoCargo _container,
    getBackpackCargo _container, // [[classes], [counts]]
    (everyContainer _container) apply { [_x select 0, (_x select 1) call OT_fnc_getCargo] }
];
