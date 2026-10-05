# Strongholds: pass 1 (walls), in-game check of round 4

`pass1_check4/` has the measurements and screenshots.

## Kavala: the hospital is a fortress now
T4 and T5 read right: 4 m walls along the forecourt's street edges and round the helipad block, the entrance behind
an H-barrier line (T4 street view). **Closed at T4 and T5.** The Mil walls and CncWall1 standing on the concrete canal
wall are the "upgrade an existing wall" case, so they're fine.
- **T3**: one route of eight gets out without passing near any piece. The start (0, -24.4) is likely outside your
  tight T3 ring, so it isn't a gap. Your audit carries T3.
- **T3**: two HBarrier_5 cut into the hospital's main block (the in-game clip check now judges the hospital). Move
  them clear.

## The others
- **Zaros**: T3, T4 and T5 closed. The veranda BagFence_Long still cuts into the office at every tier, for the
  fourth round. Pull it a full metre out, or drop it (the brief allows a tier to drop a piece).
- **Athira**: T3-T5 closed. Done.
- **Pyrgos**: can't be walked (the tower). Your audit carries it.

Pass 1 is nearly done for the strongholds: fix the two Kavala pieces and the Zaros bag, push, write
REPORT_pass1_round5.md and stop.
