"""Kitul alpin — CLADIRILE (planşa "Swiss Alps — Alpine Switchback").

Patru landmark-uri, fiecare in GLB-ul lui, buget <= 5000 tris per bucata:
  AlpineChurch         buildings/alpine_church.glb          6 x 8 x 14 m
  MountainChaletLarge  buildings/mountain_chalet_large.glb  12 x 9 x 9 m
  MountainChaletSmall  buildings/mountain_chalet_small.glb  8 x 6 x 6.5 m
  CableCarStation      buildings/cable_car_station.glb      14 x 8 x 8 m

Paleta alpina NU are sloturi noi (24..31 raman magenta intentionat, iar
scripts/palette.gd e al instantei de gameplay). Maparea pe sloturile existente:
  tencuiala alba -> CONCRETE      lemn de chalet -> WOOD / ROCK_DARK (grinzi)
  acoperis rosu  -> TILE_TERRACOTTA (KERB_RED doar pe accente mici: turla)
  ardezia/metal  -> VOLCANIC_BLACK   otel/gheata -> PAINTED (#7692A8)
  zapada         -> FOAM_WHITE       geamuri     -> ASPHALT (golul citeste gol)

Fata "de prezentare" spre +Y in Blender (= -Z in Godot), ca la toate cladirile.
"""

import math
from mathutils import Matrix, Vector

GLASS = ASPHALT          # slotul cel mai inchis legal = golul ferestrei
TRIM = CORAL_SAND        # rame de fereastra crem, semnatura de chalet

AO_BUILDING = dict(samples=28, dist=5.0, gradient="vertical",
                   low=0.45, high=1.00, power=0.9, floor=0.12)


def rot_verts(verts, deg, axis="Z", origin=(0.0, 0.0, 0.0)):
    """Roteste DOAR varfurile date, in jurul unui punct — pentru turle si
    piese construite cu revolve care trebuie aliniate cu corpul patrat."""
    rot = Matrix.Rotation(math.radians(deg), 3, axis)
    o = Vector(origin)
    for v in verts:
        v.co = o + rot @ (v.co - o)


def gable_body(b, half_w, eave_z, ridge_z, depth, slot, y_center=0.0, base_z=0.0):
    """Corp de casa cu fronton: pentagon in XZ extrudat pe Y.

    Frontonul face parte din corp (nu din acoperis): fara el, sub panourile
    de acoperis ar ramane un triunghi gol prin care se vede interiorul."""
    outline = [(-half_w, base_z), (-half_w, eave_z), (0.0, ridge_z),
               (half_w, eave_z), (half_w, base_z)]
    return b.prism(outline, depth, slot, center=(0.0, y_center, 0.0))


def roof_panels(b, half_w, eave_z, ridge_z, depth, slot, overhang=0.7,
                thickness=0.2, y_center=0.0):
    """Doua placi rotite, cu streasina: acoperisul care depaseste peretii e
    diferenta dintre "cutie cu capac" si "casa". Unghiul iese din cote.

    Placa se intinde de la coama (depasita cu 0.25 m, ca cele doua placi sa se
    INCRUCISEZE — capetele care doar se ating lasa o fanta pe coama, vizibila
    fix din chase cam) pana dincolo de streasina."""
    rise = ridge_z - eave_z
    ang = math.atan2(rise, half_w)
    slope_len = math.hypot(half_w + overhang, rise * (1.0 + overhang / half_w))
    length = slope_len + 0.5
    for s in (-1.0, 1.0):
        rot = Matrix.Rotation(s * ang, 3, "Y")
        # centrul placii: pe linia pantei, masurat de la coama in jos
        t = length * 0.5 - 0.25
        mid_x = s * t * math.cos(ang)
        mid_z = ridge_z - t * math.sin(ang) + thickness * 0.35
        b.box((mid_x, y_center, mid_z), (length, depth + 2 * overhang, thickness),
              slot, rotation=rot)


# ============================================================ AlpineChurch
# 6 m latime (X), 8 m adancime (Y), 14 m cu tot cu cruce. Turnul in fata (+Y),
# nava in spate — silueta clasica de biserica de sat elvetian: corp alb,
# acoperis rosu, turla zvelta.

def build_church():
    b = Builder()
    # nava: y in [-3.8, 1.6]
    gable_body(b, 3.0, 3.4, 5.4, 5.4, CONCRETE, y_center=-1.1)
    roof_panels(b, 3.0, 3.3, 5.4, 5.4, TILE_TERRACOTTA, overhang=0.55,
                thickness=0.18, y_center=-1.1)
    # turnul: fata la y=4.2 -> adancimea totala 8 m
    b.box((0.0, 2.9, 4.4), (2.6, 2.6, 8.8), CONCRETE)
    # soclu de piatra, vizibil de aproape
    b.box((0.0, 2.9, 0.35), (2.9, 2.9, 0.7), ASPHALT_EDGE)

    # turla: piramida 4 laturi rotita 45 ca fetele sa cada pe fetele turnului
    spire = b.revolve([(1.95 / math.sqrt(2.0), 0.0), (0.0, 4.4)],
                      KERB_RED, segments=4, origin=(0.0, 2.9, 8.8))
    rot_verts({v for f in spire for v in f.verts}, 45.0, "Z", (0.0, 2.9, 8.8))
    # glob + cruce
    b.cylinder((0.0, 2.9, 13.25), 0.09, 0.14, SAND_LIGHT, segments=6)
    b.box((0.0, 2.9, 13.65), (0.05, 0.05, 0.62), SAND_LIGHT)
    b.box((0.0, 2.9, 13.72), (0.34, 0.05, 0.05), SAND_LIGHT)

    # ceasul, pe fata turnului — alb cu rama de lemn
    b.cylinder((0.0, 4.26, 7.3), 0.55, 0.14, FOAM_WHITE, segments=8, axis="Y")
    # ferestrele de clopotnita, cu jaluzele intunecate
    b.window((0.0, 4.2, 6.1), 0.7, 1.1, 0.09, 0.16, GLASS, WOOD)
    # usa: arc de lemn inchis, incastrata in turn
    b.window((0.0, 4.2, 1.25), 1.3, 2.5, 0.14, 0.22, ROCK_DARK, WOOD)
    # ferestre pe flancurile navei, cate doua
    for sx in (-1.0, 1.0):
        rot = Matrix.Rotation(math.radians(sx * -90.0), 3, "Z")
        for y in (-2.4, 0.4):
            b.window((sx * 3.0, y, 2.3), 0.8, 1.6, 0.09, 0.16, GLASS, WOOD,
                     rotation=rot)
    return b


# ===================================================== MountainChaletLarge
# 12 x 9 x 9 m: parter de piatra, etaj de lemn inchis, acoperis lat cu panta
# mica si streasina adanca, balcon cu jardiniere rosii — chalet-ul de manual.

def build_chalet(width, depth, height, big=True):
    hw = width * 0.5 - 0.2
    hd = depth * 0.5
    eave = height * 0.62
    ridge = height * 0.985
    base_h = height * 0.245
    b = Builder()
    # parterul de piatra
    b.box((0.0, 0.0, base_h * 0.5), (hw * 2 - 0.15, hd * 2 - 0.15, base_h),
          CONCRETE)
    # etajul de lemn, cu fronton spre +Y
    gable_body(b, hw, eave, ridge, hd * 2, ROCK_DARK, base_z=base_h)
    # grinda de talpa dintre piatra si lemn
    b.box((0.0, 0.0, base_h + 0.06), (hw * 2 + 0.1, hd * 2 + 0.1, 0.22), WOOD)
    # acoperisul de sindrila bruna
    roof_panels(b, hw, eave, ridge, hd * 2, WOOD,
                overhang=1.0 if big else 0.7, thickness=0.22)
    # cosul
    b.box((width * 0.2, -depth * 0.16, ridge - 0.1), (0.7, 0.7, 1.5), CONCRETE)

    wall = hd - 0.075  # fata parterului de piatra
    # ferestrele etajului, pe fronton
    ys = (-1.9, 0.0, 1.9) if big else (-1.1, 1.1)
    for x in ys:
        b.window((x, hd, eave * 0.86), 0.9, 1.1, 0.08, 0.15, GLASS, TRIM)
        # jardiniera cu muscate: cutie de lemn, varful retag rosu — semnatura
        # alpina la cost de un box
        box_f = b.box((x, hd + 0.14, eave * 0.86 - 0.75), (0.95, 0.24, 0.2), WOOD)
        b.retag(box_f, KERB_RED, where="up")
    # ferestre pe parter
    for x in (-width * 0.28, width * 0.28):
        b.window((x, wall, base_h * 0.62), 0.8, 0.9, 0.08, 0.14, GLASS, TRIM)
    # ferestre laterale la etaj
    for sx in (-1.0, 1.0):
        rot = Matrix.Rotation(math.radians(sx * -90.0), 3, "Z")
        for y in ((-1.6, 1.6) if big else (0.0,)):
            b.window((sx * hw, y, eave * 0.8), 0.8, 1.0, 0.08, 0.14, GLASS,
                     TRIM, rotation=rot)

    if big:
        # balconul de pe fronton, cu balustrada de sipci
        floor_z = base_h + 0.35
        b.box((0.0, hd + 0.55, floor_z), (width * 0.62, 1.15, 0.16), WOOD)
        front = hd + 1.05
        half_b = width * 0.31 - 0.05
        b.railing((-half_b, front, floor_z + 0.08), (half_b, front, floor_z + 0.08),
                  0.85, 1.1, 0.09, 0.08, WOOD, rails=2)
        for sx in (-1.0, 1.0):
            b.railing((sx * half_b, hd + 0.02, floor_z + 0.08),
                      (sx * half_b, front, floor_z + 0.08),
                      0.85, 1.0, 0.09, 0.08, WOOD, rails=2)
    return b


# ======================================================== CableCarStation
# 14 x 8 x 8 m: hala de beton cu copertina de otel gri-albastru, roata de
# cablu sub copertina si o cabina rosie suspendata in golful de intrare.
# Golful de imbarcare priveste spre +Y.

def build_station():
    b = Builder()
    # corpul din spate (sala motoarelor), inalt pana SUB copertina: la prima
    # randare avea 5.8 m si copertina plutea cu un metru deasupra lui
    b.box((0.0, -1.7, 3.5), (13.0, 4.6, 7.0), CONCRETE)
    # soclu
    b.box((0.0, -1.7, 0.5), (13.4, 5.0, 1.0), ASPHALT_EDGE)
    # ferestre inguste pe corp, banda industriala
    for x in (-4.2, 0.0, 4.2):
        b.window((x, 0.6, 4.1), 2.0, 1.1, 0.1, 0.16, GLASS, PAINTED)

    # copertina peste golful de imbarcare: marginea din spate intra in corp,
    # panta lepada zapada spre fata
    rot = Matrix.Rotation(math.radians(6.0), 3, "X")
    roof_f = b.box((0.0, 1.6, 7.05), (14.0, 6.6, 0.35), PAINTED, rotation=rot)
    b.retag(roof_f, FOAM_WHITE, where="up")   # zapada ramasa pe copertina
    # grinda de streasina pe fata
    b.box((0.0, 4.55, 6.9), (14.0, 0.35, 0.5), PAINTED)

    # pilonii copertinei
    for sx in (-1.0, 1.0):
        b.box((sx * 6.5, 4.0, 3.4), (0.55, 0.55, 6.8), CONCRETE)

    # roata de cablu (bullwheel) orizontala, vizibila sub streasina + butuc
    b.torus((0.0, 2.4, 5.5), 1.5, 0.16, PAINTED, major_seg=10, minor_seg=4)
    b.cylinder((0.0, 2.4, 5.5), 0.35, 0.5, VOLCANIC_BLACK, segments=8)
    # doua brate care tin roata de tavan
    for sx in (-1.0, 1.0):
        b.beam((sx * 1.2, 2.4, 6.8), (sx * 0.3, 2.4, 5.55), 0.16, PAINTED)

    # cabina rosie, suspendata pe cablul care trece TANGENT la roata
    # (y = centrul rotii + raza), la gura statiei
    cable_y = 2.4 + 1.45
    cab = b.box((4.1, cable_y, 3.05), (2.1, 1.55, 1.6), KERB_RED)
    # banda de geamuri: treimea de sus a peretilor cabinei
    b.retag(cab, GLASS, where=lambda c, n: abs(n.z) < 0.5 and c.z > 3.35)
    b.box((4.1, cable_y, 3.95), (2.2, 1.65, 0.14), VOLCANIC_BLACK)  # capacul
    b.beam((4.1, cable_y, 4.0), (4.1, cable_y, 5.35), 0.12, VOLCANIC_BLACK)
    b.box((4.1, cable_y, 5.42), (0.5, 0.3, 0.3), VOLCANIC_BLACK)    # carucior
    # bucata de cablu pe care sta caruciorul, iese din statie
    b.beam((-1.0, cable_y, 5.5), (7.0, cable_y, 5.53), 0.06, VOLCANIC_BLACK)

    # peronul de imbarcare
    b.box((-1.5, 2.6, 0.55), (9.0, 3.4, 1.1), CONCRETE)
    return b


# ------------------------------------------------------------------ build
ASSETS = [
    ("AlpineChurch", build_church, "buildings/alpine_church.glb", 5000),
    ("MountainChaletLarge", lambda: build_chalet(12.0, 9.0, 9.0, big=True),
     "buildings/mountain_chalet_large.glb", 5000),
    ("MountainChaletSmall", lambda: build_chalet(8.0, 6.0, 6.5, big=False),
     "buildings/mountain_chalet_small.glb", 5000),
    ("CableCarStation", build_station, "buildings/cable_car_station.glb", 5000),
]

built = []
for name, make, glb, budget in ASSETS:
    clear_built(name)
    b = make()
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.045, bevel_angle=40.0, ao=AO_BUILDING)
    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-22s %5d tris (buget %d) %s | %.1f x %.1f x %.1f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK" if stats["tris"] <= budget else "DEPASIT",
             dims[0], dims[1], dims[2], stats["ao_min"], stats["ao_max"]))
    print("GLB:   %s (%d B)" % export_glb([obj], glb))
    built.append(obj)

print("BLEND: %s (%d B)" % save_blend(built, "alpine_buildings.blend"))
