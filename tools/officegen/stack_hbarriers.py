"""
Makes every H-barrier wall in a world's office layouts two high (the user's look): each single-high
Land_HBarrier_1/3/5_F standing on the ground gets the same piece 1.4 m above it, and the lower one is put on the
ground under it (a gap under a piece is a way through for the AI). Pieces already stacked, and pieces standing raised
on something (an old wall, a step: more than 0.6 m off the ground), stay as they are. Towns given with --skip are
left alone (e.g. the hamlets, to be reworked).

    python tools/officegen/stack_hbarriers.py [--world Altis] [--skip "Town,Town"]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import merge_layouts  # noqa: E402
import townlib  # noqa: E402

HB = ("Land_HBarrier_1_F", "Land_HBarrier_3_F", "Land_HBarrier_5_F")
UPPER = 1.4


def vec(s):
    return [float(v) for v in str(s).strip("[]").split(",")]


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    skip = set(argv[argv.index("--skip") + 1].split(",")) if "--skip" in argv else set()
    towns = merge_layouts.load_saved(world)
    probes = townlib.load(world)
    for town, t in sorted(towns.items()):
        if town in skip or town not in probes:
            continue
        ground = probes[town].ground
        stacked = raised = 0
        for n, items in t["tiers"].items():
            hb = [it for it in items if it[0] == "object" and it[1] in HB]
            for it in hb:
                c = vec(it[2])
                near = [vec(o[2])[2] - c[2] for o in hb if o is not it and math.dist(vec(o[2])[:2], c[:2]) < 0.3]
                if any(1.2 < dz < 1.6 or -1.6 < dz < -1.2 for dz in near):
                    continue  # Already one of a stack
                g = ground(c[0], c[1])
                if abs(c[2] - g) >= 0.6:
                    raised += 1
                    continue
                it[2] = f"[{c[0]:.3f},{c[1]:.3f},{g:.3f}]"
                flags = [f for f in it[4].split(",") if f and f not in ("ground", "drop")]
                items.append(["object", it[1], f"[{c[0]:.3f},{c[1]:.3f},{g + UPPER:.3f}]", it[3], ",".join(flags)])
                stacked += 1
        if stacked or raised:
            print(f"{town}: {stacked} stacked" + (f", {raised} raised left alone" if raised else ""))
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
