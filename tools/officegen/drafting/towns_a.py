"""
Draft mayor's office layouts, group towns_a (Overthrow CE): the House_Big_01 towns (4 tiers, after the hand-made
Aggelochori) and the House_Big_02 towns (3 tiers). Run from the repository root:
    python tools/officegen/drafting/towns_a.py [--map]
Writes tools/officegen/layouts/drafts/<town>.txt for each town (tl.write checks them first).
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

BIG01 = ["Agios Dionysios", "Chalkeia", "Charkia", "Kalochori", "Molos"]
BIG02 = ["Alikampos", "Dorida", "Gravia"]

WALL, GATE, ROUND = "Land_Mil_WallBig_4m_F", "Land_WallCity_01_gate_grey_F", "Land_BagFence_Round_F"

# Per town tuning: the yard rectangle (model x0, x1, y0, y1), the side for the tier 3 wall run (None: the most
# open one), wall pieces to leave out by (side, index), and extra notes.
TUNE = {
    "Agios Dionysios": {"rect": (-12, 10, -14, 11)},
    "Chalkeia": {"rect": (-10, 10, -14, 11)},
    "Charkia": {"rect": (-12, 10, -14, 11)},
    "Kalochori": {"rect": (-12, 10, -14, 11)},
    "Molos": {"rect": (-9.5, 10, -14, 11), "nest_door": "side", "gates": {"right": 5.6}},
    "Alikampos": {"rect": (-11, 9, -10, 10), "nest_door": "side"},
    "Dorida": {"rect": (-11, 9, -10, 10), "nest_door": "side"},
    "Gravia": {"rect": (-11, 9, -10, 10)},
}


def size(it):
    kind, what = it[0], it[1]
    if kind == "object":
        return tl.CLASSES[what]
    return (1.4, 1.4) if kind == "static" else (0.6, 0.6)


def yaw(it):
    o = it[3]
    return (o if it[0] == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360


def corners(t, it):
    """An item's footprint corners in model coordinates."""
    m = t.to_model(it[2])
    L, D = size(it)
    d = (yaw(it) - t.dir) % 360
    cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
    return [(m[0] + sx * L / 2 * cx[0] + sy * D / 2 * cy[0], m[1] + sx * L / 2 * cx[1] + sy * D / 2 * cy[1]) for sx in (-1, 1) for sy in (-1, 1)]


def overlap(t, a, b, tol=0.15):
    """Separating-axis overlap of two items' footprints (model xy), same height band only."""
    za, zb = t.to_model(a[2])[2], t.to_model(b[2])[2]
    ga, gb = "ground" in a[4], "ground" in b[4]
    if not (ga and gb) and abs(za - zb) > 1.5:
        return False
    pa, pb = corners(t, a), corners(t, b)
    for poly in (pa, pb):
        for i in (0, 1, 3):
            j = {0: 1, 1: 3, 3: 2}[i]
            ex, ey = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
            nx, ny = -ey, ex
            a1 = [p[0] * nx + p[1] * ny for p in pa]
            b1 = [p[0] * nx + p[1] * ny for p in pb]
            if max(a1) < min(b1) + tol * math.hypot(nx, ny) or max(b1) < min(a1) + tol * math.hypot(nx, ny):
                return False
    return True


def on_road(t, wx, wy):
    """On a road's carriageway: within 4 m of its centre line (the probe gives every road and track 10 m, wider
    than Altis' tracks are)."""
    return any(d <= min(4.0, s["width"] / 2) for d, s in t.roads_near(wx, wy, 10))


def ok(t, it, placed, road_ok=False):
    """Whether an item can go here: check()'s rules for one item, no overlap with what's placed, off roads."""
    problems = tl.check(t, [[it, it, it]] + [[it, it, it]] * (t.cap - 1))
    problems = [p for p in problems if "guards" not in p and "tiers" not in p]
    if problems:
        return False
    if "ground" in it[4] and it[0] == "object" and not road_ok:
        w = it[2]
        if on_road(t, w[0], w[1]):
            return False
        for cx, cy in corners(t, it):
            p = t.to_world(cx, cy, 0)
            if on_road(t, p[0], p[1]):
                return False
    lane = getattr(t, "lane", None)
    if lane and "ground" in it[4] and (it[0] == "static" or (it[0] == "object" and not it[1].startswith("Land_BagFence") and it[1] not in (GATE, "Flag_NATO_F"))):
        dx, dy, ux, uy = lane
        for cx, cy in corners(t, it) + [tuple(t.to_model(it[2])[:2])]:
            along = (cx - dx) * ux + (cy - dy) * uy
            if 0 <= along <= 9 and abs((cx - dx) * uy - (cy - dy) * ux) <= 1.75:
                return False  # Keeps the way out of the door clear
    walls = (WALL, GATE)
    if it[0] == "object" and any(overlap(t, it, b) for b in placed if b[0] != "guard" and not (it[1] in walls and b[1] in walls)):
        return False
    if it[0] in ("guard", "static") and any(overlap(t, it, b) for b in placed):
        return False
    return True


class Builder:
    def __init__(self, t):
        self.t, self.tiers, self.cur, self.skipped = t, [], [], []

    @property
    def placed(self):
        return [it for tier in self.tiers for it in tier] + self.cur

    def add(self, it, road_ok=False, must=False, note=""):
        if ok(self.t, it, self.placed, road_ok):
            self.cur.append(it)
            return True
        if must:
            raise ValueError(f"{self.t.name}: can't place {it[0]} {it[1]} at {[round(v, 1) for v in self.t.to_model(it[2])]}")
        self.skipped.append(note or f"{it[1]} {[round(v, 1) for v in self.t.to_model(it[2])[:2]]}")
        return False

    def first(self, cands, road_ok=False, note=""):
        """The first candidate that fits; True when one did."""
        for c in cands:
            if ok(self.t, c, self.placed, road_ok):
                self.cur.append(c)
                return c
        self.skipped.append(note or (cands[0][1] if cands else "?"))
        return None

    def tier(self):
        self.tiers.append(self.cur)
        self.cur = []

    def snapshots(self):
        out, acc = [], []
        for tier in self.tiers:
            acc = acc + tier
            out.append(list(acc))
        return out


# ---- shared pieces

def nest_post(b, cx, cy, mdir, role, behind=1.2, z=None):
    """A static in round bags facing model direction mdir at (cx, cy); its crew is the game's."""
    t = b.t
    fx, fy = math.sin(math.radians(mdir)), math.cos(math.radians(mdir))
    bag = tl.obj(t, ROUND, cx + fx * behind, cy + fy * behind, z, (mdir + 180) % 360)
    st = tl.static(t, role, cx, cy, z, mdir)
    if ok(t, bag, b.placed) and ok(t, st, b.placed):
        b.cur += [bag, st]
        return True
    return False


def door_nest(b, door, roles=("rifleman", "autorifleman")):
    """The C nest out from a door (a long bag across, short bags back towards the house, the way in at its sides)
    with a pair behind the long bag; tried at a few distances and shifts until the bag and the pair fit."""
    t = b.t
    dx, dy = door["model"][0], door["model"][1]
    od = door["mdir"]
    ux, uy = math.sin(math.radians(od)), math.cos(math.radians(od))
    t.lane = (dx, dy, ux, uy)
    lx, ly = uy, -ux  # Lateral
    for k in (3.0, 3.6, 2.6, 4.2, 4.8):
        for s in (0.0, 1.0, -1.0, 2.0, -2.0, 3.0, -3.0):
            cx, cy = dx + ux * k + lx * s, dy + uy * k + ly * s
            long_ = tl.obj(t, "Land_BagFence_Long_F", cx, cy, None, od)
            pair = [tl.guard(t, r, cx - ux * 1.15 + lx * o, cy - uy * 1.15 + ly * o, None, od) for r, o in zip(roles, (0.6, -0.6))]
            if not ok(t, long_, b.placed) or not all(ok(t, g, b.placed) for g in pair):
                continue
            b.cur.append(long_)
            for o in (1.7, -1.7):
                b.add(tl.obj(t, "Land_BagFence_Short_F", cx - ux * 0.95 + lx * o, cy - uy * 0.95 + ly * o, None, (od + 90) % 360), note="nest end bag")
            b.cur += pair
            return (round(k, 1), s)
    raise ValueError(f"{t.name}: no room for the door nest")


def near(x, y, reach=4.0, step=0.75):
    """Points round (x, y), nearest first."""
    pts = [(x + i * step, y + j * step) for i in range(-int(reach / step), int(reach / step) + 1) for j in range(-int(reach / step), int(reach / step) + 1)]
    return sorted([p for p in pts if math.hypot(p[0] - x, p[1] - y) <= reach], key=lambda p: math.hypot(p[0] - x, p[1] - y))


def static_post(b, role, cands, note, reach=4.0, rect=None):
    """A static weapon post: at or near the first of [(x, y, mdir)] that has room (inside the yard rectangle)."""
    for x, y, d in cands:
        for px, py in near(x, y, reach):
            if rect and not (rect[0] + 1.8 <= px <= rect[1] - 1.8 and rect[2] + 1.8 <= py <= rect[3] - 1.8):
                continue
            if nest_post(b, px, py, d, role):
                return (round(px, 1), round(py, 1), d)
    b.skipped.append(note)
    return None


def guard_near(b, role, x, y, d, reach=3.0, note="guard", rect=None):
    t = b.t
    for px, py in near(x, y, reach, 0.5):
        if t.inside_office(px, py, 0.8):
            continue
        if rect and not (rect[0] + 0.8 <= px <= rect[1] - 0.8 and rect[2] + 0.8 <= py <= rect[3] - 0.8):
            continue
        g = tl.guard(t, role, px, py, None, d)
        if ok(t, g, b.placed):
            b.cur.append(g)
            return g
    b.skipped.append(note)
    return None


def side_pieces(rect, side, gate_at=None):
    """Wall items (cls, x, y, mdir) along one side of the yard rectangle, a gate at gate_at (the lateral coordinate)
    when given. Sides: front (y0), back (y1), left (x0), right (x1)."""
    x0, x1, y0, y1 = rect
    if side in ("front", "back"):
        a, c, fixed, mdir, horiz = x0, x1, (y0 if side == "front" else y1), 0, True
    else:
        a, c, fixed, mdir, horiz = y0, y1, (x0 if side == "left" else x1), 90, False
    out = []
    if gate_at is None:
        n = max(1, int(math.ceil((c - a) / 4 - 0.25)))
        start = (a + c) / 2 - (n - 1) * 2
        cs = [start + 4 * i for i in range(n)]
    else:
        g = gate_at
        out.append((GATE, g if horiz else fixed, fixed if horiz else g, mdir))
        cs = []
        p = g - 2.5 - 2
        while p + 2 > a + 1.0:  # Out to the corner (the last piece may run past it)
            cs.append(p)
            p -= 4
        p = g + 2.5 + 2
        while p - 2 < c - 1.0:
            cs.append(p)
            p += 4
    for p in cs:
        out.append((WALL, p if horiz else fixed, fixed if horiz else p, mdir))
    return out


def wall_items(t, pieces):
    return [tl.obj(t, cls, x, y, None, d) for cls, x, y, d in pieces]


def road_points(t, rmin=15, rmax=24):
    """Points on approach roads (model), one per road segment crossing the ring: [(x, y, road model direction)]."""
    pts = []
    for d, s in t.roads_near(t.origin[0], t.origin[1], rmax + 2):
        a, c = t.to_model(s["beg"]), t.to_model(s["end"])
        best = None
        for k in range(41):
            f = k / 40
            x, y = a[0] + (c[0] - a[0]) * f, a[1] + (c[1] - a[1]) * f
            r = math.hypot(x, y)
            if rmin <= r <= rmax:
                sc = abs(r - (rmin + rmax) / 2)
                if best is None or sc < best[0]:
                    best = (sc, x, y)
        if best:
            rd = math.degrees(math.atan2(c[0] - a[0], c[1] - a[1])) % 360
            if all(math.hypot(best[1] - p[0], best[2] - p[1]) > 9 for p in pts):
                pts.append((best[1], best[2], rd))
    return pts


def hedgehog_line(b, x, y, rd, n=3, gap=2.8):
    """Hedgehogs across a road at (x, y), road direction rd (model)."""
    nx, ny = math.cos(math.radians(rd)), -math.sin(math.radians(rd))  # Perpendicular to the road
    got = 0
    for k in range(n):
        off = (k - (n - 1) / 2) * gap
        it = tl.obj(b.t, "Land_CzechHedgehog_01_F", x + nx * off, y + ny * off, None, 225)
        if ok(b.t, it, b.placed, road_ok=True):
            b.cur.append(it)
            got += 1
    return got


def side_score(b, rect, side, gate_at=None):
    items = wall_items(b.t, side_pieces(rect, side, gate_at))
    good = [it for it in items if ok(b.t, it, b.placed)]
    return len(good), len(items)


def lay_side(b, rect, side, gate_at=None):
    n = 0
    for it in wall_items(b.t, side_pieces(rect, side, gate_at)):
        if ok(b.t, it, b.placed):
            b.cur.append(it)
            n += 1
    return n


# ---- House_Big_01 (front = model -y; after Aggelochori)

def big01(t):
    b = Builder(t)
    f0, f1 = t.floors[0], t.floors[-1]
    tune = TUNE[t.name]
    rect = tune["rect"]
    dm = t.door("main")["model"]
    gx = round(dm[0], 1)
    # T1: Aggelochori's office furniture, the flag in front, two gendarmes
    b.add(tl.obj(t, "Land_TableDesk_F", 1.9, -5.5, f0, 137), must=True)
    b.add(tl.obj(t, "Land_OfficeChair_01_F", 3.6, -6.1, f0, 187), must=True)
    b.add(tl.obj(t, "Land_MapBoard_F", 2.0, -0.1, f0, 52), must=True)
    b.first([tl.obj(t, "Flag_NATO_F", x, y, None, 180, flag=True) for x, y in ((0.0, -8.6), (0.0, -9.2), (1.5, -9.2), (-6.5, -2.5), (-7.0, -9.0))], note="flag")
    b.add(tl.guard(t, "gendarme", 3.3, -4.5, f0, 236), must=True)
    b.add(tl.guard(t, "gendarme", 1.5, 5.0, f0, 76), must=True)
    b.tier()
    # T2: the sandbag nest 3 m out from the main door (the way in at its sides), the porch post, two riflemen at
    # the upper east windows, the side door gated
    b.info_nest = door_nest(b, t.door(tune.get("nest_door", "main")))
    b.add(tl.obj(t, "Land_BagFence_Long_F", -4.6, -3.3, f0, 272))
    b.add(tl.guard(t, "rifleman", -3.3, -3.4, f0, 268), must=True)
    b.add(tl.guard(t, "rifleman", 3.6, -5.3, f1, 90), must=True)
    b.add(tl.guard(t, "rifleman", 3.9, 5.4, f1, 90), must=True)
    if tune.get("nest_door", "main") != "side":
        b.add(tl.obj(t, "Land_PipeFence_03_m_gate_r_F", 5.0, 5.2, f0, 90))
    b.tier()
    # T3: the yard's most open side walled with a gate, an HMG over the front and a GMG, two more guards
    sides = ["front", "left", "right", "back"]
    gates = {"front": gx, "left": 0.0, "right": 0.0, "back": 0.0}
    gates.update(tune.get("gates", {}))
    scores = {s: side_score(b, rect, s, gates[s]) for s in sides}
    t3 = tune.get("t3side") or max(sides, key=lambda s: (scores[s][0] / scores[s][1], s == "front"))
    keep_gate = {"front"} | set(tune.get("gates", {}))
    lay_side(b, rect, t3, gates[t3])
    x0, x1, y0, y1 = rect
    # The HMG a few metres inside the new gate, off its line, firing out through it
    normal = {"front": (0, -1), "back": (0, 1), "left": (-1, 0), "right": (1, 0)}[t3]
    gpos = [t.to_model(it[2]) for it in b.cur if it[1] == GATE]
    gate_cands = []
    for gm in gpos:
        for lat in (3.5, -3.5, 5.0, -5.0):
            ax, ay = gm[0] - normal[0] * 6 + normal[1] * lat, gm[1] - normal[1] * 6 + normal[0] * lat
            gate_cands.append((ax, ay, math.degrees(math.atan2(gm[0] + normal[0] * 6 - ax, gm[1] + normal[1] * 6 - ay)) % 360))
    hmg = static_post(b, "hmg", gate_cands, "hmg", reach=1.5, rect=rect) if gate_cands else None
    hmg = hmg or static_post(b, "hmg", [(x1 - 3, y0 + 3, 180), (x0 + 3, y0 + 3, 180), (x1 - 3, y0 + 4.5, 160), (x0 + 3.5, y0 + 4.5, 200), (8.0, -10.5, 180), (-8.0, -10.5, 180), (x1 - 3, 0, 90), (x0 + 3, 0, 270)], "hmg", rect=rect)
    gmg = static_post(b, "gmg", [(x0 + 3, y1 - 3, 315), (x1 - 3, y1 - 3, 45), (x0 + 3, y1 - 4.5, 300), (x1 - 3.5, y1 - 4.5, 60), (-8.5, 3.0, 270), (8.5, 3.0, 90), (x0 + 3, 0, 270), (x1 - 3, 0, 90), (0, y1 - 3, 0), (x1 - 3, y0 + 3, 135)], "gmg", rect=rect)
    b.add(tl.guard(t, "rifleman", 3.8, -5.3, f0, 90), must=True)
    gate = [it for it in b.cur if it[1] == GATE]
    if gate:
        gm = t.to_model(gate[0][2])
        # An autorifleman inside the gate, a few metres in, watching it
        inward = math.degrees(math.atan2(-gm[0], -gm[1]))
        cands = []
        for back in (3.0, 4.0, 2.5):
            for lat in (1.5, -1.5, 2.5, -2.5):
                ux, uy = math.sin(math.radians(inward)), math.cos(math.radians(inward))
                cands.append(tl.guard(t, "autorifleman", gm[0] + ux * back + uy * lat, gm[1] + uy * back - ux * lat, None, (inward + 180) % 360))
        b.first(cands, note="gate autorifleman")
    else:
        b.add(tl.guard(t, "autorifleman", -0.2, 1.9, f0, 180))
    b.tier()
    # T4: the rest of the yard walled, hedgehogs across the approach roads (the front approach without one),
    # wire on the open flanks, the MG gunner upstairs, autoriflemen in the yard's corners
    for s in sides:
        if s != t3:
            lay_side(b, rect, s, gates[s] if s in keep_gate else None)
    pts = road_points(t)
    hh = 0
    for x, y, rd in pts[:3]:
        hh += hedgehog_line(b, x, y, rd)
    if not pts:
        for x, y, rd in ((gx, y0 - 5, 90), (gx - 7, y0 - 4, 90), (gx + 7, y0 - 4, 90)):
            hh += hedgehog_line(b, x, y, rd, n=2, gap=3.5)
    my, mx = (y0 + y1) / 2, (x0 + x1) / 2
    slides = (0, 3, -3, 6, -6, 9, -9)
    offs = (4, 5, 6, 3)
    for cand in ([(x0 - o, my + s, 90) for o in offs for s in slides], [(x1 + o, my + s, 90) for o in offs for s in slides],
                 [(mx + s, y1 + o, 0) for o in offs for s in slides]):
        b.first([tl.obj(t, "Land_Razorwire_F", x, y, None, d) for x, y, d in cand], note="razorwire")
    b.add(tl.guard(t, "mg_gunner", -1.3, 5.3, f1, 90), must=True)
    for cx, cy, d in ((x0 + 1.5, y0 + 1.5, 225), (x1 - 1.5, y0 + 1.5, 135), (x0 + 1.5, y1 - 1.5, 315), (x1 - 1.5, y1 - 1.5, 45), (x0 + 1.5, (y0 + y1) / 2, 270), (x1 - 1.5, (y0 + y1) / 2, 90)):
        if sum(1 for it in b.cur if it[0] == "guard") >= 4:
            break
        guard_near(b, "autorifleman", cx, cy, d, note="corner autorifleman", rect=rect)
    b.tier()
    return b, {"t3": t3, "hmg": hmg, "gmg": gmg, "roads": len(pts), "hedgehogs": hh}


# ---- House_Big_02 (front = model -x, the main door on the west side)

def big02(t):
    b = Builder(t)
    f0, f1 = t.floors[0], t.floors[-1]
    rect = TUNE[t.name]["rect"]
    dm = t.door("main")["model"]
    gy = round(dm[1], 1)
    # T1: the template's tier 1 (the office upstairs)
    for it in tl.from_template(t, 1):
        if it[1] == "Flag_NATO_F":
            b.first([it] + [tl.obj(t, "Flag_NATO_F", x, y, None, 270, flag=True) for x, y in ((-6.5, -10.0), (-7.0, -1.5), (-6.5, 2.0))], note="flag")
        else:
            b.add(it, must=True)
    b.tier()
    # T2: the template's C nest at the main door with its pair, the side door's bags, a rifleman at the upper window
    nd = TUNE[t.name].get("nest_door", "main")
    b.info_nest = door_nest(b, t.door(nd))
    if nd == "main":
        for it in tl.from_template(t, 2):
            if it[0] == "object" and t.to_model(it[2])[1] > 5:  # The side door's bags
                b.add(it)
    b.add(tl.guard(t, "rifleman", 4.2, 2.9, f1, 90), must=True)
    b.tier()
    # T3: a short wall with a gate on the most open side, one HMG in round bags, the MG gunner on the front terrace
    # and an autorifleman at the wall's gate
    x0, x1, y0, y1 = rect
    best = None
    # The main door is on the west (left) side; the others get their gate in the middle
    for side, gate_at in (("left", gy), ("right", (y0 + y1) / 2), ("front", (x0 + x1) / 2), ("back", (x0 + x1) / 2)):
        pieces = side_pieces(rect, side, gate_at)
        g = [p for p in pieces if p[0] == GATE][0]
        key = (lambda p: abs(p[2] - g[2])) if side in ("left", "right") else (lambda p: abs(p[1] - g[1]))
        items = wall_items(t, [g] + sorted([p for p in pieces if p[0] == WALL], key=key)[:2])
        good = [it for it in items if ok(t, it, b.placed)]
        score = (bool(good) and good[0][1] == GATE, len(good), side == "left")
        if best is None or score > best[0]:
            best = (score, side, good)
    _, t3, walls = best
    for it in walls:
        b.add(it)
    hmg = static_post(b, "hmg", [(x0 + 3, y0 + 2.5, 225), (x0 + 3, y1 - 2.5, 315), (x1 - 3, y0 + 2.5, 135), (x1 - 3, y1 - 2.5, 45), (-8.0, -9.0, 250), (-8.0, 3.0, 290), (x1 - 3, 0, 90), (x0 + 3, 0, 270), (0, y0 + 2.5, 180), (0, y1 - 2.5, 0)], "hmg", rect=rect)
    b.first([tl.guard(t, "mg_gunner", -4.0, -5.0, f1, 270), tl.guard(t, "mg_gunner", -2.0, -5.0, f1, 270)], note="mg gunner")
    gate = [it for it in b.cur if it[1] == GATE]
    cands = []
    if gate:
        gm = t.to_model(gate[0][2])
        inward = math.degrees(math.atan2(-gm[0], -gm[1]))
        ux, uy = math.sin(math.radians(inward)), math.cos(math.radians(inward))
        for back in (3.0, 4.0, 2.5):
            for lat in (1.5, -1.5, 2.5, -2.5):
                cands.append(tl.guard(t, "autorifleman", gm[0] + ux * back + uy * lat, gm[1] + uy * back - ux * lat, None, (inward + 180) % 360))
    cands.append(tl.guard(t, "autorifleman", 3.3, 4.5, f0, 0))
    b.first(cands, note="gate autorifleman")
    b.tier()
    return b, {"t3": t3, "hmg": hmg}


def main():
    towns = tl.load()
    show = "--map" in sys.argv
    for name in BIG01 + BIG02:
        t = towns[name]
        b, info = (big01 if name in BIG01 else big02)(t)
        tiers = b.snapshots()
        probs = tl.check(t, tiers)
        counts = [(len(x), sum(1 for it in x if it[0] == "guard")) for x in tiers]
        print(f"{name}: cap {t.cap} tiers {counts} info {info} skipped {b.skipped}")
        if probs:
            print("   PROBLEMS", probs)
            continue
        tl.write(t, tiers)
        if show:
            print(tl.ascii_map(t, tiers[-1], r=30, step=1 if "--fine" in sys.argv else 2))


if __name__ == "__main__":
    main()
