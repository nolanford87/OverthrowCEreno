import sys, math
sys.path.insert(0, 'P:/OT_chalkeia/tools/officegen')
import blocklib as bl, compound_gen as cg
from PIL import Image, ImageDraw
town, shot, ppm, half, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), sys.argv[5]
b = bl.load()[town]
im = Image.open(shot).convert('RGB')
W, H = im.size
cx, cy = W / 2, H / 2
P = lambda wx, wy: (cx + (wx - b.pos[0]) * ppm, cy - (wy - b.pos[1]) * ppm)
d = ImageDraw.Draw(im)
for r in b.roads:
    a, z = P(*r['beg'][:2]), P(*r['end'][:2])
    d.line([a, z], fill=(0, 220, 255), width=3)
    # the road's edges (half its width)
    u = cg.norm(cg.sub(r['end'][:2], r['beg'][:2])); n = (-u[1], u[0])
    for s in (1, -1):
        e1 = P(r['beg'][0] + n[0] * s * r['width'] / 2, r['beg'][1] + n[1] * s * r['width'] / 2)
        e2 = P(r['end'][0] + n[0] * s * r['width'] / 2, r['end'][1] + n[1] * s * r['width'] / 2)
        d.line([e1, e2], fill=(0, 220, 255), width=1)
for t in b.buildings:
    pts = [P(*c) for c in t.corners()]
    d.polygon(pts, outline=(255, 0, 0))
    f = cg.footprint_of(t.model if t.model.startswith('Land_') else 'Land_' + t.model)
    if f:
        for (x, y) in f[0]:
            q = [P(*t.to_world(x + sx * 0.5, y + sy * 0.5)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            d.polygon(q, outline=(255, 140, 0))
for w in b.walls:
    c = w.corners()
    e1 = ((c[0][0] + c[3][0]) / 2, (c[0][1] + c[3][1]) / 2); e2 = ((c[1][0] + c[2][0]) / 2, (c[1][1] + c[2][1]) / 2)
    d.line([P(*e1), P(*e2)], fill=(255, 255, 0), width=3)
d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(0, 0, 255))
cw = int(half * ppm)
im.crop((int(cx - cw), int(cy - cw), int(cx + cw), int(cy + cw))).resize((1000, 1000)).save(out, quality=90)
