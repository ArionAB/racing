#!/usr/bin/env python3
"""Genereaza traseul San Francisco (Track25) din cod: brief docs/track_briefs/san_francisco.md
§2, §7 pasii 2-3. Doar TRASEUL: bucla, scurtatura cu serpentine (TrackBranch, ruta 1), golful,
dealul, si geometria gri a serpentinelor masurata la 1b (straturile solide din ace, fatadele de
pe exterior, acostamentul la cota drumului). Fara case, tramvaie, decor.

    python tools/gen_sf_route.py [--plan docs/asset_briefs/img/sf_route/sf_route_plan.png]

Doua treceri (ca la Angkor): generator (fractii aproximate pe poligon) -> harta curbei coapte ->
generator (fractii exacte pe indicele copt):
    godot --headless --path . res://tools/ProbeCarraraFracmap.tscn -- \\
        --scene=res://scenes/tracks/Track25.tscn --out=res://tools/data/sf_route_fracmap.tsv
Punctele de control nu se schimba intre treceri, deci harta ramane valabila cat timp traseul
nu se muta (generatorul tipareste daca harta lipseste sau e veche).

Coordonate de HARTA: x est, y nord (metri). Godot: gx = x, gz = -y (nord = -Z).

Bucla e ORARA, cu dealul in interior si golful la nord si la est (brief §2):
  A  faleza de est, spre S (+3, 14 m). Linia de start (punctul 0) la ~250 m de turnul cu ceas,
     care sta in axul ei, dincolo de coltul A/B (brief §2.0: turn <= 32 m, grila la >= 240 m).
  B  urcarea: viraj la dreapta, ~280 m spre V, viraj la dreapta, ~130 m spre N (+3 -> +53) la
     panta CONSTANTA (intersectiile pictate, nu aplatizate), cu un racord de 24 m la varf
     (sosirea pe coama e singura creasta oarba; racordul o tine sub desprindere).
  C  coama (+53): la dreapta spre E (ocolul parcului, spre sirul de case pictate), la stanga
     spre N, apoi 96 m de elan drept (contract >= 70 m) pana la prima muchie.
  D  lantul: patru blocuri `plan28s` (gen_sf_sonda.py: 28% pe 24 m, racord 17% -> 7%, 48 m,
     caderea 9,6 m) cu intersectii plate de 24 m, toate pe azimut 0 (spre N): muchiile se vad
     una de pe alta. Ferestrele lor sunt `metadata/jump_crests`.
  E  terasa (+14,6), 36 m, apoi FURCA: bucla principala o ia la stanga pe bulevardul de 400 m
     (trei viraje de 90, +14,6 -> +3, geometria ocolului din gen_sf_serpentine.py), iar E' e
     scurtatura (TrackBranch) cu forma aleasa la 1b (ace R16, carosabil 9 m), in aceleasi
     coordonate relative la furca.
  F  cheiul de nord, spre E (+3, 12 m).
  G  coltul de NE, spre S; un cot scurt (deplasare de ~30 m spre V in jurul unei piatete), apoi
     sprintul spre linia de start.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import gen_sf_serpentine as serp  # noqa: E402  (geometria scurtaturii, masurata la 1b)

ARGS = sys.argv[1:]
PLAN_PATH = None
if "--plan" in ARGS:
    PLAN_PATH = ARGS[ARGS.index("--plan") + 1]

OUT_TSCN = os.path.join(ROOT, "scenes", "tracks", "Track25.tscn")
OBJ_REL = "scenes/tracks/track25_serp_gri.obj"
OBJ_PATH = os.path.join(ROOT, *OBJ_REL.split("/"))
FRACMAP = os.path.join(HERE, "data", "sf_route_fracmap.tsv")

STEP = 12.0
HW = 7.0           # 14 m (A, B, C, D, E)
HW_QUAY = 6.0      # 12 m (F)

# --- cote (brief §2) -------------------------------------------------------------------------
Y_LOW = 3.0        # faleza, cheiul; apa la 0
Y_TOP = 53.0       # coama
BLOCK = [0.0, -3.4, -6.8, -8.8, -9.6]   # plan28s (gen_sf_sonda.py), pe pasi de 12 m
BLOCKS = 4
FLAT_STEPS = 2     # intersectia plata de 24 m
Y_TERRACE = Y_TOP + BLOCK[-1] * BLOCKS  # 14.6
RACORD_TOP = 24.0  # racordul de la varful urcarii (11,4% -> 0)
RACORD_BASE = 24.0  # si de la baza: fara el spline-ul face genunchiul 0 -> 11,4% de 13,7% (ProbeLayout)

# --- dimensiuni -------------------------------------------------------------------------------
R_AB = 30.0        # coltul A/B (faleza -> strada tramvaiului)
B_WEST = 280.0     # urcarea spre V (brief ~290; tramvaiul ~64 s la 4,5 m/s pe ea)
R_B = 24.0         # coltul din varful strazii tramvaiului (tramvaiul iese DREPT inainte)
B_NORTH = 132.0    # urcarea spre N
R_C1 = 24.0        # coama: la dreapta spre E
C_EAST = 48.0      # latura de sud a parcului (si cei ~290 m ai strazii tramvaiului spre V)
R_C2 = 36.0        # la stanga spre N, larg: iesirea din viraj tine viteza pentru elan
RUNUP = 96.0       # elanul drept pana la prima muchie (contract >= 70 m)
TERRACE = 36.0     # terasa plata de dupa ultimul bloc, pana la furca
QUAY_X_END = 238.0  # capatul de est al cheiului (inceputul coltului de NE)
R_NE = 30.0
JOG_R = 36.0       # cotul de pe faleza: doua arce de 45 de grade + o diagonala
JOG_DIAG = 12.0
JOG_Y = 236.0      # unde incepe cotul (pe faleza de sus)
START_TO_CORNER = 202.0  # linia de start -> inceputul coltului A/B

CHAIN_STEPS = int(round((RUNUP + BLOCKS * 72.0 - 24.0 + TERRACE) / STEP))  # 33 de pasi
LIP1_STEP = int(round(RUNUP / STEP))                                        # 8


def deg(a):
    return math.radians(a)


class Turtle:
    """Harta: 0 = spre est, unghiul creste spre STANGA (antiorar). Pas uniform ~12 m pe drepte si
    pe arce, cel mult 45 de grade intre doua puncte de pe arc (memoria `viraje-stranse-puncte-pe-arc`).
    Retine pentru fiecare punct lungimea analitica `s` si o eticheta de segment."""

    def __init__(self, x, y, h):
        self.x, self.y, self.h = x, y, h
        self.pts = [(x, y)]
        self.s = [0.0]
        self.seg = ["start"]
        self.len = 0.0
        self.marks = {}

    def mark(self, name):
        self.marks[name] = (len(self.pts) - 1, self.len, self.x, self.y)

    def straight(self, L, tag, steps=None):
        n = steps if steps else max(1, int(round(L / STEP)))
        for k in range(1, n + 1):
            t = k / n
            self.pts.append((self.x + math.cos(self.h) * L * t, self.y + math.sin(self.h) * L * t))
            self.s.append(self.len + L * t)
            self.seg.append(tag)
        self.x += math.cos(self.h) * L
        self.y += math.sin(self.h) * L
        self.len += L

    def arc(self, R, ang_deg, right, tag):
        sgn = -1.0 if right else 1.0
        cx = self.x + math.cos(self.h + sgn * math.pi / 2) * R
        cy = self.y + math.sin(self.h + sgn * math.pi / 2) * R
        a0 = math.atan2(self.y - cy, self.x - cx)
        L = R * deg(ang_deg)
        n = max(int(math.ceil(ang_deg / 45.0 - 1e-9)), int(round(L / STEP)), 2)
        for k in range(1, n + 1):
            a = a0 + sgn * deg(ang_deg) * k / n
            self.pts.append((cx + R * math.cos(a), cy + R * math.sin(a)))
            self.s.append(self.len + L * k / n)
            self.seg.append(tag)
        a1 = a0 + sgn * deg(ang_deg)
        self.x, self.y = cx + R * math.cos(a1), cy + R * math.sin(a1)
        self.h += sgn * deg(ang_deg)
        self.len += L
        return (cx, cy)


# =============================================================================================
# Bucla. Se construieste invers din geometria fixa: lantul pe x = 0 spre N, prima muchie in
# (0, 0); restul se leaga de el.
# =============================================================================================
# Ocolul scurtaturii (gen_sf_serpentine.build): furca F la capatul terasei, strada tramvaiului
# la x_t = 154 m mai la N, reintalnirea la 16 m spre E de axa lantului.
SERP_R, SERP_BW, SERP_LEG, SERP_RE, BYPASS, DROP = 16.0, 4.5, 8.0, 16.0, 400.0, 11.6
F_Y = (BLOCKS * 72.0 - 24.0) + TERRACE          # 300
assert abs(Y_TERRACE - Y_LOW - DROP) < 1e-6, Y_TERRACE


def serp_local():
    """Scurtatura din gen_sf_serpentine, in coordonate relative la furca (x_s inainte, z_s la
    dreapta), plus lungimile ocolului. Copia e LITERALA (aceleasi apeluri, aceleasi constante)."""
    sc = serp.Turtle(step=serp.BSTEP)
    segs = []   # (tip, s0, s1, date) — pentru acostament si ziduri

    def rec_straight(L):
        s0 = sc.len
        x0, z0, th = sc.x, sc.z, sc.th
        sc.straight(L)
        segs.append(("S", s0, sc.len, (x0, z0, th, L)))

    def rec_arc(R, ang, right):
        s0 = sc.len
        c = sc.arc(R, ang, right)
        segs.append(("A", s0, sc.len, (c[0], c[1], R, ang, right)))
        return c

    rec_straight(serp.G1)
    rec_arc(SERP_RE, 90.0, True)
    rec_straight(4.0)
    hp = [rec_arc(SERP_R, 180.0, False)]
    rec_straight(SERP_LEG)
    hp.append(rec_arc(SERP_R, 180.0, True))
    rec_straight(SERP_LEG)
    hp.append(rec_arc(SERP_R, 180.0, False))
    rec_straight(sc.z - SERP_RE)
    rec_arc(SERP_RE, 90.0, True)
    assert abs(sc.z) < 1e-6
    rec_straight(6.0)
    rec_arc(SERP_RE, 90.0, True)
    x_t, z_m, short_len = sc.x, sc.z, sc.len
    RB = serp.RB
    B = x_t - 3.0 * RB
    arcs = 3.0 * RB * math.pi / 2.0
    A = (BYPASS - arcs - B - RB - z_m) / 2.0
    return sc, segs, hp, x_t, z_m, short_len, A, B


SC, SC_SEGS, SC_HP, X_T, Z_M, SHORT_LEN, BYP_A, BYP_B = serp_local()
RB = serp.RB
M_X = Z_M                     # reintalnirea, pe harta: x = z_s
M_Y = F_Y + X_T               # 454
QUAY_Y = M_Y

# Latura de vest a urcarii si coama: x_B = -(R_C2 + C_EAST + R_C1)
X_B = -(R_C2 + C_EAST + R_C1)
Y_CTOP = -RUNUP - R_C2 - R_C1        # capatul urcarii (inceputul virajului C1)
Y_S = Y_CTOP - B_NORTH - R_B         # strada tramvaiului (latura de sud)
JOG_SHIFT = 2.0 * JOG_R * (1.0 - math.cos(deg(45))) + JOG_DIAG * math.sin(deg(45))
X_E_HI = QUAY_X_END + R_NE           # faleza de sus
X_E = X_E_HI - JOG_SHIFT             # faleza de jos (start, A)
B_WEST_REAL = (X_E - R_AB) - (X_B + R_B)
Y_START = Y_S + R_AB + START_TO_CORNER


def build_loop():
    t = Turtle(X_E, Y_START, deg(-90))
    t.mark("start")
    t.straight(START_TO_CORNER, "A")
    t.mark("A/B")
    t.arc(R_AB, 90, True, "A/B")
    t.mark("B0")                                   # baza urcarii
    t.straight(B_WEST_REAL, "B vest")
    t.mark("B colt")
    t.arc(R_B, 90, True, "B colt")
    t.straight(B_NORTH, "B nord")
    t.mark("B1")                                   # varful urcarii
    t.arc(R_C1, 90, True, "C1")
    t.straight(C_EAST, "C est")
    t.arc(R_C2, 90, False, "C2")
    t.mark("lant0")
    assert abs(t.x) < 1e-6 and abs(t.y - (-RUNUP)) < 1e-6, (t.x, t.y)
    t.straight(CHAIN_STEPS * STEP, "D", steps=CHAIN_STEPS)
    t.mark("furca")
    assert abs(t.y - F_Y) < 1e-6
    t.arc(RB, 90, False, "E ocol 1")
    t.straight(BYP_A, "E ocol A")
    t.arc(RB, 90, True, "E ocol 2")
    t.straight(BYP_B, "E ocol B")
    t.arc(RB, 90, True, "E ocol 3")
    t.mark("placa")                                # placa turnanta: coltul de NV al ocolului
    assert abs(t.y - QUAY_Y) < 1e-6, t.y
    t.straight(QUAY_X_END - t.x, "E/F strada de jos")
    t.mark("NE")
    t.arc(R_NE, 90, True, "G colt NE")
    t.straight(QUAY_Y - R_NE - JOG_Y, "G faleza")
    t.mark("cot")
    t.arc(JOG_R, 45, True, "G cot")
    t.straight(JOG_DIAG, "G cot")
    t.arc(JOG_R, 45, False, "G cot")
    t.straight(t.y - Y_START, "G sprint")
    assert abs(t.x - X_E) < 1e-6 and abs(t.y - Y_START) < 1e-6, (t.x, t.y, X_E, Y_START)
    t.pts.pop()
    t.s.pop()
    t.seg.pop()
    return t


T = build_loop()
PTS = T.pts
N = len(PTS)
TOTAL = T.len
S = T.s
MK = T.marks

i_lant0 = MK["lant0"][0]
i_lip1 = i_lant0 + LIP1_STEP
s_B0, s_B1 = MK["B0"][1], MK["B1"][1]
s_fork = MK["furca"][1]
s_M = MK["placa"][1] + (M_X - MK["placa"][2])
CLIMB = Y_TOP - Y_LOW
CLIMB_LEN = s_B1 - s_B0
GRADE = CLIMB / (CLIMB_LEN - RACORD_TOP / 2.0 - RACORD_BASE / 2.0)


def elev_s(sv):
    """Cota pe lungimea analitica (fara lant: lantul se pune pe indici)."""
    if sv < s_B0:
        return Y_LOW
    if sv <= s_B1:
        d = sv - s_B0
        rb = RACORD_BASE
        if d <= rb:
            return Y_LOW + GRADE * d * d / (2.0 * rb)
        r0 = CLIMB_LEN - RACORD_TOP
        y_rb = Y_LOW + GRADE * rb / 2.0
        if d <= r0:
            return y_rb + GRADE * (d - rb)
        u = d - r0
        return y_rb + GRADE * (r0 - rb) + GRADE * u - GRADE * u * u / (2.0 * RACORD_TOP)
    if sv <= MK["lant0"][1]:
        return Y_TOP
    if sv <= s_fork:
        return None      # lantul, pe indici
    if sv <= s_M:
        return Y_TERRACE - DROP * (sv - s_fork) / (s_M - s_fork)
    return Y_LOW


ELEV = []
for i in range(N):
    e = elev_s(S[i])
    if e is None:
        o = i - i_lip1
        if o < 0:
            e = Y_TOP
        else:
            b, r = divmod(o, 6)
            if b >= BLOCKS:
                e = Y_TERRACE
            else:
                base = Y_TOP + BLOCK[-1] * b
                e = base + (BLOCK[r] if r < len(BLOCK) else BLOCK[-1])
    ELEV.append(e)
LIPS = [i_lip1 + 6 * b for b in range(BLOCKS)]
assert abs(ELEV[LIPS[0]] - Y_TOP) < 1e-6 and abs(ELEV[LIPS[-1] + 4] - Y_TERRACE) < 1e-6
assert all(abs(PTS[k][0]) < 1e-6 for k in range(i_lant0, i_lant0 + CHAIN_STEPS + 1))


def godot(p, e):
    return (p[0], e, -p[1])


MAIN_G = [godot(PTS[i], ELEV[i]) for i in range(N)]

# =============================================================================================
# Scurtatura: punctele de mijloc, LITERAL ca gen_sf_serpentine (pas 6 m pe drepte, cel mult 45
# de grade pe arc, cota liniara pe lungime, cota buclei unde banda se suprapune cu ea).
# =============================================================================================
F_MAP = (0.0, F_Y)


def s2m(xs, zs):
    """Coordonate relative la furca (x_s inainte = N, z_s dreapta = E) -> harta."""
    return (F_MAP[0] + zs, F_MAP[1] + xs)


def s2g(xs, zs, y):
    m = s2m(xs, zs)
    return (m[0], y, -m[1])


def branch_mid():
    raw = []
    for (x, z), sk in zip(SC.pts, SC.s):
        if sk < serp.G1 + 0.5 or sk > SHORT_LEN - 0.5:
            continue
        gx, _, gz = s2g(x, z, 0.0)
        d, ym = serp.nearest_on_poly(MAIN_G, gx, gz)
        raw.append((gx, gz, sk, d, ym))
    ia = 0
    while ia + 1 < len(raw) and raw[ia + 1][3] < serp.OVERLAP_M:
        ia += 1
    ib = len(raw) - 1
    while ib - 1 > ia and raw[ib - 1][3] < serp.OVERLAP_M:
        ib -= 1
    if raw[ia][3] >= serp.OVERLAP_M:
        sa, ya = 0.0, Y_TERRACE
    else:
        sa, ya = raw[ia][2], raw[ia][4]
    if raw[ib][3] >= serp.OVERLAP_M:
        sb, yb = SHORT_LEN, Y_TERRACE - DROP
    else:
        sb, yb = raw[ib][2], raw[ib][4]
    mid = []
    for k, (gx, gz, sk, d, ym) in enumerate(raw):
        if (k <= ia and raw[ia][3] < serp.OVERLAP_M) or (k >= ib and raw[ib][3] < serp.OVERLAP_M):
            y = ym
        else:
            y = ya + (yb - ya) * (sk - sa) / max(sb - sa, 1e-6)
        mid.append((gx, y, gz))
    return mid, (sa, ya, sb, yb)


BR_MID, BR_LIN = branch_mid()


def branch_elev(sk, gx, gz):
    """Cota benzii la lungimea sk (aceeasi regula ca punctele de control)."""
    sa, ya, sb, yb = BR_LIN
    if sk <= sa or sk >= sb:
        d, ym = serp.nearest_on_poly(MAIN_G, gx, gz)
        if d < serp.OVERLAP_M:
            return ym
    sk = min(max(sk, sa), sb)
    return ya + (yb - ya) * (sk - sa) / max(sb - sa, 1e-6)


# =============================================================================================
# Statistici de geometrie (ca ProbeLayout, pe poligonul de control; verdictul il da sonda).
# =============================================================================================
def circumradius(a, b, c):
    ab = math.dist(a, b)
    bc = math.dist(b, c)
    ca = math.dist(c, a)
    area2 = abs((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1]))
    return math.inf if area2 < 1e-9 else ab * bc * ca / (2.0 * area2)


def signed_area(seq):
    return sum(seq[i][0] * seq[(i + 1) % len(seq)][1] - seq[(i + 1) % len(seq)][0] * seq[i][1]
               for i in range(len(seq))) / 2.0


print(f"bucla: {N} puncte de control, {TOTAL:.0f} m (tinta ~2350); aria cu semn "
      f"{signed_area(PTS):+.0f} (negativ = ORAR)")
print(f"urcarea: {CLIMB_LEN:.0f} m, panta {100 * GRADE:.2f}% (+ racorduri de {RACORD_BASE:.0f} m la baza si la varf); "
      f"strada tramvaiului spre V {B_WEST_REAL:.0f} m, spre N {B_NORTH:.0f} m")
min_r = min(circumradius(PTS[i - 1], PTS[i], PTS[(i + 1) % N]) for i in range(N))
print(f"raza minima (poligon): {min_r:.1f} m (prag > {HW})")
crest_idx = set()
for L in LIPS:
    for k in range(L, L + 5):
        crest_idx.add(k)
mx, mx_at = 0.0, 0
for i in range(N):
    if i in crest_idx:
        continue
    a, b = MAIN_G[i], MAIN_G[(i + 1) % N]
    d = math.hypot(b[0] - a[0], b[2] - a[2])
    sl = abs(b[1] - a[1]) / d
    if sl > mx:
        mx, mx_at = sl, i
print(f"panta maxima in afara muchiilor (poligon): {100 * mx:.1f}% la punctul {mx_at} "
      f"(frac ~{S[mx_at] / TOTAL:.3f}; tinta < 13%)")
min_sep = 1e9
for i in range(N):
    for j in range(i + 9, N):
        if N - (j - i) <= 8:
            continue
        min_sep = min(min_sep, math.dist(PTS[i], PTS[j]))
print(f"separare minima intre tronsoane (poligon): {min_sep:.1f} m (prag >= {2 * HW})")
cx = sum(p[0] for p in PTS) / N
cy = sum(p[1] for p in PTS) / N
print(f"centroid ({cx:.0f}, {cy:.0f}); departare maxima pe axe: x {max(abs(p[0] - cx) for p in PTS):.0f}, "
      f"y {max(abs(p[1] - cy) for p in PTS):.0f} (zidul lumii la 420 pe axe, Track._build_world_bounds)")
mean_y = 0.0
for i in range(N):
    a, b = MAIN_G[i], MAIN_G[(i + 1) % N]
    mean_y += math.dist(a, b) * 0.5 * (a[1] + b[1])
mean_y /= sum(math.dist(MAIN_G[i], MAIN_G[(i + 1) % N]) for i in range(N))
print(f"cota medie a soselei (estimare pe poligon): {mean_y:.2f}")
print(f"scurtatura: {SHORT_LEN:.1f} m analitic ({len(BR_MID)} puncte), ocol {s_M - s_fork:.1f} m")
print(f"furca la s {s_fork:.0f} ({s_fork / TOTAL:.3f}), reintalnirea la s {s_M:.0f} ({s_M / TOTAL:.3f})")
for name, (i, sv, x, y) in MK.items():
    print(f"  {sv / TOTAL:6.3f}  {name:10s} ({x:7.1f}, {y:7.1f})  cota {ELEV[i] if i < N else ELEV[0]:.1f}")

# =============================================================================================
# Fractii coapte (ProbeCarraraFracmap); fara harta, aproximate pe lungimea poligonului.
# =============================================================================================
FMAP = []
if os.path.exists(FRACMAP):
    for line in open(FRACMAP, encoding="utf-8"):
        tk = line.split()
        if len(tk) == 4:
            FMAP.append(tuple(float(v) for v in tk))
if FMAP:
    # harta veche (traseul s-a mutat de la ultimul dump): fractiile ar cadea pe alta bucata de drum
    worst = max(min((fx - g[0]) ** 2 + (fz - g[2]) ** 2 for fx, fz, _, _ in FMAP) for g in MAIN_G[::5])
    if worst > 1.0:
        print(f"\nATENTIE: harta de fractii e VECHE (un punct de control la {math.sqrt(worst):.1f} m de "
              f"curba coapta). Fractiile de mai jos sunt aproximate: ruleaza ProbeCarraraFracmap si "
              f"regenereaza.")
        FMAP = []
print(f"\nharta de fractii coapte: {'%d puncte' % len(FMAP) if FMAP else 'LIPSA (aprox. pe poligon)'}")


def pos_at(sv):
    sv %= TOTAL
    for j in range(N):
        s0 = S[j]
        s1 = S[j + 1] if j + 1 < N else TOTAL
        if s0 <= sv <= s1:
            a, b = PTS[j], PTS[(j + 1) % N]
            f = (sv - s0) / max(1e-9, s1 - s0)
            return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
    return PTS[0]


def F_xy(x, y):
    """(idx, len) in punctul copt cel mai apropiat de punctul de harta (x, y)."""
    if not FMAP:
        best, bs = 1e18, 0.0
        for j in range(N):
            d = math.dist(PTS[j], (x, y))
            if d < best:
                best, bs = d, S[j]
        return (bs / TOTAL, bs / TOTAL)
    gx, gz = x, -y
    best, bd = None, 1e18
    for fx, fz, fi, fl in FMAP:
        d = (fx - gx) ** 2 + (fz - gz) ** 2
        if d < bd:
            best, bd = (fi, fl), d
    return best


def F_s(sv):
    return F_xy(*pos_at(sv))


def r4(v):
    return round(v, 4)


# Ferestrele muchiilor: de la 6 m inaintea muchiei pana la 6 m dupa capatul blocului (ca sonda).
jump_crests = []
for L in LIPS:
    a = F_s(S[L] - 6.0)[0]
    b = F_s(S[L] + 54.0)[0]
    jump_crests.append((r4(a), r4(b)))
# Cheiul de 12 m (F): de la 24 m dupa reintalnire pana la coltul de NE.
width_segments = [(r4(F_s(s_M + 24.0)[0]), r4(F_s(MK["NE"][1])[0]), HW_QUAY)]
# Capetele scurtaturii, DECLARATE (gen_sf_serpentine: furca e un Y, gura un T).
entry_at = F_xy(*F_MAP)[0]
exit_at = F_xy(M_X + serp.EXIT_AFTER, M_Y)[0]
if FMAP:
    n_b = len(FMAP)
    entry_at = (round(entry_at * n_b) + 0.5) / n_b
    exit_at = (round(exit_at * n_b) + 0.5) / n_b
print(f"jump_crests (idx): {jump_crests}")
print(f"latimi (idx): {width_segments}")
print(f"scurtatura: entry_at {entry_at:.5f}  exit_at {exit_at:.5f}")

# =============================================================================================
# Geometria gri a serpentinelor (masurata la 1b, brief §2 „Scurtatura"):
#   - STRATURI: bloc plin de 0,8 m in interiorul fiecarui ac, RETRAS 2 m de la carosabil
#     (semidisc + dreptunghiul dintre brate, varful la cota bratului de sus + 0,8);
#   - ACOSTAMENT la cota drumului pe interiorul TUTUROR virajelor benzii: la ace, fasia de 2 m
#     dintre carosabil si strat; la virajele de 90 (intrare, iesire, gura), tot interiorul (felie
#     de disc pana la centru). Contract: terenul la 0,5 m dincolo de margine >= drumul - 0,3 m
#     (memoria `treapta-teren-interior-viraj-ramura`: samplerul sapa la cota celui mai apropiat
#     punct de banda - 0,25 - 0,30, deci terenul singur nu-l poate tine);
#   - FATADE pe exterior la 1 m de margine, 1,5 m (locul caselor; sonda 1b le-a avut).
# Totul e coliziune in scena + un singur mesh gri (OBJ), fara material propriu.
# =============================================================================================
BW = SERP_BW
INNER_OFF = 2.0
BED_H = 0.8
SLAB_UNDER = 0.6     # cat intra acostamentul sub carosabil
SLAB_DROP = 0.03     # cat sta sub marginea drumului (fara buza, fara z-fighting)
WALL_OFF, WALL_H, WALL_D = 1.0, 1.5, 0.4


def sc_dense(step=0.5):
    """Linia de axa a scurtaturii, densa, din segmentele analitice: (x_s, z_s, th, sk, seg)."""
    out = []
    for si, (kind, s0, s1, d) in enumerate(SC_SEGS):
        n = max(1, int(math.ceil((s1 - s0) / step)))
        for k in range(n + (1 if si == len(SC_SEGS) - 1 else 0)):
            u = (s1 - s0) * k / n
            if kind == "S":
                x0, z0, th, _ = d
                out.append((x0 + math.cos(th) * u, z0 + math.sin(th) * u, th, s0 + u, si))
            else:
                cx_, cz_, R, ang, right = d
                sgn = 1.0 if right else -1.0
                # punctul de start al arcului = capatul segmentului precedent
                prev = SC_SEGS[si - 1] if si > 0 else None
                if k == 0:
                    pass
                # unghiul in jurul centrului: recuperat din punctul de start
                if prev is None:
                    px, pz = 0.0, 0.0
                    th_start = 0.0
                else:
                    pk, ps0, ps1, pd = prev
                    if pk == "S":
                        px = pd[0] + math.cos(pd[2]) * pd[3]
                        pz = pd[1] + math.sin(pd[2]) * pd[3]
                    else:
                        raise RuntimeError("doua arce lipite")
                a0 = math.atan2(pz - cz_, px - cx_)
                a = a0 + sgn * (u / R)
                th = a + sgn * math.pi / 2.0
                out.append((cx_ + R * math.cos(a), cz_ + R * math.sin(a), th, s0 + u, si))
    return out


DENSE = sc_dense()
DENSE_G = []
for xs, zs, th, sk, si in DENSE:
    gx, _, gz = s2g(xs, zs, 0.0)
    DENSE_G.append((gx, branch_elev(sk, gx, gz), gz, th, sk, si))


def lat_dir(th, side):
    """Directia laterala (x_s, z_s) pe partea `side` (+1 dreapta, -1 stanga) — serp.Turtle:
    dreapta = theta + 90."""
    return (math.cos(th + side * math.pi / 2.0), math.sin(th + side * math.pi / 2.0))


def road_y_near(gx, gz):
    """Cota benzii (punctul dens cel mai apropiat in plan)."""
    best, by = 1e18, 0.0
    for p in DENSE_G:
        d = (p[0] - gx) ** 2 + (p[2] - gz) ** 2
        if d < best:
            best, by = d, p[1]
    return by


tris_slab = []   # triunghiuri (godot) pentru acostament, fata in sus
boxes_wall = []  # (centru, dimensiuni, yaw) pentru fatade
prisms_bed = []  # (lista de puncte de contur (gx, gz), y_jos, y_sus) pentru straturi


def add_quad(a, b, c, d):
    """a-b-c-d in ordine; doua triunghiuri, normala in sus (se verifica si se intoarce)."""
    for t in ((a, b, c), (a, c, d)):
        u = (t[1][0] - t[0][0], t[1][1] - t[0][1], t[1][2] - t[0][2])
        v = (t[2][0] - t[0][0], t[2][1] - t[0][1], t[2][2] - t[0][2])
        ny = u[2] * v[0] - u[0] * v[2]
        tris_slab.append(t if ny > 0 else (t[0], t[2], t[1]))


def ring_pt(c_xs, c_zs, r, a, y):
    xs = c_xs + r * math.cos(a)
    zs = c_zs + r * math.sin(a)
    gx, _, gz = s2g(xs, zs, 0.0)
    return (gx, y, gz)


def ring_xz(c_xs, c_zs, r, a):
    gx, _, gz = s2g(c_xs + r * math.cos(a), c_zs + r * math.sin(a), 0.0)
    return gx, gz


def arc_info(si):
    kind, s0, s1, d = SC_SEGS[si]
    cx_, cz_, R, ang, right = d
    pk, ps0, ps1, pd = SC_SEGS[si - 1]
    px = pd[0] + math.cos(pd[2]) * pd[3]
    pz = pd[1] + math.sin(pd[2]) * pd[3]
    a0 = math.atan2(pz - cz_, px - cx_)
    sgn = 1.0 if right else -1.0
    return cx_, cz_, R, ang, sgn, a0, s0, s1


def y_on_arc(si, a):
    """Cota drumului la unghiul `a` pe arcul segmentului si."""
    cx_, cz_, R, ang, sgn, a0, s0, s1 = arc_info(si)
    u = ((a - a0) * sgn) * R
    sk = s0 + min(max(u, 0.0), s1 - s0)
    xs, zs = cx_ + R * math.cos(a), cz_ + R * math.sin(a)
    gx, _, gz = s2g(xs, zs, 0.0)
    return branch_elev(sk, gx, gz)


HAIRPIN_SEGS = [si for si, sg in enumerate(SC_SEGS) if sg[0] == "A" and abs(sg[3][3] - 180.0) < 1e-6]
NINETY_SEGS = [si for si, sg in enumerate(SC_SEGS) if sg[0] == "A" and abs(sg[3][3] - 90.0) < 1e-6]
r_edge = SERP_R - BW                 # marginea interioara a acului (11,5)
r_bed = r_edge - INNER_OFF           # stratul (9,5)
r_slab_out = r_edge + SLAB_UNDER     # acostamentul intra sub carosabil

bed_info = []
for si in HAIRPIN_SEGS:
    cx_, cz_, R, ang, sgn, a0, s0, s1 = arc_info(si)
    # bratele: segmentele drepte dinainte si de dupa ac (lungimile lor)
    arm_prev = SC_SEGS[si - 1][3][3]
    arm_next = SC_SEGS[si + 1][3][3]
    ext = min(arm_prev, arm_next)
    # axa acului: de la centru spre gura (directia opusa varfului arcului)
    a_mid = a0 + sgn * math.pi / 2.0
    ax = (-math.cos(a_mid), -math.sin(a_mid))     # spre gura
    lat = (-ax[1], ax[0])
    ys = [y_on_arc(si, a0 + sgn * math.pi * k / 24.0) for k in range(25)]
    y_top = max(ys) + BED_H
    y_bot = min(ys) - 3.0
    # conturul stratului: semidiscul (r_bed) spre varf + dreptunghiul spre gura (ext)
    outline = []
    for k in range(13):
        a = a_mid - math.pi / 2.0 + math.pi * k / 12.0
        outline.append((cx_ + r_bed * math.cos(a), cz_ + r_bed * math.sin(a)))
    p_end1 = (cx_ + ax[0] * ext + lat[0] * r_bed, cz_ + ax[1] * ext + lat[1] * r_bed)
    p_end2 = (cx_ + ax[0] * ext - lat[0] * r_bed, cz_ + ax[1] * ext - lat[1] * r_bed)
    # semidiscul merge de la a_mid-90 la a_mid+90; capetele lui sunt la +-lat
    e_first = outline[0]
    e_last = outline[-1]
    # ordonare: semicerc, apoi coltul de pe partea capatului semicercului, apoi celalalt
    def near(p, q):
        return math.dist(p, q)
    if near(e_last, p_end1) < near(e_last, p_end2):
        outline += [p_end1, p_end2]
    else:
        outline += [p_end2, p_end1]
    prisms_bed.append(([s2g(x, z, 0.0) for x, z in outline], y_bot, y_top))
    bed_info.append((s2m(cx_, cz_), y_top))
    # acostamentul: inel intre strat si carosabil pe semicerc ...
    nseg = 24
    for k in range(nseg):
        a_1 = a0 + sgn * math.pi * k / nseg
        a_2 = a0 + sgn * math.pi * (k + 1) / nseg
        y1 = y_on_arc(si, a_1) - SLAB_DROP
        y2 = y_on_arc(si, a_2) - SLAB_DROP
        add_quad(ring_pt(cx_, cz_, r_bed - 0.5, a_1, y1), ring_pt(cx_, cz_, r_slab_out, a_1, y1),
                 ring_pt(cx_, cz_, r_slab_out, a_2, y2), ring_pt(cx_, cz_, r_bed - 0.5, a_2, y2))
    # ... si fasiile de langa brate, spre gura (pe lungimea bratului mai scurt + 1 m); cota
    # fiecarui varf = cota bratului in dreptul lui (bratul coboara: o fasie plata ar iesi peste drum)
    for sgn_l in (1.0, -1.0):
        q = []
        for e_ in (0.0, ext + 1.0):
            axc = (cx_ + lat[0] * sgn_l * R + ax[0] * e_, cz_ + lat[1] * sgn_l * R + ax[1] * e_)
            gcx, _, gcz = s2g(axc[0], axc[1], 0.0)
            yy = road_y_near(gcx, gcz) - SLAB_DROP
            for rr in (r_bed - 0.5, r_slab_out):
                xs = cx_ + lat[0] * sgn_l * rr + ax[0] * e_
                zs = cz_ + lat[1] * sgn_l * rr + ax[1] * e_
                gx, _, gz = s2g(xs, zs, 0.0)
                q.append((gx, yy, gz))
        add_quad(q[0], q[1], q[3], q[2])

for si in NINETY_SEGS:
    cx_, cz_, R, ang, sgn, a0, s0, s1 = arc_info(si)
    nseg = 12
    ext_deg = 8.0
    for k in range(-1, nseg + 1):
        if k == -1:
            a_1, a_2 = a0 - sgn * deg(ext_deg), a0
        elif k == nseg:
            a_1, a_2 = a0 + sgn * deg(ang), a0 + sgn * deg(ang + ext_deg)
        else:
            a_1 = a0 + sgn * deg(ang) * k / nseg
            a_2 = a0 + sgn * deg(ang) * (k + 1) / nseg
        y1 = min(y_on_arc(si, a_1), road_y_near(*ring_xz(cx_, cz_, r_slab_out, a_1))) - SLAB_DROP
        y2 = min(y_on_arc(si, a_2), road_y_near(*ring_xz(cx_, cz_, r_slab_out, a_2))) - SLAB_DROP
        c1 = ring_pt(cx_, cz_, 0.0, a_1, y1)
        c2 = ring_pt(cx_, cz_, 0.0, a_2, y2)
        add_quad(c1, ring_pt(cx_, cz_, r_slab_out, a_1, y1), ring_pt(cx_, cz_, r_slab_out, a_2, y2), c2)
# intre virajul de iesire si cel al gurii: dreapta de 6 m, interiorul ei (spre centre)
for si in range(len(SC_SEGS) - 2):
    if si in NINETY_SEGS and si + 2 in NINETY_SEGS and SC_SEGS[si + 1][0] == "S":
        x0, z0, th, L = SC_SEGS[si + 1][3]
        side = 1.0 if SC_SEGS[si][3][4] else -1.0
        lx, lz = lat_dir(th, side)
        q2 = []
        for e_ in (0.0, L):
            sk = SC_SEGS[si + 1][1] + e_
            xc = x0 + math.cos(th) * e_
            zc = z0 + math.sin(th) * e_
            gcx, _, gcz = s2g(xc, zc, 0.0)
            yy = branch_elev(sk, gcx, gcz) - SLAB_DROP
            for rr in (BW - SLAB_UNDER, SERP_RE):
                xs = xc + lx * rr
                zs = zc + lz * rr
                gx, _, gz = s2g(xs, zs, 0.0)
                q2.append((gx, yy, gz))
        add_quad(q2[0], q2[1], q2[3], q2[2])

# Fatadele: pe exteriorul arcelor si pe partea dreptelor care nu da spre alt tronson al benzii;
# niciuna la mai putin de (latimea buclei + 3 m) de axa buclei (furca, gura).
main_xz = [(p[0], p[2]) for p in MAIN_G]


def near_main(gx, gz, lim):
    for i in range(N):
        a = main_xz[i]
        b = main_xz[(i + 1) % N]
        sx, sz = b[0] - a[0], b[1] - a[1]
        L2 = sx * sx + sz * sz
        t = max(0.0, min(1.0, ((gx - a[0]) * sx + (gz - a[1]) * sz) / max(L2, 1e-9)))
        if math.hypot(a[0] + sx * t - gx, a[1] + sz * t - gz) < lim:
            return True
    return False


def faces_branch(k, side):
    xs, zs, th, sk, si = DENSE[k]
    lx, lz = lat_dir(th, side)
    t = BW + 1.0
    while t < 2.0 * SERP_R + BW + 3.0:
        mx_, mz_ = xs + lx * t, zs + lz * t
        for j in range(0, len(DENSE), 2):
            if abs(DENSE[j][3] - sk) < 12.0:
                continue
            if math.hypot(DENSE[j][0] - mx_, DENSE[j][1] - mz_) < BW + 0.5:
                return True
        t += 1.5
    return False


wall_runs = {1.0: [], -1.0: []}
for side in (1.0, -1.0):
    run = []
    for k in range(0, len(DENSE), 3):
        xs, zs, th, sk, si = DENSE[k]
        kind = SC_SEGS[si][0]
        if kind == "A":
            right = SC_SEGS[si][3][4]
            inner_side = 1.0 if right else -1.0
            ok = side != inner_side
        else:
            ok = not faces_branch(k, side)
        lx, lz = lat_dir(th, side)
        wx_s, wz_s = xs + lx * (BW + WALL_OFF + 0.2), zs + lz * (BW + WALL_OFF + 0.2)
        gx, _, gz = s2g(wx_s, wz_s, 0.0)
        if ok and near_main(gx, gz, HW + 3.0):
            ok = False
        if ok:
            for j in range(0, len(DENSE), 2):
                if abs(DENSE[j][3] - sk) < 3.0:
                    continue
                if math.hypot(DENSE[j][0] - wx_s, DENSE[j][1] - wz_s) < BW + 0.3:
                    ok = False
                    break
        if ok:
            run.append((gx, DENSE_G[k][1], gz))
        else:
            if len(run) >= 2:
                wall_runs[side].append(run)
            run = []
    if len(run) >= 2:
        wall_runs[side].append(run)
for side, runs in wall_runs.items():
    for run in runs:
        for a, b in zip(run, run[1:]):
            L = math.hypot(b[0] - a[0], b[2] - a[2])
            if L < 0.05:
                continue
            yaw = math.atan2(b[0] - a[0], b[2] - a[2])
            ymin = min(a[1], b[1])
            h = WALL_H + 0.6
            c = ((a[0] + b[0]) / 2.0, ymin - 0.6 + h / 2.0, (a[2] + b[2]) / 2.0)
            boxes_wall.append((c, (WALL_D, h, L + 0.15), yaw))

print(f"\nserpentine (gri): {len(prisms_bed)} straturi, {len(tris_slab)} triunghiuri de acostament, "
      f"{len(boxes_wall)} segmente de fatada")

# =============================================================================================
# OBJ (vizualul gri) — un singur mesh, fara material.
# =============================================================================================
obj_v = []
obj_f = []


def obj_tri(a, b, c):
    base = len(obj_v)
    obj_v.extend([a, b, c])
    obj_f.append((base + 1, base + 2, base + 3))


for t3 in tris_slab:
    obj_tri(*t3)


def prism_faces(outline_g, y0, y1):
    """Prisma verticala din conturul (gx, _, gz), convex, in ordine; fete spre exterior."""
    pts = [(p[0], p[2]) for p in outline_g]
    area = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
               for i in range(len(pts)))
    if area > 0:
        pts = pts[::-1]
    # in (x, z) cu y in sus, o fata de sus vazuta de sus e CCW in (x, -z) => CW in (x, z)
    top = [(x, y1, z) for x, z in pts]
    bot = [(x, y0, z) for x, z in pts]
    for i in range(1, len(pts) - 1):
        obj_tri(top[0], top[i + 1], top[i])
        obj_tri(bot[0], bot[i], bot[i + 1])
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        obj_tri(bot[i], top[i], top[j])
        obj_tri(bot[i], top[j], bot[j])


for outline_g, y0, y1 in prisms_bed:
    prism_faces(outline_g, y0, y1)


def box_corners(c, size, yaw):
    hx, hy, hz = size[0] / 2.0, size[1] / 2.0, size[2] / 2.0
    cs, sn = math.cos(yaw), math.sin(yaw)
    out = []
    for dx, dz in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)):
        out.append((c[0] + dx * cs + dz * sn, c[2] - dx * sn + dz * cs))
    return out, c[1] - hy, c[1] + hy


for c, size, yaw in boxes_wall:
    ring, y0, y1 = box_corners(c, size, yaw)
    prism_faces([(x, 0.0, z) for x, z in ring], y0, y1)


with open(OBJ_PATH, "w", newline="\n") as f:
    f.write("# Track25: geometria gri a serpentinelor (tools/gen_sf_route.py). Nu se editeaza de mana.\n")
    f.write("o serpentine_gri\n")
    for v in obj_v:
        f.write("v %.3f %.3f %.3f\n" % v)
    for a, b, c in obj_f:
        va, vb, vc = obj_v[a - 1], obj_v[b - 1], obj_v[c - 1]
        u = (vb[0] - va[0], vb[1] - va[1], vb[2] - va[2])
        w = (vc[0] - va[0], vc[1] - va[1], vc[2] - va[2])
        nx = u[1] * w[2] - u[2] * w[1]
        ny = u[2] * w[0] - u[0] * w[2]
        nz = u[0] * w[1] - u[1] * w[0]
        ln = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
        f.write("vn %.4f %.4f %.4f\n" % (nx / ln, ny / ln, nz / ln))
    for k, (a, b, c) in enumerate(obj_f):
        n_ = k + 1
        f.write("f %d//%d %d//%d %d//%d\n" % (a, n_, b, n_, c, n_))
print(f"scris {OBJ_REL}: {len(obj_v)} varfuri, {len(obj_f)} triunghiuri")

# =============================================================================================
# Golful (custom_lagoon) si dealul (TerrainPeak). Apa la cota 0: offset = 0 - media soselei
# (media o calculeaza samplerul pe curba coapta; aici e estimarea pe poligon — ProbeSfRoute
# tipareste cota reala a apei).
# =============================================================================================
SHORE_N = QUAY_Y + HW_QUAY + 6.0      # 466
SHORE_E = X_E_HI + HW_QUAY + 8.0      # malul de est (faleza de sus la x_E_HI)
LAGOON = [(-470.0, SHORE_N), (SHORE_E, SHORE_N), (SHORE_E, -760.0), (900.0, -760.0),
          (900.0, 1100.0), (-470.0, 1100.0)]
SEA_OFFSET = round(0.0 - mean_y, 3)
PEAKS = [
    # (nume, x, y harta, cota, raza)
    ("Coama", -48.0, -96.0, 56.0, 130.0),
    ("FlancEst", 112.0, -100.0, 40.0, 150.0),
    ("FlancNE", 112.0, 120.0, 30.0, 130.0),
    ("FlancVest", -240.0, -40.0, 44.0, 170.0),
    ("FlancSV", -170.0, -330.0, 30.0, 140.0),
]


def V2(a, b):
    return f"Vector2({a}, {b})"


def V3(a, b, c):
    return f"Vector3({a}, {b}, {c})"


def pva(seq):
    return "PackedVector3Array(" + ", ".join(
        "0, 0, 0, 0, 0, 0, %s, %s, %s" % (("%.3f" % p[0]).rstrip("0").rstrip("."),
                                          ("%.3f" % p[1]).rstrip("0").rstrip("."),
                                          ("%.3f" % p[2]).rstrip("0").rstrip(".")) for p in seq) + ")"


def g3(v):
    return "Vector3(%.3f, %.3f, %.3f)" % v


lips_g = [MAIN_G[L] for L in LIPS]
hp_map = [s2m(c[0], c[1]) for c in SC_HP]
tower = (X_E, Y_S - 22.0)
tram_up_entry = (MK["B0"][2] + 18.0, Y_S + 30.0)   # strada laterala, pe dreapta, la baza urcarii
tram_up_exit = (X_B - 40.0, Y_S)                    # continuarea DREAPTA inainte la coltul de sus
meta = [
    "metadata/jump_crests = [%s]" % ", ".join(V2(a, b) for a, b in jump_crests),
    "metadata/sf_lips = [%s]" % ", ".join(g3(p) for p in lips_g),
    "metadata/sf_block_len = 48.0",
    "metadata/sf_profile = [%s]" % ", ".join("%.2f" % v for v in BLOCK),
    "metadata/sf_chain_azimuth_deg = 0.0",
    "metadata/sf_fork = %s" % g3(godot(F_MAP, Y_TERRACE)),
    "metadata/sf_merge = %s" % g3(godot((M_X, M_Y), Y_LOW)),
    "metadata/sf_gate_in = %s" % g3(godot((0.0, F_Y - 12.0), Y_TERRACE)),
    "metadata/sf_gate_out = %s" % g3(godot((M_X + 20.0, M_Y), Y_LOW)),
    "metadata/sf_hairpins = [%s]" % ", ".join("Vector2(%.3f, %.3f)" % (p[0], -p[1]) for p in hp_map),
    "metadata/sf_serp_radius = %.1f" % SERP_R,
    "metadata/sf_short_len = %.2f" % SHORT_LEN,
    "metadata/sf_bypass_len = %.2f" % (s_M - s_fork),
    "metadata/sf_turntable = %s" % g3(godot((MK["placa"][2], MK["placa"][3]), elev_s(MK["placa"][1]))),
    "metadata/sf_clock_tower = %s" % g3(godot(tower, Y_LOW)),
    "metadata/sf_tram_up_entry = %s" % g3(godot(tram_up_entry, Y_LOW)),
    "metadata/sf_tram_up_exit = %s" % g3(godot(tram_up_exit, elev_s(MK["B colt"][1]))),
]

# Coliziunea gri: acostament (trimesh), straturi (convex), fatade (cutii).
sub = []
nodes = []
sub.append('[sub_resource type="StandardMaterial3D" id="Mat_gri"]\ncull_mode = 2\n'
           'albedo_color = Color(0.62, 0.6, 0.57, 1)\n')
sub.append('[sub_resource type="ConcavePolygonShape3D" id="Shape_acostament"]\nbackface_collision = true\n'
           'data = PackedVector3Array(%s)\n'
           % ", ".join("%.3f, %.3f, %.3f" % v for t3 in tris_slab for v in t3))
nodes.append('[node name="SerpAcostament" type="StaticBody3D" parent="SerpentineGri"]\n')
nodes.append('[node name="Shape" type="CollisionShape3D" parent="SerpentineGri/SerpAcostament"]\n'
             'shape = SubResource("Shape_acostament")\n')
nodes.append('[node name="SerpStraturi" type="StaticBody3D" parent="SerpentineGri"]\n')
for k, (outline_g, y0, y1) in enumerate(prisms_bed):
    pts3 = []
    for p in outline_g:
        pts3 += [(p[0], y0, p[2]), (p[0], y1, p[2])]
    sub.append('[sub_resource type="ConvexPolygonShape3D" id="Shape_strat%d"]\npoints = PackedVector3Array(%s)\n'
               % (k, ", ".join("%.3f, %.3f, %.3f" % v for v in pts3)))
    nodes.append('[node name="Strat%d" type="CollisionShape3D" parent="SerpentineGri/SerpStraturi"]\n'
                 'shape = SubResource("Shape_strat%d")\n' % (k, k))
nodes.append('[node name="SerpFatade" type="StaticBody3D" parent="SerpentineGri"]\n')
box_ids = {}
for k, (c, size, yaw) in enumerate(boxes_wall):
    key = tuple(round(v, 2) for v in size)
    if key not in box_ids:
        box_ids[key] = "Box_fatada%d" % len(box_ids)
        sub.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%.2f, %.2f, %.2f)\n' % (
            box_ids[key], key[0], key[1], key[2]))
    cs, sn = math.cos(yaw), math.sin(yaw)
    nodes.append('[node name="Fatada%d" type="CollisionShape3D" parent="SerpentineGri/SerpFatade"]\n'
                 'transform = Transform3D(%.5f, 0, %.5f, 0, 1, 0, %.5f, 0, %.5f, %.3f, %.3f, %.3f)\n'
                 'shape = SubResource("%s")\n' % (k, cs, -sn, sn, cs, c[0], c[1], c[2], box_ids[key]))

peaks_txt = ""
for name, x, y, e, r in PEAKS:
    peaks_txt += (f'\n[node name="{name}" type="Marker3D" parent="Peaks"]\n'
                  f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {e}, {-y})\n'
                  f'gizmo_extents = {r}\nscript = ExtResource("2_peak")\nradius_m = {r}\n')

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="3_branch"]
[ext_resource type="ArrayMesh" path="res://{OBJ_REL}" id="4_gri"]

[sub_resource type="Curve3D" id="Curve3D_sf"]
closed = true
_data = {{
"points": {pva(MAIN_G)},
"tilts": PackedFloat32Array({", ".join("0" for _ in MAIN_G)})
}}
point_count = {len(MAIN_G)}

[sub_resource type="Curve3D" id="Curve3D_serp"]
_data = {{
"points": {pva(BR_MID)},
"tilts": PackedFloat32Array({", ".join("0" for _ in BR_MID)})
}}
point_count = {len(BR_MID)}

{chr(10).join(sub)}
[node name="Track25" type="Node3D"]
script = ExtResource("1_track")
custom_name = "San Francisco"
custom_theme = "sanfrancisco"
custom_world_seed_name = "sanfrancisco"
custom_half_width = {HW}
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_sea_level_offset = {SEA_OFFSET}
custom_lagoon = Array[Vector2]([{", ".join(V2(a, -b) for a, b in LAGOON)}])
custom_width_segments = Array[Vector3]([{", ".join(V3(*w_) for w_ in width_segments)}])
branch_smooth_level = true
terrain_pad_m = 120.0
{chr(10).join(meta)}

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_sf")

[node name="Peaks" type="Node3D" parent="."]
{peaks_txt}
[node name="Serpentine" type="Path3D" parent="."]
curve = SubResource("Curve3D_serp")
script = ExtResource("3_branch")
branch_half_width = {SERP_BW}
entry_at = {entry_at:.5f}
exit_at = {exit_at:.5f}
label = "Serpentine"
surface = 3

[node name="SerpentineGri" type="Node3D" parent="."]

[node name="Mesh" type="MeshInstance3D" parent="SerpentineGri"]
mesh = ExtResource("4_gri")
material_override = SubResource("Mat_gri")

{chr(10).join(nodes)}"""
with open(OUT_TSCN, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"scris {os.path.relpath(OUT_TSCN, ROOT)}; sea_level_offset {SEA_OFFSET}")
print(f"turnul cu ceas: harta {tower}; linia de start la {math.dist(tower, (X_E, Y_START)):.0f} m de el")
print(f"directia strazii lantului: azimut 0 (spre N); soarele temei (-28, -12): din S-SV, "
      f"la 12 grade de axa, din spate")

# =============================================================================================
# Planul de sus adnotat
# =============================================================================================
if PLAN_PATH:
    from PIL import Image, ImageDraw, ImageFont
    SC_ = 1.6
    allx = [p[0] for p in PTS] + [-470.0]
    ally = [p[1] for p in PTS]
    x0, x1 = min(p[0] for p in PTS) - 120, max(p[0] for p in PTS) + 130
    y0, y1 = min(ally) - 70, max(ally) + 90
    W, H = int((x1 - x0) * SC_), int((y1 - y0) * SC_)
    im = Image.new("RGB", (W, H), (236, 228, 205))
    d = ImageDraw.Draw(im)
    try:
        font = ImageFont.truetype("arial.ttf", 15)
        font_b = ImageFont.truetype("arialbd.ttf", 22)
        font_s = ImageFont.truetype("arial.ttf", 12)
    except OSError:
        font = font_b = font_s = ImageFont.load_default()

    def px(p):
        return ((p[0] - x0) * SC_, H - (p[1] - y0) * SC_)

    # apa
    poly = [px(q) for q in LAGOON]
    d.polygon(poly, fill=(70, 105, 150))
    # dealul: cercuri de varf
    for name, x, y, e, r in PEAKS:
        a, b = px((x - r, y + r)), px((x + r, y - r))
        d.ellipse([a[0], a[1], b[0], b[1]], outline=(190, 165, 110))
        c = px((x, y))
        d.text((c[0] - 20, c[1] - 6), f"+{e:.0f}", fill=(150, 120, 70), font=font_s)

    def col(e):
        t = max(0.0, min(1.0, (e - Y_LOW) / (Y_TOP - Y_LOW)))
        return (int(40 + 200 * t), int(90 + 60 * (1 - abs(t - 0.5) * 2)), int(200 - 170 * t))

    for i in range(N):
        a, b = MAIN_G[i], MAIN_G[(i + 1) % N]
        w = HW_QUAY if (MK["placa"][1] + (M_X - MK["placa"][2]) + 24 <= S[i] <= MK["NE"][1]) else HW
        d.line([px((a[0], -a[2])), px((b[0], -b[2]))], fill=col((a[1] + b[1]) / 2), width=int(2 * w * SC_))
    for k in range(len(DENSE_G) - 1):
        a, b = DENSE_G[k], DENSE_G[k + 1]
        d.line([px((a[0], -a[2])), px((b[0], -b[2]))], fill=(170, 70, 45), width=int(2 * BW * SC_))
    for outline_g, y0_, y1_ in prisms_bed:
        d.polygon([px((p[0], -p[2])) for p in outline_g], fill=(200, 120, 160))
    for c, size, yaw in boxes_wall:
        ring, _, _ = box_corners(c, size, yaw)
        d.polygon([px((x, -z)) for x, z in ring], fill=(90, 90, 90))
    # muchiile
    for k, L in enumerate(LIPS):
        p = PTS[L]
        a, b = px((p[0] - HW - 3, p[1])), px((p[0] + HW + 3, p[1]))
        d.line([a, b], fill=(255, 255, 255), width=5)
        d.text((b[0] + 6, b[1] - 9), f"muchia {k + 1}  +{ELEV[L]:.1f}", fill=(0, 0, 0), font=font)
    # fractii
    for k in range(0, 100, 5):
        sv = TOTAL * k / 100.0
        p = pos_at(sv)
        q = px(p)
        d.ellipse([q[0] - 3, q[1] - 3, q[0] + 3, q[1] + 3], fill=(0, 0, 0))
        d.text((q[0] + 5, q[1] + 2), f"{k / 100:.2f}", fill=(40, 40, 40), font=font_s)

    def label(p, txt, dx=8, dy=-8, f=font_b, fill=(20, 20, 20)):
        q = px(p)
        d.text((q[0] + dx, q[1] + dy), txt, fill=fill, font=f)

    label((X_E + 10, Y_START + 60), "A  faleza de est, START (+3)")
    label((X_B + 70, Y_S - 30), "B  urcarea +3 -> +53, 11,4%")
    label((X_B - 110, Y_CTOP + 40), "C  coama +53")
    label((-150, 150), "D  lantul: 4 muchii\n    spre N, +53 -> +14,6")
    label((-150, 290), "E  terasa +14,6 / furca")
    label((-120, 400), "E  ocolul 400 m\n    +14,6 -> +3")
    label((40, 380), "E'  serpentine\n     R16, 9 m")
    label((60, QUAY_Y + 20), "F  cheiul de nord (+3, 12 m)", fill=(255, 255, 255))
    label((X_E_HI + 18, 260), "G  faleza\n    (+3)", fill=(255, 255, 255))
    label((X_E_HI + 18, 30), "golful", fill=(255, 255, 255))
    # start, turn, tramvaie
    s0 = px((X_E, Y_START))
    d.line([(s0[0] - 14, s0[1]), (s0[0] + 14, s0[1])], fill=(0, 0, 0), width=4)
    q = px(tower)
    d.rectangle([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], fill=(120, 60, 30))
    d.text((q[0] + 10, q[1] - 2), f"turnul (<=32 m), {math.dist(tower, (X_E, Y_START)):.0f} m de la start",
           fill=(0, 0, 0), font=font)
    for p, txt in ((tram_up_entry, "tramvai 1: intra din strada laterala"),
                   (tram_up_exit, "tramvai 1: iese DREPT inainte"),
                   ((MK["placa"][2], MK["placa"][3]), "placa turnanta / tramvai 2 spre E")):
        q = px(p)
        d.ellipse([q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5], fill=(150, 20, 40))
        d.text((q[0] + 8, q[1] + 4), txt, fill=(150, 20, 40), font=font_s)
    # sageata de sens
    # soarele: din S-SV (azimut 192, -12 fata de axa lantului care coboara spre N)
    sun_az = deg(180.0 + 12.0)          # de unde vine, busola: 0 = N, 90 = E
    c0 = (-310.0, -250.0)
    q0 = px(c0)
    fx = math.sin(sun_az)
    fy = math.cos(sun_az)
    q1 = px((c0[0] - fx * 0.0, c0[1]))
    tip = px((c0[0] - fx * 70.0 * -1, c0[1] - fy * 70.0 * -1))
    # sageata de la soare spre centru (directia luminii)
    src = px((c0[0] + fx * 70.0, c0[1] + fy * 70.0))
    d.line([src, q0], fill=(230, 160, 30), width=5)
    d.ellipse([src[0] - 12, src[1] - 12, src[0] + 12, src[1] + 12], fill=(250, 200, 60))
    d.text((q0[0] - 80, q0[1] + 10), "soarele 28 grade, azimut -12\n(din S-SV, din spatele lantului)",
           fill=(120, 80, 0), font=font)
    # nordul
    nq = px((x1 - 60, y1 - 40))
    d.line([(nq[0], nq[1] + 40), nq], fill=(0, 0, 0), width=3)
    d.text((nq[0] - 5, nq[1] - 22), "N", fill=(0, 0, 0), font=font_b)
    d.text((10, 10), f"Track25 San Francisco — traseul ({TOTAL:.0f} m, orar). Culoarea = cota "
                     f"(albastru +3 .. rosu +53). Roz: straturile solide; gri: fatadele; caramiziu: "
                     f"scurtatura.", fill=(0, 0, 0), font=font)
    os.makedirs(os.path.dirname(os.path.abspath(PLAN_PATH)), exist_ok=True)
    im.save(PLAN_PATH)
    print("plan:", PLAN_PATH)
