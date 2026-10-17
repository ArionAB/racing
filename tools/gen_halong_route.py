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
# FAR_PLANE 380 -- turnurile ar fi fost taiate de planul de departare exact in
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
    # --- G: drumul de coasta + GOLFUL care intra in uscat -----------------
    # REDESENAT (14 oct 2026, decizia dezvoltatorului). Latura G era o linie
    # aproape dreapta de la (84,192) la (-352,322), si pe o dreapta NU exista
    # scurtatura: o banda paralela castiga 2%, iar o coarda nu are ce sa taie
    # (brief §7.3 — trei incercari, toate masurate si infirmate).
    #
    # Acum drumul OCOLESTE un golf care intra ~100 m spre uscat (nord), iar
    # scurtatura taie peste GURA golfului, la nivelul apei — exact ce cere o
    # terasa de maree. Adancimea e aleasa pe masuratoare, nu din ochi:
    #    60 m -> -12.4% (prea putin)      80 m -> -22.0%
    #   100 m -> -28.4% (TINTA -25...-35%)  120 m -> -36.2%
    # La 100 m bucla creste la 2076 m, deci ramane in fereastra 2000-2200.
    # Maimutele se muta pe ramura de intrare in golf (fractia se recalculeaza).
    (-104,  226, 40,  1.6, "G golf E"),
    (-150,  326, 34,  1.8, "G golf fund"),
    (-200,  320, 34,  1.6, "G golf fund2"),
    (-246,  262, 40,  1.4, "G golf V"),
]

# Cotele pentru care sunt DESENATE suprafetele de pe apa (brief §2).
CHEI_Y = 1.0
PONTON_Y = 0.6
# Afundarea maxima a unui ponton sub autobuz: rest_sag + sag_bus din
# RopeBridgeHazard (brief §5.3). Cat timp pontoanele sunt carosabil fix, cifra e
# doar pentru garda: tablierul viitor nu are voie sa treaca sub plasa de mare.
PONTON_SAG = 0.5 + 0.45

# --- JONCA: scara si viteza, DERIVATE din masuratori (nu alese) --------------
# Gabaritul corpului, masurat cu tools/ProbeHlPoint.tscn pe scena construita:
# `fishing_boat.glb` da un corp de 4.12 x 5.35 x 9.32 m, iar podetul masoara
# 11.5 m de carosabil. La scara 1.0 ramaneau 2.18 m de banda libera cand barca
# e pe axa — mai putin decat latimea unei masini, deci traversarea era un zid,
# nu un obstacol de ocolit. De aici 6-8 repuneri pe seed.
JONCA_BEAM_M = 9.32      # masurat, nu din brief
ROAD_AT_RAFT_M = 11.5    # masurat pe scena
# Tinta: o banda libera de ~5 m (o masina trece confortabil, dar trebuie sa
# vrea). Scara iese din ea, nu din gust.
JONCA_FREE_TARGET_M = 5.0
JONCA_SCALE = round((ROAD_AT_RAFT_M - JONCA_FREE_TARGET_M) / JONCA_BEAM_M, 3)
#
# VITEZA: implicitul clasei (12.0), nu 2.2. Antetul lui SlidingHazard are
# masuratoarea, si e contraintuitiva: "incetinirea maturarii «ca sa fie mai
# citibil» INRAUTATESTE lucrurile. Cu perioada dubla, obstacolul devine un
# blocaj semi-static si toata lumea intra in el (cadre de contact per masina:
# ~10 la perioada originala, ~110 la dublu). Un obstacol rapid traverseaza si
# elibereaza drumul; unul lent sta in el." Pusesem 2.2 din reflexul "o barca e
# lenta" — exact greşeala pe care clasa o avertizeaza. Lamele de pe Track15
# merg la 2.0 fiindca SUNT animale lente si au `model_scale` 3.135 pe un GLB
# mic; o jonca de 9 m nu e o lama.
JONCA_SWEEP = 12.0   # = SlidingHazard.MAX_SWEEP_SPEED_DEFAULT



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
# e taiat exact in cadrul in care e subiectul (memoria
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
# Maimutele: pe ramura de INTRARE in golf (intre gura si fund), unde drumul e
# sapat in perete si exista parapet pe care sa stea. Punctul "G maimute" a
# disparut la redesenarea laturii G (vezi WPTS), deci fractia se ia acum de pe
# ramura noua.
F_MAIMUTE = frac["G golf fund"]


def gap_m(f0, f1):
    return ((f1 - f0) % 1.0) * tot


print("\n=== HAZARDE CU CEAS (>= 200 m intre ele) ===")
for lbl, g in (("pontoane -> jonca", gap_m(F_PONTON2, F_JONCA)),
               ("jonca -> maimute", gap_m(F_JONCA, F_MAIMUTE)),
               ("maimute -> pontoane", gap_m(F_MAIMUTE, F_PONTON2))):
    report(g >= 200.0, f"{lbl}: {g:.0f} m")

# --- GARDA DE BANDA LIBERA la jonca ------------------------------------------
# Contractul gimmickului (brief §3): jonca e o DECIZIE ("trec sau aştept"), nu
# o taxa. Daca banda libera scade sub latimea unei masini, nu mai e decizie.
# Cifra se masoara pe scena construita cu tools/ProbeHlPoint.tscn; aici se
# verifica perechea (scara x gabarit) inainte sa se scrie .tscn-ul.
CAR_WIDTH_M = 2.6     # gabaritul caroseriei (bus_width din Track21 e 2.4)
print("\n=== GARDA DE BANDA LIBERA (jonca e decizie, nu taxa) ===")
_beam = JONCA_BEAM_M * JONCA_SCALE
_free = ROAD_AT_RAFT_M - _beam
print(f"  jonca la scara {JONCA_SCALE}: {_beam:.2f} m pe {ROAD_AT_RAFT_M:.1f} m de carosabil")
report(_free >= CAR_WIDTH_M * 1.6,
       f"banda libera {_free:.2f} m >= {CAR_WIDTH_M * 1.6:.2f} m (1.6 x latimea masinii)")
report(_free <= ROAD_AT_RAFT_M * 0.6,
       f"banda libera {_free:.2f} m <= {ROAD_AT_RAFT_M * 0.6:.2f} m (altfel jonca nu mai e obstacol)")
report(JONCA_SWEEP >= 8.0,
       f"sweep_speed {JONCA_SWEEP} >= 8.0 (antetul SlidingHazard: lent = blocaj semi-static, "
       f"~110 cadre de contact la perioada dubla vs ~10)")

# TRONSOANELE DE PONTON. Lungimea e constransa de `Track._resolve_span_holes`:
# gaura din carosabil se taie pe `2*steps` puncte coapte, iar bucla care cauta
# pasul merge doar pana la **k = 15**. Pasul mediu masurat pe Track22 e
# **2.001 m** (1009 puncte pe 2019 m), deci gaura maxima pe care mecanismul o
# poate taia e **60 m**.
#
# Prima versiune avea 3 tronsoane de 71.5 m, adica peste limita: gaura s-a
# taiat la 60 m, iar ultimii ~11 m au ramas ASFALT peste placile care se mişca.
# ProbeRace a dat 148-156 repuneri pe cursa (de la 1-3), toate grupate la
# fractiile capetelor de tronson (0.11 / 0.14 / 0.21). Nu e un defect al
# pontonului: e un contract depasit, in silentiu.
#
# Remediul NU e sa cresc limita din track.gd (ar atinge podul de pe Machu
# Picchu, care merge la 34 m si k~8): tronsoane MAI SCURTE. Sapte bucati de
# ~50 m pe cei ~353 m de zona plutitoare, cu marja fata de 60.
_PONT_START = frac["B pont1"]
_PONT_END = frac["C dig"]
_PONT_N = 7
_PONT_SPAN_FRAC = (_PONT_END - _PONT_START) / float(_PONT_N)
# Fiecare tronson lasa o fanta de insulita la capat: tablierul acopera
# `_PONT_GAP` mai putin, iar pe bucata aia sta piatra fixa.
_PONT_GAP = 0.004
# SEMI-latimea carosabilului pe pontoane. `custom_width_segments` ia HALF_WIDTH
# (vezi TrackFromPath.custom_width_segments: "(frac_start, frac_end,
# half_width)"), iar `PontoonRoadHazard.deck_width` ia latimea TOTALA a
# tablierului. Prima versiune punea 6.0 in amandoua: carosabilul ieşea de 12 m
# si tablierul de 6, deci 3 m de fiecare parte pe care masina calca pe NIMIC.
# ProbeRace: 7-24 repuneri, grupate pe primul tronson. Cifra se scrie O DATA si
# se deriva in ambele locuri.
_PONT_HALF_W = 6.0
PONT_SEGS = [
    (_PONT_START + i * _PONT_SPAN_FRAC,
     _PONT_START + (i + 1) * _PONT_SPAN_FRAC - _PONT_GAP)
    for i in range(_PONT_N)
]

# --- GARDA DE GAURA DE CAROSABIL (pontoane) ----------------------------------
# `Track._resolve_span_holes` taie gaura pe `2*steps` puncte coapte, cu bucla
# limitata la k = 15. Pasul mediu masurat pe Track22 e 2.001 m, deci gaura
# maxima e 60 m. Un tronson mai lung primeste o gaura PREA MICA si ramane
# asfalt peste placi — defect silentios care a costat 148-156 repuneri/cursa.
SPAN_HOLE_MAX_M = 2.0 * 15 * 2.001   # k_max * 2 * pas_mediu_masurat
print("\n=== GARDA DE GAURA DE CAROSABIL (tronsoane de ponton) ===")
_pont_lens = [((b - a) % 1.0) * tot for a, b in PONT_SEGS]
for _i, _ln in enumerate(_pont_lens):
    report(_ln <= SPAN_HOLE_MAX_M,
           f"tronson {_i + 1}: {_ln:.1f} m <= {SPAN_HOLE_MAX_M:.0f} m "
           f"(limita k=15 x pas 2.001 m din Track._resolve_span_holes)")
report(min(_pont_lens) >= 24.0,
       f"cel mai scurt tronson {min(_pont_lens):.1f} m >= 24 m "
       f"(sub atat, leganarea nu se simte: e o treapta, nu o pluta)")
# LATIMEA: `custom_width_segments` ia SEMI-latime, `deck_width` ia latimea
# TOTALA. Nepotrivirea e MUTA — masina calca pe nimic la 3 m de ax si cade,
# fara niciun avertisment — deci cifra se scrie o data (`_PONT_HALF_W`) si se
# deriva in ambele locuri. Garda nu compara constanta cu ea insasi (ar fi
# tautologie): verifica plafonul pe care il impune camera si `half_width`-ul
# pistei, adica faptul ca pontonul nu e nici mai ingust decat o masina care
# depaseste, nici mai lat decat carosabilul din jur.
report(_PONT_HALF_W * 2.0 >= 3.0 * CAR_WIDTH_M,
       f"tablierul {_PONT_HALF_W * 2.0:.1f} m >= 3 masini late ({3.0 * CAR_WIDTH_M:.1f} m): "
       f"se poate depasi pe el")
report(_PONT_HALF_W <= HALF_WIDTH,
       f"semi-latimea pontonului {_PONT_HALF_W:.1f} m <= {HALF_WIDTH:.1f} m a pistei "
       f"(un tablier mai lat decat drumul ar atarna peste apa)")

# --- GARDA DE SCURTATURA (banda de jos peste gura golfului) ------------------
# Patru lucruri, fiecare pentru un defect care a costat deja o runda (§7.3):
#  1. CASTIG in tinta: o banda PARALELA da -2%, deci banda trebuie sa taie
#     coarda; peste -45% drumul lung n-ar mai fi ales niciodata;
#  2. NU TRECE PESTE LINIA DE START: altfel masina inchide turul pe scurtatura
#     si reintra dincolo de start -> tur de 2.88 s, masurat;
#  3. PLATA: o terasa de maree pe panta n-ar tine apa;
#  4. TREAPTA LA JONCTIUNE zero: profilul de coborare e `4u(1-u)`.
_BRG0, _BRG1 = 0.8555, 0.9653
_bmain = ((_BRG1 - _BRG0) % 1.0) * tot
_bi0, _bi1 = int(_BRG0 * n) % n, int(_BRG1 * n) % n
_bchord = math.hypot(rs[_bi1][0] - rs[_bi0][0], rs[_bi1][1] - rs[_bi0][1])
_bgain = 100.0 * (_bchord / _bmain - 1.0)
print("\n=== GARDA DE SCURTATURA (banda de jos peste golf) ===")
print(f"  ocolul {_bmain:.1f} m, coarda {_bchord:.1f} m ({_bgain:+.1f}%)")
report(-45.0 <= _bgain <= -20.0,
       f"castigul {_bgain:+.1f}% in [-45%, -20%] (tinta Monument Valley "
       f"-25...-35%; o banda paralela da doar -2%)")
report(_BRG1 > _BRG0,
       f"banda NU trece peste linia de start ({_BRG0:.3f} -> {_BRG1:.3f}): "
       f"altfel turul se inchide pe scurtatura (masurat: tur de 2.88 s)")
_bdz = max(abs(rs[k % n][2] - rs[_bi0][2]) for k in range(_bi0, _bi1 + 1))
report(_bdz <= 3.0,
       f"abaterea de cota pe ocol {_bdz:.1f} m <= 3 m (o terasa de maree pe "
       f"panta n-ar tine apa)")
for _ue in (0.0, 1.0):
    report(1.0 * 4.0 * _ue * (1.0 - _ue) <= 0.3,
           f"treapta la jonctiune (u={_ue:.0f}): "
           f"{1.0 * 4.0 * _ue * (1.0 - _ue):.2f} m <= 0.30 m")

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
# Grota si podetul la 6 m (brief §2: ingustarea e parte din atmosfera lor).
# NOTA DE METODA: largisem podetul la 7 m crezand ca de asta cad masinile la
# frac 0.80 — n-a schimbat nimic, fiindca adevarata cauza era colizorul
# placeholder al joncii (vezi mai jos). Laţimea e repusa la intentia din brief:
# o "reparatie" care nu schimba cifra nu e o reparatie, e o modificare de
# design strecurata.
WS = [(r3(F_GROTTO0 - 0.002), r3(F_GROTTO1 + 0.002), 6.0),
      (r3(F_RAFT0 - 0.002), r3(F_RAFT1 + 0.002), 6.0)]
for a, b in PONT_SEGS:
    WS.append((r3(a), r3(b), _PONT_HALF_W))
w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in WS)

# --- varfuri: turnurile de calcar apropiate (FLANC) + insula ------------------
# Brief §2.0: turnurile apropiate sunt FLANC (< 40 m lateral), nu reper. Insula
# e relieful care duce drumul la +26 (D-E).
isl_c = at_road(F["D belvedere"], 0.0)
# PROPORTIA FACE TURNUL, nu inaltimea. Prima versiune avea raze de 70-85 m la
# inaltimi de 44-52 m, adica raport h/r = 0.57-0.74 — aia e un DEAL, nu un turn
# de carst. Pe planul de sus se vedea exact asta: insula umplea tot interiorul
# buclei ca o masa cenusie plata, iar „turnurile" erau movile late.
# Un turn de carst are pereti aproape verticali: **h/r >= 1.5**.
#
# Insula ramane larga (e o insula, nu un turn), dar coboara de la 190 la 120 m
# raza: la 190 m, cu Cebisev 305, umplea practic tot interiorul buclei si nu mai
# ramanea apa intre drum si centru — exact pe dos fata de brief §0.1 („turnuri
# verticale din apa, nu o platforma cu drum in jur").
PEAKS = [
    ("Insula", (isl_c[0] - 40.0, 30.0, isl_c[2] - 40.0), 120.0),
    ("TurnGrota", (-174.0, 58.0, 253.0), 32.0),
    ("TurnVest", (-430.0, 52.0, -40.0), 30.0),
    ("TurnSud", (-150.0, 60.0, 330.0), 33.0),
    ("TurnNord", (-60.0, 48.0, -300.0), 28.0),
    # Turnuri IN GOLF, intre drum si centru: ele sunt subiectul pistei si pana
    # acum lipseau cu totul — interiorul buclei era o singura masa de teren.
    ("TurnGolf1", (-250.0, 54.0, 60.0), 30.0),
    ("TurnGolf2", (-180.0, 46.0, -120.0), 26.0),
    ("TurnGolf3", (-30.0, 50.0, 150.0), 28.0),
]

# --- GARDA DE PROPORTIE A TURNURILOR ----------------------------------------
# Brief §0.1: ce trebuie recunoscut in 3 secunde sunt „turnuri de calcar
# cenusii iesind DREPT din apa". Un turn de carst are pereti aproape verticali;
# o movila lata citeste „deal", iar pe planul de sus arata ca o platforma cu
# drum in jur — exact ce s-a intamplat la prima generare. Garda masoara
# RAPORTUL h/r, nu inaltimea.
print("\n=== GARDA DE PROPORTIE (turn de carst, nu deal) ===")
_prop_ok = True
for _nm, _pos, _rad in PEAKS:
    if not _nm.startswith("Turn"):
        continue
    _ratio = _pos[1] / max(_rad, 0.1)
    _ok = _ratio >= 1.5
    _prop_ok = _prop_ok and _ok
    print(f"  [{'OK' if _ok else 'PROBLEMA'}] {_nm}: h={_pos[1]:.0f} / r={_rad:.0f} "
          f"-> h/r = {_ratio:.2f} (prag 1.50; sub atat e deal)")
_isl = [p for p in PEAKS if p[0] == "Insula"][0]
_isl_ok = _isl[2] <= cheb * 0.45
_prop_ok = _prop_ok and _isl_ok
print(f"  [{'OK' if _isl_ok else 'PROBLEMA'}] insula: raza {_isl[2]:.0f} m <= "
      f"{cheb * 0.45:.0f} m (45% din Cebisev {cheb:.0f}); peste atat umple "
      f"interiorul si nu mai ramane golf")
if not _prop_ok:
    print("\nGARDA DE PROPORTIE A PICAT -- nu scriu .tscn, ies cu cod 1")
    sys.exit(1)

# --- rape: apa de golf pe exteriorul buclei ----------------------------------
# Latura: -1 stanga, +1 dreapta in sensul de mers. Bucla e ANTIORARA, deci
# exteriorul (marea deschisa) e la DREAPTA pe latura de vest si de sud.
# FRACTIILE SE DERIVA DIN POI, NU SUNT CONSTANTE. Cand latura G s-a redesenat
# (golful), bucla a crescut de la 2028 la 2076 m si TOATE fractiile au alunecat
# cu ~2%. Rapele hardcodate au ramas pe cifrele vechi, deci nu mai erau aliniate
# cu pontoanele: marginea tablierului a ajuns peste buza rapei (masurat -1.44 m
# la 8 m de ax, in loc de teren) si repunerile pe primul ponton au urcat de la
# 0/3/0/4 la 1/13/2/9. O cifra care descrie o POZITIE pe traseu se leaga de
# reperul ei, nu de o fractie scrisa de mana.
RAVINES = [
    # 0 golful la pontoane (dreapta = larg): de la cheiul de start pana la dig.
    (r3(F["A chei"]), r3(F["C dig"]), 26.0, 1),
    (r3(F["C dig"]), r3(F_GROTTO0), 22.0, 1),            # 1 golful la dig
    (r3(F["E plaja"] - 0.012), r3(F["E iesire"]), 18.0, 1),  # 2 caldarea plajei
    # 3 canalul de sub podet. Rapa sta DOAR sub mijlocul podetului si incepe la
    # 30 m de buza, deci drumul are umar de fiecare parte: un canal lat pe toata
    # lungimea podetului ar fi facut din trecere o taxa, nu o atmosfera.
    # (Ingustarea a fost intai incercata ca "reparatie" pentru repunerile de la
    # frac 0.80 si N-A schimbat cifra — cauza era colizorul joncii. Se pastreaza
    # pe motivul de design, nu pe cel greşit.)
    # 3: mijlocul podetului, derivat din fractiile LUI (nu 0.800/0.822 fixe).
    (r3(F_RAFT0 + (F_RAFT1 - F_RAFT0) * 0.28),
     r3(F_RAFT0 + (F_RAFT1 - F_RAFT0) * 0.72), 30.0, 1),
    # 4 golful pe latura de coasta: de la gura golfului pana inainte de chei.
    (r3(F["G golf E"]), r3(F["G golf V"] + 0.010), 20.0, 1),
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
    # Piesele REALE de carst, alternate, cu scalare UNIFORMA. `rock_large`
    # scalat 1.9x pe Y avea h/r 2,16 — sub pragul de 2,50 al pistei, deci
    # citea ca bolovan, nu turn. `karst_stack_a/b` trec garda de silueta
    # (nisa/mijloc 0,57-0,63, h/r 2,73-3,11) si NU se mai deformeaza pe Y:
    # o scalare neuniforma ar strica exact raportul pe care il garanteaza.
    _res = "stack_a" if k % 2 == 0 else "stack_b"
    _su = sc * 0.72 if _res == "stack_a" else sc * 0.95
    add(f"TurnCalcar{k:02d}", _res,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + k * 23.0, _su, _su, _su)}, "
        f"{g[0]:.2f}, {g[1] - 1.20:.2f}, {g[2]:.2f})")
    k += 1
# Insulitele FIXE dintre tronsoanele de ponton: piatra pe care se sprijina
# capetele. Pontonul isi face tablierul singur (PontoonRoadHazard), deci aici
# vine doar ce NU pluteste. Contractul lor: pragul de la piatra la ponton <
# 0.3 m, verificat de probe_ponton (`edge_drop`, masurat 0.042 m).
k = 0
for _idx, (_pa, _pb) in enumerate(PONT_SEGS):
    if _idx == 0:
        continue   # primul tronson incepe de pe chei, nu de pe insulita
    g = at_road(_pa - _PONT_GAP * 0.5)
    # COTA: suprafata insulitei trebuie sa cada la cota tablierului, nu peste.
    # Prima versiune o lasa cu partea de sus la ~1.2-1.4 in timp ce tablierul
    # sta la 0.43-0.56 -> prag de ~0.7 m, adica de doua ori limita de 0.3 la
    # care un prag devine ZID (memoria `suprafete-cu-goluri-si-praguri`).
    # Cotele vin din `docs/asset_briefs/okinawa_kit_v2.md:213`, nu presupuse:
    # `harbour_quay.glb` are **2,2 m peste apa** (+1,5 m sub) si **originea la
    # LINIA APEI** (`--origin=waterline`), nu la baza. Deci la scara `_QUAY_SY`
    # varful sta la `2.2 * _QUAY_SY` DEASUPRA originii, si ca sa aduc varful la
    # cota drumului cobor originea cu atat.
    # COTELE PIESEI PROPRII, nu ale celei de la Okinawa. `harbour_quay.glb`
    # are 2,2 m peste apa si originea la LINIA APEI. `stone_quay.glb` e alta
    # piesa: 1,5 m inaltime totala, originea la BAZA (verificat pe GLB,
    # `--origin=assembly`, Quay_Stone min Y = 0,000). Deci varful sta la
    # 1,5 * scara DEASUPRA originii, nu la 2,2.
    _QUAY_TOP_M = 1.5
    _QUAY_SY = 1.0
    # Plus corectia de afundare la buza: tablierul nu sta la cota drumului, ci cu
    #  mai jos (masurat 0.042 m gol, pana la ~0.17 cu val+autobuz).
    # Fara ea insulitele ieseau la 0.81 fata de tablier la 0.43-0.56, adica prag
    # de 0.25-0.38 — pe muchia contractului de 0.3.
    _EDGE_SAG_M = 0.22
    _top_offset = _QUAY_TOP_M * _QUAY_SY + _EDGE_SAG_M
    # ROTIT 90°, si asta nu e cosmetic: cele doua chei au axele lungi pe
    # DIRECTII OPUSE. `harbour_quay.glb` (Okinawa) e 6,3 pe X si 12,0 pe Z —
    # lung pe Z. `stone_quay.glb` (al nostru) e 12,1 pe X si 3,3 pe Z — lung pe
    # X, fiindca e un modul de chei care se insiruie lateral.
    # Reutilizand rotatia veche, cheiul de 12 m statea DE-A CURMEZISUL
    # drumului: ProbeRace a dat zeci de blocaje la frac 0.10 (masina oprita,
    # "atinge: Plate6"), fata de 3 pe baseline. Garda de ponton nu-l prinsese
    # fiindca ea masoara PRAGUL VERTICAL (0,042 m, trecut) — defectul era pe
    # orizontala.
    # Scara pe Z (adancime) compenseaza cei 3,3 m: insulita trebuie sa acopere
    # latimea tablierului de 12 m.
    add(f"Insulita{k:02d}", "quay",
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(_pa)) + 90.0, 1.0, _QUAY_SY, 3.9)}, "
        f"{g[0]:.2f}, {g[1] - _top_offset:.2f}, {g[2]:.2f})")
    k += 1

# --- VALURILE 2 SI 3: satul, barcile, drumul, vegetatia, belvederea ---------
#
# Asezarea urmeaza POI-urile din brief §2, derivate din `F[...]`, NU fractii
# scrise de mana: cand o latura se redeseneaza, bucla isi schimba lungimea si
# toate fractiile aluneca (memoria `fractia-pe-index-vs-pe-lungime` — rapele
# hardcodate au ramas odata pe cifrele vechi si au urcat repunerile de la
# 0/3/0/4 la 1/13/2/9).
#
# LATERAL: pozitiv = dreapta in sensul de mers. Bucla e ANTIORARA, deci
# dreapta = exteriorul (marea deschisa) pe laturile de vest si sud.

# --- satul plutitor: pe apa, langa cheiul de start (POI A) ------------------
# Casele stau pe APA (cota marii = 0), nu pe teren: `at_road` da cota DRUMULUI,
# deci se foloseste 0.0 explicit. Plutele au originea la baza, deci corpul lor
# intra in apa cu ~0,12 m — exact cat sa nu se vada fundul butoaielor.
_SEA_Y = 0.0
for i, (ff, lat, kind, yaw) in enumerate((
        (F["A chei"] + 0.006, 42.0, "house_a", 18.0),
        (F["A chei"] + 0.013, 55.0, "house_b", -24.0),
        (F["A chei"] + 0.021, 44.0, "house_a", 52.0),
        (F["A chei"] + 0.028, 61.0, "house_b", 8.0),
        # mutata mai la larg: la -0.005/50 m terenul e la +0.58, adica USCAT
        # (masurat cu tools/sv_halong_apa.gd). Restul satului e pe fund de -15.3.
        (F["A chei"] - 0.010, 63.0, "house_b", 71.0),
)):
    g = at_road(ff, lat)
    add(f"CasaPlutitoare{i:02d}", kind,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + yaw, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {_SEA_Y - 0.12:.2f}, {g[2]:.2f})")

# tarcurile de peste: modulare, insiruite pe acelasi aliniament
for i, (ff, lat) in enumerate(((F["A chei"] + 0.009, 72.0),
                               (F["A chei"] + 0.016, 72.0),
                               (F["A chei"] + 0.023, 72.0))):
    g = at_road(ff, lat)
    add(f"TarcPeste{i:02d}", "farm",
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)), 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {_SEA_Y - 0.10:.2f}, {g[2]:.2f})")

# rastelele de plase: pe CHEI (uscat), deci pe cota drumului
for i, (ff, lat, yaw) in enumerate(((F["A chei"] - 0.004, 11.0, 90.0),
                                    (F["A chei"] + 0.003, 12.5, 84.0))):
    g = at_road(ff, lat)
    add(f"RastelPlase{i:02d}", "rack",
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + yaw, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})")

# --- barcile mici: imprastiate pe apa, langa sat si pe golf ----------------
for i, (ff, lat, kind, yaw, sc) in enumerate((
        (F["A chei"] + 0.011, 34.0, "sampan", 62.0, 1.0),
        (F["A chei"] + 0.019, 66.0, "basket", 0.0, 1.0),
        (F["A chei"] + 0.026, 38.0, "basket", 0.0, 1.0),
        # idem: la -0.009/46 m terenul e la +0.68 (uscat)
        (F["A chei"] - 0.018, 68.0, "sampan", -41.0, 1.0),
        (F["C dig"] - 0.014, 48.0, "sampan", 115.0, 1.0),
        (F["C dig"] - 0.021, 39.0, "basket", 0.0, 1.0),
)):
    g = at_road(ff, lat)
    # Barcile au originea la LINIA APEI (--origin=waterline), deci se aseaza
    # EXACT la cota marii: chila e deja sub zero in piesa.
    add(f"BarcaMica{i:02d}", kind,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + yaw, sc, sc, sc)}, "
        f"{g[0]:.2f}, {_SEA_Y:.2f}, {g[2]:.2f})")

# --- grota: gura pe turnul de la POI C -------------------------------------
# Portalul se lipeste de turn, cu spatele plat spre el. Cota: originea la baza,
# deci se aseaza pe cota drumului din dreptul grotei.
# PORTALUL STA LANGA DRUM, NU PESTE EL — si asta e o limita masurata, nu o
# preferinta. Pista are `custom_half_width = 7.0`, deci 14 m de carosabil;
# golul portalului e 8,95 m liberi la cota masinii (contractul brief §1.2,
# verificat pe GLB). 14 nu incap in 8,95. Ca sa incapa ar trebui scalat cu
# 1,56x, adica 18 m inaltime — peste tavanul de 11 m al lui `CameraGrota`.
#
# Asezat initial pe ax (lateral 0.0), ProbeRace a dat 36 de blocaje la frac
# 0.303, toate pe `GuraGrota_col`: montantii cadeau exact in linia de mers.
#
# Brief §1.2 cere de altfel piesa ca GURA de grota cu spatele plat, lipita de
# turn — nu ca poarta prin care trece drumul. Deci sta pe marginea dinspre
# turn (stanga = interiorul buclei pe latura de sud), cu fata spre drum.
# POZITIA: pe FLANCUL turnului `TurnGrota`, nu pe teren gol langa drum.
#
# Piesa a fost refacuta de trei ori si a esuat de fiecare data din acelasi
# motiv, pe care abia a treia captura l-a facut evident:
#   1. cutii            -> citea SOPRON cu acoperis in doua ape;
#   2. un `rock` lat    -> citea DOLMEN (lintel peste doi stalpi);
#   3. mase + cavitate  -> citea CUTIE NEAGRA langa drum.
# Numitorul comun nu e forma, e CONTEXTUL: o gura de pestera nu e un obiect,
# e o GAURA INTR-UN PERETE. Pusa pe teren deschis, i se vad spatele si
# lateralele oricat de bine ar fi modelata, iar cavitatea intunecata devine o
# cutie.
#
# Brief §1.2 spunea asta de la inceput — "spatele piesei e plat, ca sa se
# lipeasca de turn" — adica piesa PRESUPUNE un turn in spate. Eu o asezasem
# la 18 m lateral de drum, la ~41 m de centrul lui `TurnGrota` (raza 32),
# adica exact in afara masivului care ar fi completat-o.
#
# Acum se aseaza pe raza 26 din centrul turnului, pe directia dinspre drum:
# intra in flancul domului, iar spatele plat dispare in el. Distanta pana la
# sosea ramane ~15 m, deci se vede bine fara sa fie obstacol.
# GROTA: AMANATA, NU ASEZATA GRESIT A PATRA OARA.
#
# Piesa `grotto_portal.glb` ramane in kit, verificata (684/700 tri, gol 8,95 m
# liber la cota masinii). Ce nu se rezolva aici e ASEZAREA ei, si merita scris
# de ce, ca sa nu se reia de la zero:
#
# Patru incercari, toate esuate pe acelasi lucru:
#   1. montanti din `box`        -> citea SOPRON cu acoperis in doua ape;
#   2. un `rock` lat de 15 m     -> citea DOLMEN (lintel peste doi stalpi);
#   3. trei mase + cavitate      -> citea CUTIE NEAGRA langa drum;
#   4. idem + un turn in spate   -> tot cutie: turnul nu INCHIDE cavitatea,
#                                   se vede pe langa el.
#
# Cauza nu e modelarea. O gura de pestera nu e un obiect, e o GAURA INTR-UN
# PERETE — si brief §1.2 o spune direct ("spatele piesei e plat, ca sa se
# lipeasca de turn"). Pe pista asta nu exista peretele:
#
#   masurat cu `tools/sv_halong_flanc.gd`, `TurnGrota` e declarat 58 m dar
#   terenul real in jurul lui urca doar la +5,4 m. Cauza e o regula, nu un bug:
#   `_lift_peaks` mascheaza masivele cu banda de protectie a asfaltului
#   (PEAK_ROAD_CLEAR 6 m, PEAK_ROAD_FULL 32 m), ca sa nu creasca un munte peste
#   drum. Turnul fiind langa sosea, e stins aproape complet.
#
# Deci solutia reala e o decizie de PISTA, nu de kit, si sunt doua:
#   (a) gaura se sapa IN teren — `CliffFace` sau `TerrainHollow` dau perete
#       adevarat, in care portalul devine incadrarea gurii;
#   (b) grota devine tunel prin care chiar treci — dar atunci golul trebuie sa
#       acopere cei 14 m de carosabil, nu 8,95, deci e alta piesa si alt
#       contract (la scara 1,56x portalul ar avea 18 m, peste tavanul de 11 m
#       al lui `CameraGrota`).
#
# Pana la decizia aia, POI-ul C ramane cu digul si cu turnurile din jur, care
# sunt curate. `CameraGrota` ramane in scena si nu strica nimic: fara piesa,
# zona e doar un coridor intre turnuri.

# --- digul de piatra: marginea dinspre mare, pe latura de sud (POI C) ------
# Module de 8 m insiruite pe fractii egale. Numarul vine din LUNGIME, nu ghicit.
_DIKE_FROM, _DIKE_TO = F["C dig"] - 0.030, F["C dig"] + 0.085
_dike_len = ((_DIKE_TO - _DIKE_FROM) % 1.0) * L_TOTAL
_n_dike = max(2, int(_dike_len / 8.0))
for i in range(_n_dike):
    ff = _DIKE_FROM + (_DIKE_TO - _DIKE_FROM) * (i + 0.5) / _n_dike
    # 14,5 m lateral, nu 10,5: digul are 8 m modul si ~2,6 m adancime, deci
    # la 10,5 marginea lui ajungea la 4,7 m de ax — SUB semi-latimea de 7 m,
    # adica pe asfalt (masurat cu tools/sv_halong_gabarit.gd). Distanta se
    # masoara pe GABARIT, nu pe origine.
    g = at_road(ff, 14.5)
    add(f"Dig{i:02d}", "dike",
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + 90.0, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {g[1] - 0.55:.2f}, {g[2]:.2f})")

# --- POI C: turnuri mici, moloz la baza, vegetatie de mal (gauntlet) --------
# Bara: drum pe zid de piatra, turnuri care intra in apa cu o nisa, bolovani la
# poale, smocuri de verde. Digul de mai sus acopera acum toata zona (pana in
# dreptul grotei). Grota ramane decizie deschisa — aici nu se construieste.
# Distantele sunt pe GABARIT: un turn la scara s are ~5*s m raza, deci laterala
# = raza + 14,5 (dig) + rezerva, nu "cat sa para aproape".
_C0, _C1 = F["C dig"] - 0.010, F["C dig"] + 0.100
# 1) turnuri mici in apa, pe dreapta (spre larg), dincolo de dig
for i, (dff, lat, sc, nm) in enumerate((
        (0.008, 27.0, 1.25, "stack_b"), (0.026, 31.0, 1.55, "stack_a"),
        (0.046, 26.0, 1.15, "stack_b"), (0.062, 33.0, 1.6, "stack_a"),
        (0.080, 28.0, 1.3, "stack_b"), (0.097, 30.0, 1.5, "stack_a"))):
    ff = F["C dig"] + dff
    g = at_road(ff, lat)
    _su = sc * (0.72 if nm == "stack_a" else 0.95)
    add(f"TurnC{i:02d}", nm,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + i * 41.0, _su, _su, _su)}, "
        f"{g[0]:.2f}, {g[1] - 1.20:.2f}, {g[2]:.2f})")
    # inel de moloz la baza (shore_boulder) — "stanca mancata"
    for q in range(3):
        a = math.radians(i * 37.0 + q * 125.0)
        rr = 4.2 * sc ** 0.5 + 1.0
        ox, oz = math.cos(a) * rr, math.sin(a) * rr
        bs = 0.9 + 0.25 * ((i + q) % 3)
        add(f"BolovanC{i}{q}", "boulder",
            f"Transform3D({rot_y_s(i * 53.0 + q * 71.0, bs, bs, bs)}, "
            f"{g[0] + ox:.2f}, {_SEA_Y - 0.15:.2f}, {g[2] + oz:.2f})")
# 2) bolovani la poalele digului, pe latura apei (lateral 17-19)
for i in range(16):
    ff = _C0 + (_C1 - _C0) * (i + 0.5) / 16.0
    lat = 17.0 + 1.6 * ((i * 5) % 3)
    bs = 0.9 + 0.3 * ((i * 7) % 4) / 3.0
    g = at_road(ff, lat)
    add(f"BolovanDigC{i:02d}", "boulder",
        f"Transform3D({rot_y_s(i * 67.0, bs, bs, bs)}, {g[0]:.2f}, {_SEA_Y - 0.15:.2f}, {g[2]:.2f})")
# 3) vegetatie de mal pe interior (stanga): smocuri si ficusi in 2 randuri
for i in range(26):
    ff = _C0 + (_C1 - _C0) * (i + 0.5) / 26.0
    rand = i % 2
    lat = -(11.5 + rand * 6.5 + 2.0 * ((i * 3) % 4) / 3.0)
    kind = ("scrub", "ficus_a", "bamboo", "scrub", "ficus_b", "scrub")[i % 6]
    g = at_road(ff, lat)
    add(f"VegC{i:02d}", kind,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + i * 59.0, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {g[1] - 0.15:.2f}, {g[2]:.2f})")

# --- BANDA DE JOS PESTE GURA GOLFULUI + MAREEA (brief §3, §7.3) --------------
# Scurtatura TAIE COARDA peste gura golfului: drumul ocoleste 228 m spre uscat,
# banda trece direct 163 m (-28.4%, tinta Monument Valley). E la nivelul apei
# (cote 1.38-1.79), deci o terasa de maree sta acolo credibil — ceea ce NU era
# posibil pe latura dreapta de dinainte.
#
# COTA SE RACORDEAZA LA CAPETE: `TrackBranch` citeste capetele de pe bucla
# PRINCIPALA (antetul clasei: "capetele nu se deseneaza"), deci o banda
# coborata uniform ar lasa o treapta egala cu toata coborarea la ambele
# jonctiuni — de patru ori limita de 0.3 m (memoria
# `banda-coborata-uniform-lasa-treapta`). Profilul de coborare e `4u(1-u)`:
# zero la capete, maxim la mijloc. Acelasi profil il are si bombarea.
#
# Calculul sta AICI, inaintea header-ului de scena: in `.tscn` toate
# `[sub_resource]` vin INAINTEA primului `[node]`, altfel parserul da
# "Unknown tag 'sub_resource' in file" si scena nu se incarca deloc.
BR_F0, BR_F1 = 0.8555, 0.9653
_BR_DROP = 0.0          # banda e PE COTA DRUMULUI, nu sub ea. Vezi mai jos.
# BANDA NU POATE AVEA COTA PROPRIE, si asta e un contract intre doua sisteme,
# masurat pe doua garzi diferite:
#
#  1. `ProbeLaneClear` — DECISIVA. `TrackSideSampler._carve_branches` sapa
#     terenul la cota benzii minus `BRANCH_DROP` (0.25 m), dar la CAPETE
#     `TrackBranch` racordeaza la cota buclei principale, deci terenul ramane
#     sus si blocheaza intrarea. Baleiat:
#       _BR_DROP 0.00 ->  1 blocaj (jonca, pe ruta principala — nu banda)
#       _BR_DROP 0.25 -> 17 blocaje (TerrainBody in fata, la 0.09-5.3 m)
#       _BR_DROP 0.45 -> 13 blocaje
#     Adica ORICE coborare blocheaza capetele benzii. Terasa de abraziune
#     "scufundata" nu se poate face asa; daca o vrem, cere sapatura proprie
#     (`custom_hollows`) sau o rapa, nu o cota de banda.
#
#  2. `ProbeCameraSolid` — a doua constrangere, mai permisiva (0.7 m era inca
#     bine): pe o banda prea coborata camera INTRA IN MASINA, si sonda
#     raporteaza collider "Car", nu un perete (memoria
#     banda-coborata-ingroapa-camera). Baleiat: 0.0-0.7 -> 0 incidente,
#     0.85/1.0 -> 1. Sonda aia E determinista, altfel decat ProbeRace.
#
# Cu 0.0 banda ramane o scurtatura de -32.8% pe acelasi plan ca drumul, iar
# mareea o uda si o inchide la fel de bine: gimmickul nu depinde de cota.
_BR_BOW = 10.0         # bombare spre apa la mijloc (m), ca sa nu fie o rigla
_br_a = at_road(BR_F0)
_br_b = at_road(BR_F1)
_cdx, _cdz = _br_b[0] - _br_a[0], _br_b[2] - _br_a[2]
_clen = math.hypot(_cdx, _cdz) or 1.0
# Normala la coarda, orientata spre AFARA golfului (spre sud/apa): golful intra
# spre nord, deci bombarea merge in sensul opus fundului.
_cnx, _cnz = _cdz / _clen, -_cdx / _clen
_gulf = at_road(frac["G golf fund"])
if ((_gulf[0] - _br_a[0]) * _cnx + (_gulf[2] - _br_a[2]) * _cnz) > 0.0:
    _cnx, _cnz = -_cnx, -_cnz
_br_pts = []
for _j in range(5):
    _u = (_j + 0.5) / 5.0
    _shape = 4.0 * _u * (1.0 - _u)      # zero la capete, 1.0 la mijloc
    _br_pts.append((_br_a[0] + _cdx * _u + _cnx * _BR_BOW * _shape,
                    _br_a[1] + (_br_b[1] - _br_a[1]) * _u - _BR_DROP * _shape,
                    _br_a[2] + _cdz * _u + _cnz * _BR_BOW * _shape))
_br_origin = _br_pts[0]
_br_local = [(p[0] - _br_origin[0], p[1] - _br_origin[1], p[2] - _br_origin[2])
             for p in _br_pts]
# Mareea sta la MIJLOCUL benzii, pe cota ei reala (acolo coborarea e maxima).
_tide_mid = (_br_a[0] + _cdx * 0.5 + _cnx * _BR_BOW,
             (_br_a[1] + _br_b[1]) * 0.5 - _BR_DROP,
             _br_a[2] + _cdz * 0.5 + _cnz * _BR_BOW)
_tide_yaw = yaw_z_to(_cdx / _clen, _cdz / _clen)
print(f"\n  banda de jos: {BR_F0:.4f} -> {BR_F1:.4f}, coarda {_clen:.1f} m")

# Polilinia benzii de jos (capete + puncte coapte), in coordonate Godot, pentru
# garda turnurilor POI G: banda taie coarda peste golf, adica prin INTERIORUL
# viraturii unde stau turnurile de pe stanga. ProbeRace: AI-ul ia banda si da
# in hull-urile turnurilor (blocaje cu `TurnCalcarG00_col`, `G13_col`).
_BANDA_POLY = [(_br_a[0], _br_a[2])] + [(q[0], q[2]) for q in _br_pts] + [(_br_b[0], _br_b[2])]


def _d_banda(x, z):
    best = 1e9
    for (x1, z1), (x2, z2) in zip(_BANDA_POLY, _BANDA_POLY[1:]):
        dx, dz = x2 - x1, z2 - z1
        t = max(0.0, min(1.0, ((x - x1) * dx + (z - z1) * dz) / max(1e-9, dx * dx + dz * dz)))
        best = min(best, math.hypot(x - (x1 + dx * t), z - (z1 + dz * t)))
    return best


# --- POI G: soseaua taiata in peretele de calcar (0,84 -> 0,98) ------------
# Bara: perete de calcar lipit de sosea, vegetatie agatata pe el, parapet cu
# maimute. Peretele NU vine din relief (`_lift_peaks` stinge masivele langa
# sosea), deci se construieste din turnuri karst_tower_* LIPITE si scalate.
# Distanta se da pe GABARIT: centrul = semilatime + 2,5 m + raza bazei, ca
# marginea turnului sa stea la ~9,5 m de ax (prag garda 8,0; semilatime 7,0).
_G0, _G1 = F["G golf E"] + 0.004, F["G golf V"] + 0.012
_g_len = ((_G1 - _G0) % 1.0) * L_TOTAL
# (semi-extindere AABB MASURATA pe GLB: 18.2 / 16.9 / 25.0 m, inaltime, raza
#  mijloc). Garda de gabarit se uita la colturile AABB-ului, nu la raza nominala.
_TW = {"tower_a": (18.2, 55.0, 16.0), "tower_b": (16.9, 45.0, 16.0),
       "tower_c": (25.0, 65.0, 18.0)}
_AGAT = {}
_SINK = {}     # cat intra turnul in sol: ascunde poala rugina de apa (nisa)
_n_tw = max(4, int(_g_len / 15.0))
_NOTW = os.environ.get('HLG_NOTW')
for i in range(_n_tw):
    ff = _G0 + (_G1 - _G0) * (i + 0.5) / _n_tw
    kind = ("tower_a", "tower_b")[i % 2]
    rb, hh, rm = _TW[kind]
    sc = (0.42, 0.50, 0.38, 0.46, 0.52)[(i * 3) % 5]
    lat = -(9.4 + 1.2 * rb * sc * (1.0 + 0.04 * ((i * 7) % 3)))
    # CURVA: lat se masoara perpendicular pe tangenta, dar in viraj (fileturi de
    # 44-48 m) interiorul se strange spre bucla inainte/inapoi, iar colizorul
    # convex al turnului ajunge la ~3 m de asfalt (ProbeRace: 2 blocaje la
    # 0,869 cu turnul 00 la 17,7 m perpendicular). Distanta se verifica pe TOATE
    # punctele buclei: turnul se departeaza pana ce hull-ul (raza rb*sc) ramane
    # la >= 9,5 m de orice punct de ax; daca nu incape, se omite.
    _r_hull = rb * sc
    _ok = False
    for _extra_lat in range(0, 16):
        g = at_road(ff, lat - _extra_lat * 1.0)
        if (min(math.hypot(g[0] - q[0], g[2] + q[1]) for q in rs) >= _r_hull + 15.0
                and _d_banda(g[0], g[2]) >= _r_hull + 12.0):
            lat = lat - _extra_lat * 1.0
            _ok = True
            break
    if not _ok:
        continue
    gr = at_road(ff, 0.0)
    if _NOTW:
        continue
    nm = f"TurnCalcarG{i:02d}"
    _sink = 4.2 * sc
    _SINK[nm] = _sink
    add(nm, kind,
        f"Transform3D({rot_y_s(round(yaw_z_to(*travel_g(ff)) / 90.0) * 90.0 + (i % 2) * 180.0, sc, sc, sc)}, {g[0]:.2f}, {g[1] - _sink:.2f}, {g[2]:.2f})")
    # vegetatie AGATATA pe fata dinspre sosea: 2 smocuri la 25% si 50% din
    # inaltime, pe raza ~0,85 din cea de la mijloc, spre ax.
    dx, dz = gr[0] - g[0], gr[2] - g[2]
    dl = math.hypot(dx, dz) or 1.0
    for q, (hf, akind) in enumerate(((0.22, "scrub"), (0.42, "ficus_b"), (0.64, "ficus_a"))):
        rr = rm * sc * (0.80, 0.86, 0.90)[q]
        ax_, az_ = g[0] + dx / dl * rr, g[2] + dz / dl * rr
        an = f"AgatG{i:02d}{q}"
        _AGAT[an] = (nm, hh * sc * hf - _sink)
        add(an, akind,
            f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + q * 90.0 + i * 31.0, 2.3, 2.3, 2.3)}, "
            f"{ax_:.2f}, {g[1] + hh * sc * hf - _sink:.2f}, {az_:.2f})")
# smocuri la piciorul peretelui, intre sosea si turn (cresc pe sol: Veg*)
for i in range(_n_tw * 2):
    ff = _G0 + (_G1 - _G0) * (i + 0.5) / (_n_tw * 2)
    kind = ("scrub", "bamboo", "scrub", "ficus_a")[i % 4]
    lat = -(14.8 + 1.2 * ((i * 5) % 3))
    g = at_road(ff, lat)
    # nu pe banda de jos: trunchiul ficusului e solid (ProbeRace: ejectare la
    # 35 m/s in VegGP01, la 2,4 m de banda)
    if _d_banda(g[0], g[2]) < 13.0:
        continue
    add(f"VegGP{i:02d}", kind,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + i * 47.0, 1.4, 1.4, 1.4)}, "
        f"{g[0]:.2f}, {g[1] - 0.15:.2f}, {g[2]:.2f})")

# --- parapetul de coasta: pe latura unde stau maimutele (POI G) ------------
# Maimutele sar DIN perete, iar parapetul e cel pe care stau (brief §1.5), deci
# se insiruie in jurul fractiei lor, pe partea dinspre perete (stanga = -lat).
_PAR_FROM, _PAR_TO = F_MAIMUTE - 0.022, F_MAIMUTE + 0.022
_par_len = ((_PAR_TO - _PAR_FROM) % 1.0) * L_TOTAL
_n_par = max(2, int(_par_len / 6.0))
for i in range(_n_par):
    ff = _PAR_FROM + (_PAR_TO - _PAR_FROM) * (i + 0.5) / _n_par
    # -11,5, nu -9,5: parapetul are 0,55 m coama plus talus, deci la -9,5
    # marginea ajungea la 6,4-7,0 m de ax, adica PE asfalt (semi-latime 7,0).
    # Un parapet MARGINESTE drumul, nu sta in el.
    g = at_road(ff, -12.2)
    add(f"Parapet{i:02d}", "parapet",
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + 90.0, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {g[1] - 0.10:.2f}, {g[2]:.2f})")

# --- belvederea: reperul construit de pe varf (POI D) ----------------------
# "Belvedere nu am stiut unde este" a fost verdictul la volan; pavilionul e
# raspunsul (brief §1.7). Sta pe partea dinspre priveliste, langa CameraZone.
_g = at_road(F["D belvedere"], -16.0)   # gabaritul lui ajungea la 7,7 m de ax
add("PavilionBelvedere", "pavilion",
    f"Transform3D({rot_y_s(yaw_z_to(*travel_g(F['D belvedere'])) + 90.0, 1.0, 1.0, 1.0)}, "
    f"{_g[0]:.2f}, {_g[1] - 0.20:.2f}, {_g[2]:.2f})")

# --- vegetatia: ficusi si bambus pe urcarea spre belvedere (POI D) --------
# Pe malul dinspre interior (stanga), unde e versantul. Alternanta determinista.
_veg = []
# DENSITATEA vine din bugetul MASURAT, nu din prudenta.
#
# `tools/ProbePerf.tscn --track=14 --mobile` da pe Ha Long 41 de desene in
# medie (varf 78) si 0,22 ms GPU. Pentru comparatie, pe aceeasi sonda:
# Track08 1088 (varf 2194), Track09 760, Track10 553, Track02 506. Deci pista
# desena de ~13-26 de ori mai putin decat cele deja livrate, pe acelasi buget
# de 16,6 ms/cadru.
#
# Cifra aia nu e un merit, e un semnal ca versantul era GOL. 14 piese pe toata
# urcarea insemna una la ~20 m, adica o planta razleata din cand in cand, nu un
# versant de carst. Acum 34, pe trei randuri de departare, cu varietate pe
# specie si pe latura — si tot ramane cu un ordin de marime sub celelalte piste.
for i in range(34):
    u = (i + 0.5) / 34.0
    ff = F["D urcare"] + (F["D creasta"] - F["D urcare"]) * u
    side = -1.0 if i % 3 != 1 else 1.0
    # trei randuri: aproape de drum, mijloc, departe. Randul departat e mai
    # rar, ca silueta sa nu devina un zid verde.
    rand = i % 3
    # 12,0 de baza, nu 10,0: ficusii au coroana de ~1,6 m raza, deci la 10
    # marginea cadea la 6,9-8,0 m de ax.
    lat = side * (12.0 + rand * 7.5 + 3.0 * ((i * 7) % 4) / 3.0)
    kind = ("ficus_a", "bamboo", "ficus_b", "bamboo",
            "ficus_a", "scrub")[i % 6]
    _veg.append((ff, lat, kind, i * 47.0))
# tufe pe creasta, in jurul belvederei
for i in range(14):
    u = (i + 0.5) / 14.0
    ff = F["D creasta"] + (F["D varf"] - F["D creasta"]) * u
    # 11,5 de baza, nu 9,0: la 9,0 fiecare al patrulea exemplar cadea exact
    # pe pragul de gabarit si coroana ajungea la 6,9 m de ax.
    _veg.append((ff, (-1.0 if i % 2 else 1.0) * (11.5 + 4.0 * (i % 4)),
                 "scrub" if i % 3 else "ficus_b", i * 61.0))
# vegetatie si pe coasta de nord, langa parapet (POI G): maimutele stau
# intr-un loc cu copaci, nu pe un parapet intr-un desert.
for i in range(12):
    u = (i + 0.5) / 12.0
    ff = F_MAIMUTE - 0.020 + 0.040 * u
    # 15,5 de baza: la 13 coroanele ajungeau la 6,9-8,0 m de ax. Si aici
    # distanta se da pe GABARIT, nu pe origine.
    _veg.append((ff, -(15.5 + 6.0 * (i % 3)),
                 ("ficus_b", "bamboo", "ficus_a")[i % 3], i * 83.0))
for i, (ff, lat, kind, yaw) in enumerate(_veg):
    g = at_road(ff, lat)
    add(f"Veg{i:02d}", kind,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + yaw, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {g[1] - 0.15:.2f}, {g[2]:.2f})")


# --- POI E: coborarea in doua ace de par + plaja (0,53 -> 0,74) ------------
# Construit ca UNITATE (gauntlet): versant imbracat pe ambele randuri, stanci
# in petice la acele de par, plaja cu bolovani si barci trase la mal. Toate
# fractiile vin din F[...]; cotele de sol le masoara SvHalongCote.
_F_E_VEG_END = F['E plaja'] - 0.015
_E0, _E1 = F["D varf"] + 0.006, F["E iesire"] + 0.004
_E_PLAJA = F["E plaja"]
_ev = []
# 1) versantul: 3 randuri de departare, ambele laturi, pana la plaja.
_n_ev = 40
for i in range(_n_ev):
    u = (i + 0.5) / _n_ev
    ff = _E0 + (_F_E_VEG_END - _E0) * u
    side = -1.0 if i % 2 == 0 else 1.0
    rand = (i // 2) % 3
    lat = side * (12.5 + rand * 7.0 + 2.5 * ((i * 5) % 4) / 3.0)
    kind = ("ficus_a", "bamboo", "scrub", "ficus_b", "bamboo", "scrub")[i % 6]
    _ev.append((f"VegE{i:02d}", ff, lat, kind, i * 53.0, 1.0))
# 2) tufe dese pe marginea de cale la ace (un smoc de verde la fiecare cot)
for j, fa in enumerate((F["E ac1b"], F["E ac2b"])):
    for q in range(6):
        ff = fa + (q - 2.5) * 0.0035
        side = 1.0 if q % 2 else -1.0
        _ev.append((f"VegEAc{j}{q}", ff, side * (11.0 + 2.0 * (q % 3)),
                    "scrub" if q % 2 else "ficus_b", q * 71.0 + j * 17.0, 1.0))
for nm_, ff_, lat_, kind_, yaw_, sc_ in _ev:
    g = at_road(ff_, lat_)
    add(nm_, kind_,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff_)) + yaw_, sc_, sc_, sc_)}, "
        f"{g[0]:.2f}, {g[1] - 0.15:.2f}, {g[2]:.2f})")
# 3) stanci in petice (bolovani) pe versant, la ace si pe plaja
for i, (ff, lat, sc) in enumerate((
        (F["E ac1a"] - 0.006, 15.0, 1.3), (F["E ac1a"] + 0.010, -16.0, 1.6),
        (F["E ac1b"] + 0.006, 17.0, 1.4), (F["E ac2a"] - 0.008, -15.0, 1.5),
        (F["E ac2a"] + 0.008, 16.0, 1.2), (F["E ac2b"] + 0.007, -17.0, 1.6),
        (_E_PLAJA - 0.020, 14.0, 1.3), (_E_PLAJA - 0.012, -15.0, 1.5),
        (_E_PLAJA - 0.004, 16.0, 1.8), (_E_PLAJA + 0.004, -14.5, 1.4),
        (_E_PLAJA + 0.012, 15.0, 1.6), (_E_PLAJA + 0.020, -16.0, 1.3),
        (_E_PLAJA + 0.028, 15.5, 1.7))):
    g = at_road(ff, lat)
    add(f"BolovanE{i:02d}", "boulder",
        f"Transform3D({rot_y_s(i * 61.0, sc, sc, sc)}, {g[0]:.2f}, {g[1] - 0.10:.2f}, {g[2]:.2f})")
# 4) plaja: barci trase la mal, rastel de plase, ficusi la marginea nisipului
for i, (ff, lat, kind, yaw) in enumerate((
        (_E_PLAJA - 0.008, 19.0, "sampan", 80.0), (_E_PLAJA + 0.002, 21.0, "basket", 0.0),
        (_E_PLAJA + 0.014, 20.0, "sampan", 100.0), (_E_PLAJA + 0.022, 19.5, "basket", 0.0))):
    g = at_road(ff, lat)
    add(f"BarcaPlajaE{i:02d}", kind,
        f"Transform3D({rot_y_s(yaw_z_to(*travel_g(ff)) + yaw, 1.0, 1.0, 1.0)}, "
        f"{g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})")
g = at_road(_E_PLAJA + 0.008, 13.0)
add("RastelPlajaE00", "rack",
    f"Transform3D({rot_y_s(yaw_z_to(*travel_g(_E_PLAJA + 0.008)) + 90.0, 1.0, 1.0, 1.0)}, "
    f"{g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f})")

# --- COTELE DE PE USCAT, MASURATE PE TERENUL REAL ---------------------------
#
# Generatorul stie doar DRUMUL: `at_road(f, lat)` da cota soselei. Pe apa e
# exact ce trebuie (turnul intra in mare la -1,20 fata de drum). Pe uscat nu:
# acolo unde un `TerrainPeak` ridica solul peste drum, aceeasi formula ingroapa
# piesa, iar acolo unde terenul coboara (rapa de golf), o lasa in aer.
#
# Masurat pe Track22 cu `tools/sv_halong_cote.gd`: 4 turnuri ingropate cu
# 0,88-0,97 m si 16 piese plutind, una la 12,55 m in aer.
#
# DE CE NU RECALCULEZ AICI: `TrackSideSampler._lift_peaks` combina domul
# masivului prin `_smax` NETED, adauga zgomot de dune si mascheaza tot cu banda
# de protectie a asfaltului. Reimplementata in Python, formula ar diverge tacut
# de cea din joc la prima schimbare — exact tiparul din memoria
# `justificarea-din-comentariu-se-verifica`. Asa, cifra vine din `ground_y()`,
# adica din terenul pe care se conduce efectiv.
#
# FLUXUL, cand se muta ceva pe uscat:
#   1. ruleaza generatorul (cotele vechi raman pentru nodurile nemutate);
#   2. godot --headless --path . res://tools/SvHalongCote.tscn
#      > tools/halong_cote_teren.txt   (doar liniile `COTA`);
#   3. ruleaza generatorul din nou — citeste fisierul si corecteaza.
# Sonda e si garda: `VERDICT: OK` doar cand nimic nu mai e ingropat sau plutind.
COTE_TEREN = {}
_cote_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "halong_cote_teren.txt")
if os.path.isfile(_cote_path):
    with open(_cote_path, encoding="utf-8") as _fh:
        for _ln in _fh:
            _parts = _ln.split()
            if len(_parts) == 3 and _parts[0] == "COTA":
                COTE_TEREN[_parts[1]] = float(_parts[2])

# VEGETATIA DE PESTE APA SE SCOATE, nu se coboara.
#
# Un copac nu e ancorat de linia apei — daca terenul sub el e sub cota marii,
# piesa trebuie sa DISPARA, nu sa primeasca o cota. Masurat pe scena
# integrata: 20 de `Veg*` din POI D stateau peste apa, unele la -11 m, cu
# trunchiul intrand drept in mare. Se vede in videoul de pe telefon, iar garda
# veche le sarea (linia `if gy < sea_y - 1.0: continue` presupunea ca orice
# piesa de peste apa adanca e o barca).
#
# Randurile exterioare ale versantului (rand 1 si 2) ajung la 27 m lateral; pe
# o pista jumatate pe apa, atat trece de mal in golf. Nu se ingusteaza randul
# (s-ar rari versantul exact unde bara cere sa fie imbracat) — se scot doar
# pozitiile care cad in apa, iar restul raman.
#
# Cota marii in lume e 0,00 (`SEA_OFFSET` e calculat ca sa iasa asa, vezi
# garda de apa de mai sus), deci pragul e 0,05 m peste ea.
_SEA_LEVEL_WORLD = 0.0
_VEG_MIN_GROUND = _SEA_LEVEL_WORLD + 0.05
if COTE_TEREN:
    _scoase = []
    for _nm, _res, _xf, _extra in list(dec):
        if not _nm.startswith("Veg"):
            continue
        _gy = COTE_TEREN.get(_nm)
        if _gy is not None and _gy < _VEG_MIN_GROUND:
            _scoase.append((_nm, _gy))
    if _scoase:
        _rele = {n for n, _ in _scoase}
        dec[:] = [d for d in dec if d[0] not in _rele]
        print("\nvegetatie scoasa de pe apa: %d piese" % len(_scoase))
        for _n, _g in _scoase[:6]:
            print("   %-10s teren %+6.2f" % (_n, _g))
        if len(_scoase) > 6:
            print("   ... si inca %d" % (len(_scoase) - 6))

if COTE_TEREN:
    _fixed = 0
    for _i, (_nm, _res, _xf, _extra) in enumerate(dec):
        if _nm not in COTE_TEREN:
            continue
        # Transform3D(b0..b8, ox, oy, oz) -> se rescrie doar oy.
        # Transform3D(b0..b8, ox, oy, oz): ultimele trei valori sunt pozitia,
        # deci `oy` e penultima. Se rescrie DOAR ea.
        _head, _oy, _oz = _xf.rsplit(",", 2)
        dec[_i] = (_nm, _res,
                   f"{_head}, {COTE_TEREN[_nm]:.2f},{_oz}", _extra)
        _fixed += 1
    print(f"\ncote de teren aplicate: {_fixed} din {len(COTE_TEREN)} masurate")

if COTE_TEREN:
    for _i, (_nm, _res, _xf, _extra) in enumerate(dec):
        if _nm in _SINK and _nm in COTE_TEREN:
            _head, _oy, _oz = _xf.rsplit(",", 2)
            dec[_i] = (_nm, _res, f"{_head}, {COTE_TEREN[_nm] - _SINK[_nm]:.2f},{_oz}", _extra)
    for _i, (_nm, _res, _xf, _extra) in enumerate(dec):
        if _nm in _AGAT and _AGAT[_nm][0] in COTE_TEREN:
            _head, _oy, _oz = _xf.rsplit(",", 2)
            dec[_i] = (_nm, _res,
                       f"{_head}, {COTE_TEREN[_AGAT[_nm][0]] + _AGAT[_nm][1]:.2f},{_oz}", _extra)

RES = {"rock": "13_rock", "quay": "14_quay",
       "stack_a": "20_stack_a", "stack_b": "21_stack_b",
       "house_a": "22_house_a", "house_b": "23_house_b",
       "farm": "24_farm", "rack": "25_rack",
       "sampan": "26_sampan", "basket": "27_basket",
       "parapet": "29_parapet",
       "dike": "30_dike", "pavilion": "31_pavilion",
       "ficus_a": "32_ficus_a", "ficus_b": "33_ficus_b",
       "bamboo": "34_bamboo", "scrub": "35_scrub",
       "boulder": "36_boulder",
       "tower_a": "40_tower_a", "tower_b": "41_tower_b", "tower_c": "42_tower_c"}

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
[ext_resource type="Script" path="res://scenes/hazards/pontoon_road_hazard.gd" id="8_pont"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="16_branch"]
[ext_resource type="Script" path="res://scenes/hazards/camera_zone.gd" id="18_camzone"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_hollow.gd" id="19_hollow"]
[ext_resource type="Script" path="res://scenes/hazards/tide_hazard.gd" id="17_tide"]
[ext_resource type="Script" uid="uid://twspgftscxb4" path="res://scenes/props/world_prop.gd" id="9_prop"]
[ext_resource type="PackedScene" path="res://assets/models/halong/rocks/karst_stack_a.glb" id="20_stack_a"]
[ext_resource type="PackedScene" path="res://assets/models/halong/rocks/karst_stack_b.glb" id="21_stack_b"]
[ext_resource type="PackedScene" path="res://assets/models/halong/structures/stone_quay.glb" id="14_quay"]
[ext_resource type="PackedScene" path="res://assets/models/halong/vehicles/fishing_junk.glb" id="15_boat"]
[ext_resource type="PackedScene" path="res://assets/models/halong/buildings/floating_house_a.glb" id="22_house_a"]
[ext_resource type="PackedScene" path="res://assets/models/halong/buildings/floating_house_b.glb" id="23_house_b"]
[ext_resource type="PackedScene" path="res://assets/models/halong/structures/fish_farm.glb" id="24_farm"]
[ext_resource type="PackedScene" path="res://assets/models/halong/props/net_drying_rack.glb" id="25_rack"]
[ext_resource type="PackedScene" path="res://assets/models/halong/vehicles/sampan_a.glb" id="26_sampan"]
[ext_resource type="PackedScene" path="res://assets/models/halong/vehicles/basket_boat.glb" id="27_basket"]
[ext_resource type="PackedScene" path="res://assets/models/halong/structures/coast_parapet.glb" id="29_parapet"]
[ext_resource type="PackedScene" path="res://assets/models/halong/structures/stone_dike.glb" id="30_dike"]
[ext_resource type="PackedScene" path="res://assets/models/halong/structures/belvedere_pavilion.glb" id="31_pavilion"]
[ext_resource type="PackedScene" path="res://assets/models/halong/plants/karst_ficus_a.glb" id="32_ficus_a"]
[ext_resource type="PackedScene" path="res://assets/models/halong/plants/karst_ficus_b.glb" id="33_ficus_b"]
[ext_resource type="PackedScene" path="res://assets/models/halong/plants/bamboo_clump.glb" id="34_bamboo"]
[ext_resource type="PackedScene" path="res://assets/models/halong/plants/scrub_tuft.glb" id="35_scrub"]
[ext_resource type="PackedScene" path="res://assets/models/halong/rocks/shore_boulder.glb" id="36_boulder"]
[ext_resource type="PackedScene" path="res://assets/models/halong/rocks/karst_tower_a.glb" id="40_tower_a"]
[ext_resource type="PackedScene" path="res://assets/models/halong/rocks/karst_tower_b.glb" id="41_tower_b"]
[ext_resource type="PackedScene" path="res://assets/models/halong/rocks/karst_tower_c.glb" id="42_tower_c"]

[sub_resource type="Curve3D" id="Curve3D_main"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_banda"]
_data = {{
"points": {pva(_br_local)},
"tilts": PackedFloat32Array({", ".join("0" for _ in _br_local)})
}}
point_count = {len(_br_local)}

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
# --- SCOBITURILE care fac GOLFUL din interiorul buclei ----------------------
# Fara ele, interiorul e o masa continua de teren si pista citeste „drum in
# jurul unei platforme", nu „golf cu turnuri" (brief §0.1). Cauza e in
# `TrackSideSampler.ground_y`: terenul URMEAZA soseaua, deci interiorul sta la
# cota drumului minus putin — adica ~+5 m, bine peste apa de la 0.00.
# `TerrainPeak` ridica local, dar nu sapa nimic intre varfuri.
#
# `TerrainHollow` e perechea pe MINUS: coboara terenul la cota NODULUI pe raza
# ceruta, cu o palnie de `wall_m` dincolo de ea. Puse sub 0, lasa apa sa intre.
HOLLOWS = [
    # (nume, (x, y, z), raza, perete) — y NEGATIV: fundul golfului.
    ("GolfNord", (-150.0, -12.0, 40.0), 95.0, 45.0),
    ("GolfCentru", (-60.0, -10.0, -140.0), 85.0, 40.0),
    ("GolfSud", (10.0, -11.0, 170.0), 80.0, 40.0),
]
tscn += """
[node name="Hollows" type="Node3D" parent="."]
"""
for nm, (hx, hy, hz), hrad, hwall in HOLLOWS:
    tscn += f"""
[node name="{nm}" type="Marker3D" parent="Hollows"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hx:.2f}, {hy:.2f}, {hz:.2f})
gizmo_extents = {hrad}
script = ExtResource("19_hollow")
radius_m = {hrad}
wall_m = {hwall}
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
model_scale = {JONCA_SCALE}
face_travel = true
motion = 1
sweep_speed = {JONCA_SWEEP}

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
animal_model = "res://assets/models/halong/animals/macaque.glb"
alt_model = "res://assets/models/halong/animals/macaque.glb"
no_body_radius = 7.0
body_reach = 14.0

"""

# --- PONTOANELE: semnatura pistei (brief §3) ---------------------------------
# Un nod `PontoonRoadHazard` per tronson, pus PE mijlocul lui, cu capetele date
# ca `near_end`/`far_end` LOCAL. `Track._resolve_span_holes` taie carosabilul
# pe `road_hole_span()` metri centrati pe nod (contract prin duck-typing:
# `has_method("road_hole_span")`, deci pontonul e recunoscut fara sa fie
# subclasa podului — vezi antetul clasei).
#
# FAZA VALULUI e diferita pe fiecare tronson: trei pontoane cu aceeasi faza
# s-ar legana la unison si ar citi „mecanism", nu „apa" (aceeasi regula ca
# `phase` la SlidingHazard).
for _i, (_a, _b) in enumerate(PONT_SEGS):
    _mid = (_a + _b) * 0.5
    _g_mid = at_road(_mid)
    _g_a = at_road(_a)
    _g_b = at_road(_b)
    _span = ((_b - _a) % 1.0) * L_TOTAL
    # near/far LOCAL fata de nod (nodul e la mijloc).
    _near = (_g_a[0] - _g_mid[0], _g_a[1] - _g_mid[1], _g_a[2] - _g_mid[2])
    _far = (_g_b[0] - _g_mid[0], _g_b[1] - _g_mid[1], _g_b[2] - _g_mid[2])
    tscn += f"""
[node name="Ponton{_i + 1}" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {_g_mid[0]:.3f}, {_g_mid[1]:.3f}, {_g_mid[2]:.3f})
script = ExtResource("8_pont")
near_end = Vector3({_near[0]:.3f}, {_near[1]:.3f}, {_near[2]:.3f})
far_end = Vector3({_far[0]:.3f}, {_far[1]:.3f}, {_far[2]:.3f})
deck_width = {_PONT_HALF_W * 2.0:.1f}
wave_phase = {round(_i / 3.0, 3)}
plate_count = {max(6, int(_span / 6.0))}
"""

tscn += f"""
[node name="BandaDeJos" type="Path3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {_br_origin[0]:.3f}, {_br_origin[1]:.3f}, {_br_origin[2]:.3f})
curve = SubResource("Curve3D_banda")
script = ExtResource("16_branch")
branch_half_width = 4.0
surface = 1

[node name="CameraGrota" type="Area3D" parent="."]
transform = {xf_ident((F_GROTTO0 + F_GROTTO1) * 0.5)}
script = ExtResource("18_camzone")
frac_from = {r3(F_GROTTO0 - 0.004)}
frac_to = {r3(F_GROTTO1 + 0.004)}
size = Vector3(16.0, 13.0, 40.0)
ceiling = 11.0
ceiling_dist = 20.0
darkness = 0.55
cave_fog_end = 70.0
blend_time = 0.45

[node name="Maree" type="Node3D" parent="."]
transform = Transform3D({rot_y(_tide_yaw)}, {_tide_mid[0]:.3f}, {_tide_mid[1]:.3f}, {_tide_mid[2]:.3f})
script = ExtResource("17_tide")
branch_index = 1
period = 80.0
span_m = {_clen:.1f}
lane_width = 8.0
rise_m = 1.5
"""

tscn += """
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
