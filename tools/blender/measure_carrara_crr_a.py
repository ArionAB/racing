"""Garzile pieselor crr-a din kitul Carrara (derrick, blocul agatat, sania,
blocul informe) -- citesc GLB-ul EXPORTAT, in coordonate GODOT (Y sus, -Z
inainte), cu transformarile nodurilor. Excavatorul are garda lui:
measure_carrara_excavator.py.

    python tools/blender/measure_carrara_crr_a.py derrick <glb>
    python tools/blender/measure_carrara_crr_a.py block   <glb>
    python tools/blender/measure_carrara_crr_a.py sled    <glb>
    python tools/blender/measure_carrara_crr_a.py informe <glb>

Contractele (docs/asset_briefs/carrara_kit.md §1.1, scenes/hazards/*.gd):
  derrick  doua radacini `Jib` si `TowerCrane`, ambele mesh, fara translatie
           (codul pune Jib pe pivot cu transformul lui local); TowerCrane de la
           Y 0 la EXACT 22,05 (JIB_HEIGHT), pe X in +-1,8 (MAST_SIDE / 2: nimic
           spre drum, oricare ar fi partea turnului); pe Z (in lungul drumului)
           in fata axei tot +-1,8, in spate picioarele A-frame-ului au voie pana
           la 8,5; carligul desenat (varfurile cele mai joase ale lui Jib) la
           Z -17,9 +-0,15 (hook_radius 17,9 = 13 m in joc la 0,7256), bratul nu
           trece de Z -18,5.
  block    anvelopa SLAB_SIZE: X 4,6, Z 2,2 (+-0,02), de la Y -3,05 la cel mult 0
           (chingi si inel), iar MARMURA singura de la -3,05+0,04 la -0,06 si
           pe X la +-2,3 (+-0,02): blocul umple colizorul.
  sled     amprenta X si Z 2,4 +-0,2 (sfera = max(X,Z)/2), inaltime 2,3..2,6.
  informe  3 m +-10% pe fiecare axa, |X - Z| <= 0,15 (sfera = max(X,Z)/2).
Iese cu cod 1 la orice abatere sau la zero varfuri citite.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor
from measure_carrara_truck import quat_rot


def nodes_points(path):
    g, blob = load_glb(path)[:2]
    nodes = g["nodes"]
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i

    def xf(i, p):
        n = nodes[i]
        s = n.get("scale", [1, 1, 1])
        p = (p[0] * s[0], p[1] * s[1], p[2] * s[2])
        p = quat_rot(n.get("rotation", [0, 0, 0, 1]), p)
        t = n.get("translation", [0, 0, 0])
        p = (p[0] + t[0], p[1] + t[1], p[2] + t[2])
        return xf(parent[i], p) if i in parent else p

    out = {}
    for i, n in enumerate(nodes):
        if "mesh" not in n:
            continue
        pts = [xf(i, p) for prim in g["meshes"][n["mesh"]]["primitives"]
               for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
        out[n.get("name")] = pts
    roots = set(g["scenes"][g.get("scene", 0)]["nodes"])
    return g, out, roots


def bbox(pts):
    return [(min(p[k] for p in pts), max(p[k] for p in pts)) for k in range(3)]


def fmt(bb):
    return "X %+.3f..%+.3f  Y %+.3f..%+.3f  Z %+.3f..%+.3f" % tuple(v for a in bb for v in a)


def check_derrick(path, bad):
    g, pts, roots = nodes_points(path)
    names = {g["nodes"][i].get("name"): i for i in roots}
    for want in ("Jib", "TowerCrane"):
        if want not in names or want not in pts:
            bad.append("lipseste radacina-mesh %s (radacini: %s)" % (want, sorted(names)))
            return
        t = g["nodes"][names[want]].get("translation", [0, 0, 0])
        if any(abs(v) > 1e-4 for v in t):
            bad.append("%s are translatie %s (codul il muta cu transformul local)" % (want, t))
    m = bbox(pts["TowerCrane"])
    j = bbox(pts["Jib"])
    print("TowerCrane  " + fmt(m))
    print("Jib         " + fmt(j))
    if abs(m[1][0]) > 0.01:
        bad.append("catargul nu porneste de la Y 0 (%.3f)" % m[1][0])
    if abs(m[1][1] - 22.05) > 0.01:
        bad.append("varful catargului %.3f != JIB_HEIGHT 22,05" % m[1][1])
    if m[0][0] < -1.8 or m[0][1] > 1.8:
        bad.append("catargul iese pe X din +-1,8 (%.3f..%.3f)" % m[0])
    if m[2][0] < -1.8:
        bad.append("catargul iese in fata (-Z) peste 1,8 (%.3f)" % m[2][0])
    if m[2][1] > 8.5:
        bad.append("A-frame-ul trece in spate de 8,5 (%.3f)" % m[2][1])
    ymin = j[1][0]
    low = [p for p in pts["Jib"] if p[1] < ymin + 0.3]
    hz = sum(p[2] for p in low) / len(low)
    print("carligul desenat: Y min %.3f, Z mediu al varfurilor de jos %.3f (cerut -17,9)" % (ymin, hz))
    if abs(hz + 17.9) > 0.15:
        bad.append("carligul la Z %.3f, cerut -17,9 +-0,15" % hz)
    if j[2][0] < -18.5:
        bad.append("bratul trece de Z -18,5 (%.3f)" % j[2][0])


def check_block(path, bad):
    _, pts, _ = nodes_points(path)
    allp = [p for v in pts.values() for p in v]
    marble = [p for k, v in pts.items() if k.endswith(("_Marble", "_MarbleBase")) for p in v]
    if not allp or not marble:
        bad.append("zero varfuri / fara marmura (noduri %s)" % sorted(pts))
        return
    a, mb = bbox(allp), bbox(marble)
    print("tot      " + fmt(a))
    print("marmura  " + fmt(mb))
    if abs((a[0][1] - a[0][0]) - 4.6) > 0.02 or abs((a[2][1] - a[2][0]) - 2.2) > 0.02:
        bad.append("anvelopa X/Z %.3f x %.3f != 4,6 x 2,2" % (a[0][1] - a[0][0], a[2][1] - a[2][0]))
    if abs(a[1][0] + 3.05) > 0.01 or a[1][1] > 0.001 or a[1][1] < -0.06:
        bad.append("Y %.3f..%.3f, cerut -3,05..(<=0, >=-0,06)" % a[1])
    if abs(mb[0][0] + 2.3) > 0.02 or abs(mb[0][1] - 2.3) > 0.02:
        bad.append("marmura nu umple X +-2,3 (%.3f..%.3f)" % mb[0])
    if mb[1][0] > -3.05 + 0.04 + 1e-3 or abs(mb[1][1] + 0.06) > 0.01:
        bad.append("marmura Y %.3f..%.3f, cerut <=-3,01 .. -0,06" % mb[1])


def check_sled(path, bad):
    _, pts, _ = nodes_points(path)
    allp = [p for v in pts.values() for p in v]
    if not allp:
        bad.append("zero varfuri")
        return
    a = bbox(allp)
    sx, sy, sz = (a[k][1] - a[k][0] for k in range(3))
    print("sania    " + fmt(a) + "   (%.3f x %.3f x %.3f; raza sferei %.3f)" % (sx, sy, sz, max(sx, sz) / 2))
    for nm, v in (("X", sx), ("Z", sz)):
        if abs(v - 2.4) > 0.2:
            bad.append("amprenta %s %.3f, cerut 2,4 +-0,2" % (nm, v))
    if not 2.3 <= sy <= 2.6:
        bad.append("inaltimea %.3f in afara 2,3..2,6" % sy)


def check_informe(path, bad):
    _, pts, _ = nodes_points(path)
    allp = [p for v in pts.values() for p in v]
    if not allp:
        bad.append("zero varfuri")
        return
    a = bbox(allp)
    s = [a[k][1] - a[k][0] for k in range(3)]
    print("informe  " + fmt(a) + "   (%.3f x %.3f x %.3f)" % tuple(s))
    for nm, v in zip("XYZ", s):
        if abs(v - 3.0) > 0.3:
            bad.append("%s %.3f in afara 3 +-10%%" % (nm, v))
    if abs(s[0] - s[2]) > 0.15:
        bad.append("amprenta nepatrata: X %.3f vs Z %.3f" % (s[0], s[2]))


CHECKS = {"derrick": check_derrick, "block": check_block, "sled": check_sled,
          "informe": check_informe}


def main():
    kind, path = sys.argv[1], sys.argv[2]
    bad = []
    CHECKS[kind](path, bad)
    for b in bad:
        print("   !! " + b)
    print("%s: %s" % (kind, "OK" if not bad else "PROBLEME"))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
