# Genereaza traseul Transfagarasan (Track21) din waypoints cu fillet-uri de arc --
# schela copiata din gen_okinawa_route.py (pas uniform 12 m, statistici ca
# ProbeLayout), cu GARDA DE AZIMUT din docs/track_briefs/transfagarasan.md §2.0/§2.1,
# verificata pe punctele coapte INAINTE sa existe .tscn-ul (orientarea buclei se
# hotaraste din repere, nu invers). Garzile IES CU COD != 0 daca pica.
#
#   python tools/gen_transfagarasan_route.py [scenes/tracks/Track21.tscn]
#   python tools/gen_transfagarasan_route.py --sabotaj   # muta stiva de serpentine 250 m
#                                                        # spre vest: garzile TREBUIE sa
#                                                        # pice (cod 1)
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z,
# est = +X): harta ajunge in lume FARA oglindire, deci "dreapta" de pe harta e
# dreapta si in cadrul camerei (conventia din gen_kyoto_route.py).
# Sens ANTIORAR pe plan (inversat fata de Okinawa): A spre E (valea Argesului),
# B spre E (barajul), C spre N (malul lacului), D spre N (valea Caprei), E spre N
# (tunelul, lacul Balea), F spre V/E in zigzag (serpentinele), G spre V (padurea),
# H spre S (defileul Oltului), inapoi la A.
import math
import os
import sys

SABOTAJ = "--sabotaj" in sys.argv
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
OUT_PATH = ARGS[0] if ARGS else None

# Repere = puncte FIXE ale schitei (brief §2.1; nu derivate din traseu): garda de
# azimut nu se auto-confirma (memoria garda-circulara-propria-functie).
BARAJ = (95.0, -238.0)        # coronamentul barajului
PORTAL = (215.0, 90.0)        # portalul de sud al tunelului Capra-Balea
STIVA_REAL = (122.0, 259.0)   # centrul stivei de serpentine
CASCADA = (-30.0, 290.0)      # cascada Balea
TRECERE = (-200.0, 130.0)     # trecerea la nivel (cale ferata)
POENARI = (-125.0, -215.0)    # cetatea Poenari
STIVA = STIVA_REAL
if SABOTAJ:
    STIVA = (STIVA_REAL[0] - 250.0, STIVA_REAL[1])   # sabotaj: stiva se muta 250 m spre vest

# (x, y, raza de fillet, cota, eticheta) -- brief §2.1, EXACT cele 32 de puncte
# (nicio ajustare fata de brief).
WPTS = [
    (-115, -262, 0, 0.0, "A start"),        (-60, -266, 0, 2.0, "A sat"),
    (-5, -262, 30, 7.0, "B urcare"),        (50, -250, 0, 12.0, "B baraj V"),
    (95, -238, 0, 12.0, "B baraj"),         (140, -240, 0, 12.0, "B baraj E"),
    (195, -205, 30, 13.0, "C mal"),         (215, -130, 0, 16.0, "C tunele"),
    (195, -70, 30, 20.0, "C coada urs"),    (265, -30, 28, 25.5, "D Capra"),
    (180, 5, 25, 31.0, "D stana"),          (255, 40, 25, 37.0, "D zapada"),
    (215, 85, 0, 42.0, "D portal S"),       (205, 140, 0, 43.0, "E portal N"),
    (195, 175, 20, 43.0, "E Balea Lac"),    (165, 195, 0, 42.0, "F sus"),
    (80, 195, 16, 37.0, "F ac1a"),          (80, 227, 16, 37.0, "F ac1b"),
    (165, 227, 16, 31.0, "F ac2a"),         (165, 259, 16, 31.0, "F ac2b"),
    (80, 259, 16, 25.0, "F ac3a"),          (80, 291, 16, 25.0, "F ac3b"),
    (165, 291, 16, 19.0, "F ac4a"),         (165, 323, 16, 19.0, "F ac4b"),
    (40, 328, 0, 14.0, "F jos"),            (-40, 335, 30, 12.0, "G cascada"),
    (-120, 318, 40, 9.0, "H Olt N"),        (-185, 250, 40, 7.0, "H defileu"),
    (-200, 130, 0, 5.0, "H cale ferata"),   (-205, 0, 0, 3.0, "H Olt"),
    (-195, -140, 40, 1.5, "H Olt S"),       (-160, -238, 40, 0.5, "H spre Arges"),
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
        x, y = a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
        out.append((x, y, elevs[j] + (elevs[(j + 1) % len(pts)] - elevs[j]) * f))
        target += step
    return out


pts = fillet_loop(WPTS)
elevs, cum, total = assign_elev(pts, WPTS)
STEP = 12.0
rs = resample(pts, elevs, STEP)
n = len(rs)
tot = STEP * n          # lungimea poligonului de control (ca in kyoto)
print(f"puncte de control: {n} (pas {STEP} m)   lungime: {tot:.0f} m  (tinta 2000-2200)")


# fractia unui waypoint = indexul esantionului copt cel mai apropiat / n
def nearest(xy):
    best, bd = 0, 1e18
    for i, p in enumerate(rs):
        d = math.hypot(p[0] - xy[0], p[1] - xy[1])
        if d < bd:
            best, bd = i, d
    return best

frac = {}
for w in WPTS:
    frac[w[4]] = nearest((w[0], w[1])) / n

guard_results = []

def report(ok, text):
    guard_results.append(ok)
    print(f"  [{'OK' if ok else 'PROBLEMA'}] {text}")

# --- statistici si garzi de forma ---------------------------------------------
area = 0.0
for i in range(n):
    x0, y0 = rs[i][0], rs[i][1]
    x1, y1 = rs[(i + 1) % n][0], rs[(i + 1) % n][1]
    area += x0 * y1 - x1 * y0
cx = sum(p[0] for p in rs) / n
cy = sum(p[1] for p in rs) / n
cheb = max(max(abs(p[0] - cx), abs(p[1] - cy)) for p in rs)
min_r, min_r_at, max_s, max_s_at = 1e9, 0.0, 0.0, 0.0
for i in range(n):
    a, b, c = rs[i - 1], rs[i], rs[(i + 1) % n]
    r = circumradius(a, b, c)
    if r < min_r:
        min_r, min_r_at = r, i / n
    d = math.hypot(c[0] - b[0], c[1] - b[1])
    s = abs(c[2] - b[2]) / max(1e-6, d)
    if s > max_s:
        max_s, max_s_at = s, i / n
min_sep, min_sep_at = 1e18, (0, 0)
for i in range(n):
    for j in range(i + 12, n):
        if n - (j - i) <= 12:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        if d < min_sep:
            min_sep, min_sep_at = d, (i / n, j / n)

print("\n=== GARZI DE FORMA ===")
report(2000.0 <= tot <= 2200.0, f"lungime {tot:.0f} m (2000-2200)")
report(area > 0, f"sens {'ANTIORAR' if area > 0 else 'ORAR'} pe harta (cerut ANTIORAR)")
report(min_r >= 9.0, f"raza minima {min_r:.1f} m la frac {min_r_at:.3f} (>= 9, tinta >= 14 = pragul AI: {'atinsa' if min_r >= 14.0 else 'NEATINSA'})")
report(max_s < 0.13, f"panta maxima {100*max_s:.1f}% la frac {max_s_at:.3f} (< 13%)")
report(min_sep >= 20.0, f"separare minima {min_sep:.1f} m intre {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f} (>= 20)")
report(cheb < 400.0, f"Cebisev fata de centroid ({cx:.0f},{cy:.0f}): {cheb:.0f} m (< 400; zidul lumii 420)")

# --- garda de azimut -------------------------------------------------------------
def heading_deg(dx, dy):
    return math.degrees(math.atan2(dx, dy))  # 0 = N (+y), 90 = E (+x)

def heading_at(i):
    a, b = rs[i % n], rs[(i + 1) % n]
    return heading_deg(b[0] - a[0], b[1] - a[1])

def azimut_to(i, t):
    """azimutul tintei fata de directia de mers: 0 = in fata, + = dreapta."""
    p = rs[i % n]
    to = heading_deg(t[0] - p[0], t[1] - p[1])
    return (to - heading_at(i) + 180.0) % 360.0 - 180.0

def dist_to(i, t):
    return math.hypot(rs[i % n][0] - t[0], rs[i % n][1] - t[1])

def window(f0, f1):
    return list(range(int(f0 * n), int(f1 * n) + 1))

def in_frame(f0, f1, target, limit):
    idx = window(f0, f1)
    ok = [i for i in idx if abs(azimut_to(i, target)) <= limit]
    return len(ok), len(idx)

print("\n=== GARDA DE AZIMUT (brief par. 2.0/2.1, repere FIXE, in cadru = |azimut| <= 50 deg) ===")
for label, (f0, f1), target, limit, thr in (
        ("barajul din A (0.00-0.08)", (0.00, 0.08), BARAJ, 50.0, 0.80),
        ("portalul din D (0.25-0.31)", (0.25, 0.31), PORTAL, 50.0, 0.70),
        ("STIVA de serpentine din E (0.33-0.37)", (0.33, 0.37), STIVA, 50.0, 0.80),
        ("cascada din F-G (0.57-0.65)", (0.57, 0.65), CASCADA, 50.0, 0.80),
        ("trecerea la nivel din H (0.70-0.76)", (0.70, 0.76), TRECERE, 50.0, 0.80),
        ("Poenari din H (0.84-0.94)", (0.84, 0.94), POENARI, 50.0, 0.80)):
    k, m = in_frame(f0, f1, target, limit)
    idx = window(f0, f1)
    dmin = min(dist_to(i, target) for i in idx)
    dmax = max(dist_to(i, target) for i in idx)
    report(k / m >= thr,
           f"{label}: in cadru (<= {limit:.0f} deg) pe {k}/{m} puncte ({100*k/m:.0f}%, prag {100*thr:.0f}%), "
           f"distanta {dmin:.0f}-{dmax:.0f} m")

# vertical (informativ, brief §2.0): stiva intreaga (cote +37 -> +19, SUB tine) sub
# marginea de sus a cadrului camerei = 10 + 0.092*d peste cota drumului
idx = window(0.33, 0.37)
vis = 0
for i in idx:
    d = dist_to(i, STIVA)
    top = 37.0 - rs[i][2]
    if top <= 10.0 + 0.092 * d:
        vis += 1
print(f"  (info) stiva INTREAGA sub marginea de sus a cadrului pe {vis}/{len(idx)} puncte din E "
      f"(ocluzia o masoara transfagarasan_frustum_table.py, nu garda asta)")

if not all(guard_results):
    print("\nGARDA: CEL PUTIN O LINIE A PICAT -- nu scriu .tscn, ies cu cod 1")
    sys.exit(1)
print("\nGARDA: TOATE TREC")
if SABOTAJ:
    sys.exit(0)

# ---------------------------------------------------------------------------------
# De aici in jos: doar scrierea .tscn-ului (brief §7 pasul 2, §3, §3.1).
if OUT_PATH is None:
    print("(fara cale de iesire: nu scriu nimic)")
    sys.exit(0)


def godot(p, e):
    return (p[0], e, -p[1])

def r3(x):
    return round(x, 3)

_cum = cum_lengths(rs)
L_TOTAL = _cum[-1]

def road_at(f):
    """Pozitie (x, y_harta, cota) + directie unitara pe harta, INTERPOLAT pe arc."""
    sd = (f % 1.0) * L_TOTAL
    j = 0
    while j < n - 1 and _cum[j + 1] < sd:
        j += 1
    a, b = rs[j], rs[(j + 1) % n]
    t = (sd - _cum[j]) / max(1e-6, _cum[j + 1] - _cum[j])
    pos = tuple(a[k] + (b[k] - a[k]) * t for k in range(3))
    l = math.hypot(b[0] - a[0], b[1] - a[1])
    return pos, ((b[0] - a[0]) / l, (b[1] - a[1]) / l)

def pva(seq):
    return "PackedVector3Array(" + ", ".join(
        f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}" for a, b, c in seq) + ")"

F = frac
main_pts = [godot(p, p[2]) for p in rs]

# Basis ca in .tscn (nouă numere pe randuri, memoria tscn-transform-e-pe-randuri):
# X local -> (cos t, sin t), Z local -> (-sin t, cos t) in planul (x, z) al lumii.
def rot_y(deg, sc=1.0):
    c, s_ = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return f"{c*sc:.5f}, 0, {-s_*sc:.5f}, 0, {sc}, 0, {s_*sc:.5f}, 0, {c*sc:.5f}"

def rot_y_s(deg, sx, sy, sz):
    c, s_ = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return f"{sx*c:.5f}, 0, {-sz*s_:.5f}, 0, {sy}, 0, {sx*s_:.5f}, 0, {sz*c:.5f}"

def yaw_z_to(zx, zz):
    """yaw (grade) care aseaza Z local pe (zx, zz) in plan."""
    return math.degrees(math.atan2(-zx, zz))

def travel_g(f):
    """Directia de mers la fractia f, in coordonate Godot (x, z)."""
    _p, d = road_at(f)
    return (d[0], -d[1])

def at_road(f, lateral=0.0):
    """Punct Godot (x, cota, z) la `lateral` m de axa (+ = dreapta in sensul de mers)."""
    pos, d = road_at(f)
    rx, ry = d[1], -d[0]
    return (pos[0] + rx * lateral, pos[2], -(pos[1] + ry * lateral))

def xf_ident(f, lateral=0.0, dy=0.0):
    g = at_road(f, lateral)
    return f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g[0]:.3f}, {g[1] + dy:.3f}, {g[2]:.3f})"

# --- fractii (brief §3: urs 0.20, semafor la gura tunelului, avalansa 0.40, oi 0.49, tren 0.80,
#     sarituri 0.67). Avalansa isi muta singura fractia (`_build_avalanche`): se citeste din scena.
F_BEAR = 0.20
F_TUNNEL = F["D portal S"] + 14.0 / L_TOTAL   # linia de oprire: 14 m dupa coltul portalului (nu pe coltul de 318->349)
TUNNEL_LEN = 60.0
F_TUNNEL_END = F_TUNNEL + TUNNEL_LEN / L_TOTAL
F_AVAL = 0.40
F_SHEEP = 0.49
F_JUMP = 0.678
F_TRAIN = 0.80

# --- latimi: coronamentul si tunelul la 6 (rampa Track.WIDTH_RAMP_M de fiecare parte) ---
fCr0, fCr1 = F["B baraj V"], F["B baraj E"]
fTu0, fTu1 = F_TUNNEL - 0.002, F_TUNNEL_END + 0.002
WS = [(r3(fCr0), r3(fCr1), 6.0), (r3(fTu0), r3(fTu1), 6.0)]
w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in WS)

# --- rape (lac Vidraru stanga, haul dreapta, cuveta Balea, Olt dreapta) ---------------------
# Latura: -1 stanga, +1 dreapta in sensul de mers (side_at = dir x UP).
RAVINES = [
    (0.080, 0.135, 30.0, -1),   # 0 lacul Vidraru la coronament (cornisa, 4,5 m sub drum)
    (0.135, 0.245, 20.0, -1),   # 1 lacul Vidraru, malul C (mal lin)
    (0.074, 0.128, 40.0, 1),    # 2 haul de sub baraj (dreapta), cornisa
    (0.347, 0.382, 5.0, 1),     # 3 cuveta lacului Balea (apa = disc, vezi mai jos)
    (0.705, 0.775, 10.0, 1),    # 4 Oltul amonte
    (0.845, 0.975, 10.0, 1),    # 5 Oltul aval (nimic intre 0.775 si 0.845: trecerea la nivel)
]
rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d in RAVINES)
RAV_FLOORS = [(0, 3.0), (1, 3.0), (2, -28.0), (3, 37.0), (4, -4.0), (5, -5.0)]
floors_txt = ", ".join(f"Vector2({i}, {y})" for i, y in RAV_FLOORS)
RAV_WIDTHS = [(0, 120.0), (1, 150.0), (2, 60.0), (3, 55.0), (4, 45.0), (5, 45.0)]
widths_txt = ", ".join(f"Vector2({i}, {w})" for i, w in RAV_WIDTHS)
# Apa: (rapa, cota ABSOLUTA, elan la repunere). Nivelurile sunt SUB sosea pe tot coridorul de
# care se poate lega cuveta (altfel umplerea ar curge pe sosea: vezi _build_ravine_water).
RAV_WATER = [(0, 7.5, 16.0), (2, -24.0, 20.0), (4, 3.4, 16.0), (5, -2.5, 16.0)]
rwater_txt = ", ".join(f"Vector3({i}, {y}, {b})" for i, y, b in RAV_WATER)

# --- lacul Balea: disc provizoriu (cuveta sapata pe ravena 3, fara umplere automata) -----------
BAL_POS = at_road(F["E Balea Lac"], 44.0)
BAL_Y = 40.3
BAL_R = 34.0

# --- varfuri (muntele din mijloc + masivul peste tunel, tiparul Track09/Track16) -------------
tun_c = at_road((F_TUNNEL + F_TUNNEL_END) * 0.5, 0.0)
PEAKS = [
    ("MasivTunel", (tun_c[0], 85.0, tun_c[2]), 160.0),
    ("CreastaVest", (-30.0, 105.0, -100.0), 200.0),
    ("CreastaCentru", (100.0, 92.0, -115.0), 140.0),
]

# --- decor provizoriu din kitul alpin --------------------------------------------------------
dec = []   # (nume, resursa, transform_str, extra_proprietati)
def add(nm, res, xform, extra=""):
    dec.append((nm, res, xform, extra))

# Portalurile: mountain_tunnel.glb (18,7 x 12,8 x 15,3; gol 8 x 5,5), X scalat 1,5 -> gol 12 m = tunelul;
# Z local pe sensul de mers; centrat la 7,6 m in AFARA gurii. Coliziune "none" (tubul are propriile ziduri).
d_in = travel_g(F_TUNNEL)
d_out = travel_g(F_TUNNEL_END)
g_in = at_road(F_TUNNEL - 7.6 / L_TOTAL)
g_out = at_road(F_TUNNEL_END + 7.6 / L_TOTAL)
add("Portal_S", "tunnel",
    f"Transform3D({rot_y_s(yaw_z_to(*d_in), 1.5, 1.25, 1.0)}, {g_in[0]:.2f}, {g_in[1]:.2f}, {g_in[2]:.2f})",
    'metadata/coliziune = "none"')
add("Portal_N", "tunnel",
    f"Transform3D({rot_y_s(yaw_z_to(*d_out), 1.5, 1.25, 1.0)}, {g_out[0]:.2f}, {g_out[1]:.2f}, {g_out[2]:.2f})",
    'metadata/coliziune = "none"')
# utilajul parcat la portalul de sud, pe acostament
gp = at_road(F_TUNNEL - 50.0 / L_TOTAL, 9.0)   # dincolo de lampa (34 m), sa nu-i stea in fundal
add("Utilaj_parcat", "snowplow",
    f"Transform3D({rot_y(yaw_z_to(*d_in), 1.0)}, {gp[0]:.2f}, {gp[1]:.2f}, {gp[2]:.2f})")
# pereti de zapada provizorii: petice ridicate pe verticala, de-o parte si de alta a ultimilor 80 m
k = 0
for j in range(8):
    ff = F_TUNNEL - (80.0 - j * 9.0) / L_TOTAL
    for lat in (-9.8, 9.8):
        g = at_road(ff, lat)
        add(f"Zapada{k:02d}", "snow",
            f"Transform3D({rot_y_s(yaw_z_to(*d_in), 1.6, 11.0, 1.1)}, {g[0]:.2f}, {g[1] - 0.2:.2f}, {g[2]:.2f})",
            'metadata/coliziune = "none"')
        k += 1
# ziduri de sprijin provizorii: blocuri de stanca pe exteriorul acelor de par (F)
k = 0
for fl in ("F ac1b", "F ac2a", "F ac2b", "F ac3a", "F ac3b", "F ac4a", "F ac4b"):
    for dj in range(-2, 3):
        ff = F[fl] + dj * 0.0065
        _p0, d0 = road_at(ff - 0.01)
        _p1, d1 = road_at(ff + 0.01)
        cross = d0[0] * d1[1] - d0[1] * d1[0]     # >0 vireaza spre stanga -> exteriorul e la dreapta
        lat = 10.5 if cross > 0 else -10.5
        g = at_road(ff, lat)
        add(f"ZidAc{k:02d}", "rock",
            f"Transform3D({rot_y(yaw_z_to(*travel_g(ff)) + 90.0, 0.7)}, {g[0]:.2f}, {g[1] - 0.3:.2f}, {g[2]:.2f})")
        k += 1

# --- semaforul de la tunel: lampa pe stalp (nu la nivelul soselei), becuri mari, emisie ------
LAMP_BULB = 1.1
LAMP_SPACING = 1.25
LAMP_GLOW = 1.4
LAMP_HEAD = 5.6
LAMP_ARM = 3.4          # consola peste banda (capul sta la 7,6 - 3,4 = 4,2 m din axa)
LAMP_BACK_M = 34.0      # stalpul sta cu atat INAINTEA gurii: portalul (15,3 m adancime, 28 m lat.) si coltul
                        # lateral 6-14 m) ar fi acoperit stalpul si capul, masurat pe captura

# --- parapete de beton cu coliziune pe serpentine (Track._build_parapets) --------------------
# Un ac de par = doua arce de 90 grade (r 16) consecutive: arcul "a" e centrat pe F[acNa], arcul
# "b" pe F[acNb], fiecare de ~25 m. Marja de 4 m in plus la capete. Ramurile (drepte) stau INTRE
# aceste ace: ramura k merge de la sfarsitul acului k-1 la inceputul acului k.
# Latura: +1 dreapta, -1 stanga in sensul de mers. Marginea din VALE a unei ramuri e cea dinspre
# ramura urmatoare: ramura 1 (spre V) o are pe dreapta, ramura 2 (spre E) pe stanga, etc.
# Acul are parapet pe AMBELE laturi: exteriorul (altfel iesi pe versant si cobori pe langa
# stiva) si interiorul (altfel taiai coltul peste fasia dintre ramuri).
# DESCHIDEREA pentru scurtatura ciobanilor (brief §3.1 decizia 4, ramura 3 -> ramura 4 peste
# acul 3): PE DREAPTA ramurii 3, pe PARAP_GAP_M metri, imediat inaintea acului 3. Taierea
# viitoare se leaga de aici: poteca coboara pe fasia dintre ramuri si intra pe ramura 4 prin
# marginea ei dreapta (de pe ramura 4, spre sud/amonte, nu are parapet). Pune
# PARAP_OPEN_AC3 = False ca sa inchizi complet.
PARAP_OPEN_AC3 = True
PARAP_GAP_M = (26.0, 6.0)      # golul: de la 26 m pana la 6 m inaintea inceputului acului 3
_m = 1.0 / L_TOTAL
def _ac_a(k):
    return F[f"F ac{k}a"] - 17.0 * _m
def _ac_b(k):
    return F[f"F ac{k}b"] + 17.0 * _m
PARAP = []   # (f0, f1, latura)
PARAP.append((F["F sus"] + 6.0 * _m, _ac_a(1), 1))        # ramura 1, vale = dreapta
PARAP.append((_ac_a(1), _ac_b(1), 0))                     # acul 1
PARAP.append((_ac_b(1), _ac_a(2), -1))                    # ramura 2, vale = stanga
PARAP.append((_ac_a(2), _ac_b(2), 0))                     # acul 2
if PARAP_OPEN_AC3:
    PARAP.append((_ac_b(2), _ac_a(3) - PARAP_GAP_M[0] * _m, 1))   # ramura 3 pana la gol
    PARAP.append((_ac_a(3) - PARAP_GAP_M[1] * _m, _ac_a(3), 1))  # ... si dupa gol
else:
    PARAP.append((_ac_b(2), _ac_a(3), 1))
PARAP.append((_ac_a(3), _ac_b(3), 0))                     # acul 3
PARAP.append((_ac_b(3), _ac_a(4), -1))                    # ramura 4, vale = stanga
PARAP.append((_ac_a(4), _ac_b(4), 0))                     # acul 4
PARAP.append((_ac_b(4), F["F jos"], 1))                   # ramura 5, vale = dreapta
parap_txt = ", ".join(f"Vector4({r3(a)}, {r3(b)}, {sd}, 0)" for a, b, sd in PARAP)
print("\nparapete (frac0, frac1, latura):")
for a, b, sd in PARAP:
    print(f"  {a:.4f} -> {b:.4f}  latura {sd:+d}")

SUN_ROT = (-25.0, -110.0, 0.0)
SHEEP = "res://assets/models/monumentvalley/animals/sheep.glb"

# --- hazarde: transformari -----------------------------------------------------------------
sig_g = at_road(F_TUNNEL, 7.6)
sig_xf = f"Transform3D({rot_y(yaw_z_to(-d_in[0], -d_in[1]))}, {sig_g[0]:.3f}, {sig_g[1]:.3f}, {sig_g[2]:.3f})"

# Lampa: nod copil al lui SemaforTunel, mutat cu LAMP_BACK_M inapoi pe drum. Pozitie si
# inaltime se iau de pe drum la fractia ei, apoi se scriu in coordonatele locale ale hazardului
# (baza = rot_y: coloane X -> (c, s), Z -> (-s, c) in planul (x, z)).
_f_lamp = F_TUNNEL - LAMP_BACK_M / L_TOTAL
_gl = at_road(_f_lamp, 7.6)
_t_sig = yaw_z_to(-d_in[0], -d_in[1])
_d_l = travel_g(_f_lamp)
_t_lamp = yaw_z_to(-_d_l[0], -_d_l[1])
_dx, _dz = _gl[0] - sig_g[0], _gl[2] - sig_g[2]
_c, _s = math.cos(math.radians(_t_sig)), math.sin(math.radians(_t_sig))
lamp_local = (_c * _dx + _s * _dz, _gl[1] - sig_g[1], -_s * _dx + _c * _dz)
lamp_xf = f"Transform3D({rot_y(_t_lamp - _t_sig)}, {lamp_local[0]:.3f}, {lamp_local[1]:.3f}, {lamp_local[2]:.3f})"

# oile: curg in jos pe panta (nord = -Z in Godot) peste ramura a treia, road_dir de-a lungul ramurii
_pos_s, d_s = road_at(F_SHEEP)
road_dir_g = (d_s[0], -d_s[1])
flow_g = (0.0, -1.0)

# trenul: sina perpendiculara pe drum, rotita 30 de grade (diagonala)
dg = travel_g(F_TRAIN)
perp_g = (-dg[1], dg[0])
rail_deg = math.degrees(math.atan2(perp_g[1], perp_g[0])) + 30.0
tr_g = at_road(F_TRAIN)

print()
for nm, ff in (("urs", F_BEAR), ("semafor", F_TUNNEL), ("avalansa", F_AVAL), ("oi", F_SHEEP),
               ("sarituri", F_JUMP), ("tren", F_TRAIN)):
    pp, dd = road_at(ff)
    print(f"  {nm}: frac {ff:.4f} (L_TOTAL {L_TOTAL:.1f}) -> harta ({pp[0]:.0f}, {pp[1]:.0f}) cota {pp[2]:.1f} "
          f"directie {math.degrees(math.atan2(dd[0], dd[1])) % 360:.0f} deg")

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_channel.gd" id="3_channel"]
[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="4_hzm"]
[ext_resource type="Script" path="res://scenes/hazards/tunnel_signal_hazard.gd" id="5_signal"]
[ext_resource type="Script" path="res://scenes/hazards/herd_hazard.gd" id="6_herd"]
[ext_resource type="Script" path="res://scenes/hazards/train_hazard.gd" id="7_train"]
[ext_resource type="Script" path="res://scenes/hazards/hazard_lamp.gd" id="15_lamp"]
[ext_resource type="Script" uid="uid://twspgftscxb4" path="res://scenes/props/world_prop.gd" id="9_prop"]
[ext_resource type="PackedScene" path="res://assets/models/props/cow.glb" id="10_cow"]
[ext_resource type="PackedScene" path="res://assets/models/vehicles/snowplow.glb" id="11_plow"]
[ext_resource type="PackedScene" path="res://assets/models/structures/mountain_tunnel.glb" id="12_tunnel"]
[ext_resource type="PackedScene" path="res://assets/models/rocks/rock_large.glb" id="13_rock"]
[ext_resource type="PackedScene" path="res://assets/models/scatter/snow_patch.glb" id="14_snow"]

[sub_resource type="Curve3D" id="Curve3D_main"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="CylinderMesh" id="Cyl_balea"]
top_radius = {BAL_R}
bottom_radius = {BAL_R}
height = 0.1
radial_segments = 28
rings = 1
cap_bottom = false

[sub_resource type="StandardMaterial3D" id="Mat_balea"]
albedo_color = Color(0.25, 0.45, 0.47, 0.88)
transparency = 1
roughness = 0.25

[node name="Track21" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Transfagarasan"
custom_theme = "transfagarasan"
custom_world_seed_name = "transfagarasan21"
custom_half_width = 7.0
custom_road_surface = "asphalt"
custom_sun_rotation_deg = Vector3({SUN_ROT[0]:.0f}, {SUN_ROT[1]:.0f}, {SUN_ROT[2]:.0f})
custom_width_segments = Array[Vector3]([{w_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([0, 2])
custom_ravine_floors = Array[Vector2]([{floors_txt}])
custom_ravine_widths = Array[Vector2]([{widths_txt}])
custom_ravine_water = Array[Vector3]([{rwater_txt}])
custom_parapets = Array[Vector4]([{parap_txt}])
traffic_count = 0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_main")

[node name="Peaks" type="Node3D" parent="."]
"""
for nm, (px, py, pz), rad in PEAKS:
    tscn += f"""
[node name="{nm}" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {px:.2f}, {py:.2f}, {pz:.2f})
gizmo_extents = {rad}
script = ExtResource("2_peak")
radius_m = {rad}
"""
tscn += f"""
[node name="Hazarduri" type="Node3D" parent="."]

[node name="Urs" type="Marker3D" parent="Hazarduri"]
transform = {xf_ident(F_BEAR)}
gizmo_extents = 3.0
script = ExtResource("4_hzm")
kind = 0
model = ExtResource("10_cow")
model_scale = 0.9
face_travel = true
motion = 1
sweep_speed = 1.8

[node name="SemaforTunel" type="Node3D" parent="Hazarduri" node_paths=PackedStringArray("lamp")]
transform = {sig_xf}
script = ExtResource("5_signal")
period = 34.0
clear_hold = 6.0
tunnel_length = {TUNNEL_LEN}
bus_speed = 11.0
bus_width = 2.4
bus_length = 4.0
bus_model = ExtResource("11_plow")
bus_shove = 1.5
bus_side_accel = 4.0
bus_nose_angle_deg = 40.0
tunnel_half_width = 6.0
camera_tail_m = 18.0
first_green_bonus_s = 28.0
bus_lane_offset = -2.6
lamp = NodePath("Lampa")

[node name="Lampa" type="Node3D" parent="Hazarduri/SemaforTunel"]
transform = {lamp_xf}
script = ExtResource("15_lamp")
bulb_size = {LAMP_BULB}
spacing = {LAMP_SPACING}
slots = Array[int]([12, 16, 7])
glow_energy = {LAMP_GLOW}
invert_stack = true
glow_bulbs = Array[int]([0, 2])
head_height = {LAMP_HEAD}
arm_length = {LAMP_ARM}
pole_slot = 8
stop_line_span = 12.0
stop_line_offset = 7.6

[node name="Avalansa" type="Marker3D" parent="Hazarduri"]
transform = {xf_ident(F_AVAL)}
gizmo_extents = 3.0
script = ExtResource("4_hzm")
kind = 8
avalanche_period = 75.0
avalanche_from_left = true

[node name="OileAcPaior" type="Node3D" parent="Hazarduri"]
transform = {xf_ident(F_SHEEP)}
script = ExtResource("6_herd")
animal_model = "{SHEEP}"
alt_model = "{SHEEP}"
flow_dir = Vector3({flow_g[0]}, 0, {flow_g[1]})
road_dir = Vector3({road_dir_g[0]:.4f}, 0, {road_dir_g[1]:.4f})
corridor_m = 14.0
animal_mass = 45.0
speed = 2.5
spacing = 1.4
zebra_ratio = 0.0
no_body_radius = 9.0
body_reach = 18.0

[node name="Tren" type="Node3D" parent="Hazarduri"]
transform = Transform3D({rot_y(rail_deg)}, {tr_g[0]:.3f}, {tr_g[1]:.3f}, {tr_g[2]:.3f})
script = ExtResource("7_train")
model_path = "res://assets/models/vehicles/train.glb"
period = 40.0
half_rail = 65.0
road_half_width = 7.0

[node name="ParaulBalea" type="Marker3D" parent="Hazarduri"]
transform = {xf_ident(F_JUMP)}
gizmo_extents = 90.0
script = ExtResource("3_channel")
gap = 12.0
water_half = 6.0
bank = 16.0
depth = 18.0
water_y_drop = 15.0
reach = 90.0
fade = 30.0
jump = true
label = "Paraul Balea"

[node name="LacBalea" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {BAL_POS[0]:.2f}, {BAL_Y}, {BAL_POS[2]:.2f})
cast_shadow = 0
mesh = SubResource("Cyl_balea")
surface_material_override/0 = SubResource("Mat_balea")

[node name="DecorManual" type="Node3D" parent="."]
script = ExtResource("9_prop")
"""
RES = {"tunnel": "12_tunnel", "snowplow": "11_plow", "rock": "13_rock", "snow": "14_snow"}
for nm, res, xform, extra in dec:
    tscn += f"""
[node name="{nm}" parent="DecorManual" instance=ExtResource("{RES[res]}")]
transform = {xform}
"""
    if extra:
        tscn += extra + "\n"

with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"\nscris: {OUT_PATH}")
