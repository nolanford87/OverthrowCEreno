"""Chalkeia (the user's areas): tower_gen.py finds no ground level enough on the hill. The towers set by hand on the
flattest spots against the walls, stairs in (towersearch.py: real footprints, off the pieces, rocks, gate lanes):
T3 the sandbag tower against the track's wall at the south-west, by the shed (0.41 m fall); T4 two cargo patrol towers, one at the
north-west over the lower town and the west road (1.2 m fall), one in the north-east yard by the track (0.94 m)."""
import sys
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import merge_layouts as ml, blocklib as bl
b = bl.load()['Chalkeia']
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
O = b.pos
PLAN = {3: [('Land_BagBunker_Tower_F', (-12.1, -15.7), (-0.827, 0.563))],
        4: [('Land_Cargo_Patrol_V1_F', (-35.9, 26.3), (0.991, 0.137)), ('Land_Cargo_Patrol_V1_F', (8.8, 9.6), (-0.848, 0.53))]}
# The user's extra T4 watch tower (editor review), their position and turn, on the north slope over the lower town
USER = {4: [('Land_Cargo_Patrol_V1_F', [20219.621, 11693.315, 45.747], (-0.8126, -0.5828))]}
for tier, towers in PLAN.items():
    items = [it for it in t['tiers'][tier] if 'lookout' not in it[4]]
    for cls, loc, d in towers:
        w = (O[0] + loc[0], O[1] + loc[1])
        items.append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{b.ground(*w):.3f}]", f"[[{d[0]:.4f},{d[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,lookout"])
        print(f"T{tier}: {cls} at {loc}")
    for cls, w, d in USER.get(tier, []):
        items.append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{w[2]:.3f}]", f"[[{d[0]:.4f},{d[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,lookout"])
        print(f"T{tier}: the user's {cls}")
    t['tiers'][tier] = items
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
