"""Masoara pe GLB spre ce parte se uita fata cladirii (usi/ferestre).

    python tools/blender/measure_front.py <fisier.glb>

Aria fetelor cu slotul LOG_DARK (28, golurile de usa/fereastra) din nodul *_Wood,
grupata pe normala dominanta (+Y/-Y/+X/-X in Blender; GLB e Y-up, deci
Blender +Y = glTF -Z). Ultima linie: `FATA: +Y (arie ...)`. Memoria
fata-casei-nu-e-plus-z: fata se masoara, nu se presupune.
"""
import sys, os, struct, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb
import numpy as np

path = sys.argv[1]
g, binb = load_glb(path)[:2]
areas = {"+X": 0.0, "-X": 0.0, "+Y": 0.0, "-Y": 0.0}
CT = {5126: ("f", 4), 5123: ("H", 2), 5125: ("I", 4)}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def acc(i):
    a = g["accessors"][i]
    bv = g["bufferViews"][a["bufferView"]]
    fmt, sz = CT[a["componentType"]]
    n = NC[a["type"]]
    stride = bv.get("byteStride", sz * n)
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    out = np.zeros((a["count"], n))
    for k in range(a["count"]):
        out[k] = struct.unpack_from("<" + fmt * n, binb, off + k * stride)
    return out


def tris_of(node):
    out = []
    for prim in g["meshes"][node["mesh"]]["primitives"]:
        P = acc(prim["attributes"]["POSITION"])
        idx = acc(prim["indices"]).astype(int).reshape(-1, 3)
        out.append(P[idx])
    return np.concatenate(out)


occ = [tris_of(n) for n in g["nodes"]
       if "mesh" in n and not n.get("name", "").endswith("_Wood")]
OCC = np.concatenate(occ)


def exposed(o, d):
    """Raza din fata spre exterior: lovita de alta geometrie = fata ingropata
    (spatele placii de gol, ascuns in perete)."""
    e1, e2 = OCC[:, 1] - OCC[:, 0], OCC[:, 2] - OCC[:, 0]
    h = np.cross(d, e2)
    a = np.einsum("ij,ij->i", e1, h)
    ok = np.abs(a) > 1e-9
    f = np.where(ok, 1.0 / np.where(ok, a, 1.0), 0.0)
    s_ = o - OCC[:, 0]
    u = f * np.einsum("ij,ij->i", s_, h)
    q = np.cross(s_, e1)
    v = f * (q @ d)
    t = f * np.einsum("ij,ij->i", e2, q)
    hit = ok & (u >= 0) & (v >= 0) & (u + v <= 1) & (t > 1e-4)
    return not hit.any()


for node in g["nodes"]:
    if "mesh" not in node or not node.get("name", "").endswith("_Wood"):
        continue
    for prim in g["meshes"][node["mesh"]]["primitives"]:
        P = acc(prim["attributes"]["POSITION"])
        UV = acc(prim["attributes"]["TEXCOORD_0"])
        idx = acc(prim["indices"]).astype(int).reshape(-1, 3)
        for t in idx:
            slot = int(UV[t[0]][0] * 32)
            if slot != 28:
                continue
            a, b, c = P[t[0]], P[t[1]], P[t[2]]
            nrm = np.cross(b - a, c - a)
            ar = np.linalg.norm(nrm) * 0.5
            if ar < 1e-9:
                continue
            nrm = nrm / (2 * ar)
            if not exposed((a + b + c) / 3.0 + nrm * 0.03, nrm):
                continue
            # glTF (x, y, z) -> Blender (x, -z, y)
            bx, by = nrm[0], -nrm[2]
            if abs(bx) > abs(by):
                areas["+X" if bx > 0 else "-X"] += ar
            else:
                areas["+Y" if by > 0 else "-Y"] += ar
best = max(areas, key=areas.get)
print("arii goluri (LOG_DARK) pe fete:", {k: round(v, 2) for k, v in areas.items()})
print("FATA: %s (arie %.2f m2)" % (best, areas[best]))
