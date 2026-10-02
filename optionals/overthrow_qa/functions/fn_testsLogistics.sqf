/*
    Description:
    Logistics, freight hauls (OT_fnc_logisticsStart / OT_fnc_logisticsTrack): crates and rental
    spawned at the loading spot, the job's state and task, delivery (crates unloaded within 30 m of the
    drop-off) paying the player, a job failing at twice its time limit or with every crate lost.
    Part of the current QA tests. Contracts are made by hand (not from a broker). Run it as the host
    (the job runs on the server); the test's crates and vehicles are deleted afterwards.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Logistics: in play, a freight broker's contract spawns crates at its loading spot; ACE 'Load into' a vehicle, drive to the task's destination, unload: paid on delivery" call OTQA_fnc_manual;
"Logistics: through a NATO checkpoint with haul crates loaded: 'Checkpoint: inspecting your freight...', ~10 s, then 'Freight checked, move along', cover kept" call OTQA_fnc_manual;
"Logistics: late delivery pays 10% less per full 5 minutes over the time limit (not tested here, it needs real minutes)" call OTQA_fnc_manual;

// A contract near the host: [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit, danger, brokerId]
OTQA_haul_contract = {
    params ["_id", "_crates", "_pay", "_timeLimit", ["_toName", "QA drop-off"]];
    private _from = ((getPosATL player) getPos [25, getDir player]) findEmptyPosition [0, 60, "C_Truck_02_box_F"];
    if (_from isEqualTo []) then { _from = getPosATL player };
    private _to = ((getPosATL player) getPos [120, (getDir player) + 180]) findEmptyPosition [0, 80, "C_Truck_02_box_F"];
    if (_to isEqualTo []) then { _to = (getPosATL player) getPos [60, (getDir player) + 180] };
    [_id, _from, "QA yard", _to, _toName, _crates, ["van", "truck"] select (_crates > 2), _pay, _timeLimit, 0, "qa"]
};

OTQA_haul_cleanup = {
    params ["_objects"];
    { if (!isNull _x) then { detach _x; deleteVehicle _x } } forEach _objects;
    player setVariable ["OT_logisticsActive", "", true];
};

[
    ["Logistics: start a haul, deliver it, get paid", {
        if (isNil "OT_fnc_logisticsStart") exitWith { ["Logistics: OT_fnc_logisticsStart exists", false, "missing"] call OTQA_fnc_check };
        private _town = (getPosATL player) call OT_fnc_nearestTown;
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 3, 1234, 600, _town] call OTQA_haul_contract;
        private _toPos = _contract select 3;
        private _money = player getVariable ["money", 0];
        private _rep = server getVariable [format ["rep%1", _town], 0];

        ([_contract, player, true] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];

        ["Logistics: 3 crates spawned at the loading spot", (count _crates) isEqualTo 3 && { (_crates findIf { isNull _x || { (_x distance2D (_contract select 1)) > 40 } }) isEqualTo -1 },
            format ["%1 crates, %2", count _crates, _crates apply { round (_x distance2D (_contract select 1)) }]] call OTQA_fnc_check;
        ["Logistics: crates are ACE-loadable (size 1) and tagged with the job", (_crates findIf { (_x getVariable ["ace_cargo_size", -1]) isNotEqualTo 1 || { !(_x getVariable ["ace_cargo_canLoad", false]) } || { (_x getVariable ["OT_haul", ""]) isNotEqualTo _id } }) isEqualTo -1,
            str (_crates apply { [typeOf _x, _x getVariable ["ace_cargo_size", -1], _x getVariable ["ace_cargo_canLoad", false], _x getVariable ["OT_haul", ""]] })] call OTQA_fnc_check;
        ["Logistics: rented box truck spawned, owned by the player, room for the crates", !isNull _veh && { (typeOf _veh) isEqualTo "C_Truck_02_box_F" } && { (_veh call OT_fnc_getOwner) isEqualTo (getPlayerUID player) } && { (_veh getVariable ["ace_cargo_space", 0]) >= 3 } && { (_veh getVariable ["OT_haulRental", ""]) isEqualTo _id },
            format ["%1, owner %2, space %3", typeOf _veh, _veh call OT_fnc_getOwner, _veh getVariable ["ace_cargo_space", 0]]] call OTQA_fnc_check;
        ["Logistics: the player's job is set", (player getVariable ["OT_logisticsActive", ""]) isEqualTo _id, player getVariable ["OT_logisticsActive", ""]] call OTQA_fnc_check;
        ["Logistics: task and pickup marker created", ([_taskId] call BIS_fnc_taskExists) && { (markerShape format ["OT_haulPickup_%1", _id]) isNotEqualTo "" },
            format ["task %1 (%2), marker %3", _taskId, [_taskId] call BIS_fnc_taskState, markerShape format ["OT_haulPickup_%1", _id]]] call OTQA_fnc_check;

        // One crate loaded the ACE way, the truck and the other crates at the drop-off: not delivered yet
        private _crate = _crates select 0;
        private _loaded = [_crate, _veh, true] call ace_cargo_fnc_loadItem;
        sleep 0.5;
        ["Logistics: a crate loads into the rental (ACE)", _loaded && { _crate in (_veh getVariable ["ace_cargo_loaded", []]) }, format ["loaded %1, attached to %2", _loaded, attachedTo _crate]] call OTQA_fnc_check;
        _veh setPosATL _toPos;
        { _x setPosATL (_toPos getPos [6 + _forEachIndex * 2, 90]) } forEach (_crates select [1, 2]);
        sleep 7;
        ["Logistics: not delivered while a crate is still loaded", ([_taskId] call BIS_fnc_taskState) isNotEqualTo "SUCCEEDED" && { (player getVariable ["OT_logisticsActive", ""]) isEqualTo _id },
            [_taskId] call BIS_fnc_taskState] call OTQA_fnc_check;

        // Unloaded at the drop-off: delivered
        if (!isNil "ace_cargo_fnc_unloadItem") then { [_crate, _veh] call ace_cargo_fnc_unloadItem };
        sleep 0.5;
        if (!isNull (attachedTo _crate)) then {
            ["Logistics: ACE unloads the crate", false, "still attached, unloaded by hand"] call OTQA_fnc_check;
            private _list = _veh getVariable ["ace_cargo_loaded", []];
            _list deleteAt (_list find _crate);
            _veh setVariable ["ace_cargo_loaded", _list, true];
            detach _crate;
            [_crate, false] remoteExec ["hideObjectGlobal", 2];
        };
        _crate setPosATL (_toPos getPos [4, 270]);
        private _timeout = time + 15;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "SUCCEEDED" || { time > _timeout } };
        _timeout = time + 5;
        waitUntil { sleep 0.5; (player getVariable ["money", 0]) isNotEqualTo _money || { time > _timeout } };
        ["Logistics: delivered, task succeeded", ([_taskId] call BIS_fnc_taskState) isEqualTo "SUCCEEDED", [_taskId] call BIS_fnc_taskState] call OTQA_fnc_check;
        // At least the pay: a tax income tick can land at the same time
        ["Logistics: paid the contract's pay", ((player getVariable ["money", 0]) - _money) >= 1234 && { ((player getVariable ["money", 0]) - _money) < 1234 + 2000 }, format ["+%1", (player getVariable ["money", 0]) - _money]] call OTQA_fnc_check;
        ["Logistics: the job is cleared, marker gone", (player getVariable ["OT_logisticsActive", ""]) isEqualTo "" && { (markerShape format ["OT_haulPickup_%1", _id]) isEqualTo "" },
            str (player getVariable ["OT_logisticsActive", ""])] call OTQA_fnc_check;
        ["Logistics: +1 support in the town it went to", (server getVariable [format ["rep%1", _town], 0]) isEqualTo (_rep + 1), format ["%1: %2 -> %3", _town, _rep, server getVariable [format ["rep%1", _town], 0]]] call OTQA_fnc_check;

        [_crates + [_veh]] call OTQA_haul_cleanup;
    }, 90],

    ["Logistics: twice the time limit fails the job, no pay", {
        if (isNil "OT_fnc_logisticsStart") exitWith {};
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 1, 500, 2] call OTQA_haul_contract; // 2 s limit: failed after 4 s
        private _money = player getVariable ["money", 0];
        ([_contract, player, false] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
        ["Logistics: no rental when none was paid for", isNull _veh, str _veh] call OTQA_fnc_check;
        private _timeout = time + 15;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" || { time > _timeout } };
        sleep 2;
        ["Logistics: too late, task failed", ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED", [_taskId] call BIS_fnc_taskState] call OTQA_fnc_check;
        ["Logistics: no pay, job cleared", (player getVariable ["money", 0]) isEqualTo _money && { (player getVariable ["OT_logisticsActive", ""]) isEqualTo "" },
            format ["money %1 -> %2, job '%3'", _money, player getVariable ["money", 0], player getVariable ["OT_logisticsActive", ""]]] call OTQA_fnc_check;
        [_crates] call OTQA_haul_cleanup;
    }, 40],

    ["Logistics: every crate lost fails the job", {
        if (isNil "OT_fnc_logisticsStart") exitWith {};
        private _id = format ["qa%1", round (random 100000)];
        private _contract = [_id, 2, 500, 600] call OTQA_haul_contract;
        private _money = player getVariable ["money", 0];
        ([_contract, player, false] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull], ["_taskId", ""]];
        { deleteVehicle _x } forEach _crates;
        private _timeout = time + 15;
        waitUntil { sleep 1; ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" || { time > _timeout } };
        ["Logistics: crates lost, task failed, no pay", ([_taskId] call BIS_fnc_taskState) isEqualTo "FAILED" && { (player getVariable ["money", 0]) isEqualTo _money } && { (player getVariable ["OT_logisticsActive", ""]) isEqualTo "" },
            format ["%1, money %2 -> %3", [_taskId] call BIS_fnc_taskState, _money, player getVariable ["money", 0]]] call OTQA_fnc_check;
    }, 40]
]
