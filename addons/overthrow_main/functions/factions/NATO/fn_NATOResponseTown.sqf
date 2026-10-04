/*
    Description:
    The occupier's QRF for a town at stability 0: the resistance wins the town if it holds off the
    attack. Around the town's centre (OT_fnc_NATOQRFfight's head count), or for its mayor's office
    (OT_fnc_officeCapture) the office itself: held by the resistance or won back by the occupier.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Strength
        _this # 2: ARRAY - (Optional) Its mayor's office position, the fight is for the office
        _this # 3: NUMBER - (Optional) The office's radius (OT_fnc_officeRadius), default 30

    Usage: [_town, _strength] spawn OT_fnc_NATOResponseTown;

    Returns: Nothing
*/

params ["_town", "_strength", ["_office", []], ["_radius", 30]];
private _posTown = [_office, server getVariable _town] select (_office isEqualTo []);
_town setMarkerAlpha 0;

private _tskid = [independent, [format ["assault%1", _town]], [format ["%2 is assaulting %1.", _town, OT_NATO_name], format ["Battle for %1", _town], format ["assault%1", _town]], _posTown, 1, 2, true, "Defend", true] call BIS_fnc_taskCreate;

format ["%2 is attacking %1", _town, OT_NATO_name] remoteExec ["OT_fnc_notifyMinor", 0, false];

private _success = {
    params ["_tskid", "_town"];
    [_tskid, "FAILED", true] spawn BIS_fnc_taskSetState;
    [_town, 50] call OT_fnc_stability;
    server setVariable [format ["officeheld%1", _town], nil, true]; // The office is theirs again, its guards come back
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
    // Won the first QRF for it: no counter-attack on it for at least an hour (OT_fnc_NATOcounterTowns)
    ["set", _town, 3600] call OT_fnc_NATOtownGrace;
};

[_posTown, _strength, _success, _fail, [_tskid, _town], _town, [0, _radius] select (_office isNotEqualTo [])] spawn OT_fnc_NATOQRF;
