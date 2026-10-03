/*
    Description:
    Starts the occupier's heat and raids on drug operations (drugs slice 3a) on the server once the
    economy has loaded: the saved list "drugHeat" ([[operation id, heat, seconds shut, seconds of
    cooldown], ...]) is made if missing, a raid under way when the game was saved is forgotten (like a
    counter-attack), and a loop runs every 30 seconds while players are online: the heat decays and
    the timers count down (OT_fnc_drugHeatTick), and every OT_drugRaidRollEvery seconds the occupier
    rolls for a raid (OT_fnc_drugRaidCheck). Heat comes in from the operations' cycles
    (OT_fnc_drugHeat).

    Usage: [] spawn OT_fnc_initDrugRaids; (server)
*/

if (!isServer) exitWith {};
waitUntil { sleep 1; !isNil "OT_economyLoadDone" };

if (isNil { server getVariable "drugHeat" }) then { server setVariable ["drugHeat", [], true] };
server setVariable ["drugRaidTarget", "", true]; // A raid doesn't survive a reload
OT_drugRaidState = createHashMap;
OT_drugHeatLast = time;
OT_drugRaidNextRoll = time + OT_drugRaidRollEvery;

OT_drugRaidsInitDone = true;
publicVariable "OT_drugRaidsInitDone";

while { true } do {
    sleep 30;
    if ((count (allPlayers - (entities "HeadlessClient_F"))) isEqualTo 0) then {
        OT_drugHeatLast = time; // Time with nobody online doesn't count
    } else {
        [] call OT_fnc_drugHeatTick;
        if (time >= OT_drugRaidNextRoll) then {
            OT_drugRaidNextRoll = time + OT_drugRaidRollEvery;
            [] call OT_fnc_drugRaidCheck;
        };
    };
};
