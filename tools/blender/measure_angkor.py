"""Garda anvelopei Angkor -- citeste GLB-ul EXPORTAT (glTF JSON + accesoare +
transformarile nodurilor), in coordonate GODOT (Y sus, fata bogata pe -Z).

    python tools/blender/measure_angkor.py bayon <glb> [--report]
    python tools/blender/measure_angkor.py --selftest <glb>

Contractul turnului Bayon (kit §1.1): amprenta 3,0 x 3,0 m cu toleranta DOAR
spre INTERIOR (nimic dincolo de +-1,5 m pe X si Z: cutia de coliziune e de
3 x 9 x 3, iar ce iese din ea trece prin masini fara sa le atinga), latimea
masurata 2,9-3,0 (un patrat mai mic lasa un zid invizibil), inaltimea 9,0 +-0,1,
min Y ~ 0, centrat pe X si Z, nodurile `Bayon_Stone`, `Bayon_Lichen`,
`Bayon_Streak`, fara scala/rotatie pe radacini. Iese cu cod 1 la incalcare.

`--selftest` dovedeste ca garda PICA: pe doua copii sabotate ale GLB-ului
(scalat 1,1x pe radacini; ridicat 0,5 m) si pe una cu un nod redenumit, apoi
verifica ca originalul trece. Copiile se scriu in directorul temporar si se sterg.
"""
import json
import os
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402

HALF = 1.5
TOL_OUT = 1e-3          # praf numeric de float32, NU toleranta de proiectare
WIDTH_MIN, WIDTH_MAX = 2.9, 3.0 + TOL_OUT
H_NOM, H_TOL = 9.0, 0.1
NODES = ["Bayon_Lichen", "Bayon_Stone", "Bayon_Streak"]


def quat_rot(q, v):
    x, y, z, w = q
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
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            for p in read_accessor(g, blob, prim["attributes"]["POSITION"]):
                out.append(xf(i, p))
    return out


def measure(path):
    g, blob = load_glb(path)[:2]
    pts = world_points(g, blob)
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    zs = [p[2] for p in pts]
    names = sorted((n.get("name") or "").split(".")[0] for n in g["nodes"] if "mesh" in n)
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    xform = []
    for i, n in enumerate(g["nodes"]):
        if i in kids:
            continue
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            xform.append(n.get("name"))
    return dict(x=(min(xs), max(xs)), y=(min(ys), max(ys)), z=(min(zs), max(zs)),
                names=names, xform=xform)


def slot_areas(path):
    """Aria (m2) pe nod si pe slot de paleta (din UV.x colapsat: slot = floor(u*32)),
    in spatiul nodului (scala radacinii e identitate, deci metri)."""
    g, blob = load_glb(path)[:2]
    out = {}
    for n in g["nodes"]:
        if "mesh" not in n:
            continue
        name = (n.get("name") or "").split(".")[0]
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            a = prim["attributes"]
            pos = read_accessor(g, blob, a["POSITION"])
            uv = read_accessor(g, blob, a["TEXCOORD_0"])
            idx = [i[0] for i in read_accessor(g, blob, prim["indices"])]
            for t in range(0, len(idx) - 2, 3):
                p0, p1, p2 = pos[idx[t]], pos[idx[t + 1]], pos[idx[t + 2]]
                u1 = (p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2])
                v1 = (p2[0] - p0[0], p2[1] - p0[1], p2[2] - p0[2])
                cx = (u1[1] * v1[2] - u1[2] * v1[1], u1[2] * v1[0] - u1[0] * v1[2],
                      u1[0] * v1[1] - u1[1] * v1[0])
                ar = 0.5 * (cx[0] ** 2 + cx[1] ** 2 + cx[2] ** 2) ** 0.5
                slot = int(uv[idx[t]][0] * 32)
                out[(name, slot)] = out.get((name, slot), 0.0) + ar
    return out


def check_bayon(path, report=True):
    m = measure(path)
    w, d, h = m["x"][1] - m["x"][0], m["z"][1] - m["z"][0], m["y"][1] - m["y"][0]
    if report:
        print("anvelopa  X %.3f  Z %.3f  Y(inaltime) %.3f   X [%.3f, %.3f]  Z [%.3f, %.3f]  minY %.3f"
              % (w, d, h, m["x"][0], m["x"][1], m["z"][0], m["z"][1], m["y"][0]))
    bad = []
    for ax, lo_hi in (("X", m["x"]), ("Z", m["z"])):
        if lo_hi[0] < -HALF - TOL_OUT or lo_hi[1] > HALF + TOL_OUT:
            bad.append("iese din patratul de 3 m pe %s: [%.3f, %.3f] (limita +-%.1f)"
                       % (ax, lo_hi[0], lo_hi[1], HALF))
    for ax, v in (("X", w), ("Z", d)):
        if not WIDTH_MIN <= v <= WIDTH_MAX:
            bad.append("latimea pe %s = %.3f in afara %.1f-%.1f" % (ax, v, WIDTH_MIN, 3.0))
    if abs(h - H_NOM) > H_TOL:
        bad.append("inaltime %.3f != %.1f +-%.1f" % (h, H_NOM, H_TOL))
    if abs(m["y"][0]) > 0.02:
        bad.append("min Y %.3f != 0 (originea la baza)" % m["y"][0])
    for ax, lo_hi in (("X", m["x"]), ("Z", m["z"])):
        if abs((lo_hi[0] + lo_hi[1]) / 2) > 0.05:
            bad.append("necentrat pe %s" % ax)
    if m["names"] != NODES:
        bad.append("noduri %s, cerute %s" % (m["names"], NODES))
    if m["xform"]:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % m["xform"])
    if not bad:
        ar = slot_areas(path)
        tot = sum(ar.values())
        orange = sum(v for (n, s_), v in ar.items() if s_ == 30)
        green = sum(v for (n, s_), v in ar.items() if s_ == 12)
        slots_ok = {("Bayon_Stone", 3), ("Bayon_Lichen", 30), ("Bayon_Lichen", 12), ("Bayon_Streak", 20)}
        extra = sorted(k for k in ar if k not in slots_ok)
        if report:
            print("arii      total %.1f m2  lichen portocaliu %.2f%%  verde %.2f%%  dare %.2f%%"
                  % (tot, 100 * orange / tot, 100 * green / tot,
                     100 * sum(v for (n, s_), v in ar.items() if n == "Bayon_Streak") / tot))
        if orange / tot >= 0.03:
            bad.append("lichen portocaliu %.2f%% >= 3%% din aria piesei" % (100 * orange / tot))
        if extra:
            bad.append("sloturi in afara tabelului (3 / 30,12 / 20): %s" % extra)
    for b in bad:
        print("   !! " + b)
    return not bad


def _write_glb(path, g, blob):
    js = json.dumps(g, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    blob = blob + b"\0" * ((4 - len(blob) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(blob)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, total))
        fh.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        fh.write(struct.pack("<II", len(blob), 0x004E4942) + blob)


def selftest(path):
    g0, blob = load_glb(path)[:2]
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_sabotaj_")
    cases = []
    for label in ("scalat 1,1x", "ridicat 0,5 m", "nod redenumit"):
        g = json.loads(json.dumps(g0))
        kids = {c for n in g["nodes"] for c in n.get("children", [])}
        for i, n in enumerate(g["nodes"]):
            if i in kids:
                continue
            if label.startswith("scalat"):
                n["scale"] = [1.1, 1.1, 1.1]
            elif label.startswith("ridicat"):
                t = n.get("translation", [0, 0, 0])
                n["translation"] = [t[0], t[1] + 0.5, t[2]]
        if label.startswith("nod"):
            for n in g["nodes"]:
                if n.get("name") == "Bayon_Streak":
                    n["name"] = "Bayon_Dare"
        p = os.path.join(tmp, label.replace(" ", "_").replace(",", "") + ".glb")
        _write_glb(p, g, blob)
        cases.append((label, p))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, p in cases:
        print("-- sabotaj: %s" % label)
        passed = check_bayon(p)
        if passed:
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalul:")
    if not check_bayon(path):
        print("   !! SELFTEST ESUAT: garda pica pe original")
        ok = False
    else:
        print("   originalul trece")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    args = sys.argv[1:]
    if args and args[0] == "--selftest":
        sys.exit(0 if selftest(args[1]) else 1)
    if len(args) >= 2 and args[0] == "bayon":
        sys.exit(0 if check_bayon(args[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
