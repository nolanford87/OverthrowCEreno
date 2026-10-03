/*
    Description:
    Starts drugs on the server: the wild ganja zones (saved, "ganjaZones") get their spawners and
    revealed ones their markers; a new game grows OT_ganjaZoneCount of them at once, a loaded one
    missing some (harvested out before saving) grows them back over 30-60 real minutes. Owned
    dispensaries are registered as drug operations ("drugOps", OT_fnc_dispensaryRegister). Then the
    ganja loop (OT_fnc_ganjaLoop) runs every 5 seconds.

    Usage: [] spawn OT_fnc_initDrugs; (server)
*/

if (!isServer) exitWith {};
waitUntil { sleep 1; !isNil "OT_economyLoadDone" };

OT_ganjaSpawners = createHashMap; // Zone id: spawn id
OT_ganjaZonePlants = createHashMap; // Zone id: plants spawned
OT_ganjaRegrow = []; // [time, position replaced]: harvested-out zones' replacements (session)
OT_ganjaPlants = [];
publicVariable "OT_ganjaPlants";

private _fresh = (server getVariable ["ganjaNextId", 0]) isEqualTo 0;
{
    _x params ["_id", "_pos", "", "_revealed"];
    OT_ganjaSpawners set [_id, format ["spawn%1", [_pos, OT_fnc_spawnGanjaZone, [_id]] call OT_fnc_registerSpawner]];
    if (_revealed) then { [_id] call OT_fnc_ganjaZoneMarker };
} forEach (server getVariable ["ganjaZones", []]);
private _missing = OT_ganjaZoneCount - count (server getVariable ["ganjaZones", []]);
for "_i" from 1 to _missing do {
    if (_fresh) then {
        [] call OT_fnc_ganjaNewZone;
    } else {
        OT_ganjaRegrowRange params ["_soonest", "_latest"];
        OT_ganjaRegrow pushBack [time + _soonest + random (_latest - _soonest), []];
    };
};
diag_log format ["Overthrow: %1 wild ganja zones on %2", count (server getVariable ["ganjaZones", []]), worldName];

// Dispensaries bought before (or from an older build) are drug operations
if (isNil { server getVariable "drugOps" }) then { server setVariable ["drugOps", [], true] };
{
    if (_x in (server getVariable ["GEURowned", []])) then { [_x] call OT_fnc_dispensaryRegister };
} forEach OT_dispensaries;

OT_drugsInitDone = true;
publicVariable "OT_drugsInitDone";
[OT_fnc_ganjaLoop, 5] call CBA_fnc_addPerFrameHandler;
