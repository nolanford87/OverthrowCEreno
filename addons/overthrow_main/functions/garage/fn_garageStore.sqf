/*
    Description:
    Puts a vehicle in the virtual garage (HR Garage). HR Garage keeps its fuel, damage, ammo and
    looks; this keeps what it doesn't: the cargo (with what's inside backpacks etc.), ACE cargo
    (crates keep their contents), and Overthrow's owner, lock, name and attached weapon.
    A locked vehicle can only be taken out by its owner (or an admin), others by anyone.

    Parameters:
        _this # 0: OBJECT - Vehicle
        _this # 1: OBJECT - Player storing it

    Usage: [_veh, player] remoteExecCall ["OT_fnc_garageStore", 2];
*/

if (!isServer) exitWith {};
params ["_veh", "_player"];

private _uid = getPlayerUID _player;
private _hint = { _this remoteExecCall ["hint", _player] };

if (isNull _veh || { !alive _veh }) exitWith {};
if ((crew _veh) findIf { alive _x } > -1) exitWith { "Everyone has to get out of the vehicle first" call _hint };
private _owner = _veh call OT_fnc_getOwner;
if (isNil "_owner" || { _owner isEqualTo "" }) exitWith { "Take the vehicle first (get in it), then it can be stored" call _hint };
if (_owner isNotEqualTo _uid && { !(_uid in (server getVariable ["generals", []])) }) exitWith { "You can only store your own vehicles" call _hint };

private _access = _player call OT_fnc_garageAccessPoint;
if (isNull _access) exitWith { "You need to be at an owned warehouse or a resistance base" call _hint };

// HR Garage checks access (for aircraft) against its access point, on a dedicated server there is no player to find it
_access setVariable ["HR_Garage_Garage_ModuleArguments", createHashMapFromArray [["accessAir", true], ["accessNaval", true], ["accessArmor", true]], true];
HR_Garage_accessPoint = _access;
HR_Garage_PoolBase = 1000; // No limit
if (isNil "OT_garageExtra") then { OT_garageExtra = createHashMap };

// What HR Garage doesn't keep
private _locked = _veh getVariable ["OT_locked", false];
private _cargo = _veh call OT_fnc_getCargo;

// Attached weapon (Overthrow puts it back itself, HR Garage would store it as a separate vehicle)
private _attachedClass = _veh getVariable ["OT_attachedClass", ""];
private _attached = _veh getVariable ["OT_attachedWeapon", objNull];
private _attachedAmmo = [];
if (_attachedClass isNotEqualTo "" && { alive _attached }) then {
    _attachedAmmo = (_attached weaponsTurret [0]) apply { [_x, _attached ammo _x] };
};

// ACE cargo: HR Garage would unload it onto the ground. Spare wheels/tracks are left to the vehicle's own
private _aceLoaded = _veh getVariable ["ace_cargo_loaded", []];
private _aceKeep = _aceLoaded select { _x isEqualType objNull && { (typeOf _x) in ["ACE_Wheel", "ACE_Track"] } };
private _aceStore = _aceLoaded - _aceKeep;
private _aceCargo = _aceStore apply {
    if (_x isEqualType "") then { [_x, []] } else { [typeOf _x, _x call OT_fnc_getCargo] };
};
_veh setVariable ["ace_cargo_loaded", _aceKeep, true];

if (alive _attached) then {
    detach _attached;
    _attached hideObjectGlobal true;
};

private _lockUID = ["", _owner] select _locked;
private _stored = [_veh, owner _player, _lockUID, _player] call HR_Garage_fnc_addVehicle;

if (isNil "_stored" || { !_stored }) exitWith {
    // Not stored, put things back as they were
    _veh setVariable ["ace_cargo_loaded", _aceLoaded, true];
    if (alive _attached) then {
        _attached hideObjectGlobal false;
        private _item = OT_workshop select { (_x select 4) == _attachedClass && { (typeOf _veh) == (_x select 1) } };
        _attached attachTo [_veh, ((_item param [0, []]) param [5, [[0, 0, 0]]]) select 0];
    };
};

// The vehicle was added last, it has the newest id
private _vehUID = HR_Garage_UID;
OT_garageExtra set [_vehUID, [_owner, _locked, _veh getVariable ["name", ""], _cargo, _aceCargo, _attachedClass, _attachedAmmo]];
{ if (_x isEqualType objNull) then { deleteVehicle _x } } forEach _aceStore;
deleteVehicle _attached;

// Never a service source: HR Garage would fully repair / rearm / refuel every vehicle taken out
{
    private _index = _x find _vehUID;
    if (_index > -1) then {
        _x deleteAt _index;
        [_forEachIndex] call HR_Garage_fnc_declairSources;
    };
} forEach HR_Garage_Sources;
