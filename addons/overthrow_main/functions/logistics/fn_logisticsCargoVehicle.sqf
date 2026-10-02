/*
    Description:
    The vehicle a player can unload a freight job's crates from: the one they're in, or else the
    nearest within 15 m that has at least one of the job's crates in its ACE cargo.

    Parameters:
        _this # 0: OBJECT - Player
        _this # 1: STRING - Job id (OT_haul on its crates)

    Usage: [player, _id] call OT_fnc_logisticsCargoVehicle;

    Returns: OBJECT - The vehicle, objNull if none
*/

params ["_unit", "_id"];

private _hasCrates = {
    ((_this getVariable ["ace_cargo_loaded", []]) findIf { _x isEqualType objNull && { (_x getVariable ["OT_haul", ""]) isEqualTo _id } }) > -1
};
if ((vehicle _unit) isNotEqualTo _unit) exitWith { [objNull, vehicle _unit] select ((vehicle _unit) call _hasCrates) };
private _near = ((_unit nearEntities [["LandVehicle", "Air", "Ship"], 15]) select { _x call _hasCrates });
if (_near isEqualTo []) exitWith { objNull };
private _byDist = _near apply { [_x distance _unit, _x] };
_byDist sort true;
(_byDist select 0) select 1
