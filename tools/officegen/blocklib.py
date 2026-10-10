"""
The block probe's data (tools/officegen/probes/<world>_blocks.txt, the QA "blockprobe" survey's OTBLOCK lines) for
picking and building occupier compounds (tools/officegen/COMPOUND_PLAN.md), and a top-down map of a block as SVG.

    import blocklib as bl
    b = bl.load()["Rodopoli"]
    b.roads, b.buildings, b.walls, b.rocks, b.trees, b.ground(x, y)      world x, y; positions ASL
    bl.svg(b, "out.svg", polygons={"T3": [[x, y], ...]}, reach=90)

    python tools/officegen/blocklib.py "Town" [out.svg]   a map of the block
"""
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROBES = os.path.join(ROOT, "tools", "officegen", "probes")


def _vec(s):
    return [float(v) for v in s.strip("[]").split(",")] if s.strip("[]") else []


def rot(x, y, deg):
    """A vector turned clockwise by deg (Arma's directions)."""
    r = math.radians(deg)
    return x * math.cos(r) + y * math.sin(r), -x * math.sin(r) + y * math.cos(r)


class Thing:
    def __init__(self, model, pos, d, box):
        self.model, self.pos, self.dir, self.box = model, pos, d, box

    def to_world(self, x, y):
        dx, dy = rot(x, y, self.dir)
        return self.pos[0] + dx, self.pos[1] + dy

    def corners(self):
        """The box's corners (world x, y), round the box."""
        b = self.box
        return [self.to_world(x, y) for x, y in ((b[0], b[1]), (b[2], b[1]), (b[2], b[3]), (b[0], b[3]))]


class Building(Thing):
    def __init__(self, model, pos, d, box, doors, exits):
        super().__init__(model, pos, d, box)
        self.doors = doors  # model x, y
        self.exits = exits

    def door_points(self):
        # A building without door triggers (the Molos chapel): its ways in from the class probe (OTBEXIT), the
        # one nearest the building standing for its door
        doors = self.doors or exits().get(self.model, [])[:1]
        return [self.to_world(x, y) for x, y in doors]


_EXITS = None


def exits():
    """{class: [[model x, y], ...]} the class probe's buildingExit points (OTBEXIT), nearest the building first."""
    global _EXITS
    if _EXITS is None:
        _EXITS = {}
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "probes", "Altis_classes.txt")
        if os.path.exists(path):
            for line in open(path, encoding="utf-8"):
                f = line.rstrip().split("|")
                if f[0] == "OTBEXIT" and len(f) > 2:
                    _EXITS[f[1]] = json.loads(f[2])
    return _EXITS


class Block:
    def __init__(self, name):
        self.name = name
        self.roads, self.buildings, self.walls, self.rows = [], [], [], {}
        self.rocks, self.trees = [], []

    def finish(self):
        self.half = (len(self.rows) - 1) // 2

    def ground(self, wx, wy):
        """The ground (ASL) under a world point: bilinear in the 3 m grid round the office."""
        fx = (wx - self.pos[0]) / 3 + self.half
        fy = (wy - self.pos[1]) / 3 + self.half
        i, j = int(math.floor(fx)), int(math.floor(fy))
        i = max(0, min(2 * self.half - 1, i))
        j = max(0, min(2 * self.half - 1, j))
        tx, ty = fx - i, fy - j
        r0, r1 = self.rows[j], self.rows[j + 1]
        return (r0[i] * (1 - tx) + r0[i + 1] * tx) * (1 - ty) + (r1[i] * (1 - tx) + r1[i + 1] * tx) * ty

    def local(self, wx, wy):
        """World x, y as metres east and north of the office."""
        return wx - self.pos[0], wy - self.pos[1]


def load(world="Altis"):
    blocks = {}
    for line in open(os.path.join(PROBES, f"{world}_blocks.txt"), encoding="utf-8"):
        f = line.rstrip("\n").split("|")
        if len(f) < 3 or f[0] != "OTBLOCK":
            continue
        b = blocks.setdefault(f[1], Block(f[1]))
        what = f[2]
        if what == "HEAD":
            b.office, b.pos, b.dir, b.reach = f[3], _vec(f[4]), float(f[5]), float(f[6])
        elif what == "ROAD":
            b.roads.append({"type": f[3], "width": float(f[4]), "beg": _vec(f[5]), "end": _vec(f[6])})
        elif what == "BLD":
            doors = [_vec(p) for p in re.findall(r"\[[^\[\]]+\]", f[7])]
            b.buildings.append(Building(f[3], _vec(f[4]), float(f[5]), _vec(f[6]), doors, int(f[8])))
        elif what == "WALL":
            b.walls.append(Thing(f[3], _vec(f[4]), float(f[5]), _vec(f[6])))
        elif what in ("ROCK", "TREE"):
            (b.rocks if what == "ROCK" else b.trees).append(Thing(f[3], _vec(f[4]), float(f[5]), _vec(f[6])))
        elif what == "H":
            b.rows[int(f[3])] = _vec(f[4])
    for b in blocks.values():
        b.finish()
    return blocks


def svg(b, path, polygons=None, reach=90, scale=6, marks=None, pieces=None):
    """A top-down map of the block (north up, the office at the middle, a 10 m grid): roads grey, buildings with
    doors (red dots; buildings nobody can enter pale), walls and fences dark, rocks grey, trees green, the office blue, polygons (name ->
    world [x, y] list) drawn over in colour, marks (label -> world [x, y]) as labelled dots."""
    size = 2 * reach * scale
    P = lambda wx, wy: ((wx - b.pos[0] + reach) * scale, (reach - (wy - b.pos[1])) * scale)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}" font-family="sans-serif">',
           f'<rect width="{size}" height="{size}" fill="#eef0e6"/>']
    for k in range(-reach // 10 * 10, reach + 1, 10):
        x, _ = P(b.pos[0] + k, b.pos[1])
        _, y = P(b.pos[0], b.pos[1] + k)
        out.append(f'<line x1="{x}" y1="0" x2="{x}" y2="{size}" stroke="#d6d9cc" stroke-width="1"/>')
        out.append(f'<line x1="0" y1="{y}" x2="{size}" y2="{y}" stroke="#d6d9cc" stroke-width="1"/>')
    for r in b.roads:
        (x1, y1), (x2, y2) = P(*r["beg"][:2]), P(*r["end"][:2])
        out.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="#b9b4a8" stroke-width="{max(r["width"], 2) * scale:.1f}" stroke-linecap="round"/>')
    for t in b.buildings:
        pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in (P(*c) for c in t.corners()))
        office = math.dist(t.pos[:2], b.pos[:2]) < 1
        fill = "#7aa6d6" if office else ("#c9b79c" if t.exits else "#e0d8c8")
        out.append(f'<polygon points="{pts}" fill="{fill}" stroke="#7d6f5a" stroke-width="1"/>')
        for d in t.door_points():
            x, y = P(*d)
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{0.6 * scale:.1f}" fill="#c0392b"/>')
    for w in b.walls:
        c = w.corners()
        a, z = P(*((c[0][0] + c[3][0]) / 2, (c[0][1] + c[3][1]) / 2)), P(*((c[1][0] + c[2][0]) / 2, (c[1][1] + c[2][1]) / 2))
        out.append(f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{z[0]:.1f}" y2="{z[1]:.1f}" stroke="#3b3b3b" stroke-width="{0.6 * scale:.1f}"/>')
    for r in getattr(b, "rocks", []):
        pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in (P(*c) for c in r.corners()))
        out.append(f'<polygon points="{pts}" fill="#8a8f98" fill-opacity="0.55" stroke="#4b4f56" stroke-width="1"/>')
    for t in getattr(b, "trees", []):
        x, y = P(*t.pos[:2])
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{0.8 * scale:.1f}" fill="#3d8b3d" fill-opacity="0.8"/>')
    colours = ["#2e8b57", "#d4a017", "#c0392b", "#6a5acd"]
    for i, (name, poly) in enumerate((polygons or {}).items()):
        pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in (P(*p[:2]) for p in poly))
        col = colours[i % len(colours)]
        out.append(f'<polygon points="{pts}" fill="{col}" fill-opacity="0.12" stroke="{col}" stroke-width="3"/>')
        for k, p in enumerate(poly):
            x, y = P(*p[:2])
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="{col}"/><text x="{x + 7:.1f}" y="{y - 7:.1f}" font-size="14" fill="{col}">{name}.{k}</text>')
    # Layout items: walls and props as their footprints (stacked layers drawn once), gates green, hidden map
    # objects as crosses
    sizes = {"Land_HBarrier_5_F": (5.8, 1.7), "Land_HBarrier_3_F": (3.6, 1.7), "Land_HBarrier_1_F": (1.4, 1.5),
             "Land_Mil_WallBig_4m_F": (4.0, 0.6), "Land_CncWall1_F": (1.4, 1.0), "Land_NetFence_01_m_gate_F": (4.1, 0.3),
             "Land_Net_Fence_Gate_F": (6.2, 0.3), "Land_BagFence_Long_F": (2.9, 0.5), "Land_BagFence_Short_F": (1.5, 0.5),
             "Land_BagBunker_Tower_F": (6.4, 9.83), "Land_Cargo_Patrol_V1_F": (6.67, 6.8), "Land_Cargo_Tower_V1_F": (14.83, 13.48),
             "Land_ConcreteWall_01_l_gate_F": (10.61, 0.6), "Land_BagBunker_Small_F": (5.0, 5.69), "Land_LampShabby_F": (0.7, 0.8),
             "Land_PortableLight_double_F": (1.35, 1.02), "Land_Sign_WarningMilitaryArea_F": (2.09, 0.3),
             "Land_BagFence_Round_F": (2.86, 1.08), "Flag_NATO_F": (0.6, 0.6), "hmg": (1.6, 2.3)}
    seen = set()
    for it in (pieces or []):
        kind, cls, pos, ori = it[0], it[1], [float(v) for v in str(it[2]).strip("[]").split(",")], it[3]
        key = (cls, round(pos[0], 1), round(pos[1], 1))
        if key in seen:
            continue
        seen.add(key)
        if kind == "hide":
            x, y = P(*pos[:2])
            out.append(f'<path d="M{x - 6},{y - 6}L{x + 6},{y + 6}M{x - 6},{y + 6}L{x + 6},{y - 6}" stroke="#9b59b6" stroke-width="3"/>')
            continue
        if kind not in ("object", "static"):
            continue
        vd = [float(v) for v in str(ori).split("],[")[0].strip("[]").split(",")]
        ax = (vd[1], -vd[0])
        l, d = sizes.get(cls, (1.0, 1.0))
        pts = []
        for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            wx = pos[0] + ax[0] * sx * l / 2 + vd[0] * sy * d / 2
            wy = pos[1] + ax[1] * sx * l / 2 + vd[1] * sy * d / 2
            pts.append(P(wx, wy))
        fill = "#2ecc71" if "_gate" in cls.lower() else ("#e67e22" if "entrance" in str(it[4]) else ("#8e7d5a" if "HBarrier" in cls else "#555"))
        out.append(f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in pts)}" fill="{fill}" stroke="#222" stroke-width="0.6"/>')
    for label, p in (marks or {}).items():
        x, y = P(*p[:2])
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="6" fill="#111"/><text x="{x + 8:.1f}" y="{y + 5:.1f}" font-size="15" font-weight="bold">{label}</text>')
    out.append(f'<text x="10" y="24" font-size="20" font-weight="bold">{b.name}: north up, 10 m grid, office blue, doors red</text>')
    out.append("</svg>")
    open(path, "w", encoding="utf-8").write("\n".join(out))
    return path


if __name__ == "__main__":
    town = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "tools", "officegen", "compounds", f"{town}.svg")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    print(svg(load()[town], out))
