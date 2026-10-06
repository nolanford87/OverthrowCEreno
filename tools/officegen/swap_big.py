"""
Replaces every Land_HBarrier_Big_F in a world's office layouts with the same wall built from pieces the AI
respects: an HBarrier_5 and an HBarrier_3 along the big piece's line (together its 9 m), stacked two high (the lower
layer on the ground under it, the upper 1.4 m above). AI soldiers walk through HBarrier_Big in any behaviour (the QA "roadpath" survey, round 4); they
don't through the stacked pieces. Everything else stays.

    python tools/officegen/swap_big.py [--world Altis]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import merge_layouts  # noqa: E402
import townlib  # noqa: E402

BIG = "Land_HBarrier_Big_F"
# (class, offset along the big piece's length from its middle): HBarrier_5 5.8 m from its left end, HBarrier_3 3.6 m
# to its right end, overlapping 0.4 m
PARTS = [("Land_HBarrier_5_F", -1.6), ("Land_HBarrier_3_F", 2.7)]
UPPER = 1.4


def vec(s):
    return [float(v) for v in str(s).strip("[]").split(",")]


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    towns = merge_layouts.load_saved(world)
    probes = townlib.load(world)  # The ground under each new piece (on a slope it isn't the big piece's)
    swapped = {}
    for town, t in towns.items():
        for n, items in t["tiers"].items():
            out = []
            for it in items:
                kind, cls, pos, orient, extra = it
                if kind != "object" or cls != BIG:
                    out.append(it)
                    continue
                c = vec(pos)
                vd = vec(orient.split("],[")[0])
                ax = (vd[1], -vd[0])  # The piece's model x, its length
                flags = [f for f in extra.split(",") if f]
                for pc, off in PARTS:
                    x, y = c[0] + ax[0] * off, c[1] + ax[1] * off
                    # The lower layer on the ground under it (a gap under a piece is a way through for the AI)
                    z = probes[town].ground(x, y) if town in probes else c[2]
                    out.append(["object", pc, f"[{x:.3f},{y:.3f},{z:.3f}]", orient, ",".join(flags)])
                    # The upper layer at its exact height (never dropped to the ground)
                    upper = [f for f in flags if f not in ("ground", "drop")]
                    out.append(["object", pc, f"[{x:.3f},{y:.3f},{z + UPPER:.3f}]", orient, ",".join(upper)])
                swapped[town] = swapped.get(town, 0) + 1
            t["tiers"][n] = out
    merge_layouts.write_saved(world, towns)
    for town, k in sorted(swapped.items()):
        print(f"{town}: {k} HBarrier_Big replaced")
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
