# Towns: pass 1, round 2 report (answering pass1_round1b.md and pass1_round1.md)

The drafts and the script are pushed (682c353): `tools/officegen/drafting/towns.py` and
`tools/officegen/layouts/drafts/<town>.txt`. All 11 drafts pass `tl.check()` and the script's own checks:

- every run fitted between its faces;
- piece middles clear of buildings, walls, rocks, the house and a road's paved core;
- T3, T4 and T4's outer ring alone walk closed from both doors.

Nothing in this round has been in the game yet. Coordinates are office model [x, y].

**The five towns found closed are kept as they are**: Agios Dionysios, Charkia, Kalochori, Molos and Rodopoli.
Their drafts are the same as d855ea0. Kalochori, Molos and Rodopoli are also still byte-identical to round 1
(e467ad2). Agios Dionysios changed only its side-door bags, as you asked. Charkia's rings are round 1's lines with
the solid fitting described below; the solid fitting only adds overlap.

## Round 1b's ways out, one by one

Two of round 1's causes still explain most of them:

- **Box-fitted joints.** The pieces were fitted to their measured boxes, so a planned overlap was nearly nil in the
  game. The routes crossed runs mid-line: Panochori's west run, Neochori's west run, and the T4 walls at Sofia
  (32.6, -4.8) and Chalkeia (-9, -30).
- **Ties into boxes that overstate a building.** The run ends in open ground: Neochori's o_w2, and Chalkeia's west
  run end and T4 south-west.

The new one is **routes through neighbour houses**: in by one door, out by another. That happened at Sofia's north
house, Chalkeia's east house and Panochori.

| town | way out (round 1b) | what it was | now |
|---|---|---|---|
| Chalkeia | T3 (-15.1, 13.8), T4 (-14.2, 26.2) | the north-west corner and the T4 north wall's joints (box fit) | solid fitting, joints 0.45-0.7 m |
| Chalkeia | T3 (11.4, 0.8) | the side-door yard: through the east house | the ring goes round the east house (below) |
| Chalkeia | T3 (-8.2, -22.2), T4 (-8.2 to -10.1, -30) | the south face's joints, and the south shop's overstated box | solid fitting; the shop's box trimmed 2.2 m (round 2); the T3 south face is now 2 m further north |
| Neochori | (-8.7, -4.7) / (-8.7, -2.5) | the west run's joints (box fit) | solid fitting |
| Neochori | (7.5, 2.8), T4 (27.8, -4.1) / (28.3, -7.2) | through the garage and the big east house | T3 is a box of its own round the house; T4 takes in both houses (round 2) |
| Neochori | (13.2, -12.2) | the old south-east corner | T3's south-east corner and T4's south wall (round 2), solid fitting |
| Neochori | (-7.7, -21.7) | T4's o_w2 tied into the south-west house's box, which runs 3 m past the house's west wall (there's only a tree) | o_w2 turns into the old city wall at y -14.5; the city wall runs on into the house |
| Panochori | (-8.7 to -8.9, -2.8 to 9.7) | the west run's joints (box fit), next to the veranda | solid fitting; the west run is 0.8 m further out (round 2) |
| Panochori | T4 (-11.4, 22.5), (-11.5, -10.5) | the T4 north-west corner and the west wall's joints (box fit) | solid fitting |
| Paros | (11.1-12.6, 19.8-20.1), (12.8, 3.5), T4 (-5.9, -17.7) | overstated boxes (the big north house, the east house, the south house) | trimmed, and the north yard closed by an L (round 2) |
| Sofia | (20.1-20.8, 3.3-4) | the old east-gap run in open yard | replaced by a run at x 8.5 (round 2) |
| Sofia | (8.1, 7.7) and on to (-9.9, 13.1) | through the north house: in from the side door's yard, out of its door onto the road | a run on the road verge (x -9.0, y 8 to 18.6) closes that door |
| Sofia | (-11.4, -4.5), T4 (32.6, -4.8), (-8.4, -22.1) | the west run's, the T4 east wall's and the T4 south-west corner's joints (box fit) | solid fitting |
| Therisa | (7.2, 8.4) | north out of the side door's yard, between the north annexe and the north-east house, which stand apart | the yard is closed by its own L (y 9.5, then x 13 down to the canal wall); both houses are outside T3 |
| Therisa | (-6.8, -6.4) | the run between the south-west shop and the annexe stood in the open (7 m inside the shop's box) | the plaza's own west face at x -13.5, and a run closing the passage by the veranda (round 2) |
| Therisa | T4 (-26.6, -8.6) | the west shop's overstated box | trimmed 2.5 m (round 2) |

## Every office door opens inside the ring, and no line ends on a door wall

The office has two doors, as the probe records them:

- **The main door**, under the veranda, facing south (-3.3, -7.3). The veranda is open south and west.
- **The side door**, in the east wall (4.9, 5.6).

So the house's south and west sides (the veranda) and its east wall all have a door. The north wall and the north-
west room's west wall (x -4.7, y 0.5 to 7.8, beside the veranda) have none. The leak walk starts at both doors
(the veranda and outside the side door), so a closed ring means both open inside it.

**In the six open towns, no line ends on a door wall now.** The one line that still meets the office is Therisa's
pass run, at y 3 into the north-west room's west wall, which has no door. The veranda's open side is south of it,
inside the ring.

- **Chalkeia** changed most. Round 2 tied its side-door yard into the east wall (y 1.2) and the south-east run into
  the house's south wall. Now the ring goes round:
  - the north side runs from the annexe east along y 9.0, past the ruin's south side (the ruin is open: round 1b's
    tier 2 route crossed it), to x 17.2;
  - the east side runs down x 17.2 to the big rock;
  - the south face runs on east at y -17.3 into the rock. That is 2 m north of round 2's line, just north of the
    old stone wall's end, so it doesn't cross the wall.
  - The east house, whose doors the earlier routes used, is now wholly inside.
  - T4's east wall moves 1 m out (x 19) to clear the new T3 east face.
- **Charkia is not changed.** Five of its lines still end on a door wall:
  - T3 se and T4 o_h, on the south wall east of the veranda;
  - T3 e_top and e_w, on the east wall, either side of the side door (they box it in);
  - T4 o_g, on the east wall below the window.

  (n_down ends on the north wall, which has no door.)

  Your new start points found it closed at T3 and T4, and its east side is boxed in by the old garden walls. Moving
  those lines off the house means redrawing a ring the game has passed. **Say if the rule applies to the closed
  towns too, and Charkia is next.**

## What changed in the script

- **Joints**: the solid fitting overlaps pieces by 0.45-0.7 m (round 2: 0.35-0.6). Panochori moves from round 1's
  box fitting to the solid one. Charkia keeps round 2's 0.35-0.6 m, because the wider joints would push its T4
  north-east wall into the garden's wire fence. The towns found closed under the box fitting keep it (Agios
  Dionysios, Kalochori, Molos, Rodopoli).
- **Box trims**: round 2's trims stand. One is new: Sofia's north house (Land_i_House_Big_02_V2_F), west face, 4.4 m.
  It lets the verge run stand between the house and the road.

| where | overlap (solid fitting) |
|---|---|
| joints | 0.45-0.7 m |
| into another run's piece | 0.5-0.8 m (walls 0.35-0.55 m) |
| corners | flush with the cross run's outer face, or up to 0.5 m past it |
| into a building | 0.12-0.2 m past the face; townlib's 6.0 m HBarrier_5 box leaves no more |
| into the house | 0.1-0.2 m |

### Per town (this round on top of round 2)

- **Chalkeia**: round the east house, as above.
- **Neochori**: T4's o_w2 is 2.6 m now, with a 1.9 m run (o_w3) east into the old city wall at y -14.5. The rest is
  round 2's.
- **Panochori**: the solid fitting. Round 2 already moved the west face and the north-west run off the office
  (1.2 m off the veranda).
- **Paros**: as round 2, with the wider joints.
- **Sofia**:
  - The verge run "door": x -9.0, y 8 to 18.6, past the north house's road door.
  - Round 2's e1 at x 8.5 still closes the side door's yard on the east.
- **Therisa**: the side door's yard has its own L, n_n (y 9.5, from the north-west city wall east to x 13) and n_e
  (x 13, down to the canal wall). Round 2's n_e at x 15.5 ran into the north-east house, which the route went round.

### The pieces (pass1_round1.md)

- **Side-door sandbags**: Agios Dionysios's and Chalkeia's stand 2.6 m out from the door (round 1: 1.85 m).
  Charkia, Paros, Sofia and Therisa use the short bag there.
- **Panochori's H-barriers**: the west face is at x -7.0 (round 1: -6.2) and the north-west run is 1.3 m off the
  house. Round 1 measured both cutting into the office.

### The newer brief points

- **Upgrading existing walls**: not used yet. No piece stands in a real wall along its length.
- **Walling in the compound**: Neochori's T4 takes in the garage and the big house; Therisa's takes in the walled
  garden; Chalkeia's T3 now takes in the east house.

## What to check in the game

1. **Closure at T3 and T4** in the six towns, above all where a line relies on a building or a rock:
   - **Chalkeia's south face into the big rock** at (16, -17.3). On the top-down screenshot the boulders end about
     1 m short of the box's face there, by the east house's south-east corner. The rock and the house look to touch,
     but this is the point most likely to leak. Its east face's tie into the same rock, at (17.2, -4.5), meets the
     boulders.
   - **Sofia's verge run**, against the north house's road face (the trim).
   - **Neochori's o_w3**, into the old city wall.
   - The trimmed faces (round 2's table and Sofia's new one).
2. **Clips**: a run end cutting into a real wall means its trim was too deep.
3. **Charkia's house ties** (above), if the rule covers the closed towns.

## Counts (things per tier; each tier keeps the one below)

bagL/bagS: BagFence_Long/Short; HB5/3/1: HBarrier_5/3/1; W4: Mil_WallBig_4m; C1: CncWall1.

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Agios Dionysios | 0 | 5 (2 bagL, 3 bagS) | 33 (2 HB1, 14 HB3, 12 HB5, 2 bagL, 3 bagS) | 76 (1 C1, 2 HB1, 14 HB3, 12 HB5, 42 W4, 2 bagL, 3 bagS) |
| Chalkeia | 0 | 4 (2 bagL, 2 bagS) | 29 (2 HB1, 6 HB3, 17 HB5, 2 bagL, 2 bagS) | 75 (14 C1, 2 HB1, 6 HB3, 17 HB5, 32 W4, 2 bagL, 2 bagS) |
| Charkia | 0 | 4 (1 bagL, 3 bagS) | 27 (6 HB1, 12 HB3, 5 HB5, 1 bagL, 3 bagS) | 79 (9 C1, 6 HB1, 12 HB3, 5 HB5, 43 W4, 1 bagL, 3 bagS) |
| Kalochori | 0 | 5 (2 bagL, 3 bagS) | 23 (6 HB1, 3 HB3, 9 HB5, 2 bagL, 3 bagS) | 50 (5 C1, 6 HB1, 3 HB3, 9 HB5, 22 W4, 2 bagL, 3 bagS) |
| Molos | 0 | 5 (2 bagL, 3 bagS) | 19 (4 HB3, 10 HB5, 2 bagL, 3 bagS) | 54 (4 C1, 4 HB3, 10 HB5, 31 W4, 2 bagL, 3 bagS) |
| Neochori | 0 | 5 (2 bagL, 3 bagS) | 25 (1 HB1, 4 HB3, 15 HB5, 2 bagL, 3 bagS) | 77 (8 C1, 1 HB1, 5 HB3, 20 HB5, 38 W4, 2 bagL, 3 bagS) |
| Panochori | 0 | 5 (2 bagL, 3 bagS) | 24 (2 HB1, 6 HB3, 11 HB5, 2 bagL, 3 bagS) | 59 (10 C1, 2 HB1, 6 HB3, 11 HB5, 25 W4, 2 bagL, 3 bagS) |
| Paros | 0 | 4 (1 bagL, 3 bagS) | 22 (4 HB1, 2 HB3, 12 HB5, 1 bagL, 3 bagS) | 49 (7 C1, 4 HB1, 2 HB3, 12 HB5, 20 W4, 1 bagL, 3 bagS) |
| Rodopoli | 0 | 5 (2 bagL, 3 bagS) | 17 (1 HB1, 2 HB3, 9 HB5, 2 bagL, 3 bagS) | 63 (12 C1, 1 HB1, 2 HB3, 9 HB5, 34 W4, 2 bagL, 3 bagS) |
| Sofia | 0 | 4 (1 bagL, 3 bagS) | 21 (6 HB1, 2 HB3, 9 HB5, 1 bagL, 3 bagS) | 51 (3 C1, 6 HB1, 2 HB3, 13 HB5, 23 W4, 1 bagL, 3 bagS) |
| Therisa | 0 | 4 (1 bagL, 3 bagS) | 32 (10 HB1, 8 HB3, 10 HB5, 1 bagL, 3 bagS) | 84 (18 C1, 10 HB1, 8 HB3, 10 HB5, 34 W4, 1 bagL, 3 bagS) |

## Line audit (the six open towns)

Columns:

- **gap**: face to face.
- **ends tie into**: what each end meets. A run name means that run's piece; "corner" means a cross run ties into
  this end.
- **end overlaps** and **joints**: in metres, against the solid lengths.

The closed towns' audits are as in REPORT_pass1.md (Kalochori, Molos and Rodopoli, and Agios Dionysios's rings). Charkia's is in the
round 2 report at 8d968dd.

### Chalkeia

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 31.06 | corner (a run ties into it) / corner (a run ties into it) | 7: HB5 + HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 35.6 | 0.37 / 0.37 | 0.63, 0.63, 0.63, 0.63, 0.63, 0.63 |
| north | T3 | 11.55 | run west / Land_u_Addon_02_V1_F | 5: HB5 + HB3 + HB3 + HB1 + HB1 | 14.0 | 0.51 / 0.12 | 0.46, 0.46, 0.46, 0.46 |
| south | T3 | 30.45 | run west / stone_big_f | 7: HB5 + HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 35.6 | 0.79 / 0.2 | 0.69, 0.69, 0.69, 0.69, 0.69, 0.69 |
| e_n | T3 | 12.78 | Land_u_Addon_02_V1_F / corner (a run ties into it) | 3: HB5 + HB3 + HB5 | 14.0 | 0.13 / 0.09 | 0.50, 0.50 |
| east | T3 | 11.95 | run e_n / stone_big_f | 3: HB5 + HB3 + HB5 | 14.0 | 0.68 / 0.17 | 0.60, 0.60 |
| o_w | T4 | 20.70 | Land_i_Garage_V2_F / Land_i_House_Big_01_V3_F | 8: W4 + W4 + W4 + C1 + C1 + W4 + W4 + W4 | 24.2 | 0.12 / 0.12 | 0.46, 0.46, 0.46, 0.46, 0.46, 0.46, 0.46 |
| o_n | T4 | 20.00 | Land_i_House_Big_01_V3_F / corner (a run ties into it) | 7: W4 + W4 + W4 + C1 + W4 + W4 + W4 | 23.2 | 0.13 / 0.09 | 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 |
| o_ne | T4 | 4.45 | run o_n / Land_i_Shop_01_V2_F | 4: W4 + C1 + C1 + C1 | 6.7 | 0.43 / 0.15 | 0.55, 0.55, 0.55 |
| o_e | T4 | 13.00 | stone_big_f / stone_big_f | 4: W4 + W4 + W4 + W4 | 14.8 | 0.14 / 0.14 | 0.51, 0.51, 0.51 |
| o_s_w | T4 | 24.40 | Land_i_Shop_02_V2_F / corner (a run ties into it) | 8: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 29.6 | 0.19 / 0.41 | 0.66, 0.66, 0.66, 0.66, 0.66, 0.66, 0.66 |
| o_s_m | T4 | 2.25 | run o_s_w / Land_u_Addon_02_V1_F | 5: C1 + C1 + C1 + C1 + C1 | 5.0 | 0.43 / 0.15 | 0.54, 0.54, 0.54, 0.54 |
| o_s_e | T4 | 12.55 | Land_u_Addon_02_V1_F / corner (a run ties into it) | 4: W4 + W4 + W4 + W4 | 14.8 | 0.17 / 0.29 | 0.60, 0.60, 0.60 |
| o_se | T4 | 11.05 | run o_s_e / stone_big_f | 6: W4 + C1 + C1 + C1 + W4 + W4 | 14.1 | 0.39 / 0.14 | 0.50, 0.50, 0.50, 0.50, 0.50 |

### Neochori

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 26.76 | corner (a run ties into it) / corner (a run ties into it) | 6: HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 30.2 | 0.26 / 0.26 | 0.58, 0.58, 0.58, 0.58, 0.58 |
| north | T3 | 16.68 | run west / corner (a run ties into it) | 4: HB5 + HB3 + HB5 + HB5 | 19.4 | 0.67 / 0.28 | 0.59, 0.59, 0.59 |
| east | T3 | 24.98 | run north / corner (a run ties into it) | 6: HB5 + HB5 + HB3 + HB3 + HB5 + HB5 | 28.0 | 0.54 / 0.07 | 0.48, 0.48, 0.48, 0.48, 0.48 |
| south | T3 | 14.90 | run east / run west | 4: HB5 + HB1 + HB5 + HB5 | 17.3 | 0.51 / 0.51 | 0.46, 0.46, 0.46 |
| o_w2 | T4 | 2.75 | run west / corner (a run ties into it) | 1: W4 | 3.7 | 0.52 / 0.43 |  |
| o_w3 | T4 | 1.50 | run o_w2 / city_4m_f | 3: C1 + C1 + C1 | 3.0 | 0.38 / 0.13 | 0.49, 0.49 |
| o_wn | T4 | 14.25 | run west / corner (a run ties into it) | 7: W4 + W4 + C1 + C1 + C1 + W4 + W4 | 17.8 | 0.4 / 0.11 | 0.51, 0.51, 0.51, 0.51, 0.51, 0.51 |
| o_n | T4 | 17.30 | run o_wn / Land_u_Shop_01_V1_F | 7: W4 + W4 + C1 + C1 + W4 + W4 + W4 | 20.5 | 0.35 / 0.12 | 0.45, 0.45, 0.45, 0.45, 0.45, 0.45 |
| o_ne | T4 | 12.85 | Land_u_Shop_01_V1_F / corner (a run ties into it) | 4: W4 + W4 + W4 + W4 | 14.8 | 0.15 / 0.18 | 0.54, 0.54, 0.54 |
| o_e | T4 | 34.50 | run o_ne / corner (a run ties into it) | 11: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 40.7 | 0.43 / 0.21 | 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56, 0.56 |
| o_s | T4 | 39.85 | run o_e / city_4m_f | 13: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 48.1 | 0.5 / 0.18 | 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63, 0.63 |

### Panochori

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 17.98 | corner (a run ties into it) / Land_i_House_Big_02_V3_F | 5: HB5 + HB3 + HB3 + HB3 + HB5 | 20.4 | 0.16 / 0.15 | 0.53, 0.53, 0.53, 0.53 |
| west | T3 | 21.48 | Land_i_House_Big_02_V3_F / corner (a run ties into it) | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 24.8 | 0.19 / 0.44 | 0.67, 0.67, 0.67, 0.67 |
| nw | T3 | 3.45 | run west / Land_u_House_Small_02_V1_F | 3: HB3 + HB1 + HB1 | 5.4 | 0.65 / 0.16 | 0.57, 0.57 |
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
| west | T3 | 34.76 | corner (a run ties into it) / corner (a run ties into it) | 7: HB5 + HB5 + HB5 + HB5 + HB5 + HB5 + HB5 | 37.8 | 0.07 / 0.07 | 0.48, 0.48, 0.48, 0.48, 0.48, 0.48 |
| sw | T3 | 5.35 | run west / Land_i_House_Small_02_V1_F | 2: HB5 + HB1 | 6.5 | 0.54 / 0.13 | 0.48 |
| nw | T3 | 2.45 | run west / Land_i_House_Big_02_V2_F | 1: HB3 | 3.2 | 0.6 / 0.15 |  |
| ne1 | T3 | 19.43 | Land_i_House_Small_01_V1_F / corner (a run ties into it) | 4: HB5 + HB5 + HB5 + HB5 | 21.6 | 0.16 / 0.26 | 0.58, 0.58, 0.58 |
| ne2 | T3 | 4.15 | run ne1 / Land_i_House_Big_02_V2_F | 4: HB3 + HB1 + HB1 + HB1 | 6.5 | 0.6 / 0.15 | 0.53, 0.53, 0.53 |
| o_s | T4 | 14.43 | corner (a run ties into it) / Land_i_House_Small_02_V1_F | 6: W4 + W4 + C1 + C1 + W4 + W4 | 16.8 | 0.0 / 0.12 | 0.45, 0.45, 0.45, 0.45, 0.45 |
| o_w | T4 | 38.80 | run o_s / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.37 / 0.04 | 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47 |
| o_n | T4 | 11.20 | run o_w / Land_i_House_Big_02_V2_F | 6: W4 + C1 + C1 + C1 + W4 + W4 | 14.1 | 0.37 / 0.13 | 0.48, 0.48, 0.48, 0.48, 0.48 |
| o_e | T4 | 4.05 | city_pillar_f / city_8m_f | 3: W4 + C1 + C1 | 5.7 | 0.18 / 0.18 | 0.64, 0.64 |

### Sofia

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| west | T3 | 19.98 | Land_i_House_Big_02_V2_F / corner (a run ties into it) | 4: HB5 + HB5 + HB5 + HB5 | 21.6 | 0.13 / 0.06 | 0.48, 0.48, 0.48 |
| door | T3 | 9.75 | run west / free | 2: HB5 + HB5 | 10.8 | 0.6 / -0.09 | 0.54 |
| south | T3 | 14.08 | run west / corner (a run ties into it) | 3: HB5 + HB5 + HB5 | 16.2 | 0.67 / 0.28 | 0.59, 0.59 |
| se | T3 | 1.65 | run south / Land_i_House_Small_02_V2_F | 3: HB1 + HB1 + HB1 | 3.3 | 0.54 / 0.13 | 0.49, 0.49 |
| e1 | T3 | 7.20 | Land_i_House_Big_02_V2_F / Land_i_House_Small_02_V2_F | 5: HB3 + HB3 + HB1 + HB1 + HB1 | 9.7 | 0.15 / 0.15 | 0.55, 0.55, 0.55, 0.55 |
| o_w | T4 | 7.95 | run west / corner (a run ties into it) | 5: W4 + C1 + C1 + C1 + W4 | 10.4 | 0.39 / 0.09 | 0.49, 0.49, 0.49, 0.49 |
| o_s | T4 | 38.60 | run o_w / corner (a run ties into it) | 12: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 44.4 | 0.38 / 0.07 | 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49 |
| o_e | T4 | 28.55 | run o_s / Land_i_Addon_03_V1_F | 9: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 33.3 | 0.41 / 0.14 | 0.52, 0.52, 0.52, 0.52, 0.52, 0.52, 0.52, 0.52 |

### Therisa

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| south | T3 | 30.86 | corner (a run ties into it) / corner (a run ties into it) | 7: HB5 + HB5 + HB5 + HB3 + HB5 + HB5 + HB5 | 35.6 | 0.41 / 0.41 | 0.65, 0.65, 0.65, 0.65, 0.65, 0.65 |
| w | T3 | 9.70 | run south / Land_i_Addon_03_V1_F | 2: HB5 + HB5 | 10.8 | 0.51 / 0.12 | 0.46 |
| pass | T3 | 2.75 | Land_i_Addon_03_V1_F / the house | 4: HB1 + HB1 + HB1 + HB1 | 4.4 | 0.13 / 0.11 | 0.47, 0.47, 0.47 |
| se | T3 | 8.85 | run south / Land_i_Addon_03_V1_F | 5: HB3 + HB3 + HB3 + HB1 + HB1 | 11.8 | 0.62 / 0.15 | 0.55, 0.55, 0.55, 0.55 |
| n_n | T3 | 18.73 | city_8m_f / corner (a run ties into it) | 6: HB5 + HB3 + HB3 + HB3 + HB1 + HB5 | 21.5 | 0.14 / 0.11 | 0.50, 0.50, 0.50, 0.50, 0.50 |
| n_e | T3 | 4.00 | run n_n / canal_wallsmall_10m_f | 4: HB3 + HB1 + HB1 + HB1 | 6.5 | 0.64 / 0.16 | 0.57, 0.57, 0.57 |
| o_s | T4 | 33.90 | Land_i_Addon_04_V1_F / Land_i_House_Big_02_V1_F | 11: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 40.7 | 0.18 / 0.18 | 0.64, 0.64, 0.64, 0.64, 0.64, 0.64, 0.64, 0.64, 0.64, 0.64 |
| o_e | T4 | 21.00 | Land_u_Addon_02_V1_F / Land_i_House_Big_01_V2_F | 9: W4 + W4 + W4 + C1 + C1 + C1 + W4 + W4 + W4 | 25.2 | 0.13 / 0.13 | 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49, 0.49 |
| o_n | T4 | 45.48 | Land_i_House_Big_01_V2_F / corner (a run ties into it) | 14: W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 + W4 | 51.8 | 0.13 / 0.05 | 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47 |
| o_nw | T4 | 4.40 | run o_n / city_8m_f | 4: W4 + C1 + C1 + C1 | 6.7 | 0.44 / 0.16 | 0.57, 0.57, 0.57 |
| o_n1 | T4 | 3.55 | city_8m_f / city_8m_f | 7: C1 + C1 + C1 + C1 + C1 + C1 + C1 | 7.0 | 0.14 / 0.14 | 0.53, 0.53, 0.53, 0.53, 0.53, 0.53 |
| o_w | T4 | 8.95 | Land_Kiosk_redburger_F / Land_u_Shop_02_V1_F | 7: W4 + C1 + C1 + C1 + C1 + C1 + W4 | 12.4 | 0.14 / 0.14 | 0.53, 0.53, 0.53, 0.53, 0.53, 0.53 |

