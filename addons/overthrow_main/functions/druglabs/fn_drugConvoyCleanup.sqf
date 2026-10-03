/*
    Description:
    Clears a gang chemical convoy away once no player is within the given distance of its truck,
    escort or people (OT_fnc_drugConvoyMonitor, every 10 seconds once the run is over): its people
    (the dead too) and escort car are deleted, the truck too unless a player is in it or owns it.
    With a distance of 0 it's cleared at once, run over or not.

    Parameters:
        _this # 0: HASHMAP - The convoy
        _this # 1: NUMBER - (Optional) No player within this many metres, default 500

    Usage: [_convoy] call OT_fnc_drugConvoyCleanup; (server)

    Returns: BOOL - Cleared away (now or before)
*/

params ["_convoy", ["_range", 500]];

if (_convoy get "cleaned") exitWith { true };
private _units = _convoy get "units";
private _truck = _convoy get "truck";
private _escort = _convoy get "escort";
private _objects = (_units + [_truck, _escort]) select { !isNull _x };
if (_range > 0 && { (_objects findIf { private _o = _x; (allPlayers findIf { (_x distance2D _o) < _range }) > -1 }) > -1 }) exitWith { false };

_convoy set ["over", true];
_convoy set ["cleaned", true];
missionNamespace setVariable [format ["OT_drugConvoyOver_%1", _convoy get "id"], true, true];
{ if (!isNull _x) then { deleteVehicle _x } } forEach _units;
{
    if (!isNull _x && { ((crew _x) findIf { isPlayer _x }) isEqualTo -1 } && { !(_x call OT_fnc_hasOwner) }) then {
        { if !(isPlayer _x) then { deleteVehicle _x } } forEach (crew _x);
        deleteVehicle _x;
    };
} forEach [_truck, _escort];
private _group = _convoy get "group";
if (!isNull _group) then { deleteGroup _group };
if ((missionNamespace getVariable ["OT_drugConvoy", []]) isEqualTo _convoy) then { OT_drugConvoy = [] };
true;
