"""Garzile pieselor crr-d din kitul Carrara (val 2: utilajele de decor si coltul
de muzeu) -- citesc GLB-ul EXPORTAT, in coordonate GODOT (Y sus, -Z inainte),
cu transformarile nodurilor (helperele din measure_carrara_crr_a.py).

    python tools/blender/measure_carrara_crr_d.py wire_saw <glb>
    python tools/blender/measure_carrara_crr_d.py crawler  <glb>
    python tools/blender/measure_carrara_crr_d.py drill    <glb>
    python tools/blender/measure_carrara_crr_d.py cart     <glb>
    python tools/blender/measure_carrara_crr_d.py wheel    <glb>
    python tools/blender/measure_carrara_crr_d.py sled     <glb>

Contractele (docs/asset_briefs/carrara_kit.md §1.2, §1.4):
  wire_saw  `Blades` = volantul, consumat de windmill.gd (rotit pe axa LUI
            locala): rotatie identitate si scala 1 pe nod; varfurile lui
            centrate pe origine in planul YZ (+-0,02: originea in BUTUC), raza
            maxima 0,90 +-0,03 (Ø 1,8), subtire pe X (<= 0,4 si < 1/4 din
            diametru: axa pe X); volantul nu atinge sinele (>= 5 cm peste ele).
            Sinele (`Saw_Rail`, varfurile sub 0,25 m): 6,0 +-0,05 pe Z, doua
            fire la x = +-0,75. Sasiul (`Saw_Paint`): 1,6 +-0,1 pe X, 2,5 +-0,1
            pe Z, varful la 1,4 +-0,1 peste ciuperca sinei. Ansamblul in
            +-1,0 pe X si +-3,0 pe Z (nimic nu iese din sine).
  crawler   corpul fara lama (toate nodurile in afara de `Crawler_Blade`):
            4,5 +-0,2 pe Z, inaltimea 2,2 +-0,1; lama (`Crawler_Blade`)
            4,0 +-0,15 pe Z, in fata corpului (-Z), cu >= 30 de dinti.
  drill     senilele (`Drill_Black`, varfurile sub 1,0 m): 3,5 +-0,15 pe Z;
            catargul (`Drill_Mast`): 6,0 +-0,2 pe verticala, in fata senilelor
            (-Z); inaltimea totala <= 6,5.
  cart      sinele (`Cart_Rust`, varfurile sub 0,2 m): 3,0 +-0,05 pe Z;
            vagonetul (`Cart_Wood`, varfurile peste 0,3 m): 2,0 +-0,1 pe Z;
            blocul (`Cart_Marble*`): latura maxima 1,0 +-0,1.
  wheel     roata (`Pulley_Rust`): Ø 2,0 +-0,05 in planul YZ (Y si Z), pe X
            <= 0,6; suportul (`Pulley_Wood`) pe sol (Y 0).
  sled      sania (`OldSled_Wood`): lungimea (max X, Z) 2,5 +-0,1; franghia
            (`OldSled_Rope`) prezenta, peste talpa.
Iese cu cod 1 la orice abatere sau la zero varfuri citite.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_carrara_crr_a import nodes_points, bbox, fmt
from verify_glb import load_glb, read_accessor


def _span(bb, k):
    return bb[k][1] - bb[k][0]


def _local_points(path, name):
    g, blob = load_glb(path)[:2]
    for n in g["nodes"]:
        if n.get("name") == name and "mesh" in n:
            pts = [p for prim in g["meshes"][n["mesh"]]["primitives"]
                   for p in read_accessor(g, blob, prim["attributes"]["POSITION"])]
            return n, pts
    return None, []


def _need(pts, names, bad):
    miss = [n for n in names if not pts.get(n)]
    if miss:
        bad.append("lipsesc nodurile %s (are %s)" % (miss, sorted(pts)))
    return not miss


def check_wire_saw(path, bad):
    _, pts, _ = nodes_points(path)
    if not _need(pts, ("Blades", "Saw_Paint", "Saw_Rust", "Saw_Rail", "Saw_Water"), bad):
        return
    node, loc = _local_points(path, "Blades")
    r = node.get("rotation", [0, 0, 0, 1])
    s = node.get("scale", [1, 1, 1])
    t = node.get("translation", [0, 0, 0])
    print("Blades     pivot (Godot) (%.3f, %.3f, %.3f), rotatie %s, scala %s" % (tuple(t) + (r, s)))
    if any(abs(r[k]) > 1e-4 for k in range(3)) or any(abs(v - 1) > 1e-4 for v in s):
        bad.append("Blades are rotatie/scala %s %s: windmill.gd roteste pe axa LOCALA" % (r, s))
    lb = bbox(loc)
    cy, cz = (lb[1][0] + lb[1][1]) / 2, (lb[2][0] + lb[2][1]) / 2
    rmax = max(math.hypot(p[1], p[2]) for p in loc)
    sx = _span(lb, 0)
    print("Blades     local " + fmt(lb) + "   (centru YZ %+.3f %+.3f, raza max %.3f, grosime X %.3f)"
          % (cy, cz, rmax, sx))
    if abs(cy) > 0.02 or abs(cz) > 0.02:
        bad.append("originea lui Blades nu e in butuc: centrul YZ %+.3f %+.3f" % (cy, cz))
    if abs(rmax - 0.90) > 0.03:
        bad.append("raza volantului %.3f, cerut 0,90 (Ø 1,8)" % rmax)
    if sx > 0.4 or sx > 0.5 * rmax:
        bad.append("volantul nu e subtire pe X (%.3f): axa nu e X" % sx)
    w = bbox(pts["Blades"])
    rl = [p for p in pts["Saw_Rail"] if p[1] < 0.25]
    if not rl:
        bad.append("sinele n-au varfuri sub 0,25 m")
        return
    rb = bbox(rl)
    rail_top = rb[1][1]
    print("sine       " + fmt(rb) + "   (lungime %.3f)" % _span(rb, 2))
    if abs(_span(rb, 2) - 6.0) > 0.05:
        bad.append("sinele %.3f pe Z, cerut 6,0 +-0,05" % _span(rb, 2))
    for x0 in (-0.75, 0.75):
        if not any(abs(p[0] - x0) < 0.1 for p in rl):
            bad.append("lipseste firul de sina de la x = %+.2f" % x0)
    if w[1][0] < rail_top + 0.05:
        bad.append("volantul coboara la %.3f, sina e la %.3f" % (w[1][0], rail_top))
    pb = bbox(pts["Saw_Paint"])
    h = pb[1][1] - rail_top
    print("sasiu      " + fmt(pb) + "   (%.3f x %.3f, %.3f peste sina)" % (_span(pb, 0), _span(pb, 2), h))
    if abs(_span(pb, 0) - 1.6) > 0.1 or abs(_span(pb, 2) - 2.5) > 0.1:
        bad.append("sasiul %.3f x %.3f, cerut 1,6 x 2,5" % (_span(pb, 0), _span(pb, 2)))
    if abs(h - 1.4) > 0.1:
        bad.append("sasiul %.3f peste sina, cerut 1,4" % h)
    a = bbox([p for v in pts.values() for p in v])
    print("tot        " + fmt(a))
    if a[0][0] < -1.01 or a[0][1] > 1.01 or a[2][0] < -3.01 or a[2][1] > 3.01:
        bad.append("ansamblul iese din +-1,0 x +-3,0")
    if abs(a[1][0]) > 0.01:
        bad.append("talpa la Y %.3f" % a[1][0])


def _islands(path, name):
    """Numarul de componente conexe din primitivele nodului (dintii lamei)."""
    g, blob = load_glb(path)[:2]
    for n in g["nodes"]:
        if n.get("name") != name or "mesh" not in n:
            continue
        total = 0
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            pos = read_accessor(g, blob, prim["attributes"]["POSITION"])
            idx = read_accessor(g, blob, prim["indices"])
            idx = [int(i[0]) if isinstance(i, (tuple, list)) else int(i) for i in idx]
            # varfurile duplicate (normale/UV diferite) se sudeaza pe pozitie
            key = {}
            rep = []
            for p in pos:
                k = (round(p[0], 4), round(p[1], 4), round(p[2], 4))
                rep.append(key.setdefault(k, len(key)))
            par = list(range(len(key)))

            def f(i):
                while par[i] != i:
                    par[i] = par[par[i]]
                    i = par[i]
                return i
            for k in range(0, len(idx) - 2, 3):
                a, b, c = (rep[idx[k]], rep[idx[k + 1]], rep[idx[k + 2]])
                for u in (b, c):
                    ra, ru = f(a), f(u)
                    if ra != ru:
                        par[ru] = ra
            total += len({f(i) for i in range(len(key))})
        return total
    return 0


def check_crawler(path, bad):
    _, pts, _ = nodes_points(path)
    if not _need(pts, ("Crawler_Paint", "Crawler_Rust", "Crawler_Black", "Crawler_Blade"), bad):
        return
    body = bbox([p for k, v in pts.items() if k != "Crawler_Blade" for p in v])
    bl = bbox(pts["Crawler_Blade"])
    print("corp       " + fmt(body) + "   (lungime %.3f, inaltime %.3f)" % (_span(body, 2), body[1][1]))
    print("lama       " + fmt(bl) + "   (lungime %.3f)" % _span(bl, 2))
    if abs(_span(body, 2) - 4.5) > 0.2:
        bad.append("corpul %.3f pe Z, cerut 4,5 +-0,2" % _span(body, 2))
    if abs(body[1][1] - 2.2) > 0.1:
        bad.append("inaltimea %.3f, cerut 2,2 +-0,1" % body[1][1])
    if abs(_span(bl, 2) - 4.0) > 0.15:
        bad.append("lama %.3f pe Z, cerut 4,0 +-0,15" % _span(bl, 2))
    if bl[2][0] > body[2][0] - 3.5:
        bad.append("lama nu iese in fata corpului (-Z): %.3f vs %.3f" % (bl[2][0], body[2][0]))
    teeth = _islands(path, "Crawler_Blade") - 1
    print("dinti      %d (insule in Crawler_Blade, fara bara)" % teeth)
    if teeth < 30:
        bad.append("lama are %d dinti, cerut >= 30 (relief, nu textura)" % teeth)
    a = bbox([p for v in pts.values() for p in v])
    if abs(a[1][0]) > 0.01:
        bad.append("talpa la Y %.3f" % a[1][0])


def check_drill(path, bad):
    _, pts, _ = nodes_points(path)
    if not _need(pts, ("Drill_Paint", "Drill_Rust", "Drill_Black", "Drill_Mast"), bad):
        return
    tr = [p for p in pts["Drill_Black"] if p[1] < 1.0]
    tb = bbox(tr)
    mb = bbox(pts["Drill_Mast"])
    a = bbox([p for v in pts.values() for p in v])
    print("senile     " + fmt(tb) + "   (lungime %.3f)" % _span(tb, 2))
    print("catarg     " + fmt(mb) + "   (inaltime %.3f)" % _span(mb, 1))
    print("tot        " + fmt(a))
    if abs(_span(tb, 2) - 3.5) > 0.15:
        bad.append("senilele %.3f pe Z, cerut 3,5 +-0,15" % _span(tb, 2))
    if abs(_span(mb, 1) - 6.0) > 0.2:
        bad.append("catargul %.3f inalt, cerut 6,0 +-0,2" % _span(mb, 1))
    if (mb[2][0] + mb[2][1]) / 2 > tb[2][0] + 0.5:
        bad.append("catargul nu e in fata (-Z): centru Z %.3f, senilele incep la %.3f"
                   % ((mb[2][0] + mb[2][1]) / 2, tb[2][0]))
    if a[1][1] > 6.5:
        bad.append("inaltimea totala %.3f > 6,5" % a[1][1])
    if abs(a[1][0]) > 0.01:
        bad.append("talpa la Y %.3f" % a[1][0])


def check_cart(path, bad):
    _, pts, _ = nodes_points(path)
    if not _need(pts, ("Cart_Wood", "Cart_Rust", "Cart_Marble", "Cart_MarbleBase"), bad):
        return
    rl = bbox([p for p in pts["Cart_Rust"] if p[1] < 0.2])
    wd = bbox([p for p in pts["Cart_Wood"] if p[1] > 0.3])
    mb = bbox(pts["Cart_Marble"] + pts["Cart_MarbleBase"])
    print("sine       " + fmt(rl) + "   (lungime %.3f)" % _span(rl, 2))
    print("vagonet    " + fmt(wd) + "   (lungime %.3f)" % _span(wd, 2))
    print("bloc       " + fmt(mb) + "   (%.3f x %.3f x %.3f)" % tuple(_span(mb, k) for k in range(3)))
    if abs(_span(rl, 2) - 3.0) > 0.05:
        bad.append("sinele %.3f, cerut 3,0" % _span(rl, 2))
    if abs(_span(wd, 2) - 2.0) > 0.1:
        bad.append("vagonetul %.3f, cerut 2,0" % _span(wd, 2))
    if abs(max(_span(mb, k) for k in range(3)) - 1.0) > 0.1:
        bad.append("blocul %.3f, cerut 1,0" % max(_span(mb, k) for k in range(3)))


def check_wheel(path, bad):
    _, pts, _ = nodes_points(path)
    if not _need(pts, ("Pulley_Rust", "Pulley_Wood"), bad):
        return
    wb = bbox(pts["Pulley_Rust"])
    sb = bbox(pts["Pulley_Wood"])
    print("roata      " + fmt(wb) + "   (%.3f x %.3f x %.3f)" % tuple(_span(wb, k) for k in range(3)))
    print("suport     " + fmt(sb))
    for k, nm in ((1, "Y"), (2, "Z")):
        if abs(_span(wb, k) - 2.0) > 0.05:
            bad.append("roata %.3f pe %s, cerut Ø 2,0" % (_span(wb, k), nm))
    if _span(wb, 0) > 0.6:
        bad.append("roata %.3f lata pe X (> 0,6)" % _span(wb, 0))
    if abs(sb[1][0]) > 0.01:
        bad.append("suportul nu sta pe sol (Y %.3f)" % sb[1][0])


def check_sled(path, bad):
    _, pts, _ = nodes_points(path)
    if not _need(pts, ("OldSled_Wood", "OldSled_Rope"), bad):
        return
    wb = bbox(pts["OldSled_Wood"])
    rb = bbox(pts["OldSled_Rope"])
    L = max(_span(wb, 0), _span(wb, 2))
    print("sanie      " + fmt(wb) + "   (lungime %.3f)" % L)
    print("franghie   " + fmt(rb))
    if abs(L - 2.5) > 0.1:
        bad.append("sania %.3f, cerut 2,5 +-0,1" % L)
    if rb[1][0] < 0.15:
        bad.append("franghia coboara la %.3f: nu sta pe sanie" % rb[1][0])
    if abs(wb[1][0]) > 0.01:
        bad.append("talpa la Y %.3f" % wb[1][0])


CHECKS = {"wire_saw": check_wire_saw, "crawler": check_crawler, "drill": check_drill,
          "cart": check_cart, "wheel": check_wheel, "sled": check_sled}


def main():
    kind, path = sys.argv[1], sys.argv[2]
    bad = []
    CHECKS[kind](path, bad)
    for b in bad:
        print("   !! " + b)
    print("%s: %s" % (kind, "OK" if not bad else "PROBLEME"))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
