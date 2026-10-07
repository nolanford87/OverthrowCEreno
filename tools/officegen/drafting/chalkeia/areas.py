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
