"""Stromboli, kit de sat — barca mare (brief village_kit, piesa 10).

  FishingBoatLarge  stromboli/vehicles/fishing_boat_large.glb
                    Boat_L_Hull / Boat_L_Trim / Boat_L_Cabin

7 m, cu cabina mica. PLUTESTE la dana din Ginostra, deci **linia de plutire e
la origine** (memoria `decor-manual-din-cod`: originile pe linia apei pentru
tot ce sta in apa). Chila coboara sub 0, bordul urca peste.

`verify_glb --origin=waterline` verifica exact asta: geometria INCALECA Y=0.
O barca exportata cu baza la zero ar pluti cu totul peste apa.

Coca foloseste acelasi profil ca barca mica, scalat — sunt din acelasi sat.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fishing_boat_large.py
"""

import math
from mathutils import Matrix, Vector

AO_BOAT = dict(samples=22, dist=2.8, gradient="vertical",
               low=0.58, high=1.00, power=0.9, floor=0.30)

LEN = 7.0
BEAM = 2.15
FREEBOARD = 0.62      # cat iese bordul peste apa
DRAFT = 0.42          # cat intra chila sub apa

HULL = FOAM_WHITE
TRIM = SEA_DEEP
WOOD_S = WOOD

N = 11


def _hull_profile(t):
    """Semi-latimea cocii la fractia t (0 = prova, 1 = pupa)."""
    return BEAM * 0.5 * math.sin(math.pi * (0.12 + 0.80 * t)) ** 0.7


if __name__ == "__main__":
    clear_built()

    # --- coca: de la -DRAFT (chila) la +FREEBOARD (bord) -------------------
    b = Builder()
    bm = b.bm
    layer = b.slot
    top, bot = [], []
    for i in range(N + 1):
        t = i / float(N)
        y = -LEN * 0.5 + LEN * t
        hw = max(_hull_profile(t), 0.04)
        # chila: cea mai adanca la mijloc, urca spre capete
        keel = -DRAFT + 0.30 * (abs(t - 0.5) * 2) ** 2
        top.append((bm.verts.new((-hw, y, FREEBOARD)),
                    bm.verts.new((hw, y, FREEBOARD))))
        bot.append((bm.verts.new((-hw * 0.38, y, keel)),
                    bm.verts.new((hw * 0.38, y, keel))))
    for i in range(N):
        (tl0, tr0), (tl1, tr1) = top[i], top[i + 1]
        (bl0, br0), (bl1, br1) = bot[i], bot[i + 1]
        for f in (bm.faces.new((bl0, tl0, tl1, bl1)),
                  bm.faces.new((tr0, br0, br1, tr1)),
                  bm.faces.new((bl0, bl1, br1, br0))):
            f[layer] = HULL
    for (tl, tr), (bl, br) in ((top[0], bot[0]), (top[-1], bot[-1])):
        f = bm.faces.new((tl, tr, br, bl))
        f[layer] = HULL
    hull = b.to_object("Boat_L_Hull")

    # --- copastia: banda continua, ca la barca mica ------------------------
    b = Builder()
    bm = b.bm
    layer = b.slot
    for sx in (-1, 1):
        inner, outer = [], []
        for i in range(N + 1):
            t = i / float(N)
            y = -LEN * 0.5 + LEN * t
            hw = max(_hull_profile(t), 0.04)
            inner.append(bm.verts.new((sx * (hw - 0.09), y, FREEBOARD + 0.02)))
            outer.append(bm.verts.new((sx * (hw + 0.04), y, FREEBOARD + 0.02)))
        for i in range(N):
            f = bm.faces.new((inner[i], outer[i], outer[i + 1], inner[i + 1]))
            f[layer] = TRIM
    trim = b.to_object("Boat_L_Trim")

    # --- cabina mica, spre pupa --------------------------------------------
    b = Builder()
    cab_y = -LEN * 0.22
    b.box((0.0, cab_y, FREEBOARD + 0.52), (1.25, 1.5, 1.00), HULL)
    b.box((0.0, cab_y, FREEBOARD + 1.06), (1.38, 1.62, 0.10), TRIM)
    # doua ferestre inchise pe laturi
    for sx in (-1, 1):
        b.box((sx * 0.64, cab_y + 0.12, FREEBOARD + 0.70),
              (0.05, 0.75, 0.36), TRIM)
    cabin = b.to_object("Boat_L_Cabin")

    zr = (-DRAFT, FREEBOARD + 1.2)
    total = 0
    for obj, bev in ((hull, 0.05), (trim, 0.02), (cabin, 0.03)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 50.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **AO_BOAT)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        print("%-14s %3d tris" % (obj.name, tri_count(obj)))
        total += tri_count(obj)
    print("TOTAL          %3d tris  (buget 900)" % total)
    path, size = export_glb([hull, trim, cabin],
                            "stromboli/vehicles/fishing_boat_large.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
