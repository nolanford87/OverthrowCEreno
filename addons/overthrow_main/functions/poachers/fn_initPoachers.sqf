/*
    Description:
    Starts poachers on the server (OT_fnc_initHunting, once the hunting spots are picked). Shots in a
    hunting spot heat it up (OT_fnc_poacherShot, from the "FiredMan" handler OT_fnc_wantedSystem
    adds); a full spot with a player in it gets a poacher patrol, run by OT_fnc_poacherLoop every 2
    seconds. Nothing of it is saved: heat starts cold on load.

    State (server, missionNamespace):
        OT_poacherHeat - HASHMAP spot index -> [heat, time it was worked out] (OT_fnc_poacherHeat)
        OT_poacherEvents - HASHMAP spot index -> the poachers there (OT_fnc_poacherPatrol)
        OT_poacherCleanup - ARRAY of [objects, groups] left behind, deleted once no player is near
        OT_poacherCoolRate - NUMBER (Optional, tests) heat lost per second instead of the normal rate

    Usage: [] call OT_fnc_initPoachers; (server)
*/

if (!isServer) exitWith {};
if (!isNil "OT_poacherLoopId") exitWith {};

if (isNil "OT_poacherHeat") then { OT_poacherHeat = createHashMap };
if (isNil "OT_poacherEvents") then { OT_poacherEvents = createHashMap };
if (isNil "OT_poacherCleanup") then { OT_poacherCleanup = [] };
OT_poacherLoopId = [OT_fnc_poacherLoop, 2] call CBA_fnc_addPerFrameHandler;
