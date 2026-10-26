# Genereaza traseul Carrara (Track23) din waypoints cu fillet-uri de arc --
# schela din gen_fiordland_route.py / gen_halong_route.py (pas uniform 12 m,
# viraje > 90 de grade esantionate pe arc, statistici ca ProbeLayout), cu garzile
# de geometrie din brief (docs/track_briefs/carrara.md §2) verificate pe punctele
# coapte INAINTE sa existe .tscn-ul.
#
#   python tools/gen_carrara_route.py [scenes/tracks/Track23.tscn] [--plan out.png]
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z,
# est = +X): harta ajunge in lume FARA oglindire, deci "dreapta" de pe harta e
# dreapta si in cadrul camerei (conventia din gen_halong_route.py).
#
# Sens ORAR pe plan (amfiteatrul pe dreapta, in interiorul buclei, brief §2):
#   A piazzale (NV, spre E) -> B gradonii pe zidul de nord: terasa 1 spre E, ac
#   la dreapta, terasa 2 spre V, ac la stanga, terasa 3 spre E -> C fundul
#   carierei, spre E -> D galeria: portal in zidul de est, tunelul face un ac
#   de 180 de grade la dreapta prin masivul de SE si iese spre V -> E cariera de
#   sus (+45, marginea de sud, spre V, golul pe dreapta) -> F podul peste chei ->
#   G ravaneto (coboara spre N pe flancul de vest) -> H tunelul Marmifera -> A.
#
# LECTIILE DIN SONDELE PASULUI 1 (brief §7 "Runda 2"): acele sintetice de 6 m cu
# iesire scurta aruncau AI-ul larg in inceputul bermei. Aici acele au raza de
# centru 17,5 m (semicerc intre terase la 35 m), lungime de arc ~55 m, cate 25 m
# de intrare dreapta si 45 m de IESIRE dreapta inainte de terasa plata urmatoare,
# iar berma (custom_parapets stil 2) incepe DUPA iesire, nu pe ac.
import math
import sys

ARGS = [a for a in sys.argv[1:]]
OUT_PATH = None
PLAN_PATH = None
i = 0
while i < len(ARGS):
    if ARGS[i] == "--plan":
        PLAN_PATH = ARGS[i + 1]
        i += 2
        continue
    if not ARGS[i].startswith("--"):
        OUT_PATH = ARGS[i]
    i += 1

HALF_WIDTH = 4.5   # custom_half_width global; sectoarele (mai jos) il suprascriu

# (x, y, fillet_r, cota, eticheta). `cota` None = interpolata pe lungime intre ancore.
R_AC = 19.0
Y1, Y2, Y3 = 105.0, 67.0, 29.0     # terasele; 38 m intre ele = 2 x R_AC
WPTS = [
    # A: piazzale-ul (+25), spre E. Linia de start la frac 0.
    (-148.0, Y1, 0, 25.0, "A start"),
    (-27.0,  Y1, 0, 25.0, "A iesire coridor"),
    # B terasa 1 (+25, plata) pana la intrarea in acul 1.
    (15.0,   Y1, 0, 25.0, "B T1 sfarsit plat"),
    # B acul 1 (dreapta): 25 m intrare + semicerc R 19 + ~50 m iesire (coboara 25 -> 16).
    (59.0,   Y1, R_AC, None, "B ac1 N"),
    (59.0,   Y2, R_AC, None, "B ac1 S"),
    (-10.0,  Y2, 0, 16.0, "B T2 inceput plat"),
    (-60.0,  Y2, 0, 16.0, "B T2 sfarsit plat"),
    # B acul 2 (stanga) 16 -> 7.
    (-104.0, Y2, R_AC, None, "B ac2 N"),
    (-104.0, Y3, R_AC, None, "B ac2 S"),
    (-35.0,  Y3, 0, 7.0, "B T3 inceput plat"),
    (30.0,   Y3, 0, 7.0, "B T3 sfarsit plat"),
    # C: fundul carierei (+2), spre E, cu un cot la dreapta in jurul baltilor.
    (100.0,  20.0, 0, 2.0, "C intrare podea"),
    (172.0,  20.0, 60, None, "C cot 1"),
    (228.0,  -36.0, 60, None, "C cot 2"),
    # Rampe de intrare/iesire in panta (spline-ul Catmull-Rom depaseste 13% la un colt de profil):
    # ultimii 25 m de C urca 2 -> 3 (4%) INAINTE de portal, iar cei 28 m de dinaintea portalului de
    # sus raman la 44 -> 45.
    (262.0,  -36.0, 0, 2.0, "D rampa jos"),
    # D: galeria. Intra spre E, ac de 180 grade la dreapta (R 38), iese spre V.
    (287.0,  -36.0, 0, 3.0, "D portal jos"),
    (372.0,  -36.0, 38, None, "D ac intrare"),
    (372.0,  -112.0, 38, None, "D ac iesire"),
    (125.0,  -112.0, 0, 44.0, "D rampa sus"),
    (100.0,  -112.0, 0, 45.0, "D portal sus (E inceput)"),
    # E: cariera de sus (+45), marginea de sud, spre V, golul pe dreapta. DREAPTA, fara S-uri: cele doua
    # S-uri din brief (concavitate spre gol) puneau golul pe INTERIORUL virajului la dreapta (masinile
    # taiau spre apex, peste berma) si pe EXTERIORUL celui la stanga (masinile ieseau largi peste
    # berma): ProbeRace runda 2-3, 6 caderi + 2 ejectari de 43 m/s la 0.60-0.69. Revine, daca vrea
    # dezvoltatorul, ca raza mare (>= 300 m) sau cu `ai_drop_edges`.
    (-115.0, -112.0, 0, 45.0, "E sfarsit"),
    # F: podul (+43) peste chei, drept, pe aceeasi dreapta (30 m de gol).
    (-150.0, -112.0, 0, 43.0, "F pod"),
    # G: ravaneto-ul, +43 -> +27, spre N pe flancul de vest, cu S-uri.
    (-330.0, -112.0, 80, None, "G colt SV"),
    (-330.0, -30.0, 70, None, "G S1"),
    (-262.0, 25.0, 80, None, "G S2"),
    (-340.0, 70.0, 60, None, "G S3"),
    # Colt NV: 35 m de DREAPTA intre sfarsitul arcului (x -285) si portalul Marmifera (x -250); aripile
    # portalului (14 m) loveau masinile care ies larg din arc (ProbeRace, runda 0: 3 ejectari la 0.94).
    (-330.0, 105.0, 45, None, "G colt NV"),
    # H: tunelul Marmifera, drept pe Y1 intre G si piazzale.
    (-250.0, 105.0, 0, 27.0, "H portal intrare"),
    (-205.0, 105.0, 0, 25.5, "H portal iesire"),
]


# ---- TREPTELE (pasul 4): gradonii ca fete verticale, nu pante. Vezi `custom_bench_patches`.
BENCH_W = 8.0        # banc plat intre marginea asfaltului si muchia fetei (contract >= 4 m dupa berma)
BENCH_W_E = 7.5      # banc plat pe E (inainte de prima fata); mai mic ca BENCH_W: fundul se vede mai devreme
E_STEPS = 5          # fetele scarii de pe E spre fundul carierei
E_TREAD = 8.0        # latimea unei trepte intermediare (m)
WEST = -112.0       # capatul de V al scarii de pe E (fata N-S a gradonului de V)
PIT_WEST = -190.0   # capatul de V al fundului carierei (trece de scara, spre cheiul podului)
PIT_FLOOR = 0.8      # fundul carierei (drumul C sta la +2; ravena lui C coboara la acelasi nivel)

def v(a, b):
    return (b[0] - a[0], b[1] - a[1])


def norm(a):
    l = math.hypot(*a)
    return (a[0] / l, a[1] / l)


def fillet_loop(wpts):
    n = len(wpts)
    pts = []
    for i in range(n):
        p_prev = wpts[(i - 1) % n][:2]
        p = wpts[i][:2]
        p_next = wpts[(i + 1) % n][:2]
        r = wpts[i][2]
        d1, d2 = norm(v(p, p_prev)), norm(v(p, p_next))
        cosang = max(-1.0, min(1.0, d1[0] * d2[0] + d1[1] * d2[1]))
        ang = math.acos(cosang)
        turn = math.pi - ang
        if turn < math.radians(8) or r <= 0:
            pts.append((p[0], p[1], i))
            continue
        t = r / math.tan(ang / 2.0)
        lim1 = math.hypot(*v(p, p_prev)) * 0.5
        lim2 = math.hypot(*v(p, p_next)) * 0.5
        if t > min(lim1, lim2) + 1e-6:
            t = min(lim1, lim2)
            r = t * math.tan(ang / 2.0)
        t1 = (p[0] + d1[0] * t, p[1] + d1[1] * t)
        t2 = (p[0] + d2[0] * t, p[1] + d2[1] * t)
        bis = norm((d1[0] + d2[0], d1[1] + d2[1]))
        dist_c = math.hypot(p[0] - t1[0], p[1] - t1[1])
        dist_c = math.sqrt(dist_c * dist_c + r * r)
        c = (p[0] + bis[0] * dist_c, p[1] + bis[1] * dist_c)
        a1 = math.atan2(t1[1] - c[1], t1[0] - c[0])
        a2 = math.atan2(t2[1] - c[1], t2[0] - c[0])
        sweep = a2 - a1
        while sweep > math.pi:
            sweep -= 2 * math.pi
        while sweep < -math.pi:
            sweep += 2 * math.pi
        steps = max(2, int(abs(sweep) / math.radians(15)) + 1)
        for k in range(steps + 1):
            a = a1 + sweep * k / steps
            pts.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a),
                        i if k == steps // 2 else None))
    out = []
    for p in pts:
        if out and math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) < 1.0:
            if p[2] is not None and out[-1][2] is None:
                out[-1] = (out[-1][0], out[-1][1], p[2])
            continue
        out.append(p)
    if len(out) > 1 and math.hypot(out[0][0] - out[-1][0],
                                   out[0][1] - out[-1][1]) < 1.0:
        out.pop()
    return out


def cum_lengths(pts):
    cum = [0.0]
    for i in range(1, len(pts) + 1):
        a, b = pts[i - 1], pts[i % len(pts)]
        cum.append(cum[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    return cum


def assign_elev(pts, wpts):
    cum = cum_lengths(pts)
    total = cum[-1]
    anchors = []
    for i, w in enumerate(wpts):
        if w[3] is None:
            continue
        for j, p in enumerate(pts):
            if p[2] == i:
                anchors.append((cum[j], w[3]))
                break
    anchors.sort()
    anchors.append((anchors[0][0] + total, anchors[0][1]))
    out = []
    for j, p in enumerate(pts):
        l = cum[j]
        if l < anchors[0][0]:
            l += total
        e = anchors[-1][1]
        for k in range(len(anchors) - 1):
            l0, e0 = anchors[k]
            l1, e1 = anchors[k + 1]
            if l0 <= l <= l1:
                f = (l - l0) / max(1e-6, l1 - l0)
                e = e0 + (e1 - e0) * f
                break
        out.append(e)
    return out, cum, total


def circumradius(a, b, c):
    ab = math.hypot(b[0] - a[0], b[1] - a[1])
    bc = math.hypot(c[0] - b[0], c[1] - b[1])
    ca = math.hypot(a[0] - c[0], a[1] - c[1])
    s = (ab + bc + ca) / 2
    area2 = max(1e-9, s * (s - ab) * (s - bc) * (s - ca))
    return ab * bc * ca / (4 * math.sqrt(area2))


def resample(pts, elevs, step):
    cum = cum_lengths(pts)
    total = cum[-1]
    out = []
    target, j = 0.0, 0
    while target < total:
        while cum[j + 1] < target:
            j += 1
        a, b = pts[j], pts[(j + 1) % len(pts)]
        f = (target - cum[j]) / max(1e-6, cum[j + 1] - cum[j])
        out.append((a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f,
                    elevs[j] + (elevs[(j + 1) % len(pts)] - elevs[j]) * f))
        target += step
    return out


pts = fillet_loop(WPTS)
elevs, cum, total = assign_elev(pts, WPTS)

CTRL_STEP = 12.0
ctrl = resample(pts, elevs, CTRL_STEP)
if math.hypot(ctrl[0][0] - ctrl[-1][0], ctrl[0][1] - ctrl[-1][1]) < CTRL_STEP * 0.5:
    ctrl.pop()
ctrl_tag = [None] * len(ctrl)
for j, p in enumerate(pts):
    if p[2] is None:
        continue
    best, bd = 0, 1e9
    for k, q in enumerate(ctrl):
        d = math.hypot(q[0] - p[0], q[1] - p[1], q[2] - elevs[j])
        if d < bd:
            best, bd = k, d
    ctrl_tag[best] = p[2]
pts = [(q[0], q[1], ctrl_tag[k]) for k, q in enumerate(ctrl)]
elevs = [q[2] for q in ctrl]
cum = cum_lengths(pts)
total = cum[-1]
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime: {total:.0f} m")

frac = {}
for i, w in enumerate(WPTS):
    for j, p in enumerate(pts):
        if p[2] == i:
            frac[w[4]] = cum[j] / total
            break


def fr_at_dist(d):
    return d / total


def signed_area(seq):
    a = 0.0
    for i in range(len(seq)):
        x0, y0 = seq[i][0], seq[i][1]
        x1, y1 = seq[(i + 1) % len(seq)][0], seq[(i + 1) % len(seq)][1]
        a += x0 * y1 - x1 * y0
    return a / 2.0


print(f"aria cu semn (harta): {signed_area(pts):+.0f}  (negativ = ORAR)")

rs = resample(pts, elevs, 12.0)
min_r, min_r_at = 1e9, 0
max_slope, max_slope_at = 0, 0
for i in range(len(rs)):
    a, b, c = rs[i - 1], rs[i], rs[(i + 1) % len(rs)]
    r = circumradius(a, b, c)
    if r < min_r:
        min_r, min_r_at = r, i * 12.0 / total
    d = math.hypot(c[0] - b[0], c[1] - b[1])
    sl = abs(c[2] - b[2]) / max(1e-6, d)
    if sl > max_slope:
        max_slope, max_slope_at = sl, i * 12.0 / total
print(f"raza minima: {min_r:.1f} m la frac {min_r_at:.3f}  (prag > {HALF_WIDTH})")
print(f"panta maxima: {max_slope*100:.1f}% la frac {max_slope_at:.3f}  (prag < 13%)")

min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 9, len(rs)):
        if len(rs) - (j - i) <= 8:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        dy = abs(rs[j][2] - rs[i][2])
        if d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima XZ: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si "
      f"{min_sep_at[1]:.3f}  (prag >= {2*HALF_WIDTH})")

cx = sum(p[0] for p in rs) / len(rs)
cy = sum(p[1] for p in rs) / len(rs)
ext_x = max(abs(p[0] - cx) for p in rs)
ext_y = max(abs(p[1] - cy) for p in rs)
mean_elev = sum(p[2] for p in rs) / len(rs)
print(f"centroid harta ({cx:.0f}, {cy:.0f}); departare maxima de zidul lumii (420): "
      f"x {ext_x:.0f}, y {ext_y:.0f}")
print(f"cota medie sosea: {mean_elev:.1f} m")

# Marea (plasa de repunere): cota ABSOLUTA dorita sub fundul carierei (+2) si sub
# cheiul podului nu intra in discutie (cheiul are propria plasa de viaduct).
SEA_LEVEL_TARGET_ABS = -6.0
sea_offset = round(SEA_LEVEL_TARGET_ABS - mean_elev, 2)
print(f"sea_level_offset ales: {sea_offset} (mare absoluta {SEA_LEVEL_TARGET_ABS} m, "
      f"plasa de repunere la {SEA_LEVEL_TARGET_ABS - 1.2:.1f})")


def section_slopes(name, f0, f1):
    sl = []
    for i in range(len(rs)):
        f = i * 12.0 / total
        if f0 <= f <= f1:
            b, c = rs[i], rs[(i + 1) % len(rs)]
            d = math.hypot(c[0] - b[0], c[1] - b[1])
            sl.append((c[2] - b[2]) / max(1e-6, d))
    if sl:
        print(f"{name} {f0:.3f}-{f1:.3f}: panta medie {100*sum(sl)/len(sl):+.1f}%  "
              f"varf {100*max(sl, key=abs):+.1f}%")


section_slopes("B rampa ac1", frac["B T1 sfarsit plat"], frac["B T2 inceput plat"])
section_slopes("B rampa ac2", frac["B T2 sfarsit plat"], frac["B T3 inceput plat"])
section_slopes("C coborare", frac["B T3 sfarsit plat"], frac["C intrare podea"])
section_slopes("D galerie", frac["D portal jos"], frac["D portal sus (E inceput)"])
section_slopes("G ravaneto", frac["F pod"], frac["H portal intrare"])

print("\nfractii waypoint:")
for w in WPTS:
    print(f"  {frac[w[4]]:.3f}  {w[4]}  (cota {w[3] if w[3] is not None else '-'})")


def godot(p, e):
    return (p[0], e, -p[1])


def r3(x):
    return round(x, 3)


if PLAN_PATH:
    from PIL import Image, ImageDraw
    S = 1.6
    allx = [p[0] for p in rs]
    ally = [p[1] for p in rs]
    x0, x1, y0, y1 = min(allx) - 30, max(allx) + 30, min(ally) - 30, max(ally) + 30
    W, H = int((x1 - x0) * S), int((y1 - y0) * S)
    im = Image.new("RGB", (W, H), (235, 230, 215))
    d = ImageDraw.Draw(im)

    def px(p):
        return ((p[0] - x0) * S, H - (p[1] - y0) * S)

    for i in range(len(rs)):
        a, b = rs[i], rs[(i + 1) % len(rs)]
        e = (a[2] + b[2]) / 2
        t = max(0.0, min(1.0, e / 45.0))
        col = (int(40 + 200 * t), int(80 + 60 * (1 - abs(t - 0.5) * 2)), int(220 - 190 * t))
        d.line([px(a), px(b)], fill=col, width=4)
    for k in range(0, 100, 5):
        j = int(k / 100.0 * len(rs))
        p = px(rs[j])
        d.text((p[0] + 4, p[1] - 10), f"{k/100:.2f}", fill=(0, 0, 0))
    for w in WPTS:
        p = px(w)
        d.ellipse([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], fill=(0, 0, 0))
    im.save(PLAN_PATH)
    print("plan:", PLAN_PATH)



def r2(x):
    return round(x, 2)


# --------------------------------------------------------------------------
# Fractiile sunt de DOUA feluri in motor (memoria fractia-pe-index-vs-pe-lungime):
#   idx = i/n (TrackRoute.frac_at): sectoare de latime, intervale ude / de praf
#   len = _dists[i]/total: rape, parapete, zone de sol
# Punctele coapte se indesesc in viraje, deci cele doua diverg. Harta (x, z, idx, len) pe
# curba COAPTA vine din `tools/probe_carrara_fracmap.gd` (tools/data/carrara_fracmap.tsv);
# fara ea (prima trecere) se foloseste lungimea poligonului de control pentru amandoua.
# --------------------------------------------------------------------------
import os

FRACMAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data",
                       "carrara_fracmap.tsv")
fmap = []
if os.path.exists(FRACMAP):
    for line in open(FRACMAP, encoding="utf-8"):
        t = line.split()
        if len(t) == 4:
            fmap.append((float(t[0]), float(t[1]), float(t[2]), float(t[3])))
print(f"harta de fractii coapte: {'%d puncte' % len(fmap) if fmap else 'LIPSA (aprox. pe poligon)'}")

tag_s = {}
for i, w in enumerate(WPTS):
    for j, p in enumerate(pts):
        if p[2] == i:
            tag_s[w[4]] = cum[j]
            break


def pos_at(sv):
    sv = sv % total
    for j in range(len(pts)):
        if cum[j] <= sv <= cum[j + 1]:
            a, b = pts[j], pts[(j + 1) % len(pts)]
            f = (sv - cum[j]) / max(1e-9, cum[j + 1] - cum[j])
            return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
    return (pts[0][0], pts[0][1])


def F(tag, off=0.0):
    """(idx, len) la `off` metri de tag pe axa."""
    sv = (tag_s[tag] + off) % total
    if not fmap:
        return (sv / total, sv / total)
    x, y = pos_at(sv)
    gx, gz = x, -y
    best, bd = None, 1e18
    for fx, fz, fi, fl in fmap:
        d = (fx - gx) ** 2 + (fz - gz) ** 2
        if d < bd:
            best, bd = (fi, fl), d
    return best


def IDX(tag, off=0.0):
    return r3(F(tag, off)[0])


def LEN(tag, off=0.0):
    return r3(F(tag, off)[1])


def dist_between(t0, t1):
    return (tag_s[t1] - tag_s[t0]) % total


def V2(a, b):
    return f"Vector2({a}, {b})"


def V3(a, b, c):
    return f"Vector3({a}, {b}, {c})"


def V4(a, b, c, d):
    return f"Vector4({a}, {b}, {c}, {d})"


if OUT_PATH:
    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]

    # ---- latimi (idx). Jumatati de latime; globalul 4.5 e C si G (9 m). Ordinea conteaza:
    # primul sector care contine fractia castiga, deci tunelurile (cele mai inguste) sunt primele.
    width_segments = [
        # H: tunelul Marmifera — exact intre portaluri. 8 m, nu 6,5 din brief: la 6,5 m masinile de 35 m/s
        # (venind dintr-un arc) loveau rama/aripile portalului (ProbeRace runda 0-1: 5 ejectari la 0.94-0.97).
        (IDX("H portal intrare"), IDX("H portal iesire"), 4.0),
        # D + E: galeria si cariera de sus, de la portalul de jos la capatul lui E. 8 m (brief: 7).
        (IDX("D portal jos"), IDX("E sfarsit"), 4.0),
        # F: podul NU mai are sector (era 6 m): la 6 m AI-ul tinea linia la 2,6 m de axa si rotile
        # treceau peste marginea tablierului fara parapet (18 repuneri in 16 curse, runda 0).
        # Iese cu latimea globala, 9 m; trecerea 7 -> 9 m e rampa de 30 m a sectorului E.
        # A: piazzale-ul (10 m), de la iesirea din tunel pana la capatul coridorului de blocuri.
        (IDX("H portal iesire", 1.0), IDX("A iesire coridor"), 5.0),
        # B: terasele si acele iau latimea GLOBALA (9 m) — acele NU mai sunt de 6 m (lectia sondelor, runda
        # 2). Sectorul de 8,5 m din runda 0-4 strangea soseaua de la 10 la 8,5 m chiar pe dreapta de
        # start, unde plutonul e inca grupat (o masina impinsa lateral a trecut peste berma, runda 4).
    ]
    flow_windows = [
        # H -> A: iesirea din tunel (6,5 m) direct in piazzale (10 m).
        (IDX("H portal iesire", -20.0), IDX("H portal iesire", 55.0)),
    ]

    # ---- rape (len). ADANCIMEA e relativa la cota drumului MEDIATA (`road_level`, nu cea locala), deci
    # pentru o podea ABSOLUTA se declara adancime mare si se lasa podeaua sa taie: cu 5-9 m cerute,
    # la 50 m de terasa tinta iesea 11-17 (o creasta de 15 m intre doua rape, masurat cu profilul N-S).
    # Rapele 0-3 din versiunea cu grila (terasele A/T2/T3/E ca cornise) au fost INLOCUITE de platourile de
    # banc de mai jos: o cornisa cade ~50 de grade pe grila de 7.92 m si lipita de asfalt; treptele
    # adevarate sunt `custom_bench_patches` (fata verticala, bancul plat de BENCH_W m inaintea ei).
    ravines = [
        # 0: cheiul Ponti di Vara: viaduct pe ambele parti, 30 m de gol, podea la +17.
        (LEN("F pod", -15.0), LEN("F pod", 15.0), 40, 0),
        # 1: fundul carierei C, pe DREAPTA (S): baltile stau pe podea, nu pe un platou de +20.
        (LEN("C intrare podea", -20.0), LEN("D rampa jos"), 40, 1),
    ]
    cornice = [0]
    scarp = []
    # C (idx 1): racord strans, fara treapta de 1 m la marginea asfaltului (vezi TrackSideSampler.tight_ravines)
    tight = [1]
    viaduct = [0]
    floors = [(0, 17.0), (1, 2.0)]
    widths = [(0, 60.0), (1, 70.0)]

    # ---- berma continua de moloz (stil 2): doar pe marginile cu gol, NU pe ace, si DUPA iesirea din ac
    parapets = [
        # Prima berma incepe LA IESIREA din tunel (peste linia de start, interval cu trecere): fara ea,
        # primii 40 m de piazzale aveau faleza de 9 m si nicio bariera, iar plutonul din grila cadea pe
        # bancul de +16 (ProbeRace runda 1: 10 [blocaj] cu masina ramasa jos la lat 10 m).
        # ...si tine pana la INCEPUTUL arcului (25 m de intrare dreapta dupa terasa plata), nu pana la sfarsitul
        # terasei: masinile care taiau spre interiorul acului 1 treceau de capatul subtiat al bermei si
        # cadeau pe bancul de +16, de unde nu mai ieseau (ProbeRace runda 4: 6 [blocaj] cu o masina
        # ramasa 100 s jos, lat 9 m).
        (LEN("H portal iesire", 25.0), LEN("B ac1 N", -19.0), 1, 2),
        (LEN("B T2 inceput plat"), LEN("B ac2 N", -19.0), -1, 2),
        (LEN("B T3 inceput plat"), LEN("B T3 sfarsit plat", 12.0), 1, 2),
        (LEN("D portal sus (E inceput)", 20.0), LEN("E sfarsit"), 1, 2),
        # Podul (F): golul e pe AMBELE parti si tablierul nu are umeri — o roata peste muchie = cadere
        # in chei (ProbeRace runda 2: 7 repuneri ViaductNet4 pe 16 curse, masini la 5 m de axa pe un
        # tablier de 4,5). Berma pe ambele laturi, pe lungimea tablierului vizibil (+-55 m).
        (LEN("F pod", -55.0), LEN("F pod", 55.0), 0, 2),
    ]

    # ---- sol: drum de praf peste tot, mai putin podul si Marmifera; umed pe C
    dirt = [
        (IDX("F pod", 62.0), IDX("H portal intrare", -2.0)),
        (IDX("H portal iesire", 2.0), IDX("F pod", -62.0)),
    ]
    # Ud doar pana cu 40 m inainte de portal: masinile care alunecau in cotul ud iesisera cu botul
    # pe diagonala in cadrul portalului (ejectare 31 m/s, runda 0).
    wet = [(IDX("C intrare podea"), IDX("D portal jos", -40.0))]

    rav_txt = ", ".join(V4(*r) for r in ravines)
    fl_txt = ", ".join(V2(a, b) for a, b in floors)
    rw_txt = ", ".join(V2(a, b) for a, b in widths)
    w_txt = ", ".join(V3(*w) for w in width_segments)
    fw_txt = ", ".join(V2(a, b) for a, b in flow_windows)
    par_txt = ", ".join(V4(*p_) for p_ in parapets)
    dirt_txt = ", ".join(V2(a, b) for a, b in dirt)
    wet_txt = ", ".join(V2(a, b) for a, b in wet)

    # ---- masive (coordonate Godot: gx = x, gz = -y)
    def peak(name, x, y, e, r):
        return f"""
[node name="{name}" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {e}, {-y})
gizmo_extents = {r}
script = ExtResource("2_peak")
radius_m = {r}
"""
    peaks_txt = peak("MasivGalerie", 262.0, -62.0, 85.0, 175.0) \
        + peak("MasivMarmifera", -228.0, 128.0, 75.0, 95.0)

    # ---- tunelurile: noduri doar-tub la linia de oprire (originea = capatul dinspre start)
    def tunnel_node(name, tag, tag_end, hw, ceil_h, tail):
        x, y = pos_at(tag_s[tag])
        x2, y2 = pos_at(tag_s[tag] + 3.0)
        dx, dz = (x2 - x), -(y2 - y)   # directia de mers in lume (gx, gz)
        l = math.hypot(dx, dz)
        dx, dz = dx / l, dz / l
        # Basis: X local = dreapta sensului (dz, 0, -dx), Z local = sensul de mers (dx, 0, dz)
        bx = (dz, 0.0, -dx)
        bz = (dx, 0.0, dz)
        length = dist_between(tag, tag_end)
        j0 = min(range(len(pts)), key=lambda j: abs(cum[j] - tag_s[tag]))
        ee = elevs[j0]
        return f"""
[node name="{name}" type="Node3D" parent="Hazarduri"]
transform = Transform3D({r3(bx[0])}, 0, {r3(bz[0])}, 0, 1, 0, {r3(bx[2])}, 0, {r3(bz[2])}, {r2(x)}, {r2(ee)}, {r2(-y)})
script = ExtResource("5_signal")
tunnel_length = {r2(length)}
tunnel_half_width = {hw}
tunnel_ceiling = {ceil_h}
camera_tail_m = {tail}
tube_only = true
tube_class = "carrara_marble"
"""
    tunnels_txt = tunnel_node("TunelGalerie", "D portal jos", "D portal sus (E inceput)", 4.0, 9.0, 14.0) \
        + tunnel_node("TunelMarmifera", "H portal intrare", "H portal iesire", 4.0, 7.0, 12.0)

    # ---- Plase de repunere sub marginile cu gol (RespawnZone, ca ViaductNet): berma de 0,6 m nu opreste o
    # masina impinsa lateral la 25 m/s (urca pe ea si cade), iar bancul de sub faleza nu e drum: masina
    # ramanea acolo toata cursa ([blocaj] 6x, ProbeRace runda 6), iar jucatorul ar putea chiar sa taie
    # acul pe banc. Cutii subtiri chiar la piciorul falezei, sub cota drumului, pe segmente DREPTE.
    nets = []
    net_shapes = []

    def net(name, t0, o0, t1, o1, side, lat0, lat1, y_lo, y_hi):
        a = pos_at(tag_s[t0] + o0)
        b = pos_at(tag_s[t1] + o1)
        dx, dz = (b[0] - a[0]), -(b[1] - a[1])
        length = math.hypot(dx, dz)
        dx, dz = dx / length, dz / length
        rx, rz = -dz, dx                  # DREAPTA sensului de mers in lume (inainte x sus = (-fz, 0, fx))
        lat = side * (lat0 + lat1) * 0.5
        cx = (a[0] + b[0]) * 0.5 + rx * lat
        cz = -(a[1] + b[1]) * 0.5 + rz * lat
        cy = (y_lo + y_hi) * 0.5
        bxv = (-rx, 0.0, -rz)             # X local = STANGA (baza dreapta, det +1; cutia e simetrica)
        bzv = (dx, 0.0, dz)               # Z local = sensul de mers
        nets.append(f"""
[node name="{name}" type="Area3D" parent="Hazarduri"]
transform = Transform3D({r3(bxv[0])}, 0, {r3(bzv[0])}, 0, 1, 0, {r3(bxv[2])}, 0, {r3(bzv[2])}, {r2(cx)}, {r2(cy)}, {r2(cz)})
script = ExtResource("6_respawn")
backoff_m = 16.0

[node name="Forma" type="CollisionShape3D" parent="Hazarduri/{name}"]
shape = SubResource("Box_{name}")
""")
        net_shapes.append(f"""
[sub_resource type="BoxShape3D" id="Box_{name}"]
size = Vector3({r2(abs(lat1 - lat0))}, {r2(y_hi - y_lo)}, {r2(length)})
""")

    # Plase de repunere pe platourile de SUB fiecare fata (o cadere peste muchie devine repunere, nu o masina
    # blocata pe un banc care nu duce nicaieri). Lateral: de la muchia fetei (HALF_WIDTH + BENCH_W) spre gol.
    LIPLAT = HALF_WIDTH + BENCH_W
    net("PlasaA", "H portal iesire", 12.0, "B ac1 N", -19.0, 1, LIPLAT + 0.5, LIPLAT + 12.0, 12.0, 22.0)
    net("PlasaT2", "B T2 inceput plat", -4.0, "B ac2 N", -19.0, -1, LIPLAT + 0.5, LIPLAT + 12.0, 3.0, 13.0)
    net("PlasaT3", "B T3 inceput plat", -4.0, "B T3 sfarsit plat", 8.0, 1, LIPLAT + 0.5, LIPLAT + 12.0, -1.0, 8.0)
    LIPLAT_E = HALF_WIDTH + BENCH_W_E
    net("PlasaE", "D portal sus (E inceput)", 4.0, "E sfarsit", 0.0, 1, LIPLAT_E + 0.5, LIPLAT_E + E_TREAD * E_STEPS + 6.0, -2.0, 42.0)

    # ---- PLATOURI DE BANC (coordonate de lume: gx = x, gz = -y; z0 < z1 = nord -> sud).
    # Cota soselei la un x dat, citita din traseul resamplat (`rs`), pe fasia de y [ylo, yhi].
    def level_profile(ylo, yhi, xlo, xhi, thin=8.0):
        pts_ = sorted((p_[0], p_[2]) for p_ in rs if ylo <= p_[1] <= yhi and xlo <= p_[0] <= xhi)
        out_ = []
        for x_, e_ in pts_:
            if not out_ or x_ - out_[-1][0] >= thin * 0.5:
                out_.append((x_, e_))
        if pts_ and out_[-1][0] != pts_[-1][0]:
            out_.append(pts_[-1])
        return out_

    def const_level(e):
        return [(-1000.0, e), (1000.0, e)]

    patches = []

    def patch(name, x0, x1, ya, yb, lvl, soft_w, soft_e, soft_n, soft_s):
        """Dreptunghi plat in plan: x in [x0, x1], y harta in [ya, yb]. soft_* = cat se stinge in afara
        marginii vest / est / NORD (y mare) / SUD (y mic); 0 = margine DURA (aici cade o treapta)."""
        assert x0 < x1 and ya < yb
        patches.append((name, x0, x1, -yb, -ya, lvl, soft_w, soft_e, soft_n, soft_s))

    Y_T1, Y_T2, Y_T3 = Y1, Y2, Y3
    # Muchia fiecarei fete (y harta). T1 curge spre E: golul (T2) e la S, deci fata F1 sta cu BENCH_W
    # dincolo de marginea de S a lui T1. T2 curge spre V: golul (T3) e tot la S. Idem T3 -> fundul.
    LIP1 = Y_T1 - HALF_WIDTH - BENCH_W
    LIP2 = Y_T2 - HALF_WIDTH - BENCH_W
    LIP3 = Y_T3 - HALF_WIDTH - BENCH_W
    # E curge spre V pe y = -112: golul e la N (y mare). Muchiile treptelor, de la S la N.
    E_LIPS = [-112.0 + HALF_WIDTH + BENCH_W_E + E_TREAD * k for k in range(E_STEPS)]

    # fundul carierei. Partea A (sub bancul lui T3): muchia de N DURA la LIP3 (fata T3 -> fund, sau, unde
    # T3 n-are platou, un gradon in cota drumului de acolo); capatul de E se stinge (45 -> 65) in partea B,
    # care urmeaza drumul C pe la S la >= 12 m de marginea lui (nu-l sapa).
    patch("PitA", PIT_WEST, 45.0, E_LIPS[-1], LIP3, const_level(PIT_FLOOR), 0.0, 20.0, 0.0, 0.0)
    patch("PitB", 45.0, 115.0, E_LIPS[-1], 3.5, const_level(PIT_FLOOR), 0.0, 30.0, 8.0, 0.0)
    # scara de pe E: niveluri egale de la 45 la fundul carierei; treapta 0 e bancul lui E
    e_drop = (45.0 - PIT_FLOOR) / E_STEPS
    e_edges = [-124.0] + E_LIPS      # y harta, de la S la N
    for k in range(E_STEPS):
        # treapta 0 e BANCUL lui E (drumul sta pe el): se opreste la capatul lui E, ca podul F (+43) sa nu
        # intre intr-un platou de +45. Treptele 1..n coboara pana la capatul de V al fundului carierei.
        patch("E%d" % k, WEST if k == 0 else PIT_WEST, 104.0, e_edges[k], e_edges[k + 1],
              const_level(45.0 - e_drop * k),
              20.0 if k == 0 else 0.0, 15.0, 0.0, 12.0 if k == 0 else 0.0)

    # T3 / T2 / T1: banc langa drum, fata la LIP*, platoul de sub ea pana la urmatoarea fata
    l3 = level_profile(Y_T3 - 5, Y_T3 + 5, -100.0, 40.0)
    l2 = level_profile(Y_T2 - 5, Y_T2 + 5, -100.0, 38.0)
    l1 = level_profile(Y_T1 - 5, Y_T1 + 5, -150.0, 45.0)
    patch("T3", -60.0, 28.0, LIP3, LIP2, l3, 25.0, 25.0, 0.0, 0.0)
    patch("T2", -86.0, 8.0, LIP2, LIP1, l2, 22.0, 22.0, 0.0, 0.0)
    patch("T1", -150.0, 12.0, LIP1, Y_T1 + 8.0, l1, 25.0, 28.0, 12.0, 0.0)

    def fnum(v_):
        return repr(round(float(v_), 3))

    patch_txt = ", ".join(
        "{ \"lvl\": PackedVector2Array(" + ", ".join(f"{fnum(a)}, {fnum(b)}" for a, b in lvl) + "), "
        f"\"soft\": Vector4({fnum(sw)}, {fnum(se)}, {fnum(sn)}, {fnum(ss)}), "
        f"\"x0\": {fnum(x0)}, \"x1\": {fnum(x1)}, \"z0\": {fnum(z0)}, \"z1\": {fnum(z1)} }}"
        for (_n, x0, x1, z0, z1, lvl, sw, se, sn, ss) in patches)
    print("platouri de banc:")
    for (n_, x0, x1, z0, z1, lvl, sw, se, sn, ss) in patches:
        print(f"  {n_:4s} x[{x0:7.1f},{x1:7.1f}] y[{-z1:7.1f},{-z0:7.1f}]  cota {lvl[0][1]:5.1f}..{lvl[-1][1]:5.1f}  soft W{sw:g} E{se:g} N{sn:g} S{ss:g}")

    # ======================================================================================
    # HAZARDE (brief par.2 POI A/B/F, par.3; pasul 5): camionul 1 pe B, camionul 2 pe pod, excavatorul pe
    # piazzale. Curbele camioanelor se deriva din axa COAPTA (tools/data/carrara_baked.csv = dump-ul
    # `ProbeCarrara --dump-route`), nu din poligonul de control: Catmull-Rom strange arcele. Se regenereaza cu:
    #   godot ... res://tools/ProbeCarrara.tscn -- --scene=res://scenes/tracks/Track23.tscn --dump-route=<csv>
    # ======================================================================================
    BAKED = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "carrara_baked.csv")
    hz_ext = hz_sub = hz_nodes = zones_meta = ""
    if os.path.exists(BAKED):
        import csv as _csv
        brow = [tuple(map(float, r.values())) for r in _csv.DictReader(open(BAKED, encoding="utf-8"))]
        nb = len(brow)

        def b_near(gx, gz):
            return min(range(nb), key=lambda i: (brow[i][0] - gx) ** 2 + (brow[i][2] - gz) ** 2)

        def b_frac(fr_):
            return min(range(nb), key=lambda i: abs(brow[i][4] - fr_))

        TRUCK_SPEED = 8.0

        def truck_curve(i_from, i_to, lane_k, enter_off, exit_off):
            """Axa coapta de la `i_from` la `i_to` (i_from > i_to: SENS INVERS cursei), decalata pe STANGA
            cursei cu lane_k * half_width; capetele iesite din drum pe partea stanga a cursei."""
            lane_pts, last = [], None
            for i in range(i_from, i_to - 1, -1):
                x, y, z, hw, _f = brow[i]
                j, k = min(i + 1, nb - 1), max(i - 1, 0)
                dx, dz = brow[j][0] - brow[k][0], brow[j][2] - brow[k][2]
                l_ = math.hypot(dx, dz)
                dx, dz = dx / l_, dz / l_              # directia CURSEI
                rx, rz = -dz, dx                       # dreapta cursei (dir x UP)
                px, pz = x - rx * lane_k * hw, z - rz * lane_k * hw
                if last is not None and math.hypot(px - last[0], pz - last[2]) < 5.0:
                    continue
                lane_pts.append((px, y, pz, dx, dz, rx, rz))
                last = lane_pts[-1]
            x0, y0, z0, dx0, dz0, rx0, rz0 = lane_pts[0]
            xe, ye, ze, dxe, dze, rxe, rze = lane_pts[-1]
            # intrare: din spatele camionului (sensul cursei = de unde vine), pe stanga cursei, in afara drumului
            ent = [(x0 + dx0 * a - rx0 * b, y0, z0 + dz0 * a - rz0 * b) for a, b in enter_off]
            # iesire: inainte (contra cursei), pe stanga cursei
            ext = [(xe - dxe * a - rxe * b, ye, ze - dze * a - rze * b) for a, b in exit_off]
            return ent + [(a, b, c) for a, b, c, *_ in lane_pts] + ext

        def curve_len(c_):
            return sum(math.hypot(b_[0] - a_[0], b_[2] - a_[2]) for a_, b_ in zip(c_, c_[1:]))

        def bus_node(name, curve_id, c_, period, hide0):
            """phase astfel incat camionul se ASCUNDE la `hide0` s dupa t=0 (mai are hide0 * viteza de parcurs)."""
            ln = curve_len(c_)
            ph = max(0.0, 1.0 - hide0 * TRUCK_SPEED / ln)
            reappear = hide0 + max(period - ln / TRUCK_SPEED, 0.5)
            print(f"  {name}: curba {ln:.0f} m = {ln / TRUCK_SPEED:.1f} s, perioada {period:.0f} s, phase {ph:.4f} -> "
                  f"ascuns de la t={hide0:.1f} s, reapare la t={reappear:.1f} s")
            return f"""
[node name="{name}" type="Path3D" parent="Hazarduri"]
script = ExtResource("7_bus")
curve = SubResource("{curve_id}")
speed = {TRUCK_SPEED}
period = {period}
phase = {round(ph, 4)}
nose_side = 1
nose_angle_deg = 20.0
apex_outer_m = 0.0
apex_radius_m = 15.0
shove = 3.0
side_accel = 8.0
ai_reads_lane = true
soft_contact = true
model = ExtResource("8_kamaz")
"""

        def curve_sub(cid, c_):
            flat = ", ".join(f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}" for a, b, c in c_)
            return f"""
[sub_resource type="Curve3D" id="{cid}"]
_data = {{
"points": PackedVector3Array({flat}),
"tilts": PackedFloat32Array({", ".join("0" for _ in c_)})
}}
point_count = {len(c_)}
"""

        print("\nhazarde:")
        # camionul 1: din C (frac 0.318, banda stanga a cursei) pana in capul lui T1 (frac 0.059). La startul cursei
        # (3.6 s de numaratoare; plutonul ajunge la T1 la ~10 s) e deja ascuns: reapare dupa ce plutonul a trecut.
        # Intrarea vine din NORD (partea stanga a cursei), prin afara drumului.
        c1 = truck_curve(b_frac(0.318), b_frac(0.059), 0.5, [(30.0, 32.0), (10.0, 12.0)],
                         [(8.0, 7.0), (16.0, 20.0), (20.0, 34.0)])
        # camionul 2: peste pod (F), de la G (x ~ -214) la E (x ~ -70), pe partea stanga a cursei (S)
        c2 = truck_curve(b_near(-214.0, 112.0), b_near(-70.0, 112.0), 0.5, [(25.0, 30.0), (10.0, 12.0)],
                         [(8.0, 7.0), (16.0, 18.0), (20.0, 30.0)])
        hz_ext = (
            '[ext_resource type="Script" path="res://scenes/hazards/bus_hazard.gd" id="7_bus"]\n'
            '[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="9_marker"]\n'
            '[ext_resource type="PackedScene" path="res://assets/models/baikal/vehicles/kamaz_truck.glb" id="8_kamaz"]\n')
        hz_sub = curve_sub("Curve3D_camion1", c1) + curve_sub("Curve3D_camion2", c2)
        # perioada 118 s (brief par.2: ~110), ascuns la t = 3 s (reapare la ~44 s, dupa ce plutonul a trecut de C); pod: perioada 60 s (nu e multiplu al turului de ~68 s),
        # ascuns la t = 7 s
        hz_nodes += bus_node("Camion1B", "Curve3D_camion1", c1, 118.0, 3.0)
        hz_nodes += bus_node("Camion2Pod", "Curve3D_camion2", c2, 60.0, 7.0)
        # excavatorul: pe piazzale, DUPA grila (frac 0.04 = ~83 m dupa linia de start), inaintea coridorului de blocuri
        ie = b_frac(0.040)
        hz_nodes += f"""
[node name="Excavator" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {round(brow[ie][0], 2)}, {round(brow[ie][1], 2)}, {round(brow[ie][2], 2)})
script = ExtResource("9_marker")
kind = 7
excavator_ai_dice = true
excavator_soft_contact = true
"""
        print(f"  excavator: frac 0.040 la x {brow[ie][0]:.1f} (grila x ~ -190..-160, linia de start x -148)")
        # zonele pentru sonde (fractii pe INDEX): metadata citita de tools/probe_carrara.gd
        zz = [("A", IDX("H portal iesire"), IDX("A iesire coridor")),
              ("T1", IDX("A iesire coridor"), IDX("B T1 sfarsit plat")),
              ("H1", IDX("B T1 sfarsit plat"), IDX("B T2 inceput plat")),
              ("T2", IDX("B T2 inceput plat"), IDX("B T2 sfarsit plat")),
              ("H2", IDX("B T2 sfarsit plat"), IDX("B T3 inceput plat")),
              ("T3", IDX("B T3 inceput plat"), IDX("B T3 sfarsit plat")),
              ("C", IDX("B T3 sfarsit plat"), IDX("D portal jos")),
              ("D", IDX("D portal jos"), IDX("D portal sus (E inceput)")),
              ("E", IDX("D portal sus (E inceput)"), IDX("F pod", -35.0)),
              ("F", IDX("F pod", -35.0), IDX("F pod", 35.0)),
              ("G", IDX("F pod", 35.0), IDX("H portal intrare")),
              ("H", IDX("H portal intrare"), IDX("H portal iesire"))]
        zones_meta = "metadata/zones = {" + ", ".join(
            f'"{n_}": Vector2({a_}, {b_})' for n_, a_, b_ in zz if a_ <= b_) + "}\n" + 'metadata/zone_default = "A"\n'
    else:
        print("ATENTIE: tools/data/carrara_baked.csv lipseste: Track23 se genereaza FARA hazarde")

    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/hazards/tunnel_signal_hazard.gd" id="5_signal"]
[ext_resource type="Script" path="res://scenes/hazards/respawn_zone.gd" id="6_respawn"]
{hz_ext}
{"".join(net_shapes)}{hz_sub}
[sub_resource type="Curve3D" id="Curve3D_carrara"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[node name="Track23" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Carrara"
custom_theme = "carrara"
custom_half_width = {HALF_WIDTH}
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_sun_rotation_deg = Vector3(-22, -10, 0)
custom_sea_level_offset = {sea_offset}
custom_wet_ranges = Array[Vector2]([{wet_txt}])
custom_dirt_ranges = Array[Vector2]([{dirt_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([{", ".join(str(i) for i in cornice)}])
custom_scarp_ravines = Array[int]([{", ".join(str(i) for i in scarp)}])
custom_tight_ravines = Array[int]([{", ".join(str(i) for i in tight)}])
custom_viaduct_ravines = Array[int]([{", ".join(str(i) for i in viaduct)}])
custom_viaduct_net_margin = 12.0
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_ravine_widths = Array[Vector2]([{rw_txt}])
custom_bench_patches = Array[Dictionary]([{patch_txt}])
custom_width_segments = Array[Vector3]([{w_txt}])
custom_parapets = Array[Vector4]([{par_txt}])
width_flow_windows = Array[Vector2]([{fw_txt}])
terrain_pad_m = 160.0
{zones_meta}
[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_carrara")

[node name="Peaks" type="Node3D" parent="."]
{peaks_txt}
[node name="Hazarduri" type="Node3D" parent="."]
{tunnels_txt}{"".join(nets)}{hz_nodes}"""
    with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {OUT_PATH}")
    print("\ninterval                 idx            len")
    for name, a, b in [("A (H iesire->coridor)", "H portal iesire", "A iesire coridor"),
                       ("B T1", "B T1 sfarsit plat", "B T2 inceput plat"),
                       ("C", "C intrare podea", "D portal jos"),
                       ("D galerie", "D portal jos", "D portal sus (E inceput)"),
                       ("E", "D portal sus (E inceput)", "E sfarsit"),
                       ("F pod", "F pod", "F pod"),
                       ("G", "F pod", "H portal intrare"),
                       ("H tunel", "H portal intrare", "H portal iesire")]:
        print(f"  {name:24s} {IDX(a):.3f}-{IDX(b):.3f}   {LEN(a):.3f}-{LEN(b):.3f}")
