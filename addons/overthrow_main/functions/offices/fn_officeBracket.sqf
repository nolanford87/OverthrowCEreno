/*
    Description:
    A town's population bracket for its mayor's office (1-5: under 50, 50-99, 100-199, 200-399, 400+). Locked
    in its layout at the bracket it was authored for (the probe's population), as populations are rolled anew
    each game; from this game's population for a town without one. Any machine.

    Parameters:
        _this # 0: STRING - Town

    Usage: private _bracket = [_town] call OT_fnc_officeBracket;

    Returns: NUMBER - The bracket, 1-5
*/

params [["_town", "", [""]]];

private _locked = ([_town] call OT_fnc_officeLayout) param [3, 0];
if (_locked > 0) exitWith { _locked };
private _population = server getVariable [format ["population%1", _town], 0];
1 + ({ _population >= _x } count [50, 100, 200, 400])
