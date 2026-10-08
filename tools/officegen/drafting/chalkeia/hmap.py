"""A block map with the ground: 1 m contours (bold every 5 m) and spot heights, plus areas, marks."""
import os
import sys, math, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # tools/officegen
import blocklib as bl
def make(town, out, polygons=None, marks=None, reach=70, scale=7, pieces=None, contours=True):
    b = bl.load()[town]
    bl.svg(b, out, polygons=polygons, reach=reach, scale=scale, marks=marks, pieces=pieces)
    if not contours:
        return out
    s = open(out, encoding='utf-8').read()
    P = lambda wx, wy: ((wx - b.pos[0] + reach) * scale, (reach - (wy - b.pos[1])) * scale)
    g = []
    step = 1.5
    n = int(reach / step)
    H = {}
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            H[(i, j)] = b.ground(b.pos[0] + i * step, b.pos[1] + j * step)
    lo, hi = int(min(H.values())), int(max(H.values())) + 1
    for lev in range(lo, hi + 1):
        bold = lev % 5 == 0
        for i in range(-n, n):
            for j in range(-n, n):
                c = [H[(i, j)], H[(i + 1, j)], H[(i + 1, j + 1)], H[(i, j + 1)]]
                pts = []
                corners = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
                for k in range(4):
                    a, z = c[k], c[(k + 1) % 4]
                    if (a - lev) * (z - lev) < 0:
                        t = (lev - a) / (z - a)
                        (x1, y1), (x2, y2) = corners[k], corners[(k + 1) % 4]
                        pts.append(P(b.pos[0] + (x1 + (x2 - x1) * t) * step, b.pos[1] + (y1 + (y2 - y1) * t) * step))
                if len(pts) >= 2:
                    g.append(f'<line x1="{pts[0][0]:.1f}" y1="{pts[0][1]:.1f}" x2="{pts[1][0]:.1f}" y2="{pts[1][1]:.1f}" stroke="#1a5fb4" stroke-opacity="{0.9 if bold else 0.35}" stroke-width="{2.2 if bold else 1}"/>')
    for i in range(-n, n + 1, 8):
        for j in range(-n, n + 1, 8):
            x, y = P(b.pos[0] + i * step, b.pos[1] + j * step)
            g.append(f'<text x="{x:.0f}" y="{y:.0f}" font-size="12" fill="#1a5fb4" text-anchor="middle">{H[(i, j)]:.0f}</text>')
    s = s.replace('</svg>', '\n'.join(g) + '\n</svg>')
    open(out, 'w', encoding='utf-8').write(s)
    return out
if __name__ == '__main__':
    make(sys.argv[1], sys.argv[2], reach=int(sys.argv[3]) if len(sys.argv) > 3 else 70)
