"""Ambulanta v2 — masina 7/10 a garajului v2 (inalta, grea de sus), dupa foaia
docs/asset_briefs/img/vehicles/concept_ambulance.jpeg (prompt: garaj_prompturi_chatgpt.md §2.7).

  Ambulance   vehicles/ambulance.glb
              Body + 2 lampi + 4 roti ca noduri separate (contractul din toy_driver_parts.py).

Forma: doua LOFT-uri albe — cabina deschisa in fata (sectiuni in U, arcuri de
roata taiate) si cutia inalta inchisa din spate (colturi tesite, spate plat).
Banda rosie = placi subtiri lipite pe flancuri (urmaresc arcul rotii) + panouri
pe fata/spate. Girofar rosu+albastru pe muchia de sus-fata a cutiei, arc negru
rotund lipit de fata cutiei, bare/sill/grila negre. Fara cruce, fara text.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_ambulance.py
Plansa: python tools/blender/compare_concept.py ambulance concept_ambulance.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = FOAM_WHITE
BAND = CAR_RED
DARK = VOLCANIC_BLACK
SEAT_SLOT = LOG_DARK

# --- contract ---------------------------------------------------------------
WHEEL_R = 0.40
WHEEL_W = 0.36
HALF_TRACK = 0.87              # 2*0.87 + 0.36 = 2.10 peste roti
Y_FRONT = -1.45
Y_REAR = 1.40
SEAT = (0.42, -0.70, 0.74)     # soferul pe stanga; picioarele coboara la ~0.33

HW = 0.96                      # jumatate de latime caroserie (cabina)
HWB = 0.97                     # cutia
ZB = 0.38                      # fundul caroseriei
ZF = 0.50                      # podeaua cabinei
ZT = 1.18                      # linia de sus a cabinei
ZTB = 2.08                     # varful cutiei (+0.12 girofar = 2.20)
ZBAND = 0.98                   # marginea de sus a benzii rosii
ARCH_R = 0.45
CAB_Y0, CAB_Y1 = -1.50, -0.10  # cabina deschisa (parbriz .. fata cutiei)
CAB_END = 0.06                 # cabina intra in cutie
BOX_Y0, BOX_Y1 = -0.10, 2.22   # cutia
HOOP_Y = -0.18
HOOP_TOP = 1.62

_OFFS = (-0.55, -0.50, -0.44, -0.38, -0.28, -0.16, 0.0, 0.16, 0.28, 0.38, 0.44, 0.50, 0.55)


def _arch(y):
    za = ZB + 0.06
    for y0 in (Y_FRONT, Y_REAR):
        dy = abs(y - y0)
        if dy < ARCH_R:
            za = max(za, WHEEL_R + math.sqrt(ARCH_R ** 2 - dy ** 2))
    return za


def _bulge(y):
    g = 0.0
    for y0, amp in ((Y_FRONT, 0.06), (Y_REAR, 0.05)):
        dy = abs(y - y0)
        if dy < 0.55:
            g += amp * math.cos(math.pi * 0.5 * dy / 0.55) ** 2
    return g


def _cab_dims(y):
    """(hw, zt, zb, za) ale cabinei la statia y; capul din fata se micsoreaza."""
    hw, zt, zb = HW + _bulge(y), ZT, ZB
    t = max(0.0, min(1.0, (-1.96 - y) / 0.16))
    hw -= 0.10 * t
    zt -= 0.14 * t
    zb += 0.12 * t
    za = max(zb + 0.06, _arch(y)) if t == 0 else zb + 0.06
    return hw, zt, zb, za


def _cab_sec(y):
    hw, zt, zb, za = _cab_dims(y)
    cavity = CAB_Y0 - 1e-6 <= y <= CAB_Y1 + 1e-6
    zf = ZF if cavity else zt - 0.01
    x2 = min(0.60, hw - 0.20)
    wall = 0.14
    right = [(hw - wall, zt), (hw - 0.10, zt), (hw, zt - 0.10),
             (hw, za), (x2, za), (x2, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    poly += [(-(hw - wall), zf), (hw - wall, zf)]
    return (y, poly)


def _box_dims(y):
    hw, zt, zb = HWB + _bulge(y) * 0.6, ZTB, 0.40
    tf = max(0.0, min(1.0, (BOX_Y0 + 0.08 - y) / 0.08))
    tr = max(0.0, min(1.0, (y - (BOX_Y1 - 0.08)) / 0.08))
    t = max(tf, tr)
    hw -= 0.07 * t
    zt -= 0.07 * t
    za = _arch(y) if t == 0 else zb + 0.06
    return hw, zt, zb, max(za, zb + 0.06)


def _box_sec(y):
    hw, zt, zb, za = _box_dims(y)
    x2 = min(0.62, hw - 0.20)
    right = [(hw - 0.16, zt), (hw - 0.05, zt - 0.03), (hw, zt - 0.16),
             (hw, za), (x2, za), (x2, zb)]
    return (y, mirror_poly(right))


def shell(b):
    # cabina
    ys = {-2.12, -2.04, -1.96, CAB_Y0 - 0.02, CAB_Y0, CAB_Y1, CAB_Y1 + 0.02,
          CAB_Y1 + 0.06, CAB_END}
    for d in _OFFS:
        y = round(Y_FRONT + d, 3)
        if -2.0 < y < CAB_END:
            ys.add(y)
    loft(b, [_cab_sec(y) for y in sorted(ys)], PAINT)
    # cutia
    ys = {BOX_Y0, BOX_Y0 + 0.04, BOX_Y0 + 0.08, BOX_Y1 - 0.08, BOX_Y1 - 0.04, BOX_Y1}
    for d in _OFFS:
        y = round(Y_REAR + d, 3)
        if BOX_Y0 + 0.08 < y < BOX_Y1 - 0.08:
            ys.add(y)
    loft(b, [_box_sec(y) for y in sorted(ys)], PAINT)


def band(b):
    """Banda rosie: placi pe flancuri (jos urmaresc arcul) + panouri fata/spate."""
    ys_c = sorted({-2.12, -2.04, -1.96, CAB_Y0 - 0.02, CAB_Y0, CAB_Y1, CAB_Y1 + 0.02, -0.04}
                  | {round(Y_FRONT + d, 3) for d in _OFFS if -2.0 < Y_FRONT + d < -0.04})
    ys_b = sorted({BOX_Y0 + 0.08, BOX_Y1 - 0.08, 0.0}
                  | {round(Y_REAR + d, 3) for d in _OFFS
                     if BOX_Y0 + 0.08 < Y_REAR + d < BOX_Y1 - 0.08})
    for s in (-1, 1):
        for ys, dims in ((ys_c, _cab_dims), (ys_b, _box_dims)):
            sts = []
            for y in ys:
                hw, zt, zb, za = dims(y)
                x1, x0 = hw + 0.014, hw - 0.04
                if s > 0:
                    poly = [(x1, ZBAND), (x1, za), (x0, za), (x0, ZBAND)]
                else:
                    poly = [(-x0, ZBAND), (-x0, za), (-x1, za), (-x1, ZBAND)]
                sts.append((y, poly))
            loft(b, sts, BAND)
    # panou fata (pe capul tesit) si spate
    hw, zt, zb, za = _cab_dims(-2.12)
    b.box((0.0, -2.12 - 0.008, (zb + ZBAND) * 0.5), (2 * (hw + 0.014), 0.03, ZBAND - zb), BAND)
    hw, zt, zb, za = _box_dims(BOX_Y1)
    b.box((0.0, BOX_Y1 + 0.008, (0.56 + ZBAND) * 0.5), (2 * (hw + 0.014), 0.03, ZBAND - 0.56), BAND)


def bumpers(b):
    """Bare groase negre care inconjoara coltul + sill negru intre roti."""
    zb, zt = 0.30, 0.56
    for s in (-1, 1):
        sts = []
        for d, hw in ((2.30, 0.84), (2.24, 0.99), (2.10, 1.02), (1.84, 1.02)):
            sts.append((s * d, mirror_poly([(hw - 0.10, zt), (hw, zt - 0.07),
                                            (hw, zb + 0.07), (hw - 0.10, zb)])))
        if s > 0:
            sts = list(reversed(sts))
        loft(b, sts, DARK)
    for sx in (-1, 1):
        b.box((sx * 0.985, 0.0, 0.40), (0.07, 1.74, 0.20), DARK)


def front_and_rear(b):
    b.box((0.0, -2.135, 0.74), (0.62, 0.07, 0.34), DARK)
    for k in (-1, 0, 1):
        b.box((0.0, -2.175, 0.74 + k * 0.10), (0.56, 0.02, 0.045), DARK)
    for sx in (-1, 1):
        lamp_head((sx * 0.64, -2.145, 0.78), (0.26, 0.06, 0.20))
        lamp_tail((sx * 0.72, BOX_Y1 + 0.01, 0.80), (0.16, 0.06, 0.24))
        # doua ferestre mici patrate pe spatele plat al cutiei
        b.box((sx * 0.36, BOX_Y1 + 0.005, 1.52), (0.36, 0.05, 0.36), ICE_TURQUOISE)


def lightbar(b):
    """Girofar: doua blocuri (rosu / albastru) pe muchia de sus-fata a cutiei,
    mai in spate decat soferul, deci nu trece peste casca."""
    z = ZTB + 0.06 - 0.005
    b.box((-0.36, BOX_Y0 + 0.30, z), (0.66, 0.36, 0.12), CAR_RED)
    b.box((0.36, BOX_Y0 + 0.30, z), (0.66, 0.36, 0.12), CAR_BLUE)


def cab(b):
    # parbriz scurt, turcoaz, inclinat ~30 grade
    b.box((0.0, -1.42, 1.30), (1.42, 0.035, 0.30), ICE_TURQUOISE, rotation=rx(-30.0))
    # bancheta + spatar
    b.box((0.0, -0.62, 0.61), (1.40, 0.70, 0.22), SEAT_SLOT)
    b.box((0.0, -0.33, 0.97), (1.40, 0.10, 0.56), SEAT_SLOT, rotation=rx(-8.0))
    steering_wheel(b, SEAT, col_base=(SEAT[0], -1.38, 1.06))


def hoop(b):
    """Arc negru rotund, lipit de fata cutiei, in spatele capului soferului."""
    x = 0.86
    tube(b, [(-x, HOOP_Y, 1.05), (-x, HOOP_Y, HOOP_TOP), (x, HOOP_Y, HOOP_TOP), (x, HOOP_Y, 1.05)],
         DARK, r=0.085, fillet=0.22, segments=8)


def ambulance(b):
    shell(b)
    band(b)
    bumpers(b)
    front_and_rear(b)
    lightbar(b)
    cab(b)
    hoop(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Ambulance", ambulance,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/ambulance.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("ambulance", objs, SEAT, shirt=CAR_RED, length=4.6)
