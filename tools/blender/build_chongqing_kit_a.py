"""Chongqing — Urban Kit A: mobilier stradal (plansa, pozitiile 13, 14, 15).

  props/crossing_barrier.glb   bariera de trecere la nivel (monorail, POI G)
  props/cliff_railing.glb      parapetul de piatra al cornisei (POI D)
  props/lamp_lantern_{a,b,c}   stalpi cu lampioane rosii (3 variante)
  props/neon_sign_{a,b,c,d}    firme de neon: bol, peste, tub, inel
  props/bollard.glb            bolard de piatra
  props/bicycle.glb            bicicleta rezemata
  props/mailbox_wall.glb       bateria de cutii postale (holul Liziba)
  props/scooter.glb            scuterul parcat (aleea hot-pot)
  props/table_stools.glb       masa cu scaunele de restaurant
  props/steam_vent.glb         gura de aburi din bucatarie (clasa fumarola)
  props/laundry_line.glb       rufe pe sarma (Shibati)
  props/porter.glb             hamalul "bang-bang" cu prajina si cosuri

Regula care decide TOT kitul asta: piesele sunt mici si stau LANGA drum, deci
camera le vede de aproape si in miscare. Ce citeste la 60 km/h e SILUETA si
PATA DE CULOARE, nu detaliul. De aceea fiecare piesa are un gabarit clar
(lampionul e o sfera rosie pe un baston, nu un felinar cu 12 fatete) si
cheltuiala de triunghiuri se duce in conturul care se recunoaste.

Neonul: brief §4 cere UN singur material emisiv de clasa, deci firmele sunt
FORME simple pe slot LAVA_ORANGE / KERB_RED. Slotul 31 (NEON_PINK) nu se
foloseste inca — e inca rezerva magenta in atlas, si se aprinde la integrare
(decizie de paleta, nu de asset).

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_kit_a.py
"""

import math
from mathutils import Matrix, Vector

AO_PROP = dict(samples=20, dist=2.6, gradient="vertical",
               low=0.50, high=1.00, power=0.9, floor=0.18)
AO_FLAT = dict(samples=18, dist=2.0, gradient="vertical",
               low=0.55, high=1.00, power=0.9, floor=0.22)

METAL = PAINTED
STEEL = MARBLE_GREY
RED = KERB_RED
GLOW = LAVA_ORANGE
GLASS = ASPHALT
STONE = ROCK_LIGHT
TIMBER = LOG_DARK
WOODL = WOOD
CLOTH = FOAM_WHITE
DARK = VOLCANIC_BLACK


# --- 13. bariera de trecere la nivel ---------------------------------------

def build_crossing_barrier():
    """Bariera cu crucea Sf. Andrei, lumini si lance vargata.

    **Lancea ("Boom") se monteaza la z = 1.55 m**, in axa stalpului: e
    construita in jurul lui z=0 ca sa aiba pivotul in origine, deci in Godot i
    se DA cota. In randarea de control apare pe jos langa stalp, fiindca acolo
    fiecare nod e pus la originea lui.

    Brief §3: bariera e TEATRU, nu coliziune — pedeapsa e trenul. Deci conteaza
    doar cat de tare striga "vine ceva": crucea alba, doua lumini rosii si
    lancea rosu-alb. Lancea sta ridicata; hazardul o coboara rotind nodul
    "Boom" in jurul originii lui (capatul din stalp).
    """
    post = Builder()
    # soclu + stalp
    post.box((0.0, 0.0, 0.16), (0.72, 0.72, 0.32), STONE)
    post.box((0.0, 0.0, 0.40), (0.56, 0.56, 0.20), STONE)
    post.cylinder((0.0, 0.0, 1.55), 0.10, 2.30, METAL, segments=8)
    # crucea Sf. Andrei: doua lame incrucisate
    for ang in (38.0, -38.0):
        post.box((0.0, 0.06, 2.62), (1.55, 0.09, 0.20), CLOTH,
                 rotation=Matrix.Rotation(math.radians(ang), 3, "Y"))
    # cutia cu doua lumini rosii
    post.box((0.0, 0.10, 2.06), (0.82, 0.16, 0.30), DARK)
    for sx in (-1.0, 1.0):
        post.cylinder((sx * 0.26, 0.19, 2.06), 0.13, 0.10, RED, segments=8,
                      axis="Y")
    # clopotelul (telegraph sonor — brief)
    post.cylinder((0.0, 0.0, 2.88), 0.13, 0.20, METAL, segments=8)
    p = post.to_object("CrossingBarrier")

    # lancea: nod separat, originea in axa stalpului
    boom = Builder()
    L = 4.2
    n = 7
    for i in range(n):
        x = 0.30 + L * (i + 0.5) / n
        boom.box((x, 0.0, 0.0), (L / n * 0.96, 0.13, 0.17),
                 RED if i % 2 == 0 else CLOTH)
    # contragreutatea, in spate
    boom.box((-0.45, 0.0, 0.0), (0.55, 0.20, 0.22), DARK)
    bm = boom.to_object("Boom")
    return p, bm


# --- 14. parapetul cornisei -------------------------------------------------

def build_cliff_railing():
    """Tronson de parapet de 4 m: zid de piatra + balustrada de fonta.

    Brief §2, POI D: cornisa e FARA parapet pe dreapta (aia e frica de cadere),
    iar parapetul apare doar ca punctuatie, pe exteriorul unui viraj. Deci
    piesa asta e un TRONSON scurt care se pune punctual, nu un gard continuu.
    """
    b = Builder()
    L = 4.0
    # zidul de piatra: doua randuri de blocuri, cu rosturi decalate
    for row in range(2):
        z = 0.16 + row * 0.30
        n = 5
        off = 0.5 if row else 0.0
        for i in range(n + (1 if row else 0)):
            x = -L * 0.5 + L * (i + off) / n
            if x < -L * 0.5 - 0.01 or x > L * 0.5 + 0.01:
                continue
            w = min(L / n, L * 0.5 - x) * 0.94
            if w <= 0.05:
                continue
            b.box((x + w * 0.5 * 0.0, 0.0, z), (w, 0.44, 0.28), STONE)
    # coronament continuu
    b.box((0.0, 0.0, 0.63), (L, 0.52, 0.14), MARBLE_GREY)
    # balustrada de fonta deasupra
    for i in range(4):
        x = -L * 0.5 + L * (i + 0.5) / 4
        b.cylinder((x, 0.0, 1.05), 0.055, 0.70, TIMBER, segments=6)
        b.box((x, 0.0, 1.44), (0.16, 0.16, 0.12), TIMBER)
    b.box((0.0, 0.0, 1.36), (L, 0.11, 0.10), TIMBER)
    b.box((0.0, 0.0, 1.02), (L, 0.08, 0.08), TIMBER)
    return b.to_object("CliffRailing")


# --- 15a. stalpi cu lampioane ----------------------------------------------

def lamp_post(variant):
    """Stalp de lampa cu lampioane rosii. Trei variante de brat/numar.

    Lampionul e o sfera turtita rosie cu capace: la distanta de joc asta e tot
    ce se vede, si e exact ce trebuie sa se vada.
    """
    b = Builder()
    H = 3.9 if variant != 2 else 3.2
    # soclu + fus
    b.box((0.0, 0.0, 0.12), (0.42, 0.42, 0.24), STONE)
    b.cylinder((0.0, 0.0, H * 0.5 + 0.24), 0.075, H, TIMBER, segments=6)
    # capul stalpului: felinar
    b.box((0.0, 0.0, H + 0.42), (0.30, 0.30, 0.34), DARK)
    b.box((0.0, 0.0, H + 0.30), (0.24, 0.24, 0.20), GLOW)
    b.box((0.0, 0.0, H + 0.62), (0.42, 0.42, 0.09), DARK)

    def lantern(x, y, z):
        # corpul: doua trunchiuri de con lipite = sfera turtita, ieftin
        b.frustum((x, y, z + 0.10), 0.11, 0.20, 0.20, RED, segments=8)
        b.frustum((x, y, z - 0.10), 0.20, 0.11, 0.20, RED, segments=8)
        b.cylinder((x, y, z + 0.22), 0.06, 0.06, GLOW, segments=6)
        b.cylinder((x, y, z - 0.22), 0.06, 0.06, GLOW, segments=6)
        # ciucurele
        b.box((x, y, z - 0.34), (0.05, 0.05, 0.16), GLOW)

    if variant == 0:
        # un brat cu doua lampioane
        for sx in (-1.0, 1.0):
            b.beam((0.0, 0.0, H + 0.10), (sx * 0.52, 0.0, H + 0.14), 0.06, TIMBER)
            lantern(sx * 0.52, 0.0, H - 0.18)
    elif variant == 1:
        # patru lampioane pe o cruce
        for i in range(4):
            a = math.radians(45 + i * 90)
            x, y = 0.46 * math.cos(a), 0.46 * math.sin(a)
            b.beam((0.0, 0.0, H + 0.08), (x, y, H + 0.12), 0.055, TIMBER)
            lantern(x, y, H - 0.20)
    else:
        # stalp scurt, un singur lampion mare in fata
        b.beam((0.0, 0.0, H + 0.06), (0.0, 0.60, H + 0.10), 0.06, TIMBER)
        lantern(0.0, 0.60, H - 0.22)
    return b.to_object("LampLantern%s" % "ABC"[variant])


# --- 15b. firme de neon -----------------------------------------------------

def neon_sign(variant):
    """Firma de neon: un CONTUR din tuburi, pe un stalp scurt.

    Plansa are patru: bol de hot-pot, peste, tub vertical, inel. Toate sunt
    conturul desenat cu tuburi — asta e ce face neonul sa citeasca a neon si
    nu a panou luminos. Tuburile sunt cilindri subtiri pe slot emisiv.
    """
    b = Builder()
    # stalp + consola
    b.box((0.0, 0.0, 0.10), (0.34, 0.34, 0.20), STONE)
    b.cylinder((0.0, 0.0, 1.05), 0.055, 1.90, TIMBER, segments=6)

    def tube(p0, p1, r=0.045, slot=GLOW):
        b.beam(p0, p1, r * 2.0, slot)

    def ring(cx, cz, rad, seg=10, r=0.045, slot=GLOW):
        pts = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            pts.append((cx + rad * math.cos(a), 0.0, cz + rad * math.sin(a)))
        for i in range(seg):
            tube(pts[i], pts[(i + 1) % seg], r, slot)

    if variant == 0:
        # bolul de hot-pot: o cupa trapezoidala + aburi
        z0 = 2.05
        tube((-0.42, 0, z0 + 0.34), (0.42, 0, z0 + 0.34))
        tube((-0.42, 0, z0 + 0.34), (-0.26, 0, z0 - 0.22))
        tube((0.42, 0, z0 + 0.34), (0.26, 0, z0 - 0.22))
        tube((-0.26, 0, z0 - 0.22), (0.26, 0, z0 - 0.22))
        for sx in (-0.18, 0.18):
            tube((sx, 0, z0 + 0.42), (sx, 0, z0 + 0.62), 0.035)
    elif variant == 1:
        # pestele: doua arce + coada triunghiulara
        z0 = 2.05
        seg = 7
        for sgn in (1.0, -1.0):
            pts = []
            for i in range(seg + 1):
                t = i / seg
                x = -0.46 + 0.92 * t
                z = z0 + sgn * 0.26 * math.sin(math.pi * t)
                pts.append((x, 0.0, z))
            for i in range(seg):
                tube(pts[i], pts[i + 1])
        tube((-0.46, 0, z0), (-0.70, 0, z0 + 0.22))
        tube((-0.46, 0, z0), (-0.70, 0, z0 - 0.22))
        tube((-0.70, 0, z0 + 0.22), (-0.70, 0, z0 - 0.22))
        b.box((0.24, 0.0, z0 + 0.08), (0.07, 0.05, 0.07), RED)   # ochiul
    elif variant == 2:
        # firma verticala cu caractere: un tub lung + patru bare scurte
        tube((0.0, 0, 1.55), (0.0, 0, 2.75), 0.05)
        for i in range(4):
            z = 1.72 + i * 0.30
            tube((-0.16, 0, z), (0.16, 0, z), 0.035, RED if i % 2 else GLOW)
        b.box((0.0, -0.05, 2.15), (0.30, 0.06, 1.30), DARK)      # fundal
    else:
        # inelul: cercul mare + un cerc mic in interior
        ring(0.0, 2.20, 0.44, seg=12, r=0.05)
        ring(0.0, 2.20, 0.20, seg=8, r=0.035, slot=RED)
    return b.to_object("NeonSign%s" % "ABCD"[variant])


# --- 15c. piese marunte -----------------------------------------------------

def build_bollard():
    b = Builder()
    b.box((0.0, 0.0, 0.06), (0.40, 0.40, 0.12), STONE)
    b.frustum((0.0, 0.0, 0.52), 0.16, 0.13, 0.80, STONE, segments=8)
    b.cylinder((0.0, 0.0, 0.95), 0.145, 0.12, MARBLE_GREY, segments=8)
    b.cylinder((0.0, 0.0, 1.03), 0.09, 0.08, MARBLE_GREY, segments=8)
    return b.to_object("Bollard")


def build_bicycle():
    """Bicicleta rezemata: doua roti, cadru triunghiular, ghidon, sa."""
    b = Builder()
    R = 0.34
    tilt = math.radians(8.0)          # rezemata, nu in picioare
    rot = Matrix.Rotation(tilt, 3, "Y")

    def P(x, z):
        v = rot @ Vector((x, 0.0, z))
        return (v.x, 0.0, v.z + R)

    for sy, x in ((0, -0.52), (0, 0.52)):
        c = P(x, 0.0)
        b.torus(c, R, 0.035, DARK, major_seg=12, minor_seg=5, axis="Y")
        # spite: patru bare, destul cat sa nu fie roata goala
        for i in range(4):
            a = math.radians(22.5 + i * 45)
            p0 = (c[0] + R * 0.94 * math.cos(a), 0.0, c[2] + R * 0.94 * math.sin(a))
            p1 = (c[0] - R * 0.94 * math.cos(a), 0.0, c[2] - R * 0.94 * math.sin(a))
            b.beam(p0, p1, 0.018, STEEL)
        b.cylinder(c, 0.05, 0.07, STEEL, segments=6, axis="Y")
    # cadrul
    for a, c in ((P(-0.52, 0.0), P(0.02, 0.30)), (P(0.02, 0.30), P(0.34, 0.30)),
                 (P(0.34, 0.30), P(0.52, 0.0)), (P(0.02, 0.30), P(0.16, 0.02)),
                 (P(0.16, 0.02), P(0.52, 0.0)), (P(-0.52, 0.0), P(0.16, 0.02))):
        b.beam(a, c, 0.035, TROPICAL_GREEN)
    # ghidon + sa
    b.beam(P(0.34, 0.30), P(0.30, 0.52), 0.032, STEEL)
    b.box(P(0.30, 0.56), (0.06, 0.46, 0.05), DARK)
    b.box(P(0.00, 0.36), (0.22, 0.11, 0.06), DARK)
    # pedale
    b.cylinder(P(0.16, 0.02), 0.055, 0.16, STEEL, segments=6, axis="Y")
    return b.to_object("Bicycle")


def build_mailbox_wall():
    """Bateria de cutii postale din holul blocului: 4 x 3 casute verzi."""
    b = Builder()
    W, H = 1.30, 1.00
    b.box((0.0, 0.0, H * 0.5 + 0.45), (W + 0.08, 0.10, H + 0.08), STEEL)
    for r in range(3):
        for c in range(4):
            x = -W * 0.5 + W * (c + 0.5) / 4
            z = 0.45 + H * (r + 0.5) / 3
            b.box((x, 0.06, z), (W / 4 * 0.88, 0.13, H / 3 * 0.86),
                  TROPICAL_GREEN)
            b.box((x, 0.13, z + 0.09), (W / 4 * 0.60, 0.04, 0.035), DARK)
            b.box((x, 0.13, z - 0.07), (0.045, 0.05, 0.045), GLOW)
    # picioarele
    for sx in (-1.0, 1.0):
        b.beam((sx * W * 0.42, 0.0, 0.0), (sx * W * 0.42, 0.0, 0.46), 0.06,
               STEEL)
    return b.to_object("MailboxWall")


def build_scooter():
    """Scuterul parcat din aleea hot-pot: silueta de Vespa, nu de motocicleta."""
    b = Builder()
    R = 0.20
    for x in (-0.52, 0.46):
        b.torus((x, 0.0, R), R, 0.055, DARK, major_seg=10, minor_seg=5,
                axis="Y")
        b.cylinder((x, 0.0, R), 0.09, 0.09, MARBLE_GREY, segments=8, axis="Y")
    # scutul din fata (semnul distinctiv al scuterului)
    b.box((0.44, 0.0, 0.62), (0.20, 0.42, 0.66), TROPICAL_GREEN,
          rotation=Matrix.Rotation(math.radians(-12.0), 3, "Y"))
    # podeaua + corpul din spate
    b.box((0.02, 0.0, 0.40), (0.72, 0.38, 0.12), TROPICAL_GREEN)
    b.box((-0.44, 0.0, 0.60), (0.46, 0.40, 0.40), TROPICAL_GREEN)
    b.box((-0.30, 0.0, 0.84), (0.52, 0.34, 0.11), DARK)          # saua
    # ghidon + far
    b.beam((0.50, 0.0, 0.95), (0.50, 0.0, 1.06), 0.045, STEEL)
    b.box((0.50, 0.0, 1.10), (0.06, 0.46, 0.05), STEEL)
    b.cylinder((0.56, 0.0, 0.96), 0.10, 0.07, GLOW, segments=8, axis="X")
    # oglinda si portbagajul
    b.beam((0.50, 0.18, 1.12), (0.54, 0.24, 1.30), 0.025, STEEL)
    b.box((-0.56, 0.0, 0.88), (0.28, 0.30, 0.20), RUST)
    return b.to_object("Scooter")


def build_table_stools():
    """Masa joasa cu patru scaunele — mobilierul de trotuar al aleii hot-pot."""
    b = Builder()
    # masa
    b.box((0.0, 0.0, 0.62), (0.90, 0.90, 0.07), WOODL)
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.beam((sx * 0.36, sy * 0.36, 0.0), (sx * 0.36, sy * 0.36, 0.60),
                   0.055, WOODL)
    # oala de hot-pot in mijloc (pata de culoare, si e chiar subiectul aleii)
    b.cylinder((0.0, 0.0, 0.73), 0.20, 0.16, MARBLE_GREY, segments=10)
    b.cylinder((0.0, 0.0, 0.81), 0.17, 0.04, RED, segments=10)
    # patru scaunele rosii, imprastiate
    for i, (x, y) in enumerate(((0.78, 0.10), (-0.74, -0.18), (0.12, 0.80),
                                (-0.10, -0.78))):
        b.box((x, y, 0.30), (0.30, 0.30, 0.05), RED)
        for sx in (-1.0, 1.0):
            for sy in (-1.0, 1.0):
                b.beam((x + sx * 0.11, y + sy * 0.11, 0.0),
                       (x + sx * 0.11, y + sy * 0.11, 0.28), 0.035, RED)
    return b.to_object("TableStools")


def build_steam_vent():
    """Gura de aburi din bucatarie: cosul; aburul e particula, nu geometrie."""
    b = Builder()
    b.box((0.0, 0.0, 0.30), (0.62, 0.62, 0.60), STONE)
    b.box((0.0, 0.0, 0.64), (0.72, 0.72, 0.10), MARBLE_GREY)
    b.cylinder((0.0, 0.0, 0.98), 0.20, 0.60, RUST, segments=8)
    b.frustum((0.0, 0.0, 1.36), 0.22, 0.30, 0.18, RUST, segments=8)
    # gratarul de deasupra
    for i in range(3):
        b.box((0.0, -0.18 + i * 0.18, 1.47), (0.52, 0.07, 0.05), DARK)
    return b.to_object("SteamVent")


def build_laundry_line():
    """Rufe pe sarma intre doi stalpi — semnatura vizuala a lui Shibati."""
    b = Builder()
    L = 4.6
    for sx in (-1.0, 1.0):
        x = sx * L * 0.5
        b.box((x, 0.0, 0.10), (0.26, 0.26, 0.20), STONE)
        b.cylinder((x, 0.0, 1.35), 0.05, 2.50, RUST, segments=6)
    # sarma (usor lasata: doua segmente)
    b.beam((-L * 0.5, 0.0, 2.55), (0.0, 0.0, 2.38), 0.02, STEEL)
    b.beam((0.0, 0.0, 2.38), (L * 0.5, 0.0, 2.55), 0.02, STEEL)
    # rufele: panouri plate de latimi si culori diferite
    COLORS = (CLOTH, ICE_TURQUOISE, RED, CLOTH, TROPICAL_GREEN, ICE_DEEP)
    rand = _lcg(19)
    n = 6
    for i in range(n):
        t = (i + 0.5) / n
        x = -L * 0.5 + L * t
        # cota firului la x (interpolare pe cele doua segmente)
        z = 2.55 - 0.17 * (1.0 - abs(2.0 * t - 1.0))
        h = 0.55 + rand() * 0.45
        w = 0.34 + rand() * 0.22
        b.box((x, 0.0, z - h * 0.5 - 0.04), (w, 0.035, h), COLORS[i % len(COLORS)])
        # carligul
        b.box((x, 0.0, z + 0.02), (0.05, 0.05, 0.07), STEEL)
    return b.to_object("LaundryLine")


def build_porter():
    """Hamalul "bang-bang": om cu prajina de bambus si doua cosuri.

    Figurant SUB linia camerei (brief §2, POI B) — se vede de sus, pe scara.
    Deci silueta de sus conteaza: prajina orizontala cu doua greutati atarnate
    e forma care se recunoaste instantaneu, chiar si de la 30 m.

    Fara schelet: `PathMover` il plimba, si la scara asta o animatie de mers
    n-ar fi vizibila. Pozitia e "in mers", cu picioarele decalate.
    """
    b = Builder()
    SKIN = SAND_MID
    SHIRT = ICE_DEEP
    PANTS = ASPHALT_EDGE
    # picioare, decalate (pozitie de mers)
    for sy, ang in ((-1.0, 14.0), (1.0, -12.0)):
        rot = Matrix.Rotation(math.radians(ang), 3, "X")
        b.box((0.0, sy * 0.10, 0.38), (0.15, 0.17, 0.76), PANTS, rotation=rot)
        b.box((0.0, sy * 0.10 + (0.09 if ang > 0 else -0.08), 0.035),
              (0.17, 0.30, 0.07), DARK)
    # trunchi + brate
    b.box((0.0, 0.0, 1.02), (0.34, 0.22, 0.54), SHIRT)
    b.box((0.0, 0.0, 1.36), (0.20, 0.18, 0.16), SKIN)      # gat
    b.box((0.0, 0.0, 1.52), (0.21, 0.20, 0.22), SKIN)      # cap
    b.box((0.0, 0.0, 1.64), (0.25, 0.24, 0.05), DARK)      # sapca
    # Prajina se poarta pe UN umar, langa cap — nu prin el. Varianta initiala
    # o punea pe axa corpului la z=1.46, adica exact prin cutia capului
    # (1.41..1.63): de-aia hamalul iesea fara cap, ca o sperietoare.
    # Umarul e la VARFUL trunchiului (z=1.29), deci prajina calare pe el sta
    # la ~1.33 — sub cutia capului (1.41..1.63), care ramane libera.
    SHOULDER_X = 0.19
    SHOULDER_Z = 1.33
    b.beam((SHOULDER_X, 0.0, 1.16), (SHOULDER_X + 0.04, 0.0, 1.30), 0.075, SKIN)
    b.beam((-0.17, 0.0, 1.20), (-0.13, 0.0, 1.02), 0.075, SKIN)   # bratul liber
    # mana care tine prajina, peste umar
    b.box((SHOULDER_X + 0.02, 0.11, SHOULDER_Z + 0.02), (0.10, 0.12, 0.10), SKIN)
    # prajina de bambus, pe umarul drept, in lungul mersului
    b.cylinder((SHOULDER_X, 0.0, SHOULDER_Z), 0.045, 2.30, WOODL, segments=6,
               axis="Y")
    # cosurile, atarnate la capete
    for sy in (-1.0, 1.0):
        y = sy * 1.02
        b.beam((SHOULDER_X, y, SHOULDER_Z - 0.03), (SHOULDER_X, y, 0.72),
               0.022, DARK)
        b.frustum((SHOULDER_X, y, 0.58), 0.30, 0.23, 0.30, WOODL, segments=8)
        b.cylinder((SHOULDER_X, y, 0.73), 0.30, 0.035, WOODL, segments=8)
    return b.to_object("Porter")


clear_built()

results = []


def emit(obj, path, ao=AO_PROP, origin="base", bevel=0.028):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "chongqing/" + path)
    results.append((path, st["tris"], sz / 1024.0))


p, bm = build_crossing_barrier()
st_p = finish(p, bevel=0.028, ao=AO_PROP, origin="base")
st_b = finish(bm, bevel=0.028, ao=AO_PROP, origin=None)
_, sz = export_glb([p, bm], "chongqing/props/crossing_barrier.glb")
results.append(("props/crossing_barrier.glb", st_p["tris"] + st_b["tris"],
                sz / 1024.0))

emit(build_cliff_railing(), "props/cliff_railing.glb", origin="base_axis")
for v in range(3):
    emit(lamp_post(v), "props/lamp_lantern_%s.glb" % "abc"[v])
for v in range(4):
    emit(neon_sign(v), "props/neon_sign_%s.glb" % "abcd"[v], origin="base_axis")
emit(build_bollard(), "props/bollard.glb")
emit(build_bicycle(), "props/bicycle.glb", bevel=0.02)
emit(build_mailbox_wall(), "props/mailbox_wall.glb", origin="base_axis")
emit(build_scooter(), "props/scooter.glb", bevel=0.02)
emit(build_table_stools(), "props/table_stools.glb")
emit(build_steam_vent(), "props/steam_vent.glb")
emit(build_laundry_line(), "props/laundry_line.glb")
emit(build_porter(), "props/porter.glb", bevel=0.02)

print()
for path, tris, kb in results:
    print("%-34s tris=%5d %7.1f kB" % (path, tris, kb))
print("TOTAL kit A: %d tris" % sum(t for _, t, _ in results))
