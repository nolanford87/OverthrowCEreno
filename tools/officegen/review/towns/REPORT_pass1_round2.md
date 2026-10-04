# Towns: pass 1, round 2 report (answering pass1_round1.md)

Drafts and script are pushed (d855ea0): `tools/officegen/drafting/towns.py`, `tools/officegen/layouts/drafts/<town>.txt`.
All 11 drafts pass `tl.check()` and the script's own checks. Those checks are: every run fitted between its faces;
piece middles clear of buildings, walls, rocks, the house and a road's paved core; and T3, T4 and T4's outer ring
alone walked closed from the doors. None of this round has been in the game yet. Coordinates are office model [x, y].

**Kalochori, Molos and Rodopoli are unchanged** (their drafts are byte-identical to e467ad2). Agios Dionysios and
Panochori changed only where you asked: Agios's side-door bags moved, Panochori's west run moved off the house.

## What round 1's ways out turned out to be

I overlaid the draft and the probe's building boxes on your top-down screenshots, calibrating on round 1's pieces.
Three causes show up:

1. **Building boxes run past the real walls.** Many probed buildings' boxes reach 2-7 m past their real walls,
   over porches, arcades and eaves. A run tied into the box face ends in open ground. Seen at:
   - Chalkeia: the shop at the west run's south end; the south shop at T4's south-west corner.
   - Paros: the big north house, by about 5 m at both ends; the east house, by 1.5 m; the south house, by 2.4 m.
   - Sofia: both houses either side of the east gap; the H-barriers stood in open yard.
   - Therisa: the south-west shop, whose front is 7 m inside its box; the west shop at T4.
   - Neochori: the north shop, by 3.5 m and 6 m.
2. **Joints and corners fitted to the measured boxes.** The boxes (5.8, 3.6, 1.4 and 4.1 m) take in slack beyond
   the baskets and the wall's ends, so planned overlaps of 0.3-0.45 m were nearly nil in the game. That matches:
   - Charkia's two T3 corners;
   - Sofia's T4 corner (-9.3, -19.5) and the T4 wall joint at (29.2, -9.5);
   - Chalkeia's T4 wall joint at (-8.2, -29);
   - Neochori's west run joint at (-7.9, -4.3).
3. **Routes through neighbour houses.** Neochori's ring went into the garage and the big east house, then out of
   them at (7.5, 2.8) and (26.9, -3.7). Chalkeia's side-door yard was closed against the east house's north face, at
   (11.4, 0.8).

## What changed

**Fitting, in the six towns that leaked** (Chalkeia, Charkia, Neochori, Paros, Sofia, Therisa).
Pieces are now fitted by their solid lengths: HBarrier_5 5.4 m, HBarrier_3 3.2 m, HBarrier_1 1.1 m,
Mil_WallBig_4m 3.7 m. Overlaps are now:

| where | overlap |
|---|---|
| joints | 0.35-0.6 m (real) |
| into another run's piece | 0.5-0.8 m (walls 0.35-0.55 m) |
| corners | flush with the cross run's outer face, or up to 0.5 m past it |
| into a building | 0.12-0.2 m past the face; townlib's 6.0 m HBarrier_5 box leaves no more |
| into the house | 0.1-0.2 m |

The five towns found closed keep round 1's fitting, so their drafts stay as tested.

**Box trims** (`trims=` per town in the script). Where the screenshot shows a box face beyond the real wall, the
script pulls that face in before drafting, so every check, townlib's included, uses the corrected footprint:

| town | building | face | trimmed |
|---|---|---|---|
| Chalkeia | Land_u_Shop_01_V1_F (west yard corner) | east | 3.0 m |
| Chalkeia | Land_i_Shop_02_V2_F (south-west) | east | 2.2 m |
| Neochori | Land_u_Shop_01_V1_F (north shop) | south-west | 3.5 m |
| Neochori | Land_u_Shop_01_V1_F (north shop) | north-west | 5.9 m |
| Paros | Land_i_House_Big_02_V2_F (north) | west end | 5.0 m |
| Paros | Land_i_House_Big_02_V2_F (north) | east end | 5.7 m |
| Paros | Land_i_House_Small_01_V1_F (east) | north | 1.5 m |
| Paros | Land_i_House_Small_02_V1_F (south) | west | 2.4 m |
| Therisa | Land_u_Shop_02_V1_F (west) | south | 2.5 m |

These are read off the screenshots to about half a metre. If a run now cuts into a real wall at its end, the trim
was too deep; if a gap stays, too shallow.

### Per town

- **Neochori.** T3 is now a box of its own round the house; it no longer ties into the garage. T4 takes the garage
  and the big east house inside it:
  - an east wall at x 36.5;
  - a south wall at y -13.5 into the old city wall, then the road-side face carried on into the south house.
  - North, it goes round the outside of the plaza's low-walled garden (up the road verge, then along y 29) into
    the north shop's real north-west wall.
  - The road-side (west) face is still shared with T3 and stacked 2-high.
- **Charkia.** Same rings, with the new fitting. The two corners round 1 found open now overlap fully.
- **Sofia.**
  - The east gap run is gone. The side door's yard is closed by one run from the north house to the east house at
    x 8.5, so the east house's north face is inside for only 2 m.
  - T4's corner and joints get the new fitting.
- **Paros.** All three of round 1's ways out ended on overstated boxes. Now:
  - the west face runs up to y 20 and turns into the big north house's real west end;
  - the north yard is closed by an L from the east house's real north face (x 12.5) into the big north house's
    real east end;
  - the T3 south-west run and the T4 south wall go 2.4 m deeper, to the south house's real wall;
  - T4's north wall moves to y 23 to clear the new T3 corner.
- **Therisa.**
  - The south-west shop's box runs 7 m past its real front, so round 1's run between it and the annexe stood in the
    open. The plaza now has its own west face, at x -13.5, up into the west annexe.
  - The passage between that annexe and the house is closed by a run into the house's north-west room. That wall
    has no door.
  - The walled garden north-west is now outside T3 and inside T4.
  - T4's west wall goes 2.5 m deeper, to the west shop's real south wall (the way out at (-24.4, -9.9)).
- **Chalkeia.**
  - The west run comes down to its own corner with the south face; the shop's box there is open yard.
  - The side-door yard is closed against the house (a run at y 1.2) instead of the east house's north face.
  - T4's south-west wall goes 2.2 m deeper, to the south shop's real wall, with the new fitting at its joints.

### The pieces

- **Side-door sandbags:** Agios Dionysios's and Chalkeia's are now 2.6 m out from the door (round 1: 1.85 m).
- **Panochori:** the west face moved from x -6.2 to x -7.0 (1.2 m off the veranda), and the north-west run with it.
  Round 1 measured its HBarrier_5 and HBarrier_3 cutting into the office.

### The house's faces

You asked that a line end on the office only on a face with no door. Where it can, a run now ties into the north
face, the south face of the house proper, or the north-west room's west wall. Three places still tie into the east
wall, which has the side door, beside it:

- Chalkeia T3 (a run at y 1.2);
- Charkia T3 (runs at y 7.4 and -1);
- Charkia T4 (below the window).

At these three, the east wall is boxed in by neighbours or the garden's low walls, so the side door can only be
enclosed against it. Charkia's T4 tie closed in round 1.

### The newer brief points

- **Upgrading existing walls:** not used yet. No piece stands in a real wall along its length.
- **Walling in the compound:** Neochori's T4 now takes in the garage and big house; Therisa's takes in the walled
  garden. The others already ran round their cluster or used its buildings as the line.

## Counts (things per tier; each tier keeps the one below)

bagL/bagS: BagFence_Long/Short; HB5/3/1: HBarrier_5/3/1; W4: Mil_WallBig_4m; C1: CncWall1.

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Agios Dionysios | 0 | 5 (2 bagL, 3 bagS) | 33 (2 HB1, 14 HB3, 12 HB5, 2 bagL, 3 bagS) | 76 (1 C1, 2 HB1, 14 HB3, 12 HB5, 42 W4, 2 bagL, 3 bagS) |
| Chalkeia | 0 | 4 (2 bagL, 2 bagS) | 32 (5 HB1, 12 HB3, 11 HB5, 2 bagL, 2 bagS) | 75 (12 C1, 5 HB1, 12 HB3, 11 HB5, 31 W4, 2 bagL, 2 bagS) |
| Charkia | 0 | 4 (1 bagL, 3 bagS) | 27 (6 HB1, 12 HB3, 5 HB5, 1 bagL, 3 bagS) | 79 (9 C1, 6 HB1, 12 HB3, 5 HB5, 43 W4, 1 bagL, 3 bagS) |
| Kalochori | 0 | 5 (2 bagL, 3 bagS) | 23 (6 HB1, 3 HB3, 9 HB5, 2 bagL, 3 bagS) | 50 (5 C1, 6 HB1, 3 HB3, 9 HB5, 22 W4, 2 bagL, 3 bagS) |
| Molos | 0 | 5 (2 bagL, 3 bagS) | 19 (4 HB3, 10 HB5, 2 bagL, 3 bagS) | 54 (4 C1, 4 HB3, 10 HB5, 31 W4, 2 bagL, 3 bagS) |
| Neochori | 0 | 5 (2 bagL, 3 bagS) | 24 (4 HB3, 15 HB5, 2 bagL, 3 bagS) | 74 (5 C1, 5 HB3, 20 HB5, 39 W4, 2 bagL, 3 bagS) |
| Panochori | 0 | 5 (2 bagL, 3 bagS) | 23 (5 HB1, 3 HB3, 10 HB5, 2 bagL, 3 bagS) | 50 (3 C1, 5 HB1, 3 HB3, 10 HB5, 24 W4, 2 bagL, 3 bagS) |
| Paros | 0 | 4 (1 bagL, 3 bagS) | 22 (3 HB1, 4 HB3, 11 HB5, 1 bagL, 3 bagS) | 47 (5 C1, 3 HB1, 4 HB3, 11 HB5, 20 W4, 1 bagL, 3 bagS) |
| Rodopoli | 0 | 5 (2 bagL, 3 bagS) | 17 (1 HB1, 2 HB3, 9 HB5, 2 bagL, 3 bagS) | 63 (12 C1, 1 HB1, 2 HB3, 9 HB5, 34 W4, 2 bagL, 3 bagS) |
| Sofia | 0 | 4 (1 bagL, 3 bagS) | 18 (5 HB1, 2 HB3, 7 HB5, 1 bagL, 3 bagS) | 47 (2 C1, 5 HB1, 2 HB3, 11 HB5, 23 W4, 1 bagL, 3 bagS) |
| Therisa | 0 | 4 (1 bagL, 3 bagS) | 25 (7 HB1, 6 HB3, 8 HB5, 1 bagL, 3 bagS) | 73 (15 C1, 7 HB1, 6 HB3, 8 HB5, 33 W4, 1 bagL, 3 bagS) |

## What to check in the game

1. **Closure at T3 and T4**, above all where the line still relies on a building:
   - the trimmed faces above;
   - Sofia's east house (2 m of its north face is inside T3);
   - Neochori's north shop (T4 ties into its north-west and south-east faces);
   - Chalkeia's T4 east side (the ruin and the two big rocks; T4 didn't leak there in round 1).
2. **The three east-wall ties** next to the side door (above).
3. **Clips at the trimmed faces:** a run end cutting into a real wall means the trim was too deep.

## Line audit (the towns that changed)

Columns:

- **gap**: face to face.
- **ends tie into**: what each end meets. A run name means that run's piece; "corner" means a cross run ties into
  this end; "through X (low)" is a crossing.
- **end overlaps** and **joints**: in metres, against the fitted (solid) lengths in the six towns that leaked.

Kalochori, Molos and Rodopoli are as in REPORT_pass1.md.

### Chalkeia

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 33.06 | corner (a run ties into it) / corner (a run ties into it) | 7: HB5 + HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 35.6 | 0.09 / 0.09 | 0.39, 0.39, 0.39, 0.39, 0.39, 0.39 |
| north | T3 | 11.55 | run west / Land_u_Addon_02_V1_F | 5: HB3 + HB3 + HB3 + HB3 + HB1 | 13.9 | 0.57 / 0.14 | 0.41, 0.41, 0.41, 0.41 |
| south | T3 | 20.18 | run west / corner (a run ties into it) | 5: HB5 + HB3 + HB3 + HB5 + HB5 | 22.6 | 0.59 / 0.14 | 0.42, 0.42, 0.42, 0.42 |
| se | T3 | 10.60 | run south / the house | 3: HB5 + HB1 + HB5 | 11.9 | 0.5 / 0.1 | 0.35, 0.35 |
| e_s | T3 | 4.33 | corner (a run ties into it) / the house | 3: HB3 + HB1 + HB1 | 5.4 | 0.12 / 0.12 | 0.41, 0.41 |
| e1 | T3 | 8.28 | run e_s / corner (a run ties into it) | 3: HB3 + HB3 + HB3 | 9.6 | 0.53 / 0.05 | 0.37, 0.37 |
| e2 | T3 | 2.75 | run e1 / Land_u_Addon_02_V1_F | 2: HB3 + HB1 | 4.3 | 0.78 / 0.19 | 0.58 |
| o_w | T4 | 20.70 | Land_i_Garage_V2_F / Land_i_House_Big_01_V3_F | 7: W4 + W4 + W4 + C1 + W4 + W4 + W4 | 23.2 | 0.13 / 0.13 | 0.37, 0.37, 0.37, 0.37, 0.37, 0.37 |
| o_n | T4 | 20.00 | Land_i_House_Big_01_V3_F / corner (a run ties into it) | 6: W4 + W4 + W4 + W4 + W4 + W4 | 22.2 | 0.13 / 0.09 | 0.40, 0.40, 0.40, 0.40, 0.40 |
| o_ne | T4 | 4.45 | run o_n / Land_i_Shop_01_V2_F | 3: W4 + C1 + C1 | 5.7 | 0.37 / 0.13 | 0.38, 0.38 |
| o_e | T4 | 13.85 | Land_d_House_Small_01_V1_F / stone_big_f | 5: W4 + W4 + C1 + W4 + W4 | 15.8 | 0.14 / 0.14 | 0.42, 0.42, 0.42, 0.42 |
| o_s_w | T4 | 24.40 | Land_i_Shop_02_V2_F / corner (a run ties into it) | 9: W4 + W4 + W4 + C1 + C1 + W4 + W4 + W4 + W4 | 27.9 | 0.14 / 0.11 | 0.41, 0.41, 0.41, 0.41, 0.41, 0.41, 0.41, 0.41 |
| o_s_m | T4 | 2.25 | run o_s_w / Land_u_Addon_02_V1_F | 4: C1 + C1 + C1 + C1 | 4.0 | 0.39 / 0.14 | 0.41, 0.41, 0.41 |
| o_s_e | T4 | 12.55 | Land_u_Addon_02_V1_F / corner (a run ties into it) | 4: W4 + W4 + W4 + W4 | 14.8 | 0.18 / 0.41 | 0.55, 0.55, 0.55 |
| o_se | T4 | 11.05 | run o_s_e / stone_big_f | 5: W4 + C1 + C1 + W4 + W4 | 13.1 | 0.38 / 0.13 | 0.39, 0.39, 0.39, 0.39 |

### Charkia

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 16.28 | corner (a run ties into it) / Land_i_Garage_V1_dam_F | 5: HB5 + HB3 + HB3 + HB3 + HB3 | 18.2 | 0.13 / 0.14 | 0.41, 0.41, 0.41, 0.41 |
| south | T3 | 12.48 | run west / corner (a run ties into it) | 3: HB5 + HB3 + HB5 | 14.0 | 0.57 / 0.12 | 0.41, 0.41 |
| se | T3 | 5.85 | run south / the house | 3: HB3 + HB3 + HB1 | 7.5 | 0.62 / 0.14 | 0.45, 0.45 |
| north | T3 | 10.23 | Land_i_Garage_V1_dam_F / corner (a run ties into it) | 2: HB5 + HB5 | 10.8 | 0.13 / 0.06 | 0.38 |
| n_down | T3 | 2.70 | run north / the house | 2: HB3 + HB1 | 4.3 | 0.8 / 0.2 | 0.60 |
| e_top | T3 | 3.63 | corner (a run ties into it) / the house | 2: HB3 + HB1 | 4.3 | 0.13 / 0.13 | 0.41 |
| e_n | T3 | 8.38 | run e_top / corner (a run ties into it) | 3: HB3 + HB3 + HB3 | 9.6 | 0.5 / 0.01 | 0.35, 0.35 |
| e_w | T3 | 1.85 | run e_n / the house | 3: HB1 + HB1 + HB1 | 3.3 | 0.55 / 0.12 | 0.39, 0.39 |
| o_s | T4 | 29.40 | corner (a run ties into it) / corner (a run ties into it) | 9: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 33.3 | 0.18 / 0.18 | 0.44, 0.44, 0.44, 0.44, 0.44, 0.44, 0.44, 0.44 |
| o_h | T4 | 14.30 | run o_s / the house | 6: W4 + W4 + C1 + C1 + W4 + W4 | 16.8 | 0.39 / 0.12 | 0.40, 0.40, 0.40, 0.40, 0.40 |
| o_w | T4 | 38.05 | corner (a run ties into it) / run o_s | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.31 / 0.47 | 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51 |
| o_n_w | T4 | 27.20 | run o_w / through wired_fence_8m_f (low) | 9: W4 + W4 + W4 + W4 + C1 + W4 + W4 + W4 + W4 | 30.6 | 0.35 / 0.23 | 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35 |
| o_n_e | T4 | 11.90 | through wired_fence_8m_f (low) / corner (a run ties into it) | 6: W4 + C1 + C1 + C1 + W4 + W4 | 14.1 | 0.24 / 0.06 | 0.38, 0.38, 0.38, 0.38, 0.38 |
| o_e | T4 | 17.27 | run o_n_e / corner (a run ties into it) | 6: W4 + W4 + C1 + W4 + W4 + W4 | 19.5 | 0.36 / 0.03 | 0.37, 0.37, 0.37, 0.37, 0.37 |
| o_g | T4 | 7.80 | run o_e / the house | 4: W4 + C1 + C1 + W4 | 9.4 | 0.37 / 0.11 | 0.37, 0.37, 0.37 |

### Neochori

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 26.76 | corner (a run ties into it) / corner (a run ties into it) | 6: HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 30.2 | 0.38 / 0.38 | 0.54, 0.54, 0.54, 0.54, 0.54 |
| north | T3 | 16.68 | run west / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 19.4 | 0.73 / 0.38 | 0.54, 0.54, 0.54 |
| east | T3 | 24.98 | run north / corner (a run ties into it) | 5: HB5 + HB5 + HB5 + HB5 + HB5 | 27.0 | 0.52 / 0.03 | 0.37, 0.37, 0.37, 0.37 |
| south | T3 | 14.90 | run east / run west | 4: HB5 + HB3 + HB3 + HB5 | 17.2 | 0.56 / 0.56 | 0.40, 0.40, 0.40 |
| o_w2 | T4 | 10.30 | run west / Land_i_House_Small_01_V1_F | 4: W4 + C1 + W4 + W4 | 12.1 | 0.4 / 0.14 | 0.42, 0.42, 0.42 |
| o_wn | T4 | 14.15 | run west / corner (a run ties into it) | 6: W4 + W4 + C1 + C1 + W4 + W4 | 16.8 | 0.41 / 0.14 | 0.42, 0.42, 0.42, 0.42, 0.42 |
| o_n | T4 | 17.30 | run o_wn / Land_u_Shop_01_V1_F | 7: W4 + W4 + C1 + C1 + W4 + W4 + W4 | 20.5 | 0.42 / 0.15 | 0.44, 0.44, 0.44, 0.44, 0.44, 0.44 |
| o_ne | T4 | 12.85 | Land_u_Shop_01_V1_F / corner (a run ties into it) | 4: W4 + W4 + W4 + W4 | 14.8 | 0.17 / 0.29 | 0.50, 0.50, 0.50 |
| o_e | T4 | 34.50 | run o_ne / corner (a run ties into it) | 11: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 40.7 | 0.5 / 0.37 | 0.53, 0.53, 0.53, 0.53, 0.53, 0.53, 0.53, 0.53, 0.53, 0.53 |
| o_s | T4 | 39.85 | run o_e / city_4m_f | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.37 / 0.13 | 0.37, 0.37, 0.37, 0.37, 0.37, 0.37, 0.37, 0.37, 0.37, 0.37, 0.37 |

### Panochori

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 17.98 | corner (a run ties into it) / Land_i_House_Big_02_V3_F | 4: HB5 + HB3 + HB3 + HB5 | 18.8 | -0.39 / 0.3 | 0.30, 0.30, 0.30 |
| west | T3 | 21.48 | Land_i_House_Big_02_V3_F / corner (a run ties into it) | 4: HB5 + HB5 + HB5 + HB5 | 23.2 | 0.35 / 0.06 | 0.44, 0.44, 0.44 |
| nw | T3 | 3.45 | run west / Land_u_House_Small_02_V1_F | 4: HB1 + HB1 + HB1 + HB1 | 5.6 | 0.36 / 0.36 | 0.48, 0.48, 0.48 |
| ne | T3 | 4.78 | Land_u_House_Small_02_V1_F / corner (a run ties into it) | 2: HB3 + HB1 | 5.0 | 0.3 / -0.39 | 0.30 |
| east | T3 | 21.20 | run ne / run south | 4: HB5 + HB5 + HB5 + HB5 | 23.2 | 0.35 / 0.35 | 0.44, 0.44, 0.44 |
| o_w | T4 | 31.25 | Land_i_House_Big_02_V3_F / corner (a run ties into it) | 9: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 36.0 | 0.44 / 0.28 | 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 |
| o_n | T4 | 10.95 | run o_w / Land_u_House_Small_02_V1_F | 4: W4 + C1 + W4 + W4 | 13.0 | 0.38 / 0.38 | 0.43, 0.43, 0.43 |
| o_ne | T4 | 15.05 | Land_u_House_Small_02_V1_F / Land_i_House_Big_02_V3_F | 5: W4 + W4 + C1 + W4 + W4 | 17.0 | 0.32 / 0.32 | 0.33, 0.33, 0.33, 0.33 |
| o_e | T4 | 20.60 | Land_i_House_Big_01_V2_F / Land_i_House_Big_02_V2_F | 6: W4 + W4 + W4 + W4 + W4 + W4 | 24.0 | 0.44 / 0.44 | 0.51, 0.51, 0.51, 0.51, 0.51 |
| o_s | T4 | 7.20 | Land_i_House_Big_02_V3_F / Land_u_Addon_01_V1_F | 3: W4 + C1 + W4 | 9.0 | 0.42 / 0.42 | 0.48, 0.48 |

### Paros

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 34.76 | corner (a run ties into it) / corner (a run ties into it) | 7: HB5 + HB5 + HB5 + HB5 + HB5 + HB5 + HB5 | 37.8 | 0.19 / 0.19 | 0.44, 0.44, 0.44, 0.44, 0.44, 0.44 |
| sw | T3 | 5.35 | run west / Land_i_House_Small_02_V1_F | 2: HB3 + HB3 | 6.4 | 0.54 / 0.13 | 0.38 |
| nw | T3 | 2.45 | run west / Land_i_House_Big_02_V2_F | 1: HB3 | 3.2 | 0.6 / 0.15 |  |
| ne1 | T3 | 19.43 | Land_i_House_Small_01_V1_F / corner (a run ties into it) | 4: HB5 + HB5 + HB5 + HB5 | 21.6 | 0.18 / 0.38 | 0.54, 0.54, 0.54 |
| ne2 | T3 | 4.15 | run ne1 / Land_i_House_Big_02_V2_F | 4: HB3 + HB1 + HB1 + HB1 | 6.5 | 0.68 / 0.17 | 0.50, 0.50, 0.50 |
| o_s | T4 | 14.43 | corner (a run ties into it) / Land_i_House_Small_02_V1_F | 6: W4 + W4 + C1 + C1 + W4 + W4 | 16.8 | 0.14 / 0.14 | 0.42, 0.42, 0.42, 0.42, 0.42 |
| o_w | T4 | 38.80 | run o_s / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.43 / 0.2 | 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45 |
| o_n | T4 | 11.20 | run o_w / Land_i_House_Big_02_V2_F | 5: W4 + C1 + C1 + W4 + W4 | 13.1 | 0.35 / 0.12 | 0.36, 0.36, 0.36, 0.36 |
| o_e | T4 | 4.05 | city_pillar_f / city_8m_f | 2: W4 + C1 | 4.7 | 0.13 / 0.13 | 0.39 |

### Sofia

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 19.98 | Land_i_House_Big_02_V2_F / corner (a run ties into it) | 4: HB5 + HB5 + HB5 + HB5 | 21.6 | 0.15 / 0.17 | 0.43, 0.43, 0.43 |
| south | T3 | 14.08 | run west / corner (a run ties into it) | 3: HB5 + HB5 + HB5 | 16.2 | 0.71 / 0.35 | 0.53, 0.53 |
| se | T3 | 1.65 | run south / Land_i_House_Small_02_V2_F | 3: HB1 + HB1 + HB1 | 3.3 | 0.61 / 0.15 | 0.44, 0.44 |
| e1 | T3 | 7.20 | Land_i_House_Big_02_V2_F / Land_i_House_Small_02_V2_F | 4: HB3 + HB3 + HB1 + HB1 | 8.6 | 0.13 / 0.13 | 0.38, 0.38, 0.38 |
| o_w | T4 | 7.85 | run west / corner (a run ties into it) | 4: W4 + C1 + C1 + W4 | 9.4 | 0.37 / 0.05 | 0.38, 0.38, 0.38 |
| o_s | T4 | 38.60 | run o_w / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.44 / 0.23 | 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47 |
| o_e | T4 | 28.55 | run o_s / Land_i_Addon_03_V1_F | 9: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 33.3 | 0.48 / 0.17 | 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51 |

### Therisa

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 30.86 | corner (a run ties into it) / corner (a run ties into it) | 7: HB5 + HB5 + HB3 + HB3 + HB5 + HB5 + HB5 | 33.4 | 0.09 / 0.09 | 0.39, 0.39, 0.39, 0.39, 0.39, 0.39 |
| w | T3 | 9.70 | run south / Land_i_Addon_03_V1_F | 2: HB5 + HB5 | 10.8 | 0.56 / 0.14 | 0.40 |
| pass | T3 | 2.75 | Land_i_Addon_03_V1_F / the house | 4: HB1 + HB1 + HB1 + HB1 | 4.4 | 0.15 / 0.14 | 0.45, 0.45, 0.45 |
| se | T3 | 8.85 | run south / Land_i_Addon_03_V1_F | 4: HB3 + HB3 + HB3 + HB1 | 10.7 | 0.55 / 0.13 | 0.39, 0.39, 0.39 |
| n_e | T3 | 9.45 | Land_i_Addon_03_V1_F / Land_u_House_Small_01_V1_F | 4: HB5 + HB3 + HB1 + HB1 | 10.8 | 0.13 / 0.13 | 0.37, 0.37, 0.37 |
| o_s | T4 | 33.90 | Land_i_Addon_04_V1_F / Land_i_House_Big_02_V1_F | 11: W4 + W4 + W4 + W4 + W4 + C1 + W4 + W4 + W4 + W4 + W4 | 38.0 | 0.13 / 0.13 | 0.38, 0.38, 0.38, 0.38, 0.38, 0.38, 0.38, 0.38, 0.38, 0.38 |
| o_e | T4 | 21.00 | Land_u_Addon_02_V1_F / Land_i_House_Big_01_V2_F | 8: W4 + W4 + W4 + C1 + C1 + W4 + W4 + W4 | 24.2 | 0.14 / 0.14 | 0.42, 0.42, 0.42, 0.42, 0.42, 0.42, 0.42 |
| o_n | T4 | 45.48 | Land_i_House_Big_01_V2_F / corner (a run ties into it) | 14: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 51.8 | 0.15 / 0.22 | 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46 |
| o_nw | T4 | 4.40 | run o_n / city_8m_f | 3: W4 + C1 + C1 | 5.7 | 0.38 / 0.13 | 0.39, 0.39 |
| o_n1 | T4 | 3.55 | city_8m_f / city_8m_f | 6: C1 + C1 + C1 + C1 + C1 + C1 | 6.0 | 0.15 / 0.15 | 0.43, 0.43, 0.43, 0.43, 0.43 |
| o_w | T4 | 8.95 | Land_Kiosk_redburger_F / Land_u_Shop_02_V1_F | 6: W4 + C1 + C1 + C1 + C1 + W4 | 11.4 | 0.15 / 0.15 | 0.43, 0.43, 0.43, 0.43, 0.43 |

### Agios Dionysios

Unchanged but for the side-door bags; the audit is as in REPORT_pass1.md.

