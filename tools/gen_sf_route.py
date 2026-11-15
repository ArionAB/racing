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
# SF_ROUTE_DRY=1: nu scrie nimic (nici Track25.tscn, nici OBJ-ul, nici planul) — modul in care
# tools/gen_sf_pod_plan.py importa geometria traseului aprobat ca sa deseneze variantele cu pod.
DRY = os.environ.get("SF_ROUTE_DRY", "0") == "1"
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
R_NE = 30.0
# LATURA DE EST in trei gesturi (brief §2, randurile A si G; runda 2, cererea dezvoltatorului:
# runda 1 avea o dreapta de ~540 m cu un singur cot). Spre S, de la coltul de NE:
#   1. coltul de NE (F -> G), R30;
#   2. COTUL PIATETEI: doua arce de 45 de grade + o diagonala, 29,6 m spre V (piateta cu tramvaiul
#      vechi ramane intre drum si apa);
#   3. DEVIEREA de pe faleza: doua arce de 30 de grade (R50) + o diagonala, ~19 m inapoi spre E,
#      care se termina la 40 m inaintea liniei de start: dreapta de start (grila + 202 m de
#      imbranceala pana la coltul A/B) are 242 m, cu turnul in ax.
# Nicio dreapta a laturii nu trece de ~250 m (S1 172, S2 172, dreapta de start 242).
JOG_R = 36.0       # cotul piatetei: doua arce de 45 de grade + o diagonala
JOG_DIAG = 12.0
DEV_R = 50.0       # devierea de pe faleza: doua arce de 30 de grade + o diagonala
DEV_ANG = 30.0
DEV_DIAG = 12.0
DEV_BEFORE_START = 40.0   # devierea se termina cu atatia metri inaintea liniei de start
S1_LEN = 172.0            # dreapta de dupa coltul de NE, pana la cotul piatetei
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
JOG_V = 2.0 * JOG_R * math.sin(deg(45)) + JOG_DIAG * math.cos(deg(45))
DEV_SHIFT = 2.0 * DEV_R * (1.0 - math.cos(deg(DEV_ANG))) + DEV_DIAG * math.sin(deg(DEV_ANG))
DEV_V = 2.0 * DEV_R * math.sin(deg(DEV_ANG)) + DEV_DIAG * math.cos(deg(DEV_ANG))
X_E = 268.0 - JOG_SHIFT              # faleza de jos (start, A): aceeasi ca in runda 1, deci B neatinsa
X_E_HI = X_E + JOG_SHIFT - DEV_SHIFT # faleza de sus (dupa coltul de NE)
X_MID = X_E_HI - JOG_SHIFT           # intre piateta si deviere
QUAY_X_END = X_E_HI - R_NE           # capatul de est al cheiului (inceputul coltului de NE)
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
    t.straight(S1_LEN, "G faleza")
    t.mark("cot")
    t.arc(JOG_R, 45, True, "G cot piateta")
    t.straight(JOG_DIAG, "G cot piateta")
    t.arc(JOG_R, 45, False, "G cot piateta")
    t.mark("S2")
    t.straight(t.y - (Y_START + DEV_BEFORE_START + DEV_V), "G faleza 2")
    t.mark("deviere")
    t.arc(DEV_R, DEV_ANG, False, "G deviere")
    t.straight(DEV_DIAG, "G deviere")
    t.arc(DEV_R, DEV_ANG, True, "G deviere")
    t.mark("sprint")
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
BED_TIP = 10.0       # varful penei stratului, spre gura acului (m de la centrul acului)
STRIP_IN = 5.0       # fasia de langa brat intra pana la 5 m de axa acului (sub pana)
PIE_EXT_DEG = 25.0   # felia de la virajele de 90 trece de capetele arcului cu atat (iesirea: treapta
                     # de 0,3-0,4 m intre bratul acului 3 si viraj, ProbeRace la (23, 420))
SLAB_UNDER = 0.6     # cat intra acostamentul sub carosabil
# Cat sta acostamentul sub PLANUL benzii, dincolo de muchie (profilul complet: EDGE_E / EDGE_DROP).
SLAB_DROP = 0.22
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


# Cota PLANULUI benzii copte (ProbeSfRoute --dump-branch): spline-ul nu urmeaza exact cota liniara
# de aici (masurat: pana la 0,07 m), iar acostamentul sta la cativa cm de ea. Fara fisier (sau cu
# unul vechi) se foloseste cota analitica.
BR_BAKED_PATH = os.path.join(HERE, "data", "sf_route_branch.tsv")
BR_BAKED = []
if os.path.exists(BR_BAKED_PATH):
    for line in open(BR_BAKED_PATH, encoding="utf-8"):
        tk = line.split()
        if len(tk) == 3:
            BR_BAKED.append(tuple(float(v) for v in tk))
    if BR_BAKED:
        def _segd2(gx, gz):
            best = 1e18
            for a, b in zip(BR_BAKED, BR_BAKED[1:]):
                sx, sz = b[0] - a[0], b[2] - a[2]
                L2 = sx * sx + sz * sz
                t = 0.0 if L2 < 1e-9 else max(0.0, min(1.0, ((gx - a[0]) * sx + (gz - a[2]) * sz) / L2))
                best = min(best, (a[0] + sx * t - gx) ** 2 + (a[2] + sz * t - gz) ** 2)
            return best
        worst = max(_segd2(g[0], g[2]) for g in DENSE_G[60:-60:10])
        if worst > 0.8 ** 2:
            print(f"ATENTIE: banda coapta din {os.path.relpath(BR_BAKED_PATH, ROOT)} e VECHE "
                  f"({math.sqrt(worst):.1f} m): acostamentul ia cota analitica. Ruleaza ProbeSfRoute "
                  f"--dump-branch si regenereaza.")
            BR_BAKED = []
print(f"banda coapta: {'%d puncte' % len(BR_BAKED) if BR_BAKED else 'LIPSA (cota analitica)'}")


def road_y_near(gx, gz):
    """Cota planului benzii in dreptul punctului (gx, gz): proiectia pe cel mai apropiat segment
    al benzii coapte (sau al liniei dense analitice, fara fisier)."""
    pts = BR_BAKED if BR_BAKED else [(p[0], p[1], p[2]) for p in DENSE_G]
    best, bk = 1e18, 0
    for k, p in enumerate(pts):
        d = (p[0] - gx) ** 2 + (p[2] - gz) ** 2
        if d < best:
            best, bk = d, k
    by = pts[bk][1]
    bd = best
    for nb in (bk - 1, bk + 1):
        if nb < 0 or nb >= len(pts):
            continue
        a, b = pts[bk], pts[nb]
        sx, sz = b[0] - a[0], b[2] - a[2]
        L2 = sx * sx + sz * sz
        if L2 < 1e-9:
            continue
        t = max(0.0, min(1.0, ((gx - a[0]) * sx + (gz - a[2]) * sz) / L2))
        d = (a[0] + sx * t - gx) ** 2 + (a[2] + sz * t - gz) ** 2
        if d < bd:
            bd, by = d, a[1] + (b[1] - a[1]) * t
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
    u = min(max(((a - a0) * sgn) * R, 0.0), s1 - s0)
    a_cl = a0 + sgn * u / R
    xs, zs = cx_ + R * math.cos(a_cl), cz_ + R * math.sin(a_cl)
    gx, _, gz = s2g(xs, zs, 0.0)
    if BR_BAKED:
        return road_y_near(gx, gz)
    return branch_elev(s0 + u, gx, gz)


HAIRPIN_SEGS = [si for si, sg in enumerate(SC_SEGS) if sg[0] == "A" and abs(sg[3][3] - 180.0) < 1e-6]
NINETY_SEGS = [si for si, sg in enumerate(SC_SEGS) if sg[0] == "A" and abs(sg[3][3] - 90.0) < 1e-6]
r_edge = SERP_R - BW                 # marginea interioara a acului (11,5)
r_bed = r_edge - INNER_OFF           # stratul (9,5)
r_slab_out = r_edge + SLAB_UNDER     # acostamentul intra sub carosabil

# Profilul acostamentului fata de MUCHIA benzii (e = metri dincolo de muchie, spre interior; negativ
# = sub carosabil). Banda de pietris isi coboara marginea in teren cu Track.BRANCH_EDGE_SINK (0,35 m)
# pe ultimii ~2,8 m, deci un acostament la cota planului ar fi o bordura de 0,3 m chiar pe muchie
# (prima varianta: ProbeRace a gasit-o). Aici: lipit de muchie (0,33 sub plan) pe primii 0,6 m de sub
# carosabil si pana la muchie, apoi urca la 0,22 sub plan in 0,6 m si ramane acolo. La 0,5 m dincolo
# de muchie: ~0,24 sub plan (contractul cere >= plan - 0,30).
EDGE_E = (-SLAB_UNDER, 0.0, 0.6)
EDGE_DROP = (0.33, 0.33, SLAB_DROP)


def ribbon(pt, u1, u2, y1, y2, r_edge_, dir_in, r_far):
    """Fasia de acostament intre doua sectiuni (u1, u2) ale unei margini. `pt(r, u)` da punctul la
    distanta r (de la centrul virajului / de la axa benzii) pe sectiunea u; muchia benzii e la
    r_edge_, interiorul e in sensul `dir_in` (-1: spre centrul virajului, r scade; +1: r creste),
    pana la r_far. Cota = planul benzii din dreptul sectiunii - profilul de mai sus."""
    rs = [r_edge_ - dir_in * e for e in EDGE_E] + [r_far]
    ds = list(EDGE_DROP) + [SLAB_DROP]
    for k in range(len(rs) - 1):
        p1 = pt(rs[k], u1)
        p2 = pt(rs[k + 1], u1)
        p3 = pt(rs[k + 1], u2)
        p4 = pt(rs[k], u2)
        add_quad((p1[0], y1 - ds[k], p1[2]), (p2[0], y1 - ds[k + 1], p2[2]),
                 (p3[0], y2 - ds[k + 1], p3[2]), (p4[0], y2 - ds[k], p4[2]))


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
    # spre gura: o PANA cu varful la BED_TIP m de centru, nu dreptunghiul dintre brate. Masinile
    # iesite larg din virajul de dinainte (intrarea, acul vecin) intra in gura acului si o iau spre
    # banda: o fata dreapta, perpendiculara pe drumul lor, le ejecta (ProbeRace: 4-9 ejectari
    # „perete" pe 16 seed-uri la capatul stratului din acul 1). Pe pana alunecand, la ~35 de grade.
    outline.append((cx_ + ax[0] * BED_TIP, cz_ + ax[1] * BED_TIP))
    prisms_bed.append(([s2g(x, z, 0.0) for x, z in outline], y_bot, y_top))
    bed_info.append((s2m(cx_, cz_), y_top))
    # acostamentul: inel intre strat si carosabil pe semicerc ...
    nseg = 24
    for k in range(nseg):
        a_1 = a0 + sgn * math.pi * k / nseg
        a_2 = a0 + sgn * math.pi * (k + 1) / nseg
        ribbon(lambda r_, a_: ring_pt(cx_, cz_, r_, a_, 0.0), a_1, a_2,
               y_on_arc(si, a_1), y_on_arc(si, a_2), r_edge, -1.0, r_bed - 0.5)
    # ... si fasiile de langa brate, spre gura (pe lungimea bratului mai scurt + 1 m); cota
    # fiecarui capat = cota bratului in dreptul lui (bratul coboara: o fasie plata ar iesi peste drum)
    for sgn_l in (1.0, -1.0):
        ys_ = []
        for e_ in (0.0, ext + 1.0):
            axc = (cx_ + lat[0] * sgn_l * R + ax[0] * e_, cz_ + lat[1] * sgn_l * R + ax[1] * e_)
            gcx, _, gcz = s2g(axc[0], axc[1], 0.0)
            ys_.append(road_y_near(gcx, gcz))

        def arm_pt(rr, e_, sgn_l=sgn_l):
            return s2g(cx_ + lat[0] * sgn_l * rr + ax[0] * e_, cz_ + lat[1] * sgn_l * rr + ax[1] * e_, 0.0)
        ribbon(arm_pt, 0.0, ext + 1.0, ys_[0], ys_[1], r_edge, -1.0, STRIP_IN)

for si in NINETY_SEGS:
    cx_, cz_, R, ang, sgn, a0, s0, s1 = arc_info(si)
    nseg = 12
    ext_deg = PIE_EXT_DEG
    for k in range(-1, nseg + 1):
        if k == -1:
            a_1, a_2 = a0 - sgn * deg(ext_deg), a0
        elif k == nseg:
            a_1, a_2 = a0 + sgn * deg(ang), a0 + sgn * deg(ang + ext_deg)
        else:
            a_1 = a0 + sgn * deg(ang) * k / nseg
            a_2 = a0 + sgn * deg(ang) * (k + 1) / nseg
        y1 = min(y_on_arc(si, a_1), road_y_near(*ring_xz(cx_, cz_, r_slab_out, a_1)))
        y2 = min(y_on_arc(si, a_2), road_y_near(*ring_xz(cx_, cz_, r_slab_out, a_2)))
        ribbon(lambda r_, a_: ring_pt(cx_, cz_, r_, a_, 0.0), a_1, a_2, y1, y2, r_edge, -1.0, 0.0)
# intre virajul de iesire si cel al gurii: dreapta de 6 m, interiorul ei (spre centre)
for si in range(len(SC_SEGS) - 2):
    if si in NINETY_SEGS and si + 2 in NINETY_SEGS and SC_SEGS[si + 1][0] == "S":
        x0, z0, th, L = SC_SEGS[si + 1][3]
        side = 1.0 if SC_SEGS[si][3][4] else -1.0
        lx, lz = lat_dir(th, side)
        ys_ = []
        for e_ in (0.0, L):
            gcx, _, gcz = s2g(x0 + math.cos(th) * e_, z0 + math.sin(th) * e_, 0.0)
            ys_.append(road_y_near(gcx, gcz))

        def g2_pt(rr, e_):
            return s2g(x0 + math.cos(th) * e_ + lx * rr, z0 + math.sin(th) * e_ + lz * rr, 0.0)
        ribbon(g2_pt, 0.0, L, ys_[0], ys_[1], BW, 1.0, SERP_RE)

# Fatadele: pe partea care nu da spre alt tronson al benzii (regula sondei 1b, `faces_branch`);
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
    """Partea `side` e INTERIOR, cu regula sondei 1b (`probe_sf_serp.gd::_is_inner`): punctul de la
    hw + 0,5 m cade in cercul unui ac, sau pe directia laterala, pana la 2R + hw + 3 m, e alt
    tronson al benzii (la cel putin 20 m pe lungime). Acolo nu se pune fatada: e gura unui ac."""
    xs, zs, th, sk, si = DENSE[k]
    lx, lz = lat_dir(th, side)
    for hx, hz in SC_HP:
        if math.hypot(xs + lx * (BW + 0.5) - hx, zs + lz * (BW + 0.5) - hz) < SERP_R:
            return True
    t = BW + 1.0
    while t < 2.0 * SERP_R + BW + 3.0:
        mx_, mz_ = xs + lx * t, zs + lz * t
        for j in range(0, len(DENSE), 2):
            if abs(DENSE[j][3] - sk) < 20.0:
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
        if SC_SEGS[si][0] == "A" and side == (1.0 if SC_SEGS[si][3][4] else -1.0):
            ok = False      # interiorul unui viraj: acostament / strat, niciodata fatada
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

# TALUZ: orice margine a acostamentului care nu sta sub carosabil sau sub un strat e o TREAPTA de
# 0,3-0,6 m deasupra terenului (samplerul il tine la drum - 0,55) — adica exact zidul pe care
# acostamentul trebuia sa-l scoata, mutat cu cativa metri. Masurat (ProbeRace, 16 seed-uri): capatul
# fasiei de langa bratul acului 1 dadea 9 din 15 ejectari „perete" ale scurtaturii, la (13, 324).
# Fiecare astfel de margine primeste o panta de 3 m care coboara 0,7 m (23%), sub teren.
SKIRT_W, SKIRT_DROP = 3.0, 0.7


def _key(v):
    return (round(v[0], 2), round(v[2], 2))


def _inside_convex(px_, pz_, outline_g):
    pts = [(p[0], p[2]) for p in outline_g]
    sgn = 0
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        c = (b[0] - a[0]) * (pz_ - a[1]) - (b[1] - a[1]) * (px_ - a[0])
        if abs(c) < 1e-9:
            continue
        s_ = 1 if c > 0 else -1
        if sgn == 0:
            sgn = s_
        elif s_ != sgn:
            return False
    return True


def _covered(px_, pz_):
    for g in DENSE_G[::2]:
        if math.hypot(g[0] - px_, g[2] - pz_) < BW - 0.05:
            return True
    for outline_g, _, _ in prisms_bed:
        if _inside_convex(px_, pz_, outline_g):
            return True
    return False


_edges = {}
for t3 in tris_slab:
    for a_i, b_i, c_i in ((0, 1, 2), (1, 2, 0), (2, 0, 1)):
        k_ = tuple(sorted((_key(t3[a_i]), _key(t3[b_i]))))
        _edges.setdefault(k_, []).append((t3[a_i], t3[b_i], t3[c_i]))
skirts = 0
for k_, uses in list(_edges.items()):
    if len(uses) != 1:
        continue
    a, b, c = uses[0]
    mx_, mz_ = (a[0] + b[0]) / 2.0, (a[2] + b[2]) / 2.0
    ex, ez = b[0] - a[0], b[2] - a[2]
    ln = math.hypot(ex, ez)
    if ln < 0.05:
        continue
    nx_, nz_ = -ez / ln, ex / ln
    if (c[0] - mx_) * nx_ + (c[2] - mz_) * nz_ > 0:
        nx_, nz_ = -nx_, -nz_
    if _covered(mx_ + nx_ * 0.3, mz_ + nz_ * 0.3):
        continue
    a2 = (a[0] + nx_ * SKIRT_W, a[1] - SKIRT_DROP, a[2] + nz_ * SKIRT_W)
    b2 = (b[0] + nx_ * SKIRT_W, b[1] - SKIRT_DROP, b[2] + nz_ * SKIRT_W)
    add_quad(a, b, b2, a2)
    skirts += 1

print(f"\nserpentine (gri): {len(prisms_bed)} straturi, {len(tris_slab)} triunghiuri de acostament "
      f"({skirts} margini cu taluz), {len(boxes_wall)} segmente de fatada")

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


with open(os.devnull if DRY else OBJ_PATH, "w", newline="\n") as f:
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
# Tramvaiul 2 (runda 2, decizia dezvoltatorului 13 nov 2026) iese pe STANGA, spre mal, inainte de
# gura: are nevoie de un petic de chei (capatul liniei) intre strada de jos si golf. Peticul e
# taiat din golf doar pentru varianta `stanga` (vezi blocul TRAMVAIELE).
TRAM2_LAYOUT = os.environ.get("TRAM2_LAYOUT", "stanga")
TRAM2_LEFT_EXIT_X = float(os.environ.get("TRAM2_EXIT_X", "-2"))
TRAM_R_ = 14.0
if TRAM2_LAYOUT == "stanga":
    _nx0, _nx1, _ny = TRAM2_LEFT_EXIT_X - 8.0, TRAM2_LEFT_EXIT_X + TRAM_R_ + 12.0, QUAY_Y + 36.0
    LAGOON = [(-470.0, SHORE_N), (_nx0, SHORE_N), (_nx0, _ny), (_nx1, _ny), (_nx1, SHORE_N),
              (SHORE_E, SHORE_N), (SHORE_E, -760.0), (900.0, -760.0), (900.0, 1100.0), (-470.0, 1100.0)]
else:
    LAGOON = [(-470.0, SHORE_N), (SHORE_E, SHORE_N), (SHORE_E, -760.0), (900.0, -760.0),
              (900.0, 1100.0), (-470.0, 1100.0)]
SEA_OFFSET = round(0.0 - mean_y, 3)
# SOARELE (brief §4, pasul 0): 28 de grade, azimut -12 fata de axa strazii lantului, din spate.
# Conventia temei (`track.gd`, tema `sanfrancisco`): Y 0 = soare din S pe o strada care coboara
# spre N; Y creste spre E. Strada lantului are azimutul CHAIN_AZ (0 = spre N, masurat aici pe
# punctele de control ale lantului), deci Y = -12 - CHAIN_AZ. Scris pe pista (nu doar in tema),
# ca o redesenare a traseului sa-l mute odata cu strada (memoria `azimutul-soarelui-fata-de-drum`).
_c0 = PTS[i_lant0]
_c1 = PTS[i_lant0 + CHAIN_STEPS]
CHAIN_AZ = math.degrees(math.atan2(_c1[0] - _c0[0], _c1[1] - _c0[1]))
SUN_ELEV = -28
SUN_AZ = round(-12.0 - CHAIN_AZ, 1)
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
# =============================================================================================
# TRAMVAIELE (brief §2 „Ceasuri care nu impart durata turului", §3, §7 pasul 5). Doua `BusHazard`
# pe Path3D, in SENSUL cursei, cu flagurile sondei 1c: `soft_contact`, `ai_reads_lane`,
# `ai_same_direction`, `pitch_to_ground`. Placeholder gri 2,5 x 3,2 x 8,5 m (cable_car.glb nu
# exista inca). Ambele intra pe ax dintr-o strada laterala din DREAPTA cursei (de acolo pornesc
# ascunse, la TRAM_HIDE_LAT m de ax: corpul cinematic nu apare niciodata pe carosabil — memoria
# `corp-cinematic-aparut-in-masina`) cu un sfert de cerc de raza TRAM_R.
#
# TRAMVAIUL 1, URCAREA (latura de sud, spre V): intra la baza urcarii (20 m dupa coltul A/B) si
# iese DREPT INAINTE la coltul de sus (sonda 1c: iesirea laterala taia banda celor care il
# depasesc), pana la 16 m dincolo de axa laturii de nord (spatele lui la ~5 m de marginea ei).
# Ciclul ~66 s pe toata urcarea e decizia dezvoltatorului (10 nov 2026). Strada reala are 292 m
# + coltul + intrarea, deci curba are ~326 m: la 4,5 m/s ar fi 73 s de mers, adica un ciclu de
# ~77 s = EXACT turul mediu (77,4 s) — ceasul care imparte turul (lectia Stromboli). De aceea
# viteza e 5,0 m/s (ciclu 66 s, turul / ciclu = 1,17), nu 4,5.
#
# TRAMVAIUL 2, GURA SCURTATURII (strada de jos, spre E): ciclul de 29 s (turul / ciclu = 2,67) nu
# incape de la placa turnanta: placa e la 125 m de gura (ocolul de 400 m de la 1b a mutat-o), deci
# curba placa -> dincolo de gura ar avea ~165 m = 37 s, iar 37 s ~ turul / 2. Tramvaiul intra din
# strada laterala din dreapta TRAM2_BEFORE m inaintea gurii (in blocul dintre ocol si serpentine),
# trece prin fata gurii si iese in dreapta TRAM2_AFTER m dupa ea (magaziile de chei; la stanga e
# golful). Placa turnanta ramane reper de decor.
# =============================================================================================
TRAM_BODY = (2.5, 3.2, 8.5)      # latime, inaltime, lungime
TRAM_R = 14.0
TRAM_HIDE_LAT = 20.0
TRAM_Y_UP = 1.0                  # curba cu 1 m peste drum: raza de lipire porneste de la +5 m
TRAM1_SPEED, TRAM1_PERIOD = 5.0, 66.0
TRAM1_EXIT_PAST = 16.0           # cat trece de axa laturii de nord
TRAM2_SPEED, TRAM2_PERIOD = 4.5, 29.0
TRAM2_ENTRY_X = -36.0            # strada laterala a tramvaiului 2 (harta x); pe ax la x + TRAM_R
TRAM2_EXIT_X = 50.0              # unde paraseste axul spre dreapta (gura: x -5..20)
# FAZELE (`phase` = fractia curbei la incarcarea pistei; ceasul merge si in countdown, ~3,6 s).
# Tramvaiul 1 e deja pe ax, la mijlocul urcarii, cand vine plutonul in turul 1 (il desparte, ca
# in brief §2 B — sonda 1c, faza 0: 0,9% contact), niciodata in strada laterala cu plutonul strans.
# Tramvaiul 2: masurat in ProbeRace (vezi brief §7 pasul 5).
TRAM1_PHASE = float(os.environ.get("TRAM1_PHASE", "0.196"))
TRAM2_PHASE = float(os.environ.get("TRAM2_PHASE", "0.564"))
TRAM_AI = os.environ.get("TRAM_AI", "1") == "1"     # 0 = sabotaj (ai_reads_lane stins)
# Cat citeste AI-ul de pe SCURTATURA tramvaiul 2 (`BusHazard.ai_branch_reach_m`; pe bucla raman
# 90 m). Cu cei 90 m impliciti, AI-ul din serpentine se aseza pe linia lui inca din al treilea ac (si
# se oprea in strat): masurat, scurtatura pierdea 2,4 s la mediana pe trecerile care il intalneau,
# fara contact.
TRAM2_READ_M = float(os.environ.get("TRAM2_READ_M", "35"))


def _arc_pts(cx, cy, r, a0, a1, n=4):
    return [(cx + r * math.cos(a0 + (a1 - a0) * k / n), cy + r * math.sin(a0 + (a1 - a0) * k / n))
            for k in range(1, n + 1)]


def _axis(x0, x1, y):
    n = max(1, int(round(abs(x1 - x0) / STEP)))
    return [(x0 + (x1 - x0) * k / n, y) for k in range(1, n + 1)]


def _climb_elev(x):
    """Cota strazii tramvaiului 1 (latura de sud, spre V); dincolo de coltul de sus, panta
    continua drept inainte (strada pe care iese tramvaiul)."""
    x_c = MK["B colt"][2]
    if x >= MK["B0"][2]:
        return Y_LOW
    if x >= x_c:
        return elev_s(MK["B0"][1] + (MK["B0"][2] - x))
    return elev_s(MK["B colt"][1]) + GRADE * (x_c - x)


def _low_elev(x):
    """Cota strazii de jos (dupa placa; ocolul coboara liniar pana la gura)."""
    return elev_s(MK["placa"][1] + (x - MK["placa"][2])) if x < M_X else Y_LOW


X1_E = MK["B0"][2] - 20.0
TRAM1_MAP = [(X1_E, Y_S + TRAM_HIDE_LAT), (X1_E, Y_S + TRAM_R)]
TRAM1_MAP += _arc_pts(X1_E - TRAM_R, Y_S + TRAM_R, TRAM_R, 0.0, -math.pi / 2)
TRAM1_MAP += _axis(X1_E - TRAM_R, X_B - TRAM1_EXIT_PAST, Y_S)
TRAM1_G = [godot(p, _climb_elev(p[0]) + TRAM_Y_UP) for p in TRAM1_MAP]

# TRAM2_LAYOUT=placa (varianta B, de A/B): DOUA vagoane pe aceeasi linie, fiecare cu ciclul
# 2 x TRAM2_PERIOD, defazate o jumatate de ciclu (la gura trece unul la ~29 s), care pleaca de pe
# PLACA TURNANTA (brief §2 E), trec prin fata gurii, merg pe cheu si ies in dreapta la x = 100.
# TRAM2_LAYOUT=gura (runda 1, masurata: contact 14-22%): intra la x = -36, iese in DREAPTA la x = 50,
# adica dupa unirea fluxurilor — coada lui statea exact unde se varsa scurtatura in ocol.
# TRAM2_LAYOUT=stanga (implicit, runda 2): intra la TRAM2_ENTRY_X (-60), trece prin fata gurii si
# paraseste axul spre STANGA (malul, capatul liniei pe un petic de chei) incepand de la x =
# TRAM2_EXIT_X (-2): e afara de pe carosabil pe la x ~ 12, inainte de reintalnire (x ~ 22).
if TRAM2_LAYOUT == "stanga":
    _ex = TRAM2_LEFT_EXIT_X
    _en = float(os.environ.get("TRAM2_ENTRY_X", "-60"))
    TRAM2_MAP = [(_en, QUAY_Y - TRAM_HIDE_LAT), (_en, QUAY_Y - TRAM_R)]
    TRAM2_MAP += _arc_pts(_en + TRAM_R, QUAY_Y - TRAM_R, TRAM_R, math.pi, math.pi / 2)
    TRAM2_MAP += _axis(_en + TRAM_R, _ex, QUAY_Y)
    TRAM2_MAP += _arc_pts(_ex, QUAY_Y + TRAM_R, TRAM_R, -math.pi / 2, 0.0)
    TRAM2_MAP += [(_ex + TRAM_R, QUAY_Y + 26.0)]
elif TRAM2_LAYOUT == "placa":
    TRAM2_EXIT_X = 100.0
    TRAM2_MAP = [(MK["placa"][2] - 26.0, QUAY_Y)]
    TRAM2_MAP += _axis(MK["placa"][2] - 26.0, TRAM2_EXIT_X, QUAY_Y)
else:
    TRAM2_MAP = [(TRAM2_ENTRY_X, QUAY_Y - TRAM_HIDE_LAT), (TRAM2_ENTRY_X, QUAY_Y - TRAM_R)]
    TRAM2_MAP += _arc_pts(TRAM2_ENTRY_X + TRAM_R, QUAY_Y - TRAM_R, TRAM_R, math.pi, math.pi / 2)
    TRAM2_MAP += _axis(TRAM2_ENTRY_X + TRAM_R, TRAM2_EXIT_X, QUAY_Y)
if TRAM2_LAYOUT != "stanga":
    TRAM2_MAP += _arc_pts(TRAM2_EXIT_X, QUAY_Y - TRAM_R, TRAM_R, math.pi / 2, 0.0)
    TRAM2_MAP += [(TRAM2_EXIT_X + TRAM_R, QUAY_Y - TRAM_HIDE_LAT)]
TRAM2_G = [godot(p, _low_elev(p[0]) + TRAM_Y_UP) for p in TRAM2_MAP]


def _plen(seq):
    return sum(math.dist(a, b) for a, b in zip(seq, seq[1:]))


for nm, g, v, per, ph in (("tramvai 1 (urcarea)", TRAM1_G, TRAM1_SPEED, TRAM1_PERIOD, TRAM1_PHASE),
                          ("tramvai 2 (gura)", TRAM2_G, TRAM2_SPEED, TRAM2_PERIOD, TRAM2_PHASE)):
    L_ = _plen(g)
    print(f"{nm}: curba {L_:.0f} m, {L_ / v:.1f} s la {v} m/s, ciclu {per:.0f} s (ascuns "
          f"{max(per - L_ / v, 0.5):.1f} s), turul mediu 77,4 s / ciclu = {77.4 / per:.2f}, faza {ph:.3f}")
tram_up_entry = TRAM1_MAP[0]          # strada laterala, pe dreapta, la baza urcarii
tram_up_exit = TRAM1_MAP[-1]          # continuarea DREAPTA inainte la coltul de sus
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
    "metadata/sf_tram_up_exit = %s" % g3(godot(tram_up_exit, _climb_elev(tram_up_exit[0]))),
    "metadata/sf_tram_low_entry = %s" % g3(godot(TRAM2_MAP[0], _low_elev(TRAM2_MAP[0][0]))),
    "metadata/sf_tram_low_exit = %s" % g3(godot(TRAM2_MAP[-1], Y_LOW)),
    # Portile sondei de tramvaie (tools/probe_sf_watch.gd): [punct, directie] x N, pe harta Godot.
    # urcare: baza ei (B0) -> 30 m pe latura de nord; jos: 70 m dupa gura (pereche cu sf_gate_in).
    "metadata/sf_climb_gates = [%s, Vector3(-1, 0, 0), %s, Vector3(0, 0, -1)]" % (
        g3(godot((MK["B0"][2], Y_S), Y_LOW)), g3(godot((X_B, Y_S + R_B + 30.0), Y_LOW))),
    "metadata/sf_gate_out2 = %s" % g3(godot((M_X + 70.0, M_Y), Y_LOW)),
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

def _tram_node(name, curve_id, speed, period, phase, reach=0.0):
    b = "true" if TRAM_AI else "false"
    lines = [
        '[node name="%s" type="Path3D" parent="Tramvaie"]' % name,
        'curve = SubResource("%s")' % curve_id,
        'script = ExtResource("5_bus")',
        "speed = %s" % speed, "phase = %.4f" % phase, "period = %s" % period,
        "body_size = Vector3(%s, %s, %s)" % TRAM_BODY,
        "nose_side = 1", "nose_angle_deg = 20.0", "apex_outer_m = 0.0",
        "shove = 3.0", "side_accel = 8.0",
        "ai_reads_lane = " + b, "ai_same_direction = " + b,
        "soft_contact = true", "pitch_to_ground = true",
        "ai_branch_reach_m = %.1f" % reach,
        "placeholder_color = Color(0.55, 0.55, 0.55, 1)",
        "placeholder_nose_color = Color(0.42, 0.42, 0.42, 1)",
    ]
    return chr(10) + chr(10).join(lines) + chr(10)


tram_nodes = _tram_node("Tramvai1", "Curve3D_tram1", TRAM1_SPEED, TRAM1_PERIOD, TRAM1_PHASE)
if TRAM2_LAYOUT == "placa":
    _p2 = 2.0 * TRAM2_PERIOD
    _off = 0.5 * _p2 * TRAM2_SPEED / _plen(TRAM2_G)
    tram_nodes += _tram_node("Tramvai2", "Curve3D_tram2", TRAM2_SPEED, _p2, TRAM2_PHASE, TRAM2_READ_M)
    tram_nodes += _tram_node("Tramvai3", "Curve3D_tram2", TRAM2_SPEED, _p2, (TRAM2_PHASE + _off) % 1.0,
                             TRAM2_READ_M)
else:
    tram_nodes += _tram_node("Tramvai2", "Curve3D_tram2", TRAM2_SPEED, TRAM2_PERIOD, TRAM2_PHASE,
                             TRAM2_READ_M)

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="3_branch"]
[ext_resource type="ArrayMesh" path="res://{OBJ_REL}" id="4_gri"]
[ext_resource type="Script" path="res://scenes/hazards/bus_hazard.gd" id="5_bus"]

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

[sub_resource type="Curve3D" id="Curve3D_tram1"]
_data = {{
"points": {pva(TRAM1_G)},
"tilts": PackedFloat32Array({", ".join("0" for _ in TRAM1_G)})
}}
point_count = {len(TRAM1_G)}

[sub_resource type="Curve3D" id="Curve3D_tram2"]
_data = {{
"points": {pva(TRAM2_G)},
"tilts": PackedFloat32Array({", ".join("0" for _ in TRAM2_G)})
}}
point_count = {len(TRAM2_G)}

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
custom_sun_rotation_deg = Vector3({SUN_ELEV}, {SUN_AZ}, 0)
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

{chr(10).join(nodes)}
[node name="Tramvaie" type="Node3D" parent="."]
{tram_nodes}"""
with open(os.devnull if DRY else OUT_TSCN, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"scris {os.path.relpath(OUT_TSCN, ROOT)}; sea_level_offset {SEA_OFFSET}")
print(f"turnul cu ceas: harta {tower}; linia de start la {math.dist(tower, (X_E, Y_START)):.0f} m de el")
print(f"directia strazii lantului: azimut {CHAIN_AZ:.1f} grade (0 = N); soarele pe pista "
      f"({SUN_ELEV}, {SUN_AZ}, 0): din S-SV, la 12 grade de axa, din spate")

# =============================================================================================
# Planul de sus adnotat
# =============================================================================================
if PLAN_PATH and not DRY:
    from PIL import Image, ImageDraw, ImageFont
    SC_ = 1.6
    allx = [p[0] for p in PTS] + [-470.0]
    ally = [p[1] for p in PTS]
    x0, x1 = min(p[0] for p in PTS) - 430, max(p[0] for p in PTS) + 220
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
    label((X_E_HI + 24, 330), "G  faleza (+3)", fill=(255, 255, 255))
    label((X_MID + 9, 196), "piateta", f=font, fill=(40, 40, 40))
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
                   ((MK["placa"][2], MK["placa"][3]), "placa turnanta (decor)"),
                   (TRAM2_MAP[0], "tramvai 2: intra din dreapta"),
                   (TRAM2_MAP[-1], "tramvai 2: iese spre mal" if TRAM2_LAYOUT == "stanga" else "tramvai 2: iese in dreapta")):
        q = px(p)
        d.ellipse([q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5], fill=(150, 20, 40))
        d.text((q[0] + 8, q[1] + 4), txt, fill=(150, 20, 40), font=font_s)
    # soarele: din S-SV (azimut 192, adica -12 fata de axa lantului, care coboara spre N)
    sun_from = deg(180.0 + 12.0)        # busola: 0 = N, 90 = E; de UNDE vine lumina
    c0 = (-420.0, -230.0)
    q0 = px(c0)
    src = px((c0[0] + math.sin(sun_from) * 80.0, c0[1] + math.cos(sun_from) * 80.0))
    d.line([src, q0], fill=(230, 160, 30), width=6)
    d.ellipse([src[0] - 14, src[1] - 14, src[0] + 14, src[1] + 14], fill=(250, 200, 60))
    d.polygon([(q0[0], q0[1]), (q0[0] - 9, q0[1] + 16), (q0[0] + 9, q0[1] + 16)], fill=(230, 160, 30))
    d.text((q0[0] - 150, q0[1] - 70), "soarele: 28 grade, azimut 192\n(-12 fata de axa lantului,\ndin S-SV, din spate)",
           fill=(120, 80, 0), font=font)
    # nordul
    nq = px((x1 - 60, y1 - 40))
    d.line([(nq[0], nq[1] + 40), nq], fill=(0, 0, 0), width=3)
    d.text((nq[0] - 5, nq[1] - 22), "N", fill=(0, 0, 0), font=font_b)
    d.text((10, 10), f"Track25 San Francisco — traseul ({TOTAL:.0f} m, orar). Culoarea = cota "
                     f"(albastru +3 .. rosu +53); fractiile pe lungime.", fill=(0, 0, 0), font=font)
    # INSERTIA: serpentinele marite (x -24..52, y 296..466), in coltul de vest
    IS = 5.0
    ix0, iy0 = -24.0, 296.0
    iw, ih = 76.0, 170.0
    ox, oy = 12, 60
    d.rectangle([ox - 2, oy - 2, ox + iw * IS + 2, oy + ih * IS + 2], fill=(236, 228, 205), outline=(0, 0, 0), width=2)

    def ipx(p):
        return (ox + (p[0] - ix0) * IS, oy + (iy0 + ih - p[1]) * IS)

    def inside(p):
        return ix0 <= p[0] <= ix0 + iw and iy0 <= p[1] <= iy0 + ih

    for t3 in tris_slab:
        pts2 = [(v[0], -v[2]) for v in t3]
        if all(inside(q_) for q_ in pts2):
            d.polygon([ipx(q_) for q_ in pts2], fill=(205, 200, 185))
    for i in range(N):
        a_, b_ = MAIN_G[i], MAIN_G[(i + 1) % N]
        pa, pb = (a_[0], -a_[2]), (b_[0], -b_[2])
        if inside(pa) or inside(pb):
            d.line([ipx(pa), ipx(pb)], fill=col((a_[1] + b_[1]) / 2), width=int(2 * HW * IS))
    for k in range(len(DENSE_G) - 1):
        a_, b_ = DENSE_G[k], DENSE_G[k + 1]
        d.line([ipx((a_[0], -a_[2])), ipx((b_[0], -b_[2]))], fill=(170, 70, 45), width=int(2 * BW * IS))
    for outline_g, y0_, y1_ in prisms_bed:
        d.polygon([ipx((p_[0], -p_[2])) for p_ in outline_g], fill=(200, 120, 160), outline=(120, 60, 90))
    for c, size, yaw in boxes_wall:
        ring, _, _ = box_corners(c, size, yaw)
        d.polygon([ipx((x_, -z_)) for x_, z_ in ring], fill=(60, 60, 60))
    for k in range(0, len(DENSE_G), 40):
        g_ = DENSE_G[k]
        q_ = ipx((g_[0], -g_[2]))
        d.text((q_[0] + 4, q_[1] - 6), f"+{g_[1]:.1f}", fill=(255, 255, 255), font=font_s)
    d.text((ox + 6, oy + 6), "E' serpentinele (x5): caramiziu = banda 9 m, roz = straturile solide (retrase 2 m),\n"
           "gri deschis = acostamentul la cota drumului, gri inchis = fatadele (1 m, 1,5 m)",
           fill=(0, 0, 0), font=font_s)
    fq = ipx(F_MAP)
    d.text((fq[0] - 60, fq[1] + 10), "furca (+14,6)", fill=(0, 0, 0), font=font)
    mq = ipx((M_X, M_Y))
    d.text((mq[0] + 10, mq[1] + 12), "reintalnirea (+3)", fill=(0, 0, 0), font=font)
    os.makedirs(os.path.dirname(os.path.abspath(PLAN_PATH)), exist_ok=True)
    im.save(PLAN_PATH)
    print("plan:", PLAN_PATH)
