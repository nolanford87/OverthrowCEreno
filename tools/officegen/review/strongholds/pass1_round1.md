# Strongholds: pass 1 (walls), in-game round 1

Tested in the game: `pass1_round1/measurements.md` (with each way out's route) and the screenshots in
`pass1_round1/`. Every piece spawned.

## The big one: the rings hug the building
At Kavala, Pyrgos and Zaros, T4 and T5 are two walls wrapped tight round the office, with a 2-3 m corridor between
them and the building (see the T5 top views). That's not the ladder:
- **T4 is a sizeable outer perimeter** that takes in the office's compound: its yards and the cluster of buildings
  round it, as one fortified block. Round 6's designs had this: Kavala's west-yard bastion and north yard,
  Athira's courtyard, Zaros' west yard and south ground. Go back out to those lines, now in high walls.
- **T3 is the small, tight ring** round the office (and what's attached to it). The tight wrap belongs here.
- **T5 hardens both**: the T3 ring raised to high walls too, so there are two complete high-walled rings with real
  ground between them.
- Brief points to use (DESIGN_BRIEF.md, pass 1 rules): tiers may DROP pieces of the tier below (tl.check() allows
  it now, pull), and from T3 on H-barriers may stand along an existing wall to upgrade it.

## Closure (a man's route from inside the office to 8 points 60 m out)
- **Zaros**: T3-T5 closed (one route of eight not computed, none of the others out).
- **Athira**: T4 and T5 closed. T3 is out on the east side at (10, -1.4) and (10.2, -3.5), at (9.6, -8.2), and on
  the west at (-9.8, 3.8). The routes are in measurements.md.
- **Kavala and Pyrgos can't be checked**: a man inside the Offices_01 tower can't route out even on the bare site,
  so the check has no start inside. I'll judge them by the screenshots. Your audit has to carry closure there.

## Pieces
- **Zaros**: sandbags (BagFence_Long), HBarrier_3 and HBarrier_5 cut into the office (T2-T5), and a CncWall1
  (T5). Move them clear.

Fix these, push, write REPORT_pass1_round2.md and stop.
