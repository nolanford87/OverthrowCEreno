"""
Mayor's office layouts, group "strongholds" (Overthrow CE): the four 5-tier towns.
  Kavala           Land_Hospital_main_F, the hospital with its two wings (the user's choice, replacing the tower)
  Pyrgos           Land_Offices_01_V1_F, the tower block on its podium
  Athira, Zaros    Land_House_Big_01, the two-storey house with the veranda
Run from the repository root:
    python tools/officegen/drafting/strongholds.py [town ...] [--map N] [--audit] [--log]
Writes tools/officegen/layouts/drafts/<town>.txt (tl.write checks each first) and prints, per tier from 3 and per
ring, whether a man gets out (closure(): the in-game check walks one by the engine's route finding from the office's
door to points 60 m out; this one floods a 0.2 m grid from the door to 44 m out, past the office, the neighbours'
real walls (their box where unplanned), rocks and the drafts' pieces at their measured size, a man 0.5 m wide; the
probe's walls are all low here and stop him only where a line ends into one). --audit prints every run's line audit;
--map N prints tier N over the probe's map (1 m cells): W tall wall (Mil wall, the concrete walls), H H-barrier,
b sandbags, * a way out; # building (its real walls), % its box beyond them, = wall, : road, O the office.

Everything below is in the office's MODEL coordinates (x right, y forward out of the model's front; mdir 0 = +y,
90 = +x). Both buildings' main doors face model -y, so in the notes "south" is -y, "east" +x, "north" +y, "west" -x.

Pass 1 (DESIGN_BRIEF.md, "The work is now split into passes"): walls only, the same ladder in all four:
  T1 nothing.
  T2 sandbags against the office: at its doors (never boxing a door in), its porch and its ground-floor windows.
  T3 a tight ring of H-barriers round the office, tied into the office and the neighbours solid to their box, no
     opening.
  T4 an outer ring of high walls (Mil walls, the 1 m concrete wall to fit) round the whole ground, T3 inside it.
  T5 a second high-walled ring hugging T3 (1.7 m outside it): two complete high rings.
The probed walls (low city walls with railings, concrete garden walls, stone walls, pipe fences) are never a ring's
side: a ring crossing one ends into it from both sides (a junction).
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
MIL, MILC = "Land_Mil_WallBig_4m_F", "Land_Mil_WallBig_Corner_F"
CNCW4, CNCW1 = "Land_CncWall4_F", "Land_CncWall1_F"
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
           HBW4: "W", HBW6: "W", HBWC: "W", MIL: "W", MILC: "W", CNCW4: "W", CNCW1: "W", CITYGATE: "G", BARGATE: "G", WIRE: "w", HOG: "x",
           CNC: "c", CNC4: "c", JERSEY: "c", BUNKER: "B", TOWER: "T"}


def fwd(d):
    r = math.radians(d)
    return math.sin(r), math.cos(r)


def bearing(x0, y0, x1, y1):
    """The model direction from (x0, y0) to (x1, y1) (0 = +y, 90 = +x)."""
    return math.degrees(math.atan2(x1 - x0, y1 - y0)) % 360


def off(x, y, d, f, lat=0.0):
    """(x, y) moved f metres along model direction d and lat metres to its right."""
    a, b = fwd(d), fwd(d + 90)
    return x + a[0] * f + b[0] * lat, y + a[1] * f + b[1] * lat


# ---------------------------------------------------------------- footprints and overlaps (model xy)

GATES = (BARGATE, CITYGATE)
# Sizes measured in the game (boundingBoxReal [length, depth], review round 3) where townlib has none yet
REAL = {HBBIG: (9.0, 2.6), TOWER: (6.4, 9.8), BUNKER: (5.0, 5.7), CNC4: (7.6, 1.8), JERSEY: (2.6, 0.4),
        WIRE: (8.5, 2.1), HB5: (5.8, 1.7), HB3: (3.6, 1.8), HB1: (1.4, 1.7), MIL: (4.1, 1.1), CNC: (1.8, 1.8)}
TOWER_SITE = (5.6, 9.8)  # The bag tower's footprint against the site (see clips()): round 4's towers stood 2.9 m
# (across) and 3.8 m (front) off a building's box and a fence without touching them, round 5's touched a fence 5.3 m
# behind it: its box is the measured 9.8 deep but sits TOWER_SHIFT m back of its origin (the ladder side)
TOWER_SHIFT = -1.1
TOWER_LIFT = 0.5  # Its men are put this far over the platform and drop onto it (round 5: men put at the platform's
# measured height in Kavala's inner yards were pushed 1-2 m back off it; the probe's ground there is flat, so the
# surface they stand on is likely higher than the terrain grid says)
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
TALL_WALLS = ("canal_wall",)  # Probed walls that are real barriers (5.5 m canal walls by Kavala's cliff)
UPGRADE = [False]  # Set while a run upgrades a low wall (stands on and into it along its length: the brief allows it)
# Neighbours the in-game walk crosses although the probe gives them a box only (not solid to it): closure() treats
# them as open ground; tl.check() still keeps pieces out of their boxes
SOFT = {"Athira": ("Land_i_House_Small_02_V1_F",),
        "Kavala": ("Land_Hospital_side1_F", "Land_Hospital_side2_F", "office")}  # The hospital: the walk crosses its
# probed ground floor and its wings' boxes (round 2), so the rings close on themselves


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
    composite = any(o["kind"] == "part" for o in t.objs)
    if any(_sat(poly, r) for k, mdl, r in site_rects(t) if not (UPGRADE[0] and k == "wall") and not (composite and k == "part")):
        return True
    if composite:  # An office of several pieces: tl.check() leaves pieces near it to the in-game clips
        return False
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


def _centre(t, it):
    """A piece's footprint centre in model xy (a bag tower's box sits back of its origin)."""
    m = t.to_model(it[2])
    if it[0] == "object" and it[1] == TOWER:
        d = (yaw(it) - t.dir) % 360
        return off(m[0], m[1], d, TOWER_SHIFT)
    return m[0], m[1]


def _rect(t, it, L, D):
    m = _centre(t, it)
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
    m = _centre(t, it)
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
        self.objs = [(o, plan_of(o["model"]) if o["kind"] not in ("wall", "rock") else None) for o in t.objs if o["kind"] in ("building", "part", "wall", "rock")]

    def at(self, x, y, any_box=False, walls=False):
        """(kind, model, how) of what's solid at model (x, y): how "plan" (its real walls) or "box" (a neighbour
        without a plan); any_box: also "boxonly", inside a planned neighbour's box but outside its walls (a piece's
        middle may not go there: tl.check()); walls: the probe's walls too (none of the four towns' walls is a real
        barrier: low city walls with railings, garden, stone and pipe fences, so a line never ends on one unless it
        is a junction where two runs both end into it); None."""
        soft = SOFT.get(self.t.name, ())
        if "office" not in soft and self.t.on_office(x, y, 0.1, 0.1):
            return ("office", self.t.cls, "plan")
        w = self.t.to_world(x, y, 0)
        for o, p in self.objs:
            if (o["kind"] == "wall" and not walls and not o["model"].startswith(TALL_WALLS)) or o["model"] in soft:
                continue
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
        self.wall_ends = False
        self.rings = {}  # Tier -> {ring name: [items]} for the closure check
        self.start = None  # Where closure() starts (None: 1.5 m out of the main door)

    def tier(self):
        self.cur = list(self.tiers[-1]) if self.tiers else []
        self.tiers.append(self.cur)

    def drop(self, ring):
        """Take a ring's pieces (placed in any tier below) out of this tier: a tier may drop what it replaces."""
        gone = [it for rings in self.rings.values() for it in rings.get(ring, [])]
        self.cur[:] = [it for it in self.cur if not any(it is g for g in gone)]

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
    # Pass 1's materials: "H" 1-high H-barriers, "X" 2-high (HBarrier_Big, the 1-high pieces to fit), both for the
    # T3 ring; "M" the high wall (Mil wall, the 1 m concrete wall to fit) for the T4 and T5 rings
    FAMILIES = {"H": (HB5, (HB3, HB1)), "X": (HBBIG, (HB3, HB1)), "M": (MIL, (CNCW1,)), "w": (WIRE, ())}
    JOINT, END, FREE = (0.3, 0.6), (0.3, 0.38), (-0.3, 0.6)  # END 0.38: tl.check() takes HB1/HB5 for longer  # FREE: an end that only meets a crossing run
    END_WALL = (0.3, 0.6)  # Into a wall or another piece (tl.check() doesn't hold pieces out of walls)
    END_SHORT = (0.15, 0.22)  # A 1 m concrete piece into a building or a wall
    END_OFFICE = (-0.35, -0.2)  # Short of the office's probed face (rounds 1-2: flush still clipped its real walls)

    def solid(self, x, y):
        """What closes a run's end at model (x, y): the site (a planned neighbour's box too: a piece can't go further
        in; a probed wall only for a run ending on a junction, self.wall_ends), or a barrier piece of this tier
        standing there."""
        h = self.site.at(x, y, any_box=True, walls=self.wall_ends)
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

    def choose(self, gap, family, free, site_end=(False, False), building=(True, True), hard=(False, False), office=(False, False)):
        """The pieces closing a gap: ([(class, start, end)] from 0 (the first face) along the run, the overlaps),
        the joints overlapping JOINT and the ends running END into what closes them (FREE at a free end); None when
        nothing fits. A concrete block never ends a run against the site (tl.check() takes it for 4 m long)."""
        main, fin = self.FAMILIES[family]
        classes = (main,) + fin
        rng = [self.FREE if f else (self.END_OFFICE if o else (self.END if b else self.END_WALL)) for f, b, o in zip(free, building, office)]
        joint = self.JOINT
        if family == "w":  # Wire coils overlap as much as they need to (an obstacle, not a wall)
            joint, rng = (0.3, 6.0), [(-1.5, 0.5)] * 2
        best = None
        for na in range(0, 30):
            for nb in range(0, 6 if len(classes) > 1 else 1):
                for nc in range(0, 4 if len(classes) > 2 else 1):
                    k = na + nb + nc
                    if k == 0:
                        continue
                    S = na * length(main) + (nb and nb * length(classes[1])) + (nc and nc * length(classes[2]))
                    # The order: the long pieces at the ends, the blocks in the middle
                    seq = [main] * na + ([classes[1]] * nb if nb else []) + ([classes[2]] * nc if nc else [])
                    shorts = (CNC, CNCW1, HB1)  # Short pieces go mid-run, never against the site
                    longs = [c for c in seq if c not in shorts]
                    blocks = [c for c in seq if c in shorts]
                    if blocks and longs:
                        seq = longs[:1] + blocks + longs[1:]
                    if (site_end[0] and seq[0] == CNC) or (site_end[1] and seq[-1] == CNC):
                        seq = seq[::-1]
                    if (site_end[0] and seq[0] == CNC) or (site_end[1] and seq[-1] == CNC):
                        continue
                    # A 1 m concrete piece runs only 0.15-0.22 m into a building or a wall (tl.check() and clips()
                    # keep its middle, 0.2 m and a 0.1 m pad, out of them)
                    r = [self.END_SHORT if (hard[i] and seq[-i] == CNCW1) else rng[i] for i in (0, 1)]
                    lo = S - joint[1] * (k - 1) - r[0][1] - r[1][1]
                    hi = S - joint[0] * (k - 1) - r[0][0] - r[1][0]
                    if not lo - 1e-6 <= gap <= hi + 1e-6:
                        continue
                    cost = k + 2.5 * (nb + nc) + 0.5 * nc
                    if best is None or cost < best[0]:
                        best = (cost, seq, S, r)
        if not best:
            return None
        _, seq, S, rng = best
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

    def fill(self, x0, y0, x1, y1, face, family="H", z=None, road_ok=False, label="", past=1.5, walls=False, ring=None, upgrade=False):
        """One unbroken run closing the gap along (x0, y0)-(x1, y1): the gap's faces found by walking out from its
        middle (the site's real walls, or a piece of this tier), then the family's pieces butted from face to face,
        the joints overlapping 0.3-0.6 m and the ends running 0.3-0.5 m into what closes them; facing `face`.
        Logged for the audit (audit()); walls: the probe's walls end it too (a junction: both runs end into the
        wall); ring: the ring it belongs to (closure()).
        """
        self.wall_ends = walls
        UPGRADE[0] = upgrade
        (s0, h0), (s1, h1) = self.faces(x0, y0, x1, y1, past, half=size(["object", self.FAMILIES[family][0]])[1] * 0.25 + 0.05)
        L = math.hypot(x1 - x0, y1 - y0)
        ux, uy = (x1 - x0) / L, (y1 - y0) / L
        gap = s1 - s0
        run = {"tier": len(self.tiers), "label": label or f"({x0:.1f},{y0:.1f})-({x1:.1f},{y1:.1f})", "family": family,
               "a": (x0 + ux * s0, y0 + uy * s0), "b": (x0 + ux * s1, y0 + uy * s1), "u": (ux, uy), "face": face,
               "gap": gap, "ends": (h0, h1), "pieces": [], "joints": []}
        self.runs.append(run)
        site_end = tuple(h is not None and h[0] in ("building", "part", "office") for h in (h0, h1))
        bld = tuple(h is not None and h[0] in ("building", "part", "office") for h in (h0, h1))
        hard = tuple(h is not None and h[0] != "piece" for h in (h0, h1))
        offc = tuple(h is not None and h[0] == "office" for h in (h0, h1))
        pick = self.choose(gap, family, (h0 is None, h1 is None), site_end, bld, hard, offc)
        self.wall_ends = False
        if gap <= 0.05:  # Already shut (the pieces at its ends overlap)
            run["over"] = (0.0, 0.0)
            UPGRADE[0] = False
            return run
        if not pick and family == "X":  # Too short a gap for HBarrier_Big: the 1-high pieces
            pick = self.choose(gap, "H", (h0 is None, h1 is None), site_end, bld, hard, offc)
            run["family"] = "H"
        if not pick:
            self.log.append(f"T{len(self.tiers)} SKIP fill {run['label']}: nothing fits {gap:.2f} m")
            UPGRADE[0] = False
            return run
        pieces, val = pick
        run["joints"], run["over"] = val[1:-1], (val[0], val[-1])
        for c, a, b in pieces:
            cx, cy = x0 + ux * (s0 + (a + b) / 2), y0 + uy * (s0 + (a + b) / 2)
            it = self.o(c, cx, cy, face, z, road_ok=road_ok or c == WIRE)
            run["pieces"].append((c, s0 + a, s0 + b, it is not None))
            if it and ring:
                self.rings.setdefault(len(self.tiers), {}).setdefault(ring, []).append(it)
        UPGRADE[0] = False
        run["ring"] = ring
        return run

    def crossings(self, x0, y0, x1, y1):
        """Where the run (x0, y0)-(x1, y1) crosses a probed wall's line: [distance along it], sorted."""
        out = []
        L = math.hypot(x1 - x0, y1 - y0)
        for kind, mdl, poly in site_rects(self.t):
            if kind != "wall":
                continue
            # The wall's centre line: the mid-points of its box's short sides
            sides = [(poly[k], poly[(k + 1) % 4]) for k in range(4)]
            sides.sort(key=lambda e: math.dist(*e))
            (a0, a1), (b0, b1) = sides[0], sides[1]
            px, py = (a0[0] + a1[0]) / 2, (a0[1] + a1[1]) / 2
            qx, qy = (b0[0] + b1[0]) / 2, (b0[1] + b1[1]) / 2
            ux, uy, vx, vy = x1 - x0, y1 - y0, qx - px, qy - py
            den = ux * vy - uy * vx
            if abs(den) < 1e-9:
                continue
            t_ = ((px - x0) * vy - (py - y0) * vx) / den
            s_ = ((px - x0) * uy - (py - y0) * ux) / den
            if 0.0 < t_ < 1.0 and -0.02 <= s_ <= 1.02:
                out.append(t_ * L)
        return sorted(out)

    def run(self, x0, y0, x1, y1, face, family, ring, label, road_ok=False, past=1.5, upgrade=False):
        """A run split at every probed wall it crosses (each a junction: the pieces either side end into the low
        wall), each part filled (fill())."""
        L = math.hypot(x1 - x0, y1 - y0)
        cuts = [c for c in self.crossings(x0, y0, x1, y1) if 0.3 < c < L - 0.3]
        pts = [0.0] + cuts + [L]
        ux, uy = (x1 - x0) / L, (y1 - y0) / L
        for k in range(len(pts) - 1):
            a, b = pts[k], pts[k + 1]
            part = label if len(pts) == 2 else f"{label} ({k + 1}/{len(pts) - 1})"
            self.fill(x0 + ux * a, y0 + uy * a, x0 + ux * b, y0 + uy * b, face, family, road_ok=road_ok,
                      label=part, past=past if k in (0, len(pts) - 2) else 0.3, walls=len(pts) > 2, ring=ring, upgrade=upgrade)

    def piece(self, cls, x, y, d, ring, nudge=0.0, road_ok=False):
        """One piece by hand (a sandbag, a corner), counted in a ring for closure()."""
        it = self.o(cls, x, y, d, nudge=nudge, road_ok=road_ok)
        if it and ring:
            self.rings.setdefault(len(self.tiers), {}).setdefault(ring, []).append(it)
        return it

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
            tall = r["pieces"] is None or all(p[0] in (HBBIG, MIL, MILC, CNCW4, CNCW1, HBW4, HBW6) for p in placed)
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
            z = self.t.ground_model(m[0], m[1]) + TOWER_TOP + TOWER_LIFT
            spots = [(0.0,)] if not below else [(-0.35,), (0.35,)]
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
    m = _centre(t, it)
    L, D = size(it)
    d = (yaw(it) - t.dir) % 360
    lx, ly = tl.rot(x - m[0], y - m[1], -d)
    return abs(lx) <= L / 2 and abs(ly) <= D / 2


# ---------------------------------------------------------------- closure (approximating the in-game check, which
# walks a man by the engine's route finding from the office's door to points 60 m out)
GRID = 0.2      # The closure grid (m)
REACH = 44.0    # Out to here is "out" (the probe reaches 45 m: rings stay inside it)
WALL_NEAR = 0.6  # A probed (low) wall stops a man only this close to a piece (closure())
BODY = 0.25      # A man's half-width: his centre stays this far off anything (gaps under ~0.5 m are shut)
_SITE_GRID = {}


def _cells(poly, g=GRID):
    xs, ys = [p[0] for p in poly], [p[1] for p in poly]
    for i in range(int(math.floor(min(xs) / g)), int(math.ceil(max(xs) / g)) + 1):
        for j in range(int(math.floor(min(ys) / g)), int(math.ceil(max(ys) / g)) + 1):
            yield i, j


def site_grid(t):
    """The cells a man can't stand in for the site: the office (its plan), the neighbours (their real walls and
    floors where planned: a man walks between a box and the wall it holds; their box otherwise) and rocks. The
    probe's walls are left out: none is a real barrier (low walls with railings, stone walls, pipe fences)."""
    if t.name in _SITE_GRID:
        return _SITE_GRID[t.name]
    site, out = Site(t), set()
    b = t.box
    for i, j in _cells([(b[0], b[1]), (b[2], b[3])]):
        if "office" not in SOFT.get(t.name, ()) and t.on_office(i * GRID, j * GRID, 0.1, 0.1):
            out.add((i, j))
    for kind, mdl, poly in site_rects(t):
        if (kind == "wall" and not mdl.startswith(TALL_WALLS)) or mdl in SOFT.get(t.name, ()):
            continue
        for i, j in _cells(poly):
            x, y = i * GRID, j * GRID
            if (i, j) in out or not _in_poly(poly, x, y):
                continue
            if kind in ("rock", "wall"):  # (The walls here: the tall ones only)
                out.add((i, j))
                continue
            h = site.at(x, y)
            if h and h[0] in ("building", "part") and h[1] not in SOFT.get(t.name, ()):
                out.add((i, j))
    _SITE_GRID[t.name] = out
    return out


def _in_poly(poly, x, y):
    """Inside a convex quadrilateral (either winding)."""
    sgn = 0
    for k in range(4):
        ax, ay = poly[k]
        bx, by = poly[(k + 1) % 4]
        c = (bx - ax) * (y - ay) - (by - ay) * (x - ax)
        if c != 0:
            if sgn and (c > 0) != (sgn > 0):
                return False
            sgn = c
    return True


def closure(t, items, start=None):
    """Whether a man gets from the office's main door (1 m out of it) to REACH m out past the site and the given
    pieces (barriers on the ground, wire and hedgehogs left out; their real measured footprints): None when he
    can't (closed), else his way out [(x, y)] and its narrowest point ((x, y), clear width m)."""
    blocked = set(site_grid(t))
    pieces = set()
    for it in items:
        if not (is_barrier(it) and "ground" in it[4]) or it[1] in (WIRE, HOG):
            continue
        L, D = TOWER_SITE if it[1] == TOWER else size(it)
        poly = _rect(t, it, L, D)
        for i, j in _cells(poly):
            if _in_poly(poly, i * GRID, j * GRID):
                pieces.add((i, j))
    blocked |= pieces
    # A low wall counts only where a line ends into it (a junction: the notch a slanted wall leaves between a
    # piece's corner and its face is shut by the wall itself): its cells within WALL_NEAR m of a piece
    k = int(round(WALL_NEAR / GRID))
    for kind, mdl, poly in site_rects(t):
        if kind != "wall":
            continue
        for i, j in _cells(poly):
            if _in_poly(poly, i * GRID, j * GRID) and any((i + a, j + b) in pieces for a in range(-k, k + 1) for b in range(-k, k + 1)):
                blocked.add((i, j))
    k = int(BODY / GRID)
    ring_ = [(a, b) for a in range(-k, k + 1) for b in range(-k, k + 1) if (a or b) and math.hypot(a, b) * GRID <= BODY + 1e-6]
    blocked |= {(c[0] + a, c[1] + b) for c in blocked for a, b in ring_}
    if start is None:
        d = t.door("main")
        start = off(d["model"][0], d["model"][1], d["mdir"], 1.5)
    s0 = (int(round(start[0] / GRID)), int(round(start[1] / GRID)))
    n = int((t.reach - 1.0) / GRID)
    prev, todo = {s0: None}, [s0]
    end = None
    while todo and end is None:
        nxt = []
        for c in todo:
            for dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                k = (c[0] + dc[0], c[1] + dc[1])
                if k in prev or k in blocked:
                    continue
                prev[k] = c
                if k[0] * k[0] + k[1] * k[1] >= n * n:
                    end = k
                    break
                nxt.append(k)
            if end:
                break
        todo = nxt
    if end is None:
        return None
    path, c = [], end
    while c is not None:
        path.append(c)
        c = prev[c]
    path.reverse()

    def clear(c):  # Clear width across this cell: the nearest blocked cell either side, sampled round
        best = 9.9
        for a in range(0, 180, 15):
            ux, uy = math.cos(math.radians(a)), math.sin(math.radians(a))
            w = 0.0
            for sgn in (1, -1):
                r = 0.0
                while r < 3.0 and (int(round(c[0] + sgn * ux * r / GRID)), int(round(c[1] + sgn * uy * r / GRID))) not in blocked:
                    r += GRID / 2
                w += r
            best = min(best, w)
        return best
    narrow = min(path[::2], key=clear)
    return [(c[0] * GRID, c[1] * GRID) for c in path], ((narrow[0] * GRID, narrow[1] * GRID), clear(narrow))


_CROWNS = {}
CROWN = (0.34, 0.75)  # How much of a tree's box half-width its crown blinds a man on the ground, on a tower


def crowns(t):
    """The trees' crowns (model x, y, the probe's box half-width; palms left out: their crowns are high and their
    trunks thin). Round 5: a man 0.4 of it from the trunk on a tower and 0.29 on the ground saw nothing, ones 0.35-0.4 on the
    ground saw (CROWN)."""
    if t.name not in _CROWNS:
        out = []
        for o in t.objs:
            if o["kind"] == "tree" and not any(k in o["model"] for k in ("phoenix", "palm", "cocos")):
                m = t.to_model(o["pos"])
                b = o["box"]
                out.append((m[0], m[1], min(b[2] - b[0], b[3] - b[1]) / 2))
        _CROWNS[t.name] = out
    return _CROWNS[t.name]


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
    d = 0.0 if not raised or aloft else 0.5  # (On the ground or a tower: his own spot may be in a tree's crown)
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
            if not gun:  # A man sees over the low walls (round 5: not through the pipe fences)
                hit = [h for h in hit if "smallwall" not in h[1]]
            if hit:
                return d
            k_ = CROWN[1] if aloft else CROWN[0]
            if (aloft or d <= 0.5) and any(math.hypot(x - cx_, y - cy_) < k_ * r_ for cx_, cy_, r_ in crowns(t)):  # In a tree's crown
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


def overlay(t, items, r=45, path=()):
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
    for x, y in path:
        k = (int(round(x)), int(round(y)))
        if k in grid:
            grid[k] = "*"
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
# The tower block's ground floor (the probe's 1 m plan, model coordinates): solid x -17.5..13.5; the west block
# (x -17.5..-1.5) runs south to y -12.5 (a 16 m ground-floor window in its south face), the stair core's glazed
# front (x -1.5..7.5) is at y -7.5, the porch (x 7.5..13.5) at y -8.5, the main door (10.5, -7.7) facing south;
# the north face y 8.5 with the back door (-14.8, 8.4) facing north; the east face (x 13.5) is blank at ground level.


def tower_t2(d, front=-13.0, wings=False):
    """T2: sandbags against the tower block: a screen of long bags across the main door 2.7 m out (the way out
    round its ends left open, 0.8 m and more: the door is never boxed in), long bags under the stair core's glazed
    front and along the west block's ground-floor window (y `front`), a long bag across the back door 1.3 m out
    (open at both ends); wings: short bags on the porch's flanks (where no forecourt walls flank it)."""
    d.tier()
    d.o(LONG, 10.5, -10.4, 180)
    if wings:
        d.o(SHORT, 7.0, -9.4, 270)
        d.o(SHORT, 14.0, -9.4, 90)
    for x in (0.6, 4.0):
        d.o(LONG, x, -8.6, 180)
    for x in (-15.6, -12.4, -9.2, -6.0, -2.8):
        d.o(LONG, x, front, 180)
    d.o(LONG, -14.8, 9.8, 0)


def raise_inner(d, inner):
    """T5: the T3 ring raised: its H-barriers dropped and the same lines drawn again in Mil walls."""
    d.drop("T3 ring")
    inner(d, "M", "T5 ring", CNCW1)


def kavala(d):
    """Kavala: the hospital (Land_Hospital_main_F; model coordinates, "south" -y, "east" +x). Probed to 72 m. The
    complex: the south block (the helipad; its ground floor open: the in-game walk crossed it at y -17 and side2's
    box at y -1; real walls about x -38..16, y -22..-5), the main strip north of it (x about -3..16) and side1 at its
    north end (box x -8..17.5, y 20.8..44.4). The wings' boxes and the plan stand for the real building only roughly,
    so tl.check() leaves pieces near it to the in-game clips, and closure() treats them as open ground: every ring
    closes on itself. Round it: the west road (x -45, turning north-east from y 14 to (-23, 70)), the south road
    (y -30), the cliff east (the rocks from x 24-28), the forecourt (a planter, low walls at x -23..-17) west of the
    main strip and north of the south block, the service yard (tanks, containers) between the strip and the cliff.
    T2: sandbags 2 m out of each door that opens outside, along the main strip's forecourt face and the south front.
    T3: H-barriers 1.5-2 m round the whole complex: south (y -24.3), east (x 20; the Mil walls at T5 x 18.2, round side1's north end at
    y 45.3, standing into a low wall there), the forecourt side (x -10.5 down to the south block, y -2 along its north face), west (x -39.5).
    T4: Mil walls along the road edges into the cliff: the south road's edge (y -26) from the west road to the
    rocks, the west road's east edge (x -41.3, then north-east along the road to (-26.3, 50)), and the north side
    (y 50-61) along the line of tall canal walls at the forecourt's north end into the cliff: the forecourt and the service yard inside.
    T5: the T3 ring in Mil walls."""
    d.start = (13.1, -6.1)  # The in-game walk's start (between the main strip and the service yard)
    d.tier()  # T1: nothing

    d.tier()  # T2: a long bag 2 m out of every door that opens outside
    for dr in d.t.doors:
        m = d.t.to_model(dr["pos"])
        md = (dr["dir"] - d.t.dir) % 360
        if not d.t.on_office(*off(m[0], m[1], md, 1.5), 0.1, 0.1):
            d.o(LONG, *off(m[0], m[1], md, 2.0), md, nudge=0.5)
    for y in (6.0, 12.0, 16.5):                               # Along the main strip's face onto the forecourt
        d.o(LONG, -8.9, y, 270)
    for x in (-1.0, 3.5, 8.0, 12.5):                          # Along its south front
        d.o(LONG, x, -22.7, 180)

    def inner(d, fam, R, short):
        hw = 0.85 if fam == "H" else 0.55
        xe = 20.0 if fam == "H" else 18.2  # (Round 4: two H-barriers at x 18.2 cut the main block; the Mil walls didn't;
        # x 20 also clears the net fence ending at x 18.9)
        d.run(-39.5 - hw, -24.3, xe + hw, -24.3, 180, fam, R, "south line", road_ok=True, past=0.0)
        d.run(xe + hw, 45.3, -10.5 - hw, 45.3, 0, fam, R, "north line, round side1's north end (into the low wall)", past=0.0, upgrade=True)
        d.run(xe, -24.3, xe, 45.3, 90, fam, R, "east line, along the main strip and side1", past=0.6)
        d.run(-10.5, 45.3, -10.5, -2.0 - hw, 270, fam, R, "forecourt line, side1 down to the south block", past=0.6)
        d.run(-10.5, -2.0, -39.5 - hw, -2.0, 0, fam, R, "along the south block's north face", past=0.0)
        d.run(-39.5, -2.0, -39.5, -24.3, 270, fam, R, "west line, along the south block's west end", road_ok=True, past=0.6)

    d.tier()  # T3
    inner(d, "H", "T3 ring", HB1)

    d.tier()  # T4
    R = "T4 ring"
    d.run(-41.85, -26.0, 24.5, -26.0, 180, "M", R, "south road's edge to the cliff", road_ok=True, past=0.6)
    d.run(-41.3, -26.0, -41.3, 14.0, 270, "M", R, "west road's edge", road_ok=True, past=0.6)
    pts = [(-41.3, 14.0), (-36.0, 30.0), (-26.3, 50.0), (-20.9, 60.5)]  # The west road's edge, ~5.5 m off its middle
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        d.run(x0, y0, x1, y1, bearing(x0, y0, x1, y1) - 90, "M", R, "west road's edge, turning north-east", road_ok=True, past=0.6)
    # The north side: a line of tall canal walls (5.5 m, real barriers) runs from (-12, 61) to the cliff; the run
    # into the first and the gaps between them filled
    d.run(-21.45, 60.5, -10.5, 60.5, 0, "M", R, "north side into the first canal wall", road_ok=True, past=0.6)
    for (x0, y0), (x1, y1) in (((-1.8, 58.4), (5.1, 56.35)), ((14.8, 53.45), (21.7, 51.3))):
        d.fill(x0, y0, x1, y1, bearing(x0, y0, x1, y1) - 90, "M", label="north side, between the canal walls", ring=R, past=0.6)

    d.tier()  # T5
    raise_inner(d, inner)


def pyrgos(d):
    """Pyrgos (model coordinates; "south" -y, the treed square in front of the main door; "east" +x, the hill). The
    tower stands alone on open ground: a city wall down the east side (x 19, y -44..17), a low concrete wall to the
    north (y 13.2) and a city wall beyond it (y 17) with a lane between them, pipe fences round the west lot
    (x -24.7..-33.1, y -26..7) and the square (y -18.5, a gap at x 6..10.6). None is a barrier: the occupier builds
    every ring itself, crossing the low walls and pipe fences at junctions (both runs end into them).
    T3: a rectangle of H-barriers round the office: y -14.5 (in front of the window bags) to y 11.0 (the back
    door's bag), x -20 to 15.
    T4: Mil walls round the office's whole ground: the square's north half (y -27, across its path fences), the
    hill's foot outside the east city wall (x 24), beyond the lane's city wall (y 21.5), and round the west lot
    (x -32, inside its far fence).
    T5: the T3 ring raised: the same lines in Mil walls."""
    d.tier()  # T1: nothing
    tower_t2(d, wings=True)

    def inner(d, fam, R, short):
        d.fill(-20.85, -14.5, 15.85, -14.5, 180, fam, label="south line", ring=R)
        d.fill(-20.85, 11.0, 15.85, 11.0, 0, fam, label="north line", ring=R)
        d.fill(-20.0, -14.5, -20.0, 11.0, 270, fam, label="west line", ring=R, past=0.3)
        d.fill(15.0, -14.5, 15.0, 11.0, 90, fam, label="east line", ring=R, past=0.3)

    d.tier()  # T3
    inner(d, "H", "T3 ring", HB1)

    d.tier()  # T4
    R = "T4 ring"
    d.run(-32.55, -27.0, 24.55, -27.0, 180, "M", R, "square face")
    d.run(24.0, -27.0, 24.0, 22.05, 90, "M", R, "east face, the hill's foot", past=0.6)
    d.run(24.55, 21.5, -32.55, 21.5, 0, "M", R, "north face, beyond the lane")
    d.run(-32.0, 21.5, -32.0, -27.0, 270, "M", R, "west face, round the west lot", past=0.6)

    d.tier()  # T5
    raise_inner(d, inner)


# ================================================================ House_Big_01 (Athira, Zaros)
# The two-storey house's ground floor (the probe's plan): solid x -4.5..5.0, y -7.5..7.5 (the veranda along the west
# side, x -4..-3, open to the west); the main door (-3.3, -7.3) at the veranda's south end facing south, the side door
# (4.9, 5.6) facing east, a ground-floor window (5.0, -5.25) facing east.


def athira(d):
    """Athira (model coordinates; "south" -y, the main door's side). A dense block: House_Small_02 hard behind the
    house (x -5.6..3.7, y 7.5..23.9), a courtyard east (x 5..22; its north wall y 7.3 with an opening at x 12.5-17,
    and a wall slanting down to the shop, all low), the shop beyond it, House_Big_02 north-east (box x 2..26,
    y 11.9..22.6; its real walls only x 9..20: the box's west part is open ground, a corridor north between it and
    House_Small_02), House_Big_02 south-east (its box's north tip at (11.1, -13.6)), House_Small_01 south-west, the
    west lot (x -13..-5) between it and the scaffolding on House_Big_01 (x -12.6), a lane north (x -12.6..-5.6), and a
    low city wall south from the door's west side (x -4.4). tl.check() keeps a piece's middle out of a neighbour's
    box, and the shop's and both House_Big_02s' boxes reach 1-4 m past their real walls (open ground), so the rings
    close on House_Small_02, House_Small_01 and the scaffolding (solid to their boxes) and on themselves; where the
    outer ring meets the shop it lines the shop's box, 0.6 m off it.
    T3: H-barriers round the house: y -10.75 (behind the door's screen), x -7, x 8.8 (clear of the in-game walk's
    start at (6.7, -1.5)); capped into House_Small_02's west and east faces (y 8.6, 8.75), crossing the low city
    wall and the courtyard wall at junctions.
    T4: Mil walls round the compound: the west lot's mouth (x -16, House_Small_01 to the scaffolding), the lane
    north (y 12), House_Small_02, a cap across the corridor (y 11.33, the last 0.6 m before House_Big_02's box)
    east past the courtyard's opening to x 22, down to the courtyard's slanting wall, along the shop's
    north-west face (from that wall) and south-west face, and the south face (y -13, across the low city wall, past House_Big_02's tip)
    back to House_Small_01: the courtyard, the strip north of it, the west lot and the lane south inside.
    T5: the T3 ring raised: the same lines in Mil walls."""
    d.tier()  # T1: nothing

    d.tier()  # T2: a screen across the main door (open to the east, the low wall on its west), bags along the
    # veranda's open west side, at the side door (open both ends) and the east window
    d.o(LONG, -2.4, -9.4, 180)
    d.o(LONG, -5.3, -4.2, 270)
    d.o(LONG, -5.3, -0.8, 270)
    d.o(LONG, 6.3, 4.4, 90)
    d.o(LONG, 6.3, -5.25, 90)

    def inner(d, fam, R, short):
        # The house's caps stay H-barriers at T5 too: a Mil wall beside the house cuts its eaves (round 2), and the
        # Mil west line stands outside the house's box (x -7.9)
        xw = -6.8 if fam == "H" else -8.5
        d.fill(xw - 0.85, -10.75, -4.45, -10.75, 180, fam, label="south line, west corner to the low wall", ring=R, walls=True)
        d.fill(-4.45, -10.75, 9.65, -10.75, 180, fam, label="south line, low wall to the east corner", ring=R, walls=True)
        d.fill(xw, -10.75, xw, 3.45, 270, fam, label="west line", ring=R, past=0.3)
        d.fill(xw, 2.6, -4.0, 2.6, 0, "H", label="west cap against the house's north room", ring=R)
        d.fill(8.8, -10.75, 8.8, 7.34, 90, fam, label="east line, south line to the courtyard wall", ring=R, walls=True)
        d.fill(9.65, 8.35, 5.25, 8.35, 0, "H", label="north-east cap on the courtyard wall, to the house's corner", ring=R,
               past=0.0, upgrade=True)

    d.tier()  # T3
    inner(d, "H", "T3 ring", HB1)

    d.tier()  # T4
    R = "T4 ring"
    d.run(-17.0, -13.0, 23.45, -13.0, 180, "M", R, "south face, House_Small_01 to the shop", past=0.3)
    d.fill(22.9, -13.0, 15.2, -7.45, 35.8, "M", label="along the shop's south-west face", ring=R, past=0.3)
    d.fill(15.2, -7.45, 22.35, 2.4, 126.0, "M", label="along the shop's north-west face to the slanting wall", ring=R, walls=True, past=0.6)
    d.fill(22.55, 11.33, 3.9, 11.33, 0, "M", label="cap across the corridor and the strip", ring=R, past=0.0)
    d.fill(22.0, 11.33, 22.0, 3.3, 90, "M", label="down to the courtyard's slanting wall", ring=R, walls=True, past=0.6)
    d.fill(4.25, 11.33, 4.25, 7.0, 90, "H", label="down to the house's north face", ring=R)
    d.run(-16.0, -13.0, -16.0, -0.8, 270, "M", R, "west lot's mouth, House_Small_01 to the scaffolding")
    d.fill(-13.0, 5.4, -6.5, 5.4, 0, "M", label="across the lane north from the scaffolding", ring=R, past=0.3)
    d.fill(-6.5, 5.4, -4.0, 5.4, 0, "H", label="lane line's last piece, against the house's west face", ring=R)

    d.tier()  # T5
    raise_inner(d, inner)


def zaros(d):
    """Zaros (model coordinates; "south" -y, the main door's side; "east" +x, the main road). The house has Addon_03
    hard behind it (x -4.8..5.3, y 7.7..16, solid to its box) and the shop hard against its front: its real walls
    x -5..6.7, y -7.5..-16, but its box runs to x -8..12.3, y -7..-16.6, and the box's margin is open ground (the
    main road starts at x 11). The main door opens against the shop's wall; the way out is the veranda's open west
    side. West, the yard walled by low city walls (Addon_02 in it); south, the south ground to a low stone wall
    (y -23.2); east, the strip to the road and a low-walled garden (x 4..8, y 8.2..15.1); north, beyond Addon_03,
    House_Big_02 and Shop_01. None of the walls is a barrier. Pieces near the house clip it even 1.6 m off its probed
    walls (rounds 1-3), and a ring capped against it leaked round its ends past the shop's open box margin (round 3):
    so no ring touches the house.
    T3: H-barriers round the house and the shop together: behind the shop (y -18), x -8.6 along the shop's and the
    house's west side (standing into the yard's low walls where it meets them), the east side on the main road's
    shoulder (x 13.2), capped into Addon_03's west face (y 9.5) and, across the garden, its east face (y 9.2).
    T4: Mil walls round the whole block: the yard (x -23, outside its west wall, Addon_02 in it), the south ground
    (y -21.5, inside the stone wall), the strip on the main road (x 15: 2.5 m into its 10 m width), capped into
    Addon_03's east face across the garden (y 10.6) and its west face (y 12.5).
    T5: the T3 ring in Mil walls."""
    d.start = (-5.0, 2.5)  # On the veranda's open west side
    d.tier()  # T1: nothing

    d.tier()  # T2: bags along the veranda's open west side, at the side door and the east window
    veranda = [d.o(LONG, -7.6, -3.8, 270), d.o(LONG, -7.6, -0.5, 270)]  # (3.1 m off the probed wall: at 0.8-2.1 m
    # they clipped)
    d.o(LONG, 6.4, 3.8, 90)
    d.o(LONG, 6.3, -3.9, 90)

    def inner(d, fam, R, short):
        # Round the house and the shop hard against its front (the shop's box margin is open ground: a ring stopping
        # at it leaks, round 3), tied into Addon_03 behind; standing into the yard's and the garden's low walls where
        # it meets them (upgrading them); the east side on the main road's shoulder (the shop's box reaches x 12.3)
        hw = 0.85 if fam == "H" else 0.55
        xe = 13.2 if fam == "H" else 13.0
        d.run(-8.6 - hw, -18.0, xe + hw, -18.0, 180, fam, R, "south line, behind the shop", road_ok=True, past=0.0)
        d.run(-8.6 - hw, 9.5, -4.3, 9.5, 0, fam, R, "north-west cap into Addon_03", upgrade=True, past=0.0)
        d.run(xe + hw, 9.2, 4.8, 9.2, 0, fam, R, "north-east cap across the garden into Addon_03", road_ok=True, upgrade=True, past=0.0)
        d.run(-8.6, -18.0, -8.6, 9.5, 270, fam, R, "west line, along the shop and the house", past=0.6, upgrade=True)
        d.run(xe, -18.0, xe, 9.2, 90, fam, R, "east line, the road's shoulder", road_ok=True, past=0.6)

    d.tier()  # T3: the veranda's bags dropped (the ring stands just outside them)
    d.cur[:] = [it for it in d.cur if not any(it is v for v in veranda)]
    inner(d, "H", "T3 ring", HB1)

    d.tier()  # T4
    R = "T4 ring"
    d.run(-23.55, -21.5, 15.55, -21.5, 180, "M", R, "south face, the south ground", road_ok=True)
    d.run(15.0, -21.5, 15.0, 11.15, 90, "M", R, "east face, on the road", road_ok=True, past=0.6)
    d.run(15.55, 10.6, 4.8, 10.6, 0, "M", R, "north-east cap across the garden into Addon_03", road_ok=True)
    d.run(-23.0, -21.5, -23.0, 13.05, 270, "M", R, "west face, outside the yard's west wall", past=0.6)
    d.run(-23.55, 12.5, -4.3, 12.5, 0, "M", R, "north-west cap into Addon_03")

    d.tier()  # T5
    raise_inner(d, inner)


TOWNS = {"Kavala": kavala, "Pyrgos": pyrgos, "Athira": athira, "Zaros": zaros}


def build(name, towns=None):
    towns = towns or tl.load()
    t = towns[name]
    d = Draft(t)
    TOWNS[name](d)
    return t, d


def ring_closure(t, d):
    """[text]: per tier from 3, whether a man gets out past everything standing, and past each ring alone."""
    out = []
    for n, items in enumerate(d.tiers, 1):
        if n < 3:
            continue
        for name, its in [("all", items)] + list(d.rings.get(n, {}).items()):
            r = closure(t, its, d.start)
            out.append(f"T{n} {name}: " + ("closed: no way out" if r is None else
                       f"OPEN, narrowest at {[round(v, 1) for v in r[1][0]]} ({r[1][1]:.2f} m clear)"))
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    show = None
    if "--map" in sys.argv:
        show = int(sys.argv[sys.argv.index("--map") + 1])
        args = [a for a in args if a != str(show)]
    tl.MIN_GUARDS = 0  # Pass 1: walls only
    towns = tl.load()
    for name in TOWNS:
        if args and name not in args:
            continue
        t, d = build(name, towns)
        tiers = d.finish()
        if "--log" in sys.argv or any("SKIP" in l for l in d.log):
            for line in d.log:
                print(f"  {name}: {line}")
        if "--audit" in sys.argv or "--log" in sys.argv:
            for line in d.audit():
                print(f"  {name}: RUN {line}")
        for line in ring_closure(t, d):
            print(f"  {name}: {line}")
        probs = tl.check(t, tiers)
        if probs:
            print(f"{name}: PROBLEMS {probs}")
        else:
            path = tl.write(t, tiers)
            print(f"{name}: (things, guards, statics) per tier {counts(tiers)} -> {os.path.relpath(path, tl.ROOT)}")
        if show:
            r = closure(t, tiers[show - 1], d.start)
            print(overlay(t, tiers[show - 1], path=r[0] if r else ()))


if __name__ == "__main__":
    main()
