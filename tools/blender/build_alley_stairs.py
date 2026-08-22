"""Stromboli, kit de sat — scara de ulita (brief village_kit, piesa 6).

  AlleyStairs  stromboli/buildings/alley_stairs.glb
               Alley_Stairs

Modul de 4 m care urca 1.6 m pe o latime de 2 m. Se insiruie ca sa faca
ulitele in trepte ale satului.

Aici treptele sunt REALE, nu sugerate ca la scarile de pe stanca: modulul se
vede de la 5 m, de la nivelul masinii, iar contratreapta rotunjita e ce il
face varuit si nu turnat. Opt trepte de 0.20 m — cifra vine din 1.6 / 0.20,
nu din ochi.

Muretul e pe o SINGURA parte (+X): pe cealalta scara se lipeste de zid sau de
casa, iar un muret pe ambele parti ar iesi tunel.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_alley_stairs.py
"""

import math
from mathutils import Matrix, Vector

AO_STAIR = dict(samples=22, dist=2.4, gradient="vertical",
                low=0.62, high=1.00, power=0.9, floor=0.32)

RUN, WIDE, RISE = 4.0, 2.0, 1.6
STEPS = 8
LIME = FOAM_WHITE


if __name__ == "__main__":
    clear_built()
    b = Builder()

    step_h = RISE / STEPS
    step_d = RUN / STEPS

    # Treptele, ca volume suprapuse care se scurteaza: fiecare cutie porneste
    # din fata modulului si merge pana la capat, deci se acumuleaza in trepte
    # fara sa lase goluri intre ele.
    for i in range(STEPS):
        h = step_h * (i + 1)
        y0 = -RUN * 0.5 + step_d * i
        depth = RUN - step_d * i
        b.box((0.0, y0 + depth * 0.5, h * 0.5), (WIDE, depth, h), LIME)

    # muretul pe +X, urcand odata cu scara
    b.beam((WIDE * 0.5 + 0.13, -RUN * 0.5, 0.30),
           (WIDE * 0.5 + 0.13, RUN * 0.5, RISE + 0.30),
           (0.26, 0.46), LIME, up=(0, 0, 1))

    obj = b.to_object("Alley_Stairs")
    stats = finish(obj, bevel=0.07, ao=AO_STAIR, origin="base")
    print("Alley_Stairs %3d tris  (buget 250)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([obj], "stromboli/buildings/alley_stairs.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
