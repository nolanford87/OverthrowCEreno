"""
The hamlets' mayor's office layouts (2 tiers), all on Land_i_Stone_HouseBig (V1-V3): a two-storey stone village
house, front door in the south wall (model -y) at x 3, an outside stair on the east (+x) up to a landing at
x ~6, y 1-4 on the upper floor, one real window upstairs right over the front door (x 3.1). The real walls run
x -2.5..5.5, y -2.5..6.5 (the probed box is far wider). Run from the repository root:
    python tools/officegen/drafting/hamlets2.py [-m] [town ...]     (all of the group without names; -m: site maps)

The ladder (designed once for this house, fitted per site):
  T1  a police post: the office (desk facing the door, the chair behind it, the map board), the flag at the
      front-east corner, a gendarme on the door outside (the visible police presence), one inside at the back
      of the room. 2 guards.
  T2  the door held, and visibly so from the street (round 1: a C and a bag were lost in the scene):
      - a C-shaped sandbag nest (a long bag facing out, short wings back to the house) west of the door, square
        with the front, a rifleman and an autorifleman 1 m behind it;
      - an H-barrier blast wall across the door's axis 3-4 m out, so the doorway sits in a fortified pocket: the
        way in is a 1 m gap between the blast wall and the nest (every visitor passes the nest at arm's length),
        the east side shut by a bag in front of the gendarme sentry, the flag and the stair;
        The blast wall is two H-barriers high (3.2 m): the tall mark of the held door (round 2: height).
      - a post on the main approach, on a sandbag tower (its rifleman on the platform): where a road passes within
        24 m, a checkpoint on it (a concrete chicane across the road, two-barrier blocks from each edge 7 m apart,
        the tower beside it on the house's side, the occupier's flag); otherwise the tower off the front-east
        corner, its field crossing the nest's in front of the blast wall;
      - a short razor-wire run on the most open flank (west or back), so attackers are channelled to the front;
      - a marksman at the upstairs window over the door; a rifleman on the stair's landing over the east side.
      7 guards; the fortification footprint about triples.
Where the site forbids the nest in front (a road, a wall or a building right there), the nest goes to the side
of the house the threat comes from, still square with the house, still covering the door.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

TOWNS = ["Agia Triada", "Agios Petros", "Anthrakia", "Athanos", "Delfinaki", "Ekali", "Feres", "Frini", "Ifestiona",
         "Ioannina", "Kalithea", "Katalaki", "Koroni", "Negades", "Oreokastro", "Orino", "Panagia", "Syrta"]

WALLS = (-2.5, -2.5, 5.5, 6.5)       # The house's real walls (model)
STAIR = (5.4, -2.8, 7.4, 6.8)        # The outside stair and its landing: kept clear on the ground
DOOR_LANE = (2.45, 3.6)              # The front door's walkway (x), kept clear straight out from the door
UP_WINDOW = (3.1, -1.35)             # Standing spot behind the upstairs window over the door (window at x 3.12)
LANDING = (6.0, 2.5)                 # On the stair's landing


def size_of(kind, what):
    if kind == "object":
        c = tl.CLASSES.get(what, (0.6, 0.6))
        m = getattr(tl, "MEASURED", {}).get(what)
        if m and "BagFence" not in what:  # The in-game boxes (upper bounds) for the clearances of the new pieces
            return (max(c[0], m[0]), max(c[1], min(m[1], 2.2)))
        return c
    return (2.0, 2.0) if kind == "static" else (0.5, 0.5)


class Site:
    """A town's office site: what's free on the ground, and the things placed so far."""

    def __init__(self, t):
        self.t = t
        self.placed = []  # (x, y, length, depth, mdir)

    def blocked(self, kind, what, x, y, mdir, road_ok=False):
        """Why a ground footprint can't go here ('' when it can). road_ok: True anywhere on a road, "edge" with its
        centre at most 1 m inside the road's edge."""
        t = self.t
        if math.hypot(x, y) > 43.5:
            return "far"
        ln, dp = size_of(kind, what)
        w = t.to_world(x, y, 0)
        hl, hd = ln, dp
        if kind == "object" and tl.is_barrier(what):  # The check's rule: a barrier may overlap the neighbours a little
            hl, hd = max(ln - 2 * tl.BARRIER_OVERLAP, 0.2), max(dp * 0.5, 0.2)
        for h in t.hits(w[0], w[1], hl, hd, (t.dir + mdir) % 360, 0.1 if hl < ln else 0.25):
            if h[0] in ("building", "part", "rock", "wall") or (h[0] == "tree" and (kind != "object" or "Razorwire" in what)):
                return h[0]
        if t.on_office(x, y, ln, dp, mdir):
            return "office"
        pts = samples(x, y, ln, dp, mdir, 0.05)
        for box in (WALLS, STAIR):  # The real house and the stair (the plan's half-cell give lets things touch the walls)
            if any(box[0] < px < box[2] and box[1] < py < box[3] for px, py in pts):
                return "house"
        if road_ok == "edge":
            if road_depth(t, x, y) > 1.0:
                return "road"
        elif not road_ok:
            for px, py in samples(x, y, ln, dp, mdir, 0.0, 3):
                pw = t.to_world(px, py, 0)
                if t.on_road(pw[0], pw[1]):
                    return "road"
        mine = samples(x, y, ln, dp, mdir, 0.15)
        for px, py, pl, pd, pm in self.placed:
            if any(in_rect(qx, qy, px, py, pl, pd, pm) for qx, qy in mine) or \
               any(in_rect(qx, qy, x, y, ln, dp, mdir) for qx, qy in samples(px, py, pl, pd, pm, 0.15)):
                return "placed"
        return ""

    def take(self, kind, what, x, y, mdir):
        ln, dp = size_of(kind, what)
        self.placed.append((x, y, ln, dp, mdir))

    def put(self, kind, what, x, y, mdir, z=None):
        t = self.t
        if z is None:
            self.take(kind, what, x, y, mdir)
        if kind == "guard":
            return tl.guard(t, what, x, y, z, mdir)
        return tl.obj(t, what, x, y, z, mdir, flag=(what == "Flag_NATO_F"))


def samples(x, y, ln, dp, mdir, inset=0.0, n=3):
    """Points over a footprint turned to model direction mdir (its length along the turned x): an n x n grid."""
    out = []
    hl, hd = max(ln / 2 - inset, 0.05), max(dp / 2 - inset, 0.05)
    for i in range(n):
        for j in range(n):
            a = -hl + 2 * hl * i / (n - 1)
            b = -hd + 2 * hd * j / (n - 1)
            dx, dy = tl.rot(a, b, mdir)
            out.append((x + dx, y + dy))
    return out


def in_rect(px, py, x, y, ln, dp, mdir):
    a, b = tl.rot(px - x, py - y, -mdir)
    return abs(a) <= ln / 2 and abs(b) <= dp / 2


def road_depth(t, x, y):
    """How far a model point is inside the nearest road (negative: outside it)."""
    w = t.to_world(x, y, 0)
    near = t.roads_near(w[0], w[1], 20)
    return max((s["width"] / 2 - d for d, s in near), default=-99)


def mdir_along(u):
    """The model direction that lays a piece's length along the model vector u."""
    return math.degrees(math.atan2(-u[1], u[0])) % 360


# ---- the nest: a C of sandbags, square with the house, facing out from one of its sides

def nest_parts(cx, cy, face):
    """A C nest whose front bag is centred on (cx, cy) and faces model direction face (0/90/180/270): the long bag,
    two short wings running back from its ends, the two guards 1.05 m behind the front bag."""
    f = (round(math.sin(math.radians(face))), round(math.cos(math.radians(face))))  # Outward
    l = (f[1], -f[0])  # Along the bag
    back = lambda a, b: (cx - f[0] * a + l[0] * b, cy - f[1] * a + l[1] * b)
    wing_dir = (face + 90) % 360
    return [
        ("object", "Land_BagFence_Long_F", (cx, cy), face),
        ("object", "Land_BagFence_Short_F", back(0.97, 1.23), wing_dir),
        ("object", "Land_BagFence_Short_F", back(0.97, -1.23), wing_dir),
        ("guard", "rifleman", back(1.05, -0.6), face),
        ("guard", "autorifleman", back(1.05, 0.6), face),
    ]


def threat_side(t):
    """The side of the house the nearest road lies (model direction 0/90/180/270), the front without a road."""
    o = t.to_world(1.5, 2.0, 0)
    near = t.roads_near(o[0], o[1], 45)
    if not near:
        return None
    best = None
    for d, s in near[:6]:
        for p in (s["beg"], s["end"]):
            m = t.to_model(p)
            if best is None or math.hypot(m[0] - 1.5, m[1] - 2) < best[0]:
                best = (math.hypot(m[0] - 1.5, m[1] - 2), m)
    m = best[1]
    ang = math.degrees(math.atan2(m[0] - 1.5, m[1] - 2.0)) % 360
    return int(round(ang / 90) % 4 * 90)


def place_nest(site, prefer_east=False):
    """The C nest: in front of the house beside the door lane (west first), 2-6 m out; else beside the house on
    the west or the back. Returns (parts, note)."""
    t = site.t
    tries = []
    west = [(x, y, 180, "front, west of the door") for y in (-5.6, -6.1, -5.1, -6.6, -7.2) for x in (-1.4, -1.8, -2.2, -1.0, -0.6, 0.2, 0.6)]
    east = [(x, y, 180, "front, east of the door") for y in (-5.8, -6.4, -7.0) for x in (5.0, 5.5, 6.2)]
    tries += (east + west) if prefer_east else (west + east)
    # Hard against the front wall, its front bag on the road's shoulder (a street right in front of the house)
    tries += [(x, y, 180, "front, west of the door, on the street's edge", True) for y in (-4.7, -4.9, -5.1) for x in (-1.4, -1.8, -1.0, 0.6, 0.2, -0.3)]
    tries += [(x, y, 180, "front, out on the door's axis") for y in (-7.4, -8.2, -9.0) for x in (3.0, 2.0, 4.0)]
    tries += [(x, y, 180, "off the front-west corner") for x in (-4.0, -5.0, -6.5, -7.5, -8.5, -9.5, -10.5, -11.5) for y in (-4.5, -5.5, -3.5, -6.5)]
    tries += [(x, y, 270, "west side, facing west") for x in (-5.6, -6.2, -6.8, -8.0) for y in (0.5, 1.5, -0.5, 2.5, 3.5)]
    tries += [(x, y, 0, "back, facing north") for y in (9.6, 10.2) for x in (1.0, 0.0, 2.5)]
    for x, y, face, note, *road in tries:
        parts = nest_parts(x, y, face)
        if all(not site.blocked(k, w, p[0], p[1], d, road_ok=("edge" if road and k == "object" else False)) and not lane_hit(k, w, p, d) for k, w, p, d in parts):
            site.nest = (x - 1.45, x + 1.45, y, face)
            return [site.put(k, w, p[0], p[1], d) for k, w, p, d in parts], f"nest {note} at ({x:.1f}, {y:.1f})"
    return None, "NO ROOM for the nest"


def lane_hit(kind, what, p, d):
    """Whether a footprint stands in the front door's walkway (straight out to 9 m)."""
    ln, dp = size_of(kind, what)
    return any(DOOR_LANE[0] < qx < DOOR_LANE[1] and -9.0 < qy < -2.5 for qx, qy in samples(p[0], p[1], ln, dp, d, 0.0, 5))


# ---- the tiers

def tier1(site):
    t = site.t
    f0 = t.floors[0]
    out = [
        site.put("object", "Land_TableDesk_F", 1.0, 0.45, 0, z=f0),        # Facing the door, the clerk's side north
        site.put("object", "Land_OfficeChair_01_F", 1.0, 1.55, 0, z=f0),
        site.put("object", "Land_MapBoard_F", 1.0, -1.25, 0, z=f0),        # Inside the front wall, west of the door
        site.put("guard", "gendarme", -0.4, 2.3, 140, z=f0),                 # The back of the room, watching the door
    ]
    notes = []
    # The flag at the front-east corner (reviewed good), else west of the door
    for x, y in ((6.3, -3.4), (6.3, -4.2), (-1.2, -3.6), (-2.0, -4.4)) + tuple((x, y) for x in (-7.0, -8.0, -9.0) for y in (-3.0, -1.0, 1.0)):
        if not site.blocked("object", "Flag_NATO_F", x, y, 180, road_ok=True):
            out.append(site.put("object", "Flag_NATO_F", x, y, 180))
            break
    else:
        notes.append("NO FLAG")
    # The sentry: on the door's east side against the wall, facing out
    for x, y in ((4.4, -3.15), (4.4, -3.6), (1.7, -3.15)):
        if not site.blocked("guard", "gendarme", x, y, 180, road_ok=True):
            out.append(site.put("guard", "gendarme", x, y, 180))
            site.sentry = (x, y)
            break
    else:
        out.append(site.put("guard", "gendarme", 3.8, 1.7, 180, z=f0))  # No room outside: just inside the door
        site.sentry = None
        notes.append("sentry inside (no room at the door)")
    return out, notes


def blast_wall(site):
    """An H-barrier across the door's axis 3-4 m out, never in front of the nest; a clear way in (1 m or more)
    between its end and the nest, so whoever comes in passes the nest at arm's length."""
    cls = "Land_HBarrier_3_F"
    half = size_of("object", cls)[0] / 2
    nest = getattr(site, "nest", None)
    for y in (-6.1, -6.5, -7.0, -5.9):
        for x in (3.3, 3.0, 3.6, 2.7, 2.2, 1.8, 1.2, 0.8):
            if site.blocked("object", cls, x, y, 180, road_ok="edge"):
                continue
            if nest and nest[3] == 180:
                x0, x1 = x - half, x + half
                if x1 > nest[0] and x0 < nest[1]:
                    continue  # It would mask the nest's front
                gap = x0 - nest[1] if nest[1] <= x0 else nest[0] - x1
                if gap < 0.9 or gap > 2.5:
                    continue
            return site.put("object", cls, x, y, 180), f"blast wall at ({x:.1f}, {y:.1f})"
    return None, "NO blast wall (no room in front of the door)"


TOWER = "Land_BagBunker_Tower_F"
TOWER_DECK = 2.8  # The tower's platform above the ground (a guess: the in-game test reports where the man ends up)


def tower_parts(site, x, y, face):
    """A sandbag tower and its rifleman on the platform."""
    z = site.t.ground_model(x, y) + TOWER_DECK
    return [("object", TOWER, (x, y), face, None), ("guard", "rifleman", (x, y), face, z)]


def road_check(site):
    """A checkpoint on the nearest road within 24 m: a concrete chicane across the road (a two-barrier block from
    each edge, 7 m apart, so traffic slaloms through at a crawl), the sandbag tower on the house's side between the
    blocks with a rifleman on its platform over the road, the flag beside it."""
    t = site.t
    c = (1.5, 2.0)
    cw = t.to_world(c[0], c[1], 0)
    cls = "Land_CncBarrier_stripes_F"
    pl = tl.CLASSES[cls][0]
    for d0, seg in t.roads_near(cw[0], cw[1], 24)[:4]:
        a, b = t.to_model(seg["beg"]), t.to_model(seg["end"])
        vx, vy = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(vx, vy) or 1
        u = (vx / ln, vy / ln)
        k = max(0, min(ln, (c[0] - a[0]) * u[0] + (c[1] - a[1]) * u[1]))
        P = (a[0] + u[0] * k, a[1] + u[1] * k)
        n = (-u[1], u[0])
        if (c[0] - P[0]) * n[0] + (c[1] - P[1]) * n[1] < 0:
            n = (-n[0], -n[1])
        half = min(seg["width"], 10) / 2
        across = mdir_along(n)
        face = math.degrees(math.atan2(-n[0], -n[1])) % 360  # Towards the road
        for sh in (0, 3, -3, 6, -6, 9, -9, 12, -12, 15, -15):
            Q = (P[0] + u[0] * sh, P[1] + u[1] * sh)

            def at(off, sl=0.0):
                return (Q[0] + n[0] * off + u[0] * sl, Q[1] + n[1] * off + u[1] * sl)
            tower = at(half + 2.6)
            parts = [(k_, w, p, d, False) for k_, w, p, d, z in tower_parts(site, tower[0], tower[1], face)[:1]]
            parts += [("object", "Flag_NATO_F", at(half + 1.2, -2.6), face, False)]
            near = [("object", cls, at(half - pl / 2 - 0.1, -3.5), across, True), ("object", cls, at(half - 1.5 * pl - 0.1, -3.5), across, True)]
            far = [("object", cls, at(-half + pl / 2 + 0.1, 3.5), across, True), ("object", cls, at(-half + 1.5 * pl + 0.1, 3.5), across, True)]
            ok = lambda ps: all(not site.blocked(kd, w, p[0], p[1], d, road_ok=r) and not lane_hit(kd, w, p, d) for kd, w, p, d, r in ps)
            if not ok(parts) or not ok(near):
                continue
            chicane = far if ok(far) else []
            out = [site.put(kd, w, p[0], p[1], d) for kd, w, p, d, r in parts + near + chicane]
            out.append(tl.guard(t, "rifleman", tower[0], tower[1], tower_parts(site, *tower, face)[1][4], face))
            return out, f"checkpoint {math.hypot(*tower):.0f} m out ({seg['type']}, {seg['width']:.0f} m): tower, flag, {'chicane' if chicane else 'one barrier block (no room across)'}"
    return None, ""


def bunker(site):
    """No road close: a sandbag tower off the front-east corner (else the front-west), its rifleman on the platform
    over the front approach: his field crosses the nest's in front of the blast wall, and it's the tall mark of the
    post seen from afar."""
    for x, y in ((9.5, -6.5), (10.0, -8.5), (8.5, -9.0), (11.0, -5.0), (7.0, -10.5), (10.5, -10.5), (-6.5, -9.5), (-8.0, -8.0),
                 (-7.0, -11.5), (3.0, -12.5), (-11.0, -9.5), (-12.0, -11.0), (-12.5, -1.0)):
        if not site.blocked("object", TOWER, x, y, 180):
            (k1, w1, p1, d1, _), (k2, w2, p2, d2, z2) = tower_parts(site, x, y, 180)
            return [site.put(k1, w1, x, y, 180), tl.guard(site.t, "rifleman", x, y, z2, 180)], f"tower at ({x:.1f}, {y:.1f})"
    return None, "NO tower"


def wire(site):
    """A razor-wire run along the most open flank (west or back), so attackers are channelled to the front."""
    def openness(pts):
        return sum(1 for x, y in pts if not site.blocked("guard", "rifleman", x, y, 0))
    west = openness([(-x, y) for x in range(6, 16, 2) for y in (-1, 2, 5)])
    back = openness([(x, y) for y in range(9, 19, 2) for x in (-1, 1.5, 4)])
    runs = {"west": [(-5.2, y, 90) for y in (2.0, 1.0, 3.0, 0.0)] + [(-6.0, y, 90) for y in (2.0, 1.0, 3.0)],
            "back": [(x, 9.4, 0) for x in (1.5, 0.5, 2.5, -0.5)] + [(x, 10.2, 0) for x in (1.5, 0.5, 2.5)],
            "east": [(x, y, 90) for x in (9.0, 9.8) for y in (3.0, 4.0, 2.0)]}
    order = (["west", "back"] if west >= back else ["back", "west"]) + ["east"]
    for side in order:
        for x, y, d in runs[side]:
            if not site.blocked("object", "Land_Razorwire_F", x, y, d):
                return [site.put("object", "Land_Razorwire_F", x, y, d)], f"wire on the {side} flank"
    return [], "no wire (no clear flank)"


def tier2(site):
    t = site.t
    f1 = t.floors[1]
    out, notes = [], []
    nest, note = place_nest(site, prefer_east=getattr(site, "prefer_east", False))
    notes.append(note)
    if nest:
        out += nest
    bw, note = blast_wall(site)
    notes.append(note)
    if bw:
        out.append(bw)
        m = t.to_model(bw[2])
        out.append(tl.obj(t, "Land_HBarrier_3_F", m[0], m[1], t.ground_model(m[0], m[1]) + 1.75, 180))  # Stacked: 3.2 m high
    # A bag in front of the sentry: the doorway's other flank
    if site.sentry:
        sx, sy = site.sentry
        for dy in (1.1, 1.3, 0.9):
            if not site.blocked("object", "Land_BagFence_Short_F", sx, sy - dy, 180, road_ok="edge") and not lane_hit("object", "Land_BagFence_Short_F", (sx, sy - dy), 180):
                out.append(site.put("object", "Land_BagFence_Short_F", sx, sy - dy, 180))
                notes.append("bag before the sentry")
                break
        else:
            notes.append("no bag before the sentry")
    post, note = road_check(site)
    if not post:
        post, note = bunker(site)
    notes.append(note)
    out += post or []
    w, note = wire(site)
    notes.append(note)
    out += w
    out.append(site.put("guard", "marksman", UP_WINDOW[0], UP_WINDOW[1], 180, z=f1))   # The window over the door
    out.append(site.put("guard", "rifleman", LANDING[0], LANDING[1], getattr(site, "landing_dir", None) or landing_dir(t), z=f1))
    return out, notes


def landing_dir(t):
    """Where the landing's man looks: the nearest road within 35 m (on his side of the house: model 20-170), else
    out over the front-east (150), the way to the door."""
    w = t.to_world(*LANDING, 0)
    best = None
    for d, s in t.roads_near(w[0], w[1], 35):
        a, b = t.to_model(s["beg"]), t.to_model(s["end"])
        for k in range(11):
            px, py = a[0] + (b[0] - a[0]) * k / 10, a[1] + (b[1] - a[1]) * k / 10
            dd = math.hypot(px - LANDING[0], py - LANDING[1])
            if best is None or dd < best[0]:
                best = (dd, px, py)
    if best is None:
        return 150
    ang = math.degrees(math.atan2(best[1] - LANDING[0], best[2] - LANDING[1])) % 360
    if ang > 270:
        ang = 20
    return round(min(max(ang, 20), 170))


def draft(t, opts=None):
    site = Site(t)
    for k, v in (opts or {}).items():
        setattr(site, k, v)
    t1, n1 = tier1(site)
    add, n2 = tier2(site)
    return [t1, t1 + add], n1 + n2


# Per-town fitting (see the notes in main's output): prefer_east puts the nest east of the door first,
# landing_dir turns the landing's man to the side the approach comes from
OPTS = {
}


def site_map(t, items=(), r=18):
    """1 m map in model coordinates, up = the front (-y is DOWN here: the map is printed north-up in model terms,
    so the house's front is at the bottom). H house, s stair, # building, = wall, t tree, r rock, : road;
    items: g guard, b bag, f flag, o other."""
    marks = {}
    for kind, what, p, o, extra in items:
        m = t.to_model(p)
        c = "g" if kind == "guard" else ("S" if kind == "static" else ("f" if "Flag" in what else "K" if "Bunker" in what else ("b" if "Bag" in what else "B" if "HBarrier" in what else "w" if "wire" in what else "c" if "Cnc" in what else "o")))
        if kind == "object" and "ground" in extra:
            ln, dp = size_of(kind, what)
            yaw = math.degrees(math.atan2(o[0][0], o[0][1])) - t.dir
            for qx, qy in samples(m[0], m[1], ln, dp, yaw, 0.2, 5):
                marks.setdefault((round(qx), round(qy)), c)
        marks[(round(m[0]), round(m[1]))] = c
    rows = []
    for y in range(r, -r - 1, -1):
        row = f"{y:4d} "
        for x in range(-r, r + 1):
            w = t.to_world(x, y, 0)
            c = "."
            if t.on_road(w[0], w[1]):
                c = ":"
            hit = t.hits(w[0], w[1], 0.2, 0.2, 0, 0)
            if hit:
                c = {"building": "#", "wall": "=", "tree": "t", "rock": "r", "part": "O"}.get(hit[0][0], "?")
            if WALLS[0] <= x <= WALLS[2] and WALLS[1] <= y <= WALLS[3]:
                c = "H"
            elif STAIR[0] <= x <= STAIR[2] - 0.6 and -2 <= y <= 6:
                c = "s"
            c = marks.get((x, y), c)
            row += c
        rows.append(row)
    rows.append("     " + "".join(str(abs(x) % 10) for x in range(-r, r + 1)))
    return "\n".join(rows)


def main(args):
    maps = "-m" in args
    names = [a for a in args if not a.startswith("-")] or TOWNS
    towns = tl.load()
    bad = 0
    for name in names:
        t = towns[name]
        tiers, notes = draft(t, OPTS.get(name))
        problems = tl.check(t, tiers)
        counts = " / ".join(f"T{i}: {len(it)} things, {sum(1 for x in it if x[0] == 'guard')} guards, {sum(1 for x in it if x[0] == 'static')} statics" for i, it in enumerate(tiers, 1))
        print(f"{name} ({t.cls[7:]}{', spawned' if t.spawned else ''}, threat {threat_side(t)}): {counts}; {'; '.join(notes)}")
        if problems:
            bad += 1
            print("   PROBLEMS:", problems)
        else:
            tl.write(t, tiers)
        if maps:
            print(site_map(t, tiers[-1]))
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
