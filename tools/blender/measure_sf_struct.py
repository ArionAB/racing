"""Garda structurilor San Francisco (valul 3): cotele pe care le citeste jocul (sau generatorul) din
fisiere si pe care verify_glb.py nu le vede.

    python tools/blender/measure_sf_struct.py            # toate piesele
    python tools/blender/measure_sf_struct.py --selftest # dovedeste ca fiecare asertiune pica pe sabotaj

Citeste GLB-urile direct, in coordonate Godot (cititorul si uneltele de sabotaj vin din
`measure_sf_bridge.py`, doar citite). Contractul: docs/asset_briefs/sanfrancisco_inventory.md §5.1
(H4, H6), §5.4 (N1), §5.5 (F1, F2, T1) si comanda valului 3.

  sf_turntable      nodurile Turntable_Deck + Turntable_Booth; discul ⌀ 10,0 (+-0,02) centrat in
                    origine, de la Y 0, NIMIC pe disc peste +0,12; fata scandurilor la +0,05; doua
                    sine (slot 11) de-a lungul lui Z (>= 8 m lungi, <= 0,10 late), ecartament 1,10
                    (+-0,01) intre fetele interioare, capul la +0,10; ghereta 2 x 2 x 2,6 (+-0,02),
                    de la Y 0, cu TOATE varfurile in afara discului (r > 5,0).
  sf_pier_shed(_short)
                    un nod (PierShed / PierShed_Short); peretii (slot 29, pas 8d) 12,0 x 20,0 / 12,0 (+-0,05),
                    centrati; cheia la +9,0 (+-0,02); puntea cu fata la Y 0 (+-0,005); pilonii pana la
                    Y -6,0 (+-0,01); usa (scandurile slot 28 la |x| < 3) DOAR pe fata -Z; pas 8d:
                    fetele mari ale peretilor lungi doar pe slotul 29 si nicio fata a corpului pe un
                    slot cald-saturat (0-3, 9, 10, 23, 27: lemnul de chei e gri-maro, nu portocaliu).
  sf_island_light   nodurile Island_Rock + Island_Light; stanca 55-70 x 35-48 m, varful +9..+11,
                    fusta la -3,0 (+-0,01); farul are 15,0 m (+-0,3) peste stanca de sub el.
  sf_horizon        exact Hill_A/B/C + City_A/B, toate radacini, fiecare cu baza la Y 0 (+-0,01) si
                    centrat in XZ (+-0,5); dealurile 200-300 m lungi; orasele
                    150-250 m late, turnul cel mai inalt 40-80 m; v2: relieful dealurilor
                    (sloturile 0/13) 30-38 m si nimic peste 38; pâlcurile de chiparos (slot 21)
                    >= 1,4x mai late decat inalte, trunchiul gol de sub ele <= 25 % din arbore; la orase NICIO fata inclinata
                    (doar verticale si orizontale: fara piramide, turle, acoperisuri in panta) si
                    fiecare volum are capacul >= 15 % din talpa (fara varf de piramida).
  sf_stair_lane     un nod StairLane, <= 400 tri; 2,50 (+-0,01) lat, centrat; Y de la 0; Z de la
                    0 la +5,0 (urca spre +Z); urcarea treptelor 3,0 (+-0,05) de la palierul de jos;
                    zidurile (slot 8 la |x| > 0,95) >= 0,20 groase pe ambele parti.
  sf_sea_lions      UN nod SeaLions (FlockProp: un mesh); pluta (scandurile, sloturile 23/9)
                    4,0 x 3,0 (+-0,05) centrata, incaleca Y 0; leii (sloturile 2/4) >= 25 % din
                    triunghiuri; <= 1800 tri.
La toate: radacini fara scala/rotatie/translatie (memoria scala-glb-neaplicata-la-radacina),
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
    "sf_turntable": "structures/sf_turntable.glb",
    "sf_pier_shed": "structures/sf_pier_shed.glb",
    "sf_pier_shed_short": "structures/sf_pier_shed_short.glb",
    "sf_island_light": "structures/sf_island_light.glb",
    "sf_horizon": "structures/sf_horizon.glb",
    "sf_stair_lane": "props/sf_stair_lane.glb",
    "sf_sea_lions": "animals/sf_sea_lions.glb",
}
SHEDS = {"sf_pier_shed": ("PierShed", 20.0), "sf_pier_shed_short": ("PierShed_Short", 12.0)}
HILLS = ("Hill_A", "Hill_B", "Hill_C")
CITIES = ("City_A", "City_B")
FORBIDDEN = {14, 15, 16, 30}


def _box(ps):
    return [(min(p[i] for p in ps), max(p[i] for p in ps)) for i in range(3)]


def _slots(d):
    return [int(math.floor(u[0] * 32)) for u in d["uv"]]


def _tri_slots(d):
    s = _slots(d)
    return [s[t[0]] for t in d["tris"]]


def _pts(d, slots=None, pred=None):
    s = _slots(d)
    return [p for p, k in zip(d["verts"], s) if (slots is None or k in slots) and (pred is None or pred(p))]


def _roots_clean(bad, g):
    for n in _roots(g):
        if any(abs(a - b) > 1e-5 for a, b in zip(n.get("scale", [1, 1, 1]), [1, 1, 1])) \
                or any(abs(a - b) > 1e-5 for a, b in zip(n.get("rotation", [0, 0, 0, 1]), [0, 0, 0, 1])) \
                or any(abs(a) > 1e-5 for a in n.get("translation", [0, 0, 0])):
            bad.append("(radacina) %s are scala/rotatie/translatie" % n.get("name"))


def _names(bad, g, nodes, want):
    if sorted(nodes) != sorted(want):
        bad.append("(noduri) %s, contract %s" % (sorted(nodes), sorted(want)))
    roots = {n.get("name") for n in _roots(g)}
    for w in want:
        if w in nodes and w not in roots:
            bad.append("(noduri) %s nu e copil direct al radacinii" % w)


def _forbidden(bad, nodes):
    for name, d in nodes.items():
        hit = sorted(set(_slots(d)) & FORBIDDEN)
        if hit:
            bad.append("(sloturi) %s foloseste sloturile interzise %s" % (name, hit))
        if not d["color"]:
            bad.append("(sloturi) %s fara COLOR_0 (AO)" % name)


def _near(bad, tag, label, got, want, tol):
    if abs(got - want) > tol:
        bad.append("(%s) %s = %.3f, contract %.3f +-%.3g" % (tag, label, got, want, tol))


def _tri_geo(d, t):
    a, b, c = (d["verts"][i] for i in t)
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    ln = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
    return (n[0] / ln, n[1] / ln, n[2] / ln) if ln > 1e-12 else (0.0, 0.0, 0.0), ln * 0.5


def _islands(d):
    """Componentele conexe pe POZITII (exportul dubleaza varfurile pe muchiile ascutite)."""
    key = {}
    parent = {}

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    vid = []
    for p in d["verts"]:
        k = (round(p[0], 3), round(p[1], 3), round(p[2], 3))
        if k not in key:
            key[k] = len(key)
            parent[key[k]] = key[k]
        vid.append(key[k])
    for t in d["tris"]:
        a, b, c = (vid[i] for i in t)
        for x, y in ((a, b), (b, c)):
            rx, ry = find(x), find(y)
            if rx != ry:
                parent[rx] = ry
    groups = {}
    for ti, t in enumerate(d["tris"]):
        groups.setdefault(find(vid[t[0]]), []).append(ti)
    return list(groups.values())


# ------------------------------------------------------------------ piesele
def check_turntable(bad, nodes):
    deck = nodes.get("Turntable_Deck")
    booth = nodes.get("Turntable_Booth")
    if deck:
        (x0, x1), (y0, y1), (z0, z1) = _box(deck["verts"])
        _near(bad, "disc", "diametrul pe X", x1 - x0, 10.0, 0.02)
        _near(bad, "disc", "diametrul pe Z", z1 - z0, 10.0, 0.02)
        _near(bad, "disc", "centrul X", (x0 + x1) * 0.5, 0.0, 0.02)
        _near(bad, "disc", "centrul Z", (z0 + z1) * 0.5, 0.0, 0.02)
        _near(bad, "disc", "baza", y0, 0.0, 0.005)
        if y1 > 0.12 + 1e-3:
            bad.append("(pe disc) ceva pe disc urca la +%.3f, plafon +0,12" % y1)
        pl = _pts(deck, {9, 27})
        if pl:
            _near(bad, "disc", "fata scandurilor", max(p[1] for p in pl), 0.05, 0.005)
        rails = _pts(deck, {11})
        left = [p for p in rails if p[0] < 0]
        right = [p for p in rails if p[0] > 0]
        if not left or not right:
            bad.append("(sine) nu sunt doua sine (slot 11) de o parte si de alta a axei")
        else:
            _near(bad, "sine", "ecartamentul intre fetele interioare",
                  min(p[0] for p in right) - max(p[0] for p in left), 1.10, 0.01)
            for side, ps in (("stanga", left), ("dreapta", right)):
                (a0, a1), (b0, b1), (c0, c1) = _box(ps)
                if c1 - c0 < 8.0 or a1 - a0 > 0.10 + 1e-3:
                    bad.append("(sine) sina din %s nu e de-a lungul lui Z (%.2f pe Z, %.3f pe X)"
                               % (side, c1 - c0, a1 - a0))
                _near(bad, "sine", "capul sinei din %s" % side, b1, 0.10, 0.005)
    if booth:
        (x0, x1), (y0, y1), (z0, z1) = _box(booth["verts"])
        _near(bad, "ghereta", "latimea X", x1 - x0, 2.0, 0.02)
        _near(bad, "ghereta", "adancimea Z", z1 - z0, 2.0, 0.02)
        _near(bad, "ghereta", "inaltimea", y1, 2.6, 0.02)
        _near(bad, "ghereta", "baza", y0, 0.0, 0.005)
        inside = [p for p in booth["verts"] if math.hypot(p[0], p[2]) <= 5.0]
        if inside:
            bad.append("(ghereta) %d varfuri pe disc (r <= 5,0), ex. %s"
                       % (len(inside), tuple(round(v, 2) for v in inside[0])))


SHED_WALL_SLOT = 29          # pas 8d: lemnul gri-maro de chei (MARBLE_GREY, tenta in vertex colors)
SHED_DECK_SLOT = 29
SHED_ORANGE = {0, 1, 2, 3, 9, 10, 23, 27}   # sloturile calde/saturate care au facut magazia portocalie


def check_shed(bad, nodes, name, L):
    d = nodes.get(name)
    if not d:
        return
    walls = _pts(d, {SHED_WALL_SLOT}, lambda p: p[1] > 0.3)
    if walls:
        (x0, x1), (_y0, _y1), (z0, z1) = _box(walls)
        _near(bad, "amprenta", "latimea peretilor", x1 - x0, 12.0, 0.05)
        _near(bad, "amprenta", "lungimea peretilor", z1 - z0, L, 0.05)
        _near(bad, "amprenta", "centrul X", (x0 + x1) * 0.5, 0.0, 0.05)
        _near(bad, "amprenta", "centrul Z", (z0 + z1) * 0.5, 0.0, 0.05)
    else:
        bad.append("(amprenta) niciun perete pe slotul %d" % SHED_WALL_SLOT)
    # lemnul: fetele mari ale peretilor lungi (planul |x| = 6,0, > 1 m2) stau pe slotul peretelui,
    # iar nicio fata a corpului (peste punte) nu e pe un slot cald-saturat
    ts = _tri_slots(d)
    big = set()
    for t, k in zip(d["tris"], ts):
        n, area = _tri_geo(d, t)
        if area > 1.0 and abs(n[0]) > 0.99 and all(abs(abs(d["verts"][i][0]) - 6.0) < 0.005 for i in t):
            big.add(k)
    big.discard(22)              # braul alb de streasina (fata lui interioara sta in acelasi plan)
    if big != {SHED_WALL_SLOT}:
        bad.append("(lemn) peretii lungi pe sloturile %s, contract {%d}" % (sorted(big), SHED_WALL_SLOT))
    hot = sorted({k for t, k in zip(d["tris"], ts) if k in SHED_ORANGE
                  and min(d["verts"][i][1] for i in t) > 0.05})
    if hot:
        bad.append("(lemn) corpul foloseste sloturile calde %s (lemnul de chei e gri-maro)" % hot)
    (_a, _b), (y0, y1), (_c, _d) = _box(d["verts"])
    _near(bad, "cheia", "varful acoperisului", y1, 9.0, 0.02)
    roof = _pts(d, {6}, lambda p: abs(p[0]) < 0.5)
    if not roof or max(p[1] for p in roof) < 9.0 - 0.02:
        bad.append("(cheia) acoperisul (slot 6) nu urca la +9,0 deasupra axei")
    deck = _pts(d, {SHED_DECK_SLOT}, lambda p: abs(p[0]) > 6.1 and -0.5 < p[1] < 0.5)
    if not deck:
        bad.append("(punte) nicio scandura de punte langa pereti")
    else:
        _near(bad, "punte", "fata puntii", max(p[1] for p in deck), 0.0, 0.005)
    _near(bad, "piloni", "talpa pilonilor", y0, -6.0, 0.01)
    door = _pts(d, {28}, lambda p: 0.05 < p[1] < 4.6 and abs(p[0]) < 3.0)
    front = [p for p in door if p[2] < -L * 0.5]
    back = [p for p in door if p[2] > L * 0.5]
    if not front or back:
        bad.append("(fronton) usa nu e doar pe -Z (fata %d varfuri, spate %d)" % (len(front), len(back)))


def check_island(bad, nodes):
    rock = nodes.get("Island_Rock")
    light = nodes.get("Island_Light")
    if rock:
        (x0, x1), (y0, y1), (z0, z1) = _box(rock["verts"])
        if not 55.0 <= x1 - x0 <= 70.0 or not 35.0 <= z1 - z0 <= 48.0:
            bad.append("(stanca) %.1f x %.1f m, contract ~60 x 40 (55-70 x 35-48)" % (x1 - x0, z1 - z0))
        if not 9.0 <= y1 <= 11.0:
            bad.append("(stanca) varful la +%.2f, contract ~+10 (9..11)" % y1)
        _near(bad, "stanca", "fusta", y0, -3.0, 0.01)
    if rock and light:
        (lx0, lx1), (ly0, ly1), (lz0, lz1) = _box(light["verts"])
        ax, az = (lx0 + lx1) * 0.5, (lz0 + lz1) * 0.5
        under = [p[1] for p in rock["verts"] if math.hypot(p[0] - ax, p[2] - az) < 3.0]
        if not under:
            bad.append("(far) farul nu sta pe stanca")
        else:
            _near(bad, "far", "inaltimea farului peste stanca", ly1 - max(under), 15.0, 0.3)
        if 22 not in set(_tri_slots(light)):
            bad.append("(far) turnul nu e alb (slot 22)")


def check_horizon(bad, nodes):
    for name, d in nodes.items():
        (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
        _near(bad, "baza", "%s Y minim" % name, y0, 0.0, 0.01)
        if abs(x0 + x1) * 0.5 > 0.5 or abs(z0 + z1) * 0.5 > 0.5:
            bad.append("(baza) %s necentrat in XZ (%.2f, %.2f)" % (name, (x0 + x1) * 0.5, (z0 + z1) * 0.5))
        if name in HILLS:
            terr = _pts(d, {0, 13})
            ty = max(p[1] for p in terr) if terr else 0.0
            if not 200.0 <= x1 - x0 <= 300.0 or not 30.0 <= ty <= 38.0 or y1 > 38.0:
                bad.append("(deal) %s: %.0f m lung, relieful %.1f m, cu arborii %.1f m; contract "
                           "200-300 / relieful 30-38 / nimic peste 38" % (name, x1 - x0, ty, y1))
            check_cypress(bad, name, d)
        if name in CITIES:
            if not 150.0 <= x1 - x0 <= 250.0 or not 40.0 <= y1 <= 80.0 + 1e-3:
                bad.append("(oras) %s: %.0f m lat, turnul cel mai inalt %.1f m; contract 150-250 / 40-80"
                           % (name, x1 - x0, y1))
            sloped = 0
            for t in d["tris"]:
                n, area = _tri_geo(d, t)
                if area > 1e-6 and 0.02 < abs(n[1]) < 0.98:
                    sloped += 1
            if sloped:
                bad.append("(piramida) %s are %d fete inclinate (doar cutii cu acoperis plat)" % (name, sloped))
            for isl in _islands(d):
                ys = [d["verts"][i][1] for ti in isl for i in d["tris"][ti]]
                ymin, ymax = min(ys), max(ys)
                top = base = 0.0
                for ti in isl:
                    n, area = _tri_geo(d, d["tris"][ti])
                    yc = sum(d["verts"][i][1] for i in d["tris"][ti]) / 3.0
                    if n[1] > 0.98 and yc > ymax - 0.05:
                        top += area
                    if n[1] < -0.98 and yc < ymin + 0.05:
                        base += area
                if base > 1e-6 and top < 0.15 * base:
                    bad.append("(piramida) %s: un volum de %.1f m are capacul %.0f %% din talpa"
                               % (name, ymax - ymin, 100.0 * top / base))
                    break


def check_cypress(bad, name, d):
    """Pâlcurile de chiparos de pe deal: frunzisul (slot 21) grupat pe arbori (insule cu amprentele
    XZ suprapuse), trunchiul (slot 28) legat de pâlcul de deasupra lui. Fiecare pâlc: latimea
    orizontala >= 1,4 x inaltimea frunzisului; la cei cu trunchi, trunchiul gol de sub frunzis
    <= 25 % din inaltimea arborelui (talpa trunchiului -> crestet). Silueta de chiparos de
    Monterey, nu umbrela de salcam pe un bat (§3.1)."""
    ts = _tri_slots(d)
    isl = _islands(d)
    fol, trunks = [], []
    for g in isl:
        ks = {ts[ti] for ti in g}
        ps = [d["verts"][i] for ti in g for i in d["tris"][ti]]
        if ks == {21}:
            fol.append(_box(ps))
        elif ks == {28}:
            trunks.append(_box(ps))
    clumps = []
    for bx in fol:
        hit = [c for c in clumps if bx[0][0] < c[0][1] + 0.5 and c[0][0] < bx[0][1] + 0.5
               and bx[2][0] < c[2][1] + 0.5 and c[2][0] < bx[2][1] + 0.5]
        merged = [list(bx[0]), list(bx[1]), list(bx[2])]
        for c in hit:
            clumps.remove(c)
            for a in range(3):
                merged[a] = [min(merged[a][0], c[a][0]), max(merged[a][1], c[a][1])]
        clumps.append([tuple(m) for m in merged])
    trees = 0
    for c in clumps:
        fw = max(c[0][1] - c[0][0], c[2][1] - c[2][0])
        fh = c[1][1] - c[1][0]
        if fw < 1.4 * fh:
            bad.append("(chiparos) %s: un pâlc are %.1f m latime la %.1f m inaltime (< 1,4x)" % (name, fw, fh))
        for t in trunks:
            tx, tz = (t[0][0] + t[0][1]) * 0.5, (t[2][0] + t[2][1]) * 0.5
            if c[0][0] <= tx <= c[0][1] and c[2][0] <= tz <= c[2][1]:
                trees += 1
                total = c[1][1] - t[1][0]
                bare = c[1][0] - t[1][0]
                if bare > 0.25 * total:
                    bad.append("(chiparos) %s: trunchi gol de %.1f m sub frunzis, %.0f %% din %.1f m"
                               % (name, bare, 100.0 * bare / total, total))
                break
    if trees == 0:
        bad.append("(chiparos) %s: niciun chiparos cu trunchi" % name)


def check_stair(bad, nodes):
    d = nodes.get("StairLane")
    if not d:
        return
    if len(d["tris"]) > 400:
        bad.append("(triunghiuri) %d, plafon 400" % len(d["tris"]))
    (x0, x1), (y0, y1), (z0, z1) = _box(d["verts"])
    _near(bad, "gabarit", "latimea", x1 - x0, 2.5, 0.01)
    _near(bad, "gabarit", "centrul X", (x0 + x1) * 0.5, 0.0, 0.01)
    _near(bad, "gabarit", "baza", y0, 0.0, 0.005)
    _near(bad, "gabarit", "muchia din fata (Z minim)", z0, 0.0, 0.01)
    _near(bad, "gabarit", "capatul de sus (Z maxim)", z1, 5.0, 0.02)
    # treptele si palierele: triunghiurile orizontale cu fata in sus, pe slotul 8, in latimea
    # libera (|x| <= 1,0)
    ts = _tri_slots(d)
    treads = []
    for t, k in zip(d["tris"], ts):
        n, area = _tri_geo(d, t)
        if k == 8 and n[1] > 0.98 and all(abs(d["verts"][i][0]) <= 1.001 for i in t):
            treads.append(d["verts"][t[0]][1])
    if treads:
        rise = max(treads) - min(treads)
        _near(bad, "urcare", "urcarea de la palierul de jos", rise, 3.0, 0.05)
    else:
        bad.append("(urcare) nicio treapta pe slotul 8")
    for side, sg in (("stanga", -1), ("dreapta", 1)):
        w = _pts(d, {8}, lambda p, s=sg: s * p[0] > 0.95)
        th = (max(abs(p[0]) for p in w) - min(abs(p[0]) for p in w)) if w else 0.0
        if th < 0.20 - 1e-3:
            bad.append("(zid) zidul din %s are %.3f m, contract >= 0,20" % (side, th))


def check_lions(bad, nodes):
    d = nodes.get("SeaLions")
    if not d:
        return
    if len(d["tris"]) > 1800:
        bad.append("(triunghiuri) %d, plafon 1800" % len(d["tris"]))
    raft = _pts(d, {23, 9})
    if raft:
        (x0, x1), (_y0, _y1), (z0, z1) = _box(raft)
        _near(bad, "pluta", "lungimea X", x1 - x0, 4.0, 0.05)
        _near(bad, "pluta", "latimea Z", z1 - z0, 3.0, 0.05)
        if abs(x0 + x1) * 0.5 > 0.05 or abs(z0 + z1) * 0.5 > 0.05:
            bad.append("(pluta) necentrata (%.3f, %.3f)" % ((x0 + x1) * 0.5, (z0 + z1) * 0.5))
    else:
        bad.append("(pluta) nicio scandura (sloturile 23/9)")
    (_a, _b), (y0, y1), (_c, _d) = _box(d["verts"])
    if not (y0 < -0.01 and y1 > 0.01):
        bad.append("(pluta) nu incaleca linia apei (Y %.3f..%.3f)" % (y0, y1))
    ts = _tri_slots(d)
    share = sum(1 for k in ts if k in (2, 4)) / float(max(len(ts), 1))
    if share < 0.25:
        bad.append("(lei) doar %.0f %% din triunghiuri pe sloturile 2/4" % (100 * share))


def check(key, path, report=True):
    g, _blob, nodes = load(path)
    bad = []
    _roots_clean(bad, g)
    _forbidden(bad, nodes)
    if key == "sf_turntable":
        _names(bad, g, nodes, ["Turntable_Deck", "Turntable_Booth"])
        check_turntable(bad, nodes)
    elif key in SHEDS:
        name, L = SHEDS[key]
        _names(bad, g, nodes, [name])
        check_shed(bad, nodes, name, L)
    elif key == "sf_island_light":
        _names(bad, g, nodes, ["Island_Rock", "Island_Light"])
        check_island(bad, nodes)
    elif key == "sf_horizon":
        _names(bad, g, nodes, list(HILLS + CITIES))
        check_horizon(bad, nodes)
    elif key == "sf_stair_lane":
        _names(bad, g, nodes, ["StairLane"])
        check_stair(bad, nodes)
    elif key == "sf_sea_lions":
        _names(bad, g, nodes, ["SeaLions"])
        check_lions(bad, nodes)
    if report:
        allv = [p for d in nodes.values() for p in d["verts"]]
        (x0, x1), (y0, y1), (z0, z1) = _box(allv)
        tris = sum(len(d["tris"]) for d in nodes.values())
        print("%-19s X %8.3f..%7.3f  Y %7.3f..%6.3f  Z %8.3f..%7.3f  %5d tri  %s"
              % (key, x0, x1, y0, y1, z0, z1, tris, "OK" if not bad else "PICAT"))
        for line in bad:
            print("   !! " + line)
    return bad


# ------------------------------------------------------------------ selftest
def _uv_where(g, blob, node_name, pred, u):
    import struct
    from measure_sf_bridge import _accessor_slots
    pos = list(_accessor_slots(g, node_name, "POSITION"))
    tex = list(_accessor_slots(g, node_name, "TEXCOORD_0"))
    n = 0
    for (pa, pb, ps_, _k), (_ta, tb, ts, _k2) in zip(pos, tex):
        for i in range(pa["count"]):
            p = struct.unpack_from("<fff", blob, pb + i * ps_)
            uu = struct.unpack_from("<ff", blob, tb + i * ts)[0]
            if pred(p, int(math.floor(uu * 32))):
                struct.pack_into("<ff", blob, tb + i * ts, u, 0.5)
                n += 1
    return n > 0


def _poke_slot(g, blob, node_name, slots, pred, move):
    """Muta varfurile nodului care au slotul in `slots` si satisfac `pred`."""
    import struct
    from measure_sf_bridge import _accessor_slots
    pos = list(_accessor_slots(g, node_name, "POSITION"))
    tex = list(_accessor_slots(g, node_name, "TEXCOORD_0"))
    n = 0
    for (pa, pb, ps_, _k), (_ta, tb, ts, _k2) in zip(pos, tex):
        for i in range(pa["count"]):
            p = struct.unpack_from("<fff", blob, pb + i * ps_)
            uu = struct.unpack_from("<ff", blob, tb + i * ts)[0]
            if int(math.floor(uu * 32)) in slots and pred(p):
                struct.pack_into("<fff", blob, pb + i * ps_, *move(p))
                n += 1
    return n > 0


def _sab_tree(g, blob, node, stretch):
    """Primul chiparos al nodului (talpa celui mai jos trunchi): `stretch` intinde frunzisul in sus
    (coroana mai inalta decat lata); altfel ridica frunzisul cu 8 m (umbrela pe un bat)."""
    _g, _b, nodes = load_from(g, blob)
    d = nodes[node]
    s = _slots(d)
    base = min((p for p, k in zip(d["verts"], s) if k == 28), key=lambda p: p[1])
    near = lambda p: math.hypot(p[0] - base[0], p[2] - base[2]) < 22.0
    fol = [p[1] for p, k in zip(d["verts"], s) if k == 21 and near(p)]
    y0 = min(fol)
    if stretch:
        return _poke_slot(g, blob, node, {21}, near, lambda p: (p[0], y0 + 3.0 * (p[1] - y0), p[2]))
    return _poke_slot(g, blob, node, {21}, near, lambda p: (p[0], p[1] + 8.0, p[2]))


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
    if key == "sf_turntable":
        D, B = "Turntable_Deck", "Turntable_Booth"
        out += [
            ("discul latit cu 10 cm pe X", "disc", _mv(D, lambda p: p[0] > 4.99, lambda p: (p[0] + 0.1, p[1], p[2]))),
            ("o sina inaltata la +0,20", "pe disc",
             lambda g, b: poke_all(g, b, D, lambda p: 0.09 < p[1] < 0.11 and 0.5 < p[0] < 0.7, lambda p: (p[0], 0.20, p[2])) > 0),
            ("scandurile coborate la +0,03", "disc",
             lambda g, b: poke_all(g, b, D, lambda p: abs(p[1] - 0.05) < 0.001 and math.hypot(p[0], p[2]) < 4.43,
                      lambda p: (p[0], 0.03, p[2])) > 0),
            ("sina din dreapta mutata 5 cm spre exterior (ecartament 1,15)", "sine",
             _mv(D, lambda p: 0.54 < p[0] < 0.70 and p[1] > 0.06, lambda p: (p[0] + 0.05, p[1], p[2]))),
            ("sinele rotite pe X (o sina de-a curmezis)", "sine",
             lambda g, b: _uv_where(g, b, D, lambda p, k: k == 11 and p[0] > 0 and abs(p[2]) > 1.0, 6.5 / 32)
             and _uv_where(g, b, D, lambda p, k: k in (9, 27) and abs(p[2]) < 0.2 and p[1] > 0.049, 11.5 / 32)),
            ("ghereta intrata 0,5 m pe disc", "ghereta", _mv(B, lambda p: True, lambda p: (p[0] - 0.5, p[1], p[2]))),
            ("ghereta inaltata la 3,0 m", "ghereta", _mv(B, lambda p: p[1] > 2.59, lambda p: (p[0], 3.0, p[2]))),
        ]
    elif key in SHEDS:
        name, L = SHEDS[key]
        out += [
            ("peretii latiti cu 0,5 m", "amprenta",
             _mv(name, lambda p: abs(p[0] - 6.0) < 0.001 and p[1] > 0.3, lambda p: (6.5, p[1], p[2]))),
            ("acoperisul inaltat la +9,5", "cheia", _mv(name, lambda p: p[1] > 8.9, lambda p: (p[0], p[1] + 0.5, p[2]))),
            ("puntea ridicata cu 10 cm", "punte",
             _mv(name, lambda p: abs(p[1]) < 0.001 and abs(p[0]) > 6.5, lambda p: (p[0], 0.10, p[2]))),
            ("pilonii scurtati la -4", "piloni", _mv(name, lambda p: p[1] < -5.9, lambda p: (p[0], -4.0, p[2]))),
            ("magazia intoarsa (usa pe +Z)", "fronton", _mv(name, lambda p: True, lambda p: (-p[0], p[1], -p[2]))),
            ("peretii inapoi pe SAND_MID 1 (portocaliul de la 8c)", "lemn",
             lambda g, b: _uv_where(g, b, name, lambda p, k: k == SHED_WALL_SLOT and p[1] > 0.3, 1.5 / 32)),
            ("sipcile inapoi pe WOOD 9", "lemn",
             lambda g, b: _uv_where(g, b, name, lambda p, k: k == 6 and 0.3 < p[1] < 5.2
                                    and abs(abs(p[0]) - 6.0) < 0.06, 9.5 / 32)),
        ]
    elif key == "sf_island_light":
        out += [
            ("stanca intinsa la 80 m", "stanca", _mv("Island_Rock", lambda p: p[0] > 25.0, lambda p: (p[0] + 15.0, p[1], p[2]))),
            ("fusta ridicata la -1", "stanca", _mv("Island_Rock", lambda p: p[1] < -2.9, lambda p: (p[0], -1.0, p[2]))),
            ("farul inaltat cu 2 m", "far", _mv("Island_Light", lambda p: p[1] > 24.0, lambda p: (p[0], p[1] + 2.0, p[2]))),
            ("turnul vopsit gri (slot 29)", "far",
             lambda g, b: _uv_where(g, b, "Island_Light", lambda p, k: k == 22, 29.5 / 32)),
        ]
    elif key == "sf_horizon":
        out += [
            ("Hill_B ridicat cu 3 m", "baza", _mv("Hill_B", lambda p: True, lambda p: (p[0], p[1] + 3.0, p[2]))),
            ("Hill_A ridicat la 50 m", "deal",
             _mv("Hill_A", lambda p: p[1] > 25.0, lambda p: (p[0], p[1] + 15.0, p[2]))),
            ("chiparosul intins in sus (frunzisul de 3x mai inalt)", "chiparos",
             lambda g, b: _sab_tree(g, b, "Hill_B", stretch=True)),
            ("chiparosul ridicat pe un bat (frunzisul +8 m)", "chiparos",
             lambda g, b: _sab_tree(g, b, "Hill_C", stretch=False)),
            ("City_A ingustat la 120 m", "oras", _mv("City_A", lambda p: True, lambda p: (p[0] * 0.5, p[1], p[2]))),
            ("varful unui turn tras in centru (piramida)", "piramida",
             lambda g, b: _pyramid(g, b, "City_B")),
            ("City_A mutat 5 m pe X", "baza", _mv("City_A", lambda p: True, lambda p: (p[0] + 5.0, p[1], p[2]))),
        ]
    elif key == "sf_stair_lane":
        N = "StairLane"
        out += [
            ("scara latita cu 0,2 m", "gabarit", _mv(N, lambda p: p[0] > 1.24, lambda p: (p[0] + 0.2, p[1], p[2]))),
            ("scara intoarsa (urca spre -Z)", "gabarit", _mv(N, lambda p: True, lambda p: (p[0], p[1], -p[2]))),
            ("palierul de sus ridicat cu 0,5 m", "urcare",
             _mv(N, lambda p: abs(p[0]) < 1.001 and p[2] > 4.39 and p[1] > 3.0, lambda p: (p[0], p[1] + 0.5, p[2]))),
            ("zidul din dreapta subtiat la 0,10", "zid",
             _mv(N, lambda p: abs(p[0] - 1.0) < 0.001, lambda p: (1.15, p[1], p[2]))),
        ]
    elif key == "sf_sea_lions":
        N = "SeaLions"
        out += [
            ("pluta lungita la 4,5 m", "pluta", _mv(N, lambda p: p[0] > 1.99 and 0.19 < p[1] < 0.31,
                                                    lambda p: (p[0] + 0.5, p[1], p[2]))),
            ("pluta ridicata peste apa", "pluta", _mv(N, lambda p: True, lambda p: (p[0], p[1] + 0.5, p[2]))),
            ("leii vopsiti in lemn (slot 9)", "lei",
             lambda g, b: _uv_where(g, b, N, lambda p, k: k in (2, 4), 9.5 / 32)),
        ]
    return out


def _pyramid(g, blob, node):
    """Varful celui mai inalt turn: toate varfurile de pe capac trase in centrul capacului."""
    _g, _b, nodes = load_from(g, blob)
    d = nodes[node]
    top = max(p[1] for p in d["verts"])
    cap = [p for p in d["verts"] if p[1] > top - 1e-3]
    cx = sum(p[0] for p in cap) / len(cap)
    cz = sum(p[2] for p in cap) / len(cap)
    return poke_all(g, blob, node, lambda p: p[1] > top - 1e-3, lambda p: (cx, p[1], cz)) > 0


def load_from(g, blob):
    tmp = os.path.join(tempfile.mkdtemp(prefix="sfstruct_pyr_"), "x.glb")
    _write_glb(tmp, g, blob)
    out = load(tmp)
    os.remove(tmp)
    os.rmdir(os.path.dirname(tmp))
    return out


def selftest(keys):
    ok = True
    tmp = tempfile.mkdtemp(prefix="sfstruct_sabotaj_")
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
            print("   %-58s -> pica pe %-28s %s" % (label, ",".join(hit) or "NIMIC",
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
    print("GARDA STRUCTURILOR SF: %s" % ("OK (%d piese)" % len(keys) if not failed else "ESUAT: %s" % ", ".join(failed)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
