"""
Shared library for the mayor's office defence template generators (Overthrow CE).

Reads the office building probe (tools/officegen/probe_offices.txt, written by the QA addon's
OTQA_fnc_probeOffices) and turns a building's floor plan into the five cumulative defence tiers,
written as an SQF template function (addons/overthrow_main/functions/offices/templates/
fn_officeTpl_<Key>.sqf, Key = the canonical class without "Land_").

Everything is in the building's own model coordinates (building at direction 0): Arma's x is east,
y is north, z is up, and a direction of 0 points along +y, 90 along +x. A door's "outside" is found
from the grid (the first cell with nothing in it, walking out from the door in the four directions).

Template format (what each tier ADDS; the apply function places tiers 1..N cumulatively):
    [[tier 1 items], [tier 2 items], [tier 3 items], [tier 4 items], [tier 5 items]]
    item = [kind, what, [x, y, z], dir, extra]
        kind:  "guard" or "object"
        what:  a guard role ("gendarme", "rifleman", "autorifleman", "marksman", "at",
               "mg_gunner", "officer") or an object class
        pos:   model position; z is the floor the item stands on (a level z from the probe)
        dir:   direction relative to the building
        extra: flags, may be []: "outside" (the item stands on the ground outside the building, the
               apply function snaps it to the terrain), "flag" (a flag carrier, the apply function
               gives it the occupier's flag)

A generator (tools/officegen/gen_templates.py for the houses) picks the buildings, tunes them with a
spec dict (see build_tiers) and calls write_template. The ASCII render (render) shows where
everything went, for checking a template before it is tried in the game.
"""

import math
import os
import re
import json

# ---------------------------------------------------------------- object sizes (metres, length along the piece)

SIZES = {
    "Land_BagFence_Long_F": 2.9,
    "Land_BagFence_Short_F": 1.5,
    "Land_BagFence_Round_F": 1.9,
    "Land_BagFence_Corner_F": 1.8,
    "Land_BagFence_End_F": 0.6,
    "Land_HBarrier_1_F": 1.2,
    "Land_HBarrier_3_F": 3.6,
    "Land_HBarrier_5_F": 6.0,
    "Land_HBarrier_Big_F": 8.4,
    "Land_Razorwire_F": 7.6,
    "Land_CncBarrier_stripes_F": 2.6,
    "Land_CncBarrierMedium_F": 4.0,
    "Land_CzechHedgehog_01_F": 2.0,
    "Land_BagBunker_Small_F": 3.2,
    "Land_Mil_WallBig_4m_F": 4.0,
    "Land_TableDesk_F": 1.6,
    "Land_OfficeChair_01_F": 0.6,
    "Land_OfficeCabinet_01_F": 0.9,
    "Land_MapBoard_F": 1.6,
    "Land_PortableLongRangeRadio_F": 0.5,
    "Flag_NATO_F": 0.3,
}

# Classes that count as fortifications (tier 1 has none of these)
FORTIFICATIONS = ("Land_BagFence", "Land_HBarrier", "Land_Razorwire", "Land_CncBarrier",
                  "Land_CzechHedgehog", "Land_BagBunker", "Land_Mil_Wall", "Land_SandbagBarricade")

GUARD_ROLES = ("gendarme", "rifleman", "autorifleman", "marksman", "at", "mg_gunner", "officer")

# How far out from a door its approach barricades go (the hedgehog), plus the ring's inset
APPROACH_REACH = 9.2

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


def r2(v):
    """Rounded for the SQF output (no negative zero)."""
    v = round(float(v) + 0.0, 2)
    if v == 0:
        v = 0.0
    return v


# ---------------------------------------------------------------- the probe


class Building:
    """One probed building: bounding box, doors, building positions, levels and the floor grids."""

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
        """Whether a point is on the building (floor or wall) at a level."""
        return self.cell(level, x, y) != " "

    def footprint(self):
        """(min x, min y, max x, max y) of every floor or wall cell over all the levels."""
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

    # --- walls

    def exterior_dirs(self, level, x, y, reach=3):
        """Directions from a floor point in which the building's outside is near: [(dir, wall distance)],
        wall distance being how far the exterior wall is from the point (estimated from the grid)."""
        out = []
        for d in (0, 90, 180, 270):
            fx, fy = dir_vec(d)
            seen_wall = None
            for k in range(1, reach + 1):
                c = self.cell(level, x + fx * k, y + fy * k)
                if c == "#":
                    if seen_wall is None:
                        seen_wall = k
                    continue
                if c == " ":
                    if seen_wall is not None:
                        out.append((d, float(seen_wall)))
                    else:
                        out.append((d, k - 0.25))
                    break
                # floor again: an inner wall, not the outside
                if seen_wall is not None:
                    break
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
                # SQF str output doubles the quotes
                b.parts = json.loads(fields[3].replace('""', '"'))
            elif kind == "ROW":
                lz = float(fields[3])
                y = int(fields[4])
                row = "|".join(fields[5:])
                b.rows.setdefault(lz, {})[y] = row
    for b in data.values():
        if b.levels:
            # Rows are keyed by the level values as printed, match them to the levels
            fixed = {}
            for lz, rows in b.rows.items():
                fixed[b.level_of(lz)] = rows
            b.rows = fixed
    return data


def template_key(cls):
    """The canonical template key of a class (Land_ stripped, variants folded)."""
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


def is_fortification(cls):
    return cls.startswith(FORTIFICATIONS)


# ---------------------------------------------------------------- the build


class Plan:
    """The working state of a template being built for one building."""

    def __init__(self, b, spec):
        self.b = b
        self.spec = spec
        self.tiers = [[], [], [], [], []]
        self.used_positions = []      # building positions taken by guards
        self.taken = []               # (x, y, z, radius) of everything placed, to keep items apart
        self.margin = spec.get("perimeter_margin", 5.0)
        self.log = []
        self.doors = self.exterior_doors()
        self.main = self.pick_main_door()
        self.ring = self.ring_rect()

    # --- geometry helpers

    def ring_rect(self):
        """The perimeter rectangle: the bounding box plus the margin, pushed out on the sides where a
        ground-floor door's approach barricades (up to APPROACH_REACH out from the door) need the room."""
        b = self.b
        m = self.margin
        x0, y0, x1, y1 = b.bmin[0] - m, b.bmin[1] - m, b.bmax[0] + m, b.bmax[1] + m
        for door, d, k in self.doors:
            if abs(b.door_level(door) - b.ground_z) > 0.5:
                continue
            reach = k + APPROACH_REACH
            if d == 0:
                y1 = max(y1, door[1] + reach)
            elif d == 180:
                y0 = min(y0, door[1] - reach)
            elif d == 90:
                x1 = max(x1, door[0] + reach)
            else:
                x0 = min(x0, door[0] - reach)
        return (x0, y0, x1, y1)

    def in_ring(self, p, inset=0.0):
        x0, y0, x1, y1 = self.ring
        return x0 + inset <= p[0] <= x1 - inset and y0 + inset <= p[1] <= y1 - inset

    def exterior_doors(self):
        """[(door [x, y, z], outside dir, k cells to the outside)] for the doors that open outside,
        plus the spec's extra doors (buildings without door memory points)."""
        out = []
        skip = self.spec.get("interior_doors", [])
        for i, door in enumerate(self.b.doors):
            if i in skip:
                continue
            forced = self.spec.get("door_dirs", {}).get(i)
            d = forced if forced is not None else self.b.door_outside(door)
            if d is None:
                continue
            level = self.b.door_level(door)
            out.append((list(door), d, self.b.outside_k(level, door, d)))
        for door, d in self.spec.get("extra_doors", []):
            level = self.b.level_of(door[2] - 1.0)
            out.append((list(door), d, self.b.outside_k(level, door, d)))
        return out

    def pick_main_door(self):
        """The main entrance: the spec's choice, else the ground-floor door with the most open ground outside."""
        if not self.doors:
            return None
        idx = self.spec.get("main_door")
        if idx is not None:
            return self.doors[idx]
        ground = [d for d in self.doors if abs(self.b.door_level(d[0]) - self.b.ground_z) < 0.5] or self.doors

        def openness(entry):
            door, d, k = entry
            level = self.b.door_level(door)
            n = 0
            for f in range(1, 7):
                for lat in (-2, 0, 2):
                    p = offset(door, d, f, lat)
                    if self.b.cell(level, p[0], p[1]) == " ":
                        n += 1
            return n

        return max(ground, key=openness)

    def door_points(self):
        return [d[0] for d in self.doors] + [list(d) for d in self.b.doors]

    def clear_of_doors(self, p, radius=1.3):
        """Whether a point keeps clear of every door on its level (2D, the doors a storey apart don't count)."""
        for door in self.door_points():
            if abs(door[2] - 1.0 - p[2]) < 2.5 and dist2(door, p) < radius:
                return False
        return True

    def clear_of_items(self, p, radius):
        """Whether a point is not on top of something already placed (half the two radii apart, at least 0.5 m)."""
        for (x, y, z, r) in self.taken:
            if abs(z - p[2]) < 2.0 and math.hypot(x - p[0], y - p[1]) < max(0.5, (radius + r) / 2.0):
                return False
        return True

    def take(self, p, radius):
        self.taken.append((p[0], p[1], p[2], radius))

    def undo(self, tier, n=1):
        """Takes the last n items back out of a tier (when the thing they were for could not be placed)."""
        for _ in range(n):
            if self.tiers[tier - 1]:
                self.tiers[tier - 1].pop()
                self.taken.pop()

    def floor_ok(self, level, p, d=0, half=0.0):
        """Whether a point (and the piece's two ends) are on floor cells of a level."""
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

    def add(self, tier, item, radius=0.6, check_ring=True):
        """Adds an item to a tier if it fits: clear of the doors (objects), inside the ring, not on top
        of another item. Returns whether it went in."""
        kind, what, pos, d, extra = item
        if kind == "object" and not self.clear_of_doors(pos):
            self.log.append("T%d %s at %s dropped: too near a door" % (tier, what, pos))
            return False
        if check_ring and not self.in_ring(pos, 0.5):
            self.log.append("T%d %s at %s dropped: outside the perimeter" % (tier, what, pos))
            return False
        if not self.clear_of_items(pos, radius):
            self.log.append("T%d %s at %s dropped: on another item" % (tier, what, pos))
            return False
        self.tiers[tier - 1].append(item)
        self.take(pos, radius)
        return True

    def add_object(self, tier, cls, p, d, z, extra=None, radius=None):
        if radius is None:
            radius = max(0.5, SIZES.get(cls, 1.0) / 2.0)
        return self.add(tier, obj(cls, (p[0], p[1], z), d, extra), radius)

    def add_guard(self, tier, role, p, d, z, extra=None):
        return self.add(tier, guard(role, (p[0], p[1], z), d, extra), 0.4)

    # --- guard spots

    def facing(self, level, p):
        """Which way a guard at a point looks: the nearest outside wall, else the main door."""
        dirs = self.b.exterior_dirs(level, p[0], p[1], reach=2)
        if dirs:
            return min(dirs, key=lambda t: t[1])[0]
        if self.main:
            door = self.main[0]
            return vec_dir(door[0] - p[0], door[1] - p[1])
        return 0

    def free_positions(self, level=None, near=None, window=False, exclude_outside_near_main=False):
        """Building positions not yet used: on a level, nearest to a point first, or next to an outside
        wall first (window positions)."""
        out = []
        for p in self.b.positions:
            if any(dist2(p, u) < 0.3 and abs(p[2] - u[2]) < 1 for u in self.used_positions):
                continue
            if level is not None and abs(p[2] - level) > 1.0:
                continue
            out.append(p)
        if window:
            lvl = self.b.level_of(level if level is not None else self.b.ground_z)

            def wall_dist(p):
                dirs = self.b.exterior_dirs(self.b.level_of(p[2]), p[0], p[1], reach=2)
                return min([t[1] for t in dirs], default=9)

            out.sort(key=wall_dist)
        elif near is not None:
            out.sort(key=lambda p: dist2(p, near))
        return out

    def use_position(self, p):
        self.used_positions.append(p)

    def place_guard_at_position(self, tier, role, p, face=None):
        level = self.b.level_of(p[2])
        d = face if face is not None else self.facing(level, p)
        if self.add_guard(tier, role, p, d, p[2]):
            self.use_position(p)
            return True
        return False

    def guard_in_building(self, tier, role, prefer_level=None, window=False, near=None):
        """A guard at a free building position (a level preferred, window positions first if asked)."""
        choices = []
        if prefer_level is not None:
            choices = self.free_positions(prefer_level, near=near, window=window)
        if not choices:
            choices = self.free_positions(None, near=near, window=window)
        for p in choices:
            if self.place_guard_at_position(tier, role, p):
                return True
        return False

    def guard_outside(self, tier, role):
        """A guard on the ground outside when the building positions have run out: behind the sandbags
        of a door, else a corner of the perimeter."""
        z = self.b.ground_z
        for door, d, k in self.doors:
            if abs(self.b.door_level(door) - z) > 0.5:
                continue
            for lat in (1.0, -1.0):
                p = offset(door, d, k + 0.4, lat)
                if self.outside_ok(self.b.ground_z, p) and self.add_guard(tier, role, p, d, z, ["outside"]):
                    return True
        x0, y0, x1, y1 = self.ring
        for (x, y) in ((x0 + 2, y0 + 2), (x1 - 2, y0 + 2), (x1 - 2, y1 - 2), (x0 + 2, y1 - 2)):
            d = vec_dir(x - (x0 + x1) / 2, y - (y0 + y1) / 2)
            if self.add_guard(tier, role, (x, y), d, z, ["outside"]):
                return True
        return False


def door_sandbags(plan, tier, door, d, k, cls="Land_BagFence_Short_F", lateral=2.0, out=0.6):
    """Sandbags flanking a door on the outside (a piece each side, the doorway left open)."""
    b = plan.b
    level = b.door_level(door)
    z = level
    half = SIZES[cls] / 2.0
    placed = 0
    for lat in (lateral, -lateral):
        p = offset(door, d, k + out, lat)
        behind = offset(door, d, k - 1, lat)
        if not plan.outside_ok(level, p, d, half):
            # Try a little further out (the wall may sit just inside the empty cell)
            p = offset(door, d, k + out + 0.5, lat)
            if not plan.outside_ok(level, p, d, half):
                plan.log.append("T%d door sandbag at %s skipped: not outside" % (tier, (r2(p[0]), r2(p[1]))))
                continue
        if not b.is_building(level, behind[0], behind[1]):
            plan.log.append("T%d door sandbag at %s skipped: past the building's corner" % (tier, (r2(p[0]), r2(p[1]))))
            continue
        if plan.add_object(tier, cls, p, d, z, ["outside"]):
            placed += 1
    return placed


def door_barrier(plan, tier, door, d, k, cls="Land_HBarrier_3_F", out=2.4, lateral=2.4):
    """A barrier in front of a door, off to one side so the way in stays open."""
    level = plan.b.door_level(door)
    half = SIZES[cls] / 2.0
    for lat in (lateral, -lateral):
        p = offset(door, d, k + out, lat)
        if plan.outside_ok(level, p, d, half) and plan.add_object(tier, cls, p, d, level, ["outside"]):
            return True
    return False


def door_approach(plan, tier, door, d, k):
    """Barricades on the approach to a door: a staggered pair of concrete barriers and a hedgehog further out."""
    level = plan.b.door_level(door)
    n = 0
    for f, lat in ((3.8, -2.0), (5.6, 1.6)):
        p = offset(door, d, k + f, lat)
        if plan.in_ring(p, 1.6) and plan.outside_ok(level, p, d, 1.3) and \
                plan.add_object(tier, "Land_CncBarrier_stripes_F", p, d, level, ["outside"]):
            n += 1
    p = offset(door, d, k + 7.4, -0.5)
    if plan.in_ring(p, 1.6) and plan.outside_ok(level, p) and \
            plan.add_object(tier, "Land_CzechHedgehog_01_F", p, d + 45, level, ["outside"]):
        n += 1
    return n


def door_airlock(plan, tier, door, d, k, cls="Land_BagFence_Short_F"):
    """Sandbags inside a door, a piece each side of the way in."""
    level = plan.b.door_level(door)
    half = SIZES[cls] / 2.0
    n = 0
    for lat in (1.4, -1.4):
        p = offset(door, d, -2.2, lat)
        if plan.floor_ok(level, p, d, half) and plan.add_object(tier, cls, p, d + 180, level):
            n += 1
    return n


def window_sandbag(plan, tier, p, cls="Land_BagFence_Short_F"):
    """A sandbag between a building position and the nearest outside wall. Returns the facing or None."""
    b = plan.b
    level = b.level_of(p[2])
    dirs = b.exterior_dirs(level, p[0], p[1], reach=2)
    if not dirs:
        return None
    d, wall = min(dirs, key=lambda t: t[1])
    gap = max(0.6, wall - 0.5)
    q = offset(p, d, gap)
    half = SIZES[cls] / 2.0
    ok = plan.floor_ok(level, q, d, half) or plan.floor_ok(level, q)
    if ok and plan.add_object(tier, cls, q, d, level):
        return d
    return None


def window_post(plan, tier, role, prefer_level):
    """A guard behind a sandbag at a building position next to an outside wall: on the preferred
    level if it has one, else any level; the sandbag is taken back if the guard cannot stand there.
    Returns whether a post was made."""
    candidates = plan.free_positions(prefer_level, window=True)
    candidates += [p for p in plan.free_positions(None, window=True) if p not in candidates]
    for p in candidates:
        level = plan.b.level_of(p[2])
        if not plan.b.exterior_dirs(level, p[0], p[1], reach=2):
            continue
        before = len(plan.tiers[tier - 1])
        d = window_sandbag(plan, tier, p)
        if d is None:
            continue
        if plan.place_guard_at_position(tier, role, p, d):
            return True
        plan.undo(tier, len(plan.tiers[tier - 1]) - before)
    return False


def wire_sides(plan, tier, cls="Land_Razorwire_F", out=2.5):
    """Razor wire along the outside walls that have no door, hugging the footprint."""
    b = plan.b
    fx0, fy0, fx1, fy1 = b.footprint()
    z = b.ground_z
    sides = [
        (180, (fx0, fx1), fy0 - out, "y"),  # south
        (0, (fx0, fx1), fy1 + out, "y"),    # north
        (90, (fy0, fy1), fx1 + out, "x"),   # east
        (270, (fy0, fy1), fx0 - out, "x"),  # west
    ]
    length = SIZES[cls]
    n = 0
    for d, (a0, a1), c, axis in sides:
        # Skip a side that has a door opening its way
        if any(dd == d for _, dd, _ in plan.doors):
            continue
        span = a1 - a0
        count = int(span // (length + 0.3))
        if count < 1:
            continue
        start = (a0 + a1) / 2 - (count - 1) * (length + 0.3) / 2
        for i in range(count):
            a = start + i * (length + 0.3)
            p = (a, c) if axis == "y" else (c, a)
            if plan.in_ring(p, 1.0) and plan.add_object(tier, cls, p, d, z, ["outside"]):
                n += 1
    return n


def perimeter(plan, tier, long_cls="Land_HBarrier_5_F", short_cls="Land_HBarrier_3_F",
              fill_cls="Land_HBarrier_1_F", gap=4.0, gate_cls="Land_CncBarrier_stripes_F"):
    """A fenced perimeter round the building on the ring rectangle, with one gap on the side the
    main door faces, a barrier beside the gap and the gate guard spot. Returns the gate point and
    its outward direction."""
    b = plan.b
    x0, y0, x1, y1 = plan.ring
    z = b.ground_z
    main_dir = plan.main[1] if plan.main else 180
    # Where the main door's axis meets the ring
    if plan.main:
        door, d, k = plan.main
        if d == 0:
            gate_at, gate_side = door[0], 0
        elif d == 180:
            gate_at, gate_side = door[0], 180
        elif d == 90:
            gate_at, gate_side = door[1], 90
        else:
            gate_at, gate_side = door[1], 270
    else:
        gate_at, gate_side = (x0 + x1) / 2, 180
    depth = 1.2  # an H-barrier's depth: the east/west sides stop short of the corners
    sides = [
        (180, x0, x1, y0, "y"),
        (0, x0, x1, y1, "y"),
        (90, y0 + depth, y1 - depth, x1, "x"),
        (270, y0 + depth, y1 - depth, x0, "x"),
    ]
    gate = None
    for d, a0, a1, c, axis in sides:
        runs = [(a0, a1)]
        if d == gate_side:
            g = min(max(gate_at, a0 + 4), a1 - 4)
            runs = [(a0, g - gap / 2), (g + gap / 2, a1)]
            gate = ((g, c) if axis == "y" else (c, g), d)
        for (r0, r1) in runs:
            _fill_run(plan, tier, d, r0, r1, c, axis, z, long_cls, short_cls, fill_cls)
    if gate:
        p, d = gate
        # A barrier just inside the gap, off to one side, the guard beside it
        q = offset(p, d, -1.8, 2.6)
        plan.add_object(tier, gate_cls, q, d, z, ["outside"])
    return gate


def _fill_run(plan, tier, d, r0, r1, c, axis, z, long_cls, short_cls, fill_cls):
    """Fills a straight run with fence pieces (long first), centred so the ends meet the corners."""
    span = r1 - r0
    if span < 1.0:
        return
    pieces = []
    rest = span
    for cls in (long_cls, short_cls, fill_cls):
        L = SIZES[cls]
        while rest >= L - 0.2:
            pieces.append(cls)
            rest -= L
    if not pieces:
        return
    total = sum(SIZES[p] for p in pieces)
    # Spread the slack evenly between the pieces
    slack = (span - total) / max(1, len(pieces))
    a = r0
    for cls in pieces:
        L = SIZES[cls]
        centre = a + L / 2 + slack / 2
        p = (centre, c) if axis == "y" else (c, centre)
        plan.add(tier, obj(cls, (p[0], p[1], z), d, ["outside"]), radius=0.3, check_ring=False)
        a += L + slack


def desk_spot(plan):
    """A quiet corner for the mayor's desk: a ground-floor floor cell well away from the doors and the
    guard positions, with walls on two sides if possible. Returns ((x, y), facing) or None."""
    b = plan.b
    level = b.ground_z
    best, best_score = None, -99
    for (x, y) in b.floor_cells(level):
        p = (x, y, level)
        if not plan.clear_of_doors(p, 2.2):
            continue
        if any(dist2(p, q) < 1.6 and abs(q[2] - level) < 1 for q in b.positions):
            continue
        walls = []
        for d in (0, 90, 180, 270):
            fx, fy = dir_vec(d)
            if b.cell(level, x + fx, y + fy) in ("#", " "):
                walls.append(d)
        if not walls or len(walls) > 2:
            continue
        for back in walls:
            # A proper room: two floor cells in front of the desk and floor either side of it
            front = [offset((x, y), back, -1), offset((x, y), back, -2)]
            sides = [offset((x, y), back, 0, 1), offset((x, y), back, 0, -1)]
            if any(b.cell(level, q[0], q[1]) != "." for q in front):
                continue
            if sum(1 for q in sides if b.cell(level, q[0], q[1]) == ".") < 1:
                continue
            score = len(walls) * 2 - (dist2(p, plan.main[0]) * 0.05 if plan.main else 0)
            if score > best_score:
                best, best_score = ((x, y), back), score
    return best


def flavour(plan, tier=1):
    """The mayor's office props: a flag at the main door, a desk with its chair and a map inside."""
    b = plan.b
    z = b.ground_z
    n = 0
    if plan.main:
        door, d, k = plan.main
        level = b.door_level(door)
        for lat in (-3.3, 3.3):
            p = offset(door, d, k + 1.0, lat)
            if plan.outside_ok(level, p) and plan.add_object(tier, "Flag_NATO_F", p, d, level, ["outside", "flag"], 0.3):
                n += 1
                break
    spot = desk_spot(plan)
    if spot:
        (x, y), back = spot
        desk = offset((x, y), back, 0.1)
        if plan.add_object(tier, "Land_TableDesk_F", desk, back + 180, z, [], 0.8):
            n += 1
            chair = offset((x, y), back, 0.75)
            if plan.add_object(tier, "Land_OfficeChair_01_F", chair, back + 180, z, [], 0.3):
                n += 1
            plan.desk = (desk[0], desk[1], z, back)
            # A map board along the same wall if there is room beside the desk
            for lat in (1.8, -1.8):
                m = offset((x, y), back, 0.55, lat)
                if plan.floor_ok(b.ground_z, m) and plan.add_object(tier, "Land_MapBoard_F", m, back + 180, z, [], 0.8):
                    n += 1
                    break
    return n


def build_tiers(b, spec=None):
    """The five tiers for a building. spec keys (all optional):
        size: "small" | "medium" | "large" (default from the number of building positions)
        guards: [n1..n5] what each tier adds (default by size)
        main_door: index into the exterior doors, extra_doors: [([x, y, z], outside dir), ...],
        interior_doors: [door indices to ignore], door_dirs: {door index: outside dir},
        perimeter_margin: metres outside the bounding box (default 5),
        flavour: False to leave the office props out,
        extra: {tier: [items]} hand-placed items added after the generated ones
    Returns (tiers, plan)."""
    spec = spec or {}
    plan = Plan(b, spec)
    plan.desk = None
    n = len(b.positions)
    size = spec.get("size") or ("small" if n <= 9 else "medium" if n <= 30 else "large")
    counts = spec.get("guards") or GUARDS_BY_SIZE[size]
    ground = b.ground_z
    top = b.top_z
    main = plan.main

    # Tier 1: the gendarmes on the ground floor by the doors (the main door first), the office props
    if spec.get("flavour", True):
        flavour(plan, 1)
    near = main[0] if main else None
    for i in range(counts[0]):
        if not plan.guard_in_building(1, "gendarme", ground, near=near):
            plan.guard_outside(1, "gendarme")

    # Tier 2: sandbags at every outside door, a military pair at the main door
    for door, d, k in plan.doors:
        door_sandbags(plan, 2, door, d, k)
    roles = ["rifleman", "autorifleman"]
    for i in range(counts[1]):
        role = roles[i % 2]
        placed = False
        if main:
            door, d, k = main
            lat = 1.0 if i % 2 == 0 else -1.0
            p = offset(door, d, k + 0.3, lat)
            if plan.outside_ok(b.door_level(door), p):
                placed = plan.add_guard(2, role, p, d, b.door_level(door), ["outside"])
        if not placed and not plan.guard_in_building(2, role, ground, near=near):
            plan.guard_outside(2, role)

    # Tier 3: barriers at the doors, sandbagged firing positions inside, the fireteam behind them
    for door, d, k in plan.doors:
        door_barrier(plan, 3, door, d, k)
    roles = ["rifleman", "autorifleman", "rifleman"]
    for i in range(counts[2]):
        role = roles[i % 3]
        if not window_post(plan, 3, role, ground) and not plan.guard_in_building(3, role, ground, window=True):
            plan.guard_outside(3, role)
    # Sandbags at a couple more ground-floor window positions, for the men to come
    extra_windows = 0
    for p in plan.free_positions(ground, window=True):
        if extra_windows >= 2:
            break
        if b.exterior_dirs(ground, p[0], p[1], reach=2) and window_sandbag(plan, 3, p) is not None:
            extra_windows += 1

    # Tier 4: wire, sandbags on the top floor/roof, barricades on the approaches, the squad up top
    wire_sides(plan, 4)
    for door, d, k in plan.doors:
        if abs(b.door_level(door) - ground) < 0.5:
            door_approach(plan, 4, door, d, k)
    roles = ["mg_gunner", "rifleman"]
    for i in range(counts[3]):
        role = roles[i % 2]
        if not window_post(plan, 4, role, top) and not plan.guard_in_building(4, role, top, window=True):
            plan.guard_outside(4, role)

    # Tier 5: the perimeter with its gate, reinforced rooms, the marksman up top and the AT man on the gate
    gate = perimeter(plan, 5)
    if main:
        door, d, k = main
        door_airlock(plan, 5, door, d, k)
    if plan.desk:
        x, y, z, back = plan.desk
        wall = offset((x, y), back, -2.6)
        if plan.floor_ok(ground, wall, back, 1.45) and plan.clear_of_doors((wall[0], wall[1], ground), 1.6):
            plan.add_object(5, "Land_BagFence_Long_F", wall, back + 180, ground)
    roles = ["marksman", "at"]
    for i in range(counts[4]):
        role = roles[i % 2]
        placed = False
        if role == "at" and gate:
            p, d = gate
            q = offset(p, d, -1.6, -1.6)
            placed = plan.add_guard(5, role, q, d, ground, ["outside"])
        if not placed and not window_post(plan, 5, role, top) and not plan.guard_in_building(5, role, top, window=True):
            plan.guard_outside(5, role)

    for tier, items in (spec.get("extra") or {}).items():
        for item in items:
            plan.add(int(tier), item, 0.3, check_ring=False)

    return plan.tiers, plan


# ---------------------------------------------------------------- checks and output


def guard_counts(tiers):
    """Cumulative guard count at each tier."""
    out, n = [], 0
    for t in tiers:
        n += sum(1 for it in t if it[0] == "guard")
        out.append(n)
    return out


def check_tiers(b, tiers, plan=None):
    """Problems with a template, as strings (empty when it is fine)."""
    problems = []
    counts = guard_counts(tiers)
    ranges = [(2, 4), (4, 6), (6, 8), (8, 10), (10, 12)]
    for i, (lo, hi) in enumerate(ranges):
        if not lo <= counts[i] <= hi:
            problems.append("tier %d has %d guards, wanted %d-%d" % (i + 1, counts[i], lo, hi))
    for it in tiers[0]:
        if it[0] == "object" and is_fortification(it[1]):
            problems.append("tier 1 has a fortification: %s" % it[1])
    ring = plan.ring if plan else (b.bmin[0] - 8, b.bmin[1] - 8, b.bmax[0] + 8, b.bmax[1] + 8)
    for ti, t in enumerate(tiers):
        for it in t:
            kind, what, pos, d, extra = it
            if kind == "guard" and what not in GUARD_ROLES:
                problems.append("tier %d: unknown guard role %s" % (ti + 1, what))
            if kind == "object":
                for door in b.doors:
                    if abs(door[2] - 1.0 - pos[2]) < 2.5 and dist2(door, pos) < 1.2:
                        problems.append("tier %d: %s at %s within 1.2 m of door %s" % (ti + 1, what, pos, door))
            if not (ring[0] - 1 <= pos[0] <= ring[2] + 1 and ring[1] - 1 <= pos[1] <= ring[3] + 1):
                problems.append("tier %d: %s at %s outside the perimeter" % (ti + 1, what, pos))
            if min(abs(pos[2] - l) for l in b.levels) > 0.5:
                problems.append("tier %d: %s at %s not at a floor height %s" % (ti + 1, what, pos, b.levels))
            if kind == "guard" and "outside" not in extra:
                if min((dist2(pos, p) for p in b.positions if abs(p[2] - pos[2]) < 1.0), default=9) > 0.8:
                    problems.append("tier %d: guard %s at %s not at a building position" % (ti + 1, what, pos))
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
    "Tier 1: guard posts",
    "Tier 2: sandbags at the doors, a military pair",
    "Tier 3: barriers at the doors, firing positions inside, the fireteam",
    "Tier 4: wire, top floor positions, barricades on the approaches, the squad",
    "Tier 5: the perimeter and its gate, reinforced rooms, the marksman and AT man",
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
    f flag, d desk, o chair, m map; lower case for objects, upper case G for guards)."""
    marks = {"Land_BagFence": "s", "Land_HBarrier": "h", "Land_Razorwire": "w", "Land_CncBarrier": "c",
             "Land_CzechHedgehog": "x", "Flag": "f", "Land_TableDesk": "d", "Land_OfficeChair": "o",
             "Land_MapBoard": "m"}
    if ring is None:
        ring = (b.bmin[0] - 5, b.bmin[1] - 5, b.bmax[0] + 5, b.bmax[1] + 5)
    x0, y0 = int(math.floor(ring[0])) - 1, int(math.floor(ring[1])) - 1
    x1, y1 = int(math.ceil(ring[2])) + 1, int(math.ceil(ring[3])) + 1
    out = []
    for level in b.levels:
        grid = {}
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                grid[(x, y)] = b.cell(level, x, y)
        for p in b.positions_on(level):
            grid[(int(round(p[0])), int(round(p[1])))] = "P"
        for door in b.doors:
            if abs(door[2] - 1.0 - level) < 1.5:
                grid[(int(round(door[0])), int(round(door[1])))] = "D"
        for t in tiers[:upto]:
            for kind, what, pos, d, extra in t:
                if abs(pos[2] - level) > 1.0:
                    continue
                if kind == "guard":
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
