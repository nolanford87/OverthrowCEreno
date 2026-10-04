# strongholds: round 5 measurements (in-game, Altis)

Per tier: items in the layout / guards / props / statics / items not made (class missing); then the problems found.
clips = a building, wall, rock or the office's walls runs through it; floating = gap under it (m); moved = a guard pushed
more than 1 m off his post (stuck in geometry); blind = a guard's view ends within 4 m (facing a wall); blocked = a
static's field of fire ends within 15 m; view = the guards' median clear view (m). A flagged item's [x, y] is where
it stood in the office's model coordinates (your drafts' own). Screenshots beside this file:
<town>_T<tier>_top.jpg (from 55 m above the ground or the roof, north up) and <town>_T<tier>_street.jpg (from 35 m out on the street side, 20 m up).

## Kavala
- **Tier 1**: 7 items / 3 guards / 4 props / 0 statics / 0 missing; median view 30 m
- **Tier 2**: 12 items / 6 guards / 6 props / 0 statics / 0 missing; median view 30 m
- **Tier 3**: 25 items / 12 guards / 11 props / 2 statics / 0 missing; median view 30 m
  - clips: [["Land_BarGate_F","city_4m_f.p3d"]]
- **Tier 4**: 86 items / 21 guards / 61 props / 4 statics / 0 missing; median view 30 m
  - clips: [["Land_BarGate_F","city_4m_f.p3d"]]
  - moved: [["marksman",1.9,[-4.2,-17.3]],["marksman",1.3,[-3.3,14.7]],["autorifleman",2,[-2.4,15.4]]]
- **Tier 5**: 146 items / 39 guards / 100 props / 7 statics / 0 missing; median view 30 m
  - clips: [["Land_BarGate_F","city_4m_f.p3d"],["Land_BagFence_Long_F","i_house_big_02_v1_f.p3d"],["Land_CncBarrierMedium4_F","i_house_big_02_v1_f.p3d"]]
  - floating: [["B_static_AT_F",0.5,[19.2,-15.9]]]
  - moved: [["marksman",1.7,[-4.1,-18]],["marksman",2,[-2.2,15.6]]]
  - blocked: [["gmg",9.9,[15.2,-28.3]]]

## Pyrgos
- **Tier 1**: 7 items / 3 guards / 4 props / 0 statics / 0 missing; median view 27.9 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 27.9 m
- **Tier 3**: 40 items / 13 guards / 25 props / 2 statics / 0 missing; median view 30 m
- **Tier 4**: 79 items / 22 guards / 53 props / 4 statics / 0 missing; median view 30 m
  - clips: [["Land_BagBunker_Tower_F","pipe_fence_4m_f.p3d"]]
  - blind: [["marksman",0,[1.4,-23]],["marksman",0.1,[15.4,-24.4]]]
- **Tier 5**: 115 items / 37 guards / 72 props / 6 statics / 0 missing; median view 27.4 m
  - clips: [["Land_BagBunker_Tower_F","pipe_fence_4m_f.p3d"]]
  - blind: [["marksman",0,[15.3,-24.4]],["rifleman",0,[11.1,-31.7]],["rifleman",0,[-31.8,-11.1]]]

## Athira
- **Tier 1**: 6 items / 2 guards / 4 props / 0 statics / 0 missing; median view 29.7 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 29.7 m
- **Tier 3**: 46 items / 12 guards / 32 props / 2 statics / 0 missing; median view 29.7 m
  - floating: [["B_static_AT_F",0.5,[-15.8,-6.7]]]
  - blocked: [["hmg",13.8,[-15.8,-6.7]],["gmg",0,[3.3,-10.4]]]
- **Tier 4**: 68 items / 19 guards / 46 props / 3 statics / 0 missing; median view 23.3 m
- **Tier 5**: 93 items / 32 guards / 56 props / 5 statics / 0 missing; median view 25.9 m
  - moved: [["rifleman",1.3,[5.1,5.2]]]
  - blocked: [["mortar",5,[6.8,-1.4]]]

## Zaros
- **Tier 1**: 6 items / 2 guards / 4 props / 0 statics / 0 missing; median view 30 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 30 m
- **Tier 3**: 35 items / 11 guards / 22 props / 2 statics / 0 missing; median view 30 m
  - floating: [["B_static_AT_F",0.5,[11.4,-23]],["B_GMG_01_high_F",0.3,[10.6,12.3]]]
- **Tier 4**: 80 items / 20 guards / 57 props / 3 statics / 0 missing; median view 30 m
- **Tier 5**: 101 items / 32 guards / 64 props / 5 statics / 0 missing; median view 30 m
  - blocked: [["mortar",13.8,[-10.5,-6]]]

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
- Land_HBarrier_1_F: [1.4,1.7,1.5]
- Land_HBarrier_3_F: [3.6,1.8,1.6]
- Land_HBarrier_5_F: [5.8,1.7,1.6]
- Land_HBarrier_Big_F: [9,2.6,2.6]
- Land_MapBoard_F: [1.5,1,2]
- Land_Mil_WallBig_4m_F: [4.1,1.1,4.7]
- Land_OfficeChair_01_F: [0.8,0.7,1.3]
- Land_Razorwire_F: [8.5,2.1,2.1]
- Land_TableDesk_F: [1.8,0.9,0.8]
- Land_WallCity_01_gate_grey_F: [4.6,4.3,4.3]

## Where a man stands on a placed object (its building positions, MODEL coordinates [x, y, z] from its origin)
Put a tower's or bunker's guard exactly there (turned with the object) instead of guessing a height.

- Land_BagBunker_Small_F: [[-0.1,1.2,-0.9],[-0.9,-1.2,-0.9],[0.9,-1.2,-0.9]]
