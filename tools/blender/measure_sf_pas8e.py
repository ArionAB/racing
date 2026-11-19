"""Garda pieselor San Francisco ale pasului 8e: cotele si culorile pe care le cer inventarul si
consumatorii, citite din GLB-urile exportate (coordonate Godot), pe care verify_glb.py nu le vede.

    python tools/blender/measure_sf_pas8e.py            # toate piesele
    python tools/blender/measure_sf_pas8e.py --selftest # dovedeste ca fiecare asertiune pica pe sabotaj

Contract: docs/asset_briefs/sanfrancisco_inventory.md §5.1 (H5), §5.3 (M9), §5.5 (T2, T3) si comanda
pasului 8e; constructia in tools/blender/build_sf_pas8e.py. Cititorul si uneltele de sabotaj vin din
measure_sf_bridge.py / measure_sf_struct.py (doar citite).

  sf_dragon_gate   nodurile Gate_Pillar_1..4 + Gate_Frame; 12,00 x 9,00 m (+-0,02), baza la Y 0, centrata;
                   golul central 6,00 (+-0,02) intre stalpii 2 si 3 si LIBER (nicio fata) pe |x| < 2,99
                   pana la +4,50; stalpii de piatra (doar sloturile 29 / 20); tigla verde: >= 75 % din
                   aria cu fata in sus de peste +5,5 pe slotul 21; TREPTELE: acoperisurile laterale cu
                   >= 1,5 m sub cel central; streasina centrala RIDICATA la colturi cu >= 0,30 m;
                   simetrica fata / spate (fata declarata -Z nu conteaza la asezare).
  sf_gull_perch    un nod Gull_Perch, <= 150 tri; talpile (slot 23) la Y 0; 0,50-0,70 m lung (Z);
                   ciocul (slot 0) e capatul din fata (-Z); alb (22) >= 40 % din triunghiuri.
  sf_gull_glide    un nod Gull_Glide, <= 150 tri; baza la Y 0; anvergura 1,0-1,5 m; ciocul in fata (-Z);
                   varfurile aripilor negre (20) la ambele capete pe X.
  sf_parrot_perch  un nod Parrot_Perch, <= 150 tri; ghearele (slot 6) la Y 0, coada sub ele; 0,50-0,70 m
                   inalt; ciocul (19) in fata (-Z); capul ROSU (slot 7 sus); verdele (21 / 12) >= 40 %.
  sf_parrot_fly    un nod Parrot_Fly, <= 150 tri; baza la Y 0; anvergura 0,8-1,2 m; ciocul in fata;
                   capul rosu; verdele >= 40 %.
  sf_sailboat      un nod Sailboat, <= 600 tri; incaleca linia apei; coca 7,3-8,0 x 2,4-2,7 m, centrata;
                   panzele (slot 22 peste +1,5) urca 7,5-9,0 m, varful <= +10,6; prova (capatul ingust al
                   cocii) spre -Z.
  sf_lantern_string un nod LanternString; nimic peste Y 0 (prinderile); prinderile la x +-3,50 (+-0,01);
                   patru lampioane rosii (slot 7) de 0,60 (+-0,03); cablul >= 0,08 gros; nimic sub -1,70.
La toate: radacini fara scala/rotatie/translatie, niciun slot 14-16 sau 30, COLOR_0 (AO) prezent.
"""
import json
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_sf_bridge import _roots, _write_glb, hits, load, poke_all, set_uv  # noqa: E402
from measure_sf_struct import (_box, _forbidden, _islands, _names, _near, _pts, _roots_clean,  # noqa: E402
                               _slots, _tri_geo, _tri_slots, _uv_where)
from verify_glb import load_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODELS = os.path.join(ROOT, "assets", "models", "sanfrancisco")
PIECES = {
    "sf_dragon_gate": "structures/sf_dragon_gate.glb",
    "sf_gull_perch": "animals/sf_gull_perch.glb",
    "sf_gull_glide": "animals/sf_gull_glide.glb",
    "sf_parrot_perch": "animals/sf_parrot_perch.glb",
    "sf_parrot_fly": "animals/sf_parrot_fly.glb",
    "sf_sailboat": "vehicles/sf_sailboat.glb",
    "sf_lantern_string": "props/sf_lantern_string.glb",
}
GATE_NODES = ["Gate_Pillar_1", "Gate_Pillar_2", "Gate_Pillar_3", "Gate_Pillar_4", "Gate_Frame"]
BIRD_NODE = {"sf_gull_perch": "Gull_Perch", "sf_gull_glide": "Gull_Glide",
             "sf_parrot_perch": "Parrot_Perch", "sf_parrot_fly": "Parrot_Fly"}
BIRD_TRIS = 150
BEAK = {"gull": 0, "parrot": 19}
PARROT_GREENS = {21, 12, 17}     # 17: varianta "turcoaz" (parghie de masurare, vezi build)


def _all(nodes):
    return [p for d in nodes.values() for p in d["verts"]]


# ------------------------------------------------------------------ poarta
def check_gate(bad, nodes):
    allv = _all(nodes)
    if not allv:
        return
    (x0, x1), (y0, y1), (z0, z1) = _box(allv)
    _near(bad, "gabarit", "latimea", x1 - x0, 12.0, 0.02)
    _near(bad, "gabarit", "centrul X", (x0 + x1) * 0.5, 0.0, 0.02)
    _near(bad, "gabarit", "inaltimea", y1, 9.0, 0.02)
    _near(bad, "gabarit", "baza", y0, 0.0, 0.005)
    _near(bad, "gabarit", "centrul Z", (z0 + z1) * 0.5, 0.0, 0.02)
    p = [nodes.get(n) for n in GATE_NODES[:4]]
    if all(p):
        cx = [sum(v[0] for v in d["verts"]) / len(d["verts"]) for d in p]
        if cx != sorted(cx):
            bad.append("(stalpi) stalpii nu sunt in ordine de la -X la +X: %s" % [round(c, 2) for c in cx])
        gap = min(v[0] for v in p[2]["verts"]) - max(v[0] for v in p[1]["verts"])
        _near(bad, "gol", "golul central intre stalpii 2 si 3", gap, 6.0, 0.02)
        for d, name in zip(p, GATE_NODES):
            ks = set(_tri_slots(d))
            if not ks <= {29, 20}:
                bad.append("(piatra) %s pe sloturile %s, contract piatra {29, 20}" % (name, sorted(ks)))
    h = hits(nodes, (-2.99, 0.01, -3.0), (2.99, 4.5, 3.0))
    if h:
        bad.append("(gol) %d triunghiuri in golul liber (|x| < 2,99, Y 0..4,50), ex. nodul %s"
                   % (len(h), h[0][0] if isinstance(h[0], tuple) else h[0]))
    fr = nodes.get("Gate_Frame")
    if not fr:
        return
    top = _top_view(fr, ymin=5.5)
    tile = sum(1 for _y, k in top.values() if k == 21)
    if not top or tile < 0.75 * len(top):
        bad.append("(tigla) vazut de sus, doar %.0f %% din acoperisuri pe slotul 21"
                   % (100.0 * tile / max(len(top), 1)))
    roof = _pts(fr, {21})
    c_top = max((v[1] for v in roof if abs(v[0]) < 2.0), default=0.0)
    s_top = max((v[1] for v in roof if abs(v[0]) > 4.9), default=99.0)
    if c_top - s_top < 1.5:
        bad.append("(trepte) acoperisul central la +%.2f, cele laterale la +%.2f (contract >= 1,5 m diferenta)"
                   % (c_top, s_top))
    corner = [v[1] for v in roof if 4.4 < abs(v[0]) < 4.8 and abs(v[2]) > 1.35]
    mid = [v[1] for v in roof if abs(v[0]) < 0.6 and abs(v[2]) > 1.45]
    if not corner or not mid:
        bad.append("(streasina) nu gasesc streasina centrala (colt %d, mijloc %d varfuri)" % (len(corner), len(mid)))
    elif max(corner) - min(mid) < 0.30:
        bad.append("(streasina) coltul urca doar %.2f m peste mijlocul streasinii (contract >= 0,30)"
                   % (max(corner) - min(mid)))
    # simetria fata / spate: aceleasi cote pe Z si -Z (fara inscriptie, fara fata privilegiata)
    a = sorted(round(v[2], 2) for v in allv)
    b = sorted(round(-v[2], 2) for v in allv)
    if a != b:
        bad.append("(simetrie) poarta nu e simetrica fata / spate")


def _top_view(d, cell=0.1, ymin=5.5):
    """Ce se vede DE SUS: pe o grila XZ de `cell` m, slotul triunghiului celui mai inalt din fiecare
    celula (doar peste `ymin`). Fetele de sus ale grinzilor si ale tavanelor de sub acoperis nu
    conteaza: le acopera tigla."""
    ts = _tri_slots(d)
    vs = d["verts"]
    out = {}
    for t, k in zip(d["tris"], ts):
        a, b, c = (vs[i] for i in t)
        if max(a[1], b[1], c[1]) < ymin:
            continue
        den = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
        if abs(den) < 1e-12:
            continue
        i0, i1 = int(math.floor(min(a[0], b[0], c[0]) / cell)), int(math.floor(max(a[0], b[0], c[0]) / cell))
        j0, j1 = int(math.floor(min(a[2], b[2], c[2]) / cell)), int(math.floor(max(a[2], b[2], c[2]) / cell))
        for i in range(i0, i1 + 1):
            x = (i + 0.5) * cell
            for j in range(j0, j1 + 1):
                z = (j + 0.5) * cell
                l1 = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / den
                l2 = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / den
                l3 = 1.0 - l1 - l2
                if min(l1, l2, l3) < 0.0:
                    continue
                y = l1 * a[1] + l2 * b[1] + l3 * c[1]
                if y >= ymin and ((i, j) not in out or y > out[(i, j)][0]):
                    out[(i, j)] = (y, k)
    return out


# ------------------------------------------------------------------ pasarile
def check_bird(bad, key, nodes):
    name = BIRD_NODE[key]
    d = nodes.get(name)
    if not d:
        return
    kind = "gull" if key.startswith("sf_gull") else "parrot"
    perch = key.endswith("perch")
    if len(d["tris"]) > BIRD_TRIS:
        bad.append("(triunghiuri) %d, plafon %d" % (len(d["tris"]), BIRD_TRIS))
    (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
    if abs((x0 + x1) * 0.5) > 0.02 or abs((z0 + z1) * 0.5) > 0.02:
        bad.append("(origine) necentrat in XZ (%.3f, %.3f)" % ((x0 + x1) * 0.5, (z0 + z1) * 0.5))
    if perch:
        feet = _pts(d, {23} if kind == "gull" else {6})
        if not feet:
            bad.append("(talpi) nu gasesc talpile / ghearele")
        else:
            _near(bad, "talpi", "talpile", min(v[1] for v in feet), 0.0, 0.005)
        size = (z1 - z0) if kind == "gull" else (y1 - y0)
        if not 0.50 <= size <= 0.70:
            bad.append("(marime) %.2f m, contract ~0,6 (0,50-0,70)" % size)
    else:
        _near(bad, "baza", "baza", y0, 0.0, 0.005)
        span = x1 - x0
        lo, hi = (1.0, 1.5) if kind == "gull" else (0.8, 1.2)
        if not lo <= span <= hi:
            bad.append("(marime) anvergura %.2f m, contract %.1f-%.1f" % (span, lo, hi))
        if kind == "gull":
            tips = _pts(d, {20}, lambda v: abs(v[0]) > 0.45)
            if not any(v[0] < 0 for v in tips) or not any(v[0] > 0 for v in tips):
                bad.append("(aripi) varfurile negre (20) nu sunt la ambele capete")
    beak = _pts(d, {BEAK[kind]})
    if not beak:
        bad.append("(cioc) nu gasesc ciocul (slot %d)" % BEAK[kind])
    elif min(v[2] for v in beak) > z0 + 0.02:
        bad.append("(cioc) ciocul nu e capatul din fata (-Z): cioc %.3f, fata %.3f" % (min(v[2] for v in beak), z0))
    ts = _tri_slots(d)
    if kind == "gull":
        share = sum(1 for k in ts if k == 22) / float(len(ts))
        if share < 0.40:
            bad.append("(alb) doar %.0f %% din triunghiuri pe slotul 22" % (100 * share))
    else:
        share = sum(1 for k in ts if k in PARROT_GREENS) / float(len(ts))
        if share < 0.40:
            bad.append("(verde) doar %.0f %% din triunghiuri pe verde (21 / 12)" % (100 * share))
        head = [k for v, k in zip(d["verts"], _slots(d)) if v[1] > (y1 - 0.04 if perch else y0) and k not in (19, 22, 20)]
        if perch and (not head or any(k != 7 for k in head)):
            bad.append("(cap) varful papagalului nu e rosu (sloturi %s)" % sorted(set(head)))
        if not perch:
            red = _pts(d, {7})
            if not red or (sum(v[2] for v in red) / len(red)) > -0.1:
                bad.append("(cap) capul rosu (7) nu e in fata")


# ------------------------------------------------------------------ velierul
def check_sail(bad, nodes):
    d = nodes.get("Sailboat")
    if not d:
        return
    if len(d["tris"]) > 600:
        bad.append("(triunghiuri) %d, plafon 600" % len(d["tris"]))
    (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
    if not (y0 < -0.05 and y1 > 0.05):
        bad.append("(linia apei) nu incaleca Y 0 (%.3f..%.3f)" % (y0, y1))
    hull = _pts(d, {22, 20, 19}, lambda v: v[1] < 1.05 and abs(v[0]) < 1.4)
    if not hull:
        bad.append("(coca) nu gasesc coca")
        return
    (hx0, hx1), (_hy0, _hy1), (hz0, hz1) = _box(hull)
    if not 7.3 <= hz1 - hz0 <= 8.0 or not 2.4 <= hx1 - hx0 <= 2.7:
        bad.append("(coca) %.2f x %.2f m, contract 7,3-8,0 x 2,4-2,7" % (hz1 - hz0, hx1 - hx0))
    if abs((hz0 + hz1) * 0.5) > 0.1 or abs((hx0 + hx1) * 0.5) > 0.1:
        bad.append("(coca) necentrata (%.2f, %.2f)" % ((hx0 + hx1) * 0.5, (hz0 + hz1) * 0.5))
    sails = _pts(d, {22}, lambda v: v[1] > 1.5)
    if not sails:
        bad.append("(vela) nicio panza alba peste +1,5")
    else:
        lo, hi = min(v[1] for v in sails), max(v[1] for v in sails)
        if not 7.5 <= hi - lo <= 9.0 or hi > 10.6:
            bad.append("(vela) panzele urca %.2f m (pana la +%.2f), contract 7,5-9,0 si <= +10,6" % (hi - lo, hi))
    deck = [v for v in hull if 0.5 < v[1] < 1.05]
    front = [abs(v[0]) for v in deck if v[2] < hz0 + 1.2]
    back = [abs(v[0]) for v in deck if v[2] > hz1 - 1.2]
    if not front or not back or max(front) >= max(back):
        bad.append("(prova) capatul ingust al cocii nu e spre -Z (fata %.2f, spate %.2f)"
                   % (max(front, default=0), max(back, default=0)))


# ------------------------------------------------------------------ lampioanele
def check_lanterns(bad, nodes):
    d = nodes.get("LanternString")
    if not d:
        return
    (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
    if y1 > 0.005:
        bad.append("(prindere) geometria urca la +%.3f peste prinderi (Y 0)" % y1)
    if y0 < -1.70:
        bad.append("(gabarit) atarna pana la %.2f, plafon -1,70" % y0)
    ends = _pts(d, {20}, lambda v: v[1] > -0.14)
    if ends:
        _near(bad, "prindere", "prinderea din stanga", min(v[0] for v in ends) + 0.07, -3.5, 0.01)
        _near(bad, "prindere", "prinderea din dreapta", max(v[0] for v in ends) - 0.07, 3.5, 0.01)
    mid = _pts(d, {20}, lambda v: abs(v[0]) < 0.12)
    th = (max(v[1] for v in mid) - min(v[1] for v in mid)) if mid else 0.0
    if th < 0.08 - 1e-3:
        bad.append("(cablu) %.3f m gros, contract >= 0,08" % th)
    ts = _tri_slots(d)
    reds = []
    for isl in _islands(d):
        if all(ts[ti] in (7, 28) for ti in isl) and any(ts[ti] == 7 for ti in isl):
            reds.append(_box([d["verts"][i] for ti in isl for i in d["tris"][ti]]))
    if len(reds) != 4:
        bad.append("(lampion) %d lampioane rosii, contract 4" % len(reds))
    for bx in reds:
        w = bx[0][1] - bx[0][0]
        if abs(w - 0.60) > 0.03:
            bad.append("(lampion) un lampion de %.2f m, contract 0,60 (+-0,03)" % w)
            break


def check(key, path, report=True):
    g, _blob, nodes = load(path)
    bad = []
    _roots_clean(bad, g)
    _forbidden(bad, nodes)
    if key == "sf_dragon_gate":
        _names(bad, g, nodes, GATE_NODES)
        check_gate(bad, nodes)
    elif key in BIRD_NODE:
        _names(bad, g, nodes, [BIRD_NODE[key]])
        check_bird(bad, key, nodes)
    elif key == "sf_sailboat":
        _names(bad, g, nodes, ["Sailboat"])
        check_sail(bad, nodes)
    elif key == "sf_lantern_string":
        _names(bad, g, nodes, ["LanternString"])
        check_lanterns(bad, nodes)
    if report:
        allv = _all(nodes)
        (x0, x1), (y0, y1), (z0, z1) = _box(allv)
        tris = sum(len(d["tris"]) for d in nodes.values())
        print("%-18s X %7.3f..%6.3f  Y %7.3f..%6.3f  Z %7.3f..%6.3f  %5d tri  %s"
              % (key, x0, x1, y0, y1, z0, z1, tris, "OK" if not bad else "PICAT"))
        for line in bad:
            print("   !! " + line)
    return bad


# ------------------------------------------------------------------ selftest
def _mv(node, pred, move):
    return lambda g, b: poke_all(g, b, node, pred, move) > 0


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
    if key == "sf_dragon_gate":
        F = "Gate_Frame"
        out += [
            ("poarta latita (carligele +0,3 pe X)", "gabarit", _mv(F, lambda p: p[0] > 5.5, lambda p: (p[0] + 0.3, p[1], p[2]))),
            ("volutele inaltate cu 0,4", "gabarit", _mv(F, lambda p: p[1] > 8.6, lambda p: (p[0], p[1] + 0.4, p[2]))),
            ("stalpul 3 mutat 0,3 spre ax (golul 5,7)", "gol",
             _mv("Gate_Pillar_3", lambda p: True, lambda p: (p[0] - 0.3, p[1], p[2]))),
            ("grinda de jos coborata in gol (-2,5 m)", "gol",
             _mv(F, lambda p: 5.5 < p[1] < 6.1 and abs(p[0]) < 4.0 and abs(p[2]) < 0.3, lambda p: (p[0], p[1] - 2.5, p[2]))),
            ("stalpul 2 vopsit rosu (slot 7)", "piatra",
             lambda g, b: _uv_where(g, b, "Gate_Pillar_2", lambda p, k: k == 29 and p[1] > 1.2, 7.5 / 32)),
            ("tigla vopsita rosu (21 -> 7)", "tigla", lambda g, b: _uv_where(g, b, F, lambda p, k: k == 21, 7.5 / 32)),
            ("acoperisurile laterale urcate cu 1,5 m", "trepte",
             _mv(F, lambda p: abs(p[0]) > 3.0 and 5.6 < p[1] < 7.0 and abs(p[2]) > 0.7, lambda p: (p[0], p[1] + 1.5, p[2]))),
            ("streasina centrala turtita (coltii -0,5)", "streasina",
             _mv(F, lambda p: 4.0 < abs(p[0]) < 4.9 and abs(p[2]) > 1.2 and 7.6 < p[1] < 8.7,
                 lambda p: (p[0], p[1] - 0.5, p[2]))),
            ("o placa doar pe fata (+Z impins 0,2)", "simetrie",
             _mv(F, lambda p: p[2] > 0.15 and 6.05 < p[1] < 6.75 and abs(p[0]) < 1.0, lambda p: (p[0], p[1], p[2] + 0.2))),
        ]
    elif key in BIRD_NODE:
        N = BIRD_NODE[key]
        kind = "gull" if key.startswith("sf_gull") else "parrot"
        out += [
            ("pasarea intoarsa (ciocul pe +Z)", "cioc", _mv(N, lambda p: True, lambda p: (-p[0], p[1], -p[2]))),
            ("pasarea scalata x1,6", "marime", _mv(N, lambda p: True, lambda p: (p[0] * 1.6, p[1] * 1.6, p[2] * 1.6))),
        ]
        if key.endswith("perch"):
            out.append(("pasarea ridicata 0,3 m", "talpi", _mv(N, lambda p: True, lambda p: (p[0], p[1] + 0.3, p[2]))))
        else:
            out.append(("pasarea ridicata 0,3 m", "baza", _mv(N, lambda p: True, lambda p: (p[0], p[1] + 0.3, p[2]))))
        if kind == "gull":
            out.append(("pescarusul vopsit gri (22 -> 11)", "alb",
                        lambda g, b: _uv_where(g, b, N, lambda p, k: k == 22, 11.5 / 32)))
            if key.endswith("glide"):
                out.append(("varfurile aripilor albe (20 -> 22)", "aripi",
                            lambda g, b: _uv_where(g, b, N, lambda p, k: k == 20, 22.5 / 32)))
        else:
            out.append(("capul vopsit verde (7 -> 21)", "cap",
                        lambda g, b: _uv_where(g, b, N, lambda p, k: k == 7, 21.5 / 32)))
            out.append(("papagalul vopsit gri (verdele -> 29)", "verde",
                        lambda g, b: _uv_where(g, b, N, lambda p, k: k in PARROT_GREENS, 29.5 / 32)))
    elif key == "sf_sailboat":
        N = "Sailboat"
        out += [
            ("velierul intors (prova pe +Z)", "prova", _mv(N, lambda p: True, lambda p: (-p[0], p[1], -p[2]))),
            ("velierul ridicat din apa (+1 m)", "linia apei", _mv(N, lambda p: True, lambda p: (p[0], p[1] + 1.0, p[2]))),
            ("panzele scurtate la jumatate", "vela", _mv(N, lambda p: p[1] > 1.5, lambda p: (p[0], 1.5 + (p[1] - 1.5) * 0.5, p[2]))),
            ("panzele vopsite rosu (22 -> 7)", "vela", lambda g, b: _uv_where(g, b, N, lambda p, k: k == 22 and p[1] > 1.5, 7.5 / 32)),
            ("coca lungita la 9 m", "coca", _mv(N, lambda p: p[2] > 3.0, lambda p: (p[0], p[1], p[2] + 1.3))),
        ]
    elif key == "sf_lantern_string":
        N = "LanternString"
        out += [
            ("sirul ridicat 0,2 peste prinderi", "prindere", _mv(N, lambda p: True, lambda p: (p[0], p[1] + 0.2, p[2]))),
            ("modulul intins la 7,6 m", "prindere", _mv(N, lambda p: p[0] > 3.3, lambda p: (p[0] + 0.3, p[1], p[2]))),
            ("lampioanele strivite la 0,40", "lampion",
             lambda g, b: _shrink_lanterns(g, b, N)),
            ("cablul subtiat la 0,04", "cablu",
             lambda g, b: _uv_where(g, b, N, lambda p, k: False, 0.0) or _thin_cable(g, b, N)),
            ("un lampion lipsa (repictat pe cablu, 7 -> 20)", "lampion",
             lambda g, b: _uv_where(g, b, N, lambda p, k: k in (7, 28) and p[0] > 1.7, 20.5 / 32)),
        ]
    return out


def _shrink_lanterns(g, blob, node):
    xs = (-2.1, -0.7, 0.7, 2.1)
    import struct
    from measure_sf_bridge import _accessor_slots
    pos = list(_accessor_slots(g, node, "POSITION"))
    tex = list(_accessor_slots(g, node, "TEXCOORD_0"))
    n = 0
    for (pa, pb, ps_, _k), (_ta, tb, tsd, _k2) in zip(pos, tex):
        for i in range(pa["count"]):
            p = struct.unpack_from("<fff", blob, pb + i * ps_)
            k = int(math.floor(struct.unpack_from("<ff", blob, tb + i * tsd)[0] * 32))
            if k in (7, 28):
                cx = min(xs, key=lambda c: abs(c - p[0]))
                struct.pack_into("<fff", blob, pb + i * ps_, cx + (p[0] - cx) * 0.66, p[1], p[2] * 0.66)
                n += 1
    return n > 0


def _thin_cable(g, blob, node):
    """Cablul (slot 20, |x| < 3,4): fiecare varf tras spre axa lui, la jumatate."""
    import struct
    from measure_sf_bridge import _accessor_slots
    pos = list(_accessor_slots(g, node, "POSITION"))
    tex = list(_accessor_slots(g, node, "TEXCOORD_0"))
    n = 0
    for (pa, pb, ps_, _k), (_ta, tb, tsd, _k2) in zip(pos, tex):
        for i in range(pa["count"]):
            p = struct.unpack_from("<fff", blob, pb + i * ps_)
            k = int(math.floor(struct.unpack_from("<ff", blob, tb + i * tsd)[0] * 32))
            if k == 20 and abs(p[0]) < 3.4:
                yc = -0.045 - 0.55 * (1.0 - (p[0] / 3.5) ** 2)
                struct.pack_into("<fff", blob, pb + i * ps_, p[0], yc + (p[1] - yc) * 0.45, p[2] * 0.45)
                n += 1
    return n > 0


def selftest(keys):
    ok = True
    tmp = tempfile.mkdtemp(prefix="sfpas8e_sabotaj_")
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
            print("   %-52s -> pica pe %-30s %s" % (label, ",".join(hit) or "NIMIC",
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
    print("GARDA PIESELOR SF 8e: %s" % ("OK (%d piese)" % len(keys) if not failed else "ESUAT: %s" % ", ".join(failed)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
