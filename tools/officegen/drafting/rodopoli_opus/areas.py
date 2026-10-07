"""Opus's hand-designed Rodopoli T3/T4 areas (local metres from the office, then world)."""
import math
import os
import sys

sys.path.insert(0, "P:/OT_rodo_opus/tools/officegen")
import blocklib  # noqa
import merge_compounds  # noqa

b = blocklib.load()["Rodopoli"]
O = b.pos[:2]
HERE = os.path.dirname(os.path.abspath(__file__))


def L(p):
    return (p[0] - O[0], p[1] - O[1])


def W(p):
    return [round(O[0] + p[0], 2), round(O[1] + p[1], 2)]


def norm(v):
    l = math.hypot(*v)
    return (v[0] / l, v[1] / l)


def offset_line(a, z, d, toward):
    """The line parallel to road a-z, d metres off its centre on the side of point toward: (point, dir)."""
    u = norm((z[0] - a[0], z[1] - a[1]))
    n = (-u[1], u[0])
    if (toward[0] - a[0]) * n[0] + (toward[1] - a[1]) * n[1] < 0:
        n = (u[1], -u[0])
    return ((a[0] + n[0] * d, a[1] + n[1] * d), u)


def meet(l1, l2):
    (p, u), (q, v) = l1, l2
    den = u[0] * v[1] - u[1] * v[0]
    t = ((q[0] - p[0]) * v[1] - (q[1] - p[1]) * v[0]) / den
    return (p[0] + u[0] * t, p[1] + u[1] * t)


def area(p):
    return abs(sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))) / 2


IN = (0.0, 0.0)  # The office: inside
N1 = ((-37.7, -1.8), (-16.2, 15.5))
N3 = ((-7.2, 21.4), (16.2, 35.8))
E2 = ((15.9, 25.2), (27.1, 7.9))
W2 = ((-33.2, -11.0), (-13.0, -38.5))
W3 = ((-13.0, -38.5), (7.5, -68.5))


def west_line():
    """The west wall's line (both tiers): from the corner at the junction (5 m off the road's middle) straight to
    the south wall, there 8.6 m off it: through the garage fronting the road past the bend (2 m inside its box:
    it is the wall)."""
    a = meet(offset_line(*W2, 5.0, IN), offset_line(*N1, 5.0, IN))
    z = meet(south4(), offset_line(*W3, 8.6, IN))
    return (a, norm((z[0] - a[0], z[1] - a[1])))


def south4():
    # The long yard wall south-east of house V3 (city2 walls at (43.5,-22.5) .. (8.9,-45.5)), on its line
    return offset_line((43.5, -22.5), (8.9, -45.5), 0.0, IN)


def shift(line, d):
    (p, u) = line
    n = (-u[1], u[0])
    if (IN[0] - p[0]) * n[0] + (IN[1] - p[1]) * n[1] < 0:
        n = (u[1], -u[0])
    return ((p[0] + n[0] * d, p[1] + n[1] * d), u)


def tier(off, south):
    n1 = offset_line(*N1, off, IN)
    n3 = offset_line(*N3, off, IN)
    # The east road: 6 m off its middle, through the houses fronting it (more than 2 m inside their boxes: they
    # are the wall)
    e6 = offset_line(*E2, 6.1 if south == 3 else 6.0, IN)
    w2 = offset_line(*W2, off, IN)
    pts = [meet(w2, n1), meet(n1, n3), meet(n3, e6)]
    face = offset_line((32.0, -2.3), (12.1, -15.9), 0.0, IN)   # House V2's NW face
    if south == 3:
        # The yard wall 1.2 m off house V2's NW face, into the compound
        s = shift(face, 1.2)
        pts += [meet(e6, s), meet(s, w2)]
    else:
        # Past the alley's mouth the terraced houses V2 and V3 are the wall: the line 9 m off the road's middle,
        # 2 m inside their ends (the step 1 m off V2's NW face, the wall turning to the house); the long yard wall south-east of V3; the
        # west road (the garage at its bend hidden)
        e9 = offset_line(*E2, 9.0, IN)
        step = shift(face, 1.0)
        s = south4()
        w3 = offset_line(*W3, off, IN)
        pts += [meet(e6, step), meet(step, e9), meet(e9, s), meet(s, w3), meet(w3, w2)]
    return pts


if __name__ == "__main__":
    t3 = tier(5.25, 3)
    t4 = tier(5.0, 4)
    for k, p in (("T3", t3), ("T4", t4)):
        print(k, round(area(p)), [tuple(round(v, 1) for v in q) for q in p])
    polys = {"T3": [W(p) for p in t3], "T4": [W(p) for p in t4]}
    blocklib.svg(b, os.path.join(HERE, "areas.svg"), polygons=polys, reach=70, scale=7)
    if "--write" in sys.argv:
        saved = merge_compounds.load_saved("Altis")
        t = saved.setdefault("Rodopoli", {"tiers": {}})
        t["tiers"][3] = polys["T3"]
        t["tiers"][4] = polys["T4"]
        merge_compounds.write_saved("Altis", saved)
        # The main gate: on the west wall at the alley's middle (between the office's SE face and the T3 south
        # wall's inside face), so its lane runs straight up the alley
        n = (0.5736, -0.8192)          # Across the alley (the office's SE face normal, dir 235)
        office_face = n[0] * 11.5 + n[1] * -1.6
        s3 = tier(5.25, 3)
        south_in = n[0] * s3[3][0] + n[1] * s3[3][1] - 0.88
        mid = (office_face + south_in) / 2
        lines = []
        for k, pts, w in ((3, s3, 4.0), (4, tier(5.0, 4), 4.1)):
            a, u = pts[0], norm((W2[1][0] - W2[0][0], W2[1][1] - W2[0][1]))   # The west wall from the junction corner
            t = (mid - (n[0] * a[0] + n[1] * a[1])) / (n[0] * u[0] + n[1] * u[1])
            if os.environ.get("GATE_K"):
                t = float(os.environ["GATE_K"])
            g = (a[0] + u[0] * t, a[1] + u[1] * t)
            print(f"T{k} gate at", [round(v, 1) for v in g])
            lines.append(f"OTGATE|Altis|Rodopoli|{k}|[{W(g)[0]:.2f},{W(g)[1]:.2f}]|{w}")
        open("P:/OT_rodo_opus/tools/officegen/compounds/Altis_gates.txt", "w", newline=chr(10)).write(chr(10).join(lines) + chr(10))
        print("wrote", merge_compounds.write_sqf("Altis", saved))
