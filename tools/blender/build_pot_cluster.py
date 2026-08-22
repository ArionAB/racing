"""Stromboli, kit de sat — grup de ghivece (brief village_kit, piesa 14).

  PotCluster  stromboli/props/pot_cluster.glb
              Pot_Cluster

Amprenta 1 x 1 m. 3-4 ghivece de teracota (Ø 0.3-0.6) cu muscate rosii si o
opuntia mica.

E piesa care se pune langa usi si pe trepte — cea mai marunta din kit, dar si
cea care umanizeaza ulita. Muscatele folosesc acelasi slot de accent ca
bougainvillea (CAR_RED), deci grupul se citeste ca aceeasi familie de flori.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_pot_cluster.py
"""

import math
from mathutils import Matrix, Vector

AO_POT = dict(samples=18, dist=0.9, gradient="vertical",
              low=0.62, high=1.00, power=0.9, floor=0.36)

TERRA = TILE_TERRACOTTA
FLOWER = CAR_RED
LEAF = TROPICAL_GREEN
CACTUS = CACTUS_GREEN


def _lcg(seed):
    st = [seed & 0x7FFFFFFF]

    def nxt():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return nxt


def _pot(b, cx, cy, r_top, h, seed, kind="geranium"):
    """Un ghiveci tronconic + ce creste in el."""
    rnd = _lcg(seed)
    r_bot = r_top * 0.72
    b.frustum((cx, cy, h * 0.5), r_bot, r_top, h, TERRA, segments=7)
    # buza ghiveciului
    b.cylinder((cx, cy, h - 0.02), r_top * 1.08, 0.05, TERRA, segments=7)

    if kind == "geranium":
        # frunzis: o masa turtita; flori: 2-3 pete mici deasupra
        b.boulder((cx, cy, h + r_top * 0.55),
                  (r_top * 1.9, r_top * 1.9, r_top * 1.1), LEAF,
                  seed=seed + 3, segments=7, rings=3, deviation=0.10)
        for k in range(3):
            a = 2.0 * math.pi * (k + rnd() * 0.5) / 3.0
            rr = r_top * (0.5 + 0.4 * rnd())
            b.boulder((cx + rr * math.cos(a), cy + rr * math.sin(a),
                       h + r_top * 0.95),
                      (0.11, 0.11, 0.08), FLOWER, seed=seed + 7 + k,
                      segments=6, rings=3, deviation=0.06)
    else:
        # opuntia: doua palete turtite, una din alta
        b.boulder((cx, cy, h + 0.20), (0.26, 0.09, 0.34), CACTUS,
                  seed=seed + 11, segments=7, rings=4, deviation=0.06)
        b.boulder((cx + 0.13, cy + 0.02, h + 0.42), (0.19, 0.07, 0.24),
                  CACTUS, seed=seed + 13, segments=7, rings=3, deviation=0.06)


if __name__ == "__main__":
    clear_built()
    b = Builder()
    _pot(b, -0.26, 0.10, 0.17, 0.30, seed=5)
    _pot(b, 0.14, -0.18, 0.24, 0.40, seed=19)
    _pot(b, 0.28, 0.26, 0.13, 0.24, seed=31, kind="opuntia")
    _pot(b, -0.10, -0.34, 0.11, 0.20, seed=43)

    obj = b.to_object("Pot_Cluster")
    stats = finish(obj, bevel=0.015, ao=AO_POT, origin="base")
    print("Pot_Cluster %3d tris  (buget 400)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([obj], "stromboli/props/pot_cluster.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
