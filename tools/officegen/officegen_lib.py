"""
The mayor's office building probe (Overthrow CE): reads tools/officegen/probe_offices.txt, written by the
QA addon's OTQA_fnc_probeOffices ("offices" suite), into each building's floor plan (Building): its levels,
the 1 m floor grids, the doors and their real doorways, the windows and the open-sky floor. compound_gen.py
and townlib.py use it for the office's real walls.

Everything is in the building's own model coordinates (building at direction 0): Arma's x is east,
y is north, z is up, and a direction of 0 points along +y, 90 along +x.
"""

import json
import math
import re

# ---------------------------------------------------------------- vectors


def dir_vec(d):
    """Unit vector of an Arma direction (0 = +y north, 90 = +x east)."""
    r = math.radians(d)
    return (math.sin(r), math.cos(r))


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
        near = [(n, -abs(a4)) for a4, n in counts.items() if -6 <= a4 <= 12]
        if not near:
            return None
        best = max(near)
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
