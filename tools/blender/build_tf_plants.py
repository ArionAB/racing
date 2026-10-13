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

# runda 2 a refacerii: placi mai LATE (0,7-0,8 m), mai subtiri (0,16 m) si cu
# zimti mai adanci -- in runda 1 citeau ca bare de caramida cu margine valurita
JN_T = 0.16
JN_NOTCH = 0.40


def _jneapan(branches, seed, upright=(), center=()):
    """branches = [(azimut, lungime, cota_varf, [(t, lung, lat, gros, pitch), ...])]
    Ramura: porneste din centru culcata pe sol, se ridica la capat. Pe ea:
    PLACI de ace (needle_pad) la fractiile t, suprapuse ca solzii -- fiecare
    placa urmatoare putin mai sus si mai ridicata, alternand stanga/dreapta.
    upright = [(azimut, lungime, cota_varf, lung, lat, pitch)] ramuri care urca
    din centru; center = [(azimut, raza, z, lung, lat, pitch)] placi joase in
    centru (acopera golul dintre ramuri)."""
    bark, nd = Builder(), Builder()
    r = _rnd(seed)
    for k, (az, L, ztip, pads) in enumerate(branches):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        side = Vector((-d.y, d.x, 0.0))
        bend = side * ((r() - 0.5) * 0.3)
        path = [Vector((0.0, 0.0, 0.05)), d * (0.40 * L) + Vector((0, 0, 0.16)) + bend * 0.5,
                d * (0.78 * L) + bend + Vector((0, 0, 0.18 + (ztip - 0.18) * 0.35)),
                d * L + bend * 1.3 + Vector((0, 0, ztip))]
        branch(bark, path, 0.10, 0.035, TF_WOOD, seg=5)

        def at(t):
            f = t * (len(path) - 1)
            i = min(int(f), len(path) - 2)
            return path[i].lerp(path[i + 1], f - i)
        for j, (t, pl, pw, ph, pitch) in enumerate(pads):
            sgn = 1.0 if (j + k) % 2 else -1.0
            p = (at(t) + side * (sgn * 0.07) + Vector((0.0, 0.0, ph * 0.45 + 0.03 * j)))
            needle_pad(nd, p, az + sgn * (6.0 + 6.0 * r()), pl, pw, ph, TF_NEEDLES,
                       seed=seed * 100 + k * 10 + j, teeth=3, pitch=pitch,
                       roll=sgn * 6.0, notch=JN_NOTCH)
    for k, (az, L, ztip, pl, pw, pitch) in enumerate(upright):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        tip = d * L + Vector((0.0, 0.0, ztip))
        branch(bark, [Vector((0.0, 0.0, 0.05)), d * (0.35 * L) + Vector((0, 0, ztip * 0.5)), tip],
               0.08, 0.035, TF_WOOD, seg=5)
        needle_pad(nd, d * (0.55 * L + pl * 0.3) + Vector((0, 0, ztip * 0.80)), az, pl, pw,
                   JN_T, TF_NEEDLES, seed=seed * 100 + 70 + k, teeth=3, pitch=pitch,
                   notch=JN_NOTCH)
    for k, (az, rad, z, pl, pw, pitch) in enumerate(center):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        needle_pad(nd, d * rad + Vector((0, 0, z)), az, pl, pw, JN_T, TF_NEEDLES,
                   seed=seed * 100 + 90 + k, teeth=3, pitch=pitch, notch=JN_NOTCH)
    return [bark.to_object("Jneapan_Bark"), nd.to_object("Jneapan_Needles")]


def build_jneapan_a():
    """Jneapanul A (`jneapan_a`): 1,2 m inalt, 4 m lat, h/l ~0,3 -- tufa CULCATA.
    REFACUT pe contractul clarificat de coordonator (13 oct): perne = PLACI PLATE.

    LISTA DE ELEMENTE (decuparea `jneapan_a.png` + contractul clarificat; scrisa
    INAINTE de geometrie):
      a) 6 RAMURI groase (plansa: 6-7 vizibile) care pornesc din CENTRU,
         culcate pe sol (0,05-0,2 m), si se RIDICA la capete (varfurile la
         0,5-0,85 m); lungi de 1,55-1,9 m, maro (WOOD 9), vizibile intre placi.
      b) PLACI DE ACE: 3 pe fiecare ramura (18), fiecare o placa PLATA alungita
         pe ramura, ca o frunza de feriga: 0,95-1,15 m lunga, 0,7-0,8 m lata,
         0,16 m groasa, marginea ZIMTATA adanc pe lung (3 dinti pe parte), capete
         ascutite; suprapuse ca SOLZII (fiecare urmatoare mai sus, alternand
         stanga/dreapta), aproape orizontale, ridicate spre capat (4/9/16 grade).
      c) 3 placi joase in centru, intre ramuri (centrul ramane JOS; ramurile maro
         se vad) -- NU e un brad mic.
      d) NU intra: pietrele de la baza de pe plansa.
    Buget: <= 1 500 tri (MultiMesh, sute de exemplare). Runda 1-3 (inainte de
    clarificare): ciorchini pentagonali in sir, 3 792 tri -- "margele pe ata".
    Noduri: Jneapan_Bark (WOOD 9), Jneapan_Needles (LOG_DARK 28 -> clasa
    pine_needles; in preview tinta #34503A).
    """
    pads = lambda s: [(0.36, 1.05 * s, 0.80, JN_T, 4.0), (0.64, 1.15 * s, 0.76, JN_T, 9.0),
                      (0.93, 1.05 * s, 0.68, JN_T, 16.0)]
    branches = [(8.0, 1.85, 0.62, pads(1.0)), (68.0, 1.60, 0.80, pads(0.92)),
                (128.0, 1.90, 0.55, pads(1.05)), (188.0, 1.55, 0.85, pads(0.92)),
                (245.0, 1.80, 0.50, pads(1.0)), (305.0, 1.65, 0.70, pads(0.95))]
    center = [(38.0, 0.40, 0.30, 0.95, 0.75, 10.0), (158.0, 0.40, 0.32, 0.95, 0.75, 10.0),
              (275.0, 0.40, 0.28, 0.95, 0.75, 10.0)]
    return _jneapan(branches, 31, center=center)


def build_jneapan_b():
    """Jneapanul B (`jneapan_b`): 1,5 m inalt, 3 m lat, h/l ~0,5 -- compact,
    mai inalt, ASIMETRIC, cu o perna iesita intr-o parte. REFACUT pe contractul
    clarificat (placi plate).

    LISTA DE ELEMENTE (decuparea `jneapan_b.png` + contractul; plansa b e aproape
    identica cu a, deci urmez contractul pentru silueta):
      a) 5 RAMURI culcate: 4 scurte (0,95-1,15 m), cu varfurile la 0,8-1,05 m, +
         1 LUNGA spre +X (1,6 m), joasa, cu 3 placi -> perna iesita intr-o parte.
      b) 3 RAMURI care URCA din centru (varfuri la 1,1-1,2 m), fiecare cu o placa
         ridicata 28-34 grade: dau inaltimea de 1,5 m.
      c) PLACI plate, zimtate, ca la a: 3 pe fiecare ramura, 1 in centru, 3 pe
         ramurile care urca (19 placi; runda 2: tufa mai deasa).
      d) NU intra: pietrele, pamantul de la baza.
    Buget <= 1 500 tri. Noduri: Jneapan_Bark (WOOD 9), Jneapan_Needles (LOG_DARK 28).
    """
    sh = lambda: [(0.30, 0.85, 0.70, JN_T, 5.0), (0.62, 0.90, 0.70, JN_T, 10.0),
                  (0.95, 0.85, 0.64, JN_T, 18.0)]
    branches = [(0.0, 1.60, 0.40, [(0.36, 1.05, 0.80, JN_T, 3.0), (0.64, 1.10, 0.78, JN_T, 5.0),
                                   (0.93, 1.00, 0.72, JN_T, 10.0)]),
                (90.0, 1.05, 0.95, sh()), (160.0, 1.15, 1.05, sh()),
                (230.0, 0.95, 0.90, sh()), (300.0, 1.10, 0.80, sh())]
    upright = [(40.0, 0.45, 1.20, 0.90, 0.68, 30.0), (150.0, 0.40, 1.15, 0.85, 0.66, 34.0),
               (260.0, 0.45, 1.25, 0.90, 0.68, 28.0)]
    center = [(200.0, 0.20, 0.55, 0.85, 0.72, 12.0)]
    return _jneapan(branches, 47, upright=upright, center=center)


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
        # pinteni scurti si grosi (runda 2 a fagului: cei lungi si ascutiti
        # citeau ca picioare de paianjen)
        bark.taper_sweep([d * (r0 * 0.35) + Vector((0, 0, 0.75)), d * (r0 * 0.95) + Vector((0, 0, 0.22)),
                          d * (r0 * 1.55) + Vector((0, 0, 0.0))],
                         [r0 * 0.55, r0 * 0.42, r0 * 0.12], TF_BARK_GREY, segments=5)


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
    """Fagul A (`beech_tree_a`): ~12,5 m inalt, coroana ~10 m, h/l ~1,25.
    REFACUT pe contractul clarificat de coordonator (13 oct; runda 1-3 citea
    "acadea": coroana sus pe un trunchi gol, bratele nevazute).

    LISTA DE ELEMENTE (decuparea `beech_tree_a.png` + contractul clarificat;
    scrisa INAINTE de geometrie):
      a) TRUNCHI SCURT si GROS: O 0,7 m la baza, 5 pinteni de radacina evazati,
         3 m pana la ramificare; GRI (MARBLE_GREY 29), inchis la baza prin AO.
      b) 4 BRATE GROASE (O 0,44 -> 0,24 m) care pornesc in EVANTAI de la 2,9 m si
         intra in coroana la ~4,9 m, la 2,6 m de axa -- se vad intre sol si
         coroana, ca pe plansa (3-4 brate vizibile).
      c) COROANA JOASA si LATA, aproape rotunda (h coroana / l ~0,85): baza la
         ~3,8 m, latimea ~10-11 m, varful la ~12 m; din 7 MASE: 4 jos, pe
         capetele bratelor (inel), 2 la mijloc departate de axa, 1 sus lata si
         turtita; ciorchini mari, turtiti.
      d) GOLURI in partea de jos a coroanei: masele de jos au ciorchini doar de la
         ecuator in sus si miezul mic, iar intre ele (pe azimuturi alternate cu
         bratele) ramane gol -> bratele se vad prin el.
      e) NU intra: umbra, iarba.
    Noduri: Beech_Bark (MARBLE_GREY 29), Beech_Leaves (TROPICAL_GREEN 21 -> clasa
    beech_canopy, tenta recalculata la integrare).
    """
    bark, lv = Builder(), Builder()
    bark.taper_sweep([(0, 0, 0.0), (0.02, 0.0, 1.5), (0.04, 0.02, 3.1)], [0.35, 0.31, 0.29],
                     TF_BARK_GREY, segments=8)
    _root_flare(bark, 0.42, 3, n=5)
    fork = Vector((0.04, 0.02, 2.9))
    ring = []
    for k, az in enumerate((15.0, 105.0, 195.0, 285.0)):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        end = d * 2.6 + Vector((0.0, 0.0, 4.9))
        mid = fork.lerp(end, 0.5) + Vector((0.0, 0.0, -0.15))
        branch(bark, [fork, mid, end + d * 0.3 + Vector((0, 0, 0.4))], 0.22, 0.12,
               TF_BARK_GREY, seg=7)
        ring.append(((end.x + d.x * 0.2, end.y + d.y * 0.2, 5.0), (2.3, 2.3, 1.7)))
    # runda 2: masele de mijloc mai departe de axa si varful mai lat si mai
    # turtit -> dom rotund si lat (runda 1: coloana ingusta de 9 m, etajata)
    upper = [((0.0, 0.0, 9.2), (3.3, 3.3, 1.9)), ((2.2, -2.0, 7.4), (2.4, 2.4, 1.9)),
             ((-2.2, 2.0, 7.5), (2.4, 2.4, 1.9))]
    _limbs_to(bark, (0.04, 0.02, 3.4), upper, frac=0.6, r0=0.15, r1=0.07, seed=5)
    for i, (c, rad) in enumerate(ring):
        crown_mass(lv, c, rad, TF_LEAF, seed=200 + i * 7, n=7, clump_size=2.0, el_lo=-0.12,
                   squash=0.72, core_scale=0.62)
    for i, (c, rad) in enumerate(upper):
        crown_mass(lv, c, rad, TF_LEAF, seed=260 + i * 7, n=8, clump_size=2.1, el_lo=-0.35,
                   squash=0.72, core_scale=0.72)
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
    # reglaj (coordonator, 13 oct): trunchi ingrosat la fel ca a
    bark.taper_sweep([(0, 0, 0.0), (0.03, 0.0, 1.5), (0.06, 0.0, 2.8)], [0.38, 0.33, 0.31],
                     TF_BARK_GREY, segments=8)
    _root_flare(bark, 0.42, 9, n=5)
    fork = Vector((0.06, 0.0, 2.7))
    lead1 = [fork, Vector((-0.75, 0.15, 4.3)), Vector((-1.3, 0.25, 6.4))]
    lead2 = [fork, Vector((1.2, -0.1, 3.9)), Vector((2.2, -0.2, 5.6))]
    branch(bark, lead1, 0.26, 0.15, TF_BARK_GREY, seg=7)
    branch(bark, lead2, 0.26, 0.15, TF_BARK_GREY, seg=7)
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


# ---------------------------------------------------------------------------
# tufele mici: bujorul de munte (Rhododendron myrtifolium) si afinul
# ---------------------------------------------------------------------------

def _dome_points(n, rx, ry, rz, z0, seed, el_lo=0.0):
    """n puncte pe o calota de elipsoid (spirala Fibonacci, doar deasupra lui
    el_lo), centrul la z0."""
    r = _rnd(seed)
    ga = math.pi * (3.0 - math.sqrt(5.0))
    out = []
    i = 0
    while len(out) < n and i < n * 6:
        zz = 1.0 - (i + 0.5) / (n * 1.4)
        i += 1
        if zz < el_lo:
            continue
        rr = math.sqrt(max(0.0, 1.0 - zz * zz))
        a = ga * i + seed
        out.append(Vector((rx * rr * math.cos(a) * (0.92 + 0.12 * r()),
                           ry * rr * math.sin(a) * (0.92 + 0.12 * r()),
                           z0 + rz * zz)))
    return out


def build_bujor_de_munte():
    """Bujorul de munte (`bujor_de_munte`): 0,6 m inalt, 1,2 m lat, h/l ~0,5.

    LISTA DE ELEMENTE (decuparea `bujor_de_munte.png` + contractul; scrisa
    INAINTE de geometrie):
      a) TUFA joasa si DEASA: o calota de frunzis 1,2 x 1,0 x 0,5 m din 12
         ciorchini verzi.
      b) ROZETE DE FRUNZE alungite pe margine, jos (plansa: ~12 frunze verzi
         care ies de sub flori, mai ales in fata si pe laturi): 12 frunze cu
         pliu in V (leaf_vfold), radiale, usor aplecate.
      c) 8 CAPETE DE FLORI magenta la varful ramurilor, pe calota de sus
         (plansa: 6-7 capete mari), fiecare din 7 bulgarasi (~0,4 m diametru)
         -> ~40-50% din suprafata vazuta de sus (contract: ~40%).
      d) NU intra: umbra, solul.
    Noduri: Bujor_Leaves (TROPICAL_GREEN 21), Bujor_Bloom (FLAMINGO_PINK 31,
    --allow-slots=31). FLAMINGO_PINK e #D2A0BE (roz pal): magenta #B63A7A vine din
    tenta la integrare (kit §0, tabelul de sloturi).
    """
    lv, bl = Builder(), Builder()
    r = _rnd(61)
    for i, p in enumerate(_dome_points(12, 0.48, 0.40, 0.30, 0.12, 61, el_lo=-0.2)):
        clump(lv, p, (0.40, 0.36, 0.30), TF_LEAF, seed=610 + i, seg=6, rings=3, dev=0.2)
    for i in range(12):
        az = i * 30.0 + (r() - 0.5) * 14.0
        a = math.radians(az)
        base = Vector((0.36 * math.cos(a), 0.30 * math.sin(a), 0.10 + 0.08 * r()))
        leaf_vfold(lv, base, az, 0.32 + 0.06 * r(), 0.10, 0.06, TF_LEAF, fold_deg=22.0,
                   stations=4, thick=0.015, droop=0.30)
    # runda 2: 8 capete MARI (~0,4 m), mai sus -- runda 1 avea 7 capete de
    # ~0,28 m, ~15% din suprafata de sus, fata de ~40% cerut (plansa: ~60%)
    heads = _dome_points(8, 0.42, 0.34, 0.30, 0.24, 67, el_lo=0.05)
    for i, h in enumerate(heads):
        for j in range(6):
            a = j * 60.0 + 25.0 * r()
            off = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0.0)) * 0.12
            p = h + off + Vector((0.0, 0.0, 0.03 + 0.04 * r()))
            clump(bl, p, (0.19, 0.19, 0.14), TF_BLOOM, seed=700 + i * 9 + j, seg=5, rings=2,
                  dev=0.2)
        clump(bl, h + Vector((0.0, 0.0, 0.10)), (0.20, 0.20, 0.14), TF_BLOOM, seed=790 + i,
              seg=5, rings=2, dev=0.2)
    return [lv.to_object("Bujor_Leaves"), bl.to_object("Bujor_Bloom")]


def build_afin():
    """Afinul (`afin`): 0,5 m inalt, 0,9 m lat, h/l ~0,55.

    LISTA DE ELEMENTE (decuparea `afin.png` + contractul; scrisa INAINTE de
    geometrie):
      a) TUFA MARUNTA, DREAPTA: un miez de 6 ciorchini de frunze.
      b) 13 CRENGUTE cu frunze (plansa: ~10-12 "crengute" ca de feriga), fiecare
         din 4 ciorchini care se subtiaza spre varf, pe DOUA inele: 5 in centru,
         aproape verticale, varfurile la 0,44-0,5 m; 8 pe margine, culcate spre
         afara, varfurile la 0,24-0,32 m, raza 0,36-0,42 m, cu goluri intre ele
         -> calota aerisita, lata de ~0,9 m.
      c) BOBITE albastru-inchis in puncte mici: 25-30 de ~7 cm, pe suprafata
         ciorchinilor de pe crengute, spre exterior si sus, vizibile (plansa ~20;
         reglajul coordonatorului: 20-30).
      d) NU intra: umbra, solul.
    Noduri: Afin_Leaves (TROPICAL_GREEN 21), Afin_Berry (ICE_DEEP 25).
    """
    lv, be = Builder(), Builder()
    r = _rnd(81)
    # runda 2: tufa DREAPTA din 13 crengute cu frunze (plansa), nu o movila de
    # bulgari cu frunze-foaie (runda 1: 0,37 m in loc de 0,5, citea a varza)
    # runda 3: DOUA inele de crengute -- 5 interioare, aproape verticale, inalte
    # (0,45-0,5 m), 9 exterioare, joase si culcate spre afara (0,24-0,32 m) ->
    # calota cu centrul cel mai inalt; runda 2 avea un singur inel evazat si
    # citea ca o vaza goala la mijloc
    # reglaj (coordonator, 13 oct): mai AERISIT (miez mai mic, 8 crengute
    # exterioare cu goluri intre ele), latimea la cota (0,9 m), 25-30 de bobite
    # VIZIBILE (iesite din ciorchini, nu ascunse in ei)
    for i, p in enumerate(_dome_points(4, 0.14, 0.12, 0.14, 0.14, 81, el_lo=-0.2)):
        clump(lv, p, (0.22, 0.20, 0.20), TF_LEAF, seed=810 + i, seg=6, rings=3, dev=0.2)
    tips = []
    leaves_at = []
    rings_spec = [(5, 0.07, 0.06, 0.44, 0.06), (8, 0.36, 0.06, 0.24, 0.08)]
    i = -1
    for (cnt, r_lo, r_var, z_lo, z_var) in rings_spec:
      for _j in range(cnt):
        i += 1
        az = _j * (360.0 / cnt) + (r() - 0.5) * 18.0 + (20.0 if cnt == 5 else 0.0)
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        rr = r_lo + r_var * r()
        zt = z_lo + z_var * r()
        p0 = d * 0.05 + Vector((0, 0, 0.06))
        p1 = d * (rr * 0.55) + Vector((0, 0, zt * 0.55))
        p2 = d * rr + Vector((0, 0, zt))
        for k, t in enumerate((0.35, 0.62, 0.86, 1.0)):
            q = p0.lerp(p1, t * 2) if t < 0.5 else p1.lerp(p2, (t - 0.5) * 2)
            sz = 0.19 - 0.025 * k
            clump(lv, q, (sz * 1.1, sz * 0.8, sz * 0.75), TF_LEAF, seed=900 + i * 5 + k,
                  seg=5, rings=2, dev=0.22, yaw=az + 90.0, tilt=0.4)
            leaves_at.append((q, d, sz, k))
        tips.append((d, rr, zt))
    # bobitele: pe suprafata ciorchinilor de pe crengute (k = 1..3), spre
    # exterior si in sus, ca sa se vada (runda 3: ~20, dar 2/3 ascunse in frunze)
    k = 0
    for (q, d, sz, kk) in leaves_at:
        if kk == 0 or r() < 0.30:
            continue
        side = Vector((-d.y, d.x, 0.0)) * ((r() - 0.5) * sz * 0.8)
        pos = q + d * (sz * 0.42) + side + Vector((0.0, 0.0, sz * 0.28))
        be.boulder(tuple(pos), (0.07, 0.07, 0.07), TF_BERRY, seed=880 + k, segments=5,
                   rings=2, deviation=0.05)
        k += 1
    print("afin: bobite", k)
    return [lv.to_object("Afin_Leaves"), be.to_object("Afin_Berry")]


# placile de ace: fetele evantaiului de sus (unghiuri mici) se netezesc, muchiile
# laterale (~90 grade) raman vii -> placa se citeste plata, cu margine taiata
JNEAPAN_SMOOTH = 50.0

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
    emit_tf(build_beech_tree_a(), "plants/beech_tree_a.glb", _ao(12.5, 1.6, 0.42),
            keep_xy=True, bevel=0.0, smooth_angle=None)
if _want("beech_tree_b"):
    emit_tf(build_beech_tree_b(), "plants/beech_tree_b.glb", _ao(10.0, 1.6, 0.42),
            keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("bujor_de_munte"):
    emit_tf(build_bujor_de_munte(), "plants/bujor_de_munte.glb", _ao(0.6, 0.3, 0.6),
            keep_xy=False, bevel=0.0, smooth_angle=None)
if _want("afin"):
    emit_tf(build_afin(), "plants/afin.glb", _ao(0.5, 0.25, 0.6),
            keep_xy=False, bevel=0.0, smooth_angle=None)

report_tf()
