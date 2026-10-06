/*
    Description:
    Helpers the mayor's office and compound tests share (OTQA_fnc_testsOfficeGameplay, OTQA_fnc_testsCompounds):
    towns with a layout, an office's position, saving and restoring what a capture test changes, waiting for no
    QRF, one of ours standing somewhere, a camera over a test as it runs.

    Returns: Nothing
*/

// Towns with an office layout, farthest from the host first (locked at 100 people or more, or under 100 with _small)
OTQA_og_towns = {
    params [["_small", false]];
    private _towns = OT_allTowns select { ([_x] call OT_fnc_officeLayout) isNotEqualTo [] && { (([_x] call OT_fnc_officeBracket) <= 2) isEqualTo _small } };
    [_towns, [], { (server getVariable [_x, [0, 0, 0]]) distance2D player }, "DESCEND"] call BIS_fnc_sortBy;
};
OTQA_og_officePos = { ASLToAGL ((([_this] call OT_fnc_officeLayout) select 0) select 1) };

// Everything the capture tests change
OTQA_og_save = {
    params ["_town"];
    OT_nextNATOTurn = time + 3600;
    createHashMapFromArray [
        ["abandoned", +(server getVariable ["NATOabandoned", []])],
        ["resources", server getVariable ["NATOresources", 2000]],
        ["grace", +(server getVariable ["NATOtownGrace", []])],
        ["lastAttack", server getVariable ["NATOlastattack", 0]],
        ["stability", server getVariable [format ["stability%1", _town], 50]],
        ["garrison", server getVariable [format ["garrison%1", _town], 0]]
    ];
};
OTQA_og_restore = {
    params ["_town", "_saved"];
    OT_officeHoldTime = nil;
    OT_QRFsetupTime = nil;
    OT_QRFforceResult = nil;
    server setVariable ["NATOabandoned", _saved get "abandoned", true];
    server setVariable ["NATOresources", _saved get "resources", true];
    server setVariable ["NATOtownGrace", _saved get "grace", true];
    server setVariable ["NATOlastattack", _saved get "lastAttack", true];
    server setVariable [format ["stability%1", _town], _saved get "stability", true];
    server setVariable [format ["garrison%1", _town], _saved get "garrison", true];
    server setVariable [format ["officeheld%1", _town], nil, true];
    OT_nextNATOTurn = time + 120;
};
OTQA_og_idle = {
    private _timeout = time + 60;
    waitUntil { sleep 1; (server getVariable ["NATOattacking", ""]) isEqualTo "" || { time > _timeout } };
    (server getVariable ["NATOattacking", ""]) isEqualTo ""
};
// One of ours standing in the office
OTQA_og_ours = {
    params ["_pos"];
    private _group = createGroup [independent, true];
    private _unit = _group createUnit ["I_soldier_F", _pos, [], 0, "CAN_COLLIDE"];
    _unit allowDamage false;
    _unit disableAI "MOVE";
    _unit
};
// A camera over a test while it runs (as the layout check's): _offset from the subject (an object it follows,
// or a position), looking at it; OTQA_og_cameraOff ends it. Only where there's a screen
OTQA_og_camera = {
    params ["_subject", ["_offset", [0, -15, 15]]];
    call OTQA_og_cameraOff;
    if (!hasInterface) exitWith {};
    private _cam = "camera" camCreate (getPosATL player);
    _cam cameraEffect ["INTERNAL", "BACK"];
    cameraEffectEnableHUD false;
    OTQA_og_cam = _cam;
    [_cam, _subject, _offset] spawn {
        params ["_cam", "_subject", "_offset"];
        while { !isNull _cam } do {
            private _at = if (_subject isEqualType objNull) then { if (isNull _subject) then { (getPosATL _cam) vectorDiff _offset } else { getPosATL _subject } } else { _subject };
            _cam camSetTarget _at;
            _cam camSetPos (_at vectorAdd _offset);
            _cam camCommit 1;
            sleep 1;
        };
    };
};
OTQA_og_cameraOff = {
    if (!isNil "OTQA_og_cam" && { !isNull OTQA_og_cam }) then {
        OTQA_og_cam cameraEffect ["TERMINATE", "BACK"];
        camDestroy OTQA_og_cam;
    };
    OTQA_og_cam = nil;
};
