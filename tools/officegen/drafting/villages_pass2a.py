"""
Mayor's office layouts, group "villages" (Overthrow CE), pass 2a: where the gates go
(tools/officegen/review/villages/PASS2A_GATES.md). Every town starts from the user's reviewed tiers (tl.baseline), and
only its tier 3 ring changes: pieces taken out (or swapped for a shorter one) to cut one opening, and a tl.gate()
marker at the opening's middle. Villages top out at tier 3, so the T3 ring is the only one with a gate. Towns with no
ring (Abdera, Agios Konstantinos, Galati, Nifi, Topolia) need nothing and aren't written. Run from the repository root:
    python tools/officegen/drafting/villages_pass2a.py [--map] [town ...]
Writes tools/officegen/layouts/drafts/<town>.txt (tl.write checks them first) and prints, per town, the cut and the
closure audit: a flood fill for a man (villages.closed_audit) with the gate open must find a way out only at the gate,
and with the gate plugged none at all. --map prints the tier 3 on a 1 m map (model coordinates, up = the office's
front).

Coordinates are the office's model coordinates (x right, y forward of the house). The house is Land_House_Big_02 in
every town: walls x -5.3..5.3, y -5.9..5.8, the main door on the back porch's west end (-4.7, -6.2) facing -x, the
porch open to the back (-y), the front door (0.1, 5.3) facing +y.

Gate markers: tl.gate(town, x, y, width, mdir), mdir the direction the cut line runs along (90 for a line along model
x, 0 for one along model y), as the docstring has it.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import townlib as tl  # noqa: E402
import villages as v  # noqa: E402

TIER = 3  # The ring that gets the gate (villages top out at 3)

# Per town: "remove" [(class, x, y)]: ring pieces taken out (the baseline piece of that class nearest model (x, y),
# within 0.3 m); "add" [(class, x, y, mdir)]: the shorter pieces that re-fit the line's end at the opening (on the
# ground, 0.3-0.45 m into the piece they butt against); "gates" [(x, y, width, line mdir)]; "faces": what the gate
# faces and why there (the report's words). Widths are the nominal opening between the pieces' ends (townlib's
# lengths); the game's measured boxes run up to 0.3 m longer at a 2-high piece's end (HBarrier_Big 9.0 m, not 8.4).
CUTS = {
    # Back notch on the street (the track at y -16.5 runs along the back, 3 m off the line, and meets the track down
    # the east side at (14, -17)). The notch's west HBarrier_5 comes out: the opening runs from the notch's west side
    # line (HBarrier_3 at x -6.9, its east face -6.0) to the next HBarrier_5's end (-2.5), straight before the porch
    # and the main door at its west end
    "Alikampos": {
        "remove": [("Land_HBarrier_5_F", -4.9, -13.5)],
        "add": [],
        "gates": [(-4.26, -13.5, 3.5, 90)],
        "faces": "the street along the back (track at y -16.5, 3 m off), before the back porch and the main door",
    },
    # Front line on the track at y 15 (the village's through road, west to east, meeting the east track at the
    # north-east corner): the 2-high piece before the front door comes out, an HBarrier_3 re-fits the west side
    # (0.3 m into the HBarrier_1 at -4.6), the 2-high piece at 7.7 is the east jamb
    "Dorida": {
        "remove": [("Land_HBarrier_Big_F", -0.2, 10.3)],
        "add": [("Land_HBarrier_3_F", -2.4, 10.3, 0)],
        "gates": [(1.45, 10.5, 4.1, 90)],
        "faces": "the track along the front (y 15), straight before the front door",
    },
    # Cramped site: the main road curves round the west (x -39) and the way from it comes in over the open ground at
    # the front-left (y 13-19). The front line's west 2-high piece comes out and an HBarrier_3 re-fits the corner over
    # the left line's end; the opening leads into the strip down the house's west side to the main door
    "Gravia": {
        "remove": [("Land_HBarrier_Big_F", -5.7, 11.2)],
        "add": [("Land_HBarrier_3_F", -7.95, 11.2, 0)],
        "gates": [(-4.08, 11.2, 4.2, 90)],
        "faces": "the open ground at the front-left, the way in from the main road on the west; leads down the house's west side to the main door",
    },
    # The road (missing from the probe) runs along the back, the back line standing on its west half (the top view),
    # the branch east at the north end. The 2-high piece before the porch comes out, an HBarrier_3 re-fits the west
    # side (0.3 m into the 2-high piece at -12.7); the opening faces the back porch and the main door at its west end
    "Kore": {
        "remove": [("Land_HBarrier_Big_F", -4.8, -14.0)],
        "add": [("Land_HBarrier_3_F", -7.0, -14.0, 0)],
        "gates": [(-3.1, -14.0, 4.2, 90)],
        "faces": "the road along the back (the back line stands on its edge), before the back porch and the main door",
    },
    # The track behind (y -17 to -22, from the east and on to the south-west). The 2-high piece before the porch comes
    # out, an HBarrier_3 re-fits the east side (0.3 m into the HBarrier_3 at 6.8)
    "Lakka": {
        "remove": [("Land_HBarrier_Big_F", 1.3, -14.0)],
        "add": [("Land_HBarrier_3_F", 3.5, -14.0, 0)],
        "gates": [(-0.4, -14.0, 4.2, 90)],
        "faces": "the track behind the house (y -17..-22), before the back porch",
    },
    # The user's own layout: the smallest cut. The only track is the one along the front (y 20). Behind the front
    # line's west 2-high piece stood a full city wall (city_8m, y 11.1, x -11.6..-4.6) leaving only a 2.2 m slot to the
    # addon (its walls x -2.4..4.3), too narrow for the game's path finding. The user's call (round 2): that city wall
    # is hidden from tier 3 (tiers 1 and 2 keep it). The west 2-high piece gives way to an HBarrier_3 from the corner;
    # the opening (x -7.1..-2.9) leads straight into the yard on the house's west side and to the main door, clear of
    # the addon and of the palm at (-8.8, 10.8)
    "Neri": {
        "remove": [("Land_HBarrier_Big_F", -6.7, 13.2)],
        "add": [("Land_HBarrier_3_F", -8.9, 13.2, 0)],
        "hide": [(-8.1, 11.1)],
        "gates": [(-5.0, 13.2, 4.2, 90)],
        "faces": "the track along the front (y 20); into the yard on the house's west side (the city wall behind the line hidden)",
    },
    # The track down the right side (x 12.5) runs along the right line's outer face. The line beside the house leaves
    # only a 2 m strip, so the opening goes in behind the house: the right line's back 2-high piece comes out, an
    # HBarrier_3 re-fits it from the north (0.45 m into the 2-high piece at -0.4) and an HBarrier_1 closes the corner
    # over the back line's end; the opening leads into the back yard before the porch
    "Poliakko": {
        "remove": [("Land_HBarrier_Big_F", 7.3, -8.4)],
        "add": [("Land_HBarrier_3_F", 7.3, -5.95, 90), ("Land_HBarrier_1_F", 7.3, -11.95, 90)],
        "gates": [(7.3, -9.5, 3.5, 0)],
        "faces": "the track down the right side (x 12.5, its edge at the line), into the back yard before the porch",
    },
    # The track runs along the back notch (its centre at y -14.5 there). The notch's west HBarrier_5 comes out: the
    # opening runs from the notch's west side line (HBarrier_1s at x -5.4) to the HBarrier_3's end (-1.0)
    "Selakano": {
        "remove": [("Land_HBarrier_5_F", -3.4, -13.5)],
        "add": [],
        "gates": [(-2.81, -13.5, 3.6, 90)],
        "faces": "the track along the back notch, before the back porch and the main door",
    },
    # The plaza's track crosses behind the back notch (its centre at y -13.6 at x -3). The notch's west HBarrier_5 comes
    # out: the opening runs from the notch's west side line (HBarrier_3 at x -5.4) to the HBarrier_3's end (-1.0)
    "Stavros": {
        "remove": [("Land_HBarrier_5_F", -3.4, -13.5)],
        "add": [],
        "gates": [(-2.76, -13.5, 3.5, 90)],
        "faces": "the plaza's track along the back notch, before the back porch and the main door",
    },
    # The track along the front (y 12.5, the line on its edge). The left neighbour fills the front-left, so the opening
    # goes before the front door: the 2-high piece there comes out, an HBarrier_3 re-fits the west side (0.3 m into the
    # HBarrier_3 at -6.1), the 2-high piece at 7.5 is the east jamb
    "Telos": {
        "remove": [("Land_HBarrier_Big_F", -0.4, 8.7)],
        "add": [("Land_HBarrier_3_F", -2.8, 8.7, 0)],
        "gates": [(1.15, 8.7, 4.3, 90)],
        "faces": "the track along the front (y 12.5), straight before the front door",
    },
}


def model(t, it):
    return t.to_model(it[2])


def mdir(t, it):
    o = it[3]
    return (math.degrees(math.atan2(o[0][0], o[0][1])) - t.dir) % 360


def cut(t, items, cfg):
    """The tier's items with the cut made: (items, removed, added, gates)."""
    items = list(items)
    removed = []
    for cls, x, y in cfg["remove"]:
        near = sorted((it for it in items if it[0] == "object" and it[1] == cls), key=lambda it: math.hypot(model(t, it)[0] - x, model(t, it)[1] - y))
        assert near and math.hypot(model(t, near[0])[0] - x, model(t, near[0])[1] - y) < 0.3, f"{t.name}: no {cls} at {(x, y)}"
        items.remove(near[0])
        removed.append(near[0])
    added = [tl.obj(t, cls, x, y, None, d) for cls, x, y, d in cfg["add"]]
    gates = [tl.gate(t, x, y, w, d) for x, y, w, d in cfg["gates"]]
    hides = [tl.hide(t, x, y, ("wall",)) for x, y in cfg.get("hide", ())]
    return items + added + hides + gates, removed, added, gates


def site(t, items):
    """A villages.Site over these items (the tier as its one snapshot), for the closure and clip audits: every
    H-barrier counts as a ring piece (the user's saved pieces carry no "ground" flag), the map objects the tier hides
    are gone, and the outline is the ring's own extent."""
    gone = t.removed_objs(items)
    objs = t.objs
    t.objs = [o for o in objs if not any(o is g for g in gone)]
    pieces = [model(t, it) for it in items if it[0] == "object" and "HBarrier" in it[1]]
    cfg = dict(v.TOWNS[t.name])
    cfg.pop("poly", None)
    cfg["ring"] = (min(p[0] for p in pieces), max(p[0] for p in pieces), min(p[1] for p in pieces), max(p[1] for p in pieces))
    try:
        s = v.Site(t, cfg)
    finally:
        t.objs = objs
    s.tiers = [items]
    return s


v.is_piece = lambda it: it[0] == "object" and "HBarrier" in it[1]

# Where a man leaves the house: the back porch (the main door at its west end, the house door, its open back edge) and
# the foot of the front steps. Pass 1's closed_audit started from every cell within 1 m of the house, which puts the
# start outside the ring where a line ties into the house's own corners (Stavros' right side, the slot between the
# house's east wall, which has no door, and its neighbour)
DOORS = [(-5.6, -6.2), (-4.7, -6.9), (-2.9, -6.9), (-1.0, -6.9), (0.8, -6.9), (0.1, 7.4)]


def closed_audit(s, cell=0.125, man=0.24):
    """villages.closed_audit (a flood fill for a man 0.48 m across, his shoulders grown onto the H-barriers, the real
    barriers and the house) started from the house's doors (DOORS), not from all round it. Returns where he crosses
    the ring's outline: [(x, y)], one per way out (each plugged with a 1.5 m disc before looking for the next)."""
    x0, x1, y0, y1 = v.bounds(s.cfg)
    reach = max(abs(x0), abs(x1), abs(y0), abs(y1)) + 5.0
    n = int(2 * reach / cell)
    idx = lambda q: int(round((q + reach) / cell))
    blocked = bytearray(n * n)
    shapes = [r for _, r in s.closers] + [s.OFFICE]
    shapes += [s.corners(it, spacing=True) for it in s.snapshots()[-1] if v.is_piece(it)]
    for r in shapes:
        xs, ys = [p[0] for p in r], [p[1] for p in r]
        poly = [r[0], r[1], r[3], r[2]]
        for i in range(max(idx(min(xs) - man - cell), 0), min(idx(max(xs) + man + cell), n - 1) + 1):
            for j in range(max(idx(min(ys) - man - cell), 0), min(idx(max(ys) + man + cell), n - 1) + 1):
                if v.poly_dist((i * cell - reach, j * cell - reach), poly) <= man:
                    blocked[j * n + i] = 1
    starts = [(i, j) for dx, dy in DOORS for i in range(idx(dx - 1.0), idx(dx + 1.0) + 1) for j in range(idx(dy - 1.0), idx(dy + 1.0) + 1)
              if not blocked[j * n + i] and math.hypot(i * cell - reach - dx, j * cell - reach - dy) <= 1.0]
    holes = []
    for _ in range(6):
        prev = {st: None for st in starts}
        todo = list(prev)
        out, k = None, 0
        while k < len(todo):
            i, j = todo[k]
            k += 1
            x, y = i * cell - reach, j * cell - reach
            if not (x0 - 3 <= x <= x1 + 3 and y0 - 3 <= y <= y1 + 3):
                out = (i, j)
                break
            for a, b in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                if 0 <= a < n and 0 <= b < n and (a, b) not in prev and not blocked[b * n + a]:
                    prev[(a, b)] = (i, j)
                    todo.append((a, b))
        if out is None:
            break
        p, hole = out, None
        while p is not None:
            x, y = p[0] * cell - reach, p[1] * cell - reach
            if x0 - 0.5 <= x <= x1 + 0.5 and y0 - 0.5 <= y <= y1 + 0.5:
                hole = (round(x, 1), round(y, 1))
                break
            p = prev[p]
        hole = hole or (round(out[0] * cell - reach, 1), round(out[1] * cell - reach, 1))
        holes.append(hole)
        hi, hj, r = idx(hole[0]), idx(hole[1]), int(1.5 / cell)
        for a in range(hi - r, hi + r + 1):
            for b in range(hj - r, hj + r + 1):
                if 0 <= a < n and 0 <= b < n and math.hypot(a - hi, b - hj) <= r:
                    blocked[b * n + a] = 1
    return holes


def closure(t, items, cfg):
    """(ways out with the gate open, ways out with it plugged): each [(x, y)]. Meant: every way out with it open within
    its half width + 1.5 m of a gate (the game's test allows 1 m round the marker, the flood fill's crossing point
    is a cell or two off), none with it plugged."""
    s = site(t, items)
    open_ = closed_audit(s)
    plugs = []
    for x, y, w, d in cfg["gates"]:
        # A plug across the opening: a 2-high piece along the line, longer than the gap
        plugs.append(tl.obj(t, "Land_HBarrier_Big_F", x, y, None, (d - 90) % 360))
    s.tiers = [items + plugs]
    shut = closed_audit(s)
    return open_, shut


def meant(cfg, holes):
    return [h for h in holes if any(math.hypot(h[0] - x, h[1] - y) <= w / 2 + 1.5 for x, y, w, d in cfg["gates"])]


def build(name):
    t = tl.load()[name]
    tiers = tl.baseline(t)
    cfg = CUTS[name]
    out = [list(items) for items in tiers]
    removed = added = gates = []
    for n in range(TIER, len(tiers) + 1):  # The tier with the ring and any above it (none for the villages)
        out[n - 1], removed, added, gates = cut(t, tiers[n - 1], cfg)
    return t, tiers, out, removed, added


def audit(t, tiers, out, removed, added, cfg):
    lines = []
    items = out[TIER - 1]
    for it in removed:
        m = model(t, it)
        lines.append(f"   removed {it[1][5:-2]} at ({m[0]:.1f}, {m[1]:.1f}) dir {mdir(t, it):.0f}")
    for it in added:
        m = model(t, it)
        lines.append(f"   added   {it[1][5:-2]} at ({m[0]:.2f}, {m[1]:.2f}) dir {mdir(t, it):.0f}")
    for x, y in cfg.get("hide", ()):
        lines.append(f"   hidden  the map wall nearest ({x}, {y})")
    for x, y, w, d in cfg["gates"]:
        lines.append(f"   gate at ({x}, {y}), {w} m, line along {d}: {cfg['faces']}")
    s = site(t, items)
    for it in added:
        h = s.game_rays(it)
        if h:
            m = model(t, it)
            lines.append(f"   CLIP {it[1]} at ({m[0]:.1f}, {m[1]:.1f}) into {h}")
    for c in v.overlap_audit(s):
        if any(f"({model(t, a)[0]:.1f},{model(t, a)[1]:.1f})" in c for a in added):
            lines.append("   OVERLAP " + c)
    base = closed_audit(site(t, tiers[TIER - 1]))
    lines.append("   baseline (before the cut): " + ("closed" if not base else f"OPEN at {base}"))
    open_, shut = closure(t, items, cfg)
    good = meant(cfg, open_)
    bad = [h for h in open_ if h not in good]
    lines.append(f"   closure: gate open, ways out {open_} ({len(good)} through the gate, {len(bad)} not); gate plugged: "
                 + ("closed" if not shut else f"OPEN at {shut}"))
    ok = bool(good) and not bad and not shut
    lines.append("   " + ("OK: only meant ways out" if ok else "PROBLEM"))
    return lines, ok


def write(t, tiers, out):
    """tl.write, which checks first. Problems let through: only those the user's baseline already has (Alikampos: a
    "hide" of a plastic table, a prop the probe doesn't list; Neri: the user's tier 1 police post has 2 guards, so
    check() wants guards on tiers 2 and 3 too). Anything new still raises."""
    known = set(tl.check(t, tiers))
    problems = [p for p in tl.check(t, out) if p not in known]
    if problems:
        raise ValueError(f"{t.name}: " + "; ".join(problems))
    check = tl.check
    tl.check = lambda town, tiers: []
    try:
        return tl.write(t, out), sorted(known)
    finally:
        tl.check = check


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    for name in (args or CUTS):
        t, tiers, out, removed, added = build(name)
        lines, ok = audit(t, tiers, out, removed, added, CUTS[name])
        path, known = write(t, tiers, out)
        lines += [f"   kept from the baseline: {k}" for k in known]
        print(f"{name}: T{TIER} {len(tiers[TIER - 1])} -> {len(out[TIER - 1])} items; {os.path.relpath(path, tl.ROOT)}")
        print("\n".join(lines))
        if "--map" in sys.argv:
            s = site(t, out[TIER - 1])
            print(v.show(s, 26))
