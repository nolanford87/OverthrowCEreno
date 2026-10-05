/*
    Description:
    A resistance town falls back under the occupier's control: it's off the resistance's list, its
    stability is set, its resistance support drops, the resistance police station and its police are
    removed and the occupier gets a small garrison there. Used when an occupier FOB's takeover timer
    runs out (OT_fnc_NATOFOBtimers) and when the occupier wins a counter-attack on the town
    (OT_fnc_NATOCounterTown). The callers notify the players.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Its stability afterwards (0-100)
        _this # 2: NUMBER - Resistance support it loses

    Usage: [_town, 100, server getVariable [format ["rep%1", _town], 0]] call OT_fnc_NATOretakeTown;

    Returns: Nothing
*/

params ["_town", "_stability", "_supportLoss"];

private _abandoned = server getVariable ["NATOabandoned", []];
private _index = _abandoned find _town;
if (_index > -1) then { _abandoned deleteAt _index };
server setVariable ["NATOabandoned", _abandoned, true];
server setVariable [format ["NATOpatrolsent%1", _town], false];
server setVariable [format ["officeheld%1", _town], nil, true]; // Its mayor's office is theirs again

[_town, -_supportLoss] call OT_fnc_support;
[_town, _stability - (server getVariable [format ["stability%1", _town], 0])] call OT_fnc_stability;

// The resistance's police station goes: building, police count, marker, and its police
private _policePos = server getVariable [format ["policepos%1", _town], []];
if (_policePos isNotEqualTo []) then {
    { deleteVehicle _x } forEach ((nearestObjects [_policePos, [OT_policeStation], 30]) select { _x call OT_fnc_hasOwner });
};
{ deleteVehicle _x } forEach (allUnits select { (_x getVariable ["polgarrison", ""]) isEqualTo _town });
server setVariable [format ["police%1", _town], nil, true]; // A new station starts fresh
server setVariable [format ["policepos%1", _town], nil, true];
private _policeMarker = format ["%1-police", _town];
_policeMarker remoteExec ["deleteMarkerLocal", 0, false];
deleteMarker _policeMarker;

// The garrison a town at 100% stability starts with (initNATO)
private _garrison = [2, 4] select (_town in OT_NATO_priority);
server setVariable [format ["garrison%1", _town], (server getVariable [format ["garrison%1", _town], 0]) max _garrison, true];
