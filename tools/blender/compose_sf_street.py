"""Compunere de imagini pentru randarile de control ale mobilierului de strada San Francisco
(valul 2) -- Python de SISTEM (cu PIL), apelat din `preview_sf_street.py`.

    python tools/blender/compose_sf_street.py --compare --crop c.png --render r.png --out o.png
    python tools/blender/compose_sf_street.py --grid a.png,b.png,c.png,d.png --labels A,B,C,D --out o.png
    python tools/blender/compose_sf_street.py --gamecam f.png --boxes "x0,y0,x1,y1;x0,y0,x1,y1" \
        --labels "30 m,100 m" --out o.png

`--compare` e cel din compose_transfagarasan.py (fundal #C4C4C4). `--gamecam`: sus cadrul
de joc intreg (1920x1080), jos decuparile din jurul fiecarei cutii, marite la pixeli NATIVI
(fara netezire), ca sa se judece ce citeste efectiv la distanta aceea.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import BG, _flat, compare  # noqa: E402


def _label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 8 + 7 * len(text), 22), fill=(40, 40, 40))
    d.text((5, 5), text, fill=(240, 240, 240))


def grid(paths, labels, out_path):
    ims = [_flat(p) for p in paths]
    for im, t in zip(ims, labels):
        _label(im, t)
    cw = max(i.width for i in ims)
    ch = max(i.height for i in ims)
    cols = 2
    rows = (len(ims) + 1) // 2
    img = Image.new("RGB", (cols * cw + 12, rows * ch + 12 * (rows - 1)), BG)
    for k, im in enumerate(ims):
        r, c = divmod(k, cols)
        img.paste(im, (c * (cw + 12), r * (ch + 12)))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("grila:", out_path)


def gamecam(frame, boxes, labels, out_path, crop_h=520):
    fr = Image.open(frame).convert("RGB")
    crops = []
    for box, t in zip(boxes, labels):
        x0, y0, x1, y1 = box
        m = max(20, int((x1 - x0) * 0.15))
        x0, y0 = max(int(x0) - m, 0), max(int(y0) - m, 0)
        x1, y1 = min(int(x1) + m, fr.width), min(int(y1) + m, fr.height)
        c = fr.crop((x0, y0, x1, y1))
        k = max(1, crop_h // max(c.height, 1))
        c = c.resize((c.width * k, c.height * k), Image.NEAREST)
        if c.height > crop_h:
            c = c.resize((c.width * crop_h // c.height, crop_h), Image.NEAREST)
        _label(c, "%s (x%d, pixeli nativi)" % (t, k))
        crops.append(c)
    full = fr.copy()
    d = ImageDraw.Draw(full)
    for box in boxes:
        d.rectangle(tuple(int(v) for v in box), outline=(255, 230, 0), width=2)
    _label(full, "camera de joc 1920x1080")
    row_w = sum(c.width for c in crops) + 12 * (len(crops) - 1)
    w = max(full.width, row_w)
    h = full.height + 12 + max(c.height for c in crops)
    img = Image.new("RGB", (w, h), BG)
    img.paste(full, (0, 0))
    x = 0
    for c in crops:
        img.paste(c, (x, full.height + 12))
        x += c.width + 12
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("gamecam:", out_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", action="store_true")
    ap.add_argument("--crop")
    ap.add_argument("--render")
    ap.add_argument("--grid")
    ap.add_argument("--gamecam")
    ap.add_argument("--boxes")
    ap.add_argument("--labels", default="")
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, default=700)
    a = ap.parse_args()
    labels = a.labels.split(",") if a.labels else []
    if a.compare:
        compare(a.crop, a.render, a.out, a.height)
    elif a.grid:
        paths = a.grid.split(",")
        grid(paths, labels + [""] * (len(paths) - len(labels)), a.out)
    elif a.gamecam:
        boxes = [tuple(float(v) for v in s.split(",")) for s in a.boxes.split(";")]
        gamecam(a.gamecam, boxes, labels + [""] * (len(boxes) - len(labels)), a.out)


if __name__ == "__main__":
    main()
