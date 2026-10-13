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


# ---------------------------------------------------------------------------
# fagul european (Fagus sylvatica)
# ---------------------------------------------------------------------------

def _shear(builders, lean_deg, axis=(1.0, 0.0)):
    """Aplecarea arborelui: fiecare vertex se muta pe `axis` cu z*tan(lean).
    Baza trunchiului (z = 0) ramane pe origine."""
    k = math.tan(math.radians(lean_deg))
    for b in builders:
        for v in b.bm.verts:
            v.co.x += v.co.z * k * axis[0]
            v.co.y += v.co.z * k * axis[1]


def _root_flare(bark, r0, seed, n=4):
    r = _rnd(seed)
    for i in range(n):
        a = 2.0 * math.pi * (i + 0.2 * r()) / n
        d = Vector((math.cos(a), math.sin(a), 0.0))
        bark.taper_sweep([d * (r0 * 0.4) + Vector((0, 0, 0.9)), d * (r0 * 1.1) + Vector((0, 0, 0.25)),
                          d * (r0 * 2.0) + Vector((0, 0, 0.0))],
                         [r0 * 0.45, r0 * 0.35, 0.0], TF_BARK_GREY, segments=5)


def _limbs_to(bark, start, masses, frac=0.72, r0=0.17, r1=0.07, seed=0):
    """Cate un brat din `start` spre centrul fiecarei mase (pana la `frac` din
    drum, ca sa intre in miez): se vad pe sub coroana, ca pe plansa."""
    r = _rnd(seed)
    s = Vector(start)
    for (c, _rad) in masses:
        c = Vector(c)
        mid = s.lerp(c, 0.45) + Vector(((r() - 0.5) * 0.4, (r() - 0.5) * 0.4, -0.3))
        branch(bark, [s, mid, s.lerp(c, frac)], r0, r1, TF_BARK_GREY, seg=6)


def build_beech_tree_a():
    """Fagul A (`beech_tree_a`): 13 m inalt, coroana 10 m, h/l ~1,3.

    LISTA DE ELEMENTE (decuparea `beech_tree_a.png` + contractul; scrisa INAINTE
    de geometrie):
      a) TRUNCHI drept, vizibil de la sol pana la ~4,5 m, Ø ~0,8 m la baza, cu
         4 pinteni de radacina (runda 2: ramificat de la ~4,6 m); GRI si NETED (contractul; pe plansa e maro -- urmez
         contractul: scoarta fagului e gri, MARBLE_GREY 29).
      b) RAMIFICAT SUS: la ~5,2 m trunchiul se desface in 7 brate (unul spre
         fiecare masa), vizibile in golurile de sub coroana (plansa: 3-4 brate
         vizibile intre mase).
      c) COROANA ovala, LATA (10 m), din 7 MASE (contractul 5-7): varful, doua sus
         pe laturi, una in fata, una in spate, doua jos pe laturi; fiecare masa =
         miez + 9 ciorchini fatetati pe suprafata -> conturul zimtat de ciorchini
         din plansa (~18-20 vizibili din fata).
      d) baza coroanei la ~4,8 m; coroana coboara mai jos pe laturi (masele de jos).
      e) NU intra: umbra de sol, iarba.
    Noduri: Beech_Bark (MARBLE_GREY 29), Beech_Leaves (TROPICAL_GREEN 21 -> clasa
    beech_canopy, tenta recalculata la integrare).
    """
    bark, lv = Builder(), Builder()
    bark.taper_sweep([(0, 0, 0.0), (0.04, 0.0, 2.5), (0.08, 0.04, 4.8)], [0.42, 0.33, 0.27],
                     TF_BARK_GREY, segments=8)
    _root_flare(bark, 0.40, 3)
    # runda 2: coroana coboara pe laturi pana la ~4 m (pe plansa baza coroanei e
    # la ~1/3 din inaltime), mase mai mari si mai joase, ciorchini mai mari si
    # turtiti (runda 1: bule rotunde pe un bat lung -- "acadea")
    masses = [((0.0, 0.0, 10.3), (2.8, 2.8, 2.0)), ((-2.6, 0.5, 8.6), (2.5, 2.5, 2.0)),
              ((2.7, -0.4, 8.4), (2.5, 2.5, 2.0)), ((0.3, 2.3, 7.4), (2.5, 2.2, 2.0)),
              ((-0.4, -2.4, 7.6), (2.4, 2.2, 2.0)), ((-2.8, -0.8, 5.9), (2.3, 2.2, 1.7)),
              ((2.9, 1.0, 5.7), (2.3, 2.2, 1.7))]
    _limbs_to(bark, (0.08, 0.04, 4.6), masses, seed=5)
    for i, (c, rad) in enumerate(masses):
        crown_mass(lv, c, rad, TF_LEAF, seed=200 + i * 7, n=7, clump_size=2.2, el_lo=-0.45,
                   squash=0.72, core_scale=0.70)
    return [bark.to_object("Beech_Bark"), lv.to_object("Beech_Leaves")]


def build_beech_tree_b():
    """Fagul B (`beech_tree_b`): 10 m inalt, coroana 9 m, usor aplecat, h/l ~1,1.

    LISTA DE ELEMENTE (decuparea `beech_tree_b.png` + CORECTURA kitului: pe
    plansa b e aproape identic cu a -- trunchi drept, coroana rotunda; urmez
    corectura: "alta silueta", fag de margine de padure):
      a) TRUNCHI gri, neted, scurt, care se DESFACE IN DOUA la 3 m (doi conducatori
         divergenti, cel din dreapta mai lung si mai culcat).
      b) tot arborele APLECAT ~5 grade spre +X (spre lumina, marginea padurii).
      c) COROANA ASIMETRICA si mai JOASA (baza la ~4 m): 6 MASE -- doua pe
         conducatori, una sus intre ei, o masa JOASA iesita spre +X (partea
         luminata), una mica spre -X, una in fata; mai multa masa pe +X.
      d) bratele vizibile sub coroana, ca la a (runda 3: miezul maselor mai mic
         si ridicat, ca bratele sa se vada prin goluri).
      e) NU intra: umbra, iarba.
    Noduri: Beech_Bark (MARBLE_GREY 29), Beech_Leaves (TROPICAL_GREEN 21).
    """
    bark, lv = Builder(), Builder()
    # runda 3: furca la 2,7 m, conducatorii diverg mai larg (in runda 2 furca
    # intra aproape imediat in coroana si trunchiul citea simplu)
    bark.taper_sweep([(0, 0, 0.0), (0.03, 0.0, 1.5), (0.06, 0.0, 2.8)], [0.36, 0.30, 0.27],
                     TF_BARK_GREY, segments=8)
    _root_flare(bark, 0.36, 9)
    fork = Vector((0.06, 0.0, 2.7))
    lead1 = [fork, Vector((-0.75, 0.15, 4.3)), Vector((-1.3, 0.25, 6.4))]
    lead2 = [fork, Vector((1.2, -0.1, 3.9)), Vector((2.2, -0.2, 5.6))]
    branch(bark, lead1, 0.22, 0.12, TF_BARK_GREY, seg=7)
    branch(bark, lead2, 0.22, 0.12, TF_BARK_GREY, seg=7)
    m1 = [((-1.2, 0.3, 7.5), (2.3, 2.2, 1.8)), ((0.5, 0.2, 8.2), (2.3, 2.2, 1.6)),
          ((-2.3, -0.5, 5.6), (1.8, 1.7, 1.4))]
    m2 = [((2.2, -0.2, 6.8), (2.5, 2.3, 1.8)), ((3.4, 0.4, 5.0), (2.0, 1.9, 1.4)),
          ((1.2, 2.0, 5.6), (2.0, 1.7, 1.5))]
    _limbs_to(bark, lead1[-1], m1, r0=0.12, r1=0.06, seed=11)
    _limbs_to(bark, lead2[-1], m2, r0=0.12, r1=0.06, seed=12)
    for i, (c, rad) in enumerate(m1 + m2):
        crown_mass(lv, c, rad, TF_LEAF, seed=400 + i * 7, n=7, clump_size=2.0, el_lo=-0.45,
                   squash=0.72, core_scale=0.70)
    _shear([bark, lv], 5.0)
    return [bark.to_object("Beech_Bark"), lv.to_object("Beech_Leaves")]


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

if _want("beech_tree_a"):
    emit_tf(build_beech_tree_a(), "plants/beech_tree_a.glb", _ao(13.0, 1.6, 0.5),
            keep_xy=True, bevel=0.0, smooth_angle=None)
if _want("beech_tree_b"):
    emit_tf(build_beech_tree_b(), "plants/beech_tree_b.glb", _ao(10.0, 1.6, 0.5),
            keep_xy=True, bevel=0.0, smooth_angle=None)

report_tf()
