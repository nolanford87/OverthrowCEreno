"""The block probe's top-down screenshot (OTB_<town>_top.png, moved to P:\Screenshots\batch4) with polygons and
marks drawn over it: python overlay.py Town [out.jpg]. The camera looks straight down from the office + 120 m,
north up; each world point is projected through the ground under it (the probe's 3 m height grid)."""
import math, os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
import blocklib as bl
SHOTS = r"P:\Screenshots\batch4"
FOV = 0.75   # camSetFov: tan(half the horizontal view) = fov * 4/3 (Arma's 4:3 reference), checked on the boxes


def projector(b, img):
    W, H = img.size
    f = (W / 2) / (FOV * 4 / 3)
    cz = b.pos[2] + 120
    def p(x, y, z=None):
        z = b.ground(x, y) if z is None else z
        k = f / (cz - z)
        return (W / 2 + (x - b.pos[0]) * k, H / 2 - (y - b.pos[1]) * k)
    return p


SIZES = {"Land_HBarrier_5_F": (5.8, 1.7), "Land_HBarrier_3_F": (3.6, 1.7), "Land_HBarrier_1_F": (1.4, 1.5),
         "Land_Mil_WallBig_4m_F": (4.0, 0.6), "Land_CncWall1_F": (1.4, 1.0), "Land_NetFence_01_m_gate_F": (4.1, 0.3),
         "Land_BagFence_Long_F": (2.9, 0.5), "Land_BagFence_Short_F": (1.5, 0.5), "Land_BagBunker_Tower_F": (6.4, 9.83),
         "Land_Cargo_Patrol_V1_F": (6.67, 6.8), "Land_ConcreteWall_01_l_gate_F": (10.61, 0.6),
         "Land_BagBunker_Small_F": (5.0, 5.69), "Land_BagFence_Round_F": (2.86, 1.08), "hmg": (1.6, 2.3)}


def piece_layer(d, p, items):
    """Layout items (merge_layouts' fields): walls and objects as their footprints, gates green, hides purple
    crosses, guards as dots (yellow, the reserve white, the patrol cyan)."""
    for it in items:
        kind, cls, pos = it[0], it[1], [float(v) for v in str(it[2]).strip("[]").split(",")]
        x, y = p(*pos[:2])
        if kind == "hide":
            d.line([x - 9, y - 9, x + 9, y + 9], fill=(170, 60, 220), width=4); d.line([x - 9, y + 9, x + 9, y - 9], fill=(170, 60, 220), width=4)
        elif kind == "guard":
            flags = str(it[4]) if len(it) > 4 else ""
            col = (255, 255, 255) if "reserve" in flags else ((0, 220, 255) if "patrol" in flags else (255, 220, 0))
            d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=col, outline=(0, 0, 0), width=2)
        elif kind in ("object", "static", "vehicle") and (cls in SIZES or kind != "object"):
            ori = str(it[3])
            vd = [float(v) for v in ori.split("],[")[0].strip("[]").split(",")] if "[" in ori else [math.sin(math.radians(float(ori))), math.cos(math.radians(float(ori))), 0]
            ax = (vd[1], -vd[0]); l, w = SIZES.get(cls, (2.0, 2.0))
            q = [p(pos[0] + ax[0] * sx * l / 2 + vd[0] * sy * w / 2, pos[1] + ax[1] * sx * l / 2 + vd[1] * sy * w / 2)
                 for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            col = (40, 230, 40) if "gate" in cls.lower() else ((60, 60, 60) if "Mil_Wall" in cls or "Cncwall" in cls.replace("CncW", "Cncw")
                  else ((230, 120, 30) if kind != "object" or "Bunker" in cls or "Cargo" in cls else (200, 170, 110)))
            d.polygon(q, fill=col, outline=(0, 0, 0))


def draw(town, polys=(), marks=(), out=None, crop=110, boxes=False, title="", items=()):
    """polys: [(colour, [[x, y], ...])], marks: [(colour, [x, y], label)]; crop: metres each way kept; items:
    layout items drawn over (piece_layer)."""
    b = bl.load()[town]
    img = Image.open(os.path.join(SHOTS, f"OTB_{town.replace(' ', '_')}_top.png")).convert("RGB")
    p = projector(b, img)
    d = ImageDraw.Draw(img)
    if boxes:
        for t in b.buildings:
            d.polygon([p(*c) for c in t.corners()], outline=(255, 0, 255))
        for r in b.roads:
            d.line([p(*r['beg'][:2]), p(*r['end'][:2])], fill=(0, 255, 255), width=3)
    for colour, pts in polys:
        q = [p(*v) for v in pts]
        d.line(q + q[:1], fill=colour, width=3)
    piece_layer(d, p, items)
    for colour, xy, label in marks:
        x, y = p(*xy)
        d.rectangle([x - 12, y - 12, x + 12, y + 12], fill=colour, outline=(0, 0, 0), width=3)
        if label:
            d.text((x + 16, y - 10), label, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0), font_size=28)
    cx, cy = p(b.pos[0], b.pos[1])
    k = (p(b.pos[0] + 10, b.pos[1])[0] - cx) / 10
    img = img.crop((int(cx - crop * k), int(cy - crop * k), int(cx + crop * k), int(cy + crop * k)))
    img = img.resize((1100, 1100))
    if title:
        ImageDraw.Draw(img).text((10, 8), title, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0), font_size=22)
    out = out or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'compounds', f"{town.replace(' ', '_')}_areas_on_game.jpg")
    img.save(out, quality=88)
    return out


if __name__ == '__main__':
    print(draw(sys.argv[1], out=sys.argv[2] if len(sys.argv) > 2 else None, boxes=True, title=sys.argv[1] + ": probe boxes"))
