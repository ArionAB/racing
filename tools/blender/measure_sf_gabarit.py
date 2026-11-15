"""Garda de gabarit a pieselor San Francisco care au CONTRACT FIZIC in joc.

    python tools/blender/measure_sf_gabarit.py            # toate piesele
    python tools/blender/measure_sf_gabarit.py --selftest # dovedeste ca garda pica pe sabotaj

Citeste GLB-urile direct (coordonate Godot), ca `measure_sf_bridge.py` (de unde ia
cititorul si unealta de sabotaj). `verify_glb.py` masoara sloturi, AO si origine; ce
urmeaza e ce citeste FIZICA jocului din fisier si verify nu vede:

  cable_car         AABB EXACT 2,50 x 3,20 x 8,50 (+-0,02), min Y 0, centrat in XZ, un singur
                    nod `CableCar_Body`. `BusHazard` isi masoara cutia de coliziune pe AABB-ul
                    modelului, iar contactele de la pasii 1c/5/2b sunt masurate pe cutia asta: un
                    calator iesit cu 20 cm lateste corpul fizic cu 40. Roti la sol la ambele boghiuri.
  sf_median_truck   incape in 2,6 x 3,2 x 10,0 de la Y 0 (cutia hazardului, citita si de AI) si o
                    umple (>= 2,5 x 3,1 x 9,9); un nod `MedianTruck_Body`. Tunelul liber pe ax:
                    in |X| < 0,45 nimic sub Y 0,70 si nimic intre 0,80 si 1,0 (pe acolo trec baza
                    si capul blocului de 0,60 x 0,95). Banda 0,70..0,80 e a ROLELOR: ele prind
                    gatul blocului (profilul in T), deci acolo geometria e voita.
  sf_median_block   EXACT 3,00 x 0,95 x 0,60 (+-0,01), min Y 0, centrat; un nod `MedianBlock`;
                    fetele laterale ale bazei VERTICALE (profilul in panta arunca masinile peste
                    bariera): talpa si umarul la |Z| 0,30, niciun varf de fata tras spre ax.
  sf_row_b_canted, sf_row_b_canted_m (oglindita)
                    X +-3,5, fatada la Z -6,0 cu bovindoul pana la -6,9, spatele la +6,0, Y de la
                    -2,4 la cel mult +12,6; exact nodurile `Row_Wall` si `Row_Trim`; nimic nu
                    iese din planul fatadei sub +3,3 (scara e in nisa, nu pe trotuar).

Radacinile fara scala/rotatie/translatie la toate (memoria scala-glb-neaplicata-la-radacina).
"""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_sf_bridge import _roots, _write_glb, load, poke, verts  # noqa: E402
from verify_glb import load_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODELS = os.path.join(ROOT, "assets", "models", "sanfrancisco")
PIECES = {
    "cable_car": "vehicles/cable_car.glb",
    "sf_median_truck": "vehicles/sf_median_truck.glb",
    "sf_median_block": "props/sf_median_block.glb",
    "sf_row_b_canted": "buildings/sf_row_b_canted.glb",
    "sf_row_b_canted_m": "buildings/sf_row_b_canted_m.glb",
}
# Variantele `_m` (oglindite de-adevaratelea, pentru MultiMesh-ul din CityFill: o instanta cu
# scale.x = -1 iese pe dos acolo) au aceeasi amprenta, cu garajul pe -X.
ROW_KEYS = ("sf_row_b_canted", "sf_row_b_canted_m")


def _box(ps):
    return [(min(p[i] for p in ps), max(p[i] for p in ps)) for i in range(3)]


def _near(v, want, tol):
    return abs(v - want) <= tol


def _exact_box(bad, tag, b, half_x, top, half_z, tol):
    (x0, x1), (y0, y1), (z0, z1) = b
    for name, got, want in (("X-", x0, -half_x), ("X+", x1, half_x), ("Y-", y0, 0.0), ("Y+", y1, top),
                            ("Z-", z0, -half_z), ("Z+", z1, half_z)):
        if not _near(got, want, tol):
            bad.append("(%s) %s = %.3f, contract %.3f +-%.2f" % (tag, name, got, want, tol))


def _roots_clean(bad, g):
    for n in _roots(g):
        if any(abs(a - b) > 1e-5 for a, b in zip(n.get("scale", [1, 1, 1]), [1, 1, 1])) \
                or any(abs(a - b) > 1e-5 for a, b in zip(n.get("rotation", [0, 0, 0, 1]), [0, 0, 0, 1])) \
                or any(abs(a) > 1e-5 for a in n.get("translation", [0, 0, 0])):
            bad.append("(radacina) %s are scala/rotatie/translatie" % n.get("name"))


def _names(bad, nodes, want):
    if sorted(nodes) != sorted(want):
        bad.append("(noduri) %s, contract %s" % (sorted(nodes), sorted(want)))


def check(key, path, report=True):
    g, _blob, nodes = load(path)
    ps = verts(nodes)
    b = _box(ps)
    bad = []
    _roots_clean(bad, g)
    if key == "cable_car":
        _names(bad, nodes, ["CableCar_Body"])
        _exact_box(bad, "aabb", b, 1.25, 3.20, 4.25, 0.02)
        for sgn, nm in ((-1, "fata"), (1, "spate")):
            if not any(p[1] < 0.005 and sgn * p[2] > 1.5 for p in ps):
                bad.append("(roti) boghiul din %s nu atinge y = 0" % nm)
    elif key == "sf_median_truck":
        _names(bad, nodes, ["MedianTruck_Body"])
        (x0, x1), (y0, y1), (z0, z1) = b
        if x0 < -1.3005 or x1 > 1.3005 or y0 < -0.0005 or y1 > 3.2005 or z0 < -5.0005 or z1 > 5.0005:
            bad.append("(cutie) iese din 2,6 x 3,2 x 10,0: X %.3f..%.3f Y %.3f..%.3f Z %.3f..%.3f"
                       % (x0, x1, y0, y1, z0, z1))
        if x1 - x0 < 2.5 or y1 < 3.1 or z1 - z0 < 9.9 or y0 > 0.005:
            bad.append("(umplere) nu umple cutia: %.2f x %.2f x %.2f, min Y %.3f"
                       % (x1 - x0, y1 - y0, z1 - z0, y0))
        inside = [p for p in ps if abs(p[0]) < 0.45 and (p[1] < 0.70 - 1e-3 or 0.80 + 1e-3 < p[1] < 1.0)]
        if inside:
            bad.append("(tunel) %d varfuri in golul tunelului (|X| < 0,45, in afara benzii rolelor), ex. %s"
                       % (len(inside), tuple(round(v, 3) for v in inside[0])))
    elif key == "sf_median_block":
        _names(bad, nodes, ["MedianBlock"])
        _exact_box(bad, "aabb", b, 1.50, 0.95, 0.30, 0.01)
        # Fata laterala a bazei: varfuri la |Z| 0,30 jos (Y 0) si sus (Y >= 0,60), si niciun varf
        # de fata laterala (dincolo de cep/urechi, |Z| > 0,24) tras spre ax sub +0,66.
        slope = [p for p in ps if p[1] < 0.66 and 0.24 < abs(p[2]) < 0.295]
        foot = any(p[1] < 0.005 and abs(p[2]) > 0.295 for p in ps)
        shoulder = any(0.60 < p[1] < 0.66 and abs(p[2]) > 0.295 for p in ps)
        if slope or not foot or not shoulder:
            bad.append("(profil) fata laterala a bazei nu e verticala de la 0 la +0,65 "
                       "(%d varfuri trase spre ax; talpa la 0,30: %s; umarul la 0,30: %s)"
                       % (len(slope), foot, shoulder))
    elif key in ROW_KEYS:
        _names(bad, nodes, ["Row_Wall", "Row_Trim"])
        (x0, x1), (y0, y1), (z0, z1) = b
        for name, got, want, tol in (("X-", x0, -3.5, 0.01), ("X+", x1, 3.5, 0.01), ("Y-", y0, -2.4, 0.01),
                                     ("Z- (bovindou)", z0, -6.9, 0.02), ("Z+ (spate)", z1, 6.0, 0.02)):
            if not _near(got, want, tol):
                bad.append("(amprenta) %s = %.3f, contract %.3f" % (name, got, want))
        if y1 > 12.6 + 0.01:
            bad.append("(amprenta) Y+ = %.3f, cel mult 12,6" % y1)
        # sub +3,3 doar relief plat (brau, pilastrii nisei, rama garajului): cel mult 8 cm
        low = [p for p in ps if p[1] < 3.3 - 1e-3 and p[2] < -6.08]
        if low:
            bad.append("(fatada) %d varfuri ies din planul fatadei sub +3,3 (max %.2f m), ex. %s"
                       % (len(low), max(-6.0 - p[2] for p in low), tuple(round(v, 3) for v in low[0])))
    if report:
        (x0, x1), (y0, y1), (z0, z1) = b
        print("%-18s X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f  noduri %s  %s"
              % (key, x0, x1, y0, y1, z0, z1, ",".join(sorted(nodes)), "OK" if not bad else "PICAT"))
        for line in bad:
            print("   !! " + line)
    return bad


def sabotages(key):
    def node0(g):
        return next(n["name"] for n in g["nodes"] if "mesh" in n)

    def rename(g, blob):
        next(n for n in g["nodes"] if "mesh" in n)["name"] = "Altceva"

    def scale(g, blob):
        _roots(g)[0]["scale"] = [1.05, 1.0, 1.0]

    out = [("nod redenumit", "noduri", rename), ("radacina scalata 1,05", "radacina", scale)]
    if key == "cable_car":
        out += [
            ("un varf iesit lateral cu 20 cm (brat de calator)", "aabb",
             lambda g, b: poke(g, b, node0(g), lambda p: p[0] > 1.2, lambda p: (p[0] + 0.2, p[1], p[2]))),
            ("un varf peste acoperis cu 10 cm", "aabb",
             lambda g, b: poke(g, b, node0(g), lambda p: p[1] > 3.15, lambda p: (p[0], p[1] + 0.1, p[2]))),
        ]
    elif key == "sf_median_truck":
        out += [
            ("un varf iesit lateral cu 10 cm", "cutie",
             lambda g, b: poke(g, b, node0(g), lambda p: p[0] > 1.25, lambda p: (p[0] + 0.1, p[1], p[2]))),
            ("un varf coborat in tunel", "tunel",
             lambda g, b: poke(g, b, node0(g), lambda p: abs(p[0]) < 0.3 and p[1] > 1.1,
                               lambda p: (0.0, 0.5, p[2]))),
        ]
    elif key == "sf_median_block":
        out += [
            ("un varf de baza tras spre ax (fata in panta)", "profil",
             lambda g, b: poke(g, b, node0(g), lambda p: p[1] < 0.01 and abs(p[2]) > 0.29,
                               lambda p: (p[0], p[1], p[2] * 0.9))),
            ("capul inaltat cu 5 cm", "aabb",
             lambda g, b: poke(g, b, node0(g), lambda p: p[1] > 0.94, lambda p: (p[0], p[1] + 0.05, p[2]))),
        ]
    elif key in ROW_KEYS:
        out += [
            ("o treapta scoasa pe trotuar (0,5 m in fata fatadei, sub +3,3)", "fatada",
             lambda g, b: poke(g, b, "Row_Trim", lambda p: p[1] < 0.0 and p[2] < -5.9,
                               lambda p: (p[0], p[1], -6.5))),
            ("streasina iesita lateral cu 10 cm", "amprenta",
             lambda g, b: poke(g, b, "Row_Trim", lambda p: p[0] > 3.49, lambda p: (p[0] + 0.1, p[1], p[2]))),
        ]
    return out


def selftest(keys):
    ok = True
    tmp = tempfile.mkdtemp(prefix="sfg_sabotaj_")
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
            print("   %-58s -> pica pe %-22s %s" % (label, ",".join(hit) or "NIMIC",
                                                    "ok" if caught else "!! ASTEPTAT (%s)" % want))
            ok &= caught
            os.remove(p)
        orig = check(key, path, report=False)
        print("   %-58s -> %s" % ("originalul", "trece" if not orig else "!! PICA: %s" % orig))
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
    print("GARDA DE GABARIT SF: %s" % ("OK (%d piese)" % len(keys) if not failed else "ESUAT: %s" % ", ".join(failed)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
