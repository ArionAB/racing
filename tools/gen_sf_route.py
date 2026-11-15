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

BUCLA B200 (implicita din 15 nov 2026, decizia dezvoltatorului; brief §7 pasul 2b): bucla
RECONSTRUITA in jurul PODULUI ROSU carosabil, exact ca planul
docs/asset_briefs/img/sf_pod_plan/sf_pod_plan_B200.png (tools/gen_sf_pod_plan.py --variant=B):
tablier de 200 m la +20, dus-intors cu despartitorul mobil (`MovableMedianHazard`, sonda 1d),
CIRCULATIE PE STANGA pe pod (pe dreapta, strada care vine pe pod ar taia banda de intors),
STARTUL si SOSIREA pe pod (grila pe banda spre oras, imediat dupa intoarcerea-balon de pe malul
celalalt); latura de est (faleza) dispare. Spre oras: virajul de 90 de la capatul podului, strada
tramvaiului 1 ROTITA spre S (+20 -> +53), coltul de sus, coama cu bratul de 84 m spre V, elanul de
96 m, lantul, terasa, scurtatura + ocolul de 400 m, tramvaiul 2, cheiul de nord, coltul de NE si
strada de intors spre pod (+3 -> +20). Lantul, scurtatura si strada de jos raman in ACELEASI
coordonate de harta (geometria serpentinelor, tramvaiul 2 si hartile coapte ale benzii raman
valabile).

    python tools/gen_sf_route.py                       # B200 (Track25 din joc)
    SF_LAYOUT=vechi python tools/gen_sf_route.py       # bucla veche (istoric; nu scrie peste
                                                       # Track25 decat cu SF_LAYOUT_WRITE=1)
    SF_START=far0 python tools/gen_sf_route.py         # alternativa de start: linia la capatul
                                                       # benzii spre larg (inaintea balonului)
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

# Bucla: "b200" (implicit, podul rosu, decizia din 15 nov 2026) sau "vechi" (bucla cu faleza de est,
# pasii 2-5; ramane pentru tools/gen_sf_pod_plan.py si ca istoric). Bucla veche NU scrie Track25 decat
# cu SF_LAYOUT_WRITE=1 (altfel ar inlocui tacut pista din joc).
LAYOUT = os.environ.get("SF_LAYOUT", "b200")
assert LAYOUT in ("b200", "vechi"), LAYOUT
B200 = LAYOUT == "b200"
if not B200 and os.environ.get("SF_LAYOUT_WRITE", "0") != "1":
    DRY = True
# Linia de start pe B200: "far1" (planul: banda spre oras, imediat dupa intoarcere) sau "far0"
# (alternativa: capatul benzii spre larg, inaintea balonului).
START_AT = os.environ.get("SF_START", "far1")

# SF_OUT=res-relativ: scrie scena in alta parte (ex. bucla veche pentru comparatii de lumina)
OUT_TSCN = os.path.join(ROOT, *os.environ.get("SF_OUT", "scenes/tracks/Track25.tscn").split("/"))
OBJ_REL = "scenes/tracks/track25_serp_gri.obj"
OBJ_PATH = os.path.join(ROOT, *OBJ_REL.split("/"))
# Harta de fractii e per bucla SI per linie de start (fractiile pornesc de la punctul 0; garda de
# „harta veche" compara doar pozitii, deci n-ar prinde o rotire a startului).
FRACMAP = os.path.join(HERE, "data", ("sf_route_fracmap.tsv" if START_AT == "far1" else
                                      "sf_route_%s_fracmap.tsv" % START_AT) if B200 else
                       "sf_route_vechi_fracmap.tsv")

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


T_OLD = build_loop()
# Panta urcarii vechi (11,4%) e si panta strazii tramvaiului 1 pe B200 (aceeasi strada, rotita).
_MK_OLD = T_OLD.marks
CLIMB = Y_TOP - Y_LOW
CLIMB_LEN = _MK_OLD["B1"][1] - _MK_OLD["B0"][1]
GRADE = CLIMB / (CLIMB_LEN - RACORD_TOP / 2.0 - RACORD_BASE / 2.0)


def chain_elev(o):
    """Cota pe lant la `o` pasi de 12 m dupa prima muchie (o < 0: elanul de pe coama)."""
    if o < 0:
        return Y_TOP
    b, r = divmod(o, 6)
    if b >= BLOCKS:
        return Y_TERRACE
    return Y_TOP + BLOCK[-1] * b + (BLOCK[r] if r < len(BLOCK) else BLOCK[-1])


# =============================================================================================
# B200: bucla reconstruita in jurul podului rosu (geometria din tools/gen_sf_pod_plan.py, varianta
# B, tablier 200 m la +20). Podul vine din sonda 1d (tools/gen_sf_pod.py): doua benzi cu axele la
# 12,4 m, despartitor mobil +-3,5 m pe tablier, paliere de 36 m, intoarcere-balon pe malul celalalt
# (S de despartire 60 m / 8 m, R40 - R20 - R40), coridorul cu doua sensuri incepe dupa >= 60 m drepti
# (S-ul) dupa ultimul viraj. CIRCULATIE PE STANGA: banda spre larg (E) e cea de NORD.
# =============================================================================================
LANE_Z = 6.2               # axa benzii fata de axa podului (axele la 12,4 m)
SPLIT_D, SPLIT_L = 8.0, 60.0
R_BAL, R_IN = 20.0, 40.0   # balonul de intoarcere
LAND = 36.0                # palierele de la capetele tablierului
GRADE_P = 0.115            # rampa strazii de intors spre pod
EASE = 24.0                # racordurile ei (la jumatate de panta)
DECK = 200.0
DECK_Y = 20.0
DECK_HALF = 12.2           # fata interioara a parapetului exterior (sonda 1d)
HW_DECK = 9.8              # semilatimea fiecarei benzi pe tablier: 6 + 3,5 + 0,3 (sonda 1d)
OFFSET = 3.5               # despartitorul mobil, +-
X_G = 150.0                # strada de intors (fosta faleza G) pe harta
R_J = 24.0                 # virajul de 90 de la baza podului, pe banda care intra pe pod
R_T = 30.0                 # virajul de 90 la iesirea de pe pod (inaintea strazii tramvaiului)
Y_COAMA = -RUNUP - 36.0    # strada coamei (spre V) inainte de C2 (dreapta R36 spre N)
X_T = X_G + R_J - R_T      # strada tramvaiului 1 (spre S)
# Camionul despartitorului: naveta pe (200 - 2 x (30 + 15)) = 110 m la 4 m/s, 4 s de oprire la
# capete -> ciclu 63 s (turul ~83 s / 63 = 1,3: nu imparte turul, regula Stromboli; sonda avea 117 s
# pe tablierul de 300 m, adica 0,70 din turul de acum).
TRUCK_SPEED = float(os.environ.get("TRUCK_SPEED", "4.0"))
TRUCK_DWELL = float(os.environ.get("TRUCK_DWELL", "4.0"))
MEDIAN_FIX = os.environ.get("MEDIAN_FIX", "0") == "1"     # A/B: despartitor fix la axa, fara camion
MEDIAN_AI = os.environ.get("MEDIAN_AI", "1") == "1"       # 0 = SABOTAJ (ai_reads_corridor stins)


def s_curve(t, first_right, tag):
    """S-ul de 60 m cu deplasare de 8 m (sonda 1d: benzile se despart / se unesc la capete)."""
    alpha = 2.0 * math.atan2(SPLIT_D, SPLIT_L)
    rad = SPLIT_L / (2.0 * math.sin(alpha))
    t.arc(rad, math.degrees(alpha), first_right, tag)
    t.arc(rad, math.degrees(alpha), not first_right, tag)


def balloon_right(t, tag):
    """Intoarcerea-balon OGLINDITA fata de sonda (circulatie pe stanga): stanga T la R_IN,
    dreapta 180+2T la R_BAL, stanga T la R_IN."""
    w = LANE_Z + SPLIT_D
    dx = math.sqrt((R_BAL + R_IN) ** 2 - (w + R_IN) ** 2)
    theta = 90.0 - math.degrees(math.atan2(w + R_IN, dx))
    t.arc(R_IN, theta, False, tag)
    t.arc(R_BAL, 180.0 + 2.0 * theta, True, tag)
    t.arc(R_IN, theta, False, tag)


def ramp_len(rise):
    return abs(rise) / GRADE_P + EASE


def ramp_y(d, rise):
    """Cota relativa pe rampa (racord 24 m la jumatate de panta, panta, racord 24 m)."""
    L = ramp_len(rise)
    g = GRADE_P * (1 if rise >= 0 else -1)
    d = min(max(d, 0.0), L)
    if d <= EASE:
        return d * g * 0.5
    if d <= L - EASE:
        return EASE * g * 0.5 + (d - EASE) * g
    return rise - (L - d) * g * 0.5


def climb_q(d, rise, g=None, rb=RACORD_BASE, rt=RACORD_TOP):
    """Urcarea cu racorduri patratice (forma urcarii vechi), panta GRADE; dincolo de capat, plat."""
    g = g or GRADE
    L = rise / g + (rb + rt) / 2.0
    d = min(max(d, 0.0), L)
    if d <= rb:
        return g * d * d / (2.0 * rb)
    y_rb = g * rb / 2.0
    r0 = L - rt
    if d <= r0:
        return y_rb + g * (d - rb)
    u = d - r0
    return y_rb + g * (r0 - rb) + g * u - g * u * u / (2.0 * rt)


def build_b200():
    t = Turtle(0.0, -RUNUP, deg(90))
    t.mark("lant0")
    t.straight(CHAIN_STEPS * STEP, "D", steps=CHAIN_STEPS)
    t.mark("furca")
    t.arc(RB, 90, False, "E ocol 1")
    t.straight(BYP_A, "E ocol A")
    t.arc(RB, 90, True, "E ocol 2")
    t.straight(BYP_B, "E ocol B")
    t.arc(RB, 90, True, "E ocol 3")
    t.mark("placa")
    assert abs(t.y - QUAY_Y) < 1e-6
    t.straight((X_G - R_NE) - t.x, "E/F strada de jos")
    t.mark("NE")
    t.arc(R_NE, 90, True, "G colt NE")
    t.mark("G0")
    # unde incepe virajul spre pod, ca strada tramvaiului sa ajunga exact la coltul de sus dupa
    # cei B_WEST_REAL m ai ei (aceeasi strada ca in bucla veche)
    y_turn = (Y_COAMA + R_B + B_WEST_REAL + R_T + SPLIT_D + 2 * LANE_Z + SPLIT_D + R_J)
    t.straight(t.y - y_turn, "G spre pod")
    t.mark("G1")
    t.arc(R_J, 90, False, "pod baza")             # S -> E, la stanga (circulatie pe stanga)
    s_curve(t, True, "pod S")
    t.mark("pod0")                                # capul despartitorului de la baza
    t.straight(LAND, "pod palier")
    t.mark("tab0")
    t.straight(DECK, "pod tablier")
    t.mark("tab1")
    t.straight(LAND, "pod palier")
    t.mark("far0")                                # capatul benzii spre larg
    s_curve(t, False, "pod intoarcere")
    balloon_right(t, "pod intoarcere")
    s_curve(t, True, "pod intoarcere")
    t.mark("far1")                                # capul despartitorului de pe malul celalalt
    t.straight(LAND, "pod palier")
    t.mark("tab1r")
    t.straight(DECK, "pod tablier")
    t.mark("tab0r")
    t.straight(LAND, "pod palier")
    t.mark("pod1")
    s_curve(t, False, "pod S")
    rest = t.x - (X_T + R_T)
    if rest > 1e-6:
        t.straight(rest, "pod baza")
    t.arc(R_T, 90, False, "B colt A/B")           # V -> S, la stanga: strada tramvaiului (PRIMUL VIRAJ)
    t.mark("B0")
    assert abs(t.x - X_T) < 1e-6, (t.x, X_T)
    t.straight(B_WEST_REAL, "B sud")              # strada tramvaiului 1, acum spre S
    t.mark("B colt")
    t.arc(R_B, 90, True, "B colt")                # S -> V, la dreapta; tramvaiul iese drept
    t.mark("C0")
    assert abs(t.y - Y_COAMA) < 1e-6, (t.y, Y_COAMA)
    t.straight(t.x - 36.0, "C vest")              # coama, spre V (parcul, casele pictate): 84 m
    t.arc(36.0, 90, True, "C2")                   # V -> N, la dreapta: elanul de 96 m
    assert abs(t.x) < 1e-6 and abs(t.y + RUNUP) < 1e-6, (t.x, t.y)
    t.pts.pop()
    t.s.pop()
    t.seg.pop()
    mk = t.marks
    s_fork_ = mk["furca"][1]
    s_M_ = mk["placa"][1] + (M_X - mk["placa"][2])
    rise_up = DECK_Y - Y_LOW
    s_up0 = mk["G1"][1] - ramp_len(rise_up)       # rampa de intors se termina la virajul spre pod
    elev = []
    for i in range(len(t.pts)):
        sv = t.s[i]
        if sv <= s_fork_:
            elev.append(chain_elev(i - LIP1_STEP))
        elif sv <= s_M_:
            elev.append(Y_TERRACE - DROP * (sv - s_fork_) / (s_M_ - s_fork_))
        elif sv < s_up0:
            elev.append(Y_LOW)
        elif sv <= mk["G1"][1]:
            elev.append(Y_LOW + ramp_y(sv - s_up0, rise_up))
        elif sv <= mk["B0"][1]:
            elev.append(DECK_Y)
        else:
            elev.append(DECK_Y + climb_q(sv - mk["B0"][1], Y_TOP - DECK_Y))
    # punctul 0 = linia de start
    k0 = mk[START_AT][0]
    n = len(t.pts)
    s0 = t.s[k0]
    t.marks = {nm: ((v[0] - k0) % n, (v[1] - s0) % t.len, v[2], v[3]) for nm, v in mk.items()}
    t.pts = t.pts[k0:] + t.pts[:k0]
    t.s = [(v - s0) % t.len for v in t.s[k0:] + t.s[:k0]]
    t.seg = t.seg[k0:] + t.seg[:k0]
    elev = elev[k0:] + elev[:k0]
    t.s_up0 = (s_up0 - s0) % t.len
    return t, elev


if B200:
    T, ELEV = build_b200()
else:
    T = T_OLD
PTS = T.pts
N = len(PTS)
TOTAL = T.len
S = T.s
MK = T.marks

i_lant0 = MK["lant0"][0]
i_lip1 = i_lant0 + LIP1_STEP
s_B0 = MK["B0"][1]
s_B1 = MK["B1"][1] if "B1" in MK else None
s_fork = MK["furca"][1]
s_M = MK["placa"][1] + (M_X - MK["placa"][2])


def low_street_elev(sv):
    """Cota pe ocol si pe strada de jos (ambele bucle): coborare liniara furca -> reintalnire."""
    if sv <= s_M:
        return Y_TERRACE - DROP * (sv - s_fork) / (s_M - s_fork)
    return Y_LOW


def elev_s(sv):
    """Cota pe lungimea analitica (fara lant: lantul se pune pe indici). Bucla veche."""
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


if not B200:
    ELEV = []
    for i in range(N):
        e = elev_s(S[i])
        if e is None:
            e = chain_elev(i - i_lip1)
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
if B200:
    # PODUL (sonda 1d): pe tablier fiecare banda are semilatimea HW_DECK (9,8 m) — trebuie sa fie
    # „pe drum" pana la fata barierei cand ea sta pe partea cealalta, altfel `is_on_road` taxeaza
    # latimea castigata ca iarba (45%). Rampa de 30 m (Track.WIDTH_RAMP_M) e INAUNTRUL sectorului,
    # pe palier, deci la capetele tablierului latimea e deja 9,8. Cele doua benzi se SUPRAPUN la
    # mijloc, despartite fizic de bariera (exceptia voita din ProbeLayout, `two_way_corridors`).
    for a_, b_ in (("tab0", "tab1"), ("tab1r", "tab0r")):
        width_segments.append((r4(F_s(MK[a_][1] - 30.0)[0]), r4(F_s(MK[b_][1] + 30.0)[0]), HW_DECK))
    width_segments.sort()
    # Rapele-viaduct de sub tablier (golul e si SUB asfalt; plasa viaductului sub el). Fereastra =
    # tablierul; racordul rapei (RAVINE_FADE_FRAC 0,02 din tur, ~51 m) se face INAUNTRUL ei, deci
    # adancimea mare (60 m, cu podeaua la -8) aduce fundul sub apa la ~17 m de la mal; palierele
    # raman pe pamant (sonda 1d: o rapa care intra sub palier lasa fusta tablierului in drumul rotii).
    DECK_RAVINES = [(r4(F_s(MK[a_][1] + 2.0)[0]), r4(F_s(MK[b_][1] - 2.0)[0]))
                    for a_, b_ in (("tab0", "tab1"), ("tab1r", "tab0r"))]
    # Coridoarele cu doua sensuri, cu S-urile de despartire de la capete (acolo sensurile se departeaza
    # de la 12,4 m la 28,4 m), pentru ProbeLayout: exceptie NUMITA, apropierea dintre sensuri.
    TWO_WAY = [(r4(F_s(MK[a_][1] - SPLIT_L)[0]), r4(F_s(MK[b_][1] + SPLIT_L)[0]))
               for a_, b_ in (("pod0", "far0"), ("far1", "pod1"))]
    print(f"podul: rapele (idx) {DECK_RAVINES}; coridoarele cu doua sensuri {TWO_WAY}")
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
# Pasul 6: fatada de pe EXTERIORUL primului viraj de 90 (intrarea din furca, segmentele 0..2) poate
# sta mai departe de carosabil (trotuar / gradina in fata casei): acolo intra plutonul din terasa
# cu ~30 m/s, iar cine iese larg loveste fatada frontal (ejectari „perete" in acelasi punct, pe 2b).
ENTRY_WALL_OFF = float(os.environ.get("SF_ENTRY_WALL_OFF", "4.0"))
ENTRY_WALL_SEGS = 2


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
        off_ = ENTRY_WALL_OFF if si <= ENTRY_WALL_SEGS else WALL_OFF
        wx_s, wz_s = xs + lx * (BW + off_ + 0.2), zs + lz * (BW + off_ + 0.2)
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
if B200:
    # GOLFUL pe B200: cheiul de nord ca inainte (cu peticul tramvaiului 2); malul orasului la
    # COAST_N m spre E de strada de intors (x 150), apoi, de la AXIS_Y + 60 spre S, la capatul
    # podului (6 m inaintea tablierului) — capul de pod si dealul strazii tramvaiului 1 sunt uscat;
    # strâmtoarea de sub pod pana la malul celalalt (6 m dupa tablier). MALUL CELALALT (dealurile
    # aurii, cu intoarcerea-balon) e uscat la E de x_far pana la FAR_N spre N; dincolo, apa deschisa.
    _axis_y = MK["tab0"][3] - LANE_Z
    _x_city = MK["tab0"][2] - 6.0
    _x_far = MK["tab1"][2] + 6.0
    _y_cut = _axis_y + 60.0
    FAR_N = _axis_y + 110.0
    COAST_N = X_G + 40.0
    _west = LAGOON[:5] if TRAM2_LAYOUT == "stanga" else LAGOON[:1]
    LAGOON = _west + [(COAST_N, SHORE_N), (COAST_N, _y_cut), (_x_city, _y_cut), (_x_city, -760.0),
                      (_x_far, -760.0), (_x_far, FAR_N), (1400.0, FAR_N), (1400.0, 1100.0),
                      (-470.0, 1100.0)]
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
if B200:
    # Dealul se intoarce cu strada tramvaiului (acum spre S, pe x 144, +20 -> +53): flancul de est
    # urca spre colţul de sus (coama), flancul de NE coboara spre capul de pod (+20). Malul
    # celalalt: dealurile aurii, in spatele balonului (nu peste el: soseaua de acolo e la +20).
    PEAKS = [
        ("Coama", -48.0, -96.0, 56.0, 130.0),
        ("FlancEst", 190.0, -90.0, 50.0, 140.0),
        ("FlancNE", 205.0, 110.0, 30.0, 110.0),
        ("FlancVest", -240.0, -40.0, 44.0, 170.0),
        ("FlancSV", -170.0, -330.0, 30.0, 140.0),
        ("MalulCelalalt", 640.0, 90.0, 48.0, 140.0),
        ("MalulCelalaltSud", 540.0, 40.0, 34.0, 110.0),
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
if B200:
    # Pe B200 plutonul ajunge mai tarziu la ambele (startul e pe pod): fazele se trag inapoi cu
    # intarzierea sosirii, ca tramvaiul sa fie in turul 1 unde era pe bucla veche cand vine plutonul
    # (tramvaiul 1 deja pe ax, la mijlocul urcarii). Intarzierea = metrii in plus de la start pana la
    # baza urcarii / furca, la ritmul de cursa de acolo (V_EARLY, ~30 m/s; ProbeRace pas 3).
    V_EARLY = 30.0
    _dt1 = (MK["B0"][1] - _MK_OLD["B0"][1]) / V_EARLY
    _dt2 = (MK["furca"][1] - _MK_OLD["furca"][1]) / V_EARLY
    TRAM1_PHASE_DT, TRAM2_PHASE_DT = _dt1, _dt2
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


def _plen_pre(seq):
    return sum(math.dist(a, b) for a, b in zip(seq, seq[1:]))


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
    return low_street_elev(MK["placa"][1] + (x - MK["placa"][2])) if x < M_X else Y_LOW


if not B200:
    X1_E = MK["B0"][2] - 20.0
    TRAM1_MAP = [(X1_E, Y_S + TRAM_HIDE_LAT), (X1_E, Y_S + TRAM_R)]
    TRAM1_MAP += _arc_pts(X1_E - TRAM_R, Y_S + TRAM_R, TRAM_R, 0.0, -math.pi / 2)
    TRAM1_MAP += _axis(X1_E - TRAM_R, X_B - TRAM1_EXIT_PAST, Y_S)
    TRAM1_G = [godot(p, _climb_elev(p[0]) + TRAM_Y_UP) for p in TRAM1_MAP]
else:
    # Aceeasi constructie, pe strada ROTITA (spre S, x = X_T): intra din strada laterala din DREAPTA
    # (V) la 20 m dupa primul viraj, sfert de cerc R14 pe ax, iese DREPT inainte (spre S) 16 m
    # dincolo de axa coamei. Cota: urcarea strazii la distanta d de baza ei (B0); dincolo de coltul
    # de sus, panta continua drept inainte (strada pe care iese tramvaiul).
    _b0 = (MK["B0"][2], MK["B0"][3])
    _d_corner = MK["B colt"][1] - MK["B0"][1]

    def _climb_elev_b(d):
        if d <= _d_corner:
            return DECK_Y + climb_q(d, Y_TOP - DECK_Y)
        return DECK_Y + climb_q(_d_corner, Y_TOP - DECK_Y) + GRADE * (d - _d_corner)

    _e = _b0[1] - 20.0                                 # y-ul intrarii pe ax (strada merge spre -y)
    TRAM1_MAP = [(X_T - TRAM_HIDE_LAT, _e), (X_T - TRAM_R, _e)]
    TRAM1_MAP += _arc_pts(X_T - TRAM_R, _e - TRAM_R, TRAM_R, math.pi / 2, 0.0)
    _end_y = Y_COAMA - TRAM1_EXIT_PAST
    _n = max(1, int(round(((_e - TRAM_R) - _end_y) / STEP)))
    TRAM1_MAP += [(X_T, (_e - TRAM_R) + (_end_y - (_e - TRAM_R)) * k / _n) for k in range(1, _n + 1)]
    TRAM1_G = [godot(p, _climb_elev_b(max(_b0[1] - p[1], 0.0)) + TRAM_Y_UP) for p in TRAM1_MAP]
    # fazele (vezi mai sus): la incarcare tramvaiul e cu intarzierea sosirii plutonului mai in urma
    if "TRAM1_PHASE" not in os.environ:
        TRAM1_PHASE = round((0.196 - TRAM1_PHASE_DT * TRAM1_SPEED / _plen_pre(TRAM1_G)) % 1.0, 3)

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
if B200 and "TRAM2_PHASE" not in os.environ:
    TRAM2_PHASE = round((0.564 - TRAM2_PHASE_DT * TRAM2_SPEED / _plen_pre(TRAM2_G)) % 1.0, 3)


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
    "metadata/sf_turntable = %s" % g3(godot((MK["placa"][2], MK["placa"][3]), low_street_elev(MK["placa"][1]))),
] + ([
    "metadata/sf_clock_tower = %s" % g3(godot(tower, Y_LOW)),
    "metadata/sf_tram_up_entry = %s" % g3(godot(tram_up_entry, Y_LOW)),
    "metadata/sf_tram_up_exit = %s" % g3(godot(tram_up_exit, _climb_elev(tram_up_exit[0]))),
] if not B200 else [
    "metadata/sf_tram_up_entry = %s" % g3(godot(tram_up_entry, DECK_Y + climb_q(20.0, Y_TOP - DECK_Y))),
    "metadata/sf_tram_up_exit = %s" % g3(TRAM1_G[-1]),
]) + [
    "metadata/sf_tram_low_entry = %s" % g3(godot(TRAM2_MAP[0], _low_elev(TRAM2_MAP[0][0]))),
    "metadata/sf_tram_low_exit = %s" % g3(godot(TRAM2_MAP[-1], Y_LOW)),
    # Portile sondei de tramvaie (tools/probe_sf_watch.gd): [punct, directie] x N, pe harta Godot.
    # urcare: baza ei (B0) -> 30 m pe strada urmatoare dupa coltul de sus; jos: 70 m dupa gura
    # (pereche cu sf_gate_in).
    ("metadata/sf_climb_gates = [%s, Vector3(-1, 0, 0), %s, Vector3(0, 0, -1)]" % (
        g3(godot((MK["B0"][2], Y_S), Y_LOW)), g3(godot((X_B, Y_S + R_B + 30.0), Y_LOW)))) if not B200 else
    ("metadata/sf_climb_gates = [%s, Vector3(0, 0, 1), %s, Vector3(-1, 0, 0)]" % (
        g3(godot((X_T, MK["B0"][3]), DECK_Y)), g3(godot((X_T - R_B - 30.0, Y_COAMA), Y_TOP)))),
    "metadata/sf_gate_out2 = %s" % g3(godot((M_X + 70.0, M_Y), Y_LOW)),
    # strazile pe care tools/probe_sf_light.gd pune randuri de case si masoara soarele (fractii pe
    # INDEX): lantul (prima muchie -> capatul blocului 4), strada tramvaiului 1 (baza -> coltul de
    # sus), bratul coamei pana la virajul spre lant
    "metadata/sf_streets = {%s}" % ", ".join('"%s": %s' % (k_, V2(*v_)) for k_, v_ in (
        ("lant", (r4(F_s(S[LIPS[0]])[0]), r4(F_s(S[LIPS[-1]] + 48.0)[0]))),
        ("urcare", (r4(F_s(MK["B0"][1])[0]), r4(F_s(MK["B colt"][1])[0]))),
        ("coama", (r4(F_s(MK["C0"][1] if B200 else MK["B1"][1] + R_C1 * math.pi / 2)[0]),
                   r4(F_s(MK["lant0"][1] - 36.0 * math.pi / 2 if B200 else MK["lant0"][1] - R_C2 * math.pi / 2)[0]))),
    )),
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

# =============================================================================================
# PASUL 7 (brief §7 pasul 7, 15 nov 2026): MODELELE HERO. Un GLB intra in scena DOAR daca fisierul
# exista (`_p7_glb`), deci generatorul merge si cu kitul livrat pe jumatate; fara fisier ramane
# placeholderul gri al pasilor 2b/5. COLIZIUNEA nu se schimba nicaieri: vagonul are AABB-ul
# placeholderului (2,5 x 3,2 x 8,5, masurat de `PathMover` pe model), podul e pur vizual peste
# cutiile existente, utilajul si blocul raman pe cutiile hazardului.
#   SF_PAS7=0   scena pasului 6 (A/B), fara niciun model
#   SF_POD_MODEL=0 / SF_TRAM_MODEL=0 / SF_MEDIAN_MODEL=0   cate o familie stinsa
# =============================================================================================
P7 = os.environ.get("SF_PAS7", "1") == "1"
SF_MODELS = "assets/models/sanfrancisco"
P7_EXT, P7_NODES = [], []


def _p7_glb(rel, rid, flag="1"):
    """id-ul de ext_resource al GLB-ului `rel`, sau None daca fisierul lipseste / e stins."""
    if not P7 or flag != "1" or not os.path.exists(os.path.join(ROOT, *SF_MODELS.split("/"), *rel.split("/"))):
        return None
    line = '[ext_resource type="PackedScene" path="res://%s/%s" id="%s"]\n' % (SF_MODELS, rel, rid)
    if line not in P7_EXT:
        P7_EXT.append(line)
    return rid


TRAM_MODEL = _p7_glb("vehicles/cable_car.glb", "p7_tram", os.environ.get("SF_TRAM_MODEL", "1"))


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
    if TRAM_MODEL:
        # fata vagonului (clopotul, maneta) e pe -Z in GLB, deci fara corectie de orientare
        lines += ['model = ExtResource("%s")' % TRAM_MODEL, "model_yaw = 0.0"]
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

# =============================================================================================
# PODUL ROSU pe Track25 (B200; brief §7 pasul 2b). Geometria si regulile sondei 1d
# (tools/gen_sf_pod.py), in coordonatele pistei: axa podului pe harta y = AXIS_Y (Godot z = -AXIS_Y),
# tablierul de la tab0 (x 270) la tab1 (x 470) la +20; +X local al hazardului = spre E (larg).
#   - DESPARTITORUL: nodul `MovableMedianHazard` cu originea la capatul de V al tablierului, fix pe
#     paliere (36 m), mobil pe tablier, ATENUATOR (moale) la AMBELE capete ale coridorului (capul
#     de pe malul celalalt, spre traficul din balon; capul de la baza, spre traficul din virajul de
#     90). CIRCULATIE PE STANGA: sensul spre +X (larg) e pe -Z local -> `plus_dir_side = -1`;
#     `ai_reads_corridor` aprins (singura pista cu nodul);
#   - PARAPETELE exterioare: perete vertical de 1,2 m la |z| = 12,2 (fata interioara), pe tablier
#     + 12 m, cu capetele EVAZATE spre exterior (20 de grade pe 10 m); cutii statice, gri;
#   - PORTALURILE rosii la 1/4 si 3/4 din tablier: picioarele (cu coliziune) in afara parapetului,
#     traversele la +15 si +39 (fara coliziune; la +10 taiau camera de urmarire, sonda 1d);
#   - golul: rapele-viaduct de sub tablier (plasa viaductului sub el), apa golfului dedesubt si
#     SeaRespawn sub cota apei (plasa globala a temei).
# Placeholder gri (rosu doar portalurile): modelele podului nu exista inca.
# =============================================================================================
POD_EXT = ""
POD_SUB = []
POD_NODES = []
POD_PROPS = []
if B200:
    AXIS_Y = MK["tab0"][3] - LANE_Z
    GZ = -AXIS_Y
    X_D0, X_D1 = MK["tab0"][2], MK["tab1"][2]
    assert abs(MK["tab1r"][3] - (AXIS_Y - LANE_Z)) < 1e-6 and abs(X_D1 - X_D0 - DECK) < 1e-6
    _sub = {}
    # KITUL PODULUI (pasul 7): piesele `sf_bridge_*.glb`, pur vizuale, asezate pe cadrul podului
    # (origine la capatul de V al tablierului, pe fata carosabilului, pe ax; +X spre E). Cu kitul
    # de baza complet, meshurile gri/rosii `*M` ale placeholderului dispar; cutiile de coliziune
    # raman EXACT cum sunt (contractele de la 1d si 2b sunt masurate pe ele).
    _pod_flag = os.environ.get("SF_POD_MODEL", "1")
    POD_KIT = {k: _p7_glb("structures/sf_bridge_%s.glb" % k, "p7_pod_" + k, _pod_flag)
               for k in ("tower", "deck_8", "parapet_8", "flares", "cable_main", "cable_side",
                         "anchor", "walkway_8", "lamp")}
    POD_MODEL = all(POD_KIT[k] for k in ("tower", "deck_8", "parapet_8", "flares", "cable_main",
                                         "cable_side", "anchor"))
    _POD_KIT_BOXES = ("parapet", "flare", "leg", "beam")

    def _box(key, name, parent, size, xform, coll=True, mesh=True, mat="Mat_pod_gri"):
        sid = "Box_pod_%s" % key
        if sid not in _sub:
            _sub[sid] = ('[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%.3f, %.3f, %.3f)\n'
                         % (sid, size[0], size[1], size[2]))
            if not (POD_MODEL and key in _POD_KIT_BOXES):
                _sub["Mesh_pod_" + key] = ('[sub_resource type="BoxMesh" id="Mesh_pod_%s"]\n'
                                           'size = Vector3(%.3f, %.3f, %.3f)\nmaterial = SubResource("%s")\n'
                                           % (key, size[0], size[1], size[2], mat))
        tx = "transform = Transform3D(%s)\n" % ", ".join("%.5f" % v for v in xform)
        if coll:
            POD_NODES.append('[node name="%s" type="CollisionShape3D" parent="%s"]\n%sshape = SubResource("%s")\n'
                             % (name, parent, tx, sid))
        if mesh and not (POD_MODEL and key in _POD_KIT_BOXES):
            POD_NODES.append('[node name="%sM" type="MeshInstance3D" parent="%s"]\n%smesh = SubResource("Mesh_pod_%s")\n'
                             % (name, parent, tx, key))

    POD_SUB.append('[sub_resource type="StandardMaterial3D" id="Mat_pod_gri"]\nalbedo_color = Color(0.62, 0.62, 0.6, 1)\n')
    if not POD_MODEL:   # rosul placeholder al portalurilor: cu kitul, nimic nu-l mai foloseste
        POD_SUB.append('[sub_resource type="StandardMaterial3D" id="Mat_pod_rosu"]\nalbedo_color = Color(0.73, 0.21, 0.13, 1)\n')
    POD_NODES.append('[node name="Pod" type="Node3D" parent="."]\n')
    # parapetele exterioare + evazarile
    POD_NODES.append('[node name="Parapet" type="StaticBody3D" parent="Pod"]\n')
    pa, pb = X_D0 - 12.0, X_D1 + 12.0
    flare_l, flare_a = 10.0, math.radians(20.0)
    for side, nm in ((-1, "Nord"), (1, "Sud")):
        zc = GZ + side * (DECK_HALF + 0.25)
        _box("parapet", "Parapet" + nm, "Pod/Parapet", (pb - pa, 1.2, 0.5),
             (1, 0, 0, 0, 1, 0, 0, 0, 1, (pa + pb) * 0.5, DECK_Y + 0.55, zc))
        for end, xe in (("V", pa), ("E", pb)):
            dx = -1.0 if end == "V" else 1.0
            cxf = xe + dx * math.cos(flare_a) * flare_l * 0.5
            czf = zc + side * math.sin(flare_a) * flare_l * 0.5
            yaw = math.atan2(-side * math.sin(flare_a), dx * math.cos(flare_a))
            c_, s_ = math.cos(yaw), math.sin(yaw)
            # Basis(UP, yaw) pe RANDURI (sonda 1d: Transform3D din .tscn e scris pe randuri)
            _box("flare", "Evazare%s%s" % (nm, end), "Pod/Parapet", (flare_l, 1.2, 0.5),
                 (c_, 0, s_, 0, 1, 0, -s_, 0, c_, cxf, DECK_Y + 0.55, czf))
    # CAPETELE DESPARTITORULUI MUTATE IN S (runda 2, 15 nov 2026). Masurat pe B200 (8 x 16 x 250 s,
    # patru loturi): 2 treceri pe contrasens in ~2.300 — de fiecare data o masina LENTA, iesita larg
    # din virajul la stanga de dinaintea S-ului (R24 la baza podului, balonul pe malul celalalt),
    # care a trecut PE LANGA capul despartitorului si a intrat pe banda opusa (o data 21 s pe
    # contrasens, pana la o frontala). Contractul e 0. Remediul: un zid moale (meta
    # `soft_hit_crush`, ca atenuatorul) pe AXA podului, prin tot S-ul de la fiecare capat, lipit de
    # capul despartitorului: in S benzile sunt la 6,2..14,2 m de axa, deci zidul sta in afara
    # carosabilului (pe ultimii metri atinge marginea, ca despartitorul insusi). O masina iesita larg
    # din viraj loveste zidul, nu mai poate trece pe banda cealalta. `CAP_S_EXTRA` m dincolo de S,
    # spre viraj / balon (verificat: niciun punct al soselei la mai putin de semilatime + 1 m).
    CAP_S_EXTRA = float(os.environ.get("CAP_S_EXTRA", "20"))
    CAP_S = os.environ.get("CAP_S", "1") == "1"
    if CAP_S:
        POD_NODES.append('[node name="CapS" type="StaticBody3D" parent="Pod"]\nmetadata/soft_hit_crush = 1.0\n')
        cap_h = 4.3                      # de la +17 la +21,3 (coliziunea blocului: 1,3 m peste drum)
        for nm, xa, xb in (("Baza", MK["pod0"][2] - SPLIT_L - CAP_S_EXTRA, MK["pod0"][2]),
                           ("MalulCelalalt", MK["far0"][2], MK["far0"][2] + SPLIT_L + CAP_S_EXTRA)):
            _box("cap_%s" % nm.lower(), "Cap%s" % nm, "Pod/CapS", (xb - xa, cap_h, 0.6),
                 (1, 0, 0, 0, 1, 0, 0, 0, 1, (xa + xb) * 0.5, DECK_Y + 1.3 - cap_h * 0.5, GZ))
            # garda de geometrie: axa fiecarei benzi ramane la >= LANE_Z - 0,2 m de zid (ca pe coridor,
            # unde axa e la 6,2 m de despartitor); marginea soselei atinge zidul doar spre capul
            # despartitorului, unde benzile oricum se suprapun
            for k in range(0, int(xb - xa) + 1, 2):
                x_ = xa + k
                near = min(math.dist((x_, AXIS_Y), PTS[i]) for i in range(N))
                if near < LANE_Z - 0.2:
                    raise SystemExit(f"CapS {nm}: la x {x_:.0f} axa soselei e la {near:.1f} m de zid")
        print(f"capetele despartitorului mutate in S: zid moale pe axa, {SPLIT_L + CAP_S_EXTRA:.0f} m la fiecare capat")
    # portalurile: picioarele de la apa (-10) pana la varful turnului (+20 + 45)
    POD_NODES.append('[node name="Turnuri" type="StaticBody3D" parent="Pod"]\n')
    tower_h = 45.0
    leg_z = DECK_HALF + 2.3
    leg_bot = -10.0
    leg_top = DECK_Y + tower_h
    for ti, xt in enumerate((X_D0 + DECK * 0.25, X_D0 + DECK * 0.75)):
        for side in (1, -1):
            _box("leg", "T%dPicior%d" % (ti, side + 1), "Pod/Turnuri", (3.0, leg_top - leg_bot, 3.0),
                 (1, 0, 0, 0, 1, 0, 0, 0, 1, xt, (leg_top + leg_bot) * 0.5, GZ + side * leg_z),
                 mat="Mat_pod_rosu")
        for bi, yb in enumerate((DECK_Y + 15.0, DECK_Y + tower_h - 6.0)):
            _box("beam", "T%dTraversa%d" % (ti, bi), "Pod/Turnuri", (2.4, 2.4, 2 * leg_z + 3.0),
                 (1, 0, 0, 0, 1, 0, 0, 0, 1, xt, yb, GZ), coll=False, mat="Mat_pod_rosu")
    POD_SUB += list(_sub.values())
    if POD_MODEL:
        def _pod_piece(kind, name, x, flip=False, z=0.0, y=0.0):
            # cadrul podului -> lume; `flip` = rotit cu 180 de grade in jurul lui Y (capatul de E)
            r = "-1, 0, 0, 0, 1, 0, 0, 0, -1" if flip else "1, 0, 0, 0, 1, 0, 0, 0, 1"
            P7_NODES.append('[node name="%s" parent="DecorManual/Pod" instance=ExtResource("%s")]\n'
                            'transform = Transform3D(%s, %.3f, %.3f, %.3f)\nmetadata/coliziune = "none"\n'
                            % (name, POD_KIT[kind], r, X_D0 + x, DECK_Y + y, GZ + z))

        P7_NODES.append('[node name="Pod" type="Node3D" parent="DecorManual"]\n')
        for ti, xt in enumerate((DECK * 0.25, DECK * 0.75)):
            _pod_piece("tower", "Turn%d" % ti, xt)
        for k_ in range(int(round(DECK / 8.0))):
            _pod_piece("deck_8", "Tablier%02d" % k_, 8.0 * k_)
        for k_ in range(int(round((DECK + 24.0) / 8.0))):
            _pod_piece("parapet_8", "Parapet%02d" % k_, -12.0 + 8.0 * k_)
            if POD_KIT["walkway_8"]:
                _pod_piece("walkway_8", "Trotuar%02d" % k_, -12.0 + 8.0 * k_)
        _pod_piece("flares", "EvazareV", -12.0)
        _pod_piece("flares", "EvazareE", DECK + 12.0, flip=True)
        _pod_piece("cable_main", "CabluCentral", DECK * 0.25)
        _pod_piece("cable_side", "CabluV", DECK * 0.25)
        _pod_piece("cable_side", "CabluE", DECK * 0.75, flip=True)
        _pod_piece("anchor", "AncorajV", 0.0)
        _pod_piece("anchor", "AncorajE", DECK, flip=True)
        if POD_KIT["lamp"]:
            # felinarele pe trotuarul exterior (fata lui la +0,20), la 20 m, pe ambele parti, la
            # x 5, 25, ..., 195: exact intre doi tiranti (care stau din 10 in 10 m) si la 5 m de
            # turnuri (x 50 / 150). La 24 m pas, doua cadeau lipite de cate un tirant (x 40, 160).
            for k_, xl in enumerate(range(5, int(DECK), 20)):
                for side, nm in ((-1, "N"), (1, "S")):
                    _pod_piece("lamp", "Felinar%s%02d" % (nm, k_), float(xl), z=side * 13.6, y=0.20)
        print(f"podul: kitul de modele asezat ({len(P7_NODES) - 1} piese sub DecorManual/Pod); "
              f"placeholderul gri scos, cutiile de coliziune neschimbate")
    # despartitorul
    run = (DECK - 2 * (30.0 + 15.0)) / TRUCK_SPEED
    TRUCK_CYCLE = 2.0 * (run + TRUCK_DWELL)
    # FAZA: la verde (dupa ~3,6 s de numaratoare in care ceasul merge) camionul sta la capatul de E
    # (s_hi): pe aproape tot tablierul bariera e spre banda de intors (-Z), deci banda spre oras, pe
    # care pleaca grila, e LATA la start. Pleaca spre V abia dupa ce trece plutonul.
    TRUCK_PHASE = float(os.environ.get("TRUCK_PHASE", "%.4f" % (((run + 0.5) - 3.6) / TRUCK_CYCLE % 1.0)))
    POD_EXT = '[ext_resource type="PackedScene" path="res://scenes/hazards/MovableMedian.tscn" id="6_median"]\n'
    POD_NODES.append("\n".join([
        '[node name="Despartitor" parent="Pod" instance=ExtResource("6_median")]',
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)" % (X_D0, DECK_Y, GZ),
        "deck_length = %.1f" % DECK,
        "offset_m = %.2f" % OFFSET,
        "transition_m = 30.0",
        "taper_m = 30.0",
        "approach_m = %.1f" % LAND,
        "cushion_far_m = 6.0",
        "cushion_near_m = 6.0",
        "deck_half_width = %.2f" % DECK_HALF,
        "plus_dir_side = -1",
        "truck_enabled = %s" % ("false" if MEDIAN_FIX else "true"),
        "static_center = %s" % ("true" if MEDIAN_FIX else "false"),
        "truck_speed = %.2f" % TRUCK_SPEED,
        "truck_dwell_s = %.2f" % TRUCK_DWELL,
        "phase = %.4f" % TRUCK_PHASE,
        "ai_reads_corridor = %s" % ("true" if MEDIAN_AI else "false"),
    ] + ['%s = ExtResource("%s")' % (prop, rid) for prop, rid in (
        ("truck_model", _p7_glb("vehicles/sf_median_truck.glb", "p7_camion",
                                os.environ.get("SF_MEDIAN_MODEL", "1"))),
        ("block_model", _p7_glb("props/sf_median_block.glb", "p7_bloc",
                                os.environ.get("SF_MEDIAN_MODEL", "1")))) if rid] + [
        "",
    ]))
    POD_PROPS = [
        "custom_ravines = Array[Vector4]([%s])" % ", ".join(
            "Vector4(%.4f, %.4f, 60.0, 0)" % r_ for r_ in DECK_RAVINES),
        "custom_viaduct_ravines = Array[int]([0, 1])",
        "custom_viaduct_net_margin = 12.0",
        "custom_ravine_floors = Array[Vector2]([Vector2(0, -8), Vector2(1, -8)])",
    ]
    # Zidul lumii: Track._build_world_bounds pune peretii la 420 m de CENTROID (media punctelor
    # coapte). Malul celalalt trece de el (memoria `ziduri-invizibile-ale-lumii`), deci pista isi
    # declara jumatatea de latura: cea mai departata margine de sosea + 25 m.
    _seglen = [math.dist(PTS[i], PTS[(i + 1) % N]) for i in range(N)]
    _cx = sum(PTS[i][0] * _seglen[i] for i in range(N)) / TOTAL
    _cy = sum(PTS[i][1] * _seglen[i] for i in range(N)) / TOTAL
    _ext = max(max(abs(p[0] - _cx), abs(p[1] - _cy)) for p in PTS) + HW
    WORLD_HALF = float(math.ceil((_ext + 25.0) / 5.0) * 5.0)
    POD_PROPS.append("world_half_extent_m = %.1f" % WORLD_HALF)
    # GOLFUL (pasul 6, gasit de agentul foii de assets): fundul lagunei e `media soselei -
    # lagoon_depth` (TrackSideSampler._carve_lagoon), cu implicitul 20. Pe bucla veche media era
    # mica; pe B200 podul si strazile de la +20 o urca la ~23,4, deci fundul iesea la +3,4, PESTE apa
    # (0): golful era uscat peste tot, apa ramanea doar in rapele-viaduct ale podului. Fundul se
    # cere la LAGOON_BED, sub apa, ca la rapele podului (-8).
    LAGOON_BED = -8.0
    POD_PROPS.append("lagoon_depth = %.2f" % (mean_y - LAGOON_BED))
    print(f"golful: fundul lagunei la {LAGOON_BED:+.0f} (lagoon_depth {mean_y - LAGOON_BED:.2f}; implicitul 20 "
          f"l-ar fi pus la {mean_y - 20.0:+.1f}, peste apa)")
    meta += [
        "metadata/two_way_corridors = [%s]" % ", ".join(V2(a, b) for a, b in TWO_WAY),
        "metadata/sf_pod_axis = [%s, %s]" % (g3((X_D0, DECK_Y, GZ)), g3((X_D1, DECK_Y, GZ))),
        "metadata/sf_first_turn = %s" % g3(godot((X_T + R_T, MK["B0"][3] + R_T), DECK_Y)),
    ]
    print(f"podul: axa y {AXIS_Y:.1f} (Godot z {GZ:.1f}), tablier x {X_D0:.0f}..{X_D1:.0f} la +{DECK_Y:.0f}; "
          f"camion {TRUCK_SPEED} m/s, oprire {TRUCK_DWELL} s, ciclu {TRUCK_CYCLE:.1f} s, faza {TRUCK_PHASE:.4f}"
          f"{' (FIX, fara camion)' if MEDIAN_FIX else ''}{' SABOTAJ: AI orb' if not MEDIAN_AI else ''}")
    print(f"zidul lumii: centroid ({_cx:.0f}, {_cy:.0f}), cea mai departata margine {_ext:.0f} m -> "
          f"world_half_extent_m {WORLD_HALF:.0f} (implicit 420); racordul rapei {TOTAL * 0.02:.0f} m")

# =============================================================================================
# PASUL 6 (brief §7 pasul 6, 15 nov 2026): serpentinele (caramida + hortensii pe blocul solid),
# PONTONUL de pe cheiul de nord (scandura pe carosabil, cornisa spre golf, stalpi de amarare cu
# goluri) si MASINILE PARCATE (BumpProp, pe blocurile lantului si pe strada tramvaiului 1).
#   SF_PAS6=0       scena pasului 2b (A/B), fara nimic din pasul 6
#   SF_PONTON=0     fara ponton;  SF_PARCATE=0  fara masini parcate;  SF_HORTENSII=0  fara flori
#   SF_PARK_MASS    masa unei masini parcate (kg)
#   SF_BOLLARD_STEP pasul stalpilor de amarare (m; 0 = fara stalpi)
# =============================================================================================
P6 = os.environ.get("SF_PAS6", "1") == "1"
P6_PONTON = P6 and os.environ.get("SF_PONTON", "1") == "1"
P6_PARKED = P6 and os.environ.get("SF_PARCATE", "1") == "1"
P6_HORT = P6 and os.environ.get("SF_HORTENSII", "1") == "1"
PARK_MASS = float(os.environ.get("SF_PARK_MASS", "70"))
BOLLARD_STEP = float(os.environ.get("SF_BOLLARD_STEP", "6"))
P6_EXT, P6_SUB, P6_NODES, P6_PROPS = [], [], [], []
P6_BRANCH = []          # proprietati in plus pe nodul Serpentine


def _seg_dist(px, py, a, b):
    sx, sy = b[0] - a[0], b[1] - a[1]
    L2 = sx * sx + sy * sy
    t = max(0.0, min(1.0, ((px - a[0]) * sx + (py - a[1]) * sy) / max(L2, 1e-9)))
    return math.hypot(a[0] + sx * t - px, a[1] + sy * t - py), t


def road_at(px, py):
    """(distanta la axa buclei, cota interpolata a buclei in punctul cel mai apropiat)."""
    best = (1e18, 0.0)
    for i in range(N):
        a, b = PTS[i], PTS[(i + 1) % N]
        d, t = _seg_dist(px, py, a, b)
        if d < best[0]:
            best = (d, ELEV[i] + (ELEV[(i + 1) % N] - ELEV[i]) * t)
    return best


def branch_dist(gx, gz):
    return min(math.hypot(g[0] - gx, g[2] - gz) for g in DENSE_G)


if P6:
    # --- SERPENTINELE: caramida pe carosabilul ramurii (clasa `sf_brick`: dala roof_tiles + tenta
    # caramizie, din tema `sanfrancisco`: branch_texture / branch_tint), marginea dreapta, nu
    # zdrentuita ca drumul de tara. Coliziunea nu se schimba (aceeasi reteta `gravel`).
    P6_BRANCH.append("edge_noise = 0.0")
if P6_HORT:
    # --- HORTENSIILE: doar VIZUAL, pe fata de sus a blocului solid din fiecare ac (sonda 1b:
    # straturile moi se taiau in linie dreapta). Un MultiMesh (o singura trecere de desen), sfere
    # low-poly (8 x 4 segmente) cu culoarea pe instanta: roz si albastru, un singur material.
    hort = []
    rng_h = 0
    for outline_g, y0_, y1_ in prisms_bed:
        xs_ = [p[0] for p in outline_g]
        zs_ = [p[2] for p in outline_g]
        gx0, gx1, gz0, gz1 = min(xs_), max(xs_), min(zs_), max(zs_)
        k_ = 0
        gx = gx0 + 0.7
        while gx < gx1:
            gz = gz0 + 0.7 + (0.6 if k_ % 2 else 0.0)
            while gz < gz1:
                # in contur, la >= 0,6 m de margine (cele 8 directii)
                ok = _inside_convex(gx, gz, outline_g) and all(
                    _inside_convex(gx + 0.6 * math.cos(a_), gz + 0.6 * math.sin(a_), outline_g)
                    for a_ in [k__ * math.pi / 4 for k__ in range(8)])
                if ok:
                    rng_h = (rng_h * 1103515245 + 12345) & 0x7FFFFFFF
                    r_ = 0.5 + 0.3 * ((rng_h >> 8) % 100) / 100.0
                    pink = math.sin(gx * 0.35) + math.cos(gz * 0.41) > 0.0
                    # tufa nu sta pe grila: +-0,35 m, si culoarea variaza putin (pata, nu pixel)
                    jx = (((rng_h >> 3) % 71) / 71.0 - 0.5) * 0.7
                    jz = (((rng_h >> 11) % 67) / 67.0 - 0.5) * 0.7
                    k_c = 0.85 + 0.15 * ((rng_h >> 17) % 10) / 10.0
                    col = (0.86 * k_c, 0.36 * k_c, 0.58 * k_c) if pink else (0.36 * k_c, 0.46 * k_c, 0.86 * k_c)
                    hort.append((gx + jx, y1_ + r_ * 0.45, gz + jz, r_, col))
                gz += 1.3
            gx += 1.15
            k_ += 1
    buf = []
    for gx, gy, gz, r_, col in hort:
        buf += [r_, 0.0, 0.0, gx, 0.0, r_ * 0.75, 0.0, gy, 0.0, 0.0, r_, gz, col[0], col[1], col[2], 1.0]
    P6_SUB.append('[sub_resource type="SphereMesh" id="Mesh_hortensie"]\nradius = 1.0\nheight = 2.0\n'
                  'radial_segments = 8\nrings = 4\n')
    P6_SUB.append('[sub_resource type="StandardMaterial3D" id="Mat_hortensie"]\nvertex_color_use_as_albedo = true\n'
                  'roughness = 0.95\n')
    P6_SUB.append('[sub_resource type="MultiMesh" id="MM_hortensii"]\ntransform_format = 1\nuse_colors = true\n'
                  'instance_count = %d\nmesh = SubResource("Mesh_hortensie")\nbuffer = PackedFloat32Array(%s)\n'
                  % (len(hort), ", ".join(("%.3f" % v).rstrip("0").rstrip(".") for v in buf)))
    P6_NODES.append('[node name="Hortensii" type="MultiMeshInstance3D" parent="SerpentineGri"]\n'
                    'multimesh = SubResource("MM_hortensii")\nmaterial_override = SubResource("Mat_hortensie")\n')
    print(f"hortensii: {len(hort)} tufe pe {len(prisms_bed)} straturi solide (vizual, fara coliziune)")
    # PETALELE (decizia dezvoltatorului, 15 nov 2026): lovitura in blocul solid (`SerpStraturi`)
    # arunca petale roz / albastre din stratul de deasupra, prin rafalele de frunze ale PropDebris.
    # Nicio coliziune noua; un nod cu script care asculta `Car.impact`. Centrul fetei de sus a fiecarui
    # bloc = media conturului, la cota lui de sus.
    tops = []
    for outline_g, y0_, y1_ in prisms_bed:
        tops.append(((sum(p[0] for p in outline_g) / len(outline_g)), y1_,
                     (sum(p[2] for p in outline_g) / len(outline_g))))
    P6_EXT.append('[ext_resource type="Script" path="res://scenes/props/sf_hydrangea_petals.gd" id="8_petals"]\n')
    P6_NODES.append('[node name="HortensiiPetale" type="Node3D" parent="SerpentineGri"]\n'
                    'script = ExtResource("8_petals")\nbed_tops = PackedVector3Array(%s)\n'
                    % ", ".join("%.3f, %.3f, %.3f" % t for t in tops))

# --- PONTONUL (F): cheiul de nord, spre E, de la PONT_X0 pana la inceputul coltului de NE.
PONT_X0 = float(os.environ.get("SF_PONT_X0", "40"))
PONT_X1 = float(os.environ.get("SF_PONT_X1", str(MK["NE"][2])))
PONT_INFO = None
if P6_PONTON:
    assert PONT_X0 > M_X + 12.0 and PONT_X1 <= MK["NE"][2] + 1e-6, (PONT_X0, PONT_X1, M_X)
    s_p0 = s_M + (PONT_X0 - M_X)
    s_p1 = s_M + (PONT_X1 - M_X)
    fi0, fl0 = F_xy(PONT_X0, QUAY_Y)
    fi1, fl1 = F_xy(PONT_X1, QUAY_Y)
    # scandura: tot pontonul, plus 6 m in coltul de NE (pontonul se termina pe uscat, nu in apa)
    fiw1 = F_s(s_p1 + 6.0)[0]
    # CORNISA spre golf: rapa pe latura NORDULUI (stanga sensului spre E = -1 in `_side_at`),
    # fundul la -8 (sub apa, ca rapele podului), lata cat sa se verse in golf.
    ravine_idx = len(DECK_RAVINES) if B200 else 0
    PONT_INFO = dict(fi0=fi0, fi1=fi1, fl0=fl0, fl1=fl1, fiw1=fiw1, ravine=ravine_idx)
    # stalpii de amarare: pe muchia dinspre apa, cu goluri intre ei (golurile sunt singurele locuri
    # unde cazi). Cutii statice gri, 0,5 x 0,8 x 0,5 m, centrul la 0,3 m dincolo de asfalt.
    edge_y = QUAY_Y + HW_QUAY + 0.3
    P6_NODES.append('[node name="Ponton" type="Node3D" parent="."]\n')
    if BOLLARD_STEP > 0.0:
        P6_SUB.append('[sub_resource type="BoxShape3D" id="Box_stalp"]\nsize = Vector3(0.5, 0.8, 0.5)\n')
        P6_SUB.append('[sub_resource type="BoxMesh" id="Mesh_stalp"]\nsize = Vector3(0.5, 0.8, 0.5)\n'
                      'material = SubResource("Mat_gri")\n')
        # Contact MOALE (meta `soft_hit_crush`, ca atenuatorul podului): stalpul opreste si striveste,
        # dar nu arunca soferul. Pasul 6, lotul A: 2 ejectari „perete” (dv 47-48) pe primul stalp, la
        # x ~ 41, unde fluxurile de la reintalnire (ocol + scurtatura) intra pe ponton.
        P6_NODES.append('[node name="Stalpi" type="StaticBody3D" parent="Ponton"]\n'
                        'metadata/soft_hit_crush = 0.5\n')
        nb = 0
        # Primii BOLLARD_FROM m ai pontonului fara stalpi: acolo se varsa fluxurile de la reintalnire
        # (ocol + scurtatura) si masinile impinse spre nord loveau primul stalp (x 43) — 2 ejectari pe
        # lot, chiar cu contactul moale (masina atinge in acelasi tick si alt corp static, deci nu e
        # „doar” stalpul). Fara stalp, greseala de acolo e o cadere, ca pe restul pontonului.
        x_ = PONT_X0 + float(os.environ.get("SF_BOLLARD_FROM", "12")) + BOLLARD_STEP * 0.5
        while x_ < PONT_X1 - 2.0:
            y_ = Y_LOW + 0.4
            for nm_, typ_, res_ in (("S%d" % nb, "CollisionShape3D", 'shape = SubResource("Box_stalp")'),
                                    ("S%dM" % nb, "MeshInstance3D", 'mesh = SubResource("Mesh_stalp")')):
                P6_NODES.append('[node name="%s" type="%s" parent="Ponton/Stalpi"]\n'
                                'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)\n%s\n'
                                % (nm_, typ_, x_, y_, -edge_y, res_))
            nb += 1
            x_ += BOLLARD_STEP
        print(f"ponton: {nb} stalpi de amarare la {BOLLARD_STEP:.1f} m (goluri de {BOLLARD_STEP - 0.5:.1f} m)")
    P6_PROPS.append("metadata/sf_ponton = [%s, %s]" % (g3(godot((PONT_X0, QUAY_Y), Y_LOW)),
                                                      g3(godot((PONT_X1, QUAY_Y), Y_LOW))))
    P6_PROPS.append("custom_wood_deck_ranges = Array[Vector2]([Vector2(%.4f, %.4f)])" % (fi0, fiw1))
    # AI onest: muchia fara parapet e prapastie si pentru el (fractii pe LUNGIME, stanga = -1,
    # tine axa la 2,5 m de muchie) — vede ce vede jucatorul, nimic despre cine il impinge.
    P6_PROPS.append("ai_drop_edges = Array[Vector4]([Vector4(%.4f, %.4f, -1, %.1f)])"
                    % (fl0, fl1, float(os.environ.get("SF_DROP_MARGIN", "2.5"))))
    print(f"ponton: x {PONT_X0:.0f}..{PONT_X1:.0f} ({PONT_X1 - PONT_X0:.0f} m) la +{Y_LOW:.0f}, idx {fi0:.4f}..{fi1:.4f}, "
          f"lungime {fl0:.4f}..{fl1:.4f}; scandura pana la {fiw1:.4f}; rapa-cornisa #{ravine_idx}, fundul la -8")

# --- MASINILE PARCATE (D, B): perpendicular pe trotuar, pe blocurile lantului (dupa zona de
# aterizare: >= 45 m de muchie, pe toata latimea) si pe strada tramvaiului 1. Niciuna pe carosabil:
# capatul dinspre drum la PARK_GAP m dincolo de asfalt.
PARK_GAP = 0.4
PARK_LEN, PARK_W = 3.7, 1.9
PARK_LAT = HW + PARK_GAP + PARK_LEN / 2.0
PARK_SLOTS = [46.6, 49.5, 56.0, 62.5]           # metri dupa muchie (zona de aterizare: < 45)
PARK_SLOTS_LAST = [46.6, 49.5, 56.0]             # dupa muchia 4: terasa, pana inainte de furca
PARK_COLORS = [11, 19, 8]                        # PAINTED_METAL, CORAL_SAND, CONCRETE (stinse)
parked = []                                      # (x, y harta, latura, varianta, slot, eticheta)
if P6_PARKED:
    kk = 0
    for b, L in enumerate(LIPS):
        lx, ly = PTS[L]
        for u in (PARK_SLOTS if b < len(LIPS) - 1 else PARK_SLOTS_LAST):
            assert u - PARK_W / 2.0 >= 45.0
            for side in (-1.0, 1.0):
                parked.append((lx + side * PARK_LAT, ly + u, side, kk % 3, PARK_COLORS[(kk * 7 + b) % 3],
                               "lant%d" % (b + 1)))
                kk += 1
    # strada tramvaiului 1 (spre S, x = X_T): doua grupuri pe fiecare parte, departe de intrarea
    # tramvaiului (strada laterala din dreapta, la 20 m dupa primul viraj) si de colturi
    for y0_ in (120.0, 30.0):
        for j in range(3):
            for side in (-1.0, 1.0):
                parked.append((X_T + side * PARK_LAT, y0_ - j * 2.9 - (0.0 if side < 0 else 1.4), side,
                               kk % 3, PARK_COLORS[(kk * 5) % 3], "urcare"))
                kk += 1
    P6_EXT.append('[ext_resource type="Script" path="res://scenes/props/sf_parked_car.gd" id="7_parked"]\n')
    P6_NODES.append('[node name="MasiniParcate" type="Node3D" parent="."]\n')
    worst = 1e9
    for k, (mx, my, side, kind, slot, tag) in enumerate(parked):
        d_, y_ = road_at(mx, my)
        # niciuna pe carosabil: fiecare colt al caroseriei (lunga pe X: perpendiculara pe strazile
        # N-S) la >= HW + 0,3 m de axa oricarui tronson al buclei si dincolo de scurtatura
        for cx_ in (-PARK_LEN / 2.0, PARK_LEN / 2.0):
            for cz_ in (-PARK_W / 2.0, PARK_W / 2.0):
                px_, py_ = mx + cx_, my + cz_
                dd = road_at(px_, py_)[0]
                worst = min(worst, dd)
                if dd < HW + 0.3 or branch_dist(px_, -py_) < SERP_BW + 0.3:
                    raise SystemExit(f"masina parcata {k} ({tag}) pe carosabil: colt la {dd:.2f} m de axa")
        # botul spre case sau spre strada, alternativ: yaw +-90 de grade (Basis pe RANDURI)
        s_ = 1.0 if (k // 2) % 2 == 0 else -1.0
        P6_NODES.append('[node name="P%02d" type="Node3D" parent="MasiniParcate"]\n'
                        'transform = Transform3D(0, 0, %.0f, 0, 1, 0, %.0f, 0, 0, %.3f, %.3f, %.3f)\n'
                        'script = ExtResource("7_parked")\nbody_kind = %d\ncolor_slot = %d\nmass_kg = %.1f\n'
                        'metadata/sf_tag = "%s"\nmetadata/sf_axis_x = %.2f\n'
                        % (k, s_, -s_, mx, y_ + 0.05, -my, kind, slot, PARK_MASS, tag, mx - side * PARK_LAT))
    print(f"masini parcate: {len(parked)} ({sum(1 for p in parked if p[5].startswith('lant'))} pe lant, "
          f"{sum(1 for p in parked if p[5] == 'urcare')} pe strada tramvaiului), masa {PARK_MASS:.0f} kg; "
          f"cel mai apropiat colt la {worst:.2f} m de axa (carosabilul: {HW} m)")

if PONT_INFO is not None:
    # rapa pontonului se adauga la rapele podului (aceeasi lista, indicele `ravine`). Adancimea 200
    # (cu podeaua la -8): rapa se stinge pe RAVINE_FADE_FRAC (0,02 din tur, ~51 m) de la fiecare
    # capat, iar tinta e drum - adancime x stingere; cu 30 m, pe pontonul de 80 m cornisa ajungea
    # sub apa doar pe mijloc. Cu 200, la 3 m de capete e deja pe podea (ProbeSfPonton). Fractiile
    # rapei sunt pe LUNGIME (`TrackSideSampler`: _dists / _total_len), nu pe indice ca muchiile.
    _ri = PONT_INFO["ravine"]
    _new = []
    _found = False
    for line_ in POD_PROPS:
        if line_.startswith("custom_ravines = "):
            line_ = line_[:-2] + ", Vector4(%.4f, %.4f, 200.0, -1)])" % (PONT_INFO["fl0"], PONT_INFO["fl1"])
            _found = True
        elif line_.startswith("custom_ravine_floors = "):
            line_ = line_[:-2] + ", Vector2(%d, -8)])" % _ri
        _new.append(line_)
    assert _found
    POD_PROPS = _new + ["custom_cornice_ravines = Array[int]([%d])" % _ri,
                        "custom_ravine_widths = Array[Vector2]([Vector2(%d, 60)])" % _ri]

# =============================================================================================
# PASUL 8 (brief §7 pasul 8, 16 nov 2026): RANDURILE DIN FATA ale kitului casei de rand
# (`assets/models/sanfrancisco/buildings/sf_row_*.glb`, kit §3.1 / §11), pe strazile pe care
# brief-ul pune case: B (strada tramvaiului 1, ambele laturi), D (lantul, in trepte, ambele
# laturi), E (ocolul: latura de N a strazii spre V, ambele laturi ale strazii spre N), G (strada de
# intors, latura de V). Fara: latura de N a bratului coamei (casele pictate, alt kit), elanul,
# terasa (palmieri), cheiul, pontonul, podul si capetele lui, interiorul serpentinelor.
#   - FATADA paralela cu axa strazii, la CASE_SETBACK m de ea (§2.0: 10,5). Pe strada tramvaiului 1
#     masinile parcate perpendicular (pasul 6) au coltul departat la HW + PARK_GAP + PARK_LEN =
#     11,1 m de axa, deci acolo fatada sta la 11,75 (0,65 m de ele), pe ambele laturi. Pe lant
#     randurile se opresc la 45,0 m dupa muchie, inaintea primei masini parcate (46,6 - 0,95 =
#     45,65 m): 0,65 m in lungul strazii, fatada ramane la 10,5;
#   - PODEAUA (Y = 0 a casei) pe TEREN: Track25 n-are trotuar, deci podeaua = cota cea mai inalta a
#     terenului pe linia fatadei (capatul de SUS pe strada in panta), din harta coapta
#     `tools/data/sf_case_ground.tsv` (`ProbeSfCase --dump-ground`, raze pe `TerrainBody`). Fusta
#     (-2,4) acopera caderea pe 7 m (garda: generatorul si ProbeSfCase);
#   - AMESTECUL: `KIT_SEQ` din tools/sf_loc_decor.gd (familia se schimba la fiecare vecin), cinci
#     pasteluri prin metadata `wall_class` (vecinii difera mereu), mana cealalta prin fisierul `_m`
#     (niciodata scale.x = -1), garajul spre capatul de VALE;
#   - COLTURILE (`sf_row_corner_turret`, 9 m) doar la capatul de rand dinspre o intersectie reala,
#     cu turnuletul spre ea: pe lant capetele de VALE ale blocurilor (spre intersectia plata) pe
#     ambele laturi si capetele de DEAL (spre intersectia de pe muchie) doar pe latura de E (umbra
#     cade spre NE, departe de carosabil), plus capatul de N al randului de V de pe strada
#     tramvaiului 1 (strada laterala a tramvaiului). Turnuletul costa soare pe lant (pasul 7b:
#     85,4 -> 81,4 %), masurat aici cu `ProbeSfLight --real`;
#   - COLIZIUNEA: o cutie pe amprenta (latimea x 12 m, de la -2,4 la +9,6), statica, FARA
#     bovindou, sub `CaseCorpuri`; GLB-urile au `coliziune = "none"` (hull-ul implicit ar fi pus
#     un zid invizibil la 0,9 m in fata garajului) si `contact = "none"` (discurile de contact ale
#     caselor lipite s-ar suprapune in placa neagra, ca la zidurile din Machu Picchu).
#   SF_CASE=0        scena de dinainte, octet cu octet
#   SF_CASE_COLT=0   fara colturi;  =vale  doar capetele de vale;  =est  doar latura de E a lantului;
#                    =mixt  E la ambele capete, V doar la vale (87,0 % soare pe lant; implicitul,
#                    cu ambele capete pe ambele laturi, da 83,6 %)
# =============================================================================================
P8_CASE = os.environ.get("SF_CASE", "1") == "1"
P8_COLT = os.environ.get("SF_CASE_COLT", "1")
CASE_DIR = "buildings"
KIT_SEQ = ["sf_row_a_canted", "sf_row_b_square", "sf_row_c_canted", "sf_row_a_square", "sf_row_b_canted",
           "sf_row_c_square"]
KIT_CORNER = "sf_row_corner_turret"
PASTELS = ["sf_clapboard", "sf_clapboard_pink", "sf_clapboard_blue", "sf_clapboard_mint", "sf_clapboard_butter"]
CASE_W, CASE_W_CORNER, CASE_D, CASE_SKIRT, CASE_EAVE = 7.0, 9.0, 12.0, 2.4, 9.6
CASE_SETBACK = 10.5
CASE_SETBACK_PARKED = HW + PARK_GAP + PARK_LEN + 0.65           # 11,75: strada tramvaiului 1
CASE_GROUND_PATH = os.path.join(HERE, "data", "sf_case_ground.tsv")
CASE_ROAD_MIN = HW + 2.5      # amprenta fata de axa buclei (poligonul de control; sonda: HW + 1,5 pe curba coapta)
CASE_BRANCH_MIN = SERP_BW + 2.5
CASE_TRAM_MIN = 1.25 + 2.0
CASE_CAR_MIN = 0.6
P8_NODES, P8_SUB = [], []
CASE_STATS = {}


def _case_ground_grid():
    g = {}
    if os.path.exists(CASE_GROUND_PATH):
        for line in open(CASE_GROUND_PATH, encoding="utf-8"):
            tk = line.split()
            if len(tk) == 3:
                g[(int(round(float(tk[0]))), int(round(float(tk[1]))))] = float(tk[2])
    return g


def _case_ground(G_, gx, gz):
    """Cota terenului (bilinear pe grila de 1 m); None in afara hartii."""
    x0, z0 = math.floor(gx), math.floor(gz)
    fx, fz = gx - x0, gz - z0
    try:
        a, b = G_[(x0, z0)], G_[(x0 + 1, z0)]
        c, d = G_[(x0, z0 + 1)], G_[(x0 + 1, z0 + 1)]
    except KeyError:
        return None
    return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz


def _pt_seg(p, a, b):
    sx, sy = b[0] - a[0], b[1] - a[1]
    L2 = sx * sx + sy * sy
    t = max(0.0, min(1.0, ((p[0] - a[0]) * sx + (p[1] - a[1]) * sy) / max(L2, 1e-9)))
    return math.hypot(a[0] + sx * t - p[0], a[1] + sy * t - p[1])


def _edge_pts(poly, step=0.5):
    out = []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        n = max(1, int(math.ceil(math.dist(a, b) / step)))
        out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(n)]
    return out


def _in_convex(p, poly, tol=0.0):
    sgn = 0
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        c = ((b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])) / max(math.dist(a, b), 1e-9)
        if abs(c) < tol:
            return False
        s_ = 1 if c > 0 else -1
        if sgn == 0:
            sgn = s_
        elif s_ != sgn:
            return False
    return True


def _poly_poly(pa, pb):
    if any(_in_convex(p, pb) for p in pa) or any(_in_convex(p, pa) for p in pb):
        return 0.0
    return min(min(_pt_seg(p, pb[i], pb[(i + 1) % len(pb)]) for i in range(len(pb))) for p in _edge_pts(pa))


def _poly_line(poly, line):
    pts = _edge_pts(poly)
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)
    best = 1e18
    for a, b in zip(line, line[1:]):
        if _pt_seg((cx, cy), a, b) > 60.0:
            continue
        if _in_convex(a, poly):
            return 0.0
        for p in pts:
            best = min(best, _pt_seg(p, a, b))
    return best


# RANDURILE: (zona, nume, punctul de start al strazii (harta), directia ei (harta, unitara), latura
# (+1 = la dreapta directiei, -1 = la stanga), retragerea fatadei, t0, numarul de case de rand,
# coltul ("t0" / "t1" / None)). Casele se aseaza de la t0 in sensul directiei; coltul ia capatul
# cerut. Pe lant blocul b incepe la muchia lui (y = 72 b): randul se termina la 45,0 m dupa muchie
# (inaintea masinilor parcate), adica pe panta de 48 m dintre doua intersectii plate.
CASE_ROWS = []
if B200 and P8_CASE:
    # latura de E: colt la ambele capete (umbra turnuletului cade spre NE, departe de carosabil);
    # latura de V: doar la capatul de vale. Randul de E incepe cu 1 m INAINTEA muchiei (pe platul
    # intersectiei; ultima masina parcata a blocului de dinainte e la 8,55 m), ca 9 + 4 x 7 + 9 m sa
    # se opreasca tot la 45,0 m dupa muchie.
    # IMPLICIT (coordonatorul, 16 nov 2026): colt la AMBELE capete pe AMBELE laturi ale lantului.
    # Masurat cu `ProbeSfLight --real`: 83,6 % soare pe lant (contract >= 80, tinta >= 82), fata de
    # 87,0 % cu regula „E la ambele capete, V doar la vale" (`SF_CASE_COLT=mixt`). Cele 3,4 puncte
    # cumpara capatul de DEAL al randurilor de V: fara colt, acolo ramanea un perete orb de
    # 12 x 10 m chiar pe muchie, in cadrul fiecarei sarituri (p8_case_D_muchia1_gamecam.png).
    # Un colt FARA turnulet (piesa de kit care nu exista inca) ar da inapoi marja.
    _chain_colt = {"1": ("both", "both"), "mixt": ("both", "t1"), "vale": ("t1", "t1"),
                   "est": ("both", None), "0": (None, None)}.get(P8_COLT, ("both", "both"))
    for b_ in range(BLOCKS):
        y_l = PTS[LIPS[b_]][1]
        for side_, nm_, colt_ in ((1.0, "E", _chain_colt[0]), (-1.0, "V", _chain_colt[1])):
            # strada spre N (0, 1): dreapta = E
            t0_, n_ = (-1.0, 4) if colt_ == "both" else (1.0, 5 if colt_ else 6)
            if colt_ is None:
                n_, t0_ = 6, 3.0
            CASE_ROWS.append(("D", "D%d%s" % (b_ + 1, nm_), (0.0, y_l), (0.0, 1.0), side_, CASE_SETBACK,
                              t0_, n_, colt_))
    # strada tramvaiului 1: de la baza ei (B0) spre S (urca). Strazi transversale de 14 m la y ~ 88
    # si ~ -5 (benzile de soare ale brief-ului §2 B), aliniate pe ambele laturi; pe latura de V
    # randul de N incepe dupa strada laterala a tramvaiului (care intra la y ~ 164).
    _b0 = (MK["B0"][2], MK["B0"][3])
    _bc = P8_COLT != "0"
    for nm_, t0_, n_ in (("B1", 18.4, 9), ("B2", 95.4, 11), ("B3", 186.4, 12)):
        CASE_ROWS.append(("B", nm_ + "E", _b0, (0.0, -1.0), -1.0, CASE_SETBACK_PARKED, t0_, n_, None))
    for nm_, t0_, n_, colt_ in (("B1", 30.4, 6, "t0" if _bc else None), ("B2", 95.4, 11, None),
                                ("B3", 186.4, 12, None)):
        if colt_ is None and nm_ == "B1":
            t0_, n_ = 32.4, 7
        CASE_ROWS.append(("B", nm_ + "V", _b0, (0.0, -1.0), 1.0, CASE_SETBACK_PARKED, t0_, n_, colt_))
    # strada de intors (spre S, urca): latura de V, doua randuri cu o strada transversala intre ele
    _g0 = (MK["G0"][2], MK["G0"][3])
    CASE_ROWS.append(("G", "G1V", _g0, (0.0, -1.0), 1.0, CASE_SETBACK, 14.0, 9, None))
    CASE_ROWS.append(("G", "G2V", _g0, (0.0, -1.0), 1.0, CASE_SETBACK, 91.0, 7, None))
    # ocolul: strada spre V (y = 315, coboara spre V), latura de N (fatadele spre S, la soare);
    # strada spre N (x = -124,7, coboara spre N), ambele laturi
    _oa = (-RB, F_Y + RB)
    _ob = (-RB - BYP_A - RB, F_Y + 2.0 * RB)
    CASE_ROWS.append(("E", "EAN", _oa, (-1.0, 0.0), 1.0, CASE_SETBACK, 15.0, 9, None))
    CASE_ROWS.append(("E", "EBE", _ob, (0.0, 1.0), 1.0, CASE_SETBACK, 16.0, 11, None))
    CASE_ROWS.append(("E", "EBV", _ob, (0.0, 1.0), -1.0, CASE_SETBACK, 20.0, 10, None))

CASE_HOUSES = []      # dict-uri: nume, zona, fisier, pastel, w, origine (godot), X, Z (godot), podea, ...
if CASE_ROWS:
    _G = _case_ground_grid()
    if not _G:
        raise SystemExit("casele: lipseste harta terenului %s — ruleaza ProbeSfCase --dump-ground"
                         % os.path.relpath(CASE_GROUND_PATH, ROOT))
    for idx_, (zone, rname, a_, u_, side_, setb, t0_, n_reg, colt_) in enumerate(CASE_ROWS):
        nrm = (u_[1] * side_, -u_[0] * side_)            # spre casa (dreapta directiei = (uy, -ux))
        slots = [CASE_W] * n_reg
        if colt_ in ("t0", "both"):
            slots = [CASE_W_CORNER] + slots
        if colt_ in ("t1", "both"):
            slots = slots + [CASE_W_CORNER]
        t = t0_
        t_end = t0_ + sum(slots)

        def _fl(tt, off, _a=a_, _u=u_, _n=nrm):
            return (_a[0] + _u[0] * tt + _n[0] * off, _a[1] + _u[1] * tt + _n[1] * off)

        def _gnd(tt, off):
            p = _fl(tt, off)
            v = _case_ground(_G, p[0], -p[1])
            if v is None:
                raise SystemExit("casele: %s iese din harta terenului la harta (%.1f, %.1f)" % (rname, p[0], p[1]))
            return v
        # capatul de vale al randului (cota terenului pe linia fatadei la cele doua capete)
        down = 1.0 if _gnd(t_end, setb) < _gnd(t0_, setb) else -1.0
        for i_, w_ in enumerate(slots):
            corner = w_ > CASE_W
            tc = t + w_ / 2.0
            # podeaua: cota cea mai inalta a terenului pe linia fatadei (+ latura libera a coltului)
            samples = []
            k_ = 0.0
            while k_ <= w_ + 1e-6:
                samples.append(_gnd(t + k_, setb))
                k_ += 0.5
            side_line = []
            # coltul de la capatul t0 e primul slot; cel de la t1, ultimul
            c_end = "t0" if (corner and i_ == 0 and colt_ in ("t0", "both")) else "t1"
            if corner:
                te = t if c_end == "t0" else t + w_
                d_ = 0.0
                while d_ <= CASE_D + 1e-6:
                    side_line.append(_gnd(te, setb + d_))
                    d_ += 0.5
            floor_ = max(samples + side_line)
            low = min(samples + side_line)
            if floor_ - low > CASE_SKIRT - 0.05:
                raise SystemExit("casele: %s/%d cade %.2f m pe fatada (fusta %.1f)" % (rname, i_, floor_ - low, CASE_SKIRT))
            ctr = _fl(tc, setb + CASE_D / 2.0)
            Z = (nrm[0], 0.0, -nrm[1])                     # +Z_glb = spatele casei
            X = (Z[2], 0.0, -Z[0])                         # UP x Z
            # +X_glb pe harta: (X[0], -X[2])
            Xm = (X[0], -X[2])
            if corner:
                want = -1.0 if c_end == "t0" else 1.0      # turnuletul spre capatul randului
                tdir = (u_[0] * want, u_[1] * want)
                use_m = (-Xm[0] * tdir[0] - Xm[1] * tdir[1]) < 0.0     # turnuletul de baza e pe -X
                stem = KIT_CORNER
            else:
                ddir = (u_[0] * down, u_[1] * down)
                use_m = (Xm[0] * ddir[0] + Xm[1] * ddir[1]) < 0.0      # garajul de baza e pe +X
                stem = KIT_SEQ[(i_ + 2 * idx_ + (0 if side_ > 0 else 1)) % len(KIT_SEQ)]
            fname = stem + ("_m" if use_m else "")
            CASE_HOUSES.append(dict(
                name="%s_%02d" % (rname, i_), zone=zone, row=rname, file=fname, corner=corner, w=w_,
                pastel=(i_ * 2 + (0 if side_ > 0 else 3) + idx_) % len(PASTELS),
                o=(ctr[0], floor_, -ctr[1]), X=X, Z=Z, floor=floor_, drop=floor_ - low,
                fp=[_fl(t + du, setb + dd) for du, dd in ((0.0, 0.0), (w_, 0.0), (w_, CASE_D), (0.0, CASE_D))],
            ))
            t += w_
    # --- garzile de geometrie (pe harta): sosea, scurtatura, tramvaie, masini parcate, zidurile si
    # straturile serpentinelor, suprapuneri. Pica generatorul, ca la masinile parcate.
    _main_line = list(PTS) + [PTS[0]]
    _br_line = [(g[0], -g[2]) for g in DENSE_G]
    _cars = []
    for (mx, my, side, kind, slot, tag) in parked:
        _cars.append([(mx - PARK_LEN / 2.0, my - PARK_W / 2.0), (mx + PARK_LEN / 2.0, my - PARK_W / 2.0),
                      (mx + PARK_LEN / 2.0, my + PARK_W / 2.0), (mx - PARK_LEN / 2.0, my + PARK_W / 2.0)])
    _walls = [[(x_, -z_) for x_, z_ in box_corners(c, size, yaw)[0]] for c, size, yaw in boxes_wall]
    _beds = [[(p[0], -p[2]) for p in og] for og, _, _ in prisms_bed]
    worst = dict(road=1e9, branch=1e9, tram=1e9, car=1e9, serp=1e9)
    for hi_, h in enumerate(CASE_HOUSES):
        fp = h["fp"]
        for key, line, lim in (("road", _main_line, CASE_ROAD_MIN), ("branch", _br_line, CASE_BRANCH_MIN),
                               ("tram", TRAM1_MAP, CASE_TRAM_MIN), ("tram", TRAM2_MAP, CASE_TRAM_MIN)):
            d_ = _poly_line(fp, line)
            worst[key] = min(worst[key], d_)
            if d_ < lim:
                raise SystemExit("casele: %s la %.2f m de %s (prag %.2f)" % (h["name"], d_, key, lim))
        for cp in _cars:
            if math.dist(cp[0], fp[0]) > 40.0:
                continue
            d_ = _poly_poly(fp, cp)
            worst["car"] = min(worst["car"], d_)
            if d_ < CASE_CAR_MIN:
                raise SystemExit("casele: %s la %.2f m de o masina parcata" % (h["name"], d_))
        for wp in _walls + _beds:
            if math.dist(wp[0], fp[0]) > 60.0:
                continue
            d_ = _poly_poly(fp, wp)
            worst["serp"] = min(worst["serp"], d_)
            if d_ < 1.0:
                raise SystemExit("casele: %s la %.2f m de serpentine" % (h["name"], d_))
        for hj in range(hi_ + 1, len(CASE_HOUSES)):
            g_ = CASE_HOUSES[hj]["fp"]
            if math.dist(g_[0], fp[0]) > 30.0:
                continue
            if any(_in_convex(p, g_, 0.02) for p in fp) or any(_in_convex(p, fp, 0.02) for p in g_):
                raise SystemExit("casele: %s se suprapune cu %s" % (h["name"], CASE_HOUSES[hj]["name"]))
    # vecinii: alta familie, alt pastel
    for a_h, b_h in zip(CASE_HOUSES, CASE_HOUSES[1:]):
        if a_h["row"] != b_h["row"]:
            continue
        fam = lambda f: f.replace("_m", "").split("_")[2]    # noqa: E731  (a / b / c / corner)
        if fam(a_h["file"]) == fam(b_h["file"]) or a_h["pastel"] == b_h["pastel"]:
            raise SystemExit("casele: vecinii %s / %s au aceeasi familie sau acelasi pastel" % (a_h["name"], b_h["name"]))
    # --- nodurile: casele sub DecorManual/Case<zona>, cutiile sub CaseCorpuri (radacina)
    _zones_done = []
    for h in CASE_HOUSES:
        rid = _p7_glb("%s/%s.glb" % (CASE_DIR, h["file"]), "p8_" + h["file"])
        if rid is None:
            continue
        if h["zone"] not in _zones_done:
            P8_NODES.append('[node name="Case%s" type="Node3D" parent="DecorManual"]\n' % h["zone"])
            _zones_done.append(h["zone"])
        X, Z, o = h["X"], h["Z"], h["o"]
        P8_NODES.append('[node name="%s" parent="DecorManual/Case%s" instance=ExtResource("%s")]\n'
                        'transform = Transform3D(%.5f, 0, %.5f, 0, 1, 0, %.5f, 0, %.5f, %.3f, %.3f, %.3f)\n'
                        'metadata/coliziune = "none"\nmetadata/contact = "none"\nmetadata/wall_class = "%s"\n'
                        'metadata/sf_case = "%s"\nmetadata/sf_case_w = %.1f\n'
                        % (h["name"], h["zone"], rid, X[0], Z[0], X[2], Z[2], o[0], o[1], o[2],
                           PASTELS[h["pastel"]], h["zone"], h["w"]))
        h["placed"] = True
    _placed = [h for h in CASE_HOUSES if h.get("placed")]
    if _placed:
        P8_NODES.append('[node name="CaseCorpuri" type="StaticBody3D" parent="."]\n')
        for wk in sorted({h["w"] for h in _placed}):
            P8_SUB.append('[sub_resource type="BoxShape3D" id="Box_casa%d"]\nsize = Vector3(%.1f, %.1f, %.1f)\n'
                          % (int(wk), wk, CASE_SKIRT + CASE_EAVE, CASE_D))
        for h in _placed:
            X, Z, o = h["X"], h["Z"], h["o"]
            yc = o[1] - CASE_SKIRT + (CASE_SKIRT + CASE_EAVE) / 2.0
            P8_NODES.append('[node name="Corp_%s" type="CollisionShape3D" parent="CaseCorpuri"]\n'
                            'transform = Transform3D(%.5f, 0, %.5f, 0, 1, 0, %.5f, 0, %.5f, %.3f, %.3f, %.3f)\n'
                            'shape = SubResource("Box_casa%d")\n'
                            % (h["name"], X[0], Z[0], X[2], Z[2], o[0], yc, o[2], int(h["w"])))
        from collections import Counter
        print("casele de rand: %d (%s), colturi %d; fisiere %d; podeaua pe teren (fara trotuar), caderea maxima "
              "pe o fatada %.2f m (fusta %.1f)" % (
                  len(_placed), ", ".join("%s %d" % kv for kv in sorted(Counter(h["zone"] for h in _placed).items())),
                  sum(1 for h in _placed if h["corner"]), len({h["file"] for h in _placed}),
                  max(h["drop"] for h in _placed), CASE_SKIRT))
        print("casele: amprenta la >= %.2f m de axa buclei (poligon), %.2f de scurtatura, %.2f de tramvaie, "
              "%.2f de masinile parcate, %.2f de serpentine" % (worst["road"], worst["branch"], worst["tram"],
                                                                 worst["car"], worst["serp"]))
        for rn in dict.fromkeys(h["row"] for h in _placed):
            hs = [h for h in _placed if h["row"] == rn]
            print("  %-5s %2d case (%s), podeaua %.1f..%.1f, cadere max %.2f" % (
                rn, len(hs), " ".join(h["file"].replace("sf_row_", "") for h in hs),
                min(h["floor"] for h in hs), max(h["floor"] for h in hs), max(h["drop"] for h in hs)))
    P7_NODES += P8_NODES
    P6_SUB += P8_SUB

# =============================================================================================
# PASUL 8b (brief §7 pasul 8, 16 nov 2026): RANDURILE DIN SPATE. In spatele randului din fata si in
# blocurile dintre strazi, ca un singur `CityFill` (`CaseSpate`, o singura felie: 36 de buffere) cu
# instante explicite: generatorul stie strazile, deci randurile sunt PARALELE cu strada lor, spate
# in spate (0,1 m intre pereti), cu strazi transversale unde le are strada din fata.
#   - KITUL: doar casele de rand (fara colturi: turnuletul are 15 m si costa soare), amestecate cu
#     `KIT_SEQ` (familia se schimba la fiecare vecin), cele cinci pasteluri (vecinii difera mereu),
#     garajul spre VALE. Mana cealalta se scrie ca transformare OGLINDITA (determinant negativ);
#     `CityFill` o deseneaza cu fisierul `_m` si transformarea refacuta pozitiva (`mirror_models`).
#   - PODEAUA: cota cea mai inalta a terenului pe linia fatadei (ca randul din fata), din harta
#     `tools/data/sf_spate_ground.tsv` (2 m, `ProbeSfSpate --dump-ground`). Treptele de acoperis ies
#     singure: fiecare casa e la cota ei. Casa se respinge daca fusta (2,4 m) nu ajunge la teren pe
#     o latura VIZIBILA (fara alta casa lipita de ea) sau daca dealul o ingroapa peste 4 m.
#   - LIBER: parcul de pe coama (casele pictate si chiparosii vin acolo), terasa, blocul
#     serpentinelor, cheiul / pontonul / placa turnanta, podul cu capetele lui si virajul 1, intrarea
#     tramvaiului 1 (strada laterala de la y 164), strada laterala cu poarta de pe B (y ~40, H5).
#   - COLIZIUNEA: orice casa din spate cu amprenta la < 40 m de axa unei benzi (bucla, scurtatura)
#     primeste cutia ei sub `CaseSpateCorpuri` (ca `CaseCorpuri`); dincolo, niciuna (ca `CityFill`).
#   - UMBRA: arunca doar casele la <= 50 m de o banda (cascada telefonului are 55 m de la camera);
#     restul nu intra in bufferele de umbra.
#   SF_SPATE=0   scena de dinainte, octet cu octet
# =============================================================================================
P8B = os.environ.get("SF_SPATE", "1") == "1"
SPATE_GROUND_PATH = os.path.join(HERE, "data", "sf_spate_ground.tsv")
SPATE_GAP = 0.1               # intre doi pereti spate in spate
SPATE_STREET = 24.85          # intre fatadele dinspre strada din spate si perechea din mijloc (blocul D-B)
SPATE_ALLEY = 14.0            # strada din spate, in blocurile mai inguste
SPATE_BURY_MAX = 4.0
SPATE_BODY_M = 40.0
SPATE_SHADOW_M = 50.0
SPATE_ROAD_MIN = 20.0         # amprenta fata de axa oricarei benzi (randul din fata sta la 10,5)
SPATE_CELL = float(os.environ.get("SF_SPATE_CELL", "0"))   # 0 = o singura felie (36 de buffere); >0 = felii de atatia m (A/B)
SPATE_TRAM_MIN = 6.0
SPATE_HOUSES, SPATE_STATS = [], {}
# zonele LIBERE (dreptunghiuri pe harta: x0, y0, x1, y1)
SPATE_KEEP = [
    ("parcul coamei", (28.0, -140.0, 106.0, -12.0)),
    ("terasa", (-60.0, 262.0, 60.0, 306.0)),
    ("serpentinele", (-24.0, 290.0, 62.0, 475.0)),
    ("cheiul", (-200.0, 436.0, 200.0, 520.0)),
    ("placa turnanta", (-165.0, 425.0, -125.0, 470.0)),
    ("podul si virajul 1", (104.0, 166.0, 270.0, 280.0)),
    ("intrarea tramvaiului 1", (100.0, 155.0, 144.0, 176.0)),
    ("poarta de pe B (H5)", (150.0, 33.0, 264.0, 47.0)),
]


def _spate_grid():
    g = {}
    if os.path.exists(SPATE_GROUND_PATH):
        for line in open(SPATE_GROUND_PATH, encoding="utf-8"):
            tk = line.split()
            if len(tk) == 3:
                g[(int(tk[0]), int(tk[1]))] = float(tk[2])
    return g


def _spate_h(G_, mx, my):
    """Cota terenului in punctul de HARTA (mx, my), bilinear pe grila de 2 m; None in afara ei."""
    gx, gz = mx, -my
    x0, z0 = int(math.floor(gx / 2.0)) * 2, int(math.floor(gz / 2.0)) * 2
    fx, fz = (gx - x0) / 2.0, (gz - z0) / 2.0
    try:
        a, b = G_[(x0, z0)], G_[(x0 + 2, z0)]
        c, d = G_[(x0, z0 + 2)], G_[(x0 + 2, z0 + 2)]
    except KeyError:
        return None
    return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz


def _spate_segs(spans, w=CASE_W):
    """Sloturile de casa (centrele pe axa randului) din intervale (t0, t1): case lipite, centrate."""
    out = []
    for t0, t1 in spans:
        n = int(math.floor((t1 - t0 + 1e-6) / w))
        if n <= 0:
            continue
        s0 = (t0 + t1) / 2.0 - n * w / 2.0
        out.append([s0 + w * (k + 0.5) for k in range(n)])
    return out


if B200 and P8B and CASE_HOUSES:
    _GS = _spate_grid()
    if not _GS:
        raise SystemExit("randurile din spate: lipseste harta terenului %s — ruleaza ProbeSfSpate --dump-ground"
                         % os.path.relpath(SPATE_GROUND_PATH, ROOT))
    def _row_span(rn, axis):
        hs = [h for h in CASE_HOUSES if h["row"] == rn]
        k = 1 if axis == "y" else 0
        v = [p[k] for h in hs for p in h["fp"]]
        return (min(v), max(v))

    _chain = [_row_span("D%dE" % (b_ + 1), "y") for b_ in range(BLOCKS)]   # (y_l - 1, y_l + 45)
    _bv = [_row_span(r_, "y") for r_ in ("B3V", "B2V", "B1V")]
    _be = [_row_span(r_, "y") for r_ in ("B3E", "B2E", "B1E")]
    _gv = [_row_span(r_, "y") for r_ in ("G2V", "G1V")]
    _ean = [_row_span("EAN", "x")]
    _ebe = [_row_span("EBE", "y")]
    _ebv = [_row_span("EBV", "y")]
    _x_front_d = HW + 3.5 + CASE_D          # 22,5: spatele randului din fata de pe lant
    _x_bv = X_T - CASE_SETBACK_PARKED - CASE_D          # 120,25: spatele randului de V de pe B
    _x_be = X_T + CASE_SETBACK_PARKED + CASE_D          # 167,75
    _x_gv = X_G - CASE_SETBACK - CASE_D                 # 127,5
    _y_ean = F_Y + RB + CASE_SETBACK + CASE_D          # 337,5
    _x_ebe = _ob[0] + CASE_SETBACK + CASE_D             # -102,2
    _x_ebv = _ob[0] - CASE_SETBACK - CASE_D             # -147,2
    _hd = CASE_D / 2.0
    # COLOANELE: (zona, nume, axa randului, coordonata centrului peste axa, fata (+1 = spre + pe
    # cealalta axa), intervalele in lungul axei). Perechile spate in spate impart aceleasi intervale.
    _p1w = _x_front_d + SPATE_GAP + CASE_D + SPATE_STREET + _hd               # 65,45
    _bh = []
    _bh += [("D", "DE1", "y", _x_front_d + SPATE_GAP + _hd, 1.0, _chain),
            ("D", "DE2", "y", _p1w, -1.0, _chain),
            ("D", "DE3", "y", _p1w + CASE_D + SPATE_GAP, 1.0, _chain),
            ("B", "BV1", "y", _x_bv - SPATE_GAP - _hd, -1.0, _bv),
            ("D", "DV1", "y", -(_x_front_d + SPATE_GAP + _hd), -1.0, _chain),
            ("D", "DV2", "y", -_p1w, 1.0, _chain),
            ("D", "DV3", "y", -(_p1w + CASE_D + SPATE_GAP), -1.0, _chain)]
    _be_sp = []
    for a_, b_ in _be:
        _be_sp += [(a_, min(b_, 33.0)), (max(a_, 47.0), b_)] if a_ < 40.0 < b_ else [(a_, b_)]
    _be2 = _x_be + SPATE_GAP + CASE_D + SPATE_ALLEY + _hd
    _bh += [("B", "BE1", "y", _x_be + SPATE_GAP + _hd, 1.0, _be_sp),
            ("B", "BE2", "y", _be2, -1.0, _be_sp),
            ("B", "BE3", "y", _be2 + CASE_D + SPATE_GAP, 1.0, _be_sp)]
    _gv2 = _x_gv - SPATE_GAP - CASE_D - SPATE_ALLEY - _hd
    _bh += [("G", "GV1", "y", _x_gv - SPATE_GAP - _hd, -1.0, _gv),
            ("G", "GV2", "y", _gv2, 1.0, _gv),
            ("G", "GV3", "y", _gv2 - CASE_D - SPATE_GAP, -1.0, _gv)]
    # ocolul: in spatele randului de N al strazii spre V (fata spre N), in spatele celor doua laturi
    # ale strazii spre N, si doua perechi E-V in interiorul blocului (paralele cu strada spre V)
    _ei = (_x_ebe + SPATE_GAP + CASE_D + SPATE_ALLEY, -30.0)   # interiorul: strada in fata lui EBE1, pana la serpentine
    _ey2 = _y_ean + SPATE_GAP + CASE_D + SPATE_ALLEY + _hd
    _ey4 = _ey2 + CASE_D + SPATE_GAP + _hd + SPATE_ALLEY + _hd
    _bh += [("E", "EN1", "x", _y_ean + SPATE_GAP + _hd, 1.0, [(max(_ean[0][0], _ei[0]), _ean[0][1])]),
            ("E", "EBE1", "y", _x_ebe + SPATE_GAP + _hd, 1.0, _ebe),
            ("E", "EN2", "x", _ey2, -1.0, [_ei]),
            ("E", "EN3", "x", _ey2 + CASE_D + SPATE_GAP, 1.0, [_ei]),
            ("E", "EN4", "x", _ey4, -1.0, [_ei]),
            ("E", "EN5", "x", _ey4 + CASE_D + SPATE_GAP, 1.0, [_ei]),
            ("E", "EBV1", "y", _x_ebv - SPATE_GAP - _hd, -1.0, _ebv)]
    # liniile de distanta (harta)
    _ml = list(PTS) + [PTS[0]]
    _bl = [(g[0], -g[2]) for g in DENSE_G]

    def _in_keep(poly):
        # randurile sunt paralele cu axele hartii: amprenta (cu bovindoul) e chiar dreptunghiul ei
        ax0, ax1 = min(p[0] for p in poly), max(p[0] for p in poly)
        ay0, ay1 = min(p[1] for p in poly), max(p[1] for p in poly)
        for nm_, (x0_, y0_, x1_, y1_) in SPATE_KEEP:
            if ax0 < x1_ and ax1 > x0_ and ay0 < y1_ and ay1 > y0_:
                return nm_
        return None

    def _far_dist(poly, line):
        # distanta exacta si dincolo de 60 m (`_poly_line` sare segmentele departate): colturi si centru
        pts = list(poly) + [(sum(p[0] for p in poly) / len(poly), sum(p[1] for p in poly) / len(poly))]
        return min(_pt_seg(p, a, b) for p in pts for a, b in zip(line, line[1:]))

    def _in_lagoon(p):
        ins = False
        n_ = len(LAGOON)
        for i in range(n_):
            a, b = LAGOON[i], LAGOON[(i + 1) % n_]
            if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < a[0] + (p[1] - a[1]) * (b[0] - a[0]) / (b[1] - a[1]):
                ins = not ins
        return ins

    rej = {}
    _placed_fp = [h["fp"] for h in CASE_HOUSES]          # amprentele (fara bovindou) deja ocupate
    for ci_, (zone, cname, axis, cc, face, spans) in enumerate(_bh):
        if axis == "y":
            u_ = (0.0, 1.0)
            f_ = (face, 0.0)
        else:
            u_ = (1.0, 0.0)
            f_ = (0.0, face)

        def _P(t, d, _u=u_, _f=f_, _c=cc, _ax=axis):
            # punctul de pe harta: t in lungul randului, d spre fata casei de la centru
            base = (_c, t) if _ax == "y" else (t, _c)
            return (base[0] + _f[0] * d, base[1] + _f[1] * d)

        for si_, seg in enumerate(_spate_segs(spans)):
            # capatul de vale al segmentului, pe linia fatadelor
            ga = _spate_h(_GS, *_P(seg[0], _hd))
            gb = _spate_h(_GS, *_P(seg[-1], _hd))
            if ga is None or gb is None:
                rej["harta"] = rej.get("harta", 0) + len(seg)
                continue
            down = 1.0 if gb < ga else -1.0
            for i_, tc in enumerate(seg):
                ctr = _P(tc, 0.0)
                fp = [_P(tc + du, dd) for du, dd in ((-3.5, _hd), (3.5, _hd), (3.5, -_hd), (-3.5, -_hd))]
                fpb = [_P(tc + du, dd) for du, dd in ((-3.5, _hd + 0.9), (3.5, _hd + 0.9), (3.5, -_hd), (-3.5, -_hd))]
                why = _in_keep(fpb)
                if why:
                    rej[why] = rej.get(why, 0) + 1
                    continue
                if any(_in_lagoon(p) for p in fpb):
                    rej["apa"] = rej.get("apa", 0) + 1
                    continue
                d_road = min(_poly_line(fp, _ml), _poly_line(fp, _bl))
                if d_road > 1e17:
                    d_road = min(_far_dist(fp, _ml), _far_dist(fp, _bl[::4]))
                d_tram = min(_poly_line(fpb, TRAM1_MAP), _poly_line(fpb, TRAM2_MAP))
                if d_road < SPATE_ROAD_MIN or d_tram < SPATE_TRAM_MIN:
                    rej["drum"] = rej.get("drum", 0) + 1
                    continue
                if any(math.dist(q[0], fpb[0]) < 30.0 and (any(_in_convex(p, q, 0.02) for p in fpb)
                                                            or any(_in_convex(p, fpb, 0.02) for p in q))
                       for q in _placed_fp):
                    rej["suprapunere"] = rej.get("suprapunere", 0) + 1
                    continue
                fl = []
                k_ = -3.5
                while k_ <= 3.5 + 1e-6:
                    fl.append(_spate_h(_GS, *_P(tc + k_, _hd)))
                    k_ += 0.5
                if any(v is None for v in fl):
                    rej["harta"] = rej.get("harta", 0) + 1
                    continue
                floor_ = max(fl)
                Z = (-f_[0], 0.0, f_[1])
                X = (Z[2], 0.0, -Z[0])
                Xm = (X[0], -X[2])
                ddir = (u_[0] * down, u_[1] * down)
                mirror = (Xm[0] * ddir[0] + Xm[1] * ddir[1]) < 0.0
                SPATE_HOUSES.append(dict(
                    name="%s_%02d" % (cname, len([h for h in SPATE_HOUSES if h["row"] == cname])), zone=zone,
                    row=cname, col=ci_, seg=(ci_, si_), i=i_, tc=tc, ctr=ctr, fp=fp, fpb=fpb, f=f_, u=u_,
                    X=X, Z=Z, mirror=mirror, floor=floor_, d_road=d_road,
                    stem=KIT_SEQ[(i_ + 2 * ci_ + (0 if face > 0 else 1)) % len(KIT_SEQ)],
                    pastel=(i_ * 2 + (0 if face > 0 else 3) + ci_) % len(PASTELS)))
                _placed_fp.append(fpb)

    # --- fusta si ingroparea, pe laturile VIZIBILE (fara alta casa lipita), pana se stabilizeaza:
    # o casa scoasa descopera laturile vecinilor ei
    def _inside_any(p, own, fps_):
        for q in fps_:
            if q is not own and _in_convex(p, q, 0.0):
                return True
        return False

    while True:
        fps_all = [h["fp"] for h in CASE_HOUSES] + [h["fp"] for h in SPATE_HOUSES]
        bad = []
        for h in SPATE_HOUSES:
            fp = h["fp"]
            near_ = [q for q in fps_all if math.dist(q[0], fp[0]) < 30.0]
            cx_, cy_ = sum(p[0] for p in fp) / 4.0, sum(p[1] for p in fp) / 4.0
            lo_vis, hi_vis = 1e9, -1e9
            for i in range(4):
                a, b = fp[i], fp[(i + 1) % 4]
                L = math.dist(a, b)
                ox, oy = (b[1] - a[1]) / L, -(b[0] - a[0]) / L
                if ox * ((a[0] + b[0]) / 2.0 - cx_) + oy * ((a[1] + b[1]) / 2.0 - cy_) < 0.0:
                    ox, oy = -ox, -oy                                     # normala spre exterior
                n = max(1, int(round(L / 0.5)))
                for k in range(n + 1):
                    p = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
                    po = (p[0] + ox * 0.3, p[1] + oy * 0.3)
                    if _inside_any(po, fp, near_):
                        continue
                    g_ = _spate_h(_GS, *p)
                    lo_vis, hi_vis = min(lo_vis, g_), max(hi_vis, g_)
            h["drop"] = h["floor"] - lo_vis
            h["bury"] = hi_vis - h["floor"]
            if h["drop"] > CASE_SKIRT - 0.05:
                bad.append((h, "fusta"))
            elif h["bury"] > SPATE_BURY_MAX:
                bad.append((h, "ingropata"))
            elif lo_vis < 1.5:
                bad.append((h, "mal"))
        if not bad:
            break
        for h, why in bad:
            rej[why] = rej.get(why, 0) + 1
            SPATE_HOUSES.remove(h)
    # vecinii (acelasi rand, acelasi segment, consecutivi): alta familie, alt pastel
    for a_h, b_h in zip(SPATE_HOUSES, SPATE_HOUSES[1:]):
        if a_h["seg"] == b_h["seg"] and b_h["i"] == a_h["i"] + 1:
            if a_h["stem"].split("_")[2] == b_h["stem"].split("_")[2] or a_h["pastel"] == b_h["pastel"]:
                raise SystemExit("randurile din spate: vecinii %s / %s au aceeasi familie sau acelasi pastel"
                                 % (a_h["name"], b_h["name"]))
    SPATE_STATS["rej"] = rej

if SPATE_HOUSES:
    _stems = list(KIT_SEQ)
    _rids = [_p7_glb("%s/%s.glb" % (CASE_DIR, s_), "p8_" + s_) for s_ in _stems]
    _rids_m = [_p7_glb("%s/%s_m.glb" % (CASE_DIR, s_), "p8_" + s_ + "_m") for s_ in _stems]
    if all(_rids) and all(_rids_m):
        P7_EXT.append('[ext_resource type="Script" path="res://scenes/props/city_fill.gd" id="p8b_cityfill"]\n')
        xf_, wall_, sh_ = [], [], []
        for h in SPATE_HOUSES:
            X, Z = h["X"], h["Z"]
            if h["mirror"]:
                X = (-X[0], -X[1], -X[2])
            o = (h["ctr"][0], h["floor"], -h["ctr"][1])
            xf_ += [_stems.index(h["stem"]), X[0], X[1], X[2], 0, 1, 0, Z[0], Z[1], Z[2], o[0], o[1], o[2]]
            wall_.append(h["pastel"])
            h["casts"] = h["d_road"] <= SPATE_SHADOW_M
            sh_.append(1 if h["casts"] else 0)

        def _fl(v):
            s_ = ("%.3f" % v).rstrip("0").rstrip(".")
            return "0" if s_ in ("-0", "") else s_

        P8B_NODES = ['[node name="CaseSpate" type="Node3D" parent="."]\n'
                     'script = ExtResource("p8b_cityfill")\n'
                     'models = Array[PackedScene]([%s])\n'
                     'mirror_models = Array[PackedScene]([%s])\n'
                     '%s'
                     'wall_classes = PackedStringArray(%s)\n'
                     'explicit_xforms = PackedFloat32Array(%s)\n'
                     'explicit_wall = PackedInt32Array(%s)\n'
                     'explicit_shadow = PackedInt32Array(%s)\n'
                     '%s'
                     'metadata/sf_spate = true\n'
                     % (", ".join('ExtResource("%s")' % r_ for r_ in _rids),
                        ", ".join('ExtResource("%s")' % r_ for r_ in _rids_m),
                        ("cell_m = %.1f\n" % SPATE_CELL) if SPATE_CELL > 0.0 else "",
                        ", ".join('"%s"' % c_ for c_ in PASTELS),
                        ", ".join(_fl(v) for v in xf_), ", ".join(str(v) for v in wall_),
                        ", ".join(str(v) for v in sh_), "explicit_cells = true\n" if SPATE_CELL > 0.0 else "")]
        bodies = [h for h in SPATE_HOUSES if h["d_road"] < SPATE_BODY_M]
        if bodies:
            P6_SUB.append('[sub_resource type="BoxShape3D" id="Box_spate7"]\nsize = Vector3(%.1f, %.1f, %.1f)\n'
                          % (CASE_W, CASE_SKIRT + CASE_EAVE, CASE_D))
            P8B_NODES.append('[node name="CaseSpateCorpuri" type="StaticBody3D" parent="."]\n')
            for h in bodies:
                X, Z = h["X"], h["Z"]
                yc = h["floor"] - CASE_SKIRT + (CASE_SKIRT + CASE_EAVE) / 2.0
                P8B_NODES.append('[node name="Corp_%s" type="CollisionShape3D" parent="CaseSpateCorpuri"]\n'
                                 'transform = Transform3D(%.5f, 0, %.5f, 0, 1, 0, %.5f, 0, %.5f, %.3f, %.3f, %.3f)\n'
                                 'shape = SubResource("Box_spate7")\n'
                                 % (h["name"], X[0], Z[0], X[2], Z[2], h["ctr"][0], yc, -h["ctr"][1]))
        P7_NODES += P8B_NODES
        from collections import Counter
        print("randurile din spate: %d case (%s) in %d randuri, %d oglindite (fisierul _m), %d cu cutie (< %.0f m de "
              "o banda), %d arunca umbra (<= %.0f m); respinse %s" % (
                  len(SPATE_HOUSES), ", ".join("%s %d" % kv for kv in sorted(Counter(h["zone"] for h in SPATE_HOUSES).items())),
                  len({h["row"] for h in SPATE_HOUSES}), sum(1 for h in SPATE_HOUSES if h["mirror"]), len(bodies),
                  SPATE_BODY_M, sum(1 for h in SPATE_HOUSES if h["casts"]), SPATE_SHADOW_M, dict(sorted(SPATE_STATS["rej"].items()))))
        for rn in dict.fromkeys(h["row"] for h in SPATE_HOUSES):
            hs = [h for h in SPATE_HOUSES if h["row"] == rn]
            print("  %-5s %2d case, podeaua %.1f..%.1f, cadere max %.2f, ingropare max %.2f, banda la >= %.1f m" % (
                rn, len(hs), min(h["floor"] for h in hs), max(h["floor"] for h in hs), max(h["drop"] for h in hs),
                max(h["bury"] for h in hs), min(h["d_road"] for h in hs)))

if P7_NODES:
    # containerul de decor asezat din generator: `WorldProp` pune materialul lumii pe tot
    # subarborele; pista il cauta dupa nume (`DecorManual`), la radacina
    P7_EXT.append('[ext_resource type="Script" path="res://scenes/props/world_prop.gd" id="p7_worldprop"]\n')
    P7_NODES.insert(0, '[node name="DecorManual" type="Node3D" parent="."]\n'
                       'script = ExtResource("p7_worldprop")\n')
# fara niciun model, scena iese octet cu octet ca la pasul 6
P7_TAIL = (chr(10) + chr(10).join(P7_NODES)) if P7_NODES else ""

tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="3_branch"]
[ext_resource type="ArrayMesh" path="res://{OBJ_REL}" id="4_gri"]
[ext_resource type="Script" path="res://scenes/hazards/bus_hazard.gd" id="5_bus"]
{POD_EXT}{"".join(P6_EXT)}{"".join(P7_EXT)}
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

{chr(10).join(sub + POD_SUB + P6_SUB)}
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
{chr(10).join(POD_PROPS + P6_PROPS + meta)}

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
{"".join(l_ + chr(10) for l_ in P6_BRANCH)}
[node name="SerpentineGri" type="Node3D" parent="."]

[node name="Mesh" type="MeshInstance3D" parent="SerpentineGri"]
mesh = ExtResource("4_gri")
material_override = SubResource("Mat_gri")

{chr(10).join(nodes)}
[node name="Tramvaie" type="Node3D" parent="."]
{tram_nodes}
{chr(10).join(POD_NODES)}
{chr(10).join(P6_NODES)}{P7_TAIL}"""
with open(os.devnull if DRY else OUT_TSCN, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"scris {os.path.relpath(OUT_TSCN, ROOT)}; sea_level_offset {SEA_OFFSET}")
if not B200:
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
        if B200 and T.seg[(i + 1) % N].startswith("pod") and T.seg[(i + 1) % N] != "pod baza":
            w = LANE_Z      # pe pod: fiecare banda pana la axa (despartitorul)
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

    if not B200:
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
    else:
        # PODUL: tablierul (parapetele rosii pe fata exterioara), despartitorul (gri fix pe paliere,
        # portocaliu mobil pe tablier, cu S-ul camionului la mijloc), portalurile, sensurile.
        ax0, ax1 = (X_D0, AXIS_Y), (X_D1, AXIS_Y)
        for sg in (1, -1):
            d.line([px((ax0[0] - 12.0, AXIS_Y + sg * DECK_HALF)), px((ax1[0] + 12.0, AXIS_Y + sg * DECK_HALF))],
                   fill=(200, 40, 25), width=5)
        d.line([px((X_D0 - LAND, AXIS_Y)), px((X_D1 + LAND, AXIS_Y))], fill=(235, 235, 235), width=3)
        for k in range(24):
            f0, f1 = k / 24.0, (k + 0.6) / 24.0
            off = OFFSET * (1 if k >= 12 else -1)
            d.line([px((X_D0 + DECK * f0, AXIS_Y + off)), px((X_D0 + DECK * f1, AXIS_Y + off))],
                   fill=(255, 150, 30), width=4)
        tm = px((X_D0 + DECK * 0.5, AXIS_Y))
        d.rectangle([tm[0] - 8, tm[1] - 3, tm[0] + 8, tm[1] + 3], fill=(40, 40, 40))
        for f_ in (0.25, 0.75):
            for sg in (1, -1):
                q_ = px((X_D0 + DECK * f_, AXIS_Y + sg * (DECK_HALF + 2.3)))
                d.rectangle([q_[0] - 5, q_[1] - 5, q_[0] + 5, q_[1] + 5], fill=(170, 30, 20))
        for xa, yy, sgn in ((X_D0 + 40, AXIS_Y + LANE_Z, 1), (X_D1 - 40, AXIS_Y - LANE_Z, -1)):
            pa_, pb_ = px((xa, yy)), px((xa + sgn * 40, yy))
            d.line([pa_, pb_], fill=(255, 255, 255), width=3)
            d.polygon([pb_, (pb_[0] - sgn * 9, pb_[1] - 5), (pb_[0] - sgn * 9, pb_[1] + 5)], fill=(255, 255, 255))
        label((X_D0 + 5, AXIS_Y + 70), f"PODUL ROSU: tablier {DECK:.0f} m la +{DECK_Y:.0f}, dus-intors,\n"
              f"despartitor mobil (camion, ciclu {TRUCK_CYCLE:.0f} s); circulatie pe STANGA", f=font,
              fill=(255, 255, 255))
        label((MK["far0"][2] + 10, MK["far0"][3] + 60), "malul celalalt (+20):\nintoarcerea-balon R20",
              f=font, fill=(90, 60, 10))
        label((MK["pod0"][2] - 70, MK["pod0"][3] + 40), "capul de pod", f=font_s)
        label((X_T + 14, 100), f"B  strada tramvaiului, spre S\n    +{DECK_Y:.0f} -> +53, {B_WEST_REAL:.0f} m la 11,4%",
              f=font)
        label((40, Y_COAMA - 30), "C  coama +53: bratul de 84 m spre V", f=font)
        label((-150, 150), "D  lantul: 4 muchii\n    spre N, +53 -> +14,6")
        label((-150, 290), "E  terasa +14,6 / furca")
        label((-120, 400), "E  ocolul 400 m\n    +14,6 -> +3")
        label((40, 380), "E'  serpentine\n     R16, 9 m")
        label((-60, QUAY_Y + 20), "F  cheiul de nord (+3, 12 m)", fill=(255, 255, 255))
        label((X_G + 12, 380), f"G  spre pod: +3 -> +{DECK_Y:.0f}\n    ({ramp_len(DECK_Y - Y_LOW):.0f} m de rampa)",
              f=font)
        label((MK["B0"][2] + 30, MK["B0"][3] + 10), "PRIMUL VIRAJ (R30)", f=font_s)
        # start pe banda spre oras
        st_ = PTS[0]
        d.line([px((st_[0], st_[1] - 6.5)), px((st_[0], st_[1] + 6.5))], fill=(0, 0, 0), width=5)
        label((st_[0] - 40, st_[1] - 20), "START / SOSIRE" + (" (alternativa)" if START_AT != "far1" else ""),
              f=font, fill=(0, 0, 0))
        for p, txt in ((tram_up_entry, "tramvai 1: intra din dreapta"),
                       (TRAM1_MAP[-1], "tramvai 1: iese DREPT inainte"),
                       ((MK["placa"][2], MK["placa"][3]), "placa turnanta (decor)"),
                       (TRAM2_MAP[0], "tramvai 2: intra din dreapta"),
                       (TRAM2_MAP[-1], "tramvai 2: iese spre mal")):
            q = px(p)
            d.ellipse([q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5], fill=(150, 20, 40))
            d.text((q[0] + 8, q[1] + 4), txt, fill=(150, 20, 40), font=font_s)
        for path in (TRAM1_MAP, TRAM2_MAP):
            d.line([px(p) for p in path], fill=(150, 20, 40), width=2)
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
    d.text((10, 10), f"Track25 San Francisco — traseul{' B200 (podul rosu)' if B200 else ''} ({TOTAL:.0f} m, orar). Culoarea = cota "
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
