"""Decupeaza diorama-bara Carrara pe POI.

Bara e `docs/track_briefs/img/carrara_plan/diorama_v01_iter2.jpg`, diorama
acceptata (brief §9.2). Ea NU are layout-ul real al pistei (ala e
`docs/track_briefs/img/carrara_plan_adnotat.png`); ea are *look-ul* fiecarui
loc. Criticul compara captura din masina la un POI cu decupajul POI-ului, nu
cu toata plansa (docs/track_briefs/carrara_poi_gauntlet.md: "bara e look, nu
layout").

Defecte DECLARATE ale dioramei, care nu se iau din imagine (brief §9.2):
E desenat prea jos (inaltimile vin din Track23); excavatorul e desenat pe
STANGA (in joc sta pe DREAPTA, langa coridorul de blocuri); totul e mai
comprimat decat pista (bazinul de 500 m incape intr-un cadru).

Regiunile sunt in fractii din latime/inaltime ca sa nu depinda de rezolutie.
Alese de coordonator prin citirea dioramei, 30 oct 2026.

    python tools/bar/crop_carrara_bar.py [--out DIR]
"""

import argparse
import os

from PIL import Image

SRC = "docs/track_briefs/img/carrara_plan/diorama_v01_iter2.jpg"

# (x0, y0, x1, y1) in fractii; + ce trebuie sa se citeasca din decupaj.
REGIONS = {
    "A": ((0.12, 0.06, 0.42, 0.24),
          "piazzale-ul: platou de pulbere bej, blocuri crem stivuite pe margini, excavatorul cu furca, "
          "magazia cu acoperis de tabla, roata de fir, vagonetul cu bloc, cabana de piatra"),
    "B": ((0.24, 0.12, 0.66, 0.55),
          "gradonii: trepte cu fete verticale crem cu dungi de rugina, banc plat cu blocuri razlete, "
          "drumul in ace pe banc, camionul basculant galben, sirul de blocuri pe muchie"),
    "C": ((0.39, 0.43, 0.85, 0.68),
          "fundul carierei: balti turcoaz opace, derrick-ul cu blocul agatat, masina de taiat cu lant, "
          "blocuri informe si moloz pe podea, gura galeriei in perete"),
    "D": ((0.74, 0.27, 1.00, 0.65),
          "galeria Ravaccione: portal patrat taiat in perete, cu lumini, peretele inalt fatetat"),
    "E": ((0.36, 0.60, 0.95, 0.79),
          "cariera de sus: drumul pe muchia de sus, sirul de blocuri pe buza, caderea spre fund"),
    "F": ((0.16, 0.51, 0.43, 0.99),
          "Ponti di Vara: arce de caramida pe pile de marmura, torentul turcoaz cu bolovani in chei, "
          "padure de castani si ginestra pe versanti"),
    "G": ((0.00, 0.08, 0.22, 0.62),
          "ravaneto-ul si Colonnata: drumul coborand pe moloz, satul cu turn de clopotnita si tigla, "
          "castani si ginestra galbena pe versantul verde"),
    "H": ((0.14, 0.03, 0.27, 0.13),
          "tunelul Marmifera: portal de piatra cu arc in coasta, deasupra piazzale-ului"),
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_carrara")
    ap.add_argument("--src", default=SRC)
    args = ap.parse_args()

    img = Image.open(args.src).convert("RGB")
    w, h = img.size
    os.makedirs(args.out, exist_ok=True)

    for poi, ((x0, y0, x1, y1), what) in sorted(REGIONS.items()):
        box = (int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h))
        crop = img.crop(box)
        path = os.path.join(args.out, "bara_poi_%s.png" % poi)
        crop.save(path)
        print("POI %s -> %s (%dx%d)  %s" % (poi, path, crop.width, crop.height, what))
    ans = os.path.join(args.out, "bara_ansamblu.png")
    img.save(ans)
    print("ansamblu -> %s" % ans)


if __name__ == "__main__":
    main()
