/*
    Description:
    A new wild ganja zone (server): hidden, with 6-8 plants (OT_ganjaPlantsRange), at a random valid
    spot (OT_fnc_ganjaFindSpot) or a given one. Recorded in the saved server variable "ganjaZones" as
    [id, position, plants left, revealed], with a spawner for its plants (OT_fnc_spawnGanjaZone).

    Parameters:
        _this # 0: ARRAY - (Optional) Position, [] to find one
        _this # 1: ARRAY - (Optional) Positions to keep away from when finding one (the zone it replaces)

    Usage: [] call OT_fnc_ganjaNewZone; (server, scheduled when finding a spot)

    Returns: NUMBER - Zone id, -1 if no spot was found
*/

params [["_pos", []], ["_avoid", []]];

if (_pos isEqualTo []) then { _pos = [[], 0, _avoid] call OT_fnc_ganjaFindSpot };
if (_pos isEqualTo []) exitWith {
    diag_log "Overthrow: no spot found for a wild ganja zone";
    -1
};
_pos = [_pos select 0, _pos select 1, 0];

OT_ganjaPlantsRange params ["_min", "_max"];
private _plants = _min + floor random ((_max - _min) + 1);
private _id = -1;
// Recorded without a break (unscheduled), two zones growing at once don't share an id
isNil {
    _id = server getVariable ["ganjaNextId", 0];
    server setVariable ["ganjaNextId", _id + 1, true];
    private _zones = server getVariable ["ganjaZones", []];
    _zones pushBack [_id, _pos, _plants, false];
    server setVariable ["ganjaZones", _zones, true];
    OT_ganjaSpawners set [_id, format ["spawn%1", [_pos, OT_fnc_spawnGanjaZone, [_id]] call OT_fnc_registerSpawner]];
};
_id
