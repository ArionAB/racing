#!/usr/bin/env python
"""DETALIU LOCAL pe regiuni. Cat de texturata e o suprafata, independent de
cat de luminoasa e sau ce umbra cade pe ea.

    python tools/bar/detaliu_local.py <captura.png> [--ref docs/.../B_chimneys.png]

De ce exista. Runda 32 a masurat "anizotropie" in banda de jos si a iesit ca
suntem in urma. Era o masuratoare pe regiunea gresita: in banda de jos eram deja
la paritate, iar defectul vizibil (o pana maro plata in cadranul dreapta-sus) e
DEASUPRA benzii. Criticul l-a vazut din poza, fara nicio cifra; cele 32 de runde
de metrici nu-l prinsesera.

Statistica: media abaterii fata de vecinatatea imediata (cei 4 vecini). E oarba
la luminanta si la gradient lin — o panta care se intuneca uniform da ~0 — deci
masoara exact ce ne lipsea: textura de suprafata.

Ancore masurate pe cappadocia_v3 / B_chimneys (31 aug 2026):
    referinta, tot cadrul ............ 3.85
    referinta, cea mai plata dala 20% . 1.63   <- PRAGUL. Nimic sub atat.
    referinta, cea mai bogata dala .... 8.15

Regula: nicio regiune care ocupa peste ~5% din cadru nu are voie sub 1.63.
Cerul nu se numara (e gradient prin definitie) — se da --skip-sky.
"""
import sys
import numpy as np
from PIL import Image

PRAG = 1.63  # cea mai plata dala din referinta


def detail(g: np.ndarray) -> float:
    if g.shape[0] < 3 or g.shape[1] < 3:
        return float("nan")
    return float(np.abs(g[1:-1, 1:-1] - 0.25 * (
        g[:-2, 1:-1] + g[2:, 1:-1] + g[1:-1, :-2] + g[1:-1, 2:])).mean())


def grid(path: str, n: int = 5, skip_sky: bool = True):
    g = np.asarray(Image.open(path).convert("RGB")).astype(float).mean(axis=2)
    h, w = g.shape
    out = []
    for r in range(n):
        for c in range(n):
            tile = g[r * h // n:(r + 1) * h // n, c * w // n:(c + 1) * w // n]
            # Cerul: gradient lin, luminos, albastru. Se recunoaste dupa
            # canalul albastru DOMINANT, nu dupa cat e de plat — altfel
            # heuristica sterge exact defectul (o panta plata) pe care sonda
            # exista ca sa-l prinda.
            rgb = np.asarray(Image.open(path).convert("RGB")).astype(float)
            t3 = rgb[r * h // n:(r + 1) * h // n, c * w // n:(c + 1) * w // n]
            sky = (skip_sky and r == 0
                   and t3[:, :, 2].mean() > t3[:, :, 0].mean()
                   and tile.mean() > 140)
            out.append((detail(tile), r, c, tile.mean(), sky))
    return out


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    tiles = grid(sys.argv[1])
    bad = [t for t in tiles if not t[4] and t[0] < PRAG]
    print("captura: %s" % sys.argv[1])
    print("dale sub prag (%.2f), cerul exclus:" % PRAG)
    for d, r, c, m, _ in sorted(bad):
        print("   %.2f  r%d c%d  luminanta=%.1f" % (d, r, c, m))
    tot = [t[0] for t in tiles if not t[4]]
    print("median=%.2f  min=%.2f" % (np.median(tot), min(tot)))
    if bad:
        print("VERDICT: PROBLEMA — %d dale sub cea mai plata dala din referinta"
              % len(bad))
        return 1
    print("VERDICT: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
