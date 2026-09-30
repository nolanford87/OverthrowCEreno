/*
    Description:
    Resistance intelligence on occupier deliveries (OT_fnc_NATOdeliveryIntel), with real deliveries:
    the occupier base nearest the host that it still holds is sent a tank (put on its vehicle list
    first, like a trade does), with the intelligence report forced. Part of the current QA tests.
    1. Report: a convoy shows where it comes from and goes to (airdrop: a drop zone), no report at 0%
    Airdrops are flown in by an armed Blackfish (OT_fnc_NATOairdropVehicle).
    2. Destroy: the player at the airdrop's landing, it drives 400-500 m, it's destroyed, task succeeds
    3. Steal: the same, the crew is killed and the host gets in (Overthrow's real stolen vehicle
       handling), task succeeds and pays the host
    4. Delivered: it's moved next to the base, the delivery arrives and the task fails
    5. Shot down: the Blackfish is destroyed before the drop, task succeeds, off the base's list
    6. Convoy completes: a base a convoy reaches, it drives 200-300 m, is moved 200-300 m from the base
       and completes the delivery (task fails, stays on the list, escorts head back)
    7. The wait: a delivery is reported as soon as it's ordered and only sets off after the wait (8 real
       minutes in play, 60 seconds here); meanwhile the base doesn't spawn it itself
    The QA runner makes deliveries set off at once (OT_deliveryDelay 0) except in test 7.

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

// A real tank delivery to that base: [tank (a convoy) or Blackfish (an airdrop), task id, base position,
// base name, delivery script, tank class], [] if none
OTQA_intel_deliver = {
    params ["_method", ["_chance", 100], ["_base", []]];
    if (_base isEqualTo []) then { _base = call OTQA_intel_base };
    if (_base isEqualTo [] || { OT_NATO_Vehicles_TankSupport isEqualTo [] }) exitWith { [] };
    _base params ["_basePos", "_baseName"];
    private _type = selectRandom OT_NATO_Vehicles_TankSupport;

    // On the base's list first, like a trade (OT_fnc_NATOupgradeHeavyGarrisons)
    private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
    _list pushBack _type;
    server setVariable [format ["vehgarrison%1", _baseName], _list, true];

    private _isFor = { (_x getVariable ["vehgarrison", ""]) isEqualTo _baseName || { (_x getVariable ["OT_airdropFor", ""]) isEqualTo _baseName } };
    private _before = vehicles select _isFor;
    OT_deliveryIntelChance = _chance;
    private _script = [_type, _baseName, _basePos, _method] spawn OT_fnc_NATOdeliverHeavy;
    private _tank = objNull;
    private _timeout = time + 15;
    waitUntil {
        sleep 0.5;
        _tank = (vehicles select { alive _x && _isFor }) - _before param [0, objNull];
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
    [_tank, _taskId, _basePos, _baseName, _script, _type];
};

// Removes a test delivery (tank / Blackfish, crew, escorts) and, when _onList, its entry on the base's
// list (a delivery destroyed or stolen already came off it)
OTQA_intel_cleanup = {
    params ["_tank", "_baseName", "_script", "_type", "_onList"];
    terminate _script;
    {
        private _v = _x;
        private _g = group driver _v;
        { deleteVehicle _x } forEach (crew _v);
        { detach _x; deleteVehicle _x } forEach (attachedObjects _v);
        if (!isNull attachedTo _v) then { deleteVehicle (attachedTo _v) };
        deleteVehicle _v;
        if (!isNull _g) then { deleteGroup _g };
    } forEach ((vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo _baseName }) + ([_tank] select { !isNull _x && { alive _x } }));
    if (_onList) then {
        private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
        private _index = _list find _type;
        if (_index > -1) then { _list deleteAt _index };
        server setVariable [format ["vehgarrison%1", _baseName], _list, true];
    };
};

// The occupier base nearest the host that a convoy can reach, by the rules of OT_fnc_NATOdeliverHeavy
// (from a place it holds at least 4 km away, same land, a road within 50 m): [position, name], [] if none
OTQA_intel_convoyBase = {
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _sources = [];
    if !(OT_NATO_HQ in _abandoned) then { _sources pushBack [OT_NATO_HQPos, OT_NATO_HQ] };
    if !("Factory" in (server getVariable ["GEURowned", []])) then { _sources pushBack [OT_factoryPos, "Factory"] };
    { if !((_x select 1) in _abandoned) then { _sources pushBack [_x select 0, _x select 1] } } forEach (OT_objectiveData + OT_airportData + OT_commsData);
    private _bases = (OT_objectiveData + OT_airportData) select {
        private _basePos = _x select 0;
        private _baseName = _x select 1;
        !(_baseName in _abandoned) && {
            _sources findIf {
                (_x select 1) isNotEqualTo _baseName && { ((_x select 0) distance2D _basePos) >= 4000 } && { [_x select 0, _basePos] call OT_fnc_regionIsConnected } && { ((_x select 0) nearRoads 50) isNotEqualTo [] }
            } > -1
        }
    };
    if (_bases isEqualTo []) exitWith { [] };
    private _base = ([_bases, [], { (_x select 0) distance2D player }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    [_base select 0, _base select 1];
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
    _delivery params ["_plane", "_taskId", "_basePos", "_baseName", "_script", "_type"];
    private _label = format ["%1, %2", _finish, _baseName];
    private _home = getPosATL player;
    private _wasCaptive = captive player;
    private _money = player getVariable ["money", 0];
    private _influence = player getVariable ["influence", 0];
    [format ["Airdrop (%1): reported, intercept task", _label], !isNull _plane && { _taskId isNotEqualTo "" }, format ["%1, %2", _type, _taskId]] call OTQA_fnc_check;
    if (isNull _plane) exitWith {};

    // The armed Blackfish flies it in at 300-400 m
    sleep 3;
    private _planeAlt = round ((getPosATL _plane) select 2);
    [format ["Airdrop (%1): an armed Blackfish flies it in at 300-400 m", _label], (typeOf _plane) isEqualTo "B_T_VTOL_01_armed_F" && { _planeAlt > 250 } && { _planeAlt < 450 } && { side group driver _plane isEqualTo blufor },
        format ["%1 at %2 m, %3 m from the base", typeOf _plane, _planeAlt, round (_plane distance2D _basePos)]] call OTQA_fnc_check;

    if (_finish isEqualTo "shootdown") exitWith {
        // Shot down before the drop: the delivery is lost
        private _listBefore = [_baseName, _type] call OTQA_intel_listCount;
        _plane setDamage 1;
        private _state = [_taskId] call OTQA_intel_state;
        [format ["Airdrop (%1): shooting the Blackfish down completes the task", _label], _state isEqualTo "SUCCEEDED", _state] call OTQA_fnc_check;
        sleep 3;
        private _listAfter = [_baseName, _type] call OTQA_intel_listCount;
        [format ["Airdrop (%1): the tank comes off the base's list", _label], _listAfter isEqualTo (_listBefore - 1), format ["%1 on the list: %2 -> %3", _type, _listBefore, _listAfter]] call OTQA_fnc_check;
        [format ["Airdrop (%1): nothing is dropped", _label], (vehicles select { (_x getVariable ["vehgarrison", ""]) isEqualTo _baseName && { typeOf _x isEqualTo _type } && { alive _x } && { (_x distance2D _basePos) > 400 } }) isEqualTo [], ""] call OTQA_fnc_check;
        [objNull, _baseName, _script, _type, false] call OTQA_intel_cleanup; // It came off the list when shot down
        { deleteVehicle _x } forEach (crew _plane);
        deleteVehicle _plane;
    };

    // Dropped: from now on it's about the tank
    private _flight = time + 480;
    waitUntil { sleep 2; !alive _plane || { !isNull (_plane getVariable ["OT_deliveryCargo", objNull]) } || { time > _flight } };
    private _tank = _plane getVariable ["OT_deliveryCargo", objNull];
    [format ["Airdrop (%1): the Blackfish drops it", _label], !isNull _tank, format ["%1 m from the base", round (_plane distance2D _basePos)]] call OTQA_fnc_check;
    if (isNull _tank) exitWith { [_plane, _baseName, _script, _type, alive _plane] call OTQA_intel_cleanup };

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
            // At least: the regular income can land during the test (+$50 at 24x time)
            [format ["Airdrop (%1): the host owns it and gets $3500 and +20 influence", _label], !isNull _tank && { (_tank getVariable ["owner", ""]) isEqualTo getPlayerUID player } && { _paid >= 3500 } && { _gained >= 20 },
                format ["money +%1, influence +%2", _paid, _gained]] call OTQA_fnc_check;
        };
    };

    // Destroyed / stolen: already off the list; delivered: still on it
    [_tank, _baseName, _script, _type, _finish isEqualTo "deliver"] call OTQA_intel_cleanup;
    player setPosATL _home;
    player setCaptive _wasCaptive;
};

[
    ["Intel 1: report shows the route", {
        // No report at 0%
        private _quiet = ["convoy", 0] call OTQA_intel_deliver;
        if (_quiet isEqualTo []) exitWith { "Intel report test skipped: no occupier base or no tanks" call OTQA_fnc_manual };
        _quiet params ["_quietTank", "_quietTask", "", "_quietBase", "_quietScript", "_quietType"];
        ["No report when the chance fails", !isNull _quietTank && { _quietTask isEqualTo "" }, _quietBase] call OTQA_fnc_check;
        [_quietTank, _quietBase, _quietScript, _quietType, true] call OTQA_intel_cleanup;

        // Reported convoy (an airdrop if no convoy can reach the base)
        (["convoy"] call OTQA_intel_deliver) params ["_tank", "_taskId", "_basePos", "_baseName", "_script", "_type"]; // A Blackfish if it's an airdrop
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
        [_tank, _baseName, _script, _type, true] call OTQA_intel_cleanup;
        private _state = [_taskId] call OTQA_intel_state;
        ["The markers go when the task ends", (markerType (_taskId + "_from")) isEqualTo "" && { (markerShape (_taskId + "_area")) isEqualTo "" }, _state] call OTQA_fnc_check;
    }, 120],

    ["Intel 2: airdrop destroyed", { ["destroy"] call OTQA_intel_airdrop }, 720],
    ["Intel 3: airdrop stolen", { ["steal"] call OTQA_intel_airdrop }, 720],
    ["Intel 4: airdrop delivered", { ["deliver"] call OTQA_intel_airdrop }, 720],
    ["Intel 5: Blackfish shot down", { ["shootdown"] call OTQA_intel_airdrop }, 120],
    ["Intel 6: ground convoy completes", {
        private _base = call OTQA_intel_convoyBase;
        if (_base isEqualTo []) exitWith { "Convoy test skipped: no occupier base a convoy can reach" call OTQA_fnc_manual };
        (["convoy", 100, _base] call OTQA_intel_deliver) params ["_tank", "_taskId", "_basePos", "_baseName", "_script", "_type"];
        private _escorts = vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo _baseName };
        ["Convoy: a tank with 2 escorts, reported", !isNull _tank && { (count _escorts) isEqualTo 2 } && { (markerType (_taskId + "_from")) isEqualTo "mil_start" },
            format ["%1 to %2, %3 escorts, %4 m to go", _type, _baseName, count _escorts, round (_tank distance2D _basePos)]] call OTQA_fnc_check;
        private _startPos = getMarkerPos (_taskId + "_from");
        ["Convoy: it starts on a road, at least 4 km from the base", ((_startPos nearRoads 15) isNotEqualTo []) && { (_startPos distance2D _basePos) >= 3900 },
            format ["start %1 m from the base", round (_startPos distance2D _basePos)]] call OTQA_fnc_check;
        if (isNull _tank) exitWith {};

        // It drives 200-300 m
        private _start = getPosATL _tank;
        private _timeout = time + 180;
        waitUntil { sleep 1; !alive _tank || { (_tank distance2D _start) >= 200 } || { time > _timeout } };
        private _driven = round (_tank distance2D _start);
        ["Convoy: it drives off", alive _tank && { _driven >= 200 } && { _driven <= 350 }, format ["%1 m", _driven]] call OTQA_fnc_check;

        // The convoy onto a road 200-300 m from the base, tank in front, keeping their orders
        private _dir = _basePos getDir _tank;
        private _spot = _basePos getPos [250, _dir];
        private _road = [_spot, 150] call BIS_fnc_nearestRoad;
        if (!isNull _road && { ((getPosATL _road) distance2D _basePos) > 180 } && { ((getPosATL _road) distance2D _basePos) < 330 }) then { _spot = getPosATL _road };
        private _heading = _spot getDir _basePos;
        {
            private _p = (_spot getPos [_forEachIndex * 30, _heading + 180]) findEmptyPosition [0, 40, typeOf _x];
            if (_p isEqualTo []) then { _p = _spot getPos [_forEachIndex * 30, _heading + 180] };
            _x setPosATL _p;
            _x setDir _heading;
        } forEach ([_tank] + (_escorts select { alive _x }));
        ["Convoy: moved 200-300 m from the base", round (_tank distance2D _basePos) >= 180 && { (_tank distance2D _basePos) <= 330 }, format ["%1 m from %2", round (_tank distance2D _basePos), _baseName]] call OTQA_fnc_check;
        private _listBefore = [_baseName, _type] call OTQA_intel_listCount;

        // It completes the delivery
        _timeout = time + 240;
        waitUntil { sleep 2; !alive _tank || { _tank getVariable ["OT_delivered", false] } || { isNull _tank } || { time > _timeout } };
        private _arrived = isNull _tank || { _tank getVariable ["OT_delivered", false] };
        ["Convoy: the tank reaches the base", _arrived, format ["%1 m from the base", [round (_tank distance2D _basePos), 0] select (isNull _tank)]] call OTQA_fnc_check;
        private _state = [_taskId] call OTQA_intel_state;
        ["Convoy: delivered, the intercept task fails", _state isEqualTo "FAILED", _state] call OTQA_fnc_check;
        ["Convoy: the tank stays on the base's list", ([_baseName, _type] call OTQA_intel_listCount) isEqualTo _listBefore, format ["%1 on the list: %2", _type, [_baseName, _type] call OTQA_intel_listCount]] call OTQA_fnc_check;
        // The escorts are sent back after the delivery: further from the base 20 seconds later
        private _distances = _escorts apply { [_x distance2D _basePos, 0] select (isNull _x) };
        sleep 20;
        private _returning = [];
        {
            if (isNull _x || { !alive _x } || { (_x distance2D _basePos) > ((_distances select _forEachIndex) + 20) }) then { _returning pushBack _x };
        } forEach _escorts;
        ["Convoy: the escorts head back (or are gone)", (count _returning) isEqualTo (count _escorts), format ["%1 of %2", count _returning, count _escorts]] call OTQA_fnc_check;

        [_tank, _baseName, _script, _type, true] call OTQA_intel_cleanup;
    }, 600],

    ["Intel 7: announced, then sets off after the wait", {
        private _base = call OTQA_intel_base;
        if (_base isEqualTo [] || { OT_NATO_Vehicles_TankSupport isEqualTo [] }) exitWith { "Wait test skipped: no occupier base or no tanks" call OTQA_fnc_manual };
        _base params ["_basePos", "_baseName"];
        private _type = selectRandom OT_NATO_Vehicles_TankSupport;
        private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
        _list pushBack _type;
        server setVariable [format ["vehgarrison%1", _baseName], _list, true];
        private _isFor = { (_x getVariable ["vehgarrison", ""]) isEqualTo _baseName || { (_x getVariable ["OT_airdropFor", ""]) isEqualTo _baseName } };
        private _before = vehicles select _isFor;

        private _oldTasks = (player call BIS_fnc_tasksUnit) select { (_x find "intercept") isEqualTo 0 };
        OT_deliveryDelay = 60;
        OT_deliveryIntelChance = 100;
        private _ordered = time;
        private _script = [_type, _baseName, _basePos] spawn OT_fnc_NATOdeliverHeavy;
        sleep 5;
        OT_deliveryIntelChance = nil;
        OT_deliveryDelay = 0;

        // Announced at once, nothing on its way yet
        private _taskId = ((player call BIS_fnc_tasksUnit) select { (_x find "intercept") isEqualTo 0 && { !(_x in _oldTasks) } }) param [0, ""];
        ["Wait: reported as soon as it's ordered", _taskId isNotEqualTo "", format ["%1 for %2", _taskId, _baseName]] call OTQA_fnc_check;
        private _early = (vehicles select _isFor) - _before;
        ["Wait: nothing sets off before the wait", _early isEqualTo [], format ["%1 on its way after %2 s", _early apply { typeOf _x }, round (time - _ordered)]] call OTQA_fnc_check;
        private _pending = (missionNamespace getVariable ["OT_pendingDeliveries", []]) select { (_x select 0) isEqualTo _baseName };
        ["Wait: the base knows it's still to come (won't spawn it itself)", (_pending findIf { (_x select 1) isEqualTo _type }) > -1, str _pending] call OTQA_fnc_check;

        // Sets off after the wait
        private _veh = objNull;
        private _timeout = _ordered + 90;
        waitUntil { sleep 1; _veh = (vehicles select { alive _x && _isFor }) - _before param [0, objNull]; !isNull _veh || { time > _timeout } };
        ["Wait: it sets off after the wait, the report follows it", !isNull _veh && { (time - _ordered) >= 58 } && { sleep 3; (_veh getVariable ["OT_interceptTask", ""]) isEqualTo _taskId },
            format ["%1 after %2 s", typeOf _veh, round (time - _ordered)]] call OTQA_fnc_check;

        [_veh, _baseName, _script, _type, true] call OTQA_intel_cleanup;
    }, 180]
]
