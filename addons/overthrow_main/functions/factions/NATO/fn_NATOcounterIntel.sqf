/*
    Description:
    Does the resistance have intelligence on an occupier counter-attack against a town
    (OT_fnc_NATOCounterTown)? It does if it holds a radio tower within 4 km of the town, or if the
    town's people back it (resistance support of 50 or more there, the same support that makes the
    delivery intelligence more likely, OT_fnc_NATOdeliveryIntel). With intelligence the players get
    10 minutes' warning, without it 2.

    Parameters:
        _this # 0: STRING - Town

    Usage: private _intel = [_town] call OT_fnc_NATOcounterIntel;

    Returns: BOOL - Intelligence on it
*/

params ["_town"];

private _pos = server getVariable [_town, [0, 0, 0]];
private _abandoned = server getVariable ["NATOabandoned", []];
private _support = server getVariable [format ["rep%1", _town], 0];

_support >= 50 || { OT_NATOComms findIf { ((_x select 1) in _abandoned) && { ((_x select 0) distance2D _pos) < 4000 } } > -1 };
