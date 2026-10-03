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
KINKAKU_XY = (150.0, -300.0)      # pavilionul, pe malul de nord al iazului
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

# 4. Pavilionul in dreapta pe F, 20-45 deg la 70-110 m.
f_idx = frac_range_indices(frac["F intrare (spre V)"], frac["F curba stanga sfarsit"])
sel = [i for i in f_idx if 70.0 <= dist_to(i, KINKAKU_XY) <= 110.0]
ok = sum(1 for i in sel if 20.0 <= azimut_to(i, KINKAKU_XY) <= 45.0)
report(len(sel) > 0 and ok / len(sel) >= 0.6,
       f"F pavilionul in dreapta (20-45 deg) la 70-110 m: {ok}/{len(sel)} puncte "
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
report(dh < -10.0, f"F turnul daruma pe exteriorul unei curbe la STANGA: schimbare de directie {dh:+.0f} deg pe 72 m (negativ = stanga)")
sel = [i for i in range(tub_i - 14, tub_i) if 35.0 <= math.hypot(rs[i][0] - rs[tub_i][0], rs[i][1] - rs[tub_i][1]) <= 150.0]
ok = sum(1 for i in sel if abs(azimut_to(i, TUB_XY)) <= 30.0)
report(len(sel) > 0 and ok / len(sel) >= 0.8,
       f"F turnul daruma intreg in cadru pe [150,35] m: {ok}/{len(sel)} puncte cu |azimut| <= 30 ({100*ok/max(1,len(sel)):.0f}%, prag 80%)")

all_ok = all(guard_results)
print(f"\nGARDA DE AZIMUT: {'TOATE TREC' if all_ok else 'CEL PUTIN O LINIE A PICAT'}")


def godot(p, e):
    return (p[0], e, -p[1])

def r3(x):
    return round(x, 3)

def road_at_frac(f):
    return rs[int(f * n_rs) % n_rs]

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
    # la Inari (frunzele mai rare: altare, cedri). (de la, pana la, densitate.)
    carpet_zones = ", ".join(
        f"Vector3({r3(a)}, {r3(b)}, {d})" for a, b, d in (
            (F["D aterizare coborare"] + 0.004, f_bridge_a - 0.009, 1.0),
            (f_bridge_b + 0.006, 0.56, 0.6)))
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
    VIADUCTS = [0, 1, 2]
    rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d, _ in ravines)
    fl_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_FLOOR)
    rw_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_WIDTH)
    wt_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in RAVINE_WATER)

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

    # CameraZone-uri: Tsutenkyo (3,2 / 5,5 / 4) pe fractie, tunel (2,4 / 5,2) in cutie.
    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://da4os4mcgj643" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="4_branch"]
[ext_resource type="Script" path="res://scenes/tracks/track_channel.gd" id="8_channel"]
[ext_resource type="Script" path="res://scenes/hazards/camera_zone.gd" id="9_camzone"]
[ext_resource type="Script" path="res://scenes/hazards/daruma_otoshi_hazard.gd" id="11_daruma"]
[ext_resource type="Script" path="res://scenes/props/torii_tunnel.gd" id="12_torii"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/torii_senbon.glb" id="13_senbon"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/structures/torii_large.glb" id="14_large"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/trees/cedar_dark.glb" id="15_cedar"]
[ext_resource type="PackedScene" path="res://assets/models/kyoto/props/daruma_otoshi.glb" id="12_daruma_glb"]
[ext_resource type="Script" path="res://scenes/props/leaf_carpet.gd" id="16_carpet"]
[ext_resource type="Script" path="res://scenes/props/leaf_fall.gd" id="17_leaffall"]
"""
    for k, (_, _, sz) in enumerate(zones):
        tscn += f"""
[sub_resource type="BoxShape3D" id="BoxShape3D_zone{k}"]
size = Vector3({sz[0]:.2f}, {sz[1]:.2f}, {sz[2]:.2f})
"""
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

[node name="CovorFrunze" type="Node3D" parent="."]
script = ExtResource("16_carpet")
zones = Array[Vector3]([{carpet_zones}])

[node name="FrunzeCazatoare" type="GPUParticles3D" parent="."]
script = ExtResource("17_leaffall")

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

[node name="DarumaOtoshi" type="Node3D" parent="Hazarduri"]
transform = {tub_xf}
script = ExtResource("11_daruma")
side = 1
road_half_width = 5.5
model = ExtResource("12_daruma_glb")
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
    for k, (nm, g, sz) in enumerate(zones):
        tscn += f"""
[node name="{nm}" type="Area3D" parent="Hazarduri"]
monitorable = false
script = ExtResource("10_respawn")

[node name="Cutie" type="CollisionShape3D" parent="Hazarduri/{nm}"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})
shape = SubResource("BoxShape3D_zone{k}")
"""
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
