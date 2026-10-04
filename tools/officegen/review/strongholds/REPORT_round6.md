# Strongholds: round 6 report (answering round5.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`; `python tools/officegen/drafting/strongholds.py --audit`
reprints the line audit.

## Counts (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala | 7 / 3 / 0 | 12 / 6 / 0 | 25 / 12 / 2 | 86 / 21 / 4 | 146 / 39 / 7 |
| Pyrgos | 7 / 3 / 0 | 14 / 6 / 0 | 40 / 13 / 2 | 79 / 22 / 4 | 115 / 37 / 6 |
| Athira | 6 / 2 / 0 | 14 / 6 / 0 | 46 / 12 / 2 | 68 / 19 / 3 | 93 / 32 / 5 |
| Zaros | 6 / 2 / 0 | 14 / 6 / 0 | 35 / 11 / 2 | 83 / 20 / 3 | 104 / 32 / 5 |

## The checker learned from round 5 (so it now predicts what the game measured)

- **Tree crowns.** The probe's tree boxes are their crowns. A man standing inside a ficus crown is blind: one on a
  tower within 0.75 of the box half-width, one on the ground within 0.34 of it. Fitted to round 5: the blind Pyrgos
  tower men stood 0.4 of the half-width from a trunk, the checkpoint man 0.29; men 0.35-0.4 from one on the ground
  could see. Rays merely passing a crown were fine. With this, the checker flags exactly round 5's blind Pyrgos men
  and none of the posts the game passed.
- **Pipe fences block a man's view**, which the game confirmed for Pyrgos's south checkpoint man.
- **The bag tower's footprint** is the measured 9.8 m deep but sits 1.1 m back of its origin, on the ladder side.
  Round 4: a fence 3.8 m in front, no clip. Round 5: a fence 5.3 m behind, clip.
- **Tower men** are put 0.5 m over the platform and drop onto it, at ±0.35 m either side.

## Design (the critique's points)

- **Zaros, the west yard's mouth onto the road.** It is now walled 2-high from the north face's corner to Addon_02's
  corner, along x 10 for 11.7 m (one HBarrier_Big and two Mil walls), facing the road. With the west gap closed at T4,
  the open ground north and the passage are now an enclosed bailey; its only ways out are the yard's city gate and the
  ring. The new line stays west of the GMG's field up the road. The south yard's low stone wall is audited
  end to end (x −16.6..9.2): no opening. The Stone_Gate in it lies outside the ground's west line.
- **Athira, what closes the east side between the two eastern buildings** (the shop top right, the house south-east).
  The south front's 2-high run closes it, from the GMG's low stretch at x 9 to the shop at x ≈ 24.5 (along y −12.0).
  Beyond it (south-east) is the gap between the shop and the house to the south, which is outside the compound. One caveat:
  the run ends on the shop's box, and the shop's real south-west wall is 4.4 m further on, inside the box, where
  `tl.check()` won't let a piece go. Please look at the shop's south corner: is there a walkable gap between the
  line's end and the wall? If there is, it's the one hole the box rule leaves me.
- Kavala and Pyrgos: no structural change, by the critique. Pyrgos's front towers moved (below).

## Measured problems

| Problem | Fix |
|---|---|
| Kavala tower men pushed off (−4.2, −17.3), (−3.3, 14.7), (−2.4, 15.4) | The towers are turned as meant: the men sit at local (∓0.45, +0.3), facing the tower's +y, the same in every town. Zaros's and Athira's were fine, and the ground under both Kavala towers is flat to 0.2 m, so the surface there is likely higher than the probe's terrain. The men now go 0.5 m over the platform and drop onto it, at ±0.35 m. |
| Pyrgos tower marksmen blind (1.4, −23), (15.4, −24.4) | Both stood inside ficus crowns. New towers at (−11, −30) looking east across the gate's front, and (−26, −30) looking west over the west lot, chosen by a search for spots clear of crowns, fences and walls that cut no gun's field. The old (15.3, −23.8) tower also cut a pipe fence behind it; gone. |
| Pyrgos T5 riflemen blind (11.1, −31.7), (−31.8, −11.1) | South checkpoint: its men had a pipe fence 1.9 m in front; it's now at x 9, its men on the far lane. West checkpoint: its men stood in a ficus crown; it moved 3 m north. |
| Athira GMG (3.3, −10.4) 0 m | The bar gate's arm (9.7 m measured) reaches x ≈ 3.1. The GMG's bag is back at round 4's place (3.3, −12.6), which the game passed, facing 195, the gun 2.6 m back. |
| Athira "hmg"/AT (−15.8, −6.7) 13.8 m | House_Small_01's box top slants up to y −6.5 at x −30. The HMG now fires at 275. |
| Kavala GMG (15.2, −28.3) 9.9 m | It hit the house beyond the probe to the south-east; it now fires at 185. The chicane block it would pass moved 0.8 m west. |
| Athira mortar (6.8, −1.4), something 5 m in front | Something unprobed stands at about (6.8, −6.5): round 4's mortar was pushed by it too. The mortar is now at (8.0, 2.5) facing east, 15 m clear. |
| Zaros mortar 13.8 m | Moved to (−11.5, −11.5) facing north, 18.8 m clear. |
| Athira T5 rifleman pushed (5.1, 5.2) | He stood on the side door's short sandbag. Moved to (14.5, 3.5), looking over the courtyard opening's low line. |
| Kavala bar gate into a city wall | Moved to y −12.0, clear of the forecourt walls' ends. A 0.2 m crack is left between it and the wall ends, too narrow for a man; that's the audit's "OPEN 0.0-0.1, 5.1-5.2". |
| Kavala BagFence_Long and CncBarrierMedium4 into House_Big_02 (T5) | That's the south checkpoint, by a house beyond the probe. Moved 4.5 m north and 2.8 m west, its sides swapped. |
| Pyrgos tower into a pipe fence | Fixed by the tower move above. |
| Floating 0.3-0.5 m | Zaros's GMG (0.3 m, also pushed 2.5 m off its post) and its pit are unchanged, at the road's edge with the passage line beside it. Please check it again. The AT guns' 0.5 m is their tripod. |

## Line audit (every run: gap closed, run end to end, joints and end overlaps in m)

| Town | Tier | Run | Gap | Run | Pieces | Joints | Ends | Closed by | Audit |
|---|---|---|---|---|---|---|---|---|---|
| Kavala | T3 | west yard's gap, wall to block | 4.2 | 5.2 | 1xHB3+2xHB1 | 0.59,0.59 | 0.59,0.38 | wall:city_8m(box) | office:Offices_01_V1_F | closed |
| Kavala | T3 | forecourt's mouth: bar gate | 5.2 | 0.0 | (gate / bags / walls) | - | - | joins BarGate | joins BarGate | OPEN 0.0-0.1, 5.1-5.2 |
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
| Kavala | T5 | outer yard's square face, GMG to c | 5.2 | 5.6 | 1xMil4+1xCnc | 0.30 | 0.30,0.08 | piece:BagFence_Round_F | joins Mil_WallBig_4m | closed |
| Kavala | T5 | outer yard's street side | 5.5 | 6.6 | 1xMil4+2xCnc | 0.55,0.55 | 0.55,0.55 | piece:CncBarrierMedium_F | piece:BagFence_Long_F | closed |
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
| Pyrgos | T4 | wire, east of the fence | 9.6 | 8.5 | 1xwire | - | -0.56,-0.56 | wall:pipe_fence_4m(box) | FREE | closed |
| Pyrgos | T5 | north lane's roadblock | 3.3 | 4.4 | 1xHB3+1xHB1 | 0.57 | 0.57,0.57 | wall:concrete_smallwall_8m(box) | wall:city2_8m(box) | closed |
| Pyrgos | T5 | north lane filled 2-high | 41.5 | 42.7 | 5xHBBig | 0.58,0.58,0.58,0.58 | 0.58,0.58 | piece:HBarrier_3_F | wall:city2_8m(box) | closed |
| Athira | T3 | west mouth, bags to the scaffoldin | 1.3 | 2.2 | 2xHB1 | 0.58 | 0.58,0.38 | piece:BagFence_Round_F | building:scaffolding(box) | closed |
| Athira | T3 | west mouth: the two embrasures' ba | 6.1 | 0.0 | (gate / bags / walls) | - | - | FREE | FREE | closed |
| Athira | T3 | the lot's south side, House_Small_ | 11.3 | 12.0 | 2xMil4+3xCnc | 0.39,0.39,0.39,0.39 | 0.38,0.39 | building:i_House_Small_01_V3_F(box) | wall:city_8m(box) | closed |
| Athira | T3 | lane north, embrasure to the scaff | 1.8 | 2.5 | 2xHB1 | 0.35 | 0.35,0.35 | piece:BagFence_Round_F | building:scaffolding(box) | closed |
| Athira | T3 | lane north, embrasure to House_Sma | 2.3 | 3.2 | 3xHB1 | 0.51,0.51 | 0.51,0.38 | piece:BagFence_Round_F | building:i_House_Small_02_V1_F(box) | closed |
| Athira | T3 | the courtyard's opening, wall end | 4.5 | 5.5 | 1xHB3+2xHB1 | 0.46,0.46 | 0.46,0.46 | wall:city_pillar(box) | wall:city_pillar(box) | closed |
| Athira | T3 | south front, gate to GMG | 1.1 | 1.8 | 1xCnc | - | 0.37,0.37 | piece:BarGate_F | piece:BagFence_Round_F | closed |
| Athira | T3 | south front, GMG to x 9 (low) | 4.6 | 5.8 | 1xHB5 | - | 0.59,0.59 | piece:BagFence_Round_F | joins HBarrier_Big | closed |
| Athira | T3 | south front, x 9 to the shop | 11.6 | 12.5 | 1xHBBig+1xMil4 | 0.56 | 0.56,0.38 | piece:HBarrier_5_F | building:i_Shop_02_V2_F(box; its wall 4.4 m on) | box end: 4.4 m to the real wall |
| Athira | T3 | south front: bar gate | 4.0 | 0.0 | (gate / bags / walls) | - | - | FREE | FREE | closed |
| Athira | T4 | wire across the alley | 7.9 | 8.5 | 1xwire | - | 0.30,0.30 | building:i_House_Big_01_V1_F(box; its wall 1.0 m on) | building:i_House_Small_01_V3_F(box) | box end: 1.0 m to the real wall |
| Athira | T5 | the strip closed, slot to the cour | 2.8 | 3.6 | 1xHB3 | - | 0.38,0.38 | piece:BagFence_Round_F | wall:city_8m(box) | faces a road, not 2-high |
| Athira | T5 | the strip closed, slot to House_Bi | 1.4 | 2.3 | 2xHB1 | 0.53 | 0.53,0.38 | piece:BagFence_Round_F | building:u_House_Big_02_V1_F(box; its wall 0.8 m on) | box end: 0.8 m to the real wall; faces a road, not 2-high |
| Zaros | T3 | yard's north passage: city gate | 5.4 | 0.0 | (gate / bags / walls) | - | - | joins WallCity_01_gate_grey | joins WallCity_01_gate_grey | closed |
| Zaros | T3 | yard's south gap | 2.1 | 3.1 | 3xHB1 | 0.53,0.53 | 0.53,0.53 | wall:city2_8m(box) | wall:city2_8m(box) | closed |
| Zaros | T3 | strip's south leg, house to x 11.8 | 6.3 | 7.0 | 1xMil4+2xCnc | 0.34,0.34 | 0.34,0.34 | office:i_House_Big_01_V1_F | joins HBarrier_Big | closed |
| Zaros | T3 | strip's road line, leg to gate | 8.1 | 9.0 | 1xHBBig | - | 0.43,0.43 | piece:CncBarrierMedium_F | piece:BarGate_F | closed |
| Zaros | T3 | strip's north tie, gate to garden | 1.9 | 2.5 | 2xHB1 | 0.30 | 0.30,0.30 | piece:BarGate_F | wall:concrete_smallwall_4m(box) | faces a road, not 2-high |
| Zaros | T4 | north face, Addon_03 to the GMG | 6.0 | 6.9 | 1xMil4+2xCnc | 0.42,0.42 | 0.38,0.42 | building:i_Addon_03_V1_F(box) | piece:BagFence_Round_F | closed |
| Zaros | T4 | north face, GMG to the corner | 2.0 | 3.1 | 2xCnc | 0.54 | 0.54,0.54 | piece:BagFence_Round_F | joins Mil_WallBig_4m | closed |
| Zaros | T4 | east face, north corner to gate | 7.3 | 8.2 | 1xMil4+3xCnc | 0.43,0.43,0.43 | 0.43,0.43 | piece:CncBarrierMedium_F | piece:BarGate_F | closed |
| Zaros | T4 | south face, HMG to the corner | 1.2 | 1.8 | 1xCnc | - | 0.31,0.31 | piece:BagFence_Round_F | joins HBarrier_Big | closed |
| Zaros | T4 | south face: stone wall, AT and HMG | 7.0 | 0.0 | (gate / bags / walls) | - | - | FREE | joins HBarrier_Big | closed |
| Zaros | T4 | east face, gate to south corner | 25.9 | 27.0 | 3xHBBig+1xCnc | 0.59,0.59,0.59 | 0.59,0.59 | piece:BarGate_F | piece:CncBarrierMedium_F | closed |
| Zaros | T4 | the passage north shut, north face | 11.2 | 11.9 | 2xCnc+1xHBBig | 0.35,0.35 | 0.35,0.35 | piece:CncBarrierMedium_F | building:u_Addon_02_V1_F(box) | closed |
| Zaros | T4 | the south ground's stone wall | 25.8 | 0.0 | (gate / bags / walls) | - | - | joins HBarrier_3 | joins BagFence_Round | closed |
| Zaros | T4 | south ground's west side, north | 1.8 | 2.5 | 2xHB1 | 0.33 | 0.33,0.33 | wall:city2_8m(box) | piece:BagFence_Round_F | closed |
| Zaros | T4 | south ground's west side, south | 2.7 | 3.6 | 1xHB3 | - | 0.43,0.43 | piece:BagFence_Round_F | wall:stone_8m(box) | closed |
| Zaros | T4 | the open ground north's west gap | 8.9 | 9.8 | 1xHB5+1xHB3+1xHB1 | 0.48,0.48 | 0.48,0.48 | wall:concrete_smallwall_8m(box) | wall:city_8m(box) | closed |
| Zaros | T4 | wire, open ground north | 9.2 | 8.5 | 1xwire | - | -0.34,-0.34 | FREE | building:i_Addon_03_V1_F(box) | closed |
| Zaros | T4 | wire, outside the stone wall | 23.4 | 24.4 | 3xwire | 0.56,0.56 | 0.50,0.50 | FREE | wall:stone_8m(box) | closed |

These flags are known and left as they are:
- **Athira's shop corner (box end).** Explained above.
- **Athira's T5 strip roadblock and Zaros's 1.9 m T3 tie** are low by design: the roadblock is a firing slot the men
  shoot over, and the tie is too short for anything 2-high. Zaros's T4 north face covers the tie.
- **Kavala's gate crack.** The 0.2 m left between the gate and the wall ends.

## What to check in the game

1. **Kavala's tower men** at T4 and T5: do they stay on the platform now that they drop 0.5 m onto it? If not, please
   log the platform's height above the terrain at (−5, −16.4).
2. **Pyrgos's new towers and checkpoints:** the men's views.
3. **Zaros's passage line:** does it read as closing the west yard's mouth from above? And the GMG pit at
   (12.3, 14.2): does it still float or get pushed?
4. **Athira's shop corner** (above) and the GMG at (4.0, −10.1).
