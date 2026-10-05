/*
    Description:
    How far round a town's mayor's office counts as the office (taking it, holding it, the QRF for it:
    OT_fnc_officeCapture): 30 m, or more for a big building, so the whole of it is in (the Altis hospital with
    its wings is about 48 m). Server.

    Parameters:
        _this # 0: STRING - Town (with an office layout, OT_fnc_officeLayout)

    Usage: private _radius = [_town] call OT_fnc_officeRadius;

    Returns: NUMBER - Metres round the office's position
*/

params [["_town", "", [""]]];

private _office = ([_town] call OT_fnc_officeLayout) param [0, []];
if (_office isEqualTo []) exitWith { 30 };
private _b = (nearestObjects [ASLToAGL (_office select 1), [_office select 0], 3, true]) param [0, objNull];
if (isNull _b) exitWith { 30 };
private _radius = 30 max (((boundingBoxReal _b) select 2) + 5);
// A building of several pieces: out to its farthest piece too
{
    (_x select 1) params ["_x2", "_y2"];
    _radius = _radius max ((vectorMagnitude [_x2, _y2, 0]) + 15);
} forEach ([[_b] call OT_fnc_officeTemplateKey] call OT_fnc_officeParts);
_radius
