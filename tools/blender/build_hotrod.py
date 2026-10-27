"""Hot Rod v2 — masina 8/10 a garajului v2 (inlocuieste camioneta), dupa foaia
docs/asset_briefs/img/vehicles/concept_hotrod.jpeg.

  HotRod   vehicles/hotrod.glb
           Body + 2 lampi + 4 roti ca noduri separate (contractul din
           toy_driver_parts.py). Roti spate mai mari decat cele din fata.

Forma: motor URIAS la vedere in fata (bloc V8 + chiulase + suflanta gri),
grila alba verticala, cadru negru intre roti, evacuari gri care curg pe lateral;
caroseria albastra e o cada rotunjita (LOFT) doar in spatele motorului.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_hotrod.py
Verificare:
    python tools/blender/verify_glb.py assets/models/vehicles/hotrod.glb 6500 --origin=assembly
Plansa: python tools/blender/compare_concept.py hotrod concept_hotrod.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = CAR_BLUE
DARK = VOLCANIC_BLACK
GREY = MARBLE_GREY
SEAT_SLOT = LOG_DARK

# --- contract ----------------------------------------------------------------
WHEEL_R = 0.40                 # FIZICA (roata din fata)
WHEEL_W = 0.30
WHEEL_R_REAR = 0.46
WHEEL_W_REAR = 0.42
HALF_TRACK = 0.72              # fata: 2*0.72 + 0.30 = 1.74
HALF_TRACK_REAR = 0.74         # spate: 2*0.74 + 0.42 = 1.90
Y_FRONT = -1.58
Y_REAR = 1.54
SEAT = (0.38, 0.50, 0.52)      # soferul pe stanga; picioarele (0.31) raman in placa podelei

Z_SILL = 0.36                  # fata de jos a cuvei
Z_FLOOR = 0.40
Y_COWL = -0.30                 # perete de foc (inceputul cuvei)


def interp(table, y):
    if y <= table[0][0]:
        return table[0][1]
    for (y0, v0), (y1, v1) in zip(table, table[1:]):
        if y <= y1:
            t = (y - y0) / (y1 - y0) if y1 > y0 else 0.0
            return v0 + (v1 - v0) * t
    return table[-1][1]


# (y, valoare); fata = -Y
HW = [(-0.30, 0.70), (-0.05, 0.74), (0.90, 0.74), (1.10, 0.62), (1.30, 0.57),
      (1.75, 0.56), (1.88, 0.50), (1.96, 0.36)]
ZT = [(-0.30, 0.98), (0.00, 0.96), (0.80, 0.95), (1.20, 0.93), (1.60, 0.90),
      (1.82, 0.86), (1.92, 0.80), (1.96, 0.72)]
ZB = [(-0.30, Z_SILL), (1.60, Z_SILL), (1.82, 0.40), (1.92, 0.50), (1.96, 0.58)]
# 1 = cuva deschisa (podea jos), 0 = punte inchisa; capul bordului la -0.30..-0.10
OPEN = [(-0.30, 0.0), (-0.12, 0.0), (-0.04, 1.0), (0.84, 1.0), (1.00, 0.0), (2.0, 0.0)]


def stations():
    ys = set()
    for tab in (HW, ZT, ZB, OPEN):
        ys.update(round(p[0], 3) for p in tab)
    for y in (0.95, 1.05, 1.25, 1.55, 1.68):
        ys.add(y)
    return sorted(y for y in ys if -0.30 <= y <= 1.96)


def section(y):
    hw = interp(HW, y)
    zt = interp(ZT, y)
    zb = interp(ZB, y)
    k = interp(OPEN, y)
    zf = (zt - 0.03) * (1.0 - k) + Z_FLOOR * k
    zf = max(zf, zb + 0.04)
    wall = 0.14
    zm = zb + 0.45 * (zt - zb)
    right = [(hw - wall, zt), (hw - 0.05, zt), (hw, zt - 0.07),
             (hw - 0.01, zm), (hw - 0.18, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    return poly + [(-(hw - wall), zf), (hw - wall, zf)]


# =============================================================================
# Corpul
# =============================================================================
def tub(b):
    loft(b, [(y, section(y)) for y in stations()], PAINT)
    # capul bordului, peste perete de foc
    b.box((0.0, Y_COWL + 0.06, 0.96), (1.40, 0.18, 0.12), PAINT)


def tail(b):
    for sx in (-1, 1):
        lamp_tail((sx * 0.42, 1.955, 0.68), (0.16, 0.05, 0.16))


def underbody(b):
    """Placa neagra sub cuva (ascunde pantofii) + cadrul vizibil intre roti."""
    b.box((0.0, 0.30, 0.31), (1.10, 1.30, 0.10), DARK)
    for sx in (-1, 1):
        # longeroane de la bot pana la spate
        b.box((sx * 0.44, -0.20, 0.28), (0.10, 3.60, 0.13), DARK)
        # tevi de sasiu sub longeron (tub rotund)
        tube(b, [(sx * 0.40, 1.45, 0.34), (sx * 0.52, 1.88, 0.40)], r=0.04, segments=6)
    # traversa + diferential in spate
    b.box((0.0, Y_REAR, 0.44), (0.34, 0.44, 0.26), DARK)
    rod(b, (-0.62, Y_REAR, WHEEL_R_REAR), (0.62, Y_REAR, WHEEL_R_REAR), 0.05, DARK, 6)
    rod(b, (-0.60, Y_FRONT, WHEEL_R), (0.60, Y_FRONT, WHEEL_R), 0.06, DARK, 6)
    # brate de ghidare fata -> longeron
    for sx in (-1, 1):
        for dz in (0.0, 0.14):
            rod(b, (sx * 0.50, Y_FRONT + 0.05, WHEEL_R + dz),
                (sx * 0.44, -0.75, 0.30 + dz * 0.4), 0.035, DARK, 6)


def radiator_and_grille(b):
    """Tevile orizontale de sub grila si grila alba verticala."""
    for z in (0.34, 0.48, 0.62):
        rod(b, (-0.42, -1.40, z), (0.42, -1.40, z), 0.05, DARK, 6)
    # grila: inel alb in jurul unei grile negre
    b.box((0.0, -1.55, 0.64), (0.66, 0.08, 0.88), FOAM_WHITE)
    b.box((0.0, -1.598, 0.64), (0.48, 0.04, 0.70), DARK)
    for sx in (-1, 1):
        x = sx * 0.43
        lamp_head_round((x, -1.585, 0.50), 0.10, 0.08, segments=10)
        b.cylinder((x, -1.55, 0.50), 0.115, 0.07, DARK, segments=10, axis="Y")
        rod(b, (x, -1.50, 0.50), (x * 0.95, -1.28, 0.50), 0.035, DARK, 6)


def engine(b):
    """Bloc V8 aproape negru, chiulase in V, suflanta gri cu priza."""
    b.box((0.0, -0.82, 0.62), (0.92, 1.00, 0.42), DARK)
    for sx in (-1, 1):
        # chiulase: doua blocuri inclinate in V
        b.box((sx * 0.29, -0.82, 0.96), (0.34, 0.92, 0.24), DARK, rotation=ry(sx * 14.0))
        # capace/colectoare pe laterala (cilindri la vedere)
        for y in (-1.12, -0.92, -0.72, -0.52):
            b.box((sx * 0.50, y, 0.60), (0.12, 0.14, 0.24), DARK)
    # carter / baza suflantei
    b.box((0.0, -0.92, 1.10), (0.46, 0.50, 0.14), DARK)
    # suflanta: bloc gri mare cu gura de priza spre fata
    b.box((0.0, -0.90, 1.27), (0.64, 0.70, 0.30), GREY)
    b.box((0.0, -1.255, 1.28), (0.46, 0.06, 0.16), DARK)
    b.box((0.0, -0.90, 1.43), (0.52, 0.60, 0.04), GREY)


def exhausts(b):
    """Doua tevi groase pe fiecare parte, din motor spre spate, cu cot."""
    for sx in (-1, 1):
        for z_end, x_out, z_start in ((0.36, 0.72, 0.52), (0.52, 0.72, 0.68)):
            pts = [(sx * 0.52, -1.10, z_start), (sx * 0.64, -0.92, z_start),
                   (sx * x_out, -0.74, z_start - 0.02),
                   (sx * x_out, -0.46, z_end + 0.02), (sx * x_out, -0.30, z_end),
                   (sx * x_out, 0.62, z_end)]
            tube(b, pts, slot=GREY, r=0.065, fillet=0.20, segments=8)
            b.cylinder((sx * x_out, 0.625, z_end), 0.045, 0.04, DARK, segments=8, axis="Y")


def hoop(b):
    pts = [(0.52, 1.02, 0.88), (0.52, 1.02, 1.22), (-0.52, 1.02, 1.22), (-0.52, 1.02, 0.88)]
    tube(b, pts, r=0.095, fillet=0.20, segments=8)


def interior(b):
    sx_, sy, sz = SEAT
    for x in (SEAT[0], -SEAT[0]):
        b.box((x, sy + 0.02, sz - 0.07), (0.50, 0.54, 0.14), SEAT_SLOT)
        b.box((x, sy + 0.30, sz + 0.34), (0.50, 0.12, 0.72), SEAT_SLOT, rotation=rx(-10.0))
        for s in (-1, 1):
            b.box((x + s * 0.26, sy + 0.14, sz + 0.10), (0.06, 0.40, 0.24), SEAT_SLOT)
        b.box((x, sy - 0.05, 0.30), (0.46, 0.80, 0.34), DARK)   # bloc picioare: ascunde pantofii (z 0.11)
    steering_wheel(b, SEAT, col_base=(SEAT[0], -0.26, 0.98))


def hotrod(b):
    tub(b)
    tail(b)
    underbody(b)
    radiator_and_grille(b)
    engine(b)
    exhausts(b)
    hoop(b)
    interior(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "HotRod", hotrod,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             half_track_rear=HALF_TRACK_REAR,
             radius_rear=WHEEL_R_REAR, width_rear=WHEEL_W_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/hotrod.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("hotrod", objs, SEAT, length=4.0)
