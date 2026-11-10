#!/usr/bin/env python3
"""Amesteca cele 25 de capturi ale testului de loc San Francisco (brief §7 pasul 0) pentru
criticul orb: snapshots/sf_loc_src/<sursa>_<k>.png -> docs/asset_briefs/img/sf_loc/loc_NN.png
(nume neutre, ordine amestecata cu samanta fixa) + cheia nume neutru -> sursa, SEPARAT, in
docs/asset_briefs/img/sf_loc_cheie.json (in afara folderului, ca un critic caruia i se da
folderul sa nu dea peste ea).

    python tools/sf_loc_shuffle.py

Fisierele se COPIAZA cu PIL si se rescriu fara metadate (PNG fara text/chunks de la Godot),
deci nici numele, nici continutul fisierului nu spun sursa.
"""
import json
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "snapshots", "sf_loc_src")
DST = os.path.join(ROOT, "docs", "asset_briefs", "img", "sf_loc")
SEED = 1906  # cutremurul
# Aceleasi fractii ca tools/sf_loc_capture_all.sh, in ordinea capturilor (1..5).
FRACS = {"sf": [0.0586, 0.0856, 0.1149, 0.1734, 0.2252], "kyoto": [0.08, 0.27, 0.50, 0.64, 0.83]}
TR_FRACS = [0.08, 0.27, 0.46, 0.64, 0.83]
SCENE = {"sf": "tools/SfLoc.tscn (strada sintetica)", "jodhpur": "--track=10 Jodhpur",
         "kyoto": "--track=11 Kyoto", "chongqing": "--track=5 Chongqing", "okinawa": "--track=13 Okinawa"}


def main():
    files = sorted(f for f in os.listdir(SRC) if f.endswith(".png"))
    assert len(files) == 25, "astept 25 de capturi, am %d" % len(files)
    rng = random.Random(SEED)
    order = files[:]
    rng.shuffle(order)
    os.makedirs(DST, exist_ok=True)
    key = {}
    for i, f in enumerate(order, 1):
        neutral = "loc_%02d.png" % i
        img = Image.open(os.path.join(SRC, f)).convert("RGB")
        img.save(os.path.join(DST, neutral), optimize=True)
        stem = f[:-4]
        src, k = stem.rsplit("_", 1)
        key[neutral] = {"sursa": src, "captura": int(k), "scena": SCENE[src],
                        "frac": FRACS.get(src, TR_FRACS)[int(k) - 1]}
    with open(os.path.join(os.path.dirname(DST), "sf_loc_cheie.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(key, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    sf = sorted(n for n, v in key.items() if v["sursa"] == "sf")
    print("scris %d capturi in %s; San Francisco = %s" % (len(order), os.path.relpath(DST, ROOT), sf))


if __name__ == "__main__":
    main()
