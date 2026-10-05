# Towns: pass 1, round 3 report (answering pass1_round2.md)

The drafts and the script are pushed (7a2e76a). All 11 drafts pass `tl.check()` and the script's own checks: runs
fitted, piece middles clear, and T3, T4 and T4's outer ring alone walk closed from both doors. Only Chalkeia,
Neochori, Panochori and Paros changed. The seven towns you found closed are byte-identical to round 2. Nothing in
this round has been in the game yet. Coordinates are office model [x, y].

## What the round 2 routes show

In all three open towns, every route that got out is **identical at T2, T3 and T4**: the rings didn't change the
path at all. So none of these were gaps a ring could squeeze through. There were three causes.

1. **The track's lanes (Chalkeia).** The routes keep to the track's lanes, about 3.5-4 m either side of its
   middle. They run dead straight along x -8.2 from y 15 to -42, through:
   - the T3 north face (y 12);
   - the T3 south face (y -17.3);
   - T4's south-west wall (y -28).

   The T4 route at (-14.2, 26.2) is the other lane, through T4's north wall. Lines that run along a road held
   (Molos, Sofia, Rodopoli, Charkia). Lines that cross a lane didn't.

   Chalkeia also had five T3 routes your summary doesn't list (gap [], bearings 0, 45, 90, 270 and 315). They go from
   the house into the annexe and out of its north door: the annexe overlaps the house's north wall, and its rooms
   join the house's. From there they go round the ruin.
2. **The veranda steps.** The probe puts the main door in the house wall at (-1.8, -6.1), opening west onto the
   veranda. The steps come down off the veranda in front of it, at y ≈ -6.
   - **Neochori:** every route goes out of the door and down the steps to their foot at (-5.7, -6.1). That foot
     was inside the west face's band (0.6 m off the veranda), about 1 m from a joint.
   - **Panochori:** the ground drops 1.66 m there, so the steps reach about x -7.2. Its two clipping HBarrier_5
     were the pieces either side of the joint in front of them.
   - **Kalochori** held with its line 0.4 m off the veranda, but a piece's middle stands in front of its steps.
3. **Walk-through houses (Paros).** The routes go in at one door and out at another:
   - from the north yard into the big north house and out of its far end (and from its east end round the old
     city wall's end pillar);
   - from the side door's yard into the east house and out of its south side.

## The fixes

- **Chalkeia T3** keeps the track outside and doesn't use the annexe or the ruin's open ground:
  - **west face**: x -7.0 (y -17.3 to 17.4), east of the track's lane and clear of the steps' foot;
  - **north face**: y 17.4, north of the annexe's north door, ending on the west side of the ruin's rubble;
  - **north-east**: the rubble and the big rock close it;
  - **east face**: x 17.2, from that rock to the south one, as before;
  - **south face**: y -17.3, from the west face to the rock.

  No line ends on the office.
- **The ruin's box is trimmed to its rubble.** On the screenshot the rubble covers x 6-18, y 10-23 of a 20 x 20 m
  box. Round 2's T2 routes went round its west and north sides, so the rubble itself blocked them.
- **Chalkeia T4:**
  - a new wall from the shop's south face down to the rubble (x 9), because north of the rubble the ruin is
    open;
  - the rest stays as it was. Its north and south-west walls still cross the track, so its lanes may still go
    through them, but T3 now stands inside T4 with the track outside it.
- **Neochori:**
  - the west face stands at x -7.0 from the south corner to y -3.5. That is as far out as the road's paved core
    allows, 0.4 m beyond the steps' foot.
  - An HBarrier_5's middle stands in front of the steps (y -7.6 to -2.2), as at Kalochori. The joints are at
    y -7.25 and beyond.
  - North of the veranda it steps back to x -6.3 (west_n, tied into the west face), where the road bends in.
  - T4 stacks both 2-high, and its south walls move to x -7.0 with it.
- **Panochori:**
  - the west face is now at x -8.2 (round 2: -7.0). The pieces' middles stand at least 0.5 m beyond the steps'
    foot, and an HBarrier_5's middle is in front of them. The south face's end and the north-west run move with
    it. x -8.6 would clip the big south-west house.
  - **To watch:** the face now covers the track's east lane (about x -7.9). The line runs along the lane,
    which held elsewhere.
- **Paros T3** no longer uses either house:
  - **north face**: y 8.8, from the west face to x 12.5, just off the office's north wall, which has no door.
    The north yard, the broken old wall and the big house are outside.
  - **east face**: a short run at x 12.5 down to y 4.4.
  - **eh**: a run along the east house's north wall (y 4.4, from x 13.3 to 5.8) shuts its door off from the
    side door's yard. Its free end stands 0.2 m off the office, below the side door, which still opens into the
    yard.
- **Paros T4:** a wall across the gap between the old city wall's end pillar (13.1, 26.4) and the next stretch of
  city wall. Round 2's route came out of the big house's east end through that gap.

## What to check in the game

1. **Chalkeia:**
   - the north face's tie into the rubble's west side (round 2's routes passed just west of it);
   - the east face's tie into the big rock at (17.2, 11.0);
   - the south face's tie into the rock at (16, -17.3).
2. **Neochori:** whether the route still finds a way down the steps. If it does, the steps need a line on the
   veranda itself, because the road's core leaves no more room outside.
3. **Panochori:** the clips (the steps), and the track's lane along the west face.
4. **Paros:** the east house's door, against the new run along its north wall (eh), and the free end beside
   the side door.

## Counts (things per tier; each tier keeps the one below)

bagL/bagS: BagFence_Long/Short; HB5/3/1: HBarrier_5/3/1; W4: Mil_WallBig_4m; C1: CncWall1.

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Agios Dionysios | 0 | 5 (2 bagL, 3 bagS) | 33 (2 HB1, 14 HB3, 12 HB5, 2 bagL, 3 bagS) | 76 (1 C1, 2 HB1, 14 HB3, 12 HB5, 42 W4, 2 bagL, 3 bagS) |
| Chalkeia | 0 | 4 (2 bagL, 2 bagS) | 27 (2 HB1, 9 HB3, 12 HB5, 2 bagL, 2 bagS) | 75 (15 C1, 2 HB1, 9 HB3, 12 HB5, 33 W4, 2 bagL, 2 bagS) |
| Charkia | 0 | 4 (1 bagL, 3 bagS) | 27 (6 HB1, 12 HB3, 5 HB5, 1 bagL, 3 bagS) | 79 (9 C1, 6 HB1, 12 HB3, 5 HB5, 43 W4, 1 bagL, 3 bagS) |
| Kalochori | 0 | 5 (2 bagL, 3 bagS) | 23 (6 HB1, 3 HB3, 9 HB5, 2 bagL, 3 bagS) | 50 (5 C1, 6 HB1, 3 HB3, 9 HB5, 22 W4, 2 bagL, 3 bagS) |
| Molos | 0 | 5 (2 bagL, 3 bagS) | 19 (4 HB3, 10 HB5, 2 bagL, 3 bagS) | 54 (4 C1, 4 HB3, 10 HB5, 31 W4, 2 bagL, 3 bagS) |
| Neochori | 0 | 5 (2 bagL, 3 bagS) | 25 (5 HB3, 15 HB5, 2 bagL, 3 bagS) | 84 (16 C1, 6 HB3, 20 HB5, 37 W4, 2 bagL, 3 bagS) |
| Panochori | 0 | 5 (2 bagL, 3 bagS) | 21 (4 HB3, 12 HB5, 2 bagL, 3 bagS) | 56 (10 C1, 4 HB3, 12 HB5, 25 W4, 2 bagL, 3 bagS) |
| Paros | 0 | 4 (1 bagL, 3 bagS) | 21 (2 HB1, 5 HB3, 10 HB5, 1 bagL, 3 bagS) | 51 (9 C1, 2 HB1, 5 HB3, 10 HB5, 21 W4, 1 bagL, 3 bagS) |
| Rodopoli | 0 | 5 (2 bagL, 3 bagS) | 17 (1 HB1, 2 HB3, 9 HB5, 2 bagL, 3 bagS) | 63 (12 C1, 1 HB1, 2 HB3, 9 HB5, 34 W4, 2 bagL, 3 bagS) |
| Sofia | 0 | 4 (1 bagL, 3 bagS) | 21 (6 HB1, 2 HB3, 9 HB5, 1 bagL, 3 bagS) | 51 (3 C1, 6 HB1, 2 HB3, 13 HB5, 23 W4, 1 bagL, 3 bagS) |
| Therisa | 0 | 4 (1 bagL, 3 bagS) | 32 (10 HB1, 8 HB3, 10 HB5, 1 bagL, 3 bagS) | 84 (18 C1, 10 HB1, 8 HB3, 10 HB5, 34 W4, 1 bagL, 3 bagS) |

## Line audit (the four towns that changed)

Columns:

- **gap**: face to face.
- **ends tie into**: what each end meets. A run name means that run's piece; "corner" means a cross run ties into
  this end; "free" means the end stands on its own.
- **end overlaps** and **joints**: in metres, against the solid lengths.

The other towns are as in REPORT_pass1_round2.md.

### Chalkeia

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 36.46 | corner (a run ties into it) / corner (a run ties into it) | 8: HB5 + HB5 + HB5 + HB3 + HB5 + HB5 + HB5 + HB5 | 41.0 | 0.25 / 0.25 | 0.58, 0.58, 0.58, 0.58, 0.58, 0.58, 0.58 |
| north | T3 | 12.75 | run west / Land_d_House_Small_01_V1_F | 4: HB5 + HB3 + HB3 + HB3 | 15.0 | 0.57 / 0.14 | 0.51, 0.51, 0.51 |
| south | T3 | 20.45 | run west / stone_big_f | 6: HB5 + HB3 + HB3 + HB3 + HB3 + HB5 | 23.6 | 0.55 / 0.13 | 0.49, 0.49, 0.49, 0.49, 0.49 |
| east | T3 | 14.15 | Land_d_House_Small_01_V1_F / stone_big_f | 5: HB5 + HB3 + HB1 + HB1 + HB5 | 16.2 | 0.12 / 0.12 | 0.45, 0.45, 0.45, 0.45 |
| o_w | T4 | 20.70 | Land_i_Garage_V2_F / Land_i_House_Big_01_V3_F | 8: W4 + W4 + W4 + C1 + C1 + W4 + W4 + W4 | 24.2 | 0.12 / 0.12 | 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46 |
| o_n | T4 | 20.00 | Land_i_House_Big_01_V3_F / corner (a run ties into it) | 7: W4 + W4 + W4 + C1 + W4 + W4 + W4 | 23.2 | 0.13 / 0.09 | 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 |
| o_ne | T4 | 4.45 | run o_n / Land_i_Shop_01_V2_F | 4: W4 + C1 + C1 + C1 | 6.7 | 0.43 / 0.15 | 0.55, 0.55, 0.55 |
| o_nr | T4 | 3.85 | Land_i_Shop_01_V2_F / Land_d_House_Small_01_V1_F | 2: W4 + C1 | 4.7 | 0.15 / 0.15 | 0.55 |
| o_e | T4 | 13.00 | stone_big_f / stone_big_f | 4: W4 + W4 + W4 + W4 | 14.8 | 0.14 / 0.14 | 0.51, 0.51, 0.51 |
| o_s_w | T4 | 24.40 | Land_i_Shop_02_V2_F / corner (a run ties into it) | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 29.6 | 0.19 / 0.41 | 0.66, 0.66, 0.66, 0.66, 0.66, 0.66, 0.66 |
| o_s_m | T4 | 2.25 | run o_s_w / Land_u_Addon_02_V1_F | 5: C1 + C1 + C1 + C1 + C1 | 5.0 | 0.43 / 0.15 | 0.54, 0.54, 0.54, 0.54 |
| o_s_e | T4 | 12.55 | Land_u_Addon_02_V1_F / corner (a run ties into it) | 4: W4 + W4 + W4 + W4 | 14.8 | 0.17 / 0.29 | 0.60, 0.60, 0.60 |
| o_se | T4 | 11.05 | run o_s_e / stone_big_f | 6: W4 + C1 + C1 + C1 + W4 + W4 | 14.1 | 0.39 / 0.14 | 0.50, 0.50, 0.50, 0.50, 0.50 |

### Neochori

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 9.26 | corner (a run ties into it) / corner (a run ties into it) | 2: HB5 + HB5 | 10.8 | 0.44 / 0.44 | 0.67 |
| west_n | T3 | 17.08 | run west / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 19.4 | 0.59 / 0.15 | 0.53, 0.53, 0.53 |
| north | T3 | 16.78 | run west_n / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 19.4 | 0.65 / 0.25 | 0.57, 0.57, 0.57 |
| east | T3 | 24.98 | run north / corner (a run ties into it) | 6: HB5 + HB5 + HB3 + HB3 + HB5 + HB5 | 28.0 | 0.54 / 0.07 | 0.48, 0.48, 0.48, 0.48, 0.48 |
| south | T3 | 15.70 | run east / run west | 4: HB5 + HB3 + HB5 + HB5 | 19.4 | 0.8 / 0.8 | 0.70, 0.70, 0.70 |
| o_w2 | T4 | 2.60 | run west / corner (a run ties into it) | 5: C1 + C1 + C1 + C1 + C1 | 5.0 | 0.38 / 0.05 | 0.49, 0.49, 0.49, 0.49 |
| o_w3 | T4 | 2.40 | run o_w2 / city_4m_f | 5: C1 + C1 + C1 + C1 + C1 | 5.0 | 0.4 / 0.14 | 0.51, 0.51, 0.51, 0.51 |
| o_wn | T4 | 14.35 | run west_n / corner (a run ties into it) | 7: W4 + W4 + C1 + C1 + C1 + W4 + W4 | 17.8 | 0.39 / 0.09 | 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 |
| o_n | T4 | 17.40 | run o_wn / Land_u_Shop_01_V1_F | 8: W4 + W4 + C1 + C1 + C1 + W4 + W4 + W4 | 21.5 | 0.4 / 0.14 | 0.51, 0.51, 0.51, 0.51, 0.51, 0.51, 0.51 |
| o_ne | T4 | 12.85 | Land_u_Shop_01_V1_F / corner (a run ties into it) | 4: W4 + W4 + W4 + W4 | 14.8 | 0.15 / 0.18 | 0.54, 0.54, 0.54 |
| o_e | T4 | 34.50 | run o_ne / corner (a run ties into it) | 11: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 40.7 | 0.43 / 0.21 | 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56 |
| o_s | T4 | 39.85 | run o_e / city_4m_f | 13: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 48.1 | 0.5 / 0.18 | 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63 |

### Panochori

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 17.98 | corner (a run ties into it) / Land_i_House_Big_02_V3_F | 5: HB5 + HB3 + HB3 + HB3 + HB5 | 20.4 | 0.16 / 0.15 | 0.53, 0.53, 0.53, 0.53 |
| west | T3 | 19.58 | Land_i_House_Big_02_V3_F / corner (a run ties into it) | 4: HB5 + HB5 + HB5 + HB5 | 21.6 | 0.15 / 0.21 | 0.55, 0.55, 0.55 |
| nw | T3 | 4.65 | run west / Land_u_House_Small_02_V1_F | 1: HB5 | 5.4 | 0.6 / 0.15 |  |
| ne | T3 | 4.78 | Land_u_House_Small_02_V1_F / corner (a run ties into it) | 1: HB5 | 5.4 | 0.19 / 0.43 |  |
| east | T3 | 21.20 | run ne / run south | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 24.8 | 0.65 / 0.65 | 0.57, 0.57, 0.57, 0.57 |
| o_w | T4 | 31.25 | Land_i_House_Big_02_V3_F / corner (a run ties into it) | 10: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 37.0 | 0.16 / 0.28 | 0.59, 0.59, 0.59, 0.59, 0.59, 0.59, 0.59, 0.59, 0.59 |
| o_n | T4 | 10.95 | run o_w / Land_u_House_Small_02_V1_F | 6: W4 + C1 + C1 + C1 + W4 + W4 | 14.1 | 0.41 / 0.14 | 0.52, 0.52, 0.52, 0.52, 0.52 |
| o_ne | T4 | 15.05 | Land_u_House_Small_02_V1_F / Land_i_House_Big_02_V3_F | 8: W4 + W4 + C1 + C1 + C1 + C1 + W4 + W4 | 18.8 | 0.14 / 0.14 | 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 |
| o_e | T4 | 20.60 | Land_i_House_Big_01_V2_F / Land_i_House_Big_02_V2_F | 8: W4 + W4 + W4 + C1 + C1 + W4 + W4 + W4 | 24.2 | 0.13 / 0.13 | 0.48, 0.48, 0.48, 0.48, 0.48, 0.48, 0.48 |
| o_s | T4 | 7.20 | Land_i_House_Big_02_V3_F / Land_u_Addon_01_V1_F | 3: W4 + C1 + W4 | 8.4 | 0.13 / 0.13 | 0.47, 0.47 |

### Paros

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 23.56 | corner (a run ties into it) / corner (a run ties into it) | 5: HB5 + HB5 + HB5 + HB5 + HB5 | 27.0 | 0.41 / 0.41 | 0.66, 0.65, 0.65, 0.66 |
| sw | T3 | 5.35 | run west / Land_i_House_Small_02_V1_F | 2: HB5 + HB1 | 6.5 | 0.54 / 0.13 | 0.48 |
| north | T3 | 21.98 | run west / corner (a run ties into it) | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 24.8 | 0.59 / 0.14 | 0.52, 0.52, 0.52, 0.52 |
| eh | T3 | 8.48 | corner (a run ties into it) / free | 3: HB3 + HB3 + HB3 | 9.6 | 0.16 / -0.11 | 0.53, 0.53 |
| ne1 | T3 | 2.60 | run north / run eh | 2: HB3 + HB1 | 4.3 | 0.59 / 0.59 | 0.52 |
| o_s | T4 | 14.43 | corner (a run ties into it) / Land_i_House_Small_02_V1_F | 6: W4 + W4 + C1 + C1 + W4 + W4 | 16.8 | 0.0 / 0.12 | 0.45, 0.45, 0.45, 0.45, 0.45 |
| o_w | T4 | 38.80 | run o_s / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.37 / 0.04 | 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47 |
| o_n | T4 | 11.20 | run o_w / Land_i_House_Big_02_V2_F | 6: W4 + C1 + C1 + C1 + W4 + W4 | 14.1 | 0.37 / 0.13 | 0.48, 0.48, 0.48, 0.48, 0.48 |
| o_e | T4 | 4.05 | city_pillar_f / city_8m_f | 3: W4 + C1 + C1 | 5.7 | 0.18 / 0.18 | 0.64, 0.64 |
| o_ne | T4 | 4.25 | city_pillar_f / city_8m_f | 3: W4 + C1 + C1 | 5.7 | 0.16 / 0.16 | 0.57, 0.57 |

