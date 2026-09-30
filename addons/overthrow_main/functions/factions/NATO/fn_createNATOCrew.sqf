/*
    Description:
    Crews a vehicle of the occupier. createVehicleCrew puts the crew on the vehicle's own side,
    but the occupier always fights as BLUFOR (e.g. CSAT's vehicles would get an OPFOR crew).

    Parameters:
        _this # 0: OBJECT - Vehicle
        _this # 1: GROUP - (Optional) Group the crew joins, a new BLUFOR group if none

    Usage: [_veh] call OT_fnc_createNATOCrew;

    Returns: GROUP - The crew's group
*/

params ["_veh", ["_group", grpNull]];

createVehicleCrew _veh;
private _crewGroup = group ((crew _veh) param [0, objNull]);
if (isNull _group) then {
    if (side _crewGroup isEqualTo blufor) exitWith { _group = _crewGroup };
    _group = createGroup blufor;
};
if (_group isNotEqualTo _crewGroup) then {
    (crew _veh) joinSilent _group;
    if (!isNull _crewGroup && { units _crewGroup isEqualTo [] }) then { deleteGroup _crewGroup };
};
_group;
