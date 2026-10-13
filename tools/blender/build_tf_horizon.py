"""Transfagarasan -- FUNDALUL (kit docs/asset_briefs/transfagarasan_kit.md §1.8, val 3, tf-g).

  transfagarasan/effects/transfagarasan_horizon.glb   6 noduri, copii directi ai radacinii:
    FagarasRidge_A  creasta zimtata, 230 m, VARFUL DOMINANT (Negoiu, 70 m)
    FagarasRidge_B  creasta zimtata, 190 m
    FagarasRidge_C  creasta zimtata, 165 m
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
de sist, SAUA dintre varfuri, caldarile cu zapada. De aceea fiecare creasta are saile adanci
(40-55% din inaltimea varfurilor) si dinti secundari de 20-28 m: la 25-35 m deasupra bazei
silueta trebuie sa fie deja zimtata, nu doar varfurile de 60-70 m, pe care cadrul le taie.

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
# CREASTA
# ---------------------------------------------------------------------------

def _ridge(name, seed, L, W, summits, teeth, cirques, base_h=7.0):
    """`fagaras_ridge` (decuparea `fagaras_ridge.png`) -- LISTA DE ELEMENTE pe o bucata:

    - `summits` = varfurile: fiecare (x, y, inaltime, raza) -> con concav (profil
      (1 - r/R(theta))^p, p ~1,3-1,6) cu 2 ARETE lungi pe directia crestei (cos 2theta) si
      1-3 contraforturi laterale (cos 3theta, faza proprie). Sailor dintre varfuri
      cad la 40-55% din inaltimea varfurilor.
    - `teeth` = dintii secundari (gendarmi) de 20-28 m pe arete, intre varfuri: silueta
      ramane zimtata si in banda de 25-35 m pe care o vede camera.
    - `cirques` = CALDARILE GLACIARE: scobituri (centru x, y, raza, adancime) in flancuri,
      pe sub varfuri; podeaua lor si jgheaburile inalte, line, iau FOAM_WHITE.
    - poalele: un brau de contrafort verde (TROPICAL_GREEN, 28% CACTUS_GREEN) pana la
      ~15 m, cu ramasite de sist unde panta e abrupta.
    - zapada si pe fetele line de sub creasta (praguri de panta crescatoare cu cota).
    Plan: elipsa L x W (corp INCHIS), baza plata, 3 bucati: A cu varful dominant (Negoiu).
    Facetele: grila de ~3,5 m cu jitter, diagonala pe creasta, AO plat pe fateta.
    """
    b = Builder()
    nu = int(round(L / 3.6))
    nv = int(round(W / 3.6))
    hmax = max(s[2] for s in summits)
    rnd = _lcg(seed)
    S = []
    for (sx, sy, H, R) in summits:
        S.append((sx, sy, H, R, rnd() * 6.28, 0.22 + rnd() * 0.22, 1.30 + rnd() * 0.22))
    T = []
    for (sx, sy, H, R) in teeth:
        T.append((sx, sy, H, R, rnd() * 6.28, 0.30, 1.15))

    def height(x, y, rho):
        sk = base_h * _sm(1.0, 0.78, rho) * (0.85 + 0.30 * _vn(x * 0.05, y * 0.05, seed))
        m = 0.0
        for (sx, sy, H, R, ph, spur, p) in S + T:
            dx, dy = x - sx, y - sy
            r = math.hypot(dx, dy)
            th = math.atan2(dy, dx)
            Rt = R * (1.0 + 0.50 * math.cos(2.0 * th) + spur * math.cos(3.0 * th + ph))
            if r < Rt:
                m = max(m, H * (1.0 - r / Rt) ** p)
        m *= _sm(1.04, 0.80, rho)
        h = max(sk, m)
        for (cx, cy, Rc, dep) in cirques:
            d = math.hypot(x - cx, y - cy) / Rc
            if d < 1.0:
                h = max(sk * 0.92, h - dep * _sm(1.0, 0.40, d))
        return h * (1.0 + 0.045 * _vn(x * 0.23, y * 0.31, seed + 3))

    faces = _heightfield_solid(b, nu, nv, L, W, height, 0.30, seed)

    def snow(c, n):
        zf = c.z / hmax
        if c.z > 10.0 and n.z > 0.28:
            for (cx, cy, Rc, dep) in cirques:
                if math.hypot(c.x - cx, c.y - cy) < 0.82 * Rc:
                    return True
        hs = _h01(c.x * 0.31, c.y * 0.27, seed)
        if c.z > 0.16 * hmax and n.z > 0.52 - 0.40 * zf:
            return hs < 0.88
        return c.z > 0.26 * hmax and n.z > 0.25 and hs < 0.30

    def green(c, n):
        return (c.z < 10.0 and n.z > 0.62) or c.z < 3.5

    b.retag(faces, ROCK)
    b.retag(faces, SNOW, where=snow)
    b.retag(faces, GRASS, where=lambda c, n: green(c, n) and not snow(c, n))
    b.retag(faces, GRASS2, where=lambda c, n: (green(c, n) and not snow(c, n)
                                               and (_h01(c.x, c.y, seed + 5) < 0.30
                                                    or c.z > 7.5)))
    tone = b.bm.faces.layers.float.new("tone")
    b.bm.normal_update()
    for f in b.bm.faces:
        n = f.normal
        f[tone] = 0.50 + 0.50 * max(0.0, min(1.0, (n.z - 0.15) / 0.75)) ** 0.8 if f[b.slot] != SNOW else 0.92
    return settle(b, name)


def build_ridge_a():
    """FagarasRidge_A (Negoiu) -- LISTA: elipsa 230 x 66 m; 8 VARFURI (36, 44, 52, **70 =
    varful dominant, ingust, la x -8**, 50, 46, 40, 30 m); 3 DINTI secundari (24, 27, 22 m);
    3 CALDARI (R 18-22 m, adancimi 10-14 m) pe flancuri, sub varfurile 3, 4 si 6."""
    summits = [(-100, 3, 36, 24), (-72, -5, 44, 27), (-44, 5, 52, 29), (-8, -1, 70, 33),
               (24, -5, 50, 28), (52, 6, 46, 27), (78, -3, 40, 25), (100, 2, 30, 21)]
    teeth = [(-58, 8, 24, 11), (8, 8, 27, 12), (66, -9, 22, 10)]
    cirques = [(-46, 19, 20, 12), (12, -19, 22, 14), (54, 19, 18, 10)]
    return _ridge("FagarasRidge_A", 9101, 230.0, 66.0, summits, teeth, cirques)


def build_ridge_b():
    """FagarasRidge_B -- LISTA: elipsa 190 x 60 m; 6 VARFURI (42, 54, 46, 58, 44, 34 m);
    3 DINTI secundari (24, 26, 21 m); 2 CALDARI (R 19 si 17 m, adancimi 12 si 10 m)."""
    summits = [(-66, 3, 42, 26), (-36, -4, 54, 29), (-4, 4, 46, 27), (28, -3, 58, 31),
               (58, 5, 44, 26), (78, -2, 34, 22)]
    teeth = [(-50, -9, 24, 11), (12, 9, 26, 11), (44, -8, 21, 10)]
    cirques = [(-22, -19, 19, 12), (44, 18, 17, 10)]
    return _ridge("FagarasRidge_B", 9202, 190.0, 60.0, summits, teeth, cirques)


def build_ridge_c():
    """FagarasRidge_C -- LISTA: elipsa 165 x 56 m; 7 VARFURI (34, 42, 52, 44, 56, 40, 32 m);
    2 DINTI secundari (22, 25 m); 2 CALDARI (R 17 si 16 m, adancimi 10 si 9 m)."""
    summits = [(-64, 2, 34, 22), (-42, -4, 42, 24), (-18, 4, 52, 27), (6, -3, 44, 25),
               (30, 4, 56, 28), (54, -2, 40, 24), (70, 2, 32, 20)]
    teeth = [(-30, -9, 22, 10), (42, 9, 25, 11)]
    cirques = [(-8, 17, 17, 10), (44, -17, 16, 9)]
    return _ridge("FagarasRidge_C", 9303, 165.0, 56.0, summits, teeth, cirques)


# ---------------------------------------------------------------------------
# MAREA DE NORI
# ---------------------------------------------------------------------------

def _cloud(name, seed, L, W, n_lumps, slab_h, top_hi):
    """`cloud_sea` (decuparea `cloud_sea.png`) -- LISTA DE ELEMENTE pe o bucata:
    - UN STRAT PLAT (placa fatetata, elipsa L x W, `slab_h` m grosime, 28 laturi, 4 inele);
    - `n_lumps` BULGARI rotunzi (fatete late: 9 laturi x 4 inele), raze 15-29 m pe X, 70-100%
      pe Y, varfurile intre slab_h si `top_hi` (cele din centru mai inalte); ~40% sunt asezati
      pe MUCHIA placii, ca bulgarii sa iasa in contur;
    - toti pe FOAM_WHITE, corpuri inchise, baza la z=0 (fundul plat, in vale)."""
    b = Builder()
    rnd = _lcg(seed)
    rx0, ry0 = L * 0.5, W * 0.5
    prof = [(0.0, 1.0), (0.38, 1.0), (0.82, 0.90), (1.0, 0.72)]
    rings = [(slab_h * t, rx0 * f, ry0 * f, 0.0, 0.0) for t, f in prof]
    pts, _ = ring_points(rings, 28, seed + 1, 0.06)
    faceted_shell(b, pts, SNOW)
    placed = 0
    guard = 0
    while placed < n_lumps and guard < 2000:
        guard += 1
        if placed < int(n_lumps * 0.4):
            a = rnd() * 2.0 * math.pi
            k = 0.82 + rnd() * 0.20            # pe muchie sau chiar peste ea
        else:
            a = rnd() * 2.0 * math.pi
            k = math.sqrt(rnd()) * 0.80
        cx, cy = math.cos(a) * rx0 * k, math.sin(a) * ry0 * k
        rho = math.hypot(cx / rx0, cy / ry0)
        rx = 15.0 + rnd() * 14.0
        ry = rx * (0.70 + rnd() * 0.30)
        top = slab_h + (top_hi - slab_h) * (0.15 + 0.85 * rnd()) * (1.0 - 0.30 * rho)
        hl = 9.0 + rnd() * 5.0
        z0 = max(0.0, top - hl)
        hl = top - z0
        lring = [(z0 + hl * t, rx * f, ry * f, cx, cy)
                 for t, f in ((0.0, 0.94), (0.25, 1.0), (0.60, 0.80), (0.88, 0.44))]
        lp, _ = ring_points(lring, 9, seed * 7 + placed, 0.10)
        faceted_shell(b, lp, SNOW, top_pt=Vector((cx, cy, top)))
        placed += 1
    return settle(b, name)


def build_cloud_a():
    """CloudSea_A -- 280 x 70 m, placa de 6 m, 62 bulgari (raze 15-29 m), varfuri pana la 15 m."""
    return _cloud("CloudSea_A", 9411, 270.0, 66.0, 62, 4.0, 15.0)


def build_cloud_b():
    """CloudSea_B -- 220 x 60 m, placa de 5 m, 48 bulgari, varfuri pana la 13 m."""
    return _cloud("CloudSea_B", 9512, 210.0, 58.0, 48, 4.0, 13.0)


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
