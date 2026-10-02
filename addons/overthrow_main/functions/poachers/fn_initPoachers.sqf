/*
    Description:
    Starts poachers on the server (OT_fnc_initHunting, once the hunting spots are picked). Animals
    killed in a hunting spot by players or the resistance's men put hunting pressure on it
    (OT_fnc_poacherKill); picking up the meat may bring a poacher patrol, more likely the more has been
    taken there lately (OT_fnc_poacherRoll). OT_fnc_poacherLoop runs them every 2 seconds. Nothing of
    it is saved: pressure starts at nothing on load.

    State (server, missionNamespace):
        OT_poacherPressure - HASHMAP spot index -> [[time, weight], ...] kills (OT_fnc_poacherPressure)
        OT_poacherEvents - HASHMAP spot index -> the poachers there (OT_fnc_poacherPatrol)
        OT_poacherQuiet - HASHMAP spot index -> time until which no patrol comes (OT_poacherQuietTime
            after players wiped the poachers there out)
        OT_poacherCleanup - ARRAY of [objects, groups] left behind, deleted once no player is near

    Usage: [] call OT_fnc_initPoachers; (server)
*/

if (!isServer) exitWith {};
if (!isNil "OT_poacherLoopId") exitWith {};

if (isNil "OT_poacherPressure") then { OT_poacherPressure = createHashMap };
if (isNil "OT_poacherEvents") then { OT_poacherEvents = createHashMap };
if (isNil "OT_poacherQuiet") then { OT_poacherQuiet = createHashMap };
if (isNil "OT_poacherCleanup") then { OT_poacherCleanup = [] };
OT_poacherLoopId = [OT_fnc_poacherLoop, 2] call CBA_fnc_addPerFrameHandler;
