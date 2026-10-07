import sys
sys.path.insert(0, 'P:/OT_rodo_opus/tools/officegen')
import copy, math
import merge_layouts as ml, blocklib as bl, merge_compounds as mc
b = bl.load()['Rodopoli']
t = ml.load_saved('Altis')['Rodopoli']
areas = mc.load_saved('Altis')['Rodopoli']['tiers']
AB = {"marksman": "MK", "autorifleman": "AR", "rifleman": "R", "at": "AT"}
for tier in (3, 4):
    items = t['tiers'][tier]
    hid = [[float(v) for v in it[2].strip('[]').split(',')][:2] for it in items if it[0] == 'hide']
    bb = copy.copy(b)
    bb.buildings = [x for x in b.buildings if all(math.dist(x.pos[:2], h) > 0.5 for h in hid)]
    bb.walls = [x for x in b.walls if all(math.dist(x.pos[:2], h) > 0.5 for h in hid)]
    marks = {}
    for i, it in enumerate(items):
        if it[0] in ('guard', 'static', 'vehicle'):
            p = [float(v) for v in it[2].strip('[]').split(',')]
            lab = AB.get(it[1], it[1].upper()) + ("-patrol" if "patrol" in it[4] else "") + ("^" if it[0] == 'guard' and p[2] - b.ground(*p[:2]) > 1.5 else "")
            marks[f"{lab}#{i}"] = p
    marks = {k.split('#')[0] + ' ' * n: v for n, (k, v) in enumerate(marks.items())}
    out = f"P:/OT_rodo_opus/tools/officegen/compounds/Rodopoli_T{tier}_opus.svg"
    bl.svg(bb, out, polygons={f"T{tier}": areas[tier]}, reach=58, scale=8, pieces=items, marks=marks)
    print(out)
