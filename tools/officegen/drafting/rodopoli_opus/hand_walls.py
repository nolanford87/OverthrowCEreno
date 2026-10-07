"""Hand edits after compound_gen.py: map objects hidden that the generator's rule misses."""
import sys, math
sys.path.insert(0, 'P:/OT_rodo_opus/tools/officegen')
import merge_layouts as ml, blocklib as bl
b = bl.load()['Rodopoli']
towns = ml.load_saved('Altis')
t = towns['Rodopoli']
HIDE = {
    # T3: the old yard wall line 2 m behind the south H-barrier (house V2 to the garage): the rest of it is hidden
    3: [(4.2, -22.4), (-1.4, -26.3), (-7.0, -30.3)],
    # T4: the yard wall's end past the south-east corner (it runs on in the road's end); the rusty tank in the yard; the garage at the west road's bend (a way through: its front open to the road)
    4: [(43.5, -22.5), (11.8, -21.5), (0.1, -33.4)],
}
objs = b.walls + b.buildings
for tier, pts in HIDE.items():
    items = t['tiers'][tier]
    have = {(it[1], it[2]) for it in items if it[0] == 'hide'}
    for x, y in pts:
        o = min(objs, key=lambda w: math.dist(b.local(*w.pos[:2]), (x, y)))
        assert math.dist(b.local(*o.pos[:2]), (x, y)) < 0.2, (x, y)
        pos = f"[{o.pos[0]:.3f},{o.pos[1]:.3f},{o.pos[2]:.3f}]"
        if (o.model, pos) not in have:
            items.append(["hide", o.model, pos, "[[0.0000,1.0000,0.0000],[0.0000,0.0000,1.0000]]", ""])
            print(f"T{tier}: hid {o.model} at {x}, {y}")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
# T4: the generator's H-barrier barricades outside the terraced houses' outward doors (by the east road) come out:
# those doors are locked in play (OT_fnc_officeDoors), and a pair stood doubled
t = ml.load_saved('Altis')['Rodopoli']
towns = ml.load_saved('Altis')
t = towns['Rodopoli']
before = len(t['tiers'][4])
def loc(it):
    p = [float(v) for v in it[2].strip('[]').split(',')]
    return b.local(*p[:2])
for tier in (3, 4):
    doors = [b.local(*d) for bd in b.buildings if 'House_Big_02' in bd.model for d in bd.door_points()]
    t['tiers'][tier] = [it for it in t['tiers'][tier] if not (it[0] == 'object' and it[1] == 'Land_HBarrier_3_F' and any(math.dist(loc(it), d) < 2.6 for d in doors))]
print("barricades out:", before - len(t['tiers'][4]))
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
# The north-east run's last piece ran 2.4 m into House_Small_02 (a clip): T3 its H-barrier 5 a 3, T4 its military
# wall two small concrete walls, ending about 0.9 m into the house's box
towns = ml.load_saved('Altis')
t = towns['Rodopoli']
O = b.pos
def find(tier, cls, at):
    return [it for it in t['tiers'][tier] if it[0] == 'object' and it[1] == cls and math.dist(loc(it), at) < 0.2]
def put(tier, cls, p, ref, z):
    w = (O[0] + p[0], O[1] + p[1])
    t['tiers'][tier].append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{z:.3f}]", ref[3], ""])
for tier, cls, at, prev in ((3, 'Land_HBarrier_5_F', (13.7, 17.4), (10.7, 22.0)), (4, 'Land_Mil_WallBig_4m_F', (14.3, 16.7), (12.1, 20.0))):
    old = find(tier, cls, at)
    if not old:
        continue
    c = loc(old[0])
    p0 = loc(find(tier, cls, prev)[0])
    u = ((c[0] - p0[0]) / math.dist(c, p0), (c[1] - p0[1]) / math.dist(c, p0))
    for it in old:
        t['tiers'][tier].remove(it)
    zs = sorted(float(it[2].strip('[]').split(',')[2]) for it in old)
    if tier == 3:
        q = (c[0] - 0.4 * u[0], c[1] - 0.4 * u[1])
        for z in zs:
            put(3, 'Land_HBarrier_3_F', q, old[0], z)
    else:
        for k in (-1.3, -0.1):
            q = (c[0] + k * u[0], c[1] + k * u[1])
            put(4, 'Land_CncWall1_F', q, old[0], zs[0])
    print(f"T{tier}: the last piece into House_Small_02 shortened")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
