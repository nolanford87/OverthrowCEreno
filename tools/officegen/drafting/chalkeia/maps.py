import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hmap, merge_layouts as ml, merge_compounds as mc
t = ml.load_saved('Altis')['Chalkeia']
areas = mc.load_saved('Altis')['Chalkeia']['tiers']
tag = sys.argv[1] if len(sys.argv) > 1 else 'walls'
for k in (3, 4):
    out = f'P:/OT_chalkeia/tools/officegen/compounds/Chalkeia_T{k}_{tag}.svg'
    hmap.make('Chalkeia', out, polygons={f'T{k}': areas[k]}, reach=58, scale=9, pieces=t['tiers'][k])
    print(out)
