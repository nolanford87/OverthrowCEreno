#!/usr/bin/env python3
"""
gen_shops.py - mayor's office defence templates for the Altis shops and the Research HQ.

Reads tools/officegen/probe_offices.txt (OTPROBE2 lines written by the QA addon's
OTQA_fnc_probeOffices) and writes, with the shared library (officegen_lib.py),
addons/overthrow_main/functions/offices/templates/fn_officeTpl_<Key>.sqf for
Land_i_Shop_01_V1_F, Land_i_Shop_02_V1_F and Land_Research_HQ_F.

    python tools/officegen/gen_shops.py             writes the three templates
    python tools/officegen/gen_shops.py --render    also prints each template on the floor plans
    python tools/officegen/gen_shops.py --check     checks and renders, writes nothing

What comes from the probe: the exterior ground doors and the side they face (walking the floor
grid out from each door cell until it leaves the building; the library's door scoring misreads
these three, see door_facing), the porch or steps outside each door (the sandbag line goes beyond
them), the floor heights (the upper floor's height is the median of its building positions:
LEVELS starts a cluster at its lowest point, the stair landing on the small shop), the bounding
box (the wire and the perimeter ring). The generator places from those the sandbag line across
each doorway (T2), the barriers extending the main one (T3), the wire on the sides without doors
and the staggered barricades on the approach to the main door (T4), the perimeter ring with its
gate on the main-door side (T5, the library's). Guards, window and top-floor posts, reinforced
rooms and the HQ's office props are hand-placed per class in PLANS, guards on building positions
(the posts' sandbags between the position and the wall), everything checked against the grid and
the doors by the library's Plan and check_tiers.
"""
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import officegen_lib as og  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROBE = os.path.join(ROOT, "tools", "officegen", "probe_offices.txt")
OUT = os.path.join(ROOT, "addons", "overthrow_main", "functions", "offices", "templates")

N, E, S, W = 0, 90, 180, 270
LONG, SHORT = "Land_BagFence_Long_F", "Land_BagFence_Short_F"
CNC, HEDGEHOG, WIRE = "Land_CncBarrier_stripes_F", "Land_CzechHedgehog_01_F", "Land_Razorwire_F"
OUTSIDE = ["outside"]

# Doors (0-based) between rooms that the grid cannot tell from balcony doors: the HQ's upstairs
# door sits in an inner wall with a 3 m deep room beyond it, like the small shop's balcony
INTERIOR_DOORS = {"Land_Research_HQ_F": [1]}

DOOR_OUT = 2.6          # the sandbag line's distance from a door, at least
PERIM_MARGIN = 4.0      # the perimeter ring outside the bounding box
WIRE_OUT = 2.0          # razorwire outside the bounding box


# ---------------------------------------------------------------- what the probe says

def floor_z(b, level):
    """The height to put things on at a level: the median of its building positions (the upper
    floor of the small shop is 1 m above its LEVELS value, which is the stair landing)."""
    zs = [p[2] for p in b.positions if level - 0.5 <= p[2] <= level + 1.0]
    return round(statistics.median(zs), 1) if zs and level > b.ground_z else level


def door_facing(b, i):
    """(outside direction, porch depth) of a ground door that opens outside, else None. Walks the
    ground grid out from the door cell in the four directions: the door faces the side where the
    building ends (an empty cell) within 4 m, floor cells on the way being its porch or steps."""
    dx, dy, dz = b.doors[i]
    g = b.ground_z
    if not (g - 0.5 <= dz <= g + 2.0):
        return None
    cx, cy = int(round(dx)), int(round(dy))
    best = None
    for d in (N, E, S, W):
        fx, fy = og.dir_vec(d)
        porch = 0
        for k in range(1, 6):
            c = b.cell(g, cx + fx * k, cy + fy * k)
            if c == ".":
                porch = k
                continue
            if c == " " and k <= 4 and (best is None or k < best[1]):
                if porch:
                    edge = (cx + fx * (porch + 0.5)) - dx if abs(fx) > 0.5 else (cy + fy * (porch + 0.5)) - dy
                    depth = abs(edge)
                else:
                    depth = 0.0
                best = (d, k, depth)
            break
    return (best[0], best[2]) if best else None


def grid_usable(b, level):
    """Whether a level's grid shows its floor plan (the small shop's upper grid is all wall: its
    LEVELS value is the stair landing, a metre below the floor, so the floor slab fills the wall band)."""
    cells = [c for row in b.rows.get(level, {}).values() for c in row if c != " "]
    return bool(cells) and sum(c == "#" for c in cells) / len(cells) < 0.6


def fix_levels(b):
    """Puts each upper level at its floor's real height (the median of its building positions)."""
    for lv in list(b.levels):
        z = floor_z(b, lv)
        if z != lv:
            b.rows[z] = b.rows.pop(lv)
            b.levels[b.levels.index(lv)] = z


def balcony_door(b, door, d):
    """Whether an upstairs door opening d leads onto a balcony: floor for up to 3 m beyond it and
    then nothing (on the level's grid, or the ground grid under it when the level's is no use)."""
    level = b.door_level(door)
    if not grid_usable(b, level):
        level = b.ground_z
    for k in range(1, 4):
        c = b.cell(level, *og.offset(door, d, k))
        if c == " ":
            return k > 1
        if c != ".":
            return False
    return False


def doorways(b):
    """The exterior ground doors grouped into doorways (a double door is two memory points within
    2.5 m on the same side): [{centre: (x, y, z), d, porch, k, doors: [i]}], door 1's first."""
    ways = []
    for i in range(len(b.doors)):
        f = door_facing(b, i)
        if f is None:
            continue
        d, porch = f
        x, y, z = b.doors[i]
        for w in ways:
            if w["d"] == d and og.dist2(w["centre"], (x, y)) < 2.5:
                n = len(w["doors"])
                w["centre"] = ((w["centre"][0] * n + x) / (n + 1), (w["centre"][1] * n + y) / (n + 1), z)
                w["porch"] = max(w["porch"], porch)
                w["doors"].append(i)
                break
        else:
            ways.append({"centre": (x, y, z), "d": d, "porch": porch, "doors": [i]})
    for w in ways:
        w["k"] = b.outside_k(b.ground_z, w["centre"], w["d"])
    ways.sort(key=lambda w: min(w["doors"]))
    return ways


def make_plan(b, dws):
    """The library's Plan for a building, told which doors open where, with the perimeter ring on
    the bounding box plus the margin and the main doorway's centre as its main door."""
    door_dirs = {}
    for w in dws:
        for i in w["doors"]:
            door_dirs[i] = w["d"]
    for i, door in enumerate(b.doors):
        if i in door_dirs or i in INTERIOR_DOORS.get(b.cls, []):
            continue
        # Upper-floor doors: the ones onto a balcony open outside, the rest are between rooms
        if b.door_level(door) > b.ground_z:
            for d in (N, E, S, W):
                if balcony_door(b, door, d):
                    door_dirs[i] = d
                    break
    interior = [i for i in range(len(b.doors)) if i not in door_dirs]
    spec = {"door_dirs": door_dirs, "interior_doors": interior, "main_door": 0, "perimeter_margin": PERIM_MARGIN}
    plan = og.Plan(b, spec)
    plan.ring = (b.bmin[0] - PERIM_MARGIN, b.bmin[1] - PERIM_MARGIN, b.bmax[0] + PERIM_MARGIN, b.bmax[1] + PERIM_MARGIN)
    main = dws[0]
    plan.main = (list(main["centre"]), main["d"], main["k"])
    plan.desk = None
    return plan


# ---------------------------------------------------------------- generated fortifications

def fence_out(dw):
    """The sandbag line's distance from the door: DOOR_OUT, or 0.7 m beyond the porch or steps."""
    return max(DOOR_OUT, dw["porch"] + 0.7 + 0.25)


def door_line(plan, tier, dw, main):
    """T2: a bag fence across the doorway outside it (long for the main door), the way round its ends."""
    p = og.offset(dw["centre"], dw["d"], fence_out(dw))
    return plan.add_object(tier, LONG if main else SHORT, p, dw["d"], plan.b.ground_z, OUTSIDE)


def behind_line(plan, tier, dw, role, lateral):
    """A guard behind a doorway's sandbag line, on the door side of it."""
    p = og.offset(dw["centre"], dw["d"], fence_out(dw) - 0.9, lateral)
    return plan.add_guard(tier, role, p, dw["d"], plan.b.ground_z, OUTSIDE)


def line_extensions(plan, tier, dw):
    """T3: concrete barriers continuing the main doorway's sandbag line on either side, where the
    line stays within the building's width (the shops stand wall to wall with their neighbours)."""
    b = plan.b
    lat = og.SIZES[LONG] / 2 + og.SIZES[CNC] / 2 + 0.15
    n = 0
    for side in (-1, 1):
        p = og.offset(dw["centre"], dw["d"], fence_out(dw), side * lat)
        end = og.offset(p, dw["d"], 0, side * og.SIZES[CNC] / 2)
        lo, hi = (b.bmin[1], b.bmax[1]) if dw["d"] in (E, W) else (b.bmin[0], b.bmax[0])
        along = end[1] if dw["d"] in (E, W) else end[0]
        if lo - 1.0 <= along <= hi + 1.0 and plan.add_object(tier, CNC, p, dw["d"], b.ground_z, OUTSIDE):
            n += 1
    return n


def approach(plan, tier, dw):
    """T4: a staggered pair of concrete barriers and a hedgehog on the way in to the main door, between
    its sandbag line and the perimeter (what fits; the ring and its gate barrier go in first)."""
    b = plan.b
    out = fence_out(dw)
    n = 0
    for f, lat in ((out + 1.4, -2.0), (out + 2.8, 1.6)):
        p = og.offset(dw["centre"], dw["d"], f, lat)
        if plan.in_ring(p, 0.9) and plan.add_object(tier, CNC, p, dw["d"], b.ground_z, OUTSIDE):
            n += 1
    p = og.offset(dw["centre"], dw["d"], out + 4.4, -0.5)
    if plan.in_ring(p, 1.2) and plan.add_object(tier, HEDGEHOG, p, dw["d"] + 45, b.ground_z, OUTSIDE):
        n += 1
    return n


def back_hedgehogs(plan, tier, dw):
    """T4: a pair of hedgehogs flanking the way in to a secondary door."""
    n = 0
    for side in (-1, 1):
        p = og.offset(dw["centre"], dw["d"], fence_out(dw) + 2.0, side * 2.2)
        if plan.in_ring(p, 1.2) and plan.add_object(tier, HEDGEHOG, p, dw["d"] + 45, plan.b.ground_z, OUTSIDE):
            n += 1
    return n


def wire(plan, tier, limit=3):
    """T4: razorwire WIRE_OUT outside the bounding box along the sides no exterior door opens to,
    centred on each side, the longest sides first."""
    b = plan.b
    door_sides = {d for _, d, _ in plan.doors}
    cx, cy = (b.bmin[0] + b.bmax[0]) / 2, (b.bmin[1] + b.bmax[1]) / 2
    sides = {
        N: ((cx, b.bmax[1] + WIRE_OUT), b.bmax[0] - b.bmin[0]), S: ((cx, b.bmin[1] - WIRE_OUT), b.bmax[0] - b.bmin[0]),
        E: ((b.bmax[0] + WIRE_OUT, cy), b.bmax[1] - b.bmin[1]), W: ((b.bmin[0] - WIRE_OUT, cy), b.bmax[1] - b.bmin[1]),
    }
    n = 0
    for d in sorted((d for d in sides if d not in door_sides), key=lambda d: -sides[d][1])[:limit]:
        p, length = sides[d]
        if length >= og.SIZES[WIRE] and plan.add_object(tier, WIRE, p, d, b.ground_z, OUTSIDE, radius=0.5):
            n += 1
    return n


def post(plan, tier, role, p, d, gap=0.6, lateral=0.0, cls=SHORT):
    """A sandbagged post: a guard at a building position looking d, a bag fence `gap` in front of it
    (`lateral` to its right, to keep clear of a wall or the stairs); gap None for a position right at
    the wall or the floor's edge, where the wall itself is the cover."""
    z = p[2]
    ok = False
    if gap is not None:
        q = og.offset(p, d, gap, lateral)
        ok = plan.add_object(tier, cls, q, d, z)
    if not plan.add_guard(tier, role, p, d, z):
        if ok:
            plan.undo(tier)
        return False
    plan.use_position(p)
    return True


def man(plan, tier, role, p, d, extra=None):
    """A guard at a building position (or, flagged "outside", on the ground outside)."""
    ok = plan.add_guard(tier, role, p, d, p[2], extra)
    if ok and not extra:
        plan.use_position(p)
    return ok


def perimeter_and_gate(plan, tier):
    """T5: the library's ring with its gate on the main-door side (a barrier just inside the gap),
    the AT man beside the gap."""
    gate = og.perimeter(plan, tier)
    if gate:
        p, d = gate
        plan.add_guard(tier, "at", og.offset(p, d, -1.6, -1.6), d, plan.b.ground_z, OUTSIDE)
    return gate


# ---------------------------------------------------------------- the buildings

def plan_i_shop_01(b, plan, dws):
    """Small shop, 9 x 10 m: shop floor (z -2.7), the flat above (z 1.2) with a balcony over the
    front porch (south). Front double door (1, 2) and a back door (3) up two steps; the stairs run
    along the east wall (x 3, y -2..3, landing at z 0.2); doors 4 and 5 are upstairs (5 to the balcony)."""
    g, u = b.ground_z, floor_z(b, 0.2)
    front, back = dws[0], dws[1]
    # T1
    man(plan, 1, "gendarme", (0.0, -3.6, g), S, OUTSIDE)         # on the porch beside the shop door
    man(plan, 1, "gendarme", (0.9, 4.2, g), S)                   # shop floor, facing the door
    # T2
    door_line(plan, 2, front, True)
    door_line(plan, 2, back, False)
    behind_line(plan, 2, front, "rifleman", -1.0)
    behind_line(plan, 2, back, "autorifleman", 0.0)
    # T5 ring first: the gate barrier has priority over the approach barricades
    perimeter_and_gate(plan, 5)
    # T3
    line_extensions(plan, 3, front)
    post(plan, 3, "rifleman", (-1.1, -0.5, g), S, gap=1.4)       # shop window left of the door
    post(plan, 3, "mg_gunner", (-1.3, 6.0, g), N)                # back room window
    # T4
    wire(plan, 4)
    approach(plan, 4, front)
    back_hedgehogs(plan, 4, back)
    post(plan, 4, "rifleman", (-1.2, -3.5, u), S, gap=0.0, lateral=-1.0)   # balcony, west end: it is too shallow for a bag in front, so one beside him
    man(plan, 4, "officer", (1.6, 2.1, u), S)                    # the flat's living room
    # T5
    plan.add_object(5, LONG, (0.0, 1.5), S, g)                   # shop floor: a cover wall facing the door
    plan.add_object(5, LONG, (0.0, 0.5), S, u)                   # the flat: cover across the front room
    man(plan, 5, "marksman", (2.6, -3.4, u), S)                  # balcony, east end


def plan_i_shop_02(b, plan, dws):
    """Large shop, 13 x 11 m: shop floor (z -2.6), the flat above (z 1.3) with a terrace along the
    south edge and a small balcony over the west door. The west door (1) is the only exterior
    ground door; door 2 is inside the shop, 3 upstairs between rooms, 4 the balcony door. The
    shopfront bay is on the east, the stair opening upstairs at x -2..1, y 3..4."""
    g, u = b.ground_z, floor_z(b, 1.3)
    west = dws[0]
    # T1
    man(plan, 1, "gendarme", (-7.0, -1.6, g), W, OUTSIDE)        # on the step north of the door
    man(plan, 1, "gendarme", (-1.4, -0.7, g), W)                 # shop floor, facing the door
    man(plan, 1, "gendarme", (-6.7, 1.2, 1.4), W)                # the balcony over the door
    # T2
    door_line(plan, 2, west, True)
    behind_line(plan, 2, west, "rifleman", -0.8)
    behind_line(plan, 2, west, "autorifleman", 0.8)
    # T5 ring first
    perimeter_and_gate(plan, 5)
    # T3
    line_extensions(plan, 3, west)
    post(plan, 3, "rifleman", (-2.2, 3.9, g), N, gap=None)       # back wall window (right at the wall)
    post(plan, 3, "mg_gunner", (-4.8, -2.9, u), W)               # upstairs window over the entrance
    # T4
    wire(plan, 4)
    approach(plan, 4, west)
    post(plan, 4, "rifleman", (4.6, -3.7, u), E, gap=None)       # upstairs over the shopfront bay (at the floor's east edge)
    man(plan, 4, "officer", (-1.2, 2.0, u), W)                   # the flat's north room
    # T5
    plan.add_object(5, LONG, (-3.2, -1.6), W, g)                 # shop floor: a cover wall facing the door
    plan.add_object(5, SHORT, (0.5, 2.0), W, u)                  # the flat: cover by the stair opening
    post(plan, 5, "marksman", (-0.8, -3.8, u), S, gap=0.6)       # the terrace, over the south windows (its edge is 1.7 m off)


def plan_research_hq(b, plan, dws):
    """Research HQ, 13 x 13 m: glass-walled two-level building (z -2.7 and -0.5), the entrance (door 1)
    on the west under a canopy that reaches the bbox edge; door 2 is upstairs between rooms, the
    stairs by x 0..2, y 5..6. The mayor's office is upstairs in the north-east corner."""
    g, u = b.ground_z, floor_z(b, -0.5)
    west = dws[0]
    # T1: the office props, then the gendarmes
    plan.add_object(1, "Land_TableDesk_F", (5.6, 3.0), W, u)
    plan.add_object(1, "Land_OfficeChair_01_F", (6.5, 3.0), W, u)
    plan.add_object(1, "Land_MapBoard_F", (5.4, 5.7), S, u)
    plan.add_object(1, "Land_PortableLongRangeRadio_F", (6.8, 4.6), W, u)
    plan.add_object(1, "Land_OfficeCabinet_01_F", (7.0, 5.4), S, u)
    plan.add_object(1, "Flag_NATO_F", (-10.2, 5.5), W, g, ["outside", "flag"], 0.3)  # north of the entrance, off the lane
    man(plan, 1, "gendarme", (-6.0, -4.6, g), W, OUTSIDE)        # under the canopy, south of the door
    man(plan, 1, "gendarme", (-5.0, 0.9, -2.4), W)               # the lobby
    man(plan, 1, "gendarme", (-1.4, -5.4, u), S)                 # upstairs, south side
    # T2
    door_line(plan, 2, west, True)
    behind_line(plan, 2, west, "rifleman", -0.8)
    behind_line(plan, 2, west, "autorifleman", 0.8)
    # T5 ring first
    perimeter_and_gate(plan, 5)
    # T3
    line_extensions(plan, 3, west)
    post(plan, 3, "rifleman", (-1.3, -5.8, g), S)                # south glass wall
    post(plan, 3, "mg_gunner", (4.8, 5.2, -2.6), N, gap=0.8)     # north bay
    # T4
    wire(plan, 4)
    approach(plan, 4, west)
    post(plan, 4, "officer", (-3.5, 2.0, u), W)                  # upstairs over the entrance
    post(plan, 4, "rifleman", (-3.4, -3.4, u), W)                # upstairs over the entrance
    # T5
    plan.add_object(5, LONG, (-2.0, -0.5), W, g)                 # the lobby: a cover wall facing the entrance
    plan.add_object(5, SHORT, (3.6, 1.0), W, u)                  # the office: cover facing the stairs
    post(plan, 5, "marksman", (2.7, 5.3, u), N, lateral=0.7)     # upstairs, north edge, the sandbag clear of the stairs


PLANS = {
    "Land_i_Shop_01_V1_F": plan_i_shop_01,
    "Land_i_Shop_02_V1_F": plan_i_shop_02,
    "Land_Research_HQ_F": plan_research_hq,
}

NOTES = {
    "Land_i_Shop_01_V1_F": "Altis small shop: the shop floor with a flat above and a balcony over the front porch;\n"
                           "front double door and a back door. The flat is at z 1.2 (the probe's level 0.2 is the stair landing).",
    "Land_i_Shop_02_V1_F": "Altis large shop: the shop floor with a flat above, a terrace along the south edge and a\n"
                           "balcony over the west door, the only outside door.",
    "Land_Research_HQ_F": "Altis research HQ: glass-walled, two levels, the entrance on the west under a canopy. The\n"
                          "mayor's office (desk, map, radio) is upstairs in the north-east corner, the occupier's flag outside.",
}


# ---------------------------------------------------------------- main

def main(argv):
    render = "--render" in argv or "--check" in argv
    write = "--check" not in argv
    data = og.parse_probe(PROBE)
    bad = 0
    for cls, build in PLANS.items():
        b = data[cls]
        fix_levels(b)
        dws = doorways(b)
        plan = make_plan(b, dws)
        build(b, plan, dws)
        tiers = plan.tiers
        problems = og.check_tiers(b, tiers, plan)
        key = og.template_key(cls)
        print("%s -> %s: guards %s, items per tier %s" % (cls, key, og.guard_counts(tiers), [len(t) for t in tiers]))
        for w in dws:
            print("    doorway %s at (%.1f, %.1f) opens %s, porch %.1f m, sandbags %.2f m out%s" % (
                [i + 1 for i in w["doors"]], w["centre"][0], w["centre"][1], w["d"], w["porch"], fence_out(w),
                " (main)" if w is dws[0] else ""))
        print("    levels %s, interior doors %s, ring %s" % (
            [(lv, floor_z(b, lv)) for lv in b.levels], [i + 1 for i in plan.spec["interior_doors"]], plan.ring))
        for line in plan.log:
            print("    note: " + line)
        for p in problems:
            print("    PROBLEM: " + p)
            bad += 1
        if render:
            print(og.render(b, tiers, ring=plan.ring))
        if write:
            path = og.write_template(os.path.join(OUT, "fn_officeTpl_%s.sqf" % key), key, cls, tiers,
                                     generator="tools/officegen/gen_shops.py", note=NOTES[cls])
            print("    wrote " + os.path.relpath(path, ROOT))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
