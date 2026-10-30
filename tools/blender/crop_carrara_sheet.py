"""Decupari per piesa din planșele de inventar Carrara (v0.1), marite 2x.

    python tools/blender/crop_carrara_sheet.py

Citeste docs/track_briefs/img/carrara_plan/inventar_v01_a.jpg (planșa ACCEPTATA)
si inventar_v01_b.jpg (a doua generare, referinta suplimentara pentru utilaje si
creasta) si scrie docs/track_briefs/img/carrara_assets_v1/<nume>.png, plus
montajul de control _control.png (toate decuparile, cu nume).

Spre deosebire de crop_transfagarasan_sheet.py, randurile planșei nu au celule
egale (viaductul ocupa un rand intreg, blocurile mici stau cate noua pe rand),
deci fiecare piesa are caseta ei data explicit, FARA eticheta, masurata pe
planșa 1024 x 1536. Decuparea se strange apoi pe pixelii care difera de fundal
(gri ~200, esantionat din colt). Din planșa b se scot doar piesele care acolo
sunt desenate mai mare sau mai clar: sufixul `_b`.
"""
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PLAN = os.path.join(ROOT, "docs", "track_briefs", "img", "carrara_plan")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "carrara_assets_v1")
DIFF = 28
PAD = 6

# (nume, (x0, y0, x1, y1)) pe planșa a, fara eticheta de sub piesa.
SHEET_A = [
    ("ponti_di_vara", (30, 0, 1000, 246)),
    ("gallery_pillar", (55, 250, 160, 500)),
    ("colonnata_church", (200, 246, 495, 502)),
    ("derrick", (515, 270, 760, 502)),
    ("gallery_portal", (775, 315, 1005, 503)),
    ("marmifera_portal", (10, 535, 250, 708)),
    ("quarry_truck", (265, 550, 485, 708)),
    ("quarry_excavator", (510, 530, 820, 708)),
    ("drill_rig", (835, 535, 990, 710)),
    ("marble_block_hooked", (45, 725, 160, 872)),
    ("lizza_sled", (185, 750, 395, 872)),
    ("wire_saw", (395, 735, 665, 872)),
    ("chain_saw_crawler", (675, 750, 1005, 876)),
    ("museum_set", (15, 925, 295, 1036)),
    ("quarry_sign_block", (320, 945, 415, 1036)),
    ("colonnata_house_a", (430, 895, 625, 1036)),
    ("colonnata_house_b", (635, 900, 805, 1038)),
    ("colonnata_house_c", (820, 900, 1010, 1038)),
    ("marble_block_a", (30, 1105, 95, 1166)),
    ("marble_block_b", (110, 1085, 190, 1166)),
    ("marble_block_c", (205, 1065, 310, 1166)),
    ("block_stack_a", (335, 1075, 405, 1167)),
    ("block_stack_b", (435, 1065, 510, 1167)),
    ("block_informe_a", (540, 1080, 635, 1168)),
    ("block_informe_b", (655, 1090, 750, 1168)),
    ("rubble_pile_a", (765, 1095, 885, 1170)),
    ("rubble_pile_b", (895, 1095, 1005, 1170)),
    ("safety_berm", (10, 1250, 145, 1318)),
    ("work_lamp", (140, 1215, 210, 1318)),
    ("cable_reel", (215, 1225, 305, 1318)),
    ("water_tank", (315, 1215, 400, 1318)),
    ("fuel_tank", (398, 1225, 510, 1318)),
    ("office_container", (510, 1235, 630, 1318)),
    ("quarry_sign_a", (655, 1240, 725, 1320)),
    ("quarry_sign_b", (735, 1230, 795, 1320)),
    ("pipe_run", (800, 1235, 910, 1318)),
    ("_scale_car", (915, 1265, 1005, 1318)),
    ("apuan_ridge", (15, 1340, 1010, 1500)),
]

# Petice de eticheta vecina care intra in caseta unei piese: se vopsesc cu
# fundalul inainte de decupare (eticheta viaductului atinge varful crucii).
ERASE = {"inventar_v01_a.jpg": [(440, 244, 560, 262)]}

# Planșa b: utilajele desenate mai mare si creasta cu mai multe varfuri.
SHEET_B = [
    ("quarry_truck_b", (10, 85, 240, 242)),
    ("quarry_excavator_b", (260, 55, 575, 242)),
    ("wire_saw_b", (250, 295, 505, 422)),
    ("chain_saw_crawler_b", (520, 290, 835, 436)),
    ("drill_rig_b", (835, 265, 1005, 466)),
    ("apuan_ridge_b", (5, 1265, 1015, 1495)),
]


def tighten(img: Image.Image, box):
    """Strange caseta pe pixelii care difera de fundal (+PAD)."""
    x0, y0, x1, y1 = box
    a = np.asarray(img.crop(box).convert("RGB")).astype(int)
    bg = np.asarray(img.crop((2, 2, 12, 12)).convert("RGB")).reshape(-1, 3).mean(0)
    m = np.abs(a - bg).sum(2) > DIFF
    ys, xs = np.nonzero(m)
    if len(xs) == 0:
        return box
    return (max(x0, x0 + xs.min() - PAD), max(y0, y0 + ys.min() - PAD),
            min(x1, x0 + xs.max() + PAD + 1), min(y1, y0 + ys.max() + PAD + 1))


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    crops = []
    for sheet, items in (("inventar_v01_a.jpg", SHEET_A), ("inventar_v01_b.jpg", SHEET_B)):
        img = Image.open(os.path.join(PLAN, sheet)).convert("RGB")
        bg = tuple(int(v) for v in np.asarray(img.crop((2, 2, 12, 12))).reshape(-1, 3).mean(0))
        for rect in ERASE.get(sheet, []):
            ImageDraw.Draw(img).rectangle(rect, fill=bg)
        for name, box in items:
            c = img.crop(tighten(img, box))
            c = c.resize((c.width * 2, c.height * 2), Image.LANCZOS)
            c.save(os.path.join(OUT, name + ".png"))
            crops.append((name, c))
    # Montaj de control: celule de 260 x 220, cu numele dedesubt.
    cw, ch, cols = 260, 220, 6
    rows = (len(crops) + cols - 1) // cols
    sheet = Image.new("RGB", (cw * cols, ch * rows), (200, 200, 200))
    dr = ImageDraw.Draw(sheet)
    for i, (name, c) in enumerate(crops):
        t = c.copy()
        t.thumbnail((cw - 10, ch - 26))
        x, y = (i % cols) * cw, (i // cols) * ch
        sheet.paste(t, (x + (cw - t.width) // 2, y + 4))
        dr.text((x + 6, y + ch - 18), name, fill=(0, 0, 0))
    sheet.save(os.path.join(OUT, "_control.png"))
    print("scris:", len(crops), "decupari +", os.path.join(OUT, "_control.png"))


if __name__ == "__main__":
    main()
