# Villages: pass 1, round 2 report (walls; answering pass1_round1.md)

Commit `00529c2` on `layouts/villages`: the drafts and `tools/officegen/drafting/villages.py`.

- All 15 drafts pass `tl.check()`. My pass-1 wrapper round it is gone now that townlib skips the guard minimum.
- All ten tier 3 rings come out closed in the script's flood fill. The fill is finer now: 0.125 m cells and a man
  0.48 m across, so a 0.5 m gap lets him through. The old 0.25 m grid missed Telos' 0.55 m gap.
- **Unchanged:**
  - Lakka and Selakano, which the game passed. Their drafts are identical to round 1's.
  - Kore (see "Kore needs your call" below).
- **Agios Konstantinos:** the T2 BagFence_Short moved from x -4.9 to x -4.4, onto the porch.
- `python tools/officegen/drafting/villages.py --audit [--map] [town]` reprints everything below.

## What round 1's routes showed

I followed every way out in `measurements.md` to where it crosses the ring. I also overlaid the probe's boxes, the
model grid and the drafted pieces on the top views (the office's outline sits on its roof at 11.8 px/m). The
leaks fall into four causes.

1. **Line ends on a neighbour's probe box.** The box takes in eaves, porches and steps, and its walls stand
   1-3 m inside it, so the man walked round the end. From the top views:
   - Alikampos' left neighbour's north wall is at about y 5.4, against its box's 8.3.
   - Gravia's right-hand house (House_Big_01_V3) runs y -6.4..6.4 against its box's -7.1..8.7. That's the front
     2.3 m gap and the back 0.7 m one.
   - Neri's shop starts at y 0.5, against its box's -0.9.
   - Dorida's garage and Poliakko's shop are the same story.
2. **Pieces over the back porch's steps.** The house's footprint ends at the porch's edge (y -6.7), but its steps
   run on from there. Alikampos' porch stands 1.8 m above its back yard, and its routes go from (0.1, -8) straight
   through the middle of the 2-high back line. Stavros' do the same at (-1.4, -8.3). I read it as the man walking
   down the steps over the pieces placed on them. This is my inference, not something I could measure: please
   look at the steps on those two porches.
3. **Telos had a real 0.55 m gap** in its front line at x -0.2..0.4. Only the T2 sandbag stood in it.
4. **Kore: a road.** See below.

## What changed in the script

- **Buildings don't close a line any more.** Only city walls and the ring's own lines do. A ring now takes in the
  neighbours it touched, as one compound, as the brief's newer point allows.
- **Polygon rings** (`poly`, sides along x or y), so a ring can step round a neighbour, a planter or a road.
- **`walls`:** where a neighbour can't be taken in, its real walls read off the top view in model coordinates.
  - A line ends 0.45 m into them.
  - The pieces that reach into its probe box go in with `drop` (onto the ground under them), because townlib's
    box test can't tell walls from eaves.
  - The script's own clip test, from the old script's measured sizes, still runs against the real walls.
  - Each such piece is listed below, so your clip test can judge it.
- **`trust`:** keeps a neighbour's tie where it held in the game. That's Gravia's left side and Stavros' right
  side, which none of round 1's routes crossed.
- **No piece over the porch steps.** Their estimated reach is 1.4 m out per metre the porch stands above the
  ground, plus 0.6 m, over x -3..4. That's where the routes and Topolia's old porch clip put them.
- **Every piece is spaced by its measured length.**

## Per town

- **Alikampos:** a 39 x 21 m polygon round the office, its left neighbour (House_Big_01) and that house's shed.
  - The back line is at y -8.9, with a notch out to y -10.6 round the porch steps (x -3.9..4.9). That puts the
    notch about 0.7 m onto the street's visible edge, which isn't closed.
  - The right side is unchanged at x 8.
- **Dorida:** a rectangle x -13.5..17, y -8.95..10.7. It takes in the garage (the line between the garage and the
  shop) and the annex on the right. The city wall at x 15 is inside, lined at x 17.
- **Gravia:**
  - **Right line:** runs into the right-hand house's real walls, front and back (three pieces with drop).
  - **Left side:** as round 1, which held.
  - The block (the ruins and houses round it) leaves no free path round that house.
- **Neri:** a polygon round the office, its front annex and the shop on its right. The right line is at x 15.3,
  in the alley before the next buildings. The front line is at y 14.6, across the shop's forecourt (three pieces
  with drop). The back line is at y -10.5, stepping in round a planter.
- **Poliakko:** a polygon round the office and the shed on its left. The front line stays in front of the shop
  and steps round its box (y 9.6, then 6.9 west of x -10.6). No ties.
- **Stavros:**
  - **Back line:** moved out to y -9.6 past the steps, with a notch at y -7.8 for x -8..-4, where the probe's road
    comes within 3 m (`road_margin` 3, the margin Selakano passed with).
  - **Right side:** the two neighbours, as before.
- **Telos:**
  - **Gap:** filled.
  - **Front line:** runs across the front of the left neighbour (House_Small_01, real walls to y 5.1, box to 8.1;
    three pieces with drop).
  - **Right line:** moved to x 10.8, off a tree trunk that had left a 1 m slot at about (10, 3.5).

## Kore needs your call

Kore's back porch opens straight onto a road the probe doesn't list. In the top view it's the dirt road east of
the house, model y about -5.5..-15.5, running along x. Its west edge is at the porch's edge.

Both of Kore's ways out cross a 2-high piece standing on that road:
- (18.6, -9.1) across it;
- (2.3, -15.2) along it.

Their routes are identical to tier 2's, so I read it as the game's path search ignoring pieces on a road surface.
No ring can take in the porch without standing on or crossing that road. So Kore's ring is round 1's, unchanged.

Options:
- (a) Accept that closure can't be tested there.
- (b) Close the porch itself on its floor and treat the road side as the front for pass 2.
- (c) Let the ring close the road.

Tell me which. The same may be what happened at Alikampos' back line, which touched the street's edge.

## Counts (things per tier: the full snapshot)

| Town | T1 | T2 | T3 |
|---|---|---|---|
| Alikampos | 0 | 4 (3 BagLong, 1 BagShort) | 32 (3 BagLong, 1 BagShort, 11 HBBig, 1 HB5, 5 HB3, 11 HB1) |
| Dorida | 0 | 3 (2 BagLong, 1 BagShort) | 31 (2 BagLong, 1 BagShort, 7 HBBig, 4 HB5, 2 HB3, 15 HB1) |
| Gravia | 0 | 3 (2 BagLong, 1 BagShort) | 24 (2 BagLong, 1 BagShort, 4 HBBig, 3 HB5, 3 HB3, 11 HB1) |
| Kore | 0 | 3 (2 BagLong, 1 BagShort) | 23 (2 BagLong, 1 BagShort, 13 HBBig, 2 HB3, 5 HB1) |
| Lakka | 0 | 4 (3 BagLong, 1 BagShort) | 27 (3 BagLong, 1 BagShort, 8 HBBig, 1 HB5, 3 HB3, 11 HB1) |
| Neri | 0 | 2 (1 BagLong, 1 BagShort) | 26 (1 BagLong, 1 BagShort, 9 HBBig, 2 HB5, 2 HB3, 11 HB1) |
| Poliakko | 0 | 4 (3 BagLong, 1 BagShort) | 26 (3 BagLong, 1 BagShort, 10 HBBig, 2 HB3, 10 HB1) |
| Selakano | 0 | 3 (2 BagLong, 1 BagShort) | 36 (2 BagLong, 1 BagShort, 6 HBBig, 4 HB5, 6 HB3, 17 HB1) |
| Stavros | 0 | 3 (2 BagLong, 1 BagShort) | 26 (2 BagLong, 1 BagShort, 4 HBBig, 2 HB3, 17 HB1) |
| Telos | 0 | 4 (3 BagLong, 1 BagShort) | 29 (3 BagLong, 1 BagShort, 9 HBBig, 1 HB5, 6 HB3, 9 HB1) |
| Abdera | 0 | 2 (1 BagLong, 1 BagShort) | – |
| Agios Konstantinos | 0 | 4 (3 BagLong, 1 BagShort) | – |
| Galati | 0 | 3 (2 BagLong, 1 BagShort) | – |
| Nifi | 0 | 4 (3 BagLong, 1 BagShort) | – |
| Topolia | 0 | 3 (2 BagLong, 1 BagShort) | – |

No guards, statics, towers, gates, wire or props. Every T3 piece is an H-barrier; T2 is sandbags on the house.

## Line audit, tier 3

What the columns mean:
- **Gaps:** each line, end to end, is cut into the stretches between what already closes it (a city wall, a
  trusted neighbour or a neighbour's real walls within 1.2 m, or the next line at a corner).
- **Width:** the gap's length.
- **Run over it:** the metres the pieces cover.
- **Ties into:** what each end of the gap meets.
- **Run past the ends:** how far the pieces carry on past each end.
- **Open > 0.3 m:** stretches no piece crosses within 1.2 m of the line. All are at corners or beside a trunk or a
  wall, where a stepped-in piece closes them; the flood fill finds no way through any of them.

Lines are named back, front, left and right for rectangles. For polygons they are named by their fixed coordinate
and run.

### Alikampos

polygon (-31, -8.9) → (-3.9, -8.9) → (-3.9, -10.6) → (4.9, -10.6) → (4.9, -8.9) → (8, -8.9) → (8, 12) → (-31, 12). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -10.6 (-3.9..4.9) | -3.9..5.0 | 8.9 | 8.9 | corner / corner | 4.1 / 2.7 | – |
| y -8.9 (-31..-3.9) | -31.0..-3.8 | 27.2 | 27.2 | corner / corner | 1.1 / 4.1 | – |
| y -8.9 (4.9..8) | 4.9..8.1 | 3.2 | 3.2 | corner / corner | 4.1 / 1.2 | – |
| y 12 (-31..8) | -31.0..8.1 | 39.1 | 39.0 | corner / corner | 0.9 / 1.0 | – |
| x -31 (-8.9..12) | -8.9..12.1 | 21.0 | 21.0 | corner / corner | 1.2 / 1.1 | – |
| x -3.9 (-10.6..-8.9) | -10.6..-8.8 | 1.8 | 1.8 | corner / corner | 0.8 / 0.8 | – |
| x 4.9 (-10.6..-8.9) | -10.6..-8.8 | 1.8 | 1.8 | corner / corner | 0.8 / 0.7 | – |
| x 8 (-8.9..12) | -8.9..12.1 | 21.0 | 21.0 | corner / corner | 0.7 / 0.8 | – |

### Dorida

rectangle x -13.5..17, y -8.95..10.7. Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -13.5..14.8 | 28.3 | 28.3 | corner / city2_8m | 1.1 / 3.5 | – |
| back | 15.3..17.1 | 1.8 | 1.8 | city2_8m / corner | 4.1 / 1.2 | – |
| front | -13.5..17.1 | 30.6 | 30.6 | corner / corner | 0.9 / 0.9 | – |
| left | -8.9..10.8 | 19.7 | 19.7 | corner / corner | 0.8 / 0.5 | – |
| right | -8.9..10.8 | 19.7 | 19.7 | corner / corner | 0.7 / 0.8 | – |

### Gravia

rectangle x -9..9, y -13..11.2. Flood fill: closed. Pieces into a neighbour's probe box, placed with drop: HB1 at (9.0, -7.3), HB1 at (9.0, -6.6), HB3 at (9.0, 7.7).

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -7.6..9.1 | 16.7 | 16.7 | i_House_Big_01_V2 / corner | 0.8 / 0.8 | – |
| front | -9.0..9.1 | 18.1 | 18.1 | corner / corner | 0.9 / 1.3 | – |
| left | -8.0..-7.5 | 0.5 | 0.5 | i_House_Big_01_V2 / i_Shop_01_V3 | 2.6 / 4.1 | – |
| left | -7.1..5.6 | 12.7 | 12.7 | i_Shop_01_V3 / city_8md | 3.5 / 0.5 | – |
| left | 8.0..11.3 | 3.3 | 3.3 | city_8md / corner | 0.7 / 1.1 | – |
| right | -9.9..-6.4 | 3.5 | 3.5 | u_House_Small_02_V1 / i_House_Big_01_V3 | 4.1 / 0.6 | – |
| right | 6.4..11.3 | 4.9 | 4.9 | i_House_Big_01_V3 / corner | 0.5 / 0.8 | – |

Joints over 0.6 m: HBarrier_3@(7.7,11.2) x HBarrier_1@(9.0,10.4): 1.3 m along the first, 0.8 m along the second; HBarrier_1@(9.6,11.2) x HBarrier_1@(9.0,10.4): 0.8 m along the first, 0.7 m along the second.

### Kore

rectangle x -16..17.5, y -14..12. Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -16.0..17.6 | 33.6 | 33.6 | corner / corner | 1.2 / 1.1 | – |
| front | -16.0..17.6 | 33.6 | 32.7 | corner / corner | – / 1.3 | -16.0..-15.1 |
| left | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 1.1 / 0.0 | – |
| right | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 0.7 / 1.1 | – |

### Lakka

rectangle x -10..10, y -14..12. Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -10.0..10.1 | 20.1 | 20.1 | corner / corner | 0.9 / 1.2 | – |
| front | -10.0..3.6 | 13.6 | 13.6 | corner / i_Stone_HouseSmall_V2 | 0.9 / 1.9 | – |
| front | 8.5..10.1 | 1.6 | 1.6 | i_Stone_HouseSmall_V2 / corner | 2.8 / 1.0 | – |
| left | -14.0..12.1 | 26.1 | 25.6 | corner / corner | 1.2 / 1.1 | -7.8..-7.3 |
| right | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 0.7 / 0.7 | – |

Joints over 0.6 m: HBarrier_Big@(-8.8,-2.5) x HBarrier_1@(-8.8,-6.6): 0.9 m along the first, 1.4 m along the second.

### Neri

polygon (-10, -10.5) → (9.6, -10.5) → (9.6, -7.8) → (15.3, -7.8) → (15.3, 14.6) → (-10, 14.6). Flood fill: closed. Pieces into a neighbour's probe box, placed with drop: HBBig at (1.2, 14.6), HBBig at (9.2, 14.6), HB1 at (13.6, 14.6).

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -10.5 (-10..9.6) | -10.0..9.7 | 19.7 | 19.7 | corner / corner | 1.2 / 0.9 | – |
| y -7.8 (9.6..15.3) | 9.6..15.4 | 5.8 | 5.8 | corner / corner | 0.9 / 1.1 | – |
| y 14.6 (-10..15.3) | -10.0..15.4 | 25.4 | 25.4 | corner / corner | 0.9 / 0.9 | – |
| x -10 (-10.5..14.6) | -10.5..10.9 | 21.4 | 21.1 | corner / city_8m | 1.1 / – | 10.6..10.9 |
| x -10 (-10.5..14.6) | 11.4..14.7 | 3.3 | 3.3 | city_8m / corner | 0.5 / 1.2 | – |
| x 9.6 (-10.5..-7.8) | -10.5..-7.7 | 2.8 | 2.8 | corner / corner | 0.8 / 0.8 | – |
| x 15.3 (-7.8..14.6) | -7.8..11.3 | 19.1 | 19.1 | corner / city_4m | 0.8 / 4.1 | – |
| x 15.3 (-7.8..14.6) | 11.7..14.7 | 3.0 | 3.0 | city_4m / corner | 4.1 / 0.7 | – |

### Poliakko

polygon (-18, -13) → (7.3, -13) → (7.3, 9.6) → (-10.6, 9.6) → (-10.6, 6.9) → (-18, 6.9). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -13 (-18..7.3) | -18.0..7.4 | 25.4 | 25.4 | corner / corner | 1.2 / 1.1 | – |
| y 6.9 (-18..-10.6) | -18.0..-10.5 | 7.5 | 7.5 | corner / corner | 0.9 / 1.0 | – |
| y 9.6 (-10.6..7.3) | -10.6..7.4 | 18.0 | 18.0 | corner / corner | 0.9 / 1.4 | – |
| x -18 (-13..6.9) | -13.0..7.0 | 20.0 | 20.0 | corner / corner | 1.1 / 1.2 | – |
| x -10.6 (6.9..9.6) | 6.9..9.7 | 2.8 | 2.8 | corner / corner | 1.2 / 1.2 | – |
| x 7.3 (-13..9.6) | -13.0..9.7 | 22.7 | 22.7 | corner / corner | 0.7 / 0.8 | – |

### Selakano

rectangle x -17.5..15.5, y -9.9..12. Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -17.5..15.6 | 33.1 | 33.1 | corner / corner | 0.9 / 0.9 | – |
| front | -17.5..-15.2 | 2.3 | 1.8 | corner / city2_8m | – / 4.1 | -17.5..-17.0 |
| front | -10.1..15.6 | 25.7 | 25.6 | city2_8m / corner | 4.1 / 1.6 | – |
| left | -9.9..-7.7 | 2.2 | 2.2 | corner / city2_8m | 1.1 / 0.8 | – |
| left | 4.1..12.1 | 8.0 | 7.4 | city2_8m / corner | 4.1 / 0.7 | 10.7..11.3 |
| right | -9.9..12.1 | 22.0 | 22.0 | corner / corner | 0.8 / 0.7 | – |

### Stavros

polygon (-8, 12) → (-8, -7.8) → (-4, -7.8) → (-4, -9.6) → (5.5, -9.6) → (5.5, 12). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -9.6 (-4..5.5) | -4.0..5.6 | 9.6 | 9.6 | corner / corner | 3.3 / 0.7 | – |
| y -7.8 (-8..-4) | -8.0..-3.9 | 4.1 | 4.1 | corner / corner | 1.2 / 4.1 | – |
| y 12 (-8..5.5) | -8.0..5.6 | 13.6 | 13.6 | corner / corner | 0.9 / 1.0 | – |
| x -8 (-7.8..12) | -7.8..12.1 | 19.9 | 19.9 | corner / corner | 0.7 / 1.9 | – |
| x -4 (-9.6..-7.8) | -9.6..-7.7 | 1.9 | 1.9 | corner / corner | 1.1 / 0.7 | – |
| x 5.5 (-9.6..12) | – | – | – | neighbours 21.7 m | – | – |

Joints over 0.6 m: HBarrier_Big@(-8.0,4.8) x HBarrier_1@(-8.0,9.0): 0.7 m along the first, 0.7 m along the second; HBarrier_3@(3.8,12.0) x HBarrier_1@(5.5,11.3): 0.9 m along the first, 0.8 m along the second; HBarrier_1@(5.9,12.0) x HBarrier_1@(5.5,11.3): 1.1 m along the first, 0.7 m along the second.

### Telos

rectangle x -21..10.8, y -14..7.6. Flood fill: closed. Pieces into a neighbour's probe box, placed with drop: HBBig at (-17.7, 7.2), HBBig at (-9.7, 7.6), HB5 at (-3.1, 7.6).

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -21.0..10.9 | 31.9 | 31.9 | corner / corner | 0.9 / 1.1 | – |
| front | -21.0..10.9 | 31.9 | 31.9 | corner / corner | 0.9 / 1.0 | – |
| left | -14.0..-10.2 | 3.8 | 3.8 | corner / city_8m | 1.1 / 4.1 | – |
| left | -3.1..4.5 | 7.6 | 7.6 | city_8m / city_8m | 4.1 / 4.0 | – |
| left | 5.1..7.7 | 2.6 | 2.6 | city_8m / corner | 4.1 / 0.8 | – |
| right | -14.0..5.1 | 19.1 | 19.0 | corner / city_8m | 1.2 / 3.4 | – |
| right | 5.6..7.7 | 2.1 | 2.1 | city_8m / corner | 0.6 / 0.8 | – |

Joints over 0.6 m: HBarrier_Big@(-17.7,7.2) x HBarrier_1@(-21.0,6.1): 1.6 m along the first, 0.8 m along the second.

## What to check in the game

1. **Closure ("closed: no way out")**, most doubtful first:
   - **Gravia's right line** against the house's real walls at y ±6.4.
   - **Neri's front line** across the shop's forecourt.
   - **Telos' front line** before the left neighbour.
   - **Stavros' back notch** by the road.
   - **Alikampos' back notch** on the street's edge.
2. **Clips on the pieces placed with drop:** Gravia (9.0, -7.3), (9.0, -6.6), (9.0, 7.7); Neri (1.2, 14.6),
   (9.2, 14.6), (13.6, 14.6); Telos (-17.7, 7.2), (-9.7, 7.6), (-3.1, 7.6).
3. **The porch steps on Alikampos and Stavros:** whether the back lines now stand clear of them.
4. **Agios Konstantinos' porch bag** at x -4.4.
