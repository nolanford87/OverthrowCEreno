# Towns: pass 2a report (where the gates go)

Script: `tools/officegen/drafting/towns_pass2a.py` (run from the repository root; `-n` dry run, `-m` maps, `-r` the
tables below). Drafts: `tools/officegen/layouts/drafts/<town>.txt`, all ten towns (Molos left alone).

## How
- Every town starts from `tl.baseline(town)`, the user's reviewed tiers. T1 and T2 are untouched. In T3 and T4 the
  only changes are the gates: pieces taken out of a line, the stretch beside each opening re-laid so the line ends
  cleanly at the opening's edge (no piece hangs into it), and a `tl.gate()` marker at the opening's middle. A gate's
  "line" direction is the marker's `mdir` (along the line). The two review fixes (Agios Dionysios, Chalkeia) are
  described below.
- **One gate per ring everywhere; no town has a second gate.** No town has a second road into the compound that the
  occupier's vehicles would need and the first gate doesn't serve. The town's middle (from the mission's town list),
  the probe's roads and the veranda's open side (T2's bags) chose the side.
- The user's T4 drops the T3 ring in seven towns (Agios Dionysios, Chalkeia, Kalochori, Neochori, Paros, Sofia,
  Therisa), leaving one ring, or only the T3 face that is also the outer line. Those T4s get one gate. Two rings stand
  at T4 only in Charkia and Panochori: there the outer gate is round the corner from the inner one, so anyone coming
  in crosses the ground between the rings under the walls. Rodopoli is a special case (see below).
- Widths: about 3.6 m (3.1-3.9 where the pieces fit better) facing a road or track; 1.5 m where there is no road
  (Agios Dionysios). The width given is the marker's; "open" is measured between the solid ends either side.
- **Closure (checked by the agent, per tier 3+):** pass 1's flood fill (a 0.5 m man on a 0.5 m grid from the veranda
  and the side door, out to 43 m, through no building, real wall, rock or wall piece). Each tier passes three tests:
  1. with a block across every gate, there is no way out;
  2. with the gates open, he gets out, and the walk goes through each gate's middle and 1.2 m either side of it;
  3. at T4 with two rings, with only one ring's gate shut, there is still no way out.

  Where the user's line relies on something this walk lets a man cross but the game held, the walk holds it too.
  These are listed under the town (Kalochori, Neochori).
- `tl.check()` is clean for every draft, apart from three problems already in the user's baseline, left alone: hide
  items for small props the probe doesn't list (Charkia T3, Therisa T3), and Panochori's T1 guards, which make
  check() ask for guards in every tier. The script's `write()` refuses anything else.

## Per town
"Out" lists the pieces taken out (model [x, y]), "in" the pieces laid back.

### Agios Dionysios
No road within the probe's 60 m; the town's middle is 53 m west-south-west; the veranda's door bay opens west.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-13.00, -5.30) | 1.5 m (open 1.45) | west face (N-S) | in front of the door bay, towards the town; no road, so a man's width | out 4 HB3 (-13.00, -6.02 / -9.13 / -12.23 / -15.33); in HB5 + 2 HB3, re-laid from the south-west corner to the opening |
| T4 | (-20.00, -5.70) | 1.5 m (open 1.40) | west wall (N-S) | in line with the door bay, towards the town. One ring (the user's T4 drops the T3 ring) | out 6 W4 (-20.00, -8.19 / -4.78 / -1.36 / 2.06 / 5.47 / 8.89); in 6 W4, the wall north of the gate re-laid evenly to its top |

**The "large gap in the wall" (T4, north-west corner).** Pass 1's top view shows open ground where pass 1 ended the
line on the big shed's probed faces; its box runs about 6 m past the building there, so it was trimmed 4 m. The
user's four walls across the corner had slits between them, stood at three slightly different angles, and stopped
short of the north wall. Re-laid as one straight wall on the user's own line, from where it meets the west wall's
line (-20.00, 9.63) to where it meets the north wall's (-9.41, 23.00): 5 W4, joints 0.36 m, all facing out. Out:
(-18.55, 11.46), (-16.40, 14.55), (-13.71, 17.51), (-11.15, 20.80). In: (-18.85, 11.08), (-16.78, 13.70),
(-14.70, 16.31), (-12.63, 18.93), (-10.56, 21.55).

### Chalkeia
The only road is the dead-end track, which comes in from the north along the west face. The veranda's door bay opens
west onto it.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-7.00, -5.80) | 3.6 m (open 3.55) | west face (N-S) | onto the track, square in front of the door bay | out HB5 (-7.00, -6.09); in HB1 (-7.00, -8.14) |
| T4 | (-11.20, 24.00) | 3.6 m (open 3.50) | north wall (E-W) | across the track where it comes in from the north. One ring (the user's T4 drops the T3 ring's west, north and south faces); the track runs down inside the walls to the office | out 2 W4 (-12.44 / -9.40, 24.00, of the re-laid north wall); in 3 C1 (no all-W4 fit: the north wall is 18.9 m long) |

**The way out.** No measurements of the last check, so this comes from reasoning and the agent's walk. T3 is pass 1's
ring, checked closed in the game, plus one H-barrier of the user's, so the leak should be at T4, where the user took
the T3 ring out. The surest weak point was the top of the T4 west wall: it ended at (-24, 15.2) on the probed box of
the big north-west house (Land_i_House_Big_01_V3_F, the office's own class), which runs 2.3 m past the house's real
east corner (-23.9, 17.65): a 2.4 m gap, and the house has doors on two sides. The fix:
- the house's box trimmed to its real walls (+x face 2.3 m, +y face 0.7 m);
- the west wall re-laid 1 m east, at x -23.0, straight from its tie into the garage (y -5.77) to the north wall
  (y 24.4): 9 W4, joints 0.39 m. Out: 6 W4 and 2 C1 at x -24.0 (y 13.32, 10.09, 6.85, 4.97, 4.43, 2.55, -0.69, -3.92);
- the north wall re-laid from the new corner (x -23.4) to its east end (-4.51): 6 W4, joints 0.66 m. Out: x -22.89,
  -19.68, -16.48, -14.62 (C1), -12.77, -9.56, -6.36, all at y 24.

**What T4 still relies on (watch in the game).**
- The ruin (Land_d_House_Small_01, 11.5, 20.5) and the big rock south-east of the house (18.2, -12.1). The T3 ring
  relies on both the same way and checked closed.
- The buildings the west, south and north walls tie into: the garage, the two south-west shops, the south annexe
  (1.2, -35.1) and the north shop (1.2, 32.6). Any with doors both inside and outside the ring would be a way through.

### Charkia
Tracks all round; the open ground west of the house is a junction of them, and the track from the town's middle (31
m south-west) crosses the T4 compound's south-west corner. The door bay opens west. **Two rings stand at T4.**

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-12.50, -5.40) | 3.8 m (open 3.75) | west face (N-S) | onto the track junction, in front of the door bay | out 2 HB3 (-12.50, -6.13 / -3.35); in 2 HB1 (-12.50, -2.95 / -2.28) |
| T4 inner | (-12.50, -5.40) | 3.8 m | west face | kept from T3 | as T3 |
| T4 outer | (-9.70, -22.50) | 3.6 m (open 3.55) | south wall (E-W) | where the track from the town's middle crosses the wall; 17 m round the inner ring's south-west corner from the inner gate | out 5 W4 (-22.33 / -19.08 / -15.82 / -12.56 / -9.30, -22.50); in 4 W4, the wall west of the gate re-laid evenly to the corner |

### Kalochori
The main road runs east-west south of the house; the lane west of the house runs up from it to the veranda, which
opens west onto the lane. The user's T3 makes the lane's old stone wall the ring's west side and closed the lane's
mouth with three 1-high blocks. The user's T4 drops the T3 ring.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-7.22, -14.30) | 3.7 m (open 3.70) | across the lane's mouth (E-W) | onto the main road: up the lane to the veranda; from the south face's west end to the stone wall's corner | out the user's 3 HB1 (-8.46, -14.96), (-7.07, -14.47), (-6.05, -14.05); nothing in |
| T4 | (-6.10, -16.40) | 3.6 m (open 3.55) | south wall (E-W) | onto the main road at the lane's mouth, from the west wall's corner. One ring | out 6 W4 (-7.07 / -3.60 / -0.13 / 3.33 / 6.80 / 10.27, -16.40); in 5 W4, re-laid evenly to the corner |

Held in the walk: the lane's old stone walls (x about -9.4 to -9.9, y -15.3 to 9.3, and the slanted one from
(-9.41, -14.79) south-west). The walk lets a man over any low wall, but the user's rings rely on these and the game
found them closed.

### Neochori
The main road runs north-south along the west face; the door bay opens west onto it. The user's T4 keeps only the
west face of the T3 ring, stacked 2-high as the outer line along the road: one ring.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-7.00, -4.60) | 3.6 m (open 3.55) | west face (N-S) | onto the main road, square in front of the door bay | out 2 HB5 (-7.00, -4.88 / -9.62); in 2 HB3 (-7.00, -7.99 / -10.72), re-laid from the south corner |
| T4 | (-7.00, -4.60) | 3.6 m | west face, both layers | kept from T3 | out the same 2 HB5 and the 2 HB5 on them; in 2 HB3 and 2 HB3 on them |

Held in the walk (T4): the north shop's south-west wall, along its untrimmed box face from (9.5, 24.4) to (22.3,
18.1); the user's two angled walls at the north-east end tie into it.

### Panochori
A track runs north-south along the west face; it leaves the T4 compound south-west through the west wall, just north
of the big south-west house, towards the town's middle (41 m south-south-west). **Two rings stand at T4.**

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-8.20, 3.30) | 3.8 m (open 3.75) | west face (N-S) | onto the track, in the face's north half; not square in front of the door bay, so T4 keeps it out of line with the outer gate | out 2 HB5 (-8.20, 3.54 / 8.39); in 2 HB3 (-8.20, 6.79 / 9.50) |
| T4 inner | (-8.20, 3.30) | 3.8 m | west face | kept from T3 | as T3 |
| T4 outer | (-14.00, -9.25) | 3.6 m (open 3.55) | west wall (N-S) | where the track leaves south-west; its south edge is the big south-west house's wall. Attackers run 13 m up the track between the two walls to the inner gate | out all 10 W4 of the west wall (y -9.17 to 18.83); in 9 W4, re-laid evenly from the gate to the north corner |

### Paros
A track runs north-south along the west face and comes up from the main road in the south-west; the door bay opens
west. The user's T4 drops the T3 ring's west and north faces: one ring, the track inside it.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-9.50, -4.60) | 3.6 m (open 3.50) | west face (N-S) | onto the track, in front of the door bay | out 2 HB5 (-9.50, -6.84 / -2.10); in 2 HB3 (-9.50, -7.98 / -1.21) |
| T4 | (-12.75, -15.80) | 3.9 m (open 3.85) | south wall (E-W) | across the track's mouth on the main road | out W4 (-13.30), C1 (-11.40), C1 (-10.85), W4 (-8.95), all y -15.80; in W4 (-8.96, -15.80) |

### Rodopoli
The veranda opens west into a big yard walled by old city walls, the big south-west house and an annexe, open only
at a 3 m gap in its south side (pass 1 closed it with one H-barrier). South of the gap a passage runs between the
houses to the south track, the way from the town's middle.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-12.05, -17.00) | 3.1 m (open 2.95) | the yard's south side (E-W) | the gap itself, between the city wall's end and the annexe: up the passage into the yard, square onto the veranda | out HB3 (-12.10, -17.00); nothing in |
| T4 | (-12.05, -17.00) | 3.1 m | same | kept from T3 | out the same HB3 |

At T4 the yard's south side stays the outermost line where the gap is, so this gate is T4's one way in; there's no
outer ring in front of it to offset a gate in.

### Sofia
On a corner: the main road runs north-south along the west face, the track east-west along the south face. T2's bags
close the veranda's west side and leave its south end open, so the way in is from the south. The user's T4 takes the
T3 south face out and walls the track in: one ring.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-3.30, -11.50) | 3.8 m (open 3.70) | south face (E-W) | onto the track, square in front of the veranda's south end | out 2 HB5 (-5.67 / -0.85, -11.50); in 2 HB3 (-6.78 / 0.19, -11.50) |
| T4 | (-8.60, -15.10) | 3.4 m (open 3.30) | west wall (N-S) | across the track's mouth on the main road | out W4 (-8.60, -13.92), 3 C1 (-15.77 / -16.28 / -16.78), W4 (-18.64); in W4 (-8.60, -18.64), 2 C1 (-12.55 / -12.92) |

### Therisa
A plaza lies south of the house, the road 22 m beyond it (the town's middle is 59 m south). The user's T2 bags leave
the veranda's west door bay open; the user's T4 drops the T3 ring's faces: one ring.

| tier | gate at | width | line | faces / why | cut |
|---|---|---|---|---|---|
| T3 | (-5.00, -16.00) | 3.6 m (open 3.50) | south face (E-W) | across the plaza to the road, in line with the veranda's west side | out 2 HB5 (-7.34 / -2.60, -16.00); in 2 HB3 (-8.39 / -1.61, -16.00) |
| T4 | (-5.20, -24.00) | 3.6 m (open 3.55) | south wall (E-W) | facing the road across the plaza | out 2 W4 (-7.62 / -4.56, -24.00); in 3 C1 (-8.72 / -8.11 / -7.50) |

## For the lead
- **Chalkeia** is the one to watch: the fix covers the clearest gap, a reasoned guess; the list above says what else
  its T4 relies on.
- **Kalochori T3** has one edge of its gate on the lane's old stone wall (low), as the user's ring relies on it.
- Several gates sit next to 1 m pieces (HB1 or CncWall1) where the wall's length left no even fit; 2b may tidy them.

(Written by the towns agent; saved by the lead.)
