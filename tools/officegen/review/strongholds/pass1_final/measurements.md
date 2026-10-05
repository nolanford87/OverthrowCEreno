# strongholds: round 8 measurements (in-game, Altis)

Per tier: items in the layout / guards / props / statics / items not made (class missing); then the problems found.
clips = a building, wall, rock or the office's walls runs through it; floating = gap under it (m); moved = a guard pushed
more than 1 m off his post (stuck in geometry); blind = a guard's view ends within 4 m (facing a wall); blocked = a
static's field of fire ends within 15 m; view = the guards' median clear view (m). A flagged item's [x, y] is where
it stood in the office's model coordinates (your drafts' own). Screenshots beside this file:
<town>_T<tier>_top.jpg (from 55 m above the ground or the roof, north up) and <town>_T<tier>_street.jpg (from 35 m out on the street side, 20 m up).

## Kavala
Closure routes start at [13.1,-6.1] (office model; found on the bare site, 'none': not checked)
- **Tier 2**: 9 items / 0 guards / 9 props / 0 statics / 0 missing; median view 0 m
  - closed: no way out
- **Tier 3**: 55 items / 0 guards / 55 props / 0 statics / 0 missing; median view 0 m
  - closed: no way out
- **Tier 4**: 110 items / 0 guards / 110 props / 0 statics / 0 missing; median view 0 m
  - closed: no way out
  - clips: [["Land_CncWall1_F","canal_wall_10m_f.p3d",[-15.2,60.5]],["Land_CncWall1_F","canal_wall_10m_f.p3d",[-14.2,60.5]],["Land_CncWall1_F","canal_wall_10m_f.p3d",[-13.3,60.5]],["Land_CncWall1_F","canal_wall_10m_f.p3d",[-12.3,60.5]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[-0.2,57.9]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[3.5,56.8]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[16.4,52.9]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[20.1,51.8]]]
- **Tier 5**: 134 items / 0 guards / 134 props / 0 statics / 0 missing; median view 0 m
  - closed: no way out
  - clips: [["Land_CncWall1_F","canal_wall_10m_f.p3d",[-15.2,60.5]],["Land_CncWall1_F","canal_wall_10m_f.p3d",[-14.2,60.5]],["Land_CncWall1_F","canal_wall_10m_f.p3d",[-13.3,60.5]],["Land_CncWall1_F","canal_wall_10m_f.p3d",[-12.3,60.5]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[-0.2,57.9]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[3.5,56.8]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[16.4,52.9]],["Land_Mil_WallBig_4m_F","canal_wall_10m_f.p3d",[20.1,51.8]],["Land_Mil_WallBig_4m_F","office",[-11.4,-0.9]],["Land_Mil_WallBig_4m_F","office",[-39.5,-11.3]]]

## Real sizes of the classes used ([length, depth, height] m, boundingBoxReal)

- Land_BagFence_Long_F: [3.1,0.5,0.9]
- Land_BagFence_Short_F: [2,0.5,0.9]
- Land_CncWall1_F: [1.4,1,3.7]
- Land_HBarrier_1_F: [1.4,1.7,1.5]
- Land_HBarrier_3_F: [3.6,1.8,1.6]
- Land_HBarrier_5_F: [5.8,1.7,1.6]
- Land_HBarrier_Big_F: [9,2.6,2.6]
- Land_Mil_WallBig_4m_F: [4.1,1.1,4.7]
