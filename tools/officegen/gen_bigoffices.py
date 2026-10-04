#!/usr/bin/env python3
"""
Mayor's office defence templates for the two big Altis city offices:

    Land_Offices_01_V1_F   5-storey office block (Kavala), only the east tower section is enterable
    Land_Hospital_main_F   Kavala hospital composite (main + side1 + side2), open undercroft and roofs

Reads the probe data (probe_offices.txt, OTPROBE2 records in the building's model coordinates) and
writes addons/overthrow_main/functions/offices/templates/fn_officeTpl_<Key>.sqf for each. The
probe gives the bbox, the door trigger points, the AI building positions, the floor heights and a
1 m cell map per floor ('#' wall, '.' floor, ' ' nothing); the layouts themselves are hand-tuned in
the per-class sections below (offices_01 and hospital), written in terms of those probe facts.

    python tools/officegen/gen_bigoffices.py            write the templates (exit 1 on a placement note)
    python tools/officegen/gen_bigoffices.py --map      also print the cell maps with the layout drawn on

Template format (shared with the other office templates): the SQF returns
[[tier1 additions], ..., [tier5 additions]], tiers apply cumulatively, and an item is
[kind ("guard"|"object"), class or guard role, [x,y,z] model position, direction relative to the
building, extra]. Object z is the floor's level z.

Helpers are self-contained (the shared officegen_lib.py did not exist when this was written).
"""

import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PROBE = os.path.join(HERE, "probe_offices.txt")
OUT_DIR = os.path.join(ROOT, "addons", "overthrow_main", "functions", "offices", "templates")

# Occupier flag: the SQF global the occupier config sets (nato.sqf: OT_flag_NATO = "Flag_NATO_F"),
# emitted as a bare identifier so the template picks up whichever occupier is loaded.
FLAG = "OT_flag_NATO"

# Footprints (length along model X at dir 0, depth along Y) used for the clearance checks and the
# fence runs. Best-known vanilla sizes; a few cm either way does not matter here.
SIZES = {
    "Land_BagFence_Long_F": (3.0, 0.45),
    "Land_BagFence_Short_F": (1.5, 0.45),
    "Land_BagFence_Round_F": (2.6, 1.3),
    "Land_BagFence_Corner_F": (1.5, 1.5),
    "Land_HBarrier_1_F": (1.2, 1.2),
    "Land_HBarrier_3_F": (3.6, 1.2),
    "Land_HBarrier_5_F": (6.0, 1.2),
    "Land_Razorwire_F": (8.0, 1.0),
    "Land_CncBarrier_stripes_F": (3.0, 0.6),
    "Land_CzechHedgehog_01_F": (1.4, 1.4),
    "Land_BagBunker_Small_F": (3.5, 3.0),
    "Land_TableDesk_F": (1.9, 0.9),
    "Land_OfficeChair_01_F": (0.6, 0.6),
    "Land_OfficeCabinet_01_F": (0.9, 0.5),
    "Land_FilingCabinet_01_F": (0.6, 0.5),
    "Land_CampingTable_F": (1.2, 0.6),
    "Land_CampingChair_V2_F": (0.6, 0.6),
    "Land_WaterCooler_01_new_F": (0.4, 0.4),
    "Land_PortableLongRangeRadio_F": (0.4, 0.3),
    "Land_Map_altis_F": (0.5, 0.4),
    "MapBoard_altis_F": (1.3, 0.3),
    "Land_Camping_Light_F": (0.3, 0.3),
    "Land_Ammobox_rounds_F": (0.9, 0.5),
    FLAG: (0.3, 0.3),
}

DOOR_GAP = 1.2       # clear metres in front of every door (object edge to the door trigger point)
GUARD_GAP = 0.5      # objects keep this far from a guard's feet (object edge to the position)
TABLE_TOP = 0.76     # Land_CampingTable_F top above its floor, for the radio and the map


# ----------------------------------------------------------------------------------------------
# Probe data
# ----------------------------------------------------------------------------------------------

def _nums(s):
    return [float(v) for v in re.findall(r"-?\d+(?:\.\d+)?", s)]


def _triples(s):
    v = _nums(s)
    return [tuple(v[i:i + 3]) for i in range(0, len(v) - len(v) % 3, 3)]


class Probe:
    """One building's probe: bbox, doors, positions, levels and the cell maps."""

    def __init__(self, cls):
        self.cls = cls
        self.bmin = self.bmax = None
        self.doors = []
        self.positions = []
        self.levels = []
        self.rows = {}      # level z -> {y: row string}
        self.x0 = None      # model x of the first cell of a row

    def cell(self, level, x, y):
        row = self.rows.get(level, {}).get(int(round(y)))
        if row is None:
            return " "
        i = int(round(x)) - self.x0
        return row[i] if 0 <= i < len(row) else " "

    def level_of(self, z):
        return min(self.levels, key=lambda l: abs(l - z))

    def nearest_position(self, p):
        return min(self.positions, key=lambda q: (q[0] - p[0]) ** 2 + (q[1] - p[1]) ** 2 + (q[2] - p[2]) ** 2)


def parse_probe(path):
    probes = {}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.search(r"OTPROBE2\|(\w+)\|([^|\r\n]*)(?:\|(.*))?$", line.rstrip("\r\n"))
            if not m:
                continue
            kind, cls, rest = m.group(1), m.group(2), m.group(3) or ""
            p = probes.setdefault(cls, Probe(cls))
            if kind == "START":
                a, b = rest.split("|")
                p.bmin, p.bmax = tuple(_nums(a)), tuple(_nums(b))
                p.x0 = math.ceil(p.bmin[0])
            elif kind == "DOORS":
                p.doors = _triples(rest.split("|", 1)[1])
            elif kind == "POS":
                p.positions = _triples(rest.split("|", 1)[1])
            elif kind == "LEVELS":
                p.levels = _nums(rest)
            elif kind == "ROW":
                lz, y, row = rest.split("|", 2)
                p.rows.setdefault(float(lz), {})[int(y)] = row
    return probes


# ----------------------------------------------------------------------------------------------
# Geometry helpers (Arma directions: 0 = +Y, 90 = +X, clockwise)
# ----------------------------------------------------------------------------------------------

def fwd(d):
    r = math.radians(d)
    return math.sin(r), math.cos(r)


def right(d):
    return fwd(d + 90)


def at(origin, d, forward, lateral):
    """Point `forward` m along direction d from origin, `lateral` m to the right of it."""
    fx, fy = fwd(d)
    rx, ry = right(d)
    return origin[0] + fx * forward + rx * lateral, origin[1] + fy * forward + ry * lateral


def norm(d):
    return round(d % 360, 1)


def rect_dist(point, centre, d, size):
    """Distance from a point to an oriented rectangle (length along the object's X, depth along Y)."""
    fx, fy = fwd(d)
    rx, ry = right(d)
    dx, dy = point[0] - centre[0], point[1] - centre[1]
    u = dx * rx + dy * ry   # along the object's length
    v = dx * fx + dy * fy   # along its depth
    du = max(abs(u) - size[0] / 2, 0)
    dv = max(abs(v) - size[1] / 2, 0)
    return math.hypot(du, dv)


# ----------------------------------------------------------------------------------------------
# Template builder
# ----------------------------------------------------------------------------------------------

class Template:
    def __init__(self, probe, exterior_doors, interior_doors=()):
        self.probe = probe
        self.tiers = [[] for _ in range(5)]
        self.notes = []
        # exterior doors: (x, y, out direction, z); interior ones: (x, y, z)
        self.doors = [(x, y, z) for x, y, _, z in exterior_doors] + list(interior_doors)
        self.guards = []    # (x, y, z)

    # -- items ---------------------------------------------------------------------------------
    def guard(self, tier, role, pos, d, snap=True):
        """A guard at a probe building position (snap=False: a free position, e.g. the gate)."""
        if snap:
            q = self.probe.nearest_position(pos)
            dist = math.dist(q, pos)
            if dist > 0.05:
                raise ValueError(f"{self.probe.cls}: guard {pos} is {dist:.2f} m from the nearest building position {q}")
            pos = q
        self.tiers[tier - 1].append(["guard", role, pos, norm(d), []])
        self.guards.append(pos)

    def obj(self, tier, cls, pos, d, extra=None, inside=False):
        """An object; inside=True checks it stands on a floor cell of its level."""
        x, y, z = pos
        self.tiers[tier - 1].append(["object", cls, (x, y, z), norm(d), list(extra or [])])
        if inside:
            lvl = self.probe.level_of(z)
            c = self.probe.cell(lvl, x, y)
            if c != ".":
                self.notes.append(f"{cls} at ({x:.1f},{y:.1f}) level {lvl}: cell is '{c}', not floor")

    # -- door kits (offsets are forward of / to the right of the door, facing out) ----------
    def nests(self, tier, door, forward=2.6, lateral=2.4, cls="Land_BagFence_Round_F", z=None, sides=(-1, 1)):
        x, y, d, _ = door
        for s in sides:
            px, py = at((x, y), d, forward, s * lateral)
            self.obj(tier, cls, (px, py, z), d)

    def barriers(self, tier, door, forward=4.6, lateral=3.2, cls="Land_HBarrier_3_F", z=None, sides=(-1, 1)):
        self.nests(tier, door, forward, lateral, cls, z, sides)

    def wire(self, tier, door, forward=6.0, lateral=5.5, z=None, sides=(-1, 1)):
        self.nests(tier, door, forward, lateral, "Land_Razorwire_F", z, sides)

    def hedgehogs(self, tier, door, forward=7.6, lateral=2.2, z=None):
        x, y, d, _ = door
        for s in (-1, 1):
            px, py = at((x, y), d, forward, s * lateral)
            self.obj(tier, "Land_CzechHedgehog_01_F", (px, py, z), d + 45)

    def chicane(self, tier, door, forward=9.8, lateral=0.6, z=None, side=1, angle=25):
        x, y, d, _ = door
        px, py = at((x, y), d, forward, side * lateral)
        self.obj(tier, "Land_CncBarrier_stripes_F", (px, py, z), d + side * angle)

    # -- sandbag in front of a guard position --------------------------------------------------
    def window_bags(self, tier, pos, d, offset=0.65, cls="Land_BagFence_Short_F"):
        px, py = at(pos, d, offset, 0)
        self.obj(tier, cls, (px, py, pos[2]), d, inside=True)

    # -- fences --------------------------------------------------------------------------------
    def fence_run(self, tier, a, b, z, cls="Land_HBarrier_5_F", gaps=()):
        """HESCO pieces from a to b (model xy); gaps = [(t0, t1)] along the run are left open, each
        segment between them gets whole pieces squeezed to fit (they overlap a little, never gap)."""
        length = SIZES[cls][0]
        run = math.dist(a, b)
        d = math.degrees(math.atan2(b[0] - a[0], b[1] - a[1]))   # direction of travel
        cuts = [0.0]
        for g0, g1 in sorted(gaps):
            cuts += [max(g0, 0.0), min(g1, run)]
        cuts.append(run)
        for s0, s1 in zip(cuts[0::2], cuts[1::2]):
            seg = s1 - s0
            if seg < 0.6:
                continue
            n = max(1, int(math.ceil(seg / length - 1e-6)))
            step = seg / n
            for i in range(n):
                px, py = at(a, d, s0 + (i + 0.5) * step, 0)
                self.obj(tier, cls, (px, py, z), d + 90)

    def perimeter(self, tier, xmin, ymin, xmax, ymax, z, gate=None, cls="Land_HBarrier_5_F"):
        """A ring of fence on the given rectangle; gate = (side, centre along that side, width)."""
        sides = {
            "south": ((xmin, ymin), (xmax, ymin)),
            "east": ((xmax, ymin), (xmax, ymax)),
            "north": ((xmax, ymax), (xmin, ymax)),
            "west": ((xmin, ymax), (xmin, ymin)),
        }
        for name, (a, b) in sides.items():
            gaps = []
            if gate and gate[0] == name:
                _, centre, width = gate
                axis = 0 if name in ("south", "north") else 1
                t = abs(centre - a[axis])
                gaps.append((t - width / 2, t + width / 2))
            self.fence_run(tier, a, b, z, cls, gaps)

    # -- checks --------------------------------------------------------------------------------
    def check(self):
        notes = list(self.notes)
        items = [(t + 1, it) for t, tier in enumerate(self.tiers) for it in tier]
        objects = [(t, it) for t, it in items if it[0] == "object"]
        for t, (_, cls, (x, y, z), d, _) in objects:
            size = SIZES.get(cls)
            if size is None:
                notes.append(f"T{t}: no size for {cls}, clearance not checked")
                size = (0.5, 0.5)
            for dx, dy, dz in self.doors:
                if abs(self.probe.level_of(dz) - self.probe.level_of(z)) > 0.5:
                    continue   # another floor
                gap = rect_dist((dx, dy), (x, y), d, size)
                if gap < DOOR_GAP:
                    notes.append(f"T{t}: {cls} at ({x:.1f},{y:.1f}) is {gap:.2f} m from the door at ({dx},{dy})")
            for gx, gy, gz in self.guards:
                if abs(gz - z) > 1.0:
                    continue
                gap = rect_dist((gx, gy), (x, y), d, size)
                if gap < GUARD_GAP - 1e-6 and not cls.startswith("Land_BagBunker"):
                    notes.append(f"T{t}: {cls} at ({x:.1f},{y:.1f}) is {gap:.2f} m from the guard at ({gx},{gy})")
        # objects on the same floor should not sit on top of each other (fence corners may touch, and
        # the radio and map stand on a table)
        on_table = ("Land_PortableLongRangeRadio_F", "Land_Map_altis_F", "Land_CampingTable_F")
        for i, (t1, (_, c1, (x1, y1, z1), d1, _)) in enumerate(objects):
            for t2, (_, c2, (x2, y2, z2), d2, _) in objects[i + 1:]:
                if abs(z1 - z2) > 1.0 or c1 == c2 == "Land_HBarrier_5_F" or (c1 in on_table and c2 in on_table):
                    continue
                s1, s2 = SIZES.get(c1, (0.5, 0.5)), SIZES.get(c2, (0.5, 0.5))
                if rect_dist((x1, y1), (x2, y2), d2, s2) + 1e-6 < min(s1) / 2 \
                        or rect_dist((x2, y2), (x1, y1), d1, s1) + 1e-6 < min(s2) / 2:
                    notes.append(f"T{t1}/T{t2}: {c1} at ({x1:.1f},{y1:.1f}) overlaps {c2} at ({x2:.1f},{y2:.1f})")
        # the guard counts the design asks for (top of each range, cumulative)
        want = [4, 6, 8, 10, 12]
        total = 0
        for i, tier in enumerate(self.tiers):
            total += sum(1 for it in tier if it[0] == "guard")
            if total != want[i]:
                notes.append(f"tier {i + 1} has {total} guards, wanted {want[i]}")
        return notes

    # -- output --------------------------------------------------------------------------------
    def counts(self):
        g = o = 0
        out = []
        for tier in self.tiers:
            g += sum(1 for it in tier if it[0] == "guard")
            o += sum(1 for it in tier if it[0] == "object")
            out.append((g, o))
        return out

    def sqf(self, title, lines):
        def num(v):
            s = f"{v:.2f}".rstrip("0").rstrip(".")
            return "0" if s in ("-0", "") else s

        def item(it):
            kind, cls, (x, y, z), d, extra = it
            cls_s = cls if cls == FLAG else f'"{cls}"'
            extra_s = "[" + ", ".join(f'"{e}"' if isinstance(e, str) else num(e) for e in extra) + "]"
            return f'["{kind}", {cls_s}, [{num(x)}, {num(y)}, {num(z)}], {num(d)}, {extra_s}]'

        out = ["/*", "    Description:"]
        out += ["    " + l if l else "" for l in [title] + lines]
        out += [
            "",
            "    Generated by tools/officegen/gen_bigoffices.py from tools/officegen/probe_offices.txt; edit the",
            "    generator, not this file.",
            "",
            "    Returns: ARRAY - [tier 1 additions, ..., tier 5 additions] (tiers apply cumulatively); an item is",
            '        [kind ("guard" or "object"), object class or guard role, [x, y, z] in the building\'s model',
            "        coordinates, direction relative to the building, extra]",
            "*/",
            "",
            "[",
        ]
        names = ["Tier 1", "Tier 2", "Tier 3", "Tier 4", "Tier 5"]
        for i, tier in enumerate(self.tiers):
            g, o = self.counts()[i]
            out.append(f"    [ // {names[i]}: {g} guards, {o} objects in all")
            for j, it in enumerate(tier):
                out.append("        " + item(it) + ("," if j < len(tier) - 1 else ""))
            out.append("    ]" + ("," if i < 4 else ""))
        out.append("]")
        return "\n".join(out) + "\n"

    def draw(self, pad=8):
        """The cell maps with the layout drawn on, padded round the bbox so the compound shows:
        G guard, o object, f fence piece, D door, + unused building position."""
        p = self.probe
        out = []
        xs = range(p.x0 - pad, int(math.floor(p.bmax[0])) + pad + 1)
        ys = range(int(math.ceil(p.bmin[1])) - pad, int(math.floor(p.bmax[1])) + pad + 1)
        for lvl in p.levels:
            rows = p.rows.get(lvl, {})
            if not rows:
                continue
            grid = {y: [p.cell(lvl, x, y) for x in xs] for y in ys}

            def mark(x, y, ch):
                yi, xi = int(round(y)), int(round(x)) - xs[0]
                if yi in grid and 0 <= xi < len(grid[yi]):
                    grid[yi][xi] = ch

            for x, y, z in p.positions:
                if abs(p.level_of(z) - lvl) < 0.01:
                    mark(x, y, "+")
            for x, y, z in p.doors:
                if abs(p.level_of(z) - lvl) < 0.01:
                    mark(x, y, "D")
            for tier in self.tiers:
                for kind, cls, (x, y, z), d, _ in tier:
                    if abs(p.level_of(z) - lvl) < 0.01:
                        mark(x, y, "G" if kind == "guard" else ("f" if cls == "Land_HBarrier_5_F" else "o"))
            out.append(f"--- {p.cls} level {lvl} (x from {xs[0]}) ---")
            for y in sorted(grid, reverse=True):
                out.append(f"{y:4d} |" + "".join(grid[y]))
        return "\n".join(out)


# ----------------------------------------------------------------------------------------------
# Land_Offices_01_V1_F
# ----------------------------------------------------------------------------------------------
# Probe facts (model coordinates, building at dir 0):
#   levels G=-6.7, L1=-3, L2=1, L3=5, roof R=10.2; bbox +-17.8 x +-14.3 but the block itself is
#   x -17.5..13.3, y -12.5..8.6 (an L: the west leg runs to y=-12.5, the main block to y=-8.5).
#   Only the east tower section x -1..12 is enterable (G..L3), with a switchback stair core at
#   x -1.5..3.5, y -5.5..-0.5 and a ground-floor lobby strip along the whole north face (y 5..8).
#   Exterior doors: the south double door (10.4,-7.7) onto the porch and the NW door (-14.8,8.4);
#   internal doors (7.9,6), (11.3,0.3) on G and (6.2,0.1), (7.9,-5.6) on L3. The roof is one open
#   terrace with positions along the parapets. Upper-floor window positions stand under 1 m from
#   the glass, so their sandbags go beside the guard along the window line, not in front.

def offices_01(p):
    G, L1, L2, L3, R = -6.7, -3.0, 1.0, 5.0, 10.2
    MAIN = (10.4, -7.7, 180, -5.8)     # the double door, faces south
    NW = (-14.8, 8.4, 0, -6.0)         # side door at the west end of the lobby strip, faces north
    t = Template(p, [MAIN, NW], [(7.9, 6.0, -6.1), (11.3, 0.3, -6.1), (6.2, 0.1, 5.7), (7.9, -5.6, 5.9)])

    # ---- Tier 1: four gendarmes, the reception, the mayor's office ---------------------------
    t.guard(1, "gendarme", (12.1, -6.9, G), 180)        # entrance hall, by the double door
    t.guard(1, "gendarme", (0.6, 7.6, G), 0)            # north lobby strip
    t.guard(1, "gendarme", (4.1, -6.7, L1), 180)        # 1st floor south window
    t.guard(1, "gendarme", (12.2, -0.3, L3), 90)        # top floor east window
    # reception desk inside the entrance (east strip, 4 m wide: desk across it leaves 2 m to walk)
    t.obj(1, "Land_TableDesk_F", (11.5, -3.0, G), 180, inside=True)
    t.obj(1, "Land_OfficeChair_01_F", (11.5, -2.2, G), 180, inside=True)
    t.obj(1, "Land_WaterCooler_01_new_F", (12.4, -1.4, G), 270, inside=True)
    # waiting area and cabinets along the lobby strip's inner (south) wall
    t.obj(1, "Land_CampingChair_V2_F", (-11.0, 5.1, G), 0, inside=True)
    t.obj(1, "Land_CampingChair_V2_F", (-12.0, 5.1, G), 0, inside=True)
    t.obj(1, "Land_OfficeCabinet_01_F", (-6.0, 4.95, G), 0, inside=True)
    t.obj(1, "Land_OfficeCabinet_01_F", (-7.0, 4.95, G), 0, inside=True)
    t.obj(1, "MapBoard_altis_F", (-15.3, 5.1, G), 0, inside=True)   # town notices by the side door
    # the mayor's corner office on the top floor (east strip): desk facing the door in the west wall
    t.obj(1, "Land_TableDesk_F", (10.8, -2.2, L3), 270, inside=True)
    t.obj(1, "Land_OfficeChair_01_F", (11.6, -2.2, L3), 270, inside=True)
    t.obj(1, "Land_FilingCabinet_01_F", (9.4, 0.15, L3), 180, inside=True)
    t.obj(1, "Land_FilingCabinet_01_F", (10.1, 0.15, L3), 180, inside=True)
    t.obj(1, "Land_OfficeCabinet_01_F", (8.95, -2.0, L3), 90, inside=True)

    # ---- Tier 2: a military pair, sandbag nests flanking both doors --------------------------
    t.guard(2, "rifleman", (5.6, -7.1, G), 180)         # hall, south windows
    t.guard(2, "autorifleman", (1.8, -6.7, L2), 180)    # 2nd floor south window
    t.nests(2, MAIN, z=G)                               # on/just off the porch, either side of the lane
    t.nests(2, NW, z=G)

    # ---- Tier 3: fireteam with its officer, HESCO at the doors, sandbagged windows, radio room
    t.guard(3, "rifleman", (6.6, -7.0, L1), 180)
    t.guard(3, "officer", (10.3, -7.1, L3), 180)        # in the corner office
    t.barriers(3, MAIN, z=G)
    t.barriers(3, NW, z=G)
    t.window_bags(3, (5.6, -7.1, G), 180, offset=0.9)   # ground floor has room to the glass
    t.obj(3, "Land_BagFence_Short_F", (5.35, -7.4, L1), 180, inside=True)   # between the two L1 guards
    t.obj(3, "Land_BagFence_Short_F", (3.4, -7.4, L2), 180, inside=True)    # either side of the autorifleman
    t.obj(3, "Land_BagFence_Short_F", (-0.2, -7.4, L2), 180, inside=True)
    t.obj(3, "Land_BagFence_Short_F", (12.45, -1.8, L3), 90, inside=True)   # east window south of the guard
    t.obj(3, "Land_BagFence_Short_F", (11.9, -7.4, L3), 180, inside=True)   # the officer's window bay
    # radio room: the small top-floor room north of the office (x 4..7, y 1..4), door at (6.2,0.1)
    t.obj(3, "Land_CampingTable_F", (5.3, 2.4, L3), 90, inside=True)
    t.obj(3, "Land_PortableLongRangeRadio_F", (5.3, 2.4, L3 + TABLE_TOP), 90)
    t.obj(3, "Land_CampingChair_V2_F", (4.5, 2.4, L3), 90, inside=True)
    t.obj(3, "MapBoard_altis_F", (5.5, 3.9, L3), 180, inside=True)
    t.obj(3, FLAG, (14.6, -10.0, G), 0)                 # occupier's flag beside the entrance porch

    # ---- Tier 4: squad; wire, roof nests, approach barricades --------------------------------
    t.guard(4, "mg_gunner", (12.3, -7.2, R), 135)       # roof SE corner over the entrance
    t.guard(4, "rifleman", (-5.8, 7.3, R), 0)           # roof north parapet over the side door
    t.wire(4, MAIN, z=G)
    t.hedgehogs(4, MAIN, z=G)
    t.chicane(4, MAIN, z=G)
    # the side door sits 2.7 m from the west corner: wire east of its lane only, a barrier west
    t.wire(4, NW, z=G, sides=(1,))
    t.obj(4, "Land_CncBarrier_stripes_F", (-19.3, 14.4, G), 0)
    t.hedgehogs(4, NW, z=G)
    t.chicane(4, NW, z=G)
    t.obj(4, "Land_BagFence_Short_F", (12.3, -8.1, R), 180)          # L-nest at the MG's corner
    t.obj(4, "Land_BagFence_Short_F", (13.1, -7.2, R), 90)
    t.window_bags(4, (-5.8, 7.3, R), 0, offset=1.0)                  # north parapet
    t.obj(4, "Land_BagFence_Short_F", (-16.9, -0.7, R), 270)         # west parapet, by (-16.2,-0.7)
    t.obj(4, "Land_BagFence_Short_F", (12.9, -0.9, R), 90)           # east parapet, by (12.4,-0.9)
    t.obj(4, "Land_Ammobox_rounds_F", (11.0, -5.8, R), 90)           # the MG's ammunition

    # ---- Tier 5: marksman and AT, reinforced rooms, the compound -----------------------------
    t.guard(5, "marksman", (4.6, -6.5, R), 180)         # roof south edge, over the approach
    t.window_bags(5, (4.6, -6.5, R), 180, offset=1.0)
    # reinforced rooms: sandbag lines along the windows of the hall, lobby, 1st floor and office
    t.obj(5, "Land_BagFence_Long_F", (2.0, -8.0, G), 180, inside=True)
    t.obj(5, "Land_BagFence_Long_F", (-9.0, 8.1, G), 0, inside=True)
    t.obj(5, "Land_BagFence_Long_F", (0.7, -7.4, L1), 180, inside=True)
    t.obj(5, "Land_BagFence_Short_F", (12.45, -3.6, L3), 90, inside=True)
    t.obj(5, "Land_BagFence_Short_F", (12.45, -5.5, L3), 90, inside=True)
    t.obj(5, "Land_BagFence_Corner_F", (4.6, -3.9, G), 45, inside=True)   # cover at the stair foot
    # the perimeter: HESCO ring 5.5 m outside the bbox, one gate on the south in line with the door
    xmin, ymin = p.bmin[0] - 5.5, p.bmin[1] - 5.5
    xmax, ymax = p.bmax[0] + 5.5, p.bmax[1] + 5.5
    gate_x = MAIN[0]
    t.perimeter(5, xmin, ymin, xmax, ymax, G, gate=("south", gate_x, 5.5))
    t.obj(5, "Land_BagBunker_Small_F", (gate_x - 5.0, ymin + 2.3, G), 180)
    t.obj(5, "Land_BagBunker_Small_F", (gate_x + 5.0, ymin + 2.3, G), 180)
    t.guard(5, "at", (gate_x - 5.0, ymin + 2.6, G), 180, snap=False)      # the gate guard
    t.obj(5, "Land_CncBarrier_stripes_F", (gate_x - 1.5, ymin, G), 210)   # half-closes the gate
    t.obj(5, "Land_Razorwire_F", (gate_x - 7.0, ymin - 2.2, G), 180)
    t.obj(5, "Land_Razorwire_F", (gate_x + 7.0, ymin - 2.2, G), 180)
    t.obj(5, "Land_CzechHedgehog_01_F", (gate_x - 2.6, ymin - 3.6, G), 45)
    t.obj(5, "Land_CzechHedgehog_01_F", (gate_x + 2.6, ymin - 3.6, G), 45)
    t.obj(5, FLAG, (-9.0, -10.5, R), 0)                 # second flag on the roof of the west leg

    return t, "Mayor's office defence template for Land_Offices_01_V1_F (the Altis 5-storey office block).", [
        "Guards hold the entrance hall, the north lobby, the south windows of each floor, the top-floor",
        "corner office and from tier 4 the roof parapets; a reception desk sits inside the double door and",
        "the mayor's office (desk, cabinets) and a radio room are on the top floor. Fortifications flank the",
        "south double door and the north-west side door, and tier 5 adds a HESCO compound 5 m outside the",
        "bbox with its gate on the south, in line with the entrance.",
    ]


# ----------------------------------------------------------------------------------------------
# Land_Hospital_main_F (+ Land_Hospital_side1_F north wing, Land_Hospital_side2_F west wing)
# ----------------------------------------------------------------------------------------------
# Probe facts (main's model coordinates, composite at dir 0):
#   ground G=-7.8 is an open undercroft: the big covered bay x -37..13, y -21..-6 (pillars along
#   y=-6), the lobby lobe x -8..9, y -5..19 west of the main block with its entrance canopy strip
#   x -8..-3, and open forecourt further west/north-west (nothing in the model there). The blocks
#   above are solid; walkable roofs are the z=7.6 terrace ring (side1's roof, the strips either side
#   of the main block's top storey, the terrace over the bay) reached by the stair tower at the north
#   end of side1 (landings -4.2..5.7 at y=42), and side2's top roof at z=10.9/11.8.
#   Doors: A (12.2,19.8) in side1's south wall; B (2.9,15.8) and C (2.9,7.5) the main entrance pair on
#   the block's west face (the canopy and the x=-4.2 positions are outside them); D (-4.2,-7.9) and
#   E (-11.3,-18.5) in the bay, taken as facing south (no wall shows around them in the probe).

def hospital(p):
    G, R1, R2 = -7.8, 7.6, 10.9
    R2b = 11.8                      # side2's roof positions
    A = (12.2, 19.8, 180, -6.9)
    B = (2.9, 15.8, 270, -8.2)
    C = (2.9, 7.5, 270, -8.2)
    D = (-4.2, -7.9, 180, -8.2)
    E = (-11.3, -18.5, 180, -6.9)
    t = Template(p, [A, B, C, D, E])

    # ---- Tier 1: gendarmes on the entrance and the bay, the reception under the canopy -------
    t.guard(1, "gendarme", (-4.2, 7.5, G), 270)         # outside the main doors, under the canopy
    t.guard(1, "gendarme", (6.8, 4.6, G), 270)          # lobby lobe under the block
    t.guard(1, "gendarme", (-4.2, 15.9, G), 270)        # north door of the pair
    t.guard(1, "gendarme", (-2.9, -14.5, G), 180)       # the bay, between doors D and E
    t.obj(1, "Land_TableDesk_F", (-5.8, 11.65, G), 270, inside=True)      # faces the forecourt
    t.obj(1, "Land_OfficeChair_01_F", (-5.0, 11.65, G), 270, inside=True)
    t.obj(1, "Land_CampingChair_V2_F", (-7.5, 8.6, G), 90, inside=True)   # waiting area
    t.obj(1, "Land_CampingChair_V2_F", (-7.5, 9.8, G), 90, inside=True)
    t.obj(1, "MapBoard_altis_F", (-7.6, 13.6, G), 90, inside=True)
    t.obj(1, "Land_WaterCooler_01_new_F", (-3.4, 18.6, G), 270, inside=True)

    # ---- Tier 2: military pair, nests at every door -----------------------------------------
    t.guard(2, "rifleman", (-15.7, -9.1, G), 180)       # west end of the bay, door E side
    t.guard(2, "autorifleman", (2.6, 14.5, R1), 270)    # terrace strip right above the entrance
    for door in (A, B, C, D, E):
        t.nests(2, door, z=G)
    t.obj(2, "Land_OfficeCabinet_01_F", (-7.6, 15.0, G), 90, inside=True)
    t.obj(2, "Land_OfficeCabinet_01_F", (-7.6, 16.0, G), 90, inside=True)

    # ---- Tier 3: fireteam and officer; HESCO at the doors; command post; flag ----------------
    t.guard(3, "officer", (-4.1, 0.3, G), 180)          # command post at the lobby's south end
    t.guard(3, "rifleman", (13.1, -6.1, G), 90)         # east corner of the bay
    t.barriers(3, A, z=G)
    t.barriers(3, D, z=G)
    t.barriers(3, E, z=G)
    # the entrance pair shares one HESCO line at x=-1.7 with gaps in front of both doors; the
    # north flank is a single block, side1's wall is only 4 m from door B
    t.obj(3, "Land_HBarrier_3_F", (-1.7, 4.3, G), 270, inside=True)
    t.obj(3, "Land_HBarrier_3_F", (-1.7, 11.65, G), 270, inside=True)
    t.obj(3, "Land_HBarrier_1_F", (-1.7, 18.3, G), 270, inside=True)
    # firing positions covering the bay's open sides
    t.window_bags(3, (-2.9, -14.5, G), 180, offset=1.0)
    t.window_bags(3, (-15.7, -9.1, G), 180, offset=1.0)
    t.obj(3, "Land_BagFence_Short_F", (13.1, -4.9, G), 0)         # L-nest at the bay's NE corner
    t.obj(3, "Land_BagFence_Short_F", (14.3, -6.1, G), 90)
    # command post: radio table, map, board, cabinets
    t.obj(3, "Land_CampingTable_F", (-4.1, -1.4, G), 0, inside=True)
    t.obj(3, "Land_PortableLongRangeRadio_F", (-4.4, -1.4, G + TABLE_TOP), 0)
    t.obj(3, "Land_Map_altis_F", (-3.7, -1.4, G + TABLE_TOP), 90)
    t.obj(3, "Land_CampingChair_V2_F", (-2.8, -1.4, G), 270, inside=True)
    t.obj(3, "MapBoard_altis_F", (-6.6, -0.6, G), 90, inside=True)
    t.obj(3, "Land_FilingCabinet_01_F", (-7.6, -3.5, G), 90, inside=True)
    t.obj(3, "Land_FilingCabinet_01_F", (-7.6, -4.3, G), 90, inside=True)
    t.obj(3, FLAG, (-11.5, 3.0, G), 0)                   # on the forecourt, south of the lane

    # ---- Tier 4: squad; wire on the open sides, roof nests, approach barricades ---------------
    t.guard(4, "mg_gunner", (-5.3, -6.9, R1), 0)        # terrace over the bay, covers the forecourt
    t.guard(4, "rifleman", (13.3, -0.7, R1), 90)        # east terrace strip
    # razorwire either side of the entrance lane (forecourt edge) and along the bay's south edge
    t.obj(4, "Land_Razorwire_F", (-9.8, 1.0, G), 270)
    t.obj(4, "Land_Razorwire_F", (-9.8, 22.0, G), 270)
    for x in (-30.0, -21.5, 0.0, 8.5):
        t.obj(4, "Land_Razorwire_F", (x, -23.5, G), 180)
    t.hedgehogs(4, A, z=G)
    t.hedgehogs(4, D, lateral=3.5, z=G)     # wider: the bay guard's firing position is in between
    t.hedgehogs(4, E, lateral=2.5, z=G)
    t.chicane(4, A, z=G)
    # the lane in from the west: hedgehogs then a staggered pair of barriers
    t.obj(4, "Land_CzechHedgehog_01_F", (-13.5, 8.3, G), 45)
    t.obj(4, "Land_CzechHedgehog_01_F", (-13.5, 15.0, G), 45)
    t.obj(4, "Land_CncBarrier_stripes_F", (-17.5, 9.8, G), 300)
    t.obj(4, "Land_CncBarrier_stripes_F", (-22.0, 13.6, G), 240)
    # roof nests: manned ones plus the terrace corners
    t.window_bags(4, (2.6, 14.5, R1), 270, offset=0.85)
    t.obj(4, "Land_BagFence_Round_F", (-5.3, -5.6, R1), 0)
    t.window_bags(4, (13.3, -0.7, R1), 90, offset=1.0)
    t.window_bags(4, (-2.6, -19.9, R1), 180, offset=1.0)
    t.obj(4, "Land_BagFence_Short_F", (13.9, 24.8, R1), 90)
    t.obj(4, "Land_Ammobox_rounds_F", (-6.8, -7.4, R1), 0)
    t.obj(4, "Land_Camping_Light_F", (-5.6, -1.4, G), 0, inside=True)

    # ---- Tier 5: marksman on side2's roof, AT at the gate, reinforced rooms, the compound -----
    t.guard(5, "marksman", (-25.5, -8.7, R2b), 315)      # side2's roof, highest point over the forecourt
    t.window_bags(5, (-25.5, -8.7, R2b), 0, offset=1.0)
    t.obj(5, "Land_BagFence_Short_F", (-29.5, -20.5, R2b), 180)   # its second roof position
    # reinforced rooms: an L of sandbags round the command post, the lobby's open north end, the
    # canopy's forecourt edge and the bay's west end
    t.obj(5, "Land_BagFence_Long_F", (-4.1, -3.0, G), 180, inside=True)
    t.obj(5, "Land_BagFence_Short_F", (-6.3, -2.4, G), 270, inside=True)
    t.obj(5, "Land_BagFence_Long_F", (-5.3, 19.4, G), 0, inside=True)
    t.obj(5, "Land_BagFence_Long_F", (-8.8, 5.0, G), 270)
    t.obj(5, "Land_BagFence_Long_F", (-8.8, 17.6, G), 270)
    t.obj(5, "Land_BagFence_Long_F", (-18.5, -10.4, G), 180, inside=True)
    t.obj(5, "Land_BagFence_Corner_F", (-33.6, -8.9, G), 315, inside=True)  # by (-32.3,-7.8)
    # the compound: HESCO ring 5.5 m outside the composite's bbox, gate on the west (forecourt)
    # side in line with the entrance lane, two bunkers inside it, wire and hedgehogs outside
    xmin, ymin = p.bmin[0] - 5.5, p.bmin[1] - 5.5
    xmax, ymax = p.bmax[0] + 5.5, p.bmax[1] + 5.5
    gate_y = (B[1] + C[1]) / 2
    t.perimeter(5, xmin, ymin, xmax, ymax, G, gate=("west", gate_y, 6.0))
    t.obj(5, "Land_BagBunker_Small_F", (xmin + 2.4, gate_y - 6.2, G), 270)
    t.obj(5, "Land_BagBunker_Small_F", (xmin + 2.4, gate_y + 6.2, G), 270)
    t.guard(5, "at", (xmin + 2.7, gate_y + 6.2, G), 270, snap=False)      # the gate guard
    t.obj(5, "Land_CncBarrier_stripes_F", (xmin, gate_y - 1.7, G), 300)   # half-closes the gate
    t.obj(5, "Land_Razorwire_F", (xmin - 2.4, gate_y - 8.6, G), 270)
    t.obj(5, "Land_Razorwire_F", (xmin - 2.4, gate_y + 8.6, G), 270)
    t.obj(5, "Land_CzechHedgehog_01_F", (xmin - 4.4, gate_y - 2.6, G), 45)
    t.obj(5, "Land_CzechHedgehog_01_F", (xmin - 4.4, gate_y + 2.6, G), 45)
    t.obj(5, FLAG, (xmin + 4.0, gate_y - 9.5, G), 0)
    t.obj(5, FLAG, (-18.5, -15.5, R2), 0)               # on side2's roof

    return t, "Mayor's office defence template for the Kavala hospital (Land_Hospital_main_F with its two wings).", [
        "Positions are in the main building's model coordinates; the framework spawns the wings itself. Guards",
        "hold the entrance canopy, the lobby under the block, the covered bay on the south side and from tier 2",
        "the roof terraces (and side2's roof at tier 5); the canopy carries the reception and the lobby's south",
        "end a command post with radio and map. All five doors get nests then HESCO, the bay's open sides get",
        "firing positions and wire, and tier 5 rings the whole composite with HESCO 5 m outside its bbox, gated",
        "on the west (forecourt) side in line with the entrance.",
    ]


# ----------------------------------------------------------------------------------------------

BUILDINGS = {
    "Land_Offices_01_V1_F": offices_01,
    "Land_Hospital_main_F": hospital,
}


def main(argv):
    probes = parse_probe(PROBE)
    os.makedirs(OUT_DIR, exist_ok=True)
    failed = False
    for cls, build in BUILDINGS.items():
        p = probes[cls]
        t, title, lines = build(p)
        notes = t.check()
        key = cls[len("Land_"):]
        path = os.path.join(OUT_DIR, f"fn_officeTpl_{key}.sqf")
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(t.sqf(title, lines))
        counts = ", ".join(f"T{i + 1} {g}g/{o}o" for i, (g, o) in enumerate(t.counts()))
        print(f"{cls}: {os.path.relpath(path, ROOT)}  ({counts})")
        for n in notes:
            print("   NOTE " + n)
            failed = True
        if "--map" in argv:
            print(t.draw())
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
