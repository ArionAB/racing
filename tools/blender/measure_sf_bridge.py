"""Garda de gabarit a kitului podului rosu -- citeste GLB-urile EXPORTATE (glTF
JSON + accesoare + transformarile nodurilor), in coordonatele GODOT ale podului
(X de-a lungul podului, Y sus, 0 = fata carosabilului, Z lateral, 0 = axa).
Contractul e brief-ul docs/asset_briefs/sf_red_bridge.md §3-§6.

    python tools/blender/measure_sf_bridge.py                  # toate piesele
    python tools/blender/measure_sf_bridge.py tower parapet_8  # doar unele
    python tools/blender/measure_sf_bridge.py --selftest       # garda PICA pe sabotaje

Gabaritul se masoara PE TRIUNGHI (test de separare pe axe intre triunghi si
cutia interzisa), nu din AABB-ul piesei: o traversa al carei fund coboara cu
un singur colt sub +13,8 pica, chiar daca AABB-ul piesei e corect.

Verificari (cheia din paranteza apare in mesajul de esec):
  toate   (noduri)  numele nodurilor exact cele cerute, copii directi ai radacinii
          (xform)   radacinile fara scala/rotatie/translatie (piesele stau pe cadru)
          (sloturi) Steel = {7} (felinarul {7, 22}), Concrete = {8}; UV pe centre
          (ao)      COLOR_0 prezent pe fiecare nod
  tower   (gabarit1) nimic in |Z| < 12,2 pentru Y in [-0,3, +13,8]
          (gabarit2) nimic intre picioare, |Z| < 13,0, pentru Y in [-0,3, +13,8]
          (traversa) fundul otelului dintre picioare >= +13,8
          (patrat)   tot otelul cu |Z| > 13,0 sta in X +-1,5, |Z| <= 16,0
          (inaltime) otelul pe Y -30..+45
          (ingustare) piciorul sus (Y 41,5..42,3) are semilatimea 1,10..1,25
          (pila)     betonul in X +-4,5, |Z| <= 19, Y -30..-16
  deck_8  (gabarit3) nimic peste Y -0,3 pe |Z| < 15,9
          (cote)     X -0,3..8, Y -4..+0,25, |Z| <= 16,6
  parapet_8 (drum)   nimic pe |Z| < 12,2 ; (fata) fata interioara EXACT la 12,2
          (grosime)  |Z| <= 12,85; peste 12,7 doar mana curenta (Y >= 0,9) sau
                     montantii (X impar +-0,12); (cote) X 0..8, Y 0..1,2
  flares  (drum)     nimic pe |Z| < 12,2 ; (perete) in cadrul peretelui rotit cu
                     20 de grade: n in [0, 0,65], s in [0, 10]; (colt) fata
                     interioara trece prin (0, 12,2) si (-9,397, 15,620)
  cable_* (gabarit)  nimic pe |Z| < 13,0 ; (cablu) centrul cablului pe parabola
                     brief-ului, diametrul >= 0,98 ; (tirant) diametrul >= 0,349,
                     capatul de jos la Y 0,2..0,26
  anchor  (gabarit)  nimic pe |Z| < 13,2 peste Y -0,3 ; (cote) X -6..2,
                     Y -24..6, |Z| <= 17,8 ; (culee) X -1..1, sub Y -1
          (gura)     gura cusetei e LIBERA (X 1,8..2,0, Y 3,5..4,5, |Z| 14..15)
  walkway_8 (drum)   nimic pe |Z| < 12,7 ; (trotuar) fata de sus a betonului la
                     Y +0,20 ; (cote) X 0..8, |Z| <= 16,4
  lamp    (baza)     Y 0..6,0 ; (raza) totul in 0,40 m de ax ; (stalp) raza
                     stalpului 0,15
Iese cu cod 1 la orice incalcare.
"""
import json
import math
import os
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import COMPONENT, NCOMP, load_glb, read_accessor  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MODELS = os.path.join(ROOT, "assets", "models", "sanfrancisco", "structures")
TOL = 2e-3          # praf numeric de float32 + bevel, NU toleranta de proiectare
BIG = 1000.0

PIECES = ["tower", "deck_8", "parapet_8", "flares", "cable_main", "cable_side",
          "anchor", "walkway_8", "lamp"]
NODES = {
    "tower": ["Tower_Concrete", "Tower_Steel"],
    "deck_8": ["Deck_Steel"],
    "parapet_8": ["Parapet_Steel"],
    "flares": ["Flares_Steel"],
    "cable_main": ["CableMain_Steel"],
    "cable_side": ["CableSide_Steel"],
    "anchor": ["Anchor_Concrete", "Anchor_Steel"],
    "walkway_8": ["Walkway_Concrete", "Walkway_Steel"],
    "lamp": ["Lamp_Concrete", "Lamp_Steel"],
}


# --- citirea GLB-ului ------------------------------------------------------------

def quat_rot(q, v):
    x, y, z, w = q
    cx = (y * v[2] - z * v[1], z * v[0] - x * v[2], x * v[1] - y * v[0])
    cc = (y * cx[2] - z * cx[1], z * cx[0] - x * cx[2], x * cx[1] - y * cx[0])
    return tuple(v[i] + 2 * (w * cx[i] + cc[i]) for i in range(3))


def load(path):
    """-> dict nod -> {"verts", "tris", "uv", "color"}, plus json-ul si blob-ul."""
    g, blob = load_glb(path)[:2]
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

    nodes = {}
    for i, n in enumerate(g["nodes"]):
        if "mesh" not in n:
            continue
        name = n.get("name") or ""
        d = nodes.setdefault(name, {"verts": [], "tris": [], "uv": [], "color": True,
                                    "root": i not in parent})
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            a = prim["attributes"]
            base = len(d["verts"])
            d["verts"] += [xf(i, p) for p in read_accessor(g, blob, a["POSITION"])]
            d["uv"] += read_accessor(g, blob, a["TEXCOORD_0"]) if "TEXCOORD_0" in a else []
            d["color"] = d["color"] and "COLOR_0" in a
            idx = [k[0] for k in read_accessor(g, blob, prim["indices"])]
            d["tris"] += [(base + idx[t], base + idx[t + 1], base + idx[t + 2])
                          for t in range(0, len(idx) - 2, 3)]
    return g, blob, nodes


# --- triunghi contra cutie (Akenine-Moller, separare pe 13 axe) ------------------

def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def tri_box(tri, lo, hi):
    """True daca triunghiul (3 puncte) intersecteaza INTERIORUL cutiei [lo, hi]."""
    c = tuple(0.5 * (lo[i] + hi[i]) for i in range(3))
    h = tuple(0.5 * (hi[i] - lo[i]) for i in range(3))
    v = [_sub(p, c) for p in tri]
    for i in range(3):
        if min(p[i] for p in v) >= h[i] or max(p[i] for p in v) <= -h[i]:
            return False
    e = [_sub(v[1], v[0]), _sub(v[2], v[1]), _sub(v[0], v[2])]
    nrm = _cross(e[0], e[1])
    r = h[0] * abs(nrm[0]) + h[1] * abs(nrm[1]) + h[2] * abs(nrm[2])
    if abs(_dot(nrm, v[0])) >= r and r > 0:
        return False
    axes = [(1, 0, 0), (0, 1, 0), (0, 0, 1)]
    for ed in e:
        for ax in axes:
            a = _cross(ax, ed)
            if a == (0, 0, 0):
                continue
            ps = [_dot(a, p) for p in v]
            r = h[0] * abs(a[0]) + h[1] * abs(a[1]) + h[2] * abs(a[2])
            if min(ps) >= r or max(ps) <= -r:
                return False
    return True


def hits(nodes, lo, hi, names=None):
    """Triunghiurile care intra in cutia (lo, hi); cutia e stransa cu TOL."""
    lo = tuple(x + TOL for x in lo)
    hi = tuple(x - TOL for x in hi)
    out = []
    for name, d in nodes.items():
        if names and name not in names:
            continue
        vs = d["verts"]
        for t in d["tris"]:
            tri = (vs[t[0]], vs[t[1]], vs[t[2]])
            if any(min(p[i] for p in tri) >= hi[i] or max(p[i] for p in tri) <= lo[i] for i in range(3)):
                continue
            if tri_box(tri, lo, hi):
                out.append((name, tri))
    return out


def _fmt_hit(h):
    name, tri = h
    return "%s (%.3f, %.3f, %.3f)" % ((name,) + tuple(min(p[i] for p in tri) for i in range(3)))


def verts(nodes, names=None):
    return [p for n, d in nodes.items() if not names or n in names for p in d["verts"]]


# --- verificarile comune -----------------------------------------------------------

def common(key, g, nodes):
    bad = []
    names = sorted(nodes)
    if names != sorted(NODES[key]):
        bad.append("(noduri) %s, cerute %s" % (names, sorted(NODES[key])))
    for name, d in nodes.items():
        if not d["root"]:
            bad.append("(noduri) %s nu e copil direct al radacinii" % name)
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    for i, n in enumerate(g["nodes"]):
        if i in kids:
            continue
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        t = n.get("translation", [0, 0, 0])
        if (any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3))
                or any(abs(v) > 1e-4 for v in t)):
            bad.append("(xform) radacina %s: scala %s rotatie %s translatie %s" % (n.get("name"), s, r, t))
        if "mesh" not in n and not n.get("children"):
            bad.append("(noduri) nod gol %s" % n.get("name"))
    for name, d in nodes.items():
        want = {8} if name.endswith("_Concrete") else ({7, 22} if name == "Lamp_Steel" else {7})
        got, off = set(), 0
        for u, v in d["uv"]:
            sl = int(math.floor(u * 32))
            got.add(sl)
            if abs(u - (sl + 0.5) / 32) > 1e-4 or abs(v - 0.5) > 1e-4:
                off += 1
        if got != want:
            bad.append("(sloturi) %s are sloturile %s, cerute %s" % (name, sorted(got), sorted(want)))
        if off:
            bad.append("(sloturi) %s: %d UV-uri in afara centrelor de slot" % (name, off))
        if not d["color"]:
            bad.append("(ao) %s fara COLOR_0" % name)
    return bad


def rng(ps, i):
    return min(p[i] for p in ps), max(p[i] for p in ps)


# --- contractele per piesa ------------------------------------------------------------

def check_tower(nodes, rep):
    bad = []
    h1 = hits(nodes, (-BIG, -0.3, -12.2), (BIG, 13.8, 12.2))
    if h1:
        bad.append("(gabarit1) %d triunghiuri in |Z|<12,2, Y -0,3..13,8, primul %s" % (len(h1), _fmt_hit(h1[0])))
    h2 = hits(nodes, (-BIG, -0.3, -13.0), (BIG, 13.8, 13.0))
    if h2:
        bad.append("(gabarit2) %d triunghiuri intre picioare sub +13,8, primul %s" % (len(h2), _fmt_hit(h2[0])))
    st = verts(nodes, ["Tower_Steel"])
    mid = [p for p in st if abs(p[2]) < 13.0 - TOL and p[1] > -0.3]
    under = min(p[1] for p in mid) if mid else 99.0
    rep.append("fundul otelului dintre picioare (|Z|<13): Y %.3f (>= 13,8)" % under)
    if under < 13.8 - 1e-4:
        bad.append("(traversa) fundul traversei de jos la %.3f < 13,8" % under)
    outside = [p for p in st if abs(p[2]) > 13.0 + TOL]
    xs, zs = rng(outside, 0), (min(abs(p[2]) for p in outside), max(abs(p[2]) for p in outside))
    rep.append("picioarele (otel cu |Z|>13): X %.3f..%.3f  |Z| %.3f..%.3f  (patrat X +-1,5, |Z| 13..16)"
               % (xs[0], xs[1], zs[0], zs[1]))
    if xs[0] < -1.5 - TOL or xs[1] > 1.5 + TOL or zs[1] > 16.0 + TOL:
        bad.append("(patrat) picioarele ies din patratul de 3 x 3: X %.3f..%.3f, |Z| pana la %.3f"
                   % (xs[0], xs[1], zs[1]))
    ys = rng(st, 1)
    rep.append("otelul Y %.3f..%.3f" % ys)
    if abs(ys[0] + 30.0) > 0.01 or abs(ys[1] - 45.0) > 0.01:
        bad.append("(inaltime) otelul pe Y %.3f..%.3f, cerut -30..+45" % ys)
    # anvelopa piciorului pe fata exterioara (|Z| > 14,5: acolo nu ajung
    # traversele): sus, sub capitel (Y 36..42,39), si jos (Y -16..-11)
    def env(y0, y1):
        e = [abs(p[2]) - 14.5 for p in st if y0 <= p[1] <= y1 and abs(p[2]) > 14.5]
        return max(e) if e else 0.0
    hw_top, hw_bot = env(36.0, 42.39), env(-16.0, -11.0)
    rep.append("semilatimea anvelopei piciorului: jos %.3f, sus %.3f (3,0 -> 2,4 m)" % (hw_bot, hw_top))
    if not (1.15 <= hw_top <= 1.25 and hw_bot >= 1.45):
        bad.append("(ingustare) anvelopa piciorului jos %.3f / sus %.3f, cerute ~1,5 / 1,15..1,25"
                   % (hw_bot, hw_top))
    co = verts(nodes, ["Tower_Concrete"])
    if co:
        cx, cy = rng(co, 0), rng(co, 1)
        cz = max(abs(p[2]) for p in co)
        rep.append("pila: X %.3f..%.3f  Y %.3f..%.3f  |Z| <= %.3f" % (cx + cy + (cz,)))
        if cx[0] < -4.5 - TOL or cx[1] > 4.5 + TOL or cz > 19.0 + TOL or cy[0] < -30 - TOL or cy[1] > -16 + TOL:
            bad.append("(pila) betonul iese din X +-4,5, |Z| 19, Y -30..-16")
    return bad


def check_deck(nodes, rep):
    bad = []
    h = hits(nodes, (-BIG, -0.3, -15.9), (BIG, BIG, 15.9))
    if h:
        bad.append("(gabarit3) %d triunghiuri peste Y -0,3 pe |Z|<15,9, primul %s" % (len(h), _fmt_hit(h[0])))
    ps = verts(nodes)
    x, y = rng(ps, 0), rng(ps, 1)
    z = max(abs(p[2]) for p in ps)
    rep.append("X %.3f..%.3f  Y %.3f..%.3f  |Z| <= %.3f" % (x + y + (z,)))
    if x[0] < -0.3 - TOL or x[1] > 8.0 + TOL or y[0] < -4.0 - TOL or y[1] > 0.25 + TOL or z > 16.6 + TOL:
        bad.append("(cote) tablierul iese din X -0,3..8, Y -4..0,25, |Z| 16,6")
    return bad


def _wall_face_area(nodes, test):
    """Aria triunghiurilor ale caror varfuri satisfac toate `test`."""
    a = 0.0
    for d in nodes.values():
        vs = d["verts"]
        for t in d["tris"]:
            tri = [vs[k] for k in t]
            if all(test(p) for p in tri):
                c = _cross(_sub(tri[1], tri[0]), _sub(tri[2], tri[0]))
                a += 0.5 * math.sqrt(_dot(c, c))
    return a


def check_parapet(nodes, rep):
    bad = []
    h = hits(nodes, (-BIG, -BIG, -12.2), (BIG, BIG, 12.2))
    if h:
        bad.append("(drum) %d triunghiuri spre drum (|Z|<12,2), primul %s" % (len(h), _fmt_hit(h[0])))
    ps = verts(nodes)
    zmin = min(abs(p[2]) for p in ps)
    zmax = max(abs(p[2]) for p in ps)
    face = {s: _wall_face_area(nodes, lambda p, s=s: abs(p[2] - s * 12.2) < 1e-3) for s in (1, -1)}
    rep.append("fata interioara |Z| min %.4f; aria la exact 12,2: +Z %.2f m2, -Z %.2f m2; |Z| max %.3f"
               % (zmin, face[1], face[-1], zmax))
    if abs(zmin - 12.2) > 1e-3 or min(face.values()) < 2.0:
        bad.append("(fata) fata interioara nu e la 12,2 (min %.4f, arie %.2f/%.2f m2)" % (zmin, face[1], face[-1]))
    if zmax > 12.85 + TOL:
        bad.append("(grosime) parapetul iese la |Z| %.3f > 12,85" % zmax)
    thick = [p for p in ps if abs(p[2]) > 12.7 + TOL and p[1] < 0.9
             and min(abs(p[0] - c) for c in (1.0, 3.0, 5.0, 7.0)) > 0.12 + TOL]
    if thick:
        bad.append("(grosime) %d varfuri peste 12,7 care nu sunt mana curenta/montanti, primul %s"
                   % (len(thick), thick[0]))
    x, y = rng(ps, 0), rng(ps, 1)
    rep.append("X %.3f..%.3f  Y %.3f..%.3f" % (x + y))
    if x[0] < -TOL or x[1] > 8 + TOL or y[0] < -TOL or y[1] > 1.2 + TOL:
        bad.append("(cote) parapetul iese din X 0..8, Y 0..1,2")
    return bad


def check_flares(nodes, rep):
    bad = []
    h = hits(nodes, (-BIG, -BIG, -12.2), (BIG, BIG, 12.2))
    if h:
        bad.append("(drum) %d triunghiuri spre drum (|Z|<12,2), primul %s" % (len(h), _fmt_hit(h[0])))
    ca, sa = math.cos(math.radians(20)), math.sin(math.radians(20))
    ps = verts(nodes)
    ns, ss = [], []
    for x, y, z in ps:
        dz = abs(z) - 12.2
        ns.append(x * sa + dz * ca)
        ss.append(-x * ca + dz * sa)
    rep.append("in cadrul peretelui: n %.3f..%.3f (0..0,65)  s %.3f..%.3f (0..10)"
               % (min(ns), max(ns), min(ss), max(ss)))
    if min(ns) < -TOL or max(ns) > 0.65 + TOL or min(ss) < -TOL or max(ss) > 10.0 + TOL:
        bad.append("(perete) peretele iese din profil: n %.3f..%.3f, s %.3f..%.3f"
                   % (min(ns), max(ns), min(ss), max(ss)))
    for sz in (1, -1):              # pe AMBELE parti, nu doar pe una
        for px, pz in ((0.0, 12.2), (-9.397, 15.620)):
            near = min(math.hypot(p[0] - px, p[2] - sz * pz) for p in ps)
            if near > 0.01:
                bad.append("(colt) fata interioara nu trece prin (%.3f, %+.3f): cel mai aproape %.3f"
                           % (px, sz * pz, near))
    return bad


def check_cable(nodes, rep, main):
    bad = []
    h = hits(nodes, (-BIG, -BIG, -13.0), (BIG, BIG, 13.0))
    if h:
        bad.append("(gabarit) %d triunghiuri pe |Z|<13, primul %s" % (len(h), _fmt_hit(h[0])))
    ps = verts(nodes)
    if main:
        def f(x):
            return 3.0 + 41.5 * ((x - 50.0) / 50.0) ** 2
        probes = (45.0, 25.0, 75.0)
        hanger_x = 10.0
    else:
        def f(x):
            return 4.0 + 40.5 * ((x + 50.0) / 50.0) ** 2
        probes = (-45.0, -25.0, -15.0)
        hanger_x = -10.0
    for xp in probes:
        sel = [p for p in ps if abs(p[0] - xp) < 0.6 and p[2] > 0 and p[1] > 1.2]
        if not sel:
            bad.append("(cablu) niciun varf de cablu la X %.1f" % xp)
            continue
        yc = 0.5 * (min(p[1] for p in sel) + max(p[1] for p in sel))
        dz = max(math.dist(a, b) for a in sel for b in sel)
        rep.append("cablul la X %6.1f: centrul Y %.3f (parabola %.3f)  diametrul %.3f"
                   % (xp, yc, f(xp), dz))
        if abs(yc - f(xp)) > 0.15:
            bad.append("(cablu) la X %.1f centrul la Y %.3f, parabola cere %.3f" % (xp, yc, f(xp)))
        if dz < 0.98:
            bad.append("(cablu) diametrul %.3f < 1,0 la X %.1f" % (dz, xp))
    sel = []
    for d in nodes.values():
        for t in d["tris"]:
            tri = [d["verts"][k] for k in t]
            if (all(abs(p[0] - hanger_x) < 0.3 and p[2] > 0 for p in tri)
                    and max(p[1] for p in tri) - min(p[1] for p in tri) > 5.0):
                sel += tri
    dmax = max((math.hypot(a[0] - b[0], a[2] - b[2]) for a in sel for b in sel), default=0.0)
    ymin = min(p[1] for p in ps)
    rep.append("tirantul la X %.0f: diametrul %.3f ; capatul de jos Y %.3f" % (hanger_x, dmax, ymin))
    if dmax < 0.349:
        bad.append("(tirant) diametrul tirantului %.3f < 0,35" % dmax)
    if not 0.2 - TOL <= ymin <= 0.26:
        bad.append("(tirant) capatul de jos la Y %.3f, cerut 0,2..0,26" % ymin)
    return bad


def check_anchor(nodes, rep):
    bad = []
    h = hits(nodes, (-BIG, -0.3, -13.2), (BIG, BIG, 13.2))
    if h:
        bad.append("(gabarit) %d triunghiuri pe |Z|<13,2 peste Y -0,3, primul %s" % (len(h), _fmt_hit(h[0])))
    ps = verts(nodes)
    x, y = rng(ps, 0), rng(ps, 1)
    z = max(abs(p[2]) for p in ps)
    rep.append("X %.3f..%.3f  Y %.3f..%.3f  |Z| <= %.3f" % (x + y + (z,)))
    if x[0] < -6 - TOL or x[1] > 2 + TOL or y[0] < -24 - TOL or y[1] > 6 + TOL or z > 17.8 + TOL:
        bad.append("(cote) ancorajul iese din X -6..2, Y -24..6, |Z| 17,8")
    # culeea: tot ce e pe |Z| < 13,2 sta in X -1..1, sub Y -1,0 (pe triunghiuri)
    cul = (hits(nodes, (-BIG, -1.0, -13.2), (BIG, BIG, 13.2))
           + hits(nodes, (-BIG, -BIG, -13.2), (-1.0, BIG, 13.2))
           + hits(nodes, (1.0, -BIG, -13.2), (BIG, BIG, 13.2)))
    rep.append("culeea (|Z| < 13,2): %d triunghiuri in afara X -1..1 / peste Y -1" % len(cul))
    if cul:
        bad.append("(culee) culeea iese din X -1..1 sau urca peste Y -1: %s" % _fmt_hit(cul[0]))
    for s in (1, -1):
        z0, z1 = sorted((s * 14.0, s * 15.0))
        g = hits(nodes, (1.8, 3.5, z0), (2.0, 4.5, z1))
        if g:
            bad.append("(gura) gura cusetei de la Z %+.1f e astupata: %s" % (s * 14.5, _fmt_hit(g[0])))
    return bad


def check_walkway(nodes, rep):
    bad = []
    h = hits(nodes, (-BIG, -BIG, -12.7), (BIG, BIG, 12.7))
    if h:
        bad.append("(drum) %d triunghiuri pe |Z|<12,7, primul %s" % (len(h), _fmt_hit(h[0])))
    co = verts(nodes, ["Walkway_Concrete"])
    top = max(p[1] for p in co)
    ps = verts(nodes)
    x = rng(ps, 0)
    z = (min(abs(p[2]) for p in ps), max(abs(p[2]) for p in ps))
    rep.append("fata de sus a trotuarului Y %.3f ; X %.3f..%.3f  |Z| %.3f..%.3f" % ((top,) + x + z))
    if abs(top - 0.20) > 0.005:
        bad.append("(trotuar) fata de sus la Y %.3f, ceruta 0,20" % top)
    if x[0] < -TOL or x[1] > 8 + TOL or z[1] > 16.4 + TOL:
        bad.append("(cote) trotuarul iese din X 0..8, |Z| 16,4")
    return bad


def check_lamp(nodes, rep):
    bad = []
    ps = verts(nodes)
    y = rng(ps, 1)
    r = max(math.hypot(p[0], p[2]) for p in ps)
    pole = [math.hypot(p[0], p[2]) for d in nodes.values() for t in d["tris"]
            for p in [d["verts"][k] for k in t]
            if min(d["verts"][k][1] for k in t) < 2.0 and max(d["verts"][k][1] for k in t) > 4.0]
    pr = max(pole) if pole else 0.0
    rep.append("Y %.3f..%.3f ; raza maxima %.3f ; raza stalpului %.3f" % (y + (r, pr)))
    if abs(y[0]) > TOL or abs(y[1] - 6.0) > 0.05:
        bad.append("(baza) felinarul pe Y %.3f..%.3f, cerut 0..6,0 (originea la baza)" % y)
    if r > 0.40 + TOL:
        bad.append("(raza) felinarul iese la %.3f m de ax (> 0,40)" % r)
    if abs(pr - 0.15) > 0.01:
        bad.append("(stalp) raza stalpului %.3f, ceruta 0,15" % pr)
    return bad


CHECKS = {
    "tower": check_tower, "deck_8": check_deck, "parapet_8": check_parapet,
    "flares": check_flares, "cable_main": lambda n, r: check_cable(n, r, True),
    "cable_side": lambda n, r: check_cable(n, r, False), "anchor": check_anchor,
    "walkway_8": check_walkway, "lamp": check_lamp,
}


def check(key, path, report=True):
    g, blob, nodes = load(path)
    rep = []
    bad = common(key, g, nodes)
    if sorted(nodes) == sorted(NODES[key]):
        bad += CHECKS[key](nodes, rep)
    if report:
        tris = ", ".join("%s %d" % (n, len(d["tris"])) for n, d in sorted(nodes.items()))
        print("-- sf_bridge_%s  [%s]" % (key, tris))
        for line in rep:
            print("   " + line)
        for b in bad:
            print("   !! " + b)
        print("   %s" % ("OK" if not bad else "ESUAT"))
    return bad


# --- sabotajele pentru --selftest ---------------------------------------------------------

def _write_glb(path, g, blob):
    js = json.dumps(g, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    blob = bytes(blob) + b"\0" * ((4 - len(blob) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(blob)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, total))
        fh.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        fh.write(struct.pack("<II", len(blob), 0x004E4942) + blob)


def _roots(g):
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    return [n for i, n in enumerate(g["nodes"]) if i not in kids]


def _accessor_slots(g, node_name, attr):
    for n in g["nodes"]:
        if n.get("name") == node_name and "mesh" in n:
            for prim in g["meshes"][n["mesh"]]["primitives"]:
                acc = g["accessors"][prim["attributes"][attr]]
                fmt, size = COMPONENT[acc["componentType"]]
                k = NCOMP[acc["type"]]
                bv = g["bufferViews"][acc["bufferView"]]
                base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
                stride = bv.get("byteStride") or size * k
                yield acc, base, stride, k
    return


def poke(g, blob, node_name, pred, move):
    """Muta PRIMUL varf al nodului care satisface `pred` cu `move(p) -> p'`
    (scris direct in blob). Intoarce True daca a gasit unul."""
    for acc, base, stride, k in _accessor_slots(g, node_name, "POSITION"):
        for i in range(acc["count"]):
            p = struct.unpack_from("<fff", blob, base + i * stride)
            if pred(p):
                struct.pack_into("<fff", blob, base + i * stride, *move(p))
                return True
    return False


def poke_all(g, blob, node_name, pred, move):
    n = 0
    for acc, base, stride, k in _accessor_slots(g, node_name, "POSITION"):
        for i in range(acc["count"]):
            p = struct.unpack_from("<fff", blob, base + i * stride)
            if pred(p):
                struct.pack_into("<fff", blob, base + i * stride, *move(p))
                n += 1
    return n


def set_uv(g, blob, node_name, u):
    for acc, base, stride, k in _accessor_slots(g, node_name, "TEXCOORD_0"):
        struct.pack_into("<ff", blob, base, u, 0.5)
        return True
    return False


def sabotages(key):
    """(eticheta, cheia de esec asteptata, functie(g, blob)) -- fiecare atinge o
    singura verificare, ca sa se vada ca FIECARE pica singura."""
    first = NODES[key][-1]

    def rename(g, blob):
        for n in g["nodes"]:
            if n.get("name") == first:
                n["name"] = first + "X"

    def rotate(g, blob):
        for n in _roots(g):
            n["rotation"] = [0.0, 0.0871557, 0.0, 0.9961947]      # 10 grade in jurul lui Y

    def scale(g, blob):
        for n in _roots(g):
            n["scale"] = [1.001, 1.0, 1.0]

    def slot30(g, blob):
        set_uv(g, blob, NODES[key][0], (30 + 0.5) / 32)

    def shift(dx=0.0, dy=0.0, dz=0.0):
        def f(g, blob):
            for n in _roots(g):
                t = n.get("translation", [0, 0, 0])
                n["translation"] = [t[0] + dx, t[1] + dy, t[2] + dz]
        return f

    def vpoke(node, pred, move, every=False):
        def f(g, blob):
            n = poke_all(g, blob, node, pred, move) if every else poke(g, blob, node, pred, move)
            assert n, "sabotaj fara tinta: %s" % node
        return f

    out = [("nod redenumit", "noduri", rename), ("radacina rotita 10 grade", "xform", rotate),
           ("scala 1,001 pe radacina", "xform", scale), ("un UV mutat pe slotul 30", "sloturi", slot30)]
    if key == "tower":
        out += [
            ("rostul traversei de jos coborat la 13,6", "traversa",
             vpoke("Tower_Steel", lambda p: abs(p[1] - 13.89) < 0.02 and abs(p[2]) < 1.0,
                   lambda p: (p[0], 13.6, p[2]))),
            ("un varf de coltar tras la Y 5, intre picioare", "gabarit2",
             vpoke("Tower_Steel", lambda p: 11.0 < p[2] < 12.2 and 16.0 < p[1] < 18.0,
                   lambda p: (p[0], 5.0, 12.6))),
            ("un varf de picior impins la |Z| 12,0, Y 5", "gabarit1",
             vpoke("Tower_Steel", lambda p: p[2] > 13 and 3.0 < p[1] < 7.0,
                   lambda p: (p[0], 5.0, 12.0))),
            ("un varf de picior impins la X 1,6", "patrat",
             vpoke("Tower_Steel", lambda p: p[2] > 13 and 20 < p[1] < 30 and p[0] > 1.0,
                   lambda p: (1.6, p[1], p[2]))),
            ("cuseta ridicata la 45,5", "inaltime",
             vpoke("Tower_Steel", lambda p: p[1] > 44.99, lambda p: (p[0], 45.5, p[2]))),
            ("piciorul lat sus (fara ingustare)", "ingustare",
             vpoke("Tower_Steel", lambda p: 36.0 < p[1] < 42.39 and p[2] - 14.5 > 1.1,
                   lambda p: (p[0], p[1], 14.5 + 1.45))),
            ("pila impinsa la X 5", "pila",
             vpoke("Tower_Concrete", lambda p: p[0] > 4.4, lambda p: (5.0, p[1], p[2]))),
        ]
    elif key == "deck_8":
        out += [("un colt al grinzii transversale ridicat la -0,2", "gabarit3",
                 vpoke("Deck_Steel", lambda p: abs(abs(p[2]) - 15.9) < 0.06 and -1.05 < p[1] < -0.95
                       and abs(p[0]) < 0.31, lambda p: (p[0], -0.2, p[2] * 0.95))),
                ("o grinda coborata la -4,5", "cote",
                 vpoke("Deck_Steel", lambda p: abs(p[1] + 4.0) < 0.01, lambda p: (p[0], -4.5, p[2])))]
    elif key == "parapet_8":
        out += [("un varf al mainii curente spre drum, |Z| 12,1", "drum",
                 vpoke("Parapet_Steel", lambda p: abs(p[2] - 12.2) < 1e-3 and p[1] > 1.0,
                       lambda p: (p[0], p[1], 12.1))),
                # translatia radacinii ar aduce cealalta parte spre drum: se muta
                # toate varfurile fetei interioare, fata ramane plana dar la 12,25
                ("fata interioara mutata la 12,25", "fata",
                 vpoke("Parapet_Steel", lambda p: abs(abs(p[2]) - 12.2) < 1e-3,
                       lambda p: (p[0], p[1], math.copysign(12.25, p[2])), every=True)),
                ("coltul de jos al corpului umflat la 12,8", "grosime",
                 vpoke("Parapet_Steel", lambda p: abs(p[2] - 12.7) < 1e-3 and p[1] < 0.01 and p[0] < 0.01,
                       lambda p: (p[0], p[1], 12.8))),
                ("mana curenta ridicata la 1,3", "cote",
                 vpoke("Parapet_Steel", lambda p: p[1] > 1.19, lambda p: (p[0], 1.3, p[2])))]
    elif key == "flares":
        out += [("evazarea mutata 0,5 m pe +X", "perete", shift(dx=0.5)),
                ("un varf al fetei interioare la |Z| 12,0", "drum",
                 vpoke("Flares_Steel", lambda p: abs(p[0]) < 1e-3 and abs(p[2] - 12.2) < 1e-3,
                       lambda p: (p[0], p[1], 12.0))),
                ("capatul de departe scurtat cu 0,4 m", "colt",
                 vpoke("Flares_Steel", lambda p: p[0] < -9.0 and p[2] > 15.4,
                       lambda p: (p[0] + 0.376, p[1], p[2] - 0.137), every=True))]
    elif key in ("cable_main", "cable_side"):
        nd = NODES[key][0]
        main = key == "cable_main"
        xp = 45.0 if main else -45.0
        hx = 10.0 if main else -10.0

        def f(x):
            return 3.0 + 41.5 * ((x - 50.0) / 50.0) ** 2 if main else 4.0 + 40.5 * ((x + 50.0) / 50.0) ** 2

        def squeeze(p, k=0.9):
            c = (xp, f(xp), 14.5)
            return tuple(c[i] + (p[i] - c[i]) * k for i in range(3))

        def thin(p, k=0.15 / 0.175):
            return (hx + (p[0] - hx) * k, p[1], 14.5 + (p[2] - 14.5) * k)

        out += [("cablul coborat 0,5 m", "cablu", shift(dy=-0.5)),
                ("un varf de colier spre axa, |Z| 12,5", "gabarit",
                 vpoke(nd, lambda p: 13.5 < p[2] < 13.9, lambda p: (p[0], p[1], 12.5))),
                ("cablul strans la diametrul 0,9 la X 45", "cablu",
                 vpoke(nd, lambda p: abs(p[0] - xp) < 0.6 and p[2] > 0 and p[1] > 1.2, squeeze, every=True)),
                ("tirantul subtiat la 0,30", "tirant",
                 vpoke(nd, lambda p: 0.17 < math.hypot(p[0] - hx, p[2] - 14.5) < 0.18 and p[1] > 0.22,
                       thin, every=True)),
                ("mufa de jos coborata la 0", "tirant",
                 vpoke(nd, lambda p: p[1] < 0.21, lambda p: (p[0], 0.0, p[2])))]
    elif key == "anchor":
        out += [("pilonul impins 0,1 m spre drum", "gabarit",
                 vpoke("Anchor_Concrete", lambda p: abs(p[2] - 13.2) < 1e-3 and p[1] > 1,
                       lambda p: (p[0], p[1], 13.1))),
                ("capacul ridicat la 6,5", "cote",
                 vpoke("Anchor_Steel", lambda p: p[1] > 5.99, lambda p: (p[0], 6.5, p[2]))),
                ("un colt al culeii urcat la -0,5", "culee",
                 vpoke("Anchor_Concrete", lambda p: abs(p[2]) > 16.0 and abs(p[1] + 1.0) < 1e-3
                       and abs(p[0]) < 1.01, lambda p: (p[0], -0.5, p[2]), every=True)),
                ("gura cusetei astupata", "gura",
                 vpoke("Anchor_Steel", lambda p: p[0] > 1.9 and abs(p[1] - 3.42) < 0.01 and 13.8 < p[2] < 15.2,
                       lambda p: (p[0], 4.2, p[2]), every=True))]
    elif key == "walkway_8":
        out += [("trotuarul ridicat 0,1 m", "trotuar", shift(dy=0.1)),
                ("o dala impinsa spre drum, |Z| 12,5", "drum",
                 vpoke("Walkway_Concrete", lambda p: abs(p[2] - 12.7) < 1e-3, lambda p: (p[0], p[1], 12.5))),
                ("bordura lata la 16,6", "cote",
                 vpoke("Walkway_Steel", lambda p: abs(p[2] - 16.4) < 1e-3, lambda p: (p[0], p[1], 16.6)))]
    elif key == "lamp":
        out += [("felinarul ridicat 0,5 m", "baza", shift(dy=0.5)),
                ("acoperisul lat la 0,56 m", "raza",
                 vpoke("Lamp_Steel", lambda p: p[1] > 5.8 and math.hypot(p[0], p[2]) > 0.3,
                       lambda p: (p[0] * 1.6, p[1], p[2] * 1.6), every=True)),
                ("stalpul ingrosat (raza 0,195)", "stalp",
                 vpoke("Lamp_Steel", lambda p: 0.85 < p[1] < 5.05 and math.hypot(p[0], p[2]) < 0.16,
                       lambda p: (p[0] * 1.3, p[1], p[2] * 1.3), every=True))]
    return out


def selftest(keys):
    ok = True
    tmp = tempfile.mkdtemp(prefix="sfb_sabotaj_")
    for key in keys:
        path = os.path.join(MODELS, "sf_bridge_%s.glb" % key)
        print("== selftest sf_bridge_%s" % key)
        for label, want, fn in sabotages(key):
            g, blob = load_glb(path)[:2]
            g = json.loads(json.dumps(g))
            blob = bytearray(blob)
            fn(g, blob)
            p = os.path.join(tmp, "sabotaj.glb")
            _write_glb(p, g, blob)
            try:
                bad = check(key, p, report=False)
            except Exception as e:      # noqa: BLE001 -- un sabotaj care sparge citirea tot e un esec
                bad = ["(exceptie) %r" % e]
            keys_hit = sorted({b[1:b.index(")")] for b in bad if b.startswith("(")})
            caught = want in keys_hit
            print("   %-46s -> pica pe %-28s %s" % (label, ",".join(keys_hit) or "NIMIC",
                                                    "ok" if caught else "!! ASTEPTAT (%s)" % want))
            ok &= caught
            os.remove(p)
        orig = check(key, path, report=False)
        print("   %-46s -> %s" % ("originalul", "trece" if not orig else "!! PICA: %s" % orig))
        ok &= not orig
    os.rmdir(tmp)
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    args = sys.argv[1:]
    if args and args[0] == "--selftest":
        sys.exit(0 if selftest(args[1:] or PIECES) else 1)
    keys = args or PIECES
    failed = []
    for key in keys:
        if check(key, os.path.join(MODELS, "sf_bridge_%s.glb" % key)):
            failed.append(key)
    print("GARDA PODULUI: %s" % ("OK (%d piese)" % len(keys) if not failed else "ESUAT: %s" % ", ".join(failed)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
