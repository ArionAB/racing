# Genereaza traseul Angkor (Track24) din waypoints cu fillet-uri de arc -- schela din
# gen_carrara_route.py (pas uniform 12 m, viraje > 90 de grade esantionate pe arc,
# statistici ca ProbeLayout), cu garzile de geometrie din brief
# (docs/track_briefs/angkor.md §2, §7 pasul 2) verificate pe punctele coapte INAINTE sa
# existe .tscn-ul.
#
#   python tools/gen_angkor_route.py [scenes/tracks/Track24.tscn] [--plan out.png]
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z, est = +X):
# harta ajunge in lume FARA oglindire (conventia din gen_halong_route.py / gen_carrara_route.py).
#
# Sens ORAR, jungla in interiorul buclei (brief §2). Angkor Wat sta in coltul de SV, cu
# turnul central in originea hartii:
#   A calea de vest (spre E, soarele din VSV in spate, turnurile in fata) -> B prin gopura
#   de vest, pe dinauntrul galeriei (colonada pe stanga, turnurile pe dreapta), iesire prin
#   gopura de nord, calea de nord -> C Phnom Bakheng (la NV de Angkor Wat): urcarea pe flancul
#   de est si pe muchia de nord, platforma spre SUD (DEZVALUIREA: Angkor Wat in stanga-fata,
#   virajul de intrare cu concavitatea spre el), coborarea pe flancul de vest -> D calea
#   uriasilor spre N + Poarta de Sud + piata elefantului -> E Bayon spre E (terasa de 14 m)
#   -> F Terasa Elefantilor spre S, SARITURA de la capat -> G Ta Prohm spre S, ocolul pe
#   langa incinta (scurtatura prin galerie pe coarda) -> H Srah Srang (stanga) si malul
#   de sud al santului Angkor Wat (DREAPTA: intr-o bucla orara cu templul in interior,
#   santul nu poate fi in stanga — brief §2 corectat) -> coltul de SV -> A.
import math
import os
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

HALF_WIDTH = 4.5   # custom_half_width global (9 m); sectoarele (mai jos) il suprascriu

# Cote (brief §2): cale +3 (sant la 0), galerie +4, platforma Bakheng +38, Poarta de Sud +6,
# terasa Bayonului +12, coama Terasei Elefantilor +10, jungla +4..+8, intoarcerea +3.
Y_CALE = 3.0
Y_GAL = 4.0
Y_BAK = 31.0   # brief: +38; coborat ca urcarea si coborarea sa incapa in ~2,4 km la < 13%
Y_RAMPA_F = 15.0
Y_POARTA = 14.0  # brief: +6; cetatea Angkor Thom pe un dam, vezi D
Y_BAYON = 20.0
Y_TERASA = 18.0

# (x, y, fillet_r, cota, eticheta). `cota` None = interpolata pe lungime intre ancore.
WPTS = [
    # A: calea de vest, spre E, in axul turnului central (originea hartii). Linia de start la frac 0,
    # la 240 m de turn (brief §2.0: turnul de 32 m incape intreg in cadru de la >= 240 m).
    (-240.0, 0.0, 0, Y_CALE, "A start"),
    # B: un SINGUR arc (R 30) imediat dupa gopura, apoi spre N pe dinauntrul galeriei de vest:
    # colonada pe stanga, terasele si turnurile pe dreapta, la ~55 m. Trei colturi de 90 de grade la
    # 12 m (prima varianta) taiau "ritm si viteza" (brief §2, randul B); un arc pus in coltul galeriei
    # trecea la 25 m de turnuri (ele ocupa +-30 m).
    (-56.0, 0.0, 30, Y_GAL, "B arc galerie"),
    (-56.0, 104.0, 0, Y_GAL, "B cale N sfarsit"),
    # C: Phnom Bakheng. Urcarea pe flancul de est (spre N) si pe muchia de nord (spre V).
    (-56.0, 250.0, 24, None, "C colt NE"),
    (-138.0, 258.0, 18, None, "C colt NV"),
    # Platforma de sus, spre S: dezvaluirea. Virajul din coltul NV e la stanga, deci centrul lui e
    # la SE — spre Angkor Wat (concavitatea spre turnuri, brief §2.0).
    (-138.0, 224.0, 0, Y_BAK, "C platforma N"),
    (-138.0, 196.0, 0, Y_BAK, "C platforma S"),
    # Coborarea: la dreapta spre V pe muchia de sud, apoi spre N pe flancul de vest.
    (-138.0, 162.0, 16, None, "C colt SV"),
    (-230.0, 162.0, 26, None, "C colt V"),
    # D: calea uriasilor spre N, peste santul Angkor Thom, pana la Poarta de Sud. Cetatea sta pe
    # un dam (+14): coborarea de pe Bakheng are 20 m, nu 32, si incape in ~170 m la < 13%.
    (-230.0, 272.0, 0, Y_POARTA, "D cale inceput"),
    (-230.0, 382.0, 0, Y_POARTA, "D poarta"),
    # Piata de dupa poarta (elefantul traverseaza la ~22 m dupa ea), apoi la dreapta spre E.
    (-230.0, 437.0, 25, Y_POARTA, "D colt piata"),
    # E: Bayonul. Rampa de vest, terasa de 14 m, rampa de est.
    (-180.0, 437.0, 0, Y_POARTA, "E rampa V jos"),
    (-125.0, 437.0, 0, Y_BAYON, "E terasa V"),
    (-25.0, 437.0, 0, Y_BAYON, "E terasa E"),
    (30.0, 437.0, 0, Y_RAMPA_F, "E rampa E jos"),
    # F: Terasa Elefantilor, spre S. Rampa la capatul de N, coama, creasta Regelui Lepros.
    (95.0, 437.0, 28, None, "F colt"),
    (95.0, 380.0, 0, Y_RAMPA_F, "F rampa jos"),
    (95.0, 350.0, 0, Y_TERASA, "F coama inceput"),
    (95.0, 200.0, 0, Y_TERASA, "F coama sfarsit"),
    (95.0, 128.0, 0, Y_TERASA - 8.6, "F aterizare"),  # = -CREST_DROP
    # G: Ta Prohm, spre S, coborand lin spre sant. Perdeaua de liane, ocolul incintei (spre E,
    # ~145 m), scurtatura pe coarda (~110 m).
    (110.0, 112.0, 50, 9.0, "G perdea"),
    (126.0, 75.0, 30, 8.5, "G ocol intrare"),
    (230.0, 20.0, 40, 8.0, "G ocol varf"),
    (126.0, -35.0, 30, 7.0, "G ocol iesire"),
    # H: Srah Srang (stanga), apoi malul de sud al santului (dreapta), spre V.
    (130.0, -112.0, 36, None, "H colt SE"),
    (40.0, -112.0, 0, Y_CALE, "H Srah Srang V"),
    (-305.0, -112.0, 34, Y_CALE, "H colt SV"),
    (-305.0, 0.0, 30, Y_CALE, "H colt V"),
]

# Creasta Regelui Lepros: coama ramane plata pana la muchie, apoi soseaua cade 4,4 m pe UN pas de
# 12 m (37%, ca in sonda pasului 1) si continua cu o PANTA DE ATERIZARE care se indulceste pe patru
# pasi (18% -> 10% -> 5% -> 2%), ca o trambulina de schi: ce aterizeaza scurt cade pe o panta apropiata
# de traiectoria lui, nu intr-un genunchi.
#   - doua trepte de 17% (prima varianta): spline-ul rotunjea muchia pe ~24 m si doar Taxiul zbura;
#   - puncte suplimentare la 4/8 m dupa muchie: spline-ul supraincarca (32,8%), zborul scadea la 0,30 s;
#   - pas de 37% + panta de 7% (a treia): 397 de zboruri, mediana 0,58 s, dar 12 EJECTARI "perete" pe
#     16 seed-uri, toate la ~22 m dupa muchie: spline-ul uniform trecea de la -45% la -2% in ~8 m si
#     inapoi la -7% — un genunchi concav in care masinile care aterizau scurt intrau cu botul.
# Caderea de 37% e peste pragul de 22% al ProbeLayout: fereastra ei e declarata ca EXCEPTIE NUMITA
# (`metadata/jump_crests` pe nodul pistei, citita doar de tools/probe_layout.gd).
CREST_TAG = "F coama sfarsit"
CREST_PROFILE = [0.0, -4.4, -6.6, -7.8, -8.4, -8.6]   # cota fata de coama, din 12 in 12 m
CREST_DROP = -CREST_PROFILE[-1]


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
            print(f"  ATENTIE: raza la '{wpts[i][4]}' redusa la {r:.1f} m (laturi prea scurte)")
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

# Creasta: muchia e punctul de control cel mai apropiat de waypoint; cotele de dupa ea urmeaza
# CREST_PROFILE, iar cele doua dinainte raman pe coama.
crest_wi = next(i for i, w in enumerate(WPTS) if w[4] == CREST_TAG)
crest_k = next(k for k, p in enumerate(pts) if p[2] == crest_wi)
for o, dy in enumerate(CREST_PROFILE):
    elevs[crest_k + o] = Y_TERASA + dy
for o in range(1, 3):
    elevs[crest_k - o] = Y_TERASA

cum = cum_lengths(pts)
total = cum[-1]
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime: {total:.0f} m")

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


print(f"aria cu semn (harta): {signed_area(pts):+.0f}  (negativ = ORAR)")

rs = [(p[0], p[1], elevs[j]) for j, p in enumerate(pts)]
min_r, min_r_at = 1e9, 0
max_slope, max_slope_at = 0, 0
for i in range(len(rs)):
    a, b, c = rs[i - 1], rs[i], rs[(i + 1) % len(rs)]
    r = circumradius(a, b, c)
    if r < min_r:
        min_r, min_r_at = r, cum[i] / total
    d = math.hypot(c[0] - b[0], c[1] - b[1])
    sl = abs(c[2] - b[2]) / max(1e-6, d)
    if sl > max_slope:
        max_slope, max_slope_at = sl, cum[i] / total
print(f"raza minima: {min_r:.1f} m la frac {min_r_at:.3f}  (prag > latimea locala)")
print(f"panta maxima: {max_slope*100:.1f}% la frac {max_slope_at:.3f}  (ProbeLayout < 22%; urcarile < 13%)")

min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 9, len(rs)):
        if len(rs) - (j - i) <= 8:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        if d < min_sep:
            min_sep, min_sep_at = d, (cum[i] / total, cum[j] / total)
print(f"separare minima XZ: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si "
      f"{min_sep_at[1]:.3f}  (prag >= {2*HALF_WIDTH}; Bakheng: flancuri, nu benzi lipite)")

cx = sum(p[0] for p in rs) / len(rs)
cy = sum(p[1] for p in rs) / len(rs)
ext_x = max(abs(p[0] - cx) for p in rs)
ext_y = max(abs(p[1] - cy) for p in rs)
mean_elev = sum(p[2] for p in rs) / len(rs)
print(f"centroid harta ({cx:.0f}, {cy:.0f}); departare maxima de el (zidul lumii la 420): "
      f"x {ext_x:.0f}, y {ext_y:.0f}")
print(f"cota medie sosea: {mean_elev:.1f} m")

# Plasa de repunere a marii: sub cota 0 a santurilor (memoria `ziduri-invizibile-ale-lumii`).
SEA_LEVEL_TARGET_ABS = -6.0
sea_offset = round(SEA_LEVEL_TARGET_ABS - mean_elev, 2)
print(f"sea_level_offset ales: {sea_offset} (mare absoluta {SEA_LEVEL_TARGET_ABS} m)")


def section_slopes(name, t0, t1):
    f0, f1 = frac[t0], frac[t1]
    sl = []
    for i in range(len(rs)):
        f = cum[i] / total
        if f0 <= f <= f1:
            b, c = rs[i], rs[(i + 1) % len(rs)]
            d = math.hypot(c[0] - b[0], c[1] - b[1])
            sl.append((c[2] - b[2]) / max(1e-6, d))
    if sl:
        print(f"  {name:22s} {f0:.3f}-{f1:.3f}: panta medie {100*sum(sl)/len(sl):+5.1f}%  "
              f"varf {100*max(sl, key=abs):+5.1f}%")


print("\npante pe sectoare:")
section_slopes("C urcarea", "B cale N sfarsit", "C platforma N")
section_slopes("C platforma", "C platforma N", "C platforma S")
section_slopes("C-D coborarea", "C platforma S", "D cale inceput")
section_slopes("E rampa V", "E rampa V jos", "E terasa V")
section_slopes("E rampa E", "E terasa E", "E rampa E jos")
section_slopes("F rampa", "F rampa jos", "F coama inceput")
section_slopes("F creasta", "F coama sfarsit", "F aterizare")

print("\nfractii waypoint (pe lungimea poligonului de control):")
for w in WPTS:
    print(f"  {frac[w[4]]:.3f}  {w[4]}  (cota {w[3] if w[3] is not None else '-'})")


def godot(p, e):
    return (p[0], e, -p[1])


def r2(x):
    return round(x, 2)


def r3(x):
    return round(x, 3)


# ---- Ramura (scurtatura prin galeria Ta Prohm): coarda dintre intrarea si iesirea ocolului.
# Capetele nu se deseneaza (track_branch.gd): primul si ultimul punct stau la ~10 m de bucla.
# Radacina-rampa: o cocoasa de 1,2 m la 18 m inainte de iesire (sonda pasului 1).
def branch_points():
    w0 = next(w for w in WPTS if w[4] == "G ocol intrare")
    w1 = next(w for w in WPTS if w[4] == "G ocol iesire")
    e0, e1 = w0[3], w1[3]
    L = math.hypot(w1[0] - w0[0], w1[1] - w0[1])
    out = []
    s = 12.0
    while s <= L - 12.0 + 1e-6:
        t = s / L
        e = e0 + (e1 - e0) * t
        d_exit = L - s
        if abs(d_exit - 22.0) <= 4.0:
            e += 1.2 * (1.0 - abs(d_exit - 22.0) / 4.0)
        out.append((w0[0] + (w1[0] - w0[0]) * t, w0[1] + (w1[1] - w0[1]) * t, e))
        s += 10.0
    return out, L


br_pts, br_len = branch_points()
main_detour = (cum[next(j for j, p in enumerate(pts) if p[2] == next(
    i for i, w in enumerate(WPTS) if w[4] == "G ocol iesire"))]
    - cum[next(j for j, p in enumerate(pts) if p[2] == next(
        i for i, w in enumerate(WPTS) if w[4] == "G ocol intrare"))])
print(f"\nscurtatura: coarda {br_len:.0f} m fata de ocol {main_detour:.0f} m "
      f"(brief: ~110 fata de ~150)")


if PLAN_PATH:
    from PIL import Image, ImageDraw
    S = 1.2
    allx = [p[0] for p in rs]
    ally = [p[1] for p in rs]
    x0, x1, y0, y1 = min(allx) - 40, max(allx) + 40, min(ally) - 40, max(ally) + 40
    W, H = int((x1 - x0) * S), int((y1 - y0) * S)
    im = Image.new("RGB", (W, H), (235, 230, 215))
    d = ImageDraw.Draw(im)

    def px(p):
        return ((p[0] - x0) * S, H - (p[1] - y0) * S)

    # repere: turnul central Angkor Wat, cercul de 200 m si 240 m
    for rr, col in ((200, (180, 160, 120)), (240, (200, 120, 120))):
        c0 = px((-rr, rr))
        c1 = px((rr, -rr))
        d.ellipse([c0[0], c0[1], c1[0], c1[1]], outline=col)
    for i in range(len(rs)):
        a, b = rs[i], rs[(i + 1) % len(rs)]
        e = (a[2] + b[2]) / 2
        t = max(0.0, min(1.0, e / Y_BAK))
        col = (int(40 + 200 * t), int(80 + 60 * (1 - abs(t - 0.5) * 2)), int(220 - 190 * t))
        d.line([px(a), px(b)], fill=col, width=4)
    for k in range(len(br_pts) - 1):
        d.line([px(br_pts[k]), px(br_pts[k + 1])], fill=(120, 60, 20), width=2)
    for k in range(0, 100, 5):
        j = min(range(len(cum) - 1), key=lambda jj: abs(cum[jj] / total - k / 100.0))
        p = px(rs[j])
        d.text((p[0] + 5, p[1] - 10), f"{k/100:.2f}", fill=(0, 0, 0))
    for w in WPTS:
        p = px(w)
        d.ellipse([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], fill=(0, 0, 0))
    p = px((0, 0))
    d.text((p[0] + 4, p[1] + 4), "AW", fill=(150, 0, 0))
    im.save(PLAN_PATH)
    print("plan:", PLAN_PATH)


# --------------------------------------------------------------------------
# Fractiile sunt de DOUA feluri in motor (memoria `fractia-pe-index-vs-pe-lungime`):
#   idx = i/n (TrackRoute.frac_at): sectoare de latime, intervale de praf / ude
#   len = _dists[i]/total: rape, parapete, zone de sol
# Harta (x, z, idx, len) pe curba COAPTA vine din tools/data/angkor_fracmap.tsv, scrisa de
#   godot --headless --path . res://tools/ProbeCarraraFracmap.tscn -- \
#     --scene=res://scenes/tracks/Track24.tscn --out=res://tools/data/angkor_fracmap.tsv
# Doua treceri: generator (aproximativ, pe poligon) -> sonda -> generator (exact). Punctele de
# control nu se schimba intre treceri, deci harta ramane valabila cat timp traseul nu se muta.
# --------------------------------------------------------------------------
FRACMAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "angkor_fracmap.tsv")
fmap = []
if os.path.exists(FRACMAP):
    for line in open(FRACMAP, encoding="utf-8"):
        t = line.split()
        if len(t) == 4:
            fmap.append((float(t[0]), float(t[1]), float(t[2]), float(t[3])))
print(f"\nharta de fractii coapte: {'%d puncte' % len(fmap) if fmap else 'LIPSA (aprox. pe poligon)'}")

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


def s_near(x, y):
    """Lungimea pe axa a celui mai apropiat punct de (x, y) de harta."""
    best, bs = 1e18, 0.0
    for j in range(len(pts)):
        a, b = pts[j], pts[(j + 1) % len(pts)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        t = max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / max(1e-9, dx * dx + dy * dy)))
        d = math.hypot(a[0] + t * dx - x, a[1] + t * dy - y)
        if d < best:
            best, bs = d, cum[j] + t * (cum[j + 1] - cum[j])
    return bs


def F_s(sv):
    """(idx, len) la lungimea `sv` pe axa."""
    sv = sv % total
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
    return r3(F_s(tag_s[tag] + off)[0])


def LEN(tag, off=0.0):
    return r3(F_s(tag_s[tag] + off)[1])


def IDXp(x, y):
    return r3(F_s(s_near(x, y))[0])


def LENp(x, y):
    return r3(F_s(s_near(x, y))[1])


def V2(a, b):
    return f"Vector2({a}, {b})"


def V3(a, b, c):
    return f"Vector3({a}, {b}, {c})"


def V4(a, b, c, d):
    return f"Vector4({a}, {b}, {c}, {d})"


# ---- Geometria santurilor (harta). Angkor Wat: turnurile in origine, galeria la ~+-56, santul ca
# un INEL (bratele N/S/E de 38 m; bratul de V lat de 134 m, ca grila sa porneasca pe calea de
# gresie peste apa — brief §2 randul A). Rapele merg DOAR langa sosea; restul inelului e decor.
MOAT_IN = 66.0
MOAT_OUT = 104.0
MOAT_W_OUT = 200.0      # malul de vest al bratului de V
WATER_AW = 0.5          # oglinda santului Angkor Wat (cale +3)
WATER_SRAH = 0.5        # Srah Srang: aceeasi cota ca santul (umplerea rapei 0 ajunge si aici)
WATER_THOM = 11.0       # santul Angkor Thom (calea uriasilor +14)

if OUT_PATH:
    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]

    # ---- latimi (idx). Jumatati de latime; globalul 4.5 (9 m) e A, D, F, G, H.
    width_segments = [
        # B: prin templu, 8 m (de la arcul de dupa gopura pana la capatul caii de nord).
        (IDX("B arc galerie", -40.0), IDX("B cale N sfarsit"), 4.0),
        # C: Bakheng, 7 m (urcarea, platforma, coborarea pana la calea uriasilor).
        (IDX("B cale N sfarsit", 15.0), IDX("D cale inceput", -20.0), 3.5),
        # E: terasa Bayonului, 14 m (turnurile cu fete stau PE ea, pasul 6).
        (IDX("E terasa V", -10.0), IDX("E terasa E", 10.0), 7.0),
    ]
    # Poarta de Sud: deschiderea de 7 m (pilonii in afara benzii, brief §7 pasul 1, ProbeLaneClear).
    pinches = [(IDX("D poarta", -8.0), IDX("D poarta", 8.0), 3.5)]

    # ---- rape cu apa (len). Adancimea e relativa la cota MEDIATA a drumului; podeaua absoluta taie.
    ravines = [
        # 0: bratul de V al santului Angkor Wat, pe ambele parti ale caii de vest.
        (LENp(-MOAT_W_OUT, 0.0), LENp(-MOAT_IN, 0.0), 20, 0),
        # 1: bratul de N, pe ambele parti ale caii de nord.
        (LENp(-56.0, MOAT_IN), LENp(-56.0, MOAT_OUT), 20, 0),
        # 2: bratul de S, pe DREAPTA lui H (spre V, dreapta = N): turnurile oglindite.
        (LENp(MOAT_OUT, -112.0), LENp(-MOAT_W_OUT, -112.0), 20, 1),
        # 3: Srah Srang, pe STANGA lui H, imediat dupa coltul de SE.
        (LENp(92.0, -112.0), LENp(8.0, -112.0), 20, -1),
        # 4: santul Angkor Thom, pe ambele parti ale caii uriasilor.
        (LEN("D cale inceput"), LEN("D poarta", -12.0), 20, 0),
    ]
    floors = [(0, -2.0), (1, -2.0), (2, -2.0), (3, -1.5), (4, 8.5)]
    widths = [(0, 70.0), (1, 40.0), (2, 36.0), (3, 45.0), (4, 40.0)]
    water = [(0, WATER_AW, 16.0), (1, WATER_AW, 16.0), (2, WATER_AW, 16.0),
             (3, WATER_SRAH, 16.0), (4, WATER_THOM, 16.0)]

    # ---- sol (idx): laterita (praf) pe tot turul MINUS caile si terasele de piatra (brief §7 pasul 2).
    stone = sorted([
        (IDX("A start", -30.0), IDX("B arc galerie", 30.0)),         # calea de vest + gopura
        (IDXp(-56.0, 40.0), IDXp(-56.0, 112.0)),                     # gopura N + calea de nord
        (IDX("D cale inceput"), IDX("D colt piata", -20.0)),         # calea uriasilor + poarta
        (IDX("E rampa V jos"), IDX("E rampa E jos")),               # terasa Bayonului
        (IDX("F rampa jos"), IDX("F coama sfarsit")),               # Terasa Elefantilor
    ])
    dirt = []
    for k, (a, b) in enumerate(stone):
        nxt = stone[(k + 1) % len(stone)][0]
        if nxt < b:
            nxt += 1.0
        if nxt > 1.0:
            dirt.append((b, 1.0))
            dirt.append((0.0, nxt - 1.0))
        else:
            dirt.append((b, nxt))
    dirt = [(r3(a), r3(b)) for a, b in dirt if b - a > 1e-3]

    # ---- masive (coordonate Godot: gx = x, gz = -y)
    def peak(name, x, y, e, r):
        return f"""
[node name="{name}" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {e}, {-y})
gizmo_extents = {r}
script = ExtResource("2_peak")
radius_m = {r}
"""
    # Phnom Bakheng: domul sub platforma (+32), cu flancurile pe care urca si coboara soseaua.
    peaks_txt = peak("PhnomBakheng", -110.0, 205.0, Y_BAK - 2.0, 95.0)

    # ---- ramura: galeria Ta Prohm (scurtatura). Fara domino aici (pasul 5).
    br_godot = [godot(p_, p_[2]) for p_ in br_pts]
    branch_txt = """
[node name="GaleriaTaProhm" type="Path3D" parent="."]
curve = SubResource("Curve3D_galeria")
script = ExtResource("3_branch")
branch_half_width = 3.0
label = "Galeria Ta Prohm"
speed_factor = 0.85
bumpiness = 0.08
"""
    # zonele pentru sonde (fractii pe INDEX)
    zz = [("A", IDX("A start"), IDX("B arc galerie", -40.0)),
          ("B", IDX("B arc galerie", -40.0), IDX("B cale N sfarsit")),
          ("C", IDX("B cale N sfarsit"), IDX("D cale inceput")),
          ("D", IDX("D cale inceput"), IDX("E rampa V jos")),
          ("E", IDX("E rampa V jos"), IDX("F colt")),
          ("F", IDX("F colt"), IDX("F aterizare", 30.0)),
          ("G", IDX("F aterizare", 30.0), IDX("H colt SE")),
          ("H", IDX("H colt SE"), 1.0)]
    zones_meta = "metadata/zones = {" + ", ".join(
        f'"{n_}": Vector2({a_}, {b_})' for n_, a_, b_ in zz if a_ <= b_) + "}\n" + 'metadata/zone_default = "A"\n'
    # Creasta Regelui Lepros: fereastra caderii de 37% si a primului pas al pantei de aterizare (18%,
    # copt ~23%), EXCEPTIE NUMITA pentru tools/probe_layout.gd (fractii pe INDEX, de la 2 m inaintea
    # muchiei la 2 m dupa al doilea pas).
    zones_meta += (f"metadata/jump_crests = [Vector2({IDX(CREST_TAG, -2.0)}, "
                   f"{IDX(CREST_TAG, 2 * CTRL_STEP + 2.0)})]\n")

    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="3_branch"]

[sub_resource type="Curve3D" id="Curve3D_angkor"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_galeria"]
_data = {{
"points": {pva(br_godot)},
"tilts": PackedFloat32Array({", ".join("0" for _ in br_godot)})
}}
point_count = {len(br_godot)}

[node name="Track24" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Angkor"
custom_theme = "angkor"
custom_world_seed_name = "angkor"
custom_half_width = {HALF_WIDTH}
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_sea_level_offset = {sea_offset}
custom_dirt_ranges = Array[Vector2]([{", ".join(V2(a, b) for a, b in dirt)}])
custom_ravines = Array[Vector4]([{", ".join(V4(*r_) for r_ in ravines)}])
custom_ravine_floors = Array[Vector2]([{", ".join(V2(a, b) for a, b in floors)}])
custom_ravine_widths = Array[Vector2]([{", ".join(V2(a, b) for a, b in widths)}])
custom_ravine_water = Array[Vector3]([{", ".join(V3(*w_) for w_ in water)}])
custom_width_segments = Array[Vector3]([{", ".join(V3(*w_) for w_ in width_segments)}])
custom_width_pinches = Array[Vector3]([{", ".join(V3(*w_) for w_ in pinches)}])
terrain_pad_m = 120.0
{zones_meta}
[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_angkor")

[node name="Peaks" type="Node3D" parent="."]
{peaks_txt}{branch_txt}"""
    with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {OUT_PATH}")
    print(f"  praf (idx): {dirt}")
    print(f"  rape (len): {ravines}")
    print(f"  latimi (idx): {width_segments}")
    print(f"  zone: {zz}")
