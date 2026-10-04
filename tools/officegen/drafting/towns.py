"""
Drafts the mayor's office layouts of drafting group "towns" (tools/officegen/townlib.py has the API): eleven towns
of 4 tiers, all with Land_i_House_Big_01 as the office. Run from the repository root:
    python tools/officegen/drafting/towns.py [town ...] [-m] [-t N]   (all without names; -m maps; -t the tier to map)

The building (model coordinates, front = -y): the house proper is x -1.8..5.1, y -7.4..7.5, plus a north-west room
out to x -4.5; a covered veranda fills the south-west corner (x -4.5..-1.8, y -7.4..0.5), raised 0.6 m, open to
the west between pillars and to the south. The main door (-1.8, -6.1) opens west onto the veranda, the side door
(5.1, 5.6) east. Upstairs covers the whole plan, with a balcony over the veranda.

The tier ladder (the same steps in every town; the outside parts are fitted to each site):
  T1  police presence: the office furniture in the front room, the flag, a gendarme at the desk and one on the
      veranda by the main door.
  T2  the doors held: the veranda sandbagged into a porch position (its north bay and south end bagged, the bay in
      front of the door left as the way in), a C-shaped sandbag nest on the ground covering the approach to the
      veranda, the side door gated, riflemen at the balcony rail and a window. 6 guards.
  T3  a defended compound: 2-high H-barrier walls (wall pieces, or 1-high blocks with a second dropped on top) close
      the open sides facing the streets, the gate square on the way to the veranda with riflemen behind 1-high
      firing steps at its flanks, an HMG in a low bagged slot of the wall down the main street, a marksman and
      riflemen at the windows. ~12 guards.
  T4  a fort: the perimeter closed all round (the neighbouring buildings close the rest), a sandbag watchtower with
      two or three men on it over the main approach, a bunker at another corner, a concrete chicane in front of the
      gate, hedgehogs across the approach roads and razor wire belts in front of the walls, a GMG and an AT gun on
      the ground (3 statics), an MG gunner on the balcony. ~20 guards.
House posts (HOUSE_POSTS: the east windows from the plan, the balcony rail, the veranda bags) are used only where the
view from them runs 4 m or more (Drafter.sight); where the house has too few, the town's spare posts outside take
the men, then the tower. Statics stand on level ground (0.35 m over their footprint) and are aimed (Drafter.aim)
within 40 degrees of their approach for the longest field of fire. A guard who looks out through a wall gets
1-high pieces in front of him (Drafter.watched). The run prints VIEW for any man or gun that would see less than
4 m / 15 m.
Every perimeter line is unbroken: its pieces overlap 0.3 m and reach 0.5 m into the buildings and features at its
ends (a piece whose middle would stand in a building is left out: the building closes the line there), what's left
open is plugged with 1-high blocks, and the run prints any stretch still open ("GAPS"; there are none now).
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

TOWNS = ["Agios Dionysios", "Chalkeia", "Charkia", "Kalochori", "Molos", "Neochori", "Panochori", "Paros",
         "Rodopoli", "Sofia", "Therisa"]

EXTENT = (-4.7, -7.8, 5.6, 7.8)  # The house's real walls, veranda and steps (the probed box runs past them)
DOOR = (-1.8, -6.1)               # The main door, onto the veranda
VERANDA_GATE = {"W": (-4.6, -6.15), "S": (-3.1, -7.6)}  # Where the way in reaches the veranda from each side

WALL6, WALL4, HB3, HB1 = "Land_HBarrierWall6_F", "Land_HBarrierWall4_F", "Land_HBarrier_3_F", "Land_HBarrier_1_F"
BAR = "Land_BarGate_F"
LONG, SHORT, ROUND = "Land_BagFence_Long_F", "Land_BagFence_Short_F", "Land_BagFence_Round_F"
BUNKER = "Land_BagBunker_Small_F"
HOG, WIRE, CNC = "Land_CzechHedgehog_01_F", "Land_Razorwire_F", "Land_CncBarrierMedium_F"


def vec(mdir):
    return (math.sin(math.radians(mdir)), math.cos(math.radians(mdir)))


def heading(dx, dy):
    return math.degrees(math.atan2(dx, dy)) % 360


# The real lengths from the in-game check (townlib.MEASURED, less its slack), where they differ from townlib.CLASSES
SIZE = {WALL6: (8.0, 2.0), WALL4: (5.4, 2.0), HB1: (1.4, 1.6), LONG: (3.0, 0.5), SHORT: (1.8, 0.5), ROUND: (2.6, 1.0),
        WIRE: (8.0, 1.0), BAR: (6.0, 0.6), HOG: (1.8, 1.8), "Land_BagBunker_Tower_F": (3.6, 3.6)}
TOWER = "Land_BagBunker_Tower_F"
STACK = {HB3: 1.7, HB1: 1.6}  # Where a second H-barrier is dropped to stand on the first (townlib.MEASURED heights)
TOWER_DECK = 2.7  # The tower's platform above the ground (a guess for the in-game check)


def size_of(kind, what):
    if kind == "object":
        return SIZE.get(what) or tl.CLASSES.get(what, (0.6, 0.6))
    return (2.0, 2.0) if kind == "static" else (0.6, 0.6)


class Drafter:
    def __init__(self, t):
        self.t = t
        self.placed = []  # (x, y, length, depth, mdir, barrier) of the ground things so far
        self.notes = []
        self.items = []   # The current tier's full snapshot
        self.lines = []   # The perimeter lines drawn (for the gap report)
        self.towers = []  # [x, y, deck z, facing, men] of the towers placed
        self.stacked = [] # (x, y, length, depth, mdir, True) of the second blocks dropped on top (2-high for sight)

    # ---- room
    def free(self, kind, what, x, y, mdir, road_ok=False, pad=0.15, gap=0.05):
        t = self.t
        if math.hypot(x, y) > 44.5:
            return False
        ln, dp = size_of(kind, what)
        bar = kind == "object" and tl.is_barrier(what)
        if bar:  # Barriers: their middle (as townlib.check measures it, on its own sizes where they're bigger)
            cl, cd = tl.CLASSES.get(what, (ln, dp))
            tln, tdp = max(max(ln, cl) - 2 * tl.BARRIER_OVERLAP, 0.2), max(max(dp, cd) * 0.5, 0.2)
        else:
            tln, tdp = ln, dp
        w = t.to_world(x, y, 0)
        for h in t.hits(w[0], w[1], tln, tdp, (t.dir + mdir) % 360, pad):
            if h[0] in ("building", "part", "rock") or (h[0] == "tree" and not bar) or (h[0] == "wall" and kind != "object"):
                return False
        if t.on_office(x, y, tln, tdp, mdir):
            return False
        if self.overlaps(EXTENT, x, y, tln, tdp, mdir, 0.1 if bar else 0.3):
            return False
        if not road_ok and self.road(x, y, ln, mdir):
            return False
        if kind == "static" or what in (BUNKER, TOWER):  # Level ground (a static on a slope's edge floats)
            hs = [t.ground_model(cx, cy) for cx, cy in self.corners(x, y, ln * 0.8, dp * 0.8, mdir) + [(x, y)]]
            if max(hs) - min(hs) > (0.35 if kind == "static" else 0.6):
                return False
        for px, py, pl, pd, pm, pb in self.placed:
            if bar and pb:
                continue  # Barrier pieces may overlap each other (an unbroken line)
            if self.boxes_overlap((x, y, ln, dp, mdir), (px, py, pl, pd, pm), gap):
                return False
        return True

    def why(self, kind, what, x, y, mdir, road_ok=False):
        """What blocks a footprint (for tuning)."""
        t = self.t
        ln, dp = size_of(kind, what)
        w = t.to_world(x, y, 0)
        out = [h[:2] for h in t.hits(w[0], w[1], ln, dp, (t.dir + mdir) % 360, 0.15) if h[0] != "wall" or kind != "object"]
        if t.on_office(x, y, ln, dp, mdir) or self.overlaps(EXTENT, x, y, ln, dp, mdir, 0.3):
            out.append("office")
        if not road_ok and self.road(x, y, ln, mdir):
            out.append("road")
        if kind == "static" or what in (BUNKER, TOWER):
            hs = [t.ground_model(cx, cy) for cx, cy in self.corners(x, y, ln * 0.8, dp * 0.8, mdir) + [(x, y)]]
            if max(hs) - min(hs) > 0.35:
                out.append(f"slope {max(hs) - min(hs):.2f}")
        out += [("placed", round(px, 1), round(py, 1)) for px, py, pl, pd, pm, pb in self.placed if self.boxes_overlap((x, y, ln, dp, mdir), (px, py, pl, pd, pm), 0.05)]
        return out

    @staticmethod
    def corners(x, y, ln, dp, mdir):
        a, b = vec(mdir + 90), vec(mdir)
        return [(x + a[0] * ln / 2 * sx + b[0] * dp / 2 * sy, y + a[1] * ln / 2 * sx + b[1] * dp / 2 * sy) for sx in (-1, 1) for sy in (-1, 1)]

    def boxes_overlap(self, p, q, gap):
        """Separating axis test of two turned rectangles (x, y, length, depth, mdir), shrunk by gap."""
        A = self.corners(p[0], p[1], max(p[2] - gap, 0.1), max(p[3] - gap, 0.1), p[4])
        B = self.corners(q[0], q[1], max(q[2] - gap, 0.1), max(q[3] - gap, 0.1), q[4])
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
            self.placed.append((x, y, ln, dp, mdir, kind == "object" and tl.is_barrier(what)))
        it = self.make(kind, what, x, y, mdir, z, flag)
        self.items.append(it)
        return it

    def put(self, kind, what, x, y, mdir, search=0.0, road_ok=False, flag=False, need=False, note=None):
        """On the ground at the nearest clear spot within `search` m of (x, y); None (noted) without room."""
        steps = [0.0] + [r * 0.25 for r in range(1, int(search * 4) + 1)]
        for r in steps:
            n = max(1, int(r * 12))
            for k in range(n):
                a = 2 * math.pi * k / n
                px, py = x + r * math.cos(a), y + r * math.sin(a)
                if self.free(kind, what, px, py, mdir, road_ok):
                    return self.add(kind, what, px, py, mdir, flag=flag)
        self.notes.append(f"no room for {note or what} at {x:.1f},{y:.1f}: {self.why(kind, what, x, y, mdir, road_ok)}")
        assert not need, (self.t.name, what, x, y)
        return None

    def group(self, parts, x, y, search=1.0, road_ok=False, note=None):
        """Several things (kind, what, dx, dy, mdir) placed together, moved as one to the nearest spot where all fit."""
        steps = [0.0] + [r * 0.25 for r in range(1, int(search * 4) + 1)]
        for r in steps:
            n = max(1, int(r * 12))
            for k in range(n):
                a = 2 * math.pi * k / n
                ox, oy = x + r * math.cos(a), y + r * math.sin(a)
                if all(self.free(kd, w, ox + dx, oy + dy, d, road_ok) for kd, w, dx, dy, d in parts):
                    return [self.add(kd, w, ox + dx, oy + dy, d) for kd, w, dx, dy, d in parts]
        if note != "-":
            self.notes.append(f"no room for {note or parts[0][1]} at {x:.1f},{y:.1f}: " + str([(w, self.why(kd, w, x + dx, y + dy, d, road_ok)) for kd, w, dx, dy, d in parts]))
        return []

    # ---- fortification pieces
    def post(self, role, x, y, face, cover=None, back=None, search=1.0, road_ok=False, note=None, kind=None):
        """A guard (or a static: kind "static") at (x, y) facing `face`, with cover `back` m in front (towards face)."""
        kind = kind or "guard"
        if kind == "static":  # The spot within `search` m (and the facing within 40 degrees) that sees furthest
            best = None
            for r in [0.0] + [k * 0.5 for k in range(1, int(search * 2) + 1)]:
                for k in range(max(1, int(r * 8))):
                    a = 2 * math.pi * k / max(1, int(r * 8))
                    px, py = x + r * math.cos(a), y + r * math.sin(a)
                    fc = self.aim(px, py, face)
                    v = self.sight(px, py, fc, start=1.2)
                    if (best is None or v > best[0] + 1) and self.free("static", role, px, py, fc, road_ok):
                        best = (v, px, py, fc)
            if best:
                x, y, face = best[1], best[2], best[3]
        cover = cover or (ROUND if kind == "static" else SHORT)
        if back is None:
            back = {ROUND: 1.3, SHORT: 0.9, LONG: 0.9, HB3: 1.3, HB1: 1.2}.get(cover, 1.1) + (0.3 if kind == "static" else 0)
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

    def line(self, p0, p1, feats=(), road_ok=False, fill=(WALL6, WALL4, HB3, HB1), trim=(0.0, 0.0), note="wall"):
        """A perimeter line from p0 to p1 (model x, y): filled with 2-high H-barrier walls, pieces that would stand
        in a building left out (the building closes the line there). feats: (kind, s, arg) at s metres along the
        line: ("gate", s, width) a bar gate in a gap; ("fire", s, role) a 1-high H-barrier firing step with the guard
        behind it; ("static", s, role) a low bagged slot with the static behind it; ("open", s, length) a gap; the
        guards and statics face out (away from the house's side of the line)."""
        self.lines.append((p0, p1))
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        L = math.hypot(dx, dy)
        run = heading(dx, dy)
        u = (dx / L, dy / L)
        wdir = (run - 90) % 360  # A piece's length lies along the run
        # Outward: the side away from the house's centre
        nx, ny = -u[1], u[0]
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        if nx * (0 - mx) + ny * (0 - my) > 0:
            nx, ny = -nx, -ny
        out = heading(nx, ny)
        wdir = out  # Pieces face outward (their length across the out direction)
        at = lambda s, o=0.0: (p0[0] + u[0] * s + nx * o, p0[1] + u[1] * s + ny * o)
        res = []
        busy, lows = [], []
        for kind, s, arg in sorted(feats, key=lambda f: f[0] != "gate"):
            if kind == "gate":
                cls = arg if isinstance(arg, str) else BAR
                half = size_of("object", cls)[0] / 2
                busy.append((s - half, s + half))  # The gate's own length: the wall closes up to it
                x, y = at(s)
                it = self.put("object", cls, x, y, wdir, road_ok=True, note="gate")
                res += [it] if it else []
            elif kind == "open":
                busy.append((s - arg / 2, s + arg / 2))
            elif kind == "slot":  # A low bagged slot in the wall for a static added at a later tier (static_at)
                busy.append((s - 1.5, s + 1.5))
                x, y = at(s)
                res += self.group([("object", LONG, 0, 0, wdir)], x, y, 0.0, road_ok, note="slot")
            elif kind == "low":  # (s0, s1): 1-high H-barriers only (the veranda's guards fire over them)
                lows.append(arg)
                busy.append(arg)
            elif kind in ("fire", "static"):
                if kind == "fire":
                    half, back = 1.8, 1.3
                    mk = lambda x, y, gx, gy: [("object", HB3, 0, 0, wdir), ("guard", arg, gx - x, gy - y, out)]
                else:
                    role, face = (arg, out) if isinstance(arg, str) else arg
                    half, back = 1.5, 1.6
                    mk = lambda x, y, gx, gy: [("object", LONG, 0, 0, wdir), ("static", role, gx - x, gy - y, self.aim(gx, gy, face, out))]
                got = []
                fits = []
                for ds in (0, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5, 2.0, -2.0, 2.5, -2.5, 3.0, -3.0, 3.5, -3.5):
                    if any(b0 < s + ds + half - 0.05 and s + ds - half + 0.05 < b1 for b0, b1 in busy):
                        continue
                    x, y = at(s + ds)
                    gx, gy = at(s + ds, -back)
                    parts = mk(x, y, gx, gy)
                    if all(self.free(k, w, x + dx, y + dy, dd, road_ok) for k, w, dx, dy, dd in parts):
                        if kind == "fire":
                            fits.append((0, ds))
                            break
                        fits.append((-min(self.sight(gx, gy, parts[1][4], start=1.2), 30.0), abs(ds), ds))  # The longest field of fire
                if fits:
                    ds = min(fits)[-1]
                    x, y = at(s + ds)
                    gx, gy = at(s + ds, -back)
                    got = self.group(mk(x, y, gx, gy), x, y, 0.0, road_ok, note="-")
                    busy.append((s + ds - half, s + ds + half))
                if self.notes and self.notes[-1].startswith("no room for -"):
                    self.notes = [n for n in self.notes if not n.startswith("no room for -")]
                if not got:
                    x, y = at(s)
                    gx, gy = at(s, -back)
                    parts = mk(x, y, gx, gy)
                    self.notes.append(f"no room for the {kind} {parts[1][1]} at {x:.1f},{y:.1f}: " + str([(w, self.why(k, w, x + dx, y + dy, dd, road_ok)) for k, w, dx, dy, dd in parts]))
                res += got
        busy.sort()
        for s0, s1 in lows:
            res += self.fill(at, s0, s1, [], wdir, road_ok, (HB3, HB1))
        # Fill the rest
        return res + self.fill(at, trim[0], L - trim[1], busy, wdir, road_ok, fill)

    def fill(self, at, s, end, busy, wdir, road_ok, fill, ov=0.3):
        """Pieces end to end from s to end, each overlapping the one before (and the features either side) by ov, so
        the line is unbroken; a piece whose middle would stand in a building is left out (the building closes the
        line there) and the line picks up again with a piece reaching into it."""
        res = []
        segs, pos = [], s
        for b0, b1 in sorted(busy):
            if b1 <= pos:
                continue
            if b0 > pos:
                segs.append((pos, min(b0, end)))
            pos = max(pos, b1)
        if pos < end:
            segs.append((pos, end))
        for s0, s1 in segs:
            a0, a1 = (s0 - ov if s0 > s else s0 - 0.5), (s1 + ov if s1 < end else s1 + 0.5)  # Into the features / past the ends
            cur = a0
            while cur < a1 - 0.2:
                room = a1 - cur
                done = False
                for cls in fill:
                    ln = size_of("object", cls)[0]
                    if ln > room + 0.01 and cls != fill[-1] and not (cls == WALL4 and room >= 4.2):
                        continue  # (a 2-high piece may overhang both ends by 0.6 m when 4.2 m are left)
                    c = cur + ln / 2 if ln <= room else (cur + room / 2 if cls == WALL4 else a1 - ln / 2)
                    x, y = at(c)
                    if cls in (WALL6, WALL4) and self.watched(x, y, ln, wdir):
                        continue  # A guard looks out through here: 1-high pieces he fires over
                    if self.free("object", cls, x, y, wdir, road_ok, pad=0.1):
                        res.append(self.add("object", cls, x, y, wdir))
                        if cls in (HB3, HB1) and WALL6 in fill and not self.watched(x, y, ln, wdir):
                            # A 2-high stretch where no 2-high wall piece fits: a second block dropped on top
                            res.append(self.add("object", cls, x, y, wdir, z=self.t.ground_model(x, y) + STACK[cls]))
                            self.stacked.append((x, y) + size_of("object", cls) + (wdir, True))
                        cur = c + ln / 2 - ov
                        done = True
                        break
                if not done:
                    cur += 0.25
                if done and cur >= a1 - ov - 0.01:
                    break
        return res

    def static_at(self, p0, p1, s, role, face=None):
        """A static behind a line's slot (line(p0, p1) with ("slot", s, None))."""
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        L = math.hypot(dx, dy)
        u = (dx / L, dy / L)
        nx, ny = -u[1], u[0]
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        if nx * (0 - mx) + ny * (0 - my) > 0:
            nx, ny = -nx, -ny
        x, y = p0[0] + u[0] * s - nx * 1.6, p0[1] + u[1] * s - ny * 1.6
        out = heading(nx, ny)
        return self.put("static", role, x, y, self.aim(x, y, out if face is None else face, out), search=0.5, note=f"{role} behind its slot")

    def wire(self, p0, p1, road_ok=True, gap=None):
        """Razor wire along a line (pieces left out where they don't fit); gap: (s0, s1) along it left open (the
        lane to a gate)."""
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        L = math.hypot(dx, dy)
        u = (dx / L, dy / L)
        wdir = (heading(dx, dy) - 90) % 360
        out, s = [], 0.0
        while s + 7.6 <= L + 1.0:
            if gap and s < gap[1] and s + 7.6 > gap[0]:
                s = gap[1]
                continue
            x, y = p0[0] + u[0] * (s + 3.8), p0[1] + u[1] * (s + 3.8)
            it = self.put("object", WIRE, x, y, wdir, search=0.5, road_ok=road_ok, note="wire")
            out += [it] if it else []
            s += 7.6
        return out

    def hogs(self, x, y, across, n=3, spacing=2.8):
        """Czech hedgehogs in a staggered row across an approach (across: the row's direction)."""
        a, f = vec(across), vec(across + 90)
        out = []
        for k in range(n):
            o = (k - (n - 1) / 2) * spacing
            s = 0.7 if k % 2 else -0.7
            it = self.put("object", HOG, x + a[0] * o + f[0] * s, y + a[1] * o + f[1] * s, (across + 45) % 360, search=1.0, road_ok=True, note="hedgehog")
            out += [it] if it else []
        return out

    def road_block(self, x, y, n=3):
        """Hedgehogs across the road nearest model (x, y), square across it."""
        t = self.t
        w = t.to_world(x, y, 0)
        near = t.roads_near(w[0], w[1], 15)
        if not near:
            self.notes.append(f"no road near {x},{y}")
            return []
        seg = near[0][1]
        a, b = t.to_model(seg["beg"]), t.to_model(seg["end"])
        vx, vy = b[0] - a[0], b[1] - a[1]
        k = max(0, min(1, ((x - a[0]) * vx + (y - a[1]) * vy) / (vx * vx + vy * vy or 1)))
        cx, cy = a[0] + k * vx, a[1] + k * vy
        return self.hogs(cx, cy, (heading(vx, vy) + 90) % 360, n)

    def chicane(self, gx, gy, out, lat_first=1, step=4.0):
        """A serpentine in front of a gate: two concrete barriers across the approach, staggered (each closing one
        half of the way), so a vehicle has to slow and weave under the gate's guns."""
        f, l = vec(out), vec(out + 90)
        res = []
        for k, side in ((1, lat_first), (2, -lat_first)):
            x, y = gx + f[0] * step * k + l[0] * side * 1.8, gy + f[1] * step * k + l[1] * side * 1.8
            it = self.put("object", CNC, x, y, out, search=0.75, road_ok=True, note="chicane")
            res += [it] if it else []
        return res

    def aim(self, x, y, face, out=None):
        """The facing within 40 degrees of `face` (and of the wall's outward direction, when in a wall) that sees
        furthest (30 m is enough)."""
        best = (self.sight(x, y, face, start=1.2), face)
        for dd in (10, -10, 20, -20, 30, -30, 40, -40):
            f = (face + dd) % 360
            if out is not None and abs((f - out + 180) % 360 - 180) > 25:
                continue
            v = self.sight(x, y, f, start=1.2)
            if v > best[0] + 2:
                best = (v, f)
        return best[1]

    def watched(self, x, y, ln, wdir):
        """Whether a guard on the ground faces this stretch of wall from within 4.5 m."""
        for gx, gy, gl, gd, gm, gb in self.placed:
            if gb or gl not in (0.6, 2.0):
                continue  # Guards and statics
            f = vec(gm)
            for k in range(1, 10):
                if self.boxes_overlap((gx + f[0] * k * 0.5, gy + f[1] * k * 0.5, 0.1, 0.1, 0), (x, y, ln, 2.0, wdir), 0):
                    return True
        return False

    def sight(self, x, y, face, maxd=30.0, start=1.0, tall_only=True):
        """How far a man or gun at (x, y) sees along face before a building, rock, the house or one of our 2-high
        pieces (the 1-high blocks and the bags are fired over)."""
        t = self.t
        f = vec(face)
        tall = [p for p in self.placed if (p[2], p[3]) in (SIZE[WALL6], SIZE[WALL4], SIZE[TOWER], tl.CLASSES[BUNKER])] + self.stacked if tall_only else []
        tall = [q for q in tall if not self.boxes_overlap((x, y, 0.1, 0.1, 0), q[:5], 0)]  # Not what he stands in
        dd = start
        while dd < maxd:
            px, py = x + f[0] * dd, y + f[1] * dd
            w = t.to_world(px, py, 0)
            if any(h[0] in ("building", "part", "rock", "tree") for h in t.hits(w[0], w[1], 0.2, 0.2, 0, 0)):
                return dd
            if EXTENT[0] <= px <= EXTENT[2] and EXTENT[1] <= py <= EXTENT[3]:
                return dd
            if any(self.boxes_overlap((px, py, 0.1, 0.1, 0), q[:5], 0) for q in tall):
                return dd
            dd += 0.5
        return maxd

    def tower(self, x, y, face, role="mg_gunner", search=2.0, road_ok=True):
        """A sandbag watchtower with a man on its platform, facing `face`: the raised post over the main approach."""
        for r in [0.0] + [k * 0.25 for k in range(1, int(search * 4) + 1)]:
            n = max(1, int(r * 12))
            for k in range(n):
                a = 2 * math.pi * k / n
                px, py = x + r * math.cos(a), y + r * math.sin(a)
                if self.free("object", TOWER, px, py, face, road_ok):
                    self.add("object", TOWER, px, py, face)
                    z = self.t.ground_model(px, py) + TOWER_DECK
                    self.towers.append([px, py, z, face, 2])
                    l = vec(face + 90)
                    return [self.items[-1], self.add("guard", role, px + l[0] * 0.8, py + l[1] * 0.8, face, z=z),
                            self.add("guard", "marksman", px - l[0] * 0.8, py - l[1] * 0.8, (face + 30) % 360, z=z)]
        self.notes.append(f"no room for the tower at {x:.1f},{y:.1f}: {self.why('object', TOWER, x, y, face, road_ok)}")
        return []

    def bunker(self, x, y, face, role="autorifleman", search=1.0):
        """A small sandbag bunker with a guard inside, its slit facing `face`."""
        return self.group([("object", BUNKER, 0, 0, face), ("guard", role, 0, 0, face)], x, y, search, road_ok=True, note=f"bunker {role}")


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


# The house's posts: (x, y, floor index, facing). Windows from the plan (t.plan().windows: the east wall has them),
# the balcony over the veranda open to the west. A post is used only where its view runs 4 m or more.
HOUSE_POSTS = {
    "win_g_s": (4.4, -5.25, 0, 90), "win_u_s": (4.4, -5.25, 1, 90), "win_u_m": (4.4, -2.12, 1, 90),
    "win_u_n": (4.4, 5.5, 1, 90),  # (The balcony was given up: its awning posts blind a man there, round 2)
    "ver_n": (-2.8, -1.6, 0, 270), "ver_s": (-3.2, -6.8, 0, 270),  # Behind the veranda's bags (ver_s: entry W)
}


def house_view(t, d, key):
    x, y, fl, face = HOUSE_POSTS[key]
    f = vec(face)
    k = 1.2
    while EXTENT[0] <= x + f[0] * k <= EXTENT[2] and EXTENT[1] <= y + f[1] * k <= EXTENT[3]:
        k += 0.25  # From the window, the rail or the veranda's edge outward
    return d.sight(x + f[0] * k, y + f[1] * k, face, start=0.0) + k


def house_guard(t, d, cfg, role, prefer):
    """A guard at the first free house post of `prefer` that sees out (4 m or more); else at the town's spare posts
    outside (cfg["spare"]: (x, y, facing) behind short bags). Returns the item or None."""
    used = cfg.setdefault("_used", set())
    if cfg["entry"] != "W":
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
            continue  # (Blind once the walls stand)
        got = d.post(role, x, y, face, search=1.0)
        if got:
            return got[0]
    for tw in d.towers:  # A second man on a tower's platform
        if tw[4] < 3:
            tw[4] += 1
            f = vec(tw[3])
            return d.add("guard", role, tw[0] + f[0] * 0.8, tw[1] + f[1] * 0.8, tw[3], z=tw[2])
    d.notes.append(f"no house post nor spare for a {role}")
    return None


def tier2(t, d, cfg):
    f0, f1 = t.floors[0], t.floors[1]
    # The veranda as a porch position: bags inside the pillars on its north bay (the T1 gendarme behind them) and
    # across its south end, the bay in front of the door left as the way in (or the south end, entering from S)
    d.add("object", SHORT, -3.85, -3.4, 270, z=f0)
    d.add("object", SHORT, -3.85, -1.6, 270, z=f0)
    if cfg["entry"] == "W":
        d.add("object", LONG, -3.1, -7.15, 180, z=f0)
    else:  # The way in from the south: the bay in front of the door bagged instead
        d.add("object", SHORT, -3.85, -6.0, 270, z=f0)
    # The C-nest on the ground covering the approach to the veranda
    nx, ny, nf = cfg["nest"]
    d.nest(nx, ny, nf, search=2.0, road_ok=cfg.get("nest_road", False))
    # The side door gated; riflemen at the balcony rail and at a window
    d.add("object", "Land_PipeFence_03_m_gate_r_F", 5.0, 5.2, 90, z=f0)
    house_guard(t, d, cfg, "rifleman", ["win_g_s", "win_u_n", "win_u_m", "win_u_s", "ver_n"])
    house_guard(t, d, cfg, "rifleman", ["ver_n", "win_u_n", "win_u_m", "win_u_s", "win_g_s"])


def tier3_house(t, d, cfg):
    house_guard(t, d, cfg, "marksman", ["win_u_m", "win_u_s", "win_u_n"])
    house_guard(t, d, cfg, "rifleman", ["win_u_s", "win_u_n", "win_u_m", "win_g_s", "ver_s"])
    house_guard(t, d, cfg, "rifleman", ["win_u_n", "win_u_m", "win_u_s", "win_g_s", "ver_s", "ver_n"])
    for role in cfg.get("t3_extra", ()):
        house_guard(t, d, cfg, role, ["ver_s", "ver_n", "win_u_n", "win_u_m", "win_u_s", "win_g_s"])


def tier4_house(t, d, cfg):
    house_guard(t, d, cfg, "mg_gunner", ["ver_s", "win_u_n", "win_u_m", "win_u_s", "win_g_s", "ver_n"])
    house_guard(t, d, cfg, "rifleman", ["win_u_n", "win_u_m", "win_u_s", "win_g_s", "ver_s", "ver_n"])
    for role in cfg.get("t4_extra", ()):
        house_guard(t, d, cfg, role, ["ver_s", "ver_n", "win_u_n", "win_u_m", "win_u_s", "win_g_s"])


def report(t, d, tiers):
    """The views of the outside guards and the statics' fields of fire, as the in-game check measures them."""
    out = []
    for kind, what, p, o, extra in tiers[-1]:
        if kind not in ("guard", "static") or ("ground" not in extra and kind == "guard" and t.inside_office(*t.to_model(p)[:2], 1.0)):
            continue
        m = t.to_model(p)
        face = ((o if kind == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) - t.dir) % 360
        need = 15.0 if kind == "static" else 4.0
        v = d.sight(m[0], m[1], face, start=1.2 if kind == "static" else 0.6)
        if v < need:
            out.append(f"{what} at {m[0]:.1f},{m[1]:.1f} sees {v} m")
    return out


def gaps(t, d):
    """Stretches of the drawn lines that nothing closes (no barrier piece, building or the house): [(x, y, length)]."""
    out = []
    bars = [p for p in d.placed if p[5]]
    for p0, p1 in d.lines:
        L = math.dist(p0, p1)
        run = None
        for k in range(int(L / 0.25) + 1):
            x, y = p0[0] + (p1[0] - p0[0]) * k * 0.25 / L, p0[1] + (p1[1] - p0[1]) * k * 0.25 / L
            w = t.to_world(x, y, 0)
            shut = any(d.boxes_overlap((x, y, 0.05, 0.05, 0), b[:5], 0) for b in bars) or                 any(h[0] in ("building", "part", "wall", "rock") for h in t.hits(w[0], w[1], 0.05, 0.05, 0, 0)) or                 (EXTENT[0] <= x <= EXTENT[2] and EXTENT[1] <= y <= EXTENT[3])
            if not shut:
                run = run or [x, y, 0]
                run[2] += 0.25
            elif run:
                out.append(run)
                run = None
        if run:
            out.append(run)
    return [(round(x, 1), round(y, 1), round(l, 2)) for x, y, l in out if l > 0.3]


def plug(t, d):
    """Closes what's left open in the lines (short stretches beside buildings, round a static's slot) with 1-high
    blocks reaching into what's either side. Before tier 4 is taken, so the tier's snapshot has them; each plug
    goes in the tier whose line it closes (it's checked again at the tier of the line, see draft)."""
    for gx, gy, gl in gaps(t, d):
        line = min(d.lines, key=lambda l: abs((l[1][0] - l[0][0]) * (l[0][1] - gy) - (l[0][0] - gx) * (l[1][1] - l[0][1])) / math.dist(*l))
        (x0, y0), (x1, y1) = line
        L = math.dist(line[0], line[1])
        u = ((x1 - x0) / L, (y1 - y0) / L)
        cx, cy = gx + u[0] * (gl / 2 - 0.125), gy + u[1] * (gl / 2 - 0.125)
        wdir = (heading(*u) - 90) % 360
        keep = d.placed
        d.placed = [p for p in keep if not (p[2] == 2.0 and p[3] == 2.0)]  # A plug may touch a static's generous footprint
        done = False
        for off in (0, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75):
            px, py = cx + u[0] * off, cy + u[1] * off
            if d.free("object", HB1, px, py, wdir, True, pad=0.12):
                d.placed = keep
                d.add("object", HB1, px, py, wdir)
                done = True
                break
        if not done:
            d.placed = keep


def draft(t, cfg):
    cfg = dict(cfg, spare=list(cfg.get("spare", [])), _used=set())
    d = Drafter(t)
    tiers = []
    tier1(t, d, cfg)
    tiers.append(list(d.items))
    tier2(t, d, cfg)
    tiers.append(list(d.items))
    tier3_house(t, d, cfg)
    cfg["build"](d, 3)
    plug(t, d)
    tiers.append(list(d.items))
    cfg["build"](d, 4)
    tier4_house(t, d, cfg)
    plug(t, d)
    tiers.append(list(d.items))
    for r in report(t, d, tiers):
        d.notes.append("VIEW " + r)
    g = gaps(t, d)
    if g:
        d.notes.append(f"GAPS in the lines (x, y, length): {g}")
    return tiers, d.notes


# ---------------------------------------------------------------- maps

def cmap(t, items, r=34, step=1):
    """Top-down, model coordinates (up = +y; the veranda and the main door face left/down): O house, # building,
    = wall, t tree, : road; W wall, w 1-high step, G bar gate, b bags, B bunker, h hedgehog, z wire, c chicane,
    f flag, g guard (outside), S static."""
    marks = {}
    for kind, what, p, o, extra in items:
        if "ground" not in extra:
            continue
        m = t.to_model(p)
        c = {"guard": "g", "static": "S"}.get(kind)
        if c is None:
            c = {WALL6: "W", WALL4: "W", HB3: "w", HB1: "w", BAR: "G", HOG: "h", WIRE: "z", CNC: "c", BUNKER: "B",
                 "Flag_NATO_F": "f"}.get(what, "b" if "Bag" in what else "x")
        if kind == "object" and size_of(kind, what)[0] > 2.5 and what not in (HOG, BUNKER, TOWER):
            ln = size_of(kind, what)[0]
            yaw = math.degrees(math.atan2(o[0][0], o[0][1])) - t.dir
            a = vec(yaw + 90)
            for s in range(-int(ln / 2), int(ln / 2) + 1):
                marks.setdefault((round((m[0] + a[0] * s) / step), round((m[1] + a[1] * s) / step)), c)
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
                c = {"building": "#", "wall": "=", "tree": "t", "rock": "r", "part": "O"}.get(hit[0][0], "?")
            if EXTENT[0] <= x <= EXTENT[2] and EXTENT[1] <= y <= EXTENT[3]:
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

PIPEGATE = "Land_PipeFence_03_m_gate_r_F"


@site("Agios Dionysios", entry="W", nest=(-8.5, -1.8, 270), flag=(-7.0, -10.0),
      spare=[(-6.0, -12.0, 180), (6.0, -11.5, 180)])
def agios_dionysios(d, tier):
    # No road within 60 m: open ground south and east, a big house north-west, an old wall running west from the
    # veranda's north end, an old wall north from the house's north-east corner. The way in: from the west, square
    # onto the veranda's door bay.
    if tier == 3:
        d.line((-11.5, -14.5), (-11.5, 10.0), [("gate", 8.4, None), ("fire", 2.0, "rifleman"), ("fire", 14.8, "rifleman"), ("slot", 20.5, None)])
        d.line((-11.5, -14.5), (12.5, -14.5), [("fire", 9.0, "autorifleman"), ("static", 19.5, ("hmg", 180))])
    if tier == 4:
        d.static_at((-11.5, -14.5), (-11.5, 10.0), 20.5, "gmg")
        d.line((12.5, -14.5), (12.5, 10.0), [("fire", 8.0, "rifleman"), ("static", 16.0, ("at", 90))])
        d.line((-11.5, 10.0), (12.5, 10.0), [("fire", 6.0, "rifleman"), ("fire", 17.0, "autorifleman")])
        d.tower(-14.0, -17.0, 225)                                   # The raised post over the west and south approaches
        d.bunker(14.6, -16.6, 135, search=2.5, role="at")
        d.chicane(-11.5, -6.1, 270, step=5.5)
        d.wire((-16.5, -17.0), (-16.5, 8.0), gap=(5.0, 17.0))
        d.wire((-8.0, -19.0), (12.0, -19.0))
        d.hogs(-9.0, -21.5, 90, n=2)
        d.hogs(7.0, -21.5, 90, n=3)
        d.hogs(19.0, -6.0, 0, n=3)


@site("Chalkeia", t3_extra=('autorifleman',), t4_extra=('autorifleman', 'rifleman'), entry="W", nest=(2.6, -10.0, 190), flag=(4.5, -9.5),
      spare=[(-5.4, 3.5, 270), (12.5, 8.0, 90), (9.0, 5.0, 45), (10.0, 2.5, 90), (-1.0, -12.0, 200)])
def chalkeia(d, tier):
    # A track runs north-south just west of the veranda (the main street); a house abuts the north side, another the
    # east side's southern half; a yard opens north-east behind the house and open ground lies south. The way in:
    # off the track, square onto the door bay.
    if tier == 3:
        d.line((-7.2, -14.5), (-7.2, 8.0), [("gate", 8.4, None), ("fire", 1.8, "rifleman"), ("fire", 15.0, "autorifleman")], road_ok=True)
        d.line((-7.2, -14.5), (6.2, -14.5), [("static", 3.0, ("hmg", 200))])
    if tier == 4:
        d.post("at", -9.4, -11.0, 200, kind="static", search=1.5, road_ok=True)           # On the track's verge, down it
        d.post("gmg", -9.6, -17.0, 200, kind="static", search=1.5, road_ok=True)
        d.line((15.2, -1.0), (15.2, 10.6), [("fire", 3.0, "rifleman"), ("fire", 7.5, "autorifleman")])
        d.line((5.6, 0.2), (15.2, 0.2))
        d.tower(-9.6, 11.8, 330, search=2.0)                         # Over the track north
        d.chicane(-7.2, -6.1, 270, step=5.0)
        d.road_block(-12.0, 22.0)
        d.road_block(-10.0, -24.0)
        d.wire((-5.0, -18.5), (6.0, -18.5))


@site("Charkia", t3_extra=('autorifleman', 'rifleman'), t4_extra=('autorifleman',), entry="W", nest=(-9.0, -4.4, 270), flag=(-7.0, -10.5),
      spare=[])
def charkia(d, tier):
    # Between two tracks (north-west and south-east); a house close north-west, an old wall running north-east from
    # the house's south-east corner; open ground west and south towards the tracks. The way in: from the west.
    if tier == 3:
        d.line((-12.5, -12.5), (-12.5, 2.0), [("gate", 6.4, None), ("slot", 11.0, None), ("fire", 1.6, "rifleman")])
        d.line((-12.5, -12.5), (6.4, -12.5), [("fire", 7.2, "autorifleman"), ("static", 12.0, ("hmg", 160))])
        d.line((6.4, -12.5), (6.4, -7.6))
    if tier == 4:
        d.static_at((-12.5, -12.5), (-12.5, 2.0), 11.0, "gmg")
        d.line((-5.4, 10.4), (12.4, 10.4), [("fire", 6.0, "rifleman"), ("static", 12.0, ("at", 10))])
        d.line((12.4, 10.4), (12.4, -3.0), [("fire", 6.0, "rifleman")])
        d.tower(-15.0, -15.0, 225)                                   # Over the west track and the gate
        d.bunker(8.4, -14.6, 135, search=2.5, role="at")
        d.post("autorifleman", 8.0, 6.0, 45)
        d.chicane(-12.5, -6.1, 270, step=5.5)
        d.road_block(-24.0, -6.0)
        d.road_block(16.0, -12.0)
        d.road_block(-8.0, 20.0)
        d.wire((-16.5, -14.0), (-16.5, 2.0), gap=(4.0, 12.0))


@site("Kalochori", entry="S", nest=(2.5, -11.5, 180), flag=(-1.0, -9.5),
      spare=[(2.6, -14.0, 180), (-7.5, -8.0, 180)])
def kalochori(d, tier):
    # A walled front yard south of the house (old walls down both sides, a gateway in its south wall at x 0), the
    # main road beyond it; a lane west of the house between it and a wall, a yard east inside another wall; houses
    # close the north. The way in: road, the old gateway, the front yard, the veranda's south end.
    if tier == 3:
        d.put("object", BAR, 0.0, -15.4, 180, search=0.5, road_ok=True, note="gate")
        d.post("rifleman", -2.2, -13.2, 180)                                              # Inside the gateway
        d.line((-10.2, -15.6), (-3.9, -15.6), [("fire", 3.1, "autorifleman")])          # The west lane's mouth
        d.line((5.6, -15.6), (13.8, -15.6), [("static", 2.0, ("hmg", 200)), ("fire", 5.6, "rifleman")], road_ok=True)
        d.line((-10.2, 6.4), (-4.8, 6.4), [("fire", 2.7, "autorifleman")])              # The north-west lane closed
    if tier == 4:
        d.line((5.6, 10.6), (14.2, 10.6))                                                # The east yard's north side
        d.tower(5.2, -18.6, 180)                                                          # Over the road and the gateway
        d.bunker(-4.0, -18.0, 200, role="at")
        d.post("at", 1.5, -10.0, 180, cover=SHORT)                                        # The AT man inside the gateway
        d.post("at", -1.5, -11.0, 180, search=1.5, kind="static")                         # The AT gun through the gateway
        d.post("gmg", -7.0, -12.0, 180, search=1.0, kind="static")                        # Down the west lane to the road
        d.post("rifleman", -7.5, -3.0, 0)                                                 # The west lane
        d.chicane(0.0, -15.4, 180, step=4.5)
        d.road_block(-14.0, -21.0)
        d.road_block(16.0, -16.0)
        d.road_block(0.0, -28.0)
        d.wire((-10.0, -18.0), (-4.5, -18.0))


@site("Molos", entry="W", nest=(-5.2, 10.4, 270), flag=(2.0, 10.0),
      spare=[(2.0, 9.0, 0)], t4_extra=("rifleman",))
def molos(d, tier):
    # A road runs north-south just west of the veranda and a big road east-west 14 m north; a house abuts the
    # south side; a yard opens east. The way in: off the west road onto the veranda.
    if tier == 3:
        d.post("autorifleman", -3.4, 9.2, 300)
        d.line((-7.0, -7.2), (-7.0, 12.4), [("gate", 3.2, PIPEGATE), ("low", 0, (5.0, 7.8))], road_ok=True)
        d.line((-7.0, 12.4), (16.4, 12.4), [("static", 6.0, ("hmg", 0)), ("fire", 11.0, "autorifleman"), ("slot", 15.5, None), ("fire", 20.0, "rifleman")], road_ok=True)
    if tier == 4:
        d.static_at((-7.0, 12.4), (16.4, 12.4), 15.5, "at")
        d.line((16.4, 12.4), (16.4, -7.2), [("static", 5.0, ("gmg", 90)), ("fire", 12.0, "rifleman")])
        d.tower(-9.0, 14.6, 315)                                     # Over the road junction
        d.bunker(18.4, 14.4, 45, search=1.5, role="at")
        d.post("rifleman", 10.0, -4.0, 90)
        d.chicane(-7.0, -3.8, 270, step=3.0)
        d.road_block(-13.0, 4.0)
        d.road_block(-13.0, -18.0)
        d.road_block(5.0, 19.0)
        d.wire((19.0, -6.0), (19.0, 10.0))


@site("Neochori", t3_extra=('autorifleman', 'rifleman'), t4_extra=('autorifleman', 'rifleman'), entry="W", nest=(-2.6, -11.6, 225), flag=(2.0, -10.0),
      spare=[(9.6, -11.0, 180), (8.0, 2.0, 90)])
def neochori(d, tier):
    # A road runs north-south right along the veranda; a big building fills the east; open yards north and south.
    # The way in: off the road, through a blast wall standing between the road and the veranda.
    if tier == 3:
        d.line((-6.2, -14.5), (-6.2, 10.5), [("gate", 8.4, None), ("fire", 2.0, "rifleman"), ("low", 0, (12.9, 15.2))], road_ok=True)
        d.line((-6.2, -14.5), (11.4, -14.5), [("static", 8.0, ("hmg", 225)), ("slot", 13.0, None)])
    if tier == 4:
        d.static_at((-6.2, -14.5), (11.4, -14.5), 13.0, "gmg")
        d.line((-6.2, 10.5), (11.4, 10.5), [("fire", 7.0, "rifleman"), ("static", 12.5, ("at", 10))])
        d.line((11.4, -14.5), (11.4, -9.0))
        d.tower(-8.6, -17.0, 225)                                    # Over the road south and the gate
        d.bunker(-8.4, 12.6, 315, role="at")
        d.chicane(-6.2, -6.1, 270, step=3.0)
        d.road_block(-10.0, 22.0)
        d.road_block(-10.0, -22.0)
        d.wire((-4.0, -18.0), (11.0, -18.0))


@site("Panochori", t3_extra=('autorifleman', 'rifleman', 'rifleman'), t4_extra=('autorifleman', 'rifleman'), entry="W", nest=(1.6, -10.6, 250), flag=(3.0, -10.5),
      spare=[(6.0, -11.0, 200), (9.0, 0.0, 0), (4.0, -12.0, 270)])
def panochori(d, tier):
    # A road runs north-south right along the veranda and bends away south-west; a house abuts the north; old
    # walls and houses close a yard south and east. The way in: off the road through a blast wall in front of the
    # veranda, the gate square on the door; the heavy weapons in posts on the road's verge.
    if tier == 3:
        d.line((-6.1, -9.5), (-6.1, 7.8), [("gate", 3.4, PIPEGATE), ("low", 0, (5.2, 10.2))], road_ok=True)
        d.post("hmg", -8.0, 8.4, 0, kind="static", search=1.5, road_ok=True)              # Up the road north
    if tier == 4:
        d.line((6.6, 8.4), (12.2, 8.4), [("static", 1.7, ("at", 0)), ("fire", 3.8, "rifleman")])
        d.tower(-9.2, 2.4, 270, search=2.0)                                                # Over the road, beside the gate
        d.post("gmg", -8.6, -4.0, 200, kind="static", search=1.5, road_ok=True)          # Down the road south-west
        d.post("autorifleman", 9.0, 2.0, 45)
        d.road_block(-10.0, 18.0)
        d.road_block(-18.0, -10.0)


@site("Paros", t3_extra=(), t4_extra=('autorifleman', 'rifleman', 'rifleman'), entry="W", nest=(0.5, -10.0, 260), flag=(4.0, 10.0),
      spare=[(5.0, 12.5, 90), (-4.8, 9.5, 300), (12.0, 9.0, 90)])
def paros(d, tier):
    # A road runs north-south just west of the veranda; houses abut the east side and close the south; a yard
    # opens north between the house and the next block, open to the east. The way in: off the road.
    if tier == 3:
        d.line((-7.2, -11.2), (-7.2, 15.4), [("gate", 5.1, PIPEGATE), ("fire", 9.0, "rifleman"), ("fire", 20.0, "rifleman")], road_ok=True)
        d.line((17.2, 5.6), (17.2, 15.4), [("slot", 3.0, None), ("fire", 7.5, "autorifleman")])
        d.post("hmg", -9.2, 13.5, 330, kind="static", search=1.5, road_ok=True)           # On the road's verge, up the road
    if tier == 4:
        d.line((-7.2, 15.4), (17.2, 15.4))
        d.tower(-9.4, -13.0, 225, search=2.5)                                              # Over the road south
        d.tower(14.0, 12.4, 45, search=2.0, road_ok=False)                                 # Over the yard's open east side
        d.static_at((17.2, 5.6), (17.2, 15.4), 3.0, "at")
        d.post("gmg", -9.2, -9.0, 200, kind="static", search=2.0, road_ok=True)           # Down the road
        d.chicane(-7.2, -6.1, 270, step=3.0)
        d.road_block(-12.0, 22.0)
        d.road_block(-14.0, -14.0)
        d.wire((20.0, 6.0), (20.0, 14.0))


@site("Rodopoli", entry="W", nest=(-9.0, -1.8, 270), flag=(-8.0, 6.0),
      spare=[(-7.0, -10.0, 180), (12.0, 0.0, 90)], t4_extra=("autorifleman",))
def rodopoli(d, tier):
    # Houses abut the north and south sides; a walled yard opens west of the veranda (gaps to the north road and
    # the south road); behind the house a lane runs north between it and the old wall along the east road. The way
    # in: across the west yard, square onto the door bay.
    if tier == 3:
        d.post("autorifleman", 9.5, 6.0, 0)
        d.line((-12.5, -12.8), (-12.5, 9.2), [("gate", 6.7, None), ("fire", 0.4 + 1.8, "rifleman"), ("fire", 15.2, "rifleman")])
        d.line((-12.5, 9.2), (-5.0, 9.2), [("static", 4.0, ("hmg", 0))])
        d.line((-12.5, -12.8), (-3.6, -12.8))
    if tier == 4:
        d.line((6.4, 8.6), (14.6, 8.6), [("static", 4.0, ("at", 0))])
        d.line((7.6, -8.6), (10.8, -8.6), [("fire", 1.6, "rifleman")])
        d.tower(-15.0, 11.8, 315, search=2.5)                                              # Over the yard to the north gap
        d.post("gmg", -15.0, -13.0, 180, kind="static", search=2.0)                       # Over the yard's south gap
        d.chicane(-12.5, -6.1, 270, step=3.5)
        d.hogs(-11.0, 25.5, 90, n=2)
        d.hogs(-12.0, -19.0, 90, n=2)
        d.wire((-16.5, -13.0), (-16.5, 8.0), gap=(1.5, 12.5))


@site("Sofia", t3_extra=('autorifleman', 'rifleman'), t4_extra=('autorifleman', 'rifleman', 'rifleman'), entry="W", nest=(-9.6, -9.0, 250), flag=(8.0, 4.0), nest_road=True,
      spare=[(9.0, 2.0, 90), (12.0, 2.0, 90), (9.0, 5.0, 45), (-9.0, 4.0, 300), (13.0, 5.5, 45)])
def sofia(d, tier):
    # On a corner: a road runs north-south west of the veranda and a big road east-west just south of the house;
    # houses abut the north and the south-east; a small yard behind opens east. The way in: off the west road.
    if tier == 3:
        d.line((-6.8, -11.0), (-6.8, 8.0), [("gate", 4.9, PIPEGATE), ("low", 0, (6.6, 11.5)), ("fire", 15.0, "autorifleman")], road_ok=True)
        d.line((-6.8, -11.0), (5.0, -11.0), [("static", 3.2, ("hmg", 200)), ("slot", 8.6, None)], road_ok=True)
    if tier == 4:
        d.static_at((-6.8, -11.0), (5.0, -11.0), 8.6, "at")
        d.line((16.0, 0.2), (16.0, 2.8))
        d.tower(-9.6, -14.6, 225, search=2.5)                                              # Over the junction
        d.bunker(6.5, -13.4, 160, search=1.5, role="at")
        d.post("gmg", -9.6, 1.0, 330, kind="static", search=1.5, road_ok=True)            # Up the west road
        d.post("rifleman", -9.2, 3.5, 315, search=1.0, road_ok=True)
        d.chicane(-6.8, -6.1, 270, step=3.0)
        d.road_block(-15.0, 18.0)
        d.road_block(-25.0, -13.0)
        d.road_block(15.0, -16.0)


@site("Therisa", t3_extra=('autorifleman',), t4_extra=('autorifleman',), entry="S", nest=(1.6, -10.0, 200), flag=(-8.0, -9.5),
      spare=[(-11.0, -9.5, 200), (-7.0, -10.0, 180), (11.0, -10.0, 180), (-9.0, 4.0, 0)])
def therisa(d, tier):
    # No road within 25 m: a house right against the veranda's west side and another on the east, old walls north-
    # east and south-east, open ground to the south (the road 35 m beyond it) and a passage from the north-west.
    # The way in: from the south, square onto the veranda's south end.
    if tier == 3:
        d.line((-15.2, -12.4), (17.6, -12.4), [("gate", 12.1, None), ("fire", 1.9, "autorifleman"), ("fire", 5.5, "rifleman"), ("fire", 18.7, "rifleman"), ("static", 24.0, ("hmg", 180)), ("slot", 29.0, None)])
    if tier == 4:
        d.static_at((-15.2, -12.4), (17.6, -12.4), 29.0, "gmg")
        d.line((17.6, -12.4), (17.6, 4.0), [("static", 3.0, ("at", 90)), ("fire", 8.0, "rifleman")])
        d.line((-15.2, 8.6), (-4.8, 8.6), [("fire", 5.0, "rifleman")])
        d.tower(19.8, -14.8, 135, search=2.5)
        d.bunker(-14.0, -15.4, 180, search=2.0, role="at")
        d.chicane(-3.1, -12.4, 180, step=5.5)
        d.wire((-15.0, -17.0), (17.0, -17.0), gap=(7.0, 17.0))
        d.hogs(-3.0, -24.0, 90, n=4)
        d.hogs(10.0, -22.0, 90, n=3)


def main(args):
    maps = "-m" in args
    tier = None
    if "-t" in args:
        tier = int(args[args.index("-t") + 1])
        args = args[:args.index("-t")] + args[args.index("-t") + 2:]
    names = [a for a in args if a != "-m"] or TOWNS
    towns = tl.load()
    bad = 0
    for name in names:
        t = towns[name]
        tiers, notes = draft(t, dict(SITES[name]))
        problems = tl.check(t, tiers)
        counts = " / ".join(f"T{i}: {len(it)} things, {sum(1 for x in it if x[0] == 'guard')} g, {sum(1 for x in it if x[0] == 'static')} s" for i, it in enumerate(tiers, 1))
        print(f"{name}: {counts}")
        for n in notes:
            print("   ", n)
        if maps:
            print(cmap(t, tiers[(tier or len(tiers)) - 1]))
        if problems:
            bad += 1
            print(f"  PROBLEMS {problems}")
            continue
        tl.write(t, tiers)
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
