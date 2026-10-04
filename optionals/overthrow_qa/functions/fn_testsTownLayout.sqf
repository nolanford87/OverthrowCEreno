/*
    Description:
    The mayor's office layout editor (OTQA_fnc_townLayout), through its own code paths in a real town that
    has one of its bracket's candidate buildings: the town shown with that building as the office and the
    generator's tier 1 on it; a thing placed as Zeus would (counted as the town's); the tier saved (an
    OFFICE line, a TIER line with the count, one ITEM line per thing at its exact position); the next tier
    loaded (what stood plus the generator's tier 2 additions); the saved lines read back as the town's
    layout (OT_fnc_officeLayout) and shown again through OT_fnc_officeApplyLayout, everything where it was
    saved; and the town cleared with its real office building still standing, unhidden. Part of the current
    QA tests. Moves the host to the town and back; the saved layouts in play are left as they were.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

[
    ["Office layouts: save, next tier and reload in a real town", {
        call OTQA_fnc_officeReview;
        call OTQA_fnc_townLayout;
        private _from = getPosASL player;
        private _hadLayouts = !isNil "OT_officeLayouts";
        private _layouts = missionNamespace getVariable ["OT_officeLayouts", createHashMap];
        OT_officeLayouts = createHashMap; // No saved layouts while it runs: the guess and the generator's draft
        player allowDamage false;

        // A town of bracket 2 or 3 (a cap of 3 or 4: room for a next tier) with a candidate building of its own
        private _town = "";
        private _office = objNull;
        {
            if (([_x] call OTQA_townLayout_bracket) in [2, 3]) then {
                ([_x] call OTQA_townLayout_guess) params ["_b", "_parts", "_spawned"];
                if (_spawned) then { { deleteVehicle _x } forEach ([_b] + _parts) } else { _town = _x; _office = _b };
            };
            if (_town isNotEqualTo "") exitWith {};
        } forEach OT_allTowns;
        if (_town isEqualTo "") exitWith {
            OT_officeLayouts = [nil, _layouts] select _hadLayouts;
            format ["Office layouts: no bracket 2-3 town with a candidate building on %1", worldName] call OTQA_fnc_manual;
        };
        private _key = [_office] call OT_fnc_officeTemplateKey;
        private _count = {
            params ["_tier"];
            { (_x select 0) isEqualTo "guard" || { (_x select 0) isEqualTo "object" && { isClass (configFile >> "CfgVehicles" >> (_x select 1)) } } } count (([_key] call OT_fnc_officeTemplate) select (_tier - 1))
        };

        // Shown: the guessed office, the generator's tier 1
        OTQA_townLayout set ["towns", [_town]];
        [_town] call OTQA_townLayout_show;
        private _things = call OTQA_townLayout_live;
        ["Office layouts: the town shown with its candidate building as the office", (OTQA_townLayout get "building") isEqualTo _office && { !(OTQA_townLayout get "spawned") }, format ["%1: %2 at %3", _town, typeOf _office, (getPosATL _office) apply { round _x }]] call OTQA_fnc_check;
        ["Office layouts: the generator's tier 1 on it", (count _things) isEqualTo ([1] call _count) && { (OTQA_townLayout get "tier") isEqualTo 1 }, format ["%1 things, the template's tier 1 has %2", count _things, [1] call _count]] call OTQA_fnc_check;

        // Placed with Zeus (what the editor's CuratorObjectPlaced handler does), then saved
        private _extra = createVehicle ["Land_BagFence_Short_F", _office getPos [12, 45], [], 0, "CAN_COLLIDE"];
        _extra setDir 33;
        private _extraAt = getPosASL _extra;
        (OTQA_townLayout get "things") pushBack _extra;
        private _lines = call OTQA_townLayout_save;
        _things = call OTQA_townLayout_live;
        private _items = _lines select { ((_x splitString "|") select 3) isEqualTo "ITEM" };
        private _header = (_lines select 1) splitString "|";
        private _off = [];
        {
            private _f = _x splitString "|";
            private _at = parseSimpleArray (_f select 7);
            private _o = _things select _forEachIndex;
            if ((_at distance (getPosASL _o)) > 0.002 || { ((_f select 5) isEqualTo "guard") isNotEqualTo (_o isKindOf "CAManBase") }) then { _off pushBack [_forEachIndex, _f select 6] };
        } forEach _items;
        ["Office layouts: the save logs the office, the count and every thing at its exact position",
            ((_lines select 0) find (format ["|%1|OFFICE|%2|", _town, typeOf _office])) > -1 && { (parseNumber (_header select 5)) isEqualTo (count _things) } && { (count _items) isEqualTo (count _things) } && { (count _things) isEqualTo (([1] call _count) + 1) } && { _off isEqualTo [] },
            format ["%1 lines, %2 things (tier 1 + the placed one: %3), off: %4", count _lines, count _things, ([1] call _count) + 1, _off]] call OTQA_fnc_check;

        // The next tier: what stood plus the generator's tier 2 additions
        private _before = count _things;
        call OTQA_townLayout_next;
        private _after = count (call OTQA_townLayout_live);
        ["Office layouts: the next tier adds the generator's tier 2", (OTQA_townLayout get "tier") isEqualTo 2 && { _after isEqualTo (_before + ([2] call _count)) }, format ["tier %1, %2 things (%3 + %4)", OTQA_townLayout get "tier", _after, _before, [2] call _count]] call OTQA_fnc_check;

        // The saved lines read back as the town's layout (as merge_layouts.py writes it), and shown again
        private _snapshot = _items apply {
            private _f = _x splitString "|";
            private _guard = (_f select 5) isEqualTo "guard";
            [_f select 5, _f select 6, parseSimpleArray (_f select 7), if (_guard) then { parseNumber (_f select 8) } else { parseSimpleArray (_f select 8) }, (_f param [9, ""]) splitString ","]
        };
        private _o = (_lines select 0) splitString "|";
        OT_officeLayouts set [_town, [[_o select 4, parseSimpleArray (_o select 5), parseNumber (_o select 6), (_o select 7) isEqualTo "true"], [_snapshot, [], [], [], []]]];
        [_town] call OTQA_townLayout_show;
        _things = call OTQA_townLayout_live;
        private _misplaced = [];
        {
            private _thing = _x;
            private _item = (_thing getVariable ["OT_officeItem", []]) param [3, []];
            private _d = (getPosASL _thing) distance (_item param [2, [0, 0, 0]]);
            if (_d > ([0.05, 0.75] select (_thing isKindOf "CAManBase"))) then { _misplaced pushBack [_item param [1, typeOf _thing], (round (_d * 100)) / 100] };
        } forEach _things;
        ["Office layouts: a saved tier comes back where it was saved (a guard settles up to 0.75 m)",
            (OTQA_townLayout get "building") isEqualTo _office && { (count _things) isEqualTo (count _snapshot) } && { (_things findIf { (typeOf _x) isEqualTo "Land_BagFence_Short_F" && { ((getPosASL _x) distance2D _extraAt) < 0.05 } }) > -1 } && { _misplaced isEqualTo [] },
            format ["%1 things of %2 saved, misplaced: %3", count _things, count _snapshot, _misplaced]] call OTQA_fnc_check;

        // Cleared: the things gone, the real office standing as it was
        private _gone = call OTQA_townLayout_live;
        call OTQA_townLayout_clear;
        OTQA_townLayout deleteAt "town";
        sleep 2.5;
        private _left = (_gone + [_extra]) select { !isNull _x && { !isObjectHidden _x } };
        ["Office layouts: cleared, the real office still standing", _left isEqualTo [] && { alive _office } && { !isObjectHidden _office }, format ["%1 things left, office alive %2, hidden %3", count _left, alive _office, isObjectHidden _office]] call OTQA_fnc_check;

        OT_officeLayouts = [nil, _layouts] select _hadLayouts;
        player setPosASL _from;
        player allowDamage true;
    }, 180]
]
