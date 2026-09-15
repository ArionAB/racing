"""Machu Picchu — VEHICULE (plansa de inventar, randul 7).

  machupicchu/vehicles/consettur_bus.glb   autobuzul de turisti (BusHazard)
  machupicchu/vehicles/perurail_train.glb  garnitura PeruRail (TrainHazard)

Amandoua au CONSUMATOR in cod, si contractele lor sunt citite din cod, nu din
brief — brief-ul §1.5 greseste axa trenului (vezi mai jos).

AUTOBUZUL (`scenes/hazards/bus_hazard.gd:176-184` + `scenes/props/path_mover.gd`):
  - cutia de coliziune se masoara pe **AABB-ul modelului** (`body_size` din
    scena e doar placeholder-ul folosit cand modelul lipseste), deci cotele
    GLB-ului SUNT contractul: 3.6 lat x 3.0 inalt x 6.0 lung
  - **inainte = -Z local** (`bus_hazard.gd:200`: `front_z` e la Z MINIM, iar
    botul oblic se croieste in fata lui). -Z Godot = +Y Blender.
  - origine la sol, centrata pe XZ Godot (= XY Blender)

  REUSE INCERCAT SI RESPINS, cu masuratoare: `assets/models/vehicles/bus.fbx`
  masoara **13.70 m lungime x 3.81 lat x 3.84 inalt** (importat si masurat in
  Blender). E un autobuz urban lung, nu unul scurt de munte. Adus la 6.0 m
  lungime uniform, latimea ar cadea la 1.67 m (jumatate din contractul de 3.6);
  scalat neuniform (0.44 pe lungime, 0.94 pe latime), rotile de 1.26 m devin
  ovale turtite si se vede imediat. Brief-ul prevede exact cazul asta ("daca
  proportiile nu tin — prea lung — Builder de la zero"), deci: Builder.
  `bus.fbx` ramane NEATINS.

TRENUL (`scenes/hazards/train_hazard.gd:39-41, 366-409`):
  - trei noduri cautate dupa nume EXACT, doar printre copiii DIRECTI ai
    radacinii: `Train_Loco`, `Train_Tender`, `Train_Wagon`. Daca lipseste
    ORICARE, `_build_model_consist` arunca toata garnitura si cade pe cutii
    (`:381-386`) — PeruRail n-are tender, deci `Train_Tender` e un vagon scurt
    de bagaje, ca nodul sa existe.
  - **BOTUL SPRE +X.** Brief-ul §1.5 scrie "-Z Godot" si GRESESTE: hazardul
    construieste garnitura dinspre coada spre bot pe axa X si o deplaseaza spre
    +X local (`train_hazard.gd:335-339`), iar `build_train.py:19` spune explicit
    "intoarce piesele cu botul pe +X... Fara rotatia asta trenul ar traversa cu
    spatele". Lungimea fiecarei piese e pe X.
  - **ecartament `|z| = 0.45`** (`GAUGE_HALF`), **baza rotilor la y = 0**
    (hazardul aseaza piesa la `RAIL_TOP` = 0.28, deci geometria trebuie sa
    inceapa de la zero). NU se copiaza `RAIL_GAUGE = 1.52` din
    `build_baikal_railway.py` — ala e sina de DECOR, nu garnitura.
  - masurat pe `assets/models/vehicles/train.glb` (garnitura existenta), ca
    referinta de asezare: Loco 8.09 x 3.58 x 2.87, Tender 5.21 x 2.35 x 2.02,
    Wagon 8.06 x 2.95 x 2.07 — toate cu baza exact la y=0 si simetrice pe z.

NODURI MULTIPLE — capcana valului 2: `finish` se cheama PER NOD si
`set_origin_base` re-centreaza FIECARE nod pe bbox-ul LUI, deci nodurile se
desprind unul de altul. Aici cele trei piese ale trenului trebuie sa ramana pe
aceeasi talpa (baza rotilor la zero) si pe aceeasi axa (ecartamentul centrat pe
z=0), deci se foloseste `origin="base_axis"` (coboara doar pe Z, pastreaza XY)
si fiecare piesa se construieste DEJA centrata pe axa ei. Se verifica cu
`--origin=assembly`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_vehicles.py
"""

import bmesh
import math
from mathutils import Matrix

# --- autobuzul ---------------------------------------------------------------
#
# Cote de CONTRACT (AABB-ul e cutia de coliziune): 3.6 lat x 3.0 inalt x 6.0 lung.
# In Blender: X = latime, Y = lungime (+Y = inainte = -Z Godot), Z = inaltime.
BUS_W = 3.6
BUS_L = 6.0
BUS_H = 3.0

BUS_WHEEL_R = 0.52          # raza rotii
BUS_WHEEL_T = 0.30          # latimea rotii
BUS_GROUND = 0.30           # cat de sus incepe caroseria (garda la sol)
# Banda alba: autobuzele Consettur sunt galbene cu o banda alba la nivelul
# geamurilor. Banda e RETAG pe fetele laterale, nu geometrie: zero triunghiuri.
BUS_BAND_LO = 1.70
BUS_BAND_HI = 2.12


def build_bus():
    """Autobuz scurt de munte: caroserie cu bot scurt, geamuri mari, 4 roti.

    Caroseria e o cutie cu coltul de sus retras (parbrizul inclinat) — un
    paralelipiped drept ar citi a camion. Botul e SCURT (motorul sub podea, ca
    la autobuzele de munte), deci cabina incepe aproape din fata.
    """
    b = Builder()
    half_w = BUS_W * 0.5
    half_l = BUS_L * 0.5
    body_lo = BUS_GROUND
    body_hi = BUS_H

    # --- caroseria: PRISMA cu profilul real in plan YZ ---
    #
    # PRIMA VERSIUNE ERA O CUTIE SI SE VEDEA PE PLANSA SOLO: autobuzul citea ca
    # o lada dreptunghiulara pe patru roti, simetrica fata-spate. Din profil nu
    # se putea spune INCOTRO merge — si tocmai sensul conteaza la un obstacol pe
    # care il intalnesti pe contrasens (`BusHazard` il trimite pe -Z local).
    # Cifrele erau OK (948/1200), forma lipsea: fix capcana "buget neatins =
    # forma lipsa".
    #
    # Acum caroseria e un contur in YZ: parbriz INCLINAT in fata (+Y), spate
    # aproape vertical cu o mica retragere, streasina iesita peste parbriz.
    # `prism` extrudeaza un contur XZ pe Y, deci conturul se scrie in (y, z) si
    # se roteste 90° pe Z ca extrudarea sa cada pe X (latimea).
    #
    # Profilul, de la botul de jos in sens trigonometric:
    #   (+half_l, jos) bot -> urca aproape vertical pana sub parbriz
    #   parbrizul se lasa pe spate cu ~18° pana la streasina
    #   acoperisul, plan, pana in spate
    #   spatele coboara vertical
    windshield_lo = BUS_BAND_HI          # de unde incepe parbrizul inclinat
    rake = 0.52                          # cat se retrage varful parbrizului
    outline = [
        (half_l, body_lo),                       # botul, jos
        (half_l, windshield_lo),                 # pana sub parbriz
        (half_l - rake, body_hi),                # parbrizul inclinat
        (-half_l + 0.10, body_hi),               # acoperisul
        (-half_l, body_hi - 0.22),               # coltul din spate, tesit
        (-half_l, body_lo),                      # spatele, jos
    ]
    body = b.prism(outline, BUS_W, CAR_YELLOW,
                   center=(0.0, 0.0, 0.0))
    # `prism` construieste conturul in XZ si extrudeaza pe Y; noi l-am scris in
    # (y, z), deci il rotim ca lungimea sa cada pe Y si latimea pe X.
    bmesh.ops.rotate(b.bm, verts=list({v for f in body for v in f.verts}),
                     cent=(0.0, 0.0, 0.0),
                     matrix=Matrix.Rotation(math.radians(90.0), 3, "Z"))

    # Banda alba la nivelul geamurilor, pe fetele LATERALE si pe spate/fata.
    # retag pe cota: costa zero triunghiuri (dar cutia n-are taietura la cotele
    # benzii, deci banda ar prinde toata fata). De-aia banda e o cutie subtire
    # lipita peste caroserie, nu un retag: 12 triunghiuri pentru semnatura
    # vizuala a autobuzului.
    b.box((0.0, 0.0, (BUS_BAND_LO + BUS_BAND_HI) * 0.5),
          (BUS_W + 0.04, BUS_L + 0.04, BUS_BAND_HI - BUS_BAND_LO), FOAM_WHITE)

    # --- geamurile: placi ASPHALT lipite pe fetele laterale si pe fata/spate ---
    # "Geamuri mari" (brief): banda de sticla ocupa de la BUS_BAND_HI in sus,
    # pana sub streasina.
    win_lo = BUS_BAND_HI + 0.04
    win_hi = body_hi - 0.22
    for sx in (-1.0, 1.0):
        b.box((sx * (half_w + 0.01), 0.0, (win_lo + win_hi) * 0.5),
              (0.04, BUS_L - 0.70, win_hi - win_lo), ASPHALT)
    # parbrizul (fata, +Y) si luneta (spate, -Y)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (half_l + 0.01), (win_lo + win_hi) * 0.5),
              (BUS_W - 0.50, 0.04, win_hi - win_lo), ASPHALT)

    # --- acoperisul: o lespede putin mai lata, ca streasina sa arunce umbra ---
    b.box((0.0, 0.0, body_hi + 0.06), (BUS_W + 0.06, BUS_L + 0.06, 0.12),
          CAR_YELLOW)

    # --- rotile: 4 cilindri pe axa X, VOLCANIC_BLACK ---
    # `segments=10`: sub 8 roata citeste poligonala de langa drum, peste 12 e
    # cheltuiala degeaba pe o piesa care trece la 40 km/h.
    axle_y = (half_l - 1.15, -half_l + 1.05)
    for sy in axle_y:
        for sx in (-1.0, 1.0):
            b.cylinder((sx * (half_w - BUS_WHEEL_T * 0.5 + 0.02), sy,
                        BUS_WHEEL_R),
                       BUS_WHEEL_R, BUS_WHEEL_T, VOLCANIC_BLACK,
                       segments=10, axis="X")

    # --- farurile: doua placi mici SAND_LIGHT pe bot ---
    for sx in (-1.0, 1.0):
        b.box((sx * (half_w - 0.55), half_l + 0.01, body_lo + 0.55),
              (0.42, 0.04, 0.26), SAND_LIGHT)

    # --- bara din fata si din spate: ASPHALT, leaga silueta de sol ---
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (half_l + 0.03), body_lo + 0.16),
              (BUS_W - 0.16, 0.10, 0.30), ASPHALT)

    return b.to_object("Consettur_Bus")


# --- trenul ------------------------------------------------------------------
#
# Cote de contract (brief §1.5): locomotiva 2.8 lat x 3.6 inalt x 9 m lung,
# vagoane 2.8 x 3.6 x 8 m. LUNGIMEA E PE X (vezi antet).
# In Blender aici: X = lungime (+X = botul), Y = latime, Z = inaltime.
#
# ATENTIE la ordinea cotelor din brief: "2,8 × 3,6 × 9" e (latime, inaltime,
# lungime). Le scriu explicit, ca sa nu se citeasca gresit.
TR_WIDTH = 2.8
TR_HEIGHT = 3.6
LOCO_LEN = 9.0
WAGON_LEN = 8.0
TENDER_LEN = 5.0            # vagonul scurt de bagaje (PeruRail n-are tender)

GAUGE_HALF = 0.45           # train_hazard.gd:55 — ecartamentul garniturii
WHEEL_R = 0.42              # raza rotii; baza ei cade la z=0
BOGIE_INSET = 1.45          # cat de departe de capat sta centrul boghiului


def _bogie(b, cx, length):
    """Un boghiu: doua roti pe fiecare sina, plus sasiul care le leaga.

    Rotile stau pe ecartamentul de contract (`|y| = GAUGE_HALF`) si ating
    z = 0 — hazardul ridica piesa la `RAIL_TOP`, deci geometria trebuie sa
    porneasca fix de la zero, altfel garnitura pluteste sau se infige.
    """
    faces = set()
    for sy in (-1.0, 1.0):
        for dx in (-0.62, 0.62):
            faces |= b.cylinder((cx + dx, sy * GAUGE_HALF, WHEEL_R),
                                WHEEL_R, 0.16, VOLCANIC_BLACK,
                                segments=9, axis="Y")
    # sasiul boghiului: o cutie joasa care leaga rotile
    faces |= b.box((cx, 0.0, WHEEL_R + 0.18), (1.9, GAUGE_HALF * 1.7, 0.30),
                   VOLCANIC_BLACK)
    return faces


def _underframe(b, length, floor_z):
    """Sasiul: grinda continua pe toata lungimea, sub podea."""
    return b.box((0.0, 0.0, floor_z - 0.16), (length - 0.30, TR_WIDTH * 0.86, 0.32),
                 VOLCANIC_BLACK)


def build_loco():
    """Locomotiva diesel: capota lunga + cabina inalta, CAR_BLUE cu banda
    CAR_YELLOW. Botul spre +X (contract, vezi antet).

    Silueta: nasul e mai JOS decat cabina — asa se citeste sensul de mers de la
    distanta, care e tot rostul unui tren care traverseaza drumul.
    """
    b = Builder()
    half = LOCO_LEN * 0.5
    floor_z = WHEEL_R * 2.0 + 0.22       # podeaua, peste boghiuri
    body_hi = TR_HEIGHT

    _bogie(b, +half - BOGIE_INSET, LOCO_LEN)
    _bogie(b, -half + BOGIE_INSET, LOCO_LEN)
    _underframe(b, LOCO_LEN, floor_z)

    # capota din fata (spre +X): mai joasa decat cabina.
    #
    # `0.52`, nu `0.62`: pe prima plansa cabina abia se ridica peste capota si
    # locomotiva citea ca o cutie lunga cu un capac — silueta nu spunea incotro
    # merge, adica exact ce trebuie sa spuna un tren care traverseaza drumul.
    # Cu capota la 52% din inaltimea utila, treapta capota->cabina e de ~0.45 m
    # si se vede de departe.
    # A TREIA OARA pe cota asta, si de fiecare data plansa solo a spus de ce:
    #   0.62 -> cabina abia se ridica peste capota: cutie lunga cu capac
    #   0.52 -> capota a coborat atat de jos incat a devenit o PLATFORMA, iar
    #           cabina statea pe ea ca o lada pusa pe un camion-platforma. Banda
    #           galbena cadea pe muchia platformei si intarea citirea gresita.
    # Capota unei diesel-hidraulice e o MASA, nu un podium: umple cam trei
    # sferturi din inaltimea utila, cabina iese peste ea cu un cap. 0.74 da
    # treapta de ~0.3 m spre cabina si o capota care se citeste ca volum.
    hood_hi = floor_z + (body_hi - floor_z) * 0.74
    b.box((half * 0.46, 0.0, (floor_z + hood_hi) * 0.5),
          (LOCO_LEN * 0.46, TR_WIDTH, hood_hi - floor_z), CAR_BLUE)
    # cabina: pana la cota totala, si putin mai INGUSTA decat capota, ca
    # treapta sa se citeasca si in plan, nu doar pe verticala
    cab_len = LOCO_LEN * 0.30
    b.box((-half * 0.12, 0.0, (floor_z + body_hi) * 0.5),
          (cab_len, TR_WIDTH - 0.10, body_hi - floor_z), CAR_BLUE)
    # capota din spate — mai SCURTA decat cea din fata (0.26, nu 0.34): pe
    # plansa solo locomotiva iesea aproape simetrica fata-spate si nu se citea
    # incotro merge. Cu capota lunga in fata si una scurta in spate, cabina cade
    # in treimea din spate, ca la o diesel-hidraulica reala.
    b.box((-half * 0.66, 0.0, (floor_z + hood_hi) * 0.5),
          (LOCO_LEN * 0.26, TR_WIDTH, hood_hi - floor_z), CAR_BLUE)

    # --- botul: pana tesita in fata capotei ---
    #
    # DOUA VERSIUNI GRESITE INAINTEA ASTEIA, amandoua prinse pe plansa solo:
    #   1. plug ca o cutie sub bot: plutea desprins de corp, in stanga jos.
    #   2. `prism` + `bmesh.ops.rotate` pe varfurile lui: ROTATIA A TARAT SI
    #      CORPUL. `prism` intoarce fetele, iar `{v for f in nose for v in
    #      f.verts}` culege varfuri care, dupa bevel si dupa ce alte primitive
    #      au atins aceleasi pozitii, NU mai sunt doar ale botului — rotatia a
    #      dus jumatate din locomotiva cu ea. Masurat pe GLB: inaltimea cadea de
    #      la 2.37 m la 0.81 m la 1.6 m de bot, adica corpul disparuse.
    #      Semnul care a dat-o de gol: numarul de triunghiuri a ramas IDENTIC
    #      (1404) desi adaugasem si scosesem geometrie — topologia neschimbata,
    #      pozitiile mutate.
    #
    # Lectia: nu roti multimi de varfuri partajate intr-un bmesh comun. Pana se
    # scrie DIRECT in coordonatele finale, ca inelele proprii din
    # build_machupicchu_hero.py — patru varfuri sus, patru jos, opt fete.
    nose_x0 = half - 0.95           # unde incepe pana (se lipeste de capota)
    nose_x1 = half                  # varful, la capatul locomotivei
    nose_hw = TR_WIDTH * 0.49
    nose_top_back = hood_hi - 0.06  # inaltimea la capota
    nose_top_tip = hood_hi - 0.62   # ... si la varf: de-aia e pana
    v = b.bm.verts.new
    back_lo_l = v((nose_x0, -nose_hw, floor_z))
    back_lo_r = v((nose_x0, nose_hw, floor_z))
    back_hi_l = v((nose_x0, -nose_hw, nose_top_back))
    back_hi_r = v((nose_x0, nose_hw, nose_top_back))
    tip_lo_l = v((nose_x1, -nose_hw * 0.86, floor_z))
    tip_lo_r = v((nose_x1, nose_hw * 0.86, floor_z))
    tip_hi_l = v((nose_x1, -nose_hw * 0.86, nose_top_tip))
    tip_hi_r = v((nose_x1, nose_hw * 0.86, nose_top_tip))
    nose = [
        b.bm.faces.new((back_hi_l, back_hi_r, tip_hi_r, tip_hi_l)),   # fata de sus
        b.bm.faces.new((back_lo_r, back_lo_l, tip_lo_l, tip_lo_r)),   # talpa
        b.bm.faces.new((back_lo_l, back_hi_l, tip_hi_l, tip_lo_l)),   # flanc stang
        b.bm.faces.new((back_hi_r, back_lo_r, tip_lo_r, tip_hi_r)),   # flanc drept
        b.bm.faces.new((tip_lo_l, tip_hi_l, tip_hi_r, tip_lo_r)),     # fruntea
    ]
    for f in nose:
        f[b.slot] = CAR_BLUE

    # banda galbena pe toata lungimea, la cota capotei — semnatura PeruRail
    band_z = floor_z + (hood_hi - floor_z) * 0.62
    b.box((0.0, 0.0, band_z), (LOCO_LEN - 0.20, TR_WIDTH + 0.05, 0.34),
          CAR_YELLOW)

    # geamurile cabinei: fata, spate si laterale
    win_lo = floor_z + (body_hi - floor_z) * 0.52
    win_hi = body_hi - 0.30
    for sy in (-1.0, 1.0):
        b.box((-half * 0.12, sy * (TR_WIDTH * 0.5 + 0.01),
               (win_lo + win_hi) * 0.5),
              (cab_len - 0.40, 0.04, win_hi - win_lo), ASPHALT)
    for dx in (cab_len * 0.5, -cab_len * 0.5):
        b.box((-half * 0.12 + dx, 0.0, (win_lo + win_hi) * 0.5),
              (0.04, TR_WIDTH - 0.40, win_hi - win_lo), ASPHALT)

    # farul in bot. Plugul de zapada s-a scos: botul e acum o pana (vezi
    # `nose_outline`), iar lespedea de dedesubt plutea desprinsa de corp pe
    # plansa solo. Un singur volum care se termina in varf citeste mai bine
    # decat doua care nu se ating.
    b.box((half - 0.06, 0.0, hood_hi - 0.34), (0.10, 0.60, 0.30), SAND_LIGHT)

    return b.to_object("Train_Loco")


def _carriage(b, length, name_hi_windows=True):
    """Corpul comun al vagoanelor: cutie CAR_BLUE cu banda galbena, geamuri
    laterale mari si FERESTRE IN TAVAN (brief: vagonul panoramic PeruRail).

    Ferestrele de tavan sunt placi ASPHALT pe fetele inclinate ale acoperisului
    — semnatura vagonului panoramic, si se vad de sus, adica exact din camera
    de chase cam cand trenul traverseaza sub tine.
    """
    half = length * 0.5
    floor_z = WHEEL_R * 2.0 + 0.22
    body_hi = TR_HEIGHT - 0.25      # vagonul e putin mai jos decat locomotiva

    _bogie(b, +half - BOGIE_INSET, length)
    _bogie(b, -half + BOGIE_INSET, length)
    _underframe(b, length, floor_z)

    b.box((0.0, 0.0, (floor_z + body_hi) * 0.5),
          (length, TR_WIDTH, body_hi - floor_z), CAR_BLUE)

    # banda galbena la cota geamurilor
    band_z = floor_z + (body_hi - floor_z) * 0.30
    b.box((0.0, 0.0, band_z), (length - 0.16, TR_WIDTH + 0.05, 0.30),
          CAR_YELLOW)

    # geamuri laterale mari
    win_lo = floor_z + (body_hi - floor_z) * 0.48
    win_hi = body_hi - 0.26
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (TR_WIDTH * 0.5 + 0.01), (win_lo + win_hi) * 0.5),
              (length - 1.10, 0.04, win_hi - win_lo), ASPHALT)

    # acoperisul: doua fete usor inclinate, cu ferestrele de tavan pe ele
    roof_z = body_hi
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * TR_WIDTH * 0.26, roof_z + 0.10),
              (length - 0.20, TR_WIDTH * 0.50, 0.18), CAR_BLUE,
              rotation=Matrix.Rotation(math.radians(sy * 7.0), 3, "X"))
        if name_hi_windows:
            b.box((0.0, sy * TR_WIDTH * 0.27, roof_z + 0.19),
                  (length - 1.40, TR_WIDTH * 0.30, 0.05), ASPHALT,
                  rotation=Matrix.Rotation(math.radians(sy * 7.0), 3, "X"))
    return floor_z, body_hi


def build_wagon():
    b = Builder()
    _carriage(b, WAGON_LEN, name_hi_windows=True)
    return b.to_object("Train_Wagon")


def build_tender():
    """`Train_Tender` — vagonul SCURT de bagaje (5 m).

    PeruRail n-are tender (locomotiva e diesel), dar nodul TREBUIE sa existe:
    `train_hazard.gd:381-386` arunca TOATA garnitura daca lipseste vreunul din
    cele trei noduri si cade pe cutii. Deci e un vagon de bagaje: acelasi corp,
    mai scurt, fara ferestre de tavan (bagajele n-au nevoie de panorama).
    """
    b = Builder()
    _carriage(b, TENDER_LEN, name_hi_windows=False)
    return b.to_object("Train_Tender")


# --- emit --------------------------------------------------------------------

clear_built()
results = []

AO_VEHICLE = dict(samples=24, dist=1.8, gradient="vertical",
                  low=0.62, high=1.0, power=0.9, floor=0.22)


def emit(obj, path, budget, bevel=0.03, origin="base", smooth_angle=34.0):
    """`smooth_angle=34`: un vehicul vrea MUCHII VII (caroseria e tabla indoita,
    nu piatra erodata). Pragul implicit de 55° rotunjea coltul dintre capota si
    cabina intr-un tub — se vede pe plansa."""
    st = finish(obj, bevel=bevel, ao=AO_VEHICLE, origin=origin,
                smooth_angle=smooth_angle)
    results.append((path, st["tris"], budget, st["ao_min"], st["ao_max"]))
    return st


bus = build_bus()
emit(bus, "vehicles/consettur_bus.glb", 1200, bevel=0.035, origin="base")
path, size = export_glb([bus], "machupicchu/vehicles/consettur_bus.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([bus], "machupicchu_bus.blend")

# Cele trei piese ale trenului pleaca in ACELASI GLB, ca noduri separate.
# `origin="base_axis"`: coboara doar pe Z (baza rotilor la zero) si pastreaza
# XY, deci ecartamentul ramane centrat pe y=0 si lungimea pe X neatinsa. Cu
# `origin="base"` fiecare nod s-ar re-centra pe bbox-ul LUI si piesele s-ar
# desprinde una de alta (capcana valului 2).
loco = build_loco()
tender = build_tender()
wagon = build_wagon()
for obj, budget in ((loco, 1400), (tender, 800), (wagon, 1200)):
    emit(obj, "vehicles/perurail_train.glb:" + obj.name, budget,
         bevel=0.03, origin="base_axis")
path, size = export_glb([loco, tender, wagon],
                        "machupicchu/vehicles/perurail_train.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([loco, tender, wagon], "machupicchu_train.blend")

print()
for path, tris, budget, ao_lo, ao_hi in results:
    flag = "OK" if tris <= budget else "DEPASIT"
    print("%-46s tris=%5d / %5d  %-7s AO %.2f..%.2f"
          % (path, tris, budget, flag, ao_lo, ao_hi))
train_total = sum(t for p, t, _, _, _ in results if "perurail" in p)
print("garnitura in GLB (loco+tender+wagon): %d tris" % train_total)
