/*
    Description:
    The occupier impounds a player's vehicle (server): the collateral of a failed smuggling job
    (OT_fnc_logisticsSettle). Anyone in it is put out and it's gone from the map; what's in it (cargo,
    ACE cargo but freight crates, an attached weapon) is kept with it in the impound lot, the saved
    server variable "logisticsImpound": [[impound id, owner UID, class, price $, cargo, ACE cargo,
    attached weapon class], ...]. Getting it back (OT_fnc_logisticsImpoundRecover, at a garage) costs
    $500 + 75% of the vehicle's price.

    Parameters:
        _this # 0: OBJECT - Vehicle
        _this # 1: STRING - UID of its owner (it isn't impounded if it's someone else's by now)

    Usage: [_veh, _uid] call OT_fnc_logisticsImpound; (server)

    Returns: BOOL - Impounded
*/

params ["_veh", "_uid"];

if (!isServer || { isNull _veh } || { !alive _veh }) exitWith { false };
if ((_veh getVariable ["owner", ""]) isNotEqualTo _uid) exitWith { false };

private _class = typeOf _veh;
private _value = ((cost getVariable [_class, [0]]) select 0) max 0;
private _price = round (500 + (_value * 0.75));

// What goes with it: cargo, ACE cargo (freight crates stay with their job, OT_fnc_logisticsTrack clears them)
private _cargo = _veh call OT_fnc_getCargo;
private _aceLoaded = (_veh getVariable ["ace_cargo_loaded", []]) select {
    _x isEqualType "" || { !isNull _x && { (_x getVariable ["OT_haul", ""]) isEqualTo "" } }
};
private _aceCargo = _aceLoaded apply { if (_x isEqualType "") then { [_x, []] } else { [typeOf _x, _x call OT_fnc_getCargo] } };
private _attachedClass = _veh getVariable ["OT_attachedClass", ""];

private _impound = server getVariable ["logisticsImpound", []];
private _impoundId = format ["imp%1_%2", floor random 1000000, count _impound];
_impound pushBack [_impoundId, _uid, _class, _price, _cargo, _aceCargo, _attachedClass];
server setVariable ["logisticsImpound", _impound, true];

// Gone: everyone out, then the vehicle with what was loaded in it
{ [_x] remoteExec ["moveOut", _x] } forEach (crew _veh);
_veh setVariable ["owner", nil, true];
[_veh, 2] remoteExec ["lock", _veh];
[_veh, _aceLoaded select { _x isEqualType objNull }] spawn {
    params ["_veh", "_loaded"];
    sleep 1;
    { [_x] remoteExec ["moveOut", _x] } forEach (crew _veh);
    sleep 1;
    { detach _x; deleteVehicle _x } forEach _loaded;
    deleteVehicle (_veh getVariable ["OT_attachedWeapon", objNull]);
    deleteVehicle _veh;
};
true;
