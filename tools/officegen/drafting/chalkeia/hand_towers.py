"""Chalkeia: tower_gen finds no level ground. T4's one cargo patrol tower set by hand on the flattest spot against the
track's wall in the north-east yard (0.97 m fall under it), stairs in; T3's lookout and T4's second are window
marksmen (garrison_gen.py, the HQ's upper floor)."""
import sys
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import merge_layouts as ml, blocklib as bl
b = bl.load()['Chalkeia']
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
O = b.pos
for tier, cls, loc, d in ((4, 'Land_Cargo_Patrol_V1_F', (8.5, 9.8), (-0.847, 0.531)),):
    items = [it for it in t['tiers'][tier] if 'lookout' not in it[4]]
    w = (O[0] + loc[0], O[1] + loc[1])
    items.append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{b.ground(*w):.3f}]", f"[[{d[0]:.4f},{d[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,lookout"])
    t['tiers'][tier] = items
    print(f"T{tier}: {cls} at {loc}")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
