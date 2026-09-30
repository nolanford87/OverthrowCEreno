/*
    Description:
    Sets how the occupier's soldiers are equipped: 0 standard loadouts, 1 faction random (the
    occupier's own weapons and gear), 2 fully random (everything in the game).
    Chosen on the new game screen and saved with the game (server variable "OT_randomLoadoutMode"),
    the lobby setting "Occupier loadouts" (ot_occupierloadouts, same values) is the default.

    Parameters:
        _this # 0: NUMBER - Mode, -1 (default) for the lobby settings

    Usage: [2] call OT_fnc_setLoadoutMode;
*/

params [["_mode", -1, [0]]];

if (_mode < 0) then {
    _mode = ((["ot_occupierloadouts", 0] call BIS_fnc_getParamValue) max 0) min 2;
};

OT_randomLoadoutMode = _mode;
OT_randomizeLoadouts = _mode > 0;
if (!isNil "OT_randomLoadoutPools") then {
    OT_randomLoadoutPool = OT_randomLoadoutPools select (_mode isEqualTo 2);
};
_mode;
