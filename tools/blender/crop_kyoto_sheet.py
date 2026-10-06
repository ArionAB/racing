"""Decupari per piesa din planșa de inventar Kyoto (v0.2), marite 2x.

    python tools/blender/crop_kyoto_sheet.py

Citeste docs/track_briefs/img/kyoto_plan/inventar_v02.jpg si scrie
docs/track_briefs/img/kyoto_assets_v1/<nume>.png, plus montajul de control
_control.png (toate decuparile, cu nume). Cutiile (x0, x1) sunt masurate pe
planșa 1024 x 1536; pe verticala fiecare rand are limitele lui, iar
decuparea se strange automat pe pixelii care difera de fundal.
"""
import os
from PIL import Image, ImageDraw
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "docs", "track_briefs", "img", "kyoto_plan", "inventar_v02.jpg")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "kyoto_assets_v1")

# (y_sus, y_jos_fara_eticheta) per rand
ROWS = {
    1: (3, 142), 2: (160, 296), 3: (318, 426), 4: (446, 552), 5: (574, 659),
    6: (683, 796), 7: (820, 933), 8: (958, 1065), 9: (1087, 1195),
    10: (1219, 1296), 11: (1322, 1387), 12: (1405, 1486),
}

# nume: (rand, x0, x1)
PIECES = {
    "yasaka_pagoda": (1, 240, 365), "sanjunoto_pagoda": (1, 480, 605),
    "koyasu_pagoda": (1, 715, 830),
    "kiyomizu_hondo": (2, 135, 440), "kakezukuri_scaffold": (2, 500, 675),
    "niomon_gate": (2, 745, 940),
    "inari_romon": (3, 95, 292), "votive_torii_cluster": (3, 350, 625),
    "kitsune_statue": (3, 730, 915),
    "kitsune_statue_a": (3, 730, 822), "kitsune_statue_b": (3, 826, 915),
    "kinkakuji": (4, 285, 480), "yukimi_lantern": (4, 655, 720),
    "tsutenkyo_roof_module": (5, 95, 374), "togetsukyo_module": (5, 412, 692),
    "iron_truss_bridge": (5, 722, 990),
    "machiya_a": (6, 76, 184), "machiya_b": (6, 193, 279),
    "machiya_c": (6, 284, 390), "machiya_d": (6, 396, 507),
    "machiya_e": (6, 510, 615), "teahouse_front": (6, 630, 748),
    "paper_lantern": (6, 750, 815), "temple_wall": (6, 835, 1006),
    "stone_lantern_a": (7, 100, 170), "stone_lantern_b": (7, 210, 287),
    "small_shrine": (7, 300, 397), "ema_rack": (7, 410, 518),
    "bell_tower": (7, 522, 660), "chozuya": (7, 665, 795),
    "cyclopean_wall": (7, 800, 1006),
    "momiji_a": (8, 105, 245), "momiji_b": (8, 262, 410),
    "momiji_c": (8, 430, 570), "ginkgo": (8, 600, 725),
    "niwaki_pine": (8, 750, 920),
    "moso_culm": (9, 20, 108), "bamboo_crown": (9, 112, 216),
    "shiba_fence": (9, 217, 312), "karikomi_shrub_a": (9, 318, 384),
    "karikomi_shrub_b": (9, 392, 470), "garden_rock_a": (9, 484, 552),
    "garden_rock_b": (9, 570, 640), "garden_rock_c": (9, 652, 712),
    "stepping_stones": (9, 725, 810), "moss_mound": (9, 808, 902),
    "leaf_pile": (9, 905, 1006),
    "sagano_train": (10, 88, 497), "jinrikisha": (10, 532, 628),
    "yakatabune": (10, 665, 852), "monk_sweeper": (10, 882, 950),
    "sika_deer_stand": (11, 190, 268), "sika_deer_graze": (11, 314, 390),
    "sika_deer_bow": (11, 412, 495), "crow": (11, 648, 765),
    "horizon_Higashiyama_A": (12, 50, 287),
    "horizon_Higashiyama_B": (12, 288, 512),
    "horizon_Arashiyama_A": (12, 515, 755),
    "horizon_FarRoofs_A": (12, 758, 1005),
}


# piese care trec peste linia de separare de deasupra: cate px urcam cutia
TOP_EXT = {"kinkakuji": 4, "momiji_a": 8, "ginkgo": 8, "sika_deer_stand": 8,
           "moso_culm": 5}


def main():
    sheet = Image.open(SRC).convert("RGB")
    arr = np.array(sheet).astype(int)
    os.makedirs(OUT, exist_ok=True)
    # masina de scara (icoana gri din stanga fiecarui rand) nu e piesa
    car = {r: None for r in ROWS}
    done = []
    for name, (row, x0, x1) in PIECES.items():
        y0, y1 = ROWS[row]
        y0 -= TOP_EXT.get(name, 0)
        sub = arr[y0:y1, x0:x1]
        # fundalul: mediana pe marginea de sus a cutiei
        bg = np.median(sub[:4].reshape(-1, 3), axis=0)
        fg = np.abs(sub - bg).max(axis=2) > 30
        erase = None
        if name == "stepping_stones":
            # marginea movilei de muschi (verde) intra in cutie, sub piatra de sus
            erase = np.zeros_like(fg)
            erase[1160 - y0:, 798 - x0:] = True
            fg &= ~erase
        if name == "moss_mound":
            # varful pietrei de la stepping_stones intra in colt
            fg[: 1156 - y0, : 824 - x0] = False
            erase = np.zeros_like(fg)
            erase[: 1156 - y0, : 824 - x0] = True
        # puncte rătăcite (≤2 px pe coloană/rând) nu conteaza la strangere
        fg &= ~(fg.sum(axis=1) > 0.9 * fg.shape[1])[:, None]  # linii de separare
        colok = fg.sum(axis=0) >= 3
        rowok = fg.sum(axis=1) >= 3
        fg &= colok[None, :] & rowok[:, None]
        ys, xs = np.where(fg)
        if "moso_culm" == name:
            keep = ~((xs < 55) & (ys > 60))
            ys, xs = ys[keep], xs[keep]
        if len(xs) == 0:
            print("GOL:", name)
            continue
        pad = 6
        if (xs.min() == 0 or xs.max() == x1 - x0 - 1 or ys.min() == 0
                or ys.max() == y1 - y0 - 1):
            print("ATINGE MARGINEA CUTIEI:", name,
                  (xs.min() == 0, xs.max() == x1 - x0 - 1,
                   ys.min() == 0, ys.max() == y1 - y0 - 1))
        cx0 = max(x0 + xs.min() - pad, x0)
        cx1 = min(x0 + xs.max() + pad + 1, x1)
        cy0 = max(y0 + ys.min() - pad, y0)
        cy1 = min(y0 + ys.max() + pad + 1, y1)
        work = sheet
        if erase is not None:
            work = sheet.copy()
            wp = work.load()
            for yy, xx in zip(*np.where(erase)):
                wp[x0 + int(xx), y0 + int(yy)] = tuple(int(v) for v in bg)
        crop = work.crop((cx0, cy0, cx1, cy1))
        if name == "moso_culm":
            # sterge icoana masinii care intra in cutie
            px = crop.load()
            for yy in range(crop.height):
                for xx in range(crop.width):
                    if cx0 + xx < 76 and cy0 + yy > 1160:
                        px[xx, yy] = tuple(int(v) for v in bg)
        big = crop.resize((crop.width * 2, crop.height * 2), Image.LANCZOS)
        big.save(os.path.join(OUT, name + ".png"))
        done.append((name, big))
    # montaj de control
    cell_h = 300
    cells = []
    for name, im in done:
        s = cell_h / im.height if im.height > cell_h else 1.0
        if im.width * s > 420:
            s = 420 / im.width
        t = im.resize((max(int(im.width * s), 1), max(int(im.height * s), 1)))
        cells.append((name, t))
    W = 1800
    x = y = 0
    rowh = 0
    pos = []
    for name, t in cells:
        if x + t.width + 8 > W:
            x = 0
            y += rowh + 22
            rowh = 0
        pos.append((name, t, x, y))
        x += t.width + 8
        rowh = max(rowh, t.height)
    H = y + rowh + 22
    mont = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(mont)
    for name, t, px_, py_ in pos:
        mont.paste(t, (px_, py_ + 14))
        d.text((px_ + 2, py_), name, fill=(200, 0, 0))
    mont.save(os.path.join(OUT, "_control.png"))
    print("decupari:", len(done), "montaj:", mont.size)


if __name__ == "__main__":
    main()
