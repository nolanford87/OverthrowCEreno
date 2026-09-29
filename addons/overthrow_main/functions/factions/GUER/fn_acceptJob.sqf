closeDialog 0;
private _id = OT_jobShowingID;
private _job = OT_jobShowing;
private _expiry = OT_jobShowingExpiry;
_job params ["_info", "_markerPos", "_setup", "_fail", "_success", "_end", "_jobparams"];

// The setup gives the player items, creates people next to them etc. so it runs here
if !(_jobparams call _setup) exitWith {};

if (_expiry isEqualTo 0) then {
    spawner setVariable [format ["OT_jobNoExpire%1", _id], false, true];
};

private _activeJobIds = spawner getVariable ["OT_activeJobIds", []];
_activeJobIds pushBack _id;
spawner setVariable ["OT_activeJobIds", _activeJobIds, true];

private _active = spawner getVariable ["OT_activeJobs", []];
_active pushBack [_id, _job, 1, _expiry];
spawner setVariable ["OT_activeJobs", _active, true];
"Job accepted, you can find it in the 'Jobs' screen" call OT_fnc_notifyMinor;

// The server tracks the job, success checks read data that only exists there (e.g. spawned garrisons).
// The setup has already run, so it's replaced with one that does nothing
[_id, [_info, _markerPos, { true }, _fail, _success, _end, _jobparams], 1, _expiry] remoteExec ["OT_fnc_startJob", 2, false];

[player, _markerPos, _info select 0] call OT_fnc_givePlayerWaypoint;
