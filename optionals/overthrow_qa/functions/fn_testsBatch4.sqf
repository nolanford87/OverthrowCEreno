/*
    Description:
    Batch 4 (fix/virtualization-race): spawner busy flag, despawn guard, shop and police group leaks.
    Game state isn't preserved (the test save is disposable).

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"Drive up to a big NATO base, leave again before it has finished spawning: once it despawns no NATO soldiers are left standing there" call OTQA_fnc_manual;

[
    ["Spawner stays busy until spawned", {
        // A fake spawner whose code takes 3 seconds
        private _entry = ["OTQA_SPAWNER", [0, 0, 0], [0, 0, 0], { sleep 3 }, [], 0];
        _entry call OT_fnc_spawn;
        sleep 0.5;
        private _busy = !isNil { spawner getVariable "spawningOTQA_SPAWNER" };
        sleep 4;
        private _done = isNil { spawner getVariable "spawningOTQA_SPAWNER" };
        ["Spawner is marked busy while spawning", _busy, ""] call OTQA_fnc_check;
        ["Busy mark is cleared once spawned", _done, ""] call OTQA_fnc_check;
    }],

    ["Despawn waits for spawning", {
        private _loop = action_loop select { (_x select 0) isEqualTo "OT_virtualization_loop" };
        private _guarded = _loop isNotEqualTo [] && { "spawning%1" in str ((_loop select 0) select 2) };
        ["Virtualization loop won't despawn a spawner that is still spawning", _guarded, ""] call OTQA_fnc_check;
    }],

    ["Town without shops leaks no group", {
        private _town = OT_allTowns param [OT_allTowns findIf { (server getVariable [format ["activeshopsin%1", _x], []]) isEqualTo [] }, ""];
        if (_town isEqualTo "") exitWith {
            "Shop group test skipped: every town has shops" call OTQA_fnc_manual;
        };
        private _before = count (groups civilian);
        [_town, "OTQA_SPAWNER"] call OT_fnc_spawnShops;
        private _after = count (groups civilian);
        ["Spawning shops in a town without shops creates no group", _after isEqualTo _before, format ["%1: civilian groups %2 -> %3", _town, _before, _after]] call OTQA_fnc_check;
    }],

    ["Police not spawned for an unloaded town", {
        private _town = OT_allTowns param [OT_allTowns findIf { !((spawner getVariable [format ["townspawnid%1", _x], ""]) in OT_allSpawned) }, ""];
        if (_town isEqualTo "") exitWith {
            "Police test skipped: every town is spawned" call OTQA_fnc_manual;
        };
        private _before = count (groups independent);
        [_town, "Police" call OT_fnc_getSoldier, 2] call OT_fnc_createPoliceGroup;
        private _after = count (groups independent);
        ["Adding police to a town that isn't spawned creates no untracked group", _after isEqualTo _before, format ["%1: independent groups %2 -> %3", _town, _before, _after]] call OTQA_fnc_check;
    }]
]
