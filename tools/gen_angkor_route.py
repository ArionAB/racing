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
Y_PIATA = 14.0   # piata regala, sub fata de 4 m a Terasei Elefantilor
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
    # E: Bayonul. Rampa de vest, terasa de 14 m, rampa de est care coboara in PIATA REGALA (+14).
    (-180.0, 437.0, 0, Y_POARTA, "E rampa V jos"),
    (-125.0, 437.0, 0, Y_BAYON, "E terasa V"),
    (-30.0, 437.0, 0, Y_BAYON, "E terasa E"),
    (22.0, 437.0, 0, Y_PIATA, "E rampa E jos"),
    # F: Terasa Elefantilor, spre S. Din piata, drumul o ia pe DIAGONALA spre SE si urca pe terasa
    # prin capatul ei de nord: pe diagonala, fata de vest (4 m, sculptata) sta la ~30 de grade in
    # dreapta-fata — "drumul vine spre terasa din piata Bayonului in unghi" (brief §2.0). Prima
    # varianta urca pe terasa din lateral si mergea pe coama paralel cu fata: captura --gamecam n-a
    # aratat-o niciodata (memoria `perete-paralel-nu-se-vede`).
    (52.0, 437.0, 30, Y_PIATA, "F colt piata"),
    (112.0, 377.0, 30, Y_TERASA, "F colt terasa"),
    (112.0, 350.0, 0, Y_TERASA, "F coama inceput"),
    (112.0, 200.0, 0, Y_TERASA, "F coama sfarsit"),
    (112.0, 128.0, 0, Y_TERASA - 8.6, "F aterizare"),  # = -CREST_DROP
    # G: Ta Prohm, spre S, coborand lin spre sant. Perdeaua de liane (pasul 6, dupa aterizare),
    # ocolul incintei (spre E, ~165 m), scurtatura pe coarda (~110 m).
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
section_slopes("F diagonala", "F colt piata", "F colt terasa")
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
        # Val 2: cocoasa de 1,2 m (sonda pasului 1) a iesit din profil: o inlocuieste
        # `giant_root_ramp.glb` (coliziune mesh, buza la 22 m inaintea iesirii).
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


def elev_at(sv):
    """Cota soselei la lungimea `sv` (interpolata pe punctele reesantionate)."""
    sv = sv % total
    for j in range(len(pts)):
        if cum[j] <= sv <= cum[j + 1]:
            f = (sv - cum[j]) / max(1e-9, cum[j + 1] - cum[j])
            return elevs[j] + (elevs[(j + 1) % len(pts)] - elevs[j]) * f
    return elevs[0]


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
# Malul de EST al bratului de V (kit val 1, gopura de vest): pana la val 1 santul mergea pana la
# x=-66, adica pana in arcul R30 al lui B (soseaua coteste de la x~-85). Gopura de 52 m n-avea unde
# sta: in arc sau cu galeriile in apa. Malul de est se muta la -104 -> o terasa de 38 m pe care stau
# galeriile, cu gopura pe dreapta (x -103..-92), inaintea arcului.
MOAT_IN_W = 104.0
GOPURA_X = -97.5
TREE_GATE_S = 26.0      # poarta-copac pe ramura. 14 m: ramura inca se racorda la bucla (ProbeLaneClear pe banda
                        # -1,5). 22 m: aripa de est la ~4 m de virajul buclei (ProbeRace val 1: 1 ejectare + 1 blocaj
                        # langa ea). 26 m: primul bloc al dominoului se muta de la 30 la 33 m (in spatele portii).
WATER_AW = 0.5          # oglinda santului Angkor Wat (cale +3)

# Apa de JAD (gauntlet POI, piesa S): bara = verde-albastrui saturat, opac, fara turcoazul luminos al
# recifului si fara spuma alba (`water_foam` 0: malul nu mai e banda cian). Culorile merg prin
# `water_tint` (calibrare pe CPU); scriem RGB direct, nu slot nou de paleta. Cota apei ramane cea din
# `custom_ravine_water` (lotusii stau pe ea). Stil = scena, deci alte piste nu se misca.
JADE_STYLE = chr(10).join([
    "{",
    '"ravines": Array[int]([0, 1, 2, 3, 4]),',
    '"water_shallow_rgb": Color(0.27, 0.44, 0.34, 1),',
    '"water_deep_rgb": Color(0.10, 0.30, 0.20, 1),',
    '"water_shore_rgb": Color(0.20, 0.34, 0.18, 1),',
    '"water_dim": 0.9,',
    '"water_foam": 0.0,',
    '"water_crest": 0.0,',
    '"water_band": 0.0,',
    '"water_wave_amp_k": 0.25,',
    '"water_glint": 0.10',
    "}"])
WATER_SRAH = 0.5        # Srah Srang: aceeasi cota ca santul (umplerea rapei 0 ajunge si aici)
WATER_THOM = 11.0       # santul Angkor Thom (calea uriasilor +14)
DOMINO_PERIOD = 11.0    # ceasul dominoului (brief §2: nu imparte turul de ~79 s)
ELEPHANT_AFTER_GATE = 22.0
# Faza traversarii (HazardMarker.sweep_phase). Cu faza derivata din fractie, plutonul din turul 1
# ajungea in piata exact cand elefantul traversa: 9-41 s oprite pe seed (16 seed-uri). Pe 4 faze x
# 4 seed-uri: 0,0 -> 13,4 s / seed, 0,25 -> 8,7, 0,5 -> 12,3, 0,75 -> 7,1 (si turul mediu cel mai mic).
# ANGKOR_ELEPHANT_PHASE suprascrie, pentru variante A/B.
ELEPHANT_PHASE = float(os.environ.get("ANGKOR_ELEPHANT_PHASE", "0.75"))

# ---- PASUL 6 (brief §7): mecanicile ramase.
# Turnurile Bayonului pe terasa E — decizia V2 din sondele pasului 1 (brief §7 pasul 1): 3 turnuri
# de 3 x 3 m LANGA AXA (+-1 m), trecere pe ambele parti, `custom_lane_bias` 0,62 pe tot sectorul
# (tiparul stalpilor Carrara: pilotul ramane pe malul lui). Pe sonda: 2 ejectari / 6 seed-uri,
# 0 blocaje. Decalate +-3 m (desenul vechi din §2) dadeau ~29 de repuneri pe seed — NU.
# (s fata de "E terasa V", offset lateral pe harta in y; terasa are 95 m.)
BAYON_TOWERS = [(15.0, -1.0), (48.0, 1.0), (81.0, -1.0)]
BAYON_TOWER_SIZE = (3.0, 9.0, 3.0)
# 0,62 pe sonda; pe pista reala (pasul 6, 16 seed-uri) 4 din cele 5 ejectari pe turnuri au venit
# IN PLOAIE (grip ud): culoarul de 0,74 m dintre linie si turn nu ajungea. 0,72 lasa ~1,4 m.
BAYON_BIAS = 0.72
# Musonul (brief §3 „Ceasuri care nu impart durata turului”): ~137 s, nu multiplu de ~75 s.
# Cursa porneste pe USCAT (memoria `ceasul-porneste-in-prima-faza`: la ceasul 0 RainCycle e in
# telegraf); prima ploaie (inceputul telegrafului) la ~50 s, pe turul 1, in cetate.
RAIN_PERIOD = 137.0
RAIN_FIRST_AT = 50.0
# Perdeaua de liane (POI G): pe bucla PRINCIPALA, imediat dupa bifurcatia scurtaturii — la
# bifurcatie jucatorul vede un „zid verde” pe ocol si galeria cu dominoul pe coarda: hazardul fals
# contra celui real. (s dupa "G ocol intrare").
CURTAIN_AFTER_FORK = float(os.environ.get("ANGKOR_CURTAIN_AFTER_FORK", "40.0"))

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
        (LENp(-MOAT_W_OUT, 0.0), LENp(-MOAT_IN_W, 0.0), 20, 0),
        # 1: bratul de N, pe ambele parti ale caii de nord.
        (LENp(-56.0, MOAT_IN), LENp(-56.0, MOAT_OUT), 20, 0),
        # 2: bratul de S, pe DREAPTA lui H (spre V, dreapta = N): turnurile oglindite.
        (LENp(MOAT_OUT, -112.0), LENp(-MOAT_W_OUT, -112.0), 20, 1),
        # 3: Srah Srang, pe STANGA lui H, imediat dupa coltul de SE.
        (LENp(92.0, -112.0), LENp(8.0, -112.0), 20, -1),
        # 4: santul Angkor Thom, pe ambele parti ale caii uriasilor.
        (LEN("D cale inceput"), LEN("D poarta", -12.0), 20, 0),
    ]
    # PIATA REGALA (brief §2 randul F): platou de banc (`custom_bench_patches`, tiparul gradonilor
    # Carrara) la +14, cu marginea de EST DURA pe linia fetei Terasei Elefantilor (marginea dreapta a
    # coamei): caderea de 4 m e verticala. O rapa-cornisa (prima incercare) cobora terenul doar in
    # panta, pe grila de 7,92 m: din fata ieseau ~1,5 m. Celelalte margini sunt moi: spre S piata se
    # scurge in panta de aterizare, ca o masina cazuta de pe coama sa revina fara repunere.
    face_x = next(w for w in WPTS if w[4] == CREST_TAG)[0] - HALF_WIDTH - 0.5
    face_y0 = next(w for w in WPTS if w[4] == CREST_TAG)[1]
    face_y1 = next(w for w in WPTS if w[4] == "F coama inceput")[1] + 16.0
    bench = [(face_x - 47.0, face_x, face_y0, face_y1, Y_PIATA + 0.3, 25.0, 0.0, 15.0, 30.0)]
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
        (IDX("F colt terasa"), IDX("F coama sfarsit")),             # Terasa Elefantilor
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

    # ---- PASUL 6: balustradele de gresie (stil 3 in Track._build_parapets) pe caile peste sant.
    # Fractii pe LUNGIME. Pasul 3 a gasit 2 `[blocaj]` in gramada de la start: masini impinse peste
    # marginea caii de vest, pe malul santului — balustrada le inchide. Calea de vest are cate UN gol
    # pe fiecare parte (brief §2 randul A: „singurele locuri unde cazi in sant”, punctuatie, nu
    # regula), dincolo de gramada de la start (x < -140); calea uriasilor (D) e continua: uriasii
    # care tin naga sunt zidurile ei (drafting si imbranceli).
    GAP = 7.0

    # 4 zecimale, nu 3: pe un tur de 2.432 m pasul de 0,001 e 2,4 m, iar un gol de 7 m iesea 4 sau
    # 12 m (masurat cu tools/probe_angkor_pas6.gd).
    def lenx(x):
        return round(F_s(s_near(x, 0.0))[1], 4)
    parapets = [
        # calea de vest, latura +1: de la malul de vest la gol, apoi de la gol la gopura
        (lenx(-198.0), lenx(-120.0 - GAP / 2), 1, 3), (lenx(-120.0 + GAP / 2), lenx(-MOAT_IN_W - 2.0), 1, 3),
        # latura -1, golul mai departe
        # golul de pe -1 era la -95: cu malul mutat la -104 cadea pe uscat (val 1) -> -140
        (lenx(-198.0), lenx(-140.0 - GAP / 2), -1, 3), (lenx(-140.0 + GAP / 2), lenx(-MOAT_IN_W - 2.0), -1, 3),
        # calea uriasilor, ambele laturi, pana inaintea pilonilor portii
        (LEN("D cale inceput", 2.0), LEN("D poarta", -10.0), 0, 3),
        # Srah Srang, STANGA (spre bazin), de la iesirea din coltul de SE pana dupa bazin. Prima
        # rulare a pasului 6 (16 seed-uri): 22 de `[blocaj]` la frac 0,78-0,84, TOATE la sfarsitul
        # ploii — pe ud, masinile ies largi din virajul la dreapta de SE si cad pe malul bazinului,
        # cu 1 m sub sosea, de unde nu mai urca (prag lateral > 0,3 m = zid). Pe uscat: 0.
        (round(F_s(s_near(100.0, -112.0))[1], 4), round(F_s(s_near(4.0, -112.0))[1], 4), -1, 3),
        # Malul santului Angkor Wat, DREAPTA lui H (rapa 2), pana inaintea virajului de vest. A doua
        # rulare (cu stanga inchisa): 4 `[blocaj]` + 3 repuneri, toate in prima ploaie si toate pe
        # DREAPTA, cu Autobuzul: rapa 2 n-are apa (avertismentul „rapa 2 n-are nicio celula sub 0.5”,
        # preexistent pe main), deci masina cazuta nu intra in plasa de apa — ramane in santul uscat,
        # cu 1 m sub sosea. Balustrada joasa nu ascunde reflexia de la camera de joc (10 m).
        (round(F_s(s_near(100.0, -112.0))[1], 4), round(F_s(s_near(-196.0, -112.0))[1], 4), 1, 3),
    ]

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
    # Val 1: tema `angkor` n-are `branch_surface`, deci banda iesea pe implicit (nisip in culoarea
    # ierbii): din bucla nu se vedea nicio scurtatura, iar poarta-copac statea in pajiste. `surface = 3`
    # (GRAVEL) in tenta gresiei/lateritei (brief §3: „molozul din scurtatura”). Comentariile NU intra in
    # textul .tscn: un `#` intre proprietati opreste parserul (memoria `tscn-comentariu-taie-proprietati`).
    br_godot = [godot(p_, p_[2]) for p_ in br_pts]
    branch_txt = """
[node name="GaleriaTaProhm" type="Path3D" parent="."]
curve = SubResource("Curve3D_galeria")
script = ExtResource("3_branch")
branch_half_width = 3.0
label = "Galeria Ta Prohm"
speed_factor = 0.85
bumpiness = 0.08
tint = Color(0.78, 0.6, 0.48, 1)
"""
    # ---- HAZARDURILE-SEMNATURA (pasul 5). Parametrii sunt cei validati de sondele pasului 1.
    # Dominoul din galeria Ta Prohm: 3 x RimBoulderHazard la 25 m unul de altul. Nodul sta pe asfalt, in
    # punctul de impact, cu +X local spre peretele de pe care cade blocul: aici peretele de VEST al
    # galeriei (rotatie de 180 de grade in jurul lui Y; matricea e simetrica, deci nu conteaza ordinea
    # randuri/coloane). `start_clock` mai mare = cade mai devreme: cel mai INDEPARTAT are 2,4, deci
    # valul vine spre masina. Modelul ramane bolovanul implicit pe clasa temei (`rockfall_class`)
    # pana la blocul de bolta (hero-asset, pasul 7).
    w_in = next(w for w in WPTS if w[4] == "G ocol intrare")
    w_out = next(w for w in WPTS if w[4] == "G ocol iesire")
    hz_txt = ""
    for k_, (s_, clk_) in enumerate(((33.0, 0.0), (55.0, 1.2), (80.0, 2.4))):
        t_ = s_ / br_len
        bx_ = w_in[0] + (w_out[0] - w_in[0]) * t_
        by_ = w_in[1] + (w_out[1] - w_in[1]) * t_
        be_ = w_in[3] + (w_out[3] - w_in[3]) * t_
        hz_txt += f"""
[node name="Domino{k_}" type="Node3D" parent="Hazarduri"]
transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, {r2(bx_)}, {r2(be_)}, {r2(-by_)})
script = ExtResource("4_rim")
period = {DOMINO_PERIOD}
start_clock = {clk_}
rim_offset = 2.0
rim_height = 6.0
crush_seconds = 3.0
invert_steer = false
model = ExtResource("22_block")
model_scale = 1.0
"""
    # Elefantul de la Poarta de Sud: SlidingHazard TRAVERSARE prin HazardMarker (tiparul G_Elefant din
    # Track14), in piata de DUPA poarta, la 22 m. sweep_speed 3 m/s -> ciclul ~23 s; `ai_yields`: AI-ul
    # il vede prin CROSSING_GROUP (incetineste si ocoleste), aceeasi informatie ca jucatorul. Modelul e
    # `asian_elephant.glb` (kit §1.3, val 1), cu cheile lui in world_prop.gd si sliding_hazard.gd.
    ex_, ey_ = pos_at(tag_s["D poarta"] + ELEPHANT_AFTER_GATE)
    hz_txt += f"""
[node name="ElefantPoarta" type="Marker3D" parent="Hazarduri"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(ex_)}, {Y_POARTA}, {r2(-ey_)})
script = ExtResource("5_hzm")
model = ExtResource("6_eleph")
model_classes = {{
"Elephant_Mesh_Accente": "tri:elephant_hide"
}}
face_travel = true
follow_ground = true
motion = 1
sweep_speed = 3.0
ai_yields = true
""" + (f"sweep_phase = {ELEPHANT_PHASE}\n" if ELEPHANT_PHASE >= 0.0 else "")
    # ---- PASUL 6: turnurile Bayonului (corpuri statice cu nume, ca ProbeLaneClear sa le raporteze
    # pe nume). Corpul ramane si dupa hero-asset: `bayon_face_tower_a` (pasul 7) e doar vizualul,
    # in DecorManual, ca la stalpii Carrara.
    e0 = tag_s["E terasa V"]
    towers_txt = ""
    decor_txt = ""
    for k_, (ds_, off_) in enumerate(BAYON_TOWERS):
        tx_, ty_ = pos_at(e0 + ds_)
        ty_ += off_
        tz_ = Y_BAYON + BAYON_TOWER_SIZE[1] * 0.5 - 1.0   # 1 m sub terasa, ca sa nu ramana fanta
        towers_txt += f"""
[node name="BayonTurn{k_}" type="StaticBody3D" parent="Obstacole"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(tx_)}, {r2(tz_)}, {r2(-ty_)})

[node name="Forma" type="CollisionShape3D" parent="Obstacole/BayonTurn{k_}"]
shape = SubResource("Box_bayon")

"""
        # Vizualul (pasul 7, kit §1.1): `bayon_face_tower_a.glb` in DecorManual, FARA corp
        # (`coliziune="none"`): coliziunea ramane cutia de mai sus, pe care modelul o umple exact
        # (originea la baza, deci baza cutiei = 1 m sub terasa). Variantele a, b, c (kit §1.1, val 1).
        decor_txt += f"""
[node name="Bayon{"ABC"[k_]}{k_}" parent="DecorManual" instance=ExtResource("{("10_bayon", "12_bayon_b", "13_bayon_c")[k_]}")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(tx_)}, {r2(Y_BAYON - 1.0)}, {r2(-ty_)})
metadata/coliziune = "none"
"""
    # ---- VAL 1 (kit §1.2): portile prin care treci, cu `coliziune="mesh"` (carcasa convexa implicita
    # ar astupa deschiderea, brief §7 pasul 1) si cate un CameraZone cu tavanul declarat (memoria
    # `camera-zone-tavan-per-sala`: implicitul de 15 m nu corecteaza nimic sub un buiandrug de 8-9 m).
    # Baza fiecarui model = cota soselei in punctul lui; drumul trece pe -Z al modelului (+Y Blender).
    gx_, gy_ = pos_at(tag_s["D poarta"])
    ge_ = elev_at(tag_s["D poarta"])
    decor_txt += f"""
[node name="PoartaDeSud" parent="DecorManual" instance=ExtResource("14_gate_s")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(gx_)}, {r2(ge_)}, {r2(-gy_)})
metadata/coliziune = "mesh"
"""
    # Gopura de vest: soseaua merge spre +X, modelul o vrea pe -Z -> rotatie de -90 de grade in jurul
    # lui Y; randurile bazei: (0,0,-1), (0,1,0), (1,0,0) (memoria `tscn-transform-e-pe-randuri`).
    gs_ = s_near(GOPURA_X, 0.0)
    gpx_, gpy_ = pos_at(gs_)
    decor_txt += f"""
[node name="GopuraVest" parent="DecorManual" instance=ExtResource("15_gopura")]
transform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, {r2(gpx_)}, {r2(elev_at(gs_))}, {r2(-gpy_)})
metadata/coliziune = "mesh"
"""
    # Poarta-copac: la intrarea ramurii, care merge spre S (+Z Godot) -> rotatie de 180 de grade, LATA de
    # 1,45 ori (golul 9,9 m; la 1,2 ProbeRace val 3 mai gasea 2 ejectari pe stalpi). Istoric:
    # 1,2 ori de-a curmezisul (golul 6,8 -> 8,2 m): ProbeRace val 2, masinile care intra in ramura pe
    # linia virajului loveau stalpul portii la 28 m/s. Suprafata ramurii ramane reteta temei (nisipul de
    # la pasul 6) cu tenta; GRAVEL (incercat la val 1) aducea doua ejectari noi la iesirea ramurii.
    tb0_ = next(w for w in WPTS if w[4] == "G ocol intrare")
    tb1_ = next(w for w in WPTS if w[4] == "G ocol iesire")
    tbl_ = math.hypot(tb1_[0] - tb0_[0], tb1_[1] - tb0_[1])
    tt_ = TREE_GATE_S / tbl_
    tgx_ = tb0_[0] + (tb1_[0] - tb0_[0]) * tt_
    tgy_ = tb0_[1] + (tb1_[1] - tb0_[1]) * tt_
    tge_ = tb0_[3] + (tb1_[3] - tb0_[3]) * tt_
    decor_txt += f"""
[node name="PoartaCopac" parent="DecorManual" instance=ExtResource("16_treegate")]
transform = Transform3D(-1.45, 0, 0, 0, 1, 0, 0, 0, -1, {r2(tgx_)}, {r2(tge_)}, {r2(-tgy_)})
metadata/coliziune = "mesh"
"""
    cam_txt = f"""
[node name="CameraPoartaDeSud" type="Area3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(gx_)}, {r2(ge_)}, {r2(-gy_)})
script = ExtResource("17_camzone")
frac_from = {r3(IDX("D poarta", -14.0))}
frac_to = {r3(IDX("D poarta", 10.0))}
size = Vector3(12.0, 10.0, 24.0)
ceiling = 8.4
ceiling_dist = 20.0
blend_time = 0.35

[node name="CameraGopura" type="Area3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(gpx_)}, {r2(elev_at(gs_))}, {r2(-gpy_)})
script = ExtResource("17_camzone")
frac_from = {r3(F_s(gs_ - 16.0)[0])}
frac_to = {r3(F_s(gs_ + 12.0)[0])}
size = Vector3(28.0, 10.0, 14.0)
ceiling = 9.0
ceiling_dist = 22.0
blend_time = 0.35

[node name="CameraPoartaCopac" type="Area3D" parent="."]
transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, {r2(tgx_)}, {r2(tge_)}, {r2(-tgy_)})
script = ExtResource("17_camzone")
size = Vector3(10.0, 8.0, 22.0)
ceiling = 5.6
ceiling_dist = 16.0
blend_time = 0.35
"""
    # ---- VAL 2 (kit §1.4, §1.5): balustradele naga si uriasii pe LINIA zidului din cod (stil 3,
    # `Track._build_parapets`: marginea + PARAPET_GAP 0,25, grosimea 0,5, capatul dinspre masini
    # desfacut cu BALUSTRADE_FLARE_OUT 2,5 m pe BALUSTRADE_FLARE_M 16 m), cu tema `balustrade_skin`:
    # zidul ramane doar coliziune, modulele sunt vizualul (coliziune "none"). Latura +1 = DREAPTA
    # sensului (`_side_at` = dir x UP). Orientarea: X = spre exterior, Y = sus, Z = X x Y.
    def _rows(X, Y, Z):
        return (f"{r3(X[0])}, {r3(Y[0])}, {r3(Z[0])}, {r3(X[1])}, {r3(Y[1])}, {r3(Z[1])}, "
                f"{r3(X[2])}, {r3(Y[2])}, {r3(Z[2])}")

    def _cross(a, b):
        return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])

    _len_tab = [(sv_, F_s(sv_)[1]) for sv_ in [k_ * 0.5 for k_ in range(int(total / 0.5))]]

    def s_of_len(L):
        return min(_len_tab, key=lambda t: abs(t[1] - L))[0]

    def wall_pt(sv, sign, s_first, extra=0.0):
        """Punct pe axa zidului (harta) + tangenta lui (harta), cu desfacerea capatului."""
        def raw(u):
            px, py = pos_at(u)
            ax, ay = pos_at(u + 0.5)
            bx, by = pos_at(u - 0.5)
            tx, ty = ax - bx, ay - by
            n = math.hypot(tx, ty)
            tx, ty = tx / n, ty / n
            k = min(1.0, max(0.0, u - s_first) / 16.0)
            fl = 2.5 * (1.0 - (k * k * (3.0 - 2.0 * k)))
            off = HALF_WIDTH + 0.25 + 0.25 + fl + extra
            # dreapta sensului pe harta: (ty, -tx)
            return px + ty * sign * off, py - tx * sign * off
        x0, y0 = raw(sv)
        x1, y1 = raw(sv + 1.0)
        tx, ty = x1 - x0, y1 - y0
        n = math.hypot(tx, ty)
        return x0, y0, tx / n, ty / n

    def g_basis_out(tx, ty, sign):
        # in Godot: dir = (tx, 0, -ty); exteriorul = dreapta * sign = (ty, 0, tx) * sign
        X = (ty * sign, 0.0, tx * sign)
        Y = (0.0, 1.0, 0.0)
        return X, Y, _cross(X, Y)

    def g_basis_fwd(tx, ty, back=False):
        Z = (tx, 0.0, -ty) if not back else (-tx, 0.0, ty)
        Y = (0.0, 1.0, 0.0)
        return _cross(Y, Z), Y, Z

    def place(name, rid, X, Y, Z, gx, gy, gz, col="none", anchor=None):
        # `anchor` = `metadata/ancora_sol` (punct LOCAL, tools/probe_manual.gd): fata terasei are
        # originea sub coama pe care o sustine; solul ei e piata, in fata fetei.
        an = "" if anchor is None else f"metadata/ancora_sol = Vector3({anchor[0]}, {anchor[1]}, {anchor[2]})\n"
        return an_wrap(name, rid, X, Y, Z, gx, gy, gz, col) + an

    def an_wrap(name, rid, X, Y, Z, gx, gy, gz, col):
        return (f'\n[node name="{name}" parent="DecorManual" instance=ExtResource("{rid}")]\n'
                f"transform = Transform3D({_rows(X, Y, Z)}, {r2(gx)}, {r2(gy)}, {r2(gz)})\n"
                f'metadata/coliziune = "{col}"\n')

    nb_ = 0
    for (L0, L1, side_, sty_) in parapets:
        s0_, s1_ = s_of_len(L0), s_of_len(L1)
        giants_ = abs(L0 - LEN("D cale inceput", 2.0)) < 1e-4
        for sign_ in ((-1.0, 1.0) if side_ == 0 else (float(side_),)):
            # capul naga la inceputul segmentului (spre masinile care vin), pe linia desfacuta
            hx_, hy_, htx_, hty_ = wall_pt(s0_, sign_, s0_)
            X_, Y_, Z_ = g_basis_fwd(htx_, hty_)
            decor_txt += place(f"NagaCap{nb_}", "19_nagahead", X_, Y_, Z_, hx_, elev_at(s0_), -hy_)
            nb_ += 1
            sv_ = s0_ + 2.0
            k_ = 0
            while sv_ <= s1_ - 2.0 + 1e-6:
                if giants_:
                    rid_ = "20_deva" if sign_ < 0 else "21_asura"
                    wx_, wy_, wtx_, wty_ = wall_pt(sv_, sign_, s0_, extra=0.55)
                else:
                    rid_ = "18_naga"
                    wx_, wy_, wtx_, wty_ = wall_pt(sv_, sign_, s0_)
                X_, Y_, Z_ = g_basis_out(wtx_, wty_, sign_)
                decor_txt += place(f"{'Urias' if giants_ else 'Naga'}{nb_}_{k_}", rid_, X_, Y_, Z_,
                                   wx_, elev_at(sv_), -wy_)
                sv_ += 4.0
                k_ += 1
            # cap si la celalalt capat, privind inainte
            ex_, ey_, etx_, ety_ = wall_pt(s1_, sign_, s0_)
            X_, Y_, Z_ = g_basis_fwd(etx_, ety_, back=True)
            decor_txt += place(f"NagaCap{nb_}", "19_nagahead", X_, Y_, Z_, ex_, elev_at(s1_), -ey_)
            nb_ += 1

    # Terasa Elefantilor (kit §1.4): fata sculptata (+X model) spre VEST (piata) -> rotatie de 180 de
    # grade; fata cade pe linia muchiei dure a platoului (face_x), baza la cota pietei, varful = coama.
    tf_x = face_x + 0.71
    tf_n = int((face_y1 - face_y0) // 8.0)
    for k_ in range(tf_n):
        cy_ = face_y0 + 4.0 + 8.0 * k_
        decor_txt += place(f"Terasa{k_}", "23_terrace", (-1, 0, 0), (0, 1, 0), (0, 0, -1), tf_x, Y_PIATA, -cy_,
                           anchor=(1.2, 0, 0))
        if k_ % 3 == 2:
            decor_txt += place(f"StalpTrompa{k_}", "25_pillar", (-1, 0, 0), (0, 1, 0), (0, 0, -1),
                               face_x + 0.4, Y_PIATA, -(cy_ + 4.0), anchor=(1.3, 0, 0))
    decor_txt += place("TerasaCapat", "24_terrace_end", (-1, 0, 0), (0, 1, 0), (0, 0, -1),
                       tf_x, Y_PIATA, -(face_y0 + 8.0 * tf_n + 3.97), anchor=(1.2, 0, 0))
    # Regele Lepros: in piata, la capatul de sud al fetei, in afara benzii, privind spre drum (+X lume).
    decor_txt += place("RegeleLepros", "26_leper", (0, 0, 1), (0, 1, 0), (-1, 0, 0),
                       face_x - 7.0, Y_PIATA + 0.3, -(face_y0 + 10.0), col="hull")

    # Galeria Ta Prohm (kit §1.5): bolti de 4 m pe ramura, prabusite (`vault_broken`) unde cade dominoul,
    # cu partea deschisa (+X model) spre peretele de VEST (rotatie de 180: +X model -> -X lume), ca
    # nodurile `Domino*`. Peretii boltilor au corp (`mesh`): sunt peretii galeriei.
    gw0_ = next(w for w in WPTS if w[4] == "G ocol intrare")
    gw1_ = next(w for w in WPTS if w[4] == "G ocol iesire")
    gL_ = math.hypot(gw1_[0] - gw0_[0], gw1_[1] - gw0_[1])

    def br_at(sv):
        t = sv / gL_
        return (gw0_[0] + (gw1_[0] - gw0_[0]) * t, gw0_[1] + (gw1_[1] - gw0_[1]) * t,
                gw0_[3] + (gw1_[3] - gw0_[3]) * t)

    broken_ = [33.0, 55.0, 80.0]
    # boltile se opresc la 82 (capatul boltii prabusite de la 80): o bolta peste rampa (prima
    # integrare) prindea masinile urcate cu 1,2 m in corbele (ProbeLaneClear, `Bolta11`).
    edges_ = [TREE_GATE_S + 6.5] + [b for bk in broken_ for b in (bk - 2.0, bk + 2.0)][:-1] + [82.0]
    spans_ = []
    for a_, b_ in zip(edges_[0::2], edges_[1::2]):
        if b_ - a_ > 0.5:
            n_ = max(1, math.ceil((b_ - a_) / 4.0))
            for j_ in range(n_):
                spans_.append(a_ + (b_ - a_) * (j_ + 0.5) / n_)
    for j_, sv_ in enumerate(spans_):
        bx_, by_, be_ = br_at(sv_)
        decor_txt += place(f"Bolta{j_}", "27_vault", (-1, 0, 0), (0, 1, 0), (0, 0, -1), bx_, be_, -by_, col="mesh")
    for j_, sv_ in enumerate(broken_):
        bx_, by_, be_ = br_at(sv_)
        decor_txt += place(f"BoltaPrabusita{j_}", "28_vault_b", (-1, 0, 0), (0, 1, 0), (0, 0, -1),
                           bx_, be_, -by_, col="mesh")
    # Radacina-rampa: buza la 18 m inaintea capatului ramurii (cocoasa veche era la 22; mutata ca sa
    # nu stea sub bolta prabusita de la 80 m); modelul urca spre -Z, rotit cu 180 de grade.
    rx_, ry_, re_ = br_at(gL_ - 18.0 - 4.43)
    # Cota: banda de nisip a ramurii sta la ~0,13 m SUB cota punctelor ei (sonda tools/sv_angkor_rampa.gd), deci
    # rampa pusa pe cota punctelor avea muchia de jos ca o bordura de 13 cm: ProbeRace val 2, 5 ejectari
    # „perete” la ~40 m/s fix pe muchie. Coborata cu 0,15 m: muchia intra sub nisip.
    decor_txt += place("RadacinaRampa", "29_ramp", (-1, 0, 0), (0, 1, 0), (0, 0, -1), rx_, re_ - 0.15, -ry_, col="mesh")
    gc0_ = br_at(TREE_GATE_S + 6.0)
    gc1_ = br_at(84.0)
    cam_txt += f"""
[node name="CameraGaleria" type="Area3D" parent="."]
transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, {r2((gc0_[0] + gc1_[0]) / 2)}, {r2((gc0_[2] + gc1_[2]) / 2)}, {r2(-(gc0_[1] + gc1_[1]) / 2)})
script = ExtResource("17_camzone")
size = Vector3(12.0, 9.0, {r2(abs(gc1_[1] - gc0_[1]) + 4.0)})
ceiling = 6.6
ceiling_dist = 16.0
blend_time = 0.35
"""
    # ---- VAL 3-4 (kit §1.2, §1.4-§1.7): piesele mari ale locului. Decor (coliziune "none") in afara
    # benzii, cu exceptia templului (corp pe carcasa; e departe de drum, in mijlocul inelului de sant).
    # Junglă in masa (scatter) = pasul 8 al brief-ului; aici doar reperele asezate de mana.
    R90N = ((0, 0, -1), (0, 1, 0), (1, 0, 0))   # model -Z -> lume +X (fata spre est)
    R90P = ((0, 0, 1), (0, 1, 0), (-1, 0, 0))   # model -Z -> lume -X (fata spre vest)
    R180 = ((-1, 0, 0), (0, 1, 0), (0, 0, -1))
    RID = ((1, 0, 0), (0, 1, 0), (0, 0, 1))

    def put(name, rid, R, gx, gy, gz, col="none", anchor=None):
        X = (R[0][0], R[1][0], R[2][0])
        Y = (R[0][1], R[1][1], R[2][1])
        Z = (R[0][2], R[1][2], R[2][2])
        return place(name, rid, X, Y, Z, gx, gy, gz, col, anchor)

    # Angkor Wat: in locul machetelor, aceleasi cote (varful central +36, colturile +30, baza la 0),
    # fata cu scara (+Y Blender = -Z model) spre VEST, spre calea de start.
    # Soclul in trepte e ingropat ~4 m (terenul are +4 in centrul inelului), ca si machetele: varfurile
    # raman la +36 / +30, cotele verificate in brief §2.0. Ancora de sol pe treapta soclului.
    decor_txt += put("AngkorWat", "30_temple", R90P, 0.0, 0.0, 0.0, col="hull", anchor=(31.0, 4.1, 0.0))

    # Galeria de vest a incintei, pe stanga lui B (spre vest), pe uscat intre arc si santul de nord
    # (y 24..60): stalpi la x = -62, acoperisul pe ei, zidul cu basorelief la -66,3, relieful spre drum.
    for k_ in range(9):
        gy_ = 26.0 + 4.0 * k_
        ge_ = Y_GAL
        decor_txt += put(f"GalStalp{k_}", "31_gcol", RID, -62.0, ge_, -gy_)
        decor_txt += put(f"GalAcoperis{k_}", "32_groof", RID, -64.0, ge_ + 3.5, -(gy_ + 2.0),
                         anchor=(1.75, -3.5, 0.0))
        decor_txt += put(f"GalZid{k_}", "33_gwall", R90N, -66.3, ge_, -(gy_ + 2.0))
    decor_txt += put("GalStalpN", "31_gcol", RID, -62.0, Y_GAL, -(26.0 + 36.0))

    # Phnom Bakheng: platforma de sus (+31), turnulete-altar si scari pe margini, in afara benzii (7 m).
    for k_, (bx_, by_) in enumerate(((-148.0, 220.0), (-148.0, 200.0), (-128.0, 220.0), (-128.0, 200.0))):
        decor_txt += put(f"BakhengAltar{k_}", "34_shrine", R90P if bx_ < -138 else R90N, bx_, Y_BAK, -by_)
    decor_txt += put("BakhengScara0", "35_stair", R90P, -152.0, Y_BAK - 0.75, -210.0)
    decor_txt += put("BakhengScara1", "35_stair", R90N, -124.0, Y_BAK - 0.9, -210.0)

    # Srah Srang: debarcaderul pe STANGA lui H (spre sud, spre bazin), dincolo de balustrada; treptele
    # coboara spre apa (-Y Blender = +Z model -> +Z lume = sud).
    decor_txt += put("SrahSrangDebarcader", "36_landing", RID, 50.0, 2.0, -(-112.0 - 10.5))

    # Viata: tuk-tuk-uri parcate pe malul interior, langa gopura (fara corp: impingerea e decizie amanata,
    # kit §1.6), calugari in fundal.
    for k_, (tx_, ty_) in enumerate(((-88.0, 14.0), (-84.0, 15.0), (-80.0, 14.5))):
        decor_txt += put(f"TukTuk{k_}", "37_tuk", R90N, tx_, Y_CALE, -ty_)
        # cele doua radacini ale GLB-ului (kit §1.6) stau amandoua in origine: motocicleta se muta in
        # fata remorcii (-Z model = sensul de mers)
        decor_txt += (f'\n[node name="Moto" parent="DecorManual/TukTuk{k_}"]\n'
                      "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -1.95)\n")
    for k_, (mx_, my_) in enumerate(((-90.0, -16.0), (-89.0, -17.5), (-147.0, 228.0))):
        decor_txt += put(f"Calugar{k_}", "38_monk", R90P, mx_, Y_CALE if k_ < 2 else Y_BAK, -my_)

    # Moloz si restaurare pe langa galeria scurtaturii, IN AFARA peretilor (|x - 126| >= 7).
    for k_, (sv_, dx_, rid_) in enumerate(((40.0, 8.0, "39_rubble"), (58.0, -8.5, "39_rubble"),
                                         (66.0, 8.0, "40_restore"), (47.0, -8.0, "41_numbered"),
                                         (72.0, -8.5, "42_laterite"))):
        bx_, by_, be_ = br_at(sv_)
        decor_txt += put(f"MolozGalerie{k_}", rid_, R90N if dx_ > 0 else R90P, bx_ + dx_, be_, -by_)

    # Ficusi sugrumatori pe langa galerie si jungla Ta Prohm (tetrameles), palmieri de zahar pe malul
    # de vest al santului si pe malul de sud al lui H; lotusi si nuferi pe santul de vest si in Srah Srang.
    for k_, (sv_, dx_) in enumerate(((36.0, -11.0), (62.0, 11.0), (76.0, -11.5))):
        bx_, by_, be_ = br_at(sv_)
        decor_txt += put(f"Ficus{k_}", "43_fig", R90N if dx_ < 0 else R90P, bx_ + dx_, be_ - 0.2, -by_)
    for k_, (px_, py_, rid_) in enumerate(((150.0, 40.0, "44_tetra_a"), (104.0, 55.0, "45_tetra_b"),
                                         (152.0, -10.0, "44_tetra_a"), (100.0, 0.0, "46_dipt"),
                                         (165.0, 15.0, "45_tetra_b"))):
        decor_txt += put(f"JunglaTaProhm{k_}", rid_, RID, px_, 8.0, -py_, col="trunk")
    for k_ in range(6):
        # departe de calea de start (camera de pe grila sta in x -250..-230)
        pyv_ = (-48.0, -36.0, -26.0, 26.0, 36.0, 48.0)[k_]
        decor_txt += put(f"PalmierV{k_}", "47_palm", RID, -212.0 - 6.0 * (k_ % 2), Y_CALE, -pyv_, col="trunk")
        decor_txt += put(f"PalmierH{k_}", "47_palm", RID, -40.0 - 30.0 * k_, Y_CALE, -(-128.0 - 3.0 * (k_ % 2)), col="trunk")
    for k_, (lx_, ly_, rid_) in enumerate(((-160.0, 22.0, "48_lotus"), (-135.0, -26.0, "48_lotus"),
                                         (-180.0, -18.0, "49_lily"), (-120.0, 30.0, "49_lily"),
                                         (40.0, -150.0, "48_lotus"), (65.0, -140.0, "49_lily"))):
        decor_txt += put(f"Lotus{k_}", rid_, RID, lx_, WATER_AW, -ly_)

    # ==== DECORUL PER POI (gauntlet, docs/track_briefs/angkor_poi_gauntlet.md) ===========================
    # Un fisier per POI, `tools/angkor_decor/zona_<x>.py`, plus `jungla.py` (padurea in masa, globala), ca
    # constructorii sa lucreze in paralel fara conflicte pe generator. Formatul e in antetul fiecarui
    # fisier (tiparul Carrara). Cu toate fisierele goale, Track24.tscn iese identic la bit.
    import importlib
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    ZONE_R = "res://assets/models/angkor/"
    zone_ext, zone_sub, zone_nodes = "", "", ""
    zone_glb = {}
    _idx_tab = [(sv_, F_s(sv_)[0]) for sv_ in [k_ * 0.5 for k_ in range(int(total / 0.5))]]

    def s_of_idx(fr):
        fr = fr % 1.0
        return min(_idx_tab, key=lambda t: min(abs(t[1] - fr), 1.0 - abs(t[1] - fr)))[0]

    def road_frame(fr, lat, along=0.0):
        """(gx, gy_drum, gz, tx, ty, s): punctul la (frac pe INDEX, lateral + dreapta, along m inainte)."""
        sv = s_of_idx(fr) + along
        px, py = pos_at(sv)
        ax, ay = pos_at(sv + 0.5)
        bx, by = pos_at(sv - 0.5)
        tx, ty = ax - bx, ay - by
        n = math.hypot(tx, ty)
        tx, ty = tx / n, ty / n
        # dreapta sensului pe harta: (ty, -tx); Godot = (x, cota, -y)
        hx, hy = px + ty * lat, py - tx * lat
        return hx, elev_at(sv), -hy, tx, ty, sv % total

    def zone_rid(path):
        if not path.startswith("res://"):
            path = ZONE_R + path
        if path not in zone_glb:
            zone_glb[path] = f"z{len(zone_glb)}_{os.path.splitext(os.path.basename(path))[0]}"
        return zone_glb[path]

    def yaw_basis(fx, fz, yaw_deg, k):
        """Baza cu -Z al piesei pe directia (fx, fz) rotita cu yaw (grade, + = spre STANGA), scara k."""
        a = math.radians(yaw_deg)
        rx = fx * math.cos(a) + fz * math.sin(a)
        rz = -fx * math.sin(a) + fz * math.cos(a)
        Z = (-rx * k, 0.0, -rz * k)
        Y = (0.0, k, 0.0)
        X = (-rz * k, 0.0, rx * k)   # Y x Z, la aceeasi scara
        return X, Y, Z

    # Zonele INAINTEA junglei: luminisurile lor (disc cu `claim`, fara specii) scot padurea din piete/temple.
    zone_files = [f"zona_{c_}" for c_ in "abcdefgh"] + ["jungla"]
    forest_zones, forest_glbs = [], {}
    print("\n  decorul per POI (tools/angkor_decor/):")
    for zf_ in zone_files:
        if not os.path.exists(os.path.join(os.path.dirname(os.path.abspath(__file__)), "angkor_decor", zf_ + ".py")):
            continue
        zm_ = importlib.import_module(f"angkor_decor.{zf_}")
        items_ = list(getattr(zm_, "ITEMS", []))
        kit_y_ = dict(getattr(zm_, "KIT_Y", {}))
        for d_ in getattr(zm_, "FOREST", []):
            forest_zones.append(dict(d_, label=d_.get("label", zf_)))
        forest_glbs.update(getattr(zm_, "FOREST_GLBS", {}))
        if not items_:
            continue
        zn_ = "Zona" + zf_.split("_")[-1].upper() if zf_.startswith("zona_") else "Jungla"
        zone_nodes += f'\n[node name="{zn_}" type="Node3D" parent="DecorManual"]\n'
        for it_ in items_:
            nm_, path_, fr_, lat_, yaw_ = it_[:5]
            opt_ = it_[5] if len(it_) > 5 else {}
            k_ = float(opt_.get("scale", 1.0))
            if "world" in opt_:
                # pozitie absoluta in Godot (x, z); yaw absolut (0 = -Z al piesei spre -Z al lumii, nord)
                gx_, gz_ = opt_["world"]
                sv_ = s_near(gx_, -gz_)
                gy0_ = elev_at(sv_)
                fx_, fz_ = 0.0, -1.0
            else:
                gx_, gy0_, gz_, tx_, ty_, sv_ = road_frame(fr_, lat_, float(opt_.get("along", 0.0)))
                fx_, fz_ = tx_, -ty_
            gy_ = opt_.get("y", kit_y_.get(nm_, gy0_ + float(opt_.get("dy", -0.3))))
            X_, Y_, Z_ = yaw_basis(fx_, fz_, float(yaw_), k_)
            zone_nodes += (f'\n[node name="{nm_}" parent="DecorManual/{zn_}" instance=ExtResource("{zone_rid(path_)}")]\n'
                           f"transform = Transform3D({_rows(X_, Y_, Z_)}, {r2(gx_)}, {r2(gy_)}, {r2(gz_)})\n")
            if "coliziune" in opt_:
                zone_nodes += f'metadata/coliziune = "{opt_["coliziune"]}"\n'
            if "anchor" in opt_:
                a_ = opt_["anchor"]
                zone_nodes += f"metadata/ancora_sol = Vector3({a_[0]}, {a_[1]}, {a_[2]})\n"
            if opt_.get("scufundat", False):
                zone_nodes += "metadata/scufundat = true\n"
            # "child": {"Nod": (x, y, z)} muta un nod-copil al GLB-ului (tuk_tuk: `Moto` la z -1,95, ca TukTuk0..2).
            for cn_, cp_ in opt_.get("child", {}).items():
                zone_nodes += (f'\n[node name="{cn_}" parent="DecorManual/{zn_}/{nm_}"]\n'
                               f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cp_[0]}, {cp_[1]}, {cp_[2]})\n")
            print(f"    {zn_}/{nm_:22s} frac {F_s(sv_)[0]:.4f} lat {lat_:+6.1f} y {gy_:7.2f} (drum {elev_at(sv_):6.2f})")

    if forest_zones:
        zone_ext += ('[ext_resource type="Script" path="res://scenes/props/mesh_forest.gd" id="mf_script"]\n'
                     '[ext_resource type="Script" path="res://scenes/props/mesh_forest_zone.gd" id="mf_zone"]\n')
        for st_, pth_ in forest_glbs.items():
            if not pth_.startswith("res://"):
                pth_ = ZONE_R + pth_
            zone_ext += f'[ext_resource type="PackedScene" path="{pth_}" id="mf_{st_}"]\n'
        for k_, d_ in enumerate(forest_zones):
            sp_txt = ", ".join('"%s"' % x_ for x_ in d_.get("species", ()))
            zw_txt = ", ".join(str(float(w_)) for w_ in d_.get("weights", ()))
            zone_sub += f"""
[sub_resource type="Resource" id="MFZ_{k_}"]
script = ExtResource("mf_zone")
label = "{d_['label']}"
kind = {1 if d_.get('kind') == 'disc' else 0}
species = PackedStringArray({sp_txt})
weights = PackedFloat32Array({zw_txt})
spacing = {float(d_.get('spacing', 8.0))}
edge_clear_m = {float(d_.get('edge_clear_m', 9.0))}
shadow_m = {float(d_.get('shadow_m', 25.0))}
view_m = {float(d_.get('view_m', 330.0))}
max_below_road_m = {float(d_.get('max_below_road_m', 200.0))}
claim = {"true" if d_.get('claim') else "false"}
scale_min = {float(d_.get('scale_min', 0.85))}
scale_max = {float(d_.get('scale_max', 1.2))}
seed_value = {int(d_.get('seed', k_ + 1))}
"""
            if d_.get("kind") == "disc":
                if "at" in d_:   # (frac pe INDEX, lateral + dreapta)
                    cx_, _cy, cz_, _a, _b, _s = road_frame(d_["at"][0], d_["at"][1])
                else:
                    cx_, cz_ = d_["center"]
                zone_sub += f"center = Vector3({cx_:.2f}, 0, {cz_:.2f})\nradius = {float(d_['radius'])}\n"
            else:
                zone_sub += (f"frac_from = {d_['frac_from']:.4f}\nfrac_to = {d_['frac_to']:.4f}\n"
                             f"side = {int(d_.get('side', 0))}\n"
                             f"lat_min = {float(d_['lat_min'])}\nlat_max = {float(d_['lat_max'])}\n")
        scenes_txt = ", ".join(f'ExtResource("mf_{x_}")' for x_ in forest_glbs)
        zones_txt = ", ".join(f'SubResource("MFZ_{k_}")' for k_ in range(len(forest_zones)))
        zone_nodes += f"""
[node name="PadureMasa" type="Node3D" parent="."]
script = ExtResource("mf_script")
scenes = Array[PackedScene]([{scenes_txt}])
zones = Array[ExtResource("mf_zone")]([{zones_txt}])
"""
        print(f"  padurea in masa: {len(forest_zones)} zone, specii {list(forest_glbs)}")
    zone_ext += "".join(f'[ext_resource type="PackedScene" path="{p_}" id="{r_}"]\n' for p_, r_ in zone_glb.items())
    # ==== sfarsit DECORUL PER POI ========================================================================
    bias = [(IDX("E terasa V", BAYON_TOWERS[0][0] - 45.0),
             IDX("E terasa V", BAYON_TOWERS[-1][0] + 8.0), BAYON_BIAS)]

    # ---- PASUL 6: musonul + fulgerul. RainCycle e metronomul (singura cale de ud: `track.rain_wet`);
    # LightningFlash se aboneaza la el (grupul `rain_cycle`) si ruleaza DUPA el.
    hz_txt += f"""
[node name="Muson" type="Node" parent="Hazarduri"]
script = ExtResource("7_rain")
period = {RAIN_PERIOD}
telegraph = 5.0
rain_hold = 25.0
dry_out = 5.0
start_clock = {RAIN_PERIOD - RAIN_FIRST_AT}
fog_end_rain = 180.0
fog_whiten_rain = 0.25
sun_energy_rain = 0.75
sky_top_rain = Color(0.17, 0.15, 0.22, 1)
sky_horizon_rain = Color(0.36, 0.32, 0.4, 1)

[node name="Fulger" type="Node" parent="Hazarduri"]
script = ExtResource("8_flash")
"""
    # ---- PASUL 6: perdeaua de liane. Baza scrisa pe RANDURI (memoria `tscn-transform-e-pe-randuri`):
    # -Z local = sensul de mers. Orientarea se verifica in sonda (tools/probe_angkor_pas6.gd).
    cs_ = tag_s["G ocol intrare"] + CURTAIN_AFTER_FORK
    ca_, cb_ = pos_at(cs_ - 1.0), pos_at(cs_ + 1.0)
    fx_, fz_ = cb_[0] - ca_[0], -(cb_[1] - ca_[1])
    fl_ = math.hypot(fx_, fz_)
    fx_, fz_ = fx_ / fl_, fz_ / fl_
    bzx_, bzz_ = -fx_, -fz_                 # basis.z = -inainte
    bxx_, bxz_ = bzz_, -bzx_                # basis.x = up x basis.z
    cx_, cy_ = pos_at(cs_)
    ce_ = elev_at(cs_)
    hz_txt += f"""
[node name="PerdeaLiane" type="Node3D" parent="Hazarduri"]
transform = Transform3D({r3(bxx_)}, 0, {r3(bzx_)}, 0, 1, 0, {r3(bxz_)}, 0, {r3(bzz_)}, {r2(cx_)}, {r2(ce_)}, {r2(-cy_)})
script = ExtResource("9_vine")
"""
    print(f"  perdea: s {cs_:.1f}, idx {IDX('G ocol intrare', CURTAIN_AFTER_FORK)}, cota {ce_:.2f}")
    print(f"\n  elefant: frac idx {IDX('D poarta', ELEPHANT_AFTER_GATE)} "
          f"(fereastra sondei {IDX('D poarta', -10.0)},{IDX('D poarta', 45.0)})")
    print(f"  creasta: fereastra sondei {IDX(CREST_TAG, -30.0)},{IDX(CREST_TAG, 60.0)}")

    # ---- MACHETE (pasul 4): forme de CSG FARA coliziune, la cotele din brief §2.0, ca sa se poata
    # verifica incadrarea cu --gamecam inainte sa existe vreun asset. TEMPORARE: se scot cand intra
    # hero-asset-urile (pasul 7). Un singur material.
    def box(name, cx, cy, cz, sx, sy, sz):
        return f"""
[node name="{name}" type="CSGBox3D" parent="Machete"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(cx)}, {r2(cy)}, {r2(cz)})
size = Vector3({sx}, {sy}, {sz})
material = SubResource("Mat_macheta")
"""

    def tower(name, cx, cz, base, h, r):
        return f"""
[node name="{name}" type="CSGCylinder3D" parent="Machete"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {r2(cx)}, {r2(base + h / 2)}, {r2(cz)})
radius = {r}
height = {h}
sides = 8
cone = true
material = SubResource("Mat_macheta")
"""
    # Angkor Wat: soclul in trepte pana la +6, turnul central cu varful la +36, cele de colt la +30.
    # Angkor Wat: machetele au iesit la val 3 (angkor_wat_temple.glb, aceleasi cote, DecorManual).
    mach = ""
    # Poarta de Sud: macheta a iesit la val 1 (south_gate_face_tower.glb, DecorManual).
    # Terasa Elefantilor: fata de vest (4 m) de-a lungul coamei.
    c0_ = next(w for w in WPTS if w[4] == "F coama inceput")
    c1_ = next(w for w in WPTS if w[4] == CREST_TAG)
    f0_, f1_ = face_y1, face_y0
    # (macheta fetei de vest a iesit la val 2: modulele terasei, in DecorManual)

    # zonele pentru sonde (fractii pe INDEX)
    zz = [("A", IDX("A start"), IDX("B arc galerie", -40.0)),
          ("B", IDX("B arc galerie", -40.0), IDX("B cale N sfarsit")),
          ("C", IDX("B cale N sfarsit"), IDX("D cale inceput")),
          ("D", IDX("D cale inceput"), IDX("E rampa V jos")),
          ("E", IDX("E rampa V jos"), IDX("F colt piata")),
          ("F", IDX("F colt piata"), IDX("F aterizare", 30.0)),
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
[ext_resource type="Script" path="res://scenes/hazards/rim_boulder_hazard.gd" id="4_rim"]
[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="5_hzm"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/animals/asian_elephant.glb" id="6_eleph"]
[ext_resource type="Script" path="res://scenes/hazards/rain_cycle.gd" id="7_rain"]
[ext_resource type="Script" path="res://scenes/hazards/lightning_flash.gd" id="8_flash"]
[ext_resource type="Script" path="res://scenes/hazards/vine_curtain.gd" id="9_vine"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/bayon_face_tower_a.glb" id="10_bayon"]
[ext_resource type="Script" path="res://scenes/props/world_prop.gd" id="11_prop"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/bayon_face_tower_b.glb" id="12_bayon_b"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/bayon_face_tower_c.glb" id="13_bayon_c"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/south_gate_face_tower.glb" id="14_gate_s"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/aw_west_gopura.glb" id="15_gopura"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/ta_prohm_tree_gate.glb" id="16_treegate"]
[ext_resource type="Script" path="res://scenes/hazards/camera_zone.gd" id="17_camzone"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/naga_balustrade.glb" id="18_naga"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/naga_head.glb" id="19_nagahead"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/deva_giant.glb" id="20_deva"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/asura_giant.glb" id="21_asura"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/props/fallen_block.glb" id="22_block"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/elephant_terrace_module.glb" id="23_terrace"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/elephant_terrace_end.glb" id="24_terrace_end"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/elephant_trunk_pillar.glb" id="25_pillar"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/props/leper_king_statue.glb" id="26_leper"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/vault_intact.glb" id="27_vault"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/vault_broken.glb" id="28_vault_b"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/giant_root_ramp.glb" id="29_ramp"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/angkor_wat_temple.glb" id="30_temple"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/gallery_column.glb" id="31_gcol"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/gallery_roof.glb" id="32_groof"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/gallery_relief_wall.glb" id="33_gwall"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/bakheng_shrine_tower.glb" id="34_shrine"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/kit/bakheng_side_stair.glb" id="35_stair"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/structures/srah_srang_landing.glb" id="36_landing"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/vehicles/tuk_tuk.glb" id="37_tuk"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/animals/monk_standing.glb" id="38_monk"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/props/rubble_pile.glb" id="39_rubble"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/props/restoration_prop.glb" id="40_restore"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/props/numbered_block.glb" id="41_numbered"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/props/laterite_block.glb" id="42_laterite"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/strangler_fig.glb" id="43_fig"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/tetrameles_a.glb" id="44_tetra_a"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/tetrameles_b.glb" id="45_tetra_b"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/dipterocarp.glb" id="46_dipt"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/sugar_palm.glb" id="47_palm"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/lotus_cluster.glb" id="48_lotus"]
[ext_resource type="PackedScene" path="res://assets/models/angkor/plants/water_lily_pads.glb" id="49_lily"]
{zone_ext}
[sub_resource type="StandardMaterial3D" id="Mat_macheta"]
albedo_color = Color(0.72, 0.64, 0.52, 1)

[sub_resource type="BoxShape3D" id="Box_bayon"]
size = Vector3({BAYON_TOWER_SIZE[0]}, {BAYON_TOWER_SIZE[1]}, {BAYON_TOWER_SIZE[2]})

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
{zone_sub}
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
custom_water_styles = Array[Dictionary]([{JADE_STYLE}])
custom_width_segments = Array[Vector3]([{", ".join(V3(*w_) for w_ in width_segments)}])
custom_width_pinches = Array[Vector3]([{", ".join(V3(*w_) for w_ in pinches)}])
custom_parapets = Array[Vector4]([{", ".join(V4(*p_) for p_ in parapets)}])
custom_lane_bias = Array[Vector3]([{", ".join(V3(*b_) for b_ in bias)}])
custom_bench_patches = Array[Dictionary]([{", ".join(
    "{ \"lvl\": PackedVector2Array(-1000.0, %s, 1000.0, %s), \"soft\": Vector4(%s, %s, %s, %s), "
    "\"x0\": %s, \"x1\": %s, \"z0\": %s, \"z1\": %s }" % (lv_, lv_, sw_, se_, sn_, ss_, r2(x0_), r2(x1_), r2(-y1_), r2(-y0_))
    for (x0_, x1_, y0_, y1_, lv_, sw_, se_, sn_, ss_) in bench)}])
terrain_pad_m = 120.0
{zones_meta}
[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_angkor")

[node name="Peaks" type="Node3D" parent="."]
{peaks_txt}{branch_txt}
[node name="Hazarduri" type="Node3D" parent="."]
{hz_txt}
[node name="Obstacole" type="Node3D" parent="."]
{towers_txt}
[node name="DecorManual" type="Node3D" parent="."]
script = ExtResource("11_prop")
{decor_txt}{zone_nodes}{cam_txt}
[node name="Machete" type="Node3D" parent="."]
{mach}"""
    with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {OUT_PATH}")
    print(f"  praf (idx): {dirt}")
    print(f"  rape (len): {ravines}")
    print(f"  latimi (idx): {width_segments}")
    print(f"  zone: {zz}")
    print(f"  balustrade (len): {parapets}")
    print(f"  lane_bias (idx): {bias}")
