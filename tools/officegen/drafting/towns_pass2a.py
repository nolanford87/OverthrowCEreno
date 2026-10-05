"""
Pass 2a of the towns' mayor's office layouts (tools/officegen/review/towns/PASS2A_GATES.md): where the gates go. Each
town starts from the user's reviewed tiers (townlib.baseline()), never from pass 1's script: the only changes are
the gates' openings cut into the walls (pieces taken out of a line or swapped for shorter ones, so the line ends
cleanly at the opening), their markers (townlib.gate()), and the review points the brief names (Chalkeia's way
out, Agios Dionysios's disjointed line, more room inside Kalochori's T3-T4 ring). Run from the repository root:
    python tools/officegen/drafting/towns_pass2a.py [town ...] [-m] [-t N] [-n]
    (all towns without names; -m maps of each tier 3+, -t only that tier's map, -n dry run: nothing written)

The closure check (closure()) is pass 1's leak() walk (drafting/towns.py) on the edited snapshot: a 0.5 m man on a
0.5 m grid from the veranda and the side door, through neither the probe's buildings, real walls and rocks (the
map objects a tier hides left out) nor any wall, H-barrier or sandbag of the tier, out to 43 m. Per tier 3+:
  - every gate shut (a block across its opening): no way out (the gates are the only ways out);
  - every gate open: out, and each gate's opening is walked through (its middle and a metre either side of it are
    reached);
  - each ring alone with its gate shut, at tier 4 (the outer ring without the inner one): no way out.

Model coordinates throughout: x right, y towards the office's back (its front, -y, is down on the maps); the
veranda and the main door face -x (left).
"""
import collections
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)
import townlib as tl  # noqa: E402
import towns as p1  # noqa: E402  (pass 1's drafting: the building trims, real_wall(), the house's walls)

TOWNS = ["Agios Dionysios", "Chalkeia", "Charkia", "Kalochori", "Neochori", "Panochori", "Paros", "Rodopoli",
         "Sofia", "Therisa"]

HB5, HB3, HB1 = "Land_HBarrier_5_F", "Land_HBarrier_3_F", "Land_HBarrier_1_F"
WALL, CNC1 = "Land_Mil_WallBig_4m_F", "Land_CncWall1_F"
LONG, SHORT = "Land_BagFence_Long_F", "Land_BagFence_Short_F"
# Solid sizes [length, depth] (pass 1's: the measured boxes less their slack). The walk blocks on these (the
# smaller, the stricter); an opening's width is measured between the solid ends either side of it.
SIZE = {HB5: (5.4, 1.76), HB3: (3.2, 1.76), HB1: (1.1, 1.7), WALL: (3.7, 0.8), CNC1: (1.0, 0.6),
        LONG: (3.0, 0.5), SHORT: (1.8, 0.5)}
# Round 2 (the in-game check): every gate at least 3.5 m wide, a man's gate too: the engine's path finding (the
# defenders', the QRF's) doesn't get through narrower openings (1.5, 2.0 and 2.2 m gates came back closed)
GATE = 3.6     # An opening's width (m): 3.6-4.2 where the pieces fit better


def vec(mdir):
    return (math.sin(math.radians(mdir)), math.cos(math.radians(mdir)))


# ---------------------------------------------------------------- the snapshot in model coordinates

class Piece:
    """An item of a snapshot seen in model coordinates (x, y, mdir; z above the ground under it)."""

    def __init__(self, t, it):
        self.it = it
        self.kind, self.cls = it[0], it[1]
        m = t.to_model(it[2])
        self.x, self.y = m[0], m[1]
        self.z = m[2] - t.ground_model(m[0], m[1])
        if self.kind == "guard":
            yaw = it[3]
        else:
            yaw = math.degrees(math.atan2(it[3][0][0], it[3][0][1]))
        self.mdir = (yaw - t.dir) % 360
        self.ln, self.dp = SIZE.get(self.cls, (0.6, 0.6))
        if self.kind == "gate":
            self.ln, self.dp = float(self.cls), 1.0

    @property
    def wall(self):
        return self.kind == "object" and self.cls in SIZE

    def ends(self):
        """The two ends of the piece's solid length (model x, y)."""
        a = vec(self.mdir + 90) if self.kind != "gate" else vec(self.mdir)
        h = self.ln / 2
        return (self.x - a[0] * h, self.y - a[1] * h), (self.x + a[0] * h, self.y + a[1] * h)

    def box(self):
        """(x, y, length, depth, facing) for the overlap tests."""
        face = self.mdir if self.kind != "gate" else (self.mdir - 90) % 360
        return (self.x, self.y, self.ln, self.dp, face)

    def __repr__(self):
        return f"{self.cls.replace('Land_', '')}@({self.x:.2f},{self.y:.2f}) d{self.mdir:.0f} z{self.z:.1f}"


def pieces(t, items):
    return [Piece(t, it) for it in items]


def find(t, items, x, y, cls=None, r=0.35, high=None):
    """The item of a snapshot at model (x, y) (within r m; of class cls; high: True a stacked piece, False one on the
    ground, None either). Asserts exactly one."""
    got = [it for it in items if it[0] == "object" and (cls is None or it[1] == cls)]
    out = []
    for it in got:
        p = Piece(t, it)
        if math.hypot(p.x - x, p.y - y) <= r and (high is None or (p.z > 1.0) == high):
            out.append(it)
    assert len(out) == 1, f"{t.name}: {len(out)} pieces at {(x, y)} ({cls}): {[Piece(t, i) for i in out]}"
    return out[0]


def remove(t, items, *where):
    """The snapshot less the pieces at each (x, y[, cls[, high]])."""
    gone = []
    for w in where:
        it = find(t, items, w[0], w[1], *(w[2:]))
        gone.append(it)
    return [it for it in items if not any(it is g for g in gone)], gone


def ground_piece(t, cls, x, y, mdir):
    return tl.obj(t, cls, x, y, mdir=mdir)


def like(t, it, cls, x, y):
    """A piece of class cls at model (x, y), turned and set as `it` is (on the ground or at its height above it)."""
    p = Piece(t, it)
    if "ground" in it[4] or p.z < 0.5:
        return tl.obj(t, cls, x, y, mdir=p.mdir)
    new = tl.obj(t, cls, x, y, mdir=p.mdir)
    new[2][2] = t.ground(new[2][0], new[2][1]) + p.z  # (a stacked piece: as high above the ground as the one it replaces)
    new[4] = [e for e in it[4]]
    return new


def shift(t, it, along):
    """`it` moved `along` m along its own length (its line), +x of its own frame."""
    p = Piece(t, it)
    a = vec(p.mdir + 90)
    return like(t, it, it[1], p.x + a[0] * along, p.y + a[1] * along)


# ---------------------------------------------------------------- cutting a gate

JOINT = (0.35, 0.7)   # How far a refitted piece overlaps its neighbour's end (solid lengths, as pass 1: 0.45-0.7)
FILL = (HB5, HB3, HB1)
WALL_FILL = (WALL, CNC1, CNC1)


def family(cls):
    return "wall" if cls in (WALL, CNC1) else "bags" if "Bag" in cls else "hb"


def line_of(t, items, x, y, high=False):
    """The pieces of the line nearest model (x, y) on one layer (high: the stacked pieces): the walls, H-barriers and
    bags (of one kind) turned the same way (within 2 degrees) standing on the same line (within 0.3 m of it). Returns (the nearest
    piece, [the line's pieces])."""
    ps = [p for p in pieces(t, items) if p.wall and (p.z > 1.0) == high]
    near = min(ps, key=lambda p: math.hypot(p.x - x, p.y - y))
    nrm = vec(near.mdir)
    off = near.x * nrm[0] + near.y * nrm[1]
    same = [p for p in ps if abs(((p.mdir - near.mdir + 180) % 360) - 180) < 2.0 and abs(p.x * nrm[0] + p.y * nrm[1] - off) < 0.3
            and family(p.cls) == family(near.cls)]
    return near, same


def cut(t, items, x, y, width, high=False, fill=None, relay=(), bare=()):
    """(relay, bare: sides of the opening, each a model point on that side.) A gate's opening `width` m wide cut into the line at model (x, y) (on the stacked layer: high): the pieces in it
    taken out, the stretch either side between the opening and the nearest piece left re-laid with pieces fitted to
    end exactly at the opening's edge (overlapping the piece left by JOINT). Returns (the new snapshot, the opening's
    middle on the line (x, y), the line's direction, [removed pieces], [added pieces])."""
    near, line = line_of(t, items, x, y, high)
    a = vec(near.mdir + 90)
    nrm = vec(near.mdir)
    # Sides given as model points (the side of the opening they lie on) to the line's own signs
    side_of = lambda v: v if isinstance(v, int) else (1 if (v[0] - x) * a[0] + (v[1] - y) * a[1] > 0 else -1)
    relay = tuple(side_of(v) for v in relay)
    bare = tuple(side_of(v) for v in bare)
    off = near.x * nrm[0] + near.y * nrm[1]
    s_mid = x * a[0] + y * a[1]
    cx, cy = a[0] * s_mid + nrm[0] * off, a[1] * s_mid + nrm[1] * off  # The opening's middle, on the line
    s0, s1 = s_mid - width / 2, s_mid + width / 2

    def span(p):
        c = p.x * a[0] + p.y * a[1]
        return c - p.ln / 2, c + p.ln / 2
    gone = [p for p in line if span(p)[0] < s1 - 1e-6 and span(p)[1] > s0 + 1e-6]
    assert gone, f"{t.name}: nothing to cut at {(x, y)}"
    template = gone[0].it
    left = [p for p in line if p not in gone and span(p)[1] <= s0 + 1e-6]
    right = [p for p in line if p not in gone and span(p)[0] >= s1 - 1e-6]
    # The line's far ends either side of the opening (what it ties into there)
    far = {-1: min([span(p)[0] for p in line if span(p)[0] < s0] or [None]) if any(span(p)[0] < s0 for p in line) else None,
           1: max(span(p)[1] for p in line if span(p)[1] > s1) if any(span(p)[1] > s1 for p in line) else None}
    ends = {}
    # A side re-laid whole (relay, or where no piece is left beside the opening), from the line's far end (kept where
    # it was: it ties in there) to the opening, so the pieces fit evenly instead of one odd piece by the gate
    for side, rest in ((-1, left), (1, right)):
        if far[side] is not None and (side in relay or not rest):
            ends[side] = far[side]
            gone += rest
            rest.clear()
    opts = fill or (WALL_FILL if gone[0].cls in (WALL, CNC1) else FILL)
    added = []
    cost = 0.0
    for side, rest in ((-1, left), (1, right)):
        ea = JOINT
        if side in bare:
            gone += rest
            continue  # (the opening's edge on this side is another line's end, or what the line tied into)
        if side in ends:
            edge, ea = ends[side], (0.0, 0.02)
            g = (s0 - edge) if side < 0 else (edge - s1)
        elif not rest:
            continue  # (nothing of the line beyond the opening on this side)
        elif side < 0:
            edge = max(span(p)[1] for p in rest)
            g = s0 - edge
        else:
            edge = min(span(p)[0] for p in rest)
            g = edge - s1
        if g <= 0.05:
            continue
        sol = p1.solve(g, ea, (0.0, 0.02), opts, JOINT)
        if sol is None:
            cost += 5  # (an end overlapping its neighbour by more than JOINT: avoided where the opening can move)
            sol = p1.solve(g, (ea[0], ea[1] + 1.0), (0.0, 0.02), opts, JOINT)
        assert sol, f"{t.name}: can't fill {g:.2f} m beside the opening at {(x, y)}"
        order, ov = sol
        cost += len(order) + sum(2.0 for c in order if c in (HB1, CNC1))
        # Laid from the piece left (overlapping its end by ov[0]) towards the opening, the last piece ending at
        # its edge
        s = edge + side * ov[0]
        for k, cls in enumerate(order):
            ln = p1.SIZE[cls][0]
            c = s - side * ln / 2
            added.append(like(t, template, cls, a[0] * c + nrm[0] * off, a[1] * c + nrm[1] * off))
            joint = ov[k + 1] if k + 1 < len(order) else 0
            s = s - side * (ln - joint)
    out = [it for it in items if not any(it is p.it for p in gone)] + added
    cut.cost = cost + 0.3 * len(gone)
    return out, (cx, cy), (near.mdir + 90) % 360, gone, added


# ---------------------------------------------------------------- the walk

class Site:
    def __init__(self, t, items):
        self.t = t
        self.items = items
        self.removed = t.removed_objs(items)
        self.small = {o["model"] for o in t.objs if o["kind"] == "building" and max(o["box"][2] - o["box"][0], o["box"][3] - o["box"][1]) < 2.5}
        self.ps = [p for p in pieces(t, items) if p.wall]
        self.gates = [p for p in pieces(t, items) if p.kind == "gate"]

    def probe_shut(self, x, y, s=0.4):
        t = self.t
        w = t.to_world(x, y, 0)
        for h in t.hits(w[0], w[1], s, s, t.dir, 0.0, removed=self.removed):
            if h[0] in ("building", "part", "rock") and h[1] not in self.small:
                return True
            if h[0] == "wall" and p1.real_wall(h[1]):
                return True
        return False


def overlap(p, q):
    return p1.Drafter.boxes_overlap(p1.Drafter, p, q, 0)


def closure(t, items, shut=None, held=(), r=43.0, step=0.5):
    """The walk out (see the module's docstring). shut: the gate items with a block across their opening (None: all
    of the snapshot's). held: boxes (x, y, length, depth, facing) that stop the walk where the game's check found the
    user's line closed though this walk doesn't (HELD). Returns (the way out as model points or [], the cells reached)."""
    site = Site(t, items)
    bars = [p.box() for p in site.ps] + list(held)
    for g in site.gates:
        if shut is None or any(g.it is s for s in shut):
            bars.append((g.x, g.y, g.ln + 0.4, 1.5, (g.mdir - 90) % 360))
    n = int(r / step)
    cache = {}

    def shut(i, j):
        if (i, j) in cache:
            return cache[(i, j)]
        x, y = i * step, j * step
        v = p1.in_house(x, y, 0.2) or site.probe_shut(x, y) or any(
            abs(b[0] - x) < 8 and abs(b[1] - y) < 8 and overlap((x, y, 0.4, 0.4, 0), b) for b in bars)
        cache[(i, j)] = v
        return v
    sd = t.door("side")
    sx, sy = sd["model"][0] + vec(sd["mdir"])[0] * 1.2, sd["model"][1] + vec(sd["mdir"])[1] * 1.2
    # The veranda (the main door's porch: a few spots on it, as the bags on it vary) and outside the side door
    start = [(round(px / step), round(py / step)) for px, py in ((-3.3, -5.0), (-2.5, -5.5), (-2.5, -3.0), (-2.5, -7.0), (sx, sy))]
    prev = {}
    q = collections.deque()
    for c in start:
        if c not in prev and not shut(*c):
            prev[c] = None
            q.append(c)
    out = []
    while q:
        c = q.popleft()
        if c[0] * c[0] + c[1] * c[1] >= n * n:
            if not out:
                path, k = [], c
                while k is not None:
                    path.append((k[0] * step, k[1] * step))
                    k = prev[k]
                out = path[::-1]
            continue
        for dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb = (c[0] + dc[0], c[1] + dc[1])
            if nb in prev or shut(*nb):
                continue
            prev[nb] = c
            q.append(nb)
    return out, {(i * step, j * step) for i, j in prev}


def gate_walked(t, g, reached, step=0.5):
    """Whether the walk passed through gate g: its middle and a metre either side of the line reached."""
    nrm = vec(g.mdir + 90)

    def near(px, py):
        return any(math.hypot(px - cx, py - cy) <= 0.36 for cx, cy in
                   ((round(px / step) * step + dx * step, round(py / step) * step + dy * step) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
                   if (cx, cy) in reached)
    return all(near(g.x + nrm[0] * k, g.y + nrm[1] * k) for k in (-1.2, 0.0, 1.2))


def opening(t, items, g, held=()):
    """The gate's opening as cut: the free width along its line between the nearest barriers either side (a 0.1 m
    probe walked out from its middle, 0.6 m deep), (left, right) in metres from the middle."""
    site = Site(t, items)
    a = vec(g.mdir)
    out = []
    for sgn in (-1, 1):
        s = 0.0
        while s < 8:
            x, y = g.x + a[0] * s * sgn, g.y + a[1] * s * sgn
            if p1.in_house(x, y) or site.probe_shut(x, y, 0.1) or any(overlap((x, y, 0.1, 0.6, (g.mdir - 90) % 360), b) for b in [p.box() for p in site.ps] + list(held)):
                break
            s += 0.05
        out.append(round(s, 2))
    return out


# ---------------------------------------------------------------- maps

def cmap(t, items, r=44, step=1, path=()):
    """Top-down, model coordinates (up = +y): O house, # building, = real wall, - low wall or fence, t tree, r rock,
    : road, x a map object hidden; M high wall, W 2-high H-barrier, w H-barrier, b bags, G a gate's opening,
    * the way out."""
    removed = t.removed_objs(items)
    marks = {}
    for p in pieces(t, items):
        if p.kind == "gate":
            a = vec(p.mdir)
            for k in range(-int(p.ln * 2), int(p.ln * 2) + 1):
                s = k / 4
                if abs(s) <= p.ln / 2:
                    marks[(round((p.x + a[0] * s) / step), round((p.y + a[1] * s) / step))] = "G"
            continue
        if not p.wall:
            continue
        c = "M" if p.cls in (WALL, CNC1) else "b" if "Bag" in p.cls else ("W" if p.z > 1.0 else "w")
        a, f = vec(p.mdir + 90), vec(p.mdir)
        for i in range(-int(p.ln * 2), int(p.ln * 2) + 1):
            s = i / 4
            if abs(s) > p.ln / 2:
                continue
            for j in range(-int(p.dp * 2), int(p.dp * 2) + 1):
                q = j / 4
                if abs(q) > p.dp / 2:
                    continue
                key = (round((p.x + a[0] * s + f[0] * q) / step), round((p.y + a[1] * s + f[1] * q) / step))
                if marks.get(key) not in ("G", "W") or c == "W":
                    marks[key] = c
    for x, y in path:
        marks[(round(x / step), round(y / step))] = "*"
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
                gone = t.hits(w[0], w[1], step * 0.9, step * 0.9, t.dir, 0, removed=removed)
                c = {"building": "#", "wall": "=" if p1.real_wall(hit[0][1]) else "-", "tree": "t", "rock": "r", "part": "O"}.get(hit[0][0], "?") if gone else "x"
            if p1.in_house(x, y):
                c = "O"
            c = marks.get((i, j), c)
            row += c
        rows.append(row)
    rows.append("     " + "".join(("|" if i % 10 == 0 else " ") for i in range(-r // step, r // step + 1)) + f"  (| every 10 m, x from -{r})")
    return "\n".join(rows)


def setup(name, towns=None):
    """The probed town (pass 1's building trims applied, as its rings were fitted to them) and its baseline."""
    t = (towns or tl.load())[name]
    for model, near, metres in p1.SITES.get(name, {}).get("trims", ()):
        p1.trim(t, model, near, metres)
    return t, tl.baseline(t)


# ---------------------------------------------------------------- the towns

class Draft:
    """A town's tiers from its baseline, with the gates cut so far: per tier, its rings' gates and the pieces cut."""

    def __init__(self, t, base):
        self.t = t
        self.tiers = [list(items) for items in base]
        self.rings = {}   # tier: {ring name: [gate items]}
        self.log = {}     # tier: [text] (what was cut, for the report)
        self.held = {}    # tier: [boxes] where the game held the user's line (HELD)

    def gate(self, n, ring, x, y, width, high=(False,), relay=(), bare=(), fill=None, slack=0.0, what=""):
        """A gate `width` m wide cut at model (x, y) in tier n's line there (each layer in `high`), marked."""
        t = self.t
        if slack or relay == "auto":
            # The opening moved along its line by up to `slack` m to where the pieces either side fit best
            near, _ = line_of(t, self.tiers[n - 1], x, y, False)
            a = vec(near.mdir + 90)
            best = None
            w0 = width
            near0, _ = line_of(t, self.tiers[n - 1], x, y, False)
            a0 = vec(near0.mdir + 90)
            ends = [(x - a0[0] * 50, y - a0[1] * 50), (x + a0[0] * 50, y + a0[1] * 50)]
            for rl in ([(), (ends[0],), (ends[1],), (ends[0], ends[1])] if relay == "auto" else [relay]):
                for w in [w0 + 0.1 * k for k in range(0, 7)]:
                    for k in range(-int(slack * 10), int(slack * 10) + 1):
                        sx, sy = x + a[0] * k * 0.1, y + a[1] * k * 0.1
                        try:
                            cost = 0
                            items = self.tiers[n - 1]
                            for h in high:
                                items = cut(t, items, sx, sy, w, high=h, relay=rl, bare=bare, fill=fill)[0]
                                cost += cut.cost
                        except AssertionError:
                            continue
                        cost += abs(k) * 0.1 + abs(w - w0) * 1.0
                        if best is None or cost < best[0]:
                            best = (cost, sx, sy, rl, round(w, 2))
            x, y, relay, width = best[1:]
        items = self.tiers[n - 1]
        removed, added = [], []
        for h in high:
            items, mid, ldir, gone, new = cut(t, items, x, y, width, high=h, relay=relay, bare=bare, fill=fill)
            removed += gone
            added += [Piece(t, it) for it in new]
        g = tl.gate(t, mid[0], mid[1], width, ldir)
        items.append(g)
        self.tiers[n - 1] = items
        self.rings.setdefault(n, {}).setdefault(ring, []).append(g)
        self.log.setdefault(n, []).append(dict(ring=ring, at=mid, width=width, dir=ldir, what=what, removed=removed, added=added, relay=relay, bare=bare, fill=fill))
        return g

    def mark(self, n, ring, x, y, width, ldir, removed=(), added=(), what=""):
        """A gate's marker where the opening was cut by hand (removed: the pieces taken out, by model point)."""
        t = self.t
        items = self.tiers[n - 1]
        gone = [find(t, items, *w) for w in removed]
        self.tiers[n - 1] = [it for it in items if not any(it is g for g in gone)] + list(added)
        g = tl.gate(t, x, y, width, ldir)
        self.tiers[n - 1].append(g)
        self.rings.setdefault(n, {}).setdefault(ring, []).append(g)
        self.log.setdefault(n, []).append(dict(ring=ring, at=(x, y), width=width, dir=ldir, what=what, removed=[Piece(t, g_) for g_ in gone],
                                               added=[Piece(t, a) for a in added], relay=(), bare=(), fill=None, hand=removed))
        return g

    def keep(self, n, frm):
        """Tier n keeps tier `frm`'s gates (its ring stands there too): the same cut made in tier n's line."""
        for e in list(self.log.get(frm, [])):
            if "hand" in e:
                self.mark(n, e["ring"], e["at"][0], e["at"][1], e["width"], e["dir"], removed=e["hand"], what=e["what"] + f" (kept from T{frm})")
                continue
            self.gate(n, e["ring"], e["at"][0], e["at"][1], e["width"], high=self._layers(n, e["at"]), relay=e["relay"], bare=e["bare"], fill=e["fill"],
                      what=e["what"] + f" (kept from T{frm})")

    def _layers(self, n, at):
        """The layers of tier n's line at a point: (False,) or (False, True) where it's stacked 2-high."""
        ps = [p for p in pieces(self.t, self.tiers[n - 1]) if p.wall and math.hypot(p.x - at[0], p.y - at[1]) < 3.5]
        return (False, True) if any(p.z > 1.0 for p in ps) else (False,)


def verify(t, d):
    """The draft's closure, per tier 3+ (see the module's docstring): [problems], [lines of text]."""
    bad, out = [], []
    for n in range(3, len(d.tiers) + 1):
        items = d.tiers[n - 1]
        held = d.held.get(n, [])
        rings = d.rings.get(n, {})
        gates = [g for gs in rings.values() for g in gs]
        if not gates:
            bad.append(f"T{n}: no gate")
            continue
        path, _ = closure(t, items, shut=None, held=held)
        if path:
            bad.append(f"T{n}: out with every gate shut, by {[(round(x, 1), round(y, 1)) for x, y in path[::max(1, len(path) // 8)]]}")
        path, reached = closure(t, items, shut=[], held=held)
        if not path:
            bad.append(f"T{n}: no way out through the gates")
        for g in gates:
            p = Piece(t, g)
            if not gate_walked(t, p, reached):
                bad.append(f"T{n}: the gate at ({p.x:.1f}, {p.y:.1f}) isn't walked through")
            w = opening(t, items, p, held)
            out.append(f"T{n}: gate at ({p.x:.1f}, {p.y:.1f}) {p.ln:.1f} m: open {w[0] + w[1]:.2f} m across ({w[0]:.2f} / {w[1]:.2f} either side of its middle)")
        if len(rings) > 1:
            for ring, gs in rings.items():
                path, _ = closure(t, items, shut=gs, held=held)
                if path:
                    bad.append(f"T{n}: out with the {ring} ring's gates shut, by {[(round(x, 1), round(y, 1)) for x, y in path[::max(1, len(path) // 8)]]}")
    return bad, out


SITES = {}


def site(name):
    def deco(fn):
        SITES[name] = fn
        return fn
    return deco


def box(x0, y0, x1, y1):
    """A held box (HELD) between two model points, 0.6 m thick."""
    return ((x0 + x1) / 2, (y0 + y1) / 2, math.hypot(x1 - x0, y1 - y0), 0.6, (math.degrees(math.atan2(x1 - x0, y1 - y0)) - 90) % 360)


@site("Neochori")
def neochori(d):
    # The main road runs north-south right along the west face; the veranda's door bay (y -7..-4.3) opens west onto
    # it. T3: the gate in the west face square in front of the bay, a vehicle's width onto the road. T4: the user's
    # T4 keeps only the west face of the T3 ring (stacked 2-high as the outer line along the road), so it is one ring
    # and keeps the same gate, cut through both layers.
    d.gate(3, "inner", -7.0, -4.6, GATE, relay=((-7.0, -20.0),), bare=((-7.0, 10.0),),
           what="west face, onto the main road, square in front of the veranda's door bay")
    d.keep(4, 3)
    # (The user's two angled walls at the north-east end (8.96, 27.40)-(10.96, 24.29) tie into the north shop's real
    # south-west wall, 0.5 m inside its probed box; pass 1's trim of that box (3.5 m) was too deep there, so this walk
    # goes round the walls' end. Held along the box's untrimmed face.)
    d.held[4] = [box(9.5, 24.4, 22.3, 18.1)]


@site("Paros")
def paros(d):
    # A track runs north-south along the west face (from the main road south-west); the veranda's door bay opens
    # west. T3: the gate in the west face in front of the door bay, a vehicle's width onto the track. T4: the user's
    # T4 drops the T3 ring's west and north faces (one ring: the high walls west of the track, the old houses and city
    # walls, and the T3 ring's south-east runs stacked): its gate is in the south wall where the track comes up from
    # the main road, a vehicle's width, the track then running up inside the walls to the office.
    d.gate(3, "inner", -9.5, -4.6, GATE, what="west face, onto the track, in front of the veranda's door bay")
    d.gate(4, "outer", -12.75, -15.8, GATE, slack=1.0, what="south wall, across the track's mouth on the main road")
    # Round 2: T4 got out east (the side door's yard and the north yard open east onto open ground, and the big
    # houses beyond don't close it) and north (round the big north house's end, which is a way through: the north
    # yard side has a door). Both were in the baseline: pass 1's T4 relied on the T3 ring inside it, which the
    # user's T4 takes out. Closed on the T3 north face's own line (y 8.8, game-checked closed at T3), raised to high
    # walls: from the track's east side (x -7.3, where a wall runs up into the north wall) across the north of the
    # house to x 16.2, and down along the east house's east wall past its north-east corner. The north yard and the big north house are
    # outside; the track, the veranda, the side door's yard and the alley stay in.
    t = d.t
    items = d.tiers[3]
    items, _, a1 = add_line(t, items, (-7.3, 8.4), (-7.3, 23.4), out=90.0)
    j1 = relay_line.joint
    items, _, a2 = add_line(t, items, (-7.7, 8.8), (16.2, 8.8), out=0.0)
    j2 = relay_line.joint
    items, _, a3 = add_line(t, items, (16.2, 9.2), (16.2, 2.3), out=90.0)
    j3 = relay_line.joint
    d.tiers[3] = items
    d.fixes = {4: [f"T4 (round 2): a wall up the track's east side, x -7.3 from y 8.4 into the north wall (y 23.4): {len(a1)} walls, joints {j1:.2f} m: {a1}",
                   f"T4 (round 2): a wall on the T3 north face's line, y 8.8 from x -7.7 to 16.2: {len(a2)} walls, joints {j2:.2f} m: {a2}",
                   f"T4 (round 2): a wall from there down along the east house's east wall, x 16.2 from y 9.2 to 2.3: {len(a3)} walls, joints {j3:.2f} m: {a3}"]}


def relay_line(t, items, olds, p0, p1_, cls=WALL, out=None):
    """The pieces `olds` (model points of the pieces to replace) re-laid as one straight line of `cls` from model
    point p0 to p1_ (each end flush with the line it meets there), evenly jointed, facing `out`. Returns (the new
    snapshot, [removed], [added])."""
    gone = [find(t, items, x, y, r=0.5) for x, y in olds]
    L = math.hypot(p1_[0] - p0[0], p1_[1] - p0[1])
    u = ((p1_[0] - p0[0]) / L, (p1_[1] - p0[1]) / L)
    ln = p1.SIZE[cls][0]
    n = max(1, math.ceil((L - JOINT[0]) / (ln - JOINT[0])))
    j = (n * ln - L) / (n - 1) if n > 1 else 0.0
    face = out if out is not None else (math.degrees(math.atan2(u[0], u[1])) - 90) % 360
    added = []
    for k in range(n):
        c = k * (ln - j) + ln / 2
        added.append(tl.obj(t, cls, p0[0] + u[0] * c, p0[1] + u[1] * c, mdir=face))
    relay_line.joint = j
    return [it for it in items if not any(it is g for g in gone)] + added, [Piece(t, g) for g in gone], [Piece(t, a) for a in added]


def add_line(t, items, p0, p1_, cls=WALL, out=None):
    """A new straight line of `cls` from model point p0 to p1_, evenly jointed (relay_line with nothing replaced)."""
    return relay_line(t, items, [], p0, p1_, cls, out)


@site("Agios Dionysios")
def agios_dionysios(d):
    # No road within the probe's 60 m: open ground round the compound, the town's middle 50 m west-south-west. The
    # veranda's door bay opens west. T3: the gate in the west face in front of the door bay. T4 (one ring: the user's
    # T4 drops the T3 ring): the gate in the west wall, in line with the door bay. (Round 1 cut them a man's width,
    # 1.5 m: the game's path finding doesn't get through; now 3.6 m like every gate.)
    # The user's review: "a large gap in the wall" at T4's north-west corner, where pass 1 left the line to the big
    # shed's probed faces: pass 1's top view (pass1_check3) shows open ground there, the shed's box running some 6 m
    # past the building on that side (trimmed 4 m here, as pass 1 trimmed the other overstated boxes). The user's
    # four walls across the corner stood with slits between them and stopped short of the north wall: re-laid as one
    # straight wall on the user's line, evenly jointed, from the west wall's top into the north wall's end.
    t = d.t
    p1.trim(t, "Land_u_Shed_Ind_F", (-15.0, 14.5), 4.0)
    items = d.tiers[3]
    olds = [(-18.55, 11.46), (-16.40, 14.55), (-13.71, 17.51), (-11.15, 20.80)]
    (ax, ay), (bx, by) = olds[0], olds[-1]
    L = math.hypot(bx - ax, by - ay)
    u = ((bx - ax) / L, (by - ay) / L)
    # The user's line (through their first and last walls) from where it meets the west wall's line (x -20, inside
    # its top piece, 7.04..10.74) to where it meets the north wall's (y 23, inside its west piece, from -9.62)
    p0 = (-20.0, ay + (-20.0 - ax) * u[1] / u[0])
    p1_ = (ax + (23.0 - ay) * u[0] / u[1], 23.0)
    items, gone, added = relay_line(t, items, olds, p0, p1_, out=(math.degrees(math.atan2(u[0], u[1])) - 90) % 360)
    d.tiers[3] = items
    d.fixes = {4: [f"T4: the north-west corner wall re-laid on the user's line from ({p0[0]:.2f}, {p0[1]:.2f}) on the west "
                   f"wall's line to ({p1_[0]:.2f}, {p1_[1]:.2f}) on the north wall's: {len(added)} walls (were 4), joints "
                   f"{relay_line.joint:.2f} m; removed {gone}; added {added}"]}
    d.gate(3, "inner", -13.0, -5.6, GATE, slack=1.0, relay="auto", what="west face, in front of the veranda's door bay, towards the town")
    d.gate(4, "outer", -20.0, -5.6, GATE, slack=1.0, relay="auto", what="west wall, in line with the door bay, towards the town")


@site("Charkia")
def charkia(d):
    # Tracks all round; the open ground west of the house is a junction of them, and the track from the town's
    # middle (30 m south-west) runs diagonally across the T4 compound's south-west corner. The veranda's door bay opens
    # west. T3: the gate in the west face in front of the door bay, a vehicle's width onto the junction. T4 keeps it
    # (the T3 ring stands); the outer gate is in the south wall where the south-west track crosses it, a vehicle's
    # width, 17 m round the corner from the inner gate: through it, a man crosses the ground between the rings under
    # the inner ring's west face to reach the inner gate.
    d.gate(3, "inner", -12.5, -5.6, GATE, slack=1.0, relay="auto", what="west face, onto the track junction, in front of the veranda's door bay")
    d.keep(4, 3)
    d.gate(4, "outer", -10.5, -22.5, GATE, slack=1.5, relay="auto", what="south wall, where the track from the town's middle crosses it")


@site("Kalochori")
def kalochori(d):
    # The main road runs east-west 7 m south of the house's walled front yard; the lane west of the house runs up from
    # the road to the veranda (open west onto it). The user's T3 makes the lane's old stone wall the ring's west side
    # (the T3 west face taken out: more room inside) and closes the lane's mouth on the road with three 1-high
    # blocks. T3: the gate is that mouth (the three blocks out), a vehicle's width, from the T3 south face's west end
    # to the stone wall's corner: from the road up the lane to the veranda. T4 (one ring: the user's T4 drops the T3
    # ring): the gate in the south wall at the lane's mouth, a vehicle's width, from the west wall's corner.
    # (The walk counts the lane's old stone walls as closed where the user's rings rely on them: the game's check found
    # these rings closed; this walk lets a man over any low wall.)
    t = d.t
    lane = [box(-9.4, -15.3, -9.4, -6.7), box(-9.7, -7.3, -9.7, 1.3), box(-9.9, 0.7, -9.9, 9.3), box(-9.41, -14.79, -17.4, -18.0)]
    d.held[3] = d.held[4] = lane
    d.mark(3, "inner", -7.22, -14.3, 3.7, 90.0, removed=[(-8.46, -14.96), (-7.07, -14.47), (-6.05, -14.05)],
           what="the lane's mouth on the main road (the user's three 1-high blocks out), from the south face's end to the stone wall")
    d.gate(4, "outer", -6.1, -16.4, GATE, slack=0.4, relay="auto", bare=((-20.0, -16.4),), what="south wall, at the lane's mouth on the main road, from the west wall's corner")


@site("Panochori")
def panochori(d):
    # A track runs north-south along the west face, leaving the T4 compound south-west (through the west wall, just
    # north of the big south-west house: towards the town's middle, 40 m south-south-west) and north (through the
    # north wall). T3: the gate in the west face's north half, a vehicle's width onto the track; from it a man walks
    # down the west face to the veranda's door bay. It is there and not square in front of the door bay so that T4
    # can keep it: T4's outer gate is where the track leaves south-west (in line with the door bay), so anyone coming
    # in runs 13 m up the track between the two walls to reach the inner gate.
    d.gate(3, "inner", -8.2, 4.0, GATE, slack=1.0, relay="auto", what="west face's north half, onto the track")
    d.keep(4, 3)
    d.gate(4, "outer", -14.0, -9.25, GATE, relay=((-14.0, 20.0),), bare=((-14.0, -20.0),),
           what="west wall, where the track leaves south-west towards the town's middle, from the big south-west house's wall")


@site("Rodopoli")
def rodopoli(d):
    # The veranda opens west into a big yard walled by old city walls (west and north), the big south-west house and
    # an annexe (south), open only at a 3 m gap in its south side, which pass 1 closed with one H-barrier, and at its
    # north-east corner, closed by a run. South of the gap a passage runs between the houses to the track along the
    # south (the way from the town's middle, 30 m south-west). T3: the gate is that gap (the H-barrier out), 3.1 m
    # between the city wall's end and the annexe: from the track up the passage into the yard, square onto the
    # veranda. T4 keeps it: the user's T4 walls the north and east tracks and the lane in, but the yard's south side
    # stays the outermost line there, so it is T4's one way in too (no second gate: the outer walls have no road of
    # their own to serve that the yard's gate doesn't).
    d.mark(3, "inner", -12.05, -17.0, 3.1, 90.0, removed=[(-12.10, -17.00)],
           what="the yard's south gap (pass 1's H-barrier in it out), onto the passage to the south track")
    d.keep(4, 3)
    # Round 2: T4 got out north-east: up the lane behind the house (the side door opens into it), out of its north
    # end and over the north and east tracks, where the T4 walls stand on the roads (the game's path finding walks
    # through walls on a road). In the baseline: the user's T4 takes out the T3 runs that close the lane (its east
    # side and both ends), which pass 1's T4 relied on. They go back at T4 as they stand at T3 (game-checked there).
    t = d.t
    lane = [it for it in d.tiers[2] if it[0] == "object" and "HBarrier" in it[1] and
            ((Piece(t, it).x > 4.0 and abs(Piece(t, it).y) > 12.0) or abs(Piece(t, it).x - 9.3) < 0.1)]
    d.tiers[3] = d.tiers[3] + [list(it) for it in lane]
    d.fixes = {4: [f"T4 (round 2): the T3 lane runs back, as at T3: {pieces(t, lane)}"]}


@site("Sofia")
def sofia(d):
    # On a corner: the main road runs north-south along the west face and the track east-west along the south face,
    # meeting at the compound's south-west corner (the town's middle lies 18 m south-south-east, on the track). The
    # T2 bags close the veranda's west side, its south end open: the way in is from the south. T3: the gate in the
    # south face square in front of the veranda's south end, a vehicle's width onto the track. T4: the user's T4 takes
    # the T3 south face out and walls the track in (one ring); its gate is in the west wall across the track's mouth
    # on the main road, a vehicle's width: off the main road onto the track inside the walls, then north into the
    # veranda's south end.
    # Round 2: the T3 south-face gate came back closed: every route in the game leaves the veranda down its west
    # steps (-5.8, -6.3), not its south end (a railing), and the strip between the steps and the west face is too
    # tight for the path finding. The gate moves to the west face, square in front of the steps, onto the main road:
    # the H-barrier there out whole, nothing back (4.45 m). T4 doesn't keep it: its one ring already has its gate
    # at the track's mouth (fine in the game), one way in per ring.
    d.mark(3, "inner", -8.6, -4.815, 4.45, 0.0, removed=[(-8.6, -4.82)],
           what="west face, onto the main road, square in front of the veranda's west steps (the H-barrier there out whole)")
    d.gate(4, "outer", -8.6, -16.0, GATE, slack=1.0, relay="auto", what="west wall, across the track's mouth on the main road (3.6 m or more, round 2)")


@site("Therisa")
def therisa(d):
    # Open ground (a plaza) south of the house, the road 22 m beyond it (the town's middle 59 m south); the user's T2
    # bags leave the veranda's west door bay open, beside the 2.7 m passage between the veranda and the west annexe.
    # T3: the gate in the south face across the plaza from the door bay's side, a vehicle's width (vehicles come over
    # the plaza from the road). T4 (one ring: the user's T4 drops the T3 ring's faces): the gate in the south wall on
    # the same line, a vehicle's width, facing the road.
    d.gate(3, "inner", -5.0, -16.0, GATE, slack=1.0, relay="auto", what="south face, across the plaza to the road, in line with the veranda's west side")
    d.gate(4, "outer", -5.2, -24.0, GATE, relay="auto", what="south wall, facing the road across the plaza")
    # Round 2: T4 got out west through the shop west of the house (doors south, onto the plaza, and north), which
    # the user's T4 makes part of its line. In the baseline: the user's T3 west face (x -14.85) shut it out and the
    # T4 drops it. It goes back on the same line as high walls, from beside the south-west building (y -17.6) up
    # to the west annexe (y -5.2, its end in the annexe's wall), the shop and the passage south of it outside.
    t = d.t
    items, _, added = add_line(t, d.tiers[3], (-14.6, -17.6), (-14.6, -5.2), out=270.0)
    d.tiers[3] = items
    d.fixes = {4: [f"T4 (round 2): a wall on the user's T3 west face line, x -14.6 from y -17.6 to -5.2: {len(added)} walls, joints {relay_line.joint:.2f} m: {added}"]}


@site("Chalkeia")
def chalkeia(d):
    # A dead-end track runs down from the north along the west face (the only road within 60 m; it comes in from the
    # north). The veranda's door bay opens west onto it. T3: the gate in the west face square in front of the door
    # bay, a vehicle's width onto the track. T4 (one ring: the user's T4 drops the T3 ring's west, north and south
    # faces): the gate in the north wall where the track comes in, a vehicle's width; the track then runs down
    # inside the walls to the office.
    # The way out (the brief: Chalkeia still got out in the last check, at T4 by elimination: its T3 is pass 1's ring
    # as checked closed plus one more H-barrier): the T4 west wall's top end stopped at the probed box of the
    # big north-west house, which runs 2.3 m past the house's real wall there (the house is the office's own class,
    # whose walls are known): a 2.4 m gap between the wall's end and the house, and the house itself is a way
    # through (doors on two sides, the side door facing the compound). With the T3 ring inside it (pass 1's checks)
    # no route reached it; the user's T4 took that ring out. The west wall is re-laid 1 m east, from its tie into the
    # garage straight up to the north wall, so the corner no longer needs the house; the north wall re-laid from the
    # new corner to its east end (its west piece would have stuck out past the corner).
    t = d.t
    # The house's probed box to its real walls (the office class: x -4.7..5.6, y -7.8..7.8 in its own frame)
    p1.trim(t, "Land_i_House_Big_01_V3_F", (-30.9, 13.5), 2.3)
    p1.trim(t, "Land_i_House_Big_01_V3_F", (-24.55, 23.26), 0.7)
    items = d.tiers[3]
    olds_w = [(-24.0, 13.32), (-24.0, 10.09), (-24.0, 6.85), (-24.0, 4.97), (-24.0, 4.43), (-24.0, 2.55), (-24.0, -0.69), (-24.0, -3.92)]
    items, gone_w, added_w = relay_line(t, items, olds_w, (-23.0, -5.77), (-23.0, 24.4), out=270.0)
    jw = relay_line.joint
    olds_n = [(-22.89, 24.0), (-19.68, 24.0), (-16.48, 24.0), (-14.62, 24.0), (-12.77, 24.0), (-9.56, 24.0), (-6.36, 24.0)]
    items, gone_n, added_n = relay_line(t, items, olds_n, (-23.4, 24.0), (-4.51, 24.0), out=0.0)
    jn = relay_line.joint
    d.tiers[3] = items
    d.fixes = {4: [f"T4: the west wall re-laid at x -23.0 from its tie into the garage (y -5.77) to the north wall (y 24.4): "
                   f"{len(added_w)} walls, joints {jw:.2f} m; removed {gone_w}; added {added_w}",
                   f"T4: the north wall re-laid from the new corner (x -23.4) to its east end (x -4.51): {len(added_n)} walls, "
                   f"joints {jn:.2f} m; removed {gone_n}; added {added_n}"]}
    # Round 2: T3's 3.6 m gate came back closed in the game (round 1 had narrowed the opening with a 1-high block
    # beside it; the door bay's steps come down right behind it): the H-barrier in front of the door bay comes out
    # whole and nothing goes back, a 4.25 m opening between the face's own pieces
    d.mark(3, "inner", -7.0, -6.085, 4.25, 0.0, removed=[(-7.0, -6.09)],
           what="west face, onto the track, square in front of the veranda's door bay (the H-barrier there out whole)")
    # Round 2, T4's ways out:
    # - west through the garage (doors at both ends, the east one onto the track): the T4 west wall tied into the
    #   garage's north face, so the garage was part of the line. A wall along the track's west verge from the
    #   garage's north-east corner down to the south wall shuts the garage and the two shops' east sides out
    #   (they were in the baseline's line: the user's T4 took out the T3 ring that kept men away from them).
    items, gone, added = add_line(t, d.tiers[3], (-17.7, -4.9), (-17.7, -28.4), out=270.0)
    d.tiers[3] = items
    d.fixes[4].append(f"T4 (round 2): a wall along the track's west verge, x -17.7 from the garage's north-east corner "
                      f"(y -4.9) to the south wall (y -28.4), shutting the garage and the shops out: {len(added)} walls, "
                      f"joints {relay_line.joint:.2f} m; added {added}")
    # - north and south along the track: the track runs on through the south wall too (the top view: it doesn't end
    #   at the probe's last point), and the game's path finding walks through walls standing on a road (pass 1,
    #   Kore). So the T4 compound straddles a through road: a gate at each end, the road's width (the second gate's
    #   reason: the occupier's vehicles use the road both ways, and a wall across it doesn't stop them)
    d.gate(4, "outer", -13.0, 24.0, 6.4, slack=0.5, relay="auto", what="north wall, across the track where it comes in from the north (the road's width)")
    d.gate(4, "outer", -10.0, -28.0, 6.0, slack=0.5, relay="auto", what="south wall, across the track where it runs on south (the road's width): the second gate")


# ---------------------------------------------------------------- run

def write(t, base, tiers):
    """townlib.write(), refusing only the problems the draft adds: the user's baseline itself fails two of check()'s
    tests in three towns (hide items for small props the probe doesn't list, at Charkia and Therisa; tier 1's two
    guards at Panochori, which make check() want guards in every tier), which this pass leaves as the user made them."""
    known = tl.check(t, base)
    new = [p for p in tl.check(t, tiers) if p not in known]
    if new:
        raise ValueError(f"{t.name}: " + "; ".join(new))
    check = tl.check
    tl.check = lambda town, ts: []  # (checked just above)
    try:
        return tl.write(t, tiers)
    finally:
        tl.check = check


def pieces_md(ps):
    out = collections.Counter(p.cls.replace("Land_", "").replace("_F", "") for p in ps)
    return ", ".join(f"{n} {c}" for c, n in sorted(out.items()))


def report(t, d, out):
    """The draft's gates as markdown (REPORT_pass2a.md's per-town section)."""
    lines = [f"### {t.name}", ""]
    lines.append("| tier | ring | gate at (model x, y) | width | the line runs | what it faces, why | cut: out / in |")
    lines.append("|---|---|---|---|---|---|---|")
    for n in sorted(d.log):
        for e in d.log[n]:
            gone = sorted(e["removed"], key=lambda p: (p.z > 1.0, p.x, p.y))
            new = sorted(e["added"], key=lambda p: (p.z > 1.0, p.x, p.y))
            lines.append(f"| T{n} | {e['ring']} | ({e['at'][0]:.2f}, {e['at'][1]:.2f}) | {e['width']:.1f} m | {e['dir'] % 180:.0f} deg | {e['what']} | "
                         f"{len(gone)} out ({pieces_md(gone)}): {', '.join(f'({p.x:.2f}, {p.y:.2f})' + (' 2nd layer' if p.z > 1.0 else '') for p in gone)}; "
                         f"{len(new)} in ({pieces_md(new) or 'none'}) |")
    lines.append("")
    for n, fx in sorted(getattr(d, "fixes", {}).items()):
        for f in fx:
            lines.append(f"- {f}")
    lines += [f"- {o}" for o in out]
    for n, hb in sorted(d.held.items()):
        lines.append(f"- T{n}: the walk holds {len(hb)} box(es) the game's check found closed (see the script)")
    return "\n".join(lines) + "\n"


def main(args):
    dry = "-n" in args
    maps = "-m" in args
    only = None
    if "-t" in args:
        only = int(args[args.index("-t") + 1])
        args = args[:args.index("-t")] + args[args.index("-t") + 2:]
    md = "-r" in args
    names = [a for a in args if not a.startswith("-")] or TOWNS
    towns = tl.load()
    bad = 0
    sections = []
    for name in names:
        t, base = setup(name, towns)
        d = Draft(t, base)
        SITES[name](d)
        problems, out = verify(t, d)
        print(f"{name}:")
        for n, es in sorted(d.log.items()):
            for e in es:
                print(f"  T{n} {e['ring']} gate at ({e['at'][0]:.2f}, {e['at'][1]:.2f}), {e['width']:.1f} m: {e['what']}")
        for o in out:
            print("   ", o)
        if maps:
            for n in range(3, len(d.tiers) + 1):
                if only in (None, n):
                    print(f"  T{n}:")
                    print(cmap(t, d.tiers[n - 1]))
        for p in problems:
            print("  PROBLEM", p)
        if problems:
            bad += 1
            continue
        if md:
            sections.append(report(t, d, out))
        if not dry:
            write(t, base, d.tiers)
    if md:
        print("\n".join(sections))
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
