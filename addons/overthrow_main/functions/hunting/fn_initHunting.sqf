/*
    Description:
    Starts hunting on the server: picks (or loads) the map's hunting spots, registers a spawner for
    each (OT_fnc_spawnHuntingSpot), puts the revealed ones back on the map and runs the hunting loop
    (OT_fnc_huntingLoop: revealing spots, livestock at farms) every 5 seconds, and starts poachers
    (OT_fnc_initPoachers).

    Usage: [] spawn OT_fnc_initHunting; (server)
*/

if (!isServer) exitWith {};
waitUntil { sleep 1; !isNil "OT_economyLoadDone" };

private _spots = [] call OT_fnc_huntingSpots;
{
    [_x, OT_fnc_spawnHuntingSpot, [_forEachIndex]] call OT_fnc_registerSpawner;
} forEach _spots;

{
    [_x] call OT_fnc_huntingRevealMarker;
} forEach (server getVariable ["huntingRevealed", []]);

[] call OT_fnc_initPoachers; // Shots in a spot draw poachers

OT_huntingInitDone = true;
publicVariable "OT_huntingInitDone";
[OT_fnc_huntingLoop, 5] call CBA_fnc_addPerFrameHandler;
