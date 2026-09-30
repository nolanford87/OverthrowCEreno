/*
    Description:
    Resistance intelligence on occupier deliveries (OT_fnc_NATOdeliveryIntel): the intercept task,
    destroyed / stolen / delivered outcomes and the reward. Part of the current QA tests.

    Returns: ARRAY - [[name, code], ...]
*/

"Intelligence: a reported convoy / fly-in shows where the delivery comes from and goes to; a reported airdrop shows an area it may land in. The task doesn't follow the vehicle" call OTQA_fnc_manual;

// A stand-in delivery vehicle 300 m from the player, reported (chance forced)
OTQA_intel_start = {
    params ["_reward", ["_kind", "route"]];
    private _cls = selectRandom OT_NATO_Vehicles_GroundSupport;
    private _pos = (player getPos [300, random 360]) findEmptyPosition [0, 100, _cls];
    if (_pos isEqualTo []) then { _pos = player getPos [300, random 360] };
    private _veh = createVehicle [_cls, _pos, [], 0, "NONE"];
    OT_deliveryIntelChance = 100;
    [_veh, getPos player, "OTQA test base", _reward, [_kind, getPos _veh]] spawn OT_fnc_NATOdeliveryIntel;
    private _timeout = time + 5;
    waitUntil { sleep 0.2; ((_veh getVariable ["OT_interceptTask", ""]) isNotEqualTo "") || { time > _timeout } };
    OT_deliveryIntelChance = nil;
    _veh;
};
// A real reported airdrop of a tank for the nearest occupier base: the player is put next to where it
// lands, it drives 400-500 m towards the base, then "_finish" is "destroy" (blow it up) or "steal"
// (kill the crew, the host takes it). Checks the task succeeds, cleans up, puts the player back.
OTQA_intel_airdrop = {
    params ["_finish"];
    if (OT_NATO_Vehicles_TankSupport isEqualTo []) exitWith { "Airdrop intercept test skipped: the occupier has no tanks" call OTQA_fnc_manual };
    private _base = ([OT_objectiveData + OT_airportData, [], { (_x select 0) distance2D player }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    _base params ["_basePos"];
    private _home = getPosATL player;
    private _wasCaptive = captive player;
    private _money = player getVariable ["money", 0];
    private _influence = player getVariable ["influence", 0];

    OT_deliveryIntelChance = 100;
    private _delivery = [selectRandom OT_NATO_Vehicles_TankSupport, "OTQA_TEST", _basePos, "airdrop"] spawn OT_fnc_NATOdeliverHeavy;
    private _tank = objNull;
    private _timeout = time + 10;
    waitUntil { sleep 0.5; _tank = vehicles select { (_x getVariable ["vehgarrison", ""]) isEqualTo "OTQA_TEST" } param [0, objNull]; !isNull _tank || { time > _timeout } };
    OT_deliveryIntelChance = nil;
    if (isNull _tank) exitWith { [format ["Airdrop intercept (%1): tank dropped", _finish], false, "no tank appeared"] call OTQA_fnc_check };
    private _taskId = "";
    _timeout = time + 5;
    waitUntil { sleep 0.2; _taskId = _tank getVariable ["OT_interceptTask", ""]; _taskId isNotEqualTo "" || { time > _timeout } };

    // Landed and crewed
    _timeout = time + 90;
    waitUntil { sleep 1; !alive _tank || { ((getPosATL _tank) select 2) < 3 && { alive driver _tank } } || { time > _timeout } };
    private _landing = getPosATL _tank;
    [format ["Airdrop intercept (%1): tank lands and is crewed", _finish], alive _tank && { alive driver _tank }, format ["%1 at %2", typeOf _tank, _landing]] call OTQA_fnc_check;

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
    [format ["Airdrop intercept (%1): tank drives towards the base", _finish], alive _tank && { _driven >= 400 } && { _driven <= 600 } && { ((_tank distance2D _basePos) < (_landing distance2D _basePos)) },
        format ["%1 m from the landing", _driven]] call OTQA_fnc_check;

    if (_finish isEqualTo "destroy") then {
        _tank setDamage 1;
    } else {
        { _x setDamage 1 } forEach (crew _tank);
        sleep 1;
        [_tank, getPlayerUID player] call OT_fnc_setOwner; // The host takes it, as getting in does
    };
    private _state = [_tank, _taskId] call OTQA_intel_state;
    [format ["Airdrop intercept (%1): the task succeeds", _finish], _state isEqualTo "SUCCEEDED", _state] call OTQA_fnc_check;
    if (_finish isEqualTo "steal") then {
        sleep 1; // Payment goes through the player's machine
        private _paid = (player getVariable ["money", 0]) - _money;
        private _gained = (player getVariable ["influence", 0]) - _influence;
        ["Airdrop intercept (steal): the host owns it and gets $3500 and +20 influence", !isNull _tank && { (_tank getVariable ["owner", ""]) isEqualTo getPlayerUID player } && { _paid isEqualTo 3500 } && { _gained isEqualTo 20 },
            format ["money +%1, influence +%2", _paid, _gained]] call OTQA_fnc_check;
    };

    // Clean up, the player goes back
    terminate _delivery;
    private _group = group _tank;
    { deleteVehicle _x } forEach (crew _tank);
    deleteVehicle _tank;
    if (!isNull _group) then { deleteGroup _group };
    player setPosATL _home;
    player setCaptive _wasCaptive;
};

OTQA_intel_state = {
    params ["_veh", "_taskId"];
    private _timeout = time + 8;
    waitUntil { sleep 0.5; !((_taskId call BIS_fnc_taskState) in ["CREATED", "ASSIGNED", ""]) || { time > _timeout } };
    _taskId call BIS_fnc_taskState;
};

[
    ["Delivery intelligence report", {
        // Never reported at 0%
        private _cls = selectRandom OT_NATO_Vehicles_GroundSupport;
        private _quiet = createVehicle [_cls, player getPos [300, 90], [], 0, "NONE"];
        OT_deliveryIntelChance = 0;
        [_quiet, getPos player, "OTQA test base", 500] spawn OT_fnc_NATOdeliveryIntel;
        sleep 1;
        OT_deliveryIntelChance = nil;
        ["No report when the chance fails", (_quiet getVariable ["OT_interceptTask", ""]) isEqualTo "", ""] call OTQA_fnc_check;
        deleteVehicle _quiet;

        // Reported (a route): a task at where it comes from, markers from / to, not following it
        private _veh = [500] call OTQA_intel_start;
        private _taskId = _veh getVariable ["OT_interceptTask", ""];
        ["Reported delivery gets an intercept task", _taskId isNotEqualTo "" && { (_taskId call BIS_fnc_taskState) in ["CREATED", "ASSIGNED"] }, _taskId] call OTQA_fnc_check;
        private _dest = _taskId call BIS_fnc_taskDestination;
        ["Route: markers where it comes from and goes to, the task points at the start (not the vehicle)",
            (markerType (_taskId + "_from")) isEqualTo "mil_start" && { (markerType (_taskId + "_to")) isEqualTo "mil_end" } && { _dest isEqualType [] } && { (_dest distance2D _veh) < 5 },
            format ["destination %1", _dest]] call OTQA_fnc_check;

        // Destroyed: task succeeds
        _veh setDamage 1;
        private _state = [_veh, _taskId] call OTQA_intel_state;
        ["Destroying it completes the task", _state isEqualTo "SUCCEEDED", _state] call OTQA_fnc_check;
        ["The markers go when the task ends", (markerType (_taskId + "_from")) isEqualTo "", ""] call OTQA_fnc_check;
        deleteVehicle _veh;

        // Reported airdrop: an area it may land in, containing the drop point
        private _drop = [500, "drop"] call OTQA_intel_start;
        private _dropTask = _drop getVariable ["OT_interceptTask", ""];
        private _area = _dropTask + "_area";
        private _inside = (getMarkerPos _area) distance2D _drop <= ((getMarkerSize _area) select 0);
        ["Airdrop: a possible drop zone that contains the drop point", (markerShape _area) isEqualTo "ELLIPSE" && { _inside },
            format ["zone %1 m across, drop %2 m from its centre", round (((getMarkerSize _area) select 0) * 2), round ((getMarkerPos _area) distance2D _drop)]] call OTQA_fnc_check;
        _drop setVariable ["OT_delivered", true];
        [_drop, _dropTask] call OTQA_intel_state;
        deleteVehicle _drop;
    }],

    ["Stolen delivery pays the thief", {
        private _veh = [3500] call OTQA_intel_start; // A tank's reward
        private _taskId = _veh getVariable ["OT_interceptTask", ""];
        private _money = player getVariable ["money", 0];
        private _influence = player getVariable ["influence", 0];
        [_veh, getPlayerUID player] call OT_fnc_setOwner; // As getting in does
        private _state = [_veh, _taskId] call OTQA_intel_state;
        sleep 1; // Payment goes through the player's machine
        ["Stealing it completes the task", _state isEqualTo "SUCCEEDED", _state] call OTQA_fnc_check;
        ["The thief gets $3500 and +20 influence", (player getVariable ["money", 0]) isEqualTo (_money + 3500) && { (player getVariable ["influence", 0]) isEqualTo (_influence + 20) },
            format ["money +%1, influence +%2", (player getVariable ["money", 0]) - _money, (player getVariable ["influence", 0]) - _influence]] call OTQA_fnc_check;
        { deleteVehicle _x } forEach (crew _veh);
        deleteVehicle _veh;
    }],

    ["Delivered delivery fails the task", {
        private _veh = [250] call OTQA_intel_start;
        private _taskId = _veh getVariable ["OT_interceptTask", ""];
        _veh setVariable ["OT_delivered", true]; // As the delivery does on arrival
        private _state = [_veh, _taskId] call OTQA_intel_state;
        ["A delivered vehicle fails the task", _state isEqualTo "FAILED", _state] call OTQA_fnc_check;
        deleteVehicle _veh;
    }],

    ["Airdrop intercept: destroy", {
        ["destroy"] call OTQA_intel_airdrop;
    }, 300],

    ["Airdrop intercept: steal", {
        ["steal"] call OTQA_intel_airdrop;
    }, 300]
]
