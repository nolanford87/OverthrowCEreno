/*
    Description:
    The resistance town the occupier would counter-attack (OT_fnc_NATOcounterTowns): the least
    defended one it holds. Defenders are its police (counted even when not spawned) plus any other
    resistance soldiers within 400 m of it; the fewest defenders wins, then the lowest resistance
    support there, then the smallest population.
    Left out: towns in their grace period (OT_fnc_NATOtownGrace), the town already being attacked,
    and towns an occupier FOB is about to take back (OT_fnc_NATOstartFOBTimer).

    Parameters:
        -

    Usage: private _town = [] call OT_fnc_NATOcounterTarget;

    Returns: STRING - Town, "" if there's none to attack
*/

private _abandoned = server getVariable ["NATOabandoned", []];
private _attacking = server getVariable ["NATOattacking", ""];
private _fobTowns = (server getVariable ["NATOfobTimers", []]) apply { _x select 2 };

private _candidates = [];
{
    private _town = _x;
    if !(_town in _abandoned) then { continue };
    if (_town isEqualTo _attacking || { _town in _fobTowns }) then { continue };
    if ((["get", _town] call OT_fnc_NATOtownGrace) > 0) then { continue };

    private _pos = server getVariable [_town, [0, 0, 0]];
    private _police = server getVariable [format ["police%1", _town], 0];
    private _soldiers = { alive _x && { side group _x isEqualTo independent } && { (_x getVariable ["polgarrison", ""]) isEqualTo "" } } count (_pos nearEntities ["CAManBase", 400]);
    private _support = server getVariable [format ["rep%1", _town], 0];
    private _population = server getVariable [format ["population%1", _town], 0];
    _candidates pushBack [_police + _soldiers, _support, _population, _town];
} forEach OT_allTowns;

if (_candidates isEqualTo []) exitWith { "" };
_candidates sort true;
(_candidates select 0) select 3;
