"""Garda de gabarit a vegetatiei San Francisco (val 2, inventar §5.4: V1, V3, V4, N2).

    python tools/blender/measure_sf_plants.py             # toate piesele
    python tools/blender/measure_sf_plants.py --selftest  # dovedeste ca fiecare verificare pica pe sabotaj

Citeste GLB-urile direct (coordonate Godot: Y sus, Blender +Y = Godot -Z), cu cititorul din
`measure_sf_bridge.py` / `verify_glb.py` (importate, nu modificate). Ce verifica, pe langa
radacinile fara scala/rotatie/translatie (memoria scala-glb-neaplicata-la-radacina) si
numele exacte ale nodurilor:

  sf_cypress_a/b/c  (v3: v2 + UMPLERE >= 55 % (c: 50 %) a siluetei laterale in dreptunghiul
                    coroanei, rasterizata la 5 cm, si ADANCIME pe Z a masei >= 6,5 m (c: 5,5))
                    (v2, arbore de polite) a si b: inaltimea 7-9 m, coroana (`Cypress_Crown`)
                    11-13 m pe X, inaltime / latime <= 0,75; c: 6,5-8 m si 9-10 m. Cardurile
                    cel mult 1 m peste latimea maxima. APLECAREA: centrul de masa al coroanei
                    la cel putin +2,5 m pe X fata de baza (vantul vine din -X, deci un palc pus
                    cu yaw 0 se apleaca la fel); SURPLOMBA: polita de sus (ultimii 1,2 m ai
                    coroanei) ajunge la cel putin +3,0 m pe X; BAZA: diametrul trunchiului la
                    +0,5 m (cu contraforturi) cel putin 1,6 m, centrata pe origine (varfurile
                    sub 0,3 m, in 0,25 m de axa) si pe sol (min Y = 0).
  sf_street_tree    inaltimea in 6-8 m; coroana rotunda O 4-5 m pe X si pe Z, centrata pe
                    trunchi (0,3 m); trunchiul DREPT (intre 0,3 si 2,0 m nimic la peste 0,45 m
                    de axa); baza centrata si pe sol.
  sf_hydrangea(_blue)  un singur nod `Hydrangea`, 0,8-1,2 m inalta, cel mult 1,4 m lata,
                    centrata, pe sol; culorile in proportia ceruta: roz (31) > albastru (11) pe
                    varianta roz, invers pe `_blue`, frunze (21) pe amandoua.
  sf_front_garden   un nod `Garden_Body`; amprenta EXACTA 7,0 x 3,0 (X +-3,5, Z +-1,5, +-0,01),
                    pe sol, nimic peste 1,2 m; gardul viu (sloturile 21/12) de cel putin 0,55 m
                    pe latura de strada (Z < -1,0, Godot -Z = strada) si pe capatul -X pana la
                    casa (X < -2,9, Z > +0,5); jardiniera (9), florile (31) si bordura de
                    strada (19, Z < -1,2) exista.
"""
import json
import os
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_sf_bridge import (_accessor_slots, _roots, _write_glb, load, poke,  # noqa: E402
                               poke_all, verts)
from verify_glb import load_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODELS = os.path.join(ROOT, "assets", "models", "sanfrancisco")
PIECES = {
    "sf_cypress_a": "plants/sf_cypress_a.glb",
    "sf_cypress_b": "plants/sf_cypress_b.glb",
    "sf_cypress_c": "plants/sf_cypress_c.glb",
    "sf_street_tree": "plants/sf_street_tree.glb",
    "sf_hydrangea": "plants/sf_hydrangea.glb",
    "sf_hydrangea_blue": "plants/sf_hydrangea_blue.glb",
    "sf_front_garden": "props/sf_front_garden.glb",
}
CYP = ("sf_cypress_a", "sf_cypress_b", "sf_cypress_c")
HYD = ("sf_hydrangea", "sf_hydrangea_blue")
# v2 (16 nov 2026, verdictul coordonatorului: v1 citea pin niwaki): arbore de polite mai lat
# decat inalt. Inaltimea pe toate nodurile, latimea pe masa `Cypress_Crown`.
# v3 (acelasi zi: politele subtiri pe crengi goale citeau salcam): coroana trebuie sa fie MASA.
# `fill` = cat din dreptunghiul coroanei (vazut din lateral) e acoperit de frunzis + crengi;
# `depth` = intinderea masei `Cypress_Crown` pe Z (adancimea vazuta din capatul din vant).
CYP_SPEC = {"sf_cypress_a": dict(h=(7.0, 9.0), w=(11.0, 13.0), ratio=0.75, fill=0.55, depth=6.5),
            "sf_cypress_b": dict(h=(7.0, 9.0), w=(11.0, 13.0), ratio=0.75, fill=0.55, depth=6.5),
            "sf_cypress_c": dict(h=(6.5, 8.0), w=(9.0, 10.0), ratio=None, fill=0.50, depth=5.5)}
FOLIAGE = ("Cypress_Crown", "Cypress_Core", "Cypress_Leaves")
CELL = 0.05


def side_fill(nodes):
    """Umplerea siluetei laterale: toate triunghiurile (frunzis + trunchi + crengi) proiectate
    ortografic pe planul XY (privind de-a lungul lui Z), rasterizate la 5 cm; se numara
    celulele acoperite din dreptunghiul coroanei = intinderea frunzisului pe X si pe Y (de la
    cel mai jos frunzis in sus). Cardurile intra si ele, iar masa lor e `Cypress_Crown`."""
    import numpy as np
    fol = [p for n in FOLIAGE for p in nodes[n]["verts"]]
    x0, x1 = min(p[0] for p in fol), max(p[0] for p in fol)
    y0, y1 = min(p[1] for p in fol), max(p[1] for p in fol)
    nx, ny = int((x1 - x0) / CELL) + 1, int((y1 - y0) / CELL) + 1
    grid = np.zeros((ny, nx), dtype=bool)
    for d in nodes.values():
        V = np.array(d["verts"], dtype=np.float64)
        if len(V) == 0:
            continue
        P = np.stack([(V[:, 0] - x0) / CELL, (V[:, 1] - y0) / CELL], axis=1)
        for (i, j, k) in d["tris"]:
            a, b, c = P[i], P[j], P[k]
            area = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
            if abs(area) < 1e-9:
                continue
            lo_x = max(int(np.floor(min(a[0], b[0], c[0]))), 0)
            hi_x = min(int(np.ceil(max(a[0], b[0], c[0]))), nx - 1)
            lo_y = max(int(np.floor(min(a[1], b[1], c[1]))), 0)
            hi_y = min(int(np.ceil(max(a[1], b[1], c[1]))), ny - 1)
            if lo_x > hi_x or lo_y > hi_y:
                continue
            gx, gy = np.meshgrid(np.arange(lo_x, hi_x + 1) + 0.5, np.arange(lo_y, hi_y + 1) + 0.5)
            w0 = (b[0] - a[0]) * (gy - a[1]) - (b[1] - a[1]) * (gx - a[0])
            w1 = (c[0] - b[0]) * (gy - b[1]) - (c[1] - b[1]) * (gx - b[0])
            w2 = (a[0] - c[0]) * (gy - c[1]) - (a[1] - c[1]) * (gx - c[0])
            if area > 0:
                inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
            else:
                inside = (w0 <= 0) & (w1 <= 0) & (w2 <= 0)
            grid[lo_y:hi_y + 1, lo_x:hi_x + 1] |= inside
    return float(grid.mean())
NODES = {k: ["Cypress_Trunk", "Cypress_Crown", "Cypress_Core", "Cypress_Leaves"] for k in CYP}
NODES["sf_street_tree"] = ["StreetTree_Trunk", "StreetTree_Crown", "StreetTree_Core",
                           "StreetTree_Leaves"]
NODES["sf_hydrangea"] = ["Hydrangea"]
NODES["sf_hydrangea_blue"] = ["Hydrangea"]
NODES["sf_front_garden"] = ["Garden_Body"]


def _box(ps):
    return [(min(p[i] for p in ps), max(p[i] for p in ps)) for i in range(3)]


def _slots(d):
    """Slotul fiecarui varf (UV colapsat pe centrul slotului)."""
    return [int(uv[0] * 32) for uv in d["uv"]]


def _roots_clean(bad, g):
    for n in _roots(g):
        if any(abs(a - b) > 1e-5 for a, b in zip(n.get("scale", [1, 1, 1]), [1, 1, 1])) \
                or any(abs(a - b) > 1e-5 for a, b in zip(n.get("rotation", [0, 0, 0, 1]), [0, 0, 0, 1])) \
                or any(abs(a) > 1e-5 for a in n.get("translation", [0, 0, 0])):
            bad.append("(radacina) %s are scala/rotatie/translatie" % n.get("name"))


def _base(bad, trunk, tol=0.25):
    low = [p for p in trunk if p[1] < 0.3]
    if not low:
        bad.append("(baza) niciun varf de trunchi sub 0,3 m")
        return
    cx = sum(p[0] for p in low) / len(low)
    cz = sum(p[2] for p in low) / len(low)
    if abs(cx) > tol or abs(cz) > tol:
        bad.append("(baza) baza trunchiului la (%.2f, %.2f), nu pe origine (+-%.2f)" % (cx, cz, tol))


def check(key, path, report=True):
    g, _blob, nodes = load(path)
    bad = []
    _roots_clean(bad, g)
    if sorted(nodes) != sorted(NODES[key]):
        bad.append("(noduri) %s, contract %s" % (sorted(nodes), sorted(NODES[key])))
    ps = verts(nodes)
    b = _box(ps)
    (x0, x1), (y0, y1), (z0, z1) = b
    info = ""
    if abs(y0) > 0.005:
        bad.append("(sol) min Y = %.3f, nu 0" % y0)
    if key in CYP and not any(line.startswith("(noduri)") for line in bad):
        sp = CYP_SPEC[key]
        crown = nodes["Cypress_Crown"]["verts"]
        leaves = nodes["Cypress_Leaves"]["verts"]
        trunk = nodes["Cypress_Trunk"]["verts"]
        cb = _box(crown)
        lb = _box(leaves)
        cw = cb[0][1] - cb[0][0]
        lw = lb[0][1] - lb[0][0]
        cxm = sum(p[0] for p in crown) / len(crown)
        ratio = y1 / cw
        if not sp["h"][0] <= y1 <= sp["h"][1]:
            bad.append("(inaltime) %.2f m, contract %.1f-%.1f" % ((y1,) + sp["h"]))
        if not sp["w"][0] <= cw <= sp["w"][1]:
            bad.append("(latime) coroana %.2f m pe X, contract %.1f-%.1f" % ((cw,) + sp["w"]))
        if lw > sp["w"][1] + 1.0:
            bad.append("(latime) cardurile %.2f m pe X, cel mult %.1f" % (lw, sp["w"][1] + 1.0))
        if sp["ratio"] is not None and ratio > sp["ratio"]:
            bad.append("(proportie) inaltime / latime = %.2f, cel mult %.2f" % (ratio, sp["ratio"]))
        if cxm < 2.5:
            bad.append("(aplecare) centrul coroanei la X %.2f m, cel putin +2,5 (spre +X)" % cxm)
        top = [p for p in crown if p[1] >= cb[1][1] - 1.2]
        over = max(p[0] for p in top)
        if over < 3.0:
            bad.append("(surplomba) polita de sus ajunge doar la X %+.2f, cel putin +3,0" % over)
        fill = side_fill(nodes)
        if fill < sp["fill"]:
            bad.append("(umplere) silueta laterala %.0f %% plina, cel putin %.0f %%"
                       % (fill * 100, sp["fill"] * 100))
        depth = cb[2][1] - cb[2][0]
        if depth < sp["depth"]:
            bad.append("(adancime) coroana %.2f m pe Z, cel putin %.1f" % (depth, sp["depth"]))
        ring = [p for p in trunk if 0.4 <= p[1] <= 0.6]
        dia = min(max(p[0] for p in ring) - min(p[0] for p in ring),
                  max(p[2] for p in ring) - min(p[2] for p in ring)) if ring else 0.0
        if dia < 1.6:
            bad.append("(baza) diametrul la +0,5 m e %.2f m, cel putin 1,6" % dia)
        _base(bad, trunk)
        info = ("inalt %.2f  coroana X %.2f (carduri %.2f) Z %.2f  h/l %.2f  centru X %+.2f  "
                "polita de sus pana la X %+.2f  baza O %.2f  umplere %.0f %%" % (
                    y1, cw, lw, cb[2][1] - cb[2][0], ratio, cxm, over, dia, fill * 100))
    elif key == "sf_street_tree" and not any(line.startswith("(noduri)") for line in bad):
        crown = nodes["StreetTree_Crown"]["verts"]
        cb = _box(crown)
        cw, cd = cb[0][1] - cb[0][0], cb[2][1] - cb[2][0]
        cxm = sum(p[0] for p in crown) / len(crown)
        czm = sum(p[2] for p in crown) / len(crown)
        if not 6.0 <= y1 <= 8.0:
            bad.append("(inaltime) %.2f m, contract 6-8" % y1)
        if not (4.0 <= cw <= 5.0 and 4.0 <= cd <= 5.0):
            bad.append("(coroana) %.2f x %.2f m, contract O 4-5" % (cw, cd))
        if abs(cxm) > 0.3 or abs(czm) > 0.3:
            bad.append("(coroana) centrul la (%.2f, %.2f), nu pe trunchi" % (cxm, czm))
        tr = nodes["StreetTree_Trunk"]["verts"]
        off = [p for p in tr if 0.3 < p[1] < 2.0 and (p[0] ** 2 + p[2] ** 2) ** 0.5 > 0.45]
        if off:
            bad.append("(trunchi) %d varfuri la peste 0,45 m de axa intre 0,3 si 2,0 m" % len(off))
        _base(bad, tr, tol=0.1)
        info = "inalt %.2f  coroana %.2f x %.2f  centru (%+.2f, %+.2f)" % (y1, cw, cd, cxm, czm)
    elif key in HYD and not any(line.startswith("(noduri)") for line in bad):
        d = nodes["Hydrangea"]
        if not 0.8 <= y1 <= 1.2:
            bad.append("(inaltime) %.2f m, contract 0,8-1,2" % y1)
        if x1 - x0 > 1.4 or z1 - z0 > 1.4:
            bad.append("(latime) %.2f x %.2f m, cel mult 1,4" % (x1 - x0, z1 - z0))
        if abs(x0 + x1) * 0.5 > 0.05 or abs(z0 + z1) * 0.5 > 0.05:
            bad.append("(centru) cutia nu e centrata pe origine")
        sl = _slots(d)
        tris = [sl[t[0]] for t in d["tris"]]
        pink, blue, leaf = tris.count(31), tris.count(11), tris.count(21)
        want_pink = key == "sf_hydrangea"
        if leaf == 0 or (pink > blue) != want_pink or min(pink, blue) == 0:
            bad.append("(culori) roz %d / albastru %d / frunze %d triunghiuri, varianta %s"
                       % (pink, blue, leaf, "roz" if want_pink else "albastra"))
        info = "inalta %.2f  %.2f x %.2f  roz %d / albastru %d / frunze %d tri" % (
            y1, x1 - x0, z1 - z0, pink, blue, leaf)
    elif key == "sf_front_garden" and not any(line.startswith("(noduri)") for line in bad):
        d = nodes["Garden_Body"]
        for name, got, want in (("X-", x0, -3.5), ("X+", x1, 3.5), ("Z-", z0, -1.5), ("Z+", z1, 1.5)):
            if abs(got - want) > 0.01:
                bad.append("(amprenta) %s = %.3f, contract %.2f" % (name, got, want))
        if y1 > 1.2:
            bad.append("(inaltime) %.2f m, cel mult 1,2" % y1)
        sl = _slots(d)
        vs = d["verts"]
        hedge = [p for p, s in zip(vs, sl) if s in (21, 12) and p[1] >= 0.55]
        if not any(p[2] < -1.0 for p in hedge):
            bad.append("(gard viu) nimic de 0,55 m pe latura de strada (Z < -1,0)")
        if not any(p[0] < -2.9 and p[2] > 0.5 for p in hedge):
            bad.append("(gard viu) nimic de 0,55 m pe capatul -X spre casa")
        if 9 not in sl:
            bad.append("(jardiniera) lipseste lemnul (slotul 9)")
        if 31 not in sl:
            bad.append("(jardiniera) lipsesc florile (slotul 31)")
        if not any(s == 19 and p[2] < -1.2 for p, s in zip(vs, sl)):
            bad.append("(bordura) lipseste pe latura de strada (slotul 19, Z < -1,2)")
        info = "%.2f x %.2f x %.2f" % (x1 - x0, y1 - y0, z1 - z0)
    if report:
        print("%-18s X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f  %s  %s"
              % (key, x0, x1, y0, y1, z0, z1, info, "OK" if not bad else "PICAT"))
        for line in bad:
            print("   !! " + line)
    return bad


def recolor(g, blob, node_name, src, dst):
    """Muta UV-urile slotului `src` pe slotul `dst` (sabotajul de culoare)."""
    n = 0
    for acc, base, stride, k in _accessor_slots(g, node_name, "TEXCOORD_0"):
        for i in range(acc["count"]):
            u, v = struct.unpack_from("<ff", blob, base + i * stride)
            if int(u * 32) == src:
                struct.pack_into("<ff", blob, base + i * stride, (dst + 0.5) / 32.0, v)
                n += 1
    return n > 0


def thin_foliage(g, blob, k=0.35):
    """Sabotajul de umplere: frunzisul (masa, miezul, cardurile) strans pe Y spre mijlocul lui
    la `k`, cu cate un varf de card lasat sus si jos, ca dreptunghiul coroanei sa ramana acelasi."""
    ys = []
    for n in FOLIAGE:
        poke_all(g, blob, n, lambda p: ys.append(p[1]) and False, lambda p: p)
    lo, hi = min(ys), max(ys)
    mid = (lo + hi) * 0.5
    for n in FOLIAGE:
        poke_all(g, blob, n, lambda p: True, lambda p: (p[0], mid + (p[1] - mid) * k, p[2]))
    poke(g, blob, "Cypress_Leaves", lambda p: True, lambda p: (p[0], hi, p[2]))
    return poke(g, blob, "Cypress_Leaves", lambda p: p[1] < hi - 0.01, lambda p: (p[0], lo, p[2]))


def sabotages(key):
    first = NODES[key][0]

    def rename(g, blob):
        next(n for n in g["nodes"] if "mesh" in n)["name"] = "Altceva"

    def scale(g, blob):
        _roots(g)[0]["scale"] = [1.05, 1.0, 1.0]

    out = [("nod redenumit", "noduri", rename), ("radacina scalata 1,05", "radacina", scale),
           ("un varf coborat la -0,2 m", "sol",
            lambda g, b: poke(g, b, NODES[key][-1], lambda p: True,
                              lambda p: (p[0], -0.2, p[2])))]
    if key in CYP:
        out += [
            ("coroana mutata cu 2 m spre -X (aplecare inversa)", "aplecare",
             lambda g, b: poke_all(g, b, "Cypress_Crown", lambda p: True,
                                   lambda p: (p[0] - 2.0, p[1], p[2])) > 0),
            ("un varf de coroana urcat la 10,5 m", "inaltime",
             lambda g, b: poke(g, b, "Cypress_Crown", lambda p: p[1] > 5.0,
                               lambda p: (p[0], 10.5, p[2]))),
            ("un varf de coroana scos la X = +12 m", "latime",
             lambda g, b: poke(g, b, "Cypress_Crown", lambda p: p[0] > 3.0,
                               lambda p: (12.0, p[1], p[2]))),
            ("polita de sus trasa 6 m spre -X", "surplomba",
             lambda g, b: poke_all(g, b, "Cypress_Crown", lambda p: p[1] > 5.6,
                                   lambda p: (p[0] - 6.0, p[1], p[2])) > 0),
            ("trunchiul subtiat la 30 % intre +0,35 si +0,65 m", "baza",
             lambda g, b: poke_all(g, b, "Cypress_Trunk", lambda p: 0.35 < p[1] < 0.65,
                                   lambda p: (p[0] * 0.3, p[1], p[2] * 0.3)) > 0),
            ("baza trunchiului mutata 0,6 m pe X", "baza",
             lambda g, b: poke_all(g, b, "Cypress_Trunk", lambda p: p[1] < 0.3,
                                   lambda p: (p[0] + 0.6, p[1], p[2])) > 0),
        ]
        out += [
            ("frunzisul turtit pe Y la 35 % (polite subtiri), capetele pastrate", "umplere",
             lambda g, b: thin_foliage(g, b)),
            ("coroana stransa pe Z la 50 % (turn de discuri din capat)", "adancime",
             lambda g, b: poke_all(g, b, "Cypress_Crown", lambda p: True,
                                   lambda p: (p[0], p[1], p[2] * 0.5)) > 0),
        ]
        if CYP_SPEC[key]["ratio"] is not None:
            out.append(("coroana stransa pe X la 60 % (arbore inalt si ingust)", "proportie",
                        lambda g, b: poke_all(g, b, "Cypress_Crown", lambda p: True,
                                              lambda p: (p[0] * 0.6, p[1], p[2])) > 0))
    elif key == "sf_street_tree":
        out += [
            ("un varf de coroana scos la +1 m pe X", "coroana",
             lambda g, b: poke(g, b, "StreetTree_Crown", lambda p: p[0] > 2.0,
                               lambda p: (p[0] + 1.0, p[1], p[2]))),
            ("trunchiul indoit (un varf la 0,8 m de axa, la 1 m)", "trunchi",
             lambda g, b: poke(g, b, "StreetTree_Trunk", lambda p: 0.8 < p[1] < 1.2,
                               lambda p: (0.8, p[1], p[2]))),
            ("un varf de coroana urcat la 8,5 m", "inaltime",
             lambda g, b: poke(g, b, "StreetTree_Crown", lambda p: p[1] > 6.0,
                               lambda p: (p[0], 8.5, p[2]))),
            ("baza trunchiului mutata 0,3 m pe Z", "baza",
             lambda g, b: poke_all(g, b, "StreetTree_Trunk", lambda p: p[1] < 0.3,
                                   lambda p: (p[0], p[1], p[2] + 0.3)) > 0),
        ]
    elif key in HYD:
        maj, mino = (31, 11) if key == "sf_hydrangea" else (11, 31)
        out += [
            ("un varf urcat la 1,4 m", "inaltime",
             lambda g, b: poke(g, b, "Hydrangea", lambda p: p[1] > 0.8,
                               lambda p: (p[0], 1.4, p[2]))),
            ("culoarea majoritara mutata pe cea minoritara", "culori",
             lambda g, b, a=maj, c=mino: recolor(g, b, "Hydrangea", a, c)),
            ("un varf scos la 1 m lateral", "latime",
             lambda g, b: poke(g, b, "Hydrangea", lambda p: p[0] > 0.5,
                               lambda p: (1.0, p[1], p[2]))),
        ]
    elif key == "sf_front_garden":
        out += [
            ("un varf al bordurii scos cu 10 cm pe X", "amprenta",
             lambda g, b: poke(g, b, "Garden_Body", lambda p: p[0] > 3.49,
                               lambda p: (p[0] + 0.1, p[1], p[2]))),
            ("gardul viu de pe strada coborat la 0,3 m", "gard viu",
             lambda g, b: poke_all(g, b, "Garden_Body", lambda p: p[2] < -1.0 and p[1] > 0.4,
                                   lambda p: (p[0], 0.3, p[2])) > 0),
            ("un varf urcat la 1,5 m", "inaltime",
             lambda g, b: poke(g, b, "Garden_Body", lambda p: p[1] > 0.5,
                               lambda p: (p[0], 1.5, p[2]))),
            ("lemnul jardinierei mutat pe beton", "jardiniera",
             lambda g, b: recolor(g, b, "Garden_Body", 9, 8)),
            ("bordura mutata pe beton", "bordura",
             lambda g, b: recolor(g, b, "Garden_Body", 19, 8)),
        ]
    return out


def selftest(keys):
    ok = True
    tmp = tempfile.mkdtemp(prefix="sfp_sabotaj_")
    for key in keys:
        path = os.path.join(MODELS, *PIECES[key].split("/"))
        print("== selftest %s" % key)
        for label, want, fn in sabotages(key):
            g, blob = load_glb(path)[:2]
            g = json.loads(json.dumps(g))
            blob = bytearray(blob)
            done = fn(g, blob)
            p = os.path.join(tmp, "sabotaj.glb")
            _write_glb(p, g, blob)
            bad = check(key, p, report=False)
            hit = sorted({line[1:line.index(")")] for line in bad})
            caught = want in hit and done is not False
            print("   %-52s -> pica pe %-20s %s" % (label, ",".join(hit) or "NIMIC",
                                                    "ok" if caught else "!! ASTEPTAT (%s)" % want))
            ok &= caught
            os.remove(p)
        orig = check(key, path, report=False)
        print("   %-52s -> %s" % ("originalul", "trece" if not orig else "!! PICA: %s" % orig))
        ok &= not orig
    os.rmdir(tmp)
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    args = sys.argv[1:]
    if args and args[0] == "--selftest":
        sys.exit(0 if selftest(args[1:] or list(PIECES)) else 1)
    keys = args or list(PIECES)
    failed = [k for k in keys if check(k, os.path.join(MODELS, *PIECES[k].split("/")))]
    print("GARDA VEGETATIE SF: %s" % ("OK (%d piese)" % len(keys) if not failed
                                      else "ESUAT: %s" % ", ".join(failed)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
