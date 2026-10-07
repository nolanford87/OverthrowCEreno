"""Hand edits after props_gen.py: at T4 the stores (crates, the generator) go to the south yard (the open ground
between the garage, the terraced houses and the south wall), not crowded round the NE tower."""
import sys, math
sys.path.insert(0, 'P:/OT_rodo_opus/tools/officegen')
import merge_layouts as ml, blocklib as bl, merge_compounds as mc, props_gen as pg, compound_gen as cg
b = bl.load()['Rodopoli']
towns = ml.load_saved('Altis')
t = towns['Rodopoli']
areas = mc.load_saved('Altis')['Rodopoli']['tiers']
O = b.pos[:2]
STORES = pg.CRATES + ["Land_PowerGenerator_F", "Land_CanisterFuel_F"]
for tier, origin in ((4, (13.0, -35.0)),):
    items = [it for it in t['tiers'][tier] if not ("props" in it[4] and it[1] in STORES)]
    p = pg.Props(b, areas[tier], tier, items)
    p.items = items          # Props drops every props item: keep the others
    p.e.items = items
    o = (O[0] + origin[0], O[1] + origin[1])
    grid = [(o[0] + x, o[1] + y) for x in range(-14, 15) for y in range(-14, 15) if cg.inside((o[0] + x, o[1] + y), p.poly)]
    hq = tuple(O)
    for cls in pg.CRATES:
        c = p.spot(pg.SIZE[cls], cg.norm(cg.sub(hq, o)), grid, o)
        if c:
            p.put("object", cls, c, cg.norm(cg.sub(hq, c)))
            print(f"T{tier}: {cls} at {[round(v, 1) for v in b.local(*c)]}")
    c = p.spot((1.6, 2.6), (0, 1), grid, o)
    if c:
        p.put("object", "Land_PowerGenerator_F", c, (0, 1))
        p.put("object", "Land_CanisterFuel_F", cg.add(c, (1.0, 0.6)), (0, 1))
        p.put("object", "Land_CanisterFuel_F", cg.add(c, (1.0, -0.2)), (1, 0))
        print(f"T{tier}: generator at {[round(v, 1) for v in b.local(*c)]}")
    t['tiers'][tier] = p.items
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)

# Outside the main gate, both tiers: the fighting holes 5 m either side and 3 m out (their men 2 m out, clear of
# the wall's face), the sign by the gate post on its side (3.3 m along, 1 m out: off the men and the way in), the
# T4 armed car 12 m along past the hole, its length along the wall
towns = ml.load_saved('Altis')
t = towns['Rodopoli']
for tier in (3, 4):
    items = t['tiers'][tier]
    g = [it for it in items if it[0] == 'gate'][0]
    gp = [float(v) for v in g[2].strip('[]').split(',')]
    u = [float(v) for v in g[3].split('],[')[0].strip('[]').split(',')][:2]
    n = (-u[1], u[0])
    if not cg.inside(cg.add(gp[:2], n), [tuple(p[:2]) for p in areas[tier]]):
        n = (u[1], -u[0])
    def at(a, o):
        return cg.add(cg.add(gp[:2], cg.mul(u, a)), cg.mul(n, o))
    def place(it, c):
        it[2] = f"[{c[0]:.3f},{c[1]:.3f},{b.ground(*c):.3f}]"
    for it in items:
        p = [float(v) for v in it[2].strip('[]').split(',')][:2]
        a = cg.dot(cg.sub(p, gp[:2]), u)
        s = 1 if a > 0 else -1
        if it[1] == 'Land_BagFence_Round_F' and 'hole' in it[4]:
            place(it, at(5.0 * s, -3.0))
        elif it[1] == 'Land_Sign_WarningMilitaryArea_F':
            place(it, at(3.3 * s, -1.0))
        elif it[0] == 'vehicle':
            place(it, at(12.0 * s, -4.5))
    print(f"T{tier}: holes, sign and car set outside the gate")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
