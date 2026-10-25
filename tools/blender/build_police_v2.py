"""Police Interceptor v2 — masina 3/10 a garajului v2 (cea cu grip), dupa foaia
docs/asset_briefs/img/vehicles/concept_police.jpeg (garaj_prompturi_chatgpt.md §2.3).

  vehicles/police_v2.glb   Body + 2 lampi + 4 roti (contractul din toy_driver_parts.py)

Caroserie alba din loft-uri (bot cu panta, cuva deschisa, portbagaj plat),
capota albastra bloc, banda albastra jos, bara de impingere neagra, arc cu rampa
de girofaruri rosu/alb/albastru. Abatere de la 1.35 m din prompt: figurina are
1.25 m de la sezut la casca, deci rampa (in spatele capului) ajunge ~1.8 m.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_police_v2.py
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

WHITE = FOAM_WHITE
BLUE = CAR_BLUE
DARK = VOLCANIC_BLACK
SEAT_SLOT = LOG_DARK

WHEEL_R = 0.37
WHEEL_W = 0.34
HALF_TRACK = 0.78              # 1.56 + 0.34 = 1.90 peste roti
Y_FRONT = -1.28
Y_REAR = 1.30
SEAT = (0.40, 0.25, 0.64)      # picioarele coboara la z=0.23, in placa cuvei
NOSE = 1.96                    # capetele corpului alb (bara adauga ~0.12)


def _clamp01(t):
    return max(0.0, min(1.0, t))


def bulge(y):
    """1 in dreptul unei axe (aripa bombata + arc ridicat), 0 intre axe."""
    d = min(abs(y - Y_FRONT), abs(y - Y_REAR))
    return _clamp01((0.72 - d) / 0.27)


def top_z(y):
    """Linia de sus a corpului: capota coboara spre bot, restul e plat."""
    if y < -0.55:
        return 0.78 + (0.88 - 0.78) * _clamp01((y + NOSE) / (NOSE - 0.55))
    if y < 1.70:
        return 0.92 if y < 1.05 else 0.90
    return 0.90 - 0.02 * _clamp01((y - 1.70) / 0.26)


def station(y):
    """(hw, zt, zb) la cota y: mai lat si mai inalt la roti, arcul ridica
    marginea de jos, capetele se ingusteaza."""
    bg = bulge(y)
    taper = _clamp01((abs(y) - 1.45) / 0.51)
    hw = 0.90 + 0.04 * bg - 0.06 * taper
    zt = top_z(y)
    zb = 0.30 + 0.51 * bg
    return hw, zt, zb


def drop(y):
    """Cat coboara umarul tesit; in dreptul rotii aproape deloc, ca roata sa nu iasa prin el."""
    return 0.12 - 0.12 * bulge(y)


def _ys(a, bb, n):
    return [a + (bb - a) * i / n for i in range(n + 1)]


def solid_sec(y):
    hw, zt, zb = station(y)
    zf = zt + (0.92 - zt) * bulge(y)       # aripa urca peste roata
    return mirror_poly([(0.58, zt), (hw - 0.22, zf), (hw, zf - drop(y)),
                        (hw, zb + 0.08), (hw - 0.10, zb)])


def cockpit_sec(y):
    hw, zt, zb = station(y)
    right = [(0.68, zt), (hw - 0.10, zt), (hw, zt - 0.5 * drop(y)),
             (hw, zb + 0.08), (hw - 0.10, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    return poly + [(-0.68, 0.44), (0.68, 0.44)]


def body_shell(b):
    loft(b, [(y, solid_sec(y)) for y in _ys(-NOSE, -0.55, 20)], WHITE)
    loft(b, [(y, cockpit_sec(y)) for y in _ys(-0.55, 1.05, 22)], WHITE)
    loft(b, [(y, solid_sec(y)) for y in _ys(1.05, NOSE, 13)], WHITE)
    # sasiu: sub corp si praguri negre intre roti
    b.box((0.0, 0.0, 0.28), (1.20, 3.7, 0.12), DARK)
    for sx in (-1, 1):
        b.box((sx * 0.84, 0.0, 0.29), (0.18, 1.34, 0.14), DARK)
    # capota albastra, bloc (fete peste loft)
    hood = []
    for y in _ys(-1.93, -0.57, 8):
        t = (y + 1.93) / 1.36
        hw = 0.40 + 0.16 * t
        zt = top_z(y) + 0.025
        hood.append((y, mirror_poly([(hw - 0.08, zt), (hw, zt - 0.06), (hw, zt - 0.14)])))
    loft(b, hood, BLUE)
    # banda albastra jos pe laturi, intre arcuri (loft subtire pe flanc)
    for sx in (-1, 1):
        band = []
        for y in _ys(-0.70, 0.70, 10):
            hw = station(y)[0] + 0.018
            band.append((y, [(sx * hw, 0.60), (sx * hw, 0.32),
                             (sx * (hw - 0.07), 0.32), (sx * (hw - 0.07), 0.60)][::sx]))
        loft(b, band, BLUE)


def front_end(b):
    # bara neagra groasa + grila
    b.box((0.0, -1.97, 0.36), (1.86, 0.25, 0.28), DARK)
    b.box((0.0, -1.98, 0.54), (0.74, 0.06, 0.30), DARK)
    for sx in (-1, 1):
        lamp_head((sx * 0.66, -1.975, 0.56), (0.30, 0.06, 0.28), ICE_TURQUOISE)
        # bara de impingere: stalpi verticali + traverse
        b.box((sx * 0.40, -2.04, 0.62), (0.13, 0.12, 0.56), DARK)
    b.box((0.0, -2.04, 0.84), (0.93, 0.12, 0.10), DARK)
    b.box((0.0, -2.04, 0.48), (0.93, 0.12, 0.10), DARK)


def rear_end(b):
    b.box((0.0, 1.96, 0.36), (1.86, 0.25, 0.28), DARK)
    for sx in (-1, 1):
        lamp_tail((sx * 0.62, 1.965, 0.66), (0.30, 0.06, 0.16))


def windshield(b, tilt=32.0, length=0.36, half=0.70, base=(-0.66, 0.92), th=0.0175):
    """Pana joasa, lata, inclinata `tilt` grade de la verticala spre spate,
    fara rama, cu colturile de sus tesite (poligon construit direct)."""
    t = math.radians(tilt)
    d = Vector((0.0, math.sin(t), math.cos(t)))         # in sus pe panta
    n = Vector((0.0, math.cos(t), -math.sin(t)))        # normala panoului
    o = Vector((0.0, base[0], base[1]))
    poly = [(-half, 0.0), (half, 0.0), (half, length - 0.10),
            (half - 0.10, length), (-half + 0.10, length), (-half, length - 0.10)]
    rings = []
    verts = []
    for sgn in (-1, 1):
        ring = [b.bm.verts.new(tuple(o + Vector((u, 0, 0)) + d * v + n * (sgn * th)))
                for u, v in poly]
        rings.append(ring)
        verts.extend(ring)
    k = len(poly)
    for i in range(k):
        j = (i + 1) % k
        b.bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
    caps = [b.bm.faces.new(tuple(reversed(rings[0]))), b.bm.faces.new(tuple(rings[1]))]
    bmesh.ops.triangulate(b.bm, faces=caps, quad_method="BEAUTY", ngon_method="BEAUTY")
    return b._tag(verts, ICE_TURQUOISE)


def hoop_and_bar(b):
    tube(b, [(0.78, 0.84, 0.86), (0.76, 0.84, 1.52), (-0.76, 0.84, 1.52),
             (-0.78, 0.84, 0.86)], r=0.07, fillet=0.16, segments=8)
    b.box((0.0, 0.84, 1.59), (1.40, 0.22, 0.08), DARK)
    zc, h = 1.71, 0.22
    b.box((-0.46, 0.84, zc), (0.46, 0.26, h), CAR_RED)
    b.box((0.0, 0.84, zc), (0.28, 0.26, h), WHITE)
    b.box((0.46, 0.84, zc), (0.46, 0.26, h), BLUE)


def interior(b):
    sx0, sy, sz = SEAT
    for s in (1, -1):
        x = s * sx0
        b.box((x, sy + 0.02, sz - 0.05), (0.52, 0.56, 0.10), SEAT_SLOT)
        b.box((x, sy + 0.32, sz + 0.34), (0.50, 0.12, 0.76), SEAT_SLOT, rotation=rx(-10.0))
        for t in (-1, 1):
            b.box((x + t * 0.27, sy + 0.14, sz + 0.10), (0.06, 0.40, 0.28), SEAT_SLOT)
    b.box((0.0, 0.10, 0.62), (0.18, 0.80, 0.30), DARK)    # consola
    steering_wheel(b, SEAT)


def police(b):
    body_shell(b)
    front_end(b)
    rear_end(b)
    windshield(b)
    hoop_and_bar(b)
    interior(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Interceptor", police,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/police_v2.glb", SEAT, bevel=0.03, bevel_angle=65.0)
    preview_sheet("police_v2", objs, SEAT, shirt=CAR_RED, length=4.2)
