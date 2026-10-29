"""Batch 3 draft areas: hand-drawn polygons in each town's own metres from the office (east, north), on building
faces, wall lines and road verges (half the road's width + 1.2 m), from the block probe and its top-down shot.
Agios Dionysios gets two variants for the user to pick in the compound editor: "Agios Dionysios" (A: the gate on the
west wall, onto the track 24 m away) and "Agios Dionysios (B)" (B: the gate on the north wall, onto the level ground
the track ends in). python areas.py [--write] [--png] [Town ...]"""
import sys, math
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib as bl, merge_compounds as mc
CLEAR = 1.2
VARIANT = {'Agios Dionysios (B)': 'Agios Dionysios'}   # editor entry -> the town whose block it's drawn in
SPEC = {
    # A: the compound spreads west to the track (the nearest way in, 24 m off) and south over the Unfinished
    # Building's walled yard; T4 adds the shed and container yard north, and the slope east to its break (+30 m)
    # with the fenced yard of the stone shed
    'Agios Dionysios': {3: [(-18.3, 14.6), (0.6, 19.6), (17.0, 19.0), (18.0, -14.0), (6.0, -18.5), (-2.6, -26.3),
                            (-0.2, -35.0), (-16.5, -40.6), (-21.9, -40.3), (-25.4, -27.0), (-22.3, -19.6),
                            (-21.3, -12.0), (-19.4, -2.0), (-18.3, 12.0)],
                        4: [(-18.3, 14.6), (-23.0, 34.5), (-25.2, 44.0), (-27.5, 49.5), (-8.5, 55.0), (10.0, 52.0),
                            (24.0, 40.0), (29.0, 18.0), (30.5, -4.0), (34.0, -5.7), (41.0, -9.0), (38.0, -24.0),
                            (33.6, -31.6), (23.0, -30.5), (14.0, -30.0), (-0.2, -35.0), (-16.5, -40.6),
                            (-21.9, -40.3), (-25.4, -27.0), (-22.3, -19.6), (-21.3, -12.0), (-19.4, -2.0),
                            (-18.3, 12.0)]},
    # B: the compound runs north along the level (the ground falls east, not north): T3 from the office up past the
    # shed's south-east corner, T4 over the shed and the container yard to the level ground beyond (the gate there),
    # east down the slope to +28 m and south over the Unfinished Building's yard like A
    'Agios Dionysios (B)': {3: [(-18.3, 14.6), (-17.6, 15.4), (0.6, 20.3), (-2.0, 36.0), (18.5, 38.0), (18.5, 0.0),
                                (17.5, -16.0), (2.0, -20.0), (-15.0, -18.5), (-21.3, -12.0), (-19.4, -2.0),
                                (-18.3, 12.0)],
                            4: [(-18.3, 14.6), (-23.0, 34.5), (-25.2, 44.0), (-28.5, 50.5), (-26.0, 62.0),
                                (13.0, 62.0), (24.0, 40.0), (28.5, 18.0), (30.0, -4.0), (28.0, -18.0),
                                (14.0, -26.0), (-0.2, -35.0), (-16.5, -40.6), (-21.9, -40.3), (-25.4, -27.0),
                                (-22.3, -19.6), (-21.3, -12.0), (-19.4, -2.0), (-18.3, 12.0)]},
    # Gravia: the office's block east of it: the house joined to it, the two ruins and the shed to the east, the
    # pair of shops/houses to the west as the west wall, the two closed houses south as the south wall, the plaza's
    # south side as the north wall
    'Gravia': {3: [(-5.6, 12.6), (-11.3, 5.6), (-21.4, -7.3), (-18.1, -9.9), (-13.3, -15.1), (-12.3, -16.0),
                   (-8.4, -31.9), (0.6, -29.6), (12.5, -35.0), (20.5, -30.3), (21.2, -22.4), (42.4, -10.7),
                   (36.6, 1.2), (30.5, 12.6), (23.7, 14.1), (16.0, 20.3), (12.2, 14.7), (0.5, 16.5)]},
    # Poliakko: the office's north face on the track's verge, the shops and houses east of its yard, the shop row
    # west of it to the main road's verge (their fronts as the wall), the gardens' stone walls behind as the south
    'Poliakko': {3: [(-15.0, 13.6), (-8.7, 10.0), (13.2, -0.3), (22.7, -5.6), (31.7, -10.1), (28.1, -17.2),
                     (31.0, -17.9), (27.1, -25.7), (22.0, -35.3), (15.7, -42.2), (4.8, -36.1), (3.9, -27.7),
                     (-3.5, -23.4), (-10.8, -19.0), (-16.8, -16.0), (-34.5, -7.5), (-31.5, 0.0), (-26.8, 11.0),
                     (-21.5, 16.0)]},
    # Stavros: the office and its neighbours east of the track (the west edge on its verge, the office's south-west
    # end on the line): the closed house south-east, the small houses east, the walled yard north and the two stone
    # houses beyond it as the north wall
    'Stavros': {3: [(-13.5, 11.5), (-14.5, 20.0), (-19.2, 24.3), (-14.4, 31.4), (-10.1, 38.2), (-5.4, 44.6),
                    (-3.2, 43.7), (6.7, 37.6), (6.2, 34.8), (18.6, 34.6), (18.3, 21.0), (26.9, 19.7),
                    (30.0, 16.5), (22.3, 3.3), (31.7, -2.1), (38.5, -10.6), (29.9, -23.2), (20.9, -17.0),
                    (12.7, -20.8), (10.5, -25.4), (-0.9, -11.0), (-12.6, 5.8)]},
}
# The main gate proposed (local metres), on the edge facing the way in
GATE = {('Agios Dionysios', 3): (-19.4, 2.0), ('Agios Dionysios', 4): (-19.4, 2.0),
        ('Agios Dionysios (B)', 3): (8.0, 37.0), ('Agios Dionysios (B)', 4): (-2.0, 62.0),
        ('Gravia', 3): (6.0, 15.6), ('Poliakko', 3): (-12.0, 11.9), ('Stavros', 3): (-12.9, 7.5)}


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
