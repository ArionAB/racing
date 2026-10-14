"""Compunere a capturii de la distanta de joc (tf-g) -- Python de SISTEM (cu PIL).

    python tools/blender/compose_tf_g.py --grid a.png,b.png,c.png,d.png \
        --labels "..;..;..;.." --cols 2 --out out.png --width 960
"""
import argparse
import os

from PIL import Image, ImageDraw


def grid(paths, labels, cols, out, width):
    ims = []
    for p in paths:
        im0 = Image.open(p).convert("RGBA")
        im = Image.alpha_composite(Image.new("RGBA", im0.size, (196, 196, 196, 255)), im0).convert("RGB")
        h = int(im.height * width / im.width)
        ims.append(im.resize((width, h), Image.LANCZOS))
    rows = (len(ims) + cols - 1) // cols
    cell_h = max(i.height for i in ims) + 22
    img = Image.new("RGB", (cols * width, rows * cell_h), (255, 255, 255))
    d = ImageDraw.Draw(img)
    for k, im in enumerate(ims):
        x, y = (k % cols) * width, (k // cols) * cell_h
        d.text((x + 6, y + 5), labels[k] if k < len(labels) else "", fill=(160, 0, 0))
        img.paste(im, (x, y + 22))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("grid:", out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--grid", required=True)
    ap.add_argument("--labels", default="")
    ap.add_argument("--cols", type=int, default=2)
    ap.add_argument("--out", required=True)
    ap.add_argument("--width", type=int, default=960)
    a = ap.parse_args()
    grid(a.grid.split(","), a.labels.split(";"), a.cols, a.out, a.width)
