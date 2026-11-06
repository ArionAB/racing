"""Garzi Angkor, val 3, grupul A -- templul Angkor Wat.

    python tools/blender/measure_angkor_w3a.py temple <glb>
    python tools/blender/measure_angkor_w3a.py --selftest <glb>

Citeste GLB-ul EXPORTAT (coordonate GODOT: Y sus, Blender +Y = Godot -Z).
Contract (kit §1.2, anvelopa machetelor `Machete/AW_*`, brief §2.0):
  * amprenta <= 64,5 x 64,5;
  * turnul central: varful la Y = 36 +-0,5, la mai putin de 1 m de (0, 0);
  * cele patru turnuri de colt: varful la Y = 30 +-0,5, la mai putin de 1 m de (+-17, +-17);
  * varfurile = maximele locale pe cadran: centralul = maximul din raza de 8 m,
    colturile = maximul fiecarui cadran dincolo de |x|,|z| > 10 m.
Iese cu cod 1 la incalcare. `--selftest`: copii sabotate (modelul scalat 1,1x; turnul
central ridicat cu 3 m) care TREBUIE sa pice.
"""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb  # noqa: E402
from measure_angkor import _write_glb  # noqa: E402
from measure_angkor_w1a import _edit_positions  # noqa: E402
from measure_angkor_w2a import basics  # noqa: E402

FOOT_MAX = 64.5
CORNER = 17.0


def tips(pts):
    c = max((p for p in pts if p[0] ** 2 + p[2] ** 2 < 64.0), key=lambda p: p[1])
    out = {"centru": c}
    for sx in (-1, 1):
        for sz in (-1, 1):
            q = [p for p in pts if p[0] * sx > 10.0 and p[2] * sz > 10.0]
            out[(sx, sz)] = max(q, key=lambda p: p[1])
    return out


def check_temple(path, report=True):
    m = basics(path)
    fx, fz = m["x"][1] - m["x"][0], m["z"][1] - m["z"][0]
    bad = []
    if report:
        print("amprenta %.2f x %.2f (<= %.1f)" % (fx, fz, FOOT_MAX))
    if fx > FOOT_MAX or fz > FOOT_MAX:
        bad.append("amprenta %.2f x %.2f peste %.1f" % (fx, fz, FOOT_MAX))
    for name, p in tips(m["pts"]).items():
        if name == "centru":
            ex, ez, ey = 0.0, 0.0, 36.0
        else:
            ex, ez, ey = CORNER * name[0], CORNER * name[1], 30.0
        name = "centru" if name == "centru" else "colt(%+d,%+d)" % (ex, ez)
        # Godot z = -Blender y: pozitia de colt se compara pe modul simetric
        dxz = ((abs(p[0]) - abs(ex)) ** 2 + (abs(p[2]) - abs(ez)) ** 2) ** 0.5
        if report:
            print("%-14s varf Y %.3f (cerut %.1f +-0,5)  x %.2f z %.2f  abatere %.2f m" % (name, p[1], ey, p[0], p[2], dxz))
        if abs(p[1] - ey) > 0.5:
            bad.append("%s: varf %.2f, cerut %.1f +-0,5" % (name, p[1], ey))
        if dxz > 1.0:
            bad.append("%s: pozitie la %.2f m de tinta" % (name, dxz))
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def selftest(path):
    ok = True
    g0, blob0 = load_glb(path)[:2]
    tmp = tempfile.mkdtemp(prefix="angkor_w3a_sabotaj_")
    cases = [("modelul scalat 1,1x", lambda x, y, z: (x * 1.1, y * 1.1, z * 1.1)),
             ("turnul central ridicat cu 3 m",
              lambda x, y, z: (x, y + 3.0 if (abs(x) < 8 and abs(z) < 8 and y > 14.0) else y, z))]
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, fn in cases:
        g = json.loads(json.dumps(g0))
        p = os.path.join(tmp, "s.glb")
        _write_glb(p, g, _edit_positions(g, blob0, fn))
        print("-- sabotaj: %s" % label)
        if check_temple(p):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalul:")
    if not check_temple(path, report=False):
        print("   !! SELFTEST ESUAT: garda pica pe original")
        ok = False
    else:
        print("   originalul trece")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "--selftest":
        sys.exit(0 if selftest(a[1]) else 1)
    if len(a) >= 2 and a[0] == "temple":
        sys.exit(0 if check_temple(a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
