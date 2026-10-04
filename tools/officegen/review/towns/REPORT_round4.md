# Towns: round 4 report (answering round3.md)

Script: `tools/officegen/drafting/towns.py` (rewritten; `-a` prints the line audit, `-m -t N` the map of tier N).
Drafts: `tools/officegen/layouts/drafts/<town>.txt`. All 11 pass `tl.check()`, the script's own checks (every run
fitted between its faces, piece middles clear, guard counts on the ladder, closed ring), and a view/field check.
Coordinates below are office model [x, y] (x right, y to the back; the veranda and main door face -x, the front
-y), the same as the drafts and round3/measurements.md.

## Counts (things / guards / statics)

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Agios Dionysios | 6 / 2 / 0 | 17 / 6 / 0 | 63 / 12 / 1 | 127 / 19 / 3 |
| Chalkeia | 6 / 2 / 0 | 17 / 6 / 0 | 52 / 10 / 1 | 97 / 18 / 3 |
| Charkia | 6 / 2 / 0 | 17 / 6 / 0 | 42 / 11 / 1 | 85 / 19 / 3 |
| Kalochori | 6 / 2 / 0 | 17 / 6 / 0 | 41 / 10 / 1 | 83 / 18 / 3 |
| Molos | 6 / 2 / 0 | 17 / 6 / 0 | 49 / 11 / 1 | 101 / 18 / 3 |
| Neochori | 6 / 2 / 0 | 17 / 6 / 0 | 46 / 10 / 1 | 86 / 18 / 3 |
| Panochori | 6 / 2 / 0 | 17 / 6 / 0 | 42 / 10 / 1 | 78 / 18 / 3 |
| Paros | 6 / 2 / 0 | 16 / 6 / 0 | 41 / 10 / 1 | 79 / 18 / 3 |
| Rodopoli | 6 / 2 / 0 | 17 / 6 / 0 | 36 / 11 / 1 | 75 / 19 / 3 |
| Sofia | 6 / 2 / 0 | 17 / 6 / 0 | 43 / 11 / 1 | 95 / 19 / 3 |
| Therisa | 6 / 2 / 0 | 17 / 6 / 0 | 49 / 10 / 1 | 89 / 18 / 3 |

## What changed and why

### The design: tier 3 closes the compound, tier 4 hardens it into a fort
- **Tier 3 is a closed ring.** Each town's compound is now closed on every side by H-barrier runs that tie into
  the neighbouring buildings and old walls. In the towns with walled yards (Kalochori, Panochori, Rodopoli,
  Charkia's garden, Therisa's annexes), the ring is mostly the existing walls, and the runs close the gaps
  between them. The script checks this: a flood walk on a 0.5 m grid from the house, with a man's 0.4 m footprint,
  can't get out through buildings, walls, rocks or our runs. The gate counts as shut. Every town passes at tier 3
  and tier 4. The only way in is the gate. Riflemen stand behind 1-high firing steps in the runs, and the HMG sits
  in a low bagged slot.
- **Tier 4 keeps the same ring and hardens it** (each tier keeps everything of the one before):
  - **2-high faces** toward the roads and main approaches (a second H-barrier dropped on each piece). A piece stays
    1-high wherever a guard fires over it.
  - **Towers at the ring's corners**, inside it. None stands in front of the gate: each flanks it or covers another
    face. Sofia has one tower only. The house fills its corner of the block, so a second one would mean closing the
    main road or the track.
  - **A gated chicane.** In most towns it is a walled box in front of the gate. Its side walls tie into the ring,
    and two staggered baffles leave lanes about 2.4-2.9 m wide, so the way in weaves left and right under the
    gate's guns. Where there's no room for a box, the site's own walls do the job: in Kalochori and Rodopoli two
    baffles in the entry lane, in Neochori a dogleg wall across the plaza.
  - **Obstacle belts in front of the lines, inside the guns' fields.** Razor wire, overlapping 0.45 m and tied into
    the ring, the chicane or buildings, goes on open ground. Two staggered rows of hedgehogs go across each approach
    road.
  - **3 statics.** The tier 3 HMG, plus a GMG and an AT gun, each behind a low bag slot, aimed for the longest
    field (all 15 m or more, most 25-30 m) and covering different approaches.
- **Roads.** The rings stay off the paved cores of the main roads. Where the gate is on a track (Molos, Charkia,
  Panochori, Paros, Sofia), the chicane box stands on the track's verge or across the
  track. That closes the track at tier 4, the way the hedgehog road blocks already did. No box or ring crosses a
  ROAD or MAIN ROAD.

### The line rules (the audit below shows them per run)
- `run()` scans along each run's line, from its clear middle outward, to find the faces it ties into (a building,
  a wall, the house's solid walls or another run). The veranda counts as open, not as a wall to tie into. The run
  then fits pieces exactly into the gap:
  - HBarrier_5 is 5.8 m, HBarrier_3 3.6 m and HBarrier_1 1.4 m. These are the measured lengths. Wall pieces whose
    size is uncertain (HBarrierWall6, which round 3 caught clipping a Rodopoli house) are no longer used.
  - Pieces overlap each other by 0.3-0.6 m, at their ends only.
  - A piece overlaps a building, wall or the house by 0.3-0.4 m. That keeps 0.6 m off its end clear even with
    townlib.CLASSES' longer HB5/HB1 sizes.
  - Where an oblique face makes the gap impossible to fit, the run is retried up to 0.5 m to either side.
  - Firing steps and slots may slide up to 1 m to fit. The gate slides up to 0.5 m, and only if nothing else fits.
- The middle of every piece, wire belt and gate must clear buildings, walls, rocks and the house. The middle is
  0.6 m in from each end and half the piece's depth, using its longest known length and, for a gate, the swing of
  its leaf. In round 3 the drafting script let barriers overlap walls anywhere. That was the cause of every "clips
  mid-piece" line.

### Each measured problem in round3.md
- **Pipe-fence gate inside the office** (every town). Gone. The side door is barricaded with a BagFence_Long on the
  ground outside it, at [6.25, 5.6] facing out. In Paros the neighbour's wall closes the door, so no bags go there.
  The one pipe gate left is the 4 m gate in Kalochori's lane mouth, at about [-6.75, -14], away from the house: the
  lane is 4.5 m wide, too narrow for the bar gate.
- **Blind interior rifleman [3.8, -5.3]** (Agios Dionysios, Kalochori). This was the ground-floor east-window post,
  and it has been removed. House posts are now the three upstairs east windows and the two veranda posts, each used
  only where the view from it runs 4 m or more. The script's sight now counts walls as well as buildings, rocks,
  trees and our tall pieces. Round 3's sight ignored walls, which explains most of the blind and blocked lines.
- **Charkia rifleman [10.7, 4.3]; Paros marksman [14.5, 11.8] and MG gunner [11.9, 9.2]; Kalochori MG gunner
  [2.6, -13] pushed off.** All three posts are gone. Every outside guard now stands 1.3 m behind a run piece or in
  a nest, on a spot checked clear and with 4 m or more of view. Tower men use the measured TOWER_SPOTS.
- **Blocked statics** (Kalochori HMG/GMG, Rodopoli HMG/GMG, Neochori AT, Therisa AT, Panochori GMG). All new
  positions:
  - Each static stands 2.1-2.7 m behind a bag slot in a run.
  - Its facing is chosen within the slot's opening for the longest field. For a gun, any H-barrier blocks the
    field; it fires only over bags.
  - Every field is 15 m or more (see each town's line below).
  - Statics stand on ground level to 0.45 m over their footprint.
- **AT floating.** Statics still stand on level ground. If it still reads 0.3-0.7 m, it is the tripod's shape, as
  round 3 suspected.
- **Clipping mid-piece:**
  - Kalochori's HBarrier_1s into stone walls and its bar gate. All runs are new, fitted between the faces with the
    middle check above. The yard-wall bar gate is gone.
  - Charkia/Chalkeia stone walls and wire fence; Therisa and Molos city walls; Agios Dionysios tin wall (including
    the T2 nest's short bags, now at [-8.5, -4.6] clear of it); Rodopoli house; Paros/Panochori office. Same fix:
    new runs with the middle check, and pieces stay 0.2-0.3 m off the house in their middles.
  - Neochori tower in a city wall. Towers now use a 4.8 x 7.2 m footprint, taken from the screenshots (CLASSES says
    3.5), and must clear walls.

## What to check in the game
1. **Closure.** From the street side of each tier 3 and tier 4 ring, the only way in should be the gate. The flood
   check trusts the probe's footprints. Watch for:
   - gaps under 0.5 m that the check treats as shut: Paros, where the SW run's south face is 0.2 m off the south
     house; Kalochori, where the 4 m pipe gate stops 0.1-0.2 m short of the lane walls;
   - enterable neighbour houses, which a man could walk through door to door;
   - Kalochori's lane north end, closed with 0.9 m sandbags (the AT gun fires over them). Can a man step over?
2. **Clips at the ties.** Every run's ends overlap a building or wall by 0.3-0.4 m by design. The in-game middle
   check shouldn't flag them. If it does, the lead's check measures more than 0.6 m off the end.
3. **The real footprint of Land_BagBunker_Tower_F** (my guess is 4.8 x 7.2 m; measured bbox 6.4 x 9.8) and whether
   its men can see from towers that stand on a slope. Agios Dionysios and Chalkeia have up to 1.2 m of slope over
   the footprint, and a tower stands upright on its centre.
4. **Chicane lanes.** Can a man walk the box: gate, first lane, second lane, out? Lanes are about 2.4 m between
   baffles and 2.9 m at the open ends. Check the dogleg in Neochori and the lane baffles in Kalochori and Rodopoli.
5. **The bar gate.** Does its arm span the 6 m opening without fouling the pieces either side? The measured bbox
   is 9.7 m long.
6. **Stacked pieces.** Do the second H-barriers sit on the first? The drop is from ground + 1.7 m.
7. **Statics.** Fields from the [x, y] below, and whether a gun 2.1-2.7 m behind a 0.9 m bag slot fires out clear.
   The H-barriers either side are at least 1.5 m off its line of fire.
8. **Views.** Guards behind 1-high H-barrier firing steps (as in round 3), the T2 nests now inside the rings, the
   chicane guards in Sofia, and the gate sentries.

## Research drawn on (background knowledge; no web fetch this round)
- Entry control points: a serpentine or chicane of staggered barriers in front of the gate slows a vehicle and
  makes it turn under the gate's guns, with a sentry at the gate (US UFC 4-022-01 *Entry Control Facilities* /
  ATP 3-37.34 ideas).
- Perimeters: HESCO/H-barrier lines continuous and tied into hard structures, built 2-high toward the main threat,
  with firing steps and bagged weapon slots in the line.
- Obstacles: wire and hedgehog belts are only worth anything inside the fields of fire of the guns (ATP 3-90.8
  countermobility, "obstacles covered by fire").
- Urban strongpoints: use the existing buildings and walls as the perimeter, close the gaps between them, and put
  overwatch at the corners.

## The line audit (per town)
Columns:
- **length**: the drawn run.
- **gap**: face to face, i.e. what the pieces must close. For a corner end, the face is the cross run's outer face.
  For a free end (chicane baffles, wire), it is the point itself.
- **end overlaps**: how far the first and last pieces pass the faces. On tie ends they are 0.3-0.4 m. Against a
  gate, a value down to -0.35 m is a slot narrower than a man.
- **joints**: piece-to-piece overlaps, 0.3-0.6 m (a gate's opening is about 0).

Wire belts with free ends overhang their points. Where a run ends free next to a building, it is noted in the
town's description in the script.

### Agios Dionysios

No road within 60 m: open ground south and east, a big house north-west, a tin fence running west from the veranda's north end and another north from the house's north-east corner. The ring: four faces on the open ground, the west and north faces tied into the two tin fences where they cross them. The way in: from the west, square onto the veranda's door bay, the nest covering the gate from inside.

Statics: T3 hmg at [-1.2, -13.6] facing 150 (clear 23 m); T4 at at [11.9, -6.0] facing 80 (clear 30 m); T4 gmg at [1.0, 9.9] facing 360 (clear 30 m)
Towers (T4): [-8.6, -11.4] facing 180; [10.4, 7.0] facing 0
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west_s | T3 | 16.0 | 15.13 | corner/tie | 3: HB5 + GATE + HB3 | 15.4 | -0.06 / 0.35 | -0.02, -0.00 |
| south | T3 | 27.0 | 26.98 | tie/corner | 8: HB5 + HB5 + bags(slot) + HB3 + HB1 + HB3(fire) + HB3 + HB3 | 30.4 | 0.31 / 0.18 | 0.34, 0.34, 0.43, 0.43, 0.43, 0.47, 0.47 |
| east | T3 | 28.0 | 27.98 | tie/corner | 9: HB3 + HB3 + HB1 + HB1 + bags(slot) + HB5 + HB3(fire) + HB5 + HB3 | 31.8 | 0.37 / -0.32 | 0.51, 0.51, 0.51, 0.51, 0.55, 0.55, 0.32, 0.32 |
| north_e | T3 | 10.0 | 7.90 | tie/tie | 4: HB3 + HB3 + HB1 + HB1 | 10.0 | 0.35 / 0.35 | 0.46, 0.46, 0.46 |
| north_w | T3 | 19.0 | 18.68 | tie/corner | 9: HB1 + HB1 + HB1 + bags(slot) + HB3 + HB3(fire) + HB3 + HB3 + HB1 | 23.0 | 0.37 / 0.14 | 0.51, 0.51, 0.51, 0.45, 0.45, 0.46, 0.46, 0.46 |
| west_n | T3 | 15.0 | 12.10 | tie/tie | 6: HB1 + HB1 + HB1 + HB1 + HB3(fire) + HB5 | 15.0 | 0.36 / 0.3 | 0.48, 0.48, 0.48, 0.48, 0.30 |
| gate_l | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_r | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_b1 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| gate_b2 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| wire_s | T4 | 37.0 | 37.00 | free/free | 5: wire + wire + wire + wire + wire | 40.0 | 0.6 / 0.6 | 0.45, 0.45, 0.45, 0.45 |
| wire_e | T4 | 36.5 | 36.50 | free/free | 5: wire + wire + wire + wire + wire | 40.0 | 0.85 / 0.85 | 0.45, 0.45, 0.45, 0.45 |
| wire_w | T4 | 11.5 | 7.10 | free/tie | 1: wire | 8.0 | 0.55 / 0.35 |  |
| wire_nw | T4 | 16.5 | 13.10 | free/tie | 2: wire + wire | 16.0 | 2.1 / 0.35 | 0.45 |
| wire_n | T4 | 19.0 | 15.90 | free/tie | 2: wire + wire | 16.0 | -0.7 / 0.35 | 0.45 |
| wire_ne | T4 | 17.0 | 13.75 | tie/free | 2: wire + wire | 16.0 | 0.35 / 1.45 | 0.45 |

### Chalkeia

A dead-end track runs down from the north just west of the veranda and stops at a shop and a garage south- west; an annexe abuts the house's north side and a ruin closes the north-east; a house abuts the east side's southern half, an old stone wall runs on north of it; open ground lies south and west. The ring takes in the dead end of the track: the north face across the track from the annexe, the west face down the open ground to the shop, the south face from the shop across the open ground to the old wall south of the east house (a short run closing the gap between them), and a run across the east yard from the ruin to the stone wall. The guns look up the track (the long field). The way in: from the open ground west, through the west gate.

Statics: T3 hmg at [-10.0, 9.9] facing 350 (clear 30 m); T4 gmg at [-9.0, -16.9] facing 190 (clear 30 m); T4 at at [-6.7, 9.9] facing 345 (clear 30 m)
Towers (T4): [-13.6, 7.3] facing 0; [9.8, 4.4] facing 0
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 25.0 | 24.78 | tie/corner | 9: HB3 + HB3 + HB1 + HB1 + HB1 + GATE + HB3 + HB3 + HB3 | 28.2 | 0.37 / 0.05 | 0.52, 0.52, 0.52, 0.52, 0.02, -0.00, 0.44, 0.44 |
| north | T3 | 15.0 | 11.55 | tie/tie | 7: HB3 + HB1 + HB1 + bags(slot) + HB1 + bags(slot) + HB1 | 15.2 | 0.36 / 0.34 | 0.48, 0.48, 0.48, 0.55, 0.55, 0.41 |
| south | T3 | 20.0 | 19.95 | tie/tie | 6: HB5 + bags(slot) + HB3 + HB3 + HB3(fire) + HB3 | 23.2 | 0.39 / 0.35 | 0.56, 0.50, 0.50, 0.50, 0.45 |
| se | T3 | 7.5 | 2.20 | tie/tie | 3: HB1 + HB1 + HB1 | 4.2 | 0.4 / 0.4 | 0.60, 0.60 |
| east | T3 | 14.0 | 8.85 | tie/tie | 5: HB1 + HB1 + HB3(fire) + HB3 + HB1 | 11.4 | 0.34 / 0.37 | 0.41, 0.41, 0.51, 0.51 |
| gate_l | T4 | 8.9 | 8.46 | tie/free | 2: HB5 + HB3 | 9.4 | 0.36 / 0.08 | 0.49 |
| gate_r | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_b1 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| gate_b2 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| wire_w_n | T4 | 10.5 | 10.10 | free/tie | 1: wire | 8.0 | -2.45 / 0.35 |  |
| wire_s | T4 | 18.0 | 18.50 | free/tie | 3: wire + wire + wire | 24.0 | 4.25 / 0.35 | 0.45, 0.45 |

### Charkia

Between tracks (north-west, west and south-east); a long garage close north-west, its corner at the house's north-west corner; an old walled garden north-east of the house (stone walls from the house's south-east corner round to a wire fence ending north of the house). Open ground west and south. The ring: the garden's own walls are its east half; a north run from the garage to the garden fence; the west face from the garage down the open ground, the south face, and a run from its corner into the garden wall at the house's south- east corner. The way in: from the west, square onto the door bay; the garage closes the chicane's north side.

Statics: T3 hmg at [-3.1, -12.4] facing 180 (clear 30 m); T4 at at [1.0, -12.4] facing 190 (clear 30 m); T4 gmg at [2.2, -9.9] facing 80 (clear 30 m)
Towers (T4): [-7.9, -11.1] facing 270; [11.0, 12.0] facing 0
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 20.5 | 16.28 | corner/tie | 4: HB3 + HB3 + GATE + HB3(fire) | 16.8 | -0.21 / 0.4 | 0.36, -0.03, 0.00 |
| south | T3 | 15.5 | 15.48 | tie/corner | 6: HB5 + HB3 + bags(slot) + HB1 + bags(slot) + HB1 | 18.2 | 0.4 / -0.31 | 0.60, 0.60, 0.55, 0.55, 0.33 |
| se | T3 | 9.4 | 5.90 | tie/tie | 5: HB1 + HB1 + HB1 + bags(slot) + HB1 | 8.6 | 0.38 / 0.32 | 0.54, 0.54, 0.54, 0.37 |
| north | T3 | 11.0 | 10.00 | tie/tie | 4: HB3 + HB3 + HB1 + HB3(fire) | 12.2 | 0.37 / 0.35 | 0.50, 0.50, 0.50 |
| gate_l | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_b1 | T4 | 5.9 | 5.36 | tie/free | 1: HB5 | 5.8 | 0.36 / 0.08 |  |
| gate_b2 | T4 | 5.9 | 3.16 | tie/free | 1: HB3 | 3.6 | 0.36 / 0.08 |  |
| wire_w_s | T4 | 9.0 | 7.10 | free/tie | 1: wire | 8.0 | 0.55 / 0.35 |  |
| wire_s | T4 | 15.0 | 15.00 | free/free | 2: wire + wire | 16.0 | 0.28 / 0.27 | 0.45 |

### Kalochori

The main road runs 7 m south of the house's walled front yard (old concrete walls round it, no gateway); a lane runs north-south west of the house between it and an old stone wall, from the road up to a narrow gap between two houses north; a walled yard east (stone walls round it) opens south onto the road; houses and a shed close the north. The ring is mostly the old walls: the lane's mouth on the road gets the gate (a 4 m gate: the lane is 4.5 m wide), the lane's north end is closed with sandbags (the AT gun fires up the north lane over them), the gaps either side of the north shed and the east yard's south side with H-barrier runs. The way in: from the road up the lane onto the veranda, the nest looking down the lane at the gate; at tier 4 two baffles in the lane make it the chicane.

Statics: T3 hmg at [11.3, -9.9] facing 180 (clear 30 m); T4 gmg at [7.6, -9.9] facing 170 (clear 30 m); T4 at at [-7.4, 6.4] facing 0 (clear 30 m)
Towers (T4): [11.0, -4.5] facing 180; [0.1, -11.5] facing 90
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| lane_s | T3 | 7.0 | 4.30 | tie/tie | 1: GATE(4 m) | 4.0 | -0.1 / -0.2 |  |
| lane_n | T3 | 5.5 | 3.85 | tie/tie | 2: bags + bags(short) | 4.8 | 0.31 / 0.31 | 0.33 |
| north | T3 | 9.0 | 5.35 | tie/tie | 4: HB1 + HB1 + HB3(fire) + HB1 | 7.8 | 0.4 / 0.36 | 0.60, 0.60, 0.49 |
| ne | T3 | 10.0 | 6.50 | tie/tie | 5: HB3 + HB1 + HB1 + HB1 + HB1 | 9.2 | 0.36 / 0.36 | 0.49, 0.49, 0.49, 0.49 |
| east_s | T3 | 11.0 | 9.90 | tie/tie | 7: HB1 + HB1 + bags(slot) + HB1 + bags(slot) + HB1 + HB1 | 13.0 | 0.39 / 0.3 | 0.56, 0.56, 0.35, 0.35, 0.30, 0.30 |
| chicane_1 | T4 | 2.9 | 2.13 | tie/free | 2: HB1 + HB1 | 2.8 | 0.34 / -0.08 | 0.41 |
| chicane_2 | T4 | 2.8 | 2.15 | tie/free | 2: HB1 + HB1 | 2.8 | 0.33 / -0.09 | 0.40 |
| wire_s | T4 | 18.5 | 18.50 | free/free | 3: wire + wire + wire | 24.0 | 2.3 / 2.3 | 0.45, 0.45 |

### Molos

A track runs north-south 6 m west of the veranda and a big road east-west 14 m north; a shop abuts the house's front (south); old city walls run east from it to the chapel's corner. The ring: the west face along the track from the shop, the north face along the big road, the east face down the yard to the city wall. The way in: off the west track onto the veranda.

Statics: T3 hmg at [3.2, 11.2] facing 355 (clear 30 m); T4 at at [7.1, 10.7] facing 350 (clear 30 m); T4 gmg at [15.6, 6.6] facing 60 (clear 30 m)
Towers (T4): [-3.0, 10.3] facing 270; [12.6, -3.5] facing 135
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 23.1 | 22.48 | tie/corner | 6: HB1 + GATE + HB3 + HB3(fire) + HB5 + HB3 | 24.0 | 0.37 / -0.07 | 0.02, -0.01, 0.41, 0.40, 0.40 |
| north | T3 | 25.7 | 25.57 | tie/corner | 11: HB3 + HB3 + HB1 + HB1 + HB1 + bags(slot) + HB1 + HB1 + bags(slot) + HB5 + HB5 | 31.8 | 0.37 / 0.43 | 0.51, 0.51, 0.51, 0.51, 0.51, 0.60, 0.60, 0.60, 0.55, 0.55 |
| east | T3 | 23.5 | 18.60 | tie/tie | 9: HB1 + HB1 + bags(slot) + HB3 + HB3 + HB1 + HB3(fire) + HB3 + HB1 | 23.0 | 0.4 / 0.37 | 0.60, 0.60, 0.35, 0.35, 0.35, 0.35, 0.51, 0.51 |
| gate_l | T4 | 8.9 | 7.36 | tie/free | 3: HB3 + HB3 + HB1 | 8.6 | 0.35 / -0.0 | 0.45, 0.45 |
| gate_r | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_b1 | T4 | 5.9 | 5.36 | tie/free | 1: HB5 | 5.8 | 0.36 / 0.08 |  |
| gate_b2 | T4 | 5.9 | 5.36 | tie/free | 1: HB5 | 5.8 | 0.36 / 0.08 |  |

### Neochori

The main road runs north-south right along the veranda (no room for a gate box on it); a big garage and a house fill the east; a small house closes the south yard's south side, an old city wall runs north from it beside the road; old concrete garden walls run east-west 16 m north, leaving a small plaza off the road north- west of the house. The ring: the west face along the road from the south house to the plaza, the north face to the garage, a run from the south house to the garage's corner across the south-east gap. The way in: off the road onto the plaza, through the north gate; at tier 4 a wall across the plaza makes it a dogleg passage. The guns fire south-east through the gap between the south house and the garage, and up the road north.

Statics: T3 hmg at [6.9, -15.0] facing 140 (clear 27 m); T4 at at [1.6, 11.9] facing 310 (clear 22 m); T4 gmg at [8.4, -11.3] facing 140 (clear 25 m)
Towers (T4): [-0.4, -17.5] facing 180; [6.9, 10.5] facing 270
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 38.0 | 37.43 | tie/corner | 9: HB5 + HB5 + HB5 + HB5 + HB5 + HB5 + HB3(fire) + HB1 + HB1 | 41.2 | 0.35 / -0.08 | 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.40, 0.40 |
| north | T3 | 19.7 | 19.73 | tie/corner | 4: GATE + bags(slot) + HB5 + HB5 | 20.6 | 0.35 / -0.07 | -0.20, 0.40, 0.40 |
| ne | T3 | 8.0 | 3.90 | tie/tie | 2: HB3 + HB1 | 5.0 | 0.34 / 0.34 | 0.42 |
| se | T3 | 17.8 | 14.95 | tie/tie | 9: HB3 + HB1 + HB1 + bags(slot) + HB1 + HB1 + bags(slot) + HB3 + HB1 | 20.2 | 0.39 / 0.37 | 0.56, 0.56, 0.56, 0.60, 0.60, 0.60, 0.50, 0.50 |
| plaza | T4 | 4.6 | 4.10 | tie/free | 2: HB3 + HB1 | 5.0 | 0.36 / 0.06 | 0.48 |
| lane_e | T4 | 4.5 | 1.40 | tie/tie | 2: HB1 + HB1 | 2.8 | 0.4 / 0.4 | 0.60 |
| wire_se | T4 | 16.3 | 17.63 | free/tie | 2: wire + wire | 16.0 | -2.43 / 0.35 | 0.45 |

### Panochori

A track runs north-south right along the veranda; a house abuts the north side, a big house stands south- west; old stone walls close a yard east of the house and south of it, open only at its south-east corner and at the north end of the east yard. The ring: the west face along the track between the two houses (the gate on the door bay, its chicane on the track), a short run into the north house, and runs closing the east yard's north end and the south-east corner. The guns fire east out of the south-east corner and north out of the east yard's north end.

Statics: T3 hmg at [11.9, -10.0] facing 95 (clear 25 m); T4 gmg at [9.7, 14.9] facing 0 (clear 30 m); T4 at at [11.9, -13.0] facing 95 (clear 30 m)
Towers (T4): [-0.5, -10.6] facing 270; [9.1, 3.8] facing 0
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 19.5 | 22.13 | tie/corner | 8: HB3 + HB1 + HB1 + HB1 + HB1 + GATE + HB5 + HB3 | 24.6 | 0.37 / -0.28 | 0.51, 0.51, 0.51, 0.51, 0.02, -0.04, 0.34 |
| nw | T3 | 5.2 | 2.65 | tie/tie | 3: HB1 + HB1 + HB1 | 4.2 | 0.34 / 0.34 | 0.43, 0.43 |
| north | T3 | 8.0 | 5.25 | tie/tie | 4: HB1 + HB1 + bags(slot) + HB1 | 7.2 | 0.36 / 0.31 | 0.47, 0.47, 0.34 |
| se | T3 | 10.5 | 7.20 | tie/tie | 5: HB1 + bags(slot) + bags(slot) + HB1 + HB1 | 10.2 | 0.4 / 0.4 | 0.60, 0.40, 0.60, 0.60 |
| gate_l | T4 | 8.9 | 8.46 | tie/free | 2: HB5 + HB3 | 9.4 | 0.36 / 0.08 | 0.49 |
| gate_r | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_b1 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| gate_b2 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| wire_e | T4 | 7.5 | 6.00 | tie/free | 1: wire | 8.0 | 0.35 / 1.65 |  |

### Paros

A track runs north-south 7 m west of the veranda; houses abut the east side and close the south; a big house closes the north beyond a yard that opens east; an old city wall runs from the house's north-west corner to the big house. The ring: the west face along the track (the gate on the door bay, its chicane on the track), a short run from its corner into the south house, one from its north corner into the city wall, and one closing the north yard's open east side between the east house and the big house. Towers at the north yard's two corners.

Statics: T3 hmg at [11.9, 7.3] facing 90 (clear 30 m); T4 at at [-7.9, -7.0] facing 255 (clear 30 m); T4 gmg at [11.3, 9.5] facing 90 (clear 27 m)
Towers (T4): [0.7, 10.5] facing 270; [8.5, 13.2] facing 270
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 24.0 | 25.76 | corner/corner | 10: HB3 + bags(slot) + HB1 + HB1 + HB1 + GATE + HB1 + HB1 + HB3(fire) + HB5 | 29.0 | -0.15 / 0.23 | 0.37, 0.55, 0.55, 0.55, 0.04, -0.04, 0.32, 0.32, 0.49 |
| sw | T3 | 5.5 | 4.60 | tie/free | 2: HB3 + HB1 | 5.0 | 0.31 / -0.24 | 0.33 |
| nw | T3 | 6.0 | 3.55 | tie/tie | 4: HB1 + HB1 + HB1 + HB1 | 5.6 | 0.35 / 0.35 | 0.45, 0.45, 0.45 |
| ne | T3 | 13.5 | 13.15 | tie/tie | 4: bags(slot) + bags(slot) + HB5 + HB3 | 15.4 | 0.3 / 0.39 | 0.40, 0.58, 0.58 |
| gate_l | T4 | 8.9 | 8.46 | tie/free | 2: HB5 + HB3 | 9.4 | 0.36 / 0.08 | 0.49 |
| gate_r | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_b1 | T4 | 5.9 | 5.36 | tie/free | 1: HB5 | 5.8 | 0.36 / 0.08 |  |
| gate_b2 | T4 | 5.9 | 5.36 | tie/free | 1: HB5 | 5.8 | 0.36 / 0.08 |  |
| wire_e | T4 | 6.5 | 6.50 | free/free | 1: wire | 8.0 | 0.75 / 0.75 |  |

### Rodopoli

An annexe abuts the house's north side and houses its south side; a big yard west of the house is walled in by old city walls (west and north) and a big house (south-west), open only at a 3 m gap in its south wall and at its north-east corner, where it runs into a lane behind the house; the lane runs north-south between the house and a long concrete wall along the east track, open at both ends. The ring is the old walls: the south gap, the lane's south end (the gate, onto the south track) and its north end are closed. The way in is long: through the gate, up the lane (at tier 4 two baffles make it a chicane), round the annexe into the yard and onto the veranda.

Statics: T3 hmg at [7.4, -10.9] facing 160 (clear 30 m); T4 gmg at [-11.7, 24.9] facing 360 (clear 30 m); T4 at at [8.5, 24.1] facing 10 (clear 30 m)
Towers (T4): [-16.0, -12.5] facing 180; [9.8, 9.5] facing 90
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| south_gap | T3 | 7.0 | 2.90 | tie/tie | 1: HB3 | 3.6 | 0.35 / 0.35 |  |
| north_gap | T3 | 7.5 | 5.05 | tie/tie | 4: HB1 + bags(slot) + HB1 + HB1 | 7.2 | 0.35 / 0.36 | 0.45, 0.49, 0.49 |
| lane_s | T3 | 12.0 | 9.25 | tie/tie | 2: bags(slot) + GATE | 9.0 | 0.3 / -0.25 | -0.30 |
| lane_n | T3 | 11.5 | 9.65 | tie/tie | 6: HB1 + HB1 + bags(slot) + HB3(fire) + HB1 + HB1 | 12.2 | 0.34 / 0.31 | 0.41, 0.41, 0.40, 0.34, 0.34 |
| chicane_1 | T4 | 6.4 | 5.80 | tie/free | 1: HB5 | 5.8 | 0.3 / -0.3 |  |
| chicane_2 | T4 | 6.8 | 6.20 | tie/free | 2: HB3 + HB3 | 7.2 | 0.37 / 0.12 | 0.51 |

### Sofia

On a corner: the main road runs north-south 9 m west of the house and a track east-west 11 m south of it; a big house abuts the north side, another the east side's southern half; a yard east of the house is closed by houses all round but for a 2 m gap at its south-east corner. The house fills its corner of the block, so the ring hugs it on the road sides: the west face along the main road from the north house, the south face along the track (the gate in it, its chicane on the track), a short run into the east house and one closing the east yard's gap. One tower, in the east yard (no room for a second without closing the road or track).

Statics: T3 hmg at [2.9, -9.4] facing 180 (clear 23 m); T4 gmg at [-6.5, -3.9] facing 250 (clear 26 m); T4 at at [-6.5, -6.1] facing 255 (clear 25 m)
Towers (T4): [10.1, 4.0] facing 90
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| west | T3 | 20.5 | 19.98 | tie/corner | 8: HB3 + HB3 + HB1 + HB3(fire) + bags(slot) + bags(slot) + HB3 + HB1 | 23.2 | 0.32 / 0.11 | 0.36, 0.36, 0.36, 0.40, 0.40, 0.45, 0.45 |
| south | T3 | 14.1 | 14.08 | tie/corner | 7: GATE + HB1 + HB1 + HB1 + bags(slot) + HB1 + HB1 | 16.0 | -0.3 / -0.01 | 0.00, 0.46, 0.46, 0.47, 0.42, 0.42 |
| se | T3 | 4.0 | 1.70 | tie/tie | 2: HB1 + HB1 | 2.8 | 0.34 / 0.34 | 0.42 |
| east_gap | T3 | 6.0 | 2.70 | tie/tie | 3: HB1 + HB1 + HB1 | 4.2 | 0.34 / 0.34 | 0.41, 0.41 |
| gate_l | T4 | 8.9 | 8.31 | tie/free | 2: HB5 + HB3 | 9.4 | 0.38 / 0.17 | 0.54 |
| gate_r | T4 | 8.9 | 8.46 | tie/free | 2: HB5 + HB3 | 9.4 | 0.36 / 0.08 | 0.49 |
| gate_b1 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| gate_b2 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| wire_e | T4 | 8.0 | 8.00 | free/free | 1: wire | 8.0 | 0.0 / 0.0 |  |

### Therisa

No road within 25 m: annexes abut the house's west and east sides (a 2.7 m passage between the west one and the veranda, leading to a walled garden north-west), houses close the north beyond a yard that opens east; a shop and an annexe stand south-west, old city walls run south-east; open ground (a plaza) lies south, the road 30 m beyond it. The ring: the south face across the plaza from the south-west annexe to a short run into the city wall, and a run closing the north yard's east side. Towers at the south face's corners; the gate on the veranda's south end, its chicane out on the plaza.

Statics: T3 hmg at [7.4, -13.9] facing 180 (clear 30 m); T4 gmg at [10.1, -13.9] facing 170 (clear 30 m); T4 at at [13.4, 8.2] facing 90 (clear 30 m)
Towers (T4): [-10.0, -11.3] facing 270; [15.4, -12.3] facing 90
Closed at T3 and T4: yes (a flood walk from the house finds no way out; the gate counts as shut)

| run | tier | length | gap (face to face) | ends | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|---|
| south | T3 | 38.0 | 37.28 | tie/corner | 12: HB3 + HB3(fire) + HB3 + GATE + HB1 + HB1 + HB1 + HB3(fire) + bags(slot) + bags(slot) + HB5 + HB5 | 42.2 | 0.4 / 0.3 | 0.60, 0.41, -0.01, 0.02, 0.50, 0.50, 0.49, 0.40, 0.30, 0.51, 0.51 |
| se | T3 | 7.0 | 3.25 | tie/tie | 4: HB1 + HB1 + HB1 + HB1 | 5.6 | 0.38 / 0.38 | 0.53, 0.53, 0.53 |
| sw | T3 | 6.0 | 2.25 | tie/tie | 3: HB1 + HB1 + HB1 | 4.2 | 0.39 / 0.39 | 0.58, 0.58 |
| nw_gap | T3 | 8.0 | 3.80 | tie/tie | 2: HB3 + HB1 | 5.0 | 0.36 / 0.36 | 0.48 |
| n_e | T3 | 13.0 | 9.45 | tie/tie | 6: HB1 + HB1 + HB3(fire) + bags(slot) + HB1 + HB1 | 12.2 | 0.38 / 0.31 | 0.54, 0.54, 0.30, 0.34, 0.34 |
| gate_l | T4 | 8.9 | 8.41 | tie/free | 2: HB5 + HB3 | 9.4 | 0.37 / 0.11 | 0.51 |
| gate_r | T4 | 8.9 | 8.46 | tie/free | 2: HB5 + HB3 | 9.4 | 0.36 / 0.08 | 0.49 |
| gate_b1 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| gate_b2 | T4 | 4.9 | 4.36 | tie/free | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.40 |
| wire_w | T4 | 8.0 | 7.40 | tie/free | 1: wire | 8.0 | 0.35 / 0.25 |  |
| wire_e | T4 | 7.0 | 7.00 | free/free | 1: wire | 8.0 | 0.5 / 0.5 |  |
