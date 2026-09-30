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
    }]
]
