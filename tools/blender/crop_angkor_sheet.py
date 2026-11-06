"""Decupari per piesa din planșele de inventar Angkor (v0.1), marite 2x.

    python tools/blender/crop_angkor_sheet.py

Citeste cele trei generari din docs/track_briefs/img/angkor_plan/:
- inventar_v01_a.jpg  — prima planșa (de aici se ia DOAR `tuk_tuk`: remork cu
  remorca separata de motocicleta, adica tuk-tuk-ul cambodgian);
- inventar_v01_b.jpg  — planșa ACCEPTATA ca baza (mai mult detaliu pictat);
- inventar_v01_c.jpg  — corectura: turnurile Bayonului ca TURNURI, uriasii
  care tin naga, Regele Lepros fara poza de meditatie, Angkor Wat fara fete.
si scrie docs/track_briefs/img/angkor_assets_v1/<nume>.png, plus montajul de
control _control.png (toate decuparile, cu nume si sursa).

Fiecare rand al planșei are intervalul lui pe Y (FARA eticheta de sub piese,
masurat pe planșa); pe X piesele se separa automat dupa coloanele goale ale
mastii (pixeli care difera de fundalul randului). Numarul de piese gasite
trebuie sa fie exact cel al numelor din rand, altfel scriptul se opreste.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PLAN = os.path.join(ROOT, "docs", "track_briefs", "img", "angkor_plan")
OUT = os.path.join(ROOT, "docs", "track_briefs", "img", "angkor_assets_v1")
DIFF = 34      # distanta L1 fata de fundal peste care pixelul e piesa
MIN_GAP = 6    # coloane goale consecutive care despart doua piese
MIN_COL = 3    # pixeli de masca pe coloana ca sa conteze
MIN_W = 14     # segmente mai inguste sunt zgomot (umbre, puncte)
PAD = 6

ROWS_B = [
    ((0, 186), ["angkor_wat_temple", "aw_west_gopura", "south_gate_face_tower",
                "ta_prohm_tree_gate"]),
    ((213, 347), ["bayon_face_tower_a", "bayon_face_tower_b", "bayon_face_tower_c",
                  "elephant_terrace_end", "leper_king_statue", "giant_root_ramp",
                  "srah_srang_landing"]),
    ((375, 468), ["asian_elephant", "tuk_tuk", "monk_standing", "gallery_column",
                  "gallery_roof", "gallery_relief_wall", "gallery_corner", "_scale_car"]),
    ((498, 600), ["naga_balustrade", "naga_balustrade_gap", "naga_head", "deva_giant",
                  "asura_giant", "elephant_terrace_module", "elephant_trunk_pillar"]),
    ((627, 712), ["bakheng_terrace_tier", "bakheng_shrine_tower", "bakheng_side_stair",
                  "vault_intact", "vault_broken", "fallen_block", "restoration_prop",
                  "laterite_block", "rubble_pile", "numbered_block"]),
    ((736, 885), ["tetrameles_a", "tetrameles_b", "strangler_fig", "sugar_palm",
                  "dipterocarp", "vine_strands", "lotus_cluster", "water_lily_pads"]),
    ((918, 1002), ["angkor_horizon"]),
]
ROWS_A = [
    ((12, 252), ["angkor_wat_temple", "aw_west_gopura", "south_gate_face_tower",
                 "ta_prohm_tree_gate"]),
    ((304, 380), ["bayon_face_tower_a", "bayon_face_tower_b", "bayon_face_tower_c",
                  "elephant_terrace_end", "leper_king_statue", "giant_root_ramp",
                  "srah_srang_landing"]),
    ((426, 499), ["asian_elephant", "tuk_tuk", "monk_standing", "gallery_column",
                  "gallery_roof", "gallery_relief_wall", "gallery_corner", "_scale_car"]),
]
ROWS_C = [
    ((5, 496), ["bayon_face_tower_a", "bayon_face_tower_b", "bayon_face_tower_c"]),
    ((543, 898), ["deva_giant", "asura_giant", "leper_king_statue"]),
    ((945, 1400), ["angkor_wat_temple"]),
]

# Ce se ia din fiecare planșa. Restul din b.
FROM_A = {"tuk_tuk"}
FROM_C = {"bayon_face_tower_a", "bayon_face_tower_b", "bayon_face_tower_c",
          "deva_giant", "asura_giant", "leper_king_statue", "angkor_wat_temple"}


def segments(img: np.ndarray, y0: int, y1: int):
    band = img[y0:y1].astype(int)
    # Fundalul are vignetare: se esantioneaza la capetele randului.
    edge = np.concatenate([band[:, :6].reshape(-1, 3), band[:, -6:].reshape(-1, 3)])
    bg = np.median(edge, axis=0)
    mask = np.abs(band - bg).sum(2) > DIFF
    cols = mask.sum(0) >= MIN_COL
    segs, start, gap = [], None, 0
    for x in range(len(cols) + MIN_GAP):
        on = cols[x] if x < len(cols) else False
        if on:
            if start is None:
                start = x
            gap = 0
            last = x
        elif start is not None:
            gap += 1
            if gap >= MIN_GAP:
                if last - start + 1 >= MIN_W:
                    segs.append((start, last + 1))
                start, gap = None, 0
    out = []
    for x0, x1 in segs:
        sub = mask[:, x0:x1]
        ys = np.where(sub.any(1))[0]
        out.append((x0, y0 + ys[0], x1, y0 + ys[-1] + 1))
    return out


def crop_sheet(fname: str, rows, wanted=None):
    img = np.asarray(Image.open(os.path.join(PLAN, fname)).convert("RGB"))
    pil = Image.fromarray(img)
    h, w, _ = img.shape
    got = {}
    for (y0, y1), names in rows:
        segs = segments(img, y0, y1)
        if len(segs) != len(names):
            sys.exit(f"{fname} rand {y0}-{y1}: {len(segs)} piese gasite, {len(names)} nume: {segs}")
        for name, (x0, ya, x1, yb) in zip(names, segs):
            if wanted is not None and name not in wanted:
                continue
            # Pe Y caseta nu iese din rand: deasupra si dedesubt sunt etichetele.
            box = (max(0, x0 - PAD), max(y0, ya - PAD), min(w, x1 + PAD), min(y1, yb + PAD))
            c = pil.crop(box)
            got[name] = (c.resize((c.width * 2, c.height * 2), Image.LANCZOS), fname, box)
    return got


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    pieces = crop_sheet("inventar_v01_b.jpg", ROWS_B)
    pieces.update(crop_sheet("inventar_v01_a.jpg", ROWS_A, FROM_A))
    pieces.update(crop_sheet("inventar_v01_c.jpg", ROWS_C, FROM_C))
    for name, (im, src, box) in sorted(pieces.items()):
        im.save(os.path.join(OUT, f"{name}.png"))
        print(f"{name:26s} {src}  {tuple(int(v) for v in box)}")
    # Montajul de control: celule de 300 x 260, 6 pe rand.
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
