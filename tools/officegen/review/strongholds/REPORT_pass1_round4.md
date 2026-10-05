# Strongholds: pass 1, round 4 report (answering pass1_round3.md and KAVALA_DECISION.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. `python tools/officegen/drafting/strongholds.py`
rebuilds the drafts and prints the closure per tier and per ring; `--audit` adds the line audit and `--map N` draws
tier N.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala (hospital) | 0 / 0 / 0 | 9 / 0 / 0 | 58 / 0 / 0 | 113 / 0 / 0 | 134 / 0 / 0 |
| Pyrgos (unchanged) | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 96 / 0 / 0 | 106 / 0 / 0 |
| Athira (unchanged) | 0 / 0 / 0 | 5 / 0 / 0 | 19 / 0 / 0 | 52 / 0 / 0 | 56 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 28 / 0 / 0 | 66 / 0 / 0 | 70 / 0 / 0 |

## Kavala: the hospital ring, built to your design (probe to 72 m)

The round 2 walk crossed the hospital's probed ground floor and side2's box, so my closure check treats the whole
complex (the plan and both wings' boxes) as open ground. Every ring closes on its own pieces, the cliff's rocks and
the tall canal walls, never on the building.

- **T2:** as before. A long bag 2 m out of each door that opens outside, and bags along the main strip's forecourt
  face (x -8.9) and its south front (y -22.7).
- **T3, H-barriers 1.5-2 m round the whole complex** (the south block under the helipad, the main strip and side1):
  - south line at y -24.3, between the south front and the road;
  - east line at x 18.2, between the strip and the service yard;
  - round side1's north end at y 45.3, standing into the low concrete wall there (the brief's upgrade);
  - down the forecourt side of side1 and the strip at x -10.5;
  - along the south block's north face at y -2;
  - down its west end at x -39.5, on the west road's shoulder.

  A few cut through the boxes, so whether any piece runs into the real building is for your clip check. The ring
  stays 1.5 m or more outside the probed walls.
- **T4, Mil walls along the road edges into the cliff:**
  - the south road's north edge at y -26, from the west road to the rocks;
  - the west road's east edge at x -41.3, then north-east along the road, about 5.5 m off its middle, to
    (-20.9, 60.5);
  - the north side east into the line of tall canal walls (5.5 m, real barriers). It runs from (-12, 61) to the
    cliff, and I filled the two 7 m gaps between the walls. The cliff closes the east.
  - Inside it: the forecourt with its planter, the service yard and the whole complex. It crosses the low walls in
    its way at junctions.
- **T5:** the T3 ring in Mil walls (T3's H-barriers dropped).
- **Closure (my check, from your walk's start (13.1, -6.1)):** T3, T4 and T5 closed, with everything standing and
  with each ring on its own. T1 and T2 come out open.
- **What I can't see from the probe:** the real building. The game will show whether any T3 or T5 piece runs into
  it (the line along the south block's north face, the west line by the block's west end, the line round side1's
  north end).

## Zaros

- **T3 leaking round the west line's ends.** The ring capped against the house can't seal at the front. The shop's
  box margin there is open ground, and `tl.check()` keeps pieces out of it, so the walk went round the cap past the
  shop's corner. **No ring touches the house now:**
  - T3 wraps the house and the shop hard against its front (attached to it): behind the shop at y -18; along the
    shop's and the house's west side at x -8.6, standing into the yard's low walls where it meets them; on the main
    road's shoulder at x 13.2.
  - It's capped into Addon_03's west face (y 9.5) and, across the garden standing on its low south wall, its east
    face (y 9.2). Addon_03 has held T4 and T5 since round 2.
  - T5 is the same ring in Mil walls.
  - T4's east face moved out to x 15, on the road. That's 2.5 m into the probe's 10 m road width, outside T3's
    shoulder line; the road stays open.
- **Pieces cutting into the house:** the veranda bags moved another 0.5 m out to x -6.6. No H-barrier or Mil wall
  stands near the house any more.
- **Closure (my check, from the veranda (-5, 2.5)):** T3, T4 and T5 closed, with everything standing and with each
  ring on its own.

## Athira and Pyrgos

Unchanged. Athira is closed in the game at T3-T5. Pyrgos' closure rests on my audit (REPORT_pass1_round2.md).

## Line audit per ring (Kavala, Zaros)

"FREE" ends are corners: they overlap the crossing run's piece. "part:Hospital…" ends don't count at Kavala; every
ring there closes on its own pieces, the rocks and the canal walls.


### Kavala

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line | 59.4 | 60.1 | 11 HB5 | 0.37, 0.37 | corner, HB5 | corner, HB3 |
| T3 | north line, round side1's north end (into the low wall) | 30.4 | 31.0 | 5 HB5 + 1 HB3 | 0.31, 0.31 | corner, HB5 | corner, HB5 |
| T3 | east line, along the main strip and side1 (1/2) | 2.9 | 3.6 | 1 HB3 | 0.35, 0.35 | piece HB5 | low wall net_fence_4m (box) |
| T3 | east line, along the main strip and side1 (2/2) | 64.6 | 65.4 | 12 HB5 | 0.38, 0.38 | piece HB3 | piece HB5 |
| T3 | forecourt line, side1 down to the south block | 47.3 | 48.2 | 9 HB5 | 0.49, 0.49 | piece HB3 | corner, HB5 |
| T3 | along the south block's north face | 29.0 | 30.0 | 5 HB5 + 1 HB3 | 0.51, 0.51 | piece HB5 | corner, HB5 |
| T3 | west line, along the south block's west end | 20.5 | 21.6 | 4 HB5 | 0.54, 0.54 | piece HB3 | piece HB5 |
| T4 | south road's edge to the cliff | 65.7 | 66.6 | 18 Mil | 0.42, 0.42 | corner, Mil | rock:sharprock_wallh (box) |
| T4 | west road's edge | 39.4 | 40.4 | 11 Mil | 0.47, 0.47 | piece Mil | corner, Mil |
| T4 | west road's edge, turning north-east | 16.3 | 16.6 | 4 Mil + 1 Cnc1 | 0.30, 0.05 | piece Mil | corner, Mil |
| T4 | west road's edge, turning north-east | 22.1 | 22.8 | 6 Mil | 0.35, 0.35 | piece Mil | corner, Mil |
| T4 | west road's edge, turning north-east | 11.4 | 11.7 | 3 Mil | 0.30, -0.03 | piece Mil | corner, CncWall1 |
| T4 | north side into the first canal wall (1/2) | 4.0 | 4.6 | 4 Cnc1 | 0.35, 0.22 | piece Mil | low wall concrete_smallwall_4m (box) |
| T4 | north side into the first canal wall (2/2) | 3.8 | 4.2 | 4 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_4m (box) | low wall canal_wall_10m (box) |
| T4 | north side, between the canal walls | 7.2 | 7.9 | 2 Mil | 0.32, 0.32 | low wall canal_wall_10m (box) | low wall canal_wall_10m (box) |
| T4 | north side, between the canal walls | 7.2 | 7.9 | 2 Mil | 0.32, 0.32 | low wall canal_wall_10m (box) | low wall canal_wall_10m (box) |
| T5 | south line | 58.8 | 59.6 | 16 Mil | 0.40, 0.40 | corner, Mil | corner, Mil |
| T5 | north line, round side1's north end (into the low wall) | 29.8 | 30.5 | 8 Mil | 0.33, 0.33 | corner, Mil | corner, Mil |
| T5 | east line, along the main strip and side1 (1/2) | 3.2 | 4.1 | 1 Mil | 0.45, 0.45 | piece Mil | low wall net_fence_4m (box) |
| T5 | east line, along the main strip and side1 (2/2) | 64.8 | 65.8 | 18 Mil | 0.47, 0.47 | piece Mil | piece Mil |
| T5 | forecourt line, side1 down to the south block | 47.3 | 48.2 | 13 Mil | 0.43, 0.43 | piece Mil | corner, Mil |
| T5 | along the south block's north face | 29.0 | 29.8 | 8 Mil | 0.42, 0.42 | piece Mil | corner, Mil |
| T5 | west line, along the south block's west end | 21.2 | 22.2 | 6 Mil | 0.49, 0.49 | piece Mil | piece Mil |

### Zaros

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line, behind the shop | 23.5 | 24.6 | 4 HB5 + 1 HB3 | 0.55, 0.55 | corner, HB1 | corner, HB5 |
| T3 | north-west cap into Addon_03 | 4.6 | 4.7 | 1 HB3 + 1 HB1 | -0.25, 0.30 | FREE | i_Addon_03_V1 (box) |
| T3 | north-east cap across the garden into Addon_03 (1/2) | 6.1 | 6.8 | 1 HB5 + 1 HB1 | 0.35, 0.35 | corner, HB5 | low wall concrete_smallwall_8m (box) |
| T3 | north-east cap across the garden into Addon_03 (2/2) | 2.1 | 3.0 | 3 HB1 | 0.59, 0.38 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T3 | west line, along the shop and the house (1/2) | 1.2 | 2.3 | 2 HB1 | 0.53, 0.53 | piece HB5 | low wall city2_8m (box) |
| T3 | west line, along the shop and the house (2/2) | 22.5 | 23.2 | 4 HB5 + 1 HB1 | 0.36, 0.36 | low wall city2_8m (box) | low wall concrete_smallwall_4m (box) |
| T3 | east line, the road's shoulder | 25.4 | 26.6 | 5 HB5 | 0.60, 0.60 | piece HB3 | piece HB5 |
| T4 | south face, the south ground | 39.1 | 40.1 | 11 Mil | 0.50, 0.50 | corner, Mil | corner, Mil |
| T4 | east face, on the road | 32.1 | 33.1 | 9 Mil | 0.48, 0.48 | piece Mil | corner, Mil |
| T4 | north-east cap across the garden into Addon_03 (1/2) | 6.6 | 7.7 | 2 Mil | 0.52, 0.52 | piece Mil | low wall concrete_smallwall_8m (box) |
| T4 | north-east cap across the garden into Addon_03 (2/2) | 2.0 | 2.5 | 2 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T4 | west face, outside the yard's west wall | 34.0 | 34.5 | 9 Mil | 0.30, 0.20 | piece Mil | corner, Mil |
| T4 | north-west cap into Addon_03 | 17.7 | 18.5 | 5 Mil | 0.49, 0.38 | piece Mil | i_Addon_03_V1 (box) |
| T5 | south line, behind the shop | 22.7 | 23.1 | 6 Mil | 0.20, 0.20 | corner, CncWall1 | corner, Mil |
| T5 | north-west cap into Addon_03 | 4.3 | 5.0 | 1 Mil + 1 Cnc1 | 0.47, 0.22 | FREE | i_Addon_03_V1 (box) |
| T5 | north-east cap across the garden into Addon_03 (1/2) | 5.6 | 6.2 | 1 Mil + 2 Cnc1 | 0.34, 0.22 | corner, Mil | low wall concrete_smallwall_8m (box) |
| T5 | north-east cap across the garden into Addon_03 (2/2) | 2.1 | 2.5 | 2 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T5 | west line, along the shop and the house (1/2) | 1.5 | 2.3 | 2 Cnc1 | 0.54, 0.22 | piece Mil | low wall city2_8m (box) |
| T5 | west line, along the shop and the house (2/2) | 22.5 | 23.1 | 6 Mil | 0.31, 0.31 | low wall city2_8m (box) | low wall concrete_smallwall_4m (box) |
| T5 | east line, the road's shoulder | 26.1 | 26.8 | 7 Mil | 0.32, 0.32 | piece Mil | piece Mil |

## What to check in the game

1. **Kavala:**
   - the walk from (13.1, -6.1), T3-T5;
   - any T3 or T5 piece clipping the hospital;
   - T4's west line on the west road's shoulder and the walls filling the gaps between the canal walls.
2. **Zaros:**
   - the walk from (-5, 2.5), T3-T5;
   - T3's east line (x 13.2) and T4's east face (x 15) on the main road: does traffic still pass?
   - any clip left on the house.

