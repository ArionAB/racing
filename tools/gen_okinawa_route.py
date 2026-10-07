# Genereaza traseul Okinawa (Track20) din waypoints cu fillet-uri de arc --
# schela copiata din gen_monument_route.py (pas uniform 12 m, statistici ca
# ProbeLayout), cu GARDA DE AZIMUT din docs/track_briefs/okinawa.md §2.0/§2.1,
# verificata pe punctele coapte INAINTE sa existe .tscn-ul (orientarea buclei se
# hotaraste din repere, nu invers). Garzile IES CU COD != 0 daca pica.
#
#   python tools/gen_okinawa_route.py [scenes/tracks/Track20.tscn]
#   python tools/gen_okinawa_route.py --sabotaj     # muta palatul 150 m spre vest:
#                                                   # garzile TREBUIE sa pice (cod 1)
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z,
# est = +X): harta ajunge in lume FARA oglindire, deci "dreapta" de pe harta e
# dreapta si in cadrul camerei (conventia din gen_kyoto_route.py).
# Sens ORAR pe plan: A spre V (latura de S a insulei mari), B spre N (vest),
# C/D spre E (nord, urcarea si culmea), E spre S (latura de est, cornisa), F spre
# SE (coborarea si podul), G spre S/V (insula mica), H spre NV (digul), inapoi la A.
import math
import os
import sys

SABOTAJ = "--sabotaj" in sys.argv
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
OUT_PATH = ARGS[0] if ARGS else None

# Repere = puncte FIXE ale schitei (brief §2.1; nu derivate din traseu): garda de
# azimut nu se auto-confirma (memoria garda-circulara-propria-functie).
PALACE_REAL = (110.0, 285.0)   # palatul rosu, pe culme (top +46 peste mare)
LIGHTHOUSE = (318.0, 170.0)    # farul alb, capul E
CANAL = (322.0, -148.0)        # centrul traveei ridicatoare
TROMBA = (400.0, -338.0)       # plaja insulei mici
DIG = (225.0, -338.0)          # digul H, unde sparge valul
PALACE = PALACE_REAL
if SABOTAJ:
    PALACE = (PALACE_REAL[0] - 150.0, PALACE_REAL[1])   # sabotaj: palatul se muta 150 m spre vest

# (x, y, raza de fillet, cota, eticheta) -- brief §2.1, EXACT cele 25 de puncte
# (nicio ajustare fata de brief).
WPTS = [
    (35, -165, 0, 2.0, "A start"),        (-60, -168, 0, 2.0, "A sat port"),
    (-175, -150, 34, 2.5, "A colt N"),    (-215, -60, 0, 4.0, "B fukugi"),
    (-205, 0, 22, 5.0, "B sicana"),       (-228, 55, 26, 6.5, "B iesire"),
    (-178, 140, 38, 12.0, "C trestie"),   (-95, 185, 0, 19.0, "C urcare"),
    (-35, 245, 30, 25.0, "D ziduri"),     (20, 232, 26, 28.0, "D S"),
    (85, 265, 55, 30.0, "D varf"),        (150, 248, 0, 30.0, "D poarta"),
    (232, 222, 36, 27.0, "E colt S cap"), (272, 140, 0, 22.0, "E cornisa far"),
    (278, 40, 0, 14.0, "E3"),             (255, -45, 34, 9.0, "F cap pod"),
    (288, -110, 0, 8.5, "F pod start"),   (322, -148, 0, 8.5, "F traveea"),
    (360, -188, 0, 8.5, "F pod capat"),   (412, -252, 34, 5.0, "G insula"),
    (400, -338, 40, 3.0, "G plaja tromba"), (310, -375, 34, 2.0, "G3"),
    (225, -338, 0, 1.6, "H dig val"),     (140, -252, 40, 1.6, "H2"),
    (95, -168, 36, 1.8, "H colt port"),
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
print(f"puncte de control: {n} (pas {STEP} m)   lungime: {tot:.0f} m  (tinta 2000-2150)")


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
report(2000.0 <= tot <= 2150.0, f"lungime {tot:.0f} m (2000-2150)")
report(area < 0, f"sens {'ORAR' if area < 0 else 'ANTIORAR'} pe harta (cerut ORAR)")
report(min_r >= 9.0, f"raza minima {min_r:.1f} m la frac {min_r_at:.3f} (>= 9, tinta >= 25: {'atinsa' if min_r >= 25.0 else 'NEATINSA'})")
report(max_s < 0.13, f"panta maxima {100*max_s:.1f}% la frac {max_s_at:.3f} (< 13%, tinta <= 9%: {'atinsa' if max_s <= 0.09 else 'NEATINSA'})")
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

print("\n=== GARDA DE AZIMUT (brief par. 2.0/2.1, repere FIXE) ===")
for label, (f0, f1), target, limit in (
        ("palatul din C (0.25-0.40)", (0.25, 0.40), PALACE, 50.0),
        ("tromba de pe pod (0.62-0.70)", (0.62, 0.70), TROMBA, 30.0),
        ("canalul de pe cornisa (0.50-0.60)", (0.50, 0.60), CANAL, 50.0),
        ("digul de pe insula (0.78-0.86)", (0.78, 0.86), DIG, 50.0)):
    k, m = in_frame(f0, f1, target, limit)
    idx = window(f0, f1)
    dmin = min(dist_to(i, target) for i in idx)
    dmax = max(dist_to(i, target) for i in idx)
    report(k / m >= 0.80,
           f"{label}: in cadru (<= {limit:.0f} deg) pe {k}/{m} puncte ({100*k/m:.0f}%, prag 80%), "
           f"distanta {dmin:.0f}-{dmax:.0f} m")

# vertical (informativ, brief §2.0): varful palatului (+46 peste mare) vs. marginea de
# sus a cadrului camerei = 10 + 0.092*d peste cota drumului
idx = window(0.25, 0.40)
vis = 0
for i in idx:
    d = dist_to(i, PALACE)
    top = 46.0 - rs[i][2]
    if top <= 10.0 + 0.092 * d:
        vis += 1
print(f"  (info) palatul INTREG sub marginea de sus a cadrului pe {vis}/{len(idx)} puncte din C "
      f"(ocluzia o masoara okinawa_frustum_table.py, nu garda asta)")

if not all(guard_results):
    print("\nGARDA: CEL PUTIN O LINIE A PICAT -- nu scriu .tscn, ies cu cod 1")
    sys.exit(1)
print("\nGARDA: TOATE TREC")
if SABOTAJ:
    sys.exit(0)

# ---------------------------------------------------------------------------------
# De aici in jos: doar scrierea .tscn-ului.
if OUT_PATH is None:
    print("(fara cale de iesire: nu scriu nimic)")
    sys.exit(0)


def godot(p, e):
    return (p[0], e, -p[1])

def r3(x):
    return round(x, 3)

_cum = cum_lengths(rs)

def road_at(f):
    """Pozitie (x, y_harta, cota) + directie unitara pe harta, INTERPOLAT pe arc."""
    sd = (f % 1.0) * _cum[-1]
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
mean_elev = sum(p[2] for p in rs) / n
SEA_ABS = 0.0     # marea absoluta: cota 0 (digul sta la +1.6, podul la +8.5)
sea_offset = round(SEA_ABS - mean_elev, 2)
# Fundul golfului la -4 m sub mare (laguna turcoaz de mic adanc, sub SEA_REEF_DEPTH 5):
# bed = mean_y - lagoon_depth  =>  lagoon_depth = mean_y + 4.
LAGOON_WATER_DEPTH = 4.0
lagoon_depth = round(mean_elev + LAGOON_WATER_DEPTH, 1)
print(f"\ncota medie sosea {mean_elev:.2f}; sea_level_offset {sea_offset} (marea absoluta {SEA_ABS}); "
      f"lagoon_depth {lagoon_depth} (apa {LAGOON_WATER_DEPTH} m)")

SUN_ROT = (-25.0, -70.0, 0.0)   # busola 180 - y = 250 = VSV, elevatie 25 (ca in tema okinawa)

# --- latimi (semilatimi, brief §2): B 5.5, D 6, pod 6.5, dig H 6.5; restul 7 -------
fB0, fB1 = r3(F["A colt N"] + 0.004), r3(F["B iesire"])
fD0, fD1 = r3(F["D ziduri"] - 0.004), r3(F["D poarta"] + 0.012)
fP0, fP1 = r3(F["F pod start"] - 0.02), r3(F["F pod capat"] + 0.02)
fH0, fH1 = r3(F["G3"]), r3(F["H colt port"])
WS = [(fB0, fB1, 5.5), (fD0, fD1, 6.0), (fP0, fP1, 6.5), (fH0, fH1, 6.5)]
w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in WS)

# --- aleea de nisip coraligen: B ---------------------------------------------------
DIRT = [(fB0, fB1)]
dirt_txt = ", ".join(f"Vector2({a}, {b})" for a, b in DIRT)

# --- rape: 0 = cornisa E (stanga = est = marea), 1 = podul (viaduct, ambele laturi),
#           2 = digul H (ambele laturi) -------------------------------------------------
fE0, fE1 = r3(F["E cornisa far"]), r3(F["F cap pod"])
fV0, fV1 = r3(F["F pod start"] - 0.012), r3(F["F pod capat"] + 0.012)
fG0, fG1 = r3(F["G3"] + 0.015), r3(F["H colt port"] - 0.025)
RAVINES = [
    (fE0, fE1, 30.0, -1),     # cornisa E: buza la 0.5 m de asfalt, marea la picior
    (fV0, fV1, 12.5, 0),      # podul: terenul coboara si SUB tablier (viaduct), fund la -4
    (0.735, 0.805, 5.0, -1),  # plaja G: marea (stanga = larg) la ~8 m de asfalt, ca tromba sa porneasca DIN APA
    (fG0, fG1, 6.0, 0),       # digul H: marea pana la asfalt pe ambele parti, putin adanc (turcoaz)
]
rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d in RAVINES)
# Fara `custom_ravine_widths`: cu latime (60 m) cornisa a iesit un iaz dreptunghiular cu mal
# de uscat dincolo de el; fara, marginea exterioara a insulei (shore) e cea care inchide apa.

# --- golful (custom_lagoon): interiorul buclei din coltul SE, intre pod, insula mica,
#     dig si coasta insulei mari. Harta (x, y) -> lume Vector2(gx, gz) = (x, -y). ---------
BAY_MAP = [
    (225, -58), (292, -105), (330, -150), (372, -195), (405, -250), (392, -322),
    (320, -360), (232, -326), (150, -252), (108, -178), (112, -128), (160, -88),
]
lag_txt = ", ".join(f"Vector2({x}, {-y})" for x, y in BAY_MAP)

# --- hazarduri -------------------------------------------------------------------------
def marker_xf(f, along_m=0.0):
    pos, d = road_at(f + along_m / tot)
    g = godot(pos, pos[2])
    return f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g[0]:.3f}, {g[1]:.3f}, {g[2]:.3f})"

F_BRIDGE = r3((F["F traveea"]))
F_TYPHOON = float(os.environ.get("OK_TYPHOON", "0.77"))
F_WAVE = float(os.environ.get("OK_WAVE", "0.88"))
BR_POS, _bd = road_at(F_BRIDGE)
br_g = godot(BR_POS, BR_POS[2])
print(f"pod: frac {F_BRIDGE}, pozitie harta ({BR_POS[0]:.0f}, {BR_POS[1]:.0f}) cota {BR_POS[2]:.1f}; "
      f"tromba {F_TYPHOON}; val {F_WAVE}")
for nm, ff in (("pod", F_BRIDGE), ("tromba", F_TYPHOON), ("val", F_WAVE)):
    pp, dd = road_at(ff)
    print(f"  {nm}: frac {ff:.3f} -> harta ({pp[0]:.0f}, {pp[1]:.0f}) cota {pp[2]:.1f} "
          f"directie {math.degrees(math.atan2(dd[0], dd[1])) % 360:.0f} deg")

# --- decor provizoriu (kitul vechi, ca sa se vada scara) ---------------------------------
def rot_y(deg, sc=1.0):
    c, s_ = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return f"{c*sc:.5f}, 0, {-s_*sc:.5f}, 0, {sc}, 0, {s_*sc:.5f}, 0, {c*sc:.5f}"

def rot_y_s(deg, sx, sy, sz):
    """ca rot_y, dar cu scara pe fiecare axa locala (coloane scalate, randuri in .tscn)."""
    c, s_ = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return f"{sx*c:.5f}, 0, {-sz*s_:.5f}, 0, {sy}, 0, {sx*s_:.5f}, 0, {sz*c:.5f}"

def offset_from_road(f, lateral, yaw_extra=0.0):
    """Punct la `lateral` m de axa (+ = dreapta, - = stanga), + cota drumului + yaw 'along'."""
    pos, d = road_at(f)
    rx, ry = d[1], -d[0]            # dreapta pe harta pentru directia (dx, dy)
    x, y = pos[0] + rx * lateral, pos[1] + ry * lateral
    heading = math.degrees(math.atan2(d[0], d[1]))   # 0 = N, 90 = E (harta)
    # Godot: yaw 0 = obiect cu axa lunga pe +X; harta -> lume (gx = x, gz = -y).
    # directia de mers in Godot = (dx, 0, -dy); yaw = atan2(-dz, dx) pentru +X local.
    # `rot_y(t)` (formatul pe randuri din .tscn) aseaza axa locala +X pe (cos t, 0, sin t)
    # in lume, iar directia de mers in lume e (dx, 0, -dy): deci t = -atan2(dy, dx).
    yaw = -math.degrees(math.atan2(d[1], d[0]))
    return (x, pos[2], -y), yaw + yaw_extra

# tetrapozi pe latura dinspre larg (stanga) a digului H
tetra = []
f_a, f_b = fG0 + 0.01, fG1 - 0.01
k = 0
ft = f_a
while ft < f_b:
    for row, lat in enumerate((-9.0, -13.5)):
        g, yaw = offset_from_road(ft + (0.5 * 4.5 / tot if row else 0.0), lat)
        tetra.append((f"Tetra{k:02d}", g, yaw * 3.7 + k * 41.0))
        k += 1
    ft += 4.5 / tot * 2.0
# ziduri gusuku langa D (provizorii, kitul vechi, 2.8-4.5 m)
gusuku = []
for i, ff in enumerate([F["D ziduri"] + 0.006 * j for j in range(1, 12)]):
    side = -1.0 if i % 2 == 0 else 1.0
    g, yaw = offset_from_road(ff, side * 9.5)
    gusuku.append((f"Gusuku{i:02d}", g, yaw))
# farul alb (kitul vechi, lighthouse.glb 9 m), pe capul E
# poarta provizorie peste drum la ~0.43
F_GATE = 0.43
# Golul dintre picioarele din kit are ~1.9 m inauntru (x in +-0.95..1.89): ca sa treaca un
# drum de 12 m (D, semilatime 6) cu marja, X se scaleaza 6.8x (gol ~12.9 m), iar Y/Z doar 2.6x
# (poarta de ~9.6 m, nu de 25). Provizoriu: o inlocuieste `ryukyu_gate` (brief par. 5.1).
GATE_SX = 6.8
gate_pos, gate_yaw = offset_from_road(F_GATE, 0.0)

main_pts = [godot(p, p[2]) for p in rs]

SHIP_MODEL = "res://assets/models/fiordland/vehicles/cruise_boat.glb"

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/track_channel.gd" id="5_channel"]
[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="6_hzm"]
[ext_resource type="Script" uid="uid://twspgftscxb4" path="res://scenes/props/world_prop.gd" id="9_prop"]
[ext_resource type="PackedScene" path="res://assets/models/structures/tetrapod.glb" id="10_tetra"]
[ext_resource type="PackedScene" path="res://assets/models/structures/gusuku_wall.glb" id="11_gusuku"]
[ext_resource type="PackedScene" path="res://assets/models/buildings/lighthouse.glb" id="12_light"]
[ext_resource type="PackedScene" path="res://assets/models/structures/stone_gate_torii.glb" id="13_gate"]

[sub_resource type="Curve3D" id="Curve3D_main"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[node name="Track20" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Okinawa"
custom_theme = "okinawa"
custom_world_seed_name = "okinawa20"
custom_half_width = 7.0
custom_road_surface = "asphalt"
custom_sun_rotation_deg = Vector3({SUN_ROT[0]:.0f}, {SUN_ROT[1]:.0f}, {SUN_ROT[2]:.0f})
custom_sea_level_offset = {sea_offset}
custom_width_segments = Array[Vector3]([{w_txt}])
custom_dirt_ranges = Array[Vector2]([{dirt_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([0])
custom_viaduct_ravines = Array[int]([1])
custom_lagoon = Array[Vector2]([{lag_txt}])
traffic_count = 0
lagoon_depth = {lagoon_depth}

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_main")

[node name="Hazarduri" type="Node3D" parent="."]

[node name="PodMobil" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {br_g[0]:.3f}, {br_g[1]:.3f}, {br_g[2]:.3f})
gizmo_extents = 100.0
script = ExtResource("5_channel")
gap = 12.0
water_half = 26.0
bank = 20.0
depth = 13.0
reach = 100.0
fade = 40.0
jump = false
label = "Podul de la Kouri"
ship_model = "{SHIP_MODEL}"
ship_node = "Boat"
ship_scale = 1.0
ship_draft = 0.0
ship_bow_neg_z = true

[node name="Tromba" type="Marker3D" parent="Hazarduri"]
transform = {marker_xf(F_TYPHOON)}
gizmo_extents = 3.0
script = ExtResource("6_hzm")
kind = 4

[node name="Val" type="Marker3D" parent="Hazarduri"]
transform = {marker_xf(F_WAVE)}
gizmo_extents = 3.0
script = ExtResource("6_hzm")
kind = 9

[node name="DecorManual" type="Node3D" parent="."]
script = ExtResource("9_prop")

[node name="Dig_tetrapozi" type="Node3D" parent="DecorManual"]
"""
for nm, g, yaw in tetra:
    tscn += f"""
[node name="{nm}" parent="DecorManual/Dig_tetrapozi" instance=ExtResource("10_tetra")]
transform = Transform3D({rot_y(yaw, 1.6)}, {g[0]:.2f}, {g[1] + 0.25:.2f}, {g[2]:.2f})
"""
    for kk, vn in ((1, "Tetrapod_04"), (2, "Tetrapod_Stack_01")):
        tscn += f"""
[node name="{vn}" parent="DecorManual/Dig_tetrapozi/{nm}" index="{kk}"]
visible = false
"""
tscn += """
[node name="Ziduri_D" type="Node3D" parent="DecorManual"]
"""
for nm, g, yaw in gusuku:
    tscn += f"""
[node name="{nm}" parent="DecorManual/Ziduri_D" instance=ExtResource("11_gusuku")]
transform = Transform3D({rot_y(yaw, 1.3)}, {g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})
"""
    for kk, vn in ((1, "Gusuku_Wall_B"), (2, "Gusuku_Wall_C")):
        tscn += f"""
[node name="{vn}" parent="DecorManual/Ziduri_D/{nm}" index="{kk}"]
visible = false
"""
lh = (LIGHTHOUSE[0], float(os.environ.get("OK_LIGHT_Y", "22.0")), -LIGHTHOUSE[1])
tscn += f"""
[node name="Far_capul_E" parent="DecorManual" instance=ExtResource("12_light")]
transform = Transform3D(2.2, 0, 0, 0, 2.2, 0, 0, 0, 2.2, {lh[0]:.2f}, {lh[1]:.2f}, {lh[2]:.2f})

[node name="Poarta_D" parent="DecorManual" instance=ExtResource("13_gate")]
transform = Transform3D({rot_y_s(gate_yaw + 90.0, GATE_SX, 2.6, 2.6)}, {gate_pos[0]:.2f}, {gate_pos[1]:.2f}, {gate_pos[2]:.2f})
"""

with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"\nscris: {OUT_PATH}")
