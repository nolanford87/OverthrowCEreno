"""
Mayor's office layouts, group "strongholds" (Overthrow CE): the four 5-tier towns.
  Kavala, Pyrgos   Land_Offices_01_V1_F, the tower block on its podium (the showpieces)
  Athira, Zaros    Land_House_Big_01, the two-storey house with the veranda
Run from the repository root:
    python tools/officegen/drafting/strongholds.py [town ...] [--map N] [--log]
Writes tools/officegen/layouts/drafts/<town>.txt (tl.write checks each first). --map N prints tier N over the
probe's map (1 m cells): H low H-barrier, W tall wall (Mil wall, HBarrierWall), B bunker, G gate, b sandbags,
w razor wire, x hedgehog, c concrete barrier, g guard, S static, f furniture/flag; capitals of the probe:
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
CNC, CNC4 = "Land_CncBarrierMedium_F", "Land_CncBarrierMedium4_F"
BUNKER, TOWER = "Land_BagBunker_Small_F", "Land_BagBunker_Tower_F"
DESK, CHAIR, BOARD, FLAG = "Land_TableDesk_F", "Land_OfficeChair_01_F", "Land_MapBoard_F", "Flag_NATO_F"
CTABLE, CCHAIR, RADIO = "Land_CampingTable_F", "Land_CampingChair_V2_F", "Land_PortableLongRangeRadio_F"

LAP = 0.3  # How far butted barrier pieces overlap

MAPCHAR = {SHORT: "b", LONG: "b", ROUND: "b", CORNER: "b", HB1: "H", HB3: "H", HB5: "H", HBBIG: "H",
           HBW4: "W", HBW6: "W", HBWC: "W", MIL: "W", CITYGATE: "G", BARGATE: "G", WIRE: "w", HOG: "x",
           CNC: "c", CNC4: "c", BUNKER: "B", TOWER: "B"}


def fwd(d):
    r = math.radians(d)
    return math.sin(r), math.cos(r)


def off(x, y, d, f, lat=0.0):
    """(x, y) moved f metres along model direction d and lat metres to its right."""
    a, b = fwd(d), fwd(d + 90)
    return x + a[0] * f + b[0] * lat, y + a[1] * f + b[1] * lat


# ---------------------------------------------------------------- footprints and overlaps (model xy)

def size(it):
    if it[0] == "object":
        return tl.CLASSES.get(it[1], (0.6, 0.6))
    return (1.6, 1.6) if it[0] == "static" else (0.6, 0.6)


def yaw(it):
    o = it[3]
    return (o if it[0] == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360


def is_barrier(it):
    """Barrier pieces (and bag bunkers, which sit in the lines) may overlap each other at their ends and sides."""
    return it[0] == "object" and (tl.is_barrier(it[1]) or it[1] == BUNKER)


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


def single_problems(t, it):
    """check()'s per-item rules for one item."""
    probs = tl.check(t, [[it, it, it]] * t.cap)
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
        if single_problems(self.t, it):
            return False
        if it[0] == "object" and "ground" in it[4] and not road_ok and it[1] not in (WIRE, HOG) and self.t.on_road(it[2][0], it[2][1]):
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
        why = single_problems(self.t, it)[:1] or [o[1] for o in self.cur if overlap(self.t, it, o)][:2] or ["road"]
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
            gx, gy = off(x, y, face, -(tl.CLASSES[cls][1] / 2 + gap))
            return self.g(role, gx, gy, face, z, nudge=0.25)
        return None

    def gun(self, role, x, y, face, z=None, bag=True):
        """A static weapon with a round sandbag 1.3 m in front of it (an embrasure when it sits in a line)."""
        s = self.s(role, x, y, face, z)
        if s and bag:
            bx, by = off(x, y, face, 1.3)
            self.o(ROUND, bx, by, face + 180, z, nudge=0.25)
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

    FAMILIES = {"H": (HB5, HB3, HB1), "W": (HBW6, HBW4), "M": (MIL,), "w": (WIRE,), "c": (CNC4, CNC)}

    def fill(self, x0, y0, x1, y1, face, family="H", z=None, road_ok=False):
        """One unbroken run of barrier pieces from (x0, y0) to (x1, y1) (the ends overlapped by the first and last
        piece, the pieces overlapping each other by LAP or more), facing `face`: the family's longest piece
        repeated, a shorter one at the end when that fits better."""
        classes = self.FAMILIES[family]
        dist = math.hypot(x1 - x0, y1 - y0)
        along = math.degrees(math.atan2(x1 - x0, y1 - y0))
        most = 2 * tl.BARRIER_OVERLAP  # The most two pieces may overlap (their cores just touching)
        options = []
        for main in classes:  # n of one piece, evenly spaced
            L = tl.CLASSES[main][0]
            for n in range(1, 40):
                if n == 1:
                    if L >= dist - 0.1 and L - dist <= most:
                        options.append(((1, abs(L - dist)), [(main, dist / 2)]))
                    continue
                step = (dist - L) / (n - 1)
                if 0.1 <= L - step <= most:
                    options.append(((n, abs(L - step - LAP)), [(main, L / 2 + i * step) for i in range(n)]))
                    break
            for last in classes:  # n-1 of one piece at LAP and a shorter one to finish
                Ll = tl.CLASSES[last][0]
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
        """A round sandbag in a line at (x, y) (bag) and a static weapon 1.7 m behind it (role), firing through
        towards `face` (the line itself faces line_face, default the same)."""
        lf = face if line_face is None else line_face
        if bag:
            self.o(ROUND, x, y, lf + 180, z, nudge=0.0)
        if role:
            bx, by = off(x, y, lf, -1.7)
            return self.s(role, bx, by, face, z)

    def bunker(self, x, y, face, role="autorifleman", road_ok=False):
        """A small bag bunker facing out, a man inside at its slit."""
        b = self.o(BUNKER, x, y, face, nudge=0.5, road_ok=road_ok)
        if b:
            m = self.t.to_model(b[2])
            gx, gy = off(m[0], m[1], face, 0.3)
            return self.g(role, gx, gy, face, nudge=0.25, ignore=(b,))

    def checkpoint(self, x, y, face, width=7.0, out=6.0, side=1, roles=("rifleman", "autorifleman"), hb=HB5, block=CNC4):
        """A checkpoint across a road, traffic coming from `face`: an H-barrier (man-high, the men fire over it)
        across one half at (x, y) with its two men 1.2 m behind it, a concrete block across the other half `out`
        metres further out (negative: further in), `side` 1/-1 which half the H-barrier takes (right/left seen
        from the office). A vehicle can only get through in an S at walking pace, under the men's guns."""
        half = side * width / 4
        hb = self.o(hb, *off(x, y, face, 0.0, half), face, road_ok=True, nudge=0.5)
        if hb:
            m = self.t.to_model(hb[2])
            spread = min(1.5, tl.CLASSES[hb[1]][0] / 2 - 0.4)
            for role, lat in zip(roles, (-spread, spread)):
                gx, gy = off(m[0], m[1], face, -2.1, lat)
                self.g(role, gx, gy, face, nudge=0.5)
        self.o(block, *off(x, y, face, out, -half), face, road_ok=True, nudge=0.5)

    def finish(self):
        return self.tiers


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


def tower_t1(d, flag):
    """T1: the desk, chair and map board on the office floor (the chair by the wall, both facing it), the flag in
    the street; gendarmes at the main door inside the lobby, by the desk, and in the back corridor."""
    d.tier()
    d.o(DESK, 10.0, -1.6, 0, F3)
    d.o(CHAIR, 10.0, 0.0, 0, F3)
    d.o(BOARD, 8.75, -1.0, 90, F3)
    d.o(FLAG, *flag, 180, flag=True, nudge=1.0)
    d.g("gendarme", 11.8, -6.0, 180, F0)        # The lobby, watching the main door
    d.g("gendarme", 11.4, -0.8, 180, F3)        # The office, by the desk
    d.g("gendarme", -14.8, 6.0, 0, F0)          # The back corridor, watching the back door


def tower_t2_inside(d):
    """T2 inside: the back door bagged from inside, a man at the first-floor south window over the porch."""
    d.o(SHORT, -14.8, 7.3, 0, F0)
    d.g("rifleman", 4.1, -6.7, 180, F2)


def tower_t3_inside(d):
    """T3: overwatch: the roof's south-east corner HMG (the square and the junction below, from 17 m), a
    marksman at the office floor's east window (over the east street), a rifleman at the first floor's west
    south window."""
    d.gun("hmg", 11.0, -5.6, 170, ROOF)
    d.g("marksman", 12.3, -3.6, 90, F3)
    d.g("rifleman", 0.6, -6.8, 180, F2)


def tower_t4_inside(d):
    """T4: the roof held: an MG behind bags at the south-west corner (the square's west), the office floor's
    south-east window MG (the template's), a marksman on the roof's north-west over the yard and the west road."""
    d.post("mg_gunner", -14.5, -10.6, 215, LONG, z=ROOF)
    d.g("mg_gunner", 12.3, -6.6, 135, F3)
    d.post("marksman", -15.5, 7.6, 315, z=ROOF)


def tower_t5_inside(d, at=(11.6, 4.0, 90)):
    """T5: the kill zone inside. The lobby: a sandbag barricade across the hall at x 7.3 (y -7..-4) shuts the hall's
    west end, so whoever comes through the main door stands in a pocket (x 8..12, y -7..-3): riflemen behind the
    barricade fire into it from the west, an MG behind a long bag in the east arm (10.5, 2.6) fires down it from
    the north. The back corridor bagged across halfway, a rifleman covering the back door's 9 m. The stair head on
    floor -3 held from behind bags; the office floor's door bagged with a rifleman behind; the officer by the desk.
    Up top: an AT launcher on the roof's edge over the vehicle approach (from above: their thin roofs), and the
    first floor's other south windows manned."""
    d.o(LONG, 7.3, -5.6, 90, F0)                 # The barricade across the hall
    d.g("rifleman", 6.0, -6.4, 90, F0)
    d.g("autorifleman", 6.0, -4.8, 90, F0)
    d.o(LONG, 10.5, 1.5, 180, F0)                # The MG's bags in the east arm
    d.g("mg_gunner", 10.5, 2.7, 180, F0)
    d.o(LONG, -6.5, 6.5, 270, F0)                # The back corridor
    d.g("rifleman", -5.2, 6.5, 270, F0)
    d.o(SHORT, 3.4, -5.8, 270, F1)               # The stair head on floor -3
    d.g("rifleman", 4.8, -5.8, 270, F1)
    d.o(LONG, 10.0, -4.0, 180, F3)               # The office floor
    d.g("rifleman", 9.0, -2.9, 180, F3)
    d.g("officer", 8.6, -0.1, 135, F3)
    d.gun("at", *at, ROOF)
    d.g("rifleman", 1.8, -6.8, 180, F1)
    d.g("rifleman", 6.4, -6.8, 180, F1)


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
    # tower's south-west corner) shut with an H-barrier and a man behind it; riflemen behind the low wall before
    # the porch; the forecourt's mouth a bar gate; the back door's post; the roof HMG and the window marksman;
    # a GMG on the roof's south-west covering the square's west half and the west road
    d.fill(-22.2, -12.6, -16.8, -12.6, 180)                  # The west yard's gap, wall end to block corner
    d.g("rifleman", -19.5, -10.6, 180)
    d.g("autorifleman", 1.2, -10.0, 180)
    d.g("rifleman", 5.2, -10.0, 180)
    d.o(BARGATE, 10.6, -12.2, 180)
    d.post("autorifleman", -14.8, 10.6, 0)
    tower_t3_inside(d)
    d.gun("gmg", -9.0, -10.0, 205, ROOF)

    d.tier()  # T4: the fort. A forward yard closed across the square: a low H-barrier line (y -21) from the house
    # on the south-west (its north face the yard's south-west side) to the east line (x 19.5) that ties into the
    # east city wall; small bunkers at its corners; the gate on the door's axis with a chicane of two staggered
    # H-barriers outside it; HMG embrasures in the south line (the square) and the east line (the junction);
    # wire in front of the south line, hedgehogs across the east street both ways and the junction road.
    d.bunker(-9.0, -20.2, 180)                               # The south-west corner, against the house
    d.fill(-11.0, -18.6, -11.0, -12.3, 270)                  # The west side, bunker to the west block
    d.fill(-7.5, -21.0, 1.0, -21.0, 180)                     # The south line, bunker to the embrasure,
    d.embrasure(1.8, -21.0, 180)                             # the HMG over the square,
    d.fill(2.6, -21.0, 8.3, -21.0, 180)                      # on to the gate
    d.o(BARGATE, 10.5, -21.0, 180)                           # The gate, x 8..13 on the door's axis
    d.fill(12.7, -21.0, 16.1, -21.0, 180)
    d.bunker(17.6, -20.2, 180)                               # The south-east corner
    d.fill(19.6, -18.6, 19.6, -17.2, 90)                     # The east line, bunker to the embrasure,
    d.embrasure(19.6, -16.4, 90)                             # the HMG over the junction and the street,
    d.fill(19.6, -15.6, 19.6, -11.4, 90)                     # on to the city wall's corner
    d.fill(19.4, -11.4, 16.6, -11.4, 0)
    d.o(HB3, 8.6, -25.0, 180)                                # The chicane: the gate is reached in an S
    d.o(HB3, 12.4, -28.6, 180)
    d.line(-10.5, -24.6, 90, "ww", face=180)                 # Wire in front of the south line,
    d.line(15.0, -24.6, 90, "w", face=180)                   # the chicane's lane left open
    for x, y in ((23.5, -23.5), (26.5, -25.0), (29.5, -23.5), (24.0, 10.5), (27.0, 12.0), (30.0, 10.5),
                 (31.0, -10.5), (31.5, -15.5)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)          # Hedgehogs: the street both ways, the junction road
    d.g("autorifleman", -4.0, -19.2, 180)
    d.g("rifleman", 5.0, -19.2, 180)
    d.g("rifleman", 14.0, -19.2, 180)
    d.g("rifleman", 18.4, -14.6, 90)
    tower_t4_inside(d)

    d.tier()  # T5: the stronghold: checkpoints on the east street north and south, the junction road and the west
    # road's mouth on the square; a mortar in the north yard; AT man at the gate; the kill zone inside
    d.checkpoint(27.4, 17.0, 10, out=6.0)
    d.checkpoint(26.8, -30.5, 182, out=6.0)
    d.checkpoint(36.5, -13.2, 92, out=6.0, side=-1)
    d.checkpoint(-31.0, -16.5, 240, width=10.0, out=5.0)
    d.s("mortar", -5.0, 15.0, 180)
    d.g("at", 12.2, -19.3, 180)
    tower_t5_inside(d)


def pyrgos(d):
    """Pyrgos: the tower stands in its own block. A city wall runs down the east side (x 19) with the hill rising
    behind it (5-7 m higher at x 30-40: high ground looking into the compound); to the north a low concrete wall
    (y 13.3) and a city wall (y 17) with a lane between them, open to the west; to the west and south only pipe
    fences (low, see-through), the open lot west and the treed square south, the road 57 m south. The approaches:
    the square from the south (in front of the main door, the main one), the west lot, the north lane from the
    west, and fire from the hill over the east wall. The occupier builds the west and south sides itself."""
    tower_t1(d, (16.2, -9.6))

    d.tier()  # T2: a C of sandbags square with the main door, off the porch: a long bag across, shorts back to
    # the porch at its ends, the pair inside it
    d.o(LONG, 10.5, -11.4, 180)
    d.o(SHORT, 8.6, -10.5, 270)
    d.o(SHORT, 12.4, -10.5, 90)
    d.g("rifleman", 9.9, -10.1, 180)
    d.g("autorifleman", 11.1, -10.1, 180)
    tower_t2_inside(d)

    d.tier()  # T3: the compound closed. The west side a blank Mil wall (x -23.5, from the low north wall down);
    # the south front: the west block's blank face (x -17..-2) with H-barriers either side of it: the west yard's
    # mouth (x -23.3..-16.6, an embrasure in it), and from the block's corner across the porch's front to the
    # east wall (y -13.6), a bar gate on the door's axis; men behind it, the back door's post; the roof HMG over
    # the square, a GMG on the roof's west edge over the west lot, the window marksman over the hill
    d.fill(-23.6, 13.3, -23.6, -12.6, 270, "M")              # The west wall, from the low north wall down
    d.fill(-24.0, -13.3, -21.0, -13.3, 180)                  # The west yard's mouth, a round bag in it (the
    d.embrasure(-20.2, -13.3, 190, role=None)                # HMG's embrasure at T4)
    d.fill(-19.4, -13.3, -16.9, -13.3, 180)
    d.fill(-1.9, -13.6, 8.3, -13.6, 180)                     # The porch's front, block corner to the gate
    d.o(BARGATE, 10.5, -13.6, 180)                           # x 8 .. 13
    d.fill(12.7, -13.6, 19.2, -13.6, 180)                    # On into the east wall
    d.post("autorifleman", -14.8, 10.6, 0)
    d.g("rifleman", -21.6, -11.9, 180)
    d.g("autorifleman", 1.0, -11.8, 180)
    tower_t3_inside(d)
    d.gun("gmg", -15.6, -3.0, 270, ROOF)

    d.tier()  # T4: the fort. Bunkers out from the line at both corners (their slits along the faces), the north
    # lane shut where it meets the west wall; a chicane at the fence's gap in front of the gate; wire along the
    # fence line either side of the chicane, hedgehogs across the square's open middle (vehicles from the road);
    # an HMG in the west yard's embrasure (the square's west half, the lot's mouth), an HMG on the roof's east
    # edge against the hill; men along the line and at the gate
    d.bunker(-22.6, -16.4, 200)
    d.bunker(16.0, -16.7, 160)
    d.o(MIL, -23.5, 15.2, 270)                               # The north lane shut at the west wall
    d.o(HB3, 8.3, -21.4, 180)                                # The chicane: the fence gap (x 6-10.6) masked
    d.line(-19.0, -20.6, 90, "www", face=180)                # x -19 .. 3.8
    d.line(12.0, -20.6, 90, "w", face=180)
    for x, y in ((0.0, -28.0), (4.0, -30.0), (9.0, -31.0), (14.0, -30.0), (17.0, -27.5)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.embrasure(-20.2, -13.3, 190, bag=False)                # In the west yard's mouth
    d.gun("hmg", 11.8, 6.6, 90, ROOF)
    d.g("autorifleman", 3.6, -11.8, 180)
    d.g("rifleman", 6.0, -11.8, 180)
    d.g("rifleman", 14.6, -11.8, 180)
    d.g("rifleman", -8.0, 11.8, 0)                           # Over the low north wall into the lane
    tower_t4_inside(d)

    d.tier()  # T5: checkpoints on the square's path from the road, the west lot and the north lane; a bunker on
    # the hill outside the east wall denying the high ground; the mortar behind the tower; AT on the roof over
    # the square, an AT man at the gate; the kill zone inside
    d.checkpoint(8.0, -36.0, 180, out=5.0)
    d.checkpoint(-36.0, -8.0, 270, out=-6.0)
    d.o(HB3, -36.0, 15.2, 270)
    d.g("rifleman", -34.4, 14.4, 270)
    d.g("autorifleman", -34.4, 16.0, 270)
    d.bunker(27.0, -4.0, 70)
    d.s("mortar", 0.0, 10.8, 180)
    d.g("at", 13.6, -11.8, 180)
    tower_t5_inside(d, at=(2.0, -9.5, 180))


# ================================================================ House_Big_01 (Athira, Zaros)
# The two-storey house (model plan): the ground floor (-2.47): the main room (x -1..4, y -7..-2, with a nook to
# y 1), its door (-1.8, -6.1) off the veranda; the veranda (x -4..-3, y -7..2) along the west side, covered by the
# balcony above, open to the west, the main door (-3.3, -7.3) at its south end; the hall (x -4..0, y 2) with the
# stairs; the north room (x -4..4, y 4..7) with the side door (4.9, 5.6) facing east. The upper floor (0.95): the
# south room and the balcony over the veranda (x -4..4, y -7..-4; the balcony x -4..-3 the length of the
# house), the north room (y 4..7); windows east (x 5: y -5.25, -2.1, 5.5).
H0, H1 = -2.47, 0.95


def house_t1(d, flag):
    """T1: the desk in the main room (the chair by the east wall, both facing it), the map board on the west
    wall; gendarmes on the veranda by the main door and in the main room; the flag."""
    d.tier()
    d.o(DESK, 2.2, -3.4, 90, H0)
    d.o(CHAIR, 3.8, -3.4, 90, H0)
    d.o(BOARD, -1.1, -3.8, 270, H0)
    d.o(FLAG, *flag, 180, flag=True, nudge=1.0)
    d.g("gendarme", -3.5, -5.6, 180, H0)
    d.g("gendarme", 1.2, -1.0, 200, H0)


def house_t5_inside(d):
    """T5: the kill zone inside. The veranda bagged across at y -3.4 (a rifleman behind it covers the main door 4 m
    off); the main room's door (-1.8, -6.1) covered by an MG behind a long bag at the room's east side (5 m, the
    length of the room) and a rifleman in the nook; the north room's side door covered from behind bags inside;
    upstairs the stair head held, the south room's east window."""
    d.o(SHORT, -3.5, -3.4, 180, H0)
    d.g("rifleman", -3.5, -2.2, 180, H0)
    d.o(LONG, 2.6, -6.0, 270, H0)
    d.g("mg_gunner", 3.7, -5.9, 270, H0)
    d.g("rifleman", 0.4, 0.4, 200, H0)
    d.o(SHORT, 3.4, 5.4, 90, H0)
    d.g("rifleman", 2.2, 5.4, 90, H0)
    d.g("rifleman", -1.0, 1.0, 0, H1)
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

    d.tier()  # T3: the compound closed. The west lot: an H-barrier line down its west side (an HMG's embrasure in
    # it, facing the west road) to a bag bunker at its south-west corner (its slit down the west lane), and
    # along its south side to the city wall; the lane north shut with Mil walls; the courtyard's opening with a
    # tall H-barrier wall; the south front an H-barrier line (y -12.6) from the city wall to the shop block, the
    # bar gate before the main door (x -4.3..0.8), round-bag embrasures in it; a GMG in the courtyard; men behind
    # the lines, upstairs at the east windows
    d.fill(-13.2, -1.2, -13.2, -5.0, 270)
    d.embrasure(-13.2, -5.8, 270)
    d.fill(-13.2, -6.6, -13.2, -7.2, 270)
    d.bunker(-12.3, -8.4, 180)
    d.fill(-10.9, -9.2, -4.3, -9.2, 180)
    d.fill(-12.4, 8.6, -5.5, 8.6, 0, "M")
    d.fill(12.0, 7.0, 17.5, 5.8, 15, "W")
    d.o(BARGATE, -1.75, -12.6, 180)
    d.fill(0.5, -12.6, 7.2, -12.6, 180)
    d.embrasure(8.0, -12.6, 180, role=None)
    d.fill(8.8, -12.6, 14.2, -12.6, 180)
    d.embrasure(15.0, -12.6, 180, role=None)
    d.fill(15.8, -12.6, 22.8, -12.6, 180)
    d.gun("gmg", 11.0, -3.0, 170)
    d.g("rifleman", -12.0, -2.4, 270)
    d.g("autorifleman", 4.6, -10.8, 180)
    d.g("rifleman", 19.0, -10.8, 180)
    d.g("rifleman", 4.2, -5.3, 90, H1)
    d.g("marksman", 4.2, 5.5, 90, H1)

    d.tier()  # T4: the fort. A bunker out in front of the south line's east end, its slit straight down the
    # south-east gap; a chicane of two staggered H-barrier teeth in the south lane (the gate is reached in an S
    # through a pocket the line, the door's C and the HMG cover); wire across the west lot's mouth; hedgehogs in
    # the south-east gap, the strip's mouth on the east road and the west lane; the south line's HMG; the balcony
    # MG over the west lot; men along the lines
    d.bunker(19.0, -15.3, 160)
    d.fill(-4.3, -16.4, 3.0, -16.4, 180)
    d.fill(-0.4, -20.4, 6.2, -20.4, 180)
    d.fill(-15.0, -1.6, -15.0, -8.2, 270, "w")
    for x, y in ((19.6, -19.5), (19.8, -22.0), (24.0, 8.8), (24.0, 11.2), (-10.0, -15.0), (-7.0, -17.0)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.embrasure(8.0, -12.6, 180, bag=False)
    d.g("mg_gunner", -3.6, -0.6, 270, H1)
    d.g("rifleman", 1.8, -10.8, 180)
    d.g("autorifleman", 12.0, -10.8, 180)
    d.g("rifleman", -7.5, -7.9, 180)
    d.g("rifleman", -11.8, -4.0, 270)
    d.g("rifleman", 6.2, 4.3, 90)

    d.tier()  # T5: checkpoints at the west lot's mouth on the west road, in the south lane and across the strip's
    # mouth on the east road; the mortar in the courtyard; the AT launcher in the south line's second embrasure,
    # an AT man at the gate; the kill zone inside
    d.checkpoint(-27.0, -4.7, 270, width=6.5, out=-5.0, hb=HB3, block=CNC)
    d.checkpoint(0.0, -26.0, 180, width=7.0, out=5.0, side=-1, hb=HB3, block=CNC)
    d.o(HB3, 26.8, 9.9, 90)
    d.g("rifleman", 25.4, 9.2, 90)
    d.g("autorifleman", 25.4, 10.6, 90)
    d.s("mortar", 11.0, 2.0, 180)
    d.embrasure(15.0, -12.6, 180, role="at", bag=False)
    d.g("at", 0.6, -11.0, 180)
    house_t5_inside(d)


def zaros(d):
    """Zaros: a shop stands hard against the house's front (south), so the main door's way out is the veranda's
    open west side, into a walled yard (x -21..-5, y -15..7.5, Addon_02 in it) with two openings: a passage north
    (x -9..-4.5, y 7.5..10.5) onto the open ground north of the house, and a 2 m gap south (x -14..-12, y -15.5)
    onto the open ground south. The side door faces the main road (x 13-24, north-south) across a 5 m strip;
    Addon_03 stands behind the house (north), a 1 m gap between them joins the strip to the yard. The open ground
    north reaches the road through a passage north of Addon_03 (x -1..13, y 16..19.5) and the north-west road
    through a gap at (-19, 23). The approaches: the road from the north and the south (vehicles), the open ground
    north, the open ground south."""
    house_t1(d, (-9.6, -3.0))

    d.tier()  # T2: the veranda's open side held by a C square with it (a long bag across, shorts back to the house),
    # the side door's C (the strip's low walls on its north); the balcony over the yard
    d.o(LONG, -7.6, -3.5, 270)
    d.o(SHORT, -6.7, -5.3, 180)
    d.o(SHORT, -6.7, -1.7, 0)
    d.g("rifleman", -6.4, -4.1, 270)
    d.g("autorifleman", -6.4, -2.9, 270)
    d.o(LONG, 7.6, 5.6, 90)
    d.o(SHORT, 6.7, 4.0, 180)
    d.o(SHORT, 6.7, 7.2, 0)
    d.g("rifleman", 6.2, 5.6, 90)
    d.g("rifleman", -3.6, -3.4, 270, H1)

    d.tier()  # T3: the compound closed. The yard's north passage shut by a gate (a post behind it), its south gap
    # by a round-bag embrasure between H-barriers; the strip closed along the road (x 10.5) from the shop to a bar
    # gate square with the side door, tied into the low walls north; two embrasures in that line: the HMG down the
    # road south, the GMG up it north; upstairs the east windows
    d.o(CITYGATE, -6.8, 7.7, 0)
    d.post("rifleman", -6.8, 4.6, 0)
    d.fill(-14.6, -15.5, -13.8, -15.5, 180)
    d.embrasure(-12.9, -15.5, 180, role=None)
    d.fill(-12.0, -15.5, -11.4, -15.5, 180)
    d.g("rifleman", -10.8, -14.0, 180)
    d.fill(10.5, -6.6, 10.5, -5.4, 90)
    d.embrasure(10.5, -4.5, 120, line_face=90)
    d.fill(10.5, -3.6, 10.5, 0.2, 90)
    d.embrasure(10.5, 1.0, 60, role="gmg", line_face=90)
    d.fill(10.5, 1.8, 10.5, 3.3, 90)
    d.o(BARGATE, 10.5, 5.6, 90)
    d.o(HB1, 9.6, 8.5, 0)
    d.g("autorifleman", 9.0, -6.3, 90)
    d.g("rifleman", 4.2, -5.3, 90, H1)
    d.g("marksman", 4.2, 5.5, 45, H1)

    d.tier()  # T4: the fort. A bunker in the north passage (its slit over the open ground north) closing it in
    # front of the gate; a bunker out on the road's edge by the shop, its slit down the road south; a blast wall
    # in front of the bar gate (the gate is reached round it); wire along the low wall north and outside the south
    # gap; hedgehogs across the road both ways; the HMG behind the south gap; the balcony MG; men at the gate
    d.bunker(-6.3, 10.6, 0)
    d.o(HB1, -8.6, 10.6, 0)
    d.bunker(12.6, -5.2, 150, road_ok=True)
    d.o(HB3, 12.6, 5.6, 90, road_ok=True)
    d.fill(-17.0, 11.6, -10.0, 11.6, 0, "w")
    d.fill(-16.5, -17.2, -9.5, -17.2, 180, "w")
    for x, y in ((14.5, 15.0), (17.5, 16.5), (20.5, 15.0), (14.5, -13.0), (17.5, -14.5), (19.0, -12.5)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)
    d.embrasure(-12.9, -15.5, 180, bag=False)
    d.g("mg_gunner", -3.6, -0.6, 270, H1)
    d.g("rifleman", 9.0, 3.2, 90)
    d.g("rifleman", 8.8, 7.0, 90)
    d.g("autorifleman", -9.0, 5.6, 0)
    d.g("rifleman", -14.6, -14.0, 180)

    d.tier()  # T5: checkpoints on the road north and south, roadblocks in the passage from the open ground north
    # to the road and in the gap to the north-west road; the mortar in the yard; an AT launcher behind bags
    # north of the gate (up the road), an AT man at the gate; the kill zone inside
    d.checkpoint(19.0, 23.0, 0, width=9.0, out=6.0)
    d.checkpoint(16.6, -21.0, 180, width=9.0, out=6.0)
    d.o(HB3, 6.0, 17.6, 90)
    d.g("rifleman", 4.6, 17.0, 90)
    d.g("autorifleman", 4.6, 18.6, 90)
    d.o(HB5, -18.8, 22.0, 0)
    d.g("rifleman", -20.6, 20.7, 0)
    d.g("autorifleman", -19.2, 20.9, 0)
    d.s("mortar", -10.5, -6.0, 180)
    d.gun("at", 10.0, 11.0, 30)
    d.g("at", 9.0, 6.6, 90)
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
