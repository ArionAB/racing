"""Kyoto -- arborii (brief docs/asset_briefs/kyoto_kit.md §1.2).

  kyoto/plants/momiji_a.glb    arțar carmin (KERB_RED / maple_crimson)   (PILOT)
  kyoto/plants/momiji_b.glb    artar rosu-portocaliu, 3 etaje inguste (LAVA_ORANGE)
  kyoto/plants/momiji_c.glb    artar ruginiu, tabular asimetric (LARCH_RUST)
  kyoto/plants/ginkgo.glb      ginkgo auriu in con (CAR_YELLOW, --allow-car-slots)
  kyoto/plants/niwaki_pine.glb pin tuns in nori (TROPICAL_GREEN)

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
GINKGO_GOLD = CAR_YELLOW   # -> clasa ginkgo_gold (#F2D03C); --allow-car-slots=Ginkgo_Crown
RUST = LARCH_RUST          # -> clasa leaf_litter / ruginiu (#A8683A)

AO_TREE = dict(gradient="vertical",
               samples=20, dist=3.2, low=0.62, high=1.0, power=0.8, floor=0.32)

clear_built()


def _tree(prefix, blobs, limbs, crown_slot, trunk_r=0.5, fork_z=2.0, seed=1,
          subdiv=2, jag=0.24, trunk_fn=None, limb_w=(0.46, 0.32)):
    """blobs: (x, y, z, rx, ry, rz); limbs: puncte (x, y, z) spre care pleaca
    crengile groase din furca (intra in ciorchini)."""
    tr = Builder()
    cr = Builder()
    # trunchi scurt cu evazare la radacina, furca la ~1/4 din inaltime
    if trunk_fn is None:
        tr.frustum((0, 0, 0.2), trunk_r * 1.9, trunk_r * 1.3, 0.4, BARK, segments=8)
        tr.frustum((0, 0, fork_z * 0.5 + 0.2), trunk_r * 1.3, trunk_r * 0.85,
                   fork_z - 0.2, BARK, segments=8)
        fork = Vector((0.0, 0.0, fork_z))
    else:                      # trunchi propriu (inclinat/sinuos); returneaza furca
        fork = Vector(trunk_fn(tr, BARK))
    for tgt in limbs:
        t = Vector(tgt)
        mid = fork.lerp(t, 0.5) + Vector((0, 0, 0.0))
        tr.beam(fork - Vector((0, 0, 0.15)), mid, (limb_w[0], limb_w[0]), BARK)
        tr.beam(mid, t, (limb_w[1], limb_w[1]), BARK)
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


def build_momiji_b():
    """`momiji_b.png` + contract: SILUETA "PAGODA" -- inalta si ingusta.

    - trunchi INALT (~3,4 m, 40% din inaltime), drept, evazat la radacina: sub
      coroana ramane un GOL MARE prin care se vad crengile;
    - coroana in 3 ETAJE care se ingusteaza spre varf: jos 3 ciorchini lati
      (stanga/dreapta/spate), mijloc 2 + 1 spate, sus 1 ciorchine mic;
      intre etaje se vad goluri cu cer si cranguri;
    - ansamblu ~8,5 m inalt x ~9,5 m lat (h/l ~0,9), mai inalt decat a;
    - un singur slot pe coroana (LAVA_ORANGE).
    """
    b = [
        (-2.7, 0.0, 3.5, 1.9, 1.7, 1.1),    # etaj 1 stanga
        (2.8, 0.2, 3.4, 1.9, 1.7, 1.1),     # etaj 1 dreapta
        (0.0, -1.4, 3.6, 1.7, 1.6, 1.0),    # etaj 1 spate
        (-1.0, 0.2, 5.5, 1.6, 1.5, 1.0),    # etaj 2 stanga
        (1.2, 0.0, 5.4, 1.6, 1.5, 1.0),     # etaj 2 dreapta
        (0.1, -0.8, 5.6, 1.4, 1.3, 0.95),   # etaj 2 spate
        (0.0, 0.0, 7.2, 1.35, 1.3, 1.0),    # etaj 3 varf
    ]
    limbs = [(-2.5, 0.0, 3.0), (2.6, 0.1, 2.9), (0.0, -1.2, 3.1),
             (-0.9, 0.1, 4.9), (1.1, 0.0, 4.8), (0.0, 0.0, 6.5)]
    return _tree("Maple", b, limbs, LAVA_ORANGE, trunk_r=0.5, fork_z=2.4, seed=7,
                 subdiv=3, jag=0.34)


def build_momiji_c():
    """`momiji_c.png` (runda 5: decuparea castiga contractul): DOM LARG, aerisit.

    - ansamblu ~8,8 m lat x ~7,3 m inalt (l/h ~1,2), aproape simetric;
    - trunchi SCURT si GROS (Ø baza ~2,2 m, evazare puternica), furca la 2,2 m
      in 5 crengi groase care se vad prin goluri;
    - 9 ciorchini mai MICI decat la `a`, in 3 nivele: 3 jos (coborati spre 35%
      din inaltime, iesiti lateral), 3 la mijloc cu GOL mare in centru unde se
      vad crengile, 3 sus; fiecare ciorchine zimtat, suprapunere mica;
    - un singur slot pe coroana (LARCH_RUST).
    """
    b = [
        (-3.7, 0.2, 2.9, 1.5, 1.4, 0.9),    # jos stanga, lateral
        (3.8, 0.0, 2.8, 1.5, 1.4, 0.9),     # jos dreapta, lateral
        (0.2, -1.9, 3.0, 1.5, 1.4, 0.9),    # jos spate
        (-2.7, 0.1, 4.5, 1.5, 1.4, 0.9),    # mijloc stanga
        (2.7, 0.2, 4.6, 1.5, 1.4, 0.9),     # mijloc dreapta
        (0.1, -1.3, 4.7, 1.4, 1.3, 0.9),    # mijloc spate (centrul fata ramane gol)
        (-1.2, 0.2, 6.0, 1.5, 1.4, 0.9),    # sus stanga
        (1.3, 0.0, 6.1, 1.5, 1.4, 0.9),     # sus dreapta
        (0.1, -0.6, 6.5, 1.2, 1.2, 0.8),    # varf
    ]
    limbs = [(-3.4, 0.2, 2.5), (3.5, 0.0, 2.4), (-2.4, 0.1, 4.0),
             (2.5, 0.2, 4.1), (0.1, -0.8, 4.2)]
    return _tree("Maple", b, limbs, RUST, trunk_r=0.8, fork_z=2.2, seed=11,
                 subdiv=3, jag=0.34, limb_w=(0.7, 0.45))


def build_ginkgo():
    """`ginkgo.png` (runda 5: decuparea castiga contractul): TRIUNGHI LAT.

    - coroana triunghiulara larga, l/h ~1,0 (~9,6 x 9,8 m); baza cea mai lata,
      coborata la ~2,1 m (~22% din inaltime);
    - 9 ciorchini TURTITI si lati (rz/rx ~0,5), zimtati, suprapusi, in 4 nivele
      lateral: 3 jos (ies mult pe laturi), 3, 2, 1 sus -- nu sfere stivuite;
    - trunchi scurt (2,2 m) care se desface in 5 crengi vizibile in jumatatea
      de jos, plus un fus central care urca in con;
    - un singur slot pe coroana (CAR_YELLOW).
    """
    b = [
        (-3.0, 0.2, 2.9, 1.8, 1.7, 0.9),    # nivel 1 stanga
        (3.1, 0.0, 2.9, 1.8, 1.7, 0.9),     # nivel 1 dreapta
        (0.1, -2.0, 3.0, 1.8, 1.7, 0.9),    # nivel 1 spate
        (-2.0, 0.3, 4.8, 1.7, 1.6, 0.9),    # nivel 2 stanga
        (2.1, 0.1, 4.8, 1.7, 1.6, 0.9),     # nivel 2 dreapta
        (0.0, -1.3, 4.9, 1.6, 1.5, 0.9),    # nivel 2 spate
        (-0.9, 0.2, 6.7, 1.5, 1.4, 0.9),    # nivel 3 stanga
        (1.0, -0.1, 6.7, 1.5, 1.4, 0.9),    # nivel 3 dreapta
        (0.0, 0.0, 8.6, 1.4, 1.3, 1.1),     # varf
    ]
    limbs = [(-2.7, 0.2, 2.5), (2.8, 0.0, 2.5), (0.1, -1.8, 2.6),
             (-1.8, 0.3, 4.3), (1.9, 0.1, 4.3), (0.0, 0.0, 7.0)]
    return _tree("Ginkgo", b, limbs, GINKGO_GOLD, trunk_r=0.6, fork_z=2.2, seed=21,
                 subdiv=3, jag=0.34, limb_w=(0.55, 0.4))


def build_niwaki_pine():
    """`niwaki_pine.png` + contract: pin tuns in NORI.

    - trunchi SINUOS (S-uri), gros jos (Ø ~1,1 m) si subtiat sus, ~4 m;
    - 5 etaje PLATE de muschi verde (nori), fiecare pe o creanga ORIZONTALA
      lunga: varf 1 (centru, sus), 2 mijlocii (stanga mai sus, dreapta), 2
      joase (stanga extinsa, dreapta extinsa);
    - nori = icosfera subdiv 1 foarte turtita (rz/rx ~0,3), fete mari fatetate;
    - ~5 m inalt x ~7 m lat (h/l ~0,7); trunchiul se vede intre nori.
    - doua noduri: Pine_Trunk (WOOD), Pine_Crown (TROPICAL_GREEN).
    """
    pads = [
        (0.2, 0.0, 4.3, 1.5, 1.35, 0.6),     # varf
        (-2.2, 0.2, 3.2, 1.5, 1.35, 0.58),     # mijloc stanga
        (2.3, -0.1, 2.95, 1.5, 1.3, 0.58),   # mijloc dreapta
        (-2.7, 0.1, 1.55, 1.5, 1.3, 0.58),   # jos stanga
        (2.8, 0.3, 1.3, 1.5, 1.25, 0.56),    # jos dreapta
    ]

    def trunk(tr, bark):
        # S sinuos din frustumuri scurte suprapuse (rotund, nu cutii)
        n = 9
        for i in range(n):
            t = i / (n - 1.0)
            z = 0.15 + t * 3.7
            x = 0.32 * math.sin(t * 2 * math.pi * 1.1)
            r = 0.9 - 0.55 * t
            tr.frustum((x, 0.0, z), r * 1.05, r * 0.9, 0.7, bark, segments=7)
        for tx, tz, th in ((-1.9, 3.0, 0.22), (2.0, 2.8, 0.22),
                           (-2.4, 1.45, 0.24), (2.5, 1.2, 0.24)):
            z0 = tz - 1.3
            tr.beam((0.0, 0.0, z0), (tx * 0.5, 0.05, z0 + 0.45), (th * 1.5, th * 1.5), bark)
            tr.beam((tx * 0.5, 0.05, z0 + 0.45), (tx, 0.1, tz - 0.35), (th, th), bark)
        return (0.1, 0.0, 3.9)

    return _tree("Pine", pads, [], TROPICAL_GREEN, seed=33, subdiv=2, jag=0.30,
                 trunk_fn=trunk)


def _emit_tree(fn, name, budget):
    clear_built()      # nume stabile de noduri (fara sufix .001)
    tr, cr = fn()
    emit([tr, cr], "plants/%s.glb" % name, AO_TREE, bevel=0.0, smooth_angle=None,
         budget=budget)


_emit_tree(build_momiji_a, "momiji_a", 3500)
_emit_tree(build_momiji_b, "momiji_b", 3500)
_emit_tree(build_momiji_c, "momiji_c", 3500)
_emit_tree(build_ginkgo, "ginkgo", 3100)
_emit_tree(build_niwaki_pine, "niwaki_pine", 1500)
report()
