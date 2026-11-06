"""Garzi Angkor, val 1, grupul A -- Poarta de Sud (`south_gate_face_tower.glb`).

    python tools/blender/measure_angkor_w1a.py gate <glb>
    python tools/blender/measure_angkor_w1a.py --selftest <glb>

Citeste GLB-ul EXPORTAT (coordonate GODOT: Y sus, drumul merge pe Z). Contract
(kit §1.2): latimea 18-20 m (X), adancimea 7-9 m (Z), varful 17-19 m (corectura coordonatorului, runda 4); UN singur gol:
  * GOLUL la nivelul drumului se masoara ca GOL -- proiectia triunghiurilor pe planul
    de-a curmezisul drumului (X, Y); pentru inaltimile 0-2,5 m, distanta dintre cea mai
    apropiata geometrie din dreapta si din stanga axei trebuie sa fie >= 7,2 m (nimic
    din juge in +-3,6 m). Triunghiurile degenerate in proiectie (peretii juga, vazuti
    pe muchie) CONTEAZA: se taie poligonul, nu se masoara aria;
  * inaltimea libera >= 8 m: cel mai de jos punct al oricarui triunghi care intra in
    banda +-3,6 m (deasupra solului), pe toata adancimea;
  * originea la baza si la mijlocul golului (centrat pe X si Z, min Y ~ 0); noduri
    `Gate_Stone/Lichen/Streak`; fara scala/rotatie pe radacini; lichen portocaliu
    < 3% din arie; doar sloturile 3 / 30,12 / 20.
Iese cu cod 1 la incalcare. `--selftest`: copii sabotate (juga mutata la +-3,4;
buiandrug coborat la 7,5 m; nod redenumit; scalat 1,1x) TREBUIE sa pice.
"""
import json
import os
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402
from measure_angkor import quat_rot, slot_areas, _write_glb  # noqa: E402

GAP_MIN = 7.2
GAP_ZONE_H = 2.5
BAND = 3.6
CLEAR_MIN = 8.0
W_RANGE, D_RANGE, H_RANGE = (18.0, 20.0), (7.0, 9.0), (17.0, 19.0)
NODES = ["Gate_Lichen", "Gate_Stone", "Gate_Streak"]
EPS = 1e-3


def world_tris(g, blob):
    parent = {}
    for i, n in enumerate(g["nodes"]):
        for c in n.get("children", []):
            parent[c] = i

    def xf(i, p):
        n = g["nodes"][i]
        s = n.get("scale", [1, 1, 1])
        p = (p[0] * s[0], p[1] * s[1], p[2] * s[2])
        p = quat_rot(n.get("rotation", [0, 0, 0, 1]), p)
        t = n.get("translation", [0, 0, 0])
        p = (p[0] + t[0], p[1] + t[1], p[2] + t[2])
        return xf(parent[i], p) if i in parent else p

    tris = []
    for i, n in enumerate(g["nodes"]):
        if "mesh" not in n:
            continue
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            pos = [xf(i, p) for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
            idx = [k[0] for k in read_accessor(g, blob, prim["indices"])]
            for t in range(0, len(idx) - 2, 3):
                tris.append((pos[idx[t]], pos[idx[t + 1]], pos[idx[t + 2]]))
    return tris


def _clip(poly, axis, val, keep_ge):
    out = []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        ina = (a[axis] >= val) if keep_ge else (a[axis] <= val)
        inb = (b[axis] >= val) if keep_ge else (b[axis] <= val)
        if ina:
            out.append(a)
        if ina != inb:
            t = (val - a[axis]) / (b[axis] - a[axis])
            out.append((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])))
    return out


def clip_rect(poly, x0, x1, y0, y1):
    for axis, val, ge in ((0, x0, True), (0, x1, False), (1, y0, True), (1, y1, False)):
        if not poly:
            return []
        poly = _clip(poly, axis, val, ge)
    return poly


def passage(tris):
    """(gap_m, clear_h) masurate din triunghiuri, proiectate pe (X, Y)."""
    right, left, clear = 1e9, -1e9, 1e9
    for (a, b, c) in tris:
        poly = [(a[0], a[1]), (b[0], b[1]), (c[0], c[1])]
        # zona 0-2,5 m, +-8 m: cea mai apropiata geometrie de axa, pe fiecare parte
        for (x, y) in clip_rect(poly, -8.0, 8.0, 0.0, GAP_ZONE_H):
            if x > 0:
                right = min(right, x)
            elif x < 0:
                left = max(left, x)
            else:
                right, left = 0.0, 0.0
        # inaltimea libera: banda +-3,6 m, deasupra solului
        for (x, y) in clip_rect(poly, -BAND + EPS, BAND - EPS, 0.02, 60.0):
            clear = min(clear, y)
    return right - left, clear


def measure_gate(path):
    g, blob = load_glb(path)[:2]
    tris = world_tris(g, blob)
    pts = [p for t in tris for p in t]
    xs, ys, zs = [p[0] for p in pts], [p[1] for p in pts], [p[2] for p in pts]
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
    gap, clear = passage(tris)
    return dict(x=(min(xs), max(xs)), y=(min(ys), max(ys)), z=(min(zs), max(zs)),
                names=names, xform=xform, gap=gap, clear=clear)


def check_gate(path, report=True):
    m = measure_gate(path)
    w, d, h = m["x"][1] - m["x"][0], m["z"][1] - m["z"][0], m["y"][1] - m["y"][0]
    if report:
        print("anvelopa  latime X %.3f  adancime Z %.3f  inaltime Y %.3f   minY %.3f"
              % (w, d, h, m["y"][0]))
        print("golul     gol 0-%.1f m: %.3f m (min %.1f)   inaltime libera in +-%.1f m: %.3f m (min %.1f)"
              % (GAP_ZONE_H, m["gap"], GAP_MIN, BAND, m["clear"], CLEAR_MIN))
    bad = []
    for nm, v, (lo, hi) in (("latime X", w, W_RANGE), ("adancime Z", d, D_RANGE), ("inaltime", h, H_RANGE)):
        if not lo <= v <= hi:
            bad.append("%s %.3f in afara %.1f-%.1f" % (nm, v, lo, hi))
    if m["gap"] < GAP_MIN:
        bad.append("golul la 0-%.1f m e %.3f < %.1f (ceva din juge intra in +-%.1f m)"
                   % (GAP_ZONE_H, m["gap"], GAP_MIN, BAND))
    if m["clear"] < CLEAR_MIN:
        bad.append("inaltimea libera %.3f < %.1f" % (m["clear"], CLEAR_MIN))
    if abs(m["y"][0]) > 0.02:
        bad.append("min Y %.3f != 0 (originea la baza)" % m["y"][0])
    for ax, lo_hi in (("X", m["x"]), ("Z", m["z"])):
        if abs((lo_hi[0] + lo_hi[1]) / 2) > 0.05:
            bad.append("necentrat pe %s" % ax)
    if m["names"] != NODES:
        bad.append("noduri %s, cerute %s" % (m["names"], NODES))
    if m["xform"]:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % m["xform"])
    if not bad:
        ar = slot_areas(path)
        tot = sum(ar.values())
        orange = sum(v for (n, s_), v in ar.items() if s_ == 30)
        slots_ok = {("Gate_Stone", 3), ("Gate_Lichen", 30), ("Gate_Lichen", 12), ("Gate_Streak", 20)}
        extra = sorted(k for k in ar if k not in slots_ok)
        if report:
            print("arii      total %.1f m2  lichen portocaliu %.2f%%" % (tot, 100 * orange / tot))
        if orange / tot >= 0.03:
            bad.append("lichen portocaliu %.2f%% >= 3%%" % (100 * orange / tot))
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def _edit_positions(g, blob, fn):
    blob = bytearray(blob)
    for n in g["nodes"]:
        if "mesh" not in n:
            continue
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            acc = g["accessors"][prim["attributes"]["POSITION"]]
            bv = g["bufferViews"][acc["bufferView"]]
            base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
            stride = bv.get("byteStride") or 12
            for i in range(acc["count"]):
                x, y, z = struct.unpack_from("<fff", blob, base + i * stride)
                struct.pack_into("<fff", blob, base + i * stride, *fn(x, y, z))
    return bytes(blob)


def selftest(path):
    g0, blob0 = load_glb(path)[:2]
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_gate_sabotaj_")
    cases = []

    def jambs_in(x, y, z):          # juga mutata la +-3,4 m
        return ((3.4 if x > 0 else -3.4) if 3.6 < abs(x) < 4.0 else x, y, z)

    def lintel_down(x, y, z):       # buiandrugul coborat la 7,5 m
        return (x, 7.5 if 8.3 < y < 8.5 and abs(x) < 3.8 else y, z)

    for label, fn in (("juga mutata la +-3,4 m", jambs_in), ("buiandrug coborat la 7,5 m", lintel_down)):
        g = json.loads(json.dumps(g0))
        cases.append((label, g, _edit_positions(g, blob0, fn)))
    g = json.loads(json.dumps(g0))
    for n in g["nodes"]:
        if n.get("name") == "Gate_Streak":
            n["name"] = "Gate_Dare"
    cases.append(("nod redenumit", g, blob0))
    g = json.loads(json.dumps(g0))
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    for i, n in enumerate(g["nodes"]):
        if i not in kids:
            n["scale"] = [1.1, 1.1, 1.1]
    cases.append(("scalat 1,1x", g, blob0))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, g, blob in cases:
        p = os.path.join(tmp, "s.glb")
        _write_glb(p, g, blob)
        print("-- sabotaj: %s" % label)
        if check_gate(p):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalul:")
    if not check_gate(path):
        print("   !! SELFTEST ESUAT: garda pica pe original")
        ok = False
    else:
        print("   originalul trece")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest":
        sys.exit(0 if selftest(a[1]) else 1)
    if len(a) >= 2 and a[0] == "gate":
        sys.exit(0 if check_gate(a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
