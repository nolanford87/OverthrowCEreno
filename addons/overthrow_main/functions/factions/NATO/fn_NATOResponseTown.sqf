params ["_town", "_strength"];
private _posTown = server getVariable _town;
_town setMarkerAlpha 0;

private _tskid = [independent, [format ["assault%1", _town]], [format ["%2 is assaulting %1.", _town, OT_NATO_name], format ["Battle for %1", _town], format ["assault%1", _town]], _posTown, 1, 2, true, "Defend", true] call BIS_fnc_taskCreate;

format ["%2 is attacking %1", _town, OT_NATO_name] remoteExec ["OT_fnc_notifyMinor", 0, false];

private _success = {
    params ["_tskid", "_town"];
    [_tskid, "FAILED", true] spawn BIS_fnc_taskSetState;
    [_town, 50] call OT_fnc_stability;
    private _abandoned = server getVariable "NATOabandoned";
    _abandoned deleteAt (_abandoned find _town);
    server setVariable ["NATOabandoned", _abandoned, true];
};

private _fail = {
    params ["_tskid", "_town"];
    private _townpop = server getVariable format ["population%1", _town];
    _townpop remoteExec ["OT_fnc_influenceSilent", 0, false];
    format ["%3 has abandoned %1 (+%2 Influence)", _town, _townpop, OT_NATO_name] remoteExec ["OT_fnc_notifyGood", 0, false];
    [_tskid, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
    private _abandoned = server getVariable "NATOabandoned";
    _abandoned pushBack _town;
    server setVariable ["NATOabandoned", _abandoned, true];
};

[_posTown, _strength, _success, _fail, [_tskid, _town], _town] spawn OT_fnc_NATOQRF;
