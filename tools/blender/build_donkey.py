"""Stromboli, kit de sat — magarul (brief village_kit, piesa 15).

  Donkey  stromboli/props/donkey.glb
          Donkey

1.4 m la greaban, STILIZAT si CHUNKY: proportii de jucarie (cap mare, picioare
groase), in picioare, static, fara samar.

Brief-ul cere explicit "aceeasi familie cu husky-ul de sat din kitul Baikal",
si corectia din foaia de referinta e ca magarul de acolo a iesit prea realist.
Deci reteta e cea din `build_baikal_animals.build_husky`: cutii, doua volume de
corp (piept mai inalt, crupa mai joasa), picioare din doua segmente. Nimic
organic, nimic sculptat.

Ce face magarul sa fie magar si nu cal mic: **urechile lungi** (0.30 m, adica
un sfert din inaltimea la greaban), botul gri-deschis si crucea de pe spinare.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_donkey.py
"""

import math
from mathutils import Matrix, Vector

AO_DONKEY = dict(samples=20, dist=1.6, gradient="vertical",
                 low=0.58, high=1.00, power=0.9, floor=0.34)

SH = 1.40                    # inaltime la greaban
BODY = MARBLE_GREY           # corp gri (brief: u = 0.921875 -> slot 29)
MUZZLE = ROCK_DARK           # bot/coama (brief: u = 0.140625 -> slot 4)
HOOF = VOLCANIC_BLACK

body_z = SH * 0.70


if __name__ == "__main__":
    clear_built()
    b = Builder()

    # --- corp: doua volume, ca la husky ------------------------------------
    # Pieptul mai inalt si mai lat decat crupa: un singur volum ar da butoi.
    b.box((0.0, 0.22, body_z + 0.04), (0.46, 0.62, 0.50), BODY)
    b.box((0.0, -0.36, body_z - 0.02), (0.42, 0.56, 0.44), BODY)

    # crucea de pe spinare — semnul magarului. Costa doua cutii si e
    # singurul lucru care il deosebeste de un ponei gri.
    b.box((0.0, -0.02, body_z + 0.27), (0.09, 1.10, 0.05), MUZZLE)
    b.box((0.0, 0.26, body_z + 0.27), (0.40, 0.09, 0.05), MUZZLE)

    # --- gat + cap ----------------------------------------------------------
    # Gatul urca inclinat spre fata; capul e MARE (proportie de jucarie).
    b.box((0.0, 0.62, body_z + 0.34), (0.26, 0.30, 0.44), BODY,
          rotation=Matrix.Rotation(math.radians(-22.0), 3, "X"))
    b.box((0.0, 0.84, body_z + 0.52), (0.27, 0.38, 0.30), BODY)
    # botul, mai ingust si mai deschis
    b.box((0.0, 1.04, body_z + 0.42), (0.19, 0.22, 0.19), MUZZLE)
    # narile
    b.box((0.0, 1.15, body_z + 0.40), (0.15, 0.04, 0.10), HOOF)
    # ochii
    for sx in (-1, 1):
        b.box((sx * 0.115, 0.96, body_z + 0.60), (0.035, 0.035, 0.035), HOOF)

    # --- urechile: LUNGI, semnatura magarului -------------------------------
    for sx in (-1, 1):
        b.box((sx * 0.09, 0.80, body_z + 0.82), (0.09, 0.11, 0.30), BODY,
              rotation=Matrix.Rotation(math.radians(sx * 13.0), 3, "Y"))
        # interiorul urechii, mai inchis
        b.box((sx * 0.11, 0.79, body_z + 0.84), (0.045, 0.07, 0.22), MUZZLE,
              rotation=Matrix.Rotation(math.radians(sx * 13.0), 3, "Y"))

    # coama, intre urechi si greaban
    b.box((0.0, 0.70, body_z + 0.62), (0.09, 0.42, 0.13), MUZZLE,
          rotation=Matrix.Rotation(math.radians(-26.0), 3, "X"))

    # --- picioare: GROASE, doua segmente ------------------------------------
    for sx in (-1, 1):
        for (fy, hy) in ((1, 0.40), (-1, -0.52)):
            b.box((sx * 0.17, hy, body_z - 0.30), (0.17, 0.21, 0.42), BODY)
            b.box((sx * 0.17, hy + (0.02 * fy), body_z - 0.62),
                  (0.14, 0.16, 0.36), BODY)
            # copita
            b.box((sx * 0.17, hy + (0.02 * fy), body_z - 0.82),
                  (0.15, 0.17, 0.09), HOOF)

    # --- coada --------------------------------------------------------------
    b.box((0.0, -0.66, body_z + 0.06), (0.07, 0.09, 0.34), BODY,
          rotation=Matrix.Rotation(math.radians(16.0), 3, "X"))
    b.box((0.0, -0.72, body_z - 0.20), (0.09, 0.10, 0.16), MUZZLE)

    obj = b.to_object("Donkey")
    stats = finish(obj, bevel=0.025, ao=AO_DONKEY, origin="base")
    print("Donkey %4d tris  (buget 800)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([obj], "stromboli/props/donkey.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
