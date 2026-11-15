"""Compunere de imagini pentru randarile de control ale kitului de case de rand
(San Francisco) — Python de SISTEM (cu PIL); Blender nu are PIL. Apelat prin
subprocess din `preview_sf_row.py`.

    python tools/blender/compose_sf_row.py --compare --crop c.png --render r.png --out o.png
    python tools/blender/compose_sf_row.py --montage a.png,b.png --out o.png
    python tools/blender/compose_sf_row.py --stack a.png,b.png --labels "jos,sus" --out o.png

`--compare` / `--montage` sunt cele din compose_transfagarasan.py (acelasi
fundal #C4C4C4). `--stack` pune cadrele camerei de joc unul sub altul, la
rezolutia nativa, cu o eticheta mica in colt.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import BG, compare, montage  # noqa: E402


def stack(paths, labels, out_path):
    ims = [Image.open(p).convert("RGB") for p in paths]
    w = max(i.width for i in ims)
    gap = 12
    img = Image.new("RGB", (w, sum(i.height for i in ims) + gap * (len(ims) - 1)), BG)
    d = ImageDraw.Draw(img)
    y = 0
    for k, i in enumerate(ims):
        img.paste(i, (0, y))
        if labels and k < len(labels):
            d.rectangle((8, y + 8, 8 + 9 * len(labels[k]) + 12, y + 30), fill=(0, 0, 0))
            d.text((14, y + 12), labels[k], fill=(255, 255, 255))
        y += i.height + gap
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("stiva:", out_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", action="store_true")
    ap.add_argument("--crop")
    ap.add_argument("--render")
    ap.add_argument("--montage")
    ap.add_argument("--stack")
    ap.add_argument("--labels", default="")
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, default=900)
    a = ap.parse_args()
    if a.compare:
        compare(a.crop, a.render, a.out, a.height)
    elif a.montage:
        montage(a.montage.split(","), a.out)
    elif a.stack:
        stack(a.stack.split(","), [s for s in a.labels.split(",") if s], a.out)


if __name__ == "__main__":
    main()
