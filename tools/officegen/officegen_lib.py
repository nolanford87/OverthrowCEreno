"""
Shared library for the mayor's office defence template generators (Overthrow CE).

Reads the office building probe (tools/officegen/probe_offices.txt, written by the QA addon's
OTQA_fnc_probeOffices) and turns a building's floor plan into the five cumulative defence tiers,
written as an SQF template function (addons/overthrow_main/functions/offices/templates/
fn_officeTpl_<Key>.sqf, Key = the canonical class without "Land_", see template_key).

Everything is in the building's own model coordinates (building at direction 0): Arma's x is east,
y is north, z is up, and a direction of 0 points along +y, 90 along +x. Heights: an item's z is the
level (floor height from the probe) it stands on; items flagged "outside" stand on the ground and
the apply function snaps them to the terrain.

The rules (from the reviews of the first templates):
  1. Door defences are square with the real entrance: the probe's fine grid round each door gives
     the doorway's centre and width (Building.doorway), every door kit is centred on that axis.
  2. Tier 2 is a C-shaped nest 3 m out from the main door (a long bag across, short bags each end
     back towards the house, the way in at the sides) with the military pair inside it; side doors
     get a plain pair of bags; the back door gets a post at tier 3.
  3. Every fortification covers a guard or blocks an approach a guard watches: firing posts have a
     man behind them, wire runs along the sides no door opens to (so the way in is past the posts),
     vehicle stoppers stand 13 m out on the main approach where they block the line to the door.
  4. A guard stands at least 0.8 m behind his cover (GUARD_BEHIND, from the cover's near face).
  5. The tier 5 perimeter's gate is on the main door's axis, with a bar gate in the gap.
  6. The office furniture goes in the largest room: desk well off the wall facing the room, the
     chair behind it with room to sit, the map board on a wall nearby, nothing against a door.
  7. The tier 4 machine gunner takes a balcony or terrace when the building has one, bagged, facing
     the approach.
  8. Window posts (the fireteam, the marksman) stand at real windows (Building.windows, from the
     probe) facing out.

Template format (what each tier ADDS; the apply function places tiers 1..N cumulatively):
    [[tier 1 items], [tier 2 items], [tier 3 items], [tier 4 items], [tier 5 items]]
    item = [kind, what, [x, y, z], dir, extra]
        kind:  "guard", "object" or "doorway" (a marker of a real entrance, nothing is spawned for
               it: what = "main" | "back" | "side", pos = the doorway's centre at floor height,
               dir = outward, extra = [width, door index])
        what:  a guard role ("gendarme", "rifleman", "autorifleman", "marksman", "at",
               "mg_gunner", "officer") or an object class
        pos:   model position; z is the floor the item stands on (a level z from the probe)
        dir:   direction relative to the building
        extra: flags, may be []: "outside" (stands on the ground outside the building), "flag" (a
               flag carrier, gets the occupier's flag), "axis" (centred on a doorway's axis),
               "gate" (the perimeter's gate), "free" (a guard not at a building position: a
               balcony or window spot the generator checked)

A generator picks the buildings, tunes them with a spec dict (see build_tiers) and calls
write_template. The ASCII render (render) shows where everything went.
"""

import math
import os
import re
import json

# ---------------------------------------------------------------- object sizes (metres): length across (model x), depth (model y)

SIZES = {
    "Land_BagFence_Long_F": (2.9, 0.45),
    "Land_BagFence_Short_F": (1.5, 0.45),
    "Land_BagFence_Round_F": (1.9, 1.0),
    "Land_BagFence_Corner_F": (1.8, 1.8),
    "Land_BagFence_End_F": (0.6, 0.45),
    "Land_HBarrier_1_F": (1.2, 1.2),
    "Land_HBarrier_3_F": (3.6, 1.2),
    "Land_HBarrier_5_F": (6.0, 1.2),
    "Land_HBarrier_Big_F": (8.4, 2.4),
    "Land_Razorwire_F": (7.6, 1.0),
    "Land_CncBarrier_stripes_F": (2.6, 0.6),
    "Land_CncBarrierMedium_F": (4.0, 0.6),
    "Land_CzechHedgehog_01_F": (2.0, 2.0),
    "Land_BagBunker_Small_F": (3.2, 3.0),
    "Land_Mil_WallBig_4m_F": (4.0, 0.4),
    "Land_BarGate_F": (5.0, 0.6),
    "Land_TableDesk_F": (1.6, 0.9),
    "Land_OfficeChair_01_F": (0.6, 0.6),
    "Land_OfficeCabinet_01_F": (0.9, 0.5),
    "Land_MapBoard_F": (1.6, 0.3),
    "Land_PortableLongRangeRadio_F": (0.5, 0.3),
    "Land_CampingTable_F": (1.2, 0.6),
    "Land_CampingChair_V2_F": (0.6, 0.6),
    "Flag_NATO_F": (0.3, 0.3),
}


def size_of(cls):
    return SIZES.get(cls, (1.0, 1.0))


# Classes that count as fortifications (tier 1 has none of these)
FORTIFICATIONS = ("Land_BagFence", "Land_HBarrier", "Land_Razorwire", "Land_CncBarrier",
                  "Land_CzechHedgehog", "Land_BagBunker", "Land_Mil_Wall", "Land_SandbagBarricade", "Land_BarGate")

GUARD_ROLES = ("gendarme", "rifleman", "autorifleman", "marksman", "at", "mg_gunner", "officer")

GUARD_BEHIND = 0.9        # a guard this far behind his cover's near face (rule 4 asks 0.8)
NEST_OUT = 3.0            # the tier 2 nest's front, out from the main doorway's wall line
STOPPERS_OUT = 13.0       # the tier 4 vehicle stoppers on the main approach
GATE_OUT = 19.0           # the perimeter on the main door's side (the gate), out from its wall line
GATE_GAP = 6.0

# Guard counts per tier (what each tier adds) by building size; totals 10 / 11 / 12 at tier 5
GUARDS_BY_SIZE = {
    "small": [2, 2, 2, 2, 2],
    "medium": [3, 2, 2, 2, 2],
    "large": [4, 2, 2, 2, 2],
}

# ---------------------------------------------------------------- vectors


def dir_vec(d):
    """Unit vector of an Arma direction (0 = +y north, 90 = +x east)."""
    r = math.radians(d)
    return (math.sin(r), math.cos(r))


def vec_dir(dx, dy):
    """Arma direction of a vector."""
    return (math.degrees(math.atan2(dx, dy)) + 360.0) % 360.0


def norm_dir(d):
    return (d + 360.0) % 360.0


def dist2(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def offset(p, d, forward, lateral=0.0):
    """A point `forward` metres along direction d from p, and `lateral` metres to its right."""
    fx, fy = dir_vec(d)
    rx, ry = dir_vec(d + 90)
    return (p[0] + fx * forward + rx * lateral, p[1] + fy * forward + ry * lateral)


def along(p, origin, d):
    """(forward, lateral) of a point relative to an origin facing d."""
    fx, fy = dir_vec(d)
    rx, ry = dir_vec(d + 90)
    dx, dy = p[0] - origin[0], p[1] - origin[1]
    return (dx * fx + dy * fy, dx * rx + dy * ry)


def r2(v):
    """Rounded for the SQF output (no negative zero)."""
    v = round(float(v) + 0.0, 2)
    if v == 0:
        v = 0.0
    return v


def rdir(d):
    """A direction to the nearest of the four compass points."""
    return (int(round(norm_dir(d) / 90.0)) * 90) % 360


# ---------------------------------------------------------------- the probe


class Building:
    """One probed building: bounding box, doors, building positions, levels, the floor grids and,
    from the second probe, the fine grids round the doors, the windows and the open-sky floor."""

    def __init__(self, cls):
        self.cls = cls
        self.bmin = None
        self.bmax = None
        self.doors = []       # [x, y, z] (Door_N_trigger memory points, about 1 m above the floor)
        self.positions = []   # [x, y, z] building positions (floor height)
        self.levels = []      # floor heights
        self.rows = {}        # level z -> {y: row string}
        self.parts = []       # [[class, [x, y, z], dir], ...] for multi-piece buildings
        self.x0 = 0           # x of the first grid cell (ceil of bbox min x)
        self.doorgrids = {}   # door index -> {j: row} (0.25 m cells, k -14..14 across, j north)
        self.wincells = []    # (level z, x, y, dir, flags) raw window samples
        self.windows = []     # [cx, cy, level z, outward dir, width] merged
        self.opensky = {}     # level z -> set of (x, y) floor cells with nothing above

    # --- grid

    def cell(self, level, x, y):
        """The grid cell ('#' wall, '.' floor, ' ' nothing) nearest a point on a level."""
        rows = self.rows.get(level)
        if rows is None:
            return " "
        row = rows.get(int(round(y)))
        if row is None:
            return " "
        i = int(round(x)) - self.x0
        if i < 0 or i >= len(row):
            return " "
        return row[i]

    def level_of(self, z):
        """The level nearest a height."""
        return min(self.levels, key=lambda l: abs(l - z))

    def door_level(self, door):
        """The level a door stands on (its trigger point is about a metre above the floor)."""
        return self.level_of(door[2] - 1.0)

    @property
    def ground_z(self):
        return min(self.levels)

    @property
    def top_z(self):
        return max(self.levels)

    def is_building(self, level, x, y):
        return self.cell(level, x, y) != " "

    def footprint(self):
        """(min x, min y, max x, max y) of every floor or wall cell over all the levels, cell edges included."""
        xs, ys = [], []
        for lz, rows in self.rows.items():
            for y, row in rows.items():
                for i, c in enumerate(row):
                    if c != " ":
                        xs.append(self.x0 + i)
                        ys.append(y)
        if not xs:
            return (self.bmin[0], self.bmin[1], self.bmax[0], self.bmax[1])
        return (min(xs) - 0.5, min(ys) - 0.5, max(xs) + 0.5, max(ys) + 0.5)

    def centre(self):
        x0, y0, x1, y1 = self.footprint()
        return ((x0 + x1) / 2, (y0 + y1) / 2)

    def floor_cells(self, level):
        """[(x, y)] of every floor cell on a level."""
        out = []
        for y, row in self.rows.get(level, {}).items():
            for i, c in enumerate(row):
                if c == ".":
                    out.append((self.x0 + i, y))
        return out

    def positions_on(self, level):
        return [p for p in self.positions if abs(p[2] - level) <= 1.0]

    def is_open_sky(self, level, x, y):
        return (int(round(x)), int(round(y))) in self.opensky.get(level, set())

    # --- rooms

    def rooms(self, level):
        """The rooms of a level: connected floor cells under a roof, biggest first, each a dict
        {cells: set, size, level}."""
        cells = set(c for c in self.floor_cells(level) if not self.is_open_sky(level, *c))
        rooms = []
        seen = set()
        for c in sorted(cells):
            if c in seen:
                continue
            comp = set()
            stack = [c]
            while stack:
                q = stack.pop()
                if q in comp or q not in cells:
                    continue
                comp.add(q)
                x, y = q
                stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
            seen |= comp
            rooms.append({"cells": comp, "size": len(comp), "level": level})
        rooms.sort(key=lambda r: -r["size"])
        return rooms

    # --- walls

    def exterior_dirs(self, level, x, y, reach=3):
        """Directions from a floor point in which the building's outside is near, nearest first:
        [(dir, face distance)], the face distance being how far the outside wall's face is from the
        point (from the grid: a wall cell's face is about half a metre before its centre; an empty
        cell right after floor means the wall sits on the boundary between the two)."""
        out = []
        for d in (0, 90, 180, 270):
            fx, fy = dir_vec(d)
            seen_wall = None
            for k in range(1, reach + 1):
                cx, cy = int(round(x + fx * k)), int(round(y + fy * k))
                c = self.cell(level, cx, cy)
                a = (cx - x) * fx + (cy - y) * fy
                if c == "#":
                    if seen_wall is None:
                        seen_wall = max(0.1, a - 0.5)
                    continue
                if c == " ":
                    out.append((d, seen_wall if seen_wall is not None else max(0.1, a - 0.5)))
                    break
                if seen_wall is not None:
                    break
        out.sort(key=lambda t: t[1])
        return out

    def door_outside(self, door, reach=4):
        """The direction a door opens to the outside, or None for a door between rooms."""
        level = self.door_level(door)
        best, best_score = None, 0
        for d in (0, 90, 180, 270):
            fx, fy = dir_vec(d)
            score = 0
            for k in range(1, reach + 1):
                c = self.cell(level, door[0] + fx * k, door[1] + fy * k)
                if c == " ":
                    score += reach + 1 - k
                elif c == "#":
                    score -= 1
                else:
                    score -= reach + 1 - k
            if score > best_score:
                best, best_score = d, score
        return best

    def outside_k(self, level, p, d, reach=5):
        """How many cells out from p along d the first empty cell is (the wall is just before it)."""
        fx, fy = dir_vec(d)
        for k in range(1, reach + 1):
            if self.cell(level, p[0] + fx * k, p[1] + fy * k) == " ":
                return k
        return reach

    def doorway(self, i, d):
        """The real doorway of door i opening towards d, from the fine grid round its memory point:
        the wall line across d with the most wall in it, and the gap in that line nearest the point.
        {centre: (x, y, z), d, width, wall: distance of the wall line from the point along d}, or
        None when the fine grid is missing or shows no wall line (then the point itself is used)."""
        grid = self.doorgrids.get(i)
        if not grid:
            return None
        door = self.doors[i]
        z = self.door_level(door)
        fx, fy = dir_vec(d)
        rx, ry = dir_vec(d + 90)
        # cells by (forward, lateral) in 0.25 m steps
        cells = {}
        for j, row in grid.items():
            for k, c in enumerate(row):
                kk = k - 14
                a = round((kk * fx + j * fy) * 4) / 4.0 * 0.25 * 4 / 4  # 0.25 * (k·f + j·f)
                a = (kk * 0.25) * fx + (j * 0.25) * fy
                l = (kk * 0.25) * rx + (j * 0.25) * ry
                cells[(round(a * 4), round(l * 4))] = c
        counts = {}
        for (a4, l4), c in cells.items():
            if c == "#":
                counts[a4] = counts.get(a4, 0) + 1
        if not counts:
            return None
        # The wall line: the most wall between 1.5 m behind and 3 m before the point, nearest the point on ties
        best = max((n, -abs(a4)) for a4, n in counts.items() if -6 <= a4 <= 12)
        if best[0] < 8:
            return None
        a4 = -best[1]
        if (best[0], -a4) != best:
            a4 = [k for k, n in counts.items() if n == best[0] and -abs(k) == best[1]][0]
        # The gap in that line containing (or nearest) the point's lateral position
        line = {l4: cells.get((a4, l4), " ") for l4 in range(-14, 15)}
        start = 0
        if line.get(0, " ") == "#":
            opens = [l4 for l4 in range(-14, 15) if line[l4] != "#"]
            if not opens:
                return None
            start = min(opens, key=abs)
        lo = start
        while lo - 1 >= -14 and line[lo - 1] != "#":
            lo -= 1
        hi = start
        while hi + 1 <= 14 and line[hi + 1] != "#":
            hi += 1
        width = (hi - lo + 1) * 0.25
        if width > 4.0 or (lo == -14 and hi == 14):
            return None
        lat = (lo + hi) / 2.0 * 0.25
        a = a4 * 0.25
        cx, cy = offset(door, d, a, lat)
        return {"centre": (cx, cy, z), "d": d, "width": width, "wall": a, "index": i}

    def finish(self):
        """After parsing: each level at its floor's real height (the probe starts a level at its lowest
        position, a stair landing on the small shop; the median of its positions is the floor), the
        rows and open-sky cells keyed by their levels, the window samples merged into windows."""
        if self.levels:
            old = list(self.levels)
            new = []
            for lv in old:
                zs = sorted(p[2] for p in self.positions if lv - 0.5 <= p[2] <= lv + 1.0)
                med = zs[len(zs) // 2] if zs else lv
                new.append(round(med, 1) if abs(med - lv) > 0.3 else lv)
            remap = dict(zip(old, new))
            self.levels = new
            self.rows = {remap[min(old, key=lambda l: abs(l - lz))]: rows for lz, rows in self.rows.items()}
            fixed = {}
            for lz, cells in self.opensky.items():
                fixed.setdefault(remap[min(old, key=lambda l: abs(l - lz))], set()).update(cells)
            self.opensky = fixed
            self.wincells = [(remap[min(old, key=lambda l: abs(l - w[0]))],) + tuple(w[1:]) for w in self.wincells]
        # Windows: the three readings together (each catches windows the others miss), a reading left
        # out when it has most of the outer walls open (a geometry the rays miss altogether)
        def open_fraction(field):
            total = sum(4 for c in self.wincells)
            return (sum(c[field].count("1") for c in self.wincells) / total) if total else 0
        usable = [f for f, name in ((4, "geom"), (5, "view"), (6, "across")) if 0 < open_fraction(f) <= 0.6]
        self.windows_from = ",".join(name for f, name in ((4, "geom"), (5, "view"), (6, "across")) if f in usable) or "none"
        self.windows = self._merge_windows(usable)

    def _merge_windows(self, fields):
        """Samples with '1' in any of the readings along each outer wall, consecutive ones (0.25 m
        apart) as one window. Counted in eighths of a metre (the samples sit at odd eighths, which
        rounding to quarters would mix up)."""
        samples = {}
        for cell in self.wincells:
            lz, x, y, d = cell[0], cell[1], cell[2], cell[3]
            flags = ["1" if any(cell[f][i] == "1" for f in fields) else "0" for i in range(4)]
            fx, fy = dir_vec(d)
            # along the wall is across the outward direction; the wall line coordinate is the other one
            for s8, f in zip((-3, -1, 1, 3), flags):
                if f != "1":
                    continue
                if abs(fx) > 0.5:
                    samples.setdefault((lz, d, x * 8), []).append(y * 8 + s8)
                else:
                    samples.setdefault((lz, d, y * 8), []).append(x * 8 + s8)
        windows = []
        for (lz, d, line8), pts in samples.items():
            pts = sorted(set(pts))
            run = [pts[0]]
            for p in pts[1:] + [None]:
                if p is not None and p - run[-1] <= 2:
                    run.append(p)
                    continue
                c8 = (run[0] + run[-1]) / 2.0
                width = (run[-1] - run[0] + 2) / 8.0
                fx, fy = dir_vec(d)
                if abs(fx) > 0.5:
                    cx, cy = line8 / 8.0, c8 / 8.0
                else:
                    cx, cy = c8 / 8.0, line8 / 8.0
                if width >= 0.5:
                    windows.append([round(cx, 2), round(cy, 2), lz, d, round(width, 2)])
                if p is not None:
                    run = [p]
        return windows

    def windows_on(self, level):
        return [w for w in self.windows if abs(w[2] - level) < 0.5]


def parse_probe(path):
    """Every building in a probe file: {class: Building}."""
    data = {}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if not line.startswith("OTPROBE2|"):
                continue
            fields = line.split("|")
            kind = fields[1]
            if kind in ("SITE", "NOPARTS", "MISSING"):
                continue
            cls = fields[2]
            b = data.setdefault(cls, Building(cls))
            if kind == "START":
                b.bmin = json.loads(fields[3])
                b.bmax = json.loads(fields[4])
                b.x0 = math.ceil(b.bmin[0])
            elif kind == "DOORS":
                b.doors = json.loads(fields[4])
            elif kind == "POS":
                b.positions = json.loads(fields[4])
            elif kind == "LEVELS":
                b.levels = json.loads(fields[3])
            elif kind == "PARTS":
                b.parts = json.loads(fields[3].replace('""', '"'))
            elif kind == "ROW":
                lz = float(fields[3])
                y = int(fields[4])
                row = "|".join(fields[5:])
                b.rows.setdefault(lz, {})[y] = row
            elif kind == "DOORGRID":
                di, lz, j = int(fields[3]), float(fields[4]), int(fields[5])
                b.doorgrids.setdefault(di, {})[j] = "|".join(fields[6:])
            elif kind == "WINCELL":
                # up to three readings (older probe lines have fewer, repeated)
                flags = fields[7:10]
                while len(flags) < 3:
                    flags.append(flags[-1])
                b.wincells.append((float(fields[3]), int(fields[4]), int(fields[5]), int(float(fields[6])), flags[0], flags[1], flags[2]))
            elif kind == "OPENSKY":
                lz = float(fields[3])
                b.opensky.setdefault(lz, set()).update(tuple(c) for c in json.loads(fields[4]))
    for b in data.values():
        b.finish()
    return data


def template_key(cls):
    """The canonical template key of a class (Land_ stripped, the variants folded onto one)."""
    key = re.sub(r"^Land_", "", cls)
    key = re.sub(r"_b_[a-z]+_F$", "_V1_F", key)
    key = re.sub(r"_V[23]_F$", "_V1_F", key)
    key = re.sub(r"^u_", "i_", key)
    return key


# ---------------------------------------------------------------- items


def guard(role, pos, d, extra=None):
    assert role in GUARD_ROLES, role
    return ["guard", role, [r2(pos[0]), r2(pos[1]), r2(pos[2])], r2(norm_dir(d)), list(extra or [])]


def obj(cls, pos, d, extra=None):
    return ["object", cls, [r2(pos[0]), r2(pos[1]), r2(pos[2])], r2(norm_dir(d)), list(extra or [])]


def doorway_marker(role, dw):
    cx, cy, z = dw["centre"]
    return ["doorway", role, [r2(cx), r2(cy), r2(z)], r2(norm_dir(dw["d"])), [r2(dw["width"]), dw["index"]]]


def is_fortification(cls):
    return cls.startswith(FORTIFICATIONS)


# ---------------------------------------------------------------- the build


class Plan:
    """The working state of a template being built for one building."""

    def __init__(self, b, spec):
        self.b = b
        self.spec = spec
        self.tiers = [[], [], [], [], []]
        self.used_positions = []
        self.taken = []               # (x, y, z, radius) of everything placed, to keep items apart
        self.margin = spec.get("perimeter_margin", 5.0)
        self.log = []
        self.desk = None
        self.doorways = self.find_doorways()
        self.main = self.pick_main()
        self.back = self.pick_back()
        self.ring = self.ring_rect()

    # --- the doors

    def find_doorways(self):
        """The real entrances: [{centre, d, width, wall, index, role}], from the fine grids (or the
        memory points), plus the spec's extra doorways (buildings without door points)."""
        b = self.b
        out = []
        skip = self.spec.get("interior_doors", [])
        for i, door in enumerate(b.doors):
            if i in skip or abs(b.door_level(door) - b.ground_z) > 0.5:
                continue
            forced = self.spec.get("door_dirs", {}).get(i)
            d = forced if forced is not None else b.door_outside(door)
            if d is None:
                continue
            dw = b.doorway(i, d)
            if dw is None:
                level = b.door_level(door)
                k = b.outside_k(level, door, d)
                self.log.append("door %d: no fine grid or wall line, its point and the coarse grid used" % i)
                cx, cy = offset(door, d, k - 0.5)
                dw = {"centre": (cx, cy, level), "d": d, "width": 1.2, "wall": k - 0.5, "index": i}
            out.append(dw)
        for extra in self.spec.get("extra_doorways", []):
            cx, cy = extra["centre"]
            out.append({"centre": (cx, cy, b.level_of(extra.get("z", b.ground_z))), "d": extra["d"],
                        "width": extra.get("width", 1.2), "wall": 0.0, "index": -1})
        # A double door's two points are one doorway: the same way out, centres within 1.5 m
        merged = []
        for dw in out:
            twin = next((m for m in merged if rdir(m["d"]) == rdir(dw["d"]) and dist2(m["centre"], dw["centre"]) < 1.5), None)
            if twin is None:
                merged.append(dw)
                continue
            cx = (twin["centre"][0] + dw["centre"][0]) / 2.0
            cy = (twin["centre"][1] + dw["centre"][1]) / 2.0
            twin["centre"] = (cx, cy, twin["centre"][2])
            twin["width"] = max(twin["width"], dw["width"], dist2(twin["centre"], dw["centre"]) * 2 + dw["width"])
            twin["twins"] = twin.get("twins", [twin["index"]]) + [dw["index"]]
        for dw in merged:
            dw["role"] = "side"
        return merged

    def pick_main(self):
        """The main entrance: the spec's choice (an index into the doorways), else the widest with
        the most open ground outside."""
        if not self.doorways:
            return None
        idx = self.spec.get("main_door")
        if idx is not None:
            main = self.doorways[idx]
        else:
            def score(dw):
                n = 0
                level = dw["centre"][2]
                for f in range(1, 8):
                    for lat in (-2, 0, 2):
                        p = offset(dw["centre"], dw["d"], f, lat)
                        if self.b.cell(level, p[0], p[1]) == " ":
                            n += 1
                return (n, dw["width"])
            main = max(self.doorways, key=score)
        main["role"] = "main"
        return main

    def pick_back(self):
        """The back door: the one opening the other way from the main door, nearest its axis."""
        if not self.main:
            return None
        back = [dw for dw in self.doorways if dw is not self.main and rdir(dw["d"] - self.main["d"]) == 180]
        if not back:
            return None
        axis = lambda dw: abs(along(dw["centre"], self.main["centre"], self.main["d"])[1])
        b = min(back, key=axis)
        b["role"] = "back"
        return b

    def door_points(self):
        return [list(d) for d in self.b.doors] + [list(dw["centre"]) for dw in self.doorways]

    def clear_of_doors(self, p, radius=1.3):
        """Whether a point keeps clear of every door on its level (2D, the doors a storey apart don't count)."""
        for door in self.door_points():
            if abs(door[2] - 1.0 - p[2]) < 2.5 and dist2(door, p) < radius:
                return False
        return True

    # --- geometry

    def ring_rect(self):
        """The perimeter rectangle: the footprint plus the margin, pushed out to GATE_OUT from the
        main door's wall line on its side."""
        fx0, fy0, fx1, fy1 = self.b.footprint()
        m = self.margin
        x0, y0, x1, y1 = fx0 - m, fy0 - m, fx1 + m, fy1 + m
        if self.main:
            cx, cy, _ = self.main["centre"]
            d = rdir(self.main["d"])
            if d == 0:
                y1 = max(y1, cy + GATE_OUT)
            elif d == 180:
                y0 = min(y0, cy - GATE_OUT)
            elif d == 90:
                x1 = max(x1, cx + GATE_OUT)
            else:
                x0 = min(x0, cx - GATE_OUT)
        return (x0, y0, x1, y1)

    def in_ring(self, p, inset=0.0):
        x0, y0, x1, y1 = self.ring
        return x0 + inset <= p[0] <= x1 - inset and y0 + inset <= p[1] <= y1 - inset

    def clear_of_items(self, p, radius):
        """Whether a point is not on top of something already placed on its level (the levels are at
        least a metre apart; the Research HQ's are 2.2)."""
        for (x, y, z, r) in self.taken:
            if abs(z - p[2]) < 1.2 and math.hypot(x - p[0], y - p[1]) < max(0.5, (radius + r) / 2.0):
                return False
        return True

    def take(self, p, radius):
        self.taken.append((p[0], p[1], p[2], radius))

    def undo(self, tier, n=1):
        for _ in range(n):
            if self.tiers[tier - 1]:
                self.tiers[tier - 1].pop()
                self.taken.pop()

    def floor_ok(self, level, p, d=0, half=0.0):
        pts = [p]
        if half > 0:
            pts += [offset(p, d + 90, half), offset(p, d + 90, -half)]
        return all(self.b.cell(level, q[0], q[1]) == "." for q in pts)

    def outside_ok(self, level, p, d=0, half=0.0):
        pts = [p]
        if half > 0:
            pts += [offset(p, d + 90, half), offset(p, d + 90, -half)]
        return all(self.b.cell(level, q[0], q[1]) == " " for q in pts)

    # --- placing

    def add(self, tier, item, radius=0.6, check_ring=True, check_items=True, quiet=False):
        kind, what, pos, d, extra = item
        why = ""
        if kind == "object" and not self.clear_of_doors(pos):
            why = "too near a door"
        elif check_ring and not self.in_ring(pos, 0.5):
            why = "outside the perimeter"
        elif check_items and not self.clear_of_items(pos, radius):
            why = "on another item"
        if why:
            if not quiet:
                self.log.append("T%d %s at %s dropped: %s" % (tier, what, pos, why))
            return False
        self.tiers[tier - 1].append(item)
        self.take(pos, radius)
        return True

    def open_ground(self, level, p, d=0, half=0.0):
        """What a thing meant for the ground outside stands on: " " for the terrain, "." for a porch,
        steps or slab of the building (it settles onto that), None when a wall is in the way (its
        centre or, for a long piece, its ends)."""
        pts = [p]
        if half > 0:
            pts += [offset(p, d + 90, half), offset(p, d + 90, -half)]
        cells = [self.b.cell(level, q[0], q[1]) for q in pts]
        if "#" in cells:
            return None
        return self.b.cell(level, p[0], p[1])

    def add_object(self, tier, cls, p, d, z, extra=None, radius=None):
        """An object; one flagged "outside" must stand clear of the walls; on a porch or slab it loses
        the flag and settles onto that instead of the terrain."""
        if radius is None:
            radius = max(0.5, size_of(cls)[0] / 2.0)
        if extra and "outside" in extra:
            level = self.b.level_of(z)
            half = size_of(cls)[0] / 2.0 if size_of(cls)[0] >= 2.0 else 0.0
            ground = self.open_ground(level, p, d, half)
            if ground is None:
                self.log.append("T%d %s at %s dropped: a wall is there" % (tier, cls, (r2(p[0]), r2(p[1]))))
                return False
            if ground == ".":
                extra = [e for e in extra if e != "outside"]
        return self.add(tier, obj(cls, (p[0], p[1], z), d, extra), radius)

    def add_guard(self, tier, role, p, d, z, extra=None, quiet=False):
        """A guard; one flagged "outside" must stand clear of the walls; on a porch or slab he is a
        "free" spot (not a building position) instead."""
        if extra and "outside" in extra:
            ground = self.open_ground(self.b.level_of(z), p)
            if ground is None:
                if not quiet:
                    self.log.append("T%d %s at %s dropped: a wall is there" % (tier, role, (r2(p[0]), r2(p[1]))))
                return False
            if ground == ".":
                extra = [e for e in extra if e != "outside"] + ["free"]
        return self.add(tier, guard(role, (p[0], p[1], z), d, extra), 0.4, quiet=quiet)

    def add_marker(self, tier, item):
        self.tiers[tier - 1].append(item)

    # --- guard spots

    def position_free(self, p):
        return not any(dist2(p, u) < 0.3 and abs(p[2] - u[2]) < 1 for u in self.used_positions)

    def free_positions(self, level=None, near=None):
        """Building positions not yet used, on a level (any when None), nearest to a point first. A
        position off every floor's height (a stair landing) is left alone."""
        out = []
        for p in self.b.positions:
            if not self.position_free(p):
                continue
            if level is not None and abs(p[2] - level) > 1.0:
                continue
            if min(abs(p[2] - l) for l in self.b.levels) > 0.5:
                continue
            out.append(p)
        if near is not None:
            out.sort(key=lambda p: dist2(p, near))
        return out

    def use_position(self, p):
        self.used_positions.append(p)

    def facing(self, level, p):
        """Which way a guard at a point looks: a window near him, else the nearest outside wall, else the main door."""
        w = self.window_near(level, p)
        if w:
            return w[3]
        dirs = self.b.exterior_dirs(level, p[0], p[1], reach=2)
        if dirs:
            return dirs[0][0]
        if self.main:
            c = self.main["centre"]
            return vec_dir(c[0] - p[0], c[1] - p[1])
        return 0

    def place_guard_at_position(self, tier, role, p, face=None):
        level = self.b.level_of(p[2])
        d = face if face is not None else self.facing(level, p)
        if self.add_guard(tier, role, p, d, p[2]):
            self.use_position(p)
            return True
        return False

    def guard_in_building(self, tier, role, prefer_level=None, near=None):
        choices = []
        if prefer_level is not None:
            choices = self.free_positions(prefer_level, near=near)
        if not choices:
            choices = self.free_positions(None, near=near)
        for p in choices:
            if self.place_guard_at_position(tier, role, p):
                return True
        return False

    # --- windows and balconies

    def window_near(self, level, p, reach=1.8):
        ws = [w for w in self.b.windows_on(level) if dist2(w, p) <= reach]
        return min(ws, key=lambda w: dist2(w, p)) if ws else None

    def window_used(self, w):
        return any(dist2(w, u) < 0.3 and abs(w[2] - u[2]) < 0.5 for u in getattr(self, "used_windows", []))

    def use_window(self, w):
        if not hasattr(self, "used_windows"):
            self.used_windows = []
        self.used_windows.append(w)

    def window_posts(self, level, prefer_dir=None):
        """Free building positions at real windows on a level: [(position, window)], the ones facing
        prefer_dir first, then the widest windows."""
        out = []
        for p in self.free_positions(level):
            w = self.window_near(level, p)
            if w and not self.window_used(w):
                out.append((p, w))

        def key(t):
            w = t[1]
            return (0 if prefer_dir is not None and rdir(w[3]) == rdir(prefer_dir) else 1, -w[4], dist2(t[0], w))
        out.sort(key=key)
        return out

    def free_window_spots(self, level, prefer_dir=None):
        """Windows with no building position at them: a spot 0.9 m inside each, on floor."""
        out = []
        for w in self.b.windows_on(level):
            if self.window_used(w) or any(dist2(w, p) <= 1.8 for p in self.b.positions_on(level)):
                continue
            q = offset(w, w[3], -0.9)
            if self.b.cell(level, q[0], q[1]) == ".":
                out.append(((q[0], q[1], level), w))
        out.sort(key=lambda t: (0 if prefer_dir is not None and rdir(t[1][3]) == rdir(prefer_dir) else 1, -t[1][4]))
        return out

    def window_post(self, tier, role, level, prefer_dir=None):
        """A guard at a real window on a level (any level when None), bagged when there is room for
        the bag between him and the wall, facing out of the window. Returns whether one was made."""
        levels = [level] if level is not None else sorted(self.b.levels, reverse=True)
        for lv in levels:
            for p, w in self.window_posts(lv, prefer_dir):
                d = w[3]
                before = len(self.tiers[tier - 1])
                self.window_bag(tier, p, w)
                if self.place_guard_at_position(tier, role, p, d):
                    self.use_window(w)
                    return True
                self.undo(tier, len(self.tiers[tier - 1]) - before)
            for q, w in self.free_window_spots(lv, prefer_dir):
                d = w[3]
                before = len(self.tiers[tier - 1])
                self.window_bag(tier, q, w)
                if self.add_guard(tier, role, q, d, lv, ["free"]):
                    self.use_window(w)
                    return True
                self.undo(tier, len(self.tiers[tier - 1]) - before)
                self.use_window(w)  # nothing fits there, no point trying again
        return False

    def window_bag(self, tier, p, w, cls="Land_BagFence_Short_F"):
        """A bag between a post and its window when the wall is far enough for the man to stand
        GUARD_BEHIND behind the bag; the sill is his cover otherwise."""
        level = self.b.level_of(p[2])
        d = w[3]
        face = along(w, p, d)[0]  # the wall line's distance from the post
        gap = GUARD_BEHIND + size_of(cls)[1] / 2.0
        if face - gap < 0.45:
            return False
        q = offset(p, d, gap)
        if not self.floor_ok(level, q):
            return False
        return self.add_object(tier, cls, q, d, level, [], 0.6)

    def balcony_spot(self):
        """The balcony or terrace spot for the machine gunner: an open-sky floor cell on an upper
        level with an open side, the one nearest the main approach. ((x, y, z), facing) or None."""
        b = self.b
        main_d = self.main["d"] if self.main else 180
        best, best_score = None, None
        for level in b.levels:
            if level <= b.ground_z + 0.5:
                continue
            for (x, y) in b.opensky.get(level, set()):
                if any(dist2((x, y), u) < 1.0 and abs(u[2] - level) < 1 for u in self.used_positions):
                    continue
                opens = [d for d in (0, 90, 180, 270) if b.cell(level, *offset((x, y), d, 1)) == " "]
                if not opens:
                    continue
                # a facing: the open side nearest the main approach
                face = min(opens, key=lambda d: abs(((d - main_d + 180) % 360) - 180))
                towards = 1 if rdir(face) == rdir(main_d) else 0
                dist_axis = abs(along((x, y), self.main["centre"], main_d)[1]) if self.main else 0
                score = (towards, -dist_axis, level)
                if best_score is None or score > best_score:
                    best, best_score = ((x, y, level), face), score
        return best

    # --- the ground outside

    def door_out(self, dw, out, lat=0.0):
        """A ground point `out` metres outside a doorway's wall line, `lat` to the right facing out."""
        return offset(dw["centre"], dw["d"], out, lat)

    def nest(self, tier, dw):
        """Rule 2: the C-shaped nest at the main door: a long bag across the approach NEST_OUT out,
        short bags each end back towards the house, the way in at the sides."""
        d = dw["d"]
        z = dw["centre"][2]
        n = 0
        front = self.door_out(dw, NEST_OUT)
        if self.add_object(tier, "Land_BagFence_Long_F", front, d, z, ["outside", "axis"]):
            n += 1
        side_len = size_of("Land_BagFence_Short_F")[0]
        for lat in (-1.7, 1.7):
            p = self.door_out(dw, NEST_OUT - 0.2 - side_len / 2.0, lat)
            if self.add_object(tier, "Land_BagFence_Short_F", p, d + 90, z, ["outside"]):
                n += 1
        return n

    def nest_wings(self, tier, dw, cls="Land_HBarrier_3_F", lateral=4.2):
        """H-barriers either side of the main door's nest, square with the door, so the approach is
        walled in beyond the bags."""
        d = dw["d"]
        z = dw["centre"][2]
        n = 0
        for lat in (-lateral, lateral):
            p = self.door_out(dw, NEST_OUT - 0.5, lat)
            if self.outside_ok(self.b.level_of(z), p, d, size_of(cls)[0] / 2.0) and self.add_object(tier, cls, p, d, z, ["outside"]):
                n += 1
        return n

    def nest_guards(self, tier, dw, roles):
        """The pair inside the nest, GUARD_BEHIND behind its front, facing out."""
        d = dw["d"]
        z = dw["centre"][2]
        out = NEST_OUT - size_of("Land_BagFence_Long_F")[1] / 2.0 - GUARD_BEHIND
        placed = 0
        for role, lat in zip(roles, (-0.6, 0.6)):
            if self.add_guard(tier, role, self.door_out(dw, out, lat), d, z, ["outside"]):
                placed += 1
        return placed

    def door_pair(self, tier, dw, out=1.2, lateral=2.0, cls="Land_BagFence_Short_F"):
        """A plain pair of bags either side of a side door, square with it."""
        d = dw["d"]
        z = dw["centre"][2]
        n = 0
        for lat in (-lateral, lateral):
            p = self.door_out(dw, out, lat)
            if self.add_object(tier, cls, p, d, z, ["outside"]):  # the pair is square with the door, either side of its axis
                n += 1
        return n

    def door_post(self, tier, dw, role, cls="Land_BagFence_Short_F", out=2.2, lat=0.0):
        """Rule 2/3: a post outside a door: a bag across its axis with the man behind it facing out."""
        d = dw["d"]
        z = dw["centre"][2]
        depth = size_of(cls)[1]
        if not self.add_object(tier, cls, self.door_out(dw, out, lat), d, z, ["outside", "axis"] if lat == 0 else ["outside"]):
            return False
        if not self.add_guard(tier, role, self.door_out(dw, out - depth / 2.0 - GUARD_BEHIND, lat), d, z, ["outside"]):
            self.undo(tier)
            return False
        return True

    def side_post(self, tier, dw, role):
        """Rule 3: a firing post beside a side door: an H-barrier off the axis with the man behind it."""
        d = dw["d"]
        z = dw["centre"][2]
        cls = "Land_HBarrier_3_F"
        for lat in (4.2, -4.2):  # beyond the tier 2 pair of bags at 2 m
            p = self.door_out(dw, 2.6, lat)
            if not self.outside_ok(z, p, d, 1.5):
                continue
            if self.add_object(tier, cls, p, d, z, ["outside"]):
                q = self.door_out(dw, 2.6 - size_of(cls)[1] / 2.0 - GUARD_BEHIND, lat)
                if self.add_guard(tier, role, q, d, z, ["outside"]):
                    return True
                self.undo(tier)
        return False

    def stoppers(self, tier, dw):
        """Rule 3: vehicle stoppers STOPPERS_OUT out on the main approach: a striped barrier across the
        axis, hedgehogs either side of it."""
        d = dw["d"]
        z = dw["centre"][2]
        n = 0
        p = self.door_out(dw, STOPPERS_OUT)
        if self.in_ring(p, 1.5) and self.add_object(tier, "Land_CncBarrier_stripes_F", p, d, z, ["outside", "axis"]):
            n += 1
        for lat in (-2.8, 2.8):
            p = self.door_out(dw, STOPPERS_OUT - 0.8, lat)
            if self.in_ring(p, 1.5) and self.add_object(tier, "Land_CzechHedgehog_01_F", p, d + 45, z, ["outside"]):
                n += 1
        return n

    def wire_sides(self, tier, cls="Land_Razorwire_F", out=2.5):
        """Rule 3: razor wire along the outside walls that have no door, so the way in is past the posts."""
        b = self.b
        fx0, fy0, fx1, fy1 = b.footprint()
        z = b.ground_z
        sides = [
            (180, (fx0, fx1), fy0 - out, "y"),
            (0, (fx0, fx1), fy1 + out, "y"),
            (90, (fy0, fy1), fx1 + out, "x"),
            (270, (fy0, fy1), fx0 - out, "x"),
        ]
        length = size_of(cls)[0]
        n = 0
        door_sides = set(rdir(dw["d"]) for dw in self.doorways)
        for d, (a0, a1), c, axis in sides:
            if d in door_sides:
                continue
            span = a1 - a0
            count = int(span // (length + 0.3))
            if count < 1:
                continue
            start = (a0 + a1) / 2 - (count - 1) * (length + 0.3) / 2
            for i in range(count):
                a = start + i * (length + 0.3)
                p = (a, c) if axis == "y" else (c, a)
                if self.in_ring(p, 1.0) and self.add_object(tier, cls, p, d, z, ["outside"]):
                    n += 1
        return n

    def perimeter(self, tier, long_cls="Land_HBarrier_5_F", short_cls="Land_HBarrier_3_F", fill_cls="Land_HBarrier_1_F"):
        """Rule 5: the fenced perimeter on the ring rectangle with a GATE_GAP gap on the main door's
        axis, a bar gate in it and the AT man's spot behind the fence beside it. Returns the gate
        point and its outward direction (None without a main door)."""
        b = self.b
        x0, y0, x1, y1 = self.ring
        z = b.ground_z
        gate = None
        gate_side = None
        gate_at = None
        if self.main:
            d = rdir(self.main["d"])
            cx, cy, _ = self.main["centre"]
            gate_side = d
            gate_at = cx if d in (0, 180) else cy
        depth = 1.2
        sides = [
            (180, x0, x1, y0, "y"),
            (0, x0, x1, y1, "y"),
            (90, y0 + depth, y1 - depth, x1, "x"),
            (270, y0 + depth, y1 - depth, x0, "x"),
        ]
        self.gate_room = (0.0, 0.0)  # how far the fence runs either side of the gap (left, right facing out)
        for d, a0, a1, c, axis in sides:
            runs = [(a0, a1)]
            if d == gate_side:
                g = min(max(gate_at, a0 + GATE_GAP / 2 + 1), a1 - GATE_GAP / 2 - 1)
                runs = [(a0, g - GATE_GAP / 2), (g + GATE_GAP / 2, a1)]
                gate = ((g, c) if axis == "y" else (c, g), d)
                # facing out along d, the run at lower coordinates is on the right for the south and east sides
                lo, hi = g - GATE_GAP / 2 - a0, a1 - g - GATE_GAP / 2
                self.gate_room = (hi, lo) if d in (90, 180) else (lo, hi)
            for (r0, r1) in runs:
                self._fill_run(tier, d, r0, r1, c, axis, z, long_cls, short_cls, fill_cls)
        if gate:
            p, d = gate
            self.add(tier, obj("Land_BarGate_F", (p[0], p[1], z), d, ["outside", "axis", "gate"]), radius=0.3, check_ring=False, check_items=False)
        return gate

    def _fill_run(self, tier, d, r0, r1, c, axis, z, long_cls, short_cls, fill_cls):
        span = r1 - r0
        if span < 1.0:
            return
        pieces = []
        rest = span
        for cls in (long_cls, short_cls, fill_cls):
            L = size_of(cls)[0]
            while rest >= L - 0.2:
                pieces.append(cls)
                rest -= L
        if not pieces:
            return
        total = sum(size_of(p)[0] for p in pieces)
        slack = (span - total) / max(1, len(pieces))
        a = r0
        for cls in pieces:
            L = size_of(cls)[0]
            centre = a + L / 2 + slack / 2
            p = (centre, c) if axis == "y" else (c, centre)
            self.add(tier, obj(cls, (p[0], p[1], z), d, ["outside"]), radius=0.3, check_ring=False, check_items=False)
            a += L + slack

    def gate_guard(self, tier, role, gate):
        """The AT man behind the fence beside the gate, facing out, on the side with the longer run
        of fence (clear of the perimeter's corner)."""
        p, d = gate
        z = self.b.ground_z
        left, right = getattr(self, "gate_room", (9.0, 9.0))
        side = -1.0 if left >= right else 1.0
        q = offset(p, d, -(1.2 / 2.0 + GUARD_BEHIND), side * (GATE_GAP / 2.0 + 1.2))
        return self.add_guard(tier, role, q, d, z, ["outside"])

    # --- the office (rule 6)

    def office(self, tier=1):
        """The mayor's office in the biggest room: the chair by a wall, the desk 1.6 m into the room
        facing it, a map board on a wall nearby. Returns how many props went in."""
        b = self.b
        rooms = []
        for level in b.levels:
            rooms += b.rooms(level)
        if not rooms:
            return 0
        rooms.sort(key=lambda r: (-r["size"], r["level"]))
        near = self.spec.get("office_near")
        if near:
            # The spec's choice: the room holding (or nearest to) a point
            level = b.level_of(near[2])
            candidates = [r for r in rooms if r["level"] == level] or rooms
            biggest = min(candidates, key=lambda r: min(dist2(c, near) for c in r["cells"]))
        else:
            biggest = rooms[0]
            # the ground floor's room when it is nearly as big
            ground = [r for r in rooms if r["level"] == b.ground_z]
            if ground and ground[0]["size"] >= 0.75 * biggest["size"]:
                biggest = ground[0]
        level = biggest["level"]
        cells = biggest["cells"]
        best, best_score = None, None
        for (x, y) in cells:
            for back in (0, 90, 180, 270):
                wall = offset((x, y), back, 1)
                if b.cell(level, wall[0], wall[1]) == ".":
                    continue
                into = [offset((x, y), back, -k) for k in (1, 2, 3)]
                if any((int(round(q[0])), int(round(q[1]))) not in cells for q in into):
                    continue
                sides = [offset((x, y), back, 0, s) for s in (-1, 1)]
                if sum(1 for q in sides if (int(round(q[0])), int(round(q[1]))) in cells) < 2:
                    continue
                desk = offset((x, y), back, -1.6)
                if not self.clear_of_doors((x, y, level), 2.2) or not self.clear_of_doors((desk[0], desk[1], level), 2.2):
                    continue
                if any(dist2((x, y), p) < 1.4 or dist2(desk, p) < 1.4 for p in b.positions_on(level)):
                    continue
                door_dist = min([dist2((x, y), dp) for dp in self.door_points() if abs(dp[2] - 1 - level) < 2.5] or [9])
                # The main room: the most floor round the desk (a strip or a passage scores low), then away from the
                # doors; with the spec's point, nearest that point first
                openness = sum(1 for c in cells if dist2(c, desk) <= 2.5)
                if near:
                    score = (-round(dist2(desk, near)), min(openness, 18), min(door_dist, 6))
                else:
                    score = (min(openness, 18), min(door_dist, 6), -abs(x - sum(c[0] for c in cells) / len(cells)) - abs(y - sum(c[1] for c in cells) / len(cells)))
                if best_score is None or score > best_score:
                    best, best_score = ((x, y), back), score
        if not best:
            self.log.append("no room for the office")
            return 0
        (x, y), back = best
        n = 0
        # The desk's and the chair's model fronts face the wall (the review: "rotate 180")
        desk = offset((x, y), back, -1.6)
        if self.add_object(tier, "Land_TableDesk_F", desk, back, level, [], 0.9):
            n += 1
        chair = offset((x, y), back, 0.0)
        if self.add_object(tier, "Land_OfficeChair_01_F", chair, back, level, [], 0.4):
            n += 1
        self.desk = (desk[0], desk[1], level, back)
        # The map board: a wall cell of the room within 3.5 m, not the chair's, facing into the room
        boards = []
        for (bx, by) in cells:
            if dist2((bx, by), desk) > 3.5 or dist2((bx, by), (x, y)) < 1.2:
                continue
            for wd in (0, 90, 180, 270):
                w = offset((bx, by), wd, 1)
                if b.cell(level, w[0], w[1]) != "." and (int(round(w[0])), int(round(w[1]))) not in cells:
                    boards.append(((bx, by), wd))
        boards.sort(key=lambda t: dist2(t[0], desk))
        for (bx, by), wd in boards:
            m = offset((bx, by), wd, 0.35)
            if self.clear_of_doors((m[0], m[1], level), 1.6) and self.add_object(tier, "Land_MapBoard_F", m, wd + 180, level, [], 0.8):
                n += 1
                break
        return n

    def office_cover(self, tier):
        """Rule 3 (tier 5): a bag wall across the office room between the desk and the room's way in."""
        if not self.desk:
            return False
        x, y, z, back = self.desk
        wall = offset((x, y), back, -2.2)
        if self.floor_ok(z, wall, back, 1.45) and self.clear_of_doors((wall[0], wall[1], z), 1.6):
            return self.add_object(tier, "Land_BagFence_Long_F", wall, back + 180, z)
        return False

    def airlock(self, tier, dw, cls="Land_BagFence_Short_F"):
        """Bags inside the main door, a piece each side of the way in."""
        level = dw["centre"][2]
        d = dw["d"]
        n = 0
        for lat in (1.4, -1.4):
            p = offset(dw["centre"], d, -2.2, lat)
            if self.floor_ok(level, p, d, size_of(cls)[0] / 2.0) and self.add_object(tier, cls, p, d + 180, level):
                n += 1
        return n

    def flag(self, tier, dw):
        """The occupier's flag outside the main door, off the axis."""
        d = dw["d"]
        z = dw["centre"][2]
        for lat in (-3.3, 3.3, -4.5, 4.5):
            p = self.door_out(dw, 1.0, lat)
            if self.outside_ok(z, p) and self.add_object(tier, "Flag_NATO_F", p, d, z, ["outside", "flag"], 0.3):
                return True
        return False


def build_tiers(b, spec=None):
    """The five tiers for a building. spec keys (all optional):
        size: "small" | "medium" | "large" (default from the number of building positions)
        guards: [n1..n5] what each tier adds (default by size)
        main_door: index into the exterior doorways, interior_doors: [door indices to ignore],
        door_dirs: {door index: outside dir}, extra_doorways: [{centre: (x, y), d, width, z}]
        perimeter_margin: metres outside the footprint (default 5),
        office: False to leave the office props out, office_near: (x, y, z) the room and spot to
        put it in (default: the biggest room, the ground floor's when nearly as big),
        extra: {tier: [items]} hand-placed items added after the generated ones
    Returns (tiers, plan)."""
    spec = spec or {}
    plan = Plan(b, spec)
    n = len(b.positions)
    size = spec.get("size") or ("small" if n <= 9 else "medium" if n <= 30 else "large")
    counts = spec.get("guards") or GUARDS_BY_SIZE[size]
    ground = b.ground_z
    main, back = plan.main, plan.back
    main_d = main["d"] if main else None
    sides = [dw for dw in plan.doorways if dw["role"] == "side"]

    for dw in plan.doorways:
        plan.add_marker(1, doorway_marker(dw["role"], dw))

    # Tier 1: the office, the flag, the gendarmes inside by the doors
    if spec.get("office", True):
        plan.office(1)
    if main:
        plan.flag(1, main)
    for i in range(counts[0]):
        near = (main if i % 2 == 0 or not back else back)["centre"] if main else None
        if not plan.guard_in_building(1, "gendarme", ground, near=near):
            plan.guard_in_building(1, "gendarme")

    # Tier 2: the nest at the main door with the military pair in it, plain pairs at the side doors
    if main:
        plan.nest(2, main)
        placed = plan.nest_guards(2, main, ["rifleman", "autorifleman"][:counts[1]])
    else:
        placed = 0
    for dw in sides:
        plan.door_pair(2, dw)
    roles = ["rifleman", "autorifleman", "rifleman"]
    for i in range(placed, counts[1]):
        if not plan.window_post(2, roles[i % 3], ground, main_d):
            plan.guard_in_building(2, roles[i % 3], ground)

    # Tier 3: the main door's wings, a sandbagged window post, the back door's post, firing posts
    # beside the side doors, window posts for the rest
    roles = ["rifleman", "autorifleman", "rifleman"]
    placed = 0
    if main:
        plan.nest_wings(3, main)
    if counts[2] > 0 and (plan.window_post(3, roles[0], ground, main_d) or plan.window_post(3, roles[0], None, main_d)):
        placed += 1
    if back and placed < counts[2] and plan.door_post(3, back, roles[placed % 3]):
        placed += 1
    for dw in sides:
        if placed < counts[2] and plan.side_post(3, dw, roles[placed % 3]):
            placed += 1
    while placed < counts[2]:
        role = roles[placed % 3]
        if not plan.window_post(3, role, ground, main_d) and not plan.window_post(3, role, None, main_d) \
                and not plan.guard_in_building(3, role, ground):
            plan.log.append("T3: no post for a %s" % role)
            break
        placed += 1

    # Tier 4: wire on the sides without doors, the stoppers on the main approach, the machine gunner
    # on the balcony (or an upstairs window facing the approach), a rifleman at an upstairs window
    plan.wire_sides(4)
    if main:
        plan.stoppers(4, main)
    placed = 0
    if counts[3] > 0:
        spot = plan.balcony_spot()
        if spot:
            (x, y, z), face = spot
            level = z
            pos = next((p for p in plan.free_positions(level) if dist2(p, (x, y)) < 0.8), None)
            front = offset((x, y), face, GUARD_BEHIND + size_of("Land_BagFence_Short_F")[1] / 2.0)
            bag = b.is_open_sky(level, front[0], front[1]) and plan.add_object(4, "Land_BagFence_Short_F", front, face, level, [], 0.6)
            if pos is not None:
                ok = plan.place_guard_at_position(4, "mg_gunner", pos, face)
            else:
                ok = plan.add_guard(4, "mg_gunner", (x, y), face, level, ["free"])
            if ok:
                placed += 1
            elif bag:
                plan.undo(4)
    roles = ["mg_gunner", "rifleman", "autorifleman"]
    while placed < counts[3]:
        role = roles[placed % 3]
        if not plan.window_post(4, role, b.top_z if b.top_z > ground + 0.5 else None, main_d) \
                and not plan.window_post(4, role, None, main_d) and not plan.guard_in_building(4, role):
            plan.log.append("T4: no post for a %s" % role)
            break
        placed += 1

    # Tier 5: the perimeter with its gate and the AT man beside it, the airlock and the office's
    # cover, the marksman at an upstairs window over the approach
    gate = plan.perimeter(5)
    if main:
        plan.airlock(5, main)
    plan.office_cover(5)
    placed = 0
    if gate and counts[4] > 0 and plan.gate_guard(5, "at", gate):
        placed += 1
    roles = ["marksman", "at", "rifleman"]
    for i in range(counts[4] - placed):
        role = roles[i % 3]  # the marksman first, whether or not the gate took the AT man
        if not plan.window_post(5, role, b.top_z if b.top_z > ground + 0.5 else None, main_d) \
                and not plan.window_post(5, role, None, main_d) and not plan.guard_in_building(5, role):
            plan.log.append("T5: no post for a %s" % role)
            break
        placed += 1

    for tier, items in (spec.get("extra") or {}).items():
        for item in items:
            # A thing on a table (its z above the floor) may share the table's spot
            on_table = min(abs(item[2][2] - l) for l in b.levels) > 0.3
            plan.add(int(tier), item, 0.3, check_ring=False, check_items=not on_table)

    return plan.tiers, plan


# ---------------------------------------------------------------- checks and output


def guard_counts(tiers):
    out, n = [], 0
    for t in tiers:
        n += sum(1 for it in t if it[0] == "guard")
        out.append(n)
    return out


def check_tiers(b, tiers, plan=None):
    """Problems with a template, as strings (empty when it is fine). The same checks the QA test
    makes in the game (OTQA_fnc_testsOfficeTemplates), as far as the probe allows."""
    problems = []
    counts = guard_counts(tiers)
    ranges = [(2, 4), (4, 6), (6, 8), (8, 10), (10, 12)]
    for i, (lo, hi) in enumerate(ranges):
        if not lo <= counts[i] <= hi:
            problems.append("tier %d has %d guards, wanted %d-%d" % (i + 1, counts[i], lo, hi))
    for it in tiers[0]:
        if it[0] == "object" and is_fortification(it[1]):
            problems.append("tier 1 has a fortification: %s" % it[1])
    ring = plan.ring if plan else (b.bmin[0] - 22, b.bmin[1] - 22, b.bmax[0] + 22, b.bmax[1] + 22)
    doorways = [it for t in tiers for it in t if it[0] == "doorway"]
    forts = []
    for ti, t in enumerate(tiers):
        for it in t:
            kind, what, pos, d, extra = it
            if kind == "doorway":
                continue
            if kind == "guard" and what not in GUARD_ROLES:
                problems.append("tier %d: unknown guard role %s" % (ti + 1, what))
            if kind == "object":
                for door in b.doors:
                    if abs(door[2] - 1.0 - pos[2]) < 2.5 and dist2(door, pos) < 1.2:
                        problems.append("tier %d: %s at %s within 1.2 m of door %s" % (ti + 1, what, pos, door))
                if is_fortification(what):
                    forts.append(it)
                if "axis" in extra:
                    off = min([abs(along(pos, dw[2], dw[3])[1]) for dw in doorways] or [9])
                    if off > 0.5:
                        problems.append("tier %d: %s at %s is %.2f m off every doorway's axis" % (ti + 1, what, pos, off))
            if not (ring[0] - 1 <= pos[0] <= ring[2] + 1 and ring[1] - 1 <= pos[1] <= ring[3] + 1):
                problems.append("tier %d: %s at %s outside the perimeter" % (ti + 1, what, pos))
            off_floor = min(abs(pos[2] - l) for l in b.levels)
            if off_floor > 0.5 and (kind == "guard" or is_fortification(what) or off_floor > 1.0):
                problems.append("tier %d: %s at %s not at a floor height %s" % (ti + 1, what, pos, b.levels))
            if kind == "guard" and "outside" not in extra and "free" not in extra:
                if min((dist2(pos, p) for p in b.positions if abs(p[2] - pos[2]) < 1.0), default=9) > 0.8:
                    problems.append("tier %d: guard %s at %s not at a building position" % (ti + 1, what, pos))
    # Rule 4: a guard behind his cover
    for t in tiers:
        for it in t:
            if it[0] != "guard":
                continue
            gpos = it[2]
            for f in forts:
                if abs(f[2][2] - gpos[2]) > 1.5:
                    continue
                a, l = along(gpos, f[2], f[3])
                w, dp = size_of(f[1])
                if abs(l) <= w / 2.0 + 0.2 and abs(a) < dp / 2.0 + 0.8 - 0.01:
                    problems.append("guard %s at %s is %.2f m from %s at %s (behind its face: %.2f)" % (it[1], gpos, abs(a), f[1], f[2], abs(a) - dp / 2.0))
    return problems


def sqf_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        s = repr(r2(v))
        if s.endswith(".0"):
            s = s[:-2]
        return s
    if isinstance(v, str):
        return '"%s"' % v.replace('"', '""')
    return "[" + ", ".join(sqf_value(x) for x in v) + "]"


TIER_NAMES = [
    "Tier 1: the doorways, the office, the flag, the gendarmes",
    "Tier 2: the nest at the main door with the military pair, pairs of bags at the side doors",
    "Tier 3: the back door's post, firing posts at the side doors, window posts",
    "Tier 4: wire on the doorless sides, the stoppers on the approach, the gunner on the balcony, an upstairs post",
    "Tier 5: the perimeter and its gate with the AT man, the airlock, the office's cover, the marksman",
]


def write_template(path, key, cls, tiers, generator="tools/officegen/gen_templates.py", note=""):
    """Writes the SQF template function for a building (CRLF line endings like the rest of the mod)."""
    counts = guard_counts(tiers)
    lines = []
    lines.append("/*")
    lines.append("    Description:")
    lines.append("    Mayor's office defence template for %s (and the classes OT_fnc_officeTemplateKey maps" % cls)
    lines.append("    to \"%s\"): what each defence tier adds, in the building's model coordinates. Tier N in" % key)
    lines.append("    play is tiers 1..N together (OT_fnc_officeApplyTemplate). Guards at the five tiers: %s." % "/".join(str(c) for c in counts))
    if note:
        for n in note.split("\n"):
            lines.append("    " + n)
    lines.append("    Generated by %s from tools/officegen/probe_offices.txt, edit the" % generator)
    lines.append("    generator rather than this file.")
    lines.append("")
    lines.append("    Returns: ARRAY - [tier 1 additions, ..., tier 5 additions], each [[kind, class or role, [x, y, z], dir, extra], ...]")
    lines.append("        (kind \"doorway\": a marker of a real entrance for the checks, nothing is spawned for it)")
    lines.append("*/")
    lines.append("")
    lines.append("[")
    for i, t in enumerate(tiers):
        lines.append("    // %s" % TIER_NAMES[i])
        lines.append("    [")
        for j, it in enumerate(t):
            comma = "," if j < len(t) - 1 else ""
            lines.append("        %s%s" % (sqf_value(it), comma))
        lines.append("    ]%s" % ("," if i < len(tiers) - 1 else ""))
    lines.append("]")
    text = "\r\n".join(lines) + "\r\n"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    return path


def render(b, tiers, upto=5, ring=None):
    """An ASCII picture of a template on the building's grids, one per level, with the ground outside
    (G guard, s sandbag, h H-barrier, w wire, c concrete barrier, x hedgehog, p perimeter piece,
    g gate, f flag, d desk, o chair, m map board, W a window on a wall cell, : open-sky floor,
    P an unused building position, D a doorway)."""
    marks = {"Land_BagFence": "s", "Land_HBarrier": "h", "Land_Razorwire": "w", "Land_CncBarrier": "c",
             "Land_CzechHedgehog": "x", "Flag": "f", "Land_TableDesk": "d", "Land_OfficeChair": "o",
             "Land_MapBoard": "m", "Land_BarGate": "g"}
    if ring is None:
        ring = (b.bmin[0] - 5, b.bmin[1] - 5, b.bmax[0] + 5, b.bmax[1] + 5)
    x0, y0 = int(math.floor(ring[0])) - 1, int(math.floor(ring[1])) - 1
    x1, y1 = int(math.ceil(ring[2])) + 1, int(math.ceil(ring[3])) + 1
    out = []
    for level in b.levels:
        grid = {}
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                c = b.cell(level, x, y)
                if c == "." and b.is_open_sky(level, x, y):
                    c = ":"
                grid[(x, y)] = c
        for w in b.windows_on(level):
            grid[(int(round(w[0])), int(round(w[1])))] = "W"
        for p in b.positions_on(level):
            grid[(int(round(p[0])), int(round(p[1])))] = "P"
        for t in tiers[:upto]:
            for kind, what, pos, d, extra in t:
                if abs(pos[2] - level) > 1.0:
                    continue
                if kind == "doorway":
                    m = "D"
                elif kind == "guard":
                    m = "G"
                else:
                    m = "?"
                    for k, v in marks.items():
                        if what.startswith(k):
                            m = v
                    if what.startswith("Land_HBarrier") and "outside" in extra and not (
                            ring[0] + 1 < pos[0] < ring[2] - 1 and ring[1] + 1 < pos[1] < ring[3] - 1):
                        m = "p"
                grid[(int(round(pos[0])), int(round(pos[1])))] = m
        out.append("-- %s level z=%s (x %d..%d, y %d..%d)" % (b.cls, level, x0, x1, y0, y1))
        out.append("      " + "".join(str(abs(x) % 10) for x in range(x0, x1 + 1)))
        for y in range(y1, y0 - 1, -1):
            out.append("%5d " % y + "".join(grid[(x, y)] for x in range(x0, x1 + 1)))
    return "\n".join(out)
