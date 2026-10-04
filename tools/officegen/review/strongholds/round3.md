# Strongholds: round 3 critique (with the tower fix, 19bb20c9)

Tested in the game: `round3/measurements.md` and the screenshots in `round3/`. The tower men now stand on the
platform (nobody was pushed off a post). The next round's measurements also give every flagged item's [x, y] in the
office's model coordinates, so you can find it.

## The big one: tiers 4-5 don't read as a fort / a stronghold yet
Look at the top views side by side with the ladder in the brief.
- **Zaros T4/T5**: a checkpoint row of H-barriers on the street in front, a few hedgehogs, two towers behind the house.
  There's no perimeter: the west yard (between the office and the west house) and the east side (to the garden
  wall) are wide open, and T5 adds only three H-barrier stacks and a bunker. T4 must close the compound (H-barrier
  lines from the office's corners to the neighbours and the garden wall, a gated entry), T5 an outer layer on the
  approach roads and the inside of the office held.
- **Athira T5**: separate H-barrier pieces standing in an open courtyard with gaps between them; no continuous line.
  The courtyard has three open sides (north-east, south-east and the alley). Join the pieces into lines that close
  each gap between the buildings.
- **Kavala T5**: the west yard is a good fort (bunkers at its corners, H-barrier lanes), but everything is on the west.
  The east yard (open dirt to the road, north-east) and the front garden on the south street have nothing; an
  attacker walks in from the east. Close the east yard and put the outer checkpoints on the east and north roads.
- **Pyrgos T5**: from above the ground floor's defences barely show (the trees hide some): check the perimeter
  joins the fences and the neighbours all round; the roof posts are good.

## Measured problems
- **Statics placed in walls**: Kavala's GMG and Pyrgos' GMG and AT gun cut into the office (from tier 3 on).
- **Statics blocked**: Kavala HMG 1.5 m (T4) and 2.5 m (T5); Athira HMGs 9.7 and 11.3 m (T4), 2.2 m (T5). A gun
  needs at least 15 m of open ground ahead.
- **Blind guards (view 0-1 m)**: Kavala T5 two autoriflemen; Athira T5 a rifleman, an autorifleman and a rifleman;
  Zaros a marksman (T4 on) plus an AT man and a rifleman (T5); Pyrgos T5 an autorifleman 1.1 m. The gendarme at
  Kavala's and Pyrgos' door sees 2.8 m: turn him along the street.
- **Clipping mid-piece** (not the allowed end overlap): Kavala T5 BagBunker_Small into a house, HBarrier_Big into a
  wall, CncBarrierMedium4 into a wall, HBarrier_3 into houses; Athira's towers into the office and a wall; Pyrgos'
  towers into the office, wire through a fence and a wall, BagBunker_Small into a fence; Zaros' two HBarrier_1 into
  a wall; the map board into the office's wall at Kavala and Pyrgos.
- **Athira's two AT guns "floating" 0.5-0.7 m**: the AT tripod shows this in every group; keep them on level
  ground and ignore it if the ground is level.

Fix these, keep tl.check() passing, push, and report.
