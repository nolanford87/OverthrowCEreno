"""
The mayor's offices' tiers 1-2 (never a compound at those tiers), police only, no military: the hamlets' (a town
that can never reach tier 3: the user's, 2026-10-29), and with --bigger the same for every other town's tiers 1-2
(its compound tiers 3-5 untouched):
    T1: 4 gendarmes stationed in the building (its building positions, spread over its floors, each facing out:
        "garrison" turns him to his longest view in play), the office's furniture (its building family's: the
        stone house's from Feres, the big house's from Neri); outside the front door only the flag and an ammo
        box (a prop: OT_fnc_officeSpawnItems empties and locks it), no barriers;
    T2: T1, plus a portable light by the door and two patrols of 3 gendarmes ("patrol", "patrol:1" and
        "patrol:2") on opposite corners of the ring they walk in play (OT_fnc_officeGarrison: 9 m out round the
        building).
A run replaces the towns' tiers 1-2 but the user's things ("user", "hand") and the map objects a tier hides. With --carry it keeps tier 1 as
saved (the user's review) and rebuilds tier 2 from it: the saved tier 1, then tier 2's own (its light, its
patrols and the user's things there), generating the light and the patrols only where tier 2 has none. From the
town probe (townlib.py): writes each hamlet's draft (tools/officegen/layouts/drafts/<town>.txt) and merges them
(merge_layouts.py).

    python tools/officegen/hamlet_gen.py [--world Altis] [--bigger] [--towns "Feres,Abdera"] [--carry] [--dry]
"""
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import merge_layouts  # noqa: E402
import townlib  # noqa: E402

RING = 9.0  # How far out round the building the patrols walk (OT_fnc_officeGarrison)
FURNITURE = {"Stone_HouseBig": "Feres", "House_Big_02": "Neri", "House_Big_01": "Panochori"}  # Each building family's furniture from that town's T1
FURNITURE_CLASSES = ("Land_TableDesk_F", "Land_OfficeChair_01_F", "Land_MapBoard_F")
KEEP = ("user", "hand")
kept_item = lambda i: i[0] in ("hide", "gate") or any(k in i[4] for k in KEEP)
LIGHT = "Land_PortableLight_single_F"
DROPPED = ("Land_InfoStand_V2_F",)  # Taken out by the user (2026-10-29): gone from saved tiers too


def family(cls):
    return next((f for f in FURNITURE if f in cls), None)


def model_yaw(town, o):
    """A saved object's [vectorDir, vectorUp] as a model direction."""
    return (math.degrees(math.atan2(o[0][0], o[0][1])) - town.dir) % 360


def clear(town, x, y, mdir, cls=None):
    """Nothing probed under a ground thing at model (x, y) (a guard without cls) and it's off the office
    (townlib.check's rule)."""
    w = town.to_world(x, y, 0)
    yaw = (town.dir + mdir) % 360
    guard = cls is None
    length, depth = (0.5, 0.5) if guard else townlib.CLASSES[cls]
    if not guard and townlib.is_barrier(cls):
        length, depth = max(length - 2 * townlib.BARRIER_OVERLAP, 0.2), max(depth * 0.5, 0.2)
    kinds = ("building", "part", "rock", "wall") if guard else ("building", "part", "rock")
    if any(h[0] in kinds for h in town.hits(w[0], w[1], length, depth, yaw)):
        return False
    return not town.on_office(x, y, length, depth, mdir)


def place(town, cls, spots, mdir):
    """The first clear spot of spots (model (x, y)) for a ground piece: an item, None when none is."""
    for x, y in spots:
        if clear(town, x, y, mdir, cls):
            return townlib.obj(town, cls, x, y, None, mdir)
    return None


def furniture(town, towns, saved):
    """The building family's desk, chair and map board (and flag) from its reference town, in this town's model."""
    ref_name = FURNITURE.get(family(town.cls))
    if not ref_name:
        return [], None
    ref = towns[ref_name]
    out, flag = [], None
    for kind, what, p, o, extra in townlib.baseline(ref)[0]:
        if kind != "object" or (what not in FURNITURE_CLASSES and "flag" not in extra):
            continue
        m = ref.to_model(p)
        mdir = model_yaw(ref, o)
        if "flag" in extra:
            flag = (m[0], m[1], mdir)
        else:
            out.append(townlib.obj(town, what, m[0], m[1], m[2], mdir))
    return out, flag


def door_frame(town):
    """The main door: model point, outward unit vector, lateral unit vector, half width, outward model direction."""
    d = town.door("main") or (town.doors and town.door(town.doors[0]["role"]))
    if d:
        mdir = d["mdir"]
        mx, my = d["model"][0], d["model"][1]
        half = d["width"] / 2
    else:  # No doorway probed: the front of the box
        mdir, mx, my, half = 0.0, 0.0, town.box[3], 0.5
    out = (math.sin(math.radians(mdir)), math.cos(math.radians(mdir)))
    lat = (out[1], -out[0])
    return (mx, my), out, lat, half, mdir


def at(p, out, lat, f, s):
    return (p[0] + out[0] * f + lat[0] * s, p[1] + out[1] * f + lat[1] * s)


def gendarmes(town, avoid):
    """4 gendarmes on the building's positions: the ground floor's nearest the door first, then the farthest from
    those taken (floors weigh 3 m), none within 1.2 m of the furniture."""
    spots = [p for p in town.bpos if all(math.dist(p[:2], a[2][:2]) > 1.2 for a in avoid)] or list(town.bpos)
    door = town.to_world(*door_frame(town)[0], 0)
    low = min(p[2] for p in spots)
    first = min(spots, key=lambda p: (p[2] - low > 1.0, math.dist(p[:2], door[:2])))
    taken = [first]
    while len(taken) < 4 and len(taken) < len(spots):
        rest = [p for p in spots if p not in taken]
        taken.append(max(rest, key=lambda p: min(math.hypot(math.dist(p[:2], q[:2]), 3 * (abs(p[2] - q[2]) > 1.0)) for q in taken)))
    while len(taken) < 4:  # A building with fewer positions: doubled up a little apart
        p = taken[len(taken) % len(spots)]
        taken.append([p[0] + 0.8, p[1], p[2]])
    o = town.origin
    return [["guard", "gendarme", [round(v, 3) for v in p], round(math.degrees(math.atan2(p[0] - o[0], p[1] - o[1])) % 360, 1), ["garrison"]] for p in taken]


def ring(town):
    """The patrols' ring in model coordinates, corner first as OT_fnc_officeGarrison walks it: [(x, y, model
    direction of travel)] every 2 m."""
    b = town.box
    c = [(b[0] - RING, b[1] - RING), (b[2] + RING, b[1] - RING), (b[2] + RING, b[3] + RING), (b[0] - RING, b[3] + RING)]
    pts = []
    for i in range(4):
        a, e = c[i], c[(i + 1) % 4]
        n = int(math.dist(a, e) // 2)
        d = math.degrees(math.atan2(e[0] - a[0], e[1] - a[1])) % 360
        pts += [(a[0] + (e[0] - a[0]) * k / n, a[1] + (e[1] - a[1]) * k / n, d) for k in range(n)]
    return pts


def patrols(town):
    """Two patrols of 3, from opposite corners of the ring, 2 m apart on clear ground (each the other way round)."""
    pts = ring(town)
    out = []
    for p, start in ((1, 0), (2, len(pts) // 2)):
        step = 1 if p == 1 else -1
        men, k = [], start
        for _ in range(len(pts)):
            x, y, d = pts[k % len(pts)]
            if clear(town, x, y, 0) and all(math.hypot(x - m[0], y - m[1]) > 1.5 for m in men):
                men.append((x, y, d if step == 1 else (d + 180) % 360))
                if len(men) == 3:
                    break
            k += step
        for x, y, d in men:
            g = townlib.guard(town, "gendarme", x, y, None, d)
            g[4] += ["patrol", f"patrol:{p}"]
            out.append(g)
    return out


def light(town, frame):
    """Tier 2's portable light by the door."""
    p, out, lat, half, mdir = frame
    return place(town, LIGHT, [at(p, out, lat, f, half + 1.2) for f in (2.0, 2.6, 1.4)], mdir)


def tier1(town, towns, saved, frame, kept=()):
    """Tier 1 (the user's things kept: a flag of theirs stands for the generated one)."""
    p, out, lat, half, mdir = frame
    furn, flag = furniture(town, towns, saved)
    t1 = list(furn)
    f = None
    if any("flag" in i[4] for i in kept):
        pass
    elif flag:
        f = place(town, "Flag_NATO_F", [flag[:2], at(p, out, lat, 2.0, half + 3.0), at(p, out, lat, 2.0, -(half + 3.0))], flag[2])
    else:
        f = place(town, "Flag_NATO_F", [at(p, out, lat, 2.0, half + 3.0), at(p, out, lat, 2.0, -(half + 3.0)), at(p, out, lat, 3.0, half + 2.0)], mdir)
    if f:
        f[4].append("flag")
        t1.append(f)
    # By the front door: the ammo box
    box = place(town, "Box_NATO_Ammo_F", [at(p, out, lat, f_, side * (half + s_)) for side in (1, -1) for f_ in (1.0, 1.6, 2.2) for s_ in (0.9, 1.5)], mdir)
    if box:
        t1.append(box)
    return t1 + gendarmes(town, furn)


def same(a, b):
    return a[0] == b[0] and a[1] == b[1] and math.dist(a[2], b[2]) < 0.05


def build(town, towns, saved, carry=False):
    frame = door_frame(town)
    old = [[i for i in items if i[1] not in DROPPED] for items in townlib.baseline(town)]
    if carry and old:
        t1 = [list(i) for i in old[0]]
        own = [i for i in (old[1] if len(old) > 1 else []) if not any(same(i, j) for j in t1)
               and ("patrol" in i[4] or i[1] == LIGHT or kept_item(i))]
    else:
        kept = [i for i in (old[0] if old else []) if kept_item(i)]
        t1 = tier1(town, towns, saved, frame, kept) + kept
        own = [i for i in (old[1] if len(old) > 1 else []) if kept_item(i)]
    if not any(i[1] == LIGHT for i in own):
        own += [i for i in [light(town, frame)] if i]
    if not any("patrol" in i[4] for i in own):
        own += patrols(town)
    t2 = [list(i) for i in t1] + own
    return [t1, t2] + old[2:]  # The compound's tiers as they are


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    only = argv[argv.index("--towns") + 1].split(",") if "--towns" in argv else None
    dry = "--dry" in argv
    carry = "--carry" in argv
    bigger = "--bigger" in argv
    towns = townlib.load(world)
    saved = merge_layouts.load_saved(world)
    brackets = merge_layouts.probe_brackets(world)
    hamlets = sorted(n for n in saved if (brackets.get(n, 0) > 1 if bigger else brackets.get(n, 0) == 1) and n in towns and (only is None or n in only))
    paths = []
    for name in hamlets:
        town = towns[name]
        tiers = build(town, towns, saved, carry)
        guards = [sum(1 for i in t if i[0] == "guard") for t in tiers]
        patrol = [sum(1 for i in tiers[1] if f"patrol:{p}" in i[4]) for p in (1, 2)]
        print(f"{name:20} {town.cls:28} T1 {len(tiers[0]):2} items {guards[0]} men, T2 {len(tiers[1]):2} items {guards[1]} men (patrols {patrol})")
        top = tiers[2:]  # A bigger town's compound tiers: kept as they are, only tiers 1-2 written
        tiers = tiers[:2]
        town.cap = 2  # The draft's tiers (merge_layouts.py keeps the town's other tiers)
        problems = townlib.check(town, tiers)
        if problems:
            print("   " + "\n   ".join(problems))
            continue
        if not dry:
            paths.append(townlib.write(town, tiers))
    if not dry and paths:
        for path in paths:
            subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "merge_layouts.py"), path], check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
