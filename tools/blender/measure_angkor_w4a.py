"""Garzi Angkor, val 4, grupul A -- copacii (tetrameles a/b, dipterocarp, palmierul de zahar).

    python tools/blender/measure_angkor_w4a.py tetrameles <glb>
    python tools/blender/measure_angkor_w4a.py dipterocarp|palm <glb>
    python tools/blender/measure_angkor_w4a.py --selftest <tetrameles_glb>

Citeste GLB-ul EXPORTAT (Godot: Y sus). Contract (kit §1.7, sarcina val 4 A):
  * inaltimi: tetrameles 22-28 m, dipterocarp 30-38 m, palmier 12-16 m; originea la baza (min Y ~ 0);
  * noduri: <= 2 (`Tree_Trunk`, `Tree_Leaves`), nicio scala/rotatie aplicata pe radacina;
  * tetrameles, MASURAT PE NODUL `Tree_Trunk` langa sol: intinderea contraforturilor 8-10 m
    (cea mai mare dintre extinderile pe X si Z a varfurilor de sub Y = 0,4) si inaltimea lor
    3-4 m (cel mai inalt varf aflat la mai mult de 0,35 m in afara razei trunchiului, masurata
    la Y = 8-10 m);
  * PLAFON de triunghiuri per copac: 3.500. Pe care l-am pus dupa copacii existenti: `beech_a`
    are 228, banyanul ~1k-2k (Okinawa), iar copacii astia sunt de 3-5 ori mai inalti si cu
    coroane de 18 m. Plafonul e o plasa pentru accidente (o primitiva la rezolutie implicita), nu
    un tel: CLAUDE.md nu pune plafon pe triunghiuri, doar pe materiale.
Iese cu cod 1 la incalcare. `--selftest`: copii sabotate (copacul scalat 1,5x; copacul cu 4 noduri)
care TREBUIE sa pice.
"""
import copy
import json
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb  # noqa: E402
from measure_angkor import _write_glb  # noqa: E402
from measure_angkor_w1a import world_tris, _edit_positions  # noqa: E402

TRI_CAP = 3500
RANGES = {"tetrameles": (22.0, 28.0), "dipterocarp": (30.0, 38.0), "palm": (12.0, 16.0)}


def node_pts(g, blob, name):
    g2 = copy.deepcopy(g)
    for n in g2["nodes"]:
        if "mesh" in n and (n.get("name") or "").split(".")[0] != name:
            del n["mesh"]
    return [p for t in world_tris(g2, blob) for p in t]


def check(kind, path, report=True):
    g, blob = load_glb(path)[:2]
    all_tris = world_tris(g, blob)
    pts = [p for t in all_tris for p in t]
    ys = [p[1] for p in pts]
    h, ymin = max(ys) - min(ys), min(ys)
    bad = []
    lo, hi = RANGES[kind]
    names = [(n.get("name") or "").split(".")[0] for n in g["nodes"] if "mesh" in n]
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    xform = [n.get("name") for i, n in enumerate(g["nodes"]) if i not in kids and (
        any(abs(v - 1) > 1e-4 for v in n.get("scale", [1, 1, 1])) or
        any(abs(v) > 1e-4 for v in n.get("rotation", [0, 0, 0, 1])[:3]))]
    if report:
        print("%s: inaltime %.2f m (cerut %.0f-%.0f), min Y %.3f, %d triunghiuri (plafon %d), noduri %s"
              % (os.path.basename(path), h, lo, hi, ymin, len(all_tris), TRI_CAP, names))
    if not lo <= h <= hi:
        bad.append("inaltime %.2f in afara [%.0f, %.0f]" % (h, lo, hi))
    if abs(ymin) > 0.05:
        bad.append("originea nu e la baza (min Y %.3f)" % ymin)
    if len(names) > 2:
        bad.append("%d noduri (cel mult 2)" % len(names))
    if sorted(set(names)) != ["Tree_Leaves", "Tree_Trunk"]:
        bad.append("nume de noduri %s (cerut Tree_Leaves + Tree_Trunk)" % sorted(set(names)))
    if len(all_tris) > TRI_CAP:
        bad.append("%d triunghiuri peste plafonul %d" % (len(all_tris), TRI_CAP))
    if xform:
        bad.append("scala/rotatie aplicata pe radacina: %s" % xform)
    if kind == "tetrameles" and "Tree_Trunk" in names:
        tp = node_pts(g, blob, "Tree_Trunk")
        low = [p for p in tp if p[1] < 0.4]
        spread = max(max(p[0] for p in low) - min(p[0] for p in low),
                     max(p[2] for p in low) - min(p[2] for p in low)) if low else 0.0
        mid = [p for p in tp if 8.0 <= p[1] <= 10.0]
        r_t = max(math.hypot(p[0], p[2]) for p in mid) if mid else 0.0
        out = [p for p in tp if p[1] < 8.0 and math.hypot(p[0], p[2]) > r_t + 0.35]
        fin_h = max(p[1] for p in out) if out else 0.0
        if report:
            print("   contraforturi: intindere %.2f m (cerut 8-10), inaltime %.2f m (cerut 3-4); raza trunchi %.2f"
                  % (spread, fin_h, r_t))
        if not 8.0 <= spread <= 10.0:
            bad.append("intinderea contraforturilor %.2f in afara [8, 10]" % spread)
        if not 3.0 <= fin_h <= 4.0:
            bad.append("inaltimea contraforturilor %.2f in afara [3, 4]" % fin_h)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def selftest(path):
    ok = True
    g0, blob0 = load_glb(path)[:2]
    tmp = tempfile.mkdtemp(prefix="angkor_w4a_sabotaj_")
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    # 1: copacul scalat 1,5x
    g = json.loads(json.dumps(g0))
    p = os.path.join(tmp, "s1.glb")
    _write_glb(p, g, _edit_positions(g, blob0, lambda x, y, z: (x * 1.5, y * 1.5, z * 1.5)))
    cases = [("copacul scalat 1,5x", p)]
    # 2: copac cu 4 noduri (nodurile existente duplicate)
    g = json.loads(json.dumps(g0))
    extra = [copy.deepcopy(n) for n in g["nodes"] if "mesh" in n]
    base = len(g["nodes"])
    g["nodes"].extend(extra)
    sc = g["scenes"][g.get("scene", 0)]
    sc["nodes"] = list(sc["nodes"]) + list(range(base, base + len(extra)))
    p2 = os.path.join(tmp, "s2.glb")
    _write_glb(p2, g, blob0)
    cases.append(("copac cu 4 noduri", p2))
    kind = "tetrameles"
    for label, pp in cases:
        print("-- sabotaj: %s" % label)
        if check(kind, pp, report=False):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(pp)
    os.rmdir(tmp)
    print("-- originalul:")
    if not check(kind, path, report=False):
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
    if len(a) >= 2 and a[0] in RANGES:
        sys.exit(0 if check(a[0], a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
