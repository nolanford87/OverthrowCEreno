/*
    Description:
    What counts as a town's mayor's office for taking and holding it (OT_fnc_officeCapture, the QRF for it,
    OT_fnc_NATOQRFfight): the occupier compound's area at the town's tier (OT_fnc_officeCompound), or 30 m
    round the office (OT_fnc_officeRadius) for a tier or town without one. OT_fnc_officeInArea tests a unit
    against it. Server.

    Parameters:
        _this # 0: STRING - Town (with an office layout, OT_fnc_officeLayout)

    Usage: private _area = [_town] call OT_fnc_officeArea;

    Returns: ARRAY or NUMBER - The compound's polygon ([[x, y, 0], ...]), or the radius in metres
*/

params [["_town", "", [""]]];

private _area = [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeCompound;
if (_area isEqualTo []) exitWith { [_town] call OT_fnc_officeRadius };
_area apply { [_x select 0, _x select 1, 0] }
