"""Compunerea planșei satului Colonnata (grupa crr-e) -- Python de SISTEM (PIL).
Apelat din `preview_crr_buildings.py --village`.

    python tools/blender/compose_crr_buildings.py --village <3q.png> <150m.png> --out <png>

Sus: lineup-ul 3/4 la scara comuna. Jos: aceeasi lineup randata cu camera
jocului la 150 m (1920 x 1080, FOV vertical 68), DECUPATA pe sat si marita x4
cu NEAREST: fiecare bloc de 4 x 4 e un pixel real de pe ecran. Pe stanga benzii
se scrie inaltimea satului in pixeli de ecran (fara text pe piese; aici e doar
eticheta planșei).
"""
import argparse
import os

from PIL import Image, ImageDraw

BG = (196, 196, 196)


def _flat(path):
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", im.size, BG + (255,))
    return Image.alpha_composite(bg, im).convert("RGB"), im.getchannel("A")


def village(p3q, p150, out):
    top, _ = _flat(p3q)
    far, alpha = _flat(p150)
    box = alpha.point(lambda v: 255 if v > 8 else 0).getbbox()
    if box is None:
        raise SystemExit("randarea de la 150 m e goala")
    x0, y0, x1, y1 = box
    pad = 6
    crop = far.crop((max(0, x0 - pad), max(0, y0 - pad), min(far.width, x1 + pad),
                     min(far.height, y1 + pad)))
    k = 4
    big = crop.resize((crop.width * k, crop.height * k), Image.NEAREST)
    label_h = 26
    w = max(top.width, big.width)
    img = Image.new("RGB", (w, top.height + 12 + label_h + big.height), BG)
    img.paste(top, ((w - top.width) // 2, 0))
    d = ImageDraw.Draw(img)
    d.text((8, top.height + 12 + 6),
           "la 150 m, camera jocului (FOV 68, 1080p): satul are %d px inaltime, %d px latime; marit x%d"
           % (y1 - y0, x1 - x0, k), fill=(40, 40, 40))
    img.paste(big, ((w - big.width) // 2, top.height + 12 + label_h))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("plansa satului: %s (la 150 m: %d x %d px)" % (out, x1 - x0, y1 - y0))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--village", nargs=2)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    village(a.village[0], a.village[1], a.out)


if __name__ == "__main__":
    main()
