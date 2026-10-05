# Villages: pass 1, round 4 report (walls; answering pass1_round3.md)

Commit `ce06d5c` on `layouts/villages`: the drafts and `tools/officegen/drafting/villages.py`.

- All 15 drafts pass `tl.check()`.
- All ten tier 3 rings come out closed in the script's flood fill.
- **Unchanged:** Dorida, Lakka and Poliakko (closed in the game), and Kore. Their drafts are identical to round 3's.
- `python tools/officegen/drafting/villages.py --audit [--map] [town]` reprints everything below.

## What round 3 showed

**The back door's way out starts beyond the back line.** This is Alikampos, Selakano and Stavros.
- Their one route starts at (-0.5, -12.1), (-0.5, -12.4) and (-0.1, -12), not at the porch. Telos' route, for
  comparison, starts at its start point and walks out of the front door.
- That depth matches the house model's box, which reaches y -12.09 at the back. I read it as the game's path
  down the porch steps (or the house's own path) ending there, so anything nearer the house than about y -12.2
  doesn't stop it.
- The three towns that closed have their back lines past it: Dorida at -14.6, Lakka at -14, Poliakko at -13.
- **Stavros' draft is byte-identical to round 2's,** when it closed. So the change is in the walk (the start
  point is now the porch, (3.6, -5.7)), not in my pieces.

**My dropped pieces hung in the air.** Round 3 dropped them from 1.5 m above the terrain so they would land on any
terrace; instead they stayed there. That's every floating piece you list, and the men walked under them:
- Telos' route goes from (0.1, 7.2) to (-2.1, 11.7) under the floating HB5 at (-3.2, 7.6).
- Gravia's goes from (5.8, 8.6) to (10.8, 7.9) under the floating HB3 at (6.3, 8.6).
- Neri's crosses at x ≈ 9 under the floating Big.
None of them were stacked; they were single pieces at 1.4-1.5 m.

**Gravia's corridor is narrower than an H-barrier.** The two HB5 along it clipped the neighbour house. So its west
wall stands within about 1.4 m of the office's east wall.

**The T2 window bags at Gravia and Neri cut into the neighbours.**

## What changed

- **Back exit (`exit_back`, Alikampos, Selakano, Stavros):** no piece nearer the back door than y -12.6 over
  x -4.5..3.5. Each back line now has a notch out to y -13.5 in front of the porch:
  - Alikampos x -6.9..4.9;
  - Selakano and Stavros x -5.4..4.4.
  These notches stand on roads, which needs your OK (see below).
- **Dropped pieces go back to the terrain's height,** as in round 2, where none floated. Only two towns still have
  any:
  - Gravia: two, at the corridor's mouths.
  - Neri: three, across the shop's forecourt.
- **Telos' front line** moves out to y 8.7, clear of the left neighbour's probe box, so it needs no dropped pieces.
  The T2 bag at the front door gives way at T3.
- **Gravia's corridor is left outside.**
  - The right line (x 6.3) seals its north mouth from the front corner down to y 5.4, against the office's
    front-east corner, and its south mouth from the back corner up to y -5.5.
  - A keep-out area (x 5.3..7.3, y -5.5..5.4) stops any piece going into the corridor.
  - The corridor and the neighbour house are outside the ring. The office's east wall has no door, only a
    window.
- **No T2 window bag at Gravia and Neri.**

## Roads, and Kore again (your calls)

**Selakano and Stavros' notches stand on the probe's road, with no road margin.**
- Selakano's track runs about 13.7 m behind its house. The notch, out to y -14.4, covers its near half over 10 m
  and leaves the rest open.
- At Stavros the notch stands on the plaza's road. Of the road it covers about 1.5 m, at a point where the plaza
  is wide.
- Alikampos' notch stands on the street's near edge, with a 1.5 m road margin.
- None of them closes the road. The brief allows crossing a track, but this is near the line.
- If pieces standing on a road are invisible to the game's path search (Kore's case), these notches won't close
  them either. If so, say whether to close the porch itself instead.

**Kore** is unchanged: its porch opens onto a road the probe doesn't have, and both ways out cross pieces on that
road. Options:
- (a) Accept it.
- (b) Close the porch on its floor.
- (c) Let the ring close the road.

**One townlib question, for Gravia and Neri.** Where the game shows a neighbour's probe box is open ground (Gravia's
corridor mouths, Neri's forecourt under the shop's roof), `tl.check()` won't take a piece on the ground. So those
pieces go in with drop at the terrain's height. If dropped pieces don't block the path search either (Neri's round
2 route crossed at a dropped piece), I'd need an exemption there for ground pieces: say if you want one.

## Counts (things per tier: the full snapshot)

| Town | T1 | T2 | T3 |
|---|---|---|---|
| Alikampos | 0 | 4 (3 BagLong, 1 BagShort) | 37 (3 BagLong, 1 BagShort, 11 HBBig, 2 HB5, 5 HB3, 15 HB1) |
| Dorida | 0 | 3 (2 BagLong, 1 BagShort) | 31 (2 BagLong, 1 BagShort, 9 HBBig, 1 HB5, 6 HB3, 12 HB1) |
| Gravia | 0 | 3 (2 BagLong, 1 BagShort) | 20 (2 BagLong, 1 BagShort, 3 HBBig, 4 HB5, 3 HB3, 7 HB1) |
| Kore | 0 | 3 (2 BagLong, 1 BagShort) | 25 (2 BagLong, 1 BagShort, 13 HBBig, 2 HB3, 7 HB1) |
| Lakka | 0 | 4 (3 BagLong, 1 BagShort) | 27 (3 BagLong, 1 BagShort, 8 HBBig, 1 HB5, 3 HB3, 11 HB1) |
| Neri | 0 | 2 (1 BagLong, 1 BagShort) | 26 (1 BagLong, 1 BagShort, 7 HBBig, 5 HB5, 2 HB3, 10 HB1) |
| Poliakko | 0 | 4 (3 BagLong, 1 BagShort) | 26 (3 BagLong, 1 BagShort, 10 HBBig, 2 HB3, 10 HB1) |
| Selakano | 0 | 3 (2 BagLong, 1 BagShort) | 47 (2 BagLong, 1 BagShort, 6 HBBig, 1 HB5, 9 HB3, 28 HB1) |
| Stavros | 0 | 3 (2 BagLong, 1 BagShort) | 35 (2 BagLong, 1 BagShort, 3 HBBig, 1 HB5, 4 HB3, 24 HB1) |
| Telos | 0 | 4 (3 BagLong, 1 BagShort) | 28 (2 BagLong, 1 BagShort, 9 HBBig, 2 HB5, 5 HB3, 9 HB1) |
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
- **Open > 0.3 m:** stretches no piece crosses within 1.2 m of the line. All are at corners, beside a trunk or a
  wall, or (Gravia) the corridor left outside; the flood fill finds no way through.

Rectangle lines are named back, front, left and right. Polygon lines are named by their fixed coordinate and run.

### Alikampos

polygon (-31, -8.9) → (-6.9, -8.9) → (-6.9, -13.5) → (4.9, -13.5) → (4.9, -8.9) → (8, -8.9) → (8, 12) → (-31, 12). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -13.5 (-6.9..4.9) | -6.9..5.0 | 11.9 | 11.9 | corner / corner | 0.9 / 1.0 | – |
| y -8.9 (-31..-6.9) | -31.0..-6.8 | 24.2 | 24.2 | corner / corner | 1.1 / 0.8 | – |
| y -8.9 (4.9..8) | 4.9..8.1 | 3.2 | 3.2 | corner / corner | 0.8 / 1.2 | – |
| y 12 (-31..8) | -31.0..8.1 | 39.1 | 39.1 | corner / corner | 0.9 / 1.0 | – |
| x -31 (-8.9..12) | -8.9..12.1 | 21.0 | 21.0 | corner / corner | 1.2 / 1.1 | – |
| x -6.9 (-13.5..-8.9) | -13.5..-8.8 | 4.7 | 4.7 | corner / corner | 0.8 / 1.2 | – |
| x 4.9 (-13.5..-8.9) | -13.5..-8.8 | 4.7 | 4.7 | corner / corner | 0.7 / 0.7 | – |
| x 8 (-8.9..12) | -8.9..12.1 | 21.0 | 21.0 | corner / corner | 0.7 / 0.8 | – |

Joints over 0.6 m: HBarrier_1@(4.8,-8.9) x HBarrier_1@(4.9,-9.5): 1.4 m along the first, 0.8 m along the second; HBarrier_1@(3.7,12.0) x HBarrier_1@(4.1,12.0): 1.0 m along the first, 1.0 m along the second.

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

rectangle x -9..6.3, y -13..11.2. Flood fill: closed. Into a neighbour's probe box, with drop at the terrain's height: HB1 at (6.3, -6.6), HB3 at (6.3, 7.7).

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -7.6..6.4 | 14.0 | 14.0 | i_House_Big_01_V2 / corner | 0.8 / 0.9 | – |
| front | -9.0..6.4 | 15.4 | 15.4 | corner / corner | 0.9 / 1.0 | – |
| left | -8.0..-7.5 | 0.5 | 0.5 | i_House_Big_01_V2 / i_Shop_01_V3 | 2.6 / 4.1 | – |
| left | -7.1..5.6 | 12.7 | 12.7 | i_Shop_01_V3 / city_8md | 3.5 / 0.5 | – |
| left | 8.0..11.3 | 3.3 | 3.3 | city_8md / corner | 0.7 / 1.1 | – |
| right | -13.0..-6.4 | 6.6 | 6.6 | corner / i_House_Big_01_V3 | 0.8 / 0.6 | – |
| right | 6.4..11.3 | 4.9 | 4.9 | i_House_Big_01_V3 / corner | 0.5 / 1.2 | – |

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

polygon (-10, -10.5) → (9.6, -10.5) → (9.6, -7.8) → (15.3, -7.8) → (15.3, 14.6) → (-10, 14.6). Flood fill: closed. Into a neighbour's probe box, with drop at the terrain's height: HBBig at (1.2, 14.6), HBBig at (9.2, 14.6), HB1 at (13.6, 14.6).

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

polygon (-17.5, -10.3) → (-5.4, -10.3) → (-5.4, -13.5) → (4.4, -13.5) → (4.4, -10.3) → (15.5, -10.3) → (15.5, 12) → (-17.5, 12). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -13.5 (-5.4..4.4) | -5.4..4.5 | 9.9 | 9.8 | corner / corner | 0.9 / 1.5 | – |
| y -10.3 (-17.5..-5.4) | -17.5..-5.3 | 12.2 | 12.2 | corner / corner | 0.9 / 0.7 | – |
| y -10.3 (4.4..15.5) | 4.4..15.6 | 11.2 | 11.2 | corner / corner | 0.7 / 1.0 | – |
| y 12 (-17.5..15.5) | -17.5..-15.2 | 2.3 | 1.8 | corner / city2_8m | – / 4.1 | -17.5..-17.0 |
| y 12 (-17.5..15.5) | -10.1..15.6 | 25.7 | 25.4 | city2_8m / corner | 4.1 / 1.1 | 11.9..12.2 |
| x -17.5 (-10.3..12) | -10.3..-7.7 | 2.6 | 2.6 | corner / city2_8m | 1.1 / 0.6 | – |
| x -17.5 (-10.3..12) | 4.1..12.1 | 8.0 | 8.0 | city2_8m / corner | 4.1 / 0.7 | – |
| x -5.4 (-13.5..-10.3) | -13.5..-10.2 | 3.3 | 3.3 | corner / corner | 0.8 / 0.7 | – |
| x 4.4 (-13.5..-10.3) | -13.5..-10.2 | 3.3 | 3.3 | corner / corner | 0.7 / 1.2 | – |
| x 15.5 (-10.3..12) | -10.3..12.1 | 22.4 | 22.2 | corner / corner | 0.8 / 0.7 | – |

Joints over 0.6 m: HBarrier_Big@(8.2,-10.3) x HBarrier_1@(4.4,-11.3): 1.2 m along the first, 0.8 m along the second; HBarrier_1@(10.6,12.0) x HBarrier_1@(11.1,12.8): 0.9 m along the first, 0.9 m along the second.

### Stavros

polygon (-8, 12) → (-8, -7.8) → (-5.4, -7.8) → (-5.4, -13.5) → (4.4, -13.5) → (4.4, -9.6) → (5.5, -9.6) → (5.5, 12). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -13.5 (-5.4..4.4) | -5.4..4.5 | 9.9 | 9.9 | corner / corner | 0.9 / 1.0 | – |
| y -9.6 (4.4..5.5) | 4.4..5.6 | 1.2 | 1.2 | corner / corner | 0.7 / 1.1 | – |
| y -7.8 (-8..-5.4) | -8.0..-5.3 | 2.7 | 2.7 | corner / corner | 1.2 / 0.7 | – |
| y 12 (-8..5.5) | -8.0..5.6 | 13.6 | 13.6 | corner / corner | 0.9 / 1.0 | – |
| x -8 (-7.8..12) | -7.8..12.1 | 19.9 | 19.9 | corner / corner | 0.7 / 1.5 | – |
| x -5.4 (-13.5..-7.8) | -13.5..-7.7 | 5.8 | 5.8 | corner / corner | 0.8 / 0.7 | – |
| x 4.4 (-13.5..-9.6) | -13.5..-9.5 | 4.0 | 4.0 | corner / corner | 0.7 / 2.6 | – |
| x 5.5 (-9.6..12) | – | – | – | neighbours 21.7 m | – | – |

Joints over 0.6 m: HBarrier_Big@(-8.0,4.8) x HBarrier_1@(-8.0,9.0): 0.7 m along the first, 0.7 m along the second; HBarrier_3@(3.8,12.0) x HBarrier_1@(5.5,11.3): 0.9 m along the first, 0.8 m along the second; HBarrier_1@(5.9,12.0) x HBarrier_1@(5.5,11.3): 1.1 m along the first, 0.7 m along the second.

### Telos

rectangle x -21..10.8, y -14..8.7. Flood fill: closed. T2 bags left out at T3 (on a line): BagLong.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -21.0..10.9 | 31.9 | 31.9 | corner / corner | 0.9 / 1.1 | – |
| front | -21.0..10.9 | 31.9 | 31.9 | corner / corner | 0.9 / 0.9 | – |
| left | -14.0..-10.2 | 3.8 | 3.8 | corner / city_8m | 1.1 / 4.1 | – |
| left | -3.1..4.5 | 7.6 | 7.6 | city_8m / city_8m | 4.1 / 4.1 | – |
| left | 5.1..8.8 | 3.7 | 3.7 | city_8m / corner | 4.1 / 0.4 | – |
| right | -14.0..5.1 | 19.1 | 19.1 | corner / city_8m | 1.2 / 4.1 | – |
| right | 5.6..8.8 | 3.2 | 3.2 | city_8m / corner | 4.1 / 1.1 | – |

Joints over 0.6 m: HBarrier_1@(10.8,4.1) x HBarrier_1@(10.8,4.8): 0.8 m along the first, 0.8 m along the second.

## What to check in the game

1. **Closure.** Most doubtful first:
   - Selakano and Stavros' back notches on the road.
   - Gravia's sealed corridor mouths.
   - Neri's forecourt.
   - Alikampos' notch.
   - Telos' front at y 8.7.
2. **Floats and clips** on the dropped pieces:
   - Gravia: (6.3, -6.6) and (6.3, 7.7), next to the neighbour's corners.
   - Neri: the three at y 14.6.
