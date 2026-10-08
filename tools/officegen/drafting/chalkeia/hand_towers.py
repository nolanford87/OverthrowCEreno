"""Chalkeia (the user's areas): tower_gen.py finds no ground level enough on the hill. The towers set by hand on the
flattest spots against the walls, stairs in (towersearch.py: real footprints, off the pieces, rocks, gate lanes):
T3 the sandbag tower against the track's wall at the south-west, by the shed (0.41 m fall); T4 two cargo patrol towers, one at the
north-west over the lower town and the west road (1.2 m fall), one in the north-east yard by the track (0.94 m).
Also the user's own elevated posts (editor review 2026-10-08): their riflemen and roof sandbags where they put them,
flagged "user" so garrison_gen.py keeps them through a regen and counts them as placed (seeds of the wall coverage)."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # tools/officegen
import merge_layouts as ml, blocklib as bl
b = bl.load()['Chalkeia']
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
O = b.pos
PLAN = {3: [('Land_BagBunker_Tower_F', (-12.1, -15.7), (-0.827, 0.563))],
        4: [('Land_Cargo_Patrol_V1_F', (-35.9, 26.3), (0.991, 0.137)), ('Land_Cargo_Patrol_V1_F', (8.8, 9.6), (-0.848, 0.53))]}
# The user's extra T4 watch tower (editor review), their position and turn, on the north slope over the lower town
USER = {4: [('Land_Cargo_Patrol_V1_F', [20219.621, 11693.315, 45.747], (-0.8126, -0.5828))]}
# The user's elevated posts: (tier, man [x,y,z], heading, sandbag [x,y,z] + [vdir, vup] or None for a balcony)
USER_POSTS = [
    (3, [20209.096, 11659.088, 58.998], 237.3, ([20208.307, 11659.437, 58.720], "[[-0.7836,0.5763,-0.2321],[-0.1475,0.1902,0.9706]]")),
    (3, [20212.103, 11632.845, 59.450], 81.6, ([20213.898, 11631.393, 59.770], "[[-0.8271,0.5617,-0.0208],[0.0120,0.0546,0.9984]]")),
    (3, [20189.072, 11619.801, 60.602], 311.1, None),
    (4, [20194.945, 11608.928, 60.658], 136.4, None),
    (4, [20216.096, 11704.938, 49.356], 315.0, ([20217.664, 11706.221, 48.624], "[[0.8553,0.5162,0.0446],[-0.1272,0.1259,0.9838]]")),
    (4, [20234.214, 11674.380, 56.170], 60.3, ([20234.814, 11674.286, 56.130], "[[0.8006,-0.5870,0.1203],[-0.0860,0.0860,0.9926]]")),
]
f3 = lambda w: f"[{w[0]:.3f},{w[1]:.3f},{w[2]:.3f}]"
for tier in sorted(set(PLAN) | set(USER)):
    towers = PLAN.get(tier, [])
    items = [it for it in t['tiers'][tier] if 'lookout' not in it[4] and 'user' not in it[4].split(',')]
    for cls, loc, d in towers:
        w = (O[0] + loc[0], O[1] + loc[1])
        items.append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{b.ground(*w):.3f}]", f"[[{d[0]:.4f},{d[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,lookout"])
        print(f"T{tier}: {cls} at {loc}")
    for cls, w, d in USER.get(tier, []):
        items.append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{w[2]:.3f}]", f"[[{d[0]:.4f},{d[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,lookout"])
        print(f"T{tier}: the user's {cls}")
    for tr, man, hdg, bag in USER_POSTS:
        if tr != tier:
            continue
        items.append(["guard", "rifleman", f3(man), f"{hdg:.1f}", "garrison,elevated,user"])
        if bag:
            items.append(["object", "Land_BagFence_Short_F", f3(bag[0]), bag[1], "post,user"])
        print(f"T{tier}: the user's elevated post at {man[:2]}" + (" + sandbags" if bag else " (balcony)"))
    t['tiers'][tier] = items
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
