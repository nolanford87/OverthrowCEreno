"""
The occupier compounds' gate entrances (tools/officegen/COMPOUND_PLAN.md, step 4 of the Rodopoli pilot), changing
only what's round each gate (the "gate" markers of the tiers 3+ layouts):
    - the gate: T3 the net-fence swing gate, T4+ the concrete sliding gate (Land_ConcreteWall_01_l_gate_F: 10.6 m
      with the stub its panel slides behind, the way through 4.1 m), set on the opening; shut and locked in play,
      worked by the occupier (OT_fnc_officeGates): no "open" flag. The wall pieces the T4 gate stands on come out
      and the gaps either side of it are filled with small concrete wall;
    - the main gate (the one nearest the HQ) dressed inside, clear of a lane 10 m in from the gate: a small sandbag
      bunker, the flag by the wall beside the gate, a floodlight about 4 m in and 4 m aside aimed at the gate, two
      lamps along the wall; one warning sign outside; from T4 an HMG behind round sandbags aimed out through the
      gate (crewed in the garrison step);
    - side gates: a floodlight and a sign.
    (The user's touches at Rodopoli's T3: one sign, read from the street (its model +y in); the light aimed at the
    gate (its lamps face model -y); the flag by the wall.)
The pieces carry the "entrance" flag; running it again replaces only those (the gate's own cut stays).

    python tools/officegen/gate_gen.py "Town" [--world Altis] [--tiers 3,4] [--dry]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import compound_gen as cg  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402
import tower_gen as tg  # noqa: E402

T3_GATE = "Land_NetFence_01_m_gate_F"
T4_GATE = "Land_ConcreteWall_01_l_gate_F"
T4_SPAN = (-5.3, 5.3)    # Model x of the T4 gate's ends
T4_WAY = (-4.0, 0.1)     # Model x of its way through, open
WALLS = ("Mil_WallBig", "CncWall", "HBarrier")
CNC = cg.CNC
# Measured in the game (probes/Altis_classes.txt): [x, y]
SIZE = {"Land_BagBunker_Small_F": (5.0, 5.69), "Flag_NATO_F": (0.6, 0.6), "Land_PortableLight_double_F": (1.35, 1.02),
        "Land_LampShabby_F": (0.7, 0.8), "Land_Sign_WarningMilitaryArea_F": (2.09, 0.3), "Land_BagFence_Round_F": (2.86, 1.08),
        "hmg": (1.6, 2.3)}
LANE = 10.0


def vec(s):
    return [float(v) for v in str(s).strip("[]").split(",")]


def vdir(o):
    return vec(str(o).split("],[")[0])


def orient_dir(d):
    """[vectorDir, vectorUp] facing d (model +y along d)."""
    return f"[[{d[0]:.4f},{d[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]"


class Entrances:
    def __init__(self, block, poly, tier, items, town):
        self.b, self.poly, self.tier, self.town = block, [tuple(p[:2]) for p in poly], tier, town
        self.items = [list(it) for it in items if "entrance" not in it[4]]
        self.notes = []

    def edge_dist(self, p):
        n = len(self.poly)
        return min(cg.seg_dist(p, self.poly[i], self.poly[(i + 1) % n]) for i in range(n))

    def pieces(self):
        return [tg.piece_rect(it) for it in self.items if it[0] == "object"] + \
            [tg.rect(vec(it[2])[:2], cg.norm(vdir(it[3])[:2]), SIZE.get(it[1], (1.0, 1.0))) for it in self.items if it[0] == "static"]

    def free(self, c, d, size, inside=True, lanes=(), pad=0.4, verge=False):
        """Room for a footprint at c facing d: in (or out of) the area, off buildings, doors, pieces, roads, lanes."""
        box = tg.rect(c, d, size)
        if inside and not all(cg.inside(p, self.poly) for p in box):
            return False
        if not inside and any(cg.inside(p, self.poly) for p in box):
            return False
        padded = tg.rect(c, d, size, pad)
        for t in self.b.buildings:
            if tg.overlap(padded, t.corners()) or any(math.dist(c, q) < max(size) / 2 + 2.0 for q in t.door_points()):
                return False
        if any(tg.overlap(padded, q) for q in self.pieces()):
            return False
        for r in self.b.roads:
            if any(cg.seg_dist(p, r["beg"][:2], r["end"][:2]) < r["width"] / 2 + (-1.5 if verge else 0.3) for p in box + [c]):
                return False
        if any(tg.overlap(padded, q) for q in lanes):
            return False
        zs = [self.b.ground(*p) for p in box]
        return max(zs) - min(zs) <= 0.8

    def put(self, kind, cls, c, d, extra="ground,entrance"):
        z = self.b.ground(*c)
        self.items.append([kind, cls, f"[{c[0]:.3f},{c[1]:.3f},{z:.3f}]", orient_dir(d), extra])

    def near_spot(self, origin, size, d, rings, inside=True, lanes=(), verge=False):
        """The free spot nearest origin among rings of candidates (offsets along/inward), facing d."""
        best = None
        for c in rings:
            if self.free(c, d, size, inside, lanes, verge=verge):
                key = math.dist(c, origin)
                if best is None or key < best[0]:
                    best = (key, c)
        return best[1] if best else None

    def build(self):
        gates = [it for it in self.items if it[0] == "gate"]
        if not gates:
            return self.items
        hq = self.b.pos[:2]
        main = min(gates, key=lambda g: math.dist(vec(g[2])[:2], hq))
        for g in gates:
            gp = vec(g[2])[:2]
            u = cg.norm(vdir(g[3])[:2])                    # Along the wall line
            n = (-u[1], u[0])
            if not cg.inside(cg.add(gp, n), self.poly):
                n = (u[1], -u[0])                            # Inward
            self.gate(g, gp, u, n)
            lane = tg.rect(cg.add(gp, cg.mul(n, LANE / 2)), n, (max(float(g[1]), 4.0) + 1.5, LANE + 1.0))
            outer = tg.rect(cg.add(gp, cg.mul(n, -4.0)), n, (max(float(g[1]), 4.0) + 1.0, 8.0))
            self.dress(gp, u, n, [lane, outer], main=g is main, way=(T4_WAY[1] - T4_WAY[0]) if self.tier >= 4 else 3.7)
        return self.items

    def gate(self, g, gp, u, n):
        """The gate object on the opening: the right class, shut (no "open"); a T4 one cut into its wall."""
        objs = [it for it in self.items if it[0] == "object" and "gate" in it[1].lower() and math.dist(vec(it[2])[:2], gp) < 3.0]
        for it in objs:
            self.items.remove(it)
        if self.tier < 4:
            same = [it for it in objs if it[1] == T3_GATE]
            if same:  # Where it stands (the user's), only shut
                it = same[0]
                self.items.append([it[0], it[1], it[2], it[3], ",".join(f for f in it[4].split(",") if f and f != "open")])
            else:
                self.put("object", T3_GATE, gp, n, "ground")
            self.notes.append(f"T{self.tier} gate at [{gp[0]:.1f}, {gp[1]:.1f}]: net-fence gate, shut")
            return
        # The way through's middle on the opening: the stub to whichever side has more wall to stand in
        mid = (T4_WAY[0] + T4_WAY[1]) / 2
        best = None
        for s in (1, -1):
            ax = cg.mul(u, s)
            c = cg.add(gp, cg.mul(ax, -mid))
            ends = (cg.add(c, cg.mul(ax, T4_SPAN[0])), cg.add(c, cg.mul(ax, T4_SPAN[1])))
            clash = sum(1 for t in self.b.buildings if tg.overlap(tg.rect(c, (-ax[1], ax[0]), (T4_SPAN[1] - T4_SPAN[0], 1.0)), t.corners()))
            road = sum(1 for r in self.b.roads for e in ends if cg.seg_dist(e, r["beg"][:2], r["end"][:2]) < r["width"] / 2)
            key = (clash + road, s != 1)
            if best is None or key < best[0]:
                best = (key, s, c, ax)
        _, s, c, ax = best
        # Out with the wall pieces on its span (along the line, within 1.5 m of it)
        lo, hi = T4_SPAN[0] - 0.05, T4_SPAN[1] + 0.05
        kept_ends = []
        out = 0
        for it in list(self.items):
            if it[0] != "object" or not any(w in it[1] for w in WALLS):
                continue
            p = vec(it[2])[:2]
            rel = cg.sub(p, c)
            t, off = cg.dot(rel, ax), cg.dot(rel, (-ax[1], ax[0]))
            if abs(off) > 1.5:
                continue
            half = (tg.townlib.MEASURED.get(it[1]) or tg.townlib.CLASSES.get(it[1]) or (1.0, 1.0))[0] / 2
            if t + half > lo + 0.3 and t - half < hi - 0.3:
                self.items.remove(it)
                out += 1
            else:
                kept_ends.append((t - half, t + half))
        # The gaps either side filled with small concrete wall
        filled = 0
        right = min((a for a, b2 in kept_ends if a >= hi - 0.3), default=None)
        left = max((b2 for a, b2 in kept_ends if b2 <= lo + 0.3), default=None)
        for a, b2 in ((hi - 0.05, right), (left, lo + 0.05)):
            if a is None or b2 is None or b2 - a < 0.25 or b2 - a > 6.0:
                continue
            start = cg.add(c, cg.mul(ax, a))
            before = len(self.items)
            k = max(1, math.ceil((b2 - a - CNC[1]) / (CNC[1] - 0.1)) + 1) if b2 - a > CNC[1] else 1
            for i in range(k):
                mid_t = min(CNC[1] / 2 + i * (CNC[1] - 0.1), (b2 - a) - CNC[1] / 2) if b2 - a > CNC[1] else (b2 - a) / 2
                p = cg.add(start, cg.mul(ax, mid_t))
                self.items.append(["object", CNC[0], f"[{p[0]:.3f},{p[1]:.3f},{self.b.ground(*p):.3f}]", cg.orient(ax), "entrance"])
            filled += len(self.items) - before
        self.items.append(["object", T4_GATE, f"[{c[0]:.3f},{c[1]:.3f},{self.b.ground(*c):.3f}]", cg.orient(ax), "ground,entrance"])
        self.notes.append(f"T{self.tier} gate at [{gp[0]:.1f}, {gp[1]:.1f}]: concrete sliding gate, {out} wall pieces out, {filled} concrete filling")

    def dress(self, gp, u, n, lanes, main, way):
        placed = []

        def ring(origin, along, inward):
            return [cg.add(cg.add(origin, cg.mul(u, a)), cg.mul(n, i)) for a in along for i in inward]

        sides = [x * s for x in (3.5, 4.5, 5.5, 6.5, 7.5, 9.0) for s in (1, -1)]
        if main:
            # The bunker beside the lane, firing out
            c = self.near_spot(cg.add(gp, cg.mul(n, 4.0)), SIZE["Land_BagBunker_Small_F"], cg.mul(n, -1),
                               ring(gp, [x * s for x in (5.5, 6.5, 7.5, 9.0, 10.5, 12.0, 14.0) for s in (1, -1)], (3.5, 4.5, 5.5, 6.5, 8.0, 9.5)), lanes=lanes)
            if c:
                self.put("object", "Land_BagBunker_Small_F", c, cg.mul(n, -1))
                placed.append("bunker")
            c = self.near_spot(cg.add(cg.add(gp, cg.mul(u, 3.0)), cg.mul(n, 0.8)), SIZE["Flag_NATO_F"], n, ring(gp, sides, (0.8, 1.2, 1.8, 2.5)), lanes=lanes)
            if c:
                self.put("object", "Flag_NATO_F", c, n, "ground,flag,entrance")
                placed.append("flag")
            if self.tier >= 4:
                # The HMG behind round sandbags firing out through the gate (a T4 wall is higher than it): off the
                # lane, aimed through the gate's middle at the street, no more than 50 degrees off straight out
                best = None
                for c in ring(gp, [x * s for x in (3.0, 3.5, 4.0, 5.0, 6.0) for s in (1, -1)], (5.0, 6.0, 7.5, 9.0, 10.5, 12.0)):
                    d = cg.norm(cg.sub(gp, c))
                    if cg.dot(d, cg.mul(n, -1)) < math.cos(math.radians(50)):
                        continue
                    if self.free(c, d, (3.2, 3.2), lanes=lanes):
                        key = math.dist(c, gp)
                        if best is None or key < best[0]:
                            best = (key, c, d)
                if best:
                    _, c, d = best
                    self.put("static", "hmg", c, d)
                    self.put("object", "Land_BagFence_Round_F", cg.add(c, cg.mul(d, 1.4)), d)
                    placed.append("HMG nest")
        # A floodlight inside beside the lane, aimed at the gate (its lamps face model -y)
        rings = ring(gp, [x * s for x in (3.5, 4.0, 4.5, 5.0, 6.0) for s in (1, -1)], (3.5, 4.0, 4.5, 5.0, 6.0))
        best = None
        for c in rings:
            d = cg.norm(cg.sub(c, gp))
            if self.free(c, d, SIZE["Land_PortableLight_double_F"], lanes=lanes):
                key = abs(math.dist(c, gp) - 5.8)
                if best is None or key < best[0]:
                    best = (key, c, d)
        if best:
            self.put("object", "Land_PortableLight_double_F", best[1], best[2])
            placed.append("floodlight")
        # One sign outside, read from the street (its model +y in)
        c = self.near_spot(cg.add(gp, cg.mul(u, 4.0)), SIZE["Land_Sign_WarningMilitaryArea_F"], n,
                           ring(gp, [x * s for x in (3.5, 4.5, 5.5, 6.5, 8.0) for s in (1, -1)], (-1.2, -1.8, -2.5, -3.2)), inside=False, lanes=lanes, verge=True)
        if c:
            self.put("object", "Land_Sign_WarningMilitaryArea_F", c, n)
            placed.append("sign")
        # Lamps along the wall inside, either side
        if main:
            for s in (1, -1):
                c = self.near_spot(cg.add(gp, cg.mul(u, s * 11.0)), SIZE["Land_LampShabby_F"], n,
                                   ring(gp, [s * x for x in (9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 16.0)], (1.6, 2.2, 3.0)), lanes=lanes)
                if c:
                    self.put("object", "Land_LampShabby_F", c, n)
                    placed.append("lamp")
        self.notes.append(f"  {'main' if main else 'side'} gate: {', '.join(placed) or 'nothing fits'}")


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
        e = Entrances(block, areas[tier], tier, t["tiers"][tier], town)
        t["tiers"][tier] = e.build()
        print(f"{town} T{tier}:\n  " + "\n  ".join(e.notes))
        out = os.path.join(merge_layouts.ROOT, "tools", "officegen", "compounds", f"{town}_T{tier}_gates.svg")
        blocklib.svg(block, out, polygons={f"T{tier}": areas[tier]}, reach=50, scale=10, pieces=t["tiers"][tier])
    if "--dry" in argv:
        return
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
