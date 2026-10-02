/*
    Description:
    Picks up a dead animal (the "Pick up the carcass" action): 2.5 seconds kneeling, then the carcass
    becomes raw meat (OT_Meat) in the player's inventory, as much as the animal gives (OT_huntMeat):
    rabbits, snakes and hens 1, goats and sheep 3. What doesn't fit is put on the ground. In a hunting
    spot the poachers may notice (OT_fnc_poacherRoll).

    Parameters:
        _this # 0: OBJECT - The dead animal

    Usage: [cursorObject] spawn OT_fnc_huntPickup;
*/

params ["_carcass"];

if (isNull _carcass || { alive _carcass } || { _carcass getVariable ["OT_pickingUp", false] }) exitWith {};
private _meat = OT_huntMeat getOrDefault [typeOf _carcass, 0];
if (_meat < 1) exitWith {};
_carcass setVariable ["OT_pickingUp", true, true];

player playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
[2.5, false] call OT_fnc_progressBar;
sleep 2.5;
player playActionNow "stop";

if (isNull _carcass || { !alive player } || { !isNull objectParent player } || { (player distance _carcass) > 4 }) exitWith {
    if (!isNull _carcass) then { _carcass setVariable ["OT_pickingUp", false, true] };
};

private _dropped = 0;
for "_i" from 1 to _meat do {
    if (player canAdd "OT_Meat") then {
        player addItem "OT_Meat";
    } else {
        _dropped = _dropped + 1;
    };
};
if (_dropped > 0) then {
    private _holder = createVehicle ["GroundWeaponHolder", getPosATL player, [], 0, "CAN_COLLIDE"];
    _holder addItemCargoGlobal ["OT_Meat", _dropped];
};
private _spot = (getPosATL _carcass) call OT_fnc_inHuntingSpot;
deleteVehicle _carcass;
if (_spot > -1) then { [_spot] remoteExec ["OT_fnc_poacherRoll", 2] };

private _text = format ["+%1 raw meat", _meat];
if (_dropped > 0) then { _text = _text + format [" (%1 on the ground, no room)", _dropped] };
_text call OT_fnc_notifyMinor;
