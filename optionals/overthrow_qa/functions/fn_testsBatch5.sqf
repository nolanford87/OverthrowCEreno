/*
    Description:
    Batch 5 (fix/save-load-persistence).
    Checks on the loaded save, a real gang joining the resistance, forced weather cycles and a real save.
    The save test runs last: afterwards restart the mission, load the save and run batch 5 again to
    finish the save/load round trip. Game state isn't preserved (the test save is disposable).

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"Dedicated server: players without a home building rejoin at their last position, not the map corner" call OTQA_fnc_manual;

[
    ["Save/load round trip", {
        // Finishes the round trip started by the save test of an earlier run
        if !(profileNamespace getVariable ["OTQA_roundtripPending", false]) exitWith {
            "Save/load round trip: not pending. This run's save test starts one, then restart, load the save and run batch 5 again" call OTQA_fnc_manual;
        };
        profileNamespace setVariable ["OTQA_roundtripPending", nil];
        saveProfileNamespace;
        private _squad = (server getVariable ["squads", []]) select { (_x select 0) isEqualTo "OTQA_OFFLINE" };
        ["Offline player's squad survives save and load", _squad isNotEqualTo [] && { ((_squad select 0) param [3, []]) isNotEqualTo [] },
            format ["entry after load: %1", _squad]] call OTQA_fnc_check;
    }],

    ["Base flags owned by their builder", {
        private _bases = server getVariable ["bases", []];
        if (_bases isEqualTo []) exitWith {
            "Base owner test skipped: no forward bases in this save" call OTQA_fnc_manual;
        };
        private _wrong = [];
        {
            _x params ["_pos", "_name", ["_owner", ""]];
            if (_owner isEqualTo "") then { continue }; // Older saves don't store the owner
            private _flag = (_pos nearObjects [OT_flag_IND, 20]) param [0, objNull];
            if (isNull _flag || { (_flag call OT_fnc_getOwner) isNotEqualTo _owner }) then {
                _wrong pushBack _name;
            };
        } forEach _bases;
        ["Base flags owned by their builder", _wrong isEqualTo [], format ["%1 bases, wrong owner or missing flag: %2", count _bases, _wrong]] call OTQA_fnc_check;
    }],

    ["Leased buildings have positions", {
        private _bad = [];
        private _count = 0;
        {
            {
                _x params ["_id", "", ["_pos", []]];
                _count = _count + 1;
                if !(_pos isEqualType [] && { count _pos >= 2 }) then { _bad pushBack _id };
            } forEach (_x getVariable ["leasedata", []]);
        } forEach (allPlayers - (entities "HeadlessClient_F"));
        if (_count isEqualTo 0) exitWith {
            "Lease position test skipped: no leased buildings" call OTQA_fnc_manual;
        };
        ["Leased buildings have positions", _bad isEqualTo [], format ["%1 leased, without a position: %2", _count, _bad]] call OTQA_fnc_check;
    }],

    ["No empty gang records", {
        private _bad = [];
        {
            private _gangs = OT_civilians getVariable [format ["gangs%1", _x], []];
            {
                private _gang = OT_civilians getVariable [format ["gang%1", _x], []];
                if (_gang isEqualTo []) then { _bad pushBack _x };
            } forEach _gangs;
        } forEach OT_allTowns;
        ["No empty gang records", _bad isEqualTo [], format ["gang ids listed in a town without a record: %1", _bad]] call OTQA_fnc_check;
    }],

    ["Gang joins the resistance", {
        // Nearest town that has gang camp positions
        private _towns = [OT_allTowns, [], { (server getVariable [_x, [0, 0, 0]]) distance2D player }, "ASCEND"] call BIS_fnc_sortBy;
        private _town = _towns param [(_towns findIf { (spawner getVariable [format ["gangpositions%1", _x], []]) isNotEqualTo [] }), ""];
        if (_town isEqualTo "") exitWith {
            ["Gang joins the resistance", false, "no town with gang positions found (towns get them when spawned, go near one)"] call OTQA_fnc_check;
        };
        private _gangid = [_town, false] call OT_fnc_formGang;
        if (_gangid < 0) exitWith {
            ["Gang joins the resistance", false, format ["formGang returned %1 in %2", _gangid, _town]] call OTQA_fnc_check;
        };
        private _leaderGrp = createGroup independent;
        private _leader = _leaderGrp createUnit ["I_G_Soldier_F", player getPos [5, 0], [], 0, "NONE"];
        [_leader, _gangid, player] call OT_fnc_gangJoinResistance;

        private _record = OT_civilians getVariable [format ["gang%1", _gangid], "removed"];
        private _listed = _gangid in (OT_civilians getVariable [format ["gangs%1", _town], []]);
        ["Joined gang's record is removed", _record isEqualTo "removed", format ["gang%1 in %2 is %3", _gangid, _town, _record]] call OTQA_fnc_check;
        ["Joined gang is removed from the town's gang list", !_listed, ""] call OTQA_fnc_check;
    }],

    ["Cloudy weather can last", {
        // Winter months have the highest chance to stay cloudy
        private _date = date;
        setDate [_date select 0, 12, _date select 2, _date select 3, _date select 4];
        private _results = [];
        for "_i" from 1 to 30 do {
            ot_weather_change_forecast = "Cloudy";
            ot_weather_change_time = time - 1;
            private _timeout = time + 5;
            waitUntil { sleep 0.2; ot_weather_change_time > time || { time > _timeout } };
            _results pushBack ot_weather_change_forecast;
        };
        private _stayed = { _x isEqualTo "Cloudy" } count _results;
        ["Cloudy weather can stay cloudy", _stayed > 0, format ["30 forced changes from Cloudy: %1 stayed Cloudy, %2 Clear, %3 Rain",
            _stayed, { _x isEqualTo "Clear" } count _results, { _x isEqualTo "Rain" } count _results]] call OTQA_fnc_check;
    }],

    ["Save keeps offline squads", {
        // A squad of a player who hasn't joined since the last load is still the saved unit list
        private _squads = server getVariable ["squads", []];
        if ((_squads findIf { (_x select 0) isEqualTo "OTQA_OFFLINE" }) isEqualTo -1) then {
            _squads pushBack ["OTQA_OFFLINE", "QA", "Not a group, pls recreate", [["I_G_Soldier_F", getPosATL player, []]], "QA offline squad"];
            server setVariable ["squads", _squads, true];
        };

        [objNull, true] call OT_fnc_saveGame;
        private _data = missionProfileNamespace getVariable [OT_saveName, []];
        private _saved = (_data select { (_x select 0) isEqualTo "squads" }) param [0, ["", []]] select 1;
        private _offline = _saved select { (_x select 0) isEqualTo "OTQA_OFFLINE" };
        ["Save keeps an offline player's squad", _offline isNotEqualTo [], format ["%1 squads saved", count _saved]] call OTQA_fnc_check;

        private _recruits = (_data select { (_x select 0) isEqualTo "recruits" }) param [0, ["", []]] select 1;
        private _short = { count _x < 7 } count _recruits;
        ["Saved recruits keep their XP field", _short isEqualTo 0, format ["%1 recruits, %2 without XP", count _recruits, _short]] call OTQA_fnc_check;

        profileNamespace setVariable ["OTQA_roundtripPending", true];
        saveProfileNamespace;
        "Save/load round trip started: restart the mission, load the save and run batch 5 again" call OTQA_fnc_manual;
    }]
]
