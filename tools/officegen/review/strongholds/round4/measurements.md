# strongholds: round 4 measurements (in-game, Altis)

Per tier: items in the layout / guards / props / statics / items not made (class missing); then the problems found.
clips = a building, wall, rock or the office's walls runs through it; floating = gap under it (m); moved = a guard pushed
more than 1 m off his post (stuck in geometry); blind = a guard's view ends within 4 m (facing a wall); blocked = a
static's field of fire ends within 15 m; view = the guards' median clear view (m). A flagged item's [x, y] is where
it stood in the office's model coordinates (your drafts' own). Screenshots beside this file:
<town>_T<tier>_top.jpg (from 48 m above, north up) and <town>_T<tier>_street.jpg (from 35 m out on the street side, 20 m up).

## Kavala
- **Tier 1**: 7 items / 3 guards / 4 props / 0 statics / 0 missing; median view 30 m
  - blind: [["gendarme",2.8,[-14.7,6]]]
- **Tier 2**: 12 items / 6 guards / 6 props / 0 statics / 0 missing; median view 30 m
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 3**: 23 items / 12 guards / 9 props / 2 statics / 0 missing; median view 30 m
  - clips: [["B_GMG_01_high_F","office"]]
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 4**: 72 items / 20 guards / 48 props / 4 statics / 0 missing; median view 30 m
  - clips: [["B_GMG_01_high_F","office"]]
  - floating: [["B_static_AT_F",0.5,[18.5,-15.9]]]
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 5**: 126 items / 38 guards / 81 props / 7 statics / 0 missing; median view 30 m
  - clips: [["Land_BagBunker_Small_F","i_house_big_02_v1_f.p3d"],["Land_HBarrier_3_F","i_house_small_01_v3_f.p3d"],["B_GMG_01_high_F","office"]]
  - floating: [["B_static_AT_F",1.4,[19,-16.2]]]
  - blind: [["gendarme",2.8,[-14.7,5.9]]]

## Pyrgos
- **Tier 1**: 7 items / 3 guards / 4 props / 0 statics / 0 missing; median view 28.2 m
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 28.2 m
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 3**: 37 items / 13 guards / 22 props / 2 statics / 0 missing; median view 30 m
  - clips: [["B_GMG_01_high_F","office"]]
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 4**: 69 items / 22 guards / 43 props / 4 statics / 0 missing; median view 30 m
  - clips: [["Land_Razorwire_F","pipe_fence_4m_f.p3d"],["Land_CzechHedgehog_01_F","city2_8m_f.p3d"],["B_GMG_01_high_F","office"]]
  - blind: [["gendarme",2.8,[-14.7,5.9]]]
- **Tier 5**: 106 items / 37 guards / 63 props / 6 statics / 0 missing; median view 30 m
  - clips: [["Land_Razorwire_F","pipe_fence_4m_f.p3d"],["Land_CzechHedgehog_01_F","city2_8m_f.p3d"],["Land_BagBunker_Small_F","pipe_fence_4m_f.p3d"],["B_GMG_01_high_F","office"],["B_static_AT_F","office"]]
  - blind: [["gendarme",2.8,[-14.7,5.9]]]

## Athira
- **Tier 1**: 6 items / 2 guards / 4 props / 0 statics / 0 missing; median view 20.4 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 23.4 m
- **Tier 3**: 35 items / 11 guards / 22 props / 2 statics / 0 missing; median view 26.1 m
- **Tier 4**: 61 items / 18 guards / 40 props / 3 statics / 0 missing; median view 23.4 m
- **Tier 5**: 84 items / 31 guards / 48 props / 5 statics / 0 missing; median view 20.6 m
  - floating: [["B_static_AT_F",0.7,[-22.4,-5.1]]]
  - blind: [["rifleman",0,[25,9.3]],["autorifleman",0,[25.1,10.5]],["rifleman",1,[-3.7,1.9]]]
  - blocked: [["hmg",11.1,[11.9,-10.3]],["mortar",0.3,[7.8,-3.9]]]

## Zaros
- **Tier 1**: 6 items / 2 guards / 4 props / 0 statics / 0 missing; median view 30 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 30 m
  - clips: [["Land_BagFence_Short_F","office"]]
- **Tier 3**: 31 items / 11 guards / 18 props / 2 statics / 0 missing; median view 30 m
  - clips: [["Land_BagFence_Short_F","office"]]
- **Tier 4**: 58 items / 19 guards / 36 props / 3 statics / 0 missing; median view 30 m
  - clips: [["Land_BagFence_Short_F","office"]]
- **Tier 5**: 81 items / 31 guards / 45 props / 5 statics / 0 missing; median view 30 m
  - clips: [["Land_BagFence_Short_F","office"]]
  - blind: [["rifleman",1,[-3.7,1.9]]]

## Real sizes of the classes used ([length, depth, height] m, boundingBoxReal)

- B_GMG_01_high_F: [1.6,2.3,3.4]
- B_Mortar_01_F: [2.5,1.9,1.7]
- B_static_AT_F: [1,2.3,2]
- Flag_NATO_F: [0.4,1.2,8.3]
- Land_BagBunker_Small_F: [5,5.7,2.5]
- Land_BagBunker_Tower_F: [6.4,9.8,5.7]
- Land_BagFence_Long_F: [3.1,0.5,0.9]
- Land_BagFence_Round_F: [2.9,1.1,0.9]
- Land_BagFence_Short_F: [2,0.5,0.9]
- Land_BarGate_F: [9.7,0.5,8.8]
- Land_CncBarrierMedium4_F: [7.6,1.8,2]
- Land_CncBarrierMedium_F: [1.8,1.8,2]
- Land_CncBarrier_F: [2.6,0.4,0.8]
- Land_CzechHedgehog_01_F: [1.8,1.8,1.4]
- Land_HBarrierWall4_F: [5.7,4.8,3.7]
- Land_HBarrierWall6_F: [8.5,4.9,3.7]
- Land_HBarrier_1_F: [1.4,1.7,1.5]
- Land_HBarrier_3_F: [3.6,1.8,1.6]
- Land_HBarrier_5_F: [5.8,1.7,1.6]
- Land_HBarrier_Big_F: [9,2.6,2.6]
- Land_MapBoard_F: [1.5,1,2]
- Land_Mil_WallBig_4m_F: [4.1,1.1,4.7]
- Land_OfficeChair_01_F: [0.8,0.7,1.3]
- Land_PipeFence_03_m_gate_r_F: [3.3,5.1,2.4]
- Land_Razorwire_F: [8.5,2.1,2.1]
- Land_TableDesk_F: [1.8,0.9,0.8]
- Land_WallCity_01_gate_grey_F: [4.6,4.3,4.3]

## Where a man stands on a placed object (its building positions, MODEL coordinates [x, y, z] from its origin)
Put a tower's or bunker's guard exactly there (turned with the object) instead of guessing a height.

- Land_BagBunker_Small_F: [[-0.1,1.2,-0.9],[-0.9,-1.2,-0.9],[0.9,-1.2,-0.9]]
