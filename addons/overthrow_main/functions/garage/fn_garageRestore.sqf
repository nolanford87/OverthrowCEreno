/*
    Description:
    Puts back what OT_fnc_garageStore kept for a vehicle taken out of the garage: owner, lock,
    name, cargo, ACE cargo and attached weapon. Vehicles stored before (without extra data) become
    the retrieving player's. Called by the player's machine after HR Garage created the vehicle.

    Parameters:
        _this # 0: OBJECT - The vehicle taken out
        _this # 1: NUMBER - Its garage id (HR Garage vehicle UID)
        _this # 2: OBJECT - Player who took it out

    Usage: [_veh, _vehUID, player] remoteExecCall ["OT_fnc_garageRestore", 2];
*/

if (!isServer) exitWith {};
params ["_veh", "_vehUID", "_player"];
if (isNull _veh) exitWith {};
if (isNil "OT_garageExtra") then { OT_garageExtra = createHashMap };

private _extra = OT_garageExtra getOrDefault [_vehUID, []];
OT_garageExtra deleteAt _vehUID;
_extra params [["_owner", getPlayerUID _player], ["_locked", false], ["_name", ""], ["_cargo", []], ["_aceCargo", []], ["_attachedClass", ""], ["_attachedAmmo", []]];

[_veh, _owner] call OT_fnc_setOwner;
_veh setVariable ["OT_locked", _locked, true];
if (_name isNotEqualTo "") then { _veh setVariable ["name", _name, true] };
if (_cargo isNotEqualTo []) then { [_veh, _cargo] call OT_fnc_setCargo };

{
    _x params ["_class", "_contents"];
    private _item = createVehicle [_class, getPosATL _veh, [], 5, "NONE"];
    if (_contents isNotEqualTo []) then { [_item, _contents] call OT_fnc_setCargo };
    if !([_item, _veh, true] call ace_cargo_fnc_loadItem) then {
        diag_log format ["Overthrow: garage couldn't load %1 back into %2, left next to it", _class, typeOf _veh];
    };
} forEach _aceCargo;

if (_attachedClass isNotEqualTo "") then {
    _veh setVariable ["OT_attachedClass", _attachedClass, true];
    [_veh, _attachedAmmo] call OT_fnc_initAttached;
};
