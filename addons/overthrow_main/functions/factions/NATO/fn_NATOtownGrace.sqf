/*
    Description:
    Grace periods during which the occupier won't counter-attack a resistance town
    (OT_fnc_NATOcounterTowns). A town gets one hour when the resistance wins the first QRF the
    occupier sends for it after it's taken (OT_fnc_NATOResponseTown) and when it holds off a
    counter-attack (OT_fnc_NATOCounterTown).
    Kept as real seconds left, counted down by the NATO loop (only while players are online, like the
    FOB timers) and saved with the game in the server variable "NATOtownGrace": [[town, seconds], ...].

    Parameters:
        _this # 0: STRING - "get" (seconds left), "set" (at least _seconds from now), "clear", or
            "tick" (count down, run by the NATO loop)
        _this # 1: STRING - Town
        _this # 2: NUMBER - Seconds, for "set" (default 3600)

    Usage: ["set", _town, 3600] call OT_fnc_NATOtownGrace;
        private _left = ["get", _town] call OT_fnc_NATOtownGrace;

    Returns: NUMBER - Seconds of grace left for the town (0 for "tick")
*/

params [["_mode", "get", [""]], ["_town", "", [""]], ["_seconds", 3600, [0]]];

private _grace = server getVariable ["NATOtownGrace", []];
private _index = _grace findIf { (_x select 0) isEqualTo _town };

if (_mode isEqualTo "get") exitWith {
    if (_index < 0) then { 0 } else { (_grace select _index) select 1 };
};

if (_mode isEqualTo "set") exitWith {
    if (_index < 0) then {
        _grace pushBack [_town, _seconds];
    } else {
        private _entry = _grace select _index;
        _entry set [1, (_entry select 1) max _seconds];
    };
    server setVariable ["NATOtownGrace", _grace, true];
    ["get", _town] call OT_fnc_NATOtownGrace;
};

if (_mode isEqualTo "clear") exitWith {
    if (_index > -1) then { _grace deleteAt _index };
    server setVariable ["NATOtownGrace", _grace, true];
    0;
};

// "tick": the loop only runs with players online, time without any doesn't count
private _now = time;
private _elapsed = ((_now - (missionNamespace getVariable ["OT_townGraceLast", _now])) max 0) min 30;
OT_townGraceLast = _now;
if (_grace isEqualTo [] || { _elapsed isEqualTo 0 }) exitWith { 0 };
{
    _x set [1, (_x select 1) - _elapsed];
} forEach _grace;
server setVariable ["NATOtownGrace", _grace select { (_x select 1) > 0 }, true];
0;
