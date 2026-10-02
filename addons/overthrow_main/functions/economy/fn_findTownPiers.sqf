/*
    Description:
    Finds a town's piers for boat dealers (OT_piers within 600 m, 1000 m for capitals and sprawling
    towns, at least 80 m apart) and stores them (server variable "activepiersin<town>").

    Parameters:
        _this # 0: STRING - Town

    Usage: [_town] call OT_fnc_findTownPiers; (server)

    Returns: ARRAY - Pier positions
*/

params ["_town"];

private _dist = [600, 1000] select (_town in OT_sprawling || { _town in OT_capitals });
private _posTown = server getVariable _town;
private _piers = [];
if (OT_piers isNotEqualTo []) then {
    {
        private _po = getPos _x;
        if ((_piers findIf { (_x distance _po) < 80 }) isEqualTo -1) then { _piers pushBack _po };
    } forEach (nearestObjects [_posTown, OT_piers, _dist, false]);
};
server setVariable [format ["activepiersin%1", _town], _piers, true];
_piers;
