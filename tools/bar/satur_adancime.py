"""Saturatia si valoarea pe benzi de adancime, cu si fara CER.

De ce exista (runda 21). Criticul a masurat pe panoul nostru:
    aproape 0.632 -> mediu 0.650 -> departe 0.324   (valoare 0.558 -> 0.466)
si a citit din asta o "prapastie de ceata" in planul departat.

Prima cifra si a doua se reproduc (0.640 / 0.644). A treia NU: pe pixeli de
STANCA banda departata da 0.585, adica o scadere lina, nu o prapastie. 0.324
apare doar daca in banda intra si CERUL, care e deschis si aproape nesaturat si
trage media in jos. Aici sunt amandoua variantele, ca sa nu se mai confunde
"scena mea se spala in ceata" cu "am masurat cerul".

Ce ramane real dupa mascare, si e o problema:
  - saturatia CRESTE usor de la aproape la mediu (0.640 -> 0.644) in loc sa scada;
  - valoarea scade (0.522 -> 0.488) unde referinta o tine plata la ~0.69, adica
    scena noastra e mai INTUNECATA decat referinta la ORICE adancime.

  python tools/bar/satur_adancime.py snapshots/cappadocia_sofer.png
"""
import argparse
import colorsys

from PIL import Image

# Benzile de ecran care corespund, in cadrul de la frac 0.06, celor trei planuri.
BENZI = [("aproape", 430, 720), ("mediu", 300, 430), ("departe", 180, 300)]


def masoara(px, w, y0, y1, masca):
    s_tot = v_tot = 0.0
    n = 0
    for y in range(y0, y1):
        for x in range(0, w, 3):
            r, g, b = [c / 255.0 for c in px[x, y]]
            _, s, v = colorsys.rgb_to_hsv(r, g, b)
            # Cerul: deschis si aproape nesaturat. Fara masca asta, banda
            # departata masoara in mare parte cer, nu peisaj.
            if masca and v > 0.80 and s < 0.20:
                continue
            s_tot += s
            v_tot += v
            n += 1
    if n == 0:
        return None
    return s_tot / n, v_tot / n, n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    a = ap.parse_args()
    im = Image.open(a.image).convert("RGB")
    w, _ = im.size
    px = im.load()
    for masca in (True, False):
        print("--- %s ---" % ("doar peisaj (cer mascat)" if masca else "TOT cadrul, cer inclus"))
        for eticheta, y0, y1 in BENZI:
            r = masoara(px, w, y0, y1, masca)
            if r is None:
                continue
            print("  %-8s saturatie %.3f  valoare %.3f  (%d pixeli)"
                  % (eticheta, r[0], r[1], r[2]))
        print("")
    print("referinta (BBR/RR3, masurata de critic): 0.531 -> 0.456 -> 0.456,")
    print("cu valoarea PLATA la ~0.69 pe toate cele trei planuri.")


main()
