"""Transfagarasan -- FUNDALUL (kit docs/asset_briefs/transfagarasan_kit.md §1.8, val 3, tf-g).

  transfagarasan/effects/transfagarasan_horizon.glb   6 noduri, copii directi ai radacinii:
    FagarasRidge_A  creasta-perete cu 13 dinti, 230 m, dintele dominant Negoiu (+17%)
    FagarasRidge_B  creasta-perete cu 12 dinti, 190 m
    FagarasRidge_C  creasta-perete cu 12 dinti, 165 m
    CloudSea_A      marea de nori, 280 m
    CloudSea_B      marea de nori, 220 m
    FagarasPlain_A  Tara Fagarasului: 300 x 120 m de campuri si palcuri

Consumatorul e `Track._build_horizon` (scenes/tracks/track.gd): ia nodurile DUPA NUME
(`horizon_picks`), le aseaza pe inele la 200-340 m, le SCALEAZA si le da un YAW ALEATOR, deci
fiecare nod e un VOLUM INCHIS, lizibil din ORICE azimut, cu originea la BAZA (XY centrat pe
bbox, Z min = 0 -- `_build_horizon` pune nodul la `ground_y - 4`).

CE VEDE JUCATORUL (memoriile `verifica-cu-parametrii-lui`, `munte-flanc-nu-fundal`): camera de
joc sta la 10 m, priveste in jos ~29 grade (tinta la 5 m in fata, 0,4 m sus) cu fov vertical
68, deci marginea de SUS a cadrului e la doar +5,3 grade peste orizont: la 300 m, ~38 m peste
cota drumului. Creasta se citeste din banda de jos si de la mijloc: poalele verzi, flancurile
de sist, SAUA dintre varfuri, caldarile cu zapada. Reluare tf-g2: creasta e un PERETE CONTINUU cu 12-13 dinti (sei de doar 16-24%), coaste oblice,
caldari cu zapada si limbi verzi (nu ace izolate); norii sunt GRAMEZI de cumulus inalte (nu
pietricele pe o placa). Dintii de 25-35 m deasupra bazei se citesc in banda pe care o vede camera.

Sloturi (kit §0, tabelul "fundalul"): MARBLE_GREY 29 (sistul) + FOAM_WHITE 22 (zapada) +
TROPICAL_GREEN 21 / CACTUS_GREEN 12 (poalele) pe creasta; FOAM_WHITE pe nori; TROPICAL_GREEN,
CACTUS_GREEN, DRY_VEGETATION 13 pe campie. Zero sloturi noi. Umbrire PLATA (`flat_ao`: fiecare
fateta isi are propriul AO, ca facetele sa se citeasca drept plane la 300 m).
Fara coliziune; `cast_shadow` OFF o face consumatorul.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_horizon.py
"""

import math
from mathutils import Vector

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

ROCK = MARBLE_GREY           # 29: sistul (flancurile)
SNOW = FOAM_WHITE            # 22: zapada din caldari, creasta, norii
GRASS = TROPICAL_GREEN       # 21: poalele, campurile, palcurile
GRASS2 = CACTUS_GREEN        # 12: al doilea verde (olive, mai cald)
DRY = DRY_VEGETATION         # 13: campul galben-uscat

AO_RIDGE = dict(samples=12, dist=40.0, gradient="vertical", low=0.52, high=1.0,
                power=0.85, floor=0.22)
AO_CLOUD = dict(samples=12, dist=14.0, gradient="vertical", low=0.58, high=1.0,
                power=0.9, floor=0.40)
AO_PLAIN = dict(samples=8, dist=10.0, gradient="vertical", low=0.80, high=1.0,
                power=1.0, floor=0.55)


def _h01(a, b, seed):
    h = math.sin(a * 12.9898 + b * 78.233 + seed * 4.1) * 43758.5453
    return h - math.floor(h)


def _vn(a, b, seed):
    """Zgomot de valoare neted, in [-1, 1]."""
    return (math.sin(a * 1.7 + seed) * 0.5 + math.sin(b * 2.3 - seed * 1.3) * 0.3
            + math.sin((a + b) * 3.1 + seed * 2.1) * 0.2)


def _sm(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def settle(b, name):
    """Muta corpul: bbox centrat pe XY, baza la z=0 (originea nodului la baza)."""
    vs = b.bm.verts
    xs = [v.co.x for v in vs]; ys = [v.co.y for v in vs]; zs = [v.co.z for v in vs]
    d = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
    for v in vs:
        v.co += d
    return b.to_object(name)


# ---------------------------------------------------------------------------
# harta de inaltimi pe o grila patrata mapata pe elipsa -> corp INCHIS
# ---------------------------------------------------------------------------

SQ = 0.16   # 0,5 = elipsa; mai mic = contur mai drept (masa umple lungimea)


def _heightfield_solid(b, nu, nv, L, W, height_fn, jitter, seed, tone_of=None):
    """Grila (nu x nv) pe patratul [-1,1]^2, mapata pe elipsa L x W
    (x = L/2 u sqrt(1-v^2/2), y = W/2 v sqrt(1-u^2/2)); muchia patratului = conturul
    elipsei, ramane la z=0. Suprafata de sus din triunghiuri (diagonala urmareste
    creasta), baza = evantai din centru la z=0 -> volum inchis. Intoarce fetele de sus.
    `height_fn(x, y, rho)` -> cota; `rho` = raza eliptica normalizata (1 la contur)."""
    cell_x = L / float(nu)
    cell_y = W / float(nv)
    grid = {}
    for i in range(nu + 1):
        for j in range(nv + 1):
            u = -1.0 + 2.0 * i / nu
            v = -1.0 + 2.0 * j / nv
            border = i in (0, nu) or j in (0, nv)
            x = L * 0.5 * u * math.sqrt(max(0.0, 1.0 - v * v * SQ))
            y = W * 0.5 * v * math.sqrt(max(0.0, 1.0 - u * u * SQ))
            if not border:
                x += (_h01(i, j, seed) - 0.5) * 2.0 * jitter * cell_x
                y += (_h01(j, i, seed + 7) - 0.5) * 2.0 * jitter * cell_y
                rho = math.sqrt((x / (L * 0.5)) ** 2 + (y / (W * 0.5)) ** 2)
                z = height_fn(x, y, rho) if rho < 1.0 else 0.0
            else:
                z = 0.0
            grid[(i, j)] = b.bm.verts.new((x, y, max(0.0, z)))
    faces = []

    def tri(a, c, d):
        f = b.bm.faces.new([a, c, d])
        f[b.slot] = ROCK
        faces.append(f)

    for i in range(nu):
        for j in range(nv):
            p00, p10 = grid[(i, j)], grid[(i + 1, j)]
            p11, p01 = grid[(i + 1, j + 1)], grid[(i, j + 1)]
            # diagonala dintre cele doua colturi mai inalte (urmareste creasta)
            if p00.co.z + p11.co.z >= p10.co.z + p01.co.z:
                tri(p00, p10, p11)
                tri(p00, p11, p01)
            else:
                tri(p00, p10, p01)
                tri(p10, p11, p01)
    # baza: evantai din centru, peste conturul patratului (in ordine)
    loop = [grid[(i, 0)] for i in range(nu)] + [grid[(nu, j)] for j in range(nv)] \
        + [grid[(i, nv)] for i in range(nu, 0, -1)] + [grid[(0, j)] for j in range(nv, 0, -1)]
    c = b.bm.verts.new((0.0, 0.0, 0.0))
    for k in range(len(loop)):
        f = b.bm.faces.new([loop[k], loop[(k + 1) % len(loop)], c])
        f[b.slot] = ROCK
    return faces


# ---------------------------------------------------------------------------
# CREASTA (reluare tf-g2: perete continuu cu dinti, nu ace izolate)
# ---------------------------------------------------------------------------

# Anvelopa crestei, EXTRASA din decuparea `fagaras_ridge.png` (silueta de sus pe 200 de
# coloane, 0-100, max = 100; coloanele 11..588 din 602). E o CURBA LENTA (clopot: ~55% la
# capete, 100% la mijloc); dintii o modeaza in `_crest_knots`. Silueta bruta a decuparii are
# doar ~7 crestaturi (dintii din spate se suprapun peste cei din fata, vedere de sus ~25
# grade): numarul de dinti (12-15) vine din verdictul coordonatorului, nu din aceasta curba.
ENV = [12, 44, 49, 53, 53, 55, 56, 57, 57, 58, 60, 63, 64, 66, 69, 69, 70, 70, 70, 68, 67, 69,
       71, 72, 73, 75, 76, 78, 80, 80, 80, 79, 79, 76, 74, 74, 73, 74, 76, 78, 79, 80, 79, 79,
       79, 80, 82, 83, 86, 88, 89, 89, 89, 88, 88, 88, 86, 84, 84, 88, 88, 90, 91, 91, 91, 89,
       89, 88, 87, 85, 83, 82, 81, 81, 82, 83, 84, 84, 84, 82, 80, 78, 77, 77, 76, 74, 75, 76,
       78, 78, 76, 76, 77, 78, 79, 80, 84, 86, 86, 84, 84, 84, 84, 86, 87, 90, 91, 93, 95, 96,
       97, 95, 94, 94, 94, 93, 93, 93, 91, 91, 91, 90, 92, 93, 93, 92, 94, 94, 96, 97, 98, 99,
       100, 99, 98, 96, 95, 94, 92, 91, 91, 91, 89, 88, 87, 85, 84, 83, 83, 79, 77, 79, 80, 80,
       81, 79, 78, 76, 74, 74, 74, 74, 73, 71, 73, 74, 75, 77, 77, 78, 76, 74, 73, 71, 70, 68,
       66, 67, 68, 68, 67, 64, 64, 64, 64, 61, 60, 57, 57, 58, 58, 60, 60, 61, 60, 58, 57, 54,
       54, 54]
ENV_FLAT = 0.40      # env' = 0,40 + 0,60 * env: pe decupare clopotul e umflat de perspectiva
                     # (vedere de sus); verdictul cere perete aproape la aceeasi cota

RIDGE_SIL = {}


def _env_fn(lo, hi, mirror):
    n = len(ENV) - 1

    def f(xn):
        if mirror:
            xn = 1.0 - xn
        p = max(0.0, min(1.0, lo + (hi - lo) * xn)) * n
        i = max(0, min(n - 1, int(p)))
        fr = p - i
        return ENV_FLAT + (1.0 - ENV_FLAT) * (ENV[i] * (1.0 - fr) + ENV[i + 1] * fr) / 100.0
    return f


def _crest_knots(L, n, seed, nego_frac=None):
    """Profilul DINTILOR ca linie franta: noduri (x, K, w). `K` = factorul de inaltime (dinte
    ~1,0; sa dintre doi dinti = 0,76-0,84 din cel mai mic), `w` = 0 pe dinte, 1 pe sa (da mai
    tarziu coastele si jgheaburile). `n` dinti triunghiulari pe `L * 0,90`."""
    rnd = _lcg(seed)
    half = L * 0.5
    span = L * 0.90
    pitch = span / n
    cs = [-span * 0.5 + (i + 0.5) * pitch + (rnd() - 0.5) * 0.34 * pitch for i in range(n)]
    hts = [0.97 + rnd() * 0.03 for _ in range(n)]
    if nego_frac is not None:
        # Negoiu: dinte cu ~17% mai inalt decat vecinii (masa, nu ac), la anvelopa maxima
        xm = -half + L * nego_frac
        j = min(range(n), key=lambda q: abs(cs[q] - xm))
        hts[j] = 1.17
    knots = [(-half, hts[0] * 0.80, 1.0)]
    for i in range(n):
        knots.append((cs[i], hts[i], 0.0))
        if i + 1 < n:
            depth = 0.16 + 0.08 * rnd()
            m = cs[i] + (cs[i + 1] - cs[i]) * (0.5 + (rnd() - 0.5) * 0.24)
            lo_h, hi_h = min(hts[i], hts[i + 1]), max(hts[i], hts[i + 1])
            knots.append((m, (lo_h + 0.40 * (hi_h - lo_h)) * (1.0 - depth), 1.0))
    knots.append((half, hts[-1] * 0.80, 1.0))
    return knots


def _knot_eval(knots, u):
    if u <= knots[0][0]:
        return knots[0][1], knots[0][2]
    for k in range(len(knots) - 1):
        a, c = knots[k], knots[k + 1]
        if u <= c[0]:
            fr = (u - a[0]) / max(c[0] - a[0], 1e-6)
            return a[1] + (c[1] - a[1]) * fr, a[2] + (c[2] - a[2]) * fr
    return knots[-1][1], knots[-1][2]


def _peaks(col, step, off, minprom):
    """Maxime locale cu proeminenta >= minprom pe profilul de coloane `col`."""
    nb = len(col)
    pk = []
    for i in range(1, nb - 1):
        if col[i] >= col[i - 1] and col[i] > col[i + 1]:
            l = i
            while l > 0 and col[l - 1] <= col[i]:
                l -= 1
            r = i
            while r < nb - 1 and col[r + 1] <= col[i]:
                r += 1
            drops = []
            if l > 0:
                drops.append(col[i] - min(col[l:i + 1]))
            if r < nb - 1:
                drops.append(col[i] - min(col[i:r + 1]))
            if not drops:
                drops = [col[i] - min(col)]
            pr = min(drops)
            if pr >= minprom:
                pk.append((round((i + 0.5) * step - off), round(col[i], 1), round(pr, 1)))
    return pk


def _ridge(name, seed, L, W, n_teeth, h_target, win, mirror, nego_frac=None, base_h=6.0):
    """`fagaras_ridge` (decuparea `fagaras_ridge.png`), reluare tf-g2 -- LISTA DE ELEMENTE pe o
    bucata (SILUETA INTAI, apoi fatetarea):

    1. LINIA CRESTEI = un PERETE CONTINUU: anvelopa extrasa din decupare (`ENV`, comprimata la
       0,40 + 0,60 env) x un profil de `n_teeth` (12-13) DINTI TRIUNGHIULARI, de 14-18 m
       latime; sailor dintre ei coboara DOAR 16-24% din inaltimea dintelui (nu pana la poale).
       Un singur dinte (Negoiu, doar pe A) e cu ~17% mai inalt decat vecinii: masa, nu ac.
       In plan creasta ondulata +-2,5 m, culmea plata de ~2,4 m.
    2. COASTE de stanca: de la fiecare dinte pleaca oblic spre poale (evantai: 0,85 x x/(L/2)
       + 0,30 pe fata) o muchie ingusta (w < 0,25 din semi-latimea dintelui); flancul spre +X
       in umbra (ton ~0,5), cel spre -X luminat.
    3. CALDARI / CULOARE: intre coaste, scobituri largi (w 0,25-0,9), tot mai adanci spre poale
       (pana la 55% din inaltimea locala): `FOAM_WHITE` pe ~35-45% din fata de sus (masurat).
    4. Verdele (TROPICAL_GREEN, 30% CACTUS_GREEN) in LIMBI sub coaste, in treimea de jos
       (pana la 4 + 17 m, mai sus sub coaste, mai jos in culoar) + brau de poala de 6 m.
    Plan: elipsa L x W (corp INCHIS), baza plata; grila ~2,0 x 2,4 m, diagonala pe creasta,
    AO plat pe fateta. Sloturi: MARBLE_GREY, FOAM_WHITE, TROPICAL_GREEN, CACTUS_GREEN."""
    b = Builder()
    half = L * 0.5
    nu = int(round(L / 2.0))
    nv = int(round(W / 2.4))
    env = _env_fn(win[0], win[1], mirror)
    knots = _crest_knots(L, n_teeth, seed, nego_frac)
    peak = max(env(q / 2000.0) * _knot_eval(knots, -half + L * q / 2000.0)[0]
               for q in range(2001))
    Hs = h_target / peak
    rw = W * 0.5 * 0.93

    def field(x, y):
        yc = 2.5 * _vn(x * 0.04, 0.0, seed)
        d = abs(y - yc)
        side = 1.0 if y >= yc else -1.0
        xn = max(-1.0, min(1.0, x / half))
        u = max(-half, min(half, x - (0.85 * xn + 0.30 * side) * d))
        K, w = _knot_eval(knots, u)
        e = env((u + half) / L)
        t = min(1.0, max(0.0, d - 1.2) / rw)
        return Hs * e * K, w, t

    def height(x, y, rho):
        hc, w, t = field(x, y)
        gl = _sm(0.25, 0.90, w)
        gd = 0.55 * _sm(0.04, 0.75, t)
        h = hc * (1.0 - t) ** 1.2 * (1.0 - gd * gl)
        h *= 1.0 + 0.03 * _vn(x * 0.31, y * 0.27, seed + 3)
        h *= 0.22 + 0.78 * _sm(1.0, 0.86, rho)
        sk = base_h * _sm(1.0, 0.72, rho) * (0.85 + 0.30 * _vn(x * 0.05, y * 0.05, seed))
        return max(h, sk)

    faces = _heightfield_solid(b, nu, nv, L, W, height, 0.18, seed)
    hmax = max(v.co.z for v in b.bm.verts)

    def glt(c):
        _, w, t = field(c.x, c.y)
        return _sm(0.25, 0.90, w), t

    def snow(c, n):
        gl, t = glt(c)
        hs = _h01(c.x * 0.31, c.y * 0.27, seed)
        zf = c.z / hmax
        if gl > 0.30 and zf > 0.20 and n.z > 0.18:
            return hs < 0.93
        return zf > 0.55 and n.z > 0.55 and hs < 0.22

    def green(c, n):
        gl, t = glt(c)
        hs = _h01(c.x * 0.19, c.y * 0.23, seed + 9)
        gz = 4.0 + 17.0 * (1.0 - gl) * (0.70 + 0.60 * hs)
        return (c.z < gz and n.z > 0.30) or c.z < 3.0

    b.retag(faces, ROCK)
    b.retag(faces, SNOW, where=snow)
    b.retag(faces, GRASS, where=lambda c, n: green(c, n) and not snow(c, n))
    b.retag(faces, GRASS2, where=lambda c, n: (green(c, n) and not snow(c, n)
                                               and _h01(c.x, c.y, seed + 5) < 0.30))
    tone = b.bm.faces.layers.float.new("tone")
    b.bm.normal_update()
    cov = {1: [0.0, 0.0], -1: [0.0, 0.0]}
    for f in b.bm.faces:
        n = f.normal
        lit = 1.0 - _sm(-0.35, 0.35, n.x)            # flancul spre +X in umbra
        if f[b.slot] == SNOW:
            f[tone] = 0.78 + 0.18 * lit
        else:
            slope = max(0.0, min(1.0, (n.z - 0.15) / 0.75)) ** 0.8
            f[tone] = (0.48 + 0.20 * slope) * (0.45 + 0.55 * lit)
        c = f.calc_center_median()
        if c.z > 0.30 * hmax and abs(n.y) > 0.05:
            s = 1 if n.y > 0 else -1
            ar = f.calc_area() * abs(n.y)
            cov[s][0] += ar
            if f[b.slot] == SNOW:
                cov[s][1] += ar
    # silueta masurata pe FUNCTIA de inaltime: maximul pe y, la pas de 1,15 m in x
    nb = int(L / 1.15)
    col = []
    for k in range(nb):
        x = -half + (k + 0.5) * L / nb
        col.append(max(height(x, yy, math.hypot(x / half, yy / (W * 0.5)))
                       for yy in [-9.0 + 0.75 * q for q in range(25)]))
    pk = _peaks(col, L / nb, half, 0.025 * hmax)
    sad = col[int(nb * 0.1):int(nb * 0.9)]
    print("RIDGE %s: hmax %.1f; zapada pe fata de sus (z>30%% hmax) +Y %.0f%%, -Y %.0f%%; "
          "dinti %d; sa minima 10-90%% din lungime %.1f m = %.0f%% din hmax"
          % (name, hmax, 100.0 * cov[1][1] / max(cov[1][0], 1e-6),
             100.0 * cov[-1][1] / max(cov[-1][0], 1e-6), len(pk), min(sad),
             100.0 * min(sad) / hmax))
    print("  dinti (x, cota, proeminenta): %s" % pk)
    RIDGE_SIL[name] = (nb, col, hmax, L)
    return settle(b, name)


def build_ridge_a():
    """FagarasRidge_A (Negoiu) -- LISTA: 230 x 66 m, creasta 67 m max; 13 dinti pe perete
    continuu, sa 16-24%; Negoiu = dintele din anvelopa maxima (la ~65% din lungime), +17%."""
    return _ridge("FagarasRidge_A", 9101, 230.0, 66.0, 13, 66.0, (0.012, 1.0), False, 0.65)


def build_ridge_b():
    """FagarasRidge_B -- LISTA: 190 x 60 m, creasta ~52 m; 12 dinti, aceeasi lege; anvelopa
    decuparii oglindita, ferestruita 1-86% (alta ordine a dintilor decat A); fara dinte
    dominant."""
    return _ridge("FagarasRidge_B", 9202, 190.0, 60.0, 12, 51.0, (0.012, 0.86), True)


def build_ridge_c():
    """FagarasRidge_C -- LISTA: 165 x 56 m, creasta ~54 m; 12 dinti; anvelopa 14-100%."""
    return _ridge("FagarasRidge_C", 9303, 165.0, 56.0, 12, 54.0, (0.14, 1.0), False)


# ---------------------------------------------------------------------------
# MAREA DE NORI (reluare tf-g2: gramezi de cumulus, nu pietricele pe o placa)
# ---------------------------------------------------------------------------

def _cloud(name, seed, L, W, n_heaps, slab_h, top_hi):
    """`cloud_sea` (decuparea `cloud_sea.png`), reluare tf-g2 -- LISTA DE ELEMENTE pe o bucata:

    1. BAZA: o placa joasa (`slab_h` = 3 m, elipsa 0,90 L x 0,80 W, fatetata, ton 0,55: fundul
       mai intunecat care se vede prin goluri).
    2. `n_heaps` (8 pe A, 7 pe B) GRAMEZI de cumulus, in ZIGZAG de-a lungul lungimii (y = +-0,20
       W, jitter +-0,10 W), diametrul gramezii D = 1,15 x pasul L/n: vecinele se ating in
       proiectie, dar in plan raman VAI intre randuri si goluri neregulate.
    3. Fiecare gramada: un BULGARE PRINCIPAL (raza 0,26 D, varful `top_hi` x 0,75-1,00, aspect
       inaltime/diametru ~0,7-0,9) si 4-5 SATELITI la 0,28-0,36 D de centru (raza 0,16-0,20 D,
       varful 50-75% din principal, aspect ~0,55-0,9): se suprapun in COCOASE cu SEI de 4-9 m.
    4. Toti bulgarii: dom inchis (10 laturi x 4 inele + varf), fundul la z=0, FOAM_WHITE;
       tonul copt: fete de sus 1,0, flancuri spre +X mai intunecate, poala intunecata."""
    b = Builder()
    rnd = _lcg(seed)
    rx0, ry0 = L * 0.5, W * 0.5
    prof = [(0.0, 1.0), (0.38, 1.0), (0.82, 0.90), (1.0, 0.72)]
    rings = [(slab_h * t, rx0 * 0.90 * f, ry0 * 0.80 * f, 0.0, 0.0) for t, f in prof]
    pts, _ = ring_points(rings, 28, seed + 1, 0.06)
    faceted_shell(b, pts, SNOW)
    pitch = L / n_heaps
    D = pitch * 1.15
    lumps = []
    for hi in range(n_heaps):
        cx = -L * 0.5 + (hi + 0.5) * pitch + (rnd() - 0.5) * 0.16 * pitch
        cy = (0.20 if hi % 2 == 0 else -0.20) * W + (rnd() - 0.5) * 0.20 * W
        top = top_hi * (0.75 + 0.25 * rnd())
        lumps.append((cx, cy, D * (0.25 + 0.02 * rnd()), top))
        ns = 4 + int(rnd() * 1.99)
        a0 = rnd() * 6.283
        for q in range(ns):
            ang = a0 + 6.283 * (q + 0.35 * (rnd() - 0.5)) / ns
            dist = D * (0.28 + 0.08 * rnd())
            sx = cx + math.cos(ang) * dist
            sy = max(-0.33 * W, min(0.33 * W, cy + math.sin(ang) * dist * 0.85))
            lumps.append((sx, sy, D * (0.16 + 0.04 * rnd()), top * (0.50 + 0.25 * rnd())))
    for li, (cx, cy, rx, top) in enumerate(lumps):
        ry = rx * (0.86 + 0.14 * rnd())
        lring = [(top * t, rx * f, ry * f, cx, cy)
                 for t, f in ((0.0, 0.94), (0.28, 1.0), (0.62, 0.82), (0.88, 0.46))]
        lp, _ = ring_points(lring, 10, seed * 7 + li, 0.10)
        faceted_shell(b, lp, SNOW, top_pt=Vector((cx, cy, top)))
    tone = b.bm.faces.layers.float.new("tone")
    b.bm.normal_update()
    for f in b.bm.faces:
        n = f.normal
        c = f.calc_center_median()
        up = max(0.0, min(1.0, (n.z + 0.1) / 0.9))
        base = 0.50 + 0.50 * up
        lit = 1.0 - 0.22 * _sm(-0.2, 0.6, n.x)
        foot = 0.62 + 0.38 * _sm(0.0, 9.0, c.z)
        f[tone] = base * lit * foot if c.z > slab_h else 0.55
    nb = int(L / 2.0)
    col = [0.0] * nb
    for v in b.bm.verts:
        k = min(nb - 1, max(0, int((v.co.x + rx0) / L * nb)))
        col[k] = max(col[k], v.co.z)
    pk = _peaks(col, L / nb, rx0, 3.0)
    print("CLOUD %s: %d bulgari in %d gramezi; cocoase (prom >= 3 m) %d: %s; sa min %.1f m, max %.1f m"
          % (name, len(lumps), n_heaps, len(pk), pk, min(col[2:-2]), max(col)))
    return settle(b, name)


def build_cloud_a():
    """CloudSea_A -- 270 x ~66-80 m, baza 3 m, 8 gramezi, varfuri pana la ~18 m."""
    return _cloud("CloudSea_A", 9411, 270.0, 66.0, 8, 3.0, 18.0)


def build_cloud_b():
    """CloudSea_B -- 210 x ~58-72 m, baza 3 m, 7 gramezi, varfuri pana la ~16 m."""
    return _cloud("CloudSea_B", 9512, 210.0, 58.0, 7, 3.0, 16.0)


# ---------------------------------------------------------------------------
# CAMPIA
# ---------------------------------------------------------------------------

def build_plain():
    """`fagaras_plain` (decuparea `fagaras_plain.png`) -- LISTA DE ELEMENTE:
    - o placa 300 x 120 m cu RELIEF de 1,6-4,2 m (ondulat, cu poale de 9 m la margine);
    - 7 FASII de camp, late de 12-22 m, inclinate 9 grade fata de axa lunga: 3 verzi
      (CACTUS_GREEN, TROPICAL_GREEN, tonuri prin AO) si DOUA galben-uscate (DRY_VEGETATION; planșa e
      dominant galben-oliv, abatere fata de 'una' din kit), una taiata de un petic verde; petice de
      55 m cu ton propriu (tabla de camp);
    - 5 PALCURI de copaci ca mase joase (cate 2-4 bulgari faceti de 5-9 m inaltime, raze
      5-9 m), din TROPICAL_GREEN mai intunecat, asezate pe terenul real.
    Un singur nod, un singur corp inchis (evantai de baza)."""
    b = Builder()
    L, W = 300.0, 120.0
    seed = 9601
    tone = b.bm.faces.layers.float.new("tone")
    nu, nv = 60, 24
    cell = L / nu

    def rel(x, y):
        return (2.7 + 0.95 * math.sin(x * 0.021 + 1.3) * math.cos(y * 0.033)
                + 0.75 * math.sin(x * 0.047 + y * 0.029 + 2.0) + 0.35 * math.sin(y * 0.09 + x * 0.013))

    def height(x, y, rho):
        e = min(L * 0.5 - abs(x), W * 0.5 - abs(y))
        return rel(x, y) * _sm(0.0, 9.0, e)

    # grila patrata (nu eliptica): conturul dreptunghiului, colturi usor rotunjite
    grid = {}
    for i in range(nu + 1):
        for j in range(nv + 1):
            x = -L * 0.5 + L * i / nu
            y = -W * 0.5 + W * j / nv
            border = i in (0, nu) or j in (0, nv)
            if not border:
                x += (_h01(i, j, seed) - 0.5) * 0.5 * cell
                y += (_h01(j, i, seed + 7) - 0.5) * 0.5 * (W / nv)
            z = 0.0 if border else height(x, y, 0.0)
            grid[(i, j)] = b.bm.verts.new((x, y, z))
    top_faces = []

    def tri(a, c, d):
        f = b.bm.faces.new([a, c, d])
        f[b.slot] = GRASS
        f[tone] = 1.0
        top_faces.append(f)

    for i in range(nu):
        for j in range(nv):
            p00, p10 = grid[(i, j)], grid[(i + 1, j)]
            p11, p01 = grid[(i + 1, j + 1)], grid[(i, j + 1)]
            if (i + j) % 2 == 0:
                tri(p00, p10, p11); tri(p00, p11, p01)
            else:
                tri(p00, p10, p01); tri(p10, p11, p01)
    loop = [grid[(i, 0)] for i in range(nu)] + [grid[(nu, j)] for j in range(nv)] \
        + [grid[(i, nv)] for i in range(nu, 0, -1)] + [grid[(0, j)] for j in range(nv, 0, -1)]
    cv = b.bm.verts.new((0.0, 0.0, 0.0))
    for k in range(len(loop)):
        f = b.bm.faces.new([loop[k], loop[(k + 1) % len(loop)], cv])
        f[b.slot] = GRASS
        f[tone] = 1.0

    # fasiile: latimi 12-22 m (suma 120), inclinate 9 grade
    widths = [16.0, 20.0, 14.0, 22.0, 18.0, 12.0, 18.0]      # = 120
    kinds = [GRASS2, DRY, GRASS2, GRASS, DRY, GRASS2, GRASS]
    tones = [1.0, 0.95, 0.88, 0.80, 1.0, 0.9, 0.78]
    edges = [0.0]
    for w in widths:
        edges.append(edges[-1] + w)
    ang = math.radians(9.0)
    ca, sa = math.cos(ang), math.sin(ang)

    def field(c):
        s = -c.x * sa + c.y * ca + W * 0.5 + 6.0 * math.sin(c.x * 0.045 + 0.7)
        t = c.x * ca + c.y * sa
        k = 0
        for q in range(len(widths)):
            if edges[q] <= s < edges[q + 1]:
                k = q
                break
        else:
            k = 0 if s < 0 else len(widths) - 1
        slot, tn = kinds[k], tones[k]
        if k == 4 and 20.0 < t < 78.0:           # galbenul: un petic verde taie fasia
            slot, tn = GRASS2, 1.0
        if k == 1 and t > 90.0:                  # alt verde pe jumatatea de est
            slot, tn = GRASS2, 0.88
        if k == 5 and t < -45.0:
            slot, tn = GRASS, 0.74
        pi = int((t + 400.0) // 55.0)          # petice de 55 m: tabla de camp
        tn *= 0.86 + 0.14 * _h01(k, pi, seed + 2)
        return slot, tn

    for f in top_faces:
        c = f.calc_center_median()
        slot, tn = field(c)
        f[b.slot] = slot
        f[tone] = tn

    # 5 palcuri de copaci: 2-4 bulgari fiecare, pe terenul real
    clumps = [(-112, 22, 3), (-40, -30, 4), (30, 28, 3), (88, -14, 2), (118, 30, 3)]
    rnd = _lcg(seed + 11)
    for ci, (px, py, n) in enumerate(clumps):
        for q in range(n):
            cx = px + (rnd() - 0.5) * 16.0
            cy = py + (rnd() - 0.5) * 10.0
            r = 5.0 + rnd() * 4.0
            hh = 5.0 + rnd() * 4.0
            z0 = rel(cx, cy) - 0.8
            ring = [(z0 + hh * t, r * f, r * 0.85 * f, cx, cy)
                    for t, f in ((0.0, 0.88), (0.30, 1.0), (0.70, 0.78), (0.95, 0.40))]
            lp, _ = ring_points(ring, 8, seed + ci * 10 + q, 0.12)
            n0 = len(b.bm.faces)
            faceted_shell(b, lp, GRASS, top_pt=Vector((cx, cy, z0 + hh)))
            for f in list(b.bm.faces)[n0:]:
                f[tone] = 0.55
    return settle(b, "FagarasPlain_A")


# ---------------------------------------------------------------------------
# emit
# ---------------------------------------------------------------------------

def _apply_tone(o):
    me = o.data
    att = me.attributes.get("tone")
    if att is None:
        return
    ca = me.color_attributes["AO"]
    for poly in me.polygons:
        t = att.data[poly.index].value
        for i in poly.vertices:
            col = ca.data[i].color
            ca.data[i].color = (col[0] * t, col[1] * t, col[2] * t, 1.0)
    me.attributes.remove(att)


results = []


def emit(obj, ao):
    _split_all_edges(obj)
    st = finish(obj, bevel=0.0, ao=ao, origin=None, smooth_angle=None)
    _flatten_ao(obj)
    _apply_tone(obj)
    d = obj.dimensions
    results.append((obj.name, st["tris"], d.x, d.y, d.z))
    if obj.name == "FagarasPlain_A":      # amprenta: garda "campia ramane identica" (tf-g2)
        import hashlib
        me = obj.data
        hh = hashlib.sha1()
        for v in me.vertices:
            hh.update(("%.3f,%.3f,%.3f;" % (v.co.x, v.co.y, v.co.z)).encode())
        for ca in me.color_attributes["AO"].data:
            hh.update(("%.3f;" % ca.color[0]).encode())
        print("PLAIN_HASH", hh.hexdigest(), len(me.vertices), len(me.polygons))
    return obj


ra, rb, rc = build_ridge_a(), build_ridge_b(), build_ridge_c()
ca_, cb_ = build_cloud_a(), build_cloud_b()
pl = build_plain()
built = [emit(ra, AO_RIDGE), emit(rb, AO_RIDGE), emit(rc, AO_RIDGE),
         emit(ca_, AO_CLOUD), emit(cb_, AO_CLOUD), emit(pl, AO_PLAIN)]
_, sz = export_glb(built, "transfagarasan/effects/transfagarasan_horizon.glb")
print("export: transfagarasan/effects/transfagarasan_horizon.glb (%.0f KB)" % (sz / 1024.0))
print()
total = 0
for name, tris, dx, dy, dz in results:
    total += tris
    print("%-16s tris=%6d  %.1f x %.1f x %.1f m" % (name, tris, dx, dy, dz))
print("TOTAL horizon: %d tris" % total)

for i, o in enumerate(built):
    o.location.x = i * 320.0
save_blend(built, "transfagarasan_horizon.blend")
