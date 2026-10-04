"""
Mayor's office layouts, group "strongholds" (Overthrow CE): the four 5-tier towns.
  Kavala, Pyrgos   Land_Offices_01_V1_F, the tower block on its podium (the showpieces)
  Athira, Zaros    Land_House_Big_01, the two-storey house with the veranda
Run from the repository root:
    python tools/officegen/drafting/strongholds.py [town ...] [--map N] [--log]
Writes tools/officegen/layouts/drafts/<town>.txt (tl.write checks each first) and prints SHORT for every static
whose field of fire ends within 15 m and every guard whose view ends within 4 m (an approximation of the in-game
layout check: buildings, walls and pipe fences, the office, the layout's tall pieces, rising ground; a roof gun
must stand 2.4 m back from the parapet). --map N prints tier N over the
probe's map (1 m cells; --audit prints every barrier run's audit): H low H-barrier, W tall wall (Mil wall, HBarrierWall), B bunker, G gate, b sandbags,
w razor wire, x hedgehog, c concrete barrier, T bag tower, g guard, S static, f furniture/flag, ~ ^ $ on a floor; capitals of the probe:
# building (its real walls), % its box beyond them, = wall, : road, O the office.

Everything below is in the office's MODEL coordinates (x right, y forward out of the model's front; mdir 0 = +y,
90 = +x). Both buildings' main doors face model -y, so in the notes "south" is -y, "east" +x, "north" +y, "west" -x.

The ladder (DESIGN_BRIEF.md), the same in all four:
  T1 police: 2-3 gendarmes, the desk, chair and map board, the flag.
  T2 noticeable: every door held from real cover (a C of sandbags square with the main door), upper windows.
  T3 compound: the open sides closed (the neighbouring buildings and walls do most of it), a controlled gate,
     two statics with fields of fire down the approaches, overwatch upstairs.
  T4 fort: a continuous perimeter, bunkers at its corners, a chicane in front of the gate, wire and hedgehog belts
     on the approaches inside the guns' arcs, four statics whose arcs cross, posts on the roof/upper floor.
  T5 stronghold: checkpoints on every approach road (an H-barrier wall across one lane and a concrete block
     across the other, staggered: a vehicle serpentine), mortar and AT, and the office's inside a kill zone
     (barricades channelling anyone who gets in into a pocket an MG and riflemen cover from two sides, every room
     and the stairs held).
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import townlib as tl  # noqa: E402

# The pieces
SHORT, LONG, ROUND, CORNER = "Land_BagFence_Short_F", "Land_BagFence_Long_F", "Land_BagFence_Round_F", "Land_BagFence_Corner_F"
HB1, HB3, HB5, HBBIG = "Land_HBarrier_1_F", "Land_HBarrier_3_F", "Land_HBarrier_5_F", "Land_HBarrier_Big_F"
HBW4, HBW6, HBWC = "Land_HBarrierWall4_F", "Land_HBarrierWall6_F", "Land_HBarrierWall_corner_F"
MIL = "Land_Mil_WallBig_4m_F"
CITYGATE, BARGATE = "Land_WallCity_01_gate_grey_F", "Land_BarGate_F"
WIRE, HOG = "Land_Razorwire_F", "Land_CzechHedgehog_01_F"
CNC, CNC4, JERSEY = "Land_CncBarrierMedium_F", "Land_CncBarrierMedium4_F", "Land_CncBarrier_F"
TOWER_TOP = 3.4  # The bag tower's platform over the ground (measured in the game)
BUNKER, TOWER = "Land_BagBunker_Small_F", "Land_BagBunker_Tower_F"
DESK, CHAIR, BOARD, FLAG = "Land_TableDesk_F", "Land_OfficeChair_01_F", "Land_MapBoard_F", "Flag_NATO_F"
CTABLE, CCHAIR, RADIO = "Land_CampingTable_F", "Land_CampingChair_V2_F", "Land_PortableLongRangeRadio_F"

LAP = 0.3  # How far butted barrier pieces overlap
GUN_BACK = 2.1  # A static stands this far behind its round sandbag (its barrel clear of the bag)

MAPCHAR = {SHORT: "b", LONG: "b", ROUND: "b", CORNER: "b", HB1: "H", HB3: "H", HB5: "H", HBBIG: "H",
           HBW4: "W", HBW6: "W", HBWC: "W", MIL: "W", CITYGATE: "G", BARGATE: "G", WIRE: "w", HOG: "x",
           CNC: "c", CNC4: "c", JERSEY: "c", BUNKER: "B", TOWER: "T"}


def fwd(d):
    r = math.radians(d)
    return math.sin(r), math.cos(r)


def off(x, y, d, f, lat=0.0):
    """(x, y) moved f metres along model direction d and lat metres to its right."""
    a, b = fwd(d), fwd(d + 90)
    return x + a[0] * f + b[0] * lat, y + a[1] * f + b[1] * lat


# ---------------------------------------------------------------- footprints and overlaps (model xy)

GATES = (BARGATE, CITYGATE)
# Sizes measured in the game (boundingBoxReal [length, depth], review round 3) where townlib has none yet
REAL = {HBBIG: (9.0, 2.6), TOWER: (6.4, 9.8), BUNKER: (5.0, 5.7), CNC4: (7.6, 1.8), JERSEY: (2.6, 0.4),
        WIRE: (8.5, 2.1), HB5: (5.8, 1.7), HB3: (3.6, 1.8), HB1: (1.4, 1.7), MIL: (4.1, 1.1), CNC: (1.8, 1.8)}
TOWER_SITE = (5.6, 7.4)  # The bag tower's footprint against the site (see clips()): round 4's towers stood 2.9 m
# (across) and 3.8 m (front) off a building's box and a fence without touching them in the game
# Where a man stands in a bag bunker (its building position, the one at its slit, model coordinates)
BUNKER_POST = (-0.1, 1.2)


def size(it):
    """A footprint [length, depth]: the larger of townlib's size and the size measured in the game (gates, whose
    measured box takes in the arm's swing, by townlib's)."""
    if it[0] == "object":
        if it[1] in REAL:
            return REAL[it[1]]
        a = tl.CLASSES.get(it[1], (0.6, 0.6))
        m = tl.MEASURED.get(it[1]) if it[1] not in GATES else None
        return (max(a[0], m[0]), max(a[1], m[1])) if m else a
    return (1.6, 2.4) if it[0] == "static" else (0.6, 0.6)  # A static's barrel reaches 1.2 m out (measured 2.3 deep)


def length(cls):
    """A barrier piece's real length (the spacing a line is drawn with)."""
    return (REAL.get(cls) or tl.CLASSES[cls])[0]


_RECTS = {}


def site_rects(t):
    """The probe's buildings, walls and rocks as rectangles in model coordinates: [(kind, model, corners)]."""
    if t.name not in _RECTS:
        out = []
        for o in t.objs:
            if o["kind"] not in ("building", "part", "wall", "rock"):
                continue
            b = o["box"]
            pts = []
            for lx, ly in ((b[0], b[1]), (b[2], b[1]), (b[2], b[3]), (b[0], b[3])):
                wx, wy = tl.rot(lx, ly, o["dir"])
                m = t.to_model([o["pos"][0] + wx, o["pos"][1] + wy, 0])
                pts.append((m[0], m[1]))
            out.append((o["kind"], o["model"], pts))
        _RECTS[t.name] = out
    return _RECTS[t.name]


def _sat(pa, pb, tol=0.0):
    """Whether two convex quadrilaterals overlap (by more than tol)."""
    for poly in (pa, pb):
        for i in range(4):
            j = (i + 1) % 4
            ex, ey = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
            n = math.hypot(ex, ey) or 1
            nx, ny = -ey / n, ex / n
            a1 = [p[0] * nx + p[1] * ny for p in pa]
            b1 = [p[0] * nx + p[1] * ny for p in pb]
            if max(a1) <= min(b1) + tol or max(b1) <= min(a1) + tol:
                return False
    return True


def clips(t, it):
    """Whether a placed piece cuts into the probe's buildings, walls, rocks or the office mid-piece: a barrier's
    middle (its ends may overlap; wire and hedgehogs too), anything else whole; the real (measured) size."""
    if it[0] != "object" or "ground" not in it[4] or it[1] == FLAG:
        return False
    core = is_barrier(it) and it[1] not in (TOWER, BUNKER)
    poly = corners(t, it, core)
    if it[1] == TOWER:  # Its measured box (6.4 x 9.8) takes in more than it stands on
        poly = _rect(t, it, *TOWER_SITE)
    if any(_sat(poly, r) for k, mdl, r in site_rects(t)):
        return True
    m = t.to_model(it[2])
    L, D = size(it)
    if core:
        L, D = max(L - 2 * tl.BARRIER_OVERLAP, 0.2), max(D * 0.5, 0.2)
    d = (yaw(it) - t.dir) % 360
    cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
    for i in range(int(L / 0.25) + 1):
        for j in range(int(D / 0.25) + 1):
            a_, b_ = -L / 2 + min(i * 0.25, L), -D / 2 + min(j * 0.25, D)
            if t.on_office(m[0] + a_ * cx[0] + b_ * cy[0], m[1] + a_ * cx[1] + b_ * cy[1], 0.1, 0.1):
                return True
    return False


def yaw(it):
    o = it[3]
    return (o if it[0] == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360


def is_barrier(it):
    """Barrier pieces (and bag bunkers, which sit in the lines) may overlap each other at their ends and sides."""
    return it[0] == "object" and (tl.is_barrier(it[1]) or it[1] in (BUNKER, TOWER))


def _rect(t, it, L, D):
    m = t.to_model(it[2])
    d = (yaw(it) - t.dir) % 360
    cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
    return [(m[0] + sx * L / 2 * cx[0] + sy * D / 2 * cy[0], m[1] + sx * L / 2 * cx[1] + sy * D / 2 * cy[1])
            for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def corners(t, it, core=False):
    """The footprint's corners; core: a barrier piece's middle only (the part that mustn't overlap: the ends and
    the sides may, so lines run unbroken)."""
    m = t.to_model(it[2])
    L, D = size(it)
    if core:
        L, D = max(L - 2 * tl.BARRIER_OVERLAP, 0.2), max(D * 0.5, 0.2)
    d = (yaw(it) - t.dir) % 360
    cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
    return [(m[0] + sx * L / 2 * cx[0] + sy * D / 2 * cy[0], m[1] + sx * L / 2 * cx[1] + sy * D / 2 * cy[1])
            for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(t, a, b, tol=0.08):
    """Separating-axis overlap of two footprints (only in the same height band)."""
    za, zb = t.to_model(a[2])[2], t.to_model(b[2])[2]
    if abs(za - zb) > 1.6 or (a[1] == WIRE and b[1] == WIRE):  # Wire coils may lie over each other
        return False
    both = is_barrier(a) and is_barrier(b)
    if both:
        tol = 0.4  # Butted barrier pieces may overlap a little more than their cores (a line has no gaps)
    pa, pb = corners(t, a, both), corners(t, b, both)
    for poly in (pa, pb):
        for i in range(4):
            j = (i + 1) % 4
            ex, ey = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
            n = math.hypot(ex, ey) or 1
            nx, ny = -ey / n, ex / n
            a1 = [p[0] * nx + p[1] * ny for p in pa]
            b1 = [p[0] * nx + p[1] * ny for p in pb]
            if max(a1) <= min(b1) + tol or max(b1) <= min(a1) + tol:
                return False
    return True


def single_problems(t, it, extra=()):
    """check()'s per-item rules for one item (extra: items it needs beside it, a guard's tower)."""
    probs = tl.check(t, [list(extra) + [it]] * t.cap)
    probs = [p for p in probs if not extra or it[1] in p]
    return [p for p in probs if "guards" not in p and "tiers" not in p]


# ---------------------------------------------------------------- the site's solids (model xy)
# The probe gives every neighbour's bounding box, which can be far bigger than its walls (House_Big_02's runs
# 12 m either side of its centre, its walls 6.5-7.5 m): a line ended at a box leaves a hole in the game. Where the
# building probe (probe_offices.txt) has the neighbour's class (any texture variant), its ground floor plan gives
# the real walls (1 m cells); otherwise its box.
_PLANS = {}


def plan_of(model):
    """A probed building's floor plan by class (texture variants and the i_/u_ twins folded), None without."""
    if not _PLANS:
        import officegen_lib
        _PLANS.update(officegen_lib.parse_probe(os.path.join(tl.ROOT, "tools", "officegen", "probe_offices.txt")))
    v1 = re.sub(r"_V\d_F$", "_V1_F", model)
    for n in (model, v1, v1.replace("Land_u_", "Land_i_"), v1.replace("Land_i_", "Land_u_")):
        if n in _PLANS:
            return _PLANS[n]
    return None


class Site:
    """What stands on the ground round the office (model coordinates): the office (its plan), the neighbours (their
    plans where probed, else their boxes) and the walls (their boxes)."""

    def __init__(self, t):
        self.t = t
        self.objs = [(o, plan_of(o["model"]) if o["kind"] != "wall" else None) for o in t.objs if o["kind"] in ("building", "part", "wall")]

    def at(self, x, y, any_box=False):
        """(kind, model, how) of what's solid at model (x, y): how "plan" (its real walls) or "box" (a neighbour
        without a plan); any_box: also "boxonly", inside a planned neighbour's box but outside its walls (a piece's
        middle may not go there: tl.check()); None."""
        if self.t.on_office(x, y, 0.1, 0.1):
            return ("office", self.t.cls, "plan")
        w = self.t.to_world(x, y, 0)
        for o, p in self.objs:
            lx, ly = tl.rot(w[0] - o["pos"][0], w[1] - o["pos"][1], -o["dir"])
            b = o["box"]
            if not (b[0] <= lx <= b[2] and b[1] <= ly <= b[3]):
                continue
            if p is not None:
                lv = min(p.levels)
                c = p.cell(lv, lx, ly)
                if c == "#" or (c == "." and not p.is_open_sky(lv, lx, ly)):
                    return (o["kind"], o["model"], "plan")
                if not any_box:
                    continue
                return (o["kind"], o["model"], "boxonly")  # Inside its box, outside its walls
            return (o["kind"], o["model"], "box")
        return None

    def in_box(self, x, y):
        """Whether model (x, y) is inside a neighbour's box (what tl.check() holds a piece's middle out of)."""
        w = self.t.to_world(x, y, 0)
        return any(h[0] in ("building", "part") for h in self.t.hits(w[0], w[1], 0.05, 0.05, 0, 0.1))


class Draft:
    """Cumulative tiers: tier() starts the next one from a copy of the last; put() adds an item when it passes the
    single-item checks and doesn't overlap what's there (fortifications also stay off roads unless road_ok);
    otherwise it tries small nudges (nudge > 0) or logs a SKIP (a design error to fix, not a fallback)."""

    def __init__(self, t):
        self.t, self.tiers, self.cur, self.log = t, [], None, []
        self.site, self.runs = Site(t), []

    def tier(self):
        self.cur = list(self.tiers[-1]) if self.tiers else []
        self.tiers.append(self.cur)

    def _ok(self, it, road_ok, ignore=()):
        if single_problems(self.t, it, [i for i in ignore if i[1] == TOWER]):
            return False
        if it[0] == "object" and "ground" in it[4] and not road_ok and it[1] not in (WIRE, HOG) and self.t.on_road(it[2][0], it[2][1]):
            return False
        if clips(self.t, it):
            return False
        return not any(overlap(self.t, it, o) for o in self.cur if not any(o is i for i in ignore))

    def put(self, make, x, y, z, d, nudge=0.0, road_ok=False, label="", ignore=()):
        tries = [(0.0, 0.0)]
        r = 0.25
        while r <= nudge + 1e-6:
            tries += [(r * math.sin(math.radians(a)), r * math.cos(math.radians(a))) for a in range(0, 360, 45)]
            r += 0.25
        for dx, dy in tries:
            it = make(x + dx, y + dy, z, d)
            if self._ok(it, road_ok, ignore):
                self.cur.append(it)
                if dx or dy:
                    self.log.append(f"T{len(self.tiers)} {label or it[1]} nudged {dx:+.2f},{dy:+.2f}")
                return it
        it = make(x, y, z, d)
        why = single_problems(self.t, it)[:1] or [o[1] for o in self.cur if overlap(self.t, it, o)][:2] or (["clips the site"] if clips(self.t, it) else ["road"])
        self.log.append(f"T{len(self.tiers)} SKIP {label or it[1]} at ({x:.1f},{y:.1f}): {why}")
        return None

    # ---- the pieces
    def g(self, role, x, y, d, z=None, nudge=0.5, ignore=()):
        return self.put(lambda a, b, c, e: tl.guard(self.t, role, a, b, c, e), x, y, z, d, nudge, label=role, ignore=ignore)

    def o(self, cls, x, y, d, z=None, nudge=0.0, road_ok=False, flag=False):
        return self.put(lambda a, b, c, e: tl.obj(self.t, cls, a, b, c, e, flag), x, y, z, d, nudge, road_ok, cls)

    def s(self, role, x, y, d, z=None, nudge=0.25):
        return self.put(lambda a, b, c, e: tl.static(self.t, role, a, b, c, e), x, y, z, d, nudge, label=role + " static")

    def post(self, role, x, y, face, cls=SHORT, z=None, gap=1.0, nudge=0.0):
        """Cover at (x, y) square across the facing, the guard `gap` metres behind its near face, facing out."""
        if self.o(cls, x, y, face, z, nudge=nudge):
            gx, gy = off(x, y, face, -(size(["object", cls])[1] / 2 + gap))
            return self.g(role, gx, gy, face, z, nudge=0.25)
        return None

    def gun(self, role, x, y, face, z=None, bag=True, road_ok=False):
        """A static weapon in a pit: a round sandbag GUN_BACK m in front of it."""
        s = self.s(role, x, y, face, z)
        if s and bag:
            bx, by = off(x, y, face, GUN_BACK)
            self.o(ROUND, bx, by, face + 180, z, nudge=0.25, road_ok=road_ok)
        return s

    def line(self, x0, y0, along, pieces, face=None, z=None, road_ok=False):
        """A straight run from (x0, y0) along model direction `along`, butted end to end: "H" HBarrier_5 (6 m),
        "h" HBarrier_3 (3.6), "1" HBarrier_1 (1.56), "W" HBarrierWall6 (6.5, tall), "V" HBarrierWall4 (4.5),
        "M" Mil wall (4, tall), "w" razor wire (7.6), "c" concrete block (4), "C" (8), "_" a 1 m gap,
        "=" a 2 m gap, "G" a 5 m gap (the gate's), "e" a 1.7 m gap holding a round sandbag (an embrasure).
        Pieces overlap their neighbours by LAP (the line is one unbroken wall; a gap is still a gap).
        `face` is the side the line faces (default: along - 90, the left). Returns the end point."""
        spec = {"H": (HB5, 6.0), "h": (HB3, 3.6), "1": (HB1, 1.56), "W": (HBW6, 6.5), "V": (HBW4, 4.5),
                "M": (MIL, 4.0), "w": (WIRE, 7.6), "c": (CNC, 4.0), "C": (CNC4, 8.0), "_": (None, 1.0),
                "=": (None, 2.0), "G": (None, 5.0), "e": (ROUND, 1.7)}
        face = (along - 90) if face is None else face
        s = 0.0
        for p in pieces:
            cls, L = spec[p]
            if cls:
                cx, cy = off(x0, y0, along, s + L / 2)
                d = face + 180 if cls == ROUND else face
                self.o(cls, cx, cy, d, z, road_ok=road_ok or cls in (WIRE,), nudge=0.0)
            s += L - (LAP if cls and cls != ROUND else 0.0)
        return off(x0, y0, along, s)

    # A run's pieces: the family's main piece and its finishers (one height: "B" is 2-high, the finishers the tall
    # Mil wall and concrete blocks), the joints overlapping JOINT, the ends running END into what closes them (0.5 at
    # most: tl.check() holds a piece's middle, 0.6 m off its ends, out of a neighbour's box)
    FAMILIES = {"H": (HB5, (HB3, HB1)), "B": (HBBIG, (MIL, CNC)), "M": (MIL, (CNC,)), "w": (WIRE, ()), "c": (CNC4, (CNC,))}
    JOINT, END, FREE = (0.3, 0.6), (0.3, 0.38), (-0.3, 0.6)  # END 0.38: tl.check() takes HB1/HB5 for longer  # FREE: an end that only meets a crossing run
    END_WALL = (0.3, 0.6)  # Into a wall or another piece (tl.check() doesn't hold pieces out of walls)

    def solid(self, x, y):
        """What closes a run's end at model (x, y): the site (a planned neighbour's box too: a piece can't go further
        in), or a barrier piece of this tier standing there."""
        h = self.site.at(x, y, any_box=True)
        if h:
            return h
        for o in self.cur:
            if is_barrier(o) and "ground" in o[4] and o[1] not in (WIRE, HOG) and _covers(self.t, o, x, y):
                return ("piece", o[1], "plan")
        return None

    def faces(self, x0, y0, x1, y1, past=1.5, half=0.45):
        """The gap a run from (x0, y0) to (x1, y1) closes: walking out from its middle each way (up to `past` metres
        beyond its ends), the first solid point; [(distance from (x0, y0), what or None: a free end there)] *2."""
        L = math.hypot(x1 - x0, y1 - y0)
        ux, uy = (x1 - x0) / L, (y1 - y0) / L
        out = []
        for sign, end in ((-1, -past), (1, L + past)):
            s, hit = L / 2, None
            while (s >= end) if sign < 0 else (s <= end):
                for lat in (0.0, -half, half):  # Across a piece's middle (a wall met at a slant)
                    hit = self.solid(x0 + ux * s - uy * lat, y0 + uy * s + ux * lat)
                    if hit:
                        break
                if hit:
                    break
                s += 0.05 * sign
            out.append((s - 0.025 * sign, hit) if hit else ((0.0 if sign < 0 else L), None))
        return out

    def choose(self, gap, family, free, site_end=(False, False), building=(True, True)):
        """The pieces closing a gap: ([(class, start, end)] from 0 (the first face) along the run, the overlaps),
        the joints overlapping JOINT and the ends running END into what closes them (FREE at a free end); None when
        nothing fits. A concrete block never ends a run against the site (tl.check() takes it for 4 m long)."""
        main, fin = self.FAMILIES[family]
        classes = (main,) + fin
        rng = [self.FREE if f else (self.END if b else self.END_WALL) for f, b in zip(free, building)]
        joint = self.JOINT
        if family == "w":  # Wire coils overlap as much as they need to (an obstacle, not a wall)
            joint, rng = (0.3, 6.0), [(-1.5, 0.5)] * 2
        best = None
        for na in range(0, 14):
            for nb in range(0, 4 if len(classes) > 1 else 1):
                for nc in range(0, 4 if len(classes) > 2 else 1):
                    k = na + nb + nc
                    if k == 0:
                        continue
                    S = na * length(main) + (nb and nb * length(classes[1])) + (nc and nc * length(classes[2]))
                    lo = S - joint[1] * (k - 1) - rng[0][1] - rng[1][1]
                    hi = S - joint[0] * (k - 1) - rng[0][0] - rng[1][0]
                    if not lo - 1e-6 <= gap <= hi + 1e-6:
                        continue
                    # The order: the long pieces at the ends, the blocks in the middle
                    seq = [main] * na + ([classes[1]] * nb if nb else []) + ([classes[2]] * nc if nc else [])
                    longs = [c for c in seq if c != CNC]
                    blocks = [c for c in seq if c == CNC]
                    if blocks and longs:
                        seq = longs[:1] + blocks + longs[1:]
                    if (site_end[0] and seq[0] == CNC) or (site_end[1] and seq[-1] == CNC):
                        seq = seq[::-1]
                    if (site_end[0] and seq[0] == CNC) or (site_end[1] and seq[-1] == CNC):
                        continue
                    cost = k + 2.5 * (nb + nc) + 0.5 * nc
                    if best is None or cost < best[0]:
                        best = (cost, seq, S)
        if not best:
            return None
        _, seq, S = best
        # The excess (S - gap) shared out over the joints and the closed ends, each within its range
        slots = [("e0", rng[0])] + [("j", joint)] * (len(seq) - 1) + [("e1", rng[1])]
        X = S - gap
        val = [None] * len(slots)
        free_i = list(range(len(slots)))
        while free_i:
            share = (X - sum(v for v in val if v is not None)) / len(free_i)
            clamped = False
            for i in list(free_i):
                lo, hi = slots[i][1]
                if share < lo or share > hi:
                    val[i] = min(max(share, lo), hi)
                    free_i.remove(i)
                    clamped = True
            if not clamped:
                for i in free_i:
                    val[i] = share
                free_i = []
        out, pos = [], -val[0]
        for i, c in enumerate(seq):
            out.append((c, pos, pos + length(c)))
            pos += length(c) - (val[i + 1] if i + 1 < len(seq) else 0)
        return out, val

    def fill(self, x0, y0, x1, y1, face, family="H", z=None, road_ok=False, label="", past=1.5):
        """One unbroken run closing the gap along (x0, y0)-(x1, y1): the gap's faces found by walking out from its
        middle (the site's real walls, or a piece of this tier), then the family's pieces butted from face to face,
        the joints overlapping 0.3-0.6 m and the ends running 0.3-0.5 m into what closes them; facing `face`.
        Logged for the audit (audit())."""
        (s0, h0), (s1, h1) = self.faces(x0, y0, x1, y1, past, half=size(["object", self.FAMILIES[family][0]])[1] * 0.25 + 0.05)
        L = math.hypot(x1 - x0, y1 - y0)
        ux, uy = (x1 - x0) / L, (y1 - y0) / L
        gap = s1 - s0
        run = {"tier": len(self.tiers), "label": label or f"({x0:.1f},{y0:.1f})-({x1:.1f},{y1:.1f})", "family": family,
               "a": (x0 + ux * s0, y0 + uy * s0), "b": (x0 + ux * s1, y0 + uy * s1), "u": (ux, uy), "face": face,
               "gap": gap, "ends": (h0, h1), "pieces": [], "joints": []}
        self.runs.append(run)
        site_end = tuple(h is not None and h[0] != "piece" for h in (h0, h1))
        bld = tuple(h is not None and h[0] in ("building", "part", "office") for h in (h0, h1))
        pick = self.choose(gap, family, (h0 is None, h1 is None), site_end, bld)
        if not pick and family == "B":  # Too short a gap for anything 2-high: low H-barriers
            pick = self.choose(gap, "H", (h0 is None, h1 is None), site_end, bld)
            run["family"] = "H"
        if not pick:
            self.log.append(f"T{len(self.tiers)} SKIP fill {run['label']}: nothing fits {gap:.2f} m")
            return run
        pieces, val = pick
        run["joints"], run["over"] = val[1:-1], (val[0], val[-1])
        for c, a, b in pieces:
            cx, cy = x0 + ux * (s0 + (a + b) / 2), y0 + uy * (s0 + (a + b) / 2)
            it = self.o(c, cx, cy, face, z, road_ok=road_ok or c == WIRE)
            run["pieces"].append((c, s0 + a, s0 + b, it is not None))
        return run

    def closed(self, x0, y0, x1, y1, face, label):
        """Log a stretch closed by other means (a gate, the site's walls) for the audit: (x0, y0)-(x1, y1) must be
        covered end to end by the site or this tier's pieces."""
        L = math.hypot(x1 - x0, y1 - y0)
        self.runs.append({"tier": len(self.tiers), "label": label, "family": "-", "a": (x0, y0), "b": (x1, y1),
                          "u": ((x1 - x0) / L, (y1 - y0) / L), "face": face, "gap": L, "ends": (None, None), "pieces": None, "joints": []})

    def _free_end(self, r, items, i):
        """A free end (nothing closing it along the run): the crossing piece it joins at a corner, or FREE."""
        ux, uy = r["u"]
        ax, ay = r["a"] if i == 0 else r["b"]
        sign = 1 if i == 0 else -1
        for s in (-0.5, -0.3, -0.1, 0.1, 0.3, 0.5, 0.8, 1.1, 1.5):
            for lat in (-1.2, -0.8, -0.4, 0.0, 0.4, 0.8, 1.2):
                x, y = ax + ux * s * sign - uy * lat, ay + uy * s * sign + ux * lat
                for o in items:
                    if not (is_barrier(o) and "ground" in o[4]) or o[1] in (HOG, WIRE):
                        continue
                    m = self.t.to_model(o[2])
                    along = (m[0] - r["a"][0]) * ux + (m[1] - r["a"][1]) * uy
                    across = abs(-(m[0] - r["a"][0]) * uy + (m[1] - r["a"][1]) * ux)
                    if across < 0.05 and -0.5 <= along <= r["gap"] + 0.5:
                        continue  # One of the run's own pieces
                    if _covers(self.t, o, x, y):
                        return f"joins {o[1].replace('Land_', '').replace('_F', '')}"
        return "FREE"

    def audit(self):
        """Every run: its gap, its pieces' length end to end, its joints and end overlaps, what closes each end,
        any stretch the pieces and the site leave open, and a road-facing run that isn't 2-high: [text]."""
        out = []
        for r in self.runs:
            items = self.tiers[r["tier"] - 1]
            ux, uy = r["u"]
            ax, ay = r["a"]
            h0, h1 = r["ends"]
            holes, s, start = [], -0.3 if h0 else 0.0, None
            while s <= r["gap"] + (0.3 if h1 else 0.0):
                x, y = ax + ux * s, ay + uy * s
                ok = self.site.at(x, y) or any(is_barrier(o) and "ground" in o[4] and o[1] not in (HOG,) and _covers(self.t, o, x, y) for o in items)
                if not ok and start is None:
                    start = s
                if ok and start is not None:
                    holes.append((start, s))
                    start = None
                s += 0.05
            if start is not None:
                holes.append((start, s))
            placed = [p for p in (r["pieces"] or []) if p[3]]
            span = (placed[-1][2] - placed[0][1]) if placed else 0.0
            flags = []
            what = [(self._free_end(r, items, i) if h is None else f"{h[0]}:{h[1].replace('Land_', '').replace('.p3d', '')}{'' if h[2] == 'plan' else '(box)'}") for i, h in enumerate(r["ends"])]
            for i, h in enumerate(r["ends"]):
                if h and h[2] == "boxonly":  # How far on its real wall is (the stretch tl.check() won't let a piece into)
                    sign = -1 if i == 0 else 1
                    ex, ey = r["a"] if i == 0 else r["b"]
                    k = 0.0
                    while k < 10 and not (self.site.at(ex + ux * k * sign, ey + uy * k * sign) or (None, None, None))[2] == "plan":
                        k += 0.1
                    what[i] = what[i].replace("(box)", f"(box; its wall {k:.1f} m on)" if k < 10 else "(box; no wall on)")
                    flags.append(f"box end: {k:.1f} m to the real wall")
            names = "+".join(f"{sum(1 for p in placed if p[0] == c)}x{c.replace('Land_', '').replace('_F', '')}" for c in dict.fromkeys(p[0] for p in placed))
            mx, my = (ax + r["b"][0]) / 2, (ay + r["b"][1]) / 2
            fx, fy = off(mx, my, r["face"], 8.0)
            w = self.t.to_world(fx, fy, 0)
            road = any(d <= 10 for d, _ in self.t.roads_near(w[0], w[1], 10))
            tall = r["pieces"] is None or all(p[0] in (HBBIG, MIL, CNC, CNC4, HBW4, HBW6) for p in placed)
            if r["pieces"] is not None and r["family"] != "w" and any(w_.startswith("FREE") for w_ in what):
                flags.append("a free end")
            if r["pieces"] is not None and (len(placed) < len(r["pieces"]) or not r["pieces"]):
                flags.append("PIECES SKIPPED")
            if holes and r["family"] != "w":  # Wire is a belt in front of a line, not a line
                flags.append("OPEN " + ", ".join(f"{a:.1f}-{b:.1f}" for a, b in holes))
            if road and not tall and r["family"] != "w":
                flags.append("faces a road, not 2-high")
            j = ",".join(f"{v:.2f}" for v in r["joints"]) or "-"
            e = ",".join(f"{v:.2f}" for v in r.get("over", ()))
            out.append(f"T{r['tier']} {r['label'][:34]:34} gap {r['gap']:5.1f} m  run {span:5.1f} m  {names:30} joints {j:22} ends {e:10} {what[0]} | {what[1]}  {'; '.join(flags) or 'closed'}")
        return out

    def embrasure(self, x, y, face, role="hmg", z=None, bag=True, line_face=None, road_ok=False):
        """A round sandbag in a line at (x, y) (bag; the line's gap 3 m for its real width) and a static weapon
        GUN_BACK m behind it (role), firing through it towards `face` (the line itself faces line_face, default face)."""
        lf = face if line_face is None else line_face
        if bag:
            self.o(ROUND, x, y, lf + 180, z, nudge=0.0, road_ok=road_ok)
        if role:
            bx, by = off(x, y, face, -GUN_BACK)  # Behind the bag along its line of fire
            return self.s(role, bx, by, face, z)

    def bunker(self, x, y, face, role="autorifleman", road_ok=False):
        """A small bag bunker facing out, a man inside at its slit."""
        b = self.o(BUNKER, x, y, face, nudge=0.5, road_ok=road_ok)
        if b:
            m = self.t.to_model(b[2])
            gx, gy = off(m[0], m[1], face, BUNKER_POST[1], BUNKER_POST[0])
            return self.g(role, gx, gy, face, nudge=0.25, ignore=(b,))

    def tower(self, x, y, face, top="marksman", below=None, below_face=None, road_ok=False):
        """A bag tower (a corner tower of the perimeter), its open side (+y) facing out: a man on its platform
        (measured in the game: 3.4 m over the ground at the centre, level 0.6 m towards +y and to either side;
        its back wall 0.6 m towards -y), 0.3 m forward of the centre, looking out over the open side; with
        `below`, a second man on the platform beside him (the tower has no room below to stand in)."""
        tw = self.o(TOWER, x, y, face, nudge=1.5, road_ok=road_ok)
        if tw:
            m = self.t.to_model(tw[2])
            z = self.t.ground_model(m[0], m[1]) + TOWER_TOP
            spots = [(0.0,)] if not below else [(-0.45,), (0.45,)]
            for role, (lat,) in zip((top, below) if below else (top,), spots):
                self.g(role, *off(m[0], m[1], face, 0.3, lat), face, z, nudge=0.0, ignore=(tw,))
        return tw

    def checkpoint(self, x, y, face, width=7.0, out=6.0, side=1, roles=("rifleman", "autorifleman"), hb=HBBIG, block=CNC4,
                   post=None, wire=None, bag_at=-3.0):
        """A checkpoint across a road, traffic coming from `face`: a 2-high H-barrier block across one half at
        (x, y), a concrete block across the other half `out` metres further out (negative: further in): a vehicle
        chicane, through in an S at walking pace; the men behind a long sandbag on the open lane `bag_at` metres
        inside the H-barrier (the chicane's exit, their view over the bag), `side` 1/-1 which half the H-barrier
        takes (right/left seen from the office); a bag bunker at the roadside (post) and wire (wire)."""
        half = side * width / 4
        self.o(hb, *off(x, y, face, 0.0, half), face, road_ok=True, nudge=0.5)
        if roles:
            lane = -side * max(5.6 - abs(half), abs(half)) if hb == HBBIG else -half  # Clear of the block's end
            bag = self.o(LONG, *off(x, y, face, bag_at, lane), face, road_ok=True, nudge=0.5)
            if bag:
                m = self.t.to_model(bag[2])
                for role, lat in zip(roles, (-0.7, 0.7) if len(roles) > 1 else (0.0,)):
                    self.g(role, *off(m[0], m[1], face, -1.2, lat), face, nudge=0.25)
        if block:
            self.o(block, *off(x, y, face, out, -half), face, road_ok=True, nudge=0.5)
        if post:  # A bag bunker at the roadside, its slit up the road: (metres along, metres to the side)
            self.bunker(*off(x, y, face, post[0], post[1]), face, road_ok=True)
        if wire:  # Wire across the shoulder beside the barrier: (metres along, metres to the side)
            self.o(WIRE, *off(x, y, face, wire[0], wire[1]), face, road_ok=True, nudge=0.5)

    def finish(self):
        return self.tiers


# ---------------------------------------------------------------- fields of fire and views (approximating the
# in-game check: a static's field must run 15 m, a guard's view 4 m)
BLOCK_GUN = (HB1, HB3, HB5, HBBIG, HBW4, HBW6, HBWC, MIL, CITYGATE, BUNKER, TOWER, CNC4, CNC, HOG)
BLOCK_EYE = (HBBIG, HBW4, HBW6, HBWC, MIL, CITYGATE, BUNKER, TOWER)


def _covers(t, it, x, y):
    m = t.to_model(it[2])
    L, D = size(it)
    d = (yaw(it) - t.dir) % 360
    lx, ly = tl.rot(x - m[0], y - m[1], -d)
    return abs(lx) <= L / 2 and abs(ly) <= D / 2


def reach(t, items, it, limit):
    """How far a static fires (or a guard sees) along his facing before something stops it (limit when nothing
    does): the probe's buildings and walls, the office, the layout's tall pieces, rising ground; on the roof the
    roof's edge (a gun must stand 2.4 m back from the parapet, which it then fires over)."""
    m = t.to_model(it[2])
    face = (yaw(it) - t.dir) % 360
    gun = it[0] == "static"
    block = BLOCK_GUN if gun else BLOCK_EYE
    raised = "ground" not in it[4]
    plan = t.plan()
    level = plan.level_of(m[2]) if raised else None
    g0 = t.ground_model(m[0], m[1])
    own = [o for o in items if o[0] == "object" and o[1] in (BUNKER, TOWER) and _covers(t, o, m[0], m[1])]
    aloft = raised and m[2] - g0 > 2.0  # Up a floor or a tower: over the porches and the low walls
    if aloft and not plan.is_building(level, m[0], m[1]):
        raised = False
    d = 0.5
    while d <= limit:
        x, y = off(m[0], m[1], face, d)
        if raised:
            c = plan.cell(level, x, y)
            if not gun and d <= 1.25 and c == "#":  # A window's or balcony rail's thickness
                c = "."
            if level == max(plan.levels) and len(plan.levels) > 2:  # The roof (the tower block's)
                if c != ".":
                    return d if (d < 2.4 or c == "#") else limit
            elif c == "#":
                return d
            elif c == " ":
                raised, aloft = False, True  # Out through a window: over the ground from here
        else:
            w = t.to_world(x, y, 0)
            hit = [h for h in t.hits(w[0], w[1], 0.2, 0.2, 0, 0) if h[0] in ("building", "wall", "part", "rock") and not (aloft and h[0] in ("part", "wall"))]
            if not gun:  # A man sees over the low walls and through the pipe fences
                hit = [h for h in hit if not any(k in h[1] for k in ("smallwall", "pipe_fence"))]
            if hit:
                return d
            if not aloft and t.on_office(x, y, 0.2, 0.2):
                return d
            if t.ground_model(x, y) - g0 > (1.0 if gun else 1.6) and abs(m[2] - g0) < 1.0:
                return d
        for o in items:
            if o is not it and o[0] == "object" and o[1] in block and o not in own and abs(t.to_model(o[2])[2] - m[2]) < 2.0 and _covers(t, o, x, y):
                return d
        d += 0.25
    return limit


def lines_of_fire(t, tiers):
    """[text] for the statics firing under 15 m and the guards seeing under 4 m, per tier first met."""
    out, seen = [], set()
    for n, items in enumerate(tiers, 1):
        for it in items:
            if it[0] not in ("static", "guard"):
                continue
            limit = 15.0 if it[0] == "static" else 4.0
            r = reach(t, items, it, limit)
            key = (it[1], tuple(round(v, 1) for v in it[2]))
            if r < limit and key not in seen:
                seen.add(key)
                m = t.to_model(it[2])
                out.append(f"T{n} {it[0]} {it[1]} at {[round(v, 1) for v in m]} facing {(yaw(it) - t.dir) % 360:.0f}: {r:.1f} m")
    return out


def counts(tiers):
    return [(len(ti), sum(1 for it in ti if it[0] == "guard"), sum(1 for it in ti if it[0] == "static")) for ti in tiers]


def overlay(t, items, r=45):
    """The fine map with the items drawn on it (model coordinates, up = +y): # a neighbour's real walls (its plan, or
    its box without one), % its box beyond its walls (tl.check() keeps pieces' middles out of it; the game doesn't)."""
    grid = {}
    site = Site(t)
    for y in range(-r, r + 1):
        for x in range(-r, r + 1):
            w = t.to_world(x, y, 0)
            c = "."
            if t.on_road(w[0], w[1]):
                c = ":"
            h = t.hits(w[0], w[1], 0.3, 0.3, 0, 0)
            if h:
                c = {"building": "%", "wall": "=", "tree": "t", "rock": "r", "part": "%"}.get(h[0][0], "?")
            r_ = site.at(x, y)
            if r_ and r_[0] in ("building", "part"):
                c = "#"
            if t.on_office(x, y, 0.3, 0.3):
                c = "O"
            grid[(x, y)] = c
    for it in items:
        m = t.to_model(it[2])
        on_floor = "ground" not in it[4]
        if it[0] == "guard":
            ch = "g" if not on_floor else "^"
        elif it[0] == "static":
            ch = "S" if not on_floor else "$"
        else:
            ch = MAPCHAR.get(it[1], "f")
            if on_floor and ch != "f":
                ch = "~"
        if it[0] != "object":
            k = (int(round(m[0])), int(round(m[1])))
            if k in grid:
                grid[k] = ch
            continue
        L, D = size(it)
        d = (yaw(it) - t.dir) % 360
        cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
        for i in range(int(L / 0.25) + 1):
            for j in range(int(D / 0.25) + 1):
                a, b = -L / 2 + i * 0.25, -D / 2 + j * 0.25
                k = (int(round(m[0] + a * cx[0] + b * cy[0])), int(round(m[1] + a * cx[1] + b * cy[1])))
                if k in grid and grid[k] not in "g^S$":
                    grid[k] = ch
    out = ["     " + "".join(str(abs(x) // 10) if x % 10 == 0 else " " for x in range(-r, r + 1))]
    for y in range(r, -r - 1, -1):
        out.append(f"{y:4d} " + "".join(grid[(x, y)] for x in range(-r, r + 1)))
    return "\n".join(out)


# ================================================================ Offices_01 (Kavala, Pyrgos)
# The tower block (model plan, the probe's 1 m grid): the ground floor (-6.7) is the lobby, an L: the hall along the
# south front (x -1..12, y -7..-3) and its east arm (x 4..12, y -3..4); the main door (10.5, -7.7) at the hall's
# south-east corner opens onto a covered porch (x 8..13, y -8) and the forecourt; the back corridor (x -16..7,
# y 5..8) runs to the back door (-14.8, 8.4) facing north; the west block (x -17..-2, y -12..4) is solid.
# Floors -3 and 1 are the stair core over the hall's west end (x -1..7, y -7..4; the stair well x -1..2,
# y -3..-4) with south windows; floor 5 (4.97) is the office floor (x 4..12, y -7..4; east windows at x 13), the
# mayor's desk there; the roof (10.25) is a flat terrace over the whole block (x -17..13, y -12/-8..9), 17-18 m
# above the street: the overwatch over everything.
F0, F1, F2, F3, ROOF = -6.71, -2.95, 1.01, 4.97, 10.25


def tower_t1(d, flag, door_post=(12.2, -9.6)):
    """T1: the desk, chair and map board on the office floor (the chair by the wall, both facing it), the flag in
    the street; gendarmes in the lobby looking out of the main door, by the desk, and in the back corridor."""
    d.tier()
    d.o(DESK, 10.0, -1.6, 0, F3)
    d.o(CHAIR, 10.0, 0.0, 0, F3)
    d.o(BOARD, 10.5, -6.0, 180, F3)
    d.o(FLAG, *flag, 180, flag=True, nudge=1.0)
    d.g("gendarme", *door_post, 180)            # Outside the main door, looking down the street
    d.g("gendarme", 11.4, -0.8, 180, F3)        # The office, by the desk
    d.g("gendarme", -3.0, 6.5, 270, F0)         # The back corridor, down its 12 m to the back door


def tower_t2_inside(d):
    """T2 inside: the back door bagged from inside, a man at the first-floor south window over the porch."""
    d.o(SHORT, -14.8, 7.3, 0, F0)
    d.g("rifleman", 4.1, -6.7, 180, F2)


def tower_t3_inside(d):
    """T3: overwatch: the roof's south-east corner HMG (the square and the junction below, from 17 m; the roof's
    parapet its cover, 2.4 m in front), a marksman at the office floor's east window (over the east street), men
    at the floor -3 and floor 1 south windows."""
    d.s("hmg", 11.0, -5.6, 170, ROOF)            # (The roof's low dividing walls, which the plan misses, run
    # x -17..-9 at y -2 and y 1.7, x -16..-8.6 at y 1.7..4.3, x -10..-4 at y -7 and -9: guns stay clear of them)
    d.g("marksman", 12.3, -3.6, 90, F3)
    d.g("rifleman", 0.6, -6.8, 180, F2)
    d.g("rifleman", 1.8, -6.8, 180, F1)
    d.g("rifleman", 6.4, -6.8, 180, F1)


def tower_t4_inside(d):
    """T4: the roof held: an MG behind bags at the south-west corner (the square's west), the office floor's
    south-east window MG (the template's), a marksman on the roof's north-west over the yard and the west road."""
    d.post("mg_gunner", -14.5, -10.6, 215, LONG, z=ROOF)
    d.g("mg_gunner", 12.3, -6.6, 135, F3)
    d.post("marksman", -15.5, 7.6, 315, z=ROOF)


def tower_t5_inside(d, at=(10.8, 4.0, 90)):
    """T5: the kill zone inside. The lobby: a sandbag barricade across the hall at x 7.3 (y -7..-4) shuts the hall's
    west end, so whoever comes through the main door stands in a pocket (x 8..12, y -7..-1): riflemen behind the
    barricade fire into it from the west, an MG behind a long bag at the pocket's north end (11, -1.4) fires down
    it from the north. The back corridor bagged across halfway, a rifleman covering the back door's 9 m. The stair
    head on floor -3 held from behind bags; the office floor's door bagged with a rifleman behind; the officer by
    the desk. Up top: an AT launcher on the roof (2.7 m back from the parapet) over the vehicle approach, from
    above: their thin roofs."""
    d.o(LONG, 7.3, -5.6, 90, F0)                 # The barricade across the hall
    d.g("rifleman", 6.0, -6.4, 90, F0)
    d.g("autorifleman", 6.0, -4.8, 90, F0)
    d.o(LONG, 11.0, -2.6, 180, F0)               # The MG's bags at the pocket's north end
    d.g("mg_gunner", 11.0, -1.4, 180, F0)
    d.o(LONG, -6.5, 6.5, 270, F0)                # The back corridor
    d.g("rifleman", -5.0, 6.5, 270, F0)
    d.o(SHORT, 3.4, -5.8, 270, F1)               # The stair head on floor -3
    d.g("rifleman", 5.0, -5.8, 270, F1)
    d.o(LONG, 10.0, -4.0, 180, F3)               # The office floor
    d.g("rifleman", 9.0, -2.8, 180, F3)
    d.g("officer", 8.6, -0.1, 135, F3)
    d.s("at", *at, ROOF)


def kavala(d):
    """Kavala (the probe's walls, model coordinates): the tower stands in a city block whose walls are low city
    walls with railings (a man climbs them; the fort's lines are the occupier's own). The old city wall runs
    diagonally north-west of the block from (-35, -11) to (-4, 37) (a road outside it), closing the west yard
    (x -30..-17) and the north yard (x -12..4, y 9..34) behind the tower; Addon_01 (x 4..13, y 8..21) and Addon_02
    (x 1..13, y 22..34) close the north yard's east; a low city wall runs down the east side (x 17-22) between the
    block and the east street (x 22-33, the junction east at y -13); the south front onto the open square: the
    west block's face (y -12.5), a low concrete wall (y -11.2, x -1..7), the forecourt between two walls (x 8 and
    13) and a wall to the east wall (x 13..17). The west yard's south side a city wall (y -11.4, x -36..-22) with a
    5 m gap to the block. The approaches: the square from the south, the east street (north and south) and its
    junction, the road outside the old city wall (north-west), the west road onto the square.
    T3 closes the block's gaps (the west gap, the forecourt's gate); T4 rings the whole block with 2-high lines:
    a forward yard walled out into the square (its gate on the door's axis, a chicane outside), a street face
    down the east street to the north end of the block, the old city wall lined inside from the west yard's
    wall to Addon_02's corner (the north and west yards inside); T5 a second walled yard out in the square, the
    checkpoints on every road, the mortar in the north yard, AT on the roof, the kill zone inside."""
    tower_t1(d, (-0.5, -12.6))

    d.tier()  # T2: the main door held from the forecourt: a long bag across its mouth, the walls its flanks (a C)
    d.o(LONG, 10.6, -10.2, 180)
    d.g("rifleman", 10.0, -9.0, 180)
    d.g("autorifleman", 11.3, -9.0, 180)
    tower_t2_inside(d)

    d.tier()  # T3: the compound: the west yard's gap (the city wall's end to the block's corner) shut with
    # H-barriers and a man behind them; the forecourt's mouth a bar gate; the back door's post; the roof HMG, a GMG
    # on the roof's south-west (the square's west half and the west road), the window marksman and riflemen at the
    # stair core's south windows over the square
    d.fill(-22.4, -11.4, -15.8, -11.4, 180, "B", label="west yard's gap, wall to block")
    d.g("rifleman", -19.0, -9.9, 180)
    d.o(BARGATE, 10.6, -11.2, 180)
    d.closed(7.8, -11.2, 13.4, -11.2, 180, "forecourt's mouth: bar gate")
    d.post("autorifleman", -14.8, 10.6, 30)                # Out over the north yard
    tower_t3_inside(d)
    d.s("gmg", -14.5, -5.5, 250, ROOF)

    d.tier()  # T4: the fort, one 2-high ring round the whole block. The forward yard walled out across the square
    # (y -21) from its west side (x -10, off the block's face) to the street's edge, its gate on the door's axis (men
    # in its lane, a chicane of two staggered H-barriers outside), HMG embrasures in its square face and its street
    # face; the street face on up the east street's edge outside the low wall to the block's north end, turned in
    # there to the wall; the old city wall lined 2-high inside from the west yard's wall to Addon_02's corner; bag
    # towers in the forward yard (its platform over the square) and the north yard (over the old wall and the
    # road beyond it); wire outside the old wall, hedgehogs across the street both ways
    d.embrasure(1.8, -21.0, 180)                             # The HMG over the square
    d.fill(-11.3, -21.0, 0.3, -21.0, 180, "B", label="square face, west corner to HMG")
    d.o(BARGATE, 10.5, -21.0, 180)                           # The gate, x 8..13 on the door's axis
    d.fill(3.3, -21.0, 8.0, -21.0, 180, "B", label="square face, HMG to gate")
    d.fill(13.0, -21.0, 21.6, -21.0, 180, "B", label="square face, gate to street corner")
    d.fill(-10.0, -11.5, -10.0, -22.0, 270, "B", label="forward yard's west side, block to square face")
    d.embrasure(20.6, -14.4, 90, road_ok=True)               # The HMG over the junction and the street
    d.fill(20.6, -19.8, 20.6, -15.9, 90, "B", road_ok=True, label="street face, corner to HMG")
    d.fill(20.6, -12.9, 20.6, 9.6, 90, "B", road_ok=True, label="street face, HMG to the bend")
    d.fill(20.6, 8.8, 23.2, 27.0, 98, "B", road_ok=True, label="street face, bend to the north-east corner")
    d.fill(12.4, 26.4, 24.0, 26.4, 0, "B", road_ok=True, label="north side, Addon_02 to the street face")
    d.fill(-35.5, -10.2, -20.0, -10.2, 180, "B", label="west yard's south wall lined")
    d.fill(-31.6, -11.0, -11.4, 19.4, 303.5, "B", label="old city wall lined, west yard to the bend")
    d.fill(-12.6, 18.4, 1.8, 33.6, 315, "B", label="old city wall lined, bend to Addon_02")
    d.tower(-5.0, -16.4, 270, "marksman", "autorifleman")
    d.tower(-3.0, 16.0, 300, "marksman", "autorifleman")
    d.g("rifleman", 9.1, -19.4, 180)                         # The gate's lane
    d.g("autorifleman", 11.9, -19.4, 180)
    d.o(HB3, 8.6, -25.0, 180)                                # The chicane: the gate is reached in an S
    d.o(HB3, 12.4, -28.6, 180)
    d.o(WIRE, 2.2, -24.8, 180)                               # Wire before the square face's embrasure,
    d.o(WIRE, 16.4, -24.8, 180, road_ok=True)                # the chicane's lane left open
    d.fill(-31.0, 4.0, -17.5, 23.5, 303.5, "w", label="wire outside the old city wall")
    for x, y in ((24.5, -22.5), (27.5, -23.5), (30.5, -22.5), (27.5, 8.0), (30.5, 9.0), (32.5, 7.0)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)          # Hedgehogs: the street both ways
    tower_t4_inside(d)

    d.tier()  # T5: the stronghold: checkpoints on the east street north and south, the junction road, the west
    # road's mouth on the square and the road beyond the old city wall (a 2-high block and a concrete block
    # staggered across each, the men behind sandbags at the chicane's exit); a second walled yard out in the square
    # (2-high, its own gate and chicane, a GMG's embrasure and a bag tower); the mortar in the north yard; AT on the
    # roof over the street, an AT man at the gate; the kill zone inside
    d.checkpoint(29.4, 17.0, 10, out=6.0, side=1, roles=("autorifleman", "rifleman"))
    d.checkpoint(28.8, -31.5, 182, out=-5.5, side=1, roles=("autorifleman", "rifleman"))
    d.checkpoint(35.0, -13.0, 92, out=5.0, side=-1, roles=("autorifleman", "rifleman"))
    d.checkpoint(-31.0, -18.5, 240, width=6.0, out=-4.5, roles=("rifleman", "autorifleman"), bag_at=-8.0)
    d.checkpoint(-35.0, 4.2, 34, out=-6.0, roles=("autorifleman",))
    d.embrasure(1.8, -30.5, 180, role=None)                  # The forward yard's HMG fires on through this one
    d.fill(-10.5, -30.5, 0.3, -30.5, 180, "B", label="outer yard's square face, corner to bags", past=0.2)
    d.fill(-10.0, -20.0, -10.0, -31.2, 270, "B", label="outer yard's west side")
    d.o(BARGATE, 10.5, -30.5, 180)
    d.fill(3.3, -30.5, 8.0, -30.5, 180, "B", label="outer yard's square face, bags to gate")
    d.embrasure(15.5, -30.5, 165, role="gmg", line_face=180)
    d.fill(13.0, -30.5, 14.0, -30.5, 180, "B", label="outer yard's square face, gate to GMG")
    d.fill(17.0, -30.5, 22.2, -30.5, 180, "B", road_ok=True, label="outer yard's square face, GMG to corner")
    d.fill(20.9, -29.2, 20.9, -20.0, 90, "B", road_ok=True, label="outer yard's street side")
    d.tower(-4.5, -26.5, 270, "marksman")
    d.o(HB3, 8.6, -33.8, 180)
    d.o(HB3, 12.4, -35.6, 180)
    d.s("mortar", -11.0, 12.5, 30)
    d.g("at", 10.5, -18.4, 180)
    tower_t5_inside(d)


def pyrgos(d):
    """Pyrgos: the tower stands in its own block. A city wall runs down the east side (x 19) with the hill rising
    behind it (5-7 m higher at x 30-40: high ground looking into the compound); to the north a low concrete wall
    (y 13.3) and a city wall (y 17) with a lane between them, open to the west; to the west and south only pipe
    fences (low, see-through; they stop a gun's fire in the game), the open lot west and the treed square south,
    the road 57 m south. The approaches: the square from the south (in front of the main door, the main one), the
    west lot, the north lane from the west, and fire from the hill over the east wall. The occupier builds the west
    and south sides itself."""
    tower_t1(d, (4.0, -10.6), door_post=(13.6, -9.4))

    d.tier()  # T2: a C of sandbags square with the main door, off the porch: a long bag across, shorts back to
    # the porch at its ends, the pair inside it
    d.o(LONG, 10.5, -11.4, 180)
    d.o(SHORT, 8.6, -10.5, 270)
    d.o(SHORT, 12.4, -10.5, 90)
    d.g("rifleman", 9.9, -10.1, 180)
    d.g("autorifleman", 11.1, -10.1, 180)
    tower_t2_inside(d)

    d.tier()  # T3: the compound closed. The south front: the west block's blank face (x -16.5..-0.5) with
    # H-barriers either side of it: the west yard's mouth (to x -24.6, past the west wall's line), and from the
    # block's corner across the porch's front to a bar gate on the door's axis and on into the east wall (y -12.9);
    # the west side a blank Mil wall (x -23.6) from the low north wall down to the mouth; men behind them, the back
    # door's post; the roof HMG over the square, a GMG on the roof's west side over the west lot (clear of the roof's
    # low walls), the window marksman over the hill
    d.fill(-24.6, -12.9, -15.5, -12.9, 180, "H", label="west yard's mouth, to the block")
    d.fill(-23.6, 14.4, -23.6, -12.0, 270, "M", label="west wall, low north wall to the mouth")
    d.o(BARGATE, 10.5, -12.9, 180)                           # x 8 .. 13
    d.fill(-1.5, -12.9, 7.9, -12.9, 180, "H", label="porch line, block to gate")
    d.fill(13.1, -12.9, 19.6, -12.9, 180, "H", label="porch line, gate to east wall")
    d.post("autorifleman", -14.8, 10.6, 0)
    d.g("rifleman", -19.0, -10.9, 180)
    d.g("autorifleman", 1.0, -11.1, 180)
    tower_t3_inside(d)
    d.s("gmg", -14.5, -5.5, 270, ROOF)

    d.tier()  # T4: the fort. A bastion walled out in front of the west block with 2-high H-barriers (y -16.4),
    # the HMG's embrasure in it firing down the fence's gap into the square, its west side tied back to the mouth;
    # the outer face on (inside) the fence line (y -17.0) from the bastion to the east wall, 2-high, its gate on the
    # door's axis; bag towers out in front at the outer face's ends (their platforms over the square); the north
    # lane shut where it meets the west wall; a chicane at the fence's gap in front of the gate; wire along the fence
    # line west of the gap, hedgehogs across the square's open middle (vehicles from the road); an HMG on the roof's
    # east side against the hill; men along the porch line
    d.embrasure(-7.2, -16.4, 175, line_face=180)             # The HMG down the fence's gap
    d.fill(-18.0, -16.4, -8.4, -16.4, 180, "B", label="bastion face, west corner to HMG")
    d.fill(-6.0, -16.4, 0.4, -16.4, 180, "B", label="bastion face, HMG to outer face")
    d.fill(-17.4, -12.0, -17.4, -17.4, 270, "H", label="bastion's west side, mouth to face")
    d.o(BARGATE, 10.5, -17.0, 180)                           # The outer gate on the door's axis
    d.fill(-0.4, -17.0, 8.0, -17.0, 180, "B", label="outer face, bastion to gate")
    d.fill(13.0, -17.0, 19.6, -17.0, 180, "B", label="outer face, gate to east wall")
    d.tower(1.5, -22.2, 270, "marksman", "autorifleman")     # Bastion towers out in front of the outer face,
    d.tower(15.3, -23.8, 180, "marksman")                    # either side of the chicane
    d.fill(-23.5, 13.0, -23.5, 17.6, 270, "H", label="north lane shut at the west wall")
    d.o(HB3, 8.3, -21.4, 180)                                # The chicane: the fence gap (x 6-10.6) masked
    d.fill(-24.0, -20.6, -13.0, -20.6, 180, "w", label="wire, west of the fence")
    d.fill(-12.0, -20.6, -2.8, -20.6, 180, "w", label="wire, east of the fence")
    for x, y in ((-1.5, -30.5), (4.0, -30.5), (9.0, -31.0), (14.0, -31.5), (16.5, -29.0)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.s("hmg", 10.8, 6.0, 90, ROOF)
    d.g("autorifleman", 3.6, -11.0, 180)
    d.g("rifleman", 6.0, -11.0, 180)
    d.g("rifleman", -8.0, 11.8, 270)                         # Along the back strip
    tower_t4_inside(d)

    d.tier()  # T5: checkpoints on the square's path from the road and on the west lot (an H-barrier and a
    # concrete block staggered), a roadblock in the north lane; a bunker on the hill outside the east wall denying
    # the high ground; the north lane filled 2-high; the mortar behind the tower; AT on the roof over the square,
    # an AT man at the gate; the kill zone inside
    d.checkpoint(8.0, -36.0, 180, out=5.0, roles=("autorifleman", "rifleman"))
    d.checkpoint(-36.0, -8.0, 270, out=-6.0, roles=("autorifleman", "rifleman"))
    d.fill(-31.0, 13.0, -31.0, 18.0, 270, "H", label="north lane's roadblock")
    d.g("rifleman", -29.4, 14.6, 270)
    d.g("autorifleman", -29.4, 16.0, 270)
    d.bunker(27.0, -4.0, 70)
    d.fill(-22.6, 15.25, 19.6, 15.25, 0, "B", label="north lane filled 2-high")
    d.s("mortar", 0.0, 11.0, 90)
    d.g("at", 13.6, -11.0, 180)
    tower_t5_inside(d, at=(7.0, -5.8, 180))


# ================================================================ House_Big_01 (Athira, Zaros)
# The two-storey house (model plan): the ground floor (-2.47): the main room (x -1..4, y -7..-2, with a nook to
# y 1), its door (-1.8, -6.1) off the veranda; the veranda (x -4..-3, y -7..2) along the west side, covered by the
# balcony above, open to the west, the main door (-3.3, -7.3) at its south end; the hall (x -4..0, y 2) with the
# stairs; the north room (x -4..4, y 4..7) with the side door (4.9, 5.6) facing east. The upper floor (0.95): the
# south room and the balcony over the veranda (x -4..4, y -7..-4; the balcony x -4..-3 the length of the
# house), the north room (y 4..7); windows east (x 5: y -5.25, -2.1, 5.5).
H0, H1 = -2.47, 0.95


def house_t1(d, flag, door_face=180):
    """T1: the desk in the main room (the chair by the east wall, both facing it), the map board on the west
    wall; gendarmes on the veranda by the main door (looking out of it, or along the veranda where the main door
    is blocked) and in the main room; the flag."""
    d.tier()
    d.o(DESK, 2.2, -3.4, 90, H0)
    d.o(CHAIR, 3.8, -3.4, 90, H0)
    d.o(BOARD, -1.1, -3.8, 270, H0)
    d.o(FLAG, *flag, 180, flag=True, nudge=1.0)
    d.g("gendarme", -3.5, -5.6, door_face, H0)
    d.g("gendarme", 1.2, -1.0, 200, H0)


def house_t5_inside(d):
    """T5: the kill zone inside. A rifleman at the veranda's north end covers its 8 m down to the main door; the
    main room's door off the veranda (-1.8, -6.1) is covered by an MG behind a long bag at the room's east side
    (5 m off, the length of the room) and by a rifleman in the nook (crossing fire); the north room's side door
    covered from the room's far side; upstairs a rifleman across the south room to the balcony door, the marksman
    at the east window."""
    d.g("rifleman", -3.5, -0.2, 180, H0)
    d.o(LONG, 2.6, -6.0, 270, H0)
    d.g("mg_gunner", 3.7, -5.9, 270, H0)
    d.g("rifleman", 0.6, 0.0, 210, H0)
    d.g("rifleman", -2.8, 5.5, 90, H0)
    d.g("rifleman", 2.6, -6.0, 270, H1)
    d.g("marksman", 4.2, -2.1, 90, H1)


def athira(d):
    """Athira: the house stands in a dense block. North: House_Small_02 hard behind it. East: a courtyard
    (x 5..20, y -8..7) closed north by a city wall with a 4.5 m opening (x 12.5-17) onto a strip that runs east to
    the east road, and east by the shop block. South: in front of the main door, open ground to House_Big_02's tip
    and a lane south (x -4..4) between it and a city wall that runs south from the door's west side (x -4.5). West:
    an open lot (x -13..-5, y -8..-1) between building blocks to the west road, a lane north (x -12.5..-6) and a
    lane south (x -15..-5) beyond the city wall. The approaches: the west lot from the west road, the south lane,
    the west lane, the strip from the east road, and a narrow gap south-east between House_Big_02 and the shop."""
    house_t1(d, (5.6, -9.4))

    d.tier()  # T2: a C square with the main door (the city wall its west side): a long bag across 3 m out, a short
    # back to the house on its east; the side door's C (the courtyard wall its north side); the balcony over the
    # west lot
    d.o(LONG, -2.8, -10.4, 180)
    d.o(SHORT, -1.0, -9.4, 90)
    d.g("rifleman", -3.4, -9.2, 180)
    d.g("autorifleman", -2.2, -9.2, 180)
    d.o(LONG, 7.4, 5.4, 90)
    d.o(SHORT, 6.5, 3.6, 180)
    d.g("rifleman", 6.2, 5.4, 90)
    d.g("rifleman", -3.6, -3.4, 270, H1)

    d.tier()  # T3: the compound closed, 2-high. The west lot's mouth (House_Small_01's corner to the scaffolding
    # on House_Big_01) walled across, the HMG's embrasure in it facing the west road (40 m down the alley); the
    # lane north (the scaffolding to House_Small_02) walled across, an embrasure left in it for a gun up the lane
    # (T4); the courtyard's opening (between its north wall's end and the pillar) walled; the south front (y -12.6)
    # from the city wall to the shop: the bar gate before the main door, the GMG's embrasure covering the lane south,
    # low H-barriers the men fire over to x 9, then 2-high to the shop; men behind the lines, upstairs at the east
    # windows
    d.embrasure(-16.6, -6.7, 270)                            # The HMG down the alley west
    d.embrasure(-16.6, -4.1, 270, role=None)                 # A second embrasure beside it (T5: the AT gun)
    d.fill(-16.6, -3.0, -16.6, 0.0, 270, "H", label="west mouth, bags to the scaffolding")
    d.closed(-16.6, -8.1, -16.6, -2.0, 270, "west mouth: the two embrasures' bags")
    d.fill(-17.4, -9.4, -3.8, -9.4, 180, "B", label="the lot's south side, House_Small_01 to city wall")
    d.embrasure(-9.4, 8.6, 0, role=None)                     # The lane's (T4: a gun up the lane)
    d.fill(-11.0, 8.6, -14.0, 8.6, 0, "B", label="lane north, embrasure to the scaffolding")
    d.fill(-7.8, 8.6, -4.6, 8.6, 0, "B", label="lane north, embrasure to House_Small_02")
    d.fill(11.4, 7.4, 17.8, 5.7, 15, "B", label="the courtyard's opening, wall end to pillar")
    d.o(BARGATE, -1.75, -12.6, 180)
    d.o(ROUND, 2.7, -12.6, 0)                                # The GMG's embrasure (the gun 2.4 m back: clear of
    d.s("gmg", *off(2.7, -12.6, 190, -2.4), 190)             # the low line beside it), down the lane south
    d.fill(0.5, -12.6, 1.5, -12.6, 180, "B", label="south front, gate to GMG")
    d.fill(3.9, -12.6, 9.4, -12.6, 180, "H", label="south front, GMG to x 9 (low)")
    d.fill(8.8, -12.0, 24.5, -12.0, 180, "B", label="south front, x 9 to the shop")
    d.closed(-4.6, -12.6, -0.6, -12.6, 180, "south front: bar gate")
    d.g("rifleman", -14.6, -2.0, 270)                        # Over the mouth's low H-barriers
    d.g("rifleman", -11.4, 7.2, 0)                           # Over the lane line's low end
    d.g("autorifleman", 6.6, -11.0, 180)
    d.g("rifleman", 8.0, -11.0, 180)
    d.g("rifleman", 4.2, -5.3, 90, H1)
    d.g("marksman", 4.2, 5.5, 90, H1)

    d.tier()  # T4: the fort. A bag tower in the courtyard (over the south front and the south-east gap); a bag
    # bunker out in the alley west of the mouth (the west road); the HMG up the lane north through its embrasure;
    # a chicane of low concrete blocks in the south lane (staggered: the gate is reached in an S, the GMG fires
    # over them); wire across the alley; hedgehogs in the south-east gap, the strip's mouth on the east road and
    # the alley; the balcony MG; men on the south front
    d.tower(12.6, -4.0, 180, "marksman", "autorifleman")
    d.s("hmg", *off(-9.4, 8.6, 0, -GUN_BACK), 0)
    for x in (-3.2, -0.6, 2.0):
        d.o(JERSEY, x, -16.6, 180)
    for x in (-0.2, 2.4, 5.0):
        d.o(JERSEY, x, -20.6, 180, nudge=0.5)
    d.fill(-24.2, -1.0, -24.2, -8.0, 270, "w", label="wire across the alley")
    for x, y in ((19.6, -19.5), (19.8, -22.0), (28.5, 9.0), (28.5, 11.0), (-10.0, -15.0), (-7.0, -17.0)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.g("mg_gunner", -3.6, -0.6, 270, H1)
    d.g("rifleman", 1.2, -11.0, 180)
    d.g("rifleman", 5.2, -11.0, 180)
    d.g("rifleman", -0.4, -10.6, 180)
    d.g("rifleman", 6.2, 4.0, 120)

    d.tier()  # T5: checkpoints in the alley west (an AT gun behind it), in the south lane and across the strip to
    # the east road (closed with a firing slot); the mortar in the courtyard; an AT man at the gate; the kill zone
    # inside
    d.checkpoint(-31.5, -4.4, 270, width=6.5, out=-4.0, hb=HB3, block=JERSEY, bag_at=-2.5)
    d.s("at", *off(-16.6, -4.1, 270, -GUN_BACK), 270)       # Through the mouth's second embrasure
    d.checkpoint(-0.6, -27.0, 180, width=5.0, side=1, hb=HB3, block=None)  # The lane: too narrow to stagger
    d.o(ROUND, 20.0, 9.2, 270)                               # The strip: closed, a firing slot in it
    d.fill(20.0, 7.8, 20.0, 2.5, 90, "H", label="the strip closed, slot to the courtyard wall")
    d.fill(20.0, 10.6, 20.0, 13.4, 90, "H", label="the strip closed, slot to House_Big_02")
    d.g("rifleman", 18.6, 8.7, 90)
    d.g("autorifleman", 18.6, 9.7, 90)
    d.s("mortar", 6.8, -1.5, 180)
    d.g("at", 0.6, -11.0, 180)
    house_t5_inside(d)


def zaros(d):
    """Zaros (the probe's real walls, model coordinates): the house (x -4.5..5.5, y -7.5..7.5) has Addon_03 hard
    behind it (x -4.8..5.3, y 7.7..16) and the shop hard against its front (x -7.3..6.7, y -16.3..-7.3; its box runs
    on to x 12.3). West of the row lies a yard walled all round by city walls (x -21..-4.5, y -15.5..7.5, Addon_02
    in it), with a 2 m gap in its south wall (x -13.8..-11.8) and a passage north beside the house (x -9.3..-4.5);
    the main door's way out is the veranda's open west side, into the yard. East of the row a strip (x 5.5..12.5)
    runs to the main road (x 12.5..23, north-south), the side door facing it; a low-walled garden (x 4..8,
    y 8..14.6) north of the strip. South of the shop open ground walled on its south by a low stone wall (y -23.2,
    x -18..9.2). North of the yard wall the open ground north (x -16..-5, y 10..22), reached from the road by a
    passage north of Addon_03 and from the north-west by a gap in its walls. The approaches: the road from north
    and south (vehicles), the open ground north, the open ground south.
    T3 closes the yard (its gap) and the strip (a 2-high line and a bar gate at the road, tied to the shop and the
    garden wall), with gun pits at the road's edge north and south; T4 rings the whole block, 2-high on the road
    and its corners: the guns' pits become embrasures, bag towers in the yard and the south ground, the gate's
    chicane; T5 adds checkpoints up and down the road, a second line inside the stone wall and the kill zone."""
    house_t1(d, (-10.6, 1.6), door_face=270)

    d.tier()  # T2: the veranda's open side held by a C square with it (a long bag across, shorts back to the house),
    # the side door held by a long bag across it (the strip's low walls on its north); the balcony over the yard
    d.o(LONG, -9.1, -3.5, 270)                               # (A metre further out than round 4: a short bag
    d.o(SHORT, -8.2, -5.5, 180)                              # cut into the house's veranda)
    d.o(SHORT, -8.2, -1.5, 0)
    d.g("rifleman", -7.8, -4.1, 270)
    d.g("autorifleman", -7.8, -2.9, 270)
    d.o(LONG, 8.3, 5.6, 90)
    d.g("rifleman", 7.0, 5.6, 90)
    d.g("rifleman", -3.6, -3.4, 270, H1)

    d.tier()  # T3: the compound closed: the yard's north passage a city gate (a post behind it), its south gap
    # H-barriers (a man behind); the strip shut at the road by a 2-high line from the shop's corner to a bar gate
    # square with the side door, tied on into the garden wall; gun pits at the road's edge at the block's corners,
    # the HMG down the road south, the GMG up it north; upstairs the east windows
    d.o(CITYGATE, -6.8, 7.7, 0)
    d.closed(-9.6, 7.8, -4.2, 7.8, 0, "yard's north passage: city gate")
    d.post("rifleman", -6.8, 4.6, 0)
    d.fill(-14.4, -15.4, -11.2, -15.4, 180, "H", label="yard's south gap")
    d.g("rifleman", -12.8, -13.4, 180)
    d.fill(4.8, -6.0, 11.8, -6.0, 180, "B", road_ok=True, label="strip's south leg, house to x 11.8")
    d.o(BARGATE, 10.5, 5.6, 90, road_ok=True)
    d.fill(10.5, -6.0, 10.5, 3.1, 90, "B", road_ok=True, label="strip's road line, leg to gate")
    d.fill(12.8, 8.6, 7.0, 8.6, 0, "B", road_ok=True, label="strip's north tie, gate to garden wall")
    d.gun("hmg", *off(13.2, -23.9, 165, -GUN_BACK), 165, road_ok=True)
    d.gun("gmg", *off(12.8, 16.2, 15, -GUN_BACK), 15, road_ok=True)
    d.g("autorifleman", 9.2, 4.6, 90)                       # At the gate, looking through it
    d.g("rifleman", 4.2, -5.3, 90, H1)
    d.g("marksman", 4.2, 5.5, 90, H1)

    d.tier()  # T4: the fort: the block ringed. The east face 2-high on the road's edge (x 14.8) from the north face
    # to the south face, its bar gate in line with the strip's; the north face 2-high from Addon_03 to the road, the
    # GMG's embrasure in it; the south face from the stone wall's corner to the road, the HMG's embrasure in it;
    # the south ground shut on its west (x -16.6, wall to stone wall); the stone wall and the yard's city walls the
    # rest. Bag towers in the yard's north-west (over the wall to the open ground north) and the south ground (over
    # the west line); an HMG over the west line; a blast wall on the road before the gate (in by its ends);
    # wire on the open ground north and outside the stone wall, hedgehogs on the road both ways
    d.fill(4.9, 16.2, 11.3, 16.2, 0, "B", road_ok=True, label="north face, Addon_03 to the GMG")
    d.fill(14.3, 16.2, 16.3, 16.2, 0, "B", road_ok=True, label="north face, GMG to the corner")
    d.o(BARGATE, 15.0, 5.4, 90, road_ok=True)
    d.fill(15.0, 15.2, 15.0, 7.9, 90, "B", road_ok=True, label="east face, north corner to gate")
    d.embrasure(10.4, -23.9, 185, role=None, road_ok=True)                 # The AT gun's (T5), beside the HMG's
    d.fill(14.6, -23.9, 15.9, -23.9, 180, "B", road_ok=True, label="south face, HMG to the corner")
    d.closed(8.9, -23.9, 15.9, -23.9, 180, "south face: stone wall, AT and HMG bags, block")
    d.fill(15.0, 2.9, 15.0, -22.6, 90, "B", road_ok=True, label="east face, gate to south corner")
    d.embrasure(-16.6, -18.8, 270)                           # The HMG through the south ground's west side
    d.fill(-16.6, -15.4, -16.6, -18.0, 270, "H", label="south ground's west side, north")
    d.fill(-16.6, -19.6, -16.6, -23.1, 270, "H", label="south ground's west side, south")
    d.tower(-6.0, -19.8, 270, "marksman", "autorifleman")
    d.fill(-15.8, 10.6, -22.6, 18.1, 228, "H", label="the open ground north's west gap")
    d.g("rifleman", *off(-19.2, 14.35, 228, -1.8), 228)
    d.o(HBBIG, 19.0, 5.6, 90, road_ok=True)                 # The blast wall before the gate: in round its ends
    d.g("rifleman", 13.2, 4.0, 90)                            # The gate's lane, looking through it
    d.g("autorifleman", 13.2, 7.2, 90)
    d.fill(-14.0, 13.4, -5.6, 13.4, 0, "w", label="wire, open ground north")
    d.fill(-15.0, -25.8, 8.0, -25.8, 180, "w", label="wire, outside the stone wall")
    for x, y in ((14.5, 30.0), (17.5, 31.5), (20.5, 30.0), (18.5, -26.8), (21.5, -28.3), (22.8, -25.4)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)
    d.g("mg_gunner", -3.6, -0.6, 270, H1)
    d.g("autorifleman", 0.0, -5.0, 270, H1)
    d.g("rifleman", -15.2, -16.6, 270)                       # Over the west side's low H-barriers
    d.g("rifleman", -15.2, -21.4, 270)

    d.tier()  # T5: checkpoints on the road north and south (each with a bag bunker at the roadside); a second line
    # inside the stone wall; a bag bunker on the open ground north; the mortar in the yard; an AT gun in a second
    # embrasure of the north face (up the road), an AT man at the gate; the kill zone inside
    d.checkpoint(19.0, 27.0, 0, width=9.0, out=6.0)
    d.checkpoint(18.0, -39.5, 180, width=9.0, out=-7.5, roles=("autorifleman", "rifleman"))
    d.s("mortar", -10.5, -6.0, 30)
    d.s("at", *off(10.4, -23.9, 185, -GUN_BACK), 185)            # Down the road south, through its embrasure
    d.g("at", 12.0, 5.6, 90)
    d.g("rifleman", 3.0, 4.6, 270, H1)                       # Upstairs, the north room down to the stair head
    house_t5_inside(d)


TOWNS = {"Kavala": kavala, "Pyrgos": pyrgos, "Athira": athira, "Zaros": zaros}


def build(name, towns=None):
    towns = towns or tl.load()
    t = towns[name]
    d = Draft(t)
    TOWNS[name](d)
    return t, d


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    show = None
    if "--map" in sys.argv:
        show = int(sys.argv[sys.argv.index("--map") + 1])
        args = [a for a in args if a != str(show)]
    towns = tl.load()
    for name in TOWNS:
        if args and name not in args:
            continue
        t, d = build(name, towns)
        tiers = d.finish()
        if "--log" in sys.argv or any("SKIP" in l for l in d.log):
            for line in d.log:
                print(f"  {name}: {line}")
        for line in lines_of_fire(t, tiers):
            print(f"  {name}: SHORT {line}")
        if "--audit" in sys.argv or "--log" in sys.argv:
            for line in d.audit():
                print(f"  {name}: RUN {line}")
        probs = tl.check(t, tiers)
        if probs:
            print(f"{name}: PROBLEMS {probs}")
        else:
            path = tl.write(t, tiers)
            print(f"{name}: (things, guards, statics) per tier {counts(tiers)} -> {os.path.relpath(path, tl.ROOT)}")
        if show:
            print(overlay(t, tiers[show - 1]))


if __name__ == "__main__":
    main()
