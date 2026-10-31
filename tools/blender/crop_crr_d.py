"""Feliile coltului de muzeu din decuparea `museum_set.png` (kit §1.4: trei GLB-uri
separate, un singur desen pe planșa). Fiecare felie e referinta de comparatie a
GLB-ului ei (`preview_crr_d.py --compare museum_set_<x>`).

    python tools/blender/crop_crr_d.py

Coloanele (px pe decuparea de 560 x 222) sunt alese pe golurile dintre piese.
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(PROJ, "docs", "track_briefs", "img", "carrara_assets_v1", "museum_set.png")
OUT = os.path.join(PROJ, "docs", "asset_briefs", "img", "carrara_fidelity", "crops_crr_d")

SLICES = {
    "museum_set_cart": (0, 205),
    "museum_set_wheel": (200, 350),
    "museum_set_sled": (318, 560),
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    im = Image.open(SRC).convert("RGB")
    for name, (x0, x1) in SLICES.items():
        p = os.path.join(OUT, name + ".png")
        im.crop((x0, 0, min(x1, im.width), im.height)).save(p)
        print(p, im.crop((x0, 0, min(x1, im.width), im.height)).size)
