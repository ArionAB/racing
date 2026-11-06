"""Compunere de imagini pentru comparatiile Angkor (fundal #C4C4C4) -- Python de
SISTEM (cu PIL); interpretorul lui Blender nu are PIL. Apelat prin subprocess
din `preview_angkor.py`.

    python tools/blender/compose_angkor.py --compare <nume> --crop <png> \
        --render <png> --out <png> --height 900
    python tools/blender/compose_angkor.py --montage a.png,b.png --out <png>
    python tools/blender/compose_angkor.py --gamecam f1.png,f2.png \
        --boxes "x0,y0,x1,y1;x0,y0,x1,y1" --out <png>

`--compare` si `--montage` sunt cele din compose_transfagarasan.py (aceeasi
conventie, acelasi fundal); `--gamecam` e nou: pe fiecare rand, cadrul de joc
(1920x1080, la jumatate) si decuparea turnului la pixeli NATIVI, marita de 3x
(bicubic), ca sa se vada ce citeste camera de joc.
"""
import argparse
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import BG, compare, montage  # noqa: E402


def gamecam(frames, boxes, out_path, zoom=3, row_h=600):
    rows = []
    for fpath, box in zip(frames, boxes):
        fr = Image.open(fpath).convert("RGB")
        full = fr.resize((fr.width * row_h // fr.height, row_h), Image.LANCZOS)
        x0, y0, x1, y1 = box
        m = 24
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
    ap.add_argument("--compare")
    ap.add_argument("--crop")
    ap.add_argument("--render")
    ap.add_argument("--montage")
    ap.add_argument("--gamecam")
    ap.add_argument("--boxes")
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, default=900)
    a = ap.parse_args()
    if a.compare:
        compare(a.crop, a.render, a.out, a.height)
    elif a.montage:
        montage(a.montage.split(","), a.out)
    elif a.gamecam:
        boxes = [tuple(float(v) for v in s.split(",")) for s in a.boxes.split(";")]
        gamecam(a.gamecam.split(","), boxes, a.out)


if __name__ == "__main__":
    main()
