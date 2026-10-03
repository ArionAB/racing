"""Kyoto -- arborii (brief docs/asset_briefs/kyoto_kit.md §1.2).

  kyoto/plants/momiji_a.glb    arțar carmin (KERB_RED / maple_crimson)   (PILOT)
  (urmeaza: momiji_b, momiji_c, ginkgo, niwaki_pine)

Fiecare copac = DOUA noduri: `<Nume>_Trunk` si `<Nume>_Crown` (clasele se leaga
per nod, brief pistei §5.6). Coroana e din ciorchini turtiti cu margine lobata,
cu goluri intre ei -- NICIODATA glob (memoria silueta-inainte-de-umbrire).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_trees.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

BARK = WOOD
CRIMSON = KERB_RED         # -> clasa maple_crimson (#BB3522)
ORANGE_RED = CAR_RED       # -> clasa maple_orange (#E54839); exceptie --allow-car-slots=Maple
RUST = LARCH_RUST          # -> clasa leaf_litter / ruginiu (#A8683A)

AO_TREE = dict(samples=14, dist=2.5, gradient="vertical",
               low=0.78, high=1.0, power=0.9, floor=0.5)

clear_built()


def _tree(prefix, clusters, limbs, crown_slot, height, trunk_r=0.55, fork_z=2.5,
          seed=1):
    """clusters: (x, y, z, rx, rz, lobes) in metri; limbs: (cluster index) ->
    crengile pornesc din furca spre fiecare ciorchine din `limbs`."""
    tr = Builder()
    cr = Builder()
    tr.frustum((0, 0, fork_z * 0.5), trunk_r * 1.35, trunk_r * 0.78, fork_z, BARK,
               segments=7)
    tr.frustum((0, 0, 0.18), trunk_r * 1.7, trunk_r * 1.35, 0.36, BARK, segments=7)
    for li in limbs:
        x, y, z, rx, rz, lobes = clusters[li]
        a = Vector((0.0, 0.0, fork_z - 0.1))
        tgt = Vector((x * 0.55, y * 0.55, max(fork_z + 0.6, z - rz * 1.1)))
        mid = (a + tgt) * 0.5 + Vector((x * 0.1, y * 0.1, 0.0))
        tr.beam(a, mid, (0.46, 0.46), BARK)
        tr.beam(mid, tgt, (0.3, 0.3), BARK)
    for k, (x, y, z, rx, rz, lobes) in enumerate(clusters):
        leaf_cluster(cr, (x, y, z), rx, rx * 0.92, rz, crown_slot, lobes=lobes,
                     seed=seed * 31 + k, notch=0.74)
    return tr.to_object(prefix + "_Trunk"), cr.to_object(prefix + "_Crown")


def build_momiji_a():
    """`momiji_a.png` -- lista de elemente (inainte de modelare):

    - 1 trunchi gros, scurt, cu baza evazata, care se desparte la ~2 m in 3
      crengi principale.
    - Coroana de ~10 ciorchini turtiti (frunze lobate, ca de arțar), asezati in
      ETAJE: unul sus in centru, doi mai jos pe laturi, 3 pe etajul de mijloc,
      4 pe etajul de jos, cei de jos aproape de trunchi; intre ciorchini se
      vede cerul si crengile (goluri).
    - Latura coroanei mai mare decat inaltimea (h/l ~ 0,8).
    - Roșu-carmin (#BB3522); fetele de sus mai luminoase, dedesubt mai inchis
      (din AO). Iese din contur: ciorchinii laterali, lobii.
    Cote: 8,5 m inalt, ~10,5 m lat.
    """
    # (x, y, z, rx, rz, lobes), metri; z = centrul ciorchinelui
    c = [
        (0.4, 0.0, 7.2, 2.7, 1.2, 8),       # 0 varf
        (-2.7, 0.3, 6.1, 2.5, 1.15, 8),     # 1 etaj 2 stanga
        (2.9, -0.2, 5.8, 2.6, 1.15, 8),     # 2 etaj 2 dreapta
        (-4.3, 0.0, 4.3, 2.4, 1.1, 8),      # 3 mijloc stanga
        (0.2, 0.6, 4.7, 2.9, 1.2, 9),       # 4 mijloc centru
        (4.3, 0.3, 4.0, 2.4, 1.1, 8),       # 5 mijloc dreapta
        (-3.2, -0.4, 2.9, 2.0, 0.95, 7),    # 6 jos stanga
        (2.7, 0.6, 2.8, 2.2, 1.0, 7),       # 7 jos dreapta
        (-5.1, 0.3, 3.0, 1.5, 0.8, 6),      # 8 jos stanga extern
        (5.3, -0.3, 2.9, 1.4, 0.75, 6),     # 9 jos dreapta extern
    ]
    c = [(x * 0.74, y, z + 0.25, rx * 0.95, rz * 0.62, 9)
         for (x, y, z, rx, rz, lobes) in c]
    c += [(-1.6, -0.8, 5.6, 2.3, 0.7, 9), (2.0, -0.7, 3.9, 2.2, 0.7, 9),
          (-0.5, 0.9, 6.6, 2.1, 0.7, 9)]
    return _tree("Maple", c, limbs=(1, 2, 3, 5, 4, 6, 7), crown_slot=CRIMSON,
                 height=8.5, seed=1)


tr, cr = build_momiji_a()
emit([tr, cr], "plants/momiji_a.glb", AO_TREE, bevel=0.0, smooth_angle=None,
     budget=2000)
report()
