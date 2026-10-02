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

        // The rental comes with the crates loaded; at the drop-off two come out, one stays in: not delivered yet
        ["Logistics: the rental comes with every crate loaded (ACE)", (_crates findIf { !(_x in (_veh getVariable ["ace_cargo_loaded", []])) }) isEqualTo -1,
            format ["loaded %1 of %2", count ((_veh getVariable ["ace_cargo_loaded", []]) select { _x in _crates }), count _crates]] call OTQA_fnc_check;
        private _crate = _crates select 0;
        _veh setPosATL _toPos;
        {
            private _list = _veh getVariable ["ace_cargo_loaded", []];
            _list deleteAt (_list find _x);
            _veh setVariable ["ace_cargo_loaded", _list, true];
            detach _x;
            [_x, false] remoteExec ["hideObjectGlobal", 2];
            _x setPosATL (_toPos getPos [6 + _forEachIndex * 2, 90]);
        } forEach (_crates select [1, 2]);
        sleep 7;
        ["Logistics: not delivered while a crate is still loaded", ([_taskId] call BIS_fnc_taskState) isNotEqualTo "SUCCEEDED" && { (player getVariable ["OT_logisticsActive", ""]) isEqualTo _id },
            [_taskId] call BIS_fnc_taskState] call OTQA_fnc_check;

        // "Unload delivery cargo" at the drop-off: the last crate comes out behind the truck, delivered
        ["Logistics: the unload action finds the truck from beside it", ([_veh, _id] call { params ["_v", "_jid"]; private _old = getPosATL player; player setPosATL (_v modelToWorld [4, 0, 0]); sleep 0.5; private _found = [player, _jid] call OT_fnc_logisticsCargoVehicle; player setPosATL _old; _found }) isEqualTo _veh, ""] call OTQA_fnc_check;
        private _space = _veh getVariable ["ace_cargo_space", 0];
        private _out = [_veh, _id] call OT_fnc_logisticsUnload;
        sleep 0.5;
        ["Logistics: unloading sets the crate down behind the truck, space back", _out isEqualTo 1 && { isNull (attachedTo _crate) } && { !(isObjectHidden _crate) } && { !(_crate in (_veh getVariable ["ace_cargo_loaded", []])) } && { (_veh getVariable ["ace_cargo_space", 0]) isEqualTo (_space + 1) } && { (_crate distance2D _veh) < 15 },
            format ["unloaded %1, attached %2, hidden %3, %4 m from the truck, space %5 -> %6", _out, attachedTo _crate, isObjectHidden _crate, round (_crate distance2D _veh), _space, _veh getVariable ["ace_cargo_space", 0]]] call OTQA_fnc_check;
        "Logistics: drive a rented truck to a drop-off; 'Unload delivery cargo' shows within 40 m, by or in the truck, and sets the crates down behind it" call OTQA_fnc_manual;
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

        // The rental goes back to the broker: not the player's, locked, gone in 20 seconds
        ["Logistics: the rental is taken back (no owner, locked)", isNull _veh || { !(_veh call OT_fnc_hasOwner) && { (locked _veh) >= 2 } },
            format ["owner %1, locked %2", if (isNull _veh) then { "-" } else { _veh call OT_fnc_getOwner }, if (isNull _veh) then { "-" } else { locked _veh }]] call OTQA_fnc_check;
        private _gone = time + 25;
        waitUntil { sleep 1; isNull _veh || { time > _gone } };
        ["Logistics: the rental is gone 20 seconds after the job", isNull _veh, ""] call OTQA_fnc_check;

        [_crates + [_veh]] call OTQA_haul_cleanup;
    }, 120],

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
    }, 40],

    ["Logistics: brokers work from sheds by a road, away from businesses", {
        private _brokers = server getVariable ["logisticsBrokers", []];
        ["Logistics: brokers were placed", (count _brokers) > 0, format ["%1 brokers on %2: %3", count _brokers, worldName, _brokers apply { _x select 1 }]] call OTQA_fnc_check;
        private _businesses = (OT_economicData apply { _x select 0 }) + [OT_factoryPos];
        private _bad = [];
        {
            _x params ["_id", "_name", "_stand", "_loading", "_origin", "_dir"];
            private _shed = (missionNamespace getVariable ["OT_brokerSheds", createHashMap]) getOrDefault [_id, objNull];
            private _middle = if (isNull _shed) then { _origin } else { _shed modelToWorld [3.75, 3.35, 0] };
            private _problems = [];
            if (isNull _shed || { (typeOf _shed) isNotEqualTo "Land_i_Shed_Ind_F" }) then { _problems pushBack "no shed" };
            if ((_businesses findIf { (_x distance2D _middle) < 200 }) > -1) then { _problems pushBack "within 200 m of a business" };
            if !(isOnRoad _loading) then { _problems pushBack "loading spot not on a road" };
            // The road within 10 m of the shed's long side: the loading spot is 6 m from its south wall
            if (!isNull _shed && { ((_shed modelToWorld [3.75, -2.3, 0]) distance2D _loading) > 10 }) then { _problems pushBack "road too far" };
            if (_problems isNotEqualTo []) then { _bad pushBack [_name, _problems] };
        } forEach _brokers;
        ["Logistics: each broker has a shed by a road, 200 m+ from businesses", _bad isEqualTo [], str _bad] call OTQA_fnc_check;

        // A broker stands in his shed's office (spawned once a player is near)
        if (_brokers isEqualTo []) exitWith {};
        private _home = getPosATL player;
        (_brokers select 0) params ["_id", "_name", "_stand"];
        player setPosATL ((_stand getPos [25, 0]) findEmptyPosition [0, 40, "CAManBase"]);
        private _broker = objNull;
        private _timeout = time + 30;
        waitUntil { sleep 1; _broker = (allUnits select { (_x getVariable ["OT_broker", ""]) isEqualTo _id }) param [0, objNull]; !isNull _broker || { time > _timeout } };
        private _shed = (missionNamespace getVariable ["OT_brokerSheds", createHashMap]) getOrDefault [_id, objNull];
        private _inOffice = !isNull _broker && { !isNull _shed } && {
            private _m = _shed worldToModel (ASLToAGL (getPosASL _broker));
            (_m select 0) > -9 && { (_m select 0) < -4.5 } && { (_m select 1) > -2.3 } && { (_m select 1) < 2.6 }
        };
        ["Logistics: the broker stands in the shed's office", _inOffice,
            format ["%1 at %2 in the shed's own coordinates", _name, if (isNull _broker || { isNull _shed }) then { "-" } else { (_shed worldToModel (ASLToAGL (getPosASL _broker))) apply { (round (_x * 10)) / 10 } }]] call OTQA_fnc_check;
        player setPosATL _home;
    }, 60]
]
