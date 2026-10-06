"""
Puts lookout towers into a town's occupier compound tiers (tools/officegen/COMPOUND_PLAN.md, step 3 of the Rodopoli
pilot), adding to the reviewed layouts and changing nothing else. Each tier gets its own (the tier below's come down
with its wall):
    - T3: one sandbag tower (Land_BagBunker_Tower_F);
    - T4: two cargo patrol towers (Land_Cargo_Patrol_V1_F);
    - T5: those two and a cargo tower (Land_Cargo_Tower_V1_F) where one fits.
A tower stands inside the area against its wall line, clear of buildings (and 3 m of their doors), the layout's
pieces, roads, gates (7 m) and ground sloping more than 1 m under it, with its stairs (model +y) facing in. Of the
spots that fit, the ones that see most of the approach (roads outside the area within 120 m, every 4 m, not behind a
building) win, at least 20 m apart. The pieces carry the "lookout" flag; running it again replaces only those.

    python tools/officegen/tower_gen.py "Town" [--world Altis] [--dry]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import compound_gen as cg  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402
import townlib  # noqa: E402

# Measured in the game (the class probe's OTMEASURE, boundingBoxReal: [x, y] with the stairs)
TOWERS = {"Land_BagBunker_Tower_F": (6.4, 9.83), "Land_Cargo_Patrol_V1_F": (6.67, 6.8), "Land_Cargo_Tower_V1_F": (14.83, 13.48)}
PLAN = {3: ["Land_BagBunker_Tower_F"], 4: ["Land_Cargo_Patrol_V1_F"] * 2, 5: ["Land_Cargo_Patrol_V1_F"] * 2 + ["Land_Cargo_Tower_V1_F"]}
WALL_CLEAR = {3: 1.2, 4: 0.9, 5: 0.9}  # Off the edge line: half the wall's depth and some
SPREAD = 20.0
SIGHT = 120.0


def rect(c, u, size, pad=0.0):
    """A rectangle's corners: centre c, model +y along u, size (x, y)."""
    v = (u[1], -u[0])  # model +x
    hx, hy = size[0] / 2 + pad, size[1] / 2 + pad
    return [cg.add(cg.add(c, cg.mul(v, sx * hx)), cg.mul(u, sy * hy)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(p, q):
    """Do two convex polygons overlap (separating axes)?"""
    for poly in (p, q):
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            n = (b[1] - a[1], a[0] - b[0])
            pa = [cg.dot(n, x) for x in p]
            qa = [cg.dot(n, x) for x in q]
            if max(pa) < min(qa) or max(qa) < min(pa):
                return False
    return True


def piece_rect(it):
    pos = [float(v) for v in it[2].strip("[]").split(",")]
    vd = [float(v) for v in it[3].split("],[")[0].strip("[]").split(",")]
    size = townlib.MEASURED.get(it[1]) or townlib.CLASSES.get(it[1]) or (1.0, 1.0)
    return rect(pos[:2], cg.norm(vd[:2]), size[:2])


class Towers:
    def __init__(self, block, poly, tier, items):
        self.b, self.poly, self.tier = block, [tuple(p[:2]) for p in poly], tier
        self.items = items
        self.pieces = [piece_rect(it) for it in items if it[0] == "object" and "lookout" not in it[4]]
        self.gates = [[float(v) for v in it[2].strip("[]").split(",")][:2] for it in items if it[0] == "gate"]
        self.hidden = {(it[1], round(float(it[2].strip("[]").split(",")[0]), 1)) for it in items if it[0] == "hide"}
        self.blds = [t for t in block.buildings]
        self.sights = self.approach()

    def approach(self):
        pts = []
        for r in self.b.roads:
            a, z = r["beg"][:2], r["end"][:2]
            n = max(1, int(math.dist(a, z) // 4))
            for k in range(n + 1):
                p = cg.add(a, cg.mul(cg.sub(z, a), k / n))
                if not cg.inside(p, self.poly) and min(math.dist(p, v) for v in self.poly) < SIGHT:
                    pts.append(tuple(p))
        return pts

    def edge_dist(self, p):
        n = len(self.poly)
        return min(cg.seg_dist(p, self.poly[i], self.poly[(i + 1) % n]) for i in range(n))

    def fits(self, c, u, size):
        box = rect(c, u, size)
        if not all(cg.inside(p, self.poly) for p in box):
            return False
        if min(self.edge_dist(p) for p in box) < WALL_CLEAR[self.tier]:
            return False
        pad = rect(c, u, size, 0.5)
        for t in self.blds:
            if overlap(pad, t.corners()):
                return False
            if any(math.dist(c, d) < max(size) / 2 + 3.0 for d in t.door_points()):
                return False
        if any(overlap(pad, q) for q in self.pieces):
            return False
        for r in self.b.roads:
            if any(cg.seg_dist(p, r["beg"][:2], r["end"][:2]) < r["width"] / 2 + 0.5 for p in box + [c]):
                return False
        if any(math.dist(c, g) < max(size) / 2 + 7.0 for g in self.gates):
            return False
        zs = [self.b.ground(*p) for p in box]
        return max(zs) - min(zs) <= 1.0

    def seen(self, c):
        """The approach points a lookout at c sees: no building box across the line to it."""
        out = set()
        for i, p in enumerate(self.sights):
            if math.dist(c, p) > SIGHT:
                continue
            blocked = False
            for t in self.blds:
                cs = t.corners()
                if cg.inside(c, cs):
                    continue
                if any(cg.seg_cross(c, p, cs[k], cs[(k + 1) % 4]) for k in range(4)):
                    blocked = True
                    break
            if not blocked:
                out.add(i)
        return out

    def candidates(self, cls):
        size = TOWERS[cls]
        n = len(self.poly)
        out = []
        for i in range(n):
            a, b = self.poly[i], self.poly[(i + 1) % n]
            L = math.dist(a, b)
            if L < 1:
                continue
            u = cg.norm(cg.sub(b, a))
            inward = (-u[1], u[0]) if cg.inside(cg.add(cg.add(a, cg.mul(u, L / 2)), cg.mul((-u[1], u[0]), 0.5)), self.poly) else (u[1], -u[0])
            for off in (0.0, 1.0, 2.0):
                depth = WALL_CLEAR[self.tier] + size[1] / 2 + off  # The tower's back to the wall, stairs in
                t = 0.0
                while t <= L:
                    c = cg.add(cg.add(a, cg.mul(u, t)), cg.mul(inward, depth))
                    if self.fits(c, inward, size):
                        out.append((c, inward))
                    t += 1.0
        return out

    def place(self):
        chosen, covered = [], set()
        for cls in PLAN[self.tier]:
            best = None
            for c, u in self.candidates(cls):
                if any(math.dist(c, q[1]) < SPREAD for q in chosen):
                    continue
                if any(overlap(rect(c, u, TOWERS[cls], 0.5), rect(q[1], q[2], TOWERS[q[0]], 0.5)) for q in chosen):
                    continue
                s = self.seen(c)
                key = (len(s - covered), len(s))
                if best is None or key > best[0]:
                    best = (key, c, u, s)
            if best is None:
                print(f"  T{self.tier}: no room for {cls}")
                continue
            (_, c, u, s) = best
            chosen.append((cls, c, u))
            covered |= s
            print(f"  T{self.tier}: {cls} at [{c[0]:.1f}, {c[1]:.1f}] sees {len(s)} of {len(self.sights)} approach points ({len(covered)} together)")
        return [["object", cls, f"[{c[0]:.3f},{c[1]:.3f},{self.b.ground(*c):.3f}]", f"[[{u[0]:.4f},{u[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,lookout"] for cls, c, u in chosen], covered


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    town = [a for a in argv if not a.startswith("--") and a != world][0]
    block = blocklib.load(world)[town]
    areas = merge_compounds.load_saved(world)[town]["tiers"]
    towns = merge_layouts.load_saved(world)
    t = towns[town]
    for tier in (3, 4, 5):
        if tier not in areas or tier not in t["tiers"]:
            continue
        kept = [it for it in t["tiers"][tier] if "lookout" not in it[4]]
        g = Towers(block, areas[tier], tier, kept)
        towers, covered = g.place()
        t["tiers"][tier] = kept + towers
        marks = {f"v{i}": p for i, p in enumerate(g.sights) if i in covered}
        out = os.path.join(merge_layouts.ROOT, "tools", "officegen", "compounds", f"{town}_T{tier}_towers.svg")
        blocklib.svg(block, out, polygons={f"T{tier}": areas[tier]}, reach=90, scale=6, pieces=t["tiers"][tier], marks=marks)
    if "--dry" in argv:
        return
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
