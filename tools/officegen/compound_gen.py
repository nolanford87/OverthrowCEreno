"""
Generates a town's occupier compound walls (tools/officegen/COMPOUND_PLAN.md) from its areas
(tools/officegen/compounds/<world>.txt) and the block probe (tools/officegen/probes/<world>_blocks.txt). Each tier
3+ with an area becomes the town's tier 2 snapshot plus one ring round that area (the tier below's ring comes down):
    - an edge running into a road is set inside it: 0.25 m inside the road's edge at T3 (H-barrier), right at the
      edge at T4+ (military and concrete walls), so no wall stands on a road (the AI walks through those);
    - a road crossing an edge is a gate of its width (3.5-8 m); a compound no road crosses gets a 4 m main gate on
      its road-facing edge nearest the HQ's door;
    - a building on an edge is part of the wall; a door of it opening outside the area is barricaded;
    - the map's walls and fences along an edge or inside the area are hidden (our wall goes up on the edge's;
      the occupier cleared the compound);
    - the rest of every edge is wall: T3 2-high H-barrier (the upper layer 1.4 m up, each pair on the ground) with
      small concrete wall for the remainders; T4+ mostly the tall military wall, small concrete wall for the
      remainders, 2-high H-barrier where the ground slopes too much for a rigid panel.
Writes the tiers into tools/officegen/layouts/<world>.txt and the mod's layout data, and an SVG map of each tier.

    python tools/officegen/compound_gen.py "Town" [--world Altis] [--dry]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402

ROOT = merge_layouts.ROOT
HB = [("Land_HBarrier_5_F", 5.8), ("Land_HBarrier_3_F", 3.6), ("Land_HBarrier_1_F", 1.4)]
UPPER = 1.4
MIL = ("Land_Mil_WallBig_4m_F", 4.0)   # The tall green military wall (T4+)
MIL_JOINT = 0.1
CNC = ("Land_CncWall1_F", 1.4)         # The small grey concrete wall (fills a run's remainder)
JOINT = 0.3          # How far pieces run into each other
# How far inside a road's edge an edge along it is set, by tier (the user's): the deep H-barrier (T3) 0.25 m; the
# thin military and concrete walls (T4+) right at the edge, no margin (only off the road surface: the AI walks
# through walls standing on a road)
ROAD_CLEAR = {3: 0.25, 4: 0.0, 5: 0.0}
GATE_SMALL, GATE_LARGE = "Land_NetFence_01_m_gate_F", "Land_Net_Fence_Gate_F"


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def mul(a, k):
    return (a[0] * k, a[1] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def norm(a):
    l = math.hypot(*a) or 1
    return (a[0] / l, a[1] / l)


def seg_dist(p, a, b):
    ab = sub(b, a)
    t = max(0, min(1, dot(sub(p, a), ab) / (dot(ab, ab) or 1)))
    return math.dist(p, add(a, mul(ab, t)))


def seg_cross(a, b, c, d):
    """Where segments ab and cd cross: (t along ab, point), or None."""
    r, s = sub(b, a), sub(d, c)
    den = cross(r, s)
    if abs(den) < 1e-9:
        return None
    t = cross(sub(c, a), s) / den
    u = cross(sub(c, a), r) / den
    if 0 <= t <= 1 and 0 <= u <= 1:
        return t, add(a, mul(r, t))
    return None


def inside(p, poly):
    c = False
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]:
            c = not c
    return c


def line_meet(p, u, q, v):
    """Where the lines p + t u and q + s v meet (None if parallel)."""
    den = cross(u, v)
    if abs(den) < 1e-6:
        return None
    t = cross(sub(q, p), v) / den
    return add(p, mul(u, t))


def orient(u):
    """[vectorDir, vectorUp] for a piece whose length (model x) runs along u."""
    return f"[[{-u[1]:.4f},{u[0]:.4f},0.0000],[0.0000,0.0000,1.0000]]"


def fill_lengths(L):
    """Pieces (class, length) covering L with joints, the fewest with the least overhang."""
    best = None
    for k5 in range(int(L // 5.5) + 2):
        for k3 in range(3):
            for k1 in range(3):
                parts = [HB[0]] * k5 + [HB[1]] * k3 + [HB[2]] * k1
                if not parts:
                    continue
                cover = sum(l for _, l in parts) - JOINT * (len(parts) - 1)
                if cover + 0.05 < L:
                    continue
                key = (cover - L, len(parts))
                if best is None or key < best[0]:
                    best = (key, parts)
    return best[1] if best else [HB[2]]


class Gen:
    def __init__(self, block, poly, town, tier):
        self.b, self.town, self.tier = block, town, tier
        p = [tuple(v[:2]) for v in poly]
        area = sum(cross(p[i], p[(i + 1) % len(p)]) for i in range(len(p))) / 2
        self.poly = p if area > 0 else p[::-1]   # Counter-clockwise: inward is to the left of each edge
        self.items, self.notes = [], []
        self.done_buildings = set()
        self.solid = [t for t in block.buildings if min(t.box[2] - t.box[0], t.box[3] - t.box[1]) >= 3 and t.box[5] - t.box[4] >= 2.5]

    def ground(self, x, y):
        return self.b.ground(x, y)

    def road_clearance(self, a, b):
        """How far an edge's worst point is inside a road running along it (negative: clear of it by that much)."""
        worst = -99
        u = norm(sub(b, a))
        for r in self.b.roads:
            ra, rb = tuple(r["beg"][:2]), tuple(r["end"][:2])
            if abs(dot(norm(sub(rb, ra)), u)) < 0.85:   # Not along it (a crossing road makes a gate)
                continue
            for k in range(11):
                p = add(a, mul(sub(b, a), k / 10))
                worst = max(worst, r["width"] / 2 + ROAD_CLEAR[self.tier] - seg_dist(p, ra, rb))
        return worst

    def edges(self):
        """The edges, each set inside any road along it, re-met at the corners: [(a, b)]."""
        n = len(self.poly)
        lines = []
        for i in range(n):
            a, b = self.poly[i], self.poly[(i + 1) % n]
            u = norm(sub(b, a))
            inward = (-u[1], u[0])
            off = min(max(self.road_clearance(a, b), 0), 4)
            if off > 0:
                self.notes.append(f"edge {i} set {off:.1f} m inside a road along it")
            lines.append((add(a, mul(inward, off)), u))
        corners = []
        for i in range(n):
            p, u = lines[i - 1]
            q, v = lines[i]
            corners.append(line_meet(p, u, q, v) or q)
        return [(corners[i], corners[(i + 1) % n]) for i in range(n)]

    def gates(self, edges):
        """Openings per edge: {edge index: [(t from, t to, width, middle)]}."""
        out = {}
        for i, (a, b) in enumerate(edges):
            L = math.dist(a, b)
            for r in self.b.roads:
                hit = seg_cross(a, b, tuple(r["beg"][:2]), tuple(r["end"][:2]))
                if hit:
                    w = max(3.5, min(8.0, r["width"]))
                    t = hit[0] * L
                    out.setdefault(i, []).append((t - w / 2, t + w / 2, w, hit[1]))
        if not out:
            # No road through it: a main gate on the road-facing edge nearest the HQ's door
            hq = next((t for t in self.b.buildings if math.dist(t.pos[:2], self.b.pos[:2]) < 1), None)
            door = (hq.door_points() or [self.b.pos[:2]])[0] if hq else self.b.pos[:2]
            best = None
            for i, (a, b) in enumerate(edges):
                L = math.dist(a, b)
                if L < 8:
                    continue
                facing = min((seg_dist(add(a, mul(sub(b, a), k / 10)), tuple(r["beg"][:2]), tuple(r["end"][:2])) for r in self.b.roads for k in range(11)), default=99)
                if facing > 12:
                    continue
                t = max(4, min(L - 4, dot(sub(door, a), norm(sub(b, a)))))
                m = add(a, mul(norm(sub(b, a)), t))
                score = math.dist(m, door)
                if self.on_building(m, 0):
                    continue
                if best is None or score < best[0]:
                    best = (score, i, t, m)
            if best:
                _, i, t, m = best
                out[i] = [(t - 2, t + 2, 4.0, m)]
                self.notes.append(f"no road crosses it: a 4 m main gate on edge {i}")
        return out

    def on_building(self, p, deep=2.0):
        """The building whose footprint holds p at least deep metres in from every side of its box (a box is
        bigger than the walls: porches, a garage's open front; an edge only grazing one gets a wall)."""
        for t in self.solid:
            lx, ly = blocklib.rot(p[0] - t.pos[0], p[1] - t.pos[1], -t.dir)
            if t.box[0] + deep <= lx <= t.box[2] - deep and t.box[1] + deep <= ly <= t.box[3] - deep:
                return t
        return None

    def build(self):
        edges = self.edges()
        gates = self.gates(edges)
        hidden = set()
        for i, (a, b) in enumerate(edges):
            L = math.dist(a, b)
            if L < 0.2:
                continue
            u = norm(sub(b, a))
            # Along the edge every 0.25 m: open (wall goes up), a building, or a gate
            n = max(1, int(L / 0.25))
            kinds = []
            for k in range(n + 1):
                t = L * k / n
                p = add(a, mul(u, t))
                g = any(t0 <= t <= t1 for t0, t1, _, _ in gates.get(i, []))
                kinds.append("gate" if g else ("bld" if self.on_building(p) else "wall"))
            # Wall stretches, run 0.4 m into a building they meet (a joint), never into a gate
            runs, start = [], None
            for k, kd in enumerate(kinds + ["end"]):
                if kd == "wall" and start is None:
                    start = k
                elif kd != "wall" and start is not None:
                    t0, t1 = L * start / n, L * (k - 1) / n
                    if start > 0 and kinds[start - 1] == "bld":
                        t0 -= 0.4
                    if k <= n and kinds[k] == "bld":
                        t1 += 0.4
                    runs.append((t0, t1))
                    start = None
            for t0, t1 in runs:
                self.lay(add(a, mul(u, t0)), u, t1 - t0)
            # Buildings on the edge: one with doors opening both into the compound and out of it is a way through,
            # so its outward doors are barricaded (a door opens the way from the building's middle through it)
            for t in {self.on_building(add(a, mul(u, L * k / n))) for k, kd in enumerate(kinds) if kd == "bld"} - {None}:
                if id(t) in self.done_buildings:
                    continue
                self.done_buildings.add(id(t))
                ins, outs = [], []
                for d in t.door_points():
                    out_dir = norm(sub(d, t.pos[:2]))
                    (ins if inside(add(d, mul(out_dir, 1.5)), self.poly) else outs).append((d, out_dir))
                if ins and outs:
                    for d, nrm in outs:
                        side = (nrm[1], -nrm[0])
                        self.lay(add(add(d, mul(nrm, 1.3)), mul(side, -1.8)), side, 3.6)
                    self.notes.append(f"{len(outs)} outward doors of {t.model} (a way through) barricaded")
            # The map's walls and fences along the edge hidden
            for w in self.b.walls:
                c = w.corners()
                e1 = ((c[0][0] + c[3][0]) / 2, (c[0][1] + c[3][1]) / 2)
                e2 = ((c[1][0] + c[2][0]) / 2, (c[1][1] + c[2][1]) / 2)
                mid = ((e1[0] + e2[0]) / 2, (e1[1] + e2[1]) / 2)
                along = norm(sub(e2, e1))
                # On the edge (along it, or short), or anywhere inside the area: the occupier cleared the compound
                # (the edge as drawn and as set off a road: whichever is nearer)
                a0, b0 = self.poly[i], self.poly[(i + 1) % len(self.poly)]
                near = min(seg_dist(mid, a, b), seg_dist(mid, a0, b0))
                if id(w) not in hidden and (inside(mid, self.poly) or (near < 2.0 and (math.dist(e1, e2) < 1.5 or abs(dot(along, u)) > 0.9))):
                    hidden.add(id(w))
                    self.items.append(["hide", w.model, f"[{w.pos[0]:.3f},{w.pos[1]:.3f},{w.pos[2]:.3f}]", "[[0.0000,1.0000,0.0000],[0.0000,0.0000,1.0000]]", ""])
            # The gates
            for t0, t1, w, m in gates.get(i, []):
                pos = add(a, mul(u, (t0 + t1) / 2))
                z = self.ground(*pos)
                self.items.append(["gate", f"{w:.1f}", f"[{pos[0]:.3f},{pos[1]:.3f},{z:.3f}]", f"[[{u[0]:.4f},{u[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", ""])
                self.items.append(["object", GATE_SMALL if w <= 4.8 else GATE_LARGE, f"[{pos[0]:.3f},{pos[1]:.3f},{z:.3f}]", orient(u), "ground,open"])
        self.notes.append(f"{sum(1 for it in self.items if it[0] == 'hide')} map walls and fences hidden, {sum(1 for it in self.items if it[0] == 'gate')} gates")
        return self.items

    def lay(self, a, u, L):
        """A wall from a along u for L metres in the tier's materials:
        T3: 2-high H-barrier (HBarrier_5/3), the odd remainder in small concrete wall (CncWall1);
        T4+: the tall military wall (Mil_WallBig_4m) panel by panel, the remainder in small concrete wall; 2-high
        H-barrier where a rigid panel can't sit (ground falling more than 0.5 m along it) or a run is too short."""
        if L < 0.3:
            return
        if self.tier >= 4 and L >= MIL[1] - 0.2:
            t, slope = 0.0, None
            while t < L - 0.05:
                rest = L - t
                if rest >= MIL[1] - 0.2:
                    p0, p1 = add(a, mul(u, t)), add(a, mul(u, min(t + MIL[1], L)))
                    if abs(self.ground(*p0) - self.ground(*p1)) <= 0.5:
                        if slope is not None:
                            self.lay_hb(add(a, mul(u, slope)), u, t - slope + JOINT)
                            slope = None
                        mid = t + MIL[1] / 2 if rest >= MIL[1] else L - MIL[1] / 2
                        self.piece(MIL[0], add(a, mul(u, mid)), u)
                        t += MIL[1] - MIL_JOINT
                        continue
                    if slope is None:
                        slope = t
                    t += 1.0
                    continue
                if slope is not None:
                    self.lay_hb(add(a, mul(u, slope)), u, L - slope)
                else:
                    self.lay_cnc(add(a, mul(u, t - MIL_JOINT)), u, rest + MIL_JOINT)
                return
            if slope is not None:
                self.lay_hb(add(a, mul(u, slope)), u, L - slope)
            return
        self.lay_hb(a, u, L, cnc_rest=self.tier == 3)

    def piece(self, cls, p, u, upper=False):
        z = self.ground(*p)
        self.items.append(["object", cls, f"[{p[0]:.3f},{p[1]:.3f},{z:.3f}]", orient(u), ""])
        if upper:
            self.items.append(["object", cls, f"[{p[0]:.3f},{p[1]:.3f},{z + UPPER:.3f}]", orient(u), ""])

    def lay_hb(self, a, u, L, cnc_rest=False):
        """2-high H-barrier along L; with cnc_rest, H-barrier 5s and 3s only and the remainder in small concrete wall."""
        if L < 0.3:
            return
        if cnc_rest:
            best = None
            for k5 in range(int(L // 5.5) + 1):
                for k3 in range(3):
                    parts = [HB[0]] * k5 + [HB[1]] * k3
                    cover = sum(l for _, l in parts) - JOINT * max(len(parts) - 1, 0) if parts else 0
                    if cover > L + 0.05:
                        continue
                    key = (L - cover, len(parts))
                    if best is None or key < best[0]:
                        best = (key, parts, cover)
            _, parts, cover = best
            t = 0
            for cls, l in parts:
                self.piece(cls, add(a, mul(u, t + l / 2)), u, upper=True)
                t += l - JOINT
            if L - cover > 0.2:
                self.lay_cnc(add(a, mul(u, max(cover - JOINT, 0))), u, L - max(cover - JOINT, 0))
            return
        t = 0
        for cls, l in fill_lengths(L):
            mid = min(t + l / 2, L - l / 2) if l < L else L / 2
            self.piece(cls, add(a, mul(u, mid)), u, upper=True)
            t += l - JOINT

    def lay_cnc(self, a, u, L):
        """Small concrete wall (CncWall1) panels along L."""
        k = max(1, math.ceil((L - CNC[1]) / (CNC[1] - 0.1)) + 1) if L > CNC[1] else 1
        for i in range(k):
            mid = min(CNC[1] / 2 + i * (CNC[1] - 0.1), L - CNC[1] / 2) if L > CNC[1] else L / 2
            self.piece(CNC[0], add(a, mul(u, mid)), u)


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    town = [a for a in argv if not a.startswith("--") and a != world][0]
    block = blocklib.load(world)[town]
    areas = merge_compounds.load_saved(world)[town]["tiers"]
    towns = merge_layouts.load_saved(world)
    t = towns[town]
    base = [it for it in t["tiers"].get(2, [])]
    polys = {}
    for tier in (3, 4, 5):
        if tier not in areas:
            continue
        g = Gen(block, areas[tier], town, tier)
        items = g.build()
        print(f"{town} T{tier}: {sum(1 for it in items if it[0] == 'object')} pieces; " + "; ".join(g.notes))
        t["tiers"][tier] = [list(it) for it in base] + items
        polys[f"T{tier}"] = areas[tier]
        out = os.path.join(ROOT, "tools", "officegen", "compounds", f"{town}_T{tier}_walls.svg")
        blocklib.svg(block, out, polygons={f"T{tier}": areas[tier]}, reach=65, scale=8, pieces=t["tiers"][tier])
    if "--dry" in argv:
        return
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
