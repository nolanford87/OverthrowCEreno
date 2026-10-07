"""Chalkeia hand edits after props_gen.py: outside the main gate (both tiers) the fighting holes 5.5 m either side
and 3.5 m out (their men 2.5 m out: a man's way along the wall stays open), the sign by the gate post (3.3 m along,
1.25 m out, clear of the H-barrier's face). At 2 m out the holes' men stood against the wall and a man walking out
of the T3 gate stuck between them, the sign and the wall."""
import sys
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import merge_layouts as ml, blocklib as bl, merge_compounds as mc, compound_gen as cg
b = bl.load()['Chalkeia']
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
areas = mc.load_saved('Altis')['Chalkeia']['tiers']
for tier in (3, 4):
    items = t['tiers'][tier]
    g = [it for it in items if it[0] == 'gate'][0]
    gp = [float(v) for v in g[2].strip('[]').split(',')]
    u = [float(v) for v in g[3].split('],[')[0].strip('[]').split(',')][:2]
    n = (-u[1], u[0])
    if not cg.inside(cg.add(gp[:2], n), [tuple(p[:2]) for p in areas[tier]]):
        n = (u[1], -u[0])
    at = lambda a, o: cg.add(cg.add(gp[:2], cg.mul(u, a)), cg.mul(n, o))
    def place(it, c):
        it[2] = f"[{c[0]:.3f},{c[1]:.3f},{b.ground(*c):.3f}]"
    for it in items:
        p = [float(v) for v in it[2].strip('[]').split(',')][:2]
        s = 1 if cg.dot(cg.sub(p, gp[:2]), u) > 0 else -1
        if it[1] == 'Land_BagFence_Round_F' and 'hole' in it[4]:
            place(it, at(5.5 * s, -3.5))
        elif it[1] == 'Land_Sign_WarningMilitaryArea_F':
            place(it, at(3.3 * s, -1.25))
    print(f"T{tier}: holes and sign set outside the gate")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)

# T3's net-fence gate turned round (its model +y out): its leaf swings away from a man walking out from inside. As
# placed (+y in) a man starting 6 m in reached it while it was still swinging and stuck on it (the walk test failed
# 2 runs in 4); turned, 3 runs of 3 passed
towns = ml.load_saved('Altis')
t = towns['Chalkeia']
for it in t['tiers'][3]:
    if it[1] == 'Land_NetFence_01_m_gate_F':
        vd = [float(v) for v in it[3].split('],[')[0].strip('[]').split(',')]
        it[3] = f"[[{-vd[0]:.4f},{-vd[1]:.4f},0.0000],[0.0000,0.0000,1.0000]]"
        print("T3: the gate turned round")
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
