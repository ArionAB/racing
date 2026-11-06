"""Angkor -- terasa elefantilor, Regele Lepros, radacina-rampa (kit §1.4, val 2, grupul A).

  angkor/kit/elephant_terrace_module.glb   8,0 m (Y) x 4,0 m inaltime, procesiune de 3 elefanti pe +X
  angkor/kit/elephant_terrace_end.glb      capatul de nord intors (colt, trepte), 7,9 m
  angkor/kit/elephant_trunk_pillar.glb     stalp 1,6 x 1,6 x 4,0 cu cap de elefant, trompa la sol
  angkor/props/leper_king_statue.glb       statuie sezand pe soclu, un genunchi ridicat
  angkor/kit/giant_root_ramp.glb           radacina argintie-rampa, plan inclinat unic

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_terrace.py
ANK_ONLY=<module|end|pillar|statue|ramp> reface doar piesa respectiva.

DECIZIA DEZVOLTATORULUI (6 nov 2026): tot ce e sculptural e SIMPLIFICAT -- forme mari,
putin adanci, blocate. Fara portrete, fara figuri „din primitive” cu pretentii.

Axe: X latime, Y adancime / lungime, Z sus. Fata bogata a terasei pe +X; terasa se
inlantuie pe Y (capete plate la ±4,0). Rampa: capatul JOS spre −Y Blender (= +Z in
Godot), masinile vin dinspre −Y si urca spre +Y (= spre −Z in Godot).

LISTA DE ELEMENTE (scrisa INAINTE de geometrie; decuparile din angkor_assets_v1):
 MODUL (8 m): miez de gresie x −0,65..0,40, soclu in doua trepte (0..0,75), camp de panou
   neted (0,75..3,3) cu 3 elefanti in relief (siluete blocate, 0,25..0,37 m adancime),
   banda de blocuri deasupra elefantilor, pilastri de capat de 0,2 m, cornisa in trepte
   (3,3..4,0). NIMIC peste 4,0: drumul e pe coama. Capetele ±4,0 plane si identice.
 CAPAT: aceeasi fata (2 elefanti), la nord piersa colt cu cornisa si soclul intoarse pe
   fata +Y, zid de capat cu blocuri, 3 trepte la baza fetei de capat. Capatul de sud (−Y)
   are acelasi profil ca modulul (se leaga).
 STALP: soclu, fus cu blocuri, capac; pe fata +Y capul: doua boltiri pe frunte, doua
   urechi late, doua colti scurti, trompa in jos pana la sol cu varf curbat inainte.
 STATUIE: soclu in doua trepte (1,2 m), figura blocata de ~2,4 m: tors, cap cu par simplu
   (FARA coroana, FARA aureola), genunchiul drept ridicat cu mana pe el, stangul indoit la
   sol cu mana pe genunchi. NU e poza de meditatie.
 RAMPA: lat 7,4, lung 7,0 (+0,5 radacini), inalt 1,2: UN plan inclinat (17,1%) subimpartit
   in grila (AO), fara praguri. Radacinile (laterale, noduri, perdea sub buza) stau
   SUB planul de rulare, in afara lui sau dedesubt.
 Culori (kit §0): gresie ROCK_LIGHT 3 in `*_Stone`; lichen LAVA_ORANGE 30 / CACTUS_GREEN
   12 in `*_Lichen` (sub 3%); dare VOLCANIC_BLACK 20 in `*_Streak`; radacina CORAL_SAND
   19 cu AO cald in `Root_Ramp`. Fara texturi proprii, fara ROCK_DARK, fara alb.
"""

import math
import os
import bmesh
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")
ANK_ROOT = CORAL_SAND         # 19

PROUD = 0.04

# --- terasa ---------------------------------------------------------------------------
FACE_X = 0.40           # planul campului de panou
BACK_X = -0.65          # spatele zidului (plat, nu se vede)
Z_PLINTH = 0.55         # cota pe care stau elefantii
Z_CORN = 3.25           # sub cornisa
Z_TOP = 4.00            # cota drumului: NIMIC peste ea
ELE_H = 0.80            # scara elefantului (lungime ~2,15 m, crestet ~1,7 m)
ELE_W = 0.85            # factorul adancimii reliefului (max ~0,37 m)
PILASTER = 0.20
SOCLE = [(0.0, 0.30, 0.22), (0.30, Z_PLINTH, 0.10)]       # (z0, z1, iesire)
CORN = [(Z_CORN, 3.45, 0.12), (3.45, 3.72, 0.22), (3.72, Z_TOP, 0.28)]

AO_TERRACE = dict(samples=24, dist=0.6, gradient="vertical", low=0.62, high=1.0,
                  power=0.85, floor=0.30, strength=1.3, z_range=(0.0, Z_TOP))


def wall_blocks(b, fr, u0, u1, z0, z1, courses, bw, proud=PROUD, gap=0.035, seed=0):
    """Blocuri in relief pe un perete plan (ca in poarta): `fr` are originea pe fata
    peretelui, w<0 in perete, u de-a lungul fetei intre u0 si u1."""
    rnd = lcg(seed + 31)
    ch = (z1 - z0) / courses
    L = u1 - u0
    n = max(2, int(round(L / bw)))
    for c in range(courses):
        za, zb = z0 + c * ch + gap * 0.5, z0 + (c + 1) * ch - gap * 0.5
        edges = [u0 + L * i / n for i in range(n + 1)]
        if c % 2:
            edges = [u0] + [e + L / (2 * n) for e in edges[:-1]] + [u1]
        edges = [e + (rnd() - 0.5) * 0.12 * bw if 0 < i < len(edges) - 1 else e
                 for i, e in enumerate(edges)]
        for ua, ub in zip(edges[:-1], edges[1:]):
            if ub - ua < 0.1:
                continue
            ua, ub = ua + gap * 0.5, ub - gap * 0.5
            ctr = fr.p((ua + ub) * 0.5, -proud * 0.5 - 0.005, (za + zb) * 0.5)
            b.box(ctr, (ub - ua, proud + 0.01, zb - za), ANK_STONE, rotation=fr.rot)


def rbox(b, x0, x1, y0, y1, z0, z1, slot=ANK_STONE):
    b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), (x1 - x0, y1 - y0, z1 - z0), slot)


def limb(b, p0, p1, r0, r1, slot=ANK_STONE, seg=6):
    """Membru blocat: invelitoarea a doua inele de `seg` laturi (6 = fatetat) de raze
    r0/r1 in jurul axei p0-p1."""
    p0, p1 = Vector(p0), Vector(p1)
    ax = (p1 - p0).normalized()
    ref = Vector((0, 0, 1)) if abs(ax.z) < 0.9 else Vector((1, 0, 0))
    ux = ax.cross(ref).normalized()
    uy = ax.cross(ux).normalized()
    pts = []
    for p, r in ((p0, r0), (p1, r1)):
        for k in range(seg):
            a = 2.0 * math.pi * (k + 0.5) / seg
            pts.append(p + ux * (math.cos(a) * r) + uy * (math.sin(a) * r))
    hull(b, pts, slot)


def spline(pts, radii, sub=3):
    """Catmull-Rom pe puncte + raze interpolate liniar."""
    P = [Vector(p) for p in pts]
    n = len(P)
    out, rr = [], []
    for i in range(n - 1):
        p0, p1, p2, p3 = P[max(i - 1, 0)], P[i], P[i + 1], P[min(i + 2, n - 1)]
        for k in range(sub):
            t = k / float(sub)
            a = 0.5 * ((p1 * 2.0) + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t * t
                       + (p3 - p0 + (p1 - p2) * 3.0) * t * t * t)
            out.append(a)
            rr.append(radii[i] * (1 - t) + radii[i + 1] * t)
    out.append(P[-1])
    rr.append(radii[-1])
    return out, rr


# --- elefantul in relief (siluta din poarta, scalata la terasa) -------------------------
def elephant(b, fr, dirn, h=1.0, wd=1.0):
    """Siluta blocata a unui elefant in relief, in cadrul `fr` (origine pe fata peretelui,
    la talpa; u de-a lungul fetei, w in afara). `dirn` = sensul lui u in care priveste.
    Coordonate locale (s inainte, t sus, w afara); `h` scaleaza lungimea/inaltimea, `wd`
    adancimea reliefului."""
    def P(s, t, w):
        return fr.p(dirn * s * h, w * wd, t * h)

    def hl(pts):
        hull(b, [P(*q) for q in pts], ANK_STONE)

    hl([(-1.40, 1.20, 0.0), (-1.40, 1.20, 0.26), (-1.40, 2.25, 0.0), (-1.40, 2.25, 0.26),
        (0.95, 1.20, 0.0), (0.95, 1.20, 0.26), (0.95, 2.30, 0.0), (0.95, 2.30, 0.26),
        (-1.10, 2.50, 0.0), (-1.10, 2.50, 0.30), (0.55, 2.55, 0.0), (0.55, 2.55, 0.32),
        (-0.30, 2.65, 0.0), (-0.30, 2.65, 0.34),
        (-1.20, 1.80, 0.40), (0.80, 1.80, 0.40), (-0.2, 2.40, 0.40), (-0.2, 1.4, 0.38)])
    for (s0, s1, wv) in ((0.45, 0.95, 0.34), (-0.05, 0.38, 0.22), (-0.90, -0.50, 0.22), (-1.40, -0.92, 0.34)):
        hl([(s0, 0.0, 0.0), (s0, 0.0, wv), (s1, 0.0, 0.0), (s1, 0.0, wv),
            (s0, 1.30, 0.0), (s0, 1.30, wv), (s1, 1.30, 0.0), (s1, 1.30, wv)])
    hl([(0.78, 1.55, 0.0), (0.78, 2.95, 0.0), (1.70, 1.55, 0.0), (1.62, 2.65, 0.0),
        (0.90, 2.62, 0.40), (1.30, 2.95, 0.34), (1.62, 2.25, 0.30), (1.00, 1.75, 0.34),
        (0.92, 2.95, 0.30)])
    hl([(0.52, 2.15, 0.30), (0.78, 2.70, 0.30), (1.06, 2.15, 0.30), (0.78, 1.55, 0.30),
        (0.64, 2.15, 0.44), (0.78, 2.50, 0.44), (0.96, 2.15, 0.44), (0.78, 1.72, 0.44)])
    chain = [(1.64, 2.15, 0.34, 0.54), (1.82, 1.55, 0.31, 0.46), (1.95, 0.90, 0.28, 0.38),
             (2.00, 0.30, 0.25, 0.30), (2.02, 0.0, 0.22, 0.24)]
    for (sa, ta, wa, la), (sb, tb, wb, lb) in zip(chain[:-1], chain[1:]):
        hl([(sa - la * 0.5, ta, 0.0), (sa + la * 0.5, ta, 0.0), (sa - la * 0.5, ta, wa), (sa + la * 0.5, ta, wa),
            (sb - lb * 0.5, tb, 0.0), (sb + lb * 0.5, tb, 0.0), (sb - lb * 0.5, tb, wb), (sb + lb * 0.5, tb, wb)])
    hl([(1.40, 1.75, 0.28), (1.52, 1.78, 0.34), (2.02, 1.38, 0.30), (2.08, 1.32, 0.34),
        (1.40, 1.68, 0.34), (1.95, 1.30, 0.28)])
    hl([(-1.40, 2.25, 0.0), (-1.46, 2.25, 0.10), (-1.58, 1.50, 0.0), (-1.62, 1.50, 0.08),
        (-1.40, 2.15, 0.10)])


ELE_S_CENTER = (2.08 + (-1.62)) * 0.5      # centrul siluetei pe s


def face_frame(y_center):
    """Cadru pe fata +X: u spre −Y, w spre +X. Originea pe fata, y ales ca elefantul
    (care priveste spre +Y) sa fie centrat pe `y_center`."""
    return Frame((FACE_X, y_center - ELE_S_CENTER * ELE_H, 0.0), 270.0)


def terrace_wall(S, L_, y0, y1, ele_y, end_south=True, end_north=True, corner=False):
    """Zidul terasei intre y0 si y1, fata pe +X. `ele_y` = centrele elefantilor."""
    face = Frame((FACE_X, 0.0, 0.0), 270.0)           # u = −y
    # miez si socluri: miezul urca pana la cornisa
    rbox(S, BACK_X, FACE_X, y0, y1, 0.0, Z_CORN)
    for (za, zb, pr) in SOCLE:
        rbox(S, BACK_X, FACE_X + pr - PROUD, y0, y1, za, zb)
        wall_blocks(S, Frame((FACE_X + pr, 0.0, 0.0), 270.0), -y1, -y0, za, zb, 1,
                    0.95, seed=int(za * 10) + 1)
    # banda de blocuri deasupra elefantilor
    # pilastri de capat (0,2 m): la capetele de lant, plati, identici
    if end_south:
        rbox(S, FACE_X, FACE_X + 0.10, y0, y0 + PILASTER, Z_PLINTH, Z_CORN)
    if end_north:
        rbox(S, FACE_X, FACE_X + 0.10, y1 - PILASTER, y1, Z_PLINTH, Z_CORN)
    # cornisa in trepte
    for (za, zb, pr) in CORN:
        rbox(S, BACK_X, FACE_X + pr, y0, y1, za, zb)
    # elefantii
    for cy in ele_y:
        elephant(S, face_frame(cy), -1, ELE_H, ELE_W)


def lichen_streak(Ln, Sk, rnd, y0, y1, n_orange, n_green, streaks, seed=0, ledges=None):
    """Pete pe pervazurile fetei +X si dare sub cornisa."""
    spots = ["o"] * n_orange + ["g"] * n_green
    for i in range(len(spots) - 1, 0, -1):
        j = int(rnd() * (i + 1))
        spots[i], spots[j] = spots[j], spots[i]
    # pervaze: (z suprafata, x interior, x exterior, grosime) + varful cornisei (z 3,97)
    sites = [(0.30, FACE_X + 0.10, FACE_X + 0.22, 0.03),
             (Z_CORN + 0.20, FACE_X, FACE_X + 0.12, 0.03),
             (3.72, FACE_X + 0.12, FACE_X + 0.22, 0.03),
             (3.97, FACE_X + 0.04, FACE_X + 0.24, 0.04),
             (3.97, FACE_X + 0.04, FACE_X + 0.24, 0.04),
             (3.97, FACE_X + 0.04, FACE_X + 0.24, 0.04)]
    for si, kind in enumerate(spots):
        z_s, xi, xo, th = sites[int(rnd() * len(sites))]
        wid = xo - xi
        y = y0 + 0.5 + rnd() * (y1 - y0 - 1.0)
        rw = min(wid * 0.40, 0.04 + 0.05 * rnd())
        ru = min(0.30, rw * (1.8 + 1.6 * rnd()))
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        if kind == "g":
            ru, rw = ru * 1.1, rw * 1.05
        if z_s > 3.9:      # varful cornisei: pete mai late, putin proeminente
            rw = min((xo - xi) * 0.45, 0.07 + 0.08 * rnd())
            ru = rw * (1.6 + 1.6 * rnd())
        lichen_spot(Ln, ((xi + xo) * 0.5, y, z_s), rw, ru, th, slot, yaw_deg=0.0, seed=seed + si)
    # dare: sub prima treapta a cornisei si pe banda de blocuri
    for _ in range(streaks):
        y = y0 + 0.4 + rnd() * (y1 - y0 - 0.8)
        ln = 0.20 + 0.15 * rnd()
        streak(Sk, (FACE_X + PROUD, y, Z_CORN - 0.02), 270.0, 0.10 + 0.04 * rnd(), ln, 0.025, ANK_STREAK)


# --- piesa 1: modulul --------------------------------------------------------------------
def build_module():
    S, Ln, Sk = Builder(), Builder(), Builder()
    rnd = lcg(61)
    terrace_wall(S, 8.0, -4.0, 4.0, (-1.95, 1.95))
    lichen_streak(Ln, Sk, rnd, -4.0, 4.0, 14, 8, 4, seed=100)
    return [S.to_object("Terrace_Stone"), Ln.to_object("Terrace_Lichen"), Sk.to_object("Terrace_Streak")]


# --- piesa 2: capatul de nord ----------------------------------------------------------
END_Y0, END_Y1 = -4.0, 3.3


def build_end():
    S, Ln, Sk = Builder(), Builder(), Builder()
    rnd = lcg(67)
    y0, y1 = END_Y0, END_Y1
    # fata: ca modulul, dar capatul nordic nu are pilastru plat: are piersa colt
    terrace_wall(S, 7.0, y0, y1, (-2.2, 1.0), end_south=True, end_north=False)
    # piersa de colt: soclul si cornisa se INTORC pe fata +Y (capatul de nord); zidul de
    # capat (+Y) cu blocuri; coltul cu un pilastru in L
    for (za, zb, pr) in SOCLE:
        rbox(S, BACK_X, FACE_X + pr - PROUD, y1, y1 + pr - PROUD, za, zb)
        wall_blocks(S, Frame((0.0, y1 + pr, 0.0), 0.0), BACK_X, FACE_X + pr, za, zb, 1, 0.95,
                    seed=int(za * 10) + 11)
    for (za, zb, pr) in CORN:
        rbox(S, BACK_X, FACE_X + pr, y1, y1 + pr, za, zb)
    rbox(S, BACK_X, FACE_X, y1, y1 + 0.001 + 0.0, Z_PLINTH, Z_CORN)    # fata de capat (plan)
    # pilastrul de colt in L (iese 0,10 pe +X si pe +Y)
    rbox(S, FACE_X, FACE_X + 0.10, y1 - 0.40, y1 + 0.10, Z_PLINTH, Z_CORN)
    rbox(S, BACK_X, FACE_X + 0.10, y1, y1 + 0.10, Z_PLINTH, Z_CORN)
    # peretele de capat: blocuri
    wall_blocks(S, Frame((0.0, y1 + 0.10, 0.0), 0.0), BACK_X, FACE_X + 0.10, Z_PLINTH, Z_CORN, 3, 0.85, seed=21)
    # trepte laterale: 3 trepte la baza fetei de capat, pe latimea zidului
    for i in range(3):
        d = 0.18 * (3 - i)
        zt = 0.40 * (i + 1)
        rbox(S, BACK_X + 0.15, FACE_X - 0.05, y1 + 0.10, y1 + 0.10 + d, 0.0, zt)
    # fiecare treapta: blocuri pe fata ei
    for i in range(3):
        d = 0.18 * (3 - i)
        zt = 0.40 * (i + 1)
        wall_blocks(S, Frame((0.0, y1 + 0.10 + d, 0.0), 0.0), BACK_X + 0.15, FACE_X - 0.05,
                    max(0.0, zt - 0.40), zt, 1, 0.8, seed=31 + i)
    lichen_streak(Ln, Sk, rnd, y0, y1, 12, 7, 4, seed=200)
    return [S.to_object("Terrace_Stone"), Ln.to_object("Terrace_Lichen"), Sk.to_object("Terrace_Streak")]


# --- piesa 3: stalpul cu cap de elefant -------------------------------------------------
PIL_X = 0.80            # jumatate de latime
PIL_YB, PIL_YF = -0.80, 0.50       # spatele si fata miezului; relieful iese pana la 0,80


def build_pillar():
    S, Ln, Sk = Builder(), Builder(), Builder()
    rnd = lcg(71)
    # soclu, fus, capac
    rbox(S, -PIL_X + PROUD, PIL_X - PROUD, PIL_YB + PROUD, PIL_YF, 0.0, 0.30)
    rbox(S, -0.72 + PROUD, 0.72 - PROUD, -0.72 + PROUD, PIL_YF, 0.30, 3.55)
    # socluri cu blocuri pe 3 laturi (spate, stanga, dreapta) si pe fata
    for (fx, fy, yaw, half_u, z0, z1, courses, seed) in (
            (0.0, PIL_YF, 0.0, PIL_X, 0.0, 0.30, 1, 1),
            (PIL_X, (PIL_YB + PIL_YF) * 0.5, 270.0, (PIL_YF - PIL_YB) * 0.5, 0.0, 0.30, 1, 2),
            (-PIL_X, (PIL_YB + PIL_YF) * 0.5, 90.0, (PIL_YF - PIL_YB) * 0.5, 0.0, 0.30, 1, 3),
            (0.0, PIL_YB, 180.0, PIL_X, 0.0, 0.30, 1, 4)):
        wall_blocks(S, Frame((fx, fy, 0.0), yaw), -half_u, half_u, z0, z1, courses, 0.8, seed=seed)
    # fusul: blocuri pe laterale si spate; pe fata, doar deasupra si dedesubt de cap (aici
    # capul ocupa fata, deci blocuri la marginile fusului)
    for (fx, fy, yaw, half_u, seed) in (
            (0.72, (-0.72 + PIL_YF) * 0.5, 270.0, (PIL_YF + 0.72) * 0.5, 5),
            (-0.72, (-0.72 + PIL_YF) * 0.5, 90.0, (PIL_YF + 0.72) * 0.5, 6),
            (0.0, -0.72, 180.0, 0.72, 7)):
        wall_blocks(S, Frame((fx, fy, 0.0), yaw), -half_u, half_u, 0.30, 3.55, 5, 0.75, seed=seed)
    wall_blocks(S, Frame((0.0, PIL_YF, 0.0), 0.0), -0.72, 0.72, 3.10, 3.55, 1, 0.8, seed=8)
    # capac in doua trepte
    rbox(S, -PIL_X, PIL_X, PIL_YB, PIL_YF + 0.08, 3.55, 3.78)
    rbox(S, -PIL_X + 0.04, PIL_X - 0.04, PIL_YB + 0.04, PIL_YF + 0.04, 3.78, 4.0)

    # --- capul de elefant pe fata +Y (u = x, w = +Y), relief maxim 0,30 m ---------------
    fr = Frame((0.0, PIL_YF, 0.0), 0.0)

    def hl(pts):
        hull(S, [fr.p(u, w, z) for (u, z, w) in pts], ANK_STONE)

    # craniu: bloc fatetat, mai lat jos, cu doua bolti pe frunte
    hl([(sg * 0.40, 1.15, 0.0) for sg in (-1, 1)] + [(sg * 0.47, 2.7, 0.0) for sg in (-1, 1)]
       + [(sg * 0.32, 3.30, 0.0) for sg in (-1, 1)]
       + [(sg * 0.28, 1.35, 0.20) for sg in (-1, 1)] + [(sg * 0.36, 2.6, 0.22) for sg in (-1, 1)]
       + [(sg * 0.24, 3.15, 0.18) for sg in (-1, 1)])
    for sg in (-1, 1):
        hl([(sg * 0.02, 2.80, 0.18), (sg * 0.30, 2.80, 0.18), (sg * 0.02, 3.28, 0.15), (sg * 0.28, 3.25, 0.15),
            (sg * 0.06, 2.88, 0.30), (sg * 0.26, 2.88, 0.30), (sg * 0.08, 3.20, 0.27), (sg * 0.24, 3.18, 0.27)])
    # sprancene: doua pene mici deasupra ochilor
    for sg in (-1, 1):
        hl([(sg * 0.12, 2.62, 0.20), (sg * 0.34, 2.60, 0.20), (sg * 0.12, 2.72, 0.27), (sg * 0.34, 2.70, 0.27),
            (sg * 0.12, 2.62, 0.27), (sg * 0.34, 2.60, 0.27)])
    # ochi: doua boabe mici
    for sg in (-1, 1):
        hl([(sg * 0.20, 2.50, 0.20), (sg * 0.30, 2.50, 0.20), (sg * 0.20, 2.40, 0.20), (sg * 0.30, 2.40, 0.20),
            (sg * 0.25, 2.47, 0.27), (sg * 0.25, 2.43, 0.27)])
    # urechi: doua evantaie late, subtiri
    for sg in (-1, 1):
        hl([(sg * 0.44, 3.10, 0.0), (sg * 0.72, 2.90, 0.0), (sg * 0.72, 2.15, 0.0), (sg * 0.62, 1.65, 0.0),
            (sg * 0.44, 2.00, 0.0),
            (sg * 0.44, 3.10, 0.21), (sg * 0.70, 2.90, 0.21), (sg * 0.70, 2.17, 0.21), (sg * 0.61, 1.68, 0.21),
            (sg * 0.45, 2.00, 0.21)])
    # trompa: lant de segmente de la radacina nasului pana la sol; varful curbat inainte
    chain = [(2.45, 0.46, 0.24), (2.05, 0.42, 0.27), (1.55, 0.38, 0.29), (1.05, 0.34, 0.30),
             (0.55, 0.31, 0.30), (0.12, 0.28, 0.30)]
    for (za, wa, pa), (zb, wb, pb) in zip(chain[:-1], chain[1:]):
        hl([(-wa * 0.5, za, 0.0), (wa * 0.5, za, 0.0), (-wa * 0.5, za, pa), (wa * 0.5, za, pa),
            (-wb * 0.5, zb, 0.0), (wb * 0.5, zb, 0.0), (-wb * 0.5, zb, pb), (wb * 0.5, zb, pb)])
    hl([(-0.13, 0.20, 0.10), (0.13, 0.20, 0.10), (-0.12, 0.0, 0.10), (0.12, 0.0, 0.10),
        (-0.12, 0.0, 0.30), (0.12, 0.0, 0.30), (-0.13, 0.20, 0.30), (0.13, 0.20, 0.30)])
    # colti scurti, de o parte si de alta a trompei
    for sg in (-1, 1):
        hl([(sg * 0.24, 2.02, 0.14), (sg * 0.32, 2.02, 0.14), (sg * 0.30, 1.35, 0.22), (sg * 0.38, 1.40, 0.18),
            (sg * 0.24, 2.02, 0.22), (sg * 0.30, 2.02, 0.20)])

    # lichen pe pervazele capacului si ale soclului, dare sub capac
    spots = [("o", 0.30, 0.0), ("g", 3.78, 0.5), ("o", 3.78, 1.0), ("g", 0.30, 1.5), ("o", 3.99, 2.0),
             ("g", 3.99, 2.5), ("o", 3.55, 3.0), ("g", 3.55, 3.5)]
    for si, (kind, zs, _) in enumerate(spots):
        side = int(rnd() * 4)
        f2 = Frame((0.0, 0.0, 0.0), 90.0 * side)
        wo = (PIL_X if side % 2 == 0 else PIL_X)   # ledge: ~0,05..0,08 m sub marginea de sus
        if zs == 0.30:
            inner, outer = 0.72 - PROUD, PIL_X - PROUD
        elif zs == 3.55:
            inner, outer = 0.72 - PROUD, PIL_X
        elif zs == 3.78:
            inner, outer = PIL_X - 0.04, PIL_X
        else:
            inner, outer = 0.0, 0.70
        rw = min((outer - inner) * 0.40, 0.04 + 0.04 * rnd())
        if zs > 3.9:
            rw = 0.07 + 0.05 * rnd()
        ru = rw * (1.6 + 1.4 * rnd())
        u = (rnd() * 2 - 1) * 0.5
        pt = f2.p(u, (inner + outer) * 0.5, zs)
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        lichen_spot(Ln, (pt.x, pt.y, pt.z), ru, rw, 0.03, slot, yaw_deg=90.0 * side, seed=300 + si)
    for k in range(5):
        side = (0, 1, 2, 3, 1)[k]
        f2 = Frame((0.0, 0.0, 0.0), 90.0 * side)
        u = (rnd() * 2 - 1) * 0.45
        p = f2.p(u, 0.72 + 0.0, 0.0)
        streak(Sk, (p.x, p.y, 3.53), 90.0 * side, 0.10 + 0.04 * rnd(), 0.20 + 0.12 * rnd(), 0.025, ANK_STREAK)
    return [S.to_object("Pillar_Stone"), Ln.to_object("Pillar_Lichen"), Sk.to_object("Pillar_Streak")]


# --- piesa 4: Regele Lepros ------------------------------------------------------------
PED_H = 1.2
AO_STATUE = dict(samples=24, dist=0.5, gradient="vertical", low=0.60, high=1.0,
                 power=0.85, floor=0.30, strength=1.3, z_range=(0.0, 3.7))


def build_statue():
    S, Ln, Sk = Builder(), Builder(), Builder()
    rnd = lcg(83)
    # soclul: doua trepte (0..0,5 / 0,5..1,2), blocuri in relief
    stepped_base(S, [(0.0, 0.50, 1.15), (0.50, PED_H, 0.95)], proud=0.04, block_w=0.9)
    z0 = PED_H

    def Z(z):
        return z0 + z

    def V(x, y, z):
        return (x, y, z0 + z)

    # bazinul: pânza pe care sta figura (acopera sezutul)
    hull(S, [V(sx * 0.46, sy * 0.34, zz) for sx in (-1, 1) for sy in (-1, 1) for zz in (0.0, 0.42)], ANK_STONE)
    # picioare: dreptul ridicat (genunchi sus), stangul indoit la sol
    limb(S, V(0.30, 0.0, 0.26), V(0.36, 0.70, 1.02), 0.30, 0.24)             # coapsa
    limb(S, V(0.36, 0.72, 1.00), V(0.36, 0.84, 0.22), 0.23, 0.16)            # pulpa
    hull(S, [V(0.36 + sx * 0.13, y, zz) for sx in (-1, 1) for (y, zz) in ((0.70, 0.0), (0.70, 0.17), (1.04, 0.0), (1.04, 0.10))], ANK_STONE)
    limb(S, V(-0.30, 0.0, 0.24), V(-0.90, 0.46, 0.24), 0.27, 0.23)           # coapsa stanga
    limb(S, V(-0.90, 0.46, 0.24), V(-0.52, 0.18, 0.18), 0.22, 0.17)          # pulpa stanga, peste
    
    # trunchi: de la solduri la umeri, usor tras inapoi
    hull(S, [V(sx * 0.40, sy, 0.38) for sx in (-1, 1) for sy in (-0.28, 0.28)]
         + [V(sx * 0.50, sy, 1.00) for sx in (-1, 1) for sy in (-0.30, 0.30)]
         + [V(sx * 0.58, sy, 1.52) for sx in (-1, 1) for sy in (-0.24, 0.24)]
         + [V(sx * 0.20, sy, 1.68) for sx in (-1, 1) for sy in (-0.16, 0.16)], ANK_STONE)
    # centura si fusta de fata
    hull(S, [V(sx * 0.43, sy, zz) for sx in (-1, 1) for sy in (-0.30, 0.34) for zz in (0.36, 0.50)], ANK_STONE)
    hull(S, [V(sx * 0.15, 0.30, 0.52) for sx in (-1, 1)] + [V(sx * 0.17, 0.40, 0.46) for sx in (-1, 1)]
         + [V(sx * 0.14, 0.34, 0.02) for sx in (-1, 1)] + [V(sx * 0.12, 0.42, 0.02) for sx in (-1, 1)], ANK_STONE)
    # brate: dreptul peste genunchiul ridicat, stangul pe genunchiul indoit
    limb(S, V(0.58, 0.0, 1.46), V(0.72, 0.30, 1.04), 0.20, 0.17)
    limb(S, V(0.72, 0.30, 1.04), V(0.42, 0.64, 1.24), 0.17, 0.14)
    hull(S, [V(0.40 + sx * 0.13, 0.64 + sy, 1.19 + sz) for sx in (-1, 1) for sy in (-0.12, 0.16) for sz in (-0.03, 0.08)], ANK_STONE)
    limb(S, V(-0.58, 0.0, 1.46), V(-0.68, 0.12, 0.88), 0.20, 0.17)
    limb(S, V(-0.68, 0.12, 0.88), V(-0.90, 0.46, 0.50), 0.17, 0.14)
    hull(S, [V(-0.90 + sx * 0.12, 0.46 + sy, 0.44 + sz) for sx in (-1, 1) for sy in (-0.12, 0.16) for sz in (-0.03, 0.08)], ANK_STONE)
    # gat si cap: fata mica, blocata, par simplu (calota), urechi
    hull(S, [V(sx * 0.17, sy, zz) for sx in (-1, 1) for sy in (-0.14, 0.14) for zz in (1.60, 1.84)], ANK_STONE)
    hull(S, [V(sx * 0.19, 0.04, 1.84) for sx in (-1, 1)] + [V(sx * 0.24, -0.10, 2.0) for sx in (-1, 1)]
         + [V(sx * 0.26, 0.10, 2.06) for sx in (-1, 1)] + [V(sx * 0.22, 0.18, 2.12) for sx in (-1, 1)]
         + [V(sx * 0.17, 0.20, 1.86) for sx in (-1, 1)] + [V(sx * 0.17, -0.18, 2.22) for sx in (-1, 1)]
         + [V(sx * 0.19, 0.18, 2.26) for sx in (-1, 1)], ANK_STONE)
    # parul: calota care acopera craniul, linia frunte la ~2,22
    hull(S, [V(sx * 0.255, sy, zz) for sx in (-1, 1) for (sy, zz) in ((-0.20, 2.04), (0.10, 2.20), (0.19, 2.26), (-0.20, 2.30))]
         + [V(sx * 0.19, sy, zz) for sx in (-1, 1) for (sy, zz) in ((-0.17, 2.46), (0.14, 2.44))], ANK_STONE)
    # trasaturi mici si largi: spranceana, nas, gura, urechi
    hull(S, [V(sx * 0.18, 0.205, zz) for sx in (-1, 1) for zz in (2.15, 2.21)]
         + [V(sx * 0.18, 0.24, zz) for sx in (-1, 1) for zz in (2.15, 2.19)], ANK_STONE)
    hull(S, [V(sx * 0.035, 0.20, 2.14) for sx in (-1, 1)] + [V(sx * 0.05, 0.20, 1.98) for sx in (-1, 1)]
         + [V(0.0, 0.27, 1.99)], ANK_STONE)
    hull(S, [V(sx * 0.085, 0.20, zz) for sx in (-1, 1) for zz in (1.90, 1.94)]
         + [V(sx * 0.085, 0.225, zz) for sx in (-1, 1) for zz in (1.90, 1.93)], ANK_STONE)
    for sx in (-1, 1):
        hull(S, [V(sx * 0.255, 0.0, 2.12), V(sx * 0.31, 0.0, 2.04), V(sx * 0.31, 0.0, 1.84), V(sx * 0.255, 0.03, 1.80),
                 V(sx * 0.255, -0.06, 2.12), V(sx * 0.31, -0.06, 2.04), V(sx * 0.31, -0.06, 1.84)], ANK_STONE)

    # lichen pe treptele soclului si dare pe soclu / piept
    top_ledges = [(0.50, 0.95, 1.15), (PED_H, 0.0, 0.95)]
    for si in range(10):
        kind = "o" if si % 3 else "g"
        z_s, inner, outer = top_ledges[si % 2]
        side = int(rnd() * 4)
        f2 = Frame((0.0, 0.0, 0.0), 90.0 * side)
        if z_s == 0.50:
            wc = (0.95 + 1.15) * 0.5
            rw, ru = min(0.07, 0.04 + 0.04 * rnd()), 0.10 + 0.12 * rnd()
            u = (rnd() * 2 - 1) * 0.9
        else:
            wc = 0.82
            rw, ru = 0.05 + 0.05 * rnd(), 0.10 + 0.12 * rnd()
            u = (rnd() * 2 - 1) * 0.7
        pt = f2.p(u, wc, z_s)
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        lichen_spot(Ln, (pt.x, pt.y, pt.z), ru, rw, 0.03, slot, yaw_deg=90.0 * side, seed=400 + si)
    for k in range(4):
        side = k % 4
        f2 = Frame((0.0, 0.0, 0.0), 90.0 * side)
        u = (rnd() * 2 - 1) * 0.7
        p = f2.p(u, 0.95 + 0.001, 0.0)
        streak(Sk, (p.x, p.y, PED_H - 0.02), 90.0 * side, 0.11 + 0.04 * rnd(), 0.25 + 0.15 * rnd(), 0.025, ANK_STREAK)
    return [S.to_object("Statue_Stone"), Ln.to_object("Statue_Lichen"), Sk.to_object("Statue_Streak")]


# --- piesa 5: radacina-rampa -------------------------------------------------------------
RAMP_HW = 3.7           # jumatate din latimea planului de rulare (7,4 m)
RAMP_Y0, RAMP_Y1 = -3.5, 3.5
RAMP_H = 1.2
AO_RAMP = dict(samples=24, dist=0.9, gradient="vertical", low=0.55, high=1.0,
               power=0.9, floor=0.26, strength=1.3, z_range=(0.0, RAMP_H))


def ramp_z(y):
    return RAMP_H * (y - RAMP_Y0) / (RAMP_Y1 - RAMP_Y0)


def build_ramp():
    R = Builder()
    # corpul: pana intre planul de rulare si sol; marginile de jos mai inguste (rădăcina
    # se strange sub planul de rulare). Planul de sus: 4 colturi -> subimpartit in grila.
    top = [(sx * RAMP_HW, y, ramp_z(y)) for sx in (-1, 1) for y in (RAMP_Y0, RAMP_Y1)]
    bot = [(sx * RAMP_HW, y, 0.0) for sx in (-1, 1) for y in (RAMP_Y0 + 0.001, RAMP_Y1)]
    hull(R, top + bot, ANK_ROOT)
    bm = R.bm
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bmesh.ops.dissolve_limit(bm, angle_limit=0.0005, verts=bm.verts[:], edges=bm.edges[:])
    big = max((f for f in bm.faces if f.normal.z > 0.5), key=lambda f: f.calc_area())
    bmesh.ops.subdivide_edges(bm, edges=list(big.edges), cuts=13, use_grid_fill=True)

    def lift(pts, rr, sub=3, k=1.35):
        pp, r2 = spline(pts, [r * k if r > 0.05 else r for r in rr], sub=sub)
        R.taper_sweep([tuple(p) for p in pp], r2, ANK_ROOT, segments=8)

    rnd = lcg(97)
    for sx in (-1, 1):
        # contraforturi pe flanc: tuburi ingropate pe jumatate in peretele lateral, sub planul
        # de rulare, care se desfac spre sol (nu stau pe plan)
        lift([(sx * 3.60, 3.30, 0.70), (sx * 3.85, 2.00, 0.58), (sx * 3.95, 0.60, 0.45),
              (sx * 4.10, -1.00, 0.28), (sx * 4.40, -2.40, 0.10)],
             [0.38, 0.38, 0.34, 0.26, 0.02])
        lift([(sx * 3.40, 3.10, 0.50), (sx * 4.20, 3.20, 0.40), (sx * 4.90, 2.60, 0.22), (sx * 5.30, 1.90, 0.02)],
             [0.46, 0.40, 0.28, 0.02])
        lift([(sx * 3.50, 1.60, 0.40), (sx * 4.30, 1.30, 0.28), (sx * 4.80, 0.30, 0.14), (sx * 5.00, -0.50, 0.02)],
             [0.34, 0.30, 0.20, 0.02])
        lift([(sx * 3.55, 2.60, 0.34), (sx * 4.40, 2.20, 0.30), (sx * 5.10, 1.00, 0.16), (sx * 5.40, -0.20, 0.02)],
             [0.30, 0.28, 0.18, 0.02])
        lift([(sx * 3.60, -0.40, 0.18), (sx * 4.20, -1.60, 0.14), (sx * 4.50, -2.70, 0.08), (sx * 4.60, -3.40, 0.02)],
             [0.20, 0.17, 0.10, 0.02], k=1.0)
        for (ky, kr) in ((2.6, 0.38), (0.2, 0.32), (-1.8, 0.22)):
            kz = max(kr * 0.9, ramp_z(ky) - kr - 0.12)
            ellipsoid(R, (sx * (3.75 + kr * 0.45), ky, kz), (kr * 1.05, kr * 1.35, kr * 0.9), ANK_ROOT,
                      Matrix.Identity(3), seg=8, rings=5)
    # perdeaua de sub buza: radacini dese pe fata inalta, in contact, pana la sol
    for i, xk in enumerate((-3.2, -2.2, -1.1, 0.0, 1.1, 2.2, 3.2)):
        w = (rnd() - 0.5) * 0.3
        lift([(xk, 3.40, 0.92), (xk + w, 3.60, 0.60), (xk + w * 1.5, 3.88, 0.24), (xk + w * 2.0, 4.05, 0.02)],
             [0.26, 0.26, 0.18, 0.02], k=1.0)
    # radacinile care intra in sol: nimic sub z = 0 (originea la baza ramane planul solului)
    for v in bm.verts:
        v.co.z = max(v.co.z, 0.0)
    # toata fata pe slotul radacinii
    for f in bm.faces:
        f[R.slot] = ANK_ROOT
    return [R.to_object("Root_Ramp")]


# --- emitere -----------------------------------------------------------------------------
def emit(only):
    kw = dict(bevel=0.0, bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0)
    if only == "module":
        emit_angkor(build_module(), "kit/elephant_terrace_module.glb", AO_TERRACE, **kw)
    elif only == "end":
        emit_angkor(build_end(), "kit/elephant_terrace_end.glb", AO_TERRACE, **kw)
    elif only == "pillar":
        emit_angkor(build_pillar(), "kit/elephant_trunk_pillar.glb",
                    dict(AO_TERRACE, z_range=(0.0, 4.0)), **kw)
    elif only == "statue":
        emit_angkor(build_statue(), "props/leper_king_statue.glb", AO_STATUE, **kw)
    elif only == "ramp":
        emit_angkor(build_ramp(), "kit/giant_root_ramp.glb", AO_RAMP, bevel=0.0, smooth_angle=60.0,
                    anchor=(0.0, 0.0), ao_tint={"Root_Ramp": (0.85, 1.25, 1.75)})
    clear_built()


for _o in ("module", "end", "pillar", "statue", "ramp"):
    if not ONLY or ONLY == _o:
        emit(_o)
report_angkor()
