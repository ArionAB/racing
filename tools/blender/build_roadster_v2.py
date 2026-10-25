"""Muscle Roadster v2 — masina 2/10 a garajului v2 ("cea rapida"), dupa foaia
docs/asset_briefs/img/vehicles/concept_muscle.jpeg (prompt: garaj_prompturi_chatgpt.md §2.2).

  Roadster   vehicles/roadster_v2.glb
             Body + 2 lampi + 4 roti ca noduri separate (contractul din
             toy_driver_parts.py).

Forma: UN SINGUR loft pentru caroserie, cu sectiuni (x, z) la cote y. Parametrii
sectiunii (latime, cota de sus, cota de jos, cuva cockpitului, arcurile de roata)
sunt tabele liniare pe portiuni, iar statiile se aleg ca reuniunea nodurilor
tuturor tabelelor — arcul rotii e taiat in loft ridicand cota de jos a peretelui
exterior in jurul fiecarei roti. Dungile albe sunt loft-uri subtiri care urmaresc
profilul de sus (capota, priza, portbagaj).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_roadster_v2.py
Verificare:
    python tools/blender/verify_glb.py assets/models/vehicles/roadster_v2.glb 6500 --origin=assembly
Plansa: python tools/blender/compare_concept.py roadster_v2 concept_muscle.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

PAINT = CAR_RED
STRIPE_SLOT = FOAM_WHITE
DARK = VOLCANIC_BLACK
SEAT_SLOT = LOG_DARK
GLASS = ICE_TURQUOISE

# --- contract (garaj_prompturi_chatgpt.md §2.2) ------------------------------
WHEEL_R = 0.38                 # FIZICA: nu se schimba
WHEEL_W = 0.36
HALF_TRACK = 0.78              # 2*0.78 + 0.36 = 1.92 peste roti
Y_FRONT = -1.35
Y_REAR = 1.25                  # ampatament 2.60
SEAT = (0.42, 0.22, 0.58)      # soferul pe stanga (+X); locul din dreapta gol
ARCH_R = 0.45                  # raza arcului in jurul rotii (roata 0.38)
Z_SILL = 0.27                  # fata de jos a caroseriei
Z_FLOOR = 0.46                 # podeaua cockpitului
HOOP_Y = 0.76
HOOP_TOP = 1.60   # arcul sta IN SPATELE scaunelor, sub nivelul castii (1.83)


def interp(table, y):
    """Interpolare liniara pe portiuni; tabelul e [(y, valoare), ...] sortat."""
    if y <= table[0][0]:
        return table[0][1]
    for (y0, v0), (y1, v1) in zip(table, table[1:]):
        if y <= y1:
            t = (y - y0) / (y1 - y0) if y1 > y0 else 0.0
            return v0 + (v1 - v0) * t
    return table[-1][1]


# (y, valoare): fata = -Y
HW = [(-2.00, 0.88), (-1.80, 0.95), (-1.35, 0.97), (-1.00, 0.91), (-0.80, 0.86),
      (0.70, 0.84), (0.78, 0.90), (1.25, 0.99), (1.80, 0.98), (2.00, 0.92)]
ZT = [(-2.00, 0.76), (-1.80, 0.90), (-1.35, 0.97), (-1.00, 0.94), (-0.84, 0.95), (-0.76, 0.88),
      (0.72, 0.88), (0.78, 0.95), (1.25, 1.02), (1.80, 0.98), (1.88, 0.97), (1.91, 1.02),
      (2.00, 1.02)]
ZS = [(-2.00, 0.40), (-1.85, Z_SILL), (2.00, Z_SILL)]
# 0 = capota/portbagaj (plin), 1 = cuva cockpitului; rampele sunt abrupte
COCKPIT = [(-2.00, 0.0), (-0.86, 0.0), (-0.76, 1.0), (0.72, 1.0), (0.78, 0.0), (2.00, 0.0)]
SCOOP = [(-1.64, 0.0), (-1.52, 0.12), (-1.06, 0.12), (-0.98, 0.0)]

ARCH_DY = (0.0, 0.12, 0.22, 0.31, 0.38, 0.42, 0.45, 0.50)


def arch_z(y):
    """Cota de jos a peretelui exterior: ridicata peste fiecare roata."""
    z = Z_SILL
    for wy in (Y_FRONT, Y_REAR):
        dy = abs(y - wy)
        if dy < ARCH_R:
            z = max(z, WHEEL_R + math.sqrt(ARCH_R ** 2 - dy ** 2))
    return z


def stations():
    ys = set()
    for tab in (HW, ZT, ZS, COCKPIT):
        ys.update(round(p[0], 3) for p in tab)
    for wy in (Y_FRONT, Y_REAR):
        for d in ARCH_DY:
            ys.add(round(wy + d, 3))
            ys.add(round(wy - d, 3))
    return sorted(ys)


def section(y):
    hw = interp(HW, y)
    zt = interp(ZT, y)
    zs = interp(ZS, y)
    k = interp(COCKPIT, y)
    xi = 0.10 + 0.58 * k
    zf = (zt - 0.02) * (1.0 - k) + Z_FLOOR * k
    za = max(zs, arch_z(y))
    # sub arc, peretele exterior se opreste deasupra arcului; interiorul coboara
    xa = 0.57
    za = min(za, zt - 0.06)
    right = [(xi, zt), (hw - 0.04, zt), (hw, zt - 0.08), (hw, za), (xa, za), (xa, zs)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    return poly + [(-xi, zf), (xi, zf)]


# =============================================================================
# Corpul
# =============================================================================
def shell(b):
    ys = [y for y in stations() if -2.0 <= y <= 2.0]
    loft(b, [(y, section(y)) for y in ys], PAINT)


def stripe_sections(xc, w, y0, y1, extra=()):
    ys = {round(p[0], 3) for tab in (ZT, SCOOP) for p in tab if y0 <= p[0] <= y1}
    ys.update((y0, y1))
    ys.update(round(e, 3) for e in extra)
    out = []
    for y in sorted(ys):
        z = interp(ZT, y) + interp(SCOOP, y) + 0.012
        out.append((y, [(xc + w * 0.5, z), (xc + w * 0.5, z - 0.03),
                        (xc - w * 0.5, z - 0.03), (xc - w * 0.5, z)]))
    return out


def stripes(b):
    """Doua dungi albe late (~25 cm) peste capota, priza si portbagaj."""
    for sx in (-1, 1):
        loft(b, stripe_sections(sx * 0.33, 0.25, -2.0, -0.86), STRIPE_SLOT)
        loft(b, stripe_sections(sx * 0.33, 0.25, 0.78, 2.0), STRIPE_SLOT)


def scoop(b):
    """Priza de aer de pe capota: un bloc, fata abrupta, spatele care coboara."""
    secs = []
    for y in sorted({p[0] for p in SCOOP}):
        zt = interp(ZT, y)
        h = interp(SCOOP, y)
        hw = 0.50 if h > 0.0 else 0.46
        secs.append((y, [(hw, zt + h), (hw, zt - 0.03), (-hw, zt - 0.03), (-hw, zt + h)]))
    loft(b, secs, PAINT)


def front_end(b):
    """Bot lat: grila neagra, doua faruri dreptunghiulare, bara groasa."""
    b.box((0.0, -2.012, 0.58), (1.04, 0.06, 0.28), DARK)
    for sx in (-1, 1):
        lamp_head((sx * 0.69, -2.012, 0.60), (0.24, 0.06, 0.22))
    b.box((0.0, -2.05, 0.40), (1.86, 0.14, 0.18), DARK)
    for sx in (-1, 1):
        b.box((sx * 0.90, -1.93, 0.40), (0.14, 0.30, 0.18), DARK)
        b.box((sx * 0.90, 1.93, 0.40), (0.14, 0.30, 0.18), DARK)
    b.box((0.0, -1.98, 0.28), (1.0, 0.10, 0.10), DARK)       # spoiler fata, buza joasa


def rear_end(b):
    b.box((0.0, 2.05, 0.40), (1.86, 0.14, 0.18), DARK)
    for sx in (-1, 1):
        lamp_tail((sx * 0.62, 2.015, 0.72), (0.30, 0.06, 0.16))
        b.cylinder((sx * 0.38, 2.08, 0.24), 0.05, 0.12, RIM, segments=8, axis="Y")


def underbody(b):
    """Tava neagra intre roti (si ascunde pantofii figurinei)."""
    b.box((0.0, 0.20, 0.22), (1.10, 1.30, 0.10), DARK)


def windscreen(b):
    """Parbriz scurt, bloc turcoaz inclinat, cu aripi care invaluie spre coaming."""
    b.box((0.0, -0.74, 1.04), (1.62, 0.10, 0.34), GLASS, rotation=rx(-28.0))
    for sx in (-1, 1):
        b.box((sx * 0.84, -0.66, 1.00), (0.06, 0.36, 0.24), GLASS,
              rotation=rz(sx * 22.0) @ rx(-28.0))
    b.box((0.0, -0.84, 0.96), (1.70, 0.10, 0.08), DARK)       # rama de jos


def hoop(b):
    """Un singur arc gros in spatele scaunelor."""
    pts = [(0.80, HOOP_Y, 0.86), (0.78, HOOP_Y, HOOP_TOP), (-0.78, HOOP_Y, HOOP_TOP),
           (-0.80, HOOP_Y, 0.86)]
    tube(b, pts, r=0.07, fillet=0.18)


def interior(b):
    sx_, sy, sz = SEAT
    for x in (SEAT[0], -SEAT[0]):
        b.box((x, sy + 0.02, sz - 0.07), (0.56, 0.56, 0.14), SEAT_SLOT)
        b.box((x, sy + 0.34, sz + 0.34), (0.56, 0.12, 0.72), SEAT_SLOT,
              rotation=rx(-10.0))
        b.box((x, sy + 0.40, sz + 0.78), (0.34, 0.14, 0.22), SEAT_SLOT)  # tetiera
        for s in (-1, 1):
            b.box((x + s * 0.30, sy + 0.14, sz + 0.12), (0.08, 0.40, 0.28), SEAT_SLOT)
    b.box((0.0, sy + 0.20, sz - 0.02), (0.20, 0.90, 0.22), DARK)        # tunel
    b.box((0.0, -0.70, 0.84), (1.46, 0.20, 0.10), DARK)                 # bord
    steering_wheel(b, SEAT, col_base=(SEAT[0], -0.76, 0.88))


def roadster(b):
    shell(b)
    stripes(b)
    scoop(b)
    front_end(b)
    rear_end(b)
    underbody(b)
    windscreen(b)
    hoop(b)
    interior(b)


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Roadster", roadster,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_factory=toy_wheel_fn, wheel_bevel=0.0),
        "vehicles/roadster_v2.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    preview_sheet("roadster_v2", objs, SEAT, length=4.2)
