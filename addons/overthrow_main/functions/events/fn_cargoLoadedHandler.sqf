params ["_item", "_veh"];
private _pos = getPosATL _veh;

// ACE passes the loaded object (or its classname), check its class and its contents
private _illegal = false;
if (_item isEqualType objNull) then {
    _illegal = (typeOf _item) in OT_illegalItems || { ((_item call OT_fnc_unitStock) findIf { (_x select 0) in OT_illegalItems }) != -1 };
} else {
    _illegal = _item in OT_illegalItems;
};

if (_illegal) then {
    {
        if (isPlayer _x && { _x call OT_fnc_unitSeenNATO }) then {
            _x setCaptive false;
            [_x] call OT_fnc_revealToNATO;
        };
    } forEach (_pos nearEntities ["CAManBase", 30]);
};
