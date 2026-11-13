#!/usr/bin/env python3
"""PLANURI PE HARTIE pentru podul rosu carosabil pe San Francisco (Track25): doua variante de
traseu, desenate ca dezvoltatorul sa aleaga din desene. NU schimba Track25 (traseul aprobat se
importa din tools/gen_sf_route.py in modul SF_ROUTE_DRY=1, care nu scrie nimic).

Podul vine din sonda 1d (worktree wt-sf-pod, ramura sanfrancisco/sonda-pod, tools/gen_sf_pod.py;
brief §7 pasul 1d): doua benzi cu axele la 12,4 m, despartitor mobil +-3,5 m pe tablier, paliere
de 36 m la capete, intoarcere-balon pe malul celalalt (S de despartire 60 m / 8 m, R40 - R20 - R40),
rampa <= 11,5 % cu racorduri de 24 m, coridorul cu doua sensuri incepe dupa >= 60 m drepti (S-ul
de 60 m) dupa ultimul viraj.

  A  RAMIFICATIE de pe latura de est: traseul aprobat ramane neatins (lantul, urcarea,
     scurtatura, tramvaiele, dreapta de start); COTUL PIATETEI (al doilea din cele trei gesturi
     ale laturii de est) e inlocuit de dus-intorsul pe pod, spre E, peste golf.
  B  BUCLA RECONSTRUITA in jurul podului: tablierul poarta dreapta de start (dus, spre oras) si
     dreapta finala (intors, spre malul celalalt); latura de est (faleza) dispare. Blocuri
     pastrate: lantul (runup 96 + 4 muchii + terasa), scurtatura cu serpentine + ocolul de 400 m +
     tramvaiul 2 + strada de jos, strada tramvaiului 1 (292 m la 11,4 %, coltul din varf la R24,
     tramvaiul intra din dreapta la 20 m dupa coltul de dinainte si iese drept inainte).

    python tools/gen_sf_pod_plan.py --variant=A [--deck=200] [--deck-y=23]
    python tools/gen_sf_pod_plan.py --variant=B [--deck=200] [--deck-y=20] [--xg=150]

Scrie: planul docs/asset_briefs/img/sf_pod_plan/sf_pod_plan_<V><D>.png, scena de geometrie
tools/SondaSfPodPlan<V><D>.tscn (doar pentru ProbeLayout: bucla + scurtatura, fara decor) si
tipareste cifrele (lungime, tur estimat, cat din tur e pe pod, cea mai lunga dreapta, statistici
de geometrie). Doua treceri, ca la gen_sf_route (fractiile muchiilor pe indicele copt):
    godot --headless --path . res://tools/ProbeCarraraFracmap.tscn -- \\
        --scene=res://tools/SondaSfPodPlanA200.tscn --out=res://tools/data/sf_pod_plan_A200_fracmap.tsv
    python tools/gen_sf_pod_plan.py --variant=A --deck=200
    godot --headless --fixed-fps 60 --path . res://tools/ProbeLayout.tscn -- \\
        --scene=res://tools/SondaSfPodPlanA200.tscn

TIMPUL DE TUR ESTIMAT (nu e ProbeRace): ritmul fiecarei bucati pastrate din Track25 se ia din
ProbeRace-ul de la pasul 3 (8 masini x 16 seed-uri, fara tramvaie: viteza mediana pe felii de 5 %,
cu felia grilei inlocuita de cea dinainte), iar bucla veche se recalibreaza pe 77,4 s / 2.424 m.
Bucatile noi au ritmul sondei 1d: tablier + paliere 300 m / 9,1 s, intoarcerea (S + balon + S,
237 m) 9,9 s - 2 paliere; rampa in sus ca urcarea tramvaiului, in jos ca o dreapta; virajele de
90 de grade ca virajele de 90 ale buclei vechi.
"""
import contextlib
import io
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

MY_ARGS = sys.argv[1:]


def arg(name, default):
    for a in MY_ARGS:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


VARIANT = arg("variant", "B").upper()
DECK = float(arg("deck", "200"))
DECK_Y = float(arg("deck-y", "23" if VARIANT == "A" else "20"))
X_G = float(arg("xg", "150"))           # B: axa strazii de intors (fosta faleza G) pe harta
TAG = f"{VARIANT}{int(DECK)}"
PLAN = arg("plan", os.path.join(ROOT, "docs", "asset_briefs", "img", "sf_pod_plan", f"sf_pod_plan_{TAG}.png"))
SCENE_REL = f"tools/SondaSfPodPlan{TAG}.tscn"
SCENE = os.path.join(ROOT, *SCENE_REL.split("/"))
FRACMAP = os.path.join(HERE, "data", f"sf_pod_plan_{TAG}_fracmap.tsv")

# Traseul aprobat, fara sa scrie nimic (Track25.tscn ramane cel din joc).
os.environ["SF_ROUTE_DRY"] = "1"
sys.argv = [sys.argv[0]]
with contextlib.redirect_stdout(io.StringIO()):
    import gen_sf_route as gr  # noqa: E402

deg = gr.deg

# --- podul (sonda 1d, tools/gen_sf_pod.py) ---------------------------------------------------
LANE_Z = 6.2               # axa benzii fata de axa podului (axele la 12,4 m)
SPLIT_D, SPLIT_L = 8.0, 60.0
R_BAL, R_IN = 20.0, 40.0   # balonul de intoarcere
LAND = 36.0                # palierele de la capetele tablierului
GRADE_P = 0.115            # rampa podului
EASE = 24.0                # racordurile rampei (la jumatate de panta, ca in gen_sf_pod)
DECK_HALF = 12.2           # fata interioara a parapetului exterior
OFFSET = 3.5               # despartitorul mobil, +-
TRUCK_SPAN = 210.0         # naveta camionului pe sonda (pe tablierul de 300)
R_J = 24.0                 # virajul de 90 de la baza podului, pe banda care intra pe pod
R_T = 30.0                 # virajul de 90 la iesirea de pe pod (B: inaintea strazii tramvaiului)

# --- ritmuri pentru timpul estimat ------------------------------------------------------------
V_DECK = 300.0 / 9.1                       # sonda 1d: o trecere peste tablier
T_TURN = 9.9 - 2 * LAND / V_DECK           # S + balon + S (intoarcerea fara paliere)


class T2(gr.Turtle):
    """Turtle-ul lui gen_sf_route, care retine si segmentele (pentru dreapta cea mai lunga)."""

    def __init__(self, x, y, h):
        super().__init__(x, y, h)
        self.segs = []   # (tip, lungime, raza, unghi, eticheta, s0, s1)

    def straight(self, L, tag, steps=None):
        s0 = self.len
        super().straight(L, tag, steps)
        self.segs.append(("S", L, math.inf, 0.0, tag, s0, self.len))

    def arc(self, R, ang_deg, right, tag):
        s0 = self.len
        c = super().arc(R, ang_deg, right, tag)
        self.segs.append(("A", R * deg(ang_deg), R, ang_deg, tag, s0, self.len))
        return c


def s_curve(t, first_right, tag):
    """S-ul de 60 m cu deplasare de 8 m (sonda: benzile se despart / se unesc la capete)."""
    alpha = 2.0 * math.atan2(SPLIT_D, SPLIT_L)
    rad = SPLIT_L / (2.0 * math.sin(alpha))
    t.arc(rad, math.degrees(alpha), first_right, tag)
    t.arc(rad, math.degrees(alpha), not first_right, tag)


def balloon_right(t, tag):
    """Intoarcerea-balon OGLINDITA fata de sonda (acolo: dreapta, stanga 180+2T, dreapta): aici
    banda de dus e pe STANGA axei (circulatie pe stanga pe pod, vezi mai jos), deci intoarcerea
    e la dreapta: stanga T la R_IN, dreapta 180+2T la R_BAL, stanga T la R_IN."""
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


def climb_q(d, rise, grade=None, rb=24.0, rt=24.0):
    """Urcarea cu racorduri patratice (forma din gen_sf_route.elev_s), panta gr.GRADE."""
    g = grade if grade else gr.GRADE
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


# =============================================================================================
# Varianta A — ramificatie din cotul piatetei
# =============================================================================================
def build_A():
    t = T2(gr.X_E, gr.Y_START, deg(-90))
    t.mark("start")
    # IDENTIC cu gen_sf_route.build_loop pana la cotul piatetei (aceleasi apeluri, aceleasi puncte)
    t.straight(gr.START_TO_CORNER, "A")
    t.mark("A/B")
    t.arc(gr.R_AB, 90, True, "A/B")
    t.mark("B0")
    t.straight(gr.B_WEST_REAL, "B vest")
    t.mark("B colt")
    t.arc(gr.R_B, 90, True, "B colt")
    t.straight(gr.B_NORTH, "B nord")
    t.mark("B1")
    t.arc(gr.R_C1, 90, True, "C1")
    t.straight(gr.C_EAST, "C est")
    t.arc(gr.R_C2, 90, False, "C2")
    t.mark("lant0")
    t.straight(gr.CHAIN_STEPS * gr.STEP, "D", steps=gr.CHAIN_STEPS)
    t.mark("furca")
    t.arc(gr.RB, 90, False, "E ocol 1")
    t.straight(gr.BYP_A, "E ocol A")
    t.arc(gr.RB, 90, True, "E ocol 2")
    t.straight(gr.BYP_B, "E ocol B")
    t.arc(gr.RB, 90, True, "E ocol 3")
    t.mark("placa")
    t.straight(gr.QUAY_X_END - t.x, "E/F strada de jos")
    t.mark("NE")
    t.arc(gr.R_NE, 90, True, "G colt NE")
    t.straight(gr.S1_LEN, "G faleza")
    t.mark("cot")
    n_same = len(t.pts)
    # --- dus-intorsul pe pod, spre E. CIRCULATIE PE STANGA pe pod: banda care pleaca (spre E) e
    # cea de NORD, cea care se intoarce (spre V) e cea de SUD. Pe dreapta, banda de plecare ar fi
    # cea de sud, iar faleza care vine din nord ar trebui sa o traverseze pe cea de intors.
    t.arc(R_J, 90, False, "pod baza")             # S -> E, la stanga
    s_curve(t, True, "pod S")                     # spre axa (sud)
    t.mark("pod0")                                # capul despartitorului fix
    rise = DECK_Y - gr.Y_LOW
    t.straight(ramp_len(rise), "pod rampa sus")
    t.straight(LAND, "pod palier")
    t.mark("tab0")
    t.straight(DECK, "pod tablier")
    t.mark("tab1")
    t.straight(LAND, "pod palier")
    t.mark("far0")
    s_curve(t, False, "pod intoarcere")           # spre nord (afara)
    balloon_right(t, "pod intoarcere")
    s_curve(t, True, "pod intoarcere")            # spre axa (nord)
    t.mark("far1")
    t.straight(LAND, "pod palier")
    t.mark("tab1r")
    t.straight(DECK, "pod tablier")
    t.mark("tab0r")
    t.straight(LAND, "pod palier")
    t.mark("ramp_jos")
    t.straight(ramp_len(rise), "pod rampa jos")
    t.mark("pod1")
    s_curve(t, False, "pod S")                    # spre sud (afara)
    t.straight(t.x - (gr.X_MID + R_J), "pod baza")
    t.arc(R_J, 90, False, "pod baza")             # V -> S, la stanga
    assert abs(t.x - gr.X_MID) < 1e-6, (t.x, gr.X_MID)
    t.mark("S2")
    t.straight(t.y - (gr.Y_START + gr.DEV_BEFORE_START + gr.DEV_V), "G faleza 2")
    t.mark("deviere")
    t.arc(gr.DEV_R, gr.DEV_ANG, False, "G deviere")
    t.straight(gr.DEV_DIAG, "G deviere")
    t.arc(gr.DEV_R, gr.DEV_ANG, True, "G deviere")
    t.mark("sprint")
    t.straight(t.y - gr.Y_START, "G sprint")
    assert abs(t.x - gr.X_E) < 1e-6 and abs(t.y - gr.Y_START) < 1e-6
    t.pts.pop()
    t.s.pop()
    t.seg.pop()
    for k in range(n_same):
        assert math.dist(t.pts[k], gr.PTS[k]) < 1e-6
    mk = t.marks
    elev = []
    for i in range(len(t.pts)):
        sv = t.s[i]
        if i < n_same:
            elev.append(gr.ELEV[i])
        elif sv <= mk["pod0"][1]:
            elev.append(gr.Y_LOW)
        elif sv <= mk["ramp_jos"][1]:
            elev.append(gr.Y_LOW + ramp_y(sv - mk["pod0"][1], rise))
        elif sv <= mk["pod1"][1]:
            elev.append(DECK_Y - ramp_y(sv - mk["ramp_jos"][1], rise))
        else:
            elev.append(gr.Y_LOW)
    lips = list(gr.LIPS)
    return t, elev, lips, 0


# =============================================================================================
# Varianta B — bucla reconstruita in jurul podului
# =============================================================================================
Y_COAMA = -gr.RUNUP - 36.0           # strada coamei (spre V) inainte de C2' (dreapta R36 spre N)
X_T = X_G + R_J - R_T                # strada tramvaiului (spre S): iesirea de pe pod vireaza direct


def build_B():
    t = T2(0.0, -gr.RUNUP, deg(90))
    t.mark("lant0")
    t.straight(gr.CHAIN_STEPS * gr.STEP, "D", steps=gr.CHAIN_STEPS)
    t.mark("furca")
    t.arc(gr.RB, 90, False, "E ocol 1")
    t.straight(gr.BYP_A, "E ocol A")
    t.arc(gr.RB, 90, True, "E ocol 2")
    t.straight(gr.BYP_B, "E ocol B")
    t.arc(gr.RB, 90, True, "E ocol 3")
    t.mark("placa")
    assert abs(t.y - gr.QUAY_Y) < 1e-6
    t.straight((X_G - gr.R_NE) - t.x, "E/F strada de jos")
    t.mark("NE")
    t.arc(gr.R_NE, 90, True, "G colt NE")
    t.mark("G0")
    # cota la care trebuie sa inceapa virajul spre pod, ca strada tramvaiului sa ajunga exact la
    # coltul din varf (y = Y_COAMA + R_B) dupa cei 292 m ai ei
    y_turn = (Y_COAMA + gr.R_B + gr.B_WEST_REAL + R_T + SPLIT_D + 2 * LANE_Z + SPLIT_D + R_J)
    t.straight(t.y - y_turn, "G spre pod")
    t.mark("G1")
    t.arc(R_J, 90, False, "pod baza")             # S -> E, la stanga (circulatie pe stanga)
    s_curve(t, True, "pod S")
    t.mark("pod0")
    t.straight(LAND, "pod palier")
    t.mark("tab0")
    t.straight(DECK, "pod tablier")
    t.mark("tab1")
    t.straight(LAND, "pod palier")
    t.mark("far0")
    s_curve(t, False, "pod intoarcere")
    balloon_right(t, "pod intoarcere")
    s_curve(t, True, "pod intoarcere")
    t.mark("far1")                                # LINIA DE START (pe banda de dus, spre oras)
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
    t.arc(R_T, 90, False, "B colt A/B")           # V -> S, la stanga: strada tramvaiului
    t.mark("B0")
    assert abs(t.x - X_T) < 1e-6, (t.x, X_T)
    t.straight(gr.B_WEST_REAL, "B vest")          # strada tramvaiului 1, acum spre S
    t.mark("B colt")
    t.arc(gr.R_B, 90, True, "B colt")             # S -> V, la dreapta; tramvaiul iese drept
    t.mark("C0")
    assert abs(t.y - Y_COAMA) < 1e-6, (t.y, Y_COAMA)
    t.straight(t.x - 36.0, "C est")               # coama, spre V (parcul, casele pictate)
    t.arc(36.0, 90, True, "C2")                   # V -> N, la dreapta: elanul de 96 m
    assert abs(t.x) < 1e-6 and abs(t.y + gr.RUNUP) < 1e-6, (t.x, t.y)
    t.pts.pop()
    t.s.pop()
    t.seg.pop()
    mk = t.marks
    # cote
    s_l0_old = gr.MK["lant0"][1]
    i_placa = mk["placa"][0]
    rise_up = DECK_Y - gr.Y_LOW
    s_up0 = mk["G1"][1] - ramp_len(rise_up)        # rampa de intors se termina la virajul spre pod
    rise_climb = gr.Y_TOP - DECK_Y
    elev = []
    for i in range(len(t.pts)):
        sv = t.s[i]
        if i <= i_placa:
            elev.append(gr.ELEV[gr.i_lant0 + i])
        elif sv < s_up0:
            s_old = sv - mk["placa"][1] + gr.MK["placa"][1]
            elev.append(gr.elev_s(s_old) if s_old <= gr.s_M else gr.Y_LOW)
        elif sv <= mk["G1"][1]:
            elev.append(gr.Y_LOW + ramp_y(sv - s_up0, rise_up))
        elif sv <= mk["B0"][1]:
            elev.append(DECK_Y)
        else:
            elev.append(DECK_Y + climb_q(sv - mk["B0"][1], rise_climb))
    # punctul 0 = linia de start
    k0 = mk["far1"][0]
    t.marks = {n: ((v[0] - k0) % len(t.pts), (v[1] - t.s[k0]) % t.len, v[2], v[3]) for n, v in mk.items()}
    s0 = t.s[k0]
    t.pts = t.pts[k0:] + t.pts[:k0]
    t.s = [(v - s0) % t.len for v in t.s[k0:] + t.s[:k0]]
    t.seg = t.seg[k0:] + t.seg[:k0]
    t.segs = [(a, b, c, d, e, (f - s0) % t.len, (f - s0) % t.len + b) for a, b, c, d, e, f, g in t.segs]
    elev = elev[k0:] + elev[:k0]
    i_l = (0 - k0) % len(t.pts)
    lips = [(i_l + gr.LIP1_STEP + 6 * b) for b in range(gr.BLOCKS)]
    return t, elev, lips, s_up0


T, ELEV, LIPS, S_UP0 = build_A() if VARIANT == "A" else build_B()
PTS, S, SEG, MK, TOTAL = T.pts, T.s, T.seg, T.marks, T.len
N = len(PTS)
MAIN_G = [(PTS[i][0], ELEV[i], -PTS[i][1]) for i in range(N)]
assert abs(ELEV[LIPS[0]] - gr.Y_TOP) < 1e-6, ELEV[LIPS[0]]
assert abs(ELEV[LIPS[-1] + 4] - gr.Y_TERRACE) < 1e-6

# =============================================================================================
# Cifre
# =============================================================================================
out = []


def say(s=""):
    out.append(s)
    print(s)


def seg_len(prefix):
    return sum(s1 - s0 for k, L, R, a, tag, s0, s1 in T.segs if tag.startswith(prefix))


say(f"=== Varianta {VARIANT}, tablier {DECK:.0f} m la +{DECK_Y:.0f} ===")
say(f"bucla: {N} puncte de control, {TOTAL:.0f} m (Track25 azi: {gr.TOTAL:.0f} m pe poligon, 2.424 m copt)")

# --- timpul estimat --------------------------------------------------------------------------
SLICES = [31.8, 31.7, 32.2, 29.5, 28.6, 30.9, 30.0, 33.3, 32.7, 33.3,
          26.7, 26.3, 27.1, 29.9, 32.9, 32.3, 32.9, 31.7, 33.4, 23.9]   # ProbeRace pas 3, r_base
SLICES_FLY = SLICES[:-1] + [SLICES[-2]]       # felia grilei (lenta din countdown) -> cea dinainte
pace_old = {}                                  # eticheta veche -> [metri, secunde]
for i in range(gr.N):
    a, b = gr.S[i], (gr.S[i + 1] if i + 1 < gr.N else gr.TOTAL)
    v = SLICES_FLY[min(19, int(((a + b) * 0.5) / gr.TOTAL * 20))]
    acc = pace_old.setdefault(gr.T.seg[i + 1] if i + 1 < gr.N else "G sprint", [0.0, 0.0])
    acc[0] += b - a
    acc[1] += (b - a) / v
t_old = sum(v[1] for v in pace_old.values())
K = 77.4 / t_old                               # recalibrarea pe turul masurat


def pace(tag):
    m, s = pace_old[tag]
    return s / m * K


corner90 = sum(pace_old[k][1] for k in ("A/B", "G colt NE", "B colt")) / \
    sum(pace_old[k][0] for k in ("A/B", "G colt NE", "B colt")) * K
flat = pace("G faleza")
climb = pace("B vest")
t_parts = {}


def add_time(name, sec):
    t_parts[name] = t_parts.get(name, 0.0) + sec


for k, L, R, a, tag, s0, s1 in T.segs:
    if tag in ("pod tablier", "pod palier"):
        add_time("pod: tablier + paliere", L / V_DECK)
    elif tag == "pod intoarcere":
        add_time("pod: intoarcerea (S + balon + S)", L / 237.0 * T_TURN)
    elif tag == "pod rampa sus":
        add_time("pod: rampe", L * climb)
    elif tag == "pod rampa jos":
        add_time("pod: rampe", L / V_DECK)
    elif tag in ("pod S",):
        add_time("pod: baza (S + viraje)", L * flat)
    elif tag == "pod baza":
        add_time("pod: baza (S + viraje)", L * (corner90 if k == "A" else flat))
    elif tag == "G spre pod":
        up = min(L, ramp_len(DECK_Y - gr.Y_LOW))
        add_time("oras", up * climb + (L - up) * flat)
    elif tag == "B colt A/B":
        add_time("oras", L * pace("A/B"))
    elif tag in pace_old:
        add_time("oras", L * pace(tag))
    else:
        raise KeyError(tag)
LAP = sum(t_parts.values())
say(f"tur estimat: {LAP:.1f} s  (Track25: 77,4 s; recalibrare K = {K:.3f})")
for kk, vv in t_parts.items():
    say(f"    {kk:36s} {vv:5.1f} s")

on_deck = seg_len("pod tablier") + seg_len("pod palier")
on_bridge = sum(s1 - s0 for k, L, R, a, tag, s0, s1 in T.segs if tag.startswith("pod"))
t_deck = t_parts.get("pod: tablier + paliere", 0.0)
t_bridge = sum(v for kk, v in t_parts.items() if kk.startswith("pod"))
say(f"pe tablier (cu paliere): {on_deck:.0f} m = {100 * on_deck / TOTAL:.0f}% din lungime, "
    f"{t_deck:.1f} s = {100 * t_deck / LAP:.0f}% din timp")
say(f"pe pod cu tot (rampe, baza, intoarcere): {on_bridge:.0f} m = {100 * on_bridge / TOTAL:.0f}%, "
    f"{t_bridge:.1f} s = {100 * t_bridge / LAP:.0f}% din timp")

# --- cea mai lunga dreapta -------------------------------------------------------------------


def longest(loose):
    """Cea mai lunga bucata fara viraj. loose: S-urile de 60 m / 8 m (raza 114) nu rup dreapta."""
    segs = T.segs
    best, cur, cur_tags, best_tags, cur_s0, best_s0 = 0.0, 0.0, [], [], 0.0, 0.0
    n = len(segs)
    for j in range(2 * n):
        k, L, R, a, tag, s0, s1 = segs[j % n]
        ok = k == "S" or (loose and R >= 100.0)
        if ok:
            if cur == 0.0:
                cur_s0 = s0
            cur += L
            if tag not in cur_tags:
                cur_tags.append(tag)
            if cur > best and cur <= TOTAL:
                best, best_tags, best_s0 = cur, list(cur_tags), cur_s0
        else:
            cur, cur_tags = 0.0, []
    return best, best_tags, best_s0


lg_strict = longest(False)
lg_loose = longest(True)
say(f"cea mai lunga dreapta: {lg_strict[0]:.0f} m ({' + '.join(lg_strict[1])}); "
    f"cu S-urile de 8 m numarate ca drepte: {lg_loose[0]:.0f} m ({' + '.join(lg_loose[1])})")

# --- geometrie, ca ProbeLayout (pe poligon; verdictul il da sonda) ----------------------------
min_r = min(gr.circumradius(PTS[i - 1], PTS[i], PTS[(i + 1) % N]) for i in range(N))
crest = set()
for L in LIPS:
    crest.update(range(L, L + 5))
mx, mx_at = 0.0, 0
for i in range(N):
    if i in crest:
        continue
    a, b = MAIN_G[i], MAIN_G[(i + 1) % N]
    d = math.hypot(b[0] - a[0], b[2] - a[2])
    sl = abs(b[1] - a[1]) / d
    if sl > mx:
        mx, mx_at = sl, i
on_corr = [SEG[i].startswith("pod") for i in range(N)]


def hdg(i):
    a, b = PTS[i], PTS[(i + 1) % N]
    return math.atan2(b[1] - a[1], b[0] - a[0])


min_sep, min_sep_corr, sep_at = 1e9, 1e9, 0
for i in range(N):
    for j in range(i + 9, N):
        if N - (j - i) <= 8:
            continue
        d = math.dist(PTS[i], PTS[j])
        anti = math.cos(hdg(i) - hdg(j)) < -0.95
        if on_corr[i] and on_corr[j] and anti and d < 2 * gr.HW:
            min_sep_corr = min(min_sep_corr, d)
            continue
        if d < min_sep:
            min_sep, sep_at = d, i
cx = sum(MAIN_G[i][0] * math.dist(PTS[i], PTS[(i + 1) % N]) for i in range(N)) / TOTAL
cy = sum(PTS[i][1] * math.dist(PTS[i], PTS[(i + 1) % N]) for i in range(N)) / TOTAL
ext_x = max(abs(p[0] - cx) for p in PTS) + gr.HW
ext_y = max(abs(p[1] - cy) for p in PTS) + gr.HW
say(f"raza minima (poligon): {min_r:.1f} m (prag > {gr.HW}); panta maxima in afara muchiilor: "
    f"{100 * mx:.1f}% (punctul {mx_at}, {SEG[mx_at]})")
say(f"separare minima intre tronsoane, fara cele doua sensuri ale podului: {min_sep:.1f} m "
    f"(prag {2 * gr.HW:.0f}; la {SEG[sep_at]}); sensurile podului: {min_sep_corr:.1f} m (axele la 12,4: EXCEPTIA VOITA)")
say(f"centroid ({cx:.0f}, {cy:.0f}); departare maxima pe axe + semilatimea: x {ext_x:.0f}, y {ext_y:.0f} "
    f"(zidul lumii la 420, Track._build_world_bounds): depasire x {max(0, ext_x - 420):.0f} m, "
    f"y {max(0, ext_y - 420):.0f} m")

# --- podul fata de oras -----------------------------------------------------------------------
tab0, tab1 = MK["tab0"], MK["tab1"]
deck_pts = [(tab0[2] + (tab1[2] - tab0[2]) * k / 20.0, tab0[3] + (tab1[3] - tab0[3]) * k / 20.0) for k in range(21)]
lips_map = [PTS[L] for L in LIPS]
for k, lp in enumerate(lips_map):
    dmin = min(math.dist(lp, q) for q in deck_pts)
    dmax = max(math.dist(lp, q) for q in deck_pts)
    near = min(deck_pts, key=lambda q: math.dist(lp, q))
    az = math.degrees(math.atan2(near[0] - lp[0], near[1] - lp[1]))   # 0 = N (axa lantului)
    say(f"de pe muchia {k + 1} (+{ELEV[LIPS[k]]:.1f}): tablierul la {dmin:.0f}..{dmax:.0f} m, cel mai "
        f"apropiat capat la azimut {az:+.0f} grade fata de axa lantului (- = stanga); FAR_PLANE 380")
far_pt = max(PTS, key=lambda p: math.dist(p, (0.0, 100.0)))
say(f"cel mai departat punct al buclei de mijlocul lantului (0, 100): {math.dist(far_pt, (0.0, 100.0)):.0f} m "
    f"la ({far_pt[0]:.0f}, {far_pt[1]:.0f})")
for name in sorted(MK, key=lambda n: MK[n][1]):
    i, sv, x, y = MK[name]
    say(f"  {sv / TOTAL:6.3f}  {name:10s} ({x:7.1f}, {y:7.1f})  cota {ELEV[i % N]:.1f}")

# =============================================================================================
# Fractii coapte (ProbeCarraraFracmap pe scena de aici) — pentru jump_crests si scurtatura
# =============================================================================================
FMAP = []
if os.path.exists(FRACMAP):
    for line in open(FRACMAP, encoding="utf-8"):
        tk = line.split()
        if len(tk) == 4:
            FMAP.append(tuple(float(v) for v in tk))
    worst = max(min((fx - g[0]) ** 2 + (fz - g[2]) ** 2 for fx, fz, _, _ in FMAP) for g in MAIN_G[::5])
    if worst > 1.0:
        print(f"ATENTIE: harta de fractii {os.path.basename(FRACMAP)} e VECHE; fractii aproximate")
        FMAP = []
print(f"harta de fractii: {'%d puncte' % len(FMAP) if FMAP else 'LIPSA (aprox. pe poligon)'}")


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


jump_crests = [(round(F_s(S[L] - 6.0)[0], 4), round(F_s(S[L] + 54.0)[0], 4)) for L in LIPS]
entry_at = F_xy(*gr.F_MAP)[0]
exit_at = F_xy(gr.M_X + gr.serp.EXIT_AFTER, gr.M_Y)[0]
if FMAP:
    n_b = len(FMAP)
    entry_at = (round(entry_at * n_b) + 0.5) / n_b
    exit_at = (round(exit_at * n_b) + 0.5) / n_b

# =============================================================================================
# Scena de geometrie (doar ProbeLayout / ProbeCarraraFracmap): bucla + scurtatura
# =============================================================================================
tscn = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="3_branch"]

[sub_resource type="Curve3D" id="Curve3D_sf"]
closed = true
_data = {{
"points": {gr.pva(MAIN_G)},
"tilts": PackedFloat32Array({", ".join("0" for _ in MAIN_G)})
}}
point_count = {N}

[sub_resource type="Curve3D" id="Curve3D_serp"]
_data = {{
"points": {gr.pva(gr.BR_MID)},
"tilts": PackedFloat32Array({", ".join("0" for _ in gr.BR_MID)})
}}
point_count = {len(gr.BR_MID)}

[node name="SondaSfPodPlan{TAG}" type="Node3D"]
script = ExtResource("1_track")
custom_name = "SF pod plan {TAG}"
custom_theme = "sanfrancisco"
custom_world_seed_name = "sanfrancisco"
custom_half_width = {gr.HW}
custom_road_surface = "asphalt"
custom_gate_model = "none"
branch_smooth_level = true
terrain_pad_m = 120.0
metadata/jump_crests = [{", ".join(gr.V2(a, b) for a, b in jump_crests)}]

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_sf")

[node name="Serpentine" type="Path3D" parent="."]
curve = SubResource("Curve3D_serp")
script = ExtResource("3_branch")
branch_half_width = {gr.SERP_BW}
entry_at = {entry_at:.5f}
exit_at = {exit_at:.5f}
label = "Serpentine"
surface = 3
"""
with open(SCENE, "w", encoding="utf-8", newline="\n") as f:
    f.write(tscn)
print(f"scris {SCENE_REL} (jump_crests {jump_crests}; scurtatura {entry_at:.4f} -> {exit_at:.4f})")

# =============================================================================================
# Tramvaiele (aceeasi constructie ca gen_sf_route: intra din strada laterala din DREAPTA, la 20 m
# dupa coltul de dinainte, sfert de cerc R14 pe ax, iese DREPT inainte 16 m dincolo de strada
# urmatoare)
# =============================================================================================


def tram1_path():
    b0 = MK["B0"]
    hx, hy = math.cos(T_heading_at(b0[0])), math.sin(T_heading_at(b0[0]))
    rx, ry = hy, -hx                                   # dreapta mersului
    ex, ey = b0[2] + hx * 20.0, b0[3] + hy * 20.0
    pts = [(ex + rx * gr.TRAM_HIDE_LAT, ey + ry * gr.TRAM_HIDE_LAT), (ex + rx * 14.0, ey + ry * 14.0)]
    cxx, cyy = ex + rx * 14.0 + hx * 14.0, ey + ry * 14.0 + hy * 14.0
    a0 = math.atan2(-hy, -hx)
    a1 = math.atan2(-ry, -rx)
    da = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
    for k in range(1, 5):
        a = a0 + da * k / 4
        pts.append((cxx + 14.0 * math.cos(a), cyy + 14.0 * math.sin(a)))
    bc = MK["B colt"]
    # strada urmatoare: axa ei e la R_B dincolo de coltul de sus, pe directia mersului
    end_d = math.hypot(bc[2] - ex, bc[3] - ey) + gr.R_B + gr.TRAM1_EXIT_PAST
    pts.append((ex + hx * end_d, ey + hy * end_d))
    return pts


def T_heading_at(i):
    a, b = PTS[i % N], PTS[(i + 1) % N]
    return math.atan2(b[1] - a[1], b[0] - a[0])


TRAM1 = tram1_path()
TRAM2 = gr.TRAM2_MAP
say(f"tramvaiul 1: curba {sum(math.dist(a, b) for a, b in zip(TRAM1, TRAM1[1:])):.0f} m "
    f"(Track25: 328), ciclu 66 s -> tur / ciclu = {LAP / 66.0:.2f}; tramvaiul 2: ciclu 29 s -> "
    f"tur / ciclu = {LAP / 29.0:.2f}; camionul (sonda: 117 s) -> {LAP / 117.0:.2f}")

# ProbeLayout (rulat pe scena de aici; iesirea pastrata in tools/data/sf_pod_plan_<TAG>_probelayout.txt)
LAYOUT_TXT = os.path.join(HERE, "data", f"sf_pod_plan_{TAG}_probelayout.txt")
if os.path.exists(LAYOUT_TXT):
    lines = [ln.strip() for ln in open(LAYOUT_TXT, encoding="utf-8")]
    main_l = lines[lines.index(next(x for x in lines if x.startswith("ruta 0"))):]
    pick = [x for x in main_l[:6] if x.startswith(("raza minima", "panta maxima", "apropiere de sine"))]
    say("ProbeLayout (sonda, curba coapta): " + "; ".join(" ".join(x.split()) for x in pick)
        + ". Singura abatere: cele doua sensuri ale podului (axele la 12,4 m < 2 x 7), voita; "
        "scurtatura OK (racord 0,00 / 0,00 m, castig 148 m).")
else:
    say("ProbeLayout: nerulat pe scena asta")

# =============================================================================================
# Planul
# =============================================================================================
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

SC_ = 1.25 if VARIANT == "A" else 1.45
xs = [p[0] for p in PTS + gr.PTS]
ys = [p[1] for p in PTS + gr.PTS]
x0, x1 = min(min(xs), -150.0) - 70, max(xs) + 90
y0, y1 = min(ys) - 80, max(ys) + 110
PANEL_W = 560
W, H = int((x1 - x0) * SC_) + PANEL_W, int((y1 - y0) * SC_)
im = Image.new("RGB", (W, H), (236, 228, 205))
d = ImageDraw.Draw(im)
try:
    font = ImageFont.truetype("arial.ttf", 15)
    font_b = ImageFont.truetype("arialbd.ttf", 20)
    font_t = ImageFont.truetype("arialbd.ttf", 17)
    font_s = ImageFont.truetype("arial.ttf", 12)
except OSError:
    font = font_b = font_t = font_s = ImageFont.load_default()


def px(p):
    return ((p[0] - x0) * SC_, H - (p[1] - y0) * SC_)


SEA = (70, 105, 150)
LAND_C = (236, 228, 205)
GOLD = (222, 196, 130)
# apa
if VARIANT == "A":
    lagoon = [(1400.0 if abs(x_ - 900.0) < 1e-6 else x_, y_) for x_, y_ in gr.LAGOON]
else:
    ax_y = MK["pod0"][3] - LANE_Z if False else None
    yb = MK["tab0"][3]                      # banda de intors pe tablier
    axis_y = yb - LANE_Z
    coast = X_G + 40.0
    nx0, nx1 = gr.TRAM2_LEFT_EXIT_X - 8.0, gr.TRAM2_LEFT_EXIT_X + gr.TRAM_R_ + 12.0
    ny = gr.QUAY_Y + 36.0
    lagoon = [(-470.0, gr.SHORE_N), (nx0, gr.SHORE_N), (nx0, ny), (nx1, ny), (nx1, gr.SHORE_N),
              (coast, gr.SHORE_N), (coast, axis_y + 60.0), (MK["tab0"][2] - 6.0, axis_y + 60.0),
              (MK["tab0"][2] - 6.0, axis_y - 70.0), (coast, axis_y - 70.0), (coast, -760.0),
              (1400.0, -760.0), (1400.0, 1100.0), (-470.0, 1100.0)]
d.polygon([px(q) for q in lagoon], fill=SEA)
# malul celalalt: promontoriul cu intoarcerea (dealuri aurii)
far_i0, far_i1 = MK["far0"][0], MK["far1"][0]
idx = range(far_i0, far_i1 + 1) if far_i1 >= far_i0 else list(range(far_i0, N)) + list(range(0, far_i1 + 1))
fx = [PTS[i % N][0] for i in idx]
fy = [PTS[i % N][1] for i in idx]
fa, fb = px((min(fx) - 30, max(fy) + 55)), px((max(fx) + 70, min(fy) - 55))
d.rounded_rectangle([fa[0], fa[1], fb[0], fb[1]], radius=int(60 * SC_), fill=GOLD)
q = px((max(fx) + 10, max(fy) + 45))
d.text((fa[0] + 10, fa[1] + 8), f"malul celalalt (+{DECK_Y:.0f}):\ndealuri aurii", fill=(110, 80, 20), font=font)
if VARIANT == "A":
    # baza podului: umplutura de chei langa piateta
    ba, bb = px((gr.X_MID - 10, MK["cot"][3] + 4)), px((MK["pod0"][2] + 4, MK["S2"][3] - 4))
    d.rectangle([ba[0], ba[1], bb[0], bb[1]], fill=LAND_C)
for name, x, y, e, r in gr.PEAKS:
    a, b = px((x - r, y + r)), px((x + r, y - r))
    d.ellipse([a[0], a[1], b[0], b[1]], outline=(200, 178, 128))

# traseul vechi, subtire (ce se schimba)
for i in range(gr.N):
    a, b = gr.PTS[i], gr.PTS[(i + 1) % gr.N]
    d.line([px(a), px(b)], fill=(150, 150, 150), width=2)


def col(e):
    t_ = max(0.0, min(1.0, (e - gr.Y_LOW) / (gr.Y_TOP - gr.Y_LOW)))
    return (int(40 + 200 * t_), int(90 + 60 * (1 - abs(t_ - 0.5) * 2)), int(200 - 170 * t_))


# podul: parapetele rosii (fata exterioara a tablierului) si turnurile
dir_e = (MK["tab1"][2] - MK["tab0"][2], MK["tab1"][3] - MK["tab0"][3])
ln_ = math.hypot(*dir_e)
ux, uy = dir_e[0] / ln_, dir_e[1] / ln_
nxv, nyv = -uy, ux                                  # stanga mersului spre larg (= nord la ambele)
ax0 = (MK["tab0"][2] - nxv * LANE_Z, MK["tab0"][3] - nyv * LANE_Z)
ax1 = (MK["tab1"][2] - nxv * LANE_Z, MK["tab1"][3] - nyv * LANE_Z)
deck_poly = [(ax0[0] + nxv * DECK_HALF, ax0[1] + nyv * DECK_HALF), (ax1[0] + nxv * DECK_HALF, ax1[1] + nyv * DECK_HALF),
             (ax1[0] - nxv * DECK_HALF, ax1[1] - nyv * DECK_HALF), (ax0[0] - nxv * DECK_HALF, ax0[1] - nyv * DECK_HALF)]
d.polygon([px(q_) for q_ in deck_poly], fill=(200, 60, 40))
DECK_POLY = deck_poly

for i in range(N):
    a, b = MAIN_G[i], MAIN_G[(i + 1) % N]
    w = gr.HW
    if SEG[i].startswith("pod") and SEG[i] not in ("pod baza",):
        w = 6.0
    if SEG[i] == "E/F strada de jos" and VARIANT == "A" and S[i] >= MK["placa"][1] + 130:
        w = gr.HW_QUAY
    d.line([px((a[0], -a[2])), px((b[0], -b[2]))], fill=col((a[1] + b[1]) / 2), width=max(2, int(2 * w * SC_)))
# parapetele rosii ale tablierului, peste benzi
for e0, e1 in ((0, 1), (3, 2)):
    d.line([px(DECK_POLY[e0]), px(DECK_POLY[e1])], fill=(200, 40, 25), width=5)
# scurtatura
for k in range(len(gr.DENSE_G) - 1):
    a, b = gr.DENSE_G[k], gr.DENSE_G[k + 1]
    d.line([px((a[0], -a[2])), px((b[0], -b[2]))], fill=(170, 70, 45), width=int(2 * gr.BW * SC_))
for outline_g, y0_, y1_ in gr.prisms_bed:
    d.polygon([px((p[0], -p[2])) for p in outline_g], fill=(200, 120, 160))

# despartitorul: fix (gri) pe tot coridorul, mobil (portocaliu, +-3,5) pe tablier
p_a = (MK["pod0"][2] - nxv * LANE_Z, MK["pod0"][3] - nyv * LANE_Z)
p_b = (MK["far0"][2] - nxv * LANE_Z, MK["far0"][3] - nyv * LANE_Z)
d.line([px(p_a), px(p_b)], fill=(235, 235, 235), width=3)
seg_n = 24
for k in range(seg_n):
    f0, f1 = k / seg_n, (k + 0.6) / seg_n
    off = OFFSET * (1 if (k // 6) % 2 == 0 else -1)
    qa = (ax0[0] + (ax1[0] - ax0[0]) * f0 + nxv * off, ax0[1] + (ax1[1] - ax0[1]) * f0 + nyv * off)
    qb = (ax0[0] + (ax1[0] - ax0[0]) * f1 + nxv * off, ax0[1] + (ax1[1] - ax0[1]) * f1 + nyv * off)
    d.line([px(qa), px(qb)], fill=(255, 150, 30), width=4)
# turnurile (portaluri) la 1/4 si 3/4 din tablier
for f_ in (0.25, 0.75):
    c_ = (ax0[0] + (ax1[0] - ax0[0]) * f_, ax0[1] + (ax1[1] - ax0[1]) * f_)
    for sg in (1, -1):
        q_ = px((c_[0] + nxv * (DECK_HALF + 2.5) * sg, c_[1] + nyv * (DECK_HALF + 2.5) * sg))
        d.rectangle([q_[0] - 6, q_[1] - 6, q_[0] + 6, q_[1] + 6], fill=(170, 30, 20))
# camionul, la mijlocul tablierului, si naveta lui
span = min(TRUCK_SPAN, DECK - 60.0)
cm = (ax0[0] + (ax1[0] - ax0[0]) * 0.5, ax0[1] + (ax1[1] - ax0[1]) * 0.5)
t_a = px((cm[0] - ux * 5 - nxv * 1.3, cm[1] - uy * 5 - nyv * 1.3))
t_b = px((cm[0] + ux * 5 + nxv * 1.3, cm[1] + uy * 5 + nyv * 1.3))
d.rectangle([min(t_a[0], t_b[0]), min(t_a[1], t_b[1]), max(t_a[0], t_b[0]), max(t_a[1], t_b[1])], fill=(40, 40, 40))
qa = px((cm[0] - ux * span / 2 + nxv * (DECK_HALF + 14), cm[1] - uy * span / 2 + nyv * (DECK_HALF + 14)))
qb = px((cm[0] + ux * span / 2 + nxv * (DECK_HALF + 14), cm[1] + uy * span / 2 + nyv * (DECK_HALF + 14)))
d.line([qa, qb], fill=(40, 40, 40), width=2)
for qq, sgn in ((qa, 1), (qb, -1)):
    d.polygon([qq, (qq[0] + 10 * sgn, qq[1] - 5), (qq[0] + 10 * sgn, qq[1] + 5)], fill=(40, 40, 40))
d.text((min(qa[0], qb[0]) + 10, qa[1] - 22), f"camionul muta despartitorul (+-3,5 m), naveta ~{span:.0f} m",
       fill=(20, 20, 20), font=font_s)
# sensurile pe pod (sageti) — circulatie pe stanga
for mkn, lab in (("tab0", "intors (spre larg)" if VARIANT == "B" else "dus (spre larg)"),
                 ("tab1r", "dus (spre oras), START" if VARIANT == "B" else "intors (spre faleza)")):
    i_ = MK[mkn][0]
    a_ = PTS[i_]
    b_ = PTS[(i_ + 2) % N]
    hh = math.atan2(b_[1] - a_[1], b_[0] - a_[0])
    pa_ = (a_[0] + math.cos(hh) * 30, a_[1] + math.sin(hh) * 30)
    pb_ = (a_[0] + math.cos(hh) * 60, a_[1] + math.sin(hh) * 60)
    d.line([px(pa_), px(pb_)], fill=(255, 255, 255), width=3)
    tip = px(pb_)
    bk = (pb_[0] - math.cos(hh) * 9, pb_[1] - math.sin(hh) * 9)
    l_ = px((bk[0] - math.sin(hh) * 5, bk[1] + math.cos(hh) * 5))
    r_ = px((bk[0] + math.sin(hh) * 5, bk[1] - math.cos(hh) * 5))
    d.polygon([tip, l_, r_], fill=(255, 255, 255))
    lq = px((a_[0] + math.cos(hh) * 70, a_[1] + math.sin(hh) * 70))
    d.text((lq[0] + 4, lq[1] + (6 if mkn == "tab1r" else -22)), lab, fill=(255, 255, 255), font=font_s)

# muchiile
for k, L in enumerate(LIPS):
    p = PTS[L]
    a, b = px((p[0] - gr.HW - 3, p[1])), px((p[0] + gr.HW + 3, p[1]))
    d.line([a, b], fill=(255, 255, 255), width=5)
    d.text((b[0] + 6, b[1] - 9), f"muchia {k + 1}  +{ELEV[L]:.1f}", fill=(0, 0, 0), font=font_s)
# fractii
for k in range(0, 100, 5):
    p = pos_at(TOTAL * k / 100.0)
    q_ = px(p)
    d.ellipse([q_[0] - 3, q_[1] - 3, q_[0] + 3, q_[1] + 3], fill=(0, 0, 0))
    d.text((q_[0] + 5, q_[1] + 2), f"{k / 100:.2f}", fill=(30, 30, 30), font=font_s)
# start
i0 = 0
h0 = T_heading_at(i0)
pl = (PTS[0][0] - math.sin(h0) * 9, PTS[0][1] + math.cos(h0) * 9)
pr = (PTS[0][0] + math.sin(h0) * 9, PTS[0][1] - math.cos(h0) * 9)
for kk in range(6):
    f0, f1 = kk / 6, (kk + 1) / 6
    qa = px((pl[0] + (pr[0] - pl[0]) * f0, pl[1] + (pr[1] - pl[1]) * f0))
    qb = px((pl[0] + (pr[0] - pl[0]) * f1, pl[1] + (pr[1] - pl[1]) * f1))
    d.line([qa, qb], fill=(0, 0, 0) if kk % 2 == 0 else (255, 255, 255), width=7)
# tramvaiele
for path, nm in ((TRAM1, "tramvai 1"), (TRAM2, "tramvai 2")):
    d.line([px(p) for p in path], fill=(150, 20, 40), width=3)
    q_ = px(path[0])
    d.ellipse([q_[0] - 5, q_[1] - 5, q_[0] + 5, q_[1] + 5], fill=(150, 20, 40))
    q_ = px(path[-1])
    d.ellipse([q_[0] - 5, q_[1] - 5, q_[0] + 5, q_[1] + 5], fill=(150, 20, 40))
q_ = px(TRAM1[0])
d.text((q_[0] + 8, q_[1] - 4), "tramvai 1: intra din dreapta", fill=(150, 20, 40), font=font_s)
q_ = px(TRAM1[-1])
d.text((q_[0] + 8, q_[1] - 4), "tramvai 1: iese DREPT", fill=(150, 20, 40), font=font_s)
q_ = px(TRAM2[0])
d.text((q_[0] + 8, q_[1] + 2), "tramvai 2", fill=(150, 20, 40), font=font_s)


def label(p, txt, dx=8, dy=-8, f=font_b, fill=(20, 20, 20)):
    q_ = px(p)
    d.text((q_[0] + dx, q_[1] + dy), txt, fill=fill, font=f)


label((-150, 150), "D  lantul: 4 muchii\n    spre N, +53 -> +14,6")
label((-150, 290), "E  terasa / furca")
label((-125, 410), "E  ocolul\n    400 m", f=font_t)
label((40, 380), "E'  serpentine", f=font_t)
label((MK["tab0"][2] - 10, MK["tab0"][3] + 92), f"PODUL ROSU: tablier {DECK:.0f} m la +{DECK_Y:.0f},\n"
      f"doua sensuri, despartitor mobil", fill=(255, 255, 255), f=font_t)
label((MK["far0"][2] - 60, MK["far0"][3] - 95), "intoarcerea\n(balon R20, S de 60 m)", f=font, fill=(90, 60, 10))
if VARIANT == "A":
    label((gr.X_E + 14, gr.Y_START + 40), "A  START (neschimbat)", f=font_t)
    q_ = px((gr.X_E, gr.Y_S - 22.0))
    d.rectangle([q_[0] - 6, q_[1] - 6, q_[0] + 6, q_[1] + 6], fill=(120, 60, 30))
    d.text((q_[0] + 10, q_[1] - 2), "turnul cu ceas", fill=(0, 0, 0), font=font_s)
    label((gr.X_B + 70, gr.Y_S - 30), "B  urcarea +3 -> +53", f=font_t)
    label((gr.X_B - 110, gr.Y_CTOP + 40), "C  coama +53", f=font_t)
    label((60, gr.QUAY_Y + 22), "F  cheiul de nord (+3)", f=font_t, fill=(255, 255, 255))
    label((MK["pod0"][2] - 10, MK["pod0"][3] - 60), f"baza podului: in locul\ncotului piatetei; rampa +3 -> +{DECK_Y:.0f}"
          f" ({ramp_len(DECK_Y - 3):.0f} m)", f=font_s)
    label((gr.X_E_HI + 20, 330), "G  faleza, dreapta 1 (172 m)", f=font_s, fill=(255, 255, 255))
    label((gr.X_MID + 20, 110), f"G  dreapta 2 ({MK['deviere'][1] - MK['S2'][1]:.0f} m)", f=font_s,
          fill=(255, 255, 255))
else:
    label((MK["far1"][2] - 60, MK["far1"][3] - 40), "START / SOSIRE", f=font_t, fill=(0, 0, 0))
    label((X_T + 14, 90), f"B  strada tramvaiului, spre S\n    {DECK_Y:.0f} -> +53, 292 m la 11,4%", f=font_t)
    label((60, Y_COAMA - 34), "C  coama +53 (parcul, casele pictate)", f=font_t)
    label((60, gr.QUAY_Y + 22), "F  cheiul de nord (+3)", f=font_t, fill=(255, 255, 255))
    label((X_G + 12, 380), f"G  spre pod: +3 -> +{DECK_Y:.0f}\n    ({ramp_len(DECK_Y - 3):.0f} m de rampa)", f=font_s)
    label((gr.X_E - 30, -60), "fosta latura de est\n(faleza) -> golf", f=font_s, fill=(230, 230, 230))
# nordul
nq = px((x1 - 40, y1 - 40))
d.line([(nq[0], nq[1] + 40), nq], fill=(0, 0, 0), width=3)
d.text((nq[0] - 5, nq[1] - 22), "N", fill=(0, 0, 0), font=font_b)
title = ("A  ramificatie de pe faleza de est (traseul aprobat neatins)" if VARIANT == "A"
         else "B  bucla reconstruita in jurul podului (latura de est dispare)")
d.text((10, 8), f"San Francisco — podul rosu carosabil, varianta {title}", fill=(0, 0, 0), font=font_t)
d.text((10, 32), "Culoarea = cota (albastru +3 .. rosu +53); gri subtire = Track25 de azi; puncte = fractii pe "
       "lungime; rosu = tablierul, portocaliu = despartitorul mobil; circulatie pe STANGA pe pod.",
       fill=(30, 30, 30), font=font_s)
# panoul cu cifre
PX0 = W - PANEL_W + 10
d.rectangle([W - PANEL_W, 0, W, H], fill=(246, 241, 226))
d.line([(W - PANEL_W, 0), (W - PANEL_W, H)], fill=(0, 0, 0), width=2)
yy = 14
d.text((PX0, yy), f"Varianta {VARIANT}, tablier {DECK:.0f} m", fill=(0, 0, 0), font=font_b)
yy += 34
for line in out[1:]:
    if line.startswith("  ") and line.strip()[:1].isdigit() and "(" in line and "cota" in line:
        continue
    words = line.split(" ")
    cur = ""
    for w_ in words:
        if len(cur) + len(w_) > 74:
            d.text((PX0, yy), cur, fill=(20, 20, 20), font=font_s)
            yy += 16
            cur = "   " + w_
        else:
            cur = (cur + " " + w_) if cur else w_
    if cur:
        d.text((PX0, yy), cur, fill=(20, 20, 20), font=font_s)
        yy += 16
    yy += 3
os.makedirs(os.path.dirname(os.path.abspath(PLAN)), exist_ok=True)
im.save(PLAN)
print("plan:", os.path.relpath(PLAN, ROOT))
