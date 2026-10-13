"""Banda drumului de pe coronamentul barajului, MASURATA pe GLB-ul exportat.

Contract (kit §1.2 `vidraru_dam`): originea fiecarui nod e la cota drumului,
asfaltul il face codul, deci barajul il TINE, nu il acopera:
  * nimic peste Y = -0,05 (glTF Y sus) in banda |x| <= 6,0 (drumul de 12 m);
  * parapetul are ~1,1 m si sta pe 6,25 <= |x| <= 7,0.

Ce se masoara (toate nodurile, cu transformarea lor; axele glTF: X lateral,
Y sus, Z adancime = -Y Blender):
  deck_max   cota maxima a geometriei din banda |x| <= half (triunghiurile se
             TAIE la marginea benzii, deci o fata care incalca banda doar pe o
             muchie se masoara exact, nu dupa varfuri)
  top        pe o grila de 0,25 m in banda: cota celei mai inalte suprafete de
             sub fiecare punct (min / max) + acoperirea (cat din banda are
             suport sub drum; o gaura in coronament iese aici)
  parapet    cota maxima pe 6,25 <= |x| <= 7,0, pe fiecare parte

    python tools/blender/measure_tf_deck.py assets/models/transfagarasan/structures/vidraru_dam.glb
    python tools/blender/measure_tf_deck.py <glb> --contract=-0.05 [--half=6.0]   # iese 1 daca incalca
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure_gap as mg  # noqa: E402


def _clip(poly, k, sign, lim):
    """Sutherland-Hodgman: pastreaza punctele cu sign * p[k] <= sign * lim."""
    out = []
    n = len(poly)
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        fp, fq = sign * (lim - p[k]), sign * (lim - q[k])
        if fp >= 0:
            out.append(p)
        if (fp >= 0) != (fq >= 0):
            t = fp / (fp - fq)
            out.append(p + (q - p) * t)
    return out


def band_max(tris, lo, hi):
    """Cota maxima a triunghiurilor taiate la lo <= x <= hi."""
    best = -1e9
    sel = (tris[:, :, 0].max(axis=1) >= lo) & (tris[:, :, 0].min(axis=1) <= hi)
    for t in tris[sel]:
        poly = [t[0], t[1], t[2]]
        poly = _clip(poly, 0, 1.0, hi)
        if len(poly) >= 3:
            poly = _clip(poly, 0, -1.0, lo)
        if len(poly) >= 3:
            best = max(best, max(p[1] for p in poly))
    return best


def top_surface(tris, half, step=0.25):
    """Pe grila (x, z) din banda: cota celei mai inalte suprafete de sub punct."""
    zmin, zmax = tris[:, :, 2].min(), tris[:, :, 2].max()
    xs = np.arange(-half + step * 0.5, half, step)
    zs = np.arange(zmin + step * 0.5, zmax, step)
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    v0 = b[:, [0, 2]] - a[:, [0, 2]]
    v1 = c[:, [0, 2]] - a[:, [0, 2]]
    den = v0[:, 0] * v1[:, 1] - v1[:, 0] * v0[:, 1]
    ok = np.abs(den) > 1e-9
    a, v0, v1, den = a[ok], v0[ok], v1[ok], den[ok]
    ya, yb, yc = tris[ok][:, 0, 1], tris[ok][:, 1, 1], tris[ok][:, 2, 1]
    tops = []
    for x in xs:
        for z in zs:
            px, pz = x - a[:, 0], z - a[:, 2]
            u = (px * v1[:, 1] - v1[:, 0] * pz) / den
            v = (v0[:, 0] * pz - px * v0[:, 1]) / den
            inside = (u >= -1e-6) & (v >= -1e-6) & (u + v <= 1 + 1e-6)
            if inside.any():
                h = ya + (yb - ya) * u + (yc - ya) * v
                tops.append(h[inside].max())
            else:
                tops.append(np.nan)
    return np.array(tops)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    half, contract = 6.0, None
    for a in sys.argv[1:]:
        if a.startswith("--half="):
            half = float(a[7:])
        elif a.startswith("--contract="):
            contract = float(a[11:])
    tris = mg.gather(args[0])
    dmax = band_max(tris, -half, half)
    top = top_surface(tris, half)
    cov = np.isfinite(top).mean()
    pl = band_max(tris, -7.0, -6.25)
    pr = band_max(tris, 6.25, 7.0)
    print(os.path.basename(args[0]), "| banda |x| <= %.2f m, %d triunghiuri" % (half, len(tris)))
    print("deck_max %.3f" % dmax)
    if np.isfinite(top).any():
        print("top_min %.3f  top_max %.3f  acoperire %.1f%%" % (
            np.nanmin(top), np.nanmax(top), 100.0 * cov))
    else:
        print("top: nicio suprafata in banda")
    print("parapet_lac(-X) %.3f  parapet_hau(+X) %.3f" % (pl, pr))
    if contract is not None:
        good = dmax <= contract and cov >= 0.99
        print("CONTRACT %s (deck_max <= %.2f, acoperire >= 99%%)" % ("OK" if good else "INCALCAT", contract))
        sys.exit(0 if good else 1)
