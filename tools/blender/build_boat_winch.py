"""Stromboli, kit de sat — scripetele de tras barcile (brief village_kit, piesa 11).

  BoatWinch  stromboli/props/boat_winch.glb
             Boat_Winch

2 x 1 x 1 m. Tambur cu manivela pe cadru de lemn, franghie sugerata ca tor pe
tambur. Ruginit — sta pe plaja, in sare.

Se pune langa barca mica, la capatul bustenilor de rulare: impreuna spun
"barca asta se trage la mal cu mana", care e povestea plajei din Ginostra.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_boat_winch.py
"""

import math
from mathutils import Matrix, Vector

AO_WINCH = dict(samples=20, dist=1.4, gradient="vertical",
                low=0.58, high=1.00, power=0.9, floor=0.32)

WOOD_S = WOOD
METAL = RUST


if __name__ == "__main__":
    clear_built()
    b = Builder()

    # cadrul de lemn: doi montanti in A, legati jos de o talpa
    for sx in (-1, 1):
        b.box((sx * 0.42, 0.0, 0.06), (0.20, 0.85, 0.12), WOOD_S)   # talpa
        b.box((sx * 0.42, 0.0, 0.40), (0.14, 0.14, 0.68), WOOD_S)   # montant
    # traversa de sus, intre montanti
    b.box((0.0, 0.0, 0.70), (0.98, 0.12, 0.12), WOOD_S)

    # tamburul: cilindru transversal intre montanti, cu doua flanse
    b.cylinder((0.0, 0.0, 0.52), 0.17, 0.62, METAL, segments=8, axis="X")
    for sx in (-1, 1):
        b.cylinder((sx * 0.32, 0.0, 0.52), 0.23, 0.05, METAL,
                   segments=8, axis="X")

    # franghia infasurata: tor turtit peste tambur
    b.torus((0.0, 0.0, 0.52), 0.205, 0.055, WOOD_S,
            major_seg=8, minor_seg=4, axis="X")

    # manivela: brat + maner, pe partea +X
    b.box((0.46, 0.0, 0.52), (0.06, 0.30, 0.06), METAL)
    b.cylinder((0.46, 0.17, 0.52), 0.035, 0.18, METAL, segments=6, axis="Y")

    obj = b.to_object("Boat_Winch")
    stats = finish(obj, bevel=0.02, ao=AO_WINCH, origin="base")
    print("Boat_Winch %3d tris  (buget 350)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([obj], "stromboli/props/boat_winch.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
