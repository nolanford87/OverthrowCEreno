"""
Mayor's office layouts, group "villages" (Overthrow CE), pass 1: walls only (tools/officegen/DESIGN_BRIEF.md, "The work
is now split into passes"). The Land_House_Big_02 offices (a two-storey town house, the office upstairs). Run from the
repository root:
    python tools/officegen/drafting/villages.py [--map] [--audit] [town ...]
Writes tools/officegen/layouts/drafts/<town>.txt for each town (tl.write checks them first); --map prints each town's
top tier on a 1 m map (model coordinates, up = the office's front), --audit the tier 3 ring line by line (each gap
between what really closes it, the run of pieces there and what each end ties into), whether a man gets out (a flood
fill) and every piece the game's clip test would flag (its rays across the measured box).

The building (model coordinates): walls at x -5.3..5.3, y -5.9..5.8. On the ground floor:
  - the back porch (y -5..-6.5, under the back balcony from x -5 to 1): open to the back (-y) and at its west end
    (the main doorway, (-4.7, -6.2), facing -x); the house door at (-2.9, -4.3);
  - the front door at (0.1, 5.3), opening forward (+y), its steps out to y 7;
  - one ground-floor window, east (x 5, y 2.9).

The ladder for pass 1 (every tier keeps the one before; walls, H-barriers and sandbags only):
  1  nothing.
  2  sandbags on the house: a long bag along the porch's back edge on the porch floor (the men in the door and on
     the porch bunker behind it) and a short one across the porch's west mouth, leaving a way on at the corner; a
     long bag at the foot of the front steps; a long bag on the ground under the east window. Nothing in the yard.
  3  a tight ring round the house, its yard and what stands against it, closed all round with no opening (the
     entrances come in pass 2): H-barriers on a rectangle or a polygon per town, 2-high (Land_HBarrier_Big_F) laid
     first, 1-high ones (HBarrier_5/3/1) filling the rest, each piece 0.3-0.6 m into the one before. A line may end
     only on another line or a full-height city wall: a neighbour's probe box stands well outside its walls (round
     1 in the game: the man walked round the line's end), so a ring takes in the neighbours it touches. Where one
     can't be taken in, the line runs into its real walls as the top view shows them ("walls"), and where a
     neighbour's tie held in the game it's kept ("trust"). No piece over the back porch's steps (they run out about
     1.4 m per metre the porch stands above the ground, and the game walked a man down them over the pieces there).
     The house itself never closes the ring (its two doors would make a way through it).
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

TALL = ("Land_HBarrier_Big_F",)  # 2-high
HBARRIERS = ("Land_HBarrier_5_F", "Land_HBarrier_3_F", "Land_HBarrier_1_F")  # 1-high, longest first
OVERLAP = 0.45  # How far a piece runs into the one before it (or a wall, a building): the brief's 0.3-0.6 m
LENGTH_DEPTH = tl.CLASSES["Land_HBarrier_5_F"][1] / 2  # A 1-high line's half depth
CORNER = 0.9  # How far the back and front lines run past the corners: to the side lines' outer faces
# Real boxes the round 4 test measured that townlib's MEASURED lacks ([length, depth] m, boundingBoxReal)
MEASURED_MORE = {"Land_BagBunker_Tower_F": (6.4, 9.8), "Land_BagBunker_Small_F": (5.0, 5.7), "Land_HBarrier_Big_F": (9.0, 2.6),
                 "Land_HBarrierWall4_F": (5.7, 4.8), "Land_CncBarrier_stripes_F": (2.6, 0.4), "Land_CncBarrierMedium_F": (1.8, 1.8)}
# The pieces' lengths for spacing them: the shorter of townlib's size and the game's measured box (an upper bound), so a
# planned overlap is at least that in the game (HBarrier_1 measured 1.4 m, HBarrier_5 5.8 m)
LENGTH = {c: min(tl.CLASSES[c][0], tl.MEASURED.get(c, MEASURED_MORE.get(c, (99,)))[0]) for c in HBARRIERS + TALL}

# Per town (see also steps (x0, x1, more): the porch steps' zone, default (-6, 4, 1.6); plug False: no gap plugging,
# so a ring the game passed stays as it was; exit_back: no line nearer the back door than y -12.6 over x -4.5..3.5;
# keep [(x0, x1, y0, y1)]: areas no piece may enter; window False: no T2 bag under the east window): ring (the tier 3 yard: model x0, x1, y0, y1) or poly (its corners in order, every side along x or y); tall
# (the sides laid 2-high first: their names, or True for all); ties (models that close a line here though
# real_barrier() leaves them out: a damaged city wall that crosses a line, the pieces butting into it from both
# sides); trust (neighbours whose probe box closes a line: their ties held in the game) and trust_buildings (every
# solid building's); walls ([(model, (x0, x1, y0, y1))]: a neighbour's real walls in model coordinates, read off the
# top view, closing a line; the pieces into its probe box go in with "drop"); road_margin (how near a track's centre
# line a piece may stand, default 4 m); fill_flood ((cell, man) for the hole filler: Selakano's round 1, which the
# game passed); porch_west_x (the T2 bag across the porch's west mouth).
TOWNS = {
    # Round 1 in the game: the man walked round a line's end on a neighbour's box (its walls stand well inside it):
    # the ring takes in the neighbours it touched and closes on itself. Round 2: he walked over the back line where
    # it stood at the foot of the porch's steps: the back lines stand clear of them (the steps zone). Round 3: the way
    # out of the back door started at about (-0.3, -12.2), the house model's box: exit_back keeps lines beyond it
    "Alikampos": {"exit_back": True, "road_margin": 1.5, "poly": [(-31, -8.9), (-6.9, -8.9), (-6.9, -13.5), (4.9, -13.5), (4.9, -8.9), (8, -8.9), (8, 12), (-31, 12)], "tall": True},
    "Dorida": {"poly": [(-13.5, 10.7), (-13.5, -9.0), (-8.3, -9.0), (-8.3, -14.6), (17, -14.6), (17, 10.7)], "tall": True},
    # Its right-hand neighbour stands against the office and is boxed in by others, and the game walked a man through
    # it (round 2). The corridor between them is too narrow for a line (round 3 clipped it): the right line seals its
    # two mouths against the office's corners (into the neighbour's probe box, so with drop), leaving the corridor and
    # the neighbour outside; the left side's ties held in the game
    "Gravia": {"window": False, "keep": [(5.3, 7.3, -5.5, 5.4)], "trust": ("Land_i_House_Big_01_V2_F", "Land_i_Shop_01_V3_F", "Land_u_House_Small_02_V1_F"), "ties": ("city_8md_f.p3d",),
               "walls": [("Land_i_House_Big_01_V3_F", (6.7, 20.5, -6.4, 6.4))], "ring": (-9, 6.3, -13, 11.2), "tall": ("back", "front", "right")},
    # Its back porch opens onto a road (missing from the probe), and the game walks a man through pieces on that road:
    # accepted as closed by its design (the lead's call, pass1_check5), left as it is
    "Kore": {"ring": (-16, 17.5, -14, 12), "tall": ("back", "front", "left", "right")},
    "Lakka": {"trust_buildings": True, "ring": (-10, 10, -14, 12), "tall": ("back", "right", "left", "front")},
    # The shop on its right is walked through (rounds 2-4: in by its south side, out by its front door and down its front
    # steps, a landing 1.4 m up at x 9, to about y 17): no barrier, and the ring takes it in whole. Its dropped pieces
    # never held (rounds 2, 4, 5: the route crossed at each), so the front line stands past the shop's probe box, all
    # on the ground (y 20.2, on the street's middle, as Selakano's and Stavros' notches on their roads, which closed)
    "Neri": {"road_margin": 0.0, "window": False, "steps": (-6.0, 4.0, 1.0), "walls": [("Land_u_Shop_01_V1_F", None, (5.6, 13.8, 0.5, 12.2)), ("Land_i_Addon_04_V1_F", (-2.4, 4.3, 5.5, 11.8))],
             "poly": [(-10, -10.5), (9.6, -10.5), (9.6, -7.8), (15.3, -7.8), (15.3, 20.2), (-10, 20.2)], "tall": True},
    "Poliakko": {"poly": [(-18, -13), (7.3, -13), (7.3, 9.6), (-10.6, 9.6), (-10.6, 6.9), (-18, 6.9)], "tall": True},
    "Selakano": {"exit_back": True, "road_margin": 0.0, "poly": [(-17.5, -10.3), (-5.4, -10.3), (-5.4, -13.5), (4.4, -13.5), (4.4, -10.3), (15.5, -10.3), (15.5, 12), (-17.5, 12)],
                 "tall": True},
    # Its right side, the two neighbours, held in the game. Round 3: the way out of the back door started at about
    # (-0.1, -12), beyond the back line: the back line steps out past it (on the plaza's road)
    "Stavros": {"exit_back": True, "steps": (-3.0, 4.0, 0.6), "road_margin": 0.0, "trust": ("Land_u_House_Big_01_V1_F", "Land_i_House_Small_02_V3_F"),
                "poly": [(-8, 12), (-8, -7.8), (-5.4, -7.8), (-5.4, -13.5), (4.4, -13.5), (4.4, -9.6), (5.5, -9.6), (5.5, 12)], "tall": True},
    # Round 3: dropped pieces across the neighbour's front hung in the air; the front line stands clear of its box
    "Telos": {"road_margin": 3.0, "ring": (-21, 10.8, -14, 8.7), "tall": True},
    "Abdera": {},
    "Agios Konstantinos": {"porch_west_x": (-4.4,)},  # At -4.9 it floated 1.5 m: off the porch's west end
    "Galati": {},
    "Nifi": {},
    "Topolia": {},
}


def real_barrier(o):
    """Whether a probed thing could close a line by itself: a full-height city wall (4.2 m box, not a damaged "md"
    piece) or a solid building (only with TOWNS "trust" or "trust_buildings": their boxes stand well outside their
    walls). Not an addon (sheds, lean-tos and terraces, their boxes far bigger than their walls), a ruin
    or a damaged building, the stone walls (chest high), pipe and wire fences, low concrete walls, planters, wells."""
    m = o["model"].lower()
    if o["kind"] == "wall":
        return m.startswith("city") and "md_" not in m and "pillard" not in m
    if o["kind"] == "building":
        return m.startswith("land_") and not any(k in m for k in ("addon", "_d_", "land_d_", "dam", "slum"))
    return False


def edges(cfg):
    """The ring's straight lines: from "ring" (x0, x1, y0, y1) the back, front, left and right sides, or from "poly"
    (the corners in order, every side along x or y) its sides. Each {"name", "h" (along x), "fixed" (its y, or x),
    "a", "c" (its run along it), "inward" (the unit normal into the ring)}; along x first, then along y, each low to
    high."""
    if "poly" in cfg:
        pts = cfg["poly"]
        area = sum(p[0] * q[1] - q[0] * p[1] for p, q in zip(pts, pts[1:] + pts[:1]))
        out = []
        for p, q in zip(pts, pts[1:] + pts[:1]):
            h = abs(p[1] - q[1]) < 1e-6
            dx, dy = (1 if q[0] > p[0] else -1, 0) if h else (0, 1 if q[1] > p[1] else -1)
            inward = (-dy, dx) if area > 0 else (dy, -dx)
            fixed, a, c = (p[1], min(p[0], q[0]), max(p[0], q[0])) if h else (p[0], min(p[1], q[1]), max(p[1], q[1]))
            out.append({"name": f"{'y' if h else 'x'} {fixed:g} ({a:g}..{c:g})", "h": h, "fixed": fixed, "a": a, "c": c, "inward": inward})
        return sorted(out, key=lambda e: (not e["h"], e["fixed"]))
    x0, x1, y0, y1 = cfg["ring"]
    return [{"name": "back", "h": True, "fixed": y0, "a": x0, "c": x1, "inward": (0, 1)},
            {"name": "front", "h": True, "fixed": y1, "a": x0, "c": x1, "inward": (0, -1)},
            {"name": "left", "h": False, "fixed": x0, "a": y0, "c": y1, "inward": (1, 0)},
            {"name": "right", "h": False, "fixed": x1, "a": y0, "c": y1, "inward": (-1, 0)}]


def bounds(cfg):
    """The ring's outline box: x0, x1, y0, y1."""
    if "poly" in cfg:
        xs, ys = [p[0] for p in cfg["poly"]], [p[1] for p in cfg["poly"]]
        return min(xs), max(xs), min(ys), max(ys)
    return cfg["ring"]


def has_ring(s):
    return ("ring" in s.cfg or "poly" in s.cfg) and s.t.cap >= 3


def uv(d):
    """Model direction d as a unit vector (compass: 0 = +y, 90 = +x)."""
    r = math.radians(d)
    return math.sin(r), math.cos(r)


def is_piece(it):
    """An H-barrier of the ring: on the ground, or dropped onto it (into a neighbour's box, TOWNS "walls")."""
    return it[0] == "object" and "HBarrier" in it[1] and ("ground" in it[4] or "drop" in it[4])


def barrierish(cls):
    """Pieces that may overlap each other, the neighbours and old walls a little (townlib's barrier rule)."""
    return tl.is_barrier(cls) or "BagBunker" in cls


class Site:
    def __init__(self, t, cfg):
        self.t, self.cfg = t, cfg
        self.f0, self.f1 = t.floors[0], t.floors[-1]
        self.tiers, self.cur, self.skipped = [], [], []
        self.gone = []  # (tier index, item): a lower tier's item this tier and the ones above leave out
        for p, q in cfg.get("roads", ()):  # Roads the probe missed, read off the top view (model coordinates)
            t.roads.append({"type": "SEEN", "width": 10.0, "beg": t.to_world(p[0], p[1], 0), "end": t.to_world(q[0], q[1], 0)})
        # The probed walls, buildings and tree trunks as rectangles in model coordinates (centre, model dir, half
        # sizes), for a proper overlap test: a thin wall crossing a piece's middle has no corner inside it
        # The back porch's steps: they aren't in the house's footprint and run out from its edge (y -6.5) about 1.4 m
        # per metre the porch stands above the ground (a man walks down them over a piece standing there)
        rise = max(self.f0 - t.ground_model(x, -7.0) for x in (-4.0, -1.0, 2.0, 4.0))
        # The whole porch: round 2 in the game walked men out over pieces at x -4 to 0, 1 m beyond this estimate
        x0, x1, more = cfg.get("steps", (-6.0, 4.0, 1.6))
        self.keep = [[(x, y) for x in (x0, x1) for y in (-6.5 - 1.4 * max(rise, 0.0) - more, -6.5)]]
        for x0, x1, y0, y1 in cfg.get("keep", ()):  # A town's own keep-out areas (Gravia's corridor)
            self.keep.append([(x, y) for x in (x0, x1) for y in (y0, y1)])
        if cfg.get("exit_back"):
            # Round 3: the game's route out of the back door started at about (-0.3, -12.2), the house model's box
            # (its path down the steps), beyond a back line standing nearer: none in front of the porch nearer than -12.6
            self.keep.append([(x, y) for x in (-4.5, 3.5) for y in (-12.6, -6.5)])
        self.rects, self.names, self.walls = [], [], []
        for o in t.objs:
            if o["kind"] not in ("wall", "building", "rock", "tree"):
                continue
            b = o["box"]
            if o["kind"] == "tree":
                b = [-0.6, -0.6, 0.6, 0.6]
            cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
            dx, dy = tl.rot(cx, cy, o["dir"])
            m = t.to_model([o["pos"][0] + dx, o["pos"][1] + dy, 0])
            self.names.append(o["model"])
            md = (o["dir"] - t.dir) % 360
            hx, hy = (b[2] - b[0]) / 2, (b[3] - b[1]) / 2
            ax, ay = tl.rot(1, 0, md), tl.rot(0, 1, md)
            real = ((real_barrier(o) and (o["kind"] == "wall" or cfg.get("trust_buildings"))) or o["model"] in cfg.get("ties", ())
                    or o["model"] in cfg.get("trust", ()))
            seen = next((w for mdl, w, near in ((e[0], e[1], e[2] if len(e) > 2 else e[1]) for e in cfg.get("walls", ())) if mdl == o["model"] and
                         math.dist(((near[0] + near[1]) / 2, (near[2] + near[3]) / 2), (m[0], m[1])) < 8), False)
            if seen is None:
                # Open underneath (the game walked a man through it): no barrier, and pieces may go into its box
                self.walls.append(o["model"])
                continue
            if seen:
                # Its real walls as the top view shows them (the probe's box takes in its eaves, porches and steps)
                x0, x1, y0, y1 = seen
                self.rects.append(("real building", [(x, y) for x in (x0, x1) for y in (y0, y1)]))
                self.walls.append(o["model"])
                continue
            self.rects.append((o["kind"] if not real else "real " + o["kind"], [(m[0] + sx * hx * ax[0] + sy * hy * ay[0], m[1] + sx * hx * ax[1] + sy * hy * ay[1])
                                          for sx in (-1, 1) for sy in (-1, 1)]))

    # ---- geometry
    @property
    def placed(self):
        return [it for tier in self.tiers for it in tier if not any(it is g for k, g in self.gone)] + self.cur

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

    def corners(self, it, core=False, real=False, spacing=False):
        """An item's footprint (4 corners, model coordinates): its class size; core, a barrier's middle only; real,
        the game's measured box; spacing, an H-barrier at the length it's spaced by (LENGTH: what surely stands)."""
        t = self.t
        m = t.to_model(it[2])
        L, D = self.size(it, core)
        if spacing and it[1] in LENGTH:
            L = LENGTH[it[1]]
        if real and it[0] == "object":
            L, D = (tl.MEASURED.get(it[1]) or MEASURED_MORE.get(it[1]) or (L, D))[:2]
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
    WALLS = [(-5.3, -5.0), (-5.3, 5.8), (5.3, -5.0), (5.3, 5.8)]  # Its walls (the back porch, y -5 to -6.5, left out)

    def game_rays(self, it):
        """The in-game clip test (fn_checkLayouts): two rays across the diagonals of a ground thing's footprint at its
        real (measured, upper-bound) size; a barrier's only over its middle (0.6 m off each end, half its depth).
        Returns what they run through: [(kind, where)] of the probed walls/buildings/rocks and the office."""
        if ("ground" not in it[4] and not is_piece(it)) or it[0] == "guard" or it[1] == "Flag_NATO_F":
            return []  # The flag's box takes in its cloth's swing: it has its own rule (ok())
        what = it[1] if it[0] == "object" else f"static {it[1]}"
        L, D = next((v[:2] for k, v in tl.MEASURED.items() if (k == what or k.startswith(what + " (")) and k != "Land_BarGate_F"),
                    MEASURED_MORE.get(it[1]) or tl.CLASSES.get(it[1], (1.4, 2.3)))  # The bar gate's real box takes in its arm's swing: its posts only
        if it[0] == "object" and tl.is_barrier(it[1]):
            ix, iy = max(L / 2 - 0.6, 0.1), D / 4
        else:
            ix, iy = 0.4 * L, 0.4 * D
        m = self.t.to_model(it[2])
        d = (self.yaw(it) - self.t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)

        def rays(ix, iy):
            P = lambda a, b: (m[0] + a * ix * cx[0] + b * iy * cy[0], m[1] + a * ix * cx[1] + b * iy * cy[1])
            return [(P(-1, -1), P(1, 1)), (P(-1, 1), P(1, -1))]
        out = []
        office = [(x + (0.03 if x > 0 else -0.03), y + (0.03 if y > 0 else -0.03)) for x, y in self.OFFICE]  # A margin
        if it[1] == "Land_BagBunker_Tower_F":
            # Its 6.4 x 9.8 box takes in more than the sandbags: round 4 clipped no wall or building beyond 2 m of a
            # tower's centre, but the office from 1.8 and 2.6 m off it (not from 2.8 m): its centre 2.7 m clear of the house
            ix = iy = 2.0
            if poly_dist(m[:2], [office[0], office[1], office[3], office[2]]) < 2.7:
                out.append(("office", (0.0, 0.1)))
        for kind, r in self.rects + ([] if out else [("office", office)]):
            if kind == "tree":
                continue  # The game's test leaves trees out
            if any(seg_rect(a, b, r) for a, b in rays(ix, iy)):
                out.append((kind, tuple(round(v, 1) for v in rect_centre(r))))
        return out

    def on_road(self, x, y):
        w = self.t.to_world(x, y, 0)
        return any(d <= min(self.cfg.get("road_margin", 4.0), s["width"] / 2) for d, s in self.t.roads_near(w[0], w[1], 10))

    # ---- the per-item rules
    def ok(self, it):
        t = self.t
        probs = [p for p in tl.check(t, [[it, it]] * t.cap) if "guards" not in p and "tiers" not in p]
        # Into the box of a building whose real walls are known (TOWNS "walls") and no further: it goes in with
        # "drop" (onto the ground under it), as townlib's box test can't tell those walls from the eaves, porches and
        # steps its box takes in; the rules below and the game's clip test judge it against the real walls
        drop = bool(probs) and all(re.findall(r"'(Land_\w+)'", p) and set(re.findall(r"'(Land_\w+)'", p)) <= set(self.walls)
                                   for p in probs)
        if probs and not drop:
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
            if self.sat(self.corners(it), self.OFFICE, 0.35):
                return False  # Into the house itself (its whole footprint, beyond the 0.3 m the box is padded by)
            if is_piece(it) and any(self.sat(self.corners(it), k, 0.0) for k in self.keep):
                return False  # Over the back porch's steps, or nearer than where the way out of the back door ends
            if it[1] != "Land_BagBunker_Tower_F" and self.sat(self.corners(it, real=True), self.WALLS, 0.05):
                return False  # Its real (measured) footprint into the house's walls
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
        if drop:
            it[4] = ["drop"]  # At the terrain's height (round 3: dropped from 1.5 m up, they hung there)
        return True

    def add(self, it, note=""):
        if self.ok(it):
            self.cur.append(it)
            return it
        if note:
            self.skipped.append(note)
        return None

    def tier(self):
        self.tiers.append(self.cur)
        self.cur = []

    def snapshots(self):
        out, acc = [], []
        for n, tier in enumerate(self.tiers):
            acc = [it for it in acc if not any(it is g for k, g in self.gone if k == n)] + tier
            out.append(list(acc))
        return out

    # ---- shorthands
    def O(self, cls, x, y, mdir, z=None, flag=False):
        return tl.obj(self.t, cls, x, y, z, mdir % 360, flag)

    @property
    def closers(self):
        """The real barriers (real_barrier) as rectangles: what may close a stretch of the ring: [(model, rect)]."""
        return [(n, r) for (k, r), n in zip(self.rects, self.names) if k.startswith("real")]


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


def ring_side(s, e, tall=False, phase="fill"):
    """H-barrier pieces along one side of the ring, overlapping so the line is unbroken. Where tall, first the 2-high
    pieces, wherever one fits, each stepping in up to 1.2 m to clear an old wall (phase "tall", run for every side
    first); then (phase "fill") 1-high pieces fill what is still open. Every piece starts OVERLAP into what is
    before it (a piece or a real barrier). The back and front lines run on past the corners to the side lines' outer
    faces; the side lines butt into them. Returns the pieces placed."""
    fixed, inward = e["fixed"], e["inward"]
    if e["h"]:
        a, c, mdir = e["a"] - CORNER, e["c"] + CORNER, 0
        pt = lambda u: (u, fixed)
        cut = lambda u, w: ((u, fixed - w), (u, fixed + w))
    else:
        a, c, mdir = e["a"], e["c"], 90
        pt = lambda u: (fixed, u)
        cut = lambda u, w: ((fixed - w, u), (fixed + w, u))
    old = [r for n, r in s.closers]

    def covered(u):
        """The line closed at u: a piece across it (within 1 m) or a real barrier on it."""
        p, q = cut(u, 1.0)
        if any(seg_rect(p, q, s.corners(it, spacing=True)) for it in s.cur if it[0] == "object" and is_piece(it)):
            return True
        p, q = cut(u, 0.3)
        return any(seg_rect(p, q, r) for r in old)

    # The line's far end: short of what already closes it there (the next side's line), OVERLAP into it
    end = c
    while end > a and covered(end):
        end -= 0.1
    end = min(c, end + OVERLAP) if end < c else c
    placed = []
    if tall and phase == "tall":
        u = a
        while u < end and covered(u + 0.05):
            u += 0.1
        u = max(a, u - OVERLAP) if u > a else a
        stop = end
        if not e["h"]:
            # Where the back or front line isn't there yet (it comes 1-high in the fill), leave its half depth
            # free at the corner: it runs on to the corner and this piece's end butts into its side
            if u == a:
                u = a + LENGTH_DEPTH - OVERLAP
            if stop == c:
                stop = c - LENGTH_DEPTH + OVERLAP
        while stop - u > 3.0:
            got = None
            if u + LENGTH[TALL[0]] <= stop + 0.05:
                for inset in (0.0, 0.4, 0.8, 1.2):
                    x, y = pt(u + LENGTH[TALL[0]] / 2)
                    got = s.add(s.O("Land_HBarrier_Big_F", x + inward[0] * inset, y + inward[1] * inset, mdir))
                    if got:
                        break
            if got:
                placed.append(got)
                u += LENGTH[TALL[0]] - OVERLAP
            else:
                u += 0.25
    if phase != "fill":
        return placed
    u = a
    while end - u > 0.05:
        if covered(u + 0.1):
            u += 0.1
            continue
        start = max(a, u - OVERLAP) if u > a else a  # OVERLAP into what is before it
        # This run: on to what closes the line next (OVERLAP into it) or the line's end, tiled exactly
        v = u
        while v < end and not covered(v + 0.1):
            v += 0.1
        run_end = min(end, v + OVERLAP) if v < end else end
        plan = tile(run_end - start)
        k, done = start, start
        for cls, ln, ov in plan:
            got = None
            for inset in (0.0, 0.4, 0.8):
                x, y = pt(k + ln / 2)
                got = s.add(s.O(cls, x + inward[0] * inset, y + inward[1] * inset, mdir))
                if got:
                    break
            if not got:
                break  # Something in the way: the greedy fill below takes it from here
            placed.append(got)
            done = k + ln
            k += ln - ov
        else:
            u = run_end
            continue
        # Greedy: the longest piece that fits here, then on
        u = max(u, done)
        start = max(a, u - OVERLAP) if u > a else a
        room = end - start
        got = None
        for cls, ln in ((c, LENGTH[c]) for c in HBARRIERS):
            if ln > room + 0.15 and cls != "Land_HBarrier_1_F":
                continue
            # On the line, or stepped in up to 0.8 m (off a road's edge, round a tree trunk) so a longer piece fits;
            # slid back 0.15 m over the piece before when what is ahead leaves only a slot
            for back, inset in [(b, i) for i in (0.0, 0.4, 0.8) for b in (0.0, 0.15)]:
                x, y = pt(start - back + ln / 2)
                got = s.add(s.O(cls, x + inward[0] * inset, y + inward[1] * inset, mdir))
                if got:
                    break
            if got:
                break
        if got:
            placed.append(got)
            u = start - back + ln  # Its end: the next piece starts OVERLAP back over it
        else:
            u += 0.2  # Blocked here (a neighbour, a wall, a road): a bit further on
    return placed


def tile(R):
    """1-high pieces covering a run of R m end to end, each joint overlapping 0.3-0.6 m (the same for all), the last
    running no more than 0.15 m past R: [(class, length, overlap)], longest first; the fewest pieces, then the joints
    nearest OVERLAP. Where no set fits exactly, the one overrunning least (never one leaving a gap)."""
    best = None
    for n5 in range(9):
        for n3 in range(4):
            for n1 in range(4):
                n = n5 + n3 + n1
                if not n:
                    continue
                S = sum(LENGTH[c] * k for c, k in zip(HBARRIERS, (n5, n3, n1)))
                if n == 1:
                    if S < R - 0.05:
                        continue
                    ov, over = OVERLAP, max(0.0, S - R - 0.15)
                else:
                    most = (S - R) / (n - 1)  # The joints can't overlap more than this without a gap
                    if most < 0.3 - 1e-6:
                        continue
                    ov = min(max(OVERLAP, (S - R - 0.15) / (n - 1)), most, 0.6)
                    over = max(0.0, S - (n - 1) * ov - R - 0.15)
                key = (round(over, 2), n, abs(ov - OVERLAP), n1)
                if best is None or key < best[0]:
                    best = (key, [c for c, k in zip(HBARRIERS, (n5, n3, n1)) for _ in range(k)], ov)
    return [(c, LENGTH[c], best[2]) for c in best[1]]


def plug_gaps(s, band=0.3):
    """Every stretch of a line no piece or real barrier crosses (within band m of it, past the corners' half depth):
    an HBarrier_1 across it, on the line or stepped up to 0.8 m off it. The flood fill can miss a slot that opens
    onto the house's footprint (Telos' front, round 2: a man walked out of the front door into it). Returns the
    pieces added."""
    added = []
    old = [r for n, r in s.closers]
    for e in edges(s.cfg):
        fixed = e["fixed"]
        cut = (lambda u, w: ((u, fixed - w), (u, fixed + w))) if e["h"] else (lambda u, w: ((fixed - w, u), (fixed + w, u)))
        pt = (lambda u: (u, fixed)) if e["h"] else (lambda u: (fixed, u))
        u, open0 = e["a"] + LENGTH_DEPTH, None
        while u <= e["c"] - LENGTH_DEPTH + 0.05:
            p, q = cut(u, band)
            shut = any(seg_rect(p, q, s.corners(it, spacing=True)) for it in s.cur if is_piece(it)) or any(seg_rect(p, q, r) for r in old)
            if not shut and open0 is None:
                open0 = u
            if (shut or u + 0.05 > e["c"] - LENGTH_DEPTH) and open0 is not None:
                mid = (open0 + u) / 2
                for du in (0, 0.2, -0.2, 0.4, -0.4):
                    for dv in (0, 0.4, -0.4, 0.8, -0.8):
                        x, y = pt(mid + du)
                        it = s.add(s.O("Land_HBarrier_1_F", x + e["inward"][0] * dv, y + e["inward"][1] * dv, 0 if e["h"] else 90))
                        if it:
                            added.append(it)
                            break
                    else:
                        continue
                    break
                else:
                    s.skipped.append(f"gap at {pt(mid)}")
                open0 = None
            u += 0.05
    return added


def fill_holes(s, tries=10):
    """Close every hole a man could slip through (closed_audit): an H-barrier on the ring's line at the hole (or up
    to 1.2 m off it), overlapping the pieces either side at their ends. Returns the pieces added."""
    added = []
    for _ in range(tries):
        s.tiers.append(s.cur)  # closed_audit reads the snapshots
        holes = closed_audit(s, *s.cfg.get("fill_flood", ()))
        s.tiers.pop()
        if not holes:
            break
        hx, hy = holes[0]
        # The nearest lines
        near = sorted(edges(s.cfg), key=lambda e: math.hypot(*(((hx - min(max(hx, e["a"]), e["c"])), hy - e["fixed"]) if e["h"] else
                                                               (hx - e["fixed"], hy - min(max(hy, e["a"]), e["c"])))))
        got = None
        for e in near[:2]:
            along = 0 if e["h"] else 90
            for cls in ("Land_HBarrier_1_F", "Land_HBarrier_3_F", "Land_HBarrier_5_F"):
                for du in (0, 0.4, -0.4, 0.8, -0.8, 1.2, -1.2, 1.8, -1.8, 2.4, -2.4):
                    for dv in (0, -0.4, 0.4, -0.8, 0.8, -1.2, 1.2):
                        for turn in (0, 90):
                            if e["h"]:
                                x, y = hx + du, e["fixed"] + dv
                            else:
                                x, y = e["fixed"] + dv, hy + du
                            it = s.O(cls, x, y, along + turn)
                            if s.ok(it):
                                s.cur.append(it)
                                s.tiers.append(s.cur)
                                left = closed_audit(s, *s.cfg.get("fill_flood", ()))
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


def tier1(s):
    s.tier()  # Pass 1: no cover at all


def tier2(s):
    """Sandbags on the house, nothing in the yard: the porch's back edge and west mouth (on the porch floor), the foot
    of the front steps, under the east window."""
    f0 = s.f0
    posts = [
        ("porch", [s.O("Land_BagFence_Long_F", x, y, 0, f0) for y in (-6.0, -5.8, -6.2) for x in (-1.6, -1.3, -1.9)]),
        ("porch", [s.O("Land_BagFence_Short_F", x, y, 90, f0) for x in s.cfg.get("porch_west_x", (-4.9, -4.7)) for y in (-5.6, -5.4)]),
        ("front", [s.O("Land_BagFence_Long_F", 0.1, y, 0) for y in (7.6, 7.9, 8.2)]),
        ("window", [s.O("Land_BagFence_Long_F", x, 2.9, 90) for x in (5.9, 6.1, 6.3)]),
    ]
    for key, cands in posts:
        if s.cfg.get(key, True) and not next((c for c in cands if s.add(c)), None):
            s.skipped.append(f"T2 {key} bags")
    s.tier()


def tier3(s):
    """The ring: every side's 2-high pieces first, then the 1-high fill, then whatever hole a man still finds."""
    tall = s.cfg.get("tall", ())
    es = edges(s.cfg)
    # A tier 2 sandbag standing on a line (Telos' front door bag) gives way to it
    for it in [i for tier in s.tiers for i in tier if "BagFence" in i[1]]:
        m = s.t.to_model(it[2])
        if poly_dist(m[:2], [s.OFFICE[0], s.OFFICE[1], s.OFFICE[3], s.OFFICE[2]]) > 0 and any(abs((m[1] if e["h"] else m[0]) - e["fixed"]) < 1.2 and e["a"] - 1 <= (m[0] if e["h"] else m[1]) <= e["c"] + 1 for e in es):
            s.gone.append((len(s.tiers), it))
    istall = lambda e: tall is True or e["name"] in tall
    s.lines = {e["name"]: ring_side(s, e, istall(e), "tall") for e in es}
    for e in es:
        s.lines[e["name"]] += ring_side(s, e, istall(e), "fill")
    s.plugged = plug_gaps(s) if s.cfg.get("plug", True) else []
    s.filled = fill_holes(s)
    s.tier()


def build(name):
    t = tl.load()[name]
    s = Site(t, TOWNS[name])
    tier1(s)
    tier2(s)
    if has_ring(s):
        tier3(s)
    return s


def report(s):
    out = []
    for n, items in enumerate(s.snapshots(), 1):
        kinds = {}
        for i in items:
            kinds[i[1]] = kinds.get(i[1], 0) + 1
        out.append(f"T{n}: {len(items)} things" + (" (" + ", ".join(f"{v} {k[5:-2]}" for k, v in sorted(kinds.items())) + ")" if kinds else ""))
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


def overlap_audit(s):
    """Every pair of top-tier H-barriers whose footprints overlap, checked against the brief: overlapping at their
    ends only, 0.3-0.6 m. A pair passes when the overlap reaches an end of both pieces (a straight joint, or a corner
    where one butts into the other's end) and runs no more than 0.65 m along at least one of them. Returns [text]
    for the pairs that don't."""
    out = []
    items = [it for it in s.snapshots()[-1] if it[0] == "object" and "HBarrier" in it[1]]

    def along(p, other):
        """Where other overlaps p along p's length: (reaches p's end, length)."""
        m = s.t.to_model(p[2])
        L = LENGTH[p[1]]
        ax = tl.rot(1, 0, (s.yaw(p) - s.t.dir) % 360)
        us = [(c[0] - m[0]) * ax[0] + (c[1] - m[1]) * ax[1] for c in other]
        lo, hi = max(min(us), -L / 2), min(max(us), L / 2)
        return lo <= -L / 2 + 0.3 or hi >= L / 2 - 0.3, hi - lo  # Within 0.3 m of the end (the real boxes differ that much)

    for i, a in enumerate(items):
        for b in items[i + 1:]:
            pa, pb = s.corners(a, spacing=True), s.corners(b, spacing=True)
            if not s.sat(pa, pb, 0.02):
                continue
            (ea, la), (eb, lb) = along(a, pb), along(b, pa)
            if not (ea and eb and min(la, lb) <= 0.65):
                ma, mb = s.t.to_model(a[2]), s.t.to_model(b[2])
                out.append(f"{a[1][5:-2]}@({ma[0]:.1f},{ma[1]:.1f}) x {b[1][5:-2]}@({mb[0]:.1f},{mb[1]:.1f}): "
                           f"{la:.1f} m along the first{'' if ea else ' (mid-piece)'}, {lb:.1f} m along the second{'' if eb else ' (mid-piece)'}")
    return out


def line_audit(s, step=0.1, band=1.2):
    """Each ring side, corner to corner, cut into the gaps the pieces have to close: the stretches between what
    already closes the line (a real barrier within band m of it, or the next side's line at a corner). Per gap: its length, the length of line the pieces cover there, how far the pieces run past its ends
    (onto what they tie into) and any stretch left open. Per side: the metres closed 2-high, 1-high and by the real
    barriers ("neighbours"). Returns [(side, span, {kind: m}, [gap dicts])]."""
    if not has_ring(s):
        return []
    items = [it for it in s.snapshots()[-1] if it[0] == "object" and is_piece(it)]
    old = s.closers

    def kind_of(cls):
        return "2-high" if cls in TALL else "1-high"

    out = []
    for e in edges(s.cfg):
        side, fixed, a, c = e["name"], e["fixed"], e["a"], e["c"]
        if e["h"]:
            cut = lambda u, f=fixed: ((u, f - band), (u, f + band))
        else:
            cut = lambda u, f=fixed: ((f - band, u), (f + band, u))
        n = int(round((c - a) / step))
        marks = []
        for k in range(n + 1):
            u = a + k * step
            p, q = cut(u)
            hit = [name for name, r in old if seg_rect(p, q, r)]
            if hit:
                marks.append(("old", hit[0]))
                continue
            hit = [it for it in items if seg_rect(p, q, s.corners(it, spacing=True))]
            marks.append(("piece", kind_of(hit[0][1])) if hit else ("open", None))
        tally = {}
        for m, kd in marks:
            key = kd if m == "piece" else ("neighbours" if m == "old" else "open")
            tally[key] = round(tally.get(key, 0) + step, 1)
        # The gaps: runs between "old" marks (the side's ends count as tied: the next side's line is there)
        gaps, start = [], None
        for k, (m, kd) in enumerate(marks + [("old", None)]):
            if m != "old" and start is None:
                start = k
            elif m == "old" and start is not None:
                seg = marks[start:k]
                u0, u1 = a + start * step, a + (k - 1) * step
                cover = sum(step for mm, _ in seg if mm == "piece")
                opens, o0 = [], None
                for j, (mm, _) in enumerate(seg + [("piece", None)]):
                    if mm == "open" and o0 is None:
                        o0 = j
                    elif mm != "open" and o0 is not None:
                        if (j - o0) * step > 0.3:
                            opens.append((round(u0 + o0 * step, 1), round(u0 + j * step, 1)))
                        o0 = None
                # How far the pieces covering the gap's ends run past them
                def reach(u, d):
                    k2 = 0
                    while True:
                        p, q = cut(u + d * (k2 + 1) * step)
                        if not any(seg_rect(p, q, s.corners(it, spacing=True)) for it in items) or k2 > 40:
                            return round(k2 * step, 1)
                        k2 += 1
                tie0 = "corner" if start == 0 else marks[start - 1][1]
                tie1 = "corner" if k == len(marks) else marks[k][1]
                gaps.append({"from": round(u0, 1), "to": round(u1 + step, 1), "length": round(u1 - u0 + step, 1),
                             "covered": round(cover, 1), "open": opens, "ties": (tie0, tie1),
                             "past": (reach(u0, -1) if marks[start][0] == "piece" else None,
                                      reach(u1, 1) if marks[k - 1][0] == "piece" else None)})
                start = None
        out.append((side, round(c - a, 1), tally, gaps))
    return out


def closed_audit(s, cell=0.125, man=0.24, reach=None):
    """Whether the top tier's yard is closed: a flood fill from the way in (a man, his shoulders 2 x man wide, on a
    cell m grid: a gap of 0.5 m lets him through) from all round the house through everything but the H-barriers, the real barriers and the house
    (the low walls, fences, addons and ruins don't stop him).
    Returns [] when no man gets out, else where he crosses the ring's outline: [(x, y)], one per hole."""
    if not has_ring(s):
        return []
    x0, x1, y0, y1 = bounds(s.cfg)
    reach = reach or max(abs(x0), abs(x1), abs(y0), abs(y1)) + 5.0
    n = int(2 * reach / cell)
    idx = lambda v: int(round((v + reach) / cell))
    blocked = bytearray(n * n)
    shapes = [r for n, r in s.closers] + [s.OFFICE]
    for it in s.snapshots()[-1]:
        if it[0] == "object" and is_piece(it):
            shapes.append(s.corners(it, spacing=True))
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
    # Every free cell within 1 m of the house: the doors are on two sides of it
    starts = [(i, j) for i in range(idx(-7.0), idx(7.0) + 1) for j in range(idx(-8.5), idx(8.5) + 1)
              if not blocked[j * n + i] and poly_dist((i * cell - reach, j * cell - reach), [s.OFFICE[0], s.OFFICE[1], s.OFFICE[3], s.OFFICE[2]]) <= 1.0]
    holes = []
    for _ in range(6):
        # Breadth first, so the way out found is the shortest; it leaves the ring's outline at the hole
        prev = {st: None for st in starts}
        todo = list(starts)
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
        tl.write(s.t, s.snapshots())
        print(f"{name}: {report(s)}; skipped {s.skipped}; holes filled {len(getattr(s, 'filled', []))}")
        if "--audit" in sys.argv:
            for side, span, tally, gaps in line_audit(s):
                print(f"   line {side:5}: {span:5.1f} m: " + ", ".join(f"{k} {v}" for k, v in sorted(tally.items())))
                for g in gaps:
                    print(f"      gap {g['from']:6.1f}..{g['to']:6.1f} ({g['ties'][0]} - {g['ties'][1]}): {g['length']:5.1f} m, "
                          f"pieces {g['covered']:5.1f} m, past the ends {g['past']}" + (f", OPEN {g['open']}" if g["open"] else ""))
            for c in clip_audit(s):
                print("   CLIP", c)
            for c in overlap_audit(s):
                print("   OVERLAP", c)
            if has_ring(s):
                holes = closed_audit(s)
                print("   closed:", "yes" if not holes else f"NO, a man gets out at {holes}")
        if "--map" in sys.argv:
            print(show(s))
