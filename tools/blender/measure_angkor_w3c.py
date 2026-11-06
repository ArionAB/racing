"""Garzi Angkor, val 3, grupul C -- debarcader, tuk-tuk, calugar, blocuri mici.

    python tools/blender/measure_angkor_w3c.py landing <glb>
    python tools/blender/measure_angkor_w3c.py tuk <glb>
    python tools/blender/measure_angkor_w3c.py monk|laterite|rubble|numbered <glb>
    python tools/blender/measure_angkor_w3c.py --selftest <tuk.glb> <landing.glb>

Citeste GLB-ul EXPORTAT (coordonate GODOT: Y sus, Blender +Y = Godot -Z). Contracte (kit 1.4-1.6):
  debarcader: ~14 x 8 m (+-10%), scara coboara 1,5 m (min Y intre -1,9 si -1,5), SUPRAFATA
    PLATFORMEI la Y = 0 +- 0,05 (dale orizontale de cel putin 60 m2 la |Y| < 0,05), noduri
    Landing_Laterite / _Stone / _Lichen;
  tuk-tuk: EXACT doua radacini `Moto` si `Remorca`; pe fiecare, cea mai lunga latura orizontala
    <= 2,0 m (limita BumpProp: scenes/props/bump_prop.gd MAX_FOOTPRINT_M) si inaltime <= 1,8
    (MAX_HEIGHT_M); scala/rotatia identice pe radacini; Moto ~1,9 x 0,7, Remorca <= 2,0 x ~1,4
    x 1,7-1,8; nicio piesa in afara radacinilor;
  calugar 1,7 m; bloc de laterita 0,6-1,2 m; moloz ~2 m (1,8-2,2); bloc cu cifra 0,8 m
    (+-10%), cu nodul `Block_Paint` (singurul marcaj din kit).
Iese cu cod 1 la incalcare. `--selftest`: remorca de 2,3 m, tuk-tuk-ul unit intr-o singura
radacina si platforma ridicata cu 0,2 m TREBUIE sa pice.
"""
import json
import os
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402
from measure_angkor import quat_rot, _write_glb  # noqa: E402
from measure_angkor_w1a import _edit_positions, world_tris  # noqa: E402


def parents(g):
    par = {}
    for i, n in enumerate(g["nodes"]):
        for c in n.get("children", []):
            par[c] = i
    return par


def node_world(g, par, i, p):
    while True:
        n = g["nodes"][i]
        s = n.get("scale", [1, 1, 1])
        p = (p[0] * s[0], p[1] * s[1], p[2] * s[2])
        p = quat_rot(n.get("rotation", [0, 0, 0, 1]), p)
        t = n.get("translation", [0, 0, 0])
        p = (p[0] + t[0], p[1] + t[1], p[2] + t[2])
        if i not in par:
            return p, i
        i = par[i]


def points_by_root(g, blob):
    par = parents(g)
    out = {}
    for i, n in enumerate(g["nodes"]):
        if "mesh" not in n:
            continue
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            for p in read_accessor(g, blob, prim["attributes"]["POSITION"]):
                w, root = node_world(g, par, i, p)
                out.setdefault(root, []).append(w)
    return out


def mesh_names(g):
    return sorted((n.get("name") or "").split(".")[0] for n in g["nodes"] if "mesh" in n)


def roots(g):
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    return [i for i in range(len(g["nodes"])) if i not in kids]


def dims(pts):
    xs, ys, zs = [p[0] for p in pts], [p[1] for p in pts], [p[2] for p in pts]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def xform_bad(g, bad):
    for i in roots(g):
        n = g["nodes"][i]
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            bad.append("scala/rotatie neaplicata pe radacina %s" % n.get("name"))


def within(v, lo, hi, what, bad):
    if not lo <= v <= hi:
        bad.append("%s %.3f in afara %.2f-%.2f" % (what, v, lo, hi))


def check_landing(path, report=True):
    g, blob = load_glb(path)[:2]
    bad = []
    pts = [p for ps in points_by_root(g, blob).values() for p in ps]
    (x0, x1), (y0, y1), (z0, z1) = dims(pts)
    wx, wz = x1 - x0, z1 - z0
    if report:
        print("anvelopa  X %.2f (14+-1,4)  Z %.2f (8+-0,8)  Y %.2f..%.2f" % (wx, wz, y0, y1))
    within(wx, 12.6, 15.4, "latime X", bad)
    within(wz, 7.2, 8.8, "adancime Z", bad)
    within(y0, -1.9, -1.5, "talpa scarii Y", bad)
    # suprafata platformei: arie de fete orientate in sus la Y = 0 +- 0,05
    area = 0.0
    for (a, b, c) in world_tris(g, blob):
        ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
        nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
        ar = (nx * nx + ny * ny + nz * nz) ** 0.5 / 2
        if ar > 0 and ny / (2 * ar) > 0.99 and max(abs(a[1]), abs(b[1]), abs(c[1])) < 0.05:
            area += ar
    if report:
        print("platforma arie sus la |Y|<0,05: %.1f m2 (min 60)" % area)
    if area < 60.0:
        bad.append("suprafata platformei nu e la Y=0+-0,05 (doar %.1f m2, cerut >= 60)" % area)
    if mesh_names(g) != ["Landing_Laterite", "Landing_Lichen", "Landing_Stone"]:
        bad.append("noduri %s" % mesh_names(g))
    xform_bad(g, bad)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def check_tuk(path, report=True):
    g, blob = load_glb(path)[:2]
    bad = []
    rs = roots(g)
    names = sorted(g["nodes"][i].get("name", "") for i in rs)
    if names != ["Moto", "Remorca"]:
        bad.append("radacini %s, cerute exact [Moto, Remorca]" % names)
    xform_bad(g, bad)
    by = points_by_root(g, blob)
    for i in rs:
        nm = g["nodes"][i].get("name")
        if i not in by:
            bad.append("radacina %s fara geometrie" % nm)
            continue
        (x0, x1), (y0, y1), (z0, z1) = dims(by[i])
        wx, wh, wz = x1 - x0, y1 - y0, z1 - z0     # Godot: X lat, Y inaltime, Z lungime
        longest = max(wx, wz)
        if report:
            print("%-8s  X %.3f  Y(inalt) %.3f  Z %.3f   cea mai lunga latura %.3f (max 2,0)  talpa Y %.3f"
                  % (nm, wx, wh, wz, longest, y0))
        if longest > 2.0:
            bad.append("%s: latura orizontala %.3f > 2,0 (BumpProp)" % (nm, longest))
        if wh > 1.8:
            bad.append("%s: inaltime %.3f > 1,8 (BumpProp)" % (nm, wh))
        if abs(y0) > 0.02:
            bad.append("%s: talpa nu e la Y=0 (%.3f)" % (nm, y0))
        if nm == "Moto":
            within(wz, 1.71, 2.09, "Moto lungime", bad)
            within(wx, 0.63, 0.88, "Moto latime", bad)
        elif nm == "Remorca":
            within(wz, 1.80, 2.0, "Remorca lungime", bad)
            within(wx, 1.26, 1.54, "Remorca latime", bad)
            within(wh, 1.70, 1.80, "Remorca inaltime", bad)
    for n in mesh_names(g):
        if not (n.startswith("Moto_") or n.startswith("Remorca_")):
            bad.append("nod mesh in afara conventiei: %s" % n)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def check_simple(kind):
    def fn(path, report=True):
        g, blob = load_glb(path)[:2]
        bad = []
        pts = [p for ps in points_by_root(g, blob).values() for p in ps]
        (x0, x1), (y0, y1), (z0, z1) = dims(pts)
        wx, wh, wz = x1 - x0, y1 - y0, z1 - z0
        mh = max(wx, wz)
        if report:
            print("%-9s X %.3f  inalt %.3f  Z %.3f" % (kind, wx, wh, wz))
        if abs(y0) > 0.02:
            bad.append("talpa nu e la Y=0 (%.3f)" % y0)
        if kind == "monk":
            within(wh, 1.53, 1.87, "inaltime", bad)
        elif kind == "laterite":
            within(mh, 0.6, 1.2, "latura mare", bad)
        elif kind == "rubble":
            within(mh, 1.8, 2.2, "intindere in plan", bad)
        elif kind == "numbered":
            within(mh, 0.72, 0.88, "latura mare", bad)
            if "Block_Paint" not in mesh_names(g):
                bad.append("lipseste nodul Block_Paint (cifra)")
        xform_bad(g, bad)
        for b_ in bad:
            print("   !! " + b_)
        return not bad
    return fn


def _stretch_node_z(g, blob, node_ids, factor):
    """Intinde pe Z (Blender Y -> glTF Z) varfurile nodurilor date; actualizeaza min/max."""
    blob = bytearray(blob)
    for ci in node_ids:
        n = g["nodes"][ci]
        if "mesh" not in n:
            continue
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            acc = g["accessors"][prim["attributes"]["POSITION"]]
            bv = g["bufferViews"][acc["bufferView"]]
            base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
            stride = bv.get("byteStride") or 12
            for k in range(acc["count"]):
                x, y, z = struct.unpack_from("<fff", blob, base + k * stride)
                struct.pack_into("<fff", blob, base + k * stride, x, y, z * factor)
            acc["min"] = [v * (factor if j == 2 else 1) for j, v in enumerate(acc["min"])]
            acc["max"] = [v * (factor if j == 2 else 1) for j, v in enumerate(acc["max"])]
    return bytes(blob)


def selftest(tuk, landing):
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_w3c_sabotaj_")
    cases = []
    g0, b0 = load_glb(tuk)[:2]
    g = json.loads(json.dumps(g0))
    rem = [i for i in roots(g) if g["nodes"][i].get("name") == "Remorca"][0]
    blob = _stretch_node_z(g, b0, g["nodes"][rem].get("children", []), 2.3 / 1.96)
    cases.append(("remorca de 2,3 m", check_tuk, g, blob))
    g = json.loads(json.dumps(g0))
    moto = [i for i in roots(g) if g["nodes"][i].get("name") == "Moto"][0]
    rem = [i for i in roots(g) if g["nodes"][i].get("name") == "Remorca"][0]
    g["nodes"][moto].setdefault("children", []).append(rem)
    sc = g["scenes"][0]["nodes"]
    if rem in sc:
        sc.remove(rem)
    cases.append(("tuk-tuk intr-o singura radacina", check_tuk, g, b0))
    gl, bl = load_glb(landing)[:2]
    g = json.loads(json.dumps(gl))
    cases.append(("platforma ridicata cu 0,2 m", check_landing, g,
                  _edit_positions(g, bl, lambda x, y, z: (x, y + 0.2, z))))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, fn, g, blob in cases:
        p = os.path.join(tmp, "s.glb")
        _write_glb(p, g, blob)
        print("-- sabotaj: %s" % label)
        if fn(p, report=False):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalele:")
    for fn, p in ((check_tuk, tuk), (check_landing, landing)):
        if not fn(p, report=False):
            print("   !! SELFTEST ESUAT: garda pica pe original (%s)" % os.path.basename(p))
            ok = False
    if ok:
        print("   originalele trec")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest":
        sys.exit(0 if selftest(a[1], a[2]) else 1)
    if len(a) >= 2:
        fn = {"landing": check_landing, "tuk": check_tuk}.get(a[0])
        if fn is None and a[0] in ("monk", "laterite", "rubble", "numbered"):
            fn = check_simple(a[0])
        if fn:
            sys.exit(0 if fn(a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
