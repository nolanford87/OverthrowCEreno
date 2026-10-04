# Strongholds: round 5 report (answering round4.md)

Branch `layouts/strongholds`. Drafts: `tools/officegen/layouts/drafts/{Kavala,Pyrgos,Athira,Zaros}.txt`, script
`tools/officegen/drafting/strongholds.py`. Every draft passes `tl.check()`. Run
`python tools/officegen/drafting/strongholds.py --audit` to reprint the line audit below, or add `--map N` for tier N's map.

## Counts (things / guards / statics per tier)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala | 7 / 3 / 0 | 12 / 6 / 0 | 25 / 12 / 2 | 86 / 21 / 4 | 146 / 39 / 7 |
| Pyrgos | 7 / 3 / 0 | 14 / 6 / 0 | 40 / 13 / 2 | 79 / 22 / 4 | 115 / 37 / 6 |
| Athira | 6 / 2 / 0 | 14 / 6 / 0 | 46 / 12 / 2 | 68 / 19 / 3 | 93 / 32 / 5 |
| Zaros | 6 / 2 / 0 | 14 / 6 / 0 | 35 / 11 / 2 | 80 / 20 / 3 | 101 / 32 / 5 |

All four are within the ladder (T3 10-14, T4 18-24, T5 30-40 guards; at most 200 things).

## Why the lines were open, and what changed in the tooling

1. **The old lines weren't measured.** Each "line" was a hand-placed piece or a fill between endpoints I had guessed.
   `fill()` now finds the gap itself. It walks out from the middle of the stretch, sampling across the piece's middle
   width so it catches walls met at a slant, until it meets something solid each way. Then it butts pieces from face
   to face: joints overlap 0.3-0.6 m, ends run 0.3-0.6 m into walls or other pieces, and 0.3-0.38 m into a
   building's box. An end that meets nothing is reported as free. Each run is logged for the audit.
2. **Bounding boxes aren't walls.** The probe's boxes can be far bigger than the buildings. House_Big_02's box runs
   ±12 m and its walls only −6.5..7.5 m. Where `probe_offices.txt` has the neighbour's class (any texture variant),
   the site model now uses its real floor plan, and the map marks box-only ground as `%`. `tl.check()` still holds a
   piece's middle out of every box, so a line can only end at a box. The audit reports how far the real wall lies
   beyond it ("box end").
3. **2-high everywhere it matters.** Family `B` is HBarrier_Big, with the Mil wall (4.7 m) and the concrete T-wall
   (CncBarrierMedium, 2 m) as finishers. `tl.check()` takes a CncBarrierMedium as 4 m long (the game measured 1.8 m),
   so blocks are kept in the middle of a run, never against a wall. A gap too short for anything 2-high falls back to
   low H-barriers, and the audit flags it if it faces a road.
4. **Clip check.** It is now a rectangle-overlap test against every probed wall, building and rock box (pipe fences
   are 0.2 m thick; the old 0.5 m sampling missed them). It also covers wire and hedgehogs, which it used to skip.
5. **Statics** take their measured length (1.6 × 2.4 m) and stand 2.1 m behind their round bag (was 1.9 m), so the
   barrel clears the bag. That is the likely cause of the "floating" guns: they spawned overlapping their own bags
   and were pushed up. The ground at Kavala's street gun is flat to 0.1 m, and Athira's slopes about 6 %.
6. **Audit.** Each run's gap is checked along its centre line, end to end, against the site and the tier's pieces.
   The audit also lists the joints, the end overlaps, what closes each end (a building, wall, piece, or "joins X" for
   a corner), any open stretch, any box end, and any road-facing run that isn't 2-high.

## Per town: what changed

**Kavala.** One 2-high ring now runs round the whole block. The forward yard is walled out into the square, with the
gate on the door's axis, the chicane, and HMG embrasures in the square face and the street face. The street face runs
outside the low railing wall from the square up to the block's north-east corner, then turns in to the wall. A north
side runs from Addon_02 to the street face. The old city wall is lined 2-high on its inside, from the west yard's south
wall round to Addon_02, so the north yard is now inside the ring with its bag tower. The west yard's south wall is
lined too. The city walls here are low walls with railings, so every face is the occupier's own H-barrier. The old
inner back line at y 12.4 is gone (it was inside the ring).
- **East street-edge line (round 4):** it was in the T5 snapshot (map rows x 19..22, y −11..10), and
  `Kavala_T5_street.jpg` shows it as the 2-high row along the bottom. The top view misses it because the line sits 7 m
  beyond the roof's edge on the frame's bottom side, under the roof's perspective. The line is now closed at both ends
  (the audit's "street face" runs).
- T5 adds a second walled yard out in the square: west side, square face with gate, a GMG embrasure and a tower,
  street side. It adds five checkpoints. The mortar moved to the north yard.

**Pyrgos.** The lines are re-laid so each one ends in something. The west yard's mouth and the porch line end in the
block. The Mil west wall ends in the mouth line. The porch line runs block → gate → east city wall. The bastion face
(2-high, with the HMG embrasure) ties back to the mouth line, and the outer face (2-high) runs bastion → gate → east
wall. The north lane is shut with a measured run, and T5 fills the lane 2-high.

**Athira.** The west lot's real mouth is at x −16.6, not −13: House_Small_01's box ends at x −16.5. It now holds two
embrasures (the HMG at T3, the AT gun at T5) and low H-barriers into the scaffolding. The lot's south side is walled
2-high from House_Small_01 to the city wall, which closes the way south past the house. The lane north is walled
2-high, with an embrasure for the T4 HMG firing 38 m up the lane. The courtyard's opening is closed between the
pillars. The south front runs gate → GMG embrasure → low stretch for the riflemen → 2-high to the shop, whose face is
diagonal (x ≈ 24 at the line). T5 closes the strip to the east road at x 20 with a firing slot.

**Zaros.** Rebuilt from scratch.
- **T3:** the yard is closed (its walls, the city gate, H-barriers in its 2 m south gap). The strip is closed at the
  road by a 2-high line from the house to a bar gate, tied into the garden wall. Gun pits sit at the block's corners on
  the road's edge.
- **T4:** a ring round the whole block. The east face runs 2-high along the road's edge for 37 m, with its gate. The
  north face runs from Addon_03 to the road, with the GMG embrasure. The south face goes stone wall → AT and HMG
  embrasures → road, and the south ground is shut on its west. A bag tower stands in the south ground and a blast wall
  sits before the gate. The open ground north's west gap is walled, with a man behind it. Wire and hedgehogs are
  placed off the guns' lines.
- **T5:** checkpoints up and down the road, the AT gun in the south face, the mortar in the yard.
- **Round 4's single pieces:** (−16.8, 3.4), (3.0, 17.6), (−15.4, 24.0), (−26.3, 12.6), (−19.6, −12.4),
  (−20.6, −18.5), (11.4, −18.4), (9.8, −21.4) are all gone.

## The round-4 measured problems

| Problem | Fix |
|---|---|
| Door gendarme (−14.7, 5.9), Kavala and Pyrgos, 2.8 m | Now at (−3.0, 6.5) on the ground floor, looking 12 m down the back corridor to the back door. |
| Athira T5 rifleman (25, 9.3) and autorifleman (25.1, 10.5) blind | That roadblock is gone. The strip is now closed at x 20 with a round-bag slot; the men stand 0.85 m behind it, facing out. Hedgehogs moved off. |
| Interior rifleman (−3.7, 1.9), Athira and Zaros | He was placed inside the wall at y 1 and got pushed. Now at (−3.5, −0.2), looking down the veranda's 7 m to the main door. |
| Athira HMG (11.9, −10.3) 11 m | Removed. The T4 HMG now fires up the lane north (−9.4, 6.5), with 38 m clear. |
| Athira mortar (7.8, −3.9) 0.3 m | Now at (6.8, −1.5), clear of the tower; 10 m to the first piece. |
| Roof GMG into the office (Kavala, Pyrgos) | The probe's roof plan misses the roof's low dividing walls. I traced them from the round-4 top view (y −2, y 1.7, x −16..−8.6, y −7, y −9). The GMG is now at (−14.5, −5.5), between them. |
| Pyrgos roof AT into the office | Now at (7.0, −5.8), clear of the stair blocks and the low walls. |
| Floating AT, Kavala (19, −16.2) | The street gun now has a 2.4 m footprint and stands 2.1 m behind its bag; the ground there is flat. |
| Floating AT, Athira (−22.4, −5.1) | Moved into the west mouth's second embrasure at (−14.5, −4.1). |
| Kavala T5 BagBunker_Small into house_big_02 | The junction checkpoint's roadside bunker is removed. It stood 40 m out, by a house the probe doesn't reach. |
| Kavala T5 HBarrier_3 into house_small_01 | The outer chicane's far block moved in to (12.4, −35.6). Please check: the house isn't in the probe. |
| Pyrgos wire through a pipe fence | Wire is now in two runs, each ending on the fence. |
| Pyrgos hedgehog into a city wall | The clip check now covers hedgehogs; that hedgehog moved to (16.5, −29). |
| Pyrgos BagBunker_Small into a pipe fence | The checkpoint bunkers are removed. |
| Zaros BagFence_Short into the office | The veranda's C of bags moved 1 m west, and the flag with it. |

## Line audit (every run; gap = what it closes, run = its pieces end to end, joints and end overlaps in m)

Closed-by-other-means stretches (gates, embrasure bags) show run 0.0 with their pieces checked along the line.
"joins X" means a free end that meets a crossing run at a corner.

| Town | Tier | Run | Gap | Run | Pieces | Joints | Ends | Closed by | Audit |
|---|---|---|---|---|---|---|---|---|---|
| Kavala | T3 | west yard's gap, wall to block | 4.2 | 5.2 | 1xHB3+2xHB1 | 0.59,0.59 | 0.59,0.38 | wall:city_8m(box) | office:Offices_01_V1_F | closed |
| Kavala | T3 | forecourt's mouth: bar gate | 5.6 | 0.0 | (gate / bags) | - | - | joins BagFence_Long | joins BagFence_Long | closed |
| Kavala | T4 | square face, west corner to HMG | 11.6 | 12.6 | 1xHBBig+1xMil4 | 0.49 | 0.49,0.49 | joins Mil_WallBig_4m | piece:BagFence_Round_F | closed |
| Kavala | T4 | square face, HMG to gate | 4.7 | 5.5 | 1xMil4+1xCnc | 0.40 | 0.40,0.40 | piece:BagFence_Round_F | piece:BarGate_F | closed |
| Kavala | T4 | square face, gate to street corner | 8.6 | 9.0 | 1xHBBig | - | 0.30,0.13 | piece:BarGate_F | joins CncBarrierMedium | closed |
| Kavala | T4 | forward yard's west side, block to | 7.2 | 7.9 | 2xMil4 | 0.32 | 0.32,0.32 | office:Offices_01_V1_F | piece:HBarrier_Big_F | closed |
| Kavala | T4 | street face, corner to HMG | 3.8 | 4.6 | 3xCnc | 0.40,0.40 | 0.40,0.40 | piece:HBarrier_Big_F | piece:BagFence_Round_F | closed |
| Kavala | T4 | street face, HMG to the bend | 22.5 | 23.0 | 2xHBBig+1xCnc+1xMil4 | 0.30,0.30,0.30 | 0.30,0.17 | piece:BagFence_Round_F | joins HBarrier_Big | closed |
| Kavala | T4 | street face, bend to the north-eas | 15.2 | 16.2 | 1xHBBig+2xMil4 | 0.51,0.51 | 0.51,0.51 | piece:Mil_WallBig_4m_F | wall:city_8m(box) | closed |
| Kavala | T4 | north side, Addon_02 to the street | 10.3 | 11.3 | 3xMil4 | 0.52,0.52 | 0.38,0.52 | building:i_Addon_02_V1_F(box) | wall:city_8m(box) | closed |
| Kavala | T4 | west yard's south wall lined | 11.7 | 12.6 | 1xHBBig+1xMil4 | 0.48 | 0.48,0.48 | wall:city_4m(box) | piece:HBarrier_3_F | closed |
| Kavala | T4 | old city wall lined, west yard to | 33.5 | 34.5 | 4xHBBig | 0.50,0.50,0.50 | 0.50,0.50 | piece:HBarrier_Big_F | joins HBarrier_Big | closed |
| Kavala | T4 | old city wall lined, bend to Addon | 19.5 | 20.3 | 2xHBBig+2xCnc | 0.43,0.43,0.43 | 0.43,0.43 | piece:HBarrier_Big_F | wall:city_8m(box) | closed |
| Kavala | T4 | wire outside the old city wall | 23.7 | 24.6 | 3xwire | 0.45,0.45 | 0.45,0.45 | FREE | FREE | closed |
| Kavala | T5 | outer yard's square face, corner t | 10.8 | 11.7 | 1xHBBig+2xCnc | 0.44,0.44 | 0.44,0.44 | joins Mil_WallBig_4m | piece:BagFence_Round_F | closed |
| Kavala | T5 | outer yard's west side | 6.9 | 7.8 | 2xMil4 | 0.43 | 0.43,0.43 | piece:HBarrier_Big_F | piece:HBarrier_Big_F | closed |
| Kavala | T5 | outer yard's square face, bags to | 4.7 | 5.5 | 1xMil4+1xCnc | 0.40 | 0.40,0.40 | piece:BagFence_Round_F | piece:BarGate_F | closed |
| Kavala | T5 | outer yard's square face, gate to | 1.0 | 1.8 | 1xCnc | - | 0.40,0.40 | piece:BarGate_F | piece:BagFence_Round_F | closed |
| Kavala | T5 | outer yard's square face, GMG to c | 5.6 | 6.6 | 1xMil4+2xCnc | 0.53,0.53 | 0.53,0.53 | piece:BagFence_Round_F | piece:HBarrier_Big_F | closed |
| Kavala | T5 | outer yard's street side | 7.3 | 7.9 | 2xMil4 | 0.30 | 0.30,0.30 | piece:CncBarrierMedium_F | piece:HBarrier_Big_F | closed |
| Pyrgos | T3 | west yard's mouth, to the block | 7.1 | 7.9 | 1xHB5+2xHB1 | 0.37,0.37 | 0.37,0.37 | joins Mil_WallBig_4m | office:Offices_01_V1_F | closed |
| Pyrgos | T3 | west wall, low north wall to the m | 25.3 | 26.2 | 7xMil4 | 0.42,0.42,0.42,0.42,0.42,0.42 | 0.42,0.42 | wall:concrete_smallwall_8m(box) | piece:HBarrier_5_F | closed |
| Pyrgos | T3 | porch line, block to gate | 9.5 | 10.1 | 1xHB5+1xHB3+1xHB1 | 0.33,0.33 | 0.33,0.33 | office:Offices_01_V1_F | piece:BarGate_F | closed |
| Pyrgos | T3 | porch line, gate to east wall | 5.7 | 6.7 | 1xHB5+1xHB1 | 0.48 | 0.48,0.48 | piece:BarGate_F | wall:city2_8m(box) | closed |
| Pyrgos | T4 | bastion face, west corner to HMG | 9.3 | 10.3 | 1xHBBig+1xCnc | 0.49 | 0.49,0.49 | joins HBarrier_1 | piece:BagFence_Round_F | closed |
| Pyrgos | T4 | bastion face, HMG to outer face | 6.1 | 6.9 | 1xMil4+2xCnc | 0.39,0.39 | 0.39,0.39 | piece:BagFence_Round_F | joins Mil_WallBig_4m | closed |
| Pyrgos | T4 | bastion's west side, mouth to face | 1.3 | 2.3 | 2xHB1 | 0.48 | 0.48,0.48 | piece:HBarrier_1_F | piece:HBarrier_Big_F | closed |
| Pyrgos | T4 | outer face, bastion to gate | 7.2 | 7.9 | 2xMil4 | 0.33 | 0.33,0.33 | piece:CncBarrierMedium_F | piece:BarGate_F | closed |
| Pyrgos | T4 | outer face, gate to east wall | 5.7 | 6.7 | 2xCnc+1xMil4 | 0.50,0.50 | 0.50,0.50 | piece:BarGate_F | wall:city2_8m(box) | closed |
| Pyrgos | T4 | north lane shut at the west wall | 3.3 | 4.4 | 1xHB3+1xHB1 | 0.57 | 0.57,0.57 | wall:concrete_smallwall_8m(box) | wall:city2_8m(box) | closed |
| Pyrgos | T4 | wire, west of the fence | 11.4 | 8.5 | 1xwire | - | -1.44,-1.44 | FREE | wall:pipe_fence_4m(box) | closed |
| Pyrgos | T4 | wire, east of the fence | 9.2 | 8.5 | 1xwire | - | -0.35,-0.35 | wall:pipe_fence_4m(box) | piece:BagBunker_Tower_F | closed |
| Pyrgos | T5 | north lane's roadblock | 3.3 | 4.4 | 1xHB3+1xHB1 | 0.57 | 0.57,0.57 | wall:concrete_smallwall_8m(box) | wall:city2_8m(box) | closed |
| Pyrgos | T5 | north lane filled 2-high | 41.5 | 42.7 | 5xHBBig | 0.58,0.58,0.58,0.58 | 0.58,0.58 | piece:HBarrier_3_F | wall:city2_8m(box) | closed |
| Athira | T3 | west mouth, bags to the scaffoldin | 1.3 | 2.2 | 2xHB1 | 0.58 | 0.58,0.38 | piece:BagFence_Round_F | building:scaffolding(box) | closed |
| Athira | T3 | west mouth: the two embrasures' ba | 6.1 | 0.0 | (gate / bags) | - | - | FREE | FREE | closed |
| Athira | T3 | the lot's south side, House_Small_ | 11.3 | 12.0 | 2xMil4+3xCnc | 0.39,0.39,0.39,0.39 | 0.38,0.39 | building:i_House_Small_01_V3_F(box) | wall:city_8m(box) | closed |
| Athira | T3 | lane north, embrasure to the scaff | 1.8 | 2.5 | 2xHB1 | 0.35 | 0.35,0.35 | piece:BagFence_Round_F | building:scaffolding(box) | closed |
| Athira | T3 | lane north, embrasure to House_Sma | 2.3 | 3.2 | 3xHB1 | 0.51,0.51 | 0.51,0.38 | piece:BagFence_Round_F | building:i_House_Small_02_V1_F(box) | closed |
| Athira | T3 | the courtyard's opening, wall end | 4.5 | 5.5 | 1xHB3+2xHB1 | 0.46,0.46 | 0.46,0.46 | wall:city_pillar(box) | wall:city_pillar(box) | closed |
| Athira | T3 | south front, gate to GMG | 0.5 | 1.4 | 1xHB1 | - | 0.47,0.47 | piece:BarGate_F | piece:BagFence_Round_F | closed |
| Athira | T3 | south front, GMG to x 9 (low) | 5.2 | 5.8 | 1xHB5 | - | 0.30,0.28 | piece:BagFence_Round_F | joins HBarrier_Big | closed |
| Athira | T3 | south front, x 9 to the shop | 11.9 | 12.7 | 1xHBBig+1xMil4 | 0.41 | 0.41,0.38 | piece:HBarrier_5_F | building:i_Shop_02_V2_F(box; its wall 4.4 m on) | box end: 4.4 m to the real wall |
| Athira | T3 | south front: bar gate | 4.0 | 0.0 | (gate / bags) | - | - | FREE | FREE | closed |
| Athira | T4 | wire across the alley | 7.9 | 8.5 | 1xwire | - | 0.30,0.30 | building:i_House_Big_01_V1_F(box; its wall 1.0 m on) | building:i_House_Small_01_V3_F(box) | box end: 1.0 m to the real wall |
| Athira | T5 | the strip closed, slot to the cour | 2.8 | 3.6 | 1xHB3 | - | 0.38,0.38 | piece:BagFence_Round_F | wall:city_8m(box) | faces a road, not 2-high |
| Athira | T5 | the strip closed, slot to House_Bi | 1.4 | 2.3 | 2xHB1 | 0.53 | 0.53,0.38 | piece:BagFence_Round_F | building:u_House_Big_02_V1_F(box; its wall 0.8 m on) | box end: 0.8 m to the real wall; faces a road, not 2-high |
| Zaros | T3 | yard's north passage: city gate | 5.4 | 0.0 | (gate / bags) | - | - | joins WallCity_01_gate_grey | joins WallCity_01_gate_grey | closed |
| Zaros | T3 | yard's south gap | 2.1 | 3.1 | 3xHB1 | 0.53,0.53 | 0.53,0.53 | wall:city2_8m(box) | wall:city2_8m(box) | closed |
| Zaros | T3 | strip's south leg, house to x 11.8 | 6.3 | 7.0 | 1xMil4+2xCnc | 0.34,0.34 | 0.34,0.34 | office:i_House_Big_01_V1_F | joins HBarrier_Big | closed |
| Zaros | T3 | strip's road line, leg to gate | 8.1 | 9.0 | 1xHBBig | - | 0.43,0.43 | piece:CncBarrierMedium_F | piece:BarGate_F | closed |
| Zaros | T3 | strip's north tie, gate to garden | 1.9 | 2.5 | 2xHB1 | 0.30 | 0.30,0.30 | piece:BarGate_F | wall:concrete_smallwall_4m(box) | faces a road, not 2-high |
| Zaros | T4 | north face, Addon_03 to the GMG | 6.0 | 6.9 | 1xMil4+2xCnc | 0.42,0.42 | 0.38,0.42 | building:i_Addon_03_V1_F(box) | piece:BagFence_Round_F | closed |
| Zaros | T4 | north face, GMG to the corner | 2.0 | 3.1 | 2xCnc | 0.54 | 0.54,0.54 | piece:BagFence_Round_F | joins Mil_WallBig_4m | closed |
| Zaros | T4 | east face, north corner to gate | 7.3 | 8.2 | 1xMil4+3xCnc | 0.43,0.43,0.43 | 0.43,0.43 | piece:CncBarrierMedium_F | piece:BarGate_F | closed |
| Zaros | T4 | south face, HMG to the corner | 1.2 | 1.8 | 1xCnc | - | 0.31,0.31 | piece:BagFence_Round_F | joins HBarrier_Big | closed |
| Zaros | T4 | south face: stone wall, AT and HMG | 7.0 | 0.0 | (gate / bags) | - | - | FREE | joins HBarrier_Big | closed |
| Zaros | T4 | east face, gate to south corner | 25.9 | 27.0 | 3xHBBig+1xCnc | 0.59,0.59,0.59 | 0.59,0.59 | piece:BarGate_F | piece:CncBarrierMedium_F | closed |
| Zaros | T4 | south ground's west side, north | 1.8 | 2.5 | 2xHB1 | 0.33 | 0.33,0.33 | wall:city2_8m(box) | piece:BagFence_Round_F | closed |
| Zaros | T4 | south ground's west side, south | 2.7 | 3.6 | 1xHB3 | - | 0.43,0.43 | piece:BagFence_Round_F | wall:stone_8m(box) | closed |
| Zaros | T4 | the open ground north's west gap | 8.9 | 9.8 | 1xHB5+1xHB3+1xHB1 | 0.48,0.48 | 0.48,0.48 | wall:concrete_smallwall_8m(box) | wall:city_8m(box) | closed |
| Zaros | T4 | wire, open ground north | 9.2 | 8.5 | 1xwire | - | -0.34,-0.34 | FREE | building:i_Addon_03_V1_F(box) | closed |
| Zaros | T4 | wire, outside the stone wall | 23.4 | 24.4 | 3xwire | 0.56,0.56 | 0.50,0.50 | FREE | wall:stone_8m(box) | closed |

Remaining flags, by design or out of my reach:
- **Athira south front's shop end (box end 4.4 m).** The shop is rotated, and its box covers the ground in front of
  its diagonal south-west face. `tl.check()` won't let a piece in, so check in game whether a man can walk between the
  line's end (x ≈ 24.5, y −12) and the shop's wall.
- **Athira strip roadblock (T5) and Zaros strip north tie (T3, 1.9 m).** Both are 1-high on purpose or by size. The
  roadblock is a firing slot the men shoot over. The tie is too short for a 2-high piece, and Zaros's T4 north face
  encloses it.
- **Wire runs** are belts in front of lines, not lines: their ends are left free.

## Research used

- [UFC 4-022-01, Entry Control Facilities](https://www.wbdg.org/FFC/DOD/UFC/ARCHIVES/ufc_4_022_01_2005.pdf) (also
  [EverySpec](https://everyspec.com/DoD/DoD-UFC/ufc_4_022_01_6389/),
  [archived AF ECF guide](https://www.wbdg.org/FFC/AF/AFDG/ARCHIVES/entrycontrol.pdf),
  [access-control design notes](https://breakingac.com/news/2026/jan/05/designing-safer-access-control-points-for-military-and-government-sites/)).
  An ECF is an approach zone, then a controlled entry, then a response zone with an overwatch post at the barrier.
  Here that is the chicane outside the gate, the gate's lane men, and the tower or embrasure gun covering the gate.
- HESCO/H-barrier perimeters
  ([army-technology](https://www.army-technology.com/contractors/civil-defence-security-and-law-enforcement/hesco/),
  [militarysystems-tech](https://www.militarysystems-tech.com/suppliers/force-protection/hesco-bastion-ltd)): one
  continuous filled-unit line shaped to the ground, with corners built into the line. Hence ring faces that run from
  building to building with corner overlaps, and gun embrasures in the line instead of guns behind a blind 2-high wall.

## What to check in the game

1. **The top views at T4/T5:** each ring should read continuous. In the audit, every run reads "closed" (or
   "joins …" at a corner). Please list any gap a man fits through, with its [x, y].
2. **Box ends:** listed above, Athira's shop corner first. Also Athira's west mouth, which ends on the scaffolding's
   box beside House_Big_01: check whether the scaffolding is passable at ground level.
3. **Statics:** the roof GMG at (−14.5, −5.5) in Kavala and Pyrgos (I traced the low roof walls from a picture, give or
   take 1 m); the new embrasure guns (Zaros's corners, Athira's west mouth and lane, Kavala's street); and whether any
   gun still floats.
4. **Bag towers:** the clip check now uses a 5.6 × 7.4 m footprint (round 4's evidence) rather than the 6.4 × 9.8 m box.
   Check Zaros's south-ground tower at (−6, −19.8) and Pyrgos's front towers.
5. **CncBarrierMedium's real length:** 1.8 m measured against 4 m in townlib's CLASSES. The runs use 1.8 m; check that
   the T-walls actually close their joints.
6. **Kavala's outer chicane block** at (12.4, −35.6), by the unprobed small house.
