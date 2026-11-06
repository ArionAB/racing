"""Garda elefantului asiatic Angkor (val 1, grupul C) -- citeste GLB-ul
EXPORTAT (glTF JSON + accesoare + joints/weights), in coordonate GODOT
(Y sus, fata pe -Z). Nu cere Blender.

    python tools/blender/measure_angkor_w1c.py elephant <glb>
    python tools/blender/measure_angkor_w1c.py --selftest <glb>

Contractul (kit 1.3), tot ce se poate masura pe fisier:
  * nodurile, EXACT cele ale elefantului din Serengeti: 11 oase (Body, Head,
    Trunk1/2, EarL/R, LegFL/FR/RL/RR, Tail) + `Elephant_Mesh` + radacina
    `Elephant` -- `StrideDriver` conduce picioarele si `Body` dupa nume;
  * animatiile `Walk` (1,5 s) si `Trumpet`;
  * UMARUL 2,8-3,0 m: cel mai inalt punct al corpului (varfuri cu Body ca os
    dominant, |x| < 0,8) in dreptul picioarelor din fata (+-0,6 m); fara
    cap si urechi. LUNGIMEA 5,4-5,8 m cu trompa (extinderea pe Z a intregului
    mesh). Inaltimea totala (cu bolta capului) <= 3,4;
  * spatele cel mai inalt LA MIJLOC: maximul dintre picioare e cu >= 0,10 m
    peste umar si >= sold; SOLDUL (la picioarele din spate) nu coboara cu
    mai mult de 0,20 m sub umar, iar varful capului nu depaseste spatele de
    la mijloc (cote raportate);
  * urechi MICI: latimea totala (X, cu urechi) <= 2,8 m, fata de 4,0 m la cel african;
  * radacina fara scala/rotatie; sloturile = cele ale elefantului din
    Serengeti (acelasi aranjament, ca jocul sa-l trateze identic).
Iese cu cod 1 la incalcare. `--selftest`: copii sabotate (os redenumit, scala
1,2x pe radacina, animatie redenumita) trebuie sa pice; originalul trece.
"""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402
from measure_angkor import quat_rot, world_points, _write_glb  # noqa: E402

BONES = {"Body", "Head", "Trunk1", "Trunk2", "EarL", "EarR",
         "LegFL", "LegFR", "LegRL", "LegRR", "Tail"}
SHOULDER = (2.8, 3.0)
LENGTH = (5.4, 5.8)
HEIGHT_MAX = 3.4
ARCH_MIN = 0.10
HIP_DROP_MAX = 0.20      # soldul (la picioarele din spate) nu cade mai mult de atat sub umar
EAR_WIDTH_MAX = 2.80
WALK_S = 1.5
SERENGETI = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                         "assets", "models", "serengeti", "animals", "elephant.glb")


def node_world(g, i):
    parent = {c: p for p, n in enumerate(g["nodes"]) for c in n.get("children", [])}
    p, k = (0.0, 0.0, 0.0), i
    while True:
        n = g["nodes"][k]
        s = n.get("scale", [1, 1, 1])
        p = (p[0] * s[0], p[1] * s[1], p[2] * s[2])
        p = quat_rot(n.get("rotation", [0, 0, 0, 1]), p)
        t = n.get("translation", [0, 0, 0])
        p = (p[0] + t[0], p[1] + t[1], p[2] + t[2])
        if k not in parent:
            return p
        k = parent[k]


def slots_of(path):
    g, blob = load_glb(path)[:2]
    out = set()
    for n in g["nodes"]:
        if "mesh" in n:
            for prim in g["meshes"][n["mesh"]]["primitives"]:
                for u in read_accessor(g, blob, prim["attributes"]["TEXCOORD_0"]):
                    out.add(int(u[0] * 32))
    return out


def check(path, report=True):
    g, blob = load_glb(path)[:2]
    bad = []
    names = [n.get("name", "") for n in g["nodes"]]
    # --- noduri ---
    missing = sorted((BONES | {"Elephant_Mesh", "Elephant"}) - set(names))
    extra = sorted(set(names) - BONES - {"Elephant_Mesh", "Elephant"})
    if missing:
        bad.append("lipsesc nodurile %s" % missing)
    if extra:
        bad.append("noduri in plus %s" % extra)
    mesh_nodes = [n for n in g["nodes"] if "mesh" in n]
    if [n.get("name") for n in mesh_nodes] != ["Elephant_Mesh"]:
        bad.append("mesh-ul trebuie sa fie UN singur nod `Elephant_Mesh`, nu %s"
                   % [n.get("name") for n in mesh_nodes])
    # --- animatii ---
    anims = {a.get("name"): a for a in g.get("animations", [])}
    if set(anims) != {"Walk", "Trumpet"}:
        bad.append("animatii %s, cerute Walk + Trumpet" % sorted(map(str, anims)))
    if "Walk" in anims:
        acc = [g["accessors"][s["input"]] for s in anims["Walk"]["samplers"]]
        dur = max(a["max"][0] for a in acc) - min(a["min"][0] for a in acc)
        if report:
            print("Walk      durata %.3f s (cerut %.1f)" % (dur, WALK_S))
        if abs(dur - WALK_S) > 0.02:
            bad.append("Walk dureaza %.3f s, nu %.1f" % (dur, WALK_S))
    # --- radacina ---
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    for i, n in enumerate(g["nodes"]):
        if i in kids:
            continue
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            bad.append("scala/rotatie neaplicata pe radacina `%s`" % n.get("name"))
    if "Elephant_Mesh" not in names or "LegFL" not in names or "LegRL" not in names:
        for b in bad:
            print("   !! " + b)
        return False
    # --- cote ---
    pts = world_points(g, blob)
    xs, ys, zs = [p[0] for p in pts], [p[1] for p in pts], [p[2] for p in pts]
    length = max(zs) - min(zs)
    height = max(ys) - min(ys)
    width = max(xs) - min(xs)
    mi = next(i for i, n in enumerate(g["nodes"]) if "mesh" in n)
    prim = g["meshes"][g["nodes"][mi]["mesh"]]["primitives"][0]
    joints = read_accessor(g, blob, prim["attributes"]["JOINTS_0"])
    wts = read_accessor(g, blob, prim["attributes"]["WEIGHTS_0"])
    skin_names = [g["nodes"][j].get("name") for j in g["skins"][0]["joints"]]
    body = []
    for p, jn, w in zip(pts, joints, wts):
        k = max(range(4), key=lambda q: w[q])
        if skin_names[jn[k]] == "Body" and abs(p[0]) < 0.8:
            body.append(p)
    zf = node_world(g, names.index("LegFL"))[2]
    zr = node_world(g, names.index("LegRL"))[2]
    sh = max(p[1] for p in body if abs(p[2] - zf) <= 0.6)
    rump = max(p[1] for p in body if abs(p[2] - zr) <= 0.6)
    mid = max(p[1] for p in body if min(zf, zr) < p[2] < max(zf, zr))
    head_top = max(p[1] for p, jn, w in zip(pts, joints, wts)
                   if skin_names[jn[max(range(4), key=lambda q: w[q])]] == "Head")
    ntri = sum(g["accessors"][pr["indices"]]["count"] // 3
               for n in mesh_nodes for pr in g["meshes"][n["mesh"]]["primitives"])
    if report:
        print("cote      umar %.3f m   spate-mijloc %.3f   sold %.3f (umar%+.3f)   varf cap %.3f   lungime %.3f   "
              "inaltime totala %.3f   latime (cu urechi) %.3f   min Y %.3f   %d tri"
              % (sh, mid, rump, rump - sh, head_top, length, height, width, min(ys), ntri))
    if not SHOULDER[0] <= sh <= SHOULDER[1]:
        bad.append("umarul %.3f in afara %.1f-%.1f" % (sh, SHOULDER[0], SHOULDER[1]))
    if not LENGTH[0] <= length <= LENGTH[1]:
        bad.append("lungimea %.3f in afara %.1f-%.1f" % (length, LENGTH[0], LENGTH[1]))
    if height > HEIGHT_MAX:
        bad.append("inaltimea totala %.3f > %.1f" % (height, HEIGHT_MAX))
    if mid < sh + ARCH_MIN or mid < rump:
        bad.append("spatele nu e cel mai inalt la mijloc: mijloc %.3f, umar %.3f, sold %.3f "
                   "(cerut mijloc >= umar + %.2f si >= sold)" % (mid, sh, rump, ARCH_MIN))
    if rump < sh - HIP_DROP_MAX:
        bad.append("soldul %.3f cade cu %.3f sub umar (max %.2f): spate lasat"
                   % (rump, sh - rump, HIP_DROP_MAX))
    if head_top > mid + 0.02:
        bad.append("capul (%.3f) trece peste spatele de la mijloc (%.3f)" % (head_top, mid))
    if width > EAR_WIDTH_MAX:
        bad.append("latime %.3f > %.2f: urechi prea mari" % (width, EAR_WIDTH_MAX))
    if abs(min(ys)) > 0.02:
        bad.append("min Y %.3f != 0" % min(ys))
    ser = os.path.normpath(SERENGETI)
    if os.path.exists(ser):
        a, b = slots_of(path), slots_of(ser)
        if report:
            print("sloturi   %s (Serengeti %s)" % (sorted(a), sorted(b)))
        if a != b:
            bad.append("sloturi %s != cele din Serengeti %s" % (sorted(a), sorted(b)))
    for b in bad:
        print("   !! " + b)
    return not bad


def selftest(path):
    g0, blob = load_glb(path)[:2]
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_sabotaj_w1c_")
    cases = []
    for label in ("os redenumit", "scalat 1,2x", "animatie redenumita"):
        g = json.loads(json.dumps(g0))
        kids = {c for n in g["nodes"] for c in n.get("children", [])}
        if label.startswith("os"):
            for n in g["nodes"]:
                if n.get("name") == "LegFL":
                    n["name"] = "LegXL"
        elif label.startswith("scalat"):
            for i, n in enumerate(g["nodes"]):
                if i not in kids:
                    n["scale"] = [1.2, 1.2, 1.2]
        else:
            for a in g["animations"]:
                if a["name"] == "Walk":
                    a["name"] = "Wxlk"
        p = os.path.join(tmp, label.replace(" ", "_").replace(",", "") + ".glb")
        _write_glb(p, g, blob)
        cases.append((label, p))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, p in cases:
        print("-- sabotaj: %s" % label)
        if check(p, report=False):
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalul:")
    if not check(path, report=False):
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
    if len(args) >= 2 and args[0] == "elephant":
        sys.exit(0 if check(args[1], report=True) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
