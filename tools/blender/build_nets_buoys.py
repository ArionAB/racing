"""Stromboli, kit de sat — plase si geamanduri (brief village_kit, piesa 12).

  NetsBuoys  stromboli/props/nets_buoys.glb
             Net_Pile / Buoys

Amprenta 2 x 2 m. Gramada joasa de plase + 4-5 geamanduri sferice.

**Plasa e un VOLUM poligonal neregulat, nu fire modelate** (brief). La 5 m o
gramada de plase citeste ca o masa moale cu contur zimtat — firele individuale
n-ar fi nici vizibile, nici accesibile ca buget.

Geamandurile alterneaza portocaliu-teracota si alb: sunt singurul accent de
culoare al piesei si ce o face sa se vada pe plaja neagra.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_nets_buoys.py
"""

import math
from mathutils import Matrix, Vector

AO_NET = dict(samples=20, dist=1.2, gradient="vertical",
              low=0.55, high=1.00, power=0.9, floor=0.30)
AO_BUOY = dict(samples=18, dist=1.0, gradient="spherical",
               low=0.66, high=1.00, power=0.9, floor=0.42)

NET = DRY_VEGETATION       # plasa: oliv-galbui, ca in brief
BUOY_A = TILE_TERRACOTTA   # portocaliu
BUOY_B = FOAM_WHITE        # alb


if __name__ == "__main__":
    clear_built()

    # --- gramada de plase ---------------------------------------------------
    # Trei volume `rock` turtite, suprapuse: forma organica, contur neregulat,
    # cost mic. `rock` e primitiva de masa amorfa din biblioteca — o folosim
    # pentru ce nu are muchii construite.
    b = Builder()
    heaps = [((0.0, 0.0), (1.7, 1.5, 0.55), 11),
             ((0.45, -0.35), (1.0, 0.9, 0.42), 23),
             ((-0.40, 0.30), (0.85, 1.0, 0.36), 37)]
    for (cx, cy), size, seed in heaps:
        # z = size/2 * 0.38, nu 0.42: bevelul ridica gramada cu ~10 mm si
        # ansamblul iesea 'plutind' la sonda.
        b.rock((cx, cy, size[2] * 0.36), size, NET, seed=seed,
               segments=7, rings=3, taper=0.55)
    net = b.to_object("Net_Pile")

    # --- geamanduri ---------------------------------------------------------
    # Cinci sfere mici, alternand culoarea, imprastiate pe langa gramada.
    b = Builder()
    # z putin SUB raza: geamandurile stau pe nisip, deci se ingroapa un pic.
    # La z = raza exact, bevelul + deviatia lui `boulder` le ridica cu ~10 mm
    # si sonda raporta ansamblul "plutind".
    buoys = [((0.95, 0.55, 0.15), 0.17, BUOY_A),
             ((-0.85, -0.60, 0.13), 0.15, BUOY_B),
             ((0.30, 0.95, 0.115), 0.13, BUOY_A),
             ((-1.00, 0.45, 0.105), 0.12, BUOY_A),
             ((0.70, -0.95, 0.12), 0.14, BUOY_B)]
    for (pos, r, slot) in buoys:
        b.boulder(pos, (r * 2, r * 2, r * 1.85), slot, seed=int(r * 1000),
                  segments=7, rings=4, deviation=0.05)
    buoy = b.to_object("Buoys")

    zr = (0.0, 0.7)
    total = 0
    for obj, ao, bev in ((net, AO_NET, 0.03), (buoy, AO_BUOY, 0.02)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        print("%-12s %3d tris" % (obj.name, tri_count(obj)))
        total += tri_count(obj)
    print("TOTAL        %3d tris  (buget 500)" % total)
    path, size = export_glb([net, buoy], "stromboli/props/nets_buoys.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
