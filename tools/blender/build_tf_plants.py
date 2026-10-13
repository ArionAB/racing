"""Transfagarasan -- plantele (brief docs/asset_briefs/transfagarasan_kit.md §1.5).

  transfagarasan/plants/jneapan_a.glb        jneapan culcat, 1,2 x 4 m     (Jneapan_Bark, Jneapan_Needles)
  transfagarasan/plants/jneapan_b.glb        jneapan compact, 1,5 x 3 m
  transfagarasan/plants/beech_tree_a.glb     fag european, 13 m, coroana 10 m  (Beech_Bark, Beech_Leaves)
  transfagarasan/plants/beech_tree_b.glb     fag de margine, 10 m, bifurcat la 3 m
  transfagarasan/plants/bujor_de_munte.glb   tufa 0,6 x 1,2 m, flori magenta   (Bujor_Leaves, Bujor_Bloom)
  transfagarasan/plants/afin.glb             tufa 0,5 x 0,9 m, bobite          (Afin_Leaves, Afin_Berry)

Plantele merg pe MultiMesh: UN mesh compact per material, fara noduri inutile,
origine la baza (la copaci: baza trunchiului), scala aplicata pe radacini, fara
oglindire (memoria multimesh-oglindire-culling). Coliziunea (`trunk` la arbori,
`none` la tufe) e a coordonatorului. Vocabularul (`needle_pad`, `crown_mass`,
`clump`, `branch`) e in `tf_shapes_nature.py`.

Sloturi (kit §0, tabelul pe roluri): jneapanul LOG_DARK 28 (clasa pine_needles pe
*_Needles), ramurile WOOD 9; fagul TROPICAL_GREEN 21 / trunchiul MARBLE_GREY 29;
bujorul TROPICAL_GREEN 21 + FLAMINGO_PINK 31; afinul TROPICAL_GREEN 21 + ICE_DEEP 25.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_plants.py
Variabila de mediu TF_ONLY=<piesa> reface doar piesa respectiva.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())
exec(open(os.path.join(_here, "tf_shapes_nature.py")).read())

clear_built()


def _ao(h, dist=0.8, low=0.55):
    return dict(samples=24, dist=dist, gradient="vertical", low=low, high=1.0,
                power=0.7, floor=0.30, z_range=(-0.01, h))


# ---------------------------------------------------------------------------
# jneapanul (Pinus mugo)
# ---------------------------------------------------------------------------

def _jneapan(branches, seed, upright=()):
    """branches = [(azimut, lungime, cota_varf, [(t, lung, lat, inalt, rise), ...])]
    Ramura: porneste din centru culcata pe sol (0,05-0,2 m), se ridica la capat.
    Pe ea: perne de ace (needle_pad) la fractiile t. `upright` = ramuri scurte
    care urca din centru (azimut, lungime, cota_varf, lat_perna)."""
    bark, nd = Builder(), Builder()
    r = _rnd(seed)
    for k, (az, L, ztip, pads) in enumerate(branches):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        side = Vector((-d.y, d.x, 0.0)) * ((r() - 0.5) * 0.25)
        path = [Vector((0.0, 0.0, 0.04)), d * (0.30 * L) + Vector((0, 0, 0.14)),
                d * (0.60 * L) + side + Vector((0, 0, 0.18)),
                d * (0.85 * L) + side * 1.5 + Vector((0, 0, 0.18 + (ztip - 0.18) * 0.45)),
                d * L + side * 1.8 + Vector((0, 0, ztip))]
        branch(bark, path, 0.11, 0.035, TF_WOOD, seg=6)

        def at(t):
            f = t * (len(path) - 1)
            i = min(int(f), len(path) - 2)
            return path[i].lerp(path[i + 1], f - i)
        for j, (t, pl, pw, ph, rise) in enumerate(pads):
            p = at(t) + Vector((0.0, 0.0, ph * 0.25))
            needle_pad(nd, p, az + (r() - 0.5) * 30.0, pl, pw, ph, TF_NEEDLES,
                       seed=seed * 100 + k * 10 + j, n=3, rise=rise)
    for k, (az, L, ztip, pw) in enumerate(upright):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        tip = d * L + Vector((0.0, 0.0, ztip))
        branch(bark, [Vector((0.0, 0.0, 0.05)), d * (0.3 * L) + Vector((0, 0, ztip * 0.45)), tip],
               0.09, 0.04, TF_WOOD, seg=6)
        needle_pad(nd, d * (0.55 * L) + Vector((0, 0, ztip * 0.62)), az, 0.75, pw, 0.5,
                   TF_NEEDLES, seed=seed * 100 + 70 + k, n=3, rise=0.3)
    return [bark.to_object("Jneapan_Bark"), nd.to_object("Jneapan_Needles")]


def build_jneapan_a():
    """Jneapanul A (`jneapan_a`): 1,2 m inalt, 4 m lat, h/l ~0,3 -- tufa CULCATA.

    LISTA DE ELEMENTE (decuparea `jneapan_a.png` + contractul; scrisa INAINTE
    de geometrie):
      a) 6 RAMURI groase (plansa: 6-7 vizibile; contractul 4-6) care pornesc
         din CENTRU, culcate pe sol (0,05-0,2 m), si se RIDICA la capete
         (varfurile la 0,5-0,85 m); lungi de 1,55-1,9 m, maro (WOOD 9), vizibile
         intre perne in centrul tufei.
      b) PERNE DENSE de ace: 4 pe fiecare ramura (24), fiecare o "creanga cu
         ace" PLATA, cu marginea zimtata (miez + 3 lobi alternanti pe fiecare
         parte), suprapuse -> perna continua; perna de la varf urca cu ramura.
         (Runda 1: perne din bile in sir -- citeau ca margele, nu ca ace.)
      c) centrul tufei JOS si rar (pe plansa se vad ramurile maro): fara masa
         centrala inalta -- NU e un brad mic.
      d) NU intra: pietrele de la baza de pe plansa (decor de integrare).
    Noduri: Jneapan_Bark (WOOD 9), Jneapan_Needles (LOG_DARK 28 -> clasa
    pine_needles; in preview tinta #34503A).
    """
    pads = lambda s: [(0.30, 0.80 * s, 0.95, 0.36, 0.0), (0.52, 0.85 * s, 0.95, 0.38, 0.04),
                      (0.74, 0.85 * s, 0.90, 0.40, 0.10), (0.95, 0.80 * s, 0.85, 0.42, 0.22)]
    branches = [(8.0, 1.85, 0.62, pads(1.0)), (68.0, 1.60, 0.80, pads(0.9)),
                (128.0, 1.90, 0.55, pads(1.05)), (188.0, 1.55, 0.85, pads(0.9)),
                (245.0, 1.80, 0.50, pads(1.0)), (305.0, 1.65, 0.70, pads(0.95))]
    return _jneapan(branches, 31)


def build_jneapan_b():
    """Jneapanul B (`jneapan_b`): 1,5 m inalt, 3 m lat, h/l ~0,5 -- compact,
    mai inalt, ASIMETRIC, cu o perna iesita intr-o parte.

    LISTA DE ELEMENTE (decuparea `jneapan_b.png` + contractul; plansa b e aproape
    identica cu a, deci urmez contractul pentru silueta):
      a) 5 RAMURI culcate: 4 scurte (0,95-1,15 m) care urca mai abrupt (varfuri
         la 0,8-1,05 m) + 1 LUNGA spre +X (1,6 m), joasa, cu 4 perne -> perna
         iesita intr-o parte (asimetria ceruta).
      b) 3 RAMURI SCURTE care URCA din centru (varfuri la 1,2-1,3 m), fiecare cu
         o perna inclinata: dau inaltimea de 1,5 m. (Runda 1: o bila mare in
         centru -- citea ca un bulgare, nu ca ace.)
      c) PERNE plate, zimtate, ca la a: 3 pe ramurile scurte, 4 pe cea lunga.
      d) NU intra: pietrele, pamantul de la baza.
    Noduri: Jneapan_Bark (WOOD 9), Jneapan_Needles (LOG_DARK 28).
    """
    sh = lambda: [(0.40, 0.65, 0.85, 0.42, 0.0), (0.72, 0.65, 0.80, 0.44, 0.05),
                  (0.96, 0.60, 0.75, 0.46, 0.2)]
    branches = [(0.0, 1.60, 0.40, [(0.30, 0.80, 0.95, 0.42, 0.0), (0.55, 0.85, 0.95, 0.44, 0.0),
                                   (0.78, 0.85, 0.90, 0.46, 0.05), (0.98, 0.80, 0.85, 0.50, 0.15)]),
                (90.0, 1.05, 0.95, sh()), (160.0, 1.15, 1.05, sh()),
                (230.0, 0.95, 0.90, sh()), (300.0, 1.10, 0.80, sh())]
    upright = [(40.0, 0.45, 1.30, 0.80), (150.0, 0.40, 1.20, 0.75), (260.0, 0.45, 1.25, 0.80)]
    return _jneapan(branches, 47, upright=upright)


# runda 3: umbrire neteda pe ciorchinii de 5 x 2 (cu fatete plate citeau ca
# niste cubulete; lobii de pe plansa sunt rotunjiti)
JNEAPAN_SMOOTH = 100.0   # 75 nu netezea nimic: fetele ciorchinilor de 5 laturi se intalnesc la 72-90+ grade

ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


if _want("jneapan_a"):
    emit_tf(build_jneapan_a(), "plants/jneapan_a.glb", _ao(1.2, 0.6), keep_xy=True,
            bevel=0.0, smooth_angle=JNEAPAN_SMOOTH)
if _want("jneapan_b"):
    emit_tf(build_jneapan_b(), "plants/jneapan_b.glb", _ao(1.5, 0.6), keep_xy=True,
            bevel=0.0, smooth_angle=JNEAPAN_SMOOTH)

report_tf()
