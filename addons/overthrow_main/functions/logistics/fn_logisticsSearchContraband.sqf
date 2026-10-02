/*
    Description:
    A search finds contraband crates (smuggling, tagged OT_contraband by OT_fnc_logisticsStart) on or
    around a player (server, from checkpoint searches, OT_fnc_initNATOCheckpoint, and random searches,
    OT_fnc_NATOsearch): in the ACE cargo of the vehicle they're in or of a vehicle of theirs within
    10 m, carried or dragged by them, or on the ground within 6 m. Their cover is blown: they and
    everyone in their vehicle become wanted (not captive, revealed to the occupier). The crates are
    not seized by the search; that happens if they are killed while wanted.

    Parameters:
        _this # 0: OBJECT - The searched player

    Usage: private _found = [_unit] call OT_fnc_logisticsSearchContraband; (server)

    Returns: BOOL - Contraband found (cover blown)
*/

params ["_unit"];

if (isNull _unit) exitWith { false };
private _isContraband = { _x isEqualType objNull && { !isNull _x } && { (_x getVariable ["OT_contraband", ""]) isNotEqualTo "" } };
private _uid = getPlayerUID _unit;

private _vehicles = (_unit nearEntities [["LandVehicle", "Air", "Ship"], 10]) select { (_x getVariable ["owner", ""]) isEqualTo _uid };
if (!isNull objectParent _unit) then { _vehicles pushBackUnique (objectParent _unit) };
private _found = (_vehicles findIf { ((_x getVariable ["ace_cargo_loaded", []]) findIf _isContraband) > -1 }) > -1
    || { ((attachedObjects _unit) findIf _isContraband) > -1 }
    || { (((_unit nearObjects 6) select { isNull attachedTo _x }) findIf _isContraband) > -1 };
if (!_found) exitWith { false };

private _people = [_unit];
if (!isNull objectParent _unit) then { _people = (crew (objectParent _unit)) select { alive _x } };
{
    if (local _x) then { _x setCaptive false } else { [_x, false] remoteExec ["setCaptive", _x] };
    [_x] call OT_fnc_revealToNATO;
} forEach _people;
if (isPlayer _unit) then {
    format ["%1 found the contraband: your cover is blown", OT_NATO_name] remoteExec ["OT_fnc_notifyBad", _unit, false];
};
true;
