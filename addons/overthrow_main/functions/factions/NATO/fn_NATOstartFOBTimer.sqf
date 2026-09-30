/*
    Description:
    Starts a FOB's 15 minute takeover timer, once its vehicle (its last upgrade) has arrived or was
    lost. When it runs out, the town nearest the FOB falls back under the occupier's control
    (OT_fnc_NATOFOBtimers), unless the FOB is cleared first. Once per FOB.

    Parameters:
        _this # 0: ARRAY - FOB position

    Usage: [_fobPos] call OT_fnc_NATOstartFOBTimer;
*/

if (!isServer) exitWith {};
params ["_fobPos"];

private _fob = (server getVariable ["NATOfobs", []]) select { (_x select 0) isEqualTo _fobPos } param [0, []];
if (_fob isEqualTo []) exitWith {};
private _upgrades = _fob select 2;
if ("TownTimer" in _upgrades) exitWith {};
_upgrades pushBack "TownTimer";

private _town = _fobPos call OT_fnc_nearestTown;
private _timers = server getVariable ["NATOfobTimers", []];
_timers pushBack [_fobPos, 900, _town]; // Seconds left
server setVariable ["NATOfobTimers", _timers];

format ["The %1 FOB near %2 is set up. In 15 minutes %2 falls back under its control unless the FOB is cleared", OT_NATO_name, _town] remoteExec ["OT_fnc_notifyMinor", 0, false];
diag_log format ["Overthrow: %1 FOB takeover timer started for %2", OT_NATO_name, _town];
