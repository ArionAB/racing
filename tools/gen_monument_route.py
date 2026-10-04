# Genereaza traseul Monument Valley (Track19) din waypoints cu fillet-uri de arc --
# schela copiata din gen_kyoto_route.py (pas uniform 12 m, statistici ca ProbeLayout),
# fara specificul Kyoto, plus GARDA DE AZIMUT din docs/track_briefs/monument_valley.md
# §2.0, verificata pe punctele coapte INAINTE sa existe .tscn-ul (orientarea buclei
# se hotaraste din repere, nu invers). Garzile IES CU COD != 0 daca pica.
#
#   python tools/gen_monument_route.py [scenes/tracks/Track19.tscn]
#   python tools/gen_monument_route.py --sabotaj     # muta WM 80 m spre vest: garzile TREBUIE sa pice
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z,
# est = +X): harta ajunge in lume FARA oglindire, deci "dreapta" de pe harta e
# dreapta si in cadrul camerei (conventia din gen_kyoto_route.py).
# Sens ORAR pe plan: A spre E (latura de N), B/C/D spre S (latura de E, prin poarta
# Mittens), E spre V (latura de S), F/G spre N (latura de V), H spre E.
import math
import sys

SABOTAJ = "--sabotaj" in sys.argv
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
OUT_PATH = ARGS[0] if ARGS else None

# Repere = puncte FIXE ale schitei (nu derivate din traseu): garda de azimut nu se
# auto-confirma (memoria garda-circulara-propria-functie).
WM_REAL = (262.0, -300.0)   # West Mitten
EM = (338.0, -318.0)        # East Mitten
MB = (372.0, -262.0)        # Merrick Butte (la est, in afara buclei)
WM = WM_REAL
if SABOTAJ:
    WM = (WM_REAL[0] - 80.0, WM_REAL[1])   # sabotaj: reperul se muta 80 m spre vest

# (x, y, raza de fillet, cota sau None, eticheta) -- brief §2.1
WPTS = [
    (210, 40, 0, 12.0, "A start"),
    (300, 40, 34, 12.0, "A colt spre S"),
    (302, -8, 0, 12.0, "B coama"),
    (300, -150, 0, 0.0, "B capat asfalt"),
    (300, -166, 0, 0.0, "C grila"),
    (300, -228, 0, 0.0, "C cai"),
    (300, -309, 0, 0.5, "D poarta Mittens"),
    (300, -428, 46, 1.5, "D viraj spre V"),
    (210, -444, 0, 3.0, "E intrare trecatoare"),
    (120, -436, 0, 4.5, "E1"),
    (20, -450, 0, 6.5, "E2 defileu"),
    (-80, -444, 0, 9.0, "E' arcul"),
    (-150, -450, 44, 10.0, "F colt spre N"),
    (-200, -360, 40, 12.0, "F cornisa 1"),
    (-176, -258, 40, 13.5, "F cornisa 2"),
    (-198, -186, 34, 14.0, "F capat cornisa"),
    (-100, -160, 44, 6.0, "G S1 est"),
    (40, -180, 46, 1.0, "G S1 apex"),
    (80, -96, 44, 0.5, "G S1 iesire"),
    (-70, -60, 44, 0.0, "G S2 vest"),
    (-96, -14, 0, -0.5, "G2 albia"),
    (-96, 12, 30, 0.0, "G2 aterizare"),
    (-60, 40, 0, 1.0, "H inceput"),
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
print(f"puncte de control: {n} (pas {STEP} m)   lungime: {tot:.0f} m  (tinta ~2100 m)")


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
report(2050.0 <= tot <= 2150.0, f"lungime {tot:.0f} m (2050-2150)")
report(area < 0, f"sens {'ORAR' if area < 0 else 'ANTIORAR'} pe harta (cerut ORAR)")
report(min_r >= 9.0, f"raza minima {min_r:.1f} m la frac {min_r_at:.3f} (>= 9)")
report(max_s < 0.13, f"panta maxima {100*max_s:.1f}% la frac {max_s_at:.3f} (< 13%)")
report(min_sep >= 20.0, f"separare minima {min_sep:.1f} m intre {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f} (>= 20)")
report(cheb < 400.0, f"Cebasev fata de centroid ({cx:.0f},{cy:.0f}): {cheb:.0f} m (< 400; zidul lumii 420)")

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

crest_i = nearest((302, -8))
gate_i = nearest((300, -309))
print("\n=== GARDA DE AZIMUT (brief §2.0) ===")
az_w, az_e = azimut_to(crest_i, WM), azimut_to(crest_i, EM)
d_w, d_e = dist_to(crest_i, WM), dist_to(crest_i, EM)
report(abs(az_w) <= 15.0 and abs(az_e) <= 15.0 and 250.0 <= d_w <= 320.0 and 250.0 <= d_e <= 320.0,
       f"coama (frac {crest_i/n:.3f}, cota {rs[crest_i][2]:.1f}): WM azimut {az_w:+.1f} la {d_w:.0f} m, "
       f"EM {az_e:+.1f} la {d_e:.0f} m (prag <=15 deg, 250-320 m)")
idx = list(range(crest_i, gate_i + 1))
both = [i for i in idx if abs(azimut_to(i, WM)) <= 50.0 and abs(azimut_to(i, EM)) <= 50.0]
report(len(both) / len(idx) >= 0.70,
       f"B-D: AMBII Mittens in cadru (<= 50 deg) pe {len(both)}/{len(idx)} puncte "
       f"({100*len(both)/len(idx):.0f}%, prag 70%); cel mai aproape WM {min(dist_to(i, WM) for i in idx):.0f} m, "
       f"EM {min(dist_to(i, EM) for i in idx):.0f} m")

# soarele: elevatie 18, rotatie y -70 => busola 180 - y = 250 (VSV)
SUN_ROT = (-18.0, -70.0, 0.0)
sun_bearing = (180.0 - SUN_ROT[1]) % 360.0

def rel_sun(i):
    return (sun_bearing - heading_at(i) + 180.0) % 360.0 - 180.0

def mean_rel(f0, f1):
    i0, i1 = int(f0 * n), int(f1 * n)
    xs = [math.sin(math.radians(rel_sun(i))) for i in range(i0, i1 + 1)]
    ys = [math.cos(math.radians(rel_sun(i))) for i in range(i0, i1 + 1)]
    return math.degrees(math.atan2(sum(xs), sum(ys)))

b_rel = mean_rel(frac["B coama"] + 0.01, frac["B capat asfalt"])
e_rel = mean_rel(frac["E intrare trecatoare"], frac["E' arcul"])
report(30.0 <= b_rel <= 110.0,
       f"soarele ({sun_bearing:.0f} busola, 18 deg) fata de B (spre S): {b_rel:+.0f} deg (DREAPTA = pozitiv, 30-110)")
report(abs(e_rel) <= 40.0,
       f"soarele fata de E (spre V): {e_rel:+.0f} deg (in fata, |az| <= 40) -- contralumina trecatorii")
b_head = heading_at(nearest((300, -100))) % 360.0
e_head = heading_at(nearest((120, -436))) % 360.0
report(150.0 <= b_head <= 210.0 and 250.0 <= e_head <= 290.0,
       f"directii: B {b_head:.0f} (spre S), E {e_head:.0f} (spre V)")

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

def curve_pts(seq):
    return pva(seq)

F = frac
mean_elev = sum(p[2] for p in rs) / n
SEA_ABS = -22.0
sea_offset = round(SEA_ABS - mean_elev, 2)
print(f"\ncota medie sosea {mean_elev:.1f}; sea_level_offset {sea_offset} (marea absoluta {SEA_ABS})")

# --- latimi (semilatimi, brief §2): A/B/H 7 (implicit), C/D 6.5, E 5.5, F 6, G 8 --------
WS = [
    (0.131, 0.297, 6.5),
    (0.297, 0.434, 5.5),
    (0.434, 0.600, 6.0),
    (0.600, 0.834, 8.0),
]
w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in WS)

# --- parametri de suprafata / relief din brief ---------------------------------------
F_DIRT_FROM = r3(F["C grila"])      # ~0.137: grila pentru vite
F_DIRT_TO = 0.86                     # inceputul asfaltului lui H
GORGE = (0.33, 0.42)
ARCH = 0.434
CORN = (0.47, 0.60)

# --- Mittens: TerrainPeak (talus) + turn DecorManual ----------------------------------
PEAK_R = 28.0
PEAK_H = 15.0
peaks = [("WestMitten", WM_REAL), ("EastMitten", EM), ("Merrick", MB)]
# turnurile: Butte_B/Butte_C din rocks/butte.glb, scalate la ~30 m (placeholder, §5.2)
TOWERS = [  # nume, pozitie harta, varianta pastrata, scala, rotatie y (grade)
    ("WM_Turn", WM_REAL, "Butte_B", 0.86, 20.0),
    ("EM_Turn", EM, "Butte_B", 0.80, 200.0),
    ("MB_Turn", MB, "Butte_C", 0.62, 110.0),
]
VARIANTS = ["Butte_A", "Butte_B", "Butte_C", "Mesa_A", "Mesa_B"]
TOWER_Y = 13.0

# --- Bluff: escarpa de la sud de A ---------------------------------------------------
bluff_g = (270.0, 12.0, 6.0)

# --- G2: albia uscata ----------------------------------------------------------------
F_G2 = 0.838
g2_pos, g2_dir = road_at(F_G2)
g2_g = godot(g2_pos, g2_pos[2])

# --- G': scurtatura Dunele ----------------------------------------------------------
# Capetele sunt alese prin cautare (pe esantioane, frac 0.60-0.80): coarda trebuie sa fie
# cu 25-35% mai scurta decat tronsonul principal, la >= 25 m de restul drumului, iar castigul
# estimat (30 m/s, banda la 0.8x) sa cada in 0.5-1.5 s. Prima alegere (S1 est -> S1 iesire,
# 0.640 -> 0.743) dadea doar -20% si +0.02 s: bulge-ul lui S1 e prea mic ca sa plateasca.
i_in = 113    # frac 0.6457
i_out = 132   # frac 0.7543
main_len = sum(math.hypot(rs[(k + 1) % n][0] - rs[k][0], rs[(k + 1) % n][1] - rs[k][1])
               for k in range(i_in, i_out))
SHORT_PTS_MAP = []   # puncte INTERIOARE ale benzii (harta)
p0, p1 = rs[i_in], rs[i_out]
for t in (0.25, 0.5, 0.75):
    x = p0[0] + (p1[0] - p0[0]) * t
    y = p0[1] + (p1[1] - p0[1]) * t
    SHORT_PTS_MAP.append((x, y, p0[2] + (p1[2] - p0[2]) * t))
chain = [(p0[0], p0[1])] + [(a, b) for a, b, _ in SHORT_PTS_MAP] + [(p1[0], p1[1])]
short_len = sum(math.hypot(chain[k + 1][0] - chain[k][0], chain[k + 1][1] - chain[k][1])
                for k in range(len(chain) - 1))
V_REF = 30.0
dt = main_len / V_REF - short_len / (0.8 * V_REF)
print(f"G': principal {main_len:.0f} m, scurtatura {short_len:.0f} m "
      f"(-{100*(1-short_len/main_len):.0f}%, tinta 25-35%); entry_at {i_in/n:.4f} exit_at {i_out/n:.4f}; "
      f"castig estimat la {V_REF:.0f} m/s cu viteza 0.8x: {dt:+.2f} s (tinta 0.5-1.5)")
br_pts = [godot((a, b), e) for a, b, e in SHORT_PTS_MAP]


# --- hazarduri -------------------------------------------------------------------------
def marker_xf(f, along_m=0.0):
    pos, d = road_at(f + along_m / tot)
    g = godot(pos, pos[2])
    return f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g[0]:.3f}, {g[1]:.3f}, {g[2]:.3f})"

# rockfall D: markerul sta pe talusul WM (harta (278,-306)), traseul local trece peste drum spre EM
rf1_start = (278.0, -306.0)
rf1 = [(0, 0, 0), (12, -3, -2), (22, -5.5, -3), (30, -6, -3), (44, -5.5, -4)]   # +x = est
rf1_g = (rf1_start[0], 6.0, -rf1_start[1])
# rockfall E: de pe peretele din stanga (sud, mers spre V) peste drum, in trecatoare (x~72)
rf2_start = (72.0, -478.0)
rf2_g = (rf2_start[0], 9.0, -rf2_start[1])
rf2 = [(0, 0, 0), (-1, -2, -14), (-2, -5, -26), (-3, -6, -37), (-3, -6, -52)]    # -Z = nord

HORSE_C = 0.166
HORSE_G = 0.78
DEVIL_MAP = (-10.0, -125.0)

# landmarks A: turn de apa (id 0) si moara (id 2), pe stanga (nord) startului
LANDMARKS = [(0.012, -1, 0), (0.028, -1, 2)]
lm_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in LANDMARKS)

main_pts = [godot(p, p[2]) for p in rs]

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_bluff.gd" id="3_bluff"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="4_branch"]
[ext_resource type="Script" path="res://scenes/tracks/track_channel.gd" id="5_channel"]
[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="6_hzm"]
[ext_resource type="Script" path="res://scenes/hazards/dust_devil_hazard.gd" id="7_devil"]
[ext_resource type="Script" path="res://scenes/hazards/respawn_zone.gd" id="8_respawn"]
[ext_resource type="Script" uid="uid://twspgftscxb4" path="res://scenes/props/world_prop.gd" id="9_prop"]
[ext_resource type="PackedScene" path="res://assets/models/rocks/butte.glb" id="10_butte"]
[ext_resource type="PackedScene" path="res://assets/models/jodhpur/animals/baraat_horse.glb" id="11_horse"]

[sub_resource type="BoxShape3D" id="Box_cornisa"]
size = Vector3(130.0, 12.0, 270.0)

[sub_resource type="Curve3D" id="Curve3D_main"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_dunele"]
closed = false
_data = {{
"points": {pva(br_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in br_pts)})
}}
point_count = {len(br_pts)}

[sub_resource type="Curve3D" id="Curve3D_rf1"]
closed = false
_data = {{
"points": {curve_pts(rf1)},
"tilts": PackedFloat32Array({", ".join("0" for _ in rf1)})
}}
point_count = {len(rf1)}

[sub_resource type="Curve3D" id="Curve3D_rf2"]
closed = false
_data = {{
"points": {curve_pts(rf2)},
"tilts": PackedFloat32Array({", ".join("0" for _ in rf2)})
}}
point_count = {len(rf2)}

[node name="Track19" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Monument Valley"
custom_theme = "monumentvalley"
custom_world_seed_name = "monumentvalley"
custom_half_width = 7.0
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_sun_rotation_deg = Vector3({SUN_ROT[0]:.0f}, {SUN_ROT[1]:.0f}, {SUN_ROT[2]:.0f})
custom_sea_level_offset = {sea_offset}
custom_width_segments = Array[Vector3]([{w_txt}])
custom_dirt_ranges = Array[Vector2]([Vector2({F_DIRT_FROM}, {F_DIRT_TO})])
custom_gorge_ranges = Array[Vector2]([Vector2({GORGE[0]}, {GORGE[1]})])
custom_arch_fracs = Array[float]([{ARCH}])
custom_ravines = Array[Vector4]([Vector4({CORN[0]}, {CORN[1]}, 13.0, 1)])
custom_cornice_ravines = Array[int]([0])
custom_ravine_widths = Array[Vector2]([Vector2(0, 45.0)])
custom_landmarks = Array[Vector3]([{lm_txt}])
traffic_count = 0
terrain_pad_m = 260.0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_main")

[node name="Peaks" type="Node3D" parent="."]
"""
for nm, xy in peaks:
    g = (xy[0], PEAK_H, -xy[1])
    tscn += f"""
[node name="{nm}" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})
gizmo_extents = {PEAK_R}
script = ExtResource("2_peak")
radius_m = {PEAK_R}
"""
tscn += f"""
[node name="EscarpaA" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {bluff_g[0]:.2f}, {bluff_g[1]:.2f}, {bluff_g[2]:.2f})
gizmo_extents = 40.0
script = ExtResource("3_bluff")
half_width_m = 90.0
side_fade_m = 30.0
run_m = 24.0
drop_m = 12.0
terrace_count = 1
terrace_tread_m = 40.0
terrace_rise_m = 0.0
length_m = 190.0
end_fade_m = 40.0
road_clear_m = 8.0

[node name="Dunele" type="Path3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
curve = SubResource("Curve3D_dunele")
script = ExtResource("4_branch")
branch_half_width = 3.5
label = "Scurtatura Dunele"
entry_at = {i_in / n:.5f}
exit_at = {i_out / n:.5f}
speed_factor = 0.8
surface = 1
bumpiness = 0.06

[node name="Hazarduri" type="Node3D" parent="."]

[node name="AlbiaG2" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {g2_g[0]:.2f}, {g2_g[1]:.2f}, {g2_g[2]:.2f})
gizmo_extents = 40.0
script = ExtResource("5_channel")
gap = 12.0
water_half = 6.0
bank = 8.0
depth = 5.0
reach = 40.0
fade = 14.0
jump = true
dry = true
build_towers = false
build_ships = false
respawn_past_gap = true
label = "albia secata G2"

[node name="BolovanD" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {rf1_g[0]:.2f}, {rf1_g[1]:.2f}, {rf1_g[2]:.2f})
gizmo_extents = 3.0
script = ExtResource("6_hzm")
kind = 1
rock_pause = 13.0

[node name="Traseu" type="Path3D" parent="Hazarduri/BolovanD"]
curve = SubResource("Curve3D_rf1")

[node name="BolovanE" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {rf2_g[0]:.2f}, {rf2_g[1]:.2f}, {rf2_g[2]:.2f})
gizmo_extents = 3.0
script = ExtResource("6_hzm")
kind = 1
rock_pause = 17.0

[node name="Traseu" type="Path3D" parent="Hazarduri/BolovanE"]
curve = SubResource("Curve3D_rf2")
"""
for nm, f, along in (("CalC1", HORSE_C, 0.0), ("CalC2", HORSE_C, 3.5),
                     ("CalG1", HORSE_G, 0.0), ("CalG2", HORSE_G, 3.5)):
    tscn += f"""
[node name="{nm}" type="Marker3D" parent="Hazarduri"]
transform = {marker_xf(f, along)}
gizmo_extents = 3.0
script = ExtResource("6_hzm")
model = ExtResource("11_horse")
model_node = "Horse"
face_travel = true
motion = 1
sweep_speed = 2.0
"""
dv = (DEVIL_MAP[0], 1.0, -DEVIL_MAP[1])
tscn += f"""
[node name="VartejG" type="Node3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {dv[0]:.2f}, {dv[1]:.2f}, {dv[2]:.2f})
script = ExtResource("7_devil")
amplitude = Vector2(30, 18)
dust_amount = 24
debris_amount = 10
cone_color = Color(0.62, 0.34, 0.2, 1)

[node name="PlasaCornisa" type="Area3D" parent="Hazarduri"]
monitorable = false
script = ExtResource("8_respawn")

[node name="Cutie" type="CollisionShape3D" parent="Hazarduri/PlasaCornisa"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -120.0, -2.0, 320.0)
shape = SubResource("Box_cornisa")

[node name="DecorManual" type="Node3D" parent="."]
script = ExtResource("9_prop")
"""
for nm, xy, keep, sc, rot in TOWERS:
    g = (xy[0], TOWER_Y, -xy[1])
    c, s_ = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    tscn += f"""
[node name="{nm}" parent="DecorManual" instance=ExtResource("10_butte")]
transform = Transform3D({c*sc:.5f}, 0, {-s_*sc:.5f}, 0, {sc}, 0, {s_*sc:.5f}, 0, {c*sc:.5f}, {g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})
"""
    for k, vn in enumerate(VARIANTS):
        if vn != keep:
            tscn += f"""
[node name="{vn}" parent="DecorManual/{nm}" index="{k}"]
visible = false
"""

with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"\nscris: {OUT_PATH}")
