/*
    Description:
    The occupier raises one town's mayor's office a defence tier (the user's, 2026-10-30), once a turn at most,
    from the turn's spending budget and on the same chance roll as its other spends. The town most under threat
    first: its size (population) and the resistance nearby (the towns and bases the resistance has taken, and the
    resistance's own bases, within 3 km). A step costs 150 to tier 2, 400 to 3 (the walls), 600 to 4, 1000 to 5.
    Only a town still the occupier's (not taken, its office not held), below the highest tier it can reach
    (OT_fnc_officeTier), and out of every player's sight (not in spawn distance), so a new tier never goes up in
    front of a player; a town won back keeps its tier.

    Parameters:
        _this # 0: NUMBER - The turn's spending left
        _this # 1: NUMBER - The turn's chance (a spend goes ahead on random 100 > it)

    Usage: _spend = [_spend, _chance] call OT_fnc_NATOupgradeOffices;

    Returns: NUMBER - The spending left
*/

params ["_spend", "_chance"];

if ((random 100) <= _chance) exitWith { _spend };
private _resources = server getVariable ["NATOresources", 2000];
private _abandoned = server getVariable ["NATOabandoned", []];
private _theirs = (OT_allTowns + ((OT_objectiveData + OT_airportData + OT_commsData) apply { _x select 1 })) select { _x in _abandoned };
private _near = (_theirs apply { server getVariable [_x, [0, 0, 0]] }) + ((server getVariable ["bases", []]) apply { _x select 0 });
private _cost = { [150, 400, 600, 1000] select ((_this - 1) min 3) };

private _candidates = OT_allTowns select {
    private _town = _x;
    private _tier = [_town] call OT_fnc_officeTier;
    ([_town] call OT_fnc_officeLayout) isNotEqualTo []
        && { !(_town in _abandoned) }
        && { !(server getVariable [format ["officeheld%1", _town], false]) }
        && { _tier < ([_town, true] call OT_fnc_officeTier) }
        && { (_tier call _cost) <= (_spend min _resources) }
        && { !([server getVariable [_town, [0, 0, 0]]] call OT_fnc_inSpawnDistance) }
};
if (_candidates isEqualTo []) exitWith { _spend };

// The threat: a point per 100 people, 3 for each place of the resistance's within 3 km
private _threat = {
    private _pos = server getVariable [_this, [0, 0, 0]];
    ((server getVariable [format ["population%1", _this], 0]) / 100) + 3 * ({ (_x distance2D _pos) < 3000 } count _near)
};
private _town = ([_candidates, [], { _x call _threat }, "DESCEND"] call BIS_fnc_sortBy) select 0;
private _tier = [_town] call OT_fnc_officeTier;
private _price = _tier call _cost;
server setVariable [format ["officetier%1", _town], _tier + 1, true];
server setVariable ["NATOresources", _resources - _price];
diag_log format ["Overthrow: %1 raises %2's mayor's office to tier %3 (%4 resources)", OT_NATO_name, _town, _tier + 1, _price];
_spend - _price
