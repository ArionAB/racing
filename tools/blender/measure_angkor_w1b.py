"""Garda grupului B, val 1: aw_west_gopura + ta_prohm_tree_gate.
Citeste GLB-ul EXPORTAT (glTF JSON + accesoare + transformarile nodurilor), in
coordonate GODOT (Y sus, drumul pe Z, latimea pe X).

    python tools/blender/measure_angkor_w1b.py gopura   <glb>
    python tools/blender/measure_angkor_w1b.py treegate <glb>
    python tools/blender/measure_angkor_w1b.py --selftest <gopura.glb> <treegate.glb>

Golul se masoara ca GOL (memoriile cota-de-contract-se-masoara-ca-gol,
golul-se-masoara-pe-fereastra-lui): triunghiurile din banda de inaltime 0-2,5 m
se TAIE pe banda (Sutherland-Hodgman) si se proiecteaza pe sectiunea
transversala; golul = distanta dintre cel mai apropiat punct de axa pe dreapta si
pe stanga. Inaltimea libera = cota cea mai joasa a oricarui triunghi (taiat pe
fasia |x| < jumatatea golului) deasupra solului.

gopura:  lungime 50-56 (X), inaltime 14-16, adancime 8-12, gol >= 10,0 (fiecare
         parte >= 5,0), inaltime libera >= 8,0, noduri Gopura_*, sloturi din tabel.
treegate: gresia (TreeGate_Stone) ~14 m lat (13-15), varful gresiei 7-9, arborele
         18-22, gol >= 6,6 (fiecare parte >= 3,3), inaltime libera >= 5,5 pe TOATE
         nodurile (nicio radacina in gol sub 5,5), noduri TreeGate_*, sloturi.

`--selftest`: copii sabotate IN MEMORIE ale listei de triunghiuri citite din
fisierul real (picioare mutate la +-4,5, stalp in gol, buiandrug coborat, lungime
scalata; radacina impinsa in gol la 3 m, picioare la +-3,0, buiandrug coborat,
blocuri in gol) trebuie sa PICE; originalul trebuie sa treaca.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402
from measure_angkor import quat_rot, slot_areas  # noqa: E402

BAND = (0.0, 2.5)        # banda de inaltime a golului (mașina)
TOL = 1e-3
GOPURA_NODES = ["Gopura_Lichen", "Gopura_Stone", "Gopura_Streak"]
TREE_NODES = ["TreeGate_Canopy", "TreeGate_Lichen", "TreeGate_Root", "TreeGate_Stone", "TreeGate_Streak"]
GOPURA_SLOTS = {("Gopura_Stone", 3), ("Gopura_Lichen", 30), ("Gopura_Lichen", 12), ("Gopura_Streak", 20)}
TREE_SLOTS = {("TreeGate_Stone", 3), ("TreeGate_Lichen", 30), ("TreeGate_Lichen", 12),
              ("TreeGate_Streak", 20), ("TreeGate_Root", 19), ("TreeGate_Canopy", 21), ("TreeGate_Canopy", 12)}


def world_tris(path):
    """[(nume_nod, (p0, p1, p2))] in coordonate Godot (transformarile nodurilor aplicate)."""
    g, blob = load_glb(path)[:2]
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

    out = []
    for i, n in enumerate(g["nodes"]):
        if "mesh" not in n:
            continue
        name = (n.get("name") or "").split(".")[0]
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            pos = [xf(i, p) for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
            idx = [k[0] for k in read_accessor(g, blob, prim["indices"])]
            for t in range(0, len(idx) - 2, 3):
                out.append((name, (pos[idx[t]], pos[idx[t + 1]], pos[idx[t + 2]])))
    return out


def _clip(poly, axis, lo, hi):
    """Taie poligonul (lista de puncte 3D) pe lo <= p[axis] <= hi."""
    for sign, bound in ((1, lo), (-1, hi)):
        res = []
        n = len(poly)
        for k in range(n):
            a, b = poly[k], poly[(k + 1) % n]
            da, db = sign * (a[axis] - bound), sign * (b[axis] - bound)
            if da >= 0:
                res.append(a)
            if (da >= 0) != (db >= 0):
                t = da / (da - db)
                res.append(tuple(a[i] + (b[i] - a[i]) * t for i in range(3)))
        poly = res
        if not poly:
            return []
    return poly


def gap_and_clear(tris, half, band=BAND, nodes=None):
    """-> (gol_dreapta, gol_stanga, inaltime_libera, nod_cel_mai_jos).
    gol_* = cel mai apropiat de axa punct (|x|) din banda; inaltime libera = cota
    minima a geometriei taiate pe fasia |x| < half (deasupra solului)."""
    right, left = 1e9, 1e9
    zmin, who = 1e9, None
    for name, tri in tris:
        if nodes and name not in nodes:
            continue
        ys = [p[1] for p in tri]
        if max(ys) >= band[0] and min(ys) <= band[1]:
            poly = _clip(list(tri), 1, band[0], band[1])
            for p in poly:
                if p[0] >= 0:
                    right = min(right, p[0])
                else:
                    left = min(left, -p[0])
        xs = [p[0] for p in tri]
        if max(xs) > -half and min(xs) < half:
            poly = _clip(list(tri), 0, -half + TOL, half - TOL)
            for p in poly:
                if p[1] > 0.05 and p[1] < zmin:
                    zmin, who = p[1], name
    return right, left, zmin, who


def extent(tris, nodes=None):
    pts = [p for n, t in tris if not nodes or n in nodes for p in t]
    return [(min(p[a] for p in pts), max(p[a] for p in pts)) for a in range(3)]


def meta(path):
    g = load_glb(path)[0]
    names = sorted((n.get("name") or "").split(".")[0] for n in g["nodes"] if "mesh" in n)
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    xform = []
    for i, n in enumerate(g["nodes"]):
        if i in kids:
            continue
        s, r = n.get("scale", [1, 1, 1]), n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            xform.append(n.get("name"))
    return names, xform


def check_gopura(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    (x0, x1), (y0, y1), (z0, z1) = extent(tris)
    length, height, depth = x1 - x0, y1 - y0, z1 - z0
    r, l, zc, who = gap_and_clear(tris, 5.0)
    if report:
        print("gopura   lungime %.2f (X %.2f..%.2f)  inaltime %.2f  adancime %.2f  minY %.3f"
              % (length, x0, x1, height, depth, y0))
        print("         gol: dreapta %.3f + stanga %.3f = %.3f m (banda %.1f-%.1f m)   inaltime libera %.2f m (%s)"
              % (r, l, r + l, BAND[0], BAND[1], zc, who))
    if not 50.0 <= length <= 56.0:
        bad.append("lungime %.2f in afara 50-56" % length)
    if not 14.0 <= height <= 16.0:
        bad.append("inaltime %.2f in afara 14-16" % height)
    if not 8.0 <= depth <= 12.0:
        bad.append("adancime %.2f in afara 8-12" % depth)
    if abs(y0) > 0.02:
        bad.append("min Y %.3f != 0" % y0)
    if abs((x0 + x1) / 2) > 0.1:
        bad.append("necentrat pe X")
    if r < 5.0 - TOL or l < 5.0 - TOL or r + l < 10.0 - TOL:
        bad.append("gol %.3f (dr %.3f, st %.3f) < 10,0 / 2 x 5,0" % (r + l, r, l))
    if zc < 8.0:
        bad.append("inaltime libera %.2f < 8,0 (%s)" % (zc, who))
    if names is not None and names != GOPURA_NODES:
        bad.append("noduri %s, cerute %s" % (names, GOPURA_NODES))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    if slots is not None:
        tot = sum(slots.values())
        orange = sum(v for (n, s_), v in slots.items() if s_ == 30)
        if report:
            print("         arii: total %.0f m2, lichen portocaliu %.2f%%" % (tot, 100 * orange / tot))
        if orange / tot >= 0.03:
            bad.append("lichen portocaliu %.2f%% >= 3%%" % (100 * orange / tot))
        extra = sorted(k for k in slots if k not in GOPURA_SLOTS)
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b in bad:
        print("   !! " + b)
    return not bad


def check_treegate(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    (sx0, sx1), (sy0, sy1), (sz0, sz1) = extent(tris, ["TreeGate_Stone"])
    (ax0, ax1), (ay0, ay1), (az0, az1) = extent(tris)
    sw, top = sx1 - sx0, sy1
    r, l, zc, who = gap_and_clear(tris, 3.3)
    _, _, zc_root, _ = gap_and_clear(tris, 3.3, nodes=["TreeGate_Root"])
    if report:
        print("treegate gresia %.2f lat (X %.2f..%.2f), adanc %.2f, varf %.2f | tot %.2f x %.2f x %.2f, minY %.3f"
              % (sw, sx0, sx1, sz1 - sz0, top, ax1 - ax0, az1 - az0, ay1 - ay0, ay0))
        print("         gol: dreapta %.3f + stanga %.3f = %.3f m   inaltime libera %.2f m (%s); radacina cea mai joasa in |x|<3,3: %.2f"
              % (r, l, r + l, zc, who, zc_root))
    if not 13.0 <= sw <= 15.0:
        bad.append("gresia %.2f lat, cerut ~14 (13-15)" % sw)
    if not 7.0 <= top <= 9.0:
        bad.append("varful gresiei %.2f in afara 7-9" % top)
    if not 18.0 <= ay1 - ay0 <= 22.0:
        bad.append("arborele %.2f in afara 18-22" % (ay1 - ay0))
    if abs(ay0) > 0.02:
        bad.append("min Y %.3f != 0" % ay0)
    if r < 3.3 - TOL or l < 3.3 - TOL or r + l < 6.6 - TOL:
        bad.append("gol %.3f (dr %.3f, st %.3f) < 6,6" % (r + l, r, l))
    if zc < 5.5:
        bad.append("inaltime libera %.2f < 5,5 (%s)" % (zc, who))
    if names is not None and names != TREE_NODES:
        bad.append("noduri %s, cerute %s" % (names, TREE_NODES))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    if slots is not None:
        tot = sum(slots.values())
        orange = sum(v for (n, s_), v in slots.items() if s_ == 30)
        if report:
            print("         arii: total %.0f m2, lichen portocaliu %.2f%%" % (tot, 100 * orange / tot))
        if orange / tot >= 0.03:
            bad.append("lichen portocaliu %.2f%% >= 3%%" % (100 * orange / tot))
        extra = sorted(k for k in slots if k not in TREE_SLOTS)
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b in bad:
        print("   !! " + b)
    return not bad


# --- sabotaje (pe lista de triunghiuri, in memorie) ---------------------------

def _box_tris(name, x0, x1, y0, y1, z0, z1):
    v = [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
    q = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    out = []
    for a, b, c, d in q:
        out.append((name, (v[a], v[b], v[c])))
        out.append((name, (v[a], v[c], v[d])))
    return out


def _move(tris, pred, d):
    out = []
    for n, t in tris:
        if pred(n, t):
            t = tuple((p[0] + d[0], p[1] + d[1], p[2] + d[2]) for p in t)
        out.append((n, t))
    return out


def sabotage_gopura(tris):
    side = lambda n, t: all(abs(p[0]) >= 5.0 - 1e-4 and abs(p[0]) <= 9.2 for p in t) and min(p[1] for p in t) < 8.9 and all(abs(p[2]) < 5.2 for p in t)
    def jambs(n, t):
        return side(n, t)
    cases = []
    # picioarele mutate spre axa cu 0,6 m (jumatatea golului 5,1 -> 4,5)
    c = []
    for n, t in tris:
        if side(n, t):
            sgn = 1 if sum(p[0] for p in t) > 0 else -1
            t = tuple((p[0] - sgn * 0.6, p[1], p[2]) for p in t)
        c.append((n, t))
    cases.append(("picioare mutate la +-4,5", c))
    cases.append(("stalp in mijlocul golului", tris + _box_tris("Gopura_Stone", -0.4, 0.4, -0.4, 0.4, 0.0, 3.0)))
    cases.append(("buiandrug coborat 1,5 m",
                  _move(tris, lambda n, t: all(abs(p[0]) < 5.1 for p in t) and min(p[1] for p in t) >= 8.9, (0, -1.5, 0))))
    cases.append(("lungime scalata 1,15x", [(n, tuple((p[0] * 1.15, p[1], p[2]) for p in t)) for n, t in tris]))
    return cases


def sabotage_tree(tris):
    cases = []
    cases.append(("radacina impinsa in gol la 3 m", tris + _box_tris("TreeGate_Root", -0.4, 0.4, 2.6, 3.4, 2.6, 3.4)))
    # o radacina reala trasa in gol: triunghiurile de radacina cu x in [-5,-3.4] si z in [2,4] mutate cu +1,5 pe X
    cases.append(("radacina reala trasa in gol",
                  _move(tris, lambda n, t: n == "TreeGate_Root" and all(-6.5 < p[0] < -3.0 and 1.0 < p[1] < 5.0 for p in t), (2.2, 0, 0))))
    c = []
    for n, t in tris:
        if n == "TreeGate_Stone" and all(3.2 <= abs(p[0]) <= 5.7 for p in t) and max(p[1] for p in t) < 5.7 and all(abs(p[2]) < 3.3 for p in t):
            sgn = 1 if sum(p[0] for p in t) > 0 else -1
            t = tuple((p[0] - sgn * 0.45, p[1], p[2]) for p in t)
        c.append((n, t))
    cases.append(("picioare mutate la +-3,0", c))
    cases.append(("buiandrug coborat 0,8 m",
                  _move(tris, lambda n, t: n == "TreeGate_Stone" and all(abs(p[0]) < 5.7 for p in t) and min(p[1] for p in t) >= 5.55 and all(abs(p[2]) < 3.3 for p in t), (0, -0.8, 0))))
    cases.append(("bloc cazut in gol", tris + _box_tris("TreeGate_Stone", -1.0, 1.0, 0.0, 1.0, 0.0, 1.2)))
    return cases


def selftest(gop, tre):
    ok = True
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, path, fn, cases in (
            ("gopura", gop, check_gopura, sabotage_gopura), ("treegate", tre, check_treegate, sabotage_tree)):
        tris = world_tris(path)
        for name, bad_tris in cases(tris):
            print("-- sabotaj %s: %s" % (label, name))
            if fn(bad_tris, report=False):
                print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
                ok = False
            else:
                print("   garda a picat, cum trebuie")
        print("-- originalul %s:" % label)
        if not fn(tris, report=False):
            print("   !! SELFTEST ESUAT: garda pica pe original")
            ok = False
        else:
            print("   originalul trece")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest" and len(a) >= 3:
        sys.exit(0 if selftest(a[1], a[2]) else 1)
    if len(a) >= 2 and a[0] in ("gopura", "treegate"):
        tris = world_tris(a[1])
        names, xform = meta(a[1])
        slots = slot_areas(a[1])
        fn = check_gopura if a[0] == "gopura" else check_treegate
        sys.exit(0 if fn(tris, names, xform, slots) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
