/*
    Description:
    FOB clear-up (OT_fnc_NATOclearFOB), with a real FOB built 250-400 m from the host like a loaded
    game builds one (flag, soldiers, upgrades). Part of the current QA tests.
    1. Lost: its soldiers are killed, the host walks in, the FOB check clears it: its construction
       (flag, barriers, sandbags, HMGs) goes, the bodies stay
    2. Won: its takeover timer runs out, its vehicle joins the town's garrison; with the host over
       1 km away it disbands: construction and living soldiers go, bodies and the vehicle stay

    Returns: ARRAY - [[name, code, seconds], ...]
*/

// Builds a FOB near the host: its position, [] if no spot was found
OTQA_fob_build = {
    params ["_upgrades"];
    private _p = [getPos player, 250, 400, 15, 0, 0.3, 0] call BIS_fnc_findSafePos;
    if ((_p distance2D player) > 600) exitWith { [] };
    private _pos = [_p select 0, _p select 1, 0];
    OT_flag_NATO createVehicle _pos;
    private _fobs = server getVariable ["NATOfobs", []];
    _fobs pushBack [_pos, 4, +_upgrades];
    server setVariable ["NATOfobs", _fobs, true];
    private _group = createGroup blufor;
    for "_i" from 1 to 4 do {
        private _civ = _group createUnit [selectRandom OT_NATO_Units_LevelOne, [[[_pos, 30]]] call BIS_fnc_randomPos, [], 0, "NONE"];
        _civ setVariable ["garrison", "HQ", false];
        _civ setVariable ["OT_fob", _pos];
    };
    _group call OT_fnc_initMilitaryPatrol;
    [_pos, _upgrades] spawn OT_fnc_NATOupgradeFOB;
    _pos;
};

// What it built still standing (flag, barriers, sandbags, statics)
OTQA_fob_built = {
    params ["_pos"];
    count (nearestObjects [_pos, [OT_flag_NATO, OT_NATO_Barrier_Small, OT_NATO_Barrier_Large, OT_NATO_Sandbag_Curved, OT_NATO_HMG, OT_NATO_Mortar] + OT_NATO_StaticGarrison_LevelOne, 60]);
};

OTQA_fob_units = {
    params ["_pos", "_alive"];
    (allDeadMen + allUnits) select { alive _x isEqualTo _alive && { (_x getVariable ["OT_fob", []]) isEqualTo _pos } };
};

private _tests = [];

_tests pushBack ["FOB lost: construction cleared, bodies stay", {
    private _home = getPosATL player;
    private _pos = [["Barriers", "HMG"]] call OTQA_fob_build;
    if (_pos isEqualTo []) exitWith { ["FOB lost: a spot for the FOB", false, "none found near the host"] call OTQA_fnc_check };
    private _timeout = time + 20;
    waitUntil { sleep 1; ([_pos] call OTQA_fob_built) >= 13 || { time > _timeout } };
    private _built = [_pos] call OTQA_fob_built;
    ["FOB lost: it's built", _built >= 13, format ["%1 objects", _built]] call OTQA_fnc_check;

    { _x setDamage 1 } forEach ([_pos, true] call OTQA_fob_units);
    sleep 2;
    private _dead = count ([_pos, false] call OTQA_fob_units);
    // Any other occupier soldier within 300 m still holds it: killed too (named in the result)
    private _others = (_pos nearEntities ["CAManBase", 300]) select { alive _x && { side group _x isEqualTo blufor } };
    private _othersText = str (_others apply { format ["%1 (%2, %3 m)", typeOf _x, _x getVariable ["garrison", ""], round (_x distance2D _pos)] });
    { _x setDamage 1 } forEach _others;
    player setPosATL (_pos getPos [8, random 360]);
    sleep 3;
    call OT_fnc_NATOcheckFOBs;
    sleep 1;

    ["FOB lost: it's off the FOB list", ((server getVariable ["NATOfobs", []]) findIf { (_x select 0) isEqualTo _pos }) isEqualTo -1,
        format ["other occupier soldiers near it: %1", _othersText]] call OTQA_fnc_check;
    private _left = [_pos] call OTQA_fob_built;
    ["FOB lost: its construction is cleared", _left isEqualTo 0, format ["%1 objects left", _left]] call OTQA_fnc_check;
    private _bodies = [_pos, false] call OTQA_fob_units;
    ["FOB lost: the bodies stay", (count _bodies) isEqualTo _dead && { _dead >= 8 }, format ["%1 of %2 bodies", count _bodies, _dead]] call OTQA_fnc_check;
    ["FOB lost: no body left in a static", (_bodies findIf { !isNull objectParent _x }) isEqualTo -1, ""] call OTQA_fnc_check;

    { deleteVehicle _x } forEach _bodies;
    player setPosATL _home;
}, 120];

_tests pushBack ["FOB won: vehicle joins the town, construction cleared", {
    private _home = getPosATL player;
    private _pos = [["Barriers", "HMG", "Vehicle"]] call OTQA_fob_build;
    if (_pos isEqualTo []) exitWith { ["FOB won: a spot for the FOB", false, "none found near the host"] call OTQA_fnc_check };
    private _veh = objNull;
    private _timeout = time + 25;
    waitUntil {
        sleep 1;
        _veh = vehicles select { alive _x && { (_x getVariable ["OT_fobVehicle", []]) isEqualTo _pos } } param [0, objNull];
        (([_pos] call OTQA_fob_built) >= 13 && { !isNull _veh }) || { time > _timeout }
    };
    ["FOB won: it's built with its vehicle", !isNull _veh, format ["%1 objects, %2", [_pos] call OTQA_fob_built, typeOf _veh]] call OTQA_fnc_check;
    if (isNull _veh) exitWith { player setPosATL _home };
    private _type = typeOf _veh;

    // A soldier on foot killed: his body stays
    private _victim = ([_pos, true] call OTQA_fob_units) select { isNull objectParent _x } param [0, objNull];
    _victim setDamage 1;

    // Its takeover timer runs out
    private _town = _pos call OT_fnc_nearestTown;
    private _listBefore = { _x isEqualTo _type } count (server getVariable [format ["vehgarrison%1", _town], []]);
    private _timers = server getVariable ["NATOfobTimers", []];
    _timers pushBack [_pos, 1, _town];
    server setVariable ["NATOfobTimers", _timers];
    OT_fobTimerLast = time - 5;
    call OT_fnc_NATOFOBtimers;

    private _listAfter = { _x isEqualTo _type } count (server getVariable [format ["vehgarrison%1", _town], []]);
    ["FOB won: its vehicle joins the town's garrison", alive _veh && { (_veh getVariable ["vehgarrison", ""]) isEqualTo _town } && { _listAfter isEqualTo (_listBefore + 1) },
        format ["%1 on %2's list: %3 -> %4", _type, _town, _listBefore, _listAfter]] call OTQA_fnc_check;
    private _fob = (server getVariable ["NATOfobs", []]) select { (_x select 0) isEqualTo _pos } param [0, []];
    ["FOB won: it disbands once the host is away, not before", _fob isNotEqualTo [] && { "Disband" in (_fob select 2) } && { ([_pos] call OTQA_fob_built) >= 13 }, str _fob] call OTQA_fnc_check;

    // The host goes over 1 km away
    private _away = [getPos player, 1500, 2200, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
    player setPosATL [_away select 0, _away select 1, 0];
    sleep 2;
    call OT_fnc_NATOFOBtimers;
    sleep 1;

    ["FOB won: it's off the FOB list", ((server getVariable ["NATOfobs", []]) findIf { (_x select 0) isEqualTo _pos }) isEqualTo -1, format ["host %1 m away", round (player distance2D _pos)]] call OTQA_fnc_check;
    private _left = [_pos] call OTQA_fob_built;
    ["FOB won: its construction is cleared", _left isEqualTo 0, format ["%1 objects left", _left]] call OTQA_fnc_check;
    private _alive = ([_pos, true] call OTQA_fob_units) select { isNull objectParent _x };
    ["FOB won: its soldiers on foot are gone", _alive isEqualTo [], format ["%1 left", count _alive]] call OTQA_fnc_check;
    ["FOB won: the body stays", !isNull _victim && { !alive _victim }, ""] call OTQA_fnc_check;
    ["FOB won: the vehicle stays", alive _veh, ""] call OTQA_fnc_check;

    deleteVehicle _victim;
    player setPosATL _home;
}, 150];

_tests;
