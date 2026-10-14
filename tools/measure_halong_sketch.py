# Masoara schita de traseu Ha Long (Track22) INAINTE sa existe .tscn-ul, ca
# defectele de forma sa iasa pe cifre si nu la volan. Functiile geometrice sunt
# copiate din tools/gen_transfagarasan_route.py (fillet pe arc, pas 12 m,
# statistici ca ProbeLayout). Garzile IES CU COD != 0 daca pica.
#
#   python tools/measure_halong_sketch.py
#   python tools/measure_halong_sketch.py --sabotaj   # muta sirul de turnuri de
#                                                     # fundal 400 m spre vest:
#                                                     # garda de azimut TREBUIE
#                                                     # sa pice (cod 1)
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y, deci
# harta ajunge in lume FARA oglindire (conventia din gen_kyoto_route.py).
#
# Bucla e ANTIORARA pe plan: A (cheiul, NV) -> B (pontoane, spre S pe latura de
# vest) -> C (dig + grota, spre E pe latura de sud) -> D (urcare + belvedere,
# est) -> E (coborare + plaja) -> F (canalul) -> G (coasta, spre V pe latura de
# nord) -> inapoi la A.
#
# DE CE EXISTA GARDA DE APA (cea care a prins defectul real): cota marii e
# `_sampler.mean_road_y() + sea_level_offset` (track.gd:7055), adica RELATIVA la
# media cotelor soselei, nu la y = 0. Pe o pista jumatate pe apa, insula inalta
# RIDICA marea peste pontoane. Prima schita avea insula la +38 -> media +8.2 ->
# apa la +1.2, cu pontoanele (la +0.6) scufundate.
import math
import sys

SABOTAJ = "--sabotaj" in sys.argv

HALF_WIDTH = 7.0   # semi-latimea standard din brief

# (x, y, raza de fillet, cota, eticheta)
WPTS = [
    # Bucla e ORARA pe plan: A (chei, NV) -> G (coasta, spre S)? NU --
    # ordinea e A -> B -> C -> D -> E -> F -> G, iar sensul orar iese din
    # asezarea lor: A in NORD-VEST, B spre SUD pe latura de vest, C spre EST
    # pe latura de sud, D/E in EST, F/G spre VEST pe latura de nord.
    # --- A: cheiul satului plutitor (nord-vest) -----------------------------
    (-352,  322, 44,  1.0, "A start"),
    (-362,  240, 0,   1.0, "A chei"),
    # --- B: pontoanele, trei tronsoane despartite de insulite fixe ----------
    (-354,  168, 0,   0.6, "B pont1"),
    (-346,   96, 0,   0.6, "B insulita1"),
    (-338,   24, 0,   0.6, "B pont2"),
    (-330,  -48, 0,   0.6, "B insulita2"),
    (-320, -120, 0,   0.6, "B pont3"),
    # --- C: digul de piatra, apoi grota marina -----------------------------
    (-296, -188, 44,  1.5, "C dig"),
    (-218, -240, 0,   2.4, "C grota V"),
    (-130, -266, 0,   3.0, "C grota E"),
    # --- D: urcarea pe spinarea insulei + belvederea ------------------------
    ( -36, -284, 48,  7.0, "D urcare"),
    (  60, -272, 44, 14.0, "D creasta"),
    ( 152, -224, 40, 21.0, "D belvedere"),
    ( 204, -152, 0,  26.0, "D varf"),
    # --- E: coborarea in doua ace de par (raza 24) + plaja ------------------
    ( 196,  -52, 24, 21.0, "E ac1a"),
    ( 132,  -36, 24, 17.0, "E ac1b"),
    ( 164,   28, 24, 11.0, "E ac2a"),
    ( 228,   44, 24,  7.0, "E ac2b"),
    ( 212,  112, 0,   3.0, "E plaja"),
    ( 156,  164, 44,  1.6, "E iesire"),
    # --- F: canalul cu podetul de plute ------------------------------------
    (  84,  192, 0,   1.4, "F podet E"),
    (  -8,  206, 0,   1.4, "F podet V"),
    # --- G: drumul de coasta, sapat in perete ------------------------------
    (-104,  226, 48,  1.6, "G coasta E"),
    (-206,  262, 0,   1.4, "G maimute"),
    (-292,  300, 44,  1.2, "G coasta V"),
]

# Repere FIXE pentru garda de azimut (nu derivate din traseu).
SAT = (-366.0, 280.0)        # centrul satului plutitor
GROTA = (-174.0, -253.0)       # gura grotei
BELVEDERE = (152.0, -224.0)   # punctul de belvedere
PLAJA = (212.0, 112.0)       # centrul plajei
PODET = (38.0, 199.0)         # mijlocul podetului de plute
TURNURI_REAL = (430.0, -150.0)   # centrul sirului de turnuri de fundal (EST)
# Sabotaj: mutate 400 m spre vest -> garda de azimut de pe belvedere pica.
TURNURI = (30.0, -150.0) if SABOTAJ else TURNURI_REAL


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

fail = []
print(f"=== SCHITA HA LONG (Track22) ===")
print(f"puncte de control: {n} (pas {STEP} m)   lungime: {tot:.0f} m  (tinta 2000-2200)")
if not (1950 <= tot <= 2250):
    fail.append(f"lungime {tot:.0f} m in afara tintei 1950-2250")

# --- raza minima ---------------------------------------------------------
rmin, rmin_i = 1e18, 0
for i in range(n):
    a, b, c = rs[(i - 1) % n], rs[i], rs[(i + 1) % n]
    r = circumradius(a[:2], b[:2], c[:2])
    if r < rmin:
        rmin, rmin_i = r, i
print(f"raza minima: {rmin:.1f} m la frac {rmin_i / n:.3f}   (prag AI ~14 m, ProbeLayout >= 9)")
if rmin < 14.0:
    fail.append(f"raza minima {rmin:.1f} m sub pragul AI de 14 m")

# --- panta maxima --------------------------------------------------------
gmax, gmax_i = 0.0, 0
for i in range(n):
    a, b = rs[i], rs[(i + 1) % n]
    d = math.hypot(b[0] - a[0], b[1] - a[1])
    g = abs(b[2] - a[2]) / max(1e-6, d)
    if g > gmax:
        gmax, gmax_i = g, i
print(f"panta maxima: {gmax * 100:.1f}%  la frac {gmax_i / n:.3f}   (prag 13%)")
if gmax > 0.13:
    fail.append(f"panta maxima {gmax * 100:.1f}% peste 13%")

# --- separare minima intre portiuni neadiacente --------------------------
# Pragul din memoria dunele-hairpin-pileup: >= 2 * half_width intre axe.
need = 2.0 * HALF_WIDTH
smin, smin_pair = 1e18, None
for i in range(n):
    for j in range(i + 1, n):
        along = min(abs(i - j), n - abs(i - j)) * STEP
        if along < 60.0:      # portiuni vecine pe traseu: nu se compara
            continue
        d = math.hypot(rs[i][0] - rs[j][0], rs[i][1] - rs[j][1])
        if d < smin:
            smin, smin_pair = d, (i / n, j / n)
print(f"separare minima: {smin:.1f} m intre frac {smin_pair[0]:.3f} si {smin_pair[1]:.3f}"
      f"   (prag {need:.0f} m = 2*half_width)")
if smin < need:
    fail.append(f"separare {smin:.1f} m sub 2*half_width ({need:.0f} m)")

# --- centroid si raza Cebisev (zidul lumii la 420 m) ---------------------
cx = sum(p[0] for p in rs) / n
cy = sum(p[1] for p in rs) / n
cheb = max(max(abs(p[0] - cx), abs(p[1] - cy)) for p in rs)
print(f"centroid: ({cx:.0f}, {cy:.0f})   Cebisev: {cheb:.0f} m   (zidul lumii la 420)")
if cheb > 400.0:
    fail.append(f"Cebisev {cheb:.0f} m prea aproape de zidul lumii (420)")

# --- APA: cota marii e RELATIVA la media cotelor soselei -----------------
# track.gd:7055 — sea_y = _sampler.mean_road_y() + sea_level_offset. NU y=0.
# Pe o pista jumatate pe apa, asta leaga cotele de pe apa (chei, pontoane) de
# MEDIA intregului traseu, deci insula le trage in sus.
ymin = min(p[2] for p in rs)
ymax = max(p[2] for p in rs)
ymean = sum(p[2] for p in rs) / n
CHEI = 1.0
PONTON = 0.6
sea_default = ymean - 7.0            # cu sea_level_offset implicit
offset_needed = -ymean               # ca apa sa iasa la 0.0
print(f"cote: min {ymin:.1f}  max {ymax:.1f}  medie {ymean:.1f}")
print(f"  cu sea_level_offset implicit (-7.0): apa la {sea_default:+.1f}")
print(f"  pontoanele la {PONTON:+.1f}, cheiul la {CHEI:+.1f}")
if sea_default > PONTON - 0.3:
    print(f"  !! implicitul INUNDA pontoanele -> sea_level_offset = {offset_needed:.1f}")
print(f"  sea_level_offset NECESAR: {offset_needed:.1f}  (apa la 0.0)")
# plasa de mare: track.gd _build_sea_respawn -> sea_y - 1.2, 60 m adancime
net_top = 0.0 - 1.2
print(f"  plasa de mare (SeaRespawn) la {net_top:+.1f} = apa - 1.2")
if net_top > PONTON - 1.0:
    fail.append(f"plasa de mare la {net_top:+.1f}: prea aproape de pontoane ({PONTON:+.1f})")
# adancimea apei sub ponton: valul pontonului coboara tablierul
PONT_SAG = 0.45 + 0.5        # sag_bus + rest_sag, din RopeBridgeHazard
if PONTON - PONT_SAG < net_top:
    fail.append(f"pontonul afundat la {PONTON-PONT_SAG:+.1f} trece SUB plasa {net_top:+.1f}: repunere falsa")
else:
    print(f"  ponton afundat max {PONTON-PONT_SAG:+.1f} > plasa {net_top:+.1f}: ok")

# --- sens de parcurgere (trebuie ORAR pe plan) ---------------------------
area = 0.0
for i in range(n):
    a, b = rs[i], rs[(i + 1) % n]
    area += a[0] * b[1] - b[0] * a[1]
sens = "ANTIORAR" if area > 0 else "ORAR"
print(f"sens: {sens}  (brief v0.3: ANTIORAR)")
if area < 0:
    fail.append("sensul e ORAR, briful v0.3 cere ANTIORAR")

# --- fractiile reperelor si ale POI --------------------------------------
def nearest(xy):
    best, bd = 0, 1e18
    for i, p in enumerate(rs):
        d = math.hypot(p[0] - xy[0], p[1] - xy[1])
        if d < bd:
            best, bd = i, d
    return best

print("\n--- fractii ---")
for w in WPTS:
    i = nearest((w[0], w[1]))
    print(f"  {w[4]:<16} frac {i / n:.3f}   cota {rs[i][2]:5.1f}")

# --- distante intre hazardele cu ceas ------------------------------------
print("\n--- hazarde cu ceas ---")
f_pont = nearest((-338, 24)) / n      # centrul pontoanelor (tronson 2)
f_jonca = nearest(PODET) / n
f_maimute = nearest((-206, 262)) / n
def gap(f0, f1):
    d = (f1 - f0) % 1.0
    return d * tot
print(f"  pontoane  frac {f_pont:.3f}")
print(f"  jonca     frac {f_jonca:.3f}")
print(f"  maimute   frac {f_maimute:.3f}")
g1 = gap(f_pont, f_jonca)
g2 = gap(f_jonca, f_maimute)
g3 = gap(f_maimute, f_pont)
print(f"  pontoane -> jonca:   {g1:.0f} m")
print(f"  jonca -> maimute:    {g2:.0f} m")
print(f"  maimute -> pontoane: {g3:.0f} m")
for nm, g in (("pontoane->jonca", g1), ("jonca->maimute", g2), ("maimute->pontoane", g3)):
    if g < 200.0:
        fail.append(f"hazarde cu ceas prea apropiate ({nm}: {g:.0f} m < 200)")

# --- garda de azimut: reperele se vad din locurile cerute ---------------
# Camera: jumatatea de cadru lateral ~50 grade. Reperul trebuie sa cada in
# cadru pe o fereastra de fractii, privind inainte pe traseu.
print("\n--- garda de azimut (jumatate de cadru 50 grade) ---")

def heading(i):
    a, b = rs[i], rs[(i + 1) % n]
    return math.atan2(b[1] - a[1], b[0] - a[0])

def visible(i, target):
    h = heading(i)
    dx, dy = target[0] - rs[i][0], target[1] - rs[i][1]
    ang = math.atan2(dy, dx) - h
    while ang > math.pi:
        ang -= 2 * math.pi
    while ang < -math.pi:
        ang += 2 * math.pi
    return abs(math.degrees(ang)) <= 50.0, math.hypot(dx, dy)

CHECKS = [
    ("turnurile de fundal de pe belvedere", TURNURI, 0.0, 0.0),
    ("grota de pe pontoane",                GROTA,    0.0, 0.0),
    ("satul de pe coasta",                  SAT,      0.0, 0.0),
]
# fereastra pe care se cere vizibilitatea, in fractii
WINDOWS = {
    "turnurile de fundal de pe belvedere": (nearest(BELVEDERE) / n, 0.06),
    "grota de pe pontoane":                (f_pont, 0.05),
    "satul de pe coasta":                  (f_maimute, 0.05),
}
for name, target, _, _ in CHECKS:
    f0, span = WINDOWS[name]
    i0 = int(f0 * n)
    k = max(1, int(span * n))
    seen = 0
    dists = []
    for d in range(k):
        i = (i0 + d) % n
        ok, dist = visible(i, target)
        if ok:
            seen += 1
            dists.append(dist)
    rng = f"{min(dists):.0f}-{max(dists):.0f} m" if dists else "-"
    print(f"  {name:<40} {seen}/{k} cadre   dist {rng}")
    if seen == 0:
        fail.append(f"garda de azimut: {name} nu se vede in nicio fractie din fereastra")

# --- verdict -------------------------------------------------------------
print()
if fail:
    print("PICAT:")
    for f in fail:
        print(f"  - {f}")
    sys.exit(1)
print("TOATE GARZILE TREC")
