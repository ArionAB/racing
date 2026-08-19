"""Baikal — kitul satului Khuzhir (planşa, pozitia 11).

  UN FISIER PE PIESA (buildings/): log_house_a.glb, log_house_b.glb,
                                   log_house_c.glb, banya.glb
                        (props/):  fish_rack.glb, well_crane.glb,
                                   woodpile.glb, village_signpost.glb
  village_props.glb (props/)      PlankFence, FenceGate, Sled, BarrelsCrates
  vehicles          (vehicles/)   uaz_bukhanka.glb, kamaz_truck.glb
  husky_dog.glb     (props/)      caine animat (Idle / Walk), figurant PathMover

Identitatea satului siberian sta in TREI lucruri, si toate trei sunt aici:
randul de barne orizontale (nu pereti netezi), tocurile de fereastra sculptate
si vopsite (nalichniki, in doua culori) si zapada groasa pe acoperisuri de
tabla. Fara ele ies cabane generice de munte.

Fata "de prezentare" a fiecarei cladiri e spre +Y in Blender (= -Z in Godot).

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_village.py
"""

import math
from mathutils import Matrix, Vector

AO_BUILD = dict(samples=26, dist=5.0, gradient="vertical",
                low=0.45, high=1.00, power=0.9, floor=0.12)
AO_PROP = dict(samples=22, dist=3.0, gradient="vertical",
               low=0.48, high=1.00, power=0.9, floor=0.15)
AO_VEHICLE = dict(samples=24, dist=4.0, gradient="vertical",
                  low=0.48, high=1.00, power=0.9, floor=0.15)

GLASS = ASPHALT
TRIM_BLUE = PAINTED        # toc de fereastra albastru — cel mai frecvent
TRIM_WHITE = FOAM_WHITE    # a doua culoare de toc


def _drop_to_zero(objs):
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box)
             for o in objs)
    for o in objs:
        o.location.z -= lo


def log_wall(b, center, size, seed, slot=LOG_DARK, log_h=0.40, corners=True):
    """Zid de barne orizontale, cu capete incrucisate la colturi.

    Randul de barne E identitatea arhitecturii de aici. Se face din cutii
    suprapuse, nu din cilindri: la 40 cm si distanta de joc sectiunea rotunda
    nu se citeste, dar ar tripla triunghiurile. Ce se vede e umbra dintre
    randuri, si aia o da bevel-ul.
    """
    cx, cy, cz = center
    sx, sy, sz = size
    rows = max(int(sz / log_h), 1)
    h = sz / rows
    rand = _lcg(seed)
    for i in range(rows):
        z = cz + h * (i + 0.5)
        d = 0.03 + rand() * 0.05
        b.box((cx, cy, z), (sx + d, sy + d, h * 0.92), slot)
    if corners:
        # capetele iesite ("in coada de randunica") — doar la fiecare a doua
        # barna, altfel coltul devine un bloc plin
        for i in range(0, rows, 2):
            z = cz + h * (i + 0.5)
            b.box((cx, cy, z), (sx + 0.50, sy * 0.14, h * 0.88), slot)
            b.box((cx, cy, z), (sx * 0.14, sy + 0.50, h * 0.88), slot)


def gable_roof(b, half_w, eave_z, ridge_z, depth, y_center, slot=VOLCANIC_BLACK,
               overhang=0.55, thickness=0.16, snow=True, snow_slot=FOAM_WHITE):
    """Acoperis in doua ape cu streasina + strat de zapada."""
    rise = ridge_z - eave_z
    ang = math.atan2(rise, half_w)
    slope = math.hypot(half_w + overhang, rise * (1.0 + overhang / half_w))
    length = slope + 0.35
    for sgn in (-1.0, 1.0):
        rot = Matrix.Rotation(sgn * ang, 3, "Y")
        t = length * 0.5 - 0.18
        mx = sgn * t * math.cos(ang)
        mz = ridge_z - t * math.sin(ang) + thickness * 0.35
        b.box((mx, y_center, mz), (length, depth + 2 * overhang, thickness),
              slot, rotation=rot)
        if snow:
            # Retrasa de la streasina: zapada care ajunge fix in marginea
            # acoperisului citeste ca o a doua placa vopsita alb.
            b.box((mx, y_center, mz + thickness * 0.78),
                  (length * 0.94, depth + 2 * overhang * 0.80,
                   thickness * 0.55), snow_slot, rotation=rot)
    # coama
    b.box((0.0, y_center, ridge_z + thickness * 0.5),
          (0.30, depth + 2 * overhang * 0.9, 0.18), slot)


def window(b, center, w=0.75, h=0.95, trim=TRIM_BLUE, depth=0.10):
    """Fereastra cu toc sculptat (nalichnik).

    Tocul NU e un chenar simplu: are o coronita deasupra si un prag dedesubt,
    care ies in afara. Aia se citeste de la distanta si aia face casa
    ruseasca — un dreptunghi de sticla intr-un perete nu spune nimic.
    """
    cx, cy, cz = center
    # golul
    b.box((cx, cy, cz), (w, depth, h), GLASS)
    # ramele laterale
    for sx in (-1, 1):
        b.box((cx + sx * (w * 0.5 + 0.07), cy + 0.02, cz),
              (0.14, depth + 0.06, h + 0.10), trim)
    # pragul de jos
    b.box((cx, cy + 0.02, cz - h * 0.5 - 0.09), (w + 0.42, depth + 0.08, 0.12),
          trim)
    # coronita de sus, in doua trepte
    b.box((cx, cy + 0.02, cz + h * 0.5 + 0.09), (w + 0.34, depth + 0.08, 0.12),
          trim)
    b.box((cx, cy + 0.03, cz + h * 0.5 + 0.22), (w * 0.62, depth + 0.10, 0.14),
          trim)
    # obloane
    for sx in (-1, 1):
        b.box((cx + sx * (w * 0.5 + 0.20), cy + 0.04, cz),
              (0.16, depth + 0.04, h * 0.94), trim)


def _log_house(name, w, d, wall_h, ridge_h, seed, trim, windows_front=2,
               chimney=True):
    """O casa de barne. A/B/C difera prin cote, culoarea tocurilor si detalii."""
    b = Builder()
    log_wall(b, (0.0, 0.0, 0.0), (w, d, wall_h), seed=seed)
    # frontonul: pentagon plin, ca sa nu se vada prin acoperis
    b.prism([(-w * 0.5, wall_h), (0.0, ridge_h), (w * 0.5, wall_h)], d,
            LOG_DARK, center=(0.0, 0.0, 0.0))
    gable_roof(b, w * 0.5, wall_h, ridge_h, d, 0.0)
    # soclu de piatra: casele stau pe pietre, nu direct pe pamant
    b.box((0.0, 0.0, 0.16), (w + 0.3, d + 0.3, 0.32), MARBLE_GREY)
    # Ferestrele si USA impart aceeasi fata (+Y), deci trebuie sa nu se
    # calce. Usa sta la marginea din dreapta; ferestrele se distribuie pe
    # RESTUL fatadei, nu pe toata latimea. Prima versiune le imprastia pe
    # toata fatada si a treia fereastra cadea fix peste usa — se vedea in
    # randarea de control ca un toc de fereastra fara geam, cu peretele in
    # spate (usa acoperea sticla, fiind cu 1 cm mai in fata).
    door_x = w * 0.30
    door_half = 0.43
    usable_lo, usable_hi = -w * 0.5 + 0.75, door_x - door_half - 0.55
    for i in range(windows_front):
        t = (i + 0.5) / windows_front
        x = usable_lo + (usable_hi - usable_lo) * t
        window(b, (x, d * 0.5 + 0.04, wall_h * 0.62), trim=trim)
    # o fereastra pe fiecare lateral
    for sx in (-1, 1):
        b.box((sx * (w * 0.5 + 0.04), -d * 0.18, wall_h * 0.62),
              (0.10, 0.70, 0.90), GLASS)
        b.box((sx * (w * 0.5 + 0.07), -d * 0.18, wall_h * 0.62),
              (0.06, 0.92, 1.12), trim)
    # usa, pe fata
    b.box((door_x, d * 0.5 + 0.04, wall_h * 0.42),
          (door_half * 2.0, 0.10, wall_h * 0.84), WOOD)
    if chimney:
        # hornul: caramida, cu capac. Fumul il pune pista (particule).
        cx = -w * 0.22
        b.box((cx, -d * 0.15, ridge_h + 0.35), (0.55, 0.55, 1.5), ASPHALT_EDGE)
        b.box((cx, -d * 0.15, ridge_h + 1.16), (0.75, 0.75, 0.16), VOLCANIC_BLACK)
    obj = b.to_object(name)
    finish(obj, bevel=0.03, ao=AO_BUILD, origin="base")
    return obj


def build_houses():
    """Casele A/B/C + banya + racul de peste, intr-un GLB de cladiri."""
    clear_built()
    objs = []

    # cotele din brief: 8x6x5, 10x7x6, 6x5x4
    objs.append(_log_house("LogHouse_A", 8.0, 6.0, 3.5, 5.0, seed=311,
                           trim=TRIM_BLUE, windows_front=2))
    objs.append(_log_house("LogHouse_B", 10.0, 7.0, 4.0, 6.0, seed=577,
                           trim=TRIM_WHITE, windows_front=3))
    objs.append(_log_house("LogHouse_C", 6.0, 5.0, 3.0, 4.0, seed=823,
                           trim=TRIM_BLUE, windows_front=1))

    # --- banya (baia de aburi), 4x3x3 --------------------------------------
    b = Builder()
    log_wall(b, (0.0, 0.0, 0.0), (4.0, 3.0, 2.3), seed=99)
    b.prism([(-2.0, 2.3), (0.0, 3.1), (2.0, 2.3)], 3.0, LOG_DARK)
    gable_roof(b, 2.0, 2.3, 3.1, 3.0, 0.0, overhang=0.4)
    b.box((0.0, 1.54, 1.0), (0.75, 0.12, 1.9), WOOD)        # usa mica
    b.box((-1.2, 1.54, 1.65), (0.45, 0.10, 0.42), GLASS)     # ferestruica
    b.box((1.0, -0.6, 3.5), (0.40, 0.40, 1.1), ASPHALT_EDGE)  # horn
    banya = b.to_object("Banya")
    finish(banya, bevel=0.03, ao=AO_BUILD, origin="base")
    objs.append(banya)

    # --- uscatorul de omul, 3x1.5x2 ----------------------------------------
    # Rama de lemn cu siruri de peste argintiu atarnat. Pestele e detaliul care
    # spune "sat de pescari" mai tare decat orice altceva din kit.
    b = Builder()
    for sx in (-1, 1):
        b.beam((sx * 1.4, -0.6, 0.0), (sx * 1.4, -0.6, 2.0), 0.12, WOOD)
        b.beam((sx * 1.4, 0.6, 0.0), (sx * 1.4, 0.6, 2.0), 0.12, WOOD)
        b.beam((sx * 1.4, -0.6, 2.0), (sx * 1.4, 0.6, 2.0), 0.10, WOOD)
    for k, z in enumerate((1.95, 1.45)):
        b.beam((-1.45, 0.0, z), (1.45, 0.0, z), 0.07, WOOD)
        # pestii: placute subtiri, alternand usor pe orizontala
        rand = _lcg(400 + k * 17)
        for i in range(9):
            x = -1.25 + i * 0.31
            b.box((x, (rand() - 0.5) * 0.10, z - 0.30),
                  (0.09, 0.16, 0.46), FOAM_WHITE,
                  rotation=Matrix.Rotation(math.radians((rand() - 0.5) * 18.0),
                                           3, "Y"))
    rack = b.to_object("FishRack")
    finish(rack, bevel=0.02, ao=AO_PROP, origin="base")
    objs.append(rack)

    # --- fantana cu cumpana, 4 m -------------------------------------------
    b = Builder()
    log_wall(b, (0.0, 0.0, 0.0), (1.3, 1.3, 0.85), seed=55, corners=True)
    b.beam((-0.75, 0.0, 0.0), (-0.75, 0.0, 3.0), 0.20, WOOD)     # stalpul
    # cumpana: bara lunga inclinata, cu contragreutate
    b.beam((-0.75, 0.0, 2.9), (1.9, 0.0, 1.5), 0.14, WOOD)
    b.beam((-0.75, 0.0, 2.9), (-1.7, 0.0, 3.4), 0.14, WOOD)
    b.box((-1.85, 0.0, 3.45), (0.45, 0.45, 0.45), MARBLE_GREY)   # greutatea
    # galeata pe funie
    b.beam((1.85, 0.0, 1.5), (1.85, 0.0, 0.75), 0.03, WOOD)
    b.frustum((1.85, 0.0, 0.58), 0.20, 0.16, 0.34, RUST, segments=8)
    well = b.to_object("Well")
    finish(well, bevel=0.02, ao=AO_PROP, origin="base")
    objs.append(well)

    # --- stiva de lemne, 3x1x1.5 -------------------------------------------
    b = Builder()
    rand = _lcg(720)
    rows, cols = 5, 11
    for r in range(rows):
        for c in range(cols):
            if rand() > 0.94:
                continue        # goluri: o stiva perfecta arata ca un zid
            x = -1.4 + c * 0.28
            z = 0.14 + r * 0.27
            # busteni pe capat: cercuri de sectiune spre +Y
            b.cylinder((x + (rand() - 0.5) * 0.04, 0.0, z), 0.13, 0.95,
                       WOOD if rand() > 0.35 else LOG_DARK, segments=7,
                       axis="Y")
    # capac de zapada
    b.box((0.0, 0.0, 0.14 + rows * 0.27 + 0.04), (3.05, 1.05, 0.14), FOAM_WHITE)
    pile = b.to_object("Woodpile")
    finish(pile, bevel=0.015, ao=AO_PROP, origin="base")
    objs.append(pile)

    # --- stalpul cu sageti, 3 m --------------------------------------------
    b = Builder()
    b.frustum((0.0, 0.0, 1.5), 0.11, 0.09, 3.0, WOOD, segments=8)
    rand = _lcg(1234)
    for i, (z, ang, length) in enumerate(((2.62, 18.0, 1.10),
                                          (2.30, 155.0, 0.92),
                                          (1.98, 268.0, 1.02),
                                          (1.66, 72.0, 0.85))):
        a = math.radians(ang)
        # sageata: placa orizontala care pleaca radial, cu varf tesit
        mid = ((length * 0.5 + 0.12) * math.cos(a),
               (length * 0.5 + 0.12) * math.sin(a), z)
        b.box(mid, (length, 0.06, 0.20), WOOD,
              rotation=Matrix.Rotation(a, 3, "Z"))
    b.cylinder((0.0, 0.0, 3.06), 0.14, 0.12, FOAM_WHITE, segments=8)
    sign = b.to_object("Signpost")
    finish(sign, bevel=0.02, ao=AO_PROP, origin="base_axis")
    objs.append(sign)

    # UN FISIER PE PIESA, spre deosebire de celelalte kituri (ice/forest/shore),
    # care raman GLB-uri multi-nod.
    #
    # Cererea a fost explicita, dar are si o justificare care tine: cladirile de
    # sat sunt piese HERO, asezate una cate una pe ulita din Khuzhir, nu
    # imprastiate statistic ca pietrele sau copacii. O piesa asezata manual se
    # refera direct (`buildings/log_house_a.glb`), fara sa mai treaca prin
    # `Track._extract_glb_node()` si fara offsetul de pe rand.
    #
    # Costul: 8 incarcari de resursa in loc de una, si 8 perechi .glb/.import.
    # Materialul ramane UNUL SINGUR (atlasul), deci numarul de draw call-uri NU
    # creste — batch-ul se face oricum pe material, nu pe fisier.
    #
    # Piesele se exporta DIN ORIGINE, nu de pe rand: fiecare fisier isi are
    # originea la baza lui. De aia asezarea pe rand (pentru .blend si pentru
    # planşa de referinta) se face DUPA export.
    _drop_to_zero(objs)
    files = {
        "LogHouse_A": "buildings/log_house_a.glb",
        "LogHouse_B": "buildings/log_house_b.glb",
        "LogHouse_C": "buildings/log_house_c.glb",
        "Banya": "buildings/banya.glb",
        "FishRack": "props/fish_rack.glb",
        "Well": "props/well_crane.glb",
        "Woodpile": "props/woodpile.glb",
        "Signpost": "props/village_signpost.glb",
    }
    for o in objs:
        export_glb([o], files[o.name])
    print("VillageKit: %d tris in %d fisiere (%s)"
          % (sum(tri_count(o) for o in objs), len(objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))

    # .blend-ul ramane comun (o singura sursa pentru tot satul), cu piesele
    # asezate pe rand ca sa fie lizibil la deschidere.
    x = 0.0
    for o in objs:
        o.location.x = x
        x += 13.0
    save_blend(objs, "baikal_village_kit.blend")
    return objs


# ============================================================ Props de sat
def build_village_props():
    clear_built()
    objs = []

    # --- gard de scanduri, modul de 3 m ------------------------------------
    b = Builder()
    for sx in (-1, 1):
        b.beam((sx * 1.5, 0.0, 0.0), (sx * 1.5, 0.0, 1.6), 0.14, WOOD)
    rand = _lcg(66)
    for pt in _span_points((-1.42, 0.0, 0.0), (1.42, 0.0, 0.0), 0.19,
                           endpoints=False):
        h = 1.42 + rand() * 0.13
        b.box((pt.x, 0.0, h * 0.5), (0.16, 0.05, h), WOOD)
        # capac de zapada pe fiecare scandura
        b.box((pt.x, 0.0, h + 0.03), (0.17, 0.07, 0.05), FOAM_WHITE)
    for z in (0.45, 1.15):
        b.beam((-1.5, 0.06, z), (1.5, 0.06, z), 0.07, WOOD)
    fence = b.to_object("PlankFence")
    finish(fence, bevel=0.015, ao=AO_PROP, origin="base")
    objs.append(fence)

    # --- poarta de gard -----------------------------------------------------
    b = Builder()
    for sx in (-1, 1):
        b.frustum((sx * 1.6, 0.0, 1.1), 0.16, 0.13, 2.2, WOOD, segments=8)
        b.cylinder((sx * 1.6, 0.0, 2.26), 0.19, 0.10, FOAM_WHITE, segments=8)
    # canaturile, cu diagonala de rigidizare
    for sx in (-1, 1):
        for pt in _span_points((sx * 0.15, 0.0, 0.0), (sx * 1.42, 0.0, 0.0),
                               0.21, endpoints=False):
            b.box((pt.x, 0.0, 0.82), (0.17, 0.05, 1.55), WOOD)
        for z in (0.35, 1.42):
            b.beam((sx * 0.12, 0.05, z), (sx * 1.45, 0.05, z), 0.07, WOOD)
        b.beam((sx * 0.14, 0.05, 0.30), (sx * 1.43, 0.05, 1.46), 0.06, WOOD)
    # acoperisul mic de deasupra portii — detaliu rusesc
    gable_roof(b, 1.95, 2.3, 2.75, 0.55, 0.0, overhang=0.25, thickness=0.10)
    gate = b.to_object("FenceGate")
    finish(gate, bevel=0.015, ao=AO_PROP, origin="base")
    objs.append(gate)

    # --- sania de lemn, 1.8 m ----------------------------------------------
    b = Builder()
    for sy in (-1, 1):
        y = sy * 0.28
        # talpa curbata in fata: trei segmente inlantuite cu beam
        pts = [(-0.9, y, 0.06), (0.45, y, 0.06), (0.78, y, 0.14),
               (0.92, y, 0.34)]
        for i in range(len(pts) - 1):
            b.beam(pts[i], pts[i + 1], (0.09, 0.07), WOOD)
        # montanti
        for x in (-0.7, -0.1, 0.5):
            b.beam((x, y, 0.09), (x, y, 0.42), 0.07, WOOD)
    # platforma: sipci transversale
    for pt in _span_points((-0.82, 0.0, 0.46), (0.62, 0.0, 0.46), 0.16):
        b.box((pt.x, 0.0, 0.46), (0.11, 0.62, 0.05), WOOD)
    b.beam((-0.9, -0.28, 0.46), (-0.9, 0.28, 0.46), 0.06, WOOD)
    sled = b.to_object("Sled")
    finish(sled, bevel=0.015, ao=AO_PROP, origin="base")
    objs.append(sled)

    # --- butoaie + lazi -----------------------------------------------------
    b = Builder()
    rand = _lcg(4242)
    # trei butoaie albastre
    for i, (x, y, rot) in enumerate(((-1.1, 0.0, 0.0), (-0.35, 0.35, 0.0),
                                     (-0.7, -0.5, 90.0))):
        if rot == 0.0:
            b.frustum((x, y, 0.42), 0.30, 0.27, 0.84, PAINTED, segments=9)
            for z in (0.20, 0.64):
                b.torus((x, y, z), 0.31, 0.035, RUST, major_seg=9, minor_seg=4)
        else:   # unul culcat
            b.cylinder((x, y, 0.30), 0.30, 0.84, PAINTED, segments=9, axis="X")
    # lazi de peste, stivuite
    for x, y, z, s in ((0.55, -0.2, 0.22, 0.44), (0.55, -0.2, 0.66, 0.42),
                       (1.15, 0.25, 0.24, 0.48), (0.95, -0.45, 0.20, 0.40)):
        b.box((x, y, z), (s * 1.5, s, s), WOOD)
        # sipcile lazii, sugerate prin doua benzi mai inchise
        b.box((x, y, z + s * 0.28), (s * 1.53, s * 1.02, s * 0.10), LOG_DARK)
    # doua canistre
    for x, y in ((1.65, -0.15), (1.62, 0.35)):
        b.box((x, y, 0.24), (0.20, 0.34, 0.48), TROPICAL_GREEN)
        b.cylinder((x, y, 0.51), 0.05, 0.08, RUST, segments=6)
    crates = b.to_object("BarrelsCrates")
    finish(crates, bevel=0.02, ao=AO_PROP, origin="base")
    objs.append(crates)

    x = 0.0
    for o in objs:
        o.location.x = x
        x += 5.0
    _drop_to_zero(objs)
    print("VillageKit(props): %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "props/village_props.glb")
    save_blend(objs, "baikal_village_props.blend")
    return objs


# ============================================================ Vehicule parcate
# Statice, decor. Botul spre +Y (ca sa se poata aseza "parcate cu fata la drum"
# fara rotatii ciudate in pista).

def build_uaz():
    """UAZ-452 „bukhanka" (painea): 4.5 x 2 x 2.2 m, verde-oliv.

    Silueta e o CUTIE CU BOT TESIT si roti la colturi — asta o face
    recognoscibila. Farurile rotunde jos, in bara, sunt al doilea semn.
    """
    clear_built()
    b = Builder()
    L, W, H = 4.5, 2.0, 2.2
    floor = 0.42
    # caroseria
    b.box((0.0, 0.0, floor + (H - floor) * 0.5), (W, L * 0.93, H - floor),
          TROPICAL_GREEN)
    # botul tesit (fata = +Y)
    b.box((0.0, L * 0.44, floor + 0.55), (W * 0.98, 0.55, 1.0), TROPICAL_GREEN,
          rotation=Matrix.Rotation(math.radians(14.0), 3, "X"))
    # parbriz + geamuri laterale
    b.box((0.0, L * 0.34, floor + 1.30), (W * 0.86, 0.10, 0.62), GLASS,
          rotation=Matrix.Rotation(math.radians(10.0), 3, "X"))
    for sx in (-1, 1):
        for i in range(3):
            b.box((sx * (W * 0.5 - 0.03), L * 0.14 - i * 0.72, floor + 1.28),
                  (0.08, 0.56, 0.50), GLASS)
    # acoperis usor bombat + zapada
    b.box((0.0, -0.1, H - 0.04), (W * 0.94, L * 0.88, 0.10), TROPICAL_GREEN)
    b.box((0.0, -0.1, H + 0.05), (W * 0.86, L * 0.80, 0.08), FOAM_WHITE)
    # bara + faruri rotunde
    b.box((0.0, L * 0.47, floor + 0.12), (W * 0.96, 0.16, 0.22), ASPHALT_EDGE)
    for sx in (-1, 1):
        b.cylinder((sx * 0.62, L * 0.46, floor + 0.52), 0.17, 0.12, FOAM_WHITE,
                   segments=8, axis="Y")
    # roti
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.cylinder((sx * (W * 0.5 - 0.06), sy * L * 0.32, 0.42), 0.42, 0.26,
                       VOLCANIC_BLACK, segments=9, axis="X")
    obj = b.to_object("UAZ_Bukhanka")
    finish(obj, bevel=0.03, ao=AO_VEHICLE, origin="base")
    print("UAZ: %d tris" % tri_count(obj))
    export_glb([obj], "vehicles/uaz_bukhanka.glb")
    save_blend([obj], "baikal_uaz.blend")
    return [obj]


def build_kamaz():
    """Kamaz cu prelata: 8 x 2.5 x 3 m, portocaliu ruginit. Parcat pe gheata."""
    clear_built()
    b = Builder()
    L, W = 8.0, 2.5
    wheel_r = 0.55
    chassis = wheel_r + 0.35
    # sasiul
    b.box((0.0, 0.0, chassis - 0.12), (W * 0.8, L, 0.24), VOLCANIC_BLACK)
    # cabina (fata = +Y)
    b.box((0.0, L * 0.34, chassis + 1.05), (W, 2.0, 2.10), KERB_RED)
    b.box((0.0, L * 0.34 + 1.02, chassis + 0.55), (W * 0.98, 0.14, 1.05),
          KERB_RED)                                        # masca
    b.box((0.0, L * 0.30 + 0.98, chassis + 1.55), (W * 0.88, 0.10, 0.78), GLASS,
          rotation=Matrix.Rotation(math.radians(8.0), 3, "X"))  # parbriz
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.03), L * 0.34, chassis + 1.50),
              (0.08, 0.85, 0.62), GLASS)
        b.cylinder((sx * 0.85, L * 0.34 + 1.06, chassis + 0.30), 0.16, 0.12,
                   FOAM_WHITE, segments=8, axis="Y")        # faruri
    b.box((0.0, L * 0.34, chassis + 2.18), (W * 0.94, 1.9, 0.12), FOAM_WHITE)
    # prelata: arcuri peste bena
    bed_y = -L * 0.16
    b.box((0.0, bed_y, chassis + 0.30), (W, L * 0.56, 0.55), WOOD)
    n = 7
    for i in range(n):
        y = bed_y + L * 0.56 * (i / (n - 1.0) - 0.5)
        # arc semicircular din blocuri rotite pe tangenta
        for k in range(7):
            a = math.pi * (k + 0.5) / 7
            cx = -math.cos(a) * W * 0.5
            cz = chassis + 0.58 + math.sin(a) * 0.85
            b.box((cx, y, cz), (0.12, 0.16, (math.pi * W * 0.5 / 7) * 1.15),
                  DRY_VEGETATION, rotation=Matrix.Rotation(a, 3, "Y"))
    # panza dintre arcuri
    for k in range(7):
        a = math.pi * (k + 0.5) / 7
        cx = -math.cos(a) * (W * 0.5 - 0.04)
        cz = chassis + 0.58 + math.sin(a) * 0.81
        b.box((cx, bed_y, cz), (0.07, L * 0.55, (math.pi * W * 0.5 / 7) * 1.1),
              DRY_VEGETATION, rotation=Matrix.Rotation(a, 3, "Y"))
    # roti: 2 in fata, 4 spate (jumelate)
    for sx in (-1, 1):
        b.cylinder((sx * (W * 0.5 - 0.10), L * 0.30, wheel_r), wheel_r, 0.32,
                   VOLCANIC_BLACK, segments=9, axis="X")
        for dy in (-0.62, 0.10):
            b.cylinder((sx * (W * 0.5 - 0.10), bed_y + dy - 0.6, wheel_r),
                       wheel_r, 0.30, VOLCANIC_BLACK, segments=9, axis="X")
    obj = b.to_object("Kamaz_Truck")
    finish(obj, bevel=0.03, ao=AO_VEHICLE, origin="base")
    print("Kamaz: %d tris" % tri_count(obj))
    export_glb([obj], "vehicles/kamaz_truck.glb")
    save_blend([obj], "baikal_kamaz.blend")
    return [obj]


if __name__ == "__main__":
    build_houses()
    build_village_props()
    build_uaz()
    build_kamaz()
