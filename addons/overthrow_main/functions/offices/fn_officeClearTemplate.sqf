/*
    Description:
    Takes a mayor's office defence template off a building: deletes the guards and the props and
    fortifications OT_fnc_officeApplyTemplate put there (the building's "OT_officeGuards" and
    "OT_officeObjects"), the guards first and, when it can wait, the things they stood in a moment
    later (deleted things are gone only at the end of the frame). Some House objects (seen with the
    gate bunkers) ignore deleteVehicle until they're hidden: a script tries again for a few seconds,
    hiding what stays. The building's other pieces stay. Server.

    Parameters:
        _this # 0: OBJECT - The building

    Usage: [_building] call OT_fnc_officeClearTemplate;

    Returns: ARRAY - [objects, guards] being deleted (null once gone)
*/

params [["_building", objNull, [objNull]]];

if (isNull _building) exitWith { [[], []] };
private _guards = _building getVariable ["OT_officeGuards", []];
private _objects = _building getVariable ["OT_officeObjects", []];
private _group = grpNull;
if (_guards isNotEqualTo []) then { _group = group (_guards select 0) };

{ deleteVehicle _x } forEach _guards;
if (canSuspend) then { sleep 0.5 };
{
    _x enableSimulationGlobal true;
    deleteVehicle _x;
} forEach _objects;
if (!isNull _group && { (units _group) isEqualTo [] }) then { deleteGroup _group };
[_objects + _guards] spawn {
    params ["_things"];
    for "_i" from 1 to 3 do {
        sleep 1;
        private _left = _things select { !isNull _x };
        if (_left isEqualTo []) exitWith {};
        { _x hideObjectGlobal true; deleteVehicle _x } forEach _left;
    };
};

_building setVariable ["OT_officeGuards", nil];
_building setVariable ["OT_officeObjects", nil];
_building setVariable ["OT_officeTier", nil];
[_objects, _guards]
