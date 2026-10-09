"""
Design study (troop placement, checkpoint 1): which elevated posts overlook a compound's walls, and how many men
that takes at 1 man per 150 m2. Offline, from the block probe (buildings, their boxes and heights, the ground),
the class probe (OTBPOS places, OTFLOORS roofs) and the layout (wall pieces, towers, gates).

A wall stretch is OVERLOOKED when every sample along it (every 2 m of the tier's line where a wall piece or gate
stands) has an elevated man within RANGE m whose eye sees a man standing 3 m outside the wall (1.2 m up): the
segment from eye to target clears the ground (the 3 m grid), every wall piece (its footprint below its top) and
every building (its box below its top), the man's own building only within 2.5 m of him (he stands at an opening).

Elevated candidates: tower platforms (the layout's lookouts); buildings inside the area or on its line: their
buildingPos places 2 m or more up (OTBPOS), and flat roof cells 2.5 m or more up at a roof's edge (OTFLOORS,
complete lines only: a cell whose neighbours are within 0.3 m, next to a cell that drops 2 m or more).

    python tools/officegen/overlook.py [--svg Town tier]
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import compound_gen as cg  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402
import townlib  # noqa: E402

RANGE = 50.0
STEP = 2.0
OUT = 10.0
BAND = (6.0, 10.0, 15.0, 20.0)   # The approach outside a wall sample: open ground this far out
TARGET_H = 1.6
EYE = 1.6
TOP = {"HBarrier": 3.0, "Mil_WallBig": 4.7, "CncWall": 1.2, "ConcreteWall_01_l_gate": 3.0, "NetFence_01_m_gate": 2.6}
PER_MAN = 150.0
MIN_GAIN = 5          # A post must overlook at least this many more samples (10 m of wall) to be worth a man (the user's)
ROOT = merge_layouts.ROOT


def places():
    out, floors = {}, {}
    for line in open(os.path.join(ROOT, "tools", "officegen", "probes", "Altis_classes.txt"), encoding="utf-8"):
        f = line.rstrip().split("|")
        if f[0] == "OTBPOS":
            out[f[1]] = [[float(v) for v in p.split(",")] for p in re.findall(r"\[([^\[\]]+)\]", f[2])]
        elif f[0] == "OTFLOORS" and f[2].endswith("]]]"):
            c = floors.setdefault(f[1], {})
            for x, y, hs in re.findall(r"\[(-?\d+),(-?\d+),\[([^\]]*)\]\]", f[2]):
                c[(int(x), int(y))] = [float(h) for h in hs.split(",") if h]
    return out, floors


def norm_cls(m):
    m = m if m.startswith("Land_") else "Land_" + m
    return [m, re.sub(r"_V\d+_F$", "_V1_F", m), m.replace("Land_u_", "Land_i_"), re.sub(r"_V\d+_F$", "_V1_F", m.replace("Land_u_", "Land_i_"))]


def vec(s):
    return [float(v) for v in str(s).strip("[]").split(",")]


class Study:
    def __init__(self, town, tier, items=None, block=None, poly=None):
        self.b = block or blocklib.load()[town]
        self.town, self.tier = town, tier
        self.poly = [tuple(p[:2]) for p in (poly or merge_compounds.load_saved("Altis")[town]["tiers"][tier])]
        self.items = items if items is not None else merge_layouts.load_saved("Altis")[town]["tiers"][tier]
        self.places, self.floors = places()
        hid = [vec(it[2])[:2] for it in self.items if it[0] == "hide"]
        self.blds = [t for t in self.b.buildings if all(math.dist(t.pos[:2], h) > 0.5 for h in hid)
                     and min(math.dist(c, q) for c in t.corners() for q in self.poly) < 60]
        self.walls = []
        for it in self.items:
            if it[0] != "object":
                continue
            key = next((k for k in TOP if k in it[1]), None)
            if key is None:
                continue
            p = vec(it[2])
            vd = vec(str(it[3]).split("],[")[0])
            size = (townlib.MEASURED.get(it[1]) or townlib.CLASSES.get(it[1]) or ((10.6, 0.6) if "l_gate" in it[1] else (4.1, 0.3)))
            rect = cg_rect(p[:2], (vd[0], vd[1]), size[:2])
            self.walls.append((rect, p[2] + TOP[key] if p[2] - self.b.ground(*p[:2]) < 0.6 else p[2] + 1.6))
        self.area = abs(sum(self.poly[i][0] * self.poly[(i + 1) % len(self.poly)][1] - self.poly[(i + 1) % len(self.poly)][0] * self.poly[i][1] for i in range(len(self.poly)))) / 2

    def samples(self):
        """Points every STEP m along the line where a wall piece stands (within 2.2 m: an edge along a road is set up to
        1.8 m inside it), with their outward target."""
        out = []
        n = len(self.poly)
        for i in range(n):
            a, c = self.poly[i], self.poly[(i + 1) % n]
            L = math.dist(a, c)
            u = cg.norm(cg.sub(c, a))
            nrm = (u[1], -u[0])
            if cg.inside(cg.add(cg.add(a, cg.mul(u, L / 2)), nrm), self.poly):
                nrm = (-u[1], u[0])   # Outward
            k = 0.0
            while k <= L:
                p = cg.add(a, cg.mul(u, k))
                if any(cg.inside(p, r) or min(cg.seg_dist(p, r[j], r[(j + 1) % 4]) for j in range(4)) < 2.2 for r, _ in self.walls):
                    # The approach: a man standing on open ground 6 to 20 m out (none when buildings stand there)
                    tgts = []
                    for o in BAND:
                        t = cg.add(p, cg.mul(nrm, o))
                        if not any(self.in_bld(t, b2) for b2 in self.blds):
                            tgts.append((t[0], t[1], self.b.ground(*t) + TARGET_H))
                    out.append((p, tgts or None))
                k += STEP
        return out

    def candidates(self):
        """Elevated posts: [(label, (x, y, eye z ASL), own building or None, kind)]."""
        out = []
        for it in self.items:
            if it[0] == "object" and "lookout" in it[4]:
                p = vec(it[2])
                h = 4.44 if "Cargo" in it[1] else 2.75
                out.append(("tower", (p[0], p[1], p[2] + h + EYE), None, "tower"))
        for t in self.blds:
            cs = t.corners()
            on = sum(cg.inside(c, self.poly) for c in cs) >= 1 or any(cg.inside(q, cs) for q in self.poly)
            if not on:
                continue
            names = norm_cls(t.model)
            pl = next((self.places[k] for k in names if k in self.places), [])
            for x, y, h in pl:
                if h < 2.0:
                    continue
                w = t.to_world(x, y)
                if not self.on_area(w):
                    continue
                out.append((t.model, (w[0], w[1], t.pos[2] + h + EYE), t, self.upper_kind(t, names, x, y, h)))
            fl = next((self.floors[k] for k in names if k in self.floors), None)
            if fl:
                for (x, y), hs in fl.items():
                    top = max(hs)
                    if top < 2.5:
                        continue
                    nb = [fl.get((x + dx, y + dy)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                    flat = all(v is None or abs(max(v) - top) < 0.3 or max(v) < top - 2 for v in nb)
                    edge = any(v is None or max(v) < top - 2 for v in nb)
                    if flat and edge:
                        w = t.to_world(x, y)
                        if not self.on_area(w):
                            continue
                        out.append((t.model, (w[0], w[1], t.pos[2] + top + EYE), t, "roof"))
        return out

    def upper_kind(self, t, names, x, y, h):
        """An upper place's kind: "balcony" when the sky is open over it (no surface 1 m or more above it) and the
        building goes on higher elsewhere (2 m or more above it: a storey over a balcony or terrace), "roof" when
        open and nothing of the building is higher (its top), else "upper" (a room: a window).
        From the class probe's floors (every up-facing surface over the 1 m cell, OTFLOORS, complete lines only), else
        the office probe's plan (its open-sky cells at the storey nearest the place's height; the building higher
        when the box's top is 2.5 m or more above that storey); "upper" when neither."""
        fl = next((self.floors[k] for k in names if k in self.floors), None)
        if fl:
            hs = fl.get((int(round(x)), int(round(y))))
            if hs is None:
                return "upper"
            top = max(max(v) for v in fl.values())
            if any(z > h + 1.0 for z in hs):
                return "upper"
            return "balcony" if top > h + 2.0 else "roof"
        plan = cg.plan_of(t.model)
        if plan is not None and len(plan.levels) > 1:
            lv = sorted(plan.levels)
            level = min(lv, key=lambda z: abs((z - lv[0]) - h))
            if level == lv[0]:
                return "upper"
            open_sky = (int(round(x)), int(round(y))) in plan.opensky.get(level, set())
            if not open_sky:
                return "upper"
            # (the plans hold only the floors men stand on: the roof's ridge is the box's top)
            return "balcony" if t.box[5] > level + 2.5 else "roof"
        return "upper"

    def on_area(self, p):
        """Inside the area or on its line (within 1.5 m): a post in a building outside isn't the compound's."""
        n = len(self.poly)
        return cg.inside(p, self.poly) or min(cg.seg_dist(p, self.poly[i], self.poly[(i + 1) % n]) for i in range(n)) < 1.5

    def in_bld(self, xy, t):
        """Inside a building's real footprint (office plan, complete roofed cells), else its box."""
        if not cg.inside(xy, t.corners()):
            return False
        lx, ly = blocklib.rot(xy[0] - t.pos[0], xy[1] - t.pos[1], -t.dir)
        plan = cg.plan_of(t.model)
        if plan is not None:
            return plan.cell(min(plan.levels), lx, ly) in "#."  and plan.cell(min(plan.levels), lx, ly) != " "
        f = cg.footprint_of(t.model if t.model.startswith("Land_") else "Land_" + t.model)
        if f is not None and f[1] >= 999:
            return (int(round(lx)), int(round(ly))) in f[0]
        return True

    def sees(self, eye, targets, own):
        """Does he see any of the approach's points?"""
        return targets is None or any(self.sees1(eye, t, own) for t in targets)

    def sees1(self, eye, target, own):
        d = math.dist(eye[:2], target[:2])
        if d > RANGE or d < 1:
            return False
        steps = int(d / 0.5)
        for k in range(1, steps):
            f = k / steps
            x, y = eye[0] + (target[0] - eye[0]) * f, eye[1] + (target[1] - eye[1]) * f
            z = eye[2] + (target[2] - eye[2]) * f
            if z < self.b.ground(x, y) + 0.1:
                return False
            for r, top in self.walls:
                if z < top and cg.inside((x, y), r):
                    return False
            for t in self.blds:
                if t is own:
                    continue  # He looks out of a window or over the roof's edge
                if z < t.pos[2] + t.box[5] and self.in_bld((x, y), t):
                    return False
        return True

    def solve(self, seeds=(), room=None, min_gain=None):
        """The posts that overlook the walls: the towers (and seeds: eyes already manned) first, then greedily the
        candidate adding most, while it adds min_gain samples or more and men are left (room)."""
        min_gain = MIN_GAIN if min_gain is None else min_gain
        S = self.samples()
        # A man already up looks out of the building he stands in
        C = self.candidates() + [("seed", e, next((t for t in self.blds if cg.inside(e[:2], t.corners())), None), "tower") for e in seeds]
        need = {si for si, (p, tgt) in enumerate(S) if tgt is not None}
        cov = {}
        for ci, (lab, eye, own, kind) in enumerate(C):
            cov[ci] = {si for si in need if self.sees(eye, S[si][1], own)}
        self.seen = {ci: set(v) for ci, v in cov.items()}
        towers = [ci for ci, c in enumerate(C) if c[3] == "tower"]
        covered = set().union(*[cov[c] for c in towers]) if towers else set()
        chosen = []
        # Balconies (and windows, as before) first; a roof only where none of them gives the coverage (the user's)
        stage = {"balcony", "upper"}
        while True:
            best = max((ci for ci in cov if ci not in towers and ci not in chosen and C[ci][3] in stage), key=lambda ci: (len(cov[ci] - covered), -C[ci][1][2]), default=None)
            if best is None or len(cov[best] - covered) < min_gain or (room is not None and len(chosen) >= room):
                if "roof" not in stage and (room is None or len(chosen) < room):
                    stage = {"balcony", "upper", "roof"}
                    continue
                break
            chosen.append(best)
            covered |= cov[best]
            # Not two men on the same spot
            for ci in list(cov):
                if ci != best and math.dist(C[ci][1][:2], C[best][1][:2]) < 1.5:
                    cov[ci] = set()
        reachable = set().union(*cov.values()) if cov else set()
        self.need = need
        self.cov = cov
        return S, C, towers, chosen, covered, reachable


def cg_rect(c, vd, size):
    v = cg.norm(vd)
    ax = (v[1], -v[0])
    hx, hy = size[0] / 2, size[1] / 2
    return [cg.add(cg.add(c, cg.mul(ax, sx * hx)), cg.mul(v, sy * hy)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def row(town, tier):
    s = Study(town, tier)
    S, C, towers, chosen, covered, reach = s.solve()
    men = round(s.area / PER_MAN)
    tower_men = sum(1 if "Bag" in it[1] else 2 for it in s.items if it[0] == "object" and "lookout" in it[4])
    gate = 1 + sum(1 for it in s.items if it[0] == "static") + (1 if tier >= 4 else 0) + sum(1 for it in s.items if it[0] == "object" and "hole" in it[4])
    patrol = 4 if tier >= 4 else 0
    elevated = len(chosen)
    reserve = men - tower_men - gate - elevated - patrol
    return dict(town=town, tier=tier, area=round(s.area), men=men, towers=tower_men, gate=gate, elevated=elevated, patrol=patrol,
                reserve=reserve, samples=len(S), facing_buildings=len(S) - len(s.need), to_cover=len(s.need), covered=len(covered), coverable=len(reach), cands=len(C)), s, S, C, towers, chosen, covered


def svg(town, tier, path):
    r, s, S, C, towers, chosen, covered = row(town, tier)
    marks = {}
    for k, ci in enumerate(towers + chosen):
        lab, eye, own, kind = C[ci]
        marks[f"{kind}{k}"] = eye
    blocklib.svg(s.b, path, polygons={f"T{tier}": [list(p) for p in s.poly]}, reach=68, scale=8, pieces=s.items, marks=marks)
    txt = open(path, encoding="utf-8").read()
    P = lambda wx, wy: ((wx - s.b.pos[0] + 68) * 8, (68 - (wy - s.b.pos[1])) * 8)
    dots = []
    for si, (p, tgt) in enumerate(S):
        x, y = P(*p)
        col = "#9a9a9a" if tgt is None else ("#1e9e3a" if si in covered else "#d0021b")
        dots.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="{col}"/>')
    txt = txt.replace("</svg>", "\n".join(dots) + "\n</svg>")
    open(path, "w", encoding="utf-8").write(txt)
    return r


if __name__ == "__main__":
    if "--svg" in sys.argv:
        i = sys.argv.index("--svg")
        print(svg(sys.argv[i + 1], int(sys.argv[i + 2]), sys.argv[i + 3]))
        sys.exit()
    for town in ("Rodopoli", "Paros", "Chalkeia"):
        for tier in (3, 4):
            print(row(town, tier)[0])
