"""Camion de tractare v2 — masina 9/10 a garajului v2, dupa foaia
docs/asset_briefs/img/vehicles/concept_towtruck.jpeg (prompt: garaj_prompturi_chatgpt.md §2.9).

  TowTruck   vehicles/tow_truck.glb
             Body + 2 lampi + 4 roti ca noduri separate (contractul din toy_driver_parts.py).

Forma: UN loft galben lung (capota scurta inalta, cabina deschisa in U, perete
inalt in spatele bancheta, apoi platforma joasa cu arcuri de roata). Punte plata
gri deasupra, brat gri gros inclinat spre spate cu suport, lant de 4 zale si
carlig in J, aproape negre. Arc negru rotund in spatele soferului + girofar
portocaliu. Bare groase negre, grila neagra, doua blocuri portocalii la spate.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_tow_truck.py
Plansa: python tools/blender/compare_concept.py tow_truck concept_towtruck.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = CAR_YELLOW
DARK = VOLCANIC_BLACK
GREY = MARBLE_GREY
SEAT_SLOT = LOG_DARK

# --- contract ---------------------------------------------------------------
WHEEL_R = 0.44
WHEEL_W = 0.40
HALF_TRACK = 0.85              # 2*0.85 + 0.40 = 2.10 peste roti
Y_FRONT = -1.75
Y_REAR = 1.35
SEAT = (0.42, -0.70, 0.84)     # soferul pe stanga; picioarele coboara la ~0.43

HW = 0.96
ZB = 0.36
ZF = 0.60                      # podeaua cabinei
Z_HOOD, Z_CAB, Z_WALL, Z_DECK = 1.14, 1.10, 1.30, 1.02
Y_NOSE, Y_END = -2.42, 2.18
CAV_Y0, CAV_Y1 = -1.15, -0.27  # cavitatea cabinei
WALL_Y1 = -0.07
HOOP_Y = -0.16

_OFFS = (-0.55, -0.50, -0.44, -0.38, -0.28, -0.16, 0.0, 0.16, 0.28, 0.38, 0.44, 0.50, 0.55)


def _clamp01(t):
    return max(0.0, min(1.0, t))


def _arch(y):
    za = ZB + 0.06
    for y0, r in ((Y_FRONT, 0.52), (Y_REAR, 0.50)):
        dy = abs(y - y0)
        if dy < r:
            za = max(za, WHEEL_R + math.sqrt(r ** 2 - dy ** 2))
    return za


def _bulge(y):
    g = 0.0
    for y0, amp in ((Y_FRONT, 0.06), (Y_REAR, 0.05)):
        dy = abs(y - y0)
        if dy < 0.55:
            g += amp * math.cos(math.pi * 0.5 * dy / 0.55) ** 2
    return g


def _dims(y):
    hw = HW + _bulge(y)
    if y < CAV_Y0 - 0.01:
        zt = Z_HOOD
    elif y <= CAV_Y1 + 0.01:
        zt = Z_CAB
    elif y <= WALL_Y1 + 0.01:
        zt = Z_WALL
    else:
        zt = Z_DECK
    zb = ZB
    tf = _clamp01((-2.30 - y) / 0.12)
    hw -= 0.08 * tf
    zt -= 0.10 * tf
    zb += 0.12 * tf
    tr = _clamp01((y - 2.10) / 0.08)
    hw -= 0.07 * tr
    zt -= 0.06 * tr
    za = max(zb + 0.06, _arch(y)) if tf == 0 else zb + 0.06
    za = min(za, zt - 0.06)
    return hw, zt, zb, za


def _sec(y):
    hw, zt, zb, za = _dims(y)
    cavity = CAV_Y0 - 1e-6 <= y <= CAV_Y1 + 1e-6
    zf = ZF if cavity else zt - 0.01
    x2 = min(0.60, hw - 0.20)
    wall = 0.14
    right = [(hw - wall, zt), (hw - 0.10, zt), (hw, zt - 0.10),
             (hw, za), (x2, za), (x2, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    poly += [(-(hw - wall), zf), (hw - wall, zf)]
    return (y, poly)


def shell(b):
    ys = {Y_NOSE, -2.36, -2.30, -1.17, CAV_Y0, CAV_Y1, CAV_Y1 + 0.02, WALL_Y1,
          WALL_Y1 + 0.02, 0.2, 0.5, 2.10, 2.14, Y_END}
    for y0 in (Y_FRONT, Y_REAR):
        for d in _OFFS:
            y = round(y0 + d, 3)
            if Y_NOSE + 0.20 < y < CAV_Y0 - 0.04 or WALL_Y1 + 0.06 < y < 2.08:
                ys.add(y)
    loft(b, [_sec(y) for y in sorted(ys)], PAINT)
    # punte plata gri, inset pe platforma
    b.box((0.0, 1.06, Z_DECK + 0.025), (1.64, 2.24, 0.05), GREY)


def bumpers(b):
    zb, zt = 0.30, 0.64
    for pts in (((-2.50, 0.86), (-2.46, 0.98), (-2.38, 1.03), (-2.26, 1.03)),
                ((2.16, 1.02), (2.30, 1.02), (2.38, 0.98), (2.42, 0.86))):
        loft(b, [(y, mirror_poly([(hw - 0.10, zt), (hw, zt - 0.07),
                                  (hw, zb + 0.07), (hw - 0.10, zb)])) for y, hw in pts], DARK)
    # blocuri portocalii pe spatele barei
    for sx in (-1, 1):
        b.box((sx * 0.68, 2.425, 0.46), (0.24, 0.05, 0.20), LAVA_ORANGE)


def front_and_rear(b):
    b.box((0.0, -2.445, 0.86), (0.64, 0.06, 0.42), DARK)
    for k in (-1, 0, 1):
        b.box((0.0, -2.48, 0.86 + k * 0.11), (0.56, 0.03, 0.05), DARK)
    for sx in (-1, 1):
        lamp_head((sx * 0.70, -2.435, 0.88), (0.26, 0.06, 0.26))
        lamp_tail((sx * 0.84, Y_END + 0.005, 0.86), (0.16, 0.06, 0.24))


def cab(b):
    b.box((0.0, -1.44, 1.29), (1.42, 0.035, 0.30), ICE_TURQUOISE, rotation=rx(-30.0))
    b.box((0.0, -0.62, 0.71), (1.40, 0.70, 0.22), SEAT_SLOT)
    b.box((0.0, -0.36, 1.07), (1.40, 0.10, 0.56), SEAT_SLOT, rotation=rx(-8.0))
    steering_wheel(b, SEAT, col_base=(SEAT[0], -1.40, 1.10))


def hoop(b):
    x = 0.62
    tube(b, [(-x, HOOP_Y, 1.15), (-x, HOOP_Y, 1.80), (x, HOOP_Y, 1.80), (x, HOOP_Y, 1.15)],
         DARK, r=0.085, fillet=0.22, segments=8)
    b.box((0.0, HOOP_Y, 1.93), (0.56, 0.30, 0.14), LAVA_ORANGE)


BOOM_P1 = (0.0, 0.15, 1.22)
BOOM_P2 = (0.0, 2.50, 2.00)
CHAIN_Y = 2.30


def _boom_z(y):
    t = (y - BOOM_P1[1]) / (BOOM_P2[1] - BOOM_P1[1])
    return BOOM_P1[2] + t * (BOOM_P2[2] - BOOM_P1[2])


def crane(b):
    b.beam(BOOM_P1, BOOM_P2, (0.36, 0.26), GREY)
    # bloc de montaj + suport triunghiular la baza
    b.box((0.0, 0.32, 1.24), (0.64, 0.70, 0.46), GREY)
    sts = []
    for y in (0.60, 0.95, 1.30):
        zt = _boom_z(y) - 0.13 + 0.03
        sts.append((y, mirror_poly([(0.20, zt), (0.20, Z_DECK + 0.04)])))
    loft(b, sts, GREY)
    # lant: 4 zale, alternand 90 grade
    zc = _boom_z(CHAIN_Y) - 0.13 - 0.02
    for k in range(4):
        b.torus((0.0, CHAIN_Y, zc - 0.13 * k), 0.09, 0.04, DARK,
                major_seg=8, minor_seg=4, axis="X" if k % 2 == 0 else "Y")
    # carlig J
    ztop = zc - 0.13 * 3 - 0.10
    r = 0.16
    cz = ztop - 0.26
    path = [(0.0, CHAIN_Y, ztop), (0.0, CHAIN_Y, cz)]
    for a in range(180, 421, 30):
        ar = math.radians(a)
        path.append((0.0, CHAIN_Y + r + r * math.cos(ar), cz + r * math.sin(ar)))
    b.sweep(path, 0.085, DARK, segments=6, dome_end=True, cap_start=True)


def tow_truck(b):
    shell(b)
    bumpers(b)
    front_and_rear(b)
    cab(b)
    hoop(b)
    crane(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "TowTruck", tow_truck,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/tow_truck.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("tow_truck", objs, SEAT, shirt=CAR_YELLOW, length=5.0)
