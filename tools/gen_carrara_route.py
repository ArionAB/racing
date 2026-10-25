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
    # E: cariera de sus (+45), marginea de sud, spre V, golul pe dreapta. Doua S-uri cu
    # concavitatea spre gol (virajele spre dreapta intra in cadru prin fata).
    (55.0,   -112.0, 80, 45.0, "E S1 intrare"),
    (-15.0,  -88.0, 80, 45.0, "E S1 apex (spre gol)"),
    (-75.0,  -112.0, 80, 45.0, "E S2 apex"),
    (-115.0, -112.0, 0, 45.0, "E sfarsit"),
    # F: podul (+43) peste chei, drept, pe aceeasi dreapta (30 m de gol).
    (-150.0, -112.0, 0, 43.0, "F pod"),
    # G: ravaneto-ul, +43 -> +27, spre N pe flancul de vest, cu S-uri.
    (-300.0, -112.0, 80, None, "G colt SV"),
    (-300.0, -30.0, 70, None, "G S1"),
    (-232.0, 25.0, 80, None, "G S2"),
    (-310.0, 70.0, 60, None, "G S3"),
    (-300.0, 105.0, 45, None, "G colt NV"),
    # H: tunelul Marmifera, drept pe Y1 intre G si piazzale.
    (-250.0, 105.0, 0, 27.0, "H portal intrare"),
    (-205.0, 105.0, 0, 25.5, "H portal iesire"),
]


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
        # H: tunelul Marmifera (6,5 m) — exact intre portaluri.
        (IDX("H portal intrare"), IDX("H portal iesire"), 3.25),
        # D + E: galeria si cariera de sus (7 m), de la portalul de jos la capatul lui E.
        (IDX("D portal jos"), IDX("E sfarsit"), 3.5),
        # F: podul (6 m), peste 60 m centrat pe pod; trecerea E->F o face fereastra de curgere.
        (IDX("F pod", -30.0), IDX("F pod", 30.0), 3.0),
        # A: piazzale-ul (10 m), de la iesirea din tunel pana la capatul coridorului de blocuri.
        (IDX("H portal iesire", 1.0), IDX("A iesire coridor"), 5.0),
        # B: terasele si acele (8,5 m) — acele NU mai sunt de 6 m (lectia sondelor, runda 2).
        (IDX("B T1 sfarsit plat"), IDX("B T3 sfarsit plat"), 4.25),
    ]
    flow_windows = [
        # E -> F -> iesire: latimea curge intre sectoarele lipite (7 -> 6 -> 9 m).
        (IDX("E sfarsit", -40.0), IDX("F pod", 85.0)),
        # H -> A: iesirea din tunel (6,5 m) direct in piazzale (10 m).
        (IDX("H portal iesire", -20.0), IDX("H portal iesire", 55.0)),
    ]

    # ---- rape (len)
    ravines = [
        # 0: A / terasa 1, golul pe DREAPTA (pit). Cornisa taiata vertical, podea la +16.
        (LEN("H portal iesire", 20.0), LEN("B T1 sfarsit plat", 8.0), 9, 1),
        # 1: terasa 2, golul pe STANGA (mergem spre V, pit-ul e la S), podea la +7.
        (LEN("B T2 inceput plat", -6.0), LEN("B T2 sfarsit plat", 6.0), 9, -1),
        # 2: terasa 3, golul pe DREAPTA, podea la +2 (fundul carierei).
        (LEN("B T3 inceput plat", -6.0), LEN("B T3 sfarsit plat", 6.0), 5, 1),
        # 3: cariera de sus E, golul pe DREAPTA: 43 m pana la fundul carierei (+2).
        (LEN("D portal sus (E inceput)", 20.0), LEN("E sfarsit"), 44, 1),
        # 4: cheiul Ponti di Vara: viaduct pe ambele parti, 30 m de gol, podea la +17.
        (LEN("F pod", -15.0), LEN("F pod", 15.0), 26, 0),
    ]
    cornice = [0, 1, 2, 3, 4]
    scarp = [0, 1, 2, 3]
    viaduct = [4]
    floors = [(0, 16.0), (1, 7.0), (2, 2.0), (3, 2.0), (4, 17.0)]
    widths = [(0, 40.0), (1, 40.0), (2, 60.0), (3, 90.0), (4, 60.0)]

    # ---- berma continua de moloz (stil 2): doar pe marginile cu gol, NU pe ace, si DUPA iesirea din ac
    parapets = [
        (LEN("A start"), LEN("B T1 sfarsit plat"), 1, 2),
        (LEN("B T2 inceput plat"), LEN("B T2 sfarsit plat"), -1, 2),
        (LEN("B T3 inceput plat"), LEN("B T3 sfarsit plat"), 1, 2),
        (LEN("D portal sus (E inceput)", 20.0), LEN("E sfarsit"), 1, 2),
    ]

    # ---- sol: drum de praf peste tot, mai putin podul si Marmifera; umed pe C
    dirt = [
        (IDX("F pod", 62.0), IDX("H portal intrare", -2.0)),
        (IDX("H portal iesire", 2.0), IDX("F pod", -62.0)),
    ]
    wet = [(IDX("C intrare podea"), IDX("D portal jos"))]

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
    tunnels_txt = tunnel_node("TunelGalerie", "D portal jos", "D portal sus (E inceput)", 3.5, 9.0, 14.0) \
        + tunnel_node("TunelMarmifera", "H portal intrare", "H portal iesire", 3.25, 7.0, 12.0)

    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/hazards/tunnel_signal_hazard.gd" id="5_signal"]

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
custom_sea_level_offset = {sea_offset}
custom_wet_ranges = Array[Vector2]([{wet_txt}])
custom_dirt_ranges = Array[Vector2]([{dirt_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([{", ".join(str(i) for i in cornice)}])
custom_scarp_ravines = Array[int]([{", ".join(str(i) for i in scarp)}])
custom_viaduct_ravines = Array[int]([{", ".join(str(i) for i in viaduct)}])
custom_viaduct_net_margin = 12.0
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_ravine_widths = Array[Vector2]([{rw_txt}])
custom_width_segments = Array[Vector3]([{w_txt}])
custom_parapets = Array[Vector4]([{par_txt}])
width_flow_windows = Array[Vector2]([{fw_txt}])
terrain_pad_m = 160.0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_carrara")

[node name="Peaks" type="Node3D" parent="."]
{peaks_txt}
[node name="Hazarduri" type="Node3D" parent="."]
{tunnels_txt}"""
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
