/*
    Description:
    How angry a gang is about drugs on its turf right now (any machine, read only): its record
    ("drugTurfAnger", OT_fnc_drugTurfState) with the anger forgotten since its last tick taken off.

    Parameters:
        _this # 0: NUMBER - Gang id

    Usage: private _anger = [_gangId] call OT_fnc_drugTurfAngerOf;

    Returns: NUMBER - Anger, 0 for a gang with nothing to be angry about
*/

params ["_gangId"];

private _all = server getVariable ["drugTurfAnger", []];
private _i = _all findIf { (_x select 0) isEqualTo _gangId };
if (_i < 0) exitWith { 0 };
(_all select _i) params ["", "_anger", "_tick"];
if (_tick > serverTime) exitWith { _anger }; // An earlier session's clock
(_anger - (((serverTime - _tick) / 60) * OT_drugTurfDecay)) max 0
