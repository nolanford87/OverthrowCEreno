/*
    Description:
    The live capture test (the "capturetest" QA mode, the Rodopoli pilot's step 7): not a test that runs by itself
    but a game set up for the host to play. Rodopoli at T4 and stability 0 with its office's capture under way
    (OT_fnc_officeCapture), the host put on the main street about 150 m out with an assault kit (a rifle and
    ammunition, grenades, ACE charges and a clacker for the gates, ACE's lockpick for the doors, medical), armed
    and not undercover. While the mission runs, a line every 15 s for following it from the RPT:
        OTLIVE|seconds in|guards alive|lost|the task's state|office held|attacking|host's distance|captive

    Returns: ARRAY - [[name, code, seconds]]
*/

[
    ["Live capture: Rodopoli at T4 set up", {
        private _town = "Rodopoli";
        server setVariable [format ["officetier%1", _town], 4, true];
        server setVariable [format ["stability%1", _town], 0, true];
        server setVariable [format ["compoundlost%1", _town], nil];
        // On the main street, 150 m out from the HQ past its main gate
        private _hq = ASLToAGL ((([_town] call OT_fnc_officeLayout) select 0) select 1);
        private _gates = ((([_town] call OT_fnc_officeLayout) select 1) select 3) select { (_x select 0) isEqualTo "gate" };
        private _gate = if (_gates isEqualTo []) then { _hq vectorAdd [0, 20, 0] } else { ASLToAGL (([_gates, [], { (ASLToAGL (_x select 2)) distance2D _hq }, "ASCEND"] call BIS_fnc_sortBy) select 0 select 2) };
        private _start = _hq vectorAdd ((vectorNormalized (_gate vectorDiff _hq)) vectorMultiply 150);
        private _road = (_start nearRoads 60) param [0, objNull];
        if (!isNull _road) then { _start = getPosATL _road };
        _start = _start findEmptyPosition [0, 30, "B_Soldier_F"];
        player setPosATL _start;
        player setDir (_start getDir _hq);
        // The kit
        removeAllWeapons player;
        player addWeapon "arifle_MX_F";
        for "_i" from 1 to 8 do { player addMagazine "30Rnd_65x39_caseless_mag" };
        for "_i" from 1 to 4 do { player addMagazine "HandGrenade" };
        for "_i" from 1 to 2 do { player addMagazine "SmokeShell" };
        player addBackpack "B_AssaultPack_mcamo";
        for "_i" from 1 to 3 do { player addItemToBackpack "DemoCharge_Remote_Mag" };
        player addItem "ACE_Clacker";
        player addItem "ACE_key_lockpick";
        for "_i" from 1 to 6 do { player addItem "ACE_fieldDressing" };
        player addItem "ACE_morphine";
        player setCaptive false;
        // The capture under way, its task up
        [_town] spawn OT_fnc_officeCapture;
        hint format ["Live capture test: Rodopoli at T4, stability 0, the task to take its office is up.\n\nYou're on the main street about 150 m from the compound with a rifle, grenades, 3 charges and a clacker (gates), a lockpick (doors).\n\nClear the compound, hold the HQ 2 minutes, then hold off the counter-attack (it comes in about 10 minutes)."];
        // The log, every 15 s while the game runs
        [_town] spawn {
            params ["_town"];
            private _t0 = time;
            while { true } do {
                private _guards = allUnits select { alive _x && { (_x getVariable ["OT_compoundGuard", ""]) isEqualTo _town } };
                diag_log format ["OTLIVE|%1|%2|%3|%4|%5|%6|%7|%8", round (time - _t0), count _guards, (server getVariable [format ["compoundlost%1", _town], [0, 0]]) select 0,
                    [format ["office%1", _town]] call BIS_fnc_taskState, server getVariable [format ["officeheld%1", _town], false],
                    server getVariable ["NATOattacking", ""], round (player distance2D (server getVariable [_town, [0, 0, 0]])), captive player];
                sleep 15;
            };
        };
        ["Live capture: set up, over to the player", true, format ["host at %1, %2 m from the HQ", mapGridPosition player, round (player distance2D _hq)]] call OTQA_fnc_check;
    }, 30]
]
