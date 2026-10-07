import sys, os, copy, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hmap, blocklib as bl, merge_layouts as ml, merge_compounds as mc
b = bl.load()['Chalkeia']
t = ml.load_saved('Altis')['Chalkeia']
areas = mc.load_saved('Altis')['Chalkeia']['tiers']
AB = {"marksman": "MK", "autorifleman": "AR", "rifleman": "R", "at": "AT"}
for k in (3, 4):
    items = t['tiers'][k]
    marks = {}
    for i, it in enumerate(items):
        if it[0] in ('guard', 'static', 'vehicle'):
            p = [float(v) for v in it[2].strip('[]').split(',')]
            lab = AB.get(it[1], it[1].upper()) + ("-patrol" if "patrol" in it[4] else "") + ("^" if it[0] == 'guard' and p[2] - b.ground(*p[:2]) > 1.5 else "")
            marks[lab + ' ' * i] = p
    out = f'P:/OT_chalkeia/tools/officegen/compounds/Chalkeia_T{k}_opus.svg'
    hmap.make('Chalkeia', out, polygons={f'T{k}': areas[k]}, reach=58, scale=9, pieces=items, marks=marks)
    print(out)
