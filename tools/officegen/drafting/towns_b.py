"""
Drafts the mayor's office layouts of drafting group towns_b (tools/officegen/townlib.py has the API). Run from the
repository root:
    python tools/officegen/drafting/towns_b.py [town ...] [-m]   (all of the group without names; -m prints maps)

4 tiers, House_Big_01 (the hand-made Aggelochori's building, its layout followed):
  T1  Aggelochori's tier 1: desk, chair and map board in the front room, the flag by the front, 2 gendarmes.
  T2  a C-nest of sandbags beside the main door (its path left clear) with a rifleman and an autorifleman, a
      rifleman upstairs over the veranda and one at the front window, an autorifleman inside, the side door
      closed with a gate fence, the narrowest side gap beside the house closed.
  T3  a run of Land_Mil_WallBig_4m_F with a gate on the yard's most open side, an HMG in round bags covering the
      main approach, a rifleman at a ground floor window and an autorifleman at the gate.
  T4  the yard's walls carried round the open sides, a GMG in round bags, Czech hedgehogs and razor wire across
      the approach road(s) 13-24 m out, an MG gunner upstairs, a rifleman upstairs and an autorifleman on the yard.
3 tiers, House_Big_02:
  T1  the template's tier 1 (the desk upstairs), the flag moved off anything it clashes with.
  T2  a C-nest beside the main door with a rifleman and an autorifleman, a rifleman on the balcony over the front
      door, the narrowest side gap closed.
  T3  a short wall section with a gate on the most open side, one static in round bags, 2 more guards.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import townlib as tl  # noqa: E402

BIG01 = ["Neochori", "Panochori", "Paros", "Rodopoli", "Sofia", "Therisa"]
BIG02 = ["Kore", "Lakka", "Neri"]

# The houses' real walls in model coordinates (the probed bounding boxes run well past them): xmin, ymin, xmax, ymax
EXTENT = {
    "i_House_Big_01_V1_F": (-4.6, -7.7, 5.6, 7.7),  # x -4.5..-2.5: the covered veranda along the west side
    "i_House_Big_02_V1_F": (-5.4, -6.9, 5.4, 7.5),
}
WALL = "Land_Mil_WallBig_4m_F"
GATE = "Land_WallCity_01_gate_grey_F"
ROUND = "Land_BagFence_Round_F"
HOG = "Land_CzechHedgehog_01_F"
WIRE = "Land_Razorwire_F"
OBSTACLES = (HOG, WIRE)


def size_of(kind, what):
    if kind == "object":
        return tl.CLASSES.get(what, (0.6, 0.6))
    return (2.0, 2.0) if kind == "static" else (0.5, 0.5)


def vec(mdir):
    return (math.sin(math.radians(mdir)), math.cos(math.radians(mdir)))


class Drafter:
    def __init__(self, t):
        self.t = t
        self.placed = []  # (x, y, radius) of the outside things so far
        self.notes = []

    def world_yaw(self, mdir):
        return (self.t.dir + mdir) % 360

    def free(self, kind, what, x, y, mdir, road_ok=False, trees=True, spacing=0.8):
        """Whether a ground footprint is clear: the check()'s rules, plus trees, probed walls, roads and what's
        placed already."""
        t = self.t
        if math.hypot(x, y) > 44:
            return False
        ln, dp = size_of(kind, what)
        w = t.to_world(x, y, 0)
        for h in t.hits(w[0], w[1], ln, dp, self.world_yaw(mdir), 0.2):
            if h[0] in ("building", "part", "rock", "wall") or (h[0] == "tree" and trees):
                return False
        if t.on_office(x, y, ln, dp, mdir):
            return False
        ext = EXTENT[t.key]
        a, b = vec(mdir + 90), vec(mdir)
        for i in range(5):
            for j in range(3):
                px = x + a[0] * ln * (i / 4 - 0.5) + b[0] * dp * (j / 2 - 0.5)
                py = y + a[1] * ln * (i / 4 - 0.5) + b[1] * dp * (j / 2 - 0.5)
                if ext[0] - 0.3 < px < ext[2] + 0.3 and ext[1] - 0.3 < py < ext[3] + 0.3:
                    return False  # Against or under the house (the plan's cells are coarse)
        r = max(ln, dp) / 2
        if not road_ok and self.road(x, y, ln, dp, mdir):
            return False
        return all(math.hypot(x - px, y - py) >= (r + pr) * spacing for px, py, pr in self.placed)

    def road(self, x, y, ln=0.5, dp=0.5, mdir=0.0):
        """Whether a footprint's centre or ends stand on a road."""
        a = vec(mdir + 90)
        for s in (-0.5, 0, 0.5):
            px, py = x + a[0] * ln * s * 0.8, y + a[1] * ln * s * 0.8
            w = self.t.to_world(px, py, 0)
            if any(d < seg["width"] / 2 - 1.0 for d, seg in self.t.roads_near(w[0], w[1], 15)):
                return True  # Within the road's paved core (the probe's widths take in the verges)
        return False

    def take(self, x, y, kind, what):
        ln, dp = size_of(kind, what)
        self.placed.append((x, y, max(ln, dp) / 2))

    def put(self, kind, what, x, y, mdir, z=None, search=0.0, road_ok=False, trees=True, flag=False, need=False):
        """A thing at model (x, y) (z None: on the ground, checked and searched round up to `search` m for a clear
        spot; z a floor: inside, unchecked). Returns the item, or None (noted) when there's no room."""
        t = self.t
        if z is None:
            spot = None
            steps = [0.0] + [r * 0.5 for r in range(1, int(search * 2) + 1)]
            for r in steps:
                for k in range(max(1, int(r * 8))):
                    a = 2 * math.pi * k / max(1, int(r * 8))
                    px, py = x + r * math.cos(a), y + r * math.sin(a)
                    if self.free(kind, what, px, py, mdir, road_ok, trees):
                        spot = (px, py)
                        break
                if spot:
                    break
            if spot is None:
                self.notes.append(f"no room for {what} at {x:.1f},{y:.1f}")
                assert not need, (t.name, what, x, y)
                return None
            x, y = spot
            self.take(x, y, kind, what)
        if kind == "guard":
            return tl.guard(t, what, x, y, z, mdir)
        if kind == "static":
            return tl.static(t, what, x, y, z, mdir)
        return tl.obj(t, what, x, y, z, mdir, flag=flag)

    def many(self, specs, **kw):
        """put() each (kind, what, x, y, mdir[, z]) spec; the ones that fit."""
        out = []
        for s in specs:
            it = self.put(*s[:5], z=s[5] if len(s) > 5 else None, **kw)
            if it:
                out.append(it)
        return out

    def post(self, role, x, y, mdir, cover=ROUND, back=1.1, search=1.5):
        """A static weapon (role in tl.STATIC_ROLES) or a guard (any other role) behind a piece of cover, both moved
        together to the nearest clear spot, facing model direction mdir."""
        f = vec(mdir)
        kind = "static" if role in tl.STATIC_ROLES else "guard"
        cdir = (mdir + 180) % 360 if cover == ROUND else mdir
        steps = [0.0] + [r * 0.5 for r in range(1, int(search * 2) + 1)]
        for r in steps:
            for k in range(max(1, int(r * 8))):
                a = 2 * math.pi * k / max(1, int(r * 8))
                px, py = x + r * math.cos(a), y + r * math.sin(a)
                cx, cy = px + f[0] * back, py + f[1] * back
                if self.free(kind, role, px, py, mdir, spacing=0.6) and self.free("object", cover, cx, cy, cdir, spacing=0.6):
                    self.take(px, py, kind, role)
                    self.take(cx, cy, "object", cover)
                    me = tl.static(self.t, role, px, py, None, mdir) if kind == "static" else tl.guard(self.t, role, px, py, None, mdir)
                    return [tl.obj(self.t, cover, cx, cy, None, cdir), me]
        self.notes.append(f"no room for the {role} post at {x:.1f},{y:.1f}")
        return []

    def wall_run(self, x0, y0, mdir_run, n, gate_at=None, holes=()):
        """n wall pieces butted end to end from (x0, y0) along model direction mdir_run (the run's first piece's
        outer end at (x0, y0)); gate_at: the index of a slot that takes the gate (5 m) instead; holes: slots left
        open (4 m, for a static's post). Pieces with no room are left out (a neighbour or a road there)."""
        f = vec(mdir_run)
        wdir = (mdir_run - 90) % 360  # The piece's length along the run
        out, pos, skipped = [], 0.0, 0
        for i in range(n):
            if i == gate_at:
                ln, cls = 5.0, GATE
            else:
                ln, cls = 4.0, WALL
            cx, cy = x0 + f[0] * (pos + ln / 2), y0 + f[1] * (pos + ln / 2)
            pos += ln
            if i in holes:
                continue
            if self.free("object", cls, cx, cy, wdir, spacing=0.4):
                self.take(cx, cy, "object", cls)
                out.append(tl.obj(self.t, cls, cx, cy, None, wdir))
            else:
                skipped += 1
        if skipped:
            self.notes.append(f"{skipped} of the {n} wall slots from {x0:.0f},{y0:.0f} left out (blocked)")
        return out


# ---------------------------------------------------------------- tier 1 and tier 2, the house's own kit

def door_frame(t):
    d = t.door("main")
    (x, y, _), m = d["model"], d["mdir"]
    return (x, y), m, vec(m), vec(m + 90), d["width"]


def at(origin, f, lat, a, b):
    return (origin[0] + f[0] * a + lat[0] * b, origin[1] + f[1] * a + lat[1] * b)


def tier1(t, dr):
    if t.key == "i_House_Big_01_V1_F":
        # Aggelochori's hand-placed tier 1 (the template's desk was in an odd spot): the front room
        f0 = t.floors[0]
        items = [
            dr.put("object", "Land_TableDesk_F", 1.9, -5.5, 137, z=f0),
            dr.put("object", "Land_OfficeChair_01_F", 3.6, -6.1, 187, z=f0),
            dr.put("object", "Land_MapBoard_F", 2.0, -0.1, 52, z=f0),
            dr.put("guard", "gendarme", 3.3, -4.5, 236, z=f0),
            dr.put("guard", "gendarme", 1.5, 5.0, 76, z=f0),
        ]
        items.append(dr.put("object", "Flag_NATO_F", 0.0, -8.4, 180, search=5, flag=True, need=True))
        return items
    out = []
    for kind, what, p, d, extra in tl.template(t.key)[0]:
        if kind == "doorway":
            continue
        if "outside" not in extra:
            out.append(dr.put(kind, what, p[0], p[1], d, z=p[2]))
        else:
            out.append(dr.put(kind, what, p[0], p[1], d, search=6, flag="flag" in extra, need=True))
    return out


def nest(t, dr, prefer=None):
    """A sandbag C-nest beside the main door, facing out, its two guards behind it; the door's own path stays
    clear. prefer: 1 or -1, the side (along the door's lateral axis) to try first."""
    o, m, f, lat, width = door_frame(t)
    b0 = width / 2 + 1.45 + 0.7  # The long bag's inner end 0.7 m off the doorway's edge
    sides = (prefer, -prefer) if prefer else (1, -1)
    for side in sides:
        for a in (3.2, 4.0, 4.8):
            for b in (b0, b0 + 1.0, b0 + 2.0):
                b *= side
                parts = [
                    ("object", "Land_BagFence_Long_F", at(o, f, lat, a, b), m),
                    ("object", "Land_BagFence_Short_F", at(o, f, lat, a - 0.85, b + side * 1.75), (m + 90) % 360),
                    ("guard", "rifleman", at(o, f, lat, a - 1.2, b - side * 0.6), m),
                    ("guard", "autorifleman", at(o, f, lat, a - 1.2, b + side * 0.6), m),
                ]
                if all(dr.free(k, w, p[0], p[1], d) for k, w, p, d in parts):
                    out = []
                    for k, w, p, d in parts:
                        dr.take(p[0], p[1], k, w)
                        out.append(tl.obj(t, w, p[0], p[1], None, d) if k == "object" else tl.guard(t, w, p[0], p[1], None, d))
                    return out, f"nest at {[round(v) for v in at(o, f, lat, a, b)]}"
    out = []
    for side, role in ((-1, "rifleman"), (1, "autorifleman")):
        for a in (1.0, 1.5, 2.0, 2.5):
            p = at(o, f, lat, a, side * (width / 2 + 1.0))
            if dr.free("guard", role, p[0], p[1], m):
                dr.take(p[0], p[1], "guard", role)
                out.append(tl.guard(t, role, p[0], p[1], None, m))
                break
    return out, "NO ROOM for a nest by the door, the two guards stand at its flanks"


def gap(t, dr):
    """The narrower of the side gaps beside the house (the front's flanks), closed with a gate fence and bags."""
    xmin, ymin, xmax, ymax = EXTENT[t.key]
    front = round(t.door("main")["mdir"]) % 360
    best = None
    if front in (180, 0):
        fy = ymin + 0.4 if front == 180 else ymax - 0.4
        flanks = [("x", xmin, -1, (ymin + 1.5, ymax - 1.5), fy), ("x", xmax, 1, (ymin + 1.5, ymax - 1.5), fy)]
    else:
        fx = xmin + 0.4 if front == 270 else xmax - 0.4
        flanks = [("y", ymin, -1, (xmin + 1.5, xmax - 1.5), fx), ("y", ymax, 1, (xmin + 1.5, xmax - 1.5), fx)]
    for axis, edge, sgn, samples, along in flanks:
        ds = []
        for s in samples + (along,):
            d = None
            for k in range(1, 25):
                off = k * 0.25
                x, y = (edge + sgn * off, s) if axis == "x" else (s, edge + sgn * off)
                w = t.to_world(x, y, 0)
                if any(h[0] in ("building", "part", "wall", "rock") for h in t.hits(w[0], w[1], 0.3, 0.3, 0, 0)):
                    d = off
                    break
            ds.append(d)
        if all(d is not None and 1.2 <= d <= 5.5 for d in ds):
            if best is None or ds[-1] < best[0]:
                best = (ds[-1], axis, edge, sgn, along)
    if best is None:
        return [], "no narrow side gap"
    d, axis, edge, sgn, along = best
    left = d - 0.3
    pieces = []
    for cls, ln in (("Land_PipeFence_03_m_gate_r_F", 4.0), ("Land_BagFence_Long_F", 2.9), ("Land_BagFence_Short_F", 1.5), ("Land_BagFence_Short_F", 1.5), ("Land_BagFence_End_F", 0.6)):
        if ln <= left + 0.1:
            pieces.append((cls, ln))
            left -= ln
    out, pos = [], 0.15
    for cls, ln in pieces:
        c = edge + sgn * (pos + ln / 2)
        x, y = (c, along) if axis == "x" else (along, c)
        mdir = 0 if axis == "x" else 90
        if dr.free("object", cls, x, y, mdir, trees=False, road_ok=True):
            dr.take(x, y, "object", cls)
            out.append(tl.obj(t, cls, x, y, None, mdir))
        pos += ln
    side = {("x", -1): "west", ("x", 1): "east", ("y", -1): "south", ("y", 1): "north"}[(axis, sgn)]
    return out, f"{side} side gap ({d:.1f} m) closed with {len(out)} pieces"


def tier2_big01(t, dr, cfg):
    f0, f1 = t.floors[0], t.floors[1]
    n, nnote = nest(t, dr, cfg.get("nest_side"))
    g, gnote = gap(t, dr)
    items = n + g + [
        dr.put("guard", "rifleman", -3.4, -3.4, 270, z=f1),           # Upstairs over the veranda
        dr.put("guard", "rifleman", 0.2, -6.0, 180, z=f1),            # Upstairs at the front window
        dr.put("guard", "autorifleman", -0.2, 1.9, 180, z=f0),        # Inside, covering the hall (Aggelochori's)
        dr.put("object", "Land_PipeFence_03_m_gate_r_F", 5.0, 5.2, 90, z=f0),  # The side door closed (Aggelochori's)
    ]
    dr.notes.append(nnote)
    dr.notes.append(gnote)
    return items


def tier2_big02(t, dr, cfg):
    n, nnote = nest(t, dr, cfg.get("nest_side"))
    g, gnote = gap(t, dr)
    dr.notes.append(nnote)
    dr.notes.append(gnote)
    return n + [dr.put("guard", "rifleman", -3.8, -4.6, 270, z=t.floors[1])] + g  # The balcony over the front door's recess


# ---------------------------------------------------------------- per town: the yard, statics, obstacles

def obstacles(dr, specs):
    """Hedgehogs and wire (on roads allowed: they're across the approaches)."""
    out = []
    for cls, x, y, mdir in specs:
        it = dr.put("object", cls, x, y, mdir, search=1.5, road_ok=True, trees=False)
        if it:
            out.append(it)
    return out


def block(dr, cx, cy, n=3):
    """Czech hedgehogs across the road nearest model (cx, cy): n of them 3 m apart, square across it, staggered."""
    t = dr.t
    w = t.to_world(cx, cy, 0)
    d, seg = t.roads_near(w[0], w[1], 15)[0]
    a, b = t.to_model(seg["beg"]), t.to_model(seg["end"])
    run = math.degrees(math.atan2(b[0] - a[0], b[1] - a[1]))
    vx, vy = b[0] - a[0], b[1] - a[1]
    k = max(0, min(1, ((cx - a[0]) * vx + (cy - a[1]) * vy) / (vx * vx + vy * vy or 1)))
    cx, cy = a[0] + k * vx, a[1] + k * vy  # On the road's centre line
    f, lat = vec(run), vec(run + 90)
    specs = []
    for k in range(n):
        o = (k - (n - 1) / 2) * 3.0
        s = 0.8 if k % 2 else -0.8
        specs.append((HOG, cx + lat[0] * o + f[0] * s, cy + lat[1] * o + f[1] * s, (run + 45) % 360))
    return obstacles(dr, specs)


def draft(t, cfg):
    dr = Drafter(t)
    t1 = tier1(t, dr)
    t2 = t1 + (tier2_big01 if t.key == "i_House_Big_01_V1_F" else tier2_big02)(t, dr, cfg)
    tiers = [t1, t2]
    for n in range(3, t.cap + 1):
        add = []
        for spec in cfg.get(f"t{n}", []):
            what = spec[0]
            if what == "wall":
                add += dr.wall_run(*spec[1:])
            elif what == "post":
                add += dr.post(*spec[1:])
            elif what == "obst":
                add += obstacles(dr, spec[1])
            elif what == "block":
                add += block(dr, *spec[1:])
            elif what == "obj":  # (class, x, y, mdir, on a road allowed)
                it = dr.put("object", spec[1], spec[2], spec[3], spec[4], search=1.0, road_ok=spec[5] if len(spec) > 5 else False)
                if it:
                    add.append(it)
            elif what == "in":  # A guard inside: (role, x, y, mdir, floor index)
                add.append(dr.put("guard", spec[1], spec[2], spec[3], spec[4], z=t.floors[spec[5]]))
            elif what == "guard":  # A guard outside on the ground
                it = dr.put("guard", spec[1], spec[2], spec[3], spec[4], search=1.5)
                if it:
                    add.append(it)
            else:
                raise ValueError(spec)
        tiers.append(tiers[-1] + add)
    return tiers, dr.notes


def cmap(t, items, r=32, step=1):
    """A top-down map in model coordinates (up = +y, the house's back; the main door of a Big_01 faces down):
    O house, # building, = wall, t tree, : road; W our wall, G gate, b bags, h hedgehog, z wire, f flag,
    g guard (outside), S static, x other."""
    marks = {}
    for kind, what, p, o, extra in items:
        if "ground" not in extra:
            continue
        m = t.to_model(p)
        c = {"guard": "g", "static": "S"}.get(kind)
        if c is None:
            c = {WALL: "W", GATE: "G", HOG: "h", WIRE: "z", "Flag_NATO_F": "f"}.get(what, "b" if "Bag" in what else "x")
        if kind == "object" and what in (WALL, GATE, WIRE):
            ln = tl.CLASSES[what][0]
            yaw = math.degrees(math.atan2(o[0][0], o[0][1])) - t.dir
            a = vec(yaw + 90)
            for s in range(-int(ln / 2), int(ln / 2) + 1):
                marks.setdefault((round((m[0] + a[0] * s) / step), round((m[1] + a[1] * s) / step)), c)
        marks[(round(m[0] / step), round(m[1] / step))] = c
    ext = EXTENT[t.key]
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
            if ext[0] <= x <= ext[2] and ext[1] <= y <= ext[3]:
                c = "O"
            c = marks.get((i, j), c)
            row += c
        rows.append(row)
    rows.append("     " + "".join(("|" if i % 10 == 0 else " ") for i in range(-r // step, r // step + 1)) + "  (| every 10 m, x from -%d)" % r)
    return "\n".join(rows)


# Per town: what tiers 3 and 4 add (model coordinates; the main door of a Big_01 faces -y, of a Big_02 -x).
#   ("wall", x0, y0, run direction, slots, gate slot, open slots)  ("post", role, x, y, facing): a static or guard
#   behind round bags  ("in", role, x, y, facing, floor index)  ("guard", role, x, y, facing): outside
#   ("obj", class, x, y, mdir, road ok)  ("obst", [(class, x, y, mdir)])  ("block", x, y): hedgehogs across a road
F0, F1 = 0, 1
CFG = {
    # The street runs past the veranda (west); a garage closes the east. Front yard: the gate in the gap between the
    # veranda's corner and the street wall, walls round the south and east with the HMG's post in the south run.
    # T4: the back yard closed (wire along the street side, the GMG covering it), hedgehogs across the street.
    "Neochori": {
        "t3": [("obj", GATE, -5.4, -10.0, 90, True), ("wall", -3.2, -17.5, 90, 4, None, (2,)),
               ("post", "hmg", 6.8, -16.3, 180), ("wall", 12.8, -17.5, 0, 2),
               ("guard", "autorifleman", -2.4, -12.0, 250), ("in", "rifleman", 3.8, -5.3, 90, F0)],
        "t4": [("post", "gmg", -1.6, 12.2, 290), ("obst", [(WIRE, -5.6, 12.5, 90)]),
               ("wall", -6.4, 17.6, 90, 1), ("wall", 13.0, 11.0, 0, 1),
               ("block", -10.5, -21.0), ("block", -10.5, 21.0), ("obst", [(WIRE, 18.0, -21.0, 0)]),
               ("in", "mg_gunner", -3.6, 5.4, 270, F1), ("in", "rifleman", 3.9, 5.4, 90, F1),
               ("guard", "autorifleman", 1.2, 13.8, 315)],
    },
    # The track runs past the veranda (west) and bends west past the front; a house right behind, a wall on the
    # east. Front yard: the old walls close the south, a gate on the street side, a wall closes the east passage.
    "Panochori": {
        "t3": [("obj", GATE, -5.6, -10.9, 90, True), ("wall", 11.6, -8.6, 180, 2),
               ("post", "hmg", 9.0, 14.0, 0),
               ("guard", "autorifleman", -2.6, -12.4, 270), ("in", "rifleman", 3.8, -5.3, 90, F0)],
        "t4": [("post", "gmg", 4.5, -12.3, 260),
               ("block", -9.0, 20.0), ("block", -14.5, -9.5, 2),
               ("in", "mg_gunner", -3.6, 5.4, 270, F1), ("in", "rifleman", 3.9, 5.4, 90, F1),
               ("guard", "autorifleman", 8.5, 5.0, 0)],
    },
    # A track past the veranda (west), the main road beyond the front; a house against the east side. T3: the back
    # yard walled on the east with the gate, the HMG in front covering the main road. T4: the west wall along the
    # track with the street gate, the GMG covering the back gate, hedgehogs on the track both ways.
    "Paros": {
        "t3": [("wall", 14.5, 6.0, 0, 3, 1), ("obj", "Land_BagFence_Long_F", -5.5, 8.8, 90),
               ("post", "hmg", 2.0, -10.5, 240),
               ("guard", "autorifleman", 5.0, 12.0, 90), ("in", "rifleman", -3.3, -1.0, 270, F0)],
        "t4": [("obj", "Land_BagFence_Long_F", -7.9, -13.4, 0), ("wall", -9.4, -13.3, 0, 4, 1), ("wall", -9.4, 3.9, 90, 1),
               ("post", "gmg", 9.0, 12.0, 90),
               ("block", -13.0, 18.0), ("block", -17.5, -13.0),
               ("in", "mg_gunner", -3.6, 5.4, 270, F1), ("in", "rifleman", -2.7, 0.6, 270, F1),
               ("guard", "autorifleman", -7.9, -1.0, 270)],
    },
    # A house right in front and one behind; the track along the east behind an old low wall, a dog-leg passage
    # from the door to the front track. T3: the open west side walled with a gate, the HMG covering the passage.
    # T4: the back closed, the GMG in the east yard over the low wall, hedgehogs on the east track both ways and on
    # the front track, wire on the open west.
    "Rodopoli": {
        "t3": [("wall", -9.5, -7.5, 0, 4, 1), ("wall", -9.5, 9.0, 90, 1),
               ("post", "hmg", -14.0, -12.0, 200),
               ("guard", "autorifleman", -7.5, -1.0, 270), ("in", "rifleman", 3.8, -5.3, 90, F0)],
        "t4": [("obj", WALL, 8.5, 17.8, 0),
               ("post", "gmg", 9.5, -3.0, 60), ("obst", [(WIRE, -16.0, 2.0, 90)]),
               ("block", 22.0, -14.0), ("block", 21.0, 16.0), ("block", -15.0, -26.5),
               ("in", "mg_gunner", -3.6, 5.4, 270, F1), ("in", "rifleman", 3.9, 5.4, 90, F1),
               ("guard", "autorifleman", -8.0, 0.0, 270)],
    },
    # On the corner of the main road (west) and a track (front), houses behind and against the east. T3: a wall
    # screening the veranda from the main road with a gate, the HMG by the door covering the junction. T4: the
    # GMG in the pocket east of the house, hedgehogs on all three approaches (the front strip stays open to the
    # track: no room for a wall that leaves the door's path clear).
    "Sofia": {
        "t3": [("wall", -8.3, 7.5, 180, 4, 1),
               ("post", "hmg", 3.5, -10.2, 200),
               ("guard", "autorifleman", -6.8, -2.0, 270), ("in", "rifleman", -3.3, -6.0, 200, F0)],
        "t4": [("post", "gmg", 10.0, 4.0, 90),
               ("block", -15.0, 20.0), ("block", -14.5, -24.0), ("block", 18.0, -16.0),
               ("in", "mg_gunner", -3.6, 5.4, 270, F1), ("in", "rifleman", 3.9, 5.4, 90, F1),
               ("guard", "autorifleman", 6.0, -10.4, 180)],
    },
    # No road near (a track 28 m behind, a road 38 m in front); open ground in front, houses west and east. T3: the
    # front yard walled with the gate on the door's axis and the HMG's post in the south run. T4: the yard's west
    # side and the back closed, hedgehogs and wire on the open southern approach and the back track.
    "Therisa": {
        "t3": [("wall", -9.8, -16.0, 90, 5, 1, (3,)), ("wall", 11.2, -16.0, 0, 3),
               ("post", "hmg", 5.2, -14.8, 180),
               ("guard", "autorifleman", -1.0, -14.0, 180), ("in", "rifleman", -3.3, -1.0, 270, F0)],
        "t4": [("wall", -9.8, -16.0, 0, 2), ("wall", 7.0, 6.0, 0, 1),
               ("post", "gmg", 1.0, -11.0, 225),
               ("obst", [(HOG, -5.5, -23.5, 45), (HOG, -1.0, -23.5, 45), (WIRE, -11.0, -21.0, 0), (WIRE, 4.5, -21.0, 0),
                         (WIRE, -10.0, 10.0, 0)]),
               ("block", -12.0, 27.0),
               ("in", "mg_gunner", -3.6, 5.4, 270, F1), ("in", "rifleman", 3.9, 5.4, 90, F1),
               ("guard", "autorifleman", -8.3, -12.0, 270)],
    },
    # No road near; a house against the east and one west of the door's lane, open ground south. T3: the gate across
    # the lane on the door's axis, a wall along the open south with the HMG's post in it.
    "Kore": {
        "t3": [("wall", -15.0, -3.7, 180, 2, 0), ("wall", -14.7, -13.0, 90, 4, None, (2,)),
               ("post", "hmg", -4.7, -11.9, 180),
               ("guard", "autorifleman", -12.5, -6.2, 270), ("in", "rifleman", 3.3, 6.3, 0, F1)],
    },
    # A track in front (south); houses west and behind. T3: a wall between the house and the track with the gate
    # at its west end by the old wall, the HMG's post in the run covering the track.
    "Lakka": {
        "t3": [("wall", -11.0, -12.0, 90, 5, 0, (2,)),
               ("post", "hmg", 0.0, -10.9, 180),
               ("guard", "autorifleman", -8.5, -9.5, 180), ("in", "rifleman", 4.2, 2.9, 90, F1)],
    },
    # A track behind (north) past the old walls of the front yard; open to the south. T3: the gap between the old
    # walls and the house to the south closed with a gate, the HMG in a gap of the old north wall covering the track.
    "Neri": {
        "t3": [("wall", -14.0, -13.6, 90, 3, 1),
               ("post", "hmg", -13.0, 9.8, 0),
               ("guard", "autorifleman", -9.0, -11.0, 180), ("in", "rifleman", -0.6, -5.3, 180, F1)],
    },
}


def main(args):
    maps = "-m" in args
    names = [a for a in args if a != "-m"] or BIG01 + BIG02
    towns = tl.load()
    for name in names:
        t = towns[name]
        tiers, notes = draft(t, CFG.get(name, {}))
        problems = tl.check(t, tiers)
        counts = " / ".join(f"T{i}: {len(it)} items, {sum(1 for x in it if x[0] == 'guard')} guards" for i, it in enumerate(tiers, 1))
        print(f"{name} ({t.cls}, {t.cap} tiers): {counts}")
        for n in notes:
            print("   ", n)
        if maps:
            print(cmap(t, tiers[-1]))
        if problems:
            print(f"  PROBLEMS {problems}")
            continue
        if len(tiers) == t.cap:
            tl.write(t, tiers)


if __name__ == "__main__":
    main(sys.argv[1:])
