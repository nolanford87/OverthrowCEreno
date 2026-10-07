import sys, math
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import tower_gen as tg, blocklib as bl, merge_compounds as mc, merge_layouts as ml, compound_gen as cg
b = bl.load()['Chalkeia']
areas = mc.load_saved('Altis')['Chalkeia']['tiers']
t = ml.load_saved('Altis')['Chalkeia']
tier, cls, maxfall = int(sys.argv[1]), sys.argv[2], float(sys.argv[3])
blds = [q for q in b.buildings if math.hypot(*b.local(*q.pos[:2])) < 80]
feet = []
for q in blds:
    m = q.model if q.model.startswith('Land_') else 'Land_' + q.model
    f = cg.footprint_of(m)
    feet.append([q.to_world(cx, cy) for cx, cy in f[0]] if f and f[1] >= 999 else None)
kept = [it for it in t['tiers'][tier] if not ('lookout' in it[4] or 'props' in it[4] or 'entrance' in it[4] or it[0] == 'guard')]
hidden = {(it[1], round(float(it[2].strip('[]').split(',')[0]), 1)) for it in t['tiers'][tier] if it[0] == 'hide'}
g = tg.Towers(b, areas[tier], tier, kept)
size = tg.TOWERS[cls]; out = []
for i in range(len(g.poly)):
    a, c = g.poly[i], g.poly[(i + 1) % len(g.poly)]; L = math.dist(a, c); u = cg.norm(cg.sub(c, a))
    inward = (-u[1], u[0]) if cg.inside(cg.add(cg.add(a, cg.mul(u, L / 2)), cg.mul((-u[1], u[0]), 0.5)), g.poly) else (u[1], -u[0])
    for off in (0, 0.5, 1, 2):
        s = 0.0
        while s <= L:
            cc = cg.add(cg.add(a, cg.mul(u, s)), cg.mul(inward, 1.2 + size[1] / 2 + off)); s += 1.0
            box = tg.rect(cc, inward, size)
            if not all(cg.inside(p, g.poly) for p in box): continue
            pad = tg.rect(cc, inward, size, 0.4)
            bad = False
            for q, fp in zip(blds, feet):
                if (q.model, round(q.pos[0], 1)) in hidden: continue
                if fp is None:
                    if tg.overlap(pad, q.corners()): bad = True; break
                elif any(cg.inside(w, tg.rect(cc, inward, size, 0.9)) for w in fp): bad = True; break
            if bad or any(tg.overlap(pad, q) for q in g.pieces) or any(math.dist(cc, q) < max(size) / 2 + 4 for q in g.gates) or any(tg.overlap(pad, r.corners()) for r in b.rocks): continue
            zs = [b.ground(*p) for p in box]
            if max(zs) - min(zs) > maxfall: continue
            out.append((len(g.seen(cc)), round(max(zs) - min(zs), 2), [round(v, 1) for v in b.local(*cc)], i, off, [round(v, 3) for v in inward]))
out.sort(key=lambda r: (-r[0], r[1]))
for o in out[:15]: print(o)
