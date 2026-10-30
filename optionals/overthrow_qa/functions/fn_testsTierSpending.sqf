/*
    Description:
    The occupier raising a town's mayor's office a tier (OT_fnc_NATOupgradeOffices, the user's rules): one town a
    turn, one tier up, the step's price off its resources and the turn's budget, a town of its own out of every
    player's sight and below its highest tier, the most threatened first (size and the resistance nearby); not
    on a failed chance roll or a budget under the cheapest step. Part of the archived QA tests. Puts the tiers and
    resources back after.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

[
    ["Office: the occupier raises a town's tier", {
        private _towns = OT_allTowns select { ([_x] call OT_fnc_officeLayout) isNotEqualTo [] };
        private _var = { format ["officetier%1", _this] };
        private _saved = _towns apply { server getVariable (_x call _var) };
        private _keepRes = server getVariable ["NATOresources", 2000];
        private _tiers = { _towns apply { [_x] call OT_fnc_officeTier } };
        server setVariable ["NATOresources", 5000];

        private _before = call _tiers;
        private _left = [2000, -1] call OT_fnc_NATOupgradeOffices;
        private _after = call _tiers;
        private _changed = [];
        { if (_x isNotEqualTo (_before select _forEachIndex)) then { _changed pushBack [_towns select _forEachIndex, _before select _forEachIndex, _x] } } forEach _after;
        (_changed param [0, ["", 0, 0]]) params ["_town", "_from", "_to"];
        private _price = [150, 400, 600, 1000] select ((_from - 1) max 0 min 3);
        private _paid = 5000 - (server getVariable ["NATOresources", 5000]);
        ["Tier spending: one town one tier up, its price paid, out of sight and below its cap",
            (count _changed) isEqualTo 1 && { _to isEqualTo (_from + 1) } && { _paid isEqualTo _price } && { _left isEqualTo (2000 - _price) }
                && { !([server getVariable [_town, [0, 0, 0]]] call OT_fnc_inSpawnDistance) } && { _to <= ([_town, true] call OT_fnc_officeTier) },
            format ["%1: tier %2 -> %3, paid %4 (step %5), budget left %6", _town, _from, _to, _paid, _price, _left]] call OTQA_fnc_check;

        private _mid = call _tiers;
        [2000, 101] call OT_fnc_NATOupgradeOffices;
        [100, -1] call OT_fnc_NATOupgradeOffices;
        ["Tier spending: nothing on a failed roll or a budget under the cheapest step", (call _tiers) isEqualTo _mid, ""] call OTQA_fnc_check;

        { server setVariable [_x call _var, _saved select _forEachIndex, true] } forEach _towns;
        server setVariable ["NATOresources", _keepRes];
    }, 10]
]
