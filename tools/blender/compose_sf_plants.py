"""Compunere de imagini pentru randarile de control ale vegetatiei San Francisco (val 2) --
Python de SISTEM (cu PIL), apelat din `preview_sf_plants.py`.

    python tools/blender/compose_sf_plants.py --compare --crop c.png --render r.png --out o.png
    python tools/blender/compose_sf_plants.py --grid a.png,b.png,c.png --cols 3 --labels A,B,C --out o.png
    python tools/blender/compose_sf_plants.py --gamecam f.png --boxes "x0,y0,x1,y1;..." \
        --labels "a,b" --out o.png

`--compare` e cel din compose_transfagarasan.py (decupare | randare, fundal #C4C4C4).
`--grid` pune imaginile pe `--cols` coloane, cu eticheta. `--gamecam`: cadrul de joc
(1920x1080, la jumatate) sus, dedesubt decuparile cutiilor la pixeli NATIVI, marite de 3x
(ce vede jucatorul, nu ce vede randarea de aproape).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import BG, _flat, compare  # noqa: E402


def _label(img, text):
    if not text:
        return
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 8 + 7 * len(text), 22), fill=(40, 40, 40))
    d.text((5, 5), text, fill=(240, 240, 240))


def grid(paths, labels, cols, out_path, cell_h=None):
    ims = [_flat(p) for p in paths]
    if cell_h:
        ims = [i.resize((max(1, i.width * cell_h // i.height), cell_h), Image.LANCZOS) for i in ims]
    for im, t in zip(ims, labels):
        _label(im, t)
    cw = max(i.width for i in ims)
    ch = max(i.height for i in ims)
    rows = (len(ims) + cols - 1) // cols
    img = Image.new("RGB", (cols * cw + 12 * (cols - 1), rows * ch + 12 * (rows - 1)), BG)
    for k, im in enumerate(ims):
        r, c = divmod(k, cols)
        img.paste(im, (c * (cw + 12), r * (ch + 12)))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("grila:", out_path)


def gamecam(frame, boxes, labels, out_path, zoom=3, crop_h=420):
    fr = Image.open(frame).convert("RGB")
    full = fr.resize((fr.width // 2, fr.height // 2), Image.LANCZOS)
    _label(full, "camera de joc (10 m sus, 12,5 m in spate, 29 grade, FOV vertical 68)")
    crops = []
    for box, t in zip(boxes, labels):
        x0, y0, x1, y1 = box
        m = 12
        x0, y0 = max(int(x0) - m, 0), max(int(y0) - m, 0)
        x1, y1 = min(int(x1) + m, fr.width), min(int(y1) + m, fr.height)
        c = fr.crop((x0, y0, x1, y1))
        c = c.resize((c.width * zoom, c.height * zoom), Image.NEAREST)
        if c.height > crop_h:
            c = c.resize((max(1, c.width * crop_h // c.height), crop_h), Image.LANCZOS)
        _label(c, t)
        crops.append(c)
    row_w = sum(c.width for c in crops) + 12 * (len(crops) - 1)
    row_h = max(c.height for c in crops) if crops else 0
    w = max(full.width, row_w)
    img = Image.new("RGB", (w, full.height + 12 + row_h), BG)
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
    ap.add_argument("--cols", type=int, default=2)
    ap.add_argument("--cell-h", type=int, default=0)
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
        grid(paths, labels + [""] * (len(paths) - len(labels)), a.cols, a.out, a.cell_h or None)
    elif a.gamecam:
        boxes = [tuple(float(v) for v in s.split(",")) for s in a.boxes.split(";")]
        gamecam(a.gamecam, boxes, labels + [""] * (len(boxes) - len(labels)), a.out)


if __name__ == "__main__":
    main()
