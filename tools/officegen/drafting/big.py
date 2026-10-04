"""
Draft mayor's office layouts, group "big" (Overthrow CE): the two Offices_01 tower blocks (Kavala, Pyrgos, 5 tiers),
the House_Big_01 towns Athira and Zaros (5 tiers, after the hand-made Aggelochori) and the House_Big_02 towns
Poliakko, Selakano, Stavros and Telos (3 tiers). Run from the repository root:
    python tools/officegen/drafting/big.py [--map] [town ...]
Writes tools/officegen/layouts/drafts/<town>.txt for each town (tl.write checks them first). Everything below is
in the office's model coordinates (x right, y forward out of the model's front, mdir 0 = +y, 90 = +x).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import townlib as tl  # noqa: E402

WALL, GATE, CORNER = "Land_Mil_WallBig_4m_F", "Land_WallCity_01_gate_grey_F", "Land_Mil_WallBig_Corner_F"
ROUND, SHORT, LONG = "Land_BagFence_Round_F", "Land_BagFence_Short_F", "Land_BagFence_Long_F"
HB1, HB3, HB5, HBW6 = "Land_HBarrier_1_F", "Land_HBarrier_3_F", "Land_HBarrier_5_F", "Land_HBarrierWall6_F"
WIRE, HOG = "Land_Razorwire_F", "Land_CzechHedgehog_01_F"
PIPEGATE, FENCEGATE = "Land_PipeFence_03_m_gate_r_F", "Land_GameProofFence_01_l_gate_F"


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


def corners(t, it):
    m = t.to_model(it[2])
    L, D = size(it)
    d = (yaw(it) - t.dir) % 360
    cx, cy = tl.rot(1, 0, d), tl.rot(0, 1, d)
    return [(m[0] + sx * L / 2 * cx[0] + sy * D / 2 * cy[0], m[1] + sx * L / 2 * cx[1] + sy * D / 2 * cy[1])
            for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(t, a, b, tol=0.12):
    """Separating-axis overlap of two footprints (only in the same height band)."""
    za, zb = t.to_model(a[2])[2], t.to_model(b[2])[2]
    if abs(za - zb) > 1.6:
        return False
    pa, pb = corners(t, a), corners(t, b)
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
    single-item checks, doesn't overlap what's there and (fortifications) stays off roads; otherwise it tries small
    nudges (nudge > 0) or logs a skip."""

    def __init__(self, t):
        self.t, self.tiers, self.cur, self.log = t, [], None, []

    def tier(self):
        self.cur = list(self.tiers[-1]) if self.tiers else []
        self.tiers.append(self.cur)

    def _ok(self, it, road_ok, free=False):
        if single_problems(self.t, it):
            return False
        if free:
            return True
        if it[0] == "object" and "ground" in it[4] and not road_ok and self.t.on_road(it[2][0], it[2][1]) and it[1] not in (WIRE, HOG):
            return False
        for o in self.cur:
            if overlap(self.t, it, o):
                return False
        return True

    def put(self, make, x, y, z, d, nudge=0.0, road_ok=False, label="", free=False):
        """make(x, y, z, d) builds the item; returns it (or None when skipped)."""
        tries = [(0.0, 0.0)]
        if nudge:
            r = 0.5
            while r <= nudge + 1e-6:
                tries += [(r * math.sin(math.radians(a)), r * math.cos(math.radians(a))) for a in range(0, 360, 45)]
                r += 0.5
        for dx, dy in tries:
            it = make(x + dx, y + dy, z, d)
            if self._ok(it, road_ok, free):
                self.cur.append(it)
                if dx or dy:
                    self.log.append(f"T{len(self.tiers)} {label or it[1]} nudged {dx:+.1f},{dy:+.1f}")
                return it
        it = make(x, y, z, d)
        why = single_problems(self.t, it)[:1] or [o[1] for o in self.cur if overlap(self.t, it, o)][:2] or ["road"]
        self.log.append(f"T{len(self.tiers)} SKIP {label or it[1]} at ({x:.1f},{y:.1f}): {why}")
        return None

    # ---- the pieces
    def g(self, role, x, y, d, z=None, nudge=1.0):
        return self.put(lambda a, b, c, e: tl.guard(self.t, role, a, b, c, e), x, y, z, d, nudge, label=role)

    def o(self, cls, x, y, d, z=None, nudge=0.0, road_ok=False, flag=False):
        return self.put(lambda a, b, c, e: tl.obj(self.t, cls, a, b, c, e, flag), x, y, z, d, nudge, road_ok, cls)

    def post(self, role, x, y, face, cls=SHORT, z=None, back=None, nudge=0.6):
        """Cover at (x, y) across the facing, the guard behind it (1 m from its near face) facing out over it."""
        back = (tl.CLASSES[cls][1] / 2 + 1.0) if back is None else back
        if self.o(cls, x, y, face, z, nudge=nudge):
            gx, gy = off(x, y, face, -back)
            return self.g(role, gx, gy, face, z, nudge=0.5)
        return None

    def static(self, role, x, y, face, z=None, bag=True, nudge=0.5):
        """A static weapon with a round sandbag 1.3 m in front of it (its open side towards the gun)."""
        s = self.put(lambda a, b, c, e: tl.static(self.t, role, a, b, c, e), x, y, z, face, nudge, label=role + " static")
        if s and bag:
            m = self.t.to_model(s[2])
            bx, by = off(m[0], m[1], face, 1.3)
            self.o(ROUND, bx, by, face + 180, z, nudge=0.3)
        return s

    def run(self, x0, y0, along, pieces, z=None, road_ok=False):
        """A straight wall run from (x0, y0) going along model direction `along`: pieces "W" (Mil wall, 4 m),
        "G" (city gate, 5 m), "_" (a 4 m gap), "g" (a 5 m gap), "H" (HBarrier_5, 6 m), "h" (HBarrier_3, 3.6 m),
        "1" (HBarrier_1, 1.56 m), "w" (razor wire, 7.6 m). Butted end to end."""
        spec = {"W": (WALL, 4.0), "G": (GATE, 5.0), "_": (None, 4.0), "g": (None, 5.0), "H": (HB5, 6.0),
                "h": (HB3, 3.6), "1": (HB1, 1.56), "w": (WIRE, 7.6), "c": (None, 1.0)}
        s = 0.0
        for p in pieces:
            cls, L = spec[p]
            if cls:
                cx, cy = off(x0, y0, along, s + L / 2)
                self.o(cls, cx, cy, along - 90, z, road_ok=road_ok)
            s += L
        return off(x0, y0, along, s)

    def roadblock(self, x, y, face, roles=("autorifleman", "autorifleman"), spread=2.2):
        """An H-barrier wall across a road at (x, y), facing the way traffic comes (face), two men behind its ends."""
        if self.o(HBW6, x, y, face, road_ok=True, nudge=1.0):
            m = self.t.to_model(self.cur[-1][2])
            for role, lat in zip(roles, (-spread, spread)):
                gx, gy = off(m[0], m[1], face, -2.1, lat)
                self.g(role, gx, gy, face, nudge=1.0)

    def finish(self):
        return self.tiers


def counts(tiers):
    return [(len(ti), sum(1 for it in ti if it[0] == "guard")) for ti in tiers]


# ================================================================ Offices_01 (Kavala, Pyrgos)
# The tower block: the lobby (x 4..13, y -8..8) with the main door (10.5, -7.7) facing -y onto a porch (y -8..-9.5,
# x -1..13, floor -6.7, about 0.7 m over the street), the back door (-14.8, 8.4) facing +y; the west block
# (x -17..-2, y -12.5..4) is shut. Floors -6.7 / -2.95 / 1.0 / 4.97 (the office floor, east windows at x 13) and the
# roof terrace 10.25 over the whole block (x -17..13, y -12.5/-8.5..9).
F0, F1, F2, F3, ROOF = -6.71, -2.95, 1.01, 4.97, 10.25


def offices_core(d):
    """Tiers 1-2 inside and on the building (the same in both towers)."""
    t = d.t
    d.tier()  # T1: the template's tier 1
    d.cur.extend(tl.from_template(t, 1))
    d.tier()  # T2: hold the building
    d.g("rifleman", 1.8, -7.0, 180, F1)      # Window posts over the porch, second and third floors
    d.g("rifleman", 4.1, -6.7, 180, F2)
    d.g("autorifleman", 3.0, -6.7, 180, F0)  # The lobby, covering the porch


def kavala(d):
    t = d.t
    offices_core(d)
    # T2: firing posts either side of the walled forecourt's mouth (the way out stays open between them), the
    # back door's post, the east alley (between the tower and the street wall) shut at its north end, the west
    # yard shut at its south end
    d.post("rifleman", 6.2, -13.2, 180)
    d.post("autorifleman", 14.8, -13.3, 180)
    d.post("rifleman", -14.8, 10.9, 0)
    d.o(PIPEGATE, 15.8, 9.6, 0)
    d.o(FENCEGATE, -19.5, -12.3, 180)

    d.tier()  # T3: the north yard walled (Addon to the NW city wall) with its gate; HMG on the SE corner of the
    # square covering the square and the junction, GMG in the yard; porch post; the office window on the east road
    d.run(4.3, 20.0, 270, "WWGW")
    d.static("hmg", 17.4, -16.0, 160)
    d.static("gmg", -6.0, 13.5, 330)
    d.post("rifleman", 5.0, -9.25, 180, LONG, z=F0)
    d.g("rifleman", 12.2, -1.7, 90, F3)
    d.g("rifleman", -3.2, 18.4, 345)

    d.tier()  # T4: the square closed by an H-barrier line with the gate on the door's axis (low enough for the
    # porch, the windows and the roof to fire over), its east and west ends tied into the city walls; wire in front
    # of it, hedgehogs on the east street and the west road; MG on the roof's SE corner; men along the line
    d.run(-22.0, -18.0, 90, "HHHHH")          # x -22 .. 8
    d.run(13.0, -18.0, 90, "h")               # x 13 .. 16.6 (the HMG holds 16.6 .. 19.4)
    d.run(20.2, -17.6, 0, "H")                # East end up to the pocket wall
    d.run(19.3, -11.0, 270, "11")
    d.run(-22.9, -17.0, 0, "H")               # West end up to the city wall
    d.run(-21.0, -20.6, 90, "www")            # Wire in front of the west part
    for x, y in ((24.0, -24.0), (27.5, -25.0), (30.5, -23.5), (24.5, 14.0), (28.0, 15.5), (31.0, 13.5),
                 (35.0, -10.5), (35.5, -15.5), (-29.5, 10.5), (-33.0, 5.5), (-36.0, 1.5)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)
    d.post("mg_gunner", 11.5, -7.9, 170, LONG, z=ROOF)
    d.g("autorifleman", -13.0, -16.1, 180)
    d.g("autorifleman", -1.0, -16.1, 180)
    d.g("autorifleman", 14.8, -16.1, 180)
    d.g("autorifleman", 18.3, -12.5, 90)
    d.g("autorifleman", -9.0, 18.4, 15)
    d.post("rifleman", -16.0, 7.6, 315, z=ROOF)

    d.tier()  # T5: roadblocks on the east street (north and south of the square) and the west road; mortar in the
    # yard; AT gun on the porch and an AT man at the gate; marksmen and an HMG on the roof
    d.roadblock(27.6, 17.5, 12)
    d.roadblock(26.8, -28.0, 182)
    d.roadblock(-33.5, 8.5, 303)
    d.static("mortar", -10.0, 12.0, 0, bag=False)
    d.static("at", 1.0, -8.6, 180, z=F0, bag=False)
    d.g("at", 6.8, -16.1, 180)
    d.static("hmg", 10.8, 3.0, 90, z=ROOF)
    d.post("marksman", -15.6, -11.0, 225, z=ROOF)
    d.post("marksman", 11.6, 7.6, 45, z=ROOF)
    d.static("gmg", -19.5, -6.0, 240)


def pyrgos(d):
    """The tower stands in its own compound: city walls on the east (x 19) and the north (y 13-17, the street
    beyond it, y 17-26), pipe fences on the south (y -18.5, a gap at x 6-10.6) and the west (x -24.7). No roads
    were probed within reach, so the checkpoints go on the north street and the square to the south."""
    offices_core(d)
    # T2: firing posts either side of the main door's way out, the back door's post, the strips along the east
    # and west sides shut behind the building so the way in is the front
    d.post("rifleman", 6.2, -13.2, 180)
    d.post("autorifleman", 14.8, -13.3, 180)
    d.post("rifleman", -14.8, 10.9, 0)
    d.o(PIPEGATE, 16.2, 9.8, 0)
    d.o(FENCEGATE, -19.0, 10.0, 0)
    d.o(PIPEGATE, -23.0, 10.0, 0)

    d.tier()  # T3: the west yard walled (the west fence line and the south side), its gate west; HMG on the SE
    # corner covering the square, GMG in the yard; porch post; the office window over the east side
    d.run(-25.5, -13.4, 0, "WWGWW")
    d.run(-25.2, -13.4, 90, "WWW")
    d.static("hmg", 16.8, -14.4, 180)
    d.static("gmg", -21.0, -8.0, 225)
    d.post("rifleman", 5.0, -9.25, 180, LONG, z=F0)
    d.g("rifleman", 12.2, -1.7, 90, F3)
    d.g("rifleman", -22.6, -1.0, 270)

    d.tier()  # T4: the south side closed by an H-barrier line just inside the fences with the gate on the door's
    # axis, tied into the yard wall; wire outside the fences; hedgehogs on the north street's ends and the square;
    # MG on the roof's SE corner; men along the line
    d.run(-13.5, -16.0, 90, "HHHh")           # x -13.5 .. 8.1
    d.run(12.8, -16.0, 90, "11")              # x 12.8 .. 15.9 (the HMG holds the corner)
    d.o(HB1, -14.3, -14.4, 90)
    d.run(-9.5, -21.2, 90, "ww")
    d.run(11.3, -21.2, 90, "w")
    for x, y in ((22.0, 19.5), (23.5, 23.5), (-27.0, 19.5), (-28.5, 23.5), (4.0, -26.0), (16.0, -25.5), (-3.0, -30.0)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.post("mg_gunner", 11.5, -7.9, 170, LONG, z=ROOF)
    d.g("autorifleman", -9.0, -14.9, 180)
    d.g("autorifleman", 1.5, -14.9, 180)
    d.g("autorifleman", 14.2, -14.8, 180)
    d.g("autorifleman", 16.2, 7.6, 0)
    d.g("autorifleman", -20.0, 8.0, 0)
    d.post("rifleman", -16.0, 7.6, 315, z=ROOF)

    d.tier()  # T5: roadblocks on the north street's two ends and the square south of the gate; mortar in the yard;
    # AT gun on the porch, AT man at the gate; marksmen and an HMG on the roof
    d.roadblock(17.0, 21.7, 90)
    d.roadblock(-21.0, 21.7, 270)
    d.roadblock(14.0, -28.5, 180)
    d.static("mortar", -21.0, 3.0, 0, bag=False)
    d.static("at", 1.0, -8.6, 180, z=F0, bag=False)
    d.g("at", 7.0, -14.8, 180)
    d.static("hmg", 10.0, 6.4, 20, z=ROOF)
    d.post("marksman", -15.6, -11.0, 225, z=ROOF)
    d.post("marksman", 11.6, -3.5, 90, z=ROOF)


# ================================================================ House_Big_01 (Athira, Zaros): after Aggelochori
# The same building as the hand-made Aggelochori office: its own building-local items (the office furniture, the
# door's bags, the gates, the window posts, the upstairs MG and marksman) are transplanted tier by tier (each at the
# tier it first appears in there, with its final position and facing); the yard, the wire and the roadblocks are
# drawn per town. Main door (-3.3, -7.3) facing -y (a porch on its west side), side door (4.9, 5.6) facing +x.
_REF = None


def ref_rows():
    """Aggelochori's items with the tier each first appears in: [(tier, kind, what, x, y, ref z, mdir)]."""
    global _REF
    if _REF is None:
        _, ref = tl.reference()
        out = []
        for n in sorted(ref):
            for row in ref[n]:
                if not any(r[1] == row[0] and r[2] == row[1] and math.hypot(r[3] - row[2], r[4] - row[3]) < 0.6
                           and abs(r[5] - row[4]) < 1.5 for r in out):
                    out.append([n] + list(row))
        final = ref[max(ref)]
        for r in out:  # the final position and facing (the user moved some later)
            for row in final:
                if row[0] == r[1] and row[1] == r[2] and math.hypot(r[3] - row[2], r[4] - row[3]) < 0.6 and abs(r[5] - row[4]) < 1.5:
                    r[3:] = row[2:]
        _REF = [tuple(r) for r in out]
    return _REF


def ref_local(d, n, skip=()):
    """Aggelochori's building-local items of tier n onto this office (outside ones on the ground)."""
    t = d.t
    lv = min(t.plan().levels)
    for tier, kind, what, x, y, z, mdir in ref_rows():
        if (tier != n or abs(x) > 6.5 or abs(y) > 9.5 or kind == "static" or what in (ROUND, WALL, GATE)
                or what.startswith("Flag") or (what, round(x, 1), round(y, 1)) in skip):
            continue
        inside = t.plan().cell(lv, x, y) != " "
        fz = (t.floors[-1] if z > 2 else t.floors[0]) if inside else None
        if kind == "guard":
            d.g(what, x, y, mdir, fz, nudge=0.6)
        else:  # The user's own placements: only the probe's checks, not the overlap with each other
            d.put(lambda a, b, c, e, w=what: tl.obj(t, w, a, b, c, e), x, y, fz, mdir, free=True)


def big01_t1(d):
    """Tier 1: Aggelochori's, the flag where the user moved it (beside the porch)."""
    d.tier()
    flag = [r for r in ref_rows() if r[2].startswith("Flag")][-1]
    ref_local(d, 1)
    d.o(flag[2], flag[3], flag[4], flag[6], flag=True, nudge=1.5)


def athira(d):
    """Athira: the office stands in a block. The city wall runs south from the main door's west side, the lane
    east of it goes south; east of the office is an open courtyard (Big_02 north, the shop east, Big_02 south) with
    gaps to the north-east (to the east road) and the south-east."""
    big01_t1(d)
    d.tier()  # T2: Aggelochori's door bags, gates and window posts
    ref_local(d, 2)

    d.tier()  # T3: the courtyard's east side walled (Big_02 to the south line) with its gate, the start of the south
    # line; HMG covering out of the gate, GMG in the courtyard; Aggelochori's T3 posts
    d.run(12.9, 11.4, 180, "WWGWW")
    d.run(13.2, -9.9, 270, "WW")
    d.static("hmg", 9.6, 0.9, 90)
    d.static("gmg", 8.5, -4.5, 135)
    ref_local(d, 3)

    d.tier()  # T4: the south line finished with its gate on the door's lane; hedgehogs in the gaps and the lane, wire
    # on the open west; Aggelochori's upstairs MG and post; men along the walls
    d.run(5.2, -9.9, 270, "WG")
    for x, y in ((23.5, 8.0), (25.5, 10.0), (20.0, 9.5), (19.5, -13.5), (-1.0, -27.0), (1.0, -26.5)):
        d.o(HOG, x, y, 45, nudge=1.0)
    d.o(WIRE, -10.5, -4.0, 270, nudge=0.5)
    d.o(WIRE, -9.0, 4.5, 270, nudge=0.5)
    ref_local(d, 4)
    d.g("autorifleman", 11.4, 6.0, 60)
    d.g("autorifleman", 6.0, -8.6, 160)
    d.g("autorifleman", -7.5, 1.0, 270)
    d.g("autorifleman", 11.4, -7.5, 135)

    d.tier()  # T5: roadblocks in the north-east gap and down the lane; mortar in the courtyard; AT gun covering the
    # lane through the south gate; marksmen; a round sandbag post on the west
    d.roadblock(30.0, 8.5, 90)
    d.roadblock(-0.5, -22.0, 180)
    d.static("mortar", 10.0, 4.5, 0, bag=False)
    d.static("at", 1.2, -8.6, 180, bag=False)
    ref_local(d, 5)
    d.g("marksman", -3.6, 5.4, 300, t_floor(d, 1))
    d.static("gmg", -8.5, -9.5, 225)


def t_floor(d, i):
    return d.t.floors[i]


def zaros(d):
    """Zaros: a shop stands hard against the office's front, so the main door's way out is west, off the porch,
    into a yard the old walls and Addon_02 mostly close; the side door faces the east road across a 5 m strip;
    Addon_03 is behind."""
    big01_t1(d)
    d.tier()  # T2: Aggelochori's door bags, gates and window posts (what fits beside the shop)
    ref_local(d, 2)

    d.tier()  # T3: the west yard closed (a gate in the north gap, a wall in the south-west gap), the east strip walled
    # along the road with the side door's stretch left for the guns; HMG on the road, GMG in the west yard
    d.o(GATE, -7.3, 6.9, 0)
    d.o(WALL, -12.75, -15.5, 0)
    d.run(10.2, -6.8, 0, "WW")
    d.static("hmg", 8.2, 6.4, 70)
    d.static("gmg", -9.5, 1.0, 300)
    ref_local(d, 3)

    d.tier()  # T4: hedgehogs on the road both ways, wire on the west and north-west; upstairs MG; men in the yard
    for x, y in ((15.5, 22.0), (18.5, 24.5), (14.5, 26.5), (16.0, -21.5), (18.5, -24.0), (14.5, -26.0)):
        d.o(HOG, x, y, 45, road_ok=True, nudge=1.0)
    d.o(WIRE, -25.0, -8.0, 270, nudge=0.8)
    d.o(WIRE, -23.0, 8.0, 315, nudge=0.8)
    ref_local(d, 4)
    d.g("autorifleman", -11.5, 4.5, 315)
    d.g("autorifleman", -10.0, -12.8, 180)
    d.g("autorifleman", 8.6, 3.0, 60)
    d.g("autorifleman", -7.5, 4.6, 0)

    d.tier()  # T5: roadblocks on the road north and south; mortar in the yard; AT gun beside the HMG; marksmen
    d.roadblock(16.8, 16.0, 0)
    d.roadblock(17.0, -16.0, 180, roles=("autorifleman", "at"))
    d.static("mortar", -10.5, -4.0, 0, bag=False)
    d.static("at", 7.6, -1.0, 90)
    ref_local(d, 5)
    d.g("marksman", -3.6, 5.4, 300, t_floor(d, 1))
    d.post("rifleman", -13.0, 3.5, 290, ROUND)


# ================================================================ House_Big_02 (3 tiers)
# Main door (-4.7, -6.2) facing -x at the south-west corner beside an open porch (y -5..-6.5), side door (0.1, 5.3)
# facing +y; floors -2.46 / ~1.0, the upper floor's south balcony over the porch (-0.6, -5.3) and its east window
# (4.2, 2.9). T1 is the template's; T2 a sandbag position at the main door, 3 guards (one upstairs), a gap closed;
# T3 a short wall run with a gate on the most open side, one static in round bags, 2 guards.

def c_nest(d, x, y, roles=("rifleman", "autorifleman")):
    """A C of sandbags square with the main door (facing -x): the long bag across at x, short bags back towards the
    house at its ends, two men inside facing out."""
    d.o(LONG, x, y, 270)
    d.o(SHORT, x + 0.98, y - 1.22, 0)
    d.o(SHORT, x + 0.98, y + 1.22, 0)
    for role, dy in zip(roles, (-0.6, 0.6)):
        d.g(role, x + 1.2, y + dy, 270, nudge=0.3)


def poliakko(d):
    """Poliakko: Addon_02 hard against the west side north of the main door, the east road 8 m east; the door opens
    west onto the open ground in front (south-west), the most open side, walled at T3 with the gate by the door."""
    t = d.t
    d.tier()
    d.cur.extend(tl.from_template(t, 1))
    d.tier()  # T2: the C at the main door (just clear of Addon_02), the upstairs window over the road
    c_nest(d, -8.2, -6.6)
    d.g("rifleman", 4.2, 2.9, 90, t.floors[1])
    d.tier()  # T3: the front walled along y -11.6 with the gate by the door, the HMG covering out of it; the side
    # door's post and the south balcony
    d.run(5.0, -11.6, 270, "WWGWW")
    d.static("hmg", -3.0, -8.8, 190)
    d.post("autorifleman", 1.6, 7.6, 0)
    d.g("rifleman", -0.6, -5.3, 180, t.floors[1])


def selakano(d):
    """Selakano: Addon_02 on the west and the garage on the east are built onto the office; the main door opens
    into a pocket on the street (the road runs along the front, 8 m south); behind is a walled yard (the side
    door's) with one gap in its north wall."""
    t = d.t
    d.tier()
    d.cur.extend(tl.from_template(t, 1))
    d.tier()  # T2: a long bag across the pocket facing the street, the pair behind it; the south balcony; the gap
    # between Addon_02 and the west wall shut
    d.post("rifleman", -9.6, -8.3, 180, LONG, back=1.2)
    d.g("autorifleman", -8.4, -7.1, 180)
    d.g("rifleman", -0.6, -5.3, 180, t.floors[1])
    d.o(SHORT, -15.4, -5.4, 0, nudge=0.4)
    d.tier()  # T3: the yard's north gap shut with a gate between Mil wall pieces, a wall on the pocket's west flank;
    # HMG in the pocket covering the street west; the side door's post
    d.run(-12.1, 14.4, 90, "WG")
    d.o(WALL, -16.8, -9.9, 270)
    d.static("hmg", -13.6, -6.4, 220)
    d.post("autorifleman", 1.6, 7.6, 0)
    d.g("rifleman", 4.2, 2.9, 90, t.floors[1])


def stavros(d):
    """Stavros: the road runs diagonally past the main door's front (south-west); House_Big_01 east; the open
    ground north-west of the office is walled at T3 with a gate west."""
    t = d.t
    d.tier()
    d.cur.extend(tl.from_template(t, 1))
    d.tier()  # T2: posts either side of the door's way out to the road (the road is too close for a C), the south
    # balcony (no gap worth shutting: House_Big_01 and the city wall close the east)
    d.post("rifleman", -6.2, -3.4, 270)
    d.post("autorifleman", 0.0, -8.8, 200)
    d.g("rifleman", -0.6, -5.3, 200, t.floors[1])
    d.tier()  # T3: the north-west side walled at x -9 with its gate, the HMG behind the door's posts covering the
    # road; the side door's post, a man at the gate
    d.run(-9.0, -3.4, 0, "WGW")
    d.static("hmg", -7.0, 0.6, 215)
    d.post("autorifleman", 1.6, 7.6, 0)
    d.g("rifleman", -7.6, 4.8, 270)


def telos(d):
    """Telos: House_Small_01 stands against the main door (the way out is south off the porch), the road passes
    north beyond the side door; south and east are open fields, walled at T3 across the south with the gate on
    the porch's line."""
    t = d.t
    d.tier()
    d.cur.extend(tl.from_template(t, 1))
    d.tier()  # T2: posts either side of the porch's way south, the east window upstairs
    d.post("rifleman", -4.5, -9.6, 200)
    d.post("autorifleman", 1.5, -9.6, 160)
    d.g("rifleman", 4.2, 2.9, 90, t.floors[1])
    d.tier()  # T3: the south walled at y -12.5 with the gate on the porch's line; HMG at the south-east covering the
    # east field; the south balcony and the ground-floor east window
    d.run(9.0, -12.5, 270, "WWGW")
    d.static("hmg", 7.0, -8.5, 110)
    d.g("rifleman", -0.6, -5.3, 180, t.floors[1])
    d.g("autorifleman", 4.1, 2.9, 90, t.floors[0])


TOWNS = {"Kavala": kavala, "Pyrgos": pyrgos, "Athira": athira, "Zaros": zaros,
         "Poliakko": poliakko, "Selakano": selakano, "Stavros": stavros, "Telos": telos}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    towns = tl.load()
    for name, fn in TOWNS.items():
        if args and name not in args:
            continue
        t = towns[name]
        d = Draft(t)
        fn(d)
        tiers = d.finish()
        for line in d.log:
            print(f"  {name}: {line}")
        probs = tl.check(t, tiers)
        if probs:
            print(f"{name}: PROBLEMS {probs}")
            continue
        path = tl.write(t, tiers)
        print(f"{name}: {counts(tiers)} -> {os.path.relpath(path, tl.ROOT)}")
        if "--map" in sys.argv:
            print(tl.ascii_map(t, tiers[-1], r=46))


if __name__ == "__main__":
    main()
