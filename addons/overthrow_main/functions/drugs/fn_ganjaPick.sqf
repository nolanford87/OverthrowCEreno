/*
    Description:
    A player harvested a wild ganja plant (server, OT_fnc_ganjaHarvest): the plant goes, its zone has
    one fewer, the player gets 2-4 ganja (OT_ganjaYieldRange, OT_fnc_ganjaGive where they are). The
    last plant harvests the zone out: it vanishes from the map and a new one grows elsewhere in 30-60
    real minutes (OT_ganjaRegrowRange, OT_fnc_ganjaLoop). Picking needs no licence; ganja is illegal.

    Parameters:
        _this # 0: OBJECT - The plant
        _this # 1: OBJECT - The player

    Usage: [_plant, player] remoteExec ["OT_fnc_ganjaPick", 2];

    Returns: NUMBER - Ganja given, 0 if the plant was already gone
*/

params ["_plant", "_player"];

if (!isServer || { isNull _plant } || { isNull _player }) exitWith { 0 };
private _id = -1;
{
    if (_plant in _y) exitWith { _id = _x };
} forEach OT_ganjaZonePlants;
if (_id < 0) exitWith { 0 };

private _zones = server getVariable ["ganjaZones", []];
private _index = _zones findIf { (_x select 0) isEqualTo _id };
if (_index < 0) exitWith { 0 };
private _zone = _zones select _index;

OT_ganjaZonePlants set [_id, (OT_ganjaZonePlants get _id) - [_plant]];
deleteVehicle _plant;
private _left = ((_zone select 2) - 1) max 0;
_zone set [2, _left];
server setVariable ["ganjaZones", _zones, true];

OT_ganjaYieldRange params ["_min", "_max"];
private _yield = _min + floor random ((_max - _min) + 1);
[_yield, _left] remoteExec ["OT_fnc_ganjaGive", _player, false];

if (_left isEqualTo 0) then {
    private _pos = _zone select 1;
    [_id] call OT_fnc_ganjaRemoveZone;
    OT_ganjaRegrowRange params ["_soonest", "_latest"];
    OT_ganjaRegrow pushBack [time + _soonest + random (_latest - _soonest), _pos];
} else {
    call OT_fnc_ganjaPublishPlants;
};
_yield
