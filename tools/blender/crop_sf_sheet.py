"""Decupari per piesa din planșele de inventar San Francisco (v0.1), marite 2x.

    python tools/blender/crop_sf_sheet.py

Citeste din docs/asset_briefs/img/sf_route/:
- sf_inventar_v01_a.jpg            — planșa acceptata (podul si vagonul trec);
- sf_inventar_v01_b_chiparosi.jpg  — corectura: chiparosii aplecati de vant si
  inelul de fundal (de aici se iau DOAR `sf_cypress_a/b/c` si `sf_horizon`).
si scrie docs/track_briefs/img/sf_assets_v1/<nume>.png, plus montajul de control
_control.png. Pe tiparul crop_angkor_sheet.py (aceeasi segmentare pe coloane
goale); randul caselor se taie pe X explicit, fiindca piesele se ating.

Decuparea e referinta de FORMA si CULOARE a fiecarei piese (memoria
blender-fidelitate-fata-de-plansa); cotele vin din brief. Podul din DIORAMA nu e
referinta de forma (prea aproape de cel real) — cel din planșa, generic, este.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from crop_angkor_sheet import PAD, segments  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
PLAN = os.path.join(ROOT, "docs", "asset_briefs", "img", "sf_route")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "sf_assets_v1")

# (interval Y fara etichete, nume, taieturi X explicite sau None = automat).
# Numele cu `_` in fata se sar (in afara de `_scale_car`).
ROWS_A = [
    ((0, 225), ["sf_bridge_tower", "sf_bridge_deck_8", "sf_bridge_parapet_8",
                "sf_bridge_walkway_8", "sf_bridge_flares", "sf_bridge_cable_main",
                "sf_bridge_cable_side", "sf_bridge_anchor", "sf_bridge_lamp"], None),
    ((245, 392), ["cable_car", "sf_median_truck", "sf_median_block", "sf_parked_sedan",
                  "sf_parked_wagon", "sf_parked_van", "sf_row_a_canted",
                  "sf_row_a_square", "sf_row_b_canted"], None),
    ((412, 578), ["sf_row_b_square", "sf_row_c_canted", "sf_row_c_square",
                  "sf_row_corner_turret", "sf_painted_lady_a", "sf_painted_lady_b",
                  "sf_painted_lady_c", "sf_painted_lady_d", "sf_painted_lady_e",
                  "sf_painted_lady_f"],
     [(8, 162), (166, 308), (318, 462), (468, 612), (616, 768), (770, 918),
      (924, 1072), (1076, 1224), (1228, 1378), (1382, 1526)]),
    ((605, 733), ["sf_front_garden", "sf_pier_shed", "sf_turntable", "sf_dragon_gate",
                  "sf_signal_mast", "sf_street_lamp", "sf_street_props",
                  "sf_trolley_pole"], None),
    ((760, 872), ["sf_bench", "sf_bike_rack", "sf_crab_traps", "sf_stair_lane",
                  "_cypress_a_vechi", "_cypress_bc_vechi", "sf_hydrangea",
                  "sf_street_tree"], None),
    ((900, 995), ["sf_sea_lions", "sf_seagull", "sf_parrot", "_horizon_vechi",
                  "_scale_car"], None),
]
ROWS_B = [
    # a si b se ating pe planșa: taieturi explicite (se suprapun cativa pixeli)
    ((80, 525), ["sf_cypress_a", "sf_cypress_b", "sf_cypress_c"],
     [(30, 535), (503, 1150), (1157, 1510)]),
    ((650, 880), ["sf_horizon"], None),
]


def crop_sheet(fname, rows):
    img = np.asarray(Image.open(os.path.join(PLAN, fname)).convert("RGB"))
    pil = Image.fromarray(img)
    h, w, _ = img.shape
    got = {}
    for (y0, y1), names, xs in rows:
        if xs is None:
            segs = segments(img, y0, y1)
        else:
            segs = [(x0, y0, x1, y1) for x0, x1 in xs]
        if len(segs) != len(names):
            sys.exit(f"{fname} rand {y0}-{y1}: {len(segs)} piese gasite, "
                     f"{len(names)} nume: {segs}")
        for name, (x0, ya, x1, yb) in zip(names, segs):
            if name.startswith("_") and name != "_scale_car":
                continue
            box = (max(0, x0 - PAD), max(y0, ya - PAD), min(w, x1 + PAD), min(y1, yb + PAD))
            c = pil.crop(box)
            got[name] = (c.resize((c.width * 2, c.height * 2), Image.LANCZOS), fname, box)
    return got


def main():
    os.makedirs(OUT, exist_ok=True)
    pieces = crop_sheet("sf_inventar_v01_a.jpg", ROWS_A)
    pieces.update(crop_sheet("sf_inventar_v01_b_chiparosi.jpg", ROWS_B))
    for name, (im, src, box) in sorted(pieces.items()):
        im.save(os.path.join(OUT, f"{name}.png"))
        print(f"{name:24s} {src}  {tuple(int(v) for v in box)}")
    cw, ch, per = 300, 260, 6
    names = sorted(pieces)
    rows = (len(names) + per - 1) // per
    sheet = Image.new("RGB", (cw * per, ch * rows), (230, 230, 230))
    dr = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        im, src, _ = pieces[name]
        t = im.copy()
        t.thumbnail((cw - 10, ch - 34))
        cx, cy = (i % per) * cw, (i // per) * ch
        sheet.paste(t, (cx + (cw - t.width) // 2, cy + 4))
        dr.text((cx + 6, cy + ch - 26), f"{name}  [{src[-5]}]", fill=(0, 0, 0))
    sheet.save(os.path.join(OUT, "_control.png"))
    print(f"{len(pieces)} decupari -> {OUT}")


if __name__ == "__main__":
    main()
