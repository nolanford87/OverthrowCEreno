"""Chalkeia T3/T4 areas, hand-drawn (local metres from the office, east/north)."""
import math, os, sys
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib, merge_compounds
import hmap
b = blocklib.load()['Chalkeia']
O = b.pos[:2]
W = lambda p: [round(O[0] + p[0], 2), round(O[1] + p[1], 2)]
def norm(v):
    l = math.hypot(*v); return (v[0] / l, v[1] / l)
def offset(a, z, d, toward=(0, 0)):
    u = norm((z[0] - a[0], z[1] - a[1])); n = (-u[1], u[0])
    if (toward[0] - a[0]) * n[0] + (toward[1] - a[1]) * n[1] < 0: n = (u[1], -u[0])
    return ((a[0] + n[0] * d, a[1] + n[1] * d), u)
def meet(l1, l2):
    (p, u), (q, v) = l1, l2
    den = u[0] * v[1] - u[1] * v[0]
    t = ((q[0] - p[0]) * v[1] - (q[1] - p[1]) * v[0]) / den
    return (p[0] + u[0] * t, p[1] + u[1] * t)
def along(line, t):
    (p, u) = line; return (p[0] + u[0] * t, p[1] + u[1] * t)
def area(p):
    return abs(sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))) / 2
# The track past the HQ's south-east face (NE to SW)
T1 = ((31.8, 28.8), (19.0, 7.9)); T2 = ((19.0, 7.9), (6.2, -12.5)); T3s = ((6.2, -12.5), (-5.3, -29.4)); T4s = ((-5.3, -29.4), (-14.0, -39.1)); T5s = ((-14.0, -39.1), (-30.7, -52.4))
CORNERS = {}
def tier(k):
    off = 5.25 if k == 3 else 5.0
    tr = [offset(*s, off) for s in (T1, T2, T3s, T4s, T5s)]
    return tr
if __name__ == '__main__':
    pts = {3: eval(sys.argv[1]), 4: eval(sys.argv[2])} if len(sys.argv) > 2 else {}
    for k, p in pts.items():
        print(f"T{k}", round(area(p)), p)
    marks = {k: W(v) for k, v in {'GATE (main, on the track)': (12.0, 6.8), 'tower T3': (6.0, 24.0), 'tower T4 a': (8.0, 32.0), 'tower T4 b': (-33.0, -36.0)}.items()}
    hmap.make('Chalkeia', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'areas.svg'),
              polygons={f"T{k}": [W(q) for q in p] for k, p in pts.items()}, reach=65, scale=8, marks=marks)

# The areas (checkpoint 2): on the HQ's side of the track; T3's north-west edge off the big rock (through
# House_Small_01, the house and the rock its wall there), the ruin (holed walls) left outside it; T4 round the second rock, out to the west scarp
FINAL = {
    3: [(26.6, 30.2), (14.6, 10.7), (1.9, -9.5), (-9.2, -25.9), (-17.3, -35.0), (-27.5, -43.0), (-36.5, -32.5),
        (-14.9, -17.6), (-9.5, -3.8), (-11.7, 8.4), (-3.1, 21.0), (-1.5, 31.5), (16.5, 44.2)],
    4: [(27.5, 31.4), (14.8, 10.6), (2.1, -9.7), (-9.0, -26.1), (-17.1, -35.2), (-29.6, -45.2), (-39, -36), (-35.5, -8),
        (-35, 7), (-20.5, 10.5), (-17, 30), (0, 38.5), (18, 45)],
}
# The main gate on the track's edge where it bends, opening into the north-east yard
GATE = (16.4, 13.6)


def write():
    saved = merge_compounds.load_saved('Altis')
    t = saved.setdefault('Chalkeia', {'tiers': {}})
    for k, p in FINAL.items():
        t['tiers'][k] = [W(q) for q in p]
        print(f"T{k}: {round(area(p))} m2")
    merge_compounds.write_saved('Altis', saved)
    print('wrote', merge_compounds.write_sqf('Altis', saved))
    path = 'P:/OT_chalkeia/tools/officegen/compounds/Altis_gates.txt'
    lines = [l.rstrip('\n') for l in open(path, encoding='utf-8') if '|Chalkeia|' not in l] if os.path.exists(path) else []
    lines += [f"OTGATE|Altis|Chalkeia|{k}|[{W(GATE)[0]:.2f},{W(GATE)[1]:.2f}]|{w}" for k, w in ((3, 4.0), (4, 4.1))]
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
