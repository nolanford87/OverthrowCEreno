# Villages: round 4 critique (4242db81)

Tested in the game (all 15, then the flagged ones again): `round4/measurements.md` (the first run) and the
screenshots in `round4/`. Every item spawned. The re-run gives flagged items' [x, y] in the office's model
coordinates. Guards settle a little differently each run, so a 1 m reading that appears in one run and not the other
is marginal; the ones below showed in both or are clear.

## Design
Kore T3 is the standard to hit: a closed 2-high ring tied into the field wall, the tower at the road corner, a gated
entry. Lakka T3 also reads well. Telos T3 is thin for a top tier: one H-barrier row along the porch front and a short
piece on the east side; the west side and the yard behind are open. Close Telos like Kore. Check every T3 against
Kore's top view.

## Measured problems
- **Kore GMG** (-15.5, 0.5): 0.4 m in the re-run, 0 m in the first. Something stands right in front of it (the field
  wall west of the ring?). Turn it or move it to a gap with open ground ahead.
- **Poliakko's door gendarme** (3.9, 2.8): 1.1 m in both runs, at every tier.
- **The map board cuts into the office** in every village (all tiers): stand it 0.3 m off the wall.
- **Alikampos**: the flag cuts into the office; HBarrier_5 into a stone wall mid-piece (T3).
- **Clipping mid-piece (T3)**:
  - **Selakano**: two HBarrier_Big and an HBarrier_3 into city walls.
  - **Stavros**: HBarrier_5 and HBarrier_Big into a stone wall, and five HBarrier_1 into the office itself.
  - **Telos**: two HBarrier_5 and an HBarrier_3 into a city wall.
  - **Topolia**: BagFence_Long into the office (T2).
- Nifi's gendarme and Selakano's GMG were clean in the re-run: leave them.

Fix these, keep tl.check() passing, push, and report.
