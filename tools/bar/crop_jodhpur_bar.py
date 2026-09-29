"""Decupeaza diorama-bara Jodhpur (Track17) pe POI.

Bara e `docs/track_briefs/img/jodhpur_diorama_v02.jpg` (1426x1103), diorama
v0.2, facuta dupa planul real (`jodhpur_plan.png`). Ea NU e layout-ul pistei
(acela e `jodhpur_plan.png` si fractiile masurate in jodhpur_poi_gauntlet.md);
ea e *look-ul* fiecarui loc. Criticul compara captura din masina la un POI cu
decupajul POI-ului, nu cu toata plansa (docs/bara_vizuala.md; regula "bara e
look, nu layout" din fiordland_poi_gauntlet.md).

Diorama e ORIENTATA ca planul real (fortul in spate-DREAPTA, lacul in
dreapta, bazarul in fata-stanga, bucla in sensul acelor), nu ca textul
brief-ului §2 / §9 (fort in NV, bucla invers acelor). Nu e un defect de
imagine: brief-ul §2 e cel vechi. Nu conteaza pentru bara (look, nu layout).

Defecte ale dioramei care NU se iau din imagine (vezi gauntlet §"Regula"):
  - portile au goluri inguste, cat o masina; in joc golul e 7 m LIBER, masurat
    ca gol pe gabaritul caroseriei;
  - bastionul are parapet crenelat cu candele pe varf si tunurile trag spre
    DESERT (spre soare); in joc varful e fara parapet si tunurile trag spre
    ORAS;
  - vaca sta intr-o arcada laterala, in afara drumului; in joc sta culcata IN
    gura ulicioarei (pe banda de 3,2 m), la gura reala (~25 m pe banda);
  - procesiunea (caii albi) e pe carosabilul bazarului; in joc e pe trotuarul
    din D, fara coliziune;
  - fortul e o cetate intreaga, vazuta de sus; din masina e perete (§2.0):
    se ia fatada, nu silueta;
  - in fantana pavilionul sta pe o insula in mijlocul apei; in joc e la acul de
    la capatul de EST, iar rampele sunt pe terasament deasupra podelei (-9),
    nu taiate in peretele de trepte;
  - saritura e o masina care zboara de pe o stanca IN lac; in joc lacul e o
    rapa laterala pe STANGA drumului (la 4ac84517 fara kicker declarat);
  - artificiile sunt sus, pe fundalul orasului; in joc explodeaza la 20-35 m
    peste case.

Regiunile sunt in fractii din latime/inaltime ca sa nu depinda de rezolutie.
Alese prin citirea dioramei la rezolutie plina (decupaje marite 2x), 29 sep
2026. Fiecare cutie are justificarea langa ea.

    python tools/bar/crop_jodhpur_bar.py [--out DIR]
"""

import argparse
import os

from PIL import Image

SRC = "docs/track_briefs/img/jodhpur_diorama_v02.jpg"

# (x0, y0, x1, y1) in fractii; + ce trebuie sa se citeasca din decupaj.
REGIONS = {
    # px 500-770 x 730-930 (fara apa fantanii de deasupra): turnul cu ceas, rangoli pe grila, arcada portii
    # pietei in spatele turnului, tuk-tuk-urile la bordura, ghirlande.
    "A": ((0.35, 0.66, 0.54, 0.845),
          "startul: turnul cu ceas de gresie cu 4 cadrane, rangoli colorat pe "
          "caldaram la grila, arcada portii pietei, tuk-tuk-uri negru-galben "
          "parcate, ghirlande si sfori de becuri calde"),
    # px 40-450 x 540-930 (taiat la dreapta ca sa nu intre fantana): strada bazarului de la turn pana la furca spre
    # fantana — tarabe cu copertine, fasii de textile peste strada, saci de
    # condimente, tuk-tuk-uri pe banda. (Caii albi de pe carosabil sunt
    # procesiunea mutata — defect declarat, nu se copiaza.)
    "B": ((0.03, 0.49, 0.315, 0.845),
          "bazarul: tarabe cu copertine de panza saturate, fasii de textile "
          "rosu/roz/galben/verde PESTE strada, saci de condimente, tuk-tuk-uri "
          "pe banda, multime pe trotuar, case albastre deasupra"),
    # px 285-730 x 455-775: groapa cu trepte in V pe trei etaje, apa verde cu
    # candele plutitoare, pavilionul cu cupola, rampele.
    "C": ((0.20, 0.41, 0.515, 0.705),
          "fantana in trepte: gresie roz-piersica, fluxuri de trepte in V pe "
          "etaje, apa verde-inchis cu candele plutitoare, pavilionul cu "
          "coloane si cupola, candele pe fiecare treapta, drumul coborand in "
          "groapa"),
    # px 310-920 x 195-485: orasul albastru cu drumul care urca prin el —
    # case cub in doua tente, rezervoare negre pe terase, candele pe
    # parapete, cateva case ocru, copaci rari.
    "D": ((0.215, 0.175, 0.645, 0.44),
          "orasul albastru: case cub de 2-4 etaje in doua tente de albastru "
          "(deschis si indigo), ~1 din 8 ocru, rezervoare negre pe terase, "
          "candele pe fiecare parapet, ferestre luminate, copaci rari, "
          "caldaram care urca printre ele"),
    # px 180-480 x 280-480: arcada ulicioarei cu vaca zebu culcata, fasii de
    # textile, zidurile albastre; separat de D fiindca e un loc distinct.
    "D2": ((0.126, 0.254, 0.337, 0.435),
           "ulicioara: arcada de gresie in zid albastru, vaca zebu alba culcata "
           "in gura (coarne portocalii, ghirlanda), fasii de textile, ziduri "
           "inalte albastre de o parte si de alta, candele pe praguri"),
    # px 760-1070 x 55-335: zigzagul urcarii spre fort — ziduri de gresie
    # rosie cu creneluri si candele, portile cu turn si canaturi intunecate,
    # stanca roz-bruna, pavilioane chhatri pe ziduri.
    "E": ((0.533, 0.05, 0.75, 0.305),
          "portile fortului: drum in zigzag pe stanca roz-bruna, ziduri de "
          "gresie rosie crenelate cu candele, portile cu turnuri si canaturi "
          "de lemn inchis, chhatri pe ziduri, casele albastre la picior"),
    # px 1010-1310 x 90-310: bastionul rotund de gresie, tunurile pe metereze
    # cu fum alb, tiroliana cu omul pe scripete, uliii sub bastion, stanca
    # de dedesubt. (Tunurile spre desert si parapetul = defecte declarate.)
    "F": ((0.708, 0.08, 0.92, 0.285),
          "bastionul: zid rotund de gresie rosie pe stanca, tunuri pe "
          "metereze cu fum alb, tiroliana cu silueta pe cablu, ulii negri "
          "rotindu-se SUB bastion, lumina joasa aurie pe gresie"),
    # px 870-1190 x 0-135: fatada palatului (jharokha, chhatri, cupole) si
    # turnurile — reperul lui F, "fatada la inaltimea camerei".
    "PALAT": ((0.61, 0.0, 0.835, 0.122),
              "fatada palatului Mehrangarh: gresie rosie, balcoane jharokha "
              "sculptate, chhatri cu cupole, turnuri rotunde cu acoperis plat; "
              "se judeca doar primele doua etaje (in joc creasta e taiata de "
              "cadru)"),
    # px 940-1200 x 240-800: coborarea — drumul coboara pe marginea stancii
    # roz-brune, cu stanca in trepte, copaci si euforbii pe dreapta (in
    # imagine) si casele albastre pe partea cealalta.
    "G": ((0.66, 0.22, 0.842, 0.725),
          "coborarea: drum pe marginea stancii de riolit roz-brun in blocuri "
          "mari fatetate, arbusti si copaci de desert pe stanca, candele pe "
          "margine, casele albastre pe partea opusa"),
    # px 1090-1426 x 370-730: lacul verde-inchis cu candele plutitoare,
    # cenotaful alb pe stanca, masina in aer peste apa.
    "G2": ((0.765, 0.335, 1.0, 0.66),
           "Devkund: apa verde-inchis cu candele plutitoare, cenotaful de "
           "marmura alba pe stanca roz, masina in aer cu dara de spray, malul "
           "de riolit in blocuri"),
    # px 1160-1390 x 380-570: cenotaful singur — reper (alb mare, cupola +
    # chhatri), ca decupaj de siluieta/material pentru G/G2.
    "CENOTAF": ((0.813, 0.345, 0.975, 0.517),
                "Jaswant Thada: marmura alba calda, cupola centrala si patru "
                "chhatri, soclu in trepte, candele la baza, stanca roz sub el"),
    # px 715-1250 x 740-905: dreapta de intoarcere spre turn — autobuzul,
    # stalpi cu felinare, sfori de becuri, case albastre cu parter luminat.
    "H": ((0.50, 0.67, 0.877, 0.82),
          "dreapta H: asfalt lat, felinare pe stalpi si sfori de becuri "
          "calde, case albastre cu parter luminat, tuk-tuk, zidul de stanca "
          "cu candele pe marginea din fata"),
    # px 585-700 x 690-900: turnul cu ceas singur — reperul lui H (si al lui A).
    "TURN": ((0.41, 0.625, 0.49, 0.815),
             "Ghanta Ghar: turn de gresie roz cu 4 cadrane albe, balcon, "
             "cupola mica, arcada la baza, becuri pe muchii"),
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_jodhpur")
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
