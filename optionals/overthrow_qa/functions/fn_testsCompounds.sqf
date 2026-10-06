/*
    Description:
    The occupier compounds' work in progress (tools/officegen/COMPOUND_PLAN.md, the Rodopoli pilot's step 4 on).
    Part of the current QA tests; the finished steps are in OTQA_fnc_testsOfficeGameplay (archived).
    1. Gates worked by the occupier: a closed gate opens for an occupier soldier, not for one of ours, shuts
       10 s after; the town taken opens and unlocks it
    2. An occupier soldier walks out of Rodopoli's T3 compound and back in through its gate shut (the path
       finding plans no way through a shut gate: it opens for one going somewhere within 40 m)
    3. Static weapons by role: the hmg role a machine gun, the vanilla AT static read as at
    (A truck can't drive in, even through the gate open: the vehicle path finding gives up, so occupier
    vehicles park and unload outside the gate, the user's choice.)

    Returns: ARRAY - [[name, code, seconds], ...]
*/

call OTQA_fnc_testsOfficeHelpers;

private _tests = [];

_tests pushBack ["Office: gates worked by the occupier, open once taken", {
    private _town = "Rodopoli";
    private _o = _town call OTQA_og_officePos;
    private _at = AGLToASL [(_o select 0) + 400, (_o select 1) - 400, 0];
    (([[["object", "Land_NetFence_01_m_gate_F", _at, [[0, 1, 0], [0, 0, 1]], ["ground"]]], west, false, [_town, 3]] call OT_fnc_officeSpawnItems) select 0) params ["_gate"];
    private _phase = { _gate animationSourcePhase "Door_1_sound_source" };
    sleep 2;
    private _shut0 = (call _phase) < 0.1;
    private _ours = ([ASLToAGL _at vectorAdd [0, -4, 0]] call OTQA_og_ours);
    sleep 4;
    private _notOurs = (call _phase) < 0.1;
    deleteVehicle _ours;
    private _grp = createGroup [blufor, true];
    private _them = _grp createUnit ["B_Soldier_F", ASLToAGL _at vectorAdd [0, -4, 0], [], 0, "CAN_COLLIDE"];
    _them disableAI "MOVE";
    _them allowDamage false;
    sleep 4;
    private _opened = (call _phase) > 0.9;
    deleteVehicle _them;
    sleep 6;
    private _stillOpen = (call _phase) > 0.9;
    sleep 8;
    private _shutAgain = (call _phase) < 0.1 && { (_gate getVariable [format ["bis_disabled_Door_%1", 1], 0]) isEqualTo 1 };
    ["Gates: shut and locked, not opened for ours, opened for theirs, shut 10 s after", _shut0 && _notOurs && _opened && _stillOpen && _shutAgain, format ["shut %1, ours left it %2, opened %3, open 6 s after %4, shut and locked 14 s after %5", _shut0, _notOurs, _opened, _stillOpen, _shutAgain]] call OTQA_fnc_check;
    // The town taken: the gate unlocked and swung open
    server setVariable [format ["officeheld%1", _town], true, true];
    [_town, 0] call OT_fnc_officeDoors;
    sleep 2;
    private _taken = (call _phase) > 0.9 && { (_gate getVariable [format ["bis_disabled_Door_%1", 1], 0]) isEqualTo 0 };
    server setVariable [format ["officeheld%1", _town], nil, true];
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
    deleteVehicle _gate;
    ["Gates: the town taken, its gate unlocked and open", _taken, str _taken] call OTQA_fnc_check;
}, 60];

_tests pushBack ["Office: the occupier's men walk out and in through a shut gate", {
    private _town = "Rodopoli";
    ([_town, 3, west, true] call OT_fnc_officeApplyLayout) params ["", "_objects", "_guards"];
    private _gate = (_objects select { "gate" in toLower typeOf _x }) param [0, objNull];
    private _marker = ((([_town] call OT_fnc_officeLayout) select 1) select 2) select { (_x select 0) isEqualTo "gate" };
    if (isNull _gate || { _marker isEqualTo [] }) exitWith {
        { deleteVehicle _x } forEach (_objects + _guards);
        ["Walk: Rodopoli's T3 gate found", false, format ["gate %1, markers %2", _gate, count _marker]] call OTQA_fnc_check;
    };
    // The gate shut, locked and worked by the occupier, as a closed gate is in play
    _gate setVariable ["bis_disabled_Door_1", 1, true];
    _gate setVariable ["bis_disabled_Door_2", 1, true];
    _gate setVariable ["OT_officeGate", true, true];
    _gate enableSimulationGlobal true;
    [_gate] call OT_fnc_officeGates;
    private _gp = ASLToAGL ((_marker select 0) select 2);
    private _hq = _town call OTQA_og_officePos;
    private _out = (_gp vectorDiff _hq) vectorMultiply (1 / ((_gp distance2D _hq) max 1));
    private _in = _gp vectorAdd (_out vectorMultiply -10);
    private _far = _gp vectorAdd (_out vectorMultiply 30);
    _in set [2, 0];
    _far set [2, 0];
    private _walk = {
        params ["_from", "_to"];
        sleep 12; // The gate shut again behind the last
        private _shut = (_gate animationSourcePhase "Door_1_sound_source") < 0.1;
        private _grp = createGroup [blufor, true];
        private _man = _grp createUnit ["B_Soldier_F", _from, [], 0, "CAN_COLLIDE"];
        _man allowDamage false;
        _grp setBehaviour "AWARE";
        [_man, ([-(_out select 1), _out select 0, 0] vectorMultiply 14) vectorAdd [0, 0, 12]] call OTQA_og_camera;
        _man doMove _to;
        private _t = time + 90;
        private _next = 0;
        waitUntil {
            sleep 1;
            if (time > _next) then {
                _next = time + 5;
                diag_log format ["OTGATEWALKSTEP|%1 m to go|speed %2|expected %3|command %4|gate %5", round (_man distance2D _to), round speed _man, expectedDestination _man, currentCommand _man, _gate animationSourcePhase "Door_1_sound_source"];
            };
            (_man distance2D _to) < 4 || { time > _t }
        };
        private _took = round (90 - (_t - time));
        private _there = (_man distance2D _to) < 4;
        call OTQA_og_cameraOff;
        deleteVehicle _man;
        [_shut, _there, _took]
    };
    private _outward = [_in, _far] call _walk;
    private _inward = [_far, _in] call _walk;
    diag_log format ["OTGATEWALK|%1|out %2|in %3", _town, _outward, _inward];
    { deleteVehicle _x } forEach (_objects + _guards);
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
    [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;
    ["Walk: an occupier soldier gets out through the shut gate", (_outward select 0) && { _outward select 1 }, format ["gate shut first %1, out %2 in %3 s", _outward select 0, _outward select 1, _outward select 2]] call OTQA_fnc_check;
    ["Walk: an occupier soldier gets in through the shut gate", (_inward select 0) && { _inward select 1 }, format ["gate shut first %1, in %2 in %3 s", _inward select 0, _inward select 1, _inward select 2]] call OTQA_fnc_check;
}, 240];

_tests pushBack ["Office: static weapons by role", {
    private _hmg = ["hmg"] call OT_fnc_officeStatic;
    private _weapon = (getArray (configFile >> "CfgVehicles" >> _hmg >> "Turrets" >> "MainTurret" >> "weapons")) param [0, ""];
    private _mag = (getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines")) param [0, ""];
    private _sim = getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _mag >> "ammo") >> "simulation");
    ["Statics: the hmg role is a machine gun (fires bullets)", _sim isEqualTo "shotBullet", format ["%1 fires %2", _hmg, _sim]] call OTQA_fnc_check;
    ["Statics: the vanilla AT static reads as at, the HMG as hmg", (["B_static_AT_F"] call OT_fnc_officeStatic) isEqualTo "at" && { (["B_HMG_01_high_F"] call OT_fnc_officeStatic) isEqualTo "hmg" }, format ["AT %1, HMG %2", ["B_static_AT_F"] call OT_fnc_officeStatic, ["B_HMG_01_high_F"] call OT_fnc_officeStatic]] call OTQA_fnc_check;
}, 10];

_tests
