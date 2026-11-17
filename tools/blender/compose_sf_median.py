"""Compunere de imagini pentru randarile de control ale utilajului si blocului
(San Francisco, pasul 7) -- Python de SISTEM (cu PIL), apelat din
`preview_sf_median.py`.

    python tools/blender/compose_sf_median.py --compare --crop c.png --render r.png --out o.png
    python tools/blender/compose_sf_median.py --grid a.png,b.png,c.png,d.png --labels A,B,C,D --out o.png
    python tools/blender/compose_sf_median.py --gamecam f1.png,f2.png \
        --boxes "x0,y0,x1,y1;x0,y0,x1,y1" --labels "40 m,120 m" --out o.png

`--compare` e cel din compose_transfagarasan.py (fundal #C4C4C4). `--grid` pune
vederile 2x2 cu eticheta. `--gamecam`: pe fiecare rand cadrul de joc (1920x1080
la jumatate) si decuparea utilajului la pixeli NATIVI, marita de 3x.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import BG, _flat, compare  # noqa: E402


def _label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 8 + 8 * len(text), 22), fill=(40, 40, 40))
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


def gamecam(frames, boxes, labels, out_path, zoom=3, row_h=600):
    rows = []
    for fpath, box, t in zip(frames, boxes, labels):
        fr = Image.open(fpath).convert("RGB")
        full = fr.resize((fr.width * row_h // fr.height, row_h), Image.LANCZOS)
        _label(full, t)
        x0, y0, x1, y1 = box
        m = 30
        x0, y0 = max(int(x0) - m, 0), max(int(y0) - m, 0)
        x1, y1 = min(int(x1) + m, fr.width), min(int(y1) + m, fr.height)
        crop = fr.crop((x0, y0, x1, y1))
        crop = crop.resize((crop.width * zoom, crop.height * zoom), Image.BICUBIC)
        if crop.height > row_h:
            crop = crop.resize((crop.width * row_h // crop.height, row_h), Image.BICUBIC)
        row = Image.new("RGB", (full.width + 12 + crop.width, row_h), BG)
        row.paste(full, (0, 0))
        row.paste(crop, (full.width + 12, (row_h - crop.height) // 2))
        rows.append(row)
    w = max(r.width for r in rows)
    img = Image.new("RGB", (w, sum(r.height for r in rows) + 12 * (len(rows) - 1)), BG)
    y = 0
    for r in rows:
        img.paste(r, (0, y))
        y += r.height + 12
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
        frames = a.gamecam.split(",")
        boxes = [tuple(float(v) for v in s.split(",")) for s in a.boxes.split(";")]
        gamecam(frames, boxes, labels + [""] * (len(frames) - len(labels)), a.out)


if __name__ == "__main__":
    main()
