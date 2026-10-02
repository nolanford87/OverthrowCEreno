/*
    Description:
    Counts the player's hunting licence down in real time (every 10 seconds, not while the game is
    paused) and tells them when 10 minutes are left and when it runs out.

    Usage: [OT_fnc_huntingLicenceLoop, 10] call CBA_fnc_addPerFrameHandler; (player)
*/

private _now = time;
private _elapsed = ((_now - (missionNamespace getVariable ["OT_huntLicenceLast", _now])) max 0) min 30;
OT_huntLicenceLast = _now;

private _left = player getVariable ["OT_huntLicence", 0];
if (_left <= 0) exitWith {};
private _after = (_left - _elapsed) max 0;
if (_left > 600 && { _after <= 600 }) then { "Your hunting licence runs out in 10 minutes" call OT_fnc_notifyMinor };
if (_after <= 0) then { "Your hunting licence has run out" call OT_fnc_notifyMinor };
// Public so the server's copy (saved with the player) is current
player setVariable ["OT_huntLicence", _after, (floor (_after / 60)) isNotEqualTo (floor (_left / 60)) || { _after <= 0 }];
