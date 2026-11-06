"""Garda grupului B, val 4: vegetatia mica (kit §1.7) -- strangler_fig, vine_strands,
lotus_cluster, water_lily_pads. Citeste GLB-ul EXPORTAT, in coordonate GODOT (Y sus; Blender
+Y = Godot -Z).

    python tools/blender/measure_angkor_w4b.py fig    <glb>
    python tools/blender/measure_angkor_w4b.py vine   <glb>
    python tools/blender/measure_angkor_w4b.py lotus  <glb>
    python tools/blender/measure_angkor_w4b.py lily   <glb>
    python tools/blender/measure_angkor_w4b.py --selftest <plants_dir>

Contracte:
  fig:   inaltimea 10 +-1,5 m, min Y ~ 0, X 7-10 m, Z 4-9 m; noduri Fig_Leaves / Fig_Root /
         Fig_Stone; zidul (Fig_Stone) are 5,0 +-0,3 m inaltime (vezi kit: ~5 m); sloturile:
         piatra 3, radacina 19, frunze 21 + 12.
  vine:  4-6 radacini `Strand_0..N` consecutive, transformari identitate, fiecare ATARNA sub
         origine (max Y <= 0,05), lungime 3,0-4,5 m, latime laterala 0,1-0,45 m, <= 300 tri.
         Sloturi: 21 pe liane, 19 pe radacinile aeriene (un singur slot-radacina pe suvita).
  lotus: nodurile Lotus_Leaves / Lotus_Flowers, intindere in plan 1,5-3,0 m, max Y <= 0,40,
         min Y >= -0,02 (origine la apa), florile (slot 31) au aria > 0.
  lily:  nodul Lily_Pads, intindere 1,5-3,0 m, max Y <= 0,05, min Y >= -0,02, doar sloturile 12 +
         21, FIECARE pad cu crestatura (aria proiectata a insulei < 95% din discul cu diametrul
         bbox-ului; un disc intreg cu 14 laturi are ~97%).

`--selftest`: copii sabotate IN MEMORIE trebuie sa PICE: suvita atarnand IN SUS (originea jos),
suvita 5,5 m, o a saptea suvita, scala pe o radacina; nufar ridicat 0,3 m, nufar fara crestatura;
lotus ridicat 0,5 m; ficus turtit la 0,6x. Originalele trebuie sa treaca.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_angkor_w1b import world_tris, extent, meta  # noqa: E402
from measure_angkor import slot_areas  # noqa: E402

FILES = {"fig": "strangler_fig", "vine": "vine_strands", "lotus": "lotus_cluster", "lily": "water_lily_pads"}


def _nodes(tris):
    return sorted({n for n, _ in tris})


def _dims(tris, nodes=None):
    e = extent(tris, nodes)
    return [b - a for a, b in e], e


def check_fig(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    d, e = _dims(tris)
    stone = _dims(tris, ["Fig_Stone"])[1]
    if report:
        print("fig      X %.2f  Y(inaltime) %.2f  Z %.2f   min Y %.3f   zid (Fig_Stone) %.2f m"
              % (d[0], d[1], d[2], e[1][0], stone[1][1] - stone[1][0]))
    if abs(d[1] - 10.0) > 1.5:
        bad.append("inaltime %.2f in afara 10 +-1,5" % d[1])
    if not 7.0 <= d[0] <= 10.0:
        bad.append("latime X %.2f in afara 7-10" % d[0])
    if not 4.0 <= d[2] <= 9.0:
        bad.append("adancime Z %.2f in afara 4-9" % d[2])
    if abs(e[1][0]) > 0.02:
        bad.append("min Y %.3f != 0" % e[1][0])
    wall = stone[1][1] - stone[1][0]
    if abs(wall - 5.0) > 0.3:
        bad.append("zidul are %.2f m, cerut 5,0 +-0,3" % wall)
    want = ["Fig_Leaves", "Fig_Root", "Fig_Stone"]
    if names is not None and names != want:
        bad.append("noduri %s, cerute %s" % (names, want))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    if slots is not None:
        allowed = {("Fig_Stone", 3), ("Fig_Root", 19), ("Fig_Leaves", 21), ("Fig_Leaves", 12)}
        extra = sorted(k for k in slots if k not in allowed)
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b in bad:
        print("   !! " + b)
    return not bad


def check_vine(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    nodes = _nodes(tris)
    n = len(nodes)
    if not 4 <= n <= 6:
        bad.append("%d suvite, cerute 4-6" % n)
    if nodes != ["Strand_%d" % i for i in range(n)]:
        bad.append("nume %s, cerute Strand_0..Strand_%d" % (nodes, n - 1))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    for nm in nodes:
        e = extent(tris, [nm])
        cnt = sum(1 for k, _ in tris if k == nm)
        length = -e[1][0]
        width = max(e[0][1] - e[0][0], e[2][1] - e[2][0])
        if report:
            print("%-9s lungime %.2f  max Y %+.3f  latime %.2f  %d tri" % (nm, length, e[1][1], width, cnt))
        if e[1][1] > 0.05:
            bad.append("%s: max Y %.3f > 0,05 (nu atarna sub origine)" % (nm, e[1][1]))
        if not 3.0 <= length <= 4.5:
            bad.append("%s: lungime %.2f in afara 3,0-4,5" % (nm, length))
        if not 0.1 <= width <= 0.45:
            bad.append("%s: latime %.2f in afara 0,1-0,45" % (nm, width))
        if cnt > 300:
            bad.append("%s: %d triunghiuri > 300" % (nm, cnt))
    if slots is not None:
        for nm in nodes:
            used = sorted(s for (k, s) in slots if k == nm)
            if used not in ([21], [19]):
                bad.append("%s: sloturi %s, cerut doar [21] (liana) sau doar [19] (radacina)" % (nm, used))
    for b in bad:
        print("   !! " + b)
    return not bad


def check_plan(tris, name, lo_y, hi_y, report, label):
    bad = []
    d, e = _dims(tris)
    span = max(d[0], d[2])
    if report:
        print("%-8s X %.2f  Z %.2f  Y %.3f..%.3f  (Y max cerut <= %.2f)" % (label, d[0], d[2], e[1][0], e[1][1], hi_y))
    if not 1.5 <= span <= 3.0:
        bad.append("intindere in plan %.2f in afara 1,5-3,0" % span)
    if e[1][1] > hi_y:
        bad.append("max Y %.3f > %.2f (peste apa)" % (e[1][1], hi_y))
    if e[1][0] < lo_y:
        bad.append("min Y %.3f < %.2f (sub apa)" % (e[1][0], lo_y))
    return bad


def check_lotus(tris, names=None, xform=None, slots=None, report=True):
    bad = check_plan(tris, "lotus", -0.02, 0.40, report, "lotus")
    want = ["Lotus_Flowers", "Lotus_Leaves"]
    if names is not None and names != want:
        bad.append("noduri %s, cerute %s" % (names, want))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    if slots is not None:
        pink = slots.get(("Lotus_Flowers", 31), 0.0)
        if report:
            print("         arie flori roz %.3f m2" % pink)
        if pink <= 0.0:
            bad.append("nicio floare FLAMINGO_PINK 31")
        allowed = {("Lotus_Flowers", 31), ("Lotus_Flowers", 21), ("Lotus_Flowers", 12),
                   ("Lotus_Leaves", 21), ("Lotus_Leaves", 12)}
        extra = sorted(k for k in slots if k not in allowed)
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b in bad:
        print("   !! " + b)
    return not bad


def pad_islands(tris):
    """Insulele de varfuri (pad-uri) si aria proiectata a fetelor orientate in sus."""
    parent = {}

    def key(p):
        return (round(p[0], 4), round(p[1], 4), round(p[2], 4))

    def find(k):
        while parent.setdefault(k, k) != k:
            parent[k] = parent[parent[k]]
            k = parent[k]
        return k
    for _, t in tris:
        ks = [key(p) for p in t]
        for k in ks[1:]:
            parent[find(k)] = find(ks[0])
    groups = {}
    for _, t in tris:
        groups.setdefault(find(key(t[0])), []).append(t)
    out = []
    for g in groups.values():
        pts = [p for t in g for p in t]
        xs, zs = [p[0] for p in pts], [p[2] for p in pts]
        diam = max(max(xs) - min(xs), max(zs) - min(zs))
        top = 0.0
        for a, b, c in g:
            u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
            v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
            ny = u[2] * v[0] - u[0] * v[2]            # componenta Y (sus) a produsului vectorial
            if ny > 0:
                top += 0.5 * ny
        out.append((diam, top))
    return out


def lily_problems(tris, names=None, xform=None, slots=None, report=True):
    bad = check_plan(tris, "lily", -0.02, 0.05, report, "lily")
    if names is not None and names != ["Lily_Pads"]:
        bad.append("noduri %s, cerut ['Lily_Pads']" % names)
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    if slots is not None:
        extra = sorted(k for k in slots if k[1] not in (12, 21))
        if extra:
            bad.append("sloturi in afara tabelului (12/21): %s" % extra)
    isl = pad_islands(tris)
    ratios = [(top / (math.pi * (dm * 0.5) ** 2) if dm > 1e-6 else 1.0) for dm, top in isl]
    if report:
        print("         %d pad-uri; raport arie/disc: %s" % (len(isl), " ".join("%.2f" % r for r in sorted(ratios))))
    if len(isl) < 5:
        bad.append("doar %d pad-uri" % len(isl))
    for r in ratios:
        if r >= 0.95:
            bad.append("pad fara crestatura (arie %.2f din disc)" % r)
            break
    return bad


def check_lily(tris, names=None, xform=None, slots=None, report=True):
    bad = lily_problems(tris, names, xform, slots, report)
    for b in bad:
        print("   !! " + b)
    return not bad


CHECKS = {"fig": check_fig, "vine": check_vine, "lotus": check_lotus, "lily": check_lily}


def _map_nodes(tris, fn, nodes=None):
    return [(n, tuple(fn(p) for p in t) if (nodes is None or n in nodes) else t) for n, t in tris]


def selftest(plants):
    ok = True
    tris = {k: world_tris(os.path.join(plants, v + ".glb")) for k, v in FILES.items()}
    cases = [
        ("vine", "suvita atarna IN SUS (originea jos)",
         _map_nodes(tris["vine"], lambda p: (p[0], -p[1], p[2]), ["Strand_0"]), None),
        ("vine", "suvita de 5,5 m", _map_nodes(tris["vine"], lambda p: (p[0], p[1] * 1.3, p[2]), ["Strand_3"]), None),
        ("vine", "suvita cu originea coborata 0,3 m (varf peste origine)",
         _map_nodes(tris["vine"], lambda p: (p[0], p[1] + 0.3, p[2]), ["Strand_2"]), None),
        ("vine", "scala pe o radacina", tris["vine"], ["Strand_1"]),
        ("vine", "a saptea suvita",
         tris["vine"] + [("Strand_6", t) for _, t in tris["vine"] if _ == "Strand_0"][:10] +
         [("Strand_7", t) for _, t in tris["vine"] if _ == "Strand_1"][:10], None),
        ("lily", "nufar ridicat 0,3 m", _map_nodes(tris["lily"], lambda p: (p[0], p[1] + 0.3, p[2])), None),
        ("lotus", "lotus ridicat 0,5 m", _map_nodes(tris["lotus"], lambda p: (p[0], p[1] + 0.5, p[2])), None),
        ("fig", "ficus turtit la 0,6x", _map_nodes(tris["fig"], lambda p: (p[0], p[1] * 0.6, p[2])), None),
    ]
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for kind, label, bad_tris, xf in cases:
        print("-- sabotaj %s: %s" % (kind, label))
        if CHECKS[kind](bad_tris, xform=xf, report=False):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
    # nufari fara crestatura: sase discuri intregi (14 laturi) in 2 m, plate -- singura problema
    # posibila e lipsa crestaturii, deci mesajul trebuie sa o numeasca
    print("-- sabotaj lily: sase pad-uri FARA crestatura (discuri intregi)")
    full = []
    segs = 14
    for i in range(6):
        cx, cz = -0.9 + 0.9 * (i % 3), -0.5 + 1.0 * (i // 3)
        for k in range(segs):
            a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
            full.append(("Lily_Pads", ((cx, 0.02, cz), (cx + 0.35 * math.sin(a0), 0.02, cz + 0.35 * math.cos(a0)),
                                       (cx + 0.35 * math.sin(a1), 0.02, cz + 0.35 * math.cos(a1)))))
    probs = lily_problems(full, report=False)
    if any("crestatura" in m for m in probs):
        print("   garda a picat, cum trebuie (%s)" % [m for m in probs if "crestatura" in m][0])
    else:
        print("   !! SELFTEST ESUAT: garda NU a prins lipsa crestaturii (%s)" % probs)
        ok = False
    for kind in ("fig", "vine", "lotus", "lily"):
        print("-- originalul %s:" % kind)
        names, xform = meta(os.path.join(plants, FILES[kind] + ".glb"))
        slots = slot_areas(os.path.join(plants, FILES[kind] + ".glb"))
        if not CHECKS[kind](tris[kind], names, xform, slots, report=False):
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
    if len(a) >= 2 and a[0] in CHECKS:
        tris = world_tris(a[1])
        names, xform = meta(a[1])
        slots = slot_areas(a[1])
        sys.exit(0 if CHECKS[a[0]](tris, names, xform, slots) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
