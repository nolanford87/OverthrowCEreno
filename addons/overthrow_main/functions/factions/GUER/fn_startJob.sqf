params ["_id", "_job", "_repeat", "_expires"];
_job params ["_info", "_markerPos", "_setup", "_fail", "_success", "_end", "_jobparams"];
if !(_jobparams call _setup) exitWith {
    private _active = spawner getVariable ["OT_activeJobs", []];
    private _idx = -1;
    {
        _x params ["_cid"];
        if (_cid == _id) exitWith { _idx = _forEachIndex };
    } forEach _active;
    if (_idx > -1) then {
        _active deleteAt _idx;
        spawner setVariable ["OT_activeJobs", _active, true];
    };

    _active = spawner getVariable ["OT_activeJobIds", []];
    if (_id in _active) then { _active deleteAt (_active find _id) };
    spawner setVariable ["OT_activeJobIds", _active, true];
};

[
    {
        params ["_id", "_job", "_repeat", "_info", "_markerPos", "_setup", "_fail", "_success", "_end", "_jobparams", "_expires"];

        private _done = false;
        // Real seconds left: each game hour of the limit is 15 real minutes (Overthrow's original 4x),
        // whatever the time speed
        spawner setVariable [format ["OT_jobRemain%1", _id], _expires * 900, true];

        if (_expires < 1) then {
            spawner setVariable [format ["OT_jobNoExpire%1", _id], true, true];
        };
        [
            {
                (_this select 0) params ["_done", "_id", "_job", "_repeat", "", "", "", "_fail", "_success", "_end", "_jobparams", "_expires", "_lastdate"];
                private _handle = _this select 1;
                private _remains = spawner getVariable [format ["OT_jobRemain%1", _id], 0];
                if (!_done) then {
                    private _now = time;
                    private _elapsed = ((_now - _lastdate) max 0) min 30; // A pause or reload doesn't eat the time
                    _remains = _remains - _elapsed;
                    (_this select 0) set [12, _now]; //updates _lastdate
                    if (_expires < 1) then { _remains = 1 };
                    private _wassuccess = false;
                    if (call {
                        if (_remains <= 0) exitWith {
                            _wassuccess = false;
                            true;
                        };
                        if (_jobparams call _success) exitWith {
                            _wassuccess = true;
                            true;
                        };
                        if (_jobparams call _fail) exitWith {
                            _wassuccess = false;
                            true;
                        };
                        false;
                    }) then {
                        _jobparams pushBack _wassuccess;
                        _jobparams call _end;
                        private _active = spawner getVariable ["OT_activeJobs", []];
                        private _idx = -1;
                        {
                            _x params ["_cid"];
                            if (_cid == _id) exitWith { _idx = _forEachIndex };
                        } forEach _active;
                        if (_idx > -1) then {
                            _active deleteAt _idx;
                            spawner setVariable ["OT_activeJobs", _active, true];
                        };

                        _active = spawner getVariable ["OT_activeJobIds", []];
                        if (_id in _active) then { _active deleteAt (_active find _id) };
                        spawner setVariable ["OT_activeJobIds", _active, true];

                        if (_wassuccess) then {
                            format ["Job completed: %1", (_job select 0) select 0] remoteExec ["OT_fnc_notifyGood", 0, false];
                        } else {
                            if (_remains > 0) then {
                                format ["Job failed: %1", (_job select 0) select 0] remoteExec ["OT_fnc_notifyBad", 0, false];
                            } else {
                                format ["Job expired: %1", (_job select 0) select 0] remoteExec ["OT_fnc_notifyBad", 0, false];
                            };
                        };

                        if (_remains > 0) then {
                            if (_repeat < 1) then {
                                private _completed = server getVariable ["OT_completedJobIds", []];
                                _completed pushBack _id;
                                server setVariable ["OT_completedJobIds", _completed, true];
                            };
                        };

                        [_handle] call CBA_fnc_removePerFrameHandler;
                    };
                    spawner setVariable [format ["OT_jobRemain%1", _id], _remains, true];
                };
            },
            2,
            [_done, _id, _job, _repeat, _info, _markerPos, _setup, _fail, _success, _end, _jobparams, _expires, time]
        ] call CBA_fnc_addPerFrameHandler;
    },
    [_id, _job, _repeat, _info, _markerPos, _setup, _fail, _success, _end, _jobparams, _expires],
    5
] call CBA_fnc_waitAndExecute;
