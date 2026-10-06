"""Decupari per piesa din planșa de inventar Monument Valley (v0.2), marite 2x.

    python tools/blender/crop_monument_sheet.py

Citeste docs/track_briefs/img/monument_plan/inventar_v02.jpg si scrie
docs/track_briefs/img/monument_assets_v1/<nume>.png, plus montajul de control
_control.png (toate decuparile, cu nume).

Spre deosebire de crop_kyoto_sheet.py, cutiile NU sunt masurate de mana: benzile
de rand si centrele etichetelor s-au masurat pe planșa 1024 x 1536 (fundal gri
200), iar fiecare piesa primeste coloanele dintre mijloacele etichetelor
vecine. Decuparea se strange apoi pe pixelii care difera de fundal.
"""
import os
from PIL import Image, ImageDraw
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "docs", "track_briefs", "img", "monument_plan", "inventar_v02.jpg")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "monument_assets_v1")
BG = 200
DIFF = 40

# Rand: (y_sus, y_jos fara eticheta), apoi (nume, centrul etichetei pe x).
ROWS = [
    ((19, 236), [("west_mitten", 146), ("east_mitten", 404), ("merrick_butte", 633),
                 ("mesa_wall_module", 879)]),
    ((300, 443), [("sandstone_arch", 124), ("butte_small_a", 352), ("butte_small_b", 520),
                  ("butte_small_c", 696), ("rock_fin", 843), ("hoodoo", 956)]),
    ((504, 619), [("talus_boulders_a", 90), ("talus_boulders_b", 272), ("sagebrush", 425),
                  ("juniper", 573), ("yucca", 711), ("rabbitbrush", 835), ("tumbleweed", 960)]),
    ((674, 864), [("open_range_sign", 72), ("cattle_guard", 207), ("telegraph_pole", 343),
                  ("wire_fence", 478), ("trading_post", 653), ("water_tower", 825),
                  ("windmill_pump", 950)]),
    ((935, 1054), [("homestead_house", 93), ("hogan", 254), ("corral", 415),
                   ("shade_ramada", 577), ("pickup_old", 759), ("tour_truck", 935)]),
    ((1119, 1240), [("tourist_group", 117), ("horse_bay", 285), ("horse_pinto", 445),
                    ("horse_black", 619), ("sheep", 776), ("raven", 933)]),
]
# Fundalul ocupa tot randul, cu masinuta de scara in dreapta-jos (x >= 940).
HORIZON = ("horizon_mesas", (1312, 1461), (0, 938))


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
    for (y0, y1), pieces in ROWS:
        centers = [c for _, c in pieces]
        for i, (name, c) in enumerate(pieces):
            x0 = 0 if i == 0 else (centers[i - 1] + c) // 2
            x1 = W if i == len(pieces) - 1 else (c + centers[i + 1]) // 2
            crops.append((name, tighten(arr, x0, x1, y0, y1)))
    name, (y0, y1), (x0, x1) = HORIZON
    crops.append((name, tighten(arr, x0, x1, y0, y1)))

    tiles = []
    for name, box in crops:
        c = im.crop(box)
        c = c.resize((c.size[0] * 2, c.size[1] * 2), Image.LANCZOS)
        c.save(os.path.join(OUT, name + ".png"))
        tiles.append((name, c))
        print("%-18s %s" % (name, box))

    # Montajul de control: 6 pe rand, fiecare redus la 160 px inaltime.
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
