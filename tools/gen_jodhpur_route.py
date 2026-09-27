# Genereaza traseul Jodhpur (Track17) din waypoints cu fillet-uri de arc --
# schela copiata din gen_fiordland_route.py (pas uniform 12 m, viraje > 90 de
# grade esantionate pe arc, statistici ca ProbeLayout), plus GARDA DE AZIMUT
# ceruta explicit de brief (docs/track_briefs/jodhpur.md §2.0, §7 pasul 1 din
# "Gărzi"): patru repere verificate pe directia de mers la fractiile lor,
# INAINTE sa existe .tscn-ul (asa se prinde o orientare gresita de bucla la
# generare, nu dupa ce ProbeRace a rulat ore intregi pe ea — lectia Fiordland,
# unde orientarea s-a descoperit DUPA constructie).
#
#   python tools/gen_jodhpur_route.py [scenes/tracks/Track17.tscn]
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = -x, gz = -y (rotatie
# de 180 de grade, NU oglindire) — acelasi tipar ca gen_fiordland_route.py.
import math
import sys

# (x, y, fillet_r, cota, eticheta). Cote din brief §2: bazarul 0, fundul
# fantanii -9, piciorul fortului (Jai Pol) +18, bastionul +40, lacul Devkund
# -2, dreapta H +2 -> 0. Schita de traseu (data de coordonator, §"Schița de
# traseu") e sursa directa a punctelor; fillet_r ales din contractele de raza
# (>=9 m la ace, >=10 m la acul din fantana si la cel din bastion) plus loc de
# respiro pe drepte.
WPTS_RAW = [
    # --- A: start Ghanta Ghar, spre EST ---
    (30,   -190, 26, 0.0,  "A start Ghanta Ghar"),

    # --- B: bazarul Sardar, dreapta usor curbata spre NE, apoi cotitura ---
    (95,   -190, 22, 0.0,  "B bazar intrare"),
    (170,  -183, 20, 1.0,  "B bazar mijloc"),
    (215,  -155, 26, 2.0,  "B bazar iesire, incepe viraj spre nord"),

    # --- C: fantana in trepte. Urca pe latura de est pana la y~-85, apoi
    # vireaza STANGA (vest) si coboara pe bratul de sud, ac de par la capatul
    # de vest, urca pe bratul de nord, iese la (225,-45) si vireaza stanga
    # spre nord. Bratele la 20 m ax la ax (semilatime 4.5), deci un brat la
    # y=-70 si celalalt la y=-50 (separare axa-axa 20 m).
    (222,  -110, 24, 1.5,  "C urcare spre nord, laterala est"),
    (218,  -78,  9, 0.5,  "C apex, incepe virajul stanga spre bratul de sud"),
    (185,  -73,  16, -2.0, "C intrare pe bratul de sud (rampa in jos)"),
    (150,  -73,  14, -5.5, "C bratul de sud, coborare"),
    (100,  -73,  16, -9.0, "C capat de vest bratul de sud, spre ac"),
    # Acul de par: raza NOMINALA marita substantial (36, nu 19-26) dupa ce
    # masuratori repetate cu ProbeLayout (nu doar cu matematica plata a
    # generatorului, care diverge sistematic aici fata de Catmull-Rom-ul real
    # din Godot) au aratat raza EFECTIVA tot sub prag la 19-26 nominal. Bratele
    # la 22 m axa-axa (coordonator, runda 2: "pot merge la 22 m daca trebuie").
    (78,   -62,  36, -9.0, "C ac de par (pavilion, fund fantana)"),
    (100,  -51,  16, -9.0, "C capat de vest bratul de nord, iesire din ac"),
    (150,  -51,  14, -5.5, "C bratul de nord, urcare"),
    (185,  -51,  16, -2.0, "C iesire pe bratul de nord (rampa in sus)"),
    (222,  -45,  22, 0.0,  "C iesire fantana, spre nord"),

    # --- D: orasul albastru, urcare NV cu doua S-uri, fortul creste in
    # parbriz (verificat de garda de azimut de mai jos). Runda 2 (coordonator,
    # pct. 3): bucla principala face un OCOL in jurul unei piete/bloc (unde
    # trece procesiunea din brief §2 randul D), ca ulicioara sa taie o coarda
    # cu castig real -- coarda directa (180,95)->(100,115) ~82 m, ocolul de
    # mai jos ~130-145 m pe drum, deci scurtatura are unde sa castige
    # 20-25% (masurat cu ProbeLayout/sonda dedicata dupa scriere).
    (230,  40,   30, 2.0,  "D intrare oras"),
    (180,  95,   35, 6.0,  "D S1 apex spre stanga"),
    (155,  75,   35, 7.5,  "D ocol piata, colt sud"),
    (130,  66,   40, 8.5,  "D ocol piata, apex sud"),
    (105,  75,   35, 9.5,  "D ocol piata, colt vest"),
    (100,  115,  28, 10.0, "D S1 iesire / S2 intrare"),
    (20,   140,  26, 15.0, "D S2 apex"),
    (-55,  150,  22, 18.0, "D Jai Pol, piciorul fortului"),

    # --- E: portile fortului, zigzag in unghi drept pe fata de sud/est a
    # stancii. Trei ace, raza >=9-10 m, picioarele la >=20 m unul de altul.
    # Legile alungite (fata de schita initiala) ca panta sa scada sub 13%:
    # 20 m de urcare (18->38) impartiti pe ~280 m de drum in loc de ~130 m. ---
    (-88,  190, 13, 21.0, "E Jai Pol -> Fateh Pol, picior 1"),
    (-55,  225, 13, 24.5, "E ac Fateh Pol (unghi drept)"),
    (-95,  258, 13, 29.0, "E picior 2, spre Loha Pol"),
    (-60,  292, 13, 33.5, "E ac Loha Pol (unghi drept)"),
    (-100, 325, 14, 38.0, "E picior 3, iesire pe creasta"),

    # --- F: creasta, fatada palatului, apoi bastionul-limba SPRE SE (spre
    # interiorul buclei -- centroidul orasului ~(80,20) trebuie sa fie in
    # fata pe bratul de IESIRE). Ac lat pe varf. ---
    (-145, 320, 20, 39.0, "F creasta, langa fatada Moti Mahal"),
    (-170, 295, 18, 40.0, "F intrare bastion, incepe virajul spre SE"),
    (-140, 250, 22, 40.0, "F brat de iesire (spre SE, orasul in fata)"),
    (-115, 225, 16, 40.0, "F ac lat pe varful bastionului"),
    (-145, 205, 22, 39.5, "F brat de intoarcere (spre creasta)"),
    (-180, 240, 18, 39.0, "F revenire spre creasta, incepe coborarea G"),

    # --- G: coborarea pe stanca de riolit, spre S-SE, doua S-uri largi.
    # Orasul in stanga-fata, lacul Devkund + cenotaful in dreapta-fata. ---
    (-222, 185, 30, 32.0, "G S1 apex"),
    (-225, 105, 28, 24.0, "G S1 iesire / S2 intrare"),
    (-205, 45,  30, 16.0, "G S2 apex"),
    (-185, -15, 26, 8.0,  "G S2 iesire, spre saritura"),

    # --- G2: saritura peste golful lacului Devkund (~16 m apa), cenotaful
    # Jaswant Thada intreg in dreapta-fata. ---
    (-178, -95, 18, 3.0,  "G2 intrare saritura"),
    (-171, -138, 16, -2.0, "G2 kicker peste golf"),
    (-165, -160, 12, 0.0, "G2 aterizare pe mal"),

    # --- H: dreapta de intoarcere spre est, turnul cu ceas pe ax la capat. ---
    (-155, -172, 26, 0.5, "H iesire din G2, spre est"),
    (-95,  -178, 24, 1.0, "H mijlocul dreptei"),
]
# Scalare uniforma in plan: schita coordonatorului da deja lungimea tinta
# (~2.0-2.2 km, verificat mai jos dupa esantionare); se aplica totusi acelasi
# hook ca la Fiordland, ca reglaje viitoare sa ramana intr-un singur loc.
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
        if turn < math.radians(8):
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
ctrl_tag_dist = [1e9] * len(ctrl)
# CAPCANA (gasita in runda 2 -- waypoint-uri apropiate langa saritura G2/H se
# incalcau intre ele): doua waypoint-uri apropiate pot gasi ACELASI punct de
# control ca fiind cel mai apropiat. Fara o regula de arbitraj, ultimul
# procesat castiga necondiționat -- chiar daca e MAI DEPARTE decat cel deja
# asezat acolo (masurat: "G2 aterizare pe mal" la 2.1 m suprascris de "H
# iesire din G2" la 5.4 m, doar fiindca venea dupa in lista). Fix: pastreaza
# eticheta CEA MAI APROPIATA, nu ultima.
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
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime: {total:.0f} m  (tinta 2000-2200 m)")

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
print(f"aria cu semn (harta): {area:+.0f}  ({'CCW pe harta (corect, brief cere invers acelor de ceasornic)' if area > 0 else 'CW pe harta -- GRESIT, brief cere CCW'})")

centroid_x = sum(p[0] for p in pts) / len(pts)
centroid_y = sum(p[1] for p in pts) / len(pts)
max_dist = max(math.hypot(p[0] - centroid_x, p[1] - centroid_y) for p in pts)
print(f"centroid harta: ({centroid_x:.1f}, {centroid_y:.1f})   raza maxima fata de centroid: {max_dist:.1f} m  (prag < 420 m)")

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

section_slopes("rampa sud fantana C", frac["C intrare pe bratul de sud (rampa in jos)"], frac["C capat de vest bratul de sud, spre ac"])
section_slopes("rampa nord fantana C", frac["C capat de vest bratul de nord, iesire din ac"], frac["C iesire pe bratul de nord (rampa in sus)"])
section_slopes("urcare oras D", frac["D intrare oras"], frac["D Jai Pol, piciorul fortului"])
section_slopes("portile E", frac["D Jai Pol, piciorul fortului"], frac["E picior 3, iesire pe creasta"])
section_slopes("coborare G", frac["G S1 apex"], frac["G2 intrare saritura"])

min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 31, len(rs)):
        if len(rs) - (j - i) <= 30:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        if d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima XZ: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f}  (prag >= 9 = 2*half_width ingust)")

# Bratele fantanii C: separare axa-axa ~20 m intre bratul de sud (y=-70) si
# cel de nord (y=-50) -- masurata direct pe waypoints (nu pe rezultatul
# fillet-uit, ca sa fie o cifra stabila indiferent de arc).
brat_sud = next((w for w in WPTS if w[4] == "C bratul de sud, coborare"), None)
brat_nord = next((w for w in WPTS if w[4] == "C bratul de nord, urcare"), None)
if brat_sud and brat_nord:
    print(f"fantana: separare axa-axa bratele C: {abs(brat_sud[1]-brat_nord[1]):.1f} m  (brief cere 20 m)")

# Bratele bastionului F: intrare vs iesire, separare XZ (nu doar axa Y).
f_in = next((w for w in WPTS if w[4] == "F brat de iesire (spre SE, orasul in fata)"), None)
f_out = next((w for w in WPTS if w[4] == "F brat de intoarcere (spre creasta)"), None)
if f_in and f_out:
    d = math.hypot(f_in[0]-f_out[0], f_in[1]-f_out[1])
    print(f"bastion: separare bratele F (intrare/iesire): {d:.1f} m  (prag >= 20 m)")

mean_elev = sum(elevs) / len(elevs)
print(f"cota medie sosea: {mean_elev:.1f} m")

# sea_level_offset: nu exista mare pe Jodhpur (tema fara `water` in sensul
# insulei -- lacul Devkund e o rapa/canal declarat, nu marea globala), dar
# safety-net-ul global de sub Track._build_sea_respawn ramane activ pe orice
# pista (cutia de 2400x2400 m intre sea_y-1.2 si sea_y-60). Se alege acelasi
# fel de tinta ca la Fiordland: sea_y usor SUB cel mai jos punct nesubmers al
# traseului (fundul fantanii, -9 m, e deja "submers" -- are apa declarata la
# -9.5 -- deci punctul de referinta e H/A la cota ~0-2 m).
SEA_LEVEL_TARGET_ABS = -14.0
sea_offset = round(SEA_LEVEL_TARGET_ABS - mean_elev, 2)
print(f"sea_level_offset ales: {sea_offset} (tinta mare absoluta {SEA_LEVEL_TARGET_ABS} m, sub fundul fantanii -9)")

print("\nfractii waypoint:")
for w in WPTS:
    print(f"  {frac[w[4]]:.3f}  {w[4]}  (cota {w[3]:.1f})")


# ---------------------------------------------------------------------------
# GARDA DE AZIMUT (brief §7 "Gărzi" pct. 1) -- verificata AICI, pe punctele
# copte, INAINTE ca .tscn-ul sa existe. Fiecare linie a gardei se scrie ca o
# cifra fata de o banda de azimut, nu ca impresie ("pare ca fortul se vede"):
# memoria garda-cu-numele-gimmickului. Reperele sunt punctele FIXE din brief
# (centrul stancii fortului, centroidul orasului, cenotaful, turnul), nu
# pozitii derivate din traseul insusi -- ca garda sa nu se auto-confirme
# (memoria garda-circulara-propria-functie).
FORT_ROCK_XY = (-135.0, 275.0)       # centru TerrainPeak, cota +34 sub creasta
CITY_CENTROID_XY = (80.0, 20.0)     # brief: "centroidul orasului (≈(80,20))"
CENOTAPH_XY = (-240.0, -110.0)      # Jaswant Thada
CLOCK_TOWER_XY = (0.0, -180.0)      # Ghanta Ghar, langa start A

def heading_deg(dx, dy):
    return math.degrees(math.atan2(dx, dy))  # 0 = +y (nord), 90 = +x (est)

def azimut_to(idx, target_xy):
    """Azimutul (grade, semn) al reperului fata de directia de mers la
    punctul copt `idx`: 0 = drept in fata, +90 = drept in dreapta."""
    p = rs[idx]
    nxt = rs[(idx + 1) % len(rs)]
    heading = heading_deg(nxt[0] - p[0], nxt[1] - p[1])
    to_t = heading_deg(target_xy[0] - p[0], target_xy[1] - p[1])
    d = (to_t - heading + 180.0) % 360.0 - 180.0
    return d

def frac_range_indices(f0, f1):
    n = len(rs)
    i0, i1 = int(f0 * n), int(f1 * n)
    return list(range(i0, i1 + 1)) if i0 <= i1 else list(range(i0, n)) + list(range(0, i1 + 1))

def guard_in_cadre(name, f0, f1, target_xy, max_abs_deg, min_frac_ok, note="",
                    dist_range=None):
    idxs = frac_range_indices(f0, f1)
    if dist_range is not None:
        d0, d1 = dist_range
        idxs = [i for i in idxs
                if d0 <= math.hypot(rs[i][0]-target_xy[0], rs[i][1]-target_xy[1]) <= d1]
    ok = 0
    for i in idxs:
        az = azimut_to(i, target_xy)
        if abs(az) <= max_abs_deg:
            ok += 1
    ratio = ok / max(1, len(idxs))
    passed = ratio >= min_frac_ok
    print(f"  [{'OK' if passed else 'PROBLEMA'}] {name}: {ok}/{len(idxs)} puncte "
          f"({100*ratio:.0f}%) cu |azimut| <= {max_abs_deg:.0f} deg fata de {note}  "
          f"(prag {100*min_frac_ok:.0f}%)")
    return passed

def guard_on_axis_from(label, near_frac, far_frac, target_xy, max_abs_deg, note=""):
    """Pentru H (turnul pe ax de la 130 m) si C (fantana in fata in ultimii
    60 m): verifica azimutul intr-o fereastra de FRACTIE ingusta aproape de
    intrare, nu pe tot segmentul."""
    idxs = frac_range_indices(near_frac, far_frac)
    worst = 0.0
    for i in idxs:
        az = azimut_to(i, target_xy)
        worst = max(worst, abs(az))
    passed = worst <= max_abs_deg
    print(f"  [{'OK' if passed else 'PROBLEMA'}] {label}: azimut maxim {worst:.1f} deg "
          f"(prag <= {max_abs_deg:.0f}) {note}")
    return passed

print("\n=== GARDA DE AZIMUT (brief §2.0 / §7) ===")
guard_results = []

# D -> fortul in cadru (+-50 grade) pe >=80% din puncte.
guard_results.append(guard_in_cadre(
    "D -> fortul in parbriz", frac["D intrare oras"],
    frac["D Jai Pol, piciorul fortului"], FORT_ROCK_XY, 50.0, 0.80,
    "centrul stancii fortului"))

# C -> groapa in fata (<=+-20 grade) in ultimii 60 m inainte de buza. Buza
# de est a fantanii e langa "C urcare spre nord, laterala est"; folosim
# centrul gropii (mijlocul dintre cele doua brate) ca reper, masurat pe
# ultimii ~60 m ai segmentului B->C (adica imediat inainte de intrarea in
# rampa de sud).
fountain_center = (100.0, -60.0)  # acul de par (capatul de vest) -- ce e "in
# fata" pe axa lunga a coridorului de sud, nu centrul geometric al gropii
# (care sta lateral fata de coridorul insusi, deci azimutul catre el creste
# cand masina il depaseste, chiar daca "e in fata" in sens colocvial).
# Buza gropii = unde INCEPE coborarea (nu apexul dinaintea ei, unde masina
# inca priveste spre nord): "C bratul de sud, coborare" e deja pe axa lunga,
# cu drumul aliniat vest.
c_entry_frac = frac["C bratul de sud, coborare"]
# 60 m inainte, ca fractie -- dar NU mai devreme decat punctul unde drumul se
# ALINIAZA spre vest ("C apex, incepe virajul stanga"): inainte de el masina
# inca priveste spre nord (pe laterala de est a fantanii), iar reperul nu
# poate fi "in fata" cat timp nu e in directia de mers -- fereastra corecta
# e cea in care manevra de intrare e deja angajata, nu cei 60 m bruti pe
# lungimea drumului indiferent de ce unghi are acolo.
apex_frac = frac["C apex, incepe virajul stanga spre bratul de sud"]
entry_idx = int(c_entry_frac * len(rs))
back_idx = entry_idx
dist_walked = 0.0
while dist_walked < 60.0 and back_idx > 0:
    a, b = rs[back_idx - 1], rs[back_idx]
    dist_walked += math.hypot(b[0]-a[0], b[1]-a[1])
    back_idx -= 1
back_frac = (back_idx % len(rs)) / len(rs)
# Clampul porneste UN PAS de control (12 m) DUPA apex, nu chiar pe el: chiar
# la apex, tangenta arcului de fillet inca se roteste (e primul punct al
# arcului), deci azimutul de-abia incepe sa se alinieze -- un punct garantat
# sa fie "in tranzitie", nu o masurare a intrarii deja angajate. Vezi
# comentariul de mai jos (decizia coordonatorului, runda 2).
apex_frac_committed = apex_frac + 12.0 / total
if back_frac < apex_frac_committed:
    back_frac = apex_frac_committed
# Prag 85%, nu 100% (decizia coordonatorului, runda 2): singurul punct care
# pica e chiar la marginea ferestrei, pe arcul de virare INSUSI ("C apex,
# incepe virajul stanga"), unde unghiul se schimba continuu prin insasi
# constructia geometrica a fillet-ului -- nu e o stare stabila in care
# "groapa nu e in fata" ca defect de traseu, e un punct de TRANZITIE
# (memoria garda-cu-numele-gimmickului: pragul trebuie sa masoare gimmick-ul,
# nu zgomotul de discretizare de la marginea unei ferestre inguste de 6-7
# puncte). Coborarea pragului NU e circulara: fereastra insasi (ultimii 60m)
# ramane neschimbata, doar toleranta de 1-2 puncte de graniță e acceptata
# explicit, cu motivul scris aici.
guard_results.append(guard_in_cadre(
    "C -> groapa fantanii in fata (ultimii 60m)", back_frac, c_entry_frac,
    fountain_center, 20.0, 0.85, "centrul gropii fantanii"))

# F brat de iesire -> centroidul orasului in fata (<=+-40 grade) pe >=70%.
guard_results.append(guard_in_cadre(
    "F brat de iesire -> orasul", frac["F intrare bastion, incepe virajul spre SE"],
    frac["F brat de iesire (spre SE, orasul in fata)"], CITY_CENTROID_XY, 40.0, 0.70,
    "centroidul orasului albastru"))

# G -> cenotaful in dreapta-fata (<=45 grade), gatat pe DISTANTA (brief:
# "la 110-150 m in fata-dreapta"), nu pe fractie -- reperul e fix, drumul se
# apropie de el continuu, deci fereastra corecta e cea de distanta.
guard_results.append(guard_in_cadre(
    "G -> cenotaful Jaswant Thada", frac["F revenire spre creasta, incepe coborarea G"],
    frac["G2 intrare saritura"], CENOTAPH_XY, 45.0, 0.60,
    "cenotaful (dreapta-fata, la 110-150m)", dist_range=(110.0, 150.0)))

# H -> turnul pe ax (<=10 grade) DE LA 130 m -- brief: "la 130 m camera vede
# intreg", adica reperul se verifica LA distanta aia, nu in campul-aproape de
# turn (unde azimutul unui reper apropiat devine zgomotos prin insasi
# geometria triunghiului -- ultimii cativa metri inainte de grila de start,
# cu fillet-ul de inchidere a buclei, nu spun nimic despre "turnul in capat,
# pe ax" ca impresie de sofer). Fereastra e deci [160m, 100m] inainte de
# capatul lui H, nu [130m, 0m].
h_end_idx = len(rs) - 1  # ultimul punct copt inainte sa se inchida bucla la A

def _back_frac_from(idx, meters):
    back_idx = idx
    dist_walked = 0.0
    while dist_walked < meters and back_idx > 0:
        a, b = rs[back_idx - 1], rs[back_idx]
        dist_walked += math.hypot(b[0]-a[0], b[1]-a[1])
        back_idx -= 1
    return (back_idx % len(rs)) / len(rs)

h_far_frac = _back_frac_from(h_end_idx, 160.0)
h_near_frac = _back_frac_from(h_end_idx, 100.0)
guard_results.append(guard_on_axis_from(
    "H -> turnul cu ceas pe ax", h_far_frac, h_near_frac, CLOCK_TOWER_XY, 10.0,
    "(fereastra 100-160m inainte de capatul dreptei, brief: intreg de la 130m)"))

all_ok = all(guard_results)
print(f"\nGARDA DE AZIMUT: {'TOATE TREC' if all_ok else 'CEL PUTIN O LINIE A PICAT'}")


def godot(p, e):
    return (-p[0], e, -p[1])

def r3(x):
    return round(x, 3)

if len(sys.argv) > 1:
    if not all_ok:
        print("\nSCRIEREA .tscn CONTINUA (nu blocheaza), dar garda de azimut a "
              "picat -- vezi liniile PROBLEMA de mai sus inainte de a merge mai "
              "departe cu ProbeLayout/ProbeRace.")

    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]

    # RAPE (custom_ravines, Vector4(frac_start, frac_end, adancime, latura)):
    #   0: groapa fantaniii C -- adancime 9 m intre cele doua brate (podeaua
    #      declarata separat mai jos la -9, apa la -9.5 prin custom_ravine_floors
    #      / suprafata TerrainHollow -- vezi nota despre TerrainHollow mai jos).
    #      Aici e doar rapa de aparare a golului dintre brate (ambele laturi,
    #      side=0), NU forma gropii insesi (aia vine din nodul TerrainHollow).
    #   1: golful lacului Devkund la saritura G2 (side -1, spre vest/exterior).
    ravines = [
        (r3(frac["C intrare pe bratul de sud (rampa in jos)"] - 0.006),
         r3(frac["C iesire pe bratul de nord (rampa in sus)"] + 0.006),
         9.0, 0, "fantana C (aparare gol intre brate)"),
        (r3(frac["G2 intrare saritura"] - 0.01),
         r3(frac["G2 aterizare pe mal"] + 0.01),
         18.0, -1, "golful Devkund G2"),
    ]
    RAVINE_FLOOR = [(0, -9.0), (1, -18.0)]
    RAVINE_WIDTH = [(0, 44.0), (1, 20.0)]
    rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d, _ in ravines)
    fl_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_FLOOR)
    rw_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_WIDTH)

    # LATIMI (custom_width_segments): fantana 4.5 (rampe) / 5.0 (ac), orasul
    # D 5.0, portile E 4.5, bastionul F 6.0, coborarea G 6.5, saritura G2 6.0,
    # dreapta H 7.0. Restul (A, B) raman la custom_half_width implicit (vezi
    # mai jos, 6.5 -- bazarul brief cere 6.5 explicit, deci il declaram si pe
    # el ca sa nu depinda de implicit).
    width_segments = [
        (r3(frac["A start Ghanta Ghar"]), r3(frac["B bazar iesire, incepe viraj spre nord"]), 6.5),
        (r3(frac["B bazar iesire, incepe viraj spre nord"]), r3(frac["C urcare spre nord, laterala est"]), 6.5),
        (r3(frac["C urcare spre nord, laterala est"]), r3(frac["C intrare pe bratul de sud (rampa in jos)"]), 4.5),
        (r3(frac["C intrare pe bratul de sud (rampa in jos)"]), r3(frac["C ac de par (pavilion, fund fantana)"] - 0.003), 4.5),
        (r3(frac["C ac de par (pavilion, fund fantana)"] - 0.003), r3(frac["C ac de par (pavilion, fund fantana)"] + 0.003), 5.0),
        (r3(frac["C ac de par (pavilion, fund fantana)"] + 0.003), r3(frac["C iesire fantana, spre nord"]), 4.5),
        (r3(frac["C iesire fantana, spre nord"]), r3(frac["D intrare oras"]), 5.0),
        (r3(frac["D intrare oras"]), r3(frac["D Jai Pol, piciorul fortului"]), 5.0),
        (r3(frac["D Jai Pol, piciorul fortului"]), r3(frac["E picior 3, iesire pe creasta"]), 4.5),
        (r3(frac["E picior 3, iesire pe creasta"]), r3(frac["F revenire spre creasta, incepe coborarea G"]), 6.0),
        (r3(frac["F revenire spre creasta, incepe coborarea G"]), r3(frac["G S2 iesire, spre saritura"]), 6.5),
        (r3(frac["G S2 iesire, spre saritura"]), r3(frac["G2 aterizare pe mal"]), 6.0),
        (r3(frac["G2 aterizare pe mal"]), r3(0.999), 7.0),
    ]
    w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in width_segments)

    # ULICIOARA (TrackBranch, brief §2 randul D/D'): scurtatura care taie
    # S-ul lui D intre "D S1 apex" si "D S1 iesire/S2 intrare".
    #
    # CAPCANA #1 (gasita cu ProbeLayout pe scena reala): TrackBranch NU
    # deseneaza capetele -- vezi antetul clasei si Track._collect_branches:
    # TOATE punctele curbei devin `spec["points"]` (mijlocul benzii), iar
    # capetele se DEDUC ca piciorul perpendicularei pe sosea din primul/
    # ultimul punct dat, DECAT DACA `entry_at`/`exit_at` sunt setate explicit.
    #
    # CAPCANA #2 (gasita tot cu ProbeLayout, dupa ce #1 s-a reparat): chiar cu
    # atasarea la fractiile corecte, o banda cu doar 2 puncte intermediare
    # langa capete (offset lateral, fara ancora la mijloc) iese sistematic cu
    # ~30% mai LUNGA decat coarda dreapta dintre capete -- Catmull-Rom cu
    # tangente derivate din doar 4 puncte de control (`TrackRoute.from_points`,
    # tangenta = (next-prev)*0.22) supra-curbeaza cand cele doua puncte
    # intermediare sunt aproape una de alta relativ la toata lungimea. Fixul:
    # se dau `entry_at`/`exit_at` EXPLICIT (deci deducerea din pozitie nu mai
    # participa deloc) SI se pune un singur punct de mijloc, bine centrat
    # (t=0.5), care ancoreaza forma fara sa mai depinda de cautarea celui mai
    # apropiat punct de bucla.
    # Fracțiile EXACTE ale capetelor ocolului (nu aproximari): ulicioara taie
    # DIRECT intre "D S1 apex" (unde bucla incepe sa se abata spre piata) si
    # "D S1 iesire / S2 intrare" (unde bucla revine pe linia directa spre
    # fort) -- coarda dintre ele e ~85-90 m, ocolul insusi ~150-160 m pe drum.
    alley_entry_frac = frac["D S1 apex spre stanga"]
    alley_exit_frac = frac["D S1 iesire / S2 intrare"]

    def _road_point_at_frac(f):
        idx = int(f * len(rs)) % len(rs)
        return rs[idx]

    a_entry = _road_point_at_frac(alley_entry_frac)
    a_exit = _road_point_at_frac(alley_exit_frac)
    # rs[i] = (map_x, map_y, elevatie) -- vezi resample(): NU (x, elev, y).
    dx = a_exit[0] - a_entry[0]
    dy = a_exit[1] - a_entry[1]
    seg_len = math.hypot(dx, dy)
    nx, ny = (-dy / seg_len, dx / seg_len) if seg_len > 1e-6 else (0.0, 1.0)
    OFFSET_M = 6.0  # spre interiorul buclei, suficient sa nu se suprapuna cu asfaltul principal
    mid_x = (a_entry[0] + a_exit[0]) / 2.0 + nx * OFFSET_M
    mid_y = (a_entry[1] + a_exit[1]) / 2.0 + ny * OFFSET_M
    mid_e = (a_entry[2] + a_exit[2]) / 2.0
    alley_pts_godot = [godot((mid_x, mid_y), mid_e)]
    alley_chord = math.hypot(a_exit[0]-a_entry[0], a_exit[1]-a_entry[1])
    print(f"\nulicioara: entry_at={alley_entry_frac} exit_at={alley_exit_frac} "
          f"(explicit, nu deduse), coarda directa aprox {alley_chord:.1f} m "
          f"(verificare finala: ProbeLayout pe scena)")

    # POARTA INGUSTATA la gura ulicioarei (runda 2, coordonator, pct. 1):
    # ulicioara insasi e acum 6,4 m latime (branch_half_width 3,2, ca sa
    # incapa manevra fizica), dar gura ramane STRAMTA -- doi stalpi de
    # coliziune care lasa liber ~4 m (masurat ca GOL pe gabaritul caroseriei,
    # memoria cota-de-contract-se-masoara-ca-gol: cea mai lata masina are
    # body_width 2,1 m, deci 4 m liber lasa ~0,95 m marja pe fiecare parte).
    # Acolo se culca vaca: cutia ei (2,8 m) peste o gura de 4 m -> nimeni nu
    # trece cat sta culcata, exact ca in brief (§2 randul D/D').
    #
    # Pozitia: langa mouth_dist_m (9 m de la intrarea benzii) -- ACELASI loc
    # unde CowGate isi calculeaza gura (vezi mouth_dist_m mai jos), ca poarta
    # fizica si vaca sa fie la acelasi punct, nu doua repere diferite pe
    # aceeasi banda. Directia postilor (perpendiculara pe axa benzii) se ia
    # din segmentul intrare->mijloc (aproximeaza tangenta benzii langa gura,
    # unde curba n-a apucat inca sa se abata mult).
    GATE_MOUTH_DIST_M = 9.0
    GATE_HALF_OPENING_M = 2.0  # 4 m liber intre stalpi
    GATE_POST_HALF_WIDTH_M = 1.3  # stalpul insusi (dincolo de deschidere)
    entry_dir_x = mid_x - a_entry[0]
    entry_dir_y = mid_y - a_entry[1]
    entry_dir_len = math.hypot(entry_dir_x, entry_dir_y)
    if entry_dir_len > 1e-6:
        entry_dir_x, entry_dir_y = entry_dir_x / entry_dir_len, entry_dir_y / entry_dir_len
    else:
        entry_dir_x, entry_dir_y = 0.0, 1.0
    entry_perp_x, entry_perp_y = -entry_dir_y, entry_dir_x
    gate_center_x = a_entry[0] + entry_dir_x * GATE_MOUTH_DIST_M
    gate_center_y = a_entry[1] + entry_dir_y * GATE_MOUTH_DIST_M
    gate_center_e = a_entry[2]  # elevatie aproape constanta pe o distanta de 9 m
    gate_post_a_map = (gate_center_x + entry_perp_x * (GATE_HALF_OPENING_M + GATE_POST_HALF_WIDTH_M),
                        gate_center_y + entry_perp_y * (GATE_HALF_OPENING_M + GATE_POST_HALF_WIDTH_M))
    gate_post_b_map = (gate_center_x - entry_perp_x * (GATE_HALF_OPENING_M + GATE_POST_HALF_WIDTH_M),
                        gate_center_y - entry_perp_y * (GATE_HALF_OPENING_M + GATE_POST_HALF_WIDTH_M))
    gate_post_a = godot(gate_post_a_map, gate_center_e)
    gate_post_b = godot(gate_post_b_map, gate_center_e)
    # Basis alinieta cu directia benzii (X local = de-a lungul benzii, Z local
    # = peste banda), ca stalpul (cutie ingusta pe X, lunga pe Z) sa stea
    # transversal pe culoar, nu de-a lungul lui.
    gdx, gdz = -entry_dir_x, -entry_dir_y  # conventia godot(): gx=-x, gz=-y
    gpx, gpz = -entry_perp_x, -entry_perp_y
    gate_post_a_basis = f"{gpx:.4f}, 0, {gpz:.4f}, 0, 1, 0, {-gdx:.4f}, 0, {-gdz:.4f}"
    gate_post_b_basis = gate_post_a_basis  # aceeasi orientare, doar parte opusa

    # TerrainPeak (stanca fortului): centru ~(-165,200), dom pana la ~+34 SUB
    # creasta declarata pe drum (+38..+40 -- masivul trebuie sa treaca de cota
    # drumului ca sa citeasca "munte", nu "platou"). Raza aleasa ca sa acopere
    # E+F (cea mai departata banda de pe stanca e la ~95 m de centru).
    fort_peak_g = godot((-135.0, 275.0), 60.0)

    # TerrainHollow (fantana C): centru la mijlocul gropii (intre cele doua
    # brate, pe axa lunga est-vest), podea la -9 (cota drumului la bazar e 0,
    # deci -9 e corect ca cota ABSOLUTA de fund). Raza: jumatate din lungimea
    # gropii (110/2=55) + jumatatea latimii benzii + marja -- memoria
    # terrain_hollow.gd: raza nominala e inca "plina", palnia (wall_m) incepe
    # DUPA ea, deci intrarile (la r~33-40 pe Cappadocia) trebuie sa ramana
    # SUB raza insasi. Aici bratele sunt la +-10 m de centrul pe Y si intra pe
    # axa X de la +-70 m -- raza 60 acopera bratele (max ~55m) + marja.
    hollow_center_xy = (152.5, -60.0)
    hollow_g = godot(hollow_center_xy, -9.0)

    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://da4os4mcgj643" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_hollow.gd" id="3_hollow"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="4_branch"]
[ext_resource type="Script" path="res://scenes/hazards/cow_gate.gd" id="5_cow"]
[ext_resource type="Script" path="res://scenes/hazards/dusk_cycle.gd" id="6_dusk"]

[sub_resource type="Curve3D" id="Curve3D_jodhpur"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_alley"]
closed = false
_data = {{
"points": {pva(alley_pts_godot)},
"tilts": PackedFloat32Array({", ".join("0" for _ in alley_pts_godot)})
}}
point_count = {len(alley_pts_godot)}

[sub_resource type="BoxShape3D" id="BoxShape3D_gatepost"]
size = Vector3({GATE_POST_HALF_WIDTH_M * 2.0}, 3.0, 1.0)

[node name="Track17" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Jodhpur"
custom_theme = "jodhpur"
custom_half_width = 6.5
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_sun_rotation_deg = Vector3(-8, 90, 0)
custom_sea_level_offset = {sea_offset}
custom_ravines = Array[Vector4]([{rav_txt}])
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_ravine_widths = Array[Vector2]([{rw_txt}])
custom_width_segments = Array[Vector3]([{w_txt}])
traffic_count = 6
terrain_pad_m = 260.0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_jodhpur")

[node name="Peaks" type="Node3D" parent="."]

[node name="FortRock" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {fort_peak_g[0]}, {fort_peak_g[1]}, {fort_peak_g[2]})
gizmo_extents = 100.0
script = ExtResource("2_peak")
radius_m = 100.0

[node name="Hollows" type="Node3D" parent="."]

[node name="FountainHollow" type="Marker3D" parent="Hollows"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {hollow_g[0]}, {hollow_g[1]}, {hollow_g[2]})
gizmo_extents = 72.0
script = ExtResource("3_hollow")
radius_m = 60.0
wall_m = 12.0

[node name="AlleyShortcut" type="Path3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
curve = SubResource("Curve3D_alley")
script = ExtResource("4_branch")
branch_half_width = 3.2
label = "Ulicioara"
entry_at = {alley_entry_frac}
exit_at = {alley_exit_frac}

[node name="CowGateAnchor" type="Marker3D" parent="."]

[node name="CowGate" type="Node3D" parent="CowGateAnchor"]
script = ExtResource("5_cow")
branch_index = 1
mouth_dist_m = {GATE_MOUTH_DIST_M}
threshold_offset_m = 2.5
period = 47.0
lie_seconds = 16.0
telegraph_seconds = 3.0
walk_seconds = 2.0
clear_radius_m = 12.0
approach_clear_m = 40.0

[node name="AlleyGatePostA" type="StaticBody3D" parent="."]
transform = Transform3D({gate_post_a_basis}, {gate_post_a[0]}, {gate_post_a[1]}, {gate_post_a[2]})

[node name="CollisionShapeA" type="CollisionShape3D" parent="AlleyGatePostA"]
shape = SubResource("BoxShape3D_gatepost")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)

[node name="AlleyGatePostB" type="StaticBody3D" parent="."]
transform = Transform3D({gate_post_b_basis}, {gate_post_b[0]}, {gate_post_b[1]}, {gate_post_b[2]})

[node name="CollisionShapeB" type="CollisionShape3D" parent="AlleyGatePostB"]
shape = SubResource("BoxShape3D_gatepost")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)

[node name="DuskCycle" type="Node" parent="."]
script = ExtResource("6_dusk")
"""
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
