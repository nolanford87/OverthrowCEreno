/*
    Description:
    A town's boat dealer piers: OT_piers on the sea (OT_fnc_isSeaPier) within 600 m (1000 m for
    capitals and sprawling towns), at most 2, at least 200 m apart, the nearest to the town first.
    The same on every machine (terrain objects): fisheries keep away from them (fn_initVar).
    With _store (server), stored as "activepiersin<town>"; worked out again on every load.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: ARRAY - (Optional) Town position, default its server variable
        _this # 2: BOOL - (Optional) Store it, default true

    Usage: [_town] call OT_fnc_findTownPiers;

    Returns: ARRAY - Pier positions
*/

params ["_town", ["_posTown", []], ["_store", true]];

if (_posTown isEqualTo []) then { _posTown = server getVariable _town };
private _dist = [600, 1000] select (_town in OT_sprawling || { _town in OT_capitals });
private _piers = [];
if (OT_piers isNotEqualTo []) then {
    {
        private _po = getPos _x;
        if (count _piers >= 2) exitWith {};
        if ((_piers findIf { (_x distance2D _po) < 200 }) isEqualTo -1 && { _po call OT_fnc_isSeaPier }) then { _piers pushBack _po };
    } forEach (nearestObjects [_posTown, OT_piers, _dist, false]);
};
if (_store) then { server setVariable [format ["activepiersin%1", _town], _piers, true] };
_piers;
