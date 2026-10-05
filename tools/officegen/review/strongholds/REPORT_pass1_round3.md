# Strongholds: pass 1, round 3 report (answering pass1_round2.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. `python tools/officegen/drafting/strongholds.py`
rebuilds the drafts and prints the closure per tier and per ring; `--audit` adds the line audit and `--map N` draws
tier N.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala (hospital) | 0 / 0 / 0 | 9 / 0 / 0 | 30 / 0 / 0 | 72 / 0 / 0 | 83 / 0 / 0 |
| Pyrgos | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 96 / 0 / 0 | 106 / 0 / 0 |
| Athira | 0 / 0 / 0 | 5 / 0 / 0 | 19 / 0 / 0 | 52 / 0 / 0 | 56 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 16 / 0 / 0 | 53 / 0 / 0 | 56 / 0 / 0 |

Kavala and Pyrgos are unchanged from round 2. Kavala needs a decision from you first (below).

## Kavala: what you asked for can't pass `tl.check()` as the probe stands. I need a decision.

The round 2 routes show the hospital is not the solid block the probe makes it:
- The walk runs west along y -17 from x 3 to x -37, through what the probe gives as the main block's ground floor
  and side2. That ground is open, like a covered car park under the helipad block.
- It also crosses side2's box at y -1, between x -16 and -34.
- Both wings' boxes reach several metres past the buildings. Side2's box runs to x -44.9, onto the west road;
  your top view puts the helipad block's west end at about x -40.

A ring round the building and its wings, or T4 along the forecourt's west and south street edges, has to stand
in exactly the places `tl.check()` forbids:
1. **Inside the wings' boxes** (side2: x -44.9..-11.1, y -22.6..2.5; side1: x -8..17.5, y 20.8..44.4) and inside
   the main block's probed floor (x -38..16, y -22..-5). `check()` holds every piece's middle out of a building's
   or part's box and off the office's plan. The forecourt's west street edge runs at x ≈ -40, which is inside
   side2's box for y -22.6..2.5. The south block's open ground under the helipad is inside the plan.
2. **More than 46 m from the office's origin** (the probe's reach). The hospital's corners are 45-52 m out:
   - side2's south-west corner (-44.9, -22.6) is 50 m out;
   - the forecourt's north end runs past y 45;
   - the west edge at (-40, -25) is 47 m out.

   So no ring can go round them.

Any closed ring at Kavala needs one of these:
- **(a)** Let pieces stand in the hospital wings' boxes and the main block's open ground floor. That means changing
  `townlib.check()`, for Kavala or for Hospital parts. Your in-game clip check will still catch a piece that runs
  into the real building.
- **(b)** Re-probe Kavala with a larger radius (about 70 m), and give the wings' real outlines (their building
  positions, or a floor plan for side1 and side2 in `probe_offices.txt`), so the boxes stop standing in for them.

With (a) and a 52 m distance limit, I'd build your design:
- **T3:** H-barriers 1.5 m round the whole complex. That means the helipad block's south face just north of the
  south road, its west face at about x -41.5, the forecourt side of the north strip, and side1's north end.
- **T4:** high walls along the south road's edge (y ≈ -28) and the west road's edge (x ≈ -40), turning east north
  of the forecourt into the cliff and tied into the rocks on the east.
- **T5:** the T3 ring in high walls.

I've left Kavala as it was rather than add pieces I know `tl.check()` rejects. Round 2's T4 lines through the
forecourt (the ones that box the planter) are known wrong, and I'll replace them once the rules allow it.

## Athira

- **House_Small_02 is not solid.** Your walk starts at (0, 9.2), behind the house, and walks through House_Small_02's
  box at (0.5, 16.4) and (-3.1, 20). So my caps into its faces were no tie at all, and both T3 "gaps" come from that
  start. No ring touches House_Small_02 now: the rings close on the house itself. My closure check now treats
  House_Small_02 as open ground.
  - **T3:** H-barriers at y -10.75, x -6.8 and x 8.8.
    - **West cap:** at y 2.6, against the north room's west face.
    - **North-east cap:** stands on the courtyard's low wall at y 8.35, along its length (the brief's "upgrading
      an existing wall"), running from the east line to the house's north-east corner. This keeps the side door
      inside.
  - **T4:** the courtyard, the strip and the west lot as before. On the north side it no longer ties into
    House_Small_02:
    - The lane north is crossed at y 5.4, from the scaffolding into the house's west face.
    - The cap across the corridor (y 11.33) ends in an H-barrier dropping onto the house's north face at x 4.25.
  - **T5:** the T3 lines in Mil walls, the west one out at x -8.5, outside the house's bounding box.
- **Your walk's start is now outside every ring.** (0, 9.2) is in House_Small_02's yard, behind the house, which is
  the one side the rings can't close (its box is open ground, and `tl.check()` keeps pieces out of it). **Please
  start Athira's walk from the front**, the veranda or 1.5 m out of the main door at (-3.3, -8.8). From there my
  check finds T3, T4 and T5 closed, with everything standing and with each ring on its own.
- **The Mil wall cutting the house at T5** was the north-east cap, a 4.7 m wall under the house's eaves. The caps
  beside the house now stay H-barriers at T5, and the Mil lines stand outside the house's box. The T2 side door's
  bag moved from y 5.0 to y 4.4.

## Zaros

- **Pieces cutting into the house:**
  - Round 2's veranda bags (0.8-1.05 m off the probed wall) and the H-barriers ending flush still clipped. The
    house reaches past its probed plan.
  - The bags now stand 1.6 m off (x -6.1). The H-barrier lines moved out to x -7.6 and x 9.4.
  - Every cap now stops 0.2-0.35 m short of the probed walls. That still closes for a 0.5 m man.
  - At T5 the caps stay H-barriers, and the Mil lines stand at x -8.5 and x 9.4, outside the house's box, so they
    clear the eaves.
- **Your walk's start (0, -9) is inside the shop's box**, in front of the house. The rings close on the shop's edge
  there, so that start is outside them too. **Please start Zaros' walk on the veranda's open west side**
  (-5, 2.5), the way out of the main door. My check from there: T3, T4 and T5 closed, with everything standing and
  with each ring on its own.

## Closure (my check, from the front of each office)

| Town | T3 | T4 | T5 |
|---|---|---|---|
| Pyrgos (unchanged) | closed, ring closed | closed, ring closed | closed, ring closed |
| Athira | closed, ring closed | closed, ring closed | closed, ring closed |
| Zaros | closed, ring closed | closed, ring closed | closed, ring closed |
| Kavala | see above: not closable under the current rules | | |

## Line audit per ring (Athira, Zaros; Pyrgos as in REPORT_pass1_round2.md)

"Office" ends stop 0.2-0.35 m short of the house's probed wall. Those are the ends the audit lists as "OPEN" for a
few tenths of a metre, and my 0.5 m-wide walker can't pass them. "FREE" at Athira's T3 north-east cap means its west
end stops at the house's north-east corner, above the house's north face.


### Athira

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line, west corner to the low wall | 2.9 | 3.6 | 1 HB3 | 0.34, 0.34 | corner, HB5 | low wall city_8m (box) |
| T3 | south line, low wall to the east corner | 13.9 | 14.5 | 2 HB5 + 1 HB3 | 0.33, 0.33 | low wall city_8m (box) | corner, HB5 |
| T3 | west line | 13.3 | 14.3 | 2 HB5 + 1 HB3 | 0.47, 0.47 | piece HB3 | corner, HB1 |
| T3 | west cap against the house's north room | 1.4 | 1.4 | 1 HB1 | 0.30, -0.20 | piece HB3 | the office i_House_Big_01_V3 |
| T3 | east line, south line to the courtyard wall | 16.9 | 17.6 | 3 HB5 + 1 HB1 | 0.39, 0.39 | piece HB3 | low wall city_8m (box) |
| T3 | north-east cap on the courtyard wall, to the house's corner | 4.4 | 4.7 | 1 HB3 + 1 HB1 | 0.15, 0.15 | corner, HB5 | FREE |
| T4 | south face, House_Small_01 to the shop (1/2) | 10.8 | 11.5 | 3 Mil | 0.38, 0.39 | i_House_Small_01_V3 (box) | low wall city_8m (box) |
| T4 | south face, House_Small_01 to the shop (2/2) | 27.7 | 28.6 | 8 Mil | 0.60, 0.38 | low wall city_8m (box) | i_Shop_02_V2(box; its wall 3.2 m on) |
| T4 | along the shop's south-west face | 8.1 | 8.9 | 2 Mil + 1 Cnc1 | 0.37, 0.37 | piece Mil | corner, Mil |
| T4 | along the shop's north-west face to the slanting wall | 12.0 | 12.7 | 3 Mil + 1 Cnc1 | 0.34, 0.34 | piece Mil | low wall city_8m (box) |
| T4 | cap across the corridor and the strip | 18.7 | 19.3 | 5 Mil | 0.31, 0.31 | corner, Mil | corner, HB3 |
| T4 | down to the courtyard's slanting wall | 7.0 | 7.8 | 2 Mil | 0.40, 0.40 | piece Mil | low wall city_8m (box) |
| T4 | down to the house's north face | 3.3 | 3.6 | 1 HB3 | 0.30, -0.20 | piece Mil | the office i_House_Big_01_V3 |
| T4 | west lot's mouth, House_Small_01 to the scaffolding | 7.2 | 7.9 | 2 Mil | 0.35, 0.35 | i_House_Small_01_V3 (box) | scaffolding (box) |
| T4 | across the lane north from the scaffolding | 6.1 | 6.3 | 1 Mil + 2 Cnc1 | 0.30, -0.12 | scaffolding (box) | FREE |
| T4 | lane line's last piece, against the house's west face | 2.1 | 2.5 | 2 HB1 | 0.30, -0.20 | piece CncWall1 | the office i_House_Big_01_V3 |
| T5 | south line, west corner to the low wall | 4.6 | 5.2 | 1 Mil + 1 Cnc1 | 0.36, 0.22 | corner, Mil | low wall city_8m (box) |
| T5 | south line, low wall to the east corner | 13.9 | 14.9 | 4 Mil | 0.51, 0.51 | low wall city_8m (box) | corner, Mil |
| T5 | west line | 13.7 | 14.8 | 4 Mil | 0.55, 0.55 | piece Mil | corner, HB3 |
| T5 | west cap against the house's north room | 3.5 | 3.6 | 1 HB3 | 0.30, -0.20 | piece Mil | the office i_House_Big_01_V3 |
| T5 | east line, south line to the courtyard wall | 17.2 | 18.3 | 5 Mil | 0.55, 0.55 | piece Mil | low wall city_8m (box) |
| T5 | north-east cap on the courtyard wall, to the house's corner | 4.4 | 4.7 | 1 HB3 + 1 HB1 | 0.15, 0.15 | corner, Mil | corner, HB3 |

### Zaros

| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south-west cap against the veranda's edge | 3.9 | 3.6 | 1 HB3 | -0.15, -0.20 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | north-west cap against the house | 3.9 | 3.6 | 1 HB3 | -0.15, -0.20 | corner, HB3 | the office i_House_Big_01_V1 |
| T3 | west line | 9.2 | 10.0 | 1 HB5 + 1 HB1 + 1 HB3 | 0.40, 0.40 | piece HB3 | piece HB3 |
| T3 | south-east cap against the house | 4.7 | 4.7 | 1 HB3 + 1 HB1 | 0.15, -0.20 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | north-east cap against the house | 4.7 | 4.7 | 1 HB3 + 1 HB1 | 0.15, -0.20 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | east line | 10.9 | 11.9 | 2 HB5 + 1 HB1 | 0.54, 0.54 | piece HB3 | piece HB3 |
| T4 | south face, the south ground | 37.1 | 37.8 | 10 Mil | 0.35, 0.35 | corner, Mil | corner, Mil |
| T4 | east face, the road's shoulder | 32.1 | 33.1 | 9 Mil | 0.48, 0.48 | piece Mil | corner, Mil |
| T4 | north-east cap across the garden into Addon_03 (1/2) | 4.6 | 5.2 | 1 Mil + 1 Cnc1 | 0.30, 0.22 | piece Mil | low wall concrete_smallwall_8m (box) |
| T4 | north-east cap across the garden into Addon_03 (2/2) | 2.0 | 2.5 | 2 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T4 | west face, outside the yard's west wall | 34.0 | 34.5 | 9 Mil | 0.30, 0.20 | piece Mil | corner, Mil |
| T4 | north-west cap into Addon_03 | 17.7 | 18.5 | 5 Mil | 0.49, 0.38 | piece Mil | i_Addon_03_V1 (box) |
| T5 | south-west cap against the veranda's edge | 4.5 | 4.7 | 1 HB3 + 1 HB1 | 0.35, -0.20 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | north-west cap against the house | 4.5 | 4.7 | 1 HB3 + 1 HB1 | 0.35, -0.20 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | west line | 9.2 | 9.9 | 2 Mil + 2 Cnc1 | 0.36, 0.36 | piece HB3 | piece HB3 |
| T5 | south-east cap against the house | 4.4 | 4.7 | 1 HB3 + 1 HB1 | 0.45, -0.20 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | north-east cap against the house | 4.4 | 4.7 | 1 HB3 + 1 HB1 | 0.45, -0.20 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | east line | 10.9 | 11.6 | 3 Mil | 0.36, 0.36 | piece HB3 | piece HB3 |

## What to check in the game

1. **Athira and Zaros:** the walk started from the front, as above. Do the caps stopping 0.2-0.35 m short still
   clip the house, or leave a way through?
2. **Athira's north-east cap** standing on the courtyard wall.
3. **Kavala:** whichever of (a) or (b) you choose. Then I redo it to your design.

