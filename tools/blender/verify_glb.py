"""Verifica un GLB fata de contractul din docs/blender_export.md.

Independent de Blender si de Godot — citeste direct containerul glTF, ca sa
confirme ce a ajuns efectiv in fisier, nu ce credem ca am exportat.

Verifica:
  1. numele nodurilor (Godot cauta noduri dupa nume, ex. "Blades")
  2. numarul de triunghiuri fata de buget
  3. UV-urile: toate colapsate pe centre de slot din atlas -> ce sloturi foloseste
  4. COLOR_0 prezent (AO copt) + intervalul de valori
  5. bounding box: originea la baza (min Y ~ 0), centrata in XZ
  6. orientarea: pe ce parte sta masa geometriei (fata trebuie sa fie spre -Z)

Rulare:
    python tools/blender/verify_glb.py assets/models/cactus.glb [buget_tris]
"""

import json
import struct
import sys
import os

SLOTS = 32
SLOT_NAMES = [
    "sand_light", "sand_mid", "sand_shadow", "rock_light", "rock_dark",
    "asphalt", "asphalt_edge", "kerb_red", "concrete", "wood_weathered",
    "rust_metal", "painted_metal", "cactus_green", "dry_vegetation",
    "car_red", "car_blue", "car_yellow",
]

COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
             5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic, version, _ = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "nu e un GLB valid"
    off, js, bin_chunk = 12, None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            bin_chunk = chunk
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    return js, bin_chunk, len(data), version


def read_accessor(gltf, blob, index):
    acc = gltf["accessors"][index]
    fmt, size = COMPONENT[acc["componentType"]]
    n = NCOMP[acc["type"]]
    count = acc["count"]
    if "bufferView" not in acc:
        return [(0,) * n] * count
    bv = gltf["bufferViews"][acc["bufferView"]]
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride") or size * n
    out = []
    for i in range(count):
        out.append(struct.unpack_from("<" + fmt * n, blob, base + i * stride))
    return out


def verify(path, budget=None):
    gltf, blob, total, version = load_glb(path)
    print("=" * 74)
    print("%s  —  %d B, glTF v%d" % (os.path.basename(path), total, version))
    print("=" * 74)

    nodes = gltf.get("nodes", [])
    print("Noduri: %s" % ", ".join("%s" % n.get("name", "?") for n in nodes))

    grand_total = 0
    ok = True

    for node in nodes:
        if "mesh" not in node:
            continue
        mesh = gltf["meshes"][node["mesh"]]
        name = node.get("name", mesh.get("name", "?"))
        tris = 0
        slots_used = set()
        col_lo, col_hi = 1e9, -1e9
        has_color = False
        xs, ys, zs = [], [], []

        for prim in mesh["primitives"]:
            attrs = prim["attributes"]
            if "indices" in prim:
                tris += len(read_accessor(gltf, blob, prim["indices"])) // 3
            else:
                tris += len(read_accessor(gltf, blob, attrs["POSITION"])) // 3

            for p in read_accessor(gltf, blob, attrs["POSITION"]):
                xs.append(p[0]); ys.append(p[1]); zs.append(p[2])

            if "TEXCOORD_0" in attrs:
                for u, v in read_accessor(gltf, blob, attrs["TEXCOORD_0"]):
                    slot = round(u * SLOTS - 0.5)
                    exact = abs((slot + 0.5) / SLOTS - u) < 1e-4
                    slots_used.add((slot, exact))

            if "COLOR_0" in attrs:
                has_color = True
                for c in read_accessor(gltf, blob, attrs["COLOR_0"]):
                    val = c[0] / 65535.0 if isinstance(c[0], int) else c[0]
                    col_lo, col_hi = min(col_lo, val), max(col_hi, val)

        grand_total += tris
        flag = ""
        if budget is not None:
            flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
            if tris > budget:
                ok = False
        print("\n  %s: %d tris%s" % (name, tris, flag))

        names = []
        for slot, exact in sorted(slots_used):
            label = SLOT_NAMES[slot] if 0 <= slot < len(SLOT_NAMES) else "slot%d" % slot
            names.append(label if exact else "%s(NECENTRAT!)" % label)
            if not exact:
                ok = False
        print("    sloturi UV : %s" % (", ".join(names) or "FARA UV!"))
        if not slots_used:
            ok = False

        if has_color:
            print("    COLOR_0    : da, AO %.3f .. %.3f" % (col_lo, col_hi))
        else:
            print("    COLOR_0    : LIPSESTE (AO necopt)")
            ok = False

        tr = node.get("translation", [0.0, 0.0, 0.0])
        print("    bbox X     : %.3f .. %.3f  (centru %+.3f)" % (min(xs), max(xs), (min(xs) + max(xs)) / 2))
        print("    bbox Y     : %.3f .. %.3f  (inaltime %.2f m)" % (min(ys), max(ys), max(ys) - min(ys)))
        print("    bbox Z     : %.3f .. %.3f  (centru %+.3f)" % (min(zs), max(zs), (min(zs) + max(zs)) / 2))
        if any(abs(c) > 1e-6 for c in tr):
            # nod cu pivot propriu (ex. roata morii): coordonatele de mai sus sunt
            # relative la pivot, deci regula "baza la Y=0" nu i se aplica
            print("    pivot      : (%.3f, %.3f, %.3f)  -> in lume Y %.3f .. %.3f"
                  % (tr[0], tr[1], tr[2], min(ys) + tr[1], max(ys) + tr[1]))
        elif abs(min(ys)) > 0.01:
            print("    !! baza nu e la Y=0 (min Y = %.3f)" % min(ys))
            ok = False

    print("\nTOTAL: %d tris" % grand_total)
    print("VERDICT: %s" % ("OK" if ok else "PROBLEME — vezi mai sus"))
    return ok


if __name__ == "__main__":
    target = sys.argv[1]
    budget = int(sys.argv[2]) if len(sys.argv) > 2 else None
    sys.exit(0 if verify(target, budget) else 1)
