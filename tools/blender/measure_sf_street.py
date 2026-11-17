"""Garda mobilierului de strada San Francisco (valul 2): ce citeste JOCUL din fisiere si
verify_glb.py nu vede.

    python tools/blender/measure_sf_street.py            # toate piesele
    python tools/blender/measure_sf_street.py --selftest # dovedeste ca garda pica pe sabotaj

Citeste GLB-urile direct, in coordonate Godot (cititorul si unealta de sabotaj vin din
`measure_sf_bridge.py`, doar citite). Contractul: docs/asset_briefs/sanfrancisco_inventory.md
§5.3 si comanda valului 2.

  sf_parked_{sedan,wagon,van}
        un nod (`ParkedSedan` / `ParkedWagon` / `ParkedVan`); AABB EXACT 1,90 (X) x 3,70 (Z)
        +-0,02, Y de la 0, varful = inaltimea placeholderului din scenes/props/sf_parked_car.gd
        (1,33 / 1,38 / 1,61, +-0,02): `BumpProp` isi ia cutia de coliziune din AABB, iar
        contactele de la pasul 6 sunt masurate pe cutiile astea. Botul pe -Z: farurile (slot 22)
        stau la Z < -1,6 si stopurile (slot 7) la Z > +1,6. Vopseaua pe slotul 11 si DOAR
        caroseria pe el: >= 30 % din triunghiuri pe 11 (jocul il recoloreaza).
  sf_signal_mast (v2, capul supradimensionat)
        un nod `SignalMast`; sub +8,0 nimic mai departe de 1,0 m de axa stalpului (doar stalpul
        coboara: masinile zboara pana la +4,0 peste creasta); bratul ajunge la x <= -7,9 si are
        >= 0,30 m grosime; capul (sloturile 20/22/7/1/21 la |x + 7,2| <= 0,55, fara tija; fereastra |x + 7,2| <= 0,65 la masurare) cu
        fundul >= +8,0, inalt 2,2..2,6 si lat 0,9..1,1; pe AMBELE fete trei lentile colorate in
        ordinea rosu (7) / galben (1) / verde (21) de sus in jos; stalpul ⌀ 0,35 (+-0,02),
        masurat pe sectiunea de la +2,0.
  sf_street_lamp
        un nod `StreetLamp`; inalt 5,50 (+-0,03); stalpul ⌀ 0,25 (+-0,02) la +2,0; centrat.
  sf_street_props
        exact nodurile Hydrant, Mailbox, NewsBox, TrashBin, Cone (radacini); inaltimi 0,8 / 1,3 /
        1,1 / 1,0 / 0,7 (+-0,03), fiecare centrat in XZ (+-0,02) cu Y de la 0, <= 300 tri;
        hidrantul pe slotul 7; conul pe 7 cu banda alba 22 si FARA slotul 30.
  sf_bollard
        un nod `Bollard`, tot in cutia stalpului moale de joc 0,5 x 0,8 x 0,5 (|X|,|Z| <= 0,25,
        Y 0..0,8), atinge solul; doar sloturile 20 si 10; <= 200 tri.
  sf_crab_traps
        exact TrapStack, Crate, RopeCoil; fiecare <= 1,2 m pe orice axa, Y de la 0, centrat,
        <= 300 tri.
  sf_bench / sf_bike_rack
        un nod `Bench` / `BikeRack`; <= 2,0 m pe orice axa, Y de la 0, centrat, <= 400 tri.
La toate: nicio radacina cu scala/rotatie/translatie (memoria scala-glb-neaplicata-la-radacina),
niciun slot 14-16 sau 30.
"""
import json
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_sf_bridge import _roots, _write_glb, load, poke, poke_all, set_uv  # noqa: E402
from verify_glb import load_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODELS = os.path.join(ROOT, "assets", "models", "sanfrancisco")
PIECES = {
    "sf_parked_sedan": "vehicles/sf_parked_sedan.glb",
    "sf_parked_wagon": "vehicles/sf_parked_wagon.glb",
    "sf_parked_van": "vehicles/sf_parked_van.glb",
    "sf_signal_mast": "props/sf_signal_mast.glb",
    "sf_street_lamp": "props/sf_street_lamp.glb",
    "sf_street_props": "props/sf_street_props.glb",
    "sf_bollard": "props/sf_bollard.glb",
    "sf_crab_traps": "props/sf_crab_traps.glb",
    "sf_bench": "props/sf_bench.glb",
    "sf_bike_rack": "props/sf_bike_rack.glb",
}
CARS = {"sf_parked_sedan": ("ParkedSedan", 1.33), "sf_parked_wagon": ("ParkedWagon", 1.38),
        "sf_parked_van": ("ParkedVan", 1.61)}
PROPS_H = {"Hydrant": 0.8, "Mailbox": 1.3, "NewsBox": 1.1, "TrashBin": 1.0, "Cone": 0.7}
TRAPS = ("TrapStack", "Crate", "RopeCoil")
SINGLE = {"sf_signal_mast": "SignalMast", "sf_street_lamp": "StreetLamp", "sf_bollard": "Bollard",
          "sf_bench": "Bench", "sf_bike_rack": "BikeRack"}
FORBIDDEN = {14, 15, 16, 30}
LENS = (7, 1, 21)                     # rosu, galben (sand_mid), verde (tropical_green)
HEAD_SLOTS = (20, 22) + LENS


def _box(ps):
    return [(min(p[i] for p in ps), max(p[i] for p in ps)) for i in range(3)]


def _slots(d):
    return [int(math.floor(u[0] * 32)) for u in d["uv"]]


def _tri_slots(d):
    s = _slots(d)
    return [s[t[0]] for t in d["tris"]]


def _roots_clean(bad, g):
    for n in _roots(g):
        if any(abs(a - b) > 1e-5 for a, b in zip(n.get("scale", [1, 1, 1]), [1, 1, 1])) \
                or any(abs(a - b) > 1e-5 for a, b in zip(n.get("rotation", [0, 0, 0, 1]), [0, 0, 0, 1])) \
                or any(abs(a) > 1e-5 for a in n.get("translation", [0, 0, 0])):
            bad.append("(radacina) %s are scala/rotatie/translatie" % n.get("name"))


def _names(bad, nodes, want):
    if sorted(nodes) != sorted(want):
        bad.append("(noduri) %s, contract %s" % (sorted(nodes), sorted(want)))


def _forbidden(bad, nodes):
    for name, d in nodes.items():
        hit = sorted(set(_slots(d)) & FORBIDDEN)
        if hit:
            bad.append("(sloturi) %s foloseste sloturile interzise %s" % (name, hit))


def _section_diameter(d, y):
    """Diametrul sectiunii orizontale la cota y, langa axa (|r| < 1 m): muchiile
    triunghiurilor care taie planul, interpolate. Un trunchi de con are varfuri doar la capete,
    deci se masoara pe sectiune, nu pe varfuri."""
    ps = d["verts"]
    rmax = 0.0
    for t in d["tris"]:
        for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])):
            p, q = ps[a], ps[b]
            if (p[1] - y) * (q[1] - y) < 0:
                k = (y - p[1]) / (q[1] - p[1])
                x, z = p[0] + (q[0] - p[0]) * k, p[2] + (q[2] - p[2]) * k
                r = math.hypot(x, z)
                if r < 1.0:
                    rmax = max(rmax, r)
    return 2 * rmax


def _base_centred(bad, name, d, tol=0.02):
    (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
    if abs(y0) > 0.005:
        bad.append("(origine) %s: Y minim %.3f, nu 0" % (name, y0))
    if abs(x0 + x1) * 0.5 > tol or abs(z0 + z1) * 0.5 > tol:
        bad.append("(origine) %s: necentrat in XZ (%.3f, %.3f)" % (name, (x0 + x1) * 0.5, (z0 + z1) * 0.5))


def _tris(bad, name, d, cap):
    if len(d["tris"]) > cap:
        bad.append("(triunghiuri) %s are %d, plafon %d" % (name, len(d["tris"]), cap))


def check(key, path, report=True):
    g, _blob, nodes = load(path)
    bad = []
    _roots_clean(bad, g)
    _forbidden(bad, nodes)
    if key in CARS:
        node, top = CARS[key]
        _names(bad, nodes, [node])
        d = nodes.get(node) or next(iter(nodes.values()))
        (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
        for nm, got, want in (("X-", x0, -0.95), ("X+", x1, 0.95), ("Z-", z0, -1.85), ("Z+", z1, 1.85),
                              ("Y+", y1, top)):
            if abs(got - want) > 0.02:
                bad.append("(aabb) %s = %.3f, contract %.3f +-0,02" % (nm, got, want))
        if abs(y0) > 0.005:
            bad.append("(aabb) Y- = %.3f, contract 0" % y0)
        s = _slots(d)
        head = [p for p, k in zip(d["verts"], s) if k == 22]
        tail = [p for p, k in zip(d["verts"], s) if k == 7]
        if not head or not tail or max(p[2] for p in head) > -1.6 or min(p[2] for p in tail) < 1.6:
            bad.append("(bot) farurile (22) nu sunt toate la Z < -1,6 sau stopurile (7) la Z > 1,6: "
                       "botul nu e pe -Z")
        ts = _tri_slots(d)
        share = ts.count(11) / max(len(ts), 1)
        if share < 0.30:
            bad.append("(vopsea) doar %.0f %% din triunghiuri pe slotul 11" % (100 * share))
    elif key == "sf_signal_mast":
        _names(bad, nodes, ["SignalMast"])
        d = nodes.get("SignalMast") or next(iter(nodes.values()))
        ps = d["verts"]
        s = _slots(d)
        low = [p for p in ps if p[1] < 8.0 - 1e-3 and math.hypot(p[0], p[2]) > 1.0]
        if low:
            bad.append("(sub8) %d varfuri sub +8,0 la mai mult de 1,0 m de axa, ex. %s"
                       % (len(low), tuple(round(v, 2) for v in low[0])))
        if min(p[0] for p in ps) > -7.9:
            bad.append("(brat) bratul ajunge doar la x %.2f, contract -8,0" % min(p[0] for p in ps))
        # fereastra capului: |x - (-7,2)| <= 0,55, sloturile capului; tija de prindere (0,16 x 0,16
        # pe axa capului) nu e cap: leaga capul de brat
        def stem(p):
            return abs(p[0] + 7.2) <= 0.081 and abs(p[2]) <= 0.081
        # 0,65: incape un chenar prea lat, dar nu si capacul bratului (|dx| >= 0,68)
        head = [p for p, k in zip(ps, s) if abs(p[0] + 7.2) <= 0.65 and k in HEAD_SLOTS
                and not stem(p)]
        if not head:
            bad.append("(cap) niciun cap de semafor la x -7,2")
        else:
            lo, hi = min(p[1] for p in head), max(p[1] for p in head)
            w = max(p[0] for p in head) - min(p[0] for p in head)
            if lo < 8.0 - 1e-3:
                bad.append("(cap) fundul capului la +%.3f, sub +8,0" % lo)
            if not 2.2 <= hi - lo <= 2.6:
                bad.append("(cap) capul are %.3f m inaltime, contract 2,2..2,6" % (hi - lo))
            if not 0.9 <= w <= 1.1:
                bad.append("(cap) capul are %.3f m latime, contract 0,9..1,1" % w)
        # lentilele: rosu (7) sus, galben (1) la mijloc, verde (21) jos, pe AMBELE fete
        for face, sgn in (("-Z", -1), ("+Z", 1)):
            ys = {}
            for k in LENS:
                pts = [p for p, kk in zip(ps, s) if kk == k and sgn * p[2] > 0.1]
                if pts:
                    ys[k] = sum(p[1] for p in pts) / len(pts)
            if len(ys) < 3:
                bad.append("(lentile) fata %s are doar sloturile %s din %s" % (face, sorted(ys), list(LENS)))
            elif not ys[7] > ys[1] > ys[21]:
                bad.append("(lentile) fata %s: ordinea nu e rosu-galben-verde de sus in jos" % face)
        arm = [p for p, k in zip(ps, s) if k == 11 and p[0] < -4.5 and p[1] > 9.5]
        if not arm or max(p[1] for p in arm) - min(p[1] for p in arm) < 0.30 - 1e-3:
            bad.append("(brat) bratul are %.3f m grosime, contract >= 0,30"
                       % ((max(p[1] for p in arm) - min(p[1] for p in arm)) if arm else 0))
        dia = _section_diameter(d, 2.0)
        if abs(dia - 0.35) > 0.02:
            bad.append("(stalp) diametrul stalpului la +2,0: %.3f, contract 0,35" % dia)
    elif key == "sf_street_lamp":
        _names(bad, nodes, ["StreetLamp"])
        d = nodes.get("StreetLamp") or next(iter(nodes.values()))
        _base_centred(bad, "StreetLamp", d)
        (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
        if abs(y1 - 5.5) > 0.03:
            bad.append("(inaltime) %.3f, contract 5,50" % y1)
        dia = _section_diameter(d, 1.2)
        if abs(dia - 0.25) > 0.02:
            bad.append("(stalp) diametrul stalpului la +1,2: %.3f, contract 0,25" % dia)
    elif key == "sf_street_props":
        _names(bad, nodes, list(PROPS_H))
        for name, h in PROPS_H.items():
            d = nodes.get(name)
            if not d:
                continue
            _base_centred(bad, name, d)
            _tris(bad, name, d, 300)
            top = _box(d["verts"])[1][1]
            if abs(top - h) > 0.03:
                bad.append("(inaltime) %s: %.3f, contract %.2f" % (name, top, h))
        if "Hydrant" in nodes and set(_tri_slots(nodes["Hydrant"])) != {7}:
            bad.append("(culoare) hidrantul nu e tot pe slotul 7: %s" % sorted(set(_tri_slots(nodes["Hydrant"]))))
        if "Cone" in nodes and set(_tri_slots(nodes["Cone"])) != {7, 22}:
            bad.append("(culoare) conul cere sloturile {7, 22}, are %s" % sorted(set(_tri_slots(nodes["Cone"]))))
    elif key == "sf_bollard":
        _names(bad, nodes, ["Bollard"])
        d = nodes.get("Bollard") or next(iter(nodes.values()))
        (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
        if x0 < -0.2505 or x1 > 0.2505 or z0 < -0.2505 or z1 > 0.2505 or y0 < -0.0005 or y1 > 0.8005:
            bad.append("(cutie) iese din 0,5 x 0,8 x 0,5: X %.3f..%.3f Y %.3f..%.3f Z %.3f..%.3f"
                       % (x0, x1, y0, y1, z0, z1))
        if y0 > 0.005:
            bad.append("(cutie) nu atinge solul (Y minim %.3f)" % y0)
        if not set(_tri_slots(d)) <= {20, 10}:
            bad.append("(culoare) sloturi %s, contract {20, 10}" % sorted(set(_tri_slots(d))))
        _tris(bad, "Bollard", d, 200)
    elif key == "sf_crab_traps":
        _names(bad, nodes, list(TRAPS))
        for name in TRAPS:
            d = nodes.get(name)
            if not d:
                continue
            _base_centred(bad, name, d)
            _tris(bad, name, d, 300)
            b = _box(d["verts"])
            if max(hi - lo for lo, hi in b) > 1.2 + 1e-3:
                bad.append("(gabarit) %s: %.3f m, plafon 1,2" % (name, max(hi - lo for lo, hi in b)))
    elif key in ("sf_bench", "sf_bike_rack"):
        name = SINGLE[key]
        _names(bad, nodes, [name])
        d = nodes.get(name) or next(iter(nodes.values()))
        _base_centred(bad, name, d)
        _tris(bad, name, d, 400)
        b = _box(d["verts"])
        if max(hi - lo for lo, hi in b) > 2.0 + 1e-3:
            bad.append("(gabarit) %s: %.3f m, plafon 2,0" % (name, max(hi - lo for lo, hi in b)))
    if report:
        allv = [p for d in nodes.values() for p in d["verts"]]
        (x0, x1), (y0, y1), (z0, z1) = _box(allv)
        tris = sum(len(d["tris"]) for d in nodes.values())
        print("%-16s X %7.3f..%6.3f  Y %6.3f..%6.3f  Z %6.3f..%6.3f  %5d tri  noduri %s  %s"
              % (key, x0, x1, y0, y1, z0, z1, tris, ",".join(sorted(nodes)), "OK" if not bad else "PICAT"))
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

    def slot30(g, blob):
        return set_uv(g, blob, node0(g), 30.5 / 32)

    out = [("nod redenumit", "noduri", rename), ("radacina scalata 1,05", "radacina", scale),
           ("un varf pe slotul 30", "sloturi", slot30)]
    if key in CARS:
        top = CARS[key][1]
        out += [
            ("un varf iesit lateral cu 10 cm (oglinda)", "aabb",
             lambda g, b: poke(g, b, node0(g), lambda p: p[0] > 0.94, lambda p: (p[0] + 0.1, p[1], p[2]))),
            ("acoperisul inaltat cu 10 cm", "aabb",
             lambda g, b, t=top: poke_all(g, b, node0(g), lambda p: p[1] > t - 0.005,
                                          lambda p: (p[0], p[1] + 0.1, p[2])) > 0),
            ("caroseria mutata pe slotul 8", "vopsea",
             lambda g, b: _all_uv(g, b, node0(g), 8.5 / 32)),
            ("masina intoarsa (botul pe +Z)", "bot",
             lambda g, b: poke_all(g, b, node0(g), lambda p: True, lambda p: (-p[0], p[1], -p[2])) > 0),
        ]
    elif key == "sf_signal_mast":
        out += [
            ("un varf al bratului coborat la +7,0 (x -4)", "sub8",
             lambda g, b: poke(g, b, node0(g), lambda p: p[0] < -3.5 and p[1] > 9.0,
                               lambda p: (p[0], 7.0, p[2]))),
            ("capul coborat cu 0,3 m (sub +8,0)", "cap",
             lambda g, b: poke_all(g, b, node0(g), lambda p: abs(p[0] + 7.2) <= 0.55 and p[1] < 10.5,
                                   lambda p: (p[0], p[1] - 0.3, p[2])) > 0),
            ("capul intins cu 0,4 m in sus (2,8 m)", "cap",
             lambda g, b: poke_all(g, b, node0(g), lambda p: abs(p[0] + 7.2) <= 0.55 and 10.3 < p[1] < 10.5,
                                   lambda p: (p[0], p[1] + 0.4, p[2])) > 0),
            ("chenarul latit cu 0,12 m", "cap",
             lambda g, b: poke_all(g, b, node0(g), lambda p: -7.71 < p[0] < -7.69 and p[1] < 10.5,
                                   lambda p: (p[0] - 0.12, p[1], p[2])) > 0),
            ("lentila verde de pe +Z stinsa (slot 6)", "lentile",
             lambda g, b: _uv_where(g, b, node0(g), lambda p, k: k == 21 and p[2] > 0.1, 6.5 / 32)),
            ("rosu si verde inversate pe -Z", "lentile",
             lambda g, b: _uv_where(g, b, node0(g), lambda p, k: k == 7 and p[2] < -0.1, 99.0)  # marcaj temporar
             and _uv_where(g, b, node0(g), lambda p, k: k == 21 and p[2] < -0.1, 7.5 / 32)
             and _uv_where(g, b, node0(g), lambda p, k: k == 99 * 32, 21.5 / 32)),
            ("bratul subtiat la 0,17 m", "brat",
             lambda g, b: poke_all(g, b, node0(g), lambda p: -8.01 < p[0] < -7.99 and p[1] > 11.0,
                                   lambda p: (p[0], p[1] - 0.15, p[2])) > 0),
            ("bratul scurtat la 7 m", "brat",
             lambda g, b: poke_all(g, b, node0(g), lambda p: p[0] < -7.0,
                                   lambda p: (-7.0 + (p[0] + 7.0) * 0.01, p[1], p[2])) > 0),
            ("stalpul ingrosat cu 5 cm", "stalp",
             lambda g, b: poke_all(g, b, node0(g), lambda p: 0.95 < p[1] < 1.05 and math.hypot(p[0], p[2]) < 0.18,
                                   lambda p: (p[0] * 1.3, p[1], p[2] * 1.3)) > 0),
        ]
    elif key == "sf_street_lamp":
        out += [
            ("varful inaltat cu 10 cm", "inaltime",
             lambda g, b: poke(g, b, node0(g), lambda p: p[1] > 5.49, lambda p: (p[0], p[1] + 0.1, p[2]))),
            ("stalpul ingrosat", "stalp",
             lambda g, b: poke_all(g, b, node0(g), lambda p: 0.70 < p[1] < 0.74 and math.hypot(p[0], p[2]) < 0.13,
                                   lambda p: (p[0] * 1.4, p[1], p[2] * 1.4)) > 0),
        ]
    elif key == "sf_street_props":
        out += [
            ("hidrantul inaltat cu 10 cm", "inaltime",
             lambda g, b: poke(g, b, "Hydrant", lambda p: p[1] > 0.79, lambda p: (p[0], p[1] + 0.1, p[2]))),
            ("cutia postala mutata 0,3 m pe X", "origine",
             lambda g, b: poke_all(g, b, "Mailbox", lambda p: True, lambda p: (p[0] + 0.3, p[1], p[2])) > 0),
            ("conul fara banda alba (tot pe 7)", "culoare",
             lambda g, b: set_uv(g, b, "Cone", 7.5 / 32) and _all_uv(g, b, "Cone", 7.5 / 32)),
        ]
    elif key == "sf_bollard":
        out += [
            ("un varf iesit din cutie cu 5 cm", "cutie",
             lambda g, b: poke(g, b, node0(g), lambda p: p[0] > 0.2, lambda p: (0.30, p[1], p[2]))),
            ("tot pe slotul 11", "culoare", lambda g, b: _all_uv(g, b, node0(g), 11.5 / 32)),
        ]
    elif key == "sf_crab_traps":
        out += [
            ("stiva inaltata la 1,5 m", "gabarit",
             lambda g, b: poke(g, b, "TrapStack", lambda p: p[1] > 0.8, lambda p: (p[0], 1.5, p[2]))),
            ("lada ingropata 5 cm", "origine",
             lambda g, b: poke_all(g, b, "Crate", lambda p: True, lambda p: (p[0], p[1] - 0.05, p[2])) > 0),
        ]
    elif key in ("sf_bench", "sf_bike_rack"):
        out += [
            ("un varf intins la 2,3 m", "gabarit",
             lambda g, b: poke(g, b, node0(g), lambda p: p[0] > 0.6, lambda p: (2.3, p[1], p[2]))),
        ]
    return out


def _uv_where(g, blob, node_name, pred, u):
    """Muta pe `u` UV-urile varfurilor pentru care pred(pozitie, slot) e adevarat."""
    import struct
    from measure_sf_bridge import _accessor_slots
    pos = list(_accessor_slots(g, node_name, "POSITION"))
    tex = list(_accessor_slots(g, node_name, "TEXCOORD_0"))
    n = 0
    for (pa, pb, ps_, _k), (ta, tb, ts, _k2) in zip(pos, tex):
        for i in range(pa["count"]):
            p = struct.unpack_from("<fff", blob, pb + i * ps_)
            uu = struct.unpack_from("<ff", blob, tb + i * ts)[0]
            if pred(p, int(math.floor(uu * 32))):
                struct.pack_into("<ff", blob, tb + i * ts, u, 0.5)
                n += 1
    return n > 0


def _all_uv(g, blob, node_name, u):
    import struct
    from measure_sf_bridge import _accessor_slots
    for acc, base, stride, k in _accessor_slots(g, node_name, "TEXCOORD_0"):
        for i in range(acc["count"]):
            struct.pack_into("<ff", blob, base + i * stride, u, 0.5)
    return True


def selftest(keys):
    ok = True
    tmp = tempfile.mkdtemp(prefix="sfstreet_sabotaj_")
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
            print("   %-48s -> pica pe %-26s %s" % (label, ",".join(hit) or "NIMIC",
                                                    "ok" if caught else "!! ASTEPTAT (%s)" % want))
            ok &= caught
            os.remove(p)
        orig = check(key, path, report=False)
        print("   %-48s -> %s" % ("originalul", "trece" if not orig else "!! PICA: %s" % orig))
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
    print("GARDA DE STRADA SF: %s" % ("OK (%d piese)" % len(keys) if not failed else "ESUAT: %s" % ", ".join(failed)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
