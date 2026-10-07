"""
Proposes a town's occupier compound areas (tools/officegen/COMPOUND_PLAN.md, phase 1) from the block probe
(probes/<world>_blocks.txt), without the compound editor: the block the HQ stands in, grown from the HQ outward
(nearest first) over a 1 m grid, never onto a road (its half width and a metre's clearance) nor past 60 m. T3 stops
at about 1,800 m2, T4 carries on to about 2,900 m2 and T5 to 4,500 m2 (Rodopoli's T3 and T4 as reviewed), so each
tier holds the one below. A building the area takes most of (40%) comes in whole, one it barely touches goes out,
so the line runs round buildings rather than through them where it can. The outline is traced and simplified to
its corners (about 2 m), after smoothing (notches and thin arms of 2 m). Writes tools/officegen/compounds/<world>.txt and the mod's data, and an SVG of each tier.

    python tools/officegen/area_gen.py "Town" [--world Altis] [--tiers 3,4] [--dry]
"""
import heapq
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import compound_gen as cg  # noqa: E402
import merge_compounds  # noqa: E402
import merge_layouts  # noqa: E402

TARGET = {3: 1800, 4: 2900, 5: 4500}
REACH = 60
ROAD_CLEAR = 1.0


def rdp(points, eps):
    """Ramer-Douglas-Peucker on an open polyline."""
    if len(points) < 3:
        return points
    a, b = points[0], points[-1]
    best, idx = 0, 0
    for i in range(1, len(points) - 1):
        d = cg.seg_dist(points[i], a, b)
        if d > best:
            best, idx = d, i
    if best <= eps:
        return [a, b]
    return rdp(points[:idx + 1], eps)[:-1] + rdp(points[idx:], eps)


def outline(cells):
    """The outer boundary of a set of 1 m cells (x, y integer corners), as a loop of corner points."""
    edges = {}
    for (x, y) in cells:
        for (a, b, n) in (((x, y), (x + 1, y), (x, y - 1)), ((x + 1, y), (x + 1, y + 1), (x + 1, y)),
                          ((x + 1, y + 1), (x, y + 1), (x, y + 1)), ((x, y + 1), (x, y), (x - 1, y))):
            if n not in cells:
                edges.setdefault(a, []).append(b)
    loops = []
    while edges:
        start = next(iter(edges))
        loop, p = [start], start
        while True:
            nxt = edges[p].pop()
            if not edges[p]:
                del edges[p]
            if nxt == start:
                break
            loop.append(nxt)
            p = nxt
        loops.append(loop)
    return max(loops, key=len)


def morph(cells, r, grow):
    """Cells grown (a dilation) or shrunk (an erosion) by r (a square neighbourhood)."""
    out = set()
    if grow:
        for (x, y) in cells:
            for dx in range(-r, r + 1):
                for dy in range(-r, r + 1):
                    out.add((x + dx, y + dy))
    else:
        for (x, y) in cells:
            if all((x + dx, y + dy) in cells for dx in range(-r, r + 1) for dy in range(-r, r + 1)):
                out.add((x, y))
    return out


def simplify(loop, eps=2.0):
    """A closed loop simplified: split at its farthest pair, each half simplified."""
    i0 = 0
    i1 = max(range(len(loop)), key=lambda i: math.dist(loop[i], loop[0]))
    a = rdp(loop[i0:i1 + 1], eps)
    b = rdp(loop[i1:] + [loop[0]], eps)
    return a[:-1] + b[:-1]


def grow(block, tiers):
    hq = block.pos[:2]
    ox, oy = int(hq[0]), int(hq[1])
    roads = [(r["beg"][:2], r["end"][:2], r["width"] / 2 + ROAD_CLEAR) for r in block.roads]

    def blocked(c):
        p = (c[0] + 0.5, c[1] + 0.5)
        return any(cg.seg_dist(p, a, b) < w for a, b, w in roads)

    # Which building each cell lies in (its box)
    owner = {}
    for k, t in enumerate(block.buildings):
        cs = t.corners()
        xs, ys = [c[0] for c in cs], [c[1] for c in cs]
        if min(abs(x - hq[0]) for x in xs) > REACH + 15 or min(abs(y - hq[1]) for y in ys) > REACH + 15:
            continue
        for x in range(int(min(xs)), int(max(xs)) + 1):
            for y in range(int(min(ys)), int(max(ys)) + 1):
                if cg.inside((x + 0.5, y + 0.5), cs):
                    owner[(x, y)] = k
    size = {}
    for c, k in owner.items():
        size[k] = size.get(k, 0) + 1
    start = (ox, oy)
    region, seen = set(), {start}
    heap = [(0.0, start)]
    out = {}
    blocked_cache = {}
    for tier in sorted(tiers):
        while heap and len(region) < TARGET[tier]:
            d, c = heapq.heappop(heap)
            if c not in blocked_cache:
                blocked_cache[c] = blocked(c)
            if blocked_cache[c]:
                continue
            region.add(c)
            for n in ((c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)):
                if n not in seen and math.dist((n[0] + 0.5, n[1] + 0.5), hq) <= REACH:
                    seen.add(n)
                    heapq.heappush(heap, (math.dist((n[0] + 0.5, n[1] + 0.5), hq), n))
        # Whole buildings: mostly in, all in (not onto a road); barely in, out
        snapped = set(region)
        counts = {}
        for c in region:
            if c in owner:
                counts[owner[c]] = counts.get(owner[c], 0) + 1
        for k, n in counts.items():
            cells = [c for c, o in owner.items() if o == k]
            if n >= 0.4 * size[k]:
                snapped |= {c for c in cells if not blocked_cache.setdefault(c, blocked(c))}
            else:
                snapped -= set(cells)
        # Smoothed: notches filled, thin arms trimmed (2 m), never onto a road
        snapped = morph(morph(snapped, 2, True), 2, False)
        snapped = morph(morph(snapped, 2, False), 2, True)
        snapped = {c for c in snapped if not blocked_cache.setdefault(c, blocked(c))}
        # Keep only what's joined to the HQ
        joined, todo = set(), [start] if start in snapped else []
        while todo:
            c = todo.pop()
            if c in joined or c not in snapped:
                continue
            joined.add(c)
            todo.extend(((c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)))
        loop = simplify(outline(joined))
        out[tier] = ([[round(p[0], 2), round(p[1], 2)] for p in loop], len(joined))
    return out


def main(argv):
    world = argv[argv.index("--world") + 1] if "--world" in argv else "Altis"
    town = [a for a in argv if not a.startswith("--") and a != world][0]
    tiers = [int(a) for a in argv[argv.index("--tiers") + 1].split(",")] if "--tiers" in argv else [3, 4]
    block = blocklib.load(world)[town]
    areas = grow(block, tiers)
    saved = merge_compounds.load_saved(world)
    t = saved.setdefault(town, {"tiers": {}})
    for tier, (poly, cells) in areas.items():
        print(f"{town} T{tier}: {cells} m2, {len(poly)} corners")
        t["tiers"][tier] = poly
    polys = {f"T{k}": v[0] for k, v in areas.items()}
    out = os.path.join(merge_layouts.ROOT, "tools", "officegen", "compounds", f"{town}_areas.svg")
    blocklib.svg(block, out, polygons=polys, reach=REACH + 10, scale=7)
    if "--dry" in argv:
        return
    merge_compounds.write_saved(world, saved)
    print("wrote", os.path.relpath(merge_compounds.write_sqf(world, saved), merge_layouts.ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
