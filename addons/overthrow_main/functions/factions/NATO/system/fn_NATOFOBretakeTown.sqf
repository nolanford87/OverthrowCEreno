/*
    Description:
    A fully upgraded FOB (16+ soldiers, mortar, barriers, HMG and its vehicle, even a lost one) goes for
    the town nearest it when the resistance holds it: the occupier counter-attacks that town like
    it does for others (OT_fnc_NATOCounterTown). Needs no other attack underway, 20 minutes since the
    last one and the resources for it. At most one a turn.

    Usage: [] call OT_fnc_NATOFOBretakeTown;

    Returns: BOOL - A town counter-attack was started
*/

if ((server getVariable ["NATOattacking", ""]) isNotEqualTo "") exitWith { false };
if ((time - (server getVariable ["NATOlastattack", 0])) < 1200) exitWith { false };

private _abandoned = server getVariable ["NATOabandoned", []];
private _resources = server getVariable ["NATOresources", 2000];
private _started = false;

{
    _x params ["_pos", "_garrison", "_upgrades"];
    private _full = _garrison >= 16
        && { ["Mortar", "Barriers", "HMG"] findIf { !(_x in _upgrades) } isEqualTo -1 }
        && { "Vehicle" in _upgrades || { "VehicleLost" in _upgrades } };
    if (!_full) then { continue };

    private _town = _pos call OT_fnc_nearestTown;
    if !(_town in _abandoned) then { continue };
    private _population = server getVariable [format ["population%1", _town], 100];
    if (_resources < _population) then { continue };

    private _cost = (_population * 3) min _resources;
    diag_log format ["Overthrow: %1 FOB near %2 counter-attacks it", OT_NATO_name, _town];
    [_town, _cost] spawn OT_fnc_NATOCounterTown;
    server setVariable ["NATOlastcounter", _town, true];
    server setVariable ["NATOattacking", _town, true];
    server setVariable ["NATOattackstart", time, true];
    server setVariable ["NATOlastattack", time, true];
    _resources = _resources - _cost;
    _started = true;
    break;
} forEach (server getVariable ["NATOfobs", []]);

server setVariable ["NATOresources", _resources];
_started;
