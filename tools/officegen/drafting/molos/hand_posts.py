"""Molos (the user's theme: the chapel as the occupier's strongpoint): at T3 (lighter: its 12 men need their posts at the walls) and T4, sandbagged ground posts round its
one door (its west end, OTBEXIT) and its apse, and men in and around it. Flagged "hand": garrison_gen.py keeps them
and counts them in the garrison (one man per 150 m2), the rest of the garrison placed round them. No bell-tower
lookout: the class probe finds nowhere a man can stand above the nave (OTFLOORS, OTBPOS). Run after props_gen.py,
before garrison_gen.py. Model coordinates (the chapel faces north, dir 0)."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # tools/officegen
import math
import merge_layouts as ml, blocklib as bl
b = bl.load()['Molos']
O = b.pos
H = 0.51  # the nave's floor above the chapel's base (OTBPOS)
# (kind, class or role, model x, y, facing x, y, inside the chapel, the tiers)
POSTS = [
    ("object", "Land_BagFence_Round_F", 15.6, 3.4, 0.7, 0.7, False, (3, 4)),    # the apse's two corners, facing out
    ("object", "Land_BagFence_Round_F", 15.6, -3.4, 0.7, -0.7, False, (4,)),
    ("guard", "rifleman", 14.4, 2.6, 0.7, 0.7, False, (3, 4)),
    ("guard", "rifleman", 14.4, -2.6, 0.7, -0.7, False, (4,)),
    ("guard", "autorifleman", -12.6, -0.6, -1, 0, False, (3, 4)),            # behind the door's sandbag (T2's; T4: none), facing out
    ("guard", "rifleman", -8.6, 4.4, -0.7, 0.7, False, (4,)),           # the door's north side (no bags: the
                                                                       # T4 wall's gate stands 3 m out, the way out runs south)
    ("guard", "marksman", -3.3, -2.9, -1, 0, True, (3, 4)),                  # in the nave (its places): a reserve group
    ("guard", "rifleman", 5.6, 3.0, -1, 0, True, (3, 4)),                    # of their own, at ease, out on the alarm
]
# The user's edits in the layout editor (review, 2026-10-10), kept through regens ("user"): small concrete wall closing
# the chapel's north-west corner (T3, T4) and one more on T3's east line; T3's roof rifleman moved, his sandbag as it was
USER = {3: [["object", "Land_CncWall1_F", "[26989.322,23278.947,20.603]", "[[0.5760,-0.8174,0.0000],[0.0000,0.0000,1.0000]]", "user"],
            ["object", "Land_CncWall1_F", "[26988.428,23278.250,20.598]", "[[0.5760,-0.8174,0.0000],[0.0000,0.0000,1.0000]]", "user"],
            ["object", "Land_CncWall1_F", "[27017.910,23276.371,21.307]", "[[0.6376,0.7704,0.0000],[0.0000,0.0000,1.0000]]", "user"],
            ["guard", "rifleman", "[27006.623,23272.787,26.406]", "30.5", "garrison,elevated,user"],
            ["object", "Land_BagFence_Short_F", "[27007.850,23272.970,25.850]", "[[-0.1276,0.9918,0.0000],[0.0000,0.0000,1.0000]]", "post,user"]],
        4: [["object", "Land_CncWall1_F", "[26989.098,23279.213,20.605]", "[[0.5782,-0.8159,0.0000],[0.0000,0.0000,1.0000]]", "user"],
            ["object", "Land_CncWall1_F", "[26988.641,23278.914,20.603]", "[[0.5782,-0.8159,0.0000],[0.0000,0.0000,1.0000]]", "user"]]}
towns = ml.load_saved('Altis')
t = towns['Molos']
for tier in (3, 4):
    items = [it for it in t['tiers'][tier] if 'hand' not in it[4].split(',')]
    # T2's long sandbag in front of the door stands in the T3/T4 main gate's lane (the gate went on the line by the
    # door): out at these tiers (with it and T4's HMG nest the way in was shut: the layout check found no way out)
    # and at T4 its short one by the door and the gate's floodlight beside it: with the HMG nest south of the door
    # they shut the door's corner off from the gate (the layout check found no way out of it)
    drop = [("Land_BagFence_Long_F", (-15.5, -3.2), (3, 4))] + ([("Land_BagFence_Short_F", (-13.8, -0.5), (4,)), ("Land_PortableLight_double_F", (-12.5, 0.0), (4,))])
    for cls, (x, y), tiers in drop:
        if tier in tiers:
            items = [it for it in items if not (it[1] == cls and math.dist([float(v) for v in it[2].strip("[]").split(",")][:2], (O[0] + x, O[1] + y)) < 0.6)]
    for kind, what, x, y, fx, fy, inside, tiers in POSTS:
        if tier not in tiers:
            continue
        w = (O[0] + x, O[1] + y)
        z = O[2] + H if inside else b.ground(*w)   # the nave's floor (the chapel's base + OTBPOS's height)
        if kind == "object":
            items.append(["object", what, f"[{w[0]:.3f},{w[1]:.3f},{z:.3f}]", f"[[{fx:.4f},{fy:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,hand"])
        else:
            hdg = math.degrees(math.atan2(fx, fy)) % 360
            # The men in the nave are the chapel's reserve ("reserve:9", clear of garrison_gen's own groups); the
            # T4 door's north post joins them
            res = inside or (tier == 4 and (x, y) == (-8.6, 4.4))
            items.append(["guard", what, f"[{w[0]:.3f},{w[1]:.3f},{z:.3f}]", f"{hdg:.1f}", ("garrison,hand" if inside else "garrison,ground,hand") + (",reserve,reserve:9" if res else "")])
    items = [it for it in items if 'user' not in it[4].split(',')
             and not (tier == 3 and it[1] == "Land_BagFence_Short_F" and it[4] == "post" and it[2].startswith("[27007.850,23272.97"))]
    items += [list(it) for it in USER[tier]]
    t['tiers'][tier] = items
    print(f"T{tier}: {sum(1 for p in POSTS if p[0] == 'guard' and tier in p[7])} men and {sum(1 for p in POSTS if p[0] == 'object' and tier in p[7])} sandbags round and in the chapel")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
