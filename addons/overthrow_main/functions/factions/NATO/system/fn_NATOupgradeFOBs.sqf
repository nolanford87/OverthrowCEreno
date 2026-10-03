/*
    Author: ThomasAngel, ARMAZac

    Description:
    Try to send an air patrol

    Parameters:
        _spend - The current spending limit

    Usage: [_spend] call OT_fnc_NATOsendAirPatrol;

    Returns: Scalar - How much is left to spend
*/

params ["_spend", "_chance"];

private _resources = server getVariable ["NATOresources", 2000];
private _fobs = server getVariable ["NATOfobs", []];

{
    _x params ["_pos", "_garrison", "_upgrades"];
    private _max = 16;
    // Its crewed guns, as OT_fnc_NATOregisterFOB sets them, updated as they're bought
    if ((count _x) < 5) then {
        _x set [3, [0, 4] select ("HMG" in _upgrades)];
        _x set [4, parseNumber ("Mortar" in _upgrades)];
    };
    if ((_garrison < _max) && { (_spend > 150) } && { (random 100 > _chance) }) exitWith {
        // 4 more soldiers in its stored garrison, spawned now if a player is near (OT_fnc_spawnNATOFOB)
        _x set [1, _garrison + 4];
        _spend = _spend - 150;
        _resources = _resources - 150;
        private _id = OT_fobSpawners getOrDefault [_pos, ""];
        if (_id in OT_allSpawned) then { [_pos, _id] spawn OT_fnc_spawnNATOFOB };
    };

    if (!("Mortar" in _upgrades) && { (_spend > 300) } && { (random 100 > _chance) }) exitWith {
        _spend = _spend - 300;
        _resources = _resources - 300;
        _upgrades pushBack "Mortar";
        _x set [4, 1]; // Crewed once built
        [_pos, ["Mortar"]] spawn OT_fnc_NATOupgradeFOB;
    };
    if (!("Barriers" in _upgrades) && { (_spend > 50) } && { (random 100 > _chance) }) exitWith {
        _spend = _spend - 50;
        _resources = _resources - 50;
        _upgrades pushBack "Barriers";
        [_pos, ["Barriers"]] spawn OT_fnc_NATOupgradeFOB;
    };
    if (!("HMG" in _upgrades) && { (_spend > 150) } && { (random 100 > _chance) }) exitWith {
        _spend = _spend - 150;
        _resources = _resources - 150;
        _upgrades pushBack "HMG";
        _x set [3, 4]; // Crewed once built
        [_pos, ["HMG"]] spawn OT_fnc_NATOupgradeFOB;
    };
    // One vehicle per FOB, a lost one isn't replaced ("VehicleLost")
    if (!("Vehicle" in _upgrades) && { !("VehicleLost" in _upgrades) } && { (_spend > 250) } && { (random 100 > _chance) }) exitWith {
        _spend = _spend - 250;
        _resources = _resources - 250;
        _upgrades pushBack "Vehicle";
        [_pos, ["Vehicle"], true] spawn OT_fnc_NATOupgradeFOB; // Delivered: drives in or parachuted
    };
} forEach (_fobs);

server setVariable ["NATOresources", _resources];

_spend;
