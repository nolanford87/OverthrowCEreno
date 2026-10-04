"""
Mayor's office layouts, group "villages" (Overthrow CE): the Land_House_Big_02 offices (a two-storey town house,
the office upstairs). Run from the repository root:
    python tools/officegen/drafting/villages.py [--map] [--views] [town ...]
Writes tools/officegen/layouts/drafts/<town>.txt for each town (tl.write checks them first); --map prints each
town's top tier on a 1 m map (model coordinates, up = the office's front), --views every guard's and static's clear
view (m) as estimated from the probe.

The building (model coordinates): walls at x -5.3..5.3, y -5.9..5.8. Two ways in on the ground floor:
  - the back porch (y -5..-6.5, under the back balcony): open to the back (-y), the house door at (-2.9, -4.3);
  - the front door at (0.1, 5.3), opening forward (+y), under the front balcony.
Upstairs: the office (desk at (-2.4, 2)), a front balcony (y 6), a back balcony (y -5) and a window east (x 5, y 3).
Each town names its way in ("porch_s" or "front"); the other door is the second door.

The ladder (every tier keeps the one before):
  1  police presence (3 gendarmes): desk, chair, map board upstairs, the flag at the way in; a gendarme at the way
     in, one at the second door, one upstairs at the opening with the longest view.
  2  noticeable (6 guards): at the way in a sandbag C nest (rifleman + autorifleman) square with the door and clear
     of its lane, an H-barrier blast wall shielding its outer flank and a run of wire in front of it; a sandbag screen
     across the second door (a barricade inside it when a neighbour stands against it); a marksman on the balcony
     over the way in.
  3  defended compound (13 guards, 2 statics): the yard closed all round by unbroken H-barrier lines that overlap
     each other and butt into the neighbours and old walls; 2-high H-barriers (Land_HBarrier_Big_F) on the sides
     facing a road or open ground, 1-high ones elsewhere and either side of the gate so the gate pair can fire over
     them; the way in a bar gate square with the door, a chicane inside it when the yard is deep enough; a bag
     bunker tower at a corner of the gate's line (beside the gate when no corner fits), its marksman on the platform; an HMG and a GMG set into the lines (round bags in
     the line, the gun just inside), each placed where its field of fire down an approach is longest; an MG on the
     other balcony, the officer upstairs, a rifleman on the porch/at the front door, an autorifleman on a 1-high line.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

TALL = ("Land_HBarrier_Big_F", "Land_BagBunker_Tower_F")  # Block a man's view (the 1-high H-barriers he fires over)
TOWER_PLATFORM = 3.4  # The bag bunker tower's platform above the ground at its centre (measured in the game)
OUT = {"back": 180, "front": 0, "left": 270, "right": 90}

# Per town: entry (the way in, default "porch_s"); ring (the tier 3 yard: model x0, x1, y0, y1; its lines close the
# open sides, the neighbours close the rest); tall (the sides facing a road or open ground: 2-high); statics
# ([(role, [(side, lateral, skew), ...])]: the posts tried, the one with the longest field of fire taken); nest_a /
# nest_side (the tier 2 nest's distance out from the door and its side); screen_a (the second door's screen);
# gate_at (the gate off the door's axis); door_posts ([(a, l, dir)]: the second door's gendarme, stepped out
# beside its screen where the doorway post measured blind); mg_posts ("back": the MG on the back balcony); no_window (the office gendarme not at the east
# window, measured blind); avoid ([(x, y, r)]: no gun there, measured blocked in the game); tower "gate" (the tower beside the gate, not at a corner).
TOWNS = {
    "Alikampos": {"ring": (-10, 8, -10, 12), "nest_a": 2.0, "tall": ("back", "right", "front"),
                  "statics": [("hmg", [("right", -6, 30), ("right", -2, 45), ("back", 5, -30)]),
                              ("gmg", [("back", -8, 30), ("front", -6, -30), ("left", 10, -30)])]},
    "Dorida": {"entry": "front", "ring": (-19, 17, -11, 9.9), "nest_a": 2.4, "tall": ("front", "right", "left"),
               "statics": [("hmg", [("front", 8, 30), ("front", 10, 0), ("right", 7, 0)]),
                           ("gmg", [("right", -6, 30), ("right", -8, 60), ("back", 8, -30), ("back", -4, 0)])]},
    "Gravia": {"ring": (-9, 9, -13, 11.2), "tall": ("back", "front"),
               "statics": [("hmg", [("back", 4, 0), ("back", 6, -20), ("back", 2, 0)]),
                           ("gmg", [("front", -4, -30), ("front", -2, -15), ("left", 9, -30)])]},
    "Kore": {"mg_posts": "back", "avoid": [(16.7, -9.5, 2.5), (-15.5, 0.5, 3.0)], "ring": (-16, 17.5, -14, 12), "tall": ("back", "front", "left", "right"),
             "statics": [("hmg", [("back", -6, 30), ("back", 5, -30)]), ("gmg", [("back", -10, 0), ("back", -12, 0), ("left", -6, 0), ("front", -5, -30)])]},
    "Lakka": {"ring": (-10, 10, -14, 12), "tall": ("back", "right", "left", "front"),
              "statics": [("hmg", [("back", 6, -30), ("right", -10, 30)]), ("gmg", [("front", -6, -30), ("left", 6, -30)])]},
    "Neri": {"ring": (-10, 10, -12.5, 12), "gate_at": -3.2, "tall": ("back", "left"),
             "statics": [("hmg", [("back", -7, 30), ("left", -8, -30), ("back", 6, -30), ("back", 4, 0)]),
                         ("gmg", [("left", 8, 30), ("left", 4, 0)])]},
    "Poliakko": {"no_window": True, "door_posts": [(3.2, -2.6, 0), (3.2, 2.6, 0), (3.2, -2.6, 330), (3.6, -3.0, 0)], "ring": (-18, 7.3, -13, 12), "tall": ("right", "back", "left"),
                 "statics": [("hmg", [("right", -8, 30), ("right", -5, 45)]), ("gmg", [("right", 8, -30), ("right", 5, -45)])]},
    "Selakano": {"avoid": [(14.7, 1.8, 2.0)], "ring": (-17.5, 15.5, -9.6, 12), "tower": "gate", "nest_a": 1.9, "nest_side": -1, "tall": ("back", "left", "right", "front"),
                 "statics": [("hmg", [("back", -8, 30), ("left", -6, -30)]), ("gmg", [("front", -6, -30), ("left", 8, 30)])]},
    "Stavros": {"avoid": [(-7.5, 7.5, 3.5)], "entry": "front", "ring": (-8, 5.5, -7.5, 12), "tall": ("back", "left", "front"),
                "statics": [("hmg", [("left", -4, -30), ("back", -5, 30), ("left", 0, -45)]), ("gmg", [("left", 8, 0), ("front", -5, -30)])]},
    "Telos": {"nest_side": -1, "ring": (-21, 10, -14, 7.6), "tall": ("front", "back", "right", "left"),
              "statics": [("hmg", [("right", 4, 0), ("right", 0, 30), ("front", 7, 30)]), ("gmg", [("back", -6, 30), ("back", 5, -30)])]},
    "Abdera": {},
    "Agios Konstantinos": {},
    "Galati": {},
    "Nifi": {"door_posts": [(1.0, -1.2, 270), (1.0, -1.6, 290), (1.0, 1.2, 90), (1.0, 1.6, 70)]},
    "Topolia": {},
}


def uv(d):
    """Model direction d as a unit vector (compass: 0 = +y, 90 = +x)."""
    r = math.radians(d)
    return math.sin(r), math.cos(r)


def barrierish(cls):
    """Pieces that may overlap each other, the neighbours and old walls a little (townlib's barrier rule)."""
    return tl.is_barrier(cls) or "BagBunker" in cls


class Site:
    def __init__(self, t, cfg):
        self.t, self.cfg = t, cfg
        self.f0, self.f1 = t.floors[0], t.floors[-1]
        self.tiers, self.cur, self.skipped = [], [], []
        self.lanes = []  # (x, y, ux, uy, length, half width): kept clear of objects and statics
        self.entry = cfg.get("entry", "porch_s")
        if self.entry == "porch_s":
            self.D, self.d = (-2.9, -6.6), 180
        else:
            self.D, self.d = (0.1, 5.9), 0
        self.front_blocked = bool(self.building_at(0.1, 7.6, 1.6, 1.0))
        self.porch_s_blocked = bool(self.building_at(-1.5, -7.8, 3.0, 1.0))
        # The probed walls, buildings and tree trunks as rectangles in model coordinates (centre, model dir, half
        # sizes), for a proper overlap test: a thin wall crossing a piece's middle has no corner inside it
        self.rects = []
        for o in t.objs:
            if o["kind"] not in ("wall", "building", "rock", "tree"):
                continue
            b = o["box"]
            if o["kind"] == "tree":
                b = [-0.6, -0.6, 0.6, 0.6]
            cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
            dx, dy = tl.rot(cx, cy, o["dir"])
            m = t.to_model([o["pos"][0] + dx, o["pos"][1] + dy, 0])
            md = (o["dir"] - t.dir) % 360
            hx, hy = (b[2] - b[0]) / 2, (b[3] - b[1]) / 2
            ax, ay = tl.rot(1, 0, md), tl.rot(0, 1, md)
            self.rects.append((o["kind"], [(m[0] + sx * hx * ax[0] + sy * hy * ay[0], m[1] + sx * hx * ax[1] + sy * hy * ay[1])
                                          for sx in (-1, 1) for sy in (-1, 1)]))

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

    def size(self, it, core=False):
        if it[0] == "object":
            L, D = tl.CLASSES[it[1]]
            if core and barrierish(it[1]):
                return max(L - 2 * tl.BARRIER_OVERLAP, 0.2), max(D * 0.5, 0.2)
            return L, D
        return (1.4, 1.4) if it[0] == "static" else (0.6, 0.6)

    def yaw(self, it):
        o = it[3]
        return (o if it[0] == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360

    def corners(self, it, core=False):
        t = self.t
        m = t.to_model(it[2])
        L, D = self.size(it, core)
        d = (self.yaw(it) - t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
        return [(m[0] + sx * L / 2 * cx[0] + sy * D / 2 * cy[0], m[1] + sx * L / 2 * cx[1] + sy * D / 2 * cy[1]) for sx in (-1, 1) for sy in (-1, 1)]

    def inside(self, it, x, y):
        """Whether model point (x, y) is within an item's footprint."""
        m = self.t.to_model(it[2])
        L, D = self.size(it)
        lx, ly = tl.rot(x - m[0], y - m[1], -((self.yaw(it) - self.t.dir) % 360))
        return abs(lx) <= L / 2 and abs(ly) <= D / 2

    def overlap(self, a, b, tol=0.12, core=False):
        t = self.t
        za, zb = t.to_model(a[2])[2], t.to_model(b[2])[2]
        if not ("ground" in a[4] and "ground" in b[4]) and abs(za - zb) > 1.5:
            return False
        pa, pb = self.corners(a, core), self.corners(b, core)
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

    @staticmethod
    def sat(pa, pb, tol=0.05):
        """Whether two rectangles (4 corners each, ordered as corners() gives them) overlap by more than tol."""
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

    OFFICE = [(-5.4, -6.7), (-5.4, 7.0), (5.4, -6.7), (5.4, 7.0)]  # The house, its porch and front steps

    def game_rays(self, it):
        """The in-game clip test (fn_checkLayouts): two rays across the diagonals of a ground thing's footprint at its
        real (measured, upper-bound) size; a barrier's only over its middle (0.6 m off each end, half its depth).
        Returns what they run through: [(kind, where)] of the probed walls/buildings/rocks and the office."""
        if "ground" not in it[4] or it[0] == "guard":
            return []
        what = it[1] if it[0] == "object" else f"static {it[1]}"
        L, D = next((v[:2] for k, v in tl.MEASURED.items() if (k == what or k.startswith(what + " (")) and k != "Land_BarGate_F"),
                    tl.CLASSES.get(it[1], (1.4, 2.3)))  # The bar gate's real box takes in its arm's swing: its posts only
        if it[0] == "object" and barrierish(it[1]):
            ix, iy = max(L / 2 - 0.6, 0.1), D / 4
        else:
            ix, iy = 0.4 * L, 0.4 * D
        m = self.t.to_model(it[2])
        d = (self.yaw(it) - self.t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
        P = lambda a, b: (m[0] + a * ix * cx[0] + b * iy * cy[0], m[1] + a * ix * cx[1] + b * iy * cy[1])
        rays = [(P(-1, -1), P(1, 1)), (P(-1, 1), P(1, -1))]
        out = []
        for kind, r in self.rects + [("office", self.OFFICE)]:
            if kind == "tree":
                continue  # The game's test leaves trees out
            if any(seg_rect(a, b, r) for a, b in rays):
                out.append((kind, tuple(round(v, 1) for v in rect_centre(r))))
        return out

    def on_road(self, x, y):
        w = self.t.to_world(x, y, 0)
        return any(d <= min(4.0, s["width"] / 2) for d, s in self.t.roads_near(w[0], w[1], 10))

    # ---- sight
    def blocked(self, x, y, upstairs=False, low=False, origin=None):
        """Whether a sight line is stopped at model (x, y): buildings, rocks, the office, tall pieces; old walls and
        (low) the 1-high barriers too, for a man or gun on the ground."""
        t = self.t
        w = t.to_world(x, y, 0)
        kinds = ("building", "part", "rock") if upstairs else ("building", "part", "rock", "wall")
        if [h for h in t.hits(w[0], w[1], 0.3, 0.3, 0, 0) if h[0] in kinds]:
            return True
        if t.on_office(x, y, 0.2, 0.2):
            return True
        if upstairs:
            if origin is not None and math.dist(origin, (x, y)) < 5 and [h for h in t.hits(w[0], w[1], 2.0, 2.0, 0, 0) if h[0] == "tree"]:
                return True  # A tree's crown right in front of a balcony
            return False  # From a balcony or the tower's platform the yard's pieces are below the line of sight
        for it in self.placed:
            if it[0] != "object" or "ground" not in it[4]:
                continue
            tall = it[1] in TALL
            if low and not tall and "HBarrier" in it[1]:
                tall = origin is None or math.dist(origin, (x, y)) > 3.5  # A gun fires over its own line's pieces
            if tall and self.inside(it, x, y):
                return True
        return False

    def ray(self, x, y, d, start=0.6, maxd=45.0, upstairs=False, low=False):
        ux, uy = uv(d)
        k = start
        while k < maxd:
            if self.blocked(x + ux * k, y + uy * k, upstairs, low, (x, y)):
                return round(k, 1)
            k += 0.5
        return maxd

    def view(self, it):
        """A guard's or static's clear view ahead (m), from the probe: upstairs from the opening it stands at."""
        m = self.t.to_model(it[2])
        d = (self.yaw(it) - self.t.dir) % 360
        up = "ground" not in it[4] and m[2] > self.f0 + 1.5
        if it[0] == "static":
            return self.ray(m[0], m[1], d, start=2.0, low=True)
        if "ground" not in it[4] and any(b[1] == "Land_BagBunker_Tower_F" and self.inside(b, m[0], m[1]) for b in self.placed):
            return self.ray(m[0], m[1], d, start=1.8, upstairs=True)  # On the tower's platform
        if "ground" not in it[4]:
            # On a floor: from where the line of sight leaves the building
            ux, uy = uv(d)
            k = 0.0
            while k < 8 and self.t.on_office(m[0] + ux * k, m[1] + uy * k, 0.2, 0.2):
                k += 0.25
            return round(k + self.ray(m[0] + ux * k, m[1] + uy * k, d, start=0.3, upstairs=up), 1)
        return self.ray(m[0], m[1], d)

    # ---- the per-item rules
    def ok(self, it, lane_ok=False):
        t = self.t
        probs = tl.check(t, [[it, it]] * t.cap)
        if [p for p in probs if "guards" not in p and "tiers" not in p]:
            return False
        ground = "ground" in it[4]
        bar = it[0] == "object" and barrierish(it[1])
        if self.game_rays(it):
            return False  # The game's own clip test (its rays across the real footprint) would flag it
        if ground and it[0] == "object":
            m = t.to_model(it[2])
            if any(self.on_road(x, y) for x, y in self.corners(it, core=True) + [(m[0], m[1])]):
                return False
            w = it[2]
            L, D = self.size(it, core=True)
            if [h for h in t.hits(w[0], w[1], L, D, self.yaw(it), 0.0) if h[0] in ("wall", "tree")]:
                return False  # An old wall or a tree already there: it closes that bit
            core = self.corners(it, core=True)
            if any(self.sat(core, r) for k, r in self.rects):
                return False  # Into an old wall, a building or a trunk (the middle of the piece)
            margin = 1.0 if it[1] == "Flag_NATO_F" else 0.0
            box = [(x * (5.4 + margin) / 5.4, y + (margin if y > 0 else -margin)) for x, y in self.OFFICE]
            if self.sat(self.corners(it), box, 0.0):
                return False  # Into the house itself (its whole footprint, not only the middle)
        if ground and not lane_ok and it[0] in ("object", "static") and it[1] != "Flag_NATO_F":
            for x, y, ux, uy, ln, hw in self.lanes:
                for cx, cy in self.corners(it, core=bar) + [tuple(t.to_model(it[2])[:2])]:
                    a = (cx - x) * ux + (cy - y) * uy
                    if 0 <= a <= ln and abs((cx - x) * uy - (cy - y) * ux) <= hw:
                        return False
        for b in self.placed:
            if bar and b[0] == "object" and "Land_BagFence_Round_F" in (it[1], b[1]) and barrierish(b[1]):
                if self.overlap(it, b, 0.3):  # Nothing in front of a gun's bags
                    return False
                continue
            if bar and b[0] == "object" and barrierish(b[1]):
                if self.overlap(it, b, 0.1, core=True):
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

    def first(self, cands, note, lane_ok=False, see=0.0, fallback=True):
        """The first candidate that fits (and, for a guard, sees at least see metres ahead; else the one that fits
        and sees furthest)."""
        best = None
        for c in cands:
            if self.ok(c, lane_ok):
                if see <= 0:
                    self.cur.append(c)
                    return c
                v = self.view(c)
                if v >= see:
                    self.cur.append(c)
                    return c
                if best is None or v > best[0]:
                    best = (v, c)
        if best and fallback:
            self.cur.append(best[1])
            return best[1]
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

    def keeps_views(self, items, floor=6.0):
        """Whether adding items leaves every ground guard placed so far seeing at least floor metres (or what he saw)."""
        guards = [g for g in self.placed if g[0] == "guard" and ("ground" in g[4] or self.t.to_model(g[2])[2] < self.f0 + 1.5)]
        before = [self.view(g) for g in guards]
        n = len(self.cur)
        self.cur += items
        after = [self.view(g) for g in guards]
        del self.cur[n:]
        return all(a >= min(b, floor) for a, b in zip(after, before))

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

    def upstairs(self, role, posts, note):
        """A guard upstairs at the post [(x, y, dir)] with the longest view out."""
        taken = [self.t.to_model(g[2])[:2] for g in self.placed if g[0] == "guard" and "ground" not in g[4]]
        posts = [p for p in posts if all(math.dist(p[:2], q) > 0.8 for q in taken)] or posts
        best = max(posts, key=lambda p: self.view(self.G(role, p[0], p[1], p[2], self.f1)))
        g = self.G(role, best[0], best[1], best[2], self.f1)
        self.cur.append(g)
        return g


# Upstairs posts: the back balcony, the front balcony, the east window
BACK_BALCONY = [(-0.6, -5.3, 180), (-3.4, -5.3, 180), (-3.4, -5.3, 225), (0.6, -5.3, 150)]
FRONT_BALCONY = [(3.3, 6.3, 0), (-2.0, 6.3, 0), (3.3, 6.3, 30), (-2.0, 6.3, 330)]
WINDOW = [(4.3, 2.9, 90)]


def rect_centre(r):
    return sum(p[0] for p in r) / 4, sum(p[1] for p in r) / 4


def seg_rect(a, b, r):
    """Whether segment a-b crosses rectangle r (4 corners, ordered as Site.corners gives them)."""
    poly = [r[0], r[1], r[3], r[2]]
    def inside(p):
        s = []
        for i in range(4):
            q0, q1 = poly[i], poly[(i + 1) % 4]
            s.append((q1[0] - q0[0]) * (p[1] - q0[1]) - (q1[1] - q0[1]) * (p[0] - q0[0]))
        return all(v >= 0 for v in s) or all(v <= 0 for v in s)
    if inside(a) or inside(b):
        return True
    def cross(p, q, u, v):
        o = lambda p1, p2, p3: (p2[0] - p1[0]) * (p3[1] - p1[1]) - (p2[1] - p1[1]) * (p3[0] - p1[0])
        return o(p, q, u) * o(p, q, v) < 0 and o(u, v, p) * o(u, v, q) < 0
    return any(cross(a, b, poly[i], poly[(i + 1) % 4]) for i in range(4))


def near(x, y, reach=3.0, step=0.5):
    n = int(reach / step)
    pts = [(x + i * step, y + j * step) for i in range(-n, n + 1) for j in range(-n, n + 1)]
    return sorted([p for p in pts if math.hypot(p[0] - x, p[1] - y) <= reach], key=lambda p: math.hypot(p[0] - x, p[1] - y))


# ---- the pieces of the ladder

def second_door(s):
    """The door that isn't the way in: (outside point, outward dir, blocked, inside point)."""
    if s.entry == "front":
        return (-2.9, -6.6), 180, s.porch_s_blocked, (-2.9, -5.5)
    return (0.1, 5.9), 0, s.front_blocked, (0.1, 3.4)


def tier1(s):
    f0, f1 = s.f0, s.f1
    # The office upstairs (the generated template's desk corner, which reviewed fine)
    s.cur += [s.O("Land_TableDesk_F", -2.4, 2.0, 270, f1), s.O("Land_OfficeChair_01_F", -4.0, 2.0, 270, f1),
              s.O("Land_MapBoard_F", -3.5, 4.0, 90, f1)]  # Its real box is 1 m deep: 0.4 m clear of the west wall
    # The way in's lane: from the door out to the tier 3 gate (or 8 m)
    ux, uy = uv(s.d)
    if "ring" in s.cfg:
        x0, x1, y0, y1 = s.cfg["ring"]
        reach = (s.D[1] - y0 if s.entry == "porch_s" else y1 - s.D[1]) + 1.5
    else:
        reach = 8.0
    s.lanes.append((s.D[0] - ux * 0.5, s.D[1] - uy * 0.5, ux, uy, reach, 1.1))
    # The flag beside the way in, where everyone coming to the office sees it
    s.first([s.O("Flag_NATO_F", *s.ef(a, l), 0, flag=True) for a, l in
             ((1.5, -2.2), (2.0, -2.6), (1.5, 2.2), (2.5, -3.0), (3.0, 2.6), (1.0, -3.0), (4.0, -2.5), (4.0, 2.5),
              (1.0, -4.0), (1.0, 4.0), (0.6, -4.8), (0.6, 7.0), (0.6, 8.2), (1.2, -6.0))], "flag")
    # Gendarme at the way in: on the porch at its mouth, or outside the front door beside it
    if s.entry == "porch_s":
        s.first([s.G("gendarme", x, -5.8, d, f0) for x in (-1.9, -0.9, -3.9) for d in (180, 200, 160)], "porch gendarme", see=8)
    else:
        s.first([s.G("gendarme", *s.ef(a, l), d) for a, l in ((1.0, 1.6), (1.0, -1.6), (0.8, 2.2)) for d in (0, 20, 340)],
                "front gendarme", see=8)
    # Gendarme at the second door (at the east window when a neighbour stands against that door)
    D2, d2, blocked, inside = second_door(s)
    s.D2, s.d2, s.blocked2, s.in2 = D2, d2, blocked, inside
    if blocked:
        if not s.first([s.G("gendarme", 4.1, 2.9, 90, f0)], "", see=6, fallback=False):
            s.first([s.G("gendarme", x, -5.8, d, f0) for x in (1.5, 3.0, 0.5, -0.9, -3.9) for d in (180, 150, 210, 120, 240)], "second gendarme", see=8)
    elif d2 == 180:
        s.first([s.G("gendarme", x, -5.8, d, f0) for x in (-1.9, -0.9, 1.0) for d in (180, 200, 160)], "second gendarme")
    else:
        a = s.cfg.get("screen_a", 2.3) - 1.3
        posts = s.cfg.get("door_posts") or [(max(a, 1.0), l, d) for l in (-1.2, 1.2, -1.6, 1.6, -2.2, 2.2) for d in (0, 340, 20)]
        s.first([s.G("gendarme", *s.ef(pa, pl, D2, d2), pd) for pa, pl, pd in posts], "second gendarme", see=6)
    # Upstairs, at the opening with the longest view
    s.upstairs("gendarme", ([] if s.cfg.get("no_window") else WINDOW) + (BACK_BALCONY[:2] if s.entry == "porch_s" else FRONT_BALCONY[:2]), "office gendarme")
    s.tier()


def nest(s, D, d, roles, a0=3.0, prefer=1):
    """A C of sandbags beside a door: the long bag across, square with the door, short bags running back, the pair
    1 m behind the long bag; beside the door's lane so the way in stays open. Returns (side, a, lat) used."""
    for a in (a0, a0 + 0.6, a0 - 0.5, a0 + 1.2, a0 + 2.0):
        for side in (prefer, -prefer):
            for lat in (2.7, 3.2, 3.8):
                l = side * lat
                cx, cy = s.ef(a, l, D, d)
                items = [s.O("Land_BagFence_Long_F", cx, cy, d)]
                for e in (-1.7, 1.7):
                    items.append(s.O("Land_BagFence_Short_F", *s.ef(a - 0.85, l + e, D, d), d + 90))
                guards = [s.G(r, *s.ef(a - 1.1, l + o, D, d), d) for r, o in zip(roles, (-0.6, 0.6))]
                if min(s.view(g) for g in guards) < 8:
                    continue
                if s.group(items + guards):
                    return side, a, lat
    s.skipped.append(f"nest {roles}")
    return None


def tier2(s):
    f0, f1 = s.f0, s.f1
    # The nest at the way in, with an H-barrier blast wall on its outer flank and wire in front
    got = nest(s, s.D, s.d, ("rifleman", "autorifleman"), a0=s.cfg.get("nest_a", 3.0), prefer=s.cfg.get("nest_side", 1))
    if got:
        side, a, lat = got
        s.nest_side = side
        s.first([s.O("Land_HBarrier_3_F", *s.ef(a - 0.5 + da, side * (lat + 2.75 + dl)), s.d + 90)
                 for da in (0, -0.6, 0.6) for dl in (0, 0.4)], "nest blast wall")
        s.first([s.O("Land_Razorwire_F", *s.ef(a + da, side * (lat + dl)), s.d)
                 for da in (2.4, 3.0, 3.6) for dl in (2.8, 3.4, 4.0)], "nest wire")
    elif s.entry == "porch_s":
        # No ground for it (a road right off the porch): the nest on the porch's edge, under the balcony, its flank
        # shielded by an H-barrier on the ground beside the porch
        s.skipped.pop()
        s.nest_side = -1 if s.group([s.O("Land_BagFence_Long_F", 1.4, -5.8, 180, f0),
                                      s.G("rifleman", 0.8, -4.8, 180, f0), s.G("autorifleman", 2.0, -4.8, 180, f0)]) else None
        s.first([s.O("Land_HBarrier_3_F", x, y, 90) for x, y in ((6.3, -7.0), (6.3, -7.6), (5.0, -8.2))], "porch blast wall")
    else:
        s.nest_side = None
    # The second door: a screen across it outside, or a barricade just inside when a neighbour stands against it
    if s.blocked2:
        x, y = s.in2
        ux, uy = uv(s.d2)
        s.add(s.O("Land_BagFence_Short_F", x + ux * 1.0, y + uy * 1.0, s.d2, f0), "second door barricade")
    else:
        a0 = s.cfg.get("screen_a", 2.3)
        if not s.first([s.O("Land_BagFence_Long_F", *s.ef(a, l, s.D2, s.d2), s.d2) for a, l in ((a0, 0), (a0 + 0.3, 0), (a0, 0.4), (a0 + 0.7, 0), (a0 - 0.5, 0))],
                       "", lane_ok=True):
            x, y = s.in2
            ux, uy = uv(s.d2)
            s.add(s.O("Land_BagFence_Short_F", x + ux * 1.0, y + uy * 1.0, s.d2, f0), "second door barricade")
    # A marksman on the balcony over the way in
    s.upstairs("marksman", (FRONT_BALCONY if s.entry == "front" else BACK_BALCONY) + WINDOW, "marksman")
    s.tier()


def ring_side(s, side, gate=None, tall=False):
    """Barrier pieces along one side of the ring, overlapping so the line is unbroken; 2-high where tall (1-high
    within 7 m of the gate). The gate (lateral coordinate) leaves its 5 m gap. Returns the pieces placed."""
    x0, x1, y0, y1 = s.cfg["ring"]
    if side in ("back", "front"):
        fixed, a, c, mdir = (y0 if side == "back" else y1), x0, x1, 0
        pt = lambda u: (u, fixed)
    else:
        fixed, a, c, mdir = (x0 if side == "left" else x1), y0, y1, 90
        pt = lambda u: (fixed, u)
    placed = []
    segs = [(a, c)] if gate is None else [(a, gate - 2.5), (gate + 2.5, c)]
    for k, (p, q) in enumerate(segs):
        if q - p < 0.3:
            continue
        # Tile from the gate's edge outward (the segment's inner end); without a gate from the start
        start, step = (q, -1) if (gate is not None and k == 0) else (p, 1)
        end = p if step < 0 else q
        u = start + step * 0.3  # Into the gate's post a little
        while (end - u) * step > 0.0:
            room = abs(end - u)
            pieces = ([("Land_HBarrier_Big_F", 8.4)] if tall else []) + \
                [("Land_HBarrier_5_F", 6.0), ("Land_HBarrier_3_F", 3.6), ("Land_HBarrier_1_F", 1.56), ("Land_CncBarrier_F", 1.6)]
            for cls, ln in pieces:
                if ln > room + 1.2 and ln > 1.6:
                    continue
                if cls == "Land_HBarrier_Big_F" and low_here(s, pt, u + step * (ln / 2 - 0.3), ln, gate):
                    continue  # 1-high by the gate, the guns and the second door: the men there fire over it
                it = s.O(cls, *pt(u + step * (ln / 2 - 0.3)), mdir)
                if s.add(it):
                    placed.append(it)
                    u += step * (ln - 0.6)  # The next piece overlaps this one
                    break
            else:
                u += step * 0.5  # Blocked here (a neighbour, a wall, a road, a gun post): a bit further on
    return placed


def fill_holes(s, tries=10):
    """Close every hole a man could slip through (closed_audit): a short piece on the ring's line at the hole,
    overlapping the pieces either side at their ends. Returns the pieces added."""
    x0, x1, y0, y1 = s.cfg["ring"]
    added = []
    for _ in range(tries):
        s.tiers.append(s.cur)  # closed_audit reads the snapshots
        holes = closed_audit(s)
        s.tiers.pop()
        if not holes:
            break
        hx, hy = holes[0]
        # The nearest side's line
        sides = sorted([(abs(hy - y0), "back"), (abs(hy - y1), "front"), (abs(hx - x0), "left"), (abs(hx - x1), "right")])
        got = None
        for _, side in sides[:2]:
            along = 0 if side in ("back", "front") else 90
            for cls in ("Land_HBarrier_1_F", "Land_HBarrier_3_F", "Land_BagFence_Long_F", "Land_BagFence_Short_F", "Land_CncBarrier_F", "Land_HBarrier_5_F"):
                for du in (0, 0.4, -0.4, 0.8, -0.8, 1.2, -1.2, 1.8, -1.8, 2.4, -2.4):
                    for dv in (0, -0.4, 0.4, -0.8, 0.8):
                        for turn in (0, 90):
                            if side in ("back", "front"):
                                x, y = hx + du, (y0 if side == "back" else y1) + dv
                            else:
                                x, y = (x0 if side == "left" else x1) + dv, hy + du
                            it = s.O(cls, x, y, along + turn)
                            if s.ok(it):
                                s.cur.append(it)
                                s.tiers.append(s.cur)
                                left = closed_audit(s)
                                s.tiers.pop()
                                if not left or all(math.dist(h, (hx, hy)) > 1.0 for h in left):
                                    got = it
                                    break
                                s.cur.pop()
                        if got:
                            break
                    if got:
                        break
                if got:
                    break
            if got:
                break
        if not got:
            s.skipped.append(f"hole at {(hx, hy)}")
            break
        added.append(got)
    return added


def low_here(s, pt, centre, ln, gate):
    """Whether a 2-high piece centred at centre (along its line) would stand by the gate, a gun or the second door."""
    if gate is not None and abs(centre - gate) < ln / 2 + 2.5 + 1.5:
        return True
    c = pt(centre)
    a, b = pt(centre + 1.0)
    ux, uy = a - c[0], b - c[1]
    for (qx, qy), r, reach in s.low_spots:
        along = abs((qx - c[0]) * ux + (qy - c[1]) * uy)
        across = abs((qx - c[0]) * uy - (qy - c[1]) * ux)
        if along < ln / 2 + r and across < reach:
            return True
    return False


def static_post(s, role, prefs, gate_side, gate_at):
    """A static set into the ring: of the posts tried (each shifted along its line and turned a little), the one
    with the longest field of fire; the first reaching 30 m wins."""
    x0, x1, y0, y1 = s.cfg["ring"]
    best = None
    # The town's posts first, then every post round the ring (each metre of every line)
    scan = [(side, u, 0) for side in ("back", "front", "left", "right")
            for u in [v + 0.5 for v in range(int(x0 if side in ("back", "front") else y0), int(x1 if side in ("back", "front") else y1))]]
    # Strict first (well off the tower, trees, corners and the other gun); eased only when that finds no field
    for level in (0, 1):
        if best and best[0] >= 12:
            break
        for side, lat, skew in list(prefs) + scan:
            ox, oy = uv(OUT[side])
            for dl in ((0, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5, 2.0, -2.0, 3.0, -3.0) if skew or (side, lat, skew) in prefs else (0,)):
                u = lat + dl
                if side == gate_side and abs(u - gate_at) < 4.5:
                    continue
                ends = (x0, x1) if side in ("back", "front") else (y0, y1)
                if min(abs(u - e) for e in ends) < (3.0, 2.0)[level]:
                    continue  # Off the corners, or the next side's line is in its field of fire
                lx, ly = (u, y0 if side == "back" else y1) if side in ("back", "front") else (x0 if side == "left" else x1, u)
                if any(math.dist((lx, ly), q) < (9, 6)[level] for q in s.guns):
                    continue  # The other gun covers here: spread them over different approaches
                for dsk in (0, 15, -15, 30, -30, 45, -45):
                    if abs(((skew + dsk) + 180) % 360 - 180) > 20:
                        continue  # Square enough with its line that the bags, not the next H-barrier, are in front
                    d = OUT[side] + skew + dsk
                    if abs(((d - OUT[side]) + 180) % 360 - 180) > 60:
                        continue
                    fx, fy = uv(d)
                    bag = s.O("Land_BagFence_Round_F", lx + ox * 0.2, ly + oy * 0.2, d + 180)
                    gun = s.S(role, lx + ox * 0.2 - fx * 1.0, ly + oy * 0.2 - fy * 1.0, d)
                    gx, gy = lx + ox * 0.2 - fx * 1.0, ly + oy * 0.2 - fy * 1.0
                    hs = [s.t.ground_model(gx + ex * 1.3, gy + ey * 1.3) for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1), (0, 0))]
                    slope = max(hs) - min(hs)
                    if any(it[1] == "Land_BagBunker_Tower_F" and math.dist((gx, gy), s.t.to_model(it[2])[:2]) < (5.0, 3.2)[level] for it in s.placed):
                        continue  # Not beside the tower (its overhang and its man's line of fire)
                    trees = [s.t.to_model(o["pos"])[:2] for o in s.t.objs if o["kind"] == "tree"]
                    if any(math.dist((gx, gy), q) < (3.0, 1.8)[level] or math.dist((gx + fx * 4, gy + fy * 4), q) < (2.5, 1.2)[level] or
                           math.dist((gx + fx * 8, gy + fy * 8), q) < (2.0, 1.0)[level] for q in trees):
                        continue  # No tree trunk round the gun or just in front of it
                    if any(math.dist((gx, gy), (ax, ay)) < ar for ax, ay, ar in s.cfg.get("avoid", ())):
                        continue  # A post the game measured blocked
                    gw = s.t.to_world(gx, gy, 0)
                    if [h for h in s.t.hits(gw[0], gw[1], 3.5, 3.5, 0, 0) if h[0] == "wall"]:
                        continue  # Clear of old walls and buildings all round (the gun swings, its crew climbs on)
                    if slope > (0.25, 0.4)[level] or not s.ok(bag) or not s.ok(gun):
                        continue
                    n = len(s.cur)
                    s.cur += [bag, gun]
                    fire = s.ray(gx, gy, d, start=2.2, low=True)
                    del s.cur[n:]
                    if best is None or fire > best[0]:
                        best = (fire, bag, gun)
                    if fire >= 30:
                        break
                if best and best[0] >= 30:
                    break
            if best and (best[0] >= 30 or (best[0] >= 12 and (side, lat, skew) in prefs)):
                break  # The town's posts aim down a road: across it is enough
    if best is None:
        s.skipped.append(f"static {role}")
        return None
    s.cur += [best[1], best[2]]
    s.low_spots.append((tuple(s.t.to_model(best[1][2])[:2]), 1.8, 3.0))
    s.guns.append(tuple(s.t.to_model(best[1][2])[:2]))
    if best[0] < 30:
        s.skipped.append(f"static {role}: field of fire only {best[0]} m")
    return best[0]


def tier3(s):
    t, f0, f1 = s.t, s.f0, s.f1
    x0, x1, y0, y1 = s.cfg["ring"]
    gate_side = "back" if s.entry == "porch_s" else "front"
    gate_at = s.cfg.get("gate_at", s.D[0])
    line_at = y0 if gate_side == "back" else y1
    gate_dist = abs(line_at - s.D[1])
    # The gate: a bar gate in a 5 m gap of the line, square with the door
    s.add(s.O("Land_BarGate_F", gate_at, line_at, 0), "bar gate", lane_ok=True)
    # The raised post: a bag bunker tower beside the gate (the side away from the nest), its outer face in the line,
    # the marksman on its platform covering the approach and the gate
    ns = getattr(s, "nest_side", None) or 1
    inward = 1 if gate_side == "back" else -1
    tower = None
    # First choice: a corner of the gate's line, straddling the corner, the one whose platform sees furthest out
    # over the approach (diagonally out from the corner)
    corners = []
    for cx in (x0, x1):
        for k in (1.0, 1.6, 2.4, 3.2):
            tx = cx + (k if cx == x0 else -k)
            ty = line_at + inward * k
            out = (s.d + (45 if (cx == x1) == (s.d == 0) else -45)) % 360
            it = s.O("Land_BagBunker_Tower_F", tx, ty, out)
            if s.ok(it) and s.keeps_views([it]):
                n = len(s.cur)
                s.cur.append(it)
                z = t.ground_model(tx, ty) + TOWER_PLATFORM
                v = max(s.view(s.G("marksman", tx, ty, out + dd, z)) for dd in (0, 30, -30))
                del s.cur[n:]
                corners.append((v, tx, ty, out))
                break
    if corners and s.cfg.get("tower") != "gate":
        v, tx, ty, out = max(corners)
        if v >= 20:
            s.cur.append(s.O("Land_BagBunker_Tower_F", tx, ty, out))
            tower = (tx, ty)
    for sgn in ((-ns, ns) if not tower else ()):
        for off in (4.4, 5.0, 5.6, 6.2, 6.8, 7.4, 8.0, 8.6, 3.8):
            tx = s.D[0] + uv(s.d + 90)[0] * sgn * off
            if abs(tx) > 6.0:
                continue
            for dy in (1.9, 2.4, 3.0):
                ty = line_at + inward * dy
                if abs(ty) > 13.0:
                    continue
                it = s.O("Land_BagBunker_Tower_F", tx, ty, s.d)
                if s.ok(it) and s.keeps_views([it]):
                    s.cur.append(it)
                    tower = (tx, ty)
                    break
            if tower:
                break
        if tower:
            break
    if not tower:
        # Elsewhere in the yard by the house (the platform's man must stand within reach of the office)
        for ty in (-11.5, -10.5, 10.5, 11.5, -9.0, 9.0, -12.5, 12.5):
            for tx in (5.5, -5.5, 4.5, -4.5, 6.0, -6.0, 3.5, -3.5):
                it = s.O("Land_BagBunker_Tower_F", tx, ty, 180 if ty < 0 else 0)
                if s.ok(it) and s.keeps_views([it]):
                    s.cur.append(it)
                    tower = (tx, ty)
                    break
            if tower:
                break
    if tower:
        # The platform faces out over the tower's own +y (its -y side is the taller back): turn the tower to the
        # direction its man sees furthest, and stand him 0.4 m forward of the centre facing that way
        tw = next(it for it in s.cur if it[1] == "Land_BagBunker_Tower_F")
        s.cur.remove(tw)
        z = t.ground_model(*tower) + TOWER_PLATFORM
        base = (s.yaw(tw) - t.dir) % 360
        best = None
        for dd in (0, 30, -30, 60, -60, 90, -90, 135, -135, 180):
            td = (base + dd) % 360
            it = s.O("Land_BagBunker_Tower_F", tower[0], tower[1], td)
            if not s.ok(it):
                continue
            fx, fy = uv(td)
            s.cur.append(it)
            g = s.G("marksman", tower[0] + fx * 0.4, tower[1] + fy * 0.4, td, z)
            v = s.view(g)
            s.cur.pop()
            if best is None or v > best[0] + 2:
                best = (v, it, g)
        s.cur += [best[1], best[2]]
    else:
        s.skipped.append("tower")
    # The statics, each where its field of fire is longest; the lines stay 1-high round them and the second door
    s.low_spots = [(s.D2, 1.8, 7.0)]  # The second door's man looks out over the line in front of him
    s.guns = []
    s.fire = {}
    for role, prefs in s.cfg.get("statics", []):
        s.fire[role] = static_post(s, role, prefs, gate_side, gate_at)
    # The lines
    tall = s.cfg.get("tall", ())
    lines = {}
    for side in ("back", "front", "left", "right"):
        lines[side] = ring_side(s, side, gate_at if side == gate_side else None, side in tall)
    s.filled = fill_holes(s)
    # The chicane: a barrier inside the gate, offset so the way in dog-legs round it under the nest's guns
    off = -ns * 1.6
    if gate_dist >= 6.0:
        s.first([s.O("Land_HBarrier_3_F", *s.ef(gate_dist - a, off * k), s.d) for a in (3.0, 3.5, 2.6) for k in (1, 1.3)],
                "chicane", lane_ok=True)
    # The gate pair: behind the 1-high line either side of the gap, facing out
    for role, sgn in (("rifleman", 1), ("at", -1)):
        s.first([s.G(role, *s.ef(gate_dist - 1.9 - b, k * l), s.d + dd) for k in (sgn, -sgn) for b in (0, 0.5, 1.0)
                 for l in (3.6, 4.4, 5.2, 6.0, 7.0, 8.0) for dd in (0, k * 20)],
                f"gate {role}", see=8)
    # Upstairs: the MG on the other balcony, the officer in the office
    s.upstairs("mg_gunner", {"back": BACK_BALCONY}.get(s.cfg.get("mg_posts"), FRONT_BALCONY + BACK_BALCONY + WINDOW), "mg_gunner")
    s.cur.append(s.G("officer", 0.3, 4.5, 270, f1))
    # The porch / front door: a rifleman holding it
    if s.entry == "porch_s":
        s.first([s.G("rifleman", x, -5.8, d, f0) for x in (-3.9, -0.9, 0.9, 2.5) for d in (180, 210, 150)], "porch rifleman", see=6)
    else:
        s.first([s.G("rifleman", *s.ef(1.0, l), d) for l in (-1.6, 1.6, 2.2, -2.2) for d in (0, 30, 330)] +
                [s.G("rifleman", 4.1, 2.9, 90, f0)], "front rifleman", see=6)
    # An autorifleman behind a 1-high line (not the gate's), facing out over it
    order = sorted((k for k in lines if k != gate_side and lines[k]), key=lambda k: -len(lines[k]))
    cands = []
    for quiet in order:
        ox, oy = uv(OUT[quiet])
        for it in lines[quiet]:
            if it[1] in TALL:
                continue
            m = t.to_model(it[2])
            for sh in (0.0, -1.0, 1.0):
                px = m[0] - ox * 1.9 + (sh if quiet in ("back", "front") else 0)
                py = m[1] - oy * 1.9 + (sh if quiet in ("left", "right") else 0)
                cands.append(s.G("autorifleman", px, py, OUT[quiet]))
    s.first(cands, "line autorifleman", see=10)
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


def clip_audit(s):
    """Every ground thing of the top tier the game's clip rays would flag: [text]."""
    out = []
    for it in s.snapshots()[-1]:
        h = s.game_rays(it)
        if h:
            m = s.t.to_model(it[2])
            out.append(f"{it[1]}@({m[0]:.1f},{m[1]:.1f}) into {h}")
    return out


def line_audit(s, step=0.1):
    """Each ring side, end to end: its length, what closes it (the pieces on it, the neighbours, old walls, the
    office, the gate) and every open stretch over 0.3 m. Returns [(side, length, run, by_neighbours, gaps)]."""
    if "ring" not in s.cfg or s.t.cap < 3:
        return []
    x0, x1, y0, y1 = s.cfg["ring"]
    items = [it for it in s.snapshots()[-1] if it[0] == "object" and "ground" in it[4] and
             (barrierish(it[1]) or "Bunker" in it[1])]
    out = []
    for side in ("back", "front", "left", "right"):
        if side in ("back", "front"):
            fixed, a, c = (y0 if side == "back" else y1), x0, x1
            pt = lambda u, f=fixed: (u, f)
        else:
            fixed, a, c = (x0 if side == "left" else x1), y0, y1
            pt = lambda u, f=fixed: (f, u)
        n = int(round((c - a) / step))
        state, run_pts, nb_pts, gaps, open_from = [], 0, 0, [], None
        for k in range(n + 1):
            u = a + k * step
            x, y = pt(u)
            piece = next((it for it in items if s.inside(it, x, y)), None)
            nb = None
            if piece is None:
                if any(seg_rect((x - 0.15, y - 0.15), (x + 0.15, y + 0.15), r) or seg_rect((x - 0.15, y + 0.15), (x + 0.15, y - 0.15), r)
                       for kind, r in s.rects if kind in ("wall", "building", "rock")) or \
                        seg_rect((x, y), (x, y), s.OFFICE):
                    nb = True
            if piece is not None:
                run_pts += 1
            elif nb:
                nb_pts += 1
            closed = piece is not None or nb
            if not closed and open_from is None:
                open_from = u
            if closed and open_from is not None:
                if u - open_from > 0.3:
                    gaps.append((round(open_from, 1), round(u, 1)))
                open_from = None
        if open_from is not None and c - open_from > 0.3:
            gaps.append((round(open_from, 1), round(c, 1)))
        out.append((side, round(c - a, 1), round(run_pts * step, 1), round(nb_pts * step, 1), gaps))
    return out


def closed_audit(s, cell=0.25, man=0.25, reach=40.0):
    """Whether the top tier's yard is closed: a flood fill from the way in (a man, his shoulders 2 x man wide, on a
    cell m grid) through everything but the barrier pieces, the tower, the neighbours, old walls and the office.
    Returns [] when no man gets out, else where he crosses the ring's outline: [(x, y)], one per hole."""
    if "ring" not in s.cfg or s.t.cap < 3:
        return []
    x0, x1, y0, y1 = s.cfg["ring"]
    n = int(2 * reach / cell)
    idx = lambda v: int(round((v + reach) / cell))
    blocked = bytearray(n * n)
    shapes = [r for k, r in s.rects if k in ("wall", "building", "rock")] + [s.OFFICE]
    for it in s.snapshots()[-1]:
        if it[0] == "object" and "ground" in it[4] and (barrierish(it[1]) or "Bunker" in it[1]):
            shapes.append(s.corners(it))
    for r in shapes:
        xs, ys = [p[0] for p in r], [p[1] for p in r]
        poly = [r[0], r[1], r[3], r[2]]
        # Grown by the man's half width: test cell centres against the polygon pushed out by man (approximately: the
        # distance to the polygon)
        for i in range(max(idx(min(xs) - man - cell), 0), min(idx(max(xs) + man + cell), n - 1) + 1):
            for j in range(max(idx(min(ys) - man - cell), 0), min(idx(max(ys) + man + cell), n - 1) + 1):
                p = (i * cell - reach, j * cell - reach)
                if poly_dist(p, poly) <= man:
                    blocked[j * n + i] = 1
    sx, sy = s.ef(1.5, 0)
    start = (idx(sx), idx(sy))
    if blocked[start[1] * n + start[0]]:
        start = next(((i, j) for i, j in ((idx(sx + dx), idx(sy + dy)) for dx in (-1, 1, -2, 2) for dy in (0, -1, 1))
                      if not blocked[j * n + i]), start)
    holes = []
    for _ in range(6):
        # Breadth first, so the way out found is the shortest; it leaves the ring's outline at the hole
        prev = {start: None}
        todo = [start]
        out = None
        k = 0
        while k < len(todo):
            i, j = todo[k]
            k += 1
            x, y = i * cell - reach, j * cell - reach
            if not (x0 - 3 <= x <= x1 + 3 and y0 - 3 <= y <= y1 + 3):
                out = (i, j)
                break
            for a, b in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                if 0 <= a < n and 0 <= b < n and (a, b) not in prev and not blocked[b * n + a]:
                    prev[(a, b)] = (i, j)
                    todo.append((a, b))
        if out is None:
            break
        p, hole = out, None
        while p is not None:
            x, y = p[0] * cell - reach, p[1] * cell - reach
            if x0 - 0.5 <= x <= x1 + 0.5 and y0 - 0.5 <= y <= y1 + 0.5:
                hole = (round(x, 1), round(y, 1))
                break
            p = prev[p]
        hole = hole or (round(out[0] * cell - reach, 1), round(out[1] * cell - reach, 1))
        holes.append(hole)
        # Plug it (a 1.5 m disc) and look for the next
        hi, hj = idx(hole[0]), idx(hole[1])
        r = int(1.5 / cell)
        for a in range(hi - r, hi + r + 1):
            for b in range(hj - r, hj + r + 1):
                if 0 <= a < n and 0 <= b < n and math.hypot(a - hi, b - hj) <= r:
                    blocked[b * n + a] = 1
    return holes


def poly_dist(p, poly):
    """Distance from point p to a convex polygon (0 inside)."""
    inside = True
    best = 1e9
    sgn = None
    for k in range(len(poly)):
        a, b = poly[k], poly[(k + 1) % len(poly)]
        c = (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
        if sgn is None and c != 0:
            sgn = c > 0
        elif c != 0 and (c > 0) != sgn:
            inside = False
        vx, vy = b[0] - a[0], b[1] - a[1]
        t = max(0, min(1, ((p[0] - a[0]) * vx + (p[1] - a[1]) * vy) / (vx * vx + vy * vy or 1)))
        best = min(best, math.hypot(a[0] + t * vx - p[0], a[1] + t * vy - p[1]))
    return 0.0 if inside else best


def views(s):
    out = []
    for it in s.snapshots()[-1]:
        if it[0] in ("guard", "static"):
            m = s.t.to_model(it[2])
            out.append(f"{it[1]}@({m[0]:.1f},{m[1]:.1f})={s.view(it)}")
    return out


def show(s, r=24):
    t = s.t
    items = s.snapshots()[-1]
    marks = {}
    for it in items:
        if it[0] != "object":
            continue
        m = t.to_model(it[2])
        L, D = s.size(it)
        d = (s.yaw(it) - t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
        for i in range(-int(L), int(L) + 1):
            for j in range(-int(D), int(D) + 1):
                px, py = m[0] + i * 0.5 * cx[0] + j * 0.5 * cy[0], m[1] + i * 0.5 * cx[1] + j * 0.5 * cy[1]
                if abs(i * 0.5) <= L / 2 and abs(j * 0.5) <= D / 2:
                    c = {"Land_BarGate_F": "G", "Flag_NATO_F": "F", "Land_BagFence_Round_F": "(", "Land_HBarrier_Big_F": "B",
                         "Land_BagBunker_Tower_F": "T", "Land_Razorwire_F": "w"}.get(it[1], "H" if "HBarrier" in it[1] else "b" if "Bag" in it[1] else "o")
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
        print(f"{name} ({s.entry}): {report(s)}; skipped {s.skipped}; holes filled {len(getattr(s, 'filled', []))}")
        if "--audit" in sys.argv:
            for side, ln, run, nb, gaps in line_audit(s):
                print(f"   line {side:5}: {ln:5.1f} m; pieces {run:5.1f}, neighbours/walls/office {nb:5.1f}; open {gaps}")
            for c in clip_audit(s):
                print("   CLIP", c)
            holes = closed_audit(s)
            if s.t.cap >= 3:
                print("   closed:", "yes" if not holes else f"NO, a man gets out at {holes}")
        if "--views" in sys.argv:
            print("   views:", ", ".join(views(s)))
        if "--map" in sys.argv:
            print(show(s))
