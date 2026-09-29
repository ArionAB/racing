"""Compunere de imagini pentru comparatiile de fidelitate Jodhpur — Python de
SISTEM (cu PIL), nu interpretorul lui Blender (care nu are PIL instalat,
masurat direct). Apelat prin subprocess din `preview_jodhpur.py`, ca sa
raman[a] un singur punct de intrare pentru dezvoltator (`--compare`,
`--sheet`), fara sa ceara doi pasi manuali.

Doua moduri:

    python tools/blender/compose_jodhpur.py --compare <nume> \
        --crop <decupare.png> --render <randare.png> --out <iesire.png> \
        --height 900

    python tools/blender/compose_jodhpur.py --sheet <val> \
        --fid-dir <dir cu comparatii> --names a,b,c --out <iesire.png>
"""

import argparse
import os

from PIL import Image


def compose_compare(crop_path, render_path, out_path, height):
    crop_img = Image.open(crop_path).convert("RGB")
    render_img = Image.open(render_path).convert("RGB")
    scale_r = height / render_img.height
    render_img = render_img.resize((max(int(render_img.width * scale_r), 1), height))
    scale_c = height / crop_img.height
    crop_img = crop_img.resize((max(int(crop_img.width * scale_c), 1), height))

    gap = 12
    total_w = crop_img.width + gap + render_img.width
    combo = Image.new("RGB", (total_w, height), (207, 207, 207))
    combo.paste(crop_img, (0, 0))
    combo.paste(render_img, (crop_img.width + gap, 0))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    combo.save(out_path)
    print("compose: comparatie salvata:", out_path)


def compose_sheet(fid_dir, names, out_path):
    imgs = []
    for n in names:
        p = os.path.join(fid_dir, n + ".png")
        if os.path.exists(p):
            imgs.append((n, Image.open(p).convert("RGB")))
        else:
            print("compose: LIPSA comparatie:", n)
    if not imgs:
        print("compose: planta SARITA (nicio comparatie gasita)")
        return
    width = max(im.width for _, im in imgs)
    total_h = sum(im.height for _, im in imgs) + 8 * (len(imgs) - 1)
    combo = Image.new("RGB", (width, total_h), (255, 255, 255))
    y = 0
    for n, im in imgs:
        combo.paste(im, (0, y))
        y += im.height + 8
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    combo.save(out_path)
    print("compose: planta fidelitate salvata:", out_path)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--compare")
    p.add_argument("--crop")
    p.add_argument("--render")
    p.add_argument("--sheet")
    p.add_argument("--fid-dir")
    p.add_argument("--names")
    p.add_argument("--out", required=True)
    p.add_argument("--height", type=int, default=900)
    args = p.parse_args()

    if args.compare:
        compose_compare(args.crop, args.render, args.out, args.height)
    elif args.sheet:
        names = args.names.split(",") if args.names else []
        compose_sheet(args.fid_dir, names, args.out)
    else:
        raise SystemExit("foloseste --compare sau --sheet")


if __name__ == "__main__":
    main()
