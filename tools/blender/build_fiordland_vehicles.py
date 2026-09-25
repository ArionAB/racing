"""Fiordland — Vehicule (brief §1.6, val 3 din
docs/asset_briefs/fiordland_kit.md).

  fiordland/vehicles/coach_fiordland.glb   autocarul din tunelul Homer (TunnelSignalHazard)
  fiordland/vehicles/bush_plane.glb        monomotor (PathMover, aer)
  fiordland/vehicles/cruise_boat.glb       vaporas (PathMover, apa)
  fiordland/props/kayak_a.glb              caiac CAR_BLUE
  fiordland/props/kayak_b.glb              caiac CAR_YELLOW

COACH: cotele SUNT contractul de gameplay (TunnelSignalHazard.bus_width=3.0,
bus_length=8.5 — BusHazard ia AABB-ul din model). REUSE INCERCAT SI RESPINS,
cu masuratoare: `assets/models/vehicles/bus.fbx` importat si masurat aici
iese **3.81 lat x 13.70 lung x 4.27 inalt**. Adus la 8.5 m lungime (scara
0.62 pe Y) ar cere scara NEUNIFORMA pe toate cele trei axe ca sa incapa in
3.0 x 3.2 x 8.5 (X: 0.787, Y: 0.62, Z: 0.749) — rotile de 0.69 x 1.26 x 1.33 m
ar deveni ovale pe cel putin doua axe diferite, acelasi defect masurat si
respins la precedentul Machu Picchu (`build_machupicchu_vehicles.py`).
`bus.fbx` ramane NEATINS: se construieste cu Builder, aceeasi reteta
(profil YZ extrudat) ca `consettur_bus`, recolorata FOAM_WHITE/TROPICAL_GREEN/
VOLCANIC_BLACK.

AXE (brief §0.4): inainte = -Z Godot = +Y Blender.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_vehicles.py
"""

import bmesh
import math
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (brief §0.4).
BODY = FOAM_WHITE
BAND = TROPICAL_GREEN
DARK = VOLCANIC_BLACK
DECK = WOOD

AO_VEHICLE = dict(samples=22, dist=1.8, gradient="vertical",
                  low=0.60, high=1.0, power=0.9, floor=0.22)


# --- coach_fiordland -------------------------------------------------------
#
# Contract (brief §1.6 + tunnel_signal_hazard.gd): 3.0 lat x 3.2 inalt x 8.5
# lung. Nod "Coach". Origine la sol, centrata. Farurile: fete FOAM_WHITE pe
# botul din fata (+Y Blender).
COACH_W = 3.0
COACH_L = 8.5
COACH_H = 3.2

COACH_WHEEL_R = 0.55
COACH_WHEEL_T = 0.28
COACH_GROUND = 0.32          # garda la sol pana la caroserie
COACH_BAND_LO = 1.55
COACH_BAND_HI = 2.00


def build_coach():
    """Autocar de munte: profil YZ extrudat pe X (aceeasi reteta
    `consettur_bus`), scalat pe cotele Fiordland. FOAM_WHITE caroserie,
    TROPICAL_GREEN banda + fusta de jos, VOLCANIC_BLACK geamuri/roti."""
    b = Builder()
    half_w = COACH_W * 0.5
    half_l = COACH_L * 0.5
    body_lo = COACH_GROUND
    body_hi = COACH_H

    windshield_lo = COACH_BAND_HI
    rake = 0.62
    outline = [
        (half_l, body_lo),                       # botul, jos
        (half_l, windshield_lo),                 # pana sub parbriz
        (half_l - rake, body_hi),                # parbrizul inclinat
        (-half_l + 0.14, body_hi),               # acoperisul
        (-half_l, body_hi - 0.26),               # coltul din spate, tesit
        (-half_l, body_lo),                      # spatele, jos
    ]
    body = b.prism(outline, COACH_W, BODY, center=(0.0, 0.0, 0.0))
    bmesh.ops.rotate(b.bm, verts=list({v for f in body for v in f.verts}),
                     cent=(0.0, 0.0, 0.0),
                     matrix=Matrix.Rotation(math.radians(90.0), 3, "Z"))

    # fusta de jos: TROPICAL_GREEN, sub geamuri — brief: "banda si fusta de
    # jos" (doua zone verzi, nu doar banda de la geamuri)
    skirt_hi = COACH_BAND_LO - 0.02
    b.box((0.0, 0.0, (body_lo + skirt_hi) * 0.5),
          (COACH_W + 0.05, COACH_L + 0.05, skirt_hi - body_lo), BAND)

    # banda la nivelul geamurilor
    b.box((0.0, 0.0, (COACH_BAND_LO + COACH_BAND_HI) * 0.5),
          (COACH_W + 0.05, COACH_L + 0.05, COACH_BAND_HI - COACH_BAND_LO), BAND)

    # geamurile: VOLCANIC_BLACK, laterale + fata/spate
    win_lo = COACH_BAND_HI + 0.04
    win_hi = body_hi - 0.24
    for sx in (-1.0, 1.0):
        b.box((sx * (half_w + 0.01), 0.0, (win_lo + win_hi) * 0.5),
              (0.04, COACH_L - 0.85, win_hi - win_lo), DARK)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (half_l + 0.01), (win_lo + win_hi) * 0.5),
              (COACH_W - 0.55, 0.04, win_hi - win_lo), DARK)

    # acoperisul: lespede putin mai lata
    b.box((0.0, 0.0, body_hi + 0.06), (COACH_W + 0.06, COACH_L + 0.06, 0.12), BODY)

    # rotile: 4 cilindri VOLCANIC_BLACK
    axle_y = (half_l - 1.35, -half_l + 1.20)
    for sy in axle_y:
        for sx in (-1.0, 1.0):
            b.cylinder((sx * (half_w - COACH_WHEEL_T * 0.5 + 0.02), sy,
                        COACH_WHEEL_R),
                       COACH_WHEEL_R, COACH_WHEEL_T, DARK, segments=10, axis="X")

    # farurile: fete FOAM_WHITE pe botul din fata (+Y). Cutii mici, nu retag
    # (fata frontala e deja o singura fateta plana, dar geometria e sub
    # capul lui outline — un retag pe fata frontala ar prinde toata fata).
    for sx in (-1.0, 1.0):
        b.box((sx * (half_w - 0.60), half_l + 0.01, body_lo + 0.55),
              (0.40, 0.04, 0.28), BODY)

    # bara fata/spate: VOLCANIC_BLACK, leaga silueta de sol
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (half_l + 0.03), body_lo + 0.16),
              (COACH_W - 0.18, 0.10, 0.30), DARK)

    return b.to_object("Coach")


# --- bush_plane --------------------------------------------------------------
#
# Contract: anvergura 8.0 m, lungime 7.3 m, inaltime 2.7 m. Aripa SUS, tren
# coborat, elice cu disc. FOAM_WHITE + dungi CAR_RED, geamuri VOLCANIC_BLACK.
# Origine CENTRU fuzelaj (--origin=center). Inainte -Z Godot = +Y Blender.
PLANE_SPAN = 8.0
PLANE_LEN = 7.3
PLANE_H = 2.7
STRIPE = CAR_RED


def build_plane():
    """Monomotor cu aripa sus, fara nume/inmatriculare. Fuzelaj = taper_sweep
    (tub conic), aripa = cutie lunga si subtire sus, coada in T, tren fix cu
    3 roti, elice = disc PAINTED."""
    b = Builder()
    half_l = PLANE_LEN * 0.5

    # fuzelaj: tub conic pe Y (nasul spre +Y = inainte), sectiune ovala
    # aproximata cu un taper_sweep (cilindru), raza mica la coada, mare la
    # cabina, ingustata din nou spre bot.
    fuse_pts = [
        Vector((0, -half_l, 0.05)),                   # coada
        Vector((0, -half_l * 0.35, 0.15)),
        Vector((0, half_l * 0.15, 0.20)),              # cabina, cel mai gros
        Vector((0, half_l * 0.62, 0.14)),
        Vector((0, half_l, 0.03)),                     # botul motorului
    ]
    fuse_r = [0.32, 0.62, 0.72, 0.55, 0.30]
    b.taper_sweep(fuse_pts, fuse_r, BODY, segments=8, cap_start=True, cap_end=True)

    # aripa SUS: o cutie lunga, subtire, cu varfurile usor conice (doua
    # cutii care se ingusteaza spre capat) — asezata pe spinarea fuzelajului
    wing_z = 0.62
    wing_chord = 1.15
    wing_thick = 0.16
    half_span = PLANE_SPAN * 0.5
    b.box((0.0, half_l * 0.08, wing_z), (PLANE_SPAN - 1.6, wing_chord, wing_thick), BODY)
    for sx in (-1.0, 1.0):
        b.box((sx * (PLANE_SPAN * 0.5 - 0.8), half_l * 0.08, wing_z),
              (1.6, wing_chord * 0.7, wing_thick * 0.75), BODY)
    # strut-uri de sprijin (aripa sus = strut vizibil, semnatura Cessna)
    for sx in (-1.0, 1.0):
        b.beam((sx * (half_span * 0.55), half_l * 0.05, wing_z - 0.05),
              (sx * 0.55, half_l * 0.05, 0.10), 0.06, DARK)

    # dungi CAR_RED pe fuzelaj (retag pe o banda orizontala) + varfurile
    # aripii — brief: "FOAM_WHITE + dungi CAR_RED pe fuzelaj si la varfurile
    # aripilor"
    fuse_faces = [f for f in b.bm.faces if f.is_valid and f[b.slot] == BODY]
    b.retag(fuse_faces, STRIPE,
           where=lambda c, n: abs(c.z - 0.30) < 0.08 and abs(n.z) < 0.6)
    wing_tip_faces = [f for f in b.bm.faces if f.is_valid and f[b.slot] == BODY]
    b.retag(wing_tip_faces, STRIPE,
           where=lambda c, n: abs(c.y - wing_z) < 0.3 and abs(c.x) > half_span - 0.9)

    # geamurile cabinei: VOLCANIC_BLACK, laterale
    for sx in (-1.0, 1.0):
        b.box((sx * 0.63, half_l * 0.15, 0.55),
              (0.05, 1.1, 0.30), DARK)

    # coada in T: deriva verticala + stabilizator orizontal
    b.box((0.0, -half_l * 0.92, 0.55), (0.08, 0.75, 1.05), BODY)
    b.box((0.0, -half_l * 0.92, 1.02), (1.9, 0.60, 0.08), BODY)

    # trenul de aterizare: doua roti principale + una de bot, COBORAT.
    # segments=6 (nu 8): la scara de camera de joc un tren cu roti hexagonale
    # nu se distinge de unul octogonal, dar costa vizibil mai putin bevel.
    gear_r = 0.26
    for sx, sy in ((-1.0, 0.15), (1.0, 0.15)):
        b.beam((sx * 0.9, half_l * sy, 0.15), (sx * 0.9, half_l * sy, -0.55),
              0.05, DARK)
        b.cylinder((sx * 0.9, half_l * sy, -0.55), gear_r, 0.14, DARK,
                  segments=6, axis="X")
    b.beam((0.0, half_l * 0.72, 0.0), (0.0, half_l * 0.72, -0.45), 0.05, DARK)
    b.cylinder((0.0, half_l * 0.72, -0.45), gear_r * 0.75, 0.10, DARK,
              segments=6, axis="X")

    # elicea: disc PAINTED (nu pale separate, brief) in fata botului
    b.cylinder((0.0, half_l + 0.05, 0.0), 0.62, 0.04, PAINTED, segments=8, axis="Y")

    return b.to_object("Plane")


# --- cruise_boat -------------------------------------------------------------
#
# Contract: 14 x 4.5 x 5 m. Origine la LINIA DE PLUTIRE, carena 1.2 m sub
# origine. FARA dunga rosie. Punte deschisa sus, FOAM_WHITE, geamuri
# VOLCANIC_BLACK, puntea WOOD.
BOAT_LEN = 14.0
BOAT_W = 4.5
BOAT_H = 5.0
BOAT_DRAFT = 1.2


def build_boat():
    """Vaporas alb cu doua punti: carena sub linia de plutire (origine),
    cabina inchisa cu geamuri mari, punte deschisa deasupra cu balustrada
    (retag, nu geometrie — cost redus)."""
    b = Builder()
    half_l = BOAT_LEN * 0.5
    half_w = BOAT_W * 0.5

    # carena: profil YZ extrudat (prism), de la chila (sub origine) pana la
    # linia de plutire (Z=0) — subtiata la prova si pupa.
    hull_outline = [
        (half_l * 0.92, -BOAT_DRAFT * 0.15),      # prova, aproape la linia de plutire
        (half_l, 0.0),                            # varful prova
        (-half_l, 0.0),                            # pupa, la linia de plutire
        (-half_l * 0.85, -BOAT_DRAFT * 0.3),
        (-half_l * 0.55, -BOAT_DRAFT),             # chila plata sub pupa
        (half_l * 0.55, -BOAT_DRAFT),              # chila plata sub prova
    ]
    hull = b.prism(hull_outline, BOAT_W * 0.94, BODY, center=(0.0, 0.0, 0.0))
    bmesh.ops.rotate(b.bm, verts=list({v for f in hull for v in f.verts}),
                     cent=(0.0, 0.0, 0.0),
                     matrix=Matrix.Rotation(math.radians(90.0), 3, "Z"))

    # bordajul deasupra liniei de plutire: continua pana la puntea principala
    deck1_z = BOAT_H * 0.36
    b.box((0.0, 0.0, deck1_z * 0.5), (BOAT_W * 0.90, BOAT_LEN * 0.90, deck1_z), BODY)

    # cabina inchisa: geamuri mari pe toata lungimea
    cab_lo = deck1_z
    cab_hi = BOAT_H * 0.68
    b.box((0.0, 0.0, (cab_lo + cab_hi) * 0.5),
          (BOAT_W * 0.72, BOAT_LEN * 0.60, cab_hi - cab_lo), BODY)
    win_lo = cab_lo + 0.35
    win_hi = cab_hi - 0.25
    for sx in (-1.0, 1.0):
        b.box((sx * (BOAT_W * 0.36 + 0.01), 0.0, (win_lo + win_hi) * 0.5),
              (0.04, BOAT_LEN * 0.50, win_hi - win_lo), DARK)

    # puntea deschisa deasupra cabinei: platforma WOOD
    deck2_z = cab_hi
    b.box((0.0, -BOAT_LEN * 0.06, deck2_z + 0.05),
          (BOAT_W * 0.66, BOAT_LEN * 0.42, 0.10), DECK)

    # balustrada punte deschisa: doar montanti rari (nu geometrie continua) —
    # cateva bare subtiri, cost redus
    rail_z = deck2_z + 0.9
    for sy in (-1.0, -0.5, 0.0, 0.5, 1.0):
        for sx in (-1.0, 1.0):
            b.cylinder((sx * BOAT_W * 0.33, sy * BOAT_LEN * 0.18, deck2_z + 0.45),
                      0.03, 0.9, DARK, segments=5, axis="Z")

    # timonerie mica pe puntea deschisa, spre prova
    house_lo = deck2_z + 0.15
    house_hi = house_lo + 0.65
    b.box((0.0, BOAT_LEN * 0.24, (house_lo + house_hi) * 0.5),
          (BOAT_W * 0.40, BOAT_LEN * 0.16, house_hi - house_lo), BODY)
    b.box((0.0, BOAT_LEN * 0.24, house_hi - 0.20),
          (0.05, BOAT_LEN * 0.14, 0.30), DARK)

    return b.to_object("Boat")


# --- kayak_a / kayak_b -------------------------------------------------------
#
# Contract: 3.6 x 0.6 x 0.35 m. kayak_a CAR_BLUE, kayak_b CAR_YELLOW.
# Cockpit VOLCANIC_BLACK.
KAYAK_LEN = 3.6
KAYAK_W = 0.6
KAYAK_H = 0.35


def build_kayak(hull_slot, name):
    b = Builder()
    half_l = KAYAK_LEN * 0.5
    outline = [
        (0.0, -KAYAK_H * 0.05),           # chila (aproape plata)
        (KAYAK_W * 0.5, KAYAK_H * 0.55),  # bordaj
        (0.0, KAYAK_H),                    # punte, varf
        (-KAYAK_W * 0.5, KAYAK_H * 0.55),
    ]
    # extrudat pe traseul lungimii, cu latimea care se ingusteaza la prova/pupa.
    # n=4 (nu 6): bugetul de 100 tri/caiac nu are loc pentru mai multe inele
    # plus bevel plus cockpit — masurat, 6 inele ieseau 168 tri.
    n = 4
    rings = []
    for i in range(n + 1):
        t = i / n
        y = -half_l + KAYAK_LEN * t
        # ingustare cosinus la capete (prova/pupa ascutite)
        taper = math.sin(math.pi * min(max(t, 0.02), 0.98)) ** 0.6
        ring = [b.bm.verts.new((x * taper, y, z)) for x, z in outline]
        rings.append(ring)
    for lo, hi in zip(rings, rings[1:]):
        m = len(outline)
        for i in range(m):
            j = (i + 1) % m
            f = b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
            f[b.slot] = hull_slot
    b.bm.faces.new(tuple(reversed(rings[0])))[b.slot] = hull_slot
    b.bm.faces.new(tuple(rings[-1]))[b.slot] = hull_slot

    # cockpit: RETAG pe fetele de sus ale puntii (cost ZERO triunghiuri), nu
    # o cutie separata — bugetul de 100 tri/caiac nu are loc pentru geometrie
    # in plus. Fetele de sus ale inelelor din mijloc (cele doua fatete care
    # urca spre "punte", langa varful KAYAK_H) primesc DARK pe portiunea
    # centrala a lungimii.
    deck_faces = [f for f in b.bm.faces if f.is_valid and f[b.slot] == hull_slot]
    b.retag(deck_faces, DARK,
           where=lambda c, n: n.z > 0.3 and abs(c.y) < KAYAK_LEN * 0.16)

    return b.to_object(name)


# --- emit ----------------------------------------------------------------

clear_built()
results = []


def emit(obj, path, budget, bevel=0.03, origin="base", smooth_angle=34.0,
        origin_size=None, bevel_angle=30.0):
    st = finish(obj, bevel=bevel, bevel_angle=bevel_angle, ao=AO_VEHICLE,
                origin=origin, smooth_angle=smooth_angle, origin_size=origin_size)
    results.append((path, st["tris"], budget, st["ao_min"], st["ao_max"]))
    return st


coach = build_coach()
emit(coach, "vehicles/coach_fiordland.glb", 1200, bevel=0.035, origin="base")
path, size = export_glb([coach], "fiordland/vehicles/coach_fiordland.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([coach], "fiordland_coach.blend")

plane = build_plane()
# bevel_angle=60 (nu implicitul 30): geometria cilindrica (fuzelaj conic,
# roti, elice) are muchii sub 30 grade intre fatete vecine care altfel
# primesc bevel — acelasi fix de cost ca la avalanche.
st = finish(plane, bevel=0.02, bevel_angle=60.0, ao=AO_VEHICLE, origin="center",
           smooth_angle=30.0)
results.append(("vehicles/bush_plane.glb", st["tris"], 900, st["ao_min"], st["ao_max"]))
path, size = export_glb([plane], "fiordland/vehicles/bush_plane.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([plane], "fiordland_plane.blend")

# origin=None: `finish()` nu are un mod "waterline" (doar base/base_axis/
# center — ambele "base*" coboara `min(z)` la 0, ceea ce ar ridica toata
# barca si ar arunca originea la CHILA, nu la linia de plutire). Aici
# geometria e deja construita cu linia de plutire la Blender Z=0 prin
# constructie (chila la -BOAT_DRAFT, puntile deasupra) — origin=None sare
# peste pasul de recentrare si pastreaza exact ce s-a construit. Verificat
# cu verify_glb.py --origin=waterline (geometria trebuie sa incalece Y=0
# dupa export Y-up).
boat = build_boat()
emit(boat, "vehicles/cruise_boat.glb", 1500, bevel=0.03, origin=None,
    smooth_angle=34.0)
path, size = export_glb([boat], "fiordland/vehicles/cruise_boat.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([boat], "fiordland_boat.blend")

# bevel_angle=65 (nu implicitul 30): coca extrudata are fatete la unghiuri
# mici intre randuri vecine (4 inele pe 3.6 m) — la 30 grade bevel-ul testeste
# aproape toate muchiile longitudinale, exact costul care scotea caiacul din
# bugetul de 100 tri.
kayak_a = build_kayak(CAR_BLUE, "KayakA")
emit(kayak_a, "props/kayak_a.glb", 100, bevel=0.012, bevel_angle=65.0, origin="base")
export_glb([kayak_a], "fiordland/props/kayak_a.glb")
kayak_b = build_kayak(CAR_YELLOW, "KayakB")
emit(kayak_b, "props/kayak_b.glb", 100, bevel=0.012, bevel_angle=65.0, origin="base")
export_glb([kayak_b], "fiordland/props/kayak_b.glb")
save_blend([kayak_a, kayak_b], "fiordland_kayaks.blend")

print()
for path, tris, budget, ao_lo, ao_hi in results:
    flag = "OK" if tris <= budget else "DEPASIT"
    print("%-40s tris=%5d / %5d  %-7s AO %.2f..%.2f"
          % (path, tris, budget, flag, ao_lo, ao_hi))
