"""Fiordland - Vehicule, kit v2 (grupa E, docs/asset_briefs/fiordland_kit_v2.md).

  fiordland/vehicles/coach_fiordland.glb       autocarul din tunelul Homer (TunnelSignalHazard)
  fiordland/vehicles/bush_plane.glb            monomotor (PathMover, aer)
  fiordland/vehicles/cruise_boat_builder.glb   CANDIDAT Builder pentru vaporas (in joc ramane reuse-ul)
  fiordland/props/kayak_a.glb                  caiac rosu-portocaliu
  fiordland/props/kayak_b.glb                  caiac galben

v2: fidelitate fata de plansa. Siluete din bucle (loft) cu sectiuni
eliptice/poligonale, nu din cutii:
  - coach: profil YZ extrudat CU pasaje de roata taiate in contur, roti cu
    jante in pasaje, banda de geamuri neagra cu montanti, parbriz inclinat,
    acoperis alb cu aer conditionat, faruri.
  - plane: fuzelaj loft eliptic, aripa sus pe montanti (plan trapezoidal),
    coada cu deriva rosie, tren fix cu carenaje, elice cu 2 pale.
  - caiace: bucla cu curbura de bordaj (sheer) si rocker, 2 cockpituri.
  - cruise_boat_builder: carena cu evazare, doua punti, geamuri in sir,
    punte deschisa cu balustrada si banci, platforma de lemn la pupa.

COACH: cotele SUNT contractul de gameplay (TunnelSignalHazard / BusHazard iau
AABB-ul din model): nu depasi 3.06 x 3.29 x 8.66 (Godot X x Y x Z).

AXE: inainte = -Z Godot = +Y Blender.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_vehicles.py
"""

import bmesh
import math
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (zero sloturi noi).
BODY = FOAM_WHITE
GREEN = CACTUS_GREEN
DARK = VOLCANIC_BLACK
TIRE = ASPHALT
RIM = CONCRETE
DECK = WOOD
LIGHT_GREY = MARBLE_GREY

AO_VEHICLE = dict(samples=22, dist=1.8, gradient="vertical",
                  low=0.60, high=1.0, power=0.9, floor=0.22)


# --- ajutoare de forma -------------------------------------------------------

def _tag_face(b, f, slot):
    f[b.slot] = slot
    return f


def loft_pts(b, stations, slot, cap_start=True, cap_end=True, slot_fn=None):
    """Bucla de-a lungul lui Y. `stations` = lista de (y, [(x, z), ...]) cu
    ACELASI numar de puncte per sectiune. slot_fn(i, k) -> slot sau None, cu
    i = intervalul dintre statia i si i+1, k = latura k a sectiunii."""
    rings = []
    for y, pts in stations:
        rings.append([b.bm.verts.new((x, y, z)) for x, z in pts])
    faces = set()
    n = len(rings[0])
    for i, (lo, hi) in enumerate(zip(rings, rings[1:])):
        for k in range(n):
            j = (k + 1) % n
            f = b.bm.faces.new((lo[k], lo[j], hi[j], hi[k]))
            s = slot_fn(i, k) if slot_fn else None
            f[b.slot] = slot if s is None else s
            faces.add(f)
    if cap_start:
        f = b.bm.faces.new(tuple(reversed(rings[0])))
        f[b.slot] = slot
        faces.add(f)
    if cap_end:
        f = b.bm.faces.new(tuple(rings[-1]))
        f[b.slot] = slot
        faces.add(f)
    return faces


def loft(b, stations, slot, n=12, slot_fn=None, cap_start=True, cap_end=True):
    """Bucla eliptica: stations = (y, rx, rz, zc[, xc])."""
    st = []
    for s in stations:
        y, rx, rz, zc = s[:4]
        xc = s[4] if len(s) > 4 else 0.0
        pts = [(xc + rx * math.cos(2 * math.pi * k / n),
                zc + rz * math.sin(2 * math.pi * k / n)) for k in range(n)]
        st.append((y, pts))
    return loft_pts(b, st, slot, cap_start, cap_end, slot_fn)


def extrude_x(b, pts_yz, t, slot, xc=0.0):
    """Profil (y, z) extrudat pe X cu grosimea t (sau (x0, x1))."""
    if isinstance(t, (tuple, list)):
        x0, x1 = t
    else:
        x0, x1 = xc - t * 0.5, xc + t * 0.5
    a = [b.bm.verts.new((x0, y, z)) for y, z in pts_yz]
    c = [b.bm.verts.new((x1, y, z)) for y, z in pts_yz]
    n = len(pts_yz)
    faces = {b.bm.faces.new(tuple(a)), b.bm.faces.new(tuple(reversed(c)))}
    for i in range(n):
        j = (i + 1) % n
        faces.add(b.bm.faces.new((a[i], a[j], c[j], c[i])))
    for f in faces:
        f[b.slot] = slot
    return faces


def planform(b, pts_xy, z0, z1, slot):
    """Plan (x, y) extrudat pe Z intre z0 si z1."""
    lo = [b.bm.verts.new((x, y, z0)) for x, y in pts_xy]
    hi = [b.bm.verts.new((x, y, z1)) for x, y in pts_xy]
    n = len(pts_xy)
    faces = {b.bm.faces.new(tuple(hi)), b.bm.faces.new(tuple(reversed(lo)))}
    for i in range(n):
        j = (i + 1) % n
        faces.add(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    for f in faces:
        f[b.slot] = slot
    return faces


def oval(b, c, rx, ry, h, slot, seg=12):
    """Cilindru oval pe Z (centru, semi-axe rx/ry, inaltime h)."""
    faces = b.cylinder(c, 1.0, h, slot, segments=seg, axis="Z")
    verts = {v for f in faces for v in f.verts}
    for v in verts:
        v.co.x = c[0] + (v.co.x - c[0]) * rx
        v.co.y = c[1] + (v.co.y - c[1]) * ry
    return faces


# --- coach_fiordland -------------------------------------------------------
#
# Contract: <= 3.06 x 3.29 x 8.66. Nod "Coach". Origine la sol, centrata.
COACH_W = 2.96
COACH_L = 8.5
COACH_H = 3.14
COACH_WHEEL_R = 0.55
COACH_WHEEL_T = 0.30
COACH_LO = 0.32               # garda la sol pana la caroserie
COACH_AXLES = (-2.05, 2.35)   # axa spate, axa fata (Y)
ARCH_R = 0.70


def build_coach():
    b = Builder()
    hw = COACH_W * 0.5
    hl = COACH_L * 0.5
    H = COACH_H

    # profilul lateral, cu pasajele de roata TAIATE in contur
    wz = COACH_WHEEL_R
    th0 = math.asin((COACH_LO - wz) / ARCH_R)       # unghi la nivelul garzii
    outline = [(-hl, COACH_LO)]
    for yc in COACH_AXLES:
        a0 = math.pi - th0
        a1 = th0
        steps = 8
        for s in range(steps + 1):
            a = a0 + (a1 - a0) * s / steps
            outline.append((yc + ARCH_R * math.cos(a), wz + ARCH_R * math.sin(a)))
    windshield_lo = 2.05
    rake = 0.62
    outline += [(hl, COACH_LO), (hl, windshield_lo), (hl - rake, H),
                (-hl + 0.12, H), (-hl, H - 0.24)]
    extrude_x(b, outline, COACH_W, GREEN)

    # peretii interiori ai pasajelor (negru): pasajul citeste ca nisa adanca
    for yc in COACH_AXLES:
        for sx in (-1.0, 1.0):
            b.box((sx * (hw - COACH_WHEEL_T - 0.04), yc, wz + 0.30),
                  (0.04, ARCH_R * 2.0 - 0.10, 1.05), DARK)

    # rotile: anvelopa + janta, in pasaj (exterior la ~hw - 0.0)
    for yc in COACH_AXLES:
        for sx in (-1.0, 1.0):
            xc = sx * (hw - COACH_WHEEL_T * 0.5 - 0.02)
            b.cylinder((xc, yc, wz), wz, COACH_WHEEL_T, TIRE, segments=14, axis="X")
            b.cylinder((sx * (hw - 0.01), yc, wz), wz * 0.58, 0.05, RIM,
                       segments=10, axis="X")
            b.cylinder((sx * (hw + 0.005), yc, wz), wz * 0.18, 0.05, DARK,
                       segments=6, axis="X")

    # banda de geamuri neagra, continua, cu montanti
    win_lo, win_hi = 1.84, 2.86
    wy0, wy1 = -3.95, 3.95
    for sx in (-1.0, 1.0):
        b.box((sx * (hw + 0.012), (wy0 + wy1) * 0.5, (win_lo + win_hi) * 0.5),
              (0.03, wy1 - wy0, win_hi - win_lo), DARK)
        # montanti (caroserie verde peste geam)
        y = wy0 + 0.55
        while y < wy1 - 0.3:
            b.box((sx * (hw + 0.02), y, (win_lo + win_hi) * 0.5),
                  (0.03, 0.13, win_hi - win_lo + 0.02), GREEN)
            y += 0.98
    # geamul din spate
    b.box((0.0, -hl - 0.012, 2.35), (COACH_W - 0.7, 0.03, 0.72), DARK)

    # bara de sub geamuri: dunga gri-deschis continua
    for sx in (-1.0, 1.0):
        b.box((sx * (hw + 0.012), -0.1, 1.70), (0.025, 8.0, 0.14), LIGHT_GREY)
        # dunga pe flanc intre pasaje, deasupra arcurilor
        b.box((sx * (hw + 0.012), 0.15, 1.38), (0.025, 2.9, 0.22), LIGHT_GREY)

    # acoperis alb: cutie peste coltul de sus (cu streasina fata de geamuri)
    b.box((0.0, -0.15, H - 0.12), (COACH_W + 0.02, COACH_L - 0.90, 0.27), BODY)

    # unitati de aer conditionat pe acoperis (nu depasesc cota)
    b.box((0.0, 1.4, H + 0.04), (1.25, 1.6, 0.09), ASPHALT_EDGE)
    b.box((0.0, -2.4, H + 0.04), (0.8, 0.9, 0.09), ASPHALT_EDGE)

    # parbriz mare inclinat
    rl = math.hypot(rake, H - windshield_lo)
    th = math.asin(rake / rl)
    mid = Vector((hl - rake * 0.5, (windshield_lo + H) * 0.5))
    n = Vector((math.cos(th), math.sin(th)))
    c = mid + n * 0.02
    b.box((0.0, c.x, c.y), (COACH_W - 0.42, 0.03, rl * 0.9), DARK,
          rotation=Matrix.Rotation(th, 3, "X"))
    # ramele laterale ale parbrizului
    for sx in (-1.0, 1.0):
        c2 = mid + n * 0.015
        b.box((sx * (COACH_W * 0.5 - 0.17), c2.x, c2.y), (0.14, 0.03, rl * 0.96), GREEN,
              rotation=Matrix.Rotation(th, 3, "X"))

    # fata: grila neagra sus, bara neagra jos, faruri mari calde
    b.box((0.0, hl + 0.012, 1.12), (1.4, 0.04, 0.55), DARK)
    b.box((0.0, hl + 0.025, COACH_LO + 0.2), (COACH_W - 0.20, 0.07, 0.30), DARK)
    for sx in (-1.0, 1.0):
        b.cylinder((sx * 1.08, hl + 0.02, 0.88), 0.18, 0.06, SAND_LIGHT,
                   segments=10, axis="Y")
        b.box((sx * 1.08, hl + 0.02, 0.58), (0.34, 0.05, 0.14), SAND_LIGHT)
    # spate: bara + stopuri
    b.box((0.0, -hl - 0.025, COACH_LO + 0.2), (COACH_W - 0.20, 0.07, 0.30), DARK)
    for sx in (-1.0, 1.0):
        b.box((sx * 1.15, -hl - 0.012, 1.0), (0.38, 0.03, 0.2), KERB_RED)

    # oglinzi
    for sx in (-1.0, 1.0):
        b.box((sx * (hw + 0.0), hl - 0.55, 2.25), (0.07, 0.07, 0.45), DARK)

    # usa fata (dreapta in sens de mers = -X Blender nu conteaza: ambele parti)
    for sx in (-1.0, 1.0):
        for yy in (3.0, 3.95):
            b.box((sx * (hw + 0.015), yy, 1.35), (0.025, 0.035, 2.0), DARK)
        b.box((sx * (hw + 0.02), 3.5, 1.25), (0.03, 0.18, 0.04), LIGHT_GREY)

    return b.to_object("Coach")


# --- bush_plane --------------------------------------------------------------
#
# Anvergura 8.0, lungime ~7.3, inaltime ~1.9 (cu tren). Origine CENTRU.
RED = CAR_RED
PLANE_N = 12


def build_plane():
    b = Builder()

    # fuzelaj: (y, rx, rz, zc)
    fuse = [
        (-3.65, 0.05, 0.10, 0.30),
        (-3.00, 0.14, 0.18, 0.27),
        (-2.20, 0.27, 0.32, 0.18),
        (-1.20, 0.43, 0.50, 0.05),
        (-0.20, 0.52, 0.56, 0.00),
        (0.90, 0.52, 0.52, -0.01),
        (1.70, 0.47, 0.44, -0.03),
        (2.60, 0.44, 0.41, -0.04),
        (3.15, 0.40, 0.37, -0.04),
        (3.38, 0.28, 0.26, -0.04),
    ]

    def stripe(i, k):
        # banda rosie pe flancul de jos, de la nas pana la coada
        if 1 <= i <= 7 and k in (6, 11):
            return RED
        return None

    loft(b, fuse, BODY, n=PLANE_N, slot_fn=stripe)

    # spinner
    loft(b, [(3.30, 0.24, 0.23, -0.04), (3.46, 0.20, 0.19, -0.04),
             (3.60, 0.10, 0.10, -0.04), (3.68, 0.02, 0.02, -0.04)], RED, n=8)
    # elice cu 2 pale (usor inclinate)
    for ang in (math.radians(22.0),):
        b.box((0.0, 3.60, -0.04), (0.17, 0.05, 1.85), DARK,
              rotation=Matrix.Rotation(ang, 3, "Y"))
    # priza de aer / gura capotei
    b.box((0.0, 3.30, -0.22), (0.45, 0.10, 0.10), DARK)

    # aripa SUS: plan trapezoidal, varfuri rosii
    wz0, wz1 = 0.56, 0.68
    planform(b, [(-3.4, -0.42), (3.4, -0.42), (3.4, 0.95), (-3.4, 0.95)], wz0, wz1, BODY)
    for sx in (-1.0, 1.0):
        planform(b, [(sx * 3.4, -0.42), (sx * 4.0, -0.30), (sx * 4.0, 0.80), (sx * 3.4, 0.95)]
                 if sx > 0 else
                 [(-3.4, 0.95), (-4.0, 0.80), (-4.0, -0.30), (-3.4, -0.42)],
                 wz0, wz1, RED)
    # banda rosie de-a lungul bordului de atac, la radacina
    planform(b, [(-0.9, 0.88), (0.9, 0.88), (0.9, 0.97), (-0.9, 0.97)], wz1, wz1 + 0.012, RED)

    # montanti de aripa
    for sx in (-1.0, 1.0):
        b.beam((sx * 0.46, 0.30, -0.30), (sx * 2.25, 0.30, wz0 + 0.02), 0.07, DARK)
        b.beam((sx * 0.46, 0.55, -0.30), (sx * 2.25, 0.55, wz0 + 0.02), 0.05, DARK)

    # ferestre: laterale + parbriz
    for sx in (-1.0, 1.0):
        b.box((sx * 0.485, 0.15, 0.22), (0.05, 1.55, 0.33), DARK)
    b.box((0.0, 1.30, 0.40), (0.82, 0.62, 0.05), DARK,
          rotation=Matrix.Rotation(-0.36, 3, "X"))

    # coada: deriva rosie + stabilizator alb cu varfuri rosii
    extrude_x(b, [(-2.45, 0.30), (-3.22, 0.95), (-3.64, 0.95), (-3.64, 0.26)], 0.08, RED)
    planform(b, [(-1.25, -3.58), (1.25, -3.58), (1.25, -2.98), (-1.25, -2.98)], 0.25, 0.32, BODY)
    planform(b, [(1.25, -3.58), (1.62, -3.55), (1.50, -2.98), (1.25, -2.98)], 0.25, 0.32, RED)
    planform(b, [(-1.25, -2.98), (-1.50, -2.98), (-1.62, -3.55), (-1.25, -3.58)], 0.25, 0.32, RED)

    # tren fix: picioare, carenaje, roti
    for sx in (-1.0, 1.0):
        b.beam((sx * 0.38, 0.62, -0.32), (sx * 1.0, 0.80, -0.55), 0.09, DARK)
        loft(b, [(0.42, 0.02, 0.05, -0.52, sx * 1.02), (0.58, 0.09, 0.20, -0.52, sx * 1.02),
                 (0.85, 0.11, 0.24, -0.52, sx * 1.02), (1.12, 0.08, 0.17, -0.52, sx * 1.02),
                 (1.25, 0.02, 0.05, -0.52, sx * 1.02)], BODY, n=8)
        b.cylinder((sx * 1.02, 0.80, -0.72), 0.23, 0.17, DARK, segments=10, axis="X")
        b.cylinder((sx * 1.02, 0.80, -0.72), 0.11, 0.19, RIM, segments=6, axis="X")
    b.beam((0.0, 2.30, -0.30), (0.0, 2.38, -0.64), 0.10, DARK)
    b.cylinder((0.0, 2.38, -0.74), 0.20, 0.13, DARK, segments=10, axis="X")
    b.cylinder((0.0, 2.38, -0.74), 0.09, 0.15, RIM, segments=6, axis="X")

    return b.to_object("Plane")


# --- cruise_boat_builder (candidat) -------------------------------------------
#
# AABB tinta ~4.8 x 6.2 x 14.0 (Godot X x Y x Z). Origine la LINIA DE PLUTIRE
# (carena 1.2 m sub origine). Nod "Boat".
BOAT_TW = 2.35        # semi-latime la punte
BOAT_DECK = 1.05


def build_boat():
    b = Builder()
    tw = BOAT_TW
    # (y, scara latime, z punte, z chila)
    stations = [
        (-7.00, 0.80, 1.10, -0.95),
        (-5.50, 0.93, 1.07, -1.15),
        (-3.00, 1.00, BOAT_DECK, -1.20),
        (0.00, 1.00, BOAT_DECK, -1.20),
        (3.00, 0.97, 1.10, -1.15),
        (5.00, 0.80, 1.28, -0.95),
        (6.20, 0.46, 1.48, -0.62),
        (6.90, 0.10, 1.68, -0.40),
    ]
    zw = -0.05
    st = []
    for y, sc, zd, zk in stations:
        w = tw * sc
        pts = [(-w * 0.46, zk), (w * 0.46, zk), (w * 0.80, zw), (w, zd),
               (-w, zd), (-w * 0.80, zw)]
        st.append((y, pts))

    def hull_slot(i, k):
        if k in (0, 1, 5):
            return DARK
        if k == 3 and i == 0:
            return DECK      # puntea de la pupa: platforma de lemn
        return None

    loft_pts(b, st, BODY, slot_fn=hull_slot)

    # parapet de punte pe tot conturul (bordaj mic), cabina inferioara
    cw = 3.9 * 0.5
    d1 = BOAT_DECK
    # cabina inferioara: profil lateral cu fata inclinata
    cab = [(-5.50, d1), (4.0, d1), (4.0, 2.05), (3.35, 2.75), (-5.50, 2.75)]
    extrude_x(b, cab, cw * 2.0, BODY)
    # acoperis (puntea de sus) cu streasina
    b.box((0.0, -0.80, 2.75), (4.10, 10.2, 0.12), BODY)

    # geamuri la parter: sir lung de dreptunghiuri negre cu montanti albi
    for sx in (-1.0, 1.0):
        y = -4.85
        while y < 2.95:
            b.box((sx * (cw + 0.012), y + 0.42, 1.98), (0.03, 0.80, 0.78), DARK)
            y += 0.98
    # usa/geamuri pupa si fata inclinata
    for sx in (-0.9, 0.9):
        b.box((sx, -5.512, 1.85), (1.15, 0.03, 1.2), DARK)
    ang = math.atan2(4.0 - 3.35, 2.75 - 2.05)
    rl = math.hypot(4.0 - 3.35, 2.75 - 2.05)
    b.box((0.0, 3.675 + 0.012, 2.40), (3.5, 0.03, rl * 0.85), DARK,
          rotation=Matrix.Rotation(ang, 3, "X"))

    # timonerie pe puntea de sus, spre prova
    wh = 1.6
    house = [(0.7, 2.81), (3.5, 2.81), (3.5, 3.35), (3.05, 4.0), (0.7, 4.0)]
    extrude_x(b, house, wh * 2.0, BODY)
    b.box((0.0, 2.05, 4.06), (3.5, 3.4, 0.12), BODY)           # acoperis
    for sx in (-1.0, 1.0):
        y = 0.95
        while y < 3.0:
            b.box((sx * (wh + 0.012), y + 0.3, 3.45), (0.03, 0.62, 0.52), DARK)
            y += 0.78
    ang2 = math.atan2(3.5 - 3.05, 4.0 - 3.35)
    rl2 = math.hypot(3.5 - 3.05, 4.0 - 3.35)
    b.box((0.0, 3.275 + 0.012, 3.68), (2.9, 0.03, rl2 * 0.9), DARK,
          rotation=Matrix.Rotation(ang2, 3, "X"))
    # catarg + radar
    b.beam((0.0, 1.9, 4.12), (0.0, 1.9, 5.0), 0.12, DARK)
    b.box((0.0, 1.9, 4.85), (0.9, 0.10, 0.08), DARK)

    # punte deschisa spre pupa: balustrada + banci
    top = 2.81
    for sx in (-1.0, 1.0):
        b.railing((sx * 1.9, -5.55, top), (sx * 1.9, 0.6, top), 0.95, 1.0, 0.07, 0.07, BODY)
    b.railing((-1.9, -5.55, top), (1.9, -5.55, top), 0.95, 1.0, 0.07, 0.07, BODY)
    for yy in (-4.55, -3.15, -1.75):
        for sx in (-1.0, 1.0):
            b.box((sx * 0.98, yy, top + 0.25), (1.5, 0.55, 0.42), TILE_TERRACOTTA)
            b.box((sx * 0.98, yy - 0.30, top + 0.55), (1.5, 0.10, 0.45), TILE_TERRACOTTA)
    # balustrada la pupa pe platforma de lemn
    for sx in (-1.0, 1.0):
        b.railing((sx * 1.85, -7.0, BOAT_DECK), (sx * 1.85, -5.5, BOAT_DECK), 0.85, 0.75, 0.07, 0.07, BODY)
    b.railing((-1.85, -7.0, BOAT_DECK), (1.85, -7.0, BOAT_DECK), 0.85, 1.2, 0.07, 0.07, BODY)
    # fendere negre pe bordaj
    for sx in (-1.0, 1.0):
        for yy in (-4.0, -1.0, 2.0):
            b.box((sx * (tw + 0.03), yy, 0.55), (0.08, 0.35, 0.3), DARK)

    return b.to_object("Boat")


# --- kayak_a / kayak_b -------------------------------------------------------
#
# Cota: 0.6 x 0.35 x 3.6 m (X x Y x Z in Godot; lungimea pe Blender Y).
KAYAK_LEN = 3.6
KAYAK_HW = 0.30
KAYAK_ZG0 = 0.215


def build_kayak(hull_slot, deck_slot, name):
    b = Builder()
    half_l = KAYAK_LEN * 0.5
    us = [-1.0, -0.96, -0.88, -0.76, -0.6, -0.4, -0.2, 0.0,
          0.2, 0.4, 0.6, 0.76, 0.88, 0.96, 1.0]
    stations = []
    for u in us:
        a = abs(u)
        w = max(KAYAK_HW * (1.0 - a ** 2.3) ** 0.55, 0.018)
        zb = 0.20 * a ** 4
        zg = KAYAK_ZG0 + 0.085 * a ** 2
        pts_r = [(0.0, zb),
                 (0.55 * w, zb + 0.015),
                 (0.93 * w, zb + 0.08 + 0.4 * (zg - zb - 0.08)),
                 (w, zg - 0.07),
                 (0.97 * w, zg),
                 (0.62 * w, zg + 0.030),
                 (0.20 * w, zg + 0.050)]
        pts = pts_r + [(-x, z) for x, z in reversed(pts_r[1:])]
        stations.append((u * half_l, pts))

    def deck(i, k):
        # fetele de sus (puntea) in culoarea puntii; restul pe corp
        return deck_slot if k in (4, 5, 6, 7, 8) else None

    loft_pts(b, stations, hull_slot, slot_fn=deck)

    # 2 cockpituri: coaming + gaura neagra
    for yc in (-0.48, 0.52):
        zg = KAYAK_ZG0 + 0.085 * (abs(yc) / half_l) ** 2
        oval(b, (0.0, yc, zg + 0.03), 0.20, 0.32, 0.05, hull_slot, seg=12)
        oval(b, (0.0, yc, zg + 0.04), 0.15, 0.27, 0.05, DARK, seg=12)
    # creste de punte (nervuri) spre prova/pupa
    for sy in (-1.0, 1.0):
        for yy in (1.25, 1.55):
            zg = KAYAK_ZG0 + 0.085 * (yy / half_l) ** 2
            b.box((0.0, sy * yy, zg + 0.058), (0.09, 0.07, 0.03), DARK)
        b.box((0.0, sy * 1.40, KAYAK_ZG0 + 0.085 * (1.40 / half_l) ** 2 + 0.06),
              (0.035, 0.45, 0.025), hull_slot)
    return b.to_object(name)


# --- emit ----------------------------------------------------------------

clear_built()
results = []


def emit(obj, path, budget, bevel=0.03, origin="base", smooth_angle=34.0,
         origin_size=None, bevel_angle=30.0):
    st = finish(obj, bevel=bevel, bevel_angle=bevel_angle, ao=AO_VEHICLE,
                origin=origin, smooth_angle=smooth_angle, origin_size=origin_size)
    results.append((path, st["tris"], budget, st["ao_min"], st["ao_max"]))
    return st


coach = build_coach()
emit(coach, "vehicles/coach_fiordland.glb", 99999, bevel=0.02, bevel_angle=50.0,
     origin="base")
path, size = export_glb([coach], "fiordland/vehicles/coach_fiordland.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([coach], "fiordland_coach.blend")

plane = build_plane()
emit(plane, "vehicles/bush_plane.glb", 99999, bevel=0.015, bevel_angle=60.0,
     origin="center", smooth_angle=45.0)
path, size = export_glb([plane], "fiordland/vehicles/bush_plane.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([plane], "fiordland_plane.blend")

# origin=None: linia de plutire e Z=0 prin constructie (chila la ~-1.2).
boat = build_boat()
emit(boat, "vehicles/cruise_boat_builder.glb", 99999, bevel=0.03, bevel_angle=45.0,
     origin=None, smooth_angle=40.0)
path, size = export_glb([boat], "fiordland/vehicles/cruise_boat_builder.glb")
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([boat], "fiordland_boat_builder.blend")

kayak_a = build_kayak(KERB_RED, LAVA_ORANGE, "KayakA")
emit(kayak_a, "props/kayak_a.glb", 99999, bevel=0.01, bevel_angle=55.0, origin="base",
     smooth_angle=50.0)
export_glb([kayak_a], "fiordland/props/kayak_a.glb")
kayak_b = build_kayak(CAR_YELLOW, CAR_YELLOW, "KayakB")
emit(kayak_b, "props/kayak_b.glb", 99999, bevel=0.01, bevel_angle=55.0, origin="base",
     smooth_angle=50.0)
export_glb([kayak_b], "fiordland/props/kayak_b.glb")
save_blend([kayak_a, kayak_b], "fiordland_kayaks.blend")

print()
for path, tris, budget, ao_lo, ao_hi in results:
    print("%-40s tris=%5d  AO %.2f..%.2f" % (path, tris, ao_lo, ao_hi))
