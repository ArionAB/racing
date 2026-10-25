"""Plansa de comparatie: foaia de concept deasupra, randarile noastre dedesubt,
in aceeasi asezare (3/4 mare sus, lateral / fata / sus jos). Python de sistem
(PIL), dupa un build din garajul v2 care a scris snapshots/garaj_v2/<nume>_*.png.

    python tools/blender/compare_concept.py buggy_v2 concept_buggy_v2.jpeg

Iese snapshots/garaj_v2/<nume>_vs_concept.png. Vederile ortografice noastre au
TOATE aceeasi scara (4.4 m pe latimea cadrului), deci proportiile intre ele se
pot compara direct; ale foii nu sunt garantat la aceeasi scara.
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main(name, concept):
    snap = os.path.join(ROOT, "snapshots", "garaj_v2")
    ref = Image.open(os.path.join(ROOT, "docs", "asset_briefs", "img", "vehicles",
                                  concept)).convert("RGB").resize((1536, 1024))
    ours = Image.new("RGB", (1536, 1024), (216, 216, 216))
    hero = Image.open(os.path.join(snap, "%s_hero.png" % name)).convert("RGB")
    hero = hero.resize((int(hero.width * 620 / hero.height), 620))
    ours.paste(hero, ((1536 - hero.width) // 2, 0))
    for i, view in enumerate(("side", "front", "top")):
        im = Image.open(os.path.join(snap, "%s_%s.png" % (name, view))).convert("RGB")
        im = im.resize((508, 381))
        ours.paste(im, (6 + i * 512, 1024 - 381 - 10))
    sheet = Image.new("RGB", (1536, 2048 + 8), (40, 40, 40))
    sheet.paste(ref, (0, 0))
    sheet.paste(ours, (0, 1024 + 8))
    out = os.path.join(snap, "%s_vs_concept.png" % name)
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
