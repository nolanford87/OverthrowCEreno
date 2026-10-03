/*
    Description:
    Wild ganja, every 5 seconds on the server:
    - a player (not flying) within OT_ganjaRevealDist of a hidden zone reveals it to everyone, for good
      (saved in the zone, OT_fnc_ganjaZoneMarker)
    - a harvested-out zone's replacement grows once its timer is up (OT_ganjaRegrow), away from it
    - plants that despawned are dropped from the harvest list (OT_fnc_ganjaPublishPlants)

    Usage: [OT_fnc_ganjaLoop, 5] call CBA_fnc_addPerFrameHandler; (server)
*/

private _players = (allPlayers - entities "HeadlessClient_F") select { alive _x };

// Revealing zones
private _zones = server getVariable ["ganjaZones", []];
private _changed = false;
{
    _x params ["_id", "_pos", "", "_revealed"];
    if (_revealed) then { continue };
    private _finder = _players findIf {
        (_x distance2D _pos) < OT_ganjaRevealDist && { isNull objectParent _x || { !((objectParent _x) isKindOf "Air") } }
    };
    if (_finder < 0) then { continue };
    _x set [3, true];
    _changed = true;
    [_id] call OT_fnc_ganjaZoneMarker;
    "You found wild ganja growing, it's on the map" remoteExec ["OT_fnc_notifyMinor", _players select _finder, false];
} forEach _zones;
if (_changed) then { server setVariable ["ganjaZones", _zones, true] };

// Replacements for harvested-out zones: [time, position it replaces]
private _due = OT_ganjaRegrow select { (_x select 0) <= time };
if (_due isNotEqualTo []) then {
    OT_ganjaRegrow = OT_ganjaRegrow - _due;
    { [[], [_x select 1] select { _x isNotEqualTo [] }] spawn OT_fnc_ganjaNewZone } forEach _due;
};

call OT_fnc_ganjaPublishPlants;
