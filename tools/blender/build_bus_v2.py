"""Tour bus v2 — masina 6/10 a garajului v2 (cea mai grea), dupa foaia
docs/asset_briefs/img/vehicles/concept_bus.jpeg (prompt: garaj_prompturi_chatgpt.md §2.6).

  TourBus   vehicles/bus_v2.glb
            Body + 2 lampi + 4 roti ca noduri separate (contractul din toy_driver_parts.py).

Forma: un PERETE pe roti. Un singur LOFT de sectiuni in U (cutie lunga, colturi
tesite): postul soferului in fata e mai inalt (dash plin + cavitate pentru sofer),
dupa treapta laturile coboara la centura, spatele e plin. Podeaua interioara sta
deasupra rotilor (cavitatea nu poate cobori sub roata). Banda alba, banchetele,
parbrizul, grila si farurile sunt blocuri separate.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_bus_v2.py
Plansa: python tools/blender/compare_concept.py bus_v2 concept_bus.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = TROPICAL_GREEN
DARK = VOLCANIC_BLACK
SEAT_SLOT = LOG_DARK

# --- contract ---------------------------------------------------------------
WHEEL_R = 0.46
WHEEL_W = 0.40
HALF_TRACK = 0.85              # 2*0.85 + 0.40 = 2.10 peste roti
Y_FRONT = -1.75
Y_REAR = 1.60
SEAT = (0.55, -1.30, 1.02)     # sofer SUS, fata-stanga; picioarele coboara la 0.84 (in podea)

HW = 0.98                      # jumatate de latime a caroseriei
ZB = 0.35                      # garda la sol
ZT_CAB = 1.58                  # postul soferului (mai inalt)
ZT_REAR = 1.35                 # centura pasagerilor
ZF = 1.00                      # podeaua interioara (peste roata: 0.46*2 = 0.92)
Y_END = 2.62                   # fata/spatele caroseriei
CAV_Y0, CAV_Y1 = -2.00, 2.48   # cavitatea deschisa
STEP_Y = -1.40                 # treapta cabina -> pasageri
ARCH_R = 0.58
ZA_CAP = 0.96                  # arcul nu urca peste podea (roata 0.92 + 4 cm)
WALL = 0.12


def _arch(y):
    za = ZB + 0.06
    for y0 in (Y_FRONT, Y_REAR):
        dy = abs(y - y0)
        if dy < ARCH_R:
            za = max(za, WHEEL_R + math.sqrt(ARCH_R ** 2 - dy ** 2))
    return min(za, ZA_CAP)


def _sec(y):
    hw, zb = HW, ZB
    zt = ZT_CAB if y < STEP_Y else ZT_REAR
    ay = abs(y)
    if ay > 2.50:
        t = (ay - 2.50) / 0.12
        hw = HW - 0.08 * t
        zt -= 0.10 * t
        zb = ZB + 0.10 * t
        za = zb + 0.06
    else:
        za = _arch(y)
    cavity = CAV_Y0 - 1e-6 <= y <= CAV_Y1 + 1e-6
    zf = ZF if cavity else zt - 0.01
    x2 = 0.55
    right = [(hw - WALL, zt), (hw - 0.10, zt), (hw, zt - 0.10),
             (hw, za), (x2, za), (x2, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    poly += [(-(hw - WALL), zf), (hw - WALL, zf)]
    return (y, poly)


def shell(b):
    ys = {-2.62, -2.56, -2.50, CAV_Y0 - 0.02, CAV_Y0,
          STEP_Y - 0.01, STEP_Y + 0.01,
          CAV_Y1, CAV_Y1 + 0.02, 2.56, 2.62}
    for y0 in (Y_FRONT, Y_REAR):
        for d in (-0.58, -0.50, -0.40, -0.28, -0.14, 0.0, 0.14, 0.28, 0.40, 0.50, 0.58):
            y = round(y0 + d, 3)
            if -2.50 <= y <= 2.50:
                ys.add(y)
    loft(b, [_sec(y) for y in sorted(ys)], PAINT)


def bumpers(b):
    """Bare groase negre, mai late decat caroseria, ca in foaie."""
    zb, zt = 0.34, 0.68
    for s in (-1, 1):
        sts = []
        for d, hw in ((2.76, 0.86), (2.70, 1.01), (2.58, 1.03), (2.25, 1.03)):
            sts.append((s * d, mirror_poly([(hw - 0.10, zt), (hw, zt - 0.08),
                                            (hw, zb + 0.08), (hw - 0.10, zb)])))
        if s > 0:
            sts = list(reversed(sts))
        loft(b, sts, DARK)


def front_and_rear(b):
    yf = -Y_END - 0.005
    b.box((0.0, yf, 0.84), (0.84, 0.06, 0.38), DARK)               # grila lata
    for sx in (-1, 1):
        lamp_head((sx * 0.70, yf, 0.84), (0.30, 0.07, 0.38), ICE_TURQUOISE)
        lamp_tail((sx * 0.74, Y_END + 0.005, 0.90), (0.24, 0.06, 0.34))
    b.box((0.0, Y_END + 0.005, 0.84), (0.70, 0.06, 0.34), DARK)     # grila motor spate


def bands(b):
    """Banda alba lata: pe fata sub parbriz si pe laturi (mai inalta la cabina)."""
    b.box((0.0, -Y_END - 0.004, 1.22), (1.74, 0.03, 0.44), FOAM_WHITE)
    b.box((0.0, Y_END + 0.004, 1.00), (1.74, 0.03, 0.34), FOAM_WHITE)
    for sx in (-1, 1):
        x = sx * (HW + 0.012)
        y0, y1 = -2.50, STEP_Y - 0.01
        b.box((x, (y0 + y1) * 0.5, 1.18), (0.03, y1 - y0, 0.44), FOAM_WHITE)
        y0, y1 = STEP_Y + 0.01, 2.50
        b.box((x, (y0 + y1) * 0.5, 1.00), (0.03, y1 - y0, 0.36), FOAM_WHITE)


def cab(b):
    # parbriz: BLOC turcoaz gros, aproape vertical, pe toata latimea fetei
    b.box((0.0, -2.00, ZT_CAB + 0.235), (1.90, 0.11, 0.47), ICE_TURQUOISE, rotation=rx(-7.0))
    x, y, z = SEAT
    # scaun jos pe podea; piedestal solid pana la 0.55 ascunde picioarele (coboara la 0.61)
    b.box((x, y - 0.06, 0.785), (0.66, 0.82, 0.47), SEAT_SLOT)
    b.box((x, y + 0.34, z + 0.34), (0.64, 0.12, 0.66), SEAT_SLOT, rotation=rx(-8.0))
    steering_wheel(b, SEAT, col_base=(x, -1.98, 1.40))


def benches(b):
    """Trei randuri de banchete maro, spatarul spre spate."""
    for y in (-0.10, 0.90, 1.90):
        b.box((0.0, y, 1.14), (1.56, 0.52, 0.28), SEAT_SLOT)
        b.box((0.0, y + 0.16, 1.40), (1.56, 0.30, 0.26), SEAT_SLOT, rotation=rx(-6.0))


def bus(b):
    shell(b)
    bumpers(b)
    front_and_rear(b)
    bands(b)
    cab(b)
    benches(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "TourBus", bus,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/bus_v2.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("bus_v2", objs, SEAT, shirt=TROPICAL_GREEN, length=5.5)
