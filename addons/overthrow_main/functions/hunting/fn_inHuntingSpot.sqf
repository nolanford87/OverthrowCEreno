/*
    Description:
    The hunting spot a position is in (400 m across), -1 if none.

    Parameters:
        _this: ARRAY / OBJECT - Position

    Usage: (getPos player) call OT_fnc_inHuntingSpot;

    Returns: NUMBER - Spot index, -1 if none
*/

private _pos = _this;
(server getVariable ["huntingSpots", []]) findIf { (_x distance2D _pos) < 200 }
