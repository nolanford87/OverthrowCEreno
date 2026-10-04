"""
Drafts the mayor's office layouts of drafting group "towns" (tools/officegen/townlib.py has the API): eleven towns
of 4 tiers, all with Land_i_House_Big_01 as the office. Run from the repository root:
    python tools/officegen/drafting/towns.py [town ...] [-m] [-t N] [-a]
    (all towns without names; -m maps, -t the tier to map, -a the line audit of every run)

The building (model coordinates, front = -y): the house proper is x -1.8..5.6, y -7.8..7.8, plus a north-west room
out to x -4.7 (y 0.5..7.8); a covered veranda fills the south-west corner (x -4.7..-1.8, y -7.8..0.5), raised
0.6 m, open to the west between pillars and to the south. The main door opens west onto the veranda, the side door
(5.1, 5.6) east. The only real windows are in the east wall (t.plan().windows).

Pass 1 (DESIGN_BRIEF.md, "The work is now split into passes"): walls, H-barriers and sandbags only, every other
thing (guards, statics, towers, wire, hedgehogs, gates, the flag, the furniture) out of every tier until its own
pass. The helpers for those (post, nest, tower, belt, entry...) stay for the later passes. The ladder:
  T1  empty.
  T2  sandbags on the house: the veranda's north bay and south end, the side door and the ground floor's (east)
      window, bagged on the ground against the wall where there's room (nothing out in the yard).
  T3  a tight H-barrier ring round the house and its yard, tied into the neighbouring buildings and the real old
      walls (real_wall: the city walls; the low stone and concrete garden walls, tin walls, fences and broken walls
      are lined or crossed, never counted), with no opening.
  T4  a high-wall outer ring (Land_Mil_WallBig_4m_F, Land_CncWall1_F where a 4 m piece can't fit exactly) round
      the T3 ring, tied into the bigger blocks round it. Where a main road leaves no room for two lines (Neochori,
      Sofia), the T3 face along it is the outer line too, stacked 2-high, and the outer ring ties into it.

Every run is unbroken: run() finds the faces of what it ties into (a building, a wall, the house or another run) by
scanning along its line, then fits H-barrier pieces exactly between them so each piece overlaps the next and the
faces at its ENDS (0.3-0.6 m piece to piece, 0.3-0.4 m into a building, wall or the house; never mid-piece); -a prints each run's length against the gap it closes. The middle
of every piece (0.6 m off each end, half its depth, as the in-game check measures it) must stand clear of the
buildings, walls, rocks and the house, and of a road's paved core. leak() walks out on a 0.5 m grid: tiers 3 and 4 must not get
out (from the doors, as the game's own check walks); T4's outer ring is walked alone too (the T3 ring left out).
"""
import collections
import math
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

# Pass 1 is walls only (DESIGN_BRIEF.md, "The work is now split into passes"): no guards on any tier, so townlib's
# old "2 guards a tier" line is left out of the check (here, for writing too); every other check stands.
_check = tl.check
tl.check = lambda town, tiers: [p for p in _check(town, tiers) if not re.fullmatch(r"tier \d+: [01] guards", p)]

TOWNS = ["Agios Dionysios", "Chalkeia", "Charkia", "Kalochori", "Molos", "Neochori", "Panochori", "Paros",
         "Rodopoli", "Sofia", "Therisa"]

EXTENT = (-4.7, -7.8, 5.6, 7.8)  # The house's real walls, veranda and steps (the probed box runs past them)
HOUSE = ((-1.8, -7.8, 5.6, 7.8), (-4.7, 0.5, -1.8, 7.8))  # Its solid walls (the veranda is open: men walk through it)

HB5, HB3, HB1 = "Land_HBarrier_5_F", "Land_HBarrier_3_F", "Land_HBarrier_1_F"
BAR = "Land_BarGate_F"
LONG, SHORT, ROUND = "Land_BagFence_Long_F", "Land_BagFence_Short_F", "Land_BagFence_Round_F"
BUNKER, TOWER = "Land_BagBunker_Small_F", "Land_BagBunker_Tower_F"
HOG, WIRE = "Land_CzechHedgehog_01_F", "Land_Razorwire_F"
PIPEGATE = "Land_PipeFence_03_m_gate_r_F"  # A 4 m gate for an opening too narrow for the bar gate (its leaf swings 2.5 m)
WALL, CNC1 = "Land_Mil_WallBig_4m_F", "Land_CncWall1_F"  # The tier 4 high wall, and its 1 m filler


def vec(mdir):
    return (math.sin(math.radians(mdir)), math.cos(math.radians(mdir)))


def heading(dx, dy):
    return math.degrees(math.atan2(dx, dy)) % 360


# Real sizes [length, depth] (townlib.MEASURED less its slack, and the screenshots for the tower and bunker)
SIZE = {HB5: (5.8, 1.76), HB3: (3.6, 1.76), HB1: (1.4, 1.7), LONG: (3.0, 0.5), SHORT: (1.8, 0.5), ROUND: (2.6, 1.0),
        WIRE: (8.0, 1.0), BAR: (6.0, 0.6), PIPEGATE: (4.0, 0.3), HOG: (1.8, 1.8), TOWER: (4.8, 7.2), BUNKER: (4.4, 4.6),
        WALL: (4.0, 0.8), CNC1: (1.0, 0.6)}
FILL = (HB5, HB3, HB1)  # The run pieces, longest first
WALL_FILL = (WALL, CNC1, CNC1)  # A high-wall run: 4 m walls, 1 m concrete sections where the 4 m ones can't fit exactly
JOINT = (0.3, 0.6)      # How far a piece overlaps the next one at its end
TIE = (0.3, 0.4)        # ... and a face it ties into (within 0.6 m of its end even as townlib.check sizes it)
TIE_WALL = (0.3, 0.5)   # ... for the high walls (4.0 m, measured 4.1: 0.5 m in keeps 0.6 m off its end clear)
STACK = {HB5: 1.7, HB3: 1.7, HB1: 1.6}  # Where a second H-barrier is dropped to stand on the first (2-high)
HB_DEPTH = 1.76
SOLID = ("building", "part", "wall", "rock")
TOWER_DECK = 3.4  # The tower's platform above the ground at its centre (measured in the game)
# Where the men stand on a tower, in the tower's own frame (x right, y out of its front, z above the ground under it,
# facing relative to the tower's): at the centre and just forward of it, looking out over +y (round 3: fine)
TOWER_SPOTS = [(0.0, 0.3, TOWER_DECK, 0), (0.45, 0.5, TOWER_DECK, 20), (-0.45, 0.5, TOWER_DECK, -20)]


def real_wall(model):
    """Whether an old wall is a real barrier (about 2 m or more, whole): the city walls and their pillars (a bounding
    box over 4 m high, some 2.5 m of it above the ground), the canal and pipe-concrete walls. The stone walls and
    their pillars (a 2.6 m box: about 1.3 m high), the low concrete garden walls, tin walls (a 3 m box: under 2 m),
    fences, railings and the broken ("d") pieces aren't: a man climbs or steps over them, so the rings line them."""
    m = model.lower()
    if m.endswith("d_f.p3d"):
        return False
    return m.startswith(("city_", "city2_", "canal_wall", "pipewall_concrete"))


def size_of(kind, what):
    if kind == "object":
        return SIZE.get(what) or tl.CLASSES.get(what, (0.6, 0.6))
    return (2.0, 2.3) if kind == "static" else (0.6, 0.6)


def middle_of(what):
    """A barrier's middle as the in-game check measures it: 0.6 m off each end of its longest known length, half
    its depth."""
    ln, dp = SIZE.get(what) or tl.CLASSES[what]
    if what not in (BAR,):
        ln = max(ln, tl.CLASSES.get(what, (0, 0))[0], tl.MEASURED.get(what, (0, 0))[0] if what != WIRE else 0)
    if "Gate" in what and what != BAR:
        dp = max(dp, tl.MEASURED.get(what, (0, 0))[1])  # A gate's leaf swings
    return max(ln - 2 * tl.BARRIER_OVERLAP, 0.2), max(dp * 0.5, 0.2)


def in_house(x, y, m=0.0):
    return any(b[0] - m <= x <= b[2] + m and b[1] - m <= y <= b[3] + m for b in HOUSE)


def solve(g, ea, eb, opts=FILL, jr=JOINT):
    """Pieces that close a gap of g m between two faces: their ends overlap the faces by ea / eb (ranges) and each
    other by jr. Returns (classes in order, [end overlap a, joints..., end overlap b]) or None."""
    best = None
    lens = [SIZE[c][0] for c in opts]
    for n0 in range(0, 16):
        for n1 in range(0, 5):
            for n2 in range(0, 7):
                n = n0 + n1 + n2
                if n == 0 or n > 16:
                    continue
                T = n0 * lens[0] + n1 * lens[1] + n2 * lens[2]
                lo = g + ea[0] + eb[0] + (n - 1) * jr[0]
                hi = g + ea[1] + eb[1] + (n - 1) * jr[1]
                if lo - 1e-6 <= T <= hi + 1e-6:
                    key = (n, n2, n1, abs(T - (lo + hi) / 2))
                    if best is None or key < best[0]:
                        best = (key, (n0, n1, n2), T, lo, hi)
    if best is None:
        return None
    (n0, n1, n2), T, lo, hi = best[1:]
    lam = 0.5 if hi - lo < 1e-9 else (T - lo) / (hi - lo)
    n = n0 + n1 + n2
    order = [opts[0]] * n0 + [opts[1]] * n1 + [opts[2]] * n2
    if n0 and (n1 or n2):  # The short pieces in the middle of the run, the long ones at its ends
        k = max(1, n0 // 2)
        order = [opts[0]] * k + [opts[1]] * n1 + [opts[2]] * n2 + [opts[0]] * (n0 - k)
    ov = [ea[0] + lam * (ea[1] - ea[0])] + [jr[0] + lam * (jr[1] - jr[0])] * (n - 1) + [eb[0] + lam * (eb[1] - eb[0])]
    return order, ov


class Drafter:
    def __init__(self, t):
        self.t = t
        self.placed = []  # (x, y, length, depth, mdir, barrier, what) of the ground things so far
        self.notes = []
        self.problems = []  # Design errors: a run that can't close, a piece clipping (the draft isn't written)
        self.items = []   # The current tier's full snapshot
        self.runs = collections.OrderedDict()  # name: the run's record (for the audit, posts and slots)
        self.towers = []  # [x, y, ground z, facing, men] of the towers placed
        self.stacked = []  # (x, y, length, depth, mdir, True, what) of the second blocks dropped on top (2-high)
        self.tier = 1

    # ---- what's there
    def probe_hits(self, x, y, ln, dp, mdir, pad=0.05, kinds=SOLID):
        t = self.t
        w = t.to_world(x, y, 0)
        return [h for h in t.hits(w[0], w[1], ln, dp, (t.dir + mdir) % 360, pad) if h[0] in kinds]

    def barrier_hits(self, x, y, ln, dp, mdir=0.0, pad=0.0):
        """The probed things a man can't get through or over at a footprint: buildings (not the small props the
        probe lists as buildings: he walks round them), rocks and the real walls (real_wall)."""
        if not hasattr(self, "_small"):
            self._small = {o["model"] for o in self.t.objs if o["kind"] == "building" and max(o["box"][2] - o["box"][0], o["box"][3] - o["box"][1]) < 2.5}
        return [h for h in self.probe_hits(x, y, ln, dp, mdir, pad) if (h[0] != "wall" or real_wall(h[1])) and h[1] not in self._small]

    def what_at(self, x, y):
        """What a run end met at a point: a run's name, "the house", or the probed thing's model."""
        for name, rec in self.runs.items():
            if any(self.boxes_overlap((x, y, 0.15, 0.15, 0), (p["x"], p["y"]) + SIZE[p["cls"]] + (rec["out"],), 0) for p in rec["pieces"]):
                return f"run {name}"
        if in_house(x, y, 0.1):
            return "the house"
        hit = self.probe_hits(x, y, 0.15, 0.15, 0.0, 0.0)
        return (hit[0][1].replace(".p3d", "") + ("" if hit[0][0] != "wall" or real_wall(hit[0][1]) else " (low)")) if hit else "?"

    def solid_at(self, x, y, own=None, low=False):
        """Whether a point is in a building, real wall (any wall or fence: low), rock, the house's walls or one of our
        run pieces (not `own`)."""
        if in_house(x, y):
            return True
        if (self.probe_hits if low else self.barrier_hits)(x, y, 0.1, 0.1, 0.0, 0.0):
            return True
        return any(p[5] and p[6] not in (WIRE, HOG, LONG, SHORT) and (own is None or p not in own) and
                   self.boxes_overlap((x, y, 0.05, 0.05, 0), p[:5], 0) for p in self.placed)

    def free(self, kind, what, x, y, mdir, road_ok=False, pad=0.15, gap=0.05):
        t = self.t
        if math.hypot(x, y) > 44.5:
            return False
        ln, dp = size_of(kind, what)
        bar = kind == "object" and tl.is_barrier(what)
        tln, tdp = middle_of(what) if bar else (ln, dp)
        kinds = SOLID if bar else SOLID + ("tree",)
        if self.probe_hits(x, y, tln, tdp, mdir, pad, kinds):
            return False
        if t.on_office(x, y, tln, tdp, mdir):
            return False
        if self.overlaps(EXTENT, x, y, tln, tdp, mdir, 0.1 if what == TOWER else 0.3):
            return False
        if not road_ok and self.road(x, y, ln, mdir):
            return False
        if kind == "static" or what in (BUNKER, TOWER):  # Level ground (a static on a slope's edge floats)
            hs = [t.ground_model(cx, cy) for cx, cy in self.corners(x, y, ln * 0.8, dp * 0.8, mdir) + [(x, y)]]
            if max(hs) - min(hs) > {"static": 0.45, TOWER: 1.2}.get(kind if kind == "static" else what, 0.6):
                return False  # (A tower stands upright on its centre: on a slope its low side shows a gap)
        for p in self.placed:
            if bar and p[5]:
                continue  # Barrier pieces may overlap each other (an unbroken line)
            if self.boxes_overlap((x, y, ln, dp, mdir), p[:5], gap):
                return False
        return True

    def why(self, kind, what, x, y, mdir, road_ok=False):
        """What blocks a footprint (for tuning)."""
        ln, dp = size_of(kind, what)
        bar = kind == "object" and tl.is_barrier(what)
        tln, tdp = middle_of(what) if bar else (ln, dp)
        out = [h[:2] for h in self.probe_hits(x, y, tln, tdp, mdir, 0.15, SOLID if bar else SOLID + ("tree",))]
        if self.t.on_office(x, y, tln, tdp, mdir) or self.overlaps(EXTENT, x, y, tln, tdp, mdir, 0.1 if what == TOWER else 0.3):
            out.append("office")
        if not road_ok and self.road(x, y, ln, mdir):
            out.append("road")
        if kind == "static" or what in (BUNKER, TOWER):
            hs = [self.t.ground_model(cx, cy) for cx, cy in self.corners(x, y, ln * 0.8, dp * 0.8, mdir) + [(x, y)]]
            if max(hs) - min(hs) > 0.35:
                out.append(f"slope {max(hs) - min(hs):.2f}")
        out += [("placed", p[6], round(p[0], 1), round(p[1], 1)) for p in self.placed
                if not (bar and p[5]) and self.boxes_overlap((x, y, ln, dp, mdir), p[:5], 0.05)]
        return out

    @staticmethod
    def corners(x, y, ln, dp, mdir):
        a, b = vec(mdir + 90), vec(mdir)
        return [(x + a[0] * ln / 2 * sx + b[0] * dp / 2 * sy, y + a[1] * ln / 2 * sx + b[1] * dp / 2 * sy) for sx in (-1, 1) for sy in (-1, 1)]

    def boxes_overlap(self, p, q, gap):
        """Separating axis test of two turned rectangles (x, y, length, depth, mdir), shrunk by gap."""
        A = self.corners(p[0], p[1], max(p[2] - gap, 0.05), max(p[3] - gap, 0.05), p[4])
        B = self.corners(q[0], q[1], max(q[2] - gap, 0.05), max(q[3] - gap, 0.05), q[4])
        for m in (p[4], p[4] + 90, q[4], q[4] + 90):
            ax = vec(m)
            pa = [c[0] * ax[0] + c[1] * ax[1] for c in A]
            pb = [c[0] * ax[0] + c[1] * ax[1] for c in B]
            if max(pa) <= min(pb) or max(pb) <= min(pa):
                return False
        return True

    def overlaps(self, ext, x, y, ln, dp, mdir, margin):
        cx, cy = (ext[0] + ext[2]) / 2, (ext[1] + ext[3]) / 2
        return self.boxes_overlap((x, y, ln, dp, mdir), (cx, cy, ext[2] - ext[0] + 2 * margin, ext[3] - ext[1] + 2 * margin, 0), 0)

    def road(self, x, y, ln=0.5, mdir=0.0):
        a = vec(mdir + 90)
        for s in (-0.5, 0, 0.5):
            px, py = x + a[0] * ln * s * 0.8, y + a[1] * ln * s * 0.8
            w = self.t.to_world(px, py, 0)
            if any(d < seg["width"] / 2 - 1.5 for d, seg in self.t.roads_near(w[0], w[1], 15)):
                return True  # Within the road's paved core (the probe's widths take in the verges)
        return False

    # ---- placing
    def make(self, kind, what, x, y, mdir, z=None, flag=False):
        t = self.t
        if kind == "guard":
            return tl.guard(t, what, x, y, z, mdir)
        if kind == "static":
            return tl.static(t, what, x, y, z, mdir)
        return tl.obj(t, what, x, y, z, mdir, flag=flag)

    def add(self, kind, what, x, y, mdir, z=None, flag=False):
        """Placed without checks (inside the house, or already checked)."""
        if z is None:
            ln, dp = size_of(kind, what)
            self.placed.append((x, y, ln, dp, mdir, kind == "object" and tl.is_barrier(what), what if kind == "object" else kind))
        it = self.make(kind, what, x, y, mdir, z, flag)
        self.items.append(it)
        return it

    def put(self, kind, what, x, y, mdir, search=0.0, road_ok=False, flag=False, need=False, note=None):
        """On the ground at the nearest clear spot within `search` m of (x, y); None (noted) without room."""
        for r in [0.0] + [r * 0.25 for r in range(1, int(search * 4) + 1)]:
            n = max(1, int(r * 12))
            for k in range(n):
                a = 2 * math.pi * k / n
                px, py = x + r * math.cos(a), y + r * math.sin(a)
                if self.free(kind, what, px, py, mdir, road_ok):
                    return self.add(kind, what, px, py, mdir, flag=flag)
        self.notes.append(f"no room for {note or what} at {x:.1f},{y:.1f}: {self.why(kind, what, x, y, mdir, road_ok)}")
        if need:
            self.problems.append(f"no room for {note or what} at {x:.1f},{y:.1f}")
        return None

    def group(self, parts, x, y, search=1.0, road_ok=False, note=None):
        """Several things (kind, what, dx, dy, mdir) placed together, moved as one to the nearest spot where all fit."""
        for r in [0.0] + [r * 0.25 for r in range(1, int(search * 4) + 1)]:
            n = max(1, int(r * 12))
            for k in range(n):
                a = 2 * math.pi * k / n
                ox, oy = x + r * math.cos(a), y + r * math.sin(a)
                if all(self.free(kd, w, ox + dx, oy + dy, d, road_ok) for kd, w, dx, dy, d in parts):
                    return [self.add(kd, w, ox + dx, oy + dy, d) for kd, w, dx, dy, d in parts]
        if note != "-":
            self.notes.append(f"no room for {note or parts[0][1]} at {x:.1f},{y:.1f}: " + str([(w, self.why(kd, w, x + dx, y + dy, d, road_ok)) for kd, w, dx, dy, d in parts]))
        return []

    # ---- small positions
    def post(self, role, x, y, face, cover=None, back=None, search=1.0, road_ok=False, note=None, kind=None):
        """A guard (or a static: kind "static") at (x, y) facing `face`, with cover `back` m in front (towards face)."""
        kind = kind or "guard"
        if kind == "static":  # The spot within `search` m (and the facing within 40 degrees) that sees furthest
            best = None
            for r in [0.0] + [k * 0.5 for k in range(1, int(search * 2) + 1)]:
                for k in range(max(1, int(r * 8))):
                    a = 2 * math.pi * k / max(1, int(r * 8))
                    px, py = x + r * math.cos(a), y + r * math.sin(a)
                    fc = self.aim(px, py, face, static=True)
                    v = self.sight(px, py, fc, start=1.2, static=True)
                    if (best is None or v > best[0] + 1) and self.free("static", role, px, py, fc, road_ok):
                        best = (v, px, py, fc)
            if best:
                x, y, face = best[1], best[2], best[3]
        cover = cover or (ROUND if kind == "static" else SHORT)
        if back is None:
            back = {ROUND: 1.3, SHORT: 0.9, LONG: 0.9, HB3: 1.3, HB1: 1.2}.get(cover, 1.1) + (0.4 if kind == "static" else 0)
        f = vec(face)
        cdir = (face + 180) % 360 if cover == ROUND else face
        return self.group([(kind, role, 0, 0, face), ("object", cover, f[0] * back, f[1] * back, cdir)], x, y, search, road_ok, note or role)

    def nest(self, x, y, face, roles=("rifleman", "autorifleman"), search=1.5, note="nest", road_ok=False):
        """A C-shaped sandbag nest: a long bag across the front, short bags on both flanks turned back, two guards
        behind it facing out."""
        f, l = vec(face), vec(face + 90)
        parts = [("object", LONG, f[0] * 1.0, f[1] * 1.0, face),
                 ("object", SHORT, l[0] * 1.75 + f[0] * 0.25, l[1] * 1.75 + f[1] * 0.25, (face + 90) % 360),
                 ("object", SHORT, -l[0] * 1.75 + f[0] * 0.25, -l[1] * 1.75 + f[1] * 0.25, (face + 90) % 360),
                 ("guard", roles[0], l[0] * 0.65, l[1] * 0.65, face),
                 ("guard", roles[1], -l[0] * 0.65, -l[1] * 0.65, face)]
        return self.group(parts, x, y, search, road_ok, note=note)

    def aim(self, x, y, face, out=None, static=False, spread=40):
        """The facing within `spread` degrees of `face` (and 25 of the wall's outward direction, when given) that
        sees furthest (30 m is enough)."""
        best = (self.sight(x, y, face, start=1.2, static=static), face)
        for dd in range(10, spread + 1, 10):
            for f in ((face + dd) % 360, (face - dd) % 360):
                if out is not None and abs((f - out + 180) % 360 - 180) > 25:
                    continue
                v = self.sight(x, y, f, start=1.2, static=static)
                if v > best[0] + 2:
                    best = (v, f)
        return best[1]

    def sight(self, x, y, face, maxd=30.0, start=1.0, static=False):
        """How far a man or gun at (x, y) sees along face before a building, wall, rock, tree, the house or one of
        our tall pieces (towers, bunkers, 2-high stacks; for a gun also any H-barrier: it fires over bags only)."""
        f = vec(face)
        tall = [p for p in self.placed if p[6] in (TOWER, BUNKER) or (static and p[6] in FILL)] + self.stacked
        tall = [q for q in tall if not self.boxes_overlap((x, y, 0.1, 0.1, 0), q[:5], 0)]  # Not what he stands in
        dd = start
        while dd < maxd:
            px, py = x + f[0] * dd, y + f[1] * dd
            if in_house(px, py) or self.probe_hits(px, py, 0.2, 0.2, 0, 0.0, SOLID + ("tree",)):
                return dd
            if any(self.boxes_overlap((px, py, 0.1, 0.1, 0), q[:5], 0) for q in tall):
                return dd
            dd += 0.5
        return maxd

    # ---- runs: the perimeter lines
    def run(self, name, p0, p1, feats=(), ends=("tie", "tie"), out=None, fill=FILL, note="", dry=False):
        """An unbroken H-barrier run from p0 to p1 (model x, y). Each end either ties into what's there ("tie": the
        first building, real wall, house wall or run piece found scanning along the line from its middle, up to 2.5 m
        past the end; "fence": the same, stopping at a low wall or fence too, where a run on its far side ties in
        from the other side, the two overlapping through it), turns a corner ("corner": the run ends flush with the outer face of a run that will tie into
        it there) or stops at the point ("free"). feats, at s metres from p0: ("gate", s) a bar gate in a 6 m
        opening; ("fire", s, role) a 1-high firing step (HBarrier_3) with a guard 1.3 m behind it; ("slot", s) a low
        bagged slot (BagFence_Long) for a static (slot_static). The pieces between are fitted exactly (solve).
        out: the outward model direction (default: away from the house). Where the pieces can't be fitted exactly
        between the faces, the run is tried again up to 0.5 m to either side (oblique faces change the gap)."""
        if not dry:
            n = (-(p1[1] - p0[1]), p1[0] - p0[0])
            ln = math.hypot(*n)
            for disp in (0.0, 0.25, -0.25, 0.5, -0.5):
                q0 = (p0[0] + n[0] / ln * disp, p0[1] + n[1] / ln * disp)
                q1 = (p1[0] + n[0] / ln * disp, p1[1] + n[1] / ln * disp)
                if not self.run(name, q0, q1, feats, ends, out, fill, note, dry=True):
                    p0, p1 = q0, q1
                    break
        L = math.dist(p0, p1)
        u = ((p1[0] - p0[0]) / L, (p1[1] - p0[1]) / L)
        nx, ny = -u[1], u[0]
        if out is None:
            mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
            if nx * (0.5 - mx) + ny * (0 - my) > 0:
                nx, ny = -nx, -ny
        else:
            o = vec(out)
            if nx * o[0] + ny * o[1] < 0:
                nx, ny = -nx, -ny
        odir = heading(nx, ny)
        at = lambda s, o=0.0: (p0[0] + u[0] * s + nx * o, p0[1] + u[1] * s + ny * o)
        rec = {"name": name, "p0": p0, "p1": p1, "L": L, "u": u, "n": (nx, ny), "out": odir, "pieces": [], "slots": [],
               "posts": [], "tier": self.tier, "note": note, "spans": []}
        self.runs[name] = rec

        side = min(0.8, SIZE[fill[0]][1] / 2)  # The scan lines: the run's middle and its two faces

        def scan(s_from, s_to, low=False):
            step = 0.05 if s_to > s_from else -0.05
            s = s_from
            while (s <= s_to) if step > 0 else (s >= s_to):
                for o in ((0.0,) if low else (0.0, side, -side)):  # (a fence: where its middle crosses it, the probe's alone)
                    if (self.probe_hits(*at(s, o), 0.1, 0.1, 0.0, 0.0) if low else self.solid_at(*at(s, o))):
                        return s, o
                s += step
            return None, None
        faces, eranges, ekinds, ties = [], [], [], []
        s_ref = L / 2  # Where the run is clear (the scans for its faces start there)
        if any(self.solid_at(*at(s_ref, o)) for o in (0.0, 0.8, -0.8)):
            s_ref = next((k * 0.1 for k in range(int(L * 10) + 1) if not any(self.solid_at(*at(k * 0.1, o)) for o in (0.0, 0.8, -0.8))), L / 2)
        for k, (end, s_mid, s_lim) in enumerate(((ends[0], s_ref, -2.5), (ends[1], s_ref, L + 2.5))):
            if end in ("tie", "fence"):  # (fence: a low wall or fence it crosses; the run beyond it ties in too)
                s, o = scan(s_mid, s_lim, low=end == "fence")
                if s is None:
                    if dry:
                        del self.runs[name]
                        return ["nothing to tie into"]
                    self.problems.append(f"run {name}: nothing to tie into at its {'start' if k == 0 else 'end'}")
                    s = 0.0 if k == 0 else L
                    eranges.append((0.0, 0.05))
                elif end == "fence":  # Into the low wall or fence it crosses, past its middle (its thickness along the
                    # run measured on the run's middle line), so the run beyond it overlaps this one through it
                    s2 = s
                    while abs(s2 - s) < 2.0 and self.probe_hits(*at(s2, 0.0), 0.1, 0.1, 0.0, 0.0):
                        s2 += 0.05 if k else -0.05
                    th = abs(s2 - s)
                    eranges.append((th / 2 + 0.08, th / 2 + 0.16))  # (the two runs overlap 0.16-0.32 m in it)
                elif in_house(*at(s + (0.05 if k else -0.05), o)):
                    eranges.append((0.2, 0.3))  # Into the house: its walls are kept 0.2 m clear of a piece's middle
                else:
                    eranges.append(TIE_WALL if fill[0] == WALL else TIE)
                faces.append(s)
                if s is not None and not dry:
                    fh = self.probe_hits(*at(s, 0.0), 0.15, 0.15, 0.0, 0.0) if end == "fence" else None
                    ties.append(f"through {fh[0][1].replace('.p3d', '')} (low)" if fh else self.what_at(*at(s + (0.1 if k else -0.1), o)))
            elif end == "corner":
                dep = SIZE[fill[0]][1]  # (the cross run is of the same material)
                faces.append(-dep / 2 if k == 0 else L + dep / 2)
                ties.append("corner (a run ties into it)")
                eranges.append((-0.4, 0.6))  # Flush with the cross run's outer face, give or take: it ties into this one
            else:
                faces.append(0.0 if k == 0 else L)
                eranges.append((-0.3, 0.3))  # A free end stops at the point, give or take
                ties.append("free")
            ekinds.append(end)
        rec["faces"], rec["ends"], rec["eranges"], rec["ties"] = faces, ekinds, eranges, ties
        # Fixed spans along the run; the firing steps and slots may slide up to 1 m (together) for an exact fit
        def plan(shift, gshift=0.0):
            spans = []  # (s0, s1, kind, what, extra, end-overlap range for the pieces meeting it)
            for f in sorted(feats, key=lambda f: f[1]):
                kind, s = f[0], f[1]
                if kind == "gate":
                    cls = f[2] if len(f) > 2 else BAR
                    hw = SIZE[cls][0] / 2
                    spans.append((s + gshift - hw, s + gshift + hw, "gate", cls, None, (-0.05, 0.05)))
                elif kind == "fire":
                    spans.append((s + shift - 1.8, s + shift + 1.8, "fire", HB3, f[2], JOINT))
                elif kind == "slot":
                    spans.append((s + shift - 1.5, s + shift + 1.5, "slot", LONG, None, JOINT))
            spans.sort()
            bounds = [(faces[0], eranges[0])]
            for s0, s1, kind, what, extra, er in spans:
                bounds += [(s0, er), (s1, er)]
            bounds.append((faces[1], eranges[1]))
            layout, errs = [], []  # (s0, s1, cls, kind, extra)
            for k in range(0, len(bounds), 2):
                (a, ea), (b, eb) = bounds[k], bounds[k + 1]
                g = b - a
                gate_side = ea == (-0.05, 0.05) or eb == (-0.05, 0.05)
                if 0.0 < g <= 0.35 and gate_side:
                    continue  # A gap too narrow for a man between a gate's end and what's beside it
                if g <= 0.0:  # A feature reaches the face, or the next feature, itself: it must overlap it as a piece would
                    need = ea if k == 0 else eb if k + 2 == len(bounds) else ea
                    if not need[0] - 0.01 <= -g <= need[1] + 0.01:
                        errs.append(f"run {name}: features overlap by {-g:.2f} at s {a:.1f}")
                    continue
                sol = solve(g, ea, eb, fill)
                if sol and CNC1 in (sol[0][0], sol[0][-1]):  # A 1 m section at a tie: its middle is its centre, so in less
                    ca = (ea[0], min(ea[1], 0.33)) if sol[0][0] == CNC1 and ea[0] < 0.33 < ea[1] else ea
                    cb = (eb[0], min(eb[1], 0.33)) if sol[0][-1] == CNC1 and eb[0] < 0.33 < eb[1] else eb
                    sol = solve(g, ca, cb, fill) or sol
                if sol is None:
                    errs.append(f"run {name}: no fit for a {g:.2f} m gap at s {a:.1f}")
                    continue
                order, ov = sol
                cur = a - ov[0]
                for i, cls in enumerate(order):
                    ln = SIZE[cls][0]
                    layout.append((cur, cur + ln, cls, "fill", None))
                    cur = cur + ln - (ov[i + 1] if i + 1 < len(order) else 0)
            return spans, layout, errs
        tries = [0.0] + [k * sg * 0.1 for k in range(1, 11) for sg in (1, -1)]
        for gshift in tries[:11]:  # The gate moves only if nothing else fits, at most 0.5 m off its axis
            for shift in tries:
                spans, layout, errs = plan(shift, gshift)
                if not errs or not any(f[0] in ("fire", "slot") for f in feats):
                    break
            if not errs or not any(f[0] == "gate" for f in feats):
                break
        if dry:
            del self.runs[name]
            return errs
        if errs:
            spans, layout, errs = plan(0.0)
            self.problems += errs
        for s0, s1, kind, what, extra, er in spans:
            layout.append((s0, s1, what, kind, extra))
        layout.sort()
        for s0, s1, cls, kind, extra in layout:
            sc = (s0 + s1) / 2
            x, y = at(sc)
            ln, dp = SIZE[cls]
            mln, mdp = middle_of(cls)
            bad = self.probe_hits(x, y, mln, mdp, odir, 0.05)
            if self.t.on_office(x, y, mln, mdp, odir) or self.overlaps(EXTENT, x, y, mln, mdp, odir, 0.2):
                bad.append(("office",))
            bad += [("placed", p[6]) for p in self.placed if not p[5] and self.boxes_overlap((x, y, ln, dp, odir), p[:5], 0.05)]
            for ps_ in (s0 + 0.3, sc, s1 - 0.3):  # On a road's paved core (a ring may cross a track, never a road)
                for po in (0.0,):
                    w = self.t.to_world(*at(ps_, po), 0)
                    if ("road",) not in bad and any(seg["type"] != "TRACK" and dd < seg["width"] / 2 - 1.5 for dd, seg in self.t.roads_near(w[0], w[1], 15)):
                        bad.append(("road",))
            if bad:
                self.problems.append(f"run {name}: {cls} at s {s0:.1f}..{s1:.1f} ({x:.1f}, {y:.1f}) clips {bad[:2]}")
            it = self.add("object", cls, x, y, odir)
            rec["pieces"].append({"s0": s0, "s1": s1, "cls": cls, "kind": kind, "x": x, "y": y, "item": it})
            if kind == "fire":
                gx, gy = at(sc, -1.3)
                if self.free("guard", extra, gx, gy, odir, road_ok=True):
                    rec["posts"].append(self.add("guard", extra, gx, gy, odir))
                else:
                    self.problems.append(f"run {name}: no room for the {extra} behind the firing step at {gx:.1f},{gy:.1f}: {self.why('guard', extra, gx, gy, odir, True)}")
            elif kind == "slot":
                rec["slots"].append(sc)
        rec["at"] = at
        return rec

    def watched(self, x, y, ln, mdir):
        """Whether a guard (on the ground or at the house, not on a tower) looks out through this piece from within
        5 m: it stays 1-high so he fires over it."""
        for kind, what, p, o, extra in self.items:
            if kind != "guard":
                continue
            m = self.t.to_model(p)
            if "ground" not in extra and not in_house(m[0], m[1], 1.5):
                continue  # On a tower: over it all
            f = vec((o - self.t.dir) % 360)
            for k in range(1, 11):
                if self.boxes_overlap((m[0] + f[0] * k * 0.5, m[1] + f[1] * k * 0.5, 0.1, 0.1, 0), (x, y, ln, 2.0, mdir), 0):
                    return True
        return False

    def stack(self, *names):
        """The runs' H-barrier pieces 2-high (a second block dropped on each), except the firing steps and where a
        guard looks out over the run."""
        for name in names:
            rec = self.runs[name]
            for p in rec["pieces"]:
                if p["kind"] == "fill" and not p.get("stacked") and not self.watched(p["x"], p["y"], SIZE[p["cls"]][0], rec["out"]):
                    x, y = p["x"], p["y"]
                    self.add("object", p["cls"], x, y, rec["out"], z=self.t.ground_model(x, y) + STACK[p["cls"]])
                    self.stacked.append((x, y) + SIZE[p["cls"]] + (rec["out"], True, p["cls"]))
                    p["stacked"] = True

    def slot_static(self, name, k, role, face=None, spread=40):
        """A static 2.1-2.6 m behind run `name`'s k-th slot, slid along it up to 1.2 m and aimed out through the slot
        (within `spread` degrees of `face`, the run's outward direction by default), where it sees furthest."""
        rec = self.runs[name]
        best = None
        for back in (2.1, 2.4, 2.7):
            for lat in (0.0, 0.4, -0.4, 0.8, -0.8, 1.2, -1.2):
                x, y = rec["at"](rec["slots"][k] + lat, -back)
                f0 = rec["out"] if face is None else face
                for dd in [0] + [sg * a for a in range(10, spread + 1, 10) for sg in (1, -1)]:
                    f = (f0 + dd) % 360
                    v = self.sight(x, y, f, start=1.2, static=True)
                    if (best is None or v > best[0] + 0.5) and self.free("static", role, x, y, f, road_ok=True):
                        best = (v, x, y, f)
        if best is None:
            x, y = rec["at"](rec["slots"][k], -2.1)
            self.problems.append(f"no room for the {role} behind slot {k} of {name}: {self.why('static', role, x, y, rec['out'], True)}")
            return None
        return self.add("static", role, best[1], best[2], best[3])

    def behind(self, name, s, role, back=1.3, face=None):
        """A guard `back` m behind run `name` at s (a 1-high piece in front of him), facing out."""
        rec = self.runs[name]
        x, y = rec["at"](s, -back)
        f = rec["out"] if face is None else face
        if not self.free("guard", role, x, y, f, road_ok=True):
            self.problems.append(f"no room for the {role} behind {name} at s {s}: {self.why('guard', role, x, y, f, True)}")
            return None
        it = self.add("guard", role, x, y, f)
        rec["posts"].append(it)
        return it

    def point(self, name, s, o=0.0):
        """The model point s m along run `name` and o m outward of it."""
        return self.runs[name]["at"](s, o)

    def entry(self, name, gate_run, s, side=1, depth=9.3, half=5.0, right="free", left="free"):
        """A gated chicane on the gate at s along gate_run: a walled box in front of the gate (side walls `half` m
        either side of its axis, `depth` m out) with two staggered baffles, so the way in weaves left and right
        under the gate's guns; side +1 puts the first baffle on the run's -s side. Its walls tie into the run; a
        side wall given "tie" stops at what it meets, "none" is left out (a building closes that side of the box),
        and the baffles tie into whatever closes their side."""
        rec = self.runs[gate_run]
        at, odir = rec["at"], rec["out"]
        o0 = HB_DEPTH / 2 - 0.5  # The side walls start inside the run's pieces (their faces are found by scanning)
        for k, lat, end in (("l", -half, left), ("r", half, right)):
            if end == "none":
                continue  # A building closes that side of the box already
            self.run(f"{name}_{k}", at(s + lat, o0), at(s + lat, depth), ends=("tie", end),
                     out=(odir + (90 if lat > 0 else -90)) % 360, note="chicane side wall")
        b1 = depth * 0.45
        b2 = depth - HB_DEPTH / 2 - 0.05
        lane = half - HB_DEPTH / 2 - 2.9  # ~2.9 m lanes at the open ends of the baffles
        self.run(f"{name}_b1", at(s - side * (half - 0.3), b1), at(s + side * lane, b1), ends=("tie", "free"), out=odir, note="chicane inner baffle")
        self.run(f"{name}_b2", at(s + side * (half - 0.3), b2), at(s - side * lane, b2), ends=("tie", "free"), out=odir, note="chicane outer baffle")

    def belt(self, name, p0, p1, ends=("tie", "tie"), out=None):
        """A razor wire belt from p0 to p1, its pieces overlapping 0.3-0.6 m; each end ties into what's there (a
        building, wall or barrier) or stops at the point ("free"); a stretch the wire can't fit exactly is closed
        with hedgehogs."""
        L = math.dist(p0, p1)
        u = ((p1[0] - p0[0]) / L, (p1[1] - p0[1]) / L)
        nx, ny = -u[1], u[0]
        if out is not None:
            o = vec(out)
            if nx * o[0] + ny * o[1] < 0:
                nx, ny = -nx, -ny
        odir = heading(nx, ny)
        at = lambda s: (p0[0] + u[0] * s, p0[1] + u[1] * s)
        faces = []
        for k, (end, s_lim) in enumerate(((ends[0], -2.5), (ends[1], L + 2.5))):
            f = 0.0 if k == 0 else L
            if end == "tie":
                s = L / 2
                step = -0.05 if k == 0 else 0.05
                while (s >= s_lim) if k == 0 else (s <= s_lim):
                    if self.solid_at(*at(s)):
                        f = s
                        break
                    s += step
                else:
                    self.problems.append(f"belt {name}: nothing to tie into at its {'start' if k == 0 else 'end'}")
            faces.append(f)
        g = faces[1] - faces[0]
        rec = {"name": name, "p0": p0, "p1": p1, "L": L, "faces": faces, "ends": list(ends), "pieces": [], "tier": self.tier, "note": "wire belt", "slots": [], "posts": []}
        self.runs[name] = rec
        wl, j = SIZE[WIRE][0], 0.45
        sol = None
        if ends == ("tie", "tie"):
            sol = solve(g, TIE, TIE, (WIRE, WIRE, WIRE))
        if sol:
            order, ov = sol
        elif "tie" in ends:  # From the tie towards the free end (or as far as the wire fits, the rest hedgehogs)
            n = max(1, int((g + j - 0.45) // (wl - j)) if ends == ("tie", "tie") else round((g + 0.45 + j) / (wl - j)))
            order, ov = [WIRE] * n, [0.35] + [j] * (n - 1) + [None]
            if ends[0] != "tie":  # Lay it from the far end back
                faces = [faces[1] + 0.35 - (n * wl - (n - 1) * j), faces[1]]
                ov = [0.0] + [j] * (n - 1) + [None]
        else:  # Both ends free: centred on the stretch
            n = max(1, round((g + j) / (wl - j)))
            over = n * wl - (n - 1) * j - g
            order, ov = [WIRE] * n, [over / 2] + [j] * (n - 1) + [None]
        cur = faces[0] - ov[0]
        for i, cls in enumerate(order):
            sc = cur + SIZE[WIRE][0] / 2
            x, y = at(sc)
            mln, mdp = middle_of(WIRE)
            bad = self.probe_hits(x, y, mln, mdp, odir, 0.05) + [("placed", p[6]) for p in self.placed if not p[5] and self.boxes_overlap((x, y, 8.0, 1.0, odir), p[:5], 0.05)]
            if bad or self.overlaps(EXTENT, x, y, mln, mdp, odir, 0.2):
                self.problems.append(f"belt {name}: wire at s {cur:.1f} clips {bad[:2]}")
            it = self.add("object", WIRE, x, y, odir)
            rec["pieces"].append({"s0": cur, "s1": cur + SIZE[WIRE][0], "cls": WIRE, "kind": "fill", "x": x, "y": y, "item": it})
            cur = cur + SIZE[WIRE][0] - (ov[i + 1] if i + 1 < len(order) and ov[i + 1] is not None else 0)
        if not sol and ends == ("tie", "tie"):
            s = cur - 0.3 + 0.9
            while s - 0.9 < faces[1] - 0.2:
                x, y = at(s)
                if self.free("object", HOG, x, y, (odir + 45) % 360, road_ok=True):
                    it = self.add("object", HOG, x, y, (odir + 45) % 360)
                    rec["pieces"].append({"s0": s - 0.9, "s1": s + 0.9, "cls": HOG, "kind": "fill", "x": x, "y": y, "item": it})
                else:
                    self.problems.append(f"belt {name}: no room for the closing hedgehog at s {s:.1f}: {self.why('object', HOG, x, y, odir, True)}")
                s += 1.5
        return rec

    def road_belt(self, x, y, n=4, spacing=2.2):
        """A hedgehog belt across the road nearest model (x, y): two staggered rows square across it (a vehicle
        can't drive through; a man walks through under the guns)."""
        t = self.t
        w = t.to_world(x, y, 0)
        near = t.roads_near(w[0], w[1], 15)
        if not near:
            self.problems.append(f"no road near {x},{y}")
            return []
        seg = near[0][1]
        a, b = t.to_model(seg["beg"]), t.to_model(seg["end"])
        vx, vy = b[0] - a[0], b[1] - a[1]
        k = max(0, min(1, ((x - a[0]) * vx + (y - a[1]) * vy) / (vx * vx + vy * vy or 1)))
        cx, cy = a[0] + k * vx, a[1] + k * vy
        along = vec(heading(vx, vy))
        across = vec(heading(vx, vy) + 90)
        out = []
        for row, sh in ((-1.2, 0.0), (1.2, spacing / 2)):
            for i in range(n):
                o = (i - (n - 1) / 2) * spacing + sh - spacing / 4
                px, py = cx + across[0] * o + along[0] * row, cy + across[1] * o + along[1] * row
                it = self.put("object", HOG, px, py, (heading(vx, vy) + 45) % 360, search=0.75, road_ok=True, note="hedgehog")
                out += [it] if it else []
        return out

    def hogs(self, x, y, across, n=4, spacing=2.2):
        """A hedgehog belt on open ground: two staggered rows along `across` (a vehicle can't drive through)."""
        a, f = vec(across), vec(across + 90)
        out = []
        for row, sh in ((-1.1, 0.0), (1.1, spacing / 2)):
            for i in range(n):
                o = (i - (n - 1) / 2) * spacing + sh - spacing / 4
                it = self.put("object", HOG, x + a[0] * o + f[0] * row, y + a[1] * o + f[1] * row, (across + 45) % 360, search=0.75, road_ok=True, note="hedgehog")
                out += [it] if it else []
        return out

    def tower_man(self, tw, k, role):
        """A man at the tower's k-th standing spot (TOWER_SPOTS)."""
        dx, dy, dz, df = TOWER_SPOTS[k]
        l, f = vec(tw[3] + 90), vec(tw[3])
        return self.add("guard", role, tw[0] + l[0] * dx + f[0] * dy, tw[1] + l[1] * dx + f[1] * dy, (tw[3] + df) % 360, z=tw[2] + dz)

    def tower(self, x, y, face, roles=("mg_gunner", "marksman"), search=1.5):
        """A sandbag watchtower at a corner of the ring, its men on the platform looking out over `face`."""
        for r in [0.0] + [k * 0.25 for k in range(1, int(search * 4) + 1)]:
            n = max(1, int(r * 12))
            for k in range(n):
                a = 2 * math.pi * k / n
                px, py = x + r * math.cos(a), y + r * math.sin(a)
                if self.free("object", TOWER, px, py, face, road_ok=True):
                    self.add("object", TOWER, px, py, face)
                    self.towers.append([px, py, self.t.ground_model(px, py), face, len(roles)])
                    return [self.items[-1]] + [self.tower_man(self.towers[-1], i, r_) for i, r_ in enumerate(roles)]
        self.problems.append(f"no room for the tower at {x:.1f},{y:.1f}: {self.why('object', TOWER, x, y, face, True)}")
        return []

    def bunker(self, x, y, face, role="at", search=1.0):
        """A small sandbag bunker with a guard inside, its slit facing `face`."""
        got = self.group([("object", BUNKER, 0, 0, face), ("guard", role, 0, 0, face)], x, y, search, road_ok=True, note=f"bunker {role}")
        if not got:
            self.problems.append(f"no room for the bunker at {x:.1f},{y:.1f}")
        return got


# ---------------------------------------------------------------- the house's own steps

def tier1(t, d, cfg):
    f0 = t.floors[0]
    d.add("object", "Land_TableDesk_F", 1.9, -5.5, 137, z=f0)
    d.add("object", "Land_OfficeChair_01_F", 3.6, -6.1, 187, z=f0)
    d.add("object", "Land_MapBoard_F", 2.0, -0.1, 52, z=f0)
    d.add("guard", "gendarme", 3.3, -4.5, 236, z=f0)          # At the desk
    d.add("guard", "gendarme", -2.7, -3.4, 270, z=f0)         # On the veranda by the door, looking out
    fx, fy = cfg.get("flag", (-6.5, -2.5))
    d.put("object", "Flag_NATO_F", fx, fy, 180, search=4, flag=True, need=True)


# The house's posts: (x, y, floor index, facing): the upstairs east windows from the plan (t.plan().windows), the
# veranda bags. A post is used only where its view runs 4 m or more. (The balcony was given up in round 2, the
# ground floor's east window in round 3: blind at 1 m.)
HOUSE_POSTS = {
    "win_u_s": (4.4, -5.25, 1, 90), "win_u_m": (4.4, -2.12, 1, 90), "win_u_n": (4.4, 5.5, 1, 90),
    "ver_n": (-2.8, -1.6, 0, 270), "ver_s": (-3.2, -6.8, 0, 270),  # Behind the veranda's bags (ver_s: entry W)
}


def house_view(t, d, key):
    x, y, fl, face = HOUSE_POSTS[key]
    f = vec(face)
    k = 1.2
    while EXTENT[0] <= x + f[0] * k <= EXTENT[2] and EXTENT[1] <= y + f[1] * k <= EXTENT[3]:
        k += 0.25  # From the window or the veranda's edge outward
    return d.sight(x + f[0] * k, y + f[1] * k, face, start=0.0) + k


def house_guard(t, d, cfg, role, prefer):
    """A guard at the first free house post of `prefer` that sees out (4 m or more); else at the town's spare posts
    outside (cfg["spare"]: (x, y, facing) behind short bags). Returns the item or None."""
    used = cfg.setdefault("_used", set())
    if cfg["entry"] not in ("W", "W*"):
        used.add("ver_s")
    for key in prefer:
        if key in used or house_view(t, d, key) < 4.0:
            continue
        used.add(key)
        x, y, fl, face = HOUSE_POSTS[key]
        return d.add("guard", role, x, y, face, z=t.floors[fl])
    spares = cfg.setdefault("spare", [])
    while spares:
        x, y, face = spares.pop(0)
        face = d.aim(x, y, face, face)
        if d.sight(x, y, face, start=0.6) < 4.0:
            continue
        got = d.post(role, x, y, face, search=1.0)
        if got:
            return got[0]
    d.notes.append(f"no house post nor spare for a {role}")
    return None


def tier2(t, d, cfg):
    """Pass 1: sandbags on the house only, so those inside can bunker down; nothing out in the yard."""
    f0 = t.floors[0]
    # The veranda as a porch position: bags inside the pillars on its north bay and across its south end, the bay in
    # front of the door left open (or the south end, entering from S)
    d.add("object", SHORT, -3.85, -3.4, 270, z=f0)
    d.add("object", SHORT, -3.85, -1.6, 270, z=f0)
    if cfg["entry"] == "W":
        d.add("object", LONG, -3.1, -7.15, 180, z=f0)
    else:  # The way in from the south: the bay in front of the door bagged instead
        d.add("object", SHORT, -3.85, -6.0, 270, z=f0)
    # The side door and the ground floor's window (both in the east wall) bagged on the ground against the house:
    # 1.85 m out from the door (round 4: 1.35 m cut into its step), 1.5 m out from the window's frame
    sd = t.door("side")["model"]
    if not d.put("object", cfg.get("side_bags", LONG), sd[0] + 1.85, sd[1], 90, search=0.3, note="side door bags"):
        d.notes.append("the side door opens onto the neighbour (no bags)")
    for wx, wy, wz, wdir, ww in t.plan().windows if cfg.get("window_bags", True) else ():
        if abs(wz - t.plan().levels[0]) < 0.5:
            f = vec(wdir)
            if not d.put("object", SHORT, wx + f[0] * 1.5, wy + f[1] * 1.5, wdir, search=0.3, note="window bags"):
                d.notes.append(f"the window at {wx},{wy} opens onto the neighbour (no bags)")


def tier3_house(t, d, cfg):
    house_guard(t, d, cfg, "marksman", ["win_u_m", "win_u_s", "win_u_n"])
    house_guard(t, d, cfg, "rifleman", ["win_u_s", "win_u_n", "win_u_m", "ver_s"])


def tier4_house(t, d, cfg):
    if cfg["entry"] != "W" and "ver_s" in cfg.get("_used", set()) and not any(it[0] == "guard" and abs(t.to_model(it[2])[0] + 3.2) < 0.1 and abs(t.to_model(it[2])[1] + 6.8) < 0.1 for it in d.items):
        cfg["_used"].discard("ver_s")  # (by the way in from the south: a door guard there at tier 4)
        cfg["entry"] = "W*"
    for role in cfg.get("t4_house", ("mg_gunner",)):
        house_guard(t, d, cfg, role, ["ver_s", "win_u_n", "win_u_m", "win_u_s", "ver_n"])


# ---------------------------------------------------------------- checks

def report(t, d, tiers):
    """The views of the outside guards and the statics' fields of fire, as the in-game check measures them."""
    out = []
    for kind, what, p, o, extra in tiers[-1]:
        if kind not in ("guard", "static"):
            continue
        m = t.to_model(p)
        if kind == "guard" and "ground" not in extra:
            continue  # In the house (house_view) or on a tower
        face = ((o if kind == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) - t.dir) % 360
        need = 15.0 if kind == "static" else 4.0
        v = d.sight(m[0], m[1], face, start=1.2 if kind == "static" else 0.6, static=kind == "static")
        if v < need:
            out.append(f"{what} at {m[0]:.1f},{m[1]:.1f} sees {v} m")
    return out


def fields(t, d, items):
    """The statics' fields of fire: [(role, x, y, facing, metres)]."""
    out = []
    for kind, what, p, o, extra in items:
        if kind == "static":
            m = t.to_model(p)
            face = (math.degrees(math.atan2(o[0][0], o[0][1])) - t.dir) % 360
            out.append((what, round(m[0], 1), round(m[1], 1), round(face), d.sight(m[0], m[1], face, start=1.2, static=True)))
    return out


def leak(t, d, r=43.0, step=0.5, skip=0, keep=()):
    """Whether the compound is closed: a walk on a 0.5 m grid from the house's doors outward (as the game's own check
    walks a man from the door; the side door counts too: he may cross the house) that a man (0.5 m) can make
    through neither the probe's buildings, real walls and rocks nor our run pieces (the gate counts as shut; wire
    and hedgehogs don't), reaching r m out. skip: leave out the first `skip` things placed (the inner ring, to test
    the outer one alone), but for the runs named in `keep` (inner faces the outer ring shares: along a road, where
    there is no room for two lines). Returns the walk from the house to the outside (the leak), or []."""
    bars = [p for p in d.placed[skip:] if p[5] and p[6] not in (WIRE, HOG)]
    bars += [(p["x"], p["y"]) + SIZE[p["cls"]] + (d.runs[n]["out"], True, p["cls"]) for n in keep for p in d.runs[n]["pieces"]]
    n = int(r / step)

    def shut(i, j):
        x, y = i * step, j * step
        if in_house(x, y, 0.2):
            return True
        if d.barrier_hits(x, y, 0.4, 0.4):
            return True
        return any(d.boxes_overlap((x, y, 0.4, 0.4, 0), q[:5], 0) for q in bars)
    cache = {}
    sd = t.door("side")
    sx, sy = sd["model"][0] + vec(sd["mdir"])[0] * 1.2, sd["model"][1] + vec(sd["mdir"])[1] * 1.2
    start = [(round(-3.3 / step), round(-5.0 / step)), (round(sx / step), round(sy / step))]  # The veranda (the main door) and outside the side door
    prev = {}
    q = collections.deque()
    for c in start:
        if c not in prev and not shut(*c):
            prev[c] = None
            q.append(c)
    while q:
        c = q.popleft()
        if c[0] * c[0] + c[1] * c[1] >= n * n:
            path = []
            while c is not None:
                path.append((c[0] * step, c[1] * step))
                c = prev[c]
            return path[::-1]
        for dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb = (c[0] + dc[0], c[1] + dc[1])
            if nb in prev:
                continue
            if nb not in cache:
                cache[nb] = shut(*nb)
            if not cache[nb]:
                prev[nb] = c
                q.append(nb)
    return []


def audit(t, d):
    """Each run: its length, the gap it closes (face to face), how far its pieces overlap the faces and each other,
    and any stretch of its line left open. Returns (lines of text, problems)."""
    out, bad = [], []
    for name, rec in d.runs.items():
        f0, f1 = rec["faces"]
        ps = sorted(rec["pieces"], key=lambda p: p["s0"])
        cover = sum(p["s1"] - p["s0"] for p in ps)
        joints = []
        for a, b in zip(ps, ps[1:]):
            joints.append(round(a["s1"] - b["s0"], 2))
        e0 = round(f0 - ps[0]["s0"], 2) if ps else None
        e1 = round(ps[-1]["s1"] - f1, 2) if ps else None
        names = " + ".join({HB5: "HB5", HB3: "HB3", HB1: "HB1", WALL: "W4", CNC1: "C1", LONG: "bags", SHORT: "bags(short)", BAR: "GATE", PIPEGATE: "GATE(4 m)", WIRE: "wire", HOG: "hog"}.get(p["cls"], p["cls"]) +
                            ("(fire)" if p["kind"] == "fire" else "(slot)" if p["kind"] == "slot" else "") for p in ps)
        ends = "/".join(rec["ends"])
        out.append(f"| {name} | T{rec['tier']} | {f1 - f0:.2f} | {' / '.join(rec.get('ties', ()))} | {len(ps)}: {names} | {cover:.1f} | "
                   f"{e0} / {e1} | {', '.join(f'{j:.2f}' for j in joints)} |")
        is_wire = rec["note"] == "wire belt"
        for k, j in enumerate(joints):
            gate = ps[k]["cls"] in (BAR, PIPEGATE) or ps[k + 1]["cls"] in (BAR, PIPEGATE)
            hog = ps[k]["cls"] == HOG or ps[k + 1]["cls"] == HOG
            if hog:
                continue
            if gate and not -0.36 <= j <= 0.06:
                bad.append(f"{name}: the gate's opening is off by {j:.2f}")
            if not gate and not (JOINT[0] - 0.01 <= j <= JOINT[1] + 0.01):
                bad.append(f"{name}: joint {k + 1} overlaps {j:.2f} m")
        for k, (e, kind, p) in enumerate(((e0, rec["ends"][0], ps[0] if ps else None), (e1, rec["ends"][1], ps[-1] if ps else None))):
            if e is None or (p["cls"] in (BAR, PIPEGATE) and -0.36 <= e <= 0.06):
                continue  # (a gate may stop short of what's beside it by less than a man's width)
            tr = rec["eranges"][k] if "eranges" in rec else TIE
            if kind in ("tie", "fence") and not (tr[0] - 0.01 <= e <= tr[1] + 0.01) and not (is_wire and ps[-1]["cls"] == HOG):
                bad.append(f"{name}: an end overlaps its face by {e:.2f} m")
        # The line sampled every 0.1 m between the faces: covered by its pieces (the gate's opening counts)
        u = rec.get("u")
        if u:
            s, run_open, worst = f0 + 0.05 + (0.45 if rec["ends"][0] == "corner" else 0), 0.0, 0.0
            while s < f1 - 0.05 - (0.45 if rec["ends"][1] == "corner" else 0):
                if not any(p["s0"] - 0.01 <= s <= p["s1"] + 0.01 for p in ps):
                    run_open += 0.1
                    worst = max(worst, run_open)
                else:
                    run_open = 0.0
                s += 0.1
            if worst > 0.4:  # (less is no way through for a man: beside a gate's end)
                bad.append(f"{name}: {worst:.1f} m of its line open")
    return out, bad


def draft(t, cfg):
    """Pass 1 (walls only): T1 empty, T2 sandbags on the house, T3 the closed H-barrier ring, T4 the high-wall
    outer ring round it. Each tier keeps the one before."""
    cfg = dict(cfg)
    d = Drafter(t)
    tiers, leaks = [[]], {}
    d.tier = 2
    tier2(t, d, cfg)
    tiers.append(list(d.items))
    d.tier = 3
    cfg["build"](d, 3)
    leaks["T3"] = leak(t, d)
    tiers.append(list(d.items))
    inner = len(d.placed)
    d.tier = 4
    cfg["build"](d, 4)
    leaks["T4"] = leak(t, d)
    leaks["T4's outer ring alone"] = leak(t, d, skip=inner, keep=cfg.get("shared", ()))
    tiers.append(list(d.items))
    for n, path in leaks.items():
        if path:
            d.problems.append(f"{n} not closed: a way out {[(round(x, 1), round(y, 1)) for x, y in path[::max(1, len(path) // 8)]]}")
    for it in tiers[-1]:
        if it[0] != "object" or not any(m in it[1] for m in ("BagFence", "HBarrier", "Wall")):
            d.problems.append(f"{it[1]}: not a wall, H-barrier or sandbag (pass 1)")
    return tiers, d


# ---------------------------------------------------------------- maps

def cmap(t, items, r=44, step=1):
    """Top-down, model coordinates (up = +y; the veranda and the main door face left/down): O house, # building,
    = real wall, - low wall or fence, t tree, r rock, : road; M high wall, W 2-high, w H-barrier, G bar gate, b bags, T tower, B bunker, h hedgehog,
    z wire, f flag, g guard (outside), S static."""
    marks = {}
    high = {(round(t.to_model(p)[0], 1), round(t.to_model(p)[1], 1)) for kind, what, p, o, extra in items if "drop" in extra and what in FILL}
    for kind, what, p, o, extra in items:
        if "ground" not in extra:
            continue
        m = t.to_model(p)
        c = {"guard": "g", "static": "S"}.get(kind)
        if c is None:
            c = {HB5: "w", HB3: "w", HB1: "w", WALL: "M", CNC1: "M", BAR: "G", HOG: "h", WIRE: "z", BUNKER: "B", TOWER: "T",
                 "Flag_NATO_F": "f"}.get(what, "b" if "Bag" in what else "x")
            if c == "w" and (round(m[0], 1), round(m[1], 1)) in high:
                c = "W"
        if kind == "object":
            ln, dp = size_of(kind, what)
            yaw = math.degrees(math.atan2(o[0][0], o[0][1])) - t.dir
            a, f = vec(yaw + 90), vec(yaw)
            for s in [k * 0.5 for k in range(-int(ln), int(ln) + 1)]:
                if abs(s) > ln / 2:
                    continue
                for q in [k * 0.5 for k in range(-int(dp), int(dp) + 1)]:
                    if abs(q) > dp / 2:
                        continue
                    key = (round((m[0] + a[0] * s + f[0] * q) / step), round((m[1] + a[1] * s + f[1] * q) / step))
                    if marks.get(key) not in ("g", "S"):
                        marks[key] = c
        marks[(round(m[0] / step), round(m[1] / step))] = c
    rows = []
    for j in range(r // step, -r // step - 1, -1):
        row = f"{j * step:4d} "
        for i in range(-r // step, r // step + 1):
            x, y = i * step, j * step
            w = t.to_world(x, y, 0)
            c = "."
            if t.on_road(w[0], w[1]):
                c = ":"
            hit = t.hits(w[0], w[1], step * 0.9, step * 0.9, t.dir, 0)
            if hit:
                c = {"building": "#", "wall": "=" if real_wall(hit[0][1]) else "-", "tree": "t", "rock": "r", "part": "O"}.get(hit[0][0], "?")
            if in_house(x, y):
                c = "O"
            c = marks.get((i, j), c)
            row += c
        rows.append(row)
    rows.append("     " + "".join(("|" if i % 10 == 0 else " ") for i in range(-r // step, r // step + 1)) + f"  (| every 10 m, x from -{r})")
    return "\n".join(rows)


# ---------------------------------------------------------------- the towns

SITES = {}


def site(name, **cfg):
    def deco(fn):
        cfg["build"] = fn
        SITES[name] = cfg
        return fn
    return deco


# Model coordinates throughout: x right, y towards the back (the front, -y, is down on the maps); the veranda and the
# main door face -x (left).


@site("Molos", entry="W", nest=(11.3, 9.3, 0), flag=(-5.8, 5.0), spare=[])
def molos(d, tier):
    # A track runs north-south 6 m west of the veranda and a big road east-west 14 m north; a shop abuts the
    # house's front (south); old city walls run east from it to the chapel's corner. The ring: the west face along
    # the track from the shop, the north face along the big road, the east face down the yard to the city wall.
    # The way in: off the west track onto the veranda.
    if tier == 3:
        d.run("west", (-7.5, -8.5), (-7.5, 14.6), ends=("tie", "corner"))
        d.run("north", (-7.5, 14.6), (18.0, 11.5), ends=("tie", "corner"))
        d.run("east", (18.0, 11.5), (18.0, -12.0))
    if tier == 4:  # The outer ring: west of the track and north of the north track, closed on the east by the big
        # houses, the chapel and the old city walls (runs into the gaps between them); both tracks run between the rings
        W = WALL_FILL
        d.run("o_n", (6.6, 23.0), (-20.4, 23.0), ends=("tie", "corner"), fill=W)
        d.run("o_w", (-20.4, 23.0), (-20.4, -19.5), ends=("tie", "corner"), fill=W)
        d.run("o_s", (-20.4, -19.5), (-3.3, -19.5), ends=("tie", "tie"), fill=W)
        d.run("o_se", (24.0, -21.0), (24.0, -15.5), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_e", (38.5, -19.5), (38.5, -10.5), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_ne", (24.3, 19.5), (24.3, 8.0), ends=("tie", "tie"), fill=W, out=90)


@site("Agios Dionysios", entry="W", nest=(-8.5, -4.6, 270), flag=(3.0, -10.5), spare=[])
def agios_dionysios(d, tier):
    # No road within 60 m: open ground south and east, a big house north-west, a tin fence running west from the
    # veranda's north end and another north from the house's north-east corner. The ring: four faces on the open
    # ground, the west and north faces tied into the two tin fences where they cross them. The way in: from the
    # west, square onto the veranda's door bay, the nest covering the gate from inside.
    if tier == 3:
        d.run("west_s", (-13.0, -16.0), (-13.0, 0.0), ends=("corner", "fence"), fill=(HB3, HB3, HB1))  # (3.6 m pieces at the fence: their middles stay clear of it)
        d.run("south", (-13.0, -16.0), (14.0, -16.0), ends=("tie", "corner"))
        d.run("east", (14.0, -16.0), (14.0, 12.0), ends=("tie", "corner"))
        d.run("north_e", (14.0, 12.0), (4.0, 12.0), ends=("tie", "fence"))
        d.run("north_w", (6.0, 12.0), (-13.0, 12.0), ends=("fence", "corner"))
        d.run("west_n", (-13.0, 12.0), (-13.0, -3.0), ends=("tie", "fence"))
    if tier == 4:  # The outer ring: 6-8 m out on the open ground, its west and north faces tied into the big shed's
        # south-east and north-east faces (each met at about 53 degrees), the north face through the tin fence. The
        # south face stays north of the unfinished building's tip.
        W = WALL_FILL
        d.run("o_w", (-20.0, -19.5), (-20.0, 12.0), ends=("corner", "tie"), fill=W)
        d.run("o_s", (-20.0, -19.5), (24.0, -19.5), ends=("tie", "corner"), fill=W)
        d.run("o_e", (24.0, -19.5), (24.0, 23.0), ends=("tie", "corner"), fill=W)
        d.run("o_ne", (24.0, 23.0), (5.0, 23.0), ends=("tie", "fence"), fill=W)
        d.run("o_nw", (5.0, 23.0), (-9.0, 23.0), ends=("fence", "tie"), fill=W)



@site("Chalkeia", entry="W", nest=(-11.0, -2.0, 0), nest_road=True, flag=(-10.0, -9.0), spare=[])
def chalkeia(d, tier):
    # A dead-end track runs down from the north just west of the veranda and stops at a shop and a garage south-
    # west; an annexe abuts the house's north side and a ruin closes the north-east; a house abuts the east side's
    # southern half, an old stone wall runs on north of it; open ground lies south and west. The ring takes in the
    # dead end of the track: the north face across the track from the annexe, the west face down the open ground
    # to the shop, the south face from the shop across the open ground to the old wall south of the east house (a
    # short run closing the gap between them), and a run across the east yard from the ruin to the stone wall. The
    # guns look up the track (the long field). The way in: from the open ground west, through the west gate.
    if tier == 3:  # (pass 1: off the low stone walls; the east yard closed against the annexe, not the ruin)
        d.run("west", (-17.0, -13.0), (-17.0, 12.0), ends=("tie", "corner"))
        d.run("north", (-17.0, 12.0), (-2.0, 12.0), ends=("tie", "tie"))
        d.run("south", (-14.0, -19.3), (3.2, -19.3), ends=("tie", "corner"))
        d.run("se", (3.2, -19.3), (3.2, -7.8), ends=("tie", "tie"))
        d.run("e1", (9.0, -1.0), (9.0, 9.5), ends=("tie", "corner"))
        d.run("e2", (9.0, 9.5), (5.5, 9.5), ends=("tie", "tie"))
    if tier == 4:  # The outer ring: the shops and garage west and south-west, the big house north-west, the shop, the
        # ruin and the two big rocks north-east and east; runs close the gaps between them (each tie met at 55 degrees
        # or more); the south face steps round the low stone wall's end onto the south annexe
        W = WALL_FILL
        d.run("o_w", (-24.0, -5.0), (-24.0, 15.5), ends=("tie", "tie"), fill=W, out=270)
        d.run("o_n", (-24.0, 24.0), (-5.0, 24.0), ends=("tie", "corner"), fill=W, out=0)
        d.run("o_ne", (-5.0, 24.0), (-5.0, 29.5), ends=("tie", "tie"), fill=W, out=270)
        d.run("o_e", (18.0, 10.0), (18.0, -3.5), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_s_w", (-18.4, -28.0), (3.5, -28.0), ends=("tie", "corner"), fill=W, out=180)
        d.run("o_s_m", (3.5, -28.0), (3.5, -30.4), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_s_e", (6.1, -32.0), (18.5, -32.0), ends=("tie", "corner"), fill=W, out=180)
        d.run("o_se", (18.5, -32.0), (18.5, -20.5), ends=("tie", "tie"), fill=W, out=90)


@site("Charkia", entry="W", nest=(-9.0, -4.4, 270), flag=(-6.5, 1.5), spare=[], window_bags=False, side_bags=SHORT)
def charkia(d, tier):
    # Between tracks (north-west, west and south-east); a long garage close north-west, its corner at the house's
    # north-west corner; an old walled garden north-east of the house (stone walls from the house's south-east
    # corner round to a wire fence ending north of the house). Open ground west and south. The ring: the garden's
    # own walls are its east half; a north run from the garage to the garden fence; the west face from the garage
    # down the open ground, the south face, and a run from its corner into the garden wall at the house's south-
    # east corner. The way in: from the west, square onto the door bay; the garage closes the chicane's north side.
    if tier == 3:  # (pass 1: the garden's walls are low stone walls and wire fences: the north face stops short of the
        # garden's wire fence and turns into the house; a box against the house's east wall holds the side door)
        d.run("west", (-12.5, -14.5), (-12.5, 6.0), ends=("corner", "tie"))
        d.run("south", (-12.5, -14.5), (0.0, -14.5), ends=("tie", "corner"))
        d.run("se", (0.0, -14.5), (0.0, -7.8), ends=("tie", "tie"))
        d.run("north", (-5.0, 11.6), (2.0, 11.6), ends=("tie", "corner"))
        d.run("n_down", (2.0, 11.6), (2.0, 7.8), ends=("tie", "tie"))
        d.run("e_top", (8.3, 7.4), (5.6, 7.4), ends=("corner", "tie"))
        d.run("e_n", (8.3, 7.4), (8.3, -1.0), ends=("tie", "corner"))
        d.run("e_w", (8.3, -1.0), (5.6, -1.0), ends=("tie", "tie"))
    if tier == 4:  # The outer ring: on the open ground and across the tracks west, south and north (the garage inside
        # it, the west face threading between the garage and the west house's corner and the wire fence's end), and
        # inside the walled garden east: the garden's low walls are lined, the wall along its south-west side
        # running into the house's east wall below the window. The north face crosses the garden's west wire fence
        # square (fence ties). The ground-floor window is left without bags (the wall stands in front of it).
        W = WALL_FILL
        d.run("o_s", (-23.6, -22.5), (5.0, -22.5), ends=("corner", "corner"), fill=W, out=180)
        d.run("o_h", (5.0, -22.5), (5.0, -7.8), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_w", (-26.4, 15.5), (-23.6, -22.5), ends=("corner", "tie"), fill=W, out=270)
        d.run("o_n_w", (-26.4, 15.5), (1.3, 15.5), ends=("tie", "fence"), fill=W, out=0)
        d.run("o_n_e", (1.3, 15.5), (13.0, 15.5), ends=("fence", "corner"), fill=W, out=0)
        d.run("o_e", (13.0, 15.5), (13.0, -1.75), ends=("tie", "corner"), fill=W, out=90)
        d.run("o_g", (13.0, -1.75), (4.86, -6.32), ends=("tie", "tie"), fill=W, out=150)


@site("Kalochori", entry="W", nest=(-7.0, 0.2, 180), nest_road=True, flag=(6.3, -5.0), spare=[])
def kalochori(d, tier):
    # The main road runs 7 m south of the house's walled front yard (old concrete walls round it, no gateway); a
    # lane runs north-south west of the house between it and an old stone wall, from the road up to a narrow gap
    # between two houses north; a walled yard east (stone walls round it) opens south onto the road; houses and a
    # shed close the north. The ring is mostly the old walls: the lane's mouth on the road gets the gate (a 4 m
    # gate: the lane is 4.5 m wide), the lane's north end is closed with sandbags (the AT gun fires up the north
    # lane over them), the gaps either side of the north shed and the east yard's south side with H-barrier runs.
    # The way in: from the road up the lane onto the veranda, the nest looking down the lane at the gate; at tier 4
    # two baffles in the lane make it the chicane.
    if tier == 3:  # (pass 1: the yard's and the lane's walls are low: a tight ring of its own round the house and the
        # front yard, crossing the yard's two side walls square; west in the lane, east across the east yard, north
        # against the house north of the house)
        d.run("west", (-6.0, -13.7), (-6.0, 7.0), ends=("corner", "tie"))
        d.run("s_w", (-6.0, -13.7), (-4.25, -13.7), ends=("tie", "fence"))
        d.run("s_m", (-4.25, -13.7), (4.5, -13.7), ends=("fence", "fence"))
        d.run("s_e", (4.5, -13.7), (8.0, -13.7), ends=("fence", "corner"))
        d.run("east", (8.0, -13.7), (8.0, 10.5), ends=("tie", "corner"))
        d.run("north_e", (8.0, 10.5), (3.5, 10.5), ends=("tie", "tie"))
    if tier == 4:  # The outer ring: up the lane (across its north end from the big stone house to the north house),
        # along the main road's verge, up the east yard to the north shed, and from the north house square into the
        # shed's south-west face (the 0.9 m gap between them)
        W = WALL_FILL
        d.run("o_lane", (-10.5, 9.0), (-5.0, 10.27), ends=("tie", "tie"), fill=W, out=0)  # (13 degrees off square: a 4 m wall and a 1 m section fit)
        d.run("o_s", (-8.3, -16.4), (11.5, -16.4), ends=("corner", "corner"), fill=W, out=180)
        d.run("o_w", (-8.3, -16.4), (-8.3, 9.5), ends=("tie", "tie"), fill=W, out=270)
        d.run("o_e", (11.5, -16.4), (11.5, 12.8), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_n", (3.5, 14.8), (5.37, 17.38), ends=("tie", "tie"), fill=W, out=315)


@site("Neochori", entry="W", nest=(3.8, -11.5, 180), flag=(4.0, -8.8), spare=[], shared=("west",))
def neochori(d, tier):
    # The main road runs north-south right along the veranda (no room for a gate box on it); a big garage and a
    # house fill the east; a small house closes the south yard's south side, an old city wall runs north from it
    # beside the road; old concrete garden walls run east-west 16 m north, leaving a small plaza off the road north-
    # west of the house. The ring: the west face along the road from the south house to the plaza, the north face to
    # the garage, a run from the south house to the garage's corner across the south-east gap. The way in: off the
    # road onto the plaza, through the north gate; at tier 4 a wall across the plaza makes it a dogleg passage.
    # The guns fire south-east through the gap between the south house and the garage, and up the road north.
    if tier == 3:
        d.run("west", (-6.2, -24.0), (-6.2, 14.0), ends=("tie", "corner"))
        d.run("north", (-6.2, 14.0), (13.5, 14.0), ends=("tie", "corner"))
        d.run("ne", (13.5, 14.0), (13.5, 6.0), ends=("tie", "tie"))
        d.run("se", (6.0, -23.5), (12.8, -7.0), ends=("tie", "tie"))
    if tier == 4:  # The outer ring: the main road leaves no room west, so the inner ring's west face is the outer line
        # there too (stacked 2-high); from its north end a wall runs up the plaza's diagonal garden wall (lined, 1 m
        # off it) into the north shop; the shops, the big house and the garage east, the annexe and the big house
        # south-east and the small house south close the rest, with runs across the gaps between them (the one from
        # the shop to the big house through a gap in the low garden wall)
        W = WALL_FILL
        d.stack("west")
        d.run("o_nw", (-5.8, 14.05), (4.37, 27.1), ends=("tie", "tie"), fill=W, out=322)
        d.run("o_ne", (22.0, 18.5), (22.0, 11.0), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_e", (26.0, -4.9), (26.0, -14.9), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_s", (7.8, -28.0), (24.2, -28.0), ends=("tie", "tie"), fill=W, out=180)



@site("Panochori", entry="W", nest=(6.5, -11.2, 90), flag=(8.5, -4.0), spare=[])
def panochori(d, tier):
    # A track runs north-south right along the veranda; a house abuts the north side, a big house stands south-
    # west; old stone walls close a yard east of the house and south of it, open only at its south-east corner
    # and at the north end of the east yard. The ring: the west face along the track between the two houses (the
    # gate on the door bay, its chicane on the track), a short run into the north house, and runs closing the
    # east yard's north end and the south-east corner. The guns fire east out of the south-east corner and north
    # out of the east yard's north end.
    if tier == 3:  # (pass 1: the east yard's walls are low stone walls: the yard is lined inside them; the south face
        # runs into the big south-west house's north-east face)
        d.run("south", (10.6, -12.5), (-7.0, -12.5), ends=("corner", "tie"))
        d.run("west", (-6.2, -12.5), (-6.2, 10.0), ends=("tie", "corner"))
        d.run("nw", (-6.2, 10.0), (-1.0, 10.0), ends=("tie", "tie"))  # (1.3 m off the house: round 4 measured 1-high pieces 0.35 m off it cutting in)
        d.run("ne", (6.7, 10.5), (10.6, 10.5), ends=("tie", "corner"))
        d.run("east", (10.6, 10.5), (10.6, -12.5), ends=("tie", "tie"))
    if tier == 4:  # The outer ring: west across the track (into the big south-west house's north face), north along
        # the north house, east from it through the gap in the yard's low wall (between its two stone walls) to the
        # big north-east house; the annexe and the big east house, then south from its corner (between the ends of
        # two low stone walls) to the big south houses, and a run between the south annexe and the big south-west
        # house
        W = WALL_FILL
        d.run("o_w", (-14.0, -11.1), (-14.0, 20.0), ends=("tie", "corner"), fill=W, out=270)
        d.run("o_n", (-14.0, 20.0), (-2.6, 20.0), ends=("tie", "tie"), fill=W, out=0)
        d.run("o_ne", (6.7, 17.1), (21.8, 17.1), ends=("tie", "tie"), fill=W, out=0)
        d.run("o_e", (21.8, -4.6), (19.95, -25.75), ends=("tie", "tie"), fill=W, out=90)  # (slanted 5 degrees: between the two pillars)
        d.run("o_s", (-4.3, -18.0), (3.2, -18.0), ends=("tie", "tie"), fill=W, out=180)


@site("Paros", entry="W", nest=(0.5, -10.0, 260), flag=(-7.0, 11.0), spare=[])
def paros(d, tier):
    # A track runs north-south 7 m west of the veranda; houses abut the east side and close the south; a big house
    # closes the north beyond a yard that opens east; an old city wall runs from the house's north-west corner to
    # the big house. The ring: the west face along the track (the gate on the door bay, its chicane on the track),
    # a short run from its corner into the south house, one from its north corner into the city wall, and one
    # closing the north yard's open east side between the east house and the big house. Towers at the north yard's
    # two corners.
    if tier == 3:  # (pass 1: the broken city wall north-west of the house is low: the west face runs on up into the
        # big north house; the south-west run goes into the south house's west face, not alongside it)
        d.run("west", (-9.5, -13.0), (-9.5, 16.5), ends=("corner", "tie"))
        d.run("sw", (-9.5, -13.0), (-5.5, -13.0), ends=("tie", "tie"))
        d.run("ne", (12.5, 4.5), (12.5, 18.5), ends=("tie", "tie"))
    if tier == 4:  # The outer ring: west of the track (clear of the main road south-west), into the big north house
        # and the south house; north and east the big houses, the shed, the garage, the old city walls and the shops
        # close it, with a wall in the one gap in the old city wall east
        W = WALL_FILL
        d.run("o_s", (-18.0, -15.8), (-6.35, -15.8), ends=("corner", "tie"), fill=W, out=180)
        d.run("o_w", (-18.0, -15.8), (-18.0, 18.0), ends=("tie", "corner"), fill=W, out=270)
        d.run("o_n", (-18.0, 18.0), (-11.1, 18.0), ends=("tie", "tie"), fill=W, out=0)
        d.run("o_e", (36.9, 4.6), (38.15, 8.6), ends=("tie", "tie"), fill=W, out=17)


@site("Rodopoli", entry="W", nest=(-9.0, -1.8, 270), flag=(-9.0, 8.0), spare=[])
def rodopoli(d, tier):
    # An annexe abuts the house's north side and houses its south side; a big yard west of the house is walled in
    # by old city walls (west and north) and a big house (south-west), open only at a 3 m gap in its south wall and
    # at its north-east corner, where it runs into a lane behind the house; the lane runs north-south between the
    # house and a long concrete wall along the east track, open at both ends. The ring is the old walls: the south
    # gap, the lane's south end (the gate, onto the south track) and its north end are closed. The way in is long:
    # through the gate, up the lane (at tier 4 two baffles make it a chicane), round the annexe into the yard and
    # onto the veranda.
    if tier == 3:  # (pass 1: the wall along the east track is a low concrete wall: the lane is closed by a run up its
        # middle (west of its tree planters), tied into runs across the lane's two ends)
        d.run("south_gap", (-15.5, -17.0), (-8.5, -17.0), ends=("tie", "tie"), out=180)
        d.run("north_gap", (-15.0, 27.0), (-7.5, 27.0), ends=("tie", "tie"), out=0)
        d.run("lane_s", (4.5, -13.0), (9.3, -13.0), ends=("tie", "corner"), out=180)
        d.run("lane_n", (4.5, 26.2), (9.3, 26.2), ends=("tie", "corner"), out=0)
        d.run("east", (9.3, -13.0), (9.3, 26.2), ends=("tie", "tie"), out=90)
    if tier == 4:  # The outer ring: west of the walled yard (the big west houses and the garage, a wall across the gap
        # between them), along the north track's verge and down the east track's verge, back across the low concrete
        # wall (square) into the south house, and from the south annexe across to the big west house
        W = WALL_FILL
        d.run("o_w", (-28.5, -0.6), (-28.5, 10.1), ends=("tie", "tie"), fill=W, out=270)
        d.run("o_n", (19.2, 31.0), (-26.0, 31.0), ends=("corner", "corner"), fill=W, out=0)
        d.run("o_nw", (-26.0, 31.0), (-26.0, 28.2), ends=("tie", "tie"), fill=W, out=270)
        d.run("o_e", (19.2, 31.0), (19.2, -17.5), ends=("tie", "corner"), fill=W, out=90)
        d.run("o_s_e", (15.35, -17.5), (19.2, -17.5), ends=("fence", "tie"), fill=W, out=180)
        d.run("o_s_w", (5.8, -17.5), (15.35, -17.5), ends=("tie", "fence"), fill=W, out=180)
        d.run("o_sw", (-20.2, -22.0), (-10.5, -22.0), ends=("tie", "tie"), fill=W, out=180)


@site("Sofia", entry="S", nest=(-6.2, 3.0, 270), flag=(9.0, 6.8), spare=[], shared=("west",))
def sofia(d, tier):
    # On a corner: the main road runs north-south 9 m west of the house and a track east-west 11 m south of it; a
    # big house abuts the north side, another the east side's southern half; a yard east of the house is closed
    # by houses all round but for a 2 m gap at its south-east corner. The house fills its corner of the block, so
    # the ring hugs it on the road sides: the west face along the main road from the north house, the south face
    # along the track (the gate in it, its chicane on the track), a short run into the east house and one closing
    # the east yard's gap. One tower, in the east yard (no room for a second without closing the road or track).
    if tier == 3:
        d.run("west", (-8.6, 9.0), (-8.6, -11.5), ends=("tie", "corner"))
        d.run("south", (-8.6, -11.5), (5.5, -11.5), ends=("tie", "corner"))
        d.run("se", (5.5, -11.5), (5.5, -7.5), ends=("tie", "tie"))
        d.run("east_gap", (18.5, -1.5), (18.5, 4.5), ends=("tie", "tie"), out=90)
    if tier == 4:  # The outer ring: the main road leaves no room west, so the inner ring's west face is the outer line
        # there too (stacked 2-high) and runs on south along the verge; south across the track, east up to the east
        # annexe; the big houses north and east close the rest
        W = WALL_FILL
        d.stack("west")
        d.run("o_w", (-8.6, -12.4), (-8.6, -20.0), ends=("tie", "corner"), fill=W, out=270)
        d.run("o_s", (-8.6, -20.0), (30.0, -20.0), ends=("tie", "corner"), fill=W, out=180)
        d.run("o_e", (30.0, -20.0), (30.0, 9.0), ends=("tie", "tie"), fill=W, out=90)


@site("Therisa", entry="S", nest=(1.6, -10.5, 180), flag=(-1.0, 9.5), spare=[])
def therisa(d, tier):
    # No road within 25 m: annexes abut the house's west and east sides (a 2.7 m passage between the west one and
    # the veranda, leading to a walled garden north-west), houses close the north beyond a yard that opens east; a
    # shop and an annexe stand south-west, old city walls run south-east; open ground (a plaza) lies south, the road
    # 30 m beyond it. The ring: the south face across the plaza from the south-west annexe to a short run into the
    # city wall, and a run closing the north yard's east side. Towers at the south face's corners; the gate on the
    # veranda's south end, its chicane out on the plaza.
    if tier == 3:  # (pass 1: the old city wall south-east of the house is broken in its middle (a low ruin): the south
        # face turns up into its whole first stretch instead)
        d.run("south", (-17.0, -16.0), (15.6, -16.0), ends=("tie", "corner"))
        d.run("se", (15.6, -16.0), (15.6, -6.0), ends=("tie", "tie"))
        d.run("sw", (-14.6, -11.5), (-14.6, -17.5), ends=("tie", "tie"), out=270)
        d.run("nw_gap", (-19.0, 19.3), (-11.0, 19.3), ends=("tie", "tie"), out=0)
        d.run("n_e", (15.5, 0.0), (15.5, 13.0), ends=("tie", "tie"), out=90)
    if tier == 4:  # The outer ring: south across the plaza (between the south-west annexe and the big south-east house,
        # clear of the road), up the east between the annexe and the big north-east house, along the north track's
        # verge to the old north-west city walls (a wall across their one gap), and on the west the shops and the
        # kiosk (a wall between them)
        W = WALL_FILL
        d.run("o_s", (-15.4, -24.0), (18.6, -24.0), ends=("tie", "tie"), fill=W, out=180)
        d.run("o_e", (30.0, -11.0), (30.0, 10.4), ends=("tie", "tie"), fill=W, out=90)
        d.run("o_n", (23.05, 23.5), (-22.0, 23.5), ends=("tie", "corner"), fill=W, out=0)
        d.run("o_nw", (-22.0, 23.5), (-22.0, 18.7), ends=("tie", "tie"), fill=W, out=270)
        d.run("o_n1", (-28.2, 18.35), (-24.6, 18.45), ends=("tie", "tie"), fill=W, out=0)
        d.run("o_w", (-27.0, -16.4), (-27.0, -9.95), ends=("tie", "tie"), fill=W, out=270)


def counts(tiers):
    return " / ".join(f"T{i}: {len(it)} things, {sum(1 for x in it if x[0] == 'guard')} g, {sum(1 for x in it if x[0] == 'static')} s"
                      for i, it in enumerate(tiers, 1))


def main(args):
    maps = "-m" in args
    show_audit = "-a" in args
    tier = None
    if "-t" in args:
        tier = int(args[args.index("-t") + 1])
        args = args[:args.index("-t")] + args[args.index("-t") + 2:]
    names = [a for a in args if a not in ("-m", "-a")] or TOWNS
    towns = tl.load()
    bad = 0
    for name in names:
        t = towns[name]
        tiers, d = draft(t, dict(SITES[name]))
        lines, abad = audit(t, d)
        problems = tl.check(t, tiers) + d.problems + abad
        print(f"{name}: {counts(tiers)}")
        for n in d.notes:
            print("   ", n)
        for f in fields(t, d, tiers[-1]):
            print(f"    field of fire: {f[0]} at {f[1]},{f[2]} facing {f[3]}: {f[4]} m")
        if show_audit:
            print("| run | tier | gap (face to face) | ends tie into | pieces | pieces' length | end overlaps | joints |")
            print("|---|---|---|---|---|---|---|---|")
            for ln in lines:
                print(ln)
        if maps:
            print(cmap(t, tiers[(tier or len(tiers)) - 1]))
        if problems:
            bad += 1
            for p in problems:
                print(f"  PROBLEM {p}")
            continue
        tl.write(t, tiers)
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
