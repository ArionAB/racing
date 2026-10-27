"""Decupari per piesa din planșa de inventar Fiordland (v1), marite 3x.

    python tools/blender/crop_fiordland_sheet.py

Citeste docs/track_briefs/img/fiordland_assets_v1.jpg (683 x 2048) si scrie
docs/track_briefs/img/fiordland_assets_v1/<nume>.png, plus montajul de control
_control.png (toate decuparile, cu nume).

Tiparul e crop_okinawa_sheet.py, dar planșa Fiordland are separatoare
orizontale pline (fundal ~197), deci benzile vin de acolo, iar coloanele s-au
masurat ca rulari de pixeli diferiti de fundal deasupra etichetei. Masinuta de
scara din stanga fiecarui rand e lasata pe dinafara. Decuparea se strange apoi
pe pixelii care difera de fundal.
"""
import os
from PIL import Image, ImageDraw
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "docs", "track_briefs", "img", "fiordland_assets_v1.jpg")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "fiordland_assets_v1")
BG = 197
DIFF = 40
SCALE = 3

# Rand: (y_sus, y_jos deasupra etichetei), apoi (nume, x0, x1).
ROWS = [
    ((2, 205), [("stirling_ledge", 60, 432), ("torrent_chute", 440, 648)]),
    ((238, 378), [("traffic_light_pole", 92, 202), ("snow_pole", 276, 305),
                  ("guard_rock", 352, 452), ("road_sign_blank", 486, 606)]),
    ((412, 536), [("FarWall_A", 50, 296), ("SnowRidge_A", 297, 415),
                  ("SnowRidge_B", 415, 528), ("CloudBank_A", 529, 678)]),
    ((570, 682), [("wharf", 48, 195), ("cafe_shed", 207, 304), ("heli_pad", 309, 410),
                  ("lodge", 422, 577), ("luggage_container", 583, 678)]),
    ((714, 805), [("cruise_boat", 62, 276), ("kayak_a", 292, 374), ("kayak_b", 389, 471),
                  ("driftwood", 491, 653)]),
    ((840, 950), [("bush_plane", 97, 340), ("coach_fiordland", 370, 566)]),
    ((983, 1145), [("beech_a", 66, 178), ("beech_b", 180, 300), ("beech_c", 302, 425),
                   ("beech_dead", 438, 535), ("rata_tree", 545, 652)]),
    ((1178, 1295), [("fern_clump_a", 67, 186), ("fern_clump_b", 193, 311),
                    ("tussock_clump", 320, 424), ("stump", 440, 530), ("chasm_rock", 540, 668)]),
    ((1328, 1450), [("chasm_bridge_rail", 92, 574)]),
    ((1483, 1640), [("tree_avalanche", 64, 452), ("scree_slab", 459, 667)]),
    ((1673, 1790), [("kea", 150, 381), ("penguin_tawaki", 437, 499)]),
]


def tighten(arr, x0, x1, y0, y1):
    sub = np.abs(arr[y0:y1, x0:x1] - BG).sum(axis=2) > DIFF
    ys, xs = np.nonzero(sub)
    if len(xs) == 0:
        return (x0, y0, x1, y1)
    return (max(x0, x0 + xs.min() - 4), max(y0, y0 + ys.min() - 4),
            min(x1, x0 + xs.max() + 5), min(y1, y0 + ys.max() + 5))


def main():
    im = Image.open(SRC).convert("RGB")
    arr = np.asarray(im).astype(int)
    os.makedirs(OUT, exist_ok=True)
    crops = []
    for (y0, y1), pieces in ROWS:
        for name, x0, x1 in pieces:
            box = tighten(arr, x0, x1, y0, y1)
            c = im.crop(box)
            c = c.resize((c.width * SCALE, c.height * SCALE), Image.LANCZOS)
            c.save(os.path.join(OUT, name + ".png"))
            crops.append((name, c))
            print(name, box)
    # montaj de control: 5 pe rand, celule de 420 x 360
    cw, ch, n = 420, 380, 5
    rows = (len(crops) + n - 1) // n
    sheet = Image.new("RGB", (cw * n, ch * rows), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    for i, (name, c) in enumerate(crops):
        t = c.copy()
        t.thumbnail((cw - 10, ch - 30))
        x, y = (i % n) * cw, (i // n) * ch
        sheet.paste(t, (x + 5, y + 5))
        d.text((x + 8, y + ch - 22), name, fill=(255, 255, 255))
    sheet.save(os.path.join(OUT, "_control.png"))


if __name__ == "__main__":
    main()
