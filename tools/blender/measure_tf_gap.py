"""Golul unui portal/tunel Transfagarasan, MASURAT CA GOL pe mai multe ferestre.

Pe `measure_gap.py` (proiectie pe planul transversal, grila 5 cm), dar:
  * tipareste TOATE ferestrele, fiecare cu eticheta ei (memoria
    `golul-se-masoara-pe-fereastra-lui`): banda caroseriei 0-2 m (contractul),
    0,15-2 m (varianta Okinawa), si latimea la 0 / 1 / 2 m inaltime;
  * `--scale=sx,sy,sz` aplica scara instantei din scena (axele glTF: X lateral,
    Y sus, Z adancime) -- ca sa masori `mountain_tunnel.glb` asa cum sta azi pe
    Track21 (1,5; 1,25; 1,0), nu ca fisier brut;
  * `--floor=m` ignora triunghiurile cu varful sub `m` (asfaltul din
    `mountain_tunnel.glb` blocheaza banda 0-2 m); GLB-ul portalului nou n-are asfalt.

    python tools/blender/measure_tf_gap.py <glb> [--scale=1.5,1.25,1.0] [--floor=0.12]
    python tools/blender/measure_tf_gap.py <glb> --contract=13.0,7.0   # iese 1 daca sub contract
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure_gap as mg  # noqa: E402


def measure_windows(path, scale=(1.0, 1.0, 1.0), floor=None, need=7.0):
    tris = mg.gather(path) * np.array(scale)
    if floor is not None:
        tris = tris[tris[:, :, 1].max(axis=1) >= floor]
    orig = mg.gather
    mg.gather = lambda _p: tris
    out = {}
    try:
        for label, band in (("caroserie 0-2 m", (0.0, 2.0)),
                            ("0,15-2 m", (0.15, 2.0)),
                            ("la 0 m", (0.0, 0.05)),
                            ("la 1 m", (1.0, 1.05)),
                            ("la 2 m", (2.0, 2.05))):
            out[label] = mg.measure(path, band, need)
    finally:
        mg.gather = orig
    return out


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    scale, floor, contract = (1.0, 1.0, 1.0), None, None
    for a in sys.argv[1:]:
        if a.startswith("--scale="):
            scale = tuple(float(v) for v in a[8:].split(","))
        elif a.startswith("--floor="):
            floor = float(a[8:])
        elif a.startswith("--contract="):
            contract = tuple(float(v) for v in a[11:].split(","))
    need = contract[1] if contract else 7.0
    res = measure_windows(args[0], scale, floor, need)
    print(os.path.basename(args[0]), "scale", scale, "floor", floor)
    for label, r in res.items():
        print("  %-16s gol %6.2f m  (x %6.2f .. %6.2f)  inalt. libera min %5.2f  med %5.2f" % (
            label, r.get("gap", 0.0), r.get("x_lo", 0.0), r.get("x_hi", 0.0),
            r.get("clear_min", 0.0), r.get("clear_med", 0.0)))
    body = res["caroserie 0-2 m"]
    print("gap %.2f" % body.get("gap", 0.0))
    print("clear_min %.2f" % body.get("clear_min", 0.0))
    print("usable_gap %.2f" % body.get("usable_gap", 0.0))
    if contract:
        ok = (body.get("gap", 0.0) >= contract[0] and body.get("clear_min", 0.0) >= contract[1])
        sys.exit(0 if ok else 1)
