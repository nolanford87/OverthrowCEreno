# Villages: pass 1, round 3 report (walls; answering pass1_round2.md)

Commit `0b2f53a` on `layouts/villages`: the drafts and `tools/officegen/drafting/villages.py`.

- All 15 drafts pass `tl.check()`.
- All ten tier 3 rings come out closed in the script's flood fill.
- **Unchanged since round 2, as the game closed them:** Lakka, Poliakko and Stavros. Their drafts are identical.
  The new rules below are switched off or don't reach them.
- **Kore** gets two corner pieces from the gap plugger, but its road problem stands (see "Kore, again").
- `python tools/officegen/drafting/villages.py --audit [--map] [town]` reprints everything below.

## What round 2's routes showed

I followed every way out in `measurements.md`. "Front" in your critique is my back, the porch side, -y.

- **Over the back line at the foot of the porch steps.** This is what happened at Alikampos, Dorida and
  Selakano.
  - The men leave by the porch and cross the back line in its middle, at x -4 to 1. There's no gap there; the
    pieces overlap.
  - Selakano's street view shows its porch steps coming down right onto the line.
  - Stavros, whose back line I moved off its steps last round, closed.
  - So it's the steps, not the line's ends. They run out further, and across more of the porch, than my
    estimate. The porch stands 0.8-1.8 m above the ground here.
- **Telos: a real 0.55 m slot** at x -0.25..0.3, right before the front door. The T2 sandbag at the door sat in
  it, so no piece could close it. My flood fill missed it: the line overlaps the house's footprint there, so the
  fill can't reach the slot from inside, while the man walks straight out of the door into it.
- **Gravia: through its neighbour.** The route goes (1, 6.5) → (6.3, 5.9) → (6.2, 0.6) → (10.2, -2.9).
  - It runs down the corridor between the office and the house on its right (House_Big_01_V3, an enterable
    house), into that house, and out past the right line's end.
  - The house's real walls aren't where its roof is.
- **Neri: through the "shop".** The route runs under the mossy roof I had taken for the shop's walls, (8, 3) →
  (12.3, 6.4) → (8.6, 10.2) → (9.3, 15.5). So it's open underneath, a market roof or arcade.
  - He leaves across the front line at x ≈ 9, exactly where a piece with drop stood.
  - I dropped those from the terrain's height, so where a terrace stands higher they would end up under it.

## What changed

- **Porch steps zone:** no piece over the porch's whole width (x -6..4), out 1.4 m per metre the porch stands
  above the ground plus 1.6 m.
  - Neri gets 1.0 m extra: a neighbour's box corner leaves no room further out, and its back didn't leak.
  - Stavros keeps round 2's zone.
- **Gap plugging:** an HBarrier_1 goes across any stretch of a line no piece or city wall crosses (within 0.3 m
  of it). It's off for Stavros, so its tested ring stays as it was.
- **T2 bags give way at T3** where they stand on a ring line (the brief's newer point). That's Telos' front-door
  bag and Gravia's window bag.
- **Pieces with drop** now fall from 1.5 m above the terrain, so they land on whatever stands there.
- **A neighbour can be marked open underneath** (Neri's shop). It's no barrier, and pieces may go into its box.

## Per town

- **Alikampos:** the back notch now goes out to y -11.5 over x -6.9..4.9, 2.6 m deeper, so its two corners have
  proper pieces (round 2's 1.7 m offset left them touching by 6 cm).
  - It stands on the street's visible edge, with `road_margin` 3 against the probe's road, the margin Selakano
    and Stavros passed with. It doesn't close the street.
- **Dorida:** the back line goes out to y -14.6, past the two planters and clear of the steps. It steps in at
  x -8.3 round the next house's box (y -9.0 west of it).
- **Gravia:**
  - **Right line:** now runs down the corridor at x 6.3 (5.4..7.2), between the office's east wall and the
    neighbour's west wall, from the back corner to the front. The whole neighbour house is outside the ring.
    Its pieces are in the neighbour's probe box, so they go in with drop (listed below).
  - **Left side:** as before, which held.
- **Neri:** the shop's roof is no longer a barrier. The ring already ran round it (right line at x 15.3, front at
  y 14.6); its front pieces now drop from above. The back line is 1-high where the steps zone keeps 2-high
  pieces out.
- **Selakano:** the back line is at y -10.3, 1-high in front of the porch, clear of the steps (`road_margin`
  2.8; it sits on the road's verge as before, without closing it).
- **Telos:** the slot is plugged. The T2 door bag gives way at T3.

## Kore, again (your call)

Unchanged in substance. Its porch opens straight onto the road east of the house (not in the probe), and both
ways out cross 2-high pieces standing on that road. Their routes are the same as tier 2's, so pieces on a road
look invisible to the game's path search. No ring can take in the porch without standing on or crossing that
road. Options:
- (a) Accept that Kore's closure can't be tested.
- (b) Close the porch itself, on its floor.
- (c) Let the ring close the road.

I'll do whichever you pick.

## Counts (things per tier: the full snapshot)

| Town | T1 | T2 | T3 |
|---|---|---|---|
| Alikampos | 0 | 4 (3 BagLong, 1 BagShort) | 38 (3 BagLong, 1 BagShort, 11 HBBig, 2 HB5, 3 HB3, 18 HB1) |
| Dorida | 0 | 3 (2 BagLong, 1 BagShort) | 31 (2 BagLong, 1 BagShort, 9 HBBig, 1 HB5, 6 HB3, 12 HB1) |
| Gravia | 0 | 4 (3 BagLong, 1 BagShort) | 21 (2 BagLong, 1 BagShort, 3 HBBig, 6 HB5, 4 HB3, 5 HB1) |
| Kore | 0 | 3 (2 BagLong, 1 BagShort) | 25 (2 BagLong, 1 BagShort, 13 HBBig, 2 HB3, 7 HB1) |
| Lakka | 0 | 4 (3 BagLong, 1 BagShort) | 27 (3 BagLong, 1 BagShort, 8 HBBig, 1 HB5, 3 HB3, 11 HB1) |
| Neri | 0 | 3 (2 BagLong, 1 BagShort) | 27 (2 BagLong, 1 BagShort, 7 HBBig, 5 HB5, 2 HB3, 10 HB1) |
| Poliakko | 0 | 4 (3 BagLong, 1 BagShort) | 26 (3 BagLong, 1 BagShort, 10 HBBig, 2 HB3, 10 HB1) |
| Selakano | 0 | 3 (2 BagLong, 1 BagShort) | 39 (2 BagLong, 1 BagShort, 6 HBBig, 2 HB5, 8 HB3, 20 HB1) |
| Stavros | 0 | 3 (2 BagLong, 1 BagShort) | 26 (2 BagLong, 1 BagShort, 4 HBBig, 2 HB3, 17 HB1) |
| Telos | 0 | 4 (3 BagLong, 1 BagShort) | 26 (2 BagLong, 1 BagShort, 9 HBBig, 2 HB5, 5 HB3, 7 HB1) |
| Abdera | 0 | 2 (1 BagLong, 1 BagShort) | – |
| Agios Konstantinos | 0 | 4 (3 BagLong, 1 BagShort) | – |
| Galati | 0 | 3 (2 BagLong, 1 BagShort) | – |
| Nifi | 0 | 4 (3 BagLong, 1 BagShort) | – |
| Topolia | 0 | 3 (2 BagLong, 1 BagShort) | – |

No guards, statics, towers, gates, wire or props. Every T3 piece is an H-barrier; T2 is sandbags on the house
(where T3 leaves a T2 bag out, it's said under the town below).

## Line audit, tier 3

What the columns mean:
- **Gaps:** each line, end to end, is cut into the stretches between what already closes it (a city wall, a
  trusted neighbour's box, a neighbour's real walls within 1.2 m, or the next line at a corner).
- **Width:** the gap's length.
- **Run over it:** the metres the pieces cover.
- **Ties into:** what each end of the gap meets.
- **Run past the ends:** how far the pieces carry on past each end.
- **Open > 0.3 m:** stretches no piece crosses within 1.2 m of the line. All are at corners or beside a trunk or
  a wall, where a stepped-in piece closes them; the flood fill finds no way through.

Rectangle lines are named back, front, left and right. Polygon lines are named by their fixed coordinate and run.

### Alikampos

polygon (-31, -8.9) → (-6.9, -8.9) → (-6.9, -11.5) → (4.9, -11.5) → (4.9, -8.9) → (8, -8.9) → (8, 12) → (-31, 12). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -11.5 (-6.9..4.9) | -6.9..5.0 | 11.9 | 11.9 | corner / corner | 0.9 / 1.0 | – |
| y -8.9 (-31..-6.9) | -31.0..-6.8 | 24.2 | 24.2 | corner / corner | 1.1 / 0.7 | – |
| y -8.9 (4.9..8) | 4.9..8.1 | 3.2 | 3.2 | corner / corner | 0.7 / 1.2 | – |
| y 12 (-31..8) | -31.0..8.1 | 39.1 | 39.1 | corner / corner | 0.9 / 1.0 | – |
| x -31 (-8.9..12) | -8.9..12.1 | 21.0 | 21.0 | corner / corner | 1.2 / 1.1 | – |
| x -6.9 (-11.5..-8.9) | -11.5..-8.8 | 2.7 | 2.7 | corner / corner | 0.8 / 1.2 | – |
| x 4.9 (-11.5..-8.9) | -11.5..-8.8 | 2.7 | 2.7 | corner / corner | 0.7 / 0.7 | – |
| x 8 (-8.9..12) | -8.9..12.1 | 21.0 | 21.0 | corner / corner | 0.7 / 0.8 | – |

Joints over 0.6 m: HBarrier_1@(-7.3,-8.9) x HBarrier_1@(-6.9,-9.6): 1.0 m along the first, 0.7 m along the second; HBarrier_1@(3.7,12.0) x HBarrier_1@(4.1,12.0): 1.0 m along the first, 1.0 m along the second.

### Dorida

polygon (-13.5, 10.7) → (-13.5, -9) → (-8.3, -9) → (-8.3, -14.6) → (17, -14.6) → (17, 10.7). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -14.6 (-8.3..17) | -8.3..14.8 | 23.1 | 23.1 | corner / city2_8m | 0.9 / 3.5 | – |
| y -14.6 (-8.3..17) | 15.3..17.1 | 1.8 | 1.8 | city2_8m / corner | 4.1 / 1.2 | – |
| y -9 (-13.5..-8.3) | -13.5..-8.2 | 5.3 | 5.3 | corner / corner | 1.1 / 1.0 | – |
| y 10.7 (-13.5..17) | -13.5..17.1 | 30.6 | 30.6 | corner / corner | 0.9 / 1.1 | – |
| x -13.5 (-9..10.7) | -9.0..10.8 | 19.8 | 19.8 | corner / corner | 0.8 / 0.4 | – |
| x -8.3 (-14.6..-9) | -14.6..-8.9 | 5.7 | 5.7 | corner / corner | 1.2 / 0.8 | – |
| x 17 (-14.6..10.7) | -14.6..10.8 | 25.4 | 25.4 | corner / corner | 0.7 / 0.7 | – |

Joints over 0.6 m: HBarrier_5@(-11.5,10.3) x HBarrier_1@(-13.5,9.5): 1.6 m along the first, 0.8 m along the second.

### Gravia

rectangle x -9..6.3, y -13..11.2. Flood fill: closed. Into a neighbour's probe box, with drop: HB5 at (6.3, -4.3), HB5 at (6.3, 1.1), HB3 at (6.3, 5.4), HB3 at (6.3, 8.6). T2 bags left out at T3 (on a line): BagLong.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -7.6..6.4 | 14.0 | 14.0 | i_House_Big_01_V2 / corner | 0.8 / 0.9 | – |
| front | -9.0..6.4 | 15.4 | 15.4 | corner / corner | 0.9 / 1.0 | – |
| left | -8.0..-7.5 | 0.5 | 0.5 | i_House_Big_01_V2 / i_Shop_01_V3 | 2.6 / 4.1 | – |
| left | -7.1..5.6 | 12.7 | 12.7 | i_Shop_01_V3 / city_8md | 3.5 / 0.5 | – |
| left | 8.0..11.3 | 3.3 | 3.3 | city_8md / corner | 0.7 / 1.1 | – |
| right | -13.0..-6.4 | 6.6 | 6.6 | corner / i_House_Big_01_V3 | 0.8 / 4.1 | – |
| right | 6.4..11.3 | 4.9 | 4.9 | i_House_Big_01_V3 / corner | 4.1 / 1.2 | – |

### Kore

rectangle x -16..17.5, y -14..12. Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -16.0..17.6 | 33.6 | 33.6 | corner / corner | 1.2 / 1.1 | – |
| front | -16.0..17.6 | 33.6 | 33.5 | corner / corner | – / 1.3 | – |
| left | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 1.1 / 0.0 | – |
| right | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 0.7 / 1.1 | – |

Joints over 0.6 m: HBarrier_Big@(-11.0,10.8) x HBarrier_1@(-15.2,10.5): 0.7 m along the first, 1.4 m along the second.

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

polygon (-10, -10.5) → (9.6, -10.5) → (9.6, -7.8) → (15.3, -7.8) → (15.3, 14.6) → (-10, 14.6). Flood fill: closed. Into a neighbour's probe box, with drop: HBBig at (1.2, 14.6), HBBig at (9.2, 14.6), HB1 at (13.6, 14.6).

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -10.5 (-10..9.6) | -10.0..9.7 | 19.7 | 19.7 | corner / corner | 1.2 / 0.9 | – |
| y -7.8 (9.6..15.3) | 9.6..15.4 | 5.8 | 5.8 | corner / corner | 0.9 / 1.1 | – |
| y 14.6 (-10..15.3) | -10.0..15.4 | 25.4 | 25.4 | corner / corner | 0.9 / 0.9 | – |
| x -10 (-10.5..14.6) | -10.5..10.9 | 21.4 | 21.4 | corner / city_8m | 0.8 / 4.1 | – |
| x -10 (-10.5..14.6) | 11.4..14.7 | 3.3 | 3.3 | city_8m / corner | 4.1 / 1.2 | – |
| x 9.6 (-10.5..-7.8) | -10.5..-7.7 | 2.8 | 2.8 | corner / corner | 0.8 / 0.8 | – |
| x 15.3 (-7.8..14.6) | -7.8..11.3 | 19.1 | 19.1 | corner / stone_4m | 0.8 / 4.1 | – |
| x 15.3 (-7.8..14.6) | 11.7..14.7 | 3.0 | 3.0 | stone_4m / corner | 4.1 / 0.7 | – |

Joints over 0.6 m: HBarrier_5@(11.6,-7.8) x HBarrier_1@(9.6,-8.7): 1.6 m along the first, 0.7 m along the second.

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

rectangle x -17.5..15.5, y -10.3..12. Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -17.5..15.6 | 33.1 | 33.1 | corner / corner | 0.9 / 1.0 | – |
| front | -17.5..-15.2 | 2.3 | 1.8 | corner / city2_8m | – / 4.1 | -17.5..-17.0 |
| front | -10.1..15.6 | 25.7 | 25.4 | city2_8m / corner | 4.1 / 1.1 | 11.9..12.2 |
| left | -10.3..-7.7 | 2.6 | 2.6 | corner / city2_8m | 1.1 / 0.6 | – |
| left | 4.1..12.1 | 8.0 | 8.0 | city2_8m / corner | 4.1 / 0.7 | – |
| right | -10.3..12.1 | 22.4 | 22.2 | corner / corner | 0.8 / 0.7 | – |

Joints over 0.6 m: HBarrier_1@(10.6,12.0) x HBarrier_1@(11.1,12.8): 0.9 m along the first, 0.9 m along the second.

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

rectangle x -21..10.8, y -14..7.6. Flood fill: closed. Into a neighbour's probe box, with drop: HBBig at (-17.7, 7.2), HBBig at (-9.7, 7.6), HB5 at (-3.1, 7.6). T2 bags left out at T3 (on a line): BagLong.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -21.0..10.9 | 31.9 | 31.9 | corner / corner | 0.9 / 1.1 | – |
| front | -21.0..10.9 | 31.9 | 31.9 | corner / corner | 0.9 / 0.9 | – |
| left | -14.0..-10.2 | 3.8 | 3.8 | corner / city_8m | 1.1 / 4.1 | – |
| left | -3.1..4.5 | 7.6 | 7.6 | city_8m / city_8m | 4.1 / 4.0 | – |
| left | 5.1..7.7 | 2.6 | 2.6 | city_8m / corner | 4.1 / 0.8 | – |
| right | -14.0..5.1 | 19.1 | 19.1 | corner / city_8m | 1.2 / 3.4 | – |
| right | 5.6..7.7 | 2.1 | 2.1 | city_8m / corner | 4.1 / 0.8 | – |

Joints over 0.6 m: HBarrier_Big@(-17.7,7.2) x HBarrier_1@(-21.0,6.1): 1.6 m along the first, 0.8 m along the second; HBarrier_1@(10.8,4.1) x HBarrier_1@(10.8,4.8): 0.8 m along the first, 0.8 m along the second.

## What to check in the game

1. **Closure.** Most doubtful first:
   - Gravia's right line in the corridor.
   - Neri's front across the shop's forecourt.
   - The back lines of Alikampos, Dorida and Selakano, now off the steps.
   - Telos' plugged front.
2. **Clips and floats on the pieces with drop:**
   - Gravia's four at x 6.3, between the two houses' walls.
   - Neri's three at y 14.6.
   - Telos' three at y 7.6.
3. **Alikampos' notch** on the street's edge.
