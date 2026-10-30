/*
    Description:
    The mayor's offices' starting tiers a new game sets (OT_fnc_officeStartTiers from OT_fnc_initNATO, the user's
    rules): every office town has one, never above its bracket + 1; hamlets at most tier 2, about a fifth of them
    there; the strongholds tier 3 or more, exactly one at tier 5, the one nearest the occupier's HQ; the
    resistance's start town tier 1. Reads what the new game set, changes nothing. Part of the archived QA tests.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

[
    ["Office: the starting tiers a new game sets", {
        private _towns = OT_allTowns select { ([_x] call OT_fnc_officeLayout) isNotEqualTo [] };
        private _tierOf = { server getVariable [format ["officetier%1", _this], -1] };
        private _bracket = { [_this] call OT_fnc_officeBracket };
        private _bad = _towns select { private _t = _x call _tierOf; _t < 1 || { _t > 5 } || { _t > ((_x call _bracket) + 1) } };
        ["Start tiers: every office town has one, 1 to its bracket + 1", _bad isEqualTo [] && { _towns isNotEqualTo [] },
            format ["%1 towns, off: %2", count _towns, _bad apply { [_x, _x call _tierOf, _x call _bracket] }]] call OTQA_fnc_check;

        private _hamlets = _towns select { (_x call _bracket) isEqualTo 1 };
        private _t2 = _hamlets select { (_x call _tierOf) isEqualTo 2 };
        ["Start tiers: hamlets tier 1 or 2, about a fifth at 2", (_hamlets findIf { (_x call _tierOf) > 2 }) < 0 && { (count _t2) <= round (0.2 * count _hamlets) },
            format ["%1 hamlets, at tier 2: %2", count _hamlets, _t2]] call OTQA_fnc_check;

        private _strong = _towns select { (_x call _bracket) >= 4 };
        private _five = _strong select { (_x call _tierOf) isEqualTo 5 };
        private _nearest = ([_strong, [], { (server getVariable [_x, [0, 0, 0]]) distance2D OT_NATO_HQPos }, "ASCEND"] call BIS_fnc_sortBy) param [0, ""];
        ["Start tiers: strongholds tier 3+, one at tier 5, the nearest the occupier's HQ",
            (_strong findIf { (_x call _tierOf) < 3 }) < 0 && { _five isEqualTo [_nearest] },
            format ["%1; tier 5: %2, nearest the HQ (%3): %4", _strong apply { [_x, _x call _tierOf] }, _five, OT_NATO_HQ, _nearest]] call OTQA_fnc_check;

        private _start = server getVariable ["spawntown", ""];
        ["Start tiers: the resistance's start town tier 1", !(_start in _towns) || { (_start call _tierOf) isEqualTo 1 },
            format ["%1: %2", _start, _start call _tierOf]] call OTQA_fnc_check;

        private _mid = _towns select { (_x call _bracket) in [2, 3] };
        ["Start tiers: the towns' spread (tier 1 / 2 / 3)", true,
            format ["%1 towns: %2", count _mid, [1, 2, 3, 4] apply { private _t = _x; _mid select { (_x call _tierOf) isEqualTo _t } }]] call OTQA_fnc_check;
    }, 10]
]
