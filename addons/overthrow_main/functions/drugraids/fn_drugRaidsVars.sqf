/*
    Description:
    Drugs slice 3a: the numbers for occupier heat on drug operations and the raids it brings
    (OT_fnc_drugHeat, OT_fnc_drugRaidCheck, OT_fnc_drugRaid). Runs on every machine from fn_initVar,
    right after the drugs' own numbers (OT_fnc_drugsVars), so the business info can show them.

    Usage: call OT_fnc_drugRaidsVars;
*/

// Heat: what an operation's output adds (OT_fnc_drugHeat), per unit sold or made, and what it loses
// per real minute (OT_fnc_drugHeatTick). A dispensary selling 30 ganja a cycle holds level, a lab
// cooking its full 18 blow a cycle climbs by about 150 an hour
OT_drugHeatPerUnit = createHashMapFromArray [["ganja", 1], ["blow", 3]];
OT_drugHeatDecay = 1;

// Raids (OT_fnc_drugRaidChance): none under the minimum heat; the chance per roll grows with heat up
// to the maximum at "full" heat, then falls with the town's stability: the full chance at stability 0,
// the floor x it at 100. Rolled every 5 real minutes (OT_fnc_drugRaidCheck), one raid at a time
OT_drugRaidHeatMin = 40;
OT_drugRaidHeatFull = 400;
OT_drugRaidChanceMax = 30; // % per roll
OT_drugRaidStabilityFloor = 0.25;
OT_drugRaidRollEvery = 300; // Real seconds

// Who comes (OT_fnc_drugRaid): the gendarmerie (4 in a police car) under this heat, the military (two
// squads in a truck, one by air; one more dispatch with over 2 players) from it. A raid costs the
// occupier its strength in resources, like a counter-attack
OT_drugRaidMilitaryHeat = 200;
OT_drugRaidStrength = createHashMapFromArray [["police", 100], ["military", 300]];
OT_drugRaidWarning = [120, 600]; // Real seconds' warning without / with intelligence (OT_fnc_NATOcounterIntel)

// Afterwards: a raid the occupier wins seizes the stock and shuts the operation for this long (real
// seconds), and leaves it this share of its heat; one the resistance holds off takes the heat to 0.
// Either way the operation isn't raided again for the cooldown
OT_drugRaidShutTime = 3600;
OT_drugRaidHeatAfterWin = 0.25;
OT_drugRaidCooldown = 2700;
