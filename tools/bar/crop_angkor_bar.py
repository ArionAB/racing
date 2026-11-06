"""Decupeaza diorama-bara Angkor pe POI.

Bara e `docs/track_briefs/img/angkor_diorama_v03.jpg`, diorama acceptata (brief §9.1). Ea NU are
layout-ul real al pistei (ala e `docs/track_briefs/img/angkor_plan_adnotat.png`); ea are *look-ul*
fiecarui loc. Criticul compara captura din masina la un POI cu decupajul POI-ului, nu cu toata
plansa (docs/track_briefs/angkor_poi_gauntlet.md: "bara e look, nu layout").

Abaterea DECLARATA a dioramei (brief §9.1): diagonala F -> C prin piata regala nu exista pe pista
(ChatGPT a desenat-o de doua ori); totul e mai comprimat decat pista (2,4 km intr-un cadru).

Regiunile sunt in fractii din latime/inaltime ca sa nu depinda de rezolutie.
Alese de coordonator prin citirea dioramei, 6 nov 2026.

    python tools/bar/crop_angkor_bar.py [--out DIR]
"""

import argparse
import os

from PIL import Image

SRC = "docs/track_briefs/img/angkor_diorama_v03.jpg"

# (x0, y0, x1, y1) in fractii; + ce trebuie sa se citeasca din decupaj.
REGIONS = {
    "A": ((0.20, 0.44, 0.77, 0.78),
          "calea de vest: drum rosu de laterita langa santul cu lotusi, balustrada naga cu capul in evantai, "
          "gopura si cele cinci turnuri-boboc aurii in fata, oglindite in apa"),
    "B": ((0.42, 0.44, 0.75, 0.68),
          "prin Angkor Wat: gopura de vest cu deschiderea, colonada galeriei, terasele in trepte ale templului, "
          "calugarii in sofran pe scara, piatra cu licheni"),
    "C": ((0.21, 0.14, 0.52, 0.51),
          "Phnom Bakheng: dealul cu jungla, drumul rosu in serpentine, etajele de gresie cu scara centrala, "
          "turnuletele-altar pe platforma de sus"),
    "D": ((0.14, 0.08, 0.34, 0.41),
          "calea uriasilor: sirurile de deva/asura care tin naga pe ambele parti, Poarta de Sud cu fete, "
          "bazinele cu lotusi pe laturi, elefantul in piata"),
    "E": ((0.20, 0.00, 0.62, 0.17),
          "Bayonul: turnurile cu patru fete pe terasa, drumul rosu printre ele, zidul terasei, jungla in spate"),
    "F": ((0.49, 0.13, 0.78, 0.39),
          "piata regala: pavajul de gresie, Terasa Elefantilor cu elefantii sculptati pe fata, drumul pe coama "
          "terasei, jungla pe margini"),
    "G": ((0.73, 0.28, 1.00, 0.76),
          "Ta Prohm: galeriile prabusite inghitite de radacini, ficusul uriasi cu radacini argintii peste ziduri, "
          "liane atarnate, drumul de pamant rosu printre ruine"),
    "H": ((0.39, 0.63, 0.85, 0.98),
          "Srah Srang: debarcaderul de laterita cu lei de piatra, tuk-tuk-uri parcate, bazinul cu lotusi, "
          "palmieri de zahar, drumul pe malul santului cu turnurile oglindite"),
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_angkor")
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
