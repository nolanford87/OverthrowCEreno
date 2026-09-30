/*
    Description:
    Second review follow-ups (fix/review-followups): employee deaths, garrison lists, stats loop, job rewards.

    Returns: ARRAY - [[name, code], ...], part of the review and DLC QA tests (OTQA_fnc_testsFollowups)
*/

"Respawn, then use Reset UI a few times: the stats HUD keeps updating and doesn't flicker" call OTQA_fnc_manual;
"Multiplayer (as a non-host player): finish a 'Kill NATO' and an 'Operative transport' job, you get the money and the kill count hints, the host doesn't" call OTQA_fnc_manual;
"Save at night (after 19:00), restart and load: time runs at the night speed straight away" call OTQA_fnc_manual;
"New game screen: pick Occupier Loadouts (Standard, Faction Random, Fully Random), start, save and reload: the choice stays" call OTQA_fnc_manual;
"As a general, open the player list and select an offline player who never saved money: shows $0, no script error" call OTQA_fnc_manual;

// Far corner of the map, away from towns and players
OTQA_rv_spawnKill = {
    params ["_side", "_var", "_value"];
    private _pos = [worldSize - 100, worldSize - 100, 0];
    private _killerGrp = createGroup civilian;
    private _killer = _killerGrp createUnit ["C_man_1", _pos, [], 0, "CAN_COLLIDE"];
    private _victimGrp = createGroup _side;
    private _victim = _victimGrp createUnit [["C_man_1", "B_Soldier_F"] select (_side isEqualTo blufor), _pos getPos [30, 0], [], 0, "CAN_COLLIDE"];
    _victim setVariable [_var, _value];
    [_victim, _killer, _killer] call OT_fnc_deathHandler;
    { deleteVehicle _x } forEach [_victim, _killer];
    deleteGroup _killerGrp;
    deleteGroup _victimGrp;
};

[
    ["Employee death lowers the employee count", {
        server setVariable ["OTQA_TESTemploy", 3, true];
        [civilian, "employee", "OTQA_TEST"] call OTQA_rv_spawnKill;
        private _count = server getVariable ["OTQA_TESTemploy", -1];
        ["Business loses one employee", _count isEqualTo 2, format ["employees: %1 (was 3)", _count]] call OTQA_fnc_check;
        server setVariable ["OTQA_TESTemploy", nil, true];
    }],

    ["Vehicle garrison list update", {
        server setVariable ["vehgarrisonOTQA_TEST", ["B_Soldier_F", "OTQA_other"], true];
        [blufor, "vehgarrison", "OTQA_TEST"] call OTQA_rv_spawnKill;
        private _list = server getVariable ["vehgarrisonOTQA_TEST", []];
        ["Dead unit's class is removed from the list", _list isEqualTo ["OTQA_other"], format ["list: %1", _list]] call OTQA_fnc_check;

        // Not in the list: nothing else may be removed
        [blufor, "vehgarrison", "OTQA_TEST"] call OTQA_rv_spawnKill;
        _list = server getVariable ["vehgarrisonOTQA_TEST", []];
        ["Unlisted class leaves the list alone", _list isEqualTo ["OTQA_other"], format ["list: %1", _list]] call OTQA_fnc_check;
        server setVariable ["vehgarrisonOTQA_TEST", nil, true];
    }],

    ["Stats loop restart", {
        private _before = missionNamespace getVariable ["OT_statsLoopId", 0];
        player call OT_fnc_statsSystem;
        private _after = missionNamespace getVariable ["OT_statsLoopId", 0];
        ["Restarting the stats HUD replaces the old loop", _after isEqualTo (_before + 1), format ["loop id %1 -> %2", _before, _after]] call OTQA_fnc_check;
    }]
]
