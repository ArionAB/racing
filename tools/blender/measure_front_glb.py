"""Masoara pe GLB spre ce parte priveste fata cu goluri a unei cladiri.

Memoria fata-casei-nu-e-plus-z: orientarea se MASOARA, nu se presupune. Aici:
aria fetelor nodurilor `*_Openings` (usi/ferestre) pe directia normalei, in
coordonatele Godot (fata = -Z), si centrul usii (cel mai mare gol).

    python tools/blender/measure_front_glb.py assets/models/monumentvalley/buildings/hogan.glb
"""
import json
import math
import struct
import sys


def load(path):
    d = open(path, "rb").read()
    jl = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + jl])
    bo = 20 + jl + 8
    return j, d, bo


def acc(j, d, bo, i):
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    n = a["count"]
    comp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[a["type"]]
    fmt = {5126: "f", 5123: "H", 5125: "I"}[a["componentType"]]
    off = bo + bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride") or comp * struct.calcsize(fmt)
    out = []
    for k in range(n):
        out.append(struct.unpack_from("<" + fmt * comp, d, off + k * stride))
    return out


def main(path):
    j, d, bo = load(path)
    totals = {}
    allp = []
    for m in j["meshes"]:
        for pr in m["primitives"]:
            allp += acc(j, d, bo, pr["attributes"]["POSITION"])
    ctr = [(min(q[k] for q in allp) + max(q[k] for q in allp)) / 2 for k in range(3)]
    for node in j["nodes"]:
        if "mesh" not in node or not node.get("name", "").endswith("_Openings"):
            continue
        for pr in j["meshes"][node["mesh"]]["primitives"]:
            pos = acc(j, d, bo, pr["attributes"]["POSITION"])
            idx = [i[0] for i in acc(j, d, bo, pr["indices"])]
            for t in range(0, len(idx), 3):
                a, b, c = (pos[idx[t]], pos[idx[t + 1]], pos[idx[t + 2]])
                u = [b[k] - a[k] for k in range(3)]
                v = [c[k] - a[k] for k in range(3)]
                n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
                area = 0.5 * math.sqrt(sum(x * x for x in n))
                if area < 1e-9 or abs(n[1]) > 0.5 * math.sqrt(sum(x * x for x in n)):
                    continue                              # fete orizontale: nu sunt goluri de perete
                cen = [(a[k] + b[k] + c[k]) / 3 - ctr[k] for k in range(3)]
                if sum(cen[k] * n[k] for k in range(3)) <= 0:
                    continue                              # fata interioara/spate a placii: nu conteaza
                ang = round(math.degrees(math.atan2(-n[2], n[0])) / 45.0) * 45 % 360
                totals[ang] = totals.get(ang, 0.0) + area
    names = {0: "+X", 90: "-Z (FATA)", 180: "-X", 270: "+Z", 45: "+X/-Z", 135: "-X/-Z", 225: "-X/+Z", 315: "+X/+Z"}
    print(path)
    for ang, ar in sorted(totals.items(), key=lambda kv: -kv[1]):
        print("  goluri spre %-10s %.2f m2" % (names[ang], ar))
    best = max(totals.items(), key=lambda kv: kv[1])[0]
    print("  FATA MASURATA: %s" % names[best])
    return best


if __name__ == "__main__":
    main(sys.argv[1])
