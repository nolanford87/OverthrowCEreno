"""
The occupier compounds' garrison posts (tools/officegen/COMPOUND_PLAN.md, step 5 of the Rodopoli pilot), adding guards
to the reviewed tiers 3+ and changing nothing else. One man per 200 m2 of the tier's area, posts included, filled in
this order until the count is reached:
    1. the lookout towers: a marksman each (and an autorifleman in each from T4), on the tower's floor;
    2. the main gate (the one nearest the HQ): an autorifleman, in the gate bunker if it has one;
    3. the HMG crew (a static is crewed in play, so it counts);
    4. from T4 an AT soldier near the main gate;
    5. up to three at the HQ's upper windows (its buildingPos places);
    6. the patrol: a fireteam of four (rifleman, autorifleman, two riflemen) in the courtyard, "patrol" (it walks
       the inside of the walls in play);
    7. a rifleman at each side gate;
    8. more at the HQ's places.
Heights and places from the class probe (probes/<world>_classes.txt: OTFLOORS, OTBPOS). The guards carry the
"garrison" flag; running it again replaces only those.

    python tools/officegen/garrison_gen.py "Town" [--world Altis] [--tiers 3,4] [--dry]
"""
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

PER_MAN = 200.0
# Where a man stands on a tower (model x, y, height above its base), the first the lookout
TOWER_POSTS = {"Land_BagBunker_Tower_F": [(0.0, -2.0, 2.75)],
               "Land_Cargo_Patrol_V1_F": [(-2.3, 0.8, 4.44), (-2.0, -1.2, 4.14)]}
BUNKER_POSTS = [(0.9, -1.2, 0.09), (-0.9, -1.2, 0.09)]   # Land_BagBunker_Small_F's firing places, its slit model -y
PATROL = ["rifleman", "autorifleman", "rifleman", "rifleman"]
MAN = (0.8, 0.8)


def classes(world):
    """{class: [[x, y, h], ...]} buildingPos places from the class probe."""
    out = {}
    path = os.path.join(merge_layouts.ROOT, "tools", "officegen", "probes", f"{world}_classes.txt")
    for line in open(path, encoding="utf-8"):
        f = line.rstrip("\n").split("|")
        if f[0] == "OTBPOS":
            out[f[1]] = [[float(v) for v in p.split(",")] for p in re.findall(r"\[([^\[\]]+)\]", f[2])]
    return out


def area(p):
    return abs(sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))) / 2


def to_world(pos, vd, x, y):
    """Model (x, y) of a thing at pos whose model +y points along vd."""
    vx = (vd[1], -vd[0])
    return (pos[0] + vx[0] * x + vd[0] * y, pos[1] + vx[1] * x + vd[1] * y)


def heading(a, b):
    """The compass direction from a to b."""
    return math.degrees(math.atan2(b[0] - a[0], b[1] - a[1])) % 360


class Garrison:
    def __init__(self, block, poly, tier, items, places):
        self.b, self.poly, self.tier = block, [tuple(p[:2]) for p in poly], tier
        self.items = [list(it) for it in items if not (it[0] == "guard" and "garrison" in it[4])]
        self.places = places
        self.count = round(area(self.poly) / PER_MAN)
        self.centre = (sum(p[0] for p in self.poly) / len(self.poly), sum(p[1] for p in self.poly) / len(self.poly))
        self.e = gg.Entrances(block, poly, tier, self.items, "")
        self.men = []
        self.notes = []

    def room(self):
        return self.count - len(self.men) - sum(1 for it in self.items if it[0] == "static")

    def man(self, role, p, z, facing, flags):
        if self.room() <= 0:
            return False
        self.men.append(["guard", role, f"[{p[0]:.3f},{p[1]:.3f},{z:.3f}]", f"{facing:.1f}", ",".join(["garrison"] + flags)])
        return True

    def ground_man(self, role, origin, cands, facing_to=None, flags=()):
        taken = [gg.vec(m[2])[:2] for m in self.men]
        best = None
        for c in cands:
            if any(math.dist(c, t) < 1.5 for t in taken) or not self.e.free(c, (0, 1), MAN, pad=0.3):
                continue
            key = math.dist(c, origin)
            if best is None or key < best[0]:
                best = (key, c)
        if not best:
            return False
        c = best[1]
        face = heading(c, facing_to) if facing_to else heading(self.centre, c)
        return self.man(role, c, self.b.ground(*c), face, ["ground"] + list(flags))

    def build(self):
        gates = [it for it in self.items if it[0] == "gate"]
        hq = tuple(self.b.pos[:2])
        main = min(gates, key=lambda g: math.dist(gg.vec(g[2])[:2], hq)) if gates else None
        placed = {}

        def note(k):
            placed[k] = placed.get(k, 0) + 1

        # 1. The towers
        for it in [it for it in self.items if it[0] == "object" and "lookout" in it[4]]:
            pos, vd = gg.vec(it[2]), cg.norm(gg.vdir(it[3])[:2])
            for k, (x, y, h) in enumerate(TOWER_POSTS.get(it[1], [])):
                if k > 0 and self.tier < 4:
                    break
                p = to_world(pos, vd, x, y)
                if self.man(["marksman", "autorifleman"][min(k, 1)], p, pos[2] + h, heading(self.centre, p), []):
                    note("tower " + ["marksman", "autorifleman"][min(k, 1)])
        # 2. The main gate's autorifleman
        if main:
            gp = gg.vec(main[2])[:2]
            u = cg.norm(gg.vdir(main[3])[:2])
            n = (-u[1], u[0])
            if not cg.inside(cg.add(gp, n), self.poly):
                n = (u[1], -u[0])
            bunker = [it for it in self.items if it[1] == "Land_BagBunker_Small_F" and math.dist(gg.vec(it[2])[:2], gp) < 15]
            if bunker:
                # At the firing place nearer the gate, facing out through the slit
                pos, vd = gg.vec(bunker[0][2]), cg.norm(gg.vdir(bunker[0][3])[:2])
                x, y, h = min(BUNKER_POSTS, key=lambda q: math.dist(to_world(pos, vd, q[0], q[1]), gp))
                p = to_world(pos, vd, x, y)
                if self.man("autorifleman", p, pos[2] + h, heading(p, cg.sub(p, vd)), []):
                    note("gate bunker autorifleman")
            else:
                cands = [cg.add(cg.add(gp, cg.mul(u, a)), cg.mul(n, i)) for a in (-6, -5, -4, -3, 3, 4, 5, 6) for i in (2, 3, 4, 5)]
                if self.ground_man("autorifleman", cg.add(gp, cg.mul(n, 3)), cands, cg.add(gp, cg.mul(n, -20))):
                    note("gate autorifleman")
        # 3. The HMG crews count (a static is crewed in play)
        # 4. The AT soldier from T4
        if main and self.tier >= 4:
            # Not in a static's way (5 m clear of one)
            statics = [gg.vec(it[2])[:2] for it in self.items if it[0] == "static"]
            cands = [c for c in (cg.add(cg.add(gp, cg.mul(u, a)), cg.mul(n, i)) for a in (-7, -5, -3, 3, 5, 7) for i in (6, 7, 8, 9, 10))
                     if all(math.dist(c, q) >= 5 for q in statics)]
            if self.ground_man("at", cg.add(gp, cg.mul(n, 8)), cands, gp):
                note("AT")
        # 5. The HQ's upper windows: the three places nearest its outer sides (a side each where it can), facing out
        # through the nearest side
        places = self.places.get(self.b.office, [])
        vd_hq = (math.sin(math.radians(self.b.dir)), math.cos(math.radians(self.b.dir)))
        office = min(self.b.buildings, key=lambda t: math.dist(t.pos[:2], hq))
        bx = office.box

        def side(q):
            """The nearest side of the HQ's box to a place: (distance, outward model direction)."""
            return min([(q[0] - bx[0], (-1, 0)), (bx[2] - q[0], (1, 0)), (q[1] - bx[1], (0, -1)), (bx[3] - q[1], (0, 1))])

        upper = sorted([p for p in places if p[2] > 2.0], key=lambda q: side(q)[0])
        chosen = []
        for q in upper:  # One a side first
            if len(chosen) < 3 and side(q)[1] not in [side(c)[1] for c in chosen]:
                chosen.append(q)
        chosen += [q for q in upper if q not in chosen][:3 - len(chosen)]
        for x, y, h in chosen:
            p = to_world(hq, vd_hq, x, y)
            out = side((x, y))[1]
            if self.man("rifleman", p, self.b.pos[2] + h, heading(p, to_world(hq, vd_hq, x + out[0], y + out[1])), []):
                note("HQ window")
        # 6. The patrol fireteam in the courtyard
        cands = []
        minx, maxx = min(p[0] for p in self.poly), max(p[0] for p in self.poly)
        miny, maxy = min(p[1] for p in self.poly), max(p[1] for p in self.poly)
        x = minx
        while x <= maxx:
            y = miny
            while y <= maxy:
                if cg.inside((x, y), self.poly) and self.e.edge_dist((x, y)) > 3:
                    cands.append((x, y))
                y += 1.0
            x += 1.0
        if self.room() >= len(PATROL):
            for role in PATROL:
                if self.ground_man(role, self.centre, cands, None, ["patrol"]):
                    note("patrol " + role)
        # 7. A rifleman at each side gate
        for g in gates:
            if g is main:
                continue
            sp = gg.vec(g[2])[:2]
            su = cg.norm(gg.vdir(g[3])[:2])
            sn = (-su[1], su[0])
            if not cg.inside(cg.add(sp, sn), self.poly):
                sn = (su[1], -su[0])
            cands = [cg.add(cg.add(sp, cg.mul(su, a)), cg.mul(sn, i)) for a in (-5, -4, -3, 3, 4, 5) for i in (2, 3, 4)]
            if self.ground_man("rifleman", cg.add(sp, cg.mul(sn, 3)), cands, cg.add(sp, cg.mul(sn, -20))):
                note("side gate rifleman")
        # 8. The rest at the HQ's other places
        for x, y, h in [p for p in places if p not in chosen]:
            p = to_world(hq, vd_hq, x, y)
            out = side((x, y))[1]
            if self.man("rifleman", p, self.b.pos[2] + h, heading(p, to_world(hq, vd_hq, x + out[0], y + out[1])), []):
                note("HQ")
        statics = sum(1 for it in self.items if it[0] == "static")
        self.notes.append(f"{len(self.men)} men + {statics} static crew of {self.count} (one per {PER_MAN:.0f} m2): " +
                          ", ".join(f"{v} {k}" for k, v in placed.items()))
        return self.items + self.men


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    town = [a for a in argv if not a.startswith("--") and a != world][0]
    block = blocklib.load(world)[town]
    areas = merge_compounds.load_saved(world)[town]["tiers"]
    towns = merge_layouts.load_saved(world)
    t = towns[town]
    places = classes(world)
    only = [int(a) for a in argv[argv.index("--tiers") + 1].split(",")] if "--tiers" in argv else (3, 4, 5)
    for tier in only:
        if tier not in areas or tier not in t["tiers"]:
            continue
        g = Garrison(block, areas[tier], tier, t["tiers"][tier], places)
        t["tiers"][tier] = g.build()
        print(f"{town} T{tier}: " + "; ".join(g.notes))
        marks = {f"{m[1][:2]}{i}": gg.vec(m[2]) for i, m in enumerate(g.men)}
        out = os.path.join(merge_layouts.ROOT, "tools", "officegen", "compounds", f"{town}_T{tier}_garrison.svg")
        blocklib.svg(block, out, polygons={f"T{tier}": areas[tier]}, reach=55, scale=9, pieces=t["tiers"][tier], marks=marks)
    if "--dry" in argv:
        return
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
