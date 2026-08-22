"""Stromboli, kit de sat — tricicleta Ape (brief village_kit, piesa 8).

  ApePiaggio  stromboli/vehicles/ape_piaggio.glb
              Ape_Body / Ape_Wheels / Ape_Bed

2.7 x 1.3 x 1.6 m. STATICA, parcata, fara interior. Rotile sunt nod separat
ca sa poata primi o rotire daca vreodata o punem in miscare.

**Vehiculul se construieste cu LUNGIMEA PE X.** Nu e o alegere estetica, e
singurul mod in care silueta iese dintr-o bucata: `prism` primeste conturul in
planul XZ si il extrudeaza pe Y, deci cu lungimea pe X pot desena profilul
LATERAL al cabinei (capota joasa, parbriz inclinat, acoperis, spate vertical)
ca un singur contur.

Primele trei incercari au construit cabina din cutie + cilindru lipit in fata.
Toate au esuat la fel: cabina iesea frigider, iar botul rotunjit fie disparea
in interiorul cutiei, fie atarna pe langa ea ca un bulgare. Cauza e generala si
merita retinuta — **o silueta curba nu se obtine lipind primitive convexe una
langa alta**; se obtine dintr-un contur.

Verde-oliv (TROPICAL_GREEN) pe cabina — brief. Nu e slot de masina, deci nu
concureaza cu masinile jucatorului.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_ape_piaggio.py
"""

import math
from mathutils import Matrix, Vector

AO_APE = dict(samples=22, dist=1.8, gradient="vertical",
              low=0.60, high=1.00, power=0.9, floor=0.32)

L, W, H = 2.7, 1.3, 1.6        # lungime pe X, latime pe Y
CAB = TROPICAL_GREEN
WOOD_S = WOOD
TIRE = ASPHALT
GLASS = SEA_DEEP
METAL = RUST

WHEEL_R = 0.24
AXLE_Z = WHEEL_R

# Cotele pe axa X (lungimea), asezate pe hartie inainte de modelare:
#   bena     x -1.35 .. +0.05
#   cabina   x +0.05 .. +1.35 (botul iese pana la +1.55)
#   roata fata x=+1.00; roti spate x=-0.95, la y=+-0.55
BED_X0, BED_X1 = -1.35, 0.05
CAB_X0, CAB_X1 = 0.05, 1.35
CAB_W = 1.06


if __name__ == "__main__":
    clear_built()

    # --- cabina, dintr-un singur contur lateral -----------------------------
    b = Builder()
    profile = [
        (CAB_X0, 0.30),          # jos-spate
        (CAB_X1 + 0.16, 0.34),   # jos-fata (botul iese in fata cabinei)
        (CAB_X1 + 0.20, 0.62),   # urcarea botului
        (CAB_X1 - 0.04, 0.86),   # varful capotei
        (CAB_X1 - 0.30, 1.32),   # parbrizul inclinat
        (CAB_X0 + 0.06, 1.40),   # acoperisul
        (CAB_X0, 1.20),          # coborarea din spate
    ]
    b.prism(profile, CAB_W, CAB, center=(0.0, 0.0, 0.0))
    # parbriz: panou inchis pe fata inclinata a conturului
    b.box((CAB_X1 - 0.17, 0.0, 1.06), (0.10, CAB_W - 0.18, 0.42), GLASS,
          rotation=Matrix.Rotation(math.radians(22.0), 3, "Y"))
    # far
    b.cylinder((CAB_X1 + 0.19, 0.0, 0.48), 0.09, 0.07, METAL,
               segments=6, axis="X")
    body = b.to_object("Ape_Body")

    # --- roti: axa de rotatie pe Y (transversala) ---------------------------
    b = Builder()
    b.cylinder((1.00, 0.0, AXLE_Z), WHEEL_R, 0.16, TIRE, segments=8, axis="Y")
    for sy in (-1, 1):
        b.cylinder((-1.02, sy * 0.55, AXLE_Z), WHEEL_R, 0.17, TIRE,
                   segments=8, axis="Y")
    wheels = b.to_object("Ape_Wheels")

    # --- bena ---------------------------------------------------------------
    b = Builder()
    bed_cx = (BED_X0 + BED_X1) * 0.5
    bed_len = BED_X1 - BED_X0
    b.box((bed_cx, 0.0, 0.46), (bed_len, W - 0.02, 0.10), WOOD_S)
    # Obloane de 0.52, la 0.72 — nu 0.34 la 0.63. Masurat pe randare: langa o
    # cabina de 1.52 m, un oblon de 0.34 face bena sa para o tavita si
    # vehiculul sa arate dezechilibrat. La Ape real oblonul e cam la jumatate
    # din inaltimea cabinei.
    for sy in (-1, 1):
        b.box((bed_cx, sy * (W * 0.5 - 0.05), 0.72),
              (bed_len, 0.09, 0.52), WOOD_S)
    b.box((BED_X0 + 0.05, 0.0, 0.72), (0.09, W - 0.02, 0.52), WOOD_S)
    bed = b.to_object("Ape_Bed")

    zr = (0.0, H)
    total = 0
    for obj, bev in ((body, 0.035), (wheels, 0.02), (bed, 0.025)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 50.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **AO_APE)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        print("%-12s %3d tris" % (obj.name, tri_count(obj)))
        total += tri_count(obj)
    print("TOTAL        %3d tris  (buget 700)" % total)
    path, size = export_glb([body, wheels, bed],
                            "stromboli/vehicles/ape_piaggio.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
