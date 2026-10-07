"""Chalkeia hand edits after compound_gen.py: the old stone wall and pillar at T4's south-west corner hidden (on the line)."""
import sys, math
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import merge_layouts as ml, blocklib as bl
b = bl.load()['Chalkeia']
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
HIDE = {4: [(-34.0, -46.0), (-31.0, -43.2)]}
for tier, pts in HIDE.items():
    items = t['tiers'][tier]
    for x, y in pts:
        o = min(b.walls, key=lambda w: math.dist(b.local(*w.pos[:2]), (x, y)))
        assert math.dist(b.local(*o.pos[:2]), (x, y)) < 0.2
        items.append(["hide", o.model, f"[{o.pos[0]:.3f},{o.pos[1]:.3f},{o.pos[2]:.3f}]", "[[0.0000,1.0000,0.0000],[0.0000,0.0000,1.0000]]", ""])
        print(f"T{tier}: hid {o.model} at {x}, {y}")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
