"""Decupeaza diorama-bara Fiordland pe POI.

Bara e `docs/track_briefs/img/fiordland_diorama_v03.jpg` — diorama acceptata
(brief §9.0). Ea NU are layout-ul real al pistei (ala e `fiordland_plan.png`);
ea are *look-ul* fiecarui loc. Criticul compara captura din masina la un POI
cu decupajul POI-ului, nu cu toata plansa (docs/bara_vizuala.md, si
machu_picchu_poi_gauntlet.md — "bara e look, nu layout").

Trei defecte ale dioramei sunt DECLARATE in brief §9.0 si nu se iau din
imagine: Stirling pe un ciot de drum la nivelul marii (in joc cade PE
cornisa), autocarul iese din tunel in acelasi sens cu masinile (in joc vine
din fata, pe banda stanga), avionul e la ~2x scara (anvergura reala 8 m).

Regiunile sunt in fractii din latime/inaltime ca sa nu depinda de rezolutie.
Alese de coordonator prin citirea dioramei, 25 sep 2026.

    python tools/bar/crop_fiordland_bar.py [--out DIR]
"""

import argparse
import os

from PIL import Image

SRC = "docs/track_briefs/img/fiordland_diorama_v03.jpg"

# (x0, y0, x1, y1) in fractii; + ce trebuie sa se citeasca din decupaj.
REGIONS = {
    "A": ((0.55, 0.60, 0.84, 0.84),
          "cheiul: zid de piatra cu babale, ponton de lemn, doua vaporase "
          "albe, caiace, cafeneaua cu acoperis de tabla, pinguini pe pietre, "
          "apa negru-verde plata cu fatete"),
    "B": ((0.29, 0.24, 0.52, 0.46),
          "cornisa taiata in gneis: perete gri cu dungi ude si muschi pe "
          "dreapta, marea plata negru-verde jos pe stanga, fara parapet, "
          "rata cu flori rosii in crapaturi, masini pe muchie"),
    "C": ((0.13, 0.18, 0.36, 0.46),
          "Stirling: perdea alba de 30 m care cade de pe buza de roca PESTE "
          "drum, bazin alb la baza, spray, masina in perdea; peretele "
          "intunecat si ud in spatele ei"),
    "D": ((0.10, 0.04, 0.38, 0.26),
          "Chasm: padure de fag cu trunchiuri negre subtiri si coronament "
          "in etaje, bolovani cu muschi, raul alb sapat in marmite, podetul "
          "de scanduri cu balustrada, doi kea pe un ciot"),
    "E": ((0.44, 0.04, 0.72, 0.30),
          "portalul de est: gura de beton cu galerie de avalansa (arcade), "
          "semaforul pe stalp, masivul de granit gol deasupra, grohotis, "
          "chevron-uri pe urcare, autocarul in gura tunelului"),
    "F": ((0.56, 0.24, 0.78, 0.46),
          "coborarea: drum in pante prin padure rara, cicatricea avalansei "
          "(fasie goala de granit lucios) cu trunchiuri si bolovani "
          "rostogoliti peste drum, masina pe panta"),
    "G": ((0.72, 0.20, 0.92, 0.50),
          "Bowen: cascada inalta in perete pe dreapta, bazin de apa alba cu "
          "spray, kicker de piatra, masina galbena in spray, pietris"),
    "H": ((0.68, 0.46, 0.99, 0.82),
          "malul: lodge lung cu acoperis in doua ape, containere, heliport "
          "cu H alb, pista de avioane paralela cu drumul, avionul mic "
          "aterizand, fagi rari pe mal"),
    "MITRE": ((0.28, 0.40, 0.52, 0.72),
              "Mitre Peak ca insula: dom de gneis cu calota alba, un fir alb "
              "de cascada, padure la baza, apa negru-verde cu fatete in "
              "jur; se vede de pe A si B peste apa"),
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_fiordland")
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
