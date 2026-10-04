# Strongholds: pass 1, round 2 report (answering pass1_round1.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. `python tools/officegen/drafting/strongholds.py`
rebuilds the drafts and prints the closure per tier and per ring; `--audit` adds the line audit and `--map N` draws
tier N.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala | 0 / 0 / 0 | 9 / 0 / 0 | 32 / 0 / 0 | 93 / 0 / 0 | 100 / 0 / 0 |
| Pyrgos | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 96 / 0 / 0 | 106 / 0 / 0 |
| Athira | 0 / 0 / 0 | 5 / 0 / 0 | 20 / 0 / 0 | 49 / 0 / 0 | 54 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 16 / 0 / 0 | 53 / 0 / 0 | 56 / 0 / 0 |

Materials:
- **T2:** sandbags.
- **T3:** 1-high H-barriers (`_5`, `_3`, `_1`).
- **T4:** `Land_Mil_WallBig_4m_F`, with `Land_CncWall1_F` to make up lengths.
- **T5:** T5 drops T3's H-barriers and draws the same T3 lines again in Mil walls. So T5 holds two complete
  high-walled rings, the raised inner ring and the T4 outer ring, with the yards between them. That is why T5 has
  only a few more things than T4.

## What changed (the critique's points)

- **The rings no longer hug the building.** T3 is the tight ring, T4 goes back out round the compound like round 6's
  lines but in high walls, and T5 raises T3 in place:
  - **Kavala:** a forward yard walled out into the square: face at y -30.5 (x -10..21), west side at x -10 along
    House_Big_01's end, then the square face at y -21 west of it. With it, the west yard and the north yard to
    Addon_02 (outside the old city wall), and the street face. There is now 16 m of ground in front of the inner
    ring.
  - **Pyrgos:** round the west lot, the lane north and the square's north half: x -32..24, y -27..21.5. That is
    6-12 m outside the inner ring all round, crossing the square's path fences, the lot's fences and the low walls
    at junctions.
  - **Athira:** round the courtyard, the strip north of it, the west lot and the lane south. In order:
    - the west lot's mouth, from House_Small_01 to the scaffolding;
    - the lane north, into House_Small_02;
    - a cap across the corridor north (y 11.33) east past the courtyard's opening to x 22;
    - down to the courtyard's slanting wall;
    - along the shop's north-west and south-west faces, 0.6 m off its box;
    - the south face (y -13, past House_Big_02's tip) back to House_Small_01.

    The shop and both House_Big_02s have walkable ground inside their boxes that `tl.check()` won't let a piece
    stand on, so the ring lines the shop instead of tying into it.
  - **Zaros:** round the whole block: the yard (x -23, outside its west wall, with Addon_02), the south ground
    (y -21.5, inside the stone wall), the shop, and the strip on the road's shoulder (x 13). It is capped into
    Addon_03 across the garden (y 10.6) and on its west (y 12.5).
- **Athira T3's ways out.** The in-game walk starts at (6.7, -1.5), and my T3 east line stood on that spot
  (x 6.65..8.35), so the walker was put outside it. All four reported gaps follow from that start. The east line
  is now at x 8.8, and my check run from (6.7, -1.5) finds T3, T4 and T5 closed, both with everything standing and
  with each ring on its own.
- **Zaros' clips into the house.** The caps now stop flush at the house's probed walls (0-0.12 m, they used to run
  0.33 m in). The west line moved from x -6.6 to x -7.0, Athira's position, which the game didn't flag. The
  veranda bags moved from x -5.2 to -5.55, past Athira's -5.3, which wasn't flagged. If the game still flags a
  piece against the house, the house's porch reaches further than its probed plan, and I'd need its outline.
- **`Land_CncWall1_F`** now uses its measured 1.4 m length (in `townlib.py`'s CLASSES too).

## Closure

My check floods a 0.2 m grid outward from the door to 44 m out:
- **Start:** 1.5 m out of the main door; from the veranda at Zaros.
- **Walker:** 0.5 m wide.
- **What stops him:** the office's plan, each neighbour's real walls where planned (otherwise its box), rocks, and
  every piece at its measured size.
- **The probed walls:** all are low. They stop him only where a line ends into one (a junction).
- **Neighbours' box margins:** open ground.

Results, for every tier from 3 up, with everything standing and with each ring on its own:
- Kavala, Pyrgos and Athira: every tier closed, and every ring closed on its own.
- Zaros: every tier closed, and every ring closed on its own. Its T5 ring is now the raised T3 ring, so it no
  longer relies on T3 at the shop front.

For Kavala and Pyrgos, which the game can't check, the line audits below carry closure. Every run's two ends are
named: a building, a low wall at a junction, or a corner with the next run.

## Line audit per ring

T5's ring is T3's lines redrawn in Mil walls, so its runs are listed under T5 with the same names. "Already shut"
means the neighbouring pieces overlap, so no piece was needed. A "box" end is a neighbour's bounding box: Addon_01,
Addon_02, Addon_03, House_Small_01, House_Small_02 and the scaffolding have no probed plan and are solid to their
box.


### Kavala

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line, west corner to east corner | 35.2 | 36.0 | 6 HB5 + 1 HB3 | 0.40, 0.40 | corner, HB5 | corner, HB1 |
| T3 | west line, south line to the chamfer | 22.0 | 22.3 | 4 HB5 | 0.30, -0.00 | piece HB5 | corner, HB3 |
| T3 | north-west chamfer | 3.4 | 3.6 | 1 HB3 | 0.30, -0.08 | piece HB5 | corner, HB5 |
| T3 | north line, chamfer to Addon_01 | 20.8 | 21.7 | 4 HB5 | 0.50, 0.38 | piece HB3 | u_Addon_01_V1 (box) |
| T3 | east line, south line to the forecourt wall | 2.1 | 3.1 | 3 HB1 | 0.53, 0.53 | piece HB3 | low wall city_4m (box) |
| T3 | east line along the office, wall to the cap | 4.3 | 4.7 | 1 HB3 + 1 HB1 | 0.30, 0.07 | piece HB1 | corner, HB1 |
| T4 | forward yard's face, street to its west corner | 32.3 | 33.2 | 9 Mil | 0.46, 0.46 | corner, Mil | corner, Mil |
| T4 | forward yard's west side, along House_Big_01's end | 9.0 | 9.0 | 2 Mil + 1 Cnc1 | 0.30, -0.27 | piece Mil | corner, Mil |
| T4 | square face, forward yard to the west corner | 27.7 | 28.8 | 8 Mil | 0.57, 0.57 | piece Mil | corner, Mil |
| T4 | west face, square face to the old wall | 9.1 | 9.8 | 2 Mil + 2 Cnc1 | 0.39, 0.39 | piece Mil | corner, Mil |
| T4 | outside the old city wall, west corner to the north | 49.3 | 49.7 | 13 Mil | 0.30, 0.14 | piece Mil | corner, CncWall1 |
| T4 | across the old city wall | 1.8 | 2.4 | 2 Cnc1 | 0.39, 0.22 | piece Mil | low wall city_8m (box) |
| T4 | old city wall to Addon_02 | 10.4 | 11.3 | 3 Mil | 0.52, 0.38 | low wall city_8m (box) | i_Addon_02_V1 (box) |
| T4 | north side, Addon_02 to the low wall (the street face beyond) | 10.6 | 11.4 | 3 Mil | 0.38, 0.46 | i_Addon_02_V1 (box) | low wall city_8m (box) |
| T4 | street face, north corner to the bend | 18.8 | 19.3 | 5 Mil | 0.25, 0.25 | corner, Mil | corner, Mil |
| T4 | street face, bend to the forward yard | 38.4 | 39.5 | 11 Mil | 0.56, 0.56 | piece Mil | piece Mil |
| T5 | south line, west corner to east corner | 35.2 | 36.3 | 10 Mil | 0.53, 0.53 | corner, Mil | corner, CncWall1 |
| T5 | west line, south line to the chamfer | 22.3 | 23.0 | 6 Mil | 0.33, 0.33 | piece Mil | corner, Mil |
| T5 | north-west chamfer | 3.2 | 4.1 | 1 Mil | 0.44, 0.44 | piece Mil | corner, Mil |
| T5 | north line, chamfer to Addon_01 | 20.7 | 21.7 | 6 Mil | 0.59, 0.38 | piece Mil | u_Addon_01_V1 (box) |
| T5 | east line, south line to the forecourt wall | 2.4 | 3.2 | 3 Cnc1 | 0.51, 0.22 | piece Mil | low wall city_4m (box) |
| T5 | east line along the office, wall to the cap | 4.4 | 5.1 | 1 Mil + 1 Cnc1 | 0.38, 0.38 | low wall city_4m (box) | corner, CncWall1 |

T3 and T5 also each hold two pieces placed by hand: an `HB1` at T3 (a `CncWall1` at T5). One is the cap at (14.25, -6.6), its west end against the office's east face; the other is the plug at (14.4, 8.5) where the office meets Addon_01.

### Pyrgos

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line | 36.7 | 37.7 | 7 HB5 | 0.49, 0.49 | corner, HB5 | corner, HB5 |
| T3 | north line | 36.7 | 37.7 | 7 HB5 | 0.49, 0.49 | corner, HB3 | corner, HB3 |
| T3 | west line | 23.8 | 24.8 | 4 HB5 + 1 HB3 | 0.50, 0.50 | piece HB5 | piece HB5 |
| T3 | east line | 23.8 | 24.8 | 4 HB5 + 1 HB3 | 0.50, 0.50 | piece HB5 | piece HB5 |
| T4 | square face (1/4) | 33.1 | 33.8 | 9 Mil | 0.38, 0.38 | corner, CncWall1 | low wall pipe_fence_4m (box) |
| T4 | square face (2/4) | -0.1 | 0.0 | none (already shut) | 0.00, 0.00 | low wall pipe_fence_4m (box) | low wall pipe_fence_4m (box) |
| T4 | square face (3/4) | 16.0 | 16.6 | 4 Mil + 1 Cnc1 | 0.30, 0.30 | low wall pipe_fence_4m (box) | low wall city2_8m (box) |
| T4 | square face (4/4) | 5.4 | 6.2 | 1 Mil + 2 Cnc1 | 0.37, 0.37 | low wall city2_8m (box) | corner, Mil |
| T4 | east face, the hill's foot | 48.6 | 49.2 | 13 Mil | 0.34, 0.34 | piece CncWall1 | corner, Mil |
| T4 | north face, beyond the lane | 56.0 | 56.7 | 15 Mil | 0.35, 0.35 | piece Mil | corner, Mil |
| T4 | west face, round the west lot (1/5) | 3.3 | 4.1 | 1 Mil | 0.38, 0.38 | piece Mil | low wall city2_8m (box) |
| T4 | west face, round the west lot (2/5) | 3.2 | 4.1 | 1 Mil | 0.43, 0.43 | low wall city2_8m (box) | low wall concrete_smallwall_8m (box) |
| T4 | west face, round the west lot (3/5) | 6.1 | 6.8 | 1 Mil + 3 Cnc1 | 0.50, 0.22 | low wall concrete_smallwall_8m (box) | low wall pipe_fence_4m (box) |
| T4 | west face, round the west lot (4/5) | 32.7 | 33.5 | 9 Mil | 0.42, 0.42 | piece CncWall1 | low wall pipe_fence_4m (box) |
| T4 | west face, round the west lot (5/5) | 0.2 | 1.4 | 1 Cnc1 | 0.57, 0.57 | piece Mil | piece Mil |
| T5 | south line | 36.7 | 37.5 | 10 Mil | 0.39, 0.39 | corner, Mil | corner, Mil |
| T5 | north line | 36.7 | 37.5 | 10 Mil | 0.39, 0.39 | corner, Mil | corner, Mil |
| T5 | west line | 24.4 | 25.5 | 7 Mil | 0.54, 0.54 | piece Mil | piece Mil |
| T5 | east line | 24.4 | 25.5 | 7 Mil | 0.54, 0.54 | piece Mil | piece Mil |

### Athira

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line, west corner to the low wall | 3.1 | 3.6 | 1 HB3 | 0.18, 0.30 | corner, HB5 | low wall city_8m (box) |
| T3 | south line, low wall to the east corner | 13.9 | 14.5 | 2 HB5 + 1 HB3 | 0.33, 0.33 | low wall city_8m (box) | corner, HB5 |
| T3 | west line | 19.3 | 20.0 | 3 HB5 + 1 HB3 | 0.33, 0.33 | piece HB3 | corner, HB1 |
| T3 | west cap into House_Small_02 | 0.5 | 1.4 | 1 HB1 | 0.52, 0.38 | piece HB3 | i_House_Small_02_V1 (box) |
| T3 | east line, south line to the courtyard wall | 16.9 | 17.6 | 3 HB5 + 1 HB1 | 0.39, 0.39 | piece HB3 | low wall city_8m (box) |
| T3 | east cap into House_Small_02 | 6.0 | 6.8 | 1 HB5 + 1 HB1 | 0.41, 0.38 | FREE | i_House_Small_02_V1 (box) |
| T4 | south face, House_Small_01 to the shop (1/2) | 10.8 | 11.5 | 3 Mil | 0.38, 0.39 | i_House_Small_01_V3 (box) | low wall city_8m (box) |
| T4 | south face, House_Small_01 to the shop (2/2) | 27.7 | 28.6 | 8 Mil | 0.60, 0.38 | low wall city_8m (box) | i_Shop_02_V2(box; its wall 3.2 m on) |
| T4 | along the shop's south-west face | 8.1 | 8.9 | 2 Mil + 1 Cnc1 | 0.37, 0.37 | piece Mil | corner, Mil |
| T4 | along the shop's north-west face to the slanting wall | 12.0 | 12.7 | 3 Mil + 1 Cnc1 | 0.34, 0.34 | piece Mil | low wall city_8m (box) |
| T4 | cap across the corridor into House_Small_02 | 18.9 | 19.3 | 5 Mil | 0.10, 0.30 | corner, Mil | i_House_Small_02_V1 (box) |
| T4 | down to the courtyard's slanting wall | 7.0 | 7.8 | 2 Mil | 0.40, 0.40 | piece Mil | low wall city_8m (box) |
| T4 | west lot's mouth, House_Small_01 to the scaffolding | 7.2 | 7.9 | 2 Mil | 0.35, 0.35 | i_House_Small_01_V3 (box) | scaffolding (box) |
| T4 | across the lane north into House_Small_02 | 7.0 | 7.8 | 2 Mil | 0.38, 0.38 | scaffolding (box) | i_House_Small_02_V1 (box) |
| T5 | south line, west corner to the low wall | 3.1 | 4.1 | 1 Mil | 0.49, 0.49 | corner, Mil | low wall city_8m (box) |
| T5 | south line, low wall to the east corner | 13.9 | 14.9 | 4 Mil | 0.51, 0.51 | low wall city_8m (box) | corner, Mil |
| T5 | west line | 19.7 | 20.3 | 5 Mil + 1 Cnc1 | 0.32, 0.32 | piece Mil | corner, CncWall1 |
| T5 | west cap into House_Small_02 | 0.9 | 1.4 | 1 Cnc1 | 0.30, 0.22 | piece Mil | i_House_Small_02_V1 (box) |
| T5 | east line, south line to the courtyard wall | 17.2 | 18.3 | 5 Mil | 0.55, 0.55 | piece Mil | low wall city_8m (box) |
| T5 | east cap into House_Small_02 | 6.0 | 6.3 | 1 Mil + 2 Cnc1 | 0.08, 0.22 | corner, Mil | i_House_Small_02_V1 (box) |

### Zaros

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south-west cap against the veranda's edge | 3.3 | 3.6 | 1 HB3 | 0.13, 0.12 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | north-west cap against the house | 3.3 | 3.6 | 1 HB3 | 0.13, 0.12 | corner, HB3 | the office i_House_Big_01_V1 |
| T3 | west line | 9.2 | 10.0 | 1 HB5 + 1 HB1 + 1 HB3 | 0.40, 0.40 | piece HB3 | piece HB3 |
| T3 | south-east cap against the house | 4.2 | 4.7 | 1 HB3 + 1 HB1 | 0.33, 0.12 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | north-east cap against the house | 4.2 | 4.7 | 1 HB3 + 1 HB1 | 0.33, 0.12 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | east line | 10.9 | 11.9 | 2 HB5 + 1 HB1 | 0.54, 0.54 | piece HB3 | piece HB3 |
| T4 | south face, the south ground | 37.1 | 37.8 | 10 Mil | 0.35, 0.35 | corner, Mil | corner, Mil |
| T4 | east face, the road's shoulder | 32.1 | 33.1 | 9 Mil | 0.48, 0.48 | piece Mil | corner, Mil |
| T4 | north-east cap across the garden into Addon_03 (1/2) | 4.6 | 5.2 | 1 Mil + 1 Cnc1 | 0.30, 0.22 | piece Mil | low wall concrete_smallwall_8m (box) |
| T4 | north-east cap across the garden into Addon_03 (2/2) | 2.0 | 2.5 | 2 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T4 | west face, outside the yard's west wall | 34.0 | 34.5 | 9 Mil | 0.30, 0.20 | piece Mil | corner, Mil |
| T4 | north-west cap into Addon_03 | 17.7 | 18.5 | 5 Mil | 0.49, 0.38 | piece Mil | i_Addon_03_V1 (box) |
| T5 | south-west cap against the veranda's edge | 3.3 | 3.6 | 3 Cnc1 | 0.10, 0.15 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | north-west cap against the house | 3.3 | 3.6 | 3 Cnc1 | 0.10, 0.15 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | west line | 10.0 | 11.1 | 3 Mil | 0.59, 0.59 | piece CncWall1 | piece CncWall1 |
| T5 | south-east cap against the house | 4.2 | 4.1 | 1 Mil | -0.15, 0.00 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | north-east cap against the house | 4.2 | 4.1 | 1 Mil | -0.15, 0.00 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | east line | 11.6 | 12.4 | 3 Mil + 1 Cnc1 | 0.43, 0.43 | piece Mil | piece Mil |

## What to check in the game

1. **Zaros, the caps against the house:** do they still clip now that they stop flush with its probed walls? And
   is T3-T5 still closed?
2. **Athira, closure from the walk's start (6.7, -1.5):** T3-T5. Also the T4 corner where the south face and the
   lining meet at the shop's south corner (22.9, -13).
3. **Kavala and Pyrgos, from the screenshots:** the forward yard's face (y -30.5) and the T4 rings' junctions with
   the low walls and pipe fences.
4. **The road shoulders:** Kavala's street face (x 20.6) and Zaros' east face (x 13).

