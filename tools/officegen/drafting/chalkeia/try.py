import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import areas as A, compound_gen as cg
t3, t4 = eval(sys.argv[1]), eval(sys.argv[2])
for k, p in ((3, t3), (4, t4)):
    g = cg.Gen(A.b, [A.W(q) for q in p], 'Chalkeia', k)
    hits = []
    for i in range(len(p)):
        a, c = A.W(p[i]), A.W(p[(i + 1) % len(p)])
        for s in range(41):
            q = (a[0] + (c[0] - a[0]) * s / 40, a[1] + (c[1] - a[1]) * s / 40)
            if g.on_rock(q):
                hits.append(i); break
    zs = [round(A.b.ground(*A.W(q)), 1) for q in p]
    print(f"T{k} {round(A.area(p))} m2, edges on a rock: {sorted(set(hits))}, corner heights {zs}")
inside = all(cg.inside(A.W(q), [A.W(r) for r in t4]) for q in t3)
print("T3 inside T4:", inside)
