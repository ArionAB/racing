#!/usr/bin/env python3
"""Genereaza tools/SondaSfSerp*.tscn: strada SINTETICA a sondei 1b San Francisco
(brief docs/track_briefs/san_francisco.md §2 „Scurtatura: strada cu serpentine
(E')", §7 pasul 1b). NU e Track25 si nu intra in GameState.TRACK_SCENES.

Ce modeleaza (fara case, hortensii, tramvai):
  - terasa: dreapta de apropiere de 120 m la cota Y_TOP, pe +X, pana la FURCA F;
  - OCOLUL (bucla principala, ruta 0): bulevardul de 14 m care coteste la
    STANGA din furca si ocoleste blocul cu trei viraje de 90 de grade
    (stanga, dreapta, dreapta) si iese pe strada tramvaiului T (spre +Z),
    coborand DROP m liniar pe lungimea lui; lungimea se regleaza la ~270 m
    (variabila BYPASS);
  - SCURTATURA (TrackBranch, ruta 1): din furca vireaza la dreapta (furca e un
    Y), apoi TREI ACE DE PAR la raza de ax R, benzile la 2R una de alta, cu
    un viraj de 90 de grade la intrare si unul la iesire (iesirea e iar pe +X),
    o gura scurta si virajul de 90 de grade pe strada tramvaiului, unde se
    reintalneste cu ocolul. Coboara acelasi DROP, liniar pe lungimea ei;
  - restul buclei: strada tramvaiului continua 50 m, apoi o intoarcere
    dreptunghiulara (raze 25 m) care urca inapoi la Y_TOP si dreapta de grila.

Toate arcele mai mari de 45 de grade sunt desenate cu puncte PE arc (memoria
`viraje-stranse-puncte-pe-arc`), la cel mult ARC_DEG grade intre ele.

  python tools/gen_sf_serpentine.py                       # setul implicit
  R=10 BW=3.5 python tools/gen_sf_serpentine.py           # o singura varianta
  ... AI=1.0 SUFIX=F                                      # AI fortat pe scurtatura

Variabile (toate optionale; implicit = forma aleasa): R (raza acului, 16), BW
(semi-latimea benzii, 4.5), LEG (dreapta dintre ace, 8), RE (raza virajelor de
90 ale scurtaturii, 16), BYPASS (lungimea-tinta a ocolului, 400), DROP (11.6),
AI (ai_shortcut_chance; lipsa = implicitul 0.4 al AIController), SUFIX, SURF.

Metadatele scrise in scena le citeste tools/probe_sf_serp.gd: furca, punctul de
reintalnire, portile de cronometru, centrele acelor, lungimile analitice.

FORMA ALEASA (runda 2, 11 nov 2026, decizia coordonatorului pe cifrele sondei):
  R = 16 (ace la raza 16), BW = 4.5 (carosabil de 9 m), RE = 16 (si virajele
  de 90 ale scurtaturii la raza 16), BYPASS = 400 (ocolul lungit la 400 m, tot
  cu trei viraje de 90 si aceeasi cadere), scenele SondaSfSerpR16W9B400E16{F,N,O}.
  Interiorul acelor: bloc plin de 0,8 m RETRAS 2 m de la margine, fatade pe
  exterior la 1 m — nu e in scena, il pune sonda:
    ProbeSfSerp ... --walls=1.0,1.5,0 --inner=2.0,0.8,fill
  De ce: la R8 AI-ul nu urmareste acele (raza minima de viraj fara drift e
  17,5/1,9 = 9,2 m, iar AI-ul nu coboara sub ~15,5 m/s), scurtatura pierdea
  +1,6..+3 s, iar dreapta peste straturi castiga 1-5 s. Cu forma de mai sus:
  scurtatura curata castiga 1,5-1,6 s (solo), o bordura atinsa o face sa piarda
  (+1,1 s), dreapta peste straturi nu mai merge. Virajele de 90 la R10 aruncau
  AI-ul in stratul acului 1; stratul lipit de margine il prindea (repuneri la
  50% din treceri in pluton). Ocolul de 450 m dadea 3 s (peste tinta).
  Banda e pe pietris (SURF=3): "deck" (runda 1) nu sapa terenul, care intra in
  drum la ace (ProbeLaneClear 38 -> 0).

Scenele R8/R10/R12 (si R16W7, R8W7B400, R8W7C) sunt ale rundei 1, scrise cu
banda pe "deck" si virajele de 90 la R10; raman pentru reproducerea rundei 1.
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

Y_TOP = 20.0
APPROACH = 120.0     # grila (punctul 0) -> furca
GRID = 72.0          # dreapta de grila care inchide bucla
RB = 15.0            # raza colturilor bulevardului (14 m lat)
R_RET = 25.0         # raza colturilor intoarcerii
T_AFTER = 50.0       # strada tramvaiului dupa reintalnire
STEP = 12.0          # pas pe dreptele buclei
BSTEP = 6.0          # pas pe dreptele scurtaturii (echilibrat cu coarda arcelor)
ARC_DEG = 45.0       # unghi maxim intre doua puncte de pe un arc
HALF_WIDTH = 7.0
G1 = 4.0             # gang de la furca pana la virajul de intrare
EXIT_AFTER = 6.0     # cat dupa capatul gurii revine banda pe axa strazii T


OVERLAP_M = 12.0     # sub atat (ax la ax) banda isi ia cota de la bucla


def nearest_on_poly(pts, x, z):
    """Distanta in plan pana la bucla (polilinie inchisa) si cota ei acolo."""
    best = (1e18, 0.0)
    n = len(pts)
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        sx, sz = b[0] - a[0], b[2] - a[2]
        L2 = sx * sx + sz * sz
        t = 0.0 if L2 < 1e-9 else max(0.0, min(1.0, ((x - a[0]) * sx + (z - a[2]) * sz) / L2))
        qx, qz = a[0] + sx * t, a[2] + sz * t
        d2 = (x - qx) ** 2 + (z - qz) ** 2
        if d2 < best[0]:
            best = (d2, a[1] + (b[1] - a[1]) * t)
    return math.sqrt(best[0]), best[1]


def bezier_cum(points, samples=64):
    """Lungimea cumulata (3D) pana la fiecare punct de control, pe curba pe care
    o face Godot din ele: Bezier cubic cu tangenta (urmatorul - precedentul) *
    0.22 (TrackRoute.from_points), bucla inchisa. Intoarce n+1 valori (ultima =
    lungimea totala), ca fractiile entry_at / exit_at sa cada pe indicele copt.
    """
    n = len(points)
    P = [tuple(p) for p in points]
    T = []
    for i in range(n):
        a, b = P[(i - 1) % n], P[(i + 1) % n]
        T.append(tuple((b[k] - a[k]) * 0.22 for k in range(3)))
    cum = [0.0]
    for i in range(n):
        p0, p3 = P[i], P[(i + 1) % n]
        p1 = tuple(p0[k] + T[i][k] for k in range(3))
        p2 = tuple(p3[k] - T[(i + 1) % n][k] for k in range(3))
        prev = p0
        acc = 0.0
        for j in range(1, samples + 1):
            t = j / samples
            u = 1 - t
            q = tuple(u * u * u * p0[k] + 3 * u * u * t * p1[k] + 3 * u * t * t * p2[k]
                      + t * t * t * p3[k] for k in range(3))
            acc += math.dist(prev, q)
            prev = q
        cum.append(cum[-1] + acc)
    return cum


class Turtle:
    """0 = +X; dreapta (spre +Z) = theta creste (ca in gen_carrara_sonda.py)."""

    def __init__(self, x=0.0, z=0.0, th=0.0, step=STEP):
        self.x, self.z, self.th = x, z, th
        self.step = step
        self.pts = [(x, z)]
        self.s = [0.0]       # lungimea analitica pana la fiecare punct
        self.len = 0.0

    def straight(self, length):
        if length <= 1e-6:
            return
        n = max(1, int(math.ceil(length / self.step - 1e-9)))
        for k in range(1, n + 1):
            t = k / n
            self.pts.append((self.x + math.cos(self.th) * length * t,
                             self.z + math.sin(self.th) * length * t))
            self.s.append(self.len + length * t)
        self.x += math.cos(self.th) * length
        self.z += math.sin(self.th) * length
        self.len += length

    def arc(self, radius, angle_deg, right):
        sgn = 1.0 if right else -1.0
        cx = self.x + math.cos(self.th + sgn * math.pi / 2) * radius
        cz = self.z + math.sin(self.th + sgn * math.pi / 2) * radius
        a0 = math.atan2(self.z - cz, self.x - cx)
        total = math.radians(angle_deg) * sgn
        n = max(2, int(math.ceil(angle_deg / ARC_DEG - 1e-9)))
        arc_len = radius * math.radians(angle_deg)
        for k in range(1, n + 1):
            a = a0 + total * k / n
            self.pts.append((cx + math.cos(a) * radius, cz + math.sin(a) * radius))
            self.s.append(self.len + arc_len * k / n)
        a1 = a0 + total
        self.x = cx + math.cos(a1) * radius
        self.z = cz + math.sin(a1) * radius
        self.th += total
        self.len += arc_len
        return (cx, cz)


def build(R, LEG, RE, bypass_target, drop):
    # ---------------- scurtatura (din F, in coordonate relative la F) --------
    sc = Turtle(step=BSTEP)
    sc.straight(G1)
    sc.arc(RE, 90.0, True)                 # spre +Z
    L1 = 4.0
    sc.straight(L1)
    hairpins = []
    hairpins.append(sc.arc(R, 180.0, False))   # A1: spre -Z
    sc.straight(LEG)
    hairpins.append(sc.arc(R, 180.0, True))    # A2: spre +Z
    sc.straight(LEG)
    hairpins.append(sc.arc(R, 180.0, False))   # A3: spre -Z
    # pana la cota z = RE, ca iesirea spre +X sa cada pe z = 0
    sc.straight(sc.z - RE)
    sc.arc(RE, 90.0, True)                 # spre +X, pe z = 0
    assert abs(sc.z) < 1e-6, sc.z
    G2 = 6.0
    sc.straight(G2)
    sc.arc(RE, 90.0, True)                 # gura: pe strada tramvaiului (+Z)
    x_t = sc.x                             # axa strazii tramvaiului (relativ la F)
    z_m = sc.z                             # punctul de reintalnire
    short_len = sc.len

    # ---------------- ocolul: L, A, R, B, R, pana la z_m pe x = x_t -------
    B = x_t - 3.0 * RB
    assert B > 6.0, "strada tramvaiului prea aproape de furca"
    arcs = 3.0 * RB * math.pi / 2.0
    # lungime = arcs + A + B + (RB + A + z_m)  ->  A
    A = (bypass_target - arcs - B - RB - z_m) / 2.0
    assert A > 20.0, A

    # ---------------- bucla principala, de la punctul 0 ---------------------
    t = Turtle()
    t.straight(APPROACH)
    i_fork = len(t.pts) - 1
    F = (t.x, t.z)
    t.arc(RB, 90.0, False)                 # stanga, spre -Z
    t.straight(A)
    t.arc(RB, 90.0, True)                  # spre +X
    t.straight(B)
    t.arc(RB, 90.0, True)                  # spre +Z, pe strada tramvaiului
    t.straight(RB + A + z_m)
    i_merge = len(t.pts) - 1
    M = (t.x, t.z)
    byp_len = t.len - APPROACH
    t.straight(T_AFTER)
    i_climb0 = len(t.pts) - 1
    t.arc(R_RET, 90.0, True)               # spre -X
    west = t.x + GRID
    t.straight(west)
    t.arc(R_RET, 90.0, True)               # spre -Z
    t.straight(t.z - R_RET)
    i_climb1 = len(t.pts) - 1
    t.arc(R_RET, 90.0, True)               # spre +X, pe z = 0
    t.straight(GRID)
    assert abs(t.x) < 0.01 and abs(t.z) < 0.01, (t.x, t.z)
    pts2 = t.pts[:-1]
    s2 = t.s[:-1]
    loop_len = t.len

    y_bot = Y_TOP - drop
    ys = []
    for k, sk in enumerate(s2):
        if k <= i_fork:
            y = Y_TOP
        elif k <= i_merge:
            y = Y_TOP - drop * (sk - s2[i_fork]) / (s2[i_merge] - s2[i_fork])
        elif k <= i_climb0:
            y = y_bot
        elif k <= i_climb1:
            y = y_bot + drop * (sk - s2[i_climb0]) / (s2[i_climb1] - s2[i_climb0])
        else:
            y = Y_TOP
        ys.append(y)
    main_pts = [(p[0], y, p[1]) for p, y in zip(pts2, ys)]

    # punctele de mijloc ale scurtaturii: fara F si fara ultimul punct (pe T);
    # cota liniara pe lungime, de la Y_TOP la y_bot.
    # Capetele se DECLARA (entry_at / exit_at), nu se deduc: capatul dedus e
    # piciorul perpendicularei pe sosea din primul/ultimul punct desenat, si
    # aici, unde furca e un Y si gura un T, ar fi lasat un carlig de 0,5-3 m
    # intors spre bucla (masurat cu ProbeLayout: capete (123,-1) / (208, 2)).
    # Primul punct desenat e cel de la 45 de grade pe virajul de intrare;
    # ultimul, cel de la 45 de grade pe virajul gurii; banda revine pe axa
    # strazii tramvaiului la EXIT_AFTER m dupa capatul analitic al gurii.
    # Runda 2 (ProbeLaneClear: RoadTop in fata la furca si la gura): unde banda
    # se suprapune cu bucla (ax la ax < OVERLAP_M), cota ei e cota buclei, altfel
    # ramane o treapta intre cele doua plane de asfalt; intre cele doua zone de
    # suprapunere coboara liniar (nu se strange o treapta locala).
    raw = []
    for (x, z), sk in zip(sc.pts, sc.s):
        if sk < G1 + 0.5 or sk > short_len - 0.5:
            continue
        px, pz = F[0] + x, F[1] + z
        d, ym = nearest_on_poly(main_pts, px, pz)
        raw.append((px, pz, sk, d, ym))
    ia = 0
    while ia + 1 < len(raw) and raw[ia + 1][3] < OVERLAP_M:
        ia += 1
    ib = len(raw) - 1
    while ib - 1 > ia and raw[ib - 1][3] < OVERLAP_M:
        ib -= 1
    if raw[ia][3] >= OVERLAP_M:      # primul punct deja departe: pleaca de la furca
        sa, ya = 0.0, Y_TOP
    else:
        sa, ya = raw[ia][2], raw[ia][4]
    if raw[ib][3] >= OVERLAP_M:
        sb, yb = short_len, Y_TOP - drop
    else:
        sb, yb = raw[ib][2], raw[ib][4]
    mid = []
    for k, (px, pz, sk, d, ym) in enumerate(raw):
        if (k <= ia and raw[ia][3] < OVERLAP_M) or (k >= ib and raw[ib][3] < OVERLAP_M):
            y = ym
        else:
            y = ya + (yb - ya) * (sk - sa) / max(sb - sa, 1e-6)
        mid.append((px, y, pz))
    exit_pt = (M[0], M[1] + EXIT_AFTER)
    baked = read_baked(R, LEG, RE, bypass_target)
    if baked:
        # treapta 2: indicii COPTI reali (dump-ul ProbeSfSerp --mode=dump);
        # Godot nu coace la pas uniform, deci fractia nu e lungime / total
        n = len(baked)
        i_f = min(range(n), key=lambda i: (baked[i][0] - F[0]) ** 2 + (baked[i][2] - F[1]) ** 2)
        i_x = min(range(n), key=lambda i: (baked[i][0] - exit_pt[0]) ** 2 + (baked[i][2] - exit_pt[1]) ** 2)
        entry_at = (i_f + 0.5) / n
        exit_at = (i_x + 0.5) / n
    else:
        # treapta 1: aproximare pe lungimea Bezier (gresita cu ~1-10 indici)
        bez = bezier_cum(main_pts)
        L = bez[-1]
        entry_at = bez[i_fork] / L
        exit_at = (bez[i_merge] + EXIT_AFTER) / L
    hp = [(F[0] + cx, F[1] + cz) for cx, cz in hairpins]
    info = {
        "F": F, "M": M, "x_t": F[0] + x_t, "A": A, "B": B,
        "short_len": short_len, "byp_len": byp_len, "loop_len": loop_len,
        "hairpins": hp, "y_bot": y_bot, "entry_at": entry_at, "exit_at": exit_at,
        "two_stage": bool(baked),
    }
    return main_pts, mid, info


def baked_csv(R, LEG, RE, bypass):
    """Bucla principala depinde doar de forma (R, LEG, RE, ocol), nu de latimea
    benzii sau de sansa AI: un singur dump pe forma."""
    return os.path.join(ROOT, "tools", "data", "sf_serp", "main_R%s_L%s_E%s_B%s.csv" % (
        fmt(R), fmt(LEG), fmt(RE), fmt(bypass)))


def read_baked(R, LEG, RE, bypass):
    path = baked_csv(R, LEG, RE, bypass)
    if not os.path.exists(path):
        return None
    rows = []
    with open(path) as f:
        next(f)
        for line in f:
            _, x, y, z = line.strip().split(",")
            rows.append((float(x), float(y), float(z)))
    return rows


def curve_data(points, closed):
    flat = []
    for p in points:
        flat += [0, 0, 0, 0, 0, 0, p[0], p[1], p[2]]
    txt = ", ".join(("%.3f" % v).rstrip("0").rstrip(".") for v in flat)
    tilts = ", ".join("0" for _ in points)
    return ('%s_data = {\n"points": PackedVector3Array(%s),\n'
            '"tilts": PackedFloat32Array(%s)\n}\npoint_count = %d\n' % (
                "closed = true\n" if closed else "", txt, tilts, len(points)))


def fmt(v):
    return ("%.1f" % v).rstrip("0").rstrip(".")


def write(R, BW, LEG, RE, bypass, drop, ai, suffix):
    main_pts, mid, info = build(R, LEG, RE, bypass, drop)
    tag = "R%sW%s%s" % (fmt(R), fmt(2 * BW), suffix)
    tag = tag.replace(".", "p")
    name = "SondaSfSerp%s" % tag
    out = os.path.join(ROOT, "tools", name + ".tscn")
    F, M = info["F"], info["M"]
    x_t = info["x_t"]
    # portile de cronometru: 12 m INAINTE de furca, pe dreapta de apropiere
    # (x creste, |z| mic), si 20 m DUPA reintalnire, pe strada tramvaiului
    # (z creste, x ~ x_t). Aceleasi porti pentru ambele rute.
    gate_in = (F[0] - 12.0, F[1])
    gate_out = (x_t, M[1] + 20.0)
    hp = ", ".join("Vector2(%.3f, %.3f)" % h for h in info["hairpins"])
    ai_line = ["ai_shortcut_chance = %.2f" % ai] if ai is not None else []
    scene = [
        "[gd_scene format=3]", "",
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
        '[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="2_branch"]', "",
        '[sub_resource type="Curve3D" id="Curve3D_route"]\n' + curve_data(main_pts, True), "",
        '[sub_resource type="Curve3D" id="Curve3D_serp"]\n' + curve_data(mid, False), "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_track")',
    ] + ai_line + [
        'custom_name = "Sonda SF serpentine %s"' % tag,
        'custom_theme = "desert"',
        'custom_world_seed_name = "sonda_sf_serp"',
        "custom_half_width = %.1f" % HALF_WIDTH,
        'custom_gate_model = "none"',
        "metadata/serp_fork = Vector3(%.3f, %.3f, %.3f)" % (F[0], Y_TOP, F[1]),
        "metadata/serp_merge = Vector3(%.3f, %.3f, %.3f)" % (M[0], info["y_bot"], M[1]),
        "metadata/serp_gate_in = Vector2(%.3f, %.3f)" % gate_in,
        "metadata/serp_gate_out = Vector2(%.3f, %.3f)" % gate_out,
        "metadata/serp_tram_x = %.3f" % x_t,
        "metadata/serp_hairpins = [%s]" % hp,
        "metadata/serp_radius = %.2f" % R,
        "metadata/serp_branch_hw = %.2f" % BW,
        "metadata/serp_short_len = %.2f" % info["short_len"],
        "metadata/serp_bypass_len = %.2f" % info["byp_len"],
        "metadata/serp_drop = %.2f" % drop,
        "",
        '[node name="Path" type="Path3D" parent="."]',
        'curve = SubResource("Curve3D_route")', "",
        '[node name="Serpentine" type="Path3D" parent="."]',
        'curve = SubResource("Curve3D_serp")',
        'script = ExtResource("2_branch")',
        "branch_half_width = %.2f" % BW,
        "entry_at = %.5f" % info["entry_at"],
        "exit_at = %.5f" % info["exit_at"],
        'label = "Serpentine R%s"' % fmt(R),
        # 3 = GRAVEL: o banda de pe uscat SAPA terenul (Track._branch_carve_points);
        # "deck" (4, runda 1) doar il ridica, si terenul intra in drum la ace
        # (ProbeLaneClear: 38-64 de sonde blocate de TerrainBody). Suprafata e
        # doar vizuala pentru fizica (bumpiness 0).
        "surface = %d" % int(os.environ.get("SURF", "3")),
        "",
    ]
    open(out, "w", newline="\n").write("\n".join(scene))
    print("  [%s] dump: %s" % ("treapta 2" if info["two_stage"] else "TREAPTA 1 - ruleaza dump-ul",
                                os.path.relpath(baked_csv(R, LEG, RE, bypass), ROOT)))
    print("scris %s: bucla %.0f m (%d puncte); scurtatura %.1f m (analitic, %d puncte, %.1f%%), "
          "ocol %.1f m (%.1f%%; A %.1f B %.1f), gura la x %.1f; ai_shortcut_chance %s" % (
              os.path.relpath(out, ROOT), info["loop_len"], len(main_pts), info["short_len"], len(mid),
              100 * drop / info["short_len"], info["byp_len"], 100 * drop / info["byp_len"],
              info["A"], info["B"], x_t - F[0], "implicit" if ai is None else "%.2f" % ai))


def main():
    env = os.environ
    if "R" in env or "BW" in env:
        R = float(env.get("R", "16"))
        BW = float(env.get("BW", "4.5"))
        ai = float(env["AI"]) if "AI" in env else None
        write(R, BW, float(env.get("LEG", "8")), float(env.get("RE", "16")),
              float(env.get("BYPASS", "400")), float(env.get("DROP", "11.6")),
              ai, env.get("SUFIX", ""))
        return 0
    # setul implicit: FORMA ALEASA (vezi antetul), cu AI-ul fortat pe scurtatura
    # (F), cu sansa normala (N, 0.4) si fara nimeni pe ea (O, linia de baza a
    # ocolului). Treapta 2 cere dump-ul din tools/data/sf_serp (e comis).
    for ai, suf in [(1.0, "F"), (None, "N"), (0.0, "O")]:
        write(16.0, 4.5, 8.0, 16.0, 400.0, 11.6, ai, "B400E16" + suf)
    return 0


if __name__ == "__main__":
    sys.exit(main())
