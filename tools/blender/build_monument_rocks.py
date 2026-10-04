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
    A_I, B_I, N_I = 7.9, 9.4, 2.4          # intradosul nominal
    X_OUT, FLARE = 13.8, 1.3               # marginea exterioara a picioarelor
    RING = 3.2                             # grosimea inelului din jurul golului

    def I_pt(th):
        return _super_pt(A_I, B_I, th, N_I)

    def O_pt(th):                            # directia radiala (doar directie)
        x, z = _super_pt(X_OUT, 12.6, th, 2.7)
        return (x, z)

    def R_pt(th):                            # marginea exterioara a inelului
        I, O = I_pt(th), O_pt(th)
        d = (O[0] - I[0], O[1] - I[1])
        ln = math.hypot(*d) or 1.0
        return (I[0] + d[0] / ln * RING, I[1] + d[1] / ln * RING)

    def x_out(z):                            # talpa evazata pe exterior
        return X_OUT + FLARE * max(0.0, 1.0 - z / 4.5) ** 1.5

    def top_nom(x):                          # varful ~plat, putin mai jos la capete
        return 12.5 - 0.6 * (abs(x) / (X_OUT + FLARE)) ** 2

    rock = Builder()
    sl = shade_by_x(ROCK, ROCK_SHADE)
    rnd = _lcg(52)

    # ---- inelul din jurul golului (blocuri pe linia mediana) ----
    ths = [math.pi * i / 400.0 for i in range(401)]
    mid = [((I_pt(t)[0] + R_pt(t)[0]) * 0.5, (I_pt(t)[1] + R_pt(t)[1]) * 0.5) for t in ths]
    cum = [0.0]
    for i in range(1, len(mid)):
        cum.append(cum[-1] + math.hypot(mid[i][0] - mid[i - 1][0], mid[i][1] - mid[i - 1][1]))
    total = cum[-1]
    ws = []
    while sum(ws) < total:
        ws.append(2.8 + 1.8 * rnd())
    k = total / sum(ws)
    breaks = [0.0]
    for w in ws:
        breaks.append(breaks[-1] + w * k)

    def th_at(s):
        lo, hi = 0, len(cum) - 1
        while hi - lo > 1:
            m = (lo + hi) // 2
            if cum[m] <= s:
                lo = m
            else:
                hi = m
        t = (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9)
        return ths[lo] + (ths[hi] - ths[lo]) * t

    def ring_cell(ta, tb, rr):
        pin, pout = [], []
        tm = (ta + tb) * 0.5
        for t in (ta, tm, tb):
            tj = t + (rr() - 0.5) * 0.05 if t != tm else t
            I, R = I_pt(tj), R_pt(tj)
            d = (R[0] - I[0], R[1] - I[1])
            ln = math.hypot(*d) or 1.0
            d = (d[0] / ln, d[1] / ln)
            lim = 0.4 if I[1] < 3.0 else 0.7
            s = -lim + (lim + 0.3) * rr()            # negativ = spre gol
            pin.append((I[0] + d[0] * s, I[1] + d[1] * s))
            s = -0.5 + 1.1 * rr()
            pout.append((R[0] + d[0] * s, R[1] + d[1] * s))
        for idx in (0, 2):                          # baza plata la sol
            if pin[idx][1] < 0.05:
                pin[idx] = (pin[idx][0], 0.0)
                pout[idx] = (pout[idx][0], 0.0)
        return pin + list(reversed(pout))

    def slabs(poly, rr, ysplit):
        """doua felii pe adancime, cu iesiri diferite"""
        for (y0, y1, side) in ((-3.7, ysplit, -1), (ysplit, 3.7, 1)):
            if side < 0:
                y0 -= (rr() - 0.35) * 0.9
            else:
                y1 += (rr() - 0.35) * 0.9
            prism_xz(rock, poly, y0, y1, sl)

    for ri in range(len(breaks) - 1):
        ta, tb = th_at(breaks[ri]), th_at(breaks[ri + 1])
        rr = _lcg(int(rnd() * 1e6))
        slabs(chamfer(ring_cell(ta, tb, rr), 0.45), rr, (rnd() - 0.5) * 2.0)

    # ---- umplutura: randuri orizontale grosiere deasupra/in afara inelului ----
    rt = []                                          # marginea inelului ca z(x)
    for t in ths:
        x, z = R_pt(t)
        rt.append((x, z))
    rt.sort()

    def g(x):                                        # cota marginii exterioare a inelului
        if x <= rt[0][0] or x >= rt[-1][0]:
            return 0.0
        lo, hi = 0, len(rt) - 1
        while hi - lo > 1:
            m = (lo + hi) // 2
            if rt[m][0] <= x:
                lo = m
            else:
                hi = m
        t = (x - rt[lo][0]) / max(rt[hi][0] - rt[lo][0], 1e-9)
        return rt[lo][1] + (rt[hi][1] - rt[lo][1]) * t

    zc = [0.0, 3.8, 7.4, 10.4]
    for ci, z0 in enumerate(zc):
        last = ci == len(zc) - 1
        xe = X_OUT - 0.55 * ci                   # fiecare rand putin mai retras (praguri)
        edges = [-xe]
        while edges[-1] < xe - 3.0:
            edges.append(edges[-1] + 3.5 + 3.0 * rnd())
        edges.append(xe)
        for xa, xb in zip(edges[:-1], edges[1:]):
            rr = _lcg(int(rnd() * 1e6))
            ztop = zc[ci + 1] + (rr() - 0.5) * 0.5 if not last else 0.0
            jit = (rr() - 0.5) * 1.3
            n = max(4, int((xb - xa) / 0.25))
            xs = [xa + (xb - xa) * j / n for j in range(n + 1)]
            lo = [max(z0, g(x) - 0.9) for x in xs]
            hi = [(top_nom(x) + jit) if last else ztop for x in xs]
            runs, run = [], []
            for j in range(n + 1):
                if hi[j] - lo[j] > 0.3:
                    run.append(j)
                else:
                    if len(run) > 1:
                        runs.append(run)
                    run = []
            if len(run) > 1:
                runs.append(run)
            for run in runs:
                low = _simplify([(xs[j], lo[j]) for j in run], 0.06)
                upp = _simplify([(xs[j], hi[j]) for j in run], 0.06)
                poly = low + list(reversed(upp))
                if ci == 0 and run[-1] == n and xb >= xe - 1e-6:      # picior dreapta: talpa
                    zz = [lo[n] + (hi[n] - lo[n]) * q / 5.0 for q in range(6)]
                    poly = low + [(x_out(z), z) for z in zz] + list(reversed(upp))[1:]
                if ci == 0 and run[0] == 0 and xa <= -xe + 1e-6:      # picior stanga: talpa
                    zz = [hi[0] - (hi[0] - lo[0]) * q / 5.0 for q in range(6)]
                    poly = [(-x_out(z), z) for z in zz] + low + list(reversed(upp))[:-1]
                if len(poly) < 4:
                    continue
                slabs(chamfer(poly, 0.45), rr, (rr() - 0.5) * 2.0)

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


if __name__ == "__main__" or True:
    emit(list(build_west_mitten()), "rocks/west_mitten.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    emit(list(build_sandstone_arch()), "rocks/sandstone_arch.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    emit(list(build_east_mitten()), "rocks/east_mitten.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    emit(list(build_merrick_butte()), "rocks/merrick_butte.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    emit(list(build_mesa_wall_module()), "rocks/mesa_wall_module.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=8000)
    report()
