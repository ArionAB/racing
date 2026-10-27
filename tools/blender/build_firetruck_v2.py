"""Fire pumper v2 - masina 5/10 a garajului v2 (cea grea, impinge), dupa foaia
docs/asset_briefs/img/vehicles/concept_firepumper.jpeg (prompt: garaj_prompturi_chatgpt.md §2.5).

  Pumper   vehicles/firetruck_v2.glb
           Body + 2 lampi + 4 roti ca noduri separate (contractul din toy_driver_parts.py).

Forma: un singur LOFT rosu (bloc frontal plin cu bord inalt, cabina deschisa joasa,
corp inalt in spate cu buza deschisa), arcuri taiate in sectiune. Peste el:
cisterna cilindrica orizontala, scara culcata usor inclinata care depaseste spatele,
tambure de furtun cu flanse pe laturi, banda alba lata, bare groase negre, clopot rotund.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_firetruck_v2.py
Plansa: python tools/blender/compare_concept.py firetruck_v2 concept_firepumper.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = CAR_RED
DARK = VOLCANIC_BLACK
SEAT_SLOT = LOG_DARK
TANK = PAINTED

# --- contract ---------------------------------------------------------------
WHEEL_R = 0.44
WHEEL_W = 0.40
HALF_TRACK = 0.80              # 2*0.80 + 0.40 = 2.00 peste roti
Y_FRONT = -1.12
Y_REAR = 1.10
SEAT = (0.42, -0.67, 0.95)     # picioarele coboara la 0.54 (podea cabina 0.55)

HW = 0.86
ZB = 0.35                      # garda la sol
Y_END_F = -1.80                # fata: perete inalt, aproape fara capota
Y_END = 2.05                   # spatele corpului (barele pana la 2.47)
Y_FRONT_BLOCK = -1.30          # unde se termina peretele frontal plin (0.5 m)
Y_BODY = -0.15                 # unde incepe corpul inalt
ZT_FRONT, ZT_CAB, ZT_BODY = 1.34, 1.15, 1.33
ZF_CAB = 0.55
ARCH_R = 0.50
TANK_R = 0.42
TANK_Z = 1.45


def _arch(y):
    za = ZB + 0.06
    for y0 in (Y_FRONT, Y_REAR):
        dy = abs(y - y0)
        if dy < ARCH_R:
            za = max(za, WHEEL_R + math.sqrt(ARCH_R ** 2 - dy ** 2))
    return za


def _bulge(y):
    g = 0.0
    for y0, amp in ((Y_FRONT, 0.05), (Y_REAR, 0.05)):
        dy = abs(y - y0)
        if dy < 0.60:
            g += amp * math.cos(math.pi * 0.5 * dy / 0.60) ** 2
    return g


def _sec(y):
    if y < Y_FRONT_BLOCK:
        zt, zf = ZT_FRONT, ZT_FRONT - 0.01
    elif y < Y_BODY:
        zt, zf = ZT_CAB, ZF_CAB
    else:
        zt, zf = ZT_BODY, ZT_BODY - 0.12
        if y > Y_END - 0.16:
            zf = zt - 0.01          # perete spate inchis
    hw, zb = HW + _bulge(y), ZB
    za = _arch(y)
    t = 0.0
    if y > Y_END - 0.16:
        t = (y - (Y_END - 0.16)) / 0.16
    elif y < Y_END_F + 0.16:
        t = (Y_END_F + 0.16 - y) / 0.16
    if t > 0.0:
        hw -= 0.10 * t
        zt -= 0.14 * t
        if zf > zt - 0.01:
            zf = zt - 0.01
        zb = ZB + 0.17 * t
        za = zb + 0.06
    za = min(za, zt - 0.14)
    x2 = min(0.60, hw - 0.20)
    wall = 0.14
    right = [(hw - wall, zt), (hw - 0.10, zt), (hw, zt - 0.10),
             (hw, za), (x2, za), (x2, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    poly += [(-(hw - wall), zf), (hw - wall, zf)]
    return (y, poly)


def shell(b):
    ys = {Y_END_F, Y_END_F + 0.08, Y_END_F + 0.16, Y_END - 0.16, Y_END - 0.08, Y_END,
          Y_FRONT_BLOCK - 0.01, Y_FRONT_BLOCK, Y_BODY - 0.01, Y_BODY}
    for y0 in (Y_FRONT, Y_REAR):
        for d in (-0.60, -0.50, -0.30, 0.0, 0.30, 0.50, 0.60):
            ys.add(round(y0 + d, 3))
    ys = [y for y in ys if Y_END_F <= y <= Y_END]
    out = []
    for y in sorted(ys):
        if out and y - out[-1] < 0.004:
            continue
        out.append(y)
    loft(b, [_sec(y) for y in out], PAINT)


def bumpers(b):
    zb, zt = 0.30, 0.62
    for ys_, hws in (((-1.97, -1.92, -1.80, -1.60), (0.80, 0.95, 0.99, 0.99)),
                     ((2.22, 2.17, 2.05, 1.78), (0.80, 0.95, 0.99, 0.99))):
        sts = []
        for y, hw in zip(ys_, hws):
            sts.append((y, mirror_poly([(hw - 0.10, zt), (hw, zt - 0.08),
                                        (hw, zb + 0.08), (hw - 0.10, zb)])))
        if ys_[0] > 0:
            sts = list(reversed(sts))
        loft(b, sts, DARK)


def front_and_rear(b):
    yf = Y_END_F
    # bord frontal: lampi dreptunghiulare jos, clopot rotund gri mare deasupra
    for sx in (-1, 1):
        lamp_head((sx * 0.56, yf - 0.02, 0.70), (0.30, 0.07, 0.22), ICE_TURQUOISE)
        lamp_tail((sx * 0.62, Y_END + 0.02, 0.85), (0.24, 0.07, 0.22))
    b.cylinder((0.0, yf - 0.04, 1.02), 0.24, 0.12, MARBLE_GREY, segments=12, axis="Y")
    b.cylinder((0.0, yf - 0.11, 1.02), 0.10, 0.06, MARBLE_GREY, segments=12, axis="Y")


def band(b):
    """Banda alba lata pe laturile corpului inalt, urmand bombarea rotilor."""
    n = 5
    step = (Y_END - 0.20 - (Y_BODY + 0.05)) / n
    y0 = Y_BODY + 0.05 + step * 0.5
    for sx in (-1, 1):
        for i in range(n):
            y = y0 + i * step
            b.box((sx * (HW + max(_bulge(y + k * step * 0.5) for k in (-1, 0, 1)) + 0.012), y, 1.10), (0.025, step + 0.005, 0.28), FOAM_WHITE)


def reels(b):
    """Doua tambure de furtun pe fiecare lat: miez gri + doua flanse, axa X."""
    for sx in (-1, 1):
        for y in (0.30, 1.78):
            xin = HW + _bulge(y)
            b.cylinder((sx * (xin + 0.11), y, 1.10), 0.17, 0.22, MARBLE_GREY, segments=10, axis="X")
            for k in (0.03, 0.20):
                b.cylinder((sx * (xin + k), y, 1.10), 0.24, 0.05, MARBLE_GREY, segments=10, axis="X")


def cab(b):
    # parbriz scurt, turcoaz, lasat spre spate, pe marginea blocului frontal
    b.box((0.0, -1.25, 1.46), (1.20, 0.035, 0.26), ICE_TURQUOISE, rotation=rx(-30.0))
    # bancheta: cuseta + spatar usor inclinat pe peretele corpului
    b.box((0.0, -0.55, 0.735), (1.44, 0.52, 0.37), SEAT_SLOT)
    b.box((0.0, -0.23, 1.18), (1.44, 0.12, 0.56), SEAT_SLOT, rotation=rx(-8.0))
    x, y, z = SEAT
    steering_wheel(b, SEAT, col_base=(x, -1.25, 1.30))


def hoop(b):
    """Arc negru in spatele soferului, la nivelul castii (nu peste ea): montanti
    pe buza corpului + traversa; ramane sub scara."""
    yh = -0.07
    top = 1.95
    for sx in (-1, 1):
        b.box((sx * 0.74, yh, (ZT_BODY + top) * 0.5 - 0.05), (0.16, 0.16, top - ZT_BODY + 0.10), DARK)
        b.box((sx * 0.64, yh, top - 0.03), (0.24, 0.16, 0.16), DARK, rotation=ry(sx * 45.0))
    b.box((0.0, yh, top), (1.08, 0.16, 0.16), DARK)


def tank_and_ladder(b):
    y0, y1 = 0.15, 1.85
    yc = (y0 + y1) * 0.5
    b.cylinder((0.0, yc, TANK_Z), TANK_R, y1 - y0, TANK, segments=16, axis="Y")
    for y in (y0 + 0.30, y1 - 0.30):
        b.cylinder((0.0, y, TANK_Z), TANK_R + 0.025, 0.09, MARBLE_GREY, segments=12, axis="Y")
    # scara culcata, usor inclinata, iesind peste spate (decalata spre dreapta masinii)
    xl = -0.22
    b.ladder((xl, 0.15, 1.97), (xl, 2.80, 2.15), 0.40, 0.50, 0.06, 0.03, MARBLE_GREY, side=(1, 0, 0))
    for y in (0.55, 1.50):
        zl = 1.97 + 0.18 * (y - 0.15) / 2.65 - 0.04
        zs = 1.78
        b.box((xl, y, (zl + zs) * 0.5), (0.46, 0.10, zl - zs), MARBLE_GREY)


def pumper(b):
    shell(b)
    bumpers(b)
    front_and_rear(b)
    band(b)
    reels(b)
    cab(b)
    hoop(b)
    tank_and_ladder(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Pumper", pumper,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/firetruck_v2.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("firetruck_v2", objs, SEAT, shirt=CAR_RED, length=4.9)
