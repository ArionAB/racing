"""Monument Valley -- monolitii (brief docs/asset_briefs/monumentvalley_kit.md §1.1).

  monumentvalley/rocks/west_mitten.glb   turn 30 m + deget 26 m + fusta   (PILOT)
  (urmeaza: east_mitten, merrick_butte, mesa_wall_module, sandstone_arch)

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


if __name__ == "__main__" or True:
    emit(list(build_west_mitten()), "rocks/west_mitten.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    report()
