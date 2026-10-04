/*
    Description:
    The mayor's office layout editor (OTQA_fnc_townLayout), through its own code paths in a real town that
    has one of its bracket's candidate buildings: the town shown with that building as the office, the
    generator's tier 1 on it and the host on the street in front of it; a thing placed as Zeus would
    (counted as the town's); tier 1 saved (an OFFICE line, a TIER line with the count, one ITEM line per thing
    at its exact position, kept as the town's layout) and on to tier 2 (what stood plus the generator's
    tier 2 additions); saved on to the town's highest tier and into the review; tier 1 shown again in the
    review where it was saved, and saved again there without leaving it; the town confirmed (shown again, a
    town with every tier saved going straight to the review); and the town cleared with its real office
    building still standing, unhidden. Part of the current QA tests. Moves the host to the town and back;
    the saved layouts in play are left as they were.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

[
    ["Office layouts: the editor's loop in a real town", {
        call OTQA_fnc_officeReview;
        call OTQA_fnc_townLayout;
        private _from = getPosASL player;
        private _hadLayouts = !isNil "OT_officeLayouts";
        private _layouts = missionNamespace getVariable ["OT_officeLayouts", createHashMap];
        OT_officeLayouts = createHashMap; // No saved layouts while it runs: the guess and the generator's draft
        player allowDamage false;

        // A town of bracket 2 or 3 (3 or 4 tiers) with a candidate building of its own
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
        private _cap = [_town] call OTQA_townLayout_cap;

        // Shown: the guessed office, the generator's tier 1, the host on the street in front
        OTQA_townLayout set ["towns", [_town]];
        [_town] call OTQA_townLayout_show;
        private _things = call OTQA_townLayout_live;
        ["Office layouts: the town shown with its candidate building as the office", (OTQA_townLayout get "building") isEqualTo _office && { !(OTQA_townLayout get "spawned") } && { (OTQA_townLayout get "cap") isEqualTo _cap }, format ["%1 (population %2, %3 tiers): %4 at %5", _town, server getVariable [format ["population%1", _town], 0], _cap, typeOf _office, (getPosATL _office) apply { round _x }]] call OTQA_fnc_check;
        ["Office layouts: the generator's tier 1 on it", (count _things) isEqualTo ([1] call _count) && { (OTQA_townLayout get "tier") isEqualTo 1 }, format ["%1 things, the template's tier 1 has %2", count _things, [1] call _count]] call OTQA_fnc_check;
        private _m = "OTQA_townLayout_office";
        ["Office layouts: a red 30 m circle on the map round the office", (markerShape _m) isEqualTo "ELLIPSE" && { (markerSize _m) isEqualTo [30, 30] } && { (markerColor _m) isEqualTo "ColorRed" } && { ((markerPos _m) distance2D _office) < 1 }, format ["%1 %2 %3, %4 m from the office", markerShape _m, markerSize _m, markerColor _m, round ((markerPos _m) distance2D _office)]] call OTQA_fnc_check;
        private _roadsNear = (_office nearRoads 50) isNotEqualTo [];
        ["Office layouts: the host on the street in front of the office", !_roadsNear || { isOnRoad (getPosATL player) } || { ((getPosATL player) nearRoads 5) isNotEqualTo [] }, format ["at %1, %2 m from the office, roads within 50 m of it: %3", (getPosATL player) apply { round _x }, round (player distance2D _office), _roadsNear]] call OTQA_fnc_check;

        // Placed with Zeus (what the editor's CuratorObjectPlaced handler does), then tier 1 saved and on to tier 2
        private _extra = createVehicle ["Land_BagFence_Short_F", _office getPos [12, 45], [], 0, "CAN_COLLIDE"];
        _extra setDir 33;
        private _extraAt = getPosASL _extra;
        private _gmg = createVehicle ["B_GMG_01_high_F", _office getPos [14, 60], [], 0, "CAN_COLLIDE"];
        (OTQA_townLayout get "things") append [_extra, _gmg];
        sleep 2; // A static weapon just made settles on the ground first (as one placed with Zeus has by the time it's saved)
        private _saved = call OTQA_townLayout_live;
        private _lines = call OTQA_townLayout_saveAndGo;
        private _items = _lines select { ((_x splitString "|") select 3) isEqualTo "ITEM" };
        private _snapshot = ((OT_officeLayouts getOrDefault [_town, [[], [[]]]]) select 1) select 0;
        private _off = [];
        {
            private _f = _x splitString "|";
            private _o = _saved select _forEachIndex;
            private _kind = ["object", "guard"] select (_o isKindOf "CAManBase");
            if (_o isKindOf "StaticWeapon") then { _kind = "static" };
            if (((parseSimpleArray (_f select 7)) distance (getPosASL _o)) > 0.002 || { (_f select 5) isNotEqualTo _kind }) then { _off pushBack [_forEachIndex, _f select 6] };
        } forEach _items;
        ["Office layouts: the save logs the office, the count and every thing at its exact position (a static weapon by role), kept as the town's tier 1",
            ((_lines select 0) find (format ["|%1|OFFICE|%2|", _town, typeOf _office])) > -1 && { (parseNumber (((_lines select 1) splitString "|") select 5)) isEqualTo (count _saved) } && { (count _items) isEqualTo (count _saved) } && { (count _saved) isEqualTo (([1] call _count) + 2) } && { (count _snapshot) isEqualTo (count _saved) } && { _off isEqualTo [] } && { (_items findIf { "|static|gmg|" in _x }) > -1 },
            format ["%1 lines, %2 things (tier 1 + the 2 placed: %3), %4 kept, off: %5, the GMG as static gmg: %6", count _lines, count _saved, ([1] call _count) + 2, count _snapshot, _off, (_items findIf { "|static|gmg|" in _x }) > -1]] call OTQA_fnc_check;
        private _now = count (call OTQA_townLayout_live);
        ["Office layouts: saving goes on to tier 2 with the generator's additions on top", (OTQA_townLayout get "tier") isEqualTo 2 && { !(OTQA_townLayout get "review") } && { _now isEqualTo ((count _saved) + ([2] call _count)) }, format ["tier %1, %2 things (%3 + %4)", OTQA_townLayout get "tier", _now, count _saved, [2] call _count]] call OTQA_fnc_check;

        // Saved on to the highest tier, then the review
        for "_i" from 1 to 5 do {
            if (OTQA_townLayout get "review") exitWith {};
            call OTQA_townLayout_saveAndGo;
        };
        private _tiers = (OT_officeLayouts get _town) select 1;
        ["Office layouts: saved up to the town's highest tier, then the review", (OTQA_townLayout get "review") && { (OTQA_townLayout get "tier") isEqualTo _cap } && { ((_tiers select [0, _cap]) findIf { _x isEqualTo [] }) isEqualTo -1 } && { ((_tiers select [_cap]) findIf { _x isNotEqualTo [] }) isEqualTo -1 } && { !([_town] call OTQA_townLayout_unfinished) },
            format ["review %1, tier %2 of %3, things per saved tier %4", OTQA_townLayout get "review", OTQA_townLayout get "tier", _cap, _tiers apply { count _x }]] call OTQA_fnc_check;

        // The review: tier 1 shown as it was saved, saved again without leaving it
        [1] call OTQA_townLayout_reviewShow;
        _things = call OTQA_townLayout_live;
        private _misplaced = [];
        {
            private _thing = _x;
            private _item = (_thing getVariable ["OT_officeItem", []]) param [3, []];
            private _d = (getPosASL _thing) distance (_item param [2, [0, 0, 0]]);
            if (_d > ([0.05, 0.75] select (_thing isKindOf "CAManBase"))) then { _misplaced pushBack [_item param [1, typeOf _thing], (round (_d * 100)) / 100] };
        } forEach _things;
        ["Office layouts: the review shows a saved tier where it was saved (a guard settles up to 0.75 m)",
            (OTQA_townLayout get "tier") isEqualTo 1 && { (count _things) isEqualTo (count _snapshot) } && { (_things findIf { (typeOf _x) isEqualTo "Land_BagFence_Short_F" && { ((getPosASL _x) distance2D _extraAt) < 0.05 } }) > -1 } && { _misplaced isEqualTo [] },
            format ["tier %1, %2 things of %3 saved, misplaced: %4", OTQA_townLayout get "tier", count _things, count _snapshot, _misplaced]] call OTQA_fnc_check;
        call OTQA_townLayout_saveAndGo;
        ["Office layouts: a tier saved again in the review stays shown", (OTQA_townLayout get "review") && { (OTQA_townLayout get "tier") isEqualTo 1 } && { (count (((OT_officeLayouts get _town) select 1) select 0)) isEqualTo (count _snapshot) }, format ["review %1, tier %2", OTQA_townLayout get "review", OTQA_townLayout get "tier"]] call OTQA_fnc_check;

        // Confirmed: on to the next town (the same one here, every tier saved: straight to the review)
        [1] call OTQA_townLayout_step;
        ["Office layouts: a town with every tier saved opens in the review", (OTQA_townLayout get "town") isEqualTo _town && { OTQA_townLayout get "review" } && { (OTQA_townLayout get "building") isEqualTo _office } && { (count (call OTQA_townLayout_live)) isEqualTo (count _snapshot) }, format ["%1, review %2, %3 things", OTQA_townLayout get "town", OTQA_townLayout get "review", count (call OTQA_townLayout_live)]] call OTQA_fnc_check;

        // Cleared: the things gone, the real office standing as it was, the circle gone
        private _gone = call OTQA_townLayout_live;
        call OTQA_townLayout_clear;
        OTQA_townLayout deleteAt "town";
        sleep 2.5;
        private _left = (_gone + [_extra, _gmg]) select { !isNull _x && { !isObjectHidden _x } };
        ["Office layouts: cleared, the real office still standing", _left isEqualTo [] && { alive _office } && { !isObjectHidden _office } && { (markerShape _m) isEqualTo "" }, format ["%1 things left, office alive %2, hidden %3, circle %4", count _left, alive _office, isObjectHidden _office, markerShape _m]] call OTQA_fnc_check;

        // Another town with the same building starts from this town's layout, moved onto its office, and its next
        // tier adds what this town's next tier added
        private _second = "";
        private _office2 = objNull;
        {
            if (_x isNotEqualTo _town) then {
                ([_x] call OTQA_townLayout_guess) params ["_b", "_parts", "_spawned"];
                if (_spawned) then { { deleteVehicle _x } forEach ([_b] + _parts) } else {
                    if (([_b] call OT_fnc_officeTemplateKey) isEqualTo _key) then { _second = _x; _office2 = _b };
                };
            };
            if (_second isNotEqualTo "") exitWith {};
        } forEach OT_allTowns;
        if (_second isEqualTo "") then {
            format ["Office layouts: baseline not checked, no other town on %1 with a real %2", worldName, _key] call OTQA_fnc_manual;
        } else {
            private _aTiers = (OT_officeLayouts get _town) select 1;
            OTQA_townLayout set ["towns", [_second]];
            [_second] call OTQA_townLayout_show;
            private _expected = [_aTiers select 0, (OT_officeLayouts get _town) select 0, _office2] call OTQA_townLayout_moveItems;
            _things = call OTQA_townLayout_live;
            private _wrong = _things select {
                private _thing = _x;
                private _e = _expected findIf { ((_x select 2) distance (getPosASL _thing)) < ([0.05, 0.75] select (_thing isKindOf "CAManBase")) };
                _e isEqualTo -1
            };
            ["Office layouts: a town with the same building starts from the other town's layout",
                ((OTQA_townLayout get "baseline") param [0, ""]) isEqualTo _town && { (OTQA_townLayout get "building") isEqualTo _office2 } && { (count _things) isEqualTo (count (_aTiers select 0)) } && { _wrong isEqualTo [] },
                format ["%1 from %2: %3 things of %4, %5 not where moved", _second, (OTQA_townLayout get "baseline") param [0, "none"], count _things, count (_aTiers select 0), count _wrong]] call OTQA_fnc_check;
            if ((OTQA_townLayout get "cap") >= 2) then {
                private _before = count _things;
                call OTQA_townLayout_saveAndGo;
                private _adds = count ([_aTiers select 1, _aTiers select 0] call OTQA_townLayout_added);
                private _now = count (call OTQA_townLayout_live);
                ["Office layouts: its next tier adds the other town's additions for it", (OTQA_townLayout get "tier") isEqualTo 2 && { _now isEqualTo (_before + _adds) }, format ["tier %1, %2 things (%3 + %4)", OTQA_townLayout get "tier", _now, _before, _adds]] call OTQA_fnc_check;
            };
            call OTQA_townLayout_clear;
            OTQA_townLayout deleteAt "town";
            sleep 2;
        };

        OT_officeLayouts = [nil, _layouts] select _hadLayouts;
        player setPosASL _from;
        player allowDamage true;
    }, 240]
]
