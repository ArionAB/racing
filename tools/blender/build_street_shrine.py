"""Stromboli, kit de sat — edicola de strada (brief village_kit, piesa 7).

  StreetShrine  stromboli/buildings/street_shrine.glb
                Shrine_Body / Shrine_Niche

0.8 x 0.5 x 1.5 m. Edicola alba cu fronton mic si cruce, nisa arcuita retrasa
pe slot albastru. Fara statueta (brief).

Nisa e nod separat ca sa poata primi la integrare un emisiv slab (lumanare) —
si fiindca e singura suprafata colorata a piesei, deci vrem sa o putem regla
independent.

Golul nisei chiar e retras aici, si functioneaza: corpul e o cutie, iar nisa
sta la 0.12 m in fata planului ei posterior, cu marginile corpului lasate in
jurul ei. Diferenta fata de biserica (unde nu mergea) e ca acolo panoul era
IMPINS in masa; aici masa se opreste inainte.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_street_shrine.py
"""

import math
from mathutils import Matrix, Vector

AO_SHRINE = dict(samples=20, dist=1.4, gradient="vertical",
                 low=0.66, high=1.00, power=0.9, floor=0.34)

W, D, H = 0.8, 0.5, 1.5
FACE = D * 0.5
LIME = FOAM_WHITE
NICHE = SEA_DEEP


if __name__ == "__main__":
    clear_built()

    # --- corpul: soclu + trunchi + fronton + cruce -------------------------
    b = Builder()
    # soclu putin mai lat
    b.box((0.0, 0.0, 0.11), (W + 0.14, D + 0.12, 0.22), LIME)

    # Trunchiul e SPART pe verticala in trei fasii, ca sa lase golul nisei
    # intre ele — nu o cutie plina cu un panou impins in ea (lectia bisericii).
    niche_w, niche_h = 0.42, 0.62
    niche_z = 0.86
    side = (W - niche_w) * 0.5
    body_top = 1.22
    for sx in (-1, 1):
        b.box((sx * (niche_w * 0.5 + side * 0.5), 0.0, (0.22 + body_top) * 0.5),
              (side, D, body_top - 0.22), LIME)
    # sub nisa si peste ea
    b.box((0.0, 0.0, (0.22 + (niche_z - niche_h * 0.5)) * 0.5),
          (niche_w, D, niche_z - niche_h * 0.5 - 0.22), LIME)
    b.box((0.0, 0.0, (niche_z + niche_h * 0.5 + body_top) * 0.5),
          (niche_w, D, body_top - niche_z - niche_h * 0.5), LIME)
    # spatele nisei (peretele din fund)
    b.box((0.0, -FACE + 0.06, niche_z), (niche_w, 0.12, niche_h), LIME)

    # fronton mic: prisma triunghiulara peste corp
    b.prism([(-W * 0.5 - 0.05, 0.0), (0.0, 0.30), (W * 0.5 + 0.05, 0.0)],
            D + 0.10, LIME, center=(0.0, 0.0, body_top))
    # cruce
    b.box((0.0, 0.0, body_top + 0.30 + 0.17), (0.045, 0.045, 0.34), LIME)
    b.box((0.0, 0.0, body_top + 0.30 + 0.23), (0.19, 0.045, 0.045), LIME)
    body = b.to_object("Shrine_Body")

    # --- nisa: panoul albastru din fundul golului --------------------------
    b = Builder()
    b.box((0.0, -FACE + 0.15, niche_z), (niche_w - 0.05, 0.05, niche_h), NICHE)
    # arcul de sus al nisei
    b.revolve([(niche_w * 0.5 - 0.025, 0.0), (niche_w * 0.36, 0.05),
               (0.0, 0.10)], NICHE, segments=6,
              origin=(0.0, -FACE + 0.15, niche_z + niche_h * 0.5))
    niche = b.to_object("Shrine_Niche")

    zr = (0.0, H + 0.4)
    total = 0
    for obj, bev in ((body, 0.03), (niche, 0.015)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **AO_SHRINE)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        print("%-14s %3d tris" % (obj.name, tri_count(obj)))
        total += tri_count(obj)
    print("TOTAL          %3d tris  (buget 250)" % total)
    path, size = export_glb([body, niche],
                            "stromboli/buildings/street_shrine.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
