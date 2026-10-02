/*
    Description:
    Starts fishing on the server: picks (or loads) the map's fishing grounds and registers a spawner
    for each (OT_fnc_spawnFishingGround). Fisheries are businesses (OT_economicData, OT_fnc_fisheryCycle).

    Usage: [] spawn OT_fnc_initFishing; (server)
*/

if (!isServer) exitWith {};
waitUntil { sleep 1; !isNil "OT_economyLoadDone" };

private _grounds = [] call OT_fnc_fishingGrounds;
{
    [_x, OT_fnc_spawnFishingGround, [_forEachIndex]] call OT_fnc_registerSpawner;
} forEach _grounds;

OT_fishingInitDone = true;
publicVariable "OT_fishingInitDone";
