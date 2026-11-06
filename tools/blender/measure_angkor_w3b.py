"""Garda grupului B, val 3: kitul galeriei si Bakheng (kit §1.5).
Citeste GLB-ul EXPORTAT, in coordonate GODOT (Y sus; Blender +Y = Godot -Z).

    python tools/blender/measure_angkor_w3b.py <piesa> <glb>
    python tools/blender/measure_angkor_w3b.py --selftest <kit_dir>

piese: column roof wall corner tier shrine stair

Pe fiecare: anvelopa (X, Y, Z) in +-5% fata de contract, min Y ~ 0, numele nodurilor,
scala/rotatia aplicate pe radacini, doar sloturile din tabel, lichen portocaliu < 3% din arie.
Pe modulele care se inlantuie (roof pe Z, wall si tier pe X): capetele EXACT la +-L/2
(+-1 mm), NICIUN varf in banda (L/2 - 5 cm, L/2 - 0,5 mm) -- adica capatul e un plan, nu
o margine zimtata --, si profilul capatului de +L/2 are aceeasi cutie ca cel de -L/2.

`--selftest`: copii sabotate IN MEMORIE trebuie sa PICE (modul cu 0,3 m mai lung, pe fiecare
din cele trei; acoperis cu un capat inclinat; acoperis cu varfurile de sus trase 15 cm
inapoi; stalp scalat 1,2x), iar originalele trebuie sa treaca.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_angkor_w1b import world_tris, extent, meta  # noqa: E402
from measure_angkor import slot_areas  # noqa: E402

TOL = 0.05

# nume: (X, Y, Z, noduri, sloturi, axa lantului sau None, L)
SPEC = {
    "column": (0.5, 3.5, 0.5, "GalleryColumn", {("Stone", 3), ("Lichen", 30), ("Lichen", 12), ("Streak", 20)}, None, 0),
    "roof": (4.0, 2.0, 4.0, "GalleryRoof", {("Stone", 3), ("Lichen", 30), ("Lichen", 12)}, 2, 4.0),
    "wall": (4.0, 3.5, 0.6, "GalleryRelief", {("Stone", 3), ("Lichen", 30), ("Lichen", 12), ("Streak", 20)}, 0, 4.0),
    "corner": (4.0, 5.5, 4.0, "GalleryCorner", {("Stone", 3), ("Lichen", 30), ("Lichen", 12)}, None, 0),
    "tier": (8.0, 1.5, 4.0, "BakhengTier", {("Stone", 3), ("Lichen", 30), ("Lichen", 12), ("Streak", 20)}, 0, 8.0),
    "shrine": (2.5, 4.0, 2.5, "BakhengShrine", {("Stone", 3), ("Brick", 23), ("Lichen", 30), ("Lichen", 12), ("Streak", 20)}, None, 0),
    "stair": (2.0, 3.0, 3.5, "BakhengStair", {("Stone", 3), ("Lichen", 30), ("Lichen", 12), ("Streak", 20)}, None, 0),
}
FILES = {"column": "gallery_column", "roof": "gallery_roof", "wall": "gallery_relief_wall",
         "corner": "gallery_corner", "tier": "bakheng_terrace_tier", "shrine": "bakheng_shrine_tower",
         "stair": "bakheng_side_stair"}
NODE_SUFFIXES = {"column": ["Lichen", "Stone", "Streak"], "roof": ["Lichen", "Stone"],
                 "wall": ["Lichen", "Stone", "Streak"], "corner": ["Lichen", "Stone"],
                 "tier": ["Lichen", "Stone", "Streak"], "shrine": ["Brick", "Lichen", "Stone", "Streak"],
                 "stair": ["Lichen", "Stone", "Streak"]}


def chain_ends(tris, axis, L, report):
    bad = []
    h = L / 2.0
    pts = [p for _, t in tris for p in t]
    lo, hi = min(p[axis] for p in pts), max(p[axis] for p in pts)
    if abs(lo + h) > 1e-3 or abs(hi - h) > 1e-3:
        bad.append("capete %.4f / %.4f, cerute +-%.3f" % (lo, hi, h))
    near = [p for p in pts if h - TOL < abs(p[axis]) < h - 5e-4]
    if near:
        bad.append("%d varfuri in banda de %.0f cm dinaintea capatului (capat zimtat / neplan)" % (len(near), TOL * 100))
    others = [a for a in range(3) if a != axis]
    box = []
    for sgn in (1, -1):
        e = [p for p in pts if abs(p[axis] - sgn * h) <= 5e-4]
        if len(e) < 8:
            bad.append("capatul %+d: doar %d varfuri pe plan" % (sgn, len(e)))
            box.append(None)
            continue
        box.append([(min(p[a] for p in e), max(p[a] for p in e)) for a in others])
    if box[0] and box[1]:
        for a, (u, v) in enumerate(zip(box[0], box[1])):
            if abs(u[0] - v[0]) > 0.01 or abs(u[1] - v[1]) > 0.01:
                bad.append("profilele celor doua capete difera pe axa %d: %s vs %s" % (others[a], u, v))
    if report:
        print("         capete pe axa %d: [%.4f, %.4f]; profil capat: %s" % (axis, lo, hi,
              [tuple(round(v, 3) for v in b) for b in box[0] or []]))
    return bad


def check(name, tris, names=None, xform=None, slots=None, report=True):
    X, Y, Z, prefix, allowed, axis, L = SPEC[name]
    bad = []
    e = extent(tris)
    dims = [b - a for a, b in e]
    if report:
        print("%-8s cote X %.3f  Y %.3f  Z %.3f  (contract %.2f %.2f %.2f, +-5%%)  min Y %.3f"
              % (name, dims[0], dims[1], dims[2], X, Y, Z, e[1][0]))
    for ax, d, r in zip("XYZ", dims, (X, Y, Z)):
        if abs(d / r - 1.0) > 0.05:
            bad.append("cota %s %.3f in afara +-5%% fata de %.2f" % (ax, d, r))
    if abs(e[1][0]) > 0.02:
        bad.append("min Y %.3f != 0" % e[1][0])
    if axis is not None:
        bad += chain_ends(tris, axis, L, report)
    want = sorted("%s_%s" % (prefix, s) for s in NODE_SUFFIXES[name])
    if names is not None and names != want:
        bad.append("noduri %s, cerute %s" % (names, want))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    if slots is not None:
        tot = sum(slots.values())
        orange = sum(v for (n, s_), v in slots.items() if s_ == 30)
        if report:
            print("         arii: total %.1f m2, lichen portocaliu %.2f%%" % (tot, 100 * orange / tot))
        if orange / tot >= 0.03:
            bad.append("lichen portocaliu %.2f%% >= 3%%" % (100 * orange / tot))
        extra = sorted(k for k in slots if (k[0].split("_", 1)[1], k[1]) not in allowed)
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b in bad:
        print("   !! " + b)
    return not bad


def _map(tris, fn):
    return [(n, tuple(fn(p) for p in t)) for n, t in tris]


def sabotages(name, tris):
    axis, L = SPEC[name][5], SPEC[name][6]
    out = []
    if axis is not None:
        def longer(p):
            q = list(p)
            if q[axis] > 0:
                q[axis] += 0.3
            return tuple(q)
        out.append(("modul cu 0,3 m mai lung", _map(tris, longer)))
    if name == "roof":
        def slanted(p):
            q = list(p)
            if q[2] > 1.9:
                q[2] += 0.2 * q[1] / 2.0          # capat inclinat: planul nu mai e perpendicular
            return tuple(q)

        def pulled(p):
            q = list(p)
            if q[2] > 1.9 and q[1] > 1.0:
                q[2] -= 0.15                      # varfurile de sus trase inapoi: capat in trepte
            return tuple(q)
        out.append(("capat inclinat (nu e plan)", _map(tris, slanted)))
        out.append(("capat in trepte (varfurile de sus trase 15 cm)", _map(tris, pulled)))
    if name == "column":
        out.append(("stalp scalat 1,2x", _map(tris, lambda p: (p[0] * 1.2, p[1] * 1.2, p[2] * 1.2))))
    return out


def selftest(kit):
    ok = True
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for name in ("column", "roof", "wall", "tier"):
        tris = world_tris(os.path.join(kit, FILES[name] + ".glb"))
        for label, bad in sabotages(name, tris):
            print("-- sabotaj %s: %s" % (name, label))
            if check(name, bad, report=False):
                print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
                ok = False
            else:
                print("   garda a picat, cum trebuie")
        print("-- originalul %s:" % name)
        if not check(name, tris, report=False):
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
    if len(a) >= 2 and a[0] in SPEC:
        tris = world_tris(a[1])
        names, xform = meta(a[1])
        slots = slot_areas(a[1])
        sys.exit(0 if check(a[0], tris, names, xform, slots) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
