"""
Mayor's office layouts, group "villages" (Overthrow CE): the Land_House_Big_02 offices (a two-storey town house,
the office upstairs). Run from the repository root:
    python tools/officegen/drafting/villages.py [--map] [town ...]
Writes tools/officegen/layouts/drafts/<town>.txt for each town (tl.write checks them first); --map prints each
town's top tier on a 1 m map (model coordinates, up = the office's front).

The building (model coordinates): walls at x -5.3..5.3, y -5.9..5.8. Two ways in on the ground floor:
  - the back porch (y -5..-6.5, under the back balcony): open to the back (-y) and the left end (x -5.3), the
    house door at (-2.9, -4.3);
  - the front door at (0.1, 5.3), opening forward (+y), under the front balcony.
Upstairs: the office (desk at (-2.4, 2)), a front balcony (y 6, x -3..4) and a back balcony (y -5, x -4..1).
Each town names its way in (ENTRY: "porch_s", "porch_w" or "front"); the other door is the second door.

The ladder (every tier keeps the one before):
  1  police presence: desk, chair, map board upstairs, the flag at the way in; 3 gendarmes: one at the way in, one
     at the second door, one upstairs.
  2  noticeable (6 guards): a sandbagged C nest (rifleman + autorifleman) beside the way in, square with the door and
     clear of its lane; a sandbag screen across the second door (a barricade inside it when a neighbour stands
     against it) covering the gendarme there; a marksman on the balcony over the way in.
  3  defended compound (12 guards, 2 statics): H-barrier lines close the open sides of the yard between the
     neighbouring buildings; the way in is one 5 m bar-gated gap square with the door, a chicane barrier inside it
     and the gate pair behind the line either side; an HMG and a GMG set into the lines (round bags in the line,
     the gun just inside, firing out over the bags, not into a barrier) down the approach roads; an MG on the other
     balcony, the officer upstairs, a rifleman holding the ground floor hall, an autorifleman on the quiet side's
     line. Where an H-barrier won't fit (a neighbour's corner, a road edge) a concrete block fills the gap.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

BARRIERS = ("Land_HBarrier_1_F", "Land_HBarrier_3_F", "Land_HBarrier_5_F", "Land_BarGate_F", "Land_CncBarrier_F")

# Per town: entry (the way in, default "porch_s"), ring (the tier 3 yard: model x0, x1, y0, y1; its lines close the
# open sides, the neighbours close the rest), statics ([(role, ring side, lateral, skew)]: set into that line),
# nest_a / nest_side (the tier 2 nest's distance out from the door and its side), screen_a (the second door's screen
# distance), gate_at (the gate off the door's axis), quiet (the side for the line autorifleman).
TOWNS = {
    "Alikampos": {"ring": (-10, 8, -10, 12), "nest_a": 2.0, "statics": [("hmg", "right", -6, 30), ("gmg", "back", -8, 30)]},
    "Dorida": {"entry": "front", "ring": (-8, 13, -11, 9.9), "nest_a": 2.4, "statics": [("hmg", "front", 8, 30), ("gmg", "right", -6, 30)]},
    "Gravia": {"ring": (-9, 9, -13, 11.2), "statics": [("hmg", "back", 4, 0), ("gmg", "front", -4, -30)]},
    "Kore": {"ring": (-10, 10, -14, 12), "statics": [("hmg", "back", -6, 30), ("gmg", "front", -5, -30)]},
    "Lakka": {"ring": (-10, 10, -14, 12), "statics": [("hmg", "back", 6, -30), ("gmg", "front", -6, -30)]},
    "Neri": {"ring": (-10, 10, -12.5, 12), "gate_at": -3.2, "statics": [("hmg", "back", -7, 30), ("gmg", "left", 8, 30)]},
    "Poliakko": {"ring": (-9, 7.3, -13, 12), "statics": [("hmg", "right", -8, 30), ("gmg", "right", 8, -30)]},
    "Selakano": {"ring": (-10, 8, -9.6, 12), "nest_a": 1.9, "nest_side": -1, "statics": [("hmg", "back", -8, 30), ("gmg", "front", -6, -30)]},
    "Stavros": {"entry": "front", "ring": (-8, 5.5, -7.5, 12), "statics": [("hmg", "left", -4, -30), ("gmg", "left", 8, 0)]},
    "Telos": {"ring": (-9, 10, -14, 7.2), "screen_a": 1.6, "statics": [("hmg", "right", 4, 0), ("gmg", "back", -6, 30)]},
    "Abdera": {},
    "Agios Konstantinos": {},
    "Galati": {},
    "Nifi": {},
    "Topolia": {},
}


def uv(d):
    """Model direction d as a unit vector (compass: 0 = +y, 90 = +x)."""
    r = math.radians(d)
    return math.sin(r), math.cos(r)


class Site:
    def __init__(self, t, cfg):
        self.t, self.cfg = t, cfg
        self.f0, self.f1 = t.floors[0], t.floors[-1]
        self.tiers, self.cur, self.skipped = [], [], []
        self.lanes = []  # (x, y, ux, uy, length, half width): kept clear of objects and statics
        entry = cfg.get("entry", "porch_s")
        self.entry = entry
        if entry == "porch_s":
            self.D, self.d = (-2.9, -6.6), 180
        elif entry == "porch_w":
            self.D, self.d = (-5.4, -5.9), 270
        else:
            self.D, self.d = (0.1, 5.9), 0
        self.front_blocked = bool(self.building_at(0.1, 7.6, 1.6, 1.0))
        self.porch_w_blocked = bool(self.building_at(-6.6, -5.9, 1.0, 1.6))
        self.porch_s_blocked = bool(self.building_at(-1.5, -7.8, 3.0, 1.0))

    # ---- geometry
    def building_at(self, x, y, length, depth):
        w = self.t.to_world(x, y, 0)
        return [h for h in self.t.hits(w[0], w[1], length, depth, self.t.dir, 0.0) if h[0] in ("building", "wall")]

    def ef(self, a, l, D=None, d=None):
        """A point in a door's frame: a metres out along its outward direction, l to the right of it."""
        D = D or self.D
        d = self.d if d is None else d
        ux, uy = uv(d)
        rx, ry = uv(d + 90)
        return D[0] + a * ux + l * rx, D[1] + a * uy + l * ry

    @property
    def placed(self):
        return [it for tier in self.tiers for it in tier] + self.cur

    # ---- the per-item rules
    def size(self, it):
        if it[0] == "object":
            return tl.CLASSES[it[1]]
        return (1.4, 1.4) if it[0] == "static" else (0.6, 0.6)

    def yaw(self, it):
        o = it[3]
        return (o if it[0] == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360

    def corners(self, it, grow=0.0):
        t = self.t
        m = t.to_model(it[2])
        L, D = self.size(it)
        L, D = L + grow, D + grow
        d = (self.yaw(it) - t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
        return [(m[0] + sx * L / 2 * cx[0] + sy * D / 2 * cy[0], m[1] + sx * L / 2 * cx[1] + sy * D / 2 * cy[1]) for sx in (-1, 1) for sy in (-1, 1)]

    def overlap(self, a, b, tol=0.12):
        t = self.t
        za, zb = t.to_model(a[2])[2], t.to_model(b[2])[2]
        if not ("ground" in a[4] and "ground" in b[4]) and abs(za - zb) > 1.5:
            return False
        pa, pb = self.corners(a), self.corners(b)
        for poly in (pa, pb):
            for i, j in ((0, 1), (1, 3)):
                ex, ey = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
                n = math.hypot(ex, ey) or 1
                nx, ny = -ey / n, ex / n
                a1 = [p[0] * nx + p[1] * ny for p in pa]
                b1 = [p[0] * nx + p[1] * ny for p in pb]
                if max(a1) < min(b1) + tol or max(b1) < min(a1) + tol:
                    return False
        return True

    def on_road(self, x, y):
        w = self.t.to_world(x, y, 0)
        return any(d <= min(4.0, s["width"] / 2) for d, s in self.t.roads_near(w[0], w[1], 10))

    def ok(self, it, lane_ok=False):
        t = self.t
        probs = tl.check(t, [[it, it]] * t.cap)
        if [p for p in probs if "guards" not in p and "tiers" not in p]:
            return False
        ground = "ground" in it[4]
        if ground and it[0] == "object":
            m = t.to_model(it[2])
            pts = self.corners(it) + [(m[0], m[1])]
            if any(self.on_road(x, y) for x, y in pts):
                return False
            w = it[2]
            L, D = self.size(it)
            if [h for h in t.hits(w[0], w[1], L, D, self.yaw(it), 0.05) if h[0] in ("wall", "tree")]:
                return False  # An old wall or a tree already there: it closes that bit
        if ground and not lane_ok and it[0] in ("object", "static") and it[1] != "Flag_NATO_F":
            for x, y, ux, uy, ln, hw in self.lanes:
                for cx, cy in self.corners(it) + [tuple(t.to_model(it[2])[:2])]:
                    a = (cx - x) * ux + (cy - y) * uy
                    if 0 <= a <= ln and abs((cx - x) * uy - (cy - y) * ux) <= hw:
                        return False
        for b in self.placed:
            if it[0] == "object" and b[0] == "object" and it[1] in BARRIERS and b[1] in BARRIERS:
                if self.overlap(it, b, 0.3):
                    return False
                continue
            if {it[0], b[0]} == {"static", "object"} and "Land_BagFence_Round_F" in (it[1], b[1]):
                if self.overlap(it, b, 0.35):  # The gun's own bags: the gunner leans on them
                    return False
                continue
            if self.overlap(it, b):
                return False
        return True

    def add(self, it, note="", lane_ok=False):
        if self.ok(it, lane_ok):
            self.cur.append(it)
            return it
        if note:
            self.skipped.append(note)
        return None

    def first(self, cands, note, lane_ok=False):
        for c in cands:
            if self.ok(c, lane_ok):
                self.cur.append(c)
                return c
        if note:
            self.skipped.append(note)
        return None

    def group(self, items, lane_ok=False):
        """All of items or none."""
        n = len(self.cur)
        for it in items:
            if not self.ok(it, lane_ok):
                del self.cur[n:]
                return False
            self.cur.append(it)
        return True

    def tier(self):
        self.tiers.append(self.cur)
        self.cur = []

    def snapshots(self):
        out, acc = [], []
        for tier in self.tiers:
            acc = acc + tier
            out.append(list(acc))
        return out

    # ---- shorthands
    def G(self, role, x, y, mdir, z=None):
        return tl.guard(self.t, role, x, y, z, mdir % 360)

    def O(self, cls, x, y, mdir, z=None, flag=False):
        return tl.obj(self.t, cls, x, y, z, mdir % 360, flag)

    def S(self, role, x, y, mdir):
        return tl.static(self.t, role, x, y, None, mdir % 360)


def near(x, y, reach=3.0, step=0.5):
    n = int(reach / step)
    pts = [(x + i * step, y + j * step) for i in range(-n, n + 1) for j in range(-n, n + 1)]
    return sorted([p for p in pts if math.hypot(p[0] - x, p[1] - y) <= reach], key=lambda p: math.hypot(p[0] - x, p[1] - y))


# ---- the pieces of the ladder

def second_door(s):
    """The door that isn't the way in: (outside point, outward dir, blocked, inside point)."""
    if s.entry == "front":
        if not s.porch_s_blocked:
            return (-2.9, -6.6), 180, False, (-2.9, -5.5)
        return (-5.4, -5.9), 270, s.porch_w_blocked, (-3.8, -5.6)
    return (0.1, 5.9), 0, s.front_blocked, (0.1, 3.4)


def tier1(s):
    t, f0, f1 = s.t, s.f0, s.f1
    # The office upstairs (the generated template's desk corner, which reviewed fine)
    s.cur += [s.O("Land_TableDesk_F", -2.4, 2.0, 270, f1), s.O("Land_OfficeChair_01_F", -4.0, 2.0, 270, f1),
              s.O("Land_MapBoard_F", -4.25, 4.0, 90, f1)]
    # The way in's lane: from the door out to where the tier 3 line puts its gate (or 12 m)
    ux, uy = uv(s.d)
    if "ring" in s.cfg:
        x0, x1, y0, y1 = s.cfg["ring"]
        reach = {"porch_s": s.D[1] - y0, "front": y1 - s.D[1], "porch_w": s.D[0] - x0}[s.entry] + 1.5
    else:
        reach = 8.0
    s.lanes.append((s.D[0] - ux * 0.5, s.D[1] - uy * 0.5, ux, uy, s.cfg.get("lane", reach), 1.1))
    # The flag beside the way in, where everyone coming to the office sees it
    s.first([s.O("Flag_NATO_F", *s.ef(a, l), 0, flag=True) for a, l in
             ((1.5, -2.2), (2.0, -2.6), (1.5, 2.2), (2.5, -3.0), (3.0, 2.6), (1.0, -3.0), (4.0, -2.5), (4.0, 2.5))], "flag")
    # Gendarme at the way in: on the porch at its mouth, or outside the front door beside it
    if s.entry == "porch_s":
        s.cur.append(s.G("gendarme", -1.9, -5.7, 180, f0))
    elif s.entry == "porch_w":
        s.cur.append(s.G("gendarme", -4.4, -5.0, 270, f0))
    else:
        s.first([s.G("gendarme", *s.ef(a, l), 0) for a, l in ((1.0, 1.3), (1.0, -1.3), (0.8, 1.6))] +
                [s.G("gendarme", 1.2, 4.6, 0, f0)], "front gendarme")
    # Gendarme at the second door
    D2, d2, blocked, inside = second_door(s)
    s.D2, s.d2, s.blocked2, s.in2 = D2, d2, blocked, inside
    if blocked or d2 == 270:
        s.cur.append(s.G("gendarme", inside[0], inside[1], d2, f0))
    elif d2 == 180:
        s.cur.append(s.G("gendarme", -1.9, -5.7, 180, f0))
    else:
        a = s.cfg.get("screen_a", 2.3) - 1.3
        s.first([s.G("gendarme", *s.ef(a, l, D2, d2), d2) for l in (-1.3, 1.3)] +
                [s.G("gendarme", 0.9, 4.4, 0, f0)], "second gendarme")
    # Upstairs, in the office
    s.cur.append(s.G("gendarme", -0.7, 2.1, 180 if s.entry != "front" else 0, f1))
    s.tier()


def nest(s, D, d, roles, a0=3.0, prefer=1):
    """A C of sandbags beside a door: the long bag across, square with the door, short bags running back, the pair
    1 m behind the long bag; beside the door's lane so the way in stays open. Returns the lateral side used."""
    for a in (a0, a0 + 0.6, a0 - 0.5, a0 + 1.2, a0 + 2.0):
        for side in (prefer, -prefer):
            for lat in (2.7, 3.2, 3.8):
                l = side * lat
                cx, cy = s.ef(a, l, D, d)
                items = [s.O("Land_BagFence_Long_F", cx, cy, d)]
                for e in (-1.7, 1.7):
                    items.append(s.O("Land_BagFence_Short_F", *s.ef(a - 0.85, l + e, D, d), d + 90))
                items += [s.G(r, *s.ef(a - 1.1, l + o, D, d), d) for r, o in zip(roles, (-0.6, 0.6))]
                if s.group(items):
                    return side
    s.skipped.append(f"nest {roles}")
    return None


def tier2(s):
    f0, f1 = s.f0, s.f1
    # The nest at the way in
    s.nest_side = nest(s, s.D, s.d, ("rifleman", "autorifleman"), a0=s.cfg.get("nest_a", 3.0), prefer=s.cfg.get("nest_side", 1))
    if s.nest_side is None and s.entry == "porch_s":
        # No ground for it (a road or a drop right off the porch): the nest on the porch's edge, under the balcony
        s.skipped.pop()
        s.nest_side = -1 if s.group([s.O("Land_BagFence_Long_F", 1.4, -6.3, 180, f0),
                                      s.G("rifleman", 0.8, -5.3, 180, f0), s.G("autorifleman", 2.0, -5.3, 180, f0)]) else None
    # The second door: a screen across it outside, or a barricade just inside when a neighbour stands against it
    if s.blocked2 or s.d2 == 270:
        x, y = s.in2
        ux, uy = uv(s.d2)
        s.add(s.O("Land_BagFence_Short_F", x + ux * 1.0, y + uy * 1.0, s.d2, f0), "second door barricade")
    else:
        a0 = s.cfg.get("screen_a", 2.3)
        if not s.first([s.O("Land_BagFence_Long_F", *s.ef(a, l, s.D2, s.d2), s.d2) for a, l in ((a0, -0.4), (a0 + 0.3, -0.4), (a0, 0.4), (a0 + 0.7, 0), (a0 - 0.5, 0))],
                       "", lane_ok=True):
            x, y = s.in2
            ux, uy = uv(s.d2)
            s.add(s.O("Land_BagFence_Short_F", x + ux * 1.0, y + uy * 1.0, s.d2, f0), "second door barricade")
    # A marksman on the balcony over the way in
    if s.entry == "front":
        s.cur.append(s.G("marksman", 1.6, 6.3, 0, f1))
    elif s.entry == "porch_w":
        s.cur.append(s.G("marksman", -3.6, -5.3, 270, f1))
    else:
        s.cur.append(s.G("marksman", -0.6, -5.3, 180, f1))
    s.tier()


def ring_side(s, side, gate=None):
    """H-barrier pieces along one side of the ring: (side, list of placed), the gate (lateral coordinate) leaves a
    5 m gap with a bar gate."""
    x0, x1, y0, y1 = s.cfg["ring"]
    if side in ("back", "front"):  # back: y0 (-y), front: y1
        fixed, a, c, mdir = (y0 if side == "back" else y1), x0, x1, 0
        pt = lambda u: (u, fixed)
    else:  # left: x0, right: x1
        fixed, a, c, mdir = (x0 if side == "left" else x1), y0 + 0.9, y1 - 0.9, 90
        pt = lambda u: (fixed, u)
    placed = []
    segs = [(a, c)] if gate is None else [(a, gate - 2.5), (gate + 2.5, c)]
    for k, (p, q) in enumerate(segs):
        # Tile from the gate's edge outward (the segment's inner end); without a gate from the start
        start, step = (q, -1) if (gate is not None and k == 0) else (p, 1)
        end = p if step < 0 else q
        u = start
        while (end - u) * step > 0.3:
            room = abs(end - u)
            for cls, ln in (("Land_HBarrier_5_F", 6.0), ("Land_HBarrier_3_F", 3.6), ("Land_HBarrier_1_F", 1.56), ("Land_CncBarrier_F", 1.6)):
                if ln > room + 0.8 and ln > 1.6:
                    continue
                it = s.O(cls, *pt(u + step * ln / 2), mdir)
                if s.add(it, lane_ok=False):
                    placed.append(it)
                    u += step * ln
                    break
            else:
                u += step * 0.5  # Blocked here (a neighbour, a wall, a road, a gun post): a bit further on
    return placed


def tier3(s):
    t, f0, f1 = s.t, s.f0, s.f1
    x0, x1, y0, y1 = s.cfg["ring"]
    gate_side = {"porch_s": "back", "porch_w": "left", "front": "front"}[s.entry]
    gate_at = s.D[0] if gate_side in ("back", "front") else s.D[1]
    gate_at = s.cfg.get("gate_at", gate_at)
    # The gate first: a bar gate in a 5 m gap of the line, square with the door
    gpt = (gate_at, y0 if gate_side == "back" else y1) if gate_side in ("back", "front") else (x0, gate_at)
    s.add(s.O("Land_BarGate_F", *gpt, 0 if gate_side in ("back", "front") else 90), "bar gate", lane_ok=True)
    # Statics next, set into the lines: the gun 1 m inside, its round bags filling the line in front of it, so it
    # fires out over the bags (not into an H-barrier) down its approach; a skew turns a corner post
    out_dir = {"back": 180, "front": 0, "left": 270, "right": 90}
    for role, side, lat, skew in s.cfg.get("statics", []):
        d = out_dir[side] + skew
        ox, oy = uv(out_dir[side])
        done = False
        for dl in (0, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5, 2.0, -2.0):
            if side in ("back", "front"):
                lx, ly = (lat + dl, y0 if side == "back" else y1)
            else:
                lx, ly = (x0 if side == "left" else x1, lat + dl)
            fx, fy = uv(d)
            items = [s.O("Land_BagFence_Round_F", lx + ox * 0.2, ly + oy * 0.2, d + 180),
                     s.S(role, lx + ox * 0.2 - fx * 1.0, ly + oy * 0.2 - fy * 1.0, d)]
            if s.group(items):
                done = True
                break
        if not done:
            s.skipped.append(f"static {role}")
    lines = {}
    for side in s.cfg.get("sides", ("back", "front", "left", "right")):
        lines[side] = ring_side(s, side, gate_at if side == gate_side else None)
    # The chicane: a barrier inside the gate, offset so the way in dog-legs round it under the nest's guns
    ux, uy = uv(s.d)
    gate_dist = {"back": s.D[1] - y0, "front": y1 - s.D[1], "left": s.D[0] - x0}[gate_side]
    s.gate_dist = gate_dist
    off = -(s.nest_side or 1) * 1.6
    if gate_dist >= 6.0 and s.cfg.get("chicane", True):
        s.first([s.O("Land_HBarrier_3_F", *s.ef(gate_dist - a, off * k), s.d) for a in (3.0, 3.5, 2.6) for k in (1, 1.3)],
                "chicane", lane_ok=True)
    # The gate pair: behind the line either side of the gap, facing out
    for role, sgn in (("rifleman", 1), ("at", -1)):
        s.first([s.G(role, *s.ef(gate_dist - 1.9, sgn * l), s.d) for l in (3.6, 4.4, 5.2, 6.0)] +
                [s.G(role, *s.ef(gate_dist - 1.9 - b, sgn * l), s.d) for b in (0.5, 1.0) for l in (3.6, 4.4, 5.2)],
                f"gate {role}")
    # Upstairs: the MG on the other balcony, the officer in the office
    if s.entry == "front":
        s.cur.append(s.G("mg_gunner", -0.6, -5.3, 180, f1))
    else:
        s.cur.append(s.G("mg_gunner", 2.6, 6.3, 0, f1))
    s.cur.append(s.G("officer", 0.3, 4.5, 270, f1))
    # The hall: a rifleman inside covering the way in
    s.cur.append(s.G("rifleman", 0.1, -3.3, 200, f0) if s.entry != "front" else s.G("rifleman", 1.1, 1.5, 0, f0))
    # The quiet side: an autorifleman behind its line (the longest line but the gate's, unless the town names one)
    order = sorted((k for k in lines if k != gate_side and lines[k]), key=lambda k: -len(lines[k]))
    if s.cfg.get("quiet"):
        order = [s.cfg["quiet"]] + [k for k in order if k != s.cfg["quiet"]]
    placed = False
    for quiet in order:
        out = {"back": 180, "front": 0, "left": 270, "right": 90}[quiet]
        ox, oy = uv(out)
        mids = sorted(lines[quiet], key=lambda it: abs(sum(t.to_model(it[2])[:2]) * 0 + (t.to_model(it[2])[0] if quiet in ("back", "front") else t.to_model(it[2])[1])))
        cands = []
        for it in mids:
            m = t.to_model(it[2])
            for sh in (0.0, -1.0, 1.0):
                px = m[0] - ox * 1.9 + (sh if quiet in ("back", "front") else 0)
                py = m[1] - oy * 1.9 + (sh if quiet in ("left", "right") else 0)
                cands.append(s.G("autorifleman", px, py, out))
        if s.first(cands, ""):
            placed = True
            break
    if not placed:
        s.skipped.append("quiet autorifleman")
    s.tier()


def build(name):
    t = tl.load()[name]
    s = Site(t, TOWNS[name])
    tier1(s)
    tier2(s)
    if t.cap >= 3:
        tier3(s)
    return s


def report(s):
    out = []
    for n, items in enumerate(s.snapshots(), 1):
        g = sum(1 for i in items if i[0] == "guard")
        st = sum(1 for i in items if i[0] == "static")
        out.append(f"T{n}: {len(items)} things, {g} guards, {st} statics")
    return "; ".join(out)


def show(s, r=24):
    t = s.t
    items = s.snapshots()[-1]
    marks = {}
    for it in items:
        if it[0] != "object":
            continue
        for cx, cy in s.corners(it):
            pass
        m = t.to_model(it[2])
        L, D = s.size(it)
        d = (s.yaw(it) - t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
        for i in range(-int(L), int(L) + 1):
            for j in range(-int(D), int(D) + 1):
                px, py = m[0] + i * 0.5 * cx[0] + j * 0.5 * cy[0], m[1] + i * 0.5 * cx[1] + j * 0.5 * cy[1]
                if abs(i * 0.5) <= L / 2 and abs(j * 0.5) <= D / 2:
                    c = {"Land_BarGate_F": "G", "Flag_NATO_F": "F", "Land_BagFence_Round_F": "(", }.get(it[1], "H" if "HBarrier" in it[1] else "b" if "Bag" in it[1] else "o")
                    marks[(round(px), round(py))] = c
    for it in items:
        m = t.to_model(it[2])
        key = (round(m[0]), round(m[1]))
        if it[0] == "static":
            marks[key] = "S"
        elif it[0] == "guard":
            up = "ground" not in it[4] and m[2] > s.f0 + 1.5
            marks[key] = "u" if up else "g"
    rows = ["     " + "".join("|" if i == 0 else str(abs(i) // 5 % 10) if i % 5 == 0 else " " for i in range(-r, r + 1))]
    for j in range(r, -r - 1, -1):
        row = ""
        for i in range(-r, r + 1):
            w = t.to_world(i, j, 0)
            c = "."
            if s.on_road(i, j):
                c = ":"
            hit = t.hits(w[0], w[1], 0.2, 0.2, 0, 0)
            if hit:
                c = {"building": "#", "wall": "=", "tree": "t", "rock": "r", "part": "P"}.get(hit[0][0], "?")
            if t.on_office(i, j, 0.2, 0.2):
                c = "O"
            c = marks.get((i, j), c)
            row += c
        rows.append(f"{j:4d} " + row)
    return "\n".join(rows)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    for name in (args or TOWNS):
        s = build(name)
        path = tl.write(s.t, s.snapshots())
        print(f"{name} ({s.entry}): {report(s)}; skipped {s.skipped} -> {os.path.relpath(path, tl.ROOT)}")
        if "--map" in sys.argv:
            print(show(s))
