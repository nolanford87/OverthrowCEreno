/*
    Description:
    The mayor's offices' starting defence tiers at a new game (the user's, 2026-10-30), from this game's rolled
    populations: the size groups (OT_fnc_officeBracket) set each town's highest tier, the population orders the
    towns within their group, biggest first:
    - hamlets (under 50): the biggest 20% tier 2, the rest tier 1;
    - towns (50-199, ranked together): the biggest 10% tier 3, the next 20% tier 2, the rest tier 1;
    - strongholds (200+): tier 3, the one nearest the occupier's HQ tier 5;
    then the region capitals and the occupier's priority towns one up (never a second tier 5), a town more than
    4 km from every occupier base one down (a stronghold not below 3), and the resistance's start town tier 1.
    Kept as server variable "officetier<town>" (saved); OT_fnc_officeTier caps it in play at the town's
    bracket + 1 and its built tiers. Server, from OT_fnc_initNATO.

    Usage: call OT_fnc_officeStartTiers;

    Returns: Nothing
*/

private _towns = OT_allTowns select { ([_x] call OT_fnc_officeLayout) isNotEqualTo [] };
private _pop = { server getVariable [format ["population%1", _this], 0] };
private _group = { [1, 2, 2, 3, 3] select (([_this] call OT_fnc_officeBracket) - 1) }; // Hamlet, town, stronghold
private _tiers = createHashMap;

// A group biggest first: each share from the top its tier ([[share, tier], ...]), the rest tier 1
private _rank = {
    params ["_list", "_bands"];
    _list = [_list, [], { _x call _pop }, "DESCEND"] call BIS_fnc_sortBy;
    private _n = count _list;
    private _from = 0;
    {
        _x params ["_share", "_tier"];
        private _k = round (_n * _share);
        { _tiers set [_x, _tier] } forEach (_list select [_from, _k]);
        _from = _from + _k;
    } forEach _bands;
    { _tiers set [_x, 1] } forEach (_list select [_from, _n]);
};
[_towns select { (_x call _group) isEqualTo 1 }, [[0.2, 2]]] call _rank;
[_towns select { (_x call _group) isEqualTo 2 }, [[0.1, 3], [0.2, 2]]] call _rank;
private _strongholds = _towns select { (_x call _group) isEqualTo 3 };
{ _tiers set [_x, 3] } forEach _strongholds;
private _top = ([_strongholds, [], { (server getVariable [_x, [0, 0, 0]]) distance2D OT_NATO_HQPos }, "ASCEND"] call BIS_fnc_sortBy) param [0, ""];
if (_top isNotEqualTo "") then { _tiers set [_top, 5] };

private _bases = (OT_objectiveData + OT_airportData + OT_commsData) apply { _x select 0 };
private _start = server getVariable ["spawntown", ""];
{
    private _town = _x;
    private _pos = server getVariable [_town, [0, 0, 0]];
    private _tier = _tiers getOrDefault [_town, 1];
    if ((_town in OT_capitals || { _town in OT_NATO_priority }) && { _tier < 5 }) then { _tier = (_tier + 1) min 4 };
    if ((_bases findIf { (_x distance2D _pos) < 4000 }) < 0) then { _tier = (_tier - 1) max ([1, 3] select (_town in _strongholds)) };
    if (_town isEqualTo _start) then { _tier = 1 };
    server setVariable [format ["officetier%1", _town], _tier, true];
} forEach _towns;
diag_log format ["Overthrow: mayor's office starting tiers %1", _towns apply { [_x, server getVariable format ["officetier%1", _x]] }];
