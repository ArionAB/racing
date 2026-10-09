"""Okinawa v2 -- plantele (brief docs/asset_briefs/okinawa_kit_v2.md §1.3).

  okinawa/plants/fukugi_tree_a.glb   stalp de frunzis 7 m x 2,8 m   (Fukugi_Bark, Fukugi_Leaves)
  okinawa/plants/fukugi_tree_b.glb   8,5 m x 3 m, mai zvelt, varf ascutit
  okinawa/plants/fukugi_tree_c.glb   5,5 m x 2,6 m, plin, o masa laterala
  okinawa/plants/ryukyu_pine.glb     pin bonsai 9 m x 9 m              (Pine_Bark, Pine_Leaves)
  okinawa/plants/cycad.glb           cicada 2,2 m x 2,6 m              (Cycad_Bark, Cycad_Leaves)
  okinawa/plants/fan_palm.glb        palmier-evantai 6 m               (Palm_Bark, Palm_Leaves)
  okinawa/plants/bougainvillea.glb   tufa cu spatele plat 1,6 x 2,4 m  (Bougainvillea_Leaves, Bougainvillea_Bloom)

Plantele merg pe MultiMesh: UN mesh compact per material, origine la baza
trunchiului (la bougainvillea: la baza peretelui de care se lipeste), scala
aplicata pe radacini. Primitive rotunde cu `segments` setat (6-10).
Vocabularul (`foliage_column`, `foliage_pillow`, `ring_trunk`, `pleated_fan`,
`serrated_frond`) e la finalul `okinawa_shapes.py`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_okinawa_plants.py
Variabila de mediu OK_ONLY=<piesa> reface doar piesa respectiva.

Fara text, cifre sau logo-uri (regula 9).
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

LEAF = TROPICAL_GREEN      # 21
LEAF2 = CACTUS_GREEN       # 12 (cicada, palmier)
DRY = DRY_VEGETATION       # 13
BARK = WOOD                # 9
BARK_D = LOG_DARK          # 28
BLOOM = FLAMINGO_PINK      # 31 (--allow-slots=31)


def _norm(o):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(o.data)
    bm.free()


def _stub(b, h=1.25, r0=0.30):
    """Ciotul de trunchi al fukugi: ~0,8 m se vad sub frunzis, restul intra in
    el. Doua tronsoane (baza WOOD, partea umbrita LOG_DARK). Primele puncte au
    acelasi xy (lectia banyanului: primul inel al unui sweep inclinat intra
    sub sol)."""
    b.taper_sweep([(0, 0, 0.0), (0, 0, 0.30), (0.02, 0.0, 0.62)],
                  [r0 * 1.15, r0 * 0.9, r0 * 0.8], BARK, segments=7)
    b.taper_sweep([(0.02, 0.0, 0.62), (0.04, 0.02, 1.0), (0.04, 0.03, h)],
                  [r0 * 0.85, r0 * 0.7, r0 * 0.55], BARK_D, segments=7)


# ---------------------------------------------------------------------------
# fukugi -- piesa critica (stalp de frunzis, NU coroana rotunda de pe planse)
# ---------------------------------------------------------------------------

def build_fukugi(variant):
    """Fukugi (Garcinia subelliptica), 3 variante. RUNDA 4 (cerere coordonator):
    frunzisul = ANVELOPA DE CIORCHINI, nu mase netede cu cubulete.

    LISTA DE ELEMENTE (urmeaza CORECTURA de coordonator din kit §0.1/sus, nu
    decuparea: pe planse sunt foioase cu coroana rotunda, trunchi la vedere,
    verde deschis -- GRESIT; din decupare iau textura frunzisului: zeci de
    ciorchini fatetati de marime medie, vizibili pe contur, cu umbra intre ei):
      a) 7,0 x 2,8 m (h/l 2,5): miez de 6 elipsoizi suprapusi pe verticala (pas
         ~0,9 m, nevazut: 90% din raza) acoperit de ~45-54 CIORCHINI de ~0,65-1,1 m
         (boulder fatetat turtit, 6 seg x 3 inele, spin aleator, seed fix pe
         varianta), conturul ZIMTAT de ciorchini; varf rotunjit; frunzisul
         incepe la 0,8 m de sol
      b) 8,5 x 3,0 m (h/l 2,8): 7 elipsoizi, mai zvelt; ultimii trei se
         ingusteaza (88/66/40%), masa de sus inalta -> varf ASCUTIT
      c) 5,5 x 2,6 m (h/l 2,1): 5 elipsoizi + O MASA LATERALA spre +X la ~2,45 m
         (asimetric), acoperite la fel
      d) DOUA TONURI: ~28% din ciorchini, cei cu normala in sus, in nodul
         Fukugi_Leaves_Tip (CACTUS_GREEN 12, galben-verzui); restul in
         Fukugi_Leaves (TROPICAL_GREEN 21)
      e) trunchi: DOAR un ciot de ~0,8 m (WOOD jos, LOG_DARK sus); fara cubulete,
         flori, fructe sau vegetatie lipita
    Noduri: Fukugi_Leaves (21), Fukugi_Leaves_Tip (12), Fukugi_Bark (9 / 28).
    """
    spec = {
        "a": dict(H=6.7, W=2.5, n=6, tip="round", seed=11, per=14),
        "b": dict(H=8.2, W=2.65, n=7, tip="sharp", seed=23, per=13),
        "c": dict(H=5.3, W=1.95, n=5, tip="round", seed=37, per=15),
    }[variant]
    bark, leaves, tipb = Builder(), Builder(), Builder()
    _stub(bark, r0=0.20 if variant != "b" else 0.18)
    ells = column_ellipsoids(spec["H"], spec["W"], spec["n"], tip=spec["tip"],
                             seed=spec["seed"])
    if variant == "c":
        ells.append((0.72, 0.0, 2.3, 0.60, 0.58, 0.60))
    for (cx, cy, cz, rx, ry, rz) in ells:      # miezul (nu se vede prin ciorchini)
        leaves.boulder((cx, cy, cz), (2 * rx * 0.9, 2 * ry * 0.9, 2 * rz * 0.95),
                       LEAF, seed=spec["seed"] + int(cz * 10), segments=8, rings=3,
                       deviation=0.10)
    anchors = ellipsoid_anchors(ells, spec["per"], spec["seed"], el_lo=-0.7,
                                max_n=54)
    print("fukugi", variant, "ciorchini:", len(anchors))
    foliage_clumps(leaves, tipb, anchors, 0.36 * spec["W"], LEAF, LEAF2,
                   spec["seed"], tip_frac=0.28, push=0.06)
    return [leaves.to_object("Fukugi_Leaves"), tipb.to_object("Fukugi_Leaves_Tip"),
            bark.to_object("Fukugi_Bark")]


# ---------------------------------------------------------------------------
# pinul Ryukyu
# ---------------------------------------------------------------------------

def build_pine():
    """Pin Ryukyu (bonsai urias), `ryukyu_pine`. Runda 4: pernele = ciorchini.

    LISTA DE ELEMENTE (din decuparea `ryukyu_pine.png` + contractul §1.3):
      a) 1 trunchi gros, rasucit (S) si aplecat, 7 puncte, r 0,8 -> 0,28,
         radacina evazata (4 pinteni)
      b) 5 brate: stanga-jos (lung, se ridica la capat), dreapta, spate, ramura
         scurta spre fata, ramura sus-stanga, plus lider vertical
      c) 7 PERNE turtite cu goluri intre ele; fiecare = miez turtit + 11
         CIORCHINI (~0,3 din latimea pernei), ~28% (cei cu normala in sus) pe
         al doilea ton (Pine_Leaves_Tip, CACTUS_GREEN 12)
      d) FARA stanci/tufe/nisip de la baza (nu intra in GLB, kit §0.1)
    Cote tinta: 9 m x ~9 m. Noduri: Pine_Bark (WOOD 9 / LOG_DARK 28),
    Pine_Leaves (TROPICAL_GREEN 21), Pine_Leaves_Tip (CACTUS_GREEN 12).
    """
    bark, leaves, tipb = Builder(), Builder(), Builder()
    trunk = [(0, 0, 0.0), (0, 0, 0.35), (0.9, 0.3, 1.3), (1.6, 0.0, 2.6),
             (1.0, -0.4, 4.0), (1.3, 0.1, 5.4), (0.7, 0.0, 6.6)]
    bark.taper_sweep(trunk, [0.80, 0.74, 0.64, 0.52, 0.44, 0.36, 0.28], BARK,
                     segments=8)
    for k in range(4):
        a = 0.8 + k * 1.6
        d = Vector((math.cos(a), math.sin(a), 0.0))
        bark.taper_sweep([d * 0.55, d * 0.55 + Vector((0, 0, 0.12)),
                          d * 0.95 + Vector((0, 0, 0.05)),
                          d * 1.35 + Vector((0, 0, 0.0))],
                         [0.26, 0.24, 0.16, 0.0], BARK, segments=5)
    bark.taper_sweep([(0.7, 0.0, 6.5), (0.6, 0.0, 7.3), (0.5, 0.0, 8.2)],
                     [0.28, 0.2, 0.12], BARK_D, segments=6)
    arms = [
        ([(1.6, 0.0, 2.5), (0.3, 0.7, 3.3), (-1.6, 0.9, 3.9), (-2.9, 0.8, 4.4)],
         [0.30, 0.24, 0.17, 0.11]),
        ([(1.0, -0.4, 3.9), (1.9, -0.3, 3.9), (2.7, -0.4, 4.1)],
         [0.26, 0.19, 0.12]),
        ([(1.3, 0.1, 5.3), (1.0, -1.3, 5.6), (0.55, -2.4, 5.9)],
         [0.22, 0.17, 0.11]),
        ([(-1.6, 0.9, 3.9), (-1.8, 0.6, 4.8), (-1.5, 0.3, 5.6)],
         [0.14, 0.11, 0.08]),
        ([(1.0, -0.4, 3.9), (0.2, 1.0, 4.6), (-0.5, 1.8, 5.0)],
         [0.17, 0.12, 0.08]),
    ]
    for pts, rad in arms:
        bark.taper_sweep([Vector(p) for p in pts], rad, BARK_D, segments=6)
    pillows = [
        ((-3.0, 0.8, 4.95), 3.8, 3.3, 1.4, 5.0, 200),
        ((-1.4, 0.3, 6.25), 2.8, 2.5, 1.2, -4.0, 210),
        ((2.7, -0.4, 4.7), 3.4, 3.0, 1.4, -6.0, 220),
        ((0.55, -2.4, 6.5), 3.1, 2.9, 1.3, 5.0, 230),
        ((0.6, 0.1, 7.7), 4.6, 4.0, 1.7, 0.0, 240),
        ((0.7, 0.2, 8.5), 2.6, 2.3, 1.0, 4.0, 250),
        ((-0.6, 1.9, 5.5), 2.4, 2.1, 1.0, 3.0, 260),
    ]
    for c, w, d, h, tilt, seed in pillows:
        # miezul turtit (mai mic ca pernea, ascuns sub ciorchini)
        foliage_pillow(leaves, c, w * 0.78, d * 0.78, h * 0.8, LEAF, seed=seed,
                       bumps=0, seg=8, rings=3, tilt_deg=tilt, tilt_azim_deg=seed)
        a = math.radians(seed)
        axis = Vector((-math.sin(a), math.cos(a), 0.0))
        xf = Matrix.Translation(Vector(c)) @ Matrix.Rotation(math.radians(tilt), 4, axis)
        anchors = ellipsoid_anchors([(0, 0, 0, w * 0.40, d * 0.40, h * 0.46)], 15,
                                    seed, el_lo=-0.25, bury=0.0, max_n=11)
        foliage_clumps(leaves, tipb, anchors, 0.30 * w, LEAF, LEAF2, seed,
                       tip_frac=0.28, push=0.10, xform=xf)
    return [leaves.to_object("Pine_Leaves"), tipb.to_object("Pine_Leaves_Tip"),
            bark.to_object("Pine_Bark")]


# ---------------------------------------------------------------------------
# cicada
# ---------------------------------------------------------------------------

def build_cycad():
    """Cicada (sotetsu), `cycad`. Runda 4: frunze PENATE, rozeta plina.

    LISTA DE ELEMENTE (din decuparea `cycad.png`):
      a) trunchi scurt si gros (~1,05 m, r 0,4 -> 0,26), bombat
      b) solzi in geometrie: 3 randuri x 8 bulgari decalati (romburi)
      c) rozeta de 20 frunze PENATE: 7 interioare abrupte, 7 intermediare, 6
         exterioare cu varful arcuit in jos; fiecare = O nervura arcuita cu
         foliole inguste dese pe ambele parti (41 de statii alternante = ~20
         perechi, pieptene dintr-o singura lama), plan inclinat
      d) FARA stanci/nisip la baza
    Cote tinta: 2,2 m x 2,6 m. Noduri: Cycad_Bark (WOOD 9 / LOG_DARK 28),
    Cycad_Leaves (CACTUS_GREEN 12 + TROPICAL_GREEN 21).
    """
    bark, leaves = Builder(), Builder()
    bark.taper_sweep([(0, 0, 0.0), (0, 0, 0.12), (0, 0, 0.62), (0, 0, 1.2)],
                     [0.40, 0.38, 0.34, 0.26], BARK_D, segments=8)
    for row, z in enumerate((0.25, 0.57, 0.89)):
        r = 0.40 - row * 0.045
        off = math.radians(22.5) * (row % 2)
        for k in range(8):
            a = off + k * math.pi / 4
            bark.boulder((math.cos(a) * r, math.sin(a) * r, z),
                         (0.30, 0.30, 0.26), BARK, seed=500 + row * 8 + k,
                         segments=5, rings=2, deviation=0.14)
    tiers = [  # (n, elev, length, droop, start_z, base_r)
        (7, 76.0, 1.45, 0.30, 1.20, 0.08),
        (7, 52.0, 1.45, 0.65, 1.14, 0.14),
        (6, 30.0, 1.30, 0.95, 1.05, 0.20),
    ]
    rnd = _lcg(77)
    fi = 0
    for ti, (n, elev, L, droop, z0, br) in enumerate(tiers):
        for k in range(n):
            az = 360.0 * k / n + ti * 27.0 + (rnd() - 0.5) * 12.0
            ar = math.radians(az)
            base = (math.cos(ar) * br, math.sin(ar) * br, z0)
            slot = LEAF2 if fi % 2 else LEAF
            pinnate_frond(leaves, base, az, L * (0.94 + 0.12 * rnd()), 0.55,
                          elev + (rnd() - 0.5) * 8.0, slot, droop=droop, stations=31,
                          roll_deg=8.0 + 12.0 * rnd())
            fi += 1
    return [leaves.to_object("Cycad_Leaves"), bark.to_object("Cycad_Bark")]


# ---------------------------------------------------------------------------
# palmier-evantai
# ---------------------------------------------------------------------------

def _fan_leaf(leaves, bark, top, az_deg, pet_elev, plen, blade_elev, R, slot, pleats=9):
    """UN evantai pe petiol: petiolul pleaca din `top` spre `az_deg` sub
    `pet_elev` (usor arcuit), iar discul plisat (Ø 2R) sta cu centrul in capatul
    petiolului. Planul discului contine directia `blade_elev` (elevatia axei
    evantaiului fata de orizontala) si tangenta, deci NORMALA lui arata spre
    exterior (se citeste ca o palma deschisa din fata, nu pe cant)."""
    a = math.radians(az_deg)
    h = Vector((math.cos(a), math.sin(a), 0.0))
    z = Vector((0.0, 0.0, 1.0))
    e = math.radians(pet_elev)
    up_ = (h * math.cos(e) + z * math.sin(e)).normalized()
    end = top + up_ * plen
    mid = top + up_ * plen * 0.5 + z * (plen * 0.10)
    bark.taper_sweep([top, mid, end], [0.07, 0.055, 0.04], BARK_D, segments=5)
    eb = math.radians(blade_elev)
    u = (h * math.cos(eb) + z * math.sin(eb)).normalized()
    n = (-h * math.sin(eb) + z * math.cos(eb)).normalized()
    if n.dot(h) < 0:
        n = -n
    pleated_fan(leaves, end, u, n, R, slot, pleats=pleats, span_deg=265.0, depth=0.15,
                th=0.04, valley=0.76)


def build_fan_leaf_test():
    """UN evantai izolat (verificare inainte de coroana), pe petiol drept."""
    bark, leaves = Builder(), Builder()
    _fan_leaf(leaves, bark, Vector((0, 0, 0.0)), 0.0, 55.0, 1.5, 15.0, 0.95, LEAF)
    return [leaves.to_object("Palm_Leaves"), bark.to_object("Palm_Bark")]


def build_fan_palm():
    """Palmier-evantai (Livistona), `fan_palm` -- NU cocotier. RUNDA 5 (ok-g).

    LISTA DE ELEMENTE (decuparea `fan_palm.png` + verdictul de la runda 4:
    coroana asimetrica si mica, evantaie ilizibile, fusta galbena):
      a) trunchi Ø ~0,5 m (r 0,34 -> 0,22), 3,5 m, INELE la 0,30 m pana la 1,5 m;
         partea de sus (z 1,5..3,5): SOLZI IN ROMB cu muchii (laticea de 7
         randuri x 8 romburi decalate, varf spre exterior), nu bulgari
      b) coroana Ø ~4,5-5 m: 11 EVANTAIE ROTUNDE PLISATE (Ø 1,8-1,9 m, 9 pliuri,
         margine dintata) pe PETIOLI VIZIBILI, la PAS EGAL pe azimut (32,7 grade),
         in TREI INELE: 3 sus (petiol 70 grade, evantai la 70), 5 oblice
         (petiol 40, evantai la 40), 3 cazute (petiol 0, evantai la -65); ordinea
         inelelor alterneaza (sus, orizontal, jos, orizontal, ...)
      c) 3 frunze USCATE mari (DRY 13, R 0,8), atarnate lipite de trunchi sub
         coroana (plan vertical tangent la trunchi), nu o fusta orizontala
      d) FARA stanci/nisip la baza
    Cote tinta: 6 m. Noduri: Palm_Bark (WOOD 9 / LOG_DARK 28), Palm_Leaves
    (TROPICAL_GREEN 21 + CACTUS_GREEN 12 + DRY 13).
    """
    bark, leaves = Builder(), Builder()
    TH = 3.5
    ring_trunk(bark, [(0, 0, 0.0), (0, 0, 0.3), (0.05, 0.0, 1.0), (0.045, 0.01, 1.5)],
               [0.34, 0.29, 0.26, 0.25], BARK, BARK_D, ring_every=0.30, seg=8,
               ring_grow=1.12, ring_h=0.13)
    bark.taper_sweep([(0.045, 0.01, 1.48), (0.04, 0.02, 2.3), (0.0, 0.05, TH)],
                     [0.25, 0.24, 0.22], BARK, segments=8)

    def r_of_z(zz):
        return 0.25 - 0.03 * (zz - 1.5) / 2.0

    ring_trunk_cx = 0.03
    rhomb_scales(bark, r_of_z, [1.65, 1.92, 2.19, 2.46, 2.73, 3.0, 3.27], 8, BARK_D, BARK,
                 depth=0.12, cx=ring_trunk_cx, cy=0.04, w=1.15, h=0.42)
    top = Vector((0.0, 0.05, TH))
    pattern = [0, 1, 2, 1, 0, 1, 2, 1, 0, 1, 2]       # 3 sus, 5 orizontal, 3 cazute
    rings = {0: (70.0, 1.2, 70.0, 1.0), 1: (40.0, 1.6, 40.0, 1.05), 2: (0.0, 1.5, -65.0, 1.0)}
    step = 360.0 / len(pattern)
    for k, ringk in enumerate(pattern):
        pe, pl, be, R = rings[ringk]
        _fan_leaf(leaves, bark, top, 12.0 + step * k, pe, pl, be, R, LEAF if k % 2 else LEAF2)
    for k in range(3):
        az = 360.0 * k / 3 + 100.0
        a = math.radians(az)
        h = Vector((math.cos(a), math.sin(a), 0.0))
        start = top + h * 0.2 + Vector((0, 0, -0.15))
        hub = top + h * 0.40 + Vector((0, 0, -0.40))
        bark.taper_sweep([start, start + h * 0.1 + Vector((0, 0, -0.15)), hub],
                         [0.06, 0.05, 0.04], BARK_D, segments=4)
        pleated_fan(leaves, hub, Vector((0.0, 0.0, -1.0)) + h * 0.15, h, 0.80, DRY, pleats=6,
                    span_deg=200.0, depth=0.06, th=0.04)
    return [leaves.to_object("Palm_Leaves"), bark.to_object("Palm_Bark")]


# ---------------------------------------------------------------------------
# bougainvillea
# ---------------------------------------------------------------------------

def build_bougainvillea():
    """Bougainvillea, varianta cu spatele plat (se lipeste de zid). Runda 4.

    LISTA DE ELEMENTE (din decuparea `bougainvillea.png`; fara nisipul de la
    baza):
      a) tufa joasa si lata, 2,4 x 1,6 m, spatele TAIAT PLAT in y = 0 (zidul),
         adancime ~0,9 m: 5 elipsoizi de miez verzi suprapusi
      b) FRUNZIS VERDE VIZIBIL (~45% din suprafata): ~26 ciorchini de frunze
         (~0,45-0,65 m) pe anvelopa, TROPICAL_GREEN 21
      c) ~72 CIORCHINI MICI de flori (0,2-0,35 m) FLAMINGO_PINK 31, pe varfurile
         ramurilor (normala spre +Y/sus), plus 10 revarsate peste marginea de
         jos / laterala
      d) fara nisip, fara zid
    Noduri: Bougainvillea_Leaves (21), Bougainvillea_Bloom (31,
    --allow-slots=31). Origine: baza peretelui, centrata pe X.
    """
    leaves, bloom = Builder(), Builder()
    ells = [(-0.75, 0.38, 0.55, 0.62, 0.42, 0.50), (0.0, 0.40, 0.70, 0.72, 0.46, 0.65),
            (0.78, 0.38, 0.52, 0.62, 0.42, 0.48), (-0.25, 0.30, 0.30, 0.8, 0.40, 0.32),
            (0.35, 0.32, 1.0, 0.55, 0.36, 0.42)]
    for (cx, cy, cz, rx, ry, rz) in ells:
        leaves.boulder((cx, cy, cz), (2 * rx * 0.85, 2 * ry * 0.85, 2 * rz * 0.9),
                       LEAF, seed=600 + int(cx * 10), segments=8, rings=3,
                       deviation=0.12)
    la = ellipsoid_anchors(ells, 12, 51, el_lo=-0.4, bury=0.88, max_n=20)
    foliage_clumps(leaves, None, la, 0.55, LEAF, LEAF, 51, tip_frac=0.0,
                   push=0.05, flat=0.55)
    ba = [(p, n) for p, n in ellipsoid_anchors(ells, 46, 52, el_lo=-0.3, bury=0.88)
          if n.y > 0.05 or p.z < 0.45]
    ba = ba[:96]
    foliage_clumps(bloom, None, ba, 0.31, BLOOM, BLOOM, 52, tip_frac=0.0,
                   push=0.20, flat=0.7, seg=6, rings=2, size_var=0.3)
    # revarsate: ciorchini care atarna peste marginea de jos / laterala
    spill = [(Vector((x, 0.55, z)),
              Vector((0.2 * math.copysign(1, x), 0.8, -0.3)).normalized())
             for x, z in ((-1.12, 0.28), (-1.0, 0.12), (-0.55, 0.10), (0.1, 0.08),
                          (0.6, 0.12), (1.0, 0.14), (1.12, 0.3), (-0.9, 0.5),
                          (0.95, 0.5), (0.3, 0.1))]
    foliage_clumps(bloom, None, spill, 0.26, BLOOM, BLOOM, 53, tip_frac=0.0,
                   push=0.0, flat=0.7, seg=6, rings=2)
    objs = [leaves.to_object("Bougainvillea_Leaves"),
            bloom.to_object("Bougainvillea_Bloom")]
    for o in objs:
        for v in o.data.vertices:
            v.co.x *= 0.80
            if v.co.y < 0.0:
                v.co.y = 0.0
    return objs


# ---------------------------------------------------------------------------
# export
# ---------------------------------------------------------------------------

ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


AO_FUKUGI = dict(samples=22, dist=1.3, gradient="vertical", low=0.45, high=1.0,
                 power=0.8, floor=0.22)
AO_PINE = dict(samples=22, dist=2.0, gradient="vertical", low=0.55, high=1.0,
               power=0.8, floor=0.25)
AO_SMALL = dict(samples=22, dist=0.9, gradient="vertical", low=0.55, high=1.0,
                power=0.85, floor=0.25)


def _emit(objs, path, ao, zmax):
    for o in objs:
        _norm(o)
    ao = dict(ao, z_range=(0.0, zmax))
    emit_ok(objs, path, ao, keep_xy=True, bevel=0.0, smooth_angle=48.0)
    # numele de noduri trebuie sa ramana curate (fara .001) intre piese
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)


for v, zmax in (("a", 7.2), ("b", 8.7), ("c", 5.7)):
    if _want("fukugi_tree_" + v):
        _emit(build_fukugi(v), "plants/fukugi_tree_%s.glb" % v, AO_FUKUGI, zmax)
if _want("ryukyu_pine"):
    _emit(build_pine(), "plants/ryukyu_pine.glb", AO_PINE, 9.2)
if _want("cycad"):
    _emit(build_cycad(), "plants/cycad.glb", AO_SMALL, 2.4)
if _want("fan_palm"):
    _emit(build_fan_palm(), "plants/fan_palm.glb", AO_PINE, 6.2)
if _want("_fan_leaf_test"):
    _emit(build_fan_leaf_test(), "plants/_fan_leaf_test.glb", AO_PINE, 3.0)
if _want("bougainvillea"):
    _emit(build_bougainvillea(), "plants/bougainvillea.glb", AO_SMALL, 1.7)

report_ok()
