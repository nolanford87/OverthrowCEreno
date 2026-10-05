"""
Pass 2a for the strongholds (Kavala, Athira, Zaros): where the gates go, cut into the user's reviewed walls.
Run from the repository root:
    python tools/officegen/drafting/strongholds_pass2a.py [town ...] [--map N]
Each town starts from tl.baseline(town) (its tiers as the user left them in the editor: never regenerated), takes the
pieces out of a line where a gate goes, re-fits the line's ends at the opening, adds a tl.gate() marker at the gap's
middle, and writes tools/officegen/layouts/drafts/<town>.txt (tl.write checks it first). Then, per tier from 3, it
checks closure with strongholds.closure() (a 0.5 m man flooded from inside the office, every barrier on the ground):
  gates shut   each gate plugged by a wall across its opening: must be closed (no way out but the gates);
  gates open   must get out (a gate a man can't walk through is wrong too), and the way out must pass a gate.
Both are run twice: as pass 1 modelled the site (the neighbours the in-game walk crossed in pass 1, strongholds.SOFT,
taken as open ground) and with those taken as solid (as the user's edited rings rely on them). --map N prints tier N
with the way out (gates open) over the site.

Model coordinates throughout (x right, y forward of the office; "south" -y). The baseline's T3/T4 pieces in Kavala and
Zaros, and Athira's T5, were saved by the editor without their "ground" flag: they stand on the ground all the same,
and the closure check treats every barrier as on the ground.

The gates (the reasons in tools/officegen/review/strongholds/REPORT_pass2a.md):
  Kavala  T3/T4 inner: the forecourt line (x -11.4) opposite the main door (2.9, 16.4, facing west), 3.7 m;
          T5 inner the same in its Mil line, 3.2 m; T4/T5 outer: the west road's edge (x -41.6) at y 5.6, facing the
          main road's junction, 3.3 m, 10 m south of the inner gate and 30 m out. The west slope (the helipad block's
          west face) left as it is: no wall, no gate.
  Athira  (round 3) T3/T4 inner: the west line (x -6.8) onto the west lot, 3.9 m; T4/T5 outer: the south face at the
          west lot (x -10), 3.6 m, onto the lane south: 7 m from the inner gate and at right angles to it.
  Zaros   T3: the east line on the main road (x 13.2) opposite the side door (4.9, 5.6, facing east), 4.0 m; T4/T5
          (one ring, the user's): the east face on the road (x 15) at the same place, 3.1 m.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import townlib as tl  # noqa: E402
import strongholds as sh  # noqa: E402

HB1, HB3, HB5, MIL, LONG = sh.HB1, sh.HB3, sh.HB5, sh.MIL, sh.LONG

# Where the closure walk starts (inside the innermost ring): the lead's starts, but Kavala's T3 (the user's ring is the
# forecourt strip on the hospital's west side; the lead's start (13.1, -6.1) is east of the main strip, outside it)
STARTS = {"Kavala": {3: (-9.85, 9.0), 4: (13.1, -6.1), 5: (13.1, -6.1)},
          "Athira": {n: (-5.5, -6.6) for n in (3, 4, 5)},  # Round 3: inside the inner west gate, by the veranda (the
          # bare-site walk gets out from the west side only; (-3.3, -8.8) and the east side don't)
          "Zaros": {n: (-5.0, 2.5) for n in (3, 4, 5)}}
# With the hospital taken as solid, the lead's start is shut in east of the main strip: the main door's yard instead
SOLID_STARTS = {"Kavala": {n: (-9.85, 9.0) for n in (3, 4, 5)}}


class Town:
    """A town's baseline tiers, changed in place: pieces found by class and model (x, y), taken out, added."""

    def __init__(self, t):
        self.t = t
        self.tiers = tl.baseline(t)
        self.log = []

    def find(self, n, cls, x, y, tol=0.15):
        hits = [it for it in self.tiers[n - 1] if it[1] == cls and math.hypot(*(a - b for a, b in zip(self.t.to_model(it[2])[:2], (x, y)))) <= tol]
        assert len(hits) == 1, f"{self.t.name} T{n}: {len(hits)} {cls} at {(x, y)}"
        return hits[0]

    def out(self, n, cls, x, y, why):
        it = self.find(n, cls, x, y)
        self.tiers[n - 1] = [i for i in self.tiers[n - 1] if i is not it]
        self.log.append(f"T{n} out {cls} at ({x}, {y}): {why}")

    def add(self, n, cls, x, y, mdir, why):
        self.tiers[n - 1].append(tl.obj(self.t, cls, x, y, mdir=mdir))
        self.log.append(f"T{n} add {cls} at ({x}, {y}) facing {mdir}: {why}")

    def gate(self, n, x, y, width, run, what):
        """A gate's marker at the gap's middle; run: the line's direction (model)."""
        self.tiers[n - 1].append(tl.gate(self.t, x, y, width, run))
        self.log.append(f"T{n} GATE ({x}, {y}) {width:.1f} m: {what}")


def kavala(k):
    for n in (3, 4):
        # The forecourt line (HB5 at x -11.4, facing west, 5.31 m apart): the piece at y 15.49 out (12.59..18.39), an
        # HB1 back against the piece south of it (10.18, ends 13.08): 12.78..14.18; the opening 14.18..17.90 (the
        # piece at 20.80 starts at 17.90)
        k.out(n, HB5, -11.40, 15.49, "the forecourt line, the gate opposite the main door")
        k.add(n, HB1, -11.40, 13.48, 270, "re-fits the line's end south of the gate (0.3 m into the piece at y 10.18)")
        k.gate(n, -11.40, 16.04, 3.7, 0, "the forecourt line, facing the forecourt and the west road, opposite the main door (2.9, 16.4)")
    for n in (3, 4, 5):
        # The T2 bag along the main strip's face stands 1.4 m inside the opening, across it
        k.out(n, LONG, -8.90, 16.50, "the T2 bag 1.4 m behind the gate, across the way in")
    # T5: the same line in Mil walls (3.67 m apart, 4.1 long): the one at y 17.43 out, the opening 15.81..19.05
    k.out(5, MIL, -11.40, 17.43, "the T5 inner Mil line, at T4's inner gate")
    k.gate(5, -11.40, 17.43, 3.2, 0, "the T5 inner ring (Mil) at T4's inner gate, opposite the main door")
    for n in (4, 5):
        # The outer ring's west road edge (Mil at x -41.6, 3.68 m apart): the one at y 5.61 out, the opening 3.98..7.24
        k.out(n, MIL, -41.60, 5.61, "the outer ring on the west road's edge, the gate facing the main road's junction")
        k.gate(n, -41.60, 5.61, 3.3, 0, "the outer ring on the west road's edge, facing the main road's junction (-45, 10-15)")


def athira(k):
    # Round 3: the gates where the bare-site walk gets out. In the game the east side (the courtyard, the house's
    # east strip) is a dead end with no walls standing at all (round 2), so the way in is from the west lot, which
    # the bare-site routes cross going west, north and south. Round 2's east gates are gone (the baseline's pieces).
    for n in (3, 4):
        # The inner west line (x -6.8): the HB5 at y -7.44 (-10.34..-4.54) out, an HB1 on the corner with the south
        # line (-10.3..-8.9); the opening -8.9..-5.01 (the HB5 at -2.11 starts at -5.01), facing the west lot, onto the
        # house's south-west corner and the veranda's open west side
        k.out(n, HB5, -6.80, -7.44, "the inner west line, the gate onto the west lot")
        k.add(n, HB1, -6.80, -9.60, 270, "the west line's corner piece south of the gate")
        k.gate(n, -6.80, -6.95, 3.9, 0, "the inner west line, facing the west lot, onto the veranda's open west side")
        # The T2 bag along the veranda's south half stands 0.65 m inside the line, across the opening's north part
        k.out(n, LONG, -5.30, -4.20, "the T2 veranda bag 0.65 m behind the gate's north edge")
    for n in (4, 5):
        # The outer south face (Mil at y -13): the one at x -10.06 out, its neighbours eased apart within their joints
        # (west one 0.1 m into the corner with the west face, east one 0.15 m: 0.62 m into the next); the opening
        # -11.82..-8.25, onto the lane south that the bare-site walk takes
        k.out(n, MIL, -10.06, -13.00, "the outer south face at the west lot, the gate onto the lane south")
        k.out(n, MIL, -13.77, -13.00, "moved 0.1 m west to widen the opening")
        k.add(n, MIL, -13.87, -13.00, 180, "the south face west of the gate, its end in the corner with the west face")
        k.out(n, MIL, -6.35, -13.00, "moved 0.15 m east to widen the opening")
        k.add(n, MIL, -6.20, -13.00, 180, "the south face east of the gate (0.62 m into the Mil at x -2.72)")
        k.gate(n, -10.04, -13.00, 3.6, 90, "the outer south face at the west lot's mouth, facing the lane south to the road")


def zaros(k):
    # T3: the east line on the road's shoulder (x 13.2): the HB5 at y 6.02 (3.12..8.92) out, an HB1 against the HB5 at
    # 11.69 (8.79..14.59): 7.69..9.09; the opening 3.72..7.69 (the HB5 at 0.82 ends at 3.72)
    k.out(3, HB5, 13.20, 6.02, "the east line on the main road, the gate opposite the side door")
    k.add(3, HB1, 13.20, 8.39, 90, "re-fits the line's end north of the gate (0.3 m into the HB5 at y 11.69)")
    k.gate(3, 13.20, 5.70, 4.0, 0, "the east line on the main road, opposite the side door (4.9, 5.6)")
    for n in (4, 5):
        # The east face on the road (Mil at x 15, 3.62 m apart): the one at y 5.96 out, the opening 4.39..7.53
        k.out(n, MIL, 15.00, 5.96, "the east face on the main road, at T3's gate")
        k.gate(n, 15.00, 5.96, 3.1, 0, "the east face on the main road, opposite the side door (T3's gate)")


TOWNS = {"Kavala": kavala, "Athira": athira, "Zaros": zaros}


# ---------------------------------------------------------------- closure with the gates shut and open

def grounded(items):
    """Every object on the ground for the closure (the editor dropped the baseline's "ground" flags)."""
    return [it if it[0] != "object" or "ground" in it[4] or "drop" in it[4] else it[:4] + [it[4] + ["ground"]] for it in items]


def plugs(t, items):
    """A wall across each gate's opening (1 m wider than it)."""
    out = []
    for k, it in enumerate(i for i in items if i[0] == "gate"):
        cls = f"PlugWall_{k}"
        sh.REAL[cls] = (float(it[1]) + 1.0, 1.0)
        run = math.degrees(math.atan2(it[3][0][0], it[3][0][1]))
        out.append(["object", cls, it[2], tl._up_dir(run + 90), ["ground"]])
    return out


def through_gate(t, items, path):
    gates = [(t.to_model(it[2])[:2], float(it[1])) for it in items if it[0] == "gate"]
    return [g for g, w in gates if any(math.hypot(x - g[0], y - g[1]) <= w / 2 + 1 for x, y in path)]


def closure_report(t, tiers, solid=False):
    soft = sh.SOFT.get(t.name)
    if solid and soft:
        sh.SOFT[t.name] = ()
    sh._SITE_GRID.pop(t.name, None)
    out = []
    try:
        for n, items in enumerate(tiers, 1):
            if n < 3:
                continue
            g = grounded(items)
            start = SOLID_STARTS[t.name][n] if solid and t.name in SOLID_STARTS else STARTS[t.name][n]
            shut = sh.closure(t, g + plugs(t, g), start)
            opened = sh.closure(t, g, start)
            s = "closed" if shut is None else f"OPEN past the gates, narrowest at {[round(v, 1) for v in shut[1][0]]} ({shut[1][1]:.2f} m)"
            if opened is None:
                o = "NO WAY OUT through the gates"
            else:
                via = through_gate(t, items, opened[0])
                o = f"out through {[[round(v, 1) for v in p] for p in via]}" if via else "out, but NOT through a gate"
            out.append((n, s, o, opened))
    finally:
        if soft is not None:
            sh.SOFT[t.name] = soft
        sh._SITE_GRID.pop(t.name, None)
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    show = None
    if "--map" in sys.argv:
        show = int(sys.argv[sys.argv.index("--map") + 1])
        args = [a for a in args if a != str(show)]
    towns = tl.load()
    for name, fn in TOWNS.items():
        if args and name not in args:
            continue
        t = towns[name]
        k = Town(t)
        fn(k)
        for line in k.log:
            print(f"  {name}: {line}")
        for solid in (False, True):
            if solid and not sh.SOFT.get(name):
                continue
            label = f"neighbours {sh.SOFT[name]} solid" if solid else "as pass 1 modelled the site"
            for n, s, o, opened in closure_report(t, k.tiers, solid):
                print(f"  {name}: T{n} ({label}) gates shut: {s}; gates open: {o}")
                if show == n and not solid:
                    print(sh.overlay(t, grounded(k.tiers[n - 1]), r=66 if name == "Kavala" else 30, path=opened[0] if opened else ()))
        # The user's own "hide" items of map objects the probe doesn't list (Zaros: a wreck, the city gate, a
        # garbage container, a bush) fail tl.check()'s count on the baseline itself: those problems, and only
        # those, are let through (the game hides them all the same)
        known = set(tl.check(t, tl.baseline(t)))
        check = tl.check
        tl.check = lambda town, tiers: [p for p in check(town, tiers) if p not in known]
        try:
            path = tl.write(t, k.tiers)
        finally:
            tl.check = check
        if known:
            print(f"  {name}: the baseline's own problems let through: {sorted(known)}")
        print(f"{name}: items per tier {[len(x) for x in k.tiers]}, gates {[sum(1 for i in x if i[0] == 'gate') for x in k.tiers]} -> {os.path.relpath(path, tl.ROOT)}")


if __name__ == "__main__":
    main()
