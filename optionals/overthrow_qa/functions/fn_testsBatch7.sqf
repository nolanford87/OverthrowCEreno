/*
    Description:
    Batch 7 (fix/wanted-and-search): kill credit, NATO search, ACE cargo, disconnect handler, unconscious hint.
    Tests that need the player undercover skip themselves (listed as manual) when that isn't the case.
    Game state isn't preserved (the test save is disposable), but tests delete what they spawn.
    The unconscious test runs last as it blows the player's cover.

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

// Shared checks, compiled once so every test can call them
OTQA_b7_isUndercover = { alive player && { captive player } && { isNull objectParent player } };
OTQA_b7_spawnPassiveNATO = {
    params ["_pos"];
    private _grp = createGroup blufor;
    private _unit = _grp createUnit ["B_Soldier_F", _pos, [], 0, "CAN_COLLIDE"];
    { _unit disableAI _x } forEach ["MOVE", "TARGET", "AUTOTARGET", "AUTOCOMBAT", "FSM"];
    _unit;
};

"Kill NATO soldiers as the gunner of an armed vehicle: your BLU kill count and rewards go up" call OTQA_fnc_manual;
"During a real NATO search, move away twice: 'You tried to escape a NATO search' and your cover is blown" call OTQA_fnc_manual;

[
    ["Disconnect removes High Command module", {
        private _grp = createGroup sideLogic;
        private _logic = _grp createUnit ["Logic", [0, 0, 0], [], 0, "NONE"];
        missionNamespace setVariable ["OTQA_TEST_hc_module", _logic];

        // HandleDisconnect parameters: unit, id, uid, name
        [objNull, 0, "OTQA_TEST", "QA test"] call OT_fnc_playerDisconnectHandler;
        sleep 0.5;
        ["Disconnect removes High Command module", isNull _logic, "dummy module registered for uid OTQA_TEST"] call OTQA_fnc_check;

        if (!isNull _logic) then { deleteVehicle _logic };
        deleteGroup _grp;
        missionNamespace setVariable ["OTQA_TEST_hc_module", nil, true];
    }],

    ["Kill credit for vehicle gunner", {
        // Far corner of the map, away from towns and players. The victim is tagged as a vehicle garrison
        // unit of a fake base, a branch of the death handler that only changes the killer's kill count
        private _pos = [worldSize - 100, worldSize - 100, 0];
        private _crewGrp = createGroup civilian;
        private _veh = createVehicle ["C_Offroad_01_F", _pos, [], 0, "CAN_COLLIDE"];
        private _driver = _crewGrp createUnit ["C_man_1", _pos, [], 0, "CAN_COLLIDE"];
        private _gunner = _crewGrp createUnit ["C_man_1", _pos, [], 0, "CAN_COLLIDE"];
        _driver moveInDriver _veh;
        private _victimGrp = createGroup blufor;
        private _victims = [];
        private _makeVictim = {
            private _victim = _victimGrp createUnit ["B_Soldier_F", _pos getPos [30, 0], [], 0, "CAN_COLLIDE"];
            _victim setVariable ["vehgarrison", "OTQA_TEST"];
            server setVariable ["vehgarrisonOTQA_TEST", [typeOf _victim]];
            _victims pushBack _victim;
            _victim;
        };

        [call _makeVictim, _veh, _gunner] call OT_fnc_deathHandler;
        private _g = _gunner getVariable ["BLUkills", 0];
        private _d = _driver getVariable ["BLUkills", 0];
        ["Kill credited to the gunner (instigator)", (_g isEqualTo 1) && { _d isEqualTo 0 }, format ["gunner %1, driver %2 kills", _g, _d]] call OTQA_fnc_check;

        [call _makeVictim, _veh, objNull] call OT_fnc_deathHandler;
        _d = _driver getVariable ["BLUkills", 0];
        ["Kill falls back to the driver without an instigator", _d isEqualTo 1, format ["driver %1 kills", _d]] call OTQA_fnc_check;

        { deleteVehicle _x } forEach (_victims + [_driver, _gunner, _veh]);
        deleteGroup _crewGrp;
        deleteGroup _victimGrp;
        server setVariable ["vehgarrisonOTQA_TEST", nil];
    }],

    ["NATO search inventory lock", {
        if !(call OTQA_b7_isUndercover) exitWith {
            "Batch 7 search lock test skipped: be undercover (not wanted) and on foot, then run again" call OTQA_fnc_manual;
        };
        private _cop = [player getPos [4, getDir player]] call OTQA_b7_spawnPassiveNATO;
        private _search = [player, _cop] spawn OT_fnc_NATOsearch;
        private _timeout = time + 5;
        waitUntil { sleep 0.2; (player getVariable ["OT_beingSearched", false]) || { time > _timeout } };

        ["Search sets the inventory lock", player getVariable ["OT_beingSearched", false], ""] call OTQA_fnc_check;
        ["Cop is marked as searching", _cop getVariable ["OT_searching", false], ""] call OTQA_fnc_check;

        player action ["Gear", objNull];
        sleep 1;
        private _opened = !isNull (findDisplay 602);
        if (_opened) then { (findDisplay 602) closeDisplay 2 };
        ["Inventory can't be opened during a search", !_opened, ""] call OTQA_fnc_check;

        [player] call OT_fnc_savePlayerData;
        private _saved = (players_NS getVariable [getPlayerUID player, []]) findIf { (toLower (_x select 0)) isEqualTo "ot_beingsearched" };
        ["Search lock isn't written to the save", _saved isEqualTo -1, ""] call OTQA_fnc_check;

        terminate _search;
        player setVariable ["OT_beingSearched", false, true];
        private _grp = group _cop;
        deleteVehicle _cop;
        deleteGroup _grp;
    }],

    ["Search on wanted player releases cop", {
        if !(call OTQA_b7_isUndercover) exitWith {
            "Batch 7 wanted-player search test skipped: be undercover (not wanted) and on foot, then run again" call OTQA_fnc_manual;
        };
        private _cop = [player getPos [40, getDir player]] call OTQA_b7_spawnPassiveNATO;
        // All in one frame, so nothing can react to the player briefly not being captive
        isNil {
            player setCaptive false;
            [player, _cop] call OT_fnc_NATOsearch;
            player setCaptive true;
        };
        ["Cop isn't left marked as searching", !(_cop getVariable ["OT_searching", false]), ""] call OTQA_fnc_check;

        private _grp = group _cop;
        deleteVehicle _cop;
        deleteGroup _grp;
    }],

    ["ACE cargo contraband", {
        if !(call OTQA_b7_isUndercover) exitWith {
            "Batch 7 cargo test skipped: be undercover (not wanted) and on foot, then run again" call OTQA_fnc_manual;
        };
        // A NATO soldier within 7 m counts as seeing the player
        private _watcher = [player getPos [5, getDir player]] call OTQA_b7_spawnPassiveNATO;
        private _crate = createVehicle ["Box_IND_Support_F", player getPos [3, (getDir player) + 90], [], 0, "CAN_COLLIDE"];
        clearItemCargoGlobal _crate;
        clearMagazineCargoGlobal _crate;
        clearWeaponCargoGlobal _crate;
        clearBackpackCargoGlobal _crate;

        player setVariable ["SeenCacheNATO", nil];
        [_crate, player] call OT_fnc_cargoLoadedHandler;
        ["Loading legal cargo keeps cover", captive player, ""] call OTQA_fnc_check;

        private _illegal = OT_illegalItems select 0;
        if (isClass (configFile >> "CfgMagazines" >> _illegal)) then {
            _crate addMagazineCargoGlobal [_illegal, 1];
        } else {
            _crate addItemCargoGlobal [_illegal, 1];
        };
        player setVariable ["SeenCacheNATO", nil];
        [_crate, player] call OT_fnc_cargoLoadedHandler;
        private _blown = !captive player;
        player setCaptive true;
        ["Loading contraband while seen blows cover", _blown, format ["crate contained %1", _illegal]] call OTQA_fnc_check;

        deleteVehicle _crate;
        private _grp = group _watcher;
        deleteVehicle _watcher;
        deleteGroup _grp;
        player setVariable ["SeenCacheNATO", nil];
    }],

    ["Unconscious hint after an earlier revive", {
        if (isNil "ace_medical_fnc_setUnconscious") exitWith {
            "Unconscious test skipped: ace_medical_fnc_setUnconscious not available" call OTQA_fnc_manual;
        };
        // A stale medic count, as left behind by an AI revive before the fix
        player setVariable ["OT_informedMedics", 5];
        private _historyBefore = count OT_notifyHistory;

        [player, true] call ace_medical_fnc_setUnconscious;
        sleep 3;
        private _medics = player getVariable ["OT_informedMedics", 0];
        private _hinted = (OT_notifyHistory select [_historyBefore]) findIf { "You are unconscious" in _x } != -1;
        ["Medic count is reset when going unconscious", _medics <= 1, format ["medics informed: %1 (was 5)", _medics]] call OTQA_fnc_check;
        if (_medics isEqualTo 0) then {
            ["No medic nearby shows the respawn hint", _hinted, ""] call OTQA_fnc_check;
        } else {
            "An AI medic was nearby, so the respawn hint was correctly not shown. Run again away from your recruits to test the hint" call OTQA_fnc_manual;
        };

        [player, false] call ace_medical_fnc_setUnconscious;
        sleep 3;
        player setCaptive true;
        ["Player wakes up again", !(player getVariable ["ACE_isUnconscious", false]), ""] call OTQA_fnc_check;
    }]
]
