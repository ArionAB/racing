"""Garzi Angkor, val 2, grupul C -- kitul naga (balustrada, capul, uriasii).

    python tools/blender/measure_angkor_w2c.py balustrade <glb>
    python tools/blender/measure_angkor_w2c.py gap <glb>
    python tools/blender/measure_angkor_w2c.py head <glb>
    python tools/blender/measure_angkor_w2c.py giant <glb>
    python tools/blender/measure_angkor_w2c.py --selftest <balustrade.glb> <giant.glb>

Citeste GLB-ul EXPORTAT (coordonate GODOT: Y sus, lungimea modulului pe Z, Blender +Y = Godot -Z).
Contracte (kit 1.5):
  balustrada: inaltime <= 1,05 si grosime (X) <= 0,6 (zidul din cod: 1,0 x 0,5, + 0,05
    de toleranta); capetele plane la z = +-2,0 (nimic dincolo, tot ce e la |z| >= 1,99 sta
    EXACT pe plan); sectiunea trupului la capat: diametru 0,35-0,41 (trup subtire pe baza continua);
  gap: aceleasi limite de inaltime si capete, nimic pe partea drumului (x < -0,3), bucati
    cazute pe +X (x max > 0,5);
  cap: ~2,5 m inaltime (2,3-2,6), latime 1,4-1,9, intrarea trupului la z = 0 plana, aceeasi
    sectiune ca balustrada;
  uriasi: adancime (X) <= 1,6, inaltime 2,8-3,2, capetele modulului la z = +-2,0 plane, trupul
    naga la capete la 1,3-1,7 m inaltime (centrul sectiunii), diametru 0,43-0,47, cel mult 2
    noduri mesh (MultiMesh), numele `*_Stone`/`*_Lichen`, fara scala/rotatie pe radacini.
Iese cu cod 1 la incalcare. `--selftest`: balustrada ridicata la 1,3, uriasul adanc de 2,0 si
unul cu 3 noduri mesh TREBUIE sa pice.
"""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb  # noqa: E402
from measure_angkor import world_points, _write_glb  # noqa: E402
from measure_angkor_w1a import _edit_positions, world_tris  # noqa: E402

EPS = 2e-3


def info(path):
    g, blob = load_glb(path)[:2]
    pts = world_points(g, blob)
    names = sorted((n.get("name") or "").split(".")[0] for n in g["nodes"] if "mesh" in n)
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    xform = []
    for i, n in enumerate(g["nodes"]):
        if i in kids:
            continue
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            xform.append(n.get("name"))
    return pts, names, xform


def ends(pts, z_lo, z_hi, bad, tag):
    """Capetele plane la z_lo / z_hi: nimic dincolo, tot ce e in ultimul cm e pe plan."""
    zs = [p[2] for p in pts]
    if min(zs) < z_lo - EPS or max(zs) > z_hi + EPS:
        bad.append("%s: geometrie dincolo de capete (z %.3f..%.3f, cerut %.1f..%.1f)"
                   % (tag, min(zs), max(zs), z_lo, z_hi))
    for tgt in (z_lo, z_hi):
        near = [p[2] for p in pts if abs(p[2] - tgt) < 0.01]
        if not near:
            bad.append("%s: nimic la capatul z=%.1f" % (tag, tgt))
        elif max(abs(z - tgt) for z in near) > EPS:
            bad.append("%s: capat neplan la z=%.1f" % (tag, tgt))


def section(pts, z_at, sel=lambda p: True):
    """(centru y, inaltime, latime, centru x) a inelului de la z=z_at (varfurile la +-1 mm)."""
    ring = [p for p in pts if abs(p[2] - z_at) < 1e-3 and sel(p)]
    if not ring:
        return None
    ys = [p[1] for p in ring]
    xs = [p[0] for p in ring]
    return (min(ys) + max(ys)) / 2, max(ys) - min(ys), max(xs) - min(xs), (min(xs) + max(xs)) / 2


def common(names, xform, suffixes, bad):
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    for n in names:
        if not any(n.endswith(s) for s in suffixes):
            bad.append("nod cu nume in afara contractului: %s" % n)


def _section_ok(s, z, bad, tag, lo=0.42, hi=0.47):
    if not (lo - 0.01 <= s[1] <= hi and lo <= s[2] <= hi):
        bad.append("%s: sectiunea trupului la z=%.1f e %.3f x %.3f (cerut %.2f-%.2f)" % (tag, z, s[2], s[1], lo, hi))


# trupul de pe balustrada (si capul) e mai subtire (0,38): loc pentru unda sub 1,05
BAL_SEC = (0.35, 0.41)
BODY_SEL = lambda p: abs(p[0]) < 0.2 and p[1] > 0.5   # exclude coltul placii (x = 0,27) si miezul (0,23)


def _hit(tris, z, y):
    """Punctul (z, y) e acoperit de proiectia (z, y) a vreunui triunghi? (privit pe X)"""
    for (a, b, c) in tris:
        p0, p1, p2 = (a[2], a[1]), (b[2], b[1]), (c[2], c[1])
        d = (p1[1] - p2[1]) * (p0[0] - p2[0]) + (p2[0] - p1[0]) * (p0[1] - p2[1])
        if abs(d) < 1e-12:
            continue
        l1 = ((p1[1] - p2[1]) * (z - p2[0]) + (p2[0] - p1[0]) * (y - p2[1])) / d
        l2 = ((p2[1] - p0[1]) * (z - p2[0]) + (p0[0] - p2[0]) * (y - p2[1])) / d
        if l1 >= -1e-6 and l2 >= -1e-6 and 1 - l1 - l2 >= -1e-6:
            return True
    return False


def solid_base(path, y_levels=(0.1, 0.3, 0.5), step=0.1):
    """Baza e PIATRA CONTINUA (zidul din cod e masiv: nu se vede prin el). Privita din
    lateral, fiecare punct (z in -2..2, y in 0,1/0,3/0,5) trebuie acoperit. Intoarce
    lista punctelor goale."""
    g, blob = load_glb(path)[:2]
    tris = world_tris(g, blob)
    holes = []
    n = int(round(4.0 / step))
    for i in range(n + 1):
        z = -2.0 + 4.0 * i / n
        for y in y_levels:
            if not _hit(tris, z, y):
                holes.append((round(z, 2), y))
    return holes


def check_balustrade(path, report=True, gap=False):
    pts, names, xform = info(path)
    xs, ys, zs = [p[0] for p in pts], [p[1] for p in pts], [p[2] for p in pts]
    h, th = max(ys) - min(ys), max(xs) - min(xs)
    bad = []
    if report:
        print("anvelopa  inaltime %.3f (max 1,05)  X %.3f..%.3f (grosime %.3f, max 0,6)  Z %.3f..%.3f"
              % (h, min(xs), max(xs), th, min(zs), max(zs)))
    if max(ys) > 1.05 + EPS:
        bad.append("inaltime %.3f > 1,05" % max(ys))
    if abs(min(ys)) > 0.02:
        bad.append("min Y %.3f != 0" % min(ys))
    if gap:
        if min(xs) < -0.3:
            bad.append("ceva pe partea drumului: x min %.3f < -0,3" % min(xs))
        if max(xs) < 0.5:
            bad.append("nicio bucata cazuta pe +X (x max %.3f)" % max(xs))
    elif th > 0.6 + EPS:
        bad.append("grosime %.3f > 0,6" % th)
    ends(pts, -2.0, 2.0, bad, "balustrada")
    if not gap:
        holes = solid_base(path)
        if report:
            print("baza      goluri vazute din lateral (z,y < 0,52): %d" % len(holes))
        if holes:
            bad.append("baza nu e continua: %d puncte goale, primul la z=%.2f y=%.2f" % (len(holes), holes[0][0], holes[0][1]))
    for z in (-2.0, 2.0):
        s = section(pts, z, BODY_SEL)
        if s is None:
            if not gap:
                bad.append("fara trup la capatul z=%.1f" % z)
            continue
        if report:
            print("sectiune  z=%+.1f: centru y %.3f  inaltime %.3f  latime %.3f" % (z, s[0], s[1], s[2]))
        _section_ok(s, z, bad, "balustrada", *BAL_SEC)
        if abs(s[3]) > 0.01:
            bad.append("trupul necentrat pe X la capat (%.3f)" % s[3])
    common(names, xform, ("_Stone", "_Lichen"), bad)
    if names != ["Naga_Lichen", "Naga_Stone"]:
        bad.append("noduri %s, cerute Naga_Stone + Naga_Lichen" % names)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def check_head(path, report=True):
    pts, names, xform = info(path)
    xs, ys, zs = [p[0] for p in pts], [p[1] for p in pts], [p[2] for p in pts]
    bad = []
    w, h = max(xs) - min(xs), max(ys)
    if report:
        print("anvelopa  inaltime %.3f (2,3-2,6)  latime %.3f (1,4-1,9)  Z %.3f..%.3f" % (h, w, min(zs), max(zs)))
    if not 2.3 <= h <= 2.6:
        bad.append("inaltime %.3f in afara 2,3-2,6" % h)
    if not 1.4 <= w <= 1.9:
        bad.append("latime %.3f in afara 1,4-1,9" % w)
    if max(zs) > EPS:
        bad.append("geometrie in spatele intrarii (z %.3f > 0)" % max(zs))
    near = [p[2] for p in pts if abs(p[2]) < 0.01]
    if not near or max(abs(z) for z in near) > EPS:
        bad.append("intrarea trupului la z=0 lipseste sau nu e plana")
    s = section(pts, 0.0, BODY_SEL)
    if s is None:
        bad.append("fara trup la intrare")
    else:
        if report:
            print("intrare   centru y %.3f  inaltime %.3f  latime %.3f" % (s[0], s[1], s[2]))
        _section_ok(s, 0.0, bad, "cap", *BAL_SEC)
    common(names, xform, ("_Stone", "_Lichen"), bad)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def check_giant(path, report=True):
    pts, names, xform = info(path)
    xs, ys, zs = [p[0] for p in pts], [p[1] for p in pts], [p[2] for p in pts]
    bad = []
    depth, h = max(xs) - min(xs), max(ys)
    if report:
        print("anvelopa  adancime X %.3f (max 1,6)  inaltime %.3f (2,8-3,2)  Z %.3f..%.3f  noduri mesh %d (max 2)"
              % (depth, h, min(zs), max(zs), len(names)))
    if depth > 1.6 + EPS:
        bad.append("adancime %.3f > 1,6" % depth)
    if not 2.8 <= h <= 3.2:
        bad.append("inaltime %.3f in afara 2,8-3,2" % h)
    if len(names) > 2:
        bad.append("%d noduri mesh (max 2 pentru MultiMesh)" % len(names))
    ends(pts, -2.0, 2.0, bad, "uriasul")
    for z in (-2.0, 2.0):
        s = section(pts, z)
        if s is None:
            bad.append("fara trup la capatul z=%.1f" % z)
            continue
        if report:
            print("sectiune  z=%+.1f: centru y %.3f  inaltime %.3f  latime %.3f" % (z, s[0], s[1], s[2]))
        if not 1.3 <= s[0] <= 1.7:
            bad.append("trupul naga la z=%.1f e la %.3f m (cerut 1,3-1,7)" % (z, s[0]))
        _section_ok(s, z, bad, "uriasul")
    common(names, xform, ("_Stone", "_Lichen"), bad)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def selftest(bal, giant):
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_w2c_sabotaj_")
    cases = []
    g0, b0 = load_glb(bal)[:2]
    g = json.loads(json.dumps(g0))
    cases.append(("balustrada ridicata la 1,3", check_balustrade, g,
                  _edit_positions(g, b0, lambda x, y, z: (x, y * 1.3 / 1.0, z))))
    gap = os.path.join(os.path.dirname(bal), "naga_balustrade_gap.glb")
    if os.path.exists(gap):
        gg, gb = load_glb(gap)[:2]
        cases.append(("balustrada cu baza sparta (modulul gap dat drept intreg)", check_balustrade, gg, gb))
    g1, bl1 = load_glb(giant)[:2]
    g = json.loads(json.dumps(g1))
    cases.append(("uriasul adanc de 2,0", check_giant, g,
                  _edit_positions(g, bl1, lambda x, y, z: (x * 2.0 / 1.56, y, z))))
    g = json.loads(json.dumps(g1))
    donor = next(i for i, n in enumerate(g["nodes"]) if "mesh" in n)
    g["nodes"].append(dict(g["nodes"][donor], name="Giant_Extra"))
    g["scenes"][0]["nodes"].append(len(g["nodes"]) - 1)
    cases.append(("uriasul cu 3 noduri mesh", check_giant, g, bl1))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, fn, g, blob in cases:
        p = os.path.join(tmp, "s.glb")
        _write_glb(p, g, blob)
        print("-- sabotaj: %s" % label)
        if fn(p, report=False):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalele:")
    for fn, p in ((check_balustrade, bal), (check_giant, giant)):
        if not fn(p, report=False):
            print("   !! SELFTEST ESUAT: garda pica pe original (%s)" % os.path.basename(p))
            ok = False
    if ok:
        print("   originalele trec")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest":
        sys.exit(0 if selftest(a[1], a[2]) else 1)
    if len(a) >= 2:
        fn = {"balustrade": check_balustrade, "gap": lambda p: check_balustrade(p, gap=True),
              "head": check_head, "giant": check_giant}.get(a[0])
        if fn:
            sys.exit(0 if fn(a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
