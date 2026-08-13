"""Kitul alpin — OBSTACOLE MOBILE si FILLER de curte (planşa Swiss Alps).

Obstacole (300-1500 tris):
  HayCart    vehicles/hay_cart.glb     4 x 2 x 2.5 m
  TimberSled vehicles/timber_sled.glb  5 x 2 x 2 m
  Snowplow   vehicles/snowplow.glb     5 x 2.2 x 2.3 m
(vaca s-a mutat in build_cow_animated.py — asset Quaternius cu schelet)
Filler (100-600 tris):
  HayBale        props/hay_bale.glb        1.2 x 0.8 x 0.8
  WoodStack      props/wood_stack.glb      3 x 1.5 x 1.5
  AlpineSignpost signs/alpine_signpost.glb 1.8 x 0.2 x 1.8

Vehiculele stau cu fata spre +Y in Blender (= -Z in Godot), ca masinile.
Fanul e DRY_VEGETATION (galben-oliv), lemnul taiat SAND_LIGHT (capetele
bustenilor), plugul portocaliu TILE_TERRACOTTA — sloturi existente, atlasul
nu se atinge.
"""

import math
from mathutils import Matrix

CUT_WOOD = SAND_LIGHT      # capetele taiate ale bustenilor
HAY = DRY_VEGETATION

AO_PROP = dict(samples=22, dist=1.8, gradient="vertical", low=0.55, high=1.0,
               power=1.0, floor=0.18)


def log_row(b, xs, z, radius, length, seed=0):
    """Un rand de busteni pe axa Y, cu capetele re-etichetate ca lemn taiat.
    Capetele sunt fetele cu normala pe Y — retag costa zero triunghiuri."""
    rand_state = seed
    for x in xs:
        faces = b.cylinder((x, 0.0, z), radius, length, WOOD, segments=6,
                           axis="Y")
        b.retag(faces, CUT_WOOD, where=lambda c, n: abs(n.y) > 0.6)


# ================================================================ HayCart
# Caruta de fan: doua roti mari de lemn, oiste dubla in fata, lada cu sipci
# si o movila de fan care da pe dinafara. Se citeste dintr-o privire ca
# "obiect taranesc lent" — obstacolul care se traverseaza incet peste drum.

def build_hay_cart():
    b = Builder()
    # lada: podea + sipci pe laturi
    b.box((0.0, -0.2, 1.02), (1.7, 2.5, 0.14), WOOD)
    for sx in (-1.0, 1.0):
        b.pickets((sx * 0.82, -1.3, 1.02), (sx * 0.82, 0.9, 1.02), 5,
                  (0.09, 0.09, 0.55), WOOD, tilt_jitter=3.0, seed=7)
    for sy in (-1.45, 1.05):
        b.box((0.0, sy, 1.3), (1.7, 0.09, 0.5), WOOD)
    # osia + rotile cu butuc
    b.beam((-1.0, -0.2, 0.78), (1.0, -0.2, 0.78), 0.12, WOOD)
    for sx in (-1.0, 1.0):
        wheel = b.cylinder((sx * 0.97, -0.2, 0.78), 0.78, 0.12, WOOD,
                           segments=10, axis="X")
        b.retag(wheel, ROCK_DARK, where=lambda c, n: abs(n.x) > 0.6
                and math.hypot(c.y + 0.2, c.z - 0.78) < 0.3)
        b.cylinder((sx * 1.06, -0.2, 0.78), 0.14, 0.1, ROCK_DARK,
                   segments=6, axis="X")
    # oistea: doua brate spre +Y (fata), usor coborate
    for sx in (-0.45, 0.45):
        b.beam((sx, 0.9, 0.95), (sx * 0.8, 2.05, 0.62), 0.08, WOOD)
    # piciorul de sprijin din spate
    b.beam((0.0, -1.35, 0.95), (0.0, -1.55, 0.0), 0.08, WOOD)
    # movila de fan: un bolovan mare + doua movilite, sa dea peste margini
    b.boulder((0.0, -0.2, 1.75), (1.9, 2.6, 1.25), HAY, seed=5,
              segments=8, rings=4, deviation=0.14)
    b.boulder((0.3, 0.6, 2.2), (0.9, 1.0, 0.6), HAY, seed=9,
              segments=6, rings=3, deviation=0.16)
    return b


# ============================================================== TimberSled
# Sania de busteni: talpi cu varful intors, tepusi laterale, trei busteni
# jos + doi sus. Obstacolul care aluneca pe panta si te taie calea.

def build_timber_sled():
    b = Builder()
    for sx in (-1.0, 1.0):
        x = sx * 0.75
        b.box((x, -0.25, 0.14), (0.16, 4.3, 0.28), WOOD)
        # varful intors: rotatia POZITIVA in jurul lui X ridica lui +Y —
        # cu -38 varful intra in pamant si citea ca o scandura cazuta
        rot = Matrix.Rotation(math.radians(38.0), 3, "X")
        b.box((x, 2.0, 0.38), (0.16, 0.9, 0.24), WOOD, rotation=rot)
        # tepusii care tin incarcatura
        for y in (-1.6, 0.0, 1.3):
            b.box((x, y, 0.85), (0.13, 0.13, 1.15), WOOD)
    # traverse
    for y in (-1.6, 0.0, 1.3):
        b.box((0.0, y, 0.36), (1.62, 0.2, 0.16), WOOD)
    # incarcatura: 3 + 2 busteni
    log_row(b, (-0.48, 0.0, 0.48), 0.68, 0.235, 4.4)
    log_row(b, (-0.24, 0.24), 1.08, 0.235, 4.1)
    return b


# Vaca procedurala (alb cu pete) a plecat: props/cow.glb vine acum din
# build_cow_animated.py — vaca maro Quaternius, cu schelet si animatii.
# Regenerarea kitului asta NU trebuie sa o mai atinga.


# =============================================================== Snowplow
# Plug de zapada compact: corp portocaliu, cabina cu geamuri, lama lata cu
# dungi. Lama e o cutie rotita; dungile ei sunt cutii alternante lipite pe
# fata (o fata nu se poate dunga cu retag).

def build_snowplow():
    b = Builder()
    # sasiu + capota + cabina
    b.box((0.0, -0.1, 0.85), (1.5, 3.2, 0.5), VOLCANIC_BLACK)
    b.box((0.0, 0.55, 1.28), (1.4, 1.9, 0.55), TILE_TERRACOTTA)
    cab = b.box((0.0, -0.85, 1.62), (1.5, 1.5, 1.15), TILE_TERRACOTTA)
    b.retag(cab, ASPHALT,
            where=lambda c, n: abs(n.z) < 0.5 and c.z > 1.62)
    b.box((0.0, -0.85, 2.26), (1.6, 1.6, 0.14), TILE_TERRACOTTA)
    # girofar + esapament
    b.box((0.35, -0.85, 2.42), (0.18, 0.18, 0.2), KERB_RED)
    b.cylinder((-0.55, 0.1, 2.0), 0.07, 0.9, VOLCANIC_BLACK, segments=6)
    # roti
    for sx in (-1.0, 1.0):
        for y, r in ((-0.95, 0.52), (0.95, 0.44)):
            wheel = b.cylinder((sx * 0.78, y, r), r, 0.34, ASPHALT,
                               segments=9, axis="X")
            b.retag(wheel, ASPHALT_EDGE, where=lambda c, n: abs(n.x) > 0.6
                    and math.hypot(c.y - y, c.z - r) < r * 0.45)
    # lama: cutie lata rotita spre spate + dungi de avertizare. TOATE piesele
    # lamei se aseaza cu ACEEASI rotatie, prin `blade_at`: la prima randare
    # muchia de uzura era pozitionata cu cote scrise de mana si zacea pe jos,
    # la 40 cm de lama.
    from mathutils import Vector as _V
    blade_c = _V((0.0, 1.95, 0.62))
    rot = Matrix.Rotation(math.radians(-24.0), 3, "X")

    def blade_at(local, size, slot):
        p = blade_c + rot @ _V(local)
        b.box(tuple(p), size, slot, rotation=rot)

    blade_at((0.0, 0.0, 0.0), (2.2, 0.16, 1.05), ASPHALT_EDGE)
    for i in range(5):
        x = -0.88 + i * 0.44
        slot = KERB_RED if i % 2 == 0 else FOAM_WHITE
        blade_at((x, 0.09, 0.0), (0.42, 0.1, 0.95), slot)
    # muchia de uzura, prinsa de cantul de jos al lamei
    blade_at((0.0, 0.02, -0.58), (2.24, 0.14, 0.22), RUST)
    # bratele lamei
    for sx in (-0.5, 0.5):
        b.beam((sx, 0.75, 0.7), (sx * 1.3, 1.8, 0.6), 0.11, VOLCANIC_BLACK)
    return b


# ================================================================ HayBale
# Balot rotund culcat: cilindru pe axa X. Capetele (spirala de balotat) raman
# pe acelasi slot; cele doua chingi dau silueta de "balot", nu de butoi.

def build_hay_bale():
    b = Builder()
    b.cylinder((0.0, 0.0, 0.4), 0.4, 1.18, HAY, segments=12, axis="X")
    for x in (-0.35, 0.35):
        b.cylinder((x, 0.0, 0.4), 0.415, 0.07, WOOD, segments=12, axis="X")
    return b


# =============================================================== WoodStack
# Stiva de lemne de foc: 5+4+3 busteni intre patru tarusi. Capetele deschise
# la culoare sunt tot ce vede jucatorul in trecere — de aia sunt retag-uite.

def build_wood_stack():
    b = Builder()
    log_row(b, (-0.68, -0.34, 0.0, 0.34, 0.68), 0.17, 0.165, 1.4)
    log_row(b, (-0.51, -0.17, 0.17, 0.51), 0.45, 0.165, 1.35)
    log_row(b, (-0.34, 0.0, 0.34), 0.73, 0.165, 1.42)
    log_row(b, (-0.17, 0.17), 1.0, 0.16, 1.3)
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * 0.88, sy * 0.62, 0.65), (0.11, 0.11, 1.3), WOOD)
    return b


# =========================================================== AlpineSignpost
# Stalpul galben de drumetie: sageti care arata directii diferite. Galbenul
# de semnalizare nu exista in paleta; DRY_VEGETATION e cel mai apropiat
# galben-oliv si citeste corect la 40 m. Varfurile rosii sunt KERB_RED.

def arrow_outline(length, h, sign):
    tip = 0.18 * sign
    x0 = 0.07 * sign
    x1 = (0.07 + length) * sign
    return [(x0, -h * 0.5), (x1, -h * 0.5), (x1 + tip, 0.0), (x1, h * 0.5),
            (x0, h * 0.5)]


def build_signpost():
    b = Builder()
    b.box((0.0, 0.0, 0.95), (0.13, 0.13, 1.9), WOOD)
    b.box((0.0, 0.0, 1.93), (0.2, 0.2, 0.07), WOOD)
    for z, sign, length in ((1.68, 1.0, 0.72), (1.45, -1.0, 0.62),
                            (1.22, 1.0, 0.5)):
        faces = b.prism(arrow_outline(length, 0.17, sign), 0.045, HAY,
                        center=(0.0, 0.0, z))
        # varful sagetii, rosu — conventia semnelor de traseu
        b.retag(faces, KERB_RED,
                where=lambda c, n: abs(c.x) > (0.07 + length) * 0.98)
    return b


# ------------------------------------------------------------------ build
ASSETS = [
    ("HayCart", build_hay_cart, "vehicles/hay_cart.glb", 1500, 0.02,
     AO_PROP),
    ("TimberSled", build_timber_sled, "vehicles/timber_sled.glb", 1500,
     0.015, AO_PROP),
    ("Snowplow", build_snowplow, "vehicles/snowplow.glb", 1500, 0.02,
     AO_PROP),
    ("HayBale", build_hay_bale, "props/hay_bale.glb", 600, 0.03,
     dict(samples=18, dist=0.8, gradient="vertical", low=0.62, high=1.0,
          power=1.0, floor=0.3)),
    # fara bevel: la unghiul-limita 42 tesitura prindea muchiile de 60 ale
    # cilindrilor de 6 laturi si stiva sarea la 1128 de triunghiuri
    ("WoodStack", build_wood_stack, "props/wood_stack.glb", 600, 0.0,
     AO_PROP),
    ("AlpineSignpost", build_signpost, "signs/alpine_signpost.glb", 600,
     0.012, dict(samples=18, dist=1.0, gradient="vertical", low=0.6,
                 high=1.0, power=1.0, floor=0.3)),
]

built = []
for name, make, glb, budget, bevel, ao in ASSETS:
    clear_built(name)
    b = make()
    obj = b.to_object(name)
    stats = finish(obj, bevel=bevel, bevel_angle=42.0, ao=ao)
    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-15s %5d tris (buget %d) %s | %.2f x %.2f x %.2f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK" if stats["tris"] <= budget else "DEPASIT",
             dims[0], dims[1], dims[2], stats["ao_min"], stats["ao_max"]))
    print("GLB:   %s (%d B)" % export_glb([obj], glb))
    built.append(obj)

print("BLEND: %s (%d B)" % save_blend(built, "alpine_props.blend"))
