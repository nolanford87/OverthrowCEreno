/*
    Description:
    Unloads a freight job's crates from a vehicle at the drop-off (server; the "Unload delivery
    cargo" action, OT_fnc_logisticsUnloadAction): every crate of the job in its ACE cargo comes out
    and is set down in a row behind it, on the ground where there's room. The vehicle gets the cargo
    space back. Other cargo stays in.

    Parameters:
        _this # 0: OBJECT - Vehicle
        _this # 1: STRING - Job id (OT_haul on its crates)

    Usage: [_veh, _id] remoteExec ["OT_fnc_logisticsUnload", 2];

    Returns: NUMBER - Crates unloaded
*/

params ["_veh", "_id"];

if (!isServer || { isNull _veh }) exitWith { 0 };

private _loaded = _veh getVariable ["ace_cargo_loaded", []];
private _crates = _loaded select { _x isEqualType objNull && { !isNull _x } && { (_x getVariable ["OT_haul", ""]) isEqualTo _id } };
if (_crates isEqualTo []) exitWith { 0 };

// Out of its ACE cargo, the space given back
_veh setVariable ["ace_cargo_loaded", _loaded - _crates, true];
private _size = 0;
{ _size = _size + (_x getVariable ["ace_cargo_size", 1]) } forEach _crates;
_veh setVariable ["ace_cargo_space", (_veh getVariable ["ace_cargo_space", 0]) + _size, true];

// Behind it: a row across, 2 m apart, starting just clear of its back
private _back = ((boundingBoxReal _veh) select 0 select 1) - 2;
{
    private _crate = _x;
    private _across = ((_forEachIndex mod 4) - 1.5) * 2;
    private _row = floor (_forEachIndex / 4) * 2;
    private _pos = _veh modelToWorld [_across, _back - _row, 0];
    private _free = _pos findEmptyPosition [0, 10, typeOf _crate];
    if (_free isNotEqualTo [] && { !surfaceIsWater _free }) then { _pos = _free };
    detach _crate;
    _crate hideObjectGlobal false;
    _crate enableSimulationGlobal true;
    _crate setPosATL [_pos select 0, _pos select 1, 0];
    _crate setVelocity [0, 0, 0];
} forEach _crates;

count _crates
