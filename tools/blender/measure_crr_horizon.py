"""Garda fundalului Carrara (kit §1.6, val 2, crr-f) -- citeste GLB-ul EXPORTAT.

    python tools/blender/measure_crr_horizon.py [cale.glb]
    python tools/blender/measure_crr_horizon.py --selftest

In coordonate glTF/Godot (X lungimea crestei, Y sus, Z adancimea), pe fiecare nod:
  - numele: exact ApuanRidge_A, _B, _C, fiecare copil direct al radacinii (radacina
    de scena; in GLB = nod fara parinte), cu scala si rotatia aplicate;
  - lungimea (cea mai mare latura orizontala) in 160-240 m, inaltimea in 35-60 m;
  - originea la BAZA: min Y = 0 (+-0,05) si bbox centrat pe X si Z (+-0,5 m);
  - 2-3 varfuri MARI (proeminenta >= 12 m pe profilul de maxim pe lungime) --
    ApuanRidge_B are voie la dinti secundari in plus (proeminenta 6-12 m);
  - sloturile: doar 29 (calcar), 19 (moloz), 21 (padure), 13 (uscat), toate patru
    prezente; FOAM_WHITE 22 interzis (fara zapada); aria de moloz >= 4%, padurea
    >= 15%, calcarul nu peste 70% (MARBLE_GREY nu sta singur pe o fata mare);
  - siluetele DIFERA: profilul normalizat (cota / cota maxima, pe 40 de coloane)
    al oricaror doua creste difera cu >= 0,06 in medie.
`--selftest` scrie trei copii SABOTATE (nod redenumit, nod ridicat 5 m, nod scalat
x1,6 pe Y) si cere ca fiecare sa pice, iar originalul sa treaca.
Iese cu 1 la prima abatere; tipareste tot.
"""

import json
import os
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor            # noqa: E402
from measure_carrara_truck import quat_rot                 # noqa: E402

GLB = os.path.join("assets", "models", "carrara", "effects", "carrara_horizon.glb")
NODES = ["ApuanRidge_A", "ApuanRidge_B", "ApuanRidge_C"]
ALLOWED = {29: "MARBLE_GREY", 19: "CORAL_SAND", 21: "TROPICAL_GREEN", 13: "DRY_VEGETATION"}


def _xf(n, p):
    s = n.get("scale", [1, 1, 1])
    p = (p[0] * s[0], p[1] * s[1], p[2] * s[2])
    p = quat_rot(n.get("rotation", [0, 0, 0, 1]), p)
    t = n.get("translation", [0, 0, 0])
    return (p[0] + t[0], p[1] + t[1], p[2] + t[2])


def _peaks(col, minprom):
    nb = len(col)
    pk = []
    for i in range(1, nb - 1):
        if col[i] >= col[i - 1] and col[i] > col[i + 1]:
            l = i
            while l > 0 and col[l - 1] <= col[i]:
                l -= 1
            r = i
            while r < nb - 1 and col[r + 1] <= col[i]:
                r += 1
            drops = []
            if l > 0:
                drops.append(col[i] - min(col[l:i + 1]))
            if r < nb - 1:
                drops.append(col[i] - min(col[i:r + 1]))
            pr = min(drops) if drops else col[i] - min(col)
            if pr >= minprom:
                pk.append((i, round(col[i], 1), round(pr, 1)))
    return pk


def _tri_area(a, b, c):
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    x = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    return 0.5 * (x[0] ** 2 + x[1] ** 2 + x[2] ** 2) ** 0.5


def measure(path, quiet=False):
    def say(*a):
        if not quiet:
            print(*a)

    g, blob = load_glb(path)[:2]
    bad = []
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    roots = [i for i in range(len(g["nodes"])) if i not in kids]
    by_name = {}
    for i in roots:
        n = g["nodes"][i]
        if "mesh" in n:
            by_name[n.get("name")] = i
    names = sorted(by_name)
    if names != sorted(NODES):
        bad.append("noduri-radacina %s, cerute %s" % (names, NODES))
    profiles = {}
    for name in NODES:
        if name not in by_name:
            continue
        n = g["nodes"][by_name[name]]
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            bad.append("%s: scala/rotatie neaplicata %s %s" % (name, s, r))
        pts, area, tot = [], {}, 0.0
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            P = [_xf(n, p) for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
            UV = read_accessor(g, blob, prim["attributes"]["TEXCOORD_0"])
            pts += P
            idx = read_accessor(g, blob, prim["indices"]) if "indices" in prim else \
                [(k,) for k in range(len(P))]
            idx = [k[0] for k in idx]
            for t in range(0, len(idx), 3):
                a, b2, c = idx[t], idx[t + 1], idx[t + 2]
                slot = int(UV[a][0] * 32)
                ar = _tri_area(P[a], P[b2], P[c])
                area[slot] = area.get(slot, 0.0) + ar
                tot += ar
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]; zs = [p[2] for p in pts]
        dx, dy, dz = max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)
        L = max(dx, dz)
        cx, cz = (max(xs) + min(xs)) * 0.5, (max(zs) + min(zs)) * 0.5
        # profilul de maxim pe lungime (lungimea e pe X in GLB)
        nb = 60
        col = [0.0] * nb
        for p in pts:
            k = min(nb - 1, max(0, int((p[0] - min(xs)) / dx * nb)))
            col[k] = max(col[k], p[1])
        big = _peaks(col, 12.0)
        small = [q for q in _peaks(col, 6.0) if q[2] < 12.0]
        share = {k: 100.0 * v / tot for k, v in area.items()}
        say("%-13s L %.1f m  H %.1f m  adanc %.1f m  baza Y %.3f  centru (%.2f, %.2f)"
            % (name, L, dy, min(dx, dz), min(ys), cx, cz))
        say("    varfuri mari (prom >= 12 m): %d %s; dinti (6-12 m): %d"
            % (len(big), [(q[1], q[2]) for q in big], len(small)))
        say("    sloturi %%: %s" % ", ".join("%d %s %.1f" % (k, ALLOWED.get(k, "??"), v)
                                          for k, v in sorted(share.items())))
        if not 160.0 <= L <= 240.0:
            bad.append("%s: lungimea %.1f in afara 160-240" % (name, L))
        if not 35.0 <= dy <= 60.0:
            bad.append("%s: inaltimea %.1f in afara 35-60" % (name, dy))
        if abs(min(ys)) > 0.05:
            bad.append("%s: baza la Y %.3f, nu 0" % (name, min(ys)))
        if abs(cx) > 0.5 or abs(cz) > 0.5:
            bad.append("%s: bbox decentrat (%.2f, %.2f)" % (name, cx, cz))
        if not 2 <= len(big) <= 3:
            bad.append("%s: %d varfuri mari, cerute 2-3" % (name, len(big)))
        if name != "ApuanRidge_B" and len(small) > 1:
            bad.append("%s: %d dinti secundari (doar B are voie)" % (name, len(small)))
        extra = set(share) - set(ALLOWED)
        if extra:
            bad.append("%s: sloturi nepermise %s" % (name, sorted(extra)))
        if 22 in share:
            bad.append("%s: FOAM_WHITE 22 (zapada) prezent" % name)
        if set(ALLOWED) - set(share):
            bad.append("%s: lipsesc sloturile %s" % (name, sorted(set(ALLOWED) - set(share))))
        if share.get(19, 0) < 4.0:
            bad.append("%s: molozul %.1f%% < 4%%" % (name, share.get(19, 0)))
        if share.get(21, 0) + share.get(13, 0) < 15.0:
            bad.append("%s: padurea %.1f%% < 15%%" % (name, share.get(21, 0) + share.get(13, 0)))
        if share.get(29, 0) > 70.0:
            bad.append("%s: calcarul %.1f%% > 70%%" % (name, share.get(29, 0)))
        prof = []
        top = max(col) or 1.0
        for k in range(40):
            prof.append(col[min(nb - 1, int(k * nb / 40))] / top)
        profiles[name] = prof
    ks = sorted(profiles)
    for i in range(len(ks)):
        for j in range(i + 1, len(ks)):
            a, b2 = profiles[ks[i]], profiles[ks[j]]
            d = sum(abs(x - y) for x, y in zip(a, b2)) / len(a)
            say("    silueta %s vs %s: diferenta medie %.3f" % (ks[i], ks[j], d))
            if d < 0.06:
                bad.append("siluetele %s si %s prea asemanatoare (%.3f)" % (ks[i], ks[j], d))
    for b2 in bad:
        say("   !! " + b2)
    return not bad


def _write_glb(src, out, mutate):
    with open(src, "rb") as fh:
        data = fh.read()
    off, chunks = 12, []
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunks.append([ctype, data[off + 8: off + 8 + clen]])
        off += 8 + clen
    js = json.loads(chunks[0][1].decode("utf-8"))
    mutate(js)
    raw = json.dumps(js).encode("utf-8")
    raw += b" " * ((4 - len(raw) % 4) % 4)
    chunks[0][1] = raw
    body = b"".join(struct.pack("<II", len(c), t) + c for t, c in chunks)
    with open(out, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)


def selftest(path):
    def node(js, name):
        return next(n for n in js["nodes"] if n.get("name") == name)

    def rename(js):
        node(js, "ApuanRidge_B")["name"] = "ApuanRidge_X"

    def lift(js):
        node(js, "ApuanRidge_A")["translation"] = [0.0, 5.0, 0.0]

    def tall(js):
        node(js, "ApuanRidge_C")["scale"] = [1.0, 1.6, 1.0]

    ok = measure(path, quiet=True)
    print("selftest: originalul %s" % ("TRECE" if ok else "PICA"))
    good = ok
    tmp = tempfile.mkdtemp(prefix="crr_horizon_")
    for tag, fn in (("redenumit", rename), ("ridicat 5 m", lift), ("scalat x1,6", tall)):
        out = os.path.join(tmp, "sabotaj.glb")
        _write_glb(path, out, fn)
        res = measure(out, quiet=True)
        print("selftest: sabotaj %-12s %s" % (tag, "PICA (corect)" if not res else "TRECE (GARDA OARBA)"))
        good = good and not res
        os.remove(out)
    os.rmdir(tmp)
    return good


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--selftest" in args:
        args.remove("--selftest")
        sys.exit(0 if selftest(args[0] if args else GLB) else 1)
    p = args[0] if args else GLB
    ok = measure(p)
    print("crr-f orizont: %s" % ("OK" if ok else "ABATERI"))
    sys.exit(0 if ok else 1)
