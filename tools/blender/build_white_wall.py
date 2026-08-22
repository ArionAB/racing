"""Stromboli, kit de sat — zidurile albe (brief village_kit, piesa 5).

  WhiteWall  stromboli/buildings/white_wall.glb
             Wall_A / Wall_Gate / Wall_Corner

Trei module care se insiruie ca sa faca ulita. Sunt piesele cel mai des
instantiate din tot kitul, deci fiecare triunghi se inmulteste cu zeci.

`Wall_A` are o BANCA inglobata (polita de 0.4 m pe o parte) — detaliul care
face zidul sa fie mobilier de strada, nu gard. Se pune pe fata +Y, adica spre
ulita.

Modulele se aseaza cap la cap: `Wall_A` are exact 3 m pe X, iar originea la
baza, centrata — deci doua module vecine se pun la 3 m distanta, fara joc.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_white_wall.py
"""

import math
from mathutils import Matrix, Vector

AO_WALL = dict(samples=22, dist=2.6, gradient="vertical",
               low=0.66, high=1.00, power=0.9, floor=0.34)

LEN, THK, HGT = 3.0, 0.5, 0.9
LIME = FOAM_WHITE


def build_wall_a():
    """Modul drept, cu banca inglobata pe fata +Y."""
    b = Builder()
    b.box((0.0, 0.0, HGT * 0.5), (LEN, THK, HGT), LIME)
    # banca: polita de 0.4 m, la 0.45 inaltime, pe fata dinspre ulita
    b.box((0.0, THK * 0.5 + 0.18, 0.45), (LEN * 0.72, 0.40, 0.13), LIME)
    # doua picioare scurte sub polita
    for sx in (-1, 1):
        b.box((sx * LEN * 0.28, THK * 0.5 + 0.14, 0.20),
              (0.16, 0.28, 0.42), LIME)
    return b.to_object("Wall_A")


def build_wall_gate():
    """Modul cu gol de poarta de 1.2 m intre doi stalpi rotunjiti.

    Golul e REAL — spatiu intre doua mase — nu un panou inchis la culoare.
    Lectia din biserica: aici chiar trebuie sa se poata trece cu privirea.
    """
    b = Builder()
    gate = 1.2
    side = (LEN - gate) * 0.5 - 0.18      # 0.18 = jumatate din stalp
    for sx in (-1, 1):
        cx = sx * (gate * 0.5 + 0.18 + side * 0.5)
        b.box((cx, 0.0, HGT * 0.5), (side, THK, HGT), LIME)
        # stalpul rotunjit de langa gol, putin mai inalt
        b.cylinder((sx * (gate * 0.5 + 0.18), 0.0, HGT * 0.5 + 0.09),
                   0.19, HGT + 0.18, LIME, segments=8)
    return b.to_object("Wall_Gate")


def build_wall_corner():
    """Colt in L: doua brate de cate jumatate de modul."""
    b = Builder()
    arm = LEN * 0.5
    b.box((-arm * 0.5 + THK * 0.25, 0.0, HGT * 0.5), (arm, THK, HGT), LIME)
    b.box((THK * 0.25 - THK * 0.5, arm * 0.5 + THK * 0.25, HGT * 0.5),
          (THK, arm, HGT), LIME)
    return b.to_object("Wall_Corner")


if __name__ == "__main__":
    clear_built()
    parts = [build_wall_a(), build_wall_gate(), build_wall_corner()]
    total = 0
    for obj in parts:
        stats = finish(obj, bevel=0.09, ao=AO_WALL, origin="base")
        print("%-14s %3d tris" % (obj.name, stats["tris"]))
        total += stats["tris"]
    print("TOTAL          %3d tris  (buget 400)" % total)
    path, size = export_glb(parts, "stromboli/buildings/white_wall.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
