"""A tier's garrison over its walls' coverage (overlook.py): wall samples green when an elevated man overlooks the
approach, red when none does, grey facing buildings; the guards labelled by post.

    python tools/officegen/garrison_map.py Town tier out.svg
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocklib  # noqa: E402
import overlook  # noqa: E402
import gate_gen as gg  # noqa: E402

town, tier, path = sys.argv[1], int(sys.argv[2]), sys.argv[3]
st = overlook.Study(town, tier)
men = [it for it in st.items if it[0] == "guard"]
seeds = [(gg.vec(m[2])[0], gg.vec(m[2])[1], gg.vec(m[2])[2] + overlook.EYE) for m in men if gg.vec(m[2])[2] - st.b.ground(*gg.vec(m[2])[:2]) > 2.0]
import compound_gen as cg  # noqa: E402
# The men up there as observers, each in the building he stands in (he looks out of its windows)
own = lambda e: next((t for t in st.blds if cg.inside(e[:2], t.corners())), None)
cands = [("man", e, own(e), "tower") for e in seeds]
st.candidates = lambda: cands
S, C, towers, chosen, covered, reach = st.solve(room=0)
AB = {"marksman": "MK", "autorifleman": "AR", "rifleman": "R", "at": "AT"}
marks = {}
for i, m in enumerate(men):
    p = gg.vec(m[2])
    f = m[4].split(",")
    post = "res" if "reserve" in f else ("pat" if "patrol" in f else ("elev" if "elevated" in f else ""))
    marks[AB.get(m[1], m[1]) + ("-" + post if post else "") + ("^" if p[2] - st.b.ground(*p[:2]) > 1.5 else "") + " " * i] = p
blocklib.svg(st.b, path, polygons={f"T{tier}": [list(p) for p in st.poly]}, reach=68, scale=8, pieces=st.items, marks=marks)
P = lambda wx, wy: ((wx - st.b.pos[0] + 68) * 8, (68 - (wy - st.b.pos[1])) * 8)
dots = []
for si, (p, tgt) in enumerate(S):
    x, y = P(*p)
    col = "#9a9a9a" if tgt is None else ("#1e9e3a" if si in covered else "#d0021b")
    dots.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4" fill="{col}"/>')
txt = open(path, encoding="utf-8").read().replace("</svg>", "\n".join(dots) + "\n</svg>")
open(path, "w", encoding="utf-8").write(txt)
print(path, f"{len(covered)} of {len(st.need)} wall samples overlooked")
