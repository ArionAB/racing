"""Taxi v2 — masina 4/10 a garajului v2 (cea echilibrata), dupa foaia
docs/asset_briefs/img/vehicles/concept_taxi.jpeg (prompt: garaj_prompturi_chatgpt.md §2.4).

  Cab   vehicles/taxi_v2.glb
        Body + 2 lampi + 4 roti ca noduri separate (contractul din toy_driver_parts.py).

Forma: cutie galbena inalta, un singur LOFT de sectiuni in U (capota si puntea
din spate pline, cabina deschisa la mijloc), cu ARCURILE rotilor taiate in
sectiune (statii dese in jurul fiecarei roti). Banda in carouri = blocuri
solide alb / aproape-negru, firma alba simpla pe arcul lat.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_taxi_v2.py
Plansa: python tools/blender/compare_concept.py taxi_v2 concept_taxi.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = CAR_YELLOW
DARK = VOLCANIC_BLACK
SEAT_SLOT = LOG_DARK

# --- contract ---------------------------------------------------------------
WHEEL_R = 0.38
WHEEL_W = 0.36
HALF_TRACK = 0.82              # 2*0.82 + 0.36 = 2.00 peste roti
Y_FRONT = -1.15
Y_REAR = 1.15
SEAT = (0.42, 0.15, 0.64)      # pe stanga bancheta; picioarele coboara la ~0.23

HW = 0.88                      # jumatate de latime a caroseriei
ZT = 1.14                      # linia de sus a laturilor
ZB = 0.25                      # fundul (garda la sol 0.25)
ZF = 0.45                      # podeaua cabinei
CAB_Y0, CAB_Y1 = -0.60, 0.80   # cabina deschisa (intre parbriz si arc)
ARCH_R = 0.44
HOOP_Y = 0.66
HOOP_TOP = 1.80


def _arch(y):
    za = ZB + 0.06
    for y0 in (Y_FRONT, Y_REAR):
        dy = abs(y - y0)
        if dy < ARCH_R:
            za = max(za, WHEEL_R + math.sqrt(ARCH_R ** 2 - dy ** 2))
    return za


def _bulge(y):
    g = 0.0
    for y0, amp in ((Y_FRONT, 0.07), (Y_REAR, 0.05)):
        dy = abs(y - y0)
        if dy < 0.55:
            g += amp * math.cos(math.pi * 0.5 * dy / 0.55) ** 2
    return g


def _sec(y):
    """(y, poligon) pentru statia y; capetele se micsoreaza spre bare."""
    hw, zt, zb = HW + _bulge(y), ZT, ZB
    ay = abs(y)
    if ay > 1.66:
        t = (ay - 1.66) / 0.16
        hw = HW + _bulge(y) - 0.10 * t
        zt = ZT - 0.14 * t
        zb = ZB + 0.17 * t
        za = zb + 0.06
    else:
        za = _arch(y)
    cavity = CAB_Y0 - 1e-6 <= y <= CAB_Y1 + 1e-6
    zf = ZF if cavity else zt - 0.01
    x2 = min(0.60, hw - 0.20)
    wall = 0.14
    right = [(hw - wall, zt), (hw - 0.10, zt), (hw, zt - 0.10),
             (hw, za), (x2, za), (x2, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    poly += [(-(hw - wall), zf), (hw - wall, zf)]
    return (y, poly)


def shell(b):
    ys = {-1.82, -1.74, -1.66, 1.66, 1.74, 1.82,
          CAB_Y0 - 0.02, CAB_Y0, CAB_Y1, CAB_Y1 + 0.02}
    for y0 in (Y_FRONT, Y_REAR):
        for d in (-0.55, 0.55, -0.50, -0.44, -0.38, -0.28, -0.16, 0.0, 0.16, 0.28, 0.38, 0.44, 0.50):
            ys.add(round(y0 + d, 3))
    loft(b, [_sec(y) for y in sorted(ys)], PAINT)


def bumpers(b):
    """Bare groase, negre, care inconjoara coltul (hw mai mare decat caroseria)."""
    zb, zt = 0.26, 0.55
    for s in (-1, 1):
        sts = []
        for d, hw in ((1.95, 0.76), (1.90, 0.90), (1.80, 0.95), (1.55, 0.95)):
            sts.append((s * d, mirror_poly([(hw - 0.10, zt), (hw, zt - 0.07),
                                            (hw, zb + 0.07), (hw - 0.10, zb)])))
        if s < 0:
            sts = sts            # -1.95 .. -1.55, crescator
        else:
            sts = list(reversed(sts))   # 1.55 .. 1.95, crescator
        loft(b, sts, DARK)


def front_and_rear(b):
    # grila neagra plata
    b.box((0.0, -1.835, 0.70), (0.74, 0.06, 0.27), DARK)
    for sx in (-1, 1):
        b.cylinder((sx * 0.57, -1.825, 0.76), 0.17, 0.05, DARK, segments=12, axis="Y")
        lamp_head_round((sx * 0.57, -1.84, 0.76), 0.145, 0.07, segments=12)
        lamp_tail((sx * 0.70, 1.84, 0.80), (0.16, 0.06, 0.24))


def checker(b):
    n = 18
    sq = 0.17
    y0 = -(n * sq) * 0.5 + sq * 0.5
    for sx in (-1, 1):
        for i in range(n):
            slot = FOAM_WHITE if i % 2 == 0 else DARK
            b.box((sx * (HW + _bulge(y0 + i * sq) + 0.012), y0 + i * sq, 0.925), (0.02, sq, sq), slot)


def cab(b):
    # parbriz scurt, turcoaz, putin lasat spre spate
    b.box((0.0, -0.52, 1.25), (1.42, 0.035, 0.30), ICE_TURQUOISE, rotation=rx(-30.0))
    # bancheta intreaga (bloc pe podea, spatar usor inclinat)
    b.box((0.0, 0.12, 0.55), (1.46, 0.88, 0.22), SEAT_SLOT)
    b.box((0.0, 0.57, 0.90), (1.46, 0.14, 0.56), SEAT_SLOT, rotation=rx(-8.0))
    x, y, z = SEAT
    steering_wheel(b, SEAT, col_base=(x, -0.50, 1.04))


def hoop(b):
    """Arc lat si PLAT (banda 0.20 x 0.12), montanti pe laturile cabinei,
    colturi tesite la 45; firma alba pe mijlocul traversei."""
    zt = HOOP_TOP
    for sx in (-1, 1):
        x = sx * 0.78
        b.box((x, HOOP_Y, (0.98 + zt - 0.10) * 0.5), (0.20, 0.20, zt - 0.10 - 0.98 + 0.1), DARK)
        b.box((sx * 0.69, HOOP_Y, zt - 0.09), (0.30, 0.20, 0.20), DARK,
              rotation=ry(sx * 45.0))
    b.box((0.0, HOOP_Y, zt), (1.18, 0.20, 0.20), DARK)
    b.box((0.0, HOOP_Y, zt + 0.10 + 0.08), (0.55, 0.24, 0.16), FOAM_WHITE)


def taxi(b):
    shell(b)
    bumpers(b)
    front_and_rear(b)
    checker(b)
    cab(b)
    hoop(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Cab", taxi,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/taxi_v2.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("taxi_v2", objs, SEAT, shirt=CAR_YELLOW, length=3.9)
