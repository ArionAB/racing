# Genereaza traseul Ha Long (Track22) din waypoints cu fillet-uri de arc --
# schela copiata din gen_transfagarasan_route.py (pas uniform 12 m, statistici ca
# ProbeLayout), cu GARDA DE AZIMUT si GARDA DE APA din
# docs/track_briefs/halong.md §2.0/§2.1/§2, verificate pe punctele coapte INAINTE
# sa existe .tscn-ul. Garzile IES CU COD != 0 daca pica.
#
#   python tools/gen_halong_route.py [scenes/tracks/Track22.tscn]
#   python tools/gen_halong_route.py --sabotaj   # muta sirul de turnuri de fundal
#                                                # 400 m spre vest: garzile TREBUIE
#                                                # sa pice (cod 1)
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z,
# est = +X): harta ajunge in lume FARA oglindire, deci "dreapta" de pe harta e
# dreapta si in cadrul camerei (conventia din gen_kyoto_route.py).
#
# Sens ANTIORAR pe plan: A spre S (cheiul satului plutitor, NV), B spre S
# (pontoanele, latura de vest), C spre E (digul si grota, latura de sud), D spre
# NE (urcarea pe insula + belvederea), E spre N (coborarea in doua ace de par +
# plaja), F spre V (canalul cu podetul), G spre V/NV (drumul de coasta), inapoi la A.
#
# DE CE EXISTA GARDA DE APA (brief §2, memoria
# cota-marii-e-relativa-la-media-drumului): cota marii e
# `_sampler.mean_road_y() + sea_level_offset` (track.gd:7055), adica RELATIVA la
# MEDIA cotelor soselei, nu la y = 0. Pe o pista JUMATATE PE APA, un deal inalt
# ridica marea peste drumul plutitor. Prima schita avea insula la +38 -> media
# +8.2 -> apa la +1.2, cu pontoanele (desenate la +0.6) SCUFUNDATE. De aceea
# `sea_level_offset` se scrie EXPLICIT, calculat din media masurata, si garda
# verifica rezultatul.
#
# PASUL 3 din brief §7. Fundatia porneste cu pontoanele ca CAROSABIL FIX
# (`PontoonRoadHazard` nu exista inca, brief §5.3): intai se masoara traseul,
# apa si plasa de repunere cu ProbeRace (pasul 4), abia apoi vine tablierul care
# se leagana. Tronsoanele sunt deja marcate cu `custom_width_segments` la 6 m si
# cu fractiile scrise in consola, ca sa se stie unde se taie gaurile.
import math
import os
import sys

SABOTAJ = "--sabotaj" in sys.argv
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
OUT_PATH = ARGS[0] if ARGS else None

HALF_WIDTH = 7.0

# Repere = puncte FIXE ale schitei (brief §2.1; nu derivate din traseu): garda de
# azimut nu se auto-confirma (memoria garda-circulara-propria-functie).
SAT = (-366.0, 280.0)          # centrul satului plutitor
GROTA = (-174.0, -253.0)       # gura grotei
BELVEDERE = (152.0, -224.0)    # punctul de belvedere
PLAJA = (212.0, 112.0)         # centrul plajei
PODET = (38.0, 199.0)          # mijlocul podetului de plute
# Sirul de turnuri de fundal (EST). Pozitia e limitata de DOUA capete, nu doar
# de azimut (memoria efecte-de-fundal-cote-legate: inel < fog_end < FAR_PLANE):
# la 430 m distanta maxima din fereastra de belvedere ieşea 409 m, adica PESTE
# FAR_PLANE 380 -- turnurile ar fi fost tăiate de planul de departare exact in
# cadrul in care sunt subiectul. Mutate la 360 m de belvedere.
TURNURI_REAL = (360.0, -170.0)
TURNURI = TURNURI_REAL
if SABOTAJ:
    TURNURI = (TURNURI_REAL[0] - 400.0, TURNURI_REAL[1])

# (x, y, raza de fillet, cota, eticheta) -- brief §2.1, EXACT cele 25 de puncte
# masurate cu tools/measure_halong_sketch.py (nicio ajustare fata de brief).
WPTS = [
    # --- A: cheiul satului plutitor (nord-vest) ----------------------------
    (-352,  322, 44,  1.0, "A start"),     (-362,  240, 0,   1.0, "A chei"),
    # --- B: pontoanele, trei tronsoane despartite de insulite fixe ---------
    (-354,  168, 0,   0.6, "B pont1"),     (-346,   96, 0,   0.6, "B insulita1"),
    (-338,   24, 0,   0.6, "B pont2"),     (-330,  -48, 0,   0.6, "B insulita2"),
    (-320, -120, 0,   0.6, "B pont3"),
    # --- C: digul de piatra, apoi grota marina ----------------------------
    (-296, -188, 44,  1.5, "C dig"),       (-218, -240, 0,   2.4, "C grota V"),
    (-130, -266, 0,   3.0, "C grota E"),
    # --- D: urcarea pe spinarea insulei + belvederea -----------------------
    ( -36, -284, 48,  7.0, "D urcare"),    (  60, -272, 44, 14.0, "D creasta"),
    ( 152, -224, 40, 21.0, "D belvedere"), ( 204, -152, 0,  26.0, "D varf"),
    # --- E: coborarea in doua ace de par (raza 24) + plaja -----------------
    ( 196,  -52, 24, 21.0, "E ac1a"),      ( 132,  -36, 24, 17.0, "E ac1b"),
    ( 164,   28, 24, 11.0, "E ac2a"),      ( 228,   44, 24,  7.0, "E ac2b"),
    ( 212,  112, 0,   3.0, "E plaja"),     ( 156,  164, 44,  1.6, "E iesire"),
    # --- F: canalul cu podetul de plute -----------------------------------
    (  84,  192, 0,   1.4, "F podet E"),   (  -8,  206, 0,   1.4, "F podet V"),
    # --- G: drumul de coasta, sapat in perete -----------------------------
    (-104,  226, 48,  1.6, "G coasta E"),  (-206,  262, 0,   1.4, "G maimute"),
    (-292,  300, 44,  1.2, "G coasta V"),
]

# Cotele pentru care sunt DESENATE suprafetele de pe apa (brief §2).
CHEI_Y = 1.0
PONTON_Y = 0.6
# Afundarea maxima a unui ponton sub autobuz: rest_sag + sag_bus din
# RopeBridgeHazard (brief §5.3). Cat timp pontoanele sunt carosabil fix, cifra e
# doar pentru garda: tablierul viitor nu are voie sa treaca sub plasa de mare.
PONTON_SAG = 0.5 + 0.45


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
tot = STEP * n
print(f"puncte de control: {n} (pas {STEP} m)   lungime: {tot:.0f} m  (tinta 2000-2200)")


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
report(min_r >= 9.0,
       f"raza minima {min_r:.1f} m la frac {min_r_at:.3f} (>= 9, tinta >= 14 = pragul AI: "
       f"{'atinsa' if min_r >= 14.0 else 'NEATINSA'})")
report(max_s < 0.13, f"panta maxima {100*max_s:.1f}% la frac {max_s_at:.3f} (< 13%)")
report(min_sep >= 20.0,
       f"separare minima {min_sep:.1f} m intre {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f} (>= 20)")
report(cheb < 400.0,
       f"Cebisev fata de centroid ({cx:.0f},{cy:.0f}): {cheb:.0f} m (< 400; zidul lumii 420)")

# --- GARDA DE APA (brief §2) --------------------------------------------------
# Cea care a prins defectul real: insula ridica media, media ridica marea.
y_mean = sum(p[2] for p in rs) / n
y_min = min(p[2] for p in rs)
y_max = max(p[2] for p in rs)
SEA_OFFSET = -round(y_mean, 2)          # ca apa sa iasa la 0.0
sea_y = y_mean + SEA_OFFSET
net_y = sea_y - 1.2                     # track.gd _build_sea_respawn
print("\n=== GARDA DE APA (cota marii e RELATIVA la media cotelor soselei) ===")
print(f"  cote: min {y_min:.1f}  max {y_max:.1f}  medie {y_mean:.2f}")
print(f"  sea_level_offset = {SEA_OFFSET:.2f} (EXPLICIT, nu implicitul -7) -> apa la {sea_y:+.2f}")
print(f"  plasa de mare (SeaRespawn) la {net_y:+.2f} = apa - 1.2")
report(abs(sea_y) < 0.15, f"apa la {sea_y:+.2f} (tinta 0.00 +/- 0.15, cota pentru care sunt desenate chei/pontoane)")
report(sea_y < PONTON_Y - 0.3,
       f"apa {sea_y:+.2f} sub pontoane {PONTON_Y:+.2f} cu marja >= 0.3 m (altfel pontoanele sunt scufundate)")
report(PONTON_Y - PONTON_SAG > net_y,
       f"ponton afundat la {PONTON_Y - PONTON_SAG:+.2f} (rest_sag+sag_bus) DEASUPRA plasei {net_y:+.2f} "
       f"(marja {PONTON_Y - PONTON_SAG - net_y:.2f} m; altfel masina de pe ponton e repusa din greseala)")
report(CHEI_Y > sea_y + 0.5, f"cheiul {CHEI_Y:+.2f} deasupra apei cu >= 0.5 m")

# --- garda de azimut ----------------------------------------------------------
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


print("\n=== GARDA DE AZIMUT (brief §2.0/§2.1, repere FIXE, in cadru = |azimut| <= 50 deg) ===")
for label, (f0, f1), target, limit, thr in (
        ("turnurile de fundal de pe belvedere (0.44-0.52)", (0.44, 0.52), TURNURI, 50.0, 0.60),
        # Fereastra incepe la 0.15, nu la 0.12: de pe tronsonul 1 grota e la
        # ~390 m, PESTE FAR_PLANE 380, deci acolo nu se vede oricum (prinsa de
        # garda de departare). Telegraful util e de pe tronsonul 2 incolo.
        ("turnul cu grota de pe pontoane (0.15-0.22)", (0.15, 0.22), GROTA, 50.0, 0.80),
        ("satul plutitor de pe coasta (0.90-0.97)", (0.90, 0.97), SAT, 50.0, 0.80),
        ("plaja de pe acul 2 (0.66-0.70)", (0.66, 0.70), PLAJA, 50.0, 0.60),
        ("podetul de pe latura de nord (0.74-0.78)", (0.74, 0.78), PODET, 50.0, 0.70)):
    k, m = in_frame(f0, f1, target, limit)
    idx = window(f0, f1)
    dmin = min(dist_to(i, target) for i in idx)
    dmax = max(dist_to(i, target) for i in idx)
    report(k / m >= thr,
           f"{label}: in cadru (<= {limit:.0f} deg) pe {k}/{m} puncte ({100*k/m:.0f}%, prag {100*thr:.0f}%), "
           f"distanta {dmin:.0f}-{dmax:.0f} m")

# Reperele NU au voie sa stea peste planul de departare: un reper la > FAR_PLANE
# e tăiat exact in cadrul in care e subiectul (memoria
# efecte-de-fundal-cote-legate: inel < fog_end < FAR_PLANE).
FAR_PLANE = 380.0
FOG_END = 340.0     # brief §4
print(f"\n=== GARDA DE DEPARTARE (reperele sub FAR_PLANE {FAR_PLANE:.0f}) ===")
for label, (f0, f1), target in (
        ("turnurile de fundal (de pe belvedere)", (0.44, 0.52), TURNURI),
        ("turnul cu grota (de pe pontoane)", (0.15, 0.22), GROTA),
        ("satul plutitor (de pe coasta)", (0.90, 0.97), SAT)):
    idx = [i for i in window(f0, f1) if abs(azimut_to(i, target)) <= 50.0]
    if not idx:
        continue
    dmax = max(dist_to(i, target) for i in idx)
    report(dmax < FAR_PLANE,
           f"{label}: cel mai departe cadru in care se vede = {dmax:.0f} m (< {FAR_PLANE:.0f})")

# --- hazarde cu ceas: >= 200 m intre ele (track08.gd:267) ---------------------
F_PONTON2 = frac["B pont2"]
F_JONCA = frac["F podet E"] + 0.5 * (frac["F podet V"] - frac["F podet E"])
F_MAIMUTE = frac["G maimute"]


def gap_m(f0, f1):
    return ((f1 - f0) % 1.0) * tot


print("\n=== HAZARDE CU CEAS (>= 200 m intre ele) ===")
for lbl, g in (("pontoane -> jonca", gap_m(F_PONTON2, F_JONCA)),
               ("jonca -> maimute", gap_m(F_JONCA, F_MAIMUTE)),
               ("maimute -> pontoane", gap_m(F_MAIMUTE, F_PONTON2))):
    report(g >= 200.0, f"{lbl}: {g:.0f} m")

if not all(guard_results):
    print("\nGARDA: CEL PUTIN O LINIE A PICAT -- nu scriu .tscn, ies cu cod 1")
    sys.exit(1)
print("\nGARDA: TOATE TREC")
if SABOTAJ:
    print("(sabotaj cerut, dar garzile au trecut: SABOTAJUL NU PRINDE)")
    sys.exit(1)

# ---------------------------------------------------------------------------------
# De aici in jos: doar scrierea .tscn-ului (brief §7 pasul 3).
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


# --- fractiile hazardelor (brief §3) -----------------------------------------
# Grota: ~70 m prin baza unui turn, intre "C grota V" si "C grota E".
F_GROTTO0 = F["C grota V"]
F_GROTTO1 = F_GROTTO0 + 70.0 / L_TOTAL
# Podetul de plute peste canal (F), cu jonca pe la mijloc.
F_RAFT0 = F["F podet E"]
F_RAFT1 = F["F podet V"]
RAFT_LEN = ((F_RAFT1 - F_RAFT0) % 1.0) * L_TOTAL

# --- latimi: pontoanele, grota si podetul la 6 m ------------------------------
# Tronsoanele de ponton (brief §2): trei bucati despartite de doua insulite fixe.
PONT_SEGS = [
    (F["B pont1"], F["B insulita1"]),
    (F["B pont2"], F["B insulita2"]),
    (F["B pont3"], F["C dig"]),
]
# Grota si podetul la 6 m (brief §2: ingustarea e parte din atmosfera lor).
# NOTA DE METODA: lărgisem podetul la 7 m crezand ca de asta cad masinile la
# frac 0.80 — n-a schimbat nimic, fiindca adevarata cauza era colizorul
# placeholder al joncii (vezi mai jos). Lăţimea e repusa la intentia din brief:
# o "reparatie" care nu schimba cifra nu e o reparatie, e o modificare de
# design strecurata.
WS = [(r3(F_GROTTO0 - 0.002), r3(F_GROTTO1 + 0.002), 6.0),
      (r3(F_RAFT0 - 0.002), r3(F_RAFT1 + 0.002), 6.0)]
for a, b in PONT_SEGS:
    WS.append((r3(a), r3(b), 6.0))
w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in WS)

# --- varfuri: turnurile de calcar apropiate (FLANC) + insula ------------------
# Brief §2.0: turnurile apropiate sunt FLANC (< 40 m lateral), nu reper. Insula
# e relieful care duce drumul la +26 (D-E).
isl_c = at_road(F["D belvedere"], 0.0)
PEAKS = [
    ("Insula", (isl_c[0] - 40.0, 44.0, isl_c[2] - 40.0), 190.0),
    ("TurnGrota", (-174.0, 52.0, 253.0), 70.0),
    ("TurnVest", (-430.0, 46.0, -40.0), 80.0),
    ("TurnSud", (-150.0, 50.0, 330.0), 85.0),
    ("TurnNord", (-60.0, 44.0, -300.0), 75.0),
]

# --- rape: apa de golf pe exteriorul buclei ----------------------------------
# Latura: -1 stanga, +1 dreapta in sensul de mers. Bucla e ANTIORARA, deci
# exteriorul (marea deschisa) e la DREAPTA pe latura de vest si de sud.
RAVINES = [
    (0.055, 0.235, 26.0, 1),    # 0 golful la pontoane (dreapta = larg)
    (0.245, 0.300, 22.0, 1),    # 1 golful la dig
    (0.700, 0.760, 18.0, 1),    # 2 caldarea plajei
    # 3 canalul de sub podet. Rapa sta DOAR sub mijlocul podetului si incepe la
    # 30 m de buza, deci drumul are umar de fiecare parte: un canal lat pe toata
    # lungimea podetului ar fi facut din trecere o taxa, nu o atmosfera.
    # (Ingustarea a fost intai incercata ca "reparatie" pentru repunerile de la
    # frac 0.80 si N-A schimbat cifra — cauza era colizorul joncii. Se pastreaza
    # pe motivul de design, nu pe cel greşit.)
    (0.800, 0.822, 30.0, 1),    # 3 canalul de sub podet (doar la mijloc)
    (0.850, 0.980, 20.0, 1),    # 4 golful pe latura de coasta
]
rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d in RAVINES)
# Fundul: apa de golf e ADANCA (brief §0.1: verde-jad opac, nu turcoaz de mic
# adanc). -14 e SEA_NEAR_DEPTH, de la care culoarea e de larg.
RAV_FLOORS = [(0, -15.0), (1, -14.0), (2, -5.0), (3, -6.0), (4, -14.0)]
floors_txt = ", ".join(f"Vector2({i}, {y})" for i, y in RAV_FLOORS)
RAV_WIDTHS = [(0, 150.0), (1, 120.0), (2, 70.0), (3, 55.0), (4, 130.0)]
widths_txt = ", ".join(f"Vector2({i}, {w})" for i, w in RAV_WIDTHS)
# Apa in rape, la cota marii (0.0). E ACELASI golf, nu bazine separate — si de
# aceea se declara O SINGURA DATA, pe rapa 0: `_build_ravine_water` umple prin
# inundare (flood fill) de la buza in jos si tine minte celulele ude in
# `_ravine_wet`, iar o a doua rapa cu ACEEASI cota nu mai gaseste nicio celula
# libera si iese cu `push_warning` ("rapa N n-are nicio celula sub 0.0") plus o
# zona de repunere eliberata degeaba. Prima versiune le declarase pe toate cinci
# si sonda a scos exact patru avertismente.
RAV_WATER = [(0, 0.0, 18.0)]
rwater_txt = ", ".join(f"Vector3({i}, {y}, {b})" for i, y, b in RAV_WATER)

# --- soarele: ESE (~110 deg), ~30 deg (brief §4) -----------------------------
# Conventia busolei din gen_okinawa_route.py: y = 180 - azimut.
SUN_AZ = 110.0
SUN_ROT = (-30.0, 180.0 - SUN_AZ, 0.0)

# --- decor provizoriu: turnuri de calcar din kitul Okinawa -------------------
# Brief §7 pasul 3: piese PROVIZORII, ca sa se vada scara. Kitul propriu vine
# la pasul 7.
dec = []


def add(nm, res, xform, extra=""):
    dec.append((nm, res, xform, extra))


# Turnuri de calcar pe exteriorul buclei, ca FLANC (brief §2.0: < 40 m lateral).
k = 0
for ff, lat, sc in ((0.09, 34.0, 2.6), (0.14, 38.0, 3.1), (0.19, 33.0, 2.4),
                    (0.26, 36.0, 2.8), (0.31, -30.0, 2.2), (0.355, -34.0, 2.9),
                    (0.76, 32.0, 2.3), (0.80, 36.0, 2.7), (0.86, 34.0, 2.5),
                    (0.92, 38.0, 3.0), (0.96, 32.0, 2.2)):
    g = at_road(ff, lat)
    add(f"TurnCalcar{k:02d}", "rock",
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + k * 23.0, sc, sc * 1.9, sc)}, "
        f"{g[0]:.2f}, {g[1] - 1.0:.2f}, {g[2]:.2f})")
    k += 1
# Pontoanele: placi plate provizorii pe cele trei tronsoane (carosabil fix).
k = 0
for a, b in PONT_SEGS:
    span = ((b - a) % 1.0) * L_TOTAL
    steps = max(2, int(span / 14.0))
    for j in range(steps):
        ff = a + (b - a) * (j + 0.5) / steps
        g = at_road(ff, 0.0)
        add(f"Ponton{k:02d}", "quay",
            f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)), 1.4, 0.3, 1.2)}, "
            f"{g[0]:.2f}, {g[1] - 0.45:.2f}, {g[2]:.2f})",
            'metadata/coliziune = "none"')
        k += 1

RES = {"rock": "13_rock", "quay": "14_quay"}

# --- consola: fractiile care conteaza la pasul urmator -----------------------
print("\n=== FRACTII (pentru pasii urmatori) ===")
for w in WPTS:
    ff = F[w[4]]
    pp, dd = road_at(ff)
    print(f"  {w[4]:<16} frac {ff:.4f}  harta ({pp[0]:6.0f}, {pp[1]:6.0f})  cota {pp[2]:5.1f}")
print(f"\n  grota:   {F_GROTTO0:.4f} -> {F_GROTTO1:.4f}  (70 m)")
print(f"  podet:   {F_RAFT0:.4f} -> {F_RAFT1:.4f}  ({RAFT_LEN:.0f} m)")
print("  pontoane (tronsoane, pentru road_hole_span la pasul urmator):")
for idx, (a, b) in enumerate(PONT_SEGS):
    print(f"    tronson {idx+1}: {a:.4f} -> {b:.4f}  ({((b-a)%1.0)*L_TOTAL:.0f} m)")
print(f"\n  jonca:   {F_JONCA:.4f}")
print(f"  maimute: {F_MAIMUTE:.4f}")

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="4_hzm"]
[ext_resource type="Script" path="res://scenes/hazards/herd_hazard.gd" id="6_herd"]
[ext_resource type="Script" uid="uid://twspgftscxb4" path="res://scenes/props/world_prop.gd" id="9_prop"]
[ext_resource type="PackedScene" path="res://assets/models/rocks/rock_large.glb" id="13_rock"]
[ext_resource type="PackedScene" path="res://assets/models/okinawa/structures/harbour_quay.glb" id="14_quay"]
[ext_resource type="PackedScene" path="res://assets/models/okinawa/vehicles/fishing_boat.glb" id="15_boat"]

[sub_resource type="Curve3D" id="Curve3D_main"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[node name="Track22" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Ha Long"
custom_theme = "halong"
custom_world_seed_name = "halong22"
custom_half_width = {HALF_WIDTH}
custom_road_surface = "asphalt"
custom_sea_level_offset = {SEA_OFFSET:.2f}
custom_sun_rotation_deg = Vector3({SUN_ROT[0]:.0f}, {SUN_ROT[1]:.0f}, {SUN_ROT[2]:.0f})
custom_width_segments = Array[Vector3]([{w_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_ravine_floors = Array[Vector2]([{floors_txt}])
custom_ravine_widths = Array[Vector2]([{widths_txt}])
custom_ravine_water = Array[Vector3]([{rwater_txt}])
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

# Hazardele care NU cer clase noi (brief §3): jonca pe SlidingHazard (kind 0,
# TRAVERSARE) si maimutele pe HerdHazard. Pontonul si mareea vin dupa ProbeRace.
#
# JONCA ARE NEVOIE DE `model`, chiar provizoriu. `SlidingHazard` *extends
# AnimatableBody3D*, iar fara `model_scene` isi face `_build_placeholder_box()`:
# un corp SOLID de 4.5 x 2.2 x 2.6 m care traverseaza drumul. Prima versiune il
# lasase fara model si ProbeRace a dat 2-5 repuneri pe fiecare seed, toate la
# frac 0.801, toate in ACELASI punct — adica hazardul functiona perfect, doar
# ca era un zid fara forma. Diagnosticul a venit din raycast pe punct (a gasit
# un `@AnimatableBody3D@64` pe carosabil), nu din ghicit: inainte incercasem
# sa ingustez rapa canalului si sa largesc podetul, si NICIUNA n-a schimbat
# cifra (acelasi 2 si 5). Modelul provizoriu e barca de pescuit din kitul
# Okinawa, ca vaca folosita pentru urs la Transfagarasan; `fishing_junk` din
# §5.2 o inlocuieste la pasul 7.
jonca_xf = xf_ident(F_JONCA)
_pm, dm = road_at(F_MAIMUTE)
road_dir_g = (dm[0], -dm[1])
# Maimutele sar DIN perete spre drum: fluxul e transversal, dinspre stanga
# (peretele de calcar e pe stanga pe latura de nord, spre interiorul buclei).
flow_g = (-road_dir_g[1], road_dir_g[0])

tscn += f"""
[node name="Hazarduri" type="Node3D" parent="."]

[node name="JoncaCanal" type="Marker3D" parent="Hazarduri"]
transform = {jonca_xf}
gizmo_extents = 3.0
script = ExtResource("4_hzm")
kind = 0
model = ExtResource("15_boat")
model_scale = 1.0
face_travel = true
motion = 1
sweep_speed = 2.2

[node name="MaimutePerete" type="Node3D" parent="Hazarduri"]
transform = {xf_ident(F_MAIMUTE)}
script = ExtResource("6_herd")
flow_dir = Vector3({flow_g[0]:.4f}, 0, {flow_g[1]:.4f})
road_dir = Vector3({road_dir_g[0]:.4f}, 0, {road_dir_g[1]:.4f})
corridor_m = 10.0
animal_mass = 12.0
speed = 4.0
spacing = 1.1
zebra_ratio = 0.0
no_body_radius = 7.0
body_reach = 14.0

[node name="DecorManual" type="Node3D" parent="."]
script = ExtResource("9_prop")
"""
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
print(f"\nDE PUS IN TEMA `halong` (track.gd, brief §4): sea_level_offset = {SEA_OFFSET:.2f}")
print("  (NU implicitul -7: media cotelor ridica marea -- vezi garda de apa mai sus)")
