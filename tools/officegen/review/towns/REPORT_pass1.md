# Towns: pass 1 report (walls only)

Script: `tools/officegen/drafting/towns.py` (`-a` prints the line audit below, `-m -t N` the map of tier N). Drafts:
`tools/officegen/layouts/drafts/<town>.txt`. All 11 drafts pass `tl.check()`, with one exception: its "2 guards a tier" line is left out, because
pass 1 has no guards (the script filters that one line; every other check stands). They also pass the script's own checks:

- every run is fitted between its faces;
- piece middles are clear of buildings, walls, rocks, the house and a road's paved core;
- T3 and T4 are closed, and the T4 outer ring alone is closed too (walked with the T3 ring left out).

Coordinates are office model [x, y] (x right, y to the back; the veranda faces -x, the front -y), the same as in the
drafts and the measurements. These towns have 4 tiers, so there is no T5.

## Counts (things per tier; each tier keeps the one below)

| Town | T1 | T2 (sandbags) | T3 (+ H-barriers) | T4 (+ high walls) |
|---|---|---|---|---|
| Agios Dionysios | 0 | 5 (2 long, 3 short) | 33 (+28 H-barriers: 12x5, 14x3, 2x1) | 76 (+42 Mil_WallBig_4m, 1 CncWall1) |
| Chalkeia | 0 | 4 (2 long, 2 short) | 23 (+19 H-barriers: 12x5, 4x3, 3x1) | 61 (+29 Mil_WallBig_4m, 9 CncWall1) |
| Charkia | 0 | 4 (1 long, 3 short) | 24 (+20 H-barriers: 7x5, 5x3, 8x1) | 67 (+41 Mil_WallBig_4m, 2 CncWall1) |
| Kalochori | 0 | 5 (2 long, 3 short) | 23 (+18 H-barriers: 9x5, 3x3, 6x1) | 50 (+22 Mil_WallBig_4m, 5 CncWall1) |
| Molos | 0 | 5 (2 long, 3 short) | 19 (+14 H-barriers: 10x5, 4x3, 0x1) | 54 (+31 Mil_WallBig_4m, 4 CncWall1) |
| Neochori | 0 | 5 (2 long, 3 short) | 22 (+17 H-barriers: 11x5, 5x3, 1x1) | 47 (+13 Mil_WallBig_4m, 5 CncWall1, 7 H-barriers stacked on the road face) |
| Panochori | 0 | 5 (2 long, 3 short) | 23 (+18 H-barriers: 9x5, 5x3, 4x1) | 50 (+24 Mil_WallBig_4m, 3 CncWall1) |
| Paros | 0 | 3 (1 long, 2 short) | 15 (+12 H-barriers: 5x5, 6x3, 1x1) | 33 (+16 Mil_WallBig_4m, 2 CncWall1) |
| Rodopoli | 0 | 5 (2 long, 3 short) | 17 (+12 H-barriers: 9x5, 2x3, 1x1) | 63 (+34 Mil_WallBig_4m, 12 CncWall1) |
| Sofia | 0 | 4 (1 long, 3 short) | 16 (+12 H-barriers: 5x5, 2x3, 5x1) | 42 (+21 Mil_WallBig_4m, 1 CncWall1, 4 H-barriers stacked on the road face) |
| Therisa | 0 | 4 (1 long, 3 short) | 21 (+17 H-barriers: 6x5, 7x3, 4x1) | 61 (+32 Mil_WallBig_4m, 8 CncWall1) |

## What changed

- **Everything but walls is out:** guards, statics, towers, wire, hedgehogs, gates (the T3 gates are now plain
  H-barrier runs), the flag, the furniture, the T2 yard nests and the chicanes.
- **T1** is empty.
- **T2** is sandbags on the house only:
  - the veranda's north bay and south end (on the veranda floor, as before);
  - the side door, bagged on the ground 1.85 m out from it (round 4's 1.35 m cut into the office at Agios Dionysios
    and Chalkeia; this is the 0.5 m move the critique asked for);
  - the ground-floor window, in the east wall, bagged 1.5 m out.

  Where a neighbour stands against the wall there is no room, and the bags are left out (Paros: side door and
  window; Chalkeia, Sofia, Therisa: window). Charkia's window has none because its outer wall stands there.
- **T3** is a closed H-barrier ring with no opening (1-high).
- **T4** adds the outer high-wall ring: `Land_Mil_WallBig_4m_F`, with `Land_CncWall1_F` 1 m sections where 4 m walls can't
  fit a gap exactly. I added CncWall1/CncWall4 to `townlib.CLASSES` with guessed sizes (1.0/4.0 x 0.6 m); please send
  their real boxes. Neochori and Sofia also stack their road face 2-high (see below).

### The wall rules as the script applies them

**Real walls only** (`real_wall()`). Only the city walls (`city_*`, `city2_*`, their pillars), canal walls and
pipe-concrete walls count as barriers. They have a 4.2 m bounding box, about 2.5 m above the ground.

These don't count:

- stone walls and stone pillars (2.6 m box: about 1.3 m high);
- low concrete garden walls;
- tin walls (3 m box: under 2 m);
- wire and pipe fences;
- every broken "d" piece (`*_8md`, `*_pillard`).

The ties and the closure walk ignore these. A ring that meets one either lines it, crosses it square, or goes round
its end. This reworked the rings at Agios Dionysios, Chalkeia, Charkia, Kalochori, Panochori, Paros, Rodopoli and
Therisa. Kalochori's old yard walls are all low, as the critique suspected.

**Crossing a low wall.** Where a ring must cross a fence or a low wall, the runs on either side end inside it (just
past its middle line), so they overlap each other 0.16-0.32 m through it. The crossings are square, or close to it,
and the fence stays out of each piece's middle. The audit shows these ends as "through ... (low)".

**Overlaps.** Pieces overlap each other 0.3-0.6 m at their ends only. Ends tie in as follows:

| tie | overlap |
|---|---|
| H-barrier into a building or wall | 0.3-0.4 m |
| 4 m wall into a building or wall | 0.3-0.5 m (it is 4.1 m measured, so 0.6 m off its end stays clear) |
| 1 m section | at most 0.33 m |
| anything into the house | 0.2-0.3 m |

Oblique ties are met at 53 degrees or more, so a wall's far corner can't leave a gap.

**Closure is walked from the doors,** like the game's check: from the veranda and from outside the side door (a man can
cross the house). Tiers 3 and 4 get no way out. The T4 outer ring is also walked alone, with the T3 ring left out.

**Roads.** No run stands on a ROAD or MAIN ROAD's paved core (its middle line within the road's width/2 - 1.5 m).
Tracks are crossed in places: Molos, Chalkeia, Charkia, Panochori, Rodopoli and Sofia have tracks inside or between
the rings.

**Shared road face** (Neochori, Sofia). The main road runs right along the veranda, so there is no room for two lines
on that side. The T3 face along the road is the outer line there too. At T4 it is stacked 2-high (H-barriers dropped
on top), and the outer ring ties into its ends.

### The newer brief points (f36615c)

- **Upgrading real walls with H-barriers on them:** not used yet. No piece overlaps mid-piece anywhere, so there are
  no clips to discount.
- **Dropping pieces:** no tier drops any (Charkia's window simply gets no bags).
- **Walling in the compound:** T3 stays tight round the office and what's attached. T4 takes in the neighbouring
  cluster, using the neighbours themselves as parts of the outer line where they stand in it.

### Round 4's wall items

- **Low old walls** (Kalochori and the rest): counted no more; lined, crossed square or avoided (above).
- **Side-door bags cutting into the office** (Agios Dionysios, Chalkeia): moved 0.5 m out.
- **Panochori's two HBarrier_1 cutting into the office:** that run (north-west, 0.35 m off the house's north wall) now
  stands 1.3 m off it.
- **Panochori's bar gate:** gone.
- **Therisa's hedgehogs in the tree planter:** gone (no hedgehogs this pass). The script now keeps its runs clear of
  the planters and other small props too.

## What to check in the game

1. **Closure from the door** at T3 and T4. If there is a way out, it most likely goes:
   - through a neighbour building the ring uses as a wall. A house with doors on both sides, or a shed or garage,
     would let a man walk through. These are named under each town below; check above all Agios Dionysios's
     industrial shed, Chalkeia's ruin and Charkia's damaged garage;
   - between two buildings whose boxes touch only at a corner (Molos, Paros, Therisa east chains).
2. **Fence crossings:** whether the in-game clip check flags the low wall or fence inside a piece's end
   ("through ... (low)" in the audit).
3. **Real sizes** of `Land_Mil_WallBig_4m_F` (my fit uses 4.0 x 0.8 m) and `Land_CncWall1_F` (guessed 1.0 x 0.6 m).
   Also: on a slope, does a 4 m wall leave a crawl gap under one end?
4. **The stacked H-barriers** on Neochori's and Sofia's road faces: do they sit on the first row?
5. **Tin walls:** I've treated them as low (3 m box). If they're really 2 m or more, Agios Dionysios's crossings could
   become ties.

## Per town: the rings and the line audit

Columns:

- **gap**: face to face, i.e. what the pieces must close. For a corner end it is measured to the cross run's outer face.
- **ends tie into**: what each end meets. A run name means it ties into that run's pieces. "corner" means a cross run
  ties into this end. "through X (low)" is a crossing of a low wall or fence.
- **end overlaps**: how far the first and last pieces pass the faces.
- **joints**: the piece-to-piece overlaps.

Piece names: HB5/HB3/HB1 are `Land_HBarrier_5/3/1_F`, W4 is `Land_Mil_WallBig_4m_F`, C1 is `Land_CncWall1_F`.

### Agios Dionysios

Open ground round the house, a big industrial shed north-west, tin fences west of the veranda and north from the house's north-east corner.

- **T3**: the round 4 ring with its gate filled (a straight H-barrier run where it stood). The two tin fences are low (under 2 m), so they no longer close anything: the west and north faces cross them square-ish, the runs on either side overlapping each other through the fence ("through ... (low)" below).
- **T4**: a box 6-8 m out on the open ground (the south face only 3 m out, to stay north of the unfinished building's tip). Its west and north faces end in the big shed's south-east and north-east faces, each met at about 53 degrees. The north face crosses the north tin fence.
- **Relies on (check):** the big shed (Land_u_Shed_Ind_F) being closed between the two outer ties. An industrial shed may have big doors on both sides.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west_s | T3 | 15.38 | corner (a run ties into it) / through wall_tin_4_2 (low) | 5: HB3 + HB3 + HB3 + HB3 + HB3 | 18.0 | 0.25 / 0.38 | 0.50, 0.50, 0.50, 0.50 |
| south | T3 | 26.98 | run west_s / corner (a run ties into it) | 5: HB5 + HB5 + HB5 + HB5 + HB5 | 29.0 | 0.34 / -0.0 | 0.42, 0.42, 0.42, 0.42 |
| east | T3 | 27.98 | run south / corner (a run ties into it) | 6: HB5 + HB5 + HB3 + HB3 + HB5 + HB5 | 30.4 | 0.34 / -0.01 | 0.42, 0.42, 0.42, 0.42, 0.42 |
| north_e | T3 | 7.95 | run east / through wall_tin_4_2 (low) | 4: HB3 + HB3 + HB1 + HB1 | 10.0 | 0.35 / 0.32 | 0.46, 0.46, 0.46 |
| north_w | T3 | 18.68 | through wall_tin_4_2 (low) / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 21.0 | 0.34 / 0.38 | 0.53, 0.53, 0.53 |
| west_n | T3 | 12.15 | run north_w / through wall_tin_4_2 (low) | 4: HB3 + HB3 + HB3 + HB3 | 14.4 | 0.37 / 0.38 | 0.50, 0.50, 0.50 |
| o_w | T4 | 30.30 | corner (a run ties into it) / Land_u_Shed_Ind_F | 9: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 36.0 | 0.54 / 0.49 | 0.58, 0.58, 0.58, 0.58, 0.58, 0.58, 0.58, 0.58 |
| o_s | T4 | 44.00 | run o_w / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 48.0 | 0.34 / -0.22 | 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35 |
| o_e | T4 | 42.50 | run o_s / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 48.0 | 0.4 / 0.11 | 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45 |
| o_ne | T4 | 18.30 | run o_e / through wall_tin_4_2 (low) | 6: W4 + W4 + C1 + W4 + W4 + W4 | 21.0 | 0.37 / 0.31 | 0.40, 0.40, 0.40, 0.40, 0.40 |
| o_nw | T4 | 14.40 | through wall_tin_4_2 (low) / Land_u_Shed_Ind_F | 4: W4 + W4 + W4 + W4 | 16.0 | 0.29 / 0.32 | 0.33, 0.33, 0.33 |

### Chalkeia

A dead-end track west of the veranda, shops and a garage south-west, an annexe north, a ruin and two big rocks east, a house abutting the east side.

- **T3**: west and north as round 4. The south face no longer ends on the low stone wall: it turns up into the house's south wall. The east yard is closed by its own L against the annexe (not the ruin): from the east house's north face up and across.
- **T4**: the garage, shops and big house west and north-west (a wall from the garage up to the big house); a wall across the track into the north shop; the shop, the ruin and the two rocks north-east and east (a wall between the rocks); south a wall steps round the end of the low stone wall onto the south annexe, then on to the shops.
- **Relies on (check):** the ruin (Land_d_House_Small_01_V1_F) between the north shop and the north-east rock, and the two big rocks.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 24.78 | Land_u_Shop_01_V1_F / corner (a run ties into it) | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 26.8 | 0.34 / -0.0 | 0.42, 0.42, 0.42, 0.42 |
| north | T3 | 11.55 | run west / Land_u_Addon_02_V1_F | 3: HB5 + HB3 + HB3 | 13.0 | 0.33 / 0.33 | 0.39, 0.39 |
| south | T3 | 19.43 | Land_u_Shop_01_V1_F / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 21.0 | 0.34 / -0.01 | 0.42, 0.42, 0.42 |
| se | T3 | 10.60 | run south / the house | 2: HB5 + HB5 | 11.6 | 0.34 / 0.24 | 0.42 |
| e1 | T3 | 11.03 | Land_i_House_Small_01_V1_F / corner (a run ties into it) | 2: HB5 + HB5 | 11.6 | 0.33 / -0.14 | 0.38 |
| e2 | T3 | 2.75 | run e1 / Land_u_Addon_02_V1_F | 3: HB1 + HB1 + HB1 | 4.2 | 0.33 / 0.33 | 0.39, 0.39 |
| o_w | T4 | 20.70 | Land_i_Garage_V2_F / Land_i_House_Big_01_V3_F | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.43 / 0.43 | 0.49, 0.49, 0.49, 0.49, 0.49 |
| o_n | T4 | 20.00 | Land_i_House_Big_01_V3_F / corner (a run ties into it) | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.49 / 0.56 | 0.59, 0.59, 0.59, 0.59, 0.59 |
| o_ne | T4 | 4.45 | run o_n / Land_i_Shop_01_V2_F | 3: W4 + C1 + C1 | 6.0 | 0.38 / 0.31 | 0.43, 0.43 |
| o_e | T4 | 13.85 | Land_d_House_Small_01_V1_F / stone_big_f | 4: W4 + W4 + W4 + W4 | 16.0 | 0.4 / 0.4 | 0.45, 0.45, 0.45 |
| o_s_w | T4 | 22.20 | Land_i_Shop_02_V2_F / corner (a run ties into it) | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.33 / -0.25 | 0.34, 0.34, 0.34, 0.34, 0.34 |
| o_s_m | T4 | 2.25 | run o_s_w / Land_u_Addon_02_V1_F | 4: C1 + C1 + C1 + C1 | 4.0 | 0.31 / 0.31 | 0.38, 0.38, 0.38 |
| o_s_e | T4 | 12.55 | Land_u_Addon_02_V1_F / corner (a run ties into it) | 5: W4 + C1 + C1 + W4 + W4 | 14.0 | 0.33 / -0.25 | 0.34, 0.34, 0.34, 0.34 |
| o_se | T4 | 11.05 | run o_s_e / stone_big_f | 4: W4 + C1 + W4 + W4 | 13.0 | 0.37 / 0.37 | 0.40, 0.40, 0.40 |

### Charkia

Tracks round three sides, a damaged garage at the house's north-west corner, a walled garden east whose walls are low stone walls and wire fences.

- **T3 (rebuilt)**: west and south faces as before; the south face ends at x 0 and turns up into the house. The north face runs from the garage and stops short of the garden's wire fence, turning down into the house. A small box against the house's east wall holds the side door (its bags are now short ones, so the box clears them).
- **T4**: a box on the open ground and across the tracks, west, south and north, with the garage inside it. The west face threads between the garage's corner, the west house and the end of a wire fence. Inside the garden the walls are lined: the north face crosses the garden's west wire fence square; an east face runs down inside the garden, and a wall along the inside of its south-west stone wall runs into the house's east wall below the ground-floor window. A wall from the house's south wall down to the south face closes the rest. The window gets no T2 bags (the wall stands in front of it).
- **Relies on (check):** the damaged garage (Land_i_Garage_V1_dam_F) at T3. Also: T4 ties into the house in two places (its south and east walls), so the house is part of both lines on its south-east corner.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 16.28 | corner (a run ties into it) / Land_i_Garage_V1_dam_F | 3: HB5 + HB5 + HB5 | 17.4 | -0.04 / 0.34 | 0.41, 0.41 |
| south | T3 | 12.48 | run west / corner (a run ties into it) | 3: HB5 + HB3 + HB3 | 13.0 | 0.3 / -0.39 | 0.30, 0.30 |
| se | T3 | 5.85 | run south / the house | 4: HB3 + HB1 + HB1 + HB1 | 7.8 | 0.35 / 0.25 | 0.45, 0.45, 0.45 |
| north | T3 | 10.23 | Land_i_Garage_V1_dam_F / corner (a run ties into it) | 2: HB5 + HB5 | 11.6 | 0.38 / 0.44 | 0.55 |
| n_down | T3 | 2.70 | run north / the house | 3: HB1 + HB1 + HB1 | 4.2 | 0.35 / 0.25 | 0.45, 0.45 |
| e_top | T3 | 3.63 | corner (a run ties into it) / the house | 1: HB3 | 3.6 | -0.25 / 0.22 |  |
| e_n | T3 | 8.38 | run e_top / corner (a run ties into it) | 2: HB5 + HB3 | 9.4 | 0.36 / 0.19 | 0.48 |
| e_w | T3 | 1.85 | run e_n / the house | 2: HB1 + HB1 | 2.8 | 0.33 / 0.23 | 0.39 |
| o_s | T4 | 29.40 | corner (a run ties into it) / corner (a run ties into it) | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 32.0 | -0.08 / -0.08 | 0.40, 0.40, 0.40, 0.40, 0.40, 0.40, 0.40 |
| o_h | T4 | 14.30 | run o_s / the house | 4: W4 + W4 + W4 + W4 | 16.0 | 0.35 / 0.22 | 0.37, 0.37, 0.37 |
| o_w | T4 | 38.10 | corner (a run ties into it) / run o_s | 11: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.0 | 0.31 / 0.44 | 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51 |
| o_n_w | T4 | 27.20 | run o_w / through wired_fence_8m_f (low) | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 32.0 | 0.48 / 0.3 | 0.57, 0.57, 0.57, 0.57, 0.57, 0.57, 0.57 |
| o_n_e | T4 | 11.90 | through wired_fence_8m_f (low) / corner (a run ties into it) | 4: W4 + C1 + W4 + W4 | 13.0 | 0.24 / -0.21 | 0.36, 0.36, 0.36 |
| o_e | T4 | 17.27 | run o_n_e / corner (a run ties into it) | 5: W4 + W4 + W4 + W4 + W4 | 20.0 | 0.44 / 0.28 | 0.50, 0.50, 0.50, 0.50 |
| o_g | T4 | 7.60 | run o_e / the house | 3: W4 + C1 + W4 | 9.0 | 0.37 / 0.23 | 0.40, 0.40 |

### Kalochori

All the old walls here are low (stone, concrete garden walls). There is a lane west, the main road 7 m south of the front yard, a north house abutting the house, and sheds east and north-east.

- **T3 (rebuilt)**: a tight ring of its own round the house and its front yard: west in the lane, south across the front yard (crossing its two low side walls square), east up the east yard, and north from it into the north house. The north house closes the north.
- **T4**: up the lane, with a wall across its north end from the big stone house to the north house (13 degrees off square, so a 4 m wall and a 1 m section fit); along the main road's verge (clear of its paved core); up the east yard to the north shed; and a short run from the north house square into the shed's south-west face. That closes the 0.9 m gap between those two.
- **Check:** The lane corridor between the two west faces is only 1 m wide. The lane is 4 m and the two lines share it.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 22.03 | corner (a run ties into it) / Land_i_House_Small_02_V3_F | 4: HB5 + HB5 + HB5 + HB5 | 23.2 | -0.22 / 0.32 | 0.36, 0.36, 0.36 |
| s_w | T3 | 0.55 | run west / through concrete_smallwall_4m_f (low) | 1: HB1 | 1.4 | 0.39 / 0.46 |  |
| s_m | T3 | 8.20 | through concrete_smallwall_4m_f (low) / through concrete_smallwall_4m_f (low) | 2: HB5 + HB3 | 9.4 | 0.4 / 0.4 | 0.39 |
| s_e | T3 | 4.08 | through concrete_smallwall_4m_f (low) / corner (a run ties into it) | 2: HB3 + HB1 | 5.0 | 0.44 / 0.05 | 0.43 |
| east | T3 | 24.18 | run s_e / corner (a run ties into it) | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 26.8 | 0.37 / 0.26 | 0.50, 0.50, 0.50, 0.50 |
| north_e | T3 | 3.45 | run east / Land_i_House_Small_02_V3_F | 4: HB1 + HB1 + HB1 + HB1 | 5.6 | 0.36 / 0.36 | 0.48, 0.48, 0.48 |
| o_lane | T4 | 3.80 | Land_i_Stone_HouseBig_V3_F / Land_i_House_Small_02_V3_F | 2: W4 + C1 | 5.0 | 0.41 / 0.32 | 0.47 |
| o_s | T4 | 20.60 | corner (a run ties into it) / corner (a run ties into it) | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.37 / 0.37 | 0.53, 0.53, 0.53, 0.53, 0.53 |
| o_w | T4 | 25.00 | run o_s / run o_lane | 7: W4 + W4 + W4 + W4 + W4 + W4 + W4 | 28.0 | 0.35 / 0.35 | 0.38, 0.38, 0.38, 0.38, 0.38, 0.38 |
| o_e | T4 | 28.60 | run o_s / Land_i_Stone_Shed_V3_F | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 32.0 | 0.36 / 0.36 | 0.38, 0.38, 0.38, 0.38, 0.38, 0.38, 0.38 |
| o_n | T4 | 2.30 | Land_i_House_Small_02_V3_F / Land_i_Stone_Shed_V3_F | 4: C1 + C1 + C1 + C1 | 4.0 | 0.31 / 0.31 | 0.36, 0.36, 0.36 |

### Molos

Tracks west and north, a shop abutting the house's front, old city walls south-east, a chapel east.

- **T3**: the round 4 ring with its gate filled.
- **T4**: west of the west track and north of the north track (both tracks between the rings), tied into the big north house; east and south the big houses, the shop, the chapel and the old city walls close it, with walls in their three gaps.
- **Relies on (check):** building-to-building contacts on the south and east (shop/house/annexe/big house, the chapel).

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 22.48 | Land_u_Shop_02_V1_F / corner (a run ties into it) | 5: HB5 + HB3 + HB3 + HB5 + HB5 | 24.6 | 0.34 / 0.04 | 0.43, 0.43, 0.43, 0.43 |
| north | T3 | 25.57 | run west / corner (a run ties into it) | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 26.8 | 0.31 / -0.35 | 0.32, 0.32, 0.32, 0.32 |
| east | T3 | 18.70 | run north / city_8m_f | 4: HB5 + HB3 + HB5 + HB5 | 21.0 | 0.37 / 0.37 | 0.52, 0.52, 0.52 |
| o_n | T4 | 27.15 | Land_i_House_Big_02_V2_F / corner (a run ties into it) | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 32.0 | 0.47 / 0.46 | 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56 |
| o_w | T4 | 42.50 | run o_n / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 48.0 | 0.4 / 0.11 | 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45 |
| o_s | T4 | 16.65 | run o_w / Land_i_House_Small_02_V2_F | 5: W4 + W4 + W4 + W4 + W4 | 20.0 | 0.49 / 0.49 | 0.59, 0.59, 0.59, 0.59 |
| o_se | T4 | 6.05 | Land_u_House_Big_02_V1_F / city_8m_f | 5: W4 + C1 + C1 + C1 + C1 | 8.0 | 0.32 / 0.3 | 0.33, 0.33, 0.33, 0.33 |
| o_e | T4 | 6.90 | city_4m_f / Land_Chapel_V1_F | 2: W4 + W4 | 8.0 | 0.36 / 0.36 | 0.39 |
| o_ne | T4 | 10.40 | Land_i_Shop_01_V3_F / Land_Chapel_V1_F | 3: W4 + W4 + W4 | 12.0 | 0.38 / 0.38 | 0.42, 0.42 |

### Neochori

The main road runs right along the veranda (west), a plaza north with low concrete garden walls, the garage and big houses east, a house south.

- **T3**: the round 4 ring with its gate filled.
- **T4**: the road leaves no room for two lines on the west. The T3 west face is the outer line there too, stacked 2-high at T4, and the outer ring ties into it. A wall runs from its north end up the plaza's diagonal low garden wall (1 m inside it) into the north shop. The shops, the big house and the garage close the east, with a wall from the shop to the big house through a gap in the low garden wall. A wall from the big house to the south-east annexe and one from the big south-east house to the south house close the south.
- **Check:** The outer ring shares the T3 west face (my outer-only walk keeps that face in).

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 37.43 | Land_i_House_Small_01_V1_F / corner (a run ties into it) | 7: HB5 + HB5 + HB5 + HB5 + HB5 + HB5 + HB5 | 40.6 | 0.35 / 0.11 | 0.45, 0.45, 0.45, 0.45, 0.45, 0.45 |
| north | T3 | 19.68 | run west / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 21.0 | 0.33 / -0.14 | 0.38, 0.38, 0.38 |
| ne | T3 | 3.90 | run north / Land_i_Garage_V2_F | 2: HB3 + HB1 | 5.0 | 0.34 / 0.34 | 0.42 |
| se | T3 | 14.95 | Land_i_House_Small_01_V1_F / Land_i_Garage_V2_F | 4: HB5 + HB3 + HB3 + HB3 | 16.6 | 0.31 / 0.31 | 0.34, 0.34, 0.34 |
| o_nw | T4 | 15.05 | run north / Land_u_Shop_01_V1_F | 5: W4 + W4 + C1 + W4 + W4 | 17.0 | 0.32 / 0.32 | 0.33, 0.33, 0.33, 0.33 |
| o_ne | T4 | 7.30 | Land_u_Shop_01_V1_F / Land_i_House_Big_01_V1_F | 3: W4 + C1 + W4 | 9.0 | 0.4 / 0.4 | 0.45, 0.45 |
| o_e | T4 | 10.00 | Land_i_House_Big_01_V1_F / Land_u_Addon_02_V1_F | 3: W4 + W4 + W4 | 12.0 | 0.46 / 0.46 | 0.54, 0.54 |
| o_s | T4 | 16.20 | Land_i_House_Small_01_V1_F / Land_u_House_Big_01_V1_F | 7: W4 + W4 + C1 + C1 + C1 + W4 + W4 | 19.0 | 0.34 / 0.34 | 0.35, 0.35, 0.35, 0.35, 0.35, 0.35 |

### Panochori

A track along the veranda, a north house abutting the house, a big house south-west, an east yard walled by low stone walls, big houses east and north-east.

- **T3 (rebuilt)**: the east yard is lined inside its low walls. The south face runs into the big south-west house's north-east face. The north-west run now stands 1.3 m off the house: round 4 measured its 1-high pieces cutting into the office at 0.35 m.
- **T4**: west across the track into the big south-west house's north face; north along the north house; east from it through the gap between the yard's two stone walls to the big north-east house; then the annexe and the big east house. South from the east house's corner a wall runs between the ends of two low stone walls, slanted 5 degrees to clear both pillars, to the big south houses. A wall from the south annexe to the big south-west house closes the rest.
- **Check:** The slanted south-east wall passes 0.05-0.3 m from two low stone pillars (its middle is clear).

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 17.98 | corner (a run ties into it) / Land_i_House_Big_02_V3_F | 4: HB5 + HB3 + HB3 + HB5 | 18.8 | -0.39 / 0.3 | 0.30, 0.30, 0.30 |
| west | T3 | 22.48 | run south / corner (a run ties into it) | 5: HB5 + HB3 + HB3 + HB5 + HB5 | 24.6 | 0.34 / 0.04 | 0.43, 0.43, 0.43, 0.43 |
| nw | T3 | 2.65 | run west / Land_u_House_Small_02_V1_F | 3: HB1 + HB1 + HB1 | 4.2 | 0.34 / 0.34 | 0.43, 0.43 |
| ne | T3 | 4.78 | Land_u_House_Small_02_V1_F / corner (a run ties into it) | 2: HB3 + HB1 | 5.0 | 0.3 / -0.39 | 0.30 |
| east | T3 | 21.20 | run ne / run south | 4: HB5 + HB5 + HB5 + HB5 | 23.2 | 0.35 / 0.35 | 0.44, 0.44, 0.44 |
| o_w | T4 | 31.25 | Land_i_House_Big_02_V3_F / corner (a run ties into it) | 9: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 36.0 | 0.44 / 0.28 | 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 |
| o_n | T4 | 10.95 | run o_w / Land_u_House_Small_02_V1_F | 4: W4 + C1 + W4 + W4 | 13.0 | 0.38 / 0.38 | 0.43, 0.43, 0.43 |
| o_ne | T4 | 15.05 | Land_u_House_Small_02_V1_F / Land_i_House_Big_02_V3_F | 5: W4 + W4 + C1 + W4 + W4 | 17.0 | 0.32 / 0.32 | 0.33, 0.33, 0.33, 0.33 |
| o_e | T4 | 20.60 | Land_i_House_Big_01_V2_F / Land_i_House_Big_02_V2_F | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.44 / 0.44 | 0.51, 0.51, 0.51, 0.51, 0.51 |
| o_s | T4 | 7.20 | Land_i_House_Big_02_V3_F / Land_u_Addon_01_V1_F | 3: W4 + C1 + W4 | 9.0 | 0.42 / 0.42 | 0.48, 0.48 |

### Paros

A track west, houses abutting the east side and closing the south, a big house north, the main road south-west.

- **T3**: the broken city wall north-west of the house is low, so the west face now runs on up into the big north house. The south-west run goes into the south house's west face instead of alongside it, where round 4 left a 0.2 m slot. The north-east yard run is as before.
- **T4**: west of the track, clear of the main road, tied into the big north house and the south house. North and east the big houses, the shed, the garage, the old city walls and the shops close it, with a wall in the one gap in the old city wall.
- **Relies on (check):** a long chain of buildings east (big houses, shed, garage, shops); the side door opens into the yard north of the east house (inside T3).

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 29.73 | corner (a run ties into it) / Land_i_House_Big_02_V2_F | 6: HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 32.6 | 0.17 / 0.36 | 0.47, 0.47, 0.47, 0.47, 0.47 |
| sw | T3 | 2.85 | run west / Land_i_House_Small_02_V1_F | 1: HB3 | 3.6 | 0.38 / 0.38 |  |
| ne | T3 | 13.00 | Land_i_House_Small_01_V1_F / Land_i_House_Big_02_V2_F | 5: HB3 + HB3 + HB3 + HB3 + HB1 | 15.8 | 0.37 / 0.37 | 0.51, 0.51, 0.51, 0.51 |
| o_s | T4 | 11.93 | corner (a run ties into it) / Land_i_House_Small_02_V1_F | 4: W4 + C1 + W4 + W4 | 13.0 | -0.27 / 0.33 | 0.34, 0.34, 0.34 |
| o_w | T4 | 33.80 | run o_s / corner (a run ties into it) | 10: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 40.0 | 0.48 / 0.52 | 0.58, 0.58, 0.58, 0.58, 0.58, 0.58, 0.58, 0.58, 0.58 |
| o_n | T4 | 6.70 | run o_w / Land_i_House_Big_02_V2_F | 2: W4 + W4 | 8.0 | 0.41 / 0.41 | 0.47 |
| o_e | T4 | 4.05 | city_pillar_f / city_8m_f | 2: W4 + C1 | 5.0 | 0.32 / 0.3 | 0.33 |

### Rodopoli

A big walled yard west (real city walls), a lane east of the house whose east side is a low concrete wall, tracks north, east and south.

- **T3**: the yard's two gaps closed as before. The lane is now closed by a run up its middle, west of its tree planters (no room between the planters and the low wall), tied into runs across the lane's two ends.
- **T4**: west of the walled yard, the big west houses and the garage, with a wall across the gap between them past the rusty tank. Along the north track's verge and down the east track's verge. Back across the low concrete wall (square, between two pillars) into the south house. From the south annexe across to the big west house.
- **Relies on (check):** the big west house between the outer south-west wall and the west gap wall.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south_gap | T3 | 2.90 | city2_8m_f / Land_i_Addon_02_V1_F | 1: HB3 | 3.6 | 0.35 / 0.35 |  |
| north_gap | T3 | 5.05 | city_pillar_f / city2_8m_f | 1: HB5 | 5.8 | 0.38 / 0.38 |  |
| lane_s | T3 | 4.38 | Land_u_House_Small_02_V1_F / corner (a run ties into it) | 2: HB3 + HB1 | 5.0 | 0.33 / -0.1 | 0.39 |
| lane_n | T3 | 4.83 | city2_8m_f / corner (a run ties into it) | 1: HB5 | 5.8 | 0.4 / 0.57 |  |
| east | T3 | 37.40 | run lane_s / run lane_n | 7: HB5 + HB5 + HB5 + HB5 + HB5 + HB5 + HB5 | 40.6 | 0.34 / 0.34 | 0.42, 0.42, 0.42, 0.42, 0.42, 0.42 |
| o_w | T4 | 10.65 | Land_i_House_Big_02_V2_F / Land_i_Garage_V2_F | 3: W4 + W4 + W4 | 12.0 | 0.33 / 0.33 | 0.34, 0.34 |
| o_n | T4 | 46.00 | corner (a run ties into it) / corner (a run ties into it) | 13: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 52.0 | 0.17 / 0.17 | 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47 |
| o_nw | T4 | 2.40 | run o_n / Land_i_Garage_V2_F | 4: C1 + C1 + C1 + C1 | 4.0 | 0.3 / 0.3 | 0.33, 0.33, 0.33 |
| o_e | T4 | 48.50 | run o_n / corner (a run ties into it) | 13: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 52.0 | 0.3 / -0.4 | 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30 |
| o_s_e | T4 | 3.15 | through concrete_smallwall_8m_f (low) / run o_e | 1: W4 | 4.0 | 0.45 / 0.4 |  |
| o_s_w | T4 | 9.30 | Land_u_House_Small_02_V1_F / through concrete_smallwall_8m_f (low) | 6: W4 + C1 + C1 + C1 + C1 + W4 | 12.0 | 0.36 / 0.43 | 0.38, 0.38, 0.38, 0.38, 0.38 |
| o_sw | T4 | 9.75 | Land_i_House_Big_02_V2_F / Land_i_Addon_02_V1_F | 6: W4 + C1 + C1 + C1 + C1 + W4 | 12.0 | 0.32 / 0.32 | 0.32, 0.32, 0.32, 0.32, 0.32 |

### Sofia

The main road west, a track south, big houses north and east.

- **T3**: the round 4 ring with its gate filled.
- **T4**: as at Neochori, the road side is shared: the T3 west face is stacked 2-high and the outer ring runs on south from its corner along the verge. Then across the track south (the track then runs between the rings), and up the east to the east annexe. The big houses north and east close the rest.
- **Check:** The outer ring shares the T3 west face.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 19.98 | Land_i_House_Big_02_V2_F / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 21.0 | 0.31 / -0.29 | 0.33, 0.33, 0.33 |
| south | T3 | 14.08 | run west / corner (a run ties into it) | 3: HB5 + HB3 + HB5 | 15.2 | 0.34 / -0.04 | 0.41, 0.41 |
| se | T3 | 1.65 | run south / Land_i_House_Small_02_V2_F | 2: HB1 + HB1 | 2.8 | 0.35 / 0.35 | 0.45 |
| east_gap | T3 | 2.70 | Land_i_House_Small_02_V2_F / Land_i_House_Big_02_V3_F | 3: HB1 + HB1 + HB1 | 4.2 | 0.34 / 0.34 | 0.41, 0.41 |
| o_w | T4 | 8.30 | run west / corner (a run ties into it) | 3: W4 + C1 + W4 | 9.0 | 0.32 / -0.29 | 0.33, 0.33 |
| o_s | T4 | 38.60 | run o_w / corner (a run ties into it) | 11: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.0 | 0.42 / 0.2 | 0.48, 0.48, 0.48, 0.48, 0.48, 0.48, 0.48, 0.48, 0.48, 0.48 |
| o_e | T4 | 28.55 | run o_s / Land_i_Addon_03_V1_F | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 32.0 | 0.36 / 0.36 | 0.39, 0.39, 0.39, 0.39, 0.39, 0.39, 0.39 |

### Therisa

Annexes abut both sides of the house, a walled garden north-west (real city walls), a plaza south, old city walls south-east with a broken middle stretch, a road 30 m south.

- **T3**: the south-east city wall's middle stretch is a broken (low) piece, so the south face now turns up into the intact first stretch. The rest is as round 4.
- **T4**: south across the plaza between the south-west annexe and the big south-east house, clear of the road. Up the east between the annexe and the big north-east house. Along the north track's verge to the old north-west city walls, with a wall across their one gap. On the west, the shops and the kiosk, with a wall between them.
- **Relies on (check):** the building chain west (kiosk, annexe, shops) and the north-west walled block.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 31.88 | Land_i_Addon_04_V1_F / corner (a run ties into it) | 6: HB5 + HB5 + HB5 + HB5 + HB5 + HB5 | 34.8 | 0.36 / 0.18 | 0.48, 0.48, 0.48, 0.48, 0.48 |
| se | T3 | 8.85 | run south / Land_i_Addon_03_V1_F | 3: HB3 + HB3 + HB3 | 10.8 | 0.39 / 0.39 | 0.58, 0.58 |
| sw | T3 | 2.25 | Land_i_Shop_01_V1_F / run south | 3: HB1 + HB1 + HB1 | 4.2 | 0.39 / 0.39 | 0.58, 0.58 |
| nw_gap | T3 | 3.80 | city_8m_f / city_8m_f | 2: HB3 + HB1 | 5.0 | 0.36 / 0.36 | 0.48 |
| n_e | T3 | 9.45 | Land_i_Addon_03_V1_F / Land_u_House_Small_01_V1_F | 3: HB3 + HB3 + HB3 | 10.8 | 0.32 / 0.32 | 0.36, 0.36 |
| o_s | T4 | 33.90 | Land_i_Addon_04_V1_F / Land_i_House_Big_02_V1_F | 10: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 40.0 | 0.48 / 0.48 | 0.57, 0.57, 0.57, 0.57, 0.57, 0.57, 0.57, 0.57, 0.57 |
| o_e | T4 | 21.00 | Land_u_Addon_02_V1_F / Land_i_House_Big_01_V2_F | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.39 / 0.39 | 0.44, 0.44, 0.44, 0.44, 0.44 |
| o_n | T4 | 45.48 | Land_i_House_Big_01_V2_F / corner (a run ties into it) | 13: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 52.0 | 0.43 / 0.23 | 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49 |
| o_nw | T4 | 4.40 | run o_n / city_8m_f | 3: W4 + C1 + C1 | 6.0 | 0.4 / 0.31 | 0.44, 0.44 |
| o_n1 | T4 | 3.55 | city_8m_f / city_8m_f | 6: C1 + C1 + C1 + C1 + C1 + C1 | 6.0 | 0.34 / 0.31 | 0.36, 0.36, 0.36, 0.36, 0.36 |
| o_w | T4 | 6.45 | Land_Kiosk_redburger_F / Land_u_Shop_02_V1_F | 2: W4 + W4 | 8.0 | 0.49 / 0.49 | 0.58 |
