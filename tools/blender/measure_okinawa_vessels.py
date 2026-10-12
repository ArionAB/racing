"""Masoara vapoarele Okinawa DIN GLB (nu din build): lungime, latime, varf peste
linia apei, pescaj, PROVA (semnul pe Z Godot) si ierarhia de noduri.

    python tools/blender/measure_okinawa_vessels.py [island_ferry coastal_freighter fishing_boat]

Coordonate Godot (Y sus, prova pe -Z = +Y Blender). Prova = capatul ASCUTIT:
se compara latimea coastei (nodul cu `Hull` in nume) in primii/ultimii 2 m pe Z,
pe portiunea de deasupra apei. Iese cu cod 1 daca feribotul iese din contract
(varf 11,0 +- 0,5, lungime 28, latime 8, pescaj 2, prova pe -Z).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from verify_glb import load_glb, read_accessor  # noqa: E402

PROJ = os.path.dirname(os.path.dirname(HERE))
VEH = os.path.join(PROJ, "assets", "models", "okinawa", "vehicles")

CONTRACT = {"island_ferry": dict(length=28.0, width=8.0, tip=(10.5, 11.5), draft=2.0)}


def node_points(g, blob, node):
    pts = []
    mesh = g["meshes"][node["mesh"]]
    for prim in mesh["primitives"]:
        pts += [tuple(p) for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
    return pts


def measure(name):
    g, blob, _, _ = load_glb(os.path.join(VEH, name + ".glb"))
    nodes = g["nodes"]
    kids = {c for n in nodes for c in n.get("children", [])}
    roots = [i for i in range(len(nodes)) if i not in kids]
    print("== %s ==" % name)
    for r in roots:
        n = nodes[r]
        print("radacina: %-18s copii: %s  scale=%s rot=%s" % (
            n.get("name"), [nodes[c].get("name") for c in n.get("children", [])],
            n.get("scale", [1, 1, 1]), n.get("rotation", [0, 0, 0, 1])))
    allp, hull = [], []
    for n in nodes:
        if "mesh" not in n:
            continue
        pts = node_points(g, blob, n)
        allp += pts
        if "Hull" in n.get("name", ""):
            hull = pts
    xs = [p[0] for p in allp]; ys = [p[1] for p in allp]; zs = [p[2] for p in allp]
    L, W = max(zs) - min(zs), max(xs) - min(xs)
    tip, keel = max(ys), min(ys)
    print("lungime (Z)      : %.2f m   [Z %.2f .. %.2f]" % (L, min(zs), max(zs)))
    print("latime (X)       : %.2f m" % W)
    print("varf peste apa   : %.2f m   (Y max; apa = Y 0)" % tip)
    print("pescaj (Y min)   : %.2f m" % -keel)

    def width_at(pts, zlo, zhi):
        sel = [p[0] for p in pts if zlo <= p[2] <= zhi and p[1] > 0.0]
        return (max(sel) - min(sel)) if sel else 0.0

    hz = [p[2] for p in hull]
    z0, z1 = min(hz), max(hz)
    w_neg = width_at(hull, z0, z0 + 2.0)      # capatul -Z
    w_pos = width_at(hull, z1 - 2.0, z1)      # capatul +Z
    bow = "-Z" if w_neg < w_pos else "+Z"
    print("coca latime la capete (primii 2 m, peste apa): -Z %.2f m | +Z %.2f m" % (w_neg, w_pos))
    print("PROVA            : %s (capatul ascutit)  -> %s" % (
        bow, "ship_bow_neg_z = true" if bow == "-Z" else "!! ship_bow_neg_z = false"))
    ok = True
    c = CONTRACT.get(name)
    if c:
        ok = (abs(L - c["length"]) <= 0.2 and abs(W - c["width"]) <= 0.2
              and c["tip"][0] <= tip <= c["tip"][1] and abs(-keel - c["draft"]) <= 0.1
              and bow == "-Z")
        print("CONTRACT         : %s" % ("OK" if ok else "!! IN AFARA CONTRACTULUI"))
    return ok


if __name__ == "__main__":
    names = sys.argv[1:] or ["island_ferry", "coastal_freighter", "fishing_boat"]
    res = [measure(n) for n in names]
    sys.exit(0 if all(res) else 1)
