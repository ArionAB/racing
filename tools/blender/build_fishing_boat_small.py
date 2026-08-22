"""Stromboli, kit de sat — barca mica (brief village_kit, piesa 9).

  FishingBoatSmall  stromboli/vehicles/fishing_boat_small.glb
                    Boat_S_Hull / Boat_S_Trim / Boat_Rollers

5 m lungime, trasa pe plaja, asezata pe TREI BUSTENI de rulare. Bustenii sunt
nod separat fiindca pe plaja se vad sub chila, dar daca barca se pune pe dana
sau in apa, se sting.

Coca se face din `taper_sweep` pe axa lungitudinala: raze care cresc de la
prova la mijloc si scad la pupa. E singurul mod ieftin de a obtine o forma de
barca — o cutie tesita arata ca ladita.

Copastia (Boat_S_Trim) e banda colorata de pe marginea de sus: la 5-20 m ea e
ce spune "barca de pescar", nu forma cocii.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fishing_boat_small.py
"""

import math
from mathutils import Matrix, Vector

AO_BOAT = dict(samples=22, dist=2.2, gradient="vertical",
               low=0.58, high=1.00, power=0.9, floor=0.30)

LEN = 5.0
BEAM = 1.55           # latimea maxima
DEPTH = 0.62          # inaltimea bordului

HULL = FOAM_WHITE
TRIM = SEA_DEEP
WOOD_S = WOOD


def _hull_profile(t):
    """Semi-latimea cocii la fractia t din lungime (0 = prova, 1 = pupa)."""
    # prova ascutita, mijloc plin, pupa lata dar taiata
    return BEAM * 0.5 * math.sin(math.pi * (0.12 + 0.80 * t)) ** 0.7


if __name__ == "__main__":
    clear_built()

    # --- coca ---------------------------------------------------------------
    b = Builder()
    bm = b.bm
    layer = b.slot
    N = 9
    top, bot = [], []
    for i in range(N + 1):
        t = i / float(N)
        y = -LEN * 0.5 + LEN * t
        hw = max(_hull_profile(t), 0.03)
        # chila urca la prova si la pupa (sheer)
        keel = 0.10 + 0.16 * (abs(t - 0.5) * 2) ** 2
        top.append((bm.verts.new((-hw, y, DEPTH)),
                    bm.verts.new((hw, y, DEPTH))))
        bot.append((bm.verts.new((-hw * 0.42, y, keel)),
                    bm.verts.new((hw * 0.42, y, keel))))
    for i in range(N):
        (tl0, tr0), (tl1, tr1) = top[i], top[i + 1]
        (bl0, br0), (bl1, br1) = bot[i], bot[i + 1]
        for f in (bm.faces.new((bl0, tl0, tl1, bl1)),
                  bm.faces.new((tr0, br0, br1, tr1)),
                  bm.faces.new((bl0, bl1, br1, br0))):
            f[layer] = HULL
    # inchiderile de la capete
    for (tl, tr), (bl, br) in ((top[0], bot[0]), (top[-1], bot[-1])):
        f = bm.faces.new((tl, tr, br, bl))
        f[layer] = HULL
    hull = b.to_object("Boat_S_Hull")

    # --- copastia -----------------------------------------------------------
    # O BANDA CONTINUA, construita ca si coca (inele legate), nu 18 beam-uri
    # puse cap la cap. Prima versiune folosea cate un beam per segment: fiecare
    # avea capetele lui, deci in randare copastia iesea un sirag de CARNATI, nu
    # o balustrada. Plus 792 de triunghiuri — de sapte ori cat coca.
    b = Builder()
    bm = b.bm
    layer = b.slot
    for sx in (-1, 1):
        inner, outer = [], []
        for i in range(N + 1):
            t = i / float(N)
            y = -LEN * 0.5 + LEN * t
            hw = max(_hull_profile(t), 0.03)
            inner.append(bm.verts.new((sx * (hw - 0.07), y, DEPTH + 0.02)))
            outer.append(bm.verts.new((sx * (hw + 0.03), y, DEPTH + 0.02)))
        for i in range(N):
            f = bm.faces.new((inner[i], outer[i], outer[i + 1], inner[i + 1]))
            f[layer] = TRIM
    trim = b.to_object("Boat_S_Trim")

    # --- bustenii de rulare -------------------------------------------------
    b = Builder()
    for fy in (-1.5, 0.0, 1.5):
        # Mai scurti decat latimea barcii (BEAM*0.85) si asezati JOS:
        # prima versiune ii facea mai lati decat coca si ieseau picioare.
        # z = raza exact, ca bustenii sa ATINGA solul: la 0.085 cu raza
        # 0.085 bevelul ii ridica cu ~11 mm si ansamblul iesea plutind.
        b.cylinder((0.0, fy, 0.082), 0.092, BEAM * 0.85, WOOD_S,
                   segments=6, axis="X")
    rollers = b.to_object("Boat_Rollers")

    zr = (0.0, DEPTH + 0.2)
    total = 0
    for obj, bev in ((hull, 0.04), (trim, 0.02), (rollers, 0.02)):
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
    print("TOTAL          %3d tris  (buget 650)" % total)
    path, size = export_glb([hull, trim, rollers],
                            "stromboli/vehicles/fishing_boat_small.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
