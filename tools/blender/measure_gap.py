"""Masoara GOLUL de trecere al unui GLB (poarta, pod): proiectie pe plan, nu AABB.

Memoriile `cota-de-contract-se-masoara-ca-gol` si `golul-se-masoara-pe-fereastra-lui`:
golul se citeste pe gabaritul caroseriei. Aici: toate triunghiurile (cu
transformarea nodului) se proiecteaza pe planul transversal (X lateral, Y sus
in glTF; directia de mers = Z glTF = Y Blender) si se rasterizeaza la 5 cm.

  GOL LATERAL    = cel mai lat interval liber in banda de inaltime a caroseriei
                   [--band=lo,hi, implicit 0.15,2.0] care contine x = 0
  INALTIME LIBERA = pe tot intervalul GOL LATERAL, cota cea mai de jos sub care
                   nu mai e nicio geometrie (minimul peste coloane al primului
                   pixel ocupat deasupra benzii)
  GOL UTIL       = latimea intervalului in care inaltimea libera e >= --need

    python tools/blender/measure_gap.py assets/models/kyoto/structures/niomon_gate.glb
    python tools/blender/measure_gap.py <glb> --band=0.15,2.0 --need=4.0
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402

STEP = 0.05


def node_matrix(node):
    if "matrix" in node:
        return np.array(node["matrix"], dtype=float).reshape(4, 4).T
    t = node.get("translation", [0, 0, 0])
    q = node.get("rotation", [0, 0, 0, 1])
    s = node.get("scale", [1, 1, 1])
    x, y, z, w = q
    r = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
    m = np.eye(4)
    m[:3, :3] = r * np.array(s)
    m[:3, 3] = t
    return m


def gather(path):
    gltf, blob, _, _ = load_glb(path)
    nodes = gltf["nodes"]
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i

    def world(i):
        m = node_matrix(nodes[i])
        while i in parent:
            i = parent[i]
            m = node_matrix(nodes[i]) @ m
        return m

    tris = []
    for i, n in enumerate(nodes):
        if "mesh" not in n:
            continue
        m = world(i)
        for prim in gltf["meshes"][n["mesh"]]["primitives"]:
            pos = np.array(read_accessor(gltf, blob, prim["attributes"]["POSITION"]))
            pos = (m[:3, :3] @ pos.T).T + m[:3, 3]
            if "indices" in prim:
                idx = np.array(read_accessor(gltf, blob, prim["indices"])).reshape(-1)
            else:
                idx = np.arange(len(pos))
            tris.append(pos[idx].reshape(-1, 3, 3))
    return np.concatenate(tris)


def raster(tris):
    """Grila de ocupare in planul (x, y)."""
    xs, ys = tris[:, :, 0], tris[:, :, 1]
    x0, y0 = xs.min() - 0.5, 0.0
    nx = int((xs.max() + 0.5 - x0) / STEP) + 1
    ny = int((ys.max() + 0.5 - y0) / STEP) + 1
    occ = np.zeros((nx, ny), dtype=bool)
    for t in tris:
        p = t[:, :2]
        lo = np.floor((p.min(axis=0) - (x0, y0)) / STEP).astype(int)
        hi = np.ceil((p.max(axis=0) - (x0, y0)) / STEP).astype(int)
        lo = np.maximum(lo, 0)
        hi = np.minimum(hi, (nx - 1, ny - 1))
        gx, gy = np.meshgrid(np.arange(lo[0], hi[0] + 1), np.arange(lo[1], hi[1] + 1),
                             indexing="ij")
        cx = x0 + (gx + 0.5) * STEP
        cy = y0 + (gy + 0.5) * STEP
        a, b, c = p
        d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(d) < 1e-9:
            # triunghi vertical in proiectie: segment; marcheaza celulele atinse
            for s in np.linspace(0, 1, 40):
                for e in ((a, b), (b, c), (c, a)):
                    q = e[0] * (1 - s) + e[1] * s
                    ix = int((q[0] - x0) / STEP)
                    iy = int((q[1] - y0) / STEP)
                    if 0 <= ix < nx and 0 <= iy < ny:
                        occ[ix, iy] = True
            continue
        l1 = ((b[1] - c[1]) * (cx - c[0]) + (c[0] - b[0]) * (cy - c[1])) / d
        l2 = ((c[1] - a[1]) * (cx - c[0]) + (a[0] - c[0]) * (cy - c[1])) / d
        l3 = 1 - l1 - l2
        eps = -STEP / 4
        inside = (l1 >= eps) & (l2 >= eps) & (l3 >= eps)
        occ[gx[inside], gy[inside]] = True
    return occ, x0, y0


def measure(path, band=(0.15, 2.0), need=None):
    tris = gather(path)
    occ, x0, y0 = raster(tris)
    nx, ny = occ.shape
    b0 = int(band[0] / STEP)
    b1 = int(band[1] / STEP)
    blocked = occ[:, b0:b1 + 1].any(axis=1)
    c0 = int((0.0 - x0) / STEP)
    if blocked[c0]:
        return {"gap": 0.0, "note": "x=0 ocupat in banda"}
    l = c0
    while l > 0 and not blocked[l - 1]:
        l -= 1
    r = c0
    while r < nx - 1 and not blocked[r + 1]:
        r += 1
    gap = (r - l + 1) * STEP
    # inaltimea libera: primul pixel ocupat deasupra benzii pe fiecare coloana
    clear = []
    for ix in range(l, r + 1):
        col = occ[ix, b1 + 1:]
        hit = np.nonzero(col)[0]
        clear.append(y0 + (b1 + 1 + (hit[0] if len(hit) else ny)) * STEP)
    clear = np.array(clear)
    out = {"gap": gap, "x_lo": x0 + l * STEP, "x_hi": x0 + (r + 1) * STEP,
           "clear_min": float(clear.min()), "clear_med": float(np.median(clear)),
           "width": float(tris[:, :, 0].max() - tris[:, :, 0].min()),
           "height": float(tris[:, :, 1].max()),
           "depth": float(tris[:, :, 2].max() - tris[:, :, 2].min())}
    if need is not None:
        ok = clear >= need
        out["usable_gap"] = float(ok.sum() * STEP)
    return out


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    band, need = (0.15, 2.0), None
    for a in sys.argv[1:]:
        if a.startswith("--band="):
            band = tuple(float(v) for v in a[7:].split(","))
        elif a.startswith("--need="):
            need = float(a[7:])
    r = measure(args[0], band, need)
    print(os.path.basename(args[0]))
    for k, v in r.items():
        print("  %-11s %s" % (k, ("%.2f" % v) if isinstance(v, float) else v))
