private _veh = vehicle player;

if (_veh isEqualTo player) exitWith {};

format ["Taking legal inventory from vehicle"] call OT_fnc_notifyMinor;

[5, false] call OT_fnc_progressBar;
sleep 5;

{
    _x params ["_cls", "_num"];
    if (_cls in OT_allItems) then {
        // Only give the player what could be taken out of the vehicle (including backpacks etc. in it)
        for "_i" from 1 to _num do {
            if !(player canAdd _cls) exitWith {};
            if (([_veh, _cls, 1] call OT_fnc_removeFromCargo) isEqualTo 0) exitWith {};
            player addItem _cls;
        };
    };
} forEach (_veh call OT_fnc_unitStock);

"Inventory Transfer done" call OT_fnc_notifyMinor;
