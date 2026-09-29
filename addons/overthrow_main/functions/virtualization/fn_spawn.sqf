params ["_i", "_s", "_e", "_c", "_p", "_sp"];

// Mark the spawner as busy until its code has finished, so the virtualization loop
// doesn't despawn it half way through spawning (which left units behind)
spawner setVariable [format ["spawning%1", _i], time, false];
[_p + [_i], _c, _i] spawn {
    params ["_params", "_code", "_id"];
    _params call _code;
    spawner setVariable [format ["spawning%1", _id], nil, false];
};
_this set [5, time];
