"""Compunere PIL pentru preview_angkor_horizon.py (Python de SISTEM, Blender n-are PIL).

    python compose_angkor_horizon.py sky <raw.png> <out.png> <orizont 0..1>
    python compose_angkor_horizon.py row <raw.png> <out.png> <decupare.png>
"""
import sys

from PIL import Image

SKY_TOP = (0x3B, 0x35, 0x50)
SKY_HOR = (0x9C, 0x82, 0x96)
FOG = (0x85, 0x7A, 0x88)
GROUND = (0x36, 0x3A, 0x26)
GREY = (0xC4, 0xC4, 0xC4)


def sky(raw, out, horizon_frac, fog_mix=0.42):
    im = Image.open(raw).convert("RGBA")
    w, h = im.size
    hy = int(horizon_frac * h)
    bg = Image.new("RGB", (w, h), GROUND)
    for y in range(min(hy, h)):
        t = (y / float(max(hy, 1))) ** 0.8
        c = tuple(int(SKY_TOP[i] + (SKY_HOR[i] - SKY_TOP[i]) * t) for i in range(3))
        bg.paste(c, (0, y, w, y + 1))
    a = im.split()[3]
    fogged = Image.blend(im.convert("RGB"), Image.new("RGB", (w, h), FOG), fog_mix)
    bg.paste(fogged, (0, 0), a)
    bg.save(out)


def row(raw, out, crop):
    im = Image.open(raw).convert("RGBA")
    bgc = Image.new("RGBA", im.size, GREY + (255,))
    bgc.alpha_composite(im)
    c = Image.open(crop).convert("RGB")
    c = c.resize((im.width, int(c.height * im.width / c.width)), Image.LANCZOS)
    o = Image.new("RGB", (im.width, c.height + im.height + 8), GREY)
    o.paste(c, (0, 0))
    o.paste(bgc.convert("RGB"), (0, c.height + 8))
    o.save(out)


if __name__ == "__main__":
    k = sys.argv[1]
    if k == "sky":
        sky(sys.argv[2], sys.argv[3], float(sys.argv[4]))
    elif k == "row":
        row(sys.argv[2], sys.argv[3], sys.argv[4])
