# Villages: pass 1 report (walls)

Branch `layouts/villages`. The drafts and `tools/officegen/drafting/villages.py` are pushed. Every draft passes
`tl.check()`, apart from its "at least 2 guards" line: pass 1 has no guards, so the script drops just that line
before `tl.write` checks (`check_pass1`). Every tier 3 ring comes out closed in the script's flood fill, a man
0.4 m across the shoulders, walked from all round the house. The script's copy of the game's clip test flags
nothing. `python tools/officegen/drafting/villages.py --audit [--map] [town]` reprints everything below.

## The ladder as drafted

- **T1: empty**, in every town.
- **T2: sandbags on the house, nothing in the yard.** The same four positions on every office, skipped where a
  neighbour stands against that side:
  - **Porch, back edge:** a BagFence_Long on the porch floor along its open back edge, x -3.15..-0.05, y -6.0. The
    men in the house door at (-2.9, -4.3) bunker down behind it. It stays clear of the porch's east end, where
    round 5 measured Topolia's bag cutting into something at x 1.4.
  - **Porch, west mouth:** a BagFence_Short across the porch's west mouth (the main doorway, facing -x), on the
    porch floor at x -4.9. A 1.7 m way on is left at the porch's corner.
  - **Front door:** a BagFence_Long on the ground at the foot of the front steps, y 7.6.
  - **East window:** a BagFence_Long on the ground under the one ground-floor window, x 5.9.
- **T3: a tight H-barrier ring with no opening**, round the house and what is attached to it:
  - Kore's annex and shop and Neri's front annex are inside their rings.
  - Sides facing a road or open ground are laid 2-high (HBarrier_Big) first. The rest is filled 1-high
    (HBarrier_5, _3, _1).
  - T3 keeps T2's bags. No tier drops anything.

## Rules the script now holds to

- **Only real barriers close a line** (`real_barrier()`): full-height city walls (city_/city2_ 4 m and 8 m pieces
  and pillars, box 4.2 m high) and solid buildings.
  - Not counted: addons (sheds, lean-tos, terraces), ruins and damaged buildings (`d_`, `_dam`), the damaged city
    walls (`city_8md`), stone walls (chest high), pipe and wire fences, the low concrete walls, planters and wells.
  - The flood fill walks a man straight through all of those, so a line has to close past them.
- **The house never closes the ring.** Its porch door and front door are on opposite sides, so a man could walk
  through it. The whole house is inside every ring.
- **Kore's gap (round 5's in-game walk, about (-13, 13)).** The old ring ended its front and left lines on
  Addon_01's box. In the round 5 top view, that box is far bigger than the shed: the gap was the open ground
  between the ring's corner and the shed. Kore's ring is now closed on itself, all four corners line to line.
- **Joints, 0.3-0.6 m at the ends (`OVERLAP` 0.45):**
  - Pieces are spaced by the shorter of townlib's size and the game's measured box: HBarrier_1 1.4 m,
    HBarrier_5 5.8 m. So a planned overlap holds in the game.
  - Each run between two closers is tiled exactly (`tile()`): the fewest pieces, one joint overlap.
  - The back and front lines run on to the corners' outer faces. The side lines butt 0.45 m into them.
  - A new `overlap_audit` checks every overlapping pair. Two joints are over 0.6 m (listed below).
  - No piece stands on or into an old wall along its length, so none uses the brief's new "upgrade the existing
    walls" allowance.
- **Roads:** every probed road near the rings is a TRACK. Pieces keep 4 m off a track's centre line (3 m on
  Selakano's back line, below). No ring crosses a road.

## Per town, what changed for pass 1 (walls only)

- **Every town:** the guards, statics, towers, gates, chicanes, wire, flag and furniture are gone. The gate gaps
  are closed.
- **Gravia:** the left line crosses a damaged city wall (`city_8md`, x -13.4..-6.2, y ~7). It runs from 0.9 m
  off the house to the next city wall, so no line can pass it. That wall is the one `ties` entry: the pieces butt
  into it from both sides, at y 5.6 and 8.0.
- **Neri:** the front line was blocked by the annex (Addon_04) on the house's front. The front door opens into
  that annex, which has its own doors, so the line now runs in front of it, at y 14.6. It crosses the city wall at
  y ~11 on the left and ends on Shop_01 on the right.
- **Selakano:** the old back line relied on the damaged garage's box (Garage_V2_dam). In round 5's top view the
  garage is about 6.5 x 11 m against a 9 x 18 m box, with open ground behind it. The back line now runs behind the
  garage at y -9.9, on the track's verge (`road_margin` 3 m), clear of the box that `tl.check` holds pieces off.
  It does not close the track.
- **Stavros:** the right side is the two neighbours, u_House_Big_01 and i_House_Small_02. Between the house and
  them is a corridor under 1 m wide that leads from the back yard to the front yard, both inside the ring. The
  back and front lines run on to x 5.5, against House_Big_01's box (x 6.0) and House_Small_02's.
- **The rest** keep their round 6 rectangles:
  - Alikampos, Dorida, Lakka and Poliakko tie into their neighbours as before.
  - Telos ties into House_Small_01 and the city walls.
  - Kore is self-closed (above).

## Counts (things per tier: the full snapshot)

| Town | T1 | T2 | T3 |
|---|---|---|---|
| Alikampos | 0 | 4 (3 BagLong, 1 BagShort) | 23 (3 BagLong, 1 BagShort, 5 HBBig, 1 HB5, 2 HB3, 11 HB1) |
| Dorida | 0 | 3 (2 BagLong, 1 BagShort) | 26 (2 BagLong, 1 BagShort, 4 HBBig, 1 HB5, 9 HB3, 9 HB1) |
| Gravia | 0 | 3 (2 BagLong, 1 BagShort) | 21 (2 BagLong, 1 BagShort, 4 HBBig, 3 HB5, 2 HB3, 9 HB1) |
| Kore | 0 | 3 (2 BagLong, 1 BagShort) | 23 (2 BagLong, 1 BagShort, 13 HBBig, 2 HB3, 5 HB1) |
| Lakka | 0 | 4 (3 BagLong, 1 BagShort) | 27 (3 BagLong, 1 BagShort, 8 HBBig, 1 HB5, 3 HB3, 11 HB1) |
| Neri | 0 | 2 (1 BagLong, 1 BagShort) | 21 (1 BagLong, 1 BagShort, 4 HBBig, 2 HB5, 7 HB3, 6 HB1) |
| Poliakko | 0 | 4 (3 BagLong, 1 BagShort) | 24 (3 BagLong, 1 BagShort, 7 HBBig, 2 HB5, 6 HB3, 5 HB1) |
| Selakano | 0 | 3 (2 BagLong, 1 BagShort) | 36 (2 BagLong, 1 BagShort, 6 HBBig, 4 HB5, 6 HB3, 17 HB1) |
| Stavros | 0 | 3 (2 BagLong, 1 BagShort) | 21 (2 BagLong, 1 BagShort, 3 HBBig, 6 HB3, 9 HB1) |
| Telos | 0 | 4 (3 BagLong, 1 BagShort) | 28 (3 BagLong, 1 BagShort, 7 HBBig, 1 HB5, 7 HB3, 9 HB1) |
| Abdera | 0 | 2 (1 BagLong, 1 BagShort) | – |
| Agios Konstantinos | 0 | 4 (3 BagLong, 1 BagShort) | – |
| Galati | 0 | 3 (2 BagLong, 1 BagShort) | – |
| Nifi | 0 | 4 (3 BagLong, 1 BagShort) | – |
| Topolia | 0 | 3 (2 BagLong, 1 BagShort) | – |

Guards 0 and statics 0 at every tier. T2 skips:
- **East-window bags:** a neighbour stands against that side in Dorida, Gravia, Kore, Neri, Selakano, Stavros,
  Galati and Topolia.
- **Front-door bags:** a neighbour or an annex in front in Neri and Abdera.

## Line audit, tier 3

What the columns mean:
- **Gaps:** each side, corner to corner, is cut into the stretches between what already closes it (a real barrier
  within 1.2 m of the line, or the next side's line at a corner).
- **Width:** the gap's length.
- **Run over it:** the metres the pieces cover.
- **Ties into:** what each end of the gap meets.
- **Run past the ends:** how far the pieces carry on past each end of the gap (into a wall, onto the next line).
- **Open > 0.3 m:** the stretches no piece crosses within 1.2 m of the line. All are at a corner, a tree trunk
  or a neighbour's angled box corner. The flood fill finds no way through any of them, because the next piece is
  stepped in or the wall closes it.

### Alikampos

Ring x -10..8, y -10..12. 2-high first on: back, right, front. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -10.0..8.1 | 18.1 | 18.1 | corner / corner | 0.9 / 1.2 | – |
| front | -10.0..8.1 | 18.1 | 18.1 | corner / corner | 0.9 / 1.0 | – |
| left | -10.0..-7.5 | 2.5 | 2.1 | corner / House_Big_01 | 1.2 / – | -7.9..-7.5 |
| left | 8.3..12.1 | 3.8 | 3.8 | House_Big_01 / corner | 0.4 / 1.1 | – |
| right | -10.0..12.1 | 22.1 | 22.1 | corner / corner | 0.7 / 0.8 | – |

Per side: back 1-high 1.4 m, 2-high 16.7 m; front 1-high 10.5 m, 2-high 7.6 m; left 1-high 3.4 m, 2-high 2.5 m, neighbours 15.8 m, open 0.4 m; right 1-high 5.8 m, 2-high 16.3 m.

### Dorida

Ring x -19..17, y -11..9.9. 2-high first on: front, right, left. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -9.2..14.8 | 24.0 | 24.0 | House_Big_02 / city wall | 0.3 / 3.5 | – |
| back | 15.3..17.1 | 1.8 | 1.8 | city wall / corner | 4.1 / 1.2 | – |
| front | -15.2..-11.5 | 3.7 | 3.7 | Shop_02 / Garage | 0.5 / 0.4 | – |
| front | -4.1..17.1 | 21.2 | 21.2 | Garage / corner | 0.1 / 1.0 | – |
| left | -9.9..-7.1 | 2.8 | 2.8 | House_Big_02 / Shop_02 | 0.5 / 0.3 | – |
| right | -11.0..10.0 | 21.0 | 21.0 | corner / corner | 0.7 / 0.7 | – |

Per side: back 1-high 24.6 m, 2-high 1.2 m, neighbours 10.3 m; front 1-high 8.6 m, 2-high 16.3 m, neighbours 11.2 m; left 1-high 2.8 m, neighbours 18.2 m; right 1-high 4.7 m, 2-high 16.3 m.

### Gravia

Ring x -9..9, y -13..11.2. 2-high first on: back, front. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -7.6..9.1 | 16.7 | 16.7 | House_Big_01 / corner | 0.8 / 0.8 | – |
| front | -9.0..9.1 | 18.1 | 18.1 | corner / corner | 0.9 / 1.3 | – |
| left | -8.0..-7.5 | 0.5 | 0.5 | House_Big_01 / Shop_01 | 2.6 / 4.1 | – |
| left | -7.1..5.6 | 12.7 | 12.7 | Shop_01 / damaged city wall (tie) | 3.5 / 0.5 | – |
| left | 8.0..11.3 | 3.3 | 3.3 | damaged city wall (tie) / corner | 0.7 / 1.1 | – |
| right | -9.9..-7.1 | 2.8 | 2.5 | House_Small_02 / House_Big_01 | 4.1 / – | -7.4..-7.1 |
| right | 8.7..11.3 | 2.6 | 2.6 | House_Big_01 / corner | 0.3 / 0.8 | – |

Per side: back 1-high 1.1 m, 2-high 15.6 m, neighbours 1.4 m; front 1-high 2.6 m, 2-high 15.5 m; left 1-high 15.2 m, 2-high 1.3 m, neighbours 7.8 m; right 1-high 5.1 m, neighbours 18.9 m, open 0.3 m.

### Kore

Ring x -16..17.5, y -14..12. 2-high first on: back, front, left, right. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -16.0..17.6 | 33.6 | 33.6 | corner / corner | 1.2 / 1.1 | – |
| front | -16.0..17.6 | 33.6 | 32.7 | corner / corner | – / 1.3 | -16.0..-15.1 |
| left | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 1.1 / 0.0 | – |
| right | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 0.7 / 1.1 | – |

Per side: back 1-high 0.9 m, 2-high 32.7 m; front 1-high 0.4 m, 2-high 32.3 m, open 0.9 m; left 1-high 6.5 m, 2-high 19.6 m; right 1-high 0.5 m, 2-high 25.6 m.

### Lakka

Ring x -10..10, y -14..12. 2-high first on: back, right, left, front. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -10.0..10.1 | 20.1 | 20.1 | corner / corner | 0.9 / 1.2 | – |
| front | -10.0..3.6 | 13.6 | 13.6 | corner / Stone_HouseSmall | 0.9 / 1.9 | – |
| front | 8.5..10.1 | 1.6 | 1.6 | Stone_HouseSmall / corner | 2.8 / 1.0 | – |
| left | -14.0..12.1 | 26.1 | 25.6 | corner / corner | 1.2 / 1.1 | -7.8..-7.3 |
| right | -14.0..12.1 | 26.1 | 26.1 | corner / corner | 0.7 / 0.7 | – |

Per side: back 1-high 3.4 m, 2-high 16.7 m; front 1-high 1.6 m, 2-high 13.6 m, neighbours 4.9 m; left 1-high 6.7 m, 2-high 18.9 m, open 0.5 m; right 1-high 9.8 m, 2-high 16.3 m.

Joints over 0.6 m: HBarrier_Big@(-8.8,-2.5) x HBarrier_1@(-8.8,-6.6): 0.9 m along the first, 1.4 m along the second.

### Neri

Ring x -10..10, y -12.5..14.6. 2-high first on: back, left. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -10.0..-0.2 | 9.8 | 9.8 | corner / House_Big_01 | 1.2 / 1.7 | – |
| back | 4.5..10.1 | 5.6 | 5.6 | House_Big_01 / corner | 1.9 / 0.9 | – |
| front | -10.0..4.8 | 14.8 | 14.8 | corner / Shop_01 | 0.9 / 0.5 | – |
| left | -12.5..10.9 | 23.4 | 23.3 | corner / city wall | 1.1 / – | – |
| left | 11.4..14.7 | 3.3 | 3.3 | city wall / corner | 0.4 / 0.8 | – |
| right | -12.5..-0.9 | 11.6 | 11.6 | corner / Shop_01 | 0.0 / 0.4 | – |

Per side: back 1-high 2.2 m, 2-high 13.2 m, neighbours 4.7 m; front 1-high 14.8 m, neighbours 5.3 m; left 1-high 9.4 m, 2-high 17.2 m, neighbours 0.5 m, open 0.1 m; right 1-high 9.2 m, 2-high 2.4 m, neighbours 15.6 m.

### Poliakko

Ring x -18..7.3, y -13..12. 2-high first on: right, back, left. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -18.0..7.4 | 25.4 | 25.4 | corner / corner | 1.2 / 1.1 | – |
| front | -11.8..7.4 | 19.2 | 19.2 | Shop_01 / corner | 0.3 / 1.0 | – |
| left | -13.0..8.5 | 21.5 | 21.2 | corner / Shop_01 | 1.1 / – | 8.2..8.5 |
| right | -13.0..12.1 | 25.1 | 25.1 | corner / corner | 0.7 / 0.8 | – |

Per side: back 1-high 0.6 m, 2-high 24.8 m; front 1-high 19.2 m, neighbours 6.2 m; left 1-high 4.0 m, 2-high 17.2 m, neighbours 3.6 m, open 0.3 m; right 1-high 8.8 m, 2-high 16.3 m.

### Selakano

Ring x -17.5..15.5, y -9.9..12. 2-high first on: back, left, right, front. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -17.5..15.6 | 33.1 | 33.1 | corner / corner | 0.9 / 0.9 | – |
| front | -17.5..-15.2 | 2.3 | 1.8 | corner / city wall | – / 4.1 | -17.5..-17.0 |
| front | -10.1..15.6 | 25.7 | 25.6 | city wall / corner | 4.1 / 1.6 | – |
| left | -9.9..-7.7 | 2.2 | 2.2 | corner / city wall | 1.1 / 0.8 | – |
| left | 4.1..12.1 | 8.0 | 7.4 | city wall / corner | 4.1 / 0.7 | 10.7..11.3 |
| right | -9.9..12.1 | 22.0 | 22.0 | corner / corner | 0.8 / 0.7 | – |

Per side: back 1-high 17.6 m, 2-high 15.5 m; front 1-high 7.8 m, 2-high 19.6 m, neighbours 5.1 m, open 0.6 m; left 1-high 3.6 m, 2-high 6.0 m, neighbours 11.8 m, open 0.6 m; right 1-high 22.0 m.

### Stavros

Ring x -8..5.5, y -7.5..12. 2-high first on: back, left, front. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -8.0..5.6 | 13.6 | 13.6 | corner / corner | 1.2 / 1.0 | – |
| front | -8.0..5.6 | 13.6 | 13.6 | corner / corner | 0.9 / 1.0 | – |
| left | -7.5..12.1 | 19.6 | 19.3 | corner / corner | 0.3 / 1.9 | 9.3..9.6 |
| right | – | – | – | neighbours 19.6 m | – | – |

Per side: back 1-high 12.4 m, 2-high 1.2 m; front 1-high 5.1 m, 2-high 8.5 m; left 1-high 3.0 m, 2-high 16.3 m, open 0.3 m; right neighbours 19.6 m.

Joints over 0.6 m: HBarrier_3@(3.8,12.0) x HBarrier_1@(5.5,11.1): 0.9 m along the first, 0.7 m along the second.

### Telos

Ring x -21..10, y -14..7.6. 2-high first on: front, back, right, left. Flood fill: closed.

| Side | Gap (m along the line) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| back | -21.0..10.1 | 31.1 | 31.1 | corner / corner | 0.9 / 1.1 | – |
| front | -21.0..-15.5 | 5.5 | 5.5 | corner / House_Small_01 | 0.9 / 0.4 | – |
| front | -4.3..10.1 | 14.4 | 13.9 | House_Small_01 / corner | 0.4 / 1.0 | -0.1..0.4 |
| left | -14.0..-10.2 | 3.8 | 3.8 | corner / city wall | 1.1 / 4.1 | – |
| left | -3.1..4.5 | 7.6 | 7.6 | city wall / city wall | 4.1 / 3.6 | – |
| left | 5.1..7.7 | 2.6 | 2.6 | city wall / corner | 4.1 / 0.4 | – |
| right | -14.0..5.1 | 19.1 | 19.1 | corner / city wall | 1.2 / 3.4 | – |
| right | 5.6..7.7 | 2.1 | 2.1 | city wall / corner | 4.1 / 0.8 | – |

Per side: back 2-high 31.1 m; front 1-high 19.4 m, neighbours 11.2 m, open 0.5 m; left 1-high 10.9 m, 2-high 3.1 m, neighbours 7.7 m; right 1-high 4.0 m, 2-high 17.2 m, neighbours 0.5 m.

## What to check in the game

1. **Closure ("closed: no way out") in all ten rings.** The ends I trust least, most doubtful first:
   - **Stavros' right side:** the joint between the two neighbour houses (House_Big_01 and House_Small_02), and
     the 0.8 m corridor between the office and them.
   - **Gravia:** the damaged city wall the left line crosses. If a man gets through its breach, the line has to
     run round it, through the 0.9 m between it and the house, which needs a sandbag or a 1-high piece turned
     along.
   - **The building ends** (each probe box against the building's real wall):
     - Dorida: House_Big_02, Shop_02, Garage.
     - Alikampos, Gravia: House_Big_01.
     - Gravia: Shop_01, House_Small_02.
     - Lakka: Stone_HouseSmall.
     - Neri: House_Big_01, Shop_01.
     - Poliakko: Shop_01.
     - Telos: House_Small_01.
   - **Selakano:** the back line on the track's verge, and the garage's back wall.
2. **The T2 porch bags** sit on the porch floor, dropped onto it. They are the first bags on the porch's middle
   and west end, so check them for clips against the balcony's posts.
3. **The two joints over 0.6 m:**
   - **Lakka:** a 1-high piece beside the stone pillar at (-8.8, -6.6), under the end of the 2-high piece.
   - **Stavros:** the front line's end against the right side's piece at (5.5, 11.1).
4. **T1** is an empty tier (`TIER|1|0`) in every draft.
