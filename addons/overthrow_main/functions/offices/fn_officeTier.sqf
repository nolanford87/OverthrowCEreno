/*
    Description:
    A town's mayor's office defence tier (1-5): what the occupier has built up there, saved in the server
    variable "officetier<town>". Until the occupier's spending raises it, a town starts by its population
    bracket (under 50, 50-99, 100-199, 200-399, 400+: tier 1, 1, 2, 3, 4). Never above its bracket + 1 or the
    highest tier its layout has. Server.

    Parameters:
        _this # 0: STRING - Town

    Usage: private _tier = [_town] call OT_fnc_officeTier;

    Returns: NUMBER - The tier, 1-5
*/

params [["_town", "", [""]]];

private _population = server getVariable [format ["population%1", _town], 0];
private _bracket = 1 + ({ _population >= _x } count [50, 100, 200, 400]);
private _authored = 0;
{ if (_x isNotEqualTo []) then { _authored = _forEachIndex + 1 } } forEach (([_town] call OT_fnc_officeLayout) param [1, []]);

private _tier = server getVariable [format ["officetier%1", _town], [1, 1, 2, 3, 4] select (_bracket - 1)];
(_tier min (_bracket + 1) min (_authored max 1)) max 1
