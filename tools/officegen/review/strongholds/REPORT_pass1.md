# Strongholds: pass 1 report (walls)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. Run `python tools/officegen/drafting/strongholds.py`
to rebuild the drafts. It prints the closure per tier and per ring; `--audit` adds the line audit and `--map N`
draws tier N.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala | 0 / 0 / 0 | 9 / 0 / 0 | 32 / 0 / 0 | 87 / 0 / 0 | 117 / 0 / 0 |
| Pyrgos | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 87 / 0 / 0 | 127 / 0 / 0 |
| Athira | 0 / 0 / 0 | 5 / 0 / 0 | 21 / 0 / 0 | 50 / 0 / 0 | 81 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 16 / 0 / 0 | 59 / 0 / 0 | 79 / 0 / 0 |

Materials, the same in all four towns:
- **T2:** `Land_BagFence_Long_F`, plus `_Short_F` at Pyrgos.
- **T3:** `Land_HBarrier_5_F`, `_3_F` and `_1_F`, all 1-high.
- **T4 and T5:** `Land_Mil_WallBig_4m_F`, with `Land_CncWall1_F` to make up lengths. Both are on the brief's
  high-wall list.

There are no guards, statics, towers, wire, hedgehogs, gates, flag or furniture in any tier. Every tier is a
cumulative snapshot of the one below.

## The ladder as built

- **T1:** empty.
- **T2:** sandbags against the office: a screen across the main door, bags along the porch or veranda and under the
  ground-floor windows, and bags at the back or side door. A door is never boxed in: each screen leaves 0.7 m or
  more open at an end. A C closed onto the porch (my own first draft at Kavala, with the forecourt's walls) shuts
  the door, and the in-game walk would then report "closed" on every tier however open the rings were.
- **T3:** a tight ring of H-barriers round the office, tied into the office and into the neighbours that are solid
  out to their box. It has no opening.
- **T4:** an outer ring of Mil walls round the whole ground, with the T3 ring inside it.
- **T5:** a second ring of Mil walls 1.7 m outside the T3 ring, so there are two complete high-walled rings. The T3
  ring itself is kept, because `tl.check()` still rejects a tier that drops pieces of the tier below.

## How closure was checked before handing in

`closure()` in the script approximates the in-game walk:
- It floods a 0.2 m grid outward from the main door (from the veranda at Zaros, whose main door opens against the
  shop's wall) to 44 m out, which is the edge of the probe.
- The man is 0.5 m wide, so any gap under about 0.5 m counts as shut.
- These stop him: the office's plan; each neighbour's real walls where the building probe has its plan, otherwise
  its box; rocks; and every barrier piece at its measured size.
- **The probed walls don't stop him.** In all four towns every probed wall is low: city walls with railings,
  concrete garden walls, stone walls and pipe fences (the round 6 screenshots show Kavala's and Zaros'). The only
  exception is a junction. Where a ring crosses a low wall, the runs on either side both end into it, and the wall
  counts as solid within 0.6 m of a piece.
- A neighbour's box beyond its real walls counts as open ground. This applies to House_Big_02's west part at Athira
  and the shop's margin at Zaros. `tl.check()` keeps a piece's middle out of a box, so such ground can't be walled
  across.
- As a sanity check, T1 and T2 come out open in every town, so the walker isn't trapped at the start.

Results, for every tier from 3 up, with everything standing and with each ring on its own:
- **Kavala, Pyrgos and Athira:** every tier closed, and every ring closed on its own.
- **Zaros:** every tier closed. The T3 and T4 rings are each closed on their own. **The T5 ring on its own is not**
  (see Zaros below).

## Kavala

The block's walls and the old city wall north-west of it are low, so every ring is the occupier's own and ties only
into buildings: the office, Addon_01 hard against its north-east, and Addon_02 at the north end. Between the office
and the street there are 7.5 m, and the low east walls stand in that space. Between the office's north-west corner
and the old city wall there are 4 m. The inner rings hug the office in both places.

- **T2:** a screen across the main door, with the forecourt's low walls as its flanks and 0.7 m and 0.8 m open at
  its ends.
  Two bags under the stair core's glazed front, five along the west block's 16 m ground-floor window, and one 1.3 m
  out from the back door, open at both ends.
- **T3, H-barriers:**
  - The south line runs at y -14.5, in front of the window bags. The west line runs at x -19, with a chamfer
    parallel to the old wall at the north-west corner.
  - The north line runs at y 11.4 into Addon_01's west face.
  - On the east, a line at x 14.4 hugs the office's blank east face. It crosses the forecourt's low wall at a
    junction and is capped into the office by an `HB1` at (13.95, -6.6).
  - An `HB1` at (14.1, 8.5) plugs the corner where the office and Addon_01 meet.
- **T4, Mil walls round the whole block, with the west yard and the north yard inside:**
  - The square face at y -21, and the street face on the street's edge at x 20.6, bending out to 23 at the north
    end. The street face stands on the probe's 10 m road width, as round 6's did, but doesn't cross the street.
  - The north side into Addon_02, then Addon_02 itself.
  - Outside the old city wall, 1.7 m off its line: its damaged stretch's box is 2 m thick. Then across the old wall
    at a junction and east into Addon_02.
- **T5, Mil walls 1.7 m outside the T3 ring:** y -16.3, x -20.7, the chamfer, and y 13.1 into Addon_01. Its east
  side runs outside the block's low east wall at x 18.2 and is capped across that wall into the office's east face
  at y -4.9.


| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line, west corner to east corner | 35.2 | 36.0 | 6 HB5 + 1 HB3 | 0.40, 0.40 | corner, HB5 | corner, HB1 |
| T3 | west line, south line to the chamfer | 22.0 | 22.3 | 4 HB5 | 0.30, -0.00 | piece HB5 | corner, HB3 |
| T3 | north-west chamfer | 3.4 | 3.6 | 1 HB3 | 0.30, -0.08 | piece HB5 | corner, HB5 |
| T3 | north line, chamfer to Addon_01 | 20.8 | 21.7 | 4 HB5 | 0.50, 0.38 | piece HB3 | u_Addon_01_V1 (box) |
| T3 | east line, south line to the forecourt wall | 2.1 | 3.1 | 3 HB1 | 0.53, 0.53 | piece HB3 | low wall city_4m (box) |
| T3 | east line along the office, wall to the cap | 4.3 | 4.7 | 1 HB3 + 1 HB1 | 0.30, 0.07 | piece HB1 | corner, HB1 |
| T4 | square face, street to the west corner | 59.4 | 60.1 | 16 Mil | 0.36, 0.36 | corner, Mil | corner, Mil |
| T4 | west face, square face to the old wall | 9.1 | 9.3 | 2 Mil + 2 Cnc1 | 0.30, -0.07 | piece Mil | corner, Mil |
| T4 | outside the old city wall, west corner to the north | 49.8 | 50.8 | 14 Mil | 0.51, 0.51 | piece Mil | corner, CncWall1 |
| T4 | across the old city wall | 0.9 | 1.6 | 2 Cnc1 | 0.44, 0.22 | piece Mil | low wall city_8m (box) |
| T4 | old city wall to Addon_02 | 10.4 | 11.3 | 3 Mil | 0.52, 0.38 | low wall city_8m (box) | i_Addon_02_V1 (box) |
| T4 | north side, Addon_02 to the low wall (the street face beyond) | 10.6 | 11.4 | 3 Mil | 0.38, 0.46 | i_Addon_02_V1 (box) | low wall city_8m (box) |
| T4 | street face, north corner to the bend | 18.8 | 19.3 | 5 Mil | 0.25, 0.25 | corner, Mil | corner, Mil |
| T4 | street face, bend to the square face | 28.9 | 29.8 | 8 Mil | 0.43, 0.43 | piece Mil | piece Mil |
| T5 | south line | 41.3 | 42.0 | 11 Mil | 0.31, 0.31 | corner, Mil | piece Mil |
| T5 | west line, south line to the chamfer | 24.7 | 25.7 | 7 Mil | 0.50, 0.50 | piece Mil | corner, Mil |
| T5 | north-west chamfer | 4.5 | 4.8 | 1 Mil + 1 Cnc1 | 0.30, 0.02 | piece Mil | corner, Mil |
| T5 | north line, chamfer to Addon_01 | 21.9 | 22.7 | 6 Mil | 0.39, 0.38 | piece CncWall1 | u_Addon_01_V1 (box) |
| T5 | east line outside the low east wall | 11.4 | 11.7 | 3 Mil | 0.30, -0.02 | piece Mil | corner, Mil |
| T5 | cap, east line to the low wall | -0.1 | 0.0 | none (already shut) | 0.00, 0.00 | piece Mil | piece Mil |
| T5 | cap, low wall to the office | 3.3 | 4.1 | 1 Mil | 0.42, 0.38 | low wall city_8m (box) | the office Offices_01_V1 |

The T3 ring also holds the two `HB1` pieces placed by hand: the cap at (13.95, -6.6), whose west end runs into the
office, and the plug at (14.1, 8.5). Where it says "already shut", the pieces at both ends already overlap, so no
piece was needed.

## Pyrgos

The tower stands alone on open ground. A low city wall runs down the east side at x 19, a low concrete wall runs
across the north at y 13.2 with a city wall beyond it at y 17 (a lane between them), and pipe fences ring the west
lot and the square.

- **T2:** as at Kavala, plus short bags on the porch's flanks (Pyrgos has no forecourt walls).
- **T3:** a rectangle of H-barriers, x -20..15 and y -14.5..11.0. It stays off the window bags and the back door's
  bag.
- **T4, Mil walls:**
  - The square face at y -20.5 runs inside the fence line. It crosses the lot's pipe fence and the east city wall
    at junctions.
  - The east face stands outside the east city wall at x 20.15, at the hill's foot.
  - The north face runs along the lane's city wall at y 18.2.
  - The west face runs down the middle of the west lot at x -29, crossing its fence and the low wall at junctions.
- **T5:** Mil walls round the T3 ring at y -16.3, x -21.7 and x 17.3. Its north side runs in the lane at y 14.6
  and crosses the low concrete wall at both corners.


| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line | 36.7 | 37.7 | 7 HB5 | 0.49, 0.49 | corner, HB5 | corner, HB5 |
| T3 | north line | 36.7 | 37.7 | 7 HB5 | 0.49, 0.49 | corner, HB3 | corner, HB3 |
| T3 | west line | 23.8 | 24.8 | 4 HB5 + 1 HB3 | 0.50, 0.50 | piece HB5 | piece HB5 |
| T3 | east line | 23.8 | 24.8 | 4 HB5 + 1 HB3 | 0.50, 0.50 | piece HB5 | piece HB5 |
| T4 | west face, south corner to the lot's fence | 28.1 | 29.1 | 8 Mil | 0.53, 0.53 | corner, Mil | low wall pipe_fence_4m (box) |
| T4 | west face, fence to the low wall | 5.7 | 6.2 | 1 Mil + 3 Cnc1 | 0.30, 0.22 | piece Mil | low wall concrete_smallwall_8m (box) |
| T4 | west face, low wall to the lane's city wall | 3.2 | 4.1 | 1 Mil | 0.43, 0.43 | low wall concrete_smallwall_8m (box) | low wall city2_8m (box) |
| T4 | north face, along the lane's city wall | 50.2 | 49.7 | 13 Mil | -0.28, -0.28 | corner, Mil | corner, Mil |
| T4 | east face, outside the east city wall | 38.7 | 39.8 | 11 Mil | 0.53, 0.53 | piece Mil | corner, Mil |
| T4 | square face, west corner to the fence | 15.8 | 16.5 | 4 Mil + 2 Cnc1 | 0.37, 0.37 | piece Mil | low wall pipe_fence_4m (box) |
| T4 | square face, fence to the east city wall | 31.0 | 32.1 | 9 Mil | 0.59, 0.59 | piece Mil | low wall city2_8m (box) |
| T5 | south line | 40.1 | 40.9 | 11 Mil | 0.42, 0.42 | corner, Mil | corner, Mil |
| T5 | north line, in the lane | 40.1 | 40.9 | 11 Mil | 0.42, 0.42 | corner, Mil | corner, CncWall1 |
| T5 | west line, south line to the low wall | 29.0 | 29.8 | 8 Mil | 0.42, 0.42 | piece Mil | low wall concrete_smallwall_8m (box) |
| T5 | west line, low wall to the north line | -0.1 | 0.0 | none (already shut) | 0.00, 0.00 | piece Mil | piece Mil |
| T5 | east line, south line to the low wall | 28.5 | 29.4 | 8 Mil | 0.48, 0.48 | piece Mil | low wall concrete_smallwall_8m (box) |
| T5 | east line, low wall to the north line | 0.8 | 1.5 | 2 Cnc1 | 0.22, 0.49 | low wall concrete_smallwall_8m (box) | piece Mil |

## Athira

A dense block. House_Small_02 stands hard behind the house, and it is the only neighbour solid out to its box. The
other neighbours (House_Big_02 north-east and south-east, and the shop east) have real walls 1-4 m inside their
boxes. That leaves open ground no piece may stand on, including a corridor north between House_Small_02 and
House_Big_02's real west wall. So the rings close on House_Small_02 and on themselves.

- **T2:** a screen across the main door, with the low city wall on its west and the east end open. Two bags along
  the veranda's open west side, one at the side door (open at both ends) and one at the east window.
- **T3:** H-barriers at y -10.75, x -7 and x 7.5, capped into House_Small_02's west face (y 8.6) and east face
  (y 8.75). They cross the low city wall and the courtyard wall at junctions.
- **T4, Mil walls:**
  - y -14.1 across the low wall, with a chamfer past the north tip of House_Big_02's box: the chamfer's corner pokes
    0.3 m into that open tip, as both pieces' end zones may.
  - x 14.8 up through the courtyard's opening, then a cap at y 11.33 across the corridor into House_Small_02. That
    cap stands 0.57 m short of House_Big_02's box.
  - x -11.5 at the scaffolding's foot, with a line across the lane north (y 12.6) into House_Small_02.
- **T5:** Mil walls at y -12.45, x -8.7 and x 9.6, capped into House_Small_02 at y 10.6 and y 10.2.
- **The north-east corner is tight.** Only 4 m separate the courtyard wall from House_Big_02's box, so the three
  rings' caps stand side by side there, touching but not overlapping.


| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south line, west corner to the low wall | 3.1 | 3.6 | 1 HB3 | 0.18, 0.30 | corner, HB5 | low wall city_8m (box) |
| T3 | south line, low wall to the east corner | 12.6 | 13.3 | 2 HB5 + 2 HB1 | 0.37, 0.37 | low wall city_8m (box) | corner, HB5 |
| T3 | west line | 19.3 | 20.0 | 3 HB5 + 1 HB3 | 0.33, 0.33 | piece HB3 | corner, HB1 |
| T3 | west cap into House_Small_02 | 0.5 | 1.4 | 1 HB1 | 0.52, 0.38 | piece HB3 | i_House_Small_02_V1 (box) |
| T3 | east line, south line to the courtyard wall | 17.0 | 17.7 | 3 HB5 + 1 HB1 | 0.36, 0.36 | piece HB5 | low wall city_8m (box) |
| T3 | east cap into House_Small_02 | 4.7 | 4.7 | 1 HB3 + 1 HB1 | -0.30, 0.30 | FREE | i_House_Small_02_V1 (box) |
| T4 | south face, west corner to the low wall | 7.3 | 7.9 | 2 Mil | 0.25, 0.30 | corner, Mil | low wall city_8m (box) |
| T4 | south face, low wall to the chamfer | 14.1 | 15.0 | 4 Mil | 0.47, 0.47 | low wall city_8m (box) | corner, Mil |
| T4 | chamfer past House_Big_02's tip | 6.5 | 7.6 | 2 Mil | 0.58, 0.58 | piece Mil | corner, Mil |
| T4 | north-east cap across the corridor into House_Small_02 | 11.7 | 11.7 | 3 Mil | -0.30, 0.30 | corner, Mil | i_House_Small_02_V1 (box) |
| T4 | east line through the courtyard's opening | 19.9 | 20.5 | 5 Mil + 2 Cnc1 | 0.33, 0.33 | piece Mil | piece Mil |
| T4 | west line at the scaffolding's foot | 26.7 | 26.9 | 7 Mil | 0.30, -0.10 | piece Mil | corner, Mil |
| T4 | across the lane north into House_Small_02 | 5.3 | 6.0 | 1 Mil + 3 Cnc1 | 0.38, 0.22 | piece Mil | i_House_Small_02_V1 (box) |
| T5 | south line, west corner to the low wall | 4.5 | 4.8 | 1 Mil + 1 Cnc1 | 0.11, 0.15 | corner, Mil | low wall city_8m (box) |
| T5 | south line, low wall to the east corner | 14.9 | 15.5 | 4 Mil | 0.31, 0.31 | low wall city_8m (box) | piece Mil |
| T5 | west cap into House_Small_02 | 5.3 | 5.9 | 1 Mil + 3 Cnc1 | 0.40, 0.22 | piece Mil | i_House_Small_02_V1 (box) |
| T5 | west line | 22.0 | 22.7 | 6 Mil | 0.38, 0.38 | piece Mil | piece Mil |
| T5 | east cap into House_Small_02 | 6.5 | 6.9 | 1 Mil + 4 Cnc1 | 0.18, 0.22 | corner, Mil | i_House_Small_02_V1 (box) |
| T5 | east line, south line to the courtyard wall | 18.9 | 19.6 | 5 Mil + 1 Cnc1 | 0.38, 0.38 | piece Mil | low wall city_8m (box) |
| T5 | east line, courtyard wall to the cap | 2.1 | 2.8 | 4 Cnc1 | 0.22, 0.41 | low wall city_8m (box) | piece Mil |

## Zaros

Addon_03 stands hard behind the house, solid out to its box, and the shop stands hard against its front. The shop's
real walls run x -5..6.7, but its box runs x -8..12.3, and the main road starts at x 11. That box margin is open
ground no piece may stand on, and it fills the whole frontage. The main door opens against the shop's wall; the way
out is the veranda's open west side. West is the yard and east the strip and a low-walled garden. Every wall here is
low.

- **T2:** two bags along the veranda's open west side, one at the side door and one at the east window.
- **T3:** H-barriers hugging the house at x -6.6 and x 8.9. They are capped into its west and east faces at both
  ends: y -6.4 on the shop's edge, and y 4.6 and 6.25 at the back.
- **T4, Mil walls round the whole block, with the shop, Addon_03 and the garden inside:**
  - y -18, behind the shop.
  - x 13 on the main road's shoulder, the only line that fits outside the shop's box. It takes about 2.5 m of the
    probe's 10 m road width and doesn't close the road.
  - x -11.6 through the yard. It crosses the yard's low walls at four junctions, one of them in the wall cluster at
    x -9..-10, y 7..11.
  - Caps into Addon_03's west face (y 12.5) and east face (y 10.6). The east cap crosses the garden wall.
- **T5:** Mil walls hugging T3 at x -8.3 and x 10.65. They are capped into the house at y 6.2 and across the
  garden into Addon_03 at y 9.4.
- **The one ring that isn't closed on its own: Zaros T5.** Its two south ends stop at the shop's box edge, 0.3 m
  off T3's west line and 0.35 m off its east line. The shop's open box margin beyond can't be walled, so at the
  shop front T5 and T3 close together, and the tier is closed.


| Ring | Run | Gap (m) | Run (m) | Pieces | Ends into (m) | End A | End B |
|---|---|---|---|---|---|---|---|
| T3 | south-west cap into the veranda's edge | 2.9 | 3.6 | 1 HB3 | 0.33, 0.33 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | north-west cap into the house | 2.9 | 3.6 | 1 HB3 | 0.33, 0.33 | corner, HB3 | the office i_House_Big_01_V1 |
| T3 | west line | 9.2 | 10.0 | 1 HB5 + 1 HB1 + 1 HB3 | 0.40, 0.40 | piece HB3 | piece HB3 |
| T3 | south-east cap into the house | 4.2 | 4.7 | 1 HB3 + 1 HB1 | 0.15, 0.30 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | north-east cap into the house | 4.2 | 4.7 | 1 HB3 + 1 HB1 | 0.15, 0.30 | corner, HB5 | the office i_House_Big_01_V1 |
| T3 | east line | 10.9 | 11.9 | 2 HB5 + 1 HB1 | 0.54, 0.54 | piece HB3 | piece HB3 |
| T4 | south face, behind the shop | 25.7 | 26.5 | 7 Mil | 0.37, 0.37 | corner, CncWall1 | corner, Mil |
| T4 | east face, the road's shoulder | 28.6 | 29.5 | 8 Mil | 0.47, 0.47 | piece Mil | corner, Mil |
| T4 | north-east cap across the garden into Addon_03 (1/2) | 4.6 | 5.3 | 1 Mil + 2 Cnc1 | 0.41, 0.22 | piece Mil | low wall concrete_smallwall_8m (box) |
| T4 | north-east cap across the garden into Addon_03 (2/2) | 2.0 | 2.4 | 3 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T4 | west face through the yard (1/4) | 1.7 | 2.2 | 3 Cnc1 | 0.38, 0.22 | piece Mil | low wall city2_8m (box) |
| T4 | west face through the yard (2/4) | 22.6 | 23.4 | 6 Mil + 1 Cnc1 | 0.37, 0.37 | low wall city2_8m (box) | low wall city2_8m (box) |
| T4 | west face through the yard (3/4) | 2.0 | 2.4 | 3 Cnc1 | 0.22, 0.22 | low wall city2_8m (box) | low wall concrete_smallwall_8m (box) |
| T4 | west face through the yard (4/4) | 2.6 | 3.1 | 4 Cnc1 | 0.22, 0.27 | low wall concrete_smallwall_8m (box) | corner, Mil |
| T4 | north-west cap into Addon_03 | 6.3 | 6.8 | 1 Mil + 4 Cnc1 | 0.32, 0.22 | piece CncWall1 | i_Addon_03_V1 (box) |
| T5 | north-west cap into the house | 4.3 | 4.8 | 1 Mil + 1 Cnc1 | 0.23, 0.22 | corner, Mil | the office i_House_Big_01_V1 |
| T5 | west line, the shop's box edge to the cap | 13.3 | 13.8 | 3 Mil + 3 Cnc1 | 0.22, 0.30 | corner, HB3 | piece Mil |
| T5 | north-east cap across the garden into Addon_03 (1/2) | 4.6 | 5.2 | 1 Mil + 2 Cnc1 | 0.43, 0.22 | piece Mil | low wall concrete_smallwall_8m (box) |
| T5 | north-east cap across the garden into Addon_03 (2/2) | 2.0 | 2.4 | 3 Cnc1 | 0.22, 0.22 | low wall concrete_smallwall_8m (box) | i_Addon_03_V1 (box) |
| T5 | east line, the shop's box edge to the cap | 15.8 | 16.5 | 4 Mil + 2 Cnc1 | 0.37, 0.37 | i_Shop_01_V1(box; no wall on) | piece Mil |

## Round 6's wall items

- **Pieces cutting into walls, buildings or the office:** every piece's middle is kept off the probed walls, the
  buildings' boxes and the office (`clips()` and `tl.check()`). A run that crosses a low wall is split there, and
  the pieces on both sides end into the wall. A 1 m concrete piece runs only 0.15-0.22 m into a wall or building:
  any deeper and its 0.2 m middle would touch.
- **Low old walls:** none is a barrier, and none forms any side of a ring.
- **Athira's shop corner:** no ring ends on the shop any more.
- **Gaps:** the closure check above covers them.

## Not used yet from the brief's update

- **Upgrading existing walls** (H-barriers standing into a real wall along its length): not used. Every line runs
  beside or across the low walls.
- **Dropping pieces between tiers:** not used. `tl.check()` still rejects a tier that drops pieces of the tier
  below. If it allowed drops, T5 could swap T3's H-barriers for Mil walls in place. That would give Zaros' T5 a ring
  of its own at the shop front.
- **The compound:** Kavala's and Zaros' T4 rings take in the whole cluster, and Pyrgos stands alone. Athira's T4
  can't reach the shop or either House_Big_02, because their open box margins can't be walled.

## Tooling changed

- **`townlib.py`:**
  - Added `Land_CncWall4_F` (4.0 x 1.0) and `Land_CncWall1_F` (1.0 x 1.0). Both sizes are guesses; please log their
    real boxes.
  - Added `MIN_GUARDS` (default 2). The walls-only drafts set it to 0, because `check()` otherwise demands 2 guards
    a tier.
- **The drafting script:** `closure()` (described above); `run()`, which splits a run at every probed wall it
  crosses; the Mil-wall family; and the per-ring audit. The town functions were rewritten for pass 1. The helpers
  for guards, statics, towers and checkpoints are kept for later passes.

## What to check in the game

1. **Closure on T3-T5 in all four towns, and where the walk gets out if it does.** My check treats the low walls as
   passable except at junctions, and a neighbour's open box margin as walkable. If the game disagrees on either,
   these are the likely spots:
   - Kavala's T3 east line, which runs 0.05 m off the office's east face, and the corner where the office meets
     Addon_01.
   - The House_Small_02 caps at Athira and the Addon_03 caps at Zaros. Is each building solid to its box?
   - Zaros' veranda, closed at its south end by the shop's wall.
2. **The road shoulders:** the Kavala street face (x 20.6) and the Zaros east face (x 13). Do they leave the road
   drivable?
3. **Kavala's T4 outside the old city wall:** it runs next to the road's edge north-west of the block.
4. **Athira:** the unprobed object at about (6.8, -6.5) that pushed earlier rounds' statics. The T3 east line
   (x 7.5) and the east window's bag (6.3, -5.25) are near it.
5. **Athira's north-east caps:** three walls side by side at y 8.75, 10.2 and 11.33. Do they read as one thick wall,
   or clip?

