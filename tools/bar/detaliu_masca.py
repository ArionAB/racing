#!/usr/bin/env python
"""DETALIU LOCAL pe MASCA de obiect, nu pe caseta.

    python tools/bar/detaliu_masca.py <cadru.png> <masca.png> [--ref <img> [<masca_ref>]]

De ce exista. `detaliu_local.py` masoara pe o grila de dale dreptunghiulare.
Peste un obiect neregulat, o dala contine fundal in proportie NECUNOSCUTA;
fundalul (cer, ceata, teren departat) e mai neted, deci obiectul iese "prea
plat" si cand e in regula. In sesiunea din 1 sep 2026 asta a dat de trei ori
verdict fals, o data cu o dala 79% cer.

Aici statistica e ACEEASI (media abaterii fata de cei 4 vecini), dar se
calculeaza NUMAI pe pixelii marcati de masca, si numai acolo unde toti cei 4
vecini sunt tot in masca — deci nicio muchie obiect/fundal nu intra in cifra
(muchia are contrast urias si ar umfla artificial rezultatul).

Se raporteaza si distributia pe fasii ORIZONTALE ale mastii, ca sa se vada daca
detaliul e concentrat undeva sau lipseste pe toata suprafata.
"""
import sys
import numpy as np
from PIL import Image


def lum(path):
    return np.asarray(Image.open(path).convert("RGB")).astype(float).mean(axis=2)


def mask_of(path):
    m = np.asarray(Image.open(path).convert("L"))
    return m > 127


def detail_masked(g, m):
    """Abaterea fata de cei 4 vecini, doar pe pixeli cu vecinatate intreaga."""
    core = m[1:-1, 1:-1]
    n4 = m[:-2, 1:-1] & m[2:, 1:-1] & m[1:-1, :-2] & m[1:-1, 2:]
    valid = core & n4
    if valid.sum() < 50:
        return float("nan"), 0
    d = np.abs(g[1:-1, 1:-1] - 0.25 * (
        g[:-2, 1:-1] + g[2:, 1:-1] + g[1:-1, :-2] + g[1:-1, 2:]))
    return float(d[valid].mean()), int(valid.sum())


def bands(g, m, n=6):
    """Detaliu pe fasii orizontale ale mastii (sus -> jos)."""
    ys, xs = np.nonzero(m)
    if ys.size == 0:
        return []
    y0, y1 = ys.min(), ys.max()
    out = []
    for k in range(n):
        a = y0 + (y1 - y0) * k // n
        b = y0 + (y1 - y0) * (k + 1) // n
        sub = np.zeros_like(m)
        sub[a:b] = m[a:b]
        v, c = detail_masked(g, sub)
        out.append((a, b, v, c))
    return out


def main():
    a = sys.argv[1:]
    if len(a) < 2:
        print(__doc__)
        return 2
    frame, mask = a[0], a[1]
    g, m = lum(frame), mask_of(mask)
    v, c = detail_masked(g, m)
    print("%-46s detaliu %.3f  pe %d px (%.2f%% cadru)  luminanta %.1f"
          % (frame.split("/")[-1] + " @ " + mask.split("/")[-1], v, c,
             100.0 * c / m.size, g[m].mean()))
    for (y0, y1, bv, bc) in bands(g, m):
        print("    y %4d-%4d  detaliu %6.3f  (%d px)" % (y0, y1, bv, bc))
    if "--ref" in a:
        i = a.index("--ref")
        rimg = a[i + 1]
        rg = lum(rimg)
        if len(a) > i + 2 and not a[i + 2].startswith("--"):
            rm = mask_of(a[i + 2])
        else:
            rm = np.ones(rg.shape, bool)
        rv, rc = detail_masked(rg, rm)
        print("REF %-42s detaliu %.3f  pe %d px  luminanta %.1f"
              % (rimg.split("/")[-1], rv, rc, rg[rm].mean()))
        print("RAPORT noi/referinta: %.2f" % (v / rv))
    return 0


if __name__ == "__main__":
    sys.exit(main())
