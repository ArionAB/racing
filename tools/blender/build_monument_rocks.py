"""Monument Valley -- monolitii (brief docs/asset_briefs/monumentvalley_kit.md §1.1).

  monumentvalley/rocks/west_mitten.glb   turn 30 m + deget 26 m + fusta   (PILOT)
  (urmeaza: east_mitten, merrick_butte, mesa_wall_module, sandstone_arch)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_monument_rocks.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_shapes.py")).read())

# Sloturi (brief monumentvalley_kit §0 "Sloturi pe roluri")
ROCK = TILE_TERRACOTTA     # peretele; culoarea finala o da clasa mv_sandstone
ROCK_SHADE = RUST          # fetele din umbra (RUST_METAL 10)
SCREE_A = RUST             # grohotis, trepte alternante
SCREE_B = LARCH_RUST       # 27
CAP = MARBLE_GREY          # calota palida 29

# AO: corpuri mari si convexe -> gradientul vertical face munca (baza in umbra,
# varful in soare); `dist` mare fiindca piesele au 30 m.
AO_MITTEN = dict(samples=16, dist=8.0, gradient="vertical",
                 low=0.50, high=1.0, power=0.85, floor=0.16)

clear_built()


def build_west_mitten():
    """`west_mitten.png` -- lista de elemente numarate pe decupare (inainte de
    modelare):

    - PERETE: un turn cu ~11 coloane verticale vizibile pe fata lunga, late de
      1-3 m, fiecare cu fateta de umbra (stanga, mai inchisa) si fateta
      luminata; coloanele de la mijloc urca toate pana sus, cele din margini
      cobor in trepte (stanga 3 trepte: ~65%, ~80%, ~88%; dreapta 3 trepte).
      Peretele se evazeaza spre talpa (contraforturi) si se ingusteaza usor in
      sus. Randare: 12 coloane, V pe fata.
    - CALOTA: strat subtire si palid doar pe coloanele inalte, contur neregulat
      (festonat), 2 trepte (una larga, una mai ingusta deasupra).
    - GROHOTIS: fusta in ~5 terase concentrice cu caneluri radiale, urcand pana
      la ~1/6 din inaltimea turnului, alternand doua nuante de rugina; ~18
      bolovani mari colturosi asezati pe terase si ~25 de pietre mici
      imprastiate dincolo de marginea fustei.
    - DEGETUL: o turla ingusta separata, pe dreapta in decupare (pe -X in
      contract, vazut din fata); ~85% din inaltimea turnului, latime ~1/5 din
      turn, 2 trepte de umar (lat jos, ingust sus), varf rotunjit-tesit, cu
      un GOL DE CER intre ea si corp pana jos, unde fusta le leaga.
    Cote (contract): turn 30 m, amprenta ~24 x 13 m, deget 26 m x 4,5 m la 3 m
    de corp pe -X, fusta pana la raza ~22 m si <= 5 m, origine la baza turnului.
    """
    HX, HY = 12.0, 6.5
    TOP = 29.1                       # coloanele de sus; +0.5 +0.4 calota = 30 m
    # inaltimile pe coloane, de la -X la +X (decupare: stanga mai joasa si mai
    # in trepte, centrul tot sus)
    heights = [21.0, 24.5, 27.0, 29.1, 29.1, 29.1, 29.1, 29.1, 29.1, 28.0,
               25.5, 22.5]
    rnd = _lcg(5)
    heights = [h if h >= TOP - 1e-6 else h + (rnd() - 0.5) * 1.0 for h in heights]

    rock = Builder()
    cols = wall_columns(rock, HX, HY, heights, ROCK, ROCK_SHADE, seed=11,
                        flare_h=6.5, jut=0.7, foot=0.8, vfront=0.55)
    # degetul: 3 coloane lipite, cea din mijloc cea mai inalta (26 m = 25.5 +
    # calota 0.5), centrat la x = -17.25 (3 m gol fata de corp, la x = -12)
    TH_H = 25.5
    parts = [(-19.9, -14.9, -2.8, 2.8, 12.5, 0.8),
             (-19.2, -15.7, -2.3, 2.3, TH_H, 0.5),
             (-19.8, -17.4, -2.5, 2.5, 19.0, 0.6)]
    tcols = spire(rock, parts, ROCK, ROCK_SHADE, seed=3, draft=0.72)

    cap = Builder()
    cap_steps(cap, cols, CAP, TOP, t1=0.5, t2=0.4)
    cap_steps(cap, tcols, CAP, TH_H, t1=0.5, t2=0.0, inset=0.1, every=99)

    # grohotisul
    scree = Builder()
    D, STEPS, HT = 9.8, 6, 4.4
    scree_skirt(scree, HX, HY, D, STEPS, HT, [SCREE_A, SCREE_B], seed=2, tilt=0.45)
    rnd = _lcg(9)
    n_big = 0
    n_small = 0
    tries = 0
    while n_big < 60 and tries < 4000:
        tries += 1
        th = rnd() * 2 * math.pi
        d = 2.0 + rnd() * (D - 1.5)
        x, y = _super_pt(HX + d, HY + d, th)
        if abs(x) < HX - 0.5 and abs(y) < HY + 1.0:
            continue
        # spatiul gol dintre turn si deget ramane liber sus: bolovanii mici
        sz = 1.3 + rnd() * 2.2
        z = scree_height(x, y, HX, HY, D, STEPS, HT)
        if z + sz * 0.75 > 4.9:
            continue
        boulder(scree, (x, y, z + sz * 0.12), (sz * 1.2, sz, sz * 0.8),
                SCREE_A if n_big % 2 == 0 else SCREE_B, seed=100 + n_big)
        n_big += 1
    while n_small < 26:
        th = rnd() * 2 * math.pi
        d = D - 0.5 + rnd() * 3.2
        x, y = _super_pt(HX + d, HY + d, th)
        sz = 0.35 + rnd() * 0.55
        z = scree_height(x, y, HX, HY, D, STEPS, HT)
        boulder(scree, (x, y, z + sz * 0.15), (sz * 1.3, sz, sz * 0.7),
                SCREE_A if n_small % 2 else SCREE_B, seed=300 + n_small)
        n_small += 1

    return (to_obj(rock, "Mitten_Rock"), to_obj(scree, "Mitten_Scree"),
            to_obj(cap, "Mitten_Cap"))


if __name__ == "__main__" or True:
    emit(list(build_west_mitten()), "rocks/west_mitten.glb", AO_MITTEN,
         keep_xy=True, bevel=0.0, smooth_angle=None, budget=12000)
    report()
