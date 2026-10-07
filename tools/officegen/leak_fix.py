"""
Closes the leaks a layout check found in a town's occupier compound (tools/officegen/COMPOUND_PLAN.md: leaks are closed
by adding pieces, never by moving the ones there): each way out or in (OTPATH / OTPATHIN in the RPT) that doesn't go
through a gate crosses the tier's line somewhere; where that's through a building it's a door (locked for players,
OT_fnc_officeDoors) and left, elsewhere a filler goes on the line there, along it: T3 a 2-high H-barrier 1
(Land_HBarrier_1_F, the upper layer 1.4 m up), T4+ a small concrete wall (Land_CncWall1_F), unless it would stand in
a gate's opening, a building or on a road. The fillers carry the "leakfix" flag. Run the layout check again after.

    python tools/officegen/leak_fix.py "Town" [rpt] [--world Altis] [--dry]
"""
import glob
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import compound_gen as cg  # noqa: E402
import gate_gen as gg  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402
import tower_gen as tg  # noqa: E402


def crossings(rpt, town, tier, block, poly):
    """[(edge index, point)] where the gateless ways cross the area's line."""
    o, d = block.pos, block.dir
    world = lambda x, y: (o[0] + blocklib.rot(x, y, d)[0], o[1] + blocklib.rot(x, y, d)[1])
    out = []
    for line in open(rpt, encoding="utf-8", errors="replace"):
        m = re.search(r'"OTPATH(?:IN)?\|' + re.escape(town) + r'\|' + str(tier) + r'\|\d+\|[^|]*\|(\[\[.*\]\])\|none"', line)
        if not m:
            continue
        pts = [world(*p) for p in eval(m.group(1))]
        n = len(poly)
        for a, c in zip(pts, pts[1:]):
            if cg.inside(a, poly) == cg.inside(c, poly):
                continue
            for i in range(n):
                x = cg.seg_cross(a, c, poly[i], poly[(i + 1) % n])
                if x:
                    out.append((i, x[1]))
    return out


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    args = [a for a in argv if not a.startswith("--") and a != world]
    town = args[0]
    rpt = args[1] if len(args) > 1 else max(glob.glob(os.path.join(os.environ["LOCALAPPDATA"], "Arma 3", "*.rpt")), key=os.path.getmtime)
    block = blocklib.load(world)[town]
    areas = merge_compounds.load_saved(world)[town]["tiers"]
    towns = merge_layouts.load_saved(world)
    t = towns[town]
    for tier in sorted(areas):
        if tier not in t["tiers"]:
            continue
        poly = [tuple(p[:2]) for p in areas[tier]]
        items = t["tiers"][tier]
        gates = [gg.vec(it[2])[:2] for it in items if it[0] == "gate"]
        added, doors, skipped = 0, 0, 0
        done = []
        for i, p in crossings(rpt, town, tier, block, poly):
            if any(math.dist(p, q) < 1.0 for q in done):
                continue
            done.append(p)
            if any(cg.inside(p, tg.rect(x.pos[:2], (math.sin(math.radians(x.dir)), math.cos(math.radians(x.dir))), (x.box[2] - x.box[0] + 1.0, x.box[3] - x.box[1] + 1.0))) for x in block.buildings):
                doors += 1
                continue
            if any(math.dist(p, g) < 3.5 for g in gates) or any(cg.seg_dist(p, r["beg"][:2], r["end"][:2]) < r["width"] / 2 for r in block.roads):
                skipped += 1
                continue
            a, b = poly[i], poly[(i + 1) % len(poly)]
            u = cg.norm(cg.sub(b, a))
            z = block.ground(*p)
            if tier >= 4:
                items.append(["object", "Land_CncWall1_F", f"[{p[0]:.3f},{p[1]:.3f},{z:.3f}]", cg.orient(u), "ground,leakfix"])
            else:
                for dz in (0.0, cg.UPPER):
                    items.append(["object", "Land_HBarrier_1_F", f"[{p[0]:.3f},{p[1]:.3f},{z + dz:.3f}]", cg.orient(u), "leakfix"])
            added += 1
        print(f"{town} T{tier}: {added} leaks closed, {doors} through buildings (doors) left, {skipped} at a gate or on a road left")
    if "--dry" in argv:
        return
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
