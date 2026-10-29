"""The block probe's top-down screenshot (OTB_<town>_top.png, moved to P:\Screenshots\batch3) with polygons and
marks drawn over it: python overlay.py Town [out.jpg]. The camera looks straight down from the office + 120 m,
north up; each world point is projected through the ground under it (the probe's 3 m height grid)."""
import math, os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
import blocklib as bl
SHOTS = r"P:\Screenshots\batch3"
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


def draw(town, polys=(), marks=(), out=None, crop=110, boxes=False, title=""):
    """polys: [(colour, [[x, y], ...])], marks: [(colour, [x, y], label)]; crop: metres each way kept."""
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
        d.line(q + q[:1], fill=colour, width=6)
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
