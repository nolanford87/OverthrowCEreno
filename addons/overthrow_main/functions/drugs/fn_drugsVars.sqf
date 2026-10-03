/*
    Description:
    Drugs (ganja): the constants for wild ganja zones, dispensaries and gang bulk deals, and the
    map's dispensaries (OT_fnc_dispensarySites). Runs on every machine from fn_initVar, after the
    fisheries and before the economy and virtualization set businesses up.

    Usage: call OT_fnc_drugsVars;
*/

// Wild ganja zones (OT_fnc_initDrugs): a few hidden patches in the countryside at once, revealed when
// a player comes near. Each has a few plants; a harvested-out zone is replaced elsewhere after a while
OT_ganjaZoneCount = 4;
OT_ganjaZoneRadius = 40; // Its marker; the plants grow within 30 m of the middle
OT_ganjaRevealDist = 60; // A player this close reveals it
OT_ganjaPlantsRange = [6, 8]; // Plants in a new zone
OT_ganjaYieldRange = [2, 4]; // Ganja per plant harvested
OT_ganjaRegrowRange = [1800, 3600]; // Real seconds before a harvested-out zone is replaced
OT_ganjaZoneSpacing = 1500; // From other zones (and from the one it replaces)
// Plant models (vanilla shrubs, as simple objects); a pot plant if none of them exists
OT_ganjaPlantModels = [
    "\a3\plants_f\Bush\b_FicusC1s_F.p3d",
    "\a3\plants_f\Bush\b_ficusC2d_F.p3d"
] select { fileExists _x };
OT_ganjaPlantFallback = "Land_Pot_02_F";

// Dispensaries (OT_fnc_dispensaryCycle): per employee, each business cycle, sold from stock at the
// town's drug price. Level 2 (the back room, paid upgrade) also moves blow
OT_dispensarySell = createHashMapFromArray [["OT_Ganja", 3], ["OT_Blow", 1]];
OT_dispensaryUpgradeCost = 25000;

// Gangs: with this much rep, members and the leader deal drugs in bulk (OT_fnc_gangDrugMenu):
// wholesale (lots, cheaper than a gun dealer) and buying the player's drugs (less than the street)
OT_drugGangRep = 20;
OT_drugWholesale = 0.7; // x the dealer's price in the gang's town
OT_drugBulkSell = 0.6; // x the dealer's price in the gang's town
OT_drugWholesaleLots = createHashMapFromArray [["OT_Ganja", 10], ["OT_Blow", 5]];

// Gang turf (drugs slice 3b): gangs minding drugs made or sold near their camp, and the deal for their cut
call OT_fnc_drugTurfVars;

call OT_fnc_dispensarySites;
