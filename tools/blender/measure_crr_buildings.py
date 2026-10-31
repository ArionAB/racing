"""Garda grupei crr-e (satul Colonnata si blocul-semn, kit §1.4) -- citeste
GLB-urile EXPORTATE, in coordonate GODOT (X latime, Y sus, Z adancime; Blender
+Y = Godot -Z), cu transformarile nodurilor.

    python tools/blender/measure_crr_buildings.py            # toate piesele din ROOT
    python tools/blender/measure_crr_buildings.py <glb> ...  # doar fisierele date
                                                             # (piesa se ia din nume)

Contractele (kit §1.4; toleranta e in paranteza):
  colonnata_church  varful crucii 14,0 (+-0,05); clopotnita 4 x 4 masurata pe
                    trunchi intre 6,2 si 6,5 m (+0 .. +0,12); coama navei 10,0
                    (+-0,10), pe tigla din afara clopotnitei; nava 8 x 14 masurata
                    pe zidarie intre 7,0 si 7,3 m (peste pronaos si anexa, sub
                    streasina), in afara clopotnitei (+0 .. +0,12: pietrele de
                    colt ies 4 cm); usa (Church_Wood sub 3,5 m) pe fata -Z.
  colonnata_house_a 9 x 7 (X x Z), coama 8,0, coama pe X
  colonnata_house_b 7 x 8, coama 8,5, coama pe Z (frontonul spre -Z = +Y Blender),
                    HORN MARE: zidaria urca >= 1,0 m peste coama
  colonnata_house_c 10 x 7, coama 7,5, coama pe X, SCARA + TERASA: zidaria din
                    fata fetei -Z (Z < -3,8) urca la 2,6..3,0 si se intinde >= 6 m
                    pe X
     casele: amprenta masurata pe zidarie, in banda de 0,5 m de sub streasina
     (+0 .. +0,12); coama = varful tiglei (+-0,08); A si C au hornul sub
     coama + 1,0 (silueta diferita de B).
  quarry_sign_block 3,0 x 2,0 x 2,0 (+-0,01); fata slefuita (-Z): TOATE varfurile
                    din planul ei (1 mm) acopera 3,0 x 2,0 si sunt in Sign_Marble.
Pe toate: numele nodurilor-mesh exacte, sloturile pe nod (din UV) doar cele
declarate, fara FOAM_WHITE 22 si fara CAR_* 14-16.
Iese cu 1 la orice abatere sau la zero varfuri citite.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor            # noqa: E402
from measure_carrara_crr_a import nodes_points, bbox, fmt  # noqa: E402

ROOT = os.path.join("assets", "models", "carrara")
FORBIDDEN = {22: "FOAM_WHITE", 14: "CAR_RED", 15: "CAR_BLUE", 16: "CAR_YELLOW"}
HOUSE_SLOTS = {"House_Stone": {29}, "House_Roof": {23}, "House_Wood": {9, 28},
               "House_Shutter": {12}, "House_Void": {20}}
PIECES = {
    "colonnata_church": ("buildings/colonnata_church.glb",
                         {"Church_Stone": {29}, "Church_Roof": {23}, "Church_Wood": {9, 28},
                          "Church_Void": {20}}),
    "colonnata_house_a": ("buildings/colonnata_house_a.glb", HOUSE_SLOTS),
    "colonnata_house_b": ("buildings/colonnata_house_b.glb", HOUSE_SLOTS),
    "colonnata_house_c": ("buildings/colonnata_house_c.glb", HOUSE_SLOTS),
    "quarry_sign_block": ("props/quarry_sign_block.glb",
                          {"Sign_Marble": {19}, "Sign_MarbleBase": {29}}),
}
# casa: (X, Z amprenta, coama, zw = peretele sub streasina, coama pe axa)
HOUSES = {"colonnata_house_a": (9.0, 7.0, 8.0, 5.5, "X"),
          "colonnata_house_b": (7.0, 8.0, 8.5, 5.9, "Z"),
          "colonnata_house_c": (10.0, 7.0, 7.5, 5.2, "X")}


def node_slots(path):
    g, blob = load_glb(path)[:2]
    out = {}
    for n in g["nodes"]:
        if "mesh" not in n:
            continue
        s = set()
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            if "TEXCOORD_0" in prim["attributes"]:
                for uv in read_accessor(g, blob, prim["attributes"]["TEXCOORD_0"]):
                    s.add(int(uv[0] * 32))
        out[n.get("name")] = s
    return out


def ext(pts, k):
    return max(p[k] for p in pts) - min(p[k] for p in pts)


def band(pts, y0, y1, pred=None):
    return [p for p in pts if y0 < p[1] < y1 and (pred is None or pred(p))]


def in_range(bad, label, v, lo, hi):
    ok = lo <= v <= hi
    print("  %-46s %7.3f  [%.2f .. %.2f] %s" % (label, v, lo, hi, "" if ok else "  <-- !!"))
    if not ok:
        bad.append("%s %.3f in afara [%.2f .. %.2f]" % (label, v, lo, hi))


def common(path, slots_want, bad):
    _, pts, _ = nodes_points(path)
    names = sorted(pts)
    if names != sorted(slots_want):
        bad.append("noduri %s, cerute %s" % (names, sorted(slots_want)))
    if not any(pts.values()):
        bad.append("zero varfuri")
    got = node_slots(path)
    for nm, s in got.items():
        f = s & set(FORBIDDEN)
        if f:
            bad.append("%s foloseste sloturi interzise %s" % (nm, sorted(f)))
        want = slots_want.get(nm)
        if want is not None and not s <= want:
            bad.append("%s are sloturile %s, declarate %s" % (nm, sorted(s), sorted(want)))
    print("  sloturi: " + ", ".join("%s %s" % (k, sorted(v)) for k, v in sorted(got.items())))
    return pts


def check_church(pts, bad):
    allp = [p for v in pts.values() for p in v]
    print("  tot " + fmt(bbox(allp)))
    in_range(bad, "varful crucii (Y max)", max(p[1] for p in allp), 13.95, 14.05)
    in_range(bad, "crucea = varful Church_Wood", max(p[1] for p in pts["Church_Wood"]), 13.95, 14.05)
    # trunchiul clopotnitei intre fante si brau (6,2-6,5 m), la +X de nava si in
    # fata spatelui ei (Z < -3,3): acolo stau doar peretii si pietrele de colt
    shaft = band(pts["Church_Stone"], 6.2, 6.5, lambda p: p[0] > 3.5 and p[2] < -3.3)
    if not shaft:
        bad.append("clopotnita: nicio zidarie intre 6,2 si 6,5")
        return
    in_range(bad, "clopotnita X (trunchi 6,2-6,5)", ext(shaft, 0), 4.0, 4.12)
    in_range(bad, "clopotnita Z (trunchi 6,2-6,5)", ext(shaft, 2), 4.0, 4.12)
    tx0 = min(p[0] for p in shaft) - 0.6       # tot ce e la stanga clopotnitei (cu streasina)
    roof = [p for p in pts["Church_Roof"] if p[0] < tx0]
    in_range(bad, "coama navei (tigla in afara clopotnitei)", max(p[1] for p in roof), 9.90, 10.10)
    # nava 8 x 14: latimea in spatele clopotnitei (Z > -3,3), lungimea la stanga ei
    nave_x = band(pts["Church_Stone"], 7.0, 7.3, lambda p: p[2] > -3.3)
    nave_z = band(pts["Church_Stone"], 7.0, 7.3, lambda p: p[0] < 3.9)
    in_range(bad, "nava X (zidarie 7,0-7,3)", ext(nave_x, 0), 8.0, 8.12)
    in_range(bad, "nava Z (zidarie 7,0-7,3)", ext(nave_z, 2), 14.0, 14.12)
    door = [p for p in pts["Church_Wood"] if p[1] < 3.5]
    zc = 0.5 * (min(p[2] for p in allp) + max(p[2] for p in allp))
    dz = sum(p[2] for p in door) / max(1, len(door))
    print("  usa: Z mediu %.2f (centrul bbox %.2f; fata bogata = -Z)" % (dz, zc))
    if not door or dz > zc - 3.0:
        bad.append("usa nu e pe fata -Z (Z mediu %.2f)" % dz)


def check_house(name, pts, bad):
    X, Z, H, zw, axis = HOUSES[name]
    allp = [p for v in pts.values() for p in v]
    print("  tot " + fmt(bbox(allp)))
    body = band(pts["House_Stone"], zw - 0.6, zw - 0.1)
    in_range(bad, "amprenta X (zidarie sub streasina)", ext(body, 0), X, X + 0.12)
    in_range(bad, "amprenta Z (zidarie sub streasina)", ext(body, 2), Z, Z + 0.12)
    roof = pts["House_Roof"]
    top = max(p[1] for p in roof)
    in_range(bad, "coama (varful tiglei)", top, H - 0.08, H + 0.08)
    ridge = [p for p in roof if p[1] > top - 0.3]
    ex, ez = ext(ridge, 0), ext(ridge, 2)
    print("  coama: intindere X %.2f, Z %.2f -> pe %s (cerut %s)" % (ex, ez, "X" if ex > ez else "Z", axis))
    if (ex > ez) != (axis == "X"):
        bad.append("coama pe alta axa decat %s" % axis)
    stone_top = max(p[1] for p in pts["House_Stone"])
    if name == "colonnata_house_b":
        in_range(bad, "hornul mare peste coama", stone_top - top, 1.0, 2.5)
    else:
        in_range(bad, "hornul peste coama (sub 1,0)", stone_top - top, -1.0, 0.999)
    if name == "colonnata_house_c":
        front = [p for p in pts["House_Stone"] if p[2] < -(Z * 0.5 + 0.3)]
        if not front:
            bad.append("fara scara/terasa in fata fetei -Z")
            return
        in_range(bad, "scara+terasa: inaltimea (Z < -3,8)", max(p[1] for p in front), 2.6, 3.0)
        in_range(bad, "scara+terasa: intinderea pe X", ext(front, 0), 6.0, X)


def check_sign(pts, bad):
    allp = [p for v in pts.values() for p in v]
    b = bbox(allp)
    print("  tot " + fmt(b))
    for k, nm, want in ((0, "X", 3.0), (1, "Y", 2.0), (2, "Z", 2.0)):
        in_range(bad, "blocul %s" % nm, b[k][1] - b[k][0], want - 0.01, want + 0.01)
    zmin = b[2][0]
    face = [p for p in allp if p[2] < zmin + 0.001]
    in_range(bad, "fata slefuita (-Z): latime", ext(face, 0), 2.99, 3.01)
    in_range(bad, "fata slefuita (-Z): inaltime", ext(face, 1), 1.99, 2.01)
    base_on_face = [p for p in pts.get("Sign_MarbleBase", []) if p[2] < zmin + 0.001]
    if base_on_face:
        bad.append("patina (Sign_MarbleBase) pe fata slefuita: %d varfuri" % len(base_on_face))
    else:
        print("  fata slefuita: un plan, doar Sign_Marble")


def run(name, path):
    print("== %s (%s)" % (name, path))
    bad = []
    if not os.path.exists(path):
        print("   !! LIPSESTE")
        return False
    pts = common(path, PIECES[name][1], bad)
    if not bad:
        if name == "colonnata_church":
            check_church(pts, bad)
        elif name in HOUSES:
            check_house(name, pts, bad)
        else:
            check_sign(pts, bad)
    for b in bad:
        print("   !! " + b)
    print("%s: %s" % (name, "OK" if not bad else "PROBLEME"))
    return not bad


def main():
    args = sys.argv[1:]
    ok = True
    if args:
        for path in args:
            stem = os.path.splitext(os.path.basename(path))[0]
            name = next((n for n in PIECES if stem.startswith(n)), None)
            if name is None:
                sys.exit("piesa necunoscuta: %s" % path)
            ok &= run(name, path)
    else:
        for name, (rel, _) in PIECES.items():
            ok &= run(name, os.path.join(ROOT, rel))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
