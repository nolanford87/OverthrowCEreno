/*
    Description:
    The harvest from a wild ganja plant (OT_fnc_ganjaPick), on the player's machine: the ganja goes in
    their inventory, what doesn't fit on the ground.

    Parameters:
        _this # 0: NUMBER - Ganja
        _this # 1: NUMBER - Plants left in the zone

    Usage: [_yield, _left] remoteExec ["OT_fnc_ganjaGive", _player];
*/

params ["_yield", ["_left", 1]];

private _dropped = 0;
for "_i" from 1 to _yield do {
    if (player canAdd "OT_Ganja") then {
        player addItem "OT_Ganja";
    } else {
        _dropped = _dropped + 1;
    };
};
if (_dropped > 0) then {
    private _holder = createVehicle ["GroundWeaponHolder", getPosATL player, [], 0, "CAN_COLLIDE"];
    _holder addItemCargoGlobal ["OT_Ganja", _dropped];
};

private _text = format ["+%1 ganja", _yield];
if (_dropped > 0) then { _text = _text + format [" (%1 on the ground, no room)", _dropped] };
if (_left isEqualTo 0) then { _text = _text + ". That was the last plant here" };
_text call OT_fnc_notifyMinor;
