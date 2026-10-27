"""Garda rigului excavatorului Carrara -- citeste GLB-ul EXPORTAT (JSON +
accesoare + transformarile nodurilor, cu ierarhia), in coordonate GODOT.

    python tools/blender/measure_carrara_excavator.py <glb>

Contract (kit §1.1, masurat pe vehicles/rusted_digger.glb): ExcavatorHazard ia
`find_child("body")` si `find_child("arm")`, face colizorul corpului din
AABB-ul lui body FARA arm, iar bratul are o CUTIE FIXA potrivita pe rigul vechi.
Deci, cu toleranta +-0,1 m:
  - `arm` exista si e DESCENDENT al lui `body`;
  - body fara arm: X -1,95..1,95, Y 0..3,73, Z -2,45..2,48;
  - pivotul bratului (originea nodului arm, in model): (0,55; 1,95; -0,42);
  - bratul (toate mesh-urile de sub arm, in model): X 0,09..1,01, Y 0,92..3,76,
    Z -5,70..-0,32;
  - rotatia nodului arm e identitate (codul aduna raise_angle la rotation.x).
Iese cu cod 1 la orice abatere sau daca nu gaseste nodurile (garda nu e verde
pe zero masuratori).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor
from measure_carrara_truck import quat_rot

TOL = 0.1
BODY = ((-1.95, 1.95), (0.0, 3.73), (-2.45, 2.48))
PIVOT = (0.55, 1.95, -0.42)
ARM = ((0.09, 1.01), (0.92, 3.76), (-5.70, -0.32))


def measure(path):
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

    def chain(i):
        out = [i]
        while i in parent:
            i = parent[i]
            out.append(i)
        return out

    idx = {n.get("name"): i for i, n in enumerate(nodes)}
    if "body" not in idx or "arm" not in idx:
        return {"error": "lipsesc nodurile body/arm (gasite: %s)" % sorted(idx)}
    ib, ia = idx["body"], idx["arm"]
    out = {"arm_under_body": ib in chain(ia),
           "arm_rot": nodes[ia].get("rotation", [0, 0, 0, 1]),
           "pivot": xf(ia, (0.0, 0.0, 0.0))}
    body_pts, arm_pts = [], []
    for i, n in enumerate(nodes):
        if "mesh" not in n:
            continue
        ch = chain(i)
        if ib not in ch:
            continue
        pts = [xf(i, p) for prim in g["meshes"][n["mesh"]]["primitives"]
               for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
        (arm_pts if ia in ch else body_pts).extend(pts)
    for key, pts in (("body", body_pts), ("arm", arm_pts)):
        out[key] = [(min(p[k] for p in pts), max(p[k] for p in pts)) for k in range(3)] if pts else None
    return out


def main():
    path = sys.argv[1]
    m = measure(path)
    bad = []
    if "error" in m:
        print("   !! " + m["error"])
        sys.exit(1)
    for key, want in (("body", BODY), ("arm", ARM)):
        got = m[key]
        if got is None:
            bad.append("%s fara geometrie" % key)
            continue
        print("%-5s X %+.3f..%+.3f  Y %+.3f..%+.3f  Z %+.3f..%+.3f   (cerut X %+.2f..%+.2f  Y %+.2f..%+.2f  Z %+.2f..%+.2f)"
              % ((key,) + tuple(v for ax in got for v in ax) + tuple(v for ax in want for v in ax)))
        for k, ax in enumerate("XYZ"):
            for j, end in enumerate(("min", "max")):
                if abs(got[k][j] - want[k][j]) > TOL:
                    bad.append("%s %s %s = %.3f, cerut %.2f +-%.1f" % (key, ax, end, got[k][j], want[k][j], TOL))
    pv = m["pivot"]
    print("pivot (%.3f, %.3f, %.3f)   (cerut (%.2f, %.2f, %.2f))" % (pv + PIVOT))
    for k, ax in enumerate("XYZ"):
        if abs(pv[k] - PIVOT[k]) > TOL:
            bad.append("pivot %s = %.3f, cerut %.2f +-%.1f" % (ax, pv[k], PIVOT[k], TOL))
    if not m["arm_under_body"]:
        bad.append("arm NU e descendent al lui body")
    if any(abs(v) > 1e-4 for v in m["arm_rot"][:3]):
        bad.append("arm are rotatie %s (codul aduna la rotation.x)" % m["arm_rot"])
    for b in bad:
        print("   !! " + b)
    print("rig: %s" % ("OK" if not bad else "PROBLEME"))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
