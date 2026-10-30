"""Garda anvelopei camionului Carrara -- citeste GLB-ul EXPORTAT (glTF JSON +
accesoare + transformarile nodurilor), in coordonate GODOT (Y sus, botul pe -Z).

    python tools/blender/measure_carrara_truck.py <glb> [--report]

Contract (kit §1.1, masurat cu Kamaz 2,68 x 3,13 x 8,0): latime <= 2,9 (cu
oglinzi), lungime 7,6-8,2, inaltime <= 3,4, min Y ~ 0, iar cabina inalta e la
capatul -Z (varfurile cele mai inalte ale pieselor FARA marmura, cele de peste
95% din inaltimea lor maxima, au z mediu < 0). Iese cu cod 1 la incalcare.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor


def quat_rot(q, v):
    x, y, z, w = q
    # v' = v + 2w(q x v) + 2 q x (q x v)
    cx = (y * v[2] - z * v[1], z * v[0] - x * v[2], x * v[1] - y * v[0])
    cc = (y * cx[2] - z * cx[1], z * cx[0] - x * cx[2], x * cx[1] - y * cx[0])
    return tuple(v[i] + 2 * (w * cx[i] + cc[i]) for i in range(3))


def world_points(g, blob):
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
        marble = (n.get("name") or "").split(".")[0].endswith(("_Marble", "_MarbleBase"))
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            for p in read_accessor(g, blob, prim["attributes"]["POSITION"]):
                out.append((xf(i, p), marble))
    return out


def measure(path):
    g, blob = load_glb(path)[:2]
    pts = world_points(g, blob)
    xs = [p[0] for p, _ in pts]
    ys = [p[1] for p, _ in pts]
    zs = [p[2] for p, _ in pts]
    dims = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    non = [p for p, m in pts if not m]
    ymax = max(p[1] for p in non)
    tall = [p for p in non if p[1] >= 0.95 * ymax]
    zmean = sum(p[2] for p in tall) / len(tall)
    return dims, (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)), ymax, zmean


def main():
    path = sys.argv[1]
    (w, h, l), bb, ymax, zmean = measure(path)
    print("anvelopa  X(latime) %.3f  Y(inaltime) %.3f  Z(lungime) %.3f   minY %.3f  z_cabina %.2f"
          % (w, h, l, bb[2], zmean))
    bad = []
    if w > 2.9: bad.append("latime %.3f > 2.9" % w)
    if not 7.6 <= l <= 8.2: bad.append("lungime %.3f in afara 7.6-8.2" % l)
    if h > 3.4: bad.append("inaltime %.3f > 3.4" % h)
    if abs(bb[2]) > 0.02: bad.append("min Y %.3f != 0" % bb[2])
    if abs((bb[0] + bb[1]) / 2) > 0.05: bad.append("necentrat pe X")
    if zmean >= 0: bad.append("cabina inalta nu e la capatul -Z (z mediu %.2f)" % zmean)
    for b in bad:
        print("   !! " + b)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
