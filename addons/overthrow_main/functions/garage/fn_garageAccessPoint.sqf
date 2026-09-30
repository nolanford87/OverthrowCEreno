/*
    Description:
    The garage a player can use: an owned warehouse or a resistance base flag within 25 m.

    Parameters:
        _this: OBJECT - Player

    Usage: private _garage = player call OT_fnc_garageAccessPoint;

    Returns: OBJECT - Warehouse or flag, objNull if none is near
*/

private _player = _this;
private _near = ((warehouse getVariable ["owned", []]) select { !isNull _x && { (_x distance2D _player) < 25 } })
    + (_player nearObjects [OT_flag_IND, 25]);
_near param [0, objNull];
