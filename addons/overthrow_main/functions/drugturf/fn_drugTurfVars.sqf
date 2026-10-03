/*
    Description:
    Gang turf (drugs slice 3b): the numbers for gangs minding their turf, the land within
    OT_drugTurfRadius of their camp. Drug operations (dispensaries, labs) making or selling there
    (OT_fnc_drugTurf) and players dealing on the street there (OT_fnc_drugTurfStreet) anger the gang:
    rep lost, a warning, then a raid on the operation or an ambush on the dealer
    (OT_fnc_drugTurfAttack), unless the resistance pays its cut (OT_fnc_drugTurfDeal). Every machine,
    from OT_fnc_drugsVars.

    Usage: call OT_fnc_drugTurfVars;
*/

OT_drugTurfRadius = 1500; // A gang's turf: this far (m) from its camp; the nearest camp when they overlap

// Anger: per unit an operation makes or sells on its turf; a street sale counts OT_drugTurfStreetMult
// times (it's under their noses). Halved (OT_drugTurfLenient) when a player with OT_drugGangRep or more
// rep with the gang is behind it (any player on, for an operation; the seller, on the street)
OT_drugTurfAnger = createHashMapFromArray [["ganja", 1], ["blow", 2]];
OT_drugTurfStreetMult = 3;
OT_drugTurfLenient = 0.5;
OT_drugTurfRepPer = 10; // Anger points per rep lost with the gang (everyone on for an operation, the seller on the street)
OT_drugTurfDecay = 0.5; // Anger forgotten per real minute
OT_drugTurfWarnAt = 20; // Anger: they warn (once, until it has fallen to half of this)
OT_drugTurfAttackAt = 40; // Anger: they attack (the anger is spent, and builds up to twice this at most meanwhile)
OT_drugTurfAttackWait = 1200; // Real seconds between a gang's attacks

// The attack (OT_fnc_drugTurfAttack, OT_fnc_drugTurfSquad): men with the gang's gear, on foot
OT_drugTurfSquad = 3; // Men they send
OT_drugTurfAttackDelay = 180; // A raid on an operation out of spawn distance is simulated after this long (real seconds)
OT_drugTurfLoot = createHashMapFromArray [["OT_Ganja", 10], ["OT_Blow", 5]]; // Taken from a raided operation's containers, at most
OT_drugTurfSquadTimeout = 600; // Real seconds a squad is out at most

// The deal (OT_fnc_drugTurfDeal): a fee up front (the dealmaker's money), then the gang's cut of everything
// made on its turf: this share of a dispensary's sales (resistance funds) and of a street sale (the
// seller's money), and of a lab's batch in blow (out of its container)
OT_drugTurfCut = 0.2;
OT_drugTurfDealFee = 2500;
OT_drugTurfDealRep = 5; // The dealmaker's rep with the gang for making it
OT_drugTurfRepPerPaid = 1000; // And +1 rep for every this much ($, blow at the town's drug price) paid in cuts
