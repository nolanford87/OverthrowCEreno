# villages: round 8 measurements (in-game, Altis)

Per tier: items in the layout / guards / props / statics / items not made (class missing); then the problems found.
clips = a building, wall, rock or the office's walls runs through it; floating = gap under it (m); moved = a guard pushed
more than 1 m off his post (stuck in geometry); blind = a guard's view ends within 4 m (facing a wall); blocked = a
static's field of fire ends within 15 m; view = the guards' median clear view (m). A flagged item's [x, y] is where
it stood in the office's model coordinates (your drafts' own). Screenshots beside this file:
<town>_T<tier>_top.jpg (from 55 m above the ground or the roof, north up) and <town>_T<tier>_street.jpg (from 35 m out on the street side, 20 m up).

## Neri
Closure routes start at [1.1,1.5] (office model; found on the bare site, 'none': not checked)
- **Tier 2**: 2 items / 0 guards / 2 props / 0 statics / 0 missing; median view 0 m
  - ways out (bearing from the office's front; the gap: where the route last passes within 3 m of a fortification):
    - bearing 0: gap [], route [[1.2,1.5],[-0.3,6.8],[-3.3,11.2],[-6.9,15.3],[-11.4,19.2],[-15.8,23.1],[-20.3,26.9],[-20.7,32.6],[-17.7,37.1],[-12.3,38.1],[-7.8,41.3]]
    - bearing 45: gap [], route [[1.2,1.5],[-0.3,6.8],[-3.3,11.2],[-0.9,16.3],[-1.2,22],[3.7,23.7],[9.6,23.7],[15.5,23.6],[21.2,23.3],[26.8,22.9],[31.9,22.7],[32.1,28.1]]
    - bearing 90: gap [0.2,-8.2], route [[1.2,1.5],[-2.2,-2.8],[0.1,-7.3],[6,-7.8],[11.8,-7.3],[16.8,-9],[21.4,-11.4],[24.2,-6.9],[29.8,-8],[35.4,-9],[39.7,-12.7]]
    - bearing 135: gap [0.2,-8.2], route [[1.2,1.5],[-2.2,-2.8],[0.1,-7.3],[6,-7.8],[11.8,-7.3],[16.8,-9],[21.4,-11.4],[24.2,-6.9],[29.8,-8],[34.2,-10.4],[35.2,-15.4],[32.5,-19.8]]
    - bearing 180: gap [-7.3,-6.7], route [[1.2,1.5],[-2.2,-2.8],[0.1,-7.3],[-4.9,-7.9],[-10.2,-6.9],[-16,-7.3],[-21.8,-7.7],[-19.5,-12.2],[-17.8,-17.3],[-17.4,-23.1],[-17,-29],[-16.6,-34.8],[-16.1,-40.6]]
    - bearing 225: gap [-7.3,-6.7], route [[1.2,1.5],[-2.2,-2.8],[0.1,-7.3],[-4.9,-7.9],[-10.2,-6.9],[-16.2,-7.3],[-22.1,-7.8],[-26.3,-11.5],[-30.1,-15.9],[-34,-20.3]]
    - bearing 270: gap [], route []
    - bearing 315: gap [], route [[1.2,1.5],[-0.3,6.8],[-3.3,11.2],[-6.2,16],[-11.2,17.6],[-17,17.2],[-22,16.7],[-27.9,17.1],[-33.8,17.4],[-39.5,17.4]]
- **Tier 3**: 37 items / 0 guards / 37 props / 0 statics / 0 missing; median view 0 m
  - closed: no way out
  - clips: [["Land_HBarrier_1_F","u_house_big_01_v1_f.p3d",[0.6,-13.5]]]

## Real sizes of the classes used ([length, depth, height] m, boundingBoxReal)

- Land_BagFence_Long_F: [3.1,0.5,0.9]
- Land_BagFence_Short_F: [2,0.5,0.9]
- Land_CncWall1_F: [1.4,1,3.7]
- Land_HBarrier_1_F: [1.4,1.7,1.5]
- Land_HBarrier_3_F: [3.6,1.8,1.6]
- Land_HBarrier_5_F: [5.8,1.7,1.6]
- Land_HBarrier_Big_F: [9,2.6,2.6]
- Land_Mil_WallBig_4m_F: [4.1,1.1,4.7]
