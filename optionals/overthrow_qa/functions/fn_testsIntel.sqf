/*
    Description:
    Resistance intelligence on occupier deliveries (OT_fnc_NATOdeliveryIntel), with real deliveries:
    the occupier base nearest the host that it still holds is sent a tank (put on its vehicle list
    first, like a trade does), with the intelligence report forced. Part of the current QA tests.
    1. Report: a convoy shows where it comes from and goes to (airdrop: a drop zone), no report at 0%
    2. Destroy: the player at the airdrop's landing, it drives 400-500 m, it's destroyed, task succeeds
    3. Steal: the same, the crew is killed and the host gets in (Overthrow's real stolen vehicle
       handling), task succeeds and pays the host
    4. Delivered: it's moved next to the base, the delivery arrives and the task fails

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Intelligence: in play, a reported convoy / fly-in shows where the delivery comes from and goes to, a reported airdrop an area it may land in; the task doesn't follow the vehicle" call OTQA_fnc_manual;

// The occupier base nearest the host that it still holds: [position, name]
OTQA_intel_base = {
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _bases = (OT_objectiveData + OT_airportData) select { !((_x select 1) in _abandoned) };
    if (_bases isEqualTo []) exitWith { [] };
    private _base = ([_bases, [], { (_x select 0) distance2D player }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    [_base select 0, _base select 1];
};

// Counts a class on a base's vehicle list
OTQA_intel_listCount = {
    params ["_baseName", "_type"];
    { _x isEqualTo _type } count (server getVariable [format ["vehgarrison%1", _baseName], []]);
};

// A real tank delivery to that base: [tank, task id, base position, base name, delivery script], [] if none
OTQA_intel_deliver = {
    params ["_method", ["_chance", 100]];
    private _base = call OTQA_intel_base;
    if (_base isEqualTo [] || { OT_NATO_Vehicles_TankSupport isEqualTo [] }) exitWith { [] };
    _base params ["_basePos", "_baseName"];
    private _type = selectRandom OT_NATO_Vehicles_TankSupport;

    // On the base's list first, like a trade (OT_fnc_NATOupgradeHeavyGarrisons)
    private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
    _list pushBack _type;
    server setVariable [format ["vehgarrison%1", _baseName], _list, true];

    private _before = vehicles select { (_x getVariable ["vehgarrison", ""]) isEqualTo _baseName };
    OT_deliveryIntelChance = _chance;
    private _script = [_type, _baseName, _basePos, _method] spawn OT_fnc_NATOdeliverHeavy;
    private _tank = objNull;
    private _timeout = time + 15;
    waitUntil {
        sleep 0.5;
        _tank = (vehicles select { alive _x && { (_x getVariable ["vehgarrison", ""]) isEqualTo _baseName } }) - _before param [0, objNull];
        !isNull _tank || { time > _timeout }
    };
    private _taskId = "";
    if (_chance > 0) then {
        _timeout = time + 5;
        waitUntil { sleep 0.2; _taskId = _tank getVariable ["OT_interceptTask", ""]; _taskId isNotEqualTo "" || { time > _timeout } };
    } else {
        sleep 2;
        _taskId = _tank getVariable ["OT_interceptTask", ""];
    };
    OT_deliveryIntelChance = nil;
    [_tank, _taskId, _basePos, _baseName, _script];
};

// Removes a test delivery (tank, crew, escorts, its entry on the base's list if still there)
OTQA_intel_cleanup = {
    params ["_tank", "_baseName", "_script", ["_type", ""]];
    terminate _script;
    if (_type isEqualTo "" && { !isNull _tank }) then { _type = typeOf _tank };
    {
        private _v = _x;
        private _g = group driver _v;
        { deleteVehicle _x } forEach (crew _v);
        { detach _x; deleteVehicle _x } forEach (attachedObjects _v);
        if (!isNull attachedTo _v) then { deleteVehicle (attachedTo _v) };
        deleteVehicle _v;
        if (!isNull _g) then { deleteGroup _g };
    } forEach ((vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo _baseName }) + ([_tank] select { !isNull _x && { alive _x } }));
    private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
    private _index = _list find _type;
    if (_index > -1 && { _type isNotEqualTo "" } && { !isNull _tank } && { alive _tank }) then { _list deleteAt _index };
    server setVariable [format ["vehgarrison%1", _baseName], _list, true];
};

OTQA_intel_state = {
    params ["_taskId"];
    private _timeout = time + 10;
    waitUntil { sleep 0.5; !((_taskId call BIS_fnc_taskState) in ["CREATED", "ASSIGNED", ""]) || { time > _timeout } };
    _taskId call BIS_fnc_taskState;
};

// An airdrop to the base, then _finish: "destroy" / "steal" (the player next to the landing, it drives
// 400-500 m first) or "deliver" (moved next to the base)
OTQA_intel_airdrop = {
    params ["_finish"];
    private _delivery = ["airdrop"] call OTQA_intel_deliver;
    if (_delivery isEqualTo []) exitWith { format ["Airdrop test (%1) skipped: no occupier base or no tanks", _finish] call OTQA_fnc_manual };
    _delivery params ["_tank", "_taskId", "_basePos", "_baseName", "_script"];
    private _type = typeOf _tank;
    private _label = format ["%1, %2", _finish, _baseName];
    private _home = getPosATL player;
    private _wasCaptive = captive player;
    private _money = player getVariable ["money", 0];
    private _influence = player getVariable ["influence", 0];
    [format ["Airdrop (%1): reported, intercept task", _label], !isNull _tank && { _taskId isNotEqualTo "" }, format ["%1, %2", _type, _taskId]] call OTQA_fnc_check;
    if (isNull _tank) exitWith {};

    // Landed and crewed
    private _timeout = time + 90;
    waitUntil { sleep 1; !alive _tank || { ((getPosATL _tank) select 2) < 3 && { alive driver _tank } } || { time > _timeout } };
    private _landing = getPosATL _tank;
    [format ["Airdrop (%1): lands on land, on the base's island, and is crewed", _label], alive _tank && { alive driver _tank } && { !surfaceIsWater _landing } && { [_landing, _basePos] call OT_fnc_regionIsConnected },
        format ["at %1, %2 m from the base", _landing, round (_landing distance2D _basePos)]] call OTQA_fnc_check;

    if (_finish isEqualTo "deliver") then {
        // Next to the base: the delivery arrives
        private _near = _basePos findEmptyPosition [20, 150, _type];
        if (_near isEqualTo []) then { _near = _basePos };
        _tank setPosATL _near;
        private _state = [_taskId] call OTQA_intel_state;
        [format ["Airdrop (%1): delivered, the task fails", _label], _state isEqualTo "FAILED", _state] call OTQA_fnc_check;
    } else {
        // The player next to the landing (undercover, the crew won't target them)
        moveOut player;
        player setCaptive true;
        { _x disableAI "TARGET"; _x disableAI "AUTOTARGET" } forEach (crew _tank);
        private _near = (_landing getPos [40, random 360]) findEmptyPosition [0, 30, "CAManBase"];
        if (_near isEqualTo []) then { _near = _landing getPos [40, random 360] };
        player setPosATL _near;

        // It drives 400-500 m towards the base
        _timeout = time + 150;
        waitUntil { sleep 1; !alive _tank || { (_tank distance2D _landing) >= 400 } || { time > _timeout } };
        private _driven = round (_tank distance2D _landing);
        [format ["Airdrop (%1): drives towards the base", _label], alive _tank && { _driven >= 400 } && { _driven <= 600 } && { (_tank distance2D _basePos) < (_landing distance2D _basePos) },
            format ["%1 m from the landing", _driven]] call OTQA_fnc_check;

        private _listBefore = [_baseName, _type] call OTQA_intel_listCount;
        if (_finish isEqualTo "destroy") then {
            _tank setDamage 1;
        } else {
            // Crew killed, the host gets in: Overthrow's own stolen vehicle handling makes it theirs
            { _x setDamage 1 } forEach (crew _tank);
            sleep 1;
            { deleteVehicle _x } forEach (crew _tank); // Bodies out of the seats
            sleep 0.5;
            player moveInDriver _tank;
            sleep 2;
            moveOut player;
        };
        private _state = [_taskId] call OTQA_intel_state;
        [format ["Airdrop (%1): the task succeeds", _label], _state isEqualTo "SUCCEEDED", _state] call OTQA_fnc_check;
        private _listAfter = [_baseName, _type] call OTQA_intel_listCount;
        [format ["Airdrop (%1): it comes off the base's list", _label], _listAfter isEqualTo (_listBefore - 1), format ["%1 on the list: %2 -> %3", _type, _listBefore, _listAfter]] call OTQA_fnc_check;
        if (_finish isEqualTo "steal") then {
            sleep 1; // Payment goes through the player's machine
            private _paid = (player getVariable ["money", 0]) - _money;
            private _gained = (player getVariable ["influence", 0]) - _influence;
            [format ["Airdrop (%1): the host owns it and gets $3500 and +20 influence", _label], !isNull _tank && { (_tank getVariable ["owner", ""]) isEqualTo getPlayerUID player } && { _paid isEqualTo 3500 } && { _gained isEqualTo 20 },
                format ["money +%1, influence +%2", _paid, _gained]] call OTQA_fnc_check;
        };
    };

    [_tank, _baseName, _script, _type] call OTQA_intel_cleanup;
    player setPosATL _home;
    player setCaptive _wasCaptive;
};

[
    ["Intel 1: report shows the route", {
        // No report at 0%
        private _quiet = ["convoy", 0] call OTQA_intel_deliver;
        if (_quiet isEqualTo []) exitWith { "Intel report test skipped: no occupier base or no tanks" call OTQA_fnc_manual };
        _quiet params ["_quietTank", "_quietTask", "", "_quietBase", "_quietScript"];
        ["No report when the chance fails", !isNull _quietTank && { _quietTask isEqualTo "" }, _quietBase] call OTQA_fnc_check;
        [_quietTank, _quietBase, _quietScript] call OTQA_intel_cleanup;

        // Reported convoy (an airdrop if no convoy can reach the base)
        (["convoy"] call OTQA_intel_deliver) params ["_tank", "_taskId", "_basePos", "_baseName", "_script"];
        ["Reported delivery gets an intercept task", _taskId isNotEqualTo "" && { (_taskId call BIS_fnc_taskState) in ["CREATED", "ASSIGNED"] }, format ["%1 to %2", _taskId, _baseName]] call OTQA_fnc_check;
        private _escorts = vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo _baseName };
        if (_escorts isNotEqualTo []) then {
            private _dest = _taskId call BIS_fnc_taskDestination;
            ["Convoy: markers where it comes from and goes to, the task points at the start (not the tank)",
                (markerType (_taskId + "_from")) isEqualTo "mil_start" && { (markerType (_taskId + "_to")) isEqualTo "mil_end" } && { _dest isEqualType [] } && { ((getMarkerPos (_taskId + "_to")) distance2D _basePos) < 5 },
                format ["%1 escorts, task at %2", count _escorts, _dest]] call OTQA_fnc_check;
        } else {
            private _area = _taskId + "_area";
            ["Airdrop (no convoy reaches this base): a possible drop zone", (markerShape _area) isEqualTo "ELLIPSE",
                format ["zone %1 m across", round (((getMarkerSize _area) select 0) * 2)]] call OTQA_fnc_check;
        };
        [_tank, _baseName, _script] call OTQA_intel_cleanup;
        private _state = [_taskId] call OTQA_intel_state;
        ["The markers go when the task ends", (markerType (_taskId + "_from")) isEqualTo "" && { (markerShape (_taskId + "_area")) isEqualTo "" }, _state] call OTQA_fnc_check;
    }, 120],

    ["Intel 2: airdrop destroyed", { ["destroy"] call OTQA_intel_airdrop }, 300],
    ["Intel 3: airdrop stolen", { ["steal"] call OTQA_intel_airdrop }, 300],
    ["Intel 4: airdrop delivered", { ["deliver"] call OTQA_intel_airdrop }, 300]
]
