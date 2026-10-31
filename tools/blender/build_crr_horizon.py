"""Carrara -- FUNDALUL (kit docs/asset_briefs/carrara_kit.md §1.6, val 2, crr-f).

  carrara/effects/carrara_horizon.glb   3 noduri, copii directi ai radacinii:
    ApuanRidge_A   creasta lunga si joasa: 2 varfuri mari + unul mic la mijloc
                   (decuparea `apuan_ridge.png`)
    ApuanRidge_B   masivul cu mai multe varfuri: 3 mari + 2 dinti (decuparea
                   `apuan_ridge_b.png`, varianta "cu mai multe varfuri")
    ApuanRidge_C   cornul: un varf inalt si abrupt + un umar, silueta scurta

Consumatorul e `Track._build_horizon` (scenes/tracks/track.gd, tema `carrara`): ia
nodurile DUPA NUME (`horizon_picks`), le aseaza pe inele la 200-300 m, le scaleaza si
le roteste, deci fiecare nod e un VOLUM INCHIS, lizibil din ORICE azimut, cu originea
la BAZA (XY centrat pe bbox, Z min = 0; `_build_horizon` il pune la `ground_y - 4`).

Cote (kit §1.6): 160-240 m lungime, 35-60 m inaltime, 2-3 varfuri de calcar pe o
bucata. Sloturile (kit §0, tabelul "fundalul"): flancurile MARBLE_GREY 29 (crem-gri),
darele de moloz CORAL_SAND 19 (ravaneti: fasii deschise care COBOARA pe jgheaburi),
padurea de la baza TROPICAL_GREEN 21 + DRY_VEGETATION 13 (mase joase, bulgari fatetati).
FARA calota alba, fara FOAM_WHITE (brief §5.4: calota = zapada = Alpi). Zero sloturi
noi. Umbrire PLATA (AO copt pe fateta, ca fatetele de calcar sa se citeasca drept
plane la 250 m). Fara coliziune; `cast_shadow` OFF il pune `_build_horizon`.

CE VEDE JUCATORUL (memoriile `verifica-cu-parametrii-lui`, `munte-flanc-nu-fundal`):
camera de joc la 10 m, fov vertical 68, marginea de sus a cadrului la ~+5 grade peste
orizont: la 250 m, ~33 m peste cota drumului. Creasta se citeste din banda de jos si de
la mijloc: brâul verde, jgheaburile cu moloz deschis, coastele de calcar, seile.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_horizon.py
"""

import math
from mathutils import Vector

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "carrara_shapes.py"), encoding="utf-8").read())
exec(open(os.path.join(_here, "okinawa_shapes.py"), encoding="utf-8").read())

clear_built()

ROCK = MARBLE_GREY            # 29: calcarul flancurilor (crem-gri)
SCREE = CORAL_SAND            # 19: darele de moloz (ravaneti), deschise
FOREST = TROPICAL_GREEN       # 21: padurea de la baza
DRY = DRY_VEGETATION          # 13: verde-galbui (ginestra, petice uscate)

# AO si tonuri BLANDE (runda 2, din capturile de joc): la 130-250 m, cu ceata abia
# inceputa (fog_begin 150), flancul in umbra iesea gri-inchis (~80/255) langa peretii
# carierei palizi -- un munte apropiat, nu fundal. Contrastul de fundal e mic.
AO_RIDGE = dict(samples=12, dist=30.0, gradient="vertical", low=0.80, high=1.0,
                power=0.85, floor=0.50)

GRID = 3.0                    # latura celulei de relief (m): fatete de ~3 m
SKIRT = 0.6                   # poala verticala de la contur (m), vezi _heightfield_solid
SQ = 0.16                     # 0,5 = elipsa; mai mic = contur mai drept


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


# ---------------------------------------------------------------------------
# campul de relief: varfuri cu coaste si jgheaburi radiale
# ---------------------------------------------------------------------------

class RidgeField:
    """Relieful unei creste. `summits` = (x, y, H, R, nr): varful la (x, y), cota H,
    raza bazei R, `nr` coaste radiale. Fiecare varf e o piramida de calcar (profil
    aproape drept, p ~1,05-1,2) cu doua ARETE pe directia crestei (cos 2theta) si
    `nr` JGHEABURI radiale intre coaste: jgheabul e o scobitura care se adanceste la
    mijlocul flancului si se stinge la varf si la poale. `gully(x, y)` intoarce cat
    de "in jgheab" e punctul (0..1): de el se leaga darele de moloz si padurea care
    urca pe vale, deci darele COBOARA pe flanc, nu pete la intamplare."""

    def __init__(self, L, W, summits, seed, base_h=6.0, gully_depth=0.13):
        self.L, self.W, self.seed, self.base_h = L, W, seed, base_h
        self.gd = gully_depth
        rnd = _lcg(seed)
        self.S = []
        for (sx, sy, H, R, nr) in summits:
            self.S.append((sx, sy, H, R, nr, rnd() * 6.28, 0.10 + rnd() * 0.10,
                           1.12 + rnd() * 0.16))
        self.hmax = max(s[2] for s in summits)

    def rho(self, x, y):
        return math.sqrt((x / (self.L * 0.5)) ** 2 + (y / (self.W * 0.5)) ** 2)

    def eval(self, x, y):
        """(cota, jgheab, cota varfului castigator)"""
        rho = self.rho(x, y)
        seed = self.seed
        sk = self.base_h * _sm(1.0, 0.70, rho) * (0.80 + 0.35 * _vn(x * 0.045, y * 0.05, seed))
        best, gul, hwin = 0.0, 0.0, 0.0
        for (sx, sy, H, R, nr, ph, spur, p) in self.S:
            dx, dy = x - sx, y - sy
            r = math.hypot(dx, dy)
            th = math.atan2(dy, dx)
            Rt = R * (1.0 + 0.42 * math.cos(2.0 * th) + spur * math.cos(3.0 * th + ph))
            if r >= Rt:
                continue
            t = r / Rt
            hh = H * (1.0 - t) ** p
            # jgheaburi radiale, usor rasucite cu raza (nu spite de roata)
            w = 0.5 + 0.5 * math.cos(nr * th + ph * 2.0 + 1.6 * t)
            env = math.sin(math.pi * min(1.0, max(0.0, (t - 0.06) / 0.86)))
            g = (w ** 2.2) * env
            hh -= self.gd * H * g
            if hh > best:
                best, gul, hwin = hh, g, H
        best *= _sm(1.04, 0.80, rho)
        h = max(sk, best)
        if sk >= best:
            gul = 0.0
        h *= 1.0 + 0.035 * _vn(x * 0.23, y * 0.31, seed + 3)
        return max(0.0, h), gul, (hwin if hwin > 0 else self.hmax)

    def z(self, x, y):
        return self.eval(x, y)[0] if self.rho(x, y) < 1.0 else 0.0


def _heightfield_solid(b, field, slot):
    """Grila pe patratul [-1,1]^2 mapata pe elipsa L x W (ca la build_tf_horizon):
    muchia patratului = conturul elipsei, la z=0; suprafata de sus din triunghiuri
    (diagonala urmareste creasta), baza = evantai din centru -> volum INCHIS."""
    L, W, seed = field.L, field.W, field.seed
    nu = int(round(L / GRID))
    nv = int(round(W / GRID))
    cell_x, cell_y = L / float(nu), W / float(nv)
    grid = {}
    for i in range(nu + 1):
        for j in range(nv + 1):
            u = -1.0 + 2.0 * i / nu
            v = -1.0 + 2.0 * j / nv
            border = i in (0, nu) or j in (0, nv)
            x = L * 0.5 * u * math.sqrt(max(0.0, 1.0 - v * v * SQ))
            y = W * 0.5 * v * math.sqrt(max(0.0, 1.0 - u * u * SQ))
            z = SKIRT
            if not border:
                x += (_h01(i, j, seed) - 0.5) * 0.6 * cell_x
                y += (_h01(j, i, seed + 7) - 0.5) * 0.6 * cell_y
                z = max(SKIRT, field.z(x, y))
            grid[(i, j)] = b.bm.verts.new((x, y, z))
    # varfurile: cel mai apropiat vertex de grila se muta FIX pe varf, altfel
    # jitterul rateaza apexul si piramida iese cu crestetul tocit (dom)
    for (sx, sy, H, *_r) in field.S:
        k = min(((i, j) for i in range(1, nu) for j in range(1, nv)),
                key=lambda ij: (grid[ij].co.x - sx) ** 2 + (grid[ij].co.y - sy) ** 2)
        grid[k].co = Vector((sx, sy, max(SKIRT, field.z(sx, sy))))
    faces = []

    def tri(a, c, d):
        f = b.bm.faces.new([a, c, d])
        f[b.slot] = slot
        faces.append(f)

    for i in range(nu):
        for j in range(nv):
            p00, p10 = grid[(i, j)], grid[(i + 1, j)]
            p11, p01 = grid[(i + 1, j + 1)], grid[(i, j + 1)]
            if p00.co.z + p11.co.z >= p10.co.z + p01.co.z:
                tri(p00, p10, p11)
                tri(p00, p11, p01)
            else:
                tri(p00, p10, p01)
                tri(p10, p11, p01)
    loop = [grid[(i, 0)] for i in range(nu)] + [grid[(nu, j)] for j in range(nv)] \
        + [grid[(i, nv)] for i in range(nu, 0, -1)] + [grid[(0, j)] for j in range(nv, 0, -1)]
    # poala verticala de SKIRT m pana la talpa: fara ea, fetele de pe contur (cota ~0)
    # stateau coplanare cu evantaiul de baza si se bateau in adancime (z-fighting)
    bot = [b.bm.verts.new((v.co.x, v.co.y, 0.0)) for v in loop]
    n = len(loop)
    for k in range(n):
        f = b.bm.faces.new([bot[k], bot[(k + 1) % n], loop[(k + 1) % n], loop[k]])
        f[b.slot] = slot
        faces.append(f)
    c = b.bm.verts.new((0.0, 0.0, 0.0))
    for k in range(n):
        f = b.bm.faces.new([bot[(k + 1) % n], bot[k], c])
        f[b.slot] = slot
    return faces


def _clump(b, field, cx, cy, r, hh, slot, seed):
    """Un bulgare de padure (masa joasa): dom fatetat inchis, 8 laturi x 4 inele,
    talpa ingropata 1 m in relief."""
    z0 = max(0.0, field.z(cx, cy) - 1.0)
    ring = [(z0 + hh * t, r * f, r * 0.86 * f, cx, cy)
            for t, f in ((0.0, 0.86), (0.30, 1.0), (0.66, 0.80), (0.92, 0.40))]
    lp, _ = ring_points(ring, 8, seed, 0.12)
    n0 = len(b.bm.faces)
    faceted_shell(b, lp, slot, top_pt=Vector((cx, cy, z0 + hh)))
    faces = list(b.bm.faces)[n0:]
    tone = b.bm.faces.layers.float["tone"]
    for f in faces:
        # ton din cota pe bulgare (normalele se recalculeaza abia la to_object):
        # poala in umbra coroanei, crestetul luminat
        up = (f.calc_center_median().z - z0) / hh
        f[tone] = 0.72 + 0.24 * max(0.0, min(1.0, up))
    return faces


def _ridge(name, seed, L, W, summits, n_base, n_gully, base_h=6.0):
    """Lista de elemente comuna (fiecare `build_ridge_*` o numara pe a lui):

    1. CORPUL: relief pe o elipsa L x W, grila de 3 m cu jitter, inchis cu evantai la
       baza; varfurile din `summits`, fiecare cu 2 arete pe lungime si `nr` coaste
       radiale despartite de jgheaburi; seile cad sub 70% din varful mai mic.
    2. DARELE DE MOLOZ (CORAL_SAND): fetele din jgheaburi (`gully` > 0,30) intre
       linia padurii si ~90% din varf, plus conul de la gura jgheabului -> fasii
       deschise care coboara pe flanc, cate una pe jgheab.
    3. PADUREA (TROPICAL_GREEN, ~14% DRY_VEGETATION pe petice de 7 m): brau pana la
       7-12 m, urca pe jgheaburi cu ~12% din varf; plus `n_base` BULGARI de padure
       (3,2-5,5 m raza, 4-6,5 m inaltime) pe poale, de jur imprejur, si `n_gully`
       bulgari mici urcati pe jgheaburi -> silueta de la baza e zimtata de coroane.
    4. CALCARUL (MARBLE_GREY): tot restul; fetele abrupte mai inchise (ton 0,86),
       cele care privesc in sus luminoase (ton 1,0).
    Fara calota, fara zapada."""
    field = RidgeField(L, W, summits, seed, base_h=base_h)
    b = Builder()
    # stratul de ton se creeaza INAINTE de geometrie: un strat nou invalideaza
    # referintele python la fetele deja facute
    tone = b.bm.faces.layers.float.new("tone")
    faces = _heightfield_solid(b, field, ROCK)

    def forest_line(x, y, g, hloc):
        return 7.0 + 5.0 * (0.5 + 0.5 * _vn(x * 0.035, y * 0.04, seed + 9)) + 0.12 * hloc * g

    def classify(c, n):
        _, g, hloc = field.eval(c.x, c.y)
        zf = forest_line(c.x, c.y, g, hloc)
        if c.z < 2.5 or (c.z < zf and n.z > 0.30):
            dry = _h01(math.floor(c.x / 7.0), math.floor(c.y / 7.0), seed + 5) < 0.14
            return DRY if dry else FOREST
        if g > 0.30 and c.z < 0.90 * hloc and n.z > 0.20:
            return SCREE
        if g > 0.16 and c.z < zf + 7.0 and n.z > 0.35:       # conul de la gura jgheabului
            return SCREE
        return ROCK

    b.bm.normal_update()
    for f in faces:
        c = f.calc_center_median()
        s = classify(c, f.normal)
        f[b.slot] = s
        nz = f.normal.z
        if s == ROCK:
            f[tone] = 0.86 + 0.14 * max(0.0, min(1.0, (nz - 0.25) / 0.6))
        elif s == SCREE:
            f[tone] = 0.96 + 0.04 * max(0.0, min(1.0, nz))
        else:
            f[tone] = 0.84
    rnd = _lcg(seed + 31)
    clumps = 0
    for k in range(n_base):
        a = 2.0 * math.pi * (k + 0.5 * (rnd() - 0.5)) / n_base
        rr = 0.80 + 0.15 * rnd()
        cx = math.cos(a) * L * 0.5 * rr
        cy = math.sin(a) * W * 0.5 * rr
        slot = DRY if rnd() < 0.18 else FOREST
        _clump(b, field, cx, cy, 3.2 + 2.3 * rnd(), 4.0 + 2.5 * rnd(), slot, seed + k)
        clumps += 1
    tries = 0
    placed = 0
    while placed < n_gully and tries < 4000:
        tries += 1
        cx = (rnd() - 0.5) * L * 0.85
        cy = (rnd() - 0.5) * W * 0.85
        if field.rho(cx, cy) > 0.85:
            continue
        h, g, hloc = field.eval(cx, cy)
        if g < 0.30 or not (0.14 * hloc < h < 0.36 * hloc):
            continue
        slot = DRY if rnd() < 0.18 else FOREST
        _clump(b, field, cx, cy, 2.4 + 1.6 * rnd(), 3.0 + 2.0 * rnd(), slot, seed + 500 + placed)
        placed += 1
        clumps += 1
    b.bm.normal_update()
    print("RIDGE %s: %d bulgari de padure (%d pe jgheaburi)" % (name, clumps, placed))
    return settle(b, name)


def settle(b, name):
    """Muta corpul: bbox centrat pe XY, baza la z=0 (originea nodului la baza)."""
    vs = b.bm.verts
    xs = [v.co.x for v in vs]; ys = [v.co.y for v in vs]; zs = [v.co.z for v in vs]
    d = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
    for v in vs:
        v.co += d
    return b.to_object(name)


def build_ridge_a():
    """ApuanRidge_A (decuparea `apuan_ridge.png`) -- LISTA: elipsa 236 x 72 m;
    3 VARFURI: stanga cel mai inalt (40 m, x -58), mijloc mic (28 m, x +4), dreapta
    (36 m, x +62); planșa: stanga y 20 px, dreapta y 50 px (~0,9), mijloc y 110 px
    (~0,7). 9-11 coaste/jgheaburi pe varf. Padure: 64 bulgari pe poale, 18 pe jgheaburi.
    h/l: planșa ~0,15 (vazuta usor de sus, poalele din fata la y 300 px), GLB 40/236 =
    0,17."""
    summits = [(-58.0, 2.0, 40.0, 70.0, 11), (4.0, -4.0, 28.0, 46.0, 9),
               (62.0, 3.0, 36.0, 64.0, 10)]
    return _ridge("ApuanRidge_A", 7101, 236.0, 72.0, summits, 64, 18)


def build_ridge_b():
    """ApuanRidge_B (decuparea `apuan_ridge_b.png`, varianta cu MAI MULTE varfuri) --
    LISTA: elipsa 200 x 92 m (masiv adanc, planșa e vazuta de sus); 3 VARFURI mari
    (stanga 46 m, centru 52 m, dreapta 47 m) + 2 DINTI secundari ingusti (38 si 39 m,
    raza 24, in spatele seilor, ca acele mici din planșa). 9-12 coaste pe varf.
    Padure: 64 bulgari pe poale, 22 pe jgheaburi (planșa: padurea urca pana la
    jumatatea flancurilor)."""
    summits = [(-66.0, 6.0, 46.0, 50.0, 10), (-34.0, 12.0, 38.0, 24.0, 8),
               (2.0, -6.0, 52.0, 54.0, 12), (36.0, 14.0, 39.0, 24.0, 8),
               (66.0, -2.0, 47.0, 50.0, 11)]
    return _ridge("ApuanRidge_B", 7202, 200.0, 92.0, summits, 64, 22, base_h=7.0)


def build_ridge_c():
    """ApuanRidge_C (fara decupare proprie: a treia silueta, ca sa difere de A si B)
    -- LISTA: elipsa 168 x 66 m; 2 VARFURI: CORNUL de 58 m (x -18, raza mica, flancuri
    abrupte) si UMARUL de 40 m (x +44). Saua la ~22 m. 11 si 9 coaste. Padure: 50
    bulgari pe poale, 14 pe jgheaburi."""
    summits = [(-18.0, 0.0, 58.0, 58.0, 11), (44.0, 4.0, 40.0, 48.0, 9)]
    return _ridge("ApuanRidge_C", 7303, 168.0, 66.0, summits, 50, 14)


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


def emit(obj):
    _split_all_edges(obj)
    st = finish(obj, bevel=0.0, ao=AO_RIDGE, origin=None, smooth_angle=None)
    _flatten_ao(obj)
    _apply_tone(obj)
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    L = max(xs) - min(xs)
    nb = int(L / 2.0)
    col = [0.0] * nb
    for v in me.vertices:
        k = min(nb - 1, max(0, int((v.co.x - min(xs)) / L * nb)))
        col[k] = max(col[k], v.co.z)
    pk = _peaks(col, L / nb, L * 0.5, 6.0)
    # aria pe sloturi (din UV-ul colapsat)
    uv = me.uv_layers.active
    area = {}
    tot = 0.0
    for poly in me.polygons:
        s = int(uv.data[poly.loop_indices[0]].uv[0] * 32)
        area[s] = area.get(s, 0.0) + poly.area
        tot += poly.area
    share = {k: round(100.0 * v / tot, 1) for k, v in sorted(area.items())}
    d = obj.dimensions
    results.append((obj.name, st["tris"], d.x, d.y, d.z, pk, share))
    return obj


ra, rb, rc = build_ridge_a(), build_ridge_b(), build_ridge_c()
built = [emit(ra), emit(rb), emit(rc)]
_, sz = export_glb(built, "carrara/effects/carrara_horizon.glb")
print("export: carrara/effects/carrara_horizon.glb (%.0f KB)" % (sz / 1024.0))
print()
total = 0
for name, tris, dx, dy, dz, pk, share in results:
    total += tris
    print("%-14s tris=%6d  %.1f x %.1f x %.1f m" % (name, tris, dx, dy, dz))
    print("    varfuri (x, cota, proeminenta >= 6 m): %s" % (pk,))
    print("    aria pe sloturi %%: %s  (29 calcar, 19 moloz, 21 padure, 13 uscat)" % (share,))
print("TOTAL horizon: %d tris" % total)

for i, o in enumerate(built):
    o.location.x = i * 260.0
save_blend(built, "carrara_horizon.blend")
