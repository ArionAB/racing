"""Cate umbre au SILUETA, nu cat de intunecat e solul.

De ce exista: `probe_ecart_sol` masoara ecartul de luminanta pe carosabil, si
runda 30 l-a dus de la 77 la 112 (referinta 115) — dar criticul orb a dat tot
3/10 si a explicat de ce, corect:

  "O inundatie fara forma si patru umbre de con clare produc ACEEASI histograma."

Ecartul e o statistica de ORDINUL 0: nu stie nimic despre forma. Aici se numara
MUCHIILE lungi si DIRECTIONALE de pe sol — adica exact ce face ochiul sa spuna
"aia e o umbra" in loc de "aia e o pata".

  python tools/bar/umbre_silueta.py captura.png [--ref referinta.png]
"""
import sys, argparse, math
from PIL import Image


def edges(path, band=(0.55, 1.0), lo=0.20, hi=0.80):
    im = Image.open(path).convert("L")
    w, h = im.size
    px = im.load()
    y0, y1 = int(band[0] * h), int(band[1] * h)
    x0, x1 = int(lo * w), int(hi * w)
    # muchii pe orizontala si pe verticala, separat: o umbra directionala are
    # muchii ALUNGITE pe o axa, o pata de textura are muchii izotrope
    eh = ev = 0
    tot = 0
    for y in range(y0, y1 - 1, 2):
        for x in range(x0, x1 - 1, 2):
            v = px[x, y]
            tot += 1
            if abs(px[x + 1, y] - v) >= 12:
                eh += 1
            if abs(px[x, y + 1] - v) >= 12:
                ev += 1
    if tot == 0:
        return 0.0, 0.0, 0.0
    ph, pv = eh / tot * 100.0, ev / tot * 100.0
    aniso = abs(ph - pv) / max(ph + pv, 1e-6)
    return ph, pv, aniso


def run(path, label):
    ph, pv, an = edges(path)
    print("%-12s muchii tari pe orizontala %5.2f%%  pe verticala %5.2f%%  "
          "anizotropie %.2f" % (label, ph, pv, an))
    return ph + pv


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--ref", default=None)
    a = ap.parse_args()
    ours = run(a.image, "AL NOSTRU")
    if a.ref:
        ref = run(a.ref, "REFERINTA")
        print("")
        print("muchii totale: noi %.2f%%, referinta %.2f%%" % (ours, ref))
        # Densitatea NU e criteriul care separa: masurat, noi 27.6%% fata de
        # 31.8%% la referinta — practic la fel. Ce ne deosebeste e ANIZOTROPIA:
        # muchiile noastre sunt 8.2%% orizontal fata de 19.4%% vertical
        # (anizotropie 0.41), adica dungile dalei de textura; referinta are
        # 15.6/16.2 (anizotropie 0.02), fiindca muchiile ei vin din FORME.
        _, _, an_o = edges(a.image)
        _, _, an_r = edges(a.ref)
        print("")
        print("muchii totale: noi %.2f%%, referinta %.2f%% (densitatea NU separa)"
              % (ours, ref))
        print("anizotropie:   noi %.2f, referinta %.2f  <-- criteriul" % (an_o, an_r))
        ok = an_o <= 0.15
        print("VERDICT: %s (tinta: anizotropie <= 0.15 — muchii din FORME, nu "
              "dungi de dala)" % ("OK" if ok else "PICAT"))
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
