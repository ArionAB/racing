"""Stromboli, kit de sat — casa B (brief docs/asset_briefs/stromboli_village_kit.md, piesa 2).

  AeolianHouseB  stromboli/buildings/aeolian_house_b.glb
                 House_B

Casa mare a satului: 9 x 7 x 5.5 m, doua niveluri, SCARA EXTERIOARA alba spre
terasa de sus, pergola pe stalpi albi rotunzi, 3-4 goluri cu obloane.

Scara exterioara e semnatura casei eoliene — e ce o deosebeste de casa A. Urca
pe latura -X, in doua rampe cu podest, cu muret alb pe exterior. Nu e ingropata
in perete: sta LANGA el, sprijinita pe o placa proprie (lectia din biserica si
din pontonul Ginostra — geometria intr-o masa nu se vede).

Conventii comune kitului:
  - fatada spre -Z_godot = +Y_blender
  - golurile sunt panouri, nu taieturi
  - bevel 0.10 pe var (identitatea kitului), 0.03 pe lemn
  - o cutie = 44 de triunghiuri dupa bevel (masurat pe tot proiectul)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_aeolian_house_b.py
"""

import math
from mathutils import Matrix, Vector

AO_HOUSE = dict(samples=26, dist=5.0, gradient="vertical",
                low=0.68, high=1.00, power=0.9, floor=0.32)

W, D, H = 9.0, 7.0, 5.5
FACADE = D * 0.5
LOWER = 2.9                    # cota planseului intre niveluri
PARAPET = 0.55

LIME = FOAM_WHITE
SHUTTER = SEA_DEEP
VOID = ASPHALT
WOOD_S = WOOD


def _window(b, center, w, h, axis="y", ny=1.0):
    """Gol cu oblon: panou intunecat retras + UN canat in fata lui.

    Un singur canat, nu doua: dunga dintre ele e sub un pixel la 20 m si
    costa 44 de triunghiuri (masurat pe casa A).
    """
    cx, cy, cz = center
    if axis == "y":
        b.box((cx, cy - ny * 0.16, cz), (w, 0.12, h), VOID)
        b.box((cx, cy + ny * 0.03, cz), (w * 0.98, 0.07, h * 0.96), SHUTTER)
    else:
        b.box((cx - ny * 0.16, cy, cz), (0.12, w, h), VOID)
        b.box((cx + ny * 0.03, cy, cz), (0.07, w * 0.98, h * 0.96), SHUTTER)


if __name__ == "__main__":
    clear_built()
    b = Builder()

    # --- corpul in doua volume ---------------------------------------------
    # Nivelul de jos ocupa toata amprenta; cel de sus e retras pe +X, ca sa
    # lase terasa spre care urca scara. Asta e ce face casa sa citeasca "doua
    # niveluri" din silueta, nu doar din ferestre.
    b.box((0.0, 0.0, LOWER * 0.5), (W, D, LOWER), LIME)
    # 0.52, nu 0.62: terasa ramanea de 3.42 m, iar pergola (2.6 m plus stalpi)
    # iesea peste marginea ei — in randare stalpii pluteau in aer. Cu 0.52
    # terasa are 4.32 m si pergola incape cu joc.
    upper_w = W * 0.52
    upper_cx = W * 0.5 - upper_w * 0.5
    b.box((upper_cx, 0.0, LOWER + (H - LOWER) * 0.5),
          (upper_w, D, H - LOWER), LIME)

    terr_w = W - upper_w
    terr_cx = -W * 0.5 + terr_w * 0.5

    # parapet pe terasa de jos (partea descoperita, spre -X). Lasa GOL pe
    # fatada acolo unde urca scara — altfel scara se izbeste de parapet.
    pz = LOWER + PARAPET * 0.5
    b.box((terr_cx, -(D * 0.5 - 0.14), pz), (terr_w, 0.28, PARAPET), LIME)
    b.box((-(W * 0.5 - 0.14), 0.0, pz), (0.28, D - 0.56, PARAPET), LIME)

    # parapet pe acoperisul de sus, doar fata si -X (restul nu se vede)
    pz2 = H + PARAPET * 0.5
    b.box((upper_cx, FACADE - 0.14, pz2), (upper_w, 0.28, PARAPET), LIME)
    b.box((upper_cx - upper_w * 0.5 + 0.14, 0.0, pz2),
          (0.28, D - 0.56, PARAPET), LIME)

    # --- scara exterioara ---------------------------------------------------
    # Urca PE FATADA, in doua rampe, si ajunge PE TERASA — nu pe langa ea.
    #
    # Prima versiune o punea la x=-5.05, adica la 0.55 m in afara marginii
    # terasei (-4.50): rampele urcau paralel cu casa si se opreau in aer. O
    # scara eoliana reala se sprijina de perete si descarca pe terasa, deci
    # ultima rampa trebuie sa se termine INTRE marginile ei.
    #
    # Rampa 1 urca pe fatada (+Y), de la sol la jumatate; rampa 2 se intoarce
    # spre -Y peste terasa si ajunge la cota LOWER.
    st_x = terr_cx - 0.35
    mid_z = LOWER * 0.52
    b.beam((st_x, FACADE + 0.55, 0.0), (st_x, FACADE - 1.4, mid_z),
           (1.15, 0.26), LIME, up=(0, 0, 1))
    b.box((st_x, FACADE - 1.85, mid_z + 0.05), (1.35, 1.05, 0.26), LIME)
    b.beam((st_x, FACADE - 2.3, mid_z), (st_x, FACADE - 4.3, LOWER),
           (1.15, 0.26), LIME, up=(0, 0, 1))
    # muretul, pe latura dinspre exterior (-X)
    for (p0, p1) in (((st_x - 0.62, FACADE + 0.55, 0.34),
                      (st_x - 0.62, FACADE - 1.4, mid_z + 0.34)),
                     ((st_x - 0.62, FACADE - 2.3, mid_z + 0.34),
                      (st_x - 0.62, FACADE - 4.3, LOWER + 0.34))):
        b.beam(p0, p1, (0.16, 0.46), LIME, up=(0, 0, 1))

    # --- pergola pe terasa, pe stalpi albi ROTUNZI --------------------------
    # Stalpii rotunzi (pulèra) sunt ceruti explicit — sunt semnatura eoliana,
    # nu bare de lemn. Hexagon: la 5-20 m citeste rotund si costa jumatate
    # dintr-un cilindru cu 12 laturi.
    for (px, py) in ((terr_cx - 0.95, FACADE - 1.1), (terr_cx + 0.95, FACADE - 1.1),
                     (terr_cx - 0.95, FACADE - 3.1), (terr_cx + 0.95, FACADE - 3.1)):
        b.cylinder((px, py, LOWER + 1.15), 0.17, 2.3, LIME, segments=6)
    for gy in (FACADE - 1.1, FACADE - 3.1):
        b.box((terr_cx, gy, LOWER + 2.36), (2.3, 0.14, 0.14), WOOD_S)
    for gx in (terr_cx - 0.6, terr_cx + 0.6):
        b.box((gx, FACADE - 2.1, LOWER + 2.44), (0.11, 2.1, 0.11), WOOD_S)

    # --- goluri -------------------------------------------------------------
    # usa la parter, pe fatada, sub volumul de sus
    door_w, door_h = 1.15, 2.15
    b.box((upper_cx, FACADE - 0.04, door_h * 0.5), (door_w, 0.16, door_h),
          SHUTTER)
    for sgn in (-1, 1):
        b.box((upper_cx + sgn * (door_w * 0.5 + 0.07), FACADE + 0.02,
               door_h * 0.5 + 0.07), (0.14, 0.10, door_h + 0.14), LIME)

    # doua ferestre la etaj, pe fatada
    for sgn in (-1, 1):
        _window(b, (upper_cx + sgn * 1.35, FACADE - 0.02, LOWER + 1.5),
                0.95, 1.2)
    # o fereastra la parter, langa usa
    _window(b, (upper_cx - 2.35, FACADE - 0.02, 1.65), 0.9, 1.1)
    # una pe latura +X a etajului
    _window(b, (W * 0.5 - 0.02, -1.0, LOWER + 1.5), 0.95, 1.2,
            axis="x", ny=1.0)

    house = b.to_object("House_B")
    stats = finish(house, bevel=0.10, ao=AO_HOUSE, origin="base")
    print("House_B %4d tris  (buget 1300)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([house], "stromboli/buildings/aeolian_house_b.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
