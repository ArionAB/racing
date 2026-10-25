"""Decupeaza diorama-bara Ha Long pe cele 7 POI.

Bara e `docs/track_briefs/img/halong_diorama_v1.jpg` (diorama acceptata pe
masuratoare, vezi `docs/asset_briefs/halong_kit.md`). Ea NU are layout-ul real
al pistei — ala e `docs/track_briefs/img/halong_plan/halong_plan.png`. Ea are
*look-ul* fiecarui loc: cat de imbracate sunt turnurile, cat de dens e satul,
cum arata apa la baza stancii.

REGULA CARE SE INCALCA CEL MAI DES (docs/bara_vizuala.md): **bara e look, nu
layout**. Un critic care spune "la noi satul nu e langa pontoane" a comparat
asezarea si a ratat sarcina. Singura diferenta care conteaza e una pe care o
poti repara in decorul POI-ului.

TREI LUCRURI DIN DIORAMA CARE NU SE IAU CA ATARE, fiindca pista nu le poate da:
 1. **Drumul suspendat pe coama turnurilor.** In diorama soseaua urca pe
    creste de calcar cu pereti verticali de 40+ m. La noi `_lift_peaks`
    stinge masivele langa sosea (PEAK_ROAD_CLEAR 6 m, PEAK_ROAD_FULL 32 m) ca
    sa nu creasca munte peste drum — masurat pe `TurnGrota`: declarat 58 m,
    terenul real urca la +5,4. Deci peretii de langa drum vin din DECOR
    (`karst_tower_*`), nu din relief.
 2. **Tunelul prin baza turnului.** Golul piesei `grotto_portal` are 8,95 m
    liberi la cota masinii, iar carosabilul are 14 m (`custom_half_width`
    7,0). Nu incap. Grota e o decizie deschisa a dezvoltatorului.
 3. **Scara satului.** In diorama satul are ~20 de case lipite; la noi e
    decor de margine la 34-72 m lateral, deci densitatea se citeste altfel.
    Se compara ce se vede de pe sosea, nu macheta de sus.

Regiunile sunt in fractii din latime/inaltime, ca sa nu depinda de rezolutie.

    python tools/bar/crop_halong_bar.py [--out DIR]
"""

import argparse
import os

from PIL import Image

SRC = "docs/track_briefs/img/halong_diorama_v1.jpg"

# (x0, y0, x1, y1) in fractii; + ce trebuie sa se citeasca din decupaj.
# Alese prin citirea dioramei pe POI-urile din brief §2 (tabelul A..G).
REGIONS = {
    "A": ((0.00, 0.04, 0.30, 0.32),
          "cheiul satului: case plutitoare colorate inghesuite pe plute, "
          "tarcuri de peste cu flotoare ALBASTRE, barci legate, plase. "
          "Densitate mare — satul e locuit, nu trei case razlete"),
    "B": ((0.12, 0.18, 0.46, 0.62),
          "pontoanele: tablier de lemn pe flotoare albastre, serpuind intre "
          "turnuri mici de calcar care ies DREPT din apa, fiecare cu smoc "
          "de vegetatie pe varf si moloz la linia apei"),
    "C": ((0.30, 0.52, 0.72, 0.88),
          "digul si grota: drum pe zid de piatra la marginea apei, stanca "
          "mancata la baza, tunel prin baza turnului, bolovani la poale"),
    "D": ((0.62, 0.10, 1.00, 0.52),
          "urcarea si belvederea: drum care urca pe flancul insulei, "
          "VERSANT IMBRACAT in palmieri si tufe dese (nu copaci razleti), "
          "parapet pe marginea dinspre gol, pavilion alb pe varf"),
    "E": ((0.74, 0.38, 1.00, 0.76),
          "coborarea si plaja: serpentine stranse pe flanc verde, plaja de "
          "nisip la baza, bolovani in apa mica, apa tot mai deschisa la mal"),
    "F": ((0.08, 0.60, 0.44, 0.96),
          "canalul: apa deschisa intre turnuri, jonca cu vela ruginie, "
          "barci mici, turnuri cu poala de moloz si vegetatie agatata"),
    "G": ((0.44, 0.00, 0.80, 0.26),
          "drumul de coasta: sosea taiata in peretele de calcar, maimute pe "
          "parapet, vegetatie agatata pe perete, satul vizibil peste golf"),
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_halong")
    args = ap.parse_args()

    if not os.path.isfile(SRC):
        print("lipseste bara: %s" % SRC)
        return 1
    os.makedirs(args.out, exist_ok=True)
    im = Image.open(SRC)
    W, H = im.size
    print("bara %s  %dx%d" % (SRC, W, H))
    for key, (box, what) in sorted(REGIONS.items()):
        x0, y0, x1, y1 = box
        crop = im.crop((int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H)))
        dst = os.path.join(args.out, "bara_poi_%s.png" % key)
        crop.save(dst)
        print("  POI %s -> %s  (%dx%d)" % (key, dst, crop.width, crop.height))
        print("      %s" % what)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
