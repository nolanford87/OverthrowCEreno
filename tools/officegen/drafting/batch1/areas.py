"""Batch 1 draft areas: road-framed rectangles (along the town's street, across it), clipped clear of every road
(half its width + 1.2 m). python draft.py [--write] [Town ...]"""
import sys, math
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib as bl, merge_compounds as mc
from frame import frame
CLEAR = 1.2
# town: (street heading, {tier: [(along, across), ...] polygon in the frame})
SPEC = {
    'Neochori': (67, {3: [(-35, 3.9), (21, 3.9), (21, -28.5), (-35, -28.5)],
                      4: [(-46, 3.9), (22, 3.9), (22, -38.5), (-46, -38.5)]}),
    'Kalochori': (50, {3: [(-34, 14.4), (22, 14.8), (22, -13), (14, -21), (8, -24.5), (-34, -24.5)],
                       4: [(-44, 13.0), (35, 14.6), (35, -2), (26, -16), (17, -20), (8, -25.5), (-5, -36), (-44, -40)]}),
    'Sofia': (45, {3: [(-38, -4.8), (10.2, -4.8), (10.2, 24), (3.5, 31.5), (-38, 31.5)],
                   4: [(-55, -4.8), (10.2, -4.8), (10.2, 24), (2, 33), (-16, 41), (-55, 41)]}),
    'Therisa': (40, {3: [(-20, -21.2), (15, -21.2), (15, 30.3), (-20, 30.3)],
                     4: [(-29, -21.2), (28, -21.2), (28, 29.3), (-29, 29.3)]}),
}
def area(p):
    return abs(sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))) / 2
def segd(p, a, z):
    dx, dy = z[0] - a[0], z[1] - a[1]; l = dx * dx + dy * dy or 1e-9
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / l))
    return math.dist(p, (a[0] + t * dx, a[1] + t * dy))
def road_clear(b, poly):
    """The smallest clearance (m) from the area (edges sampled every 0.5 m) to a road's edge, and where."""
    worst = (99, None)
    n = len(poly)
    for i in range(n):
        a, z = poly[i], poly[(i + 1) % n]
        L = math.dist(a, z); k = max(1, int(L / 0.5))
        for j in range(k + 1):
            p = (a[0] + (z[0] - a[0]) * j / k, a[1] + (z[1] - a[1]) * j / k)
            for r in b.roads:
                c = segd(p, r['beg'][:2], r['end'][:2]) - r['width'] / 2
                if c < worst[0]:
                    worst = (c, p)
    return worst
# The main gate proposed (frame), on the street side next to the HQ (T3 and T4 share it)
GATE = {'Neochori': (14, 3.9), 'Kalochori': (-14, 14.6), 'Sofia': (-15, -4.8), 'Therisa': (0, -21.2)}
def gate(town):
    b = bl.load()[town]; return frame(b, SPEC[town][0])[1](*GATE[town])
# Half-planes in the town's own metres from the office (east, north): keep a*x + b*y >= c
CLIP = {('Kalochori', 3): [(0, 1, -24.0)], ('Kalochori', 4): [(0, 1, -33.0)]}  # T3 north of the lane south of the block, T4 over it
def clip(poly, a, b, c):
    out = []
    n = len(poly)
    f = lambda p: a * p[0] + b * p[1] - c
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        if f(p) >= 0: out.append(p)
        if (f(p) >= 0) != (f(q) >= 0):
            t = f(p) / (f(p) - f(q)); out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return out
def polys(town):
    b = bl.load()[town]; th, tiers = SPEC[town]
    to, back = frame(b, th)
    out = {}
    for k, p in tiers.items():
        w = [back(*q) for q in p]
        loc = [(x - b.pos[0], y - b.pos[1]) for x, y in w]
        for h in CLIP.get((town, k), []):
            loc = clip(loc, *h)
        out[k] = [[round(b.pos[0] + x, 2), round(b.pos[1] + y, 2)] for x, y in loc]
    return b, out
if __name__ == '__main__':
    towns = [a for a in sys.argv[1:] if not a.startswith('--')] or list(SPEC)
    saved = mc.load_saved('Altis')
    for town in towns:
        b, P = polys(town)
        for k, p in P.items():
            c, at = road_clear(b, p)
            to, _ = frame(b, SPEC[town][0])
            print(f"{town} T{k}: {round(area(p))} m2, {len(p)} corners, road clearance {c:.1f} m" + (f" at frame {[round(v, 1) for v in to(at)]}" if c < CLEAR else ""))
        saved.setdefault(town, {'tiers': {}})['tiers'].update(P)
    if '--write' in sys.argv:
        mc.write_saved('Altis', saved); mc.write_sqf('Altis', saved); print('written')
