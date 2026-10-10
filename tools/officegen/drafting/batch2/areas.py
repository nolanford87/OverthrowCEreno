"""Batch 2 draft areas: road-framed rectangles (along the town's street, across it), clipped clear of every road
(half its width + 1.2 m). python draft.py [--write] [Town ...]"""
import sys, math
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib as bl, merge_compounds as mc
from frame import frame
CLEAR = 1.2
# town: (street heading, {tier: [(along, across), ...] polygon in the frame})
# Each polygon in the town's own metres from the office (east, north: frame heading 90), from area_gen.py's growth
# (the block between the roads, nearest the HQ first) simplified, and checked clear of the roads
SPEC = {
    # Panochori: the block north-east of the HQ inside the loop road (the HQ at its south-west corner, on the road)
    'Panochori': (90, {3: [(-16.4, 8.1), (-15.6, 25.1), (-6, 30), (12, 37), (24, 29.1), (23, 19.1), (29.6, 7.1),
                           (29.6, 0.1), (24.6, -2.9), (24.6, -25.9), (6.6, -23.9), (2.6, -7.9), (-5.4, -2.9)],
                       4: [(-15.4, 4.1), (-18.4, 20.1), (-6.4, 45.1), (7.6, 45.1), (12.6, 43.1), (17.6, 33.1),
                           (31.6, 35.1), (38.6, 29.1), (44.6, 14.1), (44.6, -0.9), (50.6, -5.9), (51.6, -12.9),
                           (45.6, -17.9), (22.6, -39.9), (8.6, -44.9), (1.5, -44.9), (6.5, -17.9), (2.6, -7.9), (-5.4, -2.9)]}),
    # Charkia: the wedge between the two tracks meeting south-east of the HQ (T3), on north-west along it and past the
    # north-east track's end into the walled yards (T4)
    'Charkia': (90, {3: [(17.4, 0.3), (12.4, -13.7), (2.4, -22.7), (-0.5, -20.5), (-16, -3.5), (-37.6, 11.3),
                         (-37.6, 17.3), (-29.6, 28.3), (-24.6, 28.3), (-20.6, 35.3), (-15.6, 35.3), (-14.6, 29.3)],
                     4: [(17.4, 0.3), (12.4, -13.7), (2.4, -22.7), (-0.5, -20.5), (-16, -3.5), (-55, 26.5),
                         (-55, 40), (-45, 55), (-5, 55), (-4, 43), (-17, 37), (-14.6, 29.3)]}),
    # Neri (cap 3, a small town: T3 only): the block the HQ stands in, inside the ring of tracks
    'Neri': (90, {3: [(2.1, -21.4), (25.1, -21.4), (27.1, 6.6), (26.1, 21.6), (23.1, 30.6), (7, 23.5),
                      (-25.9, -3.4), (-23.9, -14.4), (-14.9, -23.4)]}),
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
GATE = {}
def gate(town):
    b = bl.load()[town]; return frame(b, SPEC[town][0])[1](*GATE[town])
# Half-planes in the town's own metres from the office (east, north): keep a*x + b*y >= c
CLIP = {}
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
