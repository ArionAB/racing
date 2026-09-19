"""Garajul DESCHIS: cele 5 masini ale garajului, refacute ca decapotabile de
tipuri diferite, plus variantele de sofer. Inlocuiesc FBX-urile RgsDev
(inchise), ca fiecare pilot sa poata fi aruncat din masina (vezi
docs/prototip_sofer_ragdoll.md; verdictul dezvoltatorului: „toti ragdoll").

  Roadster    vehicles/open_roadster.glb    Muscle:   lung, lat, jos; masa 1.35
  Interceptor vehicles/open_police.glb      Politia:  roadster usor, rampa de
                                            girofaruri pe arc
  Cab         vehicles/open_taxi.glb        Taxi:     cutie galbena fara acoperis,
                                            banda in carouri, firma pe arc
  Tour bus    vehicles/open_bus.glb         Autobuzul: autobuz turistic descoperit,
                                            randuri de banci, soferul in fata-stanga
  Pumper      vehicles/open_firetruck.glb   Pompierii: cabina deschisa, cisterna,
                                            scara pe spate
  Sofer       vehicles/toy_driver.glb (rosu), toy_driver_blue.glb,
              toy_driver_yellow.glb, toy_driver_green.glb

Identitatea (viteza/grip/masa/suspensie) NU se schimba — ramane in .tres.
Aici se schimba doar forma; dimensiunile tiparite (gabarit, driver_seat) se
copiaza in `scenes/cars/data/*.tres`. Conventiile de axe si contractul rotilor
sunt in toy_driver_parts.py.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_open_garage.py
Verificare (avertismentele asteptate sunt cele din build_toy_buggy.py):
    python tools/blender/verify_glb.py assets/models/vehicles/open_roadster.glb 4000 --origin=assembly
"""

import math
import os
from mathutils import Matrix, Vector

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "toy_driver_parts.py")).read())

STRIPE = FOAM_WHITE
DARK = VOLCANIC_BLACK
SEAT = LOG_DARK
GLASS = ICE_TURQUOISE      # parbrizul mic: un turcoaz deschis, citeste ca sticla


def hoop(b, x_half, y, z_base, z_top, t, slot, lean_deg=0.0):
    """Un arc de rollbar: doi montanti + traversa. `lean_deg` inclina spre spate."""
    dy = math.tan(math.radians(lean_deg)) * (z_top - z_base)
    for sx in (-1, 1):
        b.beam((sx * x_half, y, z_base), (sx * (x_half - 0.06), y + dy, z_top), t, slot)
    b.beam((-(x_half - 0.06), y + dy, z_top), ((x_half - 0.06), y + dy, z_top), t, slot)


def windshield(b, x_half, y, z_base, height, slot_frame, lean_deg=22.0):
    """Rama de parbriz inclinata, cu o placa de „sticla" subtire in ea."""
    dy = math.tan(math.radians(lean_deg)) * height
    for sx in (-1, 1):
        b.beam((sx * x_half, y, z_base), (sx * x_half, y - dy, z_base + height), 0.05, slot_frame)
    b.beam((-x_half, y - dy, z_base + height), (x_half, y - dy, z_base + height), 0.05, slot_frame)
    b.box((0.0, y - dy * 0.5, z_base + height * 0.5), (2 * x_half - 0.08, 0.03, height - 0.06),
          GLASS, rotation=rx(-lean_deg))


def bumper(b, y, z, width, slot):
    b.box((0.0, y, z), (width, 0.10, 0.12), slot)


def seat_box(b, x, y, z, w=0.6, d=0.56, back_h=0.62, lean=-8.0):
    b.box((x, y, z - 0.05), (w, d, 0.10), SEAT)
    b.box((x, y + d * 0.5 - 0.03, z + back_h * 0.5), (w, 0.10, back_h), SEAT, rotation=rx(lean))


# =============================================================================
# 1. ROADSTER (Muscle) — lung, lat, jos; capota lunga, doua locuri, aripioare
# =============================================================================
RD = dict(L=4.2, W=1.9, z0=0.30)
RD_SEAT = (0.42, 0.55, 0.62)       # x (stanga), y (spre spate), z


def roadster(b):
    z0 = RD["z0"]
    W, L = RD["W"], RD["L"]
    body_h = 0.42
    zm = z0 + body_h * 0.5
    paint = CAR_RED
    # corpul: coaja lunga si joasa; pragurile mai inchise
    b.box((0.0, 0.0, zm), (W, L - 0.5, body_h), paint)
    b.box((0.0, 0.0, z0 + 0.05), (W + 0.12, L - 0.9, 0.10), DARK)
    # capota lunga, usor ridicata spre cockpit; bulb pe capota
    b.box((0.0, -1.05, z0 + body_h + 0.04), (W - 0.16, 1.5, 0.10), paint)
    b.box((0.0, -0.9, z0 + body_h + 0.16), (0.5, 0.7, 0.16), paint)
    b.box((0.0, -1.05, z0 + body_h + 0.10), (0.30, 1.5, 0.02), STRIPE)   # dunga
    # botul: grila si bara
    b.box((0.0, -L * 0.5 + 0.22, z0 + 0.22), (W - 0.4, 0.10, 0.22), DARK)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.22), -L * 0.5 + 0.20, z0 + 0.30), (0.22, 0.08, 0.16), STRIPE)
    bumper(b, -L * 0.5 + 0.02, z0 + 0.10, W + 0.1, DARK)
    # cockpit: podea joasa, doua scaune, parbriz scurt, tablou de bord
    b.box((0.0, 0.55, z0 + 0.12), (W - 0.3, 1.2, 0.06), DARK)
    seat_box(b, RD_SEAT[0], RD_SEAT[1], RD_SEAT[2], w=0.56, d=0.5, back_h=0.56)
    seat_box(b, -RD_SEAT[0], RD_SEAT[1], RD_SEAT[2], w=0.56, d=0.5, back_h=0.56)
    b.box((0.0, -0.2, z0 + body_h + 0.10), (W - 0.3, 0.30, 0.16), DARK)     # bord
    windshield(b, W * 0.5 - 0.16, -0.3, z0 + body_h + 0.14, 0.34, DARK, lean_deg=30.0)
    # volanul
    b.beam((RD_SEAT[0], -0.05, z0 + body_h + 0.10), (RD_SEAT[0], 0.05, z0 + 0.98), 0.05, DARK)
    b.torus((RD_SEAT[0], 0.05, z0 + 0.98), 0.18, 0.03, DARK, major_seg=10, minor_seg=5, axis="Y")
    # arcul de siguranta in spatele scaunelor
    hoop(b, W * 0.5 - 0.22, 0.92, z0 + body_h, z0 + 1.28, 0.06, DARK, lean_deg=-6.0)
    # portbagaj cu aripioare mici si stopuri
    b.box((0.0, L * 0.5 - 0.55, z0 + body_h + 0.03), (W - 0.2, 0.7, 0.08), paint)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.10), L * 0.5 - 0.45, z0 + body_h + 0.16), (0.10, 0.6, 0.22), paint)
        b.box((sx * (W * 0.5 - 0.25), L * 0.5 - 0.06, z0 + 0.34), (0.26, 0.06, 0.12), CAR_RED)
    bumper(b, L * 0.5 - 0.02, z0 + 0.10, W + 0.1, DARK)
    # tevi de esapament
    for sx in (-1, 1):
        b.cylinder((sx * 0.35, L * 0.5 + 0.02, z0 + 0.06), 0.06, 0.24, RIM, segments=8, axis="Y")


# =============================================================================
# 2. INTERCEPTOR (Politia) — roadster usor, alb-albastru, girofaruri pe arc
# =============================================================================
PL = dict(L=4.2, W=1.88, z0=0.32)
PL_SEAT = (0.40, 0.50, 0.64)


def police(b):
    z0, W, L = PL["z0"], PL["W"], PL["L"]
    body_h = 0.44
    zm = z0 + body_h * 0.5
    b.box((0.0, 0.0, zm), (W, L - 0.4, body_h), CAR_BLUE)
    # banda alba pe usi + „POLICE" ca placa alba
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 + 0.005), 0.3, zm + 0.02), (0.02, 1.6, 0.16), STRIPE)
    b.box((0.0, 0.0, z0 + 0.05), (W + 0.12, L - 0.8, 0.10), DARK)
    # capota alba (contrast de tip politie), scurta si plata
    b.box((0.0, -1.1, z0 + body_h + 0.03), (W - 0.14, 1.3, 0.08), STRIPE)
    b.box((0.0, -L * 0.5 + 0.22, z0 + 0.24), (W - 0.36, 0.10, 0.24), DARK)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.22), -L * 0.5 + 0.20, z0 + 0.32), (0.22, 0.08, 0.16), STRIPE)
    # bara de impingere („push bar") in fata — semnul masinii de politie
    bumper(b, -L * 0.5 + 0.02, z0 + 0.12, W + 0.1, DARK)
    for sx in (-1, 1):
        b.beam((sx * 0.45, -L * 0.5 + 0.02, z0 + 0.18), (sx * 0.45, -L * 0.5 - 0.10, z0 + 0.52), 0.05, DARK)
    b.beam((-0.5, -L * 0.5 - 0.10, z0 + 0.52), (0.5, -L * 0.5 - 0.10, z0 + 0.52), 0.05, DARK)
    # cockpit
    b.box((0.0, 0.5, z0 + 0.12), (W - 0.3, 1.2, 0.06), DARK)
    seat_box(b, PL_SEAT[0], PL_SEAT[1], PL_SEAT[2], w=0.56, d=0.5, back_h=0.58)
    seat_box(b, -PL_SEAT[0], PL_SEAT[1], PL_SEAT[2], w=0.56, d=0.5, back_h=0.58)
    b.box((0.0, -0.25, z0 + body_h + 0.10), (W - 0.3, 0.30, 0.16), DARK)
    windshield(b, W * 0.5 - 0.16, -0.35, z0 + body_h + 0.14, 0.40, DARK, lean_deg=26.0)
    b.beam((PL_SEAT[0], -0.1, z0 + body_h + 0.10), (PL_SEAT[0], 0.0, z0 + 1.0), 0.05, DARK)
    b.torus((PL_SEAT[0], 0.0, z0 + 1.0), 0.18, 0.03, DARK, major_seg=10, minor_seg=5, axis="Y")
    # arcul cu rampa de girofaruri
    top = z0 + 1.34
    hoop(b, W * 0.5 - 0.20, 0.9, z0 + body_h, top, 0.06, DARK, lean_deg=-4.0)
    b.box((0.0, 0.86, top + 0.08), (1.1, 0.16, 0.12), DARK)
    b.box((-0.30, 0.86, top + 0.16), (0.36, 0.14, 0.14), CAR_RED)
    b.box((0.30, 0.86, top + 0.16), (0.36, 0.14, 0.14), CAR_BLUE)
    # spate
    b.box((0.0, L * 0.5 - 0.5, z0 + body_h + 0.03), (W - 0.2, 0.6, 0.08), CAR_BLUE)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.25), L * 0.5 - 0.19, z0 + 0.36), (0.26, 0.06, 0.12), CAR_RED)
    bumper(b, L * 0.5 - 0.02, z0 + 0.12, W + 0.1, DARK)
    # antena
    b.beam((-0.6, 1.4, z0 + body_h), (-0.6, 1.45, z0 + 1.2), 0.03, DARK)


# =============================================================================
# 3. CAB (Taxi) — cutie galbena fara acoperis, carouri, firma pe arc
# =============================================================================
TX = dict(L=3.9, W=2.0, z0=0.34)
TX_SEAT = (0.42, 0.15, 0.72)


def taxi(b):
    z0, W, L = TX["z0"], TX["W"], TX["L"]
    body_h = 0.62
    zm = z0 + body_h * 0.5
    b.box((0.0, 0.1, zm), (W, L - 0.6, body_h), CAR_YELLOW)
    b.box((0.0, 0.0, z0 + 0.05), (W + 0.12, L - 0.9, 0.10), DARK)
    # banda in carouri pe ambele laturi
    for sx in (-1, 1):
        for i in range(8):
            y = -1.2 + i * 0.34
            slot = DARK if i % 2 == 0 else STRIPE
            b.box((sx * (W * 0.5 + 0.005), y, zm + 0.08), (0.02, 0.32, 0.16), slot)
    # capota scurta, inalta; faruri rotunde mari
    b.box((0.0, -1.45, z0 + body_h - 0.10), (W - 0.2, 0.7, 0.12), CAR_YELLOW)
    b.box((0.0, -L * 0.5 + 0.22, z0 + 0.28), (W - 0.5, 0.10, 0.26), DARK)
    for sx in (-1, 1):
        b.cylinder((sx * (W * 0.5 - 0.28), -L * 0.5 + 0.17, z0 + 0.42), 0.12, 0.10, STRIPE,
                   segments=8, axis="Y")
    bumper(b, -L * 0.5 + 0.02, z0 + 0.12, W + 0.1, RIM)
    bumper(b, L * 0.5 - 0.02, z0 + 0.12, W + 0.1, RIM)
    # cabina deschisa: doua randuri de banci, bord, parbriz
    b.box((0.0, 0.3, z0 + 0.14), (W - 0.3, 2.0, 0.06), DARK)
    seat_box(b, TX_SEAT[0], TX_SEAT[1], TX_SEAT[2], w=0.6, d=0.5, back_h=0.6)
    seat_box(b, -TX_SEAT[0], TX_SEAT[1], TX_SEAT[2], w=0.6, d=0.5, back_h=0.6)
    seat_box(b, 0.0, 1.05, TX_SEAT[2], w=W - 0.5, d=0.5, back_h=0.6)      # bancheta
    b.box((0.0, -0.55, z0 + body_h + 0.06), (W - 0.3, 0.30, 0.16), DARK)
    windshield(b, W * 0.5 - 0.14, -0.65, z0 + body_h + 0.10, 0.5, DARK, lean_deg=18.0)
    b.beam((TX_SEAT[0], -0.4, z0 + body_h + 0.06), (TX_SEAT[0], -0.32, z0 + 1.08), 0.05, DARK)
    b.torus((TX_SEAT[0], -0.32, z0 + 1.08), 0.18, 0.03, DARK, major_seg=10, minor_seg=5, axis="Y")
    # arcul cu firma „TAXI" (placa alba cu margine neagra)
    top = z0 + 1.50
    hoop(b, W * 0.5 - 0.18, 0.55, z0 + body_h, top, 0.06, DARK)
    b.box((0.0, 0.55, top + 0.12), (0.7, 0.16, 0.22), STRIPE)
    b.box((0.0, 0.55, top + 0.12), (0.74, 0.14, 0.06), DARK)
    # portbagaj mic
    b.box((0.0, L * 0.5 - 0.45, z0 + body_h - 0.08), (W - 0.2, 0.5, 0.10), CAR_YELLOW)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.25), L * 0.5 - 0.29, z0 + 0.40), (0.24, 0.06, 0.14), CAR_RED)


# =============================================================================
# 4. TOUR BUS (Autobuzul) — descoperit, randuri de banci, sofer in fata-stanga
# =============================================================================
BS = dict(L=5.5, W=2.1, z0=0.36)
BS_SEAT = (0.55, -1.75, 0.98)      # soferul sus, in fata


def bus(b):
    z0, W, L = BS["z0"], BS["W"], BS["L"]
    wall_h = 0.9
    green = TROPICAL_GREEN
    # podeaua inalta si peretii laterali (autobuzul e o cutie fara capac)
    b.box((0.0, 0.0, z0 + 0.10), (W, L - 0.2, 0.20), DARK)
    b.box((0.0, 0.0, z0 + 0.26), (W - 0.1, L - 0.3, 0.12), green)          # brau
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.06), 0.0, z0 + 0.20 + wall_h * 0.5), (0.12, L - 0.3, wall_h), green)
        # ferestre „taiate" ca dungi turcoaz pe perete
        for i in range(5):
            y = -1.6 + i * 0.85
            b.box((sx * (W * 0.5 + 0.005), y, z0 + 0.75), (0.02, 0.55, 0.36), GLASS)
        b.box((sx * (W * 0.5 + 0.006), 0.0, z0 + 0.42), (0.02, L - 0.5, 0.08), STRIPE)
    # fata: parbriz mare inclinat, faruri, grila
    b.box((0.0, -L * 0.5 + 0.15, z0 + 0.20 + wall_h * 0.5), (W - 0.1, 0.12, wall_h), green)
    b.box((0.0, -L * 0.5 + 0.09, z0 + 0.92), (W - 0.5, 0.03, 0.42), GLASS)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.26), -L * 0.5 + 0.08, z0 + 0.42), (0.26, 0.06, 0.18), STRIPE)
    b.box((0.0, -L * 0.5 + 0.08, z0 + 0.36), (0.8, 0.06, 0.16), DARK)
    bumper(b, -L * 0.5 + 0.02, z0 + 0.14, W + 0.1, DARK)
    # spate: perete, motor, stopuri
    b.box((0.0, L * 0.5 - 0.15, z0 + 0.20 + wall_h * 0.5), (W - 0.1, 0.12, wall_h), green)
    b.box((0.0, L * 0.5 - 0.04, z0 + 0.62), (W - 0.6, 0.06, 0.36), DARK)     # grila motor
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.26), L * 0.5 - 0.06, z0 + 0.40), (0.26, 0.06, 0.16), CAR_RED)
    bumper(b, L * 0.5 - 0.02, z0 + 0.14, W + 0.1, DARK)
    # postul soferului: platforma ridicata, scaun, bord, volan
    b.box((0.0, -1.85, z0 + 0.5), (W - 0.3, 1.0, 0.6), DARK)
    seat_box(b, BS_SEAT[0], BS_SEAT[1], BS_SEAT[2], w=0.56, d=0.5, back_h=0.6)
    b.box((0.0, -2.35, z0 + 1.18), (W - 0.4, 0.26, 0.16), DARK)
    b.beam((BS_SEAT[0], -2.2, z0 + 1.18), (BS_SEAT[0], -2.1, z0 + 1.42), 0.05, DARK)
    b.torus((BS_SEAT[0], -2.1, z0 + 1.42), 0.20, 0.03, DARK, major_seg=10, minor_seg=5, axis="Y")
    # randurile de banci pentru turisti (4 randuri, spatar spre spate)
    for i in range(4):
        y = -0.75 + i * 0.75
        seat_box(b, 0.0, y, z0 + 0.62, w=W - 0.6, d=0.5, back_h=0.5)
    # balustrada de-a lungul peretilor si scara laterala
    for sx in (-1, 1):
        b.beam((sx * (W * 0.5 - 0.12), -1.3, z0 + 0.20 + wall_h),
               (sx * (W * 0.5 - 0.12), 2.4, z0 + 0.20 + wall_h), 0.05, RIM)
    # oglinzi mari
    for sx in (-1, 1):
        b.beam((sx * (W * 0.5), -L * 0.5 + 0.3, z0 + 1.05), (sx * (W * 0.5 + 0.30), -L * 0.5 + 0.2, z0 + 1.2), 0.04, DARK)
        b.box((sx * (W * 0.5 + 0.34), -L * 0.5 + 0.2, z0 + 1.22), (0.08, 0.14, 0.22), DARK)


# =============================================================================
# 5. PUMPER (Pompierii) — cabina deschisa, cisterna, scara, furtun
# =============================================================================
FT = dict(L=4.9, W=2.0, z0=0.40)
FT_SEAT = (0.45, -1.35, 0.92)


def firetruck(b):
    z0, W, L = FT["z0"], FT["W"], FT["L"]
    red = CAR_RED
    # sasiu + podea
    b.box((0.0, 0.0, z0 + 0.10), (W, L - 0.3, 0.20), DARK)
    # botul: capota scurta si inalta, grila cromata, faruri
    b.box((0.0, -L * 0.5 + 0.5, z0 + 0.55), (W - 0.2, 0.9, 0.7), red)
    b.box((0.0, -L * 0.5 + 0.06, z0 + 0.6), (W - 0.7, 0.06, 0.5), RIM)
    for sx in (-1, 1):
        b.cylinder((sx * (W * 0.5 - 0.3), -L * 0.5 + 0.06, z0 + 0.72), 0.12, 0.08, STRIPE,
                   segments=8, axis="Y")
    bumper(b, -L * 0.5 + 0.02, z0 + 0.16, W + 0.1, STRIPE)
    # cabina deschisa: podea, doua scaune, bord, parbriz, portiere joase
    b.box((0.0, -1.3, z0 + 0.45), (W - 0.2, 1.1, 0.5), red)
    seat_box(b, FT_SEAT[0], FT_SEAT[1], FT_SEAT[2], w=0.56, d=0.5, back_h=0.6)
    seat_box(b, -FT_SEAT[0], FT_SEAT[1], FT_SEAT[2], w=0.56, d=0.5, back_h=0.6)
    b.box((0.0, -1.95, z0 + 1.10), (W - 0.3, 0.26, 0.16), DARK)
    windshield(b, W * 0.5 - 0.14, -2.0, z0 + 1.14, 0.5, DARK, lean_deg=12.0)
    b.beam((FT_SEAT[0], -1.8, z0 + 1.10), (FT_SEAT[0], -1.72, z0 + 1.36), 0.05, DARK)
    b.torus((FT_SEAT[0], -1.72, z0 + 1.36), 0.18, 0.03, DARK, major_seg=10, minor_seg=5, axis="Y")
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.06), -1.3, z0 + 0.95), (0.10, 1.0, 0.5), red)   # portiere joase
    # arcul cabinei cu girofar
    top = z0 + 1.8
    hoop(b, W * 0.5 - 0.20, -0.8, z0 + 0.7, top, 0.06, DARK)
    b.box((0.0, -0.8, top + 0.10), (0.3, 0.2, 0.16), CAR_RED)
    # cisterna: cutie rosie inalta pe spate, cu dulapuri (dungi) si o dunga alba
    b.box((0.0, 0.75, z0 + 0.75), (W - 0.2, 2.3, 0.9), red)
    b.box((0.0, 0.75, z0 + 0.62), (W - 0.15, 2.32, 0.10), STRIPE)
    for sx in (-1, 1):
        for i in range(3):
            b.box((sx * (W * 0.5 - 0.09), 0.05 + i * 0.7, z0 + 0.92), (0.02, 0.5, 0.42), RIM)
    # rezervorul cilindric peste cisterna, si furtunul infasurat
    b.cylinder((0.0, 0.85, z0 + 1.45), 0.36, 1.9, RIM, segments=10, axis="Y")
    b.cylinder((0.0, 1.98, z0 + 1.0), 0.26, 0.18, CAR_YELLOW, segments=10, axis="Y")
    b.cylinder((0.0, 1.98, z0 + 1.0), 0.14, 0.24, DARK, segments=8, axis="Y")
    # scara pe partea dreapta a cisternei (Blender -X), culcata pe lung
    b.ladder((-(W * 0.5 - 0.02), 1.9, z0 + 1.58), (-(W * 0.5 - 0.02), -0.3, z0 + 1.62),
             0.36, 0.32, 0.04, 0.02, RIM)
    # spate: platforma, stopuri, bara alba
    b.box((0.0, L * 0.5 - 0.2, z0 + 0.32), (W - 0.2, 0.3, 0.2), DARK)
    for sx in (-1, 1):
        b.box((sx * (W * 0.5 - 0.26), L * 0.5 - 0.05, z0 + 0.5), (0.26, 0.06, 0.16), CAR_RED)
    bumper(b, L * 0.5 - 0.02, z0 + 0.16, W + 0.1, STRIPE)


# =============================================================================
if __name__ == "__main__":
    clear_built()

    # --- soferii: patru tricouri; fiecare varianta se sterge inainte de urmatoarea
    # (numele pieselor sunt contractul cu Godot si trebuie sa ramana exacte)
    for shirt, fname in ((CAR_RED, "vehicles/toy_driver.glb"),
                         (CAR_BLUE, "vehicles/toy_driver_blue.glb"),
                         (CAR_YELLOW, "vehicles/toy_driver_yellow.glb")):
        remove_objects(build_driver(shirt, fname))
    driver = build_driver(TROPICAL_GREEN, "vehicles/toy_driver_green.glb")

    # --- vehiculele
    garage = []
    garage.append((export_vehicle(
        "Roadster", roadster,
        dict(radius=0.38, width=0.34, half_track=0.86, y_front=-1.35, y_rear=1.30),
        "vehicles/open_roadster.glb", RD_SEAT), RD_SEAT))
    garage.append((export_vehicle(
        "Interceptor", police,
        dict(radius=0.37, width=0.32, half_track=0.85, y_front=-1.35, y_rear=1.30),
        "vehicles/open_police.glb", PL_SEAT), PL_SEAT))
    garage.append((export_vehicle(
        "Cab", taxi,
        dict(radius=0.38, width=0.34, half_track=0.90, y_front=-1.25, y_rear=1.20),
        "vehicles/open_taxi.glb", TX_SEAT), TX_SEAT))
    garage.append((export_vehicle(
        "TourBus", bus,
        dict(radius=0.46, width=0.40, half_track=0.92, y_front=-1.85, y_rear=1.75),
        "vehicles/open_bus.glb", BS_SEAT), BS_SEAT))
    garage.append((export_vehicle(
        "Pumper", firetruck,
        dict(radius=0.44, width=0.40, half_track=0.90, y_front=-1.65, y_rear=1.55),
        "vehicles/open_firetruck.glb", FT_SEAT), FT_SEAT))

    # --- previzualizari (DUPA export: mutarile de mai jos nu au voie in GLB)
    g = dict(globals())
    exec(open(os.path.join(HERE_PARTS, "preview.py")).read(), g)
    # Toate vehiculele stau in origine, deci la poza fiecaruia CELELALTE se
    # ascund din randare (shot() incadreaza obiectele date, dar Blender
    # randeaza toata scena — lectia din nota de memorie despre cubul implicit).
    names = ["roadster", "police", "taxi", "bus", "firetruck"]
    allobjs = [o for objs, _s in garage for o in objs]
    for (objs, seat), nm in zip(garage, names):
        for o in allobjs:
            o.hide_render = o not in objs
        seat_driver(driver, seat)
        out = os.path.join(PROJECT, "snapshots", "open_%s_preview.png" % nm)
        g["shot"](objs + driver, out, azimuth=35.0, elevation=16.0)
    # poza de grup: toate in linie, fara sofer
    for o in allobjs:
        o.hide_render = False
    for o in driver:
        o.hide_render = True
    x = -7.0
    for objs, _seat in garage:
        shift_objects(objs, x)
        x += 3.6
    g["shot"](allobjs, os.path.join(PROJECT, "snapshots", "open_garage_lineup.png"),
              azimuth=25.0, elevation=18.0, margin=1.05)
    print("PREVIEW: snapshots/open_*_preview.png, open_garage_lineup.png")
