"""Garzi Angkor, val 4, grupul C -- fundalul `effects/angkor_horizon.glb` (kit 1.8).

    python tools/blender/measure_angkor_w4c.py horizon <glb>
    python tools/blender/measure_angkor_w4c.py --selftest <glb>

Citeste GLB-ul EXPORTAT (coordonate GODOT: Y sus; lungimea unui nod = cea mai mare
intindere pe X/Z). Contracte:
  noduri copii directi ai radacinii, EXACT: Canopy_A/B/C, KulenRidge, StormBand_A/B, Paddies_W;
  Canopy_*      lungime 150-250, inaltime 20-35, talpa la Y=0, sloturi doar 12/21;
  KulenRidge    lungime 270-330, inaltime 30-45, talpa la Y=0, sloturi 12/21;
  StormBand_*   lungime 200-300, BAZA 40-60 m peste originea nodului (norul pluteste: conventie
                declarata, vezi build_angkor_horizon.py), grosime >= 40 si varf <= 140, baza PLATA
                (>= 1500 m2 de fete in jos la Y = baza +-0,05), sloturi EXACT {20, 29}
                (20 baza/umbra, 29 varfuri luminate);
  Paddies_W     lungime 230-270, talpa la Y=0, inaltime 12-16,5 (palmierii), sloturi 12/17/20/21;
  fisierul in ansamblu: min Y = 0 (prin celelalte noduri), scala/rotatie neutre pe radacini,
  total triunghiuri <= 40000.
Iese cu cod 1 la incalcare. `--selftest`: un StormBand lipsa (redenumit) si un StormBand asezat pe
pamant (baza coborata la Y=0) TREBUIE sa pice.
"""
import json
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402
from measure_angkor import _write_glb  # noqa: E402
from measure_angkor_w1a import world_tris  # noqa: E402
from measure_angkor_w3c import points_by_root, roots, dims, within, xform_bad  # noqa: E402

NAMES = ["Canopy_A", "Canopy_B", "Canopy_C", "KulenRidge", "StormBand_A", "StormBand_B", "Paddies_W"]
SLOTS_OK = {"Canopy": {12, 21}, "KulenRidge": {12, 21}, "StormBand": {20, 29}, "Paddies_W": {12, 17, 20, 21}}
SLOTS_N = 32


def kind(name):
    return name.split("_")[0] if name.startswith(("Canopy", "StormBand")) else name


def node_slots(g, blob, root):
    """Sloturile folosite (UV.x) si triunghiurile din subarborele radacinii."""
    out = set()
    stack = [root]
    tris = 0
    while stack:
        i = stack.pop()
        n = g["nodes"][i]
        stack.extend(n.get("children", []))
        if "mesh" not in n:
            continue
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            for uv in read_accessor(g, blob, prim["attributes"]["TEXCOORD_0"]):
                out.add(max(0, min(SLOTS_N - 1, int(math.floor(uv[0] * SLOTS_N)))))
            if "indices" in prim:
                tris += g["accessors"][prim["indices"]]["count"] // 3
    return out, tris


def down_area_at(g, blob, y_base):
    """Aria fetelor orientate in jos la Y = y_base +-0,05 (din tot fisierul: celelalte noduri
    stau la Y=0, deci nu pot atinge y_base >= 40)."""
    area = 0.0
    for (a, b, c) in world_tris(g, blob):
        ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
        nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
        ar = (nx * nx + ny * ny + nz * nz) ** 0.5 / 2
        if ar > 0 and ny / (2 * ar) < -0.99 and max(abs(p[1] - y_base) for p in (a, b, c)) < 0.05:
            area += ar
    return area


def check_horizon(path, report=True):
    g, blob = load_glb(path)[:2]
    bad = []
    rs = roots(g)
    names = sorted(g["nodes"][i].get("name", "") for i in rs)
    if names != sorted(NAMES):
        bad.append("radacini %s, cerute exact %s" % (names, sorted(NAMES)))
    xform_bad(g, bad)
    by = points_by_root(g, blob)
    all_y0 = 1e9
    tris_total = 0
    for i in rs:
        nm = g["nodes"][i].get("name", "")
        if i not in by:
            bad.append("%s fara geometrie" % nm)
            continue
        (x0, x1), (y0, y1), (z0, z1) = dims(by[i])
        length = max(x1 - x0, z1 - z0)
        h = y1 - y0
        all_y0 = min(all_y0, y0)
        k = kind(nm)
        slots, tr = node_slots(g, blob, i)
        tris_total += tr
        if report:
            print("%-12s lungime %6.1f  Y %6.1f..%6.1f (grosime %5.1f)  tris %5d  sloturi %s"
                  % (nm, length, y0, y1, h, tr, sorted(slots)))
        if k == "Canopy":
            within(length, 150, 250, nm + " lungime", bad)
            within(y1, 20, 35, nm + " inaltime", bad)
            if abs(y0) > 0.05:
                bad.append("%s: talpa nu e la Y=0 (%.2f)" % (nm, y0))
        elif k == "KulenRidge":
            within(length, 270, 330, nm + " lungime", bad)
            within(y1, 30, 45, nm + " inaltime", bad)
            if abs(y0) > 0.05:
                bad.append("%s: talpa nu e la Y=0 (%.2f)" % (nm, y0))
        elif k == "StormBand":
            within(length, 200, 300, nm + " lungime", bad)
            within(y0, 40, 60, nm + " BAZA (Y min)", bad)
            if h < 40:
                bad.append("%s: grosime %.1f < 40 (fara turnuri de cumulus)" % (nm, h))
            if y1 > 140:
                bad.append("%s: varf %.1f > 140" % (nm, y1))
            area = down_area_at(g, blob, y0)
            if report:
                print("             baza plata (fete in jos la Y min): %.0f m2 (min 1500)" % area)
            if area < 1500:
                bad.append("%s: baza nu e plata (%.0f m2 < 1500)" % (nm, area))
            if slots != {20, 29}:
                bad.append("%s: sloturi %s, cerute exact {20, 29}" % (nm, sorted(slots)))
        elif k == "Paddies_W":
            within(length, 230, 270, nm + " lungime", bad)
            within(y1, 12, 16.5, nm + " inaltime (palmieri)", bad)
            if abs(y0) > 0.05:
                bad.append("%s: talpa nu e la Y=0 (%.2f)" % (nm, y0))
        if k in SLOTS_OK and not slots <= SLOTS_OK[k]:
            bad.append("%s: sloturi in afara listei: %s" % (nm, sorted(slots - SLOTS_OK[k])))
    if all_y0 < 1e8 and abs(all_y0) > 0.05:
        bad.append("min Y al fisierului %.2f, cerut 0" % all_y0)
    if report:
        print("TOTAL triunghiuri: %d (max 40000)" % tris_total)
    if tris_total > 40000:
        bad.append("triunghiuri %d > 40000" % tris_total)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def selftest(path):
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_w4c_sabotaj_")
    g0, b0 = load_glb(path)[:2]
    cases = []
    g = json.loads(json.dumps(g0))
    for n in g["nodes"]:
        if n.get("name") == "StormBand_B":
            n["name"] = "Cloud_B"
    cases.append(("StormBand_B lipsa", g))
    g = json.loads(json.dumps(g0))
    for n in g["nodes"]:
        if n.get("name") == "StormBand_A":
            t = n.get("translation", [0, 0, 0])
            n["translation"] = [t[0], t[1] - 46.0, t[2]]      # baza coborata la sol
    cases.append(("StormBand_A pe pamant", g))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, g in cases:
        p = os.path.join(tmp, "s.glb")
        _write_glb(p, g, b0)
        print("-- sabotaj: %s" % label)
        if check_horizon(p, report=False):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalul:")
    if not check_horizon(path, report=False):
        print("   !! SELFTEST ESUAT: garda pica pe original")
        ok = False
    else:
        print("   originalul trece")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest" and len(a) >= 2:
        sys.exit(0 if selftest(a[1]) else 1)
    if len(a) >= 2 and a[0] == "horizon":
        sys.exit(0 if check_horizon(a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
