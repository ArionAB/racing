"""Compunere de imagini pentru comparatiile Kyoto -- Python de SISTEM (cu PIL);
interpretorul lui Blender nu are PIL. Apelat prin subprocess din
`preview_kyoto.py`.

    python tools/blender/compose_kyoto.py --compare <nume> --crop <png> \
        --render <png> --out <png> --height 900
    python tools/blender/compose_kyoto.py --montage a.png,b.png --out <png>
    python tools/blender/compose_kyoto.py --sheet <val> --fid-dir <dir> \
        --names a,b --out <png>
"""
import argparse
import os

from PIL import Image, ImageDraw

BG = (207, 207, 207)


def _flat(path):
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", im.size, BG + (255,))
    return Image.alpha_composite(bg, im).convert("RGB")


def compare(crop_path, render_path, out_path, height):
    crop = Image.open(crop_path).convert("RGB")
    ren = _flat(render_path)
    # aceeasi inaltime in pixeli
    crop = crop.resize((max(int(crop.width * height / crop.height), 1), height), Image.LANCZOS)
    ren = ren.resize((max(int(ren.width * height / ren.height), 1), height), Image.LANCZOS)
    gap = 12
    img = Image.new("RGB", (crop.width + gap + ren.width, height), BG)
    img.paste(crop, (0, 0))
    img.paste(ren, (crop.width + gap, 0))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("comparatie:", out_path)


def montage(paths, out_path):
    ims = [_flat(p) for p in paths]
    w = sum(i.width for i in ims)
    h = max(i.height for i in ims)
    img = Image.new("RGB", (w, h), BG)
    x = 0
    for i in ims:
        img.paste(i, (x, 0))
        x += i.width
    img.save(out_path)
    print("montaj:", out_path)


def sheet(fid_dir, names, out_path):
    ims = []
    for n in names:
        p = os.path.join(fid_dir, n + ".png")
        if os.path.exists(p):
            ims.append((n, Image.open(p).convert("RGB")))
    if not ims:
        print("nicio comparatie")
        return
    w = max(i.width for _, i in ims)
    h = sum(i.height + 22 for _, i in ims)
    img = Image.new("RGB", (w, h), (255, 255, 255))
    d = ImageDraw.Draw(img)
    y = 0
    for n, i in ims:
        d.text((4, y + 4), n, fill=(180, 0, 0))
        img.paste(i, (0, y + 22))
        y += i.height + 22
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("planșa:", out_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare")
    ap.add_argument("--crop")
    ap.add_argument("--render")
    ap.add_argument("--montage")
    ap.add_argument("--sheet")
    ap.add_argument("--fid-dir")
    ap.add_argument("--names")
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, default=900)
    a = ap.parse_args()
    if a.compare:
        compare(a.crop, a.render, a.out, a.height)
    elif a.montage:
        montage(a.montage.split(","), a.out)
    elif a.sheet:
        sheet(a.fid_dir, a.names.split(","), a.out)


if __name__ == "__main__":
    main()
