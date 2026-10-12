"""Decupari per piesa din planșa de inventar Okinawa (v0.2), marite 2x.

    python tools/blender/crop_okinawa_sheet.py

Citeste docs/track_briefs/img/okinawa_plan/inventar_v02.jpg si scrie
docs/track_briefs/img/okinawa_assets_v1/<nume>.png, plus montajul de control
_control.png (toate decuparile, cu nume).

Tiparul e crop_monument_sheet.py: benzile de rand si centrele etichetelor s-au
masurat pe planșa 1024 x 1536 (fundal gri ~201; etichetele = pixeli < 90 pe
benzi de <= 22 px), iar fiecare piesa primeste coloanele dintre mijloacele
etichetelor vecine. Decuparea se strange apoi pe pixelii care difera de fundal.
"""
import os
from PIL import Image, ImageDraw
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "docs", "track_briefs", "img", "okinawa_plan", "inventar_v02.jpg")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "okinawa_assets_v1")
BG = 201
DIFF = 40

# Rand: (y_sus, y_jos fara eticheta), apoi (nume, centrul etichetei pe x).
ROWS = [
    ((13, 149), [("ryukyu_palace", 113), ("ryukyu_gate", 323), ("gusuku_wall_curve", 513),
                 ("gusuku_wall_straight", 709), ("gusuku_arch_gate", 914)]),
    ((168, 301), [("cape_lighthouse", 112), ("heart_rock", 317), ("island_ferry", 512),
                  ("coastal_freighter", 712), ("ryukyu_house_a", 911)]),
    ((322, 447), [("ryukyu_house_b", 118), ("ryukyu_house_c", 313), ("concrete_house_a", 513),
                  ("concrete_house_b", 715), ("harbour_quay", 914)]),
    ((466, 610), [("bus_stop_shelter", 109), ("notch_rock_a", 313), ("notch_rock_b", 509),
                  ("notch_rock_c", 716), ("limestone_cliff_module", 916)]),
    ((632, 772), [("coral_stone_wall", 115), ("tetrapod", 313), ("fukugi_tree_a", 511),
                  ("fukugi_tree_b", 708), ("fukugi_tree_c", 915)]),
    ((794, 930), [("banyan", 111), ("ryukyu_pine", 315), ("pandanus", 514),
                  ("cycad", 709), ("fan_palm", 916)]),
    ((953, 1064), [("hibiscus", 113), ("bougainvillea", 318), ("sugar_cane_field_patch", 514),
                   ("vending_machine", 719), ("convex_mirror", 916)]),
    ((1094, 1212), [("fishing_net_rack", 109), ("float_pile", 316), ("sabani_canoe", 511),
                    ("fishing_boat", 711), ("water_buffalo", 914)]),
    ((1239, 1360), [("egret", 107), ("sea_turtle", 319), ("shisa_pair", 511),
                    ("waterspout", 714), ("wave_crest", 911)]),
    # Ultimul rand: mașinuța de scara sta in dreapta (x >= 860), in afara lui.
    ((1383, 1502), [("storm_wall", 128), ("ie_island", 375), ("kerama_islands", 605)]),
]
LAST_ROW_X1 = 860


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
        right = LAST_ROW_X1 if r == len(ROWS) - 1 else W
        for i, (name, c) in enumerate(pieces):
            x0 = 0 if i == 0 else (centers[i - 1] + c) // 2
            x1 = right if i == len(pieces) - 1 else (c + centers[i + 1]) // 2
            crops.append((name, tighten(arr, x0, x1, y0, y1)))

    tiles = []
    for name, box in crops:
        c = im.crop(box)
        c = c.resize((c.size[0] * 2, c.size[1] * 2), Image.LANCZOS)
        c.save(os.path.join(OUT, name + ".png"))
        tiles.append((name, c))
        print("%-24s %s" % (name, box))

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
