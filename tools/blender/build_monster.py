"""Monster truck — masina 10/10 a garajului v2, dupa foaia
docs/asset_briefs/img/vehicles/concept_monstertruck.jpeg (prompt: §2.10).

  Monster   vehicles/monster.glb
            Body + 2 lampi + 4 roti ca noduri separate (contractul din
            toy_driver_parts.py).

Rotile SUNT masina: patru anvelope uriase (R 0.62, l 0.55), mai inalte decat
podeaua cabinei, pe un cadru-scara aproape negru cu punti groase si amortizoare
cu arc la vedere. Sus, o cabina rosie deschisa de pickup (un singur loc, pe
mijloc), cusca completa peste sofer si o bena scurta cu interior maro.

Cote contract: 4.4 lung x 2.6 lat peste roti x ~2.4 la cusca; garda sub cadru
~0.75. Foaia e mult mai lata/stufoasa decat contractul — cotele vin din
contract, proportiile din foaie.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monster.py
Verificare:
    python tools/blender/verify_glb.py assets/models/vehicles/monster.glb 6500 --origin=assembly
Plansa:
    python tools/blender/compare_concept.py monster concept_monstertruck.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = CAR_RED
DARK = VOLCANIC_BLACK
WHITE = FOAM_WHITE
SEAT_SLOT = LOG_DARK

# --- contract ---------------------------------------------------------------
WHEEL_R = 0.62
WHEEL_W = 0.55
HALF_TRACK = 1.025             # 2.6 peste roti: 1.025 + 0.275
Y_FRONT = -1.45
Y_REAR = 1.45
SEAT = (0.0, -0.05, 1.10)      # pe mijloc; picioarele coboara 0.41 sub sezut
TOP = 2.46                     # axa tubului de acoperis: casca (2.35) + 5.5 cm

RAIL_Z = 0.865                 # longeron inalt: 0.75 .. 0.98 (garda 0.75)
FLOOR_ZB = 0.92                # fundul corpului (sta pe longeroane)
CAB_FLOOR = 1.00               # podeaua cabinei = jos de cusion (SEAT.z - 0.10)
BED_FLOOR = 1.22
CAB_TOP = 1.52
BED_TOP = 1.54
HOOD_TOP = 1.58

# Rotile dau lungimea (y -2.07..2.07); caroseria sta cuibarita intre ele.
Y_CAB0, Y_CAB1 = -0.80, 0.35   # cabina
Y_BED1 = 1.65                  # capatul benei
Y_NOSE = -1.65                 # botul capotei
Y_BAR = -2.00                  # bara de impingere: cel mult muchia anvelopei
HW = 0.72                      # jumatate din latimea capotei/benei (< fata interioara 0.75)
HW_CAB = 0.74


def rzm(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


# =============================================================================
# Caroseria (loft)
# =============================================================================
def hood(b):
    """Capota + aripile fata, un singur solid cu botul rotunjit."""
    st = [  # (y, jumatate de latime, z jos, z sus, tesitura)
        (Y_NOSE, 0.50, 0.98, 1.40, 0.10),
        (Y_NOSE + 0.14, 0.62, 0.94, 1.52, 0.10),
        (-1.20, HW, FLOOR_ZB, HOOD_TOP, 0.08),
        (Y_CAB0, HW, FLOOR_ZB, HOOD_TOP, 0.08),
    ]
    sec = []
    for y, hw, zb, zt, c in st:
        sec.append((y, mirror_poly([(hw - c, zt), (hw, zt - c), (hw, zb + 0.08),
                                    (hw - 0.10, zb)])))
    loft(b, sec, PAINT)


def cab(b):
    """Cabina deschisa: cuva in U, podea la nivelul sezutului."""
    st = [(Y_CAB0, HW, CAB_TOP, FLOOR_ZB, CAB_FLOOR),
          (-0.20, HW_CAB, CAB_TOP, FLOOR_ZB, CAB_FLOOR),
          (Y_CAB1, HW, CAB_TOP, FLOOR_ZB, CAB_FLOOR)]
    loft(b, [(y, u_section(hw, zt, zb, zf, wall=0.13)) for y, hw, zt, zb, zf in st],
         PAINT)
    b.box((0.0, (Y_CAB0 + Y_CAB1) * 0.5 + 0.05, CAB_FLOOR + 0.012),
          (1.00, Y_CAB1 - Y_CAB0 - 0.28, 0.025), SEAT_SLOT)


def bed(b):
    """Bena scurta: cuva in U, podea ridicata (interior maro), banda alba."""
    st = [(Y_CAB1, HW, BED_TOP, FLOOR_ZB, BED_FLOOR),
          (1.00, HW, BED_TOP, FLOOR_ZB, BED_FLOOR),
          (Y_BED1 - 0.08, HW, BED_TOP, FLOOR_ZB + 0.04, BED_FLOOR),
          (Y_BED1, HW - 0.04, BED_TOP, FLOOR_ZB + 0.10, BED_FLOOR)]
    loft(b, [(y, u_section(hw, zt, zb, zf, wall=0.14)) for y, hw, zt, zb, zf in st],
         PAINT)
    b.box((0.0, (Y_CAB1 + Y_BED1) * 0.5 + 0.06, BED_FLOOR + 0.012),
          (1.10, Y_BED1 - Y_CAB1 - 0.36, 0.025), SEAT_SLOT)
    for sx in (-1, 1):
        b.box((sx * (HW - 0.005), 1.00, 1.36), (0.04, 1.00, 0.24), WHITE)


def chevron(b):
    """Chevronul alb de pe capota: varful spre bot (-Y), bratele inapoi."""
    z = HOOD_TOP + 0.012
    for sx in (-1, 1):
        c = (sx * 0.23, -1.27, z)
        b.box(c, (0.17, 0.66, 0.024), WHITE, rotation=rzm(-sx * 45.0))


def windscreen(b):
    """Parbriz scurt turcoaz, inclinat, fara rama groasa."""
    b.box((0.0, Y_CAB0 + 0.02, HOOD_TOP + 0.15), (1.10, 0.035, 0.34), ICE_TURQUOISE,
          rotation=rx(-55.0))
    b.box((0.0, Y_CAB0 + 0.12, CAB_TOP - 0.02), (1.10, 0.20, 0.10), DARK)   # bord


# =============================================================================
# Fata: bara de impingere + faruri
# =============================================================================
def nudge_bar(b):
    b.box((0.0, -1.80, 1.22), (1.20, 0.30, 0.42), DARK)       # bloc negru cu farurile
    for sx in (-1, 1):
        x = sx * 0.37
        lamp_head_round((x, Y_BAR + 0.04, 1.22), 0.15, 0.08, segments=8)
        b.cylinder((x, Y_BAR + 0.075, 1.22), 0.18, 0.06, DARK, segments=8, axis="Y")
    yb = Y_BAR
    tube(b, [(0.50, -1.55, 0.98), (0.72, yb, 0.98), (0.72, yb, 1.56),
             (-0.72, yb, 1.56), (-0.72, yb, 0.98), (-0.50, -1.55, 0.98)],
         r=0.068, fillet=0.16, segments=6)
    tube(b, [(0.72, yb, 0.98), (-0.72, yb, 0.98)], r=0.068, segments=6)


def rear(b):
    b.box((0.0, Y_BED1 + 0.10, 1.00), (1.30, 0.12, 0.20), DARK)
    for sx in (-1, 1):
        lamp_tail((sx * 0.48, Y_BED1 + 0.025, 1.38), (0.14, 0.05, 0.18))


# =============================================================================
# Cusca completa
# =============================================================================
def cage(b):
    R = 0.055
    for sx in (-1, 1):
        tube(b, [(sx * 0.62, Y_CAB0 + 0.04, CAB_TOP - 0.05), (sx * 0.52, -0.50, TOP),
                 (sx * 0.52, 0.30, TOP), (sx * 0.62, 0.40, CAB_TOP)],
             r=R, fillet=0.20, segments=6)
        tube(b, [(sx * 0.52, 0.30, TOP), (sx * 0.58, 0.95, 1.80),
                 (sx * 0.64, 1.30, BED_TOP)], r=R, fillet=0.20, segments=6)
        tube(b, [(sx * 0.65, -0.45, CAB_TOP), (sx * 0.65, -0.45, 2.00),
                 (sx * 0.65, 0.40, 2.00), (sx * 0.65, 0.40, CAB_TOP)],
             r=0.04, fillet=0.10)
    tube(b, [(0.52, -0.50, TOP), (-0.52, -0.50, TOP)], r=R)
    tube(b, [(0.52, 0.30, TOP), (-0.52, 0.30, TOP)], r=R)
    tube(b, [(0.60, 0.95, 1.80), (-0.60, 0.95, 1.80)], r=0.045)
    tube(b, [(0.65, 0.40, 2.00), (-0.65, 0.40, 2.00)], r=0.04)
    tube(b, [(0.52, 0.33, 2.38), (-0.62, 0.40, 1.62)], r=0.04)


# =============================================================================
# Cadrul, puntile, suspensia
# =============================================================================
def frame(b):
    for sx in (-1, 1):
        b.box((sx * 0.40, 0.0, RAIL_Z), (0.16, 3.70, 0.23), DARK)
    for y in (-1.75, -1.00, 0.45, 1.00, 1.75):
        b.box((0.0, y, RAIL_Z + 0.005), (0.90, 0.14, 0.14), DARK)
    # traversa sub podeaua cabinei: ascunde pantofii soferului (coboara 0.41
    # sub sezut), ramane sub podea
    b.box((0.0, SEAT[1] - 0.53, 0.78), (0.90, 0.46, 0.40), DARK)


def axles_and_suspension(b):
    for y0 in (Y_FRONT, Y_REAR):
        s = 1 if y0 < 0 else -1          # spre centru masinii
        rod(b, (-0.78, y0, WHEEL_R), (0.78, y0, WHEEL_R), 0.095, DARK, 6)
        b.box((0.0, y0, WHEEL_R + 0.02), (0.36, 0.40, 0.34), DARK)
        for sx in (-1, 1):
            b.box((sx * 0.72, y0, WHEEL_R), (0.14, 0.22, 0.30), DARK)       # fuzeta
            bot = Vector((sx * 0.66, y0 + 0.02, 0.70))
            top = Vector((sx * 0.58, y0 + 0.02, 1.12))
            rod(b, tuple(bot), tuple(top), 0.04, DARK, 6)
            axis = (top - bot)
            for t in (0.30, 0.60):
                c = bot + axis * t
                rod(b, tuple(c - axis.normalized() * 0.045),
                    tuple(c + axis.normalized() * 0.045), 0.085, DARK, 6)
            # doua diagonale groase: de la butuc spre cadru, ca in foaie
            rod(b, (sx * 0.42, y0, WHEEL_R - 0.03),
                (sx * 0.42, y0 + s * 1.15, RAIL_Z + 0.02), 0.06, DARK, 6)
            rod(b, (sx * 0.52, y0 + s * 0.05, WHEEL_R + 0.10),
                (sx * 0.46, y0 + s * 0.85, RAIL_Z - 0.08), 0.055, DARK, 6)


def seat_and_wheel(b):
    sx_, sy, sz = SEAT
    b.box((0.0, sy + 0.02, sz - 0.05), (0.58, 0.56, 0.10), SEAT_SLOT)
    b.box((0.0, sy + 0.32, sz + 0.36), (0.58, 0.12, 0.76), SEAT_SLOT, rotation=rx(-12.0))
    for s in (-1, 1):
        b.box((s * 0.30, sy + 0.16, sz + 0.12), (0.08, 0.40, 0.30), SEAT_SLOT)
    col_top = (0.0, sy - 0.48, sz + 0.52)
    b.beam((0.0, Y_CAB0 + 0.18, CAB_TOP - 0.08), col_top, 0.05, DARK)
    b.torus(col_top, 0.24, 0.035, DARK, major_seg=12, minor_seg=5, axis="Y")


def monster(b):
    hood(b)
    cab(b)
    bed(b)
    chevron(b)
    windscreen(b)
    nudge_bar(b)
    rear(b)
    cage(b)
    frame(b)
    axles_and_suspension(b)
    seat_and_wheel(b)


def wheel_factory(radius, width):
    return toy_wheel_fn(radius, width, segments=18, hub_frac=0.52)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Monster", monster,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=wheel_factory, wheel_bevel=0.0),
        "vehicles/monster.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("monster", objs, SEAT, shirt=CAR_YELLOW, length=4.4)
