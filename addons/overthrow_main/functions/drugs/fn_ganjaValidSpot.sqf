/*
    Description:
    Can a wild ganja zone grow here: open countryside on land (no water within its 40 m), fairly flat,
    off the roads and away from buildings, at least 500 m outside towns, 800 m from bases, radio
    towers, airports and the occupier HQ, and OT_ganjaZoneSpacing from the other zones.

    Parameters:
        _this # 0: ARRAY - Position
        _this # 1: ARRAY - (Optional) More positions to keep OT_ganjaZoneSpacing from

    Usage: [_pos] call OT_fnc_ganjaValidSpot;

    Returns: BOOL
*/

params ["_pos", ["_avoid", []]];

_pos = [_pos select 0, _pos select 1, 0];
if (surfaceIsWater _pos) exitWith { false };
private _wet = false;
for "_dir" from 0 to 315 step 45 do {
    if (surfaceIsWater (_pos getPos [OT_ganjaZoneRadius, _dir])) exitWith { _wet = true };
};
if (_wet) exitWith { false };
if (((surfaceNormal _pos) select 2) < 0.94) exitWith { false };
if ((_pos nearRoads 40) isNotEqualTo []) exitWith { false };
if ((nearestTerrainObjects [_pos, ["HOUSE", "BUILDING", "CHURCH", "CHAPEL", "FUELSTATION", "HOSPITAL", "RUIN"], 120, false]) isNotEqualTo []) exitWith { false };
if ([_pos, 500] call OT_fnc_isInTown) exitWith { false };
private _bases = (OT_objectiveData + OT_airportData + OT_commsData) apply { _x select 0 };
_bases pushBack OT_NATO_HQPos;
if ((_bases findIf { (_x distance2D _pos) < 800 }) > -1) exitWith { false };
private _zones = ((server getVariable ["ganjaZones", []]) apply { _x select 1 }) + _avoid;
(_zones findIf { (_x distance2D _pos) < OT_ganjaZoneSpacing }) isEqualTo -1
