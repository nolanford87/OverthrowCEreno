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
  T2  the door held: a C-shaped sandbag nest (a long bag facing the approach, short bags as wings, open towards
      the house) off one side of the door, square with the front, with a rifleman and an autorifleman 1 m behind
      it; on the door's other side a bag in front of the gendarme so both flanks of the doorway have covered
      guns and the way in is a 1 m lane between them; a marksman at the upstairs window over the door; a rifleman
      on the stair's landing over the east side and the stair. 6 guards.
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
        return tl.CLASSES.get(what, (0.6, 0.6))
    return (2.0, 2.0) if kind == "static" else (0.5, 0.5)


class Site:
    """A town's office site: what's free on the ground, and the things placed so far."""

    def __init__(self, t):
        self.t = t
        self.placed = []  # (x, y, length, depth, mdir)

    def blocked(self, kind, what, x, y, mdir, road_ok=False):
        """Why a ground footprint can't go here ('' when it can)."""
        t = self.t
        if math.hypot(x, y) > 44:
            return "far"
        ln, dp = size_of(kind, what)
        w = t.to_world(x, y, 0)
        for h in t.hits(w[0], w[1], ln, dp, (t.dir + mdir) % 360, 0.25):
            if h[0] in ("building", "part", "rock", "wall") or (h[0] == "tree" and kind != "object"):
                return h[0]
        if t.on_office(x, y, ln, dp, mdir):
            return "office"
        # The real house and the stair (the plan's half-cell give lets things touch the walls)
        hx, hy = (ln / 2, dp / 2) if round(mdir) % 180 == 0 else (dp / 2, ln / 2)
        for box in (WALLS, STAIR):
            if x + hx > box[0] and x - hx < box[2] and y + hy > box[1] and y - hy < box[3]:
                return "house"
        if not road_ok:
            for k in (-1, 0, 1):
                px, py = (x + k * hx, y) if hx >= hy else (x, y + k * hy)
                pw = t.to_world(px, py, 0)
                if t.on_road(pw[0], pw[1]):
                    return "road"
        for px, py, pl, pd, pm in self.placed:
            ax, ay = (pl / 2, pd / 2) if round(pm) % 180 == 0 else (pd / 2, pl / 2)
            if abs(x - px) < hx + ax - 0.15 and abs(y - py) < hy + ay - 0.15:
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
    west = [(x, y, 180, "front, west of the door") for y in (-5.6, -6.1, -5.1, -6.6, -7.2) for x in (1.0, 0.6, 0.2, -0.3, -0.9)]
    east = [(x, y, 180, "front, east of the door") for y in (-5.8, -6.4, -7.0) for x in (5.0, 5.5, 6.2)]
    tries += (east + west) if prefer_east else (west + east)
    # Hard against the front wall, its front bag on the road's shoulder (a street right in front of the house)
    tries += [(x, y, 180, "front, west of the door, on the street's edge", True) for y in (-4.7, -4.9, -5.1) for x in (0.6, 0.2, -0.3)]
    tries += [(x, y, 180, "front, out on the door's axis") for y in (-7.4, -8.2, -9.0) for x in (3.0, 2.0, 4.0)]
    tries += [(x, y, 180, "off the front-west corner") for x in (-4.0, -5.0, -6.5, -7.5, -8.5, -9.5, -10.5, -11.5) for y in (-4.5, -5.5, -3.5, -6.5)]
    tries += [(x, y, 270, "west side, facing west") for x in (-5.6, -6.2, -6.8, -8.0) for y in (0.5, 1.5, -0.5, 2.5, 3.5)]
    tries += [(x, y, 0, "back, facing north") for y in (9.6, 10.2) for x in (1.0, 0.0, 2.5)]
    for x, y, face, note, *road in tries:
        parts = nest_parts(x, y, face)
        if all(not site.blocked(k, w, p[0], p[1], d, road_ok=bool(road) and k == "object") and not lane_hit(k, w, p, d) for k, w, p, d in parts):
            return [site.put(k, w, p[0], p[1], d) for k, w, p, d in parts], f"nest {note} at ({x:.1f}, {y:.1f})"
    return None, "NO ROOM for the nest"


def lane_hit(kind, what, p, d):
    """Whether a footprint stands in the front door's walkway (straight out to 9 m)."""
    ln, dp = size_of(kind, what)
    hx = ln / 2 if round(d) % 180 == 0 else dp / 2
    hy = dp / 2 if round(d) % 180 == 0 else ln / 2
    return p[0] + hx > DOOR_LANE[0] and p[0] - hx < DOOR_LANE[1] and p[1] - hy < -2.5 and p[1] + hy > -9.0


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


def tier2(site):
    t = site.t
    f1 = t.floors[1]
    out, notes = [], []
    nest, note = place_nest(site, prefer_east=getattr(site, "prefer_east", False))
    notes.append(note)
    if nest:
        out += nest
    # A bag in front of the sentry: the doorway's other flank
    if site.sentry:
        sx, sy = site.sentry
        for dy in (1.1, 1.3, 0.9):
            if not site.blocked("object", "Land_BagFence_Short_F", sx, sy - dy, 180) and not lane_hit("object", "Land_BagFence_Short_F", (sx, sy - dy), 180):
                out.append(site.put("object", "Land_BagFence_Short_F", sx, sy - dy, 180))
                notes.append("bag before the sentry")
                break
        else:
            notes.append("no bag before the sentry")
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
        c = "g" if kind == "guard" else ("S" if kind == "static" else ("f" if "Flag" in what else ("b" if "Bag" in what else "o")))
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
