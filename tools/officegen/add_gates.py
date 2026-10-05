"""
Puts a real, open gate in every gate marker's opening (pass 2a's "gate" items) of the towns given, in
tools/officegen/layouts/<world>.txt, then rewrites the mod's data function. A vehicle gate sized to the opening:
Land_NetFence_01_m_gate_F (4.1 m) for openings up to 4.8 m, Land_Net_Fence_Gate_F (6.2 m) above; centred on the
marker, its length along the line, on the ground, its doors open ("open"). A marker that already has a gate object
within 1 m is left alone.

Usage (from the repository root):
    python tools/officegen/add_gates.py [--world Altis] "Town" ...
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import merge_layouts  # noqa: E402

SMALL, LARGE = "Land_NetFence_01_m_gate_F", "Land_Net_Fence_Gate_F"


def vec(s):
    return [float(v) for v in s.strip("[]").split(",")]


def main(argv):
    world = "Altis"
    if "--world" in argv:
        i = argv.index("--world")
        world = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    towns = merge_layouts.load_saved(world)
    added = 0
    for town in argv:
        t = towns[town]
        for n, items in t["tiers"].items():
            gates = [it for it in items if it[0] == "object" and "_gate" in it[1].lower()]
            for kind, what, pos, orient, extra in [it for it in items if it[0] == "gate"]:
                p = vec(pos)
                if any(math.dist(vec(g[2])[:2], p[:2]) < 1.0 for g in gates):
                    continue
                d = vec(orient.split("],[")[0])  # The line's direction
                yaw = math.degrees(math.atan2(d[0], d[1])) - 90  # The gate's length (model x) along the line
                v = [round(math.sin(math.radians(yaw)), 4), round(math.cos(math.radians(yaw)), 4), 0.0]
                cls = SMALL if float(what) <= 4.8 else LARGE
                items.append(["object", cls, pos, f"[[{v[0]:.4f},{v[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground,open"])
                added += 1
                print(f"{town} T{n}: {cls} in the {float(what):.1f} m opening at {pos}")
    merge_layouts.write_saved(world, towns)
    print(f"{added} gates added; wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
