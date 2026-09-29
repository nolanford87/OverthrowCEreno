/*
    Description:
    Batch 2 (fix/nato-ai-loops): real jet/helicopter scrambles and a raid, checking NATO's resources.
    These spawn real NATO aircraft and a recon team. Game state isn't preserved (the test save is disposable).

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"After a QRF ends and you leave the area, NATO's surviving attackers despawn (bodies stay)" call OTQA_fnc_manual;
"Shoot down a NATO air patrol: once you leave, the wreck and crew are cleaned up" call OTQA_fnc_manual;

// Scramble aircraft at a target until NATO's random roll lets it through, returns what it cost
OTQA_b2_scramble = {
    params ["_type", "_threat", "_target"];
    private _cost = -1;
    // Unscheduled, so the NATO loop can't change the resources in between
    isNil {
        for "_i" from 1 to 80 do {
            server setVariable ["NATOresources", 1000];
            spawner setVariable ["NATOknownTargets", [[_type, getPos _target, _threat, _target, false, time]]];
            if ([] call OT_fnc_NATOscrambleAircraft) exitWith {
                _cost = 1000 - (server getVariable ["NATOresources", 0]);
            };
        };
    };
    _cost;
};

[
    ["Jet scramble cost", {
        private _target = createVehicle ["C_Heli_Light_01_civil_F", player getPos [3000, random 360], [], 0, "NONE"];
        private _cost = ["H", 200, _target] call OTQA_b2_scramble;
        ["Jet scramble costs NATO 250", _cost isEqualTo 250, format ["cost %1 (-1 = never scrambled)", _cost]] call OTQA_fnc_check;
    }],

    ["Helicopter scramble cost", {
        private _target = createVehicle ["C_Offroad_01_F", player getPos [3000, random 360], [], 0, "NONE"];
        private _cost = ["V", 150, _target] call OTQA_b2_scramble;
        ["Helicopter scramble costs NATO 100", _cost isEqualTo 100, format ["cost %1 (-1 = never scrambled)", _cost]] call OTQA_fnc_check;
    }],

    ["Raid cooldown", {
        // NATOsendRaid reads these from its caller (the NATO loop)
        private _diff = server getVariable ["OT_difficulty", 1];
        private _popControl = call OT_fnc_getControlledPopulation;
        private _knownTargets = [["FOB", player getPos [800, 0], 100, objNull, false, time]];
        private _raided = false;
        isNil {
            for "_i" from 1 to 80 do {
                spawner setVariable ["NATOlastRaid", 0];
                [1000, 0] call OT_fnc_NATOsendRaid;
                if ((_knownTargets select 0) select 4) exitWith { _raided = true };
            };
        };
        private _last = spawner getVariable ["NATOlastRaid", 0];
        ["Raid marks its target as handled", _raided, ""] call OTQA_fnc_check;
        ["Raid starts the cooldown", (time - _last) < 30, format ["NATOlastRaid %1 s ago", round (time - _last)]] call OTQA_fnc_check;
    }],

    ["Garrison vehicle lists are separate", {
        // Only meaningful in a new campaign, saved games load separate copies anyway
        private _names = (OT_objectiveData select { (server getVariable [format ["vehgarrison%1", _x select 1], []]) isNotEqualTo [] }) apply { _x select 1 };
        if (count _names < 2) exitWith {
            "Garrison list test skipped: fewer than 2 objectives with vehicle garrisons" call OTQA_fnc_manual;
        };
        private _listA = server getVariable format ["vehgarrison%1", _names select 0];
        _listA pushBack "OTQA_MARKER";
        private _shared = { "OTQA_MARKER" in (server getVariable [format ["vehgarrison%1", _x], []]) } count (_names select [1]);
        _listA deleteAt (_listA find "OTQA_MARKER");
        ["Objectives don't share one vehicle garrison list", _shared isEqualTo 0, format ["%1 other objectives affected", _shared]] call OTQA_fnc_check;
    }]
]
