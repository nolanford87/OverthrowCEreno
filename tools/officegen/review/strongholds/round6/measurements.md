# strongholds: round 6 measurements (in-game, Altis)

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
- **Tier 4**: 86 items / 21 guards / 61 props / 4 statics / 0 missing; median view 30 m
  - moved: [["marksman",1.3,[-5.9,-17]],["autorifleman",1.6,[-4.1,-15.7]],["marksman",1.6,[-4.1,15]],["autorifleman",1.4,[-2.4,16.9]]]
- **Tier 5**: 146 items / 39 guards / 100 props / 7 statics / 0 missing; median view 30 m
  - floating: [["B_static_AT_F",0.5,[19.2,-15.9]]]
  - moved: [["marksman",1.4,[-5.5,-17.6]],["autorifleman",1.5,[-4.6,-15.4]],["marksman",1.5,[-4,15]],["autorifleman",1.3,[-2.7,16.9]],["marksman",1.1,[-5,-26.6]]]
  - blocked: [["gmg",9.7,[15.7,-28.4]]]

## Pyrgos
- **Tier 1**: 7 items / 3 guards / 4 props / 0 statics / 0 missing; median view 27.9 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 27.9 m
- **Tier 3**: 40 items / 13 guards / 25 props / 2 statics / 0 missing; median view 30 m
- **Tier 4**: 79 items / 22 guards / 53 props / 4 statics / 0 missing; median view 30 m
  - clips: [["B_static_AT_F","office"]]
  - floating: [["B_GMG_01_high_F",0.3,[-14.5,-5.5]],["B_static_AT_F",0.5,[-7.8,-12]]]
  - moved: [["marksman",1.5,[-10.4,-28.6]],["autorifleman",1.8,[-11.9,-31.2]],["marksman",1.3,[-26.2,-30.7]]]
- **Tier 5**: 115 items / 37 guards / 72 props / 6 statics / 0 missing; median view 29.3 m
  - floating: [["B_GMG_01_high_F",0.3,[-14.5,-5.5]]]
  - moved: [["marksman",1.3,[-10.1,-29.9]],["autorifleman",1.6,[-11.6,-29.5]],["marksman",1.2,[-26.5,-30.5]]]

## Athira
- **Tier 1**: 6 items / 2 guards / 4 props / 0 statics / 0 missing; median view 29.7 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 29.7 m
- **Tier 3**: 46 items / 12 guards / 32 props / 2 statics / 0 missing; median view 30 m
  - blocked: [["hmg",7.6,[-16.5,-6.7]],["gmg",0,[4.1,-10.1]]]
- **Tier 4**: 68 items / 19 guards / 46 props / 3 statics / 0 missing; median view 30 m
  - moved: [["marksman",1.1,[13.1,-4.2]],["autorifleman",1.1,[12.2,-4.3]]]
- **Tier 5**: 93 items / 32 guards / 56 props / 5 statics / 0 missing; median view 30 m
  - moved: [["rifleman",1,[5.4,5.1]],["rifleman",1,[3.2,-5.6]],["marksman",1.1,[13.1,-4.2]],["autorifleman",1.1,[12.2,-4.3]]]

## Zaros
- **Tier 1**: 6 items / 2 guards / 4 props / 0 statics / 0 missing; median view 30 m
- **Tier 2**: 14 items / 6 guards / 8 props / 0 statics / 0 missing; median view 30 m
- **Tier 3**: 35 items / 11 guards / 22 props / 2 statics / 0 missing; median view 30 m
  - floating: [["B_static_AT_F",0.6,[14.7,-21.4]]]
- **Tier 4**: 83 items / 20 guards / 60 props / 3 statics / 0 missing; median view 30 m
  - moved: [["marksman",1.1,[3.8,4.5]],["marksman",1.1,[-6.2,-20.3]],["autorifleman",1.1,[-6.3,-19.4]]]
  - blocked: [["gmg",0,[12.2,14.1]]]
- **Tier 5**: 104 items / 32 guards / 67 props / 5 statics / 0 missing; median view 30 m
  - moved: [["marksman",1.1,[-6.2,-20.3]],["autorifleman",1.1,[-6.3,-19.4]]]
  - blocked: [["gmg",0,[12.2,14.1]]]

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
