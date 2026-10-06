# Genereaza traseul Kyoto (Track18) din waypoints cu fillet-uri de arc -- schela
# copiata din gen_jodhpur_route.py (pas uniform 12 m, statistici ca ProbeLayout)
# plus GARDA DE AZIMUT din docs/track_briefs/kyoto.md §2.0, verificata pe
# punctele coapte INAINTE sa existe .tscn-ul (orientarea buclei se hotaraste
# din cele cinci repere, nu invers -- lectia Fiordland).
#
#   python tools/gen_kyoto_route.py [scenes/tracks/Track18.tscn]
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z,
# est = +X): harta ajunge in lume FARA oglindire, deci "dreapta" de pe harta e
# dreapta si in cadrul camerei. NU e conventia lui gen_jodhpur_route.py
# (gx = -x, gz = -y), care oglindeste harta: acolo garda de azimut folosea doar
# |azimut|, deci oglindirea nu conta. Aici brieful vorbeste de stanga/dreapta
# (scena in fata-DREAPTA, pavilionul in DREAPTA, tubul pe exteriorul unei curbe la
# STANGA) si semnul se verifica in cadrul soferului, nu pe o harta oglindita.
# Sens ORAR pe plan: A spre N pe latura de vest, B/C spre E pe latura de nord,
# D/E spre S pe cea de est, F/G spre V pe cea de sud, H spre N pe latura de vest.
import math
import sys


def arc(cx, cy, r, a0, a1, step_deg=12.0, elevs=None, label="arc"):
    """Waypoints dense pe un arc (unghi matematic, grade; a1 < a0 = ORAR),
    fiecare cu fillet 0, ca Catmull-Rom sa nu strânga raza (memoria
    viraje-stranse-puncte-pe-arc)."""
    n = max(2, int(abs(a1 - a0) / step_deg + 0.5))
    out = []
    for k in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * k / n)
        e = None
        if elevs is not None:
            e = elevs[0] + (elevs[1] - elevs[0]) * k / n
        out.append((round(cx + r * math.cos(a), 2), round(cy + r * math.sin(a), 2),
                    0, e, f"{label} {k}"))
    return out


# --- Arcul lui E (Fushimi Inari): ORAR, raza 80, 147 grade. Podul Tsutenkyo are
# directia 150 grade (busola, SSE), iar arcul incepe tangent, la 30 m dupa pod:
# capatul de intrare are directia 150, cel de iesire 297. Coarda arcului e
# tunelul de torii (E'): 2 r sin(73.5) = 153 m fata de arcul de 205 m (-25%).
def unit_heading(deg):
    return (math.sin(math.radians(deg)), math.cos(math.radians(deg)))

BR_HEAD = 150.0
BR_D = unit_heading(BR_HEAD)
E_S0 = (402.0, -252.0)                  # inceputul arcului (30 m dupa pod)
E_R = 80.0
_right = unit_heading(BR_HEAD + 90.0)
E_C = (E_S0[0] + E_R * _right[0], E_S0[1] + E_R * _right[1])
E_A0 = math.degrees(math.atan2(E_S0[1] - E_C[1], E_S0[0] - E_C[0]))
E_SWEEP = 147.0
E_A1 = E_A0 - E_SWEEP    # ORAR
E_ARC = arc(E_C[0], E_C[1], E_R, E_A0, E_A1, 12.0, elevs=None, label="E arc")
E_ARC[0] = (E_ARC[0][0], E_ARC[0][1], 0, 12.0, "E arc intrare (E' se desprinde)")
E_ARC[len(E_ARC) // 2] = (E_ARC[len(E_ARC) // 2][0], E_ARC[len(E_ARC) // 2][1],
                          0, 24.0, "E arc apex (flancul Inari, +24)")
E_ARC[-1] = (E_ARC[-1][0], E_ARC[-1][1], 0, 12.0, "E arc iesire (E' revine)")
E_END_HEAD = BR_HEAD + E_SWEEP         # 297

# --- Curba lunga la STANGA a lui F: raza 200, 47 grade, centrul la stanga.
F_R = 200.0
_e_end = (E_ARC[-1][0], E_ARC[-1][1])
_left = unit_heading(E_END_HEAD - 90.0)
F_C = (_e_end[0] + F_R * _left[0], _e_end[1] + F_R * _left[1])
F_A0 = math.degrees(math.atan2(_e_end[1] - F_C[1], _e_end[0] - F_C[0]))
F_SWEEP = 47.0
F_ARC = arc(F_C[0], F_C[1], F_R, F_A0, F_A0 + F_SWEEP, 16.0, elevs=None, label="F arc")
F_ARC = F_ARC[1:]   # primul punct e chiar sfarsitul arcului lui E
F_ARC[0] = (F_ARC[0][0], F_ARC[0][1], 0, 5.0, "F intrare (spre V)")
F_ARC[len(F_ARC) // 2] = (F_ARC[len(F_ARC) // 2][0], F_ARC[len(F_ARC) // 2][1],
                          0, 0.0, "F curba stanga mijloc (shishi-odoshi)")
F_ARC[-1] = (F_ARC[-1][0], F_ARC[-1][1], 0, 0.0, "F curba stanga sfarsit")
F_END = (F_ARC[-1][0], F_ARC[-1][1])
F_END_HEAD = E_END_HEAD - F_SWEEP     # 250

WPTS_RAW = [
    # --- A: start Yasaka-dori, drept spre N, pagoda pe ax in capat ---
    (0,    0,    0,  0.0,  "A start Yasaka-dori"),
    (0,    100,  0,  2.0,  "A sfarsit (urcare 2%)"),

    # --- B: Sannenzaka. Colt dreapta la 18 m sub pagoda, apoi doua S-uri
    # stranse spre E, urcare spre +14 ---
    (0,    188,  26, 4.0,  "B colt pagoda (ocol 18 m)"),
    (70,   190,  0,  None, "B drept spre S1"),
    (98,   212,  22, 8.0,  "B S1 stanga"),
    (130,  192,  22, None, "B S1 dreapta"),
    (152,  176,  0,  None, "B S2 intrare"),
    (176,  188,  18, 14.0, "B S2 iesire"),

    # --- C: Kiyomizu-dera. C1 spre E pe buza, urcare 14 -> 32; colt dreapta
    # pe latura de vest a salii; puntea scenei spre S, 55 m la +32 ---
    (250,  196,  0,  None, "C1 Niomon"),
    (325,  202,  0,  None, "C1 inainte de colt"),
    (362,  198,  24, None, "C colt dreapta spre scena"),
    (364,  168,  0,  32.0, "C scena intrare"),
    (364,  118,  0,  32.0, "C scena inainte de buza"),
    (364,  104,  0,  32.0, "C scena capat (buza)"),
    # --- C2: golul de ~20 m, aterizare pe versantul opus la +26 ---
    (364,  96,   0,  25.0, "C2 aterizare"),
    (364,  84,   0,  24.2, "C2 aterizare coborare 1"),

    # --- D: valea de artari, S-uri largi spre S; podul Tsutenkyo drept pe
    # directia 150 (SSE), de unde arcul lui E continua tangent ---
    (364,  68,   0,  22.5, "C2 panta de aterizare"),
    (366,  40,   0,  None, "D aterizare coborare"),
    (396,  -14,  40, 22.0, "D S1 dreapta"),
    (352,  -86,  40, 18.5, "D S1 stanga"),
    (round(E_S0[0] - 100.0 * BR_D[0], 2), round(E_S0[1] - 100.0 * BR_D[1], 2), 0, 14.5, "D inainte de pod"),
    (round(E_S0[0] - 70.0 * BR_D[0], 2), round(E_S0[1] - 70.0 * BR_D[1], 2), 0, 12.0, "D pod Tsutenkyo intrare"),
    (round(E_S0[0] - 30.0 * BR_D[0], 2), round(E_S0[1] - 30.0 * BR_D[1], 2), 0, 12.0, "D pod Tsutenkyo iesire"),
] + E_ARC + F_ARC + [
    # --- G: bambus, doua S-uri, colt SV ---
    (104,  -410, 22, 1.0,  "G S1 intrare"),
    (60,   -470, 26, 3.0,  "G S1 apex"),
    (8,    -494, 26, 5.0,  "G S2 apex"),
    (-54,  -462, 26, 6.0,  "G S2 iesire"),
    (-66,  -410, 0,  5.0,  "G2 sub podul trenului"),

    # --- H: podul Togetsuky (150 m) si dreapta finala spre pagoda ---
    (-58,  -356, 0,  3.0,  "H pod Togetsukyo intrare"),
    (-36,  -216, 0,  3.0,  "H pod Togetsukyo iesire"),
    (-10,  -140, 30, 1.5,  "H dreapta finala"),
    (0,    -50,  0,  0.2,  "H grila"),
]
SCALE = 1.0
WPTS = [(round(x * SCALE, 2), round(y * SCALE, 2), round(r * SCALE, 2), e, lbl)
        for x, y, r, e, lbl in WPTS_RAW]


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
        if turn < math.radians(8) or r <= 0.0:
            pts.append((p[0], p[1], i))
            continue
        t = r / math.tan(ang / 2.0)
        lim1 = math.hypot(*v(p, p_prev)) * 0.5
        lim2 = math.hypot(*v(p, p_next)) * 0.5
        if t > min(lim1, lim2):
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
        steps = max(2, int(abs(sweep) / math.radians(22)) + 1)
        for k in range(steps + 1):
            a = a1 + sweep * k / steps
            pts.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a),
                        i if k == steps // 2 else None))
    out = []
    for p in pts:
        if out and math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) < 2.0:
            if p[2] is not None and out[-1][2] is None:
                out[-1] = (out[-1][0], out[-1][1], p[2])
            continue
        out.append(p)
    if len(out) > 1 and math.hypot(out[0][0] - out[-1][0],
                                   out[0][1] - out[-1][1]) < 2.0:
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

def resample(pts, elevs, step, local=None):
    """Esantioneaza la pas uniform. `local(x, y)` poate da un pas mai mic
    (zona sariturii C2: o curba Catmull-Rom cu puncte la 12 m nu poate cobori
    6 m intre buze si ramane plata la ambele capete)."""
    cum = cum_lengths(pts)
    total = cum[-1]
    out = []
    target, j = 0.0, 0
    while target < total:
        while cum[j + 1] < target:
            j += 1
        a, b = pts[j], pts[(j + 1) % len(pts)]
        f = (target - cum[j]) / max(1e-6, cum[j + 1] - cum[j])
        x, y = a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
        out.append((x, y, elevs[j] + (elevs[(j + 1) % len(pts)] - elevs[j]) * f))
        target += local(x, y) if local is not None else step
    return out

def jump_step(x, y):
    return 4.0 if (abs(x - 364.0) < 10.0 and 82.0 <= y <= 120.0) else 12.0

pts = fillet_loop(WPTS)
elevs, cum, total = assign_elev(pts, WPTS)

CTRL_STEP = 12.0
ctrl = resample(pts, elevs, CTRL_STEP, jump_step)
if math.hypot(ctrl[0][0] - ctrl[-1][0], ctrl[0][1] - ctrl[-1][1]) < CTRL_STEP * 0.5:
    ctrl.pop()
ctrl_tag = [None] * len(ctrl)
ctrl_tag_dist = [1e9] * len(ctrl)
# Eticheta cea mai APROPIATA, nu ultima (capcana gasita la Jodhpur).
for j, p in enumerate(pts):
    if p[2] is None:
        continue
    best, bd = 0, 1e9
    for k, q in enumerate(ctrl):
        d = math.hypot(q[0] - p[0], q[1] - p[1], q[2] - elevs[j])
        if d < bd:
            best, bd = k, d
    if bd < ctrl_tag_dist[best]:
        ctrl_tag[best] = p[2]
        ctrl_tag_dist[best] = bd
pts = [(q[0], q[1], ctrl_tag[k]) for k, q in enumerate(ctrl)]
elevs = [q[2] for q in ctrl]
cum = cum_lengths(pts)
total = cum[-1]
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime: {total:.0f} m  (tinta ~2200 m)")

frac = {}
for i, w in enumerate(WPTS):
    for j, p in enumerate(pts):
        if p[2] == i:
            frac[w[4]] = cum[j] / total
            break

def signed_area(seq):
    a = 0.0
    for i in range(len(seq)):
        x0, y0 = seq[i][0], seq[i][1]
        x1, y1 = seq[(i + 1) % len(seq)][0], seq[(i + 1) % len(seq)][1]
        a += x0 * y1 - x1 * y0
    return a / 2.0
area = signed_area(pts)
print(f"aria cu semn (harta): {area:+.0f}  ({'CW pe harta (corect, brief cere sens orar)' if area < 0 else 'CCW pe harta -- GRESIT, brief cere ORAR'})")

centroid_x = sum(p[0] for p in pts) / len(pts)
centroid_y = sum(p[1] for p in pts) / len(pts)
max_dist = max(math.hypot(p[0] - centroid_x, p[1] - centroid_y) for p in pts)
max_cheb = max(max(abs(p[0] - centroid_x), abs(p[1] - centroid_y)) for p in pts)
print(f"centroid harta: ({centroid_x:.1f}, {centroid_y:.1f})   raza maxima: {max_dist:.1f} m  Cebasev (zidul lumii, 420): {max_cheb:.1f} m")

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
print(f"raza minima: {min_r:.1f} m la frac {min_r_at:.3f}  (prag >= 9 m)")
print(f"panta maxima: {max_slope*100:.1f}% la frac {max_slope_at:.3f}  (prag < 13%)")

def section_slopes(name, f0, f1):
    sl = []
    for i in range(len(rs)):
        f = i * 12.0 / total
        if f0 <= f <= f1:
            b, c = rs[i], rs[(i + 1) % len(rs)]
            d = math.hypot(c[0] - b[0], c[1] - b[1])
            sl.append((c[2] - b[2]) / max(1e-6, d))
    if sl:
        print(f"{name} {f0:.3f}-{f1:.3f}: panta medie {100*sum(sl)/len(sl):+.1f}%  varf {100*max(sl, key=abs):+.1f}%")

section_slopes("B", frac["B colt pagoda (ocol 18 m)"], frac["B S2 iesire"])
section_slopes("rampa C spre scena", frac["B S2 iesire"], frac["C scena intrare"])
section_slopes("D", frac["D aterizare coborare"], frac["D pod Tsutenkyo intrare"])
section_slopes("urcare Inari", frac["E arc intrare (E' se desprinde)"], frac["E arc apex (flancul Inari, +24)"])
section_slopes("coborare Inari", frac["E arc apex (flancul Inari, +24)"], frac["E arc iesire (E' revine)"])
section_slopes("G", frac["G S1 intrare"], frac["G2 sub podul trenului"])
section_slopes("H", frac["H pod Togetsukyo intrare"], 0.999)

min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 31, len(rs)):
        if len(rs) - (j - i) <= 30:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        if d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima XZ: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f}  (prag >= 20 m)")

mean_elev = sum(elevs) / len(elevs)
print(f"cota medie sosea: {mean_elev:.1f} m")
# Marea: nu exista in Kyoto (tema fara `water`), dar plasa globala
# `_build_sea_respawn` ramane (sea_y = media + offset). Tinta: SUB cel mai jos
# punct de apa/rapa declarat (raul -6, iazul -3, rapa Tsutenkyo -4) => -22.
SEA_LEVEL_TARGET_ABS = -22.0
sea_offset = round(SEA_LEVEL_TARGET_ABS - mean_elev, 2)
print(f"sea_level_offset ales: {sea_offset} (marea absoluta {SEA_LEVEL_TARGET_ABS} m)")

print("\nfractii waypoint:")
for w in WPTS:
    if w[4].startswith("E arc ") and not ("intrare" in w[4] or "apex" in w[4] or "iesire" in w[4]):
        continue
    print(f"  {frac[w[4]]:.3f}  {w[4]}  (cota {w[3] if w[3] is not None else float('nan'):.1f})")

# ---------------------------------------------------------------------------
# GARDA DE AZIMUT (brief §2.0 / §7 pasul 2). Reperele sunt puncte FIXE ale
# schitei (pagoda, scena, pavilionul), nu derivate din traseu -- garda nu se
# auto-confirma (memoria garda-circulara-propria-functie).
PAGODA_XY = (4.0, 200.0)          # Yasaka: 15-25 m de coltul B, pe axa gridului
SCENE_XY = (324.0, 137.0)         # mijlocul puntii Kiyomizu
KOYASU_XY = (348.0, 30.0)         # pagoda Koyasu, pe versantul de aterizare
# POI F r2: pozitia REALA (tools/gen_decor_kyoto_f.gd): malul de VEST al iazului
# (iazul real ~100 x 100 m; vechiul (150, -300) cadea in mijlocul apei).
KINKAKU_XY = (117.6, -285.0)      # pavilionul, pe malul de vest al iazului
CENTROID_XY = (centroid_x, centroid_y)

def heading_deg(dx, dy):
    return math.degrees(math.atan2(dx, dy))  # 0 = +y (nord), 90 = +x (est)

def azimut_to(idx, target_xy):
    """Azimutul (grade) al reperului fata de directia de mers la punctul copt
    `idx`: 0 = drept in fata, + = dreapta."""
    p = rs[idx]
    nxt = rs[(idx + 1) % len(rs)]
    heading = heading_deg(nxt[0] - p[0], nxt[1] - p[1])
    to_t = heading_deg(target_xy[0] - p[0], target_xy[1] - p[1])
    return (to_t - heading + 180.0) % 360.0 - 180.0

def frac_range_indices(f0, f1):
    n = len(rs)
    i0, i1 = int(f0 * n), int(f1 * n)
    return list(range(i0, i1 + 1)) if i0 <= i1 else list(range(i0, n)) + list(range(0, i1 + 1))

def dist_to(i, xy):
    return math.hypot(rs[i][0] - xy[0], rs[i][1] - xy[1])

guard_results = []

def report(ok, text):
    guard_results.append(ok)
    print(f"  [{'OK' if ok else 'PROBLEMA'}] {text}")

print("\n=== GARDA DE AZIMUT (brief §2.0) ===")

# 1. Pagoda Yasaka, pe ax, intreaga de pe grila: ultimele 40 m inainte de linia
# de start sunt locurile grilei. Contract: >= 200 m de la ULTIMUL loc din grila
# (cel mai din spate, ~40 m inainte de linie) si azimut <= 8.
n_rs = len(rs)
grid_idx = [n_rs - k for k in range(1, 5)]            # ~12..48 m inainte de start
worst_az = max(abs(azimut_to(i, PAGODA_XY)) for i in grid_idx)
min_d = min(dist_to(i, PAGODA_XY) for i in grid_idx)
report(worst_az <= 8.0 and min_d >= 200.0,
       f"A pagoda Yasaka pe ax de pe grila: azimut maxim {worst_az:.1f} deg (prag 8), "
       f"distanta minima de la un loc din grila {min_d:.0f} m (prag 200)")

# Ocolul pagodei (B): drumul trece la 15-25 m de baza.
b_idx = frac_range_indices(frac["A sfarsit (urcare 2%)"], frac["B S1 stanga"])
near_d = min(dist_to(i, PAGODA_XY) for i in b_idx)
report(15.0 <= near_d <= 25.0, f"B ocolul pagodei: cea mai mica distanta la baza {near_d:.1f} m (15-25)")

# H -> pagoda apare pe ultima treime a dreptei (azimut <= 15 deg).
h_idx = frac_range_indices(frac["H dreapta finala"], 0.999)
h_ok = sum(1 for i in h_idx if abs(azimut_to(i, PAGODA_XY)) <= 15.0)
report(h_ok / max(1, len(h_idx)) >= 0.9,
       f"H pagoda in cadru pe dreapta finala: {h_ok}/{len(h_idx)} puncte cu |azimut| <= 15")

# 2. Scena Kiyomizu in fata-dreapta (20-45 deg), la 100-140 m, de pe C1.
c1 = frac_range_indices(frac["B S2 iesire"], frac["C colt dreapta spre scena"])
sel = [i for i in c1 if 100.0 <= dist_to(i, SCENE_XY) <= 140.0]
ok = sum(1 for i in sel if 20.0 <= azimut_to(i, SCENE_XY) <= 45.0)
report(len(sel) > 0 and ok / len(sel) >= 0.7,
       f"C1 scena in fata-dreapta (20-45 deg) la 100-140 m: {ok}/{len(sel)} puncte "
       f"({100*ok/max(1,len(sel)):.0f}%, prag 70%)")

# 3. Scena iese spre S, spre interiorul buclei: directia puntii cu ~S (150-210
# busola) si centroidul in fata pe directia ei.
deck = frac_range_indices(frac["C scena intrare"], frac["C scena capat (buza)"])
hd = [heading_deg(rs[(i + 1) % n_rs][0] - rs[i][0], rs[(i + 1) % n_rs][1] - rs[i][1]) % 360.0 for i in deck]
toward = [azimut_to(i, CENTROID_XY) for i in deck]
report(all(150.0 <= h <= 210.0 for h in hd) and all(abs(t) <= 60.0 for t in toward),
       f"C scena orientata spre S/interior: directie {min(hd):.0f}-{max(hd):.0f} busola, "
       f"centroidul la azimut maxim {max(abs(t) for t in toward):.0f} deg (prag 60)")

# Koyasu in fata de pe scena, la 60-100 m, azimut <= 15.
sel = [i for i in deck if 60.0 <= dist_to(i, KOYASU_XY) <= 110.0]
ok = sum(1 for i in sel if abs(azimut_to(i, KOYASU_XY)) <= 15.0)
report(len(sel) > 0 and ok == len(sel),
       f"C2 Koyasu in fata de pe scena: {ok}/{len(sel)} puncte la 60-110 m cu |azimut| <= 15")

# 4. Pavilionul in dreapta pe F. POI F r2 (pozitia reala, acceptata de
# coordonator pe captura): de pe apropierea de daruma pavilionul e la 100-150 m,
# 15-45 deg dreapta (vazut peste apa); sub 100 m drumul a trecut deja de el si
# azimutul sare peste 45 (iese din cadru lateral, corect: decizia e la daruma).
f_idx = frac_range_indices(frac["F intrare (spre V)"], frac["F curba stanga sfarsit"])
sel = [i for i in f_idx if 100.0 <= dist_to(i, KINKAKU_XY) <= 150.0]
ok = sum(1 for i in sel if 15.0 <= azimut_to(i, KINKAKU_XY) <= 45.0)
report(len(sel) > 0 and ok / len(sel) >= 0.6,
       f"F pavilionul in dreapta (15-45 deg) la 100-150 m: {ok}/{len(sel)} puncte "
       f"({100*ok/max(1,len(sel)):.0f}%, prag 60%)")

# 5. Turnul daruma-otoshi (inainte: tubul): pe exteriorul unei curbe la STANGA, cu
# fata spre tine, intreg in cadru (|azimut| <= 30) pe [150, 35] m inaintea lui.
# Turnul sta pe dreapta.
f_tub = frac["F curba stanga mijloc (shishi-odoshi)"]
tub_i = int(f_tub * n_rs)
nxt = rs[(tub_i + 1) % n_rs]
hx, hy = nxt[0] - rs[tub_i][0], nxt[1] - rs[tub_i][1]
l = math.hypot(hx, hy)
hx, hy = hx / l, hy / l
# Daruma-otoshi (inlocuieste tubul): centrul turnului sta la semilatime + 1,7 m + raza discului (2 m)
PIVOT_OFFSET = 5.5 + 1.7 + 2.0
TUB_XY = (rs[tub_i][0] + hy * PIVOT_OFFSET, rs[tub_i][1] - hx * PIVOT_OFFSET)  # dreapta
# curba la stanga: schimbarea de directie pe +-40 m
def heading_at(i):
    a, b = rs[i % n_rs], rs[(i + 1) % n_rs]
    return heading_deg(b[0] - a[0], b[1] - a[1])
dh = (heading_at(tub_i + 3) - heading_at(tub_i - 3) + 180) % 360 - 180
report(dh < -10.0, f"F carul Gion pe exteriorul unei curbe la STANGA: schimbare de directie {dh:+.0f} deg pe 72 m (negativ = stanga)")
sel = [i for i in range(tub_i - 14, tub_i) if 35.0 <= math.hypot(rs[i][0] - rs[tub_i][0], rs[i][1] - rs[tub_i][1]) <= 150.0]
ok = sum(1 for i in sel if abs(azimut_to(i, TUB_XY)) <= 30.0)
report(len(sel) > 0 and ok / len(sel) >= 0.8,
       f"F carul Gion intreg in cadru pe [150,35] m: {ok}/{len(sel)} puncte cu |azimut| <= 30 ({100*ok/max(1,len(sel)):.0f}%, prag 80%)")

all_ok = all(guard_results)
print(f"\nGARDA DE AZIMUT: {'TOATE TREC' if all_ok else 'CEL PUTIN O LINIE A PICAT'}")


def godot(p, e):
    return (p[0], e, -p[1])

def r3(x):
    return round(x, 3)

def road_at_frac(f):
    return rs[int(f * n_rs) % n_rs]

# Lungimea curbei COAPTE in joc (Track18, masurata cu tools/train_cam_meter.gd /
# route.dists[n]); poligonul de control are 2126 m, curba Catmull-Rom 2135.1 m.
# Fractiile din .tscn sunt pe curba coapta, deci metrii se convertesc cu ea.
BAKED_TOTAL_M = 2135.1
_rs_cum = cum_lengths(rs)

def road_at_arc(f):
    """Ca road_at_frac, dar INTERPOLAT pe lungimea de arc (road_at_frac ia
    esantionul rs de dedesubt, la pas de 12 m, deci rotunjeste cu pana la 12 m)."""
    sd = (f % 1.0) * _rs_cum[-1]
    j = 0
    while j < len(rs) - 1 and _rs_cum[j + 1] < sd:
        j += 1
    a, b = rs[j], rs[(j + 1) % len(rs)]
    t = (sd - _rs_cum[j]) / max(1e-6, _rs_cum[j + 1] - _rs_cum[j])
    pos = tuple(a[k] + (b[k] - a[k]) * t for k in range(3))
    l = math.hypot(b[0] - a[0], b[1] - a[1])
    return pos, ((b[0] - a[0]) / l, (b[1] - a[1]) / l)

def heading_vec_at_frac(f):
    i = int(f * n_rs) % n_rs
    a, b = rs[i], rs[(i + 1) % n_rs]
    l = math.hypot(b[0] - a[0], b[1] - a[1])
    return ((b[0] - a[0]) / l, (b[1] - a[1]) / l)

def godot_basis_row_text(f, x, y, z):
    """Transform3D cu -Z pe sensul de mers (hazard pe axa soselei). Formatul
    tscn e pe RANDURI (memoria tscn-transform-e-pe-randuri)."""
    hx, hy = heading_vec_at_frac(f)
    fx, fz = hx, -hy  # directia in Godot (gx = x, gz = -y)
    return (f"Transform3D({-fz:.5f}, 0, {-fx:.5f}, 0, 1, 0, {fx:.5f}, 0, {-fz:.5f}, "
            f"{x:.3f}, {y:.3f}, {z:.3f})")


if len(sys.argv) > 1:
    if not all_ok:
        print("\nSCRIEREA .tscn CONTINUA, dar garda de azimut a picat -- vezi liniile PROBLEMA.")

    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]

    F = frac
    f_scene_a = F["C scena intrare"]
    f_scene_b = F["C scena capat (buza)"]
    f_land = F["C2 aterizare"]
    f_bridge_a = F["D pod Tsutenkyo intrare"]
    f_bridge_b = F["D pod Tsutenkyo iesire"]
    # Covorul de frunze (LeafCarpet, brief §3): D de la aterizare pana inainte de
    # gura podului (podul acoperit nu are frunze pe tablier), E de dupa pod pana
    # la Inari (frunzele mai rare: altare, cedri), F pana la bambus (0,4). (de la, pana la, densitate.)
    carpet_zones = ", ".join(
        f"Vector3({r3(a)}, {r3(b)}, {d})" for a, b, d in (
            (F["D aterizare coborare"] + 0.004, f_bridge_a - 0.009, 1.0),
            (f_bridge_b + 0.006, 0.56, 0.6),
            # F: iazul si pavilionul, pana la prima tulpina de bambus (G): frunzele
            # se subtiaza de la 0,6 la 0,4 si se topesc la 0,674 (masurat cu
            # tools/ProbeKyotoFix.tscn: PadureMasa "bambus G tulpini" incepe la
            # frac 0,6739, prima tufa manuala la 0,6827). Lipita de zona E.
            (0.56, 0.674, 0.4)))
    f_togetsu_a = F["H pod Togetsukyo intrare"]
    f_togetsu_b = F["H pod Togetsukyo iesire"]
    f_f_a = F["F intrare (spre V)"]
    f_f_b = F["F curba stanga sfarsit"]

    # RAPE (indici in ordinea de mai jos):
    #   0: sub scena + golul C2 (viaduct, podea +16, arțarii din rapa)
    #   1: sub Tsutenkyo (viaduct, podea -4)
    #   2: raul Katsura sub Togetsukyo (viaduct, podea -6, apa -3)
    #   3: iazul pavilionului (pe dreapta lui F, podea -3, apa -1)
    ravines = [
        # Inceputul rapei urca cu ~0,016 inaintea puntii: fade-ul de capat al
        # rapelor (RAVINE_FADE_FRAC 0,02 ~ 43 m) altfel lasa doar ~4 m adancime
        # la intrarea pe punte (profil masurat, ProbeKyotoRapa).
        (r3(f_scene_a - 0.020), r3(f_land + 0.004), 16.0, 0, "scena + golul C2"),
        (r3(f_bridge_a - 0.006), r3(f_bridge_b + 0.006), 16.0, 0, "Tsutenkyo"),
        (r3(f_togetsu_a - 0.008), r3(f_togetsu_b + 0.008), 6.0, 0, "raul Katsura"),
        (r3(f_f_a), r3(f_f_b), 3.0, 1, "iazul pavilionului"),
    ]
    RAVINE_FLOOR = [(0, 16.0), (1, -4.0), (2, -6.0), (3, -3.0)]
    RAVINE_WIDTH = [(0, 50.0), (1, 45.0), (2, 70.0), (3, 90.0)]
    RAVINE_WATER = [(2, -3.0, 14.0), (3, -1.0, 10.0)]
    # LIMBA DE MAL sub odihna carului Gion Matsuri (4 oct 2026, dezvoltatorul: "pare
    # ca pluteste peste lac"): pe iaz (rapa 3) netezirea sapaturii punea malul de
    # langa asfalt la -1,0 = cota apei. (rapa, fractia carului, semilungime 7 m,
    # 12 m dincolo de asfalt; racord 8 m): odihna la x 7-13 m sta pe -0,2..-0,3.
    RAVINE_CAPES = [(3, 0.6329, 7.0, 12.0)]
    VIADUCTS = [0, 1, 2]
    rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d, _ in ravines)
    fl_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_FLOOR)
    rw_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_WIDTH)
    wt_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in RAVINE_WATER)
    cp_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d in RAVINE_CAPES)

    # LATIMI (semilatimi, tabelul din brief §2):
    # A 8, B 5.5, C 5 (rampa) / 6 (scena), C2 6, D 6 / 4.5 (pod), E 6,
    # F 5.5 (la tub) / 6.5, G 5, G2 6, H 7.
    ws = [
        (0.0, F["A sfarsit (urcare 2%)"] + 0.01, 8.0),
        (F["A sfarsit (urcare 2%)"] + 0.01, F["B S2 iesire"], 5.5),
        (F["B S2 iesire"], F["C scena intrare"] - 0.004, 5.0),
        (F["C scena intrare"] - 0.004, F["D aterizare coborare"], 6.0),
        (F["D aterizare coborare"], f_bridge_a - 0.006, 6.0),
        (f_bridge_a - 0.006, f_bridge_b + 0.006, 4.5),
        (f_bridge_b + 0.006, F["F intrare (spre V)"], 6.0),
        (F["F intrare (spre V)"], F["F curba stanga sfarsit"], 5.5),
        (F["F curba stanga sfarsit"], F["G S2 apex"], 5.0),
        (F["G S2 apex"], f_togetsu_a, 6.0),
        (f_togetsu_a, 0.999, 7.0),
    ]
    w_txt = ", ".join(f"Vector3({r3(a)}, {r3(b)}, {c})" for a, b, c in ws)

    # E' (tunelul de torii): TrackBranch dreapta pe COARDA arcului lui E.
    e_in = F["E arc intrare (E' se desprinde)"]
    e_out = F["E arc iesire (E' revine)"]
    p_in = road_at_frac(e_in)
    p_out = road_at_frac(e_out)
    chord = math.hypot(p_out[0] - p_in[0], p_out[1] - p_in[1])
    mid_xy = ((p_in[0] + p_out[0]) / 2.0, (p_in[1] + p_out[1]) / 2.0)
    mid_e = (p_in[2] + p_out[2]) / 2.0
    tunnel_pts = [godot(mid_xy, mid_e)]
    # lungimea arcului pe bucla
    arc_len = (e_out - e_in) * total
    print(f"\nE': coarda {chord:.0f} m fata de arcul {arc_len:.0f} m "
          f"(-{100*(1-chord/arc_len):.0f}%, tinta ~-25%); entry_at={e_in:.4f} exit_at={e_out:.4f}")
    # Camera tunelului: cutie rotita pe coarda, ceva mai scurta ca sa nu prinda
    # bucla principala la capete.
    tdx, tdy = (p_out[0] - p_in[0]) / chord, (p_out[1] - p_in[1]) / chord
    # (fx, fz) in Godot = (tdx, -tdy); -Z local = directia coardei; tscn pe randuri.
    tun_basis = (f"Transform3D({tdy:.5f}, 0, {-tdx:.5f}, 0, 1, 0, {tdx:.5f}, 0, {tdy:.5f}, ")
    tun_g = godot(mid_xy, mid_e)

    # Peak-uri: muntele Inari (centrul arcului E, inaltat), versantul
    # Higashiyama (spatele sălii Kiyomizu, la N-NE de scena) si dealul din
    # fundalul gradinii.
    inari_g = godot((E_C[0], E_C[1]), 40.0)
    higashi_g = godot((372.0, 150.0), 60.0)
    hill_f_g = godot((60.0, -300.0), 24.0)

    # RespawnZone-uri: NU se mai declara de mana. Le construieste Track singur:
    # `ViaductNet0/1/2` sub fiecare viaduct (plasa de sub scena are elan de 70 m,
    # `custom_viaduct_net_backoffs`), `ChannelFall_*` sub gol si `RavineWater_*`
    # in iaz si in rau. Cutiile de mana (RapaScena/RapaTsutenkyo, repunere cu
    # 14 m) se calcau cu plasa si readuceau masina la 14 m de buza: fara elan,
    # bucla de caderi (masurat cu ProbeRace, 185 de repuneri pe o cursa).
    zones = []
    scene_mid = road_at_frac((f_scene_a + f_scene_b) / 2.0)
    br_mid = road_at_frac((f_bridge_a + f_bridge_b) / 2.0)
    # GOLUL C2. Brief: ~20 m (calcul cu g = 9,8 si cadere de 6 m). Masurat cu
    # ProbeJump pe fizica reala (gravitatie arcade ~28 m/s^2, trambulina de
    # +7 m/s la desprindere, cadere de ~3 m intre buze): la 20 m gol obtinut
    # 20,9 m trece abia de la ~28 m/s; la 16,4 m, Autobuzul (plafonul 30,
    # AI x0,88-0,97) pica sub 28 m/s; la 12,17 m trece de la 26 m/s si in
    # ProbeRace 16 seed-uri trece de la 24 m/s (viteza reala la buza). Golul se
    # roteste la multipli de ~4,1 m (pasul curbei coapte): 8 / 12,2 / 16,4 / 20,9.
    # Brief §3: "daca Autobuzul nu trece fara turbo, se strange golul, nu
    # creste viteza" => 12,2 m.
    SCENE_GAP_M = 12.0
    gap_node_xy = (364.0, 100.0)
    gap_y = 30.0
    gap_g = godot(gap_node_xy, gap_y)

    # Hazarduri: tubul pe axa soselei la frac F tub, cu directia mersului
    tub_road = rs[tub_i]
    tub_g = godot((tub_road[0], tub_road[1]), tub_road[2])
    tub_xf = godot_basis_row_text(f_tub, *tub_g)
    print(f"tub: axa ({tub_road[0]:.1f},{tub_road[1]:.1f}) cota {tub_road[2]:.1f} frac {f_tub:.3f}; "
          f"pivot (dreapta, {PIVOT_OFFSET} m): ({TUB_XY[0]:.1f},{TUB_XY[1]:.1f})")

    # KOGARASHI (§3.1 decizia 1): vartejul de frunze, la iesirea de pe Tsutenkyo
    # (~25 m dupa capatul podului, unde incepe arcul lui E). Reutilizeaza
    # DustDevilHazard (Serengeti) cu leaf_mode; kick x0,6 fata de Serengeti
    # (spin 180 -> 108 grade, ridicare 2,5 -> 1,5 m, orbire 0,6 -> 0,35 s).
    # Figura Lissajous e rotita cu 30 grade ca axa X locala sa fie TRANSVERSALA
    # pe sosea (directia mersului la pod: 150 grade busola); perioada pe axa
    # transversala 1/0,0345 = ~29 s (brief §3).
    # Distanta dupa capatul podului, in metri pe lungimea curbei (total, m).
    # 3 oct 2026 (dezvoltatorul: "la iesirea din pod nu se citeste"): era la 5,6 m
    # MASURAT dupa capatul podului (road_at_frac rotunjea la esantionul de 12 m);
    # acum 14 m nominal = 17,7 m masurat pe curba coapta cu tools/ProbeKyotoFix.tscn.
    # Candidatii 10 / 14 / 18,5 m, 16 seed-uri ProbeRace: vezi brief §3.0.
    import os
    KOG_DUPA_POD_M = float(os.environ.get("KOG_DUPA_POD_M", "14"))
    # Capatul podului in .tscn e r3(f_bridge_b) (frac_to), in metri pe curba coapta.
    f_kog = r3(f_bridge_b) + KOG_DUPA_POD_M / BAKED_TOTAL_M
    kog_road, kog_head = road_at_arc(f_kog)
    # Axa lunga a figurii Lissajous (X local, rotita cu yaw in jurul lui Y) trebuie
    # sa fie TRANSVERSALA pe sosea. Rotatia Godot cu yaw: X local -> bearing
    # (90 - yaw) busola; transversala la mers (bearing H) = H + 90 => yaw = 180 - H.
    kog_bearing = math.degrees(math.atan2(kog_head[0], kog_head[1])) % 360.0
    kog_yaw = (180.0 - kog_bearing) % 180.0
    kog_g = godot((kog_road[0], kog_road[1]), kog_road[2])
    _bb = road_at_frac(f_bridge_b)
    print(f"capat pod Tsutenkyo: frac {f_bridge_b:.4f} axa ({_bb[0]:.1f},{_bb[1]:.1f}) cota {_bb[2]:.1f}; "
          f"kogarashi la {KOG_DUPA_POD_M:.1f} m dupa el")
    print(f"kogarashi: busola drum {kog_bearing:.1f} deg => path_yaw_deg {kog_yaw:.1f}")
    print(f"kogarashi: frac {f_kog:.4f} axa ({kog_road[0]:.1f},{kog_road[1]:.1f}) cota {kog_road[2]:.1f}")
    # NAVETA (4 oct 2026, dezvoltatorul, sageata pe captura): vartejul nu mai taie
    # soseaua pe loc, ci face naveta pe o diagonala din iarba din STANGA pana in GURA
    # tunelului de torii: scurtatura se ia doar cand vartejul nu e acolo. Suprascrie
    # pozitia de mai sus. Capetele sunt masurate in Godot pe rutele COAPTE (banda E'
    # exista doar acolo), nu calculate aici. Figura e o linie (amplitudine pe Z = 0),
    # deci sinusul o tine mai mult la capete: ~5 s din 25 s in gura.
    KOG_A = (397.1, 225.7)  # Godot x,z: d=1007 m, 8,9 m in stanga axei (iarba, teren 11,2)
    KOG_B = (393.2, 260.6)  # Godot x,z: pe axa benzii E' (0,5 m), 5,8 m dincolo de asfalt
    KOG_Y = 11.75           # terenul pe linie e 11,6-11,7; la capatul A 11,2
    kog_g = ((KOG_A[0] + KOG_B[0]) / 2, KOG_Y, (KOG_A[1] + KOG_B[1]) / 2)
    _kl = math.hypot(KOG_B[0] - KOG_A[0], KOG_B[1] - KOG_A[1])
    kog_half = _kl / 2
    # X local rotit cu yaw (Vector3.rotated pe UP): (cos, -sin) in (x, z).
    kog_yaw = math.degrees(math.atan2(-(KOG_B[1] - KOG_A[1]) / _kl, (KOG_B[0] - KOG_A[0]) / _kl))
    print(f"kogarashi naveta: centru ({kog_g[0]:.2f},{kog_g[2]:.2f}) semilungime {kog_half:.2f} m yaw {kog_yaw:.1f}")

    # SHISHIMAI (POI H): leul care danseaza peste soseaua dreptei finale. Pe esantionul
    # 170 al axei (frac 0,955): ultimul tronson DREPT (167-171, directia 83,7 deg, 48 m)
    # dupa curbura de la iesirea din Togetsukyo (0,894) si inainte de arcul usor spre
    # grila (0,966+), cu 24 m de dreapta in spatele lui pentru citirea telegrafului si
    # ~47 m pana la primul loc din grila (0,977), deci nu atinge startul. Pozitia e pe un
    # esantion al axei, nu la o fractie rotunjita (road_at_frac ia esantionul de DEDESUBT).
    SHI_I = 170
    shi_road = rs[SHI_I]
    shi_g = godot((shi_road[0], shi_road[1]), shi_road[2])
    shi_xf = godot_basis_row_text((SHI_I + 0.5) / n_rs, *shi_g)
    print(f"shishimai: esantion {SHI_I} frac {SHI_I / n_rs:.4f} axa ({shi_road[0]:.1f},{shi_road[1]:.1f}) cota {shi_road[2]:.1f}")


    # --- GRUPA PADUREA IN MASA (MeshForest, scenes/props/mesh_forest.gd) ---------
    # Arborii kitului in MultiMesh feliat, dincolo de primul rand de langa drum
    # (brief §2, §5.6). Zonele sunt DATE (resurse MeshForestZone); plasarea pe
    # teren real, distanta fata de drum, marea si zidul lumii se rezolva la rulare.
    # Petele de ginkgo vin PRIMELE: au `claim` si scot artarii din pata.
    def _patch_center(f, lat_signed):
        # lat_signed > 0 = dreapta fata de sens (harta: (hy, -hx)), < 0 = stanga.
        rp = road_at_frac(f)
        hx, hy = heading_vec_at_frac(f)
        mx = rp[0] + hy * lat_signed
        my = rp[1] - hx * lat_signed
        return (mx, -my)   # Godot: gx = x, gz = -y

    MAPLES = ("momiji_a", "momiji_b", "momiji_c")
    forest_zones = []   # dictionare, scrise mai jos ca sub_resource-uri

    def fz(label, kind, species, weights, **kw):
        d = dict(label=label, kind=kind, species=species, weights=weights)
        d.update(kw)
        forest_zones.append(d)

    # === POI C (Kiyomizu) === LUMINISURI: discuri cu `claim` si fara specii
    # (MeshForest le citeste ca rezervare), PRIMELE in lista, ca sa goleasca
    # zonele de artari de dupa ele. Centrele sunt cele din
    # tools/gen_decor_kyoto_c.gd (DecorManual/ZoneC_Kiyomizu).
    for lbl, cx_, cz_, rad in (("luminis C sala N", 384.0, -160.0, 13.0),
                               ("luminis C sala S", 384.0, -144.0, 13.0),
                               ("luminis C2 Koyasu", 350.0, -42.0, 11.0),
                               # culoarul de vedere buza scenei -> Koyasu (r2)
                               ("luminis C2 culoar 1", 361.0, -95.0, 7.0),
                               ("luminis C2 culoar 2", 358.0, -81.0, 7.0),
                               ("luminis C2 culoar 3", 355.0, -67.0, 7.0),
                               ("luminis C2 culoar 4", 352.5, -54.0, 7.0),
                               ("luminis C sanjunoto", 288.0, -216.0, 9.0),
                               ("luminis C clopotnita", 312.0, -215.5, 6.0),
                               ("luminis C1 vedere scena", 305.0, -172.0, 16.0),
                               ("luminis C1 vedere colt", 330.0, -184.0, 9.0),
                               ("luminis C1 buza rapei", 322.0, -164.0, 12.0),
                               # coroanele de la colt, pe liniile C1 -> scena/sala (r2)
                               ("luminis C1 colt 1", 340.0, -177.0, 10.0),
                               ("luminis C1 colt 2", 355.0, -168.0, 7.0),
                               ("luminis C1 dreapta 1", 312.0, -182.0, 8.0),
                               ("luminis C1 dreapta 2", 324.0, -183.0, 8.0),
                               ("luminis C1 dreapta 3", 340.0, -186.0, 8.0),
                               ("luminis C1 incinta 1", 302.0, -216.0, 6.0),
                               ("luminis C1 incinta 2", 323.0, -218.0, 7.0),
                               ("luminis C1 incinta 3", 337.0, -218.0, 7.0),
                               # pe axa lui C1: discul „versant Higashiyama" punea
                               # coroane peste carosabil in cadrul de la 0.235 (r2)
                               ("luminis C1 ax 1", 302.0, -199.0, 9.0),
                               ("luminis C1 ax 2", 316.0, -200.0, 9.0),
                               ("luminis C1 ax 3", 330.0, -201.0, 9.0),
                               ("luminis C1 ax 4", 344.0, -200.0, 9.0),
                               ("luminis C1 colt 3", 352.0, -186.0, 7.0)):
        fz(lbl, 1, (), (), center=(cx_, 0.0, cz_), radius=rad, claim=True)
    # === sfarsit POI C ===
    # Petele de ginkgo: 4, pe EXTERIORUL buclei (stanga la D/F, dreapta la C/H
    # dupa cum curge soseaua), ca sa se vada in fata-lateral din camera de joc.
    for lbl, f, lat, rad in (("pata ginkgo C", 0.222, -40.0, 24.0),
                             ("pata ginkgo D", 0.372, -44.0, 26.0),
                             ("pata ginkgo F", 0.600, -34.0, 20.0),
                             ("pata ginkgo H", 0.905, 40.0, 22.0)):
        cx_, cz_ = _patch_center(f, lat)
        fz(lbl, 1, ("ginkgo",), (1.0,), center=(cx_, 0.0, cz_), radius=rad,
           spacing=5.2, edge_clear_m=12.0, claim=True, scale_min=0.9, scale_max=1.25,
           max_below_road_m=3.0, seed=11 + int(f * 1000))
    # C / C2: versantul Higashiyama si rapa de sub scena (artari rosii densi).
    fz("rapa C artari", 0, MAPLES, (0.36, 0.34, 0.30), frac_from=F["C1 inainte de colt"],
       frac_to=F["D aterizare coborare"], lat_min=9.0, lat_max=72.0, spacing=5.0, edge_clear_m=10.5, seed=21)
    fz("versant Higashiyama", 1, MAPLES, (0.34, 0.33, 0.33), center=(372.0, 0.0, -150.0),
       radius=88.0, spacing=7.0, seed=22)
    # D: valea de artari (cea mai deasa), pana la gura podului si sub el.
    # POI D (runda 2, dupa reparatia MeshForest 97be100b: edge_clear_m e viu).
    # Tunelul des din diorama: trunchiurile la >= margine + 5,5 (printre
    # piesele primului rand manual, margine + 5..6,8), coroanele (semilatime
    # 5-7 m) ajung pana la ~margine + 0..1,5, dar nu pe banda. lat_min 9 lasa
    # regula de margine sa decida (pe exteriorul curbelor drumul se departeaza
    # de ax). Pas 3,8 (era 4,6): cu separarea minima vie (0,35 x pas) valea
    # iesea livada. Cedrii inchisi (10%): coniferele verzi din diorama.
    fz("valea D artari", 0, MAPLES + ("cedar_dark",), (0.33, 0.27, 0.30, 0.10), frac_from=F["D aterizare coborare"],
       frac_to=F["D pod Tsutenkyo iesire"] + 0.004, lat_min=9.0, lat_max=78.0, spacing=3.8, edge_clear_m=5.5, seed=31)
    # Rapa de sub Tsutenkyo: coroanele urca pana la nivelul podului (brief §2 D).
    # Fundul e la -8..-11 sub punte pe portiunea adanca; artarii de 8,6 m (scala
    # <= 1,05) ajung la +-1,5 m de cota puntii, iar trunchiul la >= 10,4 m de
    # ax tine coroana (semilatime <= 6,1) in afara tablierului (hw 4,5).
    fz("rapa Tsutenkyo artari", 0, MAPLES, (0.40, 0.28, 0.32), frac_from=F["D pod Tsutenkyo intrare"] + 0.002,
       frac_to=F["D pod Tsutenkyo iesire"] - 0.002, lat_min=12.5, lat_max=18.0, spacing=4.2, edge_clear_m=5.0,
       scale_min=0.85, scale_max=1.05, seed=32)
    # === POI E: poienile Inari (gen_decor_kyoto_e.gd, „; poiana" la iesire) ===
    # Cedrii fasiei (edge_clear 9, coroana pana la ~5 m) acopereau altarasele,
    # sirurile de torii votive si vulpile din DecorManual (captura r1). Fiecare
    # grup primeste o poiana DISC cu `claim`, emisa INAINTEA zonelor de cedru:
    # in ea cresc cativa cedri (70%) si artari rosii ca accent, dincolo de piese
    # (edge_clear 14).
    for k_, (px_, pz_, pr_) in enumerate((
            (401.6, 356.8, 12.0), (379.9, 336.1, 12.0), (393.3, 260.5, 9.0),
            (428.2, 291.4, 10.0), (394.2, 311.2, 10.5), (419.3, 332.9, 10.0),
            (364.8, 348.0, 10.0), (370.8, 379.8, 10.0), (351.0, 385.4, 10.0),
            (326.3, 387.1, 10.0), (389.7, 367.8, 10.0), (350.6, 354.1, 10.0),
            (360.6, 382.4, 10.0))):
        # Poiana furcii (a treia) ramane GOALA: artarii din pana dintre bucla si
        # banda ascundeau poarta mare si vulpile (captura r1b 0,478).
        gol_ = (k_ == 2)
        fz("Inari poiana %d" % k_, 1, ("cedar_dark",) + MAPLES, (0.7, 0.1, 0.1, 0.1),
           center=(px_, 0.0, pz_), radius=pr_, spacing=40.0 if gol_ else 9.0,
           edge_clear_m=60.0 if gol_ else 14.0, claim=True, scale_min=0.8,
           scale_max=1.0, seed=440 + k_)
    # === /POI E ===
    # E: muntele Inari, cedru inchis, cu cate un artar rosu printre ei.
    fz("Inari cedru fasie", 0, ("cedar_dark", "momiji_b"), (0.88, 0.12),
       frac_from=F["E arc intrare (E' se desprinde)"] - 0.008,
       frac_to=F["E arc iesire (E' revine)"] + 0.006, lat_min=12.0, lat_max=72.0,
       spacing=3.7, scale_min=0.95, scale_max=1.45, seed=41)
    fz("Inari cedru disc", 1, ("cedar_dark", "momiji_b"), (0.88, 0.12), center=(332.72, 0.0, 292.0),
       radius=70.0, spacing=4.0, scale_min=0.95, scale_max=1.45, seed=42)
    # F: gradina, niwaki cu cativa artari; nimic in iaz (sol sub cota soselei).
    # POI F: pe DREAPTA (spre iaz) fasia se opreste la 0,595, de unde incepe
    # vederea spre pavilion peste apa; malul drept il imbraca DecorManual (ZoneF).
    fz("gradina F", 0, ("niwaki_pine", "momiji_a", "momiji_c"), (0.72, 0.14, 0.14),
       frac_from=F["F intrare (spre V)"] - 0.012, frac_to=F["G S1 intrare"] + 0.004,
       lat_min=11.0, lat_max=56.0, spacing=7.0, max_below_road_m=1.6, seed=51, side=-1)
    fz("gradina F dreapta", 0, ("niwaki_pine", "momiji_a", "momiji_c"), (0.72, 0.14, 0.14),
       frac_from=F["F intrare (spre V)"] - 0.012, frac_to=0.595,
       lat_min=11.0, lat_max=56.0, spacing=7.0, max_below_road_m=1.6, seed=53, side=1)
    fz("gradina F dreapta 2", 0, ("niwaki_pine", "momiji_a", "momiji_c"), (0.72, 0.14, 0.14),
       frac_from=0.656, frac_to=F["G S1 intrare"] + 0.004,
       lat_min=11.0, lat_max=56.0, spacing=7.0, max_below_road_m=1.6, seed=54, side=1)
    # POI F: dealul gradinii (+24, in spatele pavilionului, vazut din drum pe
    # cadrul-erou): artari in trei rosuri, niwaki si cativa ginkgo, ca aurul
    # pavilionului sa stea pe rosu si verde, nu pe un con de iarba.
    fz("deal gradina F", 1, MAPLES + ("niwaki_pine", "ginkgo"), (0.26, 0.24, 0.24, 0.16, 0.10),
       center=(hill_f_g[0], 0.0, hill_f_g[2]), radius=46.0, spacing=6.0,
       edge_clear_m=10.5, scale_min=0.95, scale_max=1.3, seed=52)
    # G2 (POI G, tools/gen_decor_kyoto_g.gd): culoarul VIADUCTULUI trenuletului.
    # Podul de fier (ModulePlacer, PodulTrenului) e prelungit de DecorManual cu
    # cate o travee pe fiecare parte (axa X a podului, +-21,16 m), ca trenul de
    # 25,5 m sa nu atarne peste culee. Discurile REVENDICA banda liniei (raza
    # 4,5 = puntea + culeea) inaintea zonelor de bambus, ca tulpinile sa nu
    # strapunga traveele; edge_clear 60 = nu pun nimic, doar revendica.
    # Origine si axa MASURATE (gen_decor_kyoto_g.gd --scan verifica abaterea):
    # (-65.70, 411.02), X = (0.9956, -0.0933).
    for _k, _xa in enumerate((-32.0, -25.0, -18.0, -11.5, 11.5, 18.0, 25.0, 32.0)):
        fz(f"G2 culoar viaduct {_k}", 1, ("bamboo_crown",), (1.0,),
           center=(round(-65.70 + 0.9956 * _xa, 2), 0.0, round(411.02 - 0.0933 * _xa, 2)),
           radius=4.5, spacing=3.0, edge_clear_m=60.0, claim=True, seed=70 + _k)
    # G: padurea de bambus (mii de tulpini moso) cu tufe de bambus la margine.
    fz("bambus G tulpini", 0, ("moso_culm",), (1.0,), frac_from=F["G S1 intrare"] - 0.012,
       frac_to=F["G2 sub podul trenului"] + 0.006, lat_min=6.5, lat_max=44.0, spacing=2.0,
       edge_clear_m=3.0, scale_min=0.9, scale_max=1.15, max_below_road_m=6.0, seed=61, view_m=140.0)
    fz("bambus G margine", 0, ("bamboo_crown", "moso_culm"), (0.8, 0.2),
       frac_from=F["G S1 intrare"] - 0.012, frac_to=F["G2 sub podul trenului"] + 0.006,
       lat_min=40.0, lat_max=62.0, spacing=5.0, edge_clear_m=3.0, scale_min=0.9,
       scale_max=1.3, max_below_road_m=6.0, seed=62)
    # H (POI H, kyoto/poi-h): EXTERIORUL dreptei finale (stanga, vest) era camp
    # gol pana la orizont; diorama are acolo malul raului si dealuri impadurite
    # (artari rosii, conifere inchise). O singura FASIE pe stanga, dincolo de
    # primul rand manual (gen_decor_kyoto_h.gd, 20-45 m de ax), de la 30 m de
    # ax (randul doi de case al lui A sta la 21-27 m), departe de linia de vedere
    # spre pagoda (<= 5 m de ax pe ultima treime). `max_below_road_m` 3 tine
    # copacii afara din bazinul raului (apa la -3, drumul la +3).
    # Runda 2 (desene): r1 avea 4 discuri x 5 specii x felii de 90 m x umbra
    # = +88 felii (~+176 desene). Acum o zona, 3 specii, fara umbra (copacii
    # sunt la >= 30 m de ax; primul rand manual o arunca).
    fz("H vest fasie", 0, ("momiji_a", "momiji_b", "cedar_dark"), (0.36, 0.34, 0.30),
       frac_from=F["H pod Togetsukyo intrare"] - 0.004, frac_to=0.985, side=-1,
       lat_min=30.0, lat_max=110.0, spacing=6.0, edge_clear_m=14.0, shadow_m=0.0,
       max_below_road_m=3.0, seed=81)
    # (runda 2: discul "H deal gradina vest" scos - dealul il acopera acum
    # "deal gradina F", al lui F, cu r 46 pe tot dealul.)

    FOREST_GLBS = (("momiji_a", "plants"), ("momiji_b", "plants"), ("momiji_c", "plants"),
                   ("ginkgo", "plants"), ("niwaki_pine", "plants"), ("moso_culm", "plants"),
                   ("bamboo_crown", "plants"), ("cedar_dark", "trees"))
    forest_ext = ('[ext_resource type="Script" path="res://scenes/props/mesh_forest.gd" id="mf_script"]\n'
                  '[ext_resource type="Script" path="res://scenes/props/mesh_forest_zone.gd" id="mf_zone"]\n')
    for stem, folder in FOREST_GLBS:
        forest_ext += (f'[ext_resource type="PackedScene" path="res://assets/models/kyoto/'
                       f'{folder}/{stem}.glb" id="mf_{stem}"]\n')
    forest_sub = ""
    for k, d in enumerate(forest_zones):
        sp_txt = ", ".join('"%s"' % x for x in d['species'])
        fw_txt = ", ".join(str(x) for x in d["weights"])
        claim_txt = "true" if d.get('claim') else "false"
        forest_sub += f"""
[sub_resource type="Resource" id="MFZ_{k}"]
script = ExtResource("mf_zone")
label = "{d['label']}"
kind = {d['kind']}
species = PackedStringArray({sp_txt})
weights = PackedFloat32Array({fw_txt})
spacing = {d.get('spacing', 4.0)}
edge_clear_m = {d.get('edge_clear_m', 9.0)}
shadow_m = {d.get('shadow_m', 25.0)}
view_m = {d.get('view_m', 330.0)}
max_below_road_m = {d.get('max_below_road_m', 200.0)}
claim = {claim_txt}
scale_min = {d.get('scale_min', 0.85)}
scale_max = {d.get('scale_max', 1.2)}
seed_value = {d.get('seed', 1)}
"""
        if d['kind'] == 0:
            forest_sub += (f"frac_from = {r3(d['frac_from'])}\nfrac_to = {r3(d['frac_to'])}\n"
                           f"lat_min = {d['lat_min']}\nlat_max = {d['lat_max']}\n")
            if 'side' in d:
                forest_sub += f"side = {d['side']}\n"
        else:
            c_ = d['center']
            forest_sub += (f"center = Vector3({c_[0]:.2f}, {c_[1]:.2f}, {c_[2]:.2f})\n"
                           f"radius = {d['radius']}\n")
    scenes_txt = ", ".join(f'ExtResource("mf_{s}")' for s, _ in FOREST_GLBS)
    zones_txt = ", ".join(f'SubResource("MFZ_{k}")' for k in range(len(forest_zones)))
    forest_node = f"""
[node name="PadureMasa" type="Node3D" parent="."]
script = ExtResource("mf_script")
scenes = Array[PackedScene]([{scenes_txt}])
zones = Array[ExtResource("mf_zone")]([{zones_txt}])
"""
    # --- sfarsit GRUPA PADUREA IN MASA ---------------------------------------

    # === DECOR MANUAL (POI-uri) ==============================================
    # Generatorul asta rescrie TOT Track18.tscn, deci decorul manual al POI-urilor
    # (noduri sub `DecorManual`, memoria decor-manual-sursa-de-adevar) nu poate
    # sta doar in .tscn: ar disparea la prima regenerare. Fiecare POI isi emite
    # blocul cu generatorul lui (`tools/gen_decor_kyoto_<x>.gd --out=...`) in
    # `tools/kyoto_decor/poi_<x>.part`, cu doua sectiuni: `;;EXT` (ext_resource-uri,
    # id-uri cu prefixul POI-ului) si `;;NODES` (zona + piesele). Aici se lipesc
    # toate, in ordinea numelui; un POI nou = un fisier nou, fara cod aici.
    import glob as _glob
    import os as _os
    decor_ext = ""
    decor_nodes = ""
    _parts = sorted(_glob.glob(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)),
                                             "kyoto_decor", "poi_*.part")))
    for _pp in _parts:
        _sec = None
        for _ln in open(_pp, encoding="utf-8").read().splitlines():
            if _ln.strip() == ";;EXT":
                _sec = "ext"
                continue
            if _ln.strip() == ";;NODES":
                _sec = "nodes"
                continue
            if _sec == "ext" and _ln.strip():
                decor_ext += _ln + "\n"
            elif _sec == "nodes":
                decor_nodes += _ln + "\n"
    if _parts:
        decor_ext = ('[ext_resource type="Script" uid="uid://twspgftscxb4" '
                     'path="res://scenes/props/world_prop.gd" id="dm_prop"]\n') + decor_ext
        decor_nodes = ('\n[node name="DecorManual" type="Node3D" parent="."]\n'
                       'script = ExtResource("dm_prop")\n\n') + decor_nodes
    print(f"decor manual: {len(_parts)} blocuri POI")
    # === /DECOR MANUAL ===

    # CameraZone-uri: Tsutenkyo (3,2 / 5,5 / 4) pe fractie, tunel (2,4 / 5,2) in cutie.
    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://da4os4mcgj643" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="4_branch"]
[ext_resource type="Script" path="res://scenes/tracks/track_channel.gd" id="8_channel"]
[ext_resource type="Script" path="res://scenes/hazards/camera_zone.gd" id="9_camzone"]
[ext_resource type="Script" path="res://scenes/hazards/gion_matsuri_hazard.gd" id="11_gion"]
[ext_resource type="Script" path="res://scenes/props/torii_tunnel.gd" id="12_torii"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/torii_senbon.glb" id="13_senbon"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/torii_large.glb" id="14_large"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/trees/cedar_dark.glb" id="15_cedar"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/vehicles/gion_boko.glb" id="12_gion_glb"]
[ext_resource type="Script" path="res://scenes/hazards/dust_devil_hazard.gd" id="16_devil"]
[ext_resource type="Script" path="res://scenes/hazards/shishimai_hazard.gd" id="18_shishimai"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/props/shishimai.glb" id="19_shishimai_glb"]
[ext_resource type="Script" path="res://scenes/props/leaf_carpet.gd" id="16_carpet"]
[ext_resource type="Script" path="res://scenes/props/leaf_fall.gd" id="17_leaffall"]
[ext_resource type="Script" path="res://scenes/props/module_placer.gd" id="intc_placer"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/tsutenkyo_roof_module.glb" id="intc_tsu"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/togetsukyo_module.glb" id="intc_toget"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/kakezukuri_scaffold.glb" id="intc_scaffold"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/iron_truss_bridge.glb" id="intc_truss"]
{forest_ext}{decor_ext}"""
    for k, (_, _, sz) in enumerate(zones):
        tscn += f"""
[sub_resource type="BoxShape3D" id="BoxShape3D_zone{k}"]
size = Vector3({sz[0]:.2f}, {sz[1]:.2f}, {sz[2]:.2f})
"""
    tscn += forest_sub   # GRUPA PADUREA IN MASA
    tscn += f"""
[sub_resource type="Curve3D" id="Curve3D_kyoto"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_tunel"]
closed = false
_data = {{
"points": {pva(tunnel_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in tunnel_pts)})
}}
point_count = {len(tunnel_pts)}

[node name="Track18" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Kyoto"
custom_theme = "kyoto"
custom_half_width = 6.0
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_sun_rotation_deg = Vector3(-22, -45, 0)
custom_sea_level_offset = {sea_offset}
custom_ravines = Array[Vector4]([{rav_txt}])
custom_viaduct_ravines = Array[int]([{", ".join(str(i) for i in VIADUCTS)}])
custom_viaduct_net_margin = 10.0
custom_viaduct_net_backoffs = Array[Vector2]([Vector2(0, 70.0)])
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_ravine_widths = Array[Vector2]([{rw_txt}])
custom_ravine_water = Array[Vector3]([{wt_txt}])
custom_ravine_capes = Array[Vector4]([{cp_txt}])
custom_width_segments = Array[Vector3]([{w_txt}])
traffic_count = 0
terrain_pad_m = 260.0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_kyoto")

[node name="Peaks" type="Node3D" parent="."]

[node name="Inari" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {inari_g[0]:.2f}, {inari_g[1]:.2f}, {inari_g[2]:.2f})
gizmo_extents = 70.0
script = ExtResource("2_peak")
radius_m = 70.0

[node name="Higashiyama" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {higashi_g[0]:.2f}, {higashi_g[1]:.2f}, {higashi_g[2]:.2f})
gizmo_extents = 90.0
script = ExtResource("2_peak")
radius_m = 90.0

[node name="DealGradina" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hill_f_g[0]:.2f}, {hill_f_g[1]:.2f}, {hill_f_g[2]:.2f})
gizmo_extents = 60.0
script = ExtResource("2_peak")
radius_m = 60.0

[node name="TunelTorii" type="Path3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
curve = SubResource("Curve3D_tunel")
script = ExtResource("4_branch")
branch_half_width = 3.2
label = "Tunelul de torii"
entry_at = {e_in:.5f}
exit_at = {e_out:.5f}

[node name="ToriiTunel" type="Node3D" parent="."]
script = ExtResource("12_torii")
branch_index = 1
gate_scene = ExtResource("13_senbon")
large_gate_scene = ExtResource("14_large")
cedar_scene = ExtResource("15_cedar")
foxes_enabled = false
mouth_clearing = true

[node name="CovorFrunze" type="Node3D" parent="."]
script = ExtResource("16_carpet")
zones = Array[Vector3]([{carpet_zones}])

[node name="FrunzeCazatoare" type="GPUParticles3D" parent="."]
script = ExtResource("17_leaffall")
{forest_node}
[node name="Hazarduri" type="Node3D" parent="."]

[node name="SaritaScena" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {gap_g[0]:.2f}, {gap_g[1]:.2f}, {gap_g[2]:.2f})
gizmo_extents = 40.0
script = ExtResource("8_channel")
gap = {SCENE_GAP_M}
water_half = 8.0
bank = 10.0
depth = 13.0
water_y_drop = -1.0
reach = 36.0
fade = 14.0
label = "saritura de pe scena Kiyomizu"
respawn_past_gap = true

[node name="GionMatsuri" type="Node3D" parent="Hazarduri"]
transform = {tub_xf}
script = ExtResource("11_gion")
side = 1
road_half_width = 5.5
model = ExtResource("12_gion_glb")

[node name="Kogarashi" type="Node3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {kog_g[0]:.3f}, {kog_g[1]:.3f}, {kog_g[2]:.3f})
script = ExtResource("16_devil")
amplitude = Vector2({kog_half:.2f}, 0)
frequency = Vector2(0.04, 0.0213)
path_yaw_deg = {kog_yaw:.1f}
spin_deg = 72.0
blind_time = 0.35
lift_m = 1.5
radius = 1.8
height = 9.0
leaf_mode = true
dust_amount = 30
debris_amount = 14
cone_alpha = 0.3
cone_color = Color(0.66, 0.41, 0.23, 1)

[node name="Shishimai" type="Node3D" parent="Hazarduri"]
transform = {shi_xf}
script = ExtResource("18_shishimai")
road_half_width = 7.0
model = ExtResource("19_shishimai_glb")
"""
    tscn += f"""
[node name="CameraTsutenkyo" type="Area3D" parent="Hazarduri"]
monitorable = false
script = ExtResource("9_camzone")
size = Vector3(2, 2, 2)
frac_from = {r3(f_bridge_a - 0.004)}
frac_to = {r3(f_bridge_b + 0.004)}
height = 3.2
look_height = 0.6
fov_bonus = 4.0
ceiling = 5.5

[node name="CameraTunelTorii" type="Area3D" parent="Hazarduri"]
transform = {tun_basis}{tun_g[0]:.2f}, {tun_g[1]:.2f}, {tun_g[2]:.2f})
monitorable = false
script = ExtResource("9_camzone")
size = Vector3(8, 7, {max(chord - 14.0, 20.0):.1f})
height = 2.4
look_height = 0.6
fov_bonus = 3.0
ceiling = 5.2
"""
    # === GRUPA INT-C: PODURILE SI SCENA (ModulePlacer) ===
    # Modulele GLB repetate pe curba de scenes/props/module_placer.gd (origine in
    # centrul modulului pe axa, puntea la y = 0, -Z inainte).
    #  * Tsutenkyo: 6 m, pe intervalul de latime ingusta (frac D pod intrare..iesire).
    #    `Tsu_Rail` ascuns: dubleaza parapetul procedural (deck_rails), care RAMANE.
    #  * Togetsukyo: 10 m, pe H (frac 0,832-0,894).
    #  * Esafodajul scenei: 6 m pas, doua randuri (+-3 m) sub puntea de 12 m, cu
    #    baza la 16 m sub drum (podeaua rapei C2 = +16, puntea = +32), coliziune mesh.
    #  * Podul trenului (G2): o singura piesa pe drum, travee peste drum (gol 15,15).
    tscn += f"""
[node name="Poduri" type="Node3D" parent="."]

[node name="Tsutenkyo" type="Node3D" parent="Poduri"]
script = ExtResource("intc_placer")
model = ExtResource("intc_tsu")
frac_from = {r3(f_bridge_a)}
frac_to = {r3(f_bridge_b)}
module_length = 6.0
seam_half_width = 6.9
hide_nodes = PackedStringArray("Tsu_Rail")

[node name="Togetsukyo" type="Node3D" parent="Poduri"]
script = ExtResource("intc_placer")
model = ExtResource("intc_toget")
frac_from = {r3(f_togetsu_a)}
frac_to = {r3(f_togetsu_b)}
module_length = 10.0
seam_half_width = 7.6

[node name="EsafodajScena" type="Node3D" parent="Poduri"]
script = ExtResource("intc_placer")
model = ExtResource("intc_scaffold")
frac_from = {r3(f_scene_a)}
frac_to = {r3(f_scene_b)}
module_length = 6.0
lateral_offsets = PackedFloat32Array(-3, 3)
ground_fit = true
module_height = 15.92
collision_mode = "mesh"
seam_half_width = 3.4

[node name="PodulTrenului" type="Node3D" parent="Poduri"]
script = ExtResource("intc_placer")
model = ExtResource("intc_truss")
frac_from = {r3(F["G2 sub podul trenului"])}
frac_to = 0.0
module_length = 5.8
collision_mode = "mesh"
"""
    # === /GRUPA INT-C ===
    for k, (nm, g, sz) in enumerate(zones):
        tscn += f"""
[node name="{nm}" type="Area3D" parent="Hazarduri"]
monitorable = false
script = ExtResource("10_respawn")

[node name="Cutie" type="CollisionShape3D" parent="Hazarduri/{nm}"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})
shape = SubResource("BoxShape3D_zone{k}")
"""
    tscn += decor_nodes   # DECOR MANUAL (POI-uri)
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
