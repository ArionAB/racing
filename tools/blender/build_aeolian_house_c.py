"""Stromboli, kit de sat — casa C (brief docs/asset_briefs/stromboli_village_kit.md, piesa 3).

  AeolianHouseC  stromboli/buildings/aeolian_house_c.glb
                 House_C

Magazia/casuta satului: 5 x 5 x 3.5 m, UN singur gol de usa, horn mic
cilindric. E piesa de umplutura a ulitei — se pune de multe ori, deci trebuie
sa fie ieftina si sa nu aiba nimic care sa se repete suparator.

De-asta n-are ferestre: brief-ul cere "un singur gol de usa", iar o casuta fara
ferestre asezata de sase ori pe ulita citeste ca sir de magazii, nu ca aceeasi
casa clonata.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_aeolian_house_c.py
"""

import math
from mathutils import Matrix, Vector

AO_HOUSE = dict(samples=24, dist=3.5, gradient="vertical",
                low=0.68, high=1.00, power=0.9, floor=0.32)

W, D, H = 5.0, 5.0, 3.5
FACADE = D * 0.5
PARAPET = 0.45

LIME = FOAM_WHITE
SHUTTER = SEA_DEEP
TERRA = TILE_TERRACOTTA


if __name__ == "__main__":
    clear_built()
    b = Builder()

    # corpul
    b.box((0.0, 0.0, H * 0.5), (W, D, H), LIME)

    # parapet pe fata si pe -X (laturile care se vad din ulita)
    pz = H + PARAPET * 0.5
    b.box((0.0, FACADE - 0.13, pz), (W, 0.26, PARAPET), LIME)
    b.box((-(W * 0.5 - 0.13), 0.0, pz), (0.26, D - 0.52, PARAPET), LIME)

    # usa: panou albastru care iese din planul fatadei, cu doi montanti
    door_w, door_h = 1.05, 2.05
    b.box((0.0, FACADE - 0.04, door_h * 0.5), (door_w, 0.16, door_h), SHUTTER)
    for sgn in (-1, 1):
        b.box((sgn * (door_w * 0.5 + 0.07), FACADE + 0.02, door_h * 0.5 + 0.07),
              (0.13, 0.10, door_h + 0.14), LIME)

    # Horn mic cilindric, cu palarie de teracota. E singurul accent de culoare
    # al piesei si singurul lucru care rupe silueta de cub — de-asta nu se
    # taie, desi costa doua primitive.
    b.cylinder((W * 0.28, -D * 0.22, H + 0.42), 0.22, 0.95, LIME, segments=6)
    b.cylinder((W * 0.28, -D * 0.22, H + 0.94), 0.30, 0.12, TERRA, segments=6)

    house = b.to_object("House_C")
    stats = finish(house, bevel=0.10, ao=AO_HOUSE, origin="base")
    print("House_C %4d tris  (buget 500)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([house], "stromboli/buildings/aeolian_house_c.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
