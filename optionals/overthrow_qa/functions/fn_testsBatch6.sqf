/*
    Description:
    Batch 6 (fix/player-init): setupPlayer stacking, perk loop lifetime, waypoint watcher.
    The multiplayer-only fixes are listed as manual checks.

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"MP: have a friend with High Command squads join after you: their squads come back with their soldiers, and saving before they join keeps them" call OTQA_fnc_manual;
"MP: a friend's recruits keep their XP after someone else joins" call OTQA_fnc_manual;
"Get in a vehicle or open a box locked by another player: the message names that player (not 'any')" call OTQA_fnc_manual;
"Steal a NATO garrison vehicle (on a dedicated server or as a client): it doesn't reappear at the base after a restart" call OTQA_fnc_manual;
"Zeus 'Change Town Stability' module changes the town's stability" call OTQA_fnc_manual;
"Gun dealer lists each weapon once; import search finds items when typing capitals; a workshop weapon shows 'Get in <weapon> as Gunner'" call OTQA_fnc_manual;

[
    ["Reset UI doesn't restart player systems", {
        // Event handler IDs keep counting up, so a new dummy handler's ID shows whether any were added in between
        private _probe = { private _id = player addEventHandler ["Fired", {}]; player removeEventHandler ["Fired", _id]; _id };
        private _before = call _probe;
        private _captive = captive player;

        call OT_fnc_setupPlayer;

        private _after = call _probe;
        ["Reset UI adds no event handlers", _after isEqualTo (_before + 1), format ["handler id %1 -> %2", _before, _after]] call OTQA_fnc_check;
        ["Reset UI keeps wanted status", (captive player) isEqualTo _captive, format ["captive before %1, after %2", _captive, captive player]] call OTQA_fnc_check;
        ["Player systems registered for this body", (missionNamespace getVariable ["OT_setupPlayerUnit", objNull]) isEqualTo player, ""] call OTQA_fnc_check;
    }],

    ["Perk loop stops for other units", {
        if (isNil "ace_advanced_fatigue_anreserve") exitWith {
            "Perk loop test skipped: ACE advanced fatigue isn't running" call OTQA_fnc_manual;
        };
        private _saved = ace_advanced_fatigue_anreserve;
        ace_advanced_fatigue_anreserve = 1000;
        objNull call OT_fnc_perkSystem;
        private _changed = ace_advanced_fatigue_anreserve isNotEqualTo 1000;
        ace_advanced_fatigue_anreserve = _saved;
        ["Perk loop doesn't run for a unit that isn't the player", !_changed, ""] call OTQA_fnc_check;
    }],

    ["Waypoint watcher", {
        // Keep the current job waypoint, if any, to give it back afterwards
        private _oldMarker = missionNamespace getVariable ["OT_missionMarker", []];
        private _oldText = missionNamespace getVariable ["OT_missionMarkerText", ""];
        private _watchers = { { "givePlayerWaypoint" in (_x select 1) } count diag_activeSQFScripts };
        private _base = call _watchers;

        // Every waypoint used to leave a watcher script spinning without a sleep, only the newest should keep running
        [player, player getPos [1500, 0], "QA 1"] call OT_fnc_givePlayerWaypoint;
        [player, player getPos [1500, 90], "QA 2"] call OT_fnc_givePlayerWaypoint;
        [player, player getPos [1500, 180], "QA 3"] call OT_fnc_givePlayerWaypoint;
        sleep 2.5;
        private _running = call _watchers;
        ["Only the newest waypoint watcher keeps running", _running isEqualTo 1, format ["watchers running after 3 waypoints: %1 (%2 before)", _running, _base]] call OTQA_fnc_check;

        OT_waypointToken = OT_waypointToken + 1;
        sleep 1.5;
        private _left = call _watchers;
        ["Waypoint watcher stops when replaced", _left isEqualTo 0, format ["watchers running: %1", _left]] call OTQA_fnc_check;

        while { (waypoints group player) isNotEqualTo [] } do {
            deleteWaypoint ((waypoints group player) select 0);
        };
        OT_missionMarker = nil;
        if (_oldMarker isNotEqualTo []) then {
            [player, _oldMarker, _oldText] call OT_fnc_givePlayerWaypoint;
        };
    }]
]
