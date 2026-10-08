"""The tier's walls, gate and hides drawn over the top-down screenshot."""
import os
import sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # tools/officegen
import blocklib as bl, merge_layouts as ml, merge_compounds as mc, townlib
from PIL import Image, ImageDraw
town, shot, ppm, half, tier, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), int(sys.argv[5]), sys.argv[6]
b = bl.load()[town]
items = ml.load_saved('Altis')[town]['tiers'][tier]
area = mc.load_saved('Altis')[town]['tiers'][tier]
im = Image.open(shot).convert('RGB'); W, H = im.size
P = lambda wx, wy: (W / 2 + (wx - b.pos[0]) * ppm, H / 2 - (wy - b.pos[1]) * ppm)
d = ImageDraw.Draw(im)
d.line([P(*p) for p in area + [area[0]]], fill=(255, 255, 0), width=2)
SIZE = {"Land_ConcreteWall_01_l_gate_F": (10.6, 0.6), "Land_NetFence_01_m_gate_F": (4.1, 0.3)}
for it in items:
    p = [float(v) for v in it[2].strip('[]').split(',')]
    if it[0] == 'hide':
        x, y = P(*p[:2]); d.line([(x - 8, y - 8), (x + 8, y + 8)], fill=(200, 0, 255), width=3); d.line([(x - 8, y + 8), (x + 8, y - 8)], fill=(200, 0, 255), width=3)
        continue
    if it[0] != 'object':
        continue
    vd = [float(v) for v in it[3].split('],[')[0].strip('[]').split(',')]
    ax = (vd[1], -vd[0])
    l, dp = (SIZE.get(it[1]) or townlib.MEASURED.get(it[1]) or townlib.CLASSES.get(it[1]) or (1, 1))[:2]
    pts = [P(p[0] + ax[0] * sx * l / 2 + vd[0] * sy * dp / 2, p[1] + ax[1] * sx * l / 2 + vd[1] * sy * dp / 2) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    col = (0, 255, 0) if 'gate' in it[1].lower() else ((255, 40, 40) if any(w in it[1] for w in ('HBarrier', 'Mil_', 'Cnc')) else (255, 160, 0))
    d.polygon(pts, outline=col, fill=None)
    d.polygon(pts, outline=col)
cw = int(half * ppm)
im.crop((int(W / 2 - cw), int(H / 2 - cw), int(W / 2 + cw), int(H / 2 + cw))).resize((1000, 1000)).save(out, quality=90)
