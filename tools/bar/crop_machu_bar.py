"""Decupeaza diorama-bara Machu Picchu pe POI.

Bara e `docs/track_briefs/img/machu_picchu_v3.jpeg` — o dioarama stilizata.
Ea NU are layout-ul real al pistei (ala e `machu_picchu_plan.png`); ea are
*look-ul* fiecarui loc. Criticul compara captura din masina la un POI cu
decupajul POI-ului, nu cu toata plansa: o plansa intreaga lasa ochiul sa
judece compozitia de ansamblu, care la noi e alta prin constructie.

Regiunile sunt in fractii din latime/inaltime ca sa nu depinda de rezolutie.
Alese de lead prin citirea dioramei, 16 sep 2026.

    python tools/bar/crop_machu_bar.py [--out DIR]
"""

import argparse
import os

from PIL import Image

SRC = "docs/track_briefs/img/machu_picchu_v3.jpeg"

# (x0, y0, x1, y1) in fractii; + ce trebuie sa se citeasca din decupaj.
REGIONS = {
    "A": ((0.30, 0.33, 0.66, 0.78),
          "cetatea: campuri de ziduri joase modulare, doua case cu acoperis "
          "de paie, iarba scurta aprinsa intre ziduri, lame, pavaj"),
    "B": ((0.66, 0.60, 0.95, 0.90),
          "drumul taiat in stanca, gura de tunel cu arc de piatra, trepte "
          "alaturi, peretele cu vegetatie pe stanga"),
    "C": ((0.78, 0.28, 1.00, 0.62),
          "poarta de piatra pe creasta cu condorul pe stanca alaturi, "
          "drumul pe muchie, nor dedesubt"),
    "D": ((0.54, 0.02, 0.90, 0.32),
          "terasele in trepte cu scara de piatra drept in jos, canalul de "
          "apa, lame pe terase, casa sus"),
    "E": ((0.30, 0.08, 0.62, 0.30),
          "podul de scanduri pe cabluri intre doua turnuri de piatra, "
          "autobuzul galben pe tablier, defileul dedesubt"),
    "F": ((0.12, 0.14, 0.42, 0.42),
          "trenul albastru-galben pe mal, repezisuri albe printre bolovani, "
          "cladirea mica de gara, copaci pe mal"),
    "G": ((0.02, 0.20, 0.30, 0.62),
          "serpentinele pe flancul verde, autobuzul galben pe un ac, "
          "quenuali cu scoarta rosie intre ace"),
    "H": ((0.10, 0.52, 0.42, 0.85),
          "cornisa pe perete cu poarta/portalul de piatra, golul pe o "
          "parte, zidul pe cealalta"),
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_machu")
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


if __name__ == "__main__":
    main()
