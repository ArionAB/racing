"""Monument Valley -- monolitii (brief docs/asset_briefs/monumentvalley_kit.md §1.1).

  monumentvalley/rocks/west_mitten.glb   turn 30 m + deget 26 m + fusta   (PILOT)
  monumentvalley/rocks/sandstone_arch.glb   arc peste drum, gol >= 14 x 7,5 m   (mv-a)
  monumentvalley/rocks/east_mitten.glb       oglinda West Mitten, deget pe +X   (mv-a)
  monumentvalley/rocks/merrick_butte.glb     bloc lat cu contraforturi          (mv-a)
  monumentvalley/rocks/mesa_wall_module.glb  perete de masa inlantuibil 12 m    (mv-a)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_rocks.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_shapes.py")).read())

# Sloturi (brief monumentvalley_kit §0 "Sloturi pe roluri")
ROCK = TILE_TERRACOTTA     # peretele; culoarea finala o da clasa mv_sandstone
ROCK_SHADE = RUST          # fetele din umbra (RUST_METAL 10)
SCREE_A = RUST             # grohotis: fetele coastelor alternante
SCREE_B = LARCH_RUST       # 27
CAP = SAND_LIGHT           # calota palida, bej cald (SAND_LIGHT 0)

# AO: corpuri mari si convexe -> gradientul vertical face munca (baza in umbra,
# varful in soare); `dist` mare fiindca piesele au 30 m.
AO_MITTEN = dict(samples=16, dist=8.0, gradient="vertical",
                 low=0.50, high=1.0, power=0.85, floor=0.16)

clear_built()


def build_west_mitten():
    """`west_mitten.png` -- lista de elemente numarate pe decupare (inainte de
    modelare, revizuita dupa verdictul coordonatorului):

    - PERETE: un bloc cu varf PLAT; ~8 coloane late (~3 m) pe fata lunga, toate
      ajung la aceeasi cota (variatie <= 0,3 m), cu muchiile verticale teșite
      (2 fatete pe colt, fatetele spre -X mai inchise), 2 praguri orizontale
      (retrageri de ~0,5 m) la ~1/3 si ~2/3 din inaltime, si o talpa evazata
      in ultimele ~20% inainte de grohotis.
    - CALOTA: O SINGURA placa palida, bej, care depaseste peretele cu ~0,5-0,7 m
      pe tot conturul, in 2 trepte (una larga, una mai ingusta deasupra).
    - GROHOTIS: fusta cu ~28 de COASTE RADIALE (falduri de fusta) care coboara
      de la baza peretelui spre exterior, 2 praguri concentrice slabe, urca
      pana la ~1/6 din turn; bolovanii stau la margine si in vai intre
      coaste (~70 mari + ~40 mici imprastiati dincolo de margine).
    - DEGETUL: o turla separata, pe -X (in decupare apare pe dreapta), ~87% din
      turn, baza groasa (~6 m) care se ingusteaza spre ~3,5 m, 2 praguri
      orizontale, ultimii ~20% ingustati in 3 fatete pana la un varf bont;
      GOL DE CER de ~3 m intre ea si corp, pana jos unde fusta le leaga.
    Cote (contract): turn 30 m, amprenta ~24 x 13 m, deget 26 m x 4,5-6 m la
    3 m de corp pe -X, fusta pana la raza ~22 m si <= 5 m, origine la baza
    turnului.
    """
    HX, HY = 11.6, 6.2
    TOP = 29.1                       # coloanele; calota 28.6..29.6 + 29.6..30.0

    rock = Builder()
    cols = wall_columns(rock, HX, HY, TOP, ROCK, ROCK_SHADE, seed=11)

    # degetul (centru x = -18.2, margine dreapta -15.3 => 3,3 m de corp)
    tiers = [(0.0, 2.9, 2.6, 8.0, 2.5, 2.3),
             (8.0, 2.25, 2.1, 17.0, 1.95, 1.85),
             (17.0, 1.75, 1.7, 21.0, 1.5, 1.5),
             (21.0, 1.45, 1.4, 24.0, 1.0, 1.0),
             (24.0, 1.0, 1.0, 25.4, 0.55, 0.55),
             (25.4, 0.55, 0.55, 26.0, 0.2, 0.2)]
    tapered_spire(rock, -18.2, 0.0, tiers, ROCK, ROCK_SHADE, seed=3)

    cap = Builder()
    cap_slab(cap, cols, CAP, TOP - 0.5, TOP + 0.5, 0.45, 0.7)     # treapta 1
    cap_slab(cap, cols, CAP, TOP + 0.5, TOP + 0.9, -0.9, -0.9)    # treapta 2

    # grohotisul: coaste radiale
    scree = Builder()
    D, HT = 9.8, 6.8
    PTS = 56
    scree_ribs(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], seed=2, pts=PTS)
    rnd = _lcg(9)
    n_big = 0
    tries = 0
    while n_big < 90 and tries < 4000:
        tries += 1
        i = 2 * int(rnd() * PTS / 2)                  # unghi de vale (indice par)
        th = 2 * math.pi * (i + (rnd() - 0.5) * 0.8) / PTS
        d = 1.5 + (D - 1.0) * (rnd() ** 0.55)         # spre margine
        x, y = _super_pt(HX + d, HY + d, th)
        if abs(x) < HX + 1.0 and abs(y) < HY + 1.5:
            continue
        sz = 1.2 + rnd() * 2.2
        z = scree_height(x, y, HX, HY, D, HT, pts=PTS)
        if z + sz * 0.75 > 8.0:
            continue
        boulder(scree, (x, y, z + sz * 0.12), (sz * 1.2, sz, sz * 0.8),
                SCREE_A if n_big % 2 == 0 else SCREE_B, seed=100 + n_big)
        n_big += 1
    n_small = 0
    while n_small < 40:
        th = rnd() * 2 * math.pi
        d = D - 0.5 + rnd() * 3.2
        x, y = _super_pt(HX + d, HY + d, th)
        sz = 0.35 + rnd() * 0.55
        z = scree_height(x, y, HX, HY, D, HT, pts=PTS)
        boulder(scree, (x, y, z + sz * 0.15), (sz * 1.3, sz, sz * 0.7),
                SCREE_A if n_small % 2 else SCREE_B, seed=300 + n_small)
        n_small += 1

    return (to_obj(rock, "Mitten_Rock"), to_obj(scree, "Mitten_Scree"),
            to_obj(cap, "Mitten_Cap"))




def _simplify(pts, eps):
    """Scoate punctele aproape coliniare (Douglas-Peucker); capetele raman."""
    if len(pts) < 3:
        return list(pts)
    (x0, z0), (x1, z1) = pts[0], pts[-1]
    dx, dz = x1 - x0, z1 - z0
    ln = math.hypot(dx, dz) or 1.0
    best, bi = -1.0, 0
    for i in range(1, len(pts) - 1):
        d = abs((pts[i][0] - x0) * dz - (pts[i][1] - z0) * dx) / ln
        if d > best:
            best, bi = d, i
    if best <= eps:
        return [pts[0], pts[-1]]
    return _simplify(pts[:bi + 1], eps)[:-1] + _simplify(pts[bi:], eps)


def build_sandstone_arch():
    """`sandstone_arch.png` -- elemente numarate pe decupare (rev. 4: masa de
    piatra cu o GAURA, nu o banda curbata de dovezi):

    - SILUETA: o placa lata cu varful ~orizontal la ~12,5 m pe toata latimea
      (mai jos cu ~0,5 m spre capete, neregulat +-0,5 m); deasupra golului
      ~3,5-4 m de piatra, deasupra umerilor mult mai mult (timpanele sunt
      umplute cu blocuri).
    - BLOCURI: 4 randuri orizontale grosiere (3-3,8 m, fiecare mai retras cu 0,55 m) de blocuri late de 3,5-6,5 m,
      fiecare teșit si decalat 0,3-0,8 m; in jurul golului un inel de blocuri
      (3,2 m) care da intradosul; fiecare celula are 2 felii pe adancime (Y) cu
      iesiri diferite.
    - PICIOARE: ~7 m late la baza (talpa evazata), din aceleasi blocuri.
    - INTRADOS: nu e semicerc curat: blocurile intra in gol cu max 0,4 m (jos) /
      0,7 m; nominal a=7,9 b=9,4.
    - CALOTA: 5 placi plate separate (goluri 0,3 m, inaltimi 12,8-13,1 m).
    - GROHOTIS: bolovani si falduri la picioare, doar pe EXTERIOR (golul liber).
    - GOL: >= 14 m la h 0-2 m si >= 7,5 m liber (measure_arch_gap.py).
    Cote: ~28 m lat (cu talpa), 13 m inalt, ~7,4 m adancime (Y), origine la baza.
    """
    A_I, B_I, N_I = 8.1, 9.5, 2.4          # intradosul nominal (golul = placa dintre fatete)
    X_OUT, FLARE = 13.8, 1.3               # marginea exterioara a picioarelor

    def f_int(x):                          # cota intradosului nominal la abscisa x
        t = min(1.0, abs(x) / A_I)
        return B_I * max(0.0, 1.0 - t ** N_I) ** (1.0 / N_I)

    rock = Builder()
    sl = shade_by_x(ROCK, ROCK_SHADE)
    rnd = _lcg(52)

    def clip_faces(faces, p0, n):
        """Taie un poliedru CONVEX (lista de fete = liste de Vector) cu semi-
        spatiul n.(v-p0) >= 0 si acopera taietura cu o fata orientata spre -n
        (e fata intradosului: o fatata larga, planara, a stancii)."""
        out, cut = [], []
        for fv in faces:
            keep = []
            m = len(fv)
            for i in range(m):
                a, b = fv[i], fv[(i + 1) % m]
                da, db = n.dot(a - p0), n.dot(b - p0)
                if da >= 0:
                    keep.append(a)
                if (da > 1e-9 and db < -1e-9) or (da < -1e-9 and db > 1e-9):
                    q = a + (b - a) * (da / (da - db))
                    keep.append(q)
                    cut.append(q)
                elif abs(da) <= 1e-9:
                    cut.append(a)
            if len(keep) >= 3:
                out.append(keep)
        if len(cut) >= 3:
            uniq = []
            for q in cut:
                if all((q - u).length > 1e-5 for u in uniq):
                    uniq.append(q)
            if len(uniq) >= 3:
                c = sum(uniq, Vector()) / len(uniq)
                ref = (uniq[0] - c).normalized()
                ax2 = n.cross(ref).normalized()
                uniq.sort(key=lambda q: math.atan2((q - c).dot(ax2), (q - c).dot(ref)))
                nn = (uniq[1] - uniq[0]).cross(uniq[2] - uniq[1])
                if nn.dot(n) > 0:           # trebuie sa priveasca spre -n (in gol)
                    uniq.reverse()
                out.append(uniq)
        return out

    def loft_faces(bottom, z0, top, z1):
        n = len(bottom)
        fs = []
        for i in range(n):
            j = (i + 1) % n
            fs.append([Vector((bottom[i][0], bottom[i][1], z0)), Vector((bottom[j][0], bottom[j][1], z0)),
                       Vector((top[j][0], top[j][1], z1)), Vector((top[i][0], top[i][1], z1))])
        fs.append([Vector((p[0], p[1], z1)) for p in top])
        fs.append([Vector((p[0], p[1], z0)) for p in reversed(bottom)])
        return fs

    def column(x0, x1, xl, xr, ytop, rr, hc, outer_l=0.0, outer_r=0.0, tap_l=0.0, tap_r=0.0):
        """O coloana verticala (sector de perete): plan 6 puncte cu fata in V pe
        ambele parti (+Y / -Y), 3 etaje cu praguri in Y (retrageri), talpa
        evazata, teșite pe muchii; jos se taie cu planul fatetei de intrados.
        xl/xr = marginile reale ale coloanei (fara teseala); outer_* = cat iese
        talpa pe marginea exterioara a piciorului."""
        yf = ytop * (0.62 + 0.2 * rr()) if rr() < 0.4 else ytop * (0.93 + 0.1 * rr())
        yb = ytop * (0.62 + 0.2 * rr()) if rr() < 0.4 else ytop * (0.93 + 0.1 * rr())
        vf, vb = 0.5 + 0.8 * rr(), 0.5 + 0.8 * rr()
        xm = x0 + (x1 - x0) * (0.35 + 0.3 * rr())
        b1 = hc * (0.24 + 0.16 * rr())
        b2 = hc * (0.56 + 0.16 * rr())
        led = (0.0, 0.3 * (0.4 + 1.2 * rr()), 0.6 * (0.4 + 1.2 * rr()))

        def plan(dy, dxl, dxr):   # dxl/dxr > 0 = iese, < 0 = retras
            a, b = x0 - dxl, x1 + dxr
            return [(a, -(yb + dy)), (xm, -(yb + dy + vb)), (b, -(yb + dy)),
                    (b, yf + dy), (xm, yf + dy + vf), (a, yf + dy)]

        faces = []
        zs = [b1, b2, hc]
        # talpa: de la 0 pana la ~4 m, evazata si in Y
        fh = min(4.2 * (0.8 + 0.4 * rr()), b1)
        faces += loft_faces(chamfer(plan(0.45, outer_l, outer_r), 0.4), 0.0,
                            chamfer(plan(0.02, outer_l * 0.05, outer_r * 0.05), 0.4), fh)
        z_prev = fh
        tops = [(fh, b1, 0.0, led[0]), (b1, b2, 0.0, led[1]), (b2, hc, 0.0, led[2])]
        for (za, zb, _, dy) in tops:
            tp = 1.0 - 0.06 * (zb / hc)
            tz = zb / hc                         # taper pe marginea exterioara a piciorului
            pl = plan(-dy - (1 - tp) * 2.0, -tap_l * tz, -tap_r * tz)
            faces += loft_faces(chamfer(pl, 0.4), za, chamfer(pl, 0.4), zb)
        # fateta de intrados (doar pentru coloanele de deasupra golului)
        if abs(xl) < A_I - 1e-3 or abs(xr) < A_I - 1e-3:
            za_, zb_ = f_int(xl), f_int(xr)
            nrm = Vector((-(zb_ - za_), 0.0, (xr - xl)))
            nrm.normalize()
            # fateta se impinge putin in solid (0,0 m) -> fara supraunire de gol
            faces = clip_faces(faces, Vector((xl, 0.0, za_)), nrm)
        for fv in faces:
            _face(rock, fv, sl)

    # ---- imparteala pe X in coloane (muchiile din gol: fatete largi ale intradosului) ----
    inner = [-A_I, -6.7, -4.8, -2.4, 0.2, 2.6, 4.9, 6.8, A_I]
    wl = 1.7 + 0.6 * rnd()
    left_out = [-X_OUT, -X_OUT + wl, -X_OUT + wl + 1.7 + 0.6 * rnd(), -A_I]
    wr = 1.7 + 0.6 * rnd()
    right_out = [A_I, X_OUT - wr - 1.7 - 0.6 * rnd(), X_OUT - wr, X_OUT]
    edges = left_out[:-1] + inner + right_out[1:]
    for k in range(len(edges) - 1):
        xl, xr = edges[k], edges[k + 1]
        rr = _lcg(int(rnd() * 1e6))
        hc = 12.45 - 0.55 * (abs((xl + xr) * 0.5) / (X_OUT + FLARE)) ** 2 - rr() * 0.5
        outer_l = FLARE if k == 0 else 0.0
        outer_r = FLARE if k == len(edges) - 2 else 0.0
        # micro-rost intre coloane: fiecare margine interioara se retrage 0,06 (crapatura)
        column(xl + 0.06, xr - 0.06, xl, xr, 3.7, rr, hc, outer_l, outer_r,
               tap_l=1.3 if k == 0 else 0.0,
               tap_r=1.3 if k == len(edges) - 2 else 0.0)

    # ---- calota: 5 placi PLATE, separate, inaltimi diferite ----
    cap = Builder()
    cuts = [-12.4, -7.6, -2.9, 1.9, 6.4, 12.4]
    cuts = [cuts[0]] + [c + (rnd() - 0.5) * 0.8 for c in cuts[1:-1]] + [cuts[-1]]
    for i in range(5):
        a, b = cuts[i] + 0.15, cuts[i + 1] - 0.15
        zt = 12.8 + 0.3 * rnd()
        zb = 11.4 + 0.4 * rnd()
        yb = -(3.2 + 1.0 * rnd())
        yf = 3.2 + 1.0 * rnd()
        poly = chamfer([(a, zb), (b, zb), (b, zt), (a, zt)], 0.25)
        prism_xz(cap, poly, yb, yf, CAP)

    scree = Builder()
    D, HT = 4.2, 3.2
    PTS = 40
    LEGX = 11.6
    gap_x = A_I
    for side in (-1.0, 1.0):
        tmp = Builder()
        scree_ribs(tmp, 3.8, 3.6, D, HT, [SCREE_A, SCREE_B], seed=5 + int(side + 1),
                   pts=PTS)
        scree_boulders(tmp, 3.8, 3.6, D, HT, [SCREE_A, SCREE_B], 14, 8, 4.2,
                       seed=6 + int(side + 1), pts=PTS, cx=0.0,
                       skip=lambda x, y, s=side: abs(x + s * LEGX) < gap_x + 2.7)
        for v in tmp.bm.verts:
            v.co.x += side * LEGX
            ax = abs(v.co.x)
            if ax < gap_x + 1.2:
                v.co.z *= max(0.0, (ax - gap_x) / 1.2)
            if ax < gap_x:                       # nimic nu trece de fata golului
                v.co.x = side * gap_x
        dead = [f for f in tmp.bm.faces
                if all(abs(v.co.x) < gap_x + 0.05 for v in f.verts)]
        bmesh.ops.delete(tmp.bm, geom=dead, context="FACES")
        for f in tmp.bm.faces:
            _face(scree, [v.co.copy() for v in f.verts], f[tmp.slot])
        tmp.bm.free()

    return (to_obj(rock, "Arch_Rock"), to_obj(scree, "Arch_Scree"),
            to_obj(cap, "Arch_Cap"))


def build_east_mitten():
    """`east_mitten.png` -- lista numarata pe decupare (oglinda West Mitten):

    - PERETE: bloc cu varf plat, ~16 coloane late (1,8-3,6 m) pe tot conturul
      (patru fete), 2 praguri, taper ~10%, talpa evazata; imparteala si
      iesirile DIFERITE de West (seed 23, coloane mai inguste).
    - CALOTA: placa palida cu 2 trepte, depaseste peretele.
    - GROHOTIS: fusta cu ~28 coaste radiale pana la ~6,2 m langa perete,
      bolovani la margine si in vai.
    - DEGETUL: turla separata pe +X (spre drum), 23 m (85% din turn),
      baza ~5 m -> varf bont, 2 praguri, gol de cer de ~3 m fata de corp.
    Cote: turn 27 m, amprenta ~22 x 12 m, deget 23 m, origine la baza turnului.
    """
    HX, HY = 10.6, 5.7
    TOP = 26.1                        # coloane; calota 25.6..26.6 + 26.6..27.0
    rock = Builder()
    cols = wall_columns(rock, HX, HY, TOP, ROCK, ROCK_SHADE, seed=23, wmin=1.8,
                        wmax=3.6, flare_h=5.2, foot=1.2)
    cx = 17.1
    tiers = [(0.0, 2.5, 2.3, 7.0, 2.2, 2.0),
             (7.0, 1.95, 1.85, 15.0, 1.7, 1.6),
             (15.0, 1.55, 1.5, 18.5, 1.3, 1.3),
             (18.5, 1.25, 1.2, 21.0, 0.9, 0.9),
             (21.0, 0.9, 0.9, 22.2, 0.5, 0.5),
             (22.2, 0.5, 0.5, 23.0, 0.18, 0.18)]
    tapered_spire(rock, cx, 0.0, tiers, ROCK, ROCK_SHADE, seed=8)
    cap = Builder()
    cap_slab(cap, cols, CAP, TOP - 0.5, TOP + 0.5, 0.45, 0.7)
    cap_slab(cap, cols, CAP, TOP + 0.5, TOP + 0.9, -0.9, -0.9)
    scree = Builder()
    D, HT, PTS = 9.0, 6.2, 56
    scree_ribs(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], seed=14, pts=PTS)
    scree_boulders(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], 80, 36, 7.5,
                   seed=15, pts=PTS)
    return (to_obj(rock, "EastMitten_Rock"), to_obj(scree, "EastMitten_Scree"),
            to_obj(cap, "EastMitten_Cap"))


def build_merrick_butte():
    """`merrick_butte.png` -- lista numarata pe decupare:

    - BLOC LAT cu varf plat; ~14 coloane late (2-4 m) pe fata lunga (+Y) si
      imprejur, praguri la 1/3 si 2/3, taper ~8%.
    - CONTRAFORTURI: 3 stalpi lati (4-5 m) lipiti de fata lunga, de inaltimi
      diferite (13 / 18 / 11 m), evazati jos, cu umar inclinat spre perete.
    - CALOTA: placa palida continua in 2 trepte (plata, in trepte).
    - GROHOTIS: fusta joasa si lata, coaste radiale, ~90 bolovani colturosi
      imprastiati pe margine.
    Cote: turn 24 m, amprenta ~30 x 18 m, fara deget, origine la baza.
    """
    HX, HY = 14.4, 8.4
    TOP = 23.1                        # calota 22.6..23.6 + 23.6..24.0
    rock = Builder()
    cols = wall_columns(rock, HX, HY, TOP, ROCK, ROCK_SHADE, seed=31, wmin=2.2,
                        wmax=4.0, flare_h=5.0, foot=1.3, taper=0.08)
    for k, (bx, bh, bw) in enumerate([(-8.0, 13.0, 4.4), (0.8, 18.0, 5.0),
                                      (9.2, 11.0, 4.2)]):
        buttress(rock, bx, HY - 0.3, bw, 2.0, bh, ROCK, ROCK_SHADE, seed=50 + k)
    cap = Builder()
    cap_slab(cap, cols, CAP, TOP - 0.5, TOP + 0.5, 0.45, 0.7)
    cap_slab(cap, cols, CAP, TOP + 0.5, TOP + 0.9, -1.1, -1.1)
    scree = Builder()
    D, HT, PTS = 9.5, 5.4, 64
    scree_ribs(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], seed=17, pts=PTS)
    scree_boulders(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], 90, 40, 6.5,
                   seed=18, pts=PTS)
    return (to_obj(rock, "Butte_Rock"), to_obj(scree, "Butte_Scree"),
            to_obj(cap, "Butte_Cap"))


def build_mesa_wall_module():
    """`mesa_wall_module.png` -- lista numarata pe decupare (un modul din perete):

    - COLOANE: 5 pe modul (2 de capat identice + 3 in mijloc), late 2-3,5 m,
      cu fata (+X) si spatele (-X) in V, iesiri/recese variate, 2 praguri,
      taper doar pe X; capetele plane la y = +-6 m, IDENTICE.
    - CALOTA: placa continua palida, depaseste peretele pe X, capete plane.
    - GROHOTIS: coaste perpendiculare pe perete (perioada 3 m, deci capetele
      au acelasi profil), <= 3 m la picior pe fata, ~2 m pe spate; cativa
      bolovani mici, departe de capete.
    Cote: 12 m lung (Y), 14 m inalt, 6 m adanc (X -3..+3), origine la baza,
    centrat pe X/Y.
    """
    HL = 6.0
    TOP = 13.2                        # calota 12.7..13.6 + 13.6..14.0
    rock = Builder()
    mesa_run(rock, HL, 3.0, -3.0, TOP, ROCK, ROCK_SHADE, seed=61)
    cap = Builder()
    for (z0, z1, ox) in ((TOP - 0.5, TOP + 0.4, 0.5), (TOP + 0.4, TOP + 0.8, -0.2)):
        poly = [(-3.0 - ox - 0.3, -HL), (3.0 + ox + 0.3, -HL), (3.0 + ox + 0.3, HL),
                (-3.0 - ox - 0.3, HL)]
        loft(cap, poly, z0, poly, z1, CAP, cap_bottom=False)
    scree = Builder()
    mesa_scree(scree, HL, 3.0, 1.0, 5.5, 2.5, [SCREE_A, SCREE_B])
    mesa_scree(scree, HL, -3.0, -1.0, 4.0, 1.6, [SCREE_A, SCREE_B])
    rnd = _lcg(77)
    for n in range(9):
        if n < 6:
            x = 3.0 + 4.5 + rnd() * 1.6
        else:
            x = -(3.0 + 3.6 + rnd() * 1.0)
        y = (rnd() - 0.5) * 8.0
        sz = 0.5 + rnd() * 0.8
        boulder(scree, (x, y, sz * 0.12), (sz * 1.2, sz, sz * 0.8),
                SCREE_A if n % 2 else SCREE_B, seed=400 + n)
    return (to_obj(rock, "Mesa_Rock"), to_obj(scree, "Mesa_Scree"),
            to_obj(cap, "Mesa_Cap"))


ONLY = os.environ.get("MV_ONLY", "")     # ex. MV_ONLY=sandstone_arch: reface doar piesa


def _want(name):
    return not ONLY or ONLY == name


if __name__ == "__main__" or True:
    if _want("west_mitten"):
        emit(list(build_west_mitten()), "rocks/west_mitten.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    if _want("sandstone_arch"):
        emit(list(build_sandstone_arch()), "rocks/sandstone_arch.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    if _want("east_mitten"):
        emit(list(build_east_mitten()), "rocks/east_mitten.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    if _want("merrick_butte"):
        emit(list(build_merrick_butte()), "rocks/merrick_butte.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    if _want("mesa_wall_module"):
        emit(list(build_mesa_wall_module()), "rocks/mesa_wall_module.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=8000)
    report()
