"""Batch 4 draft areas (T3 only): polygons in each town's own metres from the office (east, north), from area_gen.py's
growth (the block round the HQ, nearest first) set on building faces and road verges (half the road's width + 1.2 m),
checked on the block probe's top-down shot. python areas.py [--write] [--png] [Town ...]"""
import sys, math
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib as bl, merge_compounds as mc
CLEAR = 1.2
VARIANT = {}   # a "<town> (B)" entry -> the town whose block it's drawn in
SPEC = {
    # Lakka: the open yard round the HQ, the track's verge as the south wall, the small house west and the stone house
    # north-east as corners of the wall, the shed north of the yard on the north line
    'Lakka': {3: [(-6.6, 29.4), (8.5, 29.5), (20.1, 29.4), (19.9, 9.0), (28.8, 4.4), (27.8, -8.6), (22.2, -17.6),
                  (-9.2, -12.1), (-26.2, -12.6), (-29.6, 7.0), (-19.3, 19.8), (-12.4, 21.4)]},
    # Alikampos: the block north-west of the junction: the east track's verge as the east wall (the HQ on it), the
    # south track's verge as the south wall, the houses and sheds west and north as the corners
    'Alikampos': {3: [(-32.9, 10.1), (-32.9, 6.1), (-38.9, 6.1), (-38.1, -13.5), (-18.0, -8.3), (7.8, -10.4),
                      (6.0, 40.1), (-8.9, 40.1), (-19.9, 36.1), (-21.9, 28.1), (-29.9, 28.1), (-33.9, 23.1)]},
    # Kore: west of the north-south track only (the old ring stood across it): its verge as the east wall, the HQ and
    # the shop north of it on the line; the yards west and south-west down the slope (about 5 m)
    'Kore': {3: [(-9.8, 29.7), (-19.8, 26.7), (-27.8, 17.7), (-32.8, 3.7), (-31.8, -11.3), (-18.8, -27.3),
                 (0.2, -34.3), (7.9, -31.3), (4.7, 29.6)]},
    # Telos: the HQ's block south-west of the junction: the north track's verge as the north wall (the HQ's corner on
    # it), the house north-west, the half-built shell west, the stone house south on the line
    'Telos': {3: [(10.1, 0.9), (-14.4, 16.1), (-18.9, 16.9), (-24.9, 5.9), (-33.9, 5.9), (-33.9, -7.1), (-29.4, -15.3),
                  (-1.5, -33.5), (6.1, -34.1), (19.1, -29.1), (27.1, -21.1), (26.3, -15.6), (20.5, -6.8)]},
    # Dorida: the HQ's block between the north-east and south-east tracks: their verges as walls, the row of houses
    # north-west as the far side
    'Dorida': {3: [(-42.3, 6.6), (-34.3, -10.4), (-31.3, -10.4), (-26.3, -18.4), (-25.3, -25.4), (-17.3, -31.4),
                   (-9.8, -29.7), (17.4, -10.0), (17.0, -5.1), (-0.3, 13.6), (-15.6, 32.8), (-20.3, 33.6),
                   (-27.3, 28.6), (-27.3, 17.6)]},
    # Selakano: west of the north-south track: its verge as the east wall (the HQ on it), the open ground west and the
    # stone shed and outhouse north
    'Selakano': {3: [(6.9, 0.0), (8.1, 7.0), (14.4, 22.1), (14.9, 27.0), (8.1, 30.0), (-5.9, 30.0), (-8.9, 26.0),
                     (-19.9, 24.0), (-25.9, 17.0), (-30.9, 3.0), (-29.9, -8.0), (-23.9, -20.0), (-7.9, -30.0),
                     (11.5, -28.2)]},
}
# The main gate proposed (local metres), on the edge facing the way in
GATE = {('Lakka', 3): (-5.6, -12.8), ('Alikampos', 3): (6.8, 17.5), ('Kore', 3): (5.2, 20.0),
        ('Telos', 3): (15.6, -3.2), ('Dorida', 3): (3.5, -20.1), ('Selakano', 3): (9.0, -13.0)}


def block(town):
    return bl.load()[VARIANT.get(town, town)]


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


def polys(town):
    b = block(town)
    return b, {k: [[round(b.pos[0] + x, 2), round(b.pos[1] + y, 2)] for x, y in p] for k, p in SPEC[town].items()}


def gate(town, tier):
    b = block(town); x, y = GATE[(town, tier)]
    return [round(b.pos[0] + x, 2), round(b.pos[1] + y, 2)]


if __name__ == '__main__':
    towns = [a for a in sys.argv[1:] if not a.startswith('--')] or list(SPEC)
    saved = mc.load_saved('Altis')
    for town in towns:
        b, P = polys(town)
        for k, p in P.items():
            c, at = road_clear(b, p)
            hs = [b.ground(*v) for v in p]
            print(f"{town} T{k}: {round(area(p))} m2, {len(p)} corners, road clearance {c:.1f} m"
                  + (f" at {[round(at[0] - b.pos[0], 1), round(at[1] - b.pos[1], 1)]}" if c < CLEAR else "")
                  + f", corners' ground {min(hs):.1f}-{max(hs):.1f} (HQ {b.ground(*b.pos[:2]):.1f})")
        saved.setdefault(town, {'tiers': {}})['tiers'].update(P)
        if '--png' in sys.argv:
            import overlay
            cols = {3: (255, 40, 40), 4: (40, 90, 255)}
            marks = [((40, 230, 40), gate(town, k), f"gate T{k}") for k in P]
            title = f"{town}: " + ", ".join(f"T{k} {round(area(p))} m2" for k, p in P.items()) + " (T3 red, T4 blue, gates green)"
            name = town.replace(' ', '_').replace('(', '').replace(')', '')
            print(overlay.draw(VARIANT.get(town, town), polys=[(cols[k], p) for k, p in P.items()], marks=marks,
                               out=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'compounds',
                                                f"{name}_areas_on_game.jpg"), crop=72, title=title))
    if '--write' in sys.argv:
        mc.write_saved('Altis', saved); mc.write_sqf('Altis', saved); print('written')
