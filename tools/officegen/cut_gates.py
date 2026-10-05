"""
Cuts gates into reviewed walls touching nothing else: for each gate marker given (a "gate" item: [x, y, z] ASL,
its width, the line's direction), the wall pieces lying across the opening come out, and the rest of each such
piece's length either side of the opening is filled again with pieces of its own kind (the same height, layer and
facing), so the line runs right up to the opening's edges. Then the marker goes in. Every other piece stays as it is.

    python tools/officegen/cut_gates.py <markers file> "Town" ...

The markers file holds OTLAYOUT lines (an agent's drafts): only their "gate" items are read. Writes
tools/officegen/layouts/<world>.txt and the mod's data function; the gates themselves go in with add_gates.py.
"""
import itertools
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import merge_layouts  # noqa: E402

# Lengths along each piece's model x (measured in the game where we have it), by family: a cut piece is refilled
# from its own family
FAMILIES = [
    {"Land_HBarrier_5_F": 5.8, "Land_HBarrier_3_F": 3.6, "Land_HBarrier_1_F": 1.4},
    {"Land_HBarrier_Big_F": 9.0, "Land_HBarrier_5_F": 5.8, "Land_HBarrier_3_F": 3.6, "Land_HBarrier_1_F": 1.4},
    {"Land_Mil_WallBig_4m_F": 4.0, "Land_CncWall1_F": 1.4},
    {"Land_CncWall4_F": 4.0, "Land_CncWall1_F": 1.4},
    {"Land_HBarrierWall6_F": 6.5, "Land_HBarrierWall4_F": 4.5},
]
LENGTH = {c: l for f in FAMILIES for c, l in f.items()}


def family(cls):
    return next(f for f in FAMILIES if cls in f)


def vec(s):
    return [float(v) for v in str(s).strip("[]").split(",")]


def fill(fam, length):
    """The fewest pieces (at most 3) of a family covering length with the least overhang: [(class, length)]."""
    best = None
    for k in (1, 2, 3):
        for combo in itertools.combinations_with_replacement(fam.items(), k):
            total = sum(l for _, l in combo)
            if total + 0.05 < length:
                continue
            key = (total - length, k)
            if best is None or key < best[0]:
                best = (key, list(combo))
        if best and best[0][0] < 1.0:
            break
    return best[1]


def cut(items, gate):
    _, width, gpos, gorient, _ = gate
    p, w = vec(gpos), float(width)
    d = vec(gorient.split("],[")[0])
    u = (d[0], d[1])  # Along the line
    n = (u[1], -u[0])
    out, added, removed = [], [], []
    for it in items:
        kind, cls, pos, orient, extra = it
        if kind != "object" or cls not in LENGTH:
            out.append(it)
            continue
        c = vec(pos)
        vd = vec(orient.split("],[")[0])
        a = (vd[1], -vd[0])  # The piece's model x, its length
        along = (c[0] - p[0]) * u[0] + (c[1] - p[1]) * u[1]
        across = (c[0] - p[0]) * n[0] + (c[1] - p[1]) * n[1]
        L = LENGTH[cls]
        if abs(a[0] * u[0] + a[1] * u[1]) < 0.9 or abs(across) > 1.5 or abs(along) - L / 2 >= w / 2 - 0.05:
            out.append(it)
            continue
        removed.append(cls)
        s0, s1 = along - L / 2, along + L / 2
        for lo, hi, outward in ((s0, -w / 2, -1), (w / 2, s1, 1)):
            if hi - lo < 0.15:
                continue
            edge = -w / 2 if outward < 0 else w / 2
            at = edge
            for fc, fl in fill(family(cls), hi - lo):
                mid = at + outward * fl / 2
                at += outward * fl
                wx = p[0] + u[0] * mid + n[0] * across
                wy = p[1] + u[1] * mid + n[1] * across
                piece = ["object", fc, f"[{wx:.3f},{wy:.3f},{c[2]:.3f}]", orient, extra]
                out.append(piece)
                added.append(fc)
    out.append(gate)
    return out, removed, added


def main(argv):
    markers_file, towns_given = argv[0], argv[1:]
    markers = merge_layouts.parse(open(markers_file, encoding="utf-8").read().splitlines())
    world = next(iter(markers))
    towns = merge_layouts.load_saved(world)
    for town in towns_given:
        for n, mitems in sorted(markers[world][town]["tiers"].items()):
            gates = [it for it in mitems if it[0] == "gate"]
            if not gates:
                continue
            items = towns[town]["tiers"].get(n, [])
            for g in gates:
                items, removed, added = cut(items, g)
                print(f"{town} T{n}: gate {float(g[1]):.1f} m at {g[2]}: out {removed}, in {added}")
            towns[town]["tiers"][n] = items
    merge_layouts.write_saved(world, towns)
    print("wrote", os.path.relpath(merge_layouts.write_sqf(world, towns), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
