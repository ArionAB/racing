"""Masuratori din GLB pentru grupa tf-f (vehicule de decor + ciobanescul).

Citeste containerul glTF direct (ca verify_glb.py), cu transformurile COMPLETE
ale nodurilor (TRS sau matrice, pe tot lantul de parinti), in axele Godot
(Y sus, -Z inainte). Doua moduri:

  aabb  <glb> [<glb> ...]
        AABB-ul ansamblului in lume (X latime, Y inaltime, Z lungime) si al
        fiecarui nod cu mesh. Cu el s-au masurat masinile garajului fata de
        carcasa de coliziune din car.gd.

  legs  <glb> [--leg-top=0.45] [<glb> ...]
        Procentul de VARFURI sub `leg_top` (in metri, pe Y din GLB) al
        PRIMULUI MeshInstance3D pe care il gaseste HerdHazard._animal_mesh_from
        (DFS cu stiva: pop_back, deci ultimul copil intai), plus acelasi
        procent pe tot fisierul. Asta e ce leagana shader-ul de galop.

    python tools/blender/measure_tf_f.py aabb assets/models/vehicles/open_roadster.glb
    python tools/blender/measure_tf_f.py legs --leg-top=0.45 assets/models/transfagarasan/animals/sheepdog.glb
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402


def _mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def _node_matrix(n):
    if "matrix" in n:
        m = n["matrix"]   # coloane
        return [[m[c * 4 + r] for c in range(4)] for r in range(4)]
    t = n.get("translation", [0, 0, 0])
    x, y, z, w = n.get("rotation", [0, 0, 0, 1])
    s = n.get("scale", [1, 1, 1])
    r = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
         [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
         [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
    return [[r[i][0] * s[0], r[i][1] * s[1], r[i][2] * s[2], t[i]] for i in range(3)] + [[0, 0, 0, 1]]


def _world(g):
    """{index_nod: matrice in lume}, plecand de la radacinile scenei."""
    out = {}
    scene = g["scenes"][g.get("scene", 0)]

    def walk(i, parent):
        m = _mat_mul(parent, _node_matrix(g["nodes"][i]))
        out[i] = m
        for c in g["nodes"][i].get("children", []):
            walk(c, m)
    ident = [[1 if i == j else 0 for j in range(4)] for i in range(4)]
    for r in scene["nodes"]:
        walk(r, ident)
    return out


def _positions(g, blob, node_i, m):
    n = g["nodes"][node_i]
    pts = []
    for prim in g["meshes"][n["mesh"]]["primitives"]:
        for p in read_accessor(g, blob, prim["attributes"]["POSITION"]):
            pts.append(tuple(sum(m[r][k] * (p[k] if k < 3 else 1.0) for k in range(4)) for r in range(3)))
    return pts


def aabb(paths):
    for path in paths:
        g, blob, _, _ = load_glb(path)
        wm = _world(g)
        lo, hi = [1e9] * 3, [-1e9] * 3
        print("==", path)
        for i, n in enumerate(g["nodes"]):
            if "mesh" not in n or i not in wm:
                continue
            pts = _positions(g, blob, i, wm[i])
            nlo = [min(p[k] for p in pts) for k in range(3)]
            nhi = [max(p[k] for p in pts) for k in range(3)]
            lo = [min(lo[k], nlo[k]) for k in range(3)]
            hi = [max(hi[k], nhi[k]) for k in range(3)]
            print("   %-24s X %6.3f..%6.3f  Y %6.3f..%6.3f  Z %6.3f..%6.3f"
                  % (n.get("name", "?"), nlo[0], nhi[0], nlo[1], nhi[1], nlo[2], nhi[2]))
        print("   ANSAMBLU latime X %.3f  inaltime Y %.3f  lungime Z %.3f   (Y %.3f..%.3f, Z %.3f..%.3f)"
              % (hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], lo[1], hi[1], lo[2], hi[2]))


def _herd_first_mesh(g):
    """Ce intoarce HerdHazard._animal_mesh_from: DFS cu stiva (pop_back), de la
    radacina scenei instantiate (Godot pune nodurile glTF sub o radacina)."""
    scene = g["scenes"][g.get("scene", 0)]
    work = [None]
    kids = {None: list(scene["nodes"])}
    while work:
        cur = work.pop()
        for c in (kids[cur] if cur is None else g["nodes"][cur].get("children", [])):
            work.append(c)
        if cur is not None and "mesh" in g["nodes"][cur]:
            return cur
    return None


def legs(paths, leg_top):
    for path in paths:
        g, blob, _, _ = load_glb(path)
        wm = _world(g)
        first = _herd_first_mesh(g)
        allp = []
        for i, n in enumerate(g["nodes"]):
            if "mesh" in n and i in wm:
                allp += _positions(g, blob, i, wm[i])
        fp = _positions(g, blob, first, wm[first]) if first is not None else []
        def pct(pts):
            return 100.0 * sum(1 for p in pts if p[1] < leg_top) / max(1, len(pts))
        ys = [p[1] for p in fp] or [0]
        zs = [p[2] for p in fp] or [0]
        print("== %s" % path)
        print("   nodul gasit de HerdHazard: %s (%d varfuri), Y %.3f..%.3f, Z %.3f..%.3f"
              % (g["nodes"][first].get("name") if first is not None else None, len(fp),
                 min(ys), max(ys), min(zs), max(zs)))
        print("   varfuri sub leg_top=%.2f: %.1f %% pe nodul turmei, %.1f %% pe tot fisierul (%d)"
              % (leg_top, pct(fp), pct(allp), len(allp)))


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] not in ("aabb", "legs"):
        print(__doc__)
        sys.exit(1)
    lt = 0.45
    files = []
    for x in a[1:]:
        if x.startswith("--leg-top="):
            lt = float(x.split("=", 1)[1])
        else:
            files.append(x)
    if a[0] == "aabb":
        aabb(files)
    else:
        legs(files, lt)
