"""
Drafts the mayor's office layouts of the 2-tier hamlets whose office is a House_Big_02 or a Stone_HouseBig
(tools/officegen/townlib.py has the API). Run from the repository root:
    python tools/officegen/drafting/hamlets.py [town ...]     (all of the group without names; -m prints the maps)

T1: the template's tier 1, outside things moved off anything they clash with.
T2: a sandbag nest beside the main door (the door's own path left clear) with a rifleman and an autorifleman
behind it, a rifleman upstairs over the front door, and the narrowest side gap beside the house closed.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

BIG02 = ["Abdera", "Agios Konstantinos", "Galati", "Nifi", "Topolia"]
STONE = ["Agia Triada", "Agios Petros", "Anthrakia", "Athanos", "Delfinaki", "Ekali", "Feres", "Frini", "Ifestiona",
         "Ioannina", "Kalithea", "Katalaki", "Koroni", "Negades", "Oreokastro", "Orino", "Panagia", "Syrta"]

# The houses' real walls in model coordinates (the probed bounding boxes run well past them): xmin, ymin, xmax, ymax
EXTENT = {
    "i_House_Big_02_V1_F": (-5.4, -6.9, 5.4, 7.5),
    "i_Stone_HouseBig_V1_F": (-2.6, -2.6, 7.0, 6.6),  # x 7: the outside stair up to the landing on the east
}


def size_of(kind, what):
    if kind == "object":
        return tl.CLASSES.get(what, (0.6, 0.6))
    return (2.0, 2.0) if kind == "static" else (0.5, 0.5)


class Drafter:
    def __init__(self, t):
        self.t = t
        self.placed = []  # (x, y, radius) of the outside things so far

    def world_yaw(self, mdir):
        return (self.t.dir + mdir) % 360

    def free(self, kind, what, x, y, mdir, road_ok=False, trees=True):
        """Whether a ground footprint is clear: the check()'s rules, plus trees, roads and what's placed already."""
        t = self.t
        if math.hypot(x, y) > 44:
            return False
        ln, dp = size_of(kind, what)
        w = t.to_world(x, y, 0)
        for h in t.hits(w[0], w[1], ln, dp, self.world_yaw(mdir), 0.2):
            if h[0] in ("building", "part", "rock") or (h[0] == "tree" and trees) or (h[0] == "wall" and kind != "object"):
                return False
        if t.on_office(x, y, ln, dp, mdir):
            return False
        if not road_ok and t.on_road(w[0], w[1]):
            return False
        r = max(ln, dp) / 2
        return all(math.hypot(x - px, y - py) >= (r + pr) * 0.8 for px, py, pr in self.placed)

    def take(self, x, y, kind, what):
        ln, dp = size_of(kind, what)
        self.placed.append((x, y, max(ln, dp) / 2))


def door_frame(t):
    d = t.door("main")
    (x, y, _), m = d["model"], d["mdir"]
    f = (math.sin(math.radians(m)), math.cos(math.radians(m)))
    lat = (math.sin(math.radians(m + 90)), math.cos(math.radians(m + 90)))
    return (x, y), m, f, lat, d["width"]


def at(origin, f, lat, a, b):
    return (origin[0] + f[0] * a + lat[0] * b, origin[1] + f[1] * a + lat[1] * b)


def tier1(t, dr):
    """The template's tier 1, the outside things (the flag) moved to the nearest clear spot when they clash."""
    out = []
    for kind, what, p, d, extra in tl.template(t.key)[0]:
        if kind == "doorway":
            continue
        if "outside" not in extra:
            out.append(tl.guard(t, what, p[0], p[1], p[2], d) if kind == "guard" else tl.obj(t, what, p[0], p[1], p[2], d, flag="flag" in extra))
            continue
        spot = None
        if dr.free(kind, what, p[0], p[1], d):
            spot = (p[0], p[1])
        else:  # The clear spot nearest the main door within 14 m of the template's
            door = t.door("main")["model"]
            cands = [(p[0] + i * 0.5, p[1] + j * 0.5) for i in range(-28, 29) for j in range(-28, 29) if math.hypot(i, j) <= 28]
            cands.sort(key=lambda c: math.hypot(c[0] - door[0], c[1] - door[1]) + 0.5 * math.hypot(c[0] - p[0], c[1] - p[1]))
            spot = next((c for c in cands if math.hypot(c[0] - door[0], c[1] - door[1]) > 2.5 and dr.free(kind, what, c[0], c[1], d)), None)
        assert spot, (t.name, what)
        dr.take(spot[0], spot[1], kind, what)
        out.append(tl.guard(t, what, spot[0], spot[1], None, d) if kind == "guard" else tl.obj(t, what, spot[0], spot[1], None, d, flag="flag" in extra))
    return out


def nest(t, dr):
    """A sandbag nest beside the main door, facing out, its two guards behind it; the door's own path stays clear."""
    o, m, f, lat, width = door_frame(t)
    flag = [it for it in tl.template(t.key)[0] if it[1] == "Flag_NATO_F"][0][2]
    flag_side = 1 if (flag[0] - o[0]) * lat[0] + (flag[1] - o[1]) * lat[1] > 0 else -1
    b0 = width / 2 + 1.45 + 0.7  # The long bag's inner end 0.7 m off the doorway's edge
    for side in (-flag_side, flag_side):
        for a in (3.2, 4.0, 4.8, 2.6):
            for b in (b0, b0 + 1.0, b0 + 2.0):
                b *= side
                parts = [
                    ("object", "Land_BagFence_Long_F", at(o, f, lat, a, b), m),
                    ("object", "Land_BagFence_Short_F", at(o, f, lat, a - 0.85, b + side * 1.75), (m + 90) % 360),
                    ("guard", "rifleman", at(o, f, lat, a - 1.2, b - side * 0.6), m),
                    ("guard", "autorifleman", at(o, f, lat, a - 1.2, b + side * 0.6), m),
                ]
                if all(dr.free(k, w, p[0], p[1], d) for k, w, p, d in parts):
                    out = []
                    for k, w, p, d in parts:
                        dr.take(p[0], p[1], k, w)
                        out.append(tl.obj(t, w, p[0], p[1], None, d) if k == "object" else tl.guard(t, w, p[0], p[1], None, d))
                    lx, ly = lat[0] * side, lat[1] * side
                    where = ("model +x" if lx > 0.7 else "model -x" if lx < -0.7 else "model +y" if ly > 0 else "model -y")
                    return out, f"nest {abs(b):.1f} m to the {where} side of the door, {a:.1f} m out"
    # No room by the door (a road or rock right there): the two guards at its flanks against the wall, or else
    # just inside it on the ground floor
    out = []
    for side, role in ((-1, "rifleman"), (1, "autorifleman")):
        for a in (1.0, 1.5, 2.0, 2.5):
            p = at(o, f, lat, a, side * (width / 2 + 1.0))
            if dr.free("guard", role, p[0], p[1], m):
                dr.take(p[0], p[1], "guard", role)
                out.append(tl.guard(t, role, p[0], p[1], None, m))
                break
    if len(out) == 2:
        return out, "NO ROOM for a nest by the door (road/rock), the pair stands bare at the door's flanks"
    out = []
    for side, role in ((-1, "rifleman"), (1, "autorifleman")):
        p = at(o, f, lat, -1.2, side * 0.6)
        out.append(tl.guard(t, role, p[0], p[1], t.floors[0], m))
    return out, "NO ROOM outside the door (rock), the pair holds just inside it"


def gap(t, dr, ext, front):
    """The narrower of the side gaps beside the house (flanks of the front), closed with a gate and bags."""
    xmin, ymin, xmax, ymax = ext
    best = None
    # Each flank: (the wall's coordinate, outward sign, the axis across the gap, samples along the wall, where the fence goes)
    if front in (180, 0):  # Front faces -y (or +y): the flanks are west and east, the passages run along y
        fy = ymin + 0.4 if front == 180 else ymax - 0.4
        flanks = [("x", xmin, -1, (ymin + 1.5, ymax - 1.5), fy), ("x", xmax, 1, (ymin + 1.5, ymax - 1.5), fy)]
    else:  # Front faces -x or +x: the flanks are south and north
        fx = xmin + 0.4 if front == 270 else xmax - 0.4
        flanks = [("y", ymin, -1, (xmin + 1.5, xmax - 1.5), fx), ("y", ymax, 1, (xmin + 1.5, xmax - 1.5), fx)]
    for axis, edge, sgn, samples, along in flanks:
        ds = []
        for s in samples + (along,):
            d = None
            for k in range(1, 25):
                off = k * 0.25
                x, y = (edge + sgn * off, s) if axis == "x" else (s, edge + sgn * off)
                w = t.to_world(x, y, 0)
                if any(h[0] in ("building", "part", "wall", "rock") for h in t.hits(w[0], w[1], 0.3, 0.3, 0, 0)):
                    d = off
                    break
            ds.append(d)
        if all(d is not None and 1.2 <= d <= 5.5 for d in ds):
            if best is None or ds[-1] < best[0]:
                best = (ds[-1], axis, edge, sgn, along)
    if best is None:
        return [], "no narrow side gap"
    d, axis, edge, sgn, along = best
    span = d - 0.3
    pieces = []
    left = span
    for cls, ln in (("Land_PipeFence_03_m_gate_r_F", 4.0), ("Land_BagFence_Long_F", 2.9), ("Land_BagFence_Short_F", 1.5), ("Land_BagFence_Short_F", 1.5), ("Land_BagFence_End_F", 0.6)):
        if ln <= left + 0.1:
            pieces.append((cls, ln))
            left -= ln
    out = []
    pos = 0.15
    for cls, ln in pieces:
        c = edge + sgn * (pos + ln / 2)
        x, y = (c, along) if axis == "x" else (along, c)
        mdir = 0 if axis == "x" else 90  # The piece's length across the gap
        if dr.free("object", cls, x, y, mdir, trees=False):
            dr.take(x, y, "object", cls)
            out.append(tl.obj(t, cls, x, y, None, mdir))
        pos += ln
    side = {("x", -1): "west", ("x", 1): "east", ("y", -1): "south", ("y", 1): "north"}[(axis, sgn)]
    return out, f"{side} side gap ({d:.1f} m) closed with {len(out)} pieces"


def upstairs(t, front):
    """A rifleman on the upper floor over the front door."""
    if t.key == "i_Stone_HouseBig_V1_F":
        return tl.guard(t, "rifleman", 2.3, -0.8, t.floors[1], 180)  # By the window over the door
    return tl.guard(t, "rifleman", -3.8, -4.6, t.floors[1], 270)  # The balcony over the front door's recess


def draft(t):
    dr = Drafter(t)
    t1 = tier1(t, dr)
    front = round(t.door("main")["mdir"]) % 360
    n, nnote = nest(t, dr)
    g, gnote = gap(t, dr, EXTENT[t.key], front)
    t2 = t1 + n + [upstairs(t, front)] + g
    return [t1, t2], f"{nnote}; {gnote}"


def main(args):
    maps = "-m" in args
    names = [a for a in args if a != "-m"] or BIG02 + STONE
    towns = tl.load()
    for name in names:
        t = towns[name]
        tiers, note = draft(t)
        problems = tl.check(t, tiers)
        if problems:
            print(f"{name}: PROBLEMS {problems}")
            continue
        tl.write(t, tiers)
        counts = " / ".join(f"T{i}: {len(it)} items, {sum(1 for x in it if x[0] == 'guard')} guards" for i, it in enumerate(tiers, 1))
        print(f"{name} ({t.cls}{', spawned' if t.spawned else ''}): {counts}; {note}")
        if maps:
            print(tl.ascii_map(t, tiers[-1], r=24, step=1))


if __name__ == "__main__":
    main(sys.argv[1:])
