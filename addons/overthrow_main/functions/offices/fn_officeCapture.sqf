/*
    Description:
    Taking a town by its mayor's office, once the town's stability is down to 0 (OT_fnc_NATOcheckTowns):
    the resistance gets a task to take the office; it's taken once no occupier soldier is left within
    30 m of it and the resistance has held it for 2 minutes. The occupier then counter-attacks the office
    (OT_fnc_NATOResponseTown, after its 10 minutes to get there, the time to bunker down): the resistance
    wins the town if it still holds the office when the attack is spent or runs out of time, the occupier
    wins it back by holding the office with nobody of the resistance inside for 2 minutes. While the
    resistance holds the office (server variable "officeheld<town>", saved) its guards don't come back;
    a game saved then and loaded again goes straight to the counter-attack. Gives up if the town's
    stability rises again first. One at a time per town. Server, scheduled.

    Parameters:
        _this # 0: STRING - Town (with an office layout, OT_fnc_officeLayout)

    Usage: [_town] spawn OT_fnc_officeCapture;

    Returns: Nothing
*/

params [["_town", "", [""]]];

private _running = format ["OT_officeCapture%1", _town];
if (missionNamespace getVariable [_running, false]) exitWith {};
missionNamespace setVariable [_running, true];

private _pos = ASLToAGL ((([_town] call OT_fnc_officeLayout) select 0) select 1);
private _held = format ["officeheld%1", _town];
private _holdTime = missionNamespace getVariable ["OT_officeHoldTime", 120]; // Shorter only in the QA tests

if !(server getVariable [_held, false]) then {
    private _task = format ["office%1", _town];
    [independent, [_task], [format ["Clear every %2 soldier out of the mayor's office in %1, then hold it for 2 minutes. %2 will counter-attack once it's ours.", _town, OT_NATO_name], format ["Take the mayor's office in %1", _town], _task], _pos, "CREATED", 2, true, "Attack", true] call BIS_fnc_taskCreate;

    private _for = 0;
    private _result = "";
    while { _result isEqualTo "" } do {
        sleep 5;
        if ((server getVariable [format ["stability%1", _town], 0]) > 0 || { _town in (server getVariable ["NATOabandoned", []]) }) then {
            _result = "CANCELED";
            continue;
        };
        // Nobody of the occupier's in the office (any floor), somebody of the resistance's
        private _units = (_pos nearEntities [["CAManBase"], 60]) select { alive _x && { (_x distance2D _pos) <= 30 } && { !(_x getVariable ["ace_isunconscious", false]) } };
        private _theirs = blufor countSide _units;
        private _ours = { side _x isEqualTo independent || { captive _x } } count _units;
        if (_theirs isEqualTo 0 && { _ours > 0 }) then {
            if (_for isEqualTo 0) then { format ["The mayor's office in %1 is clear: hold it for 2 minutes", _town] remoteExec ["OT_fnc_notifyMinor", 0, false] };
            _for = _for + 5;
            if (_for >= _holdTime) then { _result = "SUCCEEDED" };
        } else {
            _for = 0;
        };
    };
    [_task, _result, true] call BIS_fnc_taskSetState;
    if (_result isEqualTo "SUCCEEDED") then {
        server setVariable [_held, true, true];
        format ["We hold the mayor's office in %1. Bunker down: %2 will counter-attack it in about 10 minutes", _town, OT_NATO_name] remoteExec ["OT_fnc_notifyGood", 0, false];
    };
};

if (server getVariable [_held, false]) then {
    // The counter-attack, once no other is being fought
    waitUntil { sleep 5; (server getVariable ["NATOattacking", ""]) isEqualTo "" };
    private _resources = server getVariable ["NATOresources", 2000];
    private _popControl = call OT_fnc_getControlledPopulation;
    private _strength = (server getVariable [format ["population%1", _town], 100]) * ([3, 4, 5] select ({ _popControl > _x } count [1000, 2000]));
    _strength = [_strength min _resources, _resources] select (_town in OT_NATO_priority);
    server setVariable ["NATOresources", _resources - _strength];
    server setVariable [format ["garrison%1", _town], 0, true];
    server setVariable ["NATOattacking", _town, true];
    server setVariable ["NATOattackstart", time, true];
    [_town, _strength, _pos] call OT_fnc_NATOResponseTown;
    waitUntil { sleep 5; (server getVariable ["NATOattacking", ""]) isNotEqualTo _town };
};

missionNamespace setVariable [_running, nil];
