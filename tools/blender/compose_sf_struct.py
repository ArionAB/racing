"""Compunere de imagini pentru randarile de control ale structurilor San Francisco (valul 3) --
Python de SISTEM (cu PIL), apelat din `preview_sf_struct.py`.

    python tools/blender/compose_sf_struct.py --compare --crop c.png --render r.png --out o.png
    python tools/blender/compose_sf_struct.py --sky r.png --horizon-y 96 --out o.png
    python tools/blender/compose_sf_struct.py --gamecam f.png --boxes "x0,y0,x1,y1;.." --labels a,b --out o.png
    python tools/blender/compose_sf_struct.py --stack a.png,b.png --labels A,B --out o.png
    python tools/blender/compose_sf_struct.py --silhouette r.png --out o.png

`--compare` si `--gamecam` sunt cele din compose_transfagarasan.py / compose_sf_street.py (doar
importate). `--sky` pune randarea transparenta peste cerul temei `sanfrancisco` (sky_top 3C78C8
sus, sky_horizon EAE2D2 la linia orizontului, sub ea culoarea paclei DBDAD6: dincolo de apa nu e
nimic randat). `--silhouette`: tot ce e opac devine negru pe alb (silueta pura).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import BG, _flat, compare  # noqa: E402
from compose_sf_street import gamecam  # noqa: E402

SKY_TOP = (0x3C, 0x78, 0xC8)
SKY_HOR = (0xEA, 0xE2, 0xD2)
FOG = (219, 218, 214)          # Color(0.86, 0.855, 0.84) din tema


def _label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 8 + 7 * len(text), 22), fill=(40, 40, 40))
    d.text((5, 5), text, fill=(240, 240, 240))


def sky(render, horizon_y, out):
    im = Image.open(render).convert("RGBA")
    bg = Image.new("RGBA", im.size)
    px = bg.load()
    hy = max(1, horizon_y)
    for y in range(im.height):
        if y <= hy:
            t = (y / float(hy)) ** 0.6 if hy > 0 else 1.0
            c = tuple(int(SKY_TOP[i] + (SKY_HOR[i] - SKY_TOP[i]) * t) for i in range(3))
        else:
            c = FOG
        for x in range(im.width):
            px[x, y] = c + (255,)
    Image.alpha_composite(bg, im).convert("RGB").save(out)
    print("cer:", out)


def stack(paths, labels, out):
    ims = [_flat(p) for p in paths]
    for im, t in zip(ims, labels):
        if t:
            _label(im, t)
    w = max(i.width for i in ims)
    h = sum(i.height for i in ims) + 12 * (len(ims) - 1)
    img = Image.new("RGB", (w, h), BG)
    y = 0
    for im in ims:
        img.paste(im, ((w - im.width) // 2, y))
        y += im.height + 12
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("stiva:", out)


def silhouette(render, out):
    im = Image.open(render).convert("RGBA")
    a = im.split()[3]
    sil = Image.new("RGB", im.size, (255, 255, 255))
    blk = Image.new("RGB", im.size, (0, 0, 0))
    sil.paste(blk, mask=a.point(lambda v: 255 if v > 100 else 0))
    sil.save(out)
    print("silueta:", out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", action="store_true")
    ap.add_argument("--crop")
    ap.add_argument("--render")
    ap.add_argument("--sky")
    ap.add_argument("--horizon-y", type=int, default=96)
    ap.add_argument("--gamecam")
    ap.add_argument("--boxes")
    ap.add_argument("--stack")
    ap.add_argument("--silhouette")
    ap.add_argument("--labels", default="")
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, default=520)
    a = ap.parse_args()
    labels = a.labels.split(",") if a.labels else []
    if a.compare:
        compare(a.crop, a.render, a.out, a.height)
    elif a.sky:
        sky(a.sky, a.horizon_y, a.out)
    elif a.gamecam:
        boxes = [tuple(float(v) for v in s.split(",")) for s in a.boxes.split(";")]
        gamecam(a.gamecam, boxes, labels + [""] * (len(boxes) - len(labels)), a.out)
    elif a.stack:
        paths = a.stack.split(",")
        stack(paths, labels + [""] * (len(paths) - len(labels)), a.out)
    elif a.silhouette:
        silhouette(a.silhouette, a.out)


if __name__ == "__main__":
    main()
