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
probe's map (1 m cells): H low H-barrier, W tall wall (Mil wall, HBarrierWall), B bunker, G gate, b sandbags,
w razor wire, x hedgehog, c concrete barrier, T bag tower, g guard, S static, f furniture/flag, ~ ^ $ on a floor; capitals of the probe:
# building, = wall, : road, O the office.

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
        WIRE: (8.5, 2.1), HB5: (5.8, 1.7), HB3: (3.6, 1.8), HB1: (1.4, 1.7)}
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
    return (1.6, 1.6) if it[0] == "static" else (0.6, 0.6)


def length(cls):
    """A barrier piece's real length (the spacing a line is drawn with)."""
    return (REAL.get(cls) or tl.CLASSES[cls])[0]


def clips(t, it):
    """Whether a placed piece cuts into the probe's buildings, walls or the office mid-piece: a barrier's middle
    (its ends may overlap), anything else whole; the real (measured) size."""
    if it[0] != "object" or "ground" not in it[4] or it[1] in (WIRE, HOG, FLAG):
        return False
    L, D = size(it)
    if is_barrier(it) and it[1] not in (TOWER, BUNKER):
        L, D = max(L - 2 * tl.BARRIER_OVERLAP, 0.2), max(D * 0.5, 0.2)
    m = t.to_model(it[2])
    d = (yaw(it) - t.dir) % 360
    cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
    for i in range(int(L / 0.5) + 1):
        for j in range(int(D / 0.5) + 1):
            a, b = -L / 2 + min(i * 0.5, L), -D / 2 + min(j * 0.5, D)
            x, y = m[0] + a * cx[0] + b * cy[0], m[1] + a * cx[1] + b * cy[1]
            w = t.to_world(x, y, 0)
            if any(h[0] in ("building", "wall", "part") for h in t.hits(w[0], w[1], 0.05, 0.05, 0, 0.0)):
                return True
            if t.on_office(x, y, 0.1, 0.1):
                return True
    return False


def yaw(it):
    o = it[3]
    return (o if it[0] == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360


def is_barrier(it):
    """Barrier pieces (and bag bunkers, which sit in the lines) may overlap each other at their ends and sides."""
    return it[0] == "object" and (tl.is_barrier(it[1]) or it[1] in (BUNKER, TOWER))


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
    if abs(za - zb) > 1.6:
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


class Draft:
    """Cumulative tiers: tier() starts the next one from a copy of the last; put() adds an item when it passes the
    single-item checks and doesn't overlap what's there (fortifications also stay off roads unless road_ok);
    otherwise it tries small nudges (nudge > 0) or logs a SKIP (a design error to fix, not a fallback)."""

    def __init__(self, t):
        self.t, self.tiers, self.cur, self.log = t, [], None, []

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
        """A static weapon in a pit: a round sandbag 1.9 m in front of it."""
        s = self.s(role, x, y, face, z)
        if s and bag:
            bx, by = off(x, y, face, 1.9)
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

    FAMILIES = {"H": (HB5, HB3, HB1), "B": (HBBIG, HB5, HB3, HB1), "W": (HBW6, HBW4), "M": (MIL,), "w": (WIRE,), "c": (CNC4,)}

    def fill(self, x0, y0, x1, y1, face, family="H", z=None, road_ok=False):
        """One unbroken run of barrier pieces from (x0, y0) to (x1, y1) (the ends overlapped by the first and last
        piece, the pieces overlapping each other by LAP or more), facing `face`: the family's longest piece
        repeated, a shorter one at the end when that fits better."""
        classes = self.FAMILIES[family]
        dist = math.hypot(x1 - x0, y1 - y0)
        along = math.degrees(math.atan2(x1 - x0, y1 - y0))
        most = 2 * tl.BARRIER_OVERLAP + 0.35  # The most two pieces may overlap (their cores just touching)
        options = []
        for main in classes:  # n of one piece, evenly spaced
            L = length(main)
            for n in range(1, 40):
                if n == 1:
                    if L >= dist - 0.7 and L - dist <= most + 0.45:
                        options.append(((1, abs(L - dist)), [(main, dist / 2)]))
                    continue
                step = (dist - L) / (n - 1)
                if -0.01 <= L - step <= most:
                    options.append(((n, abs(L - step - LAP)), [(main, L / 2 + i * step) for i in range(n)]))
                    break
            for last in classes:  # n-1 of one piece at LAP and a shorter one to finish
                Ll = length(last)
                if last == main or Ll > L:
                    continue
                m = max(1, math.ceil((dist - Ll) / (L - LAP)))
                ov = m * (L - LAP) + LAP - (dist - Ll)  # The last joint's overlap
                if 0.1 <= ov <= most and m * (L - LAP) + LAP <= dist:
                    pieces = [(main, L / 2 + i * (L - LAP)) for i in range(m)] + [(last, dist - Ll / 2)]
                    options.append(((m + 1, abs(ov - LAP) + 0.01), pieces))
        if not options:
            self.log.append(f"T{len(self.tiers)} SKIP fill {family} ({x0:.1f},{y0:.1f})-({x1:.1f},{y1:.1f}): no fit")
            return
        for c, at in min(options, key=lambda o: o[0])[1]:
            cx, cy = off(x0, y0, along, at)
            self.o(c, cx, cy, face, z, road_ok=road_ok or c == WIRE)

    def embrasure(self, x, y, face, role="hmg", z=None, bag=True, line_face=None):
        """A round sandbag in a line at (x, y) (bag; the line's gap 3 m for its real width) and a static weapon
        1.9 m behind it (role), firing through it towards `face` (the line itself faces line_face, default face)."""
        lf = face if line_face is None else line_face
        if bag:
            self.o(ROUND, x, y, lf + 180, z, nudge=0.0)
        if role:
            bx, by = off(x, y, face, -1.9)  # Behind the bag along its line of fire
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
    """The fine map with the items drawn on it (model coordinates, up = +y)."""
    grid = {}
    for y in range(-r, r + 1):
        for x in range(-r, r + 1):
            w = t.to_world(x, y, 0)
            c = "."
            if t.on_road(w[0], w[1]):
                c = ":"
            h = t.hits(w[0], w[1], 0.3, 0.3, 0, 0)
            if h:
                c = {"building": "#", "wall": "=", "tree": "t", "rock": "r", "part": "O"}.get(h[0][0], "?")
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
    d.g("gendarme", -14.8, 6.0, 0, F0)          # The back corridor, watching the back door


def tower_t2_inside(d):
    """T2 inside: the back door bagged from inside, a man at the first-floor south window over the porch."""
    d.o(SHORT, -14.8, 7.3, 0, F0)
    d.g("rifleman", 4.1, -6.7, 180, F2)


def tower_t3_inside(d):
    """T3: overwatch: the roof's south-east corner HMG (the square and the junction below, from 17 m; the roof's
    parapet its cover, 2.4 m in front), a marksman at the office floor's east window (over the east street), men
    at the floor -3 and floor 1 south windows."""
    d.s("hmg", 11.0, -5.6, 170, ROOF)
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
    """Kavala: the tower stands in a walled city block. The west and north yards are closed by the old city walls
    (a diagonal wall from (-35, -11) to (-3, 35)), Addon_01 and Addon_02 stand north of it, a city wall runs down the
    east side (x 17-22) between the tower and the east street (x 22-33, junction east at y -13); the south front
    looks onto the open square: the west block's face, a low concrete wall (y -11.2, x -1..7) before the porch, and
    the main door's forecourt between two city walls (x 8 and 13, y -8..-11.6). The open side is the square; the
    approaches are the east street (north and south) with its junction east, the square from the south, and the
    west road coming in at the square's south-west."""
    tower_t1(d, (-0.5, -12.6))

    d.tier()  # T2: the main door held from the forecourt: a long bag across its mouth, the walls its flanks (a C)
    d.o(LONG, 10.6, -10.9, 180)
    d.g("rifleman", 10.0, -9.7, 180)
    d.g("autorifleman", 11.3, -9.7, 180)
    tower_t2_inside(d)

    d.tier()  # T3: the compound: the one gap in its walls (the west yard's, between the city wall's end and the
    # tower's south-west corner) shut with an H-barrier and a man behind it; the forecourt's mouth a bar gate; the
    # back door's post; the roof HMG, a GMG on the roof's south-west (the square's west half and the west road),
    # the window marksman and riflemen at the stair core's south windows over the square
    d.o(HB3, -19.7, -12.9, 180)                              # The west yard's gap, wall end to block corner
    d.g("rifleman", -18.8, -11.2, 180)
    d.o(BARGATE, 10.6, -12.2, 180)
    d.post("autorifleman", -14.8, 10.6, 0)
    tower_t3_inside(d)
    d.s("gmg", -14.0, 1.5, 250, ROOF)

    d.tier()  # T4: the fort, one 2-high ring round the whole block. The forward yard walled across the square
    # (y -21) from the house to the street's edge, its gate on the door's axis (men in its lane, a chicane of two
    # staggered H-barriers outside), HMG embrasures in its square face and its street face; the ring goes on up
    # the street's edge (x 20.4, outside the low garden wall) to Addon_01, from Addon_01 along the back of the
    # block (y 12.4) to the old city wall, and down the west yard (x -20.4) to the west gap; a bag tower in the
    # yard (its platform over the square), a second one out in the north yard over the low wall and the road
    # beyond it; wire round the north, hedgehogs across the street both ways
    d.fill(-11.0, -21.6, -11.0, -12.3, 270, "B")             # The yard's west side, the house to the block
    d.fill(-10.2, -21.0, 0.2, -21.0, 180, "B")               # The square face, to the embrasure,
    d.embrasure(1.8, -21.0, 180)                             # the HMG over the square,
    d.fill(3.4, -21.0, 8.0, -21.0, 180, "B")                 # on to the gate
    d.o(BARGATE, 10.5, -21.0, 180)                           # The gate, x 8..13 on the door's axis
    d.fill(13.0, -21.0, 20.2, -21.0, 180, "B")
    d.fill(19.6, -20.0, 19.6, -16.0, 90, "B")                # The street face, to the embrasure,
    d.embrasure(19.6, -14.4, 90)                             # the HMG over the junction and the street,
    d.fill(19.6, -12.8, 19.6, -11.0, 90, "B")
    d.fill(20.4, -11.6, 20.4, 9.6, 90, "B", road_ok=True)    # Up the street's edge outside the garden wall
    d.o(HB3, 16.4, 9.4, 0)                                   # the garden wall to Addon_01 (H-barriers),
    d.o(HB1, 14.1, 9.4, 0)
    d.fill(4.6, 12.4, -18.6, 12.4, 0, "B")                   # along the back of the block to the city wall,
    d.fill(-20.4, 9.2, -20.4, -11.6, 270, "B")               # down the west yard to the west gap
    d.tower(-5.0, -16.4, 270, "marksman", "autorifleman")
    d.tower(-4.0, 22.0, 300, "marksman")
    d.g("rifleman", 9.1, -19.4, 180)                         # The gate's lane
    d.g("autorifleman", 11.9, -19.4, 180)
    d.o(HB3, 8.6, -25.0, 180)                                # The chicane: the gate is reached in an S
    d.o(HB3, 12.4, -28.6, 180)
    d.o(WIRE, 2.2, -24.8, 180)                               # Wire before the square face's embrasure,
    d.o(WIRE, 16.4, -24.8, 180, road_ok=True)                # the chicane's lane left open
    d.fill(-14.0, 15.0, 2.5, 15.0, 0, "w")                   # Wire behind the back line
    for x, y in ((23.5, -22.5), (26.5, -23.5), (29.5, -22.5), (24.0, 10.0), (27.0, 11.0), (30.0, 10.0)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)          # Hedgehogs: the street both ways
    tower_t4_inside(d)

    d.tier()  # T5: the stronghold: checkpoints on the east street north and south, the junction road, the west
    # road's mouth on the square and the road beyond the old city wall (a 2-high block and a concrete block
    # staggered across each, the men behind sandbags at the chicane's exit, a bag bunker where it fits); the
    # square walled in by a second 2-high ring with its own gated chicane, a bag tower and a GMG; the mortar in the
    # yard; AT on the roof over the street, an AT man at the gate; the kill zone inside
    d.checkpoint(27.4, 17.0, 10, out=6.0, side=1, roles=("autorifleman", "rifleman"))
    d.checkpoint(26.8, -31.5, 182, out=-5.5, side=1, roles=("autorifleman", "rifleman"))
    d.checkpoint(34.5, -13.0, 92, out=5.0, side=-1, roles=("autorifleman",), post=(1.0, 6.5))
    d.checkpoint(-31.0, -18.5, 240, width=6.0, out=-4.5, roles=("rifleman", "autorifleman"), bag_at=-8.0)
    d.checkpoint(-35.0, 4.2, 34, out=-6.0, roles=("autorifleman",))
    d.fill(-10.6, -30.5, 0.2, -30.5, 180, "B")
    d.embrasure(1.8, -30.5, 180, role=None)                  # The yard's HMG fires on through this one
    d.fill(3.4, -30.5, 8.0, -30.5, 180, "B")
    d.o(BARGATE, 10.5, -30.5, 180)
    d.fill(13.0, -30.5, 14.4, -30.5, 180)
    d.embrasure(16.0, -30.5, 165, role="gmg", line_face=180)
    d.fill(17.6, -30.5, 21.4, -30.5, 180, "B")
    d.fill(20.9, -29.6, 20.9, -21.4, 90, "B")
    d.tower(-5.6, -27.0, 270, "marksman")
    d.o(HB3, 8.6, -34.0, 180)
    d.o(HB3, 12.4, -37.4, 180)
    d.s("mortar", 5.0, -15.0, 90)
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

    d.tier()  # T3: the compound closed. The west side a blank Mil wall (x -23.6, from the low north wall down);
    # the south front: the west block's blank face (x -17..-2) with H-barriers either side of it: the west yard's
    # mouth (x -24..-16.9), and from the block's corner across the porch's front to the east wall (y -13.6), a bar
    # gate on the door's axis; men behind it, the back door's post; the roof HMG over the square, a GMG on the
    # roof's west side over the west lot (2.5 m back from the parapet), the window marksman over the hill
    d.fill(-23.6, 13.3, -23.6, -12.6, 270, "M")              # The west wall, from the low north wall down
    d.fill(-24.0, -13.3, -16.9, -13.3, 180)                  # The west yard's mouth
    d.fill(-1.9, -13.6, 8.3, -13.6, 180)                     # The porch's front, block corner to the gate
    d.o(BARGATE, 10.5, -13.6, 180)                           # x 8 .. 13
    d.fill(12.7, -13.6, 19.2, -13.6, 180)                    # On into the east wall
    d.post("autorifleman", -14.8, 10.6, 0)
    d.g("rifleman", -19.0, -11.9, 180)
    d.g("autorifleman", 1.0, -11.8, 180)
    tower_t3_inside(d)
    d.s("gmg", -14.0, 1.5, 270, ROOF)

    d.tier()  # T4: the fort. A bastion walled out in front of the west block with 2-high H-barriers (y -16.4),
    # the HMG's embrasure in it firing down the fence's gap into the square; bag towers in the west yard's
    # south-west corner and at the porch line's east end (their platforms over the lines); the north lane shut
    # where it meets the west wall; a chicane at the fence's gap in front of the gate; wire along the fence line
    # either side of it, hedgehogs across the square's open middle (vehicles from the road); an HMG on the roof's
    # east side against the hill; men along the porch line
    d.o(HB1, -17.4, -15.0, 270)                              # The bastion's west side,
    d.fill(-17.6, -16.4, -8.8, -16.4, 180, "B")              # its south face to the embrasure,
    d.embrasure(-7.2, -16.4, 175, line_face=180)             # the HMG down the fence's gap,
    d.fill(-5.6, -16.4, -0.4, -16.4, 180, "B")               # on to the porch line's west end
    d.o(HB1, -0.8, -14.9, 90)
    d.tower(1.5, -22.2, 270, "marksman", "autorifleman")     # Bastion towers out in front of the outer face,
    d.tower(14.6, -24.3, 180, "marksman")                    # either side of the chicane
    d.fill(-0.8, -17.4, 7.9, -17.4, 180, "B")                # The outer face on the fence line, 2-high,
    d.o(BARGATE, 10.5, -17.4, 180)                           # its gate on the door's axis,
    d.fill(13.1, -17.4, 19.4, -17.4, 180, "B")               # on into the east wall
    d.o(HB3, -23.5, 15.25, 270)                              # The north lane shut at the west wall
    d.o(HB3, 8.3, -21.4, 180)                                # The chicane: the fence gap (x 6-10.6) masked
    d.fill(-19.0, -20.6, -2.0, -20.6, 180, "w")
    for x, y in ((-1.5, -30.5), (4.0, -30.5), (9.0, -31.0), (14.0, -31.5), (18.0, -31.0)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.s("hmg", 10.8, 6.0, 90, ROOF)
    d.g("autorifleman", 3.6, -11.8, 180)
    d.g("rifleman", 6.0, -11.8, 180)
    d.g("rifleman", -8.0, 11.8, 270)                         # Along the back strip
    tower_t4_inside(d)

    d.tier()  # T5: checkpoints on the square's path from the road and on the west lot (an H-barrier and a
    # concrete block staggered, a bag bunker beside), a roadblock in the north lane; a bunker on the hill outside
    # the east wall denying the high ground; the mortar behind the tower; AT on the roof over the square, an AT man
    # at the gate; the kill zone inside
    d.checkpoint(8.0, -36.0, 180, out=5.0, roles=("autorifleman",), post=(-1.0, 7.0))
    d.checkpoint(-36.0, -8.0, 270, out=-6.0, roles=("autorifleman",), post=(-1.0, -7.0))
    d.o(HB3, -36.0, 15.2, 270)
    d.g("rifleman", -34.4, 14.4, 270)
    d.g("autorifleman", -34.4, 16.0, 270)
    d.bunker(27.0, -4.0, 70)
    d.fill(-22.0, 15.25, 17.6, 15.25, 0, "B")               # The north lane filled 2-high behind the low wall
    d.s("mortar", 0.0, 11.0, 90)
    d.g("at", 13.6, -11.8, 180)
    tower_t5_inside(d, at=(2.0, -5.5, 180))


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
    d.g("rifleman", -3.6, 1.0, 180, H0)
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
    house_t1(d, (2.6, -9.6))

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

    d.tier()  # T3: the compound closed. The west lot: an H-barrier line down its west side (x -13.2) with an HMG's
    # embrasure facing the west road (40 m clear), round its south-west corner and along its south side to the city
    # wall; the lane north shut with Mil walls; the courtyard's opening with a tall H-barrier wall; the south front
    # (y -12.6) from the city wall to the shop block: the bar gate before the main door (x -4.3..0.8), a GMG's
    # embrasure covering the lane south, low H-barriers the men fire over to x 9, then 2-high H-barriers to the shop;
    # men behind the lines, upstairs at the east windows
    d.fill(-13.2, -1.2, -13.2, -2.5, 270)
    d.embrasure(-13.2, -4.0, 270)
    d.fill(-13.2, -5.5, -13.2, -9.2, 270)
    d.fill(-13.2, -9.2, -4.3, -9.2, 180)
    d.fill(-12.4, 8.6, -5.5, 8.6, 0, "M")
    d.fill(11.9, 5.3, 20.8, 2.2, 19, "B")                    # The courtyard's low north walls lined 2-high
    d.o(BARGATE, -1.75, -12.6, 180)
    d.fill(0.5, -12.6, 1.8, -12.6, 180)
    d.embrasure(3.2, -12.6, 195, role="gmg", line_face=180)
    d.fill(4.6, -12.6, 9.2, -12.6, 180)
    d.fill(12.0, -12.6, 22.8, -12.6, 180, "B")
    d.g("rifleman", -11.8, -2.0, 270)
    d.g("autorifleman", 6.6, -11.0, 180)
    d.g("rifleman", 8.0, -11.0, 180)
    d.g("rifleman", 4.2, -5.3, 90, H1)
    d.g("marksman", 4.2, 5.5, 90, H1)

    d.tier()  # T4: the fort. Bag towers at the west lot's south-west corner (over the lot and the west lane) and
    # the south line's east end (over the open ground and the south-east gap); the HMG's embrasure between the low
    # and the 2-high stretch (across the open ground to the lane's mouth); a chicane of low concrete blocks in the
    # south lane (staggered: the gate is reached in an S, the GMG fires over them); wire across the west lot's
    # mouth; hedgehogs in the south-east gap, the strip's mouth on the east road and the west lane; the balcony MG
    d.o(ROUND, 10.6, -12.6, 0)
    d.s("hmg", *off(10.6, -12.6, 210, -2.6), 210)
    d.tower(12.5, -3.5, 180, "marksman", "autorifleman")
    for x in (-3.2, -0.6, 2.0):
        d.o(JERSEY, x, -16.6, 180)
    for x in (-0.2, 2.4, 5.0):
        d.o(JERSEY, x, -20.6, 180, nudge=0.5)
    d.fill(-18.4, -1.0, -18.4, -2.6, 270, "B")              # The lane to the west road walled 2-high, the
    d.embrasure(-18.4, -4.0, 270, role=None)                 # HMG's line kept open through it
    d.fill(-18.4, -5.4, -18.4, -7.6, 270, "B")
    d.fill(-15.6, -1.6, -15.6, -8.2, 270, "w")
    for x, y in ((19.6, -19.5), (19.8, -22.0), (24.0, 8.8), (24.0, 11.2), (-10.0, -15.0), (-7.0, -17.0)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.g("mg_gunner", -3.6, -0.6, 270, H1)
    d.g("rifleman", 1.2, -11.0, 180)
    d.g("rifleman", 5.2, -11.0, 180)
    d.g("rifleman", -0.4, -10.6, 180)
    d.g("rifleman", 6.2, 4.0, 120)

    d.tier()  # T5: checkpoints at the west lot's mouth on the west road (with an AT gun beside it), in the south lane
    # and across the strip's mouth on the east road; the mortar in the courtyard; an AT man at the gate; the kill
    # zone inside
    d.checkpoint(-27.0, -4.7, 270, width=6.5, out=5.0, hb=HB3, block=JERSEY)
    d.gun("at", -21.5, -6.4, 270)
    d.checkpoint(-0.6, -27.0, 180, width=5.0, side=1, hb=HB3, block=None)  # The lane: too narrow to stagger
    d.o(HB3, 26.8, 9.9, 90)
    d.g("rifleman", 25.4, 9.2, 90)
    d.g("autorifleman", 25.4, 10.6, 90)
    d.s("mortar", 7.4, -6.0, 210)
    d.g("at", 0.6, -11.0, 180)
    house_t5_inside(d)


def zaros(d):
    """Zaros: a shop stands hard against the house's front (south), so the main door's way out is the veranda's
    open west side, into a walled yard (x -21..-5, y -15..7.5, Addon_02 in it) with two openings: a passage north
    (x -9..-4.5, y 7.5..10.5) onto the open ground north of the house, and a 2 m gap south (x -14..-12, y -15.5)
    onto the open ground south. The side door faces the main road (x 13-24, north-south) across a 5 m strip;
    Addon_03 stands behind the house (north). The open ground north reaches the road through a passage north of
    Addon_03 (x -1..13, y 16..19.5). The approaches: the road from the north and the south (vehicles), the open
    ground north, the open ground south. Fields of fire are short except along the road."""
    house_t1(d, (-9.6, -3.0), door_face=270)

    d.tier()  # T2: the veranda's open side held by a C square with it (a long bag across, shorts back to the house),
    # the side door held by a long bag across it (the strip's low walls on its north); the balcony over the yard
    d.o(LONG, -8.1, -3.5, 270)
    d.o(SHORT, -7.2, -5.5, 180)
    d.o(SHORT, -7.2, -1.5, 0)
    d.g("rifleman", -6.8, -4.1, 270)
    d.g("autorifleman", -6.8, -2.9, 270)
    d.o(LONG, 8.3, 5.6, 90)
    d.g("rifleman", 7.0, 5.6, 90)
    d.g("rifleman", -3.6, -3.4, 270, H1)

    d.tier()  # T3: the compound closed. The yard's north passage shut by a gate (a post behind it), its south gap
    # by H-barriers round a round-bag post; the strip closed along the road (x 10.5) from the shop to a bar gate
    # square with the side door, tied into the low walls north; gun pits on the road's edge either side of it: the
    # HMG down the road south (40 m clear), the GMG up it north; upstairs the east windows
    d.o(CITYGATE, -6.8, 7.7, 0)
    d.post("rifleman", -6.8, 4.6, 0)
    d.embrasure(-12.9, -15.5, 180, role=None)                # A round bag fills the gap
    d.g("rifleman", -12.9, -14.0, 180)
    d.fill(10.5, -6.6, 10.5, 3.3, 90)
    d.o(BARGATE, 10.5, 5.6, 90)
    d.o(HB1, 9.6, 8.5, 0)
    d.gun("hmg", 12.5, -3.0, 170, road_ok=True)
    d.gun("gmg", 11.4, 10.4, 20, road_ok=True)
    d.g("autorifleman", 9.0, -1.5, 90)
    d.g("rifleman", 4.2, -5.3, 90, H1)
    d.g("marksman", 4.2, 5.5, 90, H1)

    d.tier()  # T4: the fort. A 2-high H-barrier blast wall on the road in front of the bar gate (the gate is
    # reached round its ends, under the pits' guns); bag towers on the road's edge by the shop (over the road
    # south) and in the yard's south strip (over the walls to the open ground south); an HMG pit outside the north
    # gate firing west across the open ground north; wire along the low wall north and outside the south gap;
    # hedgehogs across the road both ways; the balcony MG; men at the gate and upstairs
    d.o(HBBIG, 13.6, 5.6, 90, road_ok=True)
    # The compound closed with 2-high lines from the block to the neighbours: the open ground south of the shop
    # (to the garden wall) walled on its road side and its west side; the yard's low west walls lined inside;
    # the open ground north (the north yard) closed at its three gaps (the passage to the road, the gap to the
    # north-west road, the corridor west); bag towers in the south ground and the north yard
    d.fill(12.3, -16.8, 8.9, -23.0, 119, road_ok=True)
    d.fill(-20.6, -15.4, -20.6, -21.6, 270, "B")
    d.fill(-19.6, -10.4, -19.6, -14.4, 270, "B")
    d.fill(-18.0, 1.6, -15.6, 5.2, 304, "B")
    d.o(HB3, 3.0, 17.6, 90)
    d.o(HB1, -15.6, 24.2, 0, nudge=1.0)
    d.fill(-28.2, 12.6, -24.4, 12.6, 270, "B")
    d.tower(-6.0, -19.5, 270, "marksman", "autorifleman")
    d.tower(-21.0, 10.5, 0, "marksman")
    d.gun("hmg", -6.6, 11.8, 290)
    d.fill(-17.0, 11.6, -10.0, 11.6, 0, "w")
    for x, y in ((14.5, 15.0), (17.5, 16.5), (20.5, 15.0), (16.5, -15.0), (18.0, -12.5)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)
    d.g("mg_gunner", -3.6, -0.6, 270, H1)
    d.g("rifleman", 9.0, 2.0, 135)
    d.g("rifleman", 9.0, -4.5, 90)
    d.g("autorifleman", 0.0, -5.0, 270, H1)
    d.g("rifleman", -9.0, 9.4, 300)

    d.tier()  # T5: checkpoints on the road north and south (each with a bag bunker at the roadside), a roadblock in
    # the passage from the open ground north to the road; a bag bunker on the open ground north; the mortar in the
    # yard; an AT gun up the road north (beside the GMG), an AT man at the gate; the kill zone inside
    d.checkpoint(19.0, 23.0, 0, width=9.0, out=6.0)
    d.checkpoint(16.6, -28.0, 180, width=9.0, out=5.0, roles=("autorifleman",))
    d.o(HB3, 6.0, 17.6, 270)
    d.g("rifleman", 7.4, 16.9, 270)
    d.g("autorifleman", 7.4, 18.3, 270)
    d.s("mortar", -10.5, -6.0, 195)
    d.gun("at", 13.6, -9.5, 175, road_ok=True)
    d.g("at", 12.0, -0.8, 170)
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
