# Villages: pass 2a, the gates

Script: `tools/officegen/drafting/villages_pass2a.py`. Drafts: `tools/officegen/layouts/drafts/<town>.txt` for the 10
towns with a ring. Each town starts from `tl.baseline(town)`. Only the T3 ring changes: pieces come out at the
opening, a shorter piece closes the line's end where needed, and a `tl.gate()` marker goes at the opening's middle.
Tiers 1 and 2 and every other T3 piece are exactly the baseline's, including Alikampos' hides and the user's own
Neri. Abdera, Agios Konstantinos, Galati, Nifi and Topolia have no ring and were not touched.

**One gate per town, no second gate anywhere.** Each ring is small (a house and its yard), and the occupier's road
passes only one side. A back gate or sally port would be a second way in with nothing to flank.

**Conventions**
- Model coordinates: x right, y forward. The main door is on the back porch's west end at (-4.7, -6.2), facing
  -x. The front door is at (0.1, 5.3), facing +y.
- Width is the nominal gap between the pieces' ends. Where a 2-high piece forms one side, its measured box (9.0 m
  against 8.4) can make the real opening up to 0.3 m narrower.
- The gate's mdir is the direction the cut line runs, per `gate()`'s docstring: 90 for a line along x, 0 for one
  along y.
- New pieces are 1-high H-barriers on the ground, each running 0.3-0.45 m into the piece it meets. All pass
  `tl.check`, the copy of the game's clip test and the overlap audit.

| Town | Gate (x, y) | Width | Line | Faces / why there | Removed | Added |
|---|---|---|---|---|---|---|
| Alikampos | (-4.26, -13.5) | 3.5 m | back notch | Street at y -16.5, 3 m off the line; in line with the porch and main door | HBarrier_5 (-4.9, -13.5) | none (the notch's west side line and the HBarrier_5 at 0.4 form the two sides) |
| Dorida | (1.45, 10.5) | 4.1 m | front | Through road at y 15, before the front door | HBarrier_Big (-0.2, 10.3) | HBarrier_3 (-2.4, 10.3) |
| Gravia | (-4.08, 11.2) | 4.2 m | front | Open ground at the front-left, the way in from the main road on the west; down the west side to the main door | HBarrier_Big (-5.7, 11.2) | HBarrier_3 (-7.95, 11.2) |
| Kore | (-3.1, -14.0) | 4.2 m | back | Back road (missing from the probe; the line stands on its edge), before the porch | HBarrier_Big (-4.8, -14.0) | HBarrier_3 (-7.0, -14.0) |
| Lakka | (-0.4, -14.0) | 4.2 m | back | Track behind the house (y -17..-22), before the porch | HBarrier_Big (1.3, -14.0) | HBarrier_3 (3.5, -14.0) |
| Neri | (-4.0, 13.2) | 2.2 m | front | Track at y 20; lined up with the slot between the city wall and the addon | HBarrier_Big (-6.7, 13.2) | HBarrier_5 (-8.0, 13.2) |
| Poliakko | (7.3, -9.5) | 3.5 m | right | Track at x 12.5 (the line on its edge); into the back yard, since the strip beside the house is 2 m | HBarrier_Big (7.3, -8.4) | HBarrier_3 (7.3, -5.95), HBarrier_1 (7.3, -11.95) |
| Selakano | (-2.81, -13.5) | 3.6 m | back notch | Track along the notch (centre y -14.5), before the porch and main door | HBarrier_5 (-3.4, -13.5) | none |
| Stavros | (-2.76, -13.5) | 3.5 m | back notch | Plaza track crossing behind the notch (centre y -13.6), before the porch and main door | HBarrier_5 (-3.4, -13.5) | none |
| Telos | (1.15, 8.7) | 4.3 m | front | Track at y 12.5 (the line on its edge), before the front door; the left neighbour fills the front-left | HBarrier_Big (-0.4, 8.7) | HBarrier_3 (-2.8, 8.7) |

**Notes**
- At Dorida, Kore, Lakka and Telos a 2-high piece (8.4 m) is too long to leave a 3-4 m opening by itself, so an
  HBarrier_3 closes one side. That leaves a 1-high stretch of 3.6 m beside the gate.
- At Telos the front steps end 0.5 m short of the line's inside face: men can get through the gate, vehicles can't.
- At Gravia the yard inside the gate is about 3.7 m wide, and there's a short low wall at (-7, 6..7).
- At Neri the city wall city_8m (y 11.1, x -11.6..-4.6) stands behind the front line's west piece, and the addon's
  walls run x -2.4..4.3. The only way into the yard from the front is the 2.2 m slot between them, so the gate is
  2.2 m (x -5.1..-2.9). It wasn't hidden, being a full city wall: the user's call.
- Kore: pass 1 found the game's path finding ignores pieces on its back road, and the gate is in that line. A way
  out "NOT through a gate" through the 2-high pieces beside it would be that known road issue.
- Two baselines don't pass `tl.check` as they stand: Alikampos has a user hide of a plastic table the probe doesn't
  list, and Neri's tier 1 police post has 2 guards (so the check wants guards on tiers 2-3). The script lets
  through only problems the baseline already had.

**Closure audit:** pass 1's flood fill (a man 0.48 m across), started from the back porch and the foot of the
front steps (pass 1's start all round the house put cells outside Stavros' ring). Results:

| Town | Baseline | Gate open: ways out | Gate plugged |
|---|---|---|---|
| Alikampos | closed | 2, both through the gate | closed |
| Dorida | closed | 3, all through the gate | closed |
| Gravia | closed | 3, all through the gate | closed |
| Kore | closed | 3, all through the gate | closed |
| Lakka | closed | 2, both through the gate | closed |
| Neri | closed | 1, through the gate | closed |
| Poliakko | closed | 2, both through the gate | closed |
| Selakano | closed | 2, both through the gate | closed |
| Stavros | closed | 2, both through the gate | closed |
| Telos | closed | 2, both through the gate | closed |

A 4 m gate shows as 2-3 crossings because the fill plugs a 1.5 m disc and looks again.

(Written by the villages agent; saved by the lead, as the agent couldn't write files outside its drafts.)
