"""
Drafting a town's mayor's office layout away from the game, from the town probe (the "townprobe" QA survey's
OTTOWN lines, kept in tools/officegen/probes/<world>_towns.txt). A draft is the same thing the layout editor
saves: per tier, a full snapshot of everything standing there (tier N includes all of tier N-1), in world
coordinates (ASL). write() puts it in tools/officegen/layouts/drafts/<town>.txt as OTLAYOUT lines;
python tools/officegen/merge_layouts.py <that file> merges it into the mod's layouts, and the layout editor then
opens the town in its review, where it's checked and fixed by hand.

Coordinates: Town.to_world(x, y, z) takes the office's MODEL coordinates (x right, y forward out of the model's
front, as the templates in functions/offices/templates use them; z above the model origin) and gives world ASL.
Directions are compass degrees; a model-relative direction d is world direction town.dir + d.
z=None puts a thing on the ground (and flags it "ground", so the game puts it on the terrain exactly).

Usage (from the repository root):
    python tools/officegen/townlib.py extract [rpt]      the newest RPT's OTTOWN lines into the probe file
    python tools/officegen/townlib.py list               the probed towns
    python tools/officegen/townlib.py show <town>        a town's probe summary and an ASCII map
    python tools/officegen/townlib.py reference          the hand-made Aggelochori layout in its office's model coordinates
    python tools/officegen/townlib.py check <draft file> checks a written draft
"""
import ast
import glob
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROBES = os.path.join(ROOT, "tools", "officegen", "probes")
DRAFTS = os.path.join(ROOT, "tools", "officegen", "layouts", "drafts")
TEMPLATES = os.path.join(ROOT, "addons", "overthrow_main", "functions", "offices", "templates")
SAVED = os.path.join(ROOT, "tools", "officegen", "layouts")

# Classes a draft may use (vanilla and its free platform data, so every player has them): [length across (model x),
# depth (model y)] in metres, for the collision checks. Static weapons go by role, not class (static()).
CLASSES = {
    "Land_BagFence_Short_F": (1.5, 0.45), "Land_BagFence_Long_F": (2.9, 0.45), "Land_BagFence_Round_F": (1.9, 1.0),
    "Land_BagFence_Corner_F": (1.8, 1.8), "Land_BagFence_End_F": (0.6, 0.45),
    "Land_HBarrier_1_F": (1.56, 1.56), "Land_HBarrier_3_F": (3.6, 1.76), "Land_HBarrier_5_F": (6.0, 1.76),
    "Land_HBarrier_Big_F": (8.4, 2.4), "Land_HBarrierWall4_F": (4.5, 2.0), "Land_HBarrierWall6_F": (6.5, 2.0),
    "Land_HBarrierWall_corner_F": (2.5, 2.5),
    "Land_Razorwire_F": (7.6, 1.0), "Land_CzechHedgehog_01_F": (2.0, 2.0),
    "Land_CncBarrier_F": (1.6, 0.6), "Land_CncBarrier_stripes_F": (2.6, 0.6), "Land_CncBarrierMedium_F": (4.0, 0.6),
    "Land_CncBarrierMedium4_F": (8.0, 0.6),
    "Land_Mil_WallBig_4m_F": (4.0, 0.6), "Land_Mil_WallBig_Corner_F": (1.0, 1.0),
    "Land_CncWall4_F": (4.0, 1.0), "Land_CncWall1_F": (1.4, 1.0),  # CncWall4 a guess; CncWall1 measured (pass 1)
    "Land_WallCity_01_gate_grey_F": (5.0, 0.6), "Land_BarGate_F": (5.0, 0.6),
    "Land_PipeFence_03_m_gate_r_F": (4.0, 0.3), "Land_GameProofFence_01_l_gate_F": (4.0, 0.3),  # The gates used at Aggelochori
    "Land_BagBunker_Small_F": (3.2, 3.0), "Land_BagBunker_Tower_F": (3.5, 3.5),
    "Land_TableDesk_F": (1.6, 0.9), "Land_OfficeChair_01_F": (0.6, 0.6), "Land_MapBoard_F": (1.6, 0.3),
    "Land_OfficeCabinet_01_F": (0.9, 0.5), "Land_CampingTable_F": (1.2, 0.6), "Land_CampingChair_V2_F": (0.6, 0.6),
    "Land_PortableLongRangeRadio_F": (0.5, 0.3), "Land_PortableLight_single_F": (0.6, 0.6),
    "Flag_NATO_F": (0.3, 0.3),
}
# Real bounding boxes measured in the game ([length, depth, height] m, boundingBoxReal, an UPPER bound: it takes in
# a gate's raised arm or swing and some slack), from the layout check's OTCLASS lines
MEASURED = {
    "Land_BagFence_Long_F": (3.1, 0.5, 0.9), "Land_BagFence_Round_F": (2.9, 1.1, 0.9), "Land_BagFence_Short_F": (2.0, 0.5, 0.9),
    "Land_BarGate_F": (9.7, 0.5, 8.8), "Land_CncBarrier_F": (2.6, 0.4, 0.8), "Land_CzechHedgehog_01_F": (1.8, 1.8, 1.4),
    "Land_HBarrierWall6_F": (8.5, 4.9, 3.7), "Land_HBarrier_1_F": (1.4, 1.7, 1.5), "Land_HBarrier_3_F": (3.6, 1.8, 1.6),
    "Land_HBarrier_5_F": (5.8, 1.7, 1.6), "Land_Mil_WallBig_4m_F": (4.1, 1.1, 4.7), "Land_Razorwire_F": (8.5, 2.1, 2.1),
    "Land_WallCity_01_gate_grey_F": (4.6, 4.3, 4.3), "Land_PipeFence_03_m_gate_r_F": (3.3, 5.1, 2.4),
    "Land_GameProofFence_01_l_gate_F": (1.5, 3.0, 2.8), "Land_TableDesk_F": (1.8, 0.9, 0.8), "Land_MapBoard_F": (1.5, 1.0, 2.0),
    "Flag_NATO_F": (0.4, 1.2, 8.3),
    "static gmg (B_GMG_01_high_F)": (1.6, 2.3, 3.4), "static at (B_static_AT_F)": (1.0, 2.3, 2.0), "static mortar (B_Mortar_01_F)": (2.5, 1.9, 1.7),
}
STATIC_ROLES = ("hmg", "gmg", "at", "aa", "mortar")
# Barrier pieces may overlap each other, the neighbours and their walls a little, so a line is one unbroken wall:
# the checks only look at their middle (BARRIER_OVERLAP m off each end, half their depth)
BARRIERS = ("Wall", "Fence", "HBarrier", "Barrier", "Gate", "Razorwire", "BagFence", "Cnc", "Hedgehog")
BARRIER_OVERLAP = 0.6


def is_barrier(cls):
    return any(b in cls for b in BARRIERS)
# Fewest guards a tier may hold once a draft has any (the walls and gates passes have none)
MIN_GUARDS = 2
GUARD_ROLES = ("gendarme", "rifleman", "autorifleman", "marksman", "at", "mg_gunner", "officer")


def _vec(s):
    return [float(x) for x in s.strip("[]").split(",") if x != ""]


def rot(x, y, d):
    """(x, y) turned clockwise by d degrees (Arma's compass)."""
    t = math.radians(d)
    return (x * math.cos(t) + y * math.sin(t), y * math.cos(t) - x * math.sin(t))


def template(key):
    """A building's generated template: [tier 1 items, ..., tier 5 items], each [kind, what, [x, y, z], dir, extra]."""
    path = os.path.join(TEMPLATES, f"fn_officeTpl_{key}.sqf")
    text = open(path, encoding="utf-8").read()
    text = text[text.index("*/") + 2:]
    text = re.sub(r"//[^\n]*", "", text)
    return ast.literal_eval(text.strip().rstrip(";"))


class Town:
    def __init__(self, name):
        self.name = name
        self.doors, self.bpos, self.objs, self.roads, self.rows = [], [], [], [], {}
        self.reach = 45  # How far round the office the probe reached (more round a big office: REACH)

    # ---- set up from the probe
    def finish(self):
        n = len(self.rows)
        self.grid = [self.rows[j] for j in range(n)]
        # The model origin: the template's doorway markers were logged at modelToWorld, so the origin is a logged
        # door minus its turned model position (getPosASL can sit off the model origin, mostly in height)
        self.origin = list(self.pos)
        try:
            tpl = template(self.key)
            marks = [it for t in tpl for it in t if it[0] == "doorway"]
            if marks and self.doors:
                m, d = marks[0], self.doors[0]
                dx, dy = rot(m[2][0], m[2][1], self.dir)
                self.origin = [d["pos"][0] - dx, d["pos"][1] - dy, d["pos"][2] - m[2][2]]
        except (OSError, ValueError, SyntaxError):
            pass
        # The office's floors: its building positions' heights (model z), merged within 1 m
        zs = sorted(p[2] - self.origin[2] for p in self.bpos)
        self.floors = []
        for z in zs:
            if not self.floors or z - self.floors[-1][-1] > 1.0:
                self.floors.append([z])
            else:
                self.floors[-1].append(z)
        self.floors = [round(sum(f) / len(f), 2) for f in self.floors]

    # ---- coordinates
    def to_world(self, x, y, z=None):
        """Model coordinates to world ASL; z None: on the ground there."""
        dx, dy = rot(x, y, self.dir)
        wx, wy = self.origin[0] + dx, self.origin[1] + dy
        wz = self.ground(wx, wy) if z is None else self.origin[2] + z
        return [wx, wy, wz]

    def to_model(self, p):
        dx, dy = rot(p[0] - self.origin[0], p[1] - self.origin[1], -self.dir)
        return [dx, dy, p[2] - self.origin[2]]

    def ground(self, wx, wy):
        """The terrain's height (ASL) at a world point, from the probe's 2 m grid (its edge beyond the reach)."""
        n = len(self.grid)
        half = (n - 1) // 2
        fi = (wx - self.pos[0]) / 2 + half
        fj = (wy - self.pos[1]) / 2 + half
        fi, fj = min(max(fi, 0), n - 1), min(max(fj, 0), n - 1)
        i0, j0 = min(int(fi), n - 2), min(int(fj), n - 2)
        ti, tj = fi - i0, fj - j0
        g = self.grid
        a = g[j0][i0] * (1 - ti) + g[j0][i0 + 1] * ti
        b = g[j0 + 1][i0] * (1 - ti) + g[j0 + 1][i0 + 1] * ti
        return a * (1 - tj) + b * tj

    def ground_model(self, x, y):
        """The ground's height at a model point, in model z (above the origin)."""
        w = self.to_world(x, y, 0)
        return self.ground(w[0], w[1]) - self.origin[2]

    def door(self, role="main"):
        """A doorway: {"pos": world, "model": model coords, "dir": outward model direction, "width"}; None without."""
        for d in self.doors:
            if d["role"] == role:
                return dict(d, model=self.to_model(d["pos"]), mdir=(d["dir"] - self.dir) % 360)
        return None

    # ---- what's there
    def inside_office(self, x, y, margin=0.0):
        """Within the office's bounding box (coarse: it takes in porches and roof overhangs)."""
        b = self.box
        return b[0] - margin <= x <= b[2] + margin and b[1] - margin <= y <= b[3] + margin

    def plan(self):
        """The office's ground floor plan from the building probe (tools/officegen/probe_offices.txt, 1 m cells in
        model coordinates): an officegen_lib.Building, None when the class isn't there."""
        if not hasattr(self, "_plan"):
            sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
            import officegen_lib
            self._plan = officegen_lib.parse_probe(os.path.join(ROOT, "tools", "officegen", "probe_offices.txt")).get("Land_" + self.key)
        return self._plan

    def on_office(self, x, y, length=0.5, depth=0.5, mdir=0.0):
        """Whether a footprint at model (x, y), turned to model direction mdir, stands on the office's ground floor
        or its walls (the probe's plan; the bounding box without one)."""
        b = self.plan()
        cx, cy = rot(1, 0, mdir), rot(0, 1, mdir)
        hl, hd = max(length / 2 - 0.5, 0), max(depth / 2 - 0.5, 0)  # The plan's cells are a metre: half a cell of give
        pts = [(x + sx * hl * cx[0] + sy * hd * cy[0], y + sx * hl * cx[1] + sy * hd * cy[1]) for sx in (-1, 0, 1) for sy in (-1, 0, 1)]
        if b is None:
            return any(self.inside_office(px, py, -0.5) for px, py in pts)
        level = min(b.levels)
        sky = b.opensky.get(level, set())

        def solid(px, py):
            c = b.cell(level, px, py)
            return c == "#" or (c == "." and (int(round(px)), int(round(py))) not in sky)  # Open-air floor (a porch) is outside
        return any(solid(px, py) for px, py in pts)

    def _footprints(self):
        if not hasattr(self, "_fp"):
            self._fp = []
            for o in self.objs:
                b = o["box"]
                if o["kind"] in ("tree", "rock"):
                    b = [max(b[0], -0.6), max(b[1], -0.6), min(b[2], 0.6), min(b[3], 0.6)] if o["kind"] == "tree" else b
                self._fp.append((o, b))
        return self._fp

    def hits(self, wx, wy, length=0.6, depth=0.6, yaw=0.0, pad=0.1, removed=()):
        """The probed things (buildings, walls, trees, rocks, the office's other pieces) a footprint of this size,
        centred on a world point and turned to a world yaw, overlaps: [(kind, model name, distance)]. Not the ones
        in removed (map objects a tier hides: removed_objs)."""
        out = []
        cx, cy = rot(1, 0, yaw), rot(0, 1, yaw)
        corners = [(wx + sx * length / 2 * cx[0] + sy * depth / 2 * cy[0], wy + sx * length / 2 * cx[1] + sy * depth / 2 * cy[1]) for sx in (-1, 1) for sy in (-1, 1)] + [(wx, wy)]
        for o, b in self._footprints():
            if any(o is r for r in removed):
                continue
            for px, py in corners:
                lx, ly = rot(px - o["pos"][0], py - o["pos"][1], -o["dir"])
                if b[0] - pad <= lx <= b[2] + pad and b[1] - pad <= ly <= b[3] + pad:
                    out.append((o["kind"], o["model"], round(math.hypot(wx - o["pos"][0], wy - o["pos"][1]), 1)))
                    break
        return out

    def removed_objs(self, items):
        """The probed objects a tier's "hide" items remove (the nearest within a metre of each)."""
        out = []
        for it in items:
            if it[0] != "hide":
                continue
            near = sorted(self.objs, key=lambda o: math.hypot(o["pos"][0] - it[2][0], o["pos"][1] - it[2][1]))
            if near and math.hypot(near[0]["pos"][0] - it[2][0], near[0]["pos"][1] - it[2][1]) <= 1.0:
                out.append(near[0])
        return out

    def roads_near(self, wx, wy, r=60):
        """Road segments by distance from a world point: [(distance, segment)], segment {"type", "width", "beg", "end"}."""
        out = []
        for s in self.roads:
            ax, ay = s["beg"][0], s["beg"][1]
            bx, by = s["end"][0], s["end"][1]
            vx, vy = bx - ax, by - ay
            t = max(0, min(1, ((wx - ax) * vx + (wy - ay) * vy) / (vx * vx + vy * vy or 1)))
            d = math.hypot(ax + t * vx - wx, ay + t * vy - wy)
            if d <= r:
                out.append((round(d, 1), s))
        return sorted(out, key=lambda x: x[0])

    def on_road(self, wx, wy):
        return any(d <= s["width"] / 2 + 0.5 for d, s in self.roads_near(wx, wy, 15))


def extract(rpt=None, world="Altis"):
    if rpt is None:
        rpt = max(glob.glob(os.path.join(os.environ.get("LOCALAPPDATA", ""), "Arma 3", "*.rpt")), key=os.path.getmtime)
    lines = []
    for line in open(rpt, encoding="utf-8", errors="replace"):
        m = re.search(r'"(OTTOWN\|.*)"\s*$', line)
        if m:
            lines.append(m.group(1))
    os.makedirs(PROBES, exist_ok=True)
    path = os.path.join(PROBES, f"{world}_towns.txt")
    old = open(path, encoding="utf-8").read().splitlines() if os.path.exists(path) else []
    new_towns = {l.split("|")[1] for l in lines}
    keep = [l for l in old if l.split("|")[1] not in new_towns]
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(keep + lines) + "\n")
    print(f"{len(new_towns)} towns from {rpt} -> {os.path.relpath(path, ROOT)}")


def load(world="Altis"):
    towns = {}
    for line in open(os.path.join(PROBES, f"{world}_towns.txt"), encoding="utf-8"):
        f = line.rstrip("\n").split("|")
        if len(f) < 3 or f[0] != "OTTOWN":
            continue
        name, what = f[1], f[2]
        t = towns.setdefault(name, Town(name))
        if what == "HEAD":
            t.key, t.cls, t.pos, t.dir = f[3], f[4], _vec(f[5]), float(f[6])
            t.spawned, t.population, t.bracket, t.cap = f[7] == "true", int(f[8]), int(f[9]), int(f[10])
        elif what == "BOX":
            t.box = _vec(f[3])
        elif what == "REACH":
            t.reach = float(f[3])
        elif what == "DOOR":
            t.doors.append({"role": f[3], "pos": _vec(f[4]), "dir": float(f[5]), "width": float(f[6])})
        elif what == "BPOS":
            t.bpos += [_vec(p) for p in re.findall(r"\[[^\[\]]+\]", f[3])]
        elif what == "OBJ":
            t.objs.append({"kind": f[3], "model": f[4], "pos": _vec(f[5]), "dir": float(f[6]), "box": _vec(f[7])})
        elif what == "ROAD":
            t.roads.append({"type": f[3], "width": float(f[4]), "beg": _vec(f[5]), "end": _vec(f[6])})
        elif what == "H":
            t.rows[int(f[3])] = _vec(f[4])
    for t in towns.values():
        if hasattr(t, "key"):
            t.finish()
    return {n: t for n, t in towns.items() if hasattr(t, "key")}


# ---- items (what a snapshot holds)

def _up_dir(yaw):
    return [[round(math.sin(math.radians(yaw)), 4), round(math.cos(math.radians(yaw)), 4), 0.0], [0.0, 0.0, 1.0]]


def guard(town, role, x, y, z=None, mdir=0.0):
    """A guard at model (x, y), on the ground (z None) or standing on model height z (a floor: town.floors), facing
    model direction mdir."""
    assert role in GUARD_ROLES, role
    return ["guard", role, town.to_world(x, y, z), (town.dir + mdir) % 360, ["ground"] if z is None else []]


def obj(town, cls, x, y, z=None, mdir=0.0, flag=False):
    """A prop or fortification at model (x, y), on the ground (z None) or dropped onto what's under model height z
    (a floor, a table), turned to model direction mdir."""
    assert cls in CLASSES, cls
    extra = (["ground"] if z is None else ["drop"]) + (["flag"] if flag else [])
    return ["object", cls, town.to_world(x, y, z), _up_dir((town.dir + mdir) % 360), extra]


def static(town, role, x, y, z=None, mdir=0.0):
    """A static weapon by role ("hmg", "gmg", "at", "aa", "mortar"), crewed in play, facing model direction mdir."""
    assert role in STATIC_ROLES, role
    return ["static", role, town.to_world(x, y, z), _up_dir((town.dir + mdir) % 360), ["ground"] if z is None else []]


def hide(town, x, y, kinds=("wall", "tree", "rock", "building")):
    """A map object removed at the tier (a fence, a low wall, a shed, a tree in the way): the probed object of those
    kinds nearest model (x, y), within 2 m. The game hides it (OT_fnc_officeHide); check() treats it as gone. It stays
    removed at every tier above this one too (OT_fnc_officeHide)."""
    w = town.to_world(x, y, 0)
    near = sorted((o for o in town.objs if o["kind"] in kinds), key=lambda o: math.hypot(o["pos"][0] - w[0], o["pos"][1] - w[1]))
    assert near and math.hypot(near[0]["pos"][0] - w[0], near[0]["pos"][1] - w[1]) <= 2.0, f"no map object within 2 m of model {(x, y)}"
    o = near[0]
    return ["hide", o["model"], list(o["pos"]), _up_dir(o["dir"]), []]


def gate(town, x, y, width, mdir=0.0):
    """A gate's opening in the walls at model (x, y), width metres across, the line it's cut in running along model
    direction mdir. A marker: nothing stands for it in the game (pass 2b gives the gate its look); the in-game check
    counts a way out through it as meant and any other as a gap. Cut the gap itself by leaving the pieces out."""
    return ["gate", f"{width:.1f}", town.to_world(x, y, 0), _up_dir((town.dir + mdir) % 360), []]


def baseline(town, world="Altis"):
    """The town's reviewed layout (tools/officegen/layouts/<world>.txt, as the user left it in the editor): its
    tiers as full snapshots, [tier 1 items, ...] up to its highest saved tier, each item [kind, what, [x, y, z] ASL,
    orientation, extra] like the drafting helpers' (guard orientation a direction, others [vectorDir, vectorUp]).
    Build the next pass on these; never regenerate what the user reviewed."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import merge_layouts
    t = merge_layouts.load_saved(world)[town.name if hasattr(town, "name") else town]
    top = max(t["tiers"]) if t["tiers"] else 0
    out = []
    for n in range(1, top + 1):
        items = []
        for kind, what, p, o, extra in t["tiers"].get(n, []):
            items.append([kind, what, _vec(p), float(o) if kind == "guard" else ast.literal_eval(o), [e for e in extra.split(",") if e]])
        out.append(items)
    return out


def from_template(town, tier):
    """The generated template's additions for a tier on this office (doorway markers left out): outside things on
    the ground, inside ones on their floor."""
    out = []
    for kind, what, p, d, extra in template(town.key)[tier - 1]:
        if kind == "doorway":
            continue
        z = None if "outside" in extra else p[2]
        if kind == "guard":
            out.append(guard(town, what, p[0], p[1], z, d))
        else:
            out.append(obj(town, what, p[0], p[1], z, d, flag="flag" in extra) if what in CLASSES else
                       ["object", what, town.to_world(p[0], p[1], z), _up_dir((town.dir + d) % 360), (["ground"] if z is None else ["drop"]) + (["flag"] if "flag" in extra else [])])
    return out


# ---- checks and writing

def _same(a, b):
    return a[0] == b[0] and a[1] == b[1] and math.dist(a[2], b[2]) < 0.05


def check(town, tiers):
    """Problems with a drafted layout: [text]. Empty is good."""
    problems = []
    if len(tiers) != town.cap:
        problems.append(f"{len(tiers)} tiers, the town has {town.cap}")
    # A tier may drop pieces of the tier below (the user, pass 1): full snapshots, not "tier N-1 plus more"
    garrisoned = any(it[0] == "guard" for items in tiers for it in items)  # Pass 1 (walls) has no guards at all
    for n, items in enumerate(tiers, 1):
        guards = sum(1 for it in items if it[0] == "guard")
        if garrisoned and guards < MIN_GUARDS:
            problems.append(f"tier {n}: {guards} guards")
        removed = town.removed_objs([it for lower in tiers[:n] for it in lower])  # A tier's removals hold above it too
        if sum(1 for it in items if it[0] == "hide") > len(town.removed_objs(items)):
            problems.append(f"tier {n}: {sum(1 for it in items if it[0] == 'hide') - len(removed)} hide items with no probed object within a metre")
        for it in items:
            kind, what, p, o, extra = it
            if kind in ("hide", "gate"):
                continue
            if what == "Land_HBarrier_Big_F":
                problems.append(f"tier {n}: Land_HBarrier_Big_F (AI soldiers walk through it): stack an HBarrier_5 and an HBarrier_3 instead (tools/officegen/swap_big.py)")
            m = town.to_model(p)
            dist = math.hypot(m[0], m[1])
            if dist > town.reach + 1:
                problems.append(f"tier {n}: {what} {dist:.0f} m out (the probe reaches {town.reach:.0f} m)")
            on_tower = kind == "guard" and any(t[0] == "object" and ("Tower" in t[1] or "Cargo" in t[1]) and math.hypot(t[2][0] - p[0], t[2][1] - p[1]) < 2.5 for t in items)
            if kind == "guard" and "ground" not in extra and not on_tower and not town.inside_office(m[0], m[1], 1.0):
                problems.append(f"tier {n}: guard {what} off the ground outside the office at {[round(v, 1) for v in m]}")
            if "ground" not in extra:
                continue  # On a floor of the office (dropped onto it in the game)
            size = CLASSES.get(what, (0.6, 0.6)) if kind == "object" else ((2.0, 2.0) if kind == "static" else (0.5, 0.5))
            if kind == "object" and is_barrier(what):
                size = (max(size[0] - 2 * BARRIER_OVERLAP, 0.2), max(size[1] * 0.5, 0.2))
            yaw = (o if kind == "guard" else math.degrees(math.atan2(o[0][0], o[0][1]))) % 360
            # An office of several pieces (Kavala's hospital): its parts' boxes and its plan reach well past the real
            # building (open ground under the helipad block), so the in-game clip check judges pieces near it
            composite = any(o["kind"] == "part" for o in town.objs)
            hit = [h for h in town.hits(p[0], p[1], size[0], size[1], yaw, removed=removed) if h[0] in (("building", "rock") if composite else ("building", "part", "rock")) or (h[0] == "wall" and kind != "object")]
            if not composite and town.on_office(m[0], m[1], size[0], size[1], (yaw - town.dir) % 360):
                hit.append(("office", town.cls, 0))
            if hit:
                problems.append(f"tier {n}: {kind} {what} at model {[round(v, 1) for v in m[:2]]} overlaps {hit[:2]}")
    return problems


def write(town, tiers):
    """The draft (full snapshots, tier 1 first) as OTLAYOUT lines in tools/officegen/layouts/drafts/<town>.txt;
    returns the path. Checked first: raises with the problems."""
    problems = check(town, tiers)
    if problems:
        raise ValueError(f"{town.name}: " + "; ".join(problems))
    f3 = lambda v: "[" + ",".join(f"{x:.3f}" for x in v) + "]"
    f4 = lambda v: "[" + ",".join(f"{x:.4f}" for x in v) + "]"
    office_pos = town.pos
    lines = [f"OTLAYOUT|Altis|{town.name}|OFFICE|{town.cls}|{f3(office_pos)}|{town.dir:.2f}|{'true' if town.spawned else 'false'}"]
    for n, items in enumerate(tiers, 1):
        lines.append(f"OTLAYOUT|Altis|{town.name}|TIER|{n}|{len(items)}")
        for kind, what, p, o, extra in items:
            orient = f"{o:.1f}" if kind == "guard" else "[" + f4(o[0]) + "," + f4(o[1]) + "]"
            lines.append(f"OTLAYOUT|Altis|{town.name}|ITEM|{n}|{kind}|{what}|{f3(p)}|{orient}|{','.join(extra)}")
    os.makedirs(DRAFTS, exist_ok=True)
    path = os.path.join(DRAFTS, f"{town.name}.txt")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    return path


def reference(world="Altis", town="Aggelochori"):
    """A hand-made layout in its office's model coordinates (z above the office's getPosASL): {tier: [(kind, what,
    x, y, z, model direction)]}."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import merge_layouts
    t = merge_layouts.load_saved(world)[town]
    cls, pos, d, _ = t["office"]
    pos, d = _vec(pos), float(d)
    out = {}
    for n, items in sorted(t["tiers"].items()):
        rows = []
        for kind, what, p, o, extra in items:
            p = _vec(p)
            x, y = rot(p[0] - pos[0], p[1] - pos[1], -d)
            if kind == "guard":
                yaw = float(o)
            else:
                v = ast.literal_eval(o)[0]
                yaw = math.degrees(math.atan2(v[0], v[1]))
            rows.append((kind, what, round(x, 1), round(y, 1), round(p[2] - pos[2], 1), round((yaw - d) % 360)))
        out[n] = rows
    return cls, out


def ascii_map(town, items=(), r=40, step=2):
    """A top-down map in model coordinates (up = the office's front, +y): O office, # building, = wall, t tree,
    : road, and the items' first letters (x a map object removed, shown gone)."""
    rows = []
    marks = {}
    for kind, what, p, o, extra in items:
        m = town.to_model(p)
        marks[(round(m[0] / step), round(m[1] / step))] = {"guard": "g", "static": "S", "hide": "x", "gate": "G"}.get(kind, "o")
    removed = town.removed_objs(items)
    for j in range(r // step, -r // step - 1, -1):
        row = ""
        for i in range(-r // step, r // step + 1):
            x, y = i * step, j * step
            w = town.to_world(x, y, 0)
            c = "."
            if town.on_road(w[0], w[1]):
                c = ":"
            hit = town.hits(w[0], w[1], 0.2, 0.2, 0, 0, removed=removed)
            if hit:
                c = {"building": "#", "wall": "=", "tree": "t", "rock": "r", "part": "O"}.get(hit[0][0], "?")
            if town.inside_office(x, y):
                c = "O"
            c = marks.get((i, j), c)
            row += c
        rows.append(row)
    return "\n".join(rows)


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a:
        print(__doc__)
    elif a[0] == "extract":
        extract(a[1] if len(a) > 1 else None)
    elif a[0] == "list":
        for n, t in sorted(load().items()):
            print(f"{n:22} {t.cls:32} pop {t.population:4} B{t.bracket} tiers {t.cap} spawned {t.spawned} doors {[d['role'] for d in t.doors]} roads {len(t.roads)} objs {len(t.objs)}")
    elif a[0] == "show":
        t = load()[a[1]]
        print(f"{t.name}: {t.cls} ({t.key}) pop {t.population} B{t.bracket} tiers {t.cap} spawned {t.spawned}")
        print(f"  office dir {t.dir}, model box {t.box}, floors (model z) {t.floors}")
        for role in ("main", "back", "side"):
            d = t.door(role)
            if d:
                print(f"  door {role}: model {[round(v, 1) for v in d['model']]} outward {d['mdir']:.0f} width {d['width']}")
        print(f"  ground at the origin {t.ground_model(0, 0):.2f} (model z); roads within 30 m: {[(d, s['type'], s['width']) for d, s in t.roads_near(t.origin[0], t.origin[1], 30)][:6]}")
        print(ascii_map(t))
    elif a[0] == "reference":
        cls, tiers = reference()
        print(f"Aggelochori, office {cls}, model coordinates (x right, y front, z above the office position, direction relative):")
        for n, rows in tiers.items():
            print(f"tier {n}: {len(rows)} things")
            for r in rows:
                print("   ", r)
    elif a[0] == "check":
        print("not wired: use townlib.check(town, tiers) from the drafting script")
