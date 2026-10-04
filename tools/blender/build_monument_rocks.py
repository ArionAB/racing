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




def build_sandstone_arch():
    """`sandstone_arch.png` -- elemente numarate pe decupare:

    - DOUA PICIOARE masive (stanga/dreapta), late de ~4 m la baza, cu talpa
      evazata, din blocuri colturoase groase, cu iesiri/recese diferite.
    - PUNTE: ~3,3 m groasa, intradosul curbat (arc de gresie), ~7 blocuri late
      pe deschidere; extradosul aproape plat sus (umerii rotunjiti).
    - CALOTA: placa palida (bej) continua pe coama, depaseste puntea; doua
      trepte (una larga, una ingusta).
    - GROHOTIS: bolovani si falduri la picioare, doar pe EXTERIOR (golul
      ramane liber pana la sol, contractul de gol).
    - GOL: >= 14 m lat la h 0-2 m si >= 7,5 m liber (masurat ca GOL, vezi
      tools/blender/measure_arch_gap.py). Aici: intrados superelipsa a=8,0 b=8,9.
    Cote: ~24 m lat (x +-12), 13 m inalt, ~7,4 m adancime (Y, directia drumului),
    origine la baza, centrata pe drum.
    """
    A_I, B_I, N_I = 8.0, 8.9, 2.4          # intradosul (golul)
    A_O, B_O, N_O, ZC = 12.0, 12.1, 2.7, 2.5   # extradosul: vertical pana la ZC

    def intr_z(x):
        r = min(abs(x) / A_I, 1.0)
        return B_I * (1.0 - r ** N_I) ** (1.0 / N_I)

    def outer_z(x):
        r = min(abs(x) / A_O, 1.0)
        return ZC + (B_O - ZC) * (1.0 - r ** N_O) ** (1.0 / N_O)

    rock = Builder()
    sl = shade_by_x(ROCK, ROCK_SHADE)
    rnd = _lcg(41)
    slices = [(-3.7, -1.25), (-1.25, 1.25), (1.25, 3.7)]
    for si, (y0, y1) in enumerate(slices):
        # rupturi in X: mereu la +-8 (fata verticala a piciorului) si +-12
        xs = [-12.0, -8.0, 8.0, 12.0]
        k = -8.0
        while True:
            k += 2.0 + rnd() * 0.7
            if k > 6.0:
                break
            xs.append(k)
        xs += [-10.0 + (rnd() - 0.5) * 0.6, 10.0 + (rnd() - 0.5) * 0.6]
        xs = sorted(set(xs))
        for a, bx in zip(xs[:-1], xs[1:]):
            if bx - a < 0.8:
                continue
            jit = rnd() * 0.4                       # coborare a varfului coloanei
            n_s = max(2, int((bx - a) / 0.8))
            top = [(a + (bx - a) * t / n_s, 0.0) for t in range(n_s + 1)]
            top = [(x, outer_z(x) - jit) for x, _ in top]
            rtop = [(x, z) for x, z in reversed(top)]
            if abs(a) >= A_I - 1e-6 and abs(bx) >= A_I - 1e-6:
                poly = [(a, 0.0), (bx, 0.0)] + rtop       # picior: sol plat
                if bx >= 12.0 - 1e-6:                    # talpa evazata pe exterior
                    poly = [(a, 0.0), (bx + 1.1, 0.0), (bx + 0.05, 3.2)] + rtop
                if a <= -12.0 + 1e-6:
                    poly = [(a - 1.1, 0.0), (bx, 0.0)] + rtop + [(a - 0.05, 3.2)]
            else:
                n_i = max(3, int((bx - a) / 0.5))        # intradosul esantionat des
                inn = [(a + (bx - a) * t / n_i, 0.0) for t in range(n_i + 1)]
                inn = [(x, intr_z(x)) for x, _ in inn]
                poly = list(inn) + rtop
            poly = chamfer(poly, 0.3)
            f0 = (rnd() - 0.3) * 0.9                     # iesirea fetei
            b0 = (rnd() - 0.3) * 0.9
            if rnd() < 0.3:
                f0 = -0.7
            yy0 = y0 - (b0 if si == 0 else 0.0)
            yy1 = y1 + (f0 if si == 2 else 0.0)
            prism_xz(rock, poly, yy0, yy1, sl)

    cap = Builder()
    xsC = [-10.5 + i for i in range(22)]
    bot = [(x, outer_z(x) - 0.55) for x in xsC]
    top = [(x, outer_z(x) + 0.5) for x in xsC]
    prism_xz(cap, bot + list(reversed(top)), -4.3, 4.3, CAP)
    xs2 = [-8.5 + i * (17.0 / 16) for i in range(17)]
    b2 = [(x, outer_z(x) + 0.5) for x in xs2]
    t2 = [(x, outer_z(x) + 0.9) for x in xs2]
    prism_xz(cap, b2 + list(reversed(t2)), -3.1, 3.2, CAP)

    scree = Builder()
    D, HT = 4.2, 3.2
    PTS = 40
    LEGX = 10.0
    gap_x = 8.0
    for side in (-1.0, 1.0):
        tmp = Builder()
        scree_ribs(tmp, 2.6, 3.6, D, HT, [SCREE_A, SCREE_B], seed=5 + int(side + 1),
                   pts=PTS)
        scree_boulders(tmp, 2.6, 3.6, D, HT, [SCREE_A, SCREE_B], 14, 8, 4.2,
                       seed=6 + int(side + 1), pts=PTS, cx=0.0,
                       skip=lambda x, y, s=side: abs(x + s * LEGX) < gap_x + 2.7)
        # muta fusta pe picior si taie ce intra in gol
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
