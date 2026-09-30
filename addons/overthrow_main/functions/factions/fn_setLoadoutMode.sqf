/*
    Description:
    Sets how the occupier's soldiers are equipped: 0 standard loadouts, 1 faction random (the
    occupier's own weapons and gear), 2 fully random (everything in the game).
    Chosen on the new game screen and saved with the game (server variable "OT_randomLoadoutMode"),
    the lobby settings "Randomize NATO loadouts" and "Randomized occupier loadouts use" are the default.

    Parameters:
        _this # 0: NUMBER - Mode, -1 (default) for the lobby settings

    Usage: [2] call OT_fnc_setLoadoutMode;
*/

params [["_mode", -1, [0]]];

if (_mode < 0) then {
    _mode = 0;
    if ((["ot_randomizeloadouts", 0] call BIS_fnc_getParamValue) isEqualTo 1) then {
        _mode = [1, 2] select ((["ot_randomloadoutpool", 0] call BIS_fnc_getParamValue) > 0);
    };
};

OT_randomLoadoutMode = _mode;
OT_randomizeLoadouts = _mode > 0;
if (!isNil "OT_randomLoadoutPools") then {
    OT_randomLoadoutPool = OT_randomLoadoutPools select (_mode isEqualTo 2);
};
_mode;
