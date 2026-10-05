# towns: round 8 measurements (in-game, Altis)

Per tier: items in the layout / guards / props / statics / items not made (class missing); then the problems found.
clips = a building, wall, rock or the office's walls runs through it; floating = gap under it (m); moved = a guard pushed
more than 1 m off his post (stuck in geometry); blind = a guard's view ends within 4 m (facing a wall); blocked = a
static's field of fire ends within 15 m; view = the guards' median clear view (m). A flagged item's [x, y] is where
it stood in the office's model coordinates (your drafts' own). Screenshots beside this file:
<town>_T<tier>_top.jpg (from 55 m above the ground or the roof, north up) and <town>_T<tier>_street.jpg (from 35 m out on the street side, 20 m up).

## Paros
Closure routes start at [0.7,5.8] (office model; found on the bare site, 'none': not checked)
- **Tier 2**: 4 items / 0 guards / 4 props / 0 statics / 0 missing; median view 0 m
  - ways out (bearing from the office's front; the gap: where the route last passes within 3 m of a fortification):
    - closure unknown (1 of 8 routes not computed): the check couldn't start, not a pass
- **Tier 3**: 26 items / 0 guards / 26 props / 0 statics / 0 missing; median view 0 m
  - ways out (bearing from the office's front; the gap: where the route last passes within 3 m of a fortification):
    - closure unknown (1 of 8 routes not computed): the check couldn't start, not a pass
  - clips: [["Land_HBarrier_5_F","i_house_small_01_v1_f.p3d",[13.8,-10.6]]]
- **Tier 4**: 61 items / 0 guards / 61 props / 0 statics / 0 missing; median view 0 m
  - ways out (bearing from the office's front; the gap: where the route last passes within 3 m of a fortification):
    - closure unknown (1 of 8 routes not computed): the check couldn't start, not a pass
  - clips: [["Land_HBarrier_5_F","i_house_small_01_v1_f.p3d",[13.8,-10.6]]]

## Real sizes of the classes used ([length, depth, height] m, boundingBoxReal)

- Land_BagFence_Long_F: [3.1,0.5,0.9]
- Land_BagFence_Short_F: [2,0.5,0.9]
- Land_CncWall1_F: [1.4,1,3.7]
- Land_HBarrier_1_F: [1.4,1.7,1.5]
- Land_HBarrier_3_F: [3.6,1.8,1.6]
- Land_HBarrier_5_F: [5.8,1.7,1.6]
- Land_Mil_WallBig_4m_F: [4.1,1.1,4.7]
