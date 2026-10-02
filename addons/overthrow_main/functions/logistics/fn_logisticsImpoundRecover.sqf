/*
    Description:
    Gets a vehicle back from the occupier's impound lot (server; "Impound lot" at a garage,
    OT_fnc_garageInitPlayer): the player pays its price (OT_fnc_logisticsImpound) and it's put down by
    the garage, theirs, with what was in it.

    Parameters:
        _this # 0: STRING - Impound id
        _this # 1: OBJECT - Player
        _this # 2: OBJECT - Where it's put down (default: the garage by the player, OT_fnc_garageAccessPoint)

    Usage: [_impoundId, player] remoteExecCall ["OT_fnc_logisticsImpoundRecover", 2];

    Returns: OBJECT - The vehicle, objNull if not recovered
*/

params ["_impoundId", "_player", ["_at", objNull]];

if (!isServer || { isNull _player }) exitWith { objNull };
private _hint = { _this remoteExec ["OT_fnc_notifyMinor", _player, false] };
if (isNull _at) then { _at = _player call OT_fnc_garageAccessPoint };
if (isNull _at) exitWith { "You need to be at an owned warehouse or a resistance base" call _hint; objNull };

private _veh = objNull;
private _record = [];
// Found and taken off the list without a break, it can't be recovered twice
isNil {
    private _impound = server getVariable ["logisticsImpound", []];
    private _idx = _impound findIf { (_x select 0) isEqualTo _impoundId && { (_x select 1) isEqualTo getPlayerUID _player } };
    if (_idx > -1 && { (_player getVariable ["money", 0]) >= ((_impound select _idx) select 3) }) then {
        _record = _impound deleteAt _idx;
        server setVariable ["logisticsImpound", _impound, true];
    };
};
if (_record isEqualTo []) exitWith { "You can't afford to get that vehicle back" call _hint; objNull };
_record params ["", "_uid", "_class", "_price", ["_cargo", []], ["_aceCargo", []], ["_attachedClass", ""]];

[-_price, "Impound fees"] remoteExec ["OT_fnc_money", _player, false];
private _pos = (getPosATL _at) findEmptyPosition [6, 80, _class];
if (_pos isEqualTo []) then { _pos = (getPosATL _at) getPos [15, random 360] };
_veh = createVehicle [_class, _pos, [], 0, "NONE"];
[_veh, _uid] call OT_fnc_setOwner;
format ["Your %1 is back from the impound lot, parked by the garage", _class call OT_fnc_vehicleGetName] call _hint;

// What was in it, once ACE has given the new vehicle its own things (as OT_fnc_garageRestore)
[_veh, _cargo, _aceCargo, _attachedClass] spawn {
    params ["_veh", "_cargo", "_aceCargo", "_attachedClass"];
    sleep 2;
    if (isNull _veh) exitWith {};
    if (_cargo isNotEqualTo []) then { [_veh, _cargo] call OT_fnc_setCargo };
    {
        _x params ["_class", "_contents"];
        private _item = createVehicle [_class, getPosATL _veh, [], 5, "NONE"];
        if (_contents isNotEqualTo []) then { [_item, _contents] call OT_fnc_setCargo };
        [_item, _veh, true] call ace_cargo_fnc_loadItem;
    } forEach _aceCargo;
    if (_attachedClass isNotEqualTo "") then {
        _veh setVariable ["OT_attachedClass", _attachedClass, true];
        [_veh] call OT_fnc_initAttached;
    };
};
_veh;
