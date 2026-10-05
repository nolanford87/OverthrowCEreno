# Towns: pass 1, round 6 report (answering pass1_check6.md)

The drafts and the script are pushed (69397be). All 11 drafts pass `tl.check()` and the script's own checks. Only
Paros changed. Nothing in this round has been in the game yet. Coordinates are office model [x, y].

## Paros: what the south-east was

There were no two runs meeting at that corner. The ring's south-east was the east house's box and the south-east
house's box (Land_i_House_Big_02_V1_F), which almost touched at (11.9, -10.7), so the script judged it closed. On
the check 6 screenshot the real walls are metres apart:

- The ground in front of the office runs on east as a dirt alley (y about -6.5 to -12) and a paved lane beside it
  (y about -12 to -15).
- They pass the east house's south porch (x 9.5-12.5, at the house's real south wall, about 2.4 m inside its box)
  and leave the ring at x 15-30.
- A way also leads south at x 11-17, across the north part of the south-east house's box (your routes cross it at
  (14.4, -16.3) and (17.2, -21)).

Your route goes in at the corner by the side door, through the east house, out of that porch at (13.1, -7.7), and
along the alley at (16.9, -11.2). The routes at bearings 180 and 225 turn south at (10.9, -12.5).

## The fix

The east house is a way through, so its porch has to stay inside: the ring now closes the alley and the lane east
of the porch.

- **cx**: x 13.8, from the east house's real south wall (y -8.0) across the alley and the lane to y -15
  (HBarrier_5 + HBarrier_3). It stands 1.3 m east of the porch.
- **cs**: y -15, from cx's end west along the lane's far side into the south house (HBarrier_3 + HBarrier_3 +
  HBarrier_1, tied at about x 7). It closes the way south.
- **Box trims** (both read off the check 6 screenshot):
  - the east house's south face, in 2.4 m to its real wall;
  - the south-east house's north face, in 6 m, because your routes cross its north part.
- **T4**: no outer line crosses the alley or the lane, so cx and cs are the outer line there too, stacked 2-high,
  as at Neochori and Sofia.

Round 5's sandbag on the east house's steps and the run along its north wall stay.

## What to check in the game

- **cx's tie into the east house's south wall.** The wall is read off the screenshot, so a gap or a clip there
  means the trim is off.
- **The cx/cs corner** at (13.8, -15), where your route passed at (14.4, -16.3).
- **The south house.** The lane is inside now, so the south house's north side faces the ring. If it has a door
  there and another outside, it would be a way through. In earlier rounds the ring's south-west run tied into it
  and held.

## Counts (each tier keeps the one below)

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Paros | 0 | 4 (1 bagL, 3 bagS) | 26 (3 HB1, 6 HB3, 12 HB5, 2 bagL, 3 bagS) | 61 (9 C1, 4 HB1, 9 HB3, 13 HB5, 21 W4, 2 bagL, 3 bagS) |

## Line audit (Paros T3: the runs round the south-east)

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| sw | T3 | 5.35 | run west / Land_i_House_Small_02_V1_F | 2: HB5 + HB1 | 6.5 | 0.54 / 0.13 | 0.48 |
| cx | T3 | 7.88 | Land_i_House_Small_01_V1_F / corner (a run ties into it) | 2: HB5 + HB3 | 8.6 | 0.13 / 0.09 | 0.50 |
| cs | T3 | 5.80 | run cx / Land_i_House_Small_02_V1_F | 3: HB3 + HB3 + HB1 | 7.5 | 0.56 / 0.14 | 0.50, 0.50 |
| eh | T3 | 7.68 | free / corner (a run ties into it) | 2: HB5 + HB3 | 8.6 | 0.04 / 0.29 | 0.59 |
