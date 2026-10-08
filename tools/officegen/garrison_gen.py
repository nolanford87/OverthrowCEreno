"""
The occupier compounds' garrison posts (tools/officegen/COMPOUND_PLAN.md), adding guards to the reviewed tiers 3+
and changing nothing else. One man per 150 m2 of the tier's area (the user's), posts included, in this order:
    1. the lookout towers: a marksman each (and an autorifleman in each from T4), on the tower's floor; where the
       compound had no room for a tower (tower_gen.py's plan: T3 one, T4 two), a marksman at an upper window
       instead, in the building on the area that's nearest its line (the HQ when no other has an upper floor);
    2. the main gate (the one nearest the HQ): an autorifleman, in the gate bunker if it has one; the HMG crew (a
       static is crewed in play, so it counts); from T4 an AT soldier near the main gate; a rifleman in each
       fighting hole outside it (props_gen.py);
    3. elevated posts until every long wall stretch is overlooked (overlook.py: roofs and upper floors of the
       buildings inside the area or on its line; a post earns its man with 10 m of wall more); a flat-roof post
       gets a short sandbag ring piece ("post"); no ground sentries at the walls;
    4. from T4 the patrol: a fireteam of four just inside the main gate, "patrol" (it walks the inside of the
       walls in play);
    5. all the men left: the reserve, a loose group 4-8 m out from the HQ's main door, "reserve" (it hunts inside
       the walls on the alarm, OT_fnc_officeGarrison).
Heights and places from the class probe (probes/<world>_classes.txt: OTFLOORS, OTBPOS). A run replaces only its own:
the guards flagged "garrison" and the "post" sandbags; everything else (the user's objects, towers, hides) stays.

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

PER_MAN = 150.0
# Where a man stands on a tower (model x, y, height above its base), the first the lookout
TOWER_POSTS = {"Land_BagBunker_Tower_F": [(0.0, -2.0, 2.75)],
               "Land_Cargo_Patrol_V1_F": [(-2.3, 0.8, 4.44), (-2.0, -1.2, 4.14)]}
BUNKER_POSTS = [(0.9, -1.2, 0.09), (-0.9, -1.2, 0.09)]   # Land_BagBunker_Small_F's firing places, its slit model -y
PATROL = ["rifleman", "autorifleman", "rifleman", "rifleman"]
RESERVE = ["rifleman", "autorifleman", "rifleman", "at", "rifleman", "marksman"]
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
    def __init__(self, block, poly, tier, items, places, town=""):
        self.b, self.poly, self.tier, self.town = block, [tuple(p[:2]) for p in poly], tier, town
        self.coverage = None
        # A run replaces only its own: the "garrison" guards and the "post" sandbags on roof posts
        self.items = [list(it) for it in items if not (it[0] == "guard" and "garrison" in it[4]) and "post" not in str(it[4]).split(",")]
        self.places = places
        self.count = round(area(self.poly) / PER_MAN)
        self.centre = (sum(p[0] for p in self.poly) / len(self.poly), sum(p[1] for p in self.poly) / len(self.poly))
        self.e = gg.Entrances(block, poly, tier, self.items, "")
        # The gates' vehicle lanes (10 m in) and their way out, kept clear of men standing
        self.lanes = []
        for g in [it for it in self.items if it[0] == "gate"]:
            gp, u = gg.vec(g[2])[:2], cg.norm(gg.vdir(g[3])[:2])
            n = (-u[1], u[0])
            if not cg.inside(cg.add(gp, n), self.poly):
                n = (u[1], -u[0])
            self.lanes.append(gg.tg.rect(cg.add(gp, cg.mul(n, 5.0)), n, (max(float(g[1]), 4.0) + 1.5, 11.0)))
        self.men = []
        self.notes = []

    def room(self):
        return self.count - len(self.men) - sum(1 for it in self.items if it[0] == "static")

    def man(self, role, p, z, facing, flags):
        if self.room() <= 0:
            return False
        # Not on another man's spot (the HQ's places serve its windows and a window lookout)
        if any(math.dist(p, gg.vec(m[2])[:2]) < 0.8 and abs(z - gg.vec(m[2])[2]) < 1.5 for m in self.men):
            return False
        # Nor on a static weapon's (an HMG up a tower takes its autorifleman's place)
        if any(math.dist(p, gg.vec(it[2])[:2]) < 1.0 and abs(z - gg.vec(it[2])[2]) < 1.5 for it in self.items if it[0] == "static"):
            return False
        self.men.append(["guard", role, f"[{p[0]:.3f},{p[1]:.3f},{z:.3f}]", f"{facing:.1f}", ",".join(["garrison"] + flags)])
        return True

    def ground_man(self, role, origin, cands, facing_to=None, flags=()):
        taken = [gg.vec(m[2])[:2] for m in self.men]
        best = None
        for c in cands:
            if any(math.dist(c, t) < 1.5 for t in taken) or not self.e.free(c, (0, 1), MAN, pad=0.3, lanes=self.lanes):
                continue
            key = math.dist(c, origin)
            if best is None or key < best[0]:
                best = (key, c)
        if not best:
            return False
        c = best[1]
        face = heading(c, facing_to) if facing_to else heading(self.centre, c)
        return self.man(role, c, self.b.ground(*c), face, ["ground"] + list(flags))

    def main_door(self):
        """The HQ's main door (the town probe's), world x, y; the HQ's middle when not probed."""
        import townlib
        try:
            t = townlib.load()[self.town]
            d = t.door("main")
            if d:
                return tuple(d["pos"][:2])
        except Exception:
            pass
        return tuple(self.b.pos[:2])

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
        # 1b. A window lookout for each tower the compound had no room for: a marksman at the upper place nearest
        # the area's line, in a building on the area (other than the HQ first)
        planned = {3: 1, 4: 2, 5: 3}.get(self.tier, 0)
        built = sum(1 for it in self.items if it[0] == "object" and "lookout" in it[4])
        if built < planned:
            taken = set()
            options = []
            for t in self.b.buildings:
                # On the area (the HQ always: a line along a street can cut its box's corners off)
                if sum(cg.inside(c, self.poly) for c in t.corners()) < 2 and math.dist(t.pos[:2], self.b.pos[:2]) >= 1:
                    continue
                cls = t.model if t.model in self.places else "Land_" + t.model
                for x, y, h in self.places.get(cls, []):
                    if h < 2.0:
                        continue
                    p = t.to_world(x, y)
                    if not cg.inside(p, self.poly):
                        continue
                    is_hq = math.dist(t.pos[:2], self.b.pos[:2]) < 1
                    options.append(((is_hq, self.e.edge_dist(p)), p, t.pos[2] + h, id(t)))
            options.sort(key=lambda o: o[0])
            for _ in range(planned - built):
                pick = next((o for o in options if o[3] not in taken), None)
                if not pick:
                    break
                taken.add(pick[3])
                if self.man("marksman", pick[1], pick[2], heading(self.centre, pick[1]), []):
                    note("window lookout marksman")
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
                # Where his line to the gate's opening is clear of the wall's pieces (not pressed against the T4
                # gate's stub)
                rects = [gg.tg.piece_rect(it) for it in self.items if it[0] == "object" and "gate" not in it[1].lower() and gg.is_wall(it[1])]
                cands = [c for c in (cg.add(cg.add(gp, cg.mul(u, a)), cg.mul(n, i)) for a in (-6, -5, -4, -3, 3, 4, 5, 6) for i in (2, 3, 4, 5))
                         if not any(gg.tg.overlap([c, cg.add(gp, cg.mul(n, 0.5)), cg.add(gp, cg.mul(n, 0.6)), cg.add(c, (0.05, 0.05))], r) for r in rects)]
                # Facing the gate's opening (beside it, straight out is the wall)
                if self.ground_man("autorifleman", cg.add(gp, cg.mul(n, 3)), cands, cg.add(gp, cg.mul(n, -6))):
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
        # 4b. A man in each fighting hole outside the main gate (props_gen.py's, "hole"): behind its sandbags (their
        # curve model -y faces out, model +y in), facing out
        for it in [it for it in self.items if it[0] == "object" and "hole" in it[4]]:
            pos, vd = gg.vec(it[2]), cg.norm(gg.vdir(it[3])[:2])
            p = cg.add(pos[:2], cg.mul(vd, 1.0))
            if self.man("rifleman", p, self.b.ground(*p), heading(p, cg.sub(p, vd)), ["ground"]):
                note("fighting hole rifleman")
        # 5. Elevated posts until the walls are overlooked (overlook.py: an approach band 6-20 m out, seen from
        # within 50 m): the towers and the men already up (window lookouts) first, then the roof and upper-floor
        # spot adding most, each earning its man with 10 m (5 samples) of wall more; a flat-roof post gets a short
        # sandbag ring piece at its edge ("post")
        room = self.room() - (len(PATROL) if self.tier >= 4 else 0)
        if room > 0:
            import overlook
            st = overlook.Study(self.town, self.tier, self.items, self.b, self.poly)
            seeds = [(gg.vec(m[2])[0], gg.vec(m[2])[1], gg.vec(m[2])[2] + overlook.EYE) for m in self.men if gg.vec(m[2])[2] - self.b.ground(*gg.vec(m[2])[:2]) > 2.0]
            S, C, towers, chosen, covered, reach = st.solve(seeds=seeds, room=room)
            self.coverage = (len(covered), len(st.need), len(reach))
            for ci in chosen:
                lab, eye, own, kind = C[ci]
                seen = [S[si][1][0] for si in st.seen[ci] if S[si][1]]
                look = (sum(t[0] for t in seen) / len(seen), sum(t[1] for t in seen) / len(seen)) if seen else self.centre
                p, z = (eye[0], eye[1]), eye[2] - overlook.EYE
                face = heading(p, look)
                if self.man("rifleman", p, z, face, ["elevated"]):
                    note("elevated " + kind)
                    if kind == "roof":
                        d = cg.norm(cg.sub(look, p))
                        q = cg.add(p, cg.mul(d, 0.9))
                        self.items.append(["object", "Land_BagFence_Short_F", f"[{q[0]:.3f},{q[1]:.3f},{z:.3f}]", gg.orient_dir(d), "post"])
        # 6. The patrol fireteam (T4) just inside the main gate, beside its lane
        if main and self.tier >= 4 and self.room() >= len(PATROL):
            cands = [cg.add(cg.add(gp, cg.mul(u, a)), cg.mul(n, i)) for a in (-6, -5, -4, -3, 3, 4, 5, 6) for i in (6, 7, 8, 9, 10, 11, 12)]
            for role in PATROL:
                if self.ground_man(role, cg.add(gp, cg.mul(n, 9)), cands, None, ["patrol"]):
                    note("patrol " + role)
        # 7. All the men left are the reserve: a loose group 4-8 m out from the HQ's main door, facing out (they hunt
        # inside the walls on the alarm, OT_fnc_officeGarrison)
        door = self.main_door()
        out = cg.norm(cg.sub(door, hq)) if math.dist(door, hq) > 0.5 else (0.0, 1.0)
        ring = []
        # In front of the door first (within 80 degrees of straight out), then round it, then out to 16 m where the
        # ground near the door is taken (a crowded yard)
        for r, span in [(r, 80) for r in (4.0, 5.0, 6.0, 7.0, 8.0)] + [(r, 180) for r in (4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0)]:
            for a in range(-span, span + 1, 15):
                d = (out[0] * math.cos(math.radians(a)) - out[1] * math.sin(math.radians(a)), out[0] * math.sin(math.radians(a)) + out[1] * math.cos(math.radians(a)))
                ring.append(cg.add(door, cg.mul(d, r)))
        ring = [c for c in ring if cg.inside(c, self.poly)]
        # Free ground for a man: off the buildings' real walls (a box takes in porches and yards: at Chalkeia it left
        # two spots), the pieces and the lanes, level enough
        import overlook
        st = overlook.Study(self.town, self.tier, self.items, self.b, self.poly)
        pieces = [gg.tg.piece_rect(it) for it in self.items if it[0] in ("object", "static", "vehicle")]

        office = min(self.b.buildings, key=lambda t: math.dist(t.pos[:2], hq))

        def open_ground(c):
            # Not in the HQ's box (its door opens on its porch: the plan alone let men stand inside it, Paros), nor
            # in another building's real walls
            if cg.inside(c, office.corners()) or any(st.in_bld(c, t) for t in st.blds if cg.inside(c, t.corners())):
                return False
            box = gg.tg.rect(c, (0, 1), (MAN[0] + 0.6, MAN[1] + 0.6))
            if any(gg.tg.overlap(box, q) for q in pieces + self.lanes):
                return False
            zs = [self.b.ground(*q) for q in box]
            return max(zs) - min(zs) < 0.8
        ring = [c for c in ring if open_ground(c)]
        while self.room() > 0:
            role = RESERVE[len([m for m in self.men if "reserve" in m[4]]) % len(RESERVE)]
            taken = [gg.vec(m[2])[:2] for m in self.men]
            cands = [c for c in ring if all(math.dist(c, t) >= 1.5 for t in taken)]
            if not cands:
                break
            c = min(cands, key=lambda q: math.dist(q, door))   # Nearest the door
            if not self.man(role, c, self.b.ground(*c), heading(c, cg.add(door, cg.mul(out, 30))), ["ground", "reserve"]):
                break
            note("reserve " + role)
        statics = sum(1 for it in self.items if it[0] == "static")
        self.notes.append(f"{len(self.men)} men + {statics} static crew of {self.count} (one per {PER_MAN:.0f} m2): " +
                          ", ".join(f"{v} {k}" for k, v in placed.items()) +
                          (f"; walls overlooked {self.coverage[0]} of {self.coverage[1]} samples ({self.coverage[2]} coverable)" if self.coverage else ""))
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
        g = Garrison(block, areas[tier], tier, t["tiers"][tier], places, town)
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
