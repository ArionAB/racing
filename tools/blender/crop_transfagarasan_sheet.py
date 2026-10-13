"""Decupari per piesa din planșa de inventar Transfagarasan (v0.2), marite 2x.

    python tools/blender/crop_transfagarasan_sheet.py

Citeste docs/track_briefs/img/transfagarasan_plan/inventar_v02.jpg si scrie
docs/track_briefs/img/transfagarasan_assets_v1/<nume>.png, plus montajul de
control _control.png (toate decuparile, cu nume).

Tiparul e crop_okinawa_sheet.py: benzile de rand si centrele etichetelor s-au
masurat pe planșa 1024 x 1536 (fundal gri ~196; etichetele = pixeli < 90 pe
benzi de <= 22 px), iar fiecare piesa primeste coloanele dintre mijloacele
etichetelor vecine. Pe ultimul rand creasta e mai lata decat celula ei, deci
acolo coloanele sunt date explicit. Decuparea se strange apoi pe pixelii care
difera de fundal. Ursul apare de doua ori (in patru labe, ridicat): doua
decupari, `brown_bear_walk` si `brown_bear_stand`.
"""
import os
from PIL import Image, ImageDraw
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "docs", "track_briefs", "img", "transfagarasan_plan", "inventar_v02.jpg")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "transfagarasan_assets_v1")
BG = 196
DIFF = 40

# Rand: (y_sus, y_jos fara eticheta), apoi (nume, centrul etichetei pe x).
ROWS = [
    ((8, 186), [("vidraru_dam", 121), ("prometheus_statue", 307), ("poenari_ruin", 503),
                ("tunnel_portal_balea", 708), ("cabana_balea_lac", 911)]),
    ((222, 366), [("cabana_balea_cascada", 113), ("brown_bear_walk", 316), ("brown_bear_stand", 503),
                  ("sheep", 705), ("sheepdog", 912)]),
    ((400, 541), [("snow_wall", 103), ("retaining_wall_straight", 310), ("retaining_wall_curve", 518),
                  ("rock_tunnel_portal", 735), ("snow_pole", 928)]),
    ((570, 738), [("road_works", 112), ("level_crossing", 325), ("bear_warning_sign", 516),
                  ("stana", 708), ("arges_house_a", 919)]),
    ((772, 916), [("arges_house_b", 112), ("souvenir_stall", 317), ("parked_car_a", 520),
                  ("parked_car_b", 726), ("motorbike", 919)]),
    ((938, 1109), [("ro_train", 135), ("cable_cabin_large", 347), ("schist_outcrop_a", 528),
                   ("schist_outcrop_b", 723), ("schist_outcrop_c", 918)]),
    ((1135, 1302), [("scree_cone", 113), ("jneapan_a", 315), ("jneapan_b", 513),
                    ("beech_tree_a", 712), ("beech_tree_b", 918)]),
]
# Granite mutate de la mijlocul dintre etichete, unde desenul vecin trece de el
# (barajul, portalul de stanca, trenul, grohotisul): (rand, piesa) -> x stanga.
CUTS = {(0, 1): 228, (2, 4): 862, (3, 3): 600, (5, 1): 264, (6, 1): 232}
# Ultimul rand, coloane explicite (x0, x1): creasta (330-620) e mai lata decat celula.
LAST_Y = (1355, 1474)
LAST = [("bujor_de_munte", 10, 175), ("afin", 175, 318), ("fagaras_ridge", 318, 622),
        ("cloud_sea", 622, 820), ("fagaras_plain", 820, 1014)]


def tighten(arr, x0, x1, y0, y1):
    sub = np.abs(arr[y0:y1, x0:x1] - BG).sum(axis=2) > DIFF
    ys, xs = np.nonzero(sub)
    if len(xs) == 0:
        return (x0, y0, x1, y1)
    return (x0 + xs.min() - 4, y0 + ys.min() - 4, x0 + xs.max() + 5, y0 + ys.max() + 5)


def main():
    im = Image.open(SRC).convert("RGB")
    arr = np.asarray(im).astype(int)
    W = im.size[0]
    os.makedirs(OUT, exist_ok=True)
    crops = []
    for r, ((y0, y1), pieces) in enumerate(ROWS):
        centers = [c for _, c in pieces]
        for i, (name, c) in enumerate(pieces):
            x0 = 0 if i == 0 else CUTS.get((r, i), (centers[i - 1] + c) // 2)
            x1 = W if i == len(pieces) - 1 else CUTS.get((r, i + 1), (c + centers[i + 1]) // 2)
            crops.append((name, tighten(arr, x0, x1, y0, y1)))
    for name, x0, x1 in LAST:
        crops.append((name, tighten(arr, x0, x1, LAST_Y[0], LAST_Y[1])))

    tiles = []
    for name, box in crops:
        c = im.crop(box)
        c = c.resize((c.size[0] * 2, c.size[1] * 2), Image.LANCZOS)
        c.save(os.path.join(OUT, name + ".png"))
        tiles.append((name, c))
        print("%-26s %s" % (name, box))

    # Montajul de control: 6 pe rand, fiecare redus in celula.
    cell_w, cell_h = 220, 200
    cols = 6
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (BG, BG, BG))
    dr = ImageDraw.Draw(sheet)
    for i, (name, c) in enumerate(tiles):
        t = c.copy()
        t.thumbnail((cell_w - 10, cell_h - 30))
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        sheet.paste(t, (x + (cell_w - t.size[0]) // 2, y + 4))
        dr.text((x + 6, y + cell_h - 22), name, fill=(20, 20, 20))
    sheet.save(os.path.join(OUT, "_control.png"))
    print("decupari:", len(tiles))


if __name__ == "__main__":
    main()
