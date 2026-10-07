"""
The occupier compounds' obstacles and props (tools/officegen/COMPOUND_PLAN.md, step 6 of the Rodopoli pilot), adding
to the reviewed tiers 3+ and changing nothing else:
    - outside: two sandbag fighting holes (round sandbags, their curve, model -y, out) just outside the main gate,
      either side of its approach ("hole": garrison_gen.py mans them from the garrison's count);
    - inside, light military clutter clear of the gate lanes, doors and the walls' inside (the patrol's loop): a
      camping table and two chairs by the HQ, a few crates, a generator with fuel cans, a camo net over a corner
      where one fits;
    - from T4 an armed vehicle (the occupier's armed car, a "vehicle" item by role, OT_fnc_officeSpawnItems) parked
      outside the main gate, crewed when the garrison's alarm goes (OT_fnc_officeGarrison).
The pieces carry the "props" flag; running it again replaces only those. Run after gate_gen.py, before
garrison_gen.py.

    python tools/officegen/props_gen.py "Town" [--world Altis] [--tiers 3,4] [--dry]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import compound_gen as cg  # noqa: E402
import gate_gen as gg  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402
import tower_gen as tg  # noqa: E402

# Measured in the game (probes/<world>_classes.txt, OTMEASURE): [x, y]
SIZE = {"Land_BagFence_Round_F": (2.86, 1.08), "Land_CampingTable_F": (1.95, 0.8), "Land_CampingChair_V2_F": (0.57, 0.59),
        "Land_Pallet_MilBoxes_F": (1.82, 1.94), "Land_CratesWooden_F": (2.5, 1.43), "Land_WoodenCrate_01_stack_x3_F": (1.77, 1.63),
        "Land_PowerGenerator_F": (0.98, 2.2), "Land_CanisterFuel_F": (0.39, 0.16), "CamoNet_BLUFOR_open_F": (21.58, 11.78),
        "armedcar": (3.0, 9.4)}
CRATES = ["Land_Pallet_MilBoxes_F", "Land_CratesWooden_F", "Land_WoodenCrate_01_stack_x3_F"]
WALL_IN = 5.0   # Kept clear along the walls' inside: the patrol's loop runs 3.5 m in


class Props:
    def __init__(self, block, poly, tier, items):
        self.b, self.poly, self.tier = block, [tuple(p[:2]) for p in poly], tier
        self.items = [list(it) for it in items if "props" not in it[4]]
        self.e = gg.Entrances(block, poly, tier, self.items, "")
        self.notes = []

    def put(self, kind, what, c, d, flags="ground,props"):
        z = self.b.ground(*c)
        self.items.append([kind, what, f"[{c[0]:.3f},{c[1]:.3f},{z:.3f}]", gg.orient_dir(d), flags])
        self.e.items = self.items

    def spot(self, size, d, cands, origin, inside=True, verge=False, lanes=(), wall_clear=True):
        best = None
        for c in cands:
            if inside and wall_clear and self.e.edge_dist(c) < WALL_IN:
                continue
            if self.e.free(c, d, size, inside, lanes, verge=verge):
                key = math.dist(c, origin)
                if best is None or key < best[0]:
                    best = (key, c)
        return best[1] if best else None

    def build(self):
        gates = [it for it in self.items if it[0] == "gate"]
        hq = tuple(self.b.pos[:2])
        placed = []
        lanes = []
        for g in gates:
            gp, u = gg.vec(g[2])[:2], cg.norm(gg.vdir(g[3])[:2])
            n = (-u[1], u[0])
            if not cg.inside(cg.add(gp, n), self.poly):
                n = (u[1], -u[0])
            lanes.append(tg.rect(cg.add(gp, cg.mul(n, 5.0)), n, (max(float(g[1]), 4.0) + 1.5, 11.0)))
            lanes.append(tg.rect(cg.add(gp, cg.mul(n, -4.0)), n, (max(float(g[1]), 4.0) + 1.0, 8.0)))
        main = min(gates, key=lambda g: math.dist(gg.vec(g[2])[:2], hq)) if gates else None
        if main:
            gp, u = gg.vec(main[2])[:2], cg.norm(gg.vdir(main[3])[:2])
            n = (-u[1], u[0])
            if not cg.inside(cg.add(gp, n), self.poly):
                n = (u[1], -u[0])
            out = cg.mul(n, -1)
            # The fighting holes either side of the approach, their curve out (model -y), a man behind each
            for s in (1, -1):
                cands = [cg.add(cg.add(gp, cg.mul(u, s * a)), cg.mul(out, i)) for a in (4.5, 5.5, 6.5, 7.5, 9.0) for i in (2.0, 3.0, 4.0, 5.0)]
                c = self.spot(SIZE["Land_BagFence_Round_F"], n, cands, cg.add(cg.add(gp, cg.mul(u, s * 5)), cg.mul(out, 3)), inside=False, verge=True, lanes=lanes)
                if c:
                    self.put("object", "Land_BagFence_Round_F", c, n, "ground,props,hole")
                    placed.append("fighting hole")
            # From T4 the armed car parked outside, along the wall (its length along it)
            if self.tier >= 4:
                # Parked on the street if it must, its middle 1.2 m kept clear for the traffic
                cands = [cg.add(cg.add(gp, cg.mul(u, s * a)), cg.mul(out, i)) for s in (1, -1) for a in (8, 10, 12, 14, 16, 18, 20, 22, 24) for i in (2.5, 3.0, 4.0, 5.0, 6.0, 7.0)]
                widest = max((r["width"] for r in self.b.roads), default=10.0)
                c = self.spot(SIZE["armedcar"], u, cands, cg.add(gp, cg.mul(out, 4)), inside=False, verge=widest / 2 - 0.6, lanes=lanes)
                if c:
                    self.put("vehicle", "armedcar", c, u, "ground,props")
                    placed.append("armed car")
        # Inside: the table and two chairs by the HQ
        office = min(self.b.buildings, key=lambda t: math.dist(t.pos[:2], hq))
        ring = []
        for r in (9.0, 10.0, 11.0, 12.0, 13.5):
            for k in range(24):
                a = math.radians(k * 15)
                ring.append((hq[0] + r * math.sin(a), hq[1] + r * math.cos(a)))
        c = self.spot((3.0, 2.2), (0, 1), ring, hq, lanes=lanes)
        if c:
            d = cg.norm(cg.sub(hq, c))
            self.put("object", "Land_CampingTable_F", c, d)
            side = (d[1], -d[0])
            for s in (1, -1):
                self.put("object", "Land_CampingChair_V2_F", cg.add(c, cg.mul(d, -0.9 if s > 0 else 0.9)), cg.mul(d, s))
            placed.append("table and chairs")
        # A few crates and the generator with fuel, along the inside a little in from the walls
        grid = []
        xs = [p[0] for p in self.poly]
        ys = [p[1] for p in self.poly]
        x = min(xs)
        while x <= max(xs):
            y = min(ys)
            while y <= max(ys):
                if cg.inside((x, y), self.poly):
                    grid.append((x, y))
                y += 1.0
            x += 1.0
        corner = max(self.poly, key=lambda p: math.dist(p, hq))
        for cls in CRATES:
            c = self.spot(SIZE[cls], cg.norm(cg.sub(hq, corner)), grid, corner, lanes=lanes)
            if c:
                self.put("object", cls, c, cg.norm(cg.sub(hq, c)))
                placed.append("crates")
        c = self.spot((1.6, 2.6), (0, 1), grid, corner, lanes=lanes)
        if c:
            self.put("object", "Land_PowerGenerator_F", c, (0, 1))
            self.put("object", "Land_CanisterFuel_F", cg.add(c, (1.0, 0.6)), (0, 1))
            self.put("object", "Land_CanisterFuel_F", cg.add(c, (1.0, -0.2)), (1, 0))
            placed.append("generator")
        # A camo net over a corner of the courtyard, where one fits (it's big: 21.6 x 11.8 m)
        c = self.spot(SIZE["CamoNet_BLUFOR_open_F"], cg.norm(cg.sub(hq, corner)), grid, corner, lanes=lanes, wall_clear=False)
        if c:
            self.put("object", "CamoNet_BLUFOR_open_F", c, cg.norm(cg.sub(hq, c)))
            placed.append("camo net")
        self.notes.append(", ".join(placed) or "nothing fits")
        return self.items


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    town = [a for a in argv if not a.startswith("--") and a != world][0]
    block = blocklib.load(world)[town]
    areas = merge_compounds.load_saved(world)[town]["tiers"]
    towns = merge_layouts.load_saved(world)
    t = towns[town]
    only = [int(a) for a in argv[argv.index("--tiers") + 1].split(",")] if "--tiers" in argv else (3, 4, 5)
    for tier in only:
        if tier not in areas or tier not in t["tiers"]:
            continue
        p = Props(block, areas[tier], tier, t["tiers"][tier])
        t["tiers"][tier] = p.build()
        print(f"{town} T{tier}: " + "; ".join(p.notes))
        out = os.path.join(merge_layouts.ROOT, "tools", "officegen", "compounds", f"{town}_T{tier}_props.svg")
        blocklib.svg(block, out, polygons={f"T{tier}": areas[tier]}, reach=55, scale=9, pieces=t["tiers"][tier])
    if "--dry" in argv:
        return
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
