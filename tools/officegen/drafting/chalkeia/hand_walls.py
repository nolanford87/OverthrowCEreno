"""Chalkeia hand edits after compound_gen.py: the old stone wall and pillar at T4's south-west corner and the open-fronted garage on the track's line hidden."""
import sys, math
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import merge_layouts as ml, blocklib as bl
b = bl.load()['Chalkeia']
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
HIDE = {4: [(-34.0, -46.0), (-31.0, -43.2)]}
# T4: the garage on the track's line (Land_i_Garage_V2_F, open-fronted: the layout check's routes went out through
# it), hidden as at Rodopoli
BLD_HIDE = {4: [(-31.1, -38.4)]}
for tier, pts in HIDE.items():
    items = t['tiers'][tier]
    for x, y in pts:
        o = min(b.walls, key=lambda w: math.dist(b.local(*w.pos[:2]), (x, y)))
        assert math.dist(b.local(*o.pos[:2]), (x, y)) < 0.2
        items.append(["hide", o.model, f"[{o.pos[0]:.3f},{o.pos[1]:.3f},{o.pos[2]:.3f}]", "[[0.0000,1.0000,0.0000],[0.0000,0.0000,1.0000]]", ""])
        print(f"T{tier}: hid {o.model} at {x}, {y}")
for tier, pts in BLD_HIDE.items():
    for x, y in pts:
        o = min(b.buildings, key=lambda w: math.dist(b.local(*w.pos[:2]), (x, y)))
        assert math.dist(b.local(*o.pos[:2]), (x, y)) < 0.2
        t['tiers'][tier].append(["hide", o.model, f"[{o.pos[0]:.3f},{o.pos[1]:.3f},{o.pos[2]:.3f}]", "[[0.0000,1.0000,0.0000],[0.0000,0.0000,1.0000]]", ""])
        print(f"T{tier}: hid {o.model} at {x}, {y}")
# The user's small concrete wall at T3 (editor review)
t['tiers'][3].append(["object", "Land_CncWall1_F", "[20210.709,11663.369,52.093]", "[[0.8267,-0.5626,0.0000],[0.0000,0.0000,1.0000]]", "ground"])
print("T3: the user's Land_CncWall1_F")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
