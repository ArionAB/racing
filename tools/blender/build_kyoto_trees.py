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

AO_TREE = dict(gradient="vertical",
               samples=20, dist=3.2, low=0.62, high=1.0, power=0.8, floor=0.32)

clear_built()


def _tree(prefix, blobs, limbs, crown_slot, trunk_r=0.5, fork_z=2.0, seed=1,
          subdiv=2, jag=0.24):
    """blobs: (x, y, z, rx, ry, rz); limbs: puncte (x, y, z) spre care pleaca
    crengile groase din furca (intra in ciorchini)."""
    tr = Builder()
    cr = Builder()
    # trunchi scurt cu evazare la radacina, furca la ~1/4 din inaltime
    tr.frustum((0, 0, 0.2), trunk_r * 1.9, trunk_r * 1.3, 0.4, BARK, segments=8)
    tr.frustum((0, 0, fork_z * 0.5 + 0.2), trunk_r * 1.3, trunk_r * 0.85,
               fork_z - 0.2, BARK, segments=8)
    fork = Vector((0.0, 0.0, fork_z))
    for tgt in limbs:
        t = Vector(tgt)
        mid = fork.lerp(t, 0.5) + Vector((0, 0, 0.0))
        tr.beam(fork - Vector((0, 0, 0.15)), mid, (0.46, 0.46), BARK)
        tr.beam(mid, t, (0.32, 0.32), BARK)
    for k, (x, y, z, rx, ry, rz) in enumerate(blobs):
        leaf_blob(cr, (x, y, z), rx, ry, rz, crown_slot, subdiv=subdiv, jag=jag,
                  seed=seed * 31 + k)
    return tr.to_object(prefix + "_Trunk"), cr.to_object(prefix + "_Crown")


def build_momiji_a():
    """`momiji_a.png` -- lista de elemente (runda 4, dupa verdictul coordonatorului):

    - coroana = 9 CIORCHINI VOLUMINOSI (icosfera subdiv 2 turtita la ~0,7 pe
      verticala), cu margine zimtata (varfuri impinse aleator), foarte
      suprapusi: 1 sus, 2 pe etajul 2 (stanga/dreapta), 1 central mare, 1 in
      spate, 2 laterali mijlocii coborati spre exterior, 2 jos langa trunchi.
    - ansamblu = dom mai LAT decat inalt (latime totala ~ 1,2 x inaltimea).
    - trunchi SCURT (~24% din inaltime), evazat la radacina, furca la 2 m in 5
      crengi groase care INTRA in ciorchini; intre ciorchinii de jos se vad 2-3
      crengi (goluri).
    - un singur slot pe coroana (KERB_RED); AO coace umbra sub si in interiorul
      ciorchinilor.
    Cote: ~8,4 m inalt, ~10 m lat.
    """
    b = [
        (0.3, 0.0, 6.9, 2.6, 2.4, 1.9),     # 0 varf
        (-3.0, 0.3, 5.9, 2.8, 2.5, 1.9),    # 1 etaj 2 stanga
        (3.1, -0.2, 5.6, 2.9, 2.5, 1.9),    # 2 etaj 2 dreapta
        (-4.1, 0.0, 3.9, 2.4, 2.2, 1.6),    # 3 mijloc stanga, coborat
        (0.2, 0.7, 5.0, 3.0, 2.6, 2.0),     # 4 central mare
        (4.2, 0.3, 3.7, 2.4, 2.2, 1.6),     # 5 mijloc dreapta
        (-2.5, -0.4, 3.2, 2.0, 1.9, 1.3),   # 6 jos stanga
        (2.4, 0.5, 3.0, 2.1, 1.9, 1.3),     # 7 jos dreapta
        (0.5, -1.7, 5.7, 2.5, 2.2, 1.7),    # 8 spate
    ]
    b = [(x * 0.98, y, z * 1.02, rx * 0.7, ry * 0.7, rz * 0.72) for (x, y, z, rx, ry, rz) in b]
    limbs = [(-2.9, 0.2, 5.0), (3.0, -0.1, 4.8), (-3.9, 0.0, 3.6),
             (4.1, 0.2, 3.4), (0.2, 0.5, 4.4)]
    return _tree("Maple", b, limbs, CRIMSON, trunk_r=0.5, fork_z=2.0, seed=1,
                 subdiv=3, jag=0.34)


tr, cr = build_momiji_a()
emit([tr, cr], "plants/momiji_a.glb", AO_TREE, bevel=0.0, smooth_angle=None,
     budget=3500)
report()
